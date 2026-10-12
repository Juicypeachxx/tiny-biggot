class_name Rex
extends RefCounted
## REX THE FAT GOLDEN RETRIEVER: a hidden boss after the owner's own dog (his ask, 5 Oct;
## ROADMAP 4.5c). Expanded game only. His art, his barn and his moves are this game's own, drawn
## from the owner's photos: the old stone barn with its beams, the green hay, the blue striped mat,
## the potato field, and a pair of round sunglasses.
##
## Where: one hidden room in a run may be REX'S BARN (12% a floor from the second, once a run), and
## on the title screen a sleeping Rex can be woken (tap him, or SPECIAL, three times): the next
## run's first room then has a door to his barn. He sleeps on his mat until you come close or hit
## him (the first blows on a sleeping dog count double). Fill his bowl first (5 gold) and he wakes
## up for dinner, full and slow: 15% less health.
##
## First phase, a fat lazy dog: BELLY FLOP (a ring where he lands, a shock wave to roll through),
## ZOOMIES (laps of the barn on a track shown first, shedding fur), POTATO DIG (potatoes lobbed
## from his patch), WOOF (he breathes in, then a bark that spreads as a ring and shoves you), NAP
## (on his mat: snores, and takes double damage).
## Second phase: he puts on his sunglasses and pulls a moldy bread loaf out of the hay (his ask, 6 Oct: bread instead of a sword; it fights the same). SWORD SPIN (a ring
## shows its reach), LEAP SLASH (a landing ring, then a lane), THE FETCH (he throws the sword down a
## lane, then runs after it to bring it back), SWORD WAVE (a crescent of shots), and his flops and
## woofs, harder.
## Beaten, he rolls over for a belly rub, leaves a guardian's hoard and offers to come along: REX,
## a pet that flops onto crowds (pets.gd).
##
## The fight runs in RiftBosses (phases, the grace between them, shock waves and lobs); this file
## holds his moves, his barn and his drawing.

const MAT := Vector2(14.0 * 16, 13.4 * 16)
const HAY := Vector2(21.6 * 16, 5.4 * 16)
const PATCH := Vector2(5.4 * 16, 13.6 * 16)
const BOWL := Vector2(18.2 * 16, 14.6 * 16)
const CENTER := Vector2(14.0 * 16, 9.6 * 16)
const TRACK := Vector2(152.0, 74.0)    # the zoomies: an oval round the middle
const PILLARS := [Vector2i(10, 8), Vector2i(17, 8), Vector2i(10, 11), Vector2i(17, 11)]   # hay bales
const REACH := 64.0                    # the sword, from his mouth to its point
const FLOP_R := 34.0
const CHANCE := 0.12
const BOWL_PRICE := 5

static func is_rex(e: Enemy) -> bool:
	return e != null and e.boss == "rex"

# ---------- His barn ----------
## World.build_room: hay bales in the middle (cover), his own tiles.
static func layout(room: Room) -> void:
	room.kit = "kit_barn"
	for c in PILLARS:
		room.set_tile(c.x, c.y, World.T_PILLAR)

## G.setup_objects: his bowl.
static func setup_objects(r: Room) -> void:
	r.objects.append({ "kind": "x_bowl", "x": BOWL.x, "y": BOWL.y, "full": false })

## G.enter_room: the barn's welcome, and Rex asleep on his mat (until he is beaten).
static func on_enter(room: Room) -> void:
	if room.cleared:
		G.show_banner("REX'S BARN", "IT SMELLS OF HAY AND HAPPY DOG")
		return
	G.show_banner("REX'S BARN", "SOMETHING BIG IS SNORING")
	var e := Combat.spawn_boss("rex", true)
	e.x = MAT.x
	e.y = MAT.y - 10.0
	e.state = &"sleep"
	e.aux = 0.5
	G.run_stats["rex"] = true

## The title screen's secret: the next run starts beside his barn.
static func add_door(r: Room) -> bool:
	for d in ["w", "e", "n", "s"]:
		if d == r.entrance or r.exits.has(d) or r.secret_dirs.has(d) or r.doors.has(d):
			continue
		r.exits[d] = { "type": "barn", "reward": "" }
		r.doors[d] = true
		for cr in World.door_tiles(d):
			r.set_tile(cr.x, cr.y, World.T_DOOR)
		G.dyn_dirty = true
		G.run_stats["rex"] = true
		return true
	return false

static func wake(e: Enemy, line: String) -> void:
	e.state = &"intro"
	e.t = 1.2
	e.st = 0.0
	G.locked = true
	G.dyn_dirty = true
	Snd.music(GameData.BOSS_TRACK)
	G.show_banner(e.d["name"], line)
	Snd.play("bark")
	G.add_shake(3)

## RiftBosses.update while he sleeps: snores, and wakes when you come close or hit him.
static func sleeping(e: Enemy, dt: float) -> void:
	var p := G.player
	e.aux -= dt
	if e.aux <= 0:
		e.aux = 2.2
		Snd.play("snore")
		Fx.float_text(e.x + 16, e.y - 34, "Z", "white")
	if e.hp < e.max_hp:
		wake(e, "YOU WOKE HIM UP")
	elif TB.dist(e, p) < 64:
		wake(e, "HE WANTS TO PLAY")

## The bowl and Rex's offer (G.interact, prompts, drawing).
static func handles(kind: String) -> bool:
	return kind == "x_bowl"

static func _rex() -> Enemy:
	for e in G.enemies:
		if is_rex(e) and e.hp > 0:
			return e
	return null

static func prompt(o: Dictionary) -> Array:
	var e := _rex()
	if o.get("used", false):
		return ["REX'S BOWL", "LICKED CLEAN", ""]
	if e != null and e.state == &"sleep":
		return ["REX'S BOWL", "EMPTY. FILL IT AND HE WAKES UP FULL AND SLOW", "FILL IT: %d GOLD" % BOWL_PRICE]
	if e != null:
		return ["REX'S BOWL", "NOT NOW. HE IS BUSY", ""]
	return ["REX'S BOWL", "FILL IT AND REX SHARES: +1 HEART", "FILL IT: %d GOLD" % BOWL_PRICE]

static func interact(o: Dictionary) -> void:
	var p := G.player
	var e := _rex()
	if o.get("used", false) or (e != null and e.state != &"sleep"):
		return G.deny(o, "NOT NOW")
	if p.gold < BOWL_PRICE:
		return G.deny(o, "NEED %d GOLD" % BOWL_PRICE)
	p.gold -= BOWL_PRICE
	o["full"] = true
	o["used"] = true
	Snd.play("coin")
	if e != null:
		# Dinner first: he wakes up full, and slower to fight.
		e.max_hp *= 0.85
		e.hp = e.max_hp
		wake(e, "HE WAKES UP FOR DINNER. FULL AND SLOW")
	else:
		p.heal(2)
		Fx.float_text(p.x, p.y - 14, "REX SHARES", "pink")
		Snd.play("heal")

## G.on_boss_dead: a good boy rolls over. His hoard, and he offers to come along.
static func on_beaten(b: Enemy) -> void:
	var room := G.room
	G.show_banner("GOOD BOY, REX!", "HE ROLLS OVER FOR A BELLY RUB")
	Snd.play("bark")
	room.objects.append({ "kind": "chest", "x": 14.0 * TB.TS - 40, "y": 9.0 * TB.TS, "boss": true })
	G.drop_item(Weapons.random_weapon(Gear.roll_item_rarity(G.floor_index, "boss"), G.player.weapon), b.x - 20, b.y + 18)
	for i in 6:
		Combat.drop_pickup("gem", b.x, b.y)
	for i in 3:
		Combat.drop_pickup("ember", b.x, b.y)
	var offer := Pets.cage(G.player, MAT.x, MAT.y - 4, "free")
	offer["pet"] = "rex"
	offer["nocage"] = true
	room.objects.append(offer)
	Meta.meta["rex"] = int(Meta.meta.get("rex", 0)) + 1
	Meta.write_save()

# ---------- The fight (from RiftBosses.update) ----------
## The grace between the phases: he runs to the hay pile and pulls out the sword.
static func to_hay(e: Enemy, dt: float) -> void:
	var dv := HAY + Vector2(0, 14) - Vector2(e.x, e.y)
	var step := 280.0 * dt
	if dv.length() > step:
		e.x += dv.normalized().x * step
		e.y += dv.normalized().y * step
		e.face = 1 if dv.x > 0 else -1
	elif e.sub == 0:
		e.sub = 1
		Fx.burst(HAY.x, HAY.y, ["#789a3e", "#bed06e", "#96b252"], 26, 90)
		Snd.play("hatchet")
	if e.st >= RiftBosses.PHASE_T - 0.05:
		e.speed = 58.0   # cool dogs walk faster

static func rest_move(e: Enemy, p: Player, dt: float) -> void:
	EnemyAI.wander_keep(e, dt, p, 70, 140)
	e.face = 1 if p.x > e.x else -1

static func adjust_damage(e: Enemy, dmg: float) -> float:
	if e.state == &"sleep" or (e.state == &"nap" and e.sub == 1):
		return dmg * 2.0   # a sleeping dog: easy to hit
	return dmg

static func attack(e: Enemy, p: Player, dt: float) -> void:
	var h2 := e.phase == 2
	match e.state:
		&"flop": _flop(e, p, dt, 3 if h2 else 2)
		&"zoomies": _zoomies(e, p, dt)
		&"dig": _dig(e, p, dt)
		&"woof": _woof(e, p, dt, 2 if h2 else 1)
		&"nap": _nap(e, p, dt)
		&"spin": _spin(e, p, dt)
		&"leap": _leap(e, p, dt)
		&"fetch": _fetch(e, p, dt)
		&"wave": _wave(e, p, dt)

## A landing spot inside the room, clear of the hay bales.
static func _spot(v: Vector2, r: float) -> Vector2:
	var s := RiftBosses._inside(v)
	if World.hits_solid(G.room, s.x, s.y, r, World.M_WALKER):
		s = World.free_spot(G.room, null, 0, World.M_WALKER, r)
	return s

static func _flop(e: Enemy, p: Player, dt: float, flops: int) -> void:
	match e.sub:
		0:
			e.from = Vector2(e.x, e.y)
			e.to = _spot(Vector2(p.x, p.y), 14.0)
			e.sub = 1
			e.st = 0.0
			Snd.play("charge")
		1:
			var k := minf(1.0, e.st / 0.75)
			e.x = lerpf(e.from.x, e.to.x, k)
			e.y = lerpf(e.from.y, e.to.y, k)
			e.z = sin(k * PI) * 34.0
			if k >= 1.0:
				e.z = 0.0
				if TB.dist_xy(p.x, p.y, e.x, e.y) < FLOP_R + p.r * 0.5:
					Combat.hurt_player(1, e.d["name"])
				if Coop.on():   # (W3: the other heroes too)
					Coop.hazard(func(hero: Player) -> bool: return TB.dist_xy(hero.x, hero.y, e.x, e.y) < FLOP_R + hero.r * 0.5, e.d["name"])
				RiftBosses.waves.append({ "x": e.x, "y": e.y, "r": 10.0, "speed": 150.0, "max": 110.0, "w": 6.0, "hit": false,
					"by": e.d["name"] })
				Combat.ering(e.x, e.y, 12, 70, randf() * TAU, "bone")
				if e.phase == 2:
					Combat.ering(e.x, e.y, 8, 95, randf() * TAU, "red")
				Fx.burst(e.x, e.y + 8, ["#d9d0b4", "#bed06e", "#f4ecd8"], 20, 90)
				Afx.dust(e.x, e.y + 8)
				G.add_shake(6)
				Snd.play("boom")
				e.sub = 2
				e.st = 0.0
		2:
			if e.st >= 0.5:
				e.slams += 1
				if e.slams >= flops:
					e.slams = 0
					RiftBosses._done(e)
				else:
					e.sub = 0

## Where the zoomies' track is at angle a.
static func track_at(a: float) -> Vector2:
	return CENTER + Vector2(cos(a) * TRACK.x, sin(a) * TRACK.y)

static func _zoomies(e: Enemy, p: Player, dt: float) -> void:
	match e.sub:
		0:   # the track shows; he trots onto it
			if e.st == dt or e.st < 0.02:
				e.angle = atan2((e.y - CENTER.y) / TRACK.y, (e.x - CENTER.x) / TRACK.x)
				e.aux = 1.0 if randf() < 0.5 else -1.0
				e.aux2 = 0.0
				Snd.play("bark")
			var at := track_at(e.angle)
			var dv := at - Vector2(e.x, e.y)
			var step := 160.0 * dt
			if dv.length() > step:
				e.x += dv.normalized().x * step
				e.y += dv.normalized().y * step
			if e.st >= 1.0:
				e.sub = 1
				e.st = 0.0
		1:   # laps
			var turn := 3.2 * dt
			e.angle += e.aux * turn
			e.aux2 += turn
			var at := track_at(e.angle)
			e.face = 1 if -sin(e.angle) * e.aux * TRACK.x > 0 else -1
			e.x = at.x
			e.y = at.y
			if e.t <= 0:
				e.t = 0.12
				Combat.eshot(e.x, e.y - 4, randf() * TAU, 26, "bone")   # fur everywhere
			if e.aux2 >= TAU * 2.0:
				RiftBosses._done(e, 0.6)

static func _dig(e: Enemy, p: Player, dt: float) -> void:
	match e.sub:
		0:   # off to his potato patch
			var dv := PATCH - Vector2(e.x, e.y)
			Combat.steer(e, PATCH.x, PATCH.y, 120.0, dt, World.M_WALKER)
			e.face = 1 if dv.x > 0 else -1
			if dv.length() < 14.0 or e.st > 2.5:
				e.sub = 1
				e.st = 0.0
				e.t = 0.0
		1:   # digging: potatoes fly
			if randf() < 0.5:
				Fx.particle(e.x + randf_range(-8, 8), e.y + 8, randf_range(-40, 40), -50, 0.4, "#704f38", 2)
			if e.t <= 0:
				e.t = 0.3
				var off := Vector2.ZERO if e.repeat == 0 else Vector2(randf_range(-56, 56), randf_range(-40, 40))
				RiftBosses._lob(e.x, e.y - 6, p.x + off.x, p.y + off.y, RiftBosses.LOB_T, "potato", e)
				e.repeat += 1
				Snd.play("ebullet")
			if e.st >= 2.4:
				e.repeat = 0
				RiftBosses._done(e)

static func _woof(e: Enemy, p: Player, dt: float, woofs: int) -> void:
	match e.sub:
		0:   # he breathes in (the ring under him gathers)
			e.face = 1 if p.x > e.x else -1
			if e.st >= 0.7:
				e.sub = 1
				e.st = 0.0
				Fx.float_text(e.x, e.y - 44, "WOOF!", "gold", true)
				Snd.play("bark")
				RiftBosses.waves.append({ "x": e.x, "y": e.y, "r": 12.0, "speed": 170.0, "max": 300.0, "w": 8.0, "hit": false,
					"by": e.d["name"] })
				Combat.ering(e.x, e.y - 6, 20 if e.phase == 2 else 16, 80, randf() * TAU, "bone")
				var away := Vector2(p.x - e.x, p.y - e.y)
				if away.length() < 120.0 and away.length() > 0.1 and p.dodge_t <= 0:
					away = away.normalized() * 28.0
					World.move_body(G.room, p, away.x, away.y, World.M_PLAYER)
				G.add_shake(4)
		1:
			if e.st >= 0.45:
				e.repeat += 1
				if e.repeat >= woofs:
					e.repeat = 0
					RiftBosses._done(e)
				else:
					e.sub = 0
					e.st = 0.0

static func _nap(e: Enemy, p: Player, dt: float) -> void:
	match e.sub:
		0:   # to his mat
			var dv := MAT - Vector2(e.x, e.y + 10)
			Combat.steer(e, MAT.x, MAT.y - 10, 110.0, dt, World.M_WALKER)
			if dv.length() < 12.0 or e.st > 2.5:
				e.sub = 1
				e.st = 0.0
				e.t = 0.0
				Fx.float_text(e.x, e.y - 36, "YAWN", "white")
		1:   # asleep: easy to hit; every snore puffs a slow ring
			if e.t <= 0:
				e.t = 1.0
				Snd.play("snore")
				Fx.float_text(e.x + 16, e.y - 34, "Z", "white")
				Combat.ering(e.x, e.y - 4, 6, 35, randf() * TAU, "bone")
			if e.st >= 3.2:
				e.sub = 2
				e.st = 0.0
		2:   # a big stretch
			if e.st >= 0.4:
				RiftBosses._done(e)

static func _spin(e: Enemy, p: Player, dt: float) -> void:
	match e.sub:
		0:   # the ring of his reach shows
			if e.st < 0.02:
				e.angle = TB.ang_to(e, p) + PI
				e.aux = 1.0 if randf() < 0.5 else -1.0
				e.aux2 = 0.0
				Snd.play("charge")
			if e.st >= 0.7:
				e.sub = 1
				e.st = 0.0
		1:
			var turn := TAU / 0.7 * dt
			e.angle += e.aux * turn
			e.aux2 += turn
			var mouth := mouth_pos(e)
			var tip := mouth + Vector2(cos(e.angle), sin(e.angle)) * REACH
			var base := mouth + Vector2(cos(e.angle), sin(e.angle)) * 12.0
			if RiftBosses._near_seg(p.x, p.y, base, tip, 6.0 + p.r * 0.5):
				Combat.hurt_player(1, e.d["name"])
			if Coop.on():   # (W3: the other heroes too)
				Coop.hazard(func(hero: Player) -> bool: return RiftBosses._near_seg(hero.x, hero.y, base, tip, 6.0 + hero.r * 0.5), e.d["name"])
			if fmod(e.aux2, PI / 6.0) < turn:
				Combat.eshot(tip.x, tip.y, e.angle + e.aux * PI / 2, 80, "bone")
			if e.aux2 >= TAU * 1.5:
				RiftBosses._done(e)

static func _leap(e: Enemy, p: Player, dt: float) -> void:
	match e.sub:
		0:
			e.from = Vector2(e.x, e.y)
			e.to = _spot(Vector2(p.x, p.y), 14.0)
			e.ca = TB.ang_xy(e.from.x, e.from.y, e.to.x, e.to.y)
			e.face = 1 if cos(e.ca) > 0 else -1
			e.sub = 1
			e.st = 0.0
			Snd.play("charge")
		1:
			var k := minf(1.0, e.st / 0.7)
			e.x = lerpf(e.from.x, e.to.x, k)
			e.y = lerpf(e.from.y, e.to.y, k)
			e.z = sin(k * PI) * 40.0
			if k >= 1.0:
				e.z = 0.0
				if TB.dist_xy(p.x, p.y, e.x, e.y) < 28.0 + p.r * 0.5:
					Combat.hurt_player(1, e.d["name"])
				if Coop.on():   # (W3: the other heroes too)
					Coop.hazard(func(hero: Player) -> bool: return TB.dist_xy(hero.x, hero.y, e.x, e.y) < 28.0 + hero.r * 0.5, e.d["name"])
				Afx.dust(e.x, e.y + 8)
				G.add_shake(4)
				Snd.play("boom")
				e.sub = 2
				e.st = 0.0
		2:   # the slash: a lane ahead of him, then the blade
			if e.st >= 0.3:
				var dx := cos(e.ca)
				var dy := sin(e.ca)
				var px := p.x - e.x
				var py := p.y - e.y
				var along := px * dx + py * dy
				if along > 0 and along < 120.0 and absf(px * dy - py * dx) < 8.0 + p.r * 0.5:
					Combat.hurt_player(1, e.d["name"])
				if Coop.on():   # (W3: the other heroes too)
					var lane := func(hero: Player) -> bool:
						var hx := hero.x - e.x
						var hy := hero.y - e.y
						var ahead := hx * dx + hy * dy
						return ahead > 0 and ahead < 120.0 and absf(hx * dy - hy * dx) < 8.0 + hero.r * 0.5
					Coop.hazard(lane, e.d["name"])
				for j in 3:
					Combat.eshot(e.x + dy * (j - 1) * 6.0, e.y - dx * (j - 1) * 6.0, e.ca, 150, "bone", 3.0)
				Snd.play("hatchet")
				e.sub = 3
				e.st = 0.0
		3:
			if e.st >= 0.25:
				e.slams += 1
				if e.slams >= 2:
					e.slams = 0
					RiftBosses._done(e)
				else:
					e.sub = 0

static func _fetch(e: Enemy, p: Player, dt: float) -> void:
	match e.sub:
		0:   # the lane the sword will fly down
			if e.st < 0.02:
				e.ca = TB.ang_to(e, p)
				e.aux2 = Afx.reach(e.x, e.y, e.ca, 400.0, World.M_BULLET)
				e.face = 1 if cos(e.ca) > 0 else -1
			if e.st >= 0.6:
				e.sub = 1
				e.st = 0.0
				e.from = mouth_pos(e)
				Snd.play("hatchet")
		1:   # it flies, spinning
			var d := minf(e.st * 330.0, e.aux2)
			e.to = e.from + Vector2(cos(e.ca), sin(e.ca)) * d
			if TB.dist_xy(e.to.x, e.to.y, p.x, p.y) < 10.0 + p.r:
				Combat.hurt_player(1, e.d["name"])
			if Coop.on():   # (W3: the other heroes too)
				Coop.hazard(func(hero: Player) -> bool: return TB.dist_xy(e.to.x, e.to.y, hero.x, hero.y) < 10.0 + hero.r, e.d["name"])
			if d >= e.aux2:
				e.sub = 2
				e.st = 0.0
				G.add_shake(2)
				Snd.play("hit")
				Fx.float_text(e.x, e.y - 40, "FETCH!", "gold")
		2:   # he looks at it, tail wagging...
			if e.st >= 0.35:
				e.sub = 3
				e.st = 0.0
				Snd.play("bark")
		3:   # ...and runs down the lane to bring it back
			var dv := e.to - Vector2(e.x, e.y)
			var step := 300.0 * dt
			var arrived := dv.length() <= step + 14.0
			if not arrived:
				var n := dv.normalized()
				arrived = World.move_body(G.room, e, n.x * step, n.y * step, World.M_WALKER) != 0
			if arrived or e.st > 2.0:
				Combat.ering(e.x, e.y - 4, 10, 70, randf() * TAU, "bone")
				RiftBosses._done(e)

static func _wave(e: Enemy, p: Player, dt: float) -> void:
	match e.sub:
		0:   # he aims (a line to you)
			e.ca = TB.ang_to(e, p)
			e.face = 1 if cos(e.ca) > 0 else -1
			if e.st >= 0.45:
				e.sub = 1
				e.st = 0.0
		1:   # a crescent of shots, side by side, all flying the same way
			var m := mouth_pos(e)
			for j in 9:
				var off := (j - 4) * 0.22
				var at := m + Vector2(cos(e.ca + off), sin(e.ca + off)) * 18.0
				Combat.eshot(at.x, at.y, e.ca, 150, "bone", 3.0)
			Snd.play("hatchet")
			e.repeat += 1
			if e.repeat >= 3:
				e.repeat = 0
				RiftBosses._done(e)
			else:
				e.sub = 0
				e.st = 0.0

# ---------- Drawing ----------
## Where his mouth is (the sword's grip).
static func mouth_pos(e: Enemy) -> Vector2:
	return Vector2(e.x, e.y + e.r + 2.0 - 32.0 - e.z)

## world_view._enemy_sprite: lying down to sleep, nap, after a flop and on his laps.
static func sprite(e: Enemy) -> String:
	if e.state == &"sleep" or (e.state == &"nap" and e.sub >= 1) or (e.state == &"flop" and e.sub == 2) \
			or (e.state == &"zoomies" and e.sub == 1):
		return "rex_lie"
	return "rex"

## The barn's floor: his potato patch, his mat, the hay pile (with a sword's grip in it, at first).
static func draw_floor(ci: CanvasItem, t: float) -> void:
	if G.room == null or G.room.type != "barn":
		return
	Gfx.sp(ci, "rex_potatoes", PATCH.x, PATCH.y + 14, 2.0, 2.0)
	Gfx.sp(ci, "rex_mat", MAT.x, MAT.y + 12, 2.0, 2.0)
	var sword_in := true
	for e in G.enemies:
		if is_rex(e) and (e.phase == 2 or (e.state == &"phase" and e.sub == 1)):
			sword_in = false
	if G.room.cleared:
		sword_in = false
	if sword_in:
		# Just the grip shows: a hint.
		Gfx.sprite(ci, "rex_sword", HAY.x + 6, HAY.y - 6, 5, 4, 1.0, 1.0, -PI / 2.6, false)
	Gfx.sp(ci, "rex_hay", HAY.x, HAY.y + 10, 2.0, 2.0)

static func draw_bowl(ci: CanvasItem, o: Dictionary, t: float) -> void:
	Gfx.sp(ci, "rex_bowl", o["x"], o["y"] + 6, 2.0, 2.0)
	if o["full"] and not G.room.cleared and _rex() == null:
		ci.draw_rect(Rect2(o["x"] - 6, o["y"] - 2, 12, 2), TB.c("#a8705a"))

## With his body (RiftBosses.draw_parts): the sunglasses and the sword, Z's, a breath before a woof.
static func draw_parts(ci: CanvasItem, e: Enemy, foot: float, t: float) -> void:
	var lying := sprite(e) == "rex_lie"
	if e.state == &"woof" and e.sub == 0:
		var k := clampf(e.st / 0.7, 0.0, 1.0)
		Gfx.text(ci, "...", e.x + 22 * e.face, foot - 66, "white", 1, 0.5)
		Afx.circle(ci, e.x, foot - 4, 40.0 - 22.0 * k, TB.c("#f2c94c"), t, 0.4 + 0.6 * k)
	if e.phase < 2 or lying:
		return
	# The sunglasses.
	Gfx.sp(ci, "rex_shades", e.x, foot - 40, 2.0, 2.0)
	# The sword: in his mouth, spinning with him, or out on its flight.
	var mouth := Vector2(e.x, foot - 32)
	var a := 0.0 if e.face > 0 else PI
	if e.state == &"spin" and e.sub == 1:
		a = e.angle
	elif e.state == &"fetch" and e.sub >= 1:
		var spin_a := e.st * 20.0 if e.sub == 1 else e.ca
		Gfx.sprite(ci, "rex_sword", e.to.x, e.to.y, 18, 4, 2.0, 2.0, spin_a, false)
		return
	elif e.state == &"wave" or e.state == &"leap":
		a = e.ca
	Gfx.sprite(ci, "rex_sword", mouth.x, mouth.y, 5, 4, 2.0, 2.0, a, false)

## On the floor with the other warnings (RiftBosses.draw_ground).
static func draw_ground(ci: CanvasItem, e: Enemy, t: float) -> void:
	var warn := Afx.C_WARN
	match e.state:
		&"flop":
			if e.sub == 1:
				Afx.landing(ci, e.to.x, e.to.y + 6, FLOP_R, e.st / 0.75, warn, t)
		&"leap":
			if e.sub == 1:
				Afx.landing(ci, e.to.x, e.to.y + 6, 28.0, e.st / 0.7, warn, t)
			elif e.sub == 2:
				Afx.lane(ci, e.x, e.y, e.ca, 8.0, 120.0, e.st / 0.3, warn, t)
		&"zoomies":
			if e.sub == 0:
				# The track: a dashed oval with arrows the way he will run.
				var n := 40
				for i in n:
					if i % 2 == 1:
						continue
					var a0 := float(i) / n * TAU
					var a1 := float(i + 1) / n * TAU
					ci.draw_line(track_at(a0), track_at(a1), Color(1.0, 0.54, 0.54, 0.85), 2.0)
				for i in 8:
					var a := float(i) / 8 * TAU + t * e.aux * 1.5
					var at := track_at(a)
					var dirv := (track_at(a + 0.05 * e.aux) - at).normalized()
					ci.draw_line(at - dirv * 4 + dirv.orthogonal() * 3, at, Color(1, 0.54, 0.54, 0.9), 1.0)
					ci.draw_line(at - dirv * 4 - dirv.orthogonal() * 3, at, Color(1, 0.54, 0.54, 0.9), 1.0)
		&"spin":
			if e.sub == 0:
				Afx.landing(ci, e.x, e.y + 2, REACH + 4.0, e.st / 0.7, warn, t)
		&"fetch":
			if e.sub == 0 or e.sub == 2:
				Afx.lane(ci, e.x, e.y, e.ca, 10.0, e.aux2, e.st / (0.6 if e.sub == 0 else 0.35), warn, t)
		&"wave":
			if e.sub == 0:
				ci.draw_set_transform(Vector2(roundf(e.x), roundf(e.y - 8)), e.ca, Vector2.ONE)
				ci.draw_rect(Rect2(20, -0.5, 240, 1.0), Color(warn.r, warn.g, warn.b, 0.4 + 0.5 * e.st / 0.45))
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		&"dig":
			if e.sub == 0:
				Afx.circle(ci, PATCH.x, PATCH.y + 8, 30.0, TB.c("#a8705a"), t, 0.7)

# ---------- The title screen's secret ----------
static var pokes := 0
static var awake_t := 0.0

## Tap him (or press SPECIAL) three times.
static func poke() -> void:
	if not GameData.rogues():
		return
	pokes += 1
	match pokes:
		1:
			G.toast("ZZZ...", "white")
			Snd.play("snore")
		2:
			G.toast("HE OPENS ONE EYE", "white")
			Snd.play("snore")
		_:
			if not G.rex_call:
				G.rex_call = true
				awake_t = 3.0
				G.toast("WOOF! REX WANTS TO PLAY. HIS BARN IS BY YOUR FIRST ROOM", "gold")
				Snd.play("bark")

static func title_rect() -> Rect2:
	return Rect2(6, 238, 70, 40)

static func draw_title(ci: CanvasItem, t: float) -> void:
	var x := 40.0
	var y := 272.0
	Gfx.sp(ci, "rex_hay", x, y + 4, 1.0, 1.0)
	if G.rex_call:
		Gfx.sp(ci, "rex", x, y - 2, 1.0, 1.0, 0.0, false)
		if Meta.meta.get("rex", 0) > 0:
			Gfx.sp(ci, "rex_shades", x, y - 17, 1.0, 1.0)
		if floori(t * 2) % 2 == 0:
			Gfx.text(ci, "WOOF!", x + 18, y - 30, "gold")
	else:
		Gfx.sp(ci, "rex_lie", x, y - 1, 1.0, 1.0)
		for i in 3:
			var k := fmod(t * 0.6 + i / 3.0, 1.0)
			Gfx.text(ci, "Z", x + 10 + k * 10, y - 16 - k * 14, "white", 1, 0.0, true, 1.0 - k)
