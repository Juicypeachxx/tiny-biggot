extends Node
## Stage 56 (his playthrough, 12 Oct: "the bosses just melts in seconds, also make bosses be visible
## when attacking ... make later bosses harder and have beaffier healthpools and armor and new mechanic
## also new attack patterens for all boses"; scripts/combat/resolve.gd, patterns.gd). Run:
##   godot --headless --path . res://tests/stage56_test.tscn -- --no-save
##   1. Deeper guardians: more health, a bigger plate, less through it (as before on the first floor).
##   2. RESOLVE: a blow of any size takes at most the resolve of a guardian's health; then it is
##      UNBROKEN: no blow hurts it, not even its plate; 3.5 s later the bar is empty and blows land.
##      Its signature answers. A build slower than the bar empties never makes it UNBROKEN.
##   3. The broken build: a blow of a billion every tick fells a tenth-floor guardian in no less than
##      its t_min, and it does fall.
##   4. Every guardian has its new patterns: all of them in stages 2 and 3, its signature in stage 1
##      from the fourth floor on; a rift guardian adds one of its own now and then.
##   5. Every pattern plays out, can hurt a hero who stands in it, and comes to an end; they are
##      cleared with the room; the drawing does not fail.
##   6. --classic: none of it (no resolve, no new patterns, the old health and plates).
##   7. 56.6 (his question: "What about normal rooms scaling"): the measure of your strength
##      (Combat.power) sees overkill (a blow counts up to 20 s of a plain build, not only twice the
##      foe's health) and only fighting time (a wait for the next wave does not lower it), so a build
##      that kills every foe in one blow makes the next foes tougher. A blow within twice the foe's
##      health counts as it did.
## Prints "stage56 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage56: ", msg)

func _run(fl: int) -> Player:
	G.hero_index = 0
	G.new_run()
	G.god = true
	G.floor_index = fl
	G.start_floor()
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.enemies.clear()
	G.room.waves_left = 0
	G.locked = true
	G.state = &"play"
	Meta.opts["autofire"] = false
	return G.player

func _boss(key: String) -> Enemy:
	var e := Combat.spawn_boss(key, true)
	e.state = &"rest"
	e.t = 99.0
	e.spawn_t = 0.0
	return e

func play(ticks: int) -> void:
	for i in ticks:
		G.player.hp = G.player.max_hp
		G.player.invuln = 0.0
		Keys.tick()
		G.update(TB.DT)
		match G.state:
			&"traits":
				G.take_trait(G.tchoice["opts"][0])
				G.tchoice = {}
				G.state = &"play"
			&"choice":
				G.choice = {}
				G.state = &"play"
			&"pause", &"dead":
				G.state = &"play"

func _ready() -> void:
	await get_tree().process_frame
	seed(56)
	_depth()
	_resolve()
	_broken()
	_plans()
	await _patterns()
	_rooms()
	_classic()
	_harder()
	print("stage56 test: PASSED" if fails == 0 else "stage56 test: %d FAILED" % fails)
	get_tree().quit()

# ---------- 1 ----------
func _depth() -> void:
	_run(0)
	var e := _boss("colossus")
	if absf(Combat.boss_hp() - 2.0) > 0.001 or absf(Armor.plate(e) / e.max_hp - 0.35) > 0.001 or absf(Armor.through(e) - 0.25) > 0.001:
		fail("the first floor changed: health x%.2f, plate %.2f, through %.3f (want 2, 0.35, 0.25)" % [Combat.boss_hp(), Armor.plate(e) / e.max_hp, Armor.through(e)])
	if absf(Resolve.t_min() - 30.0) > 0.01:   # (57: 30 s + 7 s a floor, was 25 s + 6 s)
		fail("the first floor's fewest seconds: %.1f (want 30)" % Resolve.t_min())
	_run(10)
	e = _boss("crowking")
	if absf(Combat.boss_hp() - 3.4) > 0.001 or absf(Armor.plate(e) / e.max_hp - 0.5) > 0.001 or absf(Armor.through(e) - 0.17) > 0.001:
		fail("the eleventh floor: health x%.2f, plate %.2f, through %.3f (want 3.4, 0.5, 0.17)" % [Combat.boss_hp(), Armor.plate(e) / e.max_hp, Armor.through(e)])
	if absf(Resolve.t_min() - 100.0) > 0.01:
		fail("the eleventh floor's fewest seconds: %.1f (want 100)" % Resolve.t_min())
	G.loop = 3
	if Resolve.t_min() > 140.0 or Combat.boss_hp() > 2.0 * 1.84 + 0.001:
		fail("deep loops: %.1f s, health x%.2f (want at most 140 s, x3.68)" % [Resolve.t_min(), Combat.boss_hp()])
	G.loop = 0

# ---------- 2 ----------
func _resolve() -> void:
	_run(5)
	var e := _boss("regent")
	e.armor_stage = Armor._key(e)   # (no plate: the health takes the blows whole)
	e.armor = 0.0
	var hp0 := e.hp
	Combat.damage_enemy(e, 1e9, { "no_crit": true, "no_mult": true })
	var took := (hp0 - e.hp) / e.max_hp
	if absf(took - Resolve.cap()) > 0.002 or e.unbroken_t <= 0:
		fail("a blow of a billion took %.3f of its health (want its resolve %.3f), UNBROKEN %.1f" % [took, Resolve.cap(), e.unbroken_t])
	if not Patterns.busy():
		fail("UNBROKEN without its signature")
	var hp1 := e.hp
	var a1 := e.armor
	Combat.damage_enemy(e, 1e9, { "no_crit": true, "no_mult": true })
	if e.hp != hp1 or e.armor != a1:
		fail("a blow on an UNBROKEN guardian hurt it (%.0f -> %.0f)" % [hp1, e.hp])
	for i in int(Resolve.IMMUNE * 60.0) + 2:
		Resolve.tick(TB.DT)
	if e.unbroken_t > 0 or e.resolve > 0.0:
		fail("3.5 s on it is still UNBROKEN (%.2f) or the bar is not empty (%.3f)" % [e.unbroken_t, e.resolve])
	var hp2 := e.hp
	Combat.damage_enemy(e, 10.0, { "no_crit": true, "no_mult": true })
	if hp2 - e.hp <= 0.0:
		fail("after UNBROKEN a blow does not land")
	# A build slower than the bar empties never meets it.
	Patterns.clear()
	e.resolve = 0.0
	var per_tick := 0.7 * Resolve.drain() * e.max_hp / 60.0
	for i in 600:
		Combat.damage_enemy(e, per_tick, { "no_crit": true, "no_mult": true })
		Resolve.tick(TB.DT)
		if e.unbroken_t > 0:
			fail("a slow build (70%% of the drain) made it UNBROKEN after %.1f s" % (i / 60.0))
			break
	# Rex, the good boy, has none of it.
	var rex := Enemy.new()
	rex.type = "boss"
	rex.boss = "rex"
	if Resolve.on(rex):
		fail("Rex has a resolve")

# ---------- 3 ----------
func _broken() -> void:
	_run(9)
	var e := Combat.spawn_boss("crowking", true)
	e.spawn_t = 0.0
	var tmin := Resolve.t_min()
	var t := 0.0
	while t < tmin * 2.5 and e.hp > 0:
		Combat.damage_enemy(e, 1e9, { "no_crit": true, "no_mult": true })
		play(1)
		t += TB.DT
	if e.hp > 0:
		fail("a billion a tick did not fell the tenth-floor guardian in %.0f s (%.0f%% left)" % [t, 100.0 * e.hp / e.max_hp])
	elif t < tmin * 0.95:
		fail("a billion a tick felled the tenth-floor guardian in %.1f s (want at least %.0f)" % [t, tmin])
	Patterns.clear()
	Chaos.clear()
	EBullets.clear_all()

# ---------- 4 ----------
func _plans() -> void:
	for fl in [1, 6]:
		_run(fl)
		for key in BossAI.BOSS_PLANS:
			var e := Enemy.new()
			e.type = "boss"
			e.boss = key
			e.d = GameData.BOSSES[key]
			var mine := Patterns.of(e)
			if mine.size() < 2:
				fail("%s has %d new patterns" % [key, mine.size()])
			for k in mine:
				if not k in Patterns.KINDS:
					fail("%s: no such pattern %s" % [key, k])
			var s1 := Patterns.plan(e, BossAI.BOSS_PLANS[key], 1)
			if (mine[0] in s1) != (fl >= 3) and not mine[0] in BossAI.BOSS_PLANS[key]:
				fail("%s on floor %d: its signature in stage 1 is %s" % [key, fl + 1, mine[0] in s1])
			for st in [2, 3]:
				var base: Array = BossAI.STAGE_PLANS[key][st - 2] if BossAI.STAGE_PLANS.has(key) else BossAI.BOSS_PLANS[key]
				var pl := Patterns.plan(e, base, st)
				for k in mine:
					if not k in pl:
						fail("%s stage %d lacks its %s" % [key, st, k])
				for k in base:
					if not k in pl:
						fail("%s stage %d lost its %s" % [key, st, k])
	# A rift guardian adds one of its own now and then.
	_run(4)
	var key := ""
	for k in RiftBosses.PLANS:
		if k != "rex" and GameData.BOSSES.has(k):
			key = k
			break
	if key == "":
		fail("no rift guardian to try")
	else:
		var e := Combat.spawn_boss(key, true)
		e.spawn_t = 0.0
		e.state = &"pick"
		Patterns.clear()
		e.pat_t = 0.05
		Resolve.tick(0.1)
		if not Patterns.busy():
			fail("the rift guardian %s added no pattern of its own" % key)
	Patterns.clear()

# ---------- 5 ----------
func _patterns() -> void:
	var drawn := Node2D.new()
	add_child(drawn)
	drawn.draw.connect(func():
		Patterns.draw_ground(drawn, G.time)
		Patterns.draw_over(drawn, G.time))
	for kind in Patterns.KINDS:
		for hard in [false, true]:
			var p := _run(6)
			var e := _boss("judge")
			e.x = 224.0
			e.y = 90.0
			p.x = 224.0
			p.y = 170.0
			Patterns.clear()
			EBullets.clear_all()
			var wait := Patterns.cast(e, kind, hard)
			if wait <= 0.0 or not Patterns.busy():
				fail("%s (hard %s) did not start" % [kind, hard])
				continue
			drawn.queue_redraw()
			for r in range(4, 16):   # (an open floor: pillars stop shots)
				for c in range(2, 26):
					G.room.grid[r * TB.COLS + c] = World.T_FLOOR
			var hurt := 0
			var t := 0.0
			var after := 2.5   # (its last shots land after it is cast)
			while (Patterns.busy() or after > 0.0) and t < 15.0:
				if not Patterns.busy():
					after -= TB.DT
				var hp := p.hp
				G.god = false
				p.invuln = 0.0
				Keys.tick()
				G.update(TB.DT)
				G.god = true
				if p.hp < hp:
					hurt += 1
				p.hp = p.max_hp
				p.x = 224.0 if kind != "grid" else (GRID_SPOT(Patterns.grids))
				p.y = 170.0 if kind != "grid" else 150.0
				t += TB.DT
				if fmod(t, 0.5) < TB.DT:
					drawn.queue_redraw()
					await get_tree().process_frame
			if Patterns.busy():
				fail("%s (hard %s) still going after 15 s" % [kind, hard])
			if hurt == 0:
				fail("%s (hard %s) never hurt a hero standing in it" % [kind, hard])
			Patterns.cast(e, kind, hard)
			G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
			if Patterns.busy():
				fail("%s outlived the room" % kind)
			EBullets.clear_all()
	drawn.free()

## Where the hero stands for the grid: a square the first wave lights.
func GRID_SPOT(grids: Array) -> float:
	if grids.is_empty():
		return 224.0
	for i in 24:
		if Patterns._lit(grids[0], i) and i / 6 == 1:
			return Patterns._cell(i).get_center().x
	return 224.0

# ---------- 7 ----------
func _rooms() -> void:
	var p := _run(4)
	G.run_stats["power0"] = 40.0
	G.run_stats["dps"] = 0.0
	G.run_stats["dealt"] = 0.0
	var e := Combat.spawn_enemy("slime", p.x + 40.0, p.y, false, true)
	e.spawn_t = 0.0
	var cap := Combat.blow_cap(e)
	if absf(cap - 20.0 * Combat.yardstick()) > 0.01 or cap <= e.max_hp * 2.0:
		fail("a weak foe's blow cap is %.0f (want 20 s of a plain build: %.0f)" % [cap, 20.0 * Combat.yardstick()])
	# A small blow counts whole (each blow rolls its damage: what it took is the blow).
	var hp_a := e.hp
	Combat.damage_enemy(e, e.max_hp * 0.4, { "no_crit": true, "no_mult": true })
	var small: float = G.run_stats.get("dealt", 0.0)
	if absf(small - (hp_a - e.hp)) > 0.01 * e.max_hp:
		fail("a blow that took %.1f of a foe's health counted %.1f" % [hp_a - e.hp, small])
	G.run_stats["dealt"] = 0.0
	# A blow a thousand times its health: the overkill counts, up to the cap.
	Combat.damage_enemy(e, e.max_hp * 1000.0, { "no_crit": true, "no_mult": true })
	var big: float = G.run_stats.get("dealt", 0.0)
	if absf(big - minf(e.max_hp * 1000.0, cap)) > 0.01 * big or big <= e.max_hp * 2.0:
		fail("a blow of a thousand times a foe's health counted %.0f (want %.0f)" % [big, minf(e.max_hp * 1000.0, cap)])
	G.locked = true
	Combat.track_power(TB.DT)
	var after_kill: float = G.run_stats["dps"]
	if after_kill <= 0.0:
		fail("a kill did not move the measure (dps %.1f)" % after_kill)
	# The wait for the next wave (locked, nobody there, nothing dealt) does not lower it.
	G.enemies.clear()
	for i in 300:
		Combat.track_power(TB.DT)
	if absf(G.run_stats["dps"] - after_kill) > 0.001:
		fail("five seconds of waiting moved the measure from %.1f to %.1f" % [after_kill, G.run_stats["dps"]])
	# One-blow kills, wave after wave: the next foes are tougher.
	G.run_stats["dps"] = 0.0
	var hp0 := Combat.floor_scale()
	for wave in 30:
		for k in 6:
			var f := Combat.spawn_enemy("slime", p.x + 40.0, p.y + k, false, true)
			f.spawn_t = 0.0
			Combat.damage_enemy(f, f.max_hp * 500.0, { "no_crit": true, "no_mult": true })
		Combat.track_power(TB.DT)
		G.enemies.clear()
		for i in 120:
			Combat.track_power(TB.DT)   # (the wait for the next wave)
	if Combat.power_scale() < 3.0 or Combat.floor_scale() < hp0 * 3.0:
		fail("thirty waves killed in one blow each: foes x%.2f health (want at least x3)" % (Combat.floor_scale() / hp0))
	# The curve: the lead to the power of 0.7 up to ten times ahead (57: was 0.65), then closer (100
	# times ahead: 40 times the health).
	for want in [[1.0, 1.0], [5.0, pow(5.0, 0.7)], [10.0, pow(10.0, 0.7)], [100.0, pow(10.0, 0.7) * pow(10.0, 0.9)]]:
		G.run_stats["dps"] = want[0] * Combat.yardstick()
		if absf(Combat.power_scale() - want[1]) > 0.01 * want[1]:
			fail("%.0f times ahead: foes x%.2f health (want x%.2f)" % [want[0], Combat.power_scale(), want[1]])
	G.locked = false
	G.enemies.clear()

# ---------- 6 ----------
func _classic() -> void:
	GameData.force_classic = true
	_run(8)
	var e := Combat.spawn_boss("colossus", true)
	if Resolve.on(e) or Combat.boss_hp() != 1.0 or Armor.has(e):
		fail("--classic: resolve %s, health x%.2f, a plate %s" % [Resolve.on(e), Combat.boss_hp(), Armor.has(e)])
	if Patterns.plan(e, BossAI.BOSS_PLANS["colossus"], 2) != BossAI.BOSS_PLANS["colossus"]:
		fail("--classic: the colossus' plan changed")
	if Patterns.cast(e, "grid", true) > 0.3 or Patterns.busy():
		fail("--classic: a new pattern was cast")
	GameData.force_classic = false

# ---------- 7 (Stage 57) ----------
## 57 (his ask, 12 Oct: "Crank difficulty alittle bit more up in normal rooms and at bosses"): foes
## 60% more health on the first floor and 7% more a floor (Combat.hard_hp, was 45% and 6%), their
## shots 15% faster (was 10%), a guardian rests 15% less between attacks (BossAI.done and
## RiftBosses._done; its warnings as long as before); --classic: none of it.
func _harder() -> void:
	_run(0)
	if absf(Combat.hard_hp() - 1.6) > 0.001 or absf(Combat.shot_mult() - 1.15) > 0.001 or absf(BossAI.rest() - 0.85) > 0.001:
		fail("57, the first floor: foes x%.2f health, shots x%.2f, rest x%.2f (want 1.6, 1.15, 0.85)" % [Combat.hard_hp(), Combat.shot_mult(), BossAI.rest()])
	var e := _boss("colossus")
	e.stage = 1
	e.hp = e.max_hp
	BossAI.done(e, 1.0)
	if absf(e.t - 0.85) > 0.001:
		fail("57: a guardian's rest after an attack %.2f s (want 0.85)" % e.t)
	G.enemies.clear()
	_run(10)
	if absf(Combat.hard_hp() - 2.3) > 0.001:
		fail("57, the eleventh floor: foes x%.2f health (want 2.3)" % Combat.hard_hp())
	GameData.force_classic = true
	_run(10)
	e = _boss("colossus")
	e.stage = 1
	e.hp = e.max_hp
	BossAI.done(e, 1.0)
	if Combat.hard_hp() != 1.0 or Combat.shot_mult() != 1.0 or BossAI.rest() != 1.0 or absf(e.t - 1.0) > 0.001:
		fail("57 --classic: foes x%.2f health, shots x%.2f, rest %.2f s (want 1, 1, 1)" % [Combat.hard_hp(), Combat.shot_mult(), e.t])
	G.enemies.clear()
	GameData.force_classic = false
