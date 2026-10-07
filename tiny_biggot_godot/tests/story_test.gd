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
	Meta.meta["story"] = {}
	Meta.meta["story_heard"] = 0
	print("story test: PASSED" if fails == 0 else "story test: %d FAILED" % fails)
	get_tree().quit()
