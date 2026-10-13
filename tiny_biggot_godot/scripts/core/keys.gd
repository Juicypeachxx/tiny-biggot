extends Node
## Input (port of Core.rb `Keys`). Autoload name: Keys.
##
## Bindings preserved from the VX Ace defaults that Core.rb relies on:
##   arrows            = move                 (VX Ace :UP/:DOWN/:LEFT/:RIGHT)
##   W / A / S / D     = aim up/left/down/right (VX Ace :R / :X / :Y / :Z)
##   Shift             = roll                 (VX Ace :A)
##   Enter / Space / Z = use / confirm        (VX Ace :C)
##   Q                 = heal (potion)        (VX Ace :L)
##   Esc / X           = pause / back         (VX Ace :B)
##   Ctrl, F5          = bomb                 (Input::CTRL, F5 fallback)
## Special ability (new heroes only): F, or R3 / Back on a gamepad.
## iPad Magic Keyboard extras (it has no Esc or function row): Tab, ` and P
## also pause; E and B also bomb. Every key is bound both by physical
## position and by the letter it types, so iPadOS and non-QWERTY layouts
## (e.g. QWERTZ) both work.
## Controller bindings mirror the original controls.json (Empo):
##   A = use, B / RT = roll, X / LT = heal, Y = menu, LB / RB = bomb,
##   right stick = aim, left stick / d-pad = move.
##
## The game logic runs in fixed 1/60 s ticks. tick() is called once per logic
## tick and turns raw key state into RGSS-style trigger?/repeat? edges. Presses
## that start and end between two ticks are latched so short taps (touch
## buttons) are never lost.

const ACTIONS := [
	&"move_left", &"move_right", &"move_up", &"move_down",
	&"aim_left", &"aim_right", &"aim_up", &"aim_down",
	&"roll", &"use", &"heal", &"pause", &"bomb",
	&"special",   # new: hero special ability (step-6 heroes only)
	&"belt1", &"belt2", &"belt3", &"belt4",   # Rogues layer: quick belt
]

## 13.1 (his ask, 7 Oct: "keyboard mapping in options"): the keyboard keys of every action can be
## changed (Options > KEYBOARD KEYS). A chosen key replaces that action's keyboard keys and is
## taken away from any other action; pads and touch are untouched. Esc always pauses / goes back
## and Enter always confirms, so a player can never lock themselves out. Saved in
## Meta.opts["keymap"] (action -> key code).
const REBIND := [
	[&"move_up", "MOVE UP"], [&"move_down", "MOVE DOWN"], [&"move_left", "MOVE LEFT"], [&"move_right", "MOVE RIGHT"],
	[&"aim_up", "AIM UP"], [&"aim_down", "AIM DOWN"], [&"aim_left", "AIM LEFT"], [&"aim_right", "AIM RIGHT"],
	[&"roll", "ROLL"], [&"use", "USE / CONFIRM"], [&"heal", "HEAL"], [&"bomb", "BOMB"], [&"special", "SPECIAL"],
	[&"pause", "PAUSE / BACK"], [&"belt1", "BELT 1"], [&"belt2", "BELT 2"], [&"belt3", "BELT 3"], [&"belt4", "BELT 4"],
]
const LOCKED := { &"pause": [KEY_ESCAPE], &"use": [KEY_ENTER, KEY_KP_ENTER] }
var DEFAULT_KEYS := {
	&"move_left": [KEY_LEFT], &"move_right": [KEY_RIGHT], &"move_up": [KEY_UP], &"move_down": [KEY_DOWN],
	&"aim_left": [KEY_A], &"aim_right": [KEY_D], &"aim_up": [KEY_W], &"aim_down": [KEY_S],
	&"roll": [KEY_SHIFT], &"use": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_Z], &"heal": [KEY_Q],
	&"pause": [KEY_ESCAPE, KEY_X, KEY_TAB, KEY_QUOTELEFT, KEY_P],
	&"bomb": [KEY_CTRL, KEY_F5, KEY_E, KEY_B], &"special": [KEY_F],
	&"belt1": [KEY_1], &"belt2": [KEY_2], &"belt3": [KEY_3], &"belt4": [KEY_4],
}
var capturing: StringName = &""   # waiting for a key for this action (the KEYBOARD KEYS page)
var capture_t := 0.0              # 22.4: how long it has waited (a touch-only iPad has no key to press)
const CAPTURE_MAX := 8.0
var hold_off := 0                  # ticks the keys page ignores input after a key was taken

var _down := {}
var _prev := {}
var _held := {}
var _latched := {}
var _trig := {}
var _rep := {}

# Windows co-op (COOP_PLAN.md, his word 12 Oct): each player's own devices. who = -1: every device
# at once (one player, as always); who = i: only pads[i] (Coop sets it around each hero's turn).
var pads: Array = []
var who := -1
var _merged: Array = []
var _cursor := -1

## W2: two players on one keyboard. The pad "kbm" is its left half (and the mouse), "kb2" its right
## half. When both are in the party each reads only its own keys, from these fixed tables (the
## KEYBOARD KEYS page changes the one-player keys only); a keyboard player alone keeps every key.
## A key is a key code, or [code, side] for a key that has a left and a right one (Shift, Ctrl).
## The left player aims with the mouse (or fires at the nearest foe by itself, as always).
## The CO-OP screen has both halves from the start ("in": joined): with nobody on the keyboard each
## half is its own (SPACE joins the left one, ENTER the right one); with one keyboard player, they
## have every key but the other half's USE key, which joins a second player on the keyboard.
const KB_LEFT := {
	&"move_up": [KEY_W], &"move_down": [KEY_S], &"move_left": [KEY_A], &"move_right": [KEY_D],
	&"roll": [[KEY_SHIFT, KEY_LOCATION_LEFT]], &"use": [KEY_SPACE], &"heal": [KEY_Q],
	&"pause": [KEY_ESCAPE, KEY_TAB, KEY_QUOTELEFT], &"bomb": [KEY_E], &"special": [KEY_F],
	&"belt1": [KEY_1], &"belt2": [KEY_2], &"belt3": [KEY_3], &"belt4": [KEY_4],
}
const KB_RIGHT := {
	&"move_up": [KEY_UP], &"move_down": [KEY_DOWN], &"move_left": [KEY_LEFT], &"move_right": [KEY_RIGHT],
	&"aim_up": [KEY_KP_8], &"aim_down": [KEY_KP_5, KEY_KP_2], &"aim_left": [KEY_KP_4], &"aim_right": [KEY_KP_6],
	&"roll": [[KEY_SHIFT, KEY_LOCATION_RIGHT], KEY_KP_0], &"use": [KEY_ENTER, KEY_KP_ENTER],
	&"heal": [KEY_SLASH], &"pause": [KEY_BACKSPACE], &"bomb": [[KEY_CTRL, KEY_LOCATION_RIGHT], KEY_COMMA],
	&"special": [KEY_PERIOD],
	&"belt1": [KEY_7], &"belt2": [KEY_8], &"belt3": [KEY_9], &"belt4": [KEY_0],
}
var _split := false   # each half reads its own keys (both in the party; on the CO-OP screen, neither yet)
var _lone := -1       # the CO-OP screen: the one keyboard player so far (pad), the other half free to join
var _side := {}       # code * 8 + side -> held (Shift and Ctrl: which one, from their events)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input_map()
	for a in ACTIONS:
		_down[a] = false
		_prev[a] = false
		_held[a] = 0
		_latched[a] = false
		_trig[a] = false
		_rep[a] = false
	_merged = [_down, _trig, _rep]

func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e

## Same key matched by the character it types (fallback when a platform or
## layout reports a different physical code).
func _lkey(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	return e

func _btn(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.device = -1   # (Windows co-op: every controller, not only the first)
	return e

func _mouse(b: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = b
	return e

func _axis(ax: JoyAxis, v: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = ax
	e.axis_value = v
	e.device = -1   # (every controller)
	return e

func _bind(action: StringName, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
	for e in events:
		InputMap.action_add_event(action, e)
		if e is InputEventKey:
			InputMap.action_add_event(action, _lkey(e.physical_keycode))

func _setup_input_map() -> void:
	_bind(&"move_left", [_btn(JOY_BUTTON_DPAD_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_bind(&"move_right", [_btn(JOY_BUTTON_DPAD_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_bind(&"move_up", [_btn(JOY_BUTTON_DPAD_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_bind(&"move_down", [_btn(JOY_BUTTON_DPAD_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_bind(&"aim_left", [_axis(JOY_AXIS_RIGHT_X, -1.0)])
	_bind(&"aim_right", [_axis(JOY_AXIS_RIGHT_X, 1.0)])
	_bind(&"aim_up", [_axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_bind(&"aim_down", [_axis(JOY_AXIS_RIGHT_Y, 1.0)])
	_bind(&"roll", [_btn(JOY_BUTTON_B), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0), _mouse(MOUSE_BUTTON_RIGHT)])   # (Windows: the right mouse button)
	_bind(&"use", [_btn(JOY_BUTTON_A)])
	_bind(&"heal", [_btn(JOY_BUTTON_X), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_bind(&"pause", [_btn(JOY_BUTTON_Y), _btn(JOY_BUTTON_START)])
	_bind(&"bomb", [_btn(JOY_BUTTON_LEFT_SHOULDER), _btn(JOY_BUTTON_RIGHT_SHOULDER)])
	_bind(&"special", [_btn(JOY_BUTTON_RIGHT_STICK), _btn(JOY_BUTTON_BACK)])
	for a in [&"belt1", &"belt2", &"belt3", &"belt4"]:
		_bind(a, [])
	apply_keymap()

# ---------- 13.1 Key mapping ----------
func _keymap() -> Dictionary:
	if not (Meta.opts.get("keymap") is Dictionary):
		Meta.opts["keymap"] = {}
	return Meta.opts["keymap"]

## The keyboard keys of an action now: its chosen key (and its locked keys), else its defaults
## less any key another action has taken.
func keys_of(a: StringName) -> Array:
	var km := _keymap()
	if km.has(String(a)):
		var out: Array = [int(km[String(a)])]
		for k in LOCKED.get(a, []):
			if not k in out:
				out.append(k)
		return out
	var taken := []
	for b in km:
		if b != String(a):
			taken.append(int(km[b]))
	return DEFAULT_KEYS[a].filter(func(k): return not k in taken or k in LOCKED.get(a, []))

## Rebuilds every action's keyboard keys from the defaults and the saved choices.
func apply_keymap() -> void:
	for a in ACTIONS:
		for e in InputMap.action_get_events(a):
			if e is InputEventKey:
				InputMap.action_erase_event(a, e)
		for k in keys_of(a):
			InputMap.action_add_event(a, _key(k))
			InputMap.action_add_event(a, _lkey(k))

## Gives `a` the key `code` (taken from any other action). Esc and Enter stay where they are.
func set_key(a: StringName, code: int) -> bool:
	for b in LOCKED:
		if code in LOCKED[b] and b != a:
			return false
	var km := _keymap()
	for b in km.keys():
		if int(km[b]) == code:
			km.erase(b)
	km[String(a)] = code
	apply_keymap()
	return true

func reset_keys() -> void:
	Meta.opts["keymap"] = {}
	apply_keymap()

## A key's name in the pixel font.
static func key_name(code: int) -> String:
	var n := OS.get_keycode_string(code).to_upper()
	n = n.replace("QUOTELEFT", "`").replace("KP ", "PAD ")
	var out := ""
	for ch in n:
		out += ch if ch in Gfx.FONT_CHARS else "?"
	return out if out != "" else "?"

func keys_label(a: StringName) -> String:
	var ks := keys_of(a).filter(func(k): return k != KEY_KP_ENTER)
	var names := []
	for k in ks.slice(0, 3):
		names.append(key_name(k))
	return " / ".join(names) if not names.is_empty() else "-"

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event is InputEventKey and event.location != KEY_LOCATION_UNSPECIFIED:
		_side[_code(event) * 8 + event.location] = event.pressed   # (W2: which Shift, which Ctrl)
	if capturing != &"" and event is InputEventKey and event.pressed:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code != KEY_ESCAPE:
			if set_key(capturing, code):
				Snd.play("confirm")
				Meta.write_save()
			else:
				Snd.play("deny")
		capturing = &""
		hold_off = 12
		get_viewport().set_input_as_handled()
		return
	for a in ACTIONS:
		if event.is_action_pressed(a):
			_latched[a] = true
			var pi := pad_of(event)   # (Windows co-op: and for the player whose device it is)
			if pi >= 0 and not (_split and event is InputEventKey):
				pads[pi]["latched"][a] = true
	if _split and event is InputEventKey and event.pressed:
		for half in 2:   # (W2: a key shared by two players counts for its own half)
			var pi := _half_pad(half)
			var table: Dictionary = KB_LEFT if half == 0 else KB_RIGHT
			for a in table:
				for spec in table[a]:
					if _is_spec(spec, event):
						pads[pi]["latched"][a] = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_side.clear()   # (keys let go in another window are not held here)

## Call once per fixed logic tick, before the game update.
func tick() -> void:
	use_pad(-1)
	for a in ACTIONS:
		var raw := Input.is_action_pressed(a)
		var down: bool = raw or _latched[a]
		var trig: bool = _latched[a] or (down and not _prev[a])
		_held[a] = (_held[a] + 1) if down else 0
		var h: int = _held[a]
		_trig[a] = trig
		_rep[a] = trig or (h >= 24 and (h - 24) % 6 == 0)
		_down[a] = down
		_prev[a] = raw
		_latched[a] = false
	for pd in pads:
		_pad_tick(pd)
	if Coop.on():
		use_pad(Coop.menu_pad())   # (the menus listen to whoever's turn it is: P1, else P2 to P4)
	var want := Input.CURSOR_CROSS if G.state == &"play" else Input.CURSOR_ARROW   # (Windows: aim with the mouse)
	if want != _cursor:
		_cursor = want
		Input.set_default_cursor_shape(want)

func pressed(a: StringName) -> bool:
	return _down[a]

func triggered(a: StringName) -> bool:
	return _trig[a]

func repeated(a: StringName) -> bool:
	return _rep[a]

# ---------- Core.rb Keys API ----------
func move() -> Vector2:
	var x := 0.0
	var y := 0.0
	if _down[&"move_left"]: x -= 1
	if _down[&"move_right"]: x += 1
	if _down[&"move_up"]: y -= 1
	if _down[&"move_down"]: y += 1
	if x != 0 and y != 0:
		x *= 0.7071
		y *= 0.7071
	return Vector2(x, y)

## Manual aim angle, or null when no aim key is held (an angle of 0.0 is valid!).
func aim() -> Variant:
	var pa = _pointer_aim()
	if pa != null:
		return pa
	var x := 0
	var y := 0
	if _down[&"aim_left"]: x -= 1
	if _down[&"aim_right"]: x += 1
	if _down[&"aim_up"]: y -= 1
	if _down[&"aim_down"]: y += 1
	if x == 0 and y == 0:
		return null
	return atan2(y, x)

func roll() -> bool: return _trig[&"roll"]
func use() -> bool: return _trig[&"use"]
func heal() -> bool: return _trig[&"heal"]
func pause() -> bool: return _trig[&"pause"]
func bomb() -> bool: return _trig[&"bomb"]
func special() -> bool: return _trig[&"special"]
## Quick-belt slot pressed this tick (0-3), or -1.
func belt() -> int:
	for i in 4:
		if _trig[[&"belt1", &"belt2", &"belt3", &"belt4"][i]]:
			return i
	return -1
func fire_held() -> bool: return false
func up() -> bool: return _rep[&"move_up"]
func down() -> bool: return _rep[&"move_down"]
func left() -> bool: return _rep[&"move_left"]
func right() -> bool: return _rep[&"move_right"]
func confirm() -> bool: return _trig[&"use"]
func back() -> bool: return _trig[&"pause"]
func any() -> bool: return _trig[&"use"] or _trig[&"pause"] or _trig[&"roll"]
## Input.trigger?(:X) / (:Z) in the skill tree = aim left / aim right keys.
func aim_left_trig() -> bool: return _trig[&"aim_left"]
func aim_right_trig() -> bool: return _trig[&"aim_right"]

# ---------- Windows co-op: each player's own devices (COOP_PLAN.md) ----------
## A pad: kind "kbm" (the keyboard and mouse), "kb2" (W2: the keyboard's right half, for a second
## player on it), "joy" (one controller, dev = its device id) or "bot" (tests: bot[action] = held),
## with its own down / trig / rep tables like the ones above.
func add_pad(kind: String, dev: int = -1) -> int:
	pads.append({ "kind": kind, "dev": dev, "in": true, "bot": {}, "down": {}, "prev": {}, "held": {},
		"latched": {}, "trig": {}, "rep": {} })
	_seats()
	_pad_tick(pads.back())
	return pads.size() - 1

func clear_pads() -> void:
	use_pad(-1)
	pads.clear()
	_seats()

## The CO-OP screen: pad k's player has joined (true) or left.
func seat(k: int, on: bool) -> void:
	if k >= 0 and k < pads.size():
		pads[k]["in"] = on
		_seats()

## W2: two players share the keyboard (each reads only their half of it).
func split() -> bool:
	return _split

func _seats() -> void:
	var was := [_split, _lone]
	var l := _half_pad(0)
	var r := _half_pad(1)
	_split = false
	_lone = -1
	if l >= 0 and r >= 0:
		if pads[l]["in"] == pads[r]["in"]:
			_split = true
		else:
			_lone = l if pads[l]["in"] else r
	if [_split, _lone] != was:
		for pd in pads:   # (a key held as the keyboard changes hands is not a new press for its new owner)
			if pd["kind"] in ["kbm", "kb2"]:
				for a in ACTIONS:
					pd["prev"][a] = _pad_raw(pd, a)

## The CO-OP screen with one keyboard player: the other half's pad (its USE key joins), or -1.
func _free_pad() -> int:
	return -1 if _lone < 0 else _half_pad(1 if pads[_lone]["kind"] == "kbm" else 0)

## Is the key of this InputMap event one of pad k's half's USE keys?
func _joins(k: int, e: InputEventKey) -> bool:
	var c := _code(e)
	return c in (KB_LEFT if pads[k]["kind"] == "kbm" else KB_RIGHT)[&"use"]

## The pad of the keyboard's left half ("kbm", half 0) or right half ("kb2", half 1), or -1.
func _half_pad(half: int) -> int:
	for i in pads.size():
		if pads[i]["kind"] == ("kbm" if half == 0 else "kb2"):
			return i
	return -1

## The pad of the mouse, and of the whole keyboard when one player has it: the left half's, else the
## right half's (a keyboard player alone), or -1.
func mouse_pad() -> int:
	if _lone >= 0:
		return _lone
	var i := _half_pad(0)
	return i if i >= 0 else _half_pad(1)

## The key code of a key event: where the key is (its physical place), else what it types.
static func _code(event: InputEventKey) -> int:
	return event.physical_keycode if event.physical_keycode != 0 else event.keycode

## Is this key event the key of `spec` (a code, or [code, side])?
static func _is_spec(spec, event: InputEventKey) -> bool:
	if spec is Array:
		return _code(event) == spec[0] and event.location == spec[1]
	return _code(event) == spec

## Is the key of `spec` held? A side's Shift or Ctrl by its own events (the system only tells that
## some Shift is held).
func _key_held(spec) -> bool:
	if spec is Array:
		return _side.get(int(spec[0]) * 8 + int(spec[1]), false)
	return Input.is_physical_key_pressed(spec)

## The API above reads pads[i] (-1: every device, one player).
func use_pad(i: int) -> void:
	if i >= pads.size():
		i = -1
	if i == who:
		return
	who = i
	var t: Array = _merged if i < 0 else [pads[i]["down"], pads[i]["trig"], pads[i]["rep"]]
	_down = t[0]
	_trig = t[1]
	_rep = t[2]

## The pad an input event comes from, or -1. With two players on the keyboard a key is the pad of
## its half (-1: a key of neither).
func pad_of(event: InputEvent) -> int:
	if event is InputEventKey and _split:
		for half in 2:
			var table: Dictionary = KB_LEFT if half == 0 else KB_RIGHT
			for a in table:
				for spec in table[a]:
					if _is_spec(spec, event):
						return _half_pad(half)
		return -1
	if event is InputEventKey and _free_pad() >= 0 and _joins(_free_pad(), event):
		return _free_pad()   # (the CO-OP screen: a second player joins on the keyboard)
	if event is InputEventKey or event is InputEventMouseButton:
		return mouse_pad()
	for i in pads.size():
		var pd: Dictionary = pads[i]
		if pd["kind"] == "joy" and (event is InputEventJoypadButton or event is InputEventJoypadMotion) and event.device == pd["dev"]:
			return i
	return -1

func _pad_tick(pd: Dictionary) -> void:
	for a in ACTIONS:
		var raw := _pad_raw(pd, a)
		var lat: bool = pd["latched"].get(a, false)
		var down: bool = raw or lat
		var trig: bool = lat or (down and not pd["prev"].get(a, false))
		var h: int = (int(pd["held"].get(a, 0)) + 1) if down else 0
		pd["held"][a] = h
		pd["trig"][a] = trig
		pd["rep"][a] = trig or (h >= 24 and (h - 24) % 6 == 0)
		pd["down"][a] = down
		pd["prev"][a] = raw
		pd["latched"][a] = false

func _pad_raw(pd: Dictionary, a: StringName) -> bool:
	match pd["kind"]:
		"bot":
			return pd["bot"].get(a, false)
		"kbm", "kb2":
			if _split:   # (W2: two players on the keyboard: each their own half; the mouse is the left one's)
				for spec in (KB_LEFT if pd["kind"] == "kbm" else KB_RIGHT).get(a, []):
					if _key_held(spec):
						return true
				if pd["kind"] != "kbm":
					return false
			elif _lone >= 0 and not is_same(pd, pads[_lone]):
				if a != &"use":   # (the CO-OP screen: the half nobody has yet only joins)
					return false
				for spec in (KB_LEFT if pd["kind"] == "kbm" else KB_RIGHT)[&"use"]:
					if _key_held(spec):
						return true
				return false
			var free := _free_pad()
			for e in InputMap.action_get_events(a):
				if not _split and e is InputEventKey and ((e.physical_keycode != 0 and Input.is_physical_key_pressed(e.physical_keycode))
						or (e.keycode != 0 and Input.is_key_pressed(e.keycode))) and not (free >= 0 and _joins(free, e)):
					return true
				if e is InputEventMouseButton and Input.is_mouse_button_pressed(e.button_index):
					return true
		"joy":
			var d: int = pd["dev"]
			for e in InputMap.action_get_events(a):
				if e is InputEventJoypadButton and Input.is_joy_button_pressed(d, e.button_index):
					return true
				if e is InputEventJoypadMotion and Input.get_joy_axis(d, e.axis) * signf(e.axis_value) >= 0.5:
					return true
	return false

## Aim from a pointer: the mouse while its left button is held (fire at the cursor), or a
## controller's right stick at its true angle. Null when neither is in use.
func _pointer_aim() -> Variant:
	var kind := "all"
	var dev := -1
	if who >= 0:
		kind = pads[who]["kind"]
		dev = pads[who]["dev"]
	if (kind == "all" or (who >= 0 and who == mouse_pad())) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and G.player != null:
		var m := get_viewport().get_mouse_position()
		return atan2(m.y - G.player.y, m.x - G.player.x)
	if kind == "joy":
		return _stick_aim(dev)
	if kind == "all":
		for d in Input.get_connected_joypads():
			var sa = _stick_aim(d)
			if sa != null:
				return sa
	return null

func _stick_aim(d: int) -> Variant:
	var v := Vector2(Input.get_joy_axis(d, JOY_AXIS_RIGHT_X), Input.get_joy_axis(d, JOY_AXIS_RIGHT_Y))
	return v.angle() if v.length() >= 0.5 else null
