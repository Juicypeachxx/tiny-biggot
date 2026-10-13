class_name MouseMenus
extends Node
## The Windows line (his word, 12 Oct: the PC port; COOP_PLAN.md, "not done yet": clicking menus with
## the mouse). Every menu takes the mouse the way the iPad's take a finger, through the same zones
## (Taps.zones: the rects the drawing uses): pointing at an entry selects it, a left click picks it (or
## presses a button), and the wheel moves the choice up and down. On a screen that waits for any
## button, a click goes on. In play the mouse aims and fires (Keys), so nothing here runs then; the
## constellation and the CO-OP screen read the mouse themselves.
## In co-op the mouse is the keyboard player's (with two on the keyboard, the left half's: W2): it
## works their menus, and the ones anyone may finish (the end screens), never another player's turn.
## F11 or Alt+Enter switches between the window and the full screen; the choice is kept (Meta.opts
## "fullscreen") for the next start.
## Only real mouse and key events reach it, so tests without them and the replays are untouched.

static var _acting := false   # a click of ours is being handled (Taps.send asks `latch`)

func _ready() -> void:
	if Meta.opts.get("fullscreen", false):
		_set_full(true)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo and (event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed)):
			toggle_full()
			get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseMotion or event is InputEventMouseButton) or not active():
		return
	if event is InputEventMouseMotion:
		point(event.position)
	elif event.pressed:
		click(event.position, event.button_index)

## The mouse may work the screen now.
static func active() -> bool:
	if DebugArgs.has("touch") or G.state in [&"play", &"stars", &"coop", &"fade"]:
		return false
	if Coop.on():
		var mp := Coop.menu_pad()
		if mp >= 0 and mp != Keys.mouse_pad():
			return false   # another player's menu
	return true

## Pointing: the entry under the mouse is selected (a tick of sound when it changes).
static func point(at: Vector2) -> void:
	var z := Taps.hit(at)
	if z.is_empty() or z.has("act") or z["on"]:
		return
	z["sel"].call()
	Snd.play("select")

## A click: the left button picks what is under the mouse (or goes on, on a screen that waits for any
## button); the wheel moves the choice up and down.
static func click(at: Vector2, button: int) -> void:
	_acting = true
	match button:
		MOUSE_BUTTON_LEFT:
			if Taps.any_tap():
				Taps.send(&"use")
			else:
				var z := Taps.hit(at)
				if not z.is_empty():
					if z.has("act"):
						Taps.activate(z)
					else:
						if not z["on"]:
							z["sel"].call()
						Taps.send(&"use")
		MOUSE_BUTTON_WHEEL_UP:
			Taps.send(&"move_up")
		MOUSE_BUTTON_WHEEL_DOWN:
			Taps.send(&"move_down")
	_acting = false

## Taps.send, while a click of ours is handled in co-op: the press is the keyboard player's, so it
## goes to their pad (an action event belongs to no pad). False: send it the usual way.
static func latch(action: StringName) -> bool:
	if not _acting or not Coop.on():
		return false
	var mp := Coop.menu_pad()
	if mp < 0 or mp != Keys.mouse_pad():
		return false
	Keys.pads[mp]["latched"][action] = true
	return true

static func toggle_full() -> void:
	var full := not _is_full()
	_set_full(full)
	Meta.opts["fullscreen"] = full
	Meta.write_save()
	Snd.play("select")

static func _is_full() -> bool:
	var m := DisplayServer.window_get_mode()
	return m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

static func _set_full(full: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_WINDOWED)
