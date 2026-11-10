extends Node
## 21.1 VOICES (scripts/render/barks.gd). Run:
##   godot --headless --path . res://tests/barks_test.tscn -- --no-save
## Lines never move the run's random numbers; bubbles are capped and go away; the hero speaks at
## its moments; an elite taunts; a guardian opens with its line; one ordinary foe in three runs
## when nearly dead (by its number); nothing of it under --classic; the camp remembers the last run.
## Prints "barks test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL barks: ", msg)

func _tick(n: int) -> void:
	for i in n:
		Keys.tick()
		G.update(TB.DT)

func _arena() -> Player:
	G.hero_index = 2
	G.new_run()
	G.god = true
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.enemies.clear()
	G.room.waves_left = 0
	G.locked = true
	G.state = &"play"
	G.player.x = 224.0
	G.player.y = 152.0
	return G.player

func _has(text: String) -> bool:
	return Barks.bubbles.any(func(b): return b["text"] == text)

func _ready() -> void:
	await get_tree().process_frame
	var p := _arena()
	# Lines never touch the run's dice.
	seed(77)
	var a := randi()
	seed(77)
	for i in 12:
		Barks.hero("floor", true)
		Barks.say(p, "HELLO")
	var b := randi()
	if a != b:
		fail("a line moved the run's random numbers")
	if Barks.bubbles.size() > Barks.MAX:
		fail("%d bubbles, more than %d" % [Barks.bubbles.size(), Barks.MAX])
	Barks.update(5.0)
	if not Barks.bubbles.is_empty():
		fail("bubbles did not go away")
	# The hero's moments.
	Barks._hero_t = -99.0
	Barks.hero("boss", true)
	if not Barks.bubbles.any(func(x): return is_same(x["who"], p)):
		fail("the hero said nothing when a guardian fell")
	Barks.reset()
	# An elite taunts when it comes near.
	var el := Combat.spawn_enemy("skeleton", p.x + 60.0, p.y, true, true)
	el.spawn_t = 0.0
	el.x = p.x + 60.0   # (spawn_enemy moves a foe off a pillar or crate: once in six rooms out of reach)
	el.y = p.y
	Barks._tick = 0.0
	Barks._foe_t = 0.0
	Barks.update(TB.DT)
	if not Barks.bubbles.any(func(x): return is_same(x["who"], el)):
		fail("the elite did not taunt")
	G.enemies.clear()
	Barks.reset()
	# A guardian opens its fight with its line.
	var boss := Combat.spawn_boss("colossus")
	boss.spawn_t = 0.0
	G.boss = boss
	for i in 60:
		Barks.update(TB.DT)
	if not _has(Barks.BOSS_LINES["colossus"]):
		fail("the Colossus did not open with its line")
	G.boss = null
	G.enemies.clear()
	Barks.reset()
	# One foe in three runs when nearly dead, by its number.
	var runners := 0
	var stayers := 0
	for k in 6:
		G.enemies.clear()
		var f := Combat.spawn_enemy("slime", p.x + 30.0, p.y, false, true)
		f.spawn_t = 0.0
		f.hp = f.max_hp * 0.1
		var d0 := TB.dist(f, p)
		for i in 40:
			Combat.update_enemies(TB.DT)
		if f.uid % 3 == 0:
			runners += 1
			if TB.dist(f, p) <= d0 + 4.0:
				fail("a foe that should run did not get away (%.0f -> %.0f)" % [d0, TB.dist(f, p)])
		else:
			stayers += 1
			if f.flee_t > 0.0:
				fail("a foe that should stay ran")
	if runners == 0 or stayers == 0:
		fail("the six foes were all one kind (%d ran, %d stayed)" % [runners, stayers])
	# Under --classic nothing speaks and nothing runs.
	GameData.force_classic = true
	Barks.reset()
	Barks.say(p, "NOTHING")
	var g := Combat.spawn_enemy("slime", p.x + 30.0, p.y, false, true)
	g.hp = 1.0
	while g.uid % 3 != 0:
		g = Combat.spawn_enemy("slime", p.x + 30.0, p.y, false, true)
		g.hp = 1.0
	if not Barks.bubbles.is_empty() or Barks.flee(g, TB.DT, p):
		fail("a line or a run under --classic")
	GameData.force_classic = false
	G.enemies.clear()
	# The camp remembers the last run.
	G.death_by = "a test skeleton"
	G.floor_index = 4
	Barks.remember(false)
	var line := Barks.last_run_line()
	if not line.contains("FLOOR 5") or not line.contains("A TEST SKELETON"):
		fail("the last run was not remembered: %s" % line)
	Camp.enter()
	_tick(5)
	var arch: Dictionary = {}
	for o in G.room.objects:
		if o["kind"] == "n_archivist":
			arch = o
	G.player.x = arch["x"] - 40.0
	G.player.y = arch["y"]
	_tick(3)
	if not Barks.bubbles.any(func(x): return is_same(x["who"], arch) and str(x["text"]).contains("FLOOR 5")):
		fail("the archivist did not greet you with your last run")
	print("barks test: PASSED" if fails == 0 else "barks test: %d FAILED" % fails)
	get_tree().quit()
