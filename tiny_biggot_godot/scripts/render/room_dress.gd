class_name RoomDress
extends RefCounted
## Stage 16 (his ask, 7 Oct: "revamp all rooms, add new things, make them full and enjoyable").
## Every kind of room gets furnished to suit what it is, in the floor's colours. Expanded game only.
##   TREASURE  THE HOARD: a gold-trimmed rug, heaps of coins, old open chests, gold banners, braziers
##   SHOP      THE STALL: a striped awning, shelves of bottles, a counter, sacks, crates, lanterns
##   SHRINE    a rune circle, a ring of candles, a carpet to the altar, statues, petals, incense
##   VAULT     iron floor plates, gold bars, strongboxes, chains, velvet ropes on brass posts
##   SECRET    cobwebs, dust, bones, old candles, glowing mushrooms, a forgotten crate pile
##   REST      THE CAMP: log seats, a bedroll, a tent, a pot on a tripod, firewood, a lantern
##   BOSS      an arena: a great sigil in the guardian's colour, braziers, chains, banners
##   START     a runner from the door, two braziers
##   MYSTERY   lanterns in the corners, barrels
##   Chapter II and III floors get ink, paper and letters on their floors.
## What sits still is drawn once into the room's background (paint_static: no cost per frame);
## flames, sparkles, incense and the little animals (rats, moths, butterflies: they flee from
## you) move in paint_live, with their own random numbers (the game's are never drawn here).
## Interactive (EventRooms kinds, rules: expanded game): POTS (e_pot) along the walls of many rooms
## shatter when shot or rolled into and sometimes hold coins, a gem or a heart; COIN HEAPS (e_coins)
## in treasure rooms pay a few coins when you walk through them; POWDER KEGS (e_keg) in some fights
## blow up when shot, hurting every foe near them (never you), and set off kegs beside them.

const CX := 224.0
const CY := 152.0
## Places on the top wall that the HUD (hearts and stats on the left, the minimap on the right,
## the floor's name in the middle) leaves in view.
const WALL_SPOTS := [128.0, 168.0, 280.0, 320.0]

static var _flames: Array = []     # [x, y, size]
static var _glints: Array = []     # [x, y]
static var _smoke: Array = []      # [x, y]
static var _lights: Array = []     # [x, y, strength]
static var _critters: Array = []   # { kind, x, y, vx, vy, t, flee }
static var _room: WeakRef = null
static var _rng := RandomNumberGenerator.new()

static func on(room: Room) -> bool:
	return GameData.rogues() and room != null and room.type != "barn" and not Meta.opts.get("neon", false)

static func _accent() -> Color:
	var f: Dictionary = GameData.floors()[clampi(G.floor_index, 0, GameData.floors().size() - 1)]
	return TB.c(f.get("accent_hex", "#e8873a"))

# ---------- Interactive bits (placed by game.gd setup_objects; rules) ----------
## Where they go is rolled from the room's own seed, so furnishing a room never shifts the run's
## random numbers (what a broken pot drops is rolled when it breaks, from the run's).
static func _place_rng(r: Room, salt: int) -> RandomNumberGenerator:
	var g := RandomNumberGenerator.new()
	g.seed = r.seed_value ^ salt
	return g

## Called by setup_objects for every room of the expanded game.
static func furnish(r: Room) -> void:
	if not r.theme.is_empty():
		return
	var g := _place_rng(r, 0x51a7)
	if r.type in ["combat", "elite"]:
		if g.randf() < 0.6:
			place_pots(r, 2 + g.randi() % 3)
		if g.randf() < 0.35 or Daily.is_on("powder"):
			place_kegs(r, 3 if Daily.is_on("powder") else 0)   # 18.1 POWDER DAY: kegs everywhere
	elif r.type in ["treasure", "rest", "shrine", "secret", "vault", "mystery"]:
		place_pots(r, 2 + g.randi() % 2)
	if r.type == "treasure":
		place_coins(r)
	if r.type in ["combat", "elite", "treasure", "rest", "shrine"]:
		place_props(r)   # 21.2: last, so nothing with rules moves for them

## 21.2: things that can be knocked over (drawing only): standing candelabra, and free-standing
## bookcases in the library (Chapter IV). Rolled from the room's own seed.
static func place_props(r: Room) -> void:
	var g := _place_rng(r, 0x2b1d)
	var lib := library() >= 0
	var n := (1 + g.randi() % 2) if (lib or g.randf() < 0.6) else 0
	for tries in 24:
		if n <= 0:
			break
		var side := g.randi() % 2
		var x := g.randf_range(52, 396)
		var y := g.randf_range(60, 76) if side == 0 else g.randf_range(222, 240)
		if absf(x - CX) < 50 or World.hits_solid(r, x, y, 8, World.M_PLAYER):
			continue
		var clash := false
		for o in r.objects:
			if TB.dist_xy(x, y, o["x"], o["y"]) < 26:
				clash = true
		if clash:
			continue
		r.objects.append({ "kind": "e_shelf" if lib else "e_candle", "x": x, "y": y, "used": true, "seed": g.randi() })
		n -= 1

## 21.2: something knocks a prop over (a roll, a shot, a blast). from_x: where the push came from.
static func knock(o: Dictionary, from_x: float) -> void:
	if o.get("down", false):
		return
	o["down"] = true
	o["dir"] = 1.0 if o["x"] >= from_x else -1.0
	if o["kind"] == "e_candle":
		Lives.lamp_down(o["x"], o["y"])   # 21.5: the moths round it come for you
	G.dyn_dirty = true
	Snd.play("hit", true)   # (its own dice: a prop is only drawn)
	for k in 10:
		var a := _rng.randf() * TAU
		var col: String = (["#d9d0b4", "#8b8f9c", "#f4ecd8"] if o["kind"] == "e_candle" else ["#c8a878", "#d8443c", "#4d6aa8", "#f2c94c"])[k % (3 if o["kind"] == "e_candle" else 4)]
		Fx.particle(o["x"], o["y"] - 10, cos(a) * _rng.randf_range(20, 60), sin(a) * _rng.randf_range(20, 60) - 20, 0.5, col, 1)

## 21.2: a blast or a loud thing at (x, y): props near it fall, critters near it bolt.
static func scare(x: float, y: float, r: float) -> void:
	if G.room == null or not on(G.room):
		return
	for o in G.room.objects:
		if o["kind"] in ["e_candle", "e_shelf"] and TB.dist_xy(x, y, o["x"], o["y"]) < r + 12:
			knock(o, x)
	for c in _critters:
		if TB.dist_xy(x, y, c["x"], c["y"]) < 140.0:
			_startle(c, x, y)

static func _startle(c: Dictionary, x: float, y: float) -> void:
	var away := Vector2(c["x"] - x, c["y"] - y).normalized()
	if c["kind"] == "bird":
		if c.get("fly", false):
			return
		c["fly"] = true
		c["vx"] = (70.0 if away.x >= 0 else -70.0) * _rng.randf_range(0.8, 1.2)
		c["vy"] = -95.0
		return
	var sp := 110.0 if c["kind"] == "rat" else 60.0
	c["vx"] = away.x * sp
	c["vy"] = away.y * sp
	c["t"] = 0.8

## Pots along the walls, away from the doors and anything solid.
static func place_pots(r: Room, n: int) -> void:
	var g := _place_rng(r, 0x9071)
	var tries := 0
	var placed := 0
	while placed < n and tries < 40:
		tries += 1
		var side := g.randi() % 4
		var x := 0.0
		var y := 0.0
		match side:
			0:
				x = g.randf_range(28, 420)
				y = g.randf_range(42, 52)
			1:
				x = g.randf_range(28, 420)
				y = g.randf_range(250, 260)
			2:
				x = g.randf_range(26, 36)
				y = g.randf_range(46, 256)
			_:
				x = g.randf_range(412, 422)
				y = g.randf_range(46, 256)
		if absf(x - CX) < 44 or (absf(y - CY) < 40 and (x < 60 or x > 388)):
			continue   # clear of the doors
		if World.hits_solid(r, x, y, 8, World.M_PLAYER):
			continue
		var clash := false
		for o in r.objects:
			if TB.dist_xy(x, y, o["x"], o["y"]) < 22:
				clash = true
		if clash:
			continue
		r.objects.append({ "kind": "e_pot", "x": x, "y": y, "used": true, "style": g.randi() % 3 })
		placed += 1

## One or two powder kegs out in a fight room, away from the doors and the middle.
static func place_kegs(r: Room, want: int = 0) -> void:
	var g := _place_rng(r, 0x6e9)
	var n := 1 + (1 if g.randf() < 0.4 else 0)
	if want > 0:
		n = want
	for tries in 30:
		if n <= 0:
			break
		var x := g.randf_range(60, 388)
		var y := g.randf_range(64, 240)
		if TB.dist_xy(x, y, CX, CY) < 50 or absf(x - CX) < 40 and (y < 80 or y > 224) or World.hits_solid(r, x, y, 9, World.M_PLAYER):
			continue
		var clash := false
		for o in r.objects:
			if TB.dist_xy(x, y, o["x"], o["y"]) < 30:
				clash = true
		if clash:
			continue
		r.objects.append({ "kind": "e_keg", "x": x, "y": y, "used": true })
		n -= 1

static func place_coins(r: Room) -> void:
	var g := _place_rng(r, 0xc01)
	for spot in [Vector2(70, 70), Vector2(378, 70), Vector2(66, 236), Vector2(382, 236)]:
		if g.randf() < 0.75:
			r.objects.append({ "kind": "e_coins", "x": spot.x + g.randf_range(-6, 6), "y": spot.y + g.randf_range(-4, 4), "used": true, "n": 2 + g.randi() % 4 })

## Every play tick (EventRooms.update): shots and rolls break pots; walking through a coin heap pays.
static func tick_objects(room: Room) -> void:
	var p := G.player
	for o in room.objects:
		if o.get("gone", false):
			continue
		match o["kind"]:
			"e_pot":
				var hit := p.dodge_t > 0 and TB.dist_xy(p.x, p.y, o["x"], o["y"]) < 14
				if not hit:
					for b in G.pbullets:
						if absf(b.x - o["x"]) < 7 and absf(b.y - o["y"] + 4) < 8:
							hit = true
							break
				if not hit:
					hit = _foe_shot_near(o["x"], o["y"] - 4, 6.0)   # 17.3: foes' shots break pots too
				if hit:
					_break_pot(o)
			"e_keg":
				# 17.3: a hit lights the fuse (your shots or a foe's); foes near it run; then it blows.
				if o.has("fuse"):
					o["fuse"] -= TB.DT
					for e in G.enemies:
						if e.hp > 0 and not e.is_boss() and TB.dist_xy(e.x, e.y, o["x"], o["y"]) < 70:
							var away := Vector2(e.x - o["x"], e.y - o["y"]).normalized()
							e.kx += away.x * 9.0
							e.ky += away.y * 9.0
					if o["fuse"] <= 0:
						_blow(room, o)
					continue
				var lit := false
				for b in G.pbullets:
					if absf(b.x - o["x"]) < 7 and absf(b.y - o["y"] + 5) < 9:
						lit = true
						break
				if not lit:
					lit = _foe_shot_near(o["x"], o["y"] - 5, 7.0)
				if lit:
					o["fuse"] = FUSE
					Snd.play("charge")
			"e_candle", "e_shelf":   # 21.2: a roll, your shots or a foe's knock it over
				if o.get("down", false):
					continue
				var knocked := p.dodge_t > 0 and TB.dist_xy(p.x, p.y, o["x"], o["y"]) < 14
				var from_x: float = p.x
				if not knocked:
					for b in G.pbullets:
						if absf(b.x - o["x"]) < 6 and absf(b.y - o["y"] + 9) < 10:
							knocked = true
							from_x = b.x - b.vx
							break
				if not knocked:
					knocked = _foe_shot_near(o["x"], o["y"] - 9, 7.0)
				if knocked:
					knock(o, from_x)
			"e_coins":
				if TB.dist_xy(p.x, p.y, o["x"], o["y"]) < 12:
					o["gone"] = true
					G.dyn_dirty = true
					for i in o["n"]:
						Combat.drop_pickup("coin", o["x"], o["y"])
					Snd.play("coin")
					Fx.burst(o["x"], o["y"], ["#f2c94c", "#fff07a"], 10, 40)

const FUSE := 0.6   # 17.3: seconds between a keg being hit and its blast

## True when a foe's shot is within d of (x, y).
static func _foe_shot_near(x: float, y: float, d: float) -> bool:
	for i in EBullets.n:
		if EBullets.blife[i] > 0 and absf(EBullets.bx[i] - x) < d and absf(EBullets.by[i] - y) < d:
			EBullets.blife[i] = 0.0
			return true
	return false

static func _blow(room: Room, o: Dictionary) -> void:
	if o.get("gone", false):
		return
	o["gone"] = true
	G.dyn_dirty = true
	var dmg := maxf(30.0, Weapons.wdmg(G.player) * 4.0) * (2.0 if Daily.is_on("powder") else 1.0)
	Combat.explode_at(o["x"], o["y"] - 4, dmg, null, 46, "#e8873a", true)
	G.add_shake(6)
	Snd.play("boom")
	# 17.3: the blast throws foes back and smashes the crates round it.
	for e in G.enemies:
		if e.hp > 0 and not e.is_boss():
			var d := TB.dist_xy(e.x, e.y, o["x"], o["y"])
			if d < 60 and d > 1:
				e.kx += (e.x - o["x"]) / d * 220.0
				e.ky += (e.y - o["y"]) / d * 220.0
	var c0 := int(o["x"] / TB.TS)
	var r0 := int(o["y"] / TB.TS)
	for dc in range(-3, 4):
		for dr in range(-3, 4):
			var cc := c0 + dc
			var rr := r0 + dr
			if TB.dist_xy(cc * TB.TS + 8.0, rr * TB.TS + 8.0, o["x"], o["y"]) < 46:
				Combat.hit_crate(room, cc, rr, 999.0)
	for o2 in room.objects:
		if o2["kind"] == "e_keg" and not o2.get("gone", false) and not o2.has("fuse") and TB.dist_xy(o["x"], o["y"], o2["x"], o2["y"]) < 56:
			o2["fuse"] = 0.15   # kegs set each other off

static func draw_keg(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x: float = roundf(o["x"])
	var y: float = roundf(o["y"])
	ci.draw_rect(Rect2(x - 6, y, 12, 3), Color(0, 0, 0, 0.35))
	ci.draw_rect(Rect2(x - 6, y - 13, 12, 13), TB.c("#8a2a1a"))
	ci.draw_rect(Rect2(x - 5, y - 13, 10, 13), TB.c("#b83a24"))
	ci.draw_rect(Rect2(x - 4, y - 12, 2, 11), TB.c("#d8644a"))
	for yy in [y - 11, y - 3]:
		ci.draw_rect(Rect2(x - 6, yy, 12, 2), TB.c("#4e4a5e"))
	ci.draw_rect(Rect2(x - 3, y - 8, 6, 4), TB.c("#f2c94c"))
	ci.draw_rect(Rect2(x - 1, y - 8, 2, 3), TB.c("#1a1423"))   # a warning mark
	ci.draw_line(Vector2(x + 2, y - 13), Vector2(x + 4, y - 17), TB.c("#c8a878"), 1.0)   # the fuse

static func draw_fuse(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x := roundf(o["x"])
	var y := roundf(o["y"])
	if o.has("fuse"):
		# Lit: it flashes, sparks fly, a ring shows how far the blast will reach.
		var k: float = clampf(o["fuse"] / FUSE, 0.0, 1.0)
		if fmod(t * 20.0, 1.0) < 0.5:
			ci.draw_rect(Rect2(x - 6, y - 13, 12, 13), Color(1, 1, 1, 0.55))
		ci.draw_arc(Vector2(x, y - 4), 46.0, 0, TAU, 32, Color(1.0, 0.4, 0.2, 0.6 * (1.0 - k)), 1.0)
		for j in 3:
			ci.draw_rect(Rect2(x + 4 + sin(t * 40 + j) * 3, y - 18 - j * 2 + cos(t * 33 + j) * 2, 1, 1), TB.c("#fff07a"))
		return
	if fmod(t * 3.0 + x * 0.1, 1.0) < 0.5:
		ci.draw_rect(Rect2(x + 4, y - 18, 1, 1), TB.c("#fff07a"))

static func _break_pot(o: Dictionary) -> void:
	o["gone"] = true
	G.dyn_dirty = true
	Snd.play("hit")
	Fx.burst(o["x"], o["y"] - 4, ["#a8705a", "#7a5236", "#d9b48a"] if o["style"] != 1 else ["#8b8f9c", "#5a5a6a", "#c8c8d8"], 12, 50)
	var roll := randf()
	if roll < 0.4:
		for i in 1 + randi() % 3:
			Combat.drop_pickup("coin", o["x"], o["y"])
	elif roll < 0.48:
		Combat.drop_pickup("heart", o["x"], o["y"])
	elif roll < 0.55:
		Combat.drop_pickup("gem", o["x"], o["y"])
	elif roll < 0.58:
		Combat.drop_pickup(TB.pick(["bomb", "key"]), o["x"], o["y"])

static func draw_pot(ci: CanvasItem, o: Dictionary) -> void:
	var x: float = roundf(o["x"])
	var y: float = roundf(o["y"])
	var body: Array = [["#a8705a", "#7a5236", "#d9b48a"], ["#6b6a72", "#4e4a5e", "#a8a8b8"], ["#4d6aa8", "#2b4f8a", "#9ab8ff"]][o["style"]]
	ci.draw_rect(Rect2(x - 5, y + 1, 10, 2), Color(0, 0, 0, 0.35))
	ci.draw_circle(Vector2(x, y - 3), 5.0, TB.c(body[1]))
	ci.draw_circle(Vector2(x - 0.5, y - 3.5), 4.2, TB.c(body[0]))
	ci.draw_rect(Rect2(x - 2, y - 10, 4, 3), TB.c(body[1]))
	ci.draw_rect(Rect2(x - 3, y - 11, 6, 1), TB.c(body[0]))
	ci.draw_rect(Rect2(x - 3, y - 5, 1, 3), TB.c(body[2]))
	ci.draw_rect(Rect2(x - 4, y - 3, 8, 1), TB.c(body[1]))

static func draw_coins(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x: float = o["x"]
	var y: float = o["y"]
	if fmod(t * 0.7 + x * 0.01, 1.0) < 0.12:
		ci.draw_rect(Rect2(x - 2 + (int(x) % 5), y - 5, 1, 1), Color(1, 1, 1, 0.9))

# ---------- Drawn once with the room ----------
## Called from world_view._paint_bg after the floor's own dressing.
static func paint_static(ci: CanvasItem, room: Room) -> void:
	_flames.clear()
	_glints.clear()
	_smoke.clear()
	_lights.clear()
	if _room == null or _room.get_ref() != room:
		_room = weakref(room)
		_spawn_critters(room)
	paint_ponds(ci, room)
	if not on(room):
		return
	var rng := SeedRng.new(room.seed_value ^ 0x1f3a5c7e)
	if library() >= 0 and room.theme.is_empty():
		_library_floor(ci, room, rng, library())   # 20.3 Chapter IV: out of the book, in the library
	elif G.floor_index >= GameData.FLOORS.size() + GameData.NEW_FLOORS.size() and room.theme.is_empty():
		_ink_floor(ci, room, rng)
	if not room.theme.is_empty() and room.type != "boss":
		return
	match room.type:
		"camp":
			Camp.paint_static(ci, room, rng)   # 17.2
			Gfx.sp(ci, "campfire", 224, 154)
			Camp.fire(_flames, _lights)
		"treasure": _treasure(ci, rng)
		"shop": _shop(ci, rng)
		"shrine": _shrine(ci, rng)
		"vault": _vault(ci, rng)
		"secret": _secret(ci, rng)
		"rest": _camp(ci, rng)
		"boss": _arena(ci, room, rng)
		"start": _start(ci, rng)
		"mystery":
			if room.event != "fishing":
				_mystery(ci, rng)

## 17.1: the still part of every pond in the room (also under the NEON LOOK).
static func paint_ponds(ci: CanvasItem, room: Room) -> void:
	for o in room.objects:
		if o["kind"] == "e_pond":
			Fishing.draw_pond(ci, o, 0.0, false)

## 17.1: pots, kegs and coin heaps change only when one breaks, so they are drawn with the doors
## (world_view's dyn layer, redrawn when G.dyn_dirty is set), not every frame.
static func paint_dyn(ci: CanvasItem, room: Room) -> void:
	for o in room.objects:
		if o.get("gone", false):
			continue
		match o["kind"]:
			"e_pot": draw_pot(ci, o)
			"e_keg": draw_keg(ci, o, 0.0)
			"e_coins": _heap(ci, o["x"], o["y"], o["n"] + 3)
			"e_candle": draw_candle(ci, o)   # 21.2
			"e_shelf": draw_shelf(ci, o)

## 21.2 a standing candelabrum, or one knocked over (its flames are drawn live, paint_live).
static func draw_candle(ci: CanvasItem, o: Dictionary) -> void:
	var x: float = o["x"]
	var y: float = o["y"]
	var iron := TB.c("#2a2430")
	if not o.get("down", false):
		_shadow(ci, x, y, 8)
		ci.draw_rect(Rect2(x - 3, y - 2, 6, 2), iron)
		ci.draw_rect(Rect2(x, y - 16, 1, 15), iron)
		ci.draw_rect(Rect2(x - 4, y - 14, 9, 1), iron)
		for dx in [-4.0, 0.0, 4.0]:
			ci.draw_rect(Rect2(x + dx, y - 17 + (0.0 if dx == 0.0 else 1.0), 1, 3 - (0.0 if dx == 0.0 else 1.0)), TB.c("#f4ecd8"))
		return
	var d: float = o["dir"]
	ci.draw_rect(Rect2(x + (0.0 if d > 0 else -16.0), y - 1, 16, 1), iron)
	ci.draw_rect(Rect2(x - 3, y - 2, 6, 2), iron)
	for k in 3:
		ci.draw_rect(Rect2(x + d * (8 + k * 4), y + 1 + (k % 2), 3, 1), TB.c("#f4ecd8"))
	ci.draw_circle(Vector2(x + d * 13, y + 2), 2.5, Color(0.95, 0.92, 0.85, 0.35))

## 21.2 a free-standing bookcase, or one knocked flat with its books spilled.
static func draw_shelf(ci: CanvasItem, o: Dictionary) -> void:
	var x: float = o["x"]
	var y: float = o["y"]
	var g := RandomNumberGenerator.new()
	g.seed = o["seed"]
	var spines := ["#d8443c", "#4d6aa8", "#7ab04a", "#f2c94c", "#a35bd6", "#c8a878"]
	if not o.get("down", false):
		_shadow(ci, x, y, 22)
		ci.draw_rect(Rect2(x - 10, y - 28, 20, 28), TB.c("#3a2414"))
		ci.draw_rect(Rect2(x - 9, y - 27, 18, 26), TB.c("#5a3a22"))
		for row in 3:
			var by := y - 26 + row * 9
			var bx := x - 8
			while bx < x + 7:
				var w := 2 + g.randi() % 2
				var h := 6 + g.randi() % 2
				ci.draw_rect(Rect2(bx, by + 7 - h, w, h), TB.c(spines[g.randi() % spines.size()]))
				bx += w
			ci.draw_rect(Rect2(x - 9, by + 7, 18, 1), TB.c("#3a2414"))
		return
	var d: float = o["dir"]
	var x0 := x if d > 0 else x - 28.0
	ci.draw_rect(Rect2(x0, y - 9, 28, 10), TB.c("#3a2414"))
	ci.draw_rect(Rect2(x0 + 1, y - 8, 26, 8), TB.c("#5a3a22"))
	for k in 7:
		var bxy := Vector2(x0 + g.randf_range(-6, 34), y + g.randf_range(1, 9))
		ci.draw_rect(Rect2(bxy, Vector2(4, 3)), TB.c(spines[g.randi() % spines.size()]))
		ci.draw_rect(Rect2(bxy + Vector2(1, 1), Vector2(2, 1)), TB.c("#e8dcc0"))

static func _shadow(ci: CanvasItem, x: float, y: float, w: float) -> void:
	ci.draw_rect(Rect2(x - w / 2, y - 1, w, 3), Color(0, 0, 0, 0.3))

static func _prop(ci: CanvasItem, name: String, x: float, y: float) -> void:
	var tex := Img.t(name)
	_shadow(ci, x, y, tex.get_width() - 4)
	ci.draw_texture(tex, Vector2(roundf(x - tex.get_width() / 2.0), roundf(y - tex.get_height())))

static func _rug(ci: CanvasItem, r: Rect2, edge: Color, field: Color, trim: Color) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.25))
	ci.draw_rect(r, edge)
	ci.draw_rect(r.grow(-2), trim)
	ci.draw_rect(r.grow(-3), edge)
	ci.draw_rect(r.grow(-5), field)
	var dark := field.darkened(0.2)
	var c := r.get_center()
	# A diamond medallion and corner marks.
	var m := minf(r.size.x, r.size.y) * 0.28
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -m), c + Vector2(m * 1.4, 0), c + Vector2(0, m), c + Vector2(-m * 1.4, 0)]), dark)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -m * 0.5), c + Vector2(m * 0.7, 0), c + Vector2(0, m * 0.5), c + Vector2(-m * 0.7, 0)]), trim)
	for k in 4:
		var q := Vector2(r.position.x + 8 if k % 2 == 0 else r.end.x - 9, r.position.y + 8 if k < 2 else r.end.y - 9)
		ci.draw_rect(Rect2(q, Vector2(2, 2)), trim)
	# Fringe at both ends.
	var fx := r.position.x + 2
	while fx < r.end.x - 2:
		ci.draw_rect(Rect2(fx, r.position.y - 2, 1, 2), trim)
		ci.draw_rect(Rect2(fx, r.end.y, 1, 2), trim)
		fx += 3

static func _heap(ci: CanvasItem, x: float, y: float, n: int) -> void:
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 8, y + 1), Vector2(x - 3, y - 4), Vector2(x + 3, y - 4), Vector2(x + 8, y + 1)]), TB.c("#b8862a"))
	for i in n:
		var a := i * 2.4
		var px := x + cos(a) * (2 + i % 4) * 1.4
		var py := y - 2 - (i % 3) * 1.5 + sin(a) * 1.2
		ci.draw_rect(Rect2(roundf(px) - 1, roundf(py), 3, 2), TB.c("#f2c94c"))
		ci.draw_rect(Rect2(roundf(px) - 1, roundf(py), 2, 1), TB.c("#fff07a"))

static func _banner(ci: CanvasItem, x: float, col: Color, trim: Color) -> void:
	ci.draw_rect(Rect2(x - 7, 14, 14, 1), TB.c("#4a3020"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, 15), Vector2(x + 6, 15), Vector2(x + 6, 30), Vector2(x, 26), Vector2(x - 6, 30)]), col)
	ci.draw_rect(Rect2(x - 6, 15, 12, 1), trim)
	ci.draw_rect(Rect2(x - 1, 19, 2, 4), trim)
	ci.draw_rect(Rect2(x - 2, 20, 4, 2), trim)

static func _candle(ci: CanvasItem, x: float, y: float, tall: int = 5) -> void:
	ci.draw_rect(Rect2(x - 1, y - tall, 3, tall), TB.c("#f4ecd8"))
	ci.draw_rect(Rect2(x - 1, y - tall, 1, tall), TB.c("#ffffff"))
	ci.draw_rect(Rect2(x - 2, y - 1, 5, 1), TB.c("#c8a878"))
	_flames.append([x + 0.5, y - tall - 1, 1.0])
	_lights.append([x, y - tall, 0.35])

static func _brazier(ci: CanvasItem, x: float, y: float) -> void:
	_prop(ci, "prop_brazier", x, y)
	_flames.append([x, y - 13, 2.2])
	_lights.append([x, y - 12, 1.0])

static func _web(ci: CanvasItem, x: float, y: float, sx: float, sy: float) -> void:
	var col := Color(0.85, 0.85, 0.9, 0.35)
	for k in 5:
		var a := k * PI / 8.0
		ci.draw_line(Vector2(x, y), Vector2(x + cos(a) * 18 * sx, y + sin(a) * 18 * sy), col, 1.0)
	for rr in [6.0, 11.0, 16.0]:
		var pts := PackedVector2Array()
		for k in 5:
			var a := k * PI / 8.0
			pts.append(Vector2(x + cos(a) * rr * sx, y + sin(a) * rr * sy))
		ci.draw_polyline(pts, col, 1.0)

static func _bones(ci: CanvasItem, x: float, y: float, rng: SeedRng) -> void:
	var bone := TB.c("#d9d0b4")
	for k in 3:
		var a := rng.next_f() * TAU
		var p := Vector2(x + rng.int_range(-6, 6), y + rng.int_range(-3, 3))
		var d := Vector2(cos(a), sin(a)) * 4
		ci.draw_line(p - d, p + d, bone, 1.0)
		ci.draw_rect(Rect2(p - d - Vector2(1, 1), Vector2(2, 2)), bone)
		ci.draw_rect(Rect2(p + d - Vector2(1, 1), Vector2(2, 2)), bone)
	ci.draw_circle(Vector2(x + 5, y - 2), 2.5, bone)
	ci.draw_rect(Rect2(x + 4, y - 3, 1, 1), TB.c("#1a1423"))
	ci.draw_rect(Rect2(x + 6, y - 3, 1, 1), TB.c("#1a1423"))

# ---------- The rooms ----------
## THE HOARD.
static func _treasure(ci: CanvasItem, rng: SeedRng) -> void:
	_rug(ci, Rect2(CX - 96, CY - 34, 192, 84), TB.c("#5a1620"), TB.c("#8a2a33"), TB.c("#f2c94c"))
	for x in [WALL_SPOTS[0], WALL_SPOTS[1], WALL_SPOTS[2], WALL_SPOTS[3]]:
		_banner(ci, x, TB.c("#8a2a33"), TB.c("#f2c94c"))
	_brazier(ci, CX - 120, CY - 6)
	_brazier(ci, CX + 120, CY - 6)
	for spot in [Vector2(44, 80), Vector2(404, 80), Vector2(40, 226), Vector2(408, 226), Vector2(150, 60), Vector2(300, 60)]:
		_heap(ci, spot.x, spot.y, 6 + rng.int_range(0, 5))
		_glints.append([spot.x + rng.int_range(-4, 4), spot.y - 4])
	for spot in [Vector2(90, 58), Vector2(360, 244)]:
		_shadow(ci, spot.x, spot.y, 12)
		ci.draw_texture(Img.t("chest"), Vector2(spot.x - 6, spot.y - 9), Color(0.75, 0.7, 0.7))
		ci.draw_rect(Rect2(spot.x - 5, spot.y - 11, 10, 2), TB.c("#5a3a22"))   # its lid, thrown open
	for i in 26:
		var x := rng.int_range(30, 418)
		var y := rng.int_range(44, 262)
		ci.draw_rect(Rect2(x, y, 2, 1), TB.c("#f2c94c"))
	for i in 6:
		_glints.append([rng.int_range(40, 408), rng.int_range(50, 250)])

## THE STALL.
static func _shop(ci: CanvasItem, rng: SeedRng) -> void:
	_rug(ci, Rect2(CX - 110, CY - 30, 220, 92), TB.c("#2a3a5a"), TB.c("#3f5a8a"), TB.c("#c8a878"))
	# The awning over the wares.
	var y0 := 64.0
	var x := CX - 120
	var k := 0
	while x < CX + 120:
		var col := TB.c("#d8443c") if k % 2 == 0 else TB.c("#f4ecd8")
		ci.draw_rect(Rect2(x, y0, 12, 12), col)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, y0 + 12), Vector2(x + 12, y0 + 12), Vector2(x + 6, y0 + 16)]), col)
		x += 12
		k += 1
	ci.draw_rect(Rect2(CX - 120, y0 - 2, 240, 2), TB.c("#5a3a22"))
	for px in [CX - 120, CX + 118]:
		ci.draw_rect(Rect2(px, y0, 2, 40), TB.c("#5a3a22"))
	# Shelves of bottles on the top wall.
	for sx in [118.0, 282.0]:
		ci.draw_rect(Rect2(sx, 22, 48, 2), TB.c("#5a3a22"))
		for b in 7:
			var bc: String = ["#63b84f", "#d8443c", "#4d9be6", "#f2c94c", "#a35bd6"][(b + int(sx)) % 5]
			var bh := 4 + (b * 3 + int(sx)) % 4
			ci.draw_rect(Rect2(sx + 2 + b * 7, 22 - bh, 4, bh), TB.c(bc))
			ci.draw_rect(Rect2(sx + 3 + b * 7, 22 - bh - 2, 2, 2), TB.c("#c8a878"))
	# Sacks, crates and barrels along the sides.
	for spot in [Vector2(46, 100), Vector2(54, 210), Vector2(398, 104), Vector2(392, 214)]:
		_prop(ci, "crate", spot.x, spot.y)
		_prop(ci, "barrel", spot.x + 16, spot.y + 4)
		ci.draw_circle(Vector2(spot.x - 10, spot.y - 2), 4, TB.c("#c8a878"))   # a sack
		ci.draw_rect(Rect2(spot.x - 11, spot.y - 7, 2, 2), TB.c("#8a6a4a"))
	# Hanging lanterns.
	for lx in [CX - 90, CX + 90]:
		ci.draw_line(Vector2(lx, 34), Vector2(lx, 44), TB.c("#4a3020"), 1.0)
		ci.draw_rect(Rect2(lx - 3, 44, 6, 7), TB.c("#2a2018"))
		ci.draw_rect(Rect2(lx - 2, 45, 4, 5), TB.c("#f2c94c"))
		_lights.append([lx, 48, 0.8])
	# A sign: a coin on a board.
	ci.draw_rect(Rect2(CX - 12, 36, 24, 12), TB.c("#7a5236"))
	ci.draw_rect(Rect2(CX - 12, 36, 24, 1), TB.c("#9a6a42"))
	ci.draw_circle(Vector2(CX, 42), 3.5, TB.c("#f2c94c"))
	ci.draw_rect(Rect2(CX - 1, 40, 2, 4), TB.c("#b8862a"))

## A SHRINE.
static func _shrine(ci: CanvasItem, rng: SeedRng) -> void:
	var col := _accent()
	ci.draw_rect(Rect2(CX - 14, CY + 20, 28, 120), TB.c("#5a1a3a"))   # a carpet to the altar
	ci.draw_rect(Rect2(CX - 12, CY + 20, 1, 120), TB.c("#c8a878"))
	ci.draw_rect(Rect2(CX + 11, CY + 20, 1, 120), TB.c("#c8a878"))
	var c := Vector2(CX, CY)
	ci.draw_arc(c, 54, 0, TAU, 48, Color(col.r, col.g, col.b, 0.55), 2.0)
	ci.draw_arc(c, 46, 0, TAU, 48, Color(col.r, col.g, col.b, 0.35), 1.0)
	for k in 12:
		var a := k * TAU / 12.0
		var p := c + Vector2(cos(a), sin(a)) * 50
		ci.draw_rect(Rect2(p.x - 1, p.y - 1, 3, 3), Color(col.r, col.g, col.b, 0.7))
	for k in 8:
		var a := k * TAU / 8.0 + 0.2
		_candle(ci, CX + cos(a) * 66, CY + sin(a) * 40 + 4, 4 + k % 3)
	_prop(ci, "prop_monkstatue" if G.floor_index % 2 == 0 else "prop_column", CX - 100, CY + 8)
	_prop(ci, "prop_monkstatue" if G.floor_index % 2 == 0 else "prop_column", CX + 100, CY + 8)
	for x in [WALL_SPOTS[0], WALL_SPOTS[3]]:
		_banner(ci, x, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6), TB.c("#f4ecd8"))
	for i in 30:
		var p := Vector2(rng.int_range(40, 408), rng.int_range(50, 250))
		ci.draw_rect(Rect2(p, Vector2(2, 1)), TB.c("#e86fb4") if i % 2 == 0 else TB.c("#f4ecd8"))   # petals
	_smoke.append([CX - 100, CY - 12])
	_smoke.append([CX + 100, CY - 12])

## THE VAULT.
static func _vault(ci: CanvasItem, rng: SeedRng) -> void:
	var plate := Rect2(CX - 80, CY - 40, 160, 96)
	ci.draw_rect(plate, TB.c("#3a3a48"))
	var x := plate.position.x
	while x < plate.end.x:
		ci.draw_line(Vector2(x, plate.position.y), Vector2(x, plate.end.y), TB.c("#2a2a36"), 1.0)
		x += 16
	var y := plate.position.y
	while y < plate.end.y:
		ci.draw_line(Vector2(plate.position.x, y), Vector2(plate.end.x, y), TB.c("#2a2a36"), 1.0)
		for xx in range(int(plate.position.x) + 2, int(plate.end.x), 16):
			ci.draw_rect(Rect2(xx, y + 2, 1, 1), TB.c("#6b6a72"))
		y += 16
	ci.draw_rect(plate, TB.c("#8b8f9c"), false, 1.0)
	# Velvet ropes on brass posts round the plate.
	var posts := [plate.position + Vector2(-8, -6), Vector2(plate.end.x + 8, plate.position.y - 6), plate.end + Vector2(8, 6), Vector2(plate.position.x - 8, plate.end.y + 6)]
	for i in 4:
		var a: Vector2 = posts[i]
		var b: Vector2 = posts[(i + 1) % 4]
		if i % 2 == 1:
			continue
		var mid := (a + b) * 0.5 + Vector2(0, 5)
		ci.draw_polyline(PackedVector2Array([a + Vector2(0, -8), mid + Vector2(0, -8), b + Vector2(0, -8)]), TB.c("#a8282a"), 2.0)
	for p in posts:
		ci.draw_rect(Rect2(p.x - 1, p.y - 10, 3, 10), TB.c("#c9a35a"))
		ci.draw_circle(Vector2(p.x + 0.5, p.y - 11), 2, TB.c("#f2c94c"))
	# Gold bars and strongboxes along the walls.
	for spot in [Vector2(48, 70), Vector2(400, 70), Vector2(48, 232), Vector2(400, 232)]:
		for row in 3:
			for b in 3 - row:
				ci.draw_rect(Rect2(spot.x - 9 + b * 6 + row * 3, spot.y - row * 3, 6, 3), TB.c("#f2c94c"))
				ci.draw_rect(Rect2(spot.x - 9 + b * 6 + row * 3, spot.y - row * 3, 6, 1), TB.c("#fff07a"))
		_glints.append([spot.x, spot.y - 6])
	_prop(ci, "prop_strongbox", 96, 64)
	_prop(ci, "prop_strongbox", 352, 64)
	for x2 in [150.0, 298.0]:
		_prop(ci, "wall_chains", x2, 30)

## A HIDDEN ROOM.
static func _secret(ci: CanvasItem, rng: SeedRng) -> void:
	_web(ci, 18, 34, 1, 1)
	_web(ci, 430, 34, -1, 1)
	_web(ci, 18, 270, 1, -1)
	_web(ci, 430, 270, -1, -1)
	for i in 40:
		var p := Vector2(rng.int_range(24, 424), rng.int_range(40, 264))
		ci.draw_rect(Rect2(p, Vector2(rng.int_range(2, 6), 1)), Color(0.75, 0.7, 0.6, 0.18))   # dust
	_bones(ci, 80, 220, rng)
	_bones(ci, 360, 90, rng)
	_prop(ci, "crate", 380, 238)
	_prop(ci, "crate", 394, 244)
	_prop(ci, "crate", 386, 228)
	for spot in [Vector2(60, 96), Vector2(70, 102), Vector2(390, 180)]:
		_candle(ci, spot.x, spot.y, 3)
	for spot in [Vector2(120, 250), Vector2(330, 56), Vector2(40, 160)]:
		for k in 3:
			var mx: float = spot.x + k * 5 - 5
			ci.draw_rect(Rect2(mx, spot.y - 3, 1, 3), TB.c("#c8c0e0"))
			ci.draw_rect(Rect2(mx - 1, spot.y - 5, 3, 2), TB.c("#6fd3e0"))
		_lights.append([spot.x, spot.y - 4, 0.3])

## THE CAMP (rest stops).
static func _camp(ci: CanvasItem, rng: SeedRng) -> void:
	# Grass round the fire and log seats.
	for i in 24:
		var a := rng.next_f() * TAU
		var r := 30.0 + rng.next_f() * 40.0
		var p := Vector2(CX + cos(a) * r * 1.4, CY + sin(a) * r * 0.8)
		for g in 3:
			ci.draw_line(p + Vector2(g * 2 - 2, 0), p + Vector2(g * 2 - 3, -3 - g), TB.c("#4f7f45"), 1.0)
	for spot in [Vector2(CX - 30, CY + 22), Vector2(CX + 30, CY + 22)]:
		ci.draw_rect(Rect2(spot.x - 10, spot.y - 3, 20, 6), TB.c("#6b4a2a"))
		ci.draw_rect(Rect2(spot.x - 10, spot.y - 3, 20, 1), TB.c("#8a6a4a"))
		ci.draw_circle(Vector2(spot.x - 10, spot.y), 3, TB.c("#c8a878"))
		ci.draw_circle(Vector2(spot.x - 10, spot.y), 1.5, TB.c("#8a6a4a"))
	# A tent in the top right.
	var tx := 370.0
	var ty := 92.0
	ci.draw_colored_polygon(PackedVector2Array([Vector2(tx - 30, ty), Vector2(tx, ty - 34), Vector2(tx + 30, ty)]), TB.c("#7a5a3a"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(tx - 10, ty), Vector2(tx, ty - 22), Vector2(tx + 10, ty)]), TB.c("#2a2018"))
	ci.draw_line(Vector2(tx, ty - 34), Vector2(tx, ty - 38), TB.c("#4a3020"), 1.0)
	ci.draw_line(Vector2(tx - 30, ty), Vector2(tx - 36, ty + 2), TB.c("#c8a878"), 1.0)
	ci.draw_line(Vector2(tx + 30, ty), Vector2(tx + 36, ty + 2), TB.c("#c8a878"), 1.0)
	# A bedroll, a backpack, firewood and a pot on a tripod by the fire.
	ci.draw_rect(Rect2(300, 210, 30, 10), TB.c("#3f5a8a"))
	ci.draw_rect(Rect2(300, 210, 30, 2), TB.c("#6f8ab8"))
	ci.draw_circle(Vector2(332, 215), 5, TB.c("#2b4f8a"))
	ci.draw_rect(Rect2(348, 206, 9, 11), TB.c("#7a5236"))
	ci.draw_rect(Rect2(349, 208, 7, 3), TB.c("#5a3a22"))
	for k in 5:
		ci.draw_rect(Rect2(150 + (k % 3) * 6, 214 - (k / 3) * 4, 6, 4), TB.c("#6b4a2a"))
		ci.draw_circle(Vector2(150 + (k % 3) * 6, 216 - (k / 3) * 4), 2, TB.c("#c8a878"))
	ci.draw_line(Vector2(CX - 10, CY + 2), Vector2(CX, CY - 22), TB.c("#4a3020"), 1.0)
	ci.draw_line(Vector2(CX + 10, CY + 2), Vector2(CX, CY - 22), TB.c("#4a3020"), 1.0)
	ci.draw_line(Vector2(CX, CY - 22), Vector2(CX, CY - 14), TB.c("#6b6a72"), 1.0)
	ci.draw_rect(Rect2(CX - 5, CY - 14, 10, 6), TB.c("#3a3a48"))
	ci.draw_rect(Rect2(CX - 5, CY - 14, 10, 1), TB.c("#8b8f9c"))
	_smoke.append([CX, CY - 16])
	# A lantern on a stake.
	ci.draw_rect(Rect2(110, 80, 2, 18), TB.c("#4a3020"))
	ci.draw_rect(Rect2(107, 74, 8, 7), TB.c("#2a2018"))
	ci.draw_rect(Rect2(108, 75, 6, 5), TB.c("#f2c94c"))
	_lights.append([111, 78, 0.8])
	_lights.append([CX, CY - 4, 1.6])

## A GUARDIAN'S ARENA.
static func _arena(ci: CanvasItem, room: Room, rng: SeedRng) -> void:
	var col := _accent()
	var c := Vector2(CX, CY + 8)
	for rr in [96.0, 84.0]:
		var pts := PackedVector2Array()
		for k in 64:
			var a := k * TAU / 64.0
			pts.append(c + Vector2(cos(a) * rr, sin(a) * rr * 0.58))
		pts.append(pts[0])
		ci.draw_polyline(pts, Color(col.r, col.g, col.b, 0.45 if rr > 90 else 0.25), 2.0 if rr > 90 else 1.0)
	for k in 6:
		var a := k * TAU / 6.0 + PI / 6
		var p1 := c + Vector2(cos(a) * 84, sin(a) * 84 * 0.58)
		var p2 := c + Vector2(cos(a + TAU / 3) * 84, sin(a + TAU / 3) * 84 * 0.58)
		ci.draw_line(p1, p2, Color(col.r, col.g, col.b, 0.18), 1.0)
	for k in 12:
		var a := k * TAU / 12.0
		var p := c + Vector2(cos(a) * 90, sin(a) * 90 * 0.58)
		ci.draw_rect(Rect2(p.x - 1, p.y - 1, 3, 3), Color(col.r, col.g, col.b, 0.6))
	# Cracks running out from the middle.
	for k in 7:
		var a := rng.next_f() * TAU
		var p := c
		for s in 4:
			var q := p + Vector2(cos(a), sin(a) * 0.6) * rng.int_range(6, 12)
			ci.draw_line(p, q, Color(0, 0, 0, 0.35), 1.0)
			p = q
			a += (rng.next_f() - 0.5) * 0.9
	for spot in [Vector2(44, 68), Vector2(404, 68), Vector2(44, 252), Vector2(404, 252)]:
		_brazier(ci, spot.x, spot.y)
	for x in WALL_SPOTS:
		_banner(ci, x, Color(col.r * 0.55, col.g * 0.55, col.b * 0.55), col.lightened(0.3))
	_bones(ci, 96, 236, rng)
	_bones(ci, 350, 80, rng)

## THE START of a floor.
static func _start(ci: CanvasItem, rng: SeedRng) -> void:
	_rug(ci, Rect2(CX - 16, CY + 30, 32, 90), TB.c("#3a2a3a"), TB.c("#5a3a4a"), TB.c("#c8a878"))
	_brazier(ci, CX - 44, 258)
	_brazier(ci, CX + 44, 258)

## A MYSTERY room.
static func _mystery(ci: CanvasItem, rng: SeedRng) -> void:
	for spot in [Vector2(40, 64), Vector2(408, 64), Vector2(40, 250), Vector2(408, 250)]:
		ci.draw_rect(Rect2(spot.x - 1, spot.y - 14, 2, 14), TB.c("#4a3020"))
		ci.draw_rect(Rect2(spot.x - 3, spot.y - 20, 6, 7), TB.c("#2a2018"))
		ci.draw_rect(Rect2(spot.x - 2, spot.y - 19, 4, 5), TB.c("#e86fb4" if rng.next_f() < 0.3 else "#f2c94c"))
		_lights.append([spot.x, spot.y - 17, 0.7])
	_prop(ci, "barrel", 66, 246)
	_prop(ci, "barrel", 382, 70)

## Ink, paper and letters on Chapter II and III floors (their rooms have no floor dressing of their own).
static func _ink_floor(ci: CanvasItem, room: Room, rng: SeedRng) -> void:
	var ink := TB.c("#14141e")
	var letters := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	for i in 26:
		var c := rng.int_range(TB.IX0, TB.IX0 + TB.IW - 1)
		var r := rng.int_range(TB.IY0, TB.IY0 + TB.IH - 1)
		if room.tile(c, r) != World.T_FLOOR:
			continue
		var p := Vector2(c * TB.TS + rng.int_range(2, 12), r * TB.TS + rng.int_range(2, 12))
		match i % 4:
			0:   # an ink blot with splashes
				ci.draw_circle(p, rng.int_range(3, 6), Color(ink.r, ink.g, ink.b, 0.55))
				for k in 4:
					ci.draw_circle(p + Vector2(rng.int_range(-9, 9), rng.int_range(-6, 6)), 1, Color(ink.r, ink.g, ink.b, 0.5))
			1:   # a torn page
				ci.draw_colored_polygon(PackedVector2Array([p, p + Vector2(9, -2), p + Vector2(11, 8), p + Vector2(1, 10)]), Color(0.95, 0.92, 0.85, 0.35))
				for k in 3:
					ci.draw_line(p + Vector2(2, 2 + k * 2.5), p + Vector2(8, 1.5 + k * 2.5), Color(0.1, 0.1, 0.15, 0.3), 1.0)
			2:   # a stray letter
				Gfx.text(ci, letters[rng.int_range(0, 25)], p.x, p.y, "dim", 1, 0.5)
			_:   # a dropped quill
				ci.draw_line(p, p + Vector2(10, -6), Color(0.95, 0.92, 0.85, 0.5), 1.0)
				ci.draw_line(p, p + Vector2(2, -1), ink, 1.0)

## 20.3: which Chapter IV floor this is (0 the Stacks, 1 the Reading Room, 2 the Hearth), or -1.
static func library() -> int:
	var c4 := GameData.FLOORS.size() + GameData.NEW_FLOORS.size() + GameData.CHAPTER2.size() + GameData.CHAPTER3.size()
	if G.run_stats.get("chapter", 1) != 4 or G.floor_index < c4:
		return -1
	return G.floor_index - c4

## 20.3 the library's floors: shelves of books on the wall, and on the floor what a library drops:
## books and dust (the Stacks), rugs, papers and inkpots (the Reading Room), ash and scorch marks
## (the Hearth, where rejected books burn).
static func _library_floor(ci: CanvasItem, room: Room, rng: SeedRng, k: int) -> void:
	var spines := ["#d8443c", "#4d6aa8", "#7ab04a", "#f2c94c", "#a35bd6", "#c8a878", "#e8873a"]
	for x in WALL_SPOTS:   # a bookcase on the wall at each of the HUD-free spots
		var y := 16.0
		ci.draw_rect(Rect2(x - 15, y, 30, 26), TB.c("#3a2414"))
		ci.draw_rect(Rect2(x - 14, y + 1, 28, 24), TB.c("#5a3a22"))
		for row in 2:
			var by := y + 3 + row * 12
			var bx: float = x - 13
			while bx < x + 12:
				var w := rng.int_range(2, 3)
				var h := rng.int_range(7, 9)
				var col := TB.c(spines[rng.int_range(0, spines.size() - 1)])
				if k == 2 and rng.next_f() < 0.4:
					col = TB.c("#2a1a14")   # the hearth's shelves are half burned
				ci.draw_rect(Rect2(bx, by + 9 - h, w, h), col)
				ci.draw_rect(Rect2(bx, by + 9 - h, 1, h), col.lightened(0.25))
				bx += w + (1 if rng.next_f() < 0.2 else 0)
			ci.draw_rect(Rect2(x - 14, by + 9, 28, 2), TB.c("#3a2414"))
	if k == 1:   # two long rugs under the reading tables
		for ry in [96.0, 196.0]:
			ci.draw_rect(Rect2(150, ry, 148, 26), Color(0.42, 0.12, 0.14, 0.45))
			ci.draw_rect(Rect2(152, ry + 2, 144, 22), Color(0.6, 0.45, 0.2, 0.25), false, 1.0)
	for i in 30:
		var c := rng.int_range(TB.IX0, TB.IX0 + TB.IW - 1)
		var r := rng.int_range(TB.IY0, TB.IY0 + TB.IH - 1)
		if room.tile(c, r) != World.T_FLOOR:
			continue
		var p := Vector2(c * TB.TS + rng.int_range(2, 12), r * TB.TS + rng.int_range(2, 12))
		match k * 10 + i % 3:
			0, 10:   # a dropped book
				var col := TB.c(spines[rng.int_range(0, spines.size() - 1)])
				ci.draw_rect(Rect2(p.x, p.y, 7, 5), col.darkened(0.2))
				ci.draw_rect(Rect2(p.x + 1, p.y + 1, 5, 3), TB.c("#e8dcc0"))
				ci.draw_rect(Rect2(p.x, p.y, 7, 1), col)
			1:   # a drift of dust
				ci.draw_circle(p, rng.int_range(2, 4), Color(0.8, 0.78, 0.7, 0.18))
				ci.draw_circle(p + Vector2(3, 1), 2, Color(0.8, 0.78, 0.7, 0.14))
			2, 11:   # loose papers
				ci.draw_colored_polygon(PackedVector2Array([p, p + Vector2(8, -1), p + Vector2(9, 6), p + Vector2(1, 7)]), Color(0.95, 0.92, 0.85, 0.3))
			12:   # an inkpot and its spill
				ci.draw_circle(p + Vector2(4, 3), 3, Color(0.08, 0.08, 0.14, 0.45))
				ci.draw_rect(Rect2(p.x, p.y - 3, 4, 4), TB.c("#2a2a4a"))
				ci.draw_rect(Rect2(p.x + 1, p.y - 4, 2, 1), TB.c("#c9a35a"))
			20:   # a heap of ash
				ci.draw_circle(p, rng.int_range(3, 5), Color(0.25, 0.23, 0.26, 0.5))
				ci.draw_circle(p + Vector2(-2, -1), 2, Color(0.45, 0.42, 0.45, 0.35))
			21:   # a scorch mark
				ci.draw_circle(p, rng.int_range(4, 7), Color(0.08, 0.04, 0.03, 0.35))
			_:   # a burnt page, still glowing at the edge
				ci.draw_colored_polygon(PackedVector2Array([p, p + Vector2(7, -1), p + Vector2(8, 5), p + Vector2(1, 6)]), Color(0.2, 0.15, 0.12, 0.5))
				ci.draw_rect(Rect2(p.x + 6, p.y, 2, 1), Color(1.0, 0.5, 0.2, 0.7))

# ---------- What moves (every frame, cheap) ----------
static func _spawn_critters(room: Room) -> void:
	_critters.clear()
	if not on(room):
		return
	_rng.seed = room.seed_value ^ 0x7777
	var kinds := ["rat", "rat", "moth"] if G.floor_index in [0, 3, 7, 10] else (["butterfly", "butterfly", "rat"] if G.floor_index in [1, 6] else ["moth", "rat"])
	if G.floor_index in BIRD_FLOORS and room.theme.is_empty():
		kinds = ["bird", "bird", "bird", "rat"]   # 21.2: crows on the open-air floors
	var n := _rng.randi_range(2, 4)
	for i in n:
		var k: String = kinds[_rng.randi_range(0, kinds.size() - 1)]
		_critters.append({ "kind": k, "x": _rng.randf_range(40, 408), "y": _rng.randf_range(50, 250), "vx": 0.0, "vy": 0.0, "t": _rng.randf() * 3.0,
			"col": ["#e86fb4", "#f2c94c", "#6fd3e0", "#f4ecd8"][_rng.randi_range(0, 3)] if k == "butterfly" else "#8b8f9c" })

## 21.2: crows peck about on the open-air floors (the hamlet, the warfront, the rooftops) and take
## off when you come close or something blows up; later new ones land.
const BIRD_FLOORS := [6, 7, 9]
static var _land_t := 12.0

## 17.3 weather moments (drawing only, own random numbers): lightning on the stormy floors (the
## Nightspire rooftops, the windswept roofs, the Eclipse), ink rain on the chapter floors.
const STORMY := [6, 9, 10]
static var _flash := 0.0
static var _flash_t := 6.0
static var _bolt := PackedVector2Array()
static var _drops: Array = []

## Once per logic tick (world_view, like the floor's drifting air).
static func tick(dt: float) -> void:
	var p := G.player
	if p == null:
		return
	if G.room != null and on(G.room) and G.room.theme.is_empty():
		if G.floor_index in STORMY:
			_flash = maxf(0.0, _flash - dt)
			_flash_t -= dt
			if _flash_t <= 0:
				_flash_t = _rng.randf_range(7.0, 16.0)
				_flash = 0.35
				_bolt = PackedVector2Array()
				var x := _rng.randf_range(60, 388)
				var y := 32.0
				while y < 150:
					_bolt.append(Vector2(x, y))
					x += _rng.randf_range(-14, 14)
					y += _rng.randf_range(10, 22)
		elif library() >= 0:   # 20.3: dust in the library's light; embers rising from the hearth
			if not _drops.is_empty() and (_drops[0] as Array).size() != 4:
				_drops.clear()   # (ink rain from Chapter III's floors)
			while _drops.size() < 22:
				_drops.append([_rng.randf_range(20, 428), _rng.randf_range(40, 262), _rng.randf_range(4, 10), _rng.randf() * TAU])
			for d in _drops:
				d[3] += dt
				if library() == 2:
					d[1] -= d[2] * 3.0 * dt
					d[0] += sin(d[3] * 2.0) * 6.0 * dt
					if d[1] < 36:
						d[0] = _rng.randf_range(20, 428)
						d[1] = 262.0
				else:
					d[0] += sin(d[3] * 0.7) * d[2] * dt
					d[1] += cos(d[3] * 0.5) * d[2] * 0.5 * dt
		elif G.floor_index >= GameData.FLOORS.size() + GameData.NEW_FLOORS.size():
			if not _drops.is_empty() and (_drops[0] as Array).size() != 3:
				_drops.clear()
			while _drops.size() < 18:
				_drops.append([_rng.randf_range(20, 428), _rng.randf_range(-40, 260), _rng.randf_range(70, 110)])
			for d in _drops:
				d[1] += d[2] * dt
				if d[1] > 268:
					d[0] = _rng.randf_range(20, 428)
					d[1] = _rng.randf_range(-30, 20)
	var songbirds := CampClock.birds()   # 21.6: songbirds in the camp of a morning
	if songbirds or G.floor_index in BIRD_FLOORS and G.room != null and G.room.theme.is_empty() and on(G.room):
		_land_t -= dt
		if _land_t <= 0.0:   # a new crow lands now and then
			_land_t = _rng.randf_range(3.0, 8.0) if songbirds else _rng.randf_range(10.0, 20.0)
			if _critters.filter(func(c): return c["kind"] == "bird").size() < (5 if songbirds else 3):
				var lx := _rng.randf_range(60, 388)
				_critters.append({ "kind": "bird", "x": lx, "y": 20.0, "vx": _rng.randf_range(-20, 20), "vy": 80.0, "t": 0.0,
					"col": ["#a8705a", "#4d9be6", "#d8443c", "#e8c84a"][_rng.randi() % 4] if songbirds else "#2a2838",
					"land": _rng.randf_range(80, 240) })
	for i in range(_critters.size() - 1, -1, -1):
		var c: Dictionary = _critters[i]
		if c["kind"] == "bird":
			_bird(c, p, dt)
			if c.get("gone", false):
				_critters.remove_at(i)
			continue
		c["t"] -= dt
		var d := TB.dist_xy(p.x, p.y, c["x"], c["y"])
		if d < 40:   # it runs or flutters away
			_startle(c, p.x, p.y)
			c["t"] = 0.6
		elif c["t"] <= 0:
			c["t"] = _rng.randf_range(0.8, 3.0)
			if c["kind"] == "rat" and _rng.randf() < 0.5:
				c["vx"] = 0.0
				c["vy"] = 0.0
			else:
				var a := _rng.randf() * TAU
				var sp := 40.0 if c["kind"] == "rat" else 22.0
				c["vx"] = cos(a) * sp
				c["vy"] = sin(a) * sp
		c["x"] = clampf(c["x"] + c["vx"] * dt, 24, 424)
		c["y"] = clampf(c["y"] + c["vy"] * dt, 40, 262)

static func paint_live(ci: CanvasItem, t: float) -> void:
	if G.room == null or not on(G.room):
		return
	var lib := library() if G.room.theme.is_empty() else -1
	for d in _drops:   # 17.3: ink rain on the chapter floors (20.3: dust and embers in the library)
		if (d as Array).size() < 4 and lib >= 0:
			continue
		if lib == 2:
			ci.draw_rect(Rect2(d[0], d[1], 1, 1), Color(1.0, 0.55 + 0.3 * sin(d[3] * 5.0), 0.2, 0.8))
		elif lib >= 0:
			ci.draw_rect(Rect2(d[0], d[1], 1, 1), Color(0.95, 0.9, 0.75, 0.35 + 0.2 * sin(d[3] * 2.0)))
		elif G.floor_index >= GameData.FLOORS.size() + GameData.NEW_FLOORS.size() and G.room.theme.is_empty():
			ci.draw_rect(Rect2(d[0], d[1], 1, 3), Color(0.1, 0.1, 0.18, 0.55))
	for f in _flames:
		var fl := 0.8 + 0.2 * sin(t * 13.0 + f[0])
		var s: float = f[2]
		ci.draw_rect(Rect2(f[0] - s * 0.5, f[1] - s * 1.6 * fl, s, s * 1.6 * fl), TB.c("#e8873a"))
		ci.draw_rect(Rect2(f[0] - s * 0.25, f[1] - s * fl, maxf(1.0, s * 0.5), s * fl), TB.c("#fff07a"))
	for g in _glints:
		var ph := fmod(t * 0.6 + g[0] * 0.013 + g[1] * 0.007, 1.0)
		if ph < 0.15:
			var a := 1.0 - ph / 0.15
			ci.draw_rect(Rect2(g[0], g[1] - 2, 1, 5), Color(1, 1, 0.9, a))
			ci.draw_rect(Rect2(g[0] - 2, g[1], 5, 1), Color(1, 1, 0.9, a))
	for s in _smoke:
		for k in 4:
			var ph := fmod(t * 0.35 + k * 0.25, 1.0)
			ci.draw_circle(Vector2(s[0] + sin(t + k * 1.7) * 3.0 * ph, s[1] - ph * 22.0), 1.5 + ph * 2.5, Color(0.85, 0.85, 0.9, 0.22 * (1.0 - ph)))
	if G.room != null:   # 21.2: the flames of standing candelabra (out once knocked over)
		for o in G.room.objects:
			if o["kind"] == "e_candle" and not o.get("down", false):
				for dx in [-4.0, 0.0, 4.0]:
					var fl := 0.8 + 0.2 * sin(t * 12.0 + o["x"] + dx)
					ci.draw_rect(Rect2(o["x"] + dx, o["y"] - 19 - (1.0 if dx == 0.0 else 0.0) - fl, 1, 2 * fl), TB.c("#f2c94c"))
	for c in _critters:
		var x := roundf(c["x"])
		var y := roundf(c["y"])
		match c["kind"]:
			"rat":
				var moving: bool = absf(c["vx"]) + absf(c["vy"]) > 1.0
				var dir := -1.0 if c["vx"] < 0 else 1.0
				ci.draw_rect(Rect2(x - 3, y - 2, 6, 3), TB.c("#6b6a72"))
				ci.draw_rect(Rect2(x + 2 * dir, y - 3, 2, 2), TB.c("#8b8f9c"))
				ci.draw_rect(Rect2(x - 4 * dir - (1 if dir > 0 else 0), y - 1 + (sin(t * 20) if moving else 0.0), 3, 1), TB.c("#e0a4a4"))
			"bird":   # 21.2
				var f: float = c.get("face", 1.0)
				if c.get("fly", false) or c.has("land"):
					var w := sin(t * 22.0 + x) * 3.0
					ci.draw_rect(Rect2(x - 2, y - 1, 4, 2), TB.c("#2a2838"))
					ci.draw_line(Vector2(x - 1, y - 1), Vector2(x - 5, y - 2 + w), TB.c("#3a3850"), 1.0)
					ci.draw_line(Vector2(x + 1, y - 1), Vector2(x + 5, y - 2 + w), TB.c("#3a3850"), 1.0)
				else:
					var pk: float = 1.0 if c.get("peck", 0.0) > 0.0 else 0.0
					ci.draw_rect(Rect2(x - 2, y - 3, 4, 3), TB.c("#2a2838"))
					ci.draw_rect(Rect2(x + 2 * f - (1 if f < 0 else 0), y - 4 + pk, 2, 2), TB.c("#3a3850"))
					ci.draw_rect(Rect2(x + 4 * f - (1 if f < 0 else 0), y - 3 + pk, 1, 1), TB.c("#e8873a"))
					ci.draw_rect(Rect2(x - 1, y, 1, 1), TB.c("#e8873a"))
					ci.draw_rect(Rect2(x + 1, y, 1, 1), TB.c("#e8873a"))
			"moth", "butterfly":
				var flap := absf(sin(t * 14.0 + x))
				var cl := TB.c(c["col"])
				ci.draw_rect(Rect2(x - 1 - 2 * flap, y - 1, 2, 2), cl)
				ci.draw_rect(Rect2(x + 1 + 2 * flap - 1, y - 1, 2, 2), cl)
				ci.draw_rect(Rect2(x, y - 1, 1, 3), TB.c("#2a2018"))

## 21.2 a crow: lands, pecks, hops; flies off when startled (and is gone off the top).
static func _bird(c: Dictionary, p: Player, dt: float) -> void:
	if c.get("fly", false):
		c["x"] += c["vx"] * dt
		c["y"] += c["vy"] * dt
		c["vy"] -= 30.0 * dt
		if c["y"] < 10.0 or c["x"] < -10.0 or c["x"] > 458.0:
			c["gone"] = true
		return
	if c.has("land"):   # coming down to land
		c["x"] += c["vx"] * dt
		c["y"] += c["vy"] * dt
		if c["y"] >= c["land"]:
			c.erase("land")
			c["vx"] = 0.0
			c["vy"] = 0.0
		return
	if TB.dist_xy(p.x, p.y, c["x"], c["y"]) < 60.0 or G.locked and _rng.randf() < 0.004:
		_startle(c, p.x, p.y)
		return
	c["t"] -= dt
	if c["t"] <= 0.0:   # a hop, or a peck
		c["t"] = _rng.randf_range(0.4, 1.6)
		c["peck"] = 0.25 if _rng.randf() < 0.5 else 0.0
		if c["peck"] == 0.0:
			c["x"] = clampf(c["x"] + _rng.randf_range(-6, 6), 24, 424)
			c["y"] = clampf(c["y"] + _rng.randf_range(-3, 3), 40, 262)
			c["face"] = 1.0 if _rng.randf() < 0.5 else -1.0
	c["peck"] = maxf(0.0, c.get("peck", 0.0) - dt)

## 17.3: a lightning flash over the whole room (world_view's top layer).
static func paint_over(ci: CanvasItem) -> void:
	if _flash <= 0.0 or G.room == null or not on(G.room):
		return
	var a := _flash / 0.35
	ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), Color(0.85, 0.9, 1.0, 0.22 * a))
	if _bolt.size() > 1 and a > 0.5:
		ci.draw_polyline(_bolt, Color(1, 1, 1, a), 2.0)

## The warm light of fires, candles and lanterns (the additive glow layer).
static func paint_glow(ci: CanvasItem, t: float) -> void:
	if G.room == null or not on(G.room):
		return
	for o in G.room.objects:   # 21.2: standing candelabra glow
		if o["kind"] == "e_candle" and not o.get("down", false):
			Gfx.sp(ci, "glow_torch", o["x"], o["y"] - 18 + 14.0, 14.0 / 36.0, 14.0 / 36.0, 0.0, false, 0.45 + 0.05 * sin(t * 9.0 + o["x"]))
	for i in _lights.size():
		var l: Array = _lights[i]
		var op: float = (0.55 + 0.1 * sin(t * 8.0 + i * 3.0)) * l[2]
		var sz := 36.0 * clampf(l[2], 0.3, 1.6)
		Gfx.sp(ci, "glow_torch", l[0], l[1] + sz, sz / 36.0, sz / 36.0, 0.0, false, minf(1.0, op))
