extends Node
## 35.2 PACE (scripts/game/pace.gd). Run:
##   godot --headless --path . res://tests/pace_test.tscn -- --no-save
## The next wave comes when the one before is down to its last 2; a foe appears in 0.55 s; the
## last one or two foes of a room are marked after 2 s and you hit 30% harder and move 15% faster
## (FINISH THEM); a cleared fight gives +35% move speed until you leave (CLEAR RUSH); the first
## fight of a run leaves an old chest, the second an item (FIRST SPOILS); classic is untouched.
## Prints "pace test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL pace: ", msg)

func _start() -> Player:
	G.hero_index = 0
	G.new_run()
	G.floor_index = 0
	G.start_floor()
	G.god = true
	var p := G.player
	p.oath_picks = 0
	p.pending = 0
	G.state = &"play"
	Meta.opts["autofire"] = false
	return p

func _fight() -> Room:
	var r := World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true })
	G.enter_room(r)
	G.room.objects = G.room.objects.filter(func(o): return not o["kind"] in ["e_keg", "e_pot"])
	G.room.waves_left = 2
	G.room.twist = ""
	return r

func _tick(n: int) -> void:
	for i in n:
		G.player.hp = G.player.max_hp
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}
			G.player.pending = 0

## How far the hero walks right in 6 ticks from an open spot (px/s).
func _walk(p: Player) -> float:
	var at := World.free_spot(G.room, null, 0)
	for k in 20:   # an open stretch to the right
		if not World.hits_solid(G.room, at.x + 16, at.y, p.r, World.M_PLAYER):
			break
		at = World.free_spot(G.room, null, 0)
	p.x = at.x
	p.y = at.y
	Input.action_press(&"move_right")
	_tick(1)
	var x0 := p.x
	_tick(6)
	Input.action_release(&"move_right")
	_tick(2)
	return (p.x - x0) / (6 * TB.DT)

func _foes() -> Array:
	return G.enemies.filter(func(e): return e.hp > 0 and not e.type in ["dummy", "target"])

## Kills foes until n are left (a slime that splits leaves more: they go too).
func _kill_down_to(n: int) -> void:
	for k in 12:
		var fs := _foes()
		if fs.size() <= n:
			break
		for i in fs.size() - n:
			fs[i].spawn_t = 0.0   # (one still appearing cannot be hit)
			fs[i].hidden = false
			fs[i].asleep = false
			Combat.damage_enemy(fs[i], 1e15, { "no_crit": true, "silent": true })
		_tick(1)

## Ticks until the room clears, 2 s at most (59: the kills can fill the soul gauge, and its SOUL
## SURGE stops the world a moment, G.hitstop, so the fallen are still listed: waiting only 2 ticks,
## 7 runs in 82 found the room still locked; none in 30 since).
func _until_clear() -> void:
	for i in 120:
		if not G.locked:
			break
		_tick(1)
	_tick(2)

func _ready() -> void:
	var p := _start()
	_fight()
	_tick(60)
	var first := _foes()
	if first.is_empty():
		fail("no first wave")
	elif first[0].spawn_t > 0.0 and absf(first[0].spawn_t - Pace.SPAWN_T) > 0.6:
		fail("spawn time %.2f" % first[0].spawn_t)
	# A foe appears in 0.55 s: one just made is gone from view that long.
	var e := Combat.spawn_enemy("skeleton", 100.0, 100.0)
	if absf(e.spawn_t - Pace.SPAWN_T) > 0.001:
		fail("a new foe takes %.2f s to appear, not %.2f" % [e.spawn_t, Pace.SPAWN_T])
	G.enemies.erase(e)
	_tick(1)
	# Two left of the first wave: the next one comes 0.35 s later.
	_kill_down_to(2)
	var waves := G.room.waves_left
	_tick(30)
	if G.room.waves_left != waves - 1 or _foes().size() <= 2:
		fail("the next wave did not come with 2 foes left (waves %d -> %d, foes %d)" % [waves, G.room.waves_left, _foes().size()])

	# FINISH THEM: the last wave down to its last two foes for 2 s.
	G.room.waves_left = 0
	_kill_down_to(2)
	for f in _foes():
		f.max_hp = 1e9
		f.hp = 1e9
		f.speed = 0.0
	var d0 := Weapons.wdmg(p)
	var s0 := Pace.speed_mult()
	_tick(60)
	if Pace.finishing:
		fail("FINISH THEM after 1 s (it should wait 2 s)")
	_tick(80)
	if not Pace.finishing:
		fail("no FINISH THEM after 2.3 s with 2 foes left")
	if absf(Weapons.wdmg(p) / d0 - Pace.FINISH_DMG) > 0.001 or absf(Pace.speed_mult() / s0 - Pace.FINISH_SPEED) > 0.001:
		fail("FINISH THEM: damage x%.2f, speed x%.2f" % [Weapons.wdmg(p) / d0, Pace.speed_mult() / s0])

	# CLEAR RUSH and the first spoils.
	_kill_down_to(0)
	_until_clear()
	if G.locked:
		fail("the room did not clear")
	if Pace.finishing or not Pace.rushing or absf(Pace.speed_mult() - Pace.RUSH_SPEED) > 0.001:
		fail("no CLEAR RUSH (x%.2f)" % Pace.speed_mult())
	var ran := _walk(p)
	if not G.room.objects.any(func(o): return o["kind"] == "chest"):
		fail("the first fight left no FIRST SPOILS chest")
	# The second fight: an item on the floor.
	_fight()
	if Pace.rushing:
		fail("CLEAR RUSH should end in the next room")
	G.locked = false
	var walked := _walk(p)
	if absf(ran / walked - Pace.RUSH_SPEED) > 0.05:
		fail("the rush did not speed the walk (%.0f px/s with it, %.0f without)" % [ran, walked])
	G.locked = true
	G.room.waves_left = 1
	_tick(60)
	G.room.waves_left = 0
	_kill_down_to(0)
	_until_clear()
	if not G.room.objects.any(func(o): return o["kind"] == "item"):
		fail("the second fight left no item")
	print("[pace] the rush walks %.0f px/s, plain %.0f; %s" % [ran, walked, Pace.stats])

	# Classic: none of it.
	GameData.force_classic = true
	_start()
	_fight()
	var c := Combat.spawn_enemy("skeleton", 100.0, 100.0)
	if absf(c.spawn_t - 0.75) > 0.001 or Pace.wave_gate() != 1 or Pace.wave_gap() != 0.6:
		fail("classic pace changed")
	G.enemies.erase(c)
	G.room.waves_left = 0
	_tick(2)
	_kill_down_to(0)
	_until_clear()
	if Pace.rushing or G.room.objects.any(func(o): return o["kind"] == "chest"):
		fail("classic got a rush or the spoils")
	GameData.force_classic = false
	Meta.opts["autofire"] = true

	print("pace test: PASSED" if fails == 0 else "pace test: %d FAILED" % fails)
	get_tree().quit()
