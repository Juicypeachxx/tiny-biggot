extends Node
## 22.1 WEATHER AND NIGHT IN THE DUNGEON (scripts/render/weather.gd). Run:
##   godot --headless --path . res://tests/weather_test.tscn -- --no-save
## Every floor has its weathers; the first floor is always clear; rolling the weather never moves
## the run's dice; it shows on floors, not in rift worlds or the camp; rain and snow change the
## place's sound; a night floor's light comes from the hero's lantern (the Warden's is bigger),
## candles, fires and blasts, and never more than MAX_LIGHTS; nothing under --classic.
## Prints "weather test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL weather: ", msg)

func _room(type: String = "combat") -> Room:
	var r := World.make_room(G.floor_d, type, "", "s", { "no_secret": true })
	G.enter_room(r)
	G.enemies.clear()
	G.state = &"play"
	return r

func _ready() -> void:
	await get_tree().process_frame
	G.run_stats["chapter"] = 4
	for f in GameData.floors():
		if not Weather.BY_FLOOR.has(f["name"]):
			fail("no weather for " + f["name"])
	G.hero_index = 2
	G.new_run()
	G.god = true
	# The first floor is clear; the roll never moves the run's dice; weather does come.
	G.floor_index = 0
	Weather.on_floor_start()
	if Weather.kind != "":
		fail("the first floor has weather: " + Weather.kind)
	seed(7)
	var a := randi()
	seed(7)
	var seen := {}
	var clear := 0
	for k in 60:
		G.run_stats["kills"] = k
		G.floor_index = 1 + k % 10
		Weather.on_floor_start()
		if Weather.kind == "":
			clear += 1
		else:
			seen[Weather.kind] = true
	if randi() != a:
		fail("rolling the weather moved the run's random numbers")
	if seen.size() < 4 or clear == 0:
		fail("over 60 floors: %d kinds of weather, %d clear" % [seen.size(), clear])
	# On a floor; not in a rift world, not in the camp.
	G.floor_index = 6
	Weather.kind = "rain"
	_room()
	if Weather.here() != "rain" or Snd.ambience_name() != "rain":
		fail("a rainy floor: weather '%s', sound '%s'" % [Weather.here(), Snd.ambience_name()])
	Weather.kind = "snow"
	Ambience.on_room()
	if Snd.ambience_name() != "wind":
		fail("a snowy floor sounds of '%s', not wind" % Snd.ambience_name())
	var rift := World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true })
	rift.theme = Themes.by_id("gaol")
	G.enter_room(rift)
	if Weather.here() != "":
		fail("weather inside a rift world")
	# A night floor: the lantern, candles, fires, blasts.
	Weather.kind = "dark"
	var r := _room()
	var p := G.player
	p.x = 200.0
	p.y = 150.0
	var l := Weather.lights()
	if l.is_empty() or absf(l[0].x - p.x) > 0.1 or l[0].z < Weather.LANTERN * 0.95:
		fail("the hero carries no lantern")
	var n0 := l.size()
	r.objects.append({ "kind": "e_candle", "x": 100.0, "y": 100.0 })
	G.zones.append({ "x": 300.0, "y": 200.0, "r": 9, "t": 1.0, "kind": "fire", "tick": 0.0 })
	Weather.flash(250.0, 120.0, 20.0)
	if Weather.lights().size() != n0 + 3:
		fail("a candle, a fire and a blast gave %d lights, not 3" % (Weather.lights().size() - n0))
	for k in 30:
		G.zones.append({ "x": 10.0 * k, "y": 200.0, "r": 9, "t": 1.0, "kind": "fire", "tick": 0.0 })
	if Weather.lights().size() > Weather.MAX_LIGHTS:
		fail("%d lights, more than the shader takes" % Weather.lights().size())
	G.zones.clear()
	var warden := -1
	for i in GameData.heroes().size():
		if GameData.heroes()[i]["id"] == "warden":
			warden = i
	if warden >= 0:
		G.hero_index = warden
		G.new_run()
		G.floor_index = 6
		Weather.kind = "dark"
		_room()
		if Weather.lights()[0].z < Weather.LANTERN * 1.3:
			fail("the Warden's lantern is no bigger")
	if Weather.dark_level() <= 0.0:
		fail("a night floor is not dark")
	# --classic: no weather.
	GameData.force_classic = true
	G.floor_index = 6
	Weather.on_floor_start()
	if Weather.kind != "" or Weather.dark_level() > 0.0:
		fail("weather under --classic")
	GameData.force_classic = false
	print("weather test: PASSED" if fails == 0 else "weather test: %d FAILED" % fails)
	get_tree().quit()
