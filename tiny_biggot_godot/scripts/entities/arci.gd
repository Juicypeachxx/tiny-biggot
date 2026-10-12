class_name Arci
extends RefCounted
## ARČI THE PUSSY SLAYER: the first floor's guardian in the expanded game, after the owner's own dog
## (his word, 12 Oct, with ten photos: "I want stage one boss to be custom ... i want my do to be
## first boss he is hyperactive border collie"; the name is his word). A black and white border
## collie who never stops. --classic keeps THE BONE COLOSSUS on the first floor (it is now one of
## the second floor's guardians in the expanded game). His art is ours, from the photos
## (tools/art/stage58_arci.py).
##
## First phase: BOOP BOOP BOOP (nose-first dashes down lanes shown first), FRISBEE (a disc flies out
## on a curve shown first and he races down a lane to catch it), HERDING (a ring round you shows
## where he will run: he circles you, yipping shots in, then cuts across), CAT! (a cat bolts across
## the room down a lane and he bolts after it, into the wall) and CRASH (worn out, he flops on his
## back with his tongue out: he takes half again as much).
## Second phase, at half health: SUNGLASSES ON, too cool to stop: faster, four boops, two frisbees,
## two cats, and STICK (he tears round an oval shown first with a huge stick across his jaws).
## Beaten, he is not slain: he rolls over for a belly rub and stays there, asleep (on_beaten).
##
## The fight runs in RiftBosses (phases, the grace between them, the stage at a quarter); this file
## holds his moves and his drawing.

const BOOP_WARN := 0.45
const BOOP_SPEED := 300.0
const DISC_T := 0.8            # a frisbee's flight to where he catches it
const HERD_R := 64.0           # the ring he runs round you
const HERD_T := 2.4
const CAT_WARN := 0.7
const CAT_SPEED := 340.0
const CRASH_T := 3.0
const STICK_HALF := 26.0       # half the stick, across his jaws
const TRACK := Vector2(150.0, 70.0)   # the oval he runs with the stick
const CENTER := Vector2(14.0 * 16, 9.6 * 16)
const NAME_SHORT := "ARČI"

static func is_arci(e: Enemy) -> bool:
	return e != null and e.boss == "arci"

static func _me(e: Enemy) -> Dictionary:
	if e.parts.is_empty() or e.parts[0].get("kind", "") != "arci":
		e.parts = [{ "kind": "arci", "discs": [], "cat": {}, "out": false }]
	return e.parts[0]

## The second phase: faster in everything.
static func _fast(e: Enemy) -> float:
	return 1.15 if e.phase == 2 else 1.0

# ---------- The fight (from RiftBosses.update) ----------
## The grace between the phases: he sits, and the sunglasses go on.
static func to_cool(e: Enemy, dt: float) -> void:
	e.z = 0.0
	if e.sub == 0 and e.st >= 0.5:
		e.sub = 1
		Fx.burst(e.x, e.y - 20, ["#141018", "#5a6a8a", "#ffffff"], 14, 70)
		Fx.float_text(e.x, e.y - 44, "TOO COOL", "white", true)
		Snd.play("shield")
	if e.st >= RiftBosses.PHASE_T - 0.05:
		e.speed = 70.0

## Resting is not his thing: he bounces about and keeps you in sight.
static func rest_move(e: Enemy, p: Player, dt: float) -> void:
	EnemyAI.wander_keep(e, dt, p, 60, 130)
	e.face = 1 if p.x > e.x else -1
	e.z = absf(sin(e.st * 11.0)) * 3.0   # can't stand still

## Damage (RiftBosses.adjust_damage): asleep on his back, half again as much.
static func adjust_damage(e: Enemy, dmg: float) -> float:
	if e.state == &"crash" and e.sub == 1:
		return dmg * 1.5
	return dmg

static func attack(e: Enemy, p: Player, dt: float) -> void:
	var h2 := e.phase == 2
	match e.state:
		&"boop": _boop(e, p, dt, 4 if h2 else 3)
		&"frisbee": _frisbee(e, p, dt)
		&"herd": _herd(e, p, dt)
		&"cat": _cat(e, p, dt, 2 if h2 else 1)
		&"crash": _crash(e, p, dt)
		&"stick": _stick(e, p, dt)

## How far he can run that way before a wall or a pillar stops him.
static func _run_len(x: float, y: float, a: float, most: float) -> float:
	return maxf(16.0, Afx.reach(x, y, a, most, World.M_WALKER) - 10.0)

## BOOP BOOP BOOP: a lane to where you are, then he shoots down it nose first.
static func _boop(e: Enemy, p: Player, dt: float, boops: int) -> void:
	match e.sub:
		0:
			if e.st < 0.02:
				e.ca = TB.ang_to(e, p)
				e.aux2 = _run_len(e.x, e.y, e.ca, TB.dist(e, p) + 40.0)
				e.face = 1 if cos(e.ca) > 0 else -1
				e.from = Vector2(e.x, e.y)
			e.z = 0.0
			if e.st >= BOOP_WARN / _fast(e):
				e.sub = 1
				e.st = 0.0
				Snd.play("hatchet")
		1:
			var d := minf(e.st * BOOP_SPEED * _fast(e), e.aux2)
			e.x = e.from.x + cos(e.ca) * d
			e.y = e.from.y + sin(e.ca) * d
			if TB.dist(e, p) < e.r + p.r + 2.0 and p.invuln <= 0 and p.dodge_t <= 0:
				Fx.float_text(p.x, p.y - 18, "BOOP!", "pink")
			if d >= e.aux2:
				e.repeat += 1
				Afx.dust(e.x, e.y + 8)
				if e.repeat >= boops:
					e.repeat = 0
					RiftBosses._done(e, 0.6)
				else:
					e.sub = 2
					e.st = 0.0
		2:
			if e.st >= 0.15:
				e.sub = 0
				e.st = 0.0

## A point on a frisbee's curve (a bend out to one side).
static func disc_at(d: Dictionary, k: float) -> Vector2:
	var a: Vector2 = d["s"]
	var c: Vector2 = d["c"]
	var b: Vector2 = d["e"]
	return a.lerp(c, k).lerp(c.lerp(b, k), k)

## FRISBEE: a disc flies out on a curve (shown first) and he races down a lane to catch it at its end.
## Second phase: a second disc on the other curve, that flies on and drops.
static func _frisbee(e: Enemy, p: Player, dt: float) -> void:
	var me := _me(e)
	match e.sub:
		0:
			if e.st < 0.02:
				var a := TB.ang_to(e, p)
				var ln := _run_len(e.x, e.y, a, TB.dist(e, p) + 50.0)
				var s := Vector2(e.x, e.y - 14)
				var end := RiftBosses._inside(Vector2(e.x + cos(a) * ln, e.y + sin(a) * ln))
				var side := 1.0 if randf() < 0.5 else -1.0
				var mid := s.lerp(end, 0.5)
				var perp := (end - s).normalized().orthogonal()
				me["discs"] = [{ "s": s, "c": mid + perp * 70.0 * side, "e": end, "k": 0.0, "mine": true }]
				if e.phase == 2:
					me["discs"].append({ "s": s, "c": mid - perp * 70.0 * side, "e": end, "k": 0.0, "mine": false })
				e.from = Vector2(e.x, e.y)
				e.to = end + Vector2(0, 14)
				e.ca = TB.ang_xy(e.x, e.y, e.to.x, e.to.y)
				e.face = 1 if cos(e.ca) > 0 else -1
			if e.st >= 0.55 / _fast(e):
				e.sub = 1
				e.st = 0.0
				Snd.play("hatchet")
		1:
			var k := minf(1.0, e.st / (DISC_T / _fast(e)))
			for d in me["discs"]:
				d["k"] = k
				var at := disc_at(d, k)
				if TB.dist_xy(at.x, at.y, p.x, p.y - 4) < 5.0 + p.r:
					Combat.hurt_player(1, e.d["name"])
			e.x = lerpf(e.from.x, e.to.x, k)
			e.y = lerpf(e.from.y, e.to.y, k)
			e.z = sin((k - 0.7) / 0.3 * PI) * 22.0 if k > 0.7 else 0.0   # the leap for the catch
			if k >= 1.0:
				e.z = 0.0
				e.sub = 2
				e.st = 0.0
				for d in me["discs"]:
					if not d["mine"]:
						Combat.ering(d["e"].x, d["e"].y, 6, 60, randf() * TAU, "red")
				me["discs"] = []
				if randf() < 0.5:
					Fx.float_text(e.x, e.y - 40, "CAUGHT IT!", "gold")
				Snd.play("hit")
		2:
			if e.st >= 0.25:
				RiftBosses._done(e, 0.6)

## HERDING: a ring round you shows where he will run; he circles you yipping shots in, the ring
## closing, then a lane through the middle and he cuts across.
static func _herd(e: Enemy, p: Player, dt: float) -> void:
	match e.sub:
		0:
			if e.st < 0.02:
				# The ring stays inside the room: its middle at least its size from every wall.
				e.to = Vector2(clampf(p.x, 2.5 * TB.TS + HERD_R, 25.5 * TB.TS - HERD_R),
					clampf(p.y, 3.5 * TB.TS + HERD_R, 16.0 * TB.TS - HERD_R))
				e.angle = TB.ang_xy(e.to.x, e.to.y, e.x, e.y)
				e.aux = 1.0 if randf() < 0.5 else -1.0
				e.aux2 = 0.0
			# He runs to the ring first.
			var on := e.to + Vector2(cos(e.angle), sin(e.angle)) * HERD_R
			var dv := on - Vector2(e.x, e.y)
			var step := 260.0 * dt
			if dv.length() > step:
				e.x += dv.normalized().x * step
				e.y += dv.normalized().y * step
			if e.st >= 0.6 / _fast(e):
				e.sub = 1
				e.st = 0.0
				Snd.play("bark")
				Barks.say(e, "WOOF WOOF!", "white", 1.0)
		1:
			var span := HERD_T / _fast(e)
			var k := minf(1.0, e.st / span)
			var r := HERD_R - 18.0 * k
			e.angle += e.aux * 3.3 * _fast(e) * dt
			var at := e.to + Vector2(cos(e.angle), sin(e.angle)) * r
			e.face = 1 if at.x > e.x else -1
			_run_to(e, at, 520.0 * dt)
			e.aux2 -= dt
			if e.aux2 <= 0:
				e.aux2 = 0.34 / _fast(e)
				Combat.eshot(e.x, e.y - 8, TB.ang_xy(e.x, e.y, e.to.x, e.to.y) + randf_range(-0.25, 0.25), 70.0 * _fast(e), "bone")
				if randf() < 0.3:
					Fx.float_text(e.x, e.y - 30, "YIP!", "white")
			if k >= 1.0:
				e.sub = 2
				e.st = 0.0
				e.ca = TB.ang_xy(e.x, e.y, e.to.x, e.to.y)
				e.from = Vector2(e.x, e.y)
				e.aux2 = _run_len(e.x, e.y, e.ca, r * 2.0 + 20.0)
		2:
			if e.st >= 0.3:
				e.sub = 3
				e.st = 0.0
				Snd.play("hatchet")
		3:
			var d := minf(e.st * BOOP_SPEED * 1.1 * _fast(e), e.aux2)
			e.x = e.from.x + cos(e.ca) * d
			e.y = e.from.y + sin(e.ca) * d
			e.face = 1 if cos(e.ca) > 0 else -1
			if d >= e.aux2:
				Afx.dust(e.x, e.y + 8)
				RiftBosses._done(e, 0.7)

## CAT!: a cat bolts across the room down a lane (shown first) and he bolts after it, into the wall.
static func _cat(e: Enemy, p: Player, dt: float, cats: int) -> void:
	var me := _me(e)
	match e.sub:
		0:
			if e.st < 0.02:
				e.ca = TB.ang_to(e, p) + randf_range(-0.2, 0.2)
				e.aux2 = Afx.reach(e.x, e.y, e.ca, 520.0, World.M_WALKER)
				e.from = Vector2(e.x, e.y)
				e.face = 1 if cos(e.ca) > 0 else -1
				me["cat"] = { "x": e.x + cos(e.ca) * 30.0, "y": e.y + sin(e.ca) * 30.0, "a": e.ca, "d": 30.0 }
				Barks.say(e, "CAT!!!", "gold", 1.0)
				Snd.play("bark")
			if e.st >= CAT_WARN / _fast(e):
				e.sub = 1
				e.st = 0.0
				Snd.play("charge")
		1:
			var cat: Dictionary = me["cat"]
			cat["d"] = minf(e.aux2 + 40.0, cat["d"] + CAT_SPEED * 1.15 * dt)
			cat["x"] = e.from.x + cos(e.ca) * cat["d"]
			cat["y"] = e.from.y + sin(e.ca) * cat["d"]
			var d := minf(e.st * CAT_SPEED * _fast(e), maxf(0.0, e.aux2 - 12.0))
			e.x = e.from.x + cos(e.ca) * d
			e.y = e.from.y + sin(e.ca) * d
			if d >= e.aux2 - 12.0:
				# The cat is over the wall; he is not.
				me["cat"] = {}
				G.add_shake(3)
				Snd.play("hit")
				Fx.float_text(e.x, e.y - 40, "BONK", "white", true)
				Afx.dust(e.x, e.y + 8)
				e.sub = 2
				e.st = 0.0
		2:
			if e.st >= 0.6:
				e.repeat += 1
				if e.repeat >= cats:
					e.repeat = 0
					RiftBosses._done(e, 0.5)
				else:
					e.sub = 0
					e.st = 0.0

## CRASH: worn out, he flops on his back, tongue out, asleep (he takes half again as much), then
## he is up again as if nothing happened.
static func _crash(e: Enemy, p: Player, dt: float) -> void:
	e.z = 0.0
	match e.sub:
		0:
			if e.st >= 0.25:
				e.sub = 1
				e.st = 0.0
				Snd.play("hit")
				Fx.burst(e.x, e.y + 6, ["#f2efe6", "#35313d"], 10, 50)
		1:
			if e.st >= (2.2 if e.phase == 2 else CRASH_T):
				e.sub = 2
				e.st = 0.0
				Fx.float_text(e.x, e.y - 40, "!", "gold", true)
				Snd.play("bark")
		2:
			if e.st >= 0.2:
				RiftBosses._done(e, 0.3)

## A step towards a point that moves (his ring, his oval): he catches up with it, never jumps.
static func _run_to(e: Enemy, at: Vector2, step: float) -> void:
	var dv := at - Vector2(e.x, e.y)
	if dv.length() > step:
		dv = dv.normalized() * step
	e.x += dv.x
	e.y += dv.y

static func track_at(a: float) -> Vector2:
	return CENTER + Vector2(cos(a) * TRACK.x, sin(a) * TRACK.y)

## Where the stick is: across his jaws, square to the way he runs.
static func stick_ends(e: Enemy) -> Array:
	var mouth := Vector2(e.x + 12.0 * e.face, e.y - 10.0 - e.z)
	var side := Vector2(cos(e.ca), sin(e.ca)).orthogonal() * STICK_HALF
	return [mouth - side, mouth + side]

## STICK (second phase): he finds a huge stick and tears round an oval (shown first) with it across his
## jaws: a lap and a half, and the stick hits whatever it sweeps.
static func _stick(e: Enemy, p: Player, dt: float) -> void:
	match e.sub:
		0:
			if e.st < 0.02:
				e.aux = 1.0 if randf() < 0.5 else -1.0
				var dv := Vector2(e.x, e.y) - CENTER
				e.angle = atan2(dv.y / TRACK.y, dv.x / TRACK.x)
				e.aux2 = 0.0
				Barks.say(e, "STICK!", "gold", 1.0)
			var on := track_at(e.angle)
			var dv2 := on - Vector2(e.x, e.y)
			var step := 240.0 * dt
			if dv2.length() > step:
				e.x += dv2.normalized().x * step
				e.y += dv2.normalized().y * step
			if e.st >= 0.75:
				e.sub = 1
				e.st = 0.0
				Snd.play("charge")
		1:
			var turn := TAU / 1.5 * dt
			e.angle += e.aux * turn
			e.aux2 += turn
			var at := track_at(e.angle)
			e.ca = TB.ang_xy(e.x, e.y, at.x, at.y)
			e.face = 1 if at.x > e.x else -1
			_run_to(e, at, 600.0 * dt)
			var ends := stick_ends(e)
			if RiftBosses._near_seg(p.x, p.y, ends[0], ends[1], 5.0 + p.r * 0.5):
				Combat.hurt_player(1, e.d["name"])
			if e.aux2 >= TAU * 1.5:
				RiftBosses._done(e, 0.6)

## Beaten (Game.on_boss_dead): he rolls over for a belly rub and stays there asleep.
static func on_beaten(b: Enemy) -> void:
	if G.banner.is_empty() or G.banner.get("t", 0.0) < 2.0:
		G.show_banner("GOOD BOY, " + NAME_SHORT + "!", "HE ROLLS OVER FOR A BELLY RUB")
	else:
		G.toast("GOOD BOY, " + NAME_SHORT + "!", "pink")   # (a banner of the fight's end is up)
	Snd.play("bark")
	G.room.objects.append({ "kind": "arci_rest", "x": b.x, "y": b.y, "look": look(b) })

# ---------- Drawing ----------
## His look (Stages.look; every guardian evolves with its stages): 2 his sunglasses (from the moment
## they go on), 3 the sunglasses and a gold aura (his last stage).
static func look(e: Enemy) -> int:
	return maxi(Stages.look(e), 2 if e.state == &"phase" and e.sub == 1 else 1)

## world_view._enemy_sprite: standing, running (on his dashes and laps) or asleep on his back, in his
## look.
static func sprite(e: Enemy) -> String:
	var s := "arci"
	if e.state == &"crash" and e.sub >= 1:
		s = "arci_lie"
	elif (e.state == &"boop" and e.sub == 1) or (e.state == &"frisbee" and e.sub == 1) or (e.state == &"herd" and e.sub >= 1) \
			or (e.state == &"cat" and e.sub == 1) or (e.state == &"stick" and e.sub == 1):
		s = "arci_run"
	var lk := look(e)
	return s + ("_s%d" % lk if lk > 1 else "")

## With his body (RiftBosses.draw_parts): his frisbees, the cat, the stick, Z's while he sleeps.
static func draw_parts(ci: CanvasItem, e: Enemy, foot: float, t: float) -> void:
	var me := _me(e)
	for d in me["discs"]:
		var at := disc_at(d, d["k"])
		Gfx.sp(ci, "arci_frisbee", at.x, at.y + 3, 2.0, 2.0, sin(t * 30.0) * 0.15)
	var cat: Dictionary = me["cat"]
	if not cat.is_empty():
		Gfx.sp(ci, "kitten", cat["x"], cat["y"] + 6, 1.6, 1.6, 0.0, cos(cat["a"]) < 0)
	if e.state == &"stick":
		var ends := stick_ends(e)
		var e0: Vector2 = ends[0]
		var e1: Vector2 = ends[1]
		var mid := (e0 + e1) * 0.5
		Gfx.sprite(ci, "arci_stick", mid.x, mid.y, 15, 3, 2.0, 2.0, (e1 - e0).angle(), false)
	if e.state == &"crash" and e.sub == 1:
		var k := fmod(t * 0.8, 1.0)
		Gfx.text(ci, "Z", e.x + 18 + k * 8, foot - 30 - k * 14, "white", 1, 0.5, true, 1.0 - k)
	if e.state == &"cat" and e.sub == 0:
		Gfx.text(ci, "!", e.x, foot - 62, "gold", 2, 0.5)

## On the floor with the other warnings (RiftBosses.draw_ground).
static func draw_ground(ci: CanvasItem, e: Enemy, t: float) -> void:
	var warn := Afx.C_WARN
	var me := _me(e)
	match e.state:
		&"boop":
			if e.sub == 0:
				Afx.lane(ci, e.from.x, e.from.y, e.ca, 9.0, e.aux2, e.st / (BOOP_WARN / _fast(e)), warn, t)
		&"frisbee":
			if e.sub == 0:
				var k := clampf(e.st / (0.55 / _fast(e)), 0.0, 1.0)
				for d in me["discs"]:
					for i in 16:
						if i % 2 == 1:
							continue
						var a0 := disc_at(d, i / 16.0)
						var a1 := disc_at(d, (i + 1) / 16.0)
						ci.draw_line(a0 + Vector2(0, 12), a1 + Vector2(0, 12), Color(warn.r, warn.g, warn.b, 0.4 + 0.5 * k), 2.0)
				Afx.lane(ci, e.from.x, e.from.y, e.ca, 8.0, TB.dist_xy(e.from.x, e.from.y, e.to.x, e.to.y), k, warn, t)
		&"herd":
			if e.sub == 0 or e.sub == 1:
				var r := HERD_R if e.sub == 0 else HERD_R - 18.0 * minf(1.0, e.st / (HERD_T / _fast(e)))
				var n := 36
				for i in n:
					if i % 2 == 1:
						continue
					var a0 := float(i) / n * TAU
					var a1 := float(i + 1) / n * TAU
					ci.draw_line(e.to + Vector2(cos(a0), sin(a0)) * r, e.to + Vector2(cos(a1), sin(a1)) * r, Color(warn.r, warn.g, warn.b, 0.8), 2.0)
			elif e.sub == 2:
				Afx.lane(ci, e.from.x, e.from.y, e.ca, 9.0, e.aux2, e.st / 0.3, warn, t)
		&"cat":
			if e.sub == 0:
				Afx.lane(ci, e.from.x, e.from.y, e.ca, 10.0, e.aux2, e.st / (CAT_WARN / _fast(e)), warn, t)
		&"stick":
			if e.sub == 0:
				var n := 40
				for i in n:
					if i % 2 == 1:
						continue
					ci.draw_line(track_at(float(i) / n * TAU), track_at(float(i + 1) / n * TAU), Color(warn.r, warn.g, warn.b, 0.85), 2.0)

## Beaten: asleep on his back where he fell (Game.on_boss_dead put him there; world_view draws him).
static func draw_rest(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var lk: int = o.get("look", 1)
	Gfx.sp(ci, "arci_lie" + ("_s%d" % lk if lk > 1 else ""), o["x"], o["y"] + 12, 2.0, 2.0)
	var k := fmod(t * 0.6, 1.0)
	Gfx.text(ci, "Z", o["x"] + 20 + k * 8, o["y"] - 20 - k * 14, "white", 1, 0.5, true, 1.0 - k)
	if fmod(t, 2.0) < 1.0:
		Gfx.text(ci, "<3", o["x"] - 18, o["y"] - 26 - fmod(t, 1.0) * 6.0, "pink", 1, 0.5, true, 1.0 - fmod(t, 1.0))
