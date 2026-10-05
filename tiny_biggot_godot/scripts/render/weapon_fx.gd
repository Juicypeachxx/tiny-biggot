class_name WeaponFx
extends RefCounted
## Rogues layer, phase E: themed weapon effects. Purely visual, like Juice:
## its own random generator, reads game state but never writes it, so
## replays stay identical. Each weapon's first tag picks a theme: fire shots
## shed rising embers, frost leaves drifting flakes, venom drips, storm
## crackles, shadow trails wisps, and so on. Themes show on shot trails,
## at the start of melee swings, as sparks where foes are hit, and as an
## aura around legendary weapons. Particles are Juice sparks (capped).

## motion: rise / fall (gravity) / drift (slow, floaty) / burst (fast, short) / still
const THEME := {
	"pyre": { "cols": ["#e8873a", "#d8443c", "#f2c94c"], "motion": "rise" },
	"fury": { "cols": ["#e8573a", "#f2c94c", "#d8443c"], "motion": "rise" },
	"frost": { "cols": ["#ffffff", "#6fd3e0", "#c8f0ff"], "motion": "drift" },
	"venom": { "cols": ["#b8e05a", "#7fbf3f", "#f4ffd0"], "motion": "fall" },
	"blood": { "cols": ["#d8443c", "#8a2a33", "#ff8a8a"], "motion": "fall" },
	"storm": { "cols": ["#c8f0ff", "#6fd3e0", "#ffffff"], "motion": "burst" },
	"shadow": { "cols": ["#a35bd6", "#5c3483", "#e8c8ff"], "motion": "drift" },
	"malice": { "cols": ["#7a3a8c", "#d8443c", "#3c1d47"], "motion": "drift" },
	"arcane": { "cols": ["#e86fb4", "#ffffff", "#a35bd6"], "motion": "still" },
	"fortune": { "cols": ["#f2c94c", "#fffbe0", "#e8873a"], "motion": "still" },
	"swarm": { "cols": ["#f2c94c", "#7a5236"], "motion": "burst" },
	"edge": { "cols": ["#ffffff", "#f4ecd8", "#f2c94c"], "motion": "burst" },
	"demolition": { "cols": ["#8b8f9c", "#e8873a", "#4e4a5e"], "motion": "rise" },
	"bulwark": { "cols": ["#8b8f9c", "#f4ecd8"], "motion": "fall" },
}
const MAX_TRAIL_SHOTS := 60   # shots checked per tick (stress rooms can hold 180+)
const TRAIL_CHANCE := 0.3

static var _rng := RandomNumberGenerator.new()
static var _seen_swings: Array = []
static var _flash := {}       # enemy uid -> last flash value

static func reset() -> void:
	_seen_swings.clear()
	_flash.clear()

static func theme_of(tag: String) -> Dictionary:
	return THEME.get(tag, {})

static func weapon_tag(w) -> String:
	if w == null or w["tags"].size() == 0:
		return ""
	return w["tags"][0]

## One themed particle at (x, y). spread scales the velocity.
static func emit(tag: String, x: float, y: float, spread: float = 1.0, dir: float = NAN) -> void:
	var th := theme_of(tag)
	if th.is_empty():
		return
	var cols: Array = th["cols"]
	var col := TB.c(cols[_rng.randi() % cols.size()])
	var a := _rng.randf() * TAU if is_nan(dir) else dir + _rng.randf_range(-0.6, 0.6)
	var vx := 0.0
	var vy := 0.0
	var g := 0.0
	var life := 0.35
	match th["motion"]:
		"rise":
			vx = _rng.randf_range(-8, 8) * spread
			vy = -20.0 - _rng.randf() * 25.0
			life = 0.35 + _rng.randf() * 0.25
		"fall":
			vx = cos(a) * 15.0 * spread
			vy = -10.0 * spread
			g = 140.0
			life = 0.4 + _rng.randf() * 0.2
		"drift":
			vx = cos(a) * 10.0 * spread
			vy = sin(a) * 6.0 * spread + 6.0
			life = 0.5 + _rng.randf() * 0.4
		"burst":
			var v := (50.0 + _rng.randf() * 60.0) * spread
			vx = cos(a) * v
			vy = sin(a) * v
			life = 0.12 + _rng.randf() * 0.1
		_:
			life = 0.25 + _rng.randf() * 0.25
	Juice.spark(x + _rng.randf_range(-1.5, 1.5), y + _rng.randf_range(-1.5, 1.5), vx, vy, g, life, col)

## Per logic tick, after the game update (called from Juice.update).
static func update(p: Player) -> void:
	if not GameData.rogues() or p == null:
		return
	# Shot trails.
	var n := 0
	# Crowded screens get fewer trail particles per shot.
	var chance := TRAIL_CHANCE * minf(1.0, 40.0 / maxf(1.0, G.pbullets.size()))
	for b: PBullet in G.pbullets:
		if n >= MAX_TRAIL_SHOTS:
			break
		n += 1
		if b.tag != "" and b.kind != "mine" and _rng.randf() < chance:
			emit(b.tag, b.x, b.y, 0.6)
	# Fresh melee swings burst along their edge.
	for w in G.swings:
		if _seen_swings.any(func(s): return is_same(s, w)):
			continue
		_swing_burst(w)
	_seen_swings = G.swings.duplicate()
	# Hit sparks in the weapon's theme: a foe's hit flash just went up.
	var tag := weapon_tag(p.weapon)
	var now := {}
	for e: Enemy in G.enemies:
		if e.flash > _flash.get(e.uid, 0.0) + 0.001 and tag != "":
			for k in 3:
				emit(tag, e.x, e.y - 2, 1.4)
		now[e.uid] = e.flash
	_flash = now
	# Legendary weapons glow with their theme.
	if p.weapon != null and p.weapon.get("rarity", "") == "legend" and p.dodge_t <= 0 and _rng.randf() < 0.35:
		emit(tag if tag != "" else "fortune", p.x + cos(p.aim_a) * 9, p.y - 1 + sin(p.aim_a) * 6, 0.4)

static func _swing_burst(w: Dictionary) -> void:
	var tag: String = w.get("tag", "")
	if theme_of(tag).is_empty():
		return
	match w["kind"]:
		"slash":
			var arc: float = w["arc"]
			for i in 7:
				var a: float = w["a"] - arc / 2 + arc * i / 6.0
				emit(tag, w["x"] + cos(a) * w["r"], w["y"] + sin(a) * w["r"], 1.0, a)
		"thrust", "whip", "beam":
			var len: float = w["len"]
			for i in 5:
				var d := len * (0.3 + 0.7 * i / 4.0)
				emit(tag, w["x"] + cos(w["a"]) * d, w["y"] + sin(w["a"]) * d, 0.8)
