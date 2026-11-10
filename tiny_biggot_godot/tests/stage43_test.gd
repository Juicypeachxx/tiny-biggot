extends Node
## Stage 43 THE SUPER, PSYCHIC AND AUGMENT TRAITS (his pictures, 10 Oct; scripts/combat/marvels.gd, the
## sup_, psy_ and aug_ rows of scripts/data/traits.gd, tools/art/stage43_traits.py). Run:
##   godot --headless --path . res://tests/stage43_test.tscn -- --no-save
## 15 SUPER traits for every hero, 11 PSYCHIC ones only for the Mindwarden, 5 AUGMENT ones only for
## the Tinkerer, each with its picture and colour; and what each one does; classic untouched.
## Prints "stage43 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage43: ", msg)

func _hero(id: String) -> int:
	for i in GameData.heroes().size():
		if GameData.heroes()[i]["id"] == id:
			return i
	return 0

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

func _weapon(test: Callable) -> String:
	for w in Weapons.all():
		if test.call(w) and not w["id"] in Weapons.HERO_WEAPON.values():
			return w["id"]
	return ""

func _ready() -> void:
	var mw := _hero("mindwarden")
	var tk := _hero("tinkerer")
	var groups := { "sup_": "super", "psy_": "psy", "aug_": "aug" }
	var counts := { "sup_": 15, "psy_": 11, "aug_": 5 }
	var mine := []
	for pre in groups:
		var ts := Traits.all().filter(func(t): return t["id"].begins_with(pre))
		if ts.size() != counts[pre]:
			fail("%d %s traits, not %d" % [ts.size(), pre, counts[pre]])
		for t in ts:
			mine.append(t)
			if not Img.has("tr_" + t["id"]):
				fail("%s has no picture" % t["id"])
			if TraitView.group(t) != groups[pre]:
				fail("%s is drawn as %s" % [t["id"], TraitView.group(t)])
			for ch in t["name"] + t["desc"]:
				if not ch in Gfx.FONT_CHARS:
					fail("%s: the font cannot draw %s" % [t["id"], ch])

	# The heroes' own traits: PSYCHIC for the Mindwarden, AUGMENT for the Tinkerer, nobody else.
	var p := _start(0)
	for t in mine:
		if not t["id"].begins_with("sup_") and G.trait_weight(p, t) != 0:
			fail("%s offered to %s" % [t["id"], p.hero["id"]])
	p = _start(mw)
	if Traits.all().filter(func(t): return t["id"].begins_with("psy_") and G.trait_weight(p, t) > 0).is_empty():
		fail("no PSYCHIC trait offered to the Mindwarden")
	if not Traits.all().filter(func(t): return t["id"].begins_with("aug_") and G.trait_weight(p, t) > 0).is_empty():
		fail("an AUGMENT trait offered to the Mindwarden")
	p = _start(tk)
	if Traits.all().filter(func(t): return t["id"].begins_with("aug_") and G.trait_weight(p, t) > 0).is_empty():
		fail("no AUGMENT trait offered to the Tinkerer")

	# SUPER: armor, luck, stats that count as 6 ranks, hearts, gold, speed, rolls.
	p = _start()
	var a0 := p.armor
	_take(p, "sup_protection")
	if p.armor != a0 + 5:
		fail("IRONCLAD SOUL: armor %d -> %d" % [a0, p.armor])
	var f0: int = p.fam.get("shadow", 0)
	var d0 := Attributes.value(p, "dex")
	_take(p, "sup_reflexes")
	if p.fam.get("shadow", 0) != f0 + 7 or Attributes.value(p, "dex") < d0 + 20:
		fail("BLURRED MOTION: shadow %d -> %d, DEX %d -> %d" % [f0, p.fam.get("shadow", 0), d0, Attributes.value(p, "dex")])
	var hp0 := p.max_hp
	_take(p, "sup_health")
	p.hp = 1
	Effects.fire("on_room_clear", {})
	if p.max_hp != hp0 + 6 or p.hp != p.max_hp:
		fail("EVERLASTING: max %d -> %d, hp %d" % [hp0, p.max_hp, p.hp])
	_take(p, "sup_rich")
	if Combat.held_gold(p) < 1000:
		fail("ENDLESS WEALTH: gold counts as %d" % Combat.held_gold(p))
	var c0 := p.dodge_charges
	var x0 := floori(Attributes.value(p, "dex") / float(Attributes.DEX_ROLL))
	_take(p, "sup_stamina")
	var x1 := floori(Attributes.value(p, "dex") / float(Attributes.DEX_ROLL))   # (52: and the DEX it brings, a roll a pool)
	if p.dodge_charges != c0 + 3 + (x1 - x0):
		fail("TIRELESS: %d rolls (%d from DEX)" % [p.dodge_charges - c0, x1 - x0])

	# STORMBORN: a roll strikes with lightning.
	p = _start()
	_foe(p)
	_take(p, "sup_charged")
	var b0: int = Actions.ran.get("bolts", 0)
	Effects.fire("on_roll", {})
	if Actions.ran.get("bolts", 0) != b0 + 1:
		fail("STORMBORN: no lightning on a roll")

	# SAINT AND SINNER: a revive every floor; curses cannot hurt.
	p = _start()
	_take(p, "sup_devoted")
	p.revive = 0
	G.floor_index += 1
	G.start_floor()
	p = G.player
	if p.revive < 1:
		fail("SAINT AND SINNER: no revive on a new floor")
	p.hp = p.max_hp
	Actions.run(["hurt_self", 2], 1, {})
	if p.hp != p.max_hp:
		fail("SAINT AND SINNER: a curse hurt")

	# BOTTOMLESS TANKARD: 4 drinks at once.
	p = _start()
	_take(p, "sup_drunkard")
	if p.drinks.size() < mini(4, Food.slots(p)) or Tipsy.cap(p) < 30:
		fail("BOTTOMLESS TANKARD: %d drinks, tipsy cap %d" % [p.drinks.size(), Tipsy.cap(p)])

	# BELOVED and LAZY GENIUS.
	p = _start()
	var lg := Legion.dmg_mult(p)
	_take(p, "sup_friendly")
	if absf(Legion.dmg_mult(p) / lg - 2.0) > 0.01:
		fail("BELOVED: helpers x%.2f" % (Legion.dmg_mult(p) / lg))
	p = _start()
	var dm := Might.dmg_mult(p)
	_take(p, "sup_lazy")
	var want := 1.0 + minf(2.5, 0.25 * Marvels.empty_slots(p))
	if absf(Might.dmg_mult(p) / dm - want) > 0.01 or Marvels.empty_slots(p) == 0:
		fail("LAZY GENIUS with %d empty slots: x%.2f" % [Marvels.empty_slots(p), Might.dmg_mult(p) / dm])

	# ARCANE ENGINE: the special 3 times as fast; +1 STR, DEX and INT each time.
	p = _start(mw)
	var sr := Might.special_rate(p) - Attributes.special_rate(p)   # (52: what INT and SPIRIT add is counted apart)
	_take(p, "sup_engine")
	var s0 := p.a_str + p.a_dex + p.a_int
	Might.cast(p, [])
	if absf(Might.special_rate(p) - Attributes.special_rate(p) - sr - 2.0) > 0.01 or p.a_str + p.a_dex + p.a_int != s0 + 3:
		fail("ARCANE ENGINE: rate +%.2f, stats +%d" % [Might.special_rate(p) - Attributes.special_rate(p) - sr, p.a_str + p.a_dex + p.a_int - s0])

	# PSYCHIC.
	p = _start(mw)
	_take(p, "psy_lightning")
	if Statuses.shock_cap() != Statuses.SHOCK_MAX + 4:
		fail("MIND LIGHTNING: shock cap %d" % Statuses.shock_cap())
	_take(p, "psy_knives")
	if absf(Marvels.bleed_rate(p) - (1.0 + 0.1 * p.orbitals)) > 0.001 or p.orbitals < 3:
		fail("KITCHEN KNIVES: %d moons, bleeds x%.2f" % [p.orbitals, Marvels.bleed_rate(p)])
	_take(p, "psy_bombard")
	p.moving = false
	var still := Marvels.tick_add(p)
	p.moving = true
	if absf(still - 0.5) > 0.001 or Marvels.tick_add(p) != 0.0:
		fail("MIND STORM: +%.2f standing still, +%.2f moving" % [still, Marvels.tick_add(p)])
	_take(p, "psy_combust")
	var e := _foe(p)
	if absf(Marvels.burn_extra(p, e) - e.max_hp * 0.01) > 1.0:
		fail("INNER FIRE: a burn tick takes %.0f of %.0f" % [Marvels.burn_extra(p, e), e.max_hp])
	_take(p, "psy_dilation")
	var sp := Finesse.special_power(p)
	p.drinks = [["ale", 3, "", false]]
	for i in 3:
		Might.cast(p, [])
	if absf(Finesse.special_power(p) - sp - 0.3) > 0.01 or p.drinks[0][1] != 6:
		fail("SLOW TIME: special power +%.2f, drink rooms %d" % [Finesse.special_power(p) - sp, p.drinks[0][1]])
	_take(p, "psy_randomness")
	p.dice_used = 4
	if absf(Marvels.lucky_add(p) - 0.1) > 0.001:
		fail("DICE MIND: +%.3f lucky with 4 dice used" % Marvels.lucky_add(p))
	p = _start(mw)
	var hp1 := Legion.dmg_mult(p)
	_take(p, "psy_marionettes")
	if absf(Legion.dmg_mult(p) / hp1 - 0.3) > 0.01:
		fail("PUPPET STRINGS: helpers x%.2f" % (Legion.dmg_mult(p) / hp1))
	p = _start(mw)
	_take(p, "psy_link")
	p.familiars = 1
	G.temp_fams.clear()
	if Finesse.helpers(p) == 1 and absf(Marvels.helper_mult(p) - 5.0) > 0.01:
		fail("MIND LINK: one helper x%.2f" % Marvels.helper_mult(p))
	p = _start(mw, _weapon(func(w): return Might.melee(w)))
	_take(p, "psy_rifle")
	var cm := Marvels.crit_chance(p)
	Weapons.equip_weapon(p, Weapons.by_id(_weapon(func(w): return Might.ranged(w))))
	if cm != 0.0 or absf(Marvels.crit_chance(p) - 0.2) > 0.001:
		fail("HAND-ME-DOWNS: +%.2f crit melee, +%.2f ranged" % [cm, Marvels.crit_chance(p)])

	# AUGMENT (the Tinkerer).
	p = _start(tk)
	_take(p, "aug_freeze")
	e = _foe(p)
	Might.casting = true
	var fm := Marvels.foe_mult(p, e)
	Might.casting = false
	if absf(fm - 1.5) > 0.001 or e.chill_t <= 0 or Marvels.foe_mult(p, e) != 1.0:
		fail("CRYO CORE: x%.2f in the special, chill %.1f" % [fm, e.chill_t])
	_take(p, "aug_laser")
	_take(p, "aug_lucky")
	var l0: int = Marvels.stats.get("laser", 0)
	Might.cast(p, [])
	for i in 60:
		Marvels.tick(p, TB.DT)
	if Marvels.stats.get("laser", 0) < l0 + 2 or Lucky.rush_t <= 0:
		fail("BEAM CORE / CHANCE CORE: %d beams in a second, lucky rush %.1f" % [Marvels.stats.get("laser", 0) - l0, Lucky.rush_t])
	sr = Might.special_rate(p) - Attributes.special_rate(p)
	for i in 6:
		_take(p, "aug_mana")
	if absf(Might.special_rate(p) - Attributes.special_rate(p) - sr - 1.2) > 0.01:
		fail("FLUX CORE x6: special rate +%.2f" % (Might.special_rate(p) - Attributes.special_rate(p) - sr))
	_take(p, "aug_power")
	if Marvels.special_add(p) < Might.power(p) / 100.0 - 0.001 or Might.power(p) < 10.0:
		fail("OVERDRIVE CORE: special +%.2f with %.0f power" % [Marvels.special_add(p), Might.power(p)])

	# Live fights with all of them: the Mindwarden (SUPER and PSYCHIC), the Tinkerer (AUGMENT).
	for who in [[mw, "sup_", "psy_"], [tk, "aug_", "aug_"]]:
		p = _start(who[0])
		for t in mine:
			if t["id"].begins_with(who[1]) or t["id"].begins_with(who[2]):
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
	print("[stage43] live fights: stats %s" % Marvels.stats)

	# Classic: none of it.
	GameData.force_classic = true
	var c := _start()
	c.gf["idle_hands"] = 1.0
	c.gf["still_ticks"] = 1.0
	c.gf["shock_max"] = 4.0
	if Marvels.dmg_mult(c) != 1.0 or Marvels.tick_add(c) != 0.0 or Statuses.shock_cap() != Statuses.SHOCK_MAX:
		fail("classic has SUPER, PSYCHIC or AUGMENT effects")
	GameData.force_classic = false

	print("stage43 test: PASSED" if fails == 0 else "stage43 test: %d FAILED" % fails)
	get_tree().quit()
