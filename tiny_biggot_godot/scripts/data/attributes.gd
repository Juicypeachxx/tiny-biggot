class_name Attributes
extends RefCounted
## STR / DEX / INT and weapon scaling (Rogues layer). Every weapon has a grade
## per attribute (S, A, B, C, D, E or "-"); each attribute point adds
## PER_POINT x the grade's weight to weapon damage. Grades come from the
## weapon's type and tags (or an explicit "scaling" field), so all weapons,
## original and new, get them without hand-editing.
## Attributes grow with trait ranks: each rank adds +1 to its family's
## attribute. Heroes start with their own spread, and some items add more.
## Off under --classic (GameData.rogues()), which keeps the original game.

const ATTRS := ["str", "dex", "int"]
const NAMES := { "str": "STR", "dex": "DEX", "int": "INT" }
const COLS := { "str": "red", "dex": "lime", "int": "cyan" }
const PER_POINT := 0.03
const GRADES := ["S", "A", "B", "C", "D", "E", "-"]
const COEF := { "S": 1.0, "A": 0.8, "B": 0.6, "C": 0.4, "D": 0.25, "E": 0.1, "-": 0.0 }

## Base grades per weapon type: [STR, DEX, INT].
const KIND := {
	"slash": ["A", "C", "-"], "thrust": ["B", "B", "-"], "whip": ["C", "A", "-"], "spin": ["A", "D", "-"],
	"bolt": ["-", "S", "-"], "burst": ["-", "A", "-"], "gatling": ["D", "A", "-"], "shot": ["C", "A", "-"],
	"rail": ["-", "A", "D"], "disc": ["C", "B", "-"], "boomer": ["C", "B", "-"], "flask": ["-", "C", "B"],
	"mine": ["-", "C", "B"], "orb": ["-", "-", "S"], "zap": ["-", "-", "A"], "nova": ["-", "D", "A"],
	"pulse": ["-", "-", "A"], "beam": ["-", "-", "S"], "flame": ["-", "C", "B"], "summon": ["-", "-", "A"],
	"flail": ["A", "B", "-"],   # 10.4
	# 23.1 the spellbook
	"singularity": ["-", "-", "S"], "serpent": ["-", "D", "A"], "comet": ["-", "-", "S"], "glyph": ["-", "-", "S"],
	"blades": ["-", "B", "A"], "chrono": ["-", "-", "S"], "prism": ["-", "C", "A"], "cloud": ["-", "-", "A"],
	"pinball": ["-", "B", "A"], "wild": ["-", "C", "A"],
	# 31 the toybox
	"shark": ["B", "B", "-"], "twister": ["-", "C", "A"], "disco": ["-", "C", "A"], "yoyo": ["B", "A", "-"],
	"portal": ["-", "A", "B"], "saw": ["B", "A", "-"], "voodoo": ["-", "-", "S"], "anvil": ["A", "-", "C"],
}
## Tags shift one attribute up a grade.
const TAG_ATTR := { "fury": "str", "bulwark": "str", "blood": "str", "demolition": "str",
	"edge": "dex", "shadow": "dex", "fortune": "dex",
	"arcane": "int", "pyre": "int", "frost": "int", "storm": "int", "venom": "int", "malice": "int", "swarm": "int" }
## Trait family -> attribute it trains.
const FAMILY_ATTR := TAG_ATTR
## Starting spreads per hero.
const HERO := {
	"hexer": [1, 1, 4], "poacher": [1, 4, 1], "brute": [5, 1, 0], "gravedigger": [3, 2, 1], "alchemist": [0, 2, 4],
	"warden": [2, 2, 2], "banehunter": [3, 3, 0], "oathbreaker": [5, 0, 1], "wayfarer": [2, 4, 0],
	"racketeer": [1, 4, 1], "condemned": [3, 2, 1], "cartomancer": [0, 2, 4], "sellsword": [4, 2, 0],
	"gaolbird": [2, 4, 0],
	"beekeeper": [1, 2, 3], "clockmaker": [2, 2, 2], "minstrel": [1, 2, 3], "jester": [1, 4, 1], "berserker": [6, 1, 0], "forsaken": [1, 1, 1], "tinkerer": [1, 3, 2], "boneweaver": [0, 2, 4], "mirrorknight": [4, 1, 1], "plaguesaint": [1, 2, 3],
	"frostwitch": [0, 2, 4], "demolitionist": [4, 1, 1], "executioner": [5, 1, 0], "pilgrim": [3, 1, 2], "beastmaster": [3, 3, 0], "inkling": [1, 2, 3], "mindwarden": [0, 1, 6], "tavernknight": [6, 1, 0],
}

static var _cache := {}

static func enabled() -> bool:
	return GameData.rogues()

## Grades for a weapon: { "str": "A", "dex": "C", "int": "-" }.
static func scaling(w: Dictionary) -> Dictionary:
	if w.has("scaling"):
		return w["scaling"]
	var key: String = w["id"]
	if _cache.has(key):
		return _cache[key]
	var base: Array = KIND.get(w["kind"], ["C", "C", "C"])
	var g := { "str": base[0], "dex": base[1], "int": base[2] }
	for t in w["tags"]:
		if TAG_ATTR.has(t):
			g[TAG_ATTR[t]] = _up(g[TAG_ATTR[t]])
	if w["rarity"] in ["legend", "mythic"]:
		var best := "str"
		for a in ATTRS:
			if COEF[g[a]] > COEF[g[best]]:
				best = a
		g[best] = "S"
	_cache[key] = g
	return g

static func _up(grade: String) -> String:
	if grade == "-":
		return "D"
	return GRADES[maxi(0, GRADES.find(grade) - 1)]

static func value(p: Player, a: String) -> int:
	match a:
		"str": return p.a_str
		"dex": return p.a_dex
	return p.a_int

## Weapon damage multiplier from attributes (1.0 when off).
static func mult(p: Player) -> float:
	if p.weapon == null:
		return 1.0
	return mult_for(p, p.weapon)

static func mult_for(p: Player, w: Dictionary) -> float:
	if not enabled():
		return 1.0
	var g := scaling(w)
	var m := 0.0
	for a in ATTRS:
		m += COEF[g[a]] * value(p, a)
	return 1.0 + PER_POINT * m

static func add(p: Player, a: String, n: int) -> void:
	var before := value(p, a if a in ATTRS else "int")
	match a:
		"str": p.a_str += n
		"dex": p.a_dex += n
		_: p.a_int += n
	_side(p, a if a in ATTRS else "int", before, value(p, a if a in ATTRS else "int"))

## 8.3 (his ask, 6 Oct: "stat stacking ... to buff weapons and builds"): besides weapon damage, each
## attribute adds a stat of its own. STR: +1 max heart for every 5 points. DEX: +1% crit a point.
## INT: +2% burn, poison and lightning damage a point. Kept exact when points come and go.
const SIDE := "STR: +1 MAX HEART PER 5.  DEX: +1% CRIT EACH.  INT: +2% BURN, POISON AND LIGHTNING DAMAGE EACH."
static func _side(p: Player, a: String, before: int, after: int) -> void:
	if not enabled() or before == after:
		return
	match a:
		"str":
			var d := (floori(after / 5.0) - floori(before / 5.0)) * 2
			if d != 0:
				p.max_hp = maxi(2, p.max_hp + d)
				p.hp = clampi(p.hp + maxi(0, d), 1, p.max_hp)
		"dex":
			p.crit += 0.01 * (after - before)
		"int":
			var k := 0.02 * (after - before)
			p.burn_dmg += k
			p.poison_dmg += k
			p.storm_dmg += k

static func highest(p: Player) -> String:
	var best := "str"
	for a in ATTRS:
		if value(p, a) > value(p, best):
			best = a
	return best

static func start(p: Player) -> void:
	if not enabled():
		return
	var s: Array = HERO.get(p.hero["id"], [2, 2, 2])
	for i in ATTRS.size():
		add(p, ATTRS[i], s[i] - value(p, ATTRS[i]))   # through add(): the side stats come with them

## One trait rank trains its family's attribute (core traits train your best one).
static func on_trait(p: Player, fam: String) -> void:
	if enabled():
		add(p, FAMILY_ATTR.get(fam, highest(p)), 1)

static func grade_line(w: Dictionary) -> String:
	var g := scaling(w)
	return "%s %s  %s %s  %s %s" % ["STR", g["str"], "DEX", g["dex"], "INT", g["int"]]
