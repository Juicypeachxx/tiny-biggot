class_name TouchControls
extends Node2D
## On-screen touch controls, the primary input on iPad. The layout comes from
## the original Empo controls.json ("touch.landscape"): positions are
## fractions of the screen and sizes are in points. Touches are turned into
## the same input actions as the keyboard (via InputEventAction), so the game
## logic never knows which device was used.
##
## - Move stick (left): fixed base from the layout, and a touch anywhere in
##   the left half grabs it. 8-way, like the arrow keys.
## - Aim cluster (AIM UP/L/R/DN): one finger slides between the four buttons;
##   between two buttons it aims diagonally, like holding W+A.
## - ROLL, USE, HEAL, MENU and BOMB buttons are held while the finger stays down.
##
## A key press (iPad Magic Keyboard) or gamepad input hides the controls; the
## next touch brings them back.

const LAYOUT_PATH := "res://assets/controls.json"
const KEY_TO_ACTION := {
	"KeyW": &"aim_up", "KeyA": &"aim_left", "KeyD": &"aim_right", "KeyS": &"aim_down",
	"ShiftLeft": &"roll", "Enter": &"use", "KeyQ": &"heal", "Escape": &"pause", "ControlLeft": &"bomb",
}
const AIM_ACTIONS := [&"aim_up", &"aim_left", &"aim_right", &"aim_down"]
const DIAG := 0.38   # sin(22.5 deg): 8-way split for stick and aim cluster

var stick_frac := Vector2(0.13, 0.72)
var stick_pt := 160.0
var stick_opacity := 0.7
var stick_home := Vector2.ZERO
var stick_center := Vector2.ZERO
var stick_r := 32.0
var knob := Vector2.ZERO
var buttons: Array = []     # { label, action, frac, pt, opacity, pos, r }
var aim_center := Vector2.ZERO
var aim_r := 0.0

var _touches := {}          # touch index -> { kind, action, pos }
var _held := {}             # action -> true while pressed by touch

var _mouse_as_touch := false

func _ready() -> void:
	_load_layout()
	# Shown on touch devices (the iPad), or on a desktop with --touch, where
	# the left mouse button plays the role of one finger.
	_mouse_as_touch = DebugArgs.has("touch")
	visible = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or _mouse_as_touch
	get_viewport().size_changed.connect(_layout)
	_layout()

func _load_layout() -> void:
	var f := FileAccess.open(LAYOUT_PATH, FileAccess.READ)
	if f == null:
		push_warning("TouchControls: controls.json missing, using defaults")
		return
	var data = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary):
		return
	var land: Dictionary = data.get("touch", {}).get("landscape", {})
	var dp: Dictionary = land.get("dpad", {})
	stick_frac = Vector2(dp.get("x", 0.13), dp.get("y", 0.72))
	stick_pt = dp.get("size", 160.0)
	stick_opacity = dp.get("opacity", 0.7)
	for b in land.get("buttons", []):
		var action = KEY_TO_ACTION.get(b.get("key", ""))
		if action == null:
			continue
		buttons.append({ "label": b.get("label", ""), "action": action, "frac": Vector2(b["x"], b["y"]),
			"pt": float(b.get("size", 52)), "opacity": float(b.get("opacity", 0.7)), "pos": Vector2.ZERO, "r": 10.0 })

## Converts layout points to game pixels for the current screen (integer
## stretch: 5x on the iPad Air, where one game pixel is 2.5 points).
func _pt_per_px() -> float:
	var win := DisplayServer.window_get_size()
	var scale := maxf(1.0, floorf(minf(win.x / float(TB.SW), win.y / float(TB.SH))))
	return maxf(0.5, scale / maxf(1.0, DisplayServer.screen_get_scale()))

func _layout() -> void:
	var k := _pt_per_px()
	var screen := Vector2(TB.SW, TB.SH)
	stick_home = stick_frac * screen
	stick_center = stick_home
	stick_r = clampf(stick_pt / 2.0 / k, 22.0, 48.0)
	var sum := Vector2.ZERO
	var naim := 0
	for b in buttons:
		b["pos"] = b["frac"] * screen
		b["r"] = clampf(b["pt"] / 2.0 / k, 8.0, 20.0)
		if b["action"] in AIM_ACTIONS:
			sum += b["pos"]
			naim += 1
	if naim > 0:
		aim_center = sum / naim
		aim_r = 0.0
		for b in buttons:
			if b["action"] in AIM_ACTIONS:
				aim_r = maxf(aim_r, aim_center.distance_to(b["pos"]) + b["r"])

func _input(event: InputEvent) -> void:
	if visible and _is_pad_or_key(event):
		_hide()
		return
	if not visible and (event is InputEventScreenTouch
			or (_mouse_as_touch and event is InputEventMouseButton)) and event.pressed:
		visible = true   # a touch reveals the controls again
	if not visible:
		return
	if _mouse_as_touch:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_begin(0, event.position)
			else:
				_end(0, event.position)
			_sync()
			return
		if event is InputEventMouseMotion and _touches.has(0):
			_touches[0]["pos"] = event.position
			_sync()
			return
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin(event.index, event.position)
		else:
			_end(event.index, event.position)
		_sync()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if _touches.has(event.index):
			_touches[event.index]["pos"] = event.position
			_sync()
			get_viewport().set_input_as_handled()

## Keyboard or gamepad use: true for a real press, not for releases or stick
## drift, so a key released after the switch does not flicker the controls.
static func _is_pad_or_key(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventJoypadMotion:
		return absf(event.axis_value) > 0.6
	return false

## Hides the controls and releases anything a finger was still holding.
func _hide() -> void:
	visible = false
	_touches.clear()
	_sync()

var _last_state: StringName = &""

func _process(_delta: float) -> void:
	if visible and G.state != _last_state:
		_last_state = G.state
		queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_touches.clear()
		_sync()

const MENU_BUTTONS := [&"use", &"pause", &"roll"]   # buttons that still matter on menu screens

func _begin(index: int, pos: Vector2) -> void:
	var menu_screen := G.state != &"play"
	for b in buttons:
		if b["action"] in AIM_ACTIONS or (menu_screen and not b["action"] in MENU_BUTTONS):
			continue
		if pos.distance_to(b["pos"]) <= b["r"] * 1.3:
			_touches[index] = { "kind": "button", "action": b["action"], "pos": pos }
			return
	# Menus: tap an item or card directly (scripts/render/taps.gd).
	if menu_screen:
		var z := Taps.hit(pos)
		if not z.is_empty():
			_touches[index] = { "kind": "tap", "zone": z, "pos": pos }
			return
		if Taps.any_tap():
			_touches[index] = { "kind": "tapany", "pos": pos }
			return
	if aim_r > 0 and pos.distance_to(aim_center) <= aim_r:
		_touches[index] = { "kind": "aim", "pos": pos }
		return
	if pos.x < TB.SW * 0.5:
		# Floating stick: centre on the finger unless it landed on the drawn base.
		stick_center = stick_home if pos.distance_to(stick_home) <= stick_r * 1.5 else pos
		_touches[index] = { "kind": "stick", "pos": pos }

## A finger lifted: menu taps fire on release, if it is still on the same zone.
func _end(index: int, pos: Vector2) -> void:
	var t: Dictionary = _touches.get(index, {})
	_touches.erase(index)
	match t.get("kind", ""):
		"tap":
			var z := Taps.hit(pos)
			if not z.is_empty() and z["rect"] == t["zone"]["rect"]:
				Taps.activate(z)
		"tapany":
			Taps.send(&"use")

static func _dirs(v: Vector2, dead: float) -> Array:
	var out := []
	if v.length() <= dead:
		return out
	var n := v.normalized()
	if n.x < -DIAG: out.append(&"left")
	if n.x > DIAG: out.append(&"right")
	if n.y < -DIAG: out.append(&"up")
	if n.y > DIAG: out.append(&"down")
	return out

## Recomputes which actions the current touches hold and sends the changes.
func _sync() -> void:
	var want := {}
	var has_stick := false
	knob = Vector2.ZERO
	for t in _touches.values():
		match t["kind"]:
			"button":
				want[t["action"]] = true
			"aim":
				for d in _dirs(t["pos"] - aim_center, 3.0):
					want[StringName("aim_" + d)] = true
			"stick":
				has_stick = true
				var v: Vector2 = t["pos"] - stick_center
				knob = v.limit_length(stick_r)
				for d in _dirs(v, stick_r * 0.3):
					want[StringName("move_" + d)] = true
	if not has_stick:
		stick_center = stick_home
	for a in _held.keys():
		if not want.has(a):
			_send(a, false)
			_held.erase(a)
	for a in want:
		if not _held.has(a):
			_send(a, true)
			_held[a] = true
	queue_redraw()

func _send(action: StringName, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	e.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(e)

# ---------- Drawing (game pixels, pixel-art style) ----------
func _draw() -> void:
	var ring := TB.c("#f4ecd8")
	var fill := TB.c("#1a1423")
	var hot := TB.c("#f2c94c")
	# Menus are tapped directly, so the controls fade back there.
	var dim := 1.0 if G.state == &"play" else 0.35
	# Stick
	var a := stick_opacity * dim
	draw_circle(stick_center, stick_r, Color(fill.r, fill.g, fill.b, 0.45 * a), true, -1.0, false)
	draw_arc(stick_center, stick_r, 0, TAU, 32, Color(ring.r, ring.g, ring.b, 0.6 * a), 1.0, false)
	var kc := hot if knob != Vector2.ZERO else ring
	draw_circle(stick_center + knob, stick_r * 0.42, Color(kc.r, kc.g, kc.b, 0.55 * a), true, -1.0, false)
	# Buttons
	for b in buttons:
		var held: bool = _held.has(b["action"])
		var op: float = b["opacity"] * dim
		var c: Color = hot if held else ring
		var pos: Vector2 = b["pos"].round()
		var r: float = b["r"]
		draw_circle(pos, r, Color(fill.r, fill.g, fill.b, (0.75 if held else 0.45) * op), true, -1.0, false)
		draw_arc(pos, r, 0, TAU, 24, Color(c.r, c.g, c.b, 0.8 * op), 1.0, false)
		if b["action"] in AIM_ACTIONS:
			_arrow(pos, b["action"], r * 0.45, Color(c.r, c.g, c.b, 0.9 * op))
		else:
			Gfx.text(self, b["label"], pos.x, pos.y - 2, "gold" if held else "white", 1, 0.5, true, op)

func _arrow(pos: Vector2, action: StringName, s: float, col: Color) -> void:
	var dir: Vector2 = { &"aim_up": Vector2.UP, &"aim_down": Vector2.DOWN, &"aim_left": Vector2.LEFT,
		&"aim_right": Vector2.RIGHT }[action]
	var side := Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array([pos + dir * s, pos - dir * s * 0.6 + side * s, pos - dir * s * 0.6 - side * s])
	draw_colored_polygon(pts, col)
