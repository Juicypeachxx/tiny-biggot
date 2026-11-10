class_name JapanLook
extends RefCounted
## V2 (his reference video, 10 Nov: "the whole game maps and arenas and stages needs to capture
## reference japanese vibe"): a floor drawn as a Japanese garden instead of gridded tiles. The
## first one is the koi pond of his video, on the Mirewood Grotto: soft water with no grid, lily
## pads and lotus, koi with ripples, shafts of light, a tiled roof for the top wall and garden
## stones for the banks. Drawing only, with its own random numbers (the room's seed for what is
## fixed, its own generator for what moves): no rule changes, every replay stays identical.
## The pictures (jp_*.png) are drawn by tools/art/japan_look.py.

## Per floor index: the look's colours, and what replaces BiomeDeco's props and air.
const STYLES := {
	1: { "base": "#33648f", "light": "#7ab2d6", "dark": "#1b3a68", "edge": "#0f2148", "deep": "#1a3566", "rim": "#6fa6cc",
		"props": ["prop_stonelantern", "prop_mossrock", "prop_mossrock", "prop_stump"], "air": "glints" },
}
const KOI := [["#eee8f0", "#e8873a"], ["#e8873a", "#eee8f0"], ["#eee8f0", "#eee8f0"], ["#e39a9a", "#eee8f0"], ["#eee8f0", "#c8443c"], ["#f2c94c", "#e8873a"]]

static var live := false          # the room on screen has this look
static var _koi: Array = []       # { x, y, a, sp, ph, col, lead, ox, oy }
static var _rings: Array = []     # { x, y, t, life }
static var _next_ring := 0.0
static var _room: WeakRef = null
static var _rng := RandomNumberGenerator.new()

static func on(room: Room) -> bool:
	return BiomeDeco.on(room) and STYLES.has(G.floor_index)

static func style() -> Dictionary:
	return STYLES[G.floor_index]

## BiomeDeco's floor entry with this look's props and air.
static func biome(b: Dictionary) -> Dictionary:
	var out := b.duplicate()
	out["props"] = style()["props"]
	out["air"] = style()["air"]
	return out

static func _col(hex: String, a: float = 1.0) -> Color:
	var c := TB.c(hex)
	c.a = a
	return c

## A screen-sized picture drawn shifted, wrapping round.
static func _wrapped(ci: CanvasItem, name: String, ox: int, oy: int, tint: Color) -> void:
	var tex := Img.t(name)
	for j in 2:
		for i in 2:
			ci.draw_texture(tex, Vector2(ox - TB.SW * i, oy - TB.SH * j), tint)

# ---------- the room background (drawn once per room) ----------
static func paint_ground(ci: CanvasItem, room: Room) -> void:
	var s := style()
	var ts := TB.TS
	var rng := SeedRng.new(room.seed_value ^ 0x6a09e667)
	ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), _col(s["base"]))
	_wrapped(ci, "jp_mottle", rng.int_range(0, TB.SW - 1), rng.int_range(0, TB.SH - 1), _col(s["light"], 0.75))
	_wrapped(ci, "jp_mottle", rng.int_range(0, TB.SW - 1), rng.int_range(0, TB.SH - 1), _col(s["dark"], 0.7))
	ci.draw_texture(Img.t("jp_vignette"), Vector2.ZERO, _col(s["edge"]))
	# Deep pools where the room has pits.
	for r in range(TB.IY0, TB.IY0 + TB.IH):
		for c in range(TB.IX0, TB.IX0 + TB.IW):
			if room.tile(c, r) != World.T_VOID:
				continue
			ci.draw_rect(Rect2(c * ts, r * ts, ts, ts), _col(s["deep"], 0.85))
			if room.tile(c, r - 1) != World.T_VOID:
				ci.draw_rect(Rect2(c * ts, r * ts, ts, 1), _col(s["rim"], 0.7))
			if room.tile(c - 1, r) != World.T_VOID:
				ci.draw_rect(Rect2(c * ts, r * ts, 1, ts), _col(s["rim"], 0.35))
			if room.tile(c + 1, r) != World.T_VOID:
				ci.draw_rect(Rect2(c * ts + ts - 1, r * ts, 1, ts), _col(s["rim"], 0.35))
			if room.tile(c, r + 1) != World.T_VOID:
				ci.draw_rect(Rect2(c * ts, r * ts + ts - 1, ts, 1), _col(s["rim"], 0.5))
	# Glints on the water.
	for i in 40:
		var x := rng.int_range(ts + 2, TB.SW - ts - 6)
		var y := rng.int_range(TB.IY0 * ts + 4, 17 * ts - 3)
		ci.draw_rect(Rect2(x, y, rng.int_range(2, 4), 1), _col("#9cc8e8", 0.22))
	# Drifts of small leaves.
	var start := room.type == "start"
	for i in 12 + rng.int_range(0, 4):
		var cx := rng.int_range(2 * ts, TB.SW - 2 * ts)
		var cy := rng.int_range(TB.IY0 * ts + 10, 17 * ts - 10)
		var rx := rng.int_range(10, 26)
		var ry := rng.int_range(5, 11)
		for j in rx * ry / 5:
			var a := rng.next_f() * TAU
			var d := sqrt(rng.next_f())
			var x := cx + int(cos(a) * d * rx)
			var y := cy + int(sin(a) * d * ry)
			if room.tile(x / ts, y / ts) != World.T_FLOOR or room.tile((x + 2) / ts, (y + 2) / ts) != World.T_FLOOR or (start and y >= 6 * ts and y < 10 * ts):
				continue
			ci.draw_rect(Rect2(x, y + 1, 3, 2), _col("#12284a", 0.55))
			ci.draw_rect(Rect2(x, y, 3, 2), _col(["#5ea646", "#7cc04e", "#4c9440"][rng.int_range(0, 2)]))
			ci.draw_rect(Rect2(x + rng.int_range(0, 1), y, 1, 1), _col("#a8dc66"))
	# Lily pads and lotus.
	var pads := Img.t("jp_pads")
	for i in 16 + rng.int_range(0, 6):
		var x := rng.int_range(ts + 2, TB.SW - ts - 14)
		var y := rng.int_range(TB.IY0 * ts + 6, 17 * ts - 14)
		var k: int = [0, 1, 2, 3, 4, 5, 5, 0, 1][rng.int_range(0, 8)]
		if room.tile((x + 6) / ts, (y + 6) / ts) != World.T_FLOOR or (start and y >= 6 * ts - 8 and y < 10 * ts):
			continue
		ci.draw_texture_rect_region(pads, Rect2(x, y, 12, 12), Rect2(k * 12, 0, 12, 12))
	# The banks (garden stones) and the roof along the top.
	var bank := Img.t("jp_bank")
	for c in TB.COLS:
		ci.draw_texture_rect_region(bank, Rect2(c * ts, 17 * ts, ts, ts), Rect2(rng.int_range(0, 3) * ts, 0, ts, ts))
	for r in range(TB.IY0, TB.ROWS - 1):
		ci.draw_texture_rect_region(bank, Rect2(0, r * ts, ts, ts), Rect2(rng.int_range(0, 3) * ts, 0, ts, ts))
		ci.draw_texture_rect_region(bank, Rect2(27 * ts, r * ts, ts, ts), Rect2(rng.int_range(0, 3) * ts, 0, ts, ts))
	for edge in [Rect2(ts, 17 * ts - 1, TB.IW * ts, 1), Rect2(ts, TB.IY0 * ts, 1, TB.IH * ts), Rect2(27 * ts - 1, TB.IY0 * ts, 1, TB.IH * ts)]:
		ci.draw_rect(edge, _col("#9cc8e8", 0.3))   # the water's edge against the stones
	var roof := Img.t("jp_roof")
	for i in 7:
		ci.draw_texture(roof, Vector2(i * 64, 0))
	ci.draw_rect(Rect2(0, 2 * ts, TB.SW, 3), _col("#0a1430", 0.55))   # the eave's shadow on the water
	ci.draw_rect(Rect2(0, 2 * ts + 3, TB.SW, 3), _col("#0a1430", 0.25))

# ---------- every frame ----------
static func _reset(room: Room) -> void:
	_room = weakref(room)
	_koi.clear()
	_rings.clear()
	for sch in 3:
		var lx := _rng.randf_range(60, TB.SW - 60)
		var ly := _rng.randf_range(70, TB.SH - 50)
		var a := _rng.randf() * TAU
		var lead := _koi.size()
		for i in _rng.randi_range(2, 4):
			_koi.append({ "x": lx - i * 7.0, "y": ly + i * 3.0, "a": a, "sp": _rng.randf_range(11, 17), "ph": _rng.randf() * TAU,
				"col": KOI[_rng.randi_range(0, KOI.size() - 1)], "lead": -1 if i == 0 else lead,
				"ox": -i * _rng.randf_range(5, 8), "oy": _rng.randf_range(-7, 7) })

## Moves the koi and the rings (once per logic tick).
static func tick(dt: float) -> void:
	var room := G.room
	if _room == null or _room.get_ref() != room:
		_reset(room)
	var t := G.time
	for k in _koi:
		var want: float = k["a"]
		var sp: float = k["sp"]
		if k["lead"] < 0:
			want += sin(t * 0.5 + k["ph"]) * 0.9 * dt
			if k["x"] < 44 or k["x"] > TB.SW - 44 or k["y"] < 60 or k["y"] > TB.SH - 40:
				want = Vector2(TB.SW * 0.5 - k["x"], TB.SH * 0.5 + 10 - k["y"]).angle()
		else:
			var l: Dictionary = _koi[k["lead"]]
			var tgt := Vector2(l["x"], l["y"]) + Vector2(k["ox"], k["oy"]).rotated(l["a"])
			var to := tgt - Vector2(k["x"], k["y"])
			if to.length() > 3.0:
				want = to.angle()
			sp *= clampf(to.length() / 10.0, 0.5, 1.6)
		k["a"] = rotate_toward(k["a"], want, 1.4 * dt)
		k["x"] += cos(k["a"]) * sp * dt
		k["y"] += sin(k["a"]) * sp * dt
	for r in _rings:
		r["t"] += dt
	_rings = _rings.filter(func(r): return r["t"] < r["life"])
	_next_ring -= dt
	if _next_ring <= 0.0 and _rings.size() < 6:
		_next_ring = _rng.randf_range(0.4, 1.1)
		var x := _rng.randf_range(24, TB.SW - 24)
		var y := _rng.randf_range(48, TB.SH - 28)
		if not _koi.is_empty() and _rng.randf() < 0.4:
			var k: Dictionary = _koi[_rng.randi_range(0, _koi.size() - 1)]
			x = k["x"]
			y = k["y"]
		_rings.append({ "x": x, "y": y, "t": 0.0, "life": _rng.randf_range(1.6, 2.6) })

## Koi and rings, over the floor and under everything that stands on it.
static func paint_lower(ci: CanvasItem, t: float) -> void:
	var room := G.room
	for r in _rings:
		var k: float = r["t"] / r["life"]
		var c := Vector2(roundf(r["x"]), roundf(r["y"]))
		ci.draw_arc(c, 2.0 + k * 8.0, 0, TAU, 14, _col("#cfe6f5", 0.45 * (1.0 - k)), 1.0)
		if k > 0.3:
			ci.draw_arc(c, 1.0 + (k - 0.3) * 6.0, 0, TAU, 10, _col("#cfe6f5", 0.3 * (1.0 - k)), 1.0)
	for k in _koi:
		var tile := room.tile(int(k["x"]) / TB.TS, int(k["y"]) / TB.TS)
		if tile != World.T_FLOOR and tile != World.T_VOID:
			continue   # under a rock or a lantern
		var p := Vector2(k["x"], k["y"])
		var d := Vector2.from_angle(k["a"])
		var side := d.orthogonal() * sin(t * 7.0 + k["ph"])
		for i in 2:
			var w := p - d * (9.0 + i * 5.0)
			ci.draw_rect(Rect2(roundf(w.x), roundf(w.y), 2, 1), _col("#9cc8e8", 0.22 - i * 0.08))
		var col: Array = k["col"]
		var tail := p - d * 5.0 + side * 1.5
		ci.draw_rect(Rect2(roundf(tail.x), roundf(tail.y), 2, 2), _col(col[0], 0.6))
		var mid := p - d * 3.0 + side * 0.6
		ci.draw_rect(Rect2(roundf(mid.x), roundf(mid.y), 2, 2), _col(col[1], 0.9))
		var body := p - d * 1.5
		ci.draw_rect(Rect2(roundf(body.x) - 0.0, roundf(body.y), 3, 3), _col(col[0], 0.95))
		ci.draw_rect(Rect2(roundf(p.x), roundf(p.y), 2, 2), _col(col[0], 0.95))

## The shafts of light (the additive layer).
static func paint_glow(ci: CanvasItem, t: float) -> void:
	ci.draw_texture(Img.t("jp_shafts"), Vector2(roundf(sin(t * 0.11) * 12.0), 0), Color(0.45, 0.68, 0.85, 0.55 + 0.1 * sin(t * 0.45)))
