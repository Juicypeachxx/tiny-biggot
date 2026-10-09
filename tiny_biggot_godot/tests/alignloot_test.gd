extends Node
## Stage 38 ALIGNMENT AND LOOT (scripts/game/alignments.gd 38.1 part, scripts/game/loot.gd). Run:
##   godot --headless --path . res://tests/alignloot_test.tscn -- --no-save
## Some heroes start aligned; vendors are cheaper for a matching alignment and dearer for the
## opposite; 3 GOOD or 3 EVIL choose the soul gate; a WAYSHRINE sells alignment; four pieces grow
## with an alignment; LUCK gives lucky hits; MAGIC FIND makes rarer items; TREASURE FIND makes
## more; classic is untouched.
## Prints "alignloot test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL alignloot: ", msg)

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
	G.enter_room(World.make_room(G.floor_d, "treasure", "", "s", { "no_secret": true }))
	G.room.objects.clear()
	G.state = &"play"
	return p

func _reset_al(p: Player) -> void:
	for k in Alignments.KEYS:
		p.set("al_" + k, 0)

func _ready() -> void:
	# Heroes that start aligned.
	for pair in [["bonecaller", "evil", 2], ["pilgrim", "good", 2], ["jester", "chaos", 1]]:
		var hp := _start(pair[0])
		if Alignments.value(hp, pair[1]) < pair[2]:
			fail("%s starts with %d %s, not %d" % [pair[0], Alignments.value(hp, pair[1]), pair[1], pair[2]])
	var p := _start("brute")
	_reset_al(p)
	# Vendors.
	Alignments.add(p, "good", 2)
	if absf(Alignments.price_mult(p, "good") - 0.7) > 0.001 or absf(Alignments.price_mult(p, "evil") - 1.4) > 0.001 \
			or absf(Alignments.price_mult(p, "law") - 1.0) > 0.001:
		fail("vendor prices for 2 GOOD: good x%.2f, evil x%.2f, law x%.2f" % [Alignments.price_mult(p, "good"),
			Alignments.price_mult(p, "evil"), Alignments.price_mult(p, "law")])
	var plain := G.price(100)
	if absf(float(G.price(100, "good")) / plain - 0.7) > 0.03:
		fail("a GOOD vendor charges %d of %d" % [G.price(100, "good"), plain])
	# The soul gate: items decide, unless 3 GOOD or 3 EVIL do.
	_reset_al(p)
	var by_items := Soul.realm(p)
	Alignments.add(p, "good", 3)
	if Soul.realm(p) != "heaven":
		fail("3 GOOD did not open Heaven")
	Alignments.add(p, "evil", 5)
	if Soul.realm(p) != "hell":
		fail("5 EVIL over 3 GOOD did not open Hell")
	_reset_al(p)
	if Soul.realm(p) != by_items:
		fail("with no strong alignment, the items no longer decide")
	# The WAYSHRINE.
	Alignments.wayshrine(G.room)
	var shrines := G.room.objects.filter(func(o): return o["kind"] == "alwayshrine")
	if shrines.size() < 2:
		fail("a wayshrine with %d offerings" % shrines.size())
	else:
		G.room.objects.append({ "kind": "soulgate", "x": 100.0, "y": 100.0, "realm": "hell", "light": 0, "dark": 9 })
		p.gold = 999
		var law0 := Alignments.value(p, "law")
		var s0: Dictionary = shrines.filter(func(o): return o["al"] == "law")[0]
		G.interact(s0)
		if Alignments.value(p, "law") != law0 + 1 or p.gold != 999 - s0["price"]:
			fail("buying LAWFUL at a wayshrine: law %d, gold %d" % [Alignments.value(p, "law"), p.gold])
		G.interact(s0)
		if Alignments.value(p, "law") != law0 + 1:
			fail("a wayshrine offering sold twice")
		Meta.meta["heaven_wins"] = 1
		if not Alignments.offered().has("good"):
			fail("Heaven's ruler beaten, but no GOOD offering")
		Alignments.add(p, "good", 3)
		for o in G.room.objects:
			if o["kind"] == "alwayshrine" and o["al"] == "chaos":
				G.interact(o)
		var gate: Dictionary = G.room.objects.filter(func(o): return o["kind"] == "soulgate")[0]
		if gate["realm"] != "heaven":
			fail("the soul gate did not look again after a wayshrine")
	# Gear that grows with an alignment.
	_reset_al(p)
	var d0 := Weapons.wdmg(p)
	var r0 := Weapons.wrate(p)
	Gear.equip_gear(p, Gear.by_id("saintsigil"))
	Gear.equip_gear(p, Gear.by_id("magistrateseal"))
	Alignments.add(p, "good", 4)
	Alignments.add(p, "law", 5)
	if absf(Weapons.wdmg(p) / d0 - 1.2) > 0.01:
		fail("SAINT'S SIGIL with 4 GOOD: damage x%.3f, not x1.2" % (Weapons.wdmg(p) / d0))
	if absf(Weapons.wrate(p) / r0 - 1.2) > 0.01:
		fail("MAGISTRATE'S SEAL with 5 LAWFUL: rate x%.3f, not x1.2" % (Weapons.wrate(p) / r0))
	# LUCK gives lucky hits.
	var l0 := Lucky.chance(p)
	p.luck += 5
	if absf(Lucky.chance(p) - l0 - 0.1) > 0.001:
		fail("5 LUCK gave %.3f lucky hits, not 0.10" % (Lucky.chance(p) - l0))
	# MAGIC FIND: fewer commons.
	var commons := [0, 0]
	for k in 2:
		p.gf["magic_find"] = 0.0 if k == 0 else 1.0
		for i in 2000:
			if Gear.roll_item_rarity(0) == "common":
				commons[k] += 1
	if commons[1] >= commons[0] * 0.85:
		fail("MAGIC FIND +100%%: %d commons in 2000, %d without" % [commons[1], commons[0]])
	# TREASURE FIND: one more item for sure at 100%, two at 200%.
	p.gf["treasure_find"] = 2.0
	var n0 := G.room.objects.size()
	Loot.treasure(150.0, 150.0)
	if G.room.objects.size() != n0 + 2:
		fail("TREASURE FIND 200%% left %d items" % (G.room.objects.size() - n0))
	print("[alignloot] commons %s, extra items %s" % [commons, Loot.stats])

	# Classic: none of it.
	GameData.force_classic = true
	var c := _start("brute")
	Alignments.add(c, "good", 5)
	if Alignments.price_mult(c, "good") != 1.0 or Alignments.path(c) != "":
		fail("classic alignments changed prices or the path")
	c.gf["treasure_find"] = 5.0
	var cn := G.room.objects.size()
	Loot.treasure(150.0, 150.0)
	if G.room.objects.size() != cn:
		fail("classic got treasure")
	GameData.force_classic = false
	Meta.meta.erase("heaven_wins")

	print("alignloot test: PASSED" if fails == 0 else "alignloot test: %d FAILED" % fails)
	get_tree().quit()
