class_name Chaos
extends RefCounted
## 9.1 Chaos attacks (his ask, 6 Oct, from pictures of another game's final boss: lasers, chains and
## a red circle. Ideas only). Every one is shown before it can hurt:
##   BEAMS     thin warning lines from the boss, then lasers that sweep round it.
##   LASER X   a cross of four lasers that turns, with a ring of shots when it lights.
##   HOOKS     chains flung from the boss to the walls; they swing across the room, then pull back.
##   CIRCLE    a red ring round the boss (and smaller ones under you) fills up, then blasts.
## Bosses call them through BossAI (states "lasers", "laserx", "hooks", "zone"). tick() moves them
## (from Hazards.update), clear() empties them when the room changes or a stage breaks.
## Expanded game only.

const BEAM_W := 7.0      # a beam's width
const HOOK_W := 4.0      # a chain's width
const HIT_CD := 0.6      # one thing hurts at most this often

static var beams: Array = []   # { x, y, a, spin, len, warn, fire, owner, by, cd }
static var hooks: Array = []   # { a, len, max, out, swing, spin, back, owner, by, cd }
static var zones: Array = []   # { x, y, r, warn, t, by, ring }

static func clear() -> void:
	beams.clear()
	hooks.clear()
	zones.clear()

static func busy() -> bool:
	return not (beams.is_empty() and hooks.is_empty() and zones.is_empty())

# ---------- The moves ----------
## n lasers round the boss: warn s of warning, then fire s of sweeping at spin rad/s.
static func cast_beams(e: Enemy, n: int, warn: float, fire: float, spin: float) -> float:
	if beams.size() >= 8:
		return 0.3   # never more than eight at once
	var a0 := TB.ang_to(e, G.player) + PI / n
	for i in n:
		beams.append({ "x": e.x, "y": e.y - 6, "a": a0 + i * TAU / n, "spin": spin, "len": 520.0,
			"warn": warn, "fire": fire, "owner": weakref(e), "by": e.d.get("name", "A FOE"), "cd": 0.0 })
	Snd.play("charge")
	return warn + fire

static func cast_cross(e: Enemy, warn: float, fire: float, spin: float, spr: String) -> float:
	var t := cast_beams(e, 4, warn, fire, spin)
	zones.append({ "x": e.x, "y": e.y - 6, "r": 0.0, "warn": warn, "t": 0.0, "by": e.d.get("name", "A FOE"), "ring": spr, "quiet": true })
	return t

## n chains toward and around the hero.
static func cast_hooks(e: Enemy, n: int, swing: float) -> float:
	if hooks.size() >= 8:
		return 0.3
	var at := TB.ang_to(e, G.player)
	for i in n:
		var a := at + (i - (n - 1) / 2.0) * (TAU / n)
		hooks.append({ "a": a, "len": 0.0, "max": 300.0, "out": 0.45, "swing": swing,
			"spin": (1.1 if i % 2 == 0 else -1.1), "back": 0.4, "owner": weakref(e), "by": e.d.get("name", "A FOE"), "cd": 0.0 })
	return 0.45 + swing + 0.4

## A big circle round the boss and `small` circles under the hero.
static func cast_zone(e: Enemy, r: float, warn: float, small: int, spr: String) -> float:
	zones.append({ "x": e.x, "y": e.y - 4, "r": r, "warn": warn, "t": 0.0, "by": e.d.get("name", "A FOE"), "ring": spr })
	var p := G.player
	for i in small:
		var off := Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * 40.0
		zones.append({ "x": p.x + off.x, "y": p.y + off.y, "r": 30.0, "warn": warn + 0.25 * i, "t": 0.0, "by": e.d.get("name", "A FOE"), "ring": "" })
	return warn + 0.3

# ---------- Every tick ----------
static func tick(dt: float) -> void:
	if not busy():
		return
	var p := G.player
	_tick_beams(p, dt)
	_tick_hooks(p, dt)
	_tick_zones(p, dt)

static func _anchor(b: Dictionary) -> Vector2:
	var o: Enemy = b["owner"].get_ref()
	if o != null and o.hp > 0:
		return Vector2(o.x, o.y - 6)
	return Vector2(b.get("x", 0.0), b.get("y", 0.0))

static func _seg_hit(p: Player, a: Vector2, b: Vector2, w: float) -> bool:
	var q := Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.y - 4), a, b)
	return q.distance_to(Vector2(p.x, p.y - 4)) < w * 0.5 + p.r

static func _tick_beams(p: Player, dt: float) -> void:
	var keep := []
	for b in beams:
		var o: Enemy = b["owner"].get_ref()
		if o == null or o.hp <= 0:
			continue   # the boss fell: its beams go out
		var at := _anchor(b)
		b["x"] = at.x
		b["y"] = at.y
		b["cd"] -= dt
		if b["warn"] > 0:
			b["warn"] -= dt
			if b["warn"] <= 0:
				Snd.play("beam")
		else:
			b["fire"] -= dt
			b["a"] += b["spin"] * dt
			if b["fire"] <= 0:
				continue
			var end: Vector2 = at + Vector2.from_angle(b["a"]) * b["len"]
			if b["cd"] <= 0 and _seg_hit(p, at, end, BEAM_W):
				b["cd"] = HIT_CD
				Combat.hurt_player(1, b["by"])
		keep.append(b)
	beams = keep

static func _tick_hooks(p: Player, dt: float) -> void:
	var keep := []
	for h in hooks:
		var o: Enemy = h["owner"].get_ref()
		if o == null or o.hp <= 0:
			continue
		h["cd"] -= dt
		if h["out"] > 0:
			h["out"] -= dt
			h["len"] = h["max"] * (1.0 - h["out"] / 0.45)
		elif h["swing"] > 0:
			h["swing"] -= dt
			h["a"] += h["spin"] * dt
		elif h["back"] > 0:
			h["back"] -= dt
			h["len"] = h["max"] * maxf(0.0, h["back"] / 0.4)
		else:
			continue
		var at := Vector2(o.x, o.y - 6)
		if h["cd"] <= 0 and _seg_hit(p, at, at + Vector2.from_angle(h["a"]) * h["len"], HOOK_W):
			h["cd"] = HIT_CD
			Combat.hurt_player(1, h["by"])
		keep.append(h)
	hooks = keep

static func _tick_zones(p: Player, dt: float) -> void:
	var keep := []
	for z in zones:
		z["t"] += dt
		if z["t"] < z["warn"]:
			keep.append(z)
			continue
		# It blasts.
		if z["r"] > 0:
			if TB.dist_xy(p.x, p.y, z["x"], z["y"]) < z["r"]:
				Combat.hurt_player(1, z["by"])
			Fx.burst(z["x"], z["y"], ["#ff4a3a", "#ffd0c0"], 14 if z["r"] < 50 else 26, z["r"] * 1.6)
			G.add_shake(3 if z["r"] < 50 else 7)
		if z["ring"] != "":
			Combat.ering(z["x"], z["y"], 18, 70, randf(), z["ring"])
		if not z.get("quiet", false):
			Snd.play("boom")
	zones = keep

# ---------- Drawing (world_view: the ground under everyone, the lasers over) ----------
static func draw_ground(ci: CanvasItem, t: float) -> void:
	for z in zones:
		if z["r"] <= 0:
			continue
		var k: float = clampf(z["t"] / z["warn"], 0.0, 1.0)
		var c := Vector2(z["x"], z["y"])
		ci.draw_circle(c, z["r"] * k, Color(0.85, 0.12, 0.12, 0.28))
		ci.draw_arc(c, z["r"], 0.0, TAU, 48, Color(1.0, 0.25, 0.2, 0.75 + 0.25 * sin(t * 20.0)), 2.0)
		ci.draw_arc(c, z["r"] - 4.0, 0.0, TAU, 48, Color(1.0, 0.25, 0.2, 0.3), 1.0)

static func draw_over(ci: CanvasItem, t: float) -> void:
	for b in beams:
		var a := Vector2(b["x"], b["y"])
		var end: Vector2 = a + Vector2.from_angle(b["a"]) * b["len"]
		if b["warn"] > 0:
			ci.draw_line(a, end, Color(1.0, 0.3, 0.3, 0.35 + 0.35 * sin(t * 30.0)), 1.0)
		else:
			var flick := 0.85 + 0.15 * sin(t * 50.0 + b["a"])
			ci.draw_line(a, end, Color(0.9, 0.08, 0.15, 0.45 * flick), BEAM_W + 4.0)
			ci.draw_line(a, end, Color(1.0, 0.2, 0.25, 0.95 * flick), BEAM_W)
			ci.draw_line(a, end, Color(1.0, 0.92, 0.92, flick), 2.0)
	for h in hooks:
		var o: Enemy = h["owner"].get_ref()
		if o == null:
			continue
		var a := Vector2(o.x, o.y - 6)
		var dir := Vector2.from_angle(h["a"])
		var n := int(h["len"] / 7.0)
		# 17.1: each link a small square ring of rects (they batch; an arc per link cost a draw call each).
		for i in n:
			var c := a + dir * (i * 7.0 + 4.0)
			var lc := Color(0.92, 0.9, 0.95, 1.0) if i % 2 == 0 else Color(0.85, 0.15, 0.2, 1.0)
			var x := roundf(c.x) - 2.0
			var y := roundf(c.y) - 2.0
			ci.draw_rect(Rect2(x, y, 5, 1), lc)
			ci.draw_rect(Rect2(x, y + 4, 5, 1), lc)
			ci.draw_rect(Rect2(x, y + 1, 1, 3), lc)
			ci.draw_rect(Rect2(x + 4, y + 1, 1, 3), lc)
		var tip: Vector2 = a + dir * h["len"]
		ci.draw_arc(tip, 5.0, h["a"] - 1.6, h["a"] + 1.6, 10, Color(1.0, 0.95, 0.95), 2.0)
		ci.draw_arc(tip, 6.5, h["a"] - 1.6, h["a"] + 1.6, 10, Color(0.85, 0.15, 0.2), 1.0)
