class_name EnemyAI2
extends RefCounted
## Twenty foes with a way of fighting no older foe has (ROADMAP 4.4). Every attack is warned
## first (a mark, a lane, a line, a glow). All Rogues layer: --classic never meets one.
##
## Skyreach Isles
##   skykite      circles you at a distance and leaves floating mines that burst after a while
##   gustling     swells up, then blasts you away from it (into whatever is behind you)
##   stormharpy   marks a spot on the floor, dives onto it, bursts into a ring where it lands
##   thunderhead  a drifting cloud that calls lightning onto a marked spot under you
##   mirrorwing   mirrors your movement through the middle of the room; fires when lined up
## The Drowned Bastion
##   rampartguard a shield in front takes 80% of the damage; it turns slowly: go round it
##   sludgecrawler leaves a trail of sludge that hurts if you stand in it
##   chainwarden  throws a hook along a shown line; if it catches you, it drags you in and slams
##   tidecaller   calls a sludge wave across the room along its own row (it hurts foes too)
##   longpike     keeps its distance and thrusts a long pike along a shown lane
## The Caliber Cathedral
##   shellpriest  a wide shotgun blast that knocks it back across the floor
##   dervish      spins out a spiral of shots, then stands dizzy (it takes 50% more damage)
##   deacon       keeps away from you and shields the foes near it (half damage for 3 s)
##   beltfeeder   a snake of four links; the links fire to their sides in turn
##   ammomimic    sleeps as a crate of shells until you come near, then bursts and hops at you
## The old floors (expanded game only)
##   tombspider   spits webs that stick to the floor and slow you
##   candlewight  only its lit candle lets it be hurt: lit, it shoots; out, it slides at you unseen
##   gargoyle     moves only while you move; stop and it stops
##   wardrummer   beats a drum: every foe in the room moves 50% faster for a while
##   bloodleech   latches on instead of biting: roll before it drinks (a heart lost)

const AIS := ["skykite", "gustling", "stormharpy", "thunderhead", "mirrorwing", "rampartguard", "sludgecrawler", "chainwarden",
	"tidecaller", "longpike", "shellpriest", "dervish", "deacon", "beltfeeder", "beltlink", "ammomimic", "tombspider",
	"candlewight", "gargoyle", "wardrummer", "bloodleech"]

## Extra foes for the original six floors (only when not --classic): floor index -> foes.
const OLD_FLOOR_EXTRA := { 0: ["tombspider", "bloodleech"], 1: ["tombspider"], 2: ["candlewight", "bloodleech"],
	3: ["gargoyle", "wardrummer"], 4: ["gargoyle"], 5: ["candlewight", "wardrummer"] }

static var _any_guard := false
static var _any_haste := false

static func run(e: Enemy, dt: float, p: Player) -> void:
	match e.d["ai"]:
		"skykite": _kite(e, dt, p)
		"gustling": _gustling(e, dt, p)
		"stormharpy": _harpy(e, dt, p)
		"thunderhead": _thunderhead(e, dt, p)
		"mirrorwing": _mirrorwing(e, dt, p)
		"rampartguard": _guard(e, dt, p)
		"sludgecrawler": _sludge(e, dt, p)
		"chainwarden": _chain(e, dt, p)
		"tidecaller": _tidecaller(e, dt, p)
		"longpike": _pike(e, dt, p)
		"shellpriest": _shellpriest(e, dt, p)
		"dervish": _dervish(e, dt, p)
		"deacon": _deacon(e, dt, p)
		"beltfeeder": _belt(e, dt, p)
		"beltlink": _link(e, dt, p)
		"ammomimic": _mimic(e, dt, p)
		"tombspider": _spider(e, dt, p)
		"candlewight": _candle(e, dt, p)
		"gargoyle": _gargoyle(e, dt, p)
		"wardrummer": _drummer(e, dt, p)
		"bloodleech": _leech(e, dt, p)

static func _shot(e: Enemy, d: String) -> String:
	return e.d.get("shot", d)

static func _el(e: Enemy, a: float, b: float) -> float:
	return b if e.elite else a

# ---------- Skyreach ----------
static func _kite(e: Enemy, dt: float, p: Player) -> void:
	if e.aux2 == 0.0:
		e.aux2 = 1.0 if randf() < 0.5 else -1.0
		e.angle = TB.ang_to(p, e)
	e.angle += dt * 1.1 * e.aux2
	var tx := clampf(p.x + cos(e.angle) * 72, 2.5 * TB.TS, 25.5 * TB.TS)
	var ty := clampf(p.y + sin(e.angle) * 56, 3.5 * TB.TS, 16.0 * TB.TS)
	Combat.steer(e, tx, ty, e.speed, dt, World.M_FLYER)
	e.face = 1 if p.x > e.x else -1
	if e.t <= 0:
		e.t = _el(e, 1.1, 0.8)
		Combat.eshot(e.x, e.y, randf() * TAU, 6.0, _shot(e, "cyan"), 3.0, 2.6, _shot(e, "cyan"))

static func _gustling(e: Enemy, dt: float, p: Player) -> void:
	if e.state == &"swell":
		e.st -= dt
		if e.st <= 0:
			e.state = &"idle"
			e.t = 2.2
			if TB.dist(e, p) < 70:
				var a := TB.ang_to(e, p)
				for i in 8:
					World.move_body(G.room, p, cos(a) * 8, sin(a) * 8, World.M_PLAYER)
				Combat.ering(e.x, e.y, 6, 60, randf(), _shot(e, "cyan"))
			Fx.burst(e.x, e.y, ["#c8f0ff", "#9fc3ee"], 14, 90)
			Snd.play("dodge")
		return
	Combat.steer(e, p.x, p.y, e.speed, dt, World.M_FLYER)
	if TB.dist(e, p) < 46 and e.t <= 0:
		e.state = &"swell"
		e.st = 0.6

static func _harpy(e: Enemy, dt: float, p: Player) -> void:
	match e.state:
		&"mark":
			e.st -= dt
			if e.st <= 0:
				e.state = &"dive"
				e.from = Vector2(e.x, e.y)
				e.st = 0.0
			return
		&"dive":
			e.st += dt / 0.35
			var k := minf(e.st, 1.0)
			e.x = lerpf(e.from.x, e.target.x, k)
			e.y = lerpf(e.from.y, e.target.y, k)
			e.z = sin(k * PI) * 18.0
			if k >= 1.0:
				e.z = 0.0
				e.has_target = false
				e.state = &"idle"
				e.t = _el(e, 2.4, 1.7)
				Combat.ering(e.x, e.y, 10 if e.elite else 8, 70, randf() * TAU, _shot(e, "cyan"))
				if TB.dist(e, p) < 14:
					Combat.hurt_player(1, e.d.get("label", "a harpy"))
				G.add_shake(2)
			return
	EnemyAI.wander_keep(e, dt, p, 80, 140)
	if e.t <= 0:
		e.state = &"mark"
		e.st = 0.8
		e.target = Vector2(p.x, p.y)
		e.has_target = true

static func _thunderhead(e: Enemy, dt: float, p: Player) -> void:
	var a := TB.ang_to(e, p) + PI / 2
	Combat.steer(e, e.x + cos(a) * 30, e.y + sin(a) * 30, e.speed, dt, World.M_FLYER)
	if e.t <= 0:
		e.t = _el(e, 2.8, 2.0)
		for i in (2 if e.elite else 1):
			var off := Vector2.ZERO if i == 0 else Vector2(randf_range(-24, 24), randf_range(-18, 18))
			G.room.marks.append({ "x": clampf(p.x + off.x, 3 * TB.TS, 25 * TB.TS), "y": clampf(p.y + off.y, 4 * TB.TS, 16 * TB.TS),
				"r": 14.0, "t": 0.9 })
		Snd.play("charge")

static func _mirrorwing(e: Enemy, dt: float, p: Player) -> void:
	var cx := 14.0 * TB.TS
	var cy := 9.5 * TB.TS
	Combat.steer(e, clampf(2 * cx - p.x, 2 * TB.TS, 26 * TB.TS), clampf(2 * cy - p.y, 3 * TB.TS, 16.5 * TB.TS), e.speed, dt, World.M_FLYER)
	var lined := absf(e.x - p.x) < 8 or absf(e.y - p.y) < 8
	e.has_telegraph = lined and e.t <= 0.4
	e.telegraph = TB.ang_to(e, p)
	if lined and e.t <= 0:
		e.t = _el(e, 1.2, 0.8)
		for i in 3:
			Combat.eshot(e.x, e.y, TB.ang_to(e, p) + (i - 1) * 0.08, 150, _shot(e, "cyan"), 2.5)
		Snd.play("ebullet")

# ---------- The Drowned Bastion ----------
static func _guard(e: Enemy, dt: float, p: Player) -> void:
	# The shield faces e.ca, which turns toward you at a limited rate.
	if e.aux == 0.0:
		e.aux = 1.0
		e.ca = TB.ang_to(e, p)
	var want := TB.ang_to(e, p)
	var turn := clampf(TB.wrap_ang(want - e.ca), -1.3 * dt, 1.3 * dt)
	e.ca += turn
	if e.state == &"bash":
		e.st -= dt
		World.move_body(G.room, e, cos(e.ca) * e.speed * 3 * dt, sin(e.ca) * e.speed * 3 * dt, World.M_WALKER)
		if e.st <= 0:
			e.state = &"idle"
			e.t = 1.6
		return
	Combat.steer(e, p.x, p.y, e.speed, dt, World.M_WALKER)
	e.face = 1 if cos(e.ca) > 0 else -1
	if TB.dist(e, p) < 40 and e.t <= 0:
		e.state = &"bash"
		e.st = 0.3

static func _sludge(e: Enemy, dt: float, p: Player) -> void:
	var a := TB.ang_to(e, p) + sin(e.anim * 2) * 0.8
	World.move_body(G.room, e, cos(a) * e.speed * dt, sin(a) * e.speed * dt, World.M_WALKER)
	e.face = 1 if p.x > e.x else -1
	if e.t <= 0:
		e.t = _el(e, 0.55, 0.4)
		add_goo("sludge", e.x, e.y + 2, 9.0, _el(e, 4.0, 6.0))

static func _chain(e: Enemy, dt: float, p: Player) -> void:
	match e.state:
		&"aim":
			e.st -= dt
			if e.st <= 0:
				e.state = &"idle"
				e.t = _el(e, 2.6, 2.0)
				e.has_telegraph = false
				# Does the hook's line pass the hero?
				var dx := cos(e.ca)
				var dy := sin(e.ca)
				var rx := p.x - e.x
				var ry := p.y - e.y
				var along := rx * dx + ry * dy
				if along > 0 and along < 170 and absf(rx * dy - ry * dx) < 9 and p.dodge_t <= 0:
					var pull := maxf(0.0, along - 22)
					for i in 10:
						World.move_body(G.room, p, -dx * pull / 10, -dy * pull / 10, World.M_PLAYER)
					Combat.ering(e.x, e.y, 10, 65, randf(), _shot(e, "bone"))
					G.toast("HOOKED!", "red")
				Snd.play("hatchet")
			return
	EnemyAI.wander_keep(e, dt, p, 70, 130)
	if e.t <= 0 and TB.dist(e, p) < 160:
		e.state = &"aim"
		e.st = 0.7
		e.ca = TB.ang_to(e, p)
		e.has_telegraph = true
		e.telegraph = e.ca

static func _tidecaller(e: Enemy, dt: float, p: Player) -> void:
	EnemyAI.wander_keep(e, dt, p, 110, 170)
	if e.t <= 0:
		e.t = _el(e, 5.0, 3.8)
		var dir := 1 if p.x > e.x else -1
		G.room.tides.append({ "y": clampf(e.y, 4 * TB.TS, 16 * TB.TS), "dir": dir, "t": 1.2, "x": TB.TS - 10.0 if dir > 0 else TB.SW - TB.TS + 10.0,
			"hit": { e.uid: true }, "hit_p": false })
		Snd.play("portal")

static func _pike(e: Enemy, dt: float, p: Player) -> void:
	match e.state:
		&"wind":
			e.st -= dt
			if e.st <= 0:
				e.state = &"thrust"
				e.st = 0.15
				var dx := cos(e.ca)
				var dy := sin(e.ca)
				var rx := p.x - e.x
				var ry := p.y - e.y
				var along := rx * dx + ry * dy
				if along > 0 and along < 78 and absf(rx * dy - ry * dx) < 7:
					Combat.hurt_player(1, e.d.get("label", "a longpike"))
				Snd.play("hatchet")
			return
		&"thrust":
			e.st -= dt
			if e.st <= 0:
				e.state = &"idle"
				e.t = _el(e, 1.5, 1.0)
			return
	EnemyAI.wander_keep(e, dt, p, 46, 64)
	if e.t <= 0 and TB.dist(e, p) < 80:
		e.state = &"wind"
		e.st = 0.55
		e.ca = TB.ang_to(e, p)

# ---------- The Caliber Cathedral ----------
static func _shellpriest(e: Enemy, dt: float, p: Player) -> void:
	if e.state == &"aim":
		e.st -= dt
		if e.st <= 0:
			e.state = &"idle"
			e.t = _el(e, 2.2, 1.6)
			var n := 9 if e.elite else 7
			for i in n:
				Combat.eshot(e.x, e.y - 2, e.ca + (i - (n - 1) / 2.0) * 0.13, 120 + randf() * 30, _shot(e, "red"), 2.5)
			e.kx = -cos(e.ca) * 260
			e.ky = -sin(e.ca) * 260
			G.add_shake(2)
			Snd.play("boom")
		return
	EnemyAI.wander_keep(e, dt, p, 50, 90)
	if e.t <= 0 and TB.dist(e, p) < 120:
		e.state = &"aim"
		e.st = 0.5
		e.ca = TB.ang_to(e, p)
		e.has_telegraph = true
		e.telegraph = e.ca

static func _dervish(e: Enemy, dt: float, p: Player) -> void:
	e.has_telegraph = false
	match e.state:
		&"spin":
			e.st -= dt
			e.angle += dt * 9.0
			e.ct -= dt
			if e.ct <= 0:
				e.ct = 0.07
				Combat.eshot(e.x, e.y, e.angle, 95, _shot(e, "red"), 2.5)
				if e.elite:
					Combat.eshot(e.x, e.y, e.angle + PI, 95, _shot(e, "red"), 2.5)
			Combat.steer(e, p.x, p.y, e.speed * 0.4, dt, World.M_WALKER)
			if e.st <= 0:
				e.state = &"dizzy"
				e.st = 1.6
			return
		&"dizzy":
			e.st -= dt
			if e.st <= 0:
				e.state = &"idle"
				e.t = 1.2
			return
	EnemyAI.wander_keep(e, dt, p, 60, 110)
	if e.t <= 0:
		e.state = &"spin"
		e.st = 2.0
		e.ct = 0.0

static func _deacon(e: Enemy, dt: float, p: Player) -> void:
	EnemyAI.wander_keep(e, dt, p, 130, 190)
	if e.t <= 0:
		e.t = _el(e, 4.0, 3.0)
		_any_guard = true
		for o in G.enemies:
			if o != e and o.targetable() and TB.dist(o, e) < 90:
				o.guard_t = 3.0
		Fx.burst(e.x, e.y - 6, ["#f2c94c", "#ffffff"], 12, 60)
		Snd.play("heal")

static func _belt(e: Enemy, dt: float, p: Player) -> void:
	if e.links.is_empty() and e.aux == 0.0:
		e.aux = 1.0
		for i in 3:
			var l := Combat.spawn_enemy("beltlink", e.x, e.y, e.elite, true)
			l.lead = weakref(e)   # weak: the head holds its links, the links must not hold the head
			l.cycle = i + 1
			e.links.append(l)
	e.trail.push_front(Vector2(e.x, e.y))
	if e.trail.size() > 40:
		e.trail.pop_back()
	var a := TB.ang_to(e, p) + sin(e.anim * 3) * 0.9
	World.move_body(G.room, e, cos(a) * e.speed * dt, sin(a) * e.speed * dt, World.M_WALKER)
	e.ca = a
	if e.t <= 0:
		e.t = _el(e, 0.5, 0.35)
		e.sub = (e.sub + 1) % 4
		var shooter: Enemy = e if e.sub == 0 or e.sub > e.links.size() else e.links[e.sub - 1]
		if shooter.hp > 0:
			for side in [-1, 1]:
				Combat.eshot(shooter.x, shooter.y, shooter.ca + side * PI / 2, 90, _shot(e, "red"), 2.5)
			Snd.play("ebullet")

static func _link(e: Enemy, dt: float, p: Player) -> void:
	var lead = e.lead.get_ref() if e.lead != null else null
	if lead == null or lead.hp <= 0:
		# The belt snapped: a loose link crawls at you and fires to its sides.
		e.ca = TB.ang_to(e, p)
		World.move_body(G.room, e, cos(e.ca) * e.speed * 0.6 * dt, sin(e.ca) * e.speed * 0.6 * dt, World.M_WALKER)
		if e.t <= 0:
			e.t = 1.6
			for side in [-1, 1]:
				Combat.eshot(e.x, e.y, e.ca + side * PI / 2, 90, _shot(e, "red"), 2.5)
		return
	var k: int = e.cycle * 9
	if lead.trail.size() > k:
		var to: Vector2 = lead.trail[k]
		e.ca = TB.ang_xy(e.x, e.y, to.x, to.y) if TB.dist_xy(e.x, e.y, to.x, to.y) > 0.5 else e.ca
		e.x = to.x
		e.y = to.y

static func _mimic(e: Enemy, dt: float, p: Player) -> void:
	if e.state == &"idle" and e.aux == 0.0:
		e.aux = 1.0
		e.hidden = true   # a crate of shells, as far as anyone can tell
		e.st = 9.0
	if e.hidden:
		e.st -= dt
		if TB.dist(e, p) < 48 or e.st <= 0:
			e.hidden = false
			e.state = &"awake"
			Combat.ering(e.x, e.y, 16 if e.elite else 12, 80, randf(), _shot(e, "red"))
			Fx.burst(e.x, e.y, ["#f2c94c", "#7a5236"], 16, 80)
			Snd.play("roar")
			e.t = 0.6
		return
	if e.t <= 0:
		e.t = 0.9
		var a := TB.ang_to(e, p) + (randf() - 0.5) * 0.5
		e.kx = cos(a) * 220
		e.ky = sin(a) * 220
		if e.elite:
			Combat.ering(e.x, e.y, 6, 70, randf(), _shot(e, "red"))

# ---------- The old floors ----------
static func _spider(e: Enemy, dt: float, p: Player) -> void:
	EnemyAI.wander_keep(e, dt, p, 60, 120)
	if e.t <= 0:
		e.t = _el(e, 2.6, 1.9)
		# A web blob lands where you are and sticks to the floor.
		e.target = Vector2(p.x, p.y)
		e.has_target = true
		e.st = 0.5
		e.state = &"spit"
	if e.state == &"spit":
		e.st -= dt
		if e.st <= 0:
			e.state = &"idle"
			e.has_target = false
			add_goo("web", e.target.x, e.target.y, 16.0, _el(e, 5.0, 7.0))
			Snd.play("place")

static func _candle(e: Enemy, dt: float, p: Player) -> void:
	e.cyc += dt
	var lit := fmod(e.cyc, 4.4) < 2.4
	if lit and e.hidden:
		e.hidden = false
		Fx.burst(e.x, e.y - 8, ["#f2c94c", "#e8873a"], 6, 30)
	elif not lit and not e.hidden:
		e.hidden = true
	if e.hidden:
		Combat.steer(e, p.x, p.y, e.speed * 1.4, dt, World.M_FLYER)
		return
	EnemyAI.wander_keep(e, dt, p, 70, 120)
	if e.t <= 0:
		e.t = _el(e, 0.9, 0.6)
		Combat.eshot(e.x, e.y - 6, TB.ang_to(e, p), 110, _shot(e, "fire"), 2.5)

static func _gargoyle(e: Enemy, dt: float, p: Player) -> void:
	var moving := Vector2(p.x - e.from.x, p.y - e.from.y).length() > 0.05
	e.from = Vector2(p.x, p.y)
	if moving:
		Combat.steer(e, p.x, p.y, e.speed, dt, World.M_WALKER)
		e.face = 1 if p.x > e.x else -1

static func _drummer(e: Enemy, dt: float, p: Player) -> void:
	EnemyAI.wander_keep(e, dt, p, 120, 180)
	if e.t <= 0:
		e.t = _el(e, 5.0, 3.8)
		for o in G.enemies:
			if o != e and o.targetable() and o.haste_t <= 0 and o.speed > 0:
				o.haste_t = 2.0
				o.speed *= 1.5
				_any_haste = true
		Fx.burst(e.x, e.y, ["#d8443c", "#f2c94c"], 18, 120)
		Snd.play("boom")

static func _leech(e: Enemy, dt: float, p: Player) -> void:
	if e.state == &"latched":
		e.x = p.x + 3
		e.y = p.y - 2
		e.st -= dt
		if p.dodge_t > 0:
			_unlatch(e, p, "SHAKEN OFF")
			return
		if e.st <= 0:
			Combat.hurt_player(1, e.d.get("label", "a blood leech"))
			e.hp = minf(e.max_hp, e.hp + e.max_hp * 0.5)
			_unlatch(e, p, "")
		return
	var a := TB.ang_to(e, p) + sin(e.anim * 5) * 0.4
	World.move_body(G.room, e, cos(a) * e.speed * dt, sin(a) * e.speed * dt, World.M_WALKER)
	e.face = 1 if p.x > e.x else -1
	if TB.dist(e, p) < e.r + p.r + 2 and e.t <= 0:
		e.state = &"latched"
		e.st = _el(e, 1.6, 1.2)
		G.toast("A LEECH! ROLL TO SHAKE IT OFF", "red")
		Snd.play("hurt")

static func _unlatch(e: Enemy, p: Player, text: String) -> void:
	e.state = &"idle"
	e.t = 1.5
	var a := TB.ang_to(p, e)
	e.kx = cos(a) * 200
	e.ky = sin(a) * 200
	if text != "":
		G.toast(text, "white")

# ---------- Damage rules (Combat.damage_enemy) ----------
static func adjust_damage(e: Enemy, dmg: float) -> float:
	if e.guard_t > 0:
		dmg *= 0.5
	match e.d.get("rule", ""):
		"shield":
			var p := G.player
			if absf(TB.wrap_ang(TB.ang_to(e, p) - e.ca)) < 1.0:
				dmg *= 0.2
				Fx.burst(e.x + cos(e.ca) * 6, e.y + sin(e.ca) * 6, ["#8b8f9c", "#f4ecd8"], 3, 40)
		"dizzy":
			if e.state == &"dizzy":
				dmg *= 1.5
		"phase":
			dmg = RiftBosses.adjust_damage(e, dmg)   # the rift bosses' grace between phases
	return dmg

# ---------- Webs and sludge on the floor (Room.goo) ----------
static func add_goo(kind: String, x: float, y: float, r: float, t: float) -> void:
	var room := G.room
	if room == null or room.goo.size() >= 40:
		return
	room.goo.append({ "kind": kind, "x": x, "y": y, "r": r, "t": t })

static func in_web(p: Player) -> bool:
	var room := G.room
	if room == null or room.goo.is_empty():
		return false
	for g in room.goo:
		if g["kind"] == "web" and TB.dist_xy(p.x, p.y, g["x"], g["y"]) < g["r"]:
			return true
	return false

static var _sludge_t := 0.0

## Every tick (Hazards.update): goo fades; standing in sludge for half a second hurts; shields and
## drum haste wear off.
static func tick(room: Room, dt: float) -> void:
	if not room.goo.is_empty():
		var keep := []
		var p := G.player
		var in_sludge := false
		for g in room.goo:
			g["t"] -= dt
			if g["t"] > 0:
				keep.append(g)
				if g["kind"] == "sludge" and TB.dist_xy(p.x, p.y, g["x"], g["y"]) < g["r"]:
					in_sludge = true
		room.goo = keep
		_sludge_t = _sludge_t + dt if in_sludge else 0.0
		if _sludge_t >= 0.5:
			_sludge_t = 0.0
			Combat.hurt_player(1, "a trail of sludge")
	if _any_guard or _any_haste:
		var guard := false
		var haste := false
		for e in G.enemies:
			if e.guard_t > 0:
				e.guard_t -= dt
				guard = true
			if e.haste_t > 0:
				e.haste_t -= dt
				haste = true
				if e.haste_t <= 0:
					e.speed /= 1.5
		_any_guard = guard
		_any_haste = haste

# ---------- Drawing (world_view.gd: goo on the floor, warnings with the telegraphs) ----------
static func draw_goo(ci: CanvasItem, t: float) -> void:
	var room := G.room
	if room == null or room.goo.is_empty():
		return
	for g in room.goo:
		var fade := clampf(g["t"], 0.0, 1.0)
		var r: float = g["r"]
		if g["kind"] == "web":
			var col := Color(0.95, 0.93, 0.85, 0.55 * fade)
			for k in 4:
				var a := k * PI / 4
				ci.draw_line(Vector2(g["x"] - cos(a) * r, g["y"] - sin(a) * r * 0.7), Vector2(g["x"] + cos(a) * r, g["y"] + sin(a) * r * 0.7), col, 1.0)
			ci.draw_rect(Rect2(g["x"] - r * 0.5, g["y"] - 1, r, 2), col)
		else:
			ci.draw_rect(Rect2(roundf(g["x"] - r), roundf(g["y"] - r * 0.5), r * 2, r), Color(0.25, 0.48, 0.3, 0.6 * fade))
			ci.draw_rect(Rect2(roundf(g["x"] - r * 0.6), roundf(g["y"] - r * 0.3), r * 1.2, 2), Color(0.72, 0.88, 0.35, 0.7 * fade))

static func draw_marks(ci: CanvasItem, t: float) -> void:
	var blink := floori(t * 12) % 2 == 0
	for e in G.enemies:
		match e.d.get("ai", ""):
			"stormharpy":
				if e.has_target:
					var r := 12.0
					for k in 12:
						var a := k * TAU / 12 + t * 2
						Gfx.px(ci, TB.ca("#9fc3ee", 230 if blink else 120), e.target.x + cos(a) * r, e.target.y + sin(a) * r * 0.7, 2)
			"tombspider":
				if e.has_target:
					Gfx.px(ci, TB.ca("#f4ecd8", 200 if blink else 100), e.target.x - 2, e.target.y - 2, 4)
			"chainwarden":
				if e.state == &"aim":
					var i := 12.0
					while i < 170:
						Gfx.px(ci, TB.ca("#8b8f9c", 220 if blink else 120), e.x + cos(e.ca) * i - 1, e.y + sin(e.ca) * i - 1, 2)
						i += 8
			"longpike":
				if e.state == &"wind" or e.state == &"thrust":
					var col := TB.ca("#d8443c", 200 if (blink or e.state == &"thrust") else 90)
					var i := 8.0
					while i < 78:
						Gfx.px(ci, col, e.x + cos(e.ca) * i - 1, e.y + sin(e.ca) * i - 1, 3 if e.state == &"thrust" else 2)
						i += 5
			"gustling":
				if e.state == &"swell":
					var r := 70.0 * (1.0 - e.st / 0.6)
					for k in 16:
						var a := k * TAU / 16
						Gfx.px(ci, TB.ca("#c8f0ff", 180), e.x + cos(a) * r, e.y + sin(a) * r * 0.7, 2)
			"rampartguard":
				for k in 5:
					var a: float = e.ca + (k - 2) * 0.25
					Gfx.px(ci, TB.c("#c9c2a8"), e.x + cos(a) * 9 - 1, e.y - 3 + sin(a) * 9 - 1, 2)
			"dervish":
				if e.state == &"dizzy":
					for k in 3:
						var a := t * 6 + k * TAU / 3
						Gfx.px(ci, TB.c("#f2c94c"), e.x + cos(a) * 6, e.y - 14 + sin(a) * 2, 2)
			"ammomimic":
				if e.hidden:
					Gfx.sp(ci, "ammomimic", e.x, e.y + 6)
			"candlewight":
				if e.hidden:
					Gfx.sp(ci, "candlewight", e.x, e.y + 6, 1, 1, 0.0, false, 0.18)
			"bloodleech":
				if e.state == &"latched":
					Gfx.text(ci, "ROLL!", e.x, e.y - 22, "red", 1, 0.5)
		if e.guard_t > 0:
			for k in 6:
				var a := k * TAU / 6 + t * 3
				Gfx.px(ci, TB.ca("#f2c94c", 200), e.x + cos(a) * (e.r + 4), e.y - 3 + sin(a) * (e.r + 4) * 0.7, 1)
