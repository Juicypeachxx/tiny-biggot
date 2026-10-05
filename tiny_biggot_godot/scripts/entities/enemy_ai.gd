class_name EnemyAI
extends RefCounted
## Foe behaviours (port of the ai_* functions in Entities.rb). Ruby
## dispatched with send("ai_" + name); here a match on the ai name.

static func run(e: Enemy, dt: float, p: Player) -> void:
	match e.d["ai"]:
		"bat": ai_bat(e, dt, p)
		"slime": ai_slime(e, dt, p)
		"archer": ai_archer(e, dt, p)
		"spore": ai_spore(e, dt, p)
		"cultist": ai_cultist(e, dt, p)
		"imp": ai_imp(e, dt, p)
		"knight": ai_knight(e, dt, p)
		"ghost": ai_ghost(e, dt, p)
		"book": ai_book(e, dt, p)
		"drowned": ai_drowned(e, dt, p)
		"wisp": ai_wisp(e, dt, p)
		"golem": ai_golem(e, dt, p)
		# Stage 7 behaviours.
		"ambush": ai_ambush(e, dt, p)
		"monk": ai_monk(e, dt, p)
		"gunman": ai_gunman(e, dt, p)
		"dummy": ai_dummy(e)
		"target": pass   # the shooting gallery's pop-up targets just stand there
		# Rift worlds and event rooms.
		"runner": ai_runner(e, dt, p)
		"lobber": ai_lobber(e, dt, p)
		"bomber": ai_bomber(e, dt, p)
		"caller": ai_caller(e, dt, p)
		"turret": ai_turret(e, dt, p)
		"flee": ai_flee(e, dt, p)
		"champion": ChampionAI.run(e, dt, p)
	if e.d.get("mini", false) and not e.d.get("champion", false):
		_mini_extra(e, dt)

## Bullet sprite: stage-7 foes reuse behaviours with their own shots (d["shot"]).
static func _shot(e: Enemy, default: String) -> String:
	return e.d.get("shot", default)

static func _mode(e: Enemy) -> int:
	return World.M_FLYER if e.d.get("fly", false) else World.M_WALKER

static func ai_bat(e: Enemy, dt: float, p: Player) -> void:
	var a := TB.ang_to(e, p) + sin(e.anim * 6) * 0.9
	if e.t <= 0:
		e.t = randf() * 2 + 1.5
		e.dash = 0.4
	e.dash -= dt
	var sp := e.speed * (2.2 if e.dash > 0 else 1.0)
	World.move_body(G.room, e, cos(a) * sp * dt, sin(a) * sp * dt, World.M_FLYER)
	e.face = 1 if p.x > e.x else -1

static func ai_slime(e: Enemy, dt: float, p: Player) -> void:
	if e.state == &"hop":
		e.st -= dt
		World.move_body(G.room, e, e.vx * dt, e.vy * dt, World.M_WALKER)
		if e.st <= 0:
			e.state = &"idle"
			e.t = 0.7 + randf() * 0.6
	elif e.t <= 0:
		var a := TB.ang_to(e, p) + (randf() - 0.5) * 0.6
		e.vx = cos(a) * e.speed * 2.6
		e.vy = sin(a) * e.speed * 2.6
		e.state = &"hop"
		e.st = 0.35
		e.face = 1 if e.vx > 0 else -1

static func wander_keep(e: Enemy, dt: float, p: Player, near: float, far: float) -> void:
	var d := TB.dist(e, p)
	if not e.has_wander or e.wt <= 0:
		var want := -1 if d < near else (1 if d > far else 0)
		var off := (PI / 2) * (1 if randf() < 0.5 else -1) if want == 0 else (PI if want < 0 else 0.0)
		var a := TB.ang_to(e, p) + off + (randf() - 0.5) * 0.8
		e.wander = Vector2(e.x + cos(a) * 40, e.y + sin(a) * 40)
		e.has_wander = true
		e.wt = 0.8 + randf() * 0.6
	e.wt -= dt
	var hit := Combat.steer(e, e.wander.x, e.wander.y, e.speed, dt, _mode(e))
	if hit != 0:
		e.wt = 0
	e.face = 1 if p.x > e.x else -1

static func ai_archer(e: Enemy, dt: float, p: Player) -> void:
	if e.state == &"aim":
		e.st -= dt
		if e.st <= 0:
			var a := TB.ang_to(e, p)
			if G.floor_index >= 2 or e.elite:
				Combat.efan(e.x, e.y - 2, a, e.d.get("fan", 3), 0.4, 100, _shot(e, "bone"))
			else:
				Combat.eshot(e.x, e.y - 2, a, 100, _shot(e, "bone"), 2)
				Snd.play("ebullet")
			e.state = &"idle"
			e.t = 1.8 + randf()
		return
	wander_keep(e, dt, p, 80, 140)
	if e.t <= 0:
		e.state = &"aim"
		e.st = 0.45

static func ai_spore(e: Enemy, dt: float, p: Player) -> void:
	if not e.has_wander or e.wt <= 0:
		e.wander = World.free_spot(G.room, null, 0)
		e.has_wander = true
		e.wt = 2 + randf() * 2
	e.wt -= dt
	if e.state != &"puff":
		Combat.steer(e, e.wander.x, e.wander.y, e.speed, dt, World.M_WALKER)
	if e.t <= 0 and e.state != &"puff":
		e.state = &"puff"
		e.st = 0.5
	if e.state == &"puff":
		e.st -= dt
		if e.st <= 0:
			var n := 8 + mini(3, G.floor_index) * 2 + (4 if e.elite else 0)
			e.flip = not e.flip
			Combat.ering(e.x, e.y - 3, n, 52, 0.0 if e.flip else PI / n, _shot(e, "spore"))
			e.state = &"idle"
			e.t = 2.6 + randf() * 1.2

static func ai_cultist(e: Enemy, dt: float, p: Player) -> void:
	if e.state == &"cast":
		e.st -= dt
		e.ct -= dt
		if e.ct <= 0:
			e.ct = 0.06
			e.ca += 0.42
			Combat.eshot(e.x, e.y - 3, e.ca, 62, _shot(e, "dark"))
			if e.elite or G.floor_index >= 4:
				Combat.eshot(e.x, e.y - 3, e.ca + PI, 62, _shot(e, "dark"))
			Snd.play("ebullet")
		if e.st <= 0:
			e.state = &"idle"
			e.t = 3 + randf() * 1.5
		return
	if not e.has_wander or e.wt <= 0:
		e.wander = World.free_spot(G.room, p, 60)
		e.has_wander = true
		e.wt = 1.5 + randf()
	e.wt -= dt
	Combat.steer(e, e.wander.x, e.wander.y, e.speed, dt, World.M_WALKER)
	if e.t <= 0:
		e.state = &"cast"
		e.st = 1.1
		e.ct = 0.3
		e.ca = TB.ang_to(e, p)

static func ai_imp(e: Enemy, dt: float, p: Player) -> void:
	if e.dir == 0:
		e.dir = 1 if randf() < 0.5 else -1
	if not e.has_orb:
		e.orb = randf() * TAU
		e.has_orb = true
	e.orb += dt * 0.9 * e.dir
	var tx := p.x + cos(e.orb) * 85
	var ty := p.y + sin(e.orb) * 70
	Combat.steer(e, clampf(tx, 30, TB.SW - 30), clampf(ty, 44, TB.SH - 30), e.speed, dt, World.M_FLYER)
	e.face = 1 if p.x > e.x else -1
	if e.t <= 0:
		Combat.efan(e.x, e.y, TB.ang_to(e, p), 5 if e.elite else 3, 0.5, 92, _shot(e, "fire"))
		e.t = 2.2 + randf()

static func ai_knight(e: Enemy, dt: float, p: Player) -> void:
	match e.state:
		&"tele":
			e.st -= dt
			if e.st <= 0:
				e.state = &"charge"
				e.st = 0.9
				Snd.play("charge")
			return
		&"charge":
			e.st -= dt
			var hit := World.move_body(G.room, e, cos(e.ca) * 230 * dt, sin(e.ca) * 230 * dt, World.M_WALKER)
			if randf() < 0.5:
				Fx.particle(e.x, e.y + 5, 0, 0, 0.25, "#8b8f9c", 2)
			if hit != 0:
				e.state = &"stun"
				e.st = 0.9
				G.add_shake(3)
				Snd.play("hit")
				Fx.burst(e.x, e.y, ["#8b8f9c", "#f4ecd8"], 10, 60)
				Afx.dust(e.x, e.y + 4)
				if G.floor_index >= 3 or e.elite:
					Combat.ering(e.x, e.y, 8, 70, 0, _shot(e, "red"))
			elif e.st <= 0:
				e.state = &"idle"
				e.t = 1.2
			return
		&"stun":
			e.st -= dt
			if e.st <= 0:
				e.state = &"idle"
				e.t = 1
			return
	Combat.steer(e, p.x, p.y, e.speed, dt, World.M_WALKER)
	if e.t <= 0 and TB.dist(e, p) < 170:
		e.state = &"tele"
		e.st = 0.6
		e.ca = TB.ang_to(e, p)
		e.face = 1 if cos(e.ca) > 0 else -1

static func ai_ghost(e: Enemy, dt: float, p: Player) -> void:
	if not e.has_cyc:
		e.cyc = randf() * 3
		e.has_cyc = true
	e.cyc += dt
	var vis := TB.fmodp(e.cyc, 3.6) < 2.4
	if not vis and not e.hidden:
		e.hidden = true
	if vis and e.hidden:
		e.hidden = false
		if G.floor_index >= 1:
			Combat.ering(e.x, e.y, 6 + mini(4, G.floor_index), 55, randf() * TAU, _shot(e, "cyan"))
	Combat.steer(e, p.x, p.y, e.speed * (1.4 if e.hidden else 0.8), dt, World.M_FLYER)

## Flying book: flutters around and fires fans of pages.
static func ai_book(e: Enemy, dt: float, p: Player) -> void:
	wander_keep(e, dt, p, 70, 130)
	if e.t <= 0:
		Combat.efan(e.x, e.y - 2, TB.ang_to(e, p), 7 if e.elite else 5, 0.8, 80, _shot(e, "page"))
		e.t = 2.4 + randf()

## Drowned: shambles closer, spits water, bursts when it dies.
static func ai_drowned(e: Enemy, dt: float, p: Player) -> void:
	Combat.steer(e, p.x, p.y, e.speed, dt, World.M_WALKER)
	if e.t <= 0 and TB.dist(e, p) < 160:
		Combat.efan(e.x, e.y - 3, TB.ang_to(e, p), 3, 0.35, 75, _shot(e, "water"))
		e.t = 2.6 + randf()

## Frost wisp: darts around the player and leaves drifting ice motes.
static func ai_wisp(e: Enemy, dt: float, p: Player) -> void:
	if e.dir == 0:
		e.dir = 1 if randf() < 0.5 else -1
	if not e.has_orb:
		e.orb = randf() * TAU
		e.has_orb = true
	e.orb += dt * 1.6 * e.dir
	var tx := p.x + cos(e.orb) * 60
	var ty := p.y + sin(e.orb) * 50
	Combat.steer(e, clampf(tx, 30, TB.SW - 30), clampf(ty, 44, TB.SH - 30), e.speed, dt, World.M_FLYER)
	e.face = 1 if p.x > e.x else -1
	if e.t <= 0:
		var a := TB.ang_to(e, p)
		Combat.eshot(e.x, e.y, a, 22, _shot(e, "ice"), 2.5)
		if e.elite:
			Combat.eshot(e.x, e.y, a + 0.5, 22, _shot(e, "ice"), 2.5)
		e.t = 1.1 + randf() * 0.4

## Ice golem: lumbers forward, then slams the floor with a ring of ice.
static func ai_golem(e: Enemy, dt: float, p: Player) -> void:
	if e.state == &"slam":
		e.st -= dt
		if e.st <= 0:
			G.add_shake(4)
			Snd.play("boom")
			Combat.ering(e.x, e.y, 18 if e.elite else 12, 70, randf(), _shot(e, "ice"))
			Fx.burst(e.x, e.y + 6, ["#c8f0ff", "#4d9be6"], 14, 70)
			e.state = &"idle"
			e.t = 2.4 + randf()
		return
	Combat.steer(e, p.x, p.y, e.speed, dt, World.M_WALKER)
	if e.t <= 0 and TB.dist(e, p) < 130:
		e.state = &"slam"
		e.st = 0.7
		Snd.play("charge")

# ---------- Stage 7 behaviours ----------
## Bogling: lurks under the mire (untargetable, a faint shape), surfaces next
## to the player, spits a ring, then sinks again.
static func ai_ambush(e: Enemy, dt: float, p: Player) -> void:
	match e.state:
		&"under":
			e.st -= dt
			Combat.steer(e, p.x, p.y, e.speed, dt, World.M_FLYER)
			if e.st <= 0 or TB.dist(e, p) < 34:
				e.state = &"rise"
				e.st = 0.45
				e.hidden = false
				Fx.burst(e.x, e.y + 4, ["#3f7a5a", "#63b84f"], 8, 40)
		&"rise":
			e.st -= dt
			if e.st <= 0:
				Combat.ering(e.x, e.y - 2, 12 if e.elite else 9, 58, randf() * TAU, _shot(e, "spore"))
				Snd.play("ebullet")
				e.state = &"up"
				e.st = 1.2
		&"up":
			e.st -= dt
			e.face = 1 if p.x > e.x else -1
			if e.st <= 0:
				e.state = &"under"
				e.st = 1.6 + randf()
				e.hidden = true
		_:
			e.state = &"under"
			e.st = 0.8 + randf()
			e.hidden = true

## Monk: closes in fast, sidesteps, then strikes with a palm that bursts into
## a ring of ice and an aimed fan.
static func ai_monk(e: Enemy, dt: float, p: Player) -> void:
	match e.state:
		&"step":
			e.st -= dt
			World.move_body(G.room, e, e.vx * dt, e.vy * dt, World.M_WALKER)
			if e.st <= 0:
				e.state = &"palm"
				e.st = 0.3
				e.flash = 0.1
			return
		&"palm":
			e.st -= dt
			if e.st <= 0:
				Combat.ering(e.x, e.y, 10 if e.elite else 8, 70, randf() * TAU, _shot(e, "ice"))
				Combat.efan(e.x, e.y, TB.ang_to(e, p), 3, 0.3, 95, _shot(e, "ice"))
				Snd.play("ebullet")
				e.state = &"idle"
				e.t = 1.6 + randf() * 0.8
			return
	Combat.steer(e, p.x, p.y, e.speed, dt, World.M_WALKER)
	if e.t <= 0 and TB.dist(e, p) < 70:
		var a := TB.ang_to(e, p) + (PI / 2 if randf() < 0.5 else -PI / 2)
		e.vx = cos(a) * 180
		e.vy = sin(a) * 180
		e.state = &"step"
		e.st = 0.22
		e.face = 1 if p.x > e.x else -1

## Gunman: keeps his distance, shows his aim, then fires a quick burst.
static func ai_gunman(e: Enemy, dt: float, p: Player) -> void:
	match e.state:
		&"aim":
			e.st -= dt
			e.telegraph = TB.ang_to(e, p)
			e.has_telegraph = e.st > 0.1
			if e.st <= 0:
				e.has_telegraph = false
				e.state = &"fire"
				e.sub = e.d.get("burst", 5 if e.elite else 3)
				e.ct = 0.0
				e.ca = TB.ang_to(e, p)
			return
		&"fire":
			e.ct -= dt
			if e.ct <= 0:
				e.ct = 0.09
				Combat.eshot(e.x, e.y - 2, e.ca + (randf() - 0.5) * 0.12, e.d.get("shot_speed", 135), _shot(e, "red"), 2.5)
				Snd.play("ebullet")
				e.sub -= 1
				if e.sub <= 0:
					e.state = &"idle"
					e.t = 1.4 + randf()
			return
	wander_keep(e, dt, p, 90, 150)
	if e.t <= 0:
		e.state = &"aim"
		e.st = e.d.get("aim", 0.55)

## Mini-bosses: on top of their behaviour, a ring burst every few seconds.
static func _mini_extra(e: Enemy, dt: float) -> void:
	e.mini_t -= dt
	if e.mini_t <= 0:
		e.mini_t = 3.2 + randf()
		Combat.ering(e.x, e.y - 3, 16, 60, randf() * TAU, _shot(e, "red"))
		G.add_shake(2)

## Training dummy (Rogues layer): takes hits, never dies, reports damage per second.
static func ai_dummy(e: Enemy) -> void:
	e.dps_log.append(e.max_hp - e.hp)
	e.hp = e.max_hp
	if e.dps_log.size() > 180:
		e.dps_log.pop_front()
	var sum := 0.0
	for v in e.dps_log:
		sum += v
	e.dps = sum / 3.0
	e.burn_t = 0.0
	e.poison = 0.0
	e.bleed_t = 0.0

# ---------- Rift worlds and event rooms ----------
## Runner: a bat on foot. Weaves at the hero and lunges.
static func ai_runner(e: Enemy, dt: float, p: Player) -> void:
	var a := TB.ang_to(e, p) + sin(e.anim * 6) * 0.7
	if e.t <= 0:
		e.t = randf() * 2 + 1.5
		e.dash = 0.4
	e.dash -= dt
	var sp := e.speed * (2.0 if e.dash > 0 else 1.0)
	World.move_body(G.room, e, cos(a) * sp * dt, sin(a) * sp * dt, _mode(e))
	e.face = 1 if p.x > e.x else -1

## A lobbed shot from (x, y) that comes to rest about where (tx, ty) is and
## bursts into a ring there. Fused shots slow by 3% a tick, so the throw is
## sized to the distance.
static func lob(x: float, y: float, tx: float, ty: float, spr: String) -> void:
	var d := TB.dist_xy(x, y, tx, ty)
	var speed := clampf(d * 1.9, 70.0, 300.0) / Combat.shot_mult()
	Combat.eshot(x, y, TB.ang_xy(x, y, tx, ty), speed, spr, 3.5, 1.05, spr)

## Lobber: keeps its distance and throws a bomb at where you stand.
static func ai_lobber(e: Enemy, dt: float, p: Player) -> void:
	wander_keep(e, dt, p, 90, 150)
	if e.t <= 0:
		lob(e.x, e.y - 3, p.x, p.y, _shot(e, "fire"))
		if e.elite:
			lob(e.x, e.y - 3, p.x + randf_range(-30, 30), p.y + randf_range(-30, 30), _shot(e, "fire"))
		Snd.play("ebullet")
		e.t = 2.4 + randf()

## Bomber: runs at you, flashes for a moment, then blows up.
static func ai_bomber(e: Enemy, dt: float, p: Player) -> void:
	if e.state == &"puff":
		e.st -= dt
		if e.st <= 0:
			Combat.ering(e.x, e.y, 18 if e.elite else 12, 70, randf() * TAU, _shot(e, "fire"))
			Fx.burst(e.x, e.y, ["#e8873a", "#f2c94c", "#d8443c"], 20, 100, 0.4, 2)
			G.add_shake(3)
			Snd.play("boom")
			if TB.dist(e, p) < 26:
				Combat.hurt_player(1, e.d.get("label", "a bomber"))
			Combat.kill_enemy(e)
		return
	Combat.steer(e, p.x, p.y, e.speed, dt, _mode(e))
	e.face = 1 if p.x > e.x else -1
	if TB.dist(e, p) < 30:
		e.state = &"puff"
		e.st = 0.55
		Snd.play("charge")

## Caller: hangs back and calls in more of its smaller kin.
static func ai_caller(e: Enemy, dt: float, p: Player) -> void:
	wander_keep(e, dt, p, 110, 170)
	if e.t <= 0:
		e.t = 5.0 + randf()
		if G.enemies.size() < 12:
			for i in (3 if e.elite else 2):
				Combat.spawn_enemy(e.d["summon"], e.x + randf_range(-18, 18), e.y + randf_range(-14, 14))
			Fx.burst(e.x, e.y, ["#f2c94c", "#f4ecd8"], 10, 60)
			Snd.play("bell")

## Turret: stays put and fires a turning cross of shots.
static func ai_turret(e: Enemy, dt: float, p: Player) -> void:
	e.face = 1 if p.x > e.x else -1
	if e.t <= 0:
		e.t = 1.5
		e.angle += 0.4
		var n := 8 if e.elite else 4
		for i in n:
			Combat.eshot(e.x, e.y - 2, e.angle + i * TAU / n, 78, _shot(e, "red"), 2.5)
		Snd.play("ebullet")

## Loot goblin: runs from you, sheds coins, and slips away after 14 seconds.
static func ai_flee(e: Enemy, dt: float, p: Player) -> void:
	e.cyc += dt
	if e.cyc > 14.0:
		Fx.burst(e.x, e.y, ["#63b84f", "#f2c94c"], 14, 70)
		G.toast("THE GOBLIN GOT AWAY", "grey")
		e.hp = 0
		return
	if not e.has_wander or e.wt <= 0 or TB.dist_xy(e.x, e.y, e.wander.x, e.wander.y) < 10:
		# The farthest of a few random free spots.
		var best := Vector2(e.x, e.y)
		var bd := -1.0
		for i in 6:
			var s := World.free_spot(G.room, null, 0)
			var d := TB.dist_xy(s.x, s.y, p.x, p.y)
			if d > bd:
				bd = d
				best = s
		e.wander = best
		e.has_wander = true
		e.wt = 0.9
	e.wt -= dt
	if Combat.steer(e, e.wander.x, e.wander.y, e.speed, dt, _mode(e)) != 0:
		e.wt = 0
	e.face = 1 if e.wander.x > e.x else -1
	if e.t <= 0:
		e.t = 1.2
		Combat.drop_pickup("coin", e.x, e.y)
