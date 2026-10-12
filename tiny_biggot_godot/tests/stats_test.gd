extends Node
## 8.3 Stat stacking (scripts/game/stat_drops.gd, Attributes._side). Run:
##   godot --headless --path . res://tests/stats_test.tscn -- --no-save
##   1. Every stat pickup, walked over, gives what its label says.
##   2. STR: +1 max heart per 5; DEX: +1% crit each; INT: +2% burn / poison / lightning each;
##      exact when points are taken away again (an "attr" effect undone).
##   3. Guardians leave two; the labels fit the pixel font.
## Prints "stats test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stats: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(83)
	G.hero_index = 0
	G.new_run()
	G.god = true
	var p := G.player
	G.enter_room(World.make_room(G.floor_d, "treasure", "", "s", { "no_secret": true }))
	for k in StatDrops.KINDS:
		var before := [p.a_str, p.a_dex, p.a_int, p.dmg, p.rate, p.crit, p.speed, p.luck, p.a_spi]
		G.pickups.clear()
		var pk := Combat.drop_pickup(k, p.x, p.y)
		pk.vx = 0.0
		pk.vy = 0.0
		pk.x = p.x
		pk.y = p.y
		for i in 40:
			Combat.update_pickups(TB.DT)
		if not G.pickups.is_empty():
			fail("%s was not picked up" % k)
			continue
		var after := [p.a_str, p.a_dex, p.a_int, p.dmg, p.rate, p.crit, p.speed, p.luck, p.a_spi]
		var ok := false
		match k:
			"s_str": ok = after[0] == before[0] + 1
			"s_dex": ok = after[1] == before[1] + 1 and absf(after[5] - before[5] - 0.01) < 1e-6
			"s_int": ok = after[2] == before[2] + 1
			"s_dmg": ok = absf(after[3] / before[3] - 1.02) < 1e-4
			"s_rate": ok = absf(after[4] / before[4] - 1.02) < 1e-4
			"s_crit": ok = absf(after[5] - before[5] - 0.01) < 1e-6
			"s_speed": ok = absf(after[6] / before[6] - 1.01) < 1e-4
			"s_luck": ok = after[7] == before[7] + 1
			"s_spi": ok = after[8] == before[8] + 1   # 52 SPIRIT
		if not ok:
			fail("%s: before %s after %s" % [k, before, after])
	# 2. The side stats, up and back down.
	var hp0 := p.max_hp
	var crit0 := p.crit
	var burn0 := p.burn_dmg
	var need := 5 - p.a_str % 5
	Effects.apply(p, [["attr", "str", need], ["attr", "dex", 3], ["attr", "int", 4]], 1, "test:attr")
	if p.max_hp != hp0 + 2 or absf(p.crit - crit0 - 0.03) > 1e-6 or absf(p.burn_dmg - burn0 - 0.08) > 1e-6:
		fail("side stats: max hp %d (want %d), crit +%.3f, burn +%.3f" % [p.max_hp, hp0 + 2, p.crit - crit0, p.burn_dmg - burn0])
	Effects.apply(p, [["attr", "str", need], ["attr", "dex", 3], ["attr", "int", 4]], -1, "test:attr")
	if p.max_hp != hp0 or absf(p.crit - crit0) > 1e-6 or absf(p.burn_dmg - burn0) > 1e-6:
		fail("side stats not undone: max hp %d (want %d), crit %.3f (want %.3f)" % [p.max_hp, hp0, p.crit, crit0])
	# 3. A guardian's two, and the labels.
	G.pickups.clear()
	G.on_boss_dead(Combat.spawn_boss("colossus"))
	var n := G.pickups.filter(func(k): return StatDrops.is_kind(k.kind)).size()
	if n != 2:
		fail("a guardian left %d stat pickups" % n)
	for k in StatDrops.KINDS:
		for ch in StatDrops.KINDS[k][0]:
			if Gfx.glyph_index(ch.unicode_at(0)) < 0:
				fail("the pixel font has no %s" % ch)
	print("stats test: PASSED" if fails == 0 else "stats test: %d FAILED" % fails)
	get_tree().quit()
