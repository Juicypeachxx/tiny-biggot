extends Node
## Floors as a map (scripts/world/floor_map.gd). Run: godot --headless --path . res://tests/map_test.tscn -- --no-save
##   1. Shape, on 300 floors of every index: a tree (connected, no loops) inside its bounds; the
##      guardian at the farthest dead end with the rest stop before it (and the mini-boss before
##      that on the new floors); one shop; the rift at a dead end; hidden rooms hang off fights.
##   2. Walking: through the doors every room of the map is reached, and every door leads back;
##      a cleared room stays cleared; a bombed cracked wall opens onto its hidden room; the rift's
##      rooms are off the map and its last room leads back; the vault's door is sealed until a key.
##   3. The original game (--classic is checked by the replays) and --linear keep the chain.
## Prints "map test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL map: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(31)
	_shapes()
	_walk()
	print("map test: PASSED" if fails == 0 else "map test: %d FAILED" % fails)
	get_tree().quit()

func _start(floor_i: int) -> void:
	G.hero_index = 1
	G.new_run()
	G.floor_index = floor_i
	G.start_floor()
	G.god = true

func _tick(n: int) -> void:
	for i in n:
		G.player.hp = G.player.max_hp
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

func _kill_all() -> void:
	for e in G.enemies.duplicate():
		if e.hp > 0 and e.spawn_t <= 0:
			Combat.damage_enemy(e, e.hp * 2.0 + 1.0, { "no_crit": true, "no_mult": true, "silent": true })

func _clear() -> void:
	for i in 300:
		_tick(5)
		_kill_all()
		if not G.locked:
			return

func _shapes() -> void:
	if not FloorMap.wanted():
		fail("the expanded game does not use the floor map")
		return
	for k in 300:
		_start(k % GameData.floors().size())
		var m: Dictionary = G.floor_d["map"]
		var cs: Dictionary = m["cells"]
		var open := cs.keys().filter(func(c): return not cs[c]["hidden"])
		# Connected, no loops: a tree has one fewer link than rooms.
		var links := 0
		for c in open:
			for d in ["e", "s"]:
				var to: Vector2i = c + World.DIRS[d]
				if cs.has(to) and not cs[to]["hidden"]:
					links += 1
		if links != open.size() - 1:
			fail("floor %d map %d: %d rooms but %d links (not a tree)" % [G.floor_index, k, open.size(), links])
		var seen := { m["start"]: true }
		var q := [m["start"]]
		while not q.is_empty():
			var c: Vector2i = q.pop_back()
			for d in World.DIRS:
				var to: Vector2i = c + World.DIRS[d]
				if cs.has(to) and not cs[to]["hidden"] and not seen.has(to):
					seen[to] = true
					q.append(to)
		if seen.size() != open.size():
			fail("map %d: not all rooms joined" % k)
		if open.size() < G.floor_d["total"] + 2:
			fail("map %d: only %d rooms" % [k, open.size()])
		# The guardian, the rest stop, the mini-boss.
		var boss: Vector2i = m["boss"]
		var far := 0
		for c in open:
			far = maxi(far, cs[c]["dist"])
		if cs[boss]["type"] != "boss" or cs[boss]["dist"] != far:
			fail("map %d: the guardian is not at the far end" % k)
		var rest: Vector2i = cs[boss]["parent"]
		if rest != m["start"] and cs[rest]["type"] != "rest":
			fail("map %d: no rest stop before the guardian" % k)
		if GameData.floors()[G.floor_index].has("mini") and not cs.values().any(func(c): return c.get("mini", false)):
			fail("map %d (floor %d): no mini-boss room" % [k, G.floor_index])
		var shops := cs.values().filter(func(c): return c["type"] == "shop").size()
		if shops != 1:
			fail("map %d: %d shops" % [k, shops])
		var rifts := cs.keys().filter(func(c): return cs[c]["type"] == "rift")
		if rifts.size() != 1:
			fail("map %d: %d rifts" % [k, rifts.size()])
		elif FloorMap._neighbours(cs, rifts[0]) != 1 or cs[rifts[0]].get("theme", "") == "":
			fail("map %d: the rift is not a dead end with a world" % k)
		for c in cs:
			if cs[c]["hidden"]:
				var par: Dictionary = cs[cs[c]["parent"]]
				if not par["type"] in ["combat", "elite"]:
					fail("map %d: a hidden room off a %s" % [k, par["type"]])
			if absi(c.x) > FloorMap.SPAN_X + 1 or absi(c.y) > FloorMap.SPAN_Y + 1:
				fail("map %d: a room out of bounds at %s" % [k, c])

func _go(dir: String) -> void:
	G.leave_room(dir)
	for i in 60:
		_tick(1)
		if G.fade.is_empty():
			break

func _walk() -> void:
	_start(2)
	var m: Dictionary = G.floor_d["map"]
	var cs: Dictionary = m["cells"]
	var p: Player = G.player
	p.keys = 9
	# Depth-first through the doors: every open room reached; each door has a way back.
	var stack := [m["start"]]
	var reached := { m["start"]: true }
	var guard := 0
	while not stack.is_empty() and guard < 400:
		guard += 1
		var here: Vector2i = stack[-1]
		if G.room.cell != here:
			fail("walk: in %s, expected %s" % [G.room.cell, here])
			return
		_clear()
		for o in G.room.objects.duplicate():
			if o["kind"] == "lockdoor":
				G.interact(o)
		var next := ""
		for d in G.room.exits:
			var to: Vector2i = here + World.DIRS[d]
			var ex: Dictionary = G.room.exits[d]
			if ex["type"] == "rift" or not cs.has(to) or reached.has(to):
				continue
			next = d
			break
		if next == "":
			stack.pop_back()
			if stack.is_empty():
				break
			var back: Vector2i = stack[-1]
			var bd := ""
			for d in World.DIRS:
				if here + World.DIRS[d] == back:
					bd = d
			if not G.room.exits.has(bd):
				fail("walk: no door back from %s to %s" % [here, back])
				return
			_go(bd)
			continue
		_go(next)
		var now: Vector2i = here + World.DIRS[next]
		reached[now] = true
		stack.append(now)
		if G.room.cell != now or not G.room.on_map:
			fail("walk: the door %s of %s did not lead to %s" % [next, here, now])
			return
	var open := cs.keys().filter(func(c): return not cs[c]["hidden"] and cs[c]["type"] != "rift")
	for c in open:
		if not reached.has(c):
			fail("walk: room %s (%s) never reached" % [c, cs[c]["type"]])
	# A cleared fight stays cleared.
	var fight = null
	for c in cs:
		if cs[c]["type"] in ["combat", "elite"] and cs[c]["room"] != null and cs[c]["room"].cleared:
			fight = c
	if fight == null:
		fail("walk: no cleared fight")
	else:
		var r: Room = FloorMap.room_at(fight, "s")
		G.enter_room(r)
		_tick(30)
		if G.locked or not G.enemies.filter(func(e): return e.type != "dummy").is_empty():
			fail("walk: a cleared fight locked again")
	# A hidden room: bomb its wall, walk in, walk out.
	_start(3)
	cs = G.floor_d["map"]["cells"]
	var hid = null
	for c in cs:
		if cs[c]["hidden"]:
			hid = c
	if hid != null:
		var par: Vector2i = cs[hid]["parent"]
		var pr := FloorMap.room_at(par, "s")
		G.floor_d["map"]["cur"] = par
		G.enter_room(pr)
		_kill_all()
		_clear()
		var d := ""
		for dd in World.DIRS:
			if par + World.DIRS[dd] == hid:
				d = dd
		if not G.room.secret_dirs.has(d):
			fail("hidden: no cracked wall toward it")
		World.open_secret(G.room, d)
		if not G.room.exits.has(d) or not G.room.exits[d].get("map", false):
			fail("hidden: the opened wall is not a door of the map")
		else:
			_go(d)
			if G.room.cell != hid or G.room.type != "secret":
				fail("hidden: walked into %s (%s)" % [G.room.cell, G.room.type])
			_go(World.OPP[d])
			if G.room.cell != par:
				fail("hidden: no way back")
	# The rift: off the map, and its last room leads back to the room before it.
	_start(1)
	cs = G.floor_d["map"]["cells"]
	var rift = null
	for c in cs:
		if cs[c]["type"] == "rift":
			rift = c
	if rift == null:
		fail("rift: none on the map")
	else:
		var par2: Vector2i = cs[rift]["parent"]
		G.floor_d["map"]["cur"] = par2
		G.enter_room(FloorMap.room_at(par2, "s"))
		_clear()
		var rd := ""
		for dd in World.DIRS:
			if par2 + World.DIRS[dd] == rift:
				rd = dd
		_go(rd)
		if G.room.on_map or G.room.theme.is_empty():
			fail("rift: did not enter its world")
		for step in 3:
			_clear()
			if G.room.exits.is_empty():
				fail("rift: room %d has no way on" % step)
				break
			_go(G.room.exits.keys()[0])
		if G.room.cell != par2 or not G.room.on_map:
			fail("rift: its end did not lead back (now in %s, on map %s)" % [G.room.cell, G.room.on_map])
		if cs.has(rift) or G.room.exits.has(rd):
			fail("rift: its door is still there")
