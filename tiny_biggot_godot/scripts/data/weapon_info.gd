class_name WeaponInfo
extends RefCounted
## Rogues layer: what an item card says about a weapon, and weapon upgrades.
## Type (melee / ranged / magic), range, damage type and upgrade level are
## derived from the weapon's type, tags and stats, so every weapon has them.
## Upgrades (+1 .. +25, +8% damage each) live on the weapon itself: the
## player's weapon becomes its own copy the first time it is upgraded, so a
## dropped weapon keeps its level.

const MAX_PLUS := 25
const PER_PLUS := 0.08
const MELEE := ["slash", "thrust", "whip"]
const MAGIC := ["orb", "zap", "nova", "pulse", "beam", "summon",
	"singularity", "serpent", "comet", "glyph", "blades", "chrono", "prism", "cloud", "pinball", "wild"]   # 23.1 the spellbook
const TAG_TYPE := { "pyre": "FIRE", "frost": "FROST", "venom": "POISON", "storm": "LIGHTNING", "arcane": "ARCANE",
	"malice": "SHADOW", "shadow": "SHADOW" }
const KIND_TYPE := { "slash": "SLASHING", "whip": "SLASHING", "disc": "SLASHING", "spin": "SLASHING", "boomer": "SLASHING",
	"thrust": "PIERCING", "bolt": "PIERCING", "rail": "PIERCING", "burst": "PIERCING", "gatling": "PIERCING", "shot": "PIERCING",
	"flask": "BLAST", "mine": "BLAST", "flame": "FIRE", "orb": "ARCANE", "nova": "ARCANE", "pulse": "ARCANE",
	"beam": "ARCANE", "zap": "LIGHTNING", "summon": "ARCANE",
	"grenade": "BLAST", "rocket": "BLAST", "missile": "BLAST", "sticky": "BLAST", "mortar": "BLAST", "walker": "BLAST", "strike": "BLAST",
	"dynamite": "BLAST", "wave": "PHYSICAL",
	"charge": "ARCANE", "slam": "PHYSICAL", "dash": "SLASHING", "javelin": "PIERCING", "hook": "PHYSICAL", "combo": "SLASHING",
	"heat": "FIRE", "reload": "PIERCING", "orbit": "ARCANE", "recall": "SLASHING", "flail": "PHYSICAL",
	"deck": "ARCANE", "turret": "PIERCING", "thrall": "SHADOW", "command": "PHYSICAL", "mirror": "ARCANE", "swarm": "SHADOW", "egg": "FIRE",
	"letters": "ARCANE", "bubble": "FROST", "flak": "PIERCING", "paint": "ARCANE", "slots": "PIERCING", "roller": "PHYSICAL",
	"money": "PIERCING", "camera": "ARCANE", "ray": "FROST", "junk": "PHYSICAL", "bat": "PHYSICAL", "stab": "PIERCING",
	"duel": "PIERCING", "shrink": "ARCANE", "blower": "PHYSICAL", "dome": "ARCANE", "coin": "PIERCING",
	"singularity": "SHADOW", "serpent": "FIRE", "comet": "FIRE", "glyph": "ARCANE", "blades": "SLASHING", "chrono": "ARCANE",
	"prism": "ARCANE", "cloud": "LIGHTNING", "pinball": "ARCANE", "wild": "ARCANE" }
const TYPE_COL := { "SLASHING": "bone", "PIERCING": "bone", "BLAST": "orange", "FIRE": "orange", "FROST": "cyan",
	"POISON": "lime", "LIGHTNING": "cyan", "ARCANE": "pink", "SHADOW": "purple" }

static func wtype(w: Dictionary) -> String:
	if w["kind"] in MELEE:
		return "MELEE"
	return "MAGIC" if w["kind"] in MAGIC else "RANGED"

static func range_name(w: Dictionary) -> String:
	var reach: float = w.get("range", 0.0) if w["kind"] in MELEE or w.get("speed", 0) == 0 else w["speed"] * w["life"]
	if reach <= 0:
		reach = w.get("range", 60)
	if reach < 45:
		return "SHORT"
	return "MEDIUM" if reach < 150 else "LONG"

static func damage_type(w: Dictionary) -> String:
	for t in w["tags"]:
		if TAG_TYPE.has(t):
			return TAG_TYPE[t]
	return KIND_TYPE.get(w["kind"], "PHYSICAL")

static func plus(w: Dictionary) -> int:
	return w.get("plus", 0)

static func display_name(w: Dictionary) -> String:
	return w["name"] + (" +%d" % plus(w) if plus(w) > 0 else "")

static func upgrade_mult(w: Dictionary) -> float:
	if not GameData.rogues():
		return 1.0
	return 1.0 + PER_PLUS * plus(w)

## Upgrades the player's weapon by n levels (capped). Returns the new level.
static func upgrade(p: Player, n: int) -> int:
	if p.weapon == null:
		return 0
	if not p.weapon.has("plus"):
		p.weapon = p.weapon.duplicate()
		p.weapon["plus"] = 0
	p.weapon["plus"] = mini(MAX_PLUS, p.weapon["plus"] + n)
	return p.weapon["plus"]

static func anvil_cost(p: Player) -> int:
	return 25 + 15 * plus(p.weapon)

## Damage per hit this weapon would deal for the player (before crits),
## and the low/high of the +-15% roll.
static func hit_damage(p: Player, w: Dictionary) -> float:
	return w["dmg"] * p.dmg * Attributes.mult_for(p, w) * upgrade_mult(w)

static func damage_range(p: Player, w: Dictionary) -> Array:
	var d := hit_damage(p, w)
	if not GameData.rogues():
		return [d, d]
	return [d * 0.85, d * 1.15]
