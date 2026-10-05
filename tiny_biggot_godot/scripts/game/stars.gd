class_name Stars
extends RefCounted
## The constellation: a web of passive perks for every run of the expanded game (his ask, 5 Oct,
## from a clip he sent; the names, numbers and icons are this game's own).
##
## The web grows from THE HEART in four directions: offense (up), defense (right), agility (down)
## and fortune (left). Each spoke is a chain of small stars; side branches leave it and end in a
## notable star. A star can be taken only next to one already taken (the heart always is); one can
## be given back only if nothing taken hangs off it. Points: one per guardian ever beaten, two per
## win, up to 30. Taken stars are saved (Meta.meta["stars"]) and apply at the start of each run.

const MAX_POINTS := 30
const STEP := 46.0   # distance between neighbouring stars, in web units

## Small stars along each spoke: [text, effects], cycled.
const SMALL := {
	"n": [["+4% DAMAGE", [["mul", "dmg", 1.04]]], ["+3% CRIT", [["add", "crit", 0.03]]], ["+4% FIRE RATE", [["mul", "rate", 1.04]]]],
	"e": [["+1 ARMOR AT THE START OF A RUN", [["add", "armor", 1]]], ["+5 THORNS", [["add", "thorns", 5]]], ["+1 MAX HEART", [["add", "max_hp", 2], ["add", "hp", 2]]]],
	"s": [["+4% MOVE SPEED", [["mul", "speed", 1.04]]], ["ROLLS RECHARGE 5% FASTER", [["mul", "dodge_cd", 0.95]]], ["+5% SHOT SPEED", [["mul", "shot_speed", 1.05]]]],
	"w": [["+5% GOLD", [["mul", "gold_mult", 1.05]]], ["+10 GOLD AT THE START OF A RUN", [["add", "gold", 10]]], ["SHOPS 3% CHEAPER", [["add_cap", "shop_disc", 0.03, 0.6]]]],
}
## Notable stars at the ends of side branches: [name, text, effects].
const NOTABLE := {
	"n": [
		["WAR SONG", "+15% DAMAGE", [["mul", "dmg", 1.15]]],
		["QUICKDRAW", "+12% FIRE RATE", [["mul", "rate", 1.12]]],
		["KILLER INSTINCT", "+8% CRIT. CRITS DEAL +0.25X", [["add", "crit", 0.08], ["add", "crit_mult", 0.25]]],
		["OVERFLOW", "+1 PROJECTILE, -10% DAMAGE", [["add", "count", 1], ["mul", "dmg", 0.9]]],
		["BLOOD UP", "BELOW HALF HEALTH: +30% DAMAGE", [{ "on": "while_low_hp", "do": [["buff", "dmg", 0.3, 0]] }]],
	],
	"e": [
		["SECOND DAWN", "YOU RISE ONCE MORE FROM DEATH, ONCE PER RUN", [["add", "revive", 1]]],
		["IRON HABIT", "EVERY NEW FLOOR GIVES 1 ARMOR", [{ "on": "on_floor_start", "do": [["armor", 1]] }]],
		["DEEP LUNGS", "+2 MAX HEARTS", [["add", "max_hp", 4], ["add", "hp", 4]]],
		["GRIT", "WHEN HIT AT LOW HEALTH, 30% CHANCE TO HEAL HALF A HEART", [{ "on": "on_damage_taken", "if": "low_hp", "chance": 0.3, "do": [["heal", 1]] }]],
		["BRAMBLE SKIN", "+15 THORNS. WHEN HIT, FOES NEAR YOU BLEED", [["add", "thorns", 15], { "on": "on_damage_taken", "do": [["status_area", "bleed", 1, 50]] }]],
	],
	"s": [
		["FLEET FOOT", "+12% MOVE SPEED", [["mul", "speed", 1.12]]],
		["SLIPPERY", "+1 ROLL CHARGE", [["add", "dodge_charges", 1], ["add", "charges", 1]]],
		["DEEP POCKETS", "+1 POTION SLOT AND A POTION", [["add", "max_potions", 1], ["add", "potions", 1]]],
		["GHOST STEP", "ROLLING LEAVES A RING OF 6 SHOTS (EVERY 2S)", [{ "on": "on_roll", "cd": 2.0, "do": [["nova", 6, 0.5, "spark"]] }]],
		["SCAVENGER", "20% OF CLEARED ROOMS DROP A HEART", [{ "on": "on_room_clear", "chance": 0.2, "do": [["drop", "heart"]] }]],
	],
	"w": [
		["GILDED PALM", "+25% GOLD", [["mul", "gold_mult", 1.25]]],
		["FOUR LEAVES", "+1 LUCK", [["add", "luck", 1]]],
		["LOCKSMITH", "+2 KEYS AT THE START OF A RUN", [["add", "keys", 2]]],
		["SILVER TONGUE", "SHOPS 15% CHEAPER", [["add_cap", "shop_disc", 0.15, 0.6]]],
		["DEMOLITION KIT", "+3 BOMBS AT THE START OF A RUN", [["add", "bombs", 3]]],
	],
}
const ICON := { "n": "fam_fury", "e": "fam_bulwark", "s": "fam_shadow", "w": "fam_fortune", "c": "fam_core" }
const NAME := { "n": "OFFENSE", "e": "DEFENSE", "s": "AGILITY", "w": "FORTUNE" }

static var _nodes: Array = []     # [{ id, pos: Vector2, name, text, effects, notable, side, links: [index] }]
static var _by_id := {}

## The web, built the same way every time.
static func nodes() -> Array:
	if not _nodes.is_empty():
		return _nodes
	_add("heart", Vector2.ZERO, "THE HEART", "WHERE EVERY PATH BEGINS", [], true, "c", -1)
	var dirs := { "n": Vector2(0, -1), "e": Vector2(1, 0), "s": Vector2(0, 1), "w": Vector2(-1, 0) }
	for side in ["n", "e", "s", "w"]:
		var dv: Vector2 = dirs[side]
		var perp := Vector2(-dv.y, dv.x)
		var prev := 0
		var small_i := 0
		var notable_i := 0
		for k in range(1, 8):
			var sm: Array = SMALL[side][small_i % SMALL[side].size()]
			small_i += 1
			var idx := _add("%s%d" % [side, k], dv * STEP * k, sm[0], sm[0], sm[1], false, side, prev)
			prev = idx
			# Side branches at every other star: two small stars, then a notable one.
			if k % 2 == 0 or k == 7:
				for sgn in ([1, -1] if k == 4 else [1 if (k / 2) % 2 == 0 else -1]):
					if notable_i >= NOTABLE[side].size():
						break
					var bp := idx
					for j in range(1, 3):
						var sm2: Array = SMALL[side][small_i % SMALL[side].size()]
						small_i += 1
						bp = _add("%s%d%s%d" % [side, k, "a" if sgn > 0 else "b", j], _branch(dv, perp, sgn, k, j),
							sm2[0], sm2[0], sm2[1], false, side, bp)
					var nb: Array = NOTABLE[side][notable_i]
					notable_i += 1
					_add("%s%d%s3" % [side, k, "a" if sgn > 0 else "b"], _branch(dv, perp, sgn, k, 3) + dv * STEP * 0.4,
						nb[0], nb[1], nb[2], true, side, bp)
	return _nodes

## A side branch leans outward, so it stays in its own quarter of the web.
static func _branch(dv: Vector2, perp: Vector2, sgn: int, k: int, j: int) -> Vector2:
	return dv * STEP * (k + j * 0.5) + perp * sgn * STEP * j * 0.8

static func _add(id: String, pos: Vector2, name: String, text: String, effects: Array, notable: bool, side: String, link_to: int) -> int:
	var n := { "id": id, "pos": pos, "name": name, "text": text, "effects": effects, "notable": notable, "side": side, "links": [] }
	_nodes.append(n)
	var i := _nodes.size() - 1
	_by_id[id] = i
	if link_to >= 0:
		n["links"].append(link_to)
		_nodes[link_to]["links"].append(i)
	return i

static func taken() -> Dictionary:
	if not (Meta.meta.get("stars") is Dictionary):
		Meta.meta["stars"] = {}
	return Meta.meta["stars"]

static func is_taken(i: int) -> bool:
	return i == 0 or taken().has(nodes()[i]["id"])

static func points() -> int:
	if DebugArgs.has("unlock-all"):
		return MAX_POINTS
	return mini(MAX_POINTS, int(Meta.meta.get("bosses", 0)) + 2 * int(Meta.meta.get("wins", 0)))

static func spent() -> int:
	return taken().size()

static func can_take(i: int) -> bool:
	if is_taken(i) or spent() >= points():
		return false
	for j in nodes()[i]["links"]:
		if is_taken(j):
			return true
	return false

## A star can be given back when every other taken star still joins the heart without it.
static func can_give_back(i: int) -> bool:
	if i == 0 or not is_taken(i):
		return false
	var seen := { 0: true }
	var q := [0]
	while not q.is_empty():
		var c: int = q.pop_back()
		for j in nodes()[c]["links"]:
			if j != i and is_taken(j) and not seen.has(j):
				seen[j] = true
				q.append(j)
	return seen.size() == spent()   # the heart plus every taken star but this one

static func take(i: int) -> bool:
	if not can_take(i):
		return false
	taken()[nodes()[i]["id"]] = true
	Meta.write_save()
	return true

static func give_back(i: int) -> bool:
	if not can_give_back(i):
		return false
	taken().erase(nodes()[i]["id"])
	Meta.write_save()
	return true

static func reset() -> void:
	taken().clear()
	Meta.write_save()

## At the start of a run (G.new_run, expanded game only).
static func apply_to(p: Player) -> void:
	nodes()
	for id in taken().keys():
		if not _by_id.has(id):
			taken().erase(id)   # a star that no longer exists in the web
			continue
		var n: Dictionary = _nodes[_by_id[id]]
		var direct := []
		for e in n["effects"]:
			if e is Array and e[0] == "add" and e[1] in ["gold", "keys", "bombs"]:
				p.set(e[1], p.get(e[1]) + e[2])   # things you carry, not stats
			else:
				direct.append(e)
		Effects.apply(p, direct, 1, "star:" + id)
	p.hp = mini(p.hp, p.max_hp)
