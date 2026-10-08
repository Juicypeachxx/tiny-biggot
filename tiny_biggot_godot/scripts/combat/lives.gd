class_name Lives
extends RefCounted
## 21.5 MONSTERS WITH LIVES OF THEIR OWN (his word, 8 Oct: "make game more alive"). Expanded game only.
##   asleep  in the first wave of a fight room, one ordinary walking foe in three (by its number, no
##           dice) is asleep: Zz. It wakes when you come near, when it is hurt, when a foe calls,
##           when it is the last one left, or after a while. The first hit on a sleeper does double
##           damage: a sneak attack.
##   calls   a foe brought below half health (one in two, by its number) calls for help: sleepers
##           near it wake, and foes of its kind nearby come running faster for a few seconds.
##   moths   mothlings flutter round the nearest light (a standing candelabra, a wall torch) until
##           you come close or hit one. Knock their lamp over and they come for you in a frenzy.
##   play    a fire-dog chases the sootlings about until it notices you (you come near, it is hurt,
##           or it tires of the game); a sootling flees from it.
##   greed   slimes leave you for dropped coins and gems near them and swallow them: each makes the
##           slime bigger and tougher. Burst it and the coins come back.
## No dice of the run's own are rolled here (choices go by a foe's number); what it changes is how
## foes act, so it changes play.

const WAKE_R := 72.0
const SLEEP_MAX := 14.0
const CALL_R := 150.0
const RALLY := 1.35
const RALLY_TIME := 3.0
const MOTH_NOTICE := 64.0
const DOG_NOTICE := 120.0
const DOG_BORED := 6.0
const GREED_R := 70.0
const SLIME_MAX := 1.6
const TORCHES := [Vector2(6 * 16 + 9, 16 + 6), Vector2(21 * 16 + 9, 16 + 6)]   # the two wall torches (world_view)

static func on() -> bool:
	return GameData.rogues()

# ---------- Asleep ----------
## Game.spawn_wave: in the first wave of a fight room, some ordinary walkers are asleep.
static func on_wave(spawned: Array, first: bool) -> void:
	if not on() or not first or G.room == null or G.room.type != "combat":
		return
	for e: Enemy in spawned:
		if e.uid % 3 == 1 and not e.elite and not e.is_boss() and not e.d.get("mini", false) and not e.d.get("champion", false) \
				and not e.d.get("fly", false) and e.type != "dummy":
			e.asleep = true

static func wake(e: Enemy) -> void:
	if not e.asleep:
		return
	e.asleep = false
	e.sleep_t = 0.0
	pop(e.x, e.y - e.r - 12, "!", "red")

## A floating word, put where it is asked for (Fx.float_text jitters it with the run's dice).
static func pop(x: float, y: float, text: String, col: String) -> void:
	Fx.texts.append({ "x": x, "y": y, "text": text, "col": col, "life": 0.7, "big": false })

static func _others_awake(e: Enemy) -> bool:
	for o: Enemy in G.enemies:
		if o != e and o.hp > 0 and not o.asleep and o.type != "dummy":
			return true
	return false

# ---------- Every tick of a foe (Combat.update_enemies, before its own AI) ----------
## True when this foe's life took the tick (asleep, a moth at its lamp, a dog at play, a sootling
## running from one); its own AI then waits.
static func override(e: Enemy, dt: float, p: Player) -> bool:
	if not on():
		return false
	if e.rally_t > 0.0:
		e.rally_t -= dt
		if e.rally_t <= 0.0:
			e.speed /= RALLY
	if e.asleep:
		e.sleep_t += dt
		if TB.dist(e, p) < WAKE_R or e.sleep_t > SLEEP_MAX or not _others_awake(e):
			wake(e)
		return true
	if e.d.get("ai", "") == "slime":
		return _greed(e, dt)
	if e.provoked:
		return false
	if e.type == "mothling":
		return _moth(e, dt, p)
	if e.type == "firedog":
		return _dog(e, dt, p)
	if e.type == "sootling":
		return _soot(e, dt, p)
	return false

static func _rally(e: Enemy) -> void:
	if e.rally_t <= 0.0:
		e.speed *= RALLY
	e.rally_t = RALLY_TIME

# ---------- Calls for help ----------
## Combat.damage_enemy, after the blow: below half health, one foe in two calls for help.
static func on_hurt(e: Enemy) -> void:
	if not on():
		return
	e.provoked = true
	if e.called or e.hp <= 0 or e.hp >= e.max_hp * 0.5 or e.is_boss() or e.type == "dummy":
		return
	e.called = true
	if e.uid % 2 != 0:
		return
	var line := "HELP!"
	if e.type.contains("hound") or e.type.contains("dog") or e.type.contains("fang") or e.type == "coyote":
		line = "AWOOO!"
	elif e.d.get("fly", false):
		line = "SKREEE!"
	else:
		line = ["HELP!", "OVER HERE!", "TO ME!"][e.uid % 3]
	Barks.say(e, line, "red")
	for o: Enemy in G.enemies:
		if o == e or o.hp <= 0 or TB.dist(o, e) > CALL_R:
			continue
		wake(o)
		o.provoked = true
		if o.type == e.type:
			_rally(o)

# ---------- Moths and lamps ----------
static func _lamp(e: Enemy) -> Variant:
	var best: Variant = null
	var bd := 1e9
	for o in G.room.objects:
		if o["kind"] == "e_candle" and not o.get("down", false) and not o.get("gone", false):
			var d := TB.dist_xy(o["x"], o["y"] - 14.0, e.x, e.y)
			if d < bd:
				bd = d
				best = Vector2(o["x"], o["y"] - 14.0)
	if best == null:
		for t: Vector2 in TORCHES:
			var d := t.distance_to(Vector2(e.x, e.y))
			if d < bd:
				bd = d
				best = t + Vector2(0, 14)   # just below the torch, over the floor's edge
	return best

static func _moth(e: Enemy, dt: float, p: Player) -> bool:
	if TB.dist(e, p) < MOTH_NOTICE or e.hp < e.max_hp:
		e.provoked = true
		return false
	var lamp: Variant = _lamp(e)
	if lamp == null:
		return false
	var a := G.time * 3.0 + e.uid * 1.7
	var tx: float = lamp.x + cos(a) * 12.0
	var ty: float = lamp.y + sin(a * 1.3) * 7.0
	e.face = 1 if tx > e.x else -1
	e.x += (tx - e.x) * minf(1.0, dt * 3.0)
	e.y += (ty - e.y) * minf(1.0, dt * 3.0)
	return true

## RoomDress.knock: a lamp fell; the moths round it come for you in a frenzy.
static func lamp_down(x: float, y: float) -> void:
	if not on():
		return
	for e: Enemy in G.enemies:
		if e.hp > 0 and e.type == "mothling" and not e.provoked and TB.dist_xy(e.x, e.y, x, y - 14.0) < 60.0:
			e.provoked = true
			_rally(e)
			e.rally_t = 4.0
			pop(e.x, e.y - 12, "!", "red")

# ---------- Fire-dogs and sootlings ----------
static func _nearest(e: Enemy, type: String, within: float) -> Enemy:
	var best: Enemy = null
	var bd := within
	for o: Enemy in G.enemies:
		if o != e and o.hp > 0 and o.type == type and o.spawn_t <= 0:
			var d := TB.dist(o, e)
			if d < bd:
				bd = d
				best = o
	return best

static func _dog(e: Enemy, dt: float, p: Player) -> bool:
	e.sleep_t += dt   # how long it has played
	if TB.dist(e, p) < DOG_NOTICE or e.hp < e.max_hp or e.sleep_t > DOG_BORED:
		e.provoked = true
		return false
	var s := _nearest(e, "sootling", 200.0)
	if s == null:
		return false
	if e.play_cd > 0.0:
		e.play_cd -= dt   # sits a moment, tail going
		return true
	var d := TB.dist(e, s)
	var sp := e.speed * 1.2 * dt
	e.face = 1 if s.x > e.x else -1
	World.move_body(G.room, e, (s.x - e.x) / maxf(d, 1.0) * sp, (s.y - e.y) / maxf(d, 1.0) * sp, World.M_WALKER)
	if d < e.r + s.r + 3.0:
		var a := TB.ang_xy(e.x, e.y, s.x, s.y)
		s.kx = cos(a) * 160.0
		s.ky = sin(a) * 160.0
		Barks.say(s, "EEP!", "orange")
		e.play_cd = 0.8
	return true

static func _soot(e: Enemy, dt: float, p: Player) -> bool:
	if TB.dist(e, p) < DOG_NOTICE or e.hp < e.max_hp:
		e.provoked = true
		return false
	var dog := _nearest(e, "firedog", 80.0)
	if dog == null or dog.provoked:
		return false
	var d := TB.dist(e, dog)
	var sp := e.speed * 0.9 * dt
	e.face = 1 if e.x > dog.x else -1
	World.move_body(G.room, e, (e.x - dog.x) / maxf(d, 1.0) * sp, (e.y - dog.y) / maxf(d, 1.0) * sp, World.M_FLYER)
	return true

# ---------- Greedy slimes ----------
## True while a slime goes for a coin instead of for you.
static func _greed(e: Enemy, dt: float) -> bool:
	var best: Pickup = null
	var bd := GREED_R
	for k: Pickup in G.pickups:
		if (k.kind == "coin" or k.kind == "gem") and k.z <= 1.0:
			var d := TB.dist_xy(k.x, k.y, e.x, e.y)
			if d < bd:
				bd = d
				best = k
	if best == null:
		return false
	if bd < e.r + 3.0:
		G.pickups.erase(best)
		e.coins += 5 if best.kind == "gem" else 1
		if e.scale < SLIME_MAX:
			var s1 := minf(SLIME_MAX, e.scale + 0.1)
			e.r *= s1 / e.scale
			e.scale = s1
		var more := e.max_hp * 0.2
		e.max_hp += more
		e.hp += more
		pop(e.x, e.y - e.r - 10, "GULP!", "lime")
		Snd.play("coin")
		return true
	var step := e.speed * dt
	e.face = 1 if best.x > e.x else -1
	World.move_body(G.room, e, (best.x - e.x) / bd * step, (best.y - e.y) / bd * step, World.M_WALKER)
	return true

## Combat.kill_enemy: a slime gives back what it swallowed.
static func on_kill(e: Enemy) -> void:
	if e.coins <= 0:
		return
	var gems := e.coins / 5
	for i in mini(gems, 6):
		Combat.drop_pickup("gem", e.x, e.y)
	for i in mini(e.coins - mini(gems, 6) * 5, 12):
		Combat.drop_pickup("coin", e.x, e.y)
	e.coins = 0

# ---------- Drawing (world_view._draw_enemy) ----------
static func draw(ci: CanvasItem, e: Enemy, t: float, foot: float) -> void:
	if e.asleep:
		var top := foot - e.r * 2.0 * e.scale - 6.0
		for k in 2:
			var ph := fmod(t * 0.6 + k * 0.5 + e.uid * 0.13, 1.0)   # two Zs rising one after the other
			Gfx.text(ci, "Z", e.x + 5 + ph * 7.0, top - ph * 13.0, "white", 1, 0.5, true, minf(1.0, (1.0 - ph) * 1.6))
	if e.coins > 0:
		for k in mini(e.coins, 5):
			var a := t * 1.5 + k * 1.3 + e.uid
			Gfx.px(ci, TB.c("#f2c94c"), e.x + cos(a) * e.r * 0.45, foot - e.r * e.scale - 2 + sin(a * 1.4) * e.r * 0.3, 1)
