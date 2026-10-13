class_name Spells
extends RefCounted
## Stage 23 THE SPELLBOOK (his word, 8 Oct: "Add more magic weapons with super cool effects"). Ten new
## kinds of spell (Combat.player_shoot calls `fire`), expanded game only; ideas only, every name,
## picture and number is this game's own.
##   singularity  a dark mote; on the first foe (or at the end of its flight) it becomes a black hole that
##                drags foes in and hurts them, then collapses in a blast that grows with every foe it held.
##                DEVOUR: it also eats enemy shots, and each one eaten makes the collapse harder (+10%, 15 at most).
##   serpent      a serpent of fire that hunts foes, burning all its body touches and leaving flames.
##                COIL (ice): it chills, and coils around a foe to crush it.
##   comet        a comet crosses the whole room through the foe you aim at, hitting everything on its
##                path, and bursts where it strikes. SHOWER: three comets, through three foes.
##   glyph        a rune under the foe you aim at erupts in a pillar of light that stuns; every 4th rune is
##                a great one. TWICE: each erupts twice, leaving foes vulnerable.
##   blades       each cast conjures a spectral blade that hunts and cuts foes by itself (up to six).
##                WAVES: every cut throws a wave of steel.
##   chrono       a circle where time stops: foes freeze and their shots hang in the air; when time catches
##                up, the foes it held take a blow. REVERSE: the frozen shots fly back at your foes.
##   prism        a crystal bolt that splits on a hit (or a wall) into red, blue and green bolts that burn,
##                chill and poison, and split again. FRACTAL: three times over.
##   cloud        a storm cloud that follows foes, striking lightning and raining ice on what is under it.
##                TORNADO: it spins a tornado that drags foes under the lightning.
##   pinball      a ball of light that bounces from foe to foe (6 times), faster and 10% harder each time; a
##                wall sends it back at the nearest foe. STARS: every bounce throws a seeking star.
##   wild         every cast a different spell: fireball, ice, lightning, poison, gold, a sheep, a heal, a
##                void or a huge crit. DOUBLE: two at once.
## +1 PROJECTILE STACKS WITHOUT LIMIT: every projectile past the first adds 35% damage; blades, comets,
## prism bolts add one more each first, up to their caps. Damage goes through Combat.damage_enemy and
## on_hit_effects, so crits, ailments and every on-hit effect work.

const KINDS := ["singularity", "serpent", "comet", "glyph", "blades", "chrono", "prism", "cloud", "pinball", "wild"]
## Keys a weapon row may carry to change what its kind does (the uniqueness report counts them).
const TWISTS := ["devour", "coil", "shower", "twice", "waves", "reverse", "fractal", "tornado", "stars", "double"]
const MAX_LIVE := 24        # things of one list alive at once (past it, folded into the newest)
const MAX_BLADES := 6
const MAX_CLOUDS := 3
const MAX_PRISMS := 48
const MAX_COMETS := 5
const HOLE_TIME := 1.3      # a black hole's pull, before the collapse
const WILD := ["fireball", "ice", "lightning", "venom", "gold", "sheep", "heal", "void", "crit"]
const WILD_WORD := { "fireball": ["FIREBALL!", "orange"], "ice": ["FREEZE!", "cyan"], "lightning": ["ZAP!", "cyan"],
	"venom": ["MIASMA!", "lime"], "gold": ["GOLD!", "gold"], "sheep": ["BAA!", "white"], "heal": ["MEND!", "pink"],
	"void": ["VOID!", "purple"], "crit": ["SMITE!", "red"] }
## Rough hits a cast lands, for the item card's BASE POWER (Weapons.weapon_dps).
const POWER := { "singularity": 2.0, "serpent": 3.5, "comet": 1.8, "glyph": 1.25, "blades": 4.0, "chrono": 2.5, "prism": 2.0,
	"cloud": 6.0, "pinball": 3.0, "wild": 1.5 }
const PRISM_COL := { "white": Color(1, 1, 1), "red": Color(1.0, 0.33, 0.25), "blue": Color(0.35, 0.65, 1.0), "green": Color(0.55, 0.95, 0.35) }

static var voids: Array = []      # { x, y, vx, vy, t, life, dmg, r, hole, hold, tick, held, eaten, devour, crit, col }
static var serpents: Array = []   # { x, y, a, t, life, dmg, trail, next, coil, coil_uid, coil_t, coiled, crush, fire_t, crit, col }
static var comets: Array = []     # { x0, y0, x1, y1, tx, ty, kb, t, dur, dmg, hit, burst, w, hx, hy, crit, col }
static var glyphs: Array = []     # { x, y, r, t, delay, dmg, great, n, twice, pillar, crit, col }
static var blades: Array = []     # { x, y, a, t, life, dmg, cd, waves, crit, col, i }
static var waves: Array = []      # { x, y, vx, vy, t, life, dmg, hit, a }
static var clocks: Array = []     # { x, y, r, t, life, dmg, frozen, shots, reverse, crit }
static var prisms: Array = []     # { x, y, vx, vy, t, life, dmg, gen, maxgen, c, hit, crit }
static var clouds: Array = []     # { x, y, t, life, dmg, cd, rain, tornado, crit }
static var pins: Array = []       # { x, y, vx, vy, t, life, dmg, bounces, max, last, stars, trail, crit, col }
static var rings: Array = []      # drawn only: { x, y, r0, r1, t, max, col }
static var sheep := {}            # uid -> true while wild magic keeps a foe a sheep (Enemy.shrink_t runs the time)
static var casts := 0             # glyphs: every 4th rune is a great one
static var heal_t := 0.0          # wild magic: a heal at most every 20 s
static var stats := {}            # what happened, by name (tests/spells_test reads it)

static func handles(kind: String) -> bool:
	return kind in KINDS

static func _stat(k: String, n: int = 1) -> void:
	stats[k] = stats.get(k, 0) + n

static func clear() -> void:
	for l in [voids, serpents, comets, glyphs, blades, waves, clocks, prisms, clouds, pins, rings]:
		l.clear()
	sheep.clear()

static func live() -> int:
	var n := 0
	for l in [voids, serpents, comets, glyphs, blades, waves, clocks, prisms, clouds, pins]:
		n = maxi(n, l.size())
	return n

static func _col(w: Dictionary) -> String:
	return Weapons.TAG_COLS[w["tags"][0] if w["tags"].size() > 0 else "arcane"][0]

static func _add(list: Array, o: Dictionary, cap: int = MAX_LIVE) -> void:
	if list.size() >= cap:
		list[list.size() - 1]["dmg"] += o["dmg"]   # past the cap: folded into the newest
		return
	list.append(o)

## A foe the spells may touch: not one tamed to fight for you (summons.gd), as every other attack.
static func _foe(e: Enemy) -> bool:
	return e.targetable() and e.charm_t <= 0

static func _wall(x: float, y: float) -> bool:
	return World.solid(G.room, floori(x / TB.TS), floori(y / TB.TS), World.M_BULLET)

static func _hurt(e: Enemy, dmg: float, p: Player, crit: bool = false, col: String = "") -> void:
	if e.hp <= 0 or not _foe(e):
		return
	var o := { "force_crit": crit }
	if col != "":
		o["col"] = col
	var c := Combat.damage_enemy(e, dmg, o)
	Combat.on_hit_effects(e, dmg, c, p, null)

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

static func _nearest(x: float, y: float, within: float, skip: int = -1) -> Enemy:
	var best: Enemy = null
	var bd := within
	for e in G.enemies:
		if e.uid != skip and _foe(e):
			var d := TB.dist_xy(e.x, e.y, x, y)
			if d < bd:
				bd = d
				best = e
	return best

static func _by_uid(uid: int) -> Enemy:
	for e in G.enemies:
		if e.uid == uid:
			return e
	return null

static func _big(e: Enemy) -> bool:
	return e.is_boss() or e.d.get("mini", false) or e.d.get("champion", false)

## A word over a spot, put where asked (Fx.float_text jitters with the run's dice).
static func _word(x: float, y: float, text: String, col: String) -> void:
	Fx.texts.append({ "x": x, "y": y, "text": text, "col": col, "life": 0.7, "big": false })

static func _ring(x: float, y: float, r0: float, r1: float, secs: float, col: Color) -> void:
	if rings.size() < 24:
		rings.append({ "x": x, "y": y, "r0": r0, "r1": r1, "t": 0.0, "max": secs, "col": col })

# ---------- Casting (Combat.player_shoot) ----------
static func fire(p: Player, a: float, forced: bool) -> Array:
	var w: Dictionary = p.weapon
	var n := Weapons.wcount(p)
	var more := 1.0 + 0.35 * (n - 1)
	var dmg := Weapons.wdmg(p) * more
	var col := _col(w)
	var sx := p.x + cos(a) * 7.0
	var sy := p.y - 3.0 + sin(a) * 7.0
	var spd := Weapons.wspd(p)
	var size := Weapons.wsize(p)
	match w["kind"]:
		"singularity":
			_add(voids, { "x": sx, "y": sy, "vx": cos(a) * spd, "vy": sin(a) * spd, "t": 0.0, "life": Weapons.wlife(p), "dmg": dmg,
				"r": float(w.get("radius", 48)) * size, "hole": false, "hold": 0.0, "tick": 0.0, "held": {}, "eaten": 0,
				"devour": w.get("devour", false), "crit": forced, "col": col })
			Snd.play("charge")
		"serpent":
			_add(serpents, { "x": sx, "y": sy, "a": a, "t": 0.0, "life": Weapons.wlife(p), "dmg": dmg, "trail": [], "next": {},
				"coil": w.get("coil", false), "coil_uid": -1, "coil_t": 0.0, "coiled": {}, "crush": 0.0, "fire_t": 0.0,
				"crit": forced, "col": col }, 8)
			Snd.play("charge")
		"comet":
			var count := mini(int(w.get("shower", 1)) + (n - 1), MAX_COMETS)
			var cdmg := Weapons.wdmg(p) * (1.0 + 0.35 * maxi(0, n - 1 - (count - int(w.get("shower", 1)))))
			var used := {}
			var first := _aimed(p, a)
			for i in count:
				var e: Enemy = first if i == 0 else null
				if i > 0:
					var pool := G.enemies.filter(func(f): return _foe(f) and not used.has(f.uid))
					if not pool.is_empty():
						e = pool[randi() % pool.size()]
				var tgt := Vector2(e.x, e.y) if e != null else Vector2(p.x + cos(a) * 100.0, p.y + sin(a) * 100.0)
				if e != null:
					used[e.uid] = true
				var dir := Vector2.from_angle(PI / 2 + randf_range(-0.7, 0.7))   # out of the sky, slanting
				_add(comets, { "x0": tgt.x - dir.x * 420.0, "y0": tgt.y - dir.y * 420.0, "x1": tgt.x + dir.x * 140.0, "y1": tgt.y + dir.y * 140.0,
					"tx": tgt.x, "ty": tgt.y, "kb": 420.0 / 560.0, "t": -0.3 - i * 0.15, "dur": 0.32, "dmg": cdmg, "hit": {}, "burst": false,
					"w": 10.0 * size, "hx": tgt.x - dir.x * 420.0, "hy": tgt.y - dir.y * 420.0, "crit": forced, "col": col }, MAX_COMETS * 3)
			if count >= 3:
				_stat("shower")
			Snd.play("beam")
		"glyph":
			casts += 1
			var great := casts % 4 == 0
			var e := _aimed(p, a)
			var gx: float = e.x if e != null else p.x + cos(a) * 90.0
			var gy: float = e.y if e != null else p.y + sin(a) * 90.0
			var twice: bool = w.get("twice", false)
			_add(glyphs, { "x": gx, "y": gy, "r": (54.0 if great else 22.0) * size, "t": 0.0, "delay": 0.75 if great else 0.5,
				"dmg": dmg * (2.0 if great else 1.0), "great": great, "n": 2 if twice else 1, "twice": twice, "pillar": 0.0,
				"crit": forced, "col": col })
			Snd.play("place")
		"blades":
			var add := mini(n, MAX_BLADES)
			var bdmg := Weapons.wdmg(p) * (1.0 + 0.35 * maxi(0, n - MAX_BLADES))
			for i in add:
				var ang := a + i * TAU / add
				var o := { "x": p.x + cos(ang) * 14.0, "y": p.y - 6.0 + sin(ang) * 8.0, "a": ang, "t": 0.0, "life": Weapons.wlife(p),
					"dmg": bdmg, "cd": 0.15, "waves": w.get("waves", false), "crit": forced, "col": col, "i": blades.size() }
				if blades.size() >= MAX_BLADES:
					blades.pop_front()   # the oldest blade gives way to the new one
				blades.append(o)
			Snd.play("hatchet")
		"chrono":
			var e := _aimed(p, a)
			_add(clocks, { "x": e.x if e != null else p.x + cos(a) * 80.0, "y": e.y if e != null else p.y + sin(a) * 80.0,
				"r": float(w.get("radius", 56)) * size, "t": 0.0, "life": Weapons.wlife(p), "dmg": dmg, "frozen": {}, "shots": [],
				"reverse": w.get("reverse", false), "crit": forced }, 3)
			Snd.play("bell")
		"prism":
			var k := mini(n, 3)
			var pdmg := Weapons.wdmg(p) * (1.0 + 0.35 * maxi(0, n - 3))
			for i in k:
				var aa := a + (i - (k - 1) / 2.0) * 0.18
				_add(prisms, { "x": sx, "y": sy, "vx": cos(aa) * spd, "vy": sin(aa) * spd, "t": 0.0, "life": Weapons.wlife(p),
					"dmg": pdmg, "gen": 0, "maxgen": 3 if w.get("fractal", false) else 2, "c": "white", "hit": {}, "crit": forced }, MAX_PRISMS)
			Snd.play("shoot")
		"cloud":
			var o := { "x": p.x, "y": p.y - 34.0, "t": 0.0, "life": Weapons.wlife(p), "dmg": dmg, "cd": 0.3, "rain": 0.0,
				"tornado": w.get("tornado", false), "crit": forced }
			if clouds.size() >= MAX_CLOUDS:
				clouds.pop_front()
			clouds.append(o)
			Snd.play("beam")
		"pinball":
			_add(pins, { "x": sx, "y": sy, "vx": cos(a) * spd, "vy": sin(a) * spd, "t": 0.0, "life": Weapons.wlife(p), "dmg": dmg,
				"bounces": 0, "max": int(w.get("max", 6)), "last": -1, "stars": w.get("stars", false), "trail": [], "crit": forced,
				"col": col })
			Snd.play("shoot")
		"wild":
			var first: String = WILD[randi() % WILD.size()]
			_wild(p, a, first, dmg, forced, 0)
			if w.get("double", false):
				var second: String = WILD[randi() % WILD.size()]
				while second == first:
					second = WILD[randi() % WILD.size()]
				_wild(p, a, second, dmg, forced, 1)
			_stat("double")
	return []

## One spell of wild magic.
static func _wild(p: Player, a: float, s: String, dmg: float, crit: bool, k: int) -> void:
	var e := _aimed(p, a)
	var tx: float = e.x if e != null else p.x + cos(a) * 90.0
	var ty: float = e.y if e != null else p.y + sin(a) * 90.0
	if s == "heal" and (heal_t > 0.0 or p.hp >= p.max_hp):
		s = "crit"   # a heal at most every 20 s, and only when hurt; else a smite
	_stat("wild_" + s)
	_stat("wild")
	var wd: Array = WILD_WORD[s]
	_word(p.x, p.y - 26.0 - k * 9.0, wd[0], wd[1])
	match s:
		"fireball":
			Combat.explode_at(tx, ty, dmg * 1.6, null, 30, "#e8873a")
			for f in G.enemies:
				if _foe(f) and TB.dist_xy(f.x, f.y, tx, ty) < 30 + f.r:
					Statuses.apply(f, "burn", 1, dmg)
			Snd.play("boom")
		"ice":
			if e != null:
				_hurt(e, dmg * 1.3, p, crit, "cyan")
				Statuses.apply(e, "chill", 2, dmg)
				e.stun_t = maxf(e.stun_t, 0.3 if _big(e) else 1.4)
			Fx.burst(tx, ty - 4, ["#c8f0ff", "#6fd3e0", "#ffffff"], 12, 70, 0.4)
			_ring(tx, ty, 4.0, 22.0, 0.3, Color(0.75, 0.95, 1.0))
		"lightning":
			var hit := {}
			var cur := e
			for i in 3:
				if cur == null:
					break
				hit[cur.uid] = true
				Combat.lightning(cur, dmg * 0.8)
				var nxt: Enemy = null
				var bd := 120.0
				for f in G.enemies:
					if _foe(f) and not hit.has(f.uid) and TB.dist(f, cur) < bd:
						bd = TB.dist(f, cur)
						nxt = f
				cur = nxt
		"venom":
			if G.zones.size() < 60:
				G.zones.append({ "x": tx, "y": ty, "r": 30, "t": 3.0, "kind": "poison", "tick": 0.0 })
			for f in G.enemies:
				if _foe(f) and TB.dist_xy(f.x, f.y, tx, ty) < 30 + f.r:
					Statuses.apply(f, "poison", 3, dmg)
					_hurt(f, dmg * 0.5, p, crit, "lime")
		"gold":
			if e != null:
				_hurt(e, dmg, p, crit, "gold")
				if not e.type in ["dummy", "target"]:   # (no gold from the training dummy)
					for i in 3:
						Combat.drop_pickup("coin", tx, ty)
			Snd.play("coin")
		"sheep":
			if e != null and not _big(e):
				_hurt(e, dmg * 0.5, p, crit)
				if e.hp > 0:
					e.shrink_t = maxf(e.shrink_t, 3.0)   # small, harmless to touch, squashed underfoot (oddities.gd)
					e.stun_t = maxf(e.stun_t, 3.0)
					Statuses.apply(e, "vulnerable", 1, dmg)
					sheep[e.uid] = true
			elif e != null:
				_hurt(e, dmg * 2.0, p, crit)   # too big to be a sheep: it hurts them instead
		"heal":
			p.heal(1)
			heal_t = 20.0
			Fx.burst(p.x, p.y - 6, ["#e86fb4", "#ffffff"], 10, 50, 0.4)
			Snd.play("heal")
		"void":
			_add(voids, { "x": tx, "y": ty, "vx": 0.0, "vy": 0.0, "t": 0.0, "life": 0.0, "dmg": dmg, "r": 40.0, "hole": true,
				"hold": HOLE_TIME * 0.7, "tick": 0.0, "held": {}, "eaten": 0, "devour": false, "crit": crit, "col": "#a35bd6" })
		"crit":
			if e != null:
				_hurt(e, dmg * 4.0, p, true, "red")
				_ring(e.x, e.y - 4, 2.0, 26.0, 0.3, Color(1.0, 0.85, 0.3))

# ---------- Every tick (Hazards.update) ----------
static func tick(room: Room, dt: float) -> void:
	var p := G.player
	if room == null or p == null:
		return
	heal_t = maxf(0.0, heal_t - dt)
	if not voids.is_empty():
		_tick_voids(p, room, dt)
	if not serpents.is_empty():
		_tick_serpents(p, room, dt)
	if not comets.is_empty():
		_tick_comets(p, dt)
	if not glyphs.is_empty():
		_tick_glyphs(p, dt)
	if not blades.is_empty():
		_tick_blades(p, dt)
	if not waves.is_empty():
		_tick_waves(p, dt)
	if not clocks.is_empty():
		_tick_clocks(p, dt)
	if not prisms.is_empty():
		_tick_prisms(p, dt)
	if not clouds.is_empty():
		_tick_clouds(p, room, dt)
	if not pins.is_empty():
		_tick_pins(p, dt)
	if not rings.is_empty():
		var kr := []
		for r in rings:
			r["t"] += dt
			if r["t"] < r["max"]:
				kr.append(r)
		rings = kr
	if not sheep.is_empty():
		for uid in sheep.keys():
			var e := _by_uid(uid)
			if e == null or e.hp <= 0 or e.shrink_t <= 0.0:
				sheep.erase(uid)

static func _tick_voids(p: Player, room: Room, dt: float) -> void:
	var keep := []
	for o in voids:
		o["t"] += dt
		if not o["hole"]:
			var nx: float = o["x"] + o["vx"] * dt
			var ny: float = o["y"] + o["vy"] * dt
			var stop: bool = o["t"] >= o["life"] or _wall(nx, ny)
			if not stop:
				o["x"] = nx
				o["y"] = ny
				for e in G.enemies:
					if _foe(e) and TB.dist_xy(e.x, e.y, nx, ny) < e.r + 4.0:
						stop = true
						break
			if stop:
				o["hole"] = true
				o["hold"] = HOLE_TIME
				Snd.play("portal")
			keep.append(o)
			continue
		o["hold"] -= dt
		o["tick"] -= dt
		var r: float = o["r"]
		var hurt: bool = o["tick"] <= 0.0
		if hurt:
			o["tick"] = 0.25
		for e in G.enemies.duplicate():
			if not _foe(e):
				continue
			var d := TB.dist_xy(e.x, e.y, o["x"], o["y"])
			if d > r:
				continue
			o["held"][e.uid] = true
			if not _big(e) and d > 3.0:
				var pull := minf(d - 2.0, (60.0 + 140.0 * (1.0 - d / r)) * dt)   # harder the nearer the middle
				World.move_body(room, e, (o["x"] - e.x) / d * pull, (o["y"] - e.y) / d * pull, World.M_FLYER if e.d.get("fly", false) else World.M_WALKER)
				_stat("pull")
			if hurt:
				_hurt(e, o["dmg"] * 0.15, p, false, "purple")
		if o["devour"]:
			var eaten := EBullets.take_near(o["x"], o["y"], r, 30).size()
			if eaten > 0:
				o["eaten"] += eaten
				_stat("eat", eaten)
		if o["hold"] <= 0.0:
			_collapse(o, p)
			continue
		keep.append(o)
	voids = keep

static func _collapse(o: Dictionary, p: Player) -> void:
	var held: int = (o["held"] as Dictionary).size()
	var dmg: float = o["dmg"] * (1.5 + 0.3 * held + 0.1 * mini(o["eaten"], 15))   # (+10% a shot eaten, up to 15)
	for e in G.enemies.duplicate():
		if _foe(e) and TB.dist_xy(e.x, e.y, o["x"], o["y"]) < o["r"] * 0.9 + e.r:
			_hurt(e, dmg, p, o["crit"], "purple")
	_stat("collapse")
	Fx.burst(o["x"], o["y"], ["#a35bd6", "#16141c", "#e8c8ff"], 22, 120, 0.5)
	_ring(o["x"], o["y"], 4.0, o["r"], 0.35, Color(0.75, 0.45, 1.0))
	Weather.flash(o["x"], o["y"], o["r"])
	G.shake = maxf(G.shake, 3.0 + held)
	Snd.play("boom")

static func _tick_serpents(p: Player, room: Room, dt: float) -> void:
	var keep := []
	for o in serpents:
		o["t"] += dt
		if o["t"] >= o["life"]:
			Fx.burst(o["x"], o["y"], ["#e8873a", "#f2c94c"] if not o["coil"] else ["#c8f0ff", "#6fd3e0"], 10, 60, 0.4)
			continue
		var coiled: Enemy = _by_uid(o["coil_uid"]) if o["coil_uid"] >= 0 else null
		if coiled != null and coiled.hp > 0 and o["coil_t"] > 0.0:
			# Coiled round a foe: it circles it and crushes.
			o["coil_t"] -= dt
			var ang: float = o["t"] * 9.0
			o["x"] = coiled.x + cos(ang) * (coiled.r + 6.0)
			o["y"] = coiled.y + sin(ang) * (coiled.r + 4.0)
			o["a"] = ang + PI / 2
			o["crush"] -= dt
			if o["crush"] <= 0.0:
				o["crush"] = 0.2
				_hurt(coiled, o["dmg"] * 0.8, p, o["crit"], "cyan")
				Statuses.apply(coiled, "chill", 1, o["dmg"])
				_stat("coil")
			if o["coil_t"] <= 0.0:
				o["coiled"][coiled.uid] = true
				o["coil_uid"] = -1
		else:
			o["coil_uid"] = -1
			var tgt := _nearest(o["x"], o["y"], 260.0)
			if tgt != null:
				var want := TB.ang_xy(o["x"], o["y"], tgt.x, tgt.y)
				o["a"] += clampf(TB.wrap_ang(want - o["a"]), -3.5 * dt, 3.5 * dt)
				if o["coil"] and not o["coiled"].has(tgt.uid) and TB.dist_xy(o["x"], o["y"], tgt.x, tgt.y) < tgt.r + 6.0:
					o["coil_uid"] = tgt.uid
					o["coil_t"] = 1.0
					o["crush"] = 0.0
			var dir: float = o["a"] + sin(o["t"] * 10.0) * 0.6   # the slither
			var nx: float = o["x"] + cos(dir) * 120.0 * dt
			var ny: float = o["y"] + sin(dir) * 120.0 * dt
			if _wall(nx, ny):
				o["a"] += PI * 0.6
			else:
				o["x"] = nx
				o["y"] = ny
		var tr: Array = o["trail"]
		tr.push_front(Vector2(o["x"], o["y"]))
		if tr.size() > 36:
			tr.pop_back()
		# The body: eight segments along the trail burn (or chill) what they touch.
		for e in G.enemies.duplicate():
			if not _foe(e) or o["next"].get(e.uid, 0.0) > o["t"]:
				continue
			var k := 0
			while k < tr.size():
				var s: Vector2 = tr[k]
				if absf(s.x - e.x) < e.r + 5.0 and absf(s.y - e.y) < e.r + 5.0:
					o["next"][e.uid] = o["t"] + 0.35
					_hurt(e, o["dmg"] * 0.5, p, o["crit"], "cyan" if o["coil"] else "orange")
					Statuses.apply(e, "chill" if o["coil"] else "burn", 1, o["dmg"])
					_stat("bite")
					break
				k += 5
		if not o["coil"]:
			o["fire_t"] -= dt
			if o["fire_t"] <= 0.0 and tr.size() > 30 and G.zones.size() < 60:
				o["fire_t"] = 0.3
				var tail: Vector2 = tr[30]
				G.zones.append({ "x": tail.x, "y": tail.y + 2.0, "r": 7, "t": 1.2, "kind": "fire", "tick": 0.0 })
		keep.append(o)
	serpents = keep

## The distance from (px, py) to the segment a-b.
static func _seg_d(px: float, py: float, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	var k := 0.0 if l2 < 0.001 else clampf((Vector2(px, py) - a).dot(ab) / l2, 0.0, 1.0)
	return (a + ab * k).distance_to(Vector2(px, py))

static func _tick_comets(p: Player, dt: float) -> void:
	var keep := []
	for o in comets:
		o["t"] += dt
		if o["t"] < 0.0:
			keep.append(o)
			continue
		var k := clampf(o["t"] / o["dur"], 0.0, 1.0)
		var prev := Vector2(o["hx"], o["hy"])
		var head := Vector2(lerpf(o["x0"], o["x1"], k), lerpf(o["y0"], o["y1"], k))
		o["hx"] = head.x
		o["hy"] = head.y
		for e in G.enemies.duplicate():
			if _foe(e) and not o["hit"].has(e.uid) and _seg_d(e.x, e.y, prev, head) < o["w"] + e.r:
				o["hit"][e.uid] = true
				_hurt(e, o["dmg"], p, o["crit"], "orange")
				Statuses.apply(e, "burn", 1, o["dmg"])
				_stat("comet_hit")
		if not o["burst"] and k >= o["kb"]:
			o["burst"] = true
			Combat.explode_at(o["tx"], o["ty"], o["dmg"] * 0.8, null, 26, "#f2c94c")
			_ring(o["tx"], o["ty"], 4.0, 30.0, 0.3, Color(1.0, 0.9, 0.55))
			G.shake = maxf(G.shake, 3.0)
			_stat("comet_burst")
		if o["t"] < o["dur"] + 0.45:   # the trail fades after it has gone
			keep.append(o)
	comets = keep

static func _tick_glyphs(p: Player, dt: float) -> void:
	var keep := []
	for o in glyphs:
		o["t"] += dt
		if o["pillar"] > 0.0:
			o["pillar"] -= dt
		if o["n"] > 0 and o["t"] >= o["delay"]:
			o["n"] -= 1
			o["t"] = o["delay"] - 0.35   # (a second eruption, 0.35 s on)
			o["pillar"] = 0.4
			for e in G.enemies.duplicate():
				if _foe(e) and TB.dist_xy(e.x, e.y, o["x"], o["y"]) < o["r"] + e.r:
					_hurt(e, o["dmg"], p, o["crit"], "pink")
					if e.hp > 0:
						Statuses.apply(e, "stun", 0.5, o["dmg"])
						if o["twice"]:
							Statuses.apply(e, "vulnerable", 1, o["dmg"])
							_stat("sunder")
			_stat("erupt")
			if o["great"]:
				_stat("great")
				G.shake = maxf(G.shake, 4.0)
				Snd.play("boom")
			else:
				Snd.play("hit")
			Weather.flash(o["x"], o["y"], o["r"])
		if o["n"] > 0 or o["pillar"] > 0.0:
			keep.append(o)
	glyphs = keep

static func _tick_blades(p: Player, dt: float) -> void:
	var keep := []
	var i := 0
	for o in blades:
		o["t"] += dt
		if o["t"] >= o["life"]:
			Fx.burst(o["x"], o["y"], ["#c8f0ff", "#ffffff"], 6, 40, 0.3)
			continue
		o["cd"] -= dt
		var tgt := _nearest(o["x"], o["y"], 220.0)
		var want: float
		var spd := 250.0
		if tgt == null:
			var orbit: float = G.time * 3.0 + i * TAU / maxi(1, blades.size())
			var px := p.x + cos(orbit) * 20.0
			var py := p.y - 8.0 + sin(orbit) * 10.0
			want = TB.ang_xy(o["x"], o["y"], px, py)
			spd = minf(200.0, TB.dist_xy(o["x"], o["y"], px, py) * 6.0)
		else:
			want = TB.ang_xy(o["x"], o["y"], tgt.x, tgt.y)
			if o["cd"] <= 0.0 and TB.dist_xy(o["x"], o["y"], tgt.x, tgt.y) < tgt.r + 9.0:
				o["cd"] = 0.5
				_hurt(tgt, o["dmg"], p, o["crit"], "white")
				_stat("slash")
				if o["waves"] and waves.size() < MAX_LIVE:
					waves.append({ "x": o["x"], "y": o["y"], "vx": cos(o["a"]) * 230.0, "vy": sin(o["a"]) * 230.0, "t": 0.0, "life": 0.35,
						"dmg": o["dmg"] * 0.6, "hit": { tgt.uid: true }, "a": o["a"] })
					_stat("wave")
				Snd.play("hatchet")
		if o["cd"] > 0.35:
			want = o["a"]   # carried through by the cut
		o["a"] = lerp_angle(o["a"], want, minf(1.0, 12.0 * dt))
		o["x"] += cos(o["a"]) * spd * dt
		o["y"] += sin(o["a"]) * spd * dt
		keep.append(o)
		i += 1
	blades = keep

static func _tick_waves(p: Player, dt: float) -> void:
	var keep := []
	for o in waves:
		o["t"] += dt
		o["x"] += o["vx"] * dt
		o["y"] += o["vy"] * dt
		if o["t"] >= o["life"] or _wall(o["x"], o["y"]):
			continue
		for e in G.enemies.duplicate():
			if _foe(e) and not o["hit"].has(e.uid) and TB.dist_xy(e.x, e.y, o["x"], o["y"]) < e.r + 8.0:
				o["hit"][e.uid] = true
				_hurt(e, o["dmg"], p, false, "white")
		keep.append(o)
	waves = keep

static func _tick_clocks(p: Player, dt: float) -> void:
	var keep := []
	for o in clocks:
		o["t"] += dt
		var r: float = o["r"]
		for e in G.enemies:
			if not _foe(e) or TB.dist_xy(e.x, e.y, o["x"], o["y"]) >= r:
				continue
			if not o["frozen"].has(e.uid):
				o["frozen"][e.uid] = [e.x, e.y, 0.0]
				_stat("freeze_foe")
			var f: Array = o["frozen"][e.uid]
			f[2] += dt
			if _big(e):
				Statuses.apply(e, "chill", 0.5, 0.0)   # the great are only slowed
			else:
				e.x = f[0]   # time stands still for it: where it was, doing nothing
				e.y = f[1]
				e.stun_t = maxf(e.stun_t, 0.05)
				e.kx = 0.0
				e.ky = 0.0
		for s in EBullets.take_near(o["x"], o["y"], r, 40):
			if o["shots"].size() < 60:
				o["shots"].append(s)
				_stat("freeze_shot")
		if o["t"] >= o["life"]:
			_catch_up(o, p)
			continue
		keep.append(o)
	clocks = keep

## Time catches up: the foes it held take a blow; their shots shatter (or fly back at foes).
static func _catch_up(o: Dictionary, p: Player) -> void:
	for uid in o["frozen"].keys():
		var e := _by_uid(uid)
		if e == null or not _foe(e):
			continue
		var secs: float = o["frozen"][uid][2]
		_hurt(e, o["dmg"] * (1.0 + secs), p, o["crit"], "cyan")
		_stat("catch_up")
	var n := 0
	for s in o["shots"]:
		if o["reverse"] and n < 30:
			n += 1
			var t := _nearest(s[0], s[1], 400.0)
			var a: float = TB.ang_xy(s[0], s[1], t.x, t.y) if t != null else atan2(-s[3], -s[2])
			Combat._raw_shot(s[0], s[1], a, 260, o["dmg"] * 0.5, 1.2, 2.5, 0, "spark", {}, 3.0)
			_stat("reverse")
		else:
			Fx.particle(s[0], s[1], 0, -20, 0.3, "#c8f0ff", 1)
	_ring(o["x"], o["y"], o["r"], 4.0, 0.3, Color(0.95, 0.85, 0.5))
	Snd.play("bell")

static func _tick_prisms(p: Player, dt: float) -> void:
	var keep := []
	var born := []
	for o in prisms:
		o["t"] += dt
		if o["t"] >= o["life"]:
			continue
		var nx: float = o["x"] + o["vx"] * dt
		var ny: float = o["y"] + o["vy"] * dt
		var split := false
		var base := atan2(o["vy"], o["vx"])
		if _wall(nx, ny):
			split = true
			base += PI   # back off the wall
		else:
			o["x"] = nx
			o["y"] = ny
			for e in G.enemies.duplicate():
				if _foe(e) and not o["hit"].has(e.uid) and TB.dist_xy(e.x, e.y, nx, ny) < e.r + 3.0:
					o["hit"][e.uid] = true
					_hurt(e, o["dmg"], p, o["crit"], "pink")
					match o["c"]:
						"red": Statuses.apply(e, "burn", 1, o["dmg"])
						"blue": Statuses.apply(e, "chill", 1, o["dmg"])
						"green": Statuses.apply(e, "poison", 2, o["dmg"])
					_stat("prism_hit")
					split = true
					break
		if not split:
			keep.append(o)
			continue
		if o["gen"] < o["maxgen"]:
			var spd := Vector2(o["vx"], o["vy"]).length()
			var cs := ["red", "blue", "green"]
			for i in 3:
				if prisms.size() + born.size() >= MAX_PRISMS:
					break
				var a := base + (i - 1) * 0.7
				born.append({ "x": o["x"], "y": o["y"], "vx": cos(a) * spd, "vy": sin(a) * spd, "t": 0.0, "life": 0.55,
					"dmg": o["dmg"] * 0.65, "gen": o["gen"] + 1, "maxgen": o["maxgen"], "c": cs[i], "hit": o["hit"].duplicate(), "crit": o["crit"] })
			_stat("split")
			if o["gen"] >= 2:
				_stat("fractal")   # a third split: only the fractal crown's bolts get this far
			Fx.burst(o["x"], o["y"], ["#ff5a3a", "#5aa8ff", "#8cf05a"], 6, 50, 0.25)
	prisms = keep + born

static func _tick_clouds(p: Player, room: Room, dt: float) -> void:
	var keep := []
	for o in clouds:
		o["t"] += dt
		var gx: float = o["x"]
		var gy: float = o["y"] + 26.0   # the ground under the cloud
		if o["t"] >= o["life"]:
			if o["tornado"]:
				for e in G.enemies:   # the tornado lets go: what it held is flung
					if _foe(e) and not _big(e) and TB.dist_xy(e.x, e.y, gx, gy) < 50.0:
						var a := TB.ang_xy(gx, gy, e.x, e.y)
						e.kx += cos(a) * 220.0
						e.ky += sin(a) * 220.0
			Fx.burst(gx, o["y"], ["#8b8f9c", "#c8d0e0"], 10, 40, 0.5)
			continue
		var tgt := _nearest(gx, gy, 320.0)
		var wx: float = tgt.x if tgt != null else p.x
		var wy: float = (tgt.y if tgt != null else p.y) - 26.0
		var d := TB.dist_xy(o["x"], o["y"], wx, wy)
		if d > 1.0:
			var step := minf(d, 75.0 * dt)
			o["x"] += (wx - o["x"]) / d * step
			o["y"] += (wy - o["y"]) / d * step
		o["cd"] -= dt
		if o["cd"] <= 0.0 and tgt != null and TB.dist_xy(gx, gy, tgt.x, tgt.y) < 60.0:
			o["cd"] = 0.6
			Combat.lightning(tgt, o["dmg"])
			_stat("strike")
		o["rain"] -= dt
		if o["rain"] <= 0.0:
			o["rain"] = 0.5
			for e in G.enemies:
				if _foe(e) and TB.dist_xy(e.x, e.y, gx, gy) < 30.0 + e.r:
					Statuses.apply(e, "chill", 0.5, o["dmg"])
		if o["tornado"]:
			for e in G.enemies.duplicate():
				if not _foe(e) or _big(e):
					continue
				var de := TB.dist_xy(e.x, e.y, gx, gy)
				if de < 56.0 and de > 4.0:
					var pull := minf(de - 3.0, 95.0 * dt)
					World.move_body(room, e, (gx - e.x) / de * pull, (gy - e.y) / de * pull, World.M_FLYER if e.d.get("fly", false) else World.M_WALKER)
					_stat("twist")
		keep.append(o)
	clouds = keep

static func _tick_pins(p: Player, dt: float) -> void:
	var keep := []
	for o in pins:
		o["t"] += dt
		if o["t"] >= o["life"] or o["bounces"] > o["max"]:
			Fx.burst(o["x"], o["y"], ["#f2c94c", "#ffffff"], 6, 40, 0.25)
			continue
		var nx: float = o["x"] + o["vx"] * dt
		var ny: float = o["y"] + o["vy"] * dt
		var wall := false
		if _wall(nx, o["y"]):
			o["vx"] = -o["vx"]
			nx = o["x"]
			wall = true
		if _wall(o["x"], ny):
			o["vy"] = -o["vy"]
			ny = o["y"]
			wall = true
		o["x"] = nx
		o["y"] = ny
		if wall:
			# A wall is a bumper: it sends the ball back at the nearest foe (the last one too).
			o["last"] = -1
			var back := _nearest(nx, ny, 400.0)
			if back != null:
				var sp := Vector2(o["vx"], o["vy"]).length()
				var ba := TB.ang_xy(nx, ny, back.x, back.y)
				o["vx"] = cos(ba) * sp
				o["vy"] = sin(ba) * sp
		var tr: Array = o["trail"]
		tr.push_front(Vector2(nx, ny))
		if tr.size() > 8:
			tr.pop_back()
		for e in G.enemies.duplicate():
			if not _foe(e) or e.uid == o["last"] or TB.dist_xy(e.x, e.y, nx, ny) >= e.r + 4.0:
				continue
			_hurt(e, o["dmg"] * (1.0 + 0.1 * o["bounces"]), p, o["crit"], "gold")
			_stat("bounce")
			o["bounces"] += 1
			o["last"] = e.uid
			_ring(nx, ny, 2.0, 12.0, 0.2, Color(1.0, 0.9, 0.5))
			if o["stars"]:
				Combat._raw_shot(e.x, e.y - 4.0, randf() * TAU, 200, o["dmg"] * 0.3, 1.2, 2.0, 0, "spark", {}, 4.0)
				_stat("star")
			var spd := minf(520.0, Vector2(o["vx"], o["vy"]).length() * 1.08)
			var nxt := _nearest(e.x, e.y, 220.0, e.uid)
			var a: float = TB.ang_xy(nx, ny, nxt.x, nxt.y) if nxt != null else atan2(-o["vy"], -o["vx"]) + randf_range(-0.6, 0.6)
			o["vx"] = cos(a) * spd
			o["vy"] = sin(a) * spd
			Snd.play("hit")
			break
		keep.append(o)
	pins = keep

# ---------- Drawing (world_view) ----------
## Under the people: runes, the pull of a black hole, a clock's circle, a comet's warning.
static func draw_floor(ci: CanvasItem, t: float) -> void:
	for o in glyphs:
		var r: float = o["r"]
		var c := Color(1.0, 0.55, 0.85) if not o["twice"] else Color(0.85, 0.35, 0.55)
		var fill := clampf(o["t"] / o["delay"], 0.0, 1.0) if o["n"] > 0 else 1.0
		ci.draw_circle(Vector2(o["x"], o["y"]), r, Color(c.r, c.g, c.b, 0.08 + 0.12 * fill))
		ci.draw_arc(Vector2(o["x"], o["y"]), r, 0.0, TAU, 28, Color(c.r, c.g, c.b, 0.85), 1.0)
		ci.draw_arc(Vector2(o["x"], o["y"]), r * 0.7, t * 2.0, t * 2.0 + TAU * fill, 20, Color(1, 1, 1, 0.8), 1.0)
		var marks := 8 if o["great"] else 5
		for k in marks:
			var a: float = -t * 1.5 + k * TAU / marks
			var m := Vector2(o["x"], o["y"]) + Vector2.from_angle(a) * r * 0.85
			ci.draw_rect(Rect2(roundf(m.x) - 1, roundf(m.y) - 1, 2, 2), Color(1, 0.9, 1.0, 0.9))
	for o in voids:
		if o["hole"]:
			ci.draw_circle(Vector2(o["x"], o["y"]), o["r"], Color(0.1, 0.02, 0.15, 0.18))
			ci.draw_arc(Vector2(o["x"], o["y"]), o["r"], 0.0, TAU, 32, Color(0.6, 0.3, 0.9, 0.35), 1.0)
	for o in clocks:
		var c := Vector2(o["x"], o["y"])
		var r: float = o["r"]
		ci.draw_circle(c, r, Color(0.55, 0.75, 1.0, 0.12))
		ci.draw_arc(c, r, 0.0, TAU, 36, Color(0.95, 0.85, 0.5, 0.8), 1.0)
		for k in 12:
			var m := c + Vector2.from_angle(k * TAU / 12.0) * (r - 3.0)
			ci.draw_rect(Rect2(roundf(m.x), roundf(m.y), 1, 1 + int(k % 3 == 0)), Color(1, 0.95, 0.7))
		var left: float = 1.0 - o["t"] / maxf(0.01, o["life"])
		ci.draw_line(c, c + Vector2.from_angle(-PI / 2 + TAU * (1.0 - left)) * r * 0.75, Color(1, 0.95, 0.7, 0.9), 1.0)
		ci.draw_line(c, c + Vector2.from_angle(-PI / 2 + TAU * (1.0 - left) / 12.0) * r * 0.45, Color(1, 0.95, 0.7, 0.9), 2.0)
	for o in comets:
		if o["t"] < 0.0:   # the warning: where it will cross, and the mark
			var a := Vector2(o["x0"], o["y0"])
			var b := Vector2(o["x1"], o["y1"])
			var blink := 0.35 + 0.25 * sin(t * 30.0)
			ci.draw_line(a, b, Color(1.0, 0.75, 0.3, blink * 0.6), 1.0)
			ci.draw_arc(Vector2(o["tx"], o["ty"]), 12.0, 0.0, TAU, 16, Color(1.0, 0.6, 0.2, blink), 1.0)
	for o in clouds:
		ci.draw_circle(Vector2(o["x"], o["y"] + 27.0), 14.0, Color(0, 0, 0, 0.18))

## Over the people: the spells themselves.
static func draw_over(ci: CanvasItem, t: float) -> void:
	for o in voids:
		var c := Vector2(o["x"], o["y"])
		if not o["hole"]:
			ci.draw_circle(c, 4.0, Color(0.08, 0.02, 0.12))
			ci.draw_arc(c, 5.0, t * 9.0, t * 9.0 + 4.0, 8, Color(0.75, 0.45, 1.0), 1.0)
			continue
		var grow := minf(1.0, (HOLE_TIME - o["hold"]) * 4.0)
		var core := 5.0 + 4.0 * grow
		for k in 3:   # the disk that turns about it
			var rr := core + 3.0 + k * 3.0
			var a0: float = t * (7.0 - k * 1.5) + k * 2.1
			ci.draw_arc(c, rr, a0, a0 + 3.6, 12, Color(0.85, 0.5 + k * 0.15, 1.0, 0.75 - k * 0.2), 1.0)
		for k in 10:   # motes falling in
			var ph := fmod(t * 0.9 + k * 0.1, 1.0)
			var a: float = k * 2.39 + t * 2.0
			var m: Vector2 = c + Vector2.from_angle(a) * o["r"] * (1.0 - ph)
			ci.draw_rect(Rect2(roundf(m.x), roundf(m.y), 1, 1), Color(0.9, 0.75, 1.0, 0.4 + 0.6 * ph))
		ci.draw_circle(c, core, Color(0.02, 0.0, 0.04))
		ci.draw_arc(c, core, 0.0, TAU, 16, Color(1.0, 0.85, 1.0, 0.9), 1.0)
	for o in serpents:
		var tr: Array = o["trail"]
		var ice: bool = o["coil"]
		var k := tr.size() - 1
		while k >= 0:
			var s: Vector2 = tr[k]
			var size := 4.0 - k * 0.08
			var fl := 0.5 + 0.5 * sin(t * 20.0 + k)
			var body := Color(0.55, 0.85, 1.0) if ice else Color(1.0, 0.45 + 0.25 * fl, 0.12)
			ci.draw_circle(s, size, body)
			ci.draw_circle(s, size * 0.5, Color(1, 1, 1, 0.55) if ice else Color(1.0, 0.9, 0.4, 0.8))
			k -= 3
		if not tr.is_empty():
			var h: Vector2 = tr[0]
			var f := Vector2.from_angle(o["a"])
			ci.draw_circle(h, 5.0, Color(0.75, 0.95, 1.0) if ice else Color(1.0, 0.6, 0.15))
			var side := Vector2(-f.y, f.x) * 2.0
			ci.draw_rect(Rect2(roundf(h.x + f.x * 2 + side.x), roundf(h.y + f.y * 2 + side.y), 1, 1), Color(0.1, 0.05, 0.1))
			ci.draw_rect(Rect2(roundf(h.x + f.x * 2 - side.x), roundf(h.y + f.y * 2 - side.y), 1, 1), Color(0.1, 0.05, 0.1))
			if fmod(t, 0.6) < 0.15:   # its tongue
				ci.draw_line(h + f * 5.0, h + f * 9.0, Color(1.0, 0.3, 0.4), 1.0)
	for o in comets:
		if o["t"] < 0.0:
			continue
		var head := Vector2(o["hx"], o["hy"])
		var dir := (Vector2(o["x1"], o["y1"]) - Vector2(o["x0"], o["y0"])).normalized()
		var gone: float = maxf(0.0, o["t"] - o["dur"])
		var fade := 1.0 - gone / 0.45
		for k in 14:   # the tail, and the stardust left on the path
			var back: Vector2 = head - dir * (k * 9.0)
			var al := (1.0 - k / 14.0) * fade
			ci.draw_line(back, back - dir * 9.0, Color(1.0, 0.8 - k * 0.03, 0.4, al), maxf(1.0, 4.0 - k * 0.3))
		if gone <= 0.0:
			ci.draw_circle(head, 5.0, Color(1.0, 0.95, 0.75))
			ci.draw_circle(head, 3.0, Color(1, 1, 1))
	for o in glyphs:
		if o["pillar"] <= 0.0:
			continue
		var k: float = o["pillar"] / 0.4
		var wdt: float = (o["r"] * 0.9 if o["great"] else 10.0) * k
		var top: float = o["y"] - (120.0 if o["great"] else 80.0)
		ci.draw_rect(Rect2(o["x"] - wdt, top, wdt * 2.0, o["y"] - top), Color(1.0, 0.6, 0.9, 0.35 * k))
		ci.draw_rect(Rect2(o["x"] - wdt * 0.4, top, wdt * 0.8, o["y"] - top), Color(1, 1, 1, 0.75 * k))
	for o in blades:
		var c := Vector2(o["x"], o["y"])
		var f := Vector2.from_angle(o["a"])
		var side := Vector2(-f.y, f.x)
		var al := minf(1.0, (o["life"] - o["t"]) * 2.0)
		for g in 2:   # afterimages
			var back := c - f * (6.0 + g * 6.0)
			ci.draw_line(back - f * 5.0, back + f * 5.0, Color(0.7, 0.95, 1.0, 0.25 * al / (g + 1)), 1.0)
		ci.draw_line(c - f * 5.0, c + f * 7.0, Color(0.85, 1.0, 1.0, al), 2.0)
		ci.draw_line(c + f * 7.0, c + f * 9.0, Color(1, 1, 1, al), 1.0)
		ci.draw_line(c - f * 5.0 + side * 3.0, c - f * 5.0 - side * 3.0, Color(0.6, 0.85, 1.0, al), 1.0)
		ci.draw_line(c - f * 5.0, c - f * 8.0, Color(0.4, 0.6, 0.9, al), 1.0)
	for o in waves:
		var a: float = o["a"]
		ci.draw_arc(Vector2(o["x"], o["y"]), 7.0, a - 1.1, a + 1.1, 8, Color(0.9, 1.0, 1.0, 1.0 - o["t"] / o["life"]), 2.0)
	for o in clocks:
		for s in o["shots"]:   # shots hanging in stopped time
			ci.draw_arc(Vector2(s[0], s[1]), 3.0, 0.0, TAU, 8, Color(0.8, 0.9, 1.0, 0.9), 1.0)
			ci.draw_rect(Rect2(roundf(s[0]), roundf(s[1]), 1, 1), Color(1, 0.4, 0.4))
		for uid in o["frozen"].keys():
			var e := _by_uid(uid)
			if e != null and _foe(e) and not _big(e):
				var y := roundf(e.y - e.r * e.scale * 2.0 - 8.0)
				ci.draw_rect(Rect2(roundf(e.x) - 3, y, 2, 5), Color(0.95, 0.85, 0.5))   # the pause sign
				ci.draw_rect(Rect2(roundf(e.x) + 1, y, 2, 5), Color(0.95, 0.85, 0.5))
	for o in prisms:
		var c := Vector2(o["x"], o["y"])
		var col: Color = PRISM_COL[o["c"]]
		var a := atan2(o["vy"], o["vx"])
		var f := Vector2.from_angle(a) * 4.0
		var s := Vector2(-f.y, f.x) * 0.6
		ci.draw_colored_polygon(PackedVector2Array([c + f, c + s, c - f, c - s]), col)
		ci.draw_line(c - f * 1.5, c - f * 2.5, Color(col.r, col.g, col.b, 0.5), 1.0)
		if o["c"] == "white":
			ci.draw_rect(Rect2(roundf(c.x) - 1 + roundf(sin(t * 20.0)), roundf(c.y) - 1, 1, 1), Color(1.0, 0.4, 0.4))
	for o in clouds:
		var c := Vector2(o["x"], o["y"])
		var flash := 1.0 if o["cd"] > 0.5 else 0.0   # it lights up as it strikes
		for k in 5:   # a dark rim, then the body, then the light tops
			var off := Vector2(-12.0 + k * 6.0, sin(t * 2.0 + k) * 1.5 - (4.0 if k % 2 == 1 else 0.0))
			ci.draw_circle(c + off, 8.0 - absf(k - 2) * 0.8, Color(0.12, 0.1, 0.2))
		for k in 5:
			var off := Vector2(-12.0 + k * 6.0, sin(t * 2.0 + k) * 1.5 - (4.0 if k % 2 == 1 else 0.0))
			ci.draw_circle(c + off, 7.0 - absf(k - 2) * 0.8, Color(0.5, 0.53, 0.66).lerp(Color(0.85, 0.9, 1.0), flash))
		for k in 3:
			ci.draw_circle(c + Vector2(-6.0 + k * 6.0, -4.0), 4.0, Color(0.78, 0.82, 0.92).lerp(Color(1, 1, 0.85), flash))
		for k in 6:   # rain
			var ph := fmod(t * 3.0 + k * 0.17, 1.0)
			var rx := c.x - 10.0 + k * 4.0
			var ry := c.y + 4.0 + ph * 22.0
			ci.draw_line(Vector2(rx, ry), Vector2(rx - 1.0, ry + 3.0), Color(0.7, 0.85, 1.0, 0.6), 1.0)
		if o["tornado"]:
			var g := c + Vector2(0, 26.0)
			for k in 4:
				var ry := c.y + 6.0 + k * 5.0
				var rw := 4.0 + k * 2.5
				var a0: float = t * 14.0 + k
				ci.draw_arc(Vector2(c.x + sin(t * 3.0 + k) * 2.0, ry), rw, a0, a0 + 4.2, 10, Color(0.85, 0.9, 1.0, 0.55), 1.0)
			ci.draw_arc(g, 10.0, t * 8.0, t * 8.0 + 4.0, 12, Color(0.8, 0.85, 0.95, 0.35), 1.0)
	for o in pins:
		var tr: Array = o["trail"]
		for k in tr.size():
			var s: Vector2 = tr[k]
			ci.draw_circle(s, 3.0 - k * 0.3, Color(1.0, 0.85, 0.35, 0.5 - k * 0.05))
		var c := Vector2(o["x"], o["y"])
		ci.draw_circle(c, 3.5, Color(1.0, 0.95, 0.6))
		ci.draw_circle(c, 2.0, Color(1, 1, 1))
		if o["bounces"] > 0:
			Gfx.text(ci, "X%d" % o["bounces"], c.x, c.y - 12.0, "gold", 1, 0.5)
	for r in rings:
		var k: float = r["t"] / r["max"]
		var col: Color = r["col"]
		ci.draw_arc(Vector2(r["x"], r["y"]), lerpf(r["r0"], r["r1"], k), 0.0, TAU, 24, Color(col.r, col.g, col.b, 1.0 - k), 1.0)

## World_view._draw_enemy: wild magic made this foe a sheep; it is drawn in the foe's place.
static func draw_sheep(ci: CanvasItem, e: Enemy, t: float, foot: float) -> bool:
	if sheep.is_empty() or not sheep.has(e.uid) or e.shrink_t <= 0.0:
		return false
	Gfx.sp(ci, "s_sheep", e.x, foot, 1, 1, 0.0, e.face < 0, 1.0, Color(1, 1, 1, 1) if e.flash > 0 else Color(0, 0, 0, 0))
	if fmod(t + e.uid * 0.37, 2.0) < 0.5:
		Gfx.text(ci, "BAA", e.x, foot - 18.0, "white", 1, 0.5)
	return true

## 26: a spell cast by an item (Actions "spell", traits and synergies), at a foe's spot (x, y) or
## from the hero toward it, for dmg; skip: the foe it was cast on (prism bolts fly out of it).
static func cast(kind: String, p: Player, x: float, y: float, dmg: float, skip: int = -1) -> void:
	var a := TB.ang_xy(p.x, p.y, x, y)
	match kind:
		"void":
			_add(voids, { "x": x, "y": y, "vx": 0.0, "vy": 0.0, "t": 0.0, "life": 0.0, "dmg": dmg, "r": 44.0, "hole": true,
				"hold": HOLE_TIME * 0.8, "tick": 0.0, "held": {}, "eaten": 0, "devour": false, "crit": false, "col": "#a35bd6" })
			Snd.play("portal")
		"comet":
			var dir := Vector2.from_angle(PI / 2 + randf_range(-0.7, 0.7))
			_add(comets, { "x0": x - dir.x * 420.0, "y0": y - dir.y * 420.0, "x1": x + dir.x * 140.0, "y1": y + dir.y * 140.0,
				"tx": x, "ty": y, "kb": 420.0 / 560.0, "t": -0.3, "dur": 0.32, "dmg": dmg, "hit": {}, "burst": false,
				"w": 10.0, "hx": x - dir.x * 420.0, "hy": y - dir.y * 420.0, "crit": false, "col": "orange" }, MAX_COMETS * 3)
		"glyph":
			_add(glyphs, { "x": x, "y": y, "r": 26.0, "t": 0.0, "delay": 0.5, "dmg": dmg, "great": false, "n": 1, "twice": false,
				"pillar": 0.0, "crit": false, "col": "pink" })
		"blade":
			if blades.size() >= MAX_BLADES:
				blades.pop_front()
			blades.append({ "x": p.x + cos(a) * 14.0, "y": p.y - 6.0 + sin(a) * 8.0, "a": a, "t": 0.0, "life": 4.0, "dmg": dmg,
				"cd": 0.15, "waves": false, "crit": false, "col": "white", "i": blades.size() })
		"clock":
			_add(clocks, { "x": x, "y": y, "r": 56.0, "t": 0.0, "life": 2.0, "dmg": dmg, "frozen": {}, "shots": [], "reverse": false,
				"crit": false }, 3)
			Snd.play("bell")
		"prism":
			var cs := ["red", "blue", "green"]
			for i in 3:
				var pa := a + (i - 1) * 0.9
				_add(prisms, { "x": x, "y": y, "vx": cos(pa) * 220.0, "vy": sin(pa) * 220.0, "t": 0.0, "life": 0.6, "dmg": dmg,
					"gen": 1, "maxgen": 2, "c": cs[i], "hit": { skip: true } if skip >= 0 else {}, "crit": false }, MAX_PRISMS)
		"cloud":
			if clouds.size() >= MAX_CLOUDS:
				clouds.pop_front()
			clouds.append({ "x": x, "y": y - 34.0, "t": 0.0, "life": 4.0, "dmg": dmg, "cd": 0.3, "rain": 0.0, "tornado": false, "crit": false })
		"serpent":
			_add(serpents, { "x": p.x, "y": p.y - 3.0, "a": a, "t": 0.0, "life": 3.0, "dmg": dmg, "trail": [], "next": {},
				"coil": false, "coil_uid": -1, "coil_t": 0.0, "coiled": {}, "crush": 0.0, "fire_t": 0.0, "crit": false, "col": "orange" }, 8)
		"pinball":
			_add(pins, { "x": p.x, "y": p.y - 3.0, "vx": cos(a) * 300.0, "vy": sin(a) * 300.0, "t": 0.0, "life": 2.0, "dmg": dmg,
				"bounces": 0, "max": 6, "last": -1, "stars": false, "trail": [], "crit": false, "col": "gold" })

