extends Node
## 21.4 LIFE BETWEEN THE FIGHTS (scripts/game/wanderers.gd). Run:
##   godot --headless --path . res://tests/wanderers_test.tscn -- --no-save
## A rival races you to a chest (and takes it if you are slow, leaves if you are first); waved on,
## they fight beside you in your next fight; shot, they fight you and drop the chest and their purse.
## Your last hero's ghost waits on the floor where they fell, with gold. A lost traveller follows
## you, is hurt by foes, runs home after three hits, and at a guardian's door pays with a relic.
## Whether someone turns up never moves the run's random numbers; nothing under --classic.
## Prints "wanderers test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL wanderers: ", msg)

func _tick(n: int) -> void:
	for i in n:
		Keys.tick()
		G.update(TB.DT)

func _room(type: String = "combat") -> Room:
	var r := World.make_room(G.floor_d, type, "", "s", { "no_secret": true })
	G.enter_room(r)
	G.enemies.clear()
	G.room.waves_left = 0
	G.locked = false
	G.room.cleared = true
	G.state = &"play"
	G.player.x = 224.0
	G.player.y = 200.0
	return r

func _find(kind: String) -> Dictionary:
	for o in G.room.objects:
		if o["kind"] == kind and not o.get("gone", false):
			return o
	return {}

func _chest_of(rv: Dictionary) -> Dictionary:
	for o in G.room.objects:
		if o["kind"] == "chest" and o.get("rid", -1) == rv["rid"]:
			return o
	return {}

func _ready() -> void:
	await get_tree().process_frame
	G.hero_index = 2
	G.new_run()
	G.god = true
	G.floor_index = 2
	# Whether someone turns up never moves the run's dice.
	_room()
	seed(31)
	var a := randi()
	seed(31)
	for i in 30:
		G.run_stats["kills"] = i
		G.run_stats.erase("wanderers")
		Wanderers.on_room_clear(G.room)
	if randi() != a:
		fail("turning up moved the run's random numbers")
	# The rival takes the chest when you are slow, and leaves.
	_room()
	Wanderers._rival(G.room)
	var rv := _find("w_rival")
	if rv.is_empty() or _chest_of(rv).is_empty():
		fail("no rival, or no chest with them")
	else:
		var chest := _chest_of(rv)
		for i in 900:
			Wanderers.update(TB.DT)
			if rv.get("gone", false):
				break
		if not chest.get("gone", false) or not rv.get("has_chest", false):
			fail("the rival did not take the chest")
		if not rv.get("gone", false):
			fail("the rival did not leave")
	# You get there first: they leave without it.
	_room()
	Wanderers._rival(G.room)
	rv = _find("w_rival")
	if not rv.is_empty():
		_chest_of(rv)["opened"] = true
		Wanderers.update(TB.DT)
		if rv["st"] != "leave" or rv.get("has_chest", false):
			fail("the rival did not give up when you opened the chest")
	# Waved on: they come back to fight beside you.
	_room()
	Wanderers._rival(G.room)
	rv = _find("w_rival")
	if not rv.is_empty():
		Wanderers.interact(rv)
		if int(G.run_stats.get("rival_owes", -1)) != G.floor_index:
			fail("waving the rival on did not make them owe you")
		var fight := World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true })
		G.enter_room(fight)
		var ally := _find("w_rival")
		if ally.is_empty() or ally["st"] != "ally":
			fail("the rival did not come back to help")
		else:
			G.enemies.clear()
			var foe := Combat.spawn_enemy("slime", ally["x"] + 80.0, ally["y"], false, true)
			foe.spawn_t = 0.0
			var n0: int = G.pbullets.size() + G.new_pbullets.size()
			ally["cd"] = 0.0
			Wanderers._update_ally(ally, TB.DT)
			if G.pbullets.size() + G.new_pbullets.size() <= n0:
				fail("the rival ally did not shoot at a foe")
			G.enemies.clear()
	# Shot: they fight for it, then give up, dropping the chest and their purse.
	_room()
	Wanderers._rival(G.room)
	rv = _find("w_rival")
	if not rv.is_empty():
		rv["has_chest"] = true
		var b := Combat.new_pbullet()
		b.x = rv["x"]
		b.y = rv["y"] - 6.0
		b.life = 1.0
		G.pbullets.append(b)
		Wanderers.update(TB.DT)
		G.pbullets.erase(b)
		var foe: Enemy = null
		for e in G.enemies:
			if e.d.get("rival", false):
				foe = e
		if foe == null:
			fail("shooting the rival did not start a fight")
		else:
			if foe.d["sprite"] != rv["sprite"]:
				fail("the rival fights with another face")
			var g0 := G.player.gold
			var chests := G.room.objects.filter(func(o): return o["kind"] == "chest").size()
			Combat.kill_enemy(foe)
			if G.player.gold <= g0:
				fail("the beaten rival dropped no gold")
			if G.room.objects.filter(func(o): return o["kind"] == "chest").size() <= chests:
				fail("the beaten rival did not drop the chest")
	G.enemies.clear()
	# The ghost of your last hero, where they fell, with gold.
	G.player.gold = 100
	G.player.x = 150.0
	G.player.y = 120.0
	G.on_death("a test")
	var gh: Dictionary = Meta.meta.get("ghost", {})
	if gh.is_empty() or int(gh["floor"]) != 2 or int(gh["gold"]) != 40:
		fail("the fallen hero was not remembered: %s" % str(gh))
	G.new_run()
	G.god = true
	G.floor_index = 2
	_room()
	Wanderers.on_room_clear(G.room)
	var ghost := _find("w_ghost")
	if ghost.is_empty():
		fail("no ghost on the floor where the hero fell")
	else:
		var g0 := G.player.gold
		Wanderers.interact(ghost)
		if G.player.gold != g0 + 40:
			fail("the ghost gave %d gold, not 40" % (G.player.gold - g0))
		if Meta.meta.has("ghost"):
			fail("the ghost stayed after its gold was taken")
		for i in 200:
			Wanderers.update(TB.DT)
		if not ghost.get("gone", false):
			fail("the ghost did not fade")
	# A lost traveller: follows you, hurt by foes, runs home after three hits.
	_room()
	Wanderers._traveller(G.room)
	var tv := _find("w_traveller")
	if tv.is_empty():
		fail("no traveller")
	else:
		Wanderers.interact(tv)
		if not G.run_stats.get("traveller") is Dictionary:
			fail("leading the traveller did not take them along")
		_room()
		tv = _find("w_traveller")
		if tv.is_empty() or tv["st"] != "follow":
			fail("the traveller did not come into the next room")
		else:
			G.player.x = 300.0
			for i in 60:
				Wanderers.update(TB.DT)
			if TB.dist_xy(tv["x"], tv["y"], G.player.x, G.player.y) > 30.0:
				fail("the traveller did not follow")
			EBullets.add(tv["x"], tv["y"] - 5.0, 0.0, 0.0, "red", 3.0)
			Wanderers.update(TB.DT)
			if tv["hp"] != Wanderers.TRAVELLER_HP - 1:
				fail("a foe's shot did not hurt the traveller")
			for k in 2:
				tv["iv"] = 0.0
				var e := Combat.spawn_enemy("slime", tv["x"], tv["y"], false, true)
				e.spawn_t = 0.0
				e.x = tv["x"]   # (spawning moves a foe to open floor)
				e.y = tv["y"]
				Wanderers.update(TB.DT)
				G.enemies.clear()
			if tv["st"] != "flee" or G.run_stats.has("traveller"):
				fail("after three hits the traveller did not run home")
	# A traveller led to the guardian's door pays with a relic.
	_room()
	Wanderers._traveller(G.room)
	tv = _find("w_traveller")
	if not tv.is_empty():
		Wanderers.interact(tv)
		var r0 := G.player.relics.size()
		var g0 := G.player.gold
		var boss_room := World.make_room(G.floor_d, "boss", "", "s", { "no_secret": true })
		G.enter_room(boss_room)
		if G.player.relics.size() <= r0 or G.player.gold <= g0:
			fail("the traveller did not pay at the guardian's door")
		if G.run_stats.has("traveller"):
			fail("the traveller kept following past the guardian's door")
	G.enemies.clear()
	G.boss = null
	# --classic: nobody turns up, nothing is remembered.
	GameData.force_classic = true
	Meta.meta.erase("ghost")
	G.new_run()
	G.floor_index = 2
	_room()
	for i in 30:
		G.run_stats["kills"] = i
		Wanderers.on_room_clear(G.room)
	G.on_death("a test")
	if not _find("w_rival").is_empty() or not _find("w_traveller").is_empty() or Meta.meta.has("ghost"):
		fail("a wanderer or a ghost under --classic")
	GameData.force_classic = false
	print("wanderers test: PASSED" if fails == 0 else "wanderers test: %d FAILED" % fails)
	get_tree().quit()
