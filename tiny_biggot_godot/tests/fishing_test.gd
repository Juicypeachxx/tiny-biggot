extends Node
## 15.1 fishing (scripts/game/fishing.gd). Run:
##   godot --headless --path . res://tests/fishing_test.tscn -- --no-save
## A pond takes three casts; striking too soon scares the fish; a line that follows the fish lands
## it, which pays at once and is kept between runs; every fish can be caught; letting go returns
## to play; every line fits the pixel font.
## Prints "fishing test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL fishing: ", msg)

func _tick(n: int) -> void:
	for i in n:
		Keys.tick()
		G.update(TB.DT)

func _ready() -> void:
	await get_tree().process_frame
	seed(151)
	Meta.meta["fish"] = {}
	G.hero_index = 0
	G.new_run()
	G.enemies.clear()
	G.locked = false
	Fishing.place(G.room, G.player.x + 30, G.player.y + 20)
	var pond: Dictionary = G.room.objects[G.room.objects.size() - 1]
	# Too soon: the fish flees.
	Fishing.auto = false
	Fishing.start(pond)
	Input.action_press(&"use")
	_tick(2)
	Input.action_release(&"use")
	if Fishing.phase != "done" or not Fishing.result.begins_with("TOO SOON"):
		fail("striking at once did not scare the fish (%s)" % Fishing.result)
	_tick(120)
	if G.state != &"play" or pond["casts"] != 2:
		fail("after a cast: state %s, %d casts left" % [G.state, pond["casts"]])
	# A line that follows the fish lands it.
	Fishing.auto = true
	var caught := 0
	for k in 2:
		var g0: int = G.player.gold
		Fishing.start(pond)
		for i in 60 * 40:
			_tick(1)
			if G.state == &"play":
				break
		if G.state != &"play":
			fail("cast %d never ended" % k)
			return
		if Fishing.result.contains(":"):
			caught += 1
	if caught == 0:
		fail("the auto line caught nothing in two casts (%s)" % Fishing.result)
	if Fishing.caught_kinds() == 0 or G.run_stats.get("fish", 0) != caught:
		fail("the catch was not kept (%d kinds, %d this run)" % [Fishing.caught_kinds(), G.run_stats.get("fish", 0)])
	if not pond.get("used", false):
		fail("a pond with no casts left is still open")
	# Every fish's reward runs without trouble, and every line fits the font.
	for id in Fishing.FISH:
		Fishing.pond = pond
		Fishing._reward(id)
		var d: Array = Fishing.FISH[id]
		for ch in d[0] + d[4] + "NEW! : A LEGEND FROM THE DEEP":
			if not ch in Gfx.FONT_CHARS:
				fail("'%s' not in the font: %s" % [ch, d[0]])
	Fishing.auto = false
	Meta.meta["fish"] = {}
	print("fishing test: PASSED" if fails == 0 else "fishing test: %d FAILED" % fails)
	get_tree().quit()
