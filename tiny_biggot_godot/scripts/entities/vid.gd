class_name Vid
extends RefCounted
## VID, THE HURIKAN SLAVE: the second floor's guardian in the expanded game, branch tiny-biggot-V2
## only (his word, 23 Oct, with five photos: "Vid the hurikan slave"; "he works in video engineering
## building LED walls and connecting cables, also he is drinking a lot of beer and work a lot he is
## always tired and loves One Piece manga"; "floor 2"; "for stage 2 and 3 he transforms in his metal
## form because he is metal head who watches a lot of anime"). --classic keeps THE SPORE MOTHER on
## the second floor. Our own cartoon of him (resprite/tools/vid_sheets.py): no brand, and the manga
## is only a manga (no character from any).
##
## First phase: PEACE (the peace sign, then volleys in a V), LED WALL (panels put up round you, shown
## first: they light up half at a time and a lit panel burns), CABLES (lanes across the room, shown
## first: the cables go live and spark), BEER (ŠE ENO PIVO!: he drinks and throws the bottle where you
## stand, shown first: it smashes into glass), POWER NAP (asleep on his flight case: half again as
## much and he does not hit back, but his snores drift at you) and ONE MORE CHAPTER (he reads; pages
## fly out round him).
## Second phase, at half health: he transforms, METAL FORM (long hair, studs, the horns; his look 2),
## 15% faster: HURIKAN (he spins after you, a spiral of shots flying off him), LASSO (a live cable
## swung round him, its reach shown first), WALL OF DEATH (two walls of shots run at each other from
## the sides, each with a gap shown first) and STAGE DIVE (he leaps where you stood, shown first: a
## ring of shock where he lands; three bottles where he threw one). At a quarter: FULL METAL (look 3,
## chrome and a storm; a second wall of death, a third arm to the spin).
## Beaten, he is not slain: he clocks out, asleep in his cables where he fell (on_beaten).
## The fight runs in RiftBosses (phases, the grace between them, the stage at a quarter); this file
## holds his moves and his drawing.

const NAME_SHORT := "VID"
const TOP_Y := 6.5 * TB.TS     # he is tall (as Sefe): no higher than this, or his head goes under the top bar
const PANEL := 24.0            # an LED panel's side
const LED_COLS := 6
const LED_ROWS := 4
const LED_WARN := 0.75
const LED_LIT := 0.5
const CABLE_WARN := 0.85
const CABLE_LIVE := 1.5
const LASSO_R := 96.0
const DIVE_T := 0.9
const WALL_GAP := 17.0         # half the gap in a wall of death
## The room's floor (RiftBosses._inside).
const X0 := 2.5 * TB.TS
const X1 := 25.5 * TB.TS
const Y0 := 3.5 * TB.TS
const Y1 := 16.0 * TB.TS

static func is_vid(e: Enemy) -> bool:
	return e != null and e.boss == "vid"

static func _me(e: Enemy) -> Dictionary:
	if e.parts.is_empty() or e.parts[0].get("kind", "") != "vid":
		e.parts = [{ "kind": "vid", "wall": {}, "cables": [], "bottles": [], "out": false }]
	return e.parts[0]

static func _fast(e: Enemy) -> float:
	return 1.15 if e.phase == 2 else 1.0

## His shots: an LED's cyan, purple in his metal form, ice white in full metal.
static func _col(e: Enemy) -> String:
	return ["cyan", "dark", "ice"][look(e) - 1]

# ---------- The fight (from RiftBosses.update) ----------
## The grace between the phases: he transforms.
static func to_metal(e: Enemy, dt: float) -> void:
	e.z = 0.0
	if e.sub == 0:   # a move cut short: its wall, cables and bottles go
		var me := _me(e)
		me["wall"] = {}
		me["cables"] = []
		me["bottles"] = []
	if e.sub == 0 and e.st >= 0.5:
		e.sub = 1
		Fx.burst(e.x, e.y - 40, ["#a35bd6", "#141018", "#ffffff"], 18, 90)
		Fx.float_text(e.x, e.y - 70, "METAL FORM!", "purple", true)
		G.add_shake(4)
		Snd.play("shield")
	if e.st >= RiftBosses.PHASE_T - 0.05:
		e.speed = 46.0

## Always tired: he drifts about and keeps you in sight.
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

## Damage (RiftBosses.adjust_damage): asleep on his flight case, half again as much.
static func adjust_damage(e: Enemy, dmg: float) -> float:
	if e.state == &"nap" and e.sub == 1:
		return dmg * 1.5
	return dmg

## Combat.update_enemies: no hits from him while he naps, nor in the air on a stage dive.
static func harmless(e: Enemy) -> bool:
	return (e.state == &"nap" and e.sub >= 1) or (e.state == &"dive" and e.sub == 1)

static func attack(e: Enemy, p: Player, dt: float) -> void:
	match e.state:
		&"peace": _peace(e, p, dt, 4 if e.phase == 2 else 3)
		&"ledwall": _ledwall(e, p, dt)
		&"cables": _cables(e, p, dt)
		&"beer": _beer(e, p, dt)
		&"nap": _nap(e, p, dt)
		&"manga": _manga(e, p, dt)
		&"hurikan": _hurikan(e, p, dt)
		&"lasso": _lasso(e, p, dt)
		&"walldeath": _walldeath(e, p, dt)
		&"dive": _dive(e, p, dt)
	if e.state != &"dive":
		_keep(e)

## The hand he holds up (the peace sign, the horns), from where he stands.
static func hand(e: Enemy) -> Vector2:
	return Vector2(e.x + 16.0 * e.face, e.y - 44.0)

## PEACE: the peace sign (the horns in his metal form), then volleys at you, each five shots flying
## as a V: its tip at you, its arms behind it.
static func _peace(e: Enemy, p: Player, dt: float, volleys: int) -> void:
	match e.sub:
		0:
			if e.st < 0.02:
				e.face = 1 if p.x > e.x else -1
				Barks.say(e, "PEACE!" if look(e) == 1 else "HORNS UP!", "white", 0.8)
			if e.st >= 0.5 / _fast(e):
				e.sub = 1
				e.st = 0.0
				e.repeat = 0
		1:
			if e.st >= 0.28:
				e.st = 0.0
				var h := hand(e)
				var a := TB.ang_xy(h.x, h.y, p.x, p.y - 4)
				var d := Vector2(cos(a), sin(a))
				var n := Vector2(-d.y, d.x)
				for i in 3:
					for side in ([0.0] if i == 0 else [-1.0, 1.0]):
						var q: Vector2 = h - d * (9.0 * i) + n * (9.0 * i * side)
						Combat.eshot(q.x, q.y, a, 110.0 * _fast(e), _col(e))
				Snd.play("bolt")
				e.repeat += 1
				if e.repeat >= volleys:
					e.repeat = 0
					RiftBosses._done(e, 0.6)

## LED WALL: a wall of panels laid round you (6 x 4), then half of them light up at a time (a
## checkerboard, the other half, rows, columns), each blinking first; a lit panel burns. Three in the
## first phase, four in the second.
static func _ledwall(e: Enemy, p: Player, dt: float) -> void:
	var me := _me(e)
	match e.sub:
		0:
			if e.st < 0.02:
				var w := PANEL * LED_COLS
				var h := PANEL * LED_ROWS
				me["wall"] = { "x0": clampf(p.x - w / 2.0, X0, X1 - w), "y0": clampf(p.y - h / 2.0, Y0, Y1 - h), "pat": 0,
					"n": 4 if e.phase == 2 else 3, "show": 0.0 }
				e.face = 1 if p.x > e.x else -1
				Barks.say(e, "LED WALL UP!", "cyan", 1.0)
				Snd.play("spawn")
			me["wall"]["show"] = minf(1.0, e.st / 0.6)
			if e.st >= 0.6:
				e.sub = 1
				e.st = 0.0
		1:   # the next panels blink
			if e.st >= LED_WARN / _fast(e):
				e.sub = 2
				e.st = 0.0
				Snd.play("bolt")
		2:   # lit
			var c := panel_at(me["wall"], p.x, p.y)
			if c.x >= 0 and lit(me["wall"], c.x, c.y):
				Combat.hurt_player(1, e.d["name"])
			if e.st >= LED_LIT:
				me["wall"]["pat"] += 1
				e.st = 0.0
				e.sub = 1 if me["wall"]["pat"] < me["wall"]["n"] else 3
		3:   # taken down
			me["wall"]["show"] = maxf(0.0, 1.0 - e.st / 0.35)
			if e.st >= 0.35:
				me["wall"] = {}
				RiftBosses._done(e, 0.6)

## The panel (column, row) of the wall under a point, or (-1, -1).
static func panel_at(w: Dictionary, x: float, y: float) -> Vector2i:
	if w.is_empty():
		return Vector2i(-1, -1)
	var c := floori((x - w["x0"]) / PANEL)
	var r := floori((y - w["y0"]) / PANEL)
	if c < 0 or r < 0 or c >= LED_COLS or r >= LED_ROWS:
		return Vector2i(-1, -1)
	return Vector2i(c, r)

## Whether a panel lights up in the wall's pattern now.
static func lit(w: Dictionary, c: int, r: int) -> bool:
	match int(w["pat"]) % 4:
		0: return (c + r) % 2 == 0
		1: return (c + r) % 2 == 1
		2: return r % 2 == 0
	return c % 2 == 1

## CABLES: three lanes across the room (four in the second phase, five in full metal), the first
## right where you stand, the others near you, shown first; then the cables go live and spark.
static func _cables(e: Enemy, p: Player, dt: float) -> void:
	var me := _me(e)
	match e.sub:
		0:
			if e.st < 0.02:
				var n := 5 if look(e) == 3 else (4 if e.phase == 2 else 3)
				var base := randf() * PI
				var cs := []
				for i in n:
					var q := Vector2(p.x, p.y)
					if i > 0:
						q += Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))
					cs.append(_across(q, base + i * PI / n))
				me["cables"] = cs
				e.face = 1 if p.x > e.x else -1
				Barks.say(e, "KABLI!", "white", 0.9)
			if e.st >= CABLE_WARN / _fast(e):
				e.sub = 1
				e.st = 0.0
				Snd.play("charge")
		1:
			for c in me["cables"]:
				if RiftBosses._near_seg(p.x, p.y, c[0], c[1], 4.0 + p.r * 0.5):
					Combat.hurt_player(1, e.d["name"])
					break
			if e.st >= CABLE_LIVE:
				me["cables"] = []
				RiftBosses._done(e, 0.6)

## A line through q at angle a, from wall to wall of the room.
static func _across(q: Vector2, a: float) -> Array:
	var d := Vector2(cos(a), sin(a))
	var t0 := -INF
	var t1 := INF
	for ax in 2:
		var dv := d.x if ax == 0 else d.y
		var qv := q.x if ax == 0 else q.y
		var lo := X0 if ax == 0 else Y0
		var hi := X1 if ax == 0 else Y1
		if absf(dv) < 0.0001:
			continue
		var ta := (lo - qv) / dv
		var tb := (hi - qv) / dv
		t0 = maxf(t0, minf(ta, tb))
		t1 = minf(t1, maxf(ta, tb))
	return [q + d * t0, q + d * t1]

## BEER: ŠE ENO PIVO!, he drinks, then throws the bottle where you stand (three in the second phase),
## where it lands shown first: it smashes into a ring of glass.
static func _beer(e: Enemy, p: Player, dt: float) -> void:
	var me := _me(e)
	match e.sub:
		0:
			if e.st < 0.02:
				Barks.say(e, "ŠE ENO PIVO!", "gold", 1.0)
			if e.st >= 0.9 / _fast(e):
				e.sub = 1
				e.st = 0.0
				var a0 := TB.ang_to(e, p)
				var d := TB.dist(e, p)
				var bs := []
				for i in (3 if e.phase == 2 else 1):
					var a := a0 + (i - 1) * 0.45 if e.phase == 2 else a0
					var to := _inside(Vector2(e.x + cos(a) * d, e.y + sin(a) * d))
					bs.append({ "x0": e.x + 10.0 * e.face, "y0": e.y - 30.0, "x1": to.x, "y1": to.y, "k": 0.0 })
				me["bottles"] = bs
				e.face = 1 if p.x > e.x else -1
				Snd.play("hatchet")
		1:   # the bottles in the air
			var k := minf(1.0, e.st / 0.7)
			for b in me["bottles"]:
				b["k"] = k
			if k >= 1.0:
				for b in me["bottles"]:
					if TB.dist_xy(p.x, p.y, b["x1"], b["y1"]) < 12.0 + p.r:
						Combat.hurt_player(1, e.d["name"])
					Combat.ering(b["x1"], b["y1"], 8, 70.0 * _fast(e), randf() * TAU, "ice")
					Fx.burst(b["x1"], b["y1"], ["#c8783a", "#f2c94c", "#ffffff"], 12, 70)
				Snd.play("hit")
				me["bottles"] = []
				RiftBosses._done(e, 0.6)

## POWER NAP: asleep on his flight case (he takes half again as much and does not hit back), his
## snores drifting at you; then he wakes with a start.
static func _nap(e: Enemy, p: Player, dt: float) -> void:
	e.z = 0.0
	match e.sub:
		0:
			if e.st < 0.02:
				Barks.say(e, "ŠE PET MINUT...", "white", 1.4)
			if e.st >= 0.3:
				e.sub = 1
				e.st = 0.0
				e.aux2 = 0.6
		1:
			e.aux2 -= dt
			if e.aux2 <= 0.0:
				e.aux2 = 0.8 if e.phase == 2 else 1.0
				Combat.eshot(e.x + 6.0 * e.face, e.y - 40.0, TB.ang_xy(e.x, e.y - 40.0, p.x, p.y) + randf_range(-0.3, 0.3), 38.0, "ice")
			if e.st >= (2.4 if e.phase == 2 else 3.0):
				e.sub = 2
				e.st = 0.0
				Fx.float_text(e.x, e.y - 60, "ŽE?!", "gold", true)
		2:
			if e.st >= 0.3:
				RiftBosses._done(e, 0.3)

## ONE MORE CHAPTER: he sits and reads; pages fly out round him in a slow spiral (two arms, three in
## the second phase).
static func _manga(e: Enemy, p: Player, dt: float) -> void:
	e.z = 0.0
	match e.sub:
		0:
			if e.st < 0.02:
				Barks.say(e, "ŠE EN CHAPTER...", "white", 1.2)
				e.aux = randf() * TAU
			if e.st >= 0.35:
				e.sub = 1
				e.st = 0.0
				e.aux2 = 0.0
		1:
			e.aux2 -= dt
			if e.aux2 <= 0.0:
				e.aux2 = 0.24
				var arms := 3 if e.phase == 2 else 2
				for i in arms:
					Combat.eshot(e.x, e.y - 24.0, e.aux + i * TAU / arms, 62.0 * _fast(e), "page")
				e.aux += 0.33
			if e.st >= (2.6 if e.phase == 2 else 3.2):
				RiftBosses._done(e, 0.5)

## HURIKAN (second phase): he spins after you, shots flying off him in a spiral (two arms, three in
## full metal).
static func _hurikan(e: Enemy, p: Player, dt: float) -> void:
	match e.sub:
		0:
			if e.st < 0.02:
				Barks.say(e, "HURIKAAAN!", "purple", 1.0)
				Snd.play("charge")
				e.aux = randf() * TAU
			if e.st >= 0.6 / _fast(e):
				e.sub = 1
				e.st = 0.0
				e.aux2 = 0.0
		1:
			Combat.steer(e, p.x, p.y, 62.0 * _fast(e), dt, World.M_WALKER)
			e.face = 1 if floori(e.st * 12.0) % 2 == 0 else -1   # spinning
			e.aux2 -= dt
			if e.aux2 <= 0.0:
				e.aux2 = 0.12
				var arms := 3 if look(e) == 3 else 2
				for i in arms:
					Combat.eshot(e.x, e.y - 20.0, e.aux + i * TAU / arms, 85.0 * _fast(e), _col(e))
				e.aux += 0.42
			if e.st >= 3.0:
				Afx.dust(e.x, e.y + 8)
				RiftBosses._done(e, 0.8)

## The live end of his lasso now: from his hand round along its angle.
static func lasso_ends(e: Enemy) -> Array:
	var h := Vector2(e.x, e.y - 30.0)
	return [h, h + Vector2(cos(e.angle), sin(e.angle)) * LASSO_R]

## LASSO (second phase): its reach shown first, then a live cable swings round him, a turn and a half.
static func _lasso(e: Enemy, p: Player, dt: float) -> void:
	match e.sub:
		0:
			if e.st < 0.02:
				e.aux = 1.0 if randf() < 0.5 else -1.0
				e.ca = TB.ang_to(e, p) - e.aux * 1.2   # it starts behind you
				e.angle = e.ca
				Barks.say(e, "KABEL!", "white", 0.9)
			if e.st >= 0.7:
				e.sub = 1
				e.st = 0.0
				Snd.play("charge")
		1:
			var span := 1.6 / _fast(e)
			var k := minf(1.0, e.st / span)
			e.angle = e.ca + e.aux * k * 3.0 * PI
			var ends := lasso_ends(e)
			if RiftBosses._near_seg(p.x, p.y, ends[0], ends[1], 6.0 + p.r * 0.5):
				Combat.hurt_player(1, e.d["name"])
			if k >= 1.0:
				RiftBosses._done(e, 0.6)

## WALL OF DEATH (second phase): a wall of shots from each side of the room runs at the other, each
## with a gap (shown first, gold); in full metal a second pair follows.
static func _walldeath(e: Enemy, p: Player, dt: float) -> void:
	var me := _me(e)
	match e.sub:
		0:
			if e.st < 0.02:
				var g0 := randf_range(Y0 + 24.0, Y1 - 24.0)
				var g1 := randf_range(Y0 + 24.0, Y1 - 24.0)
				if absf(g1 - g0) < 50.0:
					g1 = g0 + (60.0 if g0 < (Y0 + Y1) / 2.0 else -60.0)
				me["gaps"] = [g0, g1]
				e.face = 1 if p.x > e.x else -1
				if e.repeat == 0:
					Barks.say(e, "WALL OF DEATH!", "purple", 1.2)
				Snd.play("charge")
			if e.st >= 0.9 / _fast(e):
				var gaps: Array = me["gaps"]
				var y := Y0 + 6.0
				while y < Y1:
					if absf(y - gaps[0]) > WALL_GAP:
						Combat.eshot(X0 + 4.0, y, 0.0, 75.0 * _fast(e), _col(e))
					if absf(y - gaps[1]) > WALL_GAP:
						Combat.eshot(X1 - 4.0, y, PI, 75.0 * _fast(e), _col(e))
					y += 11.0
				Snd.play("ebullet")
				G.add_shake(3)
				e.repeat += 1
				e.st = 0.0
				if look(e) == 3 and e.repeat < 2:
					e.sub = 1
				else:
					e.repeat = 0
					me.erase("gaps")
					RiftBosses._done(e, 0.8)
		1:   # full metal: the next pair, a moment later
			if e.st >= 0.6:
				e.sub = 0
				e.st = 0.0

## STAGE DIVE (second phase): he crouches, leaps and lands where you stood (shown first): a ring of
## shock where he lands.
static func _dive(e: Enemy, p: Player, dt: float) -> void:
	match e.sub:
		0:
			e.z = 0.0
			if e.st < 0.02:
				e.from = Vector2(e.x, e.y)
				e.to = _inside(Vector2(p.x, p.y))
				e.face = 1 if p.x > e.x else -1
				Barks.say(e, "STAGE DIVE!", "purple", 1.0)
			if e.st >= 0.55:
				e.sub = 1
				e.st = 0.0
				Snd.play("hatchet")
		1:
			var k := minf(1.0, e.st / DIVE_T)
			e.x = lerpf(e.from.x, e.to.x, k)
			e.y = lerpf(e.from.y, e.to.y, k)
			e.z = sin(k * PI) * 70.0
			if k >= 1.0:
				e.z = 0.0
				if TB.dist(e, p) < 26.0 + p.r:
					Combat.hurt_player(1, e.d["name"])
				Combat.ering(e.x, e.y - 4.0, 18 if look(e) == 3 else 14, 80.0 * _fast(e), randf() * TAU, _col(e))
				Afx.dust(e.x, e.y + 8)
				G.add_shake(6)
				Snd.play("boom")
				_keep(e)
				RiftBosses._done(e, 0.7)

## Beaten (Game.on_boss_dead): he clocks out where he stands, asleep in his cables.
static func on_beaten(b: Enemy) -> void:
	if G.banner.is_empty() or G.banner.get("t", 0.0) < 2.0:
		G.show_banner(NAME_SHORT + " CLOCKED OUT", "OVERTIME IS OVER")
	else:
		G.toast(NAME_SHORT + " CLOCKED OUT", "gold")
	Snd.play("hit")
	G.room.objects.append({ "kind": "vid_rest", "x": b.x, "y": b.y, "look": look(b) })

# ---------- Drawing ----------
## His look (Stages.look): 2 his metal form (from the moment he transforms), 3 full metal.
static func look(e: Enemy) -> int:
	return maxi(Stages.look(e), 2 if e.state == &"phase" and e.sub == 1 else 1)

## world_view._enemy_sprite: the pose of each move; standing for the rest.
static func sprite(e: Enemy) -> String:
	var s := "vid"
	match e.state:
		&"peace", &"walldeath":
			s = "vid_peace"
		&"ledwall":
			s = "vid_panel"
		&"cables":
			s = "vid_lasso" if e.sub == 0 else "vid"
		&"lasso":
			s = "vid_lasso"
		&"beer":
			s = "vid_drink" if e.sub == 0 else "vid"
		&"nap":
			s = "vid_nap"
		&"manga":
			s = "vid_manga"
		&"hurikan":
			s = "vid_spin" if e.sub == 1 else "vid"
		&"dive":
			s = "vid_peace" if e.sub == 1 else "vid"
	var lk := look(e)
	return s + ("_s%d" % lk if lk > 1 else "")

## With his body (RiftBosses.draw_parts): the bottles in the air, the live lasso, his snores.
static func draw_parts(ci: CanvasItem, e: Enemy, foot: float, t: float) -> void:
	var me := _me(e)
	for b in (me.get("bottles", []) if e.state == &"beer" else []):
		var k: float = b["k"]
		var at := Vector2(lerpf(b["x0"], b["x1"], k), lerpf(b["y0"], b["y1"], k) - sin(k * PI) * 40.0)
		Gfx.sprite(ci, "vid_bottle", at.x, at.y, 6, 3, 2.0, 2.0, t * 14.0, false)
	if e.state == &"lasso" and e.sub == 1:
		var ends := lasso_ends(e)
		var h: Vector2 = ends[0]
		var tip: Vector2 = ends[1]
		ci.draw_line(h, tip, TB.c("#16141c"), 3.0)
		ci.draw_line(h, tip, TB.c("#5ee8f5") if floori(t * 20.0) % 2 == 0 else TB.c("#ffffff"), 1.0)
		ci.draw_circle(tip, 3.0, TB.c("#ffffff"))
	if e.state == &"nap" and e.sub == 1:
		var k := fmod(t * 0.7, 1.0)
		Gfx.text(ci, "Z", e.x + 10.0 * e.face + k * 8.0, foot - 70.0 - k * 16.0, "white", 1, 0.5, true, 1.0 - k)

## On the floor with the other warnings (RiftBosses.draw_ground): the LED wall, the cables, where the
## bottles land, the lasso's reach, the walls of death and their gaps, where he lands.
static func draw_ground(ci: CanvasItem, e: Enemy, t: float) -> void:
	var warn := Afx.C_WARN
	var me := _me(e)
	var w: Dictionary = me.get("wall", {})
	if e.state == &"ledwall" and not w.is_empty():
		var a: float = w["show"]
		for c in LED_COLS:
			for r in LED_ROWS:
				var x: float = w["x0"] + (c + 0.5) * PANEL
				var y: float = w["y0"] + (r + 1.0) * PANEL
				var on := lit(w, c, r)
				if e.sub == 2 and on:
					Gfx.sp(ci, "vid_led_on", x, y, 2.0, 2.0, 0.0, false, a)
				elif e.sub == 1 and on and floori(t * 10.0) % 2 == 0:
					Gfx.sp(ci, "vid_led_on", x, y, 2.0, 2.0, 0.0, false, 0.5 * a)
					ci.draw_rect(Rect2(x - PANEL / 2.0, y - PANEL, PANEL, PANEL), Color(warn, 0.8 * a), false, 1.0)
				else:
					Gfx.sp(ci, "vid_led", x, y, 2.0, 2.0, 0.0, false, a)
	match e.state:
		&"cables":
			for cb in me.get("cables", []):
				var p0: Vector2 = cb[0]
				var p1: Vector2 = cb[1]
				if e.sub == 0:
					Afx.lane(ci, p0.x, p0.y, (p1 - p0).angle(), 4.0, p0.distance_to(p1), e.st / (CABLE_WARN / _fast(e)), warn, t)
				else:
					ci.draw_line(p0, p1, TB.c("#16141c"), 3.0)
					ci.draw_line(p0, p1, TB.c("#5ee8f5"), 1.0)
					for i in 3:
						var q := p0.lerp(p1, fmod(t * 0.8 + i / 3.0, 1.0))
						ci.draw_circle(q, 2.5, TB.c("#ffffff"))
		&"beer":
			for b in me.get("bottles", []):
				Afx.landing(ci, b["x1"], b["y1"] + 4, 16.0, b["k"], warn, t)
		&"lasso":
			if e.sub == 0:
				Afx.landing(ci, e.x, e.y + 4, LASSO_R, e.st / 0.7, warn, t)
		&"walldeath":
			if e.sub == 0 and me.has("gaps"):
				var k := clampf(e.st / (0.9 / _fast(e)), 0.0, 1.0)
				var gaps: Array = me["gaps"]
				for side in 2:
					var x := X0 + 2.0 if side == 0 else X1 - 6.0
					var g: float = gaps[side]
					ci.draw_rect(Rect2(x, Y0, 4.0, g - WALL_GAP - Y0), Color(warn, 0.3 + 0.5 * k))
					ci.draw_rect(Rect2(x, g + WALL_GAP, 4.0, Y1 - g - WALL_GAP), Color(warn, 0.3 + 0.5 * k))
					ci.draw_rect(Rect2(x - 2.0, g - WALL_GAP, 8.0, WALL_GAP * 2.0), Color(1.0, 0.85, 0.3, 0.25 + 0.3 * k), false, 1.0)
		&"dive":
			if e.sub == 1:
				Afx.landing(ci, e.to.x, e.to.y + 4, 26.0, e.st / DIVE_T, warn, t)

## Beaten: asleep in his cables where he fell, snoring (Game.on_boss_dead put him there; world_view
## draws him).
static func draw_rest(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var lk: int = o.get("look", 1)
	Gfx.sp(ci, "vid_out" + ("_s%d" % lk if lk > 1 else ""), o["x"], o["y"] + 12, 2.0, 2.0)
	var k := fmod(t * 0.6, 1.0)
	Gfx.text(ci, "Z", o["x"] + 26 + k * 6, o["y"] - 20 - k * 14, "white", 1, 0.5, true, 1.0 - k)
