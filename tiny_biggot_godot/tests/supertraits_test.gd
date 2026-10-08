extends Node
## 8.4 Fun and synergy traits (traits.gd 8.4 rows). Run:
##   godot --headless --path . res://tests/supertraits_test.tscn -- --no-save
##   1. SUPER traits: never offered before level 4; TITAN'S FRAME gives +12 STR and 4 BULWARK ranks.
##   2. MOMENTUM grows with rolls and stops at +60%.
##   3. BOTTOMLESS PURSE: things that grow with gold see 1000.
##   4. The damage hooks: IDLE HANDS, COLLECTOR, ZEALOT, PRISM.
##   5. Every 8.4 text fits the pixel font.
## Prints "supertraits test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL supertraits: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(84)
	G.hero_index = 0
	G.new_run()
	G.god = true
	var p := G.player
	var titan := Traits.by_id("x_titan")
	p.level = 2
	if G.trait_weight(p, titan) != 0:
		fail("a SUPER trait is offered at level 2")
	var twin := Traits.by_id("x_twin")
	if G.trait_weight(p, twin) != 4:
		fail("a COMMON SUPER trait has weight %d at level 2, want 4 (8.5)" % G.trait_weight(p, twin))
	p.level = 1
	if G.trait_weight(p, twin) != 0:
		fail("a COMMON SUPER trait is offered at level 1")
	p.level = 5
	if G.trait_weight(p, titan) <= 0:
		fail("a SUPER trait is never offered at level 5")
	var s0 := p.a_str
	var b0: int = p.fam.get("bulwark", 0)
	p.pending += 1
	G.take_trait(titan)
	if p.a_str != s0 + 13 or p.fam.get("bulwark", 0) != b0 + 4:   # +12, and +1 as every BULWARK rank trains STR
		fail("TITAN'S FRAME: STR %d (want %d), BULWARK %d (want %d)" % [p.a_str, s0 + 13, p.fam.get("bulwark", 0), b0 + 4])
	# 2. MOMENTUM.
	var d0 := p.dmg
	p.pending += 1
	G.take_trait(Traits.by_id("y_momentum"))
	for i in 100:
		Effects.fire("on_roll", {})
		Effects.tick(TB.DT)
	if absf(p.dmg / d0 - 1.6) > 0.01:
		fail("MOMENTUM after 100 rolls: x%.3f, want x1.6" % (p.dmg / d0))
	# 3. The purse.
	p.gold = 30
	if Combat.held_gold(p) != 30:
		fail("held gold without the purse: %d" % Combat.held_gold(p))
	p.pending += 1
	G.take_trait(Traits.by_id("f_purse"))
	if Combat.held_gold(p) != 1000:
		fail("BOTTOMLESS PURSE: held gold %d" % Combat.held_gold(p))
	# 4. The hooks, on a dummy foe.
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.enemies.clear()
	var e := Combat.spawn_enemy("skeleton", p.x + 80, p.y, false, true)
	var m0 := Combat.hook_mult(p, e)
	for id in ["f_idle", "y_collector", "y_zealot", "y_prism"]:
		p.pending += 1
		G.take_trait(Traits.by_id(id))
	var empty := 0
	for sl in Gear.slots():
		if p.gear.get(sl) == null:
			empty += 1
	p.stat_picks = 3
	p.al_evil = 4
	e.burn_t = 2.0
	e.poison = 2.0
	var want := m0 + 0.2 * empty + 0.06 + 0.2 + 0.15 * 2   # 20.1: PRISM is +15% for each ailment (two here)
	if absf(Combat.hook_mult(p, e) - want) > 1e-4:
		fail("the hooks: x%.3f, want x%.3f" % [Combat.hook_mult(p, e), want])
	# 6. The odds box: the four shares add up to 100%; SUPER shows from level 4 only.
	var od := TraitView.odds(p)
	if absf(od["str"] + od["dex"] + od["int"] + od["any"] - 1.0) > 1e-6 or od["super"] <= 0.0:
		fail("odds at level %d: %s" % [p.level, od])
	p.level = 1
	if TraitView.odds(p)["super"] != 0.0:
		fail("SUPER odds at level 1 are not 0")
	for t in Traits.all():
		if t["id"].substr(0, 2) in ["x_", "f_", "y_"]:
			for ch in t["name"] + t["desc"]:
				if Gfx.glyph_index(ch.unicode_at(0)) < 0:
					fail("the pixel font has no %s (in %s)" % [ch, t["name"]])
	print("supertraits test: PASSED" if fails == 0 else "supertraits test: %d FAILED" % fails)
	get_tree().quit()
