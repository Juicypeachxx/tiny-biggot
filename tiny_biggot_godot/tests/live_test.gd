extends Node
## 10.1 Live descriptions (scripts/game/live.gd). Run:
##   godot --headless --path . res://tests/live_test.tscn -- --no-save
## A text that grows with the run shows its value now; one that does not shows nothing extra.
## Prints "live test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL live: ", msg)

## The value now comes right after the trait's own text: at the end, or (43.7, TraitRevamp) before
## the sentence the revamp added.
func _now_after_text(id: String, want: String) -> bool:
	var t := Traits.by_id(id)
	return Live.desc(t).begins_with(String(t.get("base_desc", t["desc"])) + want)

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
	if not _now_after_text("f_idle", want):
		fail("IDLE HANDS: %s (want ...%s)" % [Live.desc(Traits.by_id("f_idle")), want])
	p.stat_picks = 4
	if not _now_after_text("y_collector", " (+8% NOW)"):
		fail("COLLECTOR: %s" % Live.desc(Traits.by_id("y_collector")))
	p.gf["momentum"] = 0.17
	if not _now_after_text("y_momentum", " (+17% NOW)"):
		fail("MOMENTUM: %s" % Live.desc(Traits.by_id("y_momentum")))
	p.gold = 250
	if not Live.desc(Traits.by_id("g_goldblood")).contains("(+25% NOW)"):
		fail("GOLDEN BLOOD: %s" % Live.desc(Traits.by_id("g_goldblood")))
	if Live.desc(Traits.by_id("might")) != Traits.by_id("might")["desc"]:
		fail("a flat trait got a live value: %s" % Live.desc(Traits.by_id("might")))
	print("live test: PASSED" if fails == 0 else "live test: %d FAILED" % fails)
	get_tree().quit()
