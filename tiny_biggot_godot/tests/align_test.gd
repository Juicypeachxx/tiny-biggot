extends Node
## 8.1 Alignments (scripts/game/alignments.gd, the diagonal spokes of stars.gd). Run:
##   godot --headless --path . res://tests/align_test.tscn -- --no-save
##   1. Leads and devout follow their rules.
##   2. A rest stop has four shrines; one taken gives +1 and quiets the rest.
##   3. Each diagonal spoke: 3 points and 2 notable stars, joined to the heart.
##   4. A "while_align" star holds its bonus only while its alignment leads.
## Prints "align test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL align: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(81)
	G.hero_index = 0
	G.new_run()
	var p := G.player
	for k in Alignments.KEYS:
		if Alignments.value(p, k) != 0:
			fail("a new run starts with %s %d" % [k, Alignments.value(p, k)])
	p.al_good = 2
	if not Alignments.leads(p, "good") or not Alignments.devout(p):
		fail("GOOD 2 alone does not lead or is not devout")
	p.al_evil = 2
	if not Alignments.leads(p, "good") or not Alignments.leads(p, "evil") or Alignments.devout(p):
		fail("a tie at 2 should lead both and not be devout")
	p.al_evil = 3
	if Alignments.leads(p, "good"):
		fail("GOOD leads under EVIL 3")
	p.al_good = 0
	p.al_evil = 0
	# 2. The rest stop.
	G.enter_room(World.make_room(G.floor_d, "rest", "", "s", { "no_secret": true }))
	var sh := G.room.objects.filter(func(o): return o["kind"] == "alshrine")
	if sh.size() != 4:
		fail("a rest stop has %d shrines" % sh.size())
	else:
		G.interact(sh[2])
		if p.al_law != 1 or not sh.all(func(o): return o.get("used", false)):
			fail("taking the LAWFUL shrine gave %d and left others: %s" % [p.al_law, sh.map(func(o): return o.get("used", false))])
	# 3. The spokes.
	var nodes := Stars.nodes()
	for side in ["ne", "se", "sw", "nw"]:
		var mine := nodes.filter(func(n): return n["side"] == side)
		var pts := mine.filter(func(n): return str(n["effects"]).contains("al_")).size()
		var nb := mine.filter(func(n): return n["notable"]).size()
		if mine.size() != 7 or pts != 3 or nb != 2:
			fail("spoke %s: %d stars, %d points, %d notables" % [side, mine.size(), pts, nb])
		elif not nodes[0]["links"].has(Stars._by_id[side + "1"]):
			fail("spoke %s is not joined to the heart" % side)
	# 4. BLOODTHIRST (while EVIL leads: +20% damage).
	var bt: Dictionary = nodes[Stars._by_id["nw4"]]
	if bt["name"] != "BLOODTHIRST":
		fail("nw4 is %s" % bt["name"])
	var d0 := p.dmg
	Effects.apply(p, bt["effects"], 1, "test:bt")
	_tick(3)
	if absf(p.dmg - d0) > 1e-6:
		fail("BLOODTHIRST holds without EVIL")
	p.al_evil = 2
	_tick(3)
	if absf(p.dmg - d0 * 1.2) > 1e-4:
		fail("BLOODTHIRST does not hold with EVIL leading (%.3f vs %.3f)" % [p.dmg, d0 * 1.2])
	p.al_evil = 0
	_tick(3)
	if absf(p.dmg - d0) > 1e-4:
		fail("BLOODTHIRST stays after EVIL fell (%.3f vs %.3f)" % [p.dmg, d0])
	for n in nodes:
		for ch in str(n["text"]) + str(n["name"]):
			if Gfx.glyph_index(ch.unicode_at(0)) < 0:
				fail("the pixel font has no %s (in %s)" % [ch, n["name"]])
	print("align test: PASSED" if fails == 0 else "align test: %d FAILED" % fails)
	get_tree().quit()

func _tick(n: int) -> void:
	for i in n:
		Effects.tick(TB.DT)
