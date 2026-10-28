class_name Weather
extends RefCounted
## 22.1 WEATHER AND NIGHT IN THE DUNGEON (his word, 8 Oct: "4"). Expanded game only, drawing only:
## every floor after the first may have weather of its own, rolled with dice of its own when the
## floor begins (so a seeded run looks the same each time, and the run's dice are never moved).
##   rain   rain falling and rings on the floor; the place sounds of rain
##   storm  wind-driven rain and lightning (RoomDress's flashes)
##   fog    banks of fog drift across the rooms (the fog of Ashfall Town)
##   snow   flakes drifting down; the sound of wind
##   ash    ash and embers falling
##   dark   night: the rooms are dark but for your lantern, torches, candles, fires, blasts, glowing
##          foes and chests. Foes' eyes glow in the dark; their shots, warnings, danger circles and
##          health bars always show.
## The camp at night is lit the same way (its lanterns, the fire, the portal, fireflies).
## Rift worlds keep their own look. Nothing here touches the rules: replays are the same.

## A floor's name -> the weather it can have.
const BY_FLOOR := {
	"THE OSSUARY": ["fog", "dark"], "MIREWOOD GROTTO": ["fog", "rain", "dark"], "THE SUNKEN ARCHIVE": ["fog", "dark", "rain"],
	"THE CINDERFORGE": ["ash", "dark"], "RIMEFROST VAULT": ["snow", "fog"], "THE HOLLOW THRONE": ["dark", "fog"],
	"RAINMARSH HAMLET": ["rain", "storm", "fog"], "ASHEN WARFRONT": ["ash", "storm"], "FROSTPEAK MONASTERY": ["snow", "storm"],
	"NIGHTSPIRE ROOFTOPS": ["rain", "storm", "dark"], "THE ECLIPSE": ["dark", "storm"],
	"THE INKWELL": ["fog", "dark"], "THE BINDERY": ["dark", "fog"], "THE QUILL SPIRE": ["storm", "dark"],
	"THE GLOSSARY": ["fog", "dark"], "THE FOOTNOTES": ["dark", "fog"], "THE COVER": ["storm", "dark"],
	"THE STACKS": ["dark", "fog"], "THE READING ROOM": ["dark"], "THE HEARTH": ["ash", "dark"],
}
const CHANCE := 0.55
const NEWS := { "rain": ["IT IS RAINING ON THIS FLOOR", "cyan"], "storm": ["A STORM RAGES ON THIS FLOOR", "white"],
	"fog": ["A FOG HAS ROLLED IN", "bone"], "snow": ["SNOW IS FALLING", "white"], "ash": ["ASH FALLS LIKE SNOW", "orange"],
	"dark": ["NIGHT HAS FALLEN: KEEP TO THE LIGHT", "gold"] }
# 24.1 (his word, 9 Oct: "too dark at night, it is hard to play"): lighter nights, a moonlit blue
# rather than black, and a wider lantern; it is still night, but the room and its foes can be seen.
const DARK := 0.52        # (was 0.8)
const DARK_CAMP := 0.34   # (was 0.5)
const LANTERN := 108.0    # (was 80)
const MAX_LIGHTS := 16
const TORCHES := [Vector2(6 * 16 + 8, 18), Vector2(21 * 16 + 8, 18)]
const GLOWING := ["wisp", "lamp", "lantern", "torch", "candle", "ember", "cinder", "fire", "imp", "spark", "glimmer"]

const SHADER := """
shader_type canvas_item;
uniform vec4 lights[16];
uniform int count = 0;
uniform float dark = 0.0;
uniform vec4 night : source_color = vec4(0.05, 0.06, 0.16, 1.0);
varying vec2 world;
void vertex() {
	world = VERTEX;
}
void fragment() {
	vec2 p = floor(world) + 0.5;
	float lit = 0.0;
	for (int i = 0; i < 16; i++) {
		if (i >= count) { break; }
		vec4 l = lights[i];
		float k = clamp(1.0 - distance(p, l.xy) / l.z, 0.0, 1.0);
		lit = max(lit, k * (2.0 - k) * l.w);
	}
	float a = dark * (1.0 - lit);
	a = floor(a * 8.0 + 0.5) / 8.0;   // a few steps of light, as pixel art has
	COLOR = vec4(night.rgb, a);
}
"""

static var kind := ""
static var _shader: Shader
static var _rng := RandomNumberGenerator.new()
static var _air: Array = []      # [x, y, speed, phase] rain streaks, flakes or ash
static var _rings: Array = []    # [x, y, age] rain rings on the floor
static var _flashes: Array = []  # [x, y, r, t] the light of a blast

static func on() -> bool:
	return GameData.rogues() and not Meta.opts.get("neon", false)

## The weather of the room you are in ("" in rift worlds and the camp).
static func here() -> String:
	var room := G.room
	if kind == "" or room == null or not room.theme.is_empty() or room.type in ["camp", "barn"] or not on():
		return ""
	return kind

static func fog() -> bool:
	return here() == "fog"

static func storm() -> bool:
	return here() == "storm"

## How dark it is here: night on a floor, a gentler night in the camp.
static func dark_level() -> float:
	if here() == "dark":
		return DARK
	if CampClock.on() and CampClock.phase() == "night":
		return DARK_CAMP
	if mood():
		return MOOD
	return 0.0

## 66.5 (his word, 28 Oct, with pictures of Enter the Gungeon: "now iss all grimmy and not alive and
## boring, i want the vibe like on this picture"): every dungeon room is a little dim and warm at its
## edges, lit in pools round the hero, the torches, fires and glowing things (this same dark layer,
## lighter and warm), and its floor is darker and calmer (WorldView._calm_floor), so the heroes, foes
## and shots stand out from it. Only the look; --no-mood turns it off. Lighter (0.24) since his
## Gungeon and Runeward pictures: lit rooms in the dark, bright shots, the floors drawn rich again.
const MOOD := 0.24
const MOOD_COL := Color(0.07, 0.035, 0.05, 1.0)
const NIGHT_COL := Color(0.05, 0.06, 0.16, 1.0)

static func mood() -> bool:
	var room := G.room
	return on() and room != null and not room.type in ["camp", "barn"] and Meta.opts.get("mood", true) and not DebugArgs.has("no-mood")

## The floor's sound when the weather has one (Ambience.here).
static func sound() -> String:
	match here():
		"rain", "storm":
			return "rain"
		"snow":
			return "wind"
	return ""

## Game.start_floor, before the first room: this floor's weather.
static func on_floor_start() -> void:
	kind = ""
	_air.clear()
	_rings.clear()
	_flashes.clear()
	if not GameData.rogues() or G.floor_index <= 0:
		return
	var fl: Array = GameData.floors()
	if G.floor_index >= fl.size():
		return
	var opts: Array = BY_FLOOR.get(fl[G.floor_index]["name"], [])
	_rng.seed = hash([G.floor_index, G.run_stats.get("kills", 0), int(G.run_stats.get("time", 0.0) * 60.0), 22])
	if DebugArgs.has("weather"):
		opts = [DebugArgs.get_str("weather")]   # (pictures and tests)
	elif opts.is_empty() or _rng.randf() >= CHANCE:
		return
	kind = opts[_rng.randi() % opts.size()]
	if not NEWS.has(kind):
		kind = ""
		return
	G.toast(NEWS[kind][0], NEWS[kind][1])

## Combat.explode_at: a blast lights up the dark for a moment.
static func flash(x: float, y: float, r: float) -> void:
	if dark_level() <= 0.0 or not on():
		return
	_flashes.append([x, y, maxf(40.0, r * 2.5), 0.35])
	if _flashes.size() > 4:
		_flashes.pop_front()

## Every drawn tick (world_view.refresh): rain, flakes and ash move; blasts fade.
static func tick(dt: float) -> void:
	for i in range(_flashes.size() - 1, -1, -1):
		_flashes[i][3] -= dt
		if _flashes[i][3] <= 0.0:
			_flashes.remove_at(i)
	var w := here()
	if not w in ["rain", "storm", "snow", "ash"]:
		return
	var want := 70 if w == "storm" else (55 if w == "rain" else 40)
	while _air.size() < want:
		_air.append([_rng.randf_range(-40, TB.SW), _rng.randf_range(-TB.SH, TB.SH), _rng.randf_range(0.8, 1.2), _rng.randf() * TAU])
	for a in _air:
		match w:
			"rain":
				a[0] += 40.0 * dt
				a[1] += 300.0 * a[2] * dt
			"storm":
				a[0] += 150.0 * dt
				a[1] += 340.0 * a[2] * dt
			"snow":
				a[0] += sin(a[3] + a[1] * 0.03) * 14.0 * dt
				a[1] += 26.0 * a[2] * dt
			"ash":
				a[0] += (8.0 + sin(a[3] + a[1] * 0.02) * 10.0) * dt
				a[1] += 20.0 * a[2] * dt
		if a[1] > TB.SH or a[0] > TB.SW + 10:
			if w in ["rain", "storm"] and _rings.size() < 12 and _rng.randf() < 0.5:
				_rings.append([_rng.randf_range(24, TB.SW - 24), _rng.randf_range(40, TB.SH - 24), 0.0])
			a[0] = _rng.randf_range(-60 if w == "storm" else -20, TB.SW)
			a[1] = _rng.randf_range(-30, 0)
	for i in range(_rings.size() - 1, -1, -1):
		_rings[i][2] += dt
		if _rings[i][2] > 0.5:
			_rings.remove_at(i)

# ---------- Drawing ----------
## world_view lower layer: rain rings on the floor.
static func paint_floor(ci: CanvasItem) -> void:
	if not here() in ["rain", "storm"]:
		return
	for r in _rings:
		var k: float = r[2] / 0.5
		ci.draw_arc(Vector2(r[0], r[1]), 1.0 + k * 5.0, 0.0, TAU, 10, Color(0.75, 0.85, 1.0, 0.35 * (1.0 - k)), 1.0)

## world_view parts layer: what falls.
static func paint_air(ci: CanvasItem, t: float) -> void:
	var w := here()
	match w:
		"rain", "storm":
			var dx := 3.0 if w == "storm" else 1.0
			var col := Color(0.7, 0.8, 1.0, 0.35)
			for a in _air:
				ci.draw_line(Vector2(a[0], a[1]), Vector2(a[0] - dx, a[1] - 7.0), col, 1.0)
		"snow":
			for a in _air:
				ci.draw_rect(Rect2(roundf(a[0]), roundf(a[1]), 1 + int(a[2] > 1.1), 1 + int(a[2] > 1.1)), Color(1, 1, 1, 0.75))
		"ash":
			for i in _air.size():
				var a: Array = _air[i]
				var ember: bool = i % 7 == 0
				ci.draw_rect(Rect2(roundf(a[0]), roundf(a[1]), 1, 1),
					Color(1.0, 0.5 + 0.3 * sin(t * 6.0 + i), 0.15, 0.85) if ember else Color(0.55, 0.53, 0.55, 0.7))

## The darkness layer's material (world_view, between the people and the effects).
static func material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	return m

## world_view dark layer: one rect over the room, cut open by the lights.
static func paint_dark(ci: CanvasItem) -> void:
	var d := dark_level()
	if d <= 0.0:
		return
	var m := ci.material as ShaderMaterial
	var l := lights()
	m.set_shader_parameter("lights", l)
	m.set_shader_parameter("count", l.size())
	m.set_shader_parameter("dark", d)
	m.set_shader_parameter("night", MOOD_COL if d == MOOD and here() != "dark" else NIGHT_COL)
	ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), Color.WHITE)

## What gives light, the hero's lantern first: [x, y, radius, strength].
static func lights() -> PackedVector4Array:
	var out := PackedVector4Array()
	var t := G.time
	var p := G.player
	if p != null:
		var r := LANTERN * (1.4 if p.hero.get("id", "") == "warden" else 1.0) * (1.0 + 0.03 * sin(t * 9.0))
		out.append(Vector4(p.x, p.y - 4.0, r, 1.0))
	for f in _flashes:
		out.append(Vector4(f[0], f[1], f[2], clampf(f[3] / 0.35, 0.0, 1.0)))
	if CampClock.on():
		for lp: Vector2 in CampClock.LANTERNS:
			_add(out, lp.x + 3.0, lp.y - 12.0, 46.0 + sin(t * 7.0 + lp.x) * 2.0, 0.95)
	else:
		for tp: Vector2 in TORCHES:
			_add(out, tp.x, tp.y + 6.0, 62.0 + sin(t * 9.0 + tp.x) * 3.0, 0.9)
	if mood():   # 66.7: the first few of your shots light the floor round them
		var k := 0
		for b: PBullet in G.pbullets:
			_add(out, b.x, b.y, 26.0, 0.55)
			k += 1
			if k >= 4:
				break
	for e: Enemy in G.enemies:   # foes winding up a blow show it; glowing foes light their way
		if e.hp <= 0 or e.hidden or e.spawn_t > 0:
			continue
		if e.state in WorldView.WINDUPS:
			_add(out, e.x, e.y, 30.0, 0.8)
		elif _glows(e.type):
			_add(out, e.x, e.y - 4.0, 34.0, 0.75)
	for o in G.room.objects:
		if o.get("gone", false):
			continue
		match o["kind"]:
			"e_candle":
				if not o.get("down", false):
					_add(out, o["x"], o["y"] - 14.0, 54.0, 0.9)
			"campfire", "c_cook":
				_add(out, o["x"], o["y"] - 4.0, 78.0, 1.0)
			"portal", "loopportal", "exitportal", "soulgate", "pageportal", "c_portal":
				_add(out, o["x"], o["y"], 48.0, 0.8)
			"chest", "ichest", "pedestal", "altar":
				if not o.get("opened", false) and not o.get("used", false):
					_add(out, o["x"], o["y"], 30.0, 0.7)
	for z in G.zones:
		if z["kind"] == "fire":
			_add(out, z["x"], z["y"], 34.0, 0.8)
	for b in G.bombs:
		_add(out, b["x"], b["y"], 26.0, 0.7)
	return out

static func _add(out: PackedVector4Array, x: float, y: float, r: float, s: float) -> void:
	if out.size() < MAX_LIGHTS:
		out.append(Vector4(x, y, r, s))

static func _glows(type: String) -> bool:
	for w in GLOWING:
		if type.contains(w):
			return true
	return false

## world_view glow layer (additive, over the dark): foes' eyes.
static func paint_eyes(ci: CanvasItem, t: float) -> void:
	if here() != "dark":
		return
	for e: Enemy in G.enemies:
		if e.hp <= 0 or e.hidden or e.spawn_t > 0 or e.type == "dummy":
			continue
		var y := roundf(e.y - e.r * e.scale * 0.9 - 2.0 - e.z)
		var a := 0.75 + 0.2 * sin(t * 3.0 + e.uid)
		var c := Color(1.0, 0.25, 0.15, a) if not e.is_boss() else Color(1.0, 0.6, 0.15, a)
		var gap := 2.0 * e.scale
		ci.draw_rect(Rect2(roundf(e.x - gap - 1.0), y, 1, 1), c)
		ci.draw_rect(Rect2(roundf(e.x + gap), y, 1, 1), c)
