extends Node
## 33.2 THE TAVERN (scripts/combat/tipsy.gd). Run:
##   godot --headless --path . res://tests/tavern_test.tscn -- --no-save
## TIPSY: drinks add it up to a cap, a stack wears off every 12 s, damage and attack speed
## compound with it; the three drinks; IRON GUT; SURE STRIKE never crits and turns crit chance
## into damage; BAR BRAWLER stuns while tipsy; LAST ORDERS sends shockwaves at 8+; the saloon's
## drinks make you tipsy; the Tavern Knight's ale, STR speed and BAR FIGHT; classic is untouched.
## Prints "tavern test: PASSED" or a FAIL line per problem.

var fails := 0
var notes := []

func fail(msg: String) -> void:
	fails += 1
	print("FAIL tavern: ", msg)

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
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.enemies.clear()
	G.locked = true
	G.state = &"play"
	p.x = 14.0 * TB.TS
	p.y = 10.0 * TB.TS
	return p

func _foe(x: float, y: float) -> Enemy:
	var e := Combat.spawn_enemy("skeleton", x, y, false, true)
	e.speed = 0.0
	e.max_hp = 1e7
	e.hp = 1e7
	return e

func _tick(n: int) -> void:
	for i in n:
		var p := G.player
		p.hp = p.max_hp
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

func _ready() -> void:
	await get_tree().process_frame
	seed(332)
	var p := _start()
	var d0 := Weapons.wdmg(p)
	var r0 := Weapons.wrate(p)
	Tipsy.add(p, 2)
	if p.tipsy != 2.0:
		fail("a drink of 2 gave %.1f" % p.tipsy)
	Tipsy.add(p, 20)
	if p.tipsy != Tipsy.cap(p):
		fail("tipsy went past its cap: %.1f" % p.tipsy)
	var want_d := pow(1.06, Tipsy.BASE_CAP)
	if absf(Weapons.wdmg(p) / d0 - want_d) > 1e-4 or absf(Weapons.wrate(p) / r0 - pow(1.04, Tipsy.BASE_CAP)) > 1e-4:
		fail("at %d tipsy: damage x%.3f, speed x%.3f (want x%.3f, x%.3f)" % [p.tipsy, Weapons.wdmg(p) / d0, Weapons.wrate(p) / r0, want_d, pow(1.04, 8)])
	notes.append("8 tipsy: damage x%.2f, attack speed x%.2f" % [Weapons.wdmg(p) / d0, Weapons.wrate(p) / r0])
	Meta.opts["autofire"] = false
	_tick(int(Tipsy.DECAY * 60) + 5)
	if p.tipsy != Tipsy.BASE_CAP - 1:
		fail("after 12 s tipsy is %.1f (want %d)" % [p.tipsy, Tipsy.BASE_CAP - 1])
	# The drinks.
	p = _start()
	for k in ["c_ale", "c_stout", "c_mead"]:
		Consumables.take(p, k)
	var a0 := p.armor
	p.hp = 1
	Consumables.use(p, 0)
	Consumables.use(p, 0)
	Consumables.use(p, 0)
	if p.tipsy != 7.0 or p.armor != a0 + 1 or p.hp != 2:
		fail("ale, stout, mead: tipsy %.1f (want 7), armor +%d (want +1), hp %d (want 2)" % [p.tipsy, p.armor - a0, p.hp])
	# IRON GUT.
	p = _start()
	G.take_trait(Traits.by_id("j_irongut"))
	Tipsy.add(p, 2)
	if p.tipsy != 3.0 or Tipsy.cap(p) != Tipsy.BASE_CAP + 4:
		fail("IRON GUT: a drink gave %.1f (want 3), cap %d" % [p.tipsy, Tipsy.cap(p)])
	# SURE STRIKE.
	p = _start()
	p.crit = 0.4
	var e := _foe(p.x + 40.0, p.y)
	var hp0 := e.hp
	var crits := 0
	for i in 50:
		if Combat.damage_enemy(e, 10.0, { "silent": true }):
			crits += 1
	var normal := (hp0 - e.hp) / 50.0
	G.take_trait(Traits.by_id("j_surestrike"))
	e.hp = hp0
	var crits2 := 0
	for i in 50:
		if Combat.damage_enemy(e, 10.0, { "silent": true, "force_crit": i % 2 == 0 }):
			crits2 += 1
	var sure := (hp0 - e.hp) / 50.0
	if crits == 0 or crits2 > 0:
		fail("SURE STRIKE: %d crits before, %d after (want some, then none)" % [crits, crits2])
	if sure < normal:
		fail("SURE STRIKE: %.1f a hit, %.1f before" % [sure, normal])
	notes.append("SURE STRIKE at 40%% crit: %.1f a hit, never a crit (with crits: %.1f)" % [sure, normal])
	# BAR BRAWLER and LAST ORDERS.
	p = _start("tavernknight")
	Meta.opts["autofire"] = true
	G.take_trait(Traits.by_id("j_brawler"))
	G.take_trait(Traits.by_id("j_lastorders"))
	Tipsy.add(p, 10)
	var foes := []
	for i in 4:
		foes.append(_foe(p.x - 30.0 + i * 20.0, p.y - 26.0))
	Actions.ran.clear()
	var stunned := false
	for i in 600:
		_tick(1)
		p.tipsy = maxf(p.tipsy, 9.0)
		for f in foes:
			if f.stun_t > 0:
				stunned = true
	if not stunned:
		fail("BAR BRAWLER: no foe stunned in 10 s while tipsy")
	if Actions.ran.get("area", 0) < 3:
		fail("LAST ORDERS: %d shockwaves in 10 s at 9 tipsy" % Actions.ran.get("area", 0))
	notes.append("the Tavern Knight at 9 tipsy, 10 s: %d shockwaves" % Actions.ran.get("area", 0))
	# The Tavern Knight: an ale each floor, STR speed, BAR FIGHT.
	p = _start("tavernknight")
	if not p.belt.has("c_ale"):
		fail("the Tavern Knight has no ale in the belt: %s" % [p.belt])
	if p.a_str < 6 or p.g("rate_per_str") <= 0:
		fail("the Tavern Knight: STR %d, rate per STR %.3f" % [p.a_str, p.g("rate_per_str")])
	p.tipsy = 0.0
	Abilities.use(p)
	if p.tipsy < 3.0:
		fail("BAR FIGHT gave %.1f tipsy" % p.tipsy)
	# The saloon's drinks.
	p = _start()
	Saloon.drink(p, "courage")
	if p.tipsy < 2.0:
		fail("a drink at the saloon gave %.1f tipsy" % p.tipsy)
	# Classic.
	GameData.force_classic = true
	p.tipsy = 0.0
	Tipsy.add(p, 3)
	GameData.force_classic = false
	if p.tipsy != 0.0:
		fail("classic got tipsy")
	Meta.opts["autofire"] = true
	for n in notes:
		print("[tavern] ", n)
	print("tavern test: PASSED" if fails == 0 else "tavern test: %d FAILED" % fails)
	get_tree().quit()
