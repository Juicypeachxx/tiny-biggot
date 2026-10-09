class_name Pets
extends RefCounted
## Pets: companions with abilities of their own (his ask, 5 Oct; ROADMAP 4.5b). Expanded game only.
##
## You keep one pet at a time, for the run. Pets are found in cages: in treasure rooms (12%),
## vaults (35%), hidden rooms (20%), for sale in shops (25%), and free in a rift guardian's hoard
## (50%). A cage opens with a key (a shop's for gold). Opening one when you already have a pet
## swaps them: yours waits in the cage, free to take back. A pet cannot be hurt. It grows with
## the foes you beat while it is with you: level 2 at 12, level 3 at 35, each level stronger and
## with one more trick.
##
##   BISCUIT     fetches what drops and brings it to you; digs up coins in rooms you clear
##   ZAPPY       zaps the nearest foe (more damage, not more zaps, with +1 projectile); chains
##   CINDERTAIL  leaves a trail of fire behind you as you walk
##   BRAMBLE     rolls into foes: they bleed; it knocks shots out of the air as it rolls
##   GLIMMER     foes near its light take more damage; it flutters at hollow walls (and opens them)
##   GULP        eats enemy shots that come near; spits out coins
##   GLOOP       takes a hit for you, once a room
##   HOOTS       marks the toughest foe, then swoops on it: a heavy blow and a stun
##   SNIP        snips foes beside you; every 15 snips, a piece of armor
##   KABOOMBA    runs at a foe and blows up, then hatches again
##   REX         (never in a cage: beat him in his barn and he comes along) flops onto the biggest
##               crowd of foes; at level 3 he wears his sunglasses and the flop throws a ring of shots
##
## Names, looks and numbers are this game's own. The state of the pet's body (where it is, what it
## is doing) lives here and is reset on entering a room; what you own is on the Player (pet,
## pet_lv, pet_xp).

const LEVEL_AT := [0, 12, 35]   # foes beaten for level 1, 2, 3
const PETS := {
	"biscuit": { "name": "BISCUIT", "kind": "A PUP", "lv": ["FETCHES WHAT DROPS AND BRINGS IT TO YOU",
		"ALSO DIGS UP A COIN IN EVERY ROOM YOU CLEAR", "DIGS UP TWO, AND SOMETIMES A KEY"] },
	"zappy": { "name": "ZAPPY", "kind": "A TINY DRONE", "lv": ["ZAPS THE NEAREST FOE EVERY 1.4S",
		"ZAPS EVERY 1.1S", "ZAPS EVERY 0.8S, AND THE ZAP JUMPS TO A SECOND FOE"] },
	"cindertail": { "name": "CINDERTAIL", "kind": "A FIRE NEWT", "lv": ["LEAVES A TRAIL OF FIRE BEHIND YOU",
		"A WIDER TRAIL THAT BURNS LONGER", "A TRAIL OF FIRE THAT HARDLY GOES OUT"] },
	"bramble": { "name": "BRAMBLE", "kind": "A HEDGEHOG", "lv": ["ROLLS INTO FOES EVERY 3S: THEY BLEED. KNOCKS SHOTS AWAY",
		"ROLLS EVERY 2.4S AND HITS HARDER", "ROLLS EVERY 1.8S AND BOUNCES ON TO A SECOND FOE"] },
	"glimmer": { "name": "GLIMMER", "kind": "A LANTERN MOTH", "lv": ["FOES NEAR ITS LIGHT TAKE 20% MORE DAMAGE. FINDS HOLLOW WALLS",
		"FOES IN ITS LIGHT TAKE 30% MORE", "40% MORE, AND A HOLLOW WALL OPENS WHERE IT GLOWS"] },
	"gulp": { "name": "GULP", "kind": "A HUNGRY TOAD", "lv": ["EATS ENEMY SHOTS THAT COME NEAR. EVERY 25: A COIN",
		"EATS FASTER", "EATS FASTER STILL. EVERY 25: A COIN AND A RING OF SHOTS"] },
	"gloop": { "name": "GLOOP", "kind": "A LOYAL SLIME", "lv": ["TAKES A HIT FOR YOU, ONCE A ROOM",
		"ALSO REFORMS 20S AFTER IT TAKES ONE", "AND BURSTS INTO TEN SHOTS WHEN IT DOES"] },
	"hoots": { "name": "HOOTS", "kind": "AN OWL", "lv": ["EVERY 7S MARKS THE TOUGHEST FOE AND SWOOPS: A HEAVY BLOW",
		"EVERY 6S, HARDER", "EVERY 5S. A FOE IT KILLS DROPS A GEM"] },
	"snip": { "name": "SNIP", "kind": "A CRAB", "lv": ["SNIPS FOES BESIDE YOU. EVERY 15 SNIPS: 1 ARMOR",
		"SNIPS FASTER", "SNIPS FASTER STILL"] },
	"kaboomba": { "name": "KABOOMBA", "kind": "A FUSE BEETLE", "lv": ["EVERY 6S RUNS AT A FOE AND BLOWS UP. HATCHES AGAIN",
		"EVERY 5S, A BIGGER BLAST", "EVERY 4S, AND THE BLAST LEAVES FIRE"] },
	"rex": { "name": "REX", "kind": "A VERY GOOD BOY", "special": true, "lv": ["EVERY 8S FLOPS ONTO THE BIGGEST CROWD OF FOES",
		"EVERY 7S, AND THE FLOP STUNS", "EVERY 6S. SUNGLASSES ON: THE FLOP THROWS A RING OF SHOTS"] },
}
const IDS := ["biscuit", "zappy", "cindertail", "bramble", "glimmer", "gulp", "gloop", "hoots", "snip", "kaboomba"]

# The pet's body: where it is and what it is doing (reset in each room).
static var x := 0.0
static var y := 0.0
static var st := "follow"      # follow, fetch, carry, roll, swoop, run, gone, splat
static var cd := 1.0
static var t := 0.0
static var tgt: WeakRef = null # the foe it goes for
static var carry: Pickup = null
static var count := 0          # snips or shots eaten towards the next reward
static var hit2 := false       # a roll or a zap that already found its second foe
static var ready := true       # gloop: a hit to take
static var armor_room := false # snip: armor given this room
static var wall := ""          # glimmer: the hollow wall it found
static var bolts: Array = []   # zaps to draw: { a, b, t }
static var glow := 0.0         # glimmer: how long it has glowed at the hollow wall
static var _mark := -1.0       # hoots: time left on its mark
static var carry_from := Vector2.ZERO   # rex: where his hop began
static var hop_to := Vector2.ZERO       # rex: where he lands

static func active(p: Player) -> bool:
	return p != null and p.pet != ""

static func lv_mult(p: Player) -> float:
	return [1.0, 1.0, 1.4, 1.8][p.pet_lv]

static func pet_name(id: String) -> String:
	return PETS[id]["name"]

static func desc(id: String, lv: int) -> String:
	return PETS[id]["lv"][clampi(lv, 1, 3) - 1]

## The run gains a pet (from a cage, or --pet=ID).
static func give(p: Player, id: String, lv: int = 1, xp: int = -1) -> void:
	p.pet = id
	p.pet_lv = lv
	p.pet_xp = LEVEL_AT[lv - 1] if xp < 0 else xp
	enter_room(p)

## A room is entered: the pet comes in at your side.
static func enter_room(p: Player) -> void:
	x = p.x - 14.0
	y = p.y + 4.0
	st = "follow"
	cd = 1.0
	t = 0.0
	tgt = null
	carry = null
	hit2 = false
	ready = true
	armor_room = false
	wall = ""
	glow = 0.0
	bolts.clear()
	_mark = -1.0
	if not active(p) or G.room == null:
		return
	if p.pet == "glimmer" and not G.room.secret_dirs.is_empty():
		for d in ["e", "w", "n"]:
			if G.room.secret_dirs.has(d):
				wall = d
				break

static func on_kill(e: Enemy) -> void:
	var p := G.player
	if not active(p) or e.type == "dummy":
		return
	p.pet_xp += 1
	if p.pet_lv < 3 and p.pet_xp >= LEVEL_AT[p.pet_lv]:
		p.pet_lv += 1
		G.toast("%s GREW! %s" % [pet_name(p.pet), desc(p.pet, p.pet_lv)], "gold")
		Fx.burst(x, y, ["#f2c94c", "#f4ecd8"], 14, 60)
		Snd.play("unlock")

static func on_room_clear() -> void:
	var p := G.player
	if not active(p):
		return
	if p.pet == "biscuit" and p.pet_lv >= 2:
		# A good dig: coins, and now and then a key.
		for i in (2 if p.pet_lv >= 3 else 1):
			Combat.drop_pickup("coin", x, y)
		if p.pet_lv >= 3 and randf() < 0.15:
			Combat.drop_pickup("key", x, y)
		Fx.burst(x, y + 3, ["#7a5236", "#d9d0b4"], 8, 40)

## Gloop takes the hit (Combat._hurt_player_base): true when it did.
static func absorb(p: Player) -> bool:
	if not active(p) or p.pet != "gloop" or not ready or st == "splat":
		return false
	ready = false
	st = "splat"
	t = 20.0 if p.pet_lv >= 2 else 1e9
	p.invuln = maxf(p.invuln, 1.0)
	Fx.burst(x, y, ["#6fd3e0", "#c8f0ff", "#4d9be6"], 16, 70)
	Fx.float_text(p.x, p.y - 14, "GLOOP!", "cyan")
	Snd.play("hit")
	if p.pet_lv >= 3:
		for i in 10:
			Combat.spawn_pbullet(p, float(i) / 10 * TAU, Weapons.wdmg(p) * 0.8, "spark")
	return true

# ---------- Every tick (Combat, after the familiars) ----------
static func update(p: Player, dt: float) -> void:
	if not active(p):
		return
	t -= dt
	cd -= dt * Legion.speed(p)   # 34.2 THE LEGION PATH: pets are companions too
	_mark -= dt
	var keep := []
	for b in bolts:
		b["t"] -= dt
		if b["t"] > 0:
			keep.append(b)
	bolts = keep
	var fighting := G.enemies_active()
	match p.pet:
		"biscuit": _biscuit(p, dt)
		"zappy": _zappy(p, dt, fighting)
		"cindertail": _cindertail(p, dt)
		"bramble": _bramble(p, dt, fighting)
		"glimmer": _glimmer(p, dt)
		"gulp": _gulp(p, dt)
		"gloop": _gloop(p, dt)
		"hoots": _hoots(p, dt, fighting)
		"snip": _snip(p, dt, fighting)
		"kaboomba": _kaboomba(p, dt, fighting)
		"rex": _rex(p, dt, fighting)

## Walk (or fly) towards a point at a speed; true on arrival.
static func _go(tx: float, ty: float, speed: float, dt: float) -> bool:
	var dv := Vector2(tx - x, ty - y)
	var step := speed * dt
	if dv.length() <= step:
		x = tx
		y = ty
		return true
	dv = dv.normalized() * step
	x += dv.x
	y += dv.y
	return false

## Keep near the hero: a little behind, or circling (fliers).
static func _follow(p: Player, dt: float, orbit: float = 0.0) -> void:
	if orbit > 0:
		var a := G.time * 2.0
		_go(p.x + cos(a) * orbit, p.y - 6 + sin(a) * orbit * 0.6, 120.0, dt)
		return
	var bx := p.x - 14.0 * p.face
	var by := p.y + 4.0
	if TB.dist_xy(x, y, bx, by) > 10:
		_go(bx, by, maxf(70.0, TB.dist_xy(x, y, bx, by) * 3.0), dt)

static func _foe() -> Enemy:
	return tgt.get_ref() if tgt != null else null

static func _hit(p: Player, e: Enemy, mult: float, col: String = "cyan") -> void:
	Combat.damage_enemy(e, Weapons.wdmg(p) * mult * Legion.dmg_mult(p), { "col": col })

static func _biscuit(p: Player, dt: float) -> void:
	match st:
		"follow":
			_follow(p, dt)
			if cd > 0:
				return
			cd = 0.4
			var best: Pickup = null
			var bd := 1e9
			for k: Pickup in G.pickups:
				if k.dead or k.t < 0.5:
					continue
				var d := TB.dist_xy(k.x, k.y, p.x, p.y)
				if d > 30 and d < bd:
					bd = d
					best = k
			if best != null:
				carry = best
				st = "fetch"
		"fetch":
			if carry == null or carry.dead:
				st = "follow"
				carry = null
				return
			if _go(carry.x, carry.y, 130.0, dt):
				st = "carry"
				Snd.play("select")
		"carry":
			if carry == null or carry.dead:
				st = "follow"
				carry = null
				return
			var arrived := _go(p.x, p.y + 2, 120.0, dt)
			carry.x = x
			carry.y = y - 4
			carry.vx = 0.0
			carry.vy = 0.0
			if arrived or TB.dist_xy(x, y, p.x, p.y) < 8:
				carry.x = p.x
				carry.y = p.y
				carry = null
				st = "follow"

static func _zappy(p: Player, dt: float, fighting: bool) -> void:
	_follow(p, dt, 18.0)
	if cd > 0 or not fighting:
		return
	var e := Combat.nearest_enemy(x, y, 130)
	if e == null:
		return
	cd = [0.0, 1.4, 1.1, 0.8][p.pet_lv]
	# +1 projectile makes the zap stronger rather than adding zaps (it stacks without limit).
	var dmg := 0.6 * (1.0 + 0.25 * p.count)
	_hit(p, e, dmg)
	bolts.append({ "a": Vector2(x, y), "b": Vector2(e.x, e.y - 3), "t": 0.12 })
	if p.pet_lv >= 3:
		var e2 := Combat.nearest_enemy(e.x, e.y, 80, { e.uid: true })
		if e2 != null:
			_hit(p, e2, dmg * 0.7)
			bolts.append({ "a": Vector2(e.x, e.y - 3), "b": Vector2(e2.x, e2.y - 3), "t": 0.12 })
	Snd.play("bolt")

static func _cindertail(p: Player, dt: float) -> void:
	var was := Vector2(x, y)
	_follow(p, dt)
	if cd > 0 or Vector2(x, y).distance_to(was) < 0.2:
		return
	cd = 0.35
	G.zones.append({ "x": x, "y": y + 3, "r": [0.0, 8.0, 10.0, 12.0][p.pet_lv], "t": [0.0, 1.2, 1.6, 2.2][p.pet_lv],
		"kind": "fire", "tick": 0.0 })

static func _bramble(p: Player, dt: float, fighting: bool) -> void:
	match st:
		"follow":
			_follow(p, dt)
			if cd > 0 or not fighting:
				return
			var e := Combat.nearest_enemy(x, y, 140)
			if e == null:
				return
			tgt = weakref(e)
			st = "roll"
			t = 0.6
			hit2 = false
			Snd.play("dodge")
		"roll":
			var e := _foe()
			if e == null or e.hp <= 0 or t <= 0:
				st = "follow"
				cd = [0.0, 3.0, 2.4, 1.8][p.pet_lv]
				return
			_go(e.x, e.y, 230.0, dt)
			EBullets.kill_radius(x, y, 7.0)   # it knocks shots out of the air as it rolls
			if TB.dist_xy(x, y, e.x, e.y) < e.r + 5:
				_hit(p, e, 1.0 * lv_mult(p), "red")
				Statuses.apply(e, "bleed", 1.0, Weapons.wdmg(p))
				Fx.burst(x, y, ["#d8443c", "#7a5236"], 6, 50)
				var e2: Enemy = null
				if p.pet_lv >= 3 and not hit2:
					e2 = Combat.nearest_enemy(e.x, e.y, 90, { e.uid: true })
				if e2 != null:
					hit2 = true
					tgt = weakref(e2)
					t = 0.5
				else:
					st = "follow"
					cd = [0.0, 3.0, 2.4, 1.8][p.pet_lv]

static func _glimmer(p: Player, dt: float) -> void:
	var room := G.room
	if wall != "" and not room.secret_dirs.has(wall):
		wall = ""   # the wall is open now
	if wall != "":
		var at := World.door_center(wall)
		var inward := Vector2(World.DIRS[wall]) * -22.0
		_go(at.x + inward.x, at.y + inward.y + sin(G.time * 4.0) * 3.0, 90.0, dt)
		if p.pet_lv >= 3 and not G.locked:
			glow += dt
			if glow >= 2.5:
				G.open_secret_door(wall)   # at level 3 the hollow wall gives way where it glows
				wall = ""
	else:
		_follow(p, dt, 28.0)
	if cd > 0:
		return
	cd = 0.25
	var v: float = [0.0, 0.2, 0.3, 0.4][p.pet_lv]
	for e in G.enemies:
		if e.targetable() and TB.dist_xy(e.x, e.y, x, y) < 56.0:
			e.mark_t = maxf(e.mark_t, 0.5)
			e.mark_v = maxf(e.mark_v, v)

static func _gulp(p: Player, dt: float) -> void:
	_follow(p, dt, 20.0)
	if cd > 0:
		return
	for i in EBullets.n:
		if not EBullets.alive(i):
			continue
		var dx := EBullets.bx[i] - x
		var dy := EBullets.by[i] - y
		if dx * dx + dy * dy > 16.0 * 16.0:
			continue
		EBullets.blife[i] = EBullets.KILLED
		cd = [0.0, 0.6, 0.4, 0.25][p.pet_lv]
		count += 1
		Fx.burst(x, y, ["#63b84f", "#b8e05a"], 3, 30)
		if count >= 25:
			count = 0
			Combat.drop_pickup("coin", x, y)
			if p.pet_lv >= 3:
				for k in 8:
					Combat.spawn_pbullet(p, float(k) / 8 * TAU, Weapons.wdmg(p) * 0.7, "spark")
		return

static func _gloop(p: Player, dt: float) -> void:
	if st == "splat":
		if t <= 0:
			st = "follow"
			ready = true
			Fx.burst(x, y, ["#6fd3e0", "#c8f0ff"], 10, 40)
		return
	_follow(p, dt)

static func _hoots(p: Player, dt: float, fighting: bool) -> void:
	match st:
		"follow":
			_follow(p, dt, 24.0)
			if cd > 0 or not fighting:
				return
			var best: Enemy = null
			for e in G.enemies:
				if e.targetable() and e.type != "dummy" and (best == null or e.hp > best.hp):
					best = e
			if best == null:
				return
			tgt = weakref(best)
			st = "mark"
			_mark = 0.5
		"mark":
			_follow(p, dt, 24.0)
			var e := _foe()
			if e == null or e.hp <= 0:
				st = "follow"
				return
			if _mark <= 0:
				st = "swoop"
				t = 1.0
				Snd.play("charge")
		"swoop":
			var e := _foe()
			if e == null or e.hp <= 0 or t <= 0:
				st = "follow"
				cd = [0.0, 7.0, 6.0, 5.0][p.pet_lv]
				return
			if _go(e.x, e.y - 4, 320.0, dt):
				_hit(p, e, 2.5 * lv_mult(p), "gold")
				e.stun_t = maxf(e.stun_t, 0.5)
				G.add_shake(2)
				if e.hp <= 0 and p.pet_lv >= 3:
					Combat.drop_pickup("gem", e.x, e.y)
				st = "follow"
				cd = [0.0, 7.0, 6.0, 5.0][p.pet_lv]

static func _snip(p: Player, dt: float, fighting: bool) -> void:
	_follow(p, dt)
	if cd > 0 or not fighting:
		return
	var e := Combat.nearest_enemy(x, y, 28)
	if e == null:
		return
	cd = [0.0, 0.6, 0.45, 0.35][p.pet_lv]
	_hit(p, e, 0.8, "red")
	Snd.play("hatchet")
	count += 1
	if count >= 15 and not armor_room:
		count = 0
		armor_room = true
		p.armor += 1
		Fx.float_text(p.x, p.y - 14, "+1 ARMOR", "cyan")

static func _kaboomba(p: Player, dt: float, fighting: bool) -> void:
	match st:
		"follow":
			_follow(p, dt)
			if cd > 0 or not fighting:
				return
			var best: Enemy = null
			for e in G.enemies:
				if e.targetable() and e.type != "dummy" and TB.dist_xy(e.x, e.y, x, y) < 160 and (best == null or e.hp > best.hp):
					best = e
			if best == null:
				return
			tgt = weakref(best)
			st = "run"
			t = 1.5
		"run":
			var e := _foe()
			var boom := t <= 0 or e == null or e.hp <= 0
			if not boom:
				boom = _go(e.x, e.y, 150.0, dt) or TB.dist_xy(x, y, e.x, e.y) < e.r + 4
			if boom:
				var r: float = [0.0, 30.0, 34.0, 40.0][p.pet_lv]
				Combat.explode_at(x, y, Weapons.wdmg(p) * 2.0 * lv_mult(p), null, r, "#e8873a", true)
				if p.pet_lv >= 3:
					G.zones.append({ "x": x, "y": y, "r": 20.0, "t": 2.5, "kind": "fire", "tick": 0.0 })
				G.add_shake(3)
				Snd.play("boom")
				st = "gone"
				t = 2.0
		"gone":
			if t <= 0:
				st = "follow"
				x = p.x - 10.0
				y = p.y + 4.0
				cd = [0.0, 6.0, 5.0, 4.0][p.pet_lv]
				Fx.burst(x, y, ["#2a2838", "#d8443c"], 8, 40)

## REX: hops onto the foe with the most others around it (a ring shows where), and flops.
static func _rex(p: Player, dt: float, fighting: bool) -> void:
	match st:
		"follow":
			_follow(p, dt)
			if cd > 0 or not fighting:
				return
			var best: Enemy = null
			var crowd := -1
			for e in G.enemies:
				if not e.targetable() or e.type == "dummy" or TB.dist_xy(e.x, e.y, x, y) > 200:
					continue
				var n := 0
				for o in G.enemies:
					if o.targetable() and TB.dist(o, e) < 40:
						n += 1
				if n > crowd:
					crowd = n
					best = e
			if best == null:
				return
			tgt = weakref(best)
			st = "hop"
			t = 0.0
			carry_from = Vector2(x, y)
			hop_to = Vector2(best.x, best.y)
			Snd.play("bark")
		"hop":
			var k := minf(1.0, -t / 0.55)
			x = lerpf(carry_from.x, hop_to.x, k)
			y = lerpf(carry_from.y, hop_to.y, k)
			if k >= 1.0:
				var r := 34.0
				for e in G.enemies.duplicate():
					if e.targetable() and TB.dist_xy(e.x, e.y, x, y) < r + e.r:
						_hit(p, e, 2.2 * lv_mult(p), "gold")
						if p.pet_lv >= 2:
							e.stun_t = maxf(e.stun_t, 0.4)
				if p.pet_lv >= 3:
					for i in 8:
						Combat.spawn_pbullet(p, float(i) / 8 * TAU, Weapons.wdmg(p) * 0.8, "spark")
				Fx.burst(x, y + 4, ["#d9d0b4", "#f4ecd8"], 12, 70)
				G.add_shake(2)
				Snd.play("boom")
				st = "follow"
				cd = [0.0, 8.0, 7.0, 6.0][p.pet_lv]

# ---------- Cages ----------
static func handles(kind: String) -> bool:
	return kind == "pet_cage"

## A pet the run does not have yet (none left: any).
static func roll(p: Player) -> String:
	var pool := []
	for id in IDS:
		if id != p.pet:
			pool.append(id)
	return TB.pick(pool)

## A cage for a room (setup_objects, expanded game only): how it opens.
static func cage(p: Player, x0: float, y0: float, how: String) -> Dictionary:
	var o := { "kind": "pet_cage", "pet": roll(p), "x": x0, "y": y0, "how": how }
	if how == "gold":
		o["price"] = G.price(40 + G.floor_index * 10)
	return o

static func prompt(o: Dictionary) -> Array:
	var id: String = o["pet"]
	var p := G.player
	var how := "TAKE HIM ALONG" if o.get("nocage", false) else "SET IT FREE"
	match o["how"]:
		"key": how = "OPEN WITH 1 KEY"
		"gold": how = "BUY FOR %d GOLD" % o["price"]
	if p.pet != "":
		how += ". %s WAITS HERE" % pet_name(p.pet)
	return [pet_name(id) + ", " + PETS[id]["kind"], desc(id, 1), how]

static func interact(o: Dictionary) -> void:
	var p := G.player
	match o["how"]:
		"key":
			if p.keys < 1:
				return G.deny(o, "NEED A KEY")
			p.keys -= 1
		"gold":
			if p.gold < o["price"]:
				return G.deny(o, "NEED %d GOLD" % o["price"])
			p.gold -= o["price"]
			Snd.play("coin")
	var old := p.pet
	var old_lv := p.pet_lv
	var old_xp := p.pet_xp
	give(p, o["pet"], o.get("lv", 1), o.get("xp", -1))
	x = o["x"]
	y = o["y"] + 6
	G.toast("%s JOINS YOU" % pet_name(p.pet), "gold")
	Fx.burst(o["x"], o["y"], ["#f2c94c", "#f4ecd8"], 14, 60)
	Snd.play("unlock")
	if old == "":
		o["used"] = true
		return
	# Your old pet waits in the cage, free to take back (and keeps its growth).
	o["pet"] = old
	o["how"] = "free"
	o["lv"] = old_lv
	o["xp"] = old_xp

# ---------- Drawing ----------
static func draw_cage(ci: CanvasItem, o: Dictionary, t0: float) -> void:
	if o.get("nocage", false):
		# Rex, beaten: belly up for a rub (until he comes along, or someone takes his place).
		if o.get("used", false) and o["pet"] == "rex":
			return
		if o["pet"] == "rex":
			Gfx.sp(ci, "rex_lie", o["x"], o["y"] - 2 + roundf(sin(t0 * 3.0)), 2.0, 2.0, PI)
			if floori(t0 * 2) % 2 == 0:
				Gfx.text(ci, "<3", o["x"] + 18, o["y"] - 30, "pink")
		else:
			Gfx.sp(ci, "pet_" + o["pet"], o["x"], o["y"] + 6 + roundf(sin(t0 * 3.0) * 1.0))
		return
	if o.get("used", false):
		Gfx.sp(ci, "pet_cage", o["x"], o["y"] + 10, 1.5, 1.5, 0.0, false, 0.5)
		return
	Gfx.sp(ci, "pet_" + o["pet"], o["x"], o["y"] + 6 + roundf(sin(t0 * 3.0) * 1.0), 1.0, 1.0, 0.0, floori(t0) % 4 == 0)
	Gfx.sp(ci, "pet_cage", o["x"], o["y"] + 10, 1.5, 1.5)

## The pet, with the people and foes (world_view.gd, sorted by height on screen).
static func draw(ci: CanvasItem, p: Player, t0: float) -> void:
	if not active(p) or st == "gone":
		return
	var spr := "pet_" + p.pet
	var fly: bool = p.pet in ["zappy", "glimmer", "hoots"]
	var bob := roundf(sin(t0 * (8.0 if fly else 5.0)) * (2.0 if fly else 0.6)) - (6.0 if fly else 0.0)
	var flip := p.x < x if st == "follow" else false
	match p.pet:
		"gloop":
			if st == "splat":
				ci.draw_rect(Rect2(roundf(x) - 6, roundf(y) + 2, 12, 3), Color(0.43, 0.83, 0.88, 0.7))
				return
		"bramble":
			if st == "roll":
				Gfx.sp(ci, spr, x, y + 6, 1.0, 0.8, t0 * 20.0)
				return
		"kaboomba":
			if st == "run" and floori(t0 * 12) % 2 == 0:
				Gfx.sp(ci, spr, x, y + 6, 1.1, 1.1, 0.0, flip, 1.0, Color(1, 1, 1, 0.9))
				return
		"glimmer":
			ci.draw_circle(Vector2(x, y + bob - 4), 56.0, Color(1.0, 0.9, 0.5, 0.05))
			ci.draw_circle(Vector2(x, y + bob - 4), 30.0, Color(1.0, 0.9, 0.5, 0.06))
	if p.pet == "rex" and st == "hop":
		bob -= sin(minf(1.0, -t / 0.55) * PI) * 22.0
	Gfx.sp(ci, spr, x, y + 6 + bob, 1.0, 1.0, 0.0, flip)
	if p.pet == "rex" and p.pet_lv >= 3:
		ci.draw_rect(Rect2(roundf(x) - (5 if not flip else -1), roundf(y + bob) - 3, 5, 1), TB.c("#140f1c"))   # sunglasses
	if p.pet_lv >= 2:
		for i in p.pet_lv - 1:
			ci.draw_rect(Rect2(roundf(x) - 2 + i * 3 - (p.pet_lv - 2) * 1.5, roundf(y + bob) - 9, 2, 2), TB.c("#f2c94c"))

## Over everyone: zaps, the owl's mark.
static func draw_over(ci: CanvasItem, p: Player, t0: float) -> void:
	if not active(p):
		return
	for b in bolts:
		ci.draw_line(b["a"], b["b"], Color(0.43, 0.83, 0.88, 0.9), 2.0)
		ci.draw_line(b["a"], b["b"], Color(1, 1, 1, 1), 1.0)
	if p.pet == "rex" and st == "hop":
		Afx.landing(ci, hop_to.x, hop_to.y + 4, 34.0, minf(1.0, -t / 0.55), TB.c("#f2c94c"), t0)
	if p.pet == "hoots" and st == "mark":
		var e := _foe()
		if e != null:
			Afx.landing(ci, e.x, e.y + e.r * 0.6, e.r + 8.0, 1.0 - _mark / 0.5, TB.c("#f2c94c"), t0)
	if p.pet == "glimmer" and wall != "":
		var at := World.door_center(wall)
		if floori(t0 * 6) % 2 == 0:
			ci.draw_circle(at, 10.0, Color(1.0, 0.9, 0.5, 0.25))
