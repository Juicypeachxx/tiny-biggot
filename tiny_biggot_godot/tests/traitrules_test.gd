extends Node
## 41.5 HOW TRAITS WORK (his text, 10 Oct; asked, he chose a limit of 12; scripts/game/trait_rules.gd).
## Run:   godot --headless --path . res://tests/traitrules_test.tscn -- --no-save
## At most 12 different traits (the oath not counted); with 12 a pick offers only your own traits
## that can rank up, and stat points for the rest; traits that need a shield or a kind of weapon;
## trait tomes: learn one, swap one (the old trait's effects come off), pay for one; the tome
## screen's taps; classic untouched.
## Prints "traitrules test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL traitrules: ", msg)

func _start(weapon: String = "") -> Player:
	G.hero_index = 0
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = true
	var p := G.player
	p.oath_picks = 0
	p.special_picks = 0
	p.pending = 0
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.enemies.clear()
	G.locked = true
	G.state = &"play"
	G.tchoice = {}
	if weapon != "":
		Weapons.equip_weapon(p, Weapons.by_id(weapon))
	return p

func _learn(p: Player, id: String) -> void:
	p.pending += 1
	G.take_trait(Traits.by_id(id))

func _weapon(test: Callable) -> String:
	for w in Weapons.all():
		if test.call(w) and not w["id"] in Weapons.HERO_WEAPON.values():
			return w["id"]
	return ""

func _ready() -> void:
	# Twelve plain traits of one rank each, and VITALITY (core, 3 ranks, +1 max heart a rank).
	var plain := Traits.all().filter(func(t): return t["id"].begins_with("dex_") and t["max"] == 1 and not TraitRules.NEEDS.has(t["id"]) and t["id"] != "dex_pup")
	if plain.size() < 13:
		fail("only %d plain DEX traits" % plain.size())

	# THE LIMIT: 12, then only your own; all at their top rank, stat points.
	var p := _start()
	for i in 12:
		_learn(p, plain[i]["id"])
	if TraitRules.counted(p) != 12 or not TraitRules.full(p):
		fail("12 traits taken, %d counted" % TraitRules.counted(p))
	for c in G.trait_cands(p, ""):
		if not p.traits.has(c[0]["id"]):
			fail("a new trait (%s) offered with 12" % c[0]["id"])
			break
	for c in G.trait_cands(p, "special"):
		if not p.traits.has(c[0]["id"]) and c[0]["rarity"] != "oath":   # an oath does not count
			fail("a grimoire offered a new trait (%s) with 12" % c[0]["id"])
			break
	p.traits["o_flame"] = 1   # the run's oath does not count
	if TraitRules.counted(p) != 12:
		fail("the oath counts toward the limit")
	p.traits.erase("o_flame")
	p.pending = 1
	G.offer_traits()
	var opts: Array = G.tchoice.get("opts", [])
	if opts.size() != 3 or not opts.all(func(o): return o.has("stat")):
		fail("all 12 at their top rank: the pick is %s" % str(opts.map(func(o): return o["id"])))
	else:
		var st: String = opts[0]["stat"]
		var a0: int = p.get("a_" + st)
		G.take_trait(opts[0])
		if p.get("a_" + st) != a0 + 1 or p.pending != 0:
			fail("a stat point: %s %d -> %d, pending %d" % [st, a0, p.get("a_" + st), p.pending])
	G.state = &"play"
	G.tchoice = {}

	# With 12, one of them able to rank up: it, and two stat points.
	p = _start()
	_learn(p, "vitality")
	for i in 11:
		_learn(p, plain[i]["id"])
	p.pending = 1
	G.offer_traits()
	opts = G.tchoice.get("opts", [])
	var ids: Array = opts.map(func(o): return o["id"])
	if opts.size() != 3 or ids[0] != "vitality" or not opts[1].has("stat") or not opts[2].has("stat"):
		fail("12 traits, VITALITY can rank up: the pick is %s" % str(ids))
	G.state = &"play"
	G.tchoice = {}

	# CONDITIONS: HOLD THE LINE wants a shield; NO DISTANCE a bow or gun.
	var melee := _weapon(func(w): return Might.melee(w))
	var bow := _weapon(func(w): return Might.ranged(w))
	p = _start(melee)
	var wall := Traits.by_id("str_shieldwall")
	if G.trait_weight(p, wall) != 0:
		fail("HOLD THE LINE offered without a shield")
	Gear.equip_gear(p, Gear.by_id("o_buckler"))
	if G.trait_weight(p, wall) <= 0:
		fail("HOLD THE LINE not offered with a shield")
	if G.trait_weight(p, Traits.by_id("dex_ballistics")) != 0:
		fail("NO DISTANCE offered with a melee weapon")
	Weapons.equip_weapon(p, Weapons.by_id(bow))
	if G.trait_weight(p, Traits.by_id("dex_ballistics")) <= 0:
		fail("NO DISTANCE not offered with a bow")

	# TOMES: swap with 12; the old trait's effects come off.
	p = _start()
	_learn(p, "vitality")
	_learn(p, "vitality")
	for i in 11:
		_learn(p, plain[i]["id"])
	var hp0 := p.max_hp
	var agi_had := p.traits.has("dex_agility")
	var newt: Dictionary = plain[12]
	var o := { "kind": "ttome", "trait": newt["id"], "x": p.x + 20.0, "y": p.y }
	G.room.objects.append(o)
	TraitRules.open_tome(o)
	if G.state != &"tome" or not TraitRules.must_swap(p, o):
		fail("a tome with 12 traits does not ask for a swap")
	var list := TraitRules.swap_list(p)
	if list.size() != 12:
		fail("%d traits to give up, not 12" % list.size())
	G.tome_i = list.find(Traits.by_id("vitality"))
	var zones := Taps.zones()
	if zones.size() != 14:
		fail("the tome screen has %d tap zones, not 12 cubes and 2 buttons" % zones.size())
	TraitRules.read(p, o, list)
	if p.traits.has("vitality") or not p.traits.has(newt["id"]) or TraitRules.counted(p) != 12:
		fail("the swap: vitality %s, %s %s, %d traits" % [p.traits.has("vitality"), newt["id"], p.traits.has(newt["id"]), TraitRules.counted(p)])
	if p.max_hp != hp0 - 4:
		fail("VITALITY 2 gone, max health %d (was %d)" % [p.max_hp, hp0])
	if p.fam.has("core"):
		fail("the core family still counts %d" % p.fam["core"])
	if not o.get("gone", false) or G.state != &"play":
		fail("the tome stays after reading")
	# a hook comes off too
	if agi_had:
		var o2 := { "kind": "ttome", "trait": "dex_alacrity", "x": p.x, "y": p.y }
		TraitRules.open_tome(o2)
		var l2 := TraitRules.swap_list(p)
		G.tome_i = l2.find(Traits.by_id("dex_agility"))
		TraitRules.read(p, o2, l2)
		if p.g("agility") != 0.0:
			fail("FLEET FOOTWORK swapped away, its hook is %.1f" % p.g("agility"))

	# A tome with room: learn it. A tome for sale: pay first.
	p = _start()
	var o3 := { "kind": "ttome", "trait": plain[0]["id"], "x": p.x, "y": p.y, "price": 30 }
	p.gold = 5
	TraitRules.open_tome(o3)
	TraitRules.read(p, o3, TraitRules.swap_list(p))
	if p.traits.has(plain[0]["id"]) or p.gold != 5 or G.state != &"play":
		fail("a tome read without the gold")
	p.gold = 50
	TraitRules.open_tome(o3)
	TraitRules.read(p, o3, TraitRules.swap_list(p))
	if not p.traits.has(plain[0]["id"]) or p.gold != 20:
		fail("a bought tome: learned %s, gold %d" % [p.traits.has(plain[0]["id"]), p.gold])
	var n0 := G.room.objects.size()
	TraitRules.place_tome(G.room, 100.0, 100.0)
	if G.room.objects.size() != n0 + 1 or not Traits.has(G.room.objects[n0].get("trait", "")):
		fail("place_tome made no tome")

	# Classic: no limit, no conditions, no tomes.
	GameData.force_classic = true
	var c := _start()
	for i in 12:
		c.traits[plain[i]["id"]] = 1
	if TraitRules.full(c) or not TraitRules.allowed(c, Traits.by_id("str_shieldwall")):
		fail("classic has the limit or the conditions")
	GameData.force_classic = false

	print("traitrules test: PASSED" if fails == 0 else "traitrules test: %d FAILED" % fails)
	get_tree().quit()
