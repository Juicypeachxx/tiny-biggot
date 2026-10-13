class_name Charged
extends RefCounted
## ROADMAP 4.6 part 2, CHARGE AND COMBO: weapons you hold to charge, and weapons that work in two
## stages or in turns (ideas from Dead Cells, Risk of Rain, Aion's chain skills, Worms, GTA V and
## Saints Row: The Third; ideas only, every name, picture and number is this game's own).
##
## Held to charge (`hold`, called by Combat._update_player_base instead of the usual cooldown):
##   charge    a shot that grows: bigger, faster, harder; a full charge pierces everything
##   slam      a shockwave ring that rolls out along the floor; a full charge stuns
##   dash      a dash through foes, cutting each one; nothing touches you mid-dash
## The charge fills in 1/rate seconds while there is something to aim at. While an aim button is
## held it waits at full until you let go; aimed for you (AUTO-AIM FIRE), it lets go at full.
## In two stages, or in turns (Combat.player_shoot):
##   javelin   thrown, it pins a foe or a wall; the next attack dashes you to it
##   hook      pulls a foe to you, and the next attack is a punch that stuns (big foes pull you)
##   combo     three different attacks in turn (the row's "steps")
##   heat      fires fast and heats up; at full heat it vents a blast and cools
##   reload    a magazine of shots, then a reload (what the reload does is the weapon's own)
##   orbit     each attack adds a star circling you; at the last one they all fly at foes
##   recall    a disc flies out and spins in place; the next attack calls it back through foes
## What a weapon of those kinds does differently comes from keys on its row (TWISTS).
##
## +1 PROJECTILE STACKS WITHOUT LIMIT. A charged shot, a slam, a dash, a javelin, a punch, a combo
## step and the disc are one thing each: every projectile past the first adds 35% damage (a ball, a
## ring and a disc also grow a little, up to twice as big). A choke shotgun adds pellets up to 14 and
## a star gatherer stars up to 12, then they merge the same way. Heat and magazine guns fire through
## the usual shot path (Combat.fire_projectiles), so their shots are capped and merged there.
##
## The things in flight live here (not in the player's shot list), and their hits go through
## Combat.damage_enemy and on_hit_effects, so crits, ailments and every on-hit effect work with them.
## Emptied when the room changes, except what belongs to the weapon in hand (stars, heat, magazine).

const KINDS := ["charge", "slam", "dash", "javelin", "hook", "combo", "heat", "reload", "orbit", "recall"]
const HELD := ["charge", "slam", "dash"]
## Keys a weapon row may carry to change what its kind does (the uniqueness report counts them).
const TWISTS := ["shatter", "pull", "roll_draw", "tighten", "aura", "fire_ring", "aftershocks", "dash_blast", "phantom",
	"rod", "drag", "steps", "linked", "heat_dmg", "last_crit", "kill_reload", "throw_mag"]
const MAX_BALLS := 24
const MAX_RINGS := 12
const MAX_STARS := 12
const DASH_SPEED := 520.0
const VENT := 1.3                 # seconds an overheated gun cools before it fires again

static var level := 0.0           # the charge being held, 0..1
static var shot_lv := 0.0         # the charge of the shot being fired (kept for echoes and volleys)
static var _was_held := false
static var _last_manual := 0.0
static var balls: Array = []      # charged shots: { x, y, a, spd, r, dmg, life, t, lv, pierce, hit, crit, w, col, arrow }
static var rings: Array = []      # shockwaves: { x, y, r, max, spd, dmg, hit, stun, crit, w, col, fire, delay }
static var dashing := {}          # the dash under way: { hit, dmg, crit, w, x0, y0, col, jav, lv }
static var phantoms: Array = []   # phantom dashes to come: { x0, y0, x1, y1, t, dmg }
static var jav := {}              # the javelin: { x, y, a, spd, life, t, state, dmg, crit, w, e, ox, oy, zap }
static var hook := {}             # the hook: { x, y, a, spd, life, t, state, dmg, w, e, hit, stuck }
static var punch_t := 0.0         # a foe was pulled in: the next attack is the punch
static var step := 0              # combo: the next step
static var step_t := 9.0          # combo: time since the last step (a pause starts the chain over)
static var marked := {}           # combo: foes this chain's cuts hit (the finisher crits them)
static var heat := 0.0
static var vent_t := 0.0
static var cool_t := 0.0
static var mag := -1
static var reload_t := 0.0
static var reload_max := 1.0
static var stars: Array = []      # orbit: { hit: { uid: seconds before it can hurt that foe again } }
static var spin := 0.0            # orbit: the ring of stars turning
static var disc := {}             # recall: { x, y, vx, vy, t, life, state, dmg, r, hit, w, col, crit, spin_t }
static var flashes: Array = []    # tracers, streaks, zaps: { k, x0, y0, x1, y1, t, max, col }
static var _room: WeakRef = null
static var _wid := ""
static var stats := {}            # how often each trick happened (tests/arsenal_test reads it)

static func _stat(k: String, n: int = 1) -> void:
	stats[k] = stats.get(k, 0) + n

static func handles(kind: String) -> bool:
	return kind in KINDS

## Held to charge: Combat._update_player_base calls hold() for these instead of the usual cooldown.
static func holds(p: Player) -> bool:
	return p.weapon["kind"] in HELD

## The room changed: what was in flight is gone (the weapon's own state stays).
static func clear() -> void:
	balls.clear()
	rings.clear()
	dashing = {}
	phantoms.clear()
	jav = {}
	hook = {}
	punch_t = 0.0
	disc = {}
	flashes.clear()

## Another weapon in hand: its charge, stars, heat and magazine start fresh.
static func _reset_weapon() -> void:
	level = 0.0
	shot_lv = 0.0
	heat = 0.0
	vent_t = 0.0
	mag = -1
	reload_t = 0.0
	stars.clear()
	step = 0
	marked.clear()
	jav = {}
	hook = {}
	disc = {}
	punch_t = 0.0

static func _col(w: Dictionary) -> String:
	return Weapons.TAG_COLS[w["tags"][0] if w["tags"].size() > 0 else "core"][0]

# ---------- Holding a charge ----------
static func hold(p: Player, aim: Variant, rate: float, dt: float) -> void:
	var w: Dictionary = p.weapon
	var manual = Keys.aim()
	var held := manual != null or Keys.fire_held()
	if manual != null:
		_last_manual = manual
	var ready := aim != null and p.fire_cd <= 0 and p.dodge_t <= 0 and p.dash_t <= 0 and (G.enemies_active() or G.dummies_present())
	if ready:
		var before := level
		level = minf(1.0, level + dt * rate)
		if before < 1.0 and level >= 1.0:
			_stat("full")
			Snd.play("select")
			Fx.burst(p.x, p.y - 4, [_col(w), "#ffffff"], 6, 40, 0.2)
		if w.get("aura", 0.0) > 0:
			# The cold star: foes near you are chilled while you charge.
			for e in G.enemies:
				if e.targetable() and TB.dist(p, e) < w["aura"]:
					e.chill_t = maxf(e.chill_t, 0.4)
					_stat("aura_chill")
	var go := level > 0 and ((level >= 1.0 and not held and aim != null) or (_was_held and not held and level >= 0.1))
	var let_go := _was_held and not held
	_was_held = held
	if go:
		shot_lv = level
		level = 0.0
		p.fire_cd = 0.12   # a breath before the next charge
		var a: float = _last_manual if let_go else (aim if aim != null else p.aim_a)
		p.aim_a = a
		Combat.player_shoot(p, a)
		if p.triple > 0 and randf() < p.triple:
			p.volleys.append({ "t": 0.07 })
			p.volleys.append({ "t": 0.14 })
	elif aim == null and not held:
		level = maxf(0.0, level - dt * 0.5)   # nothing to shoot at: the charge fades slowly

# ---------- Firing (Combat.player_shoot) ----------
## Returns the player shots made (heat and magazine guns, the choke, launched stars), like
## Combat.fire_projectiles, so crits forced by an ambush and every per-shot rule reach them.
static func fire(p: Player, a: float, forced: bool) -> Array:
	var w: Dictionary = p.weapon
	var n := Weapons.wcount(p)
	var more := 1.0 + 0.35 * (n - 1)
	var grow := minf(2.0, 1.0 + 0.06 * sqrt(float(n - 1)))
	match w["kind"]:
		"charge":
			return _charge_shot(p, a, w, n, more, grow, forced)
		"slam":
			_slam(p, a, w, more, grow, forced)
		"dash":
			if dashing.is_empty():
				var lv := maxf(shot_lv, 0.25)
				var reach := Weapons.wrange(p) * (0.35 + 0.65 * lv)
				var dmg := Weapons.wdmg(p) * (0.6 + 1.4 * lv) * more
				if _only_dummies():
					_line(p, a, reach, 16.0, dmg, forced, w)   # training dummies: the cut, without the dash
				else:
					_start_dash(p, a, reach, dmg, forced, w)
					_stat("dash")
		"javelin":
			_javelin(p, a, w, more, forced)
		"hook":
			_hook_fire(p, a, w, more, forced)
		"combo":
			_combo(p, a, w, more, forced)
		"heat":
			return _heat(p, a, w)
		"reload":
			return _reload_fire(p, a, w, more)
		"orbit":
			return _orbit(p, a, w, n)
		"recall":
			_recall_fire(p, a, w, more, grow, forced)
	return []

static func _charge_shot(p: Player, a: float, w: Dictionary, n: int, more: float, grow: float, forced: bool) -> Array:
	var lv := maxf(shot_lv, 0.25)
	var full := lv >= 1.0
	if w.get("tighten", 0) > 0:
		# The choke: the charge closes the spread. +1 projectile adds pellets up to 14, then merges.
		var want := int(w["tighten"]) + n - 1
		var pellets := mini(want, 14)
		var per := Weapons.wdmg(p) * (0.6 + 0.9 * lv) * (1.0 + 0.35 * maxi(0, want - 14))
		var arc := lerpf(1.0, 0.07, lv)
		var made := []
		for i in pellets:
			var off := (float(i) / maxf(1.0, pellets - 1) - 0.5) * arc
			made.append(Combat.spawn_pbullet(p, a + off + randf_range(-0.02, 0.02), per, "clod", 0.85 + 0.5 * lv))
		_stat("choke_full" if full else "choke")
		Snd.play("shoot")
		G.add_shake(1 + 2 * lv)
		return made
	var bow: bool = w.get("roll_draw", false)
	var o := { "x": p.x + cos(a) * 8, "y": p.y - 3 + sin(a) * 8, "px": p.x, "py": p.y - 3, "a": a, "spd": Weapons.wspd(p) * (0.7 + 0.5 * lv),
		"r": (2.0 if bow else 2.5 + 4.0 * lv) * Weapons.wsize(p) * grow, "dmg": Weapons.wdmg(p) * (0.4 + 2.6 * lv) * more,
		"life": Weapons.wlife(p), "t": 0.0, "lv": lv, "pierce": 99 if full or w.get("pull", 0.0) > 0 else Weapons.wpierce(p),
		"hit": {}, "crit": forced or (full and bow), "w": w["id"], "col": _col(w), "arrow": bow }
	if balls.size() >= MAX_BALLS:
		balls[balls.size() - 1]["dmg"] += o["dmg"]   # past the cap: folded into the newest one
	else:
		balls.append(o)
	_stat("full_shot" if full else "ball")
	if full:
		G.add_shake(2)
	Snd.play("bolt" if bow else "charge")
	return []

static func _slam(p: Player, a: float, w: Dictionary, more: float, grow: float, forced: bool) -> void:
	var lv := maxf(shot_lv, 0.25)
	var x := p.x + cos(a) * 8
	var y := p.y + 2 + sin(a) * 6
	var reach := minf(Weapons.wrange(p) * (0.5 + 0.5 * lv) * grow * sqrt(Weapons.wsize(p)), 160.0)
	var dmg := Weapons.wdmg(p) * (0.5 + 1.5 * lv) * more
	var spd := maxf(Weapons.wspd(p), 120.0)
	_ring(x, y, reach, spd, dmg, lv >= 1.0, forced, w, 0.0)
	for i in int(w.get("aftershocks", 0)):
		_ring(x, y, reach * 0.65, spd, dmg * 0.5, false, false, w, 0.35 * (i + 1))
	G.add_shake(2 + 4 * lv)
	Afx.dust(x, y)
	Fx.burst(x, y, ["#8b8f9c", "#c9c2a8", _col(w)], 10 + roundi(10 * lv), 80, 0.35)
	Snd.play("boom")
	_stat("slam")

static func _ring(x: float, y: float, reach: float, spd: float, dmg: float, stun: bool, crit: bool, w: Dictionary, delay: float) -> void:
	if rings.size() >= MAX_RINGS:
		rings[rings.size() - 1]["dmg"] += dmg
		return
	rings.append({ "x": x, "y": y, "r": 2.0, "max": reach, "spd": spd, "dmg": dmg, "hit": {}, "stun": stun, "crit": crit,
		"w": w["id"], "col": _col(w), "fire": w.get("fire_ring", false), "delay": delay })

## A dash along `a`: the hero's own dash (Player.dash_t), the cuts made here. A dash of no damage
## (the grapple pulling you to a big foe) cuts nothing.
static func _start_dash(p: Player, a: float, dist: float, dmg: float, crit: bool, w: Dictionary, to_jav := false) -> void:
	p.dash_dir = Vector2.from_angle(a)
	p.dash_speed = DASH_SPEED
	p.dash_t = maxf(TB.DT, dist / DASH_SPEED)
	p.dash_dmg = 0.0   # Abilities.while_dashing tramples nothing: the cuts are made in _tick_dash
	p.dash_end = []
	p.dash_hit = {}
	p.leap_max = 0.0
	p.air = 0.0
	p.dodge_t = 0.0
	p.invuln = maxf(p.invuln, p.dash_t + 0.35)   # and a moment after: it may end beside a foe
	if absf(cos(a)) > 0.1:
		p.face = 1 if cos(a) > 0 else -1
	dashing = { "hit": {}, "dmg": dmg, "crit": crit, "w": w["id"], "x0": p.x, "y0": p.y, "col": _col(w), "jav": to_jav,
		"lv": maxf(shot_lv, 0.25) }
	Snd.play("dodge")

static func _javelin(p: Player, a: float, w: Dictionary, more: float, forced: bool) -> void:
	if jav.is_empty():
		jav = { "x": p.x + cos(a) * 6, "y": p.y - 3 + sin(a) * 6, "px": p.x, "py": p.y - 3, "a": a, "spd": Weapons.wspd(p), "life": Weapons.wlife(p),
			"t": 0.0, "state": "fly", "dmg": Weapons.wdmg(p) * more, "crit": forced, "w": w["id"], "zap": 0.0 }
		_stat("throw")
		Snd.play("hatchet")
		return
	if jav["state"] != "foe" or not dashing.is_empty():
		return   # in the air, or coming back
	var d := TB.dist_xy(p.x, p.y, jav["x"], jav["y"])
	if _only_dummies() or d > 200.0:
		# Training dummies (or a foe too far away): torn out, it comes back; the hero stays put.
		_pick_up(p, false)
		return
	# The second stage: a dash to the foe it pins, cutting everything on the way.
	_start_dash(p, TB.ang_xy(p.x, p.y, jav["x"], jav["y"]), maxf(4.0, d - 6.0), Weapons.wdmg(p) * more, forced, w, true)
	_stat("follow")

## Only training dummies in the room (the start room): a weapon never moves the hero there.
static func _only_dummies() -> bool:
	return G.dummies_present() and not G.enemies_active()

static func _hook_fire(p: Player, a: float, w: Dictionary, more: float, forced: bool) -> void:
	if punch_t > 0:
		_punch(p, a, w, more, forced)
		return
	if not hook.is_empty() or not dashing.is_empty():
		return
	hook = { "x": p.x, "y": p.y - 3, "a": a, "spd": Weapons.wspd(p), "life": Weapons.wlife(p), "t": 0.0, "state": "out",
		"dmg": Weapons.wdmg(p) * more, "w": w["id"], "hit": {}, "stuck": 0.0 }
	_stat("hook")
	Snd.play("hatchet")

## The second stage of the hook: a heavy punch that stuns and knocks the foe away (into a wall: a slam).
static func _punch(p: Player, a: float, w: Dictionary, more: float, forced: bool) -> void:
	punch_t = 0.0
	var dmg := Weapons.wdmg(p) * 3.0 * more
	var hits := _cut(p, a, Weapons.wrange(p) + 6.0, deg_to_rad(120), dmg, forced, 300.0, w)
	for e in hits:
		if not e.is_boss():
			e.stun_t = maxf(e.stun_t, 1.0)
			Arsenal.slams.append({ "e": weakref(e), "t": 0.45, "dmg": dmg })
	if not hits.is_empty():
		_stat("punch", hits.size())
		G.add_shake(4)
		Fx.float_text(p.x + cos(a) * 16, p.y - 16, "POW", "orange", true)
	Snd.play("hit")

static func _combo(p: Player, a: float, w: Dictionary, more: float, forced: bool) -> void:
	var steps: Array = w.get("steps", ["slash", "slash", "slash"])
	if step_t > 1.4 or step >= steps.size():
		step = 0   # a pause starts the chain over
	step_t = 0.0
	if step == 0:
		marked.clear()
	var s: String = steps[step]
	var dmg := Weapons.wdmg(p) * more
	var reach := Weapons.wrange(p)
	var hits := []
	match s:
		"slash":
			hits = _cut(p, a, reach, deg_to_rad(w.get("arc", 100)), dmg, forced, 110.0, w)
			Snd.play("hatchet")
		"jab":
			hits = _cut(p, a, reach * 0.8, deg_to_rad(60), dmg * 0.8, forced, 50.0, w)
			Snd.play("hatchet")
		"sweep":
			hits = _cut(p, a, reach * 1.1, deg_to_rad(170), dmg, forced, 120.0, w)
			Snd.play("hatchet")
		"thrust":
			hits = _line(p, a, reach * 2.0, 10.0, dmg * 1.4, forced, w)
			Snd.play("hatchet")
		"spin":
			hits = _cut(p, a, reach * 1.25, TAU, dmg * 1.8, forced, 170.0, w)
			Snd.play("dodge")
		"upper":
			hits = _cut(p, a, reach, deg_to_rad(90), dmg * 2.2, forced, 30.0, w)
			for e in hits:
				if not e.is_boss():
					e.stun_t = maxf(e.stun_t, 0.8)
				Statuses.apply(e, "burn", 1, dmg)
				Arsenal.plant(e, 0.45, dmg, 22.0)   # thrown up, it comes down hard
				Fx.burst(e.x, e.y - 6, ["#e8873a", "#f2c94c", "#d8443c"], 8, 70, 0.3)
			Snd.play("hit")
		"shot":
			hits = _shot(p, a, 240.0, dmg * 2.0, forced)
	if not hits.is_empty():
		_stat("step_" + s)
	for e in hits:
		marked[e.uid] = true
	step += 1
	if w.get("linked", false) and hits.is_empty():
		step = 0   # a chain skill: a miss breaks the chain
	if step >= steps.size():
		step = 0

static func _heat(p: Player, a: float, w: Dictionary) -> Array:
	var hot: float = w.get("heat_dmg", 0.0) * heat
	var keep := p.dmg
	p.dmg *= 1.0 + hot   # the reactor: the hotter, the harder (for this shot only)
	var made := Combat.fire_projectiles(p, a)
	p.dmg = keep
	if hot > 0 and heat >= 0.5:
		_stat("hot_shot")
	heat = minf(1.0, heat + 1.0 / maxf(1.0, w.get("heat", 30)))
	cool_t = 0.0
	if p.shot_n % 2 == 0:
		Snd.play("shoot")
	if heat >= 1.0:
		_vent(p, w)
	return made

## Full heat: a scalding blast around you, then the gun cools before it fires again.
static func _vent(p: Player, w: Dictionary) -> void:
	var big: bool = w.get("heat_dmg", 0.0) > 0
	var n := Weapons.wcount(p)
	Arsenal.blast(p.x, p.y, Weapons.wdmg(p) * (10.0 if big else 5.0) * (1.0 + 0.35 * (n - 1)), 64.0 if big else 44.0, "#f4ecd8")
	for i in 16:
		var aa := TAU * i / 16.0
		Fx.particle(p.x + cos(aa) * 6, p.y + sin(aa) * 4, cos(aa) * 70, sin(aa) * 50 - 20, 0.6, "#f4ecd8" if i % 2 == 0 else "#c9c2a8", 3)
	Fx.float_text(p.x, p.y - 22, "VENT", "white")
	vent_t = VENT
	p.fire_cd = VENT
	_stat("vent")
	Snd.play("beam")

static func _reload_fire(p: Player, a: float, w: Dictionary, more: float) -> Array:
	var size := int(w.get("mag", 6))
	if mag <= 0 or mag > size:
		mag = size
	var made := Combat.fire_projectiles(p, a)
	mag -= 1
	if p.shot_n % 2 == 0 or size <= 6:
		Snd.play("shoot")
	if mag > 0:
		return made
	# The last shot of the magazine, then the reload.
	if w.get("last_crit", false):
		for b in made:
			b.crit = true
		_stat("last_crit")
	reload_max = float(w.get("reload", 1.0)) / maxf(0.25, p.rate)
	reload_t = reload_max
	p.fire_cd = reload_max
	mag = size
	_stat("reload")
	Snd.play("lock")
	if w.get("throw_mag", 0.0) > 0:
		# The empty magazine, thrown at the foe: it blows.
		Arsenal.toss(p, a, w, Weapons.wdmg(p) * w["throw_mag"] * more, 30.0, 0.9, "magazine")
		_stat("mag_throw")
	return made

static func _orbit(p: Player, a: float, w: Dictionary, n: int) -> Array:
	var want := int(w.get("stars", 6)) + n - 1
	stars.append({ "hit": {} })
	_stat("star")
	Snd.play("select")
	if stars.size() < mini(want, MAX_STARS):
		return []
	# The last one: they all fly at foes.
	var dmg := Weapons.wdmg(p) * 2.0 * (1.0 + 0.35 * maxi(0, want - MAX_STARS))
	var made := []
	for i in stars.size():
		var at := _star_pos(p, i, stars.size())
		made.append(Combat._raw_shot(at.x, at.y, a + randf_range(-0.7, 0.7), Weapons.wspd(p), dmg, Weapons.wlife(p), 3.0, 0, "hex", {},
			maxf(Weapons.whoming(p), 3.0)))
	stars.clear()
	_stat("launch")
	Snd.play("bolt")
	return made

static func _recall_fire(p: Player, a: float, w: Dictionary, more: float, grow: float, forced: bool) -> void:
	if disc.is_empty():
		var sp := Weapons.wspd(p)
		disc = { "x": p.x + cos(a) * 6, "y": p.y - 3 + sin(a) * 6, "vx": cos(a) * sp, "vy": sin(a) * sp, "t": 0.0,
			"life": Weapons.wlife(p), "state": "out", "dmg": Weapons.wdmg(p) * more, "r": 4.0 * grow * Weapons.wsize(p),
			"hit": {}, "w": w["id"], "col": _col(w), "crit": forced, "spin_t": 0.0 }
		_stat("disc")
		Snd.play("hatchet")
		return
	if disc["state"] != "back":
		disc["state"] = "back"
		disc["hit"] = {}
		_stat("recall")
		Snd.play("dodge")

# ---------- Melee helpers ----------
## A blow in front of you, like Combat.attack_slash: every foe in reach and in the arc (TAU: all round).
static func _cut(p: Player, a: float, reach: float, arc: float, dmg: float, crit: bool, kb: float, w: Dictionary) -> Array:
	var hits := []
	for e in G.enemies.duplicate():
		if not e.targetable() or TB.dist(e, p) - e.r > reach:
			continue
		if arc < TAU and absf(TB.wrap_ang(TB.ang_to(p, e) - a)) > arc / 2:
			continue
		Combat.melee_hit(p, e, dmg, crit, kb)
		Afx.cut(e.x, e.y - e.z, TB.ang_to(p, e), false)
		hits.append(e)
	G.swings.append({ "kind": "slash", "x": p.x, "y": p.y - 2, "a": a, "r": reach, "arc": minf(arc, TAU), "t": 0.14, "max": 0.14,
		"tag": w["tags"][0] if w["tags"].size() > 0 else "" })
	return hits

## A thrust along the aim: every foe on the line (like Combat.attack_line).
static func _line(p: Player, a: float, length: float, width: float, dmg: float, crit: bool, w: Dictionary) -> Array:
	var dx := cos(a)
	var dy := sin(a)
	var hits := []
	for e in G.enemies.duplicate():
		if not e.targetable():
			continue
		var px: float = e.x - p.x
		var py: float = e.y - p.y
		var along: float = px * dx + py * dy
		if along > -e.r and along < length + e.r and absf(px * dy - py * dx) < width / 2.0 + e.r:
			Combat.melee_hit(p, e, dmg, crit, 130.0)
			hits.append(e)
	G.swings.append({ "kind": "thrust", "x": p.x, "y": p.y - 2, "a": a, "len": length, "width": width, "t": 0.12, "max": 0.12,
		"tag": w["tags"][0] if w["tags"].size() > 0 else "" })
	return hits

## A pistol shot: the first foe along the aim, stopped by walls. It always crits a foe the cuts
## of this chain hit (the finisher).
static func _shot(p: Player, a: float, length: float, dmg: float, crit: bool) -> Array:
	var x0 := p.x + cos(a) * 6
	var y0 := p.y - 2 + sin(a) * 6
	var hit: Enemy = null
	var d := 0.0
	while d < length and hit == null:
		d += 4.0
		var x := x0 + cos(a) * d
		var y := y0 + sin(a) * d
		if World.solid(G.room, floori(x / TB.TS), floori(y / TB.TS), World.M_BULLET):
			break
		for e in G.enemies:
			if e.targetable() and TB.dist_xy(e.x, e.y, x, y) < e.r + 2:
				hit = e
				break
	flashes.append({ "k": "tracer", "x0": x0, "y0": y0, "x1": x0 + cos(a) * d, "y1": y0 + sin(a) * d, "t": 0.1, "max": 0.1, "col": "#fffbe0" })
	Fx.particle(x0, y0, 0, 0, 0.06, "#fffbe0", 3)
	Snd.play("bolt")
	if hit == null:
		return []
	var fin := marked.has(hit.uid)
	var c := Combat.damage_enemy(hit, dmg, { "force_crit": crit or fin, "kx": cos(a) * 120, "ky": sin(a) * 120 })
	Combat.on_hit_effects(hit, dmg, c, p, null)
	if fin:
		_stat("finisher_crit")
	return [hit]

# ---------- Every tick (Hazards.update) ----------
static func tick(room: Room, dt: float) -> void:
	if _room == null or _room.get_ref() != room:
		clear()
		_room = weakref(room)
	var p := G.player
	if p == null or p.weapon == null:
		return
	if p.weapon["id"] != _wid:
		_wid = p.weapon["id"]
		_reset_weapon()
	step_t += dt
	punch_t = maxf(0.0, punch_t - dt)
	reload_t = maxf(0.0, reload_t - dt)
	if vent_t > 0:
		vent_t = maxf(0.0, vent_t - dt)
		heat = vent_t / VENT
	else:
		cool_t += dt
		if cool_t > 0.35:
			heat = maxf(0.0, heat - 0.7 * dt)
	if not dashing.is_empty():
		_tick_dash(p)
	if not balls.is_empty():
		var keep := []
		for o in balls:
			if _ball(o, p, room, dt):
				keep.append(o)
		balls = keep
	if not rings.is_empty():
		_tick_rings(p, dt)
	if not phantoms.is_empty():
		_tick_phantoms(p, dt)
	if not jav.is_empty():
		_tick_jav(p, room, dt)
	if not hook.is_empty():
		_tick_hook(p, room, dt)
	if not stars.is_empty():
		_tick_stars(p, dt)
	if not disc.is_empty():
		_tick_disc(p, room, dt)
	if not flashes.is_empty():
		var kf := []
		for f in flashes:
			f["t"] -= dt
			if f["t"] > 0:
				kf.append(f)
		flashes = kf

## A charged shot in flight; false when it is spent.
static func _ball(o: Dictionary, p: Player, room: Room, dt: float) -> bool:
	o["t"] += dt
	var w: Dictionary = Weapons._by_id.get(o["w"], {})
	var a: float = o["a"]
	var nx: float = o["x"] + cos(a) * o["spd"] * dt
	var ny: float = o["y"] + sin(a) * o["spd"] * dt
	if World.solid(room, floori(nx / TB.TS), floori(ny / TB.TS), World.M_BULLET):
		return _ball_end(o, w)
	var x0: float = o["px"]
	var y0: float = o["py"]
	o["px"] = nx
	o["py"] = ny
	o["x"] = nx
	o["y"] = ny
	var rr: float = o["r"]
	var lv: float = o["lv"]
	for e in G.enemies.duplicate():
		if not e.targetable() or o["hit"].has(e.uid) or not Arsenal.swept(e, x0, y0, nx, ny, e.r + rr):
			continue
		o["hit"][e.uid] = true
		var c := Combat.damage_enemy(e, o["dmg"], { "force_crit": o["crit"], "kx": cos(a) * 80 * lv, "ky": sin(a) * 80 * lv })
		Combat.on_hit_effects(e, o["dmg"], c, p, null)
		if lv >= 1.0:
			_stat("full_hit")
			if w.get("aura", 0.0) > 0 and not e.is_boss():
				e.stun_t = maxf(e.stun_t, 1.0)   # a full cold star freezes what it hits
				e.chill_t = maxf(e.chill_t, 3.0)
				_stat("freeze")
		if o["crit"] and o["arrow"]:
			_stat("draw_crit")
		if o["pierce"] <= 0:
			return _ball_end(o, w)
		o["pierce"] -= 1
	if w.get("pull", 0.0) > 0:
		# The gravity globe drags foes toward it as it flies.
		var reach := 40.0 + 30.0 * lv
		for e in G.enemies:
			if not e.targetable() or e.is_boss():
				continue
			var d := TB.dist_xy(e.x, e.y, nx, ny)
			if d < reach and d > 3.0:
				var s: float = minf(d - 2.0, (60.0 + 80.0 * lv) * w["pull"] * dt)
				World.move_body(room, e, (nx - e.x) / d * s, (ny - e.y) / d * s, World.M_FLYER if e.d.get("fly", false) else World.M_WALKER)
				_stat("pull")
	if randf() < 0.5:
		Fx.particle(nx - cos(a) * rr, ny - sin(a) * rr, randf_range(-10, 10), randf_range(-10, 10), 0.25, o["col"], 1 if rr < 4 else 2)
	if o["t"] >= o["life"]:
		return _ball_end(o, w)
	return true

## A charged shot's end: shards (the shatterball), a collapse (the globe), or a pop.
static func _ball_end(o: Dictionary, w: Dictionary) -> bool:
	var n: int = w.get("shatter", 0)
	if n > 0:
		_stat("shard", n)
		for i in n:
			Combat._raw_shot(o["x"], o["y"], float(i) / n * TAU + randf() * 0.3, 200, o["dmg"] * 0.3, 0.45, 2.0, 0, "spark", {})
		Snd.play("hit")
	if w.get("pull", 0.0) > 0:
		_stat("collapse")
		Arsenal.blast(o["x"], o["y"], o["dmg"] * 0.8, 26.0 + 24.0 * o["lv"], o["col"], o["crit"])
	Fx.burst(o["x"], o["y"], [o["col"], "#ffffff"], 4 + roundi(o["r"]), 50 + 10 * o["r"], 0.25)
	return false

static func _tick_rings(p: Player, dt: float) -> void:
	var keep := []
	for g in rings:
		if g["delay"] > 0:
			g["delay"] -= dt
			if g["delay"] <= 0:
				_stat("aftershock")
				G.add_shake(2)
				Afx.dust(g["x"], g["y"])
				Snd.play("boom")
			keep.append(g)
			continue
		g["r"] = minf(g["max"], g["r"] + g["spd"] * dt)
		for e in G.enemies.duplicate():
			if not e.targetable() or g["hit"].has(e.uid) or TB.dist_xy(e.x, e.y, g["x"], g["y"]) - e.r > g["r"]:
				continue
			g["hit"][e.uid] = true
			var a := TB.ang_xy(g["x"], g["y"], e.x, e.y)
			var c := Combat.damage_enemy(e, g["dmg"], { "force_crit": g["crit"], "kx": cos(a) * 140, "ky": sin(a) * 140 })
			Combat.on_hit_effects(e, g["dmg"], c, p, null)
			if g["stun"] and not e.is_boss():
				e.stun_t = maxf(e.stun_t, 0.9)
			_stat("ring_hit")
		if g["r"] < g["max"]:
			keep.append(g)
		elif g["fire"]:
			# The magma maul: a ring of fire where the shockwave ends.
			_stat("fire_ring")
			for i in 10:
				if G.zones.size() >= 60:
					break
				var aa := TAU * i / 10.0
				G.zones.append({ "x": g["x"] + cos(aa) * g["r"], "y": g["y"] + sin(aa) * g["r"], "r": 10, "t": 2.5, "kind": "fire", "tick": 0.0 })
	rings = keep

static func _tick_dash(p: Player) -> void:
	if dashing["dmg"] > 0:
		for e in G.enemies.duplicate():
			if not e.targetable() or dashing["hit"].has(e.uid) or TB.dist(e, p) >= e.r + 12:
				continue
			dashing["hit"][e.uid] = true
			var c := Combat.damage_enemy(e, dashing["dmg"], { "force_crit": dashing["crit"], "col": "gold" })
			Combat.on_hit_effects(e, dashing["dmg"], c, p, null)
			Afx.cut(e.x, e.y - e.z, TB.ang_to(p, e), true)
			_stat("dash_cut")
	if p.dash_t > 0:
		return
	# The dash is over.
	var w: Dictionary = Weapons._by_id.get(dashing["w"], {})
	if dashing["dmg"] > 0:
		flashes.append({ "k": "streak", "x0": dashing["x0"], "y0": dashing["y0"] - 3, "x1": p.x, "y1": p.y - 3, "t": 0.2, "max": 0.2,
			"col": dashing["col"] })
	if w.get("dash_blast", 0.0) > 0:
		_stat("dash_blast")
		Arsenal.blast(p.x, p.y, dashing["dmg"] * w["dash_blast"], 26.0 + 18.0 * dashing["lv"], dashing["col"], dashing["crit"])
	if w.get("phantom", 0.0) > 0:
		phantoms.append({ "x0": dashing["x0"], "y0": dashing["y0"], "x1": p.x, "y1": p.y, "t": 0.5, "dmg": dashing["dmg"] * w["phantom"] })
	if dashing["jav"]:
		_pick_up(p)
	dashing = {}

## The phantom edge: 0.5 s after a dash, a phantom cuts along the same line.
static func _tick_phantoms(p: Player, dt: float) -> void:
	var keep := []
	for m in phantoms:
		m["t"] -= dt
		if m["t"] > 0:
			keep.append(m)
			continue
		var a := Vector2(m["x0"], m["y0"])
		var b := Vector2(m["x1"], m["y1"])
		for e in G.enemies.duplicate():
			var at := Vector2(e.x, e.y)
			if e.targetable() and Geometry2D.get_closest_point_to_segment(at, a, b).distance_to(at) < e.r + 12:
				var c := Combat.damage_enemy(e, m["dmg"], { "col": "purple" })
				Combat.on_hit_effects(e, m["dmg"], c, p, null)
				Afx.cut(e.x, e.y - e.z, (b - a).angle(), true)
				_stat("phantom_cut")
		flashes.append({ "k": "streak", "x0": m["x0"], "y0": m["y0"] - 3, "x1": m["x1"], "y1": m["y1"] - 3, "t": 0.3, "max": 0.3, "col": "#a35bd6" })
		Snd.play("dodge")
	phantoms = keep

static func _tick_jav(p: Player, room: Room, dt: float) -> void:
	jav["t"] += dt
	match jav["state"]:
		"fly":
			var a: float = jav["a"]
			var nx: float = jav["x"] + cos(a) * jav["spd"] * dt
			var ny: float = jav["y"] + sin(a) * jav["spd"] * dt
			if World.solid(room, floori(nx / TB.TS), floori(ny / TB.TS), World.M_BULLET):
				jav["state"] = "wall"
				jav["t"] = 0.0
				Snd.play("place")
				Afx.dust(jav["x"], jav["y"])
				return
			var x0: float = jav["px"]
			var y0: float = jav["py"]
			jav["px"] = nx
			jav["py"] = ny
			jav["x"] = nx
			jav["y"] = ny
			for e in G.enemies:
				if e.targetable() and Arsenal.swept(e, x0, y0, nx, ny, e.r + 3):
					var c := Combat.damage_enemy(e, jav["dmg"], { "force_crit": jav["crit"] })
					Combat.on_hit_effects(e, jav["dmg"], c, p, null)
					jav["state"] = "foe"
					jav["t"] = 0.0
					jav["e"] = weakref(e)
					jav["ox"] = nx - e.x
					jav["oy"] = ny - e.y
					_stat("pin")
					Snd.play("hit")
					return
			if jav["t"] >= jav["life"]:
				jav["state"] = "floor"
				jav["t"] = 0.0
			return
		"foe":
			var e: Enemy = jav["e"].get_ref()
			if e == null or e.hp <= 0:
				jav["state"] = "floor"   # its foe fell: it drops
			else:
				jav["x"] = e.x + jav["ox"]
				jav["y"] = e.y + jav["oy"]
		"back":
			var d := TB.dist_xy(jav["x"], jav["y"], p.x, p.y - 3)
			if d < 10.0:
				jav = {}
				Snd.play("select")
				return
			var s := minf(d, 420.0 * dt)
			jav["a"] = TB.ang_xy(p.x, p.y - 3, jav["x"], jav["y"])
			jav["x"] += (p.x - jav["x"]) / d * s
			jav["y"] += (p.y - 3 - jav["y"]) / d * s
			return
	var w: Dictionary = Weapons._by_id.get(jav["w"], {})
	if w.get("rod", 0.0) > 0:
		# The thunder pike, standing pinned: lightning on the foe nearest it.
		jav["zap"] -= dt
		if jav["zap"] <= 0:
			jav["zap"] = w["rod"]
			var e := Combat.nearest_enemy(jav["x"], jav["y"], 80)
			if e != null:
				Combat.lightning(e, jav["dmg"] * 0.5)
				flashes.append({ "k": "zap", "x0": jav["x"], "y0": jav["y"] - 6, "x1": e.x, "y1": e.y - 4, "t": 0.15, "max": 0.15, "col": "#6fd3e0" })
				_stat("rod_zap")
	if dashing.is_empty() and (jav["t"] > 8.0 or (jav["state"] != "foe" and jav["t"] > 0.25)):
		jav["state"] = "back"   # a miss (or one left alone too long) comes back by itself
		jav["t"] = 0.0

## The javelin dash is over: it is torn out of its foe (a second blow) and taken back. Called back
## without a dash (`dashed` false), it is torn out and flies home.
static func _pick_up(p: Player, dashed := true) -> void:
	if jav.is_empty():
		return
	var pinned: bool = jav["state"] == "foe"
	if pinned:
		var e: Enemy = jav["e"].get_ref()
		if e != null and e.hp > 0:
			var dmg: float = jav["dmg"] * 2.0
			var c := Combat.damage_enemy(e, dmg, { "force_crit": jav["crit"], "col": "orange" })
			Combat.on_hit_effects(e, dmg, c, p, null)
			Fx.float_text(e.x, e.y - e.r - 10, "RIP", "orange")
			_stat("rip")
	if not dashed:
		jav["state"] = "back"
		jav["t"] = 0.0
	elif pinned or TB.dist_xy(jav["x"], jav["y"], p.x, p.y) < 28.0:
		jav = {}
		Snd.play("select")
	else:
		jav["state"] = "back"   # the dash fell short (a pillar): it comes back by itself

static func _tick_hook(p: Player, room: Room, dt: float) -> void:
	hook["t"] += dt
	var w: Dictionary = Weapons._by_id.get(hook["w"], {})
	match hook["state"]:
		"out":
			var a: float = hook["a"]
			var nx: float = hook["x"] + cos(a) * hook["spd"] * dt
			var ny: float = hook["y"] + sin(a) * hook["spd"] * dt
			if hook["t"] >= hook["life"] or World.solid(room, floori(nx / TB.TS), floori(ny / TB.TS), World.M_BULLET):
				hook["state"] = "back"
				return
			hook["x"] = nx
			hook["y"] = ny
			for e in G.enemies:
				if not e.targetable() or TB.dist_xy(e.x, e.y, nx, ny) >= e.r + 4:
					continue
				var dm: float = hook["dmg"] * 0.5
				var c := Combat.damage_enemy(e, dm, {})
				Combat.on_hit_effects(e, dm, c, p, null)
				hook["e"] = weakref(e)
				_stat("hooked")
				Snd.play("lock")
				if e.type == "dummy":
					hook["state"] = "back"   # a training dummy is not pulled about
					return
				if e.is_boss() or e.d.get("mini", false) or e.d.get("champion", false) or e.r >= 11.0:
					# Too big to move: the chain pulls you to it instead.
					hook["state"] = "zip"
					_start_dash(p, TB.ang_to(p, e), maxf(0.0, TB.dist(p, e) - e.r - p.r - 4.0), 0.0, false, w)
				else:
					hook["state"] = "pull"
					e.stun_t = maxf(e.stun_t, 0.4)
				return
		"pull":
			var e: Enemy = hook["e"].get_ref()
			if e == null or e.hp <= 0 or not e.targetable():
				hook = {}
				return
			e.stun_t = maxf(e.stun_t, 0.3)
			var d := TB.dist(p, e)
			var near := e.r + p.r + 8.0
			if d <= near or hook["stuck"] > 0.4:
				if d < near + 30.0:
					punch_t = 1.6
				hook = {}
				return
			var s := minf(d - near, 380.0 * dt)
			var ox := e.x
			var oy := e.y
			World.move_body(room, e, (p.x - e.x) / d * s, (p.y - e.y) / d * s, World.M_FLYER if e.d.get("fly", false) else World.M_WALKER)
			if TB.dist_xy(ox, oy, e.x, e.y) < s * 0.3:
				hook["stuck"] += dt   # caught on a pillar
			hook["x"] = e.x
			hook["y"] = e.y
			_stat("pull_foe")
			if w.get("drag", 0.0) > 0:
				# The anchor chain: the foe is dragged through the others, hitting each one.
				for o in G.enemies.duplicate():
					if o == e or not o.targetable() or hook["hit"].has(o.uid) or TB.dist(o, e) >= o.r + e.r + 4:
						continue
					hook["hit"][o.uid] = true
					var dm: float = hook["dmg"] * w["drag"]
					var aa := TB.ang_to(e, o)
					var c := Combat.damage_enemy(o, dm, { "kx": cos(aa) * 160, "ky": sin(aa) * 160 })
					Combat.on_hit_effects(o, dm, c, p, null)
					_stat("drag_hit")
		"zip":
			var e: Enemy = hook["e"].get_ref()
			if e != null:
				hook["x"] = e.x
				hook["y"] = e.y
			if p.dash_t <= 0:
				punch_t = 1.6
				hook = {}
		"back":
			var d := TB.dist_xy(hook["x"], hook["y"], p.x, p.y - 3)
			if d < 10.0:
				hook = {}
				return
			var s := minf(d, 520.0 * dt)
			hook["x"] += (p.x - hook["x"]) / d * s
			hook["y"] += (p.y - 3 - hook["y"]) / d * s

static func _star_pos(p: Player, i: int, n: int) -> Vector2:
	var a := spin + TAU * i / maxf(1.0, n)
	return Vector2(p.x + cos(a) * 18.0, p.y - 4 + sin(a) * 12.0)

static func _tick_stars(p: Player, dt: float) -> void:
	spin += dt * 3.0
	var n := stars.size()
	for i in n:
		var s: Dictionary = stars[i]
		var at := _star_pos(p, i, n)
		for uid in s["hit"].keys():
			s["hit"][uid] -= dt
			if s["hit"][uid] <= 0:
				s["hit"].erase(uid)
		for e in G.enemies.duplicate():
			if not e.targetable() or s["hit"].has(e.uid) or TB.dist_xy(e.x, e.y, at.x, at.y) >= e.r + 4:
				continue
			s["hit"][e.uid] = 0.4
			var dm := Weapons.wdmg(p) * 0.5
			var c := Combat.damage_enemy(e, dm, { "col": "gold" })
			Combat.on_hit_effects(e, dm, c, p, null)
			_stat("star_touch")

static func _tick_disc(p: Player, room: Room, dt: float) -> void:
	disc["t"] += dt
	match disc["state"]:
		"out":
			var k := maxf(0.0, 1.0 - disc["t"] / maxf(0.05, disc["life"]))
			var nx: float = disc["x"] + disc["vx"] * k * dt
			var ny: float = disc["y"] + disc["vy"] * k * dt
			if World.solid(room, floori(nx / TB.TS), floori(disc["y"] / TB.TS), World.M_BULLET):
				disc["vx"] = -disc["vx"]
				nx = disc["x"]
			if World.solid(room, floori(disc["x"] / TB.TS), floori(ny / TB.TS), World.M_BULLET):
				disc["vy"] = -disc["vy"]
				ny = disc["y"]
			disc["x"] = nx
			disc["y"] = ny
			if k <= 0:
				disc["state"] = "spin"
				disc["spin_t"] = 0.0
		"spin":
			disc["spin_t"] += dt
			if disc["spin_t"] > 5.0:
				disc["state"] = "back"   # it comes home by itself
				disc["hit"] = {}
		"back":
			var d := TB.dist_xy(disc["x"], disc["y"], p.x, p.y - 3)
			if d < 8.0:
				disc = {}
				Snd.play("place")
				return
			var s := minf(d, 460.0 * dt)
			disc["x"] += (p.x - disc["x"]) / d * s
			disc["y"] += (p.y - 3 - disc["y"]) / d * s
	# Out and spinning it cuts each foe every 0.25 s; called back, each foe once, for double.
	var back: bool = disc["state"] == "back"
	for uid in disc["hit"].keys():
		disc["hit"][uid] -= dt
		if disc["hit"][uid] <= 0:
			disc["hit"].erase(uid)
	var rr: float = disc["r"]
	for e in G.enemies.duplicate():
		if not e.targetable() or disc["hit"].has(e.uid) or TB.dist_xy(e.x, e.y, disc["x"], disc["y"]) >= e.r + rr:
			continue
		disc["hit"][e.uid] = 999.0 if back else 0.25
		var dm: float = disc["dmg"] * (2.0 if back else 0.6)
		var c := Combat.damage_enemy(e, dm, { "force_crit": disc["crit"] and back })
		Combat.on_hit_effects(e, dm, c, p, null)
		if back:
			_stat("recall_hit")

## A roll (Combat.on_roll_start): the swiftdraw bow is drawn fully at once.
static func on_roll(p: Player) -> void:
	if p.weapon != null and p.weapon.get("roll_draw", false) and level < 1.0:
		level = 1.0
		_stat("roll_draw")
		Fx.burst(p.x, p.y - 4, ["#f4ecd8", "#ffffff"], 6, 40, 0.2)
		Snd.play("select")

## A kill (Combat.kill_enemy): the deadeye reloads at once.
static func on_kill(_e: Enemy) -> void:
	var p := G.player
	if p == null or p.weapon == null or not p.weapon.get("kill_reload", false):
		return
	var size := int(p.weapon.get("mag", 6))
	if mag == size and reload_t <= 0:
		return
	mag = size
	if reload_t > 0:
		reload_t = 0.0
		p.fire_cd = minf(p.fire_cd, 0.05)
	_stat("kill_reload")
	Fx.float_text(p.x, p.y - 22, "RELOAD", "gold")

# ---------- Drawing ----------
## On the floor (world_view, after the arsenal's): shockwaves, the cold star's aura, the reach of a
## slam or a dash being charged.
static func draw_floor(ci: CanvasItem, t: float) -> void:
	var p := G.player
	if p == null or p.weapon == null:
		return
	for g in rings:
		if g["delay"] > 0:
			continue
		var c := TB.c(g["col"])
		var k: float = 1.0 - 0.6 * g["r"] / maxf(1.0, g["max"])
		ci.draw_arc(Vector2(g["x"], g["y"]), g["r"], 0.0, TAU, 40, Color(c.r, c.g, c.b, 0.85 * k), 2.0)
		ci.draw_arc(Vector2(g["x"], g["y"]), maxf(0.5, g["r"] - 3.0), 0.0, TAU, 40, Color(1, 1, 1, 0.35 * k), 1.0)
	if level <= 0:
		return
	var w: Dictionary = p.weapon
	if w.get("aura", 0.0) > 0:
		ci.draw_circle(Vector2(p.x, p.y), w["aura"], Color(0.78, 0.94, 1.0, 0.07 + 0.07 * level))
		for i in 8:
			var a := i * 0.785 + t * 0.6
			var rr: float = fmod(i * 9.1 + t * 14.0, w["aura"])
			ci.draw_rect(Rect2(roundf(p.x + cos(a) * rr), roundf(p.y + sin(a) * rr * 0.7), 1, 1), Color(1, 1, 1, 0.8))
	match w["kind"]:
		"slam":
			var n := Weapons.wcount(p)
			var reach := minf(Weapons.wrange(p) * (0.5 + 0.5 * level) * minf(2.0, 1.0 + 0.06 * sqrt(float(n - 1))) * sqrt(Weapons.wsize(p)), 160.0)
			ci.draw_arc(Vector2(p.x + cos(p.aim_a) * 8, p.y + 2 + sin(p.aim_a) * 6), reach, 0.0, TAU, 32, Color(1, 1, 1, 0.12 + 0.18 * level), 1.0)
		"dash":
			var reach := Weapons.wrange(p) * (0.35 + 0.65 * level)
			for i in int(reach / 6.0):
				var q := Vector2(p.x, p.y) + Vector2.from_angle(p.aim_a) * (8.0 + i * 6.0)
				ci.draw_rect(Rect2(roundf(q.x), roundf(q.y), 1, 1), Color(1, 1, 1, 0.3 + 0.4 * level))

## Over everyone (world_view, after the arsenal's): shots, the javelin, the hook, the disc, stars,
## tracers, the charge around the hero, the heat bar and the magazine.
static func draw_over(ci: CanvasItem, t: float) -> void:
	var p := G.player
	if p == null or p.weapon == null:
		return
	for o in balls:
		var c := TB.c(o["col"])
		var at := Vector2(o["x"], o["y"])
		if o["arrow"]:
			var d := Vector2.from_angle(o["a"])
			if o["crit"]:
				ci.draw_line(at - d * 9, at + d * 2, Color(1, 0.95, 0.6, 0.5), 3.0)
			ci.draw_line(at - d * 7, at + d * 1, TB.c("#7a5236"), 1.0)
			ci.draw_rect(Rect2(roundf(at.x + d.x * 2) - 1, roundf(at.y + d.y * 2) - 1, 2, 2), TB.c("#f4ecd8"))
			ci.draw_rect(Rect2(roundf(at.x - d.x * 7), roundf(at.y - d.y * 7), 1, 1), TB.c("#d8443c"))
		else:
			var r: float = o["r"]
			ci.draw_circle(at, r + 1.5, Color(c.r, c.g, c.b, 0.35))
			ci.draw_circle(at, r, c)
			ci.draw_circle(at - Vector2(r, r) * 0.25, r * 0.5, Color(1, 1, 1, 0.9))
	if not jav.is_empty():
		var d := Vector2.from_angle(jav["a"])
		var at := Vector2(roundf(jav["x"]), roundf(jav["y"]))
		if jav["state"] == "floor":
			ci.draw_line(at - d * 9 + Vector2(0, 3), at + d * 3 + Vector2(0, 3), Color(0, 0, 0, 0.3), 1.0)
		ci.draw_line(at - d * 10, at + d * 1, TB.c("#7a5236"), 1.0)
		ci.draw_line(at + d * 1, at + d * 4, TB.c("#f4ecd8") if not Weapons._by_id.get(jav["w"], {}).has("rod") else TB.c("#6fd3e0"), 2.0)
		if Weapons._by_id.get(jav["w"], {}).has("rod") and jav["state"] != "fly" and floori(t * 8) % 2 == 0:
			ci.draw_rect(Rect2(at.x - 1 + sin(t * 20) * 2, at.y - 7, 1, 1), TB.c("#c8f0ff"))
	if not hook.is_empty():
		var from := Vector2(p.x, p.y - 3)
		var to := Vector2(hook["x"], hook["y"])
		var dist := from.distance_to(to)
		for i in int(dist / 3.0):
			var q := from.lerp(to, i * 3.0 / maxf(1.0, dist))
			ci.draw_rect(Rect2(roundf(q.x), roundf(q.y), 1, 1), TB.c("#8b8f9c") if i % 2 == 0 else TB.c("#4e4a5e"))
		ci.draw_rect(Rect2(roundf(to.x) - 2, roundf(to.y) - 2, 4, 4), TB.c("#140f1c"))
		ci.draw_rect(Rect2(roundf(to.x) - 1, roundf(to.y) - 1, 2, 2), TB.c("#c9c2a8"))
	if punch_t > 0 and floori(t * 10) % 2 == 0:
		ci.draw_rect(Rect2(roundf(p.x + cos(p.aim_a) * 9) - 1, roundf(p.y - 3 + sin(p.aim_a) * 9) - 1, 3, 3), TB.c("#e8873a"))
	if not disc.is_empty():
		var at := Vector2(disc["x"], disc["y"])
		var r: float = disc["r"]
		ci.draw_circle(at + Vector2(0, 4), r * 0.8, Color(0, 0, 0, 0.25))
		ci.draw_circle(at, r + 1, TB.c("#140f1c"))
		ci.draw_circle(at, r, TB.c(disc["col"]))
		var sa := t * 24.0
		for i in 2:
			var q := at + Vector2.from_angle(sa + i * PI) * (r - 1)
			ci.draw_rect(Rect2(roundf(q.x), roundf(q.y), 1, 1), TB.c("#ffffff"))
	var n := stars.size()
	for i in n:
		var at := _star_pos(p, i, n)
		var x := roundf(at.x)
		var y := roundf(at.y)
		var tw := floori(t * 8 + i) % 3 == 0
		ci.draw_rect(Rect2(x - 2, y, 5, 1), TB.c("#f2c94c"))
		ci.draw_rect(Rect2(x, y - 2, 1, 5), TB.c("#f2c94c"))
		ci.draw_rect(Rect2(x, y, 1, 1), TB.c("#ffffff") if not tw else TB.c("#fffbe0"))
	for f in flashes:
		var k: float = f["t"] / f["max"]
		var c := TB.c(f["col"])
		var a := Vector2(f["x0"], f["y0"])
		var b := Vector2(f["x1"], f["y1"])
		match f["k"]:
			"tracer":
				ci.draw_line(a, b, Color(c.r, c.g, c.b, k), 1.0)
			"streak":
				ci.draw_line(a, b, Color(c.r, c.g, c.b, 0.6 * k), 3.0)
				ci.draw_line(a, b, Color(1, 1, 1, k), 1.0)
			"zap":
				var prev := a
				for j in range(1, 5):
					var q := a.lerp(b, j / 4.0) + (Vector2(sin(j * 7.3 + f["x0"]), cos(j * 5.1 + f["y1"])) * 3.0 if j < 4 else Vector2.ZERO)
					ci.draw_line(prev, q, Color(c.r, c.g, c.b, k), 1.0)
					prev = q
	var w: Dictionary = p.weapon
	if level > 0 and w["kind"] in HELD:
		var c := TB.c(_col(w))
		var full := level >= 1.0
		var col := Color(1, 1, 1) if full and floori(t * 12) % 2 == 0 else c
		ci.draw_arc(Vector2(p.x, p.y - 4), 11.0, -PI / 2, -PI / 2 + TAU * level, 24, col, 1.0)
		if w["kind"] == "charge" and not w.get("roll_draw", false) and w.get("tighten", 0) == 0:
			var m := Vector2(p.x, p.y - 3) + Vector2.from_angle(p.aim_a) * 9
			ci.draw_circle(m, 1.0 + 3.0 * level, Color(c.r, c.g, c.b, 0.8))
			ci.draw_circle(m, 0.5 + 1.5 * level, Color(1, 1, 1, 0.9))
	if w["kind"] == "heat" and heat > 0:
		var x := roundf(p.x) - 6
		var y := roundf(p.y) - 22
		ci.draw_rect(Rect2(x - 1, y - 1, 14, 4), TB.c("#140f1c"))
		var hc := TB.c("#f2c94c").lerp(TB.c("#d8443c"), heat)
		if vent_t > 0 and floori(t * 10) % 2 == 0:
			hc = Color(1, 1, 1)
		ci.draw_rect(Rect2(x, y, roundf(12 * heat), 2), hc)
	if w["kind"] == "reload":
		var size := int(w.get("mag", 6))
		var x := roundf(p.x) - 6
		var y := roundf(p.y) - 22
		if reload_t > 0:
			ci.draw_rect(Rect2(x - 1, y - 1, 14, 4), TB.c("#140f1c"))
			ci.draw_rect(Rect2(x, y, roundf(12 * (1.0 - reload_t / maxf(0.01, reload_max))), 2), TB.c("#c9c2a8"))
		elif mag > 0 and mag < size:
			for i in mag:
				ci.draw_rect(Rect2(roundf(p.x) - size + i * 2, y, 1, 2), TB.c("#f2c94c"))
