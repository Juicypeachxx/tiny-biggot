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

## 7.1 Weaknesses (his word "All", 6 Oct): every guardian, mini-boss and champion has one, shown on
## its bar. A hit of that kind wears the plate 2.5 times as fast; nothing else changes.
##   FIRE: burning and fire hits (orange numbers); POISON: poison ticks (lime); STORM: lightning
##   (cyan); CRITS: any critical hit; BLASTS: explosions and bombs.
const WEAK := ["fire", "poison", "storm", "crits", "blasts"]
const WEAK_COL := { "fire": "orange", "poison": "lime", "storm": "cyan", "crits": "gold", "blasts": "red" }
const WEAR := 2.5

static func weakness(e: Enemy) -> String:
	if not GameData.rogues() or e.type == "dummy":
		return ""
	if not (e.is_boss() or e.d.get("mini", false) or e.d.get("champion", false)):
		return ""
	var key: String = e.boss if e.is_boss() else e.type
	var sum := 0
	for i in key.length():
		sum += key.unicode_at(i)
	return WEAK[sum % WEAK.size()]

## Does this blow (Combat.damage_enemy's options and its crit) hit the foe's weakness?
static func weak_hit(e: Enemy, o: Dictionary, crit: bool) -> bool:
	match weakness(e):
		"fire": return o.get("col", "") == "orange"
		"poison": return o.get("col", "") == "lime"
		"storm": return o.get("col", "") == "cyan"
		"crits": return crit
		"blasts": return o.get("boom", false) or o.get("bomb", false)
	return false

static func has(e: Enemy) -> bool:
	if not GameData.rogues() or e.type == "dummy":
		return false
	return e.is_boss() or e.d.get("mini", false) or e.d.get("champion", false) or e.traits.has("plated")

## 56.3 (his playthrough, 12 Oct: "... and armor"): a guardian's plate grows with depth (35% of its
## health on the first floor, 1.5% more each floor down, 53% twelve floors down), and less gets
## through it (a quarter, then 0.8% less each floor, 15.4% twelve floors down).
static func plate(e: Enemy) -> float:
	if e.traits.has("plated"):
		return e.max_hp * 0.5   # a PLATED elite (elite_traits.gd)
	return e.max_hp * ((0.35 + 0.015 * mini(Resolve.depth(), 12)) if e.is_boss() else 0.25)

static func through(e: Enemy) -> float:
	return THROUGH - 0.008 * mini(Resolve.depth(), 12) if e.is_boss() else THROUGH

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
## `weak`: the blow hits the foe's weakness (wears the plate WEAR times as fast).
static func soak(e: Enemy, dmg: float, gate: float = 0.0, weak: bool = false) -> float:
	if not has(e):
		return dmg
	refresh(e)
	if e.armor <= 0:
		return dmg
	var wear := WEAR if weak else 1.0
	if dmg * wear < e.armor:
		e.armor -= dmg * wear
		return dmg * through(e)
	var rest := dmg - e.armor / wear
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
