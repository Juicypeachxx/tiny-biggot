class_name SetPieces
extends RefCounted
## 62.4 (his plan, 27 Oct: rooms that live): in the expanded game about one fight room in four on
## the first chapter's floors holds the place's own set piece (pictures drawn on PixelLab:
## resprite/pixellab/setpieces). Use it once for a small gift of the place. And small life: water
## drips from the ceiling on the wet floors, rippling where it lands (drawn only).

## [picture, name, what it says, what using it says]
const PIECES := [
	["altar", "A BONE ALTAR", "LAY YOUR HAND ON IT", "THE DEAD LEND YOU THEIR ARMOR: +1 ARMOR"],
	["spring", "A MOSSY SPRING", "DRINK FROM IT", "COLD AND CLEAR: +1 HEART"],
	["lectern", "A READING LECTERN", "READ THE OPEN PAGE", "AN OLD LESSON: +XP"],
	["forge", "A FORGE", "HAMMER YOUR WEAPON ON THE ANVIL", "A KEENER EDGE: +20% DAMAGE FOR 90S"],
	["fountain", "A FROZEN FOUNTAIN", "CRACK THE ICE", "GEMS WERE FROZEN IN IT"],
	["throne", "AN EMPTY THRONE", "SIT ON IT", "THE CUSHION HID A PURSE"],
	["well", "AN OLD WELL", "DRAW UP THE BUCKET", "FRESH WATER: +1 HEART"],
	["drum", "A WAR DRUM", "BEAT IT", "A MARCHING BEAT: +15% SPEED FOR 90S"],
	["gong", "A TEMPLE GONG", "STRIKE IT", "ITS HUM STEADIES YOU: +1 ARMOR"],
	["coop", "A PIGEON COOP", "OPEN ITS DOOR", "A PIGEON BRINGS YOU A KEY"],
	["voidaltar", "A VOID ALTAR", "TOUCH THE DARK ORB", "THE DARK FLOWS IN: +25% DAMAGE FOR 60S"],
]
const CHANCE := 0.25
## The floors where water drips (MIREWOOD GROTTO, THE SUNKEN ARCHIVE, RIMEFROST VAULT's melt,
## RAINMARSH HAMLET).
const WET := [1, 2, 4, 6]

static func handles(kind: String) -> bool:
	return kind == "setpiece"

## A new fight room's set piece (Game, with the traps and tricks).
static func setup(room: Room, floor_index: int) -> void:
	if not GameData.rogues() or floor_index < 0 or floor_index >= PIECES.size():
		return
	if not room.theme.is_empty() or not room.type in ["combat", "elite"] or room.layout in [21, 22]:
		return
	if randf() >= CHANCE and not DebugArgs.has("setpiece"):
		return
	for i in 20:
		var s := World.free_spot(room, G.player, 60, World.M_WALKER)
		var c := clampi(floori(s.x / TB.TS), TB.IX0 + 2, TB.IX0 + TB.IW - 3)
		var r := clampi(floori(s.y / TB.TS), TB.IY0 + 2, TB.IY0 + TB.IH - 3)
		if not _clear(room, c, r):
			continue
		room.objects.append({ "kind": "setpiece", "piece": floor_index, "x": (c + 1) * float(TB.TS), "y": (r + 1) * float(TB.TS) })
		return

## A 2 x 2 patch of open floor at (c, r), away from the doors, the traps and other objects.
static func _clear(room: Room, c: int, r: int) -> bool:
	for dr in 2:
		for dc in 2:
			if room.tile(c + dc, r + dr) != World.T_FLOOR:
				return false
	if absi(c - 13) <= 2 and (r <= TB.IY0 + 2 or r >= TB.IY0 + TB.IH - 3) or absi(r - 9) <= 2 and (c <= TB.IX0 + 2 or c >= TB.IX0 + TB.IW - 3):
		return false
	for t in room.traps:
		if absi(t["c"] - c) + absi(t["r"] - r) < 4:
			return false
	for o in room.objects:
		if absf(o["x"] - (c + 1) * TB.TS) < 32 and absf(o["y"] - (r + 1) * TB.TS) < 32:
			return false
	return true

static func prompt(o: Dictionary) -> Array:
	var pc: Array = PIECES[o["piece"]]
	return [pc[1], pc[2], ""]

static func interact(o: Dictionary) -> void:
	var p := G.player
	var pc: Array = PIECES[o["piece"]]
	o["used"] = true
	match pc[0]:
		"altar", "gong":
			p.armor += 1
		"spring", "well":
			p.heal(2)
		"lectern":
			Combat.gain_xp(p, 6 + G.floor_index * 2)
		"forge":
			Effects.add_buff(p, "dmg", 0.2, 90.0)
		"fountain":
			for i in 4:
				Combat.drop_pickup("gem", o["x"] + (i - 1.5) * 6, o["y"] + 14)
		"throne":
			var g := 10 + G.floor_index * 3
			p.gold += g
			Fx.float_text(o["x"], o["y"] - 18, "+%d GOLD" % g, "gold")
		"drum":
			Effects.add_buff(p, "speed", 0.15, 90.0)
		"coop":
			Combat.drop_pickup("key", o["x"], o["y"] + 14)
		"voidaltar":
			Effects.add_buff(p, "dmg", 0.25, 60.0)
	Snd.play({ "gong": "bell", "drum": "bell", "fountain": "unlock", "coop": "unlock" }.get(pc[0], "relic"))
	Fx.burst(o["x"], o["y"] - 6, ["#f2c94c", "#fffbe0", "#8b8f9c"], 14, 60)
	G.toast(pc[3], "gold")

# ---------- drawing ----------
static func draw(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var tex := Img.t("set_" + PIECES[o["piece"]][0])
	var w := tex.get_width()
	var h := tex.get_height()
	var x: float = o["x"]
	var y: float = o["y"]
	ci.draw_circle(Vector2(x, y + 6), w * 0.4, Color(0, 0, 0, 0.25), true, -1.0, false)
	var col := Color(0.62, 0.6, 0.68) if o.get("used", false) else Color(1, 1, 1)
	ci.draw_texture(tex, Vector2(roundf(x - w / 2.0), roundf(y + 8 - h)), col)
	if not o.get("used", false) and fmod(t * 0.5 + x * 0.01, 1.0) < 0.12:   # a glint: it can be used
		var gx := x + w * 0.25
		var gy := y + 8 - h * 0.8
		ci.draw_rect(Rect2(gx, gy - 2, 1, 5), Color(1, 1, 0.9, 0.8))
		ci.draw_rect(Rect2(gx - 2, gy, 5, 1), Color(1, 1, 0.9, 0.8))

## Small life on the floor (the lower layer): water dripping on the wet floors.
static func draw_live(ci: CanvasItem, t: float) -> void:
	var room := G.room
	if room == null or not GameData.rogues() or not room.theme.is_empty() or not G.floor_index in WET:
		return
	var rng := RandomNumberGenerator.new()   # (the drawing's own numbers: the game's are not touched)
	rng.seed = hash([room.cell, room.layout, room.entrance, room.exits.keys(), G.floor_index])
	var drip := TB.c("#9fd8f0")
	for i in 5:
		var c := rng.randi_range(TB.IX0 + 1, TB.IX0 + TB.IW - 2)
		var r := rng.randi_range(TB.IY0 + 1, TB.IY0 + TB.IH - 2)
		if room.tile(c, r) != World.T_FLOOR:
			continue
		var x := (c + 0.5) * TB.TS + rng.randf_range(-4, 4)
		var y := (r + 0.5) * TB.TS
		var period := rng.randf_range(1.8, 3.2)
		var k := fmod(t + rng.randf() * period, period)
		if k < 0.35:   # falling
			var f := k / 0.35
			ci.draw_rect(Rect2(x, y - 30 * (1.0 - f * f), 1, 2), Color(drip.r, drip.g, drip.b, 0.85))
		elif k < 1.0:   # a ring spreading where it landed
			var f := (k - 0.35) / 0.65
			_ring(ci, Vector2(x, y), 1.0 + f * 5.0, Color(drip.r, drip.g, drip.b, 0.55 * (1.0 - f)))
		ci.draw_rect(Rect2(x - 1, y - 1, 3, 2), Color(0.35, 0.55, 0.7, 0.18))   # the damp spot

static func _ring(ci: CanvasItem, at: Vector2, rx: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var a := i / 12.0 * TAU
		pts.append(at + Vector2(cos(a) * rx, sin(a) * rx * 0.5))
	ci.draw_polyline(pts, col, 1.0)
