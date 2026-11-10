extends Node
## 35.1 DICE (scripts/game/dice.gd). Run:
##   godot --headless --path . res://tests/dice_test.tscn -- --no-save
## A run starts with 2 REROLL, 1 ALTER and 1 BANISH die; ALTER changes one row of a trait pick or a
## relic choice, BANISH also keeps it out for the rest of the run (picks, chests, drops); REROLL
## changes every row; the backpack's items change too; the shop's DICE CUP restocks the shop; dice
## are picked up; FIXED ODDS, HOUSE RULES, HIGH ROLLER and KNUCKLEBONES do what they say; the keys
## (and taps) reach the dice; classic is untouched.
## Prints "dice test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL dice: ", msg)

func _start() -> Player:
	G.hero_index = 0
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
	G.state = &"play"
	return p

func _ids(arr: Array) -> Array:
	return arr.map(func(x): return x["id"])

func _ready() -> void:
	var p := _start()
	if p.rerolls != 2 or p.alters != 1 or p.banishes != 1:
		fail("a run starts with %d/%d/%d dice, not 2/1/1" % [p.rerolls, p.alters, p.banishes])

	# --- the trait pick ---
	p.level = 4
	p.pending = 1
	G.offer_traits()
	var before := _ids(G.tchoice["opts"])
	G.tchoice["idx"] = 0
	if not Dice.trait_row(false):
		fail("ALTER on a trait pick did nothing")
	var after := _ids(G.tchoice["opts"])
	if after[0] == before[0] or after.slice(1) != before.slice(1):
		fail("ALTER should change the chosen row only: %s -> %s" % [before, after])
	if p.alters != 0:
		fail("ALTER die not spent")
	if Dice.trait_row(false):
		fail("ALTER with no die left worked")
	var gone: String = after[1]
	G.tchoice["idx"] = 1
	if not Dice.trait_row(true):
		fail("BANISH on a trait pick did nothing")
	if not p.banished.has(gone) or p.banishes != 0:
		fail("BANISH did not keep %s out or was not spent" % gone)
	for i in 60:
		G.offer_traits()
		if _ids(G.tchoice["opts"]).has(gone):
			fail("a banished trait came back")
			break
	G.tchoice = {}
	G.state = &"play"
	p.pending = 0

	# --- the relic choice ---
	Dice.give(p, "alter", 1)
	Dice.give(p, "banish", 1)
	G.open_choice("chest", { "x": 200.0, "y": 150.0 })
	if G.state != &"choice":
		fail("no relic choice opened")
	else:
		var r0 := _ids(G.choice["relics"])
		var rr := p.rerolls
		if not Dice.choice_reroll():
			fail("REROLL on a relic choice did nothing")
		var r1 := _ids(G.choice["relics"])
		for id in r1:
			if id in r0:
				fail("REROLL kept %s" % id)
		if p.rerolls != rr - 1:
			fail("REROLL die not spent on a relic choice")
		G.choice["idx"] = 0
		Dice.choice_row(false)
		var r2 := _ids(G.choice["relics"])
		if r2[0] == r1[0]:
			fail("ALTER did not change the chosen relic")
		var rgone: String = r2[0]
		Dice.choice_row(true)
		if not p.banished.has(rgone):
			fail("BANISH did not keep the relic out")
		for i in 80:
			if _ids(G.roll_relics(4, "chest")).has(rgone):
				fail("a banished relic came back")
				break
		# Out of REROLL dice: gold pays, as the old trait reroll did.
		p.rerolls = 0
		p.gold = 500
		var cost := G.reroll_cost()
		Dice.choice_reroll()
		if p.gold != 500 - cost:
			fail("a reroll with no die should cost %d gold (gold %d)" % [cost, p.gold])
	G.choice = {}
	G.state = &"play"

	# --- the backpack ---
	p.backpack.clear()
	var w := Weapons.by_id("thoughtstone").duplicate()
	w["plus"] = 3
	p.backpack.append(w)
	p.backpack.append(Gear.by_id("marchingboots"))
	Dice.give(p, "alter", 2)
	G.inv_i = 0
	Dice.item_row(false)
	var w2: Dictionary = p.backpack[0]
	if w2["id"] == "thoughtstone" or w2["item"] != "weapon" or w2["rarity"] != w["rarity"] or WeaponInfo.plus(w2) != 3:
		fail("ALTER on a weapon: %s %s +%d" % [w2["id"], w2["rarity"], WeaponInfo.plus(w2)])
	G.inv_i = 1
	Dice.item_row(false)
	var g2: Dictionary = p.backpack[1]
	if g2["id"] == "marchingboots" or g2["slot"] != "feet":
		fail("ALTER on gear should give other feet gear, got %s (%s)" % [g2["id"], g2.get("slot", "")])
	Dice.give(p, "banish", 1)
	var bgone: String = g2["id"]
	Dice.item_row(true)
	if not p.banished.has(bgone) or p.backpack[1]["id"] == bgone:
		fail("BANISH on gear")
	for i in 200:
		if Gear.random_gear(g2["rarity"])["id"] == bgone:
			fail("banished gear dropped again")
			break

	# --- the shop's DICE CUP ---
	G.enter_room(World.make_room(G.floor_d, "shop", "", "s", { "no_secret": true }))
	var cup = null
	var sold := []
	var die_sale = null
	for o in G.room.objects:
		if o["kind"] == "dicecup":
			cup = o
		if o["kind"] == "shop" and o["item"] == "relic":
			sold.append(o["relic"]["id"])
		if o["kind"] == "shop" and o["item"] == "die":
			die_sale = o
	if cup == null or die_sale == null:
		fail("a shop has no DICE CUP or no die for sale")
	else:
		p.rerolls = 1
		G.interact(cup)
		var now := []
		for o in G.room.objects:
			if o["kind"] == "shop" and o["item"] == "relic":
				now.append(o["relic"]["id"])
		if now == sold or p.rerolls != 0:
			fail("the DICE CUP did not restock (%s -> %s, dice %d)" % [sold, now, p.rerolls])
		p.gold = 999
		var had := Dice.count(p, die_sale["die"])
		G.interact(die_sale)
		if Dice.count(p, die_sale["die"]) != had + 1:
			fail("buying a die gave nothing")

	# --- picked up ---
	var a0 := p.alters
	var k := Combat.drop_pickup("die_alter", p.x, p.y)
	k.vx = 0.0
	k.vy = 0.0
	k.vz = 0.0
	k.t = 1.0
	Combat.update_pickups(TB.DT)
	if p.alters != a0 + 1:
		fail("an ALTER die on the floor was not picked up")

	# --- traits and relics ---
	p.gf["dice_back"] = 1.0
	p.alters = 1
	p.pending = 1
	G.offer_traits()
	G.tchoice["idx"] = 0
	Dice.trait_row(false)
	if p.alters != 1:
		fail("FIXED ODDS at 100% should give the die back")
	p.gf["dice_back"] = 0.0
	Effects.apply(p, Traits.by_id("d_houserules")["effects"], 1, "trait:d_houserules")
	var g0 := p.gold
	Dice.trait_row(false)
	if p.gold != g0 + 6:
		fail("HOUSE RULES: %d gold for a die, not 6" % (p.gold - g0))
	Effects.apply(p, Relics.by_id("knucklebones")["effects"], 1, "relic:knucklebones")
	p.hp = 2
	Dice.trait_row(false)
	if p.hp != 3:
		fail("KNUCKLEBONES did not heal (hp %d)" % p.hp)
	G.tchoice = {}
	G.state = &"play"
	p.pending = 0

	# --- the keys reach the dice ---
	p.alters = 1
	p.pending = 1
	G.offer_traits()
	G.tchoice["t0"] = G.time - 10.0
	var k0 := _ids(G.tchoice["opts"])
	Taps.send(&"heal")
	await get_tree().process_frame
	Keys.tick()
	G.update_traits()
	if p.alters != 0 or _ids(G.tchoice.get("opts", [])) == k0:
		fail("HEAL on a trait pick did not throw the ALTER die")
	G.tchoice = {}
	G.state = &"play"

	# --- classic ---
	GameData.force_classic = true
	var c := _start()
	if c.alters != 0 or c.banishes != 0:
		fail("classic starts with dice")
	var cs := World.make_room(G.floor_d, "shop", "", "s", { "no_secret": true })
	G.enter_room(cs)
	for o in cs.objects:
		if o["kind"] == "dicecup" or (o["kind"] == "shop" and o["item"] == "die"):
			fail("a classic shop has dice")
			break
	GameData.force_classic = false

	print("dice: used %s" % Dice.stats)
	print("dice test: PASSED" if fails == 0 else "dice test: %d FAILED" % fails)
	get_tree().quit()
