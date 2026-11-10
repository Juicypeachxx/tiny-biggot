class_name Souls
extends RefCounted
## Stage 53 SOULS (his word, 11 Oct: "add new effects and mechanic make it very cool and satisfying").
## Expanded game only. Every foe slain lets out its soul (Combat.kill_enemy calls `on_kill`): a wisp
## that rises, then flies into you, and the SOUL gauge under the XP bar fills (an elite 3, a mini or
## a champion 5, a guardian 10; the OATH OF SOULS doubles them). At NEED (SOULBOUND: 20) it goes off:
## SOUL SURGE, a ring of light that hurts every foe within SURGE_R for 300% of your weapon's damage
## and throws them back, with a white flash and a moment of slow time. A surge at most every GAP
## seconds; souls past it wait in the gauge. Items feed on it: the triggers "on_soul" and "on_surge".
## The gauge is the hero's (`p.souls`, kept with the run); wisps and rings are only drawn.

const NEED := 30
const NEED_FAST := 20
const SURGE_R := 120.0
const SURGE_DMG := 3.0
const GAP := 0.6
const MAX_WISPS := 24

static var wisps: Array = []   # { x, y, vx, vy, t } (drawing only)
static var rings: Array = []   # { x, y, t } (drawing only)
static var flash := 0.0        # the surge's white flash (drawing only)
static var gap := 0.0          # time before the next surge may go off
static var stats := {}

static func _stat(k: String, n: int = 1) -> void:
	stats[k] = stats.get(k, 0) + n

static func clear() -> void:
	wisps.clear()
	rings.clear()
	flash = 0.0

static func need(p: Player) -> int:
	if p.g("soul_avatar") > 0:
		return 15   # 53.2 AVATAR OF SOULS
	return NEED_FAST if p.g("soul_fast") > 0 else NEED

## Combat.kill_enemy: the foe's soul comes out.
static func on_kill(e: Enemy) -> void:
	var p := G.player
	if p == null or not GameData.rogues() or e.type in ["dummy", "target"] or e.charm_t > 0:
		return
	var n := 10 if e.is_boss() else (5 if e.d.get("mini", false) or e.d.get("champion", false) else (3 if e.elite else 1))
	if p.g("soul_mult") > 0:
		n *= 1 + int(p.g("soul_mult"))
	if wisps.size() < MAX_WISPS:
		var a := randf() * TAU
		wisps.append({ "x": e.x, "y": e.y - 6.0, "vx": cos(a) * 50.0, "vy": -60.0 + sin(a) * 30.0, "t": 0.0 })
	add(p, n, e.x, e.y)

## Souls into the gauge (also the action ["souls", n]).
static func add(p: Player, n: int, x: float, y: float) -> void:
	p.souls += n
	_stat("souls", n)
	if not p.procs.is_empty():
		Effects.fire("on_soul", { "x": x, "y": y, "n": n })
	if p.souls >= need(p) and gap <= 0.0:
		surge(p)

## SOUL SURGE.
static func surge(p: Player) -> void:
	p.souls -= need(p)
	gap = GAP
	_stat("surge")
	var dmg := Weapons.wdmg(p) * SURGE_DMG * (1.0 + p.g("surge_dmg"))
	for e in G.enemies.duplicate():
		if e.targetable() and e.charm_t <= 0 and TB.dist(e, p) < SURGE_R + e.r:
			var out := Vector2(e.x - p.x, e.y - p.y).normalized() * 80.0
			Combat.damage_enemy(e, dmg, { "col": "white", "kx": out.x, "ky": out.y })
			if e.hp > 0 and p.g("surge_stun") > 0:
				Statuses.apply(e, "stun", 1, dmg)
	if p.g("surge_heal") > 0:
		p.heal(1)
	rings.append({ "x": p.x, "y": p.y - 6.0, "t": 0.0 })
	flash = 0.18
	G.hitstop = maxf(G.hitstop, 0.07)   # a moment of slow time
	G.add_shake(4)
	Fx.texts.append({ "x": p.x, "y": p.y - 30.0, "text": "SOUL SURGE!", "col": "cyan", "life": 1.0, "big": true })
	Fx.burst(p.x, p.y - 6, ["#ffffff", "#bfefff", "#e88ad8"], 24, 110, 0.5)
	Snd.play("boom")
	if not p.procs.is_empty():
		Effects.fire("on_surge", { "x": p.x, "y": p.y })

## Hazards.update: wisps fly home; a waiting surge goes off when it may.
static func tick(dt: float) -> void:
	var p := G.player
	if p == null:
		return
	gap = maxf(0.0, gap - dt)
	flash = maxf(0.0, flash - dt)
	if gap <= 0.0 and p.souls >= need(p) and GameData.rogues():
		surge(p)
	if not wisps.is_empty():
		var keep := []
		for w in wisps:
			w["t"] += dt
			var to := Vector2(p.x - w["x"], p.y - 6.0 - w["y"])
			if w["t"] > 0.25:   # it rises first, then homes in, faster and faster
				var pull: Vector2 = to.normalized() * (500.0 + 900.0 * float(w["t"])) * dt
				w["vx"] = w["vx"] * 0.9 + pull.x
				w["vy"] = w["vy"] * 0.9 + pull.y
			w["x"] += w["vx"] * dt
			w["y"] += w["vy"] * dt
			if to.length() > 8.0 and w["t"] < 2.0:
				keep.append(w)
		wisps = keep
	if not rings.is_empty():
		for r in rings:
			r["t"] += dt
		rings = rings.filter(func(r): return r["t"] < 0.45)

## Over the people (world_view): the wisps and the surge's ring.
static func draw_over(ci: CanvasItem, t: float) -> void:
	for w in wisps:
		var c := Vector2(w["x"], w["y"])
		var tail := Vector2(w["vx"], w["vy"]).normalized() * -4.0
		ci.draw_line(c, c + tail, Color(0.75, 0.95, 1.0, 0.45), 1.0)
		ci.draw_rect(Rect2(roundf(c.x) - 1, roundf(c.y) - 1, 2, 2), Color(0.85, 0.97, 1.0))
		if fmod(t * 10.0 + w["x"], 2.0) < 1.0:
			ci.draw_rect(Rect2(roundf(c.x), roundf(c.y) - 2, 1, 1), Color(1, 1, 1))
	for r in rings:
		var k: float = r["t"] / 0.45
		var rr := SURGE_R * (0.2 + 0.8 * k)
		ci.draw_arc(Vector2(r["x"], r["y"]), rr, 0.0, TAU, 48, Color(0.85, 0.97, 1.0, 1.0 - k), 2.0)
		ci.draw_arc(Vector2(r["x"], r["y"]), rr * 0.8, 0.0, TAU, 40, Color(0.91, 0.54, 0.85, (1.0 - k) * 0.6), 1.0)
	if flash > 0.0:
		ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), Color(1, 1, 1, flash * 1.2))

## The gauge on the HUD, under the XP bar.
static func draw_hud(ci: CanvasItem, p: Player) -> void:
	var nd := need(p)
	ci.draw_rect(Rect2(5, 32, 82, 3), TB.c("#140f1c"))
	ci.draw_rect(Rect2(6, 33, roundf(80.0 * minf(1.0, float(p.souls) / nd)), 1), TB.c("#bfefff" if p.souls < nd else "#ffffff"))
