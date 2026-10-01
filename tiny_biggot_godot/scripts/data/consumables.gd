class_name Consumables
extends RefCounted
## Rogues layer: quick-belt consumables. They drop as pickups ("c_..."),
## go into the 4-slot belt and are used with keys 1-4, by tapping the belt
## on the HUD, or from the inventory screen.

const BELT_SIZE := 4
const KINDS := {
	"c_fury": { "name": "FURY DRAUGHT", "desc": "+40% DAMAGE FOR 12S", "col": "#d8443c" },
	"c_smoke": { "name": "SMOKE VIAL", "desc": "ERASE NEARBY SHOTS AND BE UNTOUCHABLE FOR 1.5S", "col": "#d9d0b4" },
	"c_whet": { "name": "WHETSTONE", "desc": "+1 LEVEL TO YOUR WEAPON", "col": "#8b8f9c" },
	"c_insight": { "name": "ELIXIR OF INSIGHT", "desc": "+1 TO A RANDOM ATTRIBUTE", "col": "#4d9be6" },
}

static func is_kind(k: String) -> bool:
	return KINDS.has(k)

static func random_kind() -> String:
	return KINDS.keys()[randi() % KINDS.size()]

## Picks up a consumable into the belt; false when the belt is full.
static func take(p: Player, kind: String) -> bool:
	if p.belt.size() >= BELT_SIZE:
		return false
	p.belt.append(kind)
	return true

## Uses belt slot i (0-based).
static func use(p: Player, i: int) -> void:
	if i < 0 or i >= p.belt.size():
		Snd.play("deny")
		return
	var kind: String = p.belt[i]
	p.belt.remove_at(i)
	var d: Dictionary = KINDS[kind]
	match kind:
		"c_fury":
			Effects.add_buff(p, "dmg", 0.4, 12.0)
		"c_smoke":
			EBullets.kill_radius(p.x, p.y, 130)
			p.invuln = maxf(p.invuln, 1.5)
		"c_whet":
			WeaponInfo.upgrade(p, 1)
		"c_insight":
			Attributes.add(p, Attributes.ATTRS[randi() % 3], 1)
	Snd.play("heal")
	Juice.label(d["name"], d["col"], p.x, p.y - 22)
	Juice.ring(p.x, p.y, 3, 30, 0.35, d["col"])
