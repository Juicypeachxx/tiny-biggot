extends Node
## Small logic tests run headless: godot --headless --path . res://tests/unit_tests.tscn
## Reference values come from running the original Ruby code (see comments).

var _fails := 0

func _ready() -> void:
	_test_seed_rng()
	_test_ruby_math()
	_test_keyboard()
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
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = tc.stick_home + Vector2(tc.stick_r, 0)
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
