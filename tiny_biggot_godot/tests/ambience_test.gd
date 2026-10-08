extends Node
## 21.3 THE SOUND OF EACH PLACE (scripts/core/ambience.gd, Snd). Run:
##   godot --headless --path . res://tests/ambience_test.tscn -- --no-save
## Every floor and rift world has a loop and a floor to walk on, the sounds are there and the loops
## repeat; a floor, a rift world and the camp each play their own; walking makes footsteps (a roll
## or standing still does not); the music is fuller while a room is shut for a fight and softer
## once it is quiet; OPTIONS has a switch for it; none of it moves the run's random numbers; none of it under --classic.
## Prints "ambience test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL ambience: ", msg)

func _settle() -> void:
	for i in 30:
		Snd._process(0.1)

func _walk(p: Player, ticks: int, dx: float) -> int:
	var n0 := Snd.steps_taken
	for i in ticks:
		p.x += dx
		Ambience.tick(p)
	return Snd.steps_taken - n0

func _ready() -> void:
	await get_tree().process_frame
	# Every place and floor has its sound, and the loops repeat.
	G.run_stats["chapter"] = 4
	var places := ["camp"]
	var floors_ := ["grass"]
	for f in GameData.floors():
		if not Ambience.FLOOR.has(f["name"]):
			fail("no sound for the floor " + f["name"])
	for t in Themes.LIST + Themes.REALMS:
		if not Ambience.RIFT.has(t["id"]):
			fail("no sound for the rift world " + t["id"])
	for v in Ambience.FLOOR.values() + Ambience.RIFT.values():
		places.append(v[0])
		floors_.append(v[1])
	for pl in places:
		var path := "res://assets/audio/amb/amb_%s.wav" % pl
		var st = load(path) if ResourceLoader.exists(path) else null
		if not st is AudioStreamWAV:
			fail("missing loop " + path)
		elif st.loop_mode != AudioStreamWAV.LOOP_FORWARD:
			fail("the loop %s does not repeat" % path)
	for s in floors_:
		if not ResourceLoader.exists("res://assets/audio/se/cc_step_%s.wav" % s):
			fail("missing footsteps on " + s)
	# A floor, a later floor, a rift world, the camp.
	G.hero_index = 2
	G.new_run()
	G.god = true
	G.start_floor()
	if Snd.ambience_name() != "crypt":
		fail("the Ossuary sounds of '%s', not the crypt" % Snd.ambience_name())
	G.run_stats["chapter"] = 4
	G.floor_index = 17
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	if Snd.ambience_name() != "library":
		fail("the Stacks sound of '%s', not the library" % Snd.ambience_name())
	var rift := World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true })
	rift.theme = Themes.by_id("hell")
	G.enter_room(rift)
	if Snd.ambience_name() != "hearth":
		fail("the hell rift sounds of '%s', not fire" % Snd.ambience_name())
	G.floor_index = 0
	G.run_stats["chapter"] = 1
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.enemies.clear()
	G.state = &"play"
	var p := G.player
	p.x = 100.0
	p.y = 150.0
	# Footsteps: about one every STRIDE pixels walked; none standing still, rolling or leaping.
	Ambience.on_room()
	p.moving = true
	var n := _walk(p, 100, 1.5)
	if n < 6 or n > 8:
		fail("150 px of walking made %d footsteps, not about 7" % n)
	p.moving = false
	if _walk(p, 60, 0.0) != 0:
		fail("footsteps while standing still")
	p.moving = true
	p.dodge_t = 0.3
	if _walk(p, 60, 1.5) != 0:
		fail("footsteps during a roll")
	p.dodge_t = 0.0
	# OPTIONS: PLACE SOUNDS off: no footsteps, the loop fades away.
	Meta.opts["places"] = false
	if _walk(p, 60, 1.5) != 0:
		fail("footsteps with PLACE SOUNDS off")
	_settle()
	if Snd._amb_level[Snd._amb_cur] > 0.0:
		fail("the place's loop still plays with PLACE SOUNDS off")
	Meta.opts["places"] = true
	# The music: full in a fight, softer once the room is quiet.
	G.locked = true
	Ambience.tick(p)
	_settle()
	if absf(Snd.music_level() - Snd.MUSIC_VOL) > 0.001:
		fail("the music is at %.2f in a fight, not %.2f" % [Snd.music_level(), Snd.MUSIC_VOL])
	G.locked = false
	Ambience.tick(p)
	_settle()
	if absf(Snd.music_level() - Snd.MUSIC_CALM) > 0.001:
		fail("the music is at %.2f in a quiet room, not %.2f" % [Snd.music_level(), Snd.MUSIC_CALM])
	# None of it touches the run's dice.
	seed(91)
	var a := randi()
	seed(91)
	Snd.ambience("rain")
	Ambience.on_room()
	p.moving = true
	_walk(p, 120, 1.5)
	Snd.step("snow")
	_settle()
	if randi() != a:
		fail("the sound of a place moved the run's random numbers")
	# The camp.
	Camp.enter()
	if Snd.ambience_name() != "camp":
		fail("the camp sounds of '%s'" % Snd.ambience_name())
	# The title: it fades away, and the music is full again.
	G.state = &"title"
	G.update(TB.DT)
	_settle()
	if Snd.ambience_name() != "" or absf(Snd.music_level() - Snd.MUSIC_VOL) > 0.001:
		fail("the title kept the camp's sound or the soft music")
	# --classic: no place sounds, no footsteps, the music as it always was.
	GameData.force_classic = true
	G.new_run()
	G.start_floor()
	G.state = &"play"
	G.locked = false
	var q := G.player
	q.moving = true
	if Snd.ambience_name() != "" or _walk(q, 100, 1.5) != 0:
		fail("a place sound or footsteps under --classic")
	_settle()
	if absf(Snd.music_level() - Snd.MUSIC_VOL) > 0.001:
		fail("the music softened under --classic")
	GameData.force_classic = false
	print("ambience test: PASSED" if fails == 0 else "ambience test: %d FAILED" % fails)
	get_tree().quit()
