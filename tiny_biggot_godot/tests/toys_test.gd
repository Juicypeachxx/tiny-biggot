extends Node
## 31: THE TOYBOX. Run:
##   godot --headless --path . res://tests/toys_test.tscn -- --no-save
## Every Stage 31 weapon in turn, in a live fight with foes around (made tough, so the fight lasts):
## 4 s of attacks at the nearest foe with every tick of the game, then each kind must have done its
## thing (a bite, a lifted foe, a dance, a cut, a backstab, a trap, a pin and a shared blow, a
## crush), the toys cast by other weapons must have come out, and nothing may be left over after
## the room changes. Prints "toys test: PASSED" or a FAIL line per problem.

const IDS := ["landshark", "twisterfan", "discostaff", "steelyoyo", "portalgun", "sawlauncher", "voodoodoll", "skyanvil",
	"megalodon", "sharknado", "discoinferno", "twinyoyos", "gatecannon", "hungrysaws", "doomdoll", "grandpiano",
	"fishslapper", "rubberchicken", "confetticannon", "pinatastick", "stormjar", "smithsrevenge", "partyhorn",
	"cursedcrossbow", "portalbow", "buzzblade"]
var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL toys: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(31)
	Toys.stats.clear()
	for id in IDS:
		_one(id)
	for k in ["bite", "lifted", "slam", "dance", "string", "backstab", "trap", "pinned", "shared", "crush", "blocked",
			"cast_shark", "cast_twister", "cast_disco", "cast_pin", "cast_anvil", "cast_portal", "cast_saw"]:
		if Toys.stats.get(k, 0) <= 0:
			fail("nothing counted for %s (%s)" % [k, Toys.stats])
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	for l in [Toys.sharks, Toys.twisters, Toys.discos, Toys.yoyos, Toys.gates, Toys.saws, Toys.needles, Toys.anvils]:
		if not l.is_empty():
			fail("toys left over in a new room")
	print("[toys] ", Toys.stats)
	print("toys test: PASSED" if fails == 0 else "toys test: %d FAILED" % fails)
	get_tree().quit()

func _one(id: String) -> void:
	G.hero_index = 0
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = true
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.state = &"play"
	var p := G.player
	p.oath_picks = 0
	p.pending = 0
	Weapons.equip_weapon(p, Weapons.by_id(id))
	p.x = 14.0 * TB.TS
	p.y = 12.0 * TB.TS
	var pool: Array = GameData.floors()[G.floor_index]["pool"]
	for i in 240:
		while G.enemies.size() < 6:
			var s := World.free_spot(G.room, p, 40, World.M_FLYER)
			var e := Combat.spawn_enemy(TB.pick(pool), s.x, s.y, false, true)
			e.max_hp *= 30
			e.hp = e.max_hp
		p.hp = p.max_hp
		p.invuln = 1.0
		if i % 12 == 0:
			var t := Combat.auto_target(p, 400)
			var a := TB.ang_to(p, t) if t != null else 0.0
			p.aim_a = a
			p.shot_n += 1
			Combat.player_shoot(p, a, false)
		if i % 20 == 0 and not Toys.anvils.is_empty():
			var o: Dictionary = Toys.anvils[0]
			Combat.eshot(o["x"] + 30.0, o["y"] - 6.0, PI, 120.0)   # a foe's shot flying at the anvil
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}
