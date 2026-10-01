class_name WorldView
extends Node2D
## World rendering (port of Render.rb draw_world / redraw_dyn / build_room_bg).
##
## RGSS used one Sprite per thing, re-assigned every frame from sprite pools.
## Here every RGSS z band is one DrawLayer (a single CanvasItem) drawn in the
## same order, so the whole world is about a dozen canvas items regardless of
## how many bullets are on screen. Static layers (room background, doors and
## crates) only redraw when they change.

var bg: DrawLayer        # z 0     room tiles (static per room)
var dyn: DrawLayer       # z 1     doors, crates, cracked walls (redrawn on dyn_dirty)
var lower: DrawLayer     # z 2-9   torches, shadows, objects, exit signs, pickups, bombs
var glow: DrawLayer      # z 1900  additive glows
var vignette: Sprite2D   # z 2500

func _ready() -> void:
	bg = _layer(_paint_bg)
	dyn = _layer(_paint_dyn)
	lower = _layer(_paint_lower)
	glow = _layer(_paint_glow, true)
	vignette = Sprite2D.new()
	vignette.texture = Img.t("vignette")
	vignette.centered = false
	add_child(vignette)
	G.room_changed.connect(_on_room_changed)

func _layer(p: Callable, additive: bool = false) -> DrawLayer:
	var l := DrawLayer.new(p, additive)
	add_child(l)
	return l

func _on_room_changed() -> void:
	bg.queue_redraw()
	dyn.queue_redraw()

## Called once per logic tick.
func refresh() -> void:
	visible = G.room != null
	if not visible:
		return
	var sh := G.shake
	if sh > 0:
		position = Vector2(-roundf((TB.rnd() - 0.5) * sh), -roundf((TB.rnd() - 0.5) * sh))
	else:
		position = Vector2.ZERO
	if G.dyn_dirty:
		G.dyn_dirty = false
		dyn.queue_redraw()
	lower.queue_redraw()
	glow.queue_redraw()

# ---------- Room background (build_room_bg) ----------
func _paint_bg(ci: CanvasItem) -> void:
	var room := G.room
	if room == null:
		return
	var ts := TB.TS
	var kit := Img.t("kit%d" % G.floor_index)
	ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), TB.c("#140f1c"))
	var rng := SeedRng.new(room.seed_value ^ 0x5bd1e995)
	for r in range(TB.IY0, TB.IY0 + TB.IH):
		for c in range(TB.IX0, TB.IX0 + TB.IW):
			var v := rng.int_range(0, 7) * 2 + (0 if (r + c) % 2 == 1 else 1)
			ci.draw_texture_rect_region(kit, Rect2(c * ts, r * ts, ts, ts), Rect2(v * ts, 0, ts, ts))
	# RGSS fill_rect replaced these pixels with (10,6,16) at alpha 90 over a black screen.
	var k := 90.0 / 255.0
	ci.draw_rect(Rect2(ts, TB.IY0 * ts, TB.IW * ts, 5), Color(10 / 255.0 * k, 6 / 255.0 * k, 16 / 255.0 * k))
	for c in TB.COLS:
		ci.draw_texture_rect_region(kit, Rect2(c * ts, 0, ts, ts), Rect2(0, ts, ts, ts))
		ci.draw_texture_rect_region(kit, Rect2(c * ts, ts, ts, ts), Rect2(ts, ts, ts, ts))
		ci.draw_texture_rect_region(kit, Rect2(c * ts, 17 * ts, ts, ts), Rect2(2 * ts, ts, ts, ts))
	for r in range(TB.IY0, TB.ROWS - 1):
		ci.draw_texture_rect_region(kit, Rect2(0, r * ts, ts, ts), Rect2(3 * ts, ts, ts, ts))
		ci.draw_texture_rect_region(kit, Rect2(27 * ts, r * ts, ts, ts), Rect2(4 * ts, ts, ts, ts))
	for r in range(TB.IY0, TB.IY0 + TB.IH):
		for c in range(TB.IX0, TB.IX0 + TB.IW):
			if room.tile(c, r) == World.T_PILLAR:
				ci.draw_texture_rect_region(kit, Rect2(c * ts, r * ts - 4, ts + 1, 2 * ts), Rect2(0, 2 * ts, ts + 1, 2 * ts))

# ---------- Doors, crates, cracked walls (redraw_dyn) ----------
func _bars(ci: CanvasItem, x0: int, y0: int, w: int, h: int, vertical: bool) -> void:
	var bc := TB.c("#5a5770")
	var hc := TB.c("#8b8f9c")
	if vertical:
		var i := 2
		while i < w:
			ci.draw_rect(Rect2(x0 + i, y0, 2, h), bc)
			i += 5
		ci.draw_rect(Rect2(x0, y0 + h - 4, w, 2), hc)
	else:
		var i := 2
		while i < h:
			ci.draw_rect(Rect2(x0, y0 + i, w, 2), bc)
			i += 5
		ci.draw_rect(Rect2(x0 + w - 4, y0, 2, h), hc)

func _paint_dyn(ci: CanvasItem) -> void:
	var room := G.room
	if room == null:
		return
	var ts := TB.TS
	var dark := TB.c("#0d0a12")
	var ol := TB.c("#140f1c")
	var reveal := false
	var pl = G.get("player")
	if pl != null:
		reveal = pl.reveal
	for d in room.secret_dirs:
		for cr in World.door_tiles(d):
			if d == "n" and cr.y == 0:
				continue
			Gfx.at(ci, "crack", cr.x * ts, cr.y * ts, 1.0 if reveal else 170 / 255.0)
	var doors: Array = room.doors.keys()
	if room.entrance != "" and not doors.has(room.entrance):
		doors.append(room.entrance)
	for d in doors:
		if room.secret_dirs.has(d):
			continue
		var ex = room.exits.get(d)
		var fc := TB.c(GameData.ROOM_COL.get(ex["type"], "#8b8f9c") if ex != null else "#4e4a5e")
		var shut: bool = G.locked or room.sealed.has(d) or d == room.entrance
		match d:
			"n":
				ci.draw_rect(Rect2(13 * ts - 3, 0, 2 * ts + 6, 2 * ts), ol)
				ci.draw_rect(Rect2(13 * ts - 2, 0, 2, 2 * ts), fc)
				ci.draw_rect(Rect2(15 * ts, 0, 2, 2 * ts), fc)
				ci.draw_rect(Rect2(13 * ts - 2, 0, 2 * ts + 4, 2), fc)
				ci.draw_rect(Rect2(13 * ts, 2, 2 * ts, 2 * ts - 2), dark)
				if shut: _bars(ci, 13 * ts, 2, 2 * ts, 2 * ts - 2, true)
			"s":
				ci.draw_rect(Rect2(13 * ts - 3, 17 * ts, 2 * ts + 6, ts), ol)
				ci.draw_rect(Rect2(13 * ts - 2, 17 * ts, 2, ts), fc)
				ci.draw_rect(Rect2(15 * ts, 17 * ts, 2, ts), fc)
				ci.draw_rect(Rect2(13 * ts, 17 * ts, 2 * ts, ts), dark)
				if shut: _bars(ci, 13 * ts, 17 * ts, 2 * ts, ts, true)
			"w":
				ci.draw_rect(Rect2(0, 8 * ts - 3, ts, 3 * ts + 6), ol)
				ci.draw_rect(Rect2(0, 8 * ts - 2, ts, 2), fc)
				ci.draw_rect(Rect2(0, 11 * ts, ts, 2), fc)
				ci.draw_rect(Rect2(0, 8 * ts, ts, 3 * ts), dark)
				if shut: _bars(ci, 0, 8 * ts, ts, 3 * ts, false)
			"e":
				ci.draw_rect(Rect2(27 * ts, 8 * ts - 3, ts, 3 * ts + 6), ol)
				ci.draw_rect(Rect2(27 * ts, 8 * ts - 2, ts, 2), fc)
				ci.draw_rect(Rect2(27 * ts, 11 * ts, ts, 2), fc)
				ci.draw_rect(Rect2(27 * ts, 8 * ts, ts, 3 * ts), dark)
				if shut: _bars(ci, 27 * ts, 8 * ts, ts, 3 * ts, false)
	var shadow := TB.rgba(10, 6, 16, 90)
	for k in room.crate_hp:
		if room.tile(k.x, k.y) != World.T_CRATE:
			continue
		ci.draw_rect(Rect2(k.x * ts + 2, k.y * ts + 12, 14, 5), shadow)
		Gfx.at(ci, "crate", k.x * ts + 1, k.y * ts + 1)

# ---------- Torches, objects, exit signs (lower z bands) ----------
func _paint_lower(ci: CanvasItem) -> void:
	var room := G.room
	if room == null:
		return
	var t := G.time
	for i in 2:
		Gfx.at(ci, "torch", [6, 21][i] * TB.TS + 5, TB.TS + 1)
	for o in room.objects:
		if o.get("gone", false):
			continue
		var bob := roundf(sin(t * 3 + o["x"]) * 1.5)
		match o["kind"]:
			"lockdoor":
				if not o.get("used", false):
					Gfx.sp(ci, "lock", o["x"], o["y"] + 4 + bob)
	_paint_exit_signs(ci, room, t)

## Exit signs: what room and what reward waits behind each door.
func _paint_exit_signs(ci: CanvasItem, room: Room, t: float) -> void:
	if G.locked:
		return
	for d in room.exits:
		var c: Dictionary = room.exits[d]
		var p := World.door_center(d)
		var sx: float = p.x + { "w": 30, "e": -30 }.get(d, 0)
		var sy: float = p.y + { "n": 30 }.get(d, -2)
		var kind: Dictionary = GameData.ROOM_KINDS[c["type"]]
		var bob := roundf(sin(t * 3 + sx) * 1.5)
		var has_reward: bool = c.get("reward", "") != ""
		Gfx.sp(ci, kind["icon"], sx - (7 if has_reward else 0), sy + bob)
		if has_reward:
			Gfx.sp(ci, GameData.REWARDS[c["reward"]]["icon"], sx + 7, sy + bob)
		var w := TB.text_w(kind["name"]) + 1
		Gfx.text(ci, kind["name"], roundf(sx - w / 2), sy + 3, kind["col"])

# ---------- Additive glows ----------
func _paint_glow(ci: CanvasItem) -> void:
	var t := G.time
	for i in 2:
		var op := roundf(200 + sin(t * 9 + i * 7) * 25 + sin(t * 23 + i) * 15) / 255.0
		Gfx.at(ci, "glow_torch", [6, 21][i] * TB.TS + 8 - 36, TB.TS + 4 - 36, op)
