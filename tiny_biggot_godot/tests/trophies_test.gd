extends Node
## 7.2 Trophies (scripts/game/trophies.gd). Run:
##   godot --headless --path . res://tests/trophies_test.tscn -- --no-save
##   1. A guardian felled for the first time by a hero is a trophy (once; never Rex).
##   2. New trophies pay embers at the end of the run.
##   3. 5 / 10 / 15 trophies: the hero starts with a potion / a relic / a rare relic more.
##   4. The hero screen's line fits the pixel font.
## Prints "trophies test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL trophies: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(72)
	Meta.meta["trophies"] = {}
	G.hero_index = 0
	var hid: String = GameData.heroes()[0]["id"]
	G.new_run()
	var potions0: int = G.player.potions
	var relics0: int = G.player.relics.size()
	var b := Combat.spawn_boss("colossus")
	G.on_boss_dead(b)
	if Trophies.count(hid) != 1:
		fail("felling the Colossus gave %d trophies" % Trophies.count(hid))
	G.on_boss_dead(Combat.spawn_boss("colossus"))
	if Trophies.count(hid) != 1:
		fail("a second Colossus counted again")
	if Trophies.take(hid, "rex"):
		fail("Rex is a trophy")
	G.award_embers(false)
	if not G.award["parts"].any(func(x): return x[0] == "NEW TROPHIES" and x[1] == Trophies.EMBERS):
		fail("no embers for the new trophy: %s" % [G.award["parts"]])
	var keys := GameData.BOSSES.keys().filter(func(k): return k != "rex")
	for want in [[5, 1, 0], [10, 1, 1], [15, 1, 2]]:
		Meta.meta["trophies"] = { hid: keys.slice(0, want[0]) }
		seed(72)
		G.new_run()
		if G.player.potions != potions0 + want[1] or G.player.relics.size() < relics0 + want[2]:
			fail("%d trophies: %d potions (want %d), %d relics (want %d+) %s" % [want[0], G.player.potions, potions0 + want[1], G.player.relics.size(), relics0 + want[2], G.player.relics.map(func(r): return r["id"])])
	for n in [0, 7, 30]:
		Meta.meta["trophies"] = { hid: keys.slice(0, n) }
		var s := Trophies.line(hid)
		for ch in s:
			if Gfx.glyph_index(ch.unicode_at(0)) < 0:
				fail("the pixel font has no %s" % ch)
		if s.length() * 6 > TB.SW - 20:
			fail("the line is too wide: %s" % s)
	Meta.meta["trophies"] = {}
	print("trophies test: PASSED" if fails == 0 else "trophies test: %d FAILED" % fails)
	get_tree().quit()
