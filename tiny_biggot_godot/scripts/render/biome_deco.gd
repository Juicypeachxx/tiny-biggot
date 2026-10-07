class_name BiomeDeco
extends RefCounted
## The look of the eleven floors in the expanded game (ROADMAP 4.7 part B; his ask, 5 Oct:
## "revamp the environments, make them less boring"). Each floor gets its own props where the
## plain square pillar stood, things on the floor (cracks, puddles, moss, bones, ash...), a set
## piece in some rooms, dressing on the top wall, flickering lights, drifting air (dust, spores,
## embers, snow, rain...) and pits of its own (water, lava, a chasm, the void) in some rooms
## (World.build_room, layouts 17-20). Drawing only, with its own random numbers: the game's are
## never drawn here. His ask, 6 Oct ("revamp original stages too"): the original game (--classic)
## gets the new look as well; its rules and layouts are untouched (the pits are expanded only).
## The rift worlds and rooms with a kit of their own keep their look.

## Per floor: props (instead of the pillar), wall dressing, floor decals, set piece, air, pit.
const BIOMES := [
	{ "props": ["prop_bonepile", "prop_coffin", "prop_urn"], "wall": ["wall_skullniche", "wall_chains"], "decals": ["bones", "crack", "crack", "pebbles", "cobweb"], "piece": "mosaic", "air": "dust", "pit": "chasm" },
	{ "props": ["prop_stump", "prop_shroom", "prop_mossrock"], "wall": ["wall_vines", "wall_glowshroom"], "decals": ["moss", "moss", "grass", "puddle", "shroomlets"], "piece": "mossring", "air": "spores", "pit": "water" },
	{ "props": ["prop_shelf", "prop_bookpile", "prop_bust"], "wall": ["wall_books", "wall_window"], "decals": ["pages", "puddle", "crack", "weed"], "piece": "pool", "air": "bubbles", "pit": "water" },
	{ "props": ["prop_anvil", "prop_brazier", "prop_ironbarrel"], "wall": ["wall_vent", "wall_chains"], "decals": ["lavacrack", "soot", "coal", "plate"], "piece": "grate", "air": "embers", "pit": "lava" },
	{ "props": ["prop_icecrystal", "prop_frostpillar", "prop_strongbox"], "wall": ["wall_chains", "icicles"], "decals": ["frost", "frost", "icecrack", "sparkle"], "piece": "ice", "air": "glints", "pit": "ice" },
	{ "props": ["prop_column", "prop_candelabra", "prop_armor"], "wall": ["wall_portrait", "banner"], "decals": ["marble", "wax", "goldbits"], "piece": "carpet", "air": "gold", "pit": "chasm" },
	{ "props": ["prop_lamppost", "prop_haybale", "prop_rainbarrel"], "wall": ["wall_window", "wall_vines"], "decals": ["puddle", "mud", "grass", "leaves"], "piece": "planks", "air": "rain", "pit": "water" },
	{ "props": ["prop_sandbags", "prop_stakes", "prop_wagonwheel"], "wall": ["wall_racks", "banner"], "decals": ["scorch", "ash", "arrows", "blood"], "piece": "crater", "air": "ash", "pit": "lava" },
	{ "props": ["prop_stonelantern", "prop_prayerbell", "prop_monkstatue"], "wall": ["flags", "wall_chains"], "decals": ["snow", "snow", "seam", "petals"], "piece": "mat", "air": "snow", "pit": "ice" },
	{ "props": ["prop_chimney", "prop_gargoyle", "prop_weathervane"], "wall": ["wall_window", "wall_vent"], "decals": ["shingle", "puddle", "feather"], "piece": "skylight", "air": "wind", "pit": "chasm" },
	{ "props": ["prop_obelisk", "prop_monolith", "prop_shard"], "wall": ["wall_eye", "wall_chains"], "decals": ["rune", "voidcrack", "rune"], "piece": "sigil", "air": "motes", "pit": "void" },
]
## Props that give light: glow sprite and its offset from the prop's top left.
const LIT := { "prop_brazier": ["glow_torch", 8, 2], "prop_candelabra": ["glow_torch", 8, 1], "prop_lamppost": ["glow_torch", 3, 7],
	"prop_stonelantern": ["glow_torch", 8, 6], "prop_obelisk": ["glow_red", 8, 8] }
## Spots on the top wall face for dressing (x of a 16-wide piece), clear of the torches and the door.
const WALL_X := [24, 56, 136, 160, 272, 296, 376, 408]
## Pits (World.T_VOID in a floor's own rooms): fill, deep, lip, detail colours.
const PITS := { "chasm": ["#0b0810", "#050308", "#4e4a5e", "#1c1626"], "water": ["#1d4a5a", "#123341", "#6fd3e0", "#2f6f7f"],
	"lava": ["#8a2a1a", "#5a160e", "#f2c94c", "#e8873a"], "ice": ["#2b4f8a", "#1b3566", "#e8f6ff", "#9fc3ee"],
	"void": ["#14061a", "#07020a", "#a35bd6", "#3c1d47"] }

static var _lights: Array = []    # this room's lit props: [glow, x, y]
static var _room: WeakRef = null
static var _air: Array = []       # drifting motes: { x, y, vx, vy, t, life, k }
static var _rng := RandomNumberGenerator.new()

## True when the expanded game's look applies to this room.
static func on(room: Room) -> bool:
	return room != null and room.theme.is_empty() and room.kit == "" and room.type != "barn" and G.floor_index < GameData.FLOORS.size() + GameData.NEW_FLOORS.size()   # 12.2: Chapter II has plain tiles of its own

static func biome() -> Dictionary:
	return BIOMES[clampi(G.floor_index, 0, BIOMES.size() - 1)]

static func _col(hex: String, a: float = 1.0) -> Color:
	var c := TB.c(hex)
	c.a = a
	return c

# ---------- the room background (static, drawn once per room) ----------
## Set piece, floor decals and pits, over the tiles and under the props.
static func paint_floor(ci: CanvasItem, room: Room) -> void:
	var b := biome()
	var rng := SeedRng.new(room.seed_value ^ 0x2c1b3c6d)
	_paint_pits(ci, room, b["pit"], rng)
	if room.type != "start" and rng.next_f() < 0.6:
		_piece(ci, room, b["piece"], rng)
	var decals: Array = b["decals"]
	for i in 22 + rng.int_range(0, 10):
		var c := rng.int_range(TB.IX0, TB.IX0 + TB.IW - 1)
		var r := rng.int_range(TB.IY0, TB.IY0 + TB.IH - 1)
		var k: String = decals[rng.int_range(0, decals.size() - 1)]
		if room.tile(c, r) != World.T_FLOOR or (room.type == "start" and r >= 7 and r <= 9):
			continue
		_decal(ci, k, c * TB.TS + rng.int_range(1, 11), r * TB.TS + rng.int_range(1, 11), rng)

## Dressing on the top wall face.
static func paint_wall(ci: CanvasItem, room: Room) -> void:
	var b := biome()
	var rng := SeedRng.new(room.seed_value ^ 0x51ed270b)
	var kinds: Array = b["wall"]
	if "icicles" in kinds:
		for x in range(TB.TS, TB.SW - TB.TS, 3):
			var n := rng.int_range(1, 5)
			for j in n:
				ci.draw_rect(Rect2(x, 2 * TB.TS + j, maxi(1, 2 - j / 2), 1), _col("#e8f6ff" if j < 2 else "#9fc3ee", 0.9 - j * 0.12))
	if "flags" in kinds:
		var cols := ["#d8443c", "#f2c94c", "#63b84f", "#4d9be6", "#f4ecd8"]
		for seg in [[20, 92], [118, 186], [262, 330], [356, 428]]:
			for x in range(seg[0], seg[1]):
				var k: float = float(x - seg[0]) / (seg[1] - seg[0])
				var y := 19.0 + sin(k * PI) * 5.0
				ci.draw_rect(Rect2(x, y, 1, 1), _col("#8b8f9c", 0.8))
				if (x - seg[0]) % 7 == 3:
					ci.draw_rect(Rect2(x - 1, y + 1, 4, 5), _col(cols[(x / 7) % cols.size()], 0.9))
	var spots := WALL_X.duplicate()
	for i in 3 + rng.int_range(0, 2):
		var x: int = spots.pop_at(rng.int_range(0, spots.size() - 1))
		var k: String = kinds[rng.int_range(0, kinds.size() - 1)]
		match k:
			"icicles", "flags":
				pass
			"banner":
				var c1 := "#5c3483" if G.floor_index == 5 else "#8a2a33"
				ci.draw_rect(Rect2(x + 3, 17, 10, 1), _col("#7a5236"))
				ci.draw_rect(Rect2(x + 4, 18, 8, 11), _col(c1))
				ci.draw_rect(Rect2(x + 5, 20, 6, 1), _col("#f2c94c"))
				ci.draw_rect(Rect2(x + 7, 22, 2, 4), _col("#f2c94c"))
				ci.draw_rect(Rect2(x + 4, 29, 3, 2), _col(c1))
				ci.draw_rect(Rect2(x + 9, 29, 3, 2), _col(c1))
			_:
				var tex := Img.t(k)
				ci.draw_texture(tex, Vector2(x, 2 * TB.TS - 1 - tex.get_height()))

## A pillar tile's prop (in place of the plain square pillar), with a soft shadow at its foot.
static func paint_prop(ci: CanvasItem, room: Room, c: int, r: int) -> void:
	var props: Array = biome()["props"]
	var k: String = props[absi((c * 73856093) ^ (r * 19349663) ^ room.seed_value) % props.size()]
	var tex := Img.t(k)
	var x := float(c * TB.TS)
	var y := float((r + 1) * TB.TS + 1 - tex.get_height())
	ci.draw_rect(Rect2(x + 2, (r + 1) * TB.TS - 2, 12, 3), Color(0, 0, 0, 0.35))
	ci.draw_texture(tex, Vector2(x, y))
	if LIT.has(k):
		_lights.append([LIT[k][0], x + LIT[k][1], y + LIT[k][2]])

## Called before a room's background is drawn: forget the old room's lights and air.
static func begin(room: Room) -> void:
	_lights.clear()
	if _room == null or _room.get_ref() != room:
		_air.clear()
		_room = weakref(room)

# ---------- every frame ----------
## Flickering light over the lit props (the additive glow layer).
static func paint_glow(ci: CanvasItem, t: float) -> void:
	for i in _lights.size():
		var l: Array = _lights[i]
		var op := (190.0 + sin(t * 8.0 + i * 5.0) * 25.0 + sin(t * 21.0 + i) * 12.0) / 255.0
		Gfx.at(ci, l[0], l[1] - 36, l[2] - 36, op * (0.8 if l[0] == "glow_red" else 1.0))

## Drifting air: moves the motes (once per logic tick).
static func tick(dt: float) -> void:
	var kind: String = biome()["air"]
	var want: int = { "rain": 40, "snow": 32, "ash": 26, "embers": 22, "wind": 12 }.get(kind, 18)
	while _air.size() < want:
		_air.append(_spawn(kind, true))
	for m in _air:
		m["t"] += dt
		m["x"] += m["vx"] * dt
		m["y"] += m["vy"] * dt
		if kind in ["spores", "snow", "ash", "gold", "motes"]:
			m["x"] += sin(m["t"] * 1.7 + m["ph"]) * 6.0 * dt
		if m["t"] > m["life"] or m["y"] > TB.SH or m["y"] < 20 or m["x"] < 0 or m["x"] > TB.SW:
			m.merge(_spawn(kind, false), true)

static func _spawn(kind: String, anywhere: bool) -> Dictionary:
	var x := _rng.randf_range(16, TB.SW - 16)
	var y := _rng.randf_range(36, TB.SH - 20)
	var vx := 0.0
	var vy := 0.0
	var life := _rng.randf_range(3.0, 7.0)
	match kind:
		"dust", "glints":
			vx = _rng.randf_range(-4, 4)
			vy = _rng.randf_range(-3, 3)
		"spores", "bubbles", "embers", "motes":
			vy = -_rng.randf_range(6, 16) * (2.0 if kind == "embers" else 1.0)
			if not anywhere:
				y = TB.SH - 20 - _rng.randf_range(0, 60)
		"gold", "ash", "snow":
			vy = _rng.randf_range(5, 12) * (2.0 if kind == "snow" else 1.0)
			vx = _rng.randf_range(-3, 3) + (6.0 if kind == "snow" else 0.0)
			if not anywhere:
				y = 36.0
		"rain":
			vx = -40.0
			vy = 220.0
			life = 2.0
			if not anywhere:
				y = 36.0 + _rng.randf_range(0, 40)
		"wind":
			vx = _rng.randf_range(80, 140)
			vy = _rng.randf_range(-4, 4)
			if not anywhere:
				x = 16.0
	return { "x": x, "y": y, "vx": vx, "vy": vy, "t": 0.0, "life": life, "ph": _rng.randf() * TAU }

static func paint_air(ci: CanvasItem, t: float) -> void:
	var kind: String = biome()["air"]
	for m in _air:
		var fade := clampf(minf(m["t"], m["life"] - m["t"]) * 2.0, 0.0, 1.0)
		var x: float = roundf(m["x"])
		var y: float = roundf(m["y"])
		match kind:
			"dust": ci.draw_rect(Rect2(x, y, 1, 1), _col("#d9d0b4", 0.35 * fade))
			"spores": ci.draw_rect(Rect2(x, y, 1, 1), _col("#b8e05a", 0.6 * fade))
			"bubbles":
				ci.draw_rect(Rect2(x, y, 2, 2), _col("#6fd3e0", 0.35 * fade))
				ci.draw_rect(Rect2(x, y, 1, 1), _col("#e8f6ff", 0.5 * fade))
			"embers": ci.draw_rect(Rect2(x, y, 1, 1), _col("#f2c94c" if sin(t * 12 + m["ph"]) > 0 else "#e8873a", 0.9 * fade))
			"glints":
				var tw := maxf(0.0, sin(t * 3.0 + m["ph"]))
				ci.draw_rect(Rect2(x, y, 1, 1), _col("#e8f6ff", 0.8 * tw * fade))
				if tw > 0.9:
					ci.draw_rect(Rect2(x - 1, y, 3, 1), _col("#e8f6ff", 0.4 * fade))
					ci.draw_rect(Rect2(x, y - 1, 1, 3), _col("#e8f6ff", 0.4 * fade))
			"gold": ci.draw_rect(Rect2(x, y, 1, 1), _col("#f2c94c", (0.4 + 0.4 * maxf(0.0, sin(t * 4 + m["ph"]))) * fade))
			"rain":
				ci.draw_line(Vector2(x, y), Vector2(x + 1.5, y - 7), _col("#9fc3ee", 0.45 * fade), 1.0)
			"ash": ci.draw_rect(Rect2(x, y, 2 if m["ph"] > 3.0 else 1, 1), _col("#8b8f9c", 0.55 * fade))
			"snow": ci.draw_rect(Rect2(x, y, 2 if m["ph"] > 4.0 else 1, 2 if m["ph"] > 4.0 else 1), _col("#ffffff", 0.75 * fade))
			"wind": ci.draw_rect(Rect2(x, y, 6, 1), _col("#c8c4d8", 0.25 * fade))
			"motes": ci.draw_rect(Rect2(x, y, 1, 1), _col("#a35bd6" if m["ph"] > 3.0 else "#d8443c", (0.5 + 0.4 * sin(t * 5 + m["ph"])) * fade))

# ---------- floor pieces ----------
static func _paint_pits(ci: CanvasItem, room: Room, kind: String, rng: SeedRng) -> void:
	var pc: Array = PITS[kind]
	for r in range(TB.IY0, TB.IY0 + TB.IH):
		for c in range(TB.IX0, TB.IX0 + TB.IW):
			if room.tile(c, r) != World.T_VOID:
				continue
			var x := c * TB.TS
			var y := r * TB.TS
			ci.draw_rect(Rect2(x, y, TB.TS, TB.TS), _col(pc[0]))
			if room.tile(c, r - 1) != World.T_VOID:
				ci.draw_rect(Rect2(x, y, TB.TS, 5), _col(pc[1]))   # the far wall of the pit, in shadow
				ci.draw_rect(Rect2(x, y, TB.TS, 1), _col(pc[2], 0.8))   # the lip
			for k in 3:
				var dx := rng.int_range(1, 12)
				var dy := rng.int_range(6, 14)
				match kind:
					"water", "ice": ci.draw_rect(Rect2(x + dx, y + dy, 3, 1), _col(pc[3], 0.8))
					"lava": ci.draw_rect(Rect2(x + dx, y + dy, 2, 2), _col(pc[3 if k > 0 else 2]))
					"void": ci.draw_rect(Rect2(x + dx, y + dy, 1, 1), _col(pc[2], 0.7))
					_: ci.draw_rect(Rect2(x + dx, y + dy, 2, 1), _col(pc[3]))
			if room.tile(c - 1, r) != World.T_VOID:
				ci.draw_rect(Rect2(x, y, 1, TB.TS), _col(pc[2], 0.35))
			if room.tile(c + 1, r) != World.T_VOID:
				ci.draw_rect(Rect2(x + TB.TS - 1, y, 1, TB.TS), _col(pc[2], 0.35))
			if room.tile(c, r + 1) != World.T_VOID:
				ci.draw_rect(Rect2(x, y + TB.TS - 1, TB.TS, 1), _col(pc[2], 0.5))

## The room's centre piece (in the middle, which layouts always leave clear).
static func _piece(ci: CanvasItem, room: Room, kind: String, rng: SeedRng) -> void:
	var cx := (TB.IX0 + TB.IW / 2.0) * TB.TS
	var cy := (TB.IY0 + TB.IH / 2.0) * TB.TS
	match kind:
		"mosaic":
			for i in 24:
				var a := i * TAU / 24
				ci.draw_rect(Rect2(cx + cos(a) * 30 - 1, cy + sin(a) * 20 - 1, 3, 3), _col("#d9d0b4", 0.35))
			ci.draw_rect(Rect2(cx - 5, cy - 5, 10, 8), _col("#d9d0b4", 0.3))
			ci.draw_rect(Rect2(cx - 3, cy - 2, 2, 2), _col("#140f1c", 0.5))
			ci.draw_rect(Rect2(cx + 1, cy - 2, 2, 2), _col("#140f1c", 0.5))
		"mossring":
			for i in 40:
				var a := rng.next_f() * TAU
				var d := 22.0 + rng.next_f() * 14.0
				ci.draw_rect(Rect2(cx + cos(a) * d, cy + sin(a) * d * 0.6, 2, 2), _col("#63b84f" if i % 3 else "#b8e05a", 0.5))
		"pool", "ice":
			var w := 70.0
			var h := 28.0
			for j in int(h):
				var k := 1.0 - pow((j - h / 2) / (h / 2), 2)
				var half := w / 2 * sqrt(maxf(0.0, k))
				ci.draw_rect(Rect2(cx - half, cy - h / 2 + j, half * 2, 1), _col("#2f6f7f" if kind == "pool" else "#9fc3ee", 0.35))
			for i in 5:
				var x := cx + rng.int_range(-25, 20)
				var y := cy + rng.int_range(-8, 8)
				ci.draw_rect(Rect2(x, y, 5 if kind == "pool" else 1, 1), _col("#e8f6ff", 0.35))
				if kind == "ice":
					ci.draw_rect(Rect2(x, y, 1, 4), _col("#e8f6ff", 0.3))
		"grate":
			ci.draw_rect(Rect2(cx - 20, cy - 12, 40, 24), _col("#2b2433"))
			ci.draw_rect(Rect2(cx - 18, cy - 10, 36, 20), _col("#e8873a", 0.45))
			for i in 7:
				ci.draw_rect(Rect2(cx - 18 + i * 6, cy - 10, 2, 20), _col("#4e4a5e"))
			ci.draw_rect(Rect2(cx - 20, cy - 12, 40, 2), _col("#8b8f9c"))
			_lights.append(["glow_torch", cx, cy])
		"carpet":
			var x0 := cx - 20
			ci.draw_rect(Rect2(x0, TB.IY0 * TB.TS, 40, TB.IH * TB.TS), _col("#8a2a33", 0.85))
			ci.draw_rect(Rect2(x0 + 3, TB.IY0 * TB.TS, 2, TB.IH * TB.TS), _col("#f2c94c", 0.7))
			ci.draw_rect(Rect2(x0 + 35, TB.IY0 * TB.TS, 2, TB.IH * TB.TS), _col("#f2c94c", 0.7))
		"planks":
			for i in 3:
				ci.draw_rect(Rect2(TB.IX0 * TB.TS + 40, cy - 12 + i * 8, TB.IW * TB.TS - 80, 7), _col("#7a5236", 0.8))
				ci.draw_rect(Rect2(TB.IX0 * TB.TS + 40, cy - 12 + i * 8 + 6, TB.IW * TB.TS - 80, 1), _col("#4a3024", 0.8))
			for x in range(TB.IX0 * TB.TS + 40, TB.IX0 * TB.TS + TB.IW * TB.TS - 40, 23):
				ci.draw_rect(Rect2(x, cy - 12, 1, 23), _col("#4a3024", 0.6))
		"crater":
			for j in 3:
				var rr := 26.0 - j * 8.0
				for i in 30:
					var a := i * TAU / 30
					ci.draw_rect(Rect2(cx + cos(a) * rr, cy + sin(a) * rr * 0.6, 3, 2), Color(0, 0, 0, 0.18 + j * 0.08))
		"mat":
			ci.draw_rect(Rect2(cx - 30, cy - 18, 60, 36), _col("#d9c48a", 0.55))
			for i in range(0, 36, 4):
				ci.draw_rect(Rect2(cx - 30, cy - 18 + i, 60, 1), _col("#a08850", 0.5))
			ci.draw_rect(Rect2(cx - 30, cy - 18, 60, 2), _col("#63b84f", 0.6))
			ci.draw_rect(Rect2(cx - 30, cy + 16, 60, 2), _col("#63b84f", 0.6))
		"skylight":
			ci.draw_rect(Rect2(cx - 24, cy - 14, 48, 28), _col("#f2c94c", 0.8))
			ci.draw_rect(Rect2(cx - 22, cy - 12, 44, 24), _col("#1b2b4a"))
			ci.draw_rect(Rect2(cx - 1, cy - 12, 2, 24), _col("#f2c94c", 0.8))
			ci.draw_rect(Rect2(cx - 22, cy - 1, 44, 2), _col("#f2c94c", 0.8))
			ci.draw_rect(Rect2(cx - 18, cy - 9, 4, 1), _col("#e8f6ff", 0.6))
			ci.draw_rect(Rect2(cx + 8, cy + 4, 3, 3), _col("#e8f6ff", 0.8))
		"sigil":
			for j in 2:
				var rr := 34.0 - j * 10.0
				for i in 48:
					var a := i * TAU / 48
					ci.draw_rect(Rect2(cx + cos(a) * rr, cy + sin(a) * rr * 0.6, 1, 1), _col("#d8443c" if j == 0 else "#a35bd6", 0.6))
			for i in 6:
				var a := i * TAU / 6
				_decal(ci, "rune", cx + cos(a) * 29 - 2, cy + sin(a) * 17 - 2, rng)
			_lights.append(["glow_purple", cx, cy])

## A small mark on the floor at (x, y).
static func _decal(ci: CanvasItem, kind: String, x: float, y: float, rng: SeedRng) -> void:
	match kind:
		"crack", "icecrack", "lavacrack", "voidcrack":
			var col: Color = { "crack": Color(0, 0, 0, 0.35), "icecrack": _col("#e8f6ff", 0.45), "lavacrack": _col("#5a160e", 0.8), "voidcrack": Color(0, 0, 0, 0.6) }[kind]
			var px := x
			var py := y
			for i in 6:
				ci.draw_rect(Rect2(px, py, 1, 1), col)
				if kind == "lavacrack" and i % 2 == 0:
					ci.draw_rect(Rect2(px + 1, py, 1, 1), _col("#e8873a", 0.8))
				if kind == "voidcrack":
					ci.draw_rect(Rect2(px + 1, py, 1, 1), _col("#a35bd6", 0.5))
				px += 1
				py += rng.int_range(-1, 1)
		"bones":
			var c := _col("#d9d0b4", 0.8)
			if rng.next_f() < 0.5:
				ci.draw_rect(Rect2(x, y + 1, 5, 1), c)
				ci.draw_rect(Rect2(x - 1, y, 1, 3), c)
				ci.draw_rect(Rect2(x + 5, y, 1, 3), c)
			else:
				ci.draw_rect(Rect2(x, y, 3, 3), c)
				ci.draw_rect(Rect2(x, y + 1, 1, 1), _col("#140f1c"))
				ci.draw_rect(Rect2(x + 2, y + 1, 1, 1), _col("#140f1c"))
		"pebbles", "coal":
			for i in 3:
				ci.draw_rect(Rect2(x + rng.int_range(0, 5), y + rng.int_range(0, 4), 2, 1), _col("#4e4a5e" if kind == "pebbles" else "#14101a", 0.7))
			if kind == "coal":
				ci.draw_rect(Rect2(x + 2, y + 2, 1, 1), _col("#d8443c"))
		"cobweb":
			for i in 5:
				ci.draw_rect(Rect2(x + i, y + i, 1, 1), _col("#e8e4f0", 0.3))
				ci.draw_rect(Rect2(x + i, y, 1, 1), _col("#e8e4f0", 0.25))
				ci.draw_rect(Rect2(x, y + i, 1, 1), _col("#e8e4f0", 0.25))
		"moss":
			for i in 8:
				ci.draw_rect(Rect2(x + rng.int_range(0, 5), y + rng.int_range(0, 3), 2, 1), _col("#63b84f" if i % 2 else "#3f7a5a", 0.6))
		"grass", "weed":
			for i in 3:
				ci.draw_rect(Rect2(x + i * 2, y + (i % 2), 1, 3 - (i % 2)), _col("#b8e05a" if kind == "grass" else "#3f7a5a", 0.75))
		"puddle", "mud", "soot", "scorch", "ash", "blood", "frost", "snow":
			var col: Color = { "puddle": _col("#2f6f7f", 0.45), "mud": _col("#4a3024", 0.5), "soot": Color(0, 0, 0, 0.3), "scorch": Color(0, 0, 0, 0.4),
				"ash": _col("#8b8f9c", 0.35), "blood": _col("#8a2a33", 0.5), "frost": _col("#9fc3ee", 0.35), "snow": _col("#ffffff", 0.5) }[kind]
			var w := rng.int_range(5, 9)
			ci.draw_rect(Rect2(x + 1, y, w - 2, 1), col)
			ci.draw_rect(Rect2(x, y + 1, w, 2), col)
			ci.draw_rect(Rect2(x + 1, y + 3, w - 2, 1), col)
			if kind == "puddle":
				ci.draw_rect(Rect2(x + 2, y + 1, 2, 1), _col("#6fd3e0", 0.5))
			elif kind == "blood":
				ci.draw_rect(Rect2(x + w + 1, y + 2, 1, 1), col)
		"shroomlets":
			for i in 2:
				ci.draw_rect(Rect2(x + i * 4, y + 1, 1, 2), _col("#f4ecd8", 0.8))
				ci.draw_rect(Rect2(x + i * 4 - 1, y, 3, 1), _col("#6fd3e0", 0.8))
		"pages", "feather":
			ci.draw_rect(Rect2(x, y, 3, 2), _col("#f4ecd8", 0.7))
			ci.draw_rect(Rect2(x, y + 1, 3, 1), _col("#8b8f9c", 0.5))
			if kind == "pages":
				ci.draw_rect(Rect2(x + 4, y + 2, 3, 2), _col("#e8e4d0", 0.6))
		"plate":
			ci.draw_rect(Rect2(x, y, 6, 6), _col("#4e4a5e", 0.6))
			for d in [Vector2(0, 0), Vector2(5, 0), Vector2(0, 5), Vector2(5, 5)]:
				ci.draw_rect(Rect2(x + d.x, y + d.y, 1, 1), _col("#8b8f9c", 0.8))
		"sparkle", "goldbits", "wax", "petals":
			var col: Color = { "sparkle": _col("#ffffff", 0.7), "goldbits": _col("#f2c94c", 0.8), "wax": _col("#f4ecd8", 0.7), "petals": _col("#e86fb4", 0.6) }[kind]
			for i in 2 + rng.int_range(0, 2):
				ci.draw_rect(Rect2(x + rng.int_range(0, 6), y + rng.int_range(0, 4), 1, 1), col)
		"marble":
			var px := x
			var py := y
			for i in 9:
				ci.draw_rect(Rect2(px, py, 1, 1), _col("#e8e4f0", 0.18))
				px += 1
				py += 1 if i % 3 == 0 else 0
		"leaves":
			for i in 3:
				ci.draw_rect(Rect2(x + rng.int_range(0, 6), y + rng.int_range(0, 4), 2, 1), _col(["#e8873a", "#f2c94c", "#7a5236"][i], 0.7))
		"arrows":
			for i in 5:
				ci.draw_rect(Rect2(x + i, y + i / 2, 1, 1), _col("#7a5236", 0.8))
			ci.draw_rect(Rect2(x, y - 1, 1, 2), _col("#f4ecd8", 0.7))
		"seam":
			ci.draw_rect(Rect2(floorf(x / TB.TS) * TB.TS, floorf(y / TB.TS) * TB.TS, TB.TS, 1), Color(0, 0, 0, 0.2))
		"shingle":
			for i in 3:
				ci.draw_rect(Rect2(x + i * 4, y + 2, 4, 1), Color(0, 0, 0, 0.25))
				ci.draw_rect(Rect2(x + i * 4, y, 1, 2), Color(0, 0, 0, 0.2))
		"rune":
			var col := _col("#a35bd6" if rng.next_f() < 0.5 else "#d8443c", 0.6)
			var pats := [[0, 2, 4, 6, 8], [1, 3, 4, 5, 7], [0, 1, 2, 4, 7], [2, 4, 6, 7, 8]]
			var pat: Array = pats[rng.int_range(0, 3)]
			for k: int in pat:
				ci.draw_rect(Rect2(x + (k % 3) * 2, y + (k / 3) * 2, 2, 2), col)
