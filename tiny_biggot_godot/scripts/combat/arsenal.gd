class_name Arsenal
extends RefCounted
## New attack types for the hundred new weapons (ROADMAP 4.6, his ask: weapons with ideas from
## Worms, GTA V, Saints Row: The Third, Risk of Rain, Enter the Gungeon and others; ideas only,
## every name, picture and number is this game's own).
##
## Part 1, MAYHEM (explosives and mischief), adds nine kinds:
##   grenade   thrown, bounces along the floor and off walls, blows when its fuse runs out
##   rocket    speeds up, blows on the first foe or wall
##   missile   a swarm of small missiles that each pick a foe and hunt it
##   sticky    sticks to the first foe or wall it meets, blows after its fuse
##   mortar    lobbed over walls onto the foe you aim at (a ring shows where it lands)
##   walker    a little bomb that runs at the nearest foe
##   strike    marks a line along your aim; bombs fall along it
##   dynamite  sticks that fizz, then blow; a blast sets off sticks near it
##   wave      a cone of force that hurls foes away (into walls, for more)
## and what a weapon of those kinds does differently comes from keys on its row (TWISTS):
## shrapnel, skips, cluster, freeze, heavy, crumbs, wobble, backblast, fireworks, guided, ramp,
## swarm, lock, rolldet, remote, zone, roll, pillar, bombs, push.
## Hooks and actions for weapons of the old kinds: wall_shrapnel (pellets burst on walls),
## piggy (gold you pick up fills a pig the next shot launches), and the actions ["plant"] (a
## charge on the foe, blowing a moment later) and ["puppet"] (the foe walks into others and bursts).
##
## +1 PROJECTILE STACKS WITHOUT LIMIT. A weapon here throws at most KEEP things at once (its swarm or
## bomb line grows a little); every projectile past that is merged into the ones thrown: +35% damage
## each, and a wider blast (up to twice as wide). So any count is drawn and simulated at the cost of
## a few objects, and live objects never pass MAX_LIVE (more are folded into the newest one's damage).
##
## What is thrown lives in `live` (not in the player's shot list): its own physics and pictures, and
## its blasts go through Combat.damage_enemy and on_hit_effects, so crits, ailments and every on-hit
## effect work with them. Everything here is emptied when the room changes.

const KINDS := ["grenade", "rocket", "missile", "sticky", "mortar", "walker", "strike", "dynamite", "wave"]
const KEEP := { "grenade": 3, "rocket": 3, "sticky": 2, "mortar": 3, "walker": 3, "dynamite": 5 }
## Keys a weapon row may carry to change what its kind does (the uniqueness report counts them).
const TWISTS := ["shrapnel", "skips", "cluster", "freeze", "heavy", "crumbs", "wobble", "backblast", "fireworks", "guided",
	"ramp", "swarm", "lock", "rolldet", "remote", "zone", "roll", "pillar", "bombs", "push", "radius"]
const MAX_LIVE := 48
const GRAV := 420.0

static var live: Array = []      # thrown things: { k, x, y, vx, vy, z, vz, t, fuse, dmg, rad, col, w, ... }
static var marks: Array = []     # warnings and charges: lock-ons, strike lines, planted charges, snow zones
static var flashes: Array = []   # short pictures: force cones, pillars of light
static var slams: Array = []     # foes hurled by a wave, watched for a wall: { e (WeakRef), t, dmg }
static var throws := 0           # throws of the weapon in hand (remote charges)
static var piggy := 0.0          # gold picked up towards the pig
static var _gold_seen := -1
static var _room: WeakRef = null
static var _shards := 0          # wall shards made this tick (a budget)
static var stats := {}           # how often each trick happened (tests/arsenal_test reads it)
static var _reach := {}          # how far a throw rolls for each 1 of speed, by fuse and weight (see _reach_k)

static func _stat(k: String, n: int = 1) -> void:
	stats[k] = stats.get(k, 0) + n

static func handles(kind: String) -> bool:
	return kind in KINDS

static func clear() -> void:
	throws = 0
	live.clear()
	marks.clear()
	flashes.clear()
	slams.clear()

## How a count of projectiles is spent: [things thrown, damage multiplier, blast multiplier].
static func spend(n: int, keep: int) -> Array:
	var shots := mini(n, keep)
	var extra := n - shots
	return [shots, 1.0 + 0.35 * extra, minf(2.0, 1.0 + 0.06 * sqrt(float(extra)))]

static func _col(w: Dictionary) -> String:
	return Weapons.TAG_COLS[w["tags"][0] if w["tags"].size() > 0 else "core"][0]

static func _add(o: Dictionary) -> void:
	if live.size() >= MAX_LIVE:
		var last: Dictionary = live[live.size() - 1]
		last["dmg"] += o["dmg"]   # past the cap: the damage is folded into the newest thing
		Effects.stats["merged_shots"] += 1
		return
	live.append(o)

# ---------- Firing (Combat.player_shoot) ----------
static func fire(p: Player, a: float, forced: bool) -> void:
	var w: Dictionary = p.weapon
	var k: String = w["kind"]
	throws += 1
	var n := Weapons.wcount(p)
	var sp: Array = spend(n + (2 if k == "dynamite" else 0), KEEP.get(k, 3))   # dynamite: a bundle of three
	var shots: int = sp[0]
	var dmg: float = Weapons.wdmg(p) * sp[1]
	var rad: float = minf(w.get("radius", 30) * sqrt(Weapons.wsize(p)) * p.bomb_r * sp[2], 140.0)
	var spread := Weapons.wspread(p)
	var speed := Weapons.wspd(p)
	var fuse := Weapons.wlife(p)
	var col := _col(w)
	var base := { "w": w["id"], "dmg": dmg, "rad": rad, "col": col, "t": 0.0, "crit": forced }
	match k:
		"grenade", "dynamite", "sticky":
			if k == "sticky" and w.get("remote", 0) > 0 and throws % int(w["remote"]) == 0 and _detonate_remote():
				return   # every Nth throw is the click (a throw, if nothing waits for it)
			var heavy: bool = w.get("heavy", false)
			var v := speed * (0.6 if heavy else 1.0)
			if k != "sticky":
				# Aimed: it comes to rest by the foe nearest your aim, no farther than the arm throws.
				v = clampf(_aim_dist(p, a) / _reach_k(fuse, heavy, w.get("skips", 0)), v * 0.15, v)
			for i in shots:
				var ang := a + (i - (shots - 1) / 2.0) * spread
				var o := base.duplicate()
				o.merge({ "k": k, "x": p.x + cos(ang) * 6, "y": p.y - 2 + sin(ang) * 6, "vx": cos(ang) * v, "vy": sin(ang) * v,
					"z": 4.0, "vz": 70.0 if k != "sticky" else 0.0, "fuse": fuse, "bounces": 0, "skips": w.get("skips", 0) })
				if k == "sticky":
					o["fly"] = 0.6
					o["remote"] = w.get("remote", 0) > 0
				if k == "dynamite":
					o["fuse"] = fuse * (1.0 + 0.15 * i)   # the sticks of a bundle blow one after another
				_add(o)
			Snd.play("hatchet")
		"rocket":
			if w.get("backblast", 0.0) > 0:
				_stat("backblast")
				_cone(p, a + PI, 60.0, deg_to_rad(70.0), Weapons.wdmg(p) * w["backblast"], 0.0, "#e8873a")
			for i in shots:
				var ang := a + (i - (shots - 1) / 2.0) * spread
				var o := base.duplicate()
				o.merge({ "k": "rocket", "x": p.x + cos(ang) * 8, "y": p.y - 3 + sin(ang) * 8, "a": ang, "spd": speed, "fuse": fuse,
					"seed": randf() * TAU, "hit": {} })
				_add(o)
			Snd.play("charge")
		"missile":
			if w.get("lock", 0.0) > 0:
				var best: Enemy = null
				for e in G.enemies:
					if e.targetable() and e.type != "dummy" and TB.dist(p, e) < 320 and (best == null or e.max_hp > best.max_hp):
						best = e
				if best == null:
					best = Combat.auto_target(p, 320)
				if best != null:
					var m := base.duplicate()
					m.merge({ "k": "lock", "e": weakref(best), "t": 0.0, "lock": w["lock"], "spd": speed })
					marks.append(m)
					Snd.play("charge")
				return
			var count := mini(int(w.get("swarm", 4)) + n - 1, 16)
			var dm := Weapons.wdmg(p) * (1.0 + 0.35 * maxi(0, int(w.get("swarm", 4)) + n - 1 - 16))
			var foes := []
			for e in G.enemies:
				if e.targetable() and e.type != "dummy":
					foes.append(e)
			foes.shuffle()
			for i in count:
				var ang := a + randf_range(-1.3, 1.3)
				var o := base.duplicate()
				o.merge({ "k": "missile", "x": p.x, "y": p.y - 4, "a": ang, "spd": speed * 0.6, "fuse": fuse, "dmg": dm,
					"turn": w["homing"] + p.homing, "tgt": weakref(foes[i % foes.size()]) if not foes.is_empty() else null })
				_add(o)
			Snd.play("charge")
		"mortar":
			var tgt := Combat.auto_target(p, w.get("range", 220))
			var at := Vector2(tgt.x, tgt.y) if tgt != null else Vector2(p.x + cos(a) * 120, p.y + sin(a) * 120)
			for i in shots:
				var off := Vector2.ZERO if i == 0 else Vector2.from_angle(TAU * i / shots + a) * 26.0
				var to := RiftBosses._inside(at + off)
				var o := base.duplicate()
				o.merge({ "k": "mortar", "x0": p.x, "y0": p.y - 6, "x": to.x, "y": to.y, "fuse": fuse * (1.0 + 0.1 * i), "zone": w.get("zone", "") })
				_add(o)
			Snd.play("boom")
		"walker":
			for i in shots:
				var ang := a + (i - (shots - 1) / 2.0) * spread
				var o := base.duplicate()
				o.merge({ "k": "walker", "x": p.x + cos(ang) * 8, "y": p.y + sin(ang) * 8, "a": ang, "spd": speed, "fuse": fuse,
					"roll": w.get("roll", 0), "bounces": 0 })
				_add(o)
			Snd.play("select")
		"strike":
			if w.get("pillar", false):
				var best: Enemy = null
				for e in G.enemies:
					if e.targetable() and e.type != "dummy" and TB.dist(p, e) < w.get("range", 300) and (best == null or e.hp > best.hp):
						best = e
				if best != null:
					var m := base.duplicate()
					m.merge({ "k": "paint", "e": weakref(best), "t": 0.0, "fuse": fuse })
					marks.append(m)
					Snd.play("beam")
				return
			var bombs := mini(int(w.get("bombs", 5)) + n - 1, 12)
			var dmg2 := Weapons.wdmg(p) * (1.0 + 0.35 * maxi(0, int(w.get("bombs", 5)) + n - 1 - 12))
			var pts := []
			for i in bombs:
				pts.append(RiftBosses._inside(Vector2(p.x, p.y) + Vector2.from_angle(a) * (40.0 + 34.0 * i)))
			var m := base.duplicate()
			m.merge({ "k": "line", "pts": pts, "t": 0.0, "fuse": fuse, "dmg": dmg2, "next": 0 })
			marks.append(m)
			Snd.play("charge")
		"wave":
			var extra := maxi(0, n - 1)
			var arc := minf(TAU, deg_to_rad(w.get("arc", 70)) + deg_to_rad(12.0) * extra)
			var power := 1.0 + 0.35 * maxi(0, extra - 24)
			_cone(p, a, Weapons.wrange(p), arc, Weapons.wdmg(p) * power, w.get("push", 280), _col(w), forced)
			Snd.play("beam")

## Rolling sets off sticky bombs that wait for it (Combat.on_roll_start).
static func on_roll(p: Player) -> void:
	if p.weapon == null or not p.weapon.get("rolldet", false):
		return
	for o in live:
		if o["k"] == "sticky" and not o.get("remote", false):
			o["fuse"] = minf(o["fuse"], 0.05)

## The click: every remote charge that has landed blows. False when none waits.
static func _detonate_remote() -> bool:
	var charges := []
	for o in live:
		if o["k"] == "sticky" and o.get("remote", false) and o.get("fly", 0.0) <= 0:
			charges.append(o)
	for i in charges.size():
		var o: Dictionary = charges[i]
		o["remote"] = false
		o["fuse"] = 0.06 * i                    # one after another, quickly
		o["dmg"] *= 1.0 + 0.1 * (charges.size() - 1)   # each one stronger for the others
	if charges.is_empty():
		return false
	_stat("remote")
	Fx.float_text(G.player.x, G.player.y - 18, "CLICK", "orange")
	Snd.play("lock")
	return true

## How far to throw: to the foe nearest your aim (within about 35 degrees of it), else as far as it goes.
static func _aim_dist(p: Player, a: float) -> float:
	var best := 1e9
	for e in G.enemies:
		if e.targetable() and absf(TB.wrap_ang(TB.ang_to(p, e) - a)) < 0.6:
			best = minf(best, TB.dist(p, e))
	return best

## How far a throw goes, for each 1 of speed, before its fuse ends (no walls in the way). Worked out once
## for each fuse, weight and number of skips by playing the hops below.
static func _reach_k(fuse: float, heavy: bool, skips: int) -> float:
	var key := "%.2f/%s/%d" % [fuse, heavy, skips]
	if not _reach.has(key):
		var o := { "z": 4.0, "vz": 70.0, "vx": 1.0, "vy": 0.0, "skips": skips }
		var x := 0.0
		var t := 0.0
		while t < fuse:
			_hop(o, TB.DT, heavy)
			x += o["vx"] * TB.DT
			t += TB.DT
		_reach[key] = maxf(x, 0.05)
	return _reach[key]

## A cone of force (the repulsor) or of fire behind you (a backblast).
static func _cone(p: Player, a: float, reach: float, arc: float, dmg: float, push: float, col: String, crit := false) -> void:
	for e in G.enemies.duplicate():
		if not e.targetable():
			continue
		var d := TB.dist(p, e)
		if d > reach + e.r or absf(TB.wrap_ang(TB.ang_to(p, e) - a)) > arc / 2 + 0.1:
			continue
		var ea := TB.ang_to(p, e)
		var kx := cos(ea) * push
		var ky := sin(ea) * push
		var c := Combat.damage_enemy(e, dmg, { "kx": kx, "ky": ky, "force_crit": crit })
		Combat.on_hit_effects(e, dmg, c, p, null)
		if push > 0 and not e.is_boss():
			slams.append({ "e": weakref(e), "t": 0.45, "dmg": dmg * 1.5 })
	flashes.append({ "k": "cone", "x": p.x, "y": p.y - 2, "a": a, "arc": arc, "reach": reach, "t": 0.22, "col": col })

# ---------- Blasts ----------
static func blast(x: float, y: float, dmg: float, rad: float, col: String, crit := false, quiet := false) -> int:
	var p := G.player
	var hits := 0
	_stat("blast")
	for e in G.enemies.duplicate():
		if not e.targetable() or TB.dist_xy(e.x, e.y, x, y) >= rad + e.r:
			continue
		var a := TB.ang_xy(x, y, e.x, e.y)
		var c := Combat.damage_enemy(e, dmg, { "boom": true, "kx": cos(a) * 110, "ky": sin(a) * 110, "force_crit": crit,
			"silent": hits > 2 })
		Combat.on_hit_effects(e, dmg, c, p, null)
		hits += 1
	Vfx.blast(x, y, rad, col)
	Fx.burst(x, y, [col, "#f2c94c", "#fffbe0"], 8 + roundi(rad / 5), 60 + rad, 0.3)
	Afx.dust(x, y)
	G.add_shake(2 + rad / 18.0)
	if not quiet:
		Snd.play("boom")
	# Crates in the blast break.
	var room := G.room
	for c in range(floori((x - rad) / TB.TS), floori((x + rad) / TB.TS) + 1):
		for r in range(floori((y - rad) / TB.TS), floori((y + rad) / TB.TS) + 1):
			if room.tile(c, r) == World.T_CRATE:
				Combat.hit_crate(room, c, r, dmg)
	return hits

## The end of a thrown thing: its blast and what its weapon adds to it.
static func _boom(o: Dictionary) -> void:
	var w := Weapons.by_id(o["w"]) if Weapons._by_id.has(o["w"]) else {}
	var dmg: float = o["dmg"] * (1.0 + w.get("ramp", 0.0) * o["t"] if o["k"] == "rocket" else 1.0)
	blast(o["x"], o["y"], dmg, o["rad"], o["col"], o.get("crit", false))
	if w.is_empty():
		return
	var p := G.player
	var n: int = w.get("shrapnel", 0)
	if n > 0:
		_stat("shrapnel")
	for i in n:
		Combat._raw_shot(o["x"], o["y"], float(i) / n * TAU + randf() * 0.3, 210, o["dmg"] * 0.35, 0.4, 2.0, 0, "spark", {})
	if w.get("freeze", 0.0) > 0:
		_stat("freeze")
		for e in G.enemies:
			if e.targetable() and not e.is_boss() and TB.dist_xy(e.x, e.y, o["x"], o["y"]) < o["rad"] + e.r:
				e.stun_t = maxf(e.stun_t, w["freeze"])
				e.chill_t = maxf(e.chill_t, w["freeze"] + 2.0)
		Vfx.nova(o["x"], o["y"], o["rad"], "frost")
	if w.get("crumbs", 0) > 0 and o["k"] == "grenade":
		_stat("crumbs")
		for i in int(w["crumbs"]):
			Combat.drop_pickup("coin", o["x"], o["y"])
		if randf() < 0.1:
			Combat.drop_pickup("heart", o["x"], o["y"])
	if w.get("cluster", 0) > 0 and o["k"] == "grenade":
		_stat("seed", int(w["cluster"]))
		for i in int(w["cluster"]):
			var a: float = float(i) / float(w["cluster"]) * TAU + randf() * 0.4
			_add({ "k": "seed", "w": "", "x": o["x"], "y": o["y"], "vx": cos(a) * randf_range(70, 130), "vy": sin(a) * randf_range(70, 130),
				"z": 2.0, "vz": 90.0, "fuse": randf_range(0.35, 0.7), "dmg": o["dmg"] * 0.5, "rad": o["rad"] * 0.45, "col": o["col"],
				"t": 0.0, "bounces": 0, "skips": 0 })
	if o["k"] == "dynamite":
		# A blast sets off every stick near it, each one harder.
		for q in live:
			if q != o and q["k"] == "dynamite" and q["fuse"] > 0.12 and TB.dist_xy(q["x"], q["y"], o["x"], o["y"]) < o["rad"] + 24:
				_stat("chain")
				q["fuse"] = 0.12
				q["dmg"] *= 1.25
	if o.get("zone", "") == "frost":
		_stat("snow")
		marks.append({ "k": "snow", "x": o["x"], "y": o["y"], "r": o["rad"] + 12, "t": 3.0, "tick": 0.0 })

# ---------- Every tick (Hazards.update) ----------
static func tick(room: Room, dt: float) -> void:
	if _room == null or _room.get_ref() != room:
		clear()
		_room = weakref(room)
	var p := G.player
	_piggy_tick(p)
	_shards = 0
	if live.is_empty() and marks.is_empty() and flashes.is_empty() and slams.is_empty():
		return
	var keep := []
	var done := []
	for o in live:
		o["t"] += dt
		if _move(o, p, room, dt):
			keep.append(o)
		else:
			done.append(o)
	live = keep
	for o in done:
		_boom(o)
	_tick_marks(p, dt)
	var kf := []
	for f in flashes:
		f["t"] -= dt
		if f["t"] > 0:
			kf.append(f)
	flashes = kf
	var ks := []
	for s in slams:
		s["t"] -= dt
		var e: Enemy = s["e"].get_ref()
		if e == null or e.hp <= 0 or s["t"] <= 0:
			continue
		var mode := World.M_FLYER if e.d.get("fly", false) else World.M_WALKER
		if absf(e.kx) + absf(e.ky) > 20 and World.hits_solid(room, e.x + e.kx * dt * 2, e.y + e.ky * dt * 2, e.r, mode):
			var c := Combat.damage_enemy(e, s["dmg"], { "col": "orange" })
			Combat.on_hit_effects(e, s["dmg"], c, p, null)
			Fx.float_text(e.x, e.y - e.r - 10, "SLAM", "orange")
			_stat("slam")
			Afx.dust(e.x, e.y)
			G.add_shake(3)
			Snd.play("hit")
			continue
		ks.append(s)
	slams = ks

## Moves one thrown thing; false when it is spent (it blows next).
static func _move(o: Dictionary, p: Player, room: Room, dt: float) -> bool:
	match o["k"]:
		"grenade", "seed", "dynamite":
			o["fuse"] -= dt
			_bounce(o, room, dt, o["k"] == "grenade" and Weapons._by_id.get(o["w"], {}).get("heavy", false))
			if o["k"] != "seed" and o["z"] < 3.0 and absf(o["vx"]) + absf(o["vy"]) > 4.0:
				# Rolling into a foe's feet, it stops there.
				for e in G.enemies:
					if e.targetable() and TB.dist_xy(e.x, e.y, o["x"], o["y"]) < e.r + 3:
						o["vx"] = 0.0
						o["vy"] = 0.0
						break
			return o["fuse"] > 0
		"sticky":
			o["fuse"] -= dt if not o.get("remote", false) else 0.0
			if o.get("fly", 0.0) > 0:
				o["fly"] -= dt
				var nx: float = o["x"] + o["vx"] * dt
				var ny: float = o["y"] + o["vy"] * dt
				if World.solid(room, floori(nx / TB.TS), floori(ny / TB.TS), World.M_BULLET):
					o["fly"] = 0.0   # stuck to the wall
				else:
					o["x"] = nx
					o["y"] = ny
					for e in G.enemies:
						if e.targetable() and TB.dist_xy(e.x, e.y, nx, ny) < e.r + 3:
							o["on"] = weakref(e)
							o["ox"] = nx - e.x
							o["oy"] = ny - e.y
							o["fly"] = 0.0
							_stat("stick")
							Snd.play("place")
							break
			elif o.has("on"):
				var e: Enemy = o["on"].get_ref()
				if e != null and e.hp > 0:
					o["x"] = e.x + o["ox"]
					o["y"] = e.y + o["oy"]
				else:
					o.erase("on")   # its foe is gone: it drops to the floor
			if o.get("remote", false) and o["t"] > 30.0:
				o["remote"] = false
				o["fuse"] = 0.0
			return o["fuse"] > 0
		"rocket":
			return _rocket(o, p, room, dt)
		"missile":
			return _missile(o, room, dt)
		"mortar":
			o["fuse"] -= dt
			if o["fuse"] <= 0:
				_stat("shell")
			return o["fuse"] > 0
		"walker":
			return _walker(o, room, dt)
		"pig":
			o["fuse"] -= dt
			var nx: float = o["x"] + o["vx"] * dt
			var ny: float = o["y"] + o["vy"] * dt
			if World.solid(room, floori(nx / TB.TS), floori(ny / TB.TS), World.M_BULLET):
				return false
			o["x"] = nx
			o["y"] = ny
			for e in G.enemies:
				if e.targetable() and TB.dist_xy(e.x, e.y, nx, ny) < e.r + 8:
					return false
			return o["fuse"] > 0
	return false

## A thrown thing on the floor: tossed in an arc, bouncing off the floor and off walls.
static func _bounce(o: Dictionary, room: Room, dt: float, heavy: bool) -> void:
	if _hop(o, dt, heavy):
		# A skipping charge: a small blast every time it hops.
		_stat("skip")
		blast(o["x"], o["y"], o["dmg"] * 0.4, o["rad"] * 0.6, o["col"], false, true)
	var nx: float = o["x"] + o["vx"] * dt
	var ny: float = o["y"] + o["vy"] * dt
	if World.solid(room, floori(nx / TB.TS), floori(o["y"] / TB.TS), World.M_BULLET):
		o["vx"] = -o["vx"] * 0.6
		nx = o["x"]
	if World.solid(room, floori(o["x"] / TB.TS), floori(ny / TB.TS), World.M_BULLET):
		o["vy"] = -o["vy"] * 0.6
		ny = o["y"]
	o["x"] = nx
	o["y"] = ny

## Up and down: the arc, the hops (lower each time), then rolling to a stop (a heavy thing does not
## hop, it slides). True when a skipping charge hops.
static func _hop(o: Dictionary, dt: float, heavy: bool) -> bool:
	o["vz"] -= GRAV * dt
	o["z"] += o["vz"] * dt
	if o["z"] > 0:
		return false
	o["z"] = 0.0
	if o["vz"] < -40 and not heavy:
		o["vz"] = -o["vz"] * 0.45
		o["vx"] *= 0.7
		o["vy"] *= 0.7
		if o["skips"] > 0:
			o["skips"] -= 1
			o["vz"] = 120.0
			o["vx"] *= 1.3
			o["vy"] *= 1.3
			return true
	else:
		o["vz"] = 0.0
		var f := pow(0.02 if heavy else 0.15, dt)
		o["vx"] *= f
		o["vy"] *= f
	return false

static func _rocket(o: Dictionary, p: Player, room: Room, dt: float) -> bool:
	o["fuse"] -= dt
	var w: Dictionary = Weapons._by_id.get(o["w"], {})
	o["spd"] = minf(o["spd"] * pow(2.2, dt), 430.0)
	if w.get("wobble", 0.0) > 0:
		o["a"] += sin(o["t"] * 9.0 + o["seed"]) * w["wobble"] * 4.0 * dt
	if w.get("guided", false):
		# Steered by your aim: it turns toward the point you aim at.
		var at := Vector2(p.x, p.y) + Vector2.from_angle(p.aim_a) * 400.0
		var want := TB.ang_xy(o["x"], o["y"], at.x, at.y)
		o["a"] += clampf(TB.wrap_ang(want - o["a"]), -4.0 * dt, 4.0 * dt)
		_stat("guided")
	var nx: float = o["x"] + cos(o["a"]) * o["spd"] * dt
	var ny: float = o["y"] + sin(o["a"]) * o["spd"] * dt
	if randf() < 0.6:
		Fx.particle(o["x"] - cos(o["a"]) * 4, o["y"] - sin(o["a"]) * 4, randf_range(-10, 10), randf_range(-10, 10), 0.35,
			TB.pick(["#8b8f9c", "#4e4a5e", "#f2c94c"]), 2)
	if World.solid(room, floori(nx / TB.TS), floori(ny / TB.TS), World.M_BULLET):
		return false if not w.get("fireworks", 0) else _star(o)
	o["x"] = nx
	o["y"] = ny
	for e in G.enemies:
		if not e.targetable() or TB.dist_xy(e.x, e.y, nx, ny) >= e.r + 4:
			continue
		if w.get("fireworks", 0) > 0:
			# Festival rockets fly through foes (half damage each), and burst when their flight ends.
			if not o["hit"].has(e.uid):
				o["hit"][e.uid] = true
				var c := Combat.damage_enemy(e, o["dmg"] * 0.5, {})
				Combat.on_hit_effects(e, o["dmg"] * 0.5, c, p, null)
			continue
		return false
	if o["fuse"] <= 0:
		return false if not w.get("fireworks", 0) else _star(o)
	return true

## A festival rocket's end: a star of sparks (no blast).
static func _star(o: Dictionary) -> bool:
	var w: Dictionary = Weapons._by_id.get(o["w"], {})
	var n: int = w.get("fireworks", 12)
	_stat("star")
	var cols := ["#e86fb4", "#6fd3e0", "#f2c94c", "#b8e05a"]
	for i in n:
		Combat._raw_shot(o["x"], o["y"], float(i) / n * TAU, 170, o["dmg"] * 0.45, 0.55, 2.2, 1, "spark", {})
	Fx.burst(o["x"], o["y"], cols, 24, 120, 0.5)
	Snd.play("bolt")
	o["dmg"] = 0.0
	o["rad"] = 4.0   # the blast that follows is only a pop
	return false

static func _missile(o: Dictionary, room: Room, dt: float) -> bool:
	o["fuse"] -= dt
	if o["t"] < 0.25:
		o["spd"] = minf(o["spd"] + 300 * dt, 260.0)
	else:
		o["spd"] = minf(o["spd"] + 500 * dt, 300.0)
		var e: Enemy = o["tgt"].get_ref() if o["tgt"] != null else null
		if e == null or e.hp <= 0 or not e.targetable():
			e = Combat.nearest_enemy(o["x"], o["y"], 300)
			o["tgt"] = weakref(e) if e != null else null
		if e != null:
			_stat("hunt")
			var want := TB.ang_xy(o["x"], o["y"], e.x, e.y)
			var turn: float = o["turn"] * dt
			o["a"] += clampf(TB.wrap_ang(want - o["a"]), -turn, turn)
	var nx: float = o["x"] + cos(o["a"]) * o["spd"] * dt
	var ny: float = o["y"] + sin(o["a"]) * o["spd"] * dt
	if randf() < 0.4:
		Fx.particle(o["x"], o["y"], 0, 0, 0.25, "#c9c2a8", 1)
	if World.solid(room, floori(nx / TB.TS), floori(ny / TB.TS), World.M_BULLET):
		return false
	o["x"] = nx
	o["y"] = ny
	for e in G.enemies:
		if e.targetable() and TB.dist_xy(e.x, e.y, nx, ny) < e.r + 3:
			return false
	return o["fuse"] > 0

static func _walker(o: Dictionary, room: Room, dt: float) -> bool:
	o["fuse"] -= dt
	var a: float = o["a"]
	if o["roll"] == 0:
		# A wind-up mouse: to the nearest foe.
		var e := Combat.nearest_enemy(o["x"], o["y"], 400)
		if e != null:
			_stat("mouse")
			var want := TB.ang_xy(o["x"], o["y"], e.x, e.y)
			o["a"] = a + clampf(TB.wrap_ang(want - a), -6.0 * dt, 6.0 * dt)
	var nx: float = o["x"] + cos(o["a"]) * o["spd"] * dt
	var ny: float = o["y"] + sin(o["a"]) * o["spd"] * dt
	var bx := World.solid(room, floori(nx / TB.TS), floori(o["y"] / TB.TS), World.M_WALKER)
	var by := World.solid(room, floori(o["x"] / TB.TS), floori(ny / TB.TS), World.M_WALKER)
	if bx or by:
		if o["roll"] > 0:
			# A keg bounces off walls (twice), then breaks.
			_stat("keg_bounce")
			o["bounces"] += 1
			if o["bounces"] > int(o["roll"]):
				return false
			var v := Vector2.from_angle(o["a"])
			if bx:
				v.x = -v.x
			if by:
				v.y = -v.y
			o["a"] = v.angle()
			Snd.play("hit")
		else:
			o["a"] += PI / 2 * (1 if randf() < 0.5 else -1)   # a mouse turns aside
		return o["fuse"] > 0
	o["x"] = nx
	o["y"] = ny
	for e in G.enemies:
		if e.targetable() and TB.dist_xy(e.x, e.y, nx, ny) < e.r + 5:
			return false
	return o["fuse"] > 0

static func _tick_marks(p: Player, dt: float) -> void:
	var keep := []
	for m in marks:
		m["t"] += dt
		match m["k"]:
			"lock":
				# A lock-on: the reticle closes on the foe, then a missile that cannot miss.
				var e: Enemy = m["e"].get_ref()
				if e == null or e.hp <= 0:
					continue
				if m["t"] >= m["lock"]:
					_stat("lock")
					_add({ "k": "missile", "w": m["w"], "x": p.x, "y": p.y - 4, "a": TB.ang_to(p, e), "spd": 200.0, "fuse": 3.0,
						"dmg": m["dmg"], "rad": m["rad"], "col": m["col"], "t": 0.3, "turn": 14.0, "tgt": weakref(e) })
					Snd.play("bolt")
					continue
			"paint":
				# Painting a foe for the sky: then the pillar.
				var e: Enemy = m["e"].get_ref()
				if e == null or e.hp <= 0:
					continue
				m["x"] = e.x
				m["y"] = e.y
				if m["t"] >= m["fuse"]:
					var c := Combat.damage_enemy(e, m["dmg"], { "force_crit": m.get("crit", false), "col": "cyan" })
					Combat.on_hit_effects(e, m["dmg"], c, p, null)
					for o in G.enemies:
						if o.targetable() and not o.is_boss() and TB.dist(o, e) < 50 + o.r:
							o.stun_t = maxf(o.stun_t, 1.0)
					flashes.append({ "k": "pillar", "x": e.x, "y": e.y, "t": 0.35 })
					_stat("pillar")
					Vfx.nova(e.x, e.y, 50.0, "frost")
					G.add_shake(6)
					Snd.play("beam")
					continue
			"line":
				# A line of bombs: shown for the fuse, then they fall one after another.
				if m["t"] >= m["fuse"]:
					var k: int = m["next"]
					var gap := 0.11
					while k < m["pts"].size() and m["t"] >= m["fuse"] + k * gap:
						_stat("bomb")
						var pt: Vector2 = m["pts"][k]
						blast(pt.x, pt.y, m["dmg"], m["rad"], m["col"], m.get("crit", false) and k == 0, k > 0)
						k += 1
					m["next"] = k
					if k >= m["pts"].size():
						continue
			"plant":
				# A charge on a foe: it blows a moment later (wherever the foe went).
				var e: Enemy = m["e"].get_ref()
				if e != null and e.hp > 0:
					m["x"] = e.x
					m["y"] = e.y
				if m["t"] >= m["fuse"]:
					_stat("plant")
					blast(m["x"], m["y"], m["dmg"], m["rad"], "#e8873a", false, true)
					continue
			"snow":
				# A snowstorm: foes in it are chilled.
				m["tick"] -= dt
				if m["tick"] <= 0:
					m["tick"] = 0.25
					for e in G.enemies:
						if e.targetable() and TB.dist_xy(e.x, e.y, m["x"], m["y"]) < m["r"] + e.r:
							e.chill_t = maxf(e.chill_t, 1.0)
				if m["t"] >= 3.0:
					continue
		keep.append(m)
	marks = keep

# ---------- Old kinds, new tricks ----------
## A pellet that hits a wall bursts into shards (Combat, the wall branch). A budget keeps a huge
## count of pellets from flooding the screen: past it the shards are not made.
static func wall_shards(b: PBullet, p: Player) -> void:
	var n := int(p.g("wall_shrapnel"))
	if n <= 0 or b.kind == "spark" or _shards > 24 or G.pbullets.size() + G.new_pbullets.size() > Effects.pbullet_cap() / 2:
		return
	_shards += n
	_stat("shard", n)
	var back := atan2(-b.vy, -b.vx)
	for i in n:
		# Into the list of new shots: the update is still walking the live ones.
		var s := Combat.new_pbullet()
		var sa := back + (i - (n - 1) / 2.0) * 0.5
		s.x = b.x - b.vx * 0.01
		s.y = b.y - b.vy * 0.01
		s.vx = cos(sa) * 190.0
		s.vy = sin(sa) * 190.0
		s.dmg = b.dmg * 0.4
		s.life = 0.3
		s.max_life = 0.3
		s.r = 2.0
		s.kind = "spark"
		G.new_pbullets.append(s)

## ["plant", delay, dmg_mult, radius]: a charge on the foe (one a foe: a second one adds to it).
static func plant(e: Enemy, delay: float, dmg: float, rad: float) -> void:
	if e == null or e.hp <= 0:
		return
	for m in marks:
		if m["k"] == "plant" and m["e"].get_ref() == e:
			m["dmg"] += dmg
			return
	marks.append({ "k": "plant", "e": weakref(e), "x": e.x, "y": e.y, "t": 0.0, "fuse": delay, "dmg": dmg, "rad": rad })

## ["puppet", seconds]: the foe stops hurting you and walks into another foe, then bursts.
static func puppet(e: Enemy, secs: float) -> void:
	if e == null or e.hp <= 0 or e.is_boss() or e.d.get("mini", false) or e.d.get("champion", false) or e.type == "dummy":
		return
	if e.puppet_t <= 0:
		_stat("puppet")
		Fx.float_text(e.x, e.y - e.r - 10, "PUPPET", "purple")
	e.puppet_t = maxf(e.puppet_t, secs)

## A puppet's turn (Combat.update_enemies, instead of its own AI).
static func puppet_tick(e: Enemy, dt: float) -> void:
	e.puppet_t -= dt
	var other: Enemy = null
	var bd := 1e9
	for o in G.enemies:
		if o != e and o.targetable() and o.puppet_t <= 0:
			var d := TB.dist(o, e)
			if d < bd:
				bd = d
				other = o
	if other != null:
		Combat.steer(e, other.x, other.y, maxf(e.speed, 40.0) * 1.4, dt, World.M_FLYER if e.d.get("fly", false) else World.M_WALKER)
	if (other != null and bd < e.r + other.r + 2) or e.puppet_t <= 0:
		e.puppet_t = 0.0
		var p := G.player
		blast(e.x, e.y, Weapons.wdmg(p) * 2.0, 34.0, "#a35bd6")
		if e.hp > 0:
			var c := Combat.damage_enemy(e, e.hp * 2.0 + 1.0, { "no_crit": true, "no_mult": true, "silent": true })
			Combat.on_hit_effects(e, 0.0, c, p, null)

## The piggy bank: gold you pick up fills it; when full, the next shot is the pig.
static func _piggy_tick(p: Player) -> void:
	var g: int = G.run_stats.get("gold", 0)
	if _gold_seen < 0 or g < _gold_seen:
		_gold_seen = g
	if p.g("piggy") > 0:
		piggy += g - _gold_seen
	_gold_seen = g

static func piggy_shot(p: Player, a: float) -> bool:
	var need := p.g("piggy")
	if need <= 0 or piggy < need:
		return false
	piggy -= need
	_stat("pig")
	var dmg := Weapons.wdmg(p) * 3.0 * (1.0 + p.gold / 100.0 * 0.1)
	_add({ "k": "pig", "w": p.weapon["id"], "x": p.x, "y": p.y - 6, "vx": cos(a) * 170, "vy": sin(a) * 170, "fuse": 1.4,
		"dmg": dmg, "rad": 70.0, "col": "#f2c94c", "t": 0.0 })
	Fx.float_text(p.x, p.y - 20, "OINK!", "pink", true)
	Snd.play("coin")
	return true

# ---------- Drawing ----------
## On the floor (world_view, with the goo): things lying and rolling, warnings, snow.
static func draw_floor(ci: CanvasItem, t: float) -> void:
	if live.is_empty() and marks.is_empty():
		return
	var blink := floori(t * 10) % 2 == 0
	for m in marks:
		match m["k"]:
			"line":
				if m["t"] < m["fuse"]:
					var k: float = m["t"] / m["fuse"]
					for i in m["pts"].size():
						var pt: Vector2 = m["pts"][i]
						Afx.landing(ci, pt.x, pt.y, m["rad"], k, Afx.C_WARN, t)
						if i > 0 and blink:
							var q: Vector2 = m["pts"][i - 1]
							ci.draw_line(q, pt, Color(1, 0.54, 0.54, 0.5), 1.0)
			"snow":
				var fade := clampf(3.0 - m["t"], 0.0, 1.0)
				ci.draw_circle(Vector2(m["x"], m["y"]), m["r"], Color(0.78, 0.94, 1.0, 0.16 * fade))
				for i in 10:
					var a := i * 2.4 + t * 0.7
					var rr: float = fmod(i * 7.3 + t * 9.0, m["r"])
					ci.draw_rect(Rect2(roundf(m["x"] + cos(a) * rr), roundf(m["y"] + sin(a) * rr * 0.7), 1, 1), Color(1, 1, 1, 0.8 * fade))
	for o in live:
		match o["k"]:
			"grenade", "seed", "dynamite", "sticky":
				var x: float = o["x"]
				var y: float = o["y"]
				var zz: float = o.get("z", 0.0)
				ci.draw_circle(Vector2(x, y + 2), 3.0, Color(0, 0, 0, 0.3))
				if o["k"] == "seed":
					ci.draw_circle(Vector2(x, y - zz), 2.5, TB.c("#140f1c"))
					ci.draw_circle(Vector2(x, y - zz), 1.6, TB.c("#d8443c"))
				elif o["k"] == "dynamite":
					Gfx.sp(ci, "dynastick", x, y - zz + 3, 1.0, 1.0, o["t"] * 3.0 if zz > 0 else 0.4)
				elif o["k"] == "sticky":
					ci.draw_circle(Vector2(x, y), 3.5, TB.c("#140f1c"))
					ci.draw_circle(Vector2(x, y), 2.6, TB.c("#63b84f") if not o.get("remote", false) else TB.c("#4e4a5e"))
					if blink:
						ci.draw_rect(Rect2(roundf(x) - 1, roundf(y) - 1, 2, 2), TB.c("#d8443c"))
				else:
					Gfx.sp(ci, Weapons.by_id(o["w"])["sprite"] if Weapons._by_id.has(o["w"]) else "w_pineapple", x, y - zz + 6, 1.0, 1.0,
						o["t"] * 8.0 if zz > 0 else 0.0)
				if o["k"] != "seed" and o["k"] != "sticky":
					# The fuse: a spark, and the seconds left.
					if blink:
						ci.draw_rect(Rect2(roundf(x) + 2, roundf(y - zz) - 7, 2, 2), TB.c("#f2c94c"))
					if o["fuse"] < 9.0 and o["k"] == "grenade":
						Gfx.text(ci, str(ceili(o["fuse"])), x, y - zz - 16, "white", 1, 0.5)
			"walker":
				var spr := "w_keg" if o["roll"] > 0 else "w_clockmice"
				var flip := cos(o["a"]) < 0
				Gfx.sp(ci, spr, o["x"], o["y"] + 4, 1.0, 1.0, o["t"] * 10.0 if o["roll"] > 0 else 0.0, flip)
			"mortar":
				var k: float = 1.0 - o["fuse"] / maxf(0.01, Weapons.wlife(G.player))
				Afx.landing(ci, o["x"], o["y"], o["rad"], clampf(k, 0.0, 1.0), Afx.C_WARN, t)

## Over everyone (world_view, with the telegraphs): rockets, missiles, shells, the pig, lock-ons, pillars.
static func draw_over(ci: CanvasItem, t: float) -> void:
	if live.is_empty() and marks.is_empty() and flashes.is_empty():
		return
	var p := G.player
	for o in live:
		match o["k"]:
			"rocket", "missile":
				var a: float = o["a"]
				var big: bool = o["k"] == "rocket"
				ci.draw_set_transform(Vector2(roundf(o["x"]), roundf(o["y"])), a, Vector2.ONE)
				ci.draw_rect(Rect2(-4 if big else -2, -1.5 if big else -1, 8 if big else 4, 3 if big else 2), TB.c("#140f1c"))
				ci.draw_rect(Rect2(-3 if big else -1, -0.5, 6 if big else 3, 1), TB.c(o["col"]))
				ci.draw_rect(Rect2(3 if big else 1, -0.5, 1, 1), TB.c("#f4ecd8"))
				ci.draw_rect(Rect2(-6 if big else -3, -1, 2, 2), TB.c("#f2c94c" if floori(t * 30) % 2 == 0 else "#e8873a"))
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"mortar":
				var k: float = 1.0 - o["fuse"] / maxf(0.01, Weapons.wlife(p))
				k = clampf(k, 0.0, 1.0)
				var x: float = lerpf(o["x0"], o["x"], k)
				var y: float = lerpf(o["y0"], o["y"], k) - sin(k * PI) * 60.0
				ci.draw_circle(Vector2(x, y), 3.5, TB.c("#140f1c"))
				ci.draw_circle(Vector2(x, y), 2.5, TB.c("#4e4a5e"))
				ci.draw_rect(Rect2(roundf(x) - 1, roundf(y) - 2, 1, 1), TB.c("#f4ecd8"))
			"pig":
				Gfx.sp(ci, "w_piggybank", o["x"], o["y"] + 6, 1.0, 1.0, 0.0, o["vx"] < 0)
	for m in marks:
		match m["k"]:
			"lock":
				var e: Enemy = m["e"].get_ref()
				if e == null:
					continue
				var k: float = clampf(m["t"] / m["lock"], 0.0, 1.0)
				var r := e.r + 14.0 - 8.0 * k
				var col := Color(1, 0.3, 0.3, 0.5 + 0.5 * k)
				for i in 4:
					var a := i * PI / 2 + PI / 4 + t * 2.0
					var c := Vector2(e.x, e.y) + Vector2.from_angle(a) * r
					ci.draw_line(c, c + Vector2.from_angle(a + PI * 0.75) * 4, col, 1.0)
					ci.draw_line(c, c + Vector2.from_angle(a - PI * 0.75) * 4, col, 1.0)
			"paint":
				var k: float = clampf(m["t"] / m["fuse"], 0.0, 1.0)
				if floori(t * 20) % 2 == 0 or k > 0.7:
					ci.draw_line(Vector2(p.x, p.y - 4), Vector2(m["x"], m["y"]), Color(0.43, 0.83, 0.88, 0.5 + 0.5 * k), 1.0 + k)
				Afx.landing(ci, m["x"], m["y"] + 4, 50.0, k, TB.c("#6fd3e0"), t)
			"plant":
				if floori(t * 12) % 2 == 0:
					ci.draw_rect(Rect2(roundf(m["x"]) - 2, roundf(m["y"]) - 10, 4, 3), TB.c("#e8873a"))
					ci.draw_rect(Rect2(roundf(m["x"]) - 1, roundf(m["y"]) - 12, 2, 2), TB.c("#d8443c"))
	for f in flashes:
		match f["k"]:
			"cone":
				var k: float = f["t"] / 0.22
				var col := TB.c(f["col"])
				var pts := PackedVector2Array([Vector2(f["x"], f["y"])])
				for i in 9:
					var a: float = f["a"] - f["arc"] / 2 + f["arc"] * i / 8.0
					pts.append(Vector2(f["x"], f["y"]) + Vector2.from_angle(a) * f["reach"] * (1.1 - 0.4 * k))
				ci.draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.28 * k))
			"pillar":
				var k: float = f["t"] / 0.35
				ci.draw_rect(Rect2(f["x"] - 8 * k - 2, 2 * TB.TS, 16 * k + 4, f["y"] - 2 * TB.TS), Color(0.78, 0.94, 1.0, 0.8 * k))
				ci.draw_rect(Rect2(f["x"] - 2, 2 * TB.TS, 4, f["y"] - 2 * TB.TS), Color(1, 1, 1, k))

## The pig's fill on the HUD, while a piggy bank is in hand.
static func draw_hud(ci: CanvasItem) -> void:
	var p := G.player
	if p == null or p.g("piggy") <= 0:
		return
	var k := clampf(piggy / p.g("piggy"), 0.0, 1.0)
	Gfx.sp(ci, "w_piggybank", 12, 60, 1.0, 1.0)
	ci.draw_rect(Rect2(22, 54, 40, 4), TB.c("#140f1c"))
	ci.draw_rect(Rect2(23, 55, roundf(38 * k), 2), TB.c("#f2c94c" if k < 1.0 else "#e86fb4"))
