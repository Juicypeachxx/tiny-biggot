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
	# 33.2 THE TAVERN: drinks make you TIPSY (tipsy.gd).
	"c_ale": { "name": "FROTHY ALE", "desc": "+2 TIPSY: MORE DAMAGE AND ATTACK SPEED", "col": "#e8b84a" },
	"c_stout": { "name": "DARK STOUT", "desc": "+3 TIPSY AND 1 ARMOR", "col": "#7a5236" },
	"c_mead": { "name": "HONEY MEAD", "desc": "+2 TIPSY AND HEALS HALF A HEART", "col": "#f2c94c" },
	# 36.3: three more drinks; every drink also gives a buff for 10 rooms (food.gd).
	"c_cider": { "name": "APPLE CIDER", "desc": "+2 TIPSY. BUFF: +10% ATTACK SPEED", "col": "#c8d84a" },
	"c_grog": { "name": "SAILOR'S GROG", "desc": "+3 TIPSY. BUFF: +10% MOVE SPEED", "col": "#8a6a3a" },
	"c_wine": { "name": "PLUM WINE", "desc": "+2 TIPSY. BUFF: +5% CRIT CHANCE", "col": "#a35bd6" },
}

static func is_kind(k: String) -> bool:
	return KINDS.has(k) or Infusions.is_kind(k)

## Its name, what it does and its colour (44: an infusion's from infusions.gd).
static func data(k: String) -> Dictionary:
	return KINDS[k] if KINDS.has(k) else Infusions.card(k)

## Bosses and some elites (Combat.kill_enemy). 44: a third of the time an infusion.
static func random_kind() -> String:
	if randf() < 0.35:
		return Infusions.roll()
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
	var d: Dictionary = data(kind)
	if Infusions.is_kind(kind):   # 44: an element on the weapon
		Infusions.infuse(p, kind)
		Snd.play("relic")
		Juice.label(d["name"], d["col"], p.x, p.y - 22)
		Juice.ring(p.x, p.y, 3, 30, 0.35, d["col"])
		return
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
		"c_ale":
			Tipsy.add(p, 2)
		"c_stout":
			Tipsy.add(p, 3)
			p.armor += 1
		"c_mead":
			Tipsy.add(p, 2)
			p.heal(1)
		"c_cider", "c_wine":
			Tipsy.add(p, 2)
		"c_grog":
			Tipsy.add(p, 3)
	Food.drink(p, kind)   # 36.3: its buff for 10 rooms
	Snd.play("heal")
	Juice.label(d["name"], d["col"], p.x, p.y - 22)
	Juice.ring(p.x, p.y, 3, 30, 0.35, d["col"])
