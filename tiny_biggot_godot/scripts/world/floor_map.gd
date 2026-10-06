class_name FloorMap
extends RefCounted
## Floors as a map to explore (his ask, 5 Oct): the expanded game lays each floor out at the start
## as a tree of rooms on a grid, with doors in all four directions. You can walk back; a cleared
## room stays cleared. The guardian waits at the end of the deepest branch, with the rest stop
## before it (and, on the new floors, the mini-boss before that). Treasure, shrines, the shop, event
## rooms and the rift sit at the ends of side branches. One or two hidden rooms hang off the map
## behind cracked walls (bomb them). --classic (and --linear) keep the original chain of doors.
##
## floor_d["map"] = { "cells": { Vector2i: cell }, "cur": Vector2i, "start": Vector2i, "boss": Vector2i }
## cell = { "type", "reward", "dist", "room": Room or null, "visited", "hidden", "parent": Vector2i }
## Rooms made off the map (a rift's three rooms, a hidden room found by a loose brick or a flawless
## fight) lead back to the map cell they were entered from.

const SPAN_X := 4   # cells from the start to either side
const SPAN_Y := 3

static func active() -> bool:
	return G.floor_d.has("map")

static func wanted() -> bool:
	return GameData.rogues() and not DebugArgs.has("linear")

static func cells() -> Dictionary:
	return G.floor_d["map"]["cells"]

static func cur() -> Vector2i:
	return G.floor_d["map"]["cur"]

# ---------- Laying out a floor ----------
static func generate(floor_d: Dictionary, p: Object) -> void:
	var fi: int = floor_d["index"]
	var n_rooms: int = floor_d["total"] + 4 + TB.rint(0, 2)
	var cells := {}
	var start := Vector2i.ZERO
	cells[start] = _cell("start", "", 0, start)
	var order: Array = [start]
	var tries := 0
	while cells.size() < n_rooms and tries < 2000:
		tries += 1
		# Grow from a recent room more often than an old one: long branches, a few side shoots.
		var from: Vector2i = order[maxi(0, order.size() - 1 - TB.rint(0, mini(3, order.size() - 1)))] if TB.rnd() < 0.7 \
			else TB.pick(order)
		var d: String = TB.pick(["n", "s", "e", "w"])
		var to: Vector2i = from + World.DIRS[d]
		if cells.has(to) or absi(to.x) > SPAN_X or absi(to.y) > SPAN_Y:
			continue
		if _neighbours(cells, to) > 1:
			continue   # a tree: no loops
		if from == start and _neighbours(cells, start) >= 3:
			continue
		cells[to] = _cell("combat", "", cells[from]["dist"] + 1, from)
		order.append(to)
	# The guardian: the farthest dead end. The rest stop before it, the mini-boss before that.
	var leaves := []
	for c in cells:
		if c != start and _neighbours(cells, c) == 1:
			leaves.append(c)
	leaves.sort_custom(func(a, b): return cells[a]["dist"] > cells[b]["dist"] or (cells[a]["dist"] == cells[b]["dist"] and str(a) < str(b)))
	var boss: Vector2i = leaves[0]
	cells[boss]["type"] = "boss"
	var rest: Vector2i = cells[boss]["parent"]
	if rest != start:
		cells[rest]["type"] = "rest"
		var fdef: Dictionary = GameData.floors()[fi]
		var before: Vector2i = cells[rest]["parent"]
		if fdef.has("mini") and before != start:
			cells[before]["type"] = "elite"
			cells[before]["reward"] = "rare"
			cells[before]["mini"] = true
	# At least four side branches (a straight floor would leave no room for the shop and the rift):
	# grow dead ends off the fights along the way.
	var grow := 0
	while leaves.size() - 1 < 4 and grow < 400:
		grow += 1
		var c0: Vector2i = TB.pick(cells.keys())
		if not cells[c0]["type"] in ["combat", "start"] or (c0 == start and _neighbours(cells, start) >= 3) or leaves.has(c0):
			continue
		var dd: String = TB.pick(["n", "s", "e", "w"])
		var to2: Vector2i = c0 + World.DIRS[dd]
		if cells.has(to2) or absi(to2.x) > SPAN_X or absi(to2.y) > SPAN_Y or _neighbours(cells, to2) != 1:
			continue
		cells[to2] = _cell("combat", "", cells[c0]["dist"] + 1, c0)
		leaves.append(to2)
	# Side branches end in the good stuff.
	var extras := ["shop", "treasure", "mystery", "shrine", "mystery", "vault", "treasure", "challenge"]
	var rift_theme := ""
	if floor_d.has("rift_depth"):
		extras.insert(1, "rift")
		rift_theme = Themes.pick(G.run_stats.get("rifts", []))
	var k := 0
	for c in leaves.slice(1):
		if cells[c]["type"] != "combat" or k >= extras.size():
			continue
		var t: String = extras[k]
		k += 1
		if t == "challenge" and fi == 0:
			t = "treasure"
		cells[c]["type"] = t
		if t == "rift":
			cells[c]["theme"] = rift_theme
	# The rooms along the way: fights, with a few elite fights deeper in.
	for c in cells:
		var cell: Dictionary = cells[c]
		if cell["type"] == "combat":
			if (fi >= 1 or cell["dist"] >= 3) and TB.rnd() < 0.22:
				cell["type"] = "elite"
			cell["reward"] = World.roll_reward(p, cell["type"] == "elite")
		elif cell["type"] == "elite" and cell["reward"] == "":
			cell["reward"] = World.roll_reward(p, true)
	# Hidden rooms: off a fight, where the wall has open grid behind it.
	var hid := 0
	var want_hidden := 1 + (1 if TB.rnd() < 0.5 else 0)
	var fights := cells.keys().filter(func(c): return cells[c]["type"] in ["combat", "elite"] and not cells[c].get("mini", false))
	fights.shuffle()
	for c in fights:
		if hid >= want_hidden:
			break
		for d in ["e", "w", "n"]:
			var to: Vector2i = c + World.DIRS[d]
			if cells.has(to) or absi(to.x) > SPAN_X + 1 or absi(to.y) > SPAN_Y + 1 or _neighbours(cells, to) != 1:
				continue
			cells[to] = _cell("secret", "", cells[c]["dist"] + 1, c)
			cells[to]["hidden"] = true
			hid += 1
			break
	# Rex's barn (rex.gd): from the second floor, once a run, a hidden room may be his.
	if hid > 0 and G.floor_index >= 1 and not G.run_stats.get("rex", false) and TB.rnd() < Rex.CHANCE:
		for c in cells:
			if cells[c]["hidden"]:
				cells[c]["type"] = "barn"
				G.run_stats["rex"] = true
				break
	floor_d["map"] = { "cells": cells, "cur": start, "start": start, "boss": boss }
	floor_d["shop_done"] = true   # the map has its own shop; the chain's draw never adds one

static func _cell(t: String, reward: String, dist: int, parent: Vector2i) -> Dictionary:
	return { "type": t, "reward": reward, "dist": dist, "room": null, "visited": false, "hidden": false, "parent": parent }

static func _neighbours(cells: Dictionary, c: Vector2i) -> int:
	var n := 0
	for d in World.DIRS:
		if cells.has(c + World.DIRS[d]) and not cells[c + World.DIRS[d]]["hidden"]:
			n += 1
	return n

# ---------- Rooms of the map ----------
## The room of a cell, made the first time it is entered (entered from `entrance`).
static func room_at(c: Vector2i, entrance: String) -> Room:
	var cell: Dictionary = cells()[c]
	if cell["room"] != null:
		var r: Room = cell["room"]
		r.entrance = entrance
		return r
	var floor_d := G.floor_d
	var kind: String = cell["type"]
	var opts := { "no_secret": true }
	if kind == "mystery" or kind == "secret":
		if kind == "mystery":
			opts["event"] = TB.pick(G.mystery_events())
			if randf() < 0.18:
				opts["event"] = TB.pick(EventRooms.SPECIAL)
	# Depth: how far in it is (the mini-boss room is the one before the rest stop, as in the chain).
	floor_d["depth"] = floor_d["total"] - 2 if cell.get("mini", false) else mini(cell["dist"], floor_d["total"] - 3)
	if kind == "boss":
		floor_d["depth"] = floor_d["total"] - 1
	var r := World.make_room(floor_d, "start" if kind == "start" else kind, cell["reward"], entrance, opts)
	r.cell = c
	r.on_map = true
	cell["room"] = r
	link(r)
	return r

## Doors to every neighbour on the map (hidden ones as cracked walls), and their signs.
static func link(r: Room) -> void:
	var cs := cells()
	r.exits = {}
	for d in World.DIRS:
		var to: Vector2i = r.cell + World.DIRS[d]
		if not cs.has(to):
			continue
		var nb: Dictionary = cs[to]
		if nb["hidden"]:
			r.secret_dirs[d] = true
			r.doors[d] = true
			for cr in World.door_tiles(d):
				r.set_tile(cr.x, cr.y, World.T_WALL)
			continue
		r.doors[d] = true
		r.exits[d] = { "type": nb["type"], "reward": nb["reward"], "map": true }
		if nb["type"] == "vault" and not nb["visited"]:
			r.sealed[d] = true
			var pos := World.door_center(d)
			var ix: int = { "w": 22, "e": -22 }.get(d, 0)
			var iy: int = { "n": 26, "s": -22 }.get(d, 0)
			r.objects.append({ "kind": "lockdoor", "dir": d, "x": pos.x + ix, "y": pos.y + iy })
		for cr in World.door_tiles(d):
			r.set_tile(cr.x, cr.y, World.T_DOOR)
	r.exits_open = true

## A room made off the map has one way out: back to the map cell it was entered from.
static func link_back(r: Room) -> void:
	r.on_map = false
	r.exits = { r.entrance: { "type": "back", "reward": "", "map": true } }
	r.doors[r.entrance] = true
	for cr in World.door_tiles(r.entrance):
		r.set_tile(cr.x, cr.y, World.T_DOOR)
	r.exits_open = true

## Walking through door `dir` of the current room. Returns the room to enter.
static func step(dir: String) -> Room:
	var m: Dictionary = G.floor_d["map"]
	var room := G.room
	if not room.on_map:
		# Back from an off-map room to the cell it hangs off.
		return room_at(m["cur"], World.OPP[dir])
	var to: Vector2i = room.cell + World.DIRS[dir]
	m["cur"] = to
	var cell: Dictionary = cells()[to]
	cell["hidden"] = false
	cell["visited"] = true
	return room_at(to, World.OPP[dir])

## After a cracked wall is bombed open: the hidden cell becomes a real door.
static func on_secret_opened(room: Room, d: String) -> void:
	if not active() or not room.on_map:
		return
	var to: Vector2i = room.cell + World.DIRS[d]
	if cells().has(to):
		cells()[to]["hidden"] = false
		room.exits[d] = { "type": "secret", "reward": "", "map": true }

## The rift of this floor is used up: its door closes for good.
static func close_cell(c: Vector2i) -> void:
	if not active() or not cells().has(c):
		return
	var parent: Vector2i = cells()[c]["parent"]
	cells().erase(c)
	if cells().has(parent) and cells()[parent]["room"] != null:
		var pr: Room = cells()[parent]["room"]
		for d in World.DIRS:
			if parent + World.DIRS[d] == c:
				pr.exits.erase(d)
				pr.doors.erase(d)
				for cr in World.door_tiles(d):
					pr.set_tile(cr.x, cr.y, World.T_WALL)

# ---------- The autopilot ----------
## A door toward a room not yet seen; when all are seen, toward the guardian.
static func bot_door(room: Room) -> String:
	if not room.on_map:
		for d in room.exits:
			if room.exits[d]["type"] == "rift":
				return d   # deeper into a rift (to a new world's guardian, too)
		return room.entrance if room.exits.has(room.entrance) else (room.exits.keys()[0] if not room.exits.is_empty() else "")
	var cs := cells()
	var p := G.player
	# Breadth-first from here over open map cells.
	var prev := { room.cell: room.cell }
	var q := [room.cell]
	var goal = null
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		if c != room.cell and not cs[c]["visited"] and not (cs[c]["type"] == "vault" and p.keys <= 0):
			goal = c
			break
		for d in World.DIRS:
			var to: Vector2i = c + World.DIRS[d]
			if cs.has(to) and not cs[to]["hidden"] and not prev.has(to):
				prev[to] = c
				q.append(to)
	if goal == null:
		goal = G.floor_d["map"]["boss"]
		if not prev.has(goal):
			return ""
	var c2: Vector2i = goal
	while prev[c2] != room.cell and c2 != room.cell:
		c2 = prev[c2]
	for d in World.DIRS:
		if room.cell + World.DIRS[d] == c2:
			return d
	return ""

# ---------- The minimap (hud_view.gd) ----------
static func draw_minimap(ci: CanvasItem, right: float, top: float) -> void:
	var cs := cells()
	var w := 7.0
	var h := 5.0
	var ox := right - (SPAN_X * 2 + 3) * w
	var seen := {}
	for c in cs:
		if cs[c]["visited"] or c == cur():
			seen[c] = true
			for d in World.DIRS:
				var nb: Vector2i = c + World.DIRS[d]
				if cs.has(nb) and not cs[nb]["hidden"]:
					seen[nb] = true
	for c in seen:
		var cell: Dictionary = cs[c]
		var x: float = ox + (c.x + SPAN_X + 1) * w
		var y: float = top + (c.y + SPAN_Y + 1) * h
		var col := "#2a2838"
		if cell["visited"] or c == cur():
			col = GameData.ROOM_COL.get(cell["type"], "#5c5a78")
		if c == cur():
			col = "#f4ecd8"
		ci.draw_rect(Rect2(x, y, w - 1, h - 1), TB.c("#140f1c"))
		ci.draw_rect(Rect2(x + 1, y + 1, w - 3, h - 3), TB.c(col))
		if cell["type"] == "boss":
			Gfx.px(ci, TB.c("#d8443c"), x + 2, y + 1, 2)
