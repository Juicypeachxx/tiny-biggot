extends Node
## 9.1 Chaos attacks (scripts/combat/chaos.gd). Run:
##   godot --headless --path . res://tests/chaos_test.tscn -- --no-save
##   1. A laser never hurts during its warning, and does when it lights on you.
##   2. A chain hook hurts what it sweeps through; a danger circle hurts inside, not outside.
##   3. Never more than eight lasers or chains at once; everything goes when the boss falls.
##   4. The last guardians and the Unwritten carry the new moves.
## Prints "chaos test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL chaos: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(91)
	G.hero_index = 0
	G.new_run()
	G.floor_index = 10
	G.start_floor()
	var p := G.player
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.enemies.clear()
	var e := Combat.spawn_enemy("skeleton", p.x, p.y - 80.0, false, true)
	e.speed = 0.0
	# 1. A laser straight at the hero.
	Chaos.clear()
	Chaos.cast_beams(e, 1, 0.5, 1.0, 0.0)
	Chaos.beams[0]["a"] = TB.ang_to(e, p)
	var hp0 := _hp_after(0.4)
	if hp0 < p.max_hp:
		fail("a laser hurt during its warning")
	if _hp_after(0.3) >= p.max_hp:
		fail("a lit laser on the hero did not hurt")
	# 2. A hook, then circles.
	Chaos.clear()
	Chaos.cast_hooks(e, 1, 1.0)
	Chaos.hooks[0]["a"] = TB.ang_to(e, p)
	if _hp_after(0.6) >= p.max_hp:
		fail("a chain flung at the hero did not hurt")
	Chaos.clear()
	Chaos.zones.append({ "x": p.x, "y": p.y, "r": 40.0, "warn": 0.3, "t": 0.0, "by": "TEST", "ring": "" })
	if _hp_after(0.2) < p.max_hp:
		fail("a circle hurt before it blasted")
	if _hp_after(0.3) >= p.max_hp:
		fail("a circle did not hurt the hero inside it")
	Chaos.clear()
	Chaos.zones.append({ "x": p.x + 120.0, "y": p.y, "r": 40.0, "warn": 0.1, "t": 0.0, "by": "TEST", "ring": "" })
	if _hp_after(0.3) < p.max_hp:
		fail("a circle hurt the hero outside it")
	# 3. Caps, and the boss falling.
	Chaos.clear()
	for i in 6:
		Chaos.cast_beams(e, 4, 0.5, 2.0, 0.5)
		Chaos.cast_hooks(e, 4, 1.0)
	if Chaos.beams.size() > 11 or Chaos.hooks.size() > 11:
		fail("%d lasers and %d chains at once" % [Chaos.beams.size(), Chaos.hooks.size()])
	e.hp = 0
	Chaos.tick(TB.DT)
	if not Chaos.beams.is_empty() or not Chaos.hooks.is_empty():
		fail("lasers or chains outlived their boss")
	# 4. The plans.
	for key in ["crowking", "umbralsun", "judge", "cinderking", "unwritten"]:
		var all := str(BossAI.BOSS_PLANS[key]) + str(BossAI.STAGE_PLANS[key])
		if not ("lasers" in all or "laserx" in all) or not ("hooks" in all or "zone" in all):
			fail("%s has too few chaos moves" % key)
	# 5. 9.3: the second guardians. Each floor shows both over a few runs; the phoenix rises once.
	for f in GameData.ALT_GUARDIANS:
		var key: String = GameData.ALT_GUARDIANS[f]
		if not GameData.BOSSES.has(key) or not BossAI.BOSS_PLANS.has(key) or not BossAI.STAGE_PLANS.has(key) or not BossLoot.DROPS.has(key):
			fail("second guardian %s is missing a part" % key)
			continue
		var seen := {}
		for k in 30:
			G.floor_index = f
			G.start_floor()
			seen[G.floor_d.get("guardian", "base")] = true
		if not seen.has(key) or not seen.has("base"):
			fail("floor %d never met both its guardians: %s" % [f + 1, seen.keys()])
	var ph := Combat.spawn_boss("phoenix")
	G.god = true
	ph.phase = 2
	ph.stage = 3
	Combat.damage_enemy(ph, ph.hp * 3.0 + Armor.shown(ph) * 3.0 + 10.0, { "no_crit": true, "no_mult": true })
	if ph.hp <= 0 or ph.phase != 3:
		fail("the phoenix did not rise (hp %.0f, phase %d)" % [ph.hp, ph.phase])
	print("chaos test: PASSED" if fails == 0 else "chaos test: %d FAILED" % fails)
	get_tree().quit()

## The hero's health after s seconds of Chaos ticks, starting from full and unhurt.
func _hp_after(s: float) -> int:
	var p := G.player
	p.hp = p.max_hp
	p.invuln = 0.0
	G.god = false
	var n := int(s / TB.DT)
	for i in n:
		Chaos.tick(TB.DT)
		p.invuln = maxf(0.0, p.invuln - TB.DT)
	return p.hp
