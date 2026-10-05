class_name Oddities
extends RefCounted
## ROADMAP 4.6 part 4, GUNPLAY AND ODDITIES: strange guns and tricks (ideas from Enter the Gungeon,
## Cabal, Worms, Risk of Rain, GTA V, Saints Row: The Third, Dead Cells and Aion; ideas only, every
## name, picture and number is this game's own).
##
## Kinds (Combat.player_shoot calls `fire`):
##   letters  every shot is a letter of a word; the last letter's hit sets the word off
##   bubble   a bubble traps the first foe it meets; your next bubble on it pops it for more
##   flak     shots that pop the enemy shots they touch (and a barrage for every 15 popped)
##   paint    shots splash paint: what stands in it is changed by the colour
##   slots    every shot spins three reels (over the hero); a pair or three of a kind pays out
##   roller   a ball that rolls along the floor and grows, bouncing off walls
##   money    every shot spends a coin on a gold slug, harder the more gold you carry
##   camera   a flash that stuns; a foe's third photo develops into a huge crit
##   ray      a ray that freezes a foe held in it; frozen foes shatter when they die
##   junk     random junk, each its own trick; or fish that make foes slip
##   bat      a swing that knocks foes flying into each other, or a croquet roll
##   stab     quick stabs; a stab in the back always crits, twice as hard
##   duel     the first hit on each foe is a huge crit (a calling card)
##   shrink   shrunk foes deal no touch damage, take more, and are squashed when you walk on them
##   blower   a gust that turns enemy shots around and pushes foes back
##   dome     a dome by you: enemy shots that enter it pop, foes in it are hurt
##   coin     every 3rd attack flips a coin up; a shot that hits it splits into two seeking crits
## What a weapon of those kinds does differently comes from keys on its row (TWISTS).
##
## +1 PROJECTILE STACKS WITHOUT LIMIT: every kind here makes one thing an attack (a letter, a bubble,
## a slug, a ball, a swing, a flash...), and every projectile past the first adds 35% damage to it
## (a ball also grows). Slots and the coin flipper fire through the usual shot path. Things in flight
## never pass 32 (more are folded into the newest one).

const KINDS := ["letters", "bubble", "flak", "paint", "slots", "roller", "money", "camera", "ray", "junk", "bat", "stab",
	"duel", "shrink", "blower", "dome", "coin"]
## Keys a weapon row may carry to change what its kind does (the uniqueness report counts them).
const TWISTS := ["words", "soap", "barrage", "colors", "stakes", "moss", "fish", "croquet"]
const WORDS := { "BOOM": "#e8873a", "ZAP": "#6fd3e0", "ICE": "#c8f0ff", "BURN": "#d8443c", "GOLD": "#f2c94c", "DOOM": "#a35bd6" }
const REELS := ["7", "C", "B", "$", "X"]   # seven, cherries, bell, gold, bust
const MAX_SHOTS := 32
const PAINT_COL := { "ink": "#2b2238", "red": "#d8443c", "blue": "#4d9be6", "yellow": "#f2c94c" }

static var shots: Array = []      # things in flight: { k, x, y, vx, vy, life, t, dmg, r, pierce, hit, crit, col, ... }
static var word := ""             # letters: the word being typed, and how far
static var pos := 0
static var bubbled := {}          # uid -> { t, group }: foes trapped in bubbles
static var popped := 0            # flak: enemy shots popped (the interceptor's barrage at 15)
static var puddles: Array = []    # paint on the floor: { x, y, r, t, c, tick }
static var reels := ["7", "7", "7"]
static var spin_t := 0.0          # slots: the reels turning (drawn) after a shot
static var lucky := 0             # slots: shots left that crit (a pair of sevens)
static var balls: Array = []      # rollers: { x, y, vx, vy, r, t, life, dmg, hit, moss, cover }
static var photos := {}           # camera: uid -> photos taken
static var exposure := {}         # ray: uid -> seconds in the ray
static var frozen := {}           # ray: uid -> seconds left frozen (they shatter if they die)
static var floor_fish: Array = [] # fish on the floor: { x, y, t, dmg }
static var flying: Array = []     # bat: foes knocked flying: { e, t, dmg, hit }; or rolling: croquet
static var met := {}              # duel: foes already hit (the calling card is spent on them)
static var dome := {}             # aegis: { x, y, r, t, tick, dmg }
static var coins: Array = []      # coin flipper: { x, y, vx, vy, z, vz, t }
static var flips := 0
static var flashes: Array = []    # rays, cones, gusts: { k, x0, y0, x1, y1, a, arc, reach, t, max, col }
static var _room: WeakRef = null
static var _wid := ""
static var stats := {}            # how often each trick happened (tests/arsenal_test reads it)

static func _stat(k: String, n: int = 1) -> void:
	stats[k] = stats.get(k, 0) + n

static func handles(kind: String) -> bool:
	return kind in KINDS

static func _col(w: Dictionary) -> String:
	return Weapons.TAG_COLS[w["tags"][0] if w["tags"].size() > 0 else "core"][0]

static func clear() -> void:
	shots.clear()
	bubbled.clear()
	puddles.clear()
	balls.clear()
	photos.clear()
	exposure.clear()
	frozen.clear()
	floor_fish.clear()
	flying.clear()
	met.clear()
	dome = {}
	coins.clear()
	flashes.clear()
	word = ""
	pos = 0

static func _reset_weapon() -> void:
	clear()
	popped = 0
	lucky = 0
	flips = 0

## The foe nearest your aim (within about 30 degrees, 260 px), else the nearest one in sight.
static func _aimed(p: Player, a: float) -> Enemy:
	var best: Enemy = null
	var bd := 260.0
	for e in G.enemies:
		if e.targetable() and e.charm_t <= 0 and absf(TB.wrap_ang(TB.ang_to(p, e) - a)) < 0.5:
			var d := TB.dist(p, e)
			if d < bd:
				bd = d
				best = e
	return best if best != null else Combat.auto_target(p, 260)

static func _shoot(p: Player, a: float, k: String, dmg: float, extra: Dictionary) -> Dictionary:
	var o := { "k": k, "x": p.x + cos(a) * 7, "y": p.y - 3 + sin(a) * 7, "px": p.x, "py": p.y - 3, "vx": cos(a) * Weapons.wspd(p), "vy": sin(a) * Weapons.wspd(p),
		"life": Weapons.wlife(p), "t": 0.0, "dmg": dmg, "r": 3.0, "pierce": 0, "hit": {}, "crit": false, "col": _col(p.weapon) }
	o.merge(extra, true)
	if shots.size() >= MAX_SHOTS:
		shots[shots.size() - 1]["dmg"] += dmg   # past the cap: folded into the newest
		return shots[shots.size() - 1]
	shots.append(o)
	return o

# ---------- Firing (Combat.player_shoot) ----------
## Returns the player shots made (slots and the coin flipper fire through the usual shot path).
static func fire(p: Player, a: float, forced: bool) -> Array:
	var w: Dictionary = p.weapon
	var n := Weapons.wcount(p)
	var more := 1.0 + 0.35 * (n - 1)
	var dmg := Weapons.wdmg(p) * more
	match w["kind"]:
		"letters":
			if pos == 0 or word == "":
				var list: Array = w.get("words", ["BOOM"])
				word = list[randi() % list.size()]
				pos = 0
			var ch := word.substr(pos, 1)
			pos += 1
			var last := pos >= word.length()
			_shoot(p, a, "letter", dmg, { "ch": ch, "last": last, "word": word, "crit": forced, "col": WORDS.get(word, "#f4ecd8") })
			if last:
				pos = 0
				word = ""
			Snd.play("select")
		"bubble":
			var soap: bool = w.get("soap", false)
			_shoot(p, a, "bubble", dmg, { "r": 9.0 if soap else 5.0, "pierce": 2 if soap else 0, "soap": soap, "crit": forced,
				"group": randi() })
			Snd.play("dodge")
		"flak":
			_shoot(p, a + randf_range(-0.05, 0.05), "flak", dmg, { "r": 3.0, "pops": 3, "pierce": 1, "crit": forced })
			if p.shot_n % 2 == 0:
				Snd.play("shoot")
		"paint":
			var cols: Array = w.get("colors", ["ink"])
			var c: String = cols[p.shot_n % cols.size()]
			_shoot(p, a, "paint", dmg, { "r": 3.5, "paint": c, "col": PAINT_COL[c], "crit": forced })
			Snd.play("dodge")
		"slots":
			var made := Combat.fire_projectiles(p, a)
			if lucky > 0:
				lucky -= 1
				for b in made:
					b.crit = true
			_spin(p, w, more)
			return made
		"roller":
			if balls.size() >= 4:
				balls.pop_front()
			var moss: bool = w.get("moss", false)
			balls.append({ "x": p.x + cos(a) * 8, "y": p.y + sin(a) * 6, "vx": cos(a) * Weapons.wspd(p), "vy": sin(a) * Weapons.wspd(p),
				"r": 4.0 * minf(2.0, 1.0 + 0.06 * sqrt(float(n - 1))), "t": 0.0, "life": Weapons.wlife(p), "dmg": dmg, "hit": {}, "moss": moss,
				"cover": 0.0 })
			_stat("roll")
			Snd.play("place")
		"money":
			if p.gold > 0:
				p.gold -= 1
				var rich := 1.0 + p.gold / 100.0
				_shoot(p, a, "slug", dmg * 3.0 * rich, { "r": 4.0, "pierce": 1, "crit": forced, "col": "#f2c94c" })
				_stat("slug")
				Snd.play("coin")
			else:
				_shoot(p, a, "lint", dmg * 0.3, { "r": 2.0, "col": "#8b8f9c" })
				_stat("lint")
				Snd.play("deny")
		"camera":
			_flash(p, a, dmg, forced)
		"ray":
			_ray(p, a, dmg, forced, w)
		"junk":
			if w.get("fish", false):
				_shoot(p, a, "fish", dmg, { "r": 3.0, "life": 0.4, "crit": forced, "col": "#6fd3e0" })
				_stat("fish")
			else:
				var j: String = ["boot", "can", "bottle", "tire"][p.shot_n % 4]   # in turn
				_shoot(p, a, "junk", dmg, { "j": j, "r": 4.0 if j == "tire" else 3.0, "pierce": 99 if j == "tire" else 0,
					"bounce": 3 if j == "can" else 0, "life": Weapons.wlife(p) * (1.6 if j == "tire" else 1.0), "crit": forced })
				_stat("junk_" + j)
			Snd.play("hatchet")
		"bat":
			_swing(p, a, w, dmg, forced)
		"stab":
			_stab(p, a, w, dmg, forced)
		"duel":
			_shoot(p, a, "card", dmg, { "r": 3.0, "crit": forced, "col": "#f4ecd8" })
			Snd.play("bolt")
		"shrink":
			_shoot(p, a, "shrink", dmg, { "r": 3.0, "crit": forced, "col": "#e86fb4" })
			Snd.play("beam")
		"blower":
			_gust(p, a, dmg)
		"dome":
			if dome.is_empty() or TB.dist_xy(dome["x"], dome["y"], p.x, p.y) > 20.0:
				dome = { "x": p.x, "y": p.y, "r": 34.0, "t": 4.0, "tick": 0.0, "dmg": dmg }
				_stat("dome")
				Snd.play("place")
			dome["t"] = 4.0
			dome["dmg"] = dmg
			_lance(p, dmg * 1.5, forced)
		"coin":
			var made := Combat.fire_projectiles(p, a)
			flips += 1
			if flips % 3 == 0:
				# A coin tossed spinning along your line of fire; a shot that hits it splits.
				coins.append({ "x": p.x + cos(a) * 10, "y": p.y - 2 + sin(a) * 10, "vx": cos(a) * 45.0, "vy": sin(a) * 45.0, "t": 0.0 })
				_stat("flip")
				Snd.play("coin")
			return made
	return []

## The reels: a pair or three of a kind pays out (the gilded slots stake a coin a spin, for bigger pay).
static func _spin(p: Player, w: Dictionary, more: float) -> void:
	var stake: bool = w.get("stakes", false) and p.gold > 0
	if stake:
		p.gold -= 1
		_stat("stake")
	var pay := 3.0 if stake else 1.0
	reels = [REELS[randi() % 5], REELS[randi() % 5], REELS[randi() % 5]]
	spin_t = 0.25
	var s: String = reels[0]
	var three: bool = reels[0] == reels[1] and reels[1] == reels[2]
	if not three:
		s = reels[1] if reels[1] == reels[2] or reels[1] == reels[0] else (reels[2] if reels[2] == reels[0] else "")
	if s == "" or s == "X":
		return
	var dmg := Weapons.wdmg(p) * more * pay
	if three:
		_stat("triple")
		match s:
			"7":
				_stat("jackpot")
				Fx.float_text(p.x, p.y - 34, "JACKPOT!", "gold", true)
				Arsenal.blast(p.x, p.y, dmg * 10.0, 70.0, "#f2c94c")
				for i in roundi(6 * pay):
					Combat.drop_pickup("coin", p.x, p.y)
				Snd.play("unlock")
			"C":
				for i in 12:
					Combat._raw_shot(p.x, p.y - 3, TAU * i / 12.0, 200, dmg * 1.2, 0.6, 2.5, 0, "spark", {})
			"B":
				_bells(p, 5, dmg * 2.5)
			"$":
				for i in roundi(4 * pay):
					Combat.drop_pickup("coin", p.x, p.y)
				Snd.play("coin")
		return
	_stat("pair")
	match s:
		"7":
			lucky = 3
			Fx.float_text(p.x, p.y - 34, "LUCKY", "gold")
		"C":
			for i in 6:
				Combat._raw_shot(p.x, p.y - 3, TAU * i / 6.0 + randf(), 180, dmg * 0.8, 0.5, 2.0, 0, "spark", {})
		"B":
			_bells(p, 1, dmg * 2.0)
		"$":
			if randf() < 0.25 * pay:
				Combat.drop_pickup("coin", p.x, p.y)

static func _bells(p: Player, n: int, dmg: float) -> void:
	var foes := G.enemies.filter(func(e): return e.targetable() and e.charm_t <= 0 and TB.dist(p, e) < 220)
	foes.shuffle()
	for e in foes.slice(0, n):
		Combat.lightning(e, dmg)

## The camera: a flash in front; stuns, and each foe's third photo develops into a huge crit.
static func _flash(p: Player, a: float, dmg: float, forced: bool) -> void:
	var arc := deg_to_rad(64.0)
	for e in G.enemies.duplicate():
		if not e.targetable() or e.charm_t > 0 or TB.dist(p, e) - e.r > 76.0 or absf(TB.wrap_ang(TB.ang_to(p, e) - a)) > arc / 2:
			continue
		if not e.is_boss():
			e.stun_t = maxf(e.stun_t, 0.5)
		var n: int = photos.get(e.uid, 0) + 1
		var hit := dmg * 0.5
		var crit := forced
		if n >= 3:
			# Developed: the third photo.
			n = 0
			hit = dmg * 6.0
			crit = true
			Fx.float_text(e.x, e.y - e.r - 12, "DEVELOPED", "white")
			_stat("develop")
		photos[e.uid] = n
		var c := Combat.damage_enemy(e, hit, { "force_crit": crit, "col": "white" })
		Combat.on_hit_effects(e, hit, c, p, null)
		_stat("photo")
	flashes.append({ "k": "cone", "x0": p.x, "y0": p.y - 3, "a": a, "arc": arc, "reach": 76.0, "t": 0.12, "max": 0.12, "col": "#ffffff" })
	Snd.play("lock")

## The glacier ray: the first foe along the aim; held in it 1.2 s, it freezes solid.
static func _ray(p: Player, a: float, dmg: float, forced: bool, w: Dictionary) -> void:
	var x0 := p.x + cos(a) * 6
	var y0 := p.y - 3 + sin(a) * 6
	var hit: Enemy = null
	var d := 0.0
	while d < 150.0 and hit == null:
		d += 4.0
		var x := x0 + cos(a) * d
		var y := y0 + sin(a) * d
		if World.solid(G.room, floori(x / TB.TS), floori(y / TB.TS), World.M_BULLET):
			break
		for e in G.enemies:
			if e.targetable() and e.charm_t <= 0 and TB.dist_xy(e.x, e.y, x, y) < e.r + 2:
				hit = e
				break
	flashes.append({ "k": "ray", "x0": x0, "y0": y0, "x1": x0 + cos(a) * d, "y1": y0 + sin(a) * d, "t": 0.14, "max": 0.14, "col": "#c8f0ff" })
	if hit == null:
		return
	var c := Combat.damage_enemy(hit, dmg, { "force_crit": forced, "col": "cyan", "silent": true })
	Combat.on_hit_effects(hit, dmg, c, p, null)
	hit.chill_t = maxf(hit.chill_t, 0.5)
	var held: float = exposure.get(hit.uid, 0.0) + 1.0 / maxf(1.0, Weapons.wrate(p))
	if held >= 1.2 and not hit.is_boss():
		held = 0.0
		frozen[hit.uid] = 2.0
		hit.stun_t = maxf(hit.stun_t, 2.0)
		hit.chill_t = maxf(hit.chill_t, 4.0)
		Fx.float_text(hit.x, hit.y - hit.r - 10, "FROZEN", "cyan")
		_stat("freeze")
	exposure[hit.uid] = held

## The bat: a swing that knocks foes flying (into other foes and walls); the mallet: a croquet roll.
static func _swing(p: Player, a: float, w: Dictionary, dmg: float, forced: bool) -> void:
	var croquet: bool = w.get("croquet", false)
	var reach := Weapons.wrange(p)
	var arc := deg_to_rad(w.get("arc", 120))
	var best: Enemy = null
	for e in G.enemies.duplicate():
		if not e.targetable() or e.charm_t > 0 or TB.dist(e, p) - e.r > reach or absf(TB.wrap_ang(TB.ang_to(p, e) - a)) > arc / 2:
			continue
		var c := Combat.damage_enemy(e, dmg, { "force_crit": forced })
		Combat.on_hit_effects(e, dmg, c, p, null)
		Afx.cut(e.x, e.y - e.z, TB.ang_to(p, e), true)
		if e.hp <= 0 or e.is_boss() or e.d.get("mini", false):
			continue
		if croquet:
			if best == null or TB.dist(e, p) < TB.dist(best, p):
				best = e
		else:
			var ka := TB.ang_to(p, e)
			flying.append({ "e": weakref(e), "vx": cos(ka) * 260.0, "vy": sin(ka) * 260.0, "t": 0.6, "dmg": dmg, "hit": {}, "roll": 0 })
			_stat("launch")
	if best != null:
		# Croquet: the foe rolls straight along your aim, off two walls, through every foe in the way.
		flying.append({ "e": weakref(best), "vx": cos(a) * 220.0, "vy": sin(a) * 220.0, "t": 2.0, "dmg": dmg * 1.2, "hit": {}, "roll": 2 })
		_stat("croquet")
	G.swings.append({ "kind": "slash", "x": p.x, "y": p.y - 2, "a": a, "r": reach, "arc": arc, "t": 0.16, "max": 0.16,
		"tag": w["tags"][0] if w["tags"].size() > 0 else "" })
	Snd.play("hit")

## Quick stabs: a stab in the back (the foe facing away) always crits, twice as hard.
static func _stab(p: Player, a: float, w: Dictionary, dmg: float, forced: bool) -> void:
	var reach := Weapons.wrange(p)
	for e in G.enemies.duplicate():
		if not e.targetable() or e.charm_t > 0 or TB.dist(e, p) - e.r > reach or absf(TB.wrap_ang(TB.ang_to(p, e) - a)) > 0.7:
			continue
		var back: bool = (p.x - e.x) * e.face < 0 and not e.is_boss()
		var hit := dmg * (2.0 if back else 1.0)
		var c := Combat.damage_enemy(e, hit, { "force_crit": forced or back, "kx": cos(a) * 30, "ky": sin(a) * 30 })
		Combat.on_hit_effects(e, hit, c, p, null)
		Afx.cut(e.x, e.y - e.z, a, back)
		if back:
			_stat("backstab")
	G.swings.append({ "kind": "thrust", "x": p.x, "y": p.y - 2, "a": a, "len": reach, "width": 6.0, "t": 0.08, "max": 0.08,
		"tag": w["tags"][0] if w["tags"].size() > 0 else "" })
	Snd.play("hatchet")

## The leaf blower: enemy shots in the gust turn around (now yours); foes in it are pushed back.
static func _gust(p: Player, a: float, dmg: float) -> void:
	var arc := deg_to_rad(50.0)
	var reach := 80.0
	for i in EBullets.n:
		if not EBullets.alive(i) or EBullets.blife[i] <= 0:
			continue
		var bx := EBullets.bx[i]
		var by := EBullets.by[i]
		if TB.dist_xy(bx, by, p.x, p.y) > reach or absf(TB.wrap_ang(atan2(by - p.y, bx - p.x) - a)) > arc / 2:
			continue
		EBullets.blife[i] = EBullets.KILLED
		var sp := maxf(120.0, Vector2(EBullets.bvx[i], EBullets.bvy[i]).length())
		Combat._raw_shot(bx, by, atan2(-EBullets.bvy[i], -EBullets.bvx[i]), sp, dmg, 1.2, 2.5, 0, "spark", {})
		_stat("turned")
	for e in G.enemies.duplicate():
		if not e.targetable() or e.charm_t > 0 or TB.dist(p, e) - e.r > reach or absf(TB.wrap_ang(TB.ang_to(p, e) - a)) > arc / 2:
			continue
		var ka := TB.ang_to(p, e)
		var c := Combat.damage_enemy(e, dmg * 0.3, { "kx": cos(ka) * 160, "ky": sin(ka) * 160, "silent": true })
		Combat.on_hit_effects(e, dmg * 0.3, c, p, null)
		_stat("blown")
	flashes.append({ "k": "gust", "x0": p.x, "y0": p.y - 3, "a": a, "arc": arc, "reach": reach, "t": 0.18, "max": 0.18, "col": "#c9c2a8" })
	Snd.play("dodge")

## The aegis: a lance of light from the dome at the nearest foe (walls stop it).
static func _lance(p: Player, dmg: float, forced: bool) -> void:
	var x0: float = dome["x"]
	var y0: float = dome["y"] - 8.0
	var e := Combat.nearest_enemy(x0, y0, 220)
	if e == null or e.charm_t > 0:
		return
	var a := TB.ang_xy(x0, y0, e.x, e.y)
	var d := 0.0
	var to := TB.dist_xy(x0, y0, e.x, e.y)
	while d < to:
		d += 4.0
		if World.solid(G.room, floori((x0 + cos(a) * d) / TB.TS), floori((y0 + sin(a) * d) / TB.TS), World.M_BULLET):
			break
	flashes.append({ "k": "ray", "x0": x0, "y0": y0, "x1": x0 + cos(a) * minf(d, to), "y1": y0 + sin(a) * minf(d, to), "t": 0.14, "max": 0.14,
		"col": "#fffbe0" })
	if d < to:
		return
	var c := Combat.damage_enemy(e, dmg, { "force_crit": forced })
	Combat.on_hit_effects(e, dmg, c, p, null)
	_stat("lance")
	Snd.play("beam")

## A kill (Combat.kill_enemy): a frozen foe shatters into ice.
static func on_kill(e: Enemy) -> void:
	if not frozen.has(e.uid):
		return
	frozen.erase(e.uid)
	var p := G.player
	for i in 6:
		Combat._raw_shot(e.x, e.y, TAU * i / 6.0 + randf() * 0.4, 190, Weapons.wdmg(p) * 1.5, 0.45, 2.0, 0, "spark", {})
	Vfx.puff(e.x, e.y, "frost")
	_stat("shatter")

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
	spin_t = maxf(0.0, spin_t - dt)
	if not shots.is_empty():
		_tick_shots(p, room, dt)
	if not bubbled.is_empty():
		for uid in bubbled.keys():
			bubbled[uid]["t"] -= dt
			if bubbled[uid]["t"] <= 0:
				bubbled.erase(uid)   # the bubble pops by itself
	if not puddles.is_empty():
		_tick_puddles(p, dt)
	if not balls.is_empty():
		_tick_balls(p, room, dt)
	if not frozen.is_empty():
		for uid in frozen.keys():
			frozen[uid] -= dt
			if frozen[uid] <= 0:
				frozen.erase(uid)
	if not floor_fish.is_empty():
		_tick_fish(p, dt)
	if not flying.is_empty():
		_tick_flying(p, room, dt)
	if not dome.is_empty():
		_tick_dome(p, dt)
	if not coins.is_empty():
		_tick_coins(p, dt)
	# Shrunk foes: their time runs out; walk onto one and it is squashed.
	for e in G.enemies.duplicate():
		if e.shrink_t > 0:
			e.shrink_t -= dt
			if e.hp > 0 and e.targetable() and TB.dist(p, e) < p.r + e.r * 0.5 + 2:
				var c := Combat.damage_enemy(e, e.hp * 2.0 + 1.0, { "no_crit": true, "no_mult": true })
				Combat.on_hit_effects(e, 0.0, c, p, null)
				Fx.float_text(e.x, e.y - 10, "SQUASH", "pink")
				_stat("squash")
	if not flashes.is_empty():
		var kf := []
		for f in flashes:
			f["t"] -= dt
			if f["t"] > 0:
				kf.append(f)
		flashes = kf

static func _tick_shots(p: Player, room: Room, dt: float) -> void:
	var keep := []
	for o in shots:
		o["t"] += dt
		var nx: float = o["x"] + o["vx"] * dt
		var ny: float = o["y"] + o["vy"] * dt
		var wall_x := World.solid(room, floori(nx / TB.TS), floori(o["y"] / TB.TS), World.M_BULLET)
		var wall_y := World.solid(room, floori(o["x"] / TB.TS), floori(ny / TB.TS), World.M_BULLET)
		if wall_x or wall_y:
			if o.get("bounce", 0) > 0:
				o["bounce"] -= 1
				if wall_x:
					o["vx"] = -o["vx"]
				if wall_y:
					o["vy"] = -o["vy"]
				o["px"] = o["x"]
				o["py"] = o["y"]
				_stat("can_bounce")
				keep.append(o)
				continue
			_end(o, p)
			continue
		var x0: float = o["px"]
		var y0: float = o["py"]
		o["px"] = nx
		o["py"] = ny
		o["x"] = nx
		o["y"] = ny
		var alive := true
		if o["k"] == "flak" and o["pops"] > 0:
			# Flak pops the enemy shots it touches.
			for i in EBullets.n:
				if EBullets.alive(i) and EBullets.blife[i] > 0 and TB.dist_xy(EBullets.bx[i], EBullets.by[i], nx, ny) < EBullets.br[i] + 4.0:
					EBullets.blife[i] = EBullets.KILLED
					Fx.burst(nx, ny, ["#f2c94c", "#ffffff"], 4, 40, 0.15)
					o["pops"] -= 1
					popped += 1
					_stat("pop")
					if p.weapon.get("barrage", 0) > 0 and popped % int(p.weapon["barrage"]) == 0:
						# The interceptor: a counter barrage for every 15 popped.
						for k in 12:
							Combat._raw_shot(p.x, p.y - 3, TAU * k / 12.0, 230, Weapons.wdmg(p) * 1.2, 0.7, 2.5, 0, "spark", {})
						_stat("barrage")
						Fx.float_text(p.x, p.y - 26, "COUNTER", "orange")
					if o["pops"] <= 0:
						break
		for e in G.enemies.duplicate():
			if not e.targetable() or e.charm_t > 0 or o["hit"].has(e.uid) or not Arsenal.swept(e, x0, y0, nx, ny, e.r + o["r"]):
				continue
			o["hit"][e.uid] = true
			_hit(o, e, p)
			if o["pierce"] <= 0:
				alive = false
				break
			o["pierce"] -= 1
		if not alive:
			if o["k"] in ["paint", "fish"]:
				_end(o, p)
			continue
		if o["t"] >= o["life"]:
			_end(o, p)
			continue
		keep.append(o)
	shots = keep

## A shot of this module hits a foe.
static func _hit(o: Dictionary, e: Enemy, p: Player) -> void:
	var dmg: float = o["dmg"]
	var crit: bool = o["crit"]
	match o["k"]:
		"bubble":
			if bubbled.has(e.uid):
				# Popped: a trapped foe hit by a bubble (the soap's whole group).
				var group: int = bubbled[e.uid]["group"]
				var pops := []
				for uid in bubbled.keys():
					if uid == e.uid or (o["soap"] and bubbled[uid]["group"] == group):
						pops.append(uid)
				if pops.size() > 1:
					_stat("soap_pop")
				for f in G.enemies.duplicate():
					if pops.has(f.uid) and f.hp > 0:
						bubbled.erase(f.uid)
						var hit := dmg * (3.0 if f == e else 2.0)
						var c := Combat.damage_enemy(f, hit, { "force_crit": crit })
						Combat.on_hit_effects(f, hit, c, p, null)
						Fx.burst(f.x, f.y - 4, ["#c8f0ff", "#ffffff"], 8, 60, 0.25)
						_stat("pop_bubble")
				Snd.play("hit")
				return
			if e.is_boss() or e.d.get("mini", false):
				# Too big to trap: the bubble bursts on it instead.
				var hb := dmg * 1.5
				var cb := Combat.damage_enemy(e, hb, { "force_crit": crit })
				Combat.on_hit_effects(e, hb, cb, p, null)
				Fx.burst(e.x, e.y - 4, ["#c8f0ff", "#ffffff"], 6, 50, 0.2)
				_stat("burst_big")
				return
			var c := Combat.damage_enemy(e, dmg * 0.5, { "force_crit": crit })
			Combat.on_hit_effects(e, dmg * 0.5, c, p, null)
			if e.hp > 0:
				bubbled[e.uid] = { "t": 2.5, "group": o["group"] }
				e.stun_t = maxf(e.stun_t, 2.5)
				_stat("trap")
			return
		"card":
			if not met.has(e.uid):
				met[e.uid] = true
				dmg *= 4.0
				crit = true
				Fx.float_text(e.x, e.y - e.r - 12, "CALLING CARD", "white")
				_stat("calling")
		"shrink":
			if not e.is_boss() and not e.d.get("mini", false) and not e.d.get("champion", false):
				if e.shrink_t <= 0:
					_stat("shrink")
				e.shrink_t = maxf(e.shrink_t, 5.0)
				Statuses.apply(e, "vulnerable", 1.7, dmg)
			else:
				dmg *= 2.5   # too big to shrink: it hurts them instead
				_stat("shrink_big")
		"letter":
			if o["last"]:
				_word(o, e, p)
		"junk":
			match o["j"]:
				"boot":
					e.kx += o["vx"] * 1.5
					e.ky += o["vy"] * 1.5
					_stat("boot")
				"bottle":
					for i in 5:
						Combat._raw_shot(e.x, e.y, atan2(o["vy"], o["vx"]) + (i - 2) * 0.4, 180, dmg * 0.4, 0.35, 2.0, 0, "spark", {})
					_stat("bottle")
		"fish":
			o["x"] = e.x
			o["y"] = e.y + e.r
	var c := Combat.damage_enemy(e, dmg, { "force_crit": crit })
	Combat.on_hit_effects(e, dmg, c, p, null)

## A shot of this module ends (a wall, its life, or the foe it hit): paint, fish, a fizzled word.
static func _end(o: Dictionary, p: Player) -> void:
	match o["k"]:
		"paint":
			if puddles.size() >= 16:
				puddles.pop_front()
			puddles.append({ "x": o["x"], "y": o["y"], "r": 16.0, "t": 5.0, "c": o["paint"], "tick": 0.0, "seed": randf() * TAU })
			_stat("paint_" + String(o["paint"]))
		"fish":
			if floor_fish.size() < 12:
				floor_fish.append({ "x": o["x"], "y": o["y"], "t": 5.0, "dmg": o["dmg"] })
		"letter":
			if o["last"] and o["hit"].is_empty():
				_stat("fizzle")

## The last letter of a word hits: the word happens there.
static func _word(o: Dictionary, e: Enemy, p: Player) -> void:
	var w: String = o["word"]
	var dmg: float = o["dmg"]
	Fx.float_text(e.x, e.y - e.r - 14, w + "!", "white", true)
	_stat("word_" + w)
	_stat("word")
	match w:
		"BOOM":
			Arsenal.blast(e.x, e.y, dmg * 6.0, 40.0, "#e8873a")
		"ZAP":
			var near := G.enemies.filter(func(f): return f.targetable() and f.charm_t <= 0 and TB.dist(f, e) < 90)
			for f in near.slice(0, 4):
				Combat.lightning(f, dmg * 2.5)
		"ICE":
			for f in G.enemies:
				if f.targetable() and TB.dist(f, e) < 40 + f.r and not f.is_boss():
					f.stun_t = maxf(f.stun_t, 1.5)
					f.chill_t = maxf(f.chill_t, 4.0)
			Vfx.nova(e.x, e.y, 40.0, "frost")
		"BURN":
			if G.zones.size() < 60:
				G.zones.append({ "x": e.x, "y": e.y + 2, "r": 30, "t": 3.0, "kind": "fire", "tick": 0.0 })
			for f in G.enemies:
				if f.targetable() and TB.dist(f, e) < 40 + f.r:
					Statuses.apply(f, "burn", 1, dmg)
		"GOLD":
			for i in 3:
				Combat.drop_pickup("coin", e.x, e.y)
		"DOOM":
			Arsenal.plant(e, 1.5, dmg * 8.0, 24.0)

static func _tick_puddles(p: Player, dt: float) -> void:
	var keep := []
	for u in puddles:
		u["t"] -= dt
		if u["t"] <= 0:
			continue
		keep.append(u)
		u["tick"] -= dt
		if u["tick"] > 0:
			continue
		u["tick"] = 0.25
		var x: float = u["x"]
		var y: float = u["y"]
		var r: float = u["r"]
		if u["c"] == "yellow":
			if TB.dist_xy(p.x, p.y, x, y) < r + 2:
				p.haste_t = maxf(p.haste_t, 0.3)   # yellow paint: faster, and firing faster
				_stat("haste")
			continue
		for e in G.enemies:
			if not e.targetable() or TB.dist_xy(e.x, e.y, x, y) > r + e.r:
				continue
			match u["c"]:
				"ink":
					e.chill_t = maxf(e.chill_t, 0.4)
					Statuses.apply(e, "vulnerable", 0.15, 0.0)
					_stat("inked")
				"red":
					Statuses.apply(e, "burn", 1, Weapons.wdmg(p))
					_stat("painted_burn")
				"blue":
					e.chill_t = maxf(e.chill_t, 1.0)
					_stat("painted_chill")
	puddles = keep

static func _tick_balls(p: Player, room: Room, dt: float) -> void:
	var keep := []
	for o in balls:
		o["t"] += dt
		if o["cover"] > 0:
			# A moss boulder at rest: cover that stops enemy shots.
			o["cover"] -= dt
			EBullets.kill_radius(o["x"], o["y"] - o["r"], o["r"] + 2.0)
			if o["cover"] > 0:
				keep.append(o)
			continue
		o["r"] = minf(o["r"] + 4.0 * dt, 16.0)
		var nx: float = o["x"] + o["vx"] * dt
		var ny: float = o["y"] + o["vy"] * dt
		if World.solid(room, floori(nx / TB.TS), floori(o["y"] / TB.TS), World.M_WALKER):
			o["vx"] = -o["vx"]
			nx = o["x"]
		if World.solid(room, floori(o["x"] / TB.TS), floori(ny / TB.TS), World.M_WALKER):
			o["vy"] = -o["vy"]
			ny = o["y"]
		o["x"] = nx
		o["y"] = ny
		for uid in o["hit"].keys():
			o["hit"][uid] -= dt
			if o["hit"][uid] <= 0:
				o["hit"].erase(uid)
		var rr: float = o["r"]
		for e in G.enemies.duplicate():
			if not e.targetable() or e.charm_t > 0 or o["hit"].has(e.uid) or TB.dist_xy(e.x, e.y, nx, ny) >= e.r + rr:
				continue
			o["hit"][e.uid] = 0.5
			var dm: float = o["dmg"] * (0.5 + rr / 8.0)
			var c := Combat.damage_enemy(e, dm, { "kx": o["vx"] * 0.4, "ky": o["vy"] * 0.4 })
			Combat.on_hit_effects(e, dm, c, p, null)
			if not o["moss"]:
				e.chill_t = maxf(e.chill_t, 1.5)
			_stat("ball_hit")
		if o["t"] >= o["life"]:
			if o["moss"]:
				o["cover"] = 5.0
				_stat("cover")
				keep.append(o)
			else:
				Arsenal.blast(o["x"], o["y"], o["dmg"] * (0.5 + rr / 8.0), rr + 14.0, "#c8f0ff")
				Vfx.puff(o["x"], o["y"], "frost")
			continue
		keep.append(o)
	balls = keep

static func _tick_fish(p: Player, dt: float) -> void:
	var keep := []
	for f in floor_fish:
		f["t"] -= dt
		if f["t"] <= 0:
			continue
		var slipped := false
		for e in G.enemies.duplicate():
			if e.targetable() and e.charm_t <= 0 and not e.d.get("fly", false) and TB.dist_xy(e.x, e.y, f["x"], f["y"]) < e.r + 5:
				if not e.is_boss():
					e.stun_t = maxf(e.stun_t, 1.0)
				var c := Combat.damage_enemy(e, f["dmg"] * 1.5, {})
				Combat.on_hit_effects(e, f["dmg"] * 1.5, c, p, null)
				Fx.float_text(e.x, e.y - e.r - 10, "SLIP", "cyan")
				_stat("slip")
				slipped = true
				break
		if not slipped:
			keep.append(f)
	floor_fish = keep

static func _tick_flying(p: Player, room: Room, dt: float) -> void:
	var keep := []
	for f in flying:
		var e: Enemy = f["e"].get_ref()
		f["t"] -= dt
		if e == null or e.hp <= 0 or f["t"] <= 0:
			continue
		e.stun_t = maxf(e.stun_t, 0.1)
		var mode := World.M_FLYER if e.d.get("fly", false) else World.M_WALKER
		var hit_wall := World.move_body(room, e, f["vx"] * dt, f["vy"] * dt, mode)
		if hit_wall != 0:
			if f["roll"] > 0:
				# Croquet: off the wall, and on.
				f["roll"] -= 1
				if hit_wall & World.HIT_X:
					f["vx"] = -f["vx"]
				if hit_wall & World.HIT_Y:
					f["vy"] = -f["vy"]
				_stat("croquet_bounce")
			else:
				var c := Combat.damage_enemy(e, f["dmg"] * 1.5, { "col": "orange" })
				Combat.on_hit_effects(e, f["dmg"] * 1.5, c, p, null)
				Fx.float_text(e.x, e.y - e.r - 10, "SLAM", "orange")
				_stat("bat_slam")
				G.add_shake(2)
				continue
		# Billiards: a foe knocked into another one hurts both, and sends it on.
		for o in G.enemies.duplicate():
			if o == e or not o.targetable() or f["hit"].has(o.uid) or TB.dist(o, e) >= o.r + e.r + 2:
				continue
			f["hit"][o.uid] = true
			for t in [o, e]:
				var c := Combat.damage_enemy(t, f["dmg"], { "silent": t == e })
				Combat.on_hit_effects(t, f["dmg"], c, p, null)
			if not o.is_boss() and f["roll"] == 0:
				o.kx += f["vx"] * 0.6
				o.ky += f["vy"] * 0.6
			_stat("billiard" if f["roll"] == 0 else "croquet_hit")
			Snd.play("hit")
		f["vx"] *= pow(0.4, dt) if f["roll"] == 0 else 1.0
		f["vy"] *= pow(0.4, dt) if f["roll"] == 0 else 1.0
		keep.append(f)
	flying = keep

static func _tick_dome(p: Player, dt: float) -> void:
	dome["t"] -= dt
	if dome["t"] <= 0:
		dome = {}
		return
	var x: float = dome["x"]
	var y: float = dome["y"]
	var r: float = dome["r"]
	for i in EBullets.n:
		if EBullets.alive(i) and EBullets.blife[i] > 0 and TB.dist_xy(EBullets.bx[i], EBullets.by[i], x, y) < r:
			EBullets.blife[i] = EBullets.KILLED
			Fx.burst(EBullets.bx[i], EBullets.by[i], ["#6fd3e0", "#ffffff"], 3, 30, 0.15)
			_stat("dome_pop")
	dome["tick"] -= dt
	if dome["tick"] <= 0:
		dome["tick"] = 0.5
		for e in G.enemies.duplicate():
			if e.targetable() and e.charm_t <= 0 and TB.dist_xy(e.x, e.y, x, y) < r + e.r:
				var c := Combat.damage_enemy(e, dome["dmg"] * 0.8, { "col": "cyan", "silent": true })
				Combat.on_hit_effects(e, dome["dmg"] * 0.8, c, p, null)
				_stat("dome_hit")

static func _tick_coins(p: Player, dt: float) -> void:
	var keep := []
	for c in coins:
		c["t"] += dt
		c["x"] += c["vx"] * dt
		c["y"] += c["vy"] * dt
		if c["t"] >= 1.4:
			continue   # nobody shot it: gone
		var cy: float = c["y"]
		var split := false
		for b in G.pbullets:
			if b.life > 0 and TB.dist_xy(b.x, b.y, c["x"], cy) < b.r + 4.0:
				# Shot: the coin splits it into two crits that seek the nearest foes.
				b.life = 0.0
				var foes := G.enemies.filter(func(e): return e.targetable() and e.charm_t <= 0)
				foes.sort_custom(func(e1, e2): return TB.dist_xy(e1.x, e1.y, c["x"], cy) < TB.dist_xy(e2.x, e2.y, c["x"], cy))
				for i in 2:
					var a := TB.ang_xy(c["x"], cy, foes[i].x, foes[i].y) if i < foes.size() else randf() * TAU
					var s := Combat._raw_shot(c["x"], cy, a, 320, b.dmg * 2.0, 0.8, 2.5, 0, "bolt", {}, 8.0)
					s.crit = true
				Fx.burst(c["x"], cy, ["#f2c94c", "#ffffff"], 8, 70, 0.25)
				Snd.play("coin")
				_stat("ricochet")
				split = true
				break
		if not split:
			keep.append(c)
	coins = keep

# ---------- Drawing ----------
## On the floor (world_view, after summons.gd's): paint, fish, the dome, rollers, the ray's frost.
static func draw_floor(ci: CanvasItem, t: float) -> void:
	for u in puddles:
		var c := TB.c(PAINT_COL[u["c"]])
		var fade := clampf(u["t"], 0.0, 1.0)
		var at := Vector2(u["x"], u["y"])
		var s: float = u["seed"]
		ci.draw_circle(at, u["r"] * 0.8, Color(c.r, c.g, c.b, 0.5 * fade))
		for i in 3:
			var q: Vector2 = at + Vector2.from_angle(s + i * 2.1) * u["r"] * 0.55
			ci.draw_circle(q, u["r"] * 0.45, Color(c.r, c.g, c.b, 0.5 * fade))
	for f in floor_fish:
		var flop := floori(t * 6.0 + f["x"]) % 2 == 0
		Gfx.sp(ci, "s_fish", f["x"], f["y"] + 3, 1.0, 1.0, 0.3 if flop else -0.3, flop)
	if not dome.is_empty():
		var k := clampf(dome["t"], 0.0, 1.0)
		ci.draw_circle(Vector2(dome["x"], dome["y"]), dome["r"], Color(0.43, 0.83, 0.88, 0.12 * k))
		ci.draw_arc(Vector2(dome["x"], dome["y"]), dome["r"], 0.0, TAU, 36, Color(0.78, 0.94, 1.0, 0.7 * k), 1.0)
		for i in 6:
			var a := i * PI / 3 + t * 0.5
			var q: Vector2 = Vector2(dome["x"], dome["y"]) + Vector2.from_angle(a) * dome["r"]
			ci.draw_rect(Rect2(roundf(q.x) - 1, roundf(q.y) - 1, 2, 2), Color(1, 1, 1, 0.8 * k))
	for o in balls:
		var at := Vector2(o["x"], o["y"] - o["r"])
		var r: float = o["r"]
		ci.draw_circle(Vector2(o["x"], o["y"] + 1), r * 0.9, Color(0, 0, 0, 0.25))
		ci.draw_circle(at, r + 1, TB.c("#140f1c"))
		if o["moss"]:
			ci.draw_circle(at, r, TB.c("#5c5a78"))
			ci.draw_circle(at + Vector2(-r * 0.3, -r * 0.4), r * 0.45, TB.c("#63b84f"))
			ci.draw_circle(at + Vector2(r * 0.35, r * 0.1), r * 0.3, TB.c("#3f7a5a"))
		else:
			ci.draw_circle(at, r, TB.c("#f4ecd8"))
			ci.draw_circle(at + Vector2(-r * 0.3, -r * 0.3), r * 0.4, TB.c("#ffffff"))
			var sa: float = o["t"] * 6.0
			ci.draw_rect(Rect2(roundf(at.x + cos(sa) * r * 0.6), roundf(at.y + sin(sa) * r * 0.6), 1, 1), TB.c("#9fc3ee"))

## Over everyone (world_view, after summons.gd's): shots, bubbles, coins, cones and rays, the word
## and the reels over the hero.
static func draw_over(ci: CanvasItem, t: float) -> void:
	var p := G.player
	if p == null or p.weapon == null:
		return
	for o in shots:
		var at := Vector2(roundf(o["x"]), roundf(o["y"]))
		var c := TB.c(o["col"])
		match o["k"]:
			"letter":
				Gfx.text(ci, o["ch"], at.x, at.y - 3, "white" if not o["last"] else "gold", 1, 0.5)
			"bubble":
				var r: float = o["r"]
				ci.draw_arc(at, r, 0.0, TAU, 16, Color(0.78, 0.94, 1.0, 0.9), 1.0)
				ci.draw_rect(Rect2(at.x - r * 0.5, at.y - r * 0.6, 1, 1), TB.c("#ffffff"))
			"paint":
				ci.draw_circle(at, 3.0, TB.c("#140f1c"))
				ci.draw_circle(at, 2.2, c)
			"slug":
				ci.draw_circle(at, 4.0, TB.c("#140f1c"))
				ci.draw_circle(at, 3.0, TB.c("#f2c94c"))
				ci.draw_rect(Rect2(at.x - 1, at.y - 2, 1, 1), TB.c("#fffbe0"))
			"card":
				ci.draw_set_transform(at, o["t"] * 14.0, Vector2.ONE)
				ci.draw_rect(Rect2(-2, -3, 4, 6), TB.c("#140f1c"))
				ci.draw_rect(Rect2(-1, -2, 2, 4), TB.c("#f4ecd8"))
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"shrink":
				ci.draw_arc(at, 3.0 + sin(t * 30.0), 0.0, TAU, 10, c, 1.0)
			"junk":
				match o["j"]:
					"boot":
						ci.draw_rect(Rect2(at.x - 2, at.y - 3, 3, 5), TB.c("#7a5236"))
						ci.draw_rect(Rect2(at.x - 2, at.y + 1, 5, 2), TB.c("#4a3024"))
					"can":
						ci.draw_rect(Rect2(at.x - 2, at.y - 3, 4, 6), TB.c("#8b8f9c"))
						ci.draw_rect(Rect2(at.x - 2, at.y - 1, 4, 1), TB.c("#d8443c"))
					"bottle":
						ci.draw_rect(Rect2(at.x - 1, at.y - 1, 3, 4), TB.c("#3f7a5a"))
						ci.draw_rect(Rect2(at.x, at.y - 3, 1, 2), TB.c("#63b84f"))
					"tire":
						ci.draw_arc(at, 3.5, 0.0, TAU, 12, TB.c("#140f1c"), 2.0)
			"fish":
				Gfx.sp(ci, "s_fish", at.x, at.y + 3, 1.0, 1.0, o["t"] * 12.0)
			_:
				ci.draw_circle(at, o["r"], c)
	if not bubbled.is_empty():
		for e in G.enemies:
			if bubbled.has(e.uid):
				var r := e.r + 4.0
				var at := Vector2(e.x, e.y - e.r * 0.5 - 2.0 + sin(t * 4.0) * 1.0)
				ci.draw_circle(at, r, Color(0.78, 0.94, 1.0, 0.18))
				ci.draw_arc(at, r, 0.0, TAU, 20, Color(0.78, 0.94, 1.0, 0.85), 1.0)
				ci.draw_rect(Rect2(roundf(at.x - r * 0.5), roundf(at.y - r * 0.6), 2, 1), TB.c("#ffffff"))
	for c in coins:
		var at := Vector2(roundf(c["x"]), roundf(c["y"] - 1.0 - absf(sin(c["t"] * 9.0)) * 2.0))
		var spin := absf(sin(c["t"] * 18.0))
		ci.draw_rect(Rect2(at.x - roundf(2 * spin) - 1, at.y - 2, roundf(4 * spin) + 2, 4), TB.c("#140f1c"))
		ci.draw_rect(Rect2(at.x - roundf(2 * spin), at.y - 1, roundf(4 * spin) + 1, 2), TB.c("#f2c94c"))
		ci.draw_circle(Vector2(c["x"], c["y"] + 6.0), 2.0, Color(0, 0, 0, 0.25))
	for f in flashes:
		var k: float = f["t"] / f["max"]
		var col := TB.c(f["col"])
		match f["k"]:
			"ray":
				ci.draw_line(Vector2(f["x0"], f["y0"]), Vector2(f["x1"], f["y1"]), Color(col.r, col.g, col.b, 0.5 * k), 3.0)
				ci.draw_line(Vector2(f["x0"], f["y0"]), Vector2(f["x1"], f["y1"]), Color(1, 1, 1, k), 1.0)
			"cone", "gust":
				var pts := PackedVector2Array([Vector2(f["x0"], f["y0"])])
				for i in 9:
					var a: float = f["a"] - f["arc"] / 2 + f["arc"] * i / 8.0
					pts.append(Vector2(f["x0"], f["y0"]) + Vector2.from_angle(a) * f["reach"])
				ci.draw_colored_polygon(pts, Color(col.r, col.g, col.b, (0.45 if f["k"] == "cone" else 0.2) * k))
				if f["k"] == "gust":
					for i in 5:
						var a: float = f["a"] + (i - 2) * f["arc"] / 5.0
						var r0: float = f["reach"] * (1.0 - k) * 0.8
						var q := Vector2(f["x0"], f["y0"]) + Vector2.from_angle(a) * r0
						ci.draw_rect(Rect2(roundf(q.x), roundf(q.y), 2, 1), TB.c("#63b84f"))
	var w: Dictionary = p.weapon
	var y0 := roundf(p.y) - 30
	if w["kind"] == "letters" and word != "":
		var typed := word.substr(0, pos)
		var x0 := roundf(p.x) - word.length() * 2
		Gfx.text(ci, typed, x0, y0, "white", 1, 0.0)
		Gfx.text(ci, word.substr(pos), x0 + typed.length() * 4, y0, "dim", 1, 0.0)
	if w["kind"] == "slots":
		for i in 3:
			var x := roundf(p.x) - 9 + i * 6
			ci.draw_rect(Rect2(x - 1, y0 - 1, 6, 8), TB.c("#140f1c"))
			ci.draw_rect(Rect2(x, y0, 4, 6), TB.c("#f4ecd8"))
			var sym: String = REELS[(floori(t * 30.0) + i) % 5] if spin_t > 0 else reels[i]
			var col: String = { "7": "red", "C": "pink", "B": "gold", "$": "green", "X": "dim" }[sym]
			Gfx.text(ci, sym, x + 1, y0 + 1, col, 1, 0.0, false)
