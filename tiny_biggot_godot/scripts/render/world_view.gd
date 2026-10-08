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
var vfx: DrawLayer       # z 1950  ability effects (Vfx): blasts, lightning, marks on afflicted foes
var pbul: DrawLayer      # z 2000  player shots, moons, wisps
var bars: DrawLayer      # z 2050  foe health bars
var ebul: DrawLayer      # z 2100  enemy shots
var parts: DrawLayer     # z 2200  particles
var swing: DrawLayer     # z 2250  melee arcs, thrusts, rays
var top: DrawLayer       # z 2300  aim reticle
var vignette: Sprite2D   # z 2500
var screen: DrawLayer    # z 2600  hurt / low-health edges, flashes (Juice)
var texts: DrawLayer     # z 3000  floating numbers
var _floats: FloatTexts
var _labels: DrawLayer

## Rendering has its own random stream so drawing never shifts the game's
## RNG: a seeded run plays out identically headless or on screen.
var _vr := RandomNumberGenerator.new()

const PICKUP_SPRITE := { "coin": "coin", "heart": "heartPick", "potion": "potion", "gem": "gem", "bomb": "bomb",
	"key": "key", "armor": "armor", "ember": "ember",
	"c_fury": "c_fury", "c_smoke": "c_smoke", "c_whet": "c_whet", "c_insight": "c_insight" }

func _ready() -> void:
	bg = _layer(_paint_bg)
	dyn = _layer(_paint_dyn)
	lower = _layer(_paint_lower)
	ents = _layer(_paint_ents)
	fx = _layer(_paint_fx)
	glow = _layer(_paint_glow, true)
	vfx = _layer(_paint_vfx)
	pbul = _layer(_paint_pbullets)
	_shots = ShotBatch.new()
	pbul.add_child(_shots)
	bars = _layer(_paint_bars)
	ebul = _layer(EBullets.draw)
	parts = _layer(_paint_parts)
	swing = _layer(_paint_swings)
	top = _layer(_paint_top)
	vignette = Sprite2D.new()
	vignette.texture = Img.t("vignette")
	vignette.centered = false
	add_child(vignette)
	screen = _layer(func(ci):
		_paint_fog(ci)
		Juice.draw_screen(ci, G.player, G.time))
	texts = _layer(_paint_texts)
	_floats = FloatTexts.new()
	texts.add_child(_floats)
	_labels = DrawLayer.new(_paint_labels)
	texts.add_child(_labels)
	G.room_changed.connect(_on_room_changed)

## Ashfall Town: banks of fog drift across the room and the edges close in (drawing only).
func _paint_fog(ci: CanvasItem) -> void:
	if G.room == null or not G.room.theme.get("fog", false):
		return
	var t := G.time
	for i in 5:
		var w := 150.0 + 40.0 * (i % 3)
		var x := fposmod(t * (9.0 + i * 3.0) + i * 110.0, TB.SW + w) - w
		var y := 40.0 + i * 46.0 + sin(t * 0.4 + i) * 10.0
		ci.draw_rect(Rect2(roundf(x), roundf(y), w, 26), Color(0.78, 0.8, 0.78, 0.07))
		ci.draw_rect(Rect2(roundf(x + 14), roundf(y + 5), w - 28, 16), Color(0.78, 0.8, 0.78, 0.07))
	for k in 4:
		var th := 10.0 * (k + 1)
		var c := Color(0.62, 0.65, 0.62, 0.09)
		ci.draw_rect(Rect2(0, 0, TB.SW, th), c)
		ci.draw_rect(Rect2(0, TB.SH - th, TB.SW, th), c)
		ci.draw_rect(Rect2(0, 0, th, TB.SH), c)
		ci.draw_rect(Rect2(TB.SW - th, 0, th, TB.SH), c)

func _paint_parts(ci: CanvasItem) -> void:
	Fx.draw_particles(ci)
	Juice.draw_sparks(ci)
	if Vfx.enabled and BiomeDeco.on(G.room):
		BiomeDeco.paint_air(ci, G.time)

## The top layer, bottom to top: loot name plates (this layer), floating
## numbers (FloatTexts, kept on the canvas), then ability labels and cards.
func _paint_texts(ci: CanvasItem) -> void:
	_paint_plates(ci)

func _paint_labels(ci: CanvasItem) -> void:
	if not Meta.opts.get("fast_draw", true):
		Fx.draw_texts(ci)   # FAST DRAWING off: floating numbers drawn the plain way
	Juice.draw_labels(ci)

## Rogues layer: name plates over nearby loot (the one you stand on shows its full card instead).
func _paint_plates(ci: CanvasItem) -> void:
	if not GameData.rogues() or G.room == null or G.player == null:
		return
	var p := G.player
	for o in G.room.objects:
		if o.get("gone", false) or o.get("opened", false) or o == G.prompt:
			continue
		var name := ""
		var rar := "common"
		var sub := ""
		match o["kind"]:
			"item":
				name = WeaponInfo.display_name(o["item"]) if o["item"]["item"] == "weapon" else o["item"]["name"]
				rar = o["item"]["rarity"]
			"pedestal":
				if o["relic"] == null:
					continue
				name = o["relic"]["name"]
				rar = o["relic"]["rarity"]
				sub = o["relic"]["desc"]
			"shop":
				if o.has("thing"):
					name = o["thing"]["name"]
					rar = o["thing"]["rarity"]
				elif o["item"] == "relic":
					name = o["relic"]["name"]
					rar = o["relic"]["rarity"]
			"anvil":
				name = "ANVIL"
			_:
				continue
		if name == "" or TB.dist_xy(p.x, p.y, o["x"], o["y"]) > 110:
			continue
		var it = o.get("item") if o["kind"] == "item" else o.get("thing")
		if it is Dictionary and Gear.continues_set(p, it):   # 13.2: a piece of a set you have started
			var sz := Gear.set_size(it["set"])
			sub = "%s SET %d/%d > %d/%d" % [Gear.SETS[it["set"]]["name"], p.sets[it["set"]], sz, p.sets[it["set"]] + 1, sz]
		if sub.length() > 30:
			sub = sub.left(28) + ".."
		var w := maxi(TB.text_w(name), TB.text_w(sub)) + 6
		var h := 9 if sub == "" else 17
		var px := clampf(roundf(o["x"] - w / 2), 2, TB.SW - w - 2)
		var py := roundf(o["y"] - 30 - h)
		ci.draw_rect(Rect2(px - 1, py - 1, w + 2, h + 2), Color(0.08, 0.06, 0.11, 0.9))
		ci.draw_rect(Rect2(px, py, w, 1), TB.c(GameData.RARITY_HEX.get(rar, "#8b8f9c")))
		Gfx.text(ci, name, px + 3, py + 2, GameData.RARITY_COL.get(rar, "white"), 1, 0.0, false)
		if sub != "":
			Gfx.text(ci, sub, px + 3, py + 10, "grey", 1, 0.0, false)

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
	if Vfx.enabled and BiomeDeco.on(G.room):
		BiomeDeco.tick(TB.DT)
	if G.state == &"play":
		RoomDress.tick(TB.DT)
	_prepare_shots()
	_floats.sync()
	_labels.queue_redraw()
	for l in [lower, ents, fx, glow, vfx, pbul, bars, ebul, parts, swing, top, screen, texts]:
		l.queue_redraw()

static func deg(rgss_deg: float) -> float:
	return -deg_to_rad(rgss_deg)

# ---------- Room background (build_room_bg) ----------
func _paint_bg(ci: CanvasItem) -> void:
	var room := G.room
	if room == null:
		return
	if GameData.rogues() and Meta.opts.get("neon", false):
		_paint_neon(ci, room)   # 10.5: the NEON LOOK option
		RoomDress.paint_ponds(ci, room)
		return
	var ts := TB.TS
	# A rift world has its own tiles.
	var kit := Img.t(room.kit if room.kit != "" else (room.theme["kit"] if not room.theme.is_empty() else "kit%d" % G.floor_index))
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
	_paint_decor(ci, room)
	_paint_void(ci, room, kit)
	# The expanded game: each floor's own floor marks, wall dressing and props (ROADMAP 4.7 part B).
	var deco := BiomeDeco.on(room)
	BiomeDeco.begin(room)
	if deco:
		BiomeDeco.paint_floor(ci, room)
		BiomeDeco.paint_wall(ci, room)
	for r in range(TB.IY0, TB.IY0 + TB.IH):
		for c in range(TB.IX0, TB.IX0 + TB.IW):
			if room.tile(c, r) == World.T_PILLAR:
				if deco:
					BiomeDeco.paint_prop(ci, room, c, r)
				else:
					ci.draw_texture_rect_region(kit, Rect2(c * ts, r * ts - 4, ts + 1, 2 * ts), Rect2(0, 2 * ts, ts + 1, 2 * ts))
	RoomDress.paint_static(ci, room)   # 16: each kind of room furnished

## 10.5 (his ask, 6 Oct, from his trailer clips: an option, the usual look stays the default): black
## floors and thin bright walls in the floor's own colour (a rift world's accent in its rooms).
const NEON := ["#9aa0b0", "#63b84f", "#4d9be6", "#e8873a", "#6fd3e0", "#a35bd6", "#8fbf4a", "#d8443c", "#c8f0ff", "#7a3ab0", "#f2c94c"]
func _paint_neon(ci: CanvasItem, room: Room) -> void:
	var ts := TB.TS
	var hexc: String = room.theme.get("accent_hex", NEON[G.floor_index % NEON.size()]) if not room.theme.is_empty() else NEON[G.floor_index % NEON.size()]
	var col := TB.c(hexc)
	var dim := Color(col.r, col.g, col.b, 0.35)
	ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), TB.c("#05050a"))
	var r0 := Rect2(TB.IX0 * ts - 3, TB.IY0 * ts - 3, TB.IW * ts + 6, TB.IH * ts + 6)
	# A dotted band on the wall, then a bright line and a faint glow line inside it.
	var x := r0.position.x - 6
	while x < r0.end.x + 6:
		ci.draw_rect(Rect2(x, r0.position.y - 6, 2, 2), dim)
		ci.draw_rect(Rect2(x + 2, r0.end.y + 4, 2, 2), dim)
		x += 6
	var y := r0.position.y - 6
	while y < r0.end.y + 6:
		ci.draw_rect(Rect2(r0.position.x - 6, y, 2, 2), dim)
		ci.draw_rect(Rect2(r0.end.x + 4, y + 2, 2, 2), dim)
		y += 6
	ci.draw_rect(r0, col, false, 2.0)
	ci.draw_rect(r0.grow(-3), dim, false, 1.0)
	# Pillars and props: black blocks in the colour's outline; open sky stays black.
	for r in range(TB.IY0, TB.IY0 + TB.IH):
		for c in range(TB.IX0, TB.IX0 + TB.IW):
			if room.tile(c, r) == World.T_PILLAR:
				ci.draw_rect(Rect2(c * ts + 1, r * ts + 1, ts - 2, ts - 2), col, false, 1.0)
				ci.draw_rect(Rect2(c * ts + 3, r * ts + 3, ts - 6, ts - 6), dim, false, 1.0)

## 11.2 (his ask, 6 Oct, from his trailer clips): a foe winding up a big hit shows a red circle with
## a "!" under it, in the expanded game. Drawing only: what the foe does and when is unchanged.
const WINDUPS := [&"slam", &"tele", &"swell", &"wind", &"spin", &"thrust", &"palm"]
func _paint_warnings(ci: CanvasItem, t: float) -> void:
	if not GameData.rogues():
		return
	for e: Enemy in G.enemies:
		if e.hp <= 0 or e.hidden or e.is_boss() or not e.state in WINDUPS:
			continue
		var c := Vector2(roundf(e.x), roundf(e.y + 2))
		var r := e.r + 14.0
		var a := 0.55 + 0.35 * sin(t * 18.0)
		ci.draw_circle(c, r, Color(0.85, 0.1, 0.1, 0.16))
		ci.draw_arc(c, r, 0.0, TAU, 28, Color(1.0, 0.2, 0.2, a), 1.5)
		Gfx.text(ci, "!", c.x, c.y - e.r * e.scale - 22, "red", 2, 0.5, true, a)

## Open sky between islands (Skyreach Isles): the sky tile, with a cliff lip under any floor above it.
func _paint_void(ci: CanvasItem, room: Room, kit: Texture2D) -> void:
	if room.theme.get("layouts", "") != "isles":
		return
	var ts := TB.TS
	for r in range(TB.IY0, TB.IY0 + TB.IH):
		for c in range(TB.IX0, TB.IX0 + TB.IW):
			if room.tile(c, r) != World.T_VOID:
				continue
			var lip := room.tile(c, r - 1) != World.T_VOID
			ci.draw_texture_rect_region(kit, Rect2(c * ts, r * ts, ts, ts), Rect2((3 if lip else 2) * ts, 2 * ts, ts, ts))

## Floor markings of a rift world, over the tiles and under everything else.
func _paint_decor(ci: CanvasItem, room: Room) -> void:
	var ts := TB.TS
	match room.theme.get("decor", ""):
		"road":
			# A street: kerbs along the top and bottom, lane dashes on the traffic lanes.
			var line := Color(0.95, 0.79, 0.3, 0.55)
			var kerb := Color(0.55, 0.56, 0.61, 0.5)
			ci.draw_rect(Rect2(ts, 3 * ts, TB.IW * ts, 2), kerb)
			ci.draw_rect(Rect2(ts, 16 * ts - 2, TB.IW * ts, 2), kerb)
			for y in [92.0, 132.0, 172.0, 212.0]:
				var x := ts + 6.0
				while x < TB.SW - ts - 12:
					ci.draw_rect(Rect2(x, y, 12, 2), line)
					x += 28
		"rug":
			# A big rug in the middle of the room.
			var rr := Rect2(8 * ts, 6 * ts, 12 * ts, 7 * ts)
			ci.draw_rect(rr, Color(0.54, 0.16, 0.2, 0.85))
			ci.draw_rect(rr.grow(-3), Color(0.85, 0.27, 0.24, 0.85))
			ci.draw_rect(rr.grow(-6), Color(0.54, 0.16, 0.2, 0.85))
			ci.draw_rect(rr.grow(-8), Color(0.95, 0.79, 0.3, 0.5))
			ci.draw_rect(rr.grow(-10), Color(0.72, 0.22, 0.24, 0.9))

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
	RoomDress.paint_dyn(ci, room)   # 17.1: pots, kegs, coin heaps
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
		var shut: bool = G.locked or room.sealed.has(d) or (d == room.entrance and not room.exits.has(d))
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
		var kind: Dictionary = GameData.door_kind(c)
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
	RoomDress.paint_live(ci, t)   # 16: flames, glints, incense, little animals
	Hazards.draw_floor(ci, t)
	Rex.draw_floor(ci, t)
	EnemyAI2.draw_goo(ci, t)
	RiftBosses.draw_ground(ci, t)
	Chaos.draw_ground(ci, t)
	_paint_warnings(ci, t)   # 11.2: a red "!" circle under a foe winding up a big hit
	Arsenal.draw_floor(ci, t)
	Charged.draw_floor(ci, t)
	Summons.draw_floor(ci, t)
	Oddities.draw_floor(ci, t)
	var fancy := Vfx.enabled
	if fancy:
		Vfx.draw_floor(ci, t)
	_paint_shadows(ci, room)
	if fancy:
		Afx.draw_ground(ci, t)
		Vfx.draw_ground(ci, t)
	# Zone motes (z 5): the plain look, when FANCY EFFECTS is off.
	for z in ([] if fancy else G.zones):
		match z["kind"]:
			"fire":
				if _vr.randf() < 0.5:
					var col: String = ["#e8873a", "#f2c94c", "#d8443c"][_vr.randi() % 3]
					Gfx.px(ci, TB.c(col), z["x"] + _vr.randi_range(-z["r"], z["r"]) * 0.7, z["y"] + _vr.randi_range(-3, 3), 2)
			"poison", "ink":
				for k in 3:
					var col := TB.ca(["#b8e05a", "#63b84f"][_vr.randi() % 2] if z["kind"] == "poison" else ["#2a2a4a", "#4d6aa8"][_vr.randi() % 2], 160)
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
			# ---------- Event rooms ----------
			"mimicchest":
				Gfx.sp(ci, "chest", x, y + 4)   # looks just like a chest
			"wheel":
				# It shudders for a moment after a spin.
				var spun: float = t - o.get("spin", -9.0)
				Gfx.sp(ci, "wheel", x + (roundf(sin(t * 60) * 1.5) if spun < 0.5 else 0.0), y + 10, 2, 2)
			"well":
				Gfx.sp(ci, "well", x, y + 10, 2, 2)
			"bloodstall":
				Gfx.sp(ci, "bloodstall", x, y + 6, 2, 2)
			"bloodshop":
				ci.draw_rect(Rect2(roundf(x - 9), roundf(y + 2), 18, 6), TB.c("#3a161c"))
				ci.draw_rect(Rect2(roundf(x - 9), roundf(y + 2), 18, 1), TB.c("#8a2a33"))
				Gfx.sp(ci, o["relic"]["sprite"], x, y + bob, 2, 2)
				Gfx.at(ci, "heart_full", roundf(x - 9), roundf(y + 10))
				Gfx.text(ci, "-1", roundf(x), roundf(y + 11), "red")
			"mirror":
				if not o.get("used", false):
					var zm := 2.0 + sin(t * 3) * 0.08
					Gfx.sp(ci, "riftdoor", x, y + 8, zm, zm)
			"tome":
				Gfx.sp(ci, "tome", x, y + 6 + (0.0 if o.get("used", false) else bob), 2, 2)
			"bed":
				Gfx.sp(ci, "bed", x, y + 8, 2, 2)
			"s_decor", "s_bartender", "s_drink", "s_merchant", "s_broker", "s_drunk", "s_piano", "s_poster":
				Saloon.draw(ci, o, t)
			"e_pitboss", "e_mechanic", "e_teller", "e_card", "e_courier", "e_attendant", "e_beacon", "e_statue", "e_plate", \
					"e_decor", "w_drunk", "w_merchant", "e_frog", "e_glyph", "e_pawn", "e_hustler", "e_cup", "e_gong", "n_archivist", "n_endbook", "n_turnpage", "n_inkling", "n_bookbinder", "n_tornpage", "n_redactdoor", "n_readon", "e_pond", "e_angler", "e_pot", "e_coins", "e_keg", "c_portal", "c_wardrobe", "c_shrine", "c_telescope", "c_dummy", "c_board", "c_daily", "c_cook", "c_rack", "v_peddler", "v_bard", "v_seer", "v_monger", "v_cat", "v_gambler", "v_tinker", "c_build", "c_deco":
				EventRooms.draw(ci, o, t)
			"x_table", "x_lever", "x_skull", "x_fisher", "x_saint", "x_ratpile":
				RiftExtras.draw(ci, o, t)
			"pet_cage":
				Pets.draw_cage(ci, o, t)
			"x_bowl":
				Rex.draw_bowl(ci, o, t)
			"jukebox":
				Gfx.sp(ci, "jukebox", x, y + 10, 2, 2)
				if not o.get("used", false) and floori(t * 4) % 2 == 0:
					Gfx.px(ci, TB.c("#f2c94c"), x - 6 + floori(t * 2) % 3 * 6, y - 16, 2)
			"brick":
				Gfx.sp(ci, "brick", x, y)
			"ichest":
				Gfx.sp(ci, "chestIronOpen" if o.get("opened", false) else "chestIron", x, y + 4)
			"cchest":
				Gfx.sp(ci, "chestCursedOpen" if o.get("opened", false) else "chestCursed", x, y + 4)
			"idol":
				Gfx.sp(ci, "idol", x, y + 4)
			"campfire":
				Gfx.sp(ci, "campfire", x, y + 4)
			"alshrine":   # 8.1: a stone plinth with its alignment's sign above it
				ci.draw_rect(Rect2(x - 7, y - 2, 14, 7), TB.c("#3a3448"))
				ci.draw_rect(Rect2(x - 6, y - 2, 12, 1), TB.c("#6a6280"))
				var used: bool = o.get("used", false)
				Gfx.sp(ci, Alignments.ICON[o["al"]], x, y - 4 + (0.0 if used else sin(t * 3 + x) * 1.5), 1, 1, 0.0, false, 0.35 if used else 1.0)
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
				if ItemShow.active():
					if o.get("pedestal", false):
						ItemShow.pedestal(ci, x, y)
					ItemShow.beam(ci, o, t)
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
			"anvil":
				# Rogues layer: a small iron anvil on a stump.
				var ax := roundf(x)
				var ay := roundf(y)
				ci.draw_rect(Rect2(ax - 4, ay + 2, 8, 6), TB.c("#7a5236"))
				ci.draw_rect(Rect2(ax - 4, ay + 2, 8, 1), TB.c("#a8705a"))
				ci.draw_rect(Rect2(ax - 7, ay - 3, 13, 4), TB.c("#4e4a5e"))
				ci.draw_rect(Rect2(ax - 9, ay - 3, 3, 2), TB.c("#4e4a5e"))
				ci.draw_rect(Rect2(ax - 6, ay - 3, 11, 1), TB.c("#8b8f9c"))
				ci.draw_rect(Rect2(ax - 2, ay + 1, 4, 2), TB.c("#2a2838"))
				if floori(t * 3) % 4 == 0:
					Gfx.px(ci, TB.c("#f2c94c"), ax + 3, ay - 5)
			"loopportal", "exitportal":
				# Gold for looping on, pale for leaving.
				var zl := 1.1 + sin(t * 4) * 0.06
				Gfx.sp(ci, "portal", x, y + 6, zl, zl, 0.0, false, 1.0,
					TB.rgba(242, 201, 76, 150) if o["kind"] == "loopportal" else TB.rgba(244, 236, 216, 110))
				Gfx.text(ci, "LOOP" if o["kind"] == "loopportal" else "EXIT", x, y - 18, "gold" if o["kind"] == "loopportal" else "bone", 1, 0.5)
				if o["kind"] == "loopportal":
					# A turning gold ring marks the way round again.
					for k in 3:
						var a0 := t * 2.5 + k * TAU / 3.0
						ci.draw_arc(Vector2(x, y + 2), 13, a0, a0 + 1.4, 10, TB.ca("#f2c94c", 220), 1.5, false)
			"portal":
				var zz := 1 + sin(t * 4) * 0.05
				Gfx.sp(ci, "portal", x, y + 6, zz, zz)
			"soulgate", "pageportal":
				# Heaven or Hell (ROADMAP 4.7 part C): gold for the light, red for the dark, pale for the page.
				var lit: bool = o.get("realm", "") == "heaven"
				var col := TB.rgba(242, 201, 76, 170) if lit else (TB.rgba(216, 68, 60, 170) if o["kind"] == "soulgate" else TB.rgba(244, 236, 216, 150))
				var zs := 1.25 + sin(t * 3) * 0.08
				Gfx.sp(ci, "portal", x, y + 6, zs, zs, 0.0, false, 1.0, col)
				var label := ("HEAVEN" if lit else "HELL") if o["kind"] == "soulgate" else "THE PAGE"
				Gfx.text(ci, label, x, y - 22, ("gold" if lit else "red") if o["kind"] == "soulgate" else "bone", 1, 0.5)
				for k in 4:
					var a0 := -t * 1.8 + k * TAU / 4.0
					ci.draw_arc(Vector2(x, y + 2), 16, a0, a0 + 0.9, 8, col, 1.5, false)
				if _vr.randf() < 0.4 and G.state == &"play":
					Fx.particle(x + _vr.randi_range(-5, 5), y + _vr.randi_range(-5, 5), 0, -20, 0.5, "#a35bd6")
	if not G.locked:
		_paint_exit_signs(ci, room, t)
	# Pickups and bombs (z 9).
	for k: Pickup in G.pickups:
		var wob := 0.0 if k.kind == "coin" else roundf(sin(t * 4))
		if StatDrops.is_kind(k.kind):   # 8.3: its icon, a glint and its label over it
			Gfx.sp(ci, StatDrops.KINDS[k.kind][1], k.x, k.y + 3 - k.z - wob)
			StatDrops.draw_label(ci, k, wob)
			continue
		Gfx.sp(ci, PICKUP_SPRITE[k.kind], k.x, k.y + 3 - k.z - wob)
		if k.kind in ["coin", "gem"]:
			Juice.glint(ci, k.x + _vr.randi_range(-2, 2), k.y - k.z - wob)
	for b in G.bombs:
		var big: bool = b["t"] < 0.35
		var blink := floori(b["t"] * (20 if b["t"] < 0.4 else 8)) % 2 == 1
		Gfx.sp(ci, "bomb", b["x"], b["y"] + 4, 1.25 if big else 1.0, 1.25 if big else 1.0, 0.0, false, 1.0,
			TB.rgba(255, 80, 60, 170) if blink else Color(0, 0, 0, 0))
	# Mines sit on the floor (z 6).
	for b: PBullet in _mines:
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
			"chest", "ichest", "cchest", "mimicchest", "tome", "jukebox": shadow(ci, o["x"], o["y"] + 4, 12)
			"idol", "campfire", "altar", "fountain", "wheel", "well", "bloodstall", "bed": shadow(ci, o["x"], o["y"] + 4, 14)
			"bell": shadow(ci, o["x"], o["y"] + 4, 10)
			"s_merchant", "s_broker", "e_pitboss", "e_mechanic", "e_teller", "e_courier", "e_attendant", "w_merchant", "e_pawn", "e_hustler", "n_archivist", "n_inkling", "n_bookbinder": \
				shadow(ci, o["x"], o["y"] + 1, 8)
			"item": shadow(ci, o["x"], o["y"] + 6, 10)
	for k: Pickup in G.pickups:
		shadow(ci, k.x, k.y + 2, 6)
	for e: Enemy in G.enemies:
		if e.spawn_t > 0 or e.hidden:
			continue
		var tex := Img.t(_enemy_sprite(e))
		shadow(ci, e.x, e.y + e.r + (2 if e.is_boss() else 0), tex.get_width() * e.scale * 0.75)
	var p := G.player
	shadow(ci, p.x, p.y + 5, 10 - p.air * 0.2)   # smaller while a leap carries the hero up
	if Pets.active(p) and not Pets.st in ["gone", "splat"]:
		shadow(ci, Pets.x, Pets.y + 5, 5 if p.pet in ["zappy", "glimmer", "hoots"] else 7)

# ---------- Entities (sorted by y) ----------
func _enemy_sprite(e: Enemy) -> String:
	if e.boss == "rex":
		var rs := Rex.sprite(e)   # lying down to sleep, nap and run
		var rl := Stages.look(e)   # 6.2: party Rex, then super Rex (his ask: cute, not scary)
		return rs + "_s%d" % rl if rl > 1 and Img.has(rs + "_s%d" % rl) else rs
	var key: String = e.d["sprite"]
	var look := Stages.look(e)
	if look > 1:
		var full := key + ("_elite" if e.elite and not e.is_boss() else "")
		if Img.has(full + "_s%d" % look):
			return full + "_s%d" % look   # it has evolved (his ask, 6 Oct; minis and champions: 6.1)
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
			Pets.draw(ci, p, t)
			_draw_player(ci, p, t)
		else:
			_draw_enemy(ci, e, t)
	Juice.draw_pops(ci)

func _draw_player(ci: CanvasItem, p: Player, t: float) -> void:
	var name: String = p.hero["sprite"]
	for tr in p.trail:
		# Roll and dash ghosts are white; the Gaolbird's tempo ghosts carry their own colour.
		Gfx.sp(ci, name, tr["x"], tr["y"] + 6 - tr.get("air", 0.0), 1.0, 1.0, 0.0, tr["face"] < 0,
			clampf(tr["life"] * 2.5, 0.0, 1.0), tr.get("col", Color(1, 1, 1, 1)))
	var airborne := p.leap_max > 0
	if p.invuln > 0 and floori(t * 20) % 2 == 1 and p.dodge_t <= 0 and not airborne:
		return
	var behind := sin(p.aim_a) < -0.3
	if behind:
		_draw_weapon(ci, p)
	var bob := -1 if p.moving and p.dodge_t <= 0 and floori(p.walk_t * 10) % 2 == 1 else 0
	var zx := 1.0
	var zy := 0.85 if p.dodge_t > 0 else 1.0
	var py := p.y + 6 + bob
	if airborne:
		# A leap: stretched on the way up, tucked in on the way down, lifted off its shadow.
		var rising := p.dash_t > p.leap_max * 0.5
		zx = 0.9 if rising else 1.1
		zy = 1.15 if rising else 0.9
		py = p.y + 6 - p.air
	Gfx.sp(ci, name, p.x, py, zx, zy, 0.0, p.face < 0)
	# Equipped gear is painted over the hero (visual only).
	HeroGear.draw(ci, p, p.x, py, zx, zy, p.face < 0)
	if not behind:
		_draw_weapon(ci, p)

func _draw_weapon(ci: CanvasItem, p: Player) -> void:
	if p.weapon == null or p.dodge_t > 0 or p.leap_max > 0:
		return
	var wn: String = p.weapon["sprite"]
	var wb := Img.t(wn)
	# Polish: the weapon kicks back a little when it fires.
	var kick := Juice.recoil * 2.0
	var hx := p.x + cos(p.aim_a) * (6 - kick)
	var hy := p.y - 1 + sin(p.aim_a) * (4 - kick * 0.6)
	var left := cos(p.aim_a) < 0
	# The icon points up and to the right, so aiming right turns it by (aim - 45 degrees).
	# Aiming left is the mirror image of aiming right: the flipped sprite turns the other
	# way round. (The first port turned it the same way, so a weapon aimed up-left pointed down-left.)
	var rot := (p.aim_a - PI) + PI / 4 if left else p.aim_a - PI / 4
	if GameData.rogues() and p.weapon.get("rarity", "") == "legend":
		# Rogues layer: legendary weapons glow in their theme's colour.
		var th := WeaponFx.theme_of(WeaponFx.weapon_tag(p.weapon))
		var gc := TB.c(th["cols"][0] if not th.is_empty() else "#f2c94c")
		Gfx.sprite(ci, "glow_small", hx - 12, hy - 12, 0, 0, 1, 1, 0.0, false, 0.55 + 0.25 * sin(G.time * 5),
			Color(gc.r, gc.g, gc.b, 0.6))
	Gfx.sprite(ci, wn, hx, hy, wb.get_width() / 2, wb.get_height() / 2, 1, 1, rot, left)
	if Juice.recoil > 0.6:
		var mx := roundf(hx + cos(p.aim_a) * 8)
		var my := roundf(hy + sin(p.aim_a) * 6)
		ci.draw_rect(Rect2(mx - 1, my - 1, 3, 3), Color(1, 0.95, 0.75, 0.9))

func _draw_enemy(ci: CanvasItem, e: Enemy, t: float) -> void:
	if e.spawn_t > 0:
		return
	var boss := e.is_boss()
	if boss and e.hidden:
		return
	var name := _enemy_sprite(e)
	var sc := e.scale * (0.55 if e.shrink_t > 0 else 1.0)   # shrunk by the shrink ray (oddities.gd)
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
	if e.flash > 0 and not boss:
		# Polish: a short squash when hit.
		sx *= 1.18
		sy *= 0.84
	elif e.chill_t > 0:
		tint = TB.rgba(111, 211, 224, 130)
	if e.puppet_t > 0:
		tint = TB.rgba(163, 91, 214, 150) if floori(t * 8) % 2 == 0 else TB.rgba(163, 91, 214, 90)   # a puppet
	elif e.charm_t > 0:
		tint = TB.rgba(232, 111, 180, 130)   # tamed: fights for you
	if e.state == &"charge" and e.stun_t <= 0.0 and Vfx.enabled and (not boss or e.sub == 2):
		# A charge leaves afterimages behind the runner.
		for k in range(3, 0, -1):
			Gfx.sp(ci, name, e.x - cos(e.ca) * 9.0 * k, foot + bob - e.z - sin(e.ca) * 9.0 * k, sc * sx, sc * sy, 0.0, e.face < 0,
				0.52 - 0.13 * k, Color(1.0, 0.54, 0.54, 0.7))
	Gfx.sp(ci, name, e.x, foot + bob - e.z, sc * sx, sc * sy, 0.0, e.face < 0, 46 / 255.0 if e.hidden else 1.0, tint)
	if not e.parts.is_empty():
		RiftBosses.draw_parts(ci, e, foot + bob - e.z, t)
	if e.type == "dummy":
		Gfx.text(ci, "DPS %s" % TB.fmt_dmg(e.dps), e.x, foot - 24, "gold" if e.dps > 0 else "dim", 1, 0.5)

# ---------- z 1800: spawn rings, telegraphs, boss beams ----------
func _paint_fx(ci: CanvasItem) -> void:
	var t := G.time
	var fancy := Vfx.enabled
	var accent := TB.c(GameData.floors()[G.floor_index]["accent_hex"])
	for e: Enemy in G.enemies:
		if e.spawn_t > 0:
			var k := 1 - e.spawn_t / 0.75
			var r := 10 - k * 6
			for i in 8:
				var a := i / 8.0 * TAU + t * 3
				Gfx.px(ci, accent, e.x + cos(a) * r, e.y + sin(a) * r * 0.6 + 4)
			if floori(t * 12) % 2 == 1:
				Gfx.px(ci, accent, e.x - 1, e.y + 3, 2)
		if fancy:
			continue   # Afx draws the wind-up marks and the beams (lanes on the floor, lines and beams below)
		if e.d.get("ai", "") == "knight" and e.state == &"tele":
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
	if fancy:
		Afx.draw_marks(ci, t)
	Juice.draw_rings(ci)
	Juice.draw_magic(ci, G.player, G.time)
	_paint_marks(ci, G.player, G.time)
	Hazards.draw_marks(ci, G.time)
	Hazards.draw_traffic(ci, G.time)
	Hazards.draw_gusts(ci, G.time)
	RiftExtras.draw_hazards(ci, G.time)
	EnemyAI2.draw_marks(ci, G.time)
	RiftBosses.draw_over(ci, G.time)
	Chaos.draw_over(ci, G.time)
	Pets.draw_over(ci, G.player, G.time)
	Arsenal.draw_over(ci, G.time)
	Charged.draw_over(ci, G.time)
	Flail.draw_over(ci, G.time)
	Summons.draw_over(ci, G.time)
	Oddities.draw_over(ci, G.time)

# ---------- z 1900: additive glows ----------
## Small markers: a pink chevron over exposed foes (they take +25% damage), and
## the Gaolbird's rally: the heart at stake, the blows landed and the time left.
func _paint_marks(ci: CanvasItem, p: Player, t: float) -> void:
	if not GameData.rogues():
		return
	var pink := TB.c("#e86fb4")
	for e: Enemy in G.enemies:
		if e.vuln_t <= 0 or e.hp <= 0 or e.hidden or e.spawn_t > 0:
			continue
		if e.vuln_t < 0.8 and floori(t * 12) % 2 == 1:
			continue   # blinks as it runs out
		var x := roundf(e.x)
		var y := roundf(e.y - e.r - 11 - e.z + sin(t * 8 + e.uid) * 1.5)
		for k in 3:
			ci.draw_rect(Rect2(x - 2 + k, y + k, 1, 2), pink)
			ci.draw_rect(Rect2(x + 2 - k, y + k, 1, 2), pink)
	if p == null or p.rally_t <= 0:
		return
	var left := Rally.time_left(p)
	if left < 0.35 and floori(t * 14) % 2 == 1:
		return   # flickers when time is nearly up
	var hx := roundf(p.x - 4)
	var hy := roundf(p.y - 27 - p.air)
	ci.draw_texture_rect_region(Img.t("heart_rally"), Rect2(hx, hy, 9, 8), Rect2(0, 0, 9, 8), Color(1, 1, 1, 0.75 + 0.25 * sin(t * 12)))
	var n := p.rally_n
	var x0 := roundf(p.x - n + 0.5)
	ci.draw_rect(Rect2(x0 - 1, hy + 9, n * 2 + 1, 4), Color(0.08, 0.06, 0.11, 0.85))
	for k in n:
		ci.draw_rect(Rect2(x0 + k * 2, hy + 10, 1, 2), TB.c("#f2c94c") if k < p.rally_prog else TB.c("#4e4a5e"))
	ci.draw_rect(Rect2(x0 - 1, hy + 13, roundf((n * 2 + 1) * left), 1), TB.c("#fffbe0"))

## 13.2: a whole set glows around the hero in its colour (one ring per complete set, at most 3).
func _paint_set_aura(ci: CanvasItem, t: float) -> void:
	var p := G.player
	if p == null or not GameData.rogues() or p.hp <= 0:
		return
	var n := 0
	for id in p.set_tier:
		if p.set_tier[id] < 3:
			continue
		var cols: Array = Weapons.TAG_COLS.get(Gear.SETS[id]["tag"], Weapons.TAG_COLS["core"])
		var c := TB.c(cols[0])
		var c2 := TB.c(cols[2])
		var cx := p.x
		var cy := p.y - 3 - p.air
		var r := 13.0 + n * 4 + sin(t * 3 + n) * 1.5
		ci.draw_circle(Vector2(cx, cy), r + 4, Color(c.r, c.g, c.b, 0.10))
		ci.draw_arc(Vector2(cx, cy), r, 0, TAU, 28, Color(c.r, c.g, c.b, 0.45), 1.0)
		for k in 3:
			var a := t * (1.6 + n * 0.4) * (1 if n % 2 == 0 else -1) + k * TAU / 3
			ci.draw_circle(Vector2(cx, cy) + Vector2.from_angle(a) * r, 1.5, Color(c2.r, c2.g, c2.b, 0.9))
		n += 1
		if n >= 3:
			break

func _paint_glow(ci: CanvasItem) -> void:
	var t := G.time
	# Polish: light beams over rare, epic and legendary loot.
	for o in G.room.objects:
		if o.get("gone", false) or o.get("opened", false):
			continue
		if o["kind"] == "item":
			Juice.beam(ci, o["x"], o["y"], o["item"].get("rarity", "common"), t)
		elif o["kind"] == "pedestal" and o["relic"] != null:
			Juice.beam(ci, o["x"], o["y"], o["relic"].get("rarity", "common"), t)
	_paint_set_aura(ci, t)
	for i in 2:
		var op := roundf(200 + sin(t * 9 + i * 7) * 25 + sin(t * 23 + i) * 15) / 255.0
		Gfx.at(ci, "glow_torch", [6, 21][i] * TB.TS + 8 - 36, TB.TS + 4 - 36, op)
	BiomeDeco.paint_glow(ci, t)
	RoomDress.paint_glow(ci, t)
	for o in G.room.objects:
		if o.get("gone", false):
			continue
		var x: float = o["x"]
		var y: float = o["y"]
		match o["kind"]:
			"chest", "ichest", "mimicchest", "wheel", "well":
				if not o.get("opened", false): Gfx.at(ci, "glow_white", x - 24, y - 24)
			"mirror", "tome":
				if not o.get("used", false): Gfx.at(ci, "glow_purple", x - 30, y - 30)
			"cchest":
				if not o.get("opened", false): Gfx.at(ci, "glow_purple", x - 30, y - 30)
			"campfire":
				Gfx.at(ci, "glow_torch", x - 36, y - 40, (120 if o.get("used", false) else 220) / 255.0)
			"altar":
				if not o.get("used", false): Gfx.at(ci, "glow_red", x - 30, y - 34)
			"portal", "loopportal", "exitportal", "soulgate", "pageportal":
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
	if p.tempo > 0:
		# The Gaolbird's tempo: a pink glow that grows with it and flares in full flight.
		var tc := TB.c("#e86fb4")
		if Tempo.full(p):
			Gfx.sprite(ci, "glow_white", p.x - 24, p.y - 24 - p.air, 0, 0, 1, 1, 0.0, false, 0.42 + 0.14 * sin(t * 10),
				Color(tc.r, tc.g, tc.b, 0.8))
		elif p.tempo >= 3:
			Gfx.sprite(ci, "glow_small", p.x - 12, p.y - 12 - p.air, 0, 0, 1, 1, 0.0, false, 0.06 * p.tempo,
				Color(tc.r, tc.g, tc.b, 0.8))
	for i in G.familiars.size():
		if i >= p.familiars:
			break
		var f: Dictionary = G.familiars[i]
		Gfx.at(ci, "glow_small", f["x"] - 12, f["y"] - 12)
	if Vfx.enabled:
		# The new look: a shot glows in its own family's colour.
		var gw := Img.t("glow_white")
		for b: PBullet in _glows:
			var c := Afx.shot_col(b.kind, b.tag)
			match b.kind:
				"hex", "boomer":
					ci.draw_texture_rect(gw, Rect2(roundf(b.x) - 14, roundf(b.y) - 14, 28, 28), false, Color(c.r, c.g, c.b, 0.85))
				"rail":
					ci.draw_texture_rect(gw, Rect2(roundf(b.x) - 24, roundf(b.y) - 24, 48, 48), false, Color(c.r, c.g, c.b, 0.55))
				"pulse":
					var s := b.r * 9.0
					ci.draw_texture_rect(gw, Rect2(roundf(b.x - s * 0.5), roundf(b.y - s * 0.5), s, s), false, Color(c.r, c.g, c.b, 0.8))
	for b: PBullet in ([] if Vfx.enabled else _glows):
		match b.kind:
			"hex", "boomer":
				Gfx.at(ci, "glow_small", b.x - 12, b.y - 12)
			"rail":
				Gfx.at(ci, "glow_white", b.x - 24, b.y - 24, 120 / 255.0)
			"pulse":
				# RGSS zooms about the sprite origin, here its top-left corner.
				var z := b.r / 3.0
				Gfx.sprite(ci, "glow_small", b.x - 12, b.y - 12, 0, 0, z, z)
	if Vfx.enabled:
		Vfx.draw_glow(ci)
		Afx.draw_glow(ci)

# ---------- z 1950: ability effects ----------
func _paint_vfx(ci: CanvasItem) -> void:
	if Vfx.enabled:
		Vfx.draw_over(ci, G.time)

# ---------- z 2000: player shots, moons, wisps ----------
const PULSE_SPRITE := { "pyre": "orb_fireBig", "frost": "orb_iceBig", "shadow": "orb_darkBig", "venom": "orb_fireBig" }

var _shots: ShotBatch
var _plain: Array = []     # this tick's shots for the plain painter
var _mines: Array = []     # this tick's mines (drawn on the floor)
var _glows: Array = []     # this tick's first 40 glowing shots

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
	# Shots were sorted by _prepare_shots this tick: nearly all of them are in
	# the ShotBatch child (one instanced draw, on top); the kinds its shader
	# has no rule for are drawn here as before.
	var gf := ShotBatch.clock(t)
	var whirls := ShotBatch.WHIRL_MAX
	for b: PBullet in _plain:
		if b.ds >= 0:
			if b.dw >= 0 and whirls > 0:
				whirls -= 1
				_draw_spec(ci, b, ShotBatch.specs[b.dw], gf % 2)
			var sp: Array = ShotBatch.specs[b.ds]
			_draw_spec(ci, b, sp, gf % int(sp[2]))
		else:
			_draw_pbullet(ci, b)

## One pass over the player's shots per tick, shared by the three layers
## that show them (it used to be one loop over every shot in each layer):
## the batch buffer for the shot layer, the mines for the floor layer and
## the first 40 glowing shots for the glow layer.
func _prepare_shots() -> void:
	var t0 := Time.get_ticks_usec() if DrawLayer.perf_on else 0
	_plain.clear()
	_mines.clear()
	_glows.clear()
	var list: Array = G.pbullets
	if ShotBatch.try_reset():
		# The class tables filled up last tick and have just been emptied: every live shot is sorted
		# again below, so the classes in use take their places before anything is drawn.
		for b: PBullet in list:
			b.dk = -1
	var specs := ShotBatch.specs
	# Room for every shot plus the whirls under spinning weapons (a whirl with no room left is skipped).
	var buf := _shots.begin(list.size() + ShotBatch.WHIRL_MAX)
	var spare := ShotBatch.WHIRL_MAX
	var i := 0
	var gl := 0
	# OPTIONS > FAST DRAWING off: every shot goes to the plain painter, as before.
	var fast: bool = Meta.opts.get("fast_draw", true)
	for b: PBullet in list:
		var dk := b.dk
		if dk < 0:
			dk = ShotBatch.classify(b)
		if dk < ShotBatch.PLAIN and not fast:
			dk = ShotBatch.PLAIN
		if dk < ShotBatch.PLAIN:
			var wk: int = specs[b.dw][7] if b.dw >= 0 else -1
			if wk >= 0 and spare > 0:
				# The whirl under a spinning weapon: one more instance, drawn first.
				spare -= 1
				buf[i + 3] = roundf(b.x)
				buf[i + 7] = roundf(b.y)
				buf[i + 8] = b.vx
				buf[i + 9] = b.vy
				buf[i + 12] = fmod(b.rot * 40, 360)
				buf[i + 13] = b.r
				buf[i + 14] = wk
				buf[i + 15] = 1.0
				i += ShotBatch.STRIDE
			# Eight numbers per shot; the sprite, frame, zoom and angle are worked out in the shader.
			buf[i + 3] = roundf(b.x)
			buf[i + 7] = roundf(b.y)
			buf[i + 8] = b.vx
			buf[i + 9] = b.vy
			buf[i + 12] = fmod(b.rot * 40, 360)
			buf[i + 13] = b.r
			buf[i + 14] = dk
			buf[i + 15] = b.life / maxf(b.max_life, 0.01)
			i += ShotBatch.STRIDE
		elif dk == ShotBatch.PLAIN:
			_plain.append(b)
		else:
			_mines.append(b)
		if b.gk != 0 and gl < 40:
			# At most 40 shot glows, as in the original (pulse orbs ride along uncounted).
			if b.gk == 1:
				gl += 1
			_glows.append(b)
	_shots.finish(i / ShotBatch.STRIDE, ShotBatch.clock(G.time))
	if DrawLayer.perf_on:
		DrawLayer.perf["shots"] = DrawLayer.perf.get("shots", 0) + Time.get_ticks_usec() - t0

func _centered(ci: CanvasItem, name: String, b: PBullet, zx: float = 1.0, zy: float = 1.0, rot: float = 0.0,
		alpha: float = 1.0, tint: Color = Color(0, 0, 0, 0)) -> void:
	var tex := Img.t(name)
	Gfx.sprite(ci, name, b.x, b.y, tex.get_width() / 2, tex.get_height() / 2, zx, zy, rot, false, alpha, tint)

## The new look, drawn in script: the same sprite, frame, zoom and angle the batch's shader works out
## from the same rule (ShotBatch.specs), so FAST DRAWING on and off give the same picture.
func _draw_spec(ci: CanvasItem, b: PBullet, sp: Array, frame: int) -> void:
	var r := ShotBatch.half(b.r)      # the shader gets these as 16-bit floats: round the same way
	var z: float = sp[3]
	if sp[4] > 0.0:
		z = maxf(sp[3], r / sp[4])
	var alpha := 1.0
	var special: float = sp[6]
	if special == ShotBatch.S_HEX:
		if r > 3.5:
			sp = ShotBatch.specs[sp[8]]
		z = r / 5.0 if r > 6.0 else 1.0
	elif special == ShotBatch.S_FIRE:
		var k := ShotBatch.half(b.life / maxf(b.max_life, 0.01))
		z = 0.6 + 0.8 * (1.0 - k)
		alpha = clampf(k * 1.5, 0.0, 1.0)
	var a := 0.0
	if sp[5] == ShotBatch.R_SPIN:
		a = -deg_to_rad(ShotBatch.half(fmod(b.rot * 40, 360)))
	elif sp[5] == ShotBatch.R_HEADING:
		a = atan2(ShotBatch.half(b.vy), ShotBatch.half(b.vx))
	var cell: Rect2 = sp[1]
	var org := Vector2(floorf(cell.size.x * 0.5), floorf(cell.size.y * 0.5))
	ci.draw_set_transform(Vector2(roundf(b.x), roundf(b.y)), a, Vector2(z, z))
	ci.draw_texture_rect_region(Img.t(sp[0]), Rect2(-org, cell.size),
		Rect2(cell.position + Vector2(frame * cell.size.x, 0), cell.size), Color(1, 1, 1, alpha))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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
		"feather":
			_centered(ci, "feather", b, 1.0, 1.0, atan2(b.vy, b.vx))
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
	for e: Enemy in G.enemies:   # elite traits: their names under the foe (elite_traits.gd)
		if not e.traits.is_empty() and e.hp > 0 and not e.hidden and e.spawn_t <= 0:
			Gfx.text(ci, EliteTraits.label(e), roundf(e.x), roundf(e.y + e.r + 6), "gold", 1, 0.5)
	for e: Enemy in G.enemies:
		if e.is_boss() or e.hp >= e.max_hp or e.hidden or e.spawn_t > 0 or e.hp <= 0:
			continue
		var x := roundf(e.x - 6)
		var y := roundf(e.y + e.r + 2)
		ci.draw_rect(Rect2(x - 1, y - 1, 14, 4), TB.c("#1a1423"))
		ci.draw_rect(Rect2(x, y, 12, 2), TB.c("#4e4a5e"))
		if GameData.rogues():
			# Rogues layer: a white "damage ghost" trails the bar down.
			if e.ghost_hp < e.hp:
				e.ghost_hp = e.hp
			e.ghost_hp = maxf(e.hp, e.ghost_hp - e.max_hp * 0.012)
			ci.draw_rect(Rect2(x, y, ceilf(12.0 * e.ghost_hp / e.max_hp), 2), TB.c("#f4ecd8"))
		ci.draw_rect(Rect2(x, y, ceilf(12.0 * e.hp / e.max_hp), 2), TB.c("#f2c94c" if e.elite else "#d8443c"))
		if not e.traits.is_empty() and e.armor > 0:   # a PLATED elite's plate, over its health
			ci.draw_rect(Rect2(x, y, ceilf(12.0 * minf(e.armor, e.max_hp) / e.max_hp), 1), TB.c("#e8eef8"))

# ---------- z 2250: melee arcs, thrusts, rays ----------
func _paint_swings(ci: CanvasItem) -> void:
	if Vfx.enabled:
		Afx.draw_swings(ci, G.time)   # smears, lances, lashes, beams and the hit flashes
		return
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
	RoomDress.paint_over(ci)   # 17.3: lightning
	var p := G.player
	if G.enemies_active() or Keys.aim() != null:
		var ax := p.x + cos(p.aim_a) * 16
		var ay := p.y - 2 + sin(p.aim_a) * 16
		ci.draw_rect(Rect2(roundf(ax - 2), roundf(ay - 2), 4, 4), TB.c("#1a1423"))
		ci.draw_rect(Rect2(roundf(ax - 1), roundf(ay - 1), 2, 2), TB.c("#f4ecd8"))
