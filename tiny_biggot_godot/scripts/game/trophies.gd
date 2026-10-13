class_name Trophies
extends RefCounted
## 7.2 Trophies (his word "All", 6 Oct): the first time a hero fells a guardian (floor, rift or realm;
## not Rex, who is a good boy) it is that hero's trophy: a banner, and 20 embers at the end of the run.
## The hero screen shows the count (19 guardians). 5 / 10 / 15 trophies: the hero starts every run with a potion /
## a relic / a rare relic too. Expanded game only. Kept in Meta.meta["trophies"]: { hero id: [keys] }.

const STEPS := [[5, "A POTION"], [10, "A RELIC"], [15, "A RARE RELIC"]]
const EMBERS := 20

static func list(hero_id: String) -> Array:
	return Meta.meta.get("trophies", {}).get(hero_id, [])

static func count(hero_id: String) -> int:
	return list(hero_id).size()

static func total() -> int:
	return GameData.BOSSES.keys().filter(func(k): return k != "rex").size()

## G.on_boss_dead. True when it is a new trophy.
static func take(hero_id: String, key: String) -> bool:
	if not GameData.rogues() or key == "rex" or key == "" or list(hero_id).has(key):
		return false
	if not Meta.meta.has("trophies"):
		Meta.meta["trophies"] = {}
	var t: Dictionary = Meta.meta["trophies"]
	if not t.has(hero_id):
		t[hero_id] = []
	t[hero_id].append(key)
	G.run_stats["trophies"] = G.run_stats.get("trophies", 0) + 1
	return true

## G.new_run: the rewards of the hero's trophies so far.
static func apply(p: Player, hero_id: String) -> void:
	if not GameData.rogues():
		return
	var n := count(hero_id)
	if n >= STEPS[0][0]:
		p.potions += 1
		p.max_potions = maxi(p.max_potions, p.potions)
	if n >= STEPS[1][0]:
		var r := G.roll_relics(1, "chest")
		if not r.is_empty(): G.add_relic(p, r[0])
	if n >= STEPS[2][0]:
		var r2 := G.roll_relics(1, "iron")
		if not r2.is_empty(): G.add_relic(p, r2[0])

## The hero screen's line.
static func line(hero_id: String) -> String:
	var n := count(hero_id)
	for s in STEPS:
		if n < s[0]:
			return "TROPHIES %d/%d   AT %d: STARTS WITH %s" % [n, total(), s[0], s[1]]
	return "TROPHIES %d/%d   STARTS WITH A POTION AND TWO RELICS" % [n, total()]
