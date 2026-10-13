class_name CampBuild
extends RefCounted
## 20.2 THE CAMP GROWS (his word, 8 Oct: "camp upgrades and quests"). THE CARPENTER at her
## workbench builds what you pay for in embers (the PLANS page); each thing built stands in the camp
## from then on and does its work (Meta.meta["camp_built"]: id -> true). Expanded game only.
##   LANTERNS          lanterns on posts round the fire. They do nothing but look lovely
##   THE FISH TRAP     every run that ends, the trap in the pond puts a fish in the larder
##   THE HERB GARDEN   every meal from the cook also gives +1 max heart
##   THE SMOKEHOUSE    the cook keeps two meals at once; both are eaten at the next run's start
##   THE GUEST TENT    a third visitor comes each time
##   THE MASTER'S RACK the training ground also holds every piece of armour, and whole sets
##   THE LENDING RACK  set out holding a weapon you have found before: it goes with you, in your pack

## id: [name, embers, what it does]
const PLANS := {
	"lanterns": ["LANTERNS", 40, "LANTERNS ON POSTS ROUND THE FIRE. THEY DO NOTHING BUT LOOK LOVELY."],
	"trap": ["THE FISH TRAP", 80, "EVERY RUN THAT ENDS, THE TRAP IN THE POND PUTS A FISH IN THE LARDER."],
	"garden": ["THE HERB GARDEN", 100, "EVERY MEAL FROM THE COOK ALSO GIVES +1 MAX HEART."],
	"smokehouse": ["THE SMOKEHOUSE", 120, "THE COOK KEEPS TWO MEALS AT ONCE. BOTH ARE EATEN AT THE START OF THE NEXT RUN."],
	"guesttent": ["THE GUEST TENT", 150, "A THIRD VISITOR COMES EACH TIME YOU ARE IN THE CAMP."],
	"masterrack": ["THE MASTER'S RACK", 150, "THE TRAINING GROUND ALSO HOLDS EVERY PIECE OF ARMOUR, AND WHOLE SETS TO TRY AT ONCE."],
	"lendingrack": ["THE LENDING RACK", 250, "SET OUT HOLDING A WEAPON YOU HAVE FOUND BEFORE AND IT GOES WITH YOU, IN YOUR PACK."],
}
const PLAN_Y0 := 44
const PLAN_DY := 15
const LANTERNS := [Vector2(150, 128), Vector2(300, 152), Vector2(186, 196), Vector2(264, 196), Vector2(104, 106)]

static var plan_i := 0
static var _rng := RandomNumberGenerator.new()

static func built(id: String) -> bool:
	return Meta.meta.get("camp_built") is Dictionary and (Meta.meta["camp_built"] as Dictionary).has(id)

static func built_n() -> int:
	return (Meta.meta["camp_built"] as Dictionary).size() if Meta.meta.get("camp_built") is Dictionary else 0

static func build(id: String) -> bool:
	var cost: int = PLANS[id][1]
	if built(id) or int(Meta.meta["embers"]) < cost:
		Snd.play("deny")
		return false
	if not (Meta.meta.get("camp_built") is Dictionary):
		Meta.meta["camp_built"] = {}
	Meta.meta["embers"] -= cost
	Meta.meta["camp_built"][id] = true
	Meta.write_save()
	Snd.play("unlock")
	if Camp.active():
		_place(G.room, id)
		CampLife.arm_list = []   # the master's rack: the list is built again with the armour
		G.room_changed.emit()     # the camp is drawn again with the new thing in it
		G.add_shake(3)
		for k in 14:
			Fx.particle(80.0 + randf() * 12.0, 140.0, (randf() - 0.5) * 30.0, -20.0 - randf() * 30.0, 0.8, "#c8a878", 2)
	return true

# ---------- In the camp ----------
## Camp.setup: the carpenter, and what she has built that moves (drawn by draw()).
static func setup(r: Room) -> void:
	r.objects.append({ "kind": "c_build", "x": 66.0, "y": 146.0 })
	for id in PLANS:
		if built(id):
			_place(r, id)

static func _place(r: Room, id: String) -> void:
	match id:
		"smokehouse":
			r.objects.append({ "kind": "c_deco", "what": "smoke", "x": 272.0, "y": 124.0, "used": true })
		"lanterns":
			for v in LANTERNS:
				r.objects.append({ "kind": "c_deco", "what": "lantern", "x": v.x, "y": v.y, "used": true })
		"trap":
			r.objects.append({ "kind": "c_deco", "what": "trap", "x": 138.0, "y": 228.0, "used": true })
		"guesttent":
			r.objects.append({ "kind": "c_deco", "what": "tent", "x": 366.0, "y": 170.0, "used": true })
		"masterrack":
			r.objects.append({ "kind": "c_deco", "what": "stand", "x": 346.0, "y": 250.0, "used": true })
		"lendingrack":
			r.objects.append({ "kind": "c_deco", "what": "chest", "x": 364.0, "y": 262.0, "used": true })
		"garden":
			r.objects.append({ "kind": "c_deco", "what": "garden", "x": 148.0, "y": 132.0, "used": true })

## The lanterns' light (RoomDress paint_live / glow, with the fire's).
static func lights(rd_lights: Array) -> void:
	if built("lanterns"):
		for v in LANTERNS:
			rd_lights.append([v.x, v.y - 14.0, 0.7])

static func interact(_o: Dictionary) -> void:
	G.state = &"plans"
	G.menu = plan_i
	Snd.play("select")

static func prompt(_o: Dictionary) -> Array:
	var left := PLANS.size() - built_n()
	if left == 0:
		return ["THE CARPENTER", "\"NOTHING LEFT TO BUILD. IT IS A FINE CAMP NOW.\"", "LOOK"]
	return ["THE CARPENTER", "%d THINGS SHE COULD BUILD FOR THE CAMP" % left, "PLANS"]

## The lending rack: setting out from the camp (the portal) with a weapon found before.
static func on_set_out() -> void:
	Meta.meta.erase("lend")
	if not built("lendingrack") or G.player == null:
		return
	var w: Dictionary = G.player.weapon
	var own: String = Weapons.HERO_WEAPON.get(G.player.hero["id"], "")
	if w["id"] != own and (Meta.meta["found_w"] as Dictionary).has(w["id"]):
		Meta.meta["lend"] = w["id"]

## A run ends (G.award_embers): the fish trap catches something.
static func on_run_end() -> void:
	if not built("trap") or G.run_stats.get("camp", false):
		return
	_rng.randomize()
	var pool: Array = []
	for f in Fishing.FISH:
		var rar: String = Fishing.FISH[f][2]
		for k in { "common": 6, "junk": 3, "rare": 1, "legend": 0 }[rar]:
			pool.append(f)
	var got: String = pool[_rng.randi_range(0, pool.size() - 1)]
	CampLife.stock(got)
	Meta.meta["trap_news"] = Fishing.FISH[got][0]

# ---------- Drawing ----------
static func draw(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x: float = o["x"]
	var y: float = o["y"]
	if o["kind"] == "c_build":
		# The workbench: a plank on trestles, a saw, planks leaning, and the carpenter beside it.
		ci.draw_rect(Rect2(x - 22, y - 4, 2, 6), TB.c("#4a3020"))
		ci.draw_rect(Rect2(x + 4, y - 4, 2, 6), TB.c("#4a3020"))
		ci.draw_rect(Rect2(x - 24, y - 8, 32, 4), TB.c("#a8705a"))
		ci.draw_rect(Rect2(x - 24, y - 8, 32, 1), TB.c("#c8a878"))
		ci.draw_rect(Rect2(x - 18, y - 12, 10, 4), TB.c("#c8ccd8"))
		for k in 5:
			ci.draw_rect(Rect2(x - 18 + k * 2, y - 9, 1, 1), TB.c("#6b6a72"))
		ci.draw_line(Vector2(x - 34, y + 2), Vector2(x - 28, y - 18), TB.c("#c8a878"), 2.0)
		ci.draw_line(Vector2(x - 30, y + 2), Vector2(x - 25, y - 16), TB.c("#a8705a"), 2.0)
		Gfx.sp(ci, "npc_carpenter", x + 16, y + 2, 1, 1, 0.0, true)
		Gfx.text(ci, "CARPENTER", x + 2, y - 28, "tan", 1, 0.5)
		return
	match o["what"]:
		"smoke":
			for k in 4:
				var st := fmod(t * 0.5 + k * 0.25, 1.0)
				ci.draw_rect(Rect2(x + 5 + sin(t + k) * 2.0 + st * 4.0, y - 22 - st * 18.0, 3, 3), Color(0.8, 0.8, 0.8, 0.4 * (1.0 - st)))
		"lantern":
			var fl := 0.85 + 0.15 * sin(t * 7.0 + x)
			ci.draw_rect(Rect2(x - 1, y - 12, 2, 12), TB.c("#4a3020"))
			ci.draw_rect(Rect2(x - 3, y - 18, 6, 6), TB.c("#5a3a22"))
			ci.draw_rect(Rect2(x - 2, y - 17, 4, 4), Color(1.0, 0.75 * fl, 0.3, 1))
		"tent":
			pass   # drawn with the room (paint_static)
		"trap", "stand", "chest", "garden":
			if o["what"] == "garden":
				for k in 6:   # the herbs sway
					var hx := x - 14 + k * 6
					ci.draw_line(Vector2(hx, y), Vector2(hx + sin(t * 2.0 + k) * 1.5, y - 5), TB.c("#7ab04a"), 1.0)
					ci.draw_rect(Rect2(hx + sin(t * 2.0 + k) * 1.5 - 1, y - 7, 2, 2), TB.c(["#e86fb4", "#f2c94c", "#f4ecd8"][k % 3]))

## Where each thing stands in the camp (the PLANS page draws it from there, twice the size).
const SPOT := { "lanterns": Vector2(150, 122), "trap": Vector2(138, 226), "garden": Vector2(148, 128),
	"smokehouse": Vector2(272, 114), "guesttent": Vector2(366, 160), "masterrack": Vector2(346, 238),
	"lendingrack": Vector2(364, 256) }

## What is built that stands still, drawn once with the room (Camp.paint_static).
static func paint_static(ci: CanvasItem) -> void:
	for id in PLANS:
		if built(id):
			_still(ci, id)

## One thing that stands still, at its place in the camp.
static func _still(ci: CanvasItem, id: String) -> void:
	if id == "smokehouse":
		var x := 272.0
		var y := 124.0
		ci.draw_rect(Rect2(x - 10, y - 16, 20, 16), TB.c("#5a3a22"))
		ci.draw_rect(Rect2(x - 9, y - 15, 18, 14), TB.c("#7a5236"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 12, y - 16), Vector2(x, y - 25), Vector2(x + 12, y - 16)]), TB.c("#4a3020"))
		ci.draw_rect(Rect2(x + 4, y - 26, 4, 6), TB.c("#6b6a72"))
		ci.draw_rect(Rect2(x - 3, y - 9, 6, 9), TB.c("#2a1a12"))
		for k in 3:   # fish hanging to smoke
			ci.draw_rect(Rect2(x - 8 + k * 3, y - 13, 2, 4), TB.c(["#e8873a", "#c8a878", "#8b8f9c"][k]))
	if id == "trap":
		ci.draw_colored_polygon(PackedVector2Array([Vector2(130, 224), Vector2(146, 220), Vector2(146, 232)]), TB.c("#a8705a"))
		for k in 3:
			ci.draw_line(Vector2(132 + k * 5, 223 - k), Vector2(132 + k * 5, 230 + k), TB.c("#6b4a2a"), 1.0)
		ci.draw_rect(Rect2(146, 218, 1, 16), TB.c("#5a3a22"))
	if id == "guesttent":
		var x := 366.0
		var y := 170.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 14, y), Vector2(x, y - 20), Vector2(x + 14, y)]), TB.c("#f4ecd8"))
		for k in 3:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 14 + k * 9.3, y), Vector2(x - 2 + k * 2, y - 20 + 0.0), Vector2(x - 10 + k * 9.3, y)]), TB.c("#d8443c"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 4, y), Vector2(x, y - 9), Vector2(x + 4, y)]), TB.c("#2a1a1a"))
		ci.draw_rect(Rect2(x - 1, y - 24, 1, 5), TB.c("#5a3a22"))
		ci.draw_rect(Rect2(x, y - 24, 4, 2), TB.c("#f2c94c"))
	if id == "masterrack":
		var x := 346.0
		var y := 250.0
		ci.draw_rect(Rect2(x - 1, y - 20, 2, 20), TB.c("#4a3020"))
		ci.draw_rect(Rect2(x - 6, y - 22, 12, 10), TB.c("#8b8f9c"))
		ci.draw_rect(Rect2(x - 5, y - 21, 10, 2), TB.c("#c8ccd8"))
		ci.draw_rect(Rect2(x - 4, y - 28, 8, 6), TB.c("#6b6a72"))
		ci.draw_rect(Rect2(x - 2, y - 26, 4, 1), TB.c("#2a2838"))
		ci.draw_rect(Rect2(x - 10, y - 12, 6, 8), TB.c("#4d6aa8"))
		ci.draw_rect(Rect2(x - 9, y - 11, 4, 1), TB.c("#f2c94c"))
	if id == "lendingrack":
		var x := 364.0
		var y := 262.0
		ci.draw_rect(Rect2(x - 9, y - 9, 18, 9), TB.c("#5a3a22"))
		ci.draw_rect(Rect2(x - 8, y - 8, 16, 3), TB.c("#7a5236"))
		ci.draw_rect(Rect2(x - 9, y - 5, 18, 1), TB.c("#f2c94c"))
		ci.draw_rect(Rect2(x - 1, y - 6, 2, 3), TB.c("#f2c94c"))
	if id == "garden":
		ci.draw_rect(Rect2(130, 126, 36, 10), TB.c("#5a3a22"))
		ci.draw_rect(Rect2(131, 127, 34, 8), TB.c("#4a3a2a"))
		for k in 3:
			ci.draw_rect(Rect2(132, 128 + k * 3, 32, 1), TB.c("#3a2a1e"))

# ---------- The PLANS page (state "plans") ----------
static func update_plans() -> void:
	var ids: Array = PLANS.keys()
	var go := G.menu_nav(ids.size())
	plan_i = G.menu
	if go:
		var id: String = ids[plan_i]
		if built(id):
			Snd.play("deny")
		elif build(id):
			G.show_banner("THE CARPENTER: \"DONE BY MORNING.\"", PLANS[id][0] + ": " + PLANS[id][2])
			G.state = &"play"
	elif Keys.back():
		G.state = &"play"
		Snd.play("select")

static func draw_plans(ci: CanvasItem) -> void:
	Gfx.text(ci, "THE CARPENTER'S PLANS", TB.SW / 2, 10, "gold", 2, 0.5)
	Gfx.text(ci, "EMBERS: %d   BUILT: %d OF %d" % [Meta.meta["embers"], built_n(), PLANS.size()], TB.SW / 2, 28, "tan", 1, 0.5)
	var ids: Array = PLANS.keys()
	for i in ids.size():
		var y := PLAN_Y0 + i * PLAN_DY
		var sel := i == plan_i
		var id: String = ids[i]
		if sel:
			ci.draw_rect(Rect2(10, y - 4, 180, PLAN_DY - 2), TB.rgba(232, 135, 58, 46))
		var have := built(id)
		Gfx.text(ci, PLANS[id][0], 16, y, "gold" if sel else ("lime" if have else "white"))
		Gfx.text(ci, "BUILT" if have else "%d" % PLANS[id][1], 186, y, "lime" if have else ("white" if int(Meta.meta["embers"]) >= PLANS[id][1] else "dim"), 1, 1)
	var id: String = ids[plan_i]
	var x0 := 204
	Gfx.text(ci, PLANS[id][0], x0, 46, "gold", 2)
	var y := 64
	for l in Gfx.wrap_text(PLANS[id][2], 230):
		Gfx.text(ci, l, x0, y, "white")
		y += 10
	y += 8
	if built(id):
		Gfx.text(ci, "BUILT. IT STANDS IN THE CAMP NOW", x0, y, "lime")
	elif int(Meta.meta["embers"]) >= PLANS[id][1]:
		Gfx.text(ci, "USE: BUILD IT FOR %d EMBERS" % PLANS[id][1], x0, y, "gold")
	else:
		Gfx.text(ci, "%d EMBERS. YOU HAVE %d" % [PLANS[id][1], Meta.meta["embers"]], x0, y, "dim")
	# A picture of it, twice the size.
	var box := Rect2(x0, 150, 200, 96)
	ci.draw_rect(box, TB.c("#2e4a2a"))
	ci.draw_rect(Rect2(box.position, Vector2(box.size.x, 1)), TB.c("#c8a878"))
	ci.draw_rect(Rect2(box.position + Vector2(0, box.size.y - 1), Vector2(box.size.x, 1)), TB.c("#c8a878"))
	var c := box.get_center() + Vector2(0, 8)
	ci.draw_set_transform(c - SPOT[id] * 2.0, 0.0, Vector2(2, 2))
	_still(ci, id)
	var v: Vector2 = SPOT[id]
	match id:
		"smokehouse":
			draw(ci, { "kind": "c_deco", "what": "smoke", "x": 272.0, "y": 124.0 }, G.time)
		"lanterns":
			for k in 3:
				draw(ci, { "kind": "c_deco", "what": "lantern", "x": v.x - 24.0 + k * 24.0, "y": v.y + 10.0 }, G.time)
		"garden":
			draw(ci, { "kind": "c_deco", "what": "garden", "x": 148.0, "y": 132.0 }, G.time)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Gfx.text(ci, "MENU: BACK", TB.SW / 2, 266, "dim", 1, 0.5)
