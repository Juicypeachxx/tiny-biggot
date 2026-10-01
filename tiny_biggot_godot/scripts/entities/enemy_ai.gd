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
				Combat.efan(e.x, e.y - 2, a, 3, 0.4, 100, "bone")
			else:
				Combat.eshot(e.x, e.y - 2, a, 100, "bone", 2)
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
			Combat.ering(e.x, e.y - 3, n, 52, 0.0 if e.flip else PI / n, "spore")
			e.state = &"idle"
			e.t = 2.6 + randf() * 1.2

static func ai_cultist(e: Enemy, dt: float, p: Player) -> void:
	if e.state == &"cast":
		e.st -= dt
		e.ct -= dt
		if e.ct <= 0:
			e.ct = 0.06
			e.ca += 0.42
			Combat.eshot(e.x, e.y - 3, e.ca, 62, "dark")
			if e.elite or G.floor_index >= 4:
				Combat.eshot(e.x, e.y - 3, e.ca + PI, 62, "dark")
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
		Combat.efan(e.x, e.y, TB.ang_to(e, p), 5 if e.elite else 3, 0.5, 92, "fire")
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
				if G.floor_index >= 3 or e.elite:
					Combat.ering(e.x, e.y, 8, 70, 0, "red")
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
			Combat.ering(e.x, e.y, 6 + mini(4, G.floor_index), 55, randf() * TAU, "cyan")
	Combat.steer(e, p.x, p.y, e.speed * (1.4 if e.hidden else 0.8), dt, World.M_FLYER)

## Flying book: flutters around and fires fans of pages.
static func ai_book(e: Enemy, dt: float, p: Player) -> void:
	wander_keep(e, dt, p, 70, 130)
	if e.t <= 0:
		Combat.efan(e.x, e.y - 2, TB.ang_to(e, p), 7 if e.elite else 5, 0.8, 80, "page")
		e.t = 2.4 + randf()

## Drowned: shambles closer, spits water, bursts when it dies.
static func ai_drowned(e: Enemy, dt: float, p: Player) -> void:
	Combat.steer(e, p.x, p.y, e.speed, dt, World.M_WALKER)
	if e.t <= 0 and TB.dist(e, p) < 160:
		Combat.efan(e.x, e.y - 3, TB.ang_to(e, p), 3, 0.35, 75, "water")
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
		Combat.eshot(e.x, e.y, a, 22, "ice", 2.5)
		if e.elite:
			Combat.eshot(e.x, e.y, a + 0.5, 22, "ice", 2.5)
		e.t = 1.1 + randf() * 0.4

## Ice golem: lumbers forward, then slams the floor with a ring of ice.
static func ai_golem(e: Enemy, dt: float, p: Player) -> void:
	if e.state == &"slam":
		e.st -= dt
		if e.st <= 0:
			G.add_shake(4)
			Snd.play("boom")
			Combat.ering(e.x, e.y, 18 if e.elite else 12, 70, randf(), "ice")
			Fx.burst(e.x, e.y + 6, ["#c8f0ff", "#4d9be6"], 14, 70)
			e.state = &"idle"
			e.t = 2.4 + randf()
		return
	Combat.steer(e, p.x, p.y, e.speed, dt, World.M_WALKER)
	if e.t <= 0 and TB.dist(e, p) < 130:
		e.state = &"slam"
		e.st = 0.7
		Snd.play("charge")
