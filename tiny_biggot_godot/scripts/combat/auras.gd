class_name Auras
extends RefCounted
## 33.1 THE MIND FIELD (his word, 9 Oct: an INT aura build, "walk to the exit while everything
## dies"; ideas only, every name our own). Halos are fields round the hero that pulse while a fight
## is on. They used to be relic procs of a fixed size; now each is a stat (halo_<kind>, how many)
## and this module pulses them, so all of them grow with AURA REACH:
##   reach = 1 + 2% per INT + aura_int per INT (OVERMIND) + aura_reach (WIDE THOUGHTS ...)
## Their hits grow with aura_dmg and aura_int_dmg per INT (DEEP WELL), they pulse faster with
## aura_speed (STILL MIND), and aura_strike (HUMMING FIELD) makes every pulse hit too. The Ember
## Heart's old aura grows with the same reach. HORIZON RING sends the moons out to the field's
## edge, bigger and harder hitting. Expanded game only: classic has no halo and a reach of 1.

## kind: [base radius, period s, colour, what a pulse does]
const KINDS := {
	"burn": [56.0, 1.0, "#e8873a"], "chill": [56.0, 1.0, "#6fd3e0"], "poison": [56.0, 1.0, "#b8e05a"],
	"shock": [64.0, 1.0, "#4d9be6"], "gravity": [90.0, 2.0, "#a35bd6"], "sun": [72.0, 1.0, "#f2c94c"],
	"mind": [60.0, 1.0, "#e86fb4"], "wither": [60.0, 1.0, "#7a3a8c"], "mist": [56.0, 1.0, "#d8443c"],
}
const ORDER := ["burn", "chill", "poison", "shock", "gravity", "sun", "mind", "wither", "mist"]
const MAX_REACH := 6.0
const BASE_PER_INT := 0.02

static var _t := {}           # kind -> time to its next pulse
static var surge := 1.0       # MIND SPIRAL: the fields grow this much for a while
static var surge_t := 0.0
static var stats := {}        # kind -> pulses (tests)

static func reset() -> void:
	_t.clear()

## ["aura_surge", times, seconds]: the fields reach `times` as far for a while (MIND SPIRAL).
static func start_surge(times: float, secs: float) -> void:
	surge = maxf(surge, times)
	surge_t = maxf(surge_t, secs)

static func reach(p: Player) -> float:
	if p == null or not GameData.rogues():
		return 1.0
	var r := 1.0 + (BASE_PER_INT + p.g("aura_int")) * p.a_int + p.g("aura_reach")
	return clampf(r, 0.5, MAX_REACH) * (surge if surge_t > 0 else 1.0)

static func power(p: Player) -> float:
	return 1.0 + p.g("aura_dmg") + p.g("aura_int_dmg") * p.a_int

static func radius(p: Player, kind: String) -> float:
	return KINDS[kind][0] * reach(p)

## The halos this hero has: [kind, how many].
static func active(p: Player) -> Array:
	var out := []
	if p == null:
		return out
	for k in ORDER:
		var n := int(p.g("halo_" + k))
		if n > 0:
			out.append([k, n])
	return out

## Every logic tick (Combat.update_player): each halo pulses on its own clock while foes are up.
static func tick(p: Player, dt: float) -> void:
	if p == null or not GameData.rogues():
		return
	if surge_t > 0:
		surge_t -= dt
		if surge_t <= 0:
			surge = 1.0
	var hs := active(p)
	if hs.is_empty():
		return
	if not G.enemies_active():
		return
	var speed := 1.0 + p.g("aura_speed")
	for h in hs:
		var k: String = h[0]
		var t: float = _t.get(k, 0.0) - dt * speed
		if t <= 0:
			t += KINDS[k][1]
			_pulse(p, k, h[1])
		_t[k] = t

static func _pulse(p: Player, kind: String, n: int) -> void:
	stats[kind] = stats.get(kind, 0) + 1
	var r := radius(p, kind)
	var w := Weapons.wdmg(p) * power(p)
	var col: String = KINDS[kind][2]
	var hit := 0.0   # x weapon damage to every foe in the field
	match kind:
		"shock": hit = 0.3
		"sun": hit = 0.5
		"mind": hit = 0.35
	hit = hit * n + p.g("aura_strike")
	if kind == "gravity":
		Actions.run(["pull", r, 160], n, {})
	for e in G.enemies.duplicate():
		if not e.targetable() or TB.dist(e, p) > r + e.r:
			continue
		match kind:
			"burn", "sun": Statuses.apply(e, "burn", n, w)
			"chill": Statuses.apply(e, "chill", n, w)
			"poison": Statuses.apply(e, "poison", n, w)
			"shock": Statuses.apply(e, "shock", n, w)
			"wither":
				Statuses.apply(e, "curse", n, w)
				Statuses.apply(e, "vulnerable", 1, w)
			"mist": Statuses.apply(e, "bleed", n, w)
		var dmg := w * hit
		if kind == "gravity" and TB.dist(e, p) <= r * 0.45 + e.r:
			dmg += w * 0.6 * n
		if dmg > 0:
			Combat.damage_enemy(e, dmg, { "no_crit": true, "col": "pink" if kind == "mind" else "orange", "silent": true })
	Juice.ring(p.x, p.y, maxf(4.0, r * 0.2), r, 0.35, col)

## A foe that dies inside the BLOOD HAZE may heal you (Combat.kill_enemy).
static func on_kill(p: Player, e: Enemy) -> void:
	if p == null or p.g("halo_mist") <= 0 or not GameData.rogues():
		return
	if TB.dist(e, p) <= radius(p, "mist") + e.r and randf() < 0.04 * p.g("halo_mist"):
		p.heal(1)

## HORIZON RING: where the moons circle, how big they are and how hard they hit.
static func orbit_radius(p: Player) -> float:
	if p.g("horizon") <= 0:
		return 20.0
	return clampf(20.0 + 26.0 * (reach(p) - 1.0) + 8.0, 28.0, 150.0)

static func moon_scale(p: Player) -> float:
	if p.g("horizon") <= 0:
		return 1.0
	return clampf(1.0 + 0.5 * (reach(p) - 1.0) + 0.3, 1.3, 3.0)

static func moon_dmg(p: Player) -> float:
	if p.g("horizon") <= 0:
		return 0.7
	return 0.7 * (1.0 + 1.5 * p.g("horizon")) * power(p)

# ---------- drawing (vfx layer; reads only) ----------
## The fields: a faint disc and a rim with marks that turn slowly, one per halo. A pulse draws its
## own expanding ring (Juice). Three to four draw calls a field.
static func draw(ci: CanvasItem, p: Player, t: float) -> void:
	if p == null or not GameData.rogues():
		return
	var fields := []
	for h in active(p):
		fields.append([radius(p, h[0]), KINDS[h[0]][2]])
	if p.aura > 0 or p.g("fire_aura") > 0:
		fields.append([(38.0 + 10.0 * maxi(p.aura, 1)) * reach(p), "#e8873a"])
	if fields.is_empty():
		return
	var at := Vector2(roundf(p.x), roundf(p.y))
	for i in fields.size():
		var r: float = fields[i][0]
		var c := TB.c(fields[i][1])
		ci.draw_circle(at, r, Color(c.r, c.g, c.b, 0.05))
		ci.draw_arc(at, r, 0.0, TAU, maxi(24, int(r * 0.5)), Color(c.r, c.g, c.b, 0.35), 1.0, false)
		var marks := clampi(int(r / 10.0), 6, 28)
		var a0 := t * (0.6 if i % 2 == 0 else -0.6)
		for m in marks:
			var a := a0 + m * TAU / marks
			ci.draw_rect(Rect2(at.x + cos(a) * r - 1, at.y + sin(a) * r - 1, 2, 2), Color(c.r, c.g, c.b, 0.7))
