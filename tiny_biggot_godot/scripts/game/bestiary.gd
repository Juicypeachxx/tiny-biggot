class_name Bestiary
extends RefCounted
## 22.3 THE BESTIARY AND PAST RUNS (his word, 8 Oct: "6"): two more pages of the title's CODEX.
##   BESTIARY   every foe and guardian in the game, floor by floor and then the rift worlds: a dark
##              shape until you have met it; once met, its name, where it lives, how many you have
##              slain and what it says. (Meta "seen" and "slain", kept as you play.)
##   PAST RUNS  your last ten runs: the hero, how far, how it ended, the time, foes slain, embers.
##              (Meta "runs_log", written when a run ends.)

const COLS := 11
const ROWS := 6
const LOG_MAX := 10
const SKIP := ["dummy", "target", "beltlink"]   # not foes: the training dummy, the gallery's targets, a feeder's belt

static var _list: Array = []    # [key, is_guardian]
static var _where := {}         # key -> where it lives

# ---------- Keeping count ----------
## Combat.spawn_enemy / spawn_boss: met.
static func seen(key: String) -> void:
	var s: Dictionary = Meta.meta.get("seen", {}) if Meta.meta.get("seen") is Dictionary else {}
	if not s.has(key):
		s[key] = true
		Meta.meta["seen"] = s

## Combat.kill_enemy: slain.
static func slain(key: String) -> void:
	var s: Dictionary = Meta.meta.get("slain", {}) if Meta.meta.get("slain") is Dictionary else {}
	s[key] = int(s.get(key, 0)) + 1
	Meta.meta["slain"] = s
	seen(key)

static func has_met(key: String) -> bool:
	return Meta.meta.get("seen") is Dictionary and (Meta.meta["seen"] as Dictionary).has(key)

static func kills(key: String) -> int:
	return int((Meta.meta["slain"] as Dictionary).get(key, 0)) if Meta.meta.get("slain") is Dictionary else 0

# ---------- The list ----------
## Every foe and guardian, in the order you meet them: floor by floor (its foes, its champion, its
## guardians), then the rift worlds, then anything else.
static func entries() -> Array:
	if not _list.is_empty():
		return _list
	var have := {}
	var add := func(key: String, boss: bool, where: String) -> void:
		if key == "" or have.has(key) or key in SKIP:
			return
		if boss and not GameData.BOSSES.has(key) or not boss and not GameData.ENEMIES.has(key):
			return
		have[key] = true
		_list.append([key, boss])
		_where[key] = where
	var fl: Array = GameData.FLOORS + GameData.NEW_FLOORS + GameData.CHAPTER2 + GameData.CHAPTER3 + GameData.CHAPTER4
	for i in fl.size():
		var f: Dictionary = fl[i]
		for t in f["pool"]:
			add.call(t, false, f["name"])
		for t in EnemyAI2.OLD_FLOOR_EXTRA.get(i, []):
			add.call(t, false, f["name"])
		add.call(f.get("mini", ""), false, f["name"])
		add.call(f["boss"], true, f["name"])
		add.call(GameData.ALT_GUARDIANS.get(i, ""), true, f["name"])
	for th in Themes.LIST + Themes.REALMS:
		var where: String = th["name"]
		for t in th.get("pool", []):
			add.call(t, false, where)
		add.call(th.get("mini", ""), false, where)
		add.call(th.get("champion", ""), false, where)
		add.call(th.get("guardian", ""), true, where)
	for k in GameData.ENEMIES:
		add.call(k, false, "HERE AND THERE")
	for k in GameData.BOSSES:
		add.call(k, true, "HERE AND THERE")
	return _list

static func where(key: String) -> String:
	entries()
	return _where.get(key, "HERE AND THERE")

static func name_of(e: Array) -> String:
	if e[1]:
		return GameData.BOSSES[e[0]]["name"]
	var d: Dictionary = GameData.ENEMIES[e[0]]
	if d.has("name"):
		return str(d["name"])
	var l: String = d.get("label", e[0])
	for a in ["a ", "an ", "the "]:
		if l.begins_with(a):
			l = l.substr(a.length())
	return l.to_upper()

static func sprite_of(e: Array) -> String:
	return (GameData.BOSSES if e[1] else GameData.ENEMIES)[e[0]]["sprite"]

static func line_of(e: Array) -> String:
	if e[1]:
		return Barks.BOSS_LINES.get(e[0], "")
	var b: Array = Barks.FOE_BARKS.get(e[0], [])
	return b[0] if not b.is_empty() else ""

static func met_count() -> int:
	var n := 0
	for e in entries():
		if has_met(e[0]):
			n += 1
	return n

# ---------- Past runs ----------
## Game.award_embers: this run, at the top of the log.
static func log_run(win: bool, embers: int) -> void:
	var r := G.run_stats
	var p := G.player
	if p == null:
		return
	var fl: Array = GameData.floors()
	var how := "SLAIN BY " + G.death_by.to_upper()
	if win:
		how = "WON"
		for k in [["critic", "THE BOOK IS KEPT"], ["reader", "THE LAST PAGE"], ["redactor", "NOTHING ERASED"], ["author", "THE STORY IS YOURS"],
				["unwritten", "THE UNWRITTEN UNMADE"]]:
			if r.get(k[0], false):
				how = "WON: " + k[1]
				break
		if r.get("finale_won", false):
			how = "WON: THE LAST LAUGH"   # 55
	var rec := { "hero": p.hero["name"], "sprite": p.hero["sprite"], "floor": G.floor_index + 1,
		"place": fl[clampi(G.floor_index, 0, fl.size() - 1)]["name"], "how": how, "win": win, "time": float(r.get("time", 0.0)),
		"kills": int(r.get("kills", 0)), "embers": embers, "date": Time.get_date_string_from_system() }
	if r.get("endless", false):
		rec["depth"] = int(r.get("depth", 1))
	if r.has("daily"):
		rec["daily"] = true
	var log: Array = Meta.meta["runs_log"] if Meta.meta.get("runs_log") is Array else []
	log.push_front(rec)
	while log.size() > LOG_MAX:
		log.pop_back()
	Meta.meta["runs_log"] = log

# ---------- The pages (MenuView.draw_codex) ----------
static func draw_beasts(ci: CanvasItem, sel: int) -> void:
	var list := entries()
	Gfx.text(ci, "%d OF %d MET" % [met_count(), list.size()], TB.SW / 2, 28, "grey", 1, 0.5)
	var cw := 30
	var chh := 22
	var x0 := (TB.SW - COLS * cw) / 2 + 4
	var first_row := first_row_for(sel)
	for i in list.size():
		var row := i / COLS - first_row
		if row < 0 or row >= ROWS:
			continue
		var e: Array = list[i]
		var x := x0 + (i % COLS) * cw
		var y := 42 + row * chh
		if sel == i:
			ci.draw_rect(Rect2(x - 4, y - 4, 22, 21), TB.rgba(232, 135, 58, 90))
		if e[1]:
			ci.draw_rect(Rect2(x - 3, y - 3, 20, 19), Color(0.55, 0.15, 0.15, 0.35))   # a guardian
		var spr := sprite_of(e)
		var sz := Img.t(spr).get_size()
		var z := minf(1.0, 16.0 / maxf(1.0, maxf(sz.x, sz.y)))
		if has_met(e[0]):
			Gfx.sp(ci, spr, x + 7, y + 16, z, z)
		else:
			Gfx.sp(ci, spr, x + 7, y + 16, z, z, 0.0, false, 1.0, Color(0.2, 0.18, 0.27, 1.0))   # a dark shape
	var e: Array = list[clampi(sel, 0, list.size() - 1)]
	Gfx.panel(ci, 30, 182, TB.SW - 60, 66, "#4e4a5e", "#17121e")
	if has_met(e[0]):
		Gfx.text(ci, name_of(e), TB.SW / 2, 188, "red" if e[1] else "gold", 2, 0.5)
		Gfx.text(ci, ("A GUARDIAN OF " if e[1] else "LIVES IN ") + where(e[0]), TB.SW / 2, 205, "tan", 1, 0.5)
		Gfx.text(ci, "SLAIN: %d" % kills(e[0]), TB.SW / 2, 216, "white", 1, 0.5)
		var said := line_of(e)
		if said != "":
			Gfx.text(ci, "'" + said + "'", TB.SW / 2, 228, "cyan", 1, 0.5)
	else:
		Gfx.text(ci, "NOT YET MET", TB.SW / 2, 192, "grey", 2, 0.5)
		Gfx.text(ci, ("A GUARDIAN OF " if e[1] else "LIVES IN ") + where(e[0]), TB.SW / 2, 214, "dim", 1, 0.5)

static func first_row_for(sel: int) -> int:
	var n := entries().size()
	return clampi(sel / COLS - ROWS / 2, 0, maxi(0, (n + COLS - 1) / COLS - ROWS))

static func draw_runs(ci: CanvasItem) -> void:
	var log: Array = Meta.meta["runs_log"] if Meta.meta.get("runs_log") is Array else []
	var title := "NO RUNS YET" if log.is_empty() else ("YOUR LAST RUN" if log.size() == 1 else "YOUR LAST %d RUNS" % log.size())
	Gfx.text(ci, title, TB.SW / 2, 28, "grey", 1, 0.5)
	for i in log.size():
		var r: Dictionary = log[i]
		var y := 42 + i * 21
		ci.draw_rect(Rect2(24, y - 3, TB.SW - 48, 19), Color(1, 1, 1, 0.04 if i % 2 == 0 else 0.0))
		if Img.has(str(r.get("sprite", ""))):
			Gfx.sp(ci, r["sprite"], 36, y + 15, 0.8, 0.8)
		var head := "%s  FLOOR %d, %s" % [r.get("hero", "?"), int(r.get("floor", 1)), r.get("place", "")]
		if r.has("depth"):
			head = "%s  ENDLESS: DEPTH %d" % [r.get("hero", "?"), int(r["depth"])]
		elif r.get("daily", false):
			head += "  (DAILY)"
		Gfx.text(ci, head, 50, y, "white")
		Gfx.text(ci, str(r.get("how", "")), 50, y + 8, "gold" if r.get("win", false) else "red")
		var secs := int(r.get("time", 0.0))
		Gfx.text(ci, "%02d:%02d  %d FOES  +%d EMBERS" % [secs / 60, secs % 60, int(r.get("kills", 0)), int(r.get("embers", 0))],
			TB.SW - 28, y, "grey", 1, 1)
		Gfx.text(ci, str(r.get("date", "")), TB.SW - 28, y + 8, "dim", 1, 1)
