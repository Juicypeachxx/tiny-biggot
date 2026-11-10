extends Node
## Stage 50 (his word, 11 Oct: "Do stage 50 and 52, also we need to ajust traits and oaths to be more
## random and not repeat soo much when picking traits or rerolling them"). Run:
##   godot --headless --path . res://tests/stage50_test.tscn -- --no-save
## 50.1 PICKS THAT DO NOT REPEAT (G.vary_cands): a reroll shows none of the traits it threw away; over
## 30 picks in a row many different traits come up and none comes back often; the run's oath pick
## leaves out the oaths of the last two runs, and remembers its own for the next.
## 50.2 THE FIVE DAMAGE TYPES (damage_types.gd): each of the 20 weapons has its type; in a live fight
## each type's ailment takes hold and does its thing (a burst, rot, a shade, a discharge, a stun);
## the five new reactions each go off.
## Prints "stage50 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage50: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(50)
	_rerolls()
	_variety()
	_oaths()
	_types()
	_reactions()
	print("stage50 test: PASSED" if fails == 0 else "stage50 test: %d FAILED" % fails)
	get_tree().quit()

func _start(hero: int = 0) -> Player:
	G.hero_index = hero
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
	G.state = &"play"
	return p

## A build already going: three traits of PYRE and three of EDGE (the families then weigh 7x).
func _build(p: Player) -> void:
	var got := { "pyre": 0, "edge": 0 }
	for t in Traits.all():
		if got.has(t["fam"]) and got[t["fam"]] < 3 and t["new"] and t["rarity"] in ["common", "uncommon"]:
			p.pending += 1
			G.take_trait(t)
			got[t["fam"]] += 1
	p.pending = 0

func _ids(opts: Array) -> Array:
	return opts.filter(func(t): return not t.has("stat")).map(func(t): return t["id"])

func _rerolls() -> void:
	var p := _start()
	_build(p)
	p.level = 5
	p.pending = 1
	G.offer_traits()
	var before := _ids(G.tchoice["opts"])
	var again := 0
	for i in 12:
		G.offer_traits(true)
		var now := _ids(G.tchoice["opts"])
		for id in now:
			if before.has(id):
				again += 1
		before = now
	print("[stage50] 12 rerolls: %d traits shown again right after being thrown away" % again)
	if again > 0:
		fail("rerolls showed %d thrown-away traits again" % again)

func _variety() -> void:
	var p := _start()
	_build(p)
	p.level = 5
	var seen := {}
	for i in 30:
		p.pending = 1
		G.offer_traits()
		for id in _ids(G.tchoice["opts"]):
			seen[id] = int(seen.get(id, 0)) + 1
		G.tchoice = {}
	var most := 0
	for id in seen:
		most = maxi(most, seen[id])
	print("[stage50] 30 picks: %d different traits shown, the most often one %d times" % [seen.size(), most])
	if seen.size() < 60:
		fail("only %d different traits in 30 picks" % seen.size())
	if most > 4:
		fail("one trait came up %d times in 30 picks" % most)

func _oaths() -> void:
	var recent := ["o_flame", "o_frost", "o_venom", "o_thunder", "o_blood", "o_swarm"]
	Meta.meta["oaths_last"] = recent.slice(0, 3)
	Meta.meta["oaths_before"] = recent.slice(3, 6)
	G.hero_index = 0
	G.new_run()   # the run's oath pick
	var p := G.player
	G.offer_traits()
	var shown := _ids(G.tchoice["opts"])
	if G.tchoice.get("mode", "") != "oath":
		fail("the run did not open with an oath pick")
	for id in shown:
		if recent.has(id):
			fail("the oath pick showed %s, one of the last two runs' oaths" % id)
	G.take_trait(G.tchoice["opts"][0])
	var last: Array = Meta.meta.get("oaths_last", [])
	for id in shown:
		if not last.has(id):
			fail("the oaths this run showed were not remembered (%s)" % [last])
	if Meta.meta.get("oaths_before", []) != recent.slice(0, 3):
		fail("the run before was not kept as the one before")

const WEAPONS := { "RADIANT": ["sunlance", "halodisc", "morningray", "solarflare"],
	"NECROTIC": ["graverot", "deathknell", "lichfinger", "bonereaper"],
	"DARK": ["nightshiv", "shaderepeater", "umbralmoon", "nightfall"],
	"ENERGY": ["plasmarifle", "arccaster", "fusioncore", "ionblade"],
	"SOUND": ["wardrum", "sonichorn", "singingspear", "bansheebell"] }

func _types() -> void:
	DamageTypes.stats.clear()
	var ail := {}
	for t in WEAPONS:
		for id in WEAPONS[t]:
			var w := Weapons.by_id(id)
			if WeaponInfo.damage_type(w) != t:
				fail("%s is %s, not %s" % [id, WeaponInfo.damage_type(w), t])
			_fight(id, t, ail)
	for k in ["seared", "rot", "gloom", "charged", "rattled"]:
		if not ail.get(k, false):
			fail("no foe ever had %s" % k)
	for k in ["smite", "shade", "discharge", "rattled", "rot", "burst"]:
		if DamageTypes.stats.get(k, 0) <= 0:
			fail("nothing counted for %s (%s)" % [k, DamageTypes.stats])
	print("[stage50] ", DamageTypes.stats)

func _fight(id: String, t: String, ail: Dictionary) -> void:
	var p := _start()
	Weapons.equip_weapon(p, Weapons.by_id(id))
	p.x = 14.0 * TB.TS
	p.y = 12.0 * TB.TS
	var pool: Array = GameData.floors()[G.floor_index]["pool"]
	for i in 300:
		while G.enemies.size() < 6:
			var s := World.free_spot(G.room, p, 40, World.M_FLYER)
			var e := Combat.spawn_enemy(TB.pick(pool), s.x, s.y, false, true)
			e.max_hp *= 4
			e.hp = e.max_hp
			if t == "RADIANT":
				Statuses.apply(e, "curse", 3, 1.0)   # radiant hits deal half again to the cursed
			if t == "DARK":
				Statuses.apply(e, "gloom", 6, 1.0)   # deep gloom may call a shade
		p.hp = p.max_hp
		p.invuln = 1.0
		if i % 10 == 0:
			var f := Combat.auto_target(p, 400)
			var a := TB.ang_to(p, f) if f != null else 0.0
			p.aim_a = a
			p.shot_n += 1
			Combat.player_shoot(p, a, false)
		G.update(TB.DT)
		for e in G.enemies:
			if e.seared_t > 0: ail["seared"] = true
			if e.rot > 0: ail["rot"] = true
			if e.gloom > 0: ail["gloom"] = true
			if e.charge > 0: ail["charged"] = true
			if e.rattle > 0: ail["rattled"] = true
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

func _reactions() -> void:
	var p := _start()
	Reactions.clear()
	Reactions.stats.clear()
	var cases := { "eclipse": func(e): e.seared_t = 2.0; e.gloom = 2; e.gloom_t = 2.0,
		"blight": func(e): e.rot = 2; e.rot_t = 2.0; e.poison = 3.0,
		"superconduct": func(e): e.charge = 2; e.charge_t = 2.0; e.shock = 2; e.shock_t = 2.0,
		"crackle": func(e): e.rattle = 2; e.rattle_t = 2.0; e.chill_t = 2.0,
		"feedback": func(e): e.rattle = 2; e.rattle_t = 2.0; e.charge = 2; e.charge_t = 2.0 }
	var x := 0.0
	for r in cases:
		var e := Combat.spawn_enemy("slime", p.x + 60.0 + x, p.y, false, true)
		x += 30.0
		e.max_hp = 1e6
		e.hp = 1e6
		cases[r].call(e)
		Reactions.check(e)
		if Reactions.stats.get(r, 0) != 1:
			fail("the %s reaction did not go off (%s)" % [r, Reactions.stats])
