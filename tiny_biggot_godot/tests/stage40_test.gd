extends Node
## Stage 40 THE STRENGTH TRAITS (his pictures, 10 Oct; scripts/combat/might.gd, the str_ rows of
## scripts/data/traits.gd, tools/art/stage40_traits.py). Run:
##   godot --headless --path . res://tests/stage40_test.tscn -- --no-save
## 38 STR traits, each with its picture, in a STR family, its text drawable; and what each one does
## is there: power, rage, crushing hits, puncture, instability, bleeds, gloom, the special's speed,
## drinks twice, lucky hits per heart, steady hands, pride, courage, berserk, merciless; +5% a STR,
## DEX or INT point and +5% lucky hits a LUCK (40.0); classic untouched.
## Prints "stage40 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage40: ", msg)

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

func _foe(p: Player) -> Enemy:
	var e := Combat.spawn_enemy("skeleton", p.x + 30.0, p.y, false, true)
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
	# Every trait: a picture, a STR family, words the font can draw.
	var mine := Traits.all().filter(func(t): return t["id"].begins_with("str_"))
	if mine.size() != 38:
		fail("%d STR traits, not 38" % mine.size())
	for t in mine:
		if not Img.has("tr_" + t["id"]):
			fail("%s has no picture" % t["id"])
		if Attributes.FAMILY_ATTR.get(t["fam"], "") != "str":
			fail("%s is in %s, not a STR family" % [t["id"], t["fam"]])
		for ch in t["name"] + t["desc"]:
			if not ch in Gfx.FONT_CHARS:
				fail("%s: the font cannot draw %s" % [t["id"], ch])
		if TraitView.group(t) != "str":
			fail("%s is not drawn in the STR colour" % t["id"])

	# 40.0: +5% a point, +5% lucky hits a LUCK.
	var p := _start()
	var m0 := Attributes.mult(p)
	p.a_int += 4
	p.a_str += 4
	p.a_dex += 4
	var g := Attributes.scaling(p.weapon)
	var want: float = 0.05 * 4 * (Attributes.COEF[g["str"]] + Attributes.COEF[g["dex"]] + Attributes.COEF[g["int"]])
	if absf(Attributes.mult(p) - m0 - want) > 0.001:
		fail("4 of each stat gave x%.3f, not +%.3f" % [Attributes.mult(p) - m0, want])
	var l0 := Lucky.chance(p)
	p.luck += 2
	if absf(Lucky.chance(p) - l0 - 0.1) > 0.001:
		fail("2 LUCK gave %.3f lucky hits, not 0.10" % (Lucky.chance(p) - l0))

	# BRAWN: STR double, the others half.
	p = _start()
	p.a_str = 10
	p.a_dex = 10
	_take(p, "str_brawn")
	if Attributes.value(p, "str") != 20 or Attributes.value(p, "dex") != 5:
		fail("BRAWN: STR %d, DEX %d" % [Attributes.value(p, "str"), Attributes.value(p, "dex")])

	# POWER: WARPATH at +30% speed, CROWD FIGHTER with foes.
	p = _start()
	var d0 := Combat.player_damage_mult(p)
	_take(p, "str_warcharge")
	p.speed = float(p.hero["speed"]) * 1.35
	if absf(Might.power(p) - 75.0) > 0.01:
		fail("WARPATH at +35%% speed: %.0f power, not 75" % Might.power(p))
	if Combat.player_damage_mult(p) < d0 * 1.74:
		fail("75 power did not raise damage by 75%%: x%.2f" % (Combat.player_damage_mult(p) / d0))
	p = _start()
	_take(p, "str_crowd")
	for i in 3:
		_foe(p)
	if absf(Might.power(p) - 20.0 * Might.crowd(p)) > 0.01 or Might.crowd(p) < 4:
		fail("CROWD FIGHTER: %.0f power for %d in the room" % [Might.power(p), Might.crowd(p)])

	# BOILING BLOOD: rage from hits; a melee hit 5.
	var melee_w := _weapon(func(w): return w["kind"] == "slash")
	p = _start(melee_w)
	_take(p, "str_seething")
	var e := _foe(p)
	for i in 4:
		Combat.on_hit_effects(e, 10.0, false, p, null)
	if Might.rage < 19.9:
		fail("BOILING BLOOD: 4 melee hits gave %.1f rage, not 20" % Might.rage)
	var rd := Combat.player_damage_mult(p)
	Might.tick(p, 1.0)
	if Might.rage > 15.1 or Combat.player_damage_mult(p) >= rd:
		fail("rage did not fade")

	# BLEEDING EDGE (slash), SHARP END (thrust), BLUNT FORCE (blunt).
	p = _start(melee_w)
	_take(p, "str_keenedge")
	e = _foe(p)
	Combat.on_hit_effects(e, 50.0, false, p, null)
	if e.bleed_t <= 0:
		fail("BLEEDING EDGE: a sword hit did not bleed")
	p = _start(_weapon(func(w): return w["kind"] == "thrust"))
	_take(p, "str_sharpend")
	e = _foe(p)
	for i in 12:
		Combat.on_hit_effects(e, 10.0, false, p, null)
	if e.puncture != 10 or Might.foe_mult(p, e) < 1.39:
		fail("SHARP END: %d punctures, x%.2f" % [e.puncture, Might.foe_mult(p, e)])
	p = _start(_weapon(func(w): return Might.blunt(w)))
	_take(p, "str_bluntforce")
	e = _foe(p)
	for i in 5:
		Combat.on_hit_effects(e, 10.0, false, p, null)
	if e.stun_t <= 0:
		fail("BLUNT FORCE: 5 blunt hits did not make it reel")

	# IRON DISCIPLINE: no crits, every hit crushing (x1.5).
	p = _start()
	e = _foe(p)
	p.crit = 1.0
	var plain := 0.0
	var crushed := 0.0
	seed(7)
	for i in 50:
		Combat.damage_enemy(e, 100.0, { "no_mult": true })
	plain = 1e7 - e.hp
	e.hp = 1e7
	_take(p, "str_irondiscipline")
	seed(7)
	var c0: int = Might.stats.get("crushing", 0)
	for i in 50:
		if Combat.damage_enemy(e, 100.0, { "no_mult": true }):
			fail("IRON DISCIPLINE: a crit")
			break
	crushed = 1e7 - e.hp
	if Might.stats.get("crushing", 0) - c0 != 50:
		fail("IRON DISCIPLINE: %d crushing hits of 50" % (Might.stats.get("crushing", 0) - c0))
	print("[stage40] 50 hits: crits %.0f, crushing %.0f" % [plain, crushed])

	# SHADOW VEIL: +3 moons, a moon's hit puts 10 gloom on.
	p = _start()
	var o0 := p.orbitals
	_take(p, "str_shadowveil")
	if p.orbitals != o0 + 3:
		fail("SHADOW VEIL: %d moons" % p.orbitals)

	# The special: MUSCLE MEMORY, HONEST LABOUR; BATTLE HOWL and MERCILESS when it is used.
	p = _start()
	_take(p, "str_honest")
	if Might.special_rate(p) < 1.39:
		fail("HONEST LABOUR: special x%.2f" % Might.special_rate(p))
	if Abilities.has_special(p):
		_take(p, "str_warcry")
		var dm := p.dmg
		Abilities.use(p)
		if p.dmg <= dm:
			fail("BATTLE HOWL: no berserk after the special")

	# DOUBLE MEASURE: a drink counts twice, and comes off cleanly.
	p = _start()
	_take(p, "str_doublemeasure")
	var kind: String = Food.DRINKS.keys()[0]
	var snap := str(p.gf) + str(p.dmg) + str(p.rate) + str(p.crit) + str(p.speed)
	Food.drink(p, kind)
	if p.drinks.is_empty() or not p.drinks[0][3]:
		fail("DOUBLE MEASURE: the drink was not doubled")
	Food._wear_off(p, 0, false)
	if str(p.gf) + str(p.dmg) + str(p.rate) + str(p.crit) + str(p.speed) != snap:
		fail("DOUBLE MEASURE: a doubled drink left a trace")

	# BIG HEART: +15% lucky hits a heart.
	p = _start()
	var lb := Lucky.chance(p)
	_take(p, "str_bigheart")
	if absf(Lucky.chance(p) - lb - 0.15 * p.max_hp / 2.0) > 0.001:
		fail("BIG HEART: %.2f lucky hits" % (Lucky.chance(p) - lb))

	# STEADY HAND: rate bonuses half, damage up.
	p = _start()
	p.rate = 1.5
	var r0 := Weapons.wrate(p)
	var w0 := Weapons.wdmg(p)
	_take(p, "str_steadyhand")
	if absf(Weapons.wrate(p) / r0 - 1.25 / 1.5) > 0.01 or absf(Weapons.wdmg(p) / w0 - 2.0) > 0.01:
		fail("STEADY HAND: rate x%.2f, damage x%.2f" % [Weapons.wrate(p) / r0, Weapons.wdmg(p) / w0])

	# PRIDE: taming a foe; OPENING: courage after 2 s.
	p = _start()
	_take(p, "str_pride")
	e = Combat.spawn_enemy("skeleton", p.x + 30.0, p.y, false, true)
	Summons.charm(e, 3.0)
	if Might.pride_t <= 0:
		fail("PRIDE: taming did not start it")
	p = _start()
	_take(p, "str_opening")
	Might.last_shot = G.time - 3.0
	var dmo := p.dmg
	Might.on_attack(p)
	if p.dmg <= dmo:
		fail("OPENING: no courage after 3 s")

	# A live fight with all 38 at once: no script error, foes die.
	p = _start(melee_w)
	for t in mine:
		_take(p, t["id"])
	var foes := []
	for i in 6:
		var f := Combat.spawn_enemy("skeleton", p.x - 40.0 + i * 16.0, p.y - 40.0, false, true)
		foes.append(f)
	for i in 600:
		p.hp = p.max_hp
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}
	print("[stage40] all 38: rage %.0f, power %.0f, stats %s" % [Might.rage, Might.power(p), Might.stats])

	# Classic: none of it.
	GameData.force_classic = true
	var c := _start()
	c.gf["power"] = 100.0
	c.gf["resolute"] = 1.0
	if Might.dmg_mult(c) != 1.0 or Might.crushing(c) or Attributes.mult(c) != 1.0:
		fail("classic has power, crushing hits or attribute damage")
	GameData.force_classic = false

	print("stage40 test: PASSED" if fails == 0 else "stage40 test: %d FAILED" % fails)
	get_tree().quit()
