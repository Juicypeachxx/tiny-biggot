extends Node
## 63 THE EMBER FIRE (scripts/world/bonfire.gd). Run:
##   godot --headless --path . res://tests/bonfire_test.tscn -- --no-save
## 1 Fight rooms cleared early on a floor raise none; the first cleared halfway down raises one (with
##   its kindling, on open floor); a floor has one only; classic rooms none.
## 2 Light it (counted), kindle it twice for gold (no more), sit: it mends all the hearts, fills the
##   potions and rolls, leaves its warmth, and cannot be sat at again.
## 3 The ember shards at the run's end count it. 4 Drawn cold, lit and kindled.
## Prints "bonfire test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL bonfire: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	G.hero_index = 0
	G.new_run()
	_rising()
	_using()
	await _drawing()
	print("bonfire test: PASSED" if fails == 0 else "bonfire test: %d FAILED" % fails)
	get_tree().quit()

func _room(depth: int) -> Room:
	var room := World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true })
	room.depth = depth
	room.objects = []
	room.traps = []
	G.room = room
	return room

func _fires(room: Room) -> Array:
	return room.objects.filter(func(o): return o["kind"] == "bonfire")

func _rising() -> void:
	for f in 11:
		G.floor_index = f
		G.start_floor()
		var early := _room(0)
		Bonfire.on_clear(early)
		if not _fires(early).is_empty():
			fail("floor %d: a fire in the first room" % f)
		var mid := _room(G.floor_d["total"] - 2)
		Bonfire.on_clear(mid)
		var fs := _fires(mid)
		if fs.size() != 1:
			fail("floor %d: %d fires halfway down" % [f, fs.size()])
			continue
		var o: Dictionary = fs[0]
		if mid.tile(floori(o["x"] / TB.TS), floori(o["y"] / TB.TS)) != World.T_FLOOR:
			fail("floor %d: the fire is not on open floor" % f)
		if mid.objects.filter(func(k): return k["kind"] == "kindling").size() != 1:
			fail("floor %d: no kindling by the fire" % f)
		var again := _room(G.floor_d["total"] - 2)
		Bonfire.on_clear(again)
		if not _fires(again).is_empty():
			fail("floor %d: a second fire" % f)
	GameData.force_classic = true
	G.floor_index = 2
	G.start_floor()
	var cl := _room(G.floor_d["total"] - 2)
	Bonfire.on_clear(cl)
	GameData.force_classic = false
	if not _fires(cl).is_empty():
		fail("a classic room has a fire")

func _using() -> void:
	G.floor_index = 1
	G.start_floor()
	var room := _room(G.floor_d["total"] - 2)
	Bonfire.on_clear(room)
	var fire: Dictionary = _fires(room)[0]
	var kin: Dictionary = room.objects.filter(func(k): return k["kind"] == "kindling")[0]
	var p := G.player
	p.gold = 1000
	G.interact(kin)
	if fire["level"] != 0 or p.gold != 1000:
		fail("kindled before it was lit")
	G.run_stats["fires"] = 0
	G.interact(fire)
	if not fire["lit"] or G.run_stats["fires"] != 1:
		fail("lighting it: lit %s, counted %d" % [fire["lit"], G.run_stats["fires"]])
	if fire.get("used", false):
		fail("lighting it used it up")
	for i in 3:
		if not kin.get("used", false):
			G.interact(kin)
	if fire["level"] != Bonfire.MAX_KINDLE or p.gold >= 1000:
		fail("kindling: level %d, gold %d" % [fire["level"], p.gold])
	p.hp = 1
	p.potions = 0
	p.charges = 0
	var buffs := p.buffs.size()
	G.interact(fire)
	if p.hp != p.max_hp or p.potions < p.max_potions or p.charges != p.dodge_charges or p.buffs.size() <= buffs:
		fail("sitting: hp %d/%d, potions %d/%d, rolls %d, buffs %d" % [p.hp, p.max_hp, p.potions, p.max_potions, p.charges, p.buffs.size()])
	if not fire.get("used", false):
		fail("it can be sat at again")
	var parts := []
	Bonfire.award(parts)
	if parts.is_empty() or parts[0][1] != 2:
		fail("the run's end does not count it: %s" % [parts])

class Canvas extends Node2D:
	var done := false
	func _draw() -> void:
		for o in G.room.objects:
			Bonfire.draw(self, o, 1.0)
		done = true

func _drawing() -> void:
	G.floor_index = 0
	G.start_floor()
	var room := _room(G.floor_d["total"] - 2)
	Bonfire.on_clear(room)
	var cv := Canvas.new()
	add_child(cv)
	for step in 3:
		cv.done = false
		cv.queue_redraw()
		await get_tree().process_frame
		await get_tree().process_frame
		if not cv.done:
			fail("the fire was not drawn (step %d)" % step)
		var fire: Dictionary = _fires(room)[0]
		if step == 0:
			fire["lit"] = true
		else:
			fire["level"] = 2
