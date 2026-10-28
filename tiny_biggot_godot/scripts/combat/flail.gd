class_name Flail
extends RefCounted
## 10.4 Flails (his ask, 6 Oct, from his trailer clips: ideas only). A new weapon kind: a spiked ball
## on a chain circles you all the time and hurts every foe it touches; each attack lashes it out
## toward your aim, harder. +1 PROJECTILE adds a ball (up to four, evenly round you); every one past
## that adds 35% damage. Its hits go through Combat.melee_hit, so crits, ailments and every on-hit
## effect work. Expanded game only (the kind exists only on the new weapons).

const KIND := "flail"
const MAX_BALLS := 4
const ORBIT_R := 26.0
const LASH_R := 70.0
const LASH_T := 0.35
const HIT_CD := 0.3

static var ang := 0.0
static var lash := 0.0          # seconds left of a lash
static var aim := 0.0
static var balls: Array = []    # where each ball is now (for drawing and hits)
static var cds := {}            # foe uid -> seconds until that foe can be hit again

static func handles(kind: String) -> bool:
	return kind == KIND

static func clear() -> void:
	balls.clear()
	cds.clear()
	lash = 0.0

static func _holding(p: Player) -> bool:
	return p != null and p.weapon != null and p.weapon["kind"] == KIND

static func _n(p: Player) -> int:
	return clampi(Weapons.wcount(p), 1, MAX_BALLS)

## An attack: lash out toward the aim.
static func fire(p: Player, a: float, _forced: bool) -> void:
	lash = LASH_T
	aim = a
	Snd.play("hatchet")

static func tick(dt: float) -> void:
	var p := G.player
	if not _holding(p) or G.state != &"play":
		balls.clear()
		return
	var spin := 5.0 + Weapons.wrate(p) * 1.2
	ang += spin * dt
	if lash > 0:
		lash -= dt
	var n := _n(p)
	var extra := maxi(0, Weapons.wcount(p) - MAX_BALLS)
	var size := Weapons.wsize(p)
	balls.clear()
	for i in n:
		var a := ang + float(i) / n * TAU
		var r := ORBIT_R * size
		if lash > 0 and i == 0:
			var k := 1.0 - lash / LASH_T
			a = lerp_angle(a, aim, minf(1.0, k * 3.0))
			r += (LASH_R - ORBIT_R) * size * sin(k * PI)
		balls.append(Vector2(p.x + cos(a) * r, p.y - 4 + sin(a) * r))
	for k in cds.keys():
		cds[k] -= dt
		if cds[k] <= 0:
			cds.erase(k)
	var dmg := Weapons.wdmg(p) * (1.0 + 0.35 * extra)
	var br := 6.0 * size
	for e in G.enemies:
		if e.hp <= 0 or e.spawn_t > 0 or e.hidden or cds.has(e.uid) or not e.targetable():
			continue
		for i in balls.size():
			var b: Vector2 = balls[i]
			if TB.dist_xy(b.x, b.y, e.x, e.y - 4) < br + e.r:
				var hard := lash > 0 and i == 0
				cds[e.uid] = HIT_CD
				Combat.melee_hit(p, e, dmg * (1.6 if hard else 0.6), false, 120 if hard else 50)
				if hard:
					G.add_shake(1)
				break

## Over everyone (world_view): the chains and the spiked balls.
static func draw_over(ci: CanvasItem, _t: float) -> void:
	var p := G.player
	if balls.is_empty() or not _holding(p):
		return
	var hand := Vector2(p.x, p.y - 4)
	var size := Weapons.wsize(p)
	for b in balls:
		var d: Vector2 = b - hand
		var links := int(d.length() / 5.0)
		for k in links:
			var c := hand + d * (float(k) + 0.5) / links
			ci.draw_rect(Rect2(roundf(c.x) - 1, roundf(c.y) - 1, 2, 2), TB.c("#8b8f9c"))
		var r := 4.0 * size
		for s in 6:
			var sa := float(s) / 6.0 * TAU + ang
			ci.draw_line(b, b + Vector2.from_angle(sa) * (r + 2.5), TB.c("#c8c8d0"), 1.0)
		ci.draw_circle(b, r + 1.0, TB.c("#140f1c"))
		ci.draw_circle(b, r, TB.c("#6b6f7c"))
		ci.draw_circle(b - Vector2(1, 1), r * 0.45, TB.c("#c8c8d0"))
