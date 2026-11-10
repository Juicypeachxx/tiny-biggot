extends Node
## 18.1 THE DAILY TRIAL (scripts/game/daily.gd). Run:
##   godot --headless --path . res://tests/daily_test.tscn -- --no-save
## A date always gives the same rule, hero and start; each rule does what it says; a run's end
## scores it, keeps the day's best, pays the embers and gives the hero choice back; the camp has
## the stone; every line fits the pixel font.
## Prints "daily test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL daily: ", msg)

func _day_for(m: String) -> int:
	for d in range(20261001, 20261040):
		if Daily.mod_for(d) == m:
			return d
	return -1

func _ready() -> void:
	await get_tree().process_frame
	Meta.meta["daily_best"] = {}
	G.hero_index = 0
	# The same date, the same start.
	Daily.start(20261007)
	var g1: int = G.player.gold
	var w1: String = G.player.weapon["id"]
	var r1 := G.room.seed_value
	Daily.start(20261007)
	if G.player.weapon["id"] != w1 or G.room.seed_value != r1 or G.player.gold != g1:
		fail("the same date gave a different start")
	if G.hero_index != Daily.hero_for(20261007):
		fail("the date's hero was not used")
	for m in Daily.MODS:
		var day := _day_for(m)
		if day < 0:
			fail("no date gives %s" % m)
			continue
		G.hero_index = 0
		Daily.start(day)
		var p := G.player
		match m:
			"glass":
				if p.max_hp > GameData.heroes()[G.hero_index]["hp"] * 2 - 4 + 4 and p.dmg < 1.9:
					fail("GLASS HEROES changed nothing")
			"gold":
				if G.price(100) < 150 or p.gold_mult < 1.9:
					fail("GOLD RUSH: price %d, gold x%.1f" % [G.price(100), p.gold_mult])
			"haste":
				var e := Combat.spawn_enemy("skeleton", 100.0, 100.0, false, true)
				if e.speed < GameData.ENEMIES["skeleton"]["speed"] * 1.29:
					fail("HASTE did not hurry the foes")
			"giants":
				var b := Combat.spawn_boss("colossus")
				Daily.start(_day_for("powder"))   # compare with an ordinary day
				var b2 := Combat.spawn_boss("colossus")
				if b.max_hp < b2.max_hp * 1.45:
					fail("BIG GAME: %.0f vs %.0f" % [b.max_hp, b2.max_hp])
			"powder":
				var rm := World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true })
				RoomDress.furnish(rm)
				if rm.objects.filter(func(o): return o["kind"] == "e_keg").size() < 2:
					fail("POWDER DAY put few kegs in a fight")
		for ch in Daily.MODS[m][0] + Daily.MODS[m][1] + "THE DAILY TRIAL: ":
			if not ch in Gfx.FONT_CHARS:
				fail("'%s' not in the font: %s" % [ch, Daily.MODS[m][1]])
	# The end of a run: a score, the day's best, embers, the hero choice given back.
	G.hero_index = 0
	Daily.start(20261007)
	G.run_stats["kills"] = 30
	G.floor_index = 2
	G.award_embers(false)
	var best := Daily.best(20261007)
	if best <= 0 or not G.award["parts"].any(func(x): return x[0] == "DAILY TRIAL"):
		fail("the trial's end kept no score or paid no embers (%d)" % best)
	if G.hero_index != 0:
		fail("the hero choice was not given back")
	Camp.enter()
	if not G.room.objects.any(func(o): return o["kind"] == "c_daily"):
		fail("no daily stone in the camp")
	Meta.meta["daily_best"] = {}
	print("daily test: PASSED" if fails == 0 else "daily test: %d FAILED" % fails)
	get_tree().quit()
