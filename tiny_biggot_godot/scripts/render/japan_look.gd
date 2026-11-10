class_name JapanLook
extends RefCounted
## V2, THE KOI GARDEN (his reference video, 10 Nov; his word after the first sample: "what about
## the building in the middle and all the props ... make environments live and nice"): a place
## drawn as a Japanese koi pond instead of gridded tiles. Soft water with no grid, drifts of
## leaves, lily pads and lotus, a tiled roof for the top wall and garden stones for the banks;
## the gate of his video standing in the water (you walk under its roof, which fades while
## someone is under it), a red bridge, garden props where pillars stand; and life: koi that flee
## from the hero, frogs that jump off their pads, dragonflies, petals, rings where the hero wades.
## Drawing only, with its own random numbers (the room's seed for what is fixed, its own
## generator for what moves): no rule changes, every replay stays identical.
## Pictures: jp_* by tools/art/japan_look.py; koi_* are SpriteCook's (resprite/tools/koi_cut.py).
## Until the garden is a floor of its own (the next step), it is shown with the test option --koi
## on whatever floor is played.

const STYLE := { "base": "#33648f", "light": "#7ab2d6", "dark": "#1b3a68", "edge": "#0f2148", "deep": "#1a3566", "rim": "#6fa6cc",
	"props": ["koi_lantern", "koi_bamboo", "koi_stones", "koi_postlamp", "koi_bonsai", "koi_basin", "koi_bamboo", "koi_shrine", "koi_torii"], "air": "glints" }
const KOI := [["#f4eef2", "#f08a2c"], ["#f08a2c", "#f4eef2"], ["#f4eef2", "#f4eef2"], ["#ef9a9a", "#f4eef2"], ["#f4eef2", "#d8443c"], ["#f6cf52", "#f08a2c"], ["#2c2a38", "#f08a2c"]]

static var live := false          # the room on screen has this look
static var _koi: Array = []       # { x, y, a, sp, ph, col, lead, ox, oy, fear }
static var _rings: Array = []     # { x, y, t, life, r }
static var _frogs: Array = []     # { x, y, t, st (0 sits, 1 jumps, 2 gone), dx, dy }
static var _flies: Array = []     # { x, y, tx, ty, wait, col }
static var _petals: Array = []    # { x, y, ph, sp }
static var _pads: Array = []      # the big pads' middles (frogs sit on them)
static var _gate := false         # this room has the gate
static var _gate_at := Vector2.ZERO   # its picture's top left; the roof is 67 x 39, the posts stand below
static var _roof_a := 1.0
static var _next_ring := 0.0
static var _step := Vector2.ZERO  # where the hero's last ring was
static var _room: WeakRef = null
static var _rng := RandomNumberGenerator.new()

static func on(room: Room) -> bool:
	return BiomeDeco.on(room) and DebugArgs.has("koi")

static func style() -> Dictionary:
	return STYLE

## BiomeDeco's floor entry with this look's props and air.
static func biome(b: Dictionary) -> Dictionary:
	var out := b.duplicate()
	out["props"] = STYLE["props"]
	out["air"] = STYLE["air"]
	return out

## Where the scene's gate stands (the top left of its picture), from its first post; no gate: false.
static func find_gate(room: Room) -> bool:
	for r in range(TB.IY0, TB.IY0 + TB.IH):
		for c in range(TB.IX0, TB.IX0 + TB.IW):
			if KoiScenes.cell(room, c, r) == "X":
				_gate_at = Vector2(c * TB.TS - 4, (r + 1) * TB.TS + 1 - 65)
				return true
	return false

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
	var s := STYLE
	var ts := TB.TS
	var rng := SeedRng.new(room.seed_value ^ 0x6a09e667)
	ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), _col(s["base"]))
	_wrapped(ci, "jp_mottle", rng.int_range(0, TB.SW - 1), rng.int_range(0, TB.SH - 1), _col(s["light"], 0.75))
	_wrapped(ci, "jp_mottle", rng.int_range(0, TB.SW - 1), rng.int_range(0, TB.SH - 1), _col(s["dark"], 0.7))
	ci.draw_texture(Img.t("jp_vignette"), Vector2.ZERO, _col(s["edge"]))
	# Deep pools where the room has pits: rounded where they turn a corner, a pale rim, darker within.
	for r in range(TB.IY0, TB.IY0 + TB.IH):
		for c in range(TB.IX0, TB.IX0 + TB.IW):
			if room.tile(c, r) != World.T_VOID:
				continue
			var up := room.tile(c, r - 1) == World.T_VOID
			var dn := room.tile(c, r + 1) == World.T_VOID
			var lf := room.tile(c - 1, r) == World.T_VOID
			var rt := room.tile(c + 1, r) == World.T_VOID
			for i in ts * 2:     # half a pixel a row
				var y := i * 0.5
				var x0 := 0.0
				var x1 := float(ts)
				var from_top := y if not up else 99.0
				var from_bot := ts - 0.5 - y if not dn else 99.0
				if not lf:
					x0 = maxf(_round_in(from_top), _round_in(from_bot))
				if not rt:
					x1 = ts - maxf(_round_in(from_top), _round_in(from_bot))
				ci.draw_rect(Rect2(c * ts + x0, r * ts + y, x1 - x0, 0.5), _col(s["deep"], 0.8))
				if x0 > 0.0 or not lf:
					ci.draw_rect(Rect2(c * ts + x0, r * ts + y, 0.5, 0.5), _col(s["rim"], 0.55))
				if x1 < ts or not rt:
					ci.draw_rect(Rect2(c * ts + x1 - 0.5, r * ts + y, 0.5, 0.5), _col(s["rim"], 0.55))
			if not up:
				ci.draw_rect(Rect2(c * ts + (0.0 if lf else 6.0), r * ts, ts - (0.0 if lf else 6.0) - (0.0 if rt else 6.0), 0.5), _col(s["rim"], 0.7))
				ci.draw_rect(Rect2(c * ts + (0.0 if lf else 4.0), r * ts + 0.5, ts - (0.0 if lf else 4.0) - (0.0 if rt else 4.0), 2.5), _col("#0a1838", 0.35))   # the far side, in shade
			if not dn:
				ci.draw_rect(Rect2(c * ts + (0.0 if lf else 6.0), r * ts + ts - 0.5, ts - (0.0 if lf else 6.0) - (0.0 if rt else 6.0), 0.5), _col(s["rim"], 0.55))
			if up and dn and lf and rt and rng.next_f() < 0.25:     # darker still in the middle
				ci.draw_rect(Rect2(c * ts + rng.int_range(0, 6), r * ts + rng.int_range(2, 12), rng.int_range(6, 10), 0.5), _col("#0a1838", 0.35))
	# Glints on the water.
	for i in 40:
		var x := rng.int_range(ts + 2, TB.SW - ts - 6)
		var y := rng.int_range(TB.IY0 * ts + 4, 17 * ts - 3)
		ci.draw_rect(Rect2(x, y, rng.int_range(2, 4), 0.5), _col("#b4d8f0", 0.3))
	# Plants gather where the water is still: along the banks, round what stands in the water,
	# and in the scene's lily colonies. The open water between stays clear.
	_pads.clear()
	var scene := KoiScenes.is_scene(room)
	for i in 16:
		var along := rng.next_f()
		var off := rng.int_range(4, 13)
		var ln := rng.int_range(14, 30)
		match rng.int_range(0, 4):
			0: _drift(ci, room, rng, ts + off, lerpf(3 * ts, 16 * ts, along), 6, ln, 0.5)
			1: _drift(ci, room, rng, TB.SW - ts - off, lerpf(3 * ts, 16 * ts, along), 6, ln, 0.5)
			2, 3: _drift(ci, room, rng, lerpf(2 * ts, TB.SW - 2 * ts, along), 17 * ts - off, ln, 5, 0.5)
			_: _drift(ci, room, rng, lerpf(2 * ts, TB.SW - 2 * ts, along), 2 * ts + 4 + off, ln, 5, 0.4)
	var colonies: Array = []
	for r in range(TB.IY0, TB.IY0 + TB.IH):
		for c in range(TB.IX0, TB.IX0 + TB.IW):
			var ch := KoiScenes.cell(room, c, r)
			if ch == "*":
				colonies.append(Vector2(c * ts + 8, r * ts + 8))
			elif room.tile(c, r) == World.T_PILLAR and rng.next_f() < 0.7:
				_drift(ci, room, rng, c * ts + 8, r * ts + 15, rng.int_range(9, 13), 4, 0.6)
				if rng.next_f() < 0.35:
					_pad(ci, room, rng, c * ts + rng.int_range(-10, 16), r * ts + rng.int_range(10, 16), [5, 5, 1])
	if not scene:     # a room with no scene (the start, the guardian's, a shop): colonies in its corners
		for q in [Vector2(5, 5), Vector2(22, 5), Vector2(5, 13), Vector2(22, 13)]:
			if rng.next_f() < 0.75:
				colonies.append(Vector2((q.x + rng.int_range(-1, 1)) * ts, (q.y + rng.int_range(-1, 1)) * ts))
	for m in colonies:
		_drift(ci, room, rng, m.x, m.y, rng.int_range(24, 32), rng.int_range(11, 15), 0.85)
		for i in 6 + rng.int_range(0, 3):
			var a := rng.next_f() * TAU
			var d := 0.25 + 0.75 * rng.next_f()
			_pad(ci, room, rng, m.x + cos(a) * d * 26 - 6, m.y + sin(a) * d * 12 - 6, [0, 1, 0, 1, 2, 3, 3, 4, 5])
	# Stepping stones and bridges, where the scene has them.
	if scene:
		var step := Img.t("jp_step")
		var plank := Img.t("jp_plank")
		for r in range(TB.IY0, TB.IY0 + TB.IH):
			for c in range(TB.IX0, TB.IX0 + TB.IW):
				var ch := KoiScenes.cell(room, c, r)
				if ch == "o":
					ci.draw_texture_rect_region(step, Rect2(c * ts + 2, r * ts + 3, 12, 10), Rect2(((c + r) % 2) * 12, 0, 12, 10))
				elif ch == "=":
					ci.draw_texture_rect_region(plank, Rect2(c * ts, r * ts, ts, ts), Rect2(0, 3, 16, 14))
		for r in range(TB.IY0, TB.IY0 + TB.IH):
			for c in range(TB.IX0, TB.IX0 + TB.IW):
				if KoiScenes.cell(room, c, r) != "=":
					continue
				if KoiScenes.cell(room, c, r - 1) != "=":
					ci.draw_texture_rect_region(plank, Rect2(c * ts, r * ts - 3, ts, 4.5), Rect2(0, 0, 16, 4.5))
				if KoiScenes.cell(room, c, r + 1) != "=":
					ci.draw_texture_rect_region(plank, Rect2(c * ts, r * ts + 13, ts, 7), Rect2(0, 13, 16, 7))
	# The gate of his video: its posts and doors here, its roof over everything (paint_roof).
	_gate = scene and find_gate(room)
	if _gate:
		for i in 6:
			ci.draw_rect(Rect2(_gate_at.x + 2 - i, _gate_at.y + 62 + i * 0.5, 63 + 2 * i, 4), _col("#0a1838", 0.12))
		Gfx.at(ci, "koi_gate_base", _gate_at.x + 4.5, _gate_at.y + 39)
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
	for i in 20:     # darker towards its top, under the HUD
		ci.draw_rect(Rect2(0, i, TB.SW, 1), Color(0.03, 0.01, 0.05, 0.45 * (1.0 - i / 20.0)))
	ci.draw_rect(Rect2(0, 2 * ts, TB.SW, 3), _col("#0a1430", 0.55))   # the eave's shadow on the water
	ci.draw_rect(Rect2(0, 2 * ts + 3, TB.SW, 3), _col("#0a1430", 0.25))

## How far a pool's edge stands in from the tile's side, `d` pixels from a corner it rounds (radius 6).
static func _round_in(d: float) -> float:
	if d >= 6.0:
		return 0.0
	return roundf((6.0 - sqrt(36.0 - (6.0 - d) * (6.0 - d))) * 2.0) / 2.0

## A drift of small leaves round (cx, cy), rx wide and ry tall (half a pixel at a time: the
## picture's own pixels); `dens` 0-1.
static func _drift(ci: CanvasItem, room: Room, rng: SeedRng, cx: float, cy: float, rx: int, ry: int, dens: float) -> void:
	var ts := TB.TS
	var start := room.type == "start"
	for j in int(rx * ry * dens / 2.0):
		var a := rng.next_f() * TAU
		var d := sqrt(rng.next_f())
		var x := cx + roundf(cos(a) * d * rx * 2.0) / 2.0
		var y := cy + roundf(sin(a) * d * ry * 2.0) / 2.0
		var w := 1.5 + 0.5 * rng.int_range(0, 2)
		var shade := rng.int_range(0, 3)
		if room.tile(int(x) / ts, int(y) / ts) != World.T_FLOOR or room.tile(int(x + 2) / ts, int(y + 2) / ts) != World.T_FLOOR or (start and y >= 6 * ts and y < 10 * ts):
			continue
		if KoiScenes.cell(room, int(x) / ts, int(y) / ts) in ["=", "o"]:
			continue
		ci.draw_rect(Rect2(x + 0.5, y + 1.0, w, 1.0), _col("#10264a", 0.5))
		ci.draw_rect(Rect2(x, y, w, 1.5), _col(["#58a644", "#74c04c", "#479240", "#8fd058"][shade]))
		ci.draw_rect(Rect2(x + 0.5, y, 1.0, 0.5), _col("#b4e670"))
		ci.draw_rect(Rect2(x, y + 1.0, w, 0.5), _col("#2c6a34", 0.7))

## A lily pad (one of `kinds`: jp_pads' cells) with its top left at (x, y), if that is open water.
static func _pad(ci: CanvasItem, room: Room, rng: SeedRng, x: float, y: float, kinds: Array) -> void:
	var ts := TB.TS
	var k: int = kinds[rng.int_range(0, kinds.size() - 1)]
	x = roundf(x)
	y = roundf(y)
	for q in [Vector2(x + 1, y + 1), Vector2(x + 11, y + 1), Vector2(x + 1, y + 10), Vector2(x + 11, y + 10)]:
		if room.tile(int(q.x) / ts, int(q.y) / ts) != World.T_FLOOR or KoiScenes.cell(room, int(q.x) / ts, int(q.y) / ts) in ["=", "o"]:
			return
	if room.type == "start" and y >= 6 * ts - 8 and y < 10 * ts:
		return
	ci.draw_texture_rect_region(Img.t("jp_pads"), Rect2(x, y, 12, 12), Rect2(k * 12, 0, 12, 12))
	if k <= 1:
		_pads.append(Vector2(x + 6, y + 5))

# ---------- every frame ----------
static func _reset(room: Room) -> void:
	_room = weakref(room)
	_koi.clear()
	_rings.clear()
	_frogs.clear()
	_flies.clear()
	_petals.clear()
	_roof_a = 1.0
	for sch in 4:
		var lx := _rng.randf_range(60, TB.SW - 60)
		var ly := _rng.randf_range(70, TB.SH - 50)
		var a := _rng.randf() * TAU
		var lead := _koi.size()
		for i in _rng.randi_range(2, 5):
			_koi.append({ "x": lx - i * 7.0, "y": ly + i * 3.0, "a": a, "sp": _rng.randf_range(11, 17), "ph": _rng.randf() * TAU,
				"col": KOI[_rng.randi_range(0, KOI.size() - 1)], "lead": -1 if i == 0 else lead,
				"ox": -i * _rng.randf_range(5, 8), "oy": _rng.randf_range(-7, 7), "fear": 0.0 })
	var spots := _pads.duplicate()
	for i in mini(3, spots.size()):
		var p: Vector2 = spots.pop_at(_rng.randi_range(0, spots.size() - 1))
		_frogs.append({ "x": p.x, "y": p.y, "hx": p.x, "hy": p.y, "t": 0.0, "st": 0, "dx": 0.0, "dy": 0.0 })
	for i in 3:
		var x := _rng.randf_range(40, TB.SW - 40)
		var y := _rng.randf_range(60, TB.SH - 40)
		_flies.append({ "x": x, "y": y, "tx": x, "ty": y, "wait": _rng.randf_range(0.3, 1.5), "col": ["#6fd3e0", "#e8544c", "#f2c94c"][i] })
	for i in 12:
		_petals.append({ "x": _rng.randf_range(0, TB.SW), "y": _rng.randf_range(30, TB.SH), "ph": _rng.randf() * TAU, "sp": _rng.randf_range(9, 16) })

static func _ring(x: float, y: float, life: float, r: float) -> void:
	if _rings.size() < 14:
		_rings.append({ "x": x, "y": y, "t": 0.0, "life": life, "r": r })

## Moves everything that lives here (once per logic tick).
static func tick(dt: float) -> void:
	var room := G.room
	if _room == null or _room.get_ref() != room:
		_reset(room)
	var t := G.time
	var p := G.player
	var hero := Vector2(p.x, p.y) if p != null else Vector2(-999, -999)
	for k in _koi:
		var want: float = k["a"]
		var sp: float = k["sp"]
		var away := Vector2(k["x"], k["y"]) - hero
		if away.length() < 30.0:
			k["fear"] = 1.0     # the hero wades in: they dart away
			want = away.angle()
		elif k["lead"] < 0:
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
		var fear: float = k["fear"]
		k["fear"] = maxf(0.0, fear - dt * 1.2)
		k["a"] = rotate_toward(k["a"], want, (1.4 + fear * 9.0) * dt)
		sp *= 1.0 + fear * 3.5
		k["x"] = clampf(k["x"] + cos(k["a"]) * sp * dt, 20.0, TB.SW - 20.0)
		k["y"] = clampf(k["y"] + sin(k["a"]) * sp * dt, 38.0, TB.SH - 22.0)
	for f in _frogs:
		f["t"] += dt
		match f["st"]:
			0:
				if Vector2(f["x"], f["y"]).distance_to(hero) < 26.0:
					var d := (Vector2(f["x"], f["y"]) - hero).normalized()
					f["st"] = 1
					f["t"] = 0.0
					f["dx"] = d.x * 22.0
					f["dy"] = d.y * 22.0
			1:
				if f["t"] >= 0.35:     # into the water
					f["st"] = 2
					f["t"] = 0.0
					_ring(f["hx"] + f["dx"], f["hy"] + f["dy"], 1.2, 7.0)
			2:
				if f["t"] > 7.0 and Vector2(f["hx"], f["hy"]).distance_to(hero) > 60.0:
					f["st"] = 0     # back on its pad
	for d in _flies:
		d["wait"] -= dt
		if d["wait"] <= 0.0:
			d["wait"] = _rng.randf_range(0.5, 2.2)
			d["tx"] = clampf(d["x"] + _rng.randf_range(-70, 70), 30.0, TB.SW - 30.0)
			d["ty"] = clampf(d["y"] + _rng.randf_range(-45, 45), 50.0, TB.SH - 30.0)
		d["x"] = lerpf(d["x"], d["tx"], minf(1.0, dt * 6.0))
		d["y"] = lerpf(d["y"], d["ty"], minf(1.0, dt * 6.0))
	for q in _petals:
		q["y"] += q["sp"] * dt
		q["x"] += (5.0 + sin(t * 1.3 + q["ph"]) * 9.0) * dt
		if q["y"] > TB.SH - 18 or q["x"] > TB.SW - 14:
			if q["y"] <= TB.SH - 18 or _rng.randf() < 0.3:
				_ring(q["x"], q["y"], 0.9, 3.0)
			q["x"] = _rng.randf_range(-30, TB.SW - 40)
			q["y"] = 34.0
	for r in _rings:
		r["t"] += dt
	_rings = _rings.filter(func(r): return r["t"] < r["life"])
	if p != null and hero.distance_to(_step) > 11.0:     # the hero wades: a ring at their feet
		_step = hero
		_ring(hero.x, hero.y + 5.0, 0.8, 5.0)
	_next_ring -= dt
	if _next_ring <= 0.0:
		_next_ring = _rng.randf_range(0.4, 1.1)
		var x := _rng.randf_range(24, TB.SW - 24)
		var y := _rng.randf_range(48, TB.SH - 28)
		if not _koi.is_empty() and _rng.randf() < 0.4:
			var k: Dictionary = _koi[_rng.randi_range(0, _koi.size() - 1)]
			x = k["x"]
			y = k["y"]
		_ring(x, y, _rng.randf_range(1.6, 2.6), 8.0)
	# The gate's roof clears while the hero or a foe is under it.
	if _gate:
		var under := Rect2(_gate_at.x, _gate_at.y - 4, 67, 50)
		var clear := under.has_point(hero)
		if not clear:
			for e: Enemy in G.enemies:
				if under.has_point(Vector2(e.x, e.y)):
					clear = true
					break
		_roof_a = move_toward(_roof_a, 0.28 if clear else 1.0, dt * 4.0)

static func _half(v: Vector2) -> Vector2:
	return (v * 2.0).round() / 2.0

## Koi, frogs and rings, over the floor and under everything that stands on it.
static func paint_lower(ci: CanvasItem, t: float) -> void:
	var room := G.room
	for r in _rings:
		var k: float = r["t"] / r["life"]
		var c := _half(Vector2(r["x"], r["y"]))
		ci.draw_arc(c, 2.0 + k * r["r"], 0, TAU, 20, _col("#d6ecf8", 0.5 * (1.0 - k)), 0.5)
		if k > 0.3:
			ci.draw_arc(c, 1.0 + (k - 0.3) * r["r"] * 0.75, 0, TAU, 14, _col("#d6ecf8", 0.32 * (1.0 - k)), 0.5)
	for k in _koi:
		var tile := room.tile(int(k["x"]) / TB.TS, int(k["y"]) / TB.TS)
		if tile != World.T_FLOOR and tile != World.T_VOID:
			continue   # under a rock or a lantern
		var p := Vector2(k["x"], k["y"])
		var d := Vector2.from_angle(k["a"])
		var n := d.orthogonal()
		var wig: float = 7.0 + k["fear"] * 10.0
		for i in 2:
			var w := _half(p - d * (9.0 + i * 5.0))
			ci.draw_rect(Rect2(w.x, w.y, 2, 0.5), _col("#b4d8f0", 0.25 - i * 0.09))
		var col: Array = k["col"]
		# shade first, then the body from the tail forward: fan, stalk, back (the patch), shoulders, head
		var parts := [[6.5, 2.0, 0, 0.75], [5.0, 1.0, 0, 0.9], [3.5, 2.0, 1, 0.95], [2.0, 2.5, 0, 1.0], [0.5, 2.0, 1, 1.0], [-0.5, 1.5, 0, 1.0]]
		for pass_i in 2:
			for q in parts:
				var sway: float = sin(t * wig + k["ph"] - q[0] * 0.5) * q[0] * 0.22
				var c := _half(p - d * q[0] + n * sway)
				var w: float = q[1]
				if pass_i == 0:
					ci.draw_rect(Rect2(c.x - w * 0.5 + 0.5, c.y - w * 0.5 + 1.5, w, w), _col("#0a1838", 0.3))
				else:
					ci.draw_rect(Rect2(c.x - w * 0.5, c.y - w * 0.5, w, w), _col(col[q[2]], q[3]))
		var fin := _half(p - d * 2.0)
		ci.draw_rect(Rect2(fin.x + n.x * 1.5 - 0.5, fin.y + n.y * 1.5 - 0.5, 1, 1), _col(col[0], 0.7))
		ci.draw_rect(Rect2(fin.x - n.x * 1.5 - 0.5, fin.y - n.y * 1.5 - 0.5, 1, 1), _col(col[0], 0.7))
	for f in _frogs:
		if f["st"] == 2:
			continue
		var x: float = f["hx"]
		var y: float = f["hy"]
		if f["st"] == 1:
			var k: float = f["t"] / 0.35
			x += f["dx"] * k
			y += f["dy"] * k - sin(k * PI) * 9.0
		var breathe := 0.5 if f["st"] == 0 and sin(t * 2.0 + x) > 0.6 else 0.0
		ci.draw_rect(Rect2(x - 2, y - 1.5 - breathe, 4, 2.5 + breathe), _col("#3c8a3a"))
		ci.draw_rect(Rect2(x - 1.5, y - 2 - breathe, 3, 1), _col("#6cc04c"))
		ci.draw_rect(Rect2(x - 2.5, y + 0.5, 1, 1), _col("#2c6a34"))
		ci.draw_rect(Rect2(x + 1.5, y + 0.5, 1, 1), _col("#2c6a34"))
		ci.draw_rect(Rect2(x - 1.5, y - 2.5 - breathe, 1, 1), _col("#f6e27a"))
		ci.draw_rect(Rect2(x + 0.5, y - 2.5 - breathe, 1, 1), _col("#f6e27a"))
		ci.draw_rect(Rect2(x - 1, y - 2.5 - breathe, 0.5, 0.5), _col("#1a1420"))
		ci.draw_rect(Rect2(x + 1, y - 2.5 - breathe, 0.5, 0.5), _col("#1a1420"))

## Dragonflies and petals, over everything.
static func paint_air(ci: CanvasItem, t: float) -> void:
	for q in _petals:
		var x := roundf(q["x"] * 2.0) / 2.0
		var y := roundf(q["y"] * 2.0) / 2.0
		var turn := sin(t * 3.0 + q["ph"]) > 0.0
		ci.draw_rect(Rect2(x, y, 1.5 if turn else 1.0, 1.0 if turn else 1.5), _col("#f7b8c4", 0.85))
		ci.draw_rect(Rect2(x, y, 0.5, 0.5), _col("#ffe4ea", 0.9))
	for d in _flies:
		var x := roundf(d["x"] * 2.0) / 2.0
		var y := roundf(d["y"] * 2.0) / 2.0 + sin(t * 5.0 + x) * 0.5
		var right: bool = d["tx"] >= d["x"]
		ci.draw_rect(Rect2(x - 2 + (0.5 if right else 2.5), y + 5.5, 2, 0.5), _col("#0a1838", 0.25))   # its shade on the water
		var wing := 0.75 if fmod(t * 22.0, 2.0) < 1.0 else 0.35
		ci.draw_rect(Rect2(x - 0.5, y - 1.5, 1.5, 1.0), _col("#ffffff", wing))
		ci.draw_rect(Rect2(x - 0.5, y + 0.5, 1.5, 1.0), _col("#ffffff", wing * 0.8))
		ci.draw_rect(Rect2(x - 2, y, 4, 0.5), _col(d["col"]))
		ci.draw_rect(Rect2(x + (1.5 if right else -2.0), y - 0.5, 1, 1), _col("#1a1420"))

## The gate's roof, over the hero and the foes (foe shots stay above it).
static func paint_roof(ci: CanvasItem) -> void:
	if _gate:
		ci.draw_texture(Img.t("koi_gate_roof"), _gate_at, Color(1, 1, 1, _roof_a))

## The shafts of light (the additive layer).
static func paint_glow(ci: CanvasItem, t: float) -> void:
	ci.draw_texture(Img.t("jp_shafts"), Vector2(roundf(sin(t * 0.11) * 12.0), 0), Color(0.45, 0.68, 0.85, 0.55 + 0.1 * sin(t * 0.45)))
	# the water moves: soft light drifting across it
	_wrapped(ci, "jp_mottle", int(fmod(t * 7.0, TB.SW)), int(fmod(t * 3.0, TB.SH)), Color(0.35, 0.6, 0.8, 0.3))
