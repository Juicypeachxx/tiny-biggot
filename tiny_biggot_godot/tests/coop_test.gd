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
## C3 the rules: foes +60% health and guardians +75% for each extra player, waves +25% foes; a
## guardian's experience for every standing hero; P2 to P4's level-ups one at a time, each in their
## own turn (G.player is them, the menus listen to their pad), P1 again once play goes on; a chest
## opened by P3 is P3's choice; then (his pick, 12 Oct) P4, P1 and P2 pick from what is left, in
## turn, each with their own device, never offered a relic they own (the chest has 3 more for four).
## C4 joining and menus: on the CO-OP screen each device joins with USE (bot devices stand in for a
## keyboard and controllers), chooses with LEFT and RIGHT, MENU unreadies and leaves, a locked hero
## cannot be readied, the run starts when two or more are all ready (each with their device and
## hero); P2's MENU opens the pause as theirs (G.player and the keys theirs, P1's button does not
## close it, their gear page, "P2'S GEAR"), then P1 again; the title ends the party.
## Prints "coop test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL coop: ", msg)

func _ready() -> void:
	_pads()
	_core()
	_rules()
	_join()
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
	hs[1].x = 380.0
	hs[1].y = 60.0
	hs[3].x = 60.0
	hs[3].y = 220.0
	var e := Combat.spawn_enemy("slime", 70.0, 64.0, false, true)
	e.x = 70.0   # (the room's layout can move a spawn: here it stands by P3, whatever the room)
	e.y = 64.0
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

# ---------- C3 ----------
func _rules() -> void:
	# Health and waves: one player against four.
	Coop.want = []
	Keys.clear_pads()
	Coop.pads = [-1]
	Coop.bots = [false]
	G.new_run()
	var e1 := Combat.spawn_enemy("slime", 100, 100, false, true)
	var hp1 := e1.max_hp
	var w1 := Coop.wave_size(8)
	G.enemies.clear()
	_start4()
	var e4 := Combat.spawn_enemy("slime", 100, 100, false, true)
	if absf(e4.max_hp / hp1 - (1.0 + Coop.HP_PER * 3)) > 0.001:
		fail("four players: a foe's health x%.3f (want x%.2f)" % [e4.max_hp / hp1, 1.0 + Coop.HP_PER * 3])
	if w1 != 8 or Coop.wave_size(8) != 14:
		fail("a wave of 8: %d alone, %d for four (want 8, 14)" % [w1, Coop.wave_size(8)])
	G.enemies.clear()
	# A guardian's experience for everyone.
	var hs := Coop.heroes()
	for h in hs:
		h.pending = 0
		h.oath_picks = 0
	var xp := []
	for h in hs:
		xp.append(h.xp + h.level * 1000)
	var b := Combat.spawn_boss(GameData.BOSSES.keys()[0], true)
	Coop.enter(2)
	Combat.kill_enemy(b)
	Coop.leave()
	for i in hs.size():
		if hs[i].xp + hs[i].level * 1000 <= xp[i]:
			fail("a guardian killed by P3: P%d got no experience" % (i + 1))
	G.enemies.clear()
	G.boss = null
	# Level-ups in turn.
	G.state = &"play"
	G.locked = false
	for h in hs:
		h.pending = 0
	hs[2].pending = 1
	G.hitstop = 0.0   # (the guardian's death pauses the game a moment)
	G.win_timer = null
	G.update_play(TB.DT)
	if G.state != &"traits" or G.player != hs[2] or Coop.turn != 2 or Keys.who != Coop.pads[2]:
		fail("P3's level-up: the game %s, G.player P%d, turn %d, input pad %d (want traits, P3, 2, %d)" % [G.state, Coop.index_of(G.player) + 1, Coop.turn, Keys.who, Coop.pads[2]])
	if G.state == &"traits" and not G.tchoice.is_empty():
		var lv: int = hs[2].traits.size()
		G.take_trait(G.tchoice["opts"][0])
		G.tchoice = {}
		G.state = &"play"
		if hs[2].traits.size() <= lv and hs[2].pending > 0:
			fail("P3's pick did not go to P3")
	G.update_play(TB.DT)
	if G.player != hs[0] or Coop.turn != -1:
		fail("after P3's pick: G.player P%d, turn %d (want P1, -1)" % [Coop.index_of(G.player) + 1, Coop.turn])
	# A chest opened by P3 is P3's choice.
	G.enter_room(World.make_room(G.floor_d, "treasure", "", "s", { "no_secret": true }))
	G.enemies.clear()
	G.locked = false
	G.state = &"play"
	G.room.objects.clear()
	G.room.objects.append({ "kind": "chest", "x": 120.0, "y": 120.0 })
	hs[2].x = 124.0
	hs[2].y = 122.0
	hs[0].x = 300.0
	hs[0].y = 200.0
	Keys.pads[Coop.pads[2]]["bot"][&"use"] = true
	Keys.tick()
	G.hitstop = 0.0
	G.update_play(TB.DT)
	Keys.pads[Coop.pads[2]]["bot"][&"use"] = false
	if G.state != &"choice" or G.player != hs[2]:
		fail("P3 at a chest pressing USE: the game %s, G.player P%d (want choice, P3)" % [G.state, Coop.index_of(G.player) + 1])
	else:
		_draft(hs)
	G.state = &"play"
	G.choice = {}
	Coop.draft = []
	Coop.play_tick()
	print("[coop] C3: health x%.1f and waves x%.2f for four; a guardian's experience for all; level-ups and chests in each hero's own turn" % [1.0 + Coop.HP_PER * 3, 1.0 + Coop.WAVE_PER * 3])

# ---------- C4 ----------
## One tick with pad k's action held, then one with it let go.
func _press(k: int, a: StringName) -> void:
	Keys.pads[k]["bot"][a] = true
	Keys.tick()
	G.update(TB.DT)
	if k < Keys.pads.size():   # (the run's start makes the party's pads anew)
		Keys.pads[k]["bot"][a] = false
	Keys.tick()
	G.update(TB.DT)

func _join() -> void:
	Coop.solo()
	G.fade = {}
	G.state = &"title"
	if not G.title_items().has("CO-OP"):
		fail("no CO-OP on the title")
	Coop.open_lobby()
	if G.state != &"coop" or Keys.pads.is_empty() or Keys.pads[0]["kind"] != "kbm":
		fail("the CO-OP screen: state %s, pads %s (want the keyboard first)" % [G.state, Keys.pads.size()])
		return
	var d := [Keys.add_pad("bot"), Keys.add_pad("bot"), Keys.add_pad("bot")]
	_press(d[0], &"use")
	_press(d[1], &"use")
	if Coop.lobby.size() != 2 or Coop.lobby[0]["pad"] != d[0] or Coop.lobby[1]["pad"] != d[1]:
		fail("two devices pressed USE: %d joined" % Coop.lobby.size())
		return
	if Coop.lobby[0]["hero"] != G.hero_index or Coop.lobby[1]["hero"] == Coop.lobby[0]["hero"]:
		fail("P1 joins with the last hero (%d, want %d), P2 with another (%d)" % [Coop.lobby[0]["hero"], G.hero_index, Coop.lobby[1]["hero"]])
	_press(d[2], &"use")
	_press(d[2], &"pause")
	if Coop.lobby.size() != 2:
		fail("P3 pressed MENU to leave: %d players (want 2)" % Coop.lobby.size())
	_press(d[2], &"use")
	var order := GameData.hero_order()
	var h1: int = Coop.lobby[1]["hero"]
	_press(d[1], &"move_right")
	if Coop.lobby[1]["hero"] != order[(order.find(h1) + 1) % order.size()]:
		fail("P2's RIGHT: hero %d (want the next after %d)" % [Coop.lobby[1]["hero"], h1])
	var locked := -1
	for i in order:
		if not G.hero_unlocked(GameData.heroes()[i]):
			locked = i
	if locked >= 0:
		var keep: int = Coop.lobby[2]["hero"]
		Coop.lobby[2]["hero"] = locked
		_press(d[2], &"use")
		if Coop.lobby[2]["ready"]:
			fail("P3 was readied with a locked hero")
		Coop.lobby[2]["hero"] = keep
	_press(d[0], &"use")
	_press(d[0], &"pause")
	if Coop.lobby[0]["ready"]:
		fail("P1's MENU did not unready them")
	for k in d:
		_press(k, &"use")
	var want: Array = Coop.lobby.map(func(e): return e["hero"])
	for k in 200:   # the fade, then the run
		Keys.tick()
		G.update(TB.DT)
		if G.state == &"play" and G.fade.is_empty():
			break
	if G.state != &"play" or Coop.count() != 3:
		fail("three ready players: state %s, %d heroes (want play, 3)" % [G.state, Coop.count()])
		return
	var hs := Coop.heroes()
	for i in 3:
		if hs[i].hero["id"] != GameData.heroes()[want[i]]["id"]:
			fail("P%d plays %s (want %s)" % [i + 1, hs[i].hero["id"], GameData.heroes()[want[i]]["id"]])
	if Keys.pads.size() != 3 or Coop.pads != [0, 1, 2]:
		fail("the party's pads %s of %d (want [0, 1, 2] of 3)" % [Coop.pads, Keys.pads.size()])
	_menus()
	# The title ends the party.
	G.state = &"title"
	Keys.tick()
	G.update(TB.DT)
	if Coop.on() or not Keys.pads.is_empty() or Coop.want.size() > 1:
		fail("back on the title the party is still on (%d heroes, %d pads)" % [Coop.count(), Keys.pads.size()])
	# With nobody joined, MENU on the CO-OP screen goes back to the title.
	Coop.open_lobby()
	var b := Keys.add_pad("bot")
	_press(b, &"pause")
	if G.state != &"title":
		fail("MENU with nobody joined: state %s (want the title)" % G.state)
	Coop.solo()
	print("[coop] C4: the CO-OP screen (join, choose, ready, leave, start with 3); P2's own pause and gear; the party ends on the title")

## P2's own pause and gear, then P1 again.
func _menus() -> void:
	G.enemies.clear()
	G.hitstop = 0.0
	for h in Coop.heroes():
		h.pending = 0
	var p1 := Coop.lead()
	var p2: Player = Coop.extras[0]
	var k2: int = Coop.pads[1]
	Coop.bots = [false, false, false]   # (nobody else moves)
	_press(k2, &"pause")
	if G.state != &"pause" or Coop.turn != 1 or G.player != p2:
		fail("P2's MENU: state %s, turn %d, P2 the player %s" % [G.state, Coop.turn, G.player == p2])
		return
	if Coop.turn_label() != "P2'S MENU":
		fail("P2's pause is labelled %s" % Coop.turn_label())
	_press(Coop.pads[0], &"pause")
	if G.state != &"pause":
		fail("P1's button closed P2's pause")
	_press(k2, &"move_down")
	_press(k2, &"use")
	if G.state != &"inventory" or G.player != p2 or Coop.turn_label() != "P2'S GEAR":
		fail("P2's GEAR: state %s, P2 the player %s, label %s" % [G.state, G.player == p2, Coop.turn_label()])
	_press(k2, &"pause")
	_press(k2, &"pause")
	if G.state != &"play":
		fail("P2 left their pause: state %s" % G.state)
	Keys.tick()
	G.update(TB.DT)
	if G.player != p1 or Coop.turn != -1 or Coop.turn_label() != "":
		fail("after P2's pause P1 is not the player again (turn %d)" % Coop.turn)

# ---------- C6: a chest for everyone, in turn ----------
## USE on hero k's device (P1's is every device: the game's own input).
func _take(k: int) -> void:
	Keys.tick()   # (every button let go first: the press below is a new one)
	if Coop.pads[k] >= 0:
		_press(Coop.pads[k], &"use")
		return
	Input.action_press(&"use")
	Keys.tick()
	G.update(TB.DT)
	Input.action_release(&"use")
	Keys.tick()
	G.update(TB.DT)

func _draft(hs: Array) -> void:
	G.fade = {}   # (the door test's fade may still be running: the game waits for it)
	var base := 4 if Meta.unlocked("perk_choice") else 3
	var n0: int = G.choice["relics"].size()
	if n0 != base + 3:
		fail("a chest for four offers %d relics (want %d)" % [n0, base + 3])
	if Coop.draft != [3, 0, 1]:
		fail("after P3 the chest goes to %s (want [3, 0, 1]: P4, P1, P2)" % [Coop.draft])
	var before: Array = hs.map(func(h): return h.relics.size())
	var got := {}
	var order := [2, 3, 0, 1]
	for j in order.size():
		var k: int = order[j]
		if G.state != &"choice" or G.player != hs[k]:
			fail("P%d's turn at the chest: state %s, the player P%d" % [k + 1, G.state, Coop.index_of(G.player) + 1])
			return
		if G.choice["relics"].size() != n0 - j:
			fail("P%d chooses from %d relics (want %d)" % [k + 1, G.choice["relics"].size(), n0 - j])
		for r in G.choice["relics"]:
			if hs[k].relics.any(func(x): return x["id"] == r["id"]):
				fail("P%d is offered %s, which they own" % [k + 1, r["id"]])
		var pick: Dictionary = G.choice["relics"][G.choice["idx"]]
		_take(k)
		got[pick["id"]] = true
		if hs[k].relics.size() != before[k] + 1 or hs[k].relics.back()["id"] != pick["id"]:
			fail("P%d took %s: %d relics (want %d)" % [k + 1, pick["id"], hs[k].relics.size(), before[k] + 1])
			return
	if G.state != &"play" or got.size() != 4 or not Coop.draft.is_empty():
		fail("after four picks: state %s, %d different relics, %d still to pick (want play, 4, 0)" % [G.state, got.size(), Coop.draft.size()])
	# Test bots (--coop=N soaks) take theirs at once, so a chest never waits for them.
	var keep_bots: Array = Coop.bots.duplicate()
	Coop.bots = [false, true, true, true]
	Coop.leave()
	before = hs.map(func(h): return h.relics.size())
	G.open_choice("chest", { "x": 200.0, "y": 150.0 })
	_take(0)
	if G.state != &"play" or hs.any(func(h): return h.relics.size() != before[hs.find(h)] + 1):
		fail("P1 took, the three bots after: state %s, relics %s (were %s)" % [G.state, hs.map(func(h): return h.relics.size()), before])
	Coop.bots = keep_bots
	# A player whose controller is unplugged: anyone can finish their menu.
	var keep_pad: int = Coop.pads[1]
	Coop.pads[1] = Keys.add_pad("joy", 7)   # (no controller 7 here)
	Coop.turn = 1
	if Coop.menu_pad() != -1:
		fail("P2's controller is gone but their menu listens only to it (%d)" % Coop.menu_pad())
	Coop.pads[1] = keep_pad
	Keys.pads.pop_back()
	Coop.turn = -1
	print("[coop] C6: a chest for four offers %d relics; P3, P4, P1, P2 each took one in turn, %d different; bots take theirs; an unplugged controller's turn is anyone's" % [n0, got.size()])
