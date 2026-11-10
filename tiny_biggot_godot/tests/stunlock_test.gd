extends Node
## 39.4 STUNNED, NOT IMMORTAL (his video, 9 Oct 18:20: THE IRON CAPTAIN, stunned without a break
## by a build that stuns many times a second, stayed at two thirds of its health for good). A foe
## with stages stops at the line of its next stage until it breaks into it (stages.gd gate), and
## the break was part of its turn, which a stun skipped. Run:
##   godot --headless --path . res://tests/stunlock_test.tscn -- --no-save
## A mini-boss, a floor guardian, a rift mini and a rift guardian, each stunned on every tick and
## hit hard, must go through every stage and die; and a stun still holds a foe that is not at a
## stage line (stuns keep all their power). Also 39.4: a foe hit a hundred times in a moment shows
## one number adding them all up (not a block of numbers on one spot), and a new one after; blows
## on a foe held at its stage line, which take nothing off, do not count as damage dealt (they made
## every foe after it tougher, Combat.power_scale).
## Prints "stunlock test: PASSED" or a FAIL line per problem.

const FOES := ["ironcaptain", "ashwarlord", "tidecaptain", "stormcrown"]

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stunlock: ", msg)

func _start() -> Player:
	G.hero_index = 0
	G.new_run()
	G.floor_index = 7
	G.start_floor()
	G.god = true
	var p := G.player
	p.oath_picks = 0
	p.pending = 0
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.enemies.clear()
	G.locked = true
	G.state = &"play"
	Meta.opts["autofire"] = false
	return p

func _spawn(key: String) -> Enemy:
	var p := G.player
	if GameData.BOSSES.has(key):
		return Combat.spawn_boss(key, true)
	return Combat.spawn_enemy(key, p.x, p.y - 70.0, false, true)

func _tick() -> void:
	var p := G.player
	p.hp = p.max_hp
	Keys.tick()
	G.update(TB.DT)
	if G.state != &"play":
		G.state = &"play"
		G.tchoice = {}
		G.choice = {}

func _ready() -> void:
	for key in FOES:
		_start()
		var e := _spawn(key)
		var stages := [e.stage]
		var secs := 0.0
		while e.hp > 0 and secs < 90.0:
			e.stun_t = maxf(e.stun_t, 0.5)   # stunned on every tick, as a stun on every hit does
			Combat.damage_enemy(e, e.max_hp * 0.01, { "no_mult": true, "no_crit": true, "silent": true })
			_tick()
			secs += TB.DT
			if stages[stages.size() - 1] != e.stage:
				stages.append(e.stage)
		if e.hp > 0:
			fail("%s, stunned without a break, is still alive after 90 s at %d%% (stage %d, state %s)" % [key,
				roundi(100.0 * e.hp / e.max_hp), e.stage, e.state])
		else:
			print("[stunlock] %s died in %.1f s, stages %s" % [key, secs, stages])

	# A stun still holds a foe that is not at a stage line: it does not move or attack.
	_start()
	var m := _spawn("ironcaptain")
	m.stun_t = 3.0
	var x0 := m.x
	var y0 := m.y
	var t0 := m.t
	for i in 60:
		_tick()
	if m.x != x0 or m.y != y0 or m.t != t0:
		fail("a stunned mini-boss above its stage line moved or counted down its attack")

	# Blows on a foe held at its stage line are not "damage dealt" (Combat.power); others are.
	_start()
	var h := _spawn("ironcaptain")
	h.hp = Stages.gate(h)
	G.run_stats["dealt"] = 0.0
	for i in 20:
		Combat.damage_enemy(h, 1000.0, { "no_mult": true, "no_crit": true, "silent": true })
	if G.run_stats["dealt"] > 0.0 or h.hp != Stages.gate(h):
		fail("20 blows on a mini-boss held at its stage line counted %.0f damage dealt" % G.run_stats["dealt"])
	var sk := Combat.spawn_enemy("skeleton", G.player.x + 40.0, G.player.y, false, true)
	Combat.damage_enemy(sk, 5.0, { "no_mult": true, "no_crit": true, "silent": true })
	if G.run_stats["dealt"] <= 0.0:
		fail("a blow on a skeleton was not counted as damage dealt")

	# Numbers: a hundred hits in one moment, one number that adds them up; later hits, a new one.
	_start()
	var f := Combat.spawn_enemy("skeleton", G.player.x, G.player.y - 60.0, false, true)
	f.max_hp = 1e9
	f.hp = 1e9
	Fx.clear()
	for i in 100:
		Combat.damage_enemy(f, 10.0, { "no_mult": true, "no_crit": true, "silent": true })
	var nums := Fx.texts.filter(func(t): return t.has("sum"))
	if nums.size() != 1:
		fail("100 hits in one moment made %d numbers, not 1" % nums.size())
	elif absf(nums[0]["sum"] - (1e9 - f.hp)) > 0.01 or nums[0]["text"] != TB.fmt_dmg(1e9 - f.hp):
		fail("the number shows %s, the foe lost %.1f" % [nums[0]["text"], 1e9 - f.hp])
	for i in 24:
		_tick()
	Combat.damage_enemy(f, 10.0, { "no_mult": true, "no_crit": true, "silent": true })
	if Fx.texts.filter(func(t): return t.has("sum")).size() != 2:
		fail("a hit 0.4 s later did not start a number of its own")

	Meta.opts["autofire"] = true
	print("stunlock test: PASSED" if fails == 0 else "stunlock test: %d FAILED" % fails)
	get_tree().quit()
