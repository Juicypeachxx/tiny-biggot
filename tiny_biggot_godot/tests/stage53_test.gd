extends Node
## Stage 53 (his word, 11 Oct: "Add new level up traits to pick matching the new additions, also add
## new effects and mechanic make it very cool and satisfying"). Run:
##   godot --headless --path . res://tests/stage53_test.tscn -- --no-save
## 53.1 SOULS (souls.gd): a soul from every foe slain (an elite 3), the gauge goes off at 30 (SOULBOUND
## 20, AVATAR OF SOULS 15) and the SOUL SURGE hurts the foes near you; the OATH OF SOULS doubles souls
## and its surges heal; the new triggers (a soul, a surge, a reroll) reach their traits.
## 53.2 the hooks of the new traits: CAPACITOR, GRAVE MOSS, SUNSPOT, RESONANCE, LICH TOUCH, ECLIPSE
## CHAIN; then every new trait taken in a live fight with no error.
## Prints "stage53 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage53: ", msg)

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
	p.souls = 0
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.enemies.clear()
	G.state = &"play"
	p.x = 14.0 * TB.TS
	p.y = 12.0 * TB.TS
	return p

func _foe(p: Player, dx: float = 40.0, elite: bool = false) -> Enemy:
	var e := Combat.spawn_enemy("slime", p.x + dx, p.y, elite, true)
	e.x = p.x + dx   # just here (a spawn may move it to a free spot)
	e.y = p.y
	e.spawn_t = 0.0
	e.max_hp = 1e6
	e.hp = 1e6
	return e

func _take(p: Player, id: String) -> void:
	p.pending += 1
	G.take_trait(Traits.by_id(id))

func _ready() -> void:
	await get_tree().process_frame
	seed(53)
	_souls()
	_triggers()
	_hooks()
	_all_traits()
	print("[stage53] souls ", Souls.stats, " types ", DamageTypes.stats)
	print("stage53 test: PASSED" if fails == 0 else "stage53 test: %d FAILED" % fails)
	get_tree().quit()

func _souls() -> void:
	var p := _start()
	Combat.kill_enemy(_foe(p, 200.0))
	if p.souls != 1:
		fail("a foe gave %d souls, not 1" % p.souls)
	Combat.kill_enemy(_foe(p, 200.0, true))
	if p.souls != 4:
		fail("an elite gave %d souls, not 3" % (p.souls - 1))
	var near := _foe(p, 40.0)
	var hp0 := near.hp
	Souls.gap = 0.0
	var s0: int = Souls.stats.get("surge", 0)
	p.souls = 29
	Combat.kill_enemy(_foe(p, 200.0))
	if Souls.stats.get("surge", 0) != s0 + 1:
		fail("30 souls did not set off a SOUL SURGE")
	if p.souls != 0:
		fail("after the surge the gauge holds %d, not 0" % p.souls)
	if near.hp >= hp0:
		fail("the surge did not hurt the foe beside you")
	_take(p, "q_soulbound")
	if Souls.need(p) != 20:
		fail("SOULBOUND: a surge needs %d, not 20" % Souls.need(p))
	_take(p, "q_soulavatar")
	if Souls.need(p) != 15:
		fail("AVATAR OF SOULS: a surge needs %d, not 15" % Souls.need(p))
	p = _start()
	_take(p, "o_souls")
	if not Oaths.VOWS.has("o_souls"):
		fail("the OATH OF SOULS has no vow")
	Combat.kill_enemy(_foe(p, 200.0))
	if p.souls != 2:
		fail("OATH OF SOULS: a foe gave %d souls, not 2" % p.souls)
	p.hp = 2
	Souls.gap = 0.0
	Souls.surge(p)
	if p.hp != 3:
		fail("OATH OF SOULS: the surge did not heal half a heart (%d)" % p.hp)

func _triggers() -> void:
	var p := _start(8)   # a hero with a special
	_take(p, "q_spiritwell")
	var spi := p.a_spi
	p.special_cd = 5.0
	Souls.gap = 0.0
	Souls.surge(p)
	if p.a_spi != spi + 1 or p.special_cd > 0.0:
		fail("SPIRIT WELL: a surge gave %d SPIRIT and left the special at %.1f" % [p.a_spi - spi, p.special_cd])
	_take(p, "q_harvest")
	var b0 := p.buffs.size()
	Combat.kill_enemy(_foe(p, 200.0))
	if p.buffs.size() <= b0:
		fail("SOUL FEAST: a soul gave no damage")
	var r0 := p.rerolls
	_take(p, "q_highroller")
	if p.rerolls != r0 + 1:
		fail("BIG SPENDER did not give a reroll")
	Effects.fire("on_reroll")
	Effects.fire("on_reroll")
	if absf(p.gf.get("highroller", 0.0) - 0.08) > 0.0001:
		fail("BIG SPENDER: two rerolls gave %.3f, not 0.08" % p.gf.get("highroller", 0.0))

func _hooks() -> void:
	var p := _start()
	_take(p, "q_capacitor")
	var e := _foe(p)
	var d0: int = DamageTypes.stats.get("discharge", 0)
	for i in 3:
		Statuses.apply(e, "charged", 1, 10.0)
	if DamageTypes.stats.get("discharge", 0) != d0 + 1:
		fail("CAPACITOR: 3 charges did not discharge")
	_take(p, "q_gravemoss")
	Statuses.apply(e, "rot", 30, 10.0)
	if e.rot != DamageTypes.ROT_MAX + 5:
		fail("GRAVE MOSS: rot stops at %d, not %d" % [e.rot, DamageTypes.ROT_MAX + 5])
	e.rot = 0
	e.rot_t = 0.0
	_take(p, "q_sunspot")
	_take(p, "q_resonance")
	var f := _foe(p, -60.0)
	f.seared_t = 2.0
	f.rattle = 3
	f.rattle_t = 2.0
	var want := 1.15 * (1.0 + 0.04 * 3)
	if absf(Statuses.dmg_mult(f) - want) > 0.0001:
		fail("SUNSPOT and RESONANCE: x%.3f, not x%.3f" % [Statuses.dmg_mult(f), want])
	f.seared_t = 0.0
	f.rattle = 0
	_take(p, "q_lichtouch")
	var a := _foe(p, 100.0)
	var b := _foe(p, 120.0)
	a.rot = 4
	a.rot_t = 3.0
	Combat.kill_enemy(a)
	if b.rot != 4:
		fail("LICH TOUCH: the rot did not spread to the foe beside it (%d)" % b.rot)
	_take(p, "q_totaleclipse")
	Reactions.clear()
	var c := _foe(p, -120.0)
	var n := _foe(p, -140.0)
	c.seared_t = 2.0
	c.gloom = 2
	c.gloom_t = 2.0
	Reactions.check(c)
	if n.seared_t <= 0.0 or n.gloom < 2:
		fail("ECLIPSE CHAIN: the foe beside the eclipse was not seared and gloomed")
	var g := _foe(p, 150.0)
	G.player.procs.clear()
	Effects.apply(p, [{ "on": "on_hit", "do": [["new_ailment", 1]] }], 1, "test")
	Effects.fire("on_hit", { "enemy": g, "dmg": 5.0, "crit": false })
	if g.seared_t <= 0.0 and g.rot <= 0 and g.gloom <= 0 and g.charge <= 0 and g.rattle <= 0:
		fail("the new_ailment action gave the foe none of the five")

func _all_traits() -> void:
	var ids := []
	for t in Traits.all():
		if t["id"].begins_with("q_") and t["id"] in ["q_sunspot", "q_dawnburst", "q_gravemoss", "q_lichtouch", "q_longshadow",
				"q_livewire", "q_capacitor", "q_bassdrop", "q_resonance", "q_fivefold", "q_totaleclipse", "q_conductor",
				"q_plaguewind", "q_kindred", "q_spiritfire", "q_ladyluck", "q_highroller", "q_sharkweek", "q_dancefloor",
				"q_anvilrain", "q_pincushion", "q_backdoor", "q_soulbound", "q_harvest", "q_soulstorm", "q_spiritwell",
				"q_wispwarden", "q_soulavatar"] or t["id"] == "o_souls":
			ids.append(t["id"])
	if ids.size() != 29:
		fail("%d of the 29 new traits found" % ids.size())
	for id in ids:
		if not Img.has("tr_" + id):
			fail("%s has no picture" % id)
		var p := _start(8)
		_take(p, id)
		var pool: Array = GameData.floors()[G.floor_index]["pool"]
		for i in 150:
			while G.enemies.size() < 5:
				var s := World.free_spot(G.room, p, 40, World.M_FLYER)
				var e := Combat.spawn_enemy(TB.pick(pool), s.x, s.y, false, true)
				e.max_hp *= 2
				e.hp = e.max_hp
			p.hp = p.max_hp
			p.invuln = 1.0
			if i % 10 == 0:
				var f := Combat.auto_target(p, 400)
				var a := TB.ang_to(p, f) if f != null else 0.0
				p.aim_a = a
				p.shot_n += 1
				Combat.player_shoot(p, a, false)
			if i == 60:
				p.souls = Souls.need(p) - 1   # a surge in the fight, for the surge traits
			G.update(TB.DT)
			if G.state != &"play":
				G.state = &"play"
				G.tchoice = {}
				G.choice = {}
