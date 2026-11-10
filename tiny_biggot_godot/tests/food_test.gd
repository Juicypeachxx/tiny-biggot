extends Node
## Stage 36 FOOD AND DRINK (scripts/game/food.gd). Run:
##   godot --headless --path . res://tests/food_test.tscn -- --no-save
## Every food and golden food is picked up and gives what it says, and some XP; rooms can promise
## food (and golden food on the deepest floors); a shop sells a food; drinks give a buff for 10
## rooms, three at once (the cheese makes it four), the oldest pushed out; HOLLOW LEG keeps them;
## the GILDED LOAF and the STAR JELLY hit harder; classic is untouched.
## Prints "food test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL food: ", msg)

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

func _pick(p: Player, kind: String) -> void:
	var k := Combat.drop_pickup(kind, p.x, p.y)
	k.vx = 0.0
	k.vy = 0.0
	k.vz = 0.0
	k.t = 1.0
	Combat.update_pickups(TB.DT)

func _attrs(p: Player) -> Array:
	return [p.a_str, p.a_dex, p.a_int]

func _ready() -> void:
	var p := _start()
	# --- food ---
	for kind in Food.FOODS:
		var a0 := _attrs(p)
		var lv0 := p.level
		var xp0 := p.xp
		var slots0 := Food.slots(p)
		_pick(p, kind)
		var a1 := _attrs(p)
		var gained: int = (a1[0] - a0[0]) + (a1[1] - a0[1]) + (a1[2] - a0[2])
		if kind == "f_cheese":
			if Food.slots(p) != slots0 + 1:
				fail("the cheese did not add a drink buff slot")
		elif gained < 1:
			fail("%s gave no attribute (%s -> %s)" % [kind, a0, a1])
		if p.level == lv0 and p.xp <= xp0:
			fail("%s gave no XP" % kind)
	# --- golden food ---
	var crit0 := p.crit
	_pick(p, "gf_sunfruit")
	if absf(p.crit - crit0 - 0.03) > 0.0001:
		fail("SUNFRUIT: crit %.3f -> %.3f" % [crit0, p.crit])
	var hp0 := p.max_hp
	_pick(p, "gf_date")
	if p.max_hp != hp0 + 2:
		fail("DRAGON DATE: max hp %d -> %d" % [hp0, p.max_hp])
	for kind in Food.GOLDEN:
		if kind in ["gf_sunfruit", "gf_date"]:
			continue
		_pick(p, kind)
	if p.g("nocrit_dmg") <= 0 or p.g("proc_dmg") <= 0 or p.g("lucky") <= 0 or p.g("minion_dmg") <= 0:
		fail("golden food hooks missing: %s" % p.gf)
	# The GILDED LOAF: a hit that does not crit lands 10% harder.
	var e := Combat.spawn_enemy("skeleton", p.x + 60, p.y, false, true)
	e.max_hp = 1e9
	e.hp = 1e9
	var gf_keep: float = p.gf["nocrit_dmg"]
	var plain := 0.0
	var loaf := 0.0
	for i in 400:   # (hits roll within a damage range: an average; 40 pairs missed by luck about 1 run in 60)
		p.gf["nocrit_dmg"] = 0.0
		e.hp = 1e9
		Combat.damage_enemy(e, 100.0, { "no_crit": true, "silent": true })
		plain += 1e9 - e.hp
		p.gf["nocrit_dmg"] = gf_keep
		e.hp = 1e9
		Combat.damage_enemy(e, 100.0, { "no_crit": true, "silent": true })
		loaf += 1e9 - e.hp
	if absf(loaf / plain - (1.0 + gf_keep)) > 0.04:
		fail("GILDED LOAF: %.1f vs %.1f (x%.3f)" % [loaf, plain, loaf / plain])
	G.enemies.erase(e)

	# --- rewards ---
	var seen := {}
	for i in 400:
		seen[World.roll_reward(p)] = true
	if not seen.has("food"):
		fail("no room promised food")
	if seen.has("golden"):
		fail("golden food promised on floor 3")
	G.floor_index = Food.GOLDEN_FLOOR
	seen = {}
	for i in 400:
		seen[World.roll_reward(p)] = true
	if not seen.has("golden"):
		fail("no golden food promised on the deep floors")
	G.floor_index = 2
	var n0 := G.pickups.size()
	G.give_reward("food")
	if G.pickups.size() < n0 + 2:
		fail("a food reward left %d pickups" % (G.pickups.size() - n0))

	# --- the shop ---
	G.enter_room(World.make_room(G.floor_d, "shop", "", "s", { "no_secret": true }))
	var stall = null
	for o in G.room.objects:
		if o["kind"] == "shop" and o["item"] == "food":
			stall = o
	if stall == null:
		fail("no food for sale in the shop")
	else:
		p.gold = 999
		var a0 := _attrs(p)
		var s0 := Food.slots(p)
		G.interact(stall)
		if _attrs(p) == a0 and Food.slots(p) == s0:
			fail("buying %s gave nothing" % stall["food"])

	# --- drinks ---
	p.drinks.clear()
	p.gf["drink_slots"] = 0.0
	var dmg0 := p.dmg
	var rate0 := p.rate
	p.belt.clear()
	for k in ["c_ale", "c_cider", "c_wine"]:
		p.belt.append(k)
		Consumables.use(p, 0)
	if p.drinks.size() != 3:
		fail("3 drinks should give 3 buffs, not %d" % p.drinks.size())
	if absf(p.rate / rate0 - 1.1) > 0.001:
		fail("CIDER: rate x%.3f" % (p.rate / rate0))
	p.belt.append("c_grog")
	Consumables.use(p, 0)
	if p.drinks.size() != 3 or p.drinks[0][0] != "c_cider":
		fail("a 4th drink should push the ALE out: %s" % [p.drinks.map(func(d): return d[0])])
	# Ten rooms later they have worn off, and what they gave is gone.
	for i in Food.ROOMS:
		G.enter_room(World.make_room(G.floor_d, "treasure", "", "s", { "no_secret": true }))
	if not p.drinks.is_empty():
		fail("drink buffs did not wear off: %s" % [p.drinks])
	if absf(p.rate - rate0) > 0.0001 or absf(p.dmg - dmg0) > 0.0001:
		fail("a worn off buff left something: rate %.3f -> %.3f, dmg %.3f -> %.3f" % [rate0, p.rate, dmg0, p.dmg])
	# HOLLOW LEG: they stay.
	Effects.apply(p, Traits.by_id("j_hollowleg")["effects"], 1, "trait:j_hollowleg")
	p.belt.append("c_stout")
	Consumables.use(p, 0)
	for i in Food.ROOMS + 2:
		G.enter_room(World.make_room(G.floor_d, "treasure", "", "s", { "no_secret": true }))
	if p.drinks.size() != 1:
		fail("HOLLOW LEG: the buff wore off")
	print("[food] %s" % Food.stats)

	# --- classic ---
	GameData.force_classic = true
	var c := _start()
	seen = {}
	for i in 400:
		seen[World.roll_reward(c)] = true
	if seen.has("food") or seen.has("golden"):
		fail("classic rooms promise food")
	GameData.force_classic = false

	print("food test: PASSED" if fails == 0 else "food test: %d FAILED" % fails)
	get_tree().quit()
