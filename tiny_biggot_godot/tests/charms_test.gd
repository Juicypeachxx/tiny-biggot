extends Node
## 37.2 CHARMS (scripts/data/charms.gd). Run:
##   godot --headless --path . res://tests/charms_test.tscn -- --no-save
## Thirty charms with pictures and text the font can draw; three slots to start (COLLECTOR and the
## CHARM BRACELET add more); a charm comes off leaving the hero as before; one on the floor goes
## into a free slot or the backpack; one is for sale in a shop; in the backpack USE wears it and on
## a worn one USE takes it off; an ALTER die changes a backpack charm; a saved run keeps them;
## classic has none.
## Prints "charms test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL charms: ", msg)

func _start() -> Player:
	G.hero_index = 0
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = true
	var p := G.player
	p.oath_picks = 0
	p.pending = 0
	G.enter_room(World.make_room(G.floor_d, "treasure", "", "s", { "no_secret": true }))
	G.room.objects.clear()
	G.enemies.clear()
	G.state = &"play"
	return p

func _snap(p: Player) -> String:
	var gf := {}
	for k in p.gf:
		if absf(p.gf[k]) > 0.0001:
			gf[k] = snappedf(p.gf[k], 0.0001)
	return str([p.max_hp, snappedf(p.dmg, 0.0001), snappedf(p.rate, 0.0001), snappedf(p.speed, 0.001), snappedf(p.crit, 0.0001),
		p.luck, p.orbitals, p.pierce, p.dodge_charges, snappedf(p.burn, 0.0001), snappedf(p.chill, 0.0001), snappedf(p.chain, 0.0001),
		snappedf(p.gold_mult, 0.0001), snappedf(p.xp_mult, 0.0001), snappedf(p.shot_speed, 0.0001), snappedf(p.elite_mult, 0.0001),
		p.a_str, p.a_dex, p.a_int, gf, p.procs.size()])

func _ready() -> void:
	var p := _start()
	var all := Charms.all()
	if all.size() < 30:
		fail("only %d charms" % all.size())
	for c in all:
		if not Img.has(c["sprite"]):
			fail("%s has no picture" % c["id"])
		for txt in [c["name"], c["desc"]]:
			for ch in txt:
				if not ch in Gfx.FONT_CHARS:
					fail("%s: the font cannot draw %s" % [c["id"], ch])
	# Three slots; each charm on and off leaves no trace.
	if Charms.slots(p) != 3:
		fail("%d charm slots to start, not 3" % Charms.slots(p))
	var base := _snap(p)
	for c in all:
		if not Charms.wear(p, c):
			fail("could not wear %s" % c["id"])
			continue
		Charms.take_off(p, 0)
		if _snap(p) != base:
			fail("%s left a trace: %s -> %s" % [c["id"], base, _snap(p)])
			base = _snap(p)
	for i in 3:
		Charms.wear(p, all[i])
	if Charms.wear(p, all[3]):
		fail("a fourth charm was worn in three slots")
	Effects.apply(p, Traits.by_id("c_collector")["effects"], 1, "trait:c_collector")
	Effects.apply(p, Relics.by_id("charmbracelet")["effects"], 1, "relic:charmbracelet")
	if Charms.slots(p) != 6:
		fail("COLLECTOR and the CHARM BRACELET: %d slots, not 6" % Charms.slots(p))
	if not Charms.wear(p, all[3]):
		fail("more slots, but no fourth charm")
	while not p.charms.is_empty():
		Charms.take_off(p, 0)

	# On the floor: into a free slot.
	G.drop_item(all[5], p.x + 20, p.y)
	var o: Dictionary = G.room.objects[G.room.objects.size() - 1]
	G.interact(o)
	if not Charms.wearing(p, all[5]["id"]) or not o.get("gone", false):
		fail("a charm on the floor was not worn")
	# Slots full: into the backpack.
	for i in range(6, 6 + Charms.slots(p) - p.charms.size()):
		Charms.wear(p, all[i])
	p.backpack.clear()
	G.drop_item(all[20], p.x + 20, p.y)
	o = G.room.objects[G.room.objects.size() - 1]
	G.interact(o)
	if p.backpack.size() != 1 or p.backpack[0]["id"] != all[20]["id"]:
		fail("with every slot taken, a charm did not go into the backpack")
	# The backpack: USE with every slot taken does nothing; take one off, then it can be worn.
	G.equip_from_backpack(0)
	if p.backpack.size() != 1:
		fail("a charm was worn with every slot taken")
	G.state = &"inventory"
	G.inv_i = 10
	Taps.send(&"use")
	await get_tree().process_frame
	Keys.tick()
	G.update_inventory()
	if p.charms.size() != Charms.slots(p) - 1 or p.backpack.size() != 2:
		fail("USE on a worn charm did not take it off into the backpack (%d worn, %d in the pack)" % [p.charms.size(), p.backpack.size()])
	G.equip_from_backpack(0)
	if not Charms.wearing(p, all[20]["id"]):
		fail("a charm in the backpack was not worn with a slot free")
	G.state = &"play"
	# An ALTER die on a backpack charm.
	var bc: Dictionary = p.backpack[0]
	G.inv_i = 0
	Dice.give(p, "alter", 1)
	Dice.item_row(false)
	if p.backpack[0]["id"] == bc["id"] or p.backpack[0]["item"] != "charm" or p.backpack[0]["rarity"] != bc["rarity"]:
		fail("ALTER on a charm: %s -> %s" % [bc["id"], p.backpack[0]["id"]])
	# A saved run keeps them.
	var worn := p.charms.map(func(c): return c["id"])
	var d := RunSave.capture()
	RunSave.restore(d)
	var q := G.player
	if q.charms.map(func(c): return c["id"]) != worn:
		fail("a saved run lost its charms")
	# A shop sells one.
	G.enter_room(World.make_room(G.floor_d, "shop", "", "s", { "no_secret": true }))
	var stall = null
	for so in G.room.objects:
		if so["kind"] == "shop" and so["item"] == "charm":
			stall = so
	if stall == null:
		fail("no charm for sale in a shop")
	else:
		while not q.charms.is_empty():
			Charms.take_off(q, 0)
		q.gold = 999
		G.interact(stall)
		if not Charms.wearing(q, stall["thing"]["id"]):
			fail("a bought charm was not worn")
	print("[charms] %d charms, slots %d" % [all.size(), Charms.slots(q)])

	# Classic: none.
	GameData.force_classic = true
	var c := _start()
	G.enter_room(World.make_room(G.floor_d, "shop", "", "s", { "no_secret": true }))
	for so in G.room.objects:
		if so["kind"] == "shop" and so["item"] == "charm":
			fail("a classic shop sells a charm")
	if Charms.on():
		fail("charms on in classic")
	GameData.force_classic = false

	print("charms test: PASSED" if fails == 0 else "charms test: %d FAILED" % fails)
	get_tree().quit()
