extends Node
## Stage 52 (his word, 11 Oct: "Do stage 50 and 52"; GAMEPLAY_PLAN.md): SPIRIT and LUCK as attributes,
## and each attribute raises a pool (attributes.gd). Run:
##   godot --headless --path . res://tests/stage52_test.tscn -- --no-save
## SPIRIT starts at 2; DEX adds a roll charge for every 6 and takes it back when DEX goes; INT and
## SPIRIT speed the special (1% and 3% a point) and SPIRIT makes its blows harder (3% a point); LUCK
## is the luck stat, adds 2% gold a point and fills the dice every floor (a REROLL die for every 5);
## every third trait rank adds a SPIRIT and every second FORTUNE rank a LUCK; the stat pickups; and
## under the classic rules none of it.
## Prints "stage52 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage52: ", msg)

func _near(a: float, b: float, what: String) -> void:
	if absf(a - b) > 0.0005:
		fail("%s: %.4f (want %.4f)" % [what, a, b])

func _start(hero: int = 0) -> Player:
	G.hero_index = hero
	G.new_run()
	var p := G.player
	p.oath_picks = 0
	p.special_picks = 0
	p.pending = 0
	G.state = &"play"
	return p

func _ready() -> void:
	await get_tree().process_frame
	seed(52)
	var p := _start(8)   # a hero with a special
	if p.a_spi != 2:
		fail("SPIRIT starts at %d, not 2" % p.a_spi)
	if Attributes.value(p, "spi") != p.a_spi or Attributes.value(p, "lck") != p.luck:
		fail("SPIRIT or LUCK do not read as attributes")
	# DEX: the roll pool.
	var rolls := p.dodge_charges
	var dex := Attributes.value(p, "dex")
	var to_next := Attributes.DEX_ROLL - dex % Attributes.DEX_ROLL
	Attributes.add(p, "dex", to_next)
	if p.dodge_charges != rolls + 1:
		fail("%d DEX gave %d roll charges, not %d" % [dex + to_next, p.dodge_charges, rolls + 1])
	Attributes.add(p, "dex", -to_next)
	if p.dodge_charges != rolls:
		fail("losing the DEX did not take the roll charge back (%d, not %d)" % [p.dodge_charges, rolls])
	# INT and SPIRIT: the special.
	var r0 := Might.special_rate(p)
	Attributes.add(p, "spi", 5)
	_near(Might.special_rate(p) - r0, 0.15, "5 SPIRIT on the special's recharge")
	r0 = Might.special_rate(p)
	Attributes.add(p, "int", 4)
	_near(Might.special_rate(p) - r0, 0.04, "4 INT on the special's recharge")
	_near(Attributes.spirit_power(p), 1.0 + 0.03 * p.a_spi, "SPIRIT on the special's blows")
	# LUCK: the luck stat, gold and the dice.
	var l0 := p.luck
	Attributes.add(p, "lck", 3)
	if p.luck != l0 + 3:
		fail("+3 LUCK made luck %d, not %d" % [p.luck, l0 + 3])
	_near(Attributes.gold_mult(p), 1.0 + 0.02 * p.luck, "LUCK on gold")
	p.luck = 10
	var dice := p.rerolls
	G.floor_index = 1
	G.start_floor()
	if p.rerolls != dice + 2:
		fail("10 LUCK gave %d REROLL dice on a new floor, not 2" % (p.rerolls - dice))
	# Trait ranks: every third adds a SPIRIT, every second FORTUNE rank a LUCK.
	p = _start(8)
	var s0 := p.a_spi
	var l1 := p.luck
	var fortune := Traits.all().filter(func(t): return t["fam"] == "fortune" and t["new"] and t["max"] >= 1 and t["rarity"] in ["common", "uncommon"])
	for i in 2:
		p.pending += 1
		G.take_trait(fortune[i])
	var other := Traits.all().filter(func(t): return t["fam"] == "pyre" and t["new"] and t["rarity"] in ["common", "uncommon"])
	p.pending += 1
	G.take_trait(other[0])
	if p.a_spi != s0 + 1:
		fail("3 trait ranks gave %d SPIRIT, not 1" % (p.a_spi - s0))
	if p.luck != l1 + 1:
		fail("2 FORTUNE ranks gave %d LUCK, not 1" % (p.luck - l1))
	# The stat pickups.
	s0 = p.a_spi
	l1 = p.luck
	StatDrops.take(p, "s_spi")
	StatDrops.take(p, "s_luck")
	if p.a_spi != s0 + 1 or p.luck != l1 + 1:
		fail("the SPIRIT and LUCK pickups did not add one each")
	# Classic: none of it.
	GameData.force_classic = true
	_near(Attributes.special_rate(p), 0.0, "classic special rate")
	_near(Attributes.spirit_power(p), 1.0, "classic spirit power")
	_near(Attributes.gold_mult(p), 1.0, "classic gold")
	GameData.force_classic = false
	print("stage52 test: PASSED" if fails == 0 else "stage52 test: %d FAILED" % fails)
	get_tree().quit()
