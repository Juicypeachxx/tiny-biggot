extends Node
## The twenty new foes (scripts/entities/enemy_ai2.gd). Run: godot --headless --path . res://tests/foes_test.tscn -- --no-save
##   1. Data: sprites and elite sprites, a place in a pool, text that fits the font; --classic floors untouched.
##   2. Each foe, alone with the hero in an open room, does the thing that makes it different.
## Prints "foes test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL foes: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(777)
	_data()
	_each()
	print("foes test: PASSED" if fails == 0 else "foes test: %d FAILED" % fails)
	get_tree().quit()

func _data() -> void:
	var pooled := {}
	for t in Themes.LIST:
		for f in t["pool"]:
			pooled[f] = true
	for i in GameData.floors().size():
		for f in GameData.floors()[i]["pool"]:
			pooled[f] = true
	for ai in EnemyAI2.AIS:
		if not GameData.ENEMIES.has(ai):
			fail("%s: no data" % ai)
			continue
		var d: Dictionary = GameData.ENEMIES[ai]
		for spr in [d["sprite"], d["sprite"] + "_elite"]:
			if not Img.has(spr):
				fail("%s: no sprite %s" % [ai, spr])
		if ai != "beltlink" and not pooled.has(ai):
			fail("%s: in no pool" % ai)
		if not GameData.SPRITE_COLOR.has(ai) or not GameData.ENEMY_XP.has(ai):
			fail("%s: no colour or xp" % ai)
		for ch in str(d.get("label", "")).to_upper():
			if not ch in Gfx.FONT_CHARS:
				fail("%s: label character %s" % [ai, ch])
	# The original floors' own data is unchanged (the extras are added to copies).
	for i in GameData.FLOORS.size():
		for f in GameData.FLOORS[i]["pool"]:
			if f in EnemyAI2.AIS:
				fail("original floor %d data holds %s" % [i, f])

# ---------- A small arena ----------
func _arena() -> Player:
	G.hero_index = 0
	G.new_run()
	G.floor_d["depth"] = 2
	G.enter_room(World.make_room(G.floor_d, "treasure", "", "s"))
	G.room.objects.clear()
	for r in range(TB.IY0, TB.IY0 + TB.IH):
		for c in range(TB.IX0, TB.IX0 + TB.IW):
			G.room.set_tile(c, r, World.T_FLOOR)
	G.enemies.clear()
	EBullets.clear()
	G.room.goo.clear()
	G.room.tides.clear()
	G.room.marks.clear()
	var p := G.player
	p.x = 14.0 * TB.TS
	p.y = 10.0 * TB.TS
	G.god = true
	Meta.opts["autofire"] = false   # no shots knocking the foes about
	return p

func _foe(type: String, x: float, y: float, elite := false) -> Enemy:
	var e := Combat.spawn_enemy(type, x, y, elite, true)
	e.spawn_t = 0.0
	e.max_hp = 9999.0
	e.hp = 9999.0
	return e

func _tick(n: int, hold := true) -> void:
	var p := G.player
	for i in n:
		var px := p.x
		var py := p.y
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}
		if hold:
			p.x = px
			p.y = py

func _each() -> void:
	var p: Player
	var e: Enemy
	# Sky kite: circles at a distance and drops mines.
	p = _arena()
	e = _foe("skykite", 100, 100)
	_tick(300)
	var d := TB.dist(e, p)
	if d < 40 or d > 110 or EBullets.n == 0:
		fail("skykite: did not circle (%.0f px) or drop mines (%d shots)" % [d, EBullets.n])
	# Gustling: swells beside you and blasts you away.
	p = _arena()
	e = _foe("gustling", p.x + 30, p.y)
	var x0 := p.x
	var moved := false
	for i in 200:
		_tick(1, false)
		if absf(p.x - x0) > 25:
			moved = true
			break
	if not moved:
		fail("gustling: never blew the hero away")
	# Storm harpy: marks a spot, then lands on it.
	p = _arena()
	e = _foe("stormharpy", 100, 100)
	var marked := Vector2.ZERO
	var landed := false
	for i in 400:
		_tick(1)
		if e.state == &"mark":
			marked = e.target
		if e.state == &"dive":
			_tick(30)
			landed = TB.dist_xy(e.x, e.y, marked.x, marked.y) < 14
			break
	if not landed:
		fail("stormharpy: did not dive onto its mark")
	# Thunderhead: marks strikes on the floor.
	p = _arena()
	e = _foe("thunderhead", 100, 100)
	var struck := false
	for i in 300:
		_tick(1)
		if not G.room.marks.is_empty():
			struck = true
			break
	if not struck:
		fail("thunderhead: called no strike")
	# Mirrorwing: settles at the hero's mirror image through the middle.
	p = _arena()
	p.x = 120.0
	p.y = 100.0
	e = _foe("mirrorwing", 200, 200)
	_tick(240)
	if TB.dist_xy(e.x, e.y, 28.0 * TB.TS - 120.0, 19.0 * TB.TS - 100.0) > 16:
		fail("mirrorwing: not at the mirror image (%.0f, %.0f)" % [e.x, e.y])
	# Rampart guard: the shield in front takes most of a hit; from behind it does not.
	p = _arena()
	e = _foe("rampartguard", p.x + 40, p.y)
	_tick(60)
	e.ca = TB.ang_to(e, p)
	var front := EnemyAI2.adjust_damage(e, 100.0)
	e.ca += PI
	var back := EnemyAI2.adjust_damage(e, 100.0)
	if front > 30.0 or back < 99.0:
		fail("rampartguard: front %.0f, back %.0f" % [front, back])
	# Sludge crawler: leaves sludge; standing in it hurts.
	p = _arena()
	e = _foe("sludgecrawler", 120, 120)
	_tick(120)
	if not G.room.goo.any(func(g): return g["kind"] == "sludge"):
		fail("sludgecrawler: left no sludge")
	else:
		G.enemies.clear()
		var g0: Dictionary = G.room.goo[0]
		g0["t"] = 9.0
		p.x = g0["x"]
		p.y = g0["y"]
		G.god = false
		p.invuln = 0.0
		var hp0 := p.hp + p.armor
		_tick(45)
		G.god = true
		if p.hp + p.armor >= hp0:
			fail("sludgecrawler: standing in sludge did not hurt")
	# Chain warden: the hook drags you in.
	p = _arena()
	e = _foe("chainwarden", p.x - 120, p.y)
	var pulled := false
	for i in 400:
		var before := TB.dist(e, p)
		_tick(1, false)
		if before - TB.dist(e, p) > 40:
			pulled = true
			break
	if not pulled:
		fail("chainwarden: never dragged the hero in")
	# Tidecaller: calls a wave.
	p = _arena()
	e = _foe("tidecaller", 100, 100)
	_tick(360)
	if G.room.tides.is_empty() and not e.t > 0:
		fail("tidecaller: called no wave")
	# Longpike: a thrust along its lane hurts.
	p = _arena()
	e = _foe("longpike", p.x - 55, p.y)
	G.god = false
	var hp1 := p.hp + p.armor
	for i in 300:
		p.invuln = 0.0
		p.dodge_t = 0.0
		_tick(1)
		if p.hp + p.armor < hp1:
			break
	G.god = true
	if p.hp + p.armor >= hp1:
		fail("longpike: its thrust never landed")
	# Shell priest: a wide blast that kicks it back.
	p = _arena()
	e = _foe("shellpriest", p.x - 70, p.y)
	var kicked := false
	for i in 300:
		var ex := e.x
		_tick(1)
		if EBullets.n >= 7 and e.x < ex - 1.5:
			kicked = true
			break
	if not kicked:
		fail("shellpriest: no blast with recoil")
	# Dervish: spins, then stands dizzy and takes more damage.
	p = _arena()
	e = _foe("dervish", p.x - 70, p.y)
	var dizzy := false
	for i in 500:
		_tick(1)
		if e.state == &"dizzy":
			dizzy = true
			break
	if not dizzy or EnemyAI2.adjust_damage(e, 100.0) < 149.0:
		fail("dervish: never dizzy, or no extra damage when dizzy")
	# Deacon: shields the foes near it.
	p = _arena()
	e = _foe("deacon", 150, 150)
	var ally := _foe("skeleton", 160, 150)
	_tick(300)
	if ally.guard_t <= 0 and e.t > 3.5:
		pass
	var shielded := false
	for i in 300:
		_tick(1)
		if ally.guard_t > 0:
			shielded = true
			break
	if not shielded or EnemyAI2.adjust_damage(ally, 100.0) > 51.0:
		fail("deacon: no shield on its ally")
	# Belt feeder: three links that follow it.
	p = _arena()
	e = _foe("beltfeeder", 120, 120)
	_tick(120)
	var links := G.enemies.filter(func(o): return o.type == "beltlink")
	if links.size() != 3:
		fail("beltfeeder: %d links" % links.size())
	elif TB.dist(links[0], e) > 40:
		fail("beltfeeder: its links do not follow")
	# Ammo mimic: hidden as a crate until the hero comes near.
	p = _arena()
	e = _foe("ammomimic", p.x + 120, p.y)
	_tick(20)
	if not e.hidden:
		fail("ammomimic: not asleep at first")
	p.x = e.x - 30
	_tick(5)
	if e.hidden:
		fail("ammomimic: did not wake when the hero came near")
	# Tomb spider: a web on the floor slows the hero.
	p = _arena()
	e = _foe("tombspider", p.x + 60, p.y)
	_tick(300)
	var webs := G.room.goo.filter(func(g): return g["kind"] == "web")
	if webs.is_empty():
		fail("tombspider: spun no web")
	else:
		p.x = webs[0]["x"]
		p.y = webs[0]["y"]
		if not EnemyAI2.in_web(p):
			fail("tombspider: the web does not hold the hero")
	# Candlewight: lit, then out (and unhittable), then lit again.
	p = _arena()
	e = _foe("candlewight", 100, 100)
	var states := {}
	for i in 400:
		_tick(1)
		states[e.hidden] = true
	if states.size() != 2:
		fail("candlewight: its candle never went out and back")
	# Gargoyle: still while you are still; moves while you move.
	p = _arena()
	e = _foe("gargoyle", p.x + 80, p.y)
	_tick(5)
	var gx := e.x
	_tick(60)
	if absf(e.x - gx) > 0.5:
		fail("gargoyle: moved while the hero stood still")
	var gx2 := e.x
	for i in 30:
		p.x += 0.5
		_tick(1, false)
	if absf(e.x - gx2) < 3:
		fail("gargoyle: did not move while the hero moved")
	# War drummer: the foes around it speed up, then slow back down.
	p = _arena()
	e = _foe("wardrummer", 100, 100)
	var other := _foe("skeleton", 300, 200)
	var s0 := other.speed
	var hasted := false
	for i in 400:
		_tick(1)
		if other.speed > s0 * 1.4:
			hasted = true
			break
	_tick(180)
	if not hasted or absf(other.speed - s0) > 0.01:
		fail("wardrummer: haste %s, speed now %.1f of %.1f" % [hasted, other.speed, s0])
	# Blood leech: latches on; a roll shakes it off; otherwise it drinks.
	p = _arena()
	e = _foe("bloodleech", p.x + 12, p.y)
	var latched := false
	for i in 120:
		_tick(1)
		if e.state == &"latched":
			latched = true
			break
	if not latched:
		fail("bloodleech: never latched on")
	else:
		p.dodge_t = 0.3
		_tick(2)
		if e.state == &"latched":
			fail("bloodleech: a roll did not shake it off")
