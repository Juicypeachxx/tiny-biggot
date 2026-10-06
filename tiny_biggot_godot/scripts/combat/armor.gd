class_name Armor
extends RefCounted
## Boss armor (his ask, 6 Oct: "bosses with a bigger health pool and armor, so fights last and feel
## rewarding, not boring"; expanded game only). Guardians, rift guardians, mini-bosses and rift
## champions start every stage behind a plate: 35% of their health for guardians, 25% for the
## others. While it holds, a blow wears the plate down by its full damage and only a quarter gets
## through to the health. When it breaks: ARMOR BROKEN, the foe reels for a moment (unless the
## same blow starts its next stage) and is vulnerable (+25% damage) for 3 s. Every new stage brings a fresh plate. The build's damage is
## never touched: every point of it lands, on the plate or the health.

const THROUGH := 0.25

static func has(e: Enemy) -> bool:
	if not GameData.rogues() or e.type == "dummy":
		return false
	return e.is_boss() or e.d.get("mini", false) or e.d.get("champion", false) or e.traits.has("plated")

static func plate(e: Enemy) -> float:
	if e.traits.has("plated"):
		return e.max_hp * 0.5   # a PLATED elite (elite_traits.gd)
	return e.max_hp * (0.35 if e.is_boss() else 0.25)

## A fresh plate at the start of each stage, and each phase of a rift guardian (read lazily, on
## the first blow of the stage).
static func refresh(e: Enemy) -> void:
	if e.armor_stage != _key(e):
		e.armor_stage = _key(e)
		e.max_armor = plate(e)
		e.armor = e.max_armor

static func _key(e: Enemy) -> int:
	return e.stage * 4 + e.phase

## The plate the boss bar shows (no change to the foe: drawing never touches the game).
static func shown(e: Enemy) -> float:
	if not has(e):
		return 0.0
	return e.armor if e.armor_stage == _key(e) else plate(e)

## The part of a blow that reaches the health. `gate`: the foe's stage line (Stages.gate).
static func soak(e: Enemy, dmg: float, gate: float = 0.0) -> float:
	if not has(e):
		return dmg
	refresh(e)
	if e.armor <= 0:
		return dmg
	if dmg < e.armor:
		e.armor -= dmg
		return dmg * THROUGH
	var rest := dmg - e.armor
	e.armor = 0.0
	_break(e, gate <= 0.0 or e.hp - rest > gate)
	return rest   # what is left after breaking the plate lands whole

## `reel`: false when the same blow reaches the next stage: the stage break is its reel, and a
## stun on top would only hold the stage back.
static func _break(e: Enemy, reel: bool) -> void:
	if reel:
		e.stun_t = maxf(e.stun_t, 1.0 if e.is_boss() else 1.5)
	e.vuln_t = maxf(e.vuln_t, 3.0)
	Fx.float_text(e.x, e.y - e.r - 14, "ARMOR BROKEN", "gold", true)
	Fx.burst(e.x, e.y - 4, ["#c8d0dc", "#8a94a8", "#f4ecd8"], 18, 90)
	G.add_shake(5)
	Snd.play("boom")
