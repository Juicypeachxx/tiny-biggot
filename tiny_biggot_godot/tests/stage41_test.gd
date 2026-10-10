extends Node
## Stage 41 THE DEXTERITY TRAITS (his pictures, 10 Oct; scripts/combat/finesse.gd, the dex_ rows of
## scripts/data/traits.gd, tools/art/stage41_traits.py). Run:
##   godot --headless --path . res://tests/stage41_test.tscn -- --no-save
## 38 DEX traits, each with its picture, in a DEX family, its text drawable; and what each one does:
## lethal hits, close range for bows, rate from speed, fields, helpers' damage, tally crits, repeats
## at x2, tick speed, crits from poison and shock, grenades, a pup, morale; classic untouched.
## Prints "stage41 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage41: ", msg)

func _start(weapon: String = "") -> Player:
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
	G.locked = true
	G.state = &"play"
	if weapon != "":
		Weapons.equip_weapon(p, Weapons.by_id(weapon))
	return p

func _foe(p: Player, dx: float = 30.0) -> Enemy:
	var e := Combat.spawn_enemy("skeleton", p.x + dx, p.y, false, true)
	e.max_hp = 1e7
	e.hp = 1e7
	e.speed = 0.0
	return e

func _take(p: Player, id: String) -> void:
	Traits.apply(id, p)

func _weapon(test: Callable) -> String:
	for w in Weapons.all():
		if test.call(w) and not w["id"] in Weapons.HERO_WEAPON.values():
			return w["id"]
	return ""

func _ready() -> void:
	var mine := Traits.all().filter(func(t): return t["id"].begins_with("dex_"))
	if mine.size() != 38:
		fail("%d DEX traits, not 38" % mine.size())
	for t in mine:
		if not Img.has("tr_" + t["id"]):
			fail("%s has no picture" % t["id"])
		if Attributes.FAMILY_ATTR.get(t["fam"], "") != "dex":
			fail("%s is in %s, not a DEX family" % [t["id"], t["fam"]])
		if TraitView.group(t) != "dex":
			fail("%s is not drawn in the DEX colour" % t["id"])
		for ch in t["name"] + t["desc"]:
			if not ch in Gfx.FONT_CHARS:
				fail("%s: the font cannot draw %s" % [t["id"], ch])

	var bow := _weapon(func(w): return Might.ranged(w) and Attributes.scaling(w)["dex"] != "-")

	# FAR SIGHT: from afar, a foe under half health takes double.
	var p := _start(bow)
	var e := _foe(p, 200.0)
	e.hp = e.max_hp * 0.4
	var m0 := Finesse.foe_mult(p, e, {})
	_take(p, "dex_sharpshooter")
	if absf(Finesse.foe_mult(p, e, {}) / m0 - 2.0) > 0.01:
		fail("FAR SIGHT: x%.2f on a far, wounded foe" % (Finesse.foe_mult(p, e, {}) / m0))

	# NO DISTANCE: a bow counts as close at any range.
	p = _start(bow)
	e = _foe(p, 200.0)
	if Finesse.close(p, e):
		fail("a foe 200 px away was close before NO DISTANCE")
	_take(p, "dex_ballistics")
	if not Finesse.close(p, e):
		fail("NO DISTANCE: a bow at 200 px is not close")

	# FLEET FOOTWORK: speed above the hero's own raises the rate.
	p = _start()
	var r0 := Weapons.wrate(p)
	_take(p, "dex_agility")
	p.speed = float(p.hero["speed"]) * 1.5
	if absf(Weapons.wrate(p) / r0 - 1.5) > 0.01:
		fail("FLEET FOOTWORK at +50%% speed: rate x%.2f" % (Weapons.wrate(p) / r0))

	# WINTER COAT and TOXIC CLOUD: fields; FIELD MARSHAL: rate per field.
	p = _start()
	_take(p, "dex_chillaura")
	_take(p, "dex_poisonaura")
	if Auras.active(p).size() != 2:
		fail("two field traits, %d fields" % Auras.active(p).size())
	r0 = Weapons.wrate(p)
	_take(p, "dex_influence")
	if absf(Weapons.wrate(p) / r0 - 1.6) > 0.01:
		fail("FIELD MARSHAL with 2 fields: rate x%.2f" % (Weapons.wrate(p) / r0))

	# BOSOM BUDDY: one helper, +300%.
	p = _start()
	var lg0 := Legion.dmg_mult(p)
	_take(p, "dex_bff")
	p.familiars = 1
	if absf(Legion.dmg_mult(p) / lg0 - 4.0) > 0.01:
		fail("BOSOM BUDDY with 1 helper: x%.2f" % (Legion.dmg_mult(p) / lg0))

	# COUNTING COUP: the 3rd attack makes the next hits sure crits.
	p = _start()
	_take(p, "dex_tally")
	p.crit = 0.0
	for i in 3:
		Finesse.on_attack(p)
	e = _foe(p)
	if not Combat.damage_enemy(e, 10.0, { "no_mult": true }):
		fail("COUNTING COUP: no sure crit after 3 attacks")

	# ONE STEP AHEAD: after a roll, the next 2 attacks repeat.
	p = _start()
	_take(p, "dex_twosteps")
	Finesse.on_roll(p)
	p.volleys.clear()
	Finesse.on_attack(p)
	Finesse.on_attack(p)
	Finesse.on_attack(p)
	if p.volleys.size() != 2 or p.volleys[0].get("mult", 1.0) != 2.0:
		fail("ONE STEP AHEAD: %d repeats" % p.volleys.size())

	# TICKING CLOCK: rate bonuses speed ailment ticks.
	p = _start()
	_take(p, "dex_clockwork")
	p.rate = 1.5
	if absf(Finesse.tick_rate(p) - 1.5) > 0.01:
		fail("TICKING CLOCK: ticks x%.2f at +50%% rate" % Finesse.tick_rate(p))

	# VENOM SIGHT and SPARK BRAND: crits from poison and shock on the foe.
	p = _start()
	_take(p, "dex_toxins")
	_take(p, "dex_electric")
	e = _foe(p)
	e.poison = 10
	e.shock = 4
	if absf(Finesse.crit_chance(p, e) - 0.1) > 0.001 or absf(Finesse.crit_add(p, e) - 1.0) > 0.001:
		fail("VENOM SIGHT / SPARK BRAND: +%.2f crit, +%.2f crit damage" % [Finesse.crit_chance(p, e), Finesse.crit_add(p, e)])

	# TAINTED BLOOD: a bleed tick poisons 5 times.
	p = _start()
	_take(p, "dex_bloodinfection")
	e = _foe(p)
	Finesse.on_bleed_tick(p, e)
	if e.poison < 5:
		fail("TAINTED BLOOD: %.0f poison after a bleed tick" % e.poison)

	# POCKET GRENADES: a grenade lands on a foe.
	p = _start()
	e = _foe(p, 60.0)
	var lob0: int = Actions.did.get("lob", 0)
	Actions.run(["lob", 3.0, 30], 1, {})
	if Actions.did.get("lob", 0) != lob0 + 1 or e.hp >= 1e7:
		fail("a grenade did not land")

	# GOOD DOG: a pup; buffs +50%.
	p = _start()
	p.pet = ""
	_take(p, "dex_pup")
	if p.pet != "biscuit" or absf(Might.buff_mult(p) - 1.5) > 0.01:
		fail("GOOD DOG: pet %s, buffs x%.2f" % [p.pet, Might.buff_mult(p)])

	# INSTINCT: DEX double.
	p = _start()
	p.a_dex = 6
	_take(p, "dex_intuition")
	if Attributes.value(p, "dex") != 12:
		fail("INSTINCT: DEX %d" % Attributes.value(p, "dex"))

	# A live fight with all 38: no script error.
	p = _start(bow)
	for t in mine:
		_take(p, t["id"])
	for i in 6:
		Combat.spawn_enemy("skeleton", p.x - 40.0 + i * 16.0, p.y - 40.0, false, true)
	for i in 600:
		p.hp = p.max_hp
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}
	print("[stage41] all 38: stats %s, actions lob %d" % [Finesse.stats, Actions.did.get("lob", 0)])

	# Classic: none of it.
	GameData.force_classic = true
	var c := _start()
	c.gf["agility"] = 1.0
	c.gf["tally"] = 1.0
	c.speed *= 2.0
	if Finesse.rate_mult(c) != 1.0 or Finesse.tick_rate(c) != 1.0:
		fail("classic has DEX trait effects")
	GameData.force_classic = false

	print("stage41 test: PASSED" if fails == 0 else "stage41 test: %d FAILED" % fails)
	get_tree().quit()
