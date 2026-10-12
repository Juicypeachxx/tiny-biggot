extends Node
## Windows co-op (COOP_PLAN.md; the Windows line only). Run:
##   godot --headless --path . res://tests/coop_test.tscn -- --no-save
## C1 each player's own devices: a pad reads only its own device (here bot pads, a keyboard and a
## controller by their events), every device at once when no pad is chosen, and the edges (pressed
## this tick, held, repeated) per pad.
## C2 the co-op core: four heroes, each made like a hero of a run of their own, placed beside P1 in
## every room; foes work against their nearest standing hero; a foe shot hurts the hero it hits; a
## shot belongs to the hero who fired it; a pickup goes to the nearest hero; a hero with no hearts is
## DOWN (the run goes on), helped up by a friend in 3 s or by a cleared room, and the run ends only
## when all are down; the party leaves through a door only together. One player: no co-op at all.
## Prints "coop test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL coop: ", msg)

func _ready() -> void:
	_pads()
	_core()
	Keys.clear_pads()
	Coop.want = []
	Coop.pads = [-1]
	Coop.bots = [false]
	print("coop test: PASSED" if fails == 0 else "coop test: %d FAILED" % fails)
	get_tree().quit()

# ---------- C1 ----------
func _pads() -> void:
	Keys.clear_pads()
	var a := Keys.add_pad("bot")
	var b := Keys.add_pad("bot")
	var k := Keys.add_pad("kbm")
	var j := Keys.add_pad("joy", 3)
	Keys.pads[a]["bot"][&"move_right"] = true
	Keys.pads[a]["bot"][&"roll"] = true
	Keys.pads[b]["bot"][&"move_up"] = true
	Keys.tick()
	Keys.use_pad(a)
	if Keys.move() != Vector2(1, 0) or not Keys.roll():
		fail("pad A: move %s roll %s (want right, a roll)" % [Keys.move(), Keys.roll()])
	Keys.use_pad(b)
	if Keys.move() != Vector2(0, -1) or Keys.roll():
		fail("pad B: move %s roll %s (want up, no roll)" % [Keys.move(), Keys.roll()])
	Keys.use_pad(-1)
	if Keys.move() != Vector2.ZERO or Keys.roll():
		fail("every device: the bot pads leaked into the one-player input")
	# Held: a roll is pressed once, then only held.
	Keys.tick()
	Keys.use_pad(a)
	if Keys.roll() or not Keys.pressed(&"roll"):
		fail("pad A: a held roll rolled again (%s) or was let go (%s)" % [Keys.roll(), Keys.pressed(&"roll")])
	Keys.use_pad(-1)
	# A device's events belong to its own pad.
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	var btn := InputEventJoypadButton.new()
	btn.button_index = JOY_BUTTON_A
	btn.device = 3
	var other := InputEventJoypadButton.new()
	other.button_index = JOY_BUTTON_A
	other.device = 5
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	if Keys.pad_of(key) != k or Keys.pad_of(click) != k or Keys.pad_of(btn) != j or Keys.pad_of(other) != -1:
		fail("events to pads: key %d, mouse %d, pad 3 %d, pad 5 %d (want %d, %d, %d, -1)" % [Keys.pad_of(key), Keys.pad_of(click), Keys.pad_of(btn), Keys.pad_of(other), k, k, j])
	# A tap shorter than a tick still counts, for its own pad only.
	btn.pressed = true
	Keys._input(btn)
	Keys.tick()
	Keys.use_pad(j)
	var on_j := Keys.use()
	Keys.use_pad(k)
	var on_k := Keys.use()
	Keys.use_pad(-1)
	if not on_j or on_k:
		fail("a quick A on controller 3: its pad %s, the keyboard's %s (want true, false)" % [on_j, on_k])
	# The right mouse button rolls (Windows).
	var rolls := InputMap.action_get_events(&"roll").filter(func(e): return e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT)
	if rolls.is_empty():
		fail("the right mouse button does not roll")
	print("[coop] C1: %d pads, each reads only its own device; quick taps latch to their own pad" % Keys.pads.size())

# ---------- C2 ----------
## A few ticks of the game (a door's fade ends, the next room comes in).
func _run(ticks: int) -> void:
	for k in ticks:
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play" and G.state != &"fade":
			break

func _start4() -> void:
	Keys.clear_pads()
	var order := GameData.hero_order()
	Coop.want = [order[0], order[1], order[2], order[3]]
	Coop.pads = [-1]
	Coop.bots = [false]
	for i in 3:
		Coop.pads.append(Keys.add_pad("bot"))
		Coop.bots.append(false)
	G.hero_index = order[0]
	G.new_run()
	G.god = false
	G.state = &"play"

func _core() -> void:
	var runs0: int = Meta.meta.get("runs", 0)
	_start4()
	var hs := Coop.heroes()
	if hs.size() != 4 or not Coop.on():
		fail("a four-player run has %d heroes" % hs.size())
		return
	if int(Meta.meta.get("runs", 0)) != runs0 + 1:
		fail("a four-player run counted %d runs (want 1)" % (int(Meta.meta.get("runs", 0)) - runs0))
	var sprites := {}
	for h in hs:
		sprites[h.hero["id"]] = true
		if h.weapon == null or h.hp <= 0:
			fail("hero %s has no weapon or no hearts" % h.hero["id"])
	if sprites.size() != 4:
		fail("four players, %d different heroes (want 4)" % sprites.size())
	if G.player != hs[0]:
		fail("G.player is not P1 after the run starts")
	# Beside P1 in the room, inside it.
	for i in range(1, 4):
		var h: Player = hs[i]
		if TB.dist_xy(h.x, h.y, hs[0].x, hs[0].y) > 24 or World.hits_solid(G.room, h.x, h.y, h.r, World.M_WALKER):
			fail("P%d starts at (%.0f, %.0f), P1 at (%.0f, %.0f)" % [i + 1, h.x, h.y, hs[0].x, hs[0].y])
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.enemies.clear()
	G.room.waves_left = 0
	G.locked = true
	G.state = &"play"
	# Foes: their nearest standing hero.
	var p3: Player = hs[2]
	p3.x = 60.0
	p3.y = 60.0
	hs[0].x = 380.0
	hs[0].y = 220.0
	var e := Combat.spawn_enemy("slime", 70.0, 64.0, false, true)
	var t := Coop.foe_target(e, hs[0])
	Coop.foes_done(hs[0])
	if t != p3 or G.player != hs[0]:
		fail("a foe beside P3 works against P%d (want 3), G.player afterwards P%d" % [Coop.index_of(t) + 1, Coop.index_of(G.player) + 1])
	G.enemies.clear()
	# Foe shots: the hero they hit.
	var p2: Player = hs[1]
	p2.x = 200.0
	p2.y = 150.0
	p2.invuln = 0.0
	p2.dodge_t = 0.0
	var hp2 := p2.hp
	var hp1: int = hs[0].hp
	EBullets.clear_all()
	EBullets.add(p2.x, p2.y - 2, 0.0, 0.0, "ebullet", 3.0)
	EBullets.update(TB.DT)
	if p2.hp >= hp2 or hs[0].hp != hp1:
		fail("a foe shot on P2: P2 %d -> %d, P1 %d -> %d" % [hp2, p2.hp, hp1, hs[0].hp])
	EBullets.clear_all()
	# Shots: whose they are.
	Coop.enter(3)
	var b := Combat.spawn_pbullet(G.player, 0.0)
	Coop.leave()
	if b == null or b.owner_i != 3:
		fail("a shot fired by P4 belongs to P%d" % ((b.owner_i + 1) if b != null else 0))
	G.pbullets.clear()
	# Pickups: to the nearest hero.
	var p4: Player = hs[3]
	p4.x = 300.0
	p4.y = 80.0
	var g4 := p4.gold
	var g1: int = hs[0].gold
	G.pickups.clear()
	Combat.drop_pickup("gem", p4.x, p4.y)
	for i in 120:
		Coop.update_pickups(TB.DT)
	if p4.gold <= g4 or hs[0].gold != g1:
		fail("a gem by P4: P4's gold %d -> %d, P1's %d -> %d" % [g4, p4.gold, g1, hs[0].gold])
	# Down, not out.
	p2.invuln = 0.0
	p2.hp = 1
	p2.revive = 0
	Coop.hurt(1, 5, "the test")
	if not Coop.is_down(p2) or G.state != &"play":
		fail("P2 with no hearts: down %s, the game %s (want down, still playing)" % [Coop.is_down(p2), G.state])
	hs[0].x = p2.x + 6
	hs[0].y = p2.y
	for i in int(Coop.REVIVE_TIME / TB.DT) + 5:
		Coop._revive_tick(TB.DT)
	if Coop.is_down(p2) or p2.hp <= 0:
		fail("P2 not helped up after %.0f s beside P1" % Coop.REVIVE_TIME)
	p3.hp = 1
	p3.invuln = 0.0
	p3.revive = 0
	Coop.hurt(2, 5, "the test")
	G.room_cleared()
	if Coop.is_down(p3):
		fail("a cleared room did not bring P3 back up")
	# The door: only together (the floor's own start room, with its doors on the map).
	G.start_floor()
	for h in Coop.heroes():
		h.pending = 0   # (no oath or level-up screen in the way)
		h.oath_picks = 0
	G.enemies.clear()
	G.locked = false
	G.state = &"play"
	var r0 := G.room
	var door := ""
	for d in ["n", "e", "w", "s"]:
		if r0.exits.has(d) and not r0.sealed.has(d):
			door = d
	var at: Vector2 = { "n": Vector2(14.0 * TB.TS, TB.TS * 0.8), "s": Vector2(14.0 * TB.TS, TB.SH - TB.TS * 0.5),
		"w": Vector2(TB.TS * 0.4, 9.0 * TB.TS), "e": Vector2(TB.SW - TB.TS * 0.4, 9.0 * TB.TS) }.get(door, Vector2.ZERO)
	if door == "":
		fail("the test room has no open door")
	else:
		for h in hs:
			h.x = 14.0 * TB.TS
			h.y = 9.0 * TB.TS
		hs[0].x = at.x
		hs[0].y = at.y
		_run(60)
		if G.room != r0 or Coop.wait_msg == "":
			fail("P1 alone at the %s door: the party left, or nobody was told to wait" % door)
		for h in hs:
			h.x = at.x
			h.y = at.y
		_run(90)
		if G.room == r0:
			fail("all four at the %s door, the party did not leave" % door)
	# Everyone down: the end.
	G.state = &"play"
	for i in 4:
		var h: Player = Coop.heroes()[i]
		h.hp = 1
		h.invuln = 0.0
		h.revive = 0
		h.dodge_t = 0.0
		if i == 0:
			Combat.hurt_player(5, "the test")
		else:
			Coop.hurt(i, 5, "the test")
	if G.state != &"dead":
		fail("all four down: the game is %s (want dead)" % G.state)
	# One player: none of it.
	Coop.want = []
	G.new_run()
	if Coop.on() or Coop.heroes().size() != 1:
		fail("a one-player run after co-op still has %d heroes" % Coop.heroes().size())
	print("[coop] C2: four heroes; foes, foe shots, shots, pickups each with their own hero; down and up; the door together; all down ends it")
