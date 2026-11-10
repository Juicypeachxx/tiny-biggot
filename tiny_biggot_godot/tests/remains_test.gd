extends Node
## 21.2 ROOMS THAT KEEP THEIR STORY (scripts/render/remains.gd, room_dress.gd). Run:
##   godot --headless --path . res://tests/remains_test.tscn -- --no-save
## A fallen foe leaves remains of its own family; big blasts leave scorch marks; both stay with
## the room, fade and go, and are capped; candelabra and bookcases are placed from the room's own
## seed after everything with rules, and fall to a roll, a shot or a blast (and stay down); crows
## take off when startled; none of it moves the run's random numbers; nothing under --classic.
## Prints "remains test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL remains: ", msg)

func _arena(floor_i: int = 0) -> Player:
	G.hero_index = 2
	G.new_run()
	G.god = true
	G.floor_index = floor_i
	G.floor_d = World.new_floor(floor_i)
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.enemies.clear()
	G.room.waves_left = 0
	G.locked = true
	G.state = &"play"
	G.player.x = 224.0
	G.player.y = 152.0
	return G.player

func _ready() -> void:
	await get_tree().process_frame
	var p := _arena()
	# Families.
	for row in [["skeleton", "bones"], ["slime", "goo"], ["inkmage", "ink"], ["mothling", "feathers"], ["ghost", "ecto"],
			["golem", "scrap"], ["imp", "ash"], ["cardsprite", "paper"]]:
		if Remains.family(row[0]) != row[1]:
			fail("%s leaves %s, not %s" % [row[0], Remains.family(row[0]), row[1]])
	# A kill leaves remains; they fade and go; they are capped.
	var e := Combat.spawn_enemy("skeleton", 200.0, 150.0, false, true)
	Combat.kill_enemy(e)
	G.room.remains.clear()
	seed(55)
	var a := randi()
	seed(55)
	Remains.add(e)   # (the kill itself rolls loot from the run's dice; what it leaves must not)
	var b := randi()
	if G.room.remains.size() != 1 or G.room.remains[0]["kind"] != "bones":
		fail("a fallen skeleton left %s" % [G.room.remains])
	var t0 := G.time
	G.time = t0 + Remains.LIFE - 3.0
	Remains._t = 0.0
	Remains.tick(TB.DT)
	if G.room.remains.is_empty() or G.room.remains[0]["step"] == 0:
		fail("old remains did not fade")
	G.time = t0 + Remains.LIFE + 1.0
	Remains._t = 0.0
	Remains.tick(TB.DT)
	if not G.room.remains.is_empty():
		fail("remains did not go")
	G.time = t0
	for i in 60:
		var f := Combat.spawn_enemy("slime", 100.0 + i, 150.0, false, true)
		Remains.add(f)
	if G.room.remains.size() > Remains.MAX:
		fail("%d remains, more than %d" % [G.room.remains.size(), Remains.MAX])
	# Scorch: big blasts only.
	G.room.scorch.clear()
	Combat.explode_at(300.0, 200.0, 1.0, null, 10.0)
	if not G.room.scorch.is_empty():
		fail("a small blast left a mark")
	Combat.explode_at(300.0, 200.0, 1.0, null, 40.0)
	if G.room.scorch.size() != 1:
		fail("a big blast left no mark")
	# Remains and marks stay with their room.
	var room1 := G.room
	G.enter_room(World.make_room(G.floor_d, "combat", "", "n", { "no_secret": true }))
	G.enter_room(room1)
	if room1.remains.is_empty() or room1.scorch.is_empty():
		fail("the room forgot its remains when you came back")
	# Props: placed from the room's own seed, after the pots; knocked by a roll, a shot, a blast.
	var with_props := 0
	var props: Array = []
	for s in 30:
		var r := World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true })
		r.seed_value = 1000 + s
		var pots0 := []
		RoomDress.place_pots(r, 3)
		pots0 = r.objects.map(func(o): return Vector2(o["x"], o["y"]))
		RoomDress.place_props(r)
		var pots1 := r.objects.filter(func(o): return o["kind"] == "e_pot").map(func(o): return Vector2(o["x"], o["y"]))
		if pots0 != pots1:
			fail("props moved the pots")
		var ps := r.objects.filter(func(o): return o["kind"] == "e_candle")
		if not ps.is_empty():
			with_props += 1
			props.append_array(ps)
	if with_props == 0:
		fail("no candelabra in 30 fight rooms")
	G.room.objects.clear()
	var c1 := { "kind": "e_candle", "x": 224.0, "y": 160.0, "used": true, "seed": 1 }
	var c2 := { "kind": "e_candle", "x": 100.0, "y": 100.0, "used": true, "seed": 2 }
	var c3 := { "kind": "e_shelf", "x": 340.0, "y": 100.0, "used": true, "seed": 3 }
	G.room.objects.append_array([c1, c2, c3])
	p.x = 220.0
	p.y = 158.0
	p.dodge_t = 0.2
	seed(66)
	var c := randi()
	seed(66)
	RoomDress.tick_objects(G.room)
	var d := randi()
	p.dodge_t = 0.0
	if not c1.get("down", false):
		fail("rolling into a candelabrum did not knock it over")
	if c2.get("down", false) or c3.get("down", false):
		fail("props far away fell")
	Combat.explode_at(340.0, 104.0, 1.0, null, 30.0)
	if not c3.get("down", false):
		fail("a blast did not knock the bookcase over")
	if a != b:
		fail("remains moved the run's random numbers")
	if c != d:
		fail("knocking a prop moved the run's random numbers")
	# Crows on the open-air floors take off when startled.
	_arena(6)
	RoomDress._spawn_critters(G.room)
	var birds := RoomDress._critters.filter(func(x): return x["kind"] == "bird")
	if birds.is_empty():
		fail("no crows in the hamlet")
	else:
		var bird: Dictionary = birds[0]
		RoomDress.scare(bird["x"], bird["y"], 20.0)
		if not bird.get("fly", false):
			fail("a crow did not take off at a blast")
		for i in 240:
			RoomDress.tick(TB.DT)
		if RoomDress._critters.has(bird):
			fail("a crow that took off never left")
	# Nothing under --classic.
	GameData.force_classic = true
	var n0 := G.room.remains.size()
	Remains.add(Combat.spawn_enemy("skeleton", 50.0, 50.0, false, true))
	Remains.scorch(10.0, 10.0, 50.0)
	if G.room.remains.size() != n0 or not G.room.scorch.is_empty() and G.room.scorch.size() > 0 and G.room.scorch[-1]["x"] == 10.0:
		fail("remains or marks under --classic")
	GameData.force_classic = false
	print("remains test: PASSED" if fails == 0 else "remains test: %d FAILED" % fails)
	get_tree().quit()
