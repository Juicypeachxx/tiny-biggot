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
##   shatter     (47.2, armour break) stacks up to 5 (4 s): +5% damage taken per stack (shatter.gd)
##   seared, rot, charged, rattled (50.2): the ailments of the RADIANT, NECROTIC, ENERGY and SOUND
##               weapons (damage_types.gd)

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
	if Might.casting and p.g("merciless") > 0:
		amount *= 2.0   # 40.2 MERCILESS: what your special inflicts is twice as strong
	amount *= Finesse.status_mult(p)   # 41.1 HABIT: right after a repeat
	amount *= Arcana.focus_mult(p, name)   # 42.1 FOCUSED ELEMENTS
	amount *= Enchant.status_mult(p, name)   # 46 BITING, WYRMFROST, HUMMING, WYRMSTORM
	if name == "burn" or name == "bleed":
		Might.add_stack(p, e, name)   # 40.2 BLOOD AND ASH
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
			e.shock = mini(shock_cap(), e.shock + maxi(1, int(amount)))
			e.shock_t = 3.0
			Lucky.on_shock(e)   # 34.1 STATIC BUILD-UP
		"gloom":
			e.gloom = mini(GLOOM_MAX, e.gloom + maxi(1, int(amount)))
			e.gloom_t = 4.0
		"shatter": Shatter.add(e, int(amount))   # 47.2
		"seared": e.seared_t = maxf(e.seared_t, 3.0 * maxf(1.0, amount))   # 50.2
		"rot":
			e.rot = mini(DamageTypes.ROT_MAX + int(p.g("rot_max")) if p != null else DamageTypes.ROT_MAX, e.rot + maxi(1, int(amount)))   # (53.2 GRAVE MOSS)
			e.rot_t = 4.0
		"charged": DamageTypes.charge(e, maxi(1, int(amount)), hit_dmg)
		"rattled": DamageTypes.rattle(e, maxi(1, int(amount)))
		"vulnerable": e.vuln_t = maxf(e.vuln_t, 3.0 * amount)
		"weakened": e.weak_t = maxf(e.weak_t, 3.0 * amount)
		_:
			push_error("Statuses: unknown status " + name)
	Arcana.on_status(p, e, name, hit_dmg)   # 42.1 THORN BLOOM, EATING ACID, ELEMENT WHEEL

## 43.1 MIND LIGHTNING: the most shock a foe can hold.
static func shock_cap() -> int:
	var p := G.player
	if p == null or not GameData.rogues():
		return SHOCK_MAX
	return SHOCK_MAX + int(p.g("shock_max"))

## Damage multiplier from the new statuses (1.0 when none are active).
static func dmg_mult(e: Enemy) -> float:
	var m := 1.0
	if e.vuln_t > 0:
		m *= 1.25
	if e.shock > 0:
		m *= 1 + 0.06 * e.shock
	if e.gloom > 0:
		m *= 1 + 0.08 * e.gloom
	if e.shatter > 0:
		m *= Shatter.mult(e)   # 47.2
	if (e.seared_t > 0 or e.rattle > 0) and G.player != null:   # 53.2 SUNSPOT, RESONANCE
		var p := G.player
		if e.seared_t > 0:
			m *= 1 + p.g("vs_seared")
		m *= 1 + p.g("vs_rattle") * e.rattle
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
	if e.shatter_t > 0:
		e.shatter_t -= dt
		if e.shatter_t <= 0:
			e.shatter = 0
	if e.seared_t > 0:   # 50.2
		e.seared_t -= dt
	if e.rot_t > 0:
		e.rot_t -= dt
		DamageTypes.tick_rot(e, dt)
		if e.rot_t <= 0:
			e.rot = 0
	if e.charge_t > 0:
		e.charge_t -= dt
		if e.charge_t <= 0:
			e.charge = 0
	if e.rattle_t > 0:
		e.rattle_t -= dt
		if e.rattle_t <= 0:
			e.rattle = 0
