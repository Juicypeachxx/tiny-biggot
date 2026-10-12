extends Node
## Windows co-op (COOP_PLAN.md; the Windows line only). Run:
##   godot --headless --path . res://tests/coop_test.tscn -- --no-save
## C1 each player's own devices: a pad reads only its own device (here bot pads, a keyboard and a
## controller by their events), every device at once when no pad is chosen, and the edges (pressed
## this tick, held, repeated) per pad.
## Prints "coop test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL coop: ", msg)

func _ready() -> void:
	_pads()
	Keys.clear_pads()
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
