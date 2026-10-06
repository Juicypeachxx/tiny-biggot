extends Node
## The Gaolbird (starter hero). Run: godot --headless --path . res://tests/gaolbird_test.tscn -- --no-save
##   1. Starter: free from the first run, not sold at the shrine, original hero indices untouched.
##   2. Tempo: blows and kills build it, the bonuses are exact and come off cleanly, it fades,
##      a hit halves it, full flight adds crit; other heroes are never touched by it.
##   3. Rally: a lost heart is won back by 6 blows; cooldown, time-out and a second hit all lose it.
##   4. Rolling through a foe exposes it and sets up a crit; in full flight the roll also cuts.
##   5. Talon Dive: leaps over a pillar onto the foe, lands on open floor, hits, stuns, exposes, +2 tempo.
##   6. Iron Talons: the third strike hits foes outside the swing.
##   7. The JAILBREAK branch: every node does what it says.
##      Cheating death and dying with tempo and a rally running both end cleanly.
##   8. Thirty seconds of real play with the whole tree learned.
##   9. The hero screen: LEFT/RIGHT walk the free heroes first, and USE starts a run as the Gaolbird.
## Prints "gaolbird test: PASSED" or a FAIL line per problem.

var fails := 0
var notes := []

func fail(msg: String) -> void:
	fails += 1
	print("FAIL gaolbird: ", msg)

func _index(id: String) -> int:
	var all := GameData.heroes()
	for i in all.size():
		if all[i]["id"] == id:
			return i
	fail("no hero " + id)
	return 0

## A fresh run in an empty, locked combat room (no waves arrive: the test never calls G.update here).
func _arena(hero: String = "gaolbird", tree: Array = [0, 0, 0]) -> Player:
	Meta.meta["tree"][hero] = tree
	G.god = false
	G.hero_index = _index(hero)
	G.new_run()
	G.floor_d["depth"] = 2
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s"))
	G.room.waves_left = 0
	G.state = &"play"
	G.hitstop = 0.0
	var p := G.player
	p.x = 14.0 * TB.TS
	p.y = 9.5 * TB.TS
	p.invuln = 0.0
	# A clear strip of floor around the hero for the movement tests.
	for c in range(4, 25):
		for r in range(8, 12):
			G.room.set_tile(c, r, World.T_FLOOR)
	Keys.tick()
	return p

func _foe(x: float, y: float, hp: float = 1000.0, elite: bool = false) -> Enemy:
	var e := Combat.spawn_enemy("skeleton", x, y, elite, true)
	e.x = x
	e.y = y
	e.max_hp = hp
	e.hp = hp
	return e

func _blow(p: Player, e: Enemy) -> void:
	Combat.on_hit_effects(e, 1.0, false, p, null)

func _kill(e: Enemy) -> void:
	Combat.damage_enemy(e, (e.hp + Armor.shown(e)) * 2.0 + 1.0, { "no_crit": true, "no_mult": true, "silent": true })

func _near(a: float, b: float, eps: float = 1e-6) -> bool:
	return absf(a - b) <= eps * maxf(1.0, absf(b))

func _ready() -> void:
	await get_tree().process_frame
	seed(777)
	starter()
	tempo()
	rally()
	rolling()
	dive()
	talons()
	branch()
	dying()
	soak()
	screen()
	for n in notes:
		print("[gaolbird] ", n)
	print("gaolbird test: %s" % ("PASSED" if fails == 0 else "%d FAILURES" % fails))
	get_tree().quit(1 if fails > 0 else 0)

# ---------- 1 ----------
func starter() -> void:
	var all := GameData.heroes()
	var want := ["hexer", "poacher", "brute", "gravedigger", "alchemist", "warden", "gaolbird"]
	for i in want.size():
		if all[i]["id"] != want[i]:
			fail("hero %d is %s, want %s" % [i, all[i]["id"], want[i]])
	# The hero screen shows the free heroes first: the Gaolbird is the fourth panel.
	var order := GameData.hero_order()
	if order.size() != all.size() or order.slice(0, 4) != [0, 1, 2, 6] or order.slice(4, 7) != [3, 4, 5]:
		fail("hero screen order is %s" % [order])
	for i in all.size():
		if not i in order:
			fail("hero %d is missing from the hero screen" % i)
	var h: Dictionary = all[_index("gaolbird")]
	var saved: Dictionary = Meta.meta["unlocked"]
	Meta.meta["unlocked"] = {}
	if not G.hero_unlocked(h):
		fail("the Gaolbird is locked on a fresh save")
	Meta.meta["unlocked"] = saved
	if GameData.unlocks().any(func(u): return u["id"] == "hero_gaolbird"):
		fail("the Gaolbird is sold at the shrine")
	if not "irontalons" in Weapons.HERO_WEAPON.values():
		fail("Iron Talons could drop as loot")
	for k in 300:
		for r in ["common", "rare", "epic", "legend"]:
			if Weapons.random_weapon(r)["id"] == "irontalons":
				fail("Iron Talons dropped as loot")
				return
	var p := _arena()
	if p.weapon["id"] != "irontalons" or p.tempo_max != 10 or p.rally_n != 6 or p.g("roll_expose") <= 0:
		fail("start: weapon %s, tempo_max %d, rally_n %d" % [p.weapon["id"], p.tempo_max, p.rally_n])
	if p.traits.get("sh_blur", 0) != 1:
		fail("starting trait missing")
	notes.append("starter: free on a fresh save, fourth on the hero screen, originals keep indices 0-5, Iron Talons never drop")

# ---------- 2 ----------
func tempo() -> void:
	var p := _arena()
	var e := _foe(p.x + 60, p.y)
	var speed0 := p.speed
	var rate0 := p.rate
	var crit0 := p.crit
	for i in Tempo.HITS - 1:
		_blow(p, e)
	if p.tempo != 0:
		fail("tempo %d after %d blows (want 0)" % [p.tempo, Tempo.HITS - 1])
	_blow(p, e)
	if p.tempo != 1 or not _near(p.speed, speed0 * 1.025) or not _near(p.rate, rate0 * 1.04):
		fail("1 tempo: %d, speed x%.4f, rate x%.4f" % [p.tempo, p.speed / speed0, p.rate / rate0])
	_kill(_foe(p.x + 60, p.y + 20, 5.0))
	if p.tempo != 2:
		fail("a kill should add 1 tempo (now %d)" % p.tempo)
	_kill(_foe(p.x + 60, p.y - 20, 5.0, true))
	if p.tempo != 4:
		fail("an elite kill should add 2 tempo (now %d)" % p.tempo)
	Tempo.add(p, 50)
	if p.tempo != 10 or not Tempo.full(p) or not _near(p.speed, speed0 * 1.25) or not _near(p.rate, rate0 * 1.4) \
			or not _near(p.crit, crit0 + 0.2) or p.g("flight") != 1.0:
		fail("full flight: tempo %d, speed x%.4f, rate x%.4f, crit +%.3f, flight %s" % [p.tempo, p.speed / speed0,
			p.rate / rate0, p.crit - crit0, p.g("flight")])
	# It holds for GRACE seconds after the last blow, then fades a point every FADE seconds.
	_blow(p, e)
	var t := 0.0
	while p.tempo == 10 and t < 10.0:
		Tempo.update(p, TB.DT)
		t += TB.DT
	if absf(t - (Tempo.GRACE + Tempo.FADE)) > 0.05:
		fail("tempo began to fade after %.2f s (want %.2f)" % [t, Tempo.GRACE + Tempo.FADE])
	if p.tempo != 9 or p.g("flight") != 0.0 or not _near(p.crit, crit0):
		fail("leaving full flight: tempo %d, flight %s, crit +%.3f" % [p.tempo, p.g("flight"), p.crit - crit0])
	t = 0.0
	while p.tempo > 0 and t < 20.0:
		Tempo.update(p, TB.DT)
		t += TB.DT
	if p.tempo != 0 or not _near(p.speed, speed0) or not _near(p.rate, rate0) or not _near(p.crit, crit0):
		fail("tempo did not fade back to exactly nothing (speed x%.6f, rate x%.6f)" % [p.speed / speed0, p.rate / rate0])
	# A hit halves it (rounded down).
	Tempo.set_to(p, 10)
	var hp0 := p.hp
	Combat.hurt_player(1, "the test")
	if p.tempo != 5 or p.hp != hp0 - 1:
		fail("a hit at 10 tempo: tempo %d, hp %d -> %d" % [p.tempo, hp0, p.hp])
	p.invuln = 0.0
	Rally._end(p, false)
	Combat.hurt_player(1, "the test")
	if p.tempo != 2:
		fail("a hit at 5 tempo should leave 2 (now %d)" % p.tempo)
	# Armour takes the heart's place but does not save the tempo.
	Tempo.set_to(p, 10)
	p.invuln = 0.0
	p.armor = 1
	var hp1 := p.hp
	Combat.hurt_player(1, "the test")
	if p.tempo != 5 or p.hp != hp1 or p.armor != 0:
		fail("a hit on armour at 10 tempo: tempo %d, hp %d -> %d, armour %d" % [p.tempo, hp1, p.hp, p.armor])
	# God mode: nothing happens at all.
	Tempo.set_to(p, 10)
	p.invuln = 0.0
	G.god = true
	Combat.hurt_player(1, "the test")
	G.god = false
	if p.tempo != 10 or p.hp != hp1 or p.invuln != 0.0:
		fail("a hit in god mode changed something")
	# Only the weapon's own blows count: not a wisp's shot, not a bonus shot from a trait.
	Tempo.set_to(p, 0)
	p.tempo_hits = 0
	var wisp := Combat._raw_shot(p.x, p.y, 0.0, 200, 1.0, 1.0, 2.0, 0, "spark", {})
	for i in 20:
		Combat.on_hit_effects(e, 1.0, false, p, wisp)
	var before := G.pbullets.size()
	Actions.run(["nova", 8, 0.5, "spark"], 1, {})
	for i in range(before, G.pbullets.size()):
		for k in 5:
			Combat.on_hit_effects(e, 1.0, false, p, G.pbullets[i])
	if p.tempo != 0 or p.tempo_hits != 0:
		fail("shots that are not the weapon's own built tempo (%d, %d blows)" % [p.tempo, p.tempo_hits])
	Weapons.equip_weapon(p, Weapons.by_id("repeater"))
	before = G.pbullets.size()
	Combat.player_shoot(p, 0.0)
	if G.pbullets.size() <= before or not G.pbullets[G.pbullets.size() - 1].own:
		fail("a shot from the weapon itself is not marked as the hero's own")
	else:
		for i in Tempo.HITS:
			Combat.on_hit_effects(e, 1.0, false, p, G.pbullets[G.pbullets.size() - 1])
		if p.tempo != 1:
			fail("%d hits from the weapon's own shots gave %d tempo" % [Tempo.HITS, p.tempo])
	Weapons.equip_weapon(p, Weapons.by_id("irontalons"))
	Tempo.set_to(p, 0)
	speed0 = p.speed
	rate0 = p.rate
	crit0 = p.crit
	# The bonuses come off exactly even if the top of the meter moves while it is full.
	Tempo.set_to(p, 10)
	p.tempo_max = 13
	Tempo.set_to(p, 0)
	p.tempo_max = 10
	if not _near(p.speed, speed0, 1e-9) or not _near(p.crit, crit0, 1e-9) or p.g("flight") != 0.0 or not p.tempo_fx.is_empty():
		fail("raising the tempo cap at full flight left a bonus behind (crit +%.3f, flight %s)" % [p.crit - crit0, p.g("flight")])
	# The action, and thousands of changes leave no drift.
	Tempo.set_to(p, 0)
	Actions.run(["tempo", 2], 1, {})
	if p.tempo != 2:
		fail("the tempo action gave %d" % p.tempo)
	for i in 3000:
		Tempo.set_to(p, (i * 7) % 11)
	Tempo.set_to(p, 0)
	if not _near(p.speed, speed0, 1e-9) or not _near(p.rate, rate0, 1e-9) or not _near(p.crit, crit0, 1e-9) or p.g("flight") != 0.0:
		fail("3000 tempo changes left a drift: speed x%.12f, rate x%.12f" % [p.speed / speed0, p.rate / rate0])
	# Training dummies give nothing.
	var d := Combat.spawn_enemy("dummy", p.x + 30, p.y, false, true)
	for i in 20:
		_blow(p, d)
	if p.tempo != 0:
		fail("a training dummy built tempo")
	# No other hero is touched.
	var hx := _arena("hexer")
	var e2 := _foe(hx.x + 60, hx.y)
	var s0 := hx.speed
	for i in 20:
		_blow(hx, e2)
	_kill(e2)
	Actions.run(["tempo", 3], 1, {})
	Combat.hurt_player(1, "the test")
	if hx.tempo != 0 or hx.speed != s0 or hx.rally_t != 0.0 or hx.rally_hp != 0:
		fail("another hero picked up tempo or rally")
	notes.append("tempo: 5 blows or a kill per point, +2.5%% speed and +4%% rate each (exact), +20%% crit in full flight, holds %.1f s then fades, a hit halves it, no drift after 3000 changes, other heroes untouched" % Tempo.GRACE)

# ---------- 3 ----------
func rally() -> void:
	var p := _arena()
	var e := _foe(p.x + 60, p.y)
	var hp0 := p.hp
	Combat.hurt_player(1, "the test")
	if p.hp != hp0 - 1 or not Rally.active(p) or p.rally_hp != 1:
		fail("a hit should start a rally: hp %d, active %s, at stake %d" % [p.hp, Rally.active(p), p.rally_hp])
	for i in 5:
		_blow(p, e)
	if p.hp != hp0 - 1 or not Rally.active(p):
		fail("rally ended after 5 blows")
	_blow(p, e)
	if p.hp != hp0 or Rally.active(p) or p.rally_cd <= 0:
		fail("6 blows should win the heart back: hp %d (want %d), cd %.1f" % [p.hp, hp0, p.rally_cd])
	# While it rests, a hit simply costs the heart.
	p.invuln = 0.0
	Combat.hurt_player(1, "the test")
	if Rally.active(p) or p.hp != hp0 - 1:
		fail("rally started again during its cooldown")
	# It comes back after the cooldown.
	var t := 0.0
	while p.rally_cd > 0 and t < 20.0:
		Rally.update(p, TB.DT)
		t += TB.DT
	if absf(t - Rally.COOLDOWN) > 0.05:
		fail("rally cooldown took %.2f s (want %.1f)" % [t, Rally.COOLDOWN])
	# Time runs out: the heart is gone.
	p.invuln = 0.0
	Combat.hurt_player(1, "the test")
	if not Rally.active(p):
		fail("rally did not return after its cooldown")
	t = 0.0
	while Rally.active(p) and t < 10.0:
		Rally.update(p, TB.DT)
		t += TB.DT
	if absf(t - Rally.WINDOW) > 0.05 or p.hp != hp0 - 2 or p.rally_hp != 0:
		fail("rally time-out: %.2f s, hp %d (want %d)" % [t, p.hp, hp0 - 2])
	for i in 10:
		_blow(p, e)
	if p.hp != hp0 - 2:
		fail("blows after the time-out still healed")
	# A second hit before it is won back loses it.
	p.rally_cd = 0.0
	p.invuln = 0.0
	Combat.hurt_player(1, "the test")
	p.invuln = 0.0
	Combat.hurt_player(1, "the test")
	if Rally.active(p) or p.hp != hp0 - 4:
		fail("a second hit should lose the rally: active %s, hp %d (want %d)" % [Rally.active(p), p.hp, hp0 - 4])
	# Kills count as three blows.
	p.rally_cd = 0.0
	p.invuln = 0.0
	Combat.hurt_player(1, "the test")
	_kill(_foe(p.x + 50, p.y + 20, 5.0))
	if not Rally.active(p):
		fail("one kill should not finish a rally")
	_kill(_foe(p.x + 50, p.y - 20, 5.0))
	if Rally.active(p) or p.hp != hp0 - 4:
		fail("two kills should win the heart back: hp %d (want %d)" % [p.hp, hp0 - 4])
	# A kill by the weapon itself is three blows, not four (the killing blow is not counted twice).
	p.rally_cd = 0.0
	p.invuln = 0.0
	p.hp = hp0
	Combat.hurt_player(1, "the test")
	p.aim_a = 0.0
	var weak := _foe(p.x + 18, p.y, 0.5)
	Combat.player_shoot(p, 0.0)
	if weak.hp > 0 or p.rally_prog != Rally.KILL_BLOWS or not Rally.active(p):
		fail("a melee kill counted %d blows (want %d)" % [p.rally_prog, Rally.KILL_BLOWS])
	Rally._end(p, false)
	# Healed to full by something else while it runs: the rally quietly ends, with no cooldown.
	p.rally_cd = 0.0
	p.invuln = 0.0
	p.hp = p.max_hp
	Combat.hurt_player(1, "the test")
	p.hp = p.max_hp
	Rally.update(p, TB.DT)
	if Rally.active(p) or p.rally_hp != 0 or p.rally_cd > 0:
		fail("a rally kept running at full health")
	p.hp = hp0 - 4
	# Armour takes the hit instead: nothing is at stake.
	p.rally_cd = 0.0
	p.invuln = 0.0
	p.armor = 1
	Combat.hurt_player(1, "the test")
	if Rally.active(p):
		fail("a hit on armour started a rally")
	# A hit while rolling does nothing at all.
	p.invuln = 0.0
	p.dodge_t = 0.2
	Combat.hurt_player(1, "the test")
	p.dodge_t = 0.0
	if Rally.active(p) or p.hp != hp0 - 4:
		fail("a dodged hit changed something")
	notes.append("rally: 6 blows (a kill counts 3) inside %.0f s win the heart back; cooldown %.0f s, time-out, a second hit and armour all behave" % [Rally.WINDOW, Rally.COOLDOWN])

# ---------- 4 ----------
func rolling() -> void:
	var p := _arena()
	var e := _foe(p.x + 24, p.y)
	var far := _foe(p.x + 24, p.y + 60)
	p.start_roll(Vector2(1, 0))
	var x0 := p.x
	while p.dodge_t > 0:
		p.update_move(TB.DT)
	if p.x - x0 < 40:
		fail("the roll only moved %.0f px" % (p.x - x0))
	if e.vuln_t <= 0 or p.ambush_left < 1:
		fail("rolling through a foe: exposed %.1f s, crits set up %d" % [e.vuln_t, p.ambush_left])
	if far.vuln_t > 0:
		fail("a foe far from the roll was exposed")
	if e.hp != e.max_hp:
		fail("a roll below full flight hurt the foe")
	# In full flight the roll cuts.
	p = _arena()
	e = _foe(p.x + 24, p.y)
	Tempo.set_to(p, 10)
	p.start_roll(Vector2(1, 0))
	while p.dodge_t > 0:
		p.update_move(TB.DT)
	var dealt := e.max_hp - e.hp
	var w := Weapons.wdmg(p)
	if dealt < w * 2.5 * 0.8 or e.vuln_t <= 0:
		fail("a full-flight roll dealt %.1f (want about %.1f)" % [dealt, w * 2.5])
	notes.append("rolls: a foe rolled through is exposed and the next strike crits; in full flight the roll cuts for 250%")

# ---------- 5 ----------
func dive() -> void:
	var p := _arena()
	var h: Dictionary = p.hero
	var e := _foe(p.x + 96, p.y)
	var side := _foe(p.x + 96, p.y + 26)
	var out := _foe(p.x + 96, p.y + 130)
	# A pillar squarely in the way: a walk or a ground dash would stop here.
	var pc := floori((p.x + 48) / TB.TS)
	var pr := floori(p.y / TB.TS)
	G.room.set_tile(pc, pr, World.T_PILLAR)
	G.room.set_tile(pc, pr - 1, World.T_PILLAR)
	G.room.set_tile(pc, pr + 1, World.T_PILLAR)
	EBullets.add(e.x + 10, e.y, 0, 0, "red", 3.0)
	p.aim_a = 0.0
	if not Abilities.ready(p):
		fail("Talon Dive not ready at the start")
	Abilities.use(p)
	if p.leap_max <= 0 or p.dash_t <= 0 or p.invuln <= 0:
		fail("the leap did not start (leap %.2f, dash %.2f, invuln %.2f)" % [p.leap_max, p.dash_t, p.invuln])
	var peak := 0.0
	var ticks := 0
	var hp0 := p.hp
	while p.leap_max > 0 and ticks < 200:
		p.update_move(TB.DT)
		Combat.hurt_player(1, "the test")   # nothing can touch the hero in the air
		peak = maxf(peak, p.air)
		ticks += 1
	if p.hp != hp0:
		fail("the hero was hurt in the air")
	if ticks >= 200:
		fail("the leap never landed")
	if peak < Abilities.LEAP_HEIGHT * 0.8 or p.air != 0.0:
		fail("leap height: peak %.1f, after landing %.1f" % [peak, p.air])
	if TB.dist(p, e) > 1.5:
		fail("the dive landed %.1f px from its target" % TB.dist(p, e))
	if World.hits_solid(G.room, p.x, p.y, p.r, World.M_PLAYER):
		fail("the dive landed inside a wall")
	var w := Weapons.wdmg(p)
	for f in [e, side]:
		var dealt: float = f.max_hp - f.hp
		if dealt < w * 3.0 * 0.8 or dealt > w * 3.0 * 1.2:
			fail("dive damage %.1f (want about %.1f)" % [dealt, w * 3.0])
		if f.stun_t <= 0 or f.vuln_t <= 0:
			fail("a foe under the dive was not stunned and exposed")
	if out.hp != out.max_hp or out.stun_t > 0:
		fail("a foe far from the landing was hit")
	if p.tempo != 2:
		fail("the dive gave %d tempo (want 2)" % p.tempo)
	if EBullets.any_near(p.x, p.y, 30.0):
		fail("the dive left enemy shots at the landing")
	var cd := float(h["special"]["cd"])
	var t := 0.0
	while not Abilities.ready(p) and t < 30.0:
		p.special_cd = maxf(0.0, p.special_cd - TB.DT)   # what Abilities.update does each tick
		t += TB.DT
	if absf(t - cd) > 0.05:
		fail("the dive was ready again after %.2f s (want %.1f)" % [t, cd])
	# No foe in reach: a leap ahead, and never a landing inside a pillar.
	p = _arena()
	var ahead: float = h["special"]["do"][0][2] * 0.6
	var c2 := floori((p.x + ahead) / TB.TS)
	var r2 := floori(p.y / TB.TS)
	G.room.set_tile(c2, r2, World.T_PILLAR)
	p.aim_a = 0.0
	var x0 := p.x
	Abilities.use(p)
	ticks = 0
	while p.leap_max > 0 and ticks < 200:
		p.update_move(TB.DT)
		ticks += 1
	if absf(p.x - x0) < 40:
		fail("a dive with no target only moved %.0f px" % absf(p.x - x0))
	if World.hits_solid(G.room, p.x, p.y, p.r, World.M_PLAYER):
		fail("a dive with no target landed inside a pillar")
	# Room walls and doors stop a leap.
	p = _arena()
	p.x = 25.0 * TB.TS
	p.aim_a = 0.0
	Abilities.use(p)
	ticks = 0
	while p.leap_max > 0 and ticks < 200:
		p.update_move(TB.DT)
		ticks += 1
	if p.x > 27.0 * TB.TS or World.hits_solid(G.room, p.x, p.y, p.r, World.M_PLAYER):
		fail("a dive left the room (x %.0f)" % p.x)
	# A guardian: the hero comes down at its feet, not inside it, and is not touched at once.
	p = _arena()
	var boss := Combat.spawn_boss(GameData.floors()[0]["boss"])
	boss.x = p.x + 90
	boss.y = p.y
	p.aim_a = 0.0
	Abilities.use(p)
	ticks = 0
	while p.leap_max > 0 and ticks < 200:
		p.update_move(TB.DT)
		ticks += 1
	var gap := TB.dist(p, boss)
	if gap < boss.r + p.r or gap > boss.r + p.r + 8:
		fail("the dive landed %.1f px from a guardian of radius %.0f" % [gap, boss.r])
	if boss.hp >= boss.max_hp:
		fail("a dive at a guardian's feet did not hit it")
	G.enemies.clear()
	G.boss = null
	# Out of a roll: the leap ends the roll.
	p = _arena()
	_foe(p.x + 80, p.y)
	p.start_roll(Vector2(0, 1))
	p.update_move(TB.DT)
	Abilities.use(p)
	if p.dodge_t != 0.0 or p.leap_max <= 0:
		fail("a dive out of a roll left the roll running (%.2f s)" % p.dodge_t)
	# Entering a room in mid-leap: the leap is dropped, nothing lands in the new room.
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s"))
	if p.leap_max != 0.0 or p.dash_t != 0.0 or p.air != 0.0 or not p.dash_end.is_empty():
		fail("a leap carried into the next room")
	# Doors: a leap from inside never goes through an open door, and one begun in a doorway still moves.
	p = _arena()
	G.locked = false
	G.open_exits()
	var door := ""
	for d in G.room.doors.keys():
		var dt0: Vector2i = World.door_tiles(d)[0]
		if not World.solid(G.room, dt0.x, dt0.y, World.M_PLAYER):
			door = d
	if door == "":
		fail("no open door to test the leap against")
	else:
		var dc := World.door_center(door)
		var inward := -Vector2(World.DIRS[door])
		# Open floor in front of the door, whatever the room's layout put there.
		for k in range(1, 5):
			for off in [-1, 0]:
				var tc := floori((dc.x + inward.x * k * 16.0 + (off * 16.0 if inward.x == 0 else 0.0)) / TB.TS)
				var trow := floori((dc.y + inward.y * k * 16.0 + (off * 16.0 if inward.y == 0 else 0.0)) / TB.TS)
				if G.room.tile(tc, trow) != World.T_WALL and G.room.tile(tc, trow) != World.T_DOOR:
					G.room.set_tile(tc, trow, World.T_FLOOR)
		p.x = dc.x + inward.x * 30
		p.y = dc.y + inward.y * 30
		p.aim_a = atan2(-inward.y, -inward.x)   # straight at the door
		var room0 := G.room
		Abilities.use(p)
		ticks = 0
		while p.leap_max > 0 and ticks < 200:
			p.update_move(TB.DT)
			ticks += 1
		if G.room != room0 or World.hits_solid(G.room, p.x, p.y, p.r, World.M_FLYER):
			fail("a leap at an open door ended at (%.0f, %.0f), in the doorway or beyond" % [p.x, p.y])
		p.special_cd = 0.0
		p.x = dc.x
		p.y = dc.y
		if World.hits_solid(G.room, p.x, p.y, p.r, World.M_PLAYER):
			fail("the test could not stand the hero in the doorway")
		p.aim_a = atan2(inward.y, inward.x)   # back into the room
		var from := Vector2(p.x, p.y)
		Abilities.use(p)
		ticks = 0
		while p.leap_max > 0 and ticks < 200:
			p.update_move(TB.DT)
			ticks += 1
		if from.distance_to(Vector2(p.x, p.y)) < 40:
			fail("a dive begun in a doorway only moved %.0f px" % from.distance_to(Vector2(p.x, p.y)))
	notes.append("talon dive: clears a pillar, lands on the foe aimed at, 300% in 46 px, stun, expose, shots erased, +2 tempo, untouchable in the air, never lands in a wall, stops at walls and doors, works from a doorway, lands at a guardian's feet, ends a roll, never carries into the next room")

# ---------- 6 ----------
func talons() -> void:
	var p := _arena()
	var behind := _foe(p.x - 26, p.y)
	var front := _foe(p.x + 20, p.y)
	p.aim_a = 0.0
	Combat.player_shoot(p, 0.0)
	Combat.player_shoot(p, 0.0)
	if behind.hp != behind.max_hp:
		fail("an ordinary strike hit a foe behind the hero")
	if front.hp >= front.max_hp:
		fail("an ordinary strike missed the foe in front")
	Combat.player_shoot(p, 0.0)
	var dealt := behind.max_hp - behind.hp
	var w := Weapons.wdmg(p)
	if dealt < w * 1.5 * 0.8 or dealt > w * 1.5 * 1.2:
		fail("the finisher dealt %.1f to a foe behind (want about %.1f)" % [dealt, w * 1.5])
	notes.append("iron talons: every third strike hits all round for 150%")

# ---------- 7 ----------
func branch() -> void:
	var p := _arena("gaolbird", [0, 0, 4])
	if p.g("tempo_hold") != 2.0 or p.g("rally_window") != 1.5 or p.g("rally_haste") != 3.0 or p.g("tempo_grit") != 1.0:
		fail("branch hooks: hold %s, window %s, haste %s, grit %s" % [p.g("tempo_hold"), p.g("rally_window"), p.g("rally_haste"), p.g("tempo_grit")])
	if p.dodge_charges != 2:
		fail("HOLLOW BONES: %d roll charges" % p.dodge_charges)
	var e := _foe(p.x + 60, p.y)
	# KEEP TIME: two more seconds before the fade.
	Tempo.set_to(p, 10)
	_blow(p, e)
	var t := 0.0
	while p.tempo == 10 and t < 10.0:
		Tempo.update(p, TB.DT)
		t += TB.DT
	if absf(t - (Tempo.GRACE + 2.0 + Tempo.FADE)) > 0.05:
		fail("KEEP TIME: tempo began to fade after %.2f s" % t)
	# MURDER OF CROWS: a hit costs 2, and full-flight kills loose 8 feathers.
	Tempo.set_to(p, 10)
	Combat.hurt_player(1, "the test")
	if p.tempo != 8:
		fail("MURDER OF CROWS: a hit left %d tempo (want 8)" % p.tempo)
	Rally._end(p, false)
	if absf(p.rally_cd - (Rally.COOLDOWN * 0.5 - 3.0)) > 0.01:
		fail("OLD GRUDGE: rally cooldown after a loss %.2f" % p.rally_cd)
	# ... and at low tempo the capstone is never worse than the plain rule (2 -> 1, not 0).
	Tempo.set_to(p, 2)
	p.invuln = 0.0
	p.rally_cd = 99.0
	Combat.hurt_player(1, "the test")
	if p.tempo != 1:
		fail("MURDER OF CROWS: a hit at 2 tempo left %d (want 1)" % p.tempo)
	p.rally_cd = 0.0
	p.invuln = 0.0
	p.hp = p.max_hp
	Tempo.set_to(p, 10)
	Combat.hurt_player(1, "the test")
	# OLD GRUDGE: a longer rally that returns sooner.
	if absf(p.rally_t - (Rally.WINDOW + 1.5)) > 0.01:
		fail("OLD GRUDGE: rally window %.2f" % p.rally_t)
	for i in 6:
		_blow(p, e)
	if absf(p.rally_cd - (Rally.COOLDOWN - 3.0)) > 0.01:
		fail("OLD GRUDGE: rally cooldown %.2f" % p.rally_cd)
	Tempo.set_to(p, 10)
	p.charges = 0
	var before := G.pbullets.size()
	_kill(_foe(p.x + 40, p.y, 5.0))
	var feathers := 0
	for b in G.pbullets:
		if b.kind == "feather":
			feathers += 1
	if feathers != 8 or G.pbullets.size() - before != 8:
		fail("MURDER OF CROWS: %d feathers from a full-flight kill" % feathers)
	if p.charges != 1:
		fail("HOLLOW BONES: a full-flight kill did not refund the roll")
	# Below full flight neither happens.
	Tempo.set_to(p, 5)
	p.charges = 0
	before = G.pbullets.size()
	_kill(_foe(p.x + 40, p.y + 10, 5.0))
	if G.pbullets.size() != before or p.charges != 0:
		fail("capstone effects fired below full flight")
	notes.append("branch: KEEP TIME, OLD GRUDGE, HOLLOW BONES and MURDER OF CROWS each do what they say")

## Cheating death, and dying, with tempo and a rally in play.
func dying() -> void:
	var p := _arena()
	p.revive = 1
	p.hp = 1
	Tempo.set_to(p, 10)
	Combat.hurt_player(1, "the test")
	if G.state != &"play" or p.hp != 4 or p.revive != 0 or p.tempo != 5 or Rally.active(p):
		fail("cheating death: state %s, hp %d, tempo %d, rally %s" % [G.state, p.hp, p.tempo, Rally.active(p)])
	p.invuln = 0.0
	p.hp = 2
	p.rally_cd = 0.0
	Combat.hurt_player(1, "the test")
	if not Rally.active(p) or p.hp != 1:
		fail("the hit before the last one should start a rally (hp %d)" % p.hp)
	p.invuln = 0.0
	Tempo.set_to(p, 10)
	Combat.hurt_player(1, "the test")
	if G.state != &"dead":
		fail("the hero should be dead (state %s, hp %d)" % [G.state, p.hp])
	var base: Dictionary = p.hero
	G.new_run()
	var q := G.player
	if q == p or q.tempo != 0 or not q.tempo_fx.is_empty() or Rally.active(q) or q.rally_hp != 0 or q.g("flight") != 0.0 \
			or not _near(q.speed, float(base["speed"])) or q.leap_max != 0.0:
		fail("a new run did not start clean: tempo %d, speed %.2f" % [q.tempo, q.speed])
	G.state = &"play"
	notes.append("death: cheating death halves tempo and stakes nothing; dying with a rally running ends the run and the next one starts clean")

# ---------- 8 ----------
func soak() -> void:
	var p := _arena("gaolbird", [4, 4, 4])
	G.room.waves_left = 2
	var worst := 0
	var dives := 0
	var top := 0
	var rallies := 0
	var was_rally := false
	for i in 1800:
		Keys.tick()
		if Abilities.ready(p) and G.enemies_active():
			Abilities.use(p)
			dives += 1
		if p.hp <= 2:
			p.hp = p.max_hp   # the soak is about errors, not survival
		if i % 300 == 150:
			p.invuln = 0.0
			p.dodge_t = 0.0
			Combat.hurt_player(1, "the test")
		var t0 := Time.get_ticks_usec()
		G.update(TB.DT)
		worst = maxi(worst, Time.get_ticks_usec() - t0)
		match G.state:
			&"traits":
				G.take_trait(G.tchoice["opts"][0])
				G.tchoice = {}
				G.state = &"play"
			&"choice":
				G.add_relic(G.player, G.choice["relics"][0])
				G.choice = {}
				G.state = &"play"
			&"pause", &"dead", &"win":
				G.state = &"play"
		if G.enemies.size() < 4:
			var s := World.free_spot(G.room, p, 40, World.M_FLYER)
			Combat.spawn_enemy(TB.pick(GameData.floors()[0]["pool"]), s.x, s.y, false, true)
		top = maxi(top, p.tempo)
		if was_rally and not Rally.active(p):
			rallies += 1
		was_rally = Rally.active(p)
		if p.tempo < 0 or p.tempo > p.tempo_max or p.hp > p.max_hp or p.hp <= 0:
			fail("soak tick %d: tempo %d, hp %d/%d" % [i, p.tempo, p.hp, p.max_hp])
			break
		if not is_finite(p.speed) or not is_finite(p.rate) or not is_finite(p.x) or p.speed <= 0:
			fail("soak tick %d: speed %s, rate %s" % [i, p.speed, p.rate])
			break
		if p.leap_max <= 0 and p.dash_t <= 0 and World.hits_solid(G.room, p.x, p.y, p.r - 0.5, World.M_WALKER):
			fail("soak tick %d: the hero is inside a wall at (%.0f, %.0f)" % [i, p.x, p.y])
			break
	if dives < 2:
		fail("soak: only %d dives in 30 s" % dives)
	if top < 6:
		fail("soak: tempo never passed %d" % top)
	Meta.meta["tree"].erase("gaolbird")
	notes.append("soak: 30 s of play with the whole tree, %d dives, top tempo %d, %d rallies ended, worst tick %.2f ms" % [dives, top, rallies, worst / 1000.0])

# ---------- 9 ----------
func _press(a: StringName) -> void:
	Input.action_press(a)
	Keys.tick()
	G.update(TB.DT)
	Input.action_release(a)
	Keys.tick()
	G.update(TB.DT)

func screen() -> void:
	G.fade = {}
	G.state = &"hero"
	G.hero_index = 0
	var order := GameData.hero_order()
	var seen := [0]
	for i in order.size() - 1:
		_press(&"move_right")
		seen.append(G.hero_index)
	if seen != order:
		fail("RIGHT on the hero screen visits %s, want %s" % [seen, order])
	_press(&"move_right")
	if G.hero_index != order[0]:
		fail("RIGHT past the last hero should wrap to the first")
	_press(&"move_left")
	if G.hero_index != order[order.size() - 1]:
		fail("LEFT from the first hero should wrap to the last")
	G.hero_index = _index("gaolbird")
	var saved: Dictionary = Meta.meta["unlocked"]
	Meta.meta["unlocked"] = {}
	_press(&"use")
	for i in 40:
		Keys.tick()
		G.update(TB.DT)
	Meta.meta["unlocked"] = saved
	if G.state != &"play" or G.player.hero["id"] != "gaolbird":
		fail("USE on the Gaolbird with a fresh save: state %s, hero %s" % [G.state, G.player.hero["id"]])
	notes.append("hero screen: free heroes first, wraps both ways, USE begins a run as the Gaolbird on a fresh save")
