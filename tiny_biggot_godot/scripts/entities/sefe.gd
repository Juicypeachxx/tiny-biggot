class_name Sefe
extends RefCounted
## ŠEFE, KING OF THE BLOK: the third floor's guardian in the expanded game (his word, 13 Oct, with
## five photos: "slovenian gopnik who acts like gangster and mogg peaople he also smoke alot of
## marijuana and drinks alot of beer"; the name and "Floor 3, always" his picks). --classic keeps THE
## DROWNED LIBRARIAN on the third floor (it is now one of the fourth floor's guardians in the
## expanded game). Our own cartoon of the type (tools/art/stage59_sefe.py): no brand from the photos.
##
## First phase: FINGER GUNS (a pose, then volleys of shots from both hands: PEW PEW), MOG (a cone
## shown first: inside it when he stares and you are MOGGED, slow; and a volley after you), SMOKE
## BREAK (the gopnik squat and a joint: clouds drift at you and slow you; hit him six times and he
## coughs, stunned), BEER (PSSHT, he chugs: NA ZDRAVJE!, throws the can where you stand, shown
## first: it bursts into foam that slows you; then a belch, a ring of shots) and ZONED OUT (sitting
## on the floor staring at nothing: he takes half again as much and does not hit back).
## Second phase, at half health: the crown and the chain go on (the king of the blok): THE BIG ONE
## (the giant cone: a beam of smoke that sweeps an arc shown first, leaving clouds), CHAINSAW (revs,
## and charges down lanes shown first) and AXE (thrown down a lane, it sticks in the floor).
## Beaten, he is not slain: he passes out where he stands, snoring (on_beaten).
## The fight runs in RiftBosses (phases, the grace between them, the stage at a quarter); this file
## holds his moves, his clouds and foam, and his drawing.

const SMOKE_SLOW := 0.6        # your speed in his smoke or his foam
const CLOUD_R := 18.0
const FOAM_R := 22.0
const COUGH_HITS := 6          # hits during his smoke break that make him cough
const MOG_R := 110.0           # the stare's cone: its reach and half its width
const MOG_HALF := 0.5
const BEAM_LEN := 220.0
const SAW_SPEED := 320.0
const NAME_SHORT := "ŠEFE"
const TOP_Y := 6.5 * TB.TS     # he is tall: no higher than this, or his head goes under the top bar

static var clouds: Array = []   # smoke: { x, y, vx, vy, life, max }
static var foam: Array = []     # beer foam on the floor: { x, y, life }
static var _room: WeakRef = null

static func is_sefe(e: Enemy) -> bool:
	return e != null and e.boss == "sefe"

static func _me(e: Enemy) -> Dictionary:
	if e.parts.is_empty() or e.parts[0].get("kind", "") != "sefe":
		e.parts = [{ "kind": "sefe", "hits": 0, "can": {}, "axes": [], "out": false }]
	return e.parts[0]

static func _fast(e: Enemy) -> float:
	return 1.15 if e.phase == 2 else 1.0

static func clear() -> void:
	clouds.clear()
	foam.clear()

## Hazards.update: his clouds drift and fade, his foam dries.
static func tick(dt: float) -> void:
	if _room == null or _room.get_ref() != G.room:
		clear()
		_room = weakref(G.room)
	if clouds.is_empty() and foam.is_empty():
		return
	var keep := []
	for c in clouds:
		c["life"] -= dt
		c["x"] += c["vx"] * dt
		c["y"] += c["vy"] * dt
		c["vx"] *= 0.985
		c["vy"] *= 0.985
		if c["life"] > 0.0:
			keep.append(c)
	clouds = keep
	keep = []
	for f in foam:
		f["life"] -= dt
		if f["life"] > 0.0:
			keep.append(f)
	foam = keep

## Player.update_move: in his smoke or his foam you are slower.
static func speed_mult(p: Player) -> float:
	if clouds.is_empty() and foam.is_empty():
		return 1.0
	for c in clouds:
		if TB.dist_xy(p.x, p.y, c["x"], c["y"]) < CLOUD_R:
			return SMOKE_SLOW
	for f in foam:
		if TB.dist_xy(p.x, p.y, f["x"], f["y"]) < FOAM_R:
			return SMOKE_SLOW
	return 1.0

static func _cloud(x: float, y: float, a: float, v: float, life: float = 4.0) -> void:
	if clouds.size() < 24:
		clouds.append({ "x": x, "y": y, "vx": cos(a) * v, "vy": sin(a) * v, "life": life, "max": life })

# ---------- The fight (from RiftBosses.update) ----------
## The grace between the phases: the crown and the chain go on.
static func to_king(e: Enemy, dt: float) -> void:
	e.z = 0.0
	if e.sub == 0 and e.st >= 0.5:
		e.sub = 1
		Fx.burst(e.x, e.y - 40, ["#f2c94c", "#fff3b0", "#ffffff"], 16, 80)
		Fx.float_text(e.x, e.y - 70, "KING OF THE BLOK", "gold", true)
		Snd.play("shield")
	if e.st >= RiftBosses.PHASE_T - 0.05:
		e.speed = 46.0

static func rest_move(e: Enemy, p: Player, dt: float) -> void:
	EnemyAI.wander_keep(e, dt, p, 70, 150)
	e.face = 1 if p.x > e.x else -1
	_keep(e)

## Inside the room, and his head below the top bar (TOP_Y).
static func _inside(v: Vector2) -> Vector2:
	var c := RiftBosses._inside(v)
	return Vector2(c.x, maxf(c.y, TOP_Y))

static func _keep(e: Enemy) -> void:
	var c := _inside(Vector2(e.x, e.y))
	e.x = c.x
	e.y = c.y

## Damage (RiftBosses.adjust_damage): zoned out or coughing, half again as much. During his smoke
## break the blows are counted: enough of them and he coughs.
static func adjust_damage(e: Enemy, dmg: float) -> float:
	if (e.state == &"zoned" and e.sub == 1) or (e.state == &"smoke" and e.sub == 2):
		return dmg * 1.5
	if e.state == &"smoke" and e.sub == 1 and dmg > 0.0:
		_me(e)["hits"] += 1
	return dmg

## Combat.update_enemies: no hits from him while he sits zoned out or coughs.
static func harmless(e: Enemy) -> bool:
	return (e.state == &"zoned" and e.sub >= 1) or (e.state == &"smoke" and e.sub == 2)

static func attack(e: Enemy, p: Player, dt: float) -> void:
	match e.state:
		&"fingerguns": _fingerguns(e, p, dt, 4 if e.phase == 2 else 3)
		&"mog": _mog(e, p, dt)
		&"smoke": _smoke(e, p, dt)
		&"beer": _beer(e, p, dt)
		&"zoned": _zoned(e, p, dt)
		&"bigone": _bigone(e, p, dt)
		&"chainsaw": _chainsaw(e, p, dt, 3)
		&"axe": _axe(e, p, dt, 2 if e.phase == 2 else 1)
	_keep(e)

## His two hands (the finger guns), from where he stands.
static func hands(e: Enemy) -> Array:
	return [Vector2(e.x - 12.0 * e.face, e.y - 58.0), Vector2(e.x + 26.0 * e.face, e.y - 46.0)]

## FINGER GUNS: a pose (PEW PEW), then volleys from both hands at you.
static func _fingerguns(e: Enemy, p: Player, dt: float, volleys: int) -> void:
	match e.sub:
		0:
			if e.st < 0.02:
				e.face = 1 if p.x > e.x else -1
				Barks.say(e, "PEW PEW", "white", 0.8)
			if e.st >= 0.5 / _fast(e):
				e.sub = 1
				e.st = 0.0
				e.repeat = 0
		1:
			if e.st >= 0.25:
				e.st = 0.0
				for h in hands(e):
					var a := TB.ang_xy(h.x, h.y, p.x, p.y - 4)
					Combat.eshot(h.x, h.y, a + randf_range(-0.12, 0.12), 110.0 * _fast(e), "red")
				Snd.play("bolt")
				e.repeat += 1
				if e.repeat >= volleys:
					e.repeat = 0
					RiftBosses._done(e, 0.6)

## MOG: a cone at you, shown first; inside it when he stares and you are MOGGED (slow), and a volley
## of finger guns follows you.
static func _mog(e: Enemy, p: Player, dt: float) -> void:
	match e.sub:
		0:
			if e.st < 0.02:
				e.ca = TB.ang_to(e, p)
				e.face = 1 if cos(e.ca) > 0 else -1
				Barks.say(e, "KAJ GLEDAŠ?!", "red", 1.0)
			if e.st >= 0.8 / _fast(e):
				e.sub = 1
				e.st = 0.0
				var d := TB.dist(e, p)
				var off := absf(TB.wrap_ang(TB.ang_to(e, p) - e.ca))
				if d < MOG_R and off < MOG_HALF and p.dodge_t <= 0.0:
					Finale.mog_t = Finale.MOG_T * 1.5
					Finale.mog_cd = Finale.MOG_CD
					Fx.float_text(p.x, p.y - 26, "MOGGED!", "pink", true)
					Snd.play("shield")
		1:
			if e.st >= 0.35:
				for h in hands(e):
					Combat.eshot(h.x, h.y, TB.ang_xy(h.x, h.y, p.x, p.y - 4), 120.0 * _fast(e), "red")
				Snd.play("bolt")
				RiftBosses._done(e, 0.6)

## SMOKE BREAK: the squat and a joint; a cloud every puff drifts at you (it slows you). Six blows
## while he smokes and he coughs: stunned, half again as much.
static func _smoke(e: Enemy, p: Player, dt: float) -> void:
	var me := _me(e)
	match e.sub:
		0:
			if e.st < 0.02:
				me["hits"] = 0
				Barks.say(e, "PAVZA.", "white", 0.8)   # a break
			if e.st >= 0.4:
				e.sub = 1
				e.st = 0.0
				e.aux2 = 0.0
		1:
			e.aux2 -= dt
			if e.aux2 <= 0.0:
				e.aux2 = 0.6 / _fast(e)
				var mouth := Vector2(e.x + 4.0 * e.face, e.y - 34.0)
				_cloud(mouth.x, mouth.y + 24.0, TB.ang_xy(mouth.x, mouth.y, p.x, p.y) + randf_range(-0.4, 0.4), 38.0 * _fast(e))
			if me["hits"] >= COUGH_HITS:
				e.sub = 2
				e.st = 0.0
				Barks.say(e, "KHH! KHH!", "white", 1.4)
				Fx.float_text(e.x, e.y - 60, "COUGH!", "white", true)
				Snd.play("hit")
			elif e.st >= (3.0 if e.phase == 2 else 3.5):
				RiftBosses._done(e, 0.5)
		2:   # coughing: stunned
			if e.st >= 1.5:
				RiftBosses._done(e, 0.4)

## BEER: PSSHT, he chugs (NA ZDRAVJE!), throws the can where you stand (a ring shows where it lands):
## it bursts into foam that slows you. Then a belch: a ring of shots.
static func _beer(e: Enemy, p: Player, dt: float) -> void:
	var me := _me(e)
	match e.sub:
		0:
			if e.st < 0.02:
				Fx.float_text(e.x + 10 * e.face, e.y - 60, "PSSHT", "white")
				Snd.play("spawn")
			if e.st >= 0.3:
				e.sub = 1
				e.st = 0.0
				Barks.say(e, "NA ZDRAVJE!", "gold", 1.0)
		1:   # he chugs it
			if e.st >= 1.0 / _fast(e):
				e.sub = 2
				e.st = 0.0
				var to := RiftBosses._inside(Vector2(p.x, p.y))
				me["can"] = { "x0": e.x + 10.0 * e.face, "y0": e.y - 30.0, "x1": to.x, "y1": to.y, "k": 0.0 }
				Snd.play("hatchet")
		2:   # the can in the air
			var c: Dictionary = me["can"]
			c["k"] = minf(1.0, e.st / 0.7)
			if c["k"] >= 1.0:
				foam.append({ "x": c["x1"], "y": c["y1"], "life": 5.0 })
				if TB.dist_xy(p.x, p.y, c["x1"], c["y1"]) < 12.0 + p.r:
					Combat.hurt_player(1, e.d["name"])
				Combat.ering(c["x1"], c["y1"], 6, 60.0, randf() * TAU, "red")
				Fx.burst(c["x1"], c["y1"], ["#fff3d0", "#f2c94c", "#ffffff"], 14, 70)
				Snd.play("hit")
				me["can"] = {}
				e.sub = 3
				e.st = 0.0
		3:   # and a belch
			if e.st >= 0.45:
				Combat.ering(e.x, e.y - 20, 16 if e.phase == 2 else 12, 80.0 * _fast(e), randf() * TAU, "red")
				Fx.float_text(e.x, e.y - 64, "BURP", "lime", true)
				G.add_shake(3)
				Snd.play("boom")
				RiftBosses._done(e, 0.6)

## ZONED OUT: sitting on the floor, staring at nothing (he takes half again as much and does not
## hit back), then he snaps out of it.
static func _zoned(e: Enemy, p: Player, dt: float) -> void:
	e.z = 0.0
	match e.sub:
		0:
			if e.st >= 0.3:
				e.sub = 1
				e.st = 0.0
				Barks.say(e, "...", "white", 2.0)
		1:
			if e.st >= (2.3 if e.phase == 2 else 3.0):
				e.sub = 2
				e.st = 0.0
				Fx.float_text(e.x, e.y - 56, "KAJ?!", "gold", true)
		2:
			if e.st >= 0.3:
				RiftBosses._done(e, 0.3)

## The smoke beam of THE BIG ONE now: from his mouth along its angle.
static func beam_ends(e: Enemy) -> Array:
	var mouth := Vector2(e.x + 6.0 * e.face, e.y - 34.0)
	return [mouth, mouth + Vector2(cos(e.angle), sin(e.angle)) * BEAM_LEN]

## THE BIG ONE (second phase): the giant cone, lit; a beam of smoke sweeps an arc shown first and
## leaves clouds behind.
static func _bigone(e: Enemy, p: Player, dt: float) -> void:
	match e.sub:
		0:
			if e.st < 0.02:
				var a := TB.ang_xy(e.x, e.y - 34.0, p.x, p.y)
				e.aux = 1.0 if randf() < 0.5 else -1.0
				e.angle = a - e.aux * 0.8
				e.ca = a + e.aux * 0.8   # where the sweep ends
				e.face = 1 if cos(a) > 0 else -1
				Barks.say(e, "THE BIG ONE.", "lime", 1.2)
				Snd.play("charge")
			if e.st >= 0.9:
				e.sub = 1
				e.st = 0.0
				e.aux2 = 0.0
		1:
			var span := 1.6
			var k := minf(1.0, e.st / span)
			e.angle = lerp_angle(e.ca - e.aux * 1.6, e.ca, k)
			var ends := beam_ends(e)
			if RiftBosses._near_seg(p.x, p.y, ends[0], ends[1], 7.0 + p.r * 0.5):
				Combat.hurt_player(1, e.d["name"])
			e.aux2 -= dt
			if e.aux2 <= 0.0:
				e.aux2 = 0.4
				var e1: Vector2 = ends[1]
				_cloud(e1.x, e1.y, randf() * TAU, 10.0, 3.0)
			if k >= 1.0:
				RiftBosses._done(e, 0.7)

## CHAINSAW (second phase): BRRRM, a lane at you, and he charges down it; three times.
static func _chainsaw(e: Enemy, p: Player, dt: float, charges: int) -> void:
	match e.sub:
		0:
			if e.st < 0.02:
				e.ca = TB.ang_to(e, p)
				e.aux2 = maxf(16.0, Afx.reach(e.x, e.y, e.ca, TB.dist(e, p) + 60.0, World.M_WALKER) - 10.0)
				if sin(e.ca) < -0.05:   # (the lane shown ends where he must stop: TOP_Y)
					e.aux2 = clampf((e.y - TOP_Y) / -sin(e.ca), 16.0, e.aux2)
				e.from = Vector2(e.x, e.y)
				e.face = 1 if cos(e.ca) > 0 else -1
				if e.repeat == 0:
					Barks.say(e, "BRRRRM!", "orange", 1.0)
			if e.st >= 0.55:
				e.sub = 1
				e.st = 0.0
				Snd.play("charge")
		1:
			var d := minf(e.st * SAW_SPEED, e.aux2)
			e.x = e.from.x + cos(e.ca) * d
			e.y = e.from.y + sin(e.ca) * d
			var tip := Vector2(e.x + cos(e.ca) * 30.0, e.y - 20.0 + sin(e.ca) * 30.0)
			if RiftBosses._near_seg(p.x, p.y, Vector2(e.x, e.y - 20.0), tip, 6.0 + p.r * 0.5):
				Combat.hurt_player(1, e.d["name"])
			if d >= e.aux2:
				Afx.dust(e.x, e.y + 8)
				e.repeat += 1
				if e.repeat >= charges:
					e.repeat = 0
					RiftBosses._done(e, 0.6)
				else:
					e.sub = 0
					e.st = 0.0

## AXE (second phase): a lane at you (two in a V in the second phase), the axe flies down it spinning
## and sticks in the floor at its end.
static func _axe(e: Enemy, p: Player, dt: float, n: int) -> void:
	var me := _me(e)
	match e.sub:
		0:
			if e.st < 0.02:
				var a0 := TB.ang_to(e, p)
				var axes := []
				for i in n:
					var a := a0 + (0.0 if n == 1 else (i - 0.5) * 0.5)
					var ln := maxf(30.0, Afx.reach(e.x, e.y - 24.0, a, 260.0, World.M_BULLET) - 8.0)
					axes.append({ "a": a, "len": ln, "d": 0.0, "stuck": false, "life": 4.0 })
				me["axes"] = axes
				e.face = 1 if cos(a0) > 0 else -1
			if e.st >= 0.5:
				e.sub = 1
				e.st = 0.0
				Snd.play("hatchet")
		1:
			var flying := false
			for ax in me["axes"]:
				if ax["stuck"]:
					continue
				ax["d"] = minf(ax["len"], ax["d"] + 260.0 * dt)
				var at: Vector2 = Vector2(e.x, e.y - 24.0) + Vector2(cos(ax["a"]), sin(ax["a"])) * float(ax["d"])
				ax["x"] = at.x
				ax["y"] = at.y
				if TB.dist_xy(at.x, at.y, p.x, p.y - 4) < 7.0 + p.r:
					Combat.hurt_player(1, e.d["name"])
				if ax["d"] >= ax["len"]:
					ax["stuck"] = true
					Afx.dust(at.x, at.y + 6)
				else:
					flying = true
			if not flying:
				RiftBosses._done(e, 0.5)

## Beaten (Game.on_boss_dead): he passes out where he stands, snoring.
static func on_beaten(b: Enemy) -> void:
	clear()
	if G.banner.is_empty() or G.banner.get("t", 0.0) < 2.0:
		G.show_banner(NAME_SHORT + " PASSED OUT", "THE BLOK IS YOURS NOW")
	else:
		G.toast(NAME_SHORT + " PASSED OUT", "gold")
	Snd.play("hit")
	G.room.objects.append({ "kind": "sefe_rest", "x": b.x, "y": b.y, "look": look(b) })

# ---------- Drawing ----------
## His look (Stages.look): 2 the crown and the chain (from the moment they go on), 3 and a haze.
static func look(e: Enemy) -> int:
	return maxi(Stages.look(e), 2 if e.state == &"phase" and e.sub == 1 else 1)

## world_view._enemy_sprite: the squat at rest and on his smoke break, the can up while he chugs,
## sitting zoned out (and coughing), standing for the rest.
static func sprite(e: Enemy) -> String:
	var s := "sefe"
	if e.state == &"rest" or e.state == &"idle" or (e.state == &"smoke" and e.sub <= 1):
		s = "sefe_squat"
	elif e.state == &"beer" and e.sub == 1:
		s = "sefe_drink"
	elif (e.state == &"zoned" and e.sub >= 1) or (e.state == &"smoke" and e.sub == 2):
		s = "sefe_zoned"
	var lk := look(e)
	return s + ("_s%d" % lk if lk > 1 else "")

## With his body (RiftBosses.draw_parts): his clouds, the can in the air, the cone and its beam, the
## chainsaw, his axes.
static func draw_parts(ci: CanvasItem, e: Enemy, foot: float, t: float) -> void:
	var me := _me(e)
	for c in clouds:
		var k: float = clampf(c["life"] / c["max"], 0.0, 1.0)
		Gfx.sp(ci, "sefe_smoke", c["x"], c["y"] + 10, 2.6, 2.6, 0.0, false, 0.35 + 0.5 * k)
	var can: Dictionary = me.get("can", {})
	if not can.is_empty():
		var k: float = can["k"]
		var at := Vector2(lerpf(can["x0"], can["x1"], k), lerpf(can["y0"], can["y1"], k) - sin(k * PI) * 40.0)
		Gfx.sprite(ci, "sefe_can", at.x, at.y, 3, 5, 2.0, 2.0, t * 14.0, false)
	if e.state == &"bigone":
		var ends := beam_ends(e)
		var e0: Vector2 = ends[0]
		Gfx.sprite(ci, "sefe_cone", e0.x, e0.y, 2, 5, 1.6, 1.6, e.angle, false)
		if e.sub == 1:
			var e1: Vector2 = ends[1]
			var n := 9
			for i in n:
				var q := e0.lerp(e1, (i + 0.5) / n)
				Gfx.sp(ci, "sefe_smoke", q.x, q.y + 8, 1.4 + 0.25 * i, 1.4 + 0.25 * i, 0.0, false, 0.75)
	if e.state == &"chainsaw":
		var a := e.ca
		Gfx.sprite(ci, "sefe_chainsaw", e.x + cos(a) * 14.0, foot - 30.0 + sin(a) * 14.0, 6, 5, 2.0, 2.0, a, false)
	for ax in me.get("axes", []):
		if ax.has("x"):
			var spin: float = 0.4 if ax["stuck"] else t * 18.0
			Gfx.sprite(ci, "sefe_axe", ax["x"], ax["y"], 7, 7, 2.0, 2.0, spin, false)
	if e.state == &"smoke" and e.sub == 1:
		Gfx.px(ci, TB.c("#ff7a2a" if floori(t * 6.0) % 2 == 0 else "#ffd060"), e.x + 10.0 * e.face, foot - 30.0, 2)

## On the floor with the other warnings (RiftBosses.draw_ground): his foam, the stare's cone, where
## the can will land, the sweep of THE BIG ONE, the chainsaw's lanes, the axes' lanes.
static func draw_ground(ci: CanvasItem, e: Enemy, t: float) -> void:
	var warn := Afx.C_WARN
	var me := _me(e)
	for f in foam:
		var k: float = clampf(f["life"] / 5.0, 0.0, 1.0)
		ci.draw_circle(Vector2(f["x"], f["y"]), FOAM_R, Color(1.0, 0.95, 0.75, 0.35 * k))
		ci.draw_circle(Vector2(f["x"] - 6, f["y"] - 3), FOAM_R * 0.4, Color(1, 1, 1, 0.4 * k))
	match e.state:
		&"mog":
			if e.sub == 0:
				var k := clampf(e.st / (0.8 / _fast(e)), 0.0, 1.0)
				var pts := PackedVector2Array([Vector2(e.x, e.y)])
				for i in 9:
					var a := e.ca - MOG_HALF + MOG_HALF * 2.0 * i / 8.0
					pts.append(Vector2(e.x, e.y) + Vector2(cos(a), sin(a)) * MOG_R)
				ci.draw_colored_polygon(pts, Color(1.0, 0.45, 0.75, 0.12 + 0.25 * k))
				ci.draw_polyline(pts + PackedVector2Array([Vector2(e.x, e.y)]), Color(1.0, 0.45, 0.75, 0.5 + 0.4 * k), 1.0)
		&"beer":
			var can: Dictionary = me.get("can", {})
			if e.sub == 2 and not can.is_empty():
				Afx.landing(ci, can["x1"], can["y1"] + 4, 16.0, can["k"], warn, t)
		&"bigone":
			if e.sub == 0:
				var k := clampf(e.st / 0.9, 0.0, 1.0)
				var mouth := Vector2(e.x + 6.0 * e.face, e.y)
				var pts := PackedVector2Array([mouth])
				for i in 13:
					var a := lerp_angle(e.angle, e.ca, i / 12.0)
					pts.append(mouth + Vector2(cos(a), sin(a)) * BEAM_LEN)
				ci.draw_colored_polygon(pts, Color(warn.r, warn.g, warn.b, 0.08 + 0.2 * k))
		&"chainsaw":
			if e.sub == 0:
				Afx.lane(ci, e.from.x, e.from.y, e.ca, 10.0, e.aux2, e.st / 0.55, warn, t)
		&"axe":
			if e.sub == 0:
				for ax in me.get("axes", []):
					Afx.lane(ci, e.x, e.y, ax["a"], 6.0, ax["len"], e.st / 0.5, warn, t)

## Beaten: passed out where he fell, snoring (Game.on_boss_dead put him there; world_view draws him).
static func draw_rest(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var lk: int = o.get("look", 1)
	Gfx.sp(ci, "sefe_out" + ("_s%d" % lk if lk > 1 else ""), o["x"], o["y"] + 12, 2.0, 2.0)
	Gfx.sp(ci, "sefe_can", o["x"] + 46, o["y"] + 12, 2.0, 2.0, 1.4)   # rolled away
	var k := fmod(t * 0.6, 1.0)
	Gfx.text(ci, "Z", o["x"] - 30 + k * 6, o["y"] - 14 - k * 14, "white", 1, 0.5, true, 1.0 - k)
