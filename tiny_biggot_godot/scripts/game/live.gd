class_name Live
extends RefCounted
## 10.1 Live descriptions (his ask, 6 Oct, from his trailer clips: "dynamic descriptions"). A text
## whose bonus grows with the run shows what it gives right now: "+20% DAMAGE FOR EACH EMPTY GEAR
## SLOT (+60% NOW)". Read straight from the item's or trait's effects (the damage hooks, the "stack"
## bonuses and GOLDEN BLOOD's miser), so new content that uses them shows its value with no extra
## work. Expanded game only; the text itself is never changed.

## The current bonus of these effects as " (+N% NOW)", or "" when they do not grow.
static func now(effects: Array, p: Player) -> String:
	if p == null or not GameData.rogues():
		return ""
	var total := 0.0
	var found := false
	for e in effects:
		if e is Array and e.size() >= 3:
			if e[0] == "hook":
				var v := _hook(String(e[1]), float(e[2]), p)
				if v >= 0.0:
					total += v
					found = true
			elif e[0] == "set" and e[1] == "miser":
				total += Combat.held_gold(p) / 1000.0
				found = true
		elif e is Dictionary:
			for a in e.get("do", []):
				if a is Array and a.size() >= 5 and a[0] == "stack":
					total += float(p.gf.get(a[4], 0.0))
					found = true
	if not found:
		return ""
	return " (+%d%% NOW)" % roundi(total * 100.0)

static func _hook(key: String, v: float, p: Player) -> float:
	match key:
		"gold_dmg": return v * Combat.held_gold(p) / 100.0
		"relic_dmg": return v * p.relics.size()
		"curse_dmg", "curse_rate", "curse_crit": return v * Burdens.curses(p)   # 49.1
		"slain_dmg", "slain_rate", "slain_crit": return v * Burdens.slain(p)
		"armor_dmg": return v * mini(p.armor, 6)
		"collect_dmg": return v * p.stat_picks
		"idle_dmg":
			var empty := 0
			for sl in Gear.slots():
				if p.gear.get(sl) == null:
					empty += 1
			return v * empty
		"zealot_dmg":
			var top := 0
			for k in Alignments.KEYS:
				top = maxi(top, Alignments.value(p, k))
			return v * top
		"trait_dmg":
			var ranks := 0
			for r in p.traits.values():
				ranks += r
			return v * ranks
	return -1.0

## A trait's or item's text with its live value.
static func desc(t: Dictionary) -> String:
	if t.has("more_text"):   # 43.7: the value now belongs to the old text, before its added sentence
		return t["base_desc"] + now(t.get("effects", []), G.player) + ". " + t["more_text"]
	return t["desc"] + now(t.get("effects", []), G.player)
