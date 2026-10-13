extends Node
## 22.2 THE ENDLESS DESCENT (scripts/game/endless.gd). Run:
##   godot --headless --path . res://tests/endless_test.tscn -- --no-save
## The camp's stair starts an endless run (every floor, the depth counted); a fallen guardian leaves
## its hoard and the stair down and no ending (not at the Throne, not at the last floor); past the
## last floor the stair goes round a loop deeper; the depth is the score, and a new best pays and
## is kept; chapter quests are not won on the stair; nothing under --classic.
## Prints "endless test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL endless: ", msg)

func _boss_room() -> Enemy:
	var r := World.make_room(G.floor_d, "boss", "", "s", { "no_secret": true })
	G.enter_room(r)
	G.enemies.clear()
	var b := Combat.spawn_boss(GameData.floors()[G.floor_index]["boss"])
	b.spawn_t = 0.0
	G.boss = b
	return b

func _has(kind: String) -> bool:
	return G.room.objects.any(func(o): return o["kind"] == kind and not o.get("gone", false))

func _ready() -> void:
	await get_tree().process_frame
	Meta.meta["endless_best"] = 3
	# The stair in the camp.
	Camp.enter()
	var stair: Dictionary = {}
	for o in G.room.objects:
		if o["kind"] == "c_endless":
			stair = o
	if stair.is_empty():
		fail("no stair in the camp")
	else:
		Camp.interact(stair)
		if not G.endless_next or G.state != &"hero":
			fail("the stair did not lead to the heroes for an endless run")
	G.hero_index = 2
	G.new_run()
	G.god = true
	if not Endless.on() or GameData.floors().size() != 20 or G.endless_next:
		fail("the run is not endless over every floor (%s, %d floors)" % [Endless.on(), GameData.floors().size()])
	if Endless.depth() != 1:
		fail("the first floor is depth %d" % Endless.depth())
	# No ending at the Throne, nor at the last floor: the hoard and the stair down.
	var wins: int = Meta.meta.get("wins", 0)
	for fi in [GameData.THRONE_FLOOR, GameData.floors().size() - 1]:
		G.floor_index = fi
		G.state = &"play"
		var b := _boss_room()
		G.on_boss_dead(b)
		if not _has("portal") or not _has("chest"):
			fail("no hoard or stair down after the guardian of floor %d" % (fi + 1))
		if _has("loopportal") or _has("exitportal") or _has("soulgate") or G.state != &"play" or G.run_stats.get("critic", false):
			fail("an ending after the guardian of floor %d" % (fi + 1))
	if Meta.meta.get("wins", 0) != wins:
		fail("the Throne's guardian counted as a win on the stair")
	# Past the last floor, round again a loop deeper.
	G.floor_index = GameData.floors().size() - 1
	G.loop = 0
	Endless.next_floor()
	if G.floor_index != 0 or G.loop != 1 or Endless.depth() != 21:
		fail("past the last floor: floor %d, loop %d, depth %d" % [G.floor_index + 1, G.loop, Endless.depth()])
	Endless.on_floor()
	if Endless.best() != 21 or not G.run_stats.get("new_best", false):
		fail("depth 21 did not become the best (best %d)" % Endless.best())
	# The depth is the score.
	G.award_embers(false)
	var names: Array = G.award["parts"].map(func(x): return x[0])
	if not names.has("DEPTH") or names.has("FLOORS") or names.has("LOOPS") or not names.has("NEW BEST DEPTH"):
		fail("the score's parts: %s" % str(names))
	# Chapter quests are not won on the stair.
	if Quests.met({ "id": "chapter4" }, false, true):
		fail("a chapter quest was won on the endless stair")
	# --classic: no stair run.
	GameData.force_classic = true
	G.endless_next = true
	G.new_run()
	if Endless.on():
		fail("an endless run under --classic")
	GameData.force_classic = false
	print("endless test: PASSED" if fails == 0 else "endless test: %d FAILED" % fails)
	get_tree().quit()
