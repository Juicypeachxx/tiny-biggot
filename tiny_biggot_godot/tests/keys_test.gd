extends Node
## 13.1 key mapping (scripts/core/keys.gd, Options > KEYBOARD KEYS). Run:
##   godot --headless --path . res://tests/keys_test.tscn -- --no-save
## A chosen key replaces the action's keys and leaves every other action; Esc and Enter cannot be
## taken; the keys page takes the next key press; RESET puts every key back; every label fits the font.
## Prints "keys test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL keys: ", msg)

func _has(a: StringName, code: int) -> bool:
	for e in InputMap.action_get_events(a):
		if e is InputEventKey and (e.physical_keycode == code or e.keycode == code):
			return true
	return false

func _press(code: int) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	Keys._input(e)

func _ready() -> void:
	await get_tree().process_frame
	Keys.reset_keys()
	if not _has(&"roll", KEY_SHIFT) or not _has(&"heal", KEY_Q) or not _has(&"use", KEY_SPACE):
		fail("the default keys are missing")
	Keys.set_key(&"roll", KEY_R)
	if not _has(&"roll", KEY_R) or _has(&"roll", KEY_SHIFT):
		fail("ROLL did not move to R")
	Keys.set_key(&"roll", KEY_Q)
	if not _has(&"roll", KEY_Q) or _has(&"heal", KEY_Q) or _has(&"roll", KEY_R):
		fail("Q was not taken from HEAL for ROLL")
	if Keys.set_key(&"heal", KEY_ESCAPE) or Keys.set_key(&"roll", KEY_ENTER):
		fail("Esc or Enter could be taken")
	Keys.set_key(&"pause", KEY_O)
	if not _has(&"pause", KEY_ESCAPE) or not _has(&"pause", KEY_O):
		fail("PAUSE lost Esc")
	# The page: Options > KEYBOARD KEYS, pick BOMB, press G.
	G.state = &"options"
	G.opt_from = &"title"
	G.menu = G.OPTION_LIST.size() - 2
	if G.OPTION_LIST[G.menu][1] != "@keys":
		fail("no KEYBOARD KEYS row before BACK")
	G.state = &"keys"
	G.menu = 11
	Keys.hold_off = 0
	Keys.capturing = Keys.REBIND[11][0]
	_press(KEY_G)
	if Keys.capturing != &"" or not _has(&"bomb", KEY_G):
		fail("the page did not take G for %s" % Keys.REBIND[11][1])
	# 22.4: with no keyboard (a touch-only iPad) a tap, or the wait running out, ends the wait.
	Keys.capturing = Keys.REBIND[3][0]
	Keys.capture_t = 0.0
	for i in 30:
		Keys.tick()
		G.update_keys()
	Keys._latched[&"use"] = true   # a tap on the page counts as USE
	Keys.tick()
	G.update_keys()
	if Keys.capturing != &"":
		fail("a tap did not end the wait for a key")
	Keys.capturing = Keys.REBIND[3][0]
	Keys.capture_t = 0.0
	for i in int((Keys.CAPTURE_MAX + 0.5) / TB.DT):
		Keys.tick()
		G.update_keys()
	if Keys.capturing != &"":
		fail("the wait for a key never ended")
	for r in Keys.REBIND:
		for ch in r[1] + Keys.keys_label(r[0]):
			if not ch in Gfx.FONT_CHARS:
				fail("'%s' not in the font (%s)" % [ch, r[1]])
	Keys.reset_keys()
	if not _has(&"roll", KEY_SHIFT) or not _has(&"heal", KEY_Q) or _has(&"bomb", KEY_G) or not _has(&"pause", KEY_X):
		fail("RESET did not put the keys back")
	print("keys test: PASSED" if fails == 0 else "keys test: %d FAILED" % fails)
	get_tree().quit()
