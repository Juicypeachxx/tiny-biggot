class_name Afx
extends RefCounted
## Attack effects: melee swings, beams, hit sparks, muzzle flashes, the marks a
## foe shows before it strikes, and the guardians' attacks.
##
## Drawing only, like Vfx, and switched by the same option (FANCY EFFECTS): it
## has its own random stream, nothing here is read by the rules, and the hooks
## in the rules use none of the game's random numbers.
##
## Cost is bounded: the flashes live in one small ring of slots, a tick starts
## only a few, and everything else is drawn straight from the game state with a
## handful of sprites and rectangles each.

const SLOTS := 28            # hit sparks, crit stars, cut marks, flashes, dust alive at once
const PER_TICK := 6          # new ones a tick
const K_HIT := 0
const K_CRIT := 1
const K_CUT := 2             # turned to the blow
const K_MUZZLE := 3          # turned to the aim
const K_CAST := 4
const K_DUST := 5
const STRIPS := ["fx_hit", "fx_crit", "fx_cut", "fx_muzzle", "fx_cast", "fx_dust"]
const LIFE := [7, 11, 8, 6, 9, 15]      # ticks
const DEAD := 255

## What an enemy shot's flash is coloured, by sprite.
const SHOT_COL := { "red": "#ff8a8a", "redBig": "#ff8a8a", "bone": "#f4ecd8", "water": "#6fd3e0", "ice": "#c8f0ff",
	"iceBig": "#c8f0ff", "spore": "#b8e05a", "dark": "#e8c8ff", "darkBig": "#e8c8ff", "fire": "#f2c94c",
	"fireBig": "#f2c94c", "cyan": "#c8f0ff", "page": "#f4ecd8" }
## A guardian's own colour: its circle while it casts, its lanes and beams.
const BOSS_COL := { "colossus": "#d9d0b4", "sporemother": "#b8e05a", "librarian": "#6fd3e0", "tyrant": "#e8873a",
	"rimewarden": "#c8f0ff", "regent": "#a35bd6", "bogmatriarch": "#b8e05a", "ashwarlord": "#e8873a",
	"frozenabbot": "#c8f0ff", "crowking": "#a35bd6", "umbralsun": "#e86fb4", "judge": "#f2c94c", "cinderking": "#e8873a", "unwritten": "#f4ecd8", "holycow": "#f4ecd8",
	"stormcrown": "#6fd3e0", "bilgehydra": "#b8e05a", "brassorgan": "#e8873a" }
## States in which a guardian stands and casts: it gets a turning circle under it.
const CASTING := [&"ring", &"volley", &"spiral", &"burst", &"cloud", &"pages", &"tide", &"freeze", &"hail", &"shards",
	&"sweep", &"embers", &"curtain", &"bogspit", &"arrowrain", &"gunline", &"eclipse", &"summon",
	&"halo", &"verdict", &"brimstone", &"hellgate", &"ink", &"rewrite",
	&"moo", &"milkrain", &"udder", &"holyfire", &"stampede"]   # ROADMAP 4.7 part C (verdict and brimstone also show their lanes and rings)

static var _rng := RandomNumberGenerator.new()
static var _head := 0
static var _made := 0
static var _kind := PackedByteArray()
static var _age := PackedByteArray()
static var _x := PackedFloat32Array()
static var _y := PackedFloat32Array()
static var _rot := PackedFloat32Array()
static var _col := PackedColorArray()
static var _live := 0            # flashes alive (so an empty frame costs nothing)
## The foes that show a mark this tick (a guardian, a foe winding up or aiming, one with beams):
## found in one pass a tick, so the painters never walk the whole crowd.
static var _marked: Array[Enemy] = []
## Swings alternate direction. Which way each live swing goes is decided the tick it appears and
## kept (it must not depend on the clock, which runs on while a hit freezes the swing).
static var _swings: Array = []           # the swings seen last tick
static var _flips: Array = []            # for each, true = mirrored
static var _swing_n := 0

static var C_RED := Color.html("#d8443c")
static var C_WARN := Color.html("#ff8a8a")
static var C_WHITE := Color(1, 1, 1)

static func reset() -> void:
	if _age.size() != SLOTS:
		_kind.resize(SLOTS)
		_age.resize(SLOTS)
		_x.resize(SLOTS)
		_y.resize(SLOTS)
		_rot.resize(SLOTS)
		_col.resize(SLOTS)
	_age.fill(DEAD)
	_head = 0
	_made = 0
	_live = 0
	_marked.clear()
	_swings.clear()
	_flips.clear()

## Flashes alive right now.
static func live() -> int:
	return _live

static func _add(kind: int, x: float, y: float, rot: float, col: Color) -> void:
	if not Vfx.enabled or _made >= PER_TICK:
		return
	if _age.size() != SLOTS:
		reset()
	_made += 1
	var i := _head
	_head = (_head + 1) % SLOTS
	if _age[i] == DEAD:
		_live += 1
	_kind[i] = kind
	_age[i] = 0
	_x[i] = x
	_y[i] = y
	_rot[i] = rot
	_col[i] = col

# ---------- Called by the rules (each is one line there, and uses no game random numbers) ----------
## The colour of a shot's glow: its family's, or the plain one of its kind.
static var _glow_cols := {}
static func shot_col(kind: String, tag: String) -> Color:
	if tag == "" or tag == "core":
		tag = ShotBatch.PLAIN_TAG.get(kind, "none")
	var c = _glow_cols.get(tag)
	if c == null:
		c = TB.c(Weapons.TAG_COLS[tag][0]) if Weapons.TAG_COLS.has(tag) else TB.c("#6fd3e0")
		_glow_cols[tag] = c
	return c

## A shot lands on a foe: a small star in the weapon's colour.
static func hit(x: float, y: float, tag: String) -> void:
	if Vfx.enabled:
		_add(K_HIT, x, y, 0.0, TB.c(Weapons.TAG_COLS[tag][2]) if Weapons.TAG_COLS.has(tag) else C_WHITE)

## A critical hit: a bigger gold star.
static func crit(x: float, y: float) -> void:
	_add(K_CRIT, x, y, 0.0, C_WHITE)

## A blade lands on a foe: a cut mark across it, turned to the blow (along = a thrust).
static func cut(x: float, y: float, a: float, along: bool) -> void:
	if Vfx.enabled:
		_add(K_CUT, x, y - 2.0, a + (0.0 if along else PI * 0.5) + _rng.randf_range(-0.45, 0.45), C_WHITE)

## A volley of enemy shots leaves here: a ring flash in the shots' colour.
static func cast(x: float, y: float, spr: String) -> void:
	if Vfx.enabled:
		_add(K_CAST, x, y, 0.0, TB.c(SHOT_COL.get(spr, "#ff8a8a")))

## Something heavy lands or crashes: dust along the floor.
static func dust(x: float, y: float) -> void:
	_add(K_DUST, x, y, 0.0, C_WHITE)

## A guardian blinks out or in: a void burst.
static func warp(x: float, y: float) -> void:
	if Vfx.enabled:
		Vfx._play("fx_blast_m_void", x, y - 4.0, 0.3)
		Vfx._glow(x, y - 4.0, 40.0, 10, TB.c("#a35bd6"))

# ---------- Per logic tick (called from Juice.update) ----------
static func update(p: Player, fired: bool) -> void:
	_made = 0
	if _age.size() != SLOTS:
		reset()
	if _live > 0:
		for i in SLOTS:
			if _age[i] != DEAD:
				_age[i] += 1
				if _age[i] >= LIFE[_kind[i]]:
					_age[i] = DEAD
					_live -= 1
	# Swings that began this tick take the next direction; the others keep theirs.
	if not (G.swings.is_empty() and _swings.is_empty()):
		var flips := []
		for w in G.swings:
			var at := _seen(w)
			if at >= 0:
				flips.append(_flips[at])
			else:
				flips.append((_swing_n & 1) == 1)
				_swing_n += 1
		_swings = G.swings.duplicate()
		_flips = flips
	_marked.clear()
	if Vfx.enabled:
		for e: Enemy in G.enemies:
			if e.boss != "" or e.has_telegraph or e.state == &"tele" or not e.beams.is_empty():
				if e.hp > 0 and e.spawn_t <= 0.0:
					_marked.append(e)
	# The hero's weapon just fired a shot: a flash at the muzzle, in the weapon's colour.
	if fired and Vfx.enabled and p != null and p.weapon != null:
		var kind: String = p.weapon["kind"]
		if not kind in ["slash", "thrust", "whip", "beam", "zap", "mine", "pulse"]:
			var tags: Array = p.weapon["tags"]
			var col: Color = TB.c(Weapons.TAG_COLS[tags[0]][2]) if tags.size() > 0 and Weapons.TAG_COLS.has(tags[0]) else C_WHITE
			_add(K_MUZZLE, p.x + cos(p.aim_a) * 9.0, p.y - 2.0 + sin(p.aim_a) * 9.0, p.aim_a, col)

## Where a swing sits among the ones update() saw, or -1.
static func _seen(w: Dictionary) -> int:
	for j in _swings.size():
		if is_same(_swings[j], w):
			return j
	return -1

## Whether a swing is drawn mirrored. It is looked up by the swing itself, not by its place in
## the game's list: the game drops finished swings from that list after update() has seen it, so
## the places shift. A swing update() has not seen yet (the unseen-th such in the list, counted
## from 0) gets the direction update() is about to give it.
static func mirrored(w: Dictionary, unseen: int) -> bool:
	return _mirrored_at(_seen(w), unseen)

static func _mirrored_at(at: int, unseen: int) -> bool:
	if at >= 0:
		return _flips[at]
	return ((_swing_n + unseen) & 1) == 1

# ---------- Drawing ----------
## The flashes: over the shots, with the melee swings.
static func draw_flashes(ci: CanvasItem) -> void:
	if _live <= 0 or _age.size() != SLOTS:
		return
	var turned := false
	for i in SLOTS:
		var age := _age[i]
		if age == DEAD:
			continue
		var k := _kind[i]
		var s := Vfx._strip(STRIPS[k])
		var w: int = s[1]
		var h: int = s[2]
		var f := mini(int(s[3]) - 1, age * int(s[3]) / LIFE[k])
		if k == K_CUT or k == K_MUZZLE:
			ci.draw_set_transform(Vector2(roundf(_x[i]), roundf(_y[i])), _rot[i], Vector2.ONE)
			turned = true
			var ox := 1.0 if k == K_MUZZLE else w * 0.5     # a muzzle flash starts at the barrel
			ci.draw_texture_rect_region(s[0], Rect2(-ox, -h * 0.5, w, h), Rect2(f * w, 0, w, h), _col[i])
		else:
			if turned:
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				turned = false
			ci.draw_texture_rect_region(s[0], Rect2(roundf(_x[i] - w * 0.5), roundf(_y[i] - h * 0.5), w, h),
				Rect2(f * w, 0, w, h), _col[i])
	if turned:
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Melee swings and the hero's beam (replaces the plain arcs and bars).
static func draw_swings(ci: CanvasItem, t: float) -> void:
	var unseen := 0
	for w in G.swings:
		var k: float = w["t"] / w["max"]          # 1 when it starts, 0 when it ends
		var tag: String = w["tag"] if w["tag"] != "" else "core"
		var cols: Array = Weapons.TAG_COLS.get(tag, Weapons.TAG_COLS["core"])
		var main: Color = TB.c(cols[0])
		var light: Color = TB.c(cols[2])
		var bright := main.lerp(light, 0.5)      # a swing is drawn brighter than the family colour, to stand off the floor
		var x: float = w["x"]
		var y: float = w["y"]
		var a: float = w["a"]
		# Which way this swing goes (decided when it appeared; see update and mirrored).
		var at := _seen(w)
		var flip := -1.0 if _mirrored_at(at, unseen) else 1.0
		if at < 0:
			unseen += 1
		match w["kind"]:
			"slash":
				# A smear: the blade's path as a crescent, white-hot on its outer rim.
				var body := Vfx._strip("swing_slash")
				var edge := Vfx._strip("swing_slash_edge")
				var f := clampi(int((1.0 - k) * 4.0), 0, 3)
				var z: float = w["r"] / 22.5
				var zy: float = z * w["arc"] / deg_to_rad(140.0) * flip
				ci.draw_set_transform(Vector2(roundf(x), roundf(y)), a, Vector2(z, zy))
				ci.draw_texture_rect_region(body[0], Rect2(-24, -24, 48, 48), Rect2(f * 48, 0, 48, 48), bright)
				ci.draw_texture_rect_region(edge[0], Rect2(-24, -24, 48, 48), Rect2(f * 48, 0, 48, 48), C_WHITE)
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"thrust":
				# A lance of light with a white core and a flare at the point.
				var s := Vfx._strip("swing_thrust")
				var f := clampi(int((1.0 - k) * 3.0), 0, 2)
				var ln: float = w["len"]
				var wide := clampf(float(w["width"]) / 6.0, 1.0, 2.2)
				ci.draw_set_transform(Vector2(roundf(x), roundf(y)), a, Vector2(ln * 1.04 / 48.0, wide))
				ci.draw_texture_rect_region(s[0], Rect2(0, -5.5, 48, 11), Rect2(f * 48, 0, 48, 11), bright)
				ci.draw_set_transform(Vector2(roundf(x), roundf(y)), a, Vector2.ONE)
				ci.draw_rect(Rect2(ln * 0.25, -0.5, ln * 0.72, 1.0), Color(1, 1, 1, minf(1.0, k * 1.6)))
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				if k > 0.35:
					_flare(ci, x + cos(a) * ln, y + sin(a) * ln, int(t * 30.0), light)
			"whip":
				# A lash that snaps: the wave runs out to the tip, and the tip cracks.
				var s := Vfx._strip("swing_whip")
				var f := clampi(int((1.0 - k) * 3.0), 0, 2)
				var ln: float = w["len"]
				ci.draw_set_transform(Vector2(roundf(x), roundf(y)), a, Vector2(ln / 64.0, flip))
				ci.draw_texture_rect_region(s[0], Rect2(0, -8.5, 64, 17), Rect2(f * 64, 0, 64, 17), bright)
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				if k > 0.3:
					_flare(ci, x + cos(a) * ln, y + sin(a) * ln, int(t * 30.0), C_WHITE)
			"beam":
				_beam(ci, x, y, a, w["len"], t, 5.0, TB.c(cols[1]), main, light, 220.0)
	draw_flashes(ci)

## A flickering point of light (the four frames of fx_flare).
static func _flare(ci: CanvasItem, x: float, y: float, frame: int, col: Color) -> void:
	var s := Vfx._strip("fx_flare")
	var w: int = s[1]
	ci.draw_texture_rect_region(s[0], Rect2(roundf(x) - w / 2, roundf(y) - w / 2, w, w), Rect2((frame & 3) * w, 0, w, w), col)

## A beam: a dark sheath, the colour, a white core, pulses of light running along it,
## and a flare at each end. width is the whole width of the sheath.
static func _beam(ci: CanvasItem, x: float, y: float, a: float, ln: float, t: float, width: float,
		dark: Color, main: Color, light: Color, speed: float) -> void:
	var tick := int(t * 60.0)
	var wob := 1.0 if (tick & 2) == 0 else 0.0           # the beam breathes: a pixel wider every other pair of ticks
	var half := width * 0.5 + wob
	ci.draw_set_transform(Vector2(roundf(x), roundf(y)), a, Vector2.ONE)
	ci.draw_rect(Rect2(0, -half, ln, half * 2.0), Color(dark.r, dark.g, dark.b, 0.6))
	ci.draw_rect(Rect2(0, -half * 0.62, ln, half * 1.24), main)
	ci.draw_rect(Rect2(0, -maxf(0.5, half * 0.22), ln, maxf(1.0, half * 0.44)), C_WHITE)
	# Pulses of light that run out along the beam.
	var gap := maxf(24.0, ln / 4.0)
	var d := fmod(t * speed, gap)
	while d < ln - 4.0:
		ci.draw_rect(Rect2(d, -half, 4.0, half * 2.0), Color(light.r, light.g, light.b, 0.75))
		d += gap
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_flare(ci, x + cos(a) * 3.0, y + sin(a) * 3.0, tick / 2, light)
	_flare(ci, x + cos(a) * ln, y + sin(a) * ln, tick / 2 + 1, C_WHITE)

## The additive layer: a soft band along the hero's beam and a bloom on a fresh slash.
static func draw_glow(ci: CanvasItem) -> void:
	for w in G.swings:
		var tag: String = w["tag"] if w["tag"] != "" else "core"
		var c: Color = TB.c(Weapons.TAG_COLS.get(tag, Weapons.TAG_COLS["core"])[0])
		if w["kind"] == "beam":
			ci.draw_set_transform(Vector2(roundf(w["x"]), roundf(w["y"])), w["a"], Vector2.ONE)
			ci.draw_rect(Rect2(0, -5.0, w["len"], 10.0), Color(c.r, c.g, c.b, 0.16))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif w["kind"] == "slash":
			var k: float = w["t"] / w["max"]
			if k > 0.4:
				var r: float = w["r"]
				var tex := Img.t("glow_white")
				ci.draw_texture_rect(tex, Rect2(roundf(w["x"] + cos(w["a"]) * r * 0.6 - r), roundf(w["y"] + sin(w["a"]) * r * 0.6 - r),
					r * 2.0, r * 2.0), false, Color(c.r, c.g, c.b, 0.35 * k))
	for e in _marked:
		if not e.beams.is_empty() and e.sub == 2 and e.hp > 0:
			var c: Color = TB.c(BOSS_COL.get(e.boss, "#a35bd6"))
			for ba in e.beams:
				ci.draw_set_transform(Vector2(roundf(e.x), roundf(e.y - 4.0)), ba, Vector2.ONE)
				ci.draw_rect(Rect2(0, -12.0, 520.0, 24.0), Color(c.r, c.g, c.b, 0.2))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ---------- The marks a foe shows before it strikes, and the guardians (drawn from the game state) ----------
## How far a straight path runs from (x, y) before a wall: steps of 8 px, then the last step to the pixel.
static func _reach(x: float, y: float, a: float, most: float, mode: int) -> float:
	var room := G.room
	var dx := cos(a)
	var dy := sin(a)
	var d := 8.0
	while d < most:
		if World.solid(room, floori((x + dx * d) / TB.TS), floori((y + dy * d) / TB.TS), mode):
			var back := d - 8.0
			while back < d - 1.0:
				back += 1.0
				if World.solid(room, floori((x + dx * back) / TB.TS), floori((y + dy * back) / TB.TS), mode):
					return back - 1.0
			return d - 1.0
		d += 8.0
	return most

## The warning pictures, for the rift bosses (scripts/entities/rift_bosses.gd).
static func reach(x: float, y: float, a: float, most: float, mode: int) -> float:
	return _reach(x, y, a, most, mode)

static func lane(ci: CanvasItem, x: float, y: float, a: float, half: float, ln: float, k: float, col: Color, t: float) -> void:
	_lane(ci, x, y, a, half, ln, k, col, t)

static func landing(ci: CanvasItem, x: float, y: float, r: float, k: float, col: Color, t: float) -> void:
	_landing(ci, x, y, r, k, col, t)

static func circle(ci: CanvasItem, x: float, y: float, r: float, col: Color, t: float, a: float) -> void:
	_circle(ci, x, y, r, col, t, a)

## A charge lane on the floor: where the foe is about to run. It fills from the foe outward
## as the wind-up ends (k from 0 to 1), with chevrons marching along it.
static func _lane(ci: CanvasItem, x: float, y: float, a: float, half: float, ln: float, k: float, col: Color, t: float) -> void:
	ci.draw_set_transform(Vector2(roundf(x), roundf(y)), a, Vector2.ONE)
	ci.draw_rect(Rect2(0, -half, ln, half * 2.0), Color(col.r, col.g, col.b, 0.13))
	ci.draw_rect(Rect2(0, -half, ln * clampf(k, 0.0, 1.0), half * 2.0), Color(col.r, col.g, col.b, 0.2))
	var edge := Color(col.r, col.g, col.b, 0.85)
	ci.draw_rect(Rect2(0, -half, ln, 1.0), edge)
	ci.draw_rect(Rect2(0, half - 1.0, ln, 1.0), edge)
	ci.draw_rect(Rect2(ln - 1.0, -half, 1.0, half * 2.0), edge)
	var step := 26.0
	var q := 10.0 + fmod(t * 70.0, step)
	var arm := minf(4.0, half - 2.0)
	var chev := Color(col.r, col.g, col.b, 0.7)
	while q < ln - 4.0:
		var j := 0.0
		while j <= arm:
			ci.draw_rect(Rect2(q - j, -j - 1.0, 2.0, 1.0), chev)
			ci.draw_rect(Rect2(q - j, j, 2.0, 1.0), chev)
			j += 1.0
		q += step
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Where something is about to land: a ring on the floor that fills as it comes (k from 0 to 1).
static func _landing(ci: CanvasItem, x: float, y: float, r: float, k: float, col: Color, t: float) -> void:
	ci.draw_set_transform(Vector2(roundf(x), roundf(y)), 0.0, Vector2(1.0, 0.6))
	ci.draw_circle(Vector2.ZERO, r * clampf(k, 0.05, 1.0), Color(col.r, col.g, col.b, 0.2))
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.9), 1.0)
	if int(t * 16.0) % 2 == 0:
		ci.draw_arc(Vector2.ZERO, r - 3.0, 0.0, TAU, 20, Color(col.r, col.g, col.b, 0.45), 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## The circle under a guardian while it casts: two rings and marks that turn.
static func _circle(ci: CanvasItem, x: float, y: float, r: float, col: Color, t: float, a: float) -> void:
	ci.draw_set_transform(Vector2(roundf(x), roundf(y)), 0.0, Vector2(1.0, 0.55))
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color(col.r, col.g, col.b, 0.75 * a), 1.0)
	ci.draw_arc(Vector2.ZERO, r - 4.0, 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.4 * a), 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for j in 6:
		var ang := t * 1.6 + j * TAU / 6.0
		ci.draw_rect(Rect2(roundf(x + cos(ang) * (r - 2.0)) - 1.0, roundf(y + sin(ang) * (r - 2.0) * 0.55) - 1.0, 3, 3),
			Color(col.r, col.g, col.b, a))
		var back := -t * 2.3 + j * TAU / 6.0
		ci.draw_rect(Rect2(roundf(x + cos(back) * (r - 8.0)), roundf(y + sin(back) * (r - 8.0) * 0.55), 2, 2),
			Color(1, 1, 1, 0.7 * a))

## On the floor, under the fighters: charge lanes, landing rings, casting circles.
static func draw_ground(ci: CanvasItem, t: float) -> void:
	for e in _marked:
		if e.hp <= 0 or e.spawn_t > 0.0:
			continue
		var st := e.state
		if e.boss != "":
			if e.hidden:
				continue
			var col: Color = TB.c(BOSS_COL.get(e.boss, "#d8443c"))
			if st == &"charge":
				if e.has_telegraph:
					_lane(ci, e.x, e.y, e.telegraph, e.r + 3.0, _reach(e.x, e.y, e.telegraph, 352.0, World.M_FLYER),
						e.st / 0.55, C_WARN, t)
			elif (st == &"slam" or st == &"palms") and e.sub == 1:
				_landing(ci, e.to.x, e.to.y + e.r * 0.5, e.r + 12.0, e.st / (0.7 if st == &"slam" else 0.45), C_WARN, t)
			elif st in CASTING:
				_circle(ci, e.x, e.y + e.r * 0.6, e.r + 14.0, col, t, clampf(e.st * 4.0, 0.0, 1.0))
		elif st == &"tele":
			# A knight or a champion about to charge.
			var a := e.telegraph if e.has_telegraph else e.ca
			var left := clampf(e.st / 0.6, 0.0, 1.0)
			_lane(ci, e.x, e.y, a, e.r + 2.0, _reach(e.x, e.y, a, 184.0, World.M_WALKER), 1.0 - left, C_WARN, t)

## Over the fighters: aiming lines and the guardians' beams (replaces the dotted lines and plain bars).
static func draw_marks(ci: CanvasItem, t: float) -> void:
	if _marked.is_empty():
		return
	var blink := int(t * 30.0) % 2 == 0
	for e in _marked:
		if e.hp <= 0 or e.spawn_t > 0.0:
			continue
		if e.has_telegraph and e.state == &"aim":
			# A marksman's line of sight: it steadies and brightens as the shot comes.
			var a := e.telegraph
			var ln := _reach(e.x, e.y - 2.0, a, 330.0, World.M_BULLET)
			var k := 1.0 - clampf(e.st / 0.55, 0.0, 1.0)
			ci.draw_set_transform(Vector2(roundf(e.x), roundf(e.y - 2.0)), a, Vector2.ONE)
			if blink:
				ci.draw_rect(Rect2(8.0, -1.5, ln - 8.0, 3.0), Color(C_RED.r, C_RED.g, C_RED.b, 0.1 + 0.15 * k))
			ci.draw_rect(Rect2(8.0, -0.5, ln - 8.0, 1.0), Color(C_WARN.r, C_WARN.g, C_WARN.b, 0.4 + 0.5 * k))
			ci.draw_rect(Rect2(ln - 2.0, -1.5, 3.0, 3.0), Color(1, 1, 1, 0.5 + 0.5 * k))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if e.beams.is_empty():
			continue
		var col: Color = TB.c(BOSS_COL.get(e.boss, "#a35bd6"))
		var ox := e.x
		var oy := e.y - 4.0
		if e.sub == 2:
			# The beams fire: as wide as what they hit (7 px either side).
			for ba in e.beams:
				_beam(ci, ox, oy, ba, 520.0, t, 14.0, col, Color(0.91, 0.78, 1.0), C_WHITE, 420.0)
		else:
			# They gather: a thin line that thickens, and motes drawn in to the guardian.
			var k := clampf(e.st / 0.85, 0.0, 1.0)
			for ba in e.beams:
				ci.draw_set_transform(Vector2(roundf(ox), roundf(oy)), ba, Vector2.ONE)
				ci.draw_rect(Rect2(0, -7.0, 520.0, 14.0), Color(col.r, col.g, col.b, 0.07 + 0.08 * k))
				if blink or k > 0.75:
					ci.draw_rect(Rect2(0, -0.5 - k, 520.0, 1.0 + 2.0 * k), Color(col.r, col.g, col.b, 0.45 + 0.5 * k))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for j in 8:
				var ang := j * TAU / 8.0 + t * 4.0
				var rad := (1.0 - k) * 34.0 + 6.0
				ci.draw_rect(Rect2(roundf(ox + cos(ang) * rad), roundf(oy + sin(ang) * rad), 2, 2), Color(1, 1, 1, 0.4 + 0.6 * k))
