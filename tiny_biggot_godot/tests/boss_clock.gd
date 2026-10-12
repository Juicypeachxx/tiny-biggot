extends Node
## 56.1 How fast the guardians fall to a full build (his playthrough, 12 Oct: "the bosses just melts
## in seconds"). A tool, not part of check.sh. Run:
##   godot --headless --path . res://tests/boss_clock.tscn -- --no-save [--clock-heroes=0,3,7]
##     [--clock-seeds=2] [--clock-floors=2,4,6,8,10] [--clock-cap=150] [--clock-plain]
## For each hero, seed and floor: a run on that floor with the build a player has there by then:
## 4 levels a floor, each a trait from the game's own offer (one of them at random), 2 relics a floor
## (rolled as chests roll them), a weapon and 4 pieces of gear rolled as the floor rolls them
## (--clock-plain: the hero as it starts). Then 45 s of the floor's ordinary fights (so the game
## measures the build as in a run: Combat.power_scale), then the floor's own guardian in its room.
## The hero fights with autofire, closes in (melee) or keeps a little away, rolls now and then and
## uses the special when ready, in god mode. Prints "[clock] hero=.. floor=.. boss=.. secs=.. hp=..
## power=.." for each fight and the median seconds of each floor.

var heroes: Array = [0]
var seeds := 2
var floors: Array = [2, 4, 6, 8, 10]
var cap := 150.0
var plain := false
var by_floor := {}   # floor -> [secs]
var _held := {}

func _ints(name: String, def: Array) -> Array:
	var s := DebugArgs.get_str(name)
	if s == "":
		return def
	return Array(s.split(",")).map(func(x): return int(x))

func _ready() -> void:
	await get_tree().process_frame
	heroes = _ints("clock-heroes", heroes)
	floors = _ints("clock-floors", floors)
	seeds = maxi(1, DebugArgs.get_int("clock-seeds", seeds))
	cap = float(DebugArgs.get_int("clock-cap", int(cap)))
	plain = DebugArgs.has("clock-plain")
	for h in heroes:
		for s in seeds:
			for f in floors:
				_clock(h, s, f)
	var line := []
	for f in floors:
		var xs: Array = by_floor.get(f, [])
		xs.sort()
		line.append("floor %d: %s s" % [f, ("%.1f" % xs[xs.size() / 2]) if not xs.is_empty() else "-"])
	print("[clock] median  " + "   ".join(line))
	get_tree().quit()

func _hold(a: StringName, on: bool) -> void:
	if on and not _held.get(a, false):
		Input.action_press(a)
	elif not on and _held.get(a, false):
		Input.action_release(a)
	_held[a] = on

func _clock(h: int, s: int, f: int) -> void:
	seed(5600 + s * 7919 + f * 131 + h * 17)
	G.hero_index = h
	G.new_run()
	G.god = true
	Meta.opts["autofire"] = true
	G.floor_index = f - 1
	G.start_floor()
	G.state = &"play"
	var p := G.player
	if not plain:
		_build(p, f)
	# The floor's ordinary fights, so the game measures the build (Combat.track_power).
	var t := 0.0
	while t < 45.0:
		G.enemies.clear()
		G.locked = false
		G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
		var room := G.room
		var rt := 0.0
		while t < 45.0 and G.room == room and (G.locked or rt < 1.0):
			_step(p)
			t += TB.DT
			rt += TB.DT
	# The guardian.
	G.enemies.clear()
	G.locked = false
	G.enter_room(World.make_room(G.floor_d, "boss", "", "s", { "no_secret": true }))
	var b: Enemy = null
	var bt := 0.0
	while bt < cap + 3.0:
		_step(p)
		bt += TB.DT
		if b == null and G.boss != null:
			b = G.boss
			bt = 0.0
		if b != null and b.hp <= 0:
			break
	for a in Keys.ACTIONS:
		_hold(a, false)
	if b == null:
		print("[clock] hero=%d floor=%d: no guardian came" % [h, f])
		return
	var secs := bt if b.hp <= 0 else cap
	if not by_floor.has(f):
		by_floor[f] = []
	by_floor[f].append(secs)
	print("[clock] hero=%s floor=%d boss=%s secs=%s hp=%.0f lv=%d traits=%d relics=%d power=%.0f dps=%.0f" % [p.hero["id"], f,
		b.boss, ("%.1f" % secs) if b.hp <= 0 else (">%d (%.0f%% left)" % [int(cap), 100.0 * b.hp / b.max_hp]), b.max_hp,
		p.level, p.traits.size(), p.relics.size(), Combat.power(p), G.run_stats.get("dps", 0.0)])

## The build a player has on floor f: levels and traits, relics, a weapon, gear.
func _build(p: Player, f: int) -> void:
	for i in 4 * f:
		Combat.gain_xp(p, GameData.xp_needed(p.level) - p.xp)
	var guard := 0
	while p.pending > 0 and guard < 400:
		guard += 1
		G.offer_traits()
		if G.state == &"traits" and not G.tchoice.is_empty() and not G.tchoice["opts"].is_empty():
			G.take_trait(TB.pick(G.tchoice["opts"]))
			p.pending = maxi(0, p.pending - 1)
		else:
			p.pending = 0
		G.tchoice = {}
		G.state = &"play"
	for r in G.roll_relics(2 * f):
		G.add_relic(p, r)
	Weapons.equip_weapon(p, Weapons.random_weapon(G.roll_rarity("chest")))
	for k in 4:
		Gear.equip_gear(p, Gear.random_gear(G.roll_rarity("chest")))
	p.hp = p.max_hp

## One tick: the hero closes in or keeps away, rolls, uses the special; menus are answered.
func _step(p: Player) -> void:
	var e = Combat.nearest_enemy(p.x, p.y, 999)
	var v := Vector2.ZERO
	if e != null:
		var to := Vector2(e.x - p.x, e.y - p.y)
		var melee: bool = p.weapon != null and WeaponInfo.wtype(p.weapon) == "MELEE"
		var want: float = 12.0 + e.r if melee else 70.0
		v = to if to.length() > want + 8.0 else (-to if to.length() < want - 20.0 else Vector2.ZERO)
	_hold(&"move_left", v.x < -4)
	_hold(&"move_right", v.x > 4)
	_hold(&"move_up", v.y < -4)
	_hold(&"move_down", v.y > 4)
	_hold(&"roll", randf() < 0.01)
	_hold(&"special", Abilities.ready(p) and G.enemies_active())
	Keys.tick()
	G.update(TB.DT)
	match G.state:
		&"traits":
			if not G.tchoice.is_empty() and not G.tchoice["opts"].is_empty():
				G.take_trait(TB.pick(G.tchoice["opts"]))
			G.tchoice = {}
			G.player.pending = 0
			G.state = &"play"
		&"choice":
			G.choice = {}
			G.state = &"play"
		&"dead", &"win", &"pause", &"inventory":
			G.state = &"play"
	p.hp = maxi(p.hp, p.max_hp / 2)
