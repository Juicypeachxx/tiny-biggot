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
## The SPECIAL input (F, R3/Back, touch SKILL button) fires it when ready.

static func has_special(p: Player) -> bool:
	return p != null and p.hero.has("special")

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
	p.invuln = maxf(p.invuln, a[2] + 0.15)
	if absf(dir.x) > 0.1:
		p.face = 1 if dir.x > 0 else -1
	Snd.play("dodge")

## While dashing: trample every foe touched once, then run the end actions.
static func while_dashing(p: Player, dt: float) -> void:
	for e in G.enemies.duplicate():
		if not e.targetable() or p.dash_hit.has(e.uid) or TB.dist(e, p) >= e.r + 12:
			continue
		p.dash_hit[e.uid] = true
		Combat.damage_enemy(e, Weapons.wdmg(p) * p.dash_dmg, { "col": "gold" })
		Juice.ring(e.x, e.y, 2, 16, 0.2, "#ffffff")
	EBullets.kill_radius(p.x, p.y, 14)
	p.dash_t -= dt
	if p.dash_t <= 0:
		p.dash_t = 0.0
		for a in p.dash_end:
			Actions.run(a, 1, {})
