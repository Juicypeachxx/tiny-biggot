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
	if G.player.oath_picks > 0:   # 29: tests start past the run's OATH pick
		G.player.oath_picks = 0
		G.player.pending = maxi(0, G.player.pending - 1)
	G.enemies.clear()
	G.locked = false
	var pond: Dictionary = Fishing.place(G.room, G.player.x + 30, G.player.y - 40)
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
		if not Fishing.leap.is_empty():
			caught += 1
	if caught == 0:
		fail("the auto line caught nothing in two casts (%s)" % Fishing.result)
	if Fishing.caught_kinds() == 0 or G.run_stats.get("fish", 0) != caught or pond.get("caught", 0) != caught:
		fail("the catch was not kept (%d kinds, %d this run)" % [Fishing.caught_kinds(), G.run_stats.get("fish", 0)])
	if not pond.get("used", false):
		fail("a pond with no casts left is still open")
	# You cannot walk on water.
	G.player.x = pond["cx"]
	G.player.y = pond["cy"]
	Fishing.keep_out(G.player)
	if absf(G.player.x - pond["cx"]) < pond["rx"] * 0.9 and absf(G.player.y - pond["cy"]) < pond["ry"] * 0.9:
		fail("the hero stands in the middle of the pond")
	# THE FISHING HOLE: a lake with a dock and the Angler, who sells bait.
	G.enter_room(World.make_room(G.floor_d, "mystery", "", "s", { "event": "fishing" }))
	var lake = null
	var angler = null
	for o in G.room.objects:
		if o["kind"] == "e_pond":
			lake = o
		elif o["kind"] == "e_angler":
			angler = o
	if lake == null or angler == null or not lake["dock"]:
		fail("the fishing hole has no lake, dock or angler")
	else:
		G.player.gold = 100
		var c0: int = lake["casts"]
		G.interact(angler)
		if not lake.get("bait", false) or lake["casts"] != c0 + 2:
			fail("the bait did nothing")
		G.player.x = lake["x"]
		G.player.y = lake["y"]
		Fishing.keep_out(G.player)
		if absf(G.player.y - lake["y"]) > 0.5:
			fail("the dock does not hold the hero")
		lake["caught"] = 3
		var r0 := G.player.relics.size()
		G.interact(angler)
		if G.player.relics.size() != r0 + 1:
			fail("three fish brought no gift")
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
