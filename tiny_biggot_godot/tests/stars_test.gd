extends Node
## The constellation (scripts/game/stars.gd). Run: godot --headless --path . res://tests/stars_test.tscn -- --no-save
##   1. The web: one piece, links both ways, stars far enough apart to tap, every card fits.
##   2. Taking: only next to a taken star, only with points left, never more than MAX_POINTS (60 since 48.2; was 30).
##   3. Giving back: only a star nothing taken hangs off; reset gives back everything.
##   4. A run starts with the taken stars' effects (expanded game only), and with none in --classic.
## Prints "stars test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stars: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	_web()
	_rules()
	_runs()
	print("stars test: PASSED" if fails == 0 else "stars test: %d FAILED" % fails)
	get_tree().quit()

func _id(id: String) -> int:
	for i in Stars.nodes().size():
		if Stars.nodes()[i]["id"] == id:
			return i
	fail("no star " + id)
	return 0

func _web() -> void:
	var nodes := Stars.nodes()
	if nodes.size() < 80:
		fail("only %d stars" % nodes.size())
	var notables := 0
	for i in nodes.size():
		var n: Dictionary = nodes[i]
		if n["notable"]:
			notables += 1
		for j in n["links"]:
			if not i in nodes[j]["links"]:
				fail("link %s-%s one way" % [n["id"], nodes[j]["id"]])
		for j in range(i + 1, nodes.size()):
			if n["pos"].distance_to(nodes[j]["pos"]) < Stars.STEP * 0.5:
				fail("stars %s and %s overlap" % [n["id"], nodes[j]["id"]])
		var lines: Array = TraitView.rich_lines(n["text"], 150)
		if lines.size() > 4:
			fail("star %s card has %d lines" % [n["id"], lines.size()])
		if TB.text_w(n["name"]) > 156:
			fail("star %s name too wide" % n["id"])
	if notables != 37:   # the heart, seven on each side (48.2: was five), and two on each alignment spoke (8.1)
		fail("%d notable stars" % notables)
	var seen := { 0: true }
	var q := [0]
	while not q.is_empty():
		for j in nodes[q.pop_back()]["links"]:
			if not seen.has(j):
				seen[j] = true
				q.append(j)
	if seen.size() != nodes.size():
		fail("web in pieces: %d of %d reached" % [seen.size(), nodes.size()])

func _rules() -> void:
	Meta.meta["bosses"] = 0
	Meta.meta["wins"] = 0
	Stars.reset()
	if Stars.take(_id("n1")):
		fail("took a star with no points")
	Meta.meta["bosses"] = 3
	if Stars.points() != 3:
		fail("3 guardians gave %d points" % Stars.points())
	Meta.meta["wins"] = 1
	if Stars.points() != 5:
		fail("3 guardians and a win gave %d points" % Stars.points())
	Meta.meta["bosses"] = 99
	Meta.meta["wins"] = 99
	if Stars.points() != Stars.MAX_POINTS:
		fail("points not capped: %d" % Stars.points())
	if Stars.take(_id("n2")):
		fail("took a star not next to a taken one")
	if not Stars.take(_id("n1")) or not Stars.take(_id("n2")):
		fail("could not take n1 then n2")
	if Stars.take(_id("n1")):
		fail("took n1 twice")
	if Stars.give_back(_id("n1")):
		fail("gave back n1 with n2 hanging off it")
	if Stars.give_back(0):
		fail("gave back the heart")
	if not Stars.give_back(_id("n2")) or not Stars.give_back(_id("n1")):
		fail("could not give back n2 then n1")
	if Stars.spent() != 0:
		fail("%d spent after giving all back" % Stars.spent())
	# Take as many as the points allow, breadth first from the heart.
	var nodes := Stars.nodes()
	var q := [0]
	var got := 0
	while not q.is_empty():
		var c: int = q.pop_front()
		for j in nodes[c]["links"]:
			if Stars.take(j):
				got += 1
				q.append(j)
	if got != Stars.MAX_POINTS or Stars.spent() != Stars.MAX_POINTS:
		fail("took %d stars with %d points" % [got, Stars.MAX_POINTS])
	for i in nodes.size():
		if Stars.can_take(i):
			fail("star %s takeable with no points left" % nodes[i]["id"])
			break
	# A star in the middle of a taken chain cannot go; one at its end can.
	for i in nodes.size():
		if i == 0 or not Stars.is_taken(i):
			continue
		var outer := 0
		for j in nodes[i]["links"]:
			if Stars.is_taken(j) and nodes[j]["pos"].length() > nodes[i]["pos"].length():
				outer += 1
		if Stars.can_give_back(i) != (outer == 0):
			fail("star %s: can give back %s with %d taken beyond it" % [nodes[i]["id"], Stars.can_give_back(i), outer])
	Stars.reset()
	if Stars.spent() != 0:
		fail("reset left %d" % Stars.spent())

func _start(classic: bool) -> Player:
	GameData.force_classic = classic
	G.hero_index = 0
	G.new_run()
	GameData.force_classic = false
	return G.player

func _runs() -> void:
	Stars.reset()
	var base := _start(false)
	var b := { "dmg": base.dmg, "max_hp": base.max_hp, "gold": base.gold }
	var classic_hp := _start(true).max_hp
	for id in ["n1", "n2", "n2b1", "n2b2", "n2b3", "e1", "e2", "e3", "e4", "e4a1", "e4a2", "e4a3", "w1", "w2", "w2b1", "w2b2", "w2b3"]:
		_id(id)
		Stars.taken()[id] = true
	var p := _start(false)
	if not p.dmg > b["dmg"]:
		fail("offense stars gave no damage (%s -> %s)" % [b["dmg"], p.dmg])
	if p.max_hp <= b["max_hp"]:
		fail("defense stars: max health %d -> %d" % [b["max_hp"], p.max_hp])
	if p.hp != p.max_hp:
		fail("not starting at full health: %d/%d" % [p.hp, p.max_hp])
	if p.gold <= b["gold"]:
		fail("fortune stars: gold %d -> %d" % [b["gold"], p.gold])
	if _start(true).max_hp != classic_hp:
		fail("--classic took the stars")
	Stars.reset()
