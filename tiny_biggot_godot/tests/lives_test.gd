extends Node
## 21.5 MONSTERS WITH LIVES OF THEIR OWN (scripts/combat/lives.gd). Run:
##   godot --headless --path . res://tests/lives_test.tscn -- --no-save
## Sleepers (one walker in three in a first wave) stay put until you come near, and wake when hurt
## (a double-damage sneak attack), after a while, or when they are the last; a foe below half health
## calls for help (sleepers wake, its kind runs faster for a while); mothlings circle a lamp until
## you come near, and a fallen lamp sends them at you; a fire-dog chases a sootling until it notices
## you; slimes swallow coins, grow, and give them back when they burst. No dice of the run's own;
## nothing under --classic. Prints "lives test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL lives: ", msg)

func _foe(type: String, x: float, y: float) -> Enemy:
	var e := Combat.spawn_enemy(type, x, y, false, true)
	e.spawn_t = 0.0
	e.x = x
	e.y = y
	return e

func _foe_uid(type: String, x: float, y: float, rem: int, m: int) -> Enemy:
	var e := _foe(type, x, y)
	while e.uid % m != rem:
		G.enemies.erase(e)
		e = _foe(type, x, y)
	return e

func _run(n: int) -> void:
	for i in n:
		Combat.update_enemies(TB.DT)

func _arena() -> Player:
	G.hero_index = 2
	G.new_run()
	G.god = true
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.enemies.clear()
	G.room.waves_left = 0
	G.locked = true
	G.state = &"play"
	G.player.x = 60.0
	G.player.y = 250.0
	return G.player

func _ready() -> void:
	await get_tree().process_frame
	seed(2105)
	var p := _arena()
	# Sleepers: one walker in three, by number; they stay put while you are away.
	var wave := []
	for i in 6:
		wave.append(_foe("skeleton", 260.0 + i * 20.0, 120.0))
	Lives.on_wave(wave, true)
	var sleepers := wave.filter(func(e): return e.asleep)
	if sleepers.size() != wave.filter(func(e): return e.uid % 3 == 1).size() or sleepers.is_empty():
		fail("%d of 6 asleep, not the ones by number" % sleepers.size())
	var s: Enemy = sleepers[0] if not sleepers.is_empty() else wave[0]
	var at := Vector2(s.x, s.y)
	G.enemies.clear()
	G.enemies.append(s)
	var awake := _foe_uid("skeleton", 400.0, 60.0, 0, 3)
	_run(60)
	if not s.asleep or Vector2(s.x, s.y).distance_to(at) > 0.5:
		fail("a sleeper woke or walked while you were away")
	# A sneak attack: double damage, and it wakes.
	var twin := _foe("skeleton", 300.0, 200.0)
	seed(4)
	var h0 := s.hp
	Combat.damage_enemy(s, 3.0, { "no_crit": true })
	var d_sleep := h0 - s.hp
	seed(4)
	var h1 := twin.hp
	Combat.damage_enemy(twin, 3.0, { "no_crit": true })
	var d_awake := h1 - twin.hp
	if s.asleep or absf(d_sleep - 2.0 * d_awake) > 0.01:
		fail("a sleeper took %.2f, an awake foe %.2f (want double), asleep=%s" % [d_sleep, d_awake, s.asleep])
	# Waking: you come near; after a while; the last one left.
	var s2 := _foe("skeleton", 300.0, 120.0)
	s2.asleep = true
	p.x = 300.0 - 40.0
	p.y = 120.0
	_run(2)
	if s2.asleep:
		fail("a sleeper did not wake when you came near")
	p.x = 60.0
	p.y = 250.0
	var s3 := _foe("skeleton", 330.0, 100.0)
	s3.asleep = true
	_run(int((Lives.SLEEP_MAX + 0.5) / TB.DT))
	if s3.asleep:
		fail("a sleeper slept for ever")
	G.enemies.clear()
	var s4 := _foe("skeleton", 330.0, 100.0)
	s4.asleep = true
	_run(2)
	if s4.asleep:
		fail("the last foe left stayed asleep")
	# A call for help: sleepers near wake, its kind runs faster for a while.
	G.enemies.clear()
	var caller := _foe_uid("skeleton", 300.0, 150.0, 0, 2)
	var mate := _foe("skeleton", 340.0, 150.0)
	var sleeper := _foe("slime", 260.0, 150.0)
	sleeper.asleep = true
	var sp0 := mate.speed
	Combat.damage_enemy(caller, caller.max_hp * 0.6, { "no_crit": true, "no_mult": true })
	if caller.hp <= 0 or caller.hp >= caller.max_hp * 0.5:
		fail("the test blow left %.1f of %.1f" % [caller.hp, caller.max_hp])
	if sleeper.asleep:
		fail("a call for help did not wake the sleeper")
	if absf(mate.speed - sp0 * Lives.RALLY) > 0.01:
		fail("its kind did not run faster to the call (%.1f -> %.1f)" % [sp0, mate.speed])
	_run(int((Lives.RALLY_TIME + 0.5) / TB.DT))
	if absf(mate.speed - sp0) > 0.01:
		fail("the rally did not wear off (%.1f, was %.1f)" % [mate.speed, sp0])
	# Mothlings and a lamp.
	G.enemies.clear()
	G.room.objects = G.room.objects.filter(func(o): return o["kind"] != "e_candle")   # only the test's lamp
	G.room.objects.append({ "kind": "e_candle", "x": 360.0, "y": 90.0 })
	var moth := _foe("mothling", 300.0, 180.0)
	_run(180)
	if TB.dist_xy(moth.x, moth.y, 360.0, 76.0) > 22.0:
		fail("the mothling did not circle the lamp (%.0f px away)" % TB.dist_xy(moth.x, moth.y, 360.0, 76.0))
	for o in G.room.objects:
		if o["kind"] == "e_candle":
			RoomDress.knock(o, 300.0)
	if not moth.provoked or moth.rally_t <= 0.0:
		fail("a fallen lamp did not send the mothling at you")
	var moth2 := _foe("mothling", 200.0, 120.0)
	p.x = 200.0
	p.y = 160.0
	_run(2)
	if not moth2.provoked:
		fail("a mothling did not notice you close by")
	p.x = 60.0
	p.y = 250.0
	# A fire-dog chases a sootling until it notices you.
	G.enemies.clear()
	var dog := _foe("firedog", 300.0, 120.0)
	var soot := _foe("sootling", 360.0, 120.0)
	var d0 := TB.dist(dog, soot)
	var dx0 := dog.x
	_run(20)
	if dog.provoked or dog.x <= dx0:
		fail("the fire-dog did not chase the sootling")
	if TB.dist(dog, soot) < d0 - 30.0:
		fail("the sootling did not run from the dog")
	_run(int(Lives.DOG_BORED / TB.DT) + 5)
	if not dog.provoked:
		fail("the fire-dog never noticed you")
	# A greedy slime swallows a coin, grows, and gives it back.
	G.enemies.clear()
	G.pickups.clear()
	var slime := _foe("slime", 300.0, 150.0)
	var coin := Pickup.new()
	coin.kind = "coin"
	coin.x = 330.0
	coin.y = 150.0
	G.pickups.append(coin)
	var hp0 := slime.max_hp
	_run(120)
	if slime.coins != 1 or G.pickups.has(coin):
		fail("the slime did not swallow the coin")
	if slime.scale <= 1.0 or slime.max_hp <= hp0:
		fail("the slime did not grow")
	Combat.kill_enemy(slime)
	if G.pickups.filter(func(k): return k.kind == "coin").is_empty() and G.player.gold == 0:
		fail("the burst slime gave nothing back")
	# His report, 9 Oct: a slime that swallows a pile of coins (here 40, right under it) stops
	# growing at its full size: at most 2.2 times its health, never more.
	G.enemies.clear()
	G.pickups.clear()
	var big := _foe("slime", 300.0, 150.0)
	var base := big.max_hp
	for i in 40:
		var c := Pickup.new()
		c.kind = "coin"
		c.x = 300.0 + (i % 5) * 3.0
		c.y = 150.0 + (i / 5) * 2.0
		G.pickups.append(c)
	_run(600)
	if big.coins < 20:
		fail("the slime swallowed only %d of 40 coins" % big.coins)
	if big.max_hp > base * 2.2 + 0.01:
		fail("a slime that swallowed %d coins has x%.1f its health (at most x2.2)" % [big.coins, big.max_hp / base])
	print("[lives] a slime that swallowed %d coins: x%.2f health, size x%.1f" % [big.coins, big.max_hp / base, big.scale])
	# None of it rolls the run's dice.
	G.enemies.clear()
	var a1 := _foe("skeleton", 300.0, 100.0)
	a1.asleep = true
	_foe("mothling", 200.0, 200.0)
	_foe("firedog", 380.0, 120.0)
	_foe("sootling", 400.0, 120.0)
	_foe("skeleton", 420.0, 60.0)
	seed(12)
	var r := randi()
	seed(12)
	for e: Enemy in G.enemies.duplicate():
		for k in 30:
			Lives.override(e, TB.DT, p)
	if randi() != r:
		fail("a foe's life rolled the run's dice")
	# --classic: nobody sleeps, nothing overrides a foe.
	GameData.force_classic = true
	var w2 := []
	for i in 6:
		w2.append(_foe("skeleton", 260.0 + i * 20.0, 120.0))
	Lives.on_wave(w2, true)
	var m3 := _foe("mothling", 300.0, 180.0)
	if w2.any(func(e): return e.asleep) or Lives.override(m3, TB.DT, p):
		fail("a sleeper or a moth's life under --classic")
	GameData.force_classic = false
	print("lives test: PASSED" if fails == 0 else "lives test: %d FAILED" % fails)
	get_tree().quit()
