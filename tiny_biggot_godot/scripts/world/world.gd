class_name World
extends RefCounted
## Floors as a chain of rooms, tiles and collision (port of World.rb).
## After each room you pick the next door, and every door shows its room type
## and reward.

const T_FLOOR := 0
const T_WALL := 1
const T_PILLAR := 2
const T_DOOR := 3
const T_CRATE := 4
## Open sky between islands (Skyreach Isles only): heroes and walking foes cannot cross it;
## flying foes and every shot pass over it.
const T_VOID := 5
## Furniture of an event room (the saloon's bar, piano, tables): nothing but flyers passes; drawn
## by its room object, not by the tile kit.
const T_PROP := 6

const DIRS := { "n": Vector2i(0, -1), "s": Vector2i(0, 1), "e": Vector2i(1, 0), "w": Vector2i(-1, 0) }
const OPP := { "n": "s", "s": "n", "e": "w", "w": "e" }

## Collision modes (Ruby :player, :walker, :flyer, :bullet).
const M_PLAYER := 0
const M_WALKER := 1
const M_FLYER := 2
const M_BULLET := 3

## move_body result bits (Ruby returned [bx, by]).
const HIT_X := 1
const HIT_Y := 2

static func new_floor(index: int) -> Dictionary:
	var total := Dread.floor_rooms(index, mini(7 + index, 11))   # (48.1 TIDE OF ROOMS)
	var fd := { "index": index, "total": total, "depth": 0,
		"shop_depth": TB.rint(total / 2 - 1, total / 2 + 1), "shop_done": false, "path": [] }
	if GameData.rogues():
		# Rogues layer: every floor offers one RIFT door (a themed side stage) somewhere in its middle.
		fd["rift_depth"] = TB.rint(2, maxi(2, total - 3))
		fd["rift_done"] = false
	return fd

## opts (Rogues layer): "theme" (a rift world id), "step" (0-2 inside a rift), "event" (a mystery room's event).
static func make_room(floor_d: Dictionary, kind: String, reward: String, entrance: String, opts: Dictionary = {}) -> Room:
	var room := Room.new()
	room.type = kind
	room.reward = reward
	room.depth = floor_d["depth"]
	room.entrance = entrance
	room.seed_value = randi() % 1000000000
	if opts.has("theme"):
		room.theme = Themes.by_id(opts["theme"])
		room.rift_step = opts.get("step", 0)
		if room.rift_step == 2:
			room.champion = room.theme["champion"]
	room.event = opts.get("event", "")
	# Some fights hide a cracked wall on a side wall: bomb it to open a hidden room.
	if (kind == "combat" or kind == "elite") and room.theme.is_empty() and not opts.get("no_secret", false) and TB.rnd() < 0.28:
		var sides := ["e", "w"]
		sides.erase(entrance)
		var side: String = TB.pick(sides)
		room.secret_dirs[side] = true
		room.doors[side] = true
	build_room(room)
	return room

## Door reward for a combat room (04b_items.rb version, with weapons and gear).
static func roll_reward(p: Object, elite: bool = false) -> String:
	if elite:
		return TB.pick(["rare", "rare", "relic", "level", "weapon", "gear"])
	var low: bool = p != null and p.hp < p.max_hp / 2
	var w := { "relic": 14, "gold": 13, "heal": 20 if low else 7, "supply": 9, "armor": 6, "level": 12,
		"embers": 4, "weapon": 11, "gear": 13 }
	Food.reward_weights(w, G.floor_index)   # 36: "food", and "golden" on the deepest floors (expanded game)
	Draughts.reward_weights(w)   # 49.2 "draught", 49.3 "whet" (expanded game)
	return TB.weighted(w)

## Choices for the doors out of the current room.
static func gen_choices(floor_d: Dictionary, p: Object) -> Array:
	var d: int = floor_d["depth"] + 1
	if d >= floor_d["total"]:
		return [{ "type": "boss", "reward": "" }]
	var out := []
	if d == floor_d["shop_depth"] and not floor_d["shop_done"]:
		out.append({ "type": "shop", "reward": "" })
	if d == floor_d["total"] - 1:
		out.append({ "type": "rest", "reward": "" })
	# Stage 7: the room before the rest stop is the mini-boss room (new floors only).
	var fdef: Dictionary = GameData.floors()[floor_d["index"]]
	if fdef.has("mini") and d == floor_d["total"] - 2:
		return [{ "type": "elite", "reward": "rare" }]
	# Rogues layer: the floor's rift door, to a world this run has not seen yet.
	if floor_d.has("rift_depth") and not floor_d["rift_done"] and d >= floor_d["rift_depth"] and d < floor_d["total"] - 1:
		out.append({ "type": "rift", "reward": "", "theme": Themes.pick(G.run_stats.get("rifts", [])), "step": 0 })
	var n := 2 if d < 2 else (3 if TB.rnd() < 0.55 else 2)
	var tries := 0
	var fi: int = floor_d["index"]
	while out.size() < n and tries < 40:
		tries += 1
		var weights := { "combat": 46, "elite": 14 if (fi >= 1 or d >= 3) else 0, "treasure": 7,
			"shrine": 8, "challenge": 6 if fi >= 1 else 0, "vault": 5, "shop": 0 if floor_d["shop_done"] else 2 }
		if GameData.rogues():
			weights["mystery"] = 9   # Rogues layer: a random event room
		var kind: String = TB.weighted(weights)
		var c := { "type": kind, "reward": "" }
		if kind == "combat" or kind == "elite":
			c["reward"] = roll_reward(p, kind == "elite")
		var dup := false
		for o in out:
			if o["type"] == c["type"] and o["reward"] == c["reward"]:
				dup = true
			if kind != "combat" and o["type"] == kind:
				dup = true
		if dup:
			continue
		out.append(c)
	var has_fight := false
	for o in out:
		if o["type"] == "combat" or o["type"] == "elite":
			has_fight = true
	if not has_fight:
		out.append({ "type": "combat", "reward": roll_reward(p) })
	return out.slice(0, 3)

static func assign_exits(room: Room, choices: Array) -> void:
	var dirs := []
	for d in ["n", "w", "e"]:
		if d != room.entrance and not room.secret_dirs.has(d):
			dirs.append(d)
	# With few free walls, open doors take priority over locked vaults so a keyless hero is never boxed in.
	if choices.size() > dirs.size():
		var idx := []
		for i in choices.size():
			idx.append([1 if choices[i]["type"] == "vault" else 0, i])
		idx.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
		var sorted := []
		for e in idx:
			sorted.append(choices[e[1]])
		choices = sorted
	for i in choices.size():
		if i >= dirs.size():
			break
		var d: String = dirs[i]
		var c: Dictionary = choices[i]
		room.exits[d] = c
		room.doors[d] = true
		if c["type"] == "vault":
			room.sealed[d] = true
		for cr in door_tiles(d):
			room.set_tile(cr.x, cr.y, T_DOOR)

static func _clear_spot(ix: int, iy: int) -> bool:
	return (ix >= 10 and ix <= 15 and (iy <= 3 or iy >= 11)) or ((ix <= 3 or ix >= 22) and iy >= 5 and iy <= 9) \
		or (ix >= 11 and ix <= 14 and iy >= 6 and iy <= 8)

## Places a tile at a spot and its three mirror images (Ruby `put` lambda).
static func _put(room: Room, ix: int, iy: int, t: int) -> void:
	for ab in [Vector2i(ix, iy), Vector2i(25 - ix, iy), Vector2i(ix, 14 - iy), Vector2i(25 - ix, 14 - iy)]:
		var a: int = ab.x
		var b: int = ab.y
		if a < 0 or b < 0 or a >= TB.IW or b >= TB.IH or _clear_spot(a, b):
			continue
		room.set_tile(a + TB.IX0, b + TB.IY0, t)
		if t == T_CRATE:
			room.crate_hp[Vector2i(a + TB.IX0, b + TB.IY0)] = 12.0

static func build_room(room: Room) -> void:
	var rng := SeedRng.new(room.seed_value)
	var g := PackedByteArray()
	g.resize(TB.ROWS * TB.COLS)
	for r in TB.ROWS:
		for c in TB.COLS:
			var inside := c >= TB.IX0 and c < TB.IX0 + TB.IW and r >= TB.IY0 and r < TB.IY0 + TB.IH
			g[r * TB.COLS + c] = T_FLOOR if inside else T_WALL
	room.grid = g
	room.crate_hp = {}
	room.layout = 0
	if room.type == "barn":
		Rex.layout(room)
	if room.type in ["combat", "elite", "challenge"]:
		# Rogues layer: eight more layouts (9-16).
		# ROADMAP 4.7 part B: four more (17-20), with the floor's own pits (BiomeDeco).
		var pat := rng.int_range(0, 20 if GameData.rogues() else 8)
		# 62.2 (his plan: "mazes"): on the eleven floors of the first chapter, a fight room is now and
		# then a maze of the place's own props (stone halls) or of its pits (water, lava, drops).
		if GameData.rogues() and room.theme.is_empty() and room.champion == "" and G.floor_index <= 10 and rng.next_f() < 0.22:
			pat = 22 if G.floor_index in [1, 3, 6, 7, 9, 10] else 21
		if room.champion != "":
			pat = 0   # a champion gets an open arena
		elif room.theme.get("layouts", "") == "isles":
			pat = 100 + rng.int_range(1, 4)   # islands in the sky (layouts 101-104)
		elif room.theme.get("layouts", "") == "bastion":
			pat = 200 + rng.int_range(1, 4)   # rampart ruins (rift_extras.gd)
		elif room.theme.get("layouts", "") == "cathedral":
			pat = 300 + rng.int_range(1, 4)   # the brass nave (rift_extras.gd)
		match pat:
			1:
				_put(room, 5, 3, 2); _put(room, 6, 3, 2); _put(room, 5, 4, 2); _put(room, 6, 4, 2)
			2:
				for i in range(6, 10):
					_put(room, i, 6, 2)
				_put(room, 6, 5, 2)
			3:
				_put(room, 4, 2, 2); _put(room, 8, 2, 2); _put(room, 4, 5, 2); _put(room, 8, 5, 2); _put(room, 12, 3, 4)
			4:
				for k in 7:
					# Ruby evaluates the call arguments left to right; keep that order.
					var a := rng.int_range(2, 11)
					var b := rng.int_range(1, 6)
					var t := T_CRATE if rng.next_f() < 0.6 else T_PILLAR
					_put(room, a, b, t)
			5:
				for i in range(5, 10):
					_put(room, i, 4, 2 if i % 2 == 1 else 4)
			6:
				_put(room, 7, 2, 2); _put(room, 7, 3, 2); _put(room, 3, 6, 4); _put(room, 10, 5, 4)
			7:
				for ab in [Vector2i(3, 2), Vector2i(5, 4), Vector2i(7, 2), Vector2i(9, 4)]:
					_put(room, ab.x, ab.y, 2)
			8:
				for i in range(2, 6):
					_put(room, i, 3, 4)
				_put(room, 9, 1, 2); _put(room, 9, 2, 2)
			9:   # a ring of pillars around the middle
				_put(room, 8, 3, 2); _put(room, 10, 2, 2); _put(room, 6, 5, 2)
			10:  # two long walls with gaps: three lanes
				for i in [2, 3, 4, 6, 7, 8]:
					_put(room, i, 4, 2)
			11:  # crate staircases toward the corners
				for i in 5:
					_put(room, 2 + i, 1 + i, 4)
			12:  # corner bunkers
				_put(room, 3, 2, 2); _put(room, 4, 2, 2); _put(room, 3, 3, 2); _put(room, 5, 4, 4); _put(room, 6, 4, 4)
			13:  # a block in each quarter with crates beside it
				_put(room, 6, 3, 2); _put(room, 7, 3, 2); _put(room, 6, 4, 2); _put(room, 7, 4, 2)
				_put(room, 5, 3, 4); _put(room, 8, 4, 4); _put(room, 2, 6, 4)
			14:  # a field of single pillars
				for ab in [Vector2i(2, 1), Vector2i(5, 2), Vector2i(8, 1), Vector2i(3, 4), Vector2i(6, 5), Vector2i(9, 4), Vector2i(11, 2)]:
					_put(room, ab.x, ab.y, 2)
			15:  # a warehouse: lots of crates, a few pillars
				for k in 12:
					var a := rng.int_range(1, 11)
					var b := rng.int_range(1, 6)
					var t := T_CRATE if rng.next_f() < 0.85 else T_PILLAR
					_put(room, a, b, t)
			16:  # pillared hall: two rows of columns
				for i in [2, 5, 8, 11]:
					_put(room, i, 2, 2); _put(room, i, 5, 2)
			17:  # a pool (or a lava pit, a chasm...) in each quarter
				for a in range(3, 6):
					for b in range(2, 4):
						_put(room, a, b, T_VOID)
				_put(room, 9, 2, T_PILLAR)
			18:  # a channel across the room, broken by the doorways and the middle
				for a in range(4, 11):
					_put(room, a, 7, T_VOID)
				_put(room, 6, 3, T_PILLAR); _put(room, 8, 3, T_PILLAR)
			19:  # scattered sinkholes
				for ab in [Vector2i(3, 2), Vector2i(7, 4), Vector2i(10, 1), Vector2i(5, 6)]:
					_put(room, ab.x, ab.y, T_VOID)
					_put(room, ab.x + 1, ab.y, T_VOID)
				_put(room, 8, 2, T_PILLAR)
			20:  # two long pits along the top and bottom, props between
				for a in range(5, 11):
					_put(room, a, 1, T_VOID)
				_put(room, 4, 4, T_PILLAR); _put(room, 8, 5, T_PILLAR)
			101:  # four sky lakes, one in each quarter
				for a in range(3, 8):
					for b in range(2, 5):
						_put(room, a, b, T_VOID)
				_put(room, 10, 2, T_PILLAR)
			102:  # a ring of sky around the middle island, bridged in the four directions
				for a in range(8, 12):
					_put(room, a, 3, T_VOID)
				for b in range(3, 7):
					_put(room, 8, b, T_VOID)
				_put(room, 4, 2, T_PILLAR)
			103:  # three lanes split by two long drops (gusts love lanes)
				for a in range(1, 10):
					_put(room, a, 4, T_VOID)
				_put(room, 5, 1, T_PILLAR)
			104:  # stepping stones: a field of small holes
				for a in range(2, 11):
					for b in range(1, 7):
						if (a + b) % 3 == 0:
							_put(room, a, b, T_VOID)
			21, 22:  # 62.2 a maze: walls of props (21) or pits (22) along a lattice, every floor tile reachable
				_maze(room, rng, T_PILLAR if pat == 21 else T_VOID)
		if pat > 200:
			RiftExtras.layout(room, pat)
		room.layout = pat
	for d in room.doors.keys():
		for cr in door_tiles(d):
			room.set_tile(cr.x, cr.y, T_WALL if room.secret_dirs.has(d) else T_DOOR)

## 62.2 A maze: wall segments three tiles long between posts every four tiles, each kept at random
## (a little under half), never across the lanes from the four doors to the middle; then any floor
## the middle cannot reach is opened up, so every corner can be walked to.
static func _maze(room: Room, rng: SeedRng, t: int) -> void:
	var lane := func(c: int, r: int) -> bool:
		return (c >= 12 and c <= 15) or (r >= 8 and r <= 11) or (c >= 11 and c <= 16 and r >= 7 and r <= 12)
	var place := func(c: int, r: int) -> void:
		if c >= TB.IX0 and c < TB.IX0 + TB.IW and r >= TB.IY0 and r < TB.IY0 + TB.IH and not lane.call(c, r):
			room.set_tile(c, r, t)
	for py in range(TB.IY0 + 2, TB.IY0 + TB.IH, 4):
		for px in range(TB.IX0 + 2, TB.IX0 + TB.IW, 4):
			place.call(px, py)
			if rng.next_f() < 0.45:
				for k in range(1, 4):
					place.call(px + k, py)
			if rng.next_f() < 0.45:
				for k in range(1, 4):
					place.call(px, py + k)
	# every floor tile reachable from the middle (walkers' way)
	for _i in 40:
		var seen := {}
		var todo := [Vector2i(13, 9)]
		seen[todo[0]] = true
		while not todo.is_empty():
			var at: Vector2i = todo.pop_back()
			for d in DIRS.values():
				var n: Vector2i = at + d
				if not seen.has(n) and room.tile(n.x, n.y) in [T_FLOOR, T_CRATE]:
					seen[n] = true
					todo.append(n)
		var shut := Vector2i(-1, -1)
		for r in range(TB.IY0, TB.IY0 + TB.IH):
			for c in range(TB.IX0, TB.IX0 + TB.IW):
				if room.tile(c, r) == T_FLOOR and not seen.has(Vector2i(c, r)):
					shut = Vector2i(c, r)
					break
			if shut.x >= 0:
				break
		if shut.x < 0:
			return
		# open the wall tile next to it that leads toward the middle
		var step := Vector2i.ZERO
		for d in [Vector2i(signi(13 - shut.x), 0), Vector2i(0, signi(9 - shut.y)), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if d != Vector2i.ZERO and room.tile(shut.x + d.x, shut.y + d.y) == t:
				step = d
				break
		if step == Vector2i.ZERO:
			room.set_tile(shut.x, shut.y, t)   # (a pocket with no wall of the maze around it: filled in)
			continue
		var at2 := shut + step
		while room.tile(at2.x, at2.y) == t:
			room.set_tile(at2.x, at2.y, T_FLOOR)
			at2 += step

static func door_tiles(d: String) -> Array:
	match d:
		"n": return [Vector2i(13, 0), Vector2i(14, 0), Vector2i(13, 1), Vector2i(14, 1)]
		"s": return [Vector2i(13, 17), Vector2i(14, 17)]
		"w": return [Vector2i(0, 8), Vector2i(0, 9), Vector2i(0, 10)]
	return [Vector2i(27, 8), Vector2i(27, 9), Vector2i(27, 10)]

static func door_dir_at(c: int, r: int) -> String:
	if r <= 1:
		return "n"
	if r >= 17:
		return "s"
	return "w" if c == 0 else "e"

static func door_center(d: String) -> Vector2:
	match d:
		"n": return Vector2(14.0 * TB.TS, 1.0 * TB.TS)
		"s": return Vector2(14.0 * TB.TS, 17.5 * TB.TS)
		"w": return Vector2(0.5 * TB.TS, 9.5 * TB.TS)
	return Vector2(27.5 * TB.TS, 9.5 * TB.TS)

static func open_secret(room: Room, d: String) -> void:
	if not room.secret_dirs.has(d):
		return
	room.secret_dirs.erase(d)
	room.exits[d] = { "type": "secret", "reward": "" }
	for cr in door_tiles(d):
		room.set_tile(cr.x, cr.y, T_DOOR)
	FloorMap.on_secret_opened(room, d)   # on a floor map, the wall hid a room of the map

# ---------- Collision ----------
static func solid(room: Room, c: int, r: int, mode: int) -> bool:
	var t := room.tile(c, r)
	if t == T_FLOOR:
		return false
	if t == T_DOOR:
		return mode != M_PLAYER or G.locked or room.sealed.has(door_dir_at(c, r))
	if t == T_WALL:
		return true
	if t == T_VOID:
		return mode == M_PLAYER or mode == M_WALKER
	return mode != M_FLYER

static func hits_solid(room: Room, x: float, y: float, r: float, mode: int) -> bool:
	var c0 := floori((x - r) / TB.TS)
	var c1 := floori((x + r - 0.01) / TB.TS)
	var r0 := floori((y - r) / TB.TS)
	var r1 := floori((y + r - 0.01) / TB.TS)
	for rr in range(r0, r1 + 1):
		for cc in range(c0, c1 + 1):
			if solid(room, cc, rr, mode):
				return true
	return false

## Moves a body (any object with x, y, r) with axis-separated sliding.
## Returns HIT_X / HIT_Y bits for the axes that were blocked.
static func move_body(room: Room, e: Object, dx: float, dy: float, mode: int) -> int:
	var hit := 0
	if dx != 0:
		if not hits_solid(room, e.x + dx, e.y, e.r, mode):
			e.x += dx
		else:
			hit |= HIT_X
			var st := TB.sgn(dx)
			for i in ceili(absf(dx)):
				if hits_solid(room, e.x + st, e.y, e.r, mode):
					break
				e.x += st
	if dy != 0:
		if not hits_solid(room, e.x, e.y + dy, e.r, mode):
			e.y += dy
		else:
			hit |= HIT_Y
			var st := TB.sgn(dy)
			for i in ceili(absf(dy)):
				if hits_solid(room, e.x, e.y + st, e.r, mode):
					break
				e.y += st
	return hit

## A random free floor spot at least min_d away from `from` (an object with x, y, or null).
static func free_spot(room: Room, from: Object, min_d: float, mode: int = M_WALKER, rad: float = 8) -> Vector2:
	for i in 300:
		var c := TB.rint(TB.IX0 + 1, TB.IX0 + TB.IW - 2)
		var r := TB.rint(TB.IY0 + 1, TB.IY0 + TB.IH - 2)
		var x := c * TB.TS + 8.0
		var y := r * TB.TS + 8.0
		if solid(room, c, r, mode):
			continue
		if mode != M_FLYER and hits_solid(room, x, y, rad, mode):
			continue
		if from != null and TB.dist_xy(x, y, from.x, from.y) < min_d:
			continue
		return Vector2(x, y)
	return Vector2(TB.SW / 2.0, TB.SH / 2.0 + 16)
