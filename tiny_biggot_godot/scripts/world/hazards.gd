class_name Hazards
extends RefCounted
## Biome hazards (design spec step 7). Only the new floors have a "hazard",
## so original rooms never hold any and never reach the random draws below.
## Hazards only act while foes are active, so a cleared room is safe.
##
##   bog      mire pools: slow the player, bubble into small spore rings
##   warfront burning pits that flare, plus arrow volleys (telegraphed strikes)
##   icicle   icicles fall where you stand, two at a time (telegraphed strikes)
##   vent     rooftop steam vents puff rings of scalding steam
##   rift     void rifts that spit rings, plus falling dark stars (strikes)
## A strike marks the floor for 1 s, then hurts whoever stands in it (a roll
## dodges it, like any hit) and bursts into a small ring of shots.

const STATIC := { "bog": ["pool", 3], "warfront": ["pit", 2], "vent": ["vent", 3], "rift": ["rift", 2] }
const STRIKES := { "warfront": ["ARROW VOLLEY", "bone", 1], "icicle": ["FALLING ICICLES", "ice", 2], "rift": ["FALLING STAR", "dark", 1] }
const PERIOD := { "pool": 2.6, "pit": 3.6, "vent": 3.0, "rift": 2.4 }
const SHOT := { "pool": ["spore", 6, 40.0], "pit": ["fire", 8, 60.0], "vent": ["water", 10, 55.0], "rift": ["dark", 12, 50.0] }

static func setup(room: Room, floor_index: int) -> void:
	var fdef: Dictionary = GameData.floors()[floor_index]
	if not fdef.has("hazard") or not room.type in ["combat", "elite", "challenge"]:
		return
	var kind: String = fdef["hazard"]
	room.strike = kind if STRIKES.has(kind) else ""
	room.strike_t = 2.0
	if STATIC.has(kind):
		for i in STATIC[kind][1]:
			var s := World.free_spot(room, G.player, 70, World.M_WALKER)
			room.hazards.append({ "kind": STATIC[kind][0], "x": s.x, "y": s.y, "r": 18.0 if kind == "bog" else 10.0,
				"t": 1.0 + randf() * PERIOD[STATIC[kind][0]], "puff": 0.0 })

static func in_pool(p: Player) -> bool:
	var room := G.room
	if room == null or room.hazards.is_empty():
		return false
	for h in room.hazards:
		if h["kind"] == "pool" and TB.dist_xy(p.x, p.y, h["x"], h["y"]) < h["r"]:
			return true
	return false

static func update(dt: float) -> void:
	var room := G.room
	if room == null or (room.hazards.is_empty() and room.strike == "" and room.marks.is_empty()):
		return
	var active := G.enemies_active()
	for h in room.hazards:
		h["puff"] = maxf(0.0, h["puff"] - dt)
		h["t"] -= dt
		if h["t"] <= 0:
			h["t"] = PERIOD[h["kind"]] + randf() * 0.8
			if active:
				var sh: Array = SHOT[h["kind"]]
				Combat.ering(h["x"], h["y"], sh[1], sh[2], randf() * TAU, sh[0])
				h["puff"] = 0.4
	if room.strike != "" and active:
		room.strike_t -= dt
		if room.strike_t <= 0:
			room.strike_t = 2.6 + randf() * 0.8
			var p := G.player
			for i in STRIKES[room.strike][2]:
				var off := Vector2(randf_range(-22, 22), randf_range(-16, 16)) if i > 0 or randf() < 0.5 else Vector2.ZERO
				room.marks.append({ "x": clampf(p.x + off.x, 3 * TB.TS, 25 * TB.TS), "y": clampf(p.y + off.y, 4 * TB.TS, 16 * TB.TS),
					"r": 14.0, "t": 1.0 })
	elif not active:
		room.marks.clear()
	var keep := []
	for m in room.marks:
		m["t"] -= dt
		if m["t"] > 0:
			keep.append(m)
			continue
		var p := G.player
		var st: Array = STRIKES.get(room.strike, ["", "dark", 1])
		if TB.dist_xy(p.x, p.y, m["x"], m["y"]) < m["r"]:
			Combat.hurt_player(1, st[0])
		Combat.ering(m["x"], m["y"], 8, 55, randf() * TAU, st[1])
		G.add_shake(2)
		Snd.play("boom")
	room.marks = keep

# ---------- Drawing ----------
static func draw_floor(ci: CanvasItem, t: float) -> void:
	var room := G.room
	if room == null or room.hazards.is_empty():
		return
	for h in room.hazards:
		var at := Vector2(roundf(h["x"]), roundf(h["y"]))
		var r: float = h["r"]
		var puff: float = h["puff"]
		match h["kind"]:
			"pool":
				_ellipse(ci, at, r, r * 0.55, TB.ca("#1d3a2c", 230))
				_ellipse(ci, at, r - 3, (r - 3) * 0.55, TB.ca("#2f5a3f", 200))
				var b := Vector2(cos(t * 1.3 + h["x"]) * r * 0.5, sin(t * 1.7 + h["y"]) * r * 0.25)
				ci.draw_circle(at + b, 1.5 + puff * 4, TB.ca("#63b84f", 180), true, -1.0, false)
			"pit":
				_ellipse(ci, at, r + 2, (r + 2) * 0.6, TB.ca("#2a1810", 230))
				_ellipse(ci, at, r - 1 + puff * 6, (r - 1) * 0.6, TB.ca("#e8873a", roundi(140 + 60 * sin(t * 7 + h["x"]))))
				_ellipse(ci, at, r * 0.5, r * 0.3, TB.ca("#f2c94c", 200))
			"vent":
				ci.draw_rect(Rect2(at.x - 7, at.y - 4, 14, 8), TB.c("#2a2838"))
				for i in 4:
					ci.draw_rect(Rect2(at.x - 6 + i * 4, at.y - 3, 2, 6), TB.c("#5a5770"))
				if puff > 0:
					ci.draw_circle(at + Vector2(0, -6 - (0.4 - puff) * 20), 3 + (0.4 - puff) * 14, Color(0.9, 0.95, 1, puff * 1.5), true, -1.0, false)
			"rift":
				for k in 3:
					var a0 := t * (2.0 + k) + k * 2.1
					ci.draw_arc(at, r - k * 3 + puff * 6, a0, a0 + 4.2, 16, TB.ca("#a35bd6" if k == 1 else "#d8443c", 200), 1.5, false)
				ci.draw_circle(at, 3, TB.c("#140f1c"), true, -1.0, false)

static func draw_marks(ci: CanvasItem, t: float) -> void:
	var room := G.room
	if room == null:
		return
	for m in room.marks:
		var at := Vector2(roundf(m["x"]), roundf(m["y"]))
		var k: float = 1.0 - m["t"]
		var c := TB.c("#d8443c")
		c.a = 0.35 + 0.35 * (1.0 if floori(t * 12) % 2 == 0 else 0.0)
		ci.draw_arc(at, m["r"], 0, TAU, 24, c, 1.0, false)
		ci.draw_arc(at, m["r"] * k, 0, TAU, 20, Color(c.r, c.g, c.b, 0.8), 1.0, false)
		ci.draw_line(at - Vector2(3, 0), at + Vector2(3, 0), c, 1.0)
		ci.draw_line(at - Vector2(0, 3), at + Vector2(0, 3), c, 1.0)

static func _ellipse(ci: CanvasItem, at: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := float(i) / 20 * TAU
		pts.append(at + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)
