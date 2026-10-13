extends Node
## 10.4 Flails (scripts/combat/flail.gd). Run:
##   godot --headless --path . res://tests/flail_test.tscn -- --no-save
## The ball circles and hurts what it touches; a lash reaches a foe the orbit does not; +1 projectile
## adds a ball (up to four); every flail weapon exists with its icon.
## Prints "flail test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL flail: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(104)
	G.hero_index = 0
	G.new_run()
	G.god = true
	Meta.opts["autofire"] = false
	var p := G.player
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.enemies.clear()
	Weapons.equip_weapon(p, Weapons.by_id("morningstar"))
	var near := _dummy(Vector2(p.x + Flail.ORBIT_R, p.y - 4))
	var far := _dummy(Vector2(p.x + 64.0, p.y - 4))
	_play(90)
	if near.hp >= near.max_hp:
		fail("the circling ball never hit a foe on its path")
	if far.hp < far.max_hp:
		fail("the circling ball reached a foe beyond its orbit")
	Flail.fire(p, 0.0, false)
	_play(20)
	if far.hp >= far.max_hp:
		fail("a lash toward a foe did not reach it")
	for k in ["chainflail", "skullflail"]:
		Weapons.equip_weapon(p, Weapons.by_id(k))
		_play(2)
		if Flail.balls.size() != clampi(Weapons.wcount(p), 1, Flail.MAX_BALLS):
			fail("%s: %d balls for %d projectiles" % [k, Flail.balls.size(), Weapons.wcount(p)])
	for w in Weapons.all():
		if w["kind"] == "flail" and not Img.has(w["sprite"]):
			fail("%s has no icon" % w["id"])
	print("flail test: PASSED" if fails == 0 else "flail test: %d FAILED" % fails)
	get_tree().quit()

func _dummy(at: Vector2) -> Enemy:
	var e := Combat.spawn_enemy("skeleton", at.x, at.y + 4, false, true)
	e.speed = 0.0
	e.max_hp = 1e6
	e.hp = 1e6
	e.x = at.x
	e.y = at.y + 4
	return e

func _play(n: int) -> void:
	var p := G.player
	var x := p.x
	var y := p.y
	for i in n:
		p.hp = p.max_hp
		p.x = x
		p.y = y
		Keys.tick()
		G.update(TB.DT)
		for e in G.enemies:
			e.speed = 0.0
		if G.state != &"play":
			G.state = &"play"
