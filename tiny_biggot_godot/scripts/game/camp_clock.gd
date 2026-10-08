class_name CampClock
extends RefCounted
## 21.6 THE CAMP FOLLOWS THE IPAD'S CLOCK (his word, 8 Oct: "make game more alive").
##   morning (5-10)   songbirds land and peck about (RoomDress's birds, in colour); a warm haze;
##                    birdsong by the fire instead of crickets (Ambience: "campday")
##   day (11-16)      the camp as it always was, with birdsong
##   evening (17-20)  a dusky light; the lanterns are lit; the first fireflies
##   night (21-4)     dark blue; the lanterns and the fire glow; fireflies; stars and the moon in the pond
##   the cat          once a day (the iPad's date), when Soot is about, a small gift lies by the cat:
##                    a fish for the larder, or embers (a shiny button, a lost ring, a feather, a mouse)
## All of it is drawing with dice of its own, apart from the gift. --clock=H sets the hour.

const LANTERNS := [Vector2(196, 112), Vector2(236, 236), Vector2(40, 196), Vector2(418, 150), Vector2(330, 100)]
const POND := Vector2(92, 222)   # Camp: Fishing.place(r, 92, 222, 52, 20 ...)
const POND_R := Vector2(42, 14)
const FIREFLIES := 16
const GIFTS := [["A FISH", "fish", 0], ["A SHINY BUTTON", "embers", 8], ["A LOST RING", "embers", 15], ["A FEATHER", "embers", 5],
	["A MOUSE", "embers", 3]]
const GIFT_FISH := ["mudfin", "bonecarp", "glimmer", "crypteel"]

static var force_hour := -1   # tests
static var _rng := RandomNumberGenerator.new()
static var _flies: Array = []
static var _stars: Array = []

static func hour() -> int:
	if force_hour >= 0:
		return force_hour
	if DebugArgs.has("clock"):
		return clampi(DebugArgs.get_int("clock"), 0, 23)
	return int(Time.get_time_dict_from_system()["hour"])

static func phase() -> String:
	var h := hour()
	if h >= 5 and h < 11:
		return "morning"
	if h >= 11 and h < 17:
		return "day"
	if h >= 17 and h < 21:
		return "evening"
	return "night"

static func on() -> bool:
	return Camp.active() and not Meta.opts.get("neon", false)

static func dark() -> bool:
	return phase() in ["evening", "night"]

## RoomDress.tick: songbirds come down in the morning.
static func birds() -> bool:
	return on() and phase() == "morning"

## The camp's own sound: crickets after dark, birdsong by day (Ambience.here).
static func loop() -> String:
	return "camp" if dark() else "campday"

## Camp.enter: the banner's second line.
static func greeting() -> String:
	match phase():
		"morning":
			return "GOOD MORNING. THE BIRDS WERE UP BEFORE YOU"
		"evening":
			return "THE LANTERNS ARE LIT. REST A WHILE"
		"night":
			return "A QUIET NIGHT. THE FIREFLIES ARE OUT"
	return "REST, LOOK AROUND, AND SET OUT WHEN YOU ARE READY"

# ---------- The cat's gift ----------
static func _today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]

## Camp.enter (after the camp is set up): a gift by the cat, once a day.
static func on_enter(room: Room) -> void:
	_flies.clear()
	_stars.clear()
	if birds():
		RoomDress._land_t = 1.0   # the first songbird comes down a moment after you arrive
	if not GameData.rogues() or Meta.meta.get("cat_gift", "") == _today():
		return
	var cat: Dictionary = {}
	for o in room.objects:
		if o["kind"] == "v_cat":
			cat = o
	if cat.is_empty():
		return
	_rng.seed = hash(_today())
	var g: Array = GIFTS[_rng.randi() % GIFTS.size()]
	var o := { "kind": "c_gift", "x": cat["x"] + 14.0, "y": cat["y"] + 6.0, "name": g[0], "what": g[1], "n": g[2] }
	if g[1] == "fish":
		o["fish"] = GIFT_FISH[_rng.randi() % GIFT_FISH.size()]
	room.objects.append(o)

static func take(o: Dictionary) -> void:
	o["gone"] = true
	Meta.meta["cat_gift"] = _today()
	if o["what"] == "fish":
		CampLife.stock(o["fish"])
		G.toast("%s BROUGHT YOU A %s FOR THE LARDER" % [CampLife.CAT_NAME, Fishing.FISH[o["fish"]][0]], "cyan")
	else:
		Meta.meta["embers"] = int(Meta.meta.get("embers", 0)) + int(o["n"])
		G.toast("%s BROUGHT YOU %s: %d EMBERS" % [CampLife.CAT_NAME, o["name"], o["n"]], "orange")
	Snd.play("coin")
	Meta.write_save()
	for c in G.room.objects:
		if c["kind"] == "v_cat":
			Barks.say(c, "MRRP.", "tan")

static func prompt(o: Dictionary) -> Array:
	var what: String = "FOR THE LARDER" if o["what"] == "fish" else "%d EMBERS" % o["n"]
	return ["A GIFT FROM " + CampLife.CAT_NAME, "%s: %s" % [o["name"], what], "TAKE IT"]

static func draw_gift(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x := roundf(o["x"])
	var y := roundf(o["y"])
	ci.draw_rect(Rect2(x - 5, y + 2, 10, 2), Color(0, 0, 0, 0.3))
	match o["what"]:
		"fish":
			var c := TB.c(Fishing.FISH[o["fish"]][1])
			ci.draw_rect(Rect2(x - 4, y - 2, 7, 3), c)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 3, y - 1), Vector2(x + 6, y - 3), Vector2(x + 6, y + 2)]), c.darkened(0.2))
			ci.draw_rect(Rect2(x - 3, y - 2, 1, 1), Color(0.05, 0.05, 0.08))
		_:
			match o["name"]:
				"A SHINY BUTTON":
					ci.draw_circle(Vector2(x, y), 2.5, TB.c("#f2c94c"))
					ci.draw_rect(Rect2(x - 1, y - 1, 1, 1), TB.c("#7a5236"))
					ci.draw_rect(Rect2(x + 1, y, 1, 1), TB.c("#7a5236"))
				"A LOST RING":
					ci.draw_circle(Vector2(x, y), 2.5, TB.c("#f2c94c"), false, 1.0)
					ci.draw_rect(Rect2(x - 1, y - 4, 2, 2), TB.c("#6fd3e0"))
				"A FEATHER":
					ci.draw_line(Vector2(x - 4, y + 1), Vector2(x + 4, y - 2), TB.c("#f4ecd8"), 1.0)
					ci.draw_line(Vector2(x - 2, y + 1), Vector2(x + 3, y - 1), TB.c("#d8443c"), 1.0)
				_:
					ci.draw_rect(Rect2(x - 3, y - 2, 6, 3), TB.c("#8b8f9c"))
					ci.draw_rect(Rect2(x + 3, y - 2, 2, 2), TB.c("#8b8f9c"))
					ci.draw_line(Vector2(x - 3, y), Vector2(x - 7, y + 1), TB.c("#e86fb4"), 1.0)
	if floori(t * 3.0) % 3 == 0:
		Gfx.px(ci, TB.c("#fffbe0"), x + 3, y - 5, 1)

# ---------- Drawing ----------
## world_view lower layer: lantern posts, fireflies, stars and the moon in the pond.
static func paint_lower(ci: CanvasItem, t: float) -> void:
	if not on():
		return
	var ph := phase()
	var lit := ph in ["evening", "night"]
	for l: Vector2 in LANTERNS:
		ci.draw_rect(Rect2(l.x - 4, l.y + 1, 9, 2), Color(0, 0, 0, 0.25))
		ci.draw_rect(Rect2(l.x - 1, l.y - 16, 2, 18), TB.c("#5a3a22"))
		ci.draw_rect(Rect2(l.x - 1, l.y - 16, 5, 1), TB.c("#5a3a22"))
		var sw := roundf(sin(t * 1.3 + l.x) * 0.6)
		ci.draw_rect(Rect2(l.x + 2 + sw, l.y - 14, 3, 4), TB.c("#f2c94c") if lit else TB.c("#4e4a5e"))
		ci.draw_rect(Rect2(l.x + 2 + sw, l.y - 15, 3, 1), TB.c("#2a2838"))
	if ph == "night":
		if _stars.is_empty():
			_rng.seed = 2106
			for i in 14:
				var a := _rng.randf() * TAU
				var r := sqrt(_rng.randf()) * 0.85
				_stars.append(Vector2(POND.x + cos(a) * POND_R.x * r, POND.y + sin(a) * POND_R.y * r))
		for i in _stars.size():
			var s: Vector2 = _stars[i]
			var tw := 0.45 + 0.4 * sin(t * (1.5 + (i % 4) * 0.7) + i)
			Gfx.px(ci, Color(0.95, 0.97, 1.0, tw), s.x, s.y, 1)
		var m := POND + Vector2(18, -4)
		ci.draw_circle(m, 4.0, Color(0.92, 0.94, 0.85, 0.55))
		ci.draw_circle(m + Vector2(1.5, -1.0), 3.2, Color(0.12, 0.2, 0.32, 0.5))   # a crescent
		ci.draw_line(m + Vector2(-6, 6), m + Vector2(6, 6), Color(0.9, 0.95, 1.0, 0.18 + 0.1 * sin(t * 2.0)), 1.0)
	if lit:
		_flies_tick(ph, t)
		for f in _flies:
			var a: float = f["a"]
			if a > 0.05:
				Gfx.px(ci, Color(0.85, 1.0, 0.45, a), f["x"], f["y"], 1)

static func _flies_tick(ph: String, t: float) -> void:
	var want := FIREFLIES if ph == "night" else FIREFLIES / 3
	if _flies.size() != want:
		_flies.clear()
		_rng.seed = 2107
		for i in want:
			_flies.append({ "x0": _rng.randf_range(30, 420), "y0": _rng.randf_range(70, 262), "p": _rng.randf() * TAU,
				"s": _rng.randf_range(0.25, 0.6), "x": 0.0, "y": 0.0, "a": 0.0 })
	for f in _flies:
		var p: float = f["p"] + t * f["s"]
		f["x"] = f["x0"] + sin(p * 1.3) * 18.0 + sin(p * 0.37) * 10.0
		f["y"] = f["y0"] + cos(p * 0.9) * 10.0
		f["a"] = clampf(sin(t * 2.2 + f["p"] * 3.0) * 1.4 - 0.2, 0.0, 1.0)

## world_view fx layer (over the ground and the people, under the lights and the words): the light.
static func paint_tint(ci: CanvasItem) -> void:
	if not on():
		return
	var c := Color(0, 0, 0, 0)
	match phase():
		"morning":
			c = Color(1.0, 0.82, 0.55, 0.07)
		"evening":
			c = Color(0.42, 0.18, 0.34, 0.2)
		"night":
			c = Color(0.03, 0.05, 0.18, 0.45)
	if c.a > 0.0:
		ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), c)

## world_view glow layer (additive): lanterns, a brighter fire after dark, fireflies.
static func paint_glow(ci: CanvasItem, t: float) -> void:
	if not on() or not dark():
		return
	for l: Vector2 in LANTERNS:
		var op := (150.0 + sin(t * 7.0 + l.x) * 12.0) / 255.0
		Gfx.at(ci, "glow_torch", l.x + 3 - 36, l.y - 12 - 36, op)
	for o in G.room.objects:
		if o["kind"] == "c_cook":
			Gfx.at(ci, "glow_torch", o["x"] - 36, o["y"] - 40, (200.0 + sin(t * 9.0) * 20.0) / 255.0)
	for f in _flies:
		if f["a"] > 0.3:
			Gfx.at(ci, "glow_small", f["x"] - 12, f["y"] - 12, f["a"] * 0.45)
