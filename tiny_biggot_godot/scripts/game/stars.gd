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

const MAX_POINTS := 60   # (48.2: was 30; the spokes grew from 7 stars to 10)
const DUST_PER_POINT := 250   # 48.2 STAR DUST: a point for every 250
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
		["TEMPERED", "+10% DAMAGE AND +5% CRIT", [["mul", "dmg", 1.1], ["add", "crit", 0.05]]],   # 48.2
		["TWIN STARS", "+1 PROJECTILE", [["add", "count", 1]]],
	],
	"e": [
		["SECOND DAWN", "YOU RISE ONCE MORE FROM DEATH, ONCE PER RUN", [["add", "revive", 1]]],
		["IRON HABIT", "EVERY NEW FLOOR GIVES 1 ARMOR", [{ "on": "on_floor_start", "do": [["armor", 1]] }]],
		["DEEP LUNGS", "+2 MAX HEARTS", [["add", "max_hp", 4], ["add", "hp", 4]]],
		["GRIT", "WHEN HIT AT LOW HEALTH, 30% CHANCE TO HEAL HALF A HEART", [{ "on": "on_damage_taken", "if": "low_hp", "chance": 0.3, "do": [["heal", 1]] }]],
		["BRAMBLE SKIN", "+15 THORNS. WHEN HIT, FOES NEAR YOU BLEED", [["add", "thorns", 15], { "on": "on_damage_taken", "do": [["status_area", "bleed", 1, 50]] }]],
		["OAKEN HEART", "+1 MAX HEART AND 2 ARMOR AT THE START OF A RUN", [["add", "max_hp", 2], ["add", "hp", 2], ["add", "armor", 2]]],   # 48.2
		["DEEP DRAUGHT", "THE GOURD HOLDS ONE MORE SIP", [["hook", "gourd_sips", 1]]],
	],
	"s": [
		["FLEET FOOT", "+12% MOVE SPEED", [["mul", "speed", 1.12]]],
		["SLIPPERY", "+1 ROLL CHARGE", [["add", "dodge_charges", 1], ["add", "charges", 1]]],
		["DEEP POCKETS", "+1 POTION SLOT AND A POTION", [["add", "max_potions", 1], ["add", "potions", 1]]],
		["GHOST STEP", "ROLLING LEAVES A RING OF 6 SHOTS (EVERY 2S)", [{ "on": "on_roll", "cd": 2.0, "do": [["nova", 6, 0.5, "spark"]] }]],
		["SCAVENGER", "20% OF CLEARED ROOMS DROP A HEART", [{ "on": "on_room_clear", "chance": 0.2, "do": [["drop", "heart"]] }]],
		["SWIFT WIND", "+8% MOVE SPEED, ROLLS RECHARGE 10% FASTER", [["mul", "speed", 1.08], ["mul", "dodge_cd", 0.9]]],   # 48.2
		["SPARE STRIDE", "+1 ROLL CHARGE", [["add", "dodge_charges", 1], ["add", "charges", 1]]],
	],
	"w": [
		["GILDED PALM", "+25% GOLD", [["mul", "gold_mult", 1.25]]],
		["FOUR LEAVES", "+1 LUCK", [["add", "luck", 1]]],
		["LOCKSMITH", "+2 KEYS AT THE START OF A RUN", [["add", "keys", 2]]],
		["SILVER TONGUE", "SHOPS 15% CHEAPER", [["add_cap", "shop_disc", 0.15, 0.6]]],
		["DEMOLITION KIT", "+3 BOMBS AT THE START OF A RUN", [["add", "bombs", 3]]],
		["GOLD SENSE", "+30 GOLD AT THE START OF A RUN, +10% GOLD", [["add", "gold", 30], ["mul", "gold_mult", 1.1]]],   # 48.2
		["HAGGLER'S ART", "SHOPS 10% CHEAPER", [["add_cap", "shop_disc", 0.1, 0.6]]],
	],
}
const ICON := { "n": "fam_fury", "e": "fam_bulwark", "s": "fam_shadow", "w": "fam_fortune", "c": "fam_core",
	"ne": "al_law", "se": "al_good", "sw": "al_chaos", "nw": "al_evil" }
const NAME := { "n": "OFFENSE", "e": "DEFENSE", "s": "AGILITY", "w": "FORTUNE",
	"ne": "LAWFUL", "se": "GOOD", "sw": "CHAOTIC", "nw": "EVIL" }
const DIRS := { "n": Vector2(0, -1), "e": Vector2(1, 0), "s": Vector2(0, 1), "w": Vector2(-1, 0),
	"ne": Vector2(0.7071, -0.7071), "se": Vector2(0.7071, 0.7071), "sw": Vector2(-0.7071, 0.7071), "nw": Vector2(-0.7071, -0.7071) }

## 8.1 (his ask, 6 Oct): four diagonal spokes, one per alignment (scripts/game/alignments.gd). A straight
## chain from the heart: +1 point, a small stat, +1 point, a notable star, +1 point, a small stat, a
## notable star. Its perks hold while the alignment leads (2 or more, none higher) or you are devout.
const ALIGN := {
	"ne": ["law", ["+2% CRIT", [["add", "crit", 0.02]]], [
		["DISCIPLINE", "WHILE LAWFUL LEADS: +12% FIRE RATE AND +6% DAMAGE", [{ "on": "while_align", "need": "law", "do": [["buff", "rate", 0.12, 0], ["buff", "dmg", 0.06, 0]] }]],
		["DEVOTION", "WHILE DEVOUT (ONE ALIGNMENT 2 OR MORE, THE OTHER THREE 1 OR LESS): +30% GOLD AND +15% DAMAGE", [{ "on": "while_align", "need": "devout", "do": [["buff", "gold_mult", 0.3, 0], ["buff", "dmg", 0.15, 0]] }]]]],
	"se": ["good", ["+1 ARMOR AT THE START OF A RUN", [["add", "armor", 1]]], [
		["MERCY", "WHILE GOOD LEADS: CLEARING A ROOM HEALS HALF A HEART 30% OF THE TIME", [{ "on": "on_room_clear", "if": "lead_good", "chance": 0.3, "do": [["heal", 1]] }]],
		["SAINTHOOD", "WHILE GOOD LEADS: EVERY NEW FLOOR GIVES 2 ARMOR", [{ "on": "on_floor_start", "if": "lead_good", "do": [["armor", 2]] }]]]],
	"sw": ["chaos", ["+3% FIRE RATE", [["mul", "rate", 1.03]]], [
		["WILD SURGE", "WHILE CHAOTIC LEADS: CRITS STRIKE A RANDOM AILMENT", [{ "on": "on_crit", "if": "lead_chaos", "do": [["rand_status", 1]] }]],
		["ENTROPY", "WHILE CHAOTIC LEADS: 20% OF ATTACKS FIRE 3 EXTRA SHOTS", [{ "on": "on_shoot", "if": "lead_chaos", "chance": 0.2, "do": [["shoot", 3, 0.8, "", 0.2]] }]]]],
	"nw": ["evil", ["+3% DAMAGE", [["mul", "dmg", 1.03]]], [
		["BLOODTHIRST", "WHILE EVIL LEADS: +20% DAMAGE", [{ "on": "while_align", "need": "evil", "do": [["buff", "dmg", 0.2, 0]] }]],
		["SOUL HARVEST", "WHILE EVIL LEADS: KILLS HEAL HALF A HEART 4% OF THE TIME", [{ "on": "on_kill", "if": "lead_evil", "chance": 0.04, "do": [["heal", 1]] }]]]],
}

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
		for k in range(1, 11):   # (48.2: 10 stars a spoke, was 7; the first 7 and their branches as they were)
			var sm: Array = SMALL[side][small_i % SMALL[side].size()]
			small_i += 1
			var idx := _add("%s%d" % [side, k], dv * STEP * k, sm[0], sm[0], sm[1], false, side, prev)
			prev = idx
			# Side branches at every other star: two small stars, then a notable one.
			if k % 2 == 0 or k == 7:   # (48.2: and 8 and 10, a new notable each)
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
	if GameData.rogues():
		for side in ["ne", "se", "sw", "nw"]:   # 8.1: the alignment spokes
			var al: Array = ALIGN[side]
			var key: String = al[0]
			var pt := ["+1 " + Alignments.NAMES[key], [["add", "al_" + key, 1]]]
			var chain := [pt, al[1], pt, al[2][0], pt, al[1], al[2][1]]
			var prev2 := 0
			for k in chain.size():
				var c: Array = chain[k]
				var notable: bool = c.size() == 3
				prev2 = _add("%s%d" % [side, k + 1], DIRS[side] * STEP * (1.2 + k),
					c[0], c[1] if notable else c[0], c[2] if notable else c[1], notable, side, prev2)
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
	return mini(MAX_POINTS, int(Meta.meta.get("bosses", 0)) + 2 * int(Meta.meta.get("wins", 0)) + int(Meta.meta.get("dust", 0)) / DUST_PER_POINT)   # (48.2 STAR DUST)

## 48.2 STAR DUST (his word, 10 Oct: the other game's "Mastery EXP", "+30% for 0-4, 20% for 5-8, 10%
## for 9-12, 5% for 13-16" a cinder): what a run that ends leaves, times the DREAD bonus.
static func dust_for(win: bool) -> int:
	var r := G.run_stats
	var base := int(r.get("kills", 0)) / 4 + (G.floor_index + 1) * 10 + int(r.get("bosses", 0)) * 25 + (100 if win else 0)
	return roundi(base * Dread.dust_mult())

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
