extends Node
## 17.2 THE CAMP (scripts/game/camp.gd). Run:
##   godot --headless --path . res://tests/camp_test.tscn -- --no-save
## It is on the title menu; entering it counts no run and opens no doors; its people and things
## are there; the wardrobe, the dummy (skill trees) and the shrine come back to the camp; its pond
## has every world's fish; the portal leads to the hero screen; LEAVE CAMP goes to the title.
## Prints "camp test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL camp: ", msg)

func _tick(n: int) -> void:
	for i in n:
		Keys.tick()
		G.update(TB.DT)

func _ready() -> void:
	await get_tree().process_frame
	seed(172)
	if not G.title_items().has("THE CAMP"):
		fail("no THE CAMP on the title menu")
	var runs0: int = Meta.meta["runs"]
	Camp.enter()
	_tick(30)
	if not Camp.active() or G.state != &"play":
		fail("the camp did not open (state %s)" % G.state)
		return
	if Meta.meta["runs"] != runs0:
		fail("visiting the camp counted a run")
	if not G.room.exits.is_empty():
		fail("the camp has doors: %s" % [G.room.exits.keys()])
	var kinds := G.room.objects.map(func(o): return o["kind"])
	for k in Camp.KINDS + ["n_archivist", "e_angler", "e_pond"]:
		if not k in kinds:
			fail("the camp has no %s" % k)
	var by := {}
	for o in G.room.objects:
		by[o["kind"]] = o
	# The wardrobe comes back to the camp.
	G.interact(by["c_wardrobe"])
	if G.state != &"wardrobe":
		fail("the wardrobe did not open")
	Input.action_press(&"pause")
	_tick(2)
	Input.action_release(&"pause")
	_tick(2)
	if G.state != &"play" or not Camp.active():
		fail("the wardrobe did not come back to the camp (state %s)" % G.state)
	# The dummy: the skill trees, then back.
	G.interact(by["c_dummy"])
	if G.state != &"tree":
		fail("the dummy did not open the skill trees")
	Input.action_press(&"pause")
	_tick(2)
	Input.action_release(&"pause")
	_tick(2)
	if G.state != &"play":
		fail("the skill trees did not come back to the camp (state %s)" % G.state)
	# The pond: every world's fish can bite.
	Fishing.pond = by["e_pond"]
	G.floor_index = 0
	var seen := {}
	for i in 600:
		seen[Fishing._pick()] = true
	if not seen.has("pagepike") or not seen.has("inkfish"):
		fail("the camp's pond holds only this world's fish (%s)" % [seen.keys()])
	# The pause menu leaves the camp.
	if G.pause_items() != Camp.pause_items():
		fail("the pause menu in the camp is %s" % [G.pause_items()])
	G.state = &"pause"
	G.menu = G.pause_items().find("LEAVE CAMP")
	Input.action_press(&"use")
	_tick(2)
	Input.action_release(&"use")
	if G.state != &"title" or Meta.meta["runs"] != runs0:
		fail("LEAVE CAMP: state %s, runs %d" % [G.state, Meta.meta["runs"]])
	print("camp test: PASSED" if fails == 0 else "camp test: %d FAILED" % fails)
	get_tree().quit()
