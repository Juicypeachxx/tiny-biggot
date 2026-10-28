extends Node
## Small logic tests run headless: godot --headless --path . res://tests/unit_tests.tscn
## Reference values come from running the original Ruby code (see comments).

var _fails := 0

func _ready() -> void:
	_test_seed_rng()
	_test_ruby_math()
	_test_keyboard()
	_test_menu_taps()
	_test_synergy_loss()
	_test_background()
	_test_shots_off_the_edge()
	print("unit tests: %s" % ("PASSED" if _fails == 0 else "%d FAILED" % _fails))
	get_tree().quit(1 if _fails > 0 else 0)

func _eq(name: String, got: Variant, want: Variant) -> void:
	if str(got) != str(want):
		_fails += 1
		print("FAIL %s: got %s want %s" % [name, got, want])

func _test_seed_rng() -> void:
	# ruby: r = SeedRng.new(123456789); 5.times.map { r.next_f.round(9) }
	var r := SeedRng.new(123456789)
	var got := []
	for i in 5:
		got.append(snappedf(r.next_f(), 0.000000001))
	_eq("seed_rng next_f", got, [0.632127719, 0.521264364, 0.291056335, 0.88943642, 0.739823954])
	# ruby: r = SeedRng.new(987654321 ^ 0x5bd1e995); 8.times.map { r.int(0,7) }
	r = SeedRng.new(987654321 ^ 0x5bd1e995)
	got = []
	for i in 8:
		got.append(r.int_range(0, 7))
	_eq("seed_rng int", got, [5, 4, 0, 6, 7, 6, 7, 6])
	# ruby: SeedRng.new(0) behaves like seed 1
	r = SeedRng.new(0)
	_eq("seed_rng zero seed", snappedf(r.next_f(), 0.00000001), 0.00006295)

func _test_ruby_math() -> void:
	_eq("idiv -7/2", TB.idiv(-7, 2), -4)        # ruby: -7 / 2 == -4
	_eq("idiv 7/2", TB.idiv(7, 2), 3)
	_eq("rmod -1%5", TB.rmod(-1, 5), 4)         # ruby: -1 % 5 == 4
	_eq("rmod 7%-3", TB.rmod(7, -3), -2)        # ruby: 7 % -3 == -2
	_eq("fmodp -0.5%3.6", snappedf(TB.fmodp(-0.5, 3.6), 0.001), 3.1)
	_eq("xp_needed 1", GameData.xp_needed(1), 17)   # ruby: (10 + 7 * (1 ** 1.35)).round
	_eq("xp_needed 5", GameData.xp_needed(5), 71)   # ruby: (10 + 7 * (5 ** 1.35)).round

## iPad Magic Keyboard: extra keys and both physical/typed bindings; a key
## press hides the touch controls and releases what a finger held; a touch
## brings them back.
func _test_keyboard() -> void:
	var cases := [[KEY_E, &"bomb"], [KEY_B, &"bomb"], [KEY_TAB, &"pause"], [KEY_QUOTELEFT, &"pause"],
		[KEY_P, &"pause"], [KEY_ESCAPE, &"pause"], [KEY_SHIFT, &"roll"], [KEY_Q, &"heal"], [KEY_ENTER, &"use"]]
	for c in cases:
		for physical in [true, false]:
			var e := InputEventKey.new()
			e.pressed = true
			if physical:
				e.physical_keycode = c[0]
			else:
				e.keycode = c[0]
			_eq("key %s (%s) -> %s" % [OS.get_keycode_string(c[0]), "physical" if physical else "typed", c[1]],
				InputMap.event_is_action(e, c[1]), true)
	var tc := TouchControls.new()
	add_child(tc)
	tc.visible = true
	var state_was: StringName = G.state
	G.state = &"play"   # the stick moves the hero in play (47.3: on the title, that corner is the menu)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = (tc.stick_home + Vector2(tc.stick_r, 0)) * TB.D   # a finger comes in the screen's pixels (59.1)
	tc._input(touch)
	_eq("touch holds move_right", tc._held.has(&"move_right"), true)
	var key := InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_LEFT
	tc._input(key)
	_eq("key press hides touch controls", tc.visible, false)
	_eq("hiding releases touch-held actions", tc._held.is_empty(), true)
	var drift := InputEventJoypadMotion.new()
	drift.axis_value = 0.2
	_eq("stick drift is not gamepad use", TouchControls._is_pad_or_key(drift), false)
	var up := InputEventKey.new()
	up.physical_keycode = KEY_LEFT
	_eq("key release is not a press", TouchControls._is_pad_or_key(up), false)
	tc._input(touch)
	_eq("touch shows touch controls again", tc.visible, true)
	var pad := InputEventJoypadButton.new()
	pad.pressed = true
	pad.button_index = JOY_BUTTON_A
	tc._input(pad)
	_eq("gamepad press hides touch controls", tc.visible, false)
	tc.queue_free()
	G.state = state_was

## A tap at pos, in the game's pixels (59.1: it comes in the screen's, TB.D to each).
func _tap(tc: TouchControls, pos: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.pressed = pressed
		e.position = pos * TB.D
		tc._input(e)
	# Injected actions are buffered until the next frame; deliver them now.
	Input.flush_buffered_events()

## iPad menus: list items act on one tap; cards take two (select, confirm).
func _test_menu_taps() -> void:
	var tc := TouchControls.new()
	add_child(tc)
	tc.visible = true
	var old: StringName = G.state
	Keys.tick()
	G.state = &"title"
	G.menu = 0
	var z: Dictionary = Taps.zones()[1]
	_tap(tc, z["rect"].get_center())
	_eq("title tap selects item 1", G.menu, 1)
	_eq("title tap confirms at once", Keys._latched[&"use"], true)
	Keys.tick()
	Keys.tick()
	var opts := Traits.all().slice(0, 3)
	G.tchoice = { "opts": opts, "idx": 0 }
	G.state = &"traits"
	var card: Rect2 = Taps.zones()[2]["rect"]
	_tap(tc, card.get_center())
	_eq("trait card tap selects", G.tchoice["idx"], 2)
	_eq("first card tap does not take it", Keys._latched[&"use"], false)
	_tap(tc, card.get_center())
	_eq("second card tap takes it", Keys._latched[&"use"], true)
	Keys.tick()
	Keys.tick()
	# A drag that ends off the card does nothing.
	var e := InputEventScreenTouch.new()
	e.pressed = true
	e.position = Taps.zones()[0]["rect"].get_center() * TB.D
	tc._input(e)
	e = InputEventScreenTouch.new()
	e.pressed = false
	e.position = Vector2(2, 2) * TB.D
	tc._input(e)
	_eq("tap released elsewhere is ignored", G.tchoice["idx"], 2)
	G.state = &"dead"
	_tap(tc, Vector2(200, 150))
	_eq("tap anywhere on the end screen presses USE", Keys._latched[&"use"], true)
	Keys.tick()
	G.tchoice = {}
	G.state = old
	tc.queue_free()

## Losing a synergy takes back what it gave and leaves the hero within the limits: hit points
## not above the (lower) maximum, roll charges between 0 and the (fewer) charges there are.
## 33 (found by a bot probe, 9 Oct): a foe's shot that leaves the room was looked up as a crate past
## the edge of the tile grid: a script error that stopped the rest of that tick's foe shots. Shots
## through every edge now just end, and every other shot keeps flying.
func _test_shots_off_the_edge() -> void:
	G.hero_index = 0
	G.new_run()
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.enemies.clear()
	EBullets.clear_all()
	var edges := [Vector2(TB.SW / 2.0, TB.SH - 2.0), Vector2(TB.SW - 2.0, TB.SH / 2.0), Vector2(TB.SW / 2.0, 1.0), Vector2(1.0, TB.SH / 2.0)]
	var dirs := [PI / 2, 0.0, -PI / 2, PI]
	for i in 4:
		EBullets.add(edges[i].x, edges[i].y, cos(dirs[i]) * 600.0, sin(dirs[i]) * 600.0, "red", 2.5, -1.0, "")
	EBullets.add(TB.SW / 2.0, TB.SH / 2.0, 0.0, 30.0, "red", 2.5, -1.0, "")   # one in the middle, slow
	var y0: float = EBullets.by[EBullets.n - 1]
	for t in 4:
		EBullets.update(TB.DT)
	_eq("shots past the edge end", EBullets.n, 1)
	_eq("the shot in the middle still moves", EBullets.n == 1 and EBullets.by[0] > y0, true)
	EBullets.clear_all()

func _test_synergy_loss() -> void:
	for tag in ["bulwark", "shadow"]:
		var p := Player.new(GameData.heroes()[0])
		var base_max := p.max_hp
		var base_rolls := p.dodge_charges
		for i in 6:
			p.relics.append({ "id": "t_%s_%d" % [tag, i], "tags": [tag], "new": true, "effects": [] })
		Effects.recount_tags(p)
		_eq("%s synergy on" % tag, p.synergies.has("syn:%s:1" % tag), true)
		p.hp = p.max_hp
		p.charges = p.dodge_charges if tag == "bulwark" else 0   # full heal; all rolls spent
		p.relics.pop_back()
		Effects.recount_tags(p)
		_eq("%s synergy off" % tag, p.synergies.has("syn:%s:1" % tag), false)
		_eq("%s max hp back" % tag, p.max_hp, base_max)
		_eq("%s rolls back" % tag, p.dodge_charges, base_rolls)
		_eq("%s hp within max" % tag, p.hp <= p.max_hp and p.hp >= 1, true)
		_eq("%s roll charges within limits" % tag, p.charges >= 0 and p.charges <= p.dodge_charges, true)

## Going to the background mid-fight opens the pause menu; elsewhere nothing changes.
func _test_background() -> void:
	var was: StringName = G.state
	G.state = &"play"
	G.notification(NOTIFICATION_APPLICATION_PAUSED)
	_eq("background in a fight pauses", G.state, &"pause")
	G.state = &"title"
	G.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_eq("background on the title stays there", G.state, &"title")
	G.state = was
