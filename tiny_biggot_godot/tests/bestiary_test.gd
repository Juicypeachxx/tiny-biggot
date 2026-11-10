extends Node
## 22.3 THE BESTIARY AND PAST RUNS (scripts/game/bestiary.gd). Run:
##   godot --headless --path . res://tests/bestiary_test.tscn -- --no-save
## Every foe and guardian is listed once, with a sprite; every name, place and line it shows is in
## the pixel font and fits its panel; a foe that turns up is met and one that dies is counted; the
## log keeps the last ten runs, newest first. Prints "bestiary test: PASSED" or a FAIL line.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL bestiary: ", msg)

func _font_ok(s: String) -> bool:
	for c in s:
		if not Gfx.FONT_CHARS.contains(c):
			return false
	return true

func _ready() -> void:
	await get_tree().process_frame
	var list := Bestiary.entries()
	var keys := {}
	for e in list:
		if keys.has(e[0]):
			fail("listed twice: " + e[0])
		keys[e[0]] = true
		if not Img.has(Bestiary.sprite_of(e)):
			fail("no sprite for " + e[0])
		var shown := [Bestiary.name_of(e), ("A GUARDIAN OF " if e[1] else "LIVES IN ") + Bestiary.where(e[0]), "'" + Bestiary.line_of(e) + "'"]
		for s in shown:
			if not _font_ok(s):
				fail("not in the font: '%s' (%s)" % [s, e[0]])
		if TB.text_w(shown[0], 2) > TB.SW - 70 or TB.text_w(shown[1]) > TB.SW - 70 or TB.text_w(shown[2]) > TB.SW - 70:
			fail("too wide for the panel: %s" % e[0])
	var want := GameData.BOSSES.size()
	for k in GameData.ENEMIES:
		if not k in Bestiary.SKIP:
			want += 1
	if list.size() != want:
		fail("%d entries, not %d" % [list.size(), want])
	# Met and slain.
	G.hero_index = 2
	G.new_run()
	G.god = true
	Meta.meta.erase("seen")
	Meta.meta.erase("slain")
	if Bestiary.has_met("skeleton"):
		fail("met before it turned up")
	var e := Combat.spawn_enemy("skeleton", 200.0, 120.0, false, true)
	if not Bestiary.has_met("skeleton"):
		fail("a skeleton turned up and was not met")
	Combat.kill_enemy(e)
	if Bestiary.kills("skeleton") != 1:
		fail("slain %d, not 1" % Bestiary.kills("skeleton"))
	var b := Combat.spawn_boss("colossus")
	if not Bestiary.has_met("colossus"):
		fail("the Colossus turned up and was not met")
	G.enemies.erase(b)
	G.boss = null
	# Past runs: the last ten, newest first.
	Meta.meta.erase("runs_log")
	for i in 12:
		G.run_stats["kills"] = i
		G.death_by = "test %d" % i
		G.award_embers(false)
	var log: Array = Meta.meta.get("runs_log", [])
	if log.size() != Bestiary.LOG_MAX:
		fail("%d runs kept, not %d" % [log.size(), Bestiary.LOG_MAX])
	elif int(log[0]["kills"]) != 11 or not str(log[0]["how"]).contains("TEST 11"):
		fail("the newest run is not first: %s" % str(log[0]))
	for r in log:
		for s in [str(r["hero"]), str(r["place"]), str(r["how"])]:
			if not _font_ok(s):
				fail("a past run's words are not in the font: " + s)
	print("bestiary test: PASSED" if fails == 0 else "bestiary test: %d FAILED" % fails)
	get_tree().quit()
