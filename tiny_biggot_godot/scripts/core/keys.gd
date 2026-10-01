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
]

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
	_bind(&"move_left", [_key(KEY_LEFT), _btn(JOY_BUTTON_DPAD_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_bind(&"move_right", [_key(KEY_RIGHT), _btn(JOY_BUTTON_DPAD_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_bind(&"move_up", [_key(KEY_UP), _btn(JOY_BUTTON_DPAD_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_bind(&"move_down", [_key(KEY_DOWN), _btn(JOY_BUTTON_DPAD_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_bind(&"aim_left", [_key(KEY_A), _axis(JOY_AXIS_RIGHT_X, -1.0)])
	_bind(&"aim_right", [_key(KEY_D), _axis(JOY_AXIS_RIGHT_X, 1.0)])
	_bind(&"aim_up", [_key(KEY_W), _axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_bind(&"aim_down", [_key(KEY_S), _axis(JOY_AXIS_RIGHT_Y, 1.0)])
	_bind(&"roll", [_key(KEY_SHIFT), _btn(JOY_BUTTON_B), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_bind(&"use", [_key(KEY_ENTER), _key(KEY_KP_ENTER), _key(KEY_SPACE), _key(KEY_Z), _btn(JOY_BUTTON_A)])
	_bind(&"heal", [_key(KEY_Q), _btn(JOY_BUTTON_X), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_bind(&"pause", [_key(KEY_ESCAPE), _key(KEY_X), _key(KEY_TAB), _key(KEY_QUOTELEFT), _key(KEY_P),
		_btn(JOY_BUTTON_Y), _btn(JOY_BUTTON_START)])
	_bind(&"bomb", [_key(KEY_CTRL), _key(KEY_F5), _key(KEY_E), _key(KEY_B),
		_btn(JOY_BUTTON_LEFT_SHOULDER), _btn(JOY_BUTTON_RIGHT_SHOULDER)])
	_bind(&"special", [_key(KEY_F), _btn(JOY_BUTTON_RIGHT_STICK), _btn(JOY_BUTTON_BACK)])

func _input(event: InputEvent) -> void:
	if event.is_echo():
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
