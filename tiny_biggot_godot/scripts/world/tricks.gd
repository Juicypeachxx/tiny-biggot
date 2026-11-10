class_name Tricks
extends RefCounted
## 62.3 (his plan, 27 Oct: "hidden room mechanic it needs to click with enviroment"): in the
## expanded game a room's hidden wall (its cracked wall, World.make_room or a floor map) also has
## the place's own trick beside it. Use it and the wall opens, as a bomb opens it (bombs still do).
##
##   lever     a lever on the wall: pull it
##   bookcase  a bookcase against the wall that is not quite flush: slide it
##   draught   air you can see (dust, leaves, snow) seeping through the wall: push where it seeps
##   slab      a loose slab in the floor that rocks: press it down

## Each floor's trick (the first chapter's eleven; later floors go round again).
const KINDS := ["lever", "draught", "bookcase", "lever", "draught", "slab", "slab", "bookcase", "lever", "draught", "slab"]
const NAME := { "lever": ["AN OLD LEVER", "IT IS NOT FOR A LAMP. PULL IT"],
	"bookcase": ["A CROOKED BOOKCASE", "IT STANDS A FINGER OFF THE WALL. SLIDE IT"],
	"draught": ["A DRAUGHT", "AIR SEEPS THROUGH THE WALL HERE. PUSH IT"],
	"slab": ["A LOOSE SLAB", "IT ROCKS UNDERFOOT. PRESS IT DOWN"] }
const LINE := { "lever": "THE LEVER CLUNKS: A WALL GRINDS OPEN", "bookcase": "THE BOOKCASE SLIDES ASIDE",
	"draught": "THE WALL WAS ONLY A SCREEN", "slab": "THE SLAB SINKS: A WALL GRINDS OPEN" }

static func handles(kind: String) -> bool:
	return kind == "trick"

static func kind_for(floor_index: int) -> String:
	return KINDS[posmod(floor_index, KINDS.size())]

## A new room's trick (Game, with the traps): one beside its hidden wall.
static func setup(room: Room, floor_index: int) -> void:
	if not GameData.rogues() or room.secret_dirs.is_empty() or not room.theme.is_empty():
		return
	var d: String = room.secret_dirs.keys()[0]
	var kind := kind_for(floor_index)
	var spot := _spot(room, d, kind)
	if spot.x < 0:
		return
	room.objects.append({ "kind": "trick", "trick": kind, "dir": d, "x": spot.x, "y": spot.y })

## Where it goes: a floor tile beside the hidden wall (the draught: right in front of it).
static func _spot(room: Room, d: String, kind: String) -> Vector2:
	var ts := float(TB.TS)
	var inward: Vector2i = -World.DIRS[d]
	var mid: Vector2i = World.door_tiles(d)[0] + inward   # the first floor tile inside the wall
	var cands: Array = []
	match kind:
		"draught":
			cands = [mid, mid + inward]
		"slab":
			for k in [3, 4, 2, 5]:
				for s in [0, 1, -1, 2, -2]:
					cands.append(mid + inward * (k - 1) + Vector2i(inward.y, inward.x) * s)
		_:   # a lever or a bookcase, along the same wall a little to one side
			var side := Vector2i(absi(inward.y), absi(inward.x))
			for s in [4, -4, 5, -5, 3, -3, 6, -6]:
				cands.append(mid + side * s)
	for c in cands:
		var at: Vector2i = c
		if room.tile(at.x, at.y) == World.T_FLOOR:
			var p := Vector2((at.x + 0.5) * ts, (at.y + 0.5) * ts)
			if kind == "draught":   # (on the line between the door's two tiles)
				var dc := World.door_center(d)
				p = Vector2(dc.x, p.y) if inward.x == 0 else Vector2(p.x, dc.y)
			return p
	return Vector2(-1, -1)

static func prompt(o: Dictionary) -> Array:
	var n: Array = NAME[o["trick"]]
	return [n[0], n[1], ""]

static func interact(o: Dictionary) -> void:
	o["used"] = true
	o["t"] = G.time
	var d: String = o["dir"]
	G.add_shake(2)
	Fx.burst(o["x"], o["y"], ["#8b8f9c", "#4e4a5e", "#f4ecd8"], 12, 50)
	if not G.room.secret_dirs.has(d):
		Snd.play("lock")
		G.toast("IT HAS ALREADY BEEN OPENED", "white")
		return
	G.open_secret_door(d, LINE[o["trick"]])

# ---------- drawing (each frame, with the room's objects) ----------
static func draw(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x: float = o["x"]
	var y: float = o["y"]
	var used: bool = o.get("used", false)
	match o["trick"]:
		"lever":
			_lever(ci, x, y, used, t)
		"bookcase":
			_bookcase(ci, o, x, y, used, t)
		"draught":
			_draught(ci, o, x, y, used, t)
		"slab":
			_slab(ci, x, y, used, t)

static func _lever(ci: CanvasItem, x: float, y: float, used: bool, t: float) -> void:
	ci.draw_rect(Rect2(x - 4, y - 2, 8, 8), TB.c("#1c1a24"))
	ci.draw_rect(Rect2(x - 3, y - 1, 6, 6), TB.c("#4e4a5e"))
	ci.draw_rect(Rect2(x - 3, y - 1, 6, 1), TB.c("#8b8f9c"))
	var a := 0.6 if used else -0.6 + sin(t * 2.0) * 0.04
	var tip := Vector2(x, y + 2) + Vector2(sin(a), -cos(a)) * 10.0
	ci.draw_line(Vector2(x, y + 2), tip, TB.c("#140f1c"), 3.0)
	ci.draw_line(Vector2(x, y + 2), tip, TB.c("#a8705a"), 1.5)
	ci.draw_circle(tip, 2.0, TB.c("#e8873a" if not used else "#8b8f9c"), true, -1.0, false)
	ci.draw_circle(Vector2(x, y + 2), 1.0, TB.c("#f2c94c"), true, -1.0, false)

static func _bookcase(ci: CanvasItem, o: Dictionary, x: float, y: float, used: bool, t: float) -> void:
	var slide := 0.0
	if used:
		slide = clampf((G.time - o.get("t", 0.0)) * 20.0, 0.0, 10.0)
	var bx := x - 7 + slide
	var by := y - 15
	ci.draw_rect(Rect2(bx - 1, by - 1, 16, 22), TB.c("#140f1c"))
	ci.draw_rect(Rect2(bx, by, 14, 20), TB.c("#5a3a2a"))
	var cols := ["#a83a3a", "#3a6aa8", "#c8a040", "#4a8a4a", "#7a4aa8", "#d8c8a0"]
	for row in 3:
		var sy := by + 2 + row * 6
		ci.draw_rect(Rect2(bx + 1, sy, 12, 5), TB.c("#2a1a14"))
		var sx := bx + 1.5
		for k in 4:
			var w := 2.0 + (row + k) % 2
			ci.draw_rect(Rect2(sx, sy + (1 if (row * 3 + k) % 3 == 0 else 0), w, 5 - (1 if (row * 3 + k) % 3 == 0 else 0)), TB.c(cols[(row * 4 + k) % cols.size()]))
			sx += w + 0.5
	ci.draw_rect(Rect2(bx, by, 14, 1), TB.c("#8a5a3a"))
	if not used:   # the tell: a thin dark gap down one side
		ci.draw_rect(Rect2(bx + 14, by + 1, 1, 19), TB.ca("#000000", 200))
		if floori(t * 1.5) % 4 == 0:
			ci.draw_rect(Rect2(bx + 14, by + 4, 1, 3), TB.ca("#f2c94c", 120))

static func _draught(ci: CanvasItem, o: Dictionary, x: float, y: float, used: bool, t: float) -> void:
	if used:
		return
	var inward: Vector2 = Vector2(-World.DIRS[o["dir"]])
	var across := Vector2(inward.y, inward.x)
	var col := TB.c("#f4ecd8")
	var look: String = { 1: "leaf", 4: "snow", 9: "snow" }.get(posmod(G.floor_index, KINDS.size()), "dust")
	if look == "leaf":
		col = TB.c("#e8e070")
	elif look == "snow":
		col = TB.c("#ffffff")
	var base := Vector2(x, y) - inward * 10.0
	for i in 4:   # pale streaks of moving air, fanning out of the wall
		var f := fmod(t * 0.8 + i * 0.25, 1.0)
		var at := base + inward * (f * 34.0) + across * ((i - 1.5) * (5.0 + f * 6.0))
		ci.draw_line(at, at + inward * 9.0, Color(1, 1, 1, 0.4 * (1.0 - f)), 1.0)
	for i in 12:
		var f := fmod(t * 0.5 + i * 0.083, 1.0)
		var at := base + inward * (f * 44.0) + across * (sin(t * 3.0 + i * 1.9) * (2.0 + f * 5.0) + (i % 3 - 1) * (4.0 + f * 8.0))
		var a := 0.95 * (1.0 - f * f)
		ci.draw_rect(Rect2(at.x - 0.5, at.y - 0.5, 2 if look == "leaf" else 1.5, 1 if look == "leaf" else 1.5), Color(col.r, col.g, col.b, a))

static func _slab(ci: CanvasItem, x: float, y: float, used: bool, t: float) -> void:
	var r := Rect2(x - 7, y - 7, 14, 14)
	if used:
		ci.draw_rect(r, TB.c("#0d0a12"))
		ci.draw_rect(Rect2(r.position + Vector2(1, 2), r.size - Vector2(2, 3)), TB.c("#2e2a3a"))
		return
	var rock := 0.5 if floori(t * 1.2) % 5 == 0 else 0.0   # it rocks now and then
	ci.draw_rect(r.grow(1), TB.ca("#000000", 150))
	ci.draw_rect(Rect2(r.position + Vector2(0, -rock), r.size), TB.c("#5a5668"))
	ci.draw_rect(Rect2(r.position + Vector2(1, 1 - rock), Vector2(12, 1)), TB.c("#8b8f9c"))
	ci.draw_line(Vector2(x - 3, y - 2 - rock), Vector2(x + 2, y + 3 - rock), TB.c("#3a3648"), 1.0)
	ci.draw_line(Vector2(x + 2, y + 3 - rock), Vector2(x + 4, y + 2 - rock), TB.c("#3a3648"), 1.0)
