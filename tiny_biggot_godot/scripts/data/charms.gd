class_name Charms
extends RefCounted
## 37.2 CHARMS (his word, 9 Oct: "Ideas for sprites for new stuff, and new stuff to add"; the idea of
## a row of small passive charms; our own look: a TOKEN, a coin on a string with a symbol struck
## into it, tools/art/stage37_charms.py). Expanded game only.
##   A charm is worn in a CHARM SLOT: 3 to start, + gf charm_slots (CHARM BRACELET, COLLECTOR).
##   Picked up from the floor it goes into a free slot, or the backpack. In the backpack, USE wears
##   it (with every slot taken, take one off first: pick it in the charm row, USE). ROLL drops it.
##   Charms come from chests (a chance), elites, and one for sale in every shop.
## Their effects are reversible (they come off cleanly): Effects.apply_equipment with "charm:<id>".

const BASE_SLOTS := 3
const MAX_SLOTS := 6

## [id, name, rarity, text, effects]; the sprite is the id.
const ROWS := [
	["ch_star", "STAR TOKEN", "common", "+5% CRIT CHANCE.", [["add", "crit", 0.05]]],
	["ch_heart", "HEART TOKEN", "rare", "+1 MAX HEART.", [["add", "max_hp", 2], ["add", "hp", 2]]],
	["ch_skull", "SKULL TOKEN", "rare", "+15% DAMAGE TO ELITES.", [["add", "elite_mult", 0.15]]],
	["ch_eye", "EYE TOKEN", "common", "+1 LUCK.", [["add", "luck", 1]]],
	["ch_fang", "FANG TOKEN", "common", "6% OF HITS BLEED.", [{ "on": "on_hit", "chance": 0.06, "do": [["status", "bleed", 1]] }]],
	["ch_leaf", "LEAF TOKEN", "common", "A CLEARED ROOM HAS A 25% CHANCE TO HEAL HALF A HEART.", [{ "on": "on_room_clear", "chance": 0.25, "do": [["heal", 1]] }]],
	["ch_flame", "FLAME TOKEN", "common", "+8% BURN CHANCE.", [["add", "burn", 0.08]]],
	["ch_drop", "DROP TOKEN", "common", "8% OF HITS POISON.", [{ "on": "on_hit", "chance": 0.08, "do": [["status", "poison", 1]] }]],
	["ch_bolt", "BOLT TOKEN", "common", "8% OF HITS SHOCK.", [{ "on": "on_hit", "chance": 0.08, "do": [["status", "shock", 1]] }]],
	["ch_moon", "MOON TOKEN", "rare", "+1 MOON.", [["add", "orbitals", 1]]],
	["ch_sun", "SUN TOKEN", "epic", "+10% DAMAGE.", [["mul", "dmg", 1.1]]],
	["ch_cross", "CROSS TOKEN", "rare", "EVERY FLOOR STARTS WITH +1 ARMOR.", [{ "on": "on_floor_start", "do": [["armor", 1]] }]],
	["ch_arrow", "ARROW TOKEN", "common", "+1 PIERCE.", [["add", "pierce", 1]]],
	["ch_spiral", "SPIRAL TOKEN", "rare", "+15% AURA REACH.", [["hook", "aura_reach", 0.15]]],
	["ch_coin", "COIN TOKEN", "common", "+15% GOLD.", [["mul", "gold_mult", 1.15]]],
	["ch_key", "KEY TOKEN", "common", "EVERY FLOOR: A KEY BESIDE YOU.", [{ "on": "on_floor_start", "do": [["drop", "key"]] }]],
	["ch_wing", "WING TOKEN", "common", "+8% MOVE SPEED.", [["mul", "speed", 1.08]]],
	["ch_shield", "SHIELD TOKEN", "rare", "STOPS A HIT EVERY 12S.", [["hook", "block_rate", 0.83]]],
	["ch_sword", "SWORD TOKEN", "common", "+8% DAMAGE.", [["mul", "dmg", 1.08]]],
	["ch_clover", "CLOVER TOKEN", "common", "+3% LUCKY HITS: A LUCKY HIT STRIKES AGAIN.", [["hook", "lucky", 0.03]]],
	["ch_hourglass", "HOURGLASS TOKEN", "rare", "+10% FIRE RATE.", [["mul", "rate", 1.1]]],
	["ch_crown", "CROWN TOKEN", "legend", "+1 STR, DEX AND INT.", [["attr", "str", 1], ["attr", "dex", 1], ["attr", "int", 1]]],
	["ch_die", "DIE TOKEN", "rare", "EVERY FLOOR: A FREE DIE.", [{ "on": "on_floor_start", "do": [["dice", "any", 1]] }]],
	["ch_wave", "WAVE TOKEN", "common", "+10% SHOT SPEED.", [["mul", "shot_speed", 1.1]]],
	["ch_snow", "SNOW TOKEN", "common", "+8% CHILL CHANCE.", [["add", "chill", 0.08]]],
	["ch_feather", "FEATHER TOKEN", "rare", "+1 ROLL CHARGE.", [["add", "dodge_charges", 1]]],
	["ch_chain", "CHAIN TOKEN", "common", "+10% ARC CHANCE.", [["add", "chain", 0.1]]],
	["ch_gem", "GEM TOKEN", "common", "+10% EXPERIENCE.", [["mul", "xp_mult", 1.1]]],
	["ch_rune", "RUNE TOKEN", "rare", "+10% DAMAGE OF YOUR ITEMS' EFFECTS.", [["hook", "proc_dmg", 0.1]]],
	["ch_bone", "BONE TOKEN", "common", "+10% COMPANION DAMAGE.", [["hook", "minion_dmg", 0.1]]],
]
const RARITY_W := { "common": 60, "rare": 30, "epic": 8, "legend": 2 }

static var _list: Array = []
static var _by_id := {}

static func all() -> Array:
	if _list.is_empty():
		for row in ROWS:
			var c := { "id": row[0], "name": row[1], "rarity": row[2], "desc": row[3], "effects": row[4], "item": "charm",
				"sprite": row[0], "tags": [], "new": true }
			_list.append(c)
			_by_id[c["id"]] = c
	return _list

static func by_id(id: String) -> Dictionary:
	all()
	return _by_id[id]

static func has(id: String) -> bool:
	all()
	return _by_id.has(id)

static func on() -> bool:
	return GameData.rogues()

static func slots(p: Player) -> int:
	return mini(MAX_SLOTS, BASE_SLOTS + int(p.g("charm_slots")))

static func wearing(p: Player, id: String) -> bool:
	return p.charms.any(func(c): return c["id"] == id)

## A random charm (none worn, none banished by a die, if there is one).
static func random_charm(p: Player) -> Dictionary:
	var rar: String = TB.weighted(RARITY_W)
	var pool := all().filter(func(c): return c["rarity"] == rar and not wearing(p, c["id"]) and not Dice.banned(c["id"]))
	if pool.is_empty():
		pool = all().filter(func(c): return not wearing(p, c["id"]))
	return TB.pick(pool if not pool.is_empty() else all())

## Wears a charm in a free slot. False with every slot taken (or already worn).
static func wear(p: Player, c: Dictionary) -> bool:
	if p.charms.size() >= slots(p) or wearing(p, c["id"]):
		return false
	p.charms.append(c)
	Effects.apply_equipment(p, c["effects"], 1, "charm:" + c["id"])
	Effects.recount_tags(p)
	return true

## Takes off the charm in slot i and returns it.
static func take_off(p: Player, i: int) -> Variant:
	if i < 0 or i >= p.charms.size():
		return null
	var c: Dictionary = p.charms[i]
	Effects.apply_equipment(p, c["effects"], -1, "charm:" + c["id"])
	p.charms.remove_at(i)
	Effects.recount_tags(p)
	return c

## Picked up from the floor (Game.interact): a free slot, else the backpack.
static func pick_up(p: Player, c: Dictionary) -> bool:
	if wear(p, c):
		G.toast(c["name"] + " WORN", "gold")
		return true
	if G.to_backpack(c):
		return true
	return false

## A chance of a charm on the floor at x, y (chests, elites).
static func maybe(chance: float, x: float, y: float) -> void:
	var p := G.player
	if on() and p != null and randf() < chance:
		G.drop_item(random_charm(p), x, y)

## A charm for sale in an expanded shop.
static func stock_shop(r: Room, cx: float, cy: float) -> void:
	var c := random_charm(G.player)
	r.objects.append({ "kind": "shop", "item": "charm", "thing": c, "x": cx - 144, "y": cy - 8,
		"price": G.price({ "common": 20, "rare": 34, "epic": 52, "legend": 75 }[c["rarity"]] + G.floor_index * 4) })
