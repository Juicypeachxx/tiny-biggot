extends Node
## Stage 12 story (scripts/game/story.gd). Run:
##   godot --headless --path . res://tests/story_test.tscn -- --no-save
## The Archivist tells the open lines in order and nothing past what was reached; a milestone opens
## more; a rest stop seats him when he has something new; the Pale Regent's fall is a milestone;
## every line fits the pixel font.
## Prints "story test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL story: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(121)
	Meta.meta["story"] = {}
	Meta.meta["story_heard"] = 0
	G.hero_index = 0
	G.new_run()
	var first := Story.open_lines().size()
	if first != 2:
		fail("a new save opens %d lines, want 2" % first)
	if Story.next_line() != Story.LINES[0][1] or Story.next_line() != Story.LINES[1][1]:
		fail("the Archivist does not start at the beginning")
	if Story.has_new():
		fail("nothing new to tell, yet has_new")
	G.floor_index = 5
	G.start_floor()
	G.enter_room(World.make_room(G.floor_d, "boss", "", "s", { "no_secret": true }))
	G.on_boss_dead(Combat.spawn_boss("regent"))
	if not Story.reached("f6") or not Story.has_new():
		fail("the Pale Regent's fall opened nothing")
	G.enter_room(World.make_room(G.floor_d, "rest", "", "s", { "no_secret": true }))
	if not G.room.objects.any(func(o): return o["kind"] == "n_archivist"):
		fail("no Archivist at the rest stop with something new to tell")
	if Story.next_line() != Story.LINES[2][1]:
		fail("the next line is not the Regent's")
	for l in Story.LINES:
		for ch in l[1]:
			if not ch in Gfx.FONT_CHARS:
				fail("'%s' is not in the font: %s" % [ch, l[1]])
		if TB.text_w(l[1]) > TB.SW - 16:
			fail("too wide for the banner: %s" % l[1])
	_chapter_people()
	Meta.meta["story"] = {}
	Meta.meta["story_heard"] = 0
	print("story test: PASSED" if fails == 0 else "story test: %d FAILED" % fails)
	get_tree().quit()

## 12.2: in Chapter II a rest stop has the Bookbinder, who sells a relic; the Inkling opens a wall.
func _chapter_people() -> void:
	G.run_stats["chapter"] = 2
	G.floor_index = GameData.FLOORS.size() + GameData.NEW_FLOORS.size()
	G.start_floor()
	G.enter_room(World.make_room(G.floor_d, "rest", "", "s", { "no_secret": true }))
	var bb = null
	for o in G.room.objects:
		if o["kind"] == "n_bookbinder":
			bb = o
	if bb == null or bb.get("relic") == null:
		fail("no Bookbinder with a relic at a Chapter II rest stop")
	else:
		var n := G.player.relics.size()
		var name: String = bb["relic"]["name"]
		G.player.gold = 0
		G.interact(bb)
		if G.player.relics.size() != n:
			fail("the Bookbinder gave a relic for no gold")
		G.player.gold = bb["price"] + 5
		G.interact(bb)
		if G.player.relics.size() != n + 1 or G.player.gold != 5 or bb.get("relic") != null:
			fail("buying from the Bookbinder failed (%d relics, %d gold)" % [G.player.relics.size(), G.player.gold])
		for ch in name + EventRooms.prompt(bb)[1]:
			if not ch in Gfx.FONT_CHARS:
				fail("'%s' not in the font" % ch)
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.enemies.clear()
	var ink := { "kind": "n_inkling", "x": 100.0, "y": 100.0 }
	G.room.objects.append(ink)
	var doors := G.room.doors.size()
	G.interact(ink)
	if G.room.doors.size() != doors + 1 or not ink.get("gone", false):
		fail("the Inkling opened no wall")
	G.run_stats["chapter"] = 1
