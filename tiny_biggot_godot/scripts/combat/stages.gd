class_name Stages
extends RefCounted
## Souls-like stages for mini-bosses, rift champions and rift guardians (his ask, 6 Oct: "apply to
## all bosses and mini bosses"; expanded game only). The floor guardians have their own stage plans
## (BossAI.STAGE_PLANS); everyone else gets this: at two thirds and one third of its health (a rift
## guardian, which already has its second phase at half: a third stage at a quarter) it breaks,
## shaking in place for 1.2 s and unhurt, every shot vanishes, the banner speaks, and it comes back
## faster, with a wall of shots (stage 2) or chaos: quicker attacks and a desperation pulse (3).

const LINES := ["IT GROWS FURIOUS", "IT FIGHTS FOR ITS LIFE"]

static func applies(e: Enemy) -> bool:
	if not GameData.rogues() or e.type == "dummy":
		return false
	if e.is_boss():
		return RiftBosses.handles(e)   # rift guardians and Rex; floor guardians: BossAI.STAGE_PLANS
	return e.d.get("mini", false)

## The lowest health a blow can leave (his ask, 6 Oct: "I can't even feel the 3 stages"): however
## hard it hits, a guardian, rift guardian or mini-boss stops at the line of its next stage and has
## to break into it first. The build keeps all its power; the fight keeps all its stages.
static func gate(e: Enemy) -> float:
	if not GameData.rogues() or e.type == "dummy" or e.hp <= 0:
		return 0.0
	if e.is_boss() and BossAI.STAGE_PLANS.has(e.boss):
		if e.phase == 3:
			return 0.0   # the Holy Cow risen: its last fight
		return e.max_hp * (0.66 if e.stage <= 1 else (0.33 if e.stage == 2 else 0.0))
	if not applies(e):
		return 0.0
	if e.is_boss():   # rift guardians and Rex: a second phase at half, a third stage at a quarter
		if e.phase <= 1:
			return e.max_hp * 0.49
		return e.max_hp * 0.24 if e.stage <= 1 else 0.0
	return e.max_hp * (0.66 if e.stage <= 1 else (0.33 if e.stage == 2 else 0.0))

static func _want(e: Enemy) -> int:
	if e.is_boss():
		return 3 if e.hp < e.max_hp * 0.25 else 1
	return 3 if e.hp < e.max_hp * 0.34 else (2 if e.hp < e.max_hp * 0.67 else 1)

## Every tick, before the foe's own AI. True: the foe is in a stage break (no AI this tick).
static func tick(e: Enemy, dt: float) -> bool:
	if not applies(e) or e.hp <= 0:
		return false
	if e.break_t > 0:
		e.break_t -= dt
		e.z = absf(sin(e.break_t * 22.0)) * 3.0
		if e.break_t <= 0:
			e.z = 0.0
			Combat.ering(e.x, e.y - 4, 24, 78, randf(), e.d.get("shot", "red"))
			Combat.ering(e.x, e.y - 4, 16, 52, randf(), e.d.get("shot", "red"))
			G.add_shake(7)
			Snd.play("boom")
		return true
	var want := _want(e)
	if want > e.stage:
		e.stage = want
		e.break_t = 1.2
		e.speed *= 1.15
		EBullets.clear_all()
		G.show_banner(e.d["name"], LINES[mini(want, 3) - 2])
		G.add_shake(6)
		Snd.play("roar")
		Fx.burst(e.x, e.y, ["#f4ecd8", "#d8443c"], 22, 110)
		return true
	if e.stage >= 2:
		e.t -= dt * (0.35 if e.stage == 2 else 0.7)   # attacks come sooner
		e.pulse_t -= dt
		if e.pulse_t <= 0:
			var p := G.player
			if e.stage == 2:
				e.pulse_t = 6.0
				var gap := TB.ang_to(e, p)
				for i in 24:
					var a := gap + float(i) / 24 * TAU
					if absf(TB.wrap_ang(a - gap)) > 0.4:
						Combat.eshot(e.x, e.y - 4, a, 62, e.d.get("shot", "red"))
			else:
				e.pulse_t = 3.5
				Combat.ering(e.x, e.y - 4, 14, 64, randf(), e.d.get("shot", "red"))
				Combat.efan(e.x, e.y - 4, TB.ang_to(e, p), 5, 0.7, 110, "bone")
	return false
