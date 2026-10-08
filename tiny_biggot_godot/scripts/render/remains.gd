class_name Remains
extends RefCounted
## 21.2 ROOMS THAT KEEP THEIR STORY (his word, 8 Oct: "make game more alive"). Expanded game only,
## drawing only (own dice; nothing here touches the run's random numbers or its rules).
##   remains   a fallen foe leaves something of itself: bones, a puddle of goo, a splash of ink,
##             a heap of ash with embers, torn paper, feathers, scrap, a fading glow; a guardian
##             leaves a big one. They stay with the room (come back and they are there) and fade
##             slowly: LIFE seconds, the last FADE of them going pale.
##   scorch    a big blast leaves a black mark on the floor.
## Both are drawn with the doors and pots (world_view's dyn layer, redrawn only when something
## changes); tick() looks once a second for one that has faded a step or gone.

const LIFE := 45.0
const FADE := 12.0
const SCORCH_LIFE := 60.0
const MAX := 40
const MAX_SCORCH := 20

## family -> words in a foe's type that put it in that family (the first match wins).
const FAMILY := [
	["bones", ["skel", "bone", "skull", "osse", "crypt", "colossus", "raised"]],
	["ink", ["ink", "smudge", "quill", "scrawl", "nib", "blot", "scribe", "letter", "comma", "word", "definer", "thesaurus",
		"asterisk", "obelus", "ibid", "citation", "print", "colophon", "lexic", "errat"]],
	["paper", ["page", "book", "card", "paper", "folio", "endpaper", "mark", "mimic", "shelf", "clasp", "spine", "gild", "overdue"]],
	["ash", ["imp", "ember", "cinder", "ash", "soot", "fire", "flame", "torch", "lava", "magma", "coal", "poker", "kindling", "hearth"]],
	["feathers", ["bat", "crow", "gnat", "harpy", "moth", "bird", "kite", "heron", "wing", "owl", "wasp"]],
	["scrap", ["golem", "knight", "cog", "gear", "steam", "brass", "rivet", "clock", "drone", "chrome", "robo", "turret", "engine",
		"guard", "bookend", "spectacle", "warden", "captain"]],
	["ecto", ["ghost", "wisp", "spirit", "shade", "wraith", "phantom", "shush", "quiet", "specter", "glitch", "static"]],
	["goo", ["slime", "ooze", "goo", "bog", "mire", "sludge", "blob", "jelly", "drown", "spore", "mushroom", "toad"]],
]

static var _t := 0.0
static var _rng := RandomNumberGenerator.new()

static func on() -> bool:
	return GameData.rogues() and G.room != null and G.room.type != "camp"

static func family(type: String) -> String:
	for f in FAMILY:
		for w in f[1]:
			if type.contains(w):
				return f[0]
	return "splat"

## Combat.kill_enemy: something of the foe stays on the floor.
static func add(e: Enemy) -> void:
	if not on() or e.type == "dummy" or e.hidden or e.d.get("rival", false):
		return   # (21.4: a rival who gives up runs off)
	var room := G.room
	var big: bool = e.is_boss() or e.d.get("mini", false)
	var col: String = GameData.SPRITE_COLOR.get(e.boss if e.is_boss() else e.type, "#6b4a4a")
	room.remains.append({ "x": e.x, "y": e.y, "kind": family(e.boss if e.is_boss() else e.type), "col": col,
		"t0": G.time, "seed": e.uid * 7919 + 13, "big": big, "step": 0 })
	if room.remains.size() > MAX:
		room.remains.pop_front()
	G.dyn_dirty = true

## Combat.explode_at: a big blast marks the floor.
static func scorch(x: float, y: float, r: float) -> void:
	if not on() or r < 20.0:
		return
	var room := G.room
	room.scorch.append({ "x": x, "y": y, "r": minf(r * 0.6, 34.0), "t0": G.time, "step": 0 })
	if room.scorch.size() > MAX_SCORCH:
		room.scorch.pop_front()
	G.dyn_dirty = true

## Every tick of play: once a second, drop what is gone and redraw what has faded a step.
static func tick(dt: float) -> void:
	_t -= dt
	if _t > 0.0 or G.room == null:
		return
	_t = 1.0
	var room := G.room
	var changed := false
	for list in [[room.remains, LIFE], [room.scorch, SCORCH_LIFE]]:
		var arr: Array = list[0]
		var life: float = list[1]
		for i in range(arr.size() - 1, -1, -1):
			var r: Dictionary = arr[i]
			var age: float = G.time - r["t0"]
			if age >= life:
				arr.remove_at(i)
				changed = true
				continue
			var step := clampi(int((age - (life - FADE)) / (FADE / 4.0)) + 1, 0, 4) if age > life - FADE else 0
			if step != r["step"]:
				r["step"] = step
				changed = true
	if changed:
		G.dyn_dirty = true

# ---------- Drawing (the dyn layer) ----------
static func paint(ci: CanvasItem, room: Room) -> void:
	if room == null or (room.remains.is_empty() and room.scorch.is_empty()):
		return
	for s in room.scorch:
		var a: float = 1.0 - s["step"] * 0.22
		var c := Vector2(s["x"], s["y"])
		ci.draw_circle(c, s["r"], Color(0.05, 0.03, 0.03, 0.32 * a))
		ci.draw_circle(c, s["r"] * 0.6, Color(0.04, 0.02, 0.02, 0.3 * a))
		for k in 6:
			var ang: float = k * 1.047 + s["x"] * 0.01
			ci.draw_line(c + Vector2.from_angle(ang) * s["r"] * 0.5, c + Vector2.from_angle(ang) * s["r"] * 1.15, Color(0.06, 0.04, 0.03, 0.28 * a), 1.0)
	for r in room.remains:
		_one(ci, r)

static func _one(ci: CanvasItem, r: Dictionary) -> void:
	_rng.seed = r["seed"]
	var a: float = 1.0 - r["step"] * 0.22
	var x: float = r["x"]
	var y: float = r["y"]
	var z := 2.0 if r["big"] else 1.0
	var col := TB.c(r["col"])
	match r["kind"]:
		"bones":
			for k in 2 + int(z):
				var p := Vector2(x + _rng.randf_range(-6, 6) * z, y + _rng.randf_range(-3, 3) * z)
				var d := Vector2.from_angle(_rng.randf() * TAU) * 3.0 * z
				ci.draw_line(p - d, p + d, Color(0.9, 0.87, 0.78, 0.9 * a), 1.0)
				ci.draw_rect(Rect2(p - d - Vector2(1, 1), Vector2(2, 2)), Color(0.95, 0.92, 0.85, 0.9 * a))
				ci.draw_rect(Rect2(p + d - Vector2(1, 1), Vector2(2, 2)), Color(0.95, 0.92, 0.85, 0.9 * a))
			ci.draw_circle(Vector2(x + 3 * z, y - 1), 2.0 * z, Color(0.92, 0.89, 0.8, 0.95 * a))
			ci.draw_rect(Rect2(x + 2 * z, y - 1.5 * z, 1, 1), Color(0.1, 0.08, 0.1, a))
		"goo":
			for k in 4:
				ci.draw_circle(Vector2(x + _rng.randf_range(-5, 5) * z, y + _rng.randf_range(-2, 2) * z), _rng.randf_range(2, 4) * z,
					Color(col.r, col.g, col.b, 0.45 * a))
			ci.draw_rect(Rect2(x - 2, y - 2, 2, 1), Color(1, 1, 1, 0.35 * a))
		"ink":
			ci.draw_circle(Vector2(x, y), 4.0 * z, Color(0.06, 0.06, 0.12, 0.6 * a))
			for k in 6:
				ci.draw_circle(Vector2(x + _rng.randf_range(-9, 9) * z, y + _rng.randf_range(-5, 5) * z), _rng.randf_range(0.8, 1.8) * z,
					Color(0.06, 0.06, 0.12, 0.55 * a))
		"ash":
			ci.draw_circle(Vector2(x, y), 3.5 * z, Color(0.22, 0.2, 0.22, 0.55 * a))
			ci.draw_circle(Vector2(x - 2 * z, y - 1), 2.0 * z, Color(0.42, 0.4, 0.42, 0.45 * a))
			for k in 3:
				ci.draw_rect(Rect2(x + _rng.randf_range(-4, 4) * z, y + _rng.randf_range(-2, 2) * z, 1, 1), Color(1.0, 0.45, 0.15, 0.8 * a))
		"paper":
			for k in 3 + int(z):
				var p := Vector2(x + _rng.randf_range(-7, 7) * z, y + _rng.randf_range(-4, 4) * z)
				var d := Vector2.from_angle(_rng.randf() * TAU)
				var q := Vector2(-d.y, d.x)
				ci.draw_colored_polygon(PackedVector2Array([p - d * 2.5 - q * 1.5, p + d * 2.5 - q * 1.5, p + d * 2.0 + q * 1.5, p - d * 2.5 + q * 1.2]),
					Color(0.93, 0.9, 0.82, 0.75 * a))
		"feathers":
			for k in 4:
				var p := Vector2(x + _rng.randf_range(-6, 6) * z, y + _rng.randf_range(-3, 3) * z)
				var d := Vector2.from_angle(_rng.randf() * TAU) * 2.5
				ci.draw_line(p - d, p + d, Color(col.r, col.g, col.b, 0.85 * a), 1.0)
				ci.draw_rect(Rect2(p + d, Vector2(1, 1)), Color(col.lightened(0.3).r, col.lightened(0.3).g, col.lightened(0.3).b, 0.8 * a))
		"scrap":
			for k in 3 + int(z):
				ci.draw_rect(Rect2(x + _rng.randf_range(-6, 6) * z, y + _rng.randf_range(-3, 3) * z, 2, 2), Color(0.55, 0.56, 0.6, 0.85 * a))
			ci.draw_circle(Vector2(x, y), 2.0 * z, Color(0.42, 0.43, 0.48, 0.9 * a), false, 1.0)
		"ecto":
			ci.draw_circle(Vector2(x, y), 5.0 * z, Color(0.6, 0.95, 1.0, 0.14 * a))
			ci.draw_circle(Vector2(x, y), 2.5 * z, Color(0.8, 1.0, 1.0, 0.16 * a))
		_:
			var dk := col.darkened(0.45)
			ci.draw_circle(Vector2(x, y), 3.5 * z, Color(dk.r, dk.g, dk.b, 0.55 * a))
			for k in 4:
				ci.draw_circle(Vector2(x + _rng.randf_range(-7, 7) * z, y + _rng.randf_range(-4, 4) * z), 1.0 * z, Color(dk.r, dk.g, dk.b, 0.5 * a))
