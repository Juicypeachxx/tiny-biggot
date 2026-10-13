extends Node
## Stage 42 THE INTELLIGENCE TRAITS (his pictures, 10 Oct; scripts/combat/arcana.gd, the int_ rows of
## scripts/data/traits.gd, tools/art/stage42_traits.py). Run:
##   godot --headless --path . res://tests/stage42_test.tscn -- --no-save
## 38 INT traits, each with its picture, in an INT family, its text drawable; and what each one does:
## crits on bleeding foes, meteors from the special, lucky hits that strike more, poison that bleeds
## or leaves foes vulnerable, fields 4 times a second, tick speed, the element wheel, the special's
## charge as power, moons, cursed and sneaky hits, shards, blasts that burn, lightning twice, helpers;
## the special's traits only for a hero with a special; classic untouched.
## Prints "stage42 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage42: ", msg)

func _start(hero: int = 0, weapon: String = "") -> Player:
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
	p.pending += 1
	G.take_trait(Traits.by_id(id))

func _ready() -> void:
	var mine := Traits.all().filter(func(t): return t["id"].begins_with("int_"))
	if mine.size() != 38:
		fail("%d INT traits, not 38" % mine.size())
	for t in mine:
		if not Img.has("tr_" + t["id"]):
			fail("%s has no picture" % t["id"])
		if Attributes.FAMILY_ATTR.get(t["fam"], "") != "int":
			fail("%s is in %s, not an INT family" % [t["id"], t["fam"]])
		if TraitView.group(t) != "int":
			fail("%s is not drawn in the INT colour" % t["id"])
		for ch in t["name"] + t["desc"]:
			if not ch in Gfx.FONT_CHARS:
				fail("%s: the font cannot draw %s" % [t["id"], ch])
	var hs := -1   # a hero with a special
	var hn := -1   # one without
	for i in GameData.heroes().size():
		if GameData.heroes()[i].has("special"):
			hs = i if hs < 0 else hs
		elif hn < 0:
			hn = i

	# SURGEON'S EYE: +200% crit damage on a bleeding foe.
	var p := _start()
	var e := _foe(p)
	_take(p, "int_anatomy")
	if Arcana.crit_add(p, e) != 0.0:
		fail("SURGEON'S EYE on a foe that does not bleed")
	Statuses.apply(e, "bleed", 1, 10.0)
	if absf(Arcana.crit_add(p, e) - 2.0) > 0.001:
		fail("SURGEON'S EYE: +%.2f crit damage on a bleeding foe" % Arcana.crit_add(p, e))

	# CINDER RAIN and TIME SLIP: the special calls 3 meteors and makes ailments tick twice as fast.
	p = _start(hs)
	_foe(p)
	_take(p, "int_apocalypse")
	_take(p, "int_chrono")
	var m0: int = Actions.ran.get("meteor", 0)
	Might.cast(p, [])
	if Actions.ran.get("meteor", 0) != m0 + 3:
		fail("CINDER RAIN: %d meteors" % (Actions.ran.get("meteor", 0) - m0))
	if absf(Finesse.tick_rate(p) - 2.0) > 0.01:
		fail("TIME SLIP: ailments tick x%.2f" % Finesse.tick_rate(p))
	Arcana.tick(p, 10.5)
	if absf(Finesse.tick_rate(p) - 1.0) > 0.01:
		fail("TIME SLIP did not end")

	# The special's traits only for a hero with a special.
	if hn >= 0:
		p = _start(hn)
		for id in ["int_apocalypse", "int_chrono", "int_dreamer", "int_entropy", "int_insight", "int_beacon"]:
			if G.trait_weight(p, Traits.by_id(id)) != 0:
				fail("%s offered to a hero without a special" % id)

	# STAR READER: a lucky hit strikes 3 times.
	p = _start()
	e = _foe(p)
	p.gf["lucky"] = 1.0
	seed(5)
	Lucky.on_hit(e, 100.0, false, p, null)
	var one := 1e7 - e.hp
	e.hp = 1e7
	_take(p, "int_astromancy")
	seed(5)
	Lucky.on_hit(e, 100.0, false, p, null)
	var three := 1e7 - e.hp
	if one <= 0 or three / one < 2.4 or three / one > 3.6:
		fail("STAR READER: a lucky hit dealt %.0f, not about 3 x %.0f" % [three, one])

	# THORN BLOOM and EATING ACID: poison bleeds and leaves the foe vulnerable.
	p = _start()
	_take(p, "int_bramble")
	_take(p, "int_corrosive")
	e = _foe(p)
	Statuses.apply(e, "poison", 1, 10.0)
	if e.bleed_t <= 0 or e.vuln_t <= 0:
		fail("THORN BLOOM / EATING ACID: bleed %.1f, vulnerable %.1f" % [e.bleed_t, e.vuln_t])

	# EMBER MANTLE: a fire field, 4 pulses a second.
	p = _start()
	_take(p, "int_burnaura")
	e = _foe(p, 20.0)
	var b0: int = Auras.stats.get("burn", 0)
	for i in 60:
		Auras.tick(p, TB.DT)
	var pulses: int = Auras.stats.get("burn", 0) - b0
	if pulses < 3 or pulses > 5 or e.burn_t <= 0:
		fail("EMBER MANTLE: %d pulses in a second, burn %.1f" % [pulses, e.burn_t])

	# ELEMENT WHEEL: a burn chills, and nothing runs away.
	p = _start()
	_take(p, "int_balance")
	e = _foe(p)
	Statuses.apply(e, "burn", 1, 10.0)
	if e.chill_t <= 0:
		fail("ELEMENT WHEEL: a burn did not chill")
	Statuses.apply(e, "chill", 1, 10.0)
	if e.shock <= 0:
		fail("ELEMENT WHEEL: a chill did not shock")

	# FOCUSED ELEMENTS: the special's fire, frost and lightning count twice.
	p = _start()
	_take(p, "int_focus")
	Might.casting = true
	if Arcana.focus_mult(p, "burn") != 2.0 or Arcana.focus_mult(p, "poison") != 1.0:
		fail("FOCUSED ELEMENTS: x%.1f burn, x%.1f poison" % [Arcana.focus_mult(p, "burn"), Arcana.focus_mult(p, "poison")])
	Might.casting = false

	# DAYDREAM and MIND BEACON: the special's charge as power and helpers' damage.
	p = _start(hs)
	_take(p, "int_dreamer")
	_take(p, "int_beacon")
	p.special_cd = 0.0
	var lg := Legion.dmg_mult(p)
	if absf(Might.power(p) - 100.0) > 0.5:
		fail("DAYDREAM: %.0f power with a full charge" % Might.power(p))
	p.special_cd = float(p.hero["special"]["cd"])
	if Might.power(p) > 0.5 or absf(lg / Legion.dmg_mult(p) - 1.5) > 0.01:
		fail("DAYDREAM / MIND BEACON with an empty charge: %.0f power, helpers x%.2f" % [Might.power(p), lg / Legion.dmg_mult(p)])

	# WIDE ORBIT: +1 moon, twice as far out.
	p = _start()
	var r0 := Auras.orbit_radius(p)
	var o0 := p.orbitals
	_take(p, "int_horizon")
	if p.orbitals != o0 + 1 or absf(Auras.orbit_radius(p) / r0 - 2.0) > 0.01:
		fail("WIDE ORBIT: %d moons, radius x%.2f" % [p.orbitals - o0, Auras.orbit_radius(p) / r0])

	# FORESIGHT: +1 armor now, +2 every floor.
	p = _start()
	var a0 := p.armor
	_take(p, "int_forethought")
	Effects.fire("on_floor_start", {})
	if p.armor != a0 + 3:
		fail("FORESIGHT: armor %d -> %d" % [a0, p.armor])

	# WITCH'S MARK and WUNDERKIND: cursed hits (doubled); a cursed foe takes more.
	p = _start()
	_take(p, "int_hextouch")
	_take(p, "int_prodigy")
	if absf(Arcana.cursed_chance(p) - 0.3) > 0.001:
		fail("cursed hit chance %.2f, not 0.30" % Arcana.cursed_chance(p))
	p.gf["cursed_hit"] = 1.0
	e = _foe(p)
	Combat.damage_enemy(e, 10.0, {})
	if e.curse_t <= 0:
		fail("a sure cursed hit did not curse")

	# ICE VOLLEY and THISTLE THROW: shards that chill, a thistle that poisons and pierces.
	p = _start()
	var n0 := G.pbullets.size() + G.new_pbullets.size()
	Arcana.fan(p, 3, 10.0, "frost")
	Arcana.fan(p, 1, 10.0, "venom")
	var shots: Array = G.pbullets + G.new_pbullets
	if shots.size() != n0 + 4:
		fail("%d shards and thistles, not 4" % (shots.size() - n0))
	else:
		if not shots[shots.size() - 2].chill or shots[shots.size() - 1].poison_add != 2:
			fail("the shards do not chill or the thistle does not poison")

	# BLAZING BLASTS: a blast burns and hits harder.
	p = _start()
	_take(p, "int_ignition")
	e = _foe(p)
	Combat.explode_at(e.x, e.y, 10.0, null, 20)
	if e.burn_t <= 0 or absf(Arcana.blast_mult(p) - 1.5) > 0.001:
		fail("BLAZING BLASTS: burn %.1f, x%.2f" % [e.burn_t, Arcana.blast_mult(p)])

	# THUNDER TWICE: a strike comes again half a second later.
	p = _start()
	_take(p, "int_twice")
	e = _foe(p)
	var t0: int = Arcana.stats.get("thunder", 0)
	Combat.lightning(e, 10.0)
	if Arcana.later.size() != 1:
		fail("THUNDER TWICE: %d strikes waiting" % Arcana.later.size())
	Arcana.tick(p, 0.6)
	if Arcana.stats.get("thunder", 0) != t0 + 1 or not Arcana.later.is_empty():
		fail("THUNDER TWICE: the second strike did not come (or came again)")

	# ALCHEMIST'S BLOOD: a potion's damage for good.
	p = _start()
	_take(p, "int_mageblood")
	var d0 := p.dmg
	Effects.fire("on_potion", {})
	if p.dmg <= d0:
		fail("ALCHEMIST'S BLOOD: no damage from a potion")

	# HUNGRY MIND: +20 power an armor.
	p = _start()
	_take(p, "int_powerhungry")
	p.armor = 3
	if absf(Might.power(p) - 60.0) > 0.5:
		fail("HUNGRY MIND: %.0f power with 3 armor" % Might.power(p))

	# PACK MIND and MENAGERIE: more helpers, half as hard; +5% a helper for you and them.
	p = _start()
	var f0 := p.familiars
	lg = Legion.dmg_mult(p)
	_take(p, "int_strongtogether")
	if p.familiars != f0 + 2 or absf(Legion.dmg_mult(p) / lg - 0.5) > 0.01:
		fail("PACK MIND: %d wisps, helpers x%.2f" % [p.familiars - f0, Legion.dmg_mult(p) / lg])
	var dm := Might.dmg_mult(p)
	_take(p, "int_zoo")
	var hn2 := Finesse.helpers(p)
	if absf(Might.dmg_mult(p) / dm - (1.0 + 0.05 * hn2)) > 0.01:
		fail("MENAGERIE with %d helpers: x%.2f" % [hn2, Might.dmg_mult(p) / dm])

	# THIRD ECHO: the 4th attack repeats.
	p = _start()
	_take(p, "int_thaum")
	p.volleys.clear()
	for i in 4:
		Arcana.on_attack(p)
	if p.volleys.size() != 1:
		fail("THIRD ECHO: %d repeats after 4 attacks" % p.volleys.size())

	# CHEAP TRICKS: sneaky hits per common piece of gear.
	p = _start()
	_take(p, "int_trickery")
	var commons := 0
	for g in p.gear.values():
		if g is Dictionary and g.get("rarity", "") == "common":
			commons += 1
	if absf(Arcana.sneaky_chance(p) - 0.2 * commons) > 0.001:
		fail("CHEAP TRICKS: %.2f sneaky with %d common pieces" % [Arcana.sneaky_chance(p), commons])

	# MIND OVER MUSCLE: INT double.
	p = _start()
	p.a_int = 6
	_take(p, "int_keenmind")
	if Attributes.value(p, "int") != 14:   # 6, +1 from the trait itself, doubled
		fail("MIND OVER MUSCLE: INT %d" % Attributes.value(p, "int"))

	# VISION: the 30th attack sets off the special's moment and +100% damage.
	p = _start()
	_take(p, "int_vision")
	var v0: int = Actions.ran.get("trigger", 0)
	d0 = p.dmg
	for i in 30:
		Effects.fire("every_n_shots", {})
	if Actions.ran.get("trigger", 0) != v0 + 1 or p.dmg <= d0:
		fail("VISION: %d triggers, damage %.2f -> %.2f" % [Actions.ran.get("trigger", 0) - v0, d0, p.dmg])

	# A live fight with all 38: no script error.
	p = _start(hs)
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
	print("[stage42] all 38: stats %s, actions meteor %d fan %d" % [Arcana.stats, Actions.ran.get("meteor", 0), Actions.ran.get("fan_shots", 0)])

	# Classic: none of it.
	GameData.force_classic = true
	var c := _start()
	c.gf["dreamer"] = 100.0
	c.gf["menagerie"] = 1.0
	c.gf["elem_wheel"] = 1.0
	if Arcana.power_add(c) != 0.0 or Arcana.dmg_mult(c) != 1.0 or Arcana.tick_add(c) != 0.0:
		fail("classic has INT trait effects")
	GameData.force_classic = false

	print("stage42 test: PASSED" if fails == 0 else "stage42 test: %d FAILED" % fails)
	get_tree().quit()
