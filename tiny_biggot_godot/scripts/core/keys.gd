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
var hold_off := 0                  # ticks the keys page ignores input after a key was taken

var _down := {}
var _prev := {}
var _held := {}
var _latched := {}
var _trig := {}
var _rep := {}

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
	return e

func _axis(ax: JoyAxis, v: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = ax
	e.axis_value = v
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
	_bind(&"roll", [_btn(JOY_BUTTON_B), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
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

## Call once per fixed logic tick, before the game update.
func tick() -> void:
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
