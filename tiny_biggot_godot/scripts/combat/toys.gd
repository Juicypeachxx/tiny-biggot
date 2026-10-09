class_name Toys
extends RefCounted
## Stage 31 THE TOYBOX (his word, 9 Oct: "add more fun and crazy weapons with cool effects and new
## effects 20+"). Eight new kinds of weapon, expanded game only; ideas only, every name, picture and
## number is this game's own. Combat.player_shoot calls `fire`, Hazards.update `tick`; items cast
## them with the action ["toy", kind, mult] (`cast`).
##   shark    a fin swims under the floor (walls are no bar) to a foe, leaps out and bites, dives and
##            hunts the next: 3 bites. FRENZY: 6 bites, each 15% harder.
##   twister  a twister drifts ahead, lifting the foes it touches and carrying them round inside it;
##            when it dies down it flings them and they slam to the floor. SHARKS: it spits land sharks.
##   disco    a mirror ball over you sweeps coloured beams round you; foes in the light are hurt and
##            dance (they stop for a beat). Each cast while it turns adds a beam. PARTY: twice the beams.
##   yoyo     out to the foe and back on a string; the string cuts what it crosses, and it spins at
##            the far end. TWIN: two of them.
##   portal   each shot goes into a portal by you and comes out of one behind the foe: a stab in the
##            back for +50%, walls or not. RIFT: the far portal stays and fires twice more.
##   saw      a saw blade that bounces once, then digs in as a spinning trap for 6 s (up to 6).
##            MAGNET: the traps creep toward foes.
##   voodoo   a pin that sticks in a foe; every pinned foe takes 35% of the harm any other pinned foe
##            takes (Combat.damage_enemy calls `shared`). DOOM: pinned foes are cursed, the share 60%.
##   anvil    an anvil falls on the foe you aim at (its shadow first): a crush that stuns, and it
##            stays 5 s as cover that stops enemy shots. PIANO: a grand piano, wider, and notes fly.
## +1 PROJECTILE STACKS: every projectile past the first adds 35% damage (sharks, saws and pins: one
## more each first, up to 3). Damage goes through Combat.damage_enemy and on_hit_effects, so crits,
## ailments and every on-hit effect work.

const KINDS := ["shark", "twister", "disco", "yoyo", "portal", "saw", "voodoo", "anvil"]
## Keys a weapon row may carry to change what its kind does (the uniqueness report counts them).
const TWISTS := ["frenzy", "sharks", "party", "twin", "rift", "magnet", "doom", "piano"]
## Rough hits an attack lands, for the item card's BASE POWER (Weapons.weapon_dps).
const POWER := { "shark": 3.0, "twister": 2.5, "disco": 3.0, "yoyo": 2.2, "portal": 1.4, "saw": 3.0, "voodoo": 1.8, "anvil": 1.6 }
const MAX_SHARKS := 9
const MAX_TWISTERS := 3
const MAX_YOYOS := 6
const MAX_GATES := 6
const MAX_SAWS := 6
const MAX_NEEDLES := 24
const MAX_PINNED := 8
const MAX_ANVILS := 4
const MAX_HELD := 5
const BEAM_COLS := [Color(1.0, 0.35, 0.55), Color(0.35, 0.8, 1.0), Color(1.0, 0.9, 0.3), Color(0.5, 1.0, 0.45),
	Color(0.8, 0.5, 1.0), Color(1.0, 0.6, 0.25), Color(0.4, 1.0, 0.9), Color(1, 1, 1)]

static var sharks: Array = []    # { x, y, uid, t, bites, max, dmg, mult, frenzy, leap, bitten, life, crit, a }
static var twisters: Array = []  # { x, y, vx, vy, t, life, dmg, r, held, tick, sharks, shark_t, crit }
static var discos: Array = []    # { t, life, dmg, beams, max, spin, a, len, hit, crit }  (it floats over you)
static var yoyos: Array = []     # { a, d, max, phase, spin, dmg, hit, crit, x, y }
static var gates: Array = []     # { x, y, ex, ey, a, uid, t, life, shots, cd, dmg }
static var saws: Array = []      # { x, y, vx, vy, t, fly, life, dmg, stuck, bounced, hit, magnet, r, crit }
static var needles: Array = []   # { x, y, vx, vy, t, life, dmg, doom, crit }
static var pinned := {}          # uid -> { t, share }
static var anvils: Array = []    # { x, y, t, fall, dmg, r, piano, life, landed, crit, clang }
static var dancing := {}         # uid -> seconds left (the disco's light)
static var stats := {}           # what happened, by name (tests/toys_test reads it)
static var _sharing := false

static func handles(kind: String) -> bool:
	return kind in KINDS

static func _stat(k: String, n: int = 1) -> void:
	stats[k] = stats.get(k, 0) + n

static func clear() -> void:
	for l in [sharks, twisters, discos, yoyos, gates, saws, needles, anvils]:
		l.clear()
	pinned.clear()
	dancing.clear()

## A foe the toys may touch: not one tamed to fight for you (summons.gd), as every other attack.
static func _foe(e: Enemy) -> bool:
	return e.targetable() and e.charm_t <= 0

static func _big(e: Enemy) -> bool:
	return e.is_boss() or e.d.get("mini", false) or e.d.get("champion", false)

static func _wall(x: float, y: float) -> bool:
	return World.solid(G.room, floori(x / TB.TS), floori(y / TB.TS), World.M_BULLET)

static func _floor_ok(x: float, y: float) -> bool:
	return not World.solid(G.room, floori(x / TB.TS), floori(y / TB.TS), World.M_WALKER)

static func _hurt(e: Enemy, dmg: float, p: Player, crit: bool = false, col: String = "", extra: Dictionary = {}) -> void:
	if e.hp <= 0 or not _foe(e):
		return
	var o := extra.duplicate()
	o["force_crit"] = crit
	if col != "":
		o["col"] = col
	var c := Combat.damage_enemy(e, dmg, o)
	Combat.on_hit_effects(e, dmg, c, p, null)

static func _by_uid(uid: int) -> Enemy:
	if uid < 0:
		return null
	for e in G.enemies:
		if e.uid == uid:
			return e
	return null

static func _nearest(x: float, y: float, within: float, skip: Dictionary = {}) -> Enemy:
	var best: Enemy = null
	var bd := within
	for e in G.enemies:
		if _foe(e) and not skip.has(e.uid):
			var d := TB.dist_xy(e.x, e.y, x, y)
			if d < bd:
				bd = d
				best = e
	return best

## The foe nearest your aim (within about 30 degrees, 260 px), else the nearest one.
static func _aimed(p: Player, a: float) -> Enemy:
	var best: Enemy = null
	var bd := 260.0
	for e in G.enemies:
		if _foe(e) and absf(TB.wrap_ang(TB.ang_to(p, e) - a)) < 0.5:
			var d := TB.dist(p, e)
			if d < bd:
				bd = d
				best = e
	return best if best != null else Combat.auto_target(p, 260)

static func _word(x: float, y: float, text: String, col: String) -> void:
	Fx.texts.append({ "x": x, "y": y, "text": text, "col": col, "life": 0.7, "big": false })

## Distance from a point to a segment.
static func _seg_d(px: float, py: float, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	var k := 0.0 if l2 <= 0.0001 else clampf(((px - a.x) * ab.x + (py - a.y) * ab.y) / l2, 0.0, 1.0)
	return Vector2(px, py).distance_to(a + ab * k)

# ---------- Firing (Combat.player_shoot) ----------
static func fire(p: Player, a: float, forced: bool) -> Array:
	var w: Dictionary = p.weapon
	var n := Weapons.wcount(p)
	var dmg := Weapons.wdmg(p) * (1.0 + 0.35 * (n - 1))
	var size := Weapons.wsize(p)
	var sx := p.x + cos(a) * 7.0
	var sy := p.y - 3.0 + sin(a) * 7.0
	match w["kind"]:
		"shark":
			var k := mini(n, 3)   # a fin a projectile, up to 3; the rest adds damage
			var sd := Weapons.wdmg(p) * (1.0 + 0.35 * maxi(0, n - k))
			for i in k:
				_shark(sx + (i - (k - 1) / 2.0) * 8.0, sy + 6.0, sd, w.get("frenzy", false), forced, -1)
			Snd.play("dodge")
		"twister":
			_twister(sx, sy + 6.0, a, dmg, Weapons.wlife(p), 22.0 * size, w.get("sharks", false), forced)
			Snd.play("beam")
		"disco":
			_disco(dmg, Weapons.wlife(p), 140.0 * size, w.get("party", false), forced)
		"yoyo":
			var twin: bool = w.get("twin", false)
			for side in ([-1.0, 1.0] if twin else [0.0]):
				if yoyos.size() >= MAX_YOYOS:
					yoyos.pop_front()
				yoyos.append({ "a": a + side * 0.4, "d": 0.0, "max": maxf(60.0, Weapons.wspd(p) * Weapons.wlife(p)), "phase": 0,
					"spin": 0.0, "dmg": dmg, "hit": {}, "crit": forced, "x": sx, "y": sy, "spd": Weapons.wspd(p), "r": 5.0 * size })
			Snd.play("hatchet")
		"portal":
			var e := _aimed(p, a)
			_gate(p, sx, sy, a, e, dmg * 1.5, w.get("rift", false))
			Snd.play("portal")
		"saw":
			var k := mini(n, 3)
			var sd := Weapons.wdmg(p) * (1.0 + 0.35 * maxi(0, n - k))
			for i in k:
				var aa := a + (i - (k - 1) / 2.0) * 0.25
				_saw(sx, sy, cos(aa) * Weapons.wspd(p), sin(aa) * Weapons.wspd(p), sd, w.get("magnet", false), 7.0 * size, forced)
			Snd.play("hatchet")
		"voodoo":
			var k := mini(n, 3)
			var nd := Weapons.wdmg(p) * (1.0 + 0.35 * maxi(0, n - k))
			for i in k:
				var aa := a + (i - (k - 1) / 2.0) * 0.18
				if needles.size() >= MAX_NEEDLES:
					needles.pop_front()
				needles.append({ "x": sx, "y": sy, "vx": cos(aa) * Weapons.wspd(p), "vy": sin(aa) * Weapons.wspd(p), "t": 0.0,
					"life": Weapons.wlife(p), "dmg": nd, "doom": w.get("doom", false), "crit": forced })
			Snd.play("bolt")
		"anvil":
			var e := _aimed(p, a)
			var tx: float = e.x if e != null else p.x + cos(a) * 90.0
			var ty: float = e.y if e != null else p.y + sin(a) * 90.0
			_anvil(tx, ty, dmg, w.get("piano", false), size, forced)
	return []

static func _shark(x: float, y: float, dmg: float, frenzy: bool, crit: bool, uid: int) -> void:
	if sharks.size() >= MAX_SHARKS:
		sharks[sharks.size() - 1]["dmg"] += dmg * 0.5   # past the cap: the newest bites harder
		return
	sharks.append({ "x": x, "y": y, "uid": uid, "t": 0.0, "bites": 0, "max": 6 if frenzy else 3, "dmg": dmg, "mult": 1.0,
		"frenzy": frenzy, "leap": 0.0, "bitten": {}, "life": 7.0, "crit": crit, "a": 0.0 })

static func _twister(x: float, y: float, a: float, dmg: float, life: float, r: float, with_sharks: bool, crit: bool) -> void:
	if twisters.size() >= MAX_TWISTERS:
		twisters[twisters.size() - 1]["dmg"] += dmg * 0.5
		twisters[twisters.size() - 1]["life"] += 0.4
		return
	twisters.append({ "x": x, "y": y, "vx": cos(a) * 70.0, "vy": sin(a) * 70.0, "t": 0.0, "life": life, "dmg": dmg, "r": r,
		"held": {}, "tick": 0.0, "sharks": with_sharks, "shark_t": 0.4, "crit": crit })

static func _disco(dmg: float, life: float, length: float, party: bool, crit: bool) -> void:
	if not discos.is_empty():
		var o: Dictionary = discos[0]
		o["dmg"] = maxf(o["dmg"], dmg)
		o["life"] = o["t"] + maxf(life, o["life"] - o["t"])
		o["beams"] = mini(o["beams"] + 1, o["max"])   # each cast while it turns adds a beam
		return
	discos.append({ "t": 0.0, "life": life, "dmg": dmg, "beams": 8 if party else 4, "max": 12 if party else 8,
		"spin": 2.2 if party else 1.3, "a": randf() * TAU, "len": length, "hit": {}, "crit": crit })
	Snd.play("bell")

static func _gate(p: Player, x: float, y: float, a: float, e: Enemy, dmg: float, rift: bool) -> void:
	if gates.size() >= MAX_GATES:
		gates.pop_front()
	var ex: float
	var ey: float
	if e != null:
		var away := Vector2(e.x - p.x, e.y - p.y).normalized()
		ex = e.x + away.x * (e.r + 20.0)
		ey = e.y + away.y * (e.r + 20.0)
	else:
		ex = p.x + cos(a) * 90.0
		ey = p.y + sin(a) * 90.0
	gates.append({ "x": x + cos(a) * 8.0, "y": y + sin(a) * 8.0, "ex": ex, "ey": ey, "a": a, "uid": e.uid if e != null else -1,
		"t": 0.0, "life": 1.2 if rift else 0.4, "shots": 3 if rift else 1, "cd": 0.08, "dmg": dmg })

static func _saw(x: float, y: float, vx: float, vy: float, dmg: float, magnet: bool, r: float, crit: bool, stuck: bool = false) -> void:
	if saws.size() >= MAX_SAWS:
		saws.pop_front()   # the oldest trap gives way
	saws.append({ "x": x, "y": y, "vx": vx, "vy": vy, "t": 0.0, "fly": 0.0, "life": 6.0, "dmg": dmg, "stuck": stuck, "bounced": false,
		"hit": {}, "magnet": magnet, "r": r, "crit": crit })

static func _anvil(x: float, y: float, dmg: float, piano: bool, size: float, crit: bool) -> void:
	if anvils.size() >= MAX_ANVILS:
		anvils.pop_front()
	anvils.append({ "x": x, "y": y, "t": 0.0, "fall": 0.45, "dmg": dmg, "r": (34.0 if piano else 22.0) * size, "piano": piano,
		"life": 5.0, "landed": false, "crit": crit, "clang": 0.0 })

## Sticks a voodoo pin in a foe.
static func pin(e: Enemy, doom: bool, dmg: float) -> void:
	if e == null or e.hp <= 0 or e.type == "dummy":
		return
	if not pinned.has(e.uid) and pinned.size() >= MAX_PINNED:
		var oldest := -1
		var least := 1e9
		for uid in pinned:
			if pinned[uid]["t"] < least:
				least = pinned[uid]["t"]
				oldest = uid
		pinned.erase(oldest)
	var share := 0.6 if doom else 0.35
	if pinned.has(e.uid):
		share = maxf(share, pinned[e.uid]["share"])
	pinned[e.uid] = { "t": 6.0, "share": share }
	if doom:
		Statuses.apply(e, "curse", 2, dmg)
	_stat("pinned")

## Combat.damage_enemy: a pinned foe was hurt; every other pinned foe takes its share.
static func shared(e: Enemy, dmg: float) -> void:
	if _sharing or dmg <= 0.0 or not pinned.has(e.uid):
		return
	_sharing = true
	var share: float = pinned[e.uid]["share"]
	for uid in pinned.keys():
		if uid == e.uid:
			continue
		var o := _by_uid(uid)
		if o != null and o.hp > 0 and _foe(o):
			Combat.damage_enemy(o, dmg * share, { "no_crit": true, "no_mult": true, "col": "purple", "silent": true })
			_stat("shared")
	_sharing = false

# ---------- Cast by items (the action ["toy", kind, mult]) ----------
static func cast(kind: String, p: Player, x: float, y: float, dmg: float, uid: int = -1) -> void:
	var a := TB.ang_xy(p.x, p.y, x, y)
	match kind:
		"shark":
			_shark(p.x, p.y + 3.0, dmg, false, false, uid)
		"twister":
			_twister(x, y, p.aim_a, dmg, 2.0, 22.0, false, false)
		"disco":
			_disco(dmg, 2.5, 140.0, false, false)
		"portal":
			_gate(p, p.x, p.y - 3.0, a, _by_uid(uid), dmg * 1.5, false)
		"saw":
			_saw(x, y, 0.0, 0.0, dmg, false, 7.0, false, true)
		"pin":
			pin(_by_uid(uid), false, dmg)
		"anvil":
			_anvil(x, y, dmg, false, 1.0, false)
	_stat("cast_" + kind)

# ---------- Every tick (Hazards.update) ----------
static func tick(room: Room, dt: float) -> void:
	var p := G.player
	if room == null or p == null:
		return
	if not sharks.is_empty():
		_tick_sharks(p, dt)
	if not twisters.is_empty():
		_tick_twisters(p, dt)
	if not discos.is_empty():
		_tick_disco(p, dt)
	if not yoyos.is_empty():
		_tick_yoyos(p, dt)
	if not gates.is_empty():
		_tick_gates(p, dt)
	if not saws.is_empty():
		_tick_saws(p, dt)
	if not needles.is_empty():
		_tick_needles(p, dt)
	if not pinned.is_empty():
		for uid in pinned.keys():
			pinned[uid]["t"] -= dt
			var e := _by_uid(uid)
			if pinned[uid]["t"] <= 0.0 or e == null or e.hp <= 0:
				pinned.erase(uid)
	if not anvils.is_empty():
		_tick_anvils(p, dt)
	if not dancing.is_empty():
		for uid in dancing.keys():
			dancing[uid] -= dt
			if dancing[uid] <= 0.0:
				dancing.erase(uid)

static func _tick_sharks(p: Player, dt: float) -> void:
	var keep := []
	for o in sharks:
		o["t"] += dt
		if o["leap"] > 0.0:
			o["leap"] -= dt
			keep.append(o)
			continue
		if o["bites"] >= o["max"] or o["t"] > o["life"]:
			continue   # it dives away
		var e := _by_uid(o["uid"])
		if e == null or not _foe(e) or float(o["bitten"].get(e.uid, 0.0)) > G.time:
			var skip := {}
			for uid in o["bitten"]:
				if float(o["bitten"][uid]) > G.time:
					skip[uid] = true
			e = _nearest(o["x"], o["y"], 320.0, skip)
			o["uid"] = e.uid if e != null else -1
		if e == null:
			o["a"] += dt * 3.0   # circles where it is
			o["x"] += cos(o["a"]) * 50.0 * dt
			o["y"] += sin(o["a"]) * 50.0 * dt
			keep.append(o)
			continue
		var d := TB.dist_xy(o["x"], o["y"], e.x, e.y)
		if d < 6.0 + e.r * 0.6:
			o["bites"] += 1
			_hurt(e, o["dmg"] * o["mult"], p, o["crit"], "", { "kx": 0.0, "ky": -40.0 })
			for f in G.enemies.duplicate():
				if f != e and _foe(f) and TB.dist(f, e) < 18.0 + f.r:
					_hurt(f, o["dmg"] * o["mult"] * 0.5, p, false, "")
			if not _big(e) and e.hp > 0:
				e.stun_t = maxf(e.stun_t, 0.3)
			o["bitten"][e.uid] = G.time + 0.9
			o["leap"] = 0.35
			o["x"] = e.x
			o["y"] = e.y
			if o["frenzy"]:
				o["mult"] *= 1.15
			Fx.burst(e.x, e.y - 2, ["#ffffff", "#8fb8d0", "#d8443c"], 10, 60, 0.35)
			if o["bites"] == 1 or o["frenzy"] and o["bites"] % 3 == 0:
				_word(e.x, e.y - e.r - 18, "CHOMP!", "cyan")
			Snd.play("hatchet")
			_stat("bite")
		else:
			var a := atan2(e.y - o["y"], e.x - o["x"])
			o["a"] = a
			var spd := 200.0 if o["frenzy"] else 180.0
			o["x"] += cos(a) * spd * dt
			o["y"] += sin(a) * spd * dt
		keep.append(o)
	sharks = keep

static func _tick_twisters(p: Player, dt: float) -> void:
	var keep := []
	for o in twisters:
		o["t"] += dt
		var v := Vector2(o["vx"], o["vy"]).rotated(sin(o["t"] * 2.3) * 0.9 * dt)
		var nx: float = o["x"] + v.x * dt
		var ny: float = o["y"] + v.y * dt
		if _wall(nx, o["y"]):
			v.x = -v.x
			nx = o["x"]
		if _wall(o["x"], ny):
			v.y = -v.y
			ny = o["y"]
		o["x"] = nx
		o["y"] = ny
		o["vx"] = v.x
		o["vy"] = v.y
		var held: Dictionary = o["held"]
		var r: float = o["r"]
		# It lifts what it touches (not guardians, minis or champions: those it only hurts).
		for e in G.enemies:
			if held.size() >= MAX_HELD:
				break
			if _foe(e) and not _big(e) and not held.has(e.uid) and TB.dist_xy(e.x, e.y, o["x"], o["y"]) < r + e.r:
				held[e.uid] = randf() * TAU
				_stat("lifted")
		for uid in held.keys():
			var e := _by_uid(uid)
			if e == null or e.hp <= 0:
				held.erase(uid)
				continue
			held[uid] += dt * 7.0
			var tx: float = o["x"] + cos(held[uid]) * r * 0.55
			var ty: float = o["y"] + sin(held[uid]) * r * 0.3 - 4.0
			if _floor_ok(tx, ty):
				e.x = tx
				e.y = ty
			e.stun_t = maxf(e.stun_t, 0.1)
		o["tick"] -= dt
		if o["tick"] <= 0.0:
			o["tick"] = 0.3
			for e in G.enemies.duplicate():
				if _foe(e) and (held.has(e.uid) or TB.dist_xy(e.x, e.y, o["x"], o["y"]) < r + e.r):
					_hurt(e, o["dmg"] * 0.3, p, false, "")
		if o["sharks"]:   # SHARKNADO: land sharks drop out of it
			o["shark_t"] -= dt
			if o["shark_t"] <= 0.0:
				o["shark_t"] = 0.7
				_shark(o["x"], o["y"], o["dmg"] * 0.6, false, false, -1)
				if randf() < 0.3:
					_word(o["x"], o["y"] - r - 20, "SHARKNADO!", "cyan")
		if o["t"] >= o["life"]:
			# It dies down: everything it held is flung out and slams to the floor.
			for uid in held:
				var e := _by_uid(uid)
				if e != null and e.hp > 0:
					var out := Vector2(e.x - o["x"], e.y - o["y"]).normalized() * 60.0
					_hurt(e, o["dmg"], p, o["crit"], "", { "kx": out.x, "ky": out.y })
					if e.hp > 0:
						e.stun_t = maxf(e.stun_t, 0.6)
					Fx.burst(e.x, e.y + 2, ["#c8c0a8", "#8b8f9c"], 8, 50, 0.4)
			if not held.is_empty():
				_word(o["x"], o["y"] - r - 16, "SLAM!", "orange")
				G.add_shake(2)
				_stat("slam", held.size())
			continue
		keep.append(o)
	twisters = keep

static func _tick_disco(p: Player, dt: float) -> void:
	var o: Dictionary = discos[0]
	o["t"] += dt
	if o["t"] >= o["life"]:
		discos.clear()
		return
	o["a"] += o["spin"] * dt
	var c := Vector2(p.x, p.y - 30.0)
	var hit: Dictionary = o["hit"]
	var n: int = o["beams"]
	for e in G.enemies.duplicate():
		if not _foe(e) or float(hit.get(e.uid, 0.0)) > G.time:
			continue
		var de := TB.dist_xy(e.x, e.y, c.x, c.y)
		if de > o["len"] + e.r:
			continue
		for k in n:
			var ba: float = o["a"] + k * TAU / n
			if _seg_d(e.x, e.y - 4.0, c, c + Vector2.from_angle(ba) * o["len"]) < e.r + 3.0:
				hit[e.uid] = G.time + 0.3
				_hurt(e, o["dmg"] * 0.5, p, o["crit"], "pink")
				if e.hp > 0 and not _big(e):
					e.stun_t = maxf(e.stun_t, 0.2)   # it dances
					dancing[e.uid] = 0.6
				_stat("dance")
				break

static func _tick_yoyos(p: Player, dt: float) -> void:
	var keep := []
	for o in yoyos:
		var dir := Vector2.from_angle(o["a"])
		match o["phase"]:
			0:
				o["d"] += o["spd"] * dt
				var tip: Vector2 = Vector2(p.x, p.y - 3.0) + dir * float(o["d"])
				var touched := false
				for e in G.enemies:
					if _foe(e) and tip.distance_to(Vector2(e.x, e.y - 4.0)) < o["r"] + e.r:
						touched = true
						break
				if o["d"] >= o["max"] or touched or _wall(tip.x, tip.y):
					o["phase"] = 1
			1:
				o["spin"] += dt   # it walks the dog at the far end, grinding
				if o["spin"] >= 0.35:
					o["phase"] = 2
			2:
				o["d"] -= o["spd"] * 1.4 * dt
		if o["phase"] == 2 and o["d"] <= 0.0:
			continue   # back in your hand
		var head: Vector2 = Vector2(p.x, p.y - 3.0) + dir * float(o["d"])
		o["x"] = head.x
		o["y"] = head.y
		var hit: Dictionary = o["hit"]
		for e in G.enemies.duplicate():
			if not _foe(e) or float(hit.get(e.uid, 0.0)) > G.time:
				continue
			if head.distance_to(Vector2(e.x, e.y - 4.0)) < o["r"] + e.r:
				hit[e.uid] = G.time + (0.1 if o["phase"] == 1 else 0.2)
				_hurt(e, o["dmg"], p, o["crit"], "")
			elif _seg_d(e.x, e.y - 4.0, Vector2(p.x, p.y - 3.0), head) < 2.0 + e.r:
				hit[e.uid] = G.time + 0.25
				_hurt(e, o["dmg"] * 0.35, p, false, "")   # the string cuts
				_stat("string")
		keep.append(o)
	yoyos = keep

static func _tick_gates(p: Player, dt: float) -> void:
	var keep := []
	for o in gates:
		o["t"] += dt
		o["cd"] -= dt
		if o["shots"] > 0 and o["cd"] <= 0.0:
			o["shots"] -= 1
			o["cd"] = 0.3
			var e := _by_uid(o["uid"])
			var a: float = TB.ang_xy(o["ex"], o["ey"], e.x, e.y) if e != null and _foe(e) else o["a"]
			var b := Combat.spawn_pbullet(p, a, o["dmg"], "bolt", 1.4)
			if b != null:
				b.x = o["ex"]
				b.y = o["ey"]
			Fx.burst(o["ex"], o["ey"], ["#7ff0c8", "#ffffff"], 6, 40, 0.25)
			_stat("backstab")
		if o["t"] < o["life"] or o["shots"] > 0:
			keep.append(o)
	gates = keep

static func _tick_saws(p: Player, dt: float) -> void:
	var keep := []
	for o in saws:
		o["t"] += dt
		if not o["stuck"]:
			o["fly"] += dt
			var nx: float = o["x"] + o["vx"] * dt
			var ny: float = o["y"] + o["vy"] * dt
			var bump := false
			if _wall(nx, o["y"]):
				o["vx"] = -o["vx"]
				bump = true
			if _wall(o["x"], ny):
				o["vy"] = -o["vy"]
				bump = true
			if bump:
				if o["bounced"]:
					o["stuck"] = true   # it digs in where it is
					Snd.play("place")
				o["bounced"] = true
			else:
				o["x"] = nx
				o["y"] = ny
			if o["fly"] > 0.8:
				o["stuck"] = true
		else:
			o["life"] -= dt
			if o["life"] <= 0.0:
				continue
			if o["magnet"]:   # it creeps toward the nearest foe
				var e := _nearest(o["x"], o["y"], 200.0)
				if e != null:
					var to := Vector2(e.x - o["x"], e.y - o["y"]).normalized() * 30.0 * dt
					if not _wall(o["x"] + to.x, o["y"] + to.y):
						o["x"] += to.x
						o["y"] += to.y
		var hit: Dictionary = o["hit"]
		for e in G.enemies.duplicate():
			if _foe(e) and float(hit.get(e.uid, 0.0)) <= G.time and TB.dist_xy(e.x, e.y, o["x"], o["y"]) < o["r"] + e.r:
				hit[e.uid] = G.time + 0.2
				_hurt(e, o["dmg"] * (0.6 if o["stuck"] else 1.0), p, o["crit"] and not o["stuck"], "")
				if o["stuck"]:
					_stat("trap")
		keep.append(o)
	saws = keep

static func _tick_needles(p: Player, dt: float) -> void:
	var keep := []
	for o in needles:
		o["t"] += dt
		o["x"] += o["vx"] * dt
		o["y"] += o["vy"] * dt
		if o["t"] >= o["life"] or _wall(o["x"], o["y"]):
			continue
		var stuck := false
		for e in G.enemies:
			if _foe(e) and TB.dist_xy(e.x, e.y - 4.0, o["x"], o["y"]) < e.r + 3.0:
				_hurt(e, o["dmg"], p, o["crit"], "")
				pin(e, o["doom"], o["dmg"])
				stuck = true
				break
		if not stuck:
			keep.append(o)
	needles = keep

static func _tick_anvils(p: Player, dt: float) -> void:
	var keep := []
	for o in anvils:
		o["t"] += dt
		if not o["landed"]:
			if o["t"] >= o["fall"]:
				o["landed"] = true
				for e in G.enemies.duplicate():
					if _foe(e) and TB.dist_xy(e.x, e.y, o["x"], o["y"]) < o["r"] + e.r:
						_hurt(e, o["dmg"], p, o["crit"], "orange")
						if e.hp > 0 and not _big(e):
							e.stun_t = maxf(e.stun_t, 0.8)
						_stat("crush")
				Fx.burst(o["x"], o["y"] + 4, ["#c8c0a8", "#8b8f9c", "#ffffff"], 16, 80, 0.45)
				G.add_shake(4 if o["piano"] else 3)
				_word(o["x"], o["y"] - 30, "PLONK!" if o["piano"] else "CLANG!", "gold" if o["piano"] else "white")
				Snd.play("boom")
				if o["piano"]:   # notes fly from the wreck
					for k in 8:
						var b := Combat.spawn_pbullet(p, k * TAU / 8.0, o["dmg"] * 0.4, "spark")
						if b != null:
							b.x = o["x"]
							b.y = o["y"] - 6.0
			keep.append(o)
			continue
		o["life"] -= dt
		if o["life"] <= 0.0:
			Fx.burst(o["x"], o["y"], ["#8b8f9c", "#4e4a5e"], 8, 40, 0.3)
			continue
		var blocked := EBullets.take_near(o["x"], o["y"] - 6.0, o["r"] * 0.6, 16)   # cover: foes' shots stop on it
		if not blocked.is_empty():
			_stat("blocked", blocked.size())
			o["clang"] = 0.12
		o["clang"] = maxf(0.0, o["clang"] - dt)
		keep.append(o)
	anvils = keep

# ---------- Drawing (world_view) ----------
## On the floor: fins and their wake, saw traps, shadows of falling anvils, the anvils themselves.
static func draw_floor(ci: CanvasItem, t: float) -> void:
	for o in sharks:
		if o["leap"] > 0.0:
			continue
		var c := Vector2(o["x"], o["y"])
		var f := Vector2.from_angle(o["a"])
		for k in 3:   # the wake
			var w: Vector2 = c - f * (6.0 + k * 5.0)
			ci.draw_line(w + Vector2(-f.y, f.x) * (2.0 + k * 2.0), w - Vector2(-f.y, f.x) * (2.0 + k * 2.0), Color(0.75, 0.9, 1.0, 0.5 - k * 0.14), 1.0)
		ci.draw_colored_polygon(PackedVector2Array([c + f * 4.0, c - f * 5.0, c - f * 3.0 + Vector2(0, -9)]), Color(0.42, 0.52, 0.62))
		ci.draw_line(c + f * 4.0, c - f * 3.0 + Vector2(0, -9), Color(0.75, 0.85, 0.95), 1.0)
	for o in saws:
		var c := Vector2(o["x"], o["y"])
		var r: float = o["r"]
		if o["stuck"]:
			ci.draw_line(c + Vector2(-r - 2, 3), c + Vector2(r + 2, 3), Color(0.1, 0.08, 0.12, 0.6), 2.0)   # the slot it cut
		var spin: float = t * (24.0 if o["stuck"] else 18.0)
		ci.draw_circle(c, r, Color(0.62, 0.64, 0.7))
		for k in 8:
			var m := c + Vector2.from_angle(spin + k * TAU / 8.0) * r
			ci.draw_rect(Rect2(roundf(m.x) - 1, roundf(m.y) - 1, 2, 2), Color(0.9, 0.92, 0.98))
		ci.draw_circle(c, r * 0.35, Color(0.3, 0.3, 0.36))
		if o["stuck"] and o["life"] < 1.0 and fmod(t, 0.2) < 0.1:
			ci.draw_circle(c, r, Color(1, 1, 1, 0.35))
	for o in anvils:
		var c := Vector2(o["x"], o["y"])
		if not o["landed"]:
			var k := clampf(o["t"] / o["fall"], 0.0, 1.0)
			ci.draw_circle(c + Vector2(0, 4), o["r"] * (0.3 + 0.7 * k), Color(0, 0, 0, 0.15 + 0.25 * k))
			continue
		_draw_anvil(ci, c, o["piano"], o["r"], o["clang"] > 0.0)

static func _draw_anvil(ci: CanvasItem, c: Vector2, piano: bool, r: float, clang: bool) -> void:
	if piano:
		var w := r * 1.1
		ci.draw_rect(Rect2(c.x - w / 2, c.y - 14, w, 14), Color(0.08, 0.06, 0.1))
		ci.draw_rect(Rect2(c.x - w / 2 + 2, c.y - 6, w - 4, 4), Color(0.95, 0.93, 0.88))
		for k in int(w / 4):
			ci.draw_rect(Rect2(c.x - w / 2 + 3 + k * 4, c.y - 6, 1, 2), Color(0.1, 0.08, 0.12))
		ci.draw_rect(Rect2(c.x - w / 2, c.y - 16, w, 2), Color(0.3, 0.26, 0.34))
	else:
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-11, -12), c + Vector2(9, -12), c + Vector2(15, -9),
			c + Vector2(6, -6), c + Vector2(4, 0), c + Vector2(-6, 0), c + Vector2(-7, -6), c + Vector2(-11, -8)]), Color(0.28, 0.29, 0.33))
		ci.draw_line(c + Vector2(-11, -12), c + Vector2(9, -12), Color(0.62, 0.64, 0.7), 1.0)
		ci.draw_rect(Rect2(c.x - 8, c.y, 14, 2), Color(0.18, 0.18, 0.22))
	if clang:
		ci.draw_circle(c + Vector2(0, -8), 9.0, Color(1, 1, 0.8, 0.35))

## Over the people: leaping sharks, twisters, the disco ball and its light, yo-yos, portals,
## needles and the threads between pinned foes, falling anvils.
static func draw_over(ci: CanvasItem, t: float) -> void:
	for o in sharks:
		if o["leap"] <= 0.0:
			continue
		var k: float = 1.0 - o["leap"] / 0.35
		var c := Vector2(o["x"], o["y"] - sin(k * PI) * 14.0)
		var sgn := 1.0 if cos(o["a"]) >= 0.0 else -1.0
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-9 * sgn, 0), c + Vector2(-4 * sgn, -5), c + Vector2(7 * sgn, -4),
			c + Vector2(10 * sgn, 0), c + Vector2(7 * sgn, 3), c + Vector2(-4 * sgn, 3)]), Color(0.45, 0.56, 0.66))
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-9 * sgn, 0), c + Vector2(-13 * sgn, -5), c + Vector2(-12 * sgn, 4)]), Color(0.45, 0.56, 0.66))
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -4), c + Vector2(2 * sgn, -9), c + Vector2(4 * sgn, -4)]), Color(0.38, 0.48, 0.58))
		ci.draw_rect(Rect2(c.x - 3, c.y, 9 * sgn, 2), Color(0.92, 0.94, 0.96))   # the belly
		for i in 3:   # teeth
			ci.draw_rect(Rect2(c.x + (5 + i) * sgn, c.y - 1, 1, 1), Color(1, 1, 1))
		ci.draw_rect(Rect2(c.x + 5 * sgn, c.y - 3, 1, 1), Color(0.05, 0.05, 0.08))
	for o in twisters:
		var c := Vector2(o["x"], o["y"])
		var r: float = o["r"]
		var fade := clampf((o["life"] - o["t"]) * 3.0, 0.0, 1.0)
		for k in 7:   # stacked spinning rings, widest at the top
			var h := k * 6.0
			var rw := r * (0.25 + k * 0.12)
			var a0: float = t * (9.0 - k * 0.6) + k * 1.3
			var cc := c + Vector2(sin(t * 3.0 + k * 0.8) * 2.0, -h)
			ci.draw_arc(cc, rw, a0, a0 + 4.2, 14, Color(0.82, 0.85, 0.9, (0.75 - k * 0.07) * fade), 1.0)
		for k in 6:   # flying grit
			var a: float = t * 6.0 + k * 1.05
			var m := c + Vector2(cos(a) * r * 0.7, -10.0 - k * 4.0 + sin(a) * 3.0)
			ci.draw_rect(Rect2(roundf(m.x), roundf(m.y), 1, 1), Color(0.6, 0.55, 0.45, fade))
	if not discos.is_empty():
		var p := G.player
		var o: Dictionary = discos[0]
		var c := Vector2(p.x, p.y - 30.0)
		var n: int = o["beams"]
		var fade := clampf((o["life"] - o["t"]) * 3.0, 0.0, 1.0)
		for k in n:
			var ba: float = o["a"] + k * TAU / n
			var col: Color = BEAM_COLS[k % BEAM_COLS.size()]
			ci.draw_line(c, c + Vector2.from_angle(ba) * o["len"], Color(col.r, col.g, col.b, 0.28 * fade), 3.0)
			ci.draw_line(c, c + Vector2.from_angle(ba) * o["len"], Color(col.r, col.g, col.b, 0.7 * fade), 1.0)
		ci.draw_line(c + Vector2(0, -6), c + Vector2(0, -12), Color(0.6, 0.6, 0.7, fade), 1.0)
		ci.draw_circle(c, 6.0, Color(0.75, 0.78, 0.85, fade))
		for k in 10:   # the mirror facets glint in turn
			var m := c + Vector2(((k % 4) - 1.5) * 3.0, (int(k / 4) - 1) * 3.0)
			var on := int(t * 12.0 + k * 3) % 5 == 0
			ci.draw_rect(Rect2(roundf(m.x), roundf(m.y), 2, 2), Color(1, 1, 1, fade) if on else Color(0.5, 0.55, 0.65, fade))
	if not dancing.is_empty():
		for e in G.enemies:
			if dancing.has(e.uid):
				var hop := absf(sin(t * 10.0 + e.uid)) * 3.0
				_note(ci, Vector2(e.x + 6.0, e.y - e.r - 12.0 - hop), BEAM_COLS[e.uid % BEAM_COLS.size()])
	for o in yoyos:
		var p := G.player
		var head := Vector2(o["x"], o["y"])
		ci.draw_line(Vector2(p.x, p.y - 3.0), head, Color(0.95, 0.95, 0.9, 0.8), 1.0)
		ci.draw_circle(head, o["r"], Color(0.9, 0.3, 0.35))
		var s: float = t * 30.0
		ci.draw_line(head - Vector2.from_angle(s) * o["r"], head + Vector2.from_angle(s) * o["r"], Color(1, 0.9, 0.9), 1.0)
		ci.draw_circle(head, 1.5, Color(0.2, 0.08, 0.1))
	for o in gates:
		var k := clampf(1.0 - maxf(0.0, o["t"] - (o["life"] - 0.15)) / 0.15, 0.0, 1.0) if o["shots"] <= 0 else 1.0
		var grow := minf(1.0, o["t"] * 10.0) * k
		_portal(ci, Vector2(o["x"], o["y"]), grow, Color(0.75, 0.45, 1.0), t)
		_portal(ci, Vector2(o["ex"], o["ey"]), grow, Color(0.45, 1.0, 0.8), t)
	for o in needles:
		var c := Vector2(o["x"], o["y"])
		var f := Vector2(o["vx"], o["vy"]).normalized()
		ci.draw_line(c - f * 7.0, c, Color(0.85, 0.85, 0.9), 1.0)
		ci.draw_rect(Rect2(roundf(c.x) - 1, roundf(c.y) - 1, 2, 2), Color(0.9, 0.2, 0.3))
	if not pinned.is_empty():
		var pts := []
		for e in G.enemies:
			if pinned.has(e.uid):
				var top := Vector2(e.x, e.y - e.r - 6.0)
				ci.draw_line(top, top + Vector2(4, -6), Color(0.85, 0.85, 0.9), 1.0)
				ci.draw_rect(Rect2(roundf(top.x) + 3, roundf(top.y) - 8, 3, 3), Color(0.9, 0.2, 0.3))
				pts.append(Vector2(e.x, e.y - 4.0))
		for i in range(1, pts.size()):   # the threads that bind them
			ci.draw_line(pts[i - 1], pts[i], Color(0.7, 0.3, 0.85, 0.35 + 0.15 * sin(t * 6.0 + i)), 1.0)
	for o in anvils:
		if o["landed"]:
			continue
		var k := clampf(o["t"] / o["fall"], 0.0, 1.0)
		_draw_anvil(ci, Vector2(o["x"], o["y"] - (1.0 - k) * 220.0), o["piano"], o["r"], false)

static func _portal(ci: CanvasItem, c: Vector2, grow: float, col: Color, t: float) -> void:
	if grow <= 0.0:
		return
	for k in 3:
		var rr := (8.0 - k * 2.0) * grow
		var pts := PackedVector2Array()
		for i in 13:
			var a := i * TAU / 12.0
			pts.append(c + Vector2(cos(a) * rr * 0.6, sin(a) * rr))
		ci.draw_polyline(pts, Color(col.r, col.g, col.b, 0.9 - k * 0.25), 1.0)
	ci.draw_circle(c, 2.0 * grow, Color(1, 1, 1, 0.8))
	var s := Vector2.from_angle(t * 8.0) * 6.0 * grow
	ci.draw_rect(Rect2(roundf(c.x + s.x * 0.6), roundf(c.y + s.y), 1, 1), Color(1, 1, 1))

static func _note(ci: CanvasItem, at: Vector2, col: Color) -> void:
	ci.draw_rect(Rect2(roundf(at.x), roundf(at.y) - 6, 1, 7), col)
	ci.draw_rect(Rect2(roundf(at.x) - 2, roundf(at.y), 3, 2), col)
	ci.draw_rect(Rect2(roundf(at.x) + 1, roundf(at.y) - 6, 2, 1), col)
