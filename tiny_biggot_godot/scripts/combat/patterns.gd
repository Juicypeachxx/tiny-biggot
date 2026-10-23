class_name Patterns
extends RefCounted
## 56.4 New attack patterns for every guardian (his playthrough, 12 Oct: "new mechanic also new attack
## patterens for all boses"). Our own designs; each is shown before it can hurt, and drawn over your
## shots and effects (56.2):
##   PINWHEEL  arms of shots wind out of the guardian and turn (hard: five arms, and they turn back).
##   CAGE      a ring of marks closes round where you stand, with a gap; then it fires inward.
##   ORBIT     glowing orbs circle the guardian, widen and shoot at you; touching one hurts.
##   COMETS    slow comets that turn after you for a while, then burst in a ring.
##   GRID      the floor lights up in great squares, half of them, then the other half.
##   QUAKE     it stamps: rings of shock run out along the floor, each with a gap to slip through.
## BossAI plays them as moves (each guardian has its own two or three in its plans: NEW, `plan`);
## a rift guardian adds one of its own now and then (Resolve.tick); and a guardian that turns
## UNBROKEN answers with its signature, the first of its NEW (Resolve). tick() from Hazards.update,
## clear() wherever Chaos.clear() is. Expanded game only.

const KINDS := ["pinwheel", "cage", "orbit", "comets", "grid", "quake"]
## Each guardian's new patterns (the first is its signature).
const NEW := {
	"arci": ["comets", "orbit"],   # 58: his balls fly after you; he runs rings round you
	"sefe": ["pinwheel", "quake"],   # 59: finger guns all round; a belch that shakes the floor
	"vid": ["pinwheel", "grid"],   # V2: his hurricane; the floor an LED wall
	"colossus": ["quake", "cage"], "sporemother": ["orbit", "grid"], "librarian": ["comets", "pinwheel"],
	"tyrant": ["quake", "pinwheel"], "rimewarden": ["cage", "grid"], "regent": ["comets", "orbit"],
	"bogmatriarch": ["orbit", "grid"], "ashwarlord": ["quake", "comets"], "frozenabbot": ["pinwheel", "cage"],
	"crowking": ["comets", "grid"], "umbralsun": ["pinwheel", "orbit"], "judge": ["grid", "cage"],
	"cinderking": ["quake", "comets"], "unwritten": ["pinwheel", "grid", "comets"], "holycow": ["quake", "orbit"],
	"greatengine": ["pinwheel", "quake"], "glacialmaw": ["cage", "quake"], "inkleviathan": ["orbit", "pinwheel"],
	"thebinder": ["cage", "grid"], "author": ["comets", "grid"], "lexicon": ["pinwheel", "comets"],
	"erratum": ["grid", "quake"], "reader": ["cage", "orbit", "grid"], "redactor": ["grid", "pinwheel"],
	"shelver": ["quake", "comets"], "hush": ["cage", "orbit"], "critic": ["comets", "pinwheel", "grid"],
	"admiral": ["pinwheel", "cage"], "golemking": ["quake", "grid"], "archmage": ["orbit", "comets"],
	"phoenix": ["pinwheel", "orbit"], "wyrm": ["cage", "comets"], "chainfiend": ["quake", "cage"],
	"seraph": ["orbit", "pinwheel"], "braysalot": ["quake", "comets"], "scalesworth": ["grid", "cage"],
	"prophet": ["comets", "quake"], "chonk": ["orbit", "pinwheel"],
}
const HIT_CD := 0.6
## The floor the grid covers (6 x 4 squares).
const GRID_X := 32.0
const GRID_Y := 56.0
const GRID_W := 64.0
const GRID_H := 48.0

static var spinners: Array = []   # { owner, by, a, spin, arms, warn, fire, half, every, next, spr, col }
static var cages: Array = []      # { x, y, r, n, gap, gw, warn, t, by, spr, col }
static var orbs: Array = []       # { owner, by, a, r, r1, t, life, next, cd, col }
static var comets: Array = []     # { x, y, a, v, turn, t, life, by, spr, col }
static var grids: Array = []      # { cells, waves, warn, t, by, cd }
static var quakes: Array = []     # { x, y, r, v, gap, gw, delay, by, cd, col }

static func clear() -> void:
	spinners.clear()
	cages.clear()
	orbs.clear()
	comets.clear()
	grids.clear()
	quakes.clear()

static func busy() -> bool:
	return not (spinners.is_empty() and cages.is_empty() and orbs.is_empty() and comets.is_empty() and grids.is_empty() and quakes.is_empty())

## A guardian's patterns: its own (NEW), else two picked by its name.
static func of(e: Enemy) -> Array:
	var key: String = e.boss if e.is_boss() else e.type
	if NEW.has(key):
		return NEW[key]
	var sum := 0
	for i in key.length():
		sum += key.unicode_at(i)
	return [KINDS[sum % KINDS.size()], KINDS[(sum / KINDS.size() + 1 + sum) % KINDS.size()]]

## 56.4: a guardian's plan with its new patterns in it (the expanded game; --classic keeps the plan).
## Stage 1: its signature once, from the fourth floor on; stages 2 and 3, and a risen third stage:
## all of them, spread through the plan.
static var _plans := {}
static func plan(e: Enemy, base: Array, stage: int) -> Array:
	if not GameData.rogues() or e.boss == "rex":
		return base
	var key := "%s/%d/%d" % [e.boss, stage, 1 if G.floor_index >= 3 else 0]
	if _plans.has(key):
		return _plans[key]
	var out := base.duplicate()
	var add: Array = of(e) if stage >= 2 else ([of(e)[0]] if G.floor_index >= 3 else [])
	for i in add.size():
		var at := mini(out.size(), 1 + (i + 1) * out.size() / (add.size() + 1))
		out.insert(at, add[i])
	_plans[key] = out
	return out

static func _col(e: Enemy) -> Color:
	return TB.c(Afx.BOSS_COL.get(e.boss, "#d8443c"))

static func _spr(e: Enemy) -> String:
	return BossAI.RING_SPR.get(e.boss, e.d.get("shot", "red"))

## Casts a pattern; returns how long the guardian waits before its next move.
static func cast(e: Enemy, kind: String, hard: bool) -> float:
	if not GameData.rogues() or G.player == null:
		return 0.3
	var p := G.player
	var by: String = e.d.get("name", "A FOE")
	match kind:
		"pinwheel":
			if spinners.size() >= 2:
				return 0.3
			var arms := 5 if hard else 4
			var fire := 3.0 if hard else 2.4
			spinners.append({ "owner": weakref(e), "by": by, "a": TB.ang_to(e, p) + PI / arms, "spin": 1.5 if randf() < 0.5 else -1.5,
				"arms": arms, "warn": 0.6, "fire": fire, "half": fire * 0.5 if hard else -1.0, "every": 0.12, "next": 0.0,
				"spr": _spr(e), "col": _col(e) })
			Snd.play("charge")
			return 0.6 + fire
		"cage":
			if cages.size() >= 2:
				return 0.3
			var n := 22
			var r := 58.0 if hard else 66.0
			cages.append({ "x": p.x, "y": p.y - 4, "r": r, "n": n, "gap": randf() * TAU, "gw": 3, "warn": 0.85 if hard else 1.05,
				"t": 0.0, "by": by, "spr": _spr(e), "col": _col(e) })
			if hard:
				cages.append({ "x": p.x, "y": p.y - 4, "r": r + 22.0, "n": 26, "gap": randf() * TAU, "gw": 3, "warn": 1.25,
					"t": 0.0, "by": by, "spr": _spr(e), "col": _col(e) })
			Snd.play("charge")
			return 1.4
		"orbit":
			if orbs.size() >= 8:
				return 0.3
			var k := 4 if hard else 3
			var a0 := randf() * TAU
			for i in k:
				orbs.append({ "owner": weakref(e), "by": by, "a": a0 + i * TAU / k, "r": 18.0, "r1": 70.0 if hard else 60.0,
					"t": 0.0, "life": 6.0 if hard else 5.0, "next": 1.2 + 0.35 * i, "cd": 0.0, "col": _col(e), "spr": _spr(e) })
			Snd.play("charge")
			return 1.2
		"comets":
			if comets.size() >= 10:
				return 0.3
			var k := 5 if hard else 3
			var at := TB.ang_to(e, p)
			for i in k:
				var a := at + ((float(i) / (k - 1) - 0.5) * 1.6 if k > 1 else 0.0)
				comets.append({ "x": e.x, "y": e.y - 6, "a": a, "v": 62.0 if hard else 54.0, "turn": 1.7 if hard else 1.4,
					"t": 0.0, "life": 3.0, "by": by, "spr": _spr(e), "col": _col(e), "disc": e.boss == "arci" })   # 58: his are frisbees
			Snd.play("charge")
			return 0.9
		"grid":
			if not grids.is_empty():
				return 0.3
			var first := randi() % 2
			var waves := [first, 1 - first] + ([first] if hard else [])
			grids.append({ "waves": waves, "warn": 0.8 if hard else 1.0, "t": 0.0, "by": by, "col": _col(e) })
			Snd.play("charge")
			return 0.4 + (0.8 if hard else 1.0) * waves.size()
		"quake":
			if quakes.size() >= 6:
				return 0.3
			var k := 4 if hard else 3
			var away := TB.ang_to(e, p)
			for i in k:
				quakes.append({ "x": e.x, "y": e.y + e.r * 0.5, "r": 0.0, "v": 92.0 if hard else 84.0,
					"gap": away + PI * 0.6 * (i % 2 * 2 - 1) + randf_range(-0.4, 0.4), "gw": 0.62 if hard else 0.8,
					"delay": 0.5 + 0.45 * i, "by": by, "cd": 0.0, "col": _col(e) })
			e.z = 0.0
			G.add_shake(5)
			Snd.play("charge")
			return 0.6 + 0.45 * k
	return 0.3

## Resolve: a guardian turns UNBROKEN and answers with its signature.
static func signature(e: Enemy) -> void:
	cast(e, of(e)[0], true)

# ---------- Every tick ----------
static func tick(dt: float) -> void:
	if not busy():
		return
	var p := G.player
	if p == null:
		return
	_tick_spinners(dt)
	_tick_cages(p, dt)
	_tick_orbs(p, dt)
	_tick_comets(p, dt)
	_tick_grids(p, dt)
	_tick_quakes(p, dt)

static func _owner(h: Dictionary) -> Enemy:
	var o = h["owner"].get_ref()
	return o if o != null and (o as Enemy).hp > 0 else null

static func _tick_spinners(dt: float) -> void:
	var keep := []
	for s in spinners:
		var o := _owner(s)
		if o == null:
			continue
		if s["warn"] > 0:
			s["warn"] -= dt
			keep.append(s)
			continue
		s["fire"] -= dt
		if s["fire"] <= 0:
			continue
		if s["half"] > 0 and s["fire"] <= s["half"]:
			s["half"] = -1.0
			s["spin"] = -s["spin"]   # (hard: the arms turn back)
		s["a"] += s["spin"] * dt
		s["next"] -= dt
		if s["next"] <= 0:
			s["next"] = s["every"]
			for i in s["arms"]:
				Combat.eshot(o.x, o.y - 6, s["a"] + i * TAU / s["arms"], 74.0, s["spr"])
		keep.append(s)
	spinners = keep

static func _tick_cages(p: Player, dt: float) -> void:
	var keep := []
	for c in cages:
		c["t"] += dt
		if c["t"] < c["warn"]:
			keep.append(c)
			continue
		var n: int = c["n"]
		var g := _gap_slot(c)
		for i in n:
			if _in_gap(i, g, n, c["gw"]):
				continue
			var a := float(i) / n * TAU
			Combat.eshot(c["x"] + cos(a) * c["r"], c["y"] + sin(a) * c["r"], a + PI, 58.0, c["spr"])
		Snd.play("beam")
	cages = keep

static func _gap_slot(c: Dictionary) -> int:
	return roundi(TB.wrap_ang(c["gap"]) / TAU * c["n"] + c["n"]) % c["n"]

static func _in_gap(i: int, g: int, n: int, w: int) -> bool:
	var d := absi(i - g)
	return mini(d, n - d) <= w / 2

static func _tick_orbs(p: Player, dt: float) -> void:
	var keep := []
	for b in orbs:
		var o := _owner(b)
		if o == null:
			continue
		b["t"] += dt
		if b["t"] >= b["life"]:
			Fx.burst(_orb_at(b, o).x, _orb_at(b, o).y, [b["col"].to_html(false)], 6, 40)
			continue
		b["r"] = minf(b["r1"], b["r"] + 40.0 * dt)
		b["a"] += 1.7 * dt
		b["cd"] -= dt
		var at := _orb_at(b, o)
		if b["cd"] <= 0 and at.distance_to(Vector2(p.x, p.y - 4)) < 6.0 + p.r:
			b["cd"] = HIT_CD
			Combat.hurt_player(1, b["by"])
		b["next"] -= dt
		if b["next"] <= 0:
			b["next"] = 1.5
			Combat.eshot(at.x, at.y, atan2(p.y - at.y, p.x - at.x), 82.0, b["spr"])
		keep.append(b)
	orbs = keep

static func _orb_at(b: Dictionary, o: Enemy) -> Vector2:
	return Vector2(o.x, o.y - 6) + Vector2.from_angle(b["a"]) * b["r"]

static func _tick_comets(p: Player, dt: float) -> void:
	var keep := []
	for c in comets:
		c["t"] += dt
		var to := atan2(p.y - 4 - c["y"], p.x - c["x"])
		var d := TB.wrap_ang(to - c["a"])
		c["a"] += clampf(d, -c["turn"] * dt, c["turn"] * dt)
		c["x"] += cos(c["a"]) * c["v"] * dt
		c["y"] += sin(c["a"]) * c["v"] * dt
		var hit: bool = Vector2(c["x"], c["y"]).distance_to(Vector2(p.x, p.y - 4)) < 4.0 + p.r
		if hit:
			Combat.hurt_player(1, c["by"])
		if hit or c["t"] >= c["life"] or World.solid(G.room, floori(c["x"] / TB.TS), floori(c["y"] / TB.TS), World.M_BULLET):
			Combat.ering(c["x"], c["y"], 8, 60.0, randf(), c["spr"])
			Fx.burst(c["x"], c["y"], [c["col"].to_html(false), "#ffffff"], 8, 50)
			continue
		keep.append(c)
	comets = keep

static func _cell(i: int) -> Rect2:
	return Rect2(GRID_X + (i % 6) * GRID_W, GRID_Y + (i / 6) * GRID_H, GRID_W, GRID_H)

static func _lit(g: Dictionary, i: int) -> bool:
	return (i % 6 + i / 6) % 2 == g["waves"][0]

static func _tick_grids(p: Player, dt: float) -> void:
	var keep := []
	for g in grids:
		g["t"] += dt
		if g["t"] < g["warn"]:
			keep.append(g)
			continue
		# The lit squares blast; the next wave lights the others.
		for i in 24:
			if _lit(g, i):
				var r := _cell(i)
				if r.has_point(Vector2(p.x, p.y)):
					Combat.hurt_player(1, g["by"])
				if i % 3 == 0:
					Fx.burst(r.get_center().x, r.get_center().y, [g["col"].to_html(false), "#ffd0c0"], 6, 60)
		G.add_shake(4)
		Snd.play("boom")
		g["waves"].pop_front()
		g["t"] = 0.0
		if not g["waves"].is_empty():
			keep.append(g)
	grids = keep

static func _tick_quakes(p: Player, dt: float) -> void:
	var keep := []
	for q in quakes:
		if q["delay"] > 0:
			q["delay"] -= dt
			if q["delay"] <= 0:
				G.add_shake(3)
				Snd.play("boom")
			keep.append(q)
			continue
		q["r"] += q["v"] * dt
		q["cd"] -= dt
		if q["r"] > 340.0:
			continue
		var d := Vector2(p.x - q["x"], p.y - q["y"])
		if q["cd"] <= 0 and absf(d.length() - q["r"]) < 5.0 and absf(TB.wrap_ang(d.angle() - q["gap"])) > q["gw"] * 0.5:
			q["cd"] = HIT_CD * 2.0
			Combat.hurt_player(1, q["by"])
		keep.append(q)
	quakes = keep

# ---------- Drawing (world_view: the ground under everyone, the rest over your shots) ----------
static func draw_ground(ci: CanvasItem, t: float) -> void:
	for g in grids:
		var k: float = clampf(g["t"] / g["warn"], 0.0, 1.0)
		for i in 24:
			if _lit(g, i):
				ci.draw_rect(_cell(i).grow(-2.0), Color(g["col"], 0.12 + 0.22 * k))
	for c in cages:
		var k: float = clampf(c["t"] / c["warn"], 0.0, 1.0)
		ci.draw_circle(Vector2(c["x"], c["y"]), c["r"] * (1.0 - k * 0.15), Color(c["col"], 0.08 + 0.1 * k))

static func draw_over(ci: CanvasItem, t: float) -> void:
	var blink := 0.55 + 0.45 * sin(t * 24.0)
	for g in grids:
		var near: bool = g["t"] > g["warn"] - 0.3
		for i in 24:
			if _lit(g, i):
				ci.draw_rect(_cell(i).grow(-2.0), Color(1.0, 0.35, 0.3, (0.9 if near else 0.55) * blink), false, 1.0)
	for c in cages:
		var n: int = c["n"]
		var g := _gap_slot(c)
		for i in n:
			if _in_gap(i, g, n, c["gw"]):
				continue
			var a := float(i) / n * TAU
			var at := Vector2(c["x"] + cos(a) * c["r"], c["y"] + sin(a) * c["r"])
			ci.draw_rect(Rect2(roundf(at.x) - 2, roundf(at.y) - 2, 4, 4), Color(0.1, 0.06, 0.1, 0.8))
			ci.draw_rect(Rect2(roundf(at.x) - 1, roundf(at.y) - 1, 2, 2), Color(c["col"], blink))
	for s in spinners:
		var o := _owner(s)
		if o == null or s["warn"] <= 0:
			continue
		for i in s["arms"]:
			var a: float = s["a"] + i * TAU / s["arms"]
			var from := Vector2(o.x, o.y - 6)
			ci.draw_line(from, from + Vector2.from_angle(a) * 60.0, Color(s["col"], 0.5 * blink), 1.0)
	for b in orbs:
		var o := _owner(b)
		if o == null:
			continue
		var at := _orb_at(b, o)
		ci.draw_circle(at, 6.0, Color(b["col"], 0.35))
		ci.draw_circle(at, 4.0, Color(b["col"], 0.95))
		ci.draw_circle(at, 1.5, Color(1, 1, 1, 0.95))
	for c in comets:
		var at := Vector2(c["x"], c["y"])
		if c.get("disc", false):
			Gfx.sp(ci, "arci_frisbee", at.x, at.y + 3, 1.6, 1.6, sin(c["t"] * 30.0) * 0.2)   # 58: ARČI's frisbees
			continue
		for k in 3:
			ci.draw_circle(at - Vector2.from_angle(c["a"]) * (4.0 + 3.0 * k), 2.5 - 0.6 * k, Color(c["col"], 0.6 - 0.15 * k))
		ci.draw_circle(at, 4.0, Color(c["col"], 1.0))
		ci.draw_circle(at, 2.0, Color(1, 1, 1, 1.0))
	for q in quakes:
		var c := Vector2(q["x"], q["y"])
		if q["delay"] > 0:
			var k: float = clampf(1.0 - q["delay"] / 0.5, 0.0, 1.0)
			ci.draw_arc(c, 10.0 + 12.0 * k, 0.0, TAU, 24, Color(q["col"], 0.6 * blink), 1.0)
			continue
		var g0: float = q["gap"] + q["gw"] * 0.5
		var span: float = TAU - q["gw"]
		ci.draw_arc(c, q["r"], g0, g0 + span, 48, Color(q["col"], 0.85), 3.0)
		ci.draw_arc(c, q["r"], g0, g0 + span, 48, Color(1.0, 0.95, 0.9, 0.9), 1.0)
