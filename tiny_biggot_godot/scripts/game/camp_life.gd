class_name CampLife
extends RefCounted
## 19.2 More life in THE CAMP (his word, 7 Oct: "visitors who come and go, a cook who turns your fish
## into buffs for the next run, a training room with the dummy that tests any item").
##   THE COOK         by the fire. Fish from your larder (every fish you catch, anywhere, goes in it)
##                    become one meal, eaten at the start of your next run (the KITCHEN page).
##   VISITORS         two of four come by each time you enter the camp:
##                    THE PEDDLER     one relic for embers, waiting for you at the next run's start
##                    THE BARD        a song for the road: +10% speed and +10% gold next run
##                    THE SEER        tomorrow's daily trial, and a fortune
##                    THE FISHMONGER  buys the fish you have more than enough of, for embers
##   THE STRAY        a cat by the fire. Pet it; it follows you a while. Pet it 10 times and it stays.
##   THE TRAINING GROUND  three dummies and a rack: any weapon or relic in the game, tried in the camp
##                    only (the ARMORY page). Nothing tried there counts as found.
## Meta.meta: "larder" (fish id -> n), "meal", "song", "next_relic", "cat_pets". None of it
## exists in a fresh save, so the replays and tests are untouched.

const KINDS := ["c_cook", "c_rack", "v_peddler", "v_bard", "v_seer", "v_monger", "v_cat"]

## id: [name, what it does, needs]. A need is a fish id or a rarity (any fish of it): count.
const MEALS := {
	"soup": ["FISH SOUP", "+1 MAX HEART", { "common": 2 }],
	"eel": ["GRILLED EEL", "+15% DAMAGE", { "crypteel": 1, "common": 1 }],
	"chowder": ["EMBER CHOWDER", "+15% FIRE RATE", { "embertrout": 2 }],
	"pie": ["INKFISH PIE", "+10% CRIT CHANCE", { "inkfish": 1, "gloompike": 1 }],
	"fillet": ["GOLDEN FILLET", "+50% GOLD, AND 30 GOLD TO START", { "goldcarp": 1 }],
	"stew": ["IRON STEW", "+3 ARMOR", { "armorbass": 1, "common": 1 }],
	"broth": ["BOOT BROTH", "A KEY AND A BOMB. IT TASTES OF BOOT", { "junk": 2 }],
	"feast": ["THE MOONLIT FEAST", "A RELIC, +1 MAX HEART AND +10% DAMAGE", { "legend": 1, "common": 3 }],
}
const RARITY_WORD := { "common": "COMMON FISH", "rare": "RARE FISH", "legend": "LEGENDARY FISH", "junk": "JUNK" }

## id: [name, sprite, label over the head]
const VISITORS := {
	"v_peddler": ["THE PEDDLER", "npc_peddler", "PEDDLER"],
	"v_bard": ["THE BARD", "npc_bard", "BARD"],
	"v_seer": ["THE SEER", "npc_seer", "SEER"],
	"v_monger": ["THE FISHMONGER", "npc_monger", "FISHMONGER"],
}
const SPOTS := [Vector2(112, 178), Vector2(262, 210)]
const RELIC_PRICE := { "common": 30, "rare": 60, "epic": 100, "legend": 160 }
## Embers the fishmonger pays for one spare fish, by rarity. He leaves you 3 of each kind.
const MONGER_PAY := { "junk": 1, "common": 2, "rare": 8, "legend": 25 }
const MONGER_KEEP := 3
const CAT_NAME := "SOOT"
const CAT_STAYS := 10
const FORTUNES := [
	"\"A DOOR WILL OPEN WHERE YOU EXPECT A WALL.\"",
	"\"SOMETHING GREEN AND HUNGRY WAITS ON THE THIRD FLOOR.\"",
	"\"YOU WILL CARRY TOO MUCH GOLD, AND IT WILL NOT BE ENOUGH.\"",
	"\"THE BOOK REMEMBERS EVERY HERO. EVEN THE SHORT ONES.\"",
	"\"A KEG, A SPARK, A GOOD DAY.\"",
	"\"THE OLD ONE IN THE POND DREAMS OF YOU. DO NOT ASK WHY.\"",
	"\"SIX PIECES MAKE A LEGEND. FOUR MAKE A STORY.\"",
	"\"THE CAT KNOWS. THE CAT ALWAYS KNOWS.\"",
]
const ARM_Y0 := 34
const ARM_DY := 11
const ARM_ROWS := 20
const KIT_Y0 := 40
const KIT_DY := 14

static var arm_list: Array = []    # ["reset"] then ["w", weapon] ... then ["r", relic] ...
static var arm_i := 0
static var kit_i := 0

# ---------- The larder ----------
static func larder() -> Dictionary:
	if not (Meta.meta.get("larder") is Dictionary):
		# The first time: everything caught so far is in it.
		Meta.meta["larder"] = (Meta.meta["fish"] as Dictionary).duplicate() if Meta.meta.get("fish") is Dictionary else {}
	return Meta.meta["larder"]

## Fishing._catch: every fish caught goes in the larder.
static func stock(fish_id: String) -> void:
	var l := larder()
	l[fish_id] = int(l.get(fish_id, 0)) + 1

static func larder_total() -> int:
	var n := 0
	for k in larder():
		n += int(larder()[k])
	return n

## What a meal would take from the larder (fish id -> n), or {} when there is not enough.
static func plan(meal_id: String) -> Dictionary:
	var have := larder().duplicate()
	var take := {}
	var needs: Dictionary = MEALS[meal_id][2]
	for k in needs:
		if Fishing.FISH.has(k):
			if int(have.get(k, 0)) < int(needs[k]):
				return {}
			have[k] = int(have[k]) - int(needs[k])
			take[k] = int(needs[k])
	for k in needs:
		if Fishing.FISH.has(k):
			continue
		for n in int(needs[k]):
			var best := ""
			for f in have:
				if Fishing.FISH.has(f) and Fishing.FISH[f][2] == k and int(have[f]) > 0 and (best == "" or int(have[f]) > int(have[best])):
					best = f
			if best == "":
				return {}
			have[best] = int(have[best]) - 1
			take[best] = int(take.get(best, 0)) + 1
	return take

static func _need_have(k: String) -> int:
	if Fishing.FISH.has(k):
		return int(larder().get(k, 0))
	var n := 0
	for f in larder():
		if Fishing.FISH.has(f) and Fishing.FISH[f][2] == k:
			n += int(larder()[f])
	return n

static func cook(meal_id: String) -> bool:
	var take := plan(meal_id)
	if take.is_empty():
		Snd.play("deny")
		return false
	var l := larder()
	for f in take:
		l[f] = int(l[f]) - int(take[f])
		if int(l[f]) <= 0:
			l.erase(f)
	Meta.meta["meal"] = meal_id
	Meta.write_save()
	Snd.play("heal")
	for i in 10:
		Fx.particle(250.0 + randf() * 10.0, 140.0, (randf() - 0.5) * 10.0, -20.0 - randf() * 20.0, 1.2, "#f4ecd8", 2)
	return true

# ---------- A run begins (game.gd new_run) ----------
## The meal, the song and the peddler's parcel. Not on the daily trial (it is the same run for
## everyone): they wait for the next ordinary run.
static func on_new_run(p: Player) -> void:
	if not GameData.rogues() or Daily.starting:
		return
	var got: Array = []
	var meal: String = Meta.meta.get("meal", "")
	if MEALS.has(meal):
		match meal:
			"soup":
				p.max_hp += 2
				p.hp += 2
			"eel":
				p.dmg *= 1.15
			"chowder":
				p.rate *= 1.15
			"pie":
				p.crit += 0.10
			"fillet":
				p.gold_mult *= 1.5
				p.gold += 30
			"stew":
				p.armor += 3
			"broth":
				p.keys += 1
				p.bombs += 1
			"feast":
				p.max_hp += 2
				p.hp += 2
				p.dmg *= 1.1
				var r := G.roll_relics(1, "iron")
				if not r.is_empty():
					G.add_relic(p, r[0])
		got.append(MEALS[meal][0])
		Meta.meta.erase("meal")
	if Meta.meta.get("song", false):
		p.speed *= 1.1
		p.gold_mult *= 1.1
		got.append("THE BARD'S SONG")
		Meta.meta.erase("song")
	var nr: String = Meta.meta.get("next_relic", "")
	if nr != "":
		Meta.meta.erase("next_relic")
		for r in Relics.all():
			if r["id"] == nr:
				G.add_relic(p, r)
				got.append(r["name"])
	if not got.is_empty():
		G.toast("FROM THE CAMP: " + ", ".join(got), "gold")

# ---------- Setting up (Camp.setup / Camp.enter) ----------
static func setup(r: Room) -> void:
	r.objects.append({ "kind": "c_cook", "x": 258.0, "y": 150.0 })
	r.objects.append({ "kind": "c_rack", "x": 364.0, "y": 246.0 })
	var ids: Array = VISITORS.keys()
	ids.shuffle()
	for i in 2:
		var o := { "kind": ids[i], "x": SPOTS[i].x, "y": SPOTS[i].y, "face": 1 if SPOTS[i].x < 224.0 else -1 }
		if ids[i] == "v_peddler":
			var rr := G.roll_relics(1, "iron")
			if not rr.is_empty():
				o["relic"] = rr[0]
		r.objects.append(o)
	# The stray: most visits, and always once it has stayed.
	if int(Meta.meta.get("cat_pets", 0)) >= CAT_STAYS or randf() < 0.7:
		r.objects.append({ "kind": "v_cat", "x": 204.0, "y": 160.0, "home": Vector2(204, 160), "follow_t": 0.0, "face": 1 })

## The training ground's dummies (enemies: they show your damage per second).
static func spawn_dummies() -> void:
	for spot in [Vector2(396, 214), Vector2(424, 214), Vector2(410, 244)]:
		var d := Combat.spawn_enemy("dummy", spot.x, spot.y, false, true)
		d.max_hp = 1e6
		d.hp = 1e6
		d.spawn_t = 0.0

# ---------- Every frame in the camp (EventRooms.update) ----------
static func tick(dt: float) -> void:
	if not Camp.active():
		return
	var p := G.player
	for o in G.room.objects:
		if o["kind"] == "v_bard" and o.get("play_t", 0.0) > 0.0:
			o["play_t"] -= dt
		if o["kind"] != "v_cat":
			continue
		var target: Vector2 = o["home"]
		if o["follow_t"] > 0.0:
			o["follow_t"] -= dt
			target = Vector2(p.x - 14.0 * p.face, p.y + 4.0)
			if o["follow_t"] <= 0.0:
				o["home"] = Vector2(o["x"], o["y"])   # it naps wherever it got to
				o["used"] = false
		var dx: float = target.x - o["x"]
		var dy: float = target.y - o["y"]
		var d := sqrt(dx * dx + dy * dy)
		o["moving"] = d > 6.0
		if d > 6.0:
			var sp := minf(d * 3.0, 90.0)
			o["x"] += dx / d * sp * dt
			o["y"] += dy / d * sp * dt
			o["face"] = 1 if dx > 0 else -1

# ---------- Interacting ----------
static func interact(o: Dictionary) -> void:
	match o["kind"]:
		"c_cook":
			G.state = &"kitchen"
			G.menu = kit_i
			Snd.play("select")
		"c_rack":
			open_armory()
		"v_peddler":
			if not o.has("relic") or o.get("sold", false):
				return
			var r: Dictionary = o["relic"]
			var price: int = RELIC_PRICE.get(r["rarity"], 60)
			if int(Meta.meta["embers"]) < price:
				G.deny(o, "NOT ENOUGH EMBERS")
				return
			Meta.meta["embers"] -= price
			Meta.meta["next_relic"] = r["id"]
			o["sold"] = true
			Meta.write_save()
			Snd.play("coin")
			G.show_banner("THE PEDDLER: \"A FINE CHOICE.\"", r["name"] + " WILL BE WAITING AT THE START OF YOUR NEXT RUN")
		"v_bard":
			o["play_t"] = 4.0
			Snd.play("bell")
			if not Meta.meta.get("song", false):
				Meta.meta["song"] = true
				Meta.write_save()
				G.show_banner("THE BARD: A SONG FOR THE ROAD", "+10% SPEED AND +10% GOLD ON YOUR NEXT RUN")
			else:
				G.toast("THE BARD PLAYS IT AGAIN. IT IS STILL A GOOD SONG", "white")
		"v_seer":
			var day := Daily.tomorrow()
			var m := Daily.mod_for(day)
			var h: Dictionary = GameData.heroes()[Daily.hero_for(day)]
			o["talks"] = int(o.get("talks", 0)) + 1
			Snd.play("portal")
			G.show_banner("TOMORROW'S TRIAL: " + Daily.MODS[m][0] + ", " + h["name"], FORTUNES[(o["talks"] + day) % FORTUNES.size()])
		"v_monger":
			var sale := monger_offer()
			if sale[0] == 0:
				G.deny(o, "NOTHING SPARE")
				return
			var l := larder()
			for f in l.keys():
				if int(l[f]) > MONGER_KEEP:
					l[f] = MONGER_KEEP
			Meta.meta["embers"] += sale[1]
			Meta.write_save()
			Snd.play("coin")
			G.show_banner("THE FISHMONGER: \"PLEASURE DOING BUSINESS.\"", "%d FISH SOLD FOR %d EMBERS" % [sale[0], sale[1]])
		"v_cat":
			Meta.meta["cat_pets"] = int(Meta.meta.get("cat_pets", 0)) + 1
			o["follow_t"] = 10.0
			o["used"] = true   # while it follows you it is not in the way of the USE button
			for i in 5:
				Fx.particle(o["x"] + (randf() - 0.5) * 8.0, o["y"] - 8.0, (randf() - 0.5) * 12.0, -24.0 - randf() * 12.0, 0.9, "#e86fb4", 2)
			Snd.play("heal")
			if int(Meta.meta["cat_pets"]) == CAT_STAYS:
				G.show_banner("THE STRAY STAYS", "THE CAT HAS A NAME NOW: " + CAT_NAME + ". IT LIVES IN THE CAMP")
			Meta.write_save()

## [fish sold, embers]: everything past MONGER_KEEP of each kind.
static func monger_offer() -> Array:
	var n := 0
	var e := 0
	for f in larder():
		var extra := int(larder()[f]) - MONGER_KEEP
		if extra > 0 and Fishing.FISH.has(f):
			n += extra
			e += extra * int(MONGER_PAY.get(Fishing.FISH[f][2], 1))
	return [n, e]

static func prompt(o: Dictionary) -> Array:
	match o["kind"]:
		"c_cook":
			var m: String = Meta.meta.get("meal", "")
			return ["THE COOK", ("ON THE FIRE: " + MEALS[m][0] + ". " if MEALS.has(m) else "") + "%d FISH IN THE LARDER" % larder_total(), "COOK"]
		"c_rack":
			return ["THE TRAINING GROUND", "TRY ANY WEAPON OR RELIC ON THE DUMMIES", "CHOOSE"]
		"v_peddler":
			if not o.has("relic"):
				return ["THE PEDDLER", "\"SOLD OUT, FRIEND. NEXT TIME.\"", ""]
			var r: Dictionary = o["relic"]
			if o.get("sold", false):
				return ["THE PEDDLER", "\"IT WILL BE WAITING FOR YOU.\"", ""]
			return ["THE PEDDLER: " + r["name"], r["desc"], "BUY FOR YOUR NEXT RUN: %d EMBERS" % RELIC_PRICE.get(r["rarity"], 60)]
		"v_bard":
			return ["THE BARD", "A SONG FOR THE ROAD: +10% SPEED AND GOLD NEXT RUN", "LISTEN"]
		"v_seer":
			return ["THE SEER", "SHE SEES TOMORROW'S TRIAL, AND A LITTLE MORE", "ASK"]
		"v_monger":
			var s := monger_offer()
			if s[0] == 0:
				return ["THE FISHMONGER", "HE BUYS WHAT YOU HAVE MORE THAN %d OF. YOU HAVE NOTHING SPARE" % MONGER_KEEP, ""]
			return ["THE FISHMONGER", "%d SPARE FISH (YOU KEEP %d OF EACH KIND)" % [s[0], MONGER_KEEP], "SELL: %d EMBERS" % s[1]]
		"v_cat":
			var n := int(Meta.meta.get("cat_pets", 0))
			if n >= CAT_STAYS:
				return [CAT_NAME, "THE CAMP'S CAT. PETTED %d TIMES" % n, "PET"]
			return ["A STRAY CAT", "IT LOOKS AT YOU. IT LOOKS AT THE FIRE", "PET"]
	return ["", "", ""]

# ---------- Drawing ----------
static func draw(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x: float = o["x"]
	var y: float = o["y"]
	match o["kind"]:
		"c_cook":
			# A pot on a tripod over the fire's edge, steam, and the cook beside it.
			ci.draw_line(Vector2(x - 20, y - 2), Vector2(x - 14, y - 16), TB.c("#4a3020"), 1.0)
			ci.draw_line(Vector2(x - 8, y - 2), Vector2(x - 14, y - 16), TB.c("#4a3020"), 1.0)
			ci.draw_rect(Rect2(x - 19, y - 10, 10, 7), TB.c("#2a2838"))
			ci.draw_rect(Rect2(x - 18, y - 10, 8, 1), TB.c("#6b6a72"))
			ci.draw_rect(Rect2(x - 18, y - 11, 8, 1), TB.c("#c8a878") if Meta.meta.has("meal") else TB.c("#3a3850"))
			for k in 3:
				var st := fmod(t * 0.7 + k * 0.33, 1.0)
				ci.draw_rect(Rect2(x - 15 + sin(t * 2 + k) * 2.0, y - 13 - st * 14.0, 2, 2), Color(1, 1, 1, 0.35 * (1.0 - st)))
			Gfx.sp(ci, "npc_cook", x + 2, y + 2, 1, 1, 0.0, true)
		"c_rack":
			ci.draw_rect(Rect2(x - 12, y - 18, 2, 18), TB.c("#5a3a22"))
			ci.draw_rect(Rect2(x + 10, y - 18, 2, 18), TB.c("#5a3a22"))
			ci.draw_rect(Rect2(x - 12, y - 18, 24, 2), TB.c("#7a5236"))
			ci.draw_rect(Rect2(x - 12, y - 6, 24, 1), TB.c("#7a5236"))
			for k in 4:
				ci.draw_line(Vector2(x - 7 + k * 5, y - 17), Vector2(x - 8 + k * 5, y - 2), TB.c(["#c8ccd8", "#8a6a4a", "#c8ccd8", "#f2c94c"][k]), 1.0)
			Gfx.text(ci, "TRAINING", x, y - 30, "tan", 1, 0.5)
		"v_cat":
			var bob := (absf(sin(t * 10.0)) * 1.5) if o.get("moving", false) else 0.0
			if o.get("moving", false) or o["follow_t"] > 0.0:
				Gfx.sp(ci, "camp_cat", x, y + 2 - bob, 1, 1, 0.0, o["face"] < 0)
			else:   # napping: squashed, with z's
				Gfx.sp(ci, "camp_cat", x, y + 2, 1.1, 0.8, 0.0, o["face"] < 0)
				var zt := fmod(t * 0.6, 1.0)
				Gfx.text(ci, "Z", x + 6 + zt * 4.0, y - 10 - zt * 8.0, "dim", 1, 0.5, true, 1.0 - zt)
			if int(Meta.meta.get("cat_pets", 0)) >= CAT_STAYS:
				Gfx.text(ci, CAT_NAME, x, y - 16, "tan", 1, 0.5)
		_:
			if not VISITORS.has(o["kind"]):
				return
			var v: Array = VISITORS[o["kind"]]
			ci.draw_rect(Rect2(x - 6, y + 1, 12, 2), Color(0, 0, 0, 0.3))
			var sway := sin(t * 2.0 + x) * 0.6
			Gfx.sp(ci, v[1], x, y + 2 + sway * 0.5, 1, 1, 0.0, o["face"] < 0)
			Gfx.text(ci, v[2], x, y - 24, "tan", 1, 0.5)
			match o["kind"]:
				"v_peddler":
					if o.has("relic") and not o.get("sold", false):
						var r: Dictionary = o["relic"]
						ci.draw_rect(Rect2(x + 9, y - 6, 14, 8), TB.c("#5a3a22"))
						Gfx.sp(ci, r["sprite"], x + 16, y - 4 + sin(t * 3.0) * 1.0)
				"v_bard":
					var pt: float = o.get("play_t", 0.0)
					var notes := 3 if pt > 0.0 else 1
					for k in notes:
						var nt := fmod(t * 0.5 + k * 0.37, 1.0)
						var nx := x + 8 + nt * 10.0 + sin(nt * 9.0 + k) * 3.0
						var ny := y - 12 - nt * 22.0
						var col := TB.c(["#f2c94c", "#6fd3e0", "#e86fb4"][k]) * Color(1, 1, 1, 1.0 - nt)
						ci.draw_rect(Rect2(nx, ny, 2, 2), col)
						ci.draw_rect(Rect2(nx + 1, ny - 4, 1, 4), col)
				"v_seer":
					var gl := 0.5 + 0.5 * sin(t * 2.5)
					ci.draw_circle(Vector2(x, y - 5), 4.0 + gl, Color(0.43, 0.83, 0.88, 0.12 + 0.1 * gl))
				"v_monger":
					ci.draw_rect(Rect2(x - 22, y - 6, 12, 7), TB.c("#7a5236"))
					ci.draw_rect(Rect2(x - 21, y - 7, 10, 2), TB.c("#c8f0ff"))
					for k in 3:
						ci.draw_rect(Rect2(x - 20 + k * 3, y - 8, 2, 1), TB.c(["#6fd3e0", "#f2c94c", "#d9d0b4"][k]))

## The training ground's fence (Camp.paint_static).
static func paint_static(ci: CanvasItem) -> void:
	var post := TB.c("#5a3a22")
	var rail := TB.c("#8a6a4a")
	var x0 := 380.0
	var x1 := 438.0
	var y0 := 192.0
	var y1 := 262.0
	ci.draw_rect(Rect2(x0, y0, x1 - x0, y1 - y0), Color(0.55, 0.42, 0.25, 0.25))   # trodden earth
	for k in 4:
		ci.draw_circle(Vector2(410, 228), 6.0 + k * 6.0, Color(1, 1, 1, 0.05), false, 1.0)
	for xx in [x0, x0 + 29.0, x1]:
		ci.draw_rect(Rect2(xx - 1, y0 - 6, 3, 7), post)
	ci.draw_rect(Rect2(x0, y0 - 4, x1 - x0, 2), rail)
	for yy in [y0 + 24.0, y0 + 48.0]:
		ci.draw_rect(Rect2(x0 - 1, yy - 6, 3, 7), post)
		ci.draw_rect(Rect2(x1 - 1, yy - 6, 3, 7), post)
	ci.draw_rect(Rect2(x0, y0 - 4, 2, y1 - y0 - 10), rail)
	ci.draw_rect(Rect2(x1, y0 - 4, 2, y1 - y0 - 10), rail)

# ---------- The KITCHEN page (state "kitchen") ----------
static func update_kitchen() -> void:
	var ids: Array = MEALS.keys()
	var go := G.menu_nav(ids.size())
	kit_i = G.menu
	if go:
		if cook(ids[kit_i]):
			G.show_banner("THE COOK: \"" + MEALS[ids[kit_i]][0] + ", COMING UP.\"", "EATEN AT THE START OF YOUR NEXT RUN: " + MEALS[ids[kit_i]][1])
			G.state = &"play"
	elif Keys.back():
		G.state = &"play"
		Snd.play("select")

static func draw_kitchen(ci: CanvasItem) -> void:
	Gfx.text(ci, "THE COOK'S POT", TB.SW / 2, 10, "gold", 2, 0.5)
	var m: String = Meta.meta.get("meal", "")
	Gfx.text(ci, ("ON THE FIRE: " + MEALS[m][0] + " - " + MEALS[m][1]) if MEALS.has(m) else "NOTHING ON THE FIRE YET. ONE MEAL AT A TIME",
		TB.SW / 2, 26, "lime" if MEALS.has(m) else "dim", 1, 0.5)
	var ids: Array = MEALS.keys()
	for i in ids.size():
		var y := KIT_Y0 + i * KIT_DY
		var sel := i == kit_i
		var ok := not plan(ids[i]).is_empty()
		if sel:
			ci.draw_rect(Rect2(10, y - 4, 168, KIT_DY - 2), TB.rgba(232, 135, 58, 46))
		Gfx.text(ci, MEALS[ids[i]][0], 16, y, "gold" if sel else ("white" if ok else "dim"))
		Gfx.text(ci, "READY" if ok else "", 174, y, "lime", 1, 1)
	var id: String = ids[kit_i]
	var x0 := 192
	Gfx.text(ci, MEALS[id][0], x0, 42, "gold", 2)
	var y := 60
	for l in Gfx.wrap_text("NEXT RUN: " + MEALS[id][1], 240):
		Gfx.text(ci, l, x0, y, "white")
		y += 10
	y += 6
	Gfx.text(ci, "IT TAKES:", x0, y, "tan")
	y += 11
	var needs: Dictionary = MEALS[id][2]
	for k in needs:
		var have := _need_have(k)
		var nm: String = Fishing.FISH[k][0] if Fishing.FISH.has(k) else RARITY_WORD.get(k, k.to_upper())
		Gfx.text(ci, "%d X %s (YOU HAVE %d)" % [needs[k], nm, have], x0 + 6, y, "lime" if have >= int(needs[k]) else "red")
		y += 10
	y += 6
	var ready := not plan(id).is_empty()
	Gfx.text(ci, "USE: COOK IT" if ready else "CATCH MORE FISH: ANY POND, IN A RUN OR HERE", x0, y, "gold" if ready else "dim")
	if ready and MEALS.has(m) and m != id:
		Gfx.text(ci, "(IT TAKES THE PLACE OF " + MEALS[m][0] + ")", x0, y + 10, "dim")
	# The larder along the bottom.
	Gfx.text(ci, "THE LARDER", 16, 172, "tan")
	var k2 := 0
	for f in Fishing.FISH:
		var n := int(larder().get(f, 0))
		var fx := 22 + (k2 % 8) * 52
		var fy := 196 + (k2 / 8) * 22
		Gfx.sp(ci, Fishing.sprite_of(f), fx, fy, 1, 1, 0.0, false, 1.0 if n > 0 else 0.4)
		Gfx.text(ci, "X%d" % n, fx + 10, fy - 7, "white" if n > 0 else "dim")
		k2 += 1
	Gfx.text(ci, "MENU: BACK", TB.SW / 2, 266, "dim", 1, 0.5)

# ---------- The ARMORY page (state "armory"): the training ground's rack ----------
static func _build_list() -> void:
	arm_list = [["reset"]]
	for w in Weapons.all():
		arm_list.append(["w", w])
	for r in Relics.all():
		arm_list.append(["r", r])

static func open_armory() -> void:
	if arm_list.is_empty():
		_build_list()
	G.state = &"armory"
	G.menu = arm_i
	Snd.play("select")

static func arm_top() -> int:
	return clampi(arm_i - ARM_ROWS / 2, 0, maxi(0, arm_list.size() - ARM_ROWS))

static func first_relic() -> int:
	for i in arm_list.size():
		if arm_list[i][0] == "r":
			return i
	return 0

static func pick(i: int) -> void:
	arm_i = i
	G.menu = i

static func page(dir: int) -> void:
	arm_i = clampi(arm_i + dir * (ARM_ROWS - 2), 0, arm_list.size() - 1)
	G.menu = arm_i
	Snd.play("select")

static func update_armory() -> void:
	if arm_list.is_empty():
		_build_list()
	if Keys.left():
		page(-1)
	elif Keys.right():
		page(1)
	var go := G.menu_nav(arm_list.size())
	arm_i = G.menu
	if go:
		take(arm_list[arm_i])
	elif Keys.back():
		G.state = &"play"
		Snd.play("select")

## Takes a row: a weapon is held, a relic is added (camp only: nothing is marked found).
static func take(row: Array) -> void:
	var p := G.player
	match row[0]:
		"reset":
			var x := p.x
			var y := p.y
			Camp.fresh_player()
			G.player.x = x
			G.player.y = y
			G.toast("EVERYTHING BACK ON THE RACK", "white")
		"w":
			var w: Dictionary = row[1]
			var had: bool = Meta.meta["found_w"].has(w["id"])
			Weapons.equip_weapon(p, w)
			if not had:
				Meta.meta["found_w"].erase(w["id"])
			G.toast("YOU HOLD " + w["name"], "gold")
		"r":
			var r: Dictionary = row[1]
			p.relics.append(r)
			Relics.apply(r["id"], p)
			if r["new"]:
				Effects.recount_tags(p)
			G.toast("YOU CARRY " + r["name"], "gold")
	Snd.play("relic")
	G.state = &"play"

static func draw_armory(ci: CanvasItem) -> void:
	Gfx.text(ci, "THE TRAINING GROUND", TB.SW / 2, 8, "gold", 2, 0.5)
	Gfx.text(ci, "ANY WEAPON OR RELIC, FOR THE DUMMIES. NOTHING LEAVES THE CAMP", TB.SW / 2, 22, "dim", 1, 0.5)
	var top := arm_top()
	for j in mini(ARM_ROWS, arm_list.size() - top):
		var i := top + j
		var row: Array = arm_list[i]
		var y := ARM_Y0 + j * ARM_DY
		var sel := i == arm_i
		if sel:
			ci.draw_rect(Rect2(10, y - 3, 190, ARM_DY - 1), TB.rgba(232, 135, 58, 46))
		if row[0] == "reset":
			Gfx.text(ci, "PUT EVERYTHING BACK", 16, y, "gold" if sel else "tan")
			continue
		var it: Dictionary = row[1]
		Gfx.text(ci, ("W " if row[0] == "w" else "R ") + it["name"], 16, y, "gold" if sel else GameData.RARITY_COL.get(it["rarity"], "white"))
	if top > 0:
		Gfx.text(ci, "^", 104, ARM_Y0 - 9, "dim", 1, 0.5)
	if top + ARM_ROWS < arm_list.size():
		Gfx.text(ci, "V", 104, ARM_Y0 + ARM_ROWS * ARM_DY - 2, "dim", 1, 0.5)
	# The chosen row.
	var x0 := 214
	var row: Array = arm_list[arm_i]
	var p := G.player
	if row[0] == "reset":
		Gfx.text(ci, "PUT EVERYTHING BACK", x0, 40, "gold", 1)
		Gfx.text(ci, "YOUR HERO'S OWN WEAPON, NO RELICS", x0, 54, "white")
	else:
		var it: Dictionary = row[1]
		ci.draw_rect(Rect2(x0, 34, 28, 28), Color(0.08, 0.06, 0.11, 0.8))
		Gfx.sp(ci, it["sprite"], x0 + 14, 58, 2, 2)
		Gfx.text(ci, it["name"], x0 + 34, 38, GameData.RARITY_COL.get(it["rarity"], "white"))
		Gfx.text(ci, GameData.RARITY_NAME.get(it["rarity"], "") + (" WEAPON" if row[0] == "w" else " RELIC"), x0 + 34, 50, "grey")
		var y := 70
		for l in Gfx.wrap_text(it["desc"], 220):
			Gfx.text(ci, l, x0, y, "white")
			y += 10
	Gfx.text(ci, "HELD: " + p.weapon["name"], x0, 196, "tan")
	Gfx.text(ci, "RELICS: %d" % p.relics.size(), x0, 207, "tan")
	Gfx.text(ci, "%d / %d" % [arm_i, arm_list.size() - 1], x0, 218, "dim")
	for b in [[214, "< PAGE"], [280, "PAGE >"], [346, "THE RELICS"]]:   # taps.gd
		ci.draw_rect(Rect2(b[0], 228, 60 if b[0] < 346 else 80, 14), Color(0.2, 0.15, 0.25, 0.9))
		Gfx.text(ci, b[1], b[0] + (30 if b[0] < 346 else 40), 232, "white", 1, 0.5)
	Gfx.text(ci, "UP/DOWN: CHOOSE  LEFT/RIGHT: A PAGE  USE: TAKE IT  MENU: BACK", TB.SW / 2, 266, "dim", 1, 0.5)
