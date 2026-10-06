class_name StarView
extends Node2D
## The constellation screen (G.state == &"stars"; rules in scripts/game/stars.gd).
##   touch: tap a star to read it, tap it again to take it, hold it to give it back,
##          drag to look around, pinch to zoom; the buttons go back and reset
##   mouse: left click as a tap, right click gives back, drag pans, the wheel zooms
##   keys:  the arrows step to the nearest star that way, USE takes, ROLL gives back,
##          hold BOMB to reset everything, MENU goes back

const ZMIN := 0.55
const ZMAX := 2.0
const HOLD := 0.55            # seconds of holding a star to give it back
const RESET_HOLD := 1.0
const BACK_RECT := Rect2(TB.SW - 26, 6, 20, 16)
const RESET_RECT := Rect2(TB.SW - 76, 6, 46, 16)

static var cam := Vector2.ZERO
static var zoom := 1.0
static var sel := 0
static var _touch := {}        # index -> { start, pos, t }
static var _pinch := 0.0
static var _hold_t := 0.0
static var _reset_t := 0.0
static var _msg := ""
static var _msg_t := 0.0

static func open() -> void:
	Stars.nodes()
	G.state = &"stars"
	sel = 0
	cam = Vector2.ZERO
	zoom = 1.0
	_touch.clear()

static func close() -> void:
	G.state = &"title"
	G.menu = G.title_index("CONSTELLATION")
	Snd.play("select")

static func to_screen(v: Vector2) -> Vector2:
	return Vector2(TB.SW / 2.0, TB.SH / 2.0 + 6) + (v - cam) * zoom

static func to_web(s: Vector2) -> Vector2:
	return (s - Vector2(TB.SW / 2.0, TB.SH / 2.0 + 6)) / zoom + cam

static func radius(n: Dictionary) -> float:
	return (14.0 if n["id"] == "heart" else (11.0 if n["notable"] else 7.5)) * zoom

static func pick(s: Vector2) -> int:
	var best := -1
	var bd := 1e9
	var nodes := Stars.nodes()
	for i in nodes.size():
		var d := to_screen(nodes[i]["pos"]).distance_to(s)
		if d < maxf(radius(nodes[i]) + 4.0, 10.0) and d < bd:
			bd = d
			best = i
	return best

static func _say(s: String) -> void:
	_msg = s
	_msg_t = 1.6

static func tap(i: int) -> void:
	if i < 0:
		return
	if sel != i:
		sel = i
		Snd.play("select")
		return
	if Stars.take(i):
		Snd.play("unlock")
	elif Stars.is_taken(i):
		Snd.play("deny")
	elif Stars.spent() >= Stars.points():
		_say("NO POINTS LEFT")
		Snd.play("deny")
	else:
		_say("TAKE A STAR NEXT TO IT FIRST")
		Snd.play("deny")

static func give_back(i: int) -> void:
	if i < 0:
		return
	if Stars.give_back(i):
		Snd.play("confirm")
		_say("GIVEN BACK")
	elif Stars.is_taken(i) and i != 0:
		_say("OTHER STARS HANG OFF THIS ONE")
		Snd.play("deny")

# ---------- Keys (G.update while in this screen) ----------
static func keys(dt: float) -> void:
	_msg_t = maxf(0.0, _msg_t - dt)
	if Keys.back():
		close()
		return
	var want := Vector2.ZERO
	if Keys.left(): want = Vector2.LEFT
	elif Keys.right(): want = Vector2.RIGHT
	elif Keys.up(): want = Vector2.UP
	elif Keys.down(): want = Vector2.DOWN
	if want != Vector2.ZERO:
		var nodes := Stars.nodes()
		var here: Vector2 = nodes[sel]["pos"]
		var best := -1
		var bd := 1e9
		for i in nodes.size():
			var dv: Vector2 = nodes[i]["pos"] - here
			if i == sel or dv.length() < 1.0 or dv.normalized().dot(want) < 0.5:
				continue
			var score := dv.length() * (2.0 - dv.normalized().dot(want))
			if score < bd:
				bd = score
				best = i
		if best >= 0:
			sel = best
			Snd.play("select")
	if Keys.confirm():
		tap(sel)
	if Keys.roll():
		give_back(sel)
	if Keys.pressed(&"bomb"):
		_reset_t += dt
		if _reset_t >= RESET_HOLD:
			_reset_t = -99.0
			Stars.reset()
			Snd.play("boom")
			_say("EVERY STAR GIVEN BACK")
	else:
		_reset_t = 0.0
	# The view drifts to keep the chosen star in sight.
	var sp := to_screen(Stars.nodes()[sel]["pos"])
	if sp.x < 40 or sp.x > TB.SW - 40 or sp.y < 40 or sp.y > TB.SH - 40:
		cam = cam.lerp(Stars.nodes()[sel]["pos"], minf(1.0, dt * 6.0))
	if not _touch.is_empty():
		for k in _touch:
			_touch[k]["t"] += dt
		if _touch.size() == 1:
			var t: Dictionary = _touch.values()[0]
			if t["pos"].distance_to(t["start"]) < 6 and t["t"] >= HOLD and not t.get("held", false):
				t["held"] = true
				if RESET_RECT.has_point(t["start"]):
					Stars.reset()
					Snd.play("boom")
					_say("EVERY STAR GIVEN BACK")
				else:
					give_back(pick(t["start"]))

# ---------- Touch (forwarded by TouchControls) and mouse ----------
static func touch(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch[event.index] = { "start": event.position, "pos": event.position, "t": 0.0 }
			if _touch.size() == 2:
				var ps: Array = _touch.values()
				_pinch = ps[0]["pos"].distance_to(ps[1]["pos"])
		else:
			var t = _touch.get(event.index)
			_touch.erase(event.index)
			if t != null and t["pos"].distance_to(t["start"]) < 6 and not t.get("held", false) and _touch.is_empty():
				_release_tap(event.position)
	elif event is InputEventScreenDrag:
		if not _touch.has(event.index):
			return
		var prev: Vector2 = _touch[event.index]["pos"]
		_touch[event.index]["pos"] = event.position
		if _touch.size() == 1:
			cam -= (event.position - prev) / zoom
		elif _touch.size() == 2:
			var ps: Array = _touch.values()
			var d: float = ps[0]["pos"].distance_to(ps[1]["pos"])
			if _pinch > 1.0:
				zoom = clampf(zoom * d / _pinch, ZMIN, ZMAX)
			_pinch = d

static func _release_tap(pos: Vector2) -> void:
	if BACK_RECT.has_point(pos):
		close()
		return
	if RESET_RECT.has_point(pos):
		_say("HOLD TO RESET")
		return
	tap(pick(pos))

func _input(event: InputEvent) -> void:
	if G.state != &"stars":
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom = clampf(zoom * 1.12, ZMIN, ZMAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom = clampf(zoom / 1.12, ZMIN, ZMAX)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			give_back(pick(event.position))
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var ev := InputEventScreenTouch.new()
			ev.index = 99
			ev.pressed = event.pressed
			ev.position = event.position
			touch(ev)
	elif event is InputEventMouseMotion and _touch.has(99):
		var ev := InputEventScreenDrag.new()
		ev.index = 99
		ev.position = event.position
		touch(ev)

# ---------- Drawing ----------
func _process(_delta: float) -> void:
	visible = G.state == &"stars"
	if visible:
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, TB.SW, TB.SH), TB.c("#05050a"))
	var nodes := Stars.nodes()
	var t := G.time
	# Faint region names.
	for side in Stars.NAME:
		var dv: Vector2 = Stars.DIRS[side]
		var sp := to_screen(dv * Stars.STEP * (8.6 if side.length() == 2 else 4.5) + (Vector2.ZERO if side.length() == 2 else Vector2(dv.y, dv.x) * Stars.STEP * 1.2))
		Gfx.text(self, Stars.NAME[side], sp.x, sp.y, "dim", 1, 0.5)
	# Links.
	for i in nodes.size():
		for j in nodes[i]["links"]:
			if j < i:
				continue
			var a := to_screen(nodes[i]["pos"])
			var b := to_screen(nodes[j]["pos"])
			if not Rect2(-40, -40, TB.SW + 80, TB.SH + 80).has_point(a) and not Rect2(-40, -40, TB.SW + 80, TB.SH + 80).has_point(b):
				continue
			var lit := Stars.is_taken(i) and Stars.is_taken(j)
			draw_line(a, b, TB.c("#f2c94c") if lit else Color(0.75, 0.76, 0.8, 0.55), 2.0 if lit else 1.0)
	# Stars.
	for i in nodes.size():
		var n: Dictionary = nodes[i]
		var c := to_screen(n["pos"])
		if c.x < -20 or c.y < -20 or c.x > TB.SW + 20 or c.y > TB.SH + 20:
			continue
		var r := radius(n)
		var taken := Stars.is_taken(i)
		var ring := "#f2c94c" if taken else ("#f4ecd8" if Stars.can_take(i) else "#5a5770")
		if i == sel:
			for k in 8:
				var a := k * TAU / 8 + t * 0.8
				draw_line(c + Vector2(cos(a), sin(a)) * (r + 3), c + Vector2(cos(a), sin(a)) * (r + 7 + 2 * sin(t * 4 + k)),
					TB.c("#f2c94c" if taken else "#f4ecd8"), 1.0)
		draw_circle(c, r + 1.0, TB.c("#140f1c"))
		draw_circle(c, r, TB.c(ring))
		draw_circle(c, r - 1.5, TB.c("#0c0b12"))
		if taken and i != 0:
			draw_circle(c, r - 1.5, Color(0.95, 0.79, 0.3, 0.18))
		if zoom >= 0.8 or n["notable"] or i == 0:
			var sc := 2.0 if (i == 0 or n["notable"]) and zoom >= 1.0 else 1.0
			Gfx.sp(self, Stars.ICON[n["side"]], c.x, c.y + 5 * sc, sc, sc, 0.0, false, 1.0 if taken or Stars.can_take(i) else 0.45)
		else:
			draw_rect(Rect2(roundf(c.x) - 1, roundf(c.y) - 1, 2, 2), TB.c(ring))
	# The chosen star's card.
	var n2: Dictionary = nodes[sel]
	var title: String = n2["name"] if n2["notable"] or sel == 0 else Stars.NAME[n2["side"]] + " STAR"
	var lines: Array = TraitView.rich_lines(n2["text"], 150)
	var state := "TAKEN" if Stars.is_taken(sel) else ("TAP AGAIN OR USE TO TAKE" if Stars.can_take(sel) else
		("NO POINTS LEFT" if Stars.spent() >= Stars.points() else "TAKE A STAR NEXT TO IT FIRST"))
	var cw := 160.0
	var ch := 26.0 + lines.size() * 8
	var cp := to_screen(n2["pos"]) + Vector2(-cw / 2, -radius(n2) - ch - 8)
	cp.x = clampf(cp.x, 4, TB.SW - cw - 4)
	if cp.y < 26:
		cp.y = to_screen(n2["pos"]).y + radius(n2) + 8
	cp.y = clampf(cp.y, 26, TB.SH - ch - 4)
	Gfx.panel(self, cp.x, cp.y, cw, ch, "#f2c94c" if Stars.is_taken(sel) else "#f4ecd8", "#0c0b12")
	Gfx.text(self, title, cp.x + cw / 2, cp.y + 4, "gold", 1, 0.5)
	for j in lines.size():
		TraitView.draw_line(self, lines[j], cp.x + cw / 2 - TraitView.line_w(lines[j]) / 2.0, cp.y + 14 + j * 8)
	Gfx.text(self, state, cp.x + cw / 2, cp.y + ch - 10, "lime" if Stars.can_take(sel) else "grey", 1, 0.5)
	# The points box, the buttons and the controls.
	Gfx.panel(self, TB.SW / 2 - 44, 6, 88, 16, "#f4ecd8", "#0c0b12")
	Gfx.text(self, "%d/%d POINTS" % [Stars.spent(), Stars.points()], TB.SW / 2, 11, "gold", 1, 0.5)
	Gfx.panel(self, BACK_RECT.position.x, BACK_RECT.position.y, BACK_RECT.size.x, BACK_RECT.size.y, "#f4ecd8", "#0c0b12")
	Gfx.text(self, "<", BACK_RECT.get_center().x, BACK_RECT.position.y + 5, "white", 1, 0.5)
	Gfx.panel(self, RESET_RECT.position.x, RESET_RECT.position.y, RESET_RECT.size.x, RESET_RECT.size.y, "#8b8f9c", "#0c0b12")
	Gfx.text(self, "RESET", RESET_RECT.get_center().x, RESET_RECT.position.y + 5, "grey", 1, 0.5)
	var help := ["TAP: READ, AGAIN: TAKE", "HOLD: GIVE BACK", "DRAG: LOOK, PINCH: ZOOM", "KEYS: ARROWS, USE, ROLL", "HOLD BOMB: RESET  MENU: BACK"]
	Gfx.panel(self, 4, TB.SH - 50, 118, 46, "#8b8f9c", "#0c0b12")
	for k in help.size():
		Gfx.text(self, help[k], 8, TB.SH - 46 + k * 8, "gold" if k == 0 else "white")
	Gfx.text(self, "CONSTELLATION", 6, 8, "gold")
	if _msg_t > 0:
		Gfx.text(self, _msg, TB.SW / 2, TB.SH - 14, "red", 1, 0.5)
