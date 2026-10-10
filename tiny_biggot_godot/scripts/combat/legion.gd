class_name Legion
extends RefCounted
## 34.2 THE LEGION PATH (his word, 9 Oct: a companion build, "focus 100% on dodging while your
## summons clear the dungeon"; ideas only, every name our own). One set of numbers for every kind
## of helper: wisps (familiars and the ones called for a while), skeletons and other thralls, and
## turrets.
##   minion_dmg    their damage (BONE BEACON)
##   minion_speed  their attack speed (ENDLESS RANKS)
##   march         every 1% of your move speed above your hero's own gives them this many % of
##                 attack speed (QUICK MARCH, MARCHING BOOTS: haste turns into a blender)
##   minion_cap    how many can be out at once, on top of each kind's own cap (GRAVE MARSHAL)
## Expanded game only: classic gets 1, 1 and 0, and plays as before.

static func dmg_mult(p: Player) -> float:
	if p == null or not GameData.rogues():
		return 1.0
	return (1.0 + p.g("minion_dmg")) * Finesse.helper_mult(p)   # (41.1 BOSOM BUDDY)

static func speed(p: Player) -> float:
	if p == null or not GameData.rogues():
		return 1.0
	var haste := maxf(0.0, p.speed / maxf(1.0, float(p.hero.get("speed", p.speed))) - 1.0)
	return 1.0 + p.g("minion_speed") + p.g("march") * haste + Finesse.helper_speed(p)   # (41.1 FIELD MARSHAL)

static func cap_bonus(p: Player) -> int:
	if p == null or not GameData.rogues():
		return 0
	return int(p.g("minion_cap"))

## A thrall or turret takes the damage bonus once, the first time it acts (summons.gd).
static func boost(p: Player, o: Dictionary) -> void:
	if not o.has("lg"):
		o["lg"] = true
		o["dmg"] = o.get("dmg", 0.0) * dmg_mult(p)
