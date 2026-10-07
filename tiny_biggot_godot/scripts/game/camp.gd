class_name Camp
extends RefCounted
## 17.2 THE CAMP (his word, 7 Oct): a home between runs, walked about with your hero. Expanded game
## only; on the title menu. Nothing here is a run: no run is counted or saved, nothing can hurt you.
##   THE PORTAL       start a run (the hero screen)
##   THE ARCHIVIST    the story so far (story.gd)
##   THE ANGLER       his pond: fish without end; any world's fish can bite (they fill the fish wall)
##   THE WARDROBE     the WARDROBE page; an armour stand beside it for every set you ever completed
##   THE EMBER SHRINE the shrine's unlocks
##   THE TELESCOPE    the constellation
##   THE DUMMY        the skill trees
##   THE NOTICE BOARD runs, wins, deepest floor, trophies, fish
## What you have earned is furniture: a banner on the wall for every ending reached, a trophy cup on
## the shelf for every guardian felled (all heroes), the fish you have caught on the fish wall.
## MENU > LEAVE CAMP returns to the title.

const KINDS := ["c_portal", "c_wardrobe", "c_shrine", "c_telescope", "c_dummy", "c_board"]
## Endings: [Meta key, banner colour, name]
const ENDINGS := [["wins", "#f2c94c", "THE THRONE"], ["heaven_wins", "#fff07a", "HEAVEN"], ["hell_wins", "#d8443c", "HELL"],
	["unwritten_wins", "#f4ecd8", "THE UNWRITTEN"], ["author_wins", "#4d6aa8", "THE AUTHOR"],
	["redactor_wins", "#16141c", "THE REDACTOR"], ["reader_wins", "#a35bd6", "THE READER"]]

static func active() -> bool:
	return G.run_stats.get("camp", false) and G.room != null and G.room.type == "camp"

## The title's THE CAMP.
static func enter() -> void:
	var hero: Dictionary = GameData.heroes()[G.hero_index]
	G.player = Player.new(hero)
	Effects.reset_run_state()
	Weapons.equip_weapon(G.player, Weapons.by_id(Weapons.HERO_WEAPON[hero["id"]]))
	G.run_stats = { "kills": 0, "gold": 0, "time": 0.0, "floor": 1, "bosses": 0, "secrets": 0, "rifts": [], "camp": true }
	G.floor_index = 0
	G.loop = 0
	G.familiars = []
	G.temp_fams = []
	G.zones = []
	G.enemies.clear()
	G.floor_d = World.new_floor(0)
	var r := World.make_room(G.floor_d, "camp", "", "")
	r.kit = "kit1"
	r.exits.clear()
	r.doors.clear()
	G.enter_room(r)
	G.player.x = 224.0
	G.player.y = 196.0
	G.state = &"play"
	G.show_banner("THE CAMP", "REST, LOOK AROUND, AND SET OUT WHEN YOU ARE READY")
	Snd.music(0)

## The camp's people and things (game.gd setup_objects, room type "camp").
static func setup(r: Room) -> void:
	r.objects.append({ "kind": "c_portal", "x": 224.0, "y": 92.0 })
	r.objects.append({ "kind": "n_archivist", "x": 176.0, "y": 150.0 })
	var pond := Fishing.place(r, 92.0, 222.0, 52.0, 20.0, false, 9999)
	pond["camp"] = true
	r.objects.append({ "kind": "e_angler", "x": 160.0, "y": 238.0, "pond": pond, "rewarded": true })
	r.objects.append({ "kind": "c_wardrobe", "x": 372.0, "y": 120.0 })
	r.objects.append({ "kind": "c_shrine", "x": 352.0, "y": 222.0 })
	r.objects.append({ "kind": "c_telescope", "x": 70.0, "y": 92.0 })
	r.objects.append({ "kind": "c_dummy", "x": 124.0, "y": 118.0 })
	r.objects.append({ "kind": "c_board", "x": 300.0, "y": 70.0 })

static func interact(o: Dictionary) -> void:
	Snd.play("select")
	match o["kind"]:
		"c_portal":
			G.state = &"hero"
			G.menu = G.hero_index
			Snd.play("portal")
		"c_wardrobe":
			G.open_wardrobe(&"play")
		"c_shrine":
			G.state = &"shrine"
			G.menu = G.shrine_i
		"c_telescope":
			StarView.open()
		"c_dummy":
			G.state = &"tree"
			G.tree_hero = G.hero_index
			G.tree_b = 0
			G.tree_n = 0
		"c_board":
			var m := Meta.meta
			G.show_banner("THE NOTICE BOARD", "RUNS %d   WINS %d   DEEPEST FLOOR %d   EMBERS %d" % [m["runs"], m["wins"], m["best"], m["embers"]])

static func prompt(o: Dictionary) -> Array:
	match o["kind"]:
		"c_portal": return ["THE PORTAL", "SET OUT ON A NEW RUN", "GO"]
		"c_wardrobe": return ["THE WARDROBE", "EVERY SET, AND WHAT YOU HAVE FOUND", "OPEN"]
		"c_shrine": return ["THE EMBER SHRINE", "%d EMBERS TO SPEND" % Meta.meta["embers"], "PRAY"]
		"c_telescope": return ["THE TELESCOPE", "THE CONSTELLATION", "LOOK"]
		"c_dummy": return ["THE PRACTICE DUMMY", "THE SKILL TREES", "TRAIN"]
		"c_board": return ["THE NOTICE BOARD", "WHAT YOU HAVE DONE SO FAR", "READ"]
	return ["", "", ""]

## Where the title-menu screens go back to: the camp when they were opened from it.
static func back_state() -> StringName:
	return &"play" if active() else &"title"

static func pause_items() -> Array:
	return ["RESUME", "WARDROBE", "OPTIONS", "LEAVE CAMP"]

static func trophies_all() -> int:
	var n := 0
	for h in GameData.heroes():
		n += Trophies.count(h["id"])
	return n

# ---------- Drawing ----------
## The clearing, drawn once with the room (RoomDress.paint_static).
static func paint_static(ci: CanvasItem, room: Room, rng: SeedRng) -> void:
	# Grass, flowers, a dirt path from the portal to the fire.
	for i in 90:
		var p := Vector2(rng.int_range(24, 424), rng.int_range(40, 266))
		for g in 3:
			ci.draw_line(p + Vector2(g * 2 - 2, 0), p + Vector2(g * 2 - 3, -3 - g), TB.c("#5a9a4a" if i % 2 == 0 else "#4f7f45"), 1.0)
	for i in 30:
		var p := Vector2(rng.int_range(30, 418), rng.int_range(44, 262))
		ci.draw_rect(Rect2(p, Vector2(2, 2)), TB.c(["#f2c94c", "#e86fb4", "#f4ecd8", "#6fd3e0"][i % 4]))
	ci.draw_rect(Rect2(212, 104, 24, 30), TB.c("#6b5a3a"))
	ci.draw_rect(Rect2(214, 104, 20, 30), TB.c("#7a6a48"))
	# Trees round the edges.
	for spot in [Vector2(36, 60), Vector2(410, 58), Vector2(30, 160), Vector2(418, 186), Vector2(260, 258), Vector2(400, 258)]:
		ci.draw_rect(Rect2(spot.x - 2, spot.y - 6, 4, 10), TB.c("#5a3a22"))
		ci.draw_circle(spot + Vector2(0, -12), 11, TB.c("#2f6a3a"))
		ci.draw_circle(spot + Vector2(-4, -15), 7, TB.c("#3f8a4a"))
		ci.draw_circle(spot + Vector2(4, -10), 5, TB.c("#4f9a55"))
	# Log seats round the fire.
	for spot in [Vector2(224 - 30, 172), Vector2(224 + 30, 172), Vector2(224, 132)]:
		ci.draw_rect(Rect2(spot.x - 10, spot.y - 3, 20, 6), TB.c("#6b4a2a"))
		ci.draw_rect(Rect2(spot.x - 10, spot.y - 3, 20, 1), TB.c("#8a6a4a"))
	# The tent, behind the wardrobe.
	ci.draw_colored_polygon(PackedVector2Array([Vector2(300, 140), Vector2(328, 104), Vector2(356, 140)]), TB.c("#8a3a3a"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(318, 140), Vector2(328, 118), Vector2(338, 140)]), TB.c("#2a1a1a"))
	# The trophy shelf on the wall: a cup for every guardian ever felled (any hero).
	var cups := mini(24, trophies_all())
	ci.draw_rect(Rect2(110, 26, 228, 2), TB.c("#5a3a22"))
	for k in cups:
		var x := 114 + k * 9
		ci.draw_rect(Rect2(x, 20, 5, 4), TB.c("#f2c94c"))
		ci.draw_rect(Rect2(x + 1, 24, 3, 2), TB.c("#b8862a"))
		ci.draw_rect(Rect2(x, 20, 1, 3), TB.c("#fff07a"))
	# A banner for every ending ever reached.
	var bi := 0
	for e in ENDINGS:
		if Meta.meta.get(e[0], 0) > 0:
			var x := 120.0 + bi * 30.0
			RoomDress._banner(ci, x, TB.c(e[1]).darkened(0.25), TB.c("#f4ecd8"))
			bi += 1
	# The fish wall by the pond: every fish, dark until caught.
	var caught: Dictionary = Meta.meta["fish"] if Meta.meta.get("fish") is Dictionary else {}
	ci.draw_rect(Rect2(204, 238, 100, 32), TB.c("#5a3a22"))
	ci.draw_rect(Rect2(206, 240, 96, 28), TB.c("#7a5236"))
	var k2 := 0
	for id in Fishing.FISH:
		var fx := 214 + (k2 % 6) * 15
		var fy := 252 + (k2 / 6) * 10
		var spr := Fishing.sprite_of(id)
		Gfx.sp(ci, spr, fx, fy, 1, 1, 0.0, false, 1.0 if caught.has(id) else 0.6, Color(0, 0, 0, 0) if caught.has(id) else Color(0.2, 0.14, 0.1, 1))
		k2 += 1

## What moves (EventRooms.draw for the c_ kinds, and the fire).
static func draw(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x: float = o["x"]
	var y: float = o["y"]
	match o["kind"]:
		"c_portal":
			var zm := 2.2 + sin(t * 3) * 0.08
			Gfx.sp(ci, "riftdoor", x, y + 10, zm, zm)
			Gfx.text(ci, "SET OUT", x, y - 36, "gold", 1, 0.5)
		"c_wardrobe":
			ci.draw_rect(Rect2(x - 12, y - 30, 24, 32), TB.c("#5a3a22"))
			ci.draw_rect(Rect2(x - 11, y - 29, 22, 30), TB.c("#7a5236"))
			ci.draw_line(Vector2(x, y - 28), Vector2(x, y), TB.c("#4a3020"), 1.0)
			ci.draw_rect(Rect2(x - 3, y - 16, 2, 3), TB.c("#f2c94c"))
			ci.draw_rect(Rect2(x + 1, y - 16, 2, 3), TB.c("#f2c94c"))
			ci.draw_rect(Rect2(x - 13, y - 32, 26, 3), TB.c("#4a3020"))
			# An armour stand for every set ever completed (up to four).
			var n := mini(4, int(Meta.meta.get("sets_done", 0)))
			for k in n:
				var sx := x + 22 + k * 12
				ci.draw_rect(Rect2(sx - 1, y - 18, 2, 18), TB.c("#4a3020"))
				var col: String = ["#e8873a", "#6fd3e0", "#a35bd6", "#f2c94c"][k]
				ci.draw_rect(Rect2(sx - 4, y - 20, 8, 9), TB.c(col))
				ci.draw_rect(Rect2(sx - 3, y - 25, 6, 5), TB.c(col).darkened(0.2))
				ci.draw_rect(Rect2(sx - 4, y - 20, 8, 1), Color(1, 1, 1, 0.5))
		"c_shrine":
			Gfx.sp(ci, "altar", x, y + 4)
			var fl := 0.8 + 0.2 * sin(t * 9)
			ci.draw_rect(Rect2(x - 2, y - 18, 4, 5 * fl), Color(1.0, 0.55, 0.2))
			ci.draw_rect(Rect2(x - 1, y - 17, 2, 3 * fl), Color(1.0, 0.95, 0.5))
		"c_telescope":
			ci.draw_line(Vector2(x - 6, y), Vector2(x, y - 12), TB.c("#5a3a22"), 1.0)
			ci.draw_line(Vector2(x + 6, y), Vector2(x, y - 12), TB.c("#5a3a22"), 1.0)
			ci.draw_line(Vector2(x, y), Vector2(x, y - 12), TB.c("#5a3a22"), 1.0)
			ci.draw_line(Vector2(x - 6, y - 10), Vector2(x + 9, y - 20), TB.c("#c9a35a"), 3.0)
			ci.draw_line(Vector2(x - 6, y - 10), Vector2(x + 9, y - 20), TB.c("#f2c94c"), 1.0)
			if fmod(t, 2.0) < 0.2:
				ci.draw_rect(Rect2(x + 9, y - 22, 1, 1), Color(1, 1, 1))
		"c_dummy":
			Gfx.sp(ci, "dummy", x, y + 2)
		"c_board":
			ci.draw_rect(Rect2(x - 1, y - 6, 2, 12), TB.c("#4a3020"))
			ci.draw_rect(Rect2(x - 16, y - 22, 32, 18), TB.c("#7a5236"))
			ci.draw_rect(Rect2(x - 15, y - 21, 30, 16), TB.c("#c8a878"))
			for k in 4:
				ci.draw_rect(Rect2(x - 12, y - 18 + k * 4, 16 + (k * 5) % 8, 1), TB.c("#5a3a22"))
			ci.draw_rect(Rect2(x + 8, y - 20, 4, 4), TB.c("#d8443c"))

## The fire in the middle (RoomDress.paint_live adds its flames and light).
static func fire(rd_flames: Array, rd_lights: Array) -> void:
	rd_flames.append([224.0, 144.0, 3.0])
	rd_flames.append([220.0, 146.0, 2.0])
	rd_flames.append([228.0, 146.0, 2.0])
	rd_lights.append([224.0, 140.0, 1.6])
