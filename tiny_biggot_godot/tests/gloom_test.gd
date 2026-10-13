extends Node
## 11.2 GLOOM and prism fans. Run: godot --headless --path . res://tests/gloom_test.tscn -- --no-save
## GLOOM stacks to 10, each +8% damage taken, and wears off after 4 s; a beam weapon with three
## projectiles fans three rays (a foe off to the side of the aim is hit).
## Prints "gloom test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL gloom: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(112)
	G.hero_index = 0
	G.new_run()
	G.god = true
	var p := G.player
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.enemies.clear()
	var e := Combat.spawn_enemy("skeleton", p.x + 60, p.y, false, true)
	for i in 14:
		Statuses.apply(e, "gloom", 1, 1.0)
	if e.gloom != 10 or absf(Statuses.dmg_mult(e) - 1.8) > 1e-6:
		fail("14 gloom: %d stacks, x%.2f damage (want 10, x1.8)" % [e.gloom, Statuses.dmg_mult(e)])
	for i in 300:
		Statuses.tick(e, TB.DT)
	if e.gloom != 0:
		fail("gloom did not wear off (%d)" % e.gloom)
	G.enemies.clear()
	Weapons.equip_weapon(p, Weapons.by_id("prismfan"))
	var side := Combat.spawn_enemy("skeleton", p.x + 80 * cos(0.2), p.y - 2 + 80 * sin(0.2), false, true)
	side.speed = 0.0
	side.x = p.x + 80 * cos(0.2)   # held there: a spawn inside a pillar is moved elsewhere
	side.y = p.y + 2 + 80 * sin(0.2)
	side.max_hp = 1e6
	side.hp = 1e6
	for i in 3:
		Combat.player_shoot(p, 0.0)
	if side.hp >= side.max_hp:
		fail("a 3-ray fan did not reach a foe 0.2 off the aim")
	print("gloom test: PASSED" if fails == 0 else "gloom test: %d FAILED" % fails)
	get_tree().quit()
