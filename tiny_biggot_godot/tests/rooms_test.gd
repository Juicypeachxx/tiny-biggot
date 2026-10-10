extends Node
## 16 the rooms revamp (scripts/render/room_dress.gd). Run:
##   godot --headless --path . res://tests/rooms_test.tscn -- --no-save
## Every kind of room can be entered; pots break when shot and when rolled into;
## coin heaps pay when walked through; a shot powder keg lights its fuse, then hurts the foes near
## it and sets off the keg beside it, and never the hero; a foe's shot lights a keg and wears down a
## crate (17.3).
## Prints "rooms test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL rooms: ", msg)

func _shot(x: float, y: float) -> void:
	var b := PBullet.new()
	b.x = x
	b.y = y
	G.pbullets.append(b)

func _ready() -> void:
	await get_tree().process_frame
	seed(160)
	G.hero_index = 0
	G.new_run()
	G.god = true
	# Every kind of room can be entered with its furniture (the drawing itself: screenshots).
	for kind in ["treasure", "shop", "shrine", "vault", "secret", "rest", "boss", "start", "combat"]:
		G.enter_room(World.make_room(G.floor_d, kind, "", "s", { "no_secret": true }))
		RoomDress.tick(0.1)
	# Pots: a shot breaks one, a roll breaks another.
	G.enter_room(World.make_room(G.floor_d, "treasure", "", "s", { "no_secret": true }))
	G.enemies.clear()
	var pots := G.room.objects.filter(func(o): return o["kind"] == "e_pot")
	if pots.size() < 2:
		fail("a treasure room has %d pots" % pots.size())
	else:
		G.pbullets.clear()
		_shot(pots[0]["x"], pots[0]["y"] - 4)
		RoomDress.tick_objects(G.room)
		if not pots[0].get("gone", false):
			fail("a shot did not break a pot")
		G.pbullets.clear()
		G.player.x = pots[1]["x"]
		G.player.y = pots[1]["y"]
		G.player.dodge_t = 0.2
		RoomDress.tick_objects(G.room)
		if not pots[1].get("gone", false):
			fail("a roll did not break a pot")
		G.player.dodge_t = 0.0
	# Coin heaps pay.
	var heaps := G.room.objects.filter(func(o): return o["kind"] == "e_coins")
	if heaps.is_empty():
		fail("the hoard has no coin heaps")
	else:
		var n0 := G.pickups.size()
		G.player.x = heaps[0]["x"]
		G.player.y = heaps[0]["y"]
		RoomDress.tick_objects(G.room)
		if not heaps[0].get("gone", false) or G.pickups.size() <= n0:
			fail("walking through a coin heap paid nothing")
	# Powder kegs: a shot one hurts foes and sets off its neighbour, never the hero.
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.enemies.clear()
	G.room.objects = G.room.objects.filter(func(o): return o["kind"] != "e_keg")
	G.god = false
	# 43.5: the foe stands where the room has space (spawn_enemy moves it off a blocked tile, and the
	# room's layout changes with the seed), so the kegs and the hero go beside wherever it is.
	var foe := Combat.spawn_enemy("skeleton", 165.0, 150.0, false, true)
	var k1 := { "kind": "e_keg", "x": foe.x - 15.0, "y": foe.y, "used": true }
	var k2 := { "kind": "e_keg", "x": foe.x + 25.0, "y": foe.y, "used": true }
	G.room.objects.append(k1)
	G.room.objects.append(k2)
	var hp0 := foe.hp
	G.player.x = foe.x - 5.0
	G.player.y = foe.y + 20.0
	var php: int = G.player.hp
	G.pbullets.clear()
	_shot(k1["x"], k1["y"] - 4.0)
	RoomDress.tick_objects(G.room)
	G.pbullets.clear()
	if not k1.has("fuse") or k1.get("gone", false):
		fail("a shot keg did not light its fuse first")
	for i in 60:
		RoomDress.tick_objects(G.room)
	if not k1.get("gone", false) or not k2.get("gone", false):
		fail("the keg did not blow, or did not set off its neighbour")
	if foe.hp >= hp0:
		fail("the blast did not hurt the foe beside it")
	if G.player.hp != php:
		fail("the blast hurt the hero")
	# 17.3: a foe's shot lights a keg and chips a crate.
	var k3 := { "kind": "e_keg", "x": 300.0, "y": 200.0, "used": true }
	G.room.objects.append(k3)
	EBullets.clear_all()
	Combat.eshot(300.0, 195.0, 0.0, 1.0, "red", 2.0)
	RoomDress.tick_objects(G.room)
	if not k3.has("fuse"):
		fail("a foe's shot did not light the keg")
	var cc := 5
	var rr := 5
	G.room.set_tile(cc, rr, World.T_CRATE)
	G.room.crate_hp[Vector2i(cc, rr)] = 12.0
	EBullets.clear_all()
	Combat.eshot(cc * TB.TS + 8.0, rr * TB.TS + 8.0, 0.0, 1.0, "red", 2.0)
	EBullets.update(TB.DT)
	if G.room.crate_hp.get(Vector2i(cc, rr), 12.0) >= 12.0:
		fail("a foe's shot did not wear down a crate")
	G.pbullets.clear()
	print("rooms test: PASSED" if fails == 0 else "rooms test: %d FAILED" % fails)
	get_tree().quit()
