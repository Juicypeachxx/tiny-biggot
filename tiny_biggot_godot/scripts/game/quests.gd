class_name Quests
extends RefCounted
## 20.2 THE QUEST BOARD (his word, 8 Oct: "camp upgrades and quests"): the camp's notice board
## holds three small goals at a time. Each run that ends checks them; a goal met pays its embers
## at once (on the run's ember tally, so dread multiplies them too) and a new goal takes its place.
## Goals about fish or hidden combos can also be met in the camp: the board pays them when read.
## Meta.meta: "quests" (the three: { id, hero, base }), "quests_done" (how many ever),
## "quest_news" (what the last run finished, shown on the board). Expanded game only.

## id: [goal, embers, kind, n]. {HERO} is filled with a hero's name when the goal is drawn.
const POOL := {
	"floor6": ["REACH FLOOR 6", 40, "floor", 6],
	"floor9": ["REACH FLOOR 9", 70, "floor", 9],
	"floor12": ["REACH FLOOR 12", 100, "floor", 12],
	"win": ["WIN A RUN", 120, "win", 0],
	"kills150": ["SLAY 150 FOES IN ONE RUN", 40, "kills", 150],
	"kills400": ["SLAY 400 FOES IN ONE RUN", 80, "kills", 400],
	"bosses3": ["FELL 3 GUARDIANS IN ONE RUN", 60, "bosses", 3],
	"bosses6": ["FELL 6 GUARDIANS IN ONE RUN", 100, "bosses", 6],
	"gold300": ["PICK UP 300 GOLD IN ONE RUN", 50, "gold", 300],
	"relics8": ["CARRY 8 RELICS AT ONCE", 50, "relics", 8],
	"relics15": ["CARRY 15 RELICS AT ONCE", 90, "relics", 15],
	"set": ["COMPLETE AN ARMOUR SET", 70, "set", 0],
	"fish3": ["CATCH 3 FISH IN ONE RUN", 40, "fish", 3],
	"secret2": ["FIND 2 SECRET ROOMS IN ONE RUN", 50, "secrets", 2],
	"level10": ["REACH LEVEL 10 IN ONE RUN", 50, "level", 10],
	"level20": ["REACH LEVEL 20 IN ONE RUN", 90, "level", 20],
	"daily": ["PLAY THE DAILY TRIAL", 40, "daily", 0],
	"chapter2": ["TURN THE PAGE INTO CHAPTER II", 150, "chapter", 2],
	"chapter3": ["READ ON INTO CHAPTER III", 200, "chapter", 3],
	"chapter4": ["STEP OUT ONTO THE SHELF: CHAPTER IV", 250, "chapter", 4],
	"blade": ["REACH FLOOR 5 HOLDING A BLADE", 60, "kind", "slash"],
	"whip": ["REACH FLOOR 5 HOLDING A WHIP OR FLAIL", 60, "kind", "whip"],
	"hero": ["REACH FLOOR 5 AS {HERO}", 60, "hero", 5],
	"oldone": ["CATCH THE OLD ONE", 100, "fish_id", "oldone"],
	"moonkoi": ["CATCH A MOONLIT KOI", 80, "fish_id", "moonkoi"],
	"combo": ["FIND A HIDDEN COMBO", 80, "combo", 0],
	"dread": ["REACH FLOOR 4 WITH DREAD ON", 60, "dread", 4],
	"meal": ["SET OUT WITH A MEAL FROM THE COOK", 30, "meal", 0],
}
const SLOTS := 3

static var _ate := false   # the run began with a camp meal (CampLife.on_new_run)
static var _rng := RandomNumberGenerator.new()   # its own dice: drawing goals never moves a run's random numbers

static func active() -> Array:
	if not (Meta.meta.get("quests") is Array):
		Meta.meta["quests"] = []
	var q: Array = Meta.meta["quests"]
	while q.size() < SLOTS:
		var nq := _draw(q)
		if nq.is_empty():
			break
		q.append(nq)
	return q

## A new goal, not one already on the board; fish already caught and heroes not owned are skipped.
static func _draw(have: Array) -> Dictionary:
	_rng.randomize()
	var ids: Array = POOL.keys()
	for i in range(ids.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t = ids[i]
		ids[i] = ids[j]
		ids[j] = t
	var taken := have.map(func(x): return x["id"])
	var fish: Dictionary = Meta.meta["fish"] if Meta.meta.get("fish") is Dictionary else {}
	for id in ids:
		if id in taken:
			continue
		var d: Array = POOL[id]
		if d[2] == "fish_id" and fish.has(d[3]):
			continue
		var q := { "id": id, "hero": "", "base": 0 }
		if d[2] == "hero":
			var owned := GameData.heroes().filter(func(h): return G.hero_unlocked(h))
			if owned.is_empty():
				continue
			q["hero"] = (owned[_rng.randi_range(0, owned.size() - 1)] as Dictionary)["id"]
		if d[2] == "combo":
			q["base"] = (Meta.meta["combos_found"] as Dictionary).size() if Meta.meta.get("combos_found") is Dictionary else 0
		return q
	return {}

static func text(q: Dictionary) -> String:
	var t: String = POOL[q["id"]][0]
	if q["hero"] != "":
		for h in GameData.heroes():
			if h["id"] == q["hero"]:
				t = t.replace("{HERO}", h["name"])
	return t

static func reward(q: Dictionary) -> int:
	return int(POOL[q["id"]][1])

## Is the goal met by the run that just ended (G.run_stats, G.player), or by the camp (fish, combos)?
static func met(q: Dictionary, win: bool, in_run: bool) -> bool:
	var d: Array = POOL[q["id"]]
	var r := G.run_stats
	var p := G.player
	var fl := G.floor_index + 1
	match d[2]:
		"fish_id":
			return Meta.meta.get("fish") is Dictionary and (Meta.meta["fish"] as Dictionary).has(d[3])
		"combo":
			return Meta.meta.get("combos_found") is Dictionary and (Meta.meta["combos_found"] as Dictionary).size() > int(q["base"])
	if not in_run or p == null:
		return false
	match d[2]:
		"floor": return fl >= int(d[3])
		"win": return win
		"kills": return int(r.get("kills", 0)) >= int(d[3])
		"bosses": return int(r.get("bosses", 0)) >= int(d[3])
		"gold": return int(r.get("gold", 0)) >= int(d[3])
		"relics": return p.relics.size() >= int(d[3])
		"set": return not (r.get("sets_done", {}) as Dictionary).is_empty()
		"fish": return int(r.get("fish", 0)) >= int(d[3])
		"secrets": return int(r.get("secrets", 0)) >= int(d[3])
		"level": return p.level >= int(d[3])
		"daily": return r.has("daily")
		"chapter": return int(r.get("chapter", 1)) >= int(d[3])
		"kind": return fl >= 5 and (p.weapon["kind"] == d[3] or (d[3] == "whip" and p.weapon["kind"] == "flail"))
		"hero": return fl >= int(d[3]) and p.hero["id"] == q["hero"]
		"dread": return fl >= int(d[3]) and G.dread > 0
		"meal": return _ate
	return false

## A run ends (G.award_embers): every goal met pays on the tally and is replaced.
static func on_run_end(win: bool, parts: Array) -> void:
	if not GameData.rogues() or G.run_stats.get("camp", false):
		return
	var news: Array = []
	var keep: Array = []
	for q in active():
		if met(q, win, true):
			parts.append(["QUEST: " + text(q), reward(q)])
			news.append(text(q))
			Meta.meta["quests_done"] = int(Meta.meta.get("quests_done", 0)) + 1
		else:
			keep.append(q)
	Meta.meta["quests"] = keep
	active()   # new goals in the empty places
	Meta.meta["quest_news"] = news
	_ate = false

## The board is read in the camp: goals met there (a fish, a combo) pay now.
static func check_camp() -> Array:
	var paid: Array = []
	var keep: Array = []
	for q in active():
		if met(q, false, false):
			Meta.meta["embers"] += reward(q)
			Meta.meta["quests_done"] = int(Meta.meta.get("quests_done", 0)) + 1
			paid.append([text(q), reward(q)])
		else:
			keep.append(q)
	if not paid.is_empty():
		Meta.meta["quests"] = keep
		active()
		Meta.write_save()
	return paid

# ---------- The board (state "board") ----------
static var paid_now: Array = []

static func open_board() -> void:
	paid_now = check_camp()
	G.state = &"board"
	G.menu = 0
	Snd.play("coin" if not paid_now.is_empty() else "select")

static func update_board() -> void:
	if Keys.back() or Keys.confirm():
		G.state = &"play"
		Snd.play("select")

static func draw_board(ci: CanvasItem) -> void:
	var m := Meta.meta
	Gfx.text(ci, "THE QUEST BOARD", TB.SW / 2, 10, "gold", 2, 0.5)
	Gfx.text(ci, "RUNS %d   WINS %d   DEEPEST FLOOR %d   QUESTS DONE %d" % [m["runs"], m["wins"], m["best"], int(m.get("quests_done", 0))],
		TB.SW / 2, 28, "tan", 1, 0.5)
	Gfx.text(ci, "A GOAL PAYS WHEN A RUN THAT MEETS IT ENDS. A NEW ONE IS PINNED IN ITS PLACE", TB.SW / 2, 40, "dim", 1, 0.5)
	var qs := active()
	for i in qs.size():
		var q: Dictionary = qs[i]
		var x := 30 + i * 132
		var y := 56
		ci.draw_rect(Rect2(x + 2, y + 2, 120, 92), Color(0, 0, 0, 0.35))
		ci.draw_rect(Rect2(x, y, 120, 92), TB.c("#c8a878"))
		ci.draw_rect(Rect2(x + 1, y + 1, 118, 90), TB.c("#3e3024"))
		ci.draw_rect(Rect2(x + 1, y + 1, 118, 2), TB.c("#5a4632"))
		ci.draw_circle(Vector2(x + 60, y + 6), 3.0, TB.c("#d8443c"))
		ci.draw_rect(Rect2(x + 59, y + 4, 1, 1), TB.c("#ff9a8a"))
		var yy := y + 18
		for l in Gfx.wrap_text(text(q), 108):
			Gfx.text(ci, l, x + 60, yy, "bone", 1, 0.5)
			yy += 10
		Gfx.text(ci, "+%d EMBERS" % reward(q), x + 60, y + 78, "gold", 1, 0.5)
	var y := 164
	var news: Array = m["quest_news"] if m.get("quest_news") is Array else []
	if not news.is_empty():
		Gfx.text(ci, "DONE ON YOUR LAST RUN:", 30, y, "lime")
		y += 11
		for t in news:
			Gfx.text(ci, "- " + t, 36, y, "white")
			y += 10
	if not paid_now.is_empty():
		y += 4
		Gfx.text(ci, "DONE HERE IN THE CAMP:", 30, y, "lime")
		y += 11
		for pq in paid_now:
			Gfx.text(ci, "- %s  +%d EMBERS" % [pq[0], pq[1]], 36, y, "gold")
			y += 10
	Gfx.text(ci, "MENU: BACK", TB.SW / 2, 266, "dim", 1, 0.5)
