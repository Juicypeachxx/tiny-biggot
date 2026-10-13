class_name RiftBosses
extends RefCounted
## The mini-boss and the guardian of each new rift world (ROADMAP 4.5, his ask on 5 Oct).
##
## Where they fight: in a new world's rift, the last wave of the second room is the world's
## mini-boss. When the champion falls, a second door leads deeper, to the world's guardian: an
## optional fight with a guardian's hoard. Every attack is shown before it lands (lanes, rings and
## bands, as in ATTACK_EFFECTS.md). Below half health each one has a second phase: a moment in
## which it takes no damage and the shots on screen vanish, a line on the banner, then harder
## attacks and new ones.
##
##   THE SQUALL HERON (Skyreach, mini-boss): quills that stop in the air and turn on you; lightning
##     rods, joined by arcs; a gale along its row. Phase 2: rings of quills, arcs to itself too, a
##     second gale across.
##   THE STORMCROWN (Skyreach, guardian): sky lances (bands that strike); a ring of shots round you
##     that closes in, with one gap; downdrafts (the world's gusts); ball lightning joined by arcs.
##     Phase 2: a cyclone that hunts you, crossed lances, and the eye of the storm pulls you in.
##   THE DROWNED CAPTAIN (Bastion, mini-boss): throws his anchor down a lane and hauls himself
##     after it; swings it round in a ring; lobs barrels of sludge. Phase 2: more of each, and the
##     haul leaves sludge.
##   THE BILGE HYDRA (Bastion, guardian): heads that lunge down lanes; a breath that sweeps;
##     sludge spat in arcs; the toxic tide on call. Phase 2: two more heads, two breaths that cross.
##   THE BELLRINGER (Cathedral, mini-boss): tolls (rings of sound to roll through); a hymn of notes
##     that weave; drops the bell where you stand (and is bare, +50% damage, until it comes back).
##     Phase 2: more tolls, the bell bounces after you.
##   THE BRASS ORGAN (Cathedral, guardian): pipes light before they fire (a toccata, a fugue); a
##     chord that leaves only gold lanes safe; a choir of foes. Phase 2: pedal waves with one gap,
##     two wall turrets, and it slides along the wall as it plays.
##
## The fights' own things live in the lists below. tick() moves them (from Hazards.update, so they
## keep going while their maker is stunned); clear() empties them when the room changes and when a
## fight ends. None of this touches the original game: these bosses exist only in rift worlds.

const PHASE_T := 1.4          # the grace between the phases
const ROD_FALL := 0.35        # a lightning rod in the air
const ARC_WARN := 0.9         # an arc flickers this long before it strikes
const ARC_FIRE := 0.3
const LANCE_WARN := 0.75
const RING_WARN := 0.8
const LOB_T := 0.8

## Attack plans: [first phase, second phase], each cycled in order.
const PLANS := {
	"squallheron": [["quills", "rods", "gale"], ["quills", "rods", "gale", "rods"]],
	"stormcrown": [["lances", "vortex", "downdraft", "lances", "orbs"], ["cyclone", "lances", "vortex", "orbs", "downdraft", "lances"]],
	"tidecaptain": [["anchor", "swing", "bilge"], ["anchor", "swing", "bilge", "anchor"]],
	"bilgehydra": [["bite", "breath", "spit", "bite", "flood"], ["bite", "breath", "spit", "flood", "bite", "breath"]],
	"bellringer": [["toll", "hymn", "drop"], ["toll", "hymn", "drop", "toll"]],
	"brassorgan": [["toccata", "fugue", "chord", "choir", "toccata"], ["toccata", "chord", "fugue", "pedal", "chord", "choir"]],
	"rex": [["flop", "zoomies", "dig", "woof", "nap"], ["spin", "leap", "fetch", "flop", "wave", "woof"]],   # rex.gd
	"arci": [["frisbee", "boop", "dropit", "herd", "frisbee", "cat", "crash"], ["frenzy", "stick", "dropit", "bounce", "boop", "frisbee", "cat", "crash"]],   # arci.gd
	"sefe": [["fingerguns", "mog", "smoke", "fingerguns", "beer", "zoned"], ["bigone", "fingerguns", "chainsaw", "mog", "axe", "beer", "smoke", "zoned"]],   # sefe.gd
}
const PHASE_LINE := {
	"squallheron": "THE SQUALL BREAKS", "stormcrown": "THE EYE OF THE STORM OPENS",
	"tidecaptain": "THE DEEP WILL NOT KEEP HIM", "bilgehydra": "CUT ONE, TWO MORE RISE",
	"bellringer": "THE BELL CRACKS. IT RINGS LOUDER", "brassorgan": "THE ORGAN PLAYS ITSELF",
	"rex": "SUNGLASSES ON. HE FOUND A MOLDY LOAF IN THE HAY",
	"arci": "SUNGLASSES ON. TOO COOL TO STOP",
	"sefe": "THE CROWN GOES ON. RESPECT THE BLOK",
}
const COL := { "squallheron": "#9fc3ee", "stormcrown": "#6fd3e0", "tidecaptain": "#63b84f", "bilgehydra": "#b8e05a",
	"bellringer": "#f2c94c", "brassorgan": "#e8873a", "rex": "#f2c94c", "arci": "#e86fb4", "sefe": "#9ad07a" }
## The organ's pipes: column and top row in its 40 x 28 picture (drawn twice as large).
const PIPE_COL := [3.5, 7.5, 10.5, 13.5, 16.5, 19.5, 22.5, 25.5, 28.5, 31.5, 35.5]
const PIPE_ROW := [4, 1, 6, 1, 6, 1, 6, 1, 6, 1, 4]
const FUGUE := [0, 10, 2, 8, 4, 6, 1, 9, 3, 7, 5]   # which pipe answers which
const CHOIR := ["shellpriest", "deacon"]

static var held: Array = []      # quills: { x, y, vx, vy, fly, hold, by }
static var rods: Array = []      # lightning rods: { x, y, fx, fy, fall, life }
static var arcs: Array = []      # lightning between two points: { a, b, oa, ob, follow, warn, fire, by }
static var bands: Array = []     # sky lances: { horiz, pos, half, warn, fire, by, hit }
static var rings: Array = []     # closing rings: { x, y, r, gap, gw, warn, n, by }
static var orbs: Array = []      # ball lightning: { x, y, grow, life, pulse, by }
static var twisters: Array = []  # cyclones: { x, y, grow, life, debris, by }
static var lobs: Array = []      # sludge, barrels and the bell in the air: { x0, y0, x1, y1, t, dur, kind, by, hops, owner }
static var waves: Array = []     # tolls: { x, y, r, speed, max, w, hit, by }
static var notes: Array = []     # the hymn: { ox, oy, a, s, t, speed, amp, ph, x, y, by }
static var pipes: Array = []     # organ pipes about to fire: { i, t, warn, kind, owner }
static var chords: Array = []    # chords: { lanes, half, warn, rows, gap, by }
static var sweeps: Array = []    # pedal waves: { y, gap, half, warn, hit, by }
static var _room: WeakRef = null

static func key(e: Enemy) -> String:
	return e.boss if e.boss != "" else e.type

static func handles(e: Enemy) -> bool:
	return PLANS.has(key(e))

static func clear() -> void:
	for l in [held, rods, arcs, bands, rings, orbs, twisters, lobs, waves, notes, pipes, chords, sweeps]:
		l.clear()

static func _quiet() -> bool:
	return held.is_empty() and rods.is_empty() and arcs.is_empty() and bands.is_empty() and rings.is_empty() \
		and orbs.is_empty() and twisters.is_empty() and lobs.is_empty() and waves.is_empty() and notes.is_empty() \
		and pipes.is_empty() and chords.is_empty() and sweeps.is_empty()

## Damage (EnemyAI2.adjust_damage, rule "phase"): none in the grace between the phases; the
## bellringer without its bell takes half again as much.
static func adjust_damage(e: Enemy, dmg: float) -> float:
	if e.state == &"phase":
		return 0.0
	if e.type == "bellringer" and _bell_out(e):
		return dmg * 1.5
	if e.boss == "rex":
		return Rex.adjust_damage(e, dmg)
	if e.boss == "arci":
		return Arci.adjust_damage(e, dmg)
	if e.boss == "sefe":
		return Sefe.adjust_damage(e, dmg)
	return dmg

## A mini-boss down (Combat.kill_enemy): its things stop, and it leaves a little hoard.
static func on_kill(e: Enemy) -> void:
	if e.is_boss() or not handles(e):
		return
	clear()
	Combat.drop_pickup("heart", e.x, e.y)
	Combat.drop_pickup("ember", e.x, e.y)
	for i in 3:
		Combat.drop_pickup("gem", e.x, e.y)
	G.show_banner(e.d["name"] + " FALLS", "THE CHAMPION AWAITS")

# ---------- The fight ----------
static func update(e: Enemy, dt: float) -> void:
	var p := G.player
	var k := key(e)
	e.st += dt
	if e.parts.is_empty():
		_setup(e, k)
	if e.state == &"sleep":
		Rex.sleeping(e, dt)   # Rex, asleep on his mat until you come close
		return
	if e.state == &"intro":
		if e.t <= 0:
			_pick(e, k)
		_idle_parts(e, k, dt)
		return
	if e.phase == 1 and e.state != &"phase" and e.hp < e.max_hp * 0.5 and e.hp > 0:
		_begin_phase(e, k)
		return
	if e.state == &"phase":
		if k == "bilgehydra":
			for h in e.parts:
				h["grow"] = minf(1.0, h["grow"] + dt / PHASE_T)
		if k == "rex":
			Rex.to_hay(e, dt)
		if k == "arci":
			Arci.to_cool(e, dt)
		if k == "sefe":
			Sefe.to_king(e, dt)
		_idle_parts(e, k, dt)
		if e.st >= PHASE_T:
			e.phase = 2
			e.cycle = 0
			Combat.ering(e.x, e.y - 4, 16, 70, randf() * TAU, _shot(k))
			G.add_shake(6)
			Snd.play("boom")
			_done(e, 0.5)
		return
	if k == "stormcrown" and e.phase == 2:
		_pull(e, p, dt)
	if k == "brassorgan" and e.phase == 2:
		e.x = TB.SW / 2.0 + sin(e.aux2) * 96.0   # it slides along the wall as it plays
		e.aux2 += dt * 0.5
	if e.state == &"rest" or e.state == &"idle":
		_rest_move(e, k, p, dt)
		_idle_parts(e, k, dt)
		if e.t <= 0:
			_pick(e, k)
		return
	match k:
		"squallheron": _heron(e, p, dt)
		"stormcrown": _crown(e, p, dt)
		"tidecaptain": _captain(e, p, dt)
		"bilgehydra": _hydra(e, p, dt)
		"bellringer": _ringer(e, p, dt)
		"brassorgan": _organ(e, p, dt)
		"rex": Rex.attack(e, p, dt)
		"arci": Arci.attack(e, p, dt)
		"sefe": Sefe.attack(e, p, dt)
	_idle_parts(e, k, dt)

static func _setup(e: Enemy, k: String) -> void:
	match k:
		"tidecaptain":
			e.parts = [{ "kind": "anchor", "out": false }]
		"bellringer":
			e.parts = [{ "kind": "bell", "out": false, "glow": 0.0 }]
		"bilgehydra":
			e.x = TB.SW / 2.0
			e.y = 5.4 * TB.TS
			for i in 3:
				e.parts.append(_new_head(e, 1.0))
		"brassorgan":
			e.x = TB.SW / 2.0
			e.y = 5.75 * TB.TS
			e.parts = [{ "kind": "organ" }]
		"arci":
			e.parts = [{ "kind": "arci", "discs": [], "cat": {}, "out": false }]
		"sefe":
			e.parts = [{ "kind": "sefe", "hits": 0, "can": {}, "axes": [], "out": false }]
		_:
			e.parts = [{ "kind": "none" }]

static func _new_head(e: Enemy, grow: float) -> Dictionary:
	return { "kind": "head", "x": e.x, "y": e.y + 30.0, "st": "idle", "t": 0.0, "a": 0.0, "a1": 0.0, "len": 0.0, "d": 0.0,
		"grow": grow, "puddle": 0.0 }

static func _pick(e: Enemy, k: String) -> void:
	var plan: Array = PLANS[k][e.phase - 1]
	e.state = StringName(plan[e.cycle % plan.size()])
	e.cycle += 1
	e.st = 0.0
	e.t = 0.0
	e.sub = 0
	e.repeat = 0
	e.has_telegraph = false

static func _done(e: Enemy, wait: float = 0.9) -> void:
	e.state = &"rest"
	e.st = 0.0
	e.sub = 0
	e.has_target = false
	e.t = wait * (0.7 if e.phase == 2 else 1.0) * BossAI.rest()   # 57: 15% less rest

static func _begin_phase(e: Enemy, k: String) -> void:
	e.state = &"phase"
	e.st = 0.0
	e.sub = 0
	EBullets.clear_all()
	for l in [held, notes, lobs, orbs, twisters, pipes, chords, sweeps, arcs, rods, bands, rings, waves]:
		l.clear()
	# The room's own hazards pause too: gusts and tides end, turrets go back to waiting.
	G.room.gusts.clear()
	G.room.tides.clear()
	for tr in G.room.turrets:
		tr["state"] = 0
		tr["t"] = maxf(tr["t"], PHASE_T + 0.5)
	for part in e.parts:
		part["out"] = false
		part["st"] = "idle"
	if k == "bilgehydra":
		for i in 2:
			e.parts.append(_new_head(e, 0.0))
	if k == "brassorgan":
		for c in [5, 22]:
			G.room.turrets.append({ "x": c * TB.TS + 8.0, "y": 2.0 * TB.TS + 6.0, "t": 2.0 + randf(), "state": 0, "a": PI / 2,
				"shots": 0 })
	G.show_banner(e.d["name"], PHASE_LINE[k])
	G.add_shake(5)
	Snd.play("roar")
	Fx.burst(e.x, e.y, [COL[k], "#f4ecd8"], 24, 110)

static func _rest_move(e: Enemy, k: String, p: Player, dt: float) -> void:
	match k:
		"squallheron", "stormcrown":
			if not e.has_target or TB.dist_xy(e.x, e.y, e.target.x, e.target.y) < 4:
				e.target = Vector2(randf_range(4.0 * TB.TS, 24.0 * TB.TS), randf_range(4.0 * TB.TS, (8.0 if k == "stormcrown" else 12.0) * TB.TS))
				e.has_target = true
			Combat.steer(e, e.target.x, e.target.y, 46.0 if k == "stormcrown" else 70.0, dt, World.M_FLYER)
			e.face = 1 if p.x > e.x else -1
		"tidecaptain", "bellringer":
			EnemyAI.wander_keep(e, dt, p, 70, 130)
			e.face = 1 if p.x > e.x else -1
		"rex":
			Rex.rest_move(e, p, dt)
		"arci":
			Arci.rest_move(e, p, dt)
		"sefe":
			Sefe.rest_move(e, p, dt)

static func _pull(e: Enemy, p: Player, dt: float) -> void:
	if p.dodge_t > 0 or p.leap_max > 0:
		return
	var dv := Vector2(e.x - p.x, e.y - p.y)
	if dv.length() < 50:
		return
	dv = dv.normalized() * 18.0 * dt
	World.move_body(G.room, p, dv.x, dv.y, World.M_PLAYER)

static func _shot(k: String) -> String:
	return { "squallheron": "cyan", "stormcrown": "cyan", "tidecaptain": "spore", "bilgehydra": "spore",
		"bellringer": "bone", "brassorgan": "fire", "rex": "bone", "arci": "bone", "sefe": "red" }[k]

## A point kept inside the room.
static func _inside(v: Vector2) -> Vector2:
	return Vector2(clampf(v.x, 2.5 * TB.TS, 25.5 * TB.TS), clampf(v.y, 3.5 * TB.TS, 16.0 * TB.TS))

# ---------- THE SQUALL HERON ----------
static func _heron(e: Enemy, p: Player, dt: float) -> void:
	var h2 := e.phase == 2
	match e.state:
		&"quills":
			if e.t > 0:
				return
			if e.sub >= (3 if h2 else 2):
				_done(e)
				return
			e.t = 0.9 if h2 else 1.1
			var a := TB.ang_to(e, p)
			var n := 12 if h2 else 7
			for i in n:
				var ang: float = a + (float(i) / n * TAU if h2 else (i - (n - 1) / 2.0) * 0.2)
				held.append({ "x": e.x, "y": e.y - 4.0, "vx": cos(ang) * 130.0, "vy": sin(ang) * 130.0, "fly": 0.35, "hold": 0.5,
					"by": e.d["name"] })
			Afx.cast(e.x, e.y - 4, "cyan")
			Snd.play("ebullet")
			e.sub += 1
		&"rods":
			if e.sub == 0:
				var n := 4 if h2 else 3
				var a0 := randf() * TAU
				var pts := []
				for i in n:
					var a := a0 + float(i) / n * TAU
					pts.append(_inside(Vector2(p.x + cos(a) * 62.0, p.y + sin(a) * 50.0)))
				for i in n:
					arcs.append(_arc(pts[i], pts[(i + 1) % n], ROD_FALL + ARC_WARN, e))
					if h2:
						var fa := _arc(pts[i], Vector2(e.x, e.y - 4), ROD_FALL + ARC_WARN, e)
						fa["follow"] = weakref(e)
						arcs.append(fa)
				for pt in pts:
					rods.append({ "x": pt.x, "y": pt.y, "fx": e.x, "fy": e.y - 4, "fall": ROD_FALL, "life": ROD_FALL + ARC_WARN + ARC_FIRE + 0.3 })
				e.sub = 1
				e.st = 0.0
				Snd.play("charge")
			elif e.st > ROD_FALL + ARC_WARN + ARC_FIRE + 0.25:
				e.repeat += 1
				if e.repeat >= (2 if h2 else 1):
					_done(e)
				else:
					e.sub = 0
		&"gale":
			if e.sub == 0:
				var left := p.x > TB.SW / 2.0
				e.from = Vector2(e.x, e.y)
				e.to = Vector2(2.6 * TB.TS if left else TB.SW - 2.6 * TB.TS, clampf(p.y, 4.5 * TB.TS, 15.5 * TB.TS))
				e.sub = 1
				e.st = 0.0
			if e.sub == 1:
				var q := minf(1.0, e.st / 0.6)
				e.x = lerpf(e.from.x, e.to.x, q)
				e.y = lerpf(e.from.y, e.to.y, q)
				if q >= 1.0:
					e.sub = 2
					e.st = 0.0
					_gust(true, e.y, 1 if e.x < TB.SW / 2.0 else -1)
					if h2:
						_gust(false, p.x, 1 if p.y < TB.SH / 2.0 else -1)
					Snd.play("charge")
			elif e.sub == 2:
				e.face = 1 if e.x < TB.SW / 2.0 else -1
				if e.st > Hazards.GUST_WARN + Hazards.GUST_BLOW:
					_done(e)

static func _gust(horiz: bool, pos: float, dir: int) -> void:
	pos = clampf(pos, 4.0 * TB.TS, 16.0 * TB.TS) if horiz else clampf(pos, 3.0 * TB.TS, 25.0 * TB.TS)
	G.room.gusts.append({ "horiz": horiz, "pos": pos, "dir": dir, "t": Hazards.GUST_WARN, "blow": Hazards.GUST_BLOW, "spawn": 0.0 })

static func _arc(a: Vector2, b: Vector2, warn: float, e: Enemy) -> Dictionary:
	return { "a": a, "b": b, "warn": warn, "fire": ARC_FIRE, "by": e.d["name"], "w": warn }

# ---------- THE STORMCROWN ----------
static func _crown(e: Enemy, p: Player, dt: float) -> void:
	var h2 := e.phase == 2
	match e.state:
		&"lances":
			var n := 7 if h2 else 5
			if e.sub < n and e.t <= 0:
				e.t = 0.32
				var x: float = p.x if e.sub == 0 else p.x + randf_range(-70.0, 70.0)
				bands.append({ "horiz": false, "pos": clampf(x, 2.0 * TB.TS, 26.0 * TB.TS), "half": 11.0, "warn": LANCE_WARN,
					"fire": 0.14, "by": e.d["name"], "hit": false })
				if h2:
					bands.append({ "horiz": true, "pos": clampf(p.y + randf_range(-30.0, 30.0), 4.0 * TB.TS, 16.0 * TB.TS), "half": 11.0,
						"warn": LANCE_WARN, "fire": 0.14, "by": e.d["name"], "hit": false })
				e.sub += 1
				if e.sub % 2 == 1:
					Snd.play("charge")
			elif e.sub >= n and e.t <= -LANCE_WARN:
				_done(e)
		&"vortex":
			if e.sub == 0:
				e.angle = randf() * TAU
				_ring(p, e.angle, e)
				e.sub = 1
			elif e.sub == 1 and h2 and e.st > 0.7:
				_ring(p, e.angle + PI, e)
				e.sub = 2
			if e.st > (2.8 if h2 else 2.2):
				_done(e)
		&"downdraft":
			if e.sub == 0:
				e.sub = 1
				_gust(true, p.y, 1 if p.x < TB.SW / 2.0 else -1)
				if h2:
					_gust(false, p.x, 1 if p.y < TB.SH / 2.0 else -1)
				Snd.play("charge")
			if h2 and e.t <= 0:
				e.t = 0.8
				Combat.ering(e.x, e.y - 6, 14, 60, randf() * TAU, "ice")
			if e.st > Hazards.GUST_WARN + Hazards.GUST_BLOW + 0.2:
				_done(e)
		&"orbs":
			if e.sub == 0:
				e.sub = 1
				var n := 4 if h2 else 3
				for i in n:
					var a := float(i) / n * TAU + randf()
					orbs.append({ "x": e.x + cos(a) * 30.0, "y": e.y + sin(a) * 22.0, "grow": 0.4, "life": 4.6, "pulse": 0.9,
						"by": e.d["name"] })
				Snd.play("charge")
			if e.st > 2.0:
				_done(e)
		&"cyclone":
			if e.sub == 0:
				e.sub = 1
				twisters.append({ "x": e.x, "y": e.y + 12.0, "grow": 0.7, "life": 5.5, "debris": 0.3, "by": e.d["name"] })
				Snd.play("charge")
			if e.st > 1.2:
				_done(e)

## A ring of shots round the hero that closes in, with one gap (shown first as a ring on the floor).
static func _ring(p: Player, gap: float, e: Enemy) -> void:
	rings.append({ "x": p.x, "y": p.y, "r": 120.0, "gap": gap, "gw": 0.42, "warn": RING_WARN, "n": 24, "by": e.d["name"] })

# ---------- THE DROWNED CAPTAIN ----------
static func _captain(e: Enemy, p: Player, dt: float) -> void:
	var h2 := e.phase == 2
	var anchor: Dictionary = e.parts[0]
	match e.state:
		&"anchor":
			match e.sub:
				0:   # aim: a lane shows where the anchor will fly
					e.ca = TB.ang_to(e, p)
					e.face = 1 if cos(e.ca) > 0 else -1
					e.aux2 = Afx.reach(e.x, e.y, e.ca, 220.0, World.M_BULLET)
					e.sub = 1
					e.st = 0.0
				1:
					if e.st >= 0.6:
						e.sub = 2
						e.st = 0.0
						e.from = Vector2(e.x, e.y)
						anchor["out"] = true
						Snd.play("hatchet")
				2:   # the anchor flies
					var d := minf(e.st * 300.0, e.aux2)
					e.to = e.from + Vector2(cos(e.ca), sin(e.ca)) * d
					if TB.dist_xy(e.to.x, e.to.y, p.x, p.y) < 7.0 + p.r:
						Combat.hurt_player(1, e.d["name"])
					if d >= e.aux2:
						e.sub = 3
						e.st = 0.0
						G.add_shake(3)
						Snd.play("boom")
						Afx.dust(e.to.x, e.to.y)
						Combat.ering(e.to.x, e.to.y, 6, 55, randf() * TAU, "spore")
				3:   # the chain pulls taut: he is about to haul himself along it
					if e.st >= 0.35:
						e.sub = 4
						e.st = 0.0
						e.t = 0.0
				4:   # hauled along the chain
					var dv := e.to - Vector2(e.x, e.y)
					var step := 240.0 * dt
					var arrived := dv.length() <= step + 2.0
					if not arrived:
						var n := dv.normalized()
						arrived = World.move_body(G.room, e, n.x * step, n.y * step, World.M_WALKER) != 0
					if h2 and e.t <= 0:
						e.t = 0.12
						EnemyAI2.add_goo("sludge", e.x, e.y + 4.0, 10.0, 4.0)
					if arrived:
						anchor["out"] = false
						G.add_shake(4)
						Snd.play("boom")
						Combat.ering(e.x, e.y, 10, 60, randf() * TAU, "spore")
						e.repeat += 1
						if e.repeat >= (3 if h2 else 2):
							_done(e)
						else:
							e.sub = 0
		&"swing":
			var radius := 58.0 if h2 else 46.0
			match e.sub:
				0:
					e.angle = TB.ang_to(e, p) + PI   # it starts behind him
					e.aux = 1.0 if randf() < 0.5 else -1.0
					e.aux2 = 0.0
					e.sub = 1
					e.st = 0.0
				1:
					if e.st >= 0.7:
						e.sub = 2
						e.st = 0.0
						anchor["out"] = true
						Snd.play("charge")
				2:
					var turn := TAU / 0.9 * dt
					e.angle += e.aux * turn
					e.aux2 += turn
					e.to = Vector2(e.x + cos(e.angle) * radius, e.y + sin(e.angle) * radius)
					if TB.dist_xy(e.to.x, e.to.y, p.x, p.y) < 8.0 + p.r:
						Combat.hurt_player(1, e.d["name"])
					if e.aux2 >= PI / 4:
						e.aux2 -= PI / 4
						Combat.eshot(e.to.x, e.to.y, e.angle, 50, "spore")
					if e.st >= (1.8 if h2 else 0.9):
						anchor["out"] = false
						_done(e)
		&"bilge":
			var n := 5 if h2 else 3
			if e.sub < n and e.t <= 0:
				e.t = 0.25
				var off := Vector2.ZERO if e.sub == 0 else Vector2(randf_range(-50.0, 50.0), randf_range(-40.0, 40.0))
				_lob(e.x, e.y - 6.0, p.x + off.x, p.y + off.y, LOB_T, "sludge", e)
				e.sub += 1
				Snd.play("ebullet")
			elif e.sub >= n and e.t <= -1.0:
				_done(e)

static func _lob(x0: float, y0: float, x1: float, y1: float, dur: float, kind: String, e: Enemy, hops: int = 0) -> void:
	var to := _inside(Vector2(x1, y1))
	lobs.append({ "x0": x0, "y0": y0, "x1": to.x, "y1": to.y, "t": 0.0, "dur": dur, "kind": kind, "by": e.d["name"], "hops": hops,
		"owner": weakref(e) })

# ---------- THE BILGE HYDRA ----------
static func _head_rest(e: Enemy, i: int, n: int) -> Vector2:
	var a := PI / 2 + (i - (n - 1) / 2.0) * (0.5 if n > 3 else 0.72)
	return Vector2(e.x + cos(a) * 52.0, e.y + 8.0 + sin(a) * 40.0 + sin(G.time * 2.2 + i * 1.7) * 2.0)

static func _hydra(e: Enemy, p: Player, dt: float) -> void:
	var h2 := e.phase == 2
	var heads := e.parts
	var n := heads.size()
	match e.state:
		&"bite":
			var bites := 6 if h2 else 3
			if e.sub < bites and e.t <= 0:
				e.t = 0.4
				var order := [0, 4, 1, 3, 2, 0] if h2 else [0, 2, 1]
				var picks := [order[e.sub % order.size()]]
				if h2:
					picks.append(n - 1 - picks[0])
				for i in picks:
					var h: Dictionary = heads[mini(i, n - 1)]
					if h["st"] != "idle":
						continue
					h["st"] = "aim"
					h["t"] = 0.55
					h["a"] = TB.ang_xy(h["x"], h["y"], p.x, p.y)
					h["len"] = minf(Afx.reach(h["x"], h["y"], h["a"], 180.0, World.M_FLYER), 180.0)
					h["d"] = 0.0
					h["ox"] = h["x"]
					h["oy"] = h["y"]
				e.sub += 1
			elif e.sub >= bites and _heads_idle(e):
				_done(e)
		&"breath":
			if e.sub == 0:
				e.sub = 1
				var who := [1, 3] if h2 else [n / 2]
				for j in who.size():
					var h: Dictionary = heads[mini(who[j], n - 1)]
					var c := TB.ang_xy(h["x"], h["y"], p.x, p.y)
					var dir := 1.0 if j == 0 else -1.0
					h["st"] = "bwarn"
					h["t"] = 0.8
					h["a"] = c - 0.9 * dir
					h["a1"] = c + 0.9 * dir
					h["len"] = Afx.reach(h["x"], h["y"], c, 300.0, World.M_BULLET)
					h["puddle"] = 0.0
				Snd.play("charge")
			elif _heads_idle(e):
				_done(e)
		&"spit":
			var shots := 5 if h2 else 3
			if e.sub < shots and e.t <= 0:
				e.t = 0.3
				var h: Dictionary = heads[e.sub % n]
				var off := Vector2.ZERO if e.sub == 0 else Vector2(randf_range(-56.0, 56.0), randf_range(-40.0, 40.0))
				_lob(h["x"], h["y"], p.x + off.x, p.y + off.y, LOB_T, "sludge", e)
				e.sub += 1
				Snd.play("ebullet")
			elif e.sub >= shots and e.t <= -1.0:
				_done(e)
		&"flood":
			if e.sub == 0:
				e.sub = 1
				var rows := [p.y]
				var extra := 2 if h2 else 1
				for i in extra:
					var y := randf_range(4.0 * TB.TS, 16.0 * TB.TS)
					for tries in 6:
						var ok := true
						for r in rows:
							if absf(y - r) < 40:
								ok = false
						if ok:
							break
						y = randf_range(4.0 * TB.TS, 16.0 * TB.TS)
					rows.append(y)
				for i in rows.size():
					var dir := 1 if i % 2 == 0 else -1
					G.room.tides.append({ "y": clampf(rows[i], 4.0 * TB.TS, 16.0 * TB.TS), "dir": dir, "t": RiftExtras.TIDE_WARN,
						"x": TB.TS - 10.0 if dir > 0 else TB.SW - TB.TS + 10.0, "hit": {}, "hit_p": false })
				G.add_shake(3)
				Snd.play("roar")
			if e.st > 2.8:
				_done(e)
	# The heads (also between attacks).
	for i in n:
		var h: Dictionary = heads[i]
		match h["st"]:
			"aim":
				h["t"] -= dt
				if h["t"] <= 0:
					h["st"] = "lunge"
					Snd.play("hatchet")
			"lunge":
				h["d"] = minf(h["len"], h["d"] + 380.0 * dt)
				h["x"] = h["ox"] + cos(h["a"]) * h["d"]
				h["y"] = h["oy"] + sin(h["a"]) * h["d"]
				if TB.dist_xy(h["x"], h["y"], p.x, p.y) < 9.0 + p.r:
					Combat.hurt_player(1, e.d["name"])
				if h["d"] >= h["len"]:
					h["st"] = "back"
					Afx.dust(h["x"], h["y"])
			"back":
				var rest := _head_rest(e, i, n)
				var dv := rest - Vector2(h["x"], h["y"])
				var step := 220.0 * dt
				if dv.length() <= step:
					h["st"] = "idle"
				else:
					h["x"] += dv.normalized().x * step
					h["y"] += dv.normalized().y * step
			"bwarn":
				h["t"] -= dt
				if h["t"] <= 0:
					h["st"] = "breath"
					h["t"] = 1.6
					Snd.play("beam")
			"breath":
				h["t"] -= dt
				var k := 1.0 - clampf(h["t"] / 1.6, 0.0, 1.0)
				var a: float = lerpf(h["a"], h["a1"], k)
				var ln := Afx.reach(h["x"], h["y"], a, 300.0, World.M_BULLET)
				var dx := cos(a)
				var dy := sin(a)
				var px: float = p.x - h["x"]
				var py: float = p.y - h["y"]
				var along := px * dx + py * dy
				if along > 0 and along < ln and absf(px * dy - py * dx) < 7.0 + p.r * 0.5:
					Combat.hurt_player(1, e.d["name"])
				h["puddle"] -= dt
				if h["puddle"] <= 0:
					h["puddle"] = 0.22
					var at := randf_range(40.0, maxf(41.0, ln - 6.0))
					EnemyAI2.add_goo("sludge", h["x"] + dx * at, h["y"] + dy * at, 11.0, 3.0)
				if h["t"] <= 0:
					h["st"] = "idle"

static func _heads_idle(e: Enemy) -> bool:
	for h in e.parts:
		if h["st"] != "idle":
			return false
	return true

# ---------- THE BELLRINGER ----------
static func _bell_out(e: Enemy) -> bool:
	return not e.parts.is_empty() and e.parts[0].get("out", false)

static func _ringer(e: Enemy, p: Player, dt: float) -> void:
	var h2 := e.phase == 2
	var bell: Dictionary = e.parts[0]
	match e.state:
		&"toll":
			var n := 3 if h2 else 2
			if e.t > 0:
				return
			if e.repeat == 1:   # the swing ends: the bell sounds
				e.repeat = 0
				waves.append({ "x": e.x, "y": e.y, "r": 8.0, "speed": 120.0, "max": 340.0, "w": 6.0, "hit": false, "by": e.d["name"] })
				Fx.float_text(e.x, e.y - 30, "DONG", "gold", true)
				G.add_shake(2)
				Snd.play("bell")
				e.sub += 1
				e.t = 0.15
			elif e.sub < n:
				e.repeat = 1   # the bell swings back and glows first
				bell["glow"] = 0.5
				e.t = 0.5
			elif e.t <= -0.8:
				_done(e)
		&"hymn":
			var phrases := 4 if h2 else 3
			if e.t > 0:
				return
			if e.sub >= phrases * 6:
				_done(e)
				return
			var k := e.sub % 6
			if k == 0:
				e.ca = TB.ang_to(e, p)
				e.t = 0.35   # a breath before the phrase (the circle under him shows it)
			else:
				notes.append({ "ox": e.x, "oy": e.y - 8.0, "a": e.ca + randf_range(-0.12, 0.12), "s": 0.0, "t": 0.0, "speed": 72.0,
					"amp": 12.0, "ph": k * 1.1, "x": e.x, "y": e.y - 8.0, "by": e.d["name"] })
				Snd.play("ebullet")
				e.t = 0.5 if k == 5 else 0.12
			e.sub += 1
		&"drop":
			if e.sub == 0:
				e.sub = 1
				bell["out"] = true
				_lob(e.x + 10.0 * e.face, e.y - 4.0, p.x, p.y, 0.9, "bell", e, 2 if h2 else 0)
				Snd.play("charge")
			elif not bell["out"]:
				_done(e)

# ---------- THE BRASS ORGAN ----------
static func pipe_pos(e: Enemy, i: int) -> Vector2:
	return Vector2(e.x + (PIPE_COL[i] - 20.0) * 2.0, e.y + e.r + 2.0)

static func _organ(e: Enemy, p: Player, dt: float) -> void:
	var h2 := e.phase == 2
	match e.state:
		&"toccata":
			var steps := 22
			if e.sub < steps and e.t <= 0:
				e.t = 0.1
				var i := e.sub if e.sub <= 10 else 21 - e.sub
				pipes.append({ "i": i, "t": 0.45, "warn": 0.45, "kind": "down", "owner": weakref(e) })
				if h2 and 10 - i != i:
					pipes.append({ "i": 10 - i, "t": 0.45, "warn": 0.45, "kind": "down", "owner": weakref(e) })
				e.sub += 1
			elif e.sub >= steps and e.t <= -0.9:
				_done(e)
		&"fugue":
			var count := 16 if h2 else 12
			if e.sub < count and e.t <= 0:
				e.t = 0.22 if h2 else 0.28
				pipes.append({ "i": FUGUE[e.sub % FUGUE.size()], "t": 0.4, "warn": 0.4, "kind": "aim", "owner": weakref(e) })
				e.sub += 1
			elif e.sub >= count and e.t <= -0.8:
				_done(e)
		&"chord":
			if e.sub == 0:
				e.sub = 1
				var half := 12.0 if h2 else 14.0
				var a := randf_range(3.0 * TB.TS, 12.0 * TB.TS)
				var b := randf_range(16.0 * TB.TS, 25.0 * TB.TS)
				chords.append({ "lanes": [a, b], "half": half, "warn": 1.0, "rows": 4 if h2 else 3, "gap": 0.0, "y": e.y + e.r + 6.0,
					"by": e.d["name"] })
				Snd.play("charge")
			elif chords.is_empty() and e.st > 1.2:
				_done(e, 0.5)
		&"choir":
			if e.sub == 0:
				e.sub = 1
				if G.enemies.size() < 6:
					for i in 2:
						var s := World.free_spot(G.room, p, 90, World.M_WALKER)
						Combat.spawn_enemy(CHOIR[i % CHOIR.size()], s.x, s.y)
				Fx.burst(e.x, e.y, ["#f2c94c", "#f4ecd8"], 16, 80)
				Snd.play("bell")
			if e.st > 0.8:
				_done(e)
		&"pedal":
			if e.sub < 3 and e.t <= 0:
				e.t = 0.9
				sweeps.append({ "y": e.y + e.r + 8.0, "gap": randf_range(4.0 * TB.TS, 24.0 * TB.TS), "half": 22.0, "warn": 0.6,
					"hit": false, "by": e.d["name"] })
				Snd.play("boom")
				G.add_shake(3)
				e.sub += 1
			elif e.sub >= 3 and e.t <= -1.4:
				_done(e)

## Parts that move on their own: the hydra's idle heads find their places; the bell's glow fades.
static func _idle_parts(e: Enemy, k: String, dt: float) -> void:
	if k == "bellringer":
		e.parts[0]["glow"] = maxf(0.0, e.parts[0]["glow"] - dt)
	if k != "bilgehydra":
		return
	var n := e.parts.size()
	for i in n:
		var h: Dictionary = e.parts[i]
		if h["st"] == "idle" or h["st"] == "bwarn" or h["st"] == "breath":
			var rest := _head_rest(e, i, n)
			if h["st"] == "idle":
				h["x"] = lerpf(h["x"], rest.x, minf(1.0, dt * 8.0))
				h["y"] = lerpf(h["y"], rest.y, minf(1.0, dt * 8.0))

# ---------- The things of the fights (every tick, from Hazards.update) ----------
static func tick(room: Room, dt: float) -> void:
	if _room == null or _room.get_ref() != room:
		clear()
		_room = weakref(room)
	if _quiet():
		return
	var p := G.player
	_tick_held(p, dt)
	_tick_rods_arcs(p, dt)
	_tick_bands(p, dt)
	_tick_rings(dt)
	_tick_orbs(p, dt)
	_tick_twisters(room, p, dt)
	_tick_lobs(p, dt)
	_tick_waves(p, dt)
	_tick_notes(room, p, dt)
	_tick_pipes(p, dt)
	_tick_chords(dt)
	_tick_sweeps(p, dt)

static func _tick_held(p: Player, dt: float) -> void:
	var keep := []
	for q in held:
		if q["fly"] > 0:
			q["fly"] -= dt
			q["x"] += q["vx"] * dt
			q["y"] += q["vy"] * dt
		else:
			q["hold"] -= dt
			if q["hold"] <= 0:
				# They turn on you all at once.
				Combat.eshot(q["x"], q["y"], TB.ang_xy(q["x"], q["y"], p.x, p.y), 190, "cyan", 2.5)
				continue
		if World.solid(G.room, floori(q["x"] / TB.TS), floori(q["y"] / TB.TS), World.M_BULLET):
			continue
		if TB.dist_xy(q["x"], q["y"], p.x, p.y) < 3.0 + p.r:
			Combat.hurt_player(1, q["by"])
			continue
		keep.append(q)
	held = keep

static func _tick_rods_arcs(p: Player, dt: float) -> void:
	var keep := []
	for r in rods:
		r["fall"] -= dt
		r["life"] -= dt
		if r["life"] > 0:
			keep.append(r)
	rods = keep
	var keep2 := []
	for a in arcs:
		if a.has("follow"):
			var f: Enemy = a["follow"].get_ref()
			if f == null or f.hp <= 0:
				continue
			a["b"] = Vector2(f.x, f.y - 4)
		if a.has("oa"):
			a["a"] = Vector2(a["oa"]["x"], a["oa"]["y"])
			a["b"] = Vector2(a["ob"]["x"], a["ob"]["y"])
		if a["warn"] > 0:
			a["warn"] -= dt
			if a["warn"] <= 0:
				Snd.play("bolt")
			keep2.append(a)
			continue
		a["fire"] -= dt
		if a["fire"] <= 0:
			continue
		if _near_seg(p.x, p.y, a["a"], a["b"], 4.0 + p.r * 0.6):
			Combat.hurt_player(1, a["by"])
		keep2.append(a)
	arcs = keep2

static func _near_seg(px: float, py: float, a: Vector2, b: Vector2, w: float) -> bool:
	var ab := b - a
	var l2 := ab.length_squared()
	var k := 0.0 if l2 < 0.01 else clampf(((px - a.x) * ab.x + (py - a.y) * ab.y) / l2, 0.0, 1.0)
	return Vector2(px, py).distance_to(a + ab * k) < w

static func _tick_bands(p: Player, dt: float) -> void:
	var keep := []
	for b in bands:
		if b["warn"] > 0:
			b["warn"] -= dt
			if b["warn"] <= 0:
				# The lance strikes: whoever stands in the band is hit; sparks fly off to the sides.
				if absf((p.y if b["horiz"] else p.x) - b["pos"]) < b["half"] + p.r * 0.5:
					Combat.hurt_player(1, b["by"])
				for j in 3:
					var along: float = (5.0 + j * 4.5) * TB.TS
					var x: float = along if b["horiz"] else b["pos"]
					var y: float = b["pos"] if b["horiz"] else along
					var side := PI / 2 if b["horiz"] else 0.0
					Combat.eshot(x, y, side, 85, "cyan")
					Combat.eshot(x, y, side + PI, 85, "cyan")
				G.add_shake(2)
				Snd.play("bolt")
			keep.append(b)
			continue
		b["fire"] -= dt
		if b["fire"] > 0:
			keep.append(b)
	bands = keep

static func _tick_rings(dt: float) -> void:
	var keep := []
	for r in rings:
		r["warn"] -= dt
		if r["warn"] > 0:
			keep.append(r)
			continue
		var n: int = r["n"]
		for i in n:
			var a: float = float(i) / n * TAU
			if absf(TB.wrap_ang(a - r["gap"])) < r["gw"]:
				continue
			var x: float = r["x"] + cos(a) * r["r"]
			var y: float = r["y"] + sin(a) * r["r"]
			if x < TB.TS + 4 or x > TB.SW - TB.TS - 4 or y < 2.0 * TB.TS + 4 or y > 17.0 * TB.TS - 4:
				continue
			if World.solid(G.room, floori(x / TB.TS), floori(y / TB.TS), World.M_BULLET):
				continue
			Combat.eshot(x, y, a + PI, 60, "cyan")
		Snd.play("ebullet")
	rings = keep

static func _tick_orbs(p: Player, dt: float) -> void:
	var keep := []
	for o in orbs:
		o["life"] -= dt
		o["grow"] -= dt
		if o["life"] <= 0:
			Combat.ering(o["x"], o["y"], 8, 60, randf() * TAU, "cyan")
			continue
		var a := TB.ang_xy(o["x"], o["y"], p.x, p.y)
		var to := _inside(Vector2(o["x"] + cos(a) * 24.0 * dt, o["y"] + sin(a) * 24.0 * dt))
		o["x"] = to.x
		o["y"] = to.y
		if o["grow"] <= 0 and TB.dist_xy(o["x"], o["y"], p.x, p.y) < 6.0 + p.r:
			Combat.hurt_player(1, o["by"])
		keep.append(o)
	orbs = keep
	# Every so often the orbs join up with arcs (shown first).
	if orbs.size() >= 2:
		var o0: Dictionary = orbs[0]
		o0["pulse"] -= dt
		if o0["pulse"] <= 0:
			o0["pulse"] = 1.1
			for i in orbs.size():
				var oa: Dictionary = orbs[i]
				var ob: Dictionary = orbs[(i + 1) % orbs.size()]
				if orbs.size() == 2 and i == 1:
					break
				arcs.append({ "a": Vector2(oa["x"], oa["y"]), "b": Vector2(ob["x"], ob["y"]), "oa": oa, "ob": ob, "warn": 0.5,
					"w": 0.5, "fire": 0.2, "by": oa["by"] })

static func _tick_twisters(room: Room, p: Player, dt: float) -> void:
	var keep := []
	for w in twisters:
		w["life"] -= dt
		if w["life"] <= 0:
			Combat.ering(w["x"], w["y"], 10, 60, randf() * TAU, "ice")
			continue
		keep.append(w)
		if w["grow"] > 0:
			w["grow"] -= dt
			continue
		var a := TB.ang_xy(w["x"], w["y"], p.x, p.y)
		var to := _inside(Vector2(w["x"] + cos(a) * 44.0 * dt, w["y"] + sin(a) * 44.0 * dt))
		w["x"] = to.x
		w["y"] = to.y
		if TB.dist_xy(w["x"], w["y"], p.x, p.y) < 13.0 + p.r:
			Combat.hurt_player(1, w["by"])
		w["debris"] -= dt
		if w["debris"] <= 0:
			w["debris"] = 0.3
			Combat.eshot(w["x"], w["y"] - 6, randf() * TAU, 70, "ice")
	twisters = keep

static func _tick_lobs(p: Player, dt: float) -> void:
	var keep := []
	var landed := []
	for l in lobs:
		l["t"] += dt
		if l["t"] < l["dur"]:
			keep.append(l)
		else:
			landed.append(l)
	lobs = keep
	for l in landed:
		var x: float = l["x1"]
		var y: float = l["y1"]
		var owner: Enemy = l["owner"].get_ref()
		match l["kind"]:
			"sludge":
				if TB.dist_xy(x, y, p.x, p.y) < 14.0 + p.r:
					Combat.hurt_player(1, l["by"])
				EnemyAI2.add_goo("sludge", x, y, 16.0, 4.5)
				Combat.ering(x, y, 5, 50, randf() * TAU, "spore")
				Snd.play("hit")
			"bell":
				if TB.dist_xy(x, y, p.x, p.y) < 26.0 + p.r:
					Combat.hurt_player(1, l["by"])
				waves.append({ "x": x, "y": y, "r": 6.0, "speed": 130.0, "max": 90.0, "w": 6.0, "hit": false, "by": l["by"] })
				Combat.ering(x, y, 10, 70, randf() * TAU, "bone")
				Afx.dust(x, y)
				G.add_shake(4)
				Snd.play("bell")
				if owner == null or owner.hp <= 0:
					continue
				if l["hops"] > 0:
					_lob(x, y, p.x, p.y, 0.7, "bell", owner, l["hops"] - 1)
				else:
					_lob(x, y, owner.x + 10.0 * owner.face, owner.y - 4.0, 0.45, "home", owner)
			"home":
				if owner != null and not owner.parts.is_empty():
					owner.parts[0]["out"] = false
			"potato":   # Rex's potatoes
				if TB.dist_xy(x, y, p.x, p.y) < 12.0 + p.r:
					Combat.hurt_player(1, l["by"])
				Combat.ering(x, y, 5, 50, randf() * TAU, "bone")
				Fx.burst(x, y, ["#704f38", "#d48c84"], 8, 50)
				Snd.play("hit")

static func _tick_waves(p: Player, dt: float) -> void:
	var keep := []
	for w in waves:
		w["r"] += w["speed"] * dt
		if w["r"] > w["max"]:
			continue
		if not w["hit"] and absf(TB.dist_xy(w["x"], w["y"], p.x, p.y) - w["r"]) < w["w"] * 0.5 + p.r - 1.0:
			var before := p.invuln
			Combat.hurt_player(1, w["by"])
			w["hit"] = p.invuln > before
		keep.append(w)
	waves = keep

static func _tick_notes(room: Room, p: Player, dt: float) -> void:
	var keep := []
	for n in notes:
		n["s"] += n["speed"] * dt
		n["t"] += dt
		var dx := cos(n["a"])
		var dy := sin(n["a"])
		var wob: float = sin(n["t"] * 2.4 * TAU + n["ph"]) * n["amp"] * minf(1.0, n["s"] / 24.0)
		n["x"] = n["ox"] + dx * n["s"] - dy * wob
		n["y"] = n["oy"] + dy * n["s"] + dx * wob
		if n["t"] > 6.0 or World.solid(room, floori(n["x"] / TB.TS), floori(n["y"] / TB.TS), World.M_BULLET):
			continue
		if TB.dist_xy(n["x"], n["y"], p.x, p.y) < 3.0 + p.r:
			Combat.hurt_player(1, n["by"])
			continue
		keep.append(n)
	notes = keep

static func _tick_pipes(p: Player, dt: float) -> void:
	var keep := []
	for q in pipes:
		q["t"] -= dt
		if q["t"] > 0:
			keep.append(q)
			continue
		var e: Enemy = q["owner"].get_ref()
		if e == null or e.hp <= 0 or e.state == &"phase":
			continue
		var at := pipe_pos(e, q["i"])
		if q["kind"] == "down":
			Combat.eshot(at.x, at.y, PI / 2 - 0.08, 105, "fire")
			Combat.eshot(at.x, at.y, PI / 2 + 0.08, 105, "fire")
		else:
			Combat.efan(at.x, at.y, TB.ang_xy(at.x, at.y, p.x, p.y), 3, 0.22, 130 if e.phase == 2 else 115, "red")
		Snd.play("ebullet")
	pipes = keep

static func _tick_chords(dt: float) -> void:
	var keep := []
	for c in chords:
		if c["warn"] > 0:
			c["warn"] -= dt
			keep.append(c)
			continue
		c["gap"] -= dt
		if c["gap"] <= 0:
			c["gap"] = 0.35
			c["rows"] -= 1
			var x := 1.5 * TB.TS
			while x < TB.SW - 1.5 * TB.TS:
				var safe := false
				for l in c["lanes"]:
					if absf(x - l) < c["half"]:
						safe = true
				if not safe:
					Combat.eshot(x, c["y"], PI / 2, 120, "fire")
				x += 10.0
			Snd.play("ebullet")
			G.add_shake(1)
		if c["rows"] > 0:
			keep.append(c)
	chords = keep

static func _tick_sweeps(p: Player, dt: float) -> void:
	var keep := []
	for s in sweeps:
		if s["warn"] > 0:
			s["warn"] -= dt
			keep.append(s)
			continue
		s["y"] += 120.0 * dt
		if s["y"] > 17.0 * TB.TS:
			continue
		if not s["hit"] and absf(p.y - s["y"]) < 5.0 + p.r and absf(p.x - s["gap"]) > s["half"]:
			var before := p.invuln
			Combat.hurt_player(1, s["by"])
			s["hit"] = p.invuln > before
		keep.append(s)
	sweeps = keep

# ---------- Drawing ----------
## On the floor, under everyone: the warnings (world_view.gd, with the goo).
static func draw_ground(ci: CanvasItem, t: float) -> void:
	var blink := floori(t * 12) % 2 == 0
	for e in G.enemies:
		if not handles(e) or e.hp <= 0 or e.spawn_t > 0:
			continue
		var k := key(e)
		var col := TB.c(COL[k])
		if e.phase == 2 or e.state == &"phase":
			# A second phase shows: a ring of its colour under it that beats.
			var q := 0.5 + 0.5 * sin(t * 6.0)
			Afx.circle(ci, e.x, e.y + e.r * 0.7, e.r + 10.0 + q * 3.0, col, t, 0.5 + 0.4 * q)
		if e.state in [&"lances", &"vortex", &"downdraft", &"orbs", &"cyclone", &"hymn", &"rods", &"quills", &"flood", &"chord",
				&"toccata", &"fugue", &"pedal", &"choir"]:
			Afx.circle(ci, e.x, e.y + e.r * 0.6, e.r + 14.0, col, t, clampf(e.st * 4.0, 0.0, 1.0))
		match k:
			"rex":
				Rex.draw_ground(ci, e, t)
			"arci":
				Arci.draw_ground(ci, e, t)
			"sefe":
				Sefe.draw_ground(ci, e, t)
			"tidecaptain":
				if e.state == &"anchor" and e.sub == 1:
					Afx.lane(ci, e.x, e.y, e.ca, 5.0, e.aux2, e.st / 0.6, Afx.C_WARN, t)
				elif e.state == &"anchor" and e.sub == 3:
					Afx.lane(ci, e.x, e.y, TB.ang_xy(e.x, e.y, e.to.x, e.to.y), e.r, TB.dist_xy(e.x, e.y, e.to.x, e.to.y),
						e.st / 0.35, Afx.C_WARN, t)
				elif e.state == &"swing" and e.sub == 1:
					var radius := 58.0 if e.phase == 2 else 46.0
					Afx.landing(ci, e.x, e.y + 4, radius + 6.0, e.st / 0.7, Afx.C_WARN, t)
			"bilgehydra":
				for h in e.parts:
					if h["st"] == "aim":
						Afx.lane(ci, h["ox"], h["oy"], h["a"], 7.0, h["len"], 1.0 - h["t"] / 0.55, Afx.C_WARN, t)
					elif h["st"] == "bwarn":
						# The breath's sweep: its edges, and the line where it starts.
						var k2 := 1.0 - clampf(h["t"] / 0.8, 0.0, 1.0)
						for a in [h["a"], h["a1"]]:
							ci.draw_set_transform(Vector2(roundf(h["x"]), roundf(h["y"])), a, Vector2.ONE)
							ci.draw_rect(Rect2(10, -0.5, h["len"] - 10.0, 1.0), Color(col.r, col.g, col.b, 0.35))
							ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
						Afx.lane(ci, h["x"], h["y"], h["a"], 7.0, h["len"], k2, col, t)
	for b in bands:
		if b["warn"] <= 0:
			continue
		var rect := Rect2(TB.TS, b["pos"] - b["half"], TB.SW - 2 * TB.TS, b["half"] * 2) if b["horiz"] \
			else Rect2(b["pos"] - b["half"], 2 * TB.TS, b["half"] * 2, 15 * TB.TS)
		var k := 1.0 - clampf(b["warn"] / LANCE_WARN, 0.0, 1.0)
		ci.draw_rect(rect, Color(0.78, 0.94, 1.0, 0.1 + 0.18 * k))
		var edge := Color(0.43, 0.83, 0.88, 0.95 if blink else 0.55)
		if b["horiz"]:
			ci.draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 1), edge)
			ci.draw_rect(Rect2(rect.position.x, rect.end.y - 1, rect.size.x, 1), edge)
		else:
			ci.draw_rect(Rect2(rect.position.x, rect.position.y, 1, rect.size.y), edge)
			ci.draw_rect(Rect2(rect.end.x - 1, rect.position.y, 1, rect.size.y), edge)
			var y := 2.0 * TB.TS + fmod(t * 90.0, 24.0)
			while y < 17.0 * TB.TS - 4:
				for j in 3:
					ci.draw_rect(Rect2(b["pos"] - j - 1, y + j, 2, 1), edge)
					ci.draw_rect(Rect2(b["pos"] + j - 1, y + j, 2, 1), edge)
				y += 24.0
	for r in rings:
		var k := 1.0 - clampf(r["warn"] / RING_WARN, 0.0, 1.0)
		var c := Color(0.43, 0.83, 0.88, 0.5 + 0.4 * k)
		var segs := 48
		for i in segs:
			if i % 2 == 1:
				continue
			var a0 := float(i) / segs * TAU
			var a1 := float(i + 1) / segs * TAU
			var gap_here: bool = absf(TB.wrap_ang((a0 + a1) * 0.5 - r["gap"])) < r["gw"]
			ci.draw_line(Vector2(r["x"] + cos(a0) * r["r"], r["y"] + sin(a0) * r["r"]),
				Vector2(r["x"] + cos(a1) * r["r"], r["y"] + sin(a1) * r["r"]),
				TB.c("#f2c94c") if gap_here else c, 2.0 if gap_here else 1.0)
	for l in lobs:
		if l["kind"] == "home":
			continue
		var big: bool = l["kind"] == "bell"
		Afx.landing(ci, l["x1"], l["y1"], 26.0 if big else (12.0 if l["kind"] == "potato" else 14.0), l["t"] / l["dur"], Afx.C_WARN, t)
	for c in chords:
		if c["warn"] <= 0:
			continue
		# A chord: everything is about to be struck but the gold lanes.
		var k := 1.0 - clampf(c["warn"], 0.0, 1.0)
		ci.draw_rect(Rect2(TB.TS, c["y"], TB.SW - 2 * TB.TS, 17.0 * TB.TS - c["y"]), Color(0.85, 0.27, 0.24, 0.08 + 0.1 * k))
		for x in c["lanes"]:
			var lane := Rect2(x - c["half"], c["y"], c["half"] * 2, 17.0 * TB.TS - c["y"])
			ci.draw_rect(lane, Color(0.95, 0.79, 0.3, 0.22 + (0.12 if blink else 0.0)))
			ci.draw_rect(Rect2(lane.position.x, lane.position.y, 1, lane.size.y), TB.c("#f2c94c"))
			ci.draw_rect(Rect2(lane.end.x - 1, lane.position.y, 1, lane.size.y), TB.c("#f2c94c"))
	for s in sweeps:
		var c2 := Color(0.91, 0.53, 0.23, 0.9 if s["warn"] <= 0 or blink else 0.4)
		var y: float = s["y"]
		var g0: float = s["gap"] - s["half"]
		var g1: float = s["gap"] + s["half"]
		ci.draw_rect(Rect2(TB.TS, y - 2, g0 - TB.TS, 4), c2)
		ci.draw_rect(Rect2(g1, y - 2, TB.SW - TB.TS - g1, 4), c2)
		ci.draw_rect(Rect2(g0, y - 1, g1 - g0, 2), Color(0.95, 0.79, 0.3, 0.35))

## Over everyone: quills, rods, arcs, lance strikes, orbs, cyclones, tolls, notes, things in the air,
## the breath (world_view.gd, with the telegraphs).
static func draw_over(ci: CanvasItem, t: float) -> void:
	if _quiet() and not _any_breath():
		return
	var blink := floori(t * 16) % 2 == 0
	var p := G.player
	for q in held:
		var a := TB.ang_xy(q["x"], q["y"], p.x, p.y) if q["fly"] <= 0 else atan2(q["vy"], q["vx"])
		var white: bool = q["fly"] <= 0 and (blink or q["hold"] < 0.2)
		_feather(ci, q["x"], q["y"], a, white)
		if q["fly"] <= 0 and q["hold"] < 0.25:
			ci.draw_line(Vector2(q["x"], q["y"]), Vector2(p.x, p.y), Color(0.78, 0.94, 1.0, 0.25), 1.0)
	for r in rods:
		var k := 1.0 - clampf(r["fall"] / ROD_FALL, 0.0, 1.0)
		var x: float = lerpf(r["fx"], r["x"], k)
		var y: float = lerpf(r["fy"], r["y"], k) - sin(k * PI) * 18.0
		ci.draw_rect(Rect2(roundf(x) - 1, roundf(y) - 10, 2, 10), TB.c("#2b4f8a"))
		ci.draw_rect(Rect2(roundf(x) - 1, roundf(y) - 12, 2, 2), TB.c("#f2c94c" if blink else "#f4ecd8"))
	for a in arcs:
		var a0: Vector2 = a["a"]
		var a1: Vector2 = a["b"]
		if a["warn"] > 0:
			var k := 1.0 - clampf(a["warn"] / a["w"], 0.0, 1.0)
			if blink or k > 0.7:
				ci.draw_line(a0, a1, Color(0.78, 0.94, 1.0, 0.25 + 0.55 * k), 1.0 + k)
		else:
			_bolt(ci, a0, a1, t)
	for b in bands:
		if b["warn"] > 0:
			continue
		var rect := Rect2(TB.TS, b["pos"] - 4, TB.SW - 2 * TB.TS, 8) if b["horiz"] else Rect2(b["pos"] - 4, 2 * TB.TS, 8, 15 * TB.TS)
		ci.draw_rect(rect, Color(0.78, 0.94, 1.0, 0.85))
		ci.draw_rect(rect.grow(-2), Color(1, 1, 1, 1))
	for o in orbs:
		var g := clampf(1.0 - o["grow"] / 0.4, 0.2, 1.0)
		ci.draw_circle(Vector2(o["x"], o["y"]), 7.0 * g, Color(0.43, 0.83, 0.88, 0.4))
		ci.draw_circle(Vector2(o["x"], o["y"]), 4.0 * g, TB.c("#c8f0ff"))
		ci.draw_circle(Vector2(o["x"], o["y"]), 2.0 * g, Color(1, 1, 1, 1))
	for w in twisters:
		var g := clampf(1.0 - w["grow"] / 0.7, 0.15, 1.0)
		for j in 5:
			var rr := (4.0 + j * 2.6) * g
			var yy: float = w["y"] - j * 5.0 * g
			var a := t * 9.0 + j
			ci.draw_arc(Vector2(w["x"] + sin(a) * 2.0, yy), rr, a, a + 4.2, 10, Color(0.78, 0.94, 1.0, 0.85), 1.0)
		if w["grow"] > 0:
			Afx.landing(ci, w["x"], w["y"], 14.0, 1.0 - w["grow"] / 0.7, Afx.C_WARN, t)
	for w in waves:
		var fade: float = 1.0 - w["r"] / w["max"] * 0.6
		ci.draw_arc(Vector2(w["x"], w["y"]), w["r"], 0, TAU, 40, Color(0.95, 0.79, 0.3, fade), w["w"] * 0.6)
		ci.draw_arc(Vector2(w["x"], w["y"]), maxf(1.0, w["r"] - 3.0), 0, TAU, 40, Color(1, 1, 1, 0.5 * fade), 1.0)
	for n in notes:
		_note(ci, n["x"], n["y"])
	for l in lobs:
		var k: float = clampf(l["t"] / l["dur"], 0.0, 1.0)
		var x: float = lerpf(l["x0"], l["x1"], k)
		var y: float = lerpf(l["y0"], l["y1"], k) - sin(k * PI) * (40.0 if l["kind"] == "bell" else 28.0)
		match l["kind"]:
			"bell", "home":
				Gfx.sp(ci, "rb_bell", x, y + 6, 2.0, 2.0)
			"potato":
				Gfx.sp(ci, "rex_potato", x, y + 4, 1.5, 1.5, l["t"] * 10.0)
			_:
				ci.draw_circle(Vector2(x, y), 5.0, TB.c("#140f1c"))
				ci.draw_circle(Vector2(x, y), 4.0, TB.c("#63b84f"))
				ci.draw_rect(Rect2(roundf(x) - 2, roundf(y) - 2, 2, 2), TB.c("#b8e05a"))
	for e in G.enemies:
		if e.type == "boss" and e.boss == "bilgehydra":
			for h in e.parts:
				if h["st"] == "breath":
					var k := 1.0 - clampf(h["t"] / 1.6, 0.0, 1.0)
					var a: float = lerpf(h["a"], h["a1"], k)
					var ln := Afx.reach(h["x"], h["y"], a, 300.0, World.M_BULLET)
					ci.draw_set_transform(Vector2(roundf(h["x"]), roundf(h["y"])), a, Vector2.ONE)
					ci.draw_rect(Rect2(6, -7, ln - 6, 14), Color(0.39, 0.72, 0.31, 0.55))
					ci.draw_rect(Rect2(6, -4, ln - 6, 8), Color(0.72, 0.88, 0.35, 0.85))
					ci.draw_rect(Rect2(6, -1, ln - 6, 2), Color(0.95, 1.0, 0.8, 0.9))
					ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for s in sweeps:
		if s["warn"] > 0:
			continue
		for j in 3:
			var x := fmod(t * 140.0 + j * 37.0, TB.SW - 2 * TB.TS) + TB.TS
			if absf(x - s["gap"]) > s["half"]:
				ci.draw_rect(Rect2(roundf(x), s["y"] - 4, 2, 2), Color(1, 1, 1, 0.8))

static func _any_breath() -> bool:
	if G.boss == null or G.boss.boss != "bilgehydra":
		return false
	for h in G.boss.parts:
		if h["st"] == "breath":
			return true
	return false

static func _feather(ci: CanvasItem, x: float, y: float, a: float, white: bool) -> void:
	var col := TB.c("#ffffff" if white else "#9fc3ee")
	var dx := cos(a)
	var dy := sin(a)
	for j in 4:
		ci.draw_rect(Rect2(roundf(x + dx * (j - 2) * 1.5) - 1, roundf(y + dy * (j - 2) * 1.5) - 1, 2, 2),
			col if j > 0 else TB.c("#2b4f8a"))

static func _note(ci: CanvasItem, x: float, y: float) -> void:
	var rx := roundf(x)
	var ry := roundf(y)
	ci.draw_rect(Rect2(rx - 3, ry, 4, 3), TB.c("#140f1c"))
	ci.draw_rect(Rect2(rx - 2, ry + 1, 3, 1), TB.c("#f2c94c"))
	ci.draw_rect(Rect2(rx, ry - 6, 1, 7), TB.c("#f2c94c"))
	ci.draw_rect(Rect2(rx + 1, ry - 6, 2, 1), TB.c("#f2c94c"))

## A lightning bolt between two points: jagged, white at the core.
static func _bolt(ci: CanvasItem, a: Vector2, b: Vector2, t: float) -> void:
	var n := maxi(2, int(a.distance_to(b) / 10.0))
	var perp := (b - a).normalized().orthogonal()
	var prev := a
	for i in range(1, n + 1):
		var k := float(i) / n
		var j := 0.0 if i == n else sin(t * 40.0 + i * 2.3) * 4.0
		var pt := a.lerp(b, k) + perp * j
		ci.draw_line(prev, pt, Color(0.43, 0.83, 0.88, 0.9), 3.0)
		ci.draw_line(prev, pt, Color(1, 1, 1, 1), 1.0)
		prev = pt

## The pieces a boss carries, drawn with it (world_view.gd _draw_enemy): the anchor, the bell, the
## hydra's necks and heads, the organ's lit pipes.
static func draw_parts(ci: CanvasItem, e: Enemy, foot: float, t: float) -> void:
	if e.parts.is_empty():
		return
	match key(e):
		"rex":
			Rex.draw_parts(ci, e, foot, t)
		"arci":
			Arci.draw_parts(ci, e, foot, t)
		"sefe":
			Sefe.draw_parts(ci, e, foot, t)
		"tidecaptain":
			if e.parts[0]["out"]:
				var hand := Vector2(e.x + 6 * e.face, e.y + 2)
				var n := maxi(2, int(hand.distance_to(e.to) / 5.0))
				for i in n:
					var q := hand.lerp(e.to, float(i) / n)
					ci.draw_rect(Rect2(roundf(q.x) - 1, roundf(q.y) - 1, 2, 2), TB.c("#8b8f9c" if i % 2 == 0 else "#4e4a5e"))
				Gfx.sp(ci, "rb_anchor", e.to.x, e.to.y + 8, 2.0, 2.0)
			else:
				Gfx.sp(ci, "rb_anchor", e.x + 13 * e.face, foot - 2, 1.4, 1.4)
		"bellringer":
			var bell: Dictionary = e.parts[0]
			if not bell["out"]:
				var glow: float = bell["glow"]
				var tint := Color(1, 1, 1, 0.8) if glow > 0 and floori(t * 16) % 2 == 0 else Color(0, 0, 0, 0)
				Gfx.sp(ci, "rb_bell", e.x + 14 * e.face, foot - 6, 1.6, 1.6, sin(t * 20.0) * 0.4 if glow > 0 else 0.0,
					false, 1.0, tint)
		"bilgehydra":
			var n := e.parts.size()
			for i in n:
				var h: Dictionary = e.parts[i]
				var g: float = h["grow"]
				if g <= 0.02:
					continue
				var base := Vector2(e.x + (i - (n - 1) / 2.0) * 7.0, e.y + 6.0)
				var head := Vector2(h["x"], h["y"]).lerp(base, 1.0 - g)
				var segs := 6
				for s in segs:
					var k := float(s) / segs
					var q := base.lerp(head, k) + Vector2(0, sin(k * PI) * 6.0)
					Gfx.sp(ci, "hydraneck", q.x, q.y + 6, 2.0 * g, 2.0 * g)
				var lunging: bool = h["st"] == "lunge" or h["st"] == "aim"
				var tint := Color(1, 1, 1, 1) if lunging and h["st"] == "aim" and floori(t * 16) % 2 == 0 else Color(0, 0, 0, 0)
				Gfx.sp(ci, "hydrahead", head.x, head.y + 10, 2.0 * g, 2.0 * g, 0.0, head.x < e.x, 1.0, tint)
		"brassorgan":
			var lit := {}
			for q in pipes:
				if q["owner"].get_ref() == e:
					lit[q["i"]] = maxf(lit.get(q["i"], 0.0), 1.0 - q["t"] / q["warn"])
			var all := 0.0
			for c in chords:
				if c["warn"] > 0:
					all = 1.0 - clampf(c["warn"], 0.0, 1.0)
			var top := foot - 56.0
			for i in PIPE_COL.size():
				var k: float = maxf(lit.get(i, 0.0), all)
				if k <= 0:
					continue
				var x: float = e.x + (PIPE_COL[i] - 20.0) * 2.0
				var y0: float = top + PIPE_ROW[i] * 2.0
				ci.draw_rect(Rect2(roundf(x) - 3, y0, 6, 16), Color(1.0, 0.85, 0.4, 0.35 + 0.55 * k))
				if k > 0.6 and floori(t * 16) % 2 == 0:
					ci.draw_rect(Rect2(roundf(x) - 2, y0 - 3, 4, 3), Color(1, 1, 1, 0.9))
