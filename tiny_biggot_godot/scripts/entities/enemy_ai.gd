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
	if e.d.get("mini", false):
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
				Combat.eshot(e.x, e.y - 2, e.ca + (randf() - 0.5) * 0.12, 135, _shot(e, "red"), 2.5)
				Snd.play("ebullet")
				e.sub -= 1
				if e.sub <= 0:
					e.state = &"idle"
					e.t = 1.4 + randf()
			return
	wander_keep(e, dt, p, 90, 150)
	if e.t <= 0:
		e.state = &"aim"
		e.st = 0.55

## Mini-bosses: on top of their behaviour, a ring burst every few seconds.
static func _mini_extra(e: Enemy, dt: float) -> void:
	e.mini_t -= dt
	if e.mini_t <= 0:
		e.mini_t = 3.2 + randf()
		Combat.ering(e.x, e.y - 3, 16, 60, randf() * TAU, _shot(e, "red"))
		G.add_shake(2)
