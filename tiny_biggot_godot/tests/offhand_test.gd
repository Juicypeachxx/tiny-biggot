extends Node
## 37.1 OFFHANDS (scripts/data/gear.gd rows o_*, scripts/combat/block.gd). Run:
##   godot --headless --path . res://tests/offhand_test.tscn -- --no-save
## The offhand is a slot of its own; every offhand goes into it and comes off again leaving the
## hero as before; a shield's block comes back in time and stops a hit (and only one); the
## MIRROR SHIELD sends shards back, the SPIKED TARGE spikes out, the HAND MIRROR stops some hits;
## a lantern carries its field; classic has no blocks.
## Prints "offhand test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL offhand: ", msg)

func _start() -> Player:
	G.hero_index = 0
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	var p := G.player
	p.oath_picks = 0
	p.pending = 0
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.enemies.clear()
	G.locked = true
	G.state = &"play"
	G.god = false
	Meta.opts["autofire"] = false
	return p

func _snap(p: Player) -> Array:
	var gf := {}
	for k in p.gf:
		if absf(p.gf[k]) > 0.0001:   # (a hook back at 0 is no trace)
			gf[k] = snappedf(p.gf[k], 0.0001)
	return [p.max_hp, snappedf(p.speed, 0.001), snappedf(p.rate, 0.0001), snappedf(p.crit, 0.0001), p.burn, p.chill, p.pierce,
		p.orbitals, p.luck, p.thorns, p.dodge_charges, p.a_int, gf, p.procs.size()]

func _hit(p: Player) -> bool:
	p.invuln = 0.0
	p.dodge_t = 0.0
	var hp0 := p.hp
	var armor0 := p.armor
	Combat.hurt_player(1, "a test")
	return p.hp < hp0 or p.armor < armor0

func _ready() -> void:
	var p := _start()
	if not Gear.slots().has("offhand"):
		fail("no offhand slot")
	var offs := Gear.all().filter(func(g): return g["slot"] == "offhand")
	if offs.size() < 25:
		fail("only %d offhands" % offs.size())
	# Every offhand: on, then off again (a plain buckler in its place, then nothing) leaves no trace.
	var base := _snap(p)
	for g in offs:
		if not Img.has(g["sprite"]):
			fail("%s has no picture %s" % [g["id"], g["sprite"]])
		var old = Gear.equip_gear(p, g)
		if p.gear.get("offhand") != g:
			fail("%s did not go into the offhand slot" % g["id"])
		if old != null:
			fail("%s replaced something unexpected" % g["id"])
		_take_off(p)
		var now := _snap(p)
		if str(now) != str(base):
			fail("%s left a trace: %s -> %s" % [g["id"], base, now])
			base = now

	# A shield: ready after its time, stops one hit, then hits land again.
	p.armor = 0
	p.hp = p.max_hp
	Block.reset()
	Gear.equip_gear(p, Gear.by_id("o_buckler"))
	if not _hit(p):
		fail("a buckler stopped a hit before its block was ready")
	p.hp = p.max_hp
	for i in 8 * 60 + 5:
		Block.tick(p, TB.DT)
	if not Block.ready:
		fail("the buckler's block was not ready after 8 s")
	if _hit(p):
		fail("a ready block did not stop the hit")
	if Block.ready:
		fail("a block was not spent")
	if not _hit(p):
		fail("a second hit was stopped by a spent block")
	_take_off(p)

	# MIRROR SHIELD: shards; SPIKED TARGE: spikes.
	for pair in [["o_mirrorshield", Block.SHARDS], ["o_spiketarge", Block.SPIKES]]:
		Gear.equip_gear(p, Gear.by_id(pair[0]))
		Combat.spawn_enemy("skeleton", p.x + 80, p.y, false, true)
		Block.ready = true
		var n0 := G.pbullets.size() + G.new_pbullets.size()
		p.hp = p.max_hp
		_hit(p)
		var made := G.pbullets.size() + G.new_pbullets.size() - n0
		if made < pair[1]:
			fail("%s made %d shots on a block, not %d" % [pair[0], made, pair[1]])
		_take_off(p)
		G.enemies.clear()

	# HAND MIRROR: some hits stopped, not all.
	Gear.equip_gear(p, Gear.by_id("o_handmirror"))
	var stopped := 0
	for i in 300:
		p.hp = p.max_hp
		p.armor = 0
		if not _hit(p):
			stopped += 1
	if stopped < 20 or stopped > 80:
		fail("the HAND MIRROR stopped %d of 300 hits (about 45 expected)" % stopped)
	_take_off(p)

	# A lantern carries its field.
	Gear.equip_gear(p, Gear.by_id("o_lantern"))
	if not Auras.active(p).any(func(h): return h[0] == "burn"):
		fail("the TIN LANTERN has no field of fire")
	_take_off(p)
	print("[offhand] %d offhands; blocks %s" % [offs.size(), Block.stats])

	# Classic: no blocks.
	GameData.force_classic = true
	var c := _start()
	c.gf["block_rate"] = 5.0
	Block.ready = true
	if not _hit(c):
		fail("classic blocked a hit")
	GameData.force_classic = false
	Meta.opts["autofire"] = true

	print("offhand test: PASSED" if fails == 0 else "offhand test: %d FAILED" % fails)
	get_tree().quit()

## Takes the offhand off (the same path a swap uses: its stats, hooks and effects come off).
func _take_off(p: Player) -> void:
	var g = p.gear.get("offhand")
	if g == null:
		return
	Weapons.apply_tuples(p, g["stats"], -1, "g:" + g["id"])
	Weapons.apply_hooks(p, g["hooks"], -1)
	if not g["effects"].is_empty():
		Effects.apply_equipment(p, g["effects"], -1, "gfx:" + g["id"])
	p.gear["offhand"] = null
	Gear.update_sets(p, g["set"], -1)
	if g["new"]:
		Effects.recount_tags(p)
