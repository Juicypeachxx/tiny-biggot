class_name Statuses
extends RefCounted
## Status effects (design spec 2b). The original statuses (burn, poison, chill,
## bleed, stun, curse, mark) keep their original fields and rules; applying
## them here uses the same numbers the original combat code uses. Three
## statuses are new and only reachable through new content:
##   shock       stacks up to 5 (3 s): +6% damage taken per stack; a shocked
##               foe that dies arcs to nearby foes
##   vulnerable  (3 s): +25% damage taken
##   weakened    (3 s): moves, shoots and acts 30% slower
##   gloom       (11.2, his trailer clips) stacks up to 10 (4 s): +8% damage taken per stack

const SHOCK_MAX := 5
const GLOOM_MAX := 10

static func apply(e: Enemy, name: String, amount: float, hit_dmg: float) -> void:
	var p := G.player
	# Drawing only: a small pop when a status first takes hold.
	if Vfx.enabled:
		if name == "burn" and e.burn_t <= 0:
			Vfx.puff(e.x, e.y, "fire")
		elif name == "chill" and e.chill_t <= 0:
			Vfx.puff(e.x, e.y, "frost")
		elif name == "curse" and e.curse_t <= 0:
			Vfx.puff(e.x, e.y, "void")
		elif name == "poison" and e.poison <= 0:
			Vfx.puff(e.x, e.y, "venom")
	match name:
		"burn": e.burn_t = maxf(e.burn_t, (3.0 + p.burn_time) * maxf(1.0, amount))
		"poison": e.poison = minf(12, e.poison + amount)
		"chill": e.chill_t = maxf(e.chill_t, (2.0 + p.chill_time) * maxf(1.0, amount))
		"bleed":
			e.bleed_t = 3.0
			e.bleed_dps = maxf(e.bleed_dps, hit_dmg * 0.25 * amount)
		"stun": e.stun_t = 0.25 if e.is_boss() else 1.0 * amount
		"curse": e.curse_t = maxf(e.curse_t, 3.0 * amount)
		"mark":
			e.mark_t = 3.0
			e.mark_v = maxf(e.mark_v, 0.15 * amount)
		"shock":
			e.shock = mini(SHOCK_MAX, e.shock + maxi(1, int(amount)))
			e.shock_t = 3.0
			Lucky.on_shock(e)   # 34.1 STATIC BUILD-UP
		"gloom":
			e.gloom = mini(GLOOM_MAX, e.gloom + maxi(1, int(amount)))
			e.gloom_t = 4.0
		"vulnerable": e.vuln_t = maxf(e.vuln_t, 3.0 * amount)
		"weakened": e.weak_t = maxf(e.weak_t, 3.0 * amount)
		_:
			push_error("Statuses: unknown status " + name)

## Damage multiplier from the new statuses (1.0 when none are active).
static func dmg_mult(e: Enemy) -> float:
	var m := 1.0
	if e.vuln_t > 0:
		m *= 1.25
	if e.shock > 0:
		m *= 1 + 0.06 * e.shock
	if e.gloom > 0:
		m *= 1 + 0.08 * e.gloom
	return m

## Ticks the new statuses. Called only while one is active.
static func tick(e: Enemy, dt: float) -> void:
	if e.vuln_t > 0:
		e.vuln_t -= dt
	if e.weak_t > 0:
		e.weak_t -= dt
	if e.shock_t > 0:
		e.shock_t -= dt
		if e.shock_t <= 0:
			e.shock = 0
	if e.gloom_t > 0:
		e.gloom_t -= dt
		if e.gloom_t <= 0:
			e.gloom = 0
