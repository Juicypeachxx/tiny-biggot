extends Node
## 10.1 Live descriptions (scripts/game/live.gd). Run:
##   godot --headless --path . res://tests/live_test.tscn -- --no-save
## A text that grows with the run shows its value now; one that does not shows nothing extra.
## Prints "live test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL live: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	G.hero_index = 0
	G.new_run()
	var p := G.player
	var empty := 0
	for sl in Gear.slots():
		if p.gear.get(sl) == null:
			empty += 1
	var want := " (+%d%% NOW)" % (20 * empty)
	if not Live.desc(Traits.by_id("f_idle")).ends_with(want):
		fail("IDLE HANDS: %s (want ...%s)" % [Live.desc(Traits.by_id("f_idle")), want])
	p.stat_picks = 4
	if not Live.desc(Traits.by_id("y_collector")).ends_with("(+8% NOW)"):
		fail("COLLECTOR: %s" % Live.desc(Traits.by_id("y_collector")))
	p.gf["momentum"] = 0.17
	if not Live.desc(Traits.by_id("y_momentum")).ends_with("(+17% NOW)"):
		fail("MOMENTUM: %s" % Live.desc(Traits.by_id("y_momentum")))
	p.gold = 250
	if not Live.desc(Traits.by_id("g_goldblood")).contains("(+25% NOW)"):
		fail("GOLDEN BLOOD: %s" % Live.desc(Traits.by_id("g_goldblood")))
	if Live.desc(Traits.by_id("might")) != Traits.by_id("might")["desc"]:
		fail("a flat trait got a live value: %s" % Live.desc(Traits.by_id("might")))
	print("live test: PASSED" if fails == 0 else "live test: %d FAILED" % fails)
	get_tree().quit()
