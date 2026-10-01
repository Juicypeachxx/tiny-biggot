class_name WorldView
extends Node2D
## World rendering (port of Render.rb draw_world / redraw_dyn / build_room_bg).
##
## RGSS used one Sprite per thing, re-assigned every frame from sprite pools.
## Here every RGSS z band is one DrawLayer (a single CanvasItem), drawn in
## the same order. The whole world is about fifteen canvas items however many
## bullets are on screen, and each layer's draws are grouped by texture so
## Godot batches them. The static room background and the doors and crates
## layer only redraw when they change.

var bg: DrawLayer        # z 0     room tiles (static per room)
var dyn: DrawLayer       # z 1     doors, crates, cracked walls (redrawn on dyn_dirty)
var lower: DrawLayer     # z 2-9   torches, hint, shadows, zones, objects, signs, pickups, bombs, mines
var ents: DrawLayer      # z 100+y player, foes and the held weapon, sorted by y
var fx: DrawLayer        # z 1800  spawn rings, charge telegraphs, beams
var glow: DrawLayer      # z 1900  additive glows
var pbul: DrawLayer      # z 2000  player shots, moons, wisps
var bars: DrawLayer      # z 2050  foe health bars
var ebul: DrawLayer      # z 2100  enemy shots
var parts: DrawLayer     # z 2200  particles
var swing: DrawLayer     # z 2250  melee arcs, thrusts, rays
var top: DrawLayer       # z 2300  aim reticle
var vignette: Sprite2D   # z 2500
var texts: DrawLayer     # z 3000  floating numbers

## Rendering has its own random stream so drawing never shifts the game's
## RNG: a seeded run plays out identically headless or on screen.
var _vr := RandomNumberGenerator.new()

const PICKUP_SPRITE := { "coin": "coin", "heart": "heartPick", "potion": "potion", "gem": "gem", "bomb": "bomb",
	"key": "key", "armor": "armor", "ember": "ember" }

func _ready() -> void:
	bg = _layer(_paint_bg)
	dyn = _layer(_paint_dyn)
	lower = _layer(_paint_lower)
	ents = _layer(_paint_ents)
	fx = _layer(_paint_fx)
	glow = _layer(_paint_glow, true)
	pbul = _layer(_paint_pbullets)
	bars = _layer(_paint_bars)
	ebul = _layer(EBullets.draw)
	parts = _layer(Fx.draw_particles)
	swing = _layer(_paint_swings)
	top = _layer(_paint_top)
	vignette = Sprite2D.new()
	vignette.texture = Img.t("vignette")
	vignette.centered = false
	add_child(vignette)
	texts = _layer(Fx.draw_texts)
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
	visible = G.room != null and G.player != null
	if not visible:
		return
	var sh := G.shake
	if sh > 0:
		position = Vector2(-roundf((_vr.randf() - 0.5) * sh), -roundf((_vr.randf() - 0.5) * sh))
	else:
		position = Vector2.ZERO
	if G.dyn_dirty:
		G.dyn_dirty = false
		dyn.queue_redraw()
	for l in [lower, ents, fx, glow, pbul, bars, ebul, parts, swing, top, texts]:
		l.queue_redraw()

static func deg(rgss_deg: float) -> float:
	return -deg_to_rad(rgss_deg)

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


# ---------- Lower bands: torches, hint, shadows, zones, objects, signs, pickups, bombs ----------
func _paint_lower(ci: CanvasItem) -> void:
	var room := G.room
	var t := G.time
	for i in 2:
		Gfx.at(ci, "torch", [6, 21][i] * TB.TS + 5, TB.TS + 1)
	# Start room hint (z 3).
	if room.type == "start" and G.floor_index == 0:
		var lines := ["CLEAR THE ROOMS. SLAY THE GUARDIAN.",
			"YOU FIRE AT THE NEAREST FOE BY ITSELF" if Meta.opts["autofire"] else "AIM WITH THE AIM BUTTONS TO FIRE",
			"PRESS ROLL TO DODGE THROUGH SHOTS"]
		for i in lines.size():
			var w := TB.text_w(lines[i]) + 1
			Gfx.text(ci, lines[i], TB.SW / 2 - w / 2, 6 * TB.TS + i * 10, "bone", 1, 0.0, true, 120 / 255.0)
	_paint_shadows(ci, room)
	# Zone motes (z 5).
	for z in G.zones:
		match z["kind"]:
			"fire":
				if _vr.randf() < 0.5:
					var col: String = ["#e8873a", "#f2c94c", "#d8443c"][_vr.randi() % 3]
					Gfx.px(ci, TB.c(col), z["x"] + _vr.randi_range(-z["r"], z["r"]) * 0.7, z["y"] + _vr.randi_range(-3, 3), 2)
			"poison":
				for k in 3:
					var col := TB.ca(["#b8e05a", "#63b84f"][_vr.randi() % 2], 160)
					Gfx.px(ci, col, z["x"] + cos(t * 2 + _vr.randf() * 6) * z["r"] * _vr.randf(), z["y"] + sin(t * 3 + _vr.randf() * 6) * z["r"] * 0.6)
	# Room objects (z 6-8).
	for o in room.objects:
		if o.get("gone", false):
			continue
		var bob := roundf(sin(t * 3 + o["x"]) * 1.5)
		var x: float = o["x"]
		var y: float = o["y"]
		match o["kind"]:
			"chest":
				Gfx.sp(ci, "chestOpen" if o.get("opened", false) else "chest", x, y + 4)
			"ichest":
				Gfx.sp(ci, "chestIronOpen" if o.get("opened", false) else "chestIron", x, y + 4)
			"cchest":
				Gfx.sp(ci, "chestCursedOpen" if o.get("opened", false) else "chestCursed", x, y + 4)
			"idol":
				Gfx.sp(ci, "idol", x, y + 4)
			"campfire":
				Gfx.sp(ci, "campfire", x, y + 4)
			"bell":
				Gfx.sp(ci, "bell", x, y + 4, 1, 1, deg(sin(t * 10) * 8) if o.get("used", false) else 0.0)
			"lockdoor":
				if not o.get("used", false):
					Gfx.sp(ci, "lock", x, y + 4 + bob)
			"altar":
				Gfx.sp(ci, "altar", x, y + 4)
			"fountain":
				Gfx.sp(ci, "fountain", x, y + 4)
			"pedestal":
				ci.draw_rect(Rect2(roundf(x - 9), roundf(y + 2), 18, 6), TB.c("#4e4a5e"))
				ci.draw_rect(Rect2(roundf(x - 9), roundf(y + 2), 18, 1), TB.c("#8b8f9c"))
				if not o.get("opened", false) and o["relic"] != null:
					Gfx.sp(ci, o["relic"]["sprite"], x, y + bob, 2, 2)
			"item":
				var it: Dictionary = o["item"]
				Gfx.sp(ci, it["sprite"], x, y + 2 + bob, 1.5, 1.5)
			"shop":
				ci.draw_rect(Rect2(roundf(x - 9), roundf(y + 2), 18, 6), TB.c("#4e4a5e"))
				ci.draw_rect(Rect2(roundf(x - 9), roundf(y + 2), 18, 1), TB.c("#8b8f9c"))
				var name := ""
				if o["item"] == "relic":
					name = o["relic"]["sprite"]
				elif o.has("thing"):
					name = o["thing"]["sprite"]
				else:
					name = { "potion": "potion", "heart": "heartPick", "bomb": "bomb", "key": "key", "armor": "armor" }[o["item"]]
				Gfx.sp(ci, name, x, y + bob, 2, 2)
				var label := "%dG" % o["price"]
				Gfx.text(ci, label, roundf(x - TB.text_w(label) / 2), roundf(y + 11), "gold" if G.player.gold >= o["price"] else "red")
			"portal":
				var zz := 1 + sin(t * 4) * 0.05
				Gfx.sp(ci, "portal", x, y + 6, zz, zz)
				if _vr.randf() < 0.4 and G.state == &"play":
					Fx.particle(x + _vr.randi_range(-5, 5), y + _vr.randi_range(-5, 5), 0, -20, 0.5, "#a35bd6")
	if not G.locked:
		_paint_exit_signs(ci, room, t)
	# Pickups and bombs (z 9).
	for k: Pickup in G.pickups:
		var wob := 0.0 if k.kind == "coin" else roundf(sin(t * 4))
		Gfx.sp(ci, PICKUP_SPRITE[k.kind], k.x, k.y + 3 - k.z - wob)
	for b in G.bombs:
		var big: bool = b["t"] < 0.35
		var blink := floori(b["t"] * (20 if b["t"] < 0.4 else 8)) % 2 == 1
		Gfx.sp(ci, "bomb", b["x"], b["y"] + 4, 1.25 if big else 1.0, 1.25 if big else 1.0, 0.0, false, 1.0,
			TB.rgba(255, 80, 60, 170) if blink else Color(0, 0, 0, 0))
	# Mines sit on the floor (z 6).
	for b: PBullet in G.pbullets:
		if b.kind != "mine":
			continue
		var bm := Img.t(b.icon)
		var blink := b.arm <= 0 and floori(G.time * 6) % 2 == 1
		Gfx.sprite(ci, b.icon, b.x, b.y, bm.get_width() / 2, bm.get_height() / 2, 1, 1, 0.0, false, 1.0,
			TB.rgba(255, 80, 60, 150) if blink else Color(0, 0, 0, 0))

## RGSS shadow(): nearest shadow sprite width, drawn at z 4 under everything.
static func shadow(ci: CanvasItem, x: float, y: float, w: float) -> void:
	var ws := 6
	for v in [6, 10, 12, 14, 16, 20, 24]:
		if absf(v - w) < absf(ws - w):
			ws = v
	Gfx.at(ci, "shadow%d" % ws, x - ws / 2, y - 1)

func _paint_shadows(ci: CanvasItem, room: Room) -> void:
	for o in room.objects:
		if o.get("gone", false):
			continue
		match o["kind"]:
			"chest", "ichest", "cchest": shadow(ci, o["x"], o["y"] + 4, 12)
			"idol", "campfire", "altar", "fountain": shadow(ci, o["x"], o["y"] + 4, 14)
			"bell": shadow(ci, o["x"], o["y"] + 4, 10)
			"item": shadow(ci, o["x"], o["y"] + 6, 10)
	for k: Pickup in G.pickups:
		shadow(ci, k.x, k.y + 2, 6)
	for e: Enemy in G.enemies:
		if e.spawn_t > 0 or e.hidden:
			continue
		var tex := Img.t(_enemy_sprite(e))
		shadow(ci, e.x, e.y + e.r + (2 if e.is_boss() else 0), tex.get_width() * e.scale * 0.75)
	var p := G.player
	shadow(ci, p.x, p.y + 5, 10)

# ---------- Entities (sorted by y) ----------
func _enemy_sprite(e: Enemy) -> String:
	var key: String = e.d["sprite"]
	if key == "bat" and floori(e.anim * 8) % 2 == 1:
		key = "bat2"
	return key + "_elite" if e.elite and not e.is_boss() else key

func _paint_ents(ci: CanvasItem) -> void:
	var t := G.time
	var p := G.player
	var list: Array = []   # untyped: holds foes and the player
	list.append_array(G.enemies)
	list.append(p)
	list.sort_custom(func(a, b): return a.y < b.y)
	for e in list:
		if e == p:
			_draw_player(ci, p, t)
		else:
			_draw_enemy(ci, e, t)

func _draw_player(ci: CanvasItem, p: Player, t: float) -> void:
	var name: String = p.hero["sprite"]
	for tr in p.trail:
		Gfx.sp(ci, name, tr["x"], tr["y"] + 6, 1.0, 1.0, 0.0, tr["face"] < 0, clampf(tr["life"] * 2.5, 0.0, 1.0), Color(1, 1, 1, 1))
	if p.invuln > 0 and floori(t * 20) % 2 == 1 and p.dodge_t <= 0:
		return
	var behind := sin(p.aim_a) < -0.3
	if behind:
		_draw_weapon(ci, p)
	var bob := -1 if p.moving and p.dodge_t <= 0 and floori(p.walk_t * 10) % 2 == 1 else 0
	Gfx.sp(ci, name, p.x, p.y + 6 + bob, 1.0, 0.85 if p.dodge_t > 0 else 1.0, 0.0, p.face < 0)
	if not behind:
		_draw_weapon(ci, p)

func _draw_weapon(ci: CanvasItem, p: Player) -> void:
	if p.weapon == null or p.dodge_t > 0:
		return
	var wn: String = p.weapon["sprite"]
	var wb := Img.t(wn)
	var hx := p.x + cos(p.aim_a) * 6
	var hy := p.y - 1 + sin(p.aim_a) * 4
	var left := cos(p.aim_a) < 0
	# RGSS: angle = -(aim - PI) deg + 45, negated when mirrored; converted to Godot radians.
	var rot := -(p.aim_a - PI) + PI / 4 if left else p.aim_a - PI / 4
	Gfx.sprite(ci, wn, hx, hy, wb.get_width() / 2, wb.get_height() / 2, 1, 1, rot, left)

func _draw_enemy(ci: CanvasItem, e: Enemy, t: float) -> void:
	if e.spawn_t > 0:
		return
	var boss := e.is_boss()
	if boss and e.hidden:
		return
	var name := _enemy_sprite(e)
	var sc := e.scale
	var foot := e.y + e.r + (2 if boss else 0)
	var sx := 1.0
	var sy := 1.0
	if e.d.get("ai", "") == "slime":
		if e.state == &"hop":
			sx = 0.85
			sy = 1.2
		else:
			var q := sin(e.anim * 6) * 0.06
			sx = 1 + q
			sy = 1 - q
	var bob := roundf(sin(t * 2) * 2) if boss else (roundf(sin(e.anim * 5) * 2) - 3 if e.d.get("fly", false) else 0.0)
	var flashing := e.flash > 0 or (e.state in [&"aim", &"tele", &"puff"] and floori(t * 16) % 2 == 1)
	var tint := Color(0, 0, 0, 0)
	if flashing:
		tint = Color(1, 1, 1, 1)
	elif e.chill_t > 0:
		tint = TB.rgba(111, 211, 224, 130)
	Gfx.sp(ci, name, e.x, foot + bob - e.z, sc * sx, sc * sy, 0.0, e.face < 0, 46 / 255.0 if e.hidden else 1.0, tint)

# ---------- z 1800: spawn rings, telegraphs, boss beams ----------
func _paint_fx(ci: CanvasItem) -> void:
	var t := G.time
	var accent := TB.c(GameData.FLOORS[G.floor_index]["accent_hex"])
	for e: Enemy in G.enemies:
		if e.spawn_t > 0:
			var k := 1 - e.spawn_t / 0.75
			var r := 10 - k * 6
			for i in 8:
				var a := i / 8.0 * TAU + t * 3
				Gfx.px(ci, accent, e.x + cos(a) * r, e.y + sin(a) * r * 0.6 + 4)
			if floori(t * 12) % 2 == 1:
				Gfx.px(ci, accent, e.x - 1, e.y + 3, 2)
		if e.type == "knight" and e.state == &"tele":
			var i := 10
			while i < 160:
				Gfx.px(ci, TB.ca("#d8443c", 130), e.x + cos(e.ca) * i - 1, e.y + sin(e.ca) * i - 1, 2)
				i += 6
		if e.has_telegraph:
			var i := 16
			while i < 300:
				Gfx.px(ci, TB.ca("#e8873a", 160), e.x + cos(e.telegraph) * i - 1, e.y + sin(e.telegraph) * i - 1, 3)
				i += 6
		if not e.beams.is_empty():
			var active := e.sub == 2
			for ba in e.beams:
				if active:
					Gfx.bar(ci, TB.c("#e8c8ff"), e.x + 5 * sin(ba), e.y - 4 - 5 * cos(ba), 520, 10, ba)
					Gfx.bar(ci, TB.c("#ffffff"), e.x + 2 * sin(ba), e.y - 4 - 2 * cos(ba), 520, 4, ba)
				else:
					Gfx.bar(ci, TB.ca("#a35bd6", 180 if floori(t * 16) % 2 == 1 else 80), e.x, e.y - 4, 520, 2, ba)

# ---------- z 1900: additive glows ----------
func _paint_glow(ci: CanvasItem) -> void:
	var t := G.time
	for i in 2:
		var op := roundf(200 + sin(t * 9 + i * 7) * 25 + sin(t * 23 + i) * 15) / 255.0
		Gfx.at(ci, "glow_torch", [6, 21][i] * TB.TS + 8 - 36, TB.TS + 4 - 36, op)
	for o in G.room.objects:
		if o.get("gone", false):
			continue
		var x: float = o["x"]
		var y: float = o["y"]
		match o["kind"]:
			"chest", "ichest":
				if not o.get("opened", false): Gfx.at(ci, "glow_white", x - 24, y - 24)
			"cchest":
				if not o.get("opened", false): Gfx.at(ci, "glow_purple", x - 30, y - 30)
			"campfire":
				Gfx.at(ci, "glow_torch", x - 36, y - 40, (120 if o.get("used", false) else 220) / 255.0)
			"altar":
				if not o.get("used", false): Gfx.at(ci, "glow_red", x - 30, y - 34)
			"portal":
				Gfx.at(ci, "glow_purple", x - 30, y - 30)
			"pedestal":
				if not o.get("opened", false) and o["relic"] != null:
					Gfx.at(ci, "glow_white", x - 24, y - 30)
			"item":
				var rc := TB.c(GameData.RARITY_HEX[o["item"]["rarity"]])
				Gfx.sprite(ci, "glow_white", x - 24, y - 26, 0, 0, 1, 1, 0.0, false, 200 / 255.0, Color(rc.r, rc.g, rc.b, 120 / 255.0))
	for z in G.zones:
		match z["kind"]:
			"fire": Gfx.at(ci, "glow_small", z["x"] - 12, z["y"] - 12, 120 / 255.0)
			"smoke": Gfx.at(ci, "glow_white", z["x"] - 24, z["y"] - 24, roundf(90 * minf(1.0, z["t"])) / 255.0)
	for k: Pickup in G.pickups:
		if k.kind == "ember":
			Gfx.at(ci, "glow_small", k.x - 12, k.y - 14 - k.z)
	var p := G.player
	for i in G.familiars.size():
		if i >= p.familiars:
			break
		var f: Dictionary = G.familiars[i]
		Gfx.at(ci, "glow_small", f["x"] - 12, f["y"] - 12)
	# At most 40 shot glows, as in the original.
	var gl := 0
	for b: PBullet in G.pbullets:
		if gl >= 40:
			break
		match b.kind:
			"hex", "boomer":
				gl += 1
				Gfx.at(ci, "glow_small", b.x - 12, b.y - 12)
			"rail":
				gl += 1
				Gfx.at(ci, "glow_white", b.x - 24, b.y - 24, 120 / 255.0)
			"pulse":
				# RGSS zooms about the sprite origin, here its top-left corner.
				var z := b.r / 3.0
				Gfx.sprite(ci, "glow_small", b.x - 12, b.y - 12, 0, 0, z, z)

# ---------- z 2000: player shots, moons, wisps ----------
const PULSE_SPRITE := { "pyre": "orb_fireBig", "frost": "orb_iceBig", "shadow": "orb_darkBig", "venom": "orb_fireBig" }

func _paint_pbullets(ci: CanvasItem) -> void:
	var p := G.player
	var t := G.time
	for o in Combat.orbital_positions(p):
		Gfx.at(ci, "orb_moon", o.x - 5, o.y - 5)
	for f in G.temp_fams:
		Gfx.sp(ci, "familiar", f["x"], f["y"] + 4, 1, 1, 0.0, false, clampf(f["t"], 0.0, 1.0) if f["t"] < 1 else 1.0,
			TB.rgba(160, 220, 255, 120))
	for i in G.familiars.size():
		if i >= p.familiars:
			break
		var f: Dictionary = G.familiars[i]
		Gfx.sp(ci, "familiar", f["x"], f["y"] + 4 + roundf(sin(t * 6 + i) * 1.5))
	for b: PBullet in G.pbullets:
		_draw_pbullet(ci, b)

func _centered(ci: CanvasItem, name: String, b: PBullet, zx: float = 1.0, zy: float = 1.0, rot: float = 0.0,
		alpha: float = 1.0, tint: Color = Color(0, 0, 0, 0)) -> void:
	var tex := Img.t(name)
	Gfx.sprite(ci, name, b.x, b.y, tex.get_width() / 2, tex.get_height() / 2, zx, zy, rot, false, alpha, tint)

func _draw_pbullet(ci: CanvasItem, b: PBullet) -> void:
	match b.kind:
		"hex":
			var big := b.r > 3.5
			var z := b.r / (5.0 if big else 2.5) if b.r > 6 else 1.0
			_centered(ci, "orb_hexBig" if big else "orb_hex", b, z, z)
		"lance":
			Gfx.sprite(ci, "orb_iceBig", b.x, b.y, 6, 6, 1.3, 0.8, atan2(b.vy, b.vx))
		"dart":
			Gfx.sprite(ci, "orb_spore", b.x, b.y, 4, 4)
		"clod", "flask", "spark":
			var name: String = { "clod": "orb_clod", "flask": "orb_flask", "spark": "orb_cyan" }[b.kind]
			var z := maxf(1.0, b.r / 2.5) if b.kind != "spark" else 1.0
			_centered(ci, name, b, z, z)
		"boomer":
			var name := b.icon if b.icon != "" else "orb_gold"
			var z := maxf(1.0, b.r / 3.0)
			var rot := 0.0 if b.icon == "w_lantern" or b.icon == "w_sunlantern" else deg(fmod(b.rot * 40, 360))
			_centered(ci, name, b, z, z, rot)
		"bolt":
			var z := 1.4 if b.r > 3.2 else 1.0
			Gfx.sprite(ci, "bolt", b.x, b.y, 4, 2, z, z, atan2(b.vy, b.vx))
		"fire":
			var k := b.life / maxf(b.max_life, 0.01)
			var z := 0.6 + 0.8 * (1 - k)
			_centered(ci, "orb_fire", b, z, z, 0.0, clampf(k * 1.5, 0.0, 1.0))
		"pulse":
			var z := b.r / 4.0
			_centered(ci, PULSE_SPRITE.get(b.tag, "orb_hexBig"), b, z, z, 0.0, 1.0,
				TB.rgba(184, 224, 90, 140) if b.tag == "venom" else Color(0, 0, 0, 0))
		"mine":
			pass # drawn on the floor in the lower layer (z 6)
		"rail":
			var a := atan2(b.vy, b.vx)
			Gfx.bar(ci, Color.WHITE, b.x - cos(a) * 14, b.y - sin(a) * 14, 18, 2, a)
		_:
			var name := b.icon if b.icon != "" and b.kind != "hatchet" else "hatchet"
			var z := maxf(0.8, b.r / 4.0)
			_centered(ci, name, b, z, z, deg(fmod(b.rot * 40, 360)))

# ---------- z 2050: foe health bars ----------
func _paint_bars(ci: CanvasItem) -> void:
	for e: Enemy in G.enemies:
		if e.is_boss() or e.hp >= e.max_hp or e.hidden or e.spawn_t > 0 or e.hp <= 0:
			continue
		var x := roundf(e.x - 6)
		var y := roundf(e.y + e.r + 2)
		ci.draw_rect(Rect2(x - 1, y - 1, 14, 4), TB.c("#1a1423"))
		ci.draw_rect(Rect2(x, y, 12, 2), TB.c("#4e4a5e"))
		ci.draw_rect(Rect2(x, y, ceilf(12.0 * e.hp / e.max_hp), 2), TB.c("#f2c94c" if e.elite else "#d8443c"))

# ---------- z 2250: melee arcs, thrusts, rays ----------
func _paint_swings(ci: CanvasItem) -> void:
	for w in G.swings:
		var k: float = w["t"] / w["max"]
		var tag: String = w["tag"] if w["tag"] != "" else "core"
		var tint: String = Weapons.TAG_COLS.get(tag, Weapons.TAG_COLS["core"])[0]
		match w["kind"]:
			"slash":
				var z: float = w["r"] / 24.0 * (1.15 - 0.15 * k)
				var zy: float = z * w["arc"] / (140 * PI / 180)
				var tc := TB.c(tint)
				Gfx.sprite(ci, "slash_arc", w["x"], w["y"], 24, 24, z, zy, w["a"], false, roundf(210 * k) / 255.0,
					Color(tc.r, tc.g, tc.b, 110 / 255.0))
			"thrust", "whip":
				var col := TB.ca("#d9d0b4" if w["kind"] == "whip" else "#f4ecd8", roundi(230 * k))
				Gfx.bar(ci, col, w["x"], w["y"], w["len"] * (1.1 - 0.4 * k), maxf(2, w["width"] * 0.5), w["a"])
				var tx: float = w["x"] + cos(w["a"]) * w["len"]
				var ty: float = w["y"] + sin(w["a"]) * w["len"]
				Gfx.px(ci, Color(1, 1, 1, k), tx - 1, ty - 1, 3)
			"beam":
				Gfx.bar(ci, TB.c(tint), w["x"], w["y"] - 1, w["len"], 3, w["a"])
				Gfx.bar(ci, Color.WHITE, w["x"], w["y"], w["len"], 1, w["a"])

# ---------- z 2300: aim reticle ----------
func _paint_top(ci: CanvasItem) -> void:
	var p := G.player
	if G.enemies_active() or Keys.aim() != null:
		var ax := p.x + cos(p.aim_a) * 16
		var ay := p.y - 2 + sin(p.aim_a) * 16
		ci.draw_rect(Rect2(roundf(ax - 2), roundf(ay - 2), 4, 4), TB.c("#1a1423"))
		ci.draw_rect(Rect2(roundf(ax - 1), roundf(ay - 1), 2, 2), TB.c("#f4ecd8"))
