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
## His frisbee (his word, 12 Oct: "He loves his frizbie he is obsessed with his frizbies"): he carries
## it in his mouth; DROP IT (he drops it at your feet and stares: step on it and you throw it, and he
## bolts after it, too happy to mind your blows, x1.5, and too happy to bite; leave it and he barks at
## you twice, fans of shots); FRENZY (second phase: four frisbees fanned out on curves shown first, and he
## fetches every one, a lane shown before each dash); BOUNCE (second phase: a frisbee off the walls,
## three bounces on a path shown first, he right behind it); his RESOLVE answer flies frisbees after
## you (Patterns, comets); he sleeps beside it when beaten.
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
const DROP_WAIT := 3.0         # DROP IT: how long he waits for you to throw it
const FRENZY_N := 4
const BOUNCE_SPEED := 300.0

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

## Damage (RiftBosses.adjust_damage): asleep on his back, or off after the frisbee you threw, half
## again as much.
static func adjust_damage(e: Enemy, dmg: float) -> float:
	if (e.state == &"crash" and e.sub == 1) or (e.state == &"dropit" and (e.sub == 2 or e.sub == 3)):
		return dmg * 1.5
	return dmg

## Combat.update_enemies: no bite while he sleeps, waits for his throw or runs after it.
static func harmless(e: Enemy) -> bool:
	return e.state == &"crash" or (e.state == &"dropit" and e.sub >= 1 and e.sub <= 3)

static func attack(e: Enemy, p: Player, dt: float) -> void:
	var h2 := e.phase == 2
	match e.state:
		&"boop": _boop(e, p, dt, 4 if h2 else 3)
		&"frisbee": _frisbee(e, p, dt)
		&"herd": _herd(e, p, dt)
		&"cat": _cat(e, p, dt, 2 if h2 else 1)
		&"crash": _crash(e, p, dt)
		&"stick": _stick(e, p, dt)
		&"dropit": _dropit(e, p, dt)
		&"frenzy": _frenzy(e, p, dt)
		&"bounce": _bounce(e, p, dt)
	# However he runs, he stays on the open floor (not under the top bar, not in a wall).
	var c := RiftBosses._inside(Vector2(e.x, e.y))
	e.x = c.x
	e.y = c.y

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
				if Coop.on():   # (W4: the other heroes too)
					Coop.hazard(func(hero: Player) -> bool: return TB.dist_xy(at.x, at.y, hero.x, hero.y - 4) < 5.0 + hero.r, e.d["name"])
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
			if Coop.on():   # (W4: the other heroes too)
				Coop.hazard(func(hero: Player) -> bool: return RiftBosses._near_seg(hero.x, hero.y, ends[0], ends[1], 5.0 + hero.r * 0.5), e.d["name"])
			if e.aux2 >= TAU * 1.5:
				RiftBosses._done(e, 0.6)

## DROP IT: he trots up, drops his frisbee at your feet and stares. Step on it and you throw it: he
## bolts after it (away to one side), too happy to mind your blows. Leave it and he barks at you twice
## (fans of shots), then picks it up again.
## A hero on the frisbee he dropped throws it (W4: in co-op, any standing one).
static func _stepped(p: Player, d: Dictionary) -> bool:
	if TB.dist_xy(p.x, p.y, d["x"], d["y"]) < 9.0 + p.r:
		return true
	if Coop.on():
		for h: Player in Coop.heroes():
			if not Coop.downs.has(h) and TB.dist_xy(h.x, h.y, d["x"], d["y"]) < 9.0 + h.r:
				return true
	return false

static func _dropit(e: Enemy, p: Player, dt: float) -> void:
	var me := _me(e)
	match e.sub:
		0:   # up to you
			var dv := Vector2(p.x - e.x, p.y - e.y)
			e.face = 1 if dv.x > 0 else -1
			if dv.length() > 46.0 and e.st < 1.4:
				var step := 210.0 * _fast(e) * dt
				e.x += dv.normalized().x * step
				e.y += dv.normalized().y * step
				return
			var at := RiftBosses._inside(Vector2(e.x, e.y) + dv * 0.5)   # at your feet
			me["drop"] = { "x": at.x, "y": at.y }
			e.sub = 1
			e.st = 0.0
			Barks.say(e, "THROW IT! THROW IT!", "gold", DROP_WAIT)
			Snd.play("hit")
		1:   # he stares at it, then at you
			e.z = absf(sin(e.st * 14.0)) * 2.0
			var d: Dictionary = me["drop"]
			if _stepped(p, d):
				var side := 1.0 if randf() < 0.5 else -1.0
				var a := TB.ang_xy(e.x, e.y, d["x"], d["y"]) + PI / 2 * side
				var s0 := Vector2(d["x"], d["y"])
				var ln := clampf(Afx.reach(s0.x, s0.y, a, 220.0, World.M_BULLET) - 12.0, 40.0, 220.0)
				var end := RiftBosses._inside(s0 + Vector2(cos(a), sin(a)) * ln)
				me["drop"] = {}
				me["discs"] = [{ "s": s0, "c": s0.lerp(end, 0.5) + Vector2(0, -30), "e": end, "k": 0.0, "mine": true }]
				e.from = Vector2(e.x, e.y)
				e.to = end + Vector2(0, 14)
				e.ca = TB.ang_xy(e.x, e.y, e.to.x, e.to.y)
				e.face = 1 if cos(e.ca) > 0 else -1
				e.z = 0.0
				e.sub = 2
				e.st = 0.0
				Fx.float_text(s0.x, s0.y - 16, "GOOD THROW!", "gold")
				Barks.say(e, "!!!", "gold", 0.8)
				Snd.play("bark")
			elif e.st >= DROP_WAIT / _fast(e):
				e.z = 0.0
				e.sub = 4
				e.st = 0.0
				e.repeat = 0
				Barks.say(e, "WOOF!! WOOF!!", "red", 1.0)
		2:   # after it, as happy as a dog can be
			var k := minf(1.0, e.st / 0.9)
			for disc in me["discs"]:
				disc["k"] = k
			e.x = lerpf(e.from.x, e.to.x, k)
			e.y = lerpf(e.from.y, e.to.y, k)
			e.z = sin((k - 0.7) / 0.3 * PI) * 18.0 if k > 0.7 else 0.0
			if k >= 1.0:
				e.z = 0.0
				me["discs"] = []
				e.sub = 3
				e.st = 0.0
				Fx.float_text(e.x, e.y - 40, "GOT IT!", "gold")
		3:   # a happy spin with it
			e.face = 1 if fmod(e.st * 8.0, 2.0) < 1.0 else -1
			e.z = absf(sin(e.st * 12.0)) * 6.0
			if e.st >= 1.0:
				e.z = 0.0
				RiftBosses._done(e, 0.4)
		4:   # not thrown: two angry barks (fans of shots at you), and he picks it up
			if e.st >= 0.35:
				e.st = 0.0
				var a := TB.ang_to(e, p)
				var n := 7 if e.phase == 2 else 5
				for j in n:
					Combat.eshot(e.x, e.y - 8, a + (j - (n - 1) * 0.5) * 0.18, 90.0 * _fast(e), "bone")
				Snd.play("bark")
				G.add_shake(2)
				e.repeat += 1
				if e.repeat >= 2:
					e.repeat = 0
					me["drop"] = {}
					RiftBosses._done(e, 0.6)

## FRENZY (second phase): four frisbees fanned out on curves (shown first); then he fetches every one,
## the nearest first, a lane shown before each dash.
static func _frenzy(e: Enemy, p: Player, dt: float) -> void:
	var me := _me(e)
	match e.sub:
		0:
			if e.st < 0.02:
				var a0 := TB.ang_to(e, p)
				var s0 := Vector2(e.x, e.y - 14)
				var discs := []
				for i in FRENZY_N:
					var a := a0 + (i - (FRENZY_N - 1) * 0.5) * 0.42
					var ln := clampf(Afx.reach(s0.x, s0.y, a, 170.0, World.M_BULLET) - 12.0, 50.0, 170.0)
					var end := RiftBosses._inside(s0 + Vector2(cos(a), sin(a)) * ln)
					var bend := Vector2(cos(a), sin(a)).orthogonal() * (40.0 if i % 2 == 0 else -40.0)
					discs.append({ "s": s0, "c": s0.lerp(end, 0.5) + bend, "e": end, "k": 0.0, "mine": true })
				me["discs"] = discs
				Barks.say(e, "FRISBEES!!!", "gold", 1.0)
			if e.st >= 0.6:
				e.sub = 1
				e.st = 0.0
				Snd.play("hatchet")
		1:
			var k := minf(1.0, e.st / 0.8)
			for d in me["discs"]:
				d["k"] = k
				var at := disc_at(d, k)
				if TB.dist_xy(at.x, at.y, p.x, p.y - 4) < 5.0 + p.r:
					Combat.hurt_player(1, e.d["name"])
				if Coop.on():   # (W4: the other heroes too)
					Coop.hazard(func(hero: Player) -> bool: return TB.dist_xy(at.x, at.y, hero.x, hero.y - 4) < 5.0 + hero.r, e.d["name"])
			if k >= 1.0:
				e.sub = 2
				e.st = 0.0
				_next_disc(e, me)
		2:   # the lane to the next one
			if e.st >= 0.3:
				e.sub = 3
				e.st = 0.0
				Snd.play("hatchet")
		3:   # he gets it
			var dd := minf(e.st * 380.0, e.aux2)
			e.x = e.from.x + cos(e.ca) * dd
			e.y = e.from.y + sin(e.ca) * dd
			if dd >= e.aux2:
				if not me["discs"].is_empty():
					me["discs"].pop_front()
				Fx.float_text(e.x, e.y - 34, "CHOMP", "white")
				if me["discs"].is_empty():
					RiftBosses._done(e, 0.6)
				else:
					e.sub = 2
					e.st = 0.0
					_next_disc(e, me)

## FRENZY: the nearest frisbee on the floor first; his lane to it.
static func _next_disc(e: Enemy, me: Dictionary) -> void:
	var discs: Array = me["discs"]
	discs.sort_custom(func(a, b): return TB.dist_xy(e.x, e.y, a["e"].x, a["e"].y) < TB.dist_xy(e.x, e.y, b["e"].x, b["e"].y))
	var t: Vector2 = discs[0]["e"] + Vector2(0, 14)
	e.from = Vector2(e.x, e.y)
	e.ca = TB.ang_xy(e.x, e.y, t.x, t.y)
	e.aux2 = TB.dist_xy(e.x, e.y, t.x, t.y)
	e.face = 1 if cos(e.ca) > 0 else -1

## BOUNCE: the path of a frisbee off the room's walls: points from `s0`, `n` bounces, at most `most`.
static func bounce_path(s0: Vector2, a: float, n: int, most: float) -> Array:
	var lo := Vector2(2.5 * TB.TS + 8.0, 3.5 * TB.TS + 8.0)
	var hi := Vector2(25.5 * TB.TS - 8.0, 16.0 * TB.TS - 8.0)
	var pts := [s0]
	var at := s0
	var d := Vector2(cos(a), sin(a))
	var left := most
	for i in n + 1:
		var tx: float = ((hi.x if d.x > 0 else lo.x) - at.x) / d.x if absf(d.x) > 0.001 else INF
		var ty: float = ((hi.y if d.y > 0 else lo.y) - at.y) / d.y if absf(d.y) > 0.001 else INF
		var t := minf(maxf(0.0, minf(tx, ty)), left)
		at += d * t
		pts.append(at)
		left -= t
		if left <= 0.0:
			break
		if tx < ty:
			d.x = -d.x
		else:
			d.y = -d.y
	return pts

## A point `dist` along a path of points (BOUNCE).
static func along(pts: Array, dist: float) -> Vector2:
	var left := dist
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var l := a.distance_to(b)
		if left <= l:
			return a.lerp(b, left / maxf(0.001, l))
		left -= l
	return pts.back()

static func path_len(pts: Array) -> float:
	var n := 0.0
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		n += a.distance_to(pts[i + 1])
	return n

## BOUNCE (second phase): he flicks a frisbee off the walls (its path shown first, three bounces) and
## runs right behind it all the way.
static func _bounce(e: Enemy, p: Player, dt: float) -> void:
	var me := _me(e)
	match e.sub:
		0:
			if e.st < 0.02:
				me["path"] = bounce_path(Vector2(e.x, e.y - 14), TB.ang_to(e, p), 3, 760.0)
				Barks.say(e, "BOING!", "gold", 0.8)
			if e.st >= 0.6:
				e.sub = 1
				e.st = 0.0
				Snd.play("hatchet")
		1:
			var pts: Array = me["path"]
			var total := path_len(pts)
			var dd := e.st * BOUNCE_SPEED * _fast(e)
			var at := along(pts, minf(dd, total))
			me["discs"] = [{ "s": at, "c": at, "e": at, "k": 1.0, "mine": true }] if dd < total else []
			if dd < total and TB.dist_xy(at.x, at.y, p.x, p.y - 4) < 5.0 + p.r:
				Combat.hurt_player(1, e.d["name"])
			if dd < total and Coop.on():   # (W4: the other heroes too)
				Coop.hazard(func(hero: Player) -> bool: return TB.dist_xy(at.x, at.y, hero.x, hero.y - 4) < 5.0 + hero.r, e.d["name"])
			var behind := along(pts, clampf(dd - 40.0, 0.0, total)) + Vector2(0, 14)
			e.face = 1 if behind.x > e.x else -1
			_run_to(e, behind, 600.0 * dt)
			if dd - 40.0 >= total:
				me["discs"] = []
				me["path"] = []
				Fx.float_text(e.x, e.y - 40, "CAUGHT IT!", "gold")
				RiftBosses._done(e, 0.6)

## Whether his frisbee is in his mouth now (not thrown, not dropped, not traded for the stick).
static func holding(e: Enemy) -> bool:
	match e.state:
		&"frisbee", &"bounce":
			return e.sub == 0
		&"frenzy", &"stick", &"crash":
			return false
		&"dropit":
			return e.sub == 0 or e.sub == 3
	return true

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
	if holding(e):
		var run := sprite(e).begins_with("arci_run")
		Gfx.sp(ci, "arci_frisbee", e.x + (29.0 if run else 24.0) * e.face, foot - (24.0 if run else 31.0), 1.4, 1.4)
	elif e.state == &"crash":
		Gfx.sp(ci, "arci_frisbee", e.x - 30.0 * e.face, foot + 2.0, 1.6, 1.6)   # beside him
	var drop: Dictionary = me.get("drop", {})
	if not drop.is_empty():
		Gfx.sp(ci, "arci_frisbee", drop["x"], drop["y"] + 3, 2.0, 2.0)
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
		&"dropit":
			var drop: Dictionary = me.get("drop", {})
			if e.sub == 1 and not drop.is_empty():
				Afx.circle(ci, drop["x"], drop["y"] + 2, 12.0 + 3.0 * sin(t * 8.0), TB.c("#f2c94c"), t, 0.9)   # step here
		&"frenzy":
			if e.sub == 0:
				var k := clampf(e.st / 0.6, 0.0, 1.0)
				for d in me["discs"]:
					for i in 16:
						if i % 2 == 1:
							continue
						ci.draw_line(disc_at(d, i / 16.0) + Vector2(0, 12), disc_at(d, (i + 1) / 16.0) + Vector2(0, 12),
							Color(warn.r, warn.g, warn.b, 0.4 + 0.5 * k), 2.0)
			elif e.sub == 2:
				Afx.lane(ci, e.from.x, e.from.y, e.ca, 9.0, e.aux2, e.st / 0.3, warn, t)
		&"bounce":
			if e.sub == 0:
				var pts: Array = me.get("path", [])
				var k := clampf(e.st / 0.6, 0.0, 1.0)
				for i in pts.size() - 1:
					var a: Vector2 = pts[i]
					var b: Vector2 = pts[i + 1]
					var n := maxi(2, int(a.distance_to(b) / 8.0))
					for j in n:
						if j % 2 == 0:
							ci.draw_line(a.lerp(b, float(j) / n) + Vector2(0, 12), a.lerp(b, float(j + 1) / n) + Vector2(0, 12),
								Color(warn.r, warn.g, warn.b, 0.4 + 0.5 * k), 2.0)
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
	Gfx.sp(ci, "arci_frisbee", o["x"] - 40, o["y"] + 14, 1.6, 1.6)   # his frisbee beside him
	Gfx.sp(ci, "arci_lie" + ("_s%d" % lk if lk > 1 else ""), o["x"], o["y"] + 12, 2.0, 2.0)
	var k := fmod(t * 0.6, 1.0)
	Gfx.text(ci, "Z", o["x"] + 20 + k * 8, o["y"] - 20 - k * 14, "white", 1, 0.5, true, 1.0 - k)
	if fmod(t, 2.0) < 1.0:
		Gfx.text(ci, "<3", o["x"] - 18, o["y"] - 26 - fmod(t, 1.0) * 6.0, "pink", 1, 0.5, true, 1.0 - fmod(t, 1.0))
