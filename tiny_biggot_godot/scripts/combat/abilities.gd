class_name Abilities
extends RefCounted
## Hero special abilities (new heroes only; the six originals have none, so
## their runs never enter this code). A hero's "special" is data:
##   { "name", "desc", "cd" (seconds), "col" (hex), "do": [actions] }
## Actions are the normal effect-system actions (actions.gd) plus the ones
## below, which only make sense for an ability:
##   ["dash", speed, seconds, trample_dmg_mult, [end actions]]  charge along the aim
##   ["channel", seconds, period, [actions]]   repeat actions while it lasts
##   ["invuln", seconds]                       untouchable
##   ["leap", speed, reach, [landing actions]] jump onto the foe you aim at (or `reach` px ahead):
##                                             airborne and untouchable, clears pillars and crates
## The SPECIAL input (F, R3/Back, touch SKILL button) fires it when ready.

const LEAP_HEIGHT := 26.0     # how high a leap carries the hero (drawing only)
const LEAP_MIN := 0.2         # seconds in the air, even for a hop on the spot

static func has_special(p: Player) -> bool:
	# 20.1: the originals' skills (GameData.ORIGINAL_SPECIALS) are expanded-game only.
	return p != null and p.hero.has("special") and (p.hero.get("new", false) or GameData.rogues())

static func ready(p: Player) -> bool:
	return has_special(p) and p.special_cd <= 0

## 0..1 charge for the HUD and the touch button.
static func charge(p: Player) -> float:
	if not has_special(p):
		return 0.0
	return clampf(1.0 - p.special_cd / float(p.hero["special"]["cd"]), 0.0, 1.0)

## Called once per logic tick from Combat.update_player.
static func update(p: Player, dt: float) -> void:
	if not has_special(p):
		return
	p.special_cd = maxf(0.0, p.special_cd - dt)
	if not p.channel.is_empty():
		var c: Dictionary = p.channel
		c["t"] -= dt
		c["timer"] -= dt
		if c["timer"] <= 0:
			c["timer"] += c["period"]
			for a in c["do"]:
				Actions.run(a, 1, {})
		if c["t"] <= 0:
			p.channel = {}
	if Keys.special() and G.state == &"play":
		if p.special_cd > 0:
			Snd.play("deny")
		else:
			use(p)

static func use(p: Player) -> void:
	var sp: Dictionary = p.hero["special"]
	p.special_cd = float(sp["cd"])
	Snd.play("unlock")
	Juice.ability(p.x, p.y, sp["name"], sp.get("col", "#f2c94c"))
	for a in sp["do"]:
		Actions.run(a, 1, {})

static func start_dash(p: Player, a: Array) -> void:
	var dir := Vector2(cos(p.aim_a), sin(p.aim_a))
	var mv := Keys.move()
	if mv.length() > 0.1:
		dir = mv.normalized()
	p.dash_dir = dir
	p.dash_speed = a[1]
	p.dash_t = a[2]
	p.dash_dmg = a[3]
	p.dash_end = a[4] if a.size() > 4 else []
	p.dash_hit = {}
	p.leap_max = 0.0   # a ground charge, even if it starts in the middle of a leap
	p.air = 0.0
	p.invuln = maxf(p.invuln, a[2] + 0.15)
	if absf(dir.x) > 0.1:
		p.face = 1 if dir.x > 0 else -1
	Snd.play("dodge")

## A leap: the dash machinery, but through the air. It lands on the foe the
## hero is aiming at when one is in reach (the one nearest the aim), otherwise
## `reach` * 0.6 px along the way the hero moves or aims. No random draws.
static func start_leap(p: Player, a: Array) -> void:
	var speed: float = a[1]
	var reach: float = a[2]
	var dir := Vector2(cos(p.aim_a), sin(p.aim_a))
	var dist := reach * 0.6
	var best: Enemy = null
	var score := INF
	for e in G.enemies:
		if not e.targetable():
			continue
		var d := TB.dist(p, e)
		if d > reach:
			continue
		var s := d + absf(TB.wrap_ang(TB.ang_to(p, e) - p.aim_a)) * 40.0
		if s < score:
			score = s
			best = e
	if best != null:
		dist = TB.dist(p, best)
		if dist > 1.0:
			dir = Vector2(best.x - p.x, best.y - p.y) / dist
		if best.is_boss() or best.r > 7.0:
			# Big foes and guardians: come down at their feet, not inside them.
			dist = maxf(0.0, dist - best.r - p.r - 2.0)
	else:
		var mv := Keys.move()
		if mv.length() > 0.1:
			dir = mv.normalized()
	# A whole number of ticks, so the hero comes down exactly on the spot.
	var n := maxi(1, roundi(clampf(dist / speed, LEAP_MIN, reach / speed) / TB.DT))
	var t := n * TB.DT
	p.dash_dir = dir
	p.dash_speed = dist / t
	p.dash_t = t - TB.DT * 0.5
	p.leap_max = t
	p.air = 0.0
	p.dash_dmg = 0.0
	p.dash_end = a[3] if a.size() > 3 else []
	p.dash_hit = {}
	p.invuln = maxf(p.invuln, t + 0.4)
	p.dodge_t = 0.0   # a leap out of a roll ends the roll
	if absf(dir.x) > 0.1:
		p.face = 1 if dir.x > 0 else -1
	Snd.play("dodge")
	Juice.takeoff(p)

## The leap comes down (called by Player.update_move after its last step):
## never inside a pillar or crate, then the landing actions.
static func land(p: Player) -> void:
	p.leap_max = 0.0
	p.air = 0.0
	if World.hits_solid(G.room, p.x, p.y, p.r, World.M_PLAYER):
		var found := false
		for step in range(1, 16):
			for k in 12:
				# Back along the leap first, then around it.
				var ang := atan2(-p.dash_dir.y, -p.dash_dir.x) + ((k + 1) >> 1) * (1 if k % 2 == 0 else -1) * TAU / 12.0
				var nx := p.x + cos(ang) * step * 4.0
				var ny := p.y + sin(ang) * step * 4.0
				if not World.hits_solid(G.room, nx, ny, p.r, World.M_WALKER):
					p.x = nx
					p.y = ny
					found = true
					break
			if found:
				break
	for a in p.dash_end:
		Actions.run(a, 1, {})

## While dashing: trample every foe touched once, then run the end actions.
static func while_dashing(p: Player, dt: float) -> void:
	if p.leap_max <= 0:
		for e in G.enemies.duplicate():
			if p.dash_dmg <= 0:
				break   # a weapon's dash (charged.gd) makes its own cuts
			if not e.targetable() or p.dash_hit.has(e.uid) or TB.dist(e, p) >= e.r + 12:
				continue
			p.dash_hit[e.uid] = true
			Combat.damage_enemy(e, Weapons.wdmg(p) * p.dash_dmg, { "col": "gold" })
			Juice.ring(e.x, e.y, 2, 16, 0.2, "#ffffff")
		EBullets.kill_radius(p.x, p.y, 14)
	p.dash_t -= dt
	if p.dash_t <= 0:
		p.dash_t = 0.0
		if p.leap_max > 0:
			return   # a leap lands after this tick's step: Player.update_move calls land()
		for a in p.dash_end:
			Actions.run(a, 1, {})
