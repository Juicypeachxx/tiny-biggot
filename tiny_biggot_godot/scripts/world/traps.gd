class_name Traps
extends RefCounted
## 62.1 (his plan, 27 Oct: "mazes traps hidden room mechanic it needs to click with enviroment"):
## the first six floors' own traps, in the expanded game only (classic rooms never hold one). Each
## floor has its kind, laid in its fight rooms by the game's random numbers when the room is first
## entered. They warn before they strike, hurt foes as well as the hero (a roll dodges them, as
## any hit), and rest while the room is clear.
##
##   spikes   THE OSSUARY: bone spikes rise from an iron plate
##   thorns   MIREWOOD GROTTO: thorns burst from a root-bound plate
##   water    THE SUNKEN ARCHIVE: a drain spouts a scalding jet along three tiles
##   fire     THE CINDERFORGE: a vent breathes a line of fire
##   frost    RIMEFROST VAULT: a vent breathes a line of frost
##   blade    THE HOLLOW THRONE: a blade sweeps to and fro along its groove

const KINDS := ["spikes", "thorns", "water", "fire", "frost", "blade"]
const NAME := { "spikes": "A SPIKE TRAP", "thorns": "A THORN TRAP", "water": "A SCALDING JET", "fire": "A FIRE JET",
	"frost": "A FROST JET", "blade": "A SWINGING BLADE" }
## A plate's or a jet's cycle: resting, warning, striking (seconds).
const REST := 2.2
const WARN := 0.7
const STRIKE := 0.7
const JET_LEN := 3       # tiles a jet reaches
const BLADE_AMP := 2.5   # tiles a blade sweeps to each side
const BLADE_SPEED := 1.9

## Lays a new fight room's traps (Game, with the hazards).
static func setup(room: Room, floor_index: int) -> void:
	room.traps = []
	if not GameData.rogues() or floor_index < 0 or floor_index >= KINDS.size():
		return
	if not room.theme.is_empty() or not room.type in ["combat", "elite", "challenge"]:
		return
	var kind: String = KINDS[floor_index]
	var n := 2 + randi() % 2 + (1 if floor_index >= 3 else 0)
	for i in n * 6:
		if room.traps.size() >= n:
			break
		var s := World.free_spot(room, G.player, 60, World.M_WALKER)
		var c := clampi(floori(s.x / TB.TS), TB.IX0 + 1, TB.IX0 + TB.IW - 2)
		var r := clampi(floori(s.y / TB.TS), TB.IY0 + 1, TB.IY0 + TB.IH - 2)
		if room.tile(c, r) != World.T_FLOOR or _near(room, c, r):
			continue
		var t := { "kind": kind, "c": c, "r": r, "t": randf() * (REST + WARN + STRIKE), "hit": {} }
		match kind:
			"water", "fire", "frost":
				var dirs := []
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var ok := true
					for k in range(1, JET_LEN + 1):
						if room.tile(c + d.x * k, r + d.y * k) != World.T_FLOOR:
							ok = false
					if ok:
						dirs.append(d)
				if dirs.is_empty():
					continue
				t["d"] = dirs[randi() % dirs.size()]
			"blade":
				var ok := true
				for k in range(-3, 4):
					if room.tile(c + k, r) != World.T_FLOOR:
						ok = false
				if not ok:
					continue
		room.traps.append(t)

## Not on top of another trap, and not in a doorway's way (the first tile inside each door).
static func _near(room: Room, c: int, r: int) -> bool:
	for t in room.traps:
		if absi(t["c"] - c) + absi(t["r"] - r) < 4:
			return true
	return (absi(c - 13) <= 1 or absi(c - 14) <= 1) and (r <= TB.IY0 + 1 or r >= TB.IY0 + TB.IH - 2) \
		or (r == 9 or r == 10) and (c <= TB.IX0 + 1 or c >= TB.IX0 + TB.IW - 2)

## The cycle's part: 0 resting, 1 warning, 2 striking.
static func phase(t: Dictionary) -> int:
	if t["kind"] == "blade":
		return 2
	var x: float = fmod(t["t"], REST + WARN + STRIKE)
	return 0 if x < REST else (1 if x < REST + WARN else 2)

## Where a blade is now.
static func blade_at(t: Dictionary) -> Vector2:
	return Vector2((t["c"] + 0.5 + sin(t["t"] * BLADE_SPEED) * BLADE_AMP) * TB.TS, (t["r"] + 0.5) * TB.TS)

## The tiles a trap hurts while it strikes.
static func _hits(t: Dictionary, x: float, y: float, rad: float) -> bool:
	var ts := float(TB.TS)
	match t["kind"]:
		"blade":
			return blade_at(t).distance_to(Vector2(x, y)) < 7.0 + rad
		"water", "fire", "frost":
			var d: Vector2i = t["d"]
			for k in range(1, JET_LEN + 1):
				var cx: float = (t["c"] + d.x * k + 0.5) * ts
				var cy: float = (t["r"] + d.y * k + 0.5) * ts
				if absf(x - cx) < ts * 0.5 + rad * 0.5 and absf(y - cy) < ts * 0.5 + rad * 0.5:
					return true
			return false
		_:
			return absf(x - (t["c"] + 0.5) * ts) < ts * 0.5 + rad * 0.4 and absf(y - (t["r"] + 0.5) * ts) < ts * 0.5 + rad * 0.4

## Every tick (Hazards.update).
static func tick(room: Room, dt: float) -> void:
	if room.traps.is_empty() or not G.enemies_active():
		return
	var p := G.player
	for t in room.traps:
		var before := phase(t)
		t["t"] += dt
		var now := phase(t)
		if now == 2 and before != 2 and t["kind"] != "blade":
			t["hit"] = {}
			Snd.play("hatchet" if t["kind"] in ["spikes", "thorns"] else "beam")
		if now != 2:
			continue
		if t["kind"] == "blade":
			for k in t["hit"].keys():
				t["hit"][k] -= dt
				if t["hit"][k] <= 0:
					t["hit"].erase(k)
		if _hits(t, p.x, p.y, p.r):
			Combat.hurt_player(1, NAME[t["kind"]], true)
		for e in G.enemies.duplicate():
			if not e.targetable() or t["hit"].has(e.uid) or e.boss != "":
				continue
			if _hits(t, e.x, e.y, e.r):
				t["hit"][e.uid] = 0.8
				Combat.damage_enemy(e, 12.0 * Combat.floor_scale(), { "no_crit": true, "no_mult": true,
					"col": { "water": "cyan", "frost": "cyan", "fire": "orange", "thorns": "green" }.get(t["kind"], "white") })

# ---------- drawing (the lower layer, over the floor) ----------
static func draw(ci: CanvasItem, t: float) -> void:
	var room := G.room
	if room == null or room.traps.is_empty():
		return
	var live := G.enemies_active()
	for tr in room.traps:
		var ph := phase(tr) if live else 0
		var x: float = tr["c"] * TB.TS
		var y: float = tr["r"] * TB.TS
		var k: float = fmod(tr["t"], REST + WARN + STRIKE)
		match tr["kind"]:
			"spikes", "thorns":
				_plate(ci, x, y, tr["kind"], ph, k, t)
			"water", "fire", "frost":
				_jet(ci, x, y, tr, ph, k, t)
			"blade":
				_blade(ci, tr, live, t)

static func _plate(ci: CanvasItem, x: float, y: float, kind: String, ph: int, k: float, t: float) -> void:
	var thorn := kind == "thorns"
	ci.draw_rect(Rect2(x + 1, y + 1, 14, 14), TB.c("#1c1a24" if not thorn else "#2a2016"))
	ci.draw_rect(Rect2(x + 1.5, y + 1.5, 13, 0.5), TB.ca("#8b8f9c" if not thorn else "#6b8f3a", 160))
	for i in 3:
		for j in 3:
			ci.draw_rect(Rect2(x + 3 + i * 4, y + 3 + j * 4, 2, 2), TB.c("#07050a"))
	var tip := TB.c("#e8dcc0" if not thorn else "#7fbf4a")
	var dark := TB.c("#8a7f66" if not thorn else "#3f6a2a")
	if ph == 1:
		var shake := 0.5 if floori(t * 30) % 2 == 0 else 0.0
		for i in 3:
			for j in 3:
				ci.draw_rect(Rect2(x + 3.5 + i * 4 + shake, y + 3 + j * 4, 1, 1), tip)
	elif ph == 2:
		var up := clampf((k - REST - WARN) / 0.08, 0.0, 1.0)
		for j in 3:
			for i in 3:
				var bx := x + 4 + i * 4
				var by := y + 5 + j * 4
				var h := 6.0 * up
				ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 1.5, by), Vector2(bx + 1.5, by), Vector2(bx, by - h)]), tip)
				ci.draw_line(Vector2(bx + 0.5, by), Vector2(bx, by - h), dark, 0.5)

static func _jet(ci: CanvasItem, x: float, y: float, tr: Dictionary, ph: int, k: float, t: float) -> void:
	var col: Color = { "water": TB.c("#6fd3e0"), "fire": TB.c("#e8873a"), "frost": TB.c("#c8f0ff") }[tr["kind"]]
	var core: Color = { "water": TB.c("#e8f6ff"), "fire": TB.c("#f2c94c"), "frost": TB.c("#ffffff") }[tr["kind"]]
	ci.draw_rect(Rect2(x + 2, y + 2, 12, 12), TB.c("#1c1a24"))
	ci.draw_rect(Rect2(x + 3, y + 3, 10, 10), TB.c("#2e2a3a"))
	for i in 4:
		ci.draw_rect(Rect2(x + 4 + i * 2.5, y + 4, 1, 8), TB.c("#07050a"))
	var d: Vector2i = tr["d"]
	var o := Vector2(x + 8, y + 8)
	if ph == 1:
		for i in 3:   # puffs creeping out the way it will blow
			var f := fmod(k - REST + i * 0.23, WARN) / WARN
			var at := o + Vector2(d) * (4 + f * 14)
			ci.draw_circle(at, 1.5 + f * 2.5, Color(col.r, col.g, col.b, 0.5 * (1.0 - f)), true, -1.0, false)
	elif ph == 2:
		var n := JET_LEN * 4
		for i in n:
			var f := float(i) / n
			var at := o + Vector2(d) * (6 + f * JET_LEN * TB.TS) + Vector2(sin(t * 30 + i) * 1.5, cos(t * 27 + i * 1.7) * 1.5) * f
			var r := 3.0 + f * 4.0
			ci.draw_circle(at, r, Color(col.r, col.g, col.b, 0.75 - f * 0.35), true, -1.0, false)
			ci.draw_circle(at, r * 0.45, Color(core.r, core.g, core.b, 0.85 - f * 0.5), true, -1.0, false)

static func _blade(ci: CanvasItem, tr: Dictionary, live: bool, t: float) -> void:
	var cy: float = (tr["r"] + 0.5) * TB.TS
	var x0: float = (tr["c"] + 0.5 - BLADE_AMP) * TB.TS
	var x1: float = (tr["c"] + 0.5 + BLADE_AMP) * TB.TS
	ci.draw_rect(Rect2(x0 - 4, cy - 1.5, x1 - x0 + 8, 3), TB.c("#140f1c"))   # its groove in the floor
	ci.draw_rect(Rect2(x0 - 4, cy - 1.5, x1 - x0 + 8, 0.5), TB.ca("#f2c94c", 120))
	var at := blade_at(tr) if live else Vector2((tr["c"] + 0.5) * TB.TS, cy)
	ci.draw_circle(at + Vector2(0, 4), 6.0, Color(0, 0, 0, 0.3), true, -1.0, false)
	var a := t * 18.0 if live else 0.0
	for i in 2:   # two crescents, spinning
		var b := a + i * PI
		ci.draw_arc(at, 6.5, b, b + 2.2, 10, TB.c("#e8e4f0"), 2.0, false)
		ci.draw_arc(at, 5.0, b + 0.2, b + 2.0, 8, TB.c("#8b8f9c"), 1.0, false)
	ci.draw_circle(at, 2.0, TB.c("#f2c94c"), true, -1.0, false)
