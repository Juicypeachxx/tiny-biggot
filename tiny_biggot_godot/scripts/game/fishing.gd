class_name Fishing
extends RefCounted
## 15.1 Fishing (his ask, 7 Oct: "can you add fishing"). This game's own; expanded game only.
## A POND (EventRooms kind "e_pond") sits in some rest stops and treasure rooms: three casts.
##   CAST    the line goes out; wait for a bite (pressing USE now is too early: the fish flees)
##   BITE    a "!" over the float: press USE in time
##   REEL    a fish darts up and down a bar; hold USE to lift your box, let go to drop it. While
##           the fish is in the box the catch bar fills; outside it drains. Full: caught. Empty: lost.
## Each world has fish of its own; junk, treasure and rare fish turn up anywhere, a legendary one
## seldom (luck helps). Every catch does something at once. Kept between runs: Meta.meta["fish"].
## MENU lets go of the line.

const CASTS := 3
## id: [name, colour, rarity, difficulty, what it does, where (floor range) or [] for anywhere]
const FISH := {
	"mudfin": ["MUDFIN", "#7a5236", "common", 1.0, "HEALS HALF A HEART", []],
	"bonecarp": ["BONE CARP", "#d9d0b4", "common", 1.0, "6 GOLD", []],
	"glimmer": ["GLIMMER MINNOW", "#6fd3e0", "common", 0.9, "A GEM", []],
	"crypteel": ["CRYPT EEL", "#5c3483", "common", 1.2, "A POTION", [0, 3]],
	"embertrout": ["EMBER TROUT", "#e8873a", "common", 1.3, "HEALS A HEART AND 10 GOLD", [4, 7]],
	"gloompike": ["GLOOM PIKE", "#2a2838", "common", 1.4, "A STAT PICKUP", [8, 10]],
	"inkfish": ["INKFISH", "#2a2a4a", "common", 1.5, "A STAT PICKUP", [11, 13]],
	"pagepike": ["PAGE PIKE", "#f4ecd8", "common", 1.5, "25 GOLD", [14, 99]],
	"oldboot": ["OLD BOOT", "#4e4a5e", "junk", 0.6, "NOTHING. IT IS A BOOT", []],
	"rustkey": ["RUSTED KEY", "#a8705a", "junk", 0.7, "A KEY", []],
	"soddenscroll": ["SODDEN SCROLL", "#c8a878", "junk", 0.7, "A LITTLE EXPERIENCE", []],
	"goldcarp": ["GOLDEN CARP", "#f2c94c", "rare", 1.7, "40 GOLD", []],
	"armorbass": ["ARMORED BASS", "#8b8f9c", "rare", 1.7, "2 ARMOR", []],
	"sunkenchest": ["SUNKEN CHEST", "#8a6a4a", "rare", 1.5, "A PIECE OF GEAR", []],
	"moonkoi": ["MOONLIT KOI", "#c8f0ff", "legend", 2.2, "A RELIC AND FULL HEALTH", []],
	"oldone": ["THE OLD ONE", "#3f7a5a", "legend", 2.5, "A RELIC AND +1 MAX HEART", []],
}
const WEIGHT := { "common": 60, "junk": 22, "rare": 14, "legend": 4 }

static var pond: Dictionary = {}
static var phase := ""      # cast, bite, reel, done
static var t := 0.0
static var fish_id := ""
static var pos := 0.5        # the fish on the bar, 0 (bottom) .. 1 (top)
static var goal := 0.5
static var box := 0.3        # the bottom of your box
static var boxv := 0.0
static var prog := 0.0
static var result := ""      # what the last cast brought (shown under the bar)
static var fresh := false     # the first one of its kind ever

const BOX_H := 0.26
static var auto := false   # tests and --fish-auto: the line plays itself (strikes, follows the fish)

static func active() -> bool:
	return G.state == &"fishing"

## A pond in a room (game.gd setup_objects).
static func place(r: Room, x: float, y: float) -> void:
	r.objects.append({ "kind": "e_pond", "x": x, "y": y, "casts": CASTS })

## USE at the pond: cast.
static func start(o: Dictionary) -> void:
	if o.get("casts", 0) <= 0:
		G.toast("THE FISH HAVE GONE QUIET HERE", "grey")
		return
	pond = o
	o["casts"] -= 1
	if o["casts"] <= 0:
		o["used"] = true
	phase = "cast"
	t = 1.0 + randf() * 2.5
	result = ""
	G.state = &"fishing"
	Snd.play("dodge")

static func _pick() -> String:
	var f := G.floor_index
	var luck := G.player.luck if G.player != null else 0
	var w := {}
	for id in FISH:
		var d: Array = FISH[id]
		var where: Array = d[5]
		if not where.is_empty() and (f < where[0] or f > where[1]):
			continue
		var wt: float = WEIGHT[d[2]]
		if d[2] in ["rare", "legend"]:
			wt *= 1.0 + 0.25 * luck
		w[id] = wt
	return TB.weighted(w)

static func update(dt: float) -> void:
	if Keys.back():
		_finish("YOU LET GO OF THE LINE")
		return
	t -= dt
	match phase:
		"cast":
			if Keys.use():
				_finish("TOO SOON! THE FISH FLED")
			elif t <= 0:
				fish_id = _pick()
				phase = "bite"
				t = 0.75 if FISH[fish_id][2] != "legend" else 0.55
				Snd.play("bell")
		"bite":
			if Keys.use() or (auto and t < 0.5):
				phase = "reel"
				prog = 0.3
				pos = 0.5
				goal = randf()
				box = 0.35
				boxv = 0.0
				Snd.play("select")
			elif t <= 0:
				_finish("IT GOT AWAY")
		"reel":
			_reel(dt)
		"done":
			if t <= 0 or (Keys.use() and not auto):
				G.state = &"play"

static func _reel(dt: float) -> void:
	var diff: float = FISH[fish_id][3]
	# The fish darts toward a new spot now and then; harder fish more often and faster.
	if randf() < dt * (0.9 + diff * 0.6):
		goal = randf()
	pos = move_toward(pos, goal, dt * (0.35 + diff * 0.3))
	var hold := Keys.pressed(&"use") or (auto and pos > box + BOX_H * 0.5)
	boxv += (2.6 if hold else -2.2) * dt
	boxv = clampf(boxv, -1.4, 1.4)
	box += boxv * dt
	if box < 0.0:
		box = 0.0
		boxv = 0.0
	if box > 1.0 - BOX_H:
		box = 1.0 - BOX_H
		boxv = 0.0
	if pos >= box and pos <= box + BOX_H:
		prog += dt * 0.32
	else:
		prog -= dt * (0.16 + 0.06 * diff)
	if prog >= 1.0:
		_catch()
	elif prog <= 0.0:
		_finish("THE " + FISH[fish_id][0] + " SLIPPED THE HOOK")

static func _finish(msg: String) -> void:
	result = msg
	phase = "done"
	t = 1.2
	Snd.play("deny")

static func _catch() -> void:
	var d: Array = FISH[fish_id]
	if not (Meta.meta.get("fish") is Dictionary):
		Meta.meta["fish"] = {}
	fresh = not Meta.meta["fish"].has(fish_id)
	Meta.meta["fish"][fish_id] = int(Meta.meta["fish"].get(fish_id, 0)) + 1
	G.run_stats["fish"] = G.run_stats.get("fish", 0) + 1
	_reward(fish_id)
	result = ("NEW! " if fresh else "") + d[0] + ": " + d[4]
	phase = "done"
	t = 2.2
	Snd.play("relic" if d[2] == "legend" else ("unlock" if d[2] == "rare" else "coin"))
	var p := G.player
	Fx.burst(pond["x"], pond["y"], [d[1], "#ffffff", "#6fd3e0"], 18 if d[2] != "legend" else 34, 60)
	if d[2] == "legend":
		G.show_banner("A LEGEND FROM THE DEEP", d[0])
		G.add_shake(6)
	Meta.write_save()

static func _reward(id: String) -> void:
	var p := G.player
	var x: float = pond["x"]
	var y: float = pond["y"] + 18
	match id:
		"mudfin": p.heal(1)
		"bonecarp": _gold(6)
		"glimmer": Combat.drop_pickup("gem", x, y)
		"crypteel": Combat.drop_pickup("potion", x, y)
		"embertrout":
			p.heal(2)
			_gold(10)
		"gloompike", "inkfish": StatDrops.maybe(1.0, x, y)
		"pagepike": _gold(25)
		"oldboot": pass
		"rustkey": Combat.drop_pickup("key", x, y)
		"soddenscroll": Combat.drop_pickup("gem", x, y)
		"goldcarp": _gold(40)
		"armorbass":
			Combat.drop_pickup("armor", x, y)
			Combat.drop_pickup("armor", x, y)
		"sunkenchest": G.drop_item(Gear.random_gear(Gear.roll_item_rarity(G.floor_index, "elite")), x, y)
		"moonkoi", "oldone":
			var rel := G.roll_relics(1, "iron")
			if not rel.is_empty():
				G.add_relic(p, rel[0])
			if id == "moonkoi":
				p.hp = p.max_hp
			else:
				p.max_hp += 2
				p.hp += 2

static func _gold(n: int) -> void:
	G.player.gold += n
	G.run_stats["gold"] = G.run_stats.get("gold", 0) + n

## How many kinds have ever been caught.
static func caught_kinds() -> int:
	return (Meta.meta.get("fish", {}) as Dictionary).size() if Meta.meta.get("fish") is Dictionary else 0

# ---------- Drawing ----------
## The pond in the room (EventRooms.draw).
static func draw_pond(ci: CanvasItem, o: Dictionary, tm: float) -> void:
	var c := Vector2(o["x"], o["y"])
	var pts := PackedVector2Array()
	for i in 20:
		var a := i * TAU / 20.0
		pts.append(c + Vector2(cos(a) * 24.0, sin(a) * 12.0))
	ci.draw_colored_polygon(pts, TB.c("#2b4f8a"))
	ci.draw_polyline(pts + PackedVector2Array([pts[0]]), TB.c("#7a6a5a"), 2.0)
	for k in 2:
		var rr := fmod(tm * 0.6 + k * 0.5, 1.0)
		ci.draw_arc(c + Vector2(-6 + k * 10, -1), 3.0 + rr * 7.0, 0, TAU, 12, Color(0.75, 0.9, 1.0, 0.5 * (1.0 - rr)), 1.0)
	if active() and pond == o:
		var p := G.player
		var bob := c + Vector2(4, -1 + (sin(tm * 14) * 1.5 if phase == "bite" else sin(tm * 3)))
		ci.draw_line(Vector2(p.x + 7, p.y - 16), bob, TB.c("#f4ecd8"), 1.0)
		ci.draw_line(Vector2(p.x + 2, p.y - 8), Vector2(p.x + 7, p.y - 16), TB.c("#7a5236"), 2.0)   # the rod
		ci.draw_circle(bob, 2.0, TB.c("#d8443c"))
		if phase == "bite":
			Gfx.text(ci, "!", bob.x, bob.y - 14, "gold", 2, 0.5)
	elif o.get("casts", 0) > 0:
		Gfx.text(ci, "POND", c.x, c.y - 22, "cyan", 1, 0.5)

## The reel panel over the world (menu_view, state "fishing").
static func draw_panel(ci: CanvasItem) -> void:
	var x0 := TB.SW - 120
	var y0 := 40
	Gfx.panel(ci, x0, y0, 100, 170)
	Gfx.text(ci, "FISHING", x0 + 50, y0 + 6, "cyan", 1, 0.5)
	var bx := x0 + 14
	var by := y0 + 20
	var bh := 120
	ci.draw_rect(Rect2(bx, by, 16, bh), TB.c("#1e2238"))
	if phase == "reel":
		var bt := by + bh * (1.0 - box - BOX_H)
		ci.draw_rect(Rect2(bx + 1, bt, 14, bh * BOX_H), Color(0.39, 0.72, 0.31, 0.8))
		var fy := by + bh * (1.0 - pos)
		ci.draw_rect(Rect2(bx + 3, fy - 3, 10, 6), TB.c(FISH[fish_id][1]))
		ci.draw_rect(Rect2(bx + 3, fy - 3, 10, 1), TB.c("#ffffff"))
		# The catch bar.
		ci.draw_rect(Rect2(bx + 24, by, 6, bh), TB.c("#1a1423"))
		var ph := bh * clampf(prog, 0.0, 1.0)
		ci.draw_rect(Rect2(bx + 24, by + bh - ph, 6, ph), TB.c("#f2c94c"))
		Gfx.text(ci, "HOLD", x0 + 70, by + 30, "white", 1, 0.5)
		Gfx.text(ci, "USE", x0 + 70, by + 40, "gold", 1, 0.5)
		Gfx.text(ci, "TO RISE", x0 + 70, by + 50, "white", 1, 0.5)
	elif phase == "cast":
		Gfx.text(ci, "WAIT...", x0 + 50, by + 50, "white", 1, 0.5)
	elif phase == "bite":
		Gfx.text(ci, "BITE!", x0 + 50, by + 44, "gold", 2, 0.5)
		Gfx.text(ci, "PRESS USE", x0 + 50, by + 62, "white", 1, 0.5)
	var lines := Gfx.wrap_text(result, 88)
	for i in mini(3, lines.size()):
		Gfx.text(ci, lines[i], x0 + 50, y0 + 146 + i * 8 - (lines.size() - 1) * 4, "gold" if fresh and result.begins_with("NEW") else "white", 1, 0.5)
	Gfx.text(ci, "CASTS LEFT %d   MENU: STOP" % pond.get("casts", 0), TB.SW / 2, TB.SH - 30, "grey", 1, 0.5)
	Gfx.text(ci, "FISH FOUND %d OF %d" % [caught_kinds(), FISH.size()], TB.SW / 2, TB.SH - 20, "cyan", 1, 0.5)
