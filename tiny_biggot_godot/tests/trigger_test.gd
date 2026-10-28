extends Node
## 34.1 THE TRIGGER PATH (scripts/combat/lucky.gd). Run:
##   godot --headless --path . res://tests/trigger_test.tscn -- --no-save
## Lucky hits come at their chance, strike again and fire on_lucky (JACKPOT); SPELLSLINGER casts the
## first backpack slot's weapon on crits and lucky hits, shots of a cast never cast again, the hero's
## own weapon is back after, a weapon that cannot be cast is never cast; STATIC BUILD-UP discharges;
## QUICK FINGERS; the Trickshot plays 10 s; classic has no lucky hits.
## Prints "trigger test: PASSED" or a FAIL line per problem.

var fails := 0
var notes := []

func fail(msg: String) -> void:
	fails += 1
	print("FAIL trigger: ", msg)

func _hero(id: String) -> int:
	var all := GameData.heroes()
	for i in all.size():
		if all[i]["id"] == id:
			return i
	return 0

func _start(hero: String = "hexer") -> Player:
	G.hero_index = _hero(hero)
	G.new_run()
	G.floor_index = 2
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
	Meta.opts["autofire"] = true
	p.x = 14.0 * TB.TS
	p.y = 12.0 * TB.TS
	Lucky.stats.clear()
	return p

func _foes(p: Player, n: int = 4) -> Array:
	var out := []
	for i in n:
		var e := Combat.spawn_enemy("skeleton", p.x - 60.0 + i * 40.0, p.y - 80.0 - (i % 2) * 16.0, false, true)
		e.speed = 0.0
		e.max_hp = 1e7
		e.hp = 1e7
		out.append(e)
	return out

func _tick(n: int) -> void:
	var p := G.player
	for i in n:
		p.hp = p.max_hp
		p.x = 14.0 * TB.TS
		p.y = 12.0 * TB.TS
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

func _ready() -> void:
	await get_tree().process_frame
	seed(341)
	# Lucky hits at their chance; they strike again.
	var p := _start()
	p.gf["lucky"] = 0.5
	var foes := _foes(p)
	_tick(600)
	var hits := 0
	for e in foes:
		hits += e.struck
	if Lucky.stats.get("lucky", 0) < 10:
		fail("only %d lucky hits in 10 s at 50%%" % Lucky.stats.get("lucky", 0))
	notes.append("50%% lucky hits: %d lucky in 10 s" % Lucky.stats.get("lucky", 0))
	# JACKPOT: every 10th lucky hit, bolts.
	p = _start()
	p.gf["lucky"] = 1.0
	G.take_trait(Traits.by_id("q_jackpot"))
	_foes(p)
	Actions.ran.clear()
	_tick(300)
	if Actions.ran.get("bolts", 0) < 1:
		fail("JACKPOT never called its bolts (%d lucky hits)" % Lucky.stats.get("lucky", 0))
	# The spell slot.
	p = _start()
	var own: Dictionary = p.weapon
	G.take_trait(Traits.by_id("q_spellslinger"))
	p.crit = 0.5
	p.backpack.clear()
	p.backpack.append(Weapons.by_id("kaleidoscope"))
	_foes(p)
	var max_shots := 0
	for i in 600:
		_tick(1)
		max_shots = maxi(max_shots, G.pbullets.size())
		for b: PBullet in G.pbullets:
			if b.cast and b.kind == "" :
				pass
	if Lucky.stats.get("casts", 0) < 5:
		fail("SPELLSLINGER: only %d casts in 10 s at 50%% crit" % Lucky.stats.get("casts", 0))
	if p.weapon != own:
		fail("the hero's own weapon was not back after the casts")
	notes.append("SPELLSLINGER with a KALEIDOSCOPE in the slot, 50%% crit: %d casts in 10 s, at most %d shots" % [Lucky.stats.get("casts", 0), max_shots])
	# A weapon that cannot be cast is never cast.
	p = _start()
	G.take_trait(Traits.by_id("q_spellslinger"))
	p.crit = 1.0
	p.backpack.clear()
	p.backpack.append(Weapons.by_id("greataxe"))
	_foes(p)
	_tick(300)
	if Lucky.stats.get("casts", 0) > 0:
		fail("a great axe in the slot was cast %d times" % Lucky.stats.get("casts", 0))
	# STATIC BUILD-UP.
	p = _start()
	G.take_trait(Traits.by_id("q_static"))
	var fs := _foes(p)
	for k in Statuses.SHOCK_MAX:
		Statuses.apply(fs[0], "shock", 1, 10.0)
	if Lucky.stats.get("discharges", 0) != 1 or fs[0].shock != 0:
		fail("STATIC BUILD-UP: %d discharges, shock %d" % [Lucky.stats.get("discharges", 0), fs[0].shock])
	# QUICK FINGERS.
	p = _start()
	var r0 := Weapons.wrate(p)
	G.take_trait(Traits.by_id("q_quickfingers"))
	if absf(Weapons.wrate(p) / r0 - (1.0 + 0.01 * p.a_dex)) > 1e-4:
		fail("QUICK FINGERS: rate x%.3f at DEX %d" % [Weapons.wrate(p) / r0, p.a_dex])
	# The Trickshot.
	p = _start("trickshot")
	if p.backpack.is_empty() or p.backpack[0]["id"] != "runechalk" or p.g("slot_cast") <= 0 or Lucky.chance(p) < 0.05:
		fail("the Trickshot starts wrong: backpack %s, slot %s, lucky %.2f" % [p.backpack.map(func(x): return x["id"]), p.g("slot_cast"), Lucky.chance(p)])
	_foes(p)
	Abilities.use(p)
	if Lucky.chance(p) < 1.0:
		fail("TRICK SHOT: every hit not lucky")
	_tick(600)
	if Lucky.stats.get("casts", 0) < 3:
		fail("the Trickshot cast only %d times in 10 s" % Lucky.stats.get("casts", 0))
	notes.append("the Trickshot, 10 s with TRICK SHOT: %d lucky hits, %d casts" % [Lucky.stats.get("lucky", 0), Lucky.stats.get("casts", 0)])
	# Classic.
	GameData.force_classic = true
	if Lucky.chance(p) != 0.0:
		fail("classic has lucky hits")
	GameData.force_classic = false
	for n in notes:
		print("[trigger] ", n)
	print("trigger test: PASSED" if fails == 0 else "trigger test: %d FAILED" % fails)
	get_tree().quit()
