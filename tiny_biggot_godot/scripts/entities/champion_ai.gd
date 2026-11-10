class_name ChampionAI
extends RefCounted
## Rift champions: the boss of a rift world. A champion works through its
## list of moves (GameData.ENEMIES[...]["moves"]) in order, resting a moment
## between them. Below half health it is enraged: everything runs 35% faster.
##
##   ["charge", n]            n telegraphed charges that end in a ring
##   ["ring", n, speed, k]    k rings of n shots, each turned a little
##   ["fan", n, spread, k]    k aimed fans of n shots
##   ["spiral", shots]        a two-armed spiral
##   ["burst", n]             shows its aim, then n fast shots
##   ["duel", n]              n long aims, each followed by one very fast shot
##   ["lob", n]               n bombs lobbed at and around you
##   ["rain", n]              n marked strikes at and around you
##   ["summon", type, n]      calls in n foes (not past 12 in the room)
##   ["blink"]                vanishes, reappears elsewhere in a ring of shots
##
## Scratch fields on the foe: cycle = which move, sub = how many are left,
## st = time to the next step, ca = a held angle.

static func run(e: Enemy, dt: float, p: Player) -> void:
	if e.hp < e.max_hp * 0.5:
		dt *= 1.35
	if e.state == &"idle":
		if e.d.get("style", "melee") == "melee":
			Combat.steer(e, p.x, p.y, e.speed, dt, World.M_WALKER)
			e.face = 1 if p.x > e.x else -1
		else:
			EnemyAI.wander_keep(e, dt, p, 80, 140)
		if e.t <= 0:
			_begin(e, p)
		return
	e.st -= dt
	var m: Array = e.d["moves"][e.cycle % e.d["moves"].size()]
	var spr: String = e.d.get("shot", "red")
	match e.state:
		&"tele":   # before a charge
			e.has_telegraph = true
			if e.st <= 0:
				e.has_telegraph = false
				e.state = &"charge"
				e.st = 0.7
				Snd.play("charge")
		&"charge":
			var hit := World.move_body(G.room, e, cos(e.ca) * 250 * dt, sin(e.ca) * 250 * dt, World.M_WALKER)
			if randf() < 0.5:
				Fx.particle(e.x, e.y + 6, 0, 0, 0.25, "#8b8f9c", 2)
			if hit != 0 or e.st <= 0:
				if hit != 0:
					G.add_shake(3)
					Snd.play("hit")
				Combat.ering(e.x, e.y, 10, 66, randf() * TAU, spr)
				e.sub -= 1
				if e.sub > 0:
					_aim_charge(e, p)
				else:
					_rest(e)
		&"ring":
			if e.st <= 0:
				e.st = 0.45
				e.angle += 0.22
				Combat.ering(e.x, e.y - 3, int(m[1]), float(m[2]), e.angle, spr)
				_count(e)
		&"fan":
			if e.st <= 0:
				e.st = 0.4
				Combat.efan(e.x, e.y - 3, TB.ang_to(e, p), int(m[1]), float(m[2]), 96, spr)
				_count(e)
		&"spiral":
			if e.st <= 0:
				e.st = 0.05
				e.angle += 0.42
				Combat.eshot(e.x, e.y - 3, e.angle, 74, spr, 2.5)
				Combat.eshot(e.x, e.y - 3, e.angle + PI, 74, spr, 2.5)
				if e.sub % 6 == 0:
					Snd.play("ebullet")
				_count(e)
		&"aim":    # before a burst or a duel shot
			e.telegraph = TB.ang_to(e, p)
			e.has_telegraph = e.st > 0.08
			if e.st <= 0:
				e.has_telegraph = false
				e.ca = TB.ang_to(e, p)
				if m[0] == "duel":
					Combat.eshot(e.x, e.y - 2, e.ca, 300, spr, 3.0)
					Snd.play("bolt")
					G.add_shake(1)
					e.sub -= 1
					if e.sub > 0:
						e.st = 0.75
					else:
						_rest(e)
				else:
					e.state = &"fire"
					e.st = 0.0
		&"fire":
			if e.st <= 0:
				e.st = 0.08
				Combat.eshot(e.x, e.y - 2, e.ca + (randf() - 0.5) * 0.14, 140, spr, 2.5)
				Snd.play("ebullet")
				_count(e)
		&"lob":
			if e.st <= 0:
				e.st = 0.35
				EnemyAI.lob(e.x, e.y - 4, p.x + randf_range(-26, 26), p.y + randf_range(-22, 22), spr)
				Snd.play("ebullet")
				_count(e)
		&"wait":
			if e.st <= 0:
				_rest(e)

static func _count(e: Enemy) -> void:
	e.sub -= 1
	if e.sub <= 0:
		_rest(e)

static func _rest(e: Enemy) -> void:
	e.state = &"idle"
	e.has_telegraph = false
	e.cycle += 1
	e.t = 1.0 + randf() * 0.4

static func _aim_charge(e: Enemy, p: Player) -> void:
	e.state = &"tele"
	e.st = 0.5
	e.ca = TB.ang_to(e, p)
	e.telegraph = e.ca
	e.face = 1 if cos(e.ca) > 0 else -1

static func _begin(e: Enemy, p: Player) -> void:
	var m: Array = e.d["moves"][e.cycle % e.d["moves"].size()]
	e.st = 0.0
	match m[0]:
		"charge":
			e.sub = int(m[1])
			_aim_charge(e, p)
		"ring":
			e.sub = int(m[3])
			e.angle = randf() * TAU
			e.state = &"ring"
		"fan":
			e.sub = int(m[3])
			e.state = &"fan"
		"spiral":
			e.sub = int(m[1])
			e.angle = TB.ang_to(e, p)
			e.state = &"spiral"
		"burst":
			e.sub = int(m[1])
			e.state = &"aim"
			e.st = 0.5
		"duel":
			e.sub = int(m[1])
			e.state = &"aim"
			e.st = 0.75
		"lob":
			e.sub = int(m[1])
			e.state = &"lob"
		"rain":
			for i in int(m[1]):
				var off := Vector2.ZERO if i == 0 else Vector2(randf_range(-40, 40), randf_range(-30, 30))
				G.room.marks.append({ "x": clampf(p.x + off.x, 3 * TB.TS, 25 * TB.TS), "y": clampf(p.y + off.y, 4 * TB.TS, 16 * TB.TS),
					"r": 14.0, "t": 0.9 + i * 0.15 })
			e.state = &"wait"
			e.st = 0.8
		"summon":
			if G.enemies.size() < 12:
				for i in int(m[2]):
					Combat.spawn_enemy(m[1], e.x + randf_range(-26, 26), e.y + randf_range(-20, 20))
				Fx.burst(e.x, e.y, ["#f2c94c", "#f4ecd8"], 12, 70)
				Snd.play("bell")
			e.state = &"wait"
			e.st = 0.6
		"blink":
			Fx.burst(e.x, e.y, ["#a35bd6", "#e8c8ff"], 14, 70)
			var s := World.free_spot(G.room, p, 70, World.M_WALKER, e.r + 1)
			e.x = s.x
			e.y = s.y
			Fx.burst(e.x, e.y, ["#a35bd6", "#e8c8ff"], 14, 70)
			Combat.ering(e.x, e.y - 3, 10, 60, randf() * TAU, e.d.get("shot", "red"))
			Snd.play("portal")
			e.state = &"wait"
			e.st = 0.5
		_:
			_rest(e)
