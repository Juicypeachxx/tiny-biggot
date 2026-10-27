extends Node
## 62.1 the first six floors' traps (scripts/world/traps.gd). Run:
##   godot --headless --path . res://tests/traps_test.tscn -- --no-save
## 1 Each of the six floors lays its own kind in its fight rooms (two to four), on open floor, apart;
##   classic rooms, the start room and floors without a kind lay none.
## 2 A plate, a jet and a blade: resting they hurt no one; striking they hurt the hero standing in
##   them (once a strike) and a foe; a cleared room rests them.
## 3 Every kind is drawn.
## 4 62.2 mazes: on each of the first chapter's floors some fight rooms are mazes (of props or pits);
##   in every one each floor tile and each doorway can be walked to from the middle.
## 5 62.3 tricks: a room with a hidden wall has its floor's trick beside it, on open floor; using it
##   opens the wall; classic rooms have none.
## 6 62.4 set pieces: some fight rooms of each first-chapter floor hold the place's own, on open
##   floor; using it gives its gift once; every one is drawn, and the drips.
## Prints "traps test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL traps: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	G.hero_index = 0
	G.new_run()
	_laying()
	_striking()
	_mazes()
	_tricks()
	_set_pieces()
	await _drawing()
	print("traps test: PASSED" if fails == 0 else "traps test: %d FAILED" % fails)
	get_tree().quit()

func _room(floor_index: int, kind := "combat") -> Room:
	G.floor_index = floor_index
	G.start_floor()
	var room := World.make_room(G.floor_d, kind, "", "s", { "no_secret": true })
	G.room = room
	Traps.setup(room, floor_index)
	return room

func _laying() -> void:
	for f in Traps.KINDS.size():
		var total := 0
		for i in 12:
			var room := _room(f)
			total += room.traps.size()
			if room.traps.size() > 4:
				fail("floor %d: %d traps in a room" % [f, room.traps.size()])
			for t in room.traps:
				if t["kind"] != Traps.KINDS[f]:
					fail("floor %d lays %s" % [f, t["kind"]])
				if room.tile(t["c"], t["r"]) != World.T_FLOOR:
					fail("floor %d: a trap on a tile that is not floor" % f)
		print("[traps] floor %d (%s): %d traps in 12 rooms" % [f, Traps.KINDS[f], total])
		if total < 12:
			fail("floor %d: only %d traps in 12 rooms" % [f, total])
	if not _room(0, "start").traps.is_empty():
		fail("a start room has traps")
	if not _room(6).traps.is_empty():
		fail("floor 7 (its own hazards) has traps")
	GameData.force_classic = true
	var any := 0
	for i in 8:
		any += _room(0).traps.size()
	GameData.force_classic = false
	if any > 0:
		fail("classic rooms have traps")

## One trap of `kind` at (8, 9), the hero on its tile (a jet: its first tile; a blade: its middle).
func _one(kind: String) -> Dictionary:
	var room := _room(0)
	for r in range(TB.IY0, TB.IY0 + TB.IH):
		for c in range(TB.IX0, TB.IX0 + TB.IW):
			room.grid[r * TB.COLS + c] = World.T_FLOOR
	G.enter_room(room)
	G.enemies.clear()
	G.state = &"play"
	var t := { "kind": kind, "c": 8, "r": 9, "t": 0.0, "hit": {}, "d": Vector2i(1, 0) }
	room.traps = [t]
	return t

func _striking() -> void:
	for kind in ["spikes", "fire", "blade"]:
		var t := _one(kind)
		var p := G.player
		var at := Vector2((9.5 if kind == "fire" else 8.5) * TB.TS, 9.5 * TB.TS)
		p.x = at.x
		p.y = at.y
		var foe := Combat.spawn_enemy("skeleton", at.x, at.y, false, true)
		foe.spawn_t = 0.0
		var hp0 := p.hp
		var fhp0 := foe.hp
		if kind != "blade":
			Traps.tick(G.room, 0.5)   # resting
			p.invuln = 0.0
			if p.hp < hp0 or foe.hp < fhp0:
				fail("%s hurts while resting" % kind)
			t["t"] = Traps.REST + Traps.WARN - 0.01
		p.invuln = 0.0
		p.dodge_t = 0.0
		Traps.tick(G.room, 0.05)
		if p.hp >= hp0:
			fail("%s striking did not hurt the hero standing in it" % kind)
		if foe.hp >= fhp0 and foe.hp > 0:
			fail("%s striking did not hurt a foe" % kind)
		# a cleared room rests every trap
		G.enemies.clear()
		hp0 = p.hp
		p.invuln = 0.0
		Traps.tick(G.room, 0.05)
		if p.hp < hp0:
			fail("%s hurt the hero in a cleared room" % kind)

func _mazes() -> void:
	for f in 11:
		var mazes := 0
		for i in 60:
			G.floor_index = f
			G.start_floor()
			var room := World.make_room(G.floor_d, "combat", "", "s", {})
			if room.layout != 21 and room.layout != 22:
				continue
			mazes += 1
			var seen := {}
			var todo := [Vector2i(13, 9)]
			seen[todo[0]] = true
			while not todo.is_empty():
				var at: Vector2i = todo.pop_back()
				for d in World.DIRS.values():
					var n: Vector2i = at + d
					if not seen.has(n) and room.tile(n.x, n.y) in [World.T_FLOOR, World.T_CRATE, World.T_DOOR]:
						seen[n] = true
						todo.append(n)
			for r in TB.ROWS:
				for c in TB.COLS:
					if room.tile(c, r) in [World.T_FLOOR, World.T_DOOR] and not seen.has(Vector2i(c, r)):
						fail("floor %d maze %d: tile (%d, %d) cannot be reached" % [f, room.layout, c, r])
		print("[mazes] floor %d: %d mazes in 60 fight rooms" % [f, mazes])
		if mazes < 4:
			fail("floor %d: only %d mazes in 60 rooms" % [f, mazes])

func _tricks() -> void:
	for f in 11:
		var found := 0
		for i in 40:
			G.floor_index = f
			G.start_floor()
			var room := World.make_room(G.floor_d, "combat", "", "s", {})
			if room.secret_dirs.is_empty():
				continue
			room.objects = []
			Tricks.setup(room, f)
			var tr: Array = room.objects.filter(func(o): return o["kind"] == "trick")
			if tr.is_empty():
				fail("floor %d: a hidden wall without its trick (layout %d)" % [f, room.layout])
				continue
			found += 1
			var o: Dictionary = tr[0]
			if o["trick"] != Tricks.kind_for(f):
				fail("floor %d has a %s" % [f, o["trick"]])
			var c := floori(o["x"] / TB.TS)
			var r := floori(o["y"] / TB.TS)
			if o["trick"] != "draught" and room.tile(c, r) != World.T_FLOOR:
				fail("floor %d: the %s is not on open floor" % [f, o["trick"]])
			if found == 1:   # using it opens the wall
				G.enter_room(room)
				var d: String = o["dir"]
				G.interact(o)
				if room.secret_dirs.has(d) or not room.exits.has(d):
					fail("floor %d: the %s did not open the wall" % [f, o["trick"]])
		print("[tricks] floor %d (%s): %d hidden walls with their trick" % [f, Tricks.kind_for(f), found])
		if found == 0:
			fail("floor %d: no hidden wall in 40 rooms" % f)
	GameData.force_classic = true
	G.floor_index = 0
	G.start_floor()
	var room := World.make_room(G.floor_d, "combat", "", "s", {})
	room.secret_dirs["e"] = true
	room.objects = []
	Tricks.setup(room, 0)
	GameData.force_classic = false
	if not room.objects.is_empty():
		fail("a classic room has a trick")

func _set_pieces() -> void:
	for f in SetPieces.PIECES.size():
		var found := 0
		for i in 40:
			G.floor_index = f
			G.start_floor()
			var room := World.make_room(G.floor_d, "combat", "", "s", {})
			room.objects = []
			room.traps = []
			SetPieces.setup(room, f)
			for o in room.objects:
				found += 1
				var c := floori(o["x"] / TB.TS)
				var r := floori(o["y"] / TB.TS)
				for k in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
					if room.tile(c + k.x, r + k.y) != World.T_FLOOR:
						fail("floor %d: the set piece is not on open floor" % f)
		print("[set pieces] floor %d (%s): %d in 40 fight rooms" % [f, SetPieces.PIECES[f][0], found])
		if found < 2:
			fail("floor %d: only %d set pieces in 40 rooms" % [f, found])
	# each one's gift
	var p := G.player
	for f in SetPieces.PIECES.size():
		G.floor_index = f
		var o := { "kind": "setpiece", "piece": f, "x": 200.0, "y": 150.0 }
		G.room.objects = [o]
		var before := [p.armor, p.hp, p.xp, p.gold, p.buffs.size(), G.pickups.size()]
		p.hp = 1
		before[1] = 1
		G.interact(o)
		var after := [p.armor, p.hp, p.xp, p.gold, p.buffs.size(), G.pickups.size()]
		if after == before:
			fail("the %s gave nothing" % SetPieces.PIECES[f][0])
		if not o.get("used", false):
			fail("the %s can be used again" % SetPieces.PIECES[f][0])
		p.hp = p.max_hp
	G.floor_index = 0

class Canvas extends Node2D:
	var done := false
	func _draw() -> void:
		Traps.draw(self, 1.0)
		for o in G.room.objects:
			if o["kind"] == "trick":
				Tricks.draw(self, o, 1.0)
				o["used"] = true
				Tricks.draw(self, o, 1.0)
			if o["kind"] == "setpiece":
				SetPieces.draw(self, o, 1.0)
		for f in SetPieces.WET:
			G.floor_index = f
			SetPieces.draw_live(self, 1.0 + f)
		G.floor_index = 0
		done = true

func _drawing() -> void:
	var room := _room(0)
	G.room = room
	room.traps = []
	var x := 3
	for kind in ["spikes", "thorns", "water", "fire", "frost", "blade"]:
		room.traps.append({ "kind": kind, "c": x, "r": 9, "t": Traps.REST + Traps.WARN + 0.1, "hit": {}, "d": Vector2i(0, 1) })
		x += 4
	var foe := Combat.spawn_enemy("skeleton", 100, 100, false, true)
	foe.spawn_t = 0.0
	for k in Tricks.NAME.keys():
		room.objects.append({ "kind": "trick", "trick": k, "dir": "e", "x": 200.0, "y": 150.0 })
	for f in SetPieces.PIECES.size():
		room.objects.append({ "kind": "setpiece", "piece": f, "x": 40.0 + f * 30, "y": 120.0 })
	var cv := Canvas.new()
	add_child(cv)
	cv.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	if not cv.done:
		fail("the traps were not drawn")
