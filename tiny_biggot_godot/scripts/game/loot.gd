class_name Loot
extends RefCounted
## 38.2 LOOT (his word, 9 Oct, from notes on another game: luck, magic find, treasure find; our own
## numbers). Expanded game only.
##   LUCK           as before (rarer relics, a fourth trait row), and now +2% lucky hits a point
##                  (Lucky.LUCK_LUCKY, +5% a point).
##   MAGIC FIND     gf magic_find: weapons and armour above common come that much more often
##                  (Gear.roll_item_rarity).
##   TREASURE FIND  gf treasure_find: the chance that a cleared fight or an opened chest leaves one
##                  more item (a weapon, an armour piece or a charm). Over 100%: one for sure and a
##                  chance of a second.
## Both show in the backpack screen's stats.

static var stats := {}   # extra items (tests)

static func treasure(x: float, y: float) -> void:
	var p := G.player
	if not GameData.rogues() or p == null:
		return
	var tf := p.g("treasure_find")
	while tf > 0:
		if randf() < tf:
			var f: int = G.floor_index
			var roll := randf()
			var it: Dictionary = Weapons.random_weapon(Gear.roll_item_rarity(f), p.weapon) if roll < 0.4 \
				else (Gear.random_gear(Gear.roll_item_rarity(f)) if roll < 0.8 else Charms.random_charm(p))
			G.drop_item(it, x, y)
			stats["extra"] = stats.get("extra", 0) + 1
			x += 18.0
		tf -= 1.0
