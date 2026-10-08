extends Node
## 21.6 THE CAMP FOLLOWS THE IPAD'S CLOCK (scripts/game/camp_clock.gd). Run:
##   godot --headless --path . res://tests/camp_clock_test.tscn -- --no-save
## The hour gives the part of the day; the camp's sound follows it (birdsong by day, crickets after
## dark); songbirds land in the morning; the cat leaves one gift a day (a fish or embers) and it is
## taken once. Prints "camp clock test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL camp clock: ", msg)

func _tick(n: int) -> void:
	for i in n:
		Keys.tick()
		G.update(TB.DT)

func _ready() -> void:
	await get_tree().process_frame
	for pair in [[4, "night"], [5, "morning"], [8, "morning"], [11, "day"], [16, "day"], [17, "evening"], [20, "evening"], [21, "night"], [0, "night"]]:
		CampClock.force_hour = pair[0]
		if CampClock.phase() != pair[1]:
			fail("%d o'clock is %s, not %s" % [pair[0], CampClock.phase(), pair[1]])
	# The camp at eight in the morning: birdsong, songbirds, a gift by the cat.
	Meta.meta["cat_pets"] = CampLife.CAT_STAYS   # Soot always comes
	Meta.meta.erase("cat_gift")
	CampClock.force_hour = 8
	Camp.enter()
	if Snd.ambience_name() != "campday":
		fail("the morning camp sounds of '%s', not birdsong" % Snd.ambience_name())
	if not CampClock.birds():
		fail("no songbirds in the morning")
	for i in 600:
		RoomDress.tick(TB.DT)   # (world_view ticks the critters; a headless test has none)
	if not RoomDress._critters.any(func(c): return c["kind"] == "bird"):
		fail("no songbird came down in ten seconds of morning")
	var gift: Dictionary = {}
	for o in G.room.objects:
		if o["kind"] == "c_gift":
			gift = o
	if gift.is_empty():
		fail("the cat left no gift")
	else:
		var embers := int(Meta.meta.get("embers", 0))
		var fish := CampLife.larder_total()
		CampClock.take(gift)
		if int(Meta.meta.get("embers", 0)) == embers and CampLife.larder_total() == fish:
			fail("the gift gave nothing")
		if not gift.get("gone", false):
			fail("the gift stayed after it was taken")
		Camp.enter()
		if G.room.objects.any(func(o): return o["kind"] == "c_gift"):
			fail("a second gift on the same day")
	# After dark: crickets, no songbirds.
	CampClock.force_hour = 23
	Camp.enter()
	_tick(30)
	if Snd.ambience_name() != "camp" or CampClock.birds():
		fail("the night camp sounds of '%s' (want crickets), birds: %s" % [Snd.ambience_name(), CampClock.birds()])
	CampClock.force_hour = -1
	print("camp clock test: PASSED" if fails == 0 else "camp clock test: %d FAILED" % fails)
	get_tree().quit()
