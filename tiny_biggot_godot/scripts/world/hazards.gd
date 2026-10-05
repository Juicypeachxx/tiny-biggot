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
##   gusts    Skyreach Isles: a band across the room is marked for 1 s (arrows show the way), then
##            the wind blows along it for 1.4 s, shoving you and the foes and carrying debris
## A strike marks the floor for 1 s, then hurts whoever stands in it (a roll
## dodges it, like any hit) and bursts into a small ring of shots.

const STATIC := { "bog": ["pool", 3], "warfront": ["pit", 2], "vent": ["vent", 3], "rift": ["rift", 2],
	# Rift worlds: the same kinds of hazard under their own names.
	"pylons": ["vent", 3], "barrels": ["pit", 2], "kitchen": ["pit", 2], "bloodrain": ["pit", 1], "ash": ["rift", 1] }
const STRIKES := { "warfront": ["ARROW VOLLEY", "bone", 1], "icicle": ["FALLING ICICLES", "ice", 2], "rift": ["FALLING STAR", "dark", 1],
	"spikes": ["A SPIKE TRAP", "bone", 2], "bloodrain": ["BLOOD RAIN", "dark", 2], "dynamite": ["DYNAMITE", "fire", 1],
	"ash": ["FALLING ASH", "dark", 1] }
## Heist City traffic: a lane is marked for a second, then a car tears across
## it. It runs over whoever is in the lane, foes included.
const CAR_SPEED := 360.0
const LANES := [72.0, 112.0, 152.0, 192.0, 232.0]
const PERIOD := { "pool": 2.6, "pit": 3.6, "vent": 3.0, "rift": 2.4 }
const SHOT := { "pool": ["spore", 6, 40.0], "pit": ["fire", 8, 60.0], "vent": ["water", 10, 55.0], "rift": ["dark", 12, 50.0] }

static func setup(room: Room, floor_index: int) -> void:
	var fdef: Dictionary = GameData.floors()[floor_index]
	# A rift world brings its own hazard in place of the floor's.
	var kind: String = fdef.get("hazard", "") if room.theme.is_empty() else room.theme.get("hazard", "")
	if kind == "" or not room.type in ["combat", "elite", "challenge"]:
		return
	if kind == "traffic" or kind == "gusts":
		room.strike_t = 2.0
		return
	if kind == "tide" or kind == "turrets":
		RiftExtras.hazard_setup(room, kind)
		return
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
	if room == null:
		return
	if room.theme.get("hazard", "") == "traffic" or not room.cars.is_empty():
		_update_traffic(room, dt)
	if room.theme.get("hazard", "") == "gusts" or not room.gusts.is_empty():
		_update_gusts(room, dt)
	if room.theme.get("layouts", "") == "isles":
		_off_the_edge(room)
	if not room.tides.is_empty() or not room.turrets.is_empty() or room.theme.get("hazard", "") == "tide":
		RiftExtras.update(room, dt)
	EnemyAI2.tick(room, dt)
	RiftBosses.tick(room, dt)
	Arsenal.tick(room, dt)
	if room.hazards.is_empty() and room.strike == "" and room.marks.is_empty():
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
		var st: Array = STRIKES.get(room.strike, ["A CHAMPION'S STRIKE", "dark", 1])
		if TB.dist_xy(p.x, p.y, m["x"], m["y"]) < m["r"]:
			Combat.hurt_player(1, st[0])
		Combat.ering(m["x"], m["y"], 8, 55, randf() * TAU, st[1])
		G.add_shake(2)
		Snd.play("boom")
	room.marks = keep

static func _update_traffic(room: Room, dt: float) -> void:
	var p := G.player
	var active := G.enemies_active()
	if active and room.theme.get("hazard", "") == "traffic":
		room.strike_t -= dt
		if room.strike_t <= 0:
			room.strike_t = 3.0 + randf() * 1.2
			var lane: float = LANES[randi() % LANES.size()]
			if randf() < 0.6:
				# Usually the lane you are standing in.
				for ly in LANES:
					if absf(ly - p.y) < absf(lane - p.y):
						lane = ly
			var dir := 1 if randf() < 0.5 else -1
			room.cars.append({ "y": lane, "t": 1.0, "x": -24.0 if dir > 0 else TB.SW + 24.0, "dir": dir, "hit": {} })
	var keep := []
	for car in room.cars:
		if car["t"] > 0:
			car["t"] -= dt
			if not active:
				continue   # the fight ended while it was still only a warning
			if car["t"] <= 0:
				Snd.play("charge")
			keep.append(car)
			continue
		car["x"] += car["dir"] * CAR_SPEED * dt
		if car["x"] < -40 or car["x"] > TB.SW + 40:
			continue
		keep.append(car)
		if absf(p.y - car["y"]) < 10 and absf(p.x - car["x"]) < 14:
			Combat.hurt_player(1, "a getaway car")
		for e in G.enemies.duplicate():
			if not e.targetable() or car["hit"].has(e.uid):
				continue
			if absf(e.y - car["y"]) < 9 + e.r and absf(e.x - car["x"]) < 13 + e.r:
				car["hit"][e.uid] = true
				Combat.damage_enemy(e, 16.0 * Combat.floor_scale(), { "no_crit": true, "no_mult": true, "col": "orange",
					"kx": car["dir"] * 220.0, "ky": 0.0 })
	room.cars = keep

const GUST_PUSH := 150.0   # px/s along the band
const GUST_HALF := 18.0    # half the band's width
const GUST_WARN := 1.0
const GUST_BLOW := 1.4

static func _update_gusts(room: Room, dt: float) -> void:
	var p := G.player
	var active := G.enemies_active()
	if active and room.theme.get("hazard", "") == "gusts" and room.type != "boss":   # a guardian calls its own
		room.strike_t -= dt
		if room.strike_t <= 0:
			room.strike_t = 3.4 + randf() * 1.2
			var horiz := randf() < 0.5
			var near := randf() < 0.6   # usually where you stand
			var pos: float
			if horiz:
				pos = clampf(p.y if near else randf_range(4 * TB.TS, 16 * TB.TS), 4 * TB.TS, 16 * TB.TS)
			else:
				pos = clampf(p.x if near else randf_range(3 * TB.TS, 25 * TB.TS), 3 * TB.TS, 25 * TB.TS)
			room.gusts.append({ "horiz": horiz, "pos": pos, "dir": 1 if randf() < 0.5 else -1, "t": GUST_WARN,
				"blow": GUST_BLOW, "spawn": 0.0 })
	var keep := []
	for g in room.gusts:
		if g["t"] > 0:
			g["t"] -= dt
			if active:
				keep.append(g)   # a warning whose fight ended just fades
			continue
		g["blow"] -= dt
		if g["blow"] <= 0:
			continue
		keep.append(g)
		var step: float = g["dir"] * GUST_PUSH * dt
		if _in_band(g, p.x, p.y):
			World.move_body(room, p, step if g["horiz"] else 0.0, 0.0 if g["horiz"] else step, World.M_PLAYER)
		for e in G.enemies:
			if e.targetable() and not e.is_boss() and not e.d.get("champion", false) and _in_band(g, e.x, e.y):
				World.move_body(room, e, step if g["horiz"] else 0.0, 0.0 if g["horiz"] else step,
					World.M_FLYER if e.d.get("fly", false) else World.M_WALKER)
		if not active:
			continue
		g["spawn"] -= dt
		if g["spawn"] <= 0:
			g["spawn"] = 0.22
			var off := randf_range(-GUST_HALF + 4, GUST_HALF - 4)
			if g["horiz"]:
				var x0 := TB.TS + 4.0 if g["dir"] > 0 else TB.SW - TB.TS - 4.0
				Combat.eshot(x0, g["pos"] + off, 0.0 if g["dir"] > 0 else PI, 170.0, "ice", 2.5)
			else:
				var y0 := 3.0 * TB.TS + 4.0 if g["dir"] > 0 else 17.0 * TB.TS - 4.0
				Combat.eshot(g["pos"] + off, y0, PI / 2 if g["dir"] > 0 else -PI / 2, 170.0, "ice", 2.5)
	room.gusts = keep

static func _in_band(g: Dictionary, x: float, y: float) -> bool:
	return absf((y if g["horiz"] else x) - g["pos"]) < GUST_HALF

## Nothing should ever leave the hero standing on open sky (a dash, a blink): step back onto the
## nearest island floor.
static func _off_the_edge(room: Room) -> void:
	var p := G.player
	if p == null:
		return
	var c := floori(p.x / TB.TS)
	var r := floori(p.y / TB.TS)
	if room.tile(c, r) != World.T_VOID:
		return
	for d in range(1, 6):
		for dr in range(-d, d + 1):
			for dc in range(-d, d + 1):
				if maxi(absi(dr), absi(dc)) != d:
					continue
				var x := (c + dc) * TB.TS + 8.0
				var y := (r + dr) * TB.TS + 8.0
				if room.tile(c + dc, r + dr) == World.T_FLOOR and not World.hits_solid(room, x, y, p.r, World.M_PLAYER):
					p.x = x
					p.y = y
					return

## Gust warnings (a pale band with arrows) and the wind itself (streaks blowing along the band).
static func draw_gusts(ci: CanvasItem, t: float) -> void:
	var room := G.room
	if room == null or room.gusts.is_empty():
		return
	for g in room.gusts:
		var horiz: bool = g["horiz"]
		var pos: float = g["pos"]
		var band := Rect2(TB.TS, pos - GUST_HALF, TB.SW - 2 * TB.TS, GUST_HALF * 2) if horiz \
			else Rect2(pos - GUST_HALF, 3 * TB.TS, GUST_HALF * 2, 14 * TB.TS)
		if g["t"] > 0:
			var a := 0.2 + (0.14 if floori(t * 10) % 2 == 0 else 0.0)
			ci.draw_rect(band, Color(0.3, 0.6, 0.9, a))
			var edge := Color(0.17, 0.31, 0.54, 0.85)
			if horiz:
				ci.draw_rect(Rect2(band.position.x, band.position.y, band.size.x, 1), edge)
				ci.draw_rect(Rect2(band.position.x, band.end.y - 1, band.size.x, 1), edge)
			else:
				ci.draw_rect(Rect2(band.position.x, band.position.y, 1, band.size.y), edge)
				ci.draw_rect(Rect2(band.end.x - 1, band.position.y, 1, band.size.y), edge)
			var k := 20.0
			while k < (TB.SW if horiz else 14 * TB.TS) - 20:
				var along: float = k if g["dir"] > 0 else (TB.SW if horiz else 14 * TB.TS) - k
				for s in 2:
					var o: float = float(s) * 3.0 * g["dir"]
					if horiz:
						ci.draw_rect(Rect2(roundf(along + o), pos - 3 + s, 2, 6 - 2 * s), Color(0.17, 0.31, 0.54, 0.9))
					else:
						ci.draw_rect(Rect2(pos - 3 + s, roundf(3 * TB.TS + along + o), 6 - 2 * s, 2), Color(0.17, 0.31, 0.54, 0.9))
				k += 26.0
		else:
			var life: float = g["blow"] / GUST_BLOW
			for i in 14:
				var lane := pos - GUST_HALF + 3 + fmod(i * 7.3, GUST_HALF * 2 - 8)
				var span := TB.SW if horiz else 14 * TB.TS
				var x := fmod(t * 260.0 + i * 61.0, span)
				if g["dir"] < 0:
					x = span - x
				var col := Color(0.3, 0.6, 0.9, 0.8 * life)
				var head := Color(0.86, 0.93, 1.0, 0.9 * life)
				var hx: float = x + (8.0 if g["dir"] > 0 else 0.0)
				if horiz:
					ci.draw_rect(Rect2(roundf(x), roundf(lane), 14, 2), col)
					ci.draw_rect(Rect2(roundf(hx), roundf(lane), 5, 2), head)
				else:
					ci.draw_rect(Rect2(roundf(lane), roundf(3 * TB.TS + x), 2, 14), col)
					ci.draw_rect(Rect2(roundf(lane), roundf(3 * TB.TS + hx), 2, 5), head)
			ci.draw_rect(band, Color(0.3, 0.6, 0.9, 0.16 * life))

## Lane warnings and cars (drawn with the telegraphs, over the floor).
static func draw_traffic(ci: CanvasItem, t: float) -> void:
	var room := G.room
	if room == null or room.cars.is_empty():
		return
	for car in room.cars:
		var y: float = car["y"]
		if car["t"] > 0:
			var a := 0.16 + (0.14 if floori(t * 10) % 2 == 0 else 0.0)
			ci.draw_rect(Rect2(TB.TS, y - 8, TB.SW - 2 * TB.TS, 16), Color(0.85, 0.2, 0.2, a))
			# Chevrons point the way the car will come.
			var x := 24.0
			while x < TB.SW - 24:
				var cx: float = x if car["dir"] > 0 else TB.SW - x
				ci.draw_rect(Rect2(roundf(cx), y - 1, 6, 2), Color(1, 0.85, 0.3, a * 2.2))
				x += 28
		else:
			Gfx.sprite(ci, "car", car["x"], y + 5, 10, 10, 1, 1, 0.0, car["dir"] < 0)

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
		var k: float = clampf(1.0 - m["t"], 0.0, 1.0)
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
