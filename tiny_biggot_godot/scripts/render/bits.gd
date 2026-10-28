class_name Bits
extends RefCounted
## 60.1 (his ask, 26 Oct: "better will it be to revamp effect, make them like really really good"):
## the effects that were missing. Debris that flies, bounces and settles; fast spark streaks on
## every blow; a foe bursting into bits of its own colours when it dies; each weapon family's own
## particles on a hit (embers, slivers of ice, little forks of lightning, bubbles, specks of light,
## dark wisps, drops); cracks in the floor under heavy blows and big blasts; and the same particles
## rising off burning, frozen, poisoned, shocked, bleeding, gloomed and seared foes.
##
## Drawing only, like Afx and Vfx, and under the same switch (FANCY EFFECTS): its own random
## stream, nothing here is read by the rules, and it is called only from Afx, Vfx and Juice (the
## rules gain no line), so the replays stay identical. Bounded: one pool of CAP particles (when it
## is full the newest take the place of others in turn), at most PER_TICK new ones a tick, at most
## CRACKS cracks, and only a few afflicted foes looked at each tick.

const CAP := 256
const PER_TICK := 48
const CRACKS := 10
const GRAV := 520.0          # px/s/s, for things in the air (their height z)

const K_CHUNK := 0           # debris, or a piece of a foe: flies up, falls, bounces, settles, fades
const K_STREAK := 1          # a spark that streaks out and slows: a short line along its path
const K_EMBER := 2           # rises, wavers and cools from yellow to red
const K_SHARD := 3           # a sliver of ice that tumbles and falls
const K_BUBBLE := 4          # rises, wobbles and pops
const K_MOTE := 5            # a speck of light that rises and twinkles
const K_WISP := 6            # a dark speck that drifts and sinks
const K_DROP := 7            # a drop that arcs and falls
const K_ZAP := 8             # a little fork of lightning, gone in a blink

## What a hit of each weapon family gives off besides its streaks: [kind, how many].
const FAMILY := { "pyre": [K_EMBER, 3], "fury": [K_EMBER, 2], "frost": [K_SHARD, 3], "venom": [K_BUBBLE, 2],
	"storm": [K_ZAP, 1], "blood": [K_DROP, 3], "shadow": [K_WISP, 3], "malice": [K_WISP, 3],
	"arcane": [K_MOTE, 2], "fortune": [K_MOTE, 2], "swarm": [K_MOTE, 2], "demolition": [K_CHUNK, 2] }
## An explosion's colour (Vfx.RAMP) and what flies out of it.
const RAMP_KIND := { "fire": K_EMBER, "frost": K_SHARD, "venom": K_BUBBLE, "gold": K_MOTE, "void": K_WISP }

static var _rng := RandomNumberGenerator.new()
static var n := 0                 # particles alive: slots 0 to n - 1
static var _made := 0             # started this tick
static var _over := 0             # when full, the slot the next one takes
static var _k := PackedByteArray()
static var _sz := PackedByteArray()
static var _t := PackedFloat32Array()
static var _life := PackedFloat32Array()
static var _x := PackedFloat32Array()
static var _y := PackedFloat32Array()
static var _z := PackedFloat32Array()
static var _vx := PackedFloat32Array()
static var _vy := PackedFloat32Array()
static var _vz := PackedFloat32Array()
static var _a := PackedFloat32Array()     # a seed: a wobble's phase, a sliver's turn, a fork's way
static var _c := PackedColorArray()
static var cracks: Array = []             # [x, y, age, life, hot, lines (pairs of points)]
static var _scan := 0                     # the next foe looked at for its afflictions
static var _amb := 0.0

static var C_DARK := Color.html("#0c0810")
static var C_LIGHT := Color(1, 1, 1, 0.26)
static var C_HOT := Color.html("#ffb347")
static var C_STONE := [Color.html("#8b8f9c"), Color.html("#5e5c68"), Color.html("#c9c2a8")]
static var C_EMBER := [Color.html("#fff3a0"), Color.html("#f2c94c"), Color.html("#e8873a"), Color.html("#d8443c")]
static var C_ICE := Color.html("#c8f0ff")
static var C_VENOM := Color.html("#b8e05a")
static var C_STORM := Color.html("#c8f0ff")
static var C_BLOOD := Color.html("#d8443c")
static var C_WISP := Color.html("#5c3483")
static var C_GOLD := Color.html("#fffbe0")

static func reset() -> void:
	n = 0
	_made = 0
	_over = 0
	cracks.clear()

static func _alloc() -> void:
	for arr in [_k, _sz]:
		arr.resize(CAP)
	for arr in [_t, _life, _x, _y, _z, _vx, _vy, _vz, _a]:
		arr.resize(CAP)
	_c.resize(CAP)

static func _add(k: int, x: float, y: float, z: float, vx: float, vy: float, vz: float, life: float, c: Color,
		size: int = 1) -> void:
	if _made >= PER_TICK:
		return
	if _k.size() != CAP:
		_alloc()
	_made += 1
	var i := n
	if n >= CAP:
		i = _over
		_over = (_over + 1) % CAP
	else:
		n += 1
	_k[i] = k
	_sz[i] = size
	_t[i] = 0.0
	_life[i] = life
	_x[i] = x
	_y[i] = y
	_z[i] = z
	_vx[i] = vx
	_vy[i] = vy
	_vz[i] = vz
	_a[i] = _rng.randf() * TAU
	_c[i] = c

## Out from (x, y): n of kind k at about `speed`, the way `a` (spread wide: TAU, all round).
static func _spray(k: int, x: float, y: float, cnt: int, speed: float, a: float, spread: float, life: float,
		c: Color, size: int = 1, up: float = 0.0) -> void:
	for i in cnt:
		var d := a + _rng.randf_range(-spread, spread) * 0.5
		var v := speed * _rng.randf_range(0.5, 1.0)
		_add(k, x, y, 0.0 if up <= 0.0 else 2.0, cos(d) * v, sin(d) * v * 0.7, up * _rng.randf_range(0.6, 1.0),
			life * _rng.randf_range(0.7, 1.1), c, size)

## The particles of kind k for a hit, an explosion or an afflicted foe.
static func _flavour(k: int, x: float, y: float, cnt: int, c: Color, spread: float) -> void:
	for i in cnt:
		var ox := _rng.randf_range(-spread, spread)
		var oy := _rng.randf_range(-spread, spread) * 0.6
		match k:
			K_EMBER:
				_add(K_EMBER, x + ox, y + oy, 0.0, _rng.randf_range(-14.0, 14.0), _rng.randf_range(-30.0, -10.0), 0.0,
					_rng.randf_range(0.45, 0.85), C_EMBER[0], 2)
			K_SHARD:
				var a := _rng.randf() * TAU
				var v := _rng.randf_range(30.0, 70.0)
				_add(K_SHARD, x + ox, y + oy, 3.0, cos(a) * v, sin(a) * v * 0.6, _rng.randf_range(60.0, 120.0),
					_rng.randf_range(0.5, 0.8), C_ICE if i % 2 == 0 else c)
			K_BUBBLE:
				_add(K_BUBBLE, x + ox, y + oy, 0.0, 0.0, _rng.randf_range(-16.0, -8.0), 0.0, _rng.randf_range(0.5, 0.9),
					C_VENOM, 1 + (i % 2))
			K_ZAP:
				_add(K_ZAP, x + ox * 0.3, y + oy * 0.3, 0.0, 0.0, 0.0, 0.0, 0.16, C_STORM, 10 + _rng.randi_range(0, 6))
			K_DROP:
				var a := _rng.randf_range(-PI, 0.0)
				var v := _rng.randf_range(30.0, 70.0)
				_add(K_DROP, x + ox * 0.4, y + oy * 0.4, 2.0, cos(a) * v, sin(a) * v * 0.4, _rng.randf_range(50.0, 110.0),
					_rng.randf_range(0.4, 0.7), C_BLOOD)
			K_WISP:
				_add(K_WISP, x + ox, y + oy, 0.0, _rng.randf_range(-12.0, 12.0), _rng.randf_range(4.0, 14.0), 0.0,
					_rng.randf_range(0.5, 0.9), C_WISP)
			K_MOTE:
				_add(K_MOTE, x + ox, y + oy, 0.0, _rng.randf_range(-8.0, 8.0), _rng.randf_range(-22.0, -8.0), 0.0,
					_rng.randf_range(0.5, 0.9), c)
			K_CHUNK:
				var a := _rng.randf() * TAU
				var v := _rng.randf_range(25.0, 60.0)
				_add(K_CHUNK, x + ox * 0.4, y + oy * 0.4, 2.0, cos(a) * v, sin(a) * v * 0.6, _rng.randf_range(70.0, 130.0),
					_rng.randf_range(0.7, 1.1), C_STONE[i % 3], 2)

# ---------- Called by Afx, Vfx and Juice (never by the rules) ----------
## A shot lands (Afx.hit): two streaks in the weapon's colour and its family's own particles.
static func hit(x: float, y: float, tag: String) -> void:
	if not Vfx.enabled:
		return
	var cols: Array = Weapons.TAG_COLS.get(tag, Weapons.TAG_COLS["core"])
	var light := TB.c(cols[2])
	_spray(K_STREAK, x, y, 3, 170.0, _rng.randf() * TAU, TAU, 0.18, light)
	for i in 2:   # 66.6 (his Runeward pictures: debris everywhere): chips thrown off the foe, falling to the floor
		var a := _rng.randf() * TAU
		var v := _rng.randf_range(40.0, 90.0)
		_add(K_CHUNK, x, y, 1.5, cos(a) * v, sin(a) * v * 0.6 - 30.0, _rng.randf_range(90.0, 140.0),
			_rng.randf_range(0.6, 1.0), C_STONE[i % 3], 2)
	var f = FAMILY.get(tag)
	if f != null:
		_flavour(f[0], x, y, f[1], TB.c(cols[0]), 3.0)

## A blade lands (Afx.cut, `a` the way of the blow): streaks thrown along it; a blunt weapon's
## blow (a hammer, a maul, fists, a flail, a shovel) cracks the floor and kicks up stones instead.
static func cut(x: float, y: float, a: float, along: bool) -> void:
	if not Vfx.enabled:
		return
	var p := G.player
	if p != null and p.weapon != null and p.weapon.get("shape", "") in Might.BLUNT_SHAPES:
		heavy(x, y + 3.0, 0.55)
		return
	_spray(K_STREAK, x, y, 3, 190.0, a, 0.9 if along else 1.3, 0.14, Color(1, 1, 1))
	_spray(K_STREAK, x, y, 1, 120.0, a + PI, 1.2, 0.12, C_GOLD)

## A critical hit (Afx.crit): a starburst of gold and white streaks and a few specks of light.
static func crit(x: float, y: float) -> void:
	if not Vfx.enabled:
		return
	_spray(K_STREAK, x, y, 6, 210.0, 0.0, TAU, 0.18, C_GOLD)
	_flavour(K_MOTE, x, y, 2, C_GOLD, 4.0)

## Something heavy lands (Afx.dust: a guardian's slam, a charged slam, a crash; or a blunt weapon's
## blow): the floor cracks, stones fly and bounce, streaks, and a ring along the floor.
static func heavy(x: float, y: float, power: float) -> void:
	if not Vfx.enabled:
		return
	crack(x, y, 10.0 + 18.0 * power, power >= 0.9)
	for i in roundi(3 + 5 * power):
		var a := _rng.randf() * TAU
		var v := _rng.randf_range(30.0, 80.0) * (0.6 + power * 0.5)
		_add(K_CHUNK, x, y, 2.0, cos(a) * v, sin(a) * v * 0.55, _rng.randf_range(80.0, 150.0) * (0.7 + power * 0.4),
			_rng.randf_range(0.8, 1.2), C_STONE[i % 3], 2 if i % 3 else 1)
	_spray(K_STREAK, x, y - 2.0, roundi(2 + 3 * power), 170.0, 0.0, TAU, 0.14, Color(1, 1, 1))
	if power >= 0.5:
		Juice.ring(x, y, 4.0, 10.0 + 16.0 * power, 0.25, "#f4ecd8")

## An explosion (Vfx.blast) of reach r and colour ramp: debris, a crack when it is big, and its
## colour's particles thrown out (embers from fire, slivers from frost, ...).
static func blast(x: float, y: float, r: float, ramp: String) -> void:
	if not Vfx.enabled:
		return
	var big := r >= 24.0
	if big:
		crack(x, y + 2.0, minf(38.0, r * 0.8), ramp == "fire")
	for i in clampi(roundi(r / 4.0), 3, 14):
		var a := _rng.randf() * TAU
		var v := _rng.randf_range(40.0, 70.0 + r)
		_add(K_CHUNK, x, y, 2.0, cos(a) * v, sin(a) * v * 0.6, _rng.randf_range(90.0, 170.0), _rng.randf_range(0.8, 1.2),
			C_STONE[i % 3] if i % 2 == 0 else C_DARK, 2)
	var k: int = RAMP_KIND.get(ramp, K_EMBER)
	var col := TB.c(Vfx.RAMP_HEX.get(ramp, "#e8873a"))
	_flavour(k, x, y, clampi(roundi(r / 5.0), 3, 9), col, r * 0.45)

## A foe dies (Juice.kill): it bursts into bits of its own colours (GameData.SPRITE_COLOR), more
## and bigger for an elite or a guardian.
static func pop(e: Enemy, sprite: String) -> void:
	if not Vfx.enabled:
		return
	var key := sprite.trim_suffix("_elite")
	var base := TB.c(GameData.SPRITE_COLOR.get(key, "#d9d0b4"))
	var cols := [base, base.darkened(0.35), base.lightened(0.3)]
	var boss := e.is_boss()
	var cnt := 26 if boss else (12 if e.elite else 7)
	var y := e.y - e.z - 4.0
	for i in cnt:
		var a := _rng.randf() * TAU
		var v := _rng.randf_range(40.0, 115.0) * (1.4 if boss else 1.0)
		_add(K_CHUNK, e.x, y, 2.0, cos(a) * v, sin(a) * v * 0.6, _rng.randf_range(90.0, 170.0), _rng.randf_range(0.8, 1.3),
			cols[i % 3], 3 if boss and i % 3 == 0 else 2)
	_spray(K_STREAK, e.x, y, 3 if not boss else 8, 160.0, 0.0, TAU, 0.16, Color(1, 1, 1))

## A crack in the floor at (x, y), r across: jagged lines out from the middle, fading after a while;
## `hot`: it glows orange for a moment. Only on open floor (never on a wall, a pillar or a crate).
static func crack(x: float, y: float, r: float, hot: bool) -> void:
	var room := G.room
	if not Vfx.enabled or room == null or room.tile(floori(x / TB.TS), floori(y / TB.TS)) != World.T_FLOOR:
		return
	for c in cracks:
		if absf(c[0] - x) < 6.0 and absf(c[1] - y) < 5.0:
			c[2] = 0.0   # already cracked here: freshen it
			return
	var lines := PackedVector2Array()
	var rays := _rng.randi_range(4, 6)
	for i in rays:
		var a := TAU * i / rays + _rng.randf_range(-0.35, 0.35)
		var at := Vector2.ZERO
		var segs := _rng.randi_range(2, 3)
		for s in segs:
			a += _rng.randf_range(-0.55, 0.55)
			var nxt := at + Vector2(cos(a), sin(a) * 0.65) * (r / segs) * _rng.randf_range(0.6, 1.1)
			lines.append(at)
			lines.append(nxt)
			if s == 1 and _rng.randf() < 0.4:   # a twig off the side
				var b := a + (0.8 if _rng.randf() < 0.5 else -0.8)
				lines.append(nxt)
				lines.append(nxt + Vector2(cos(b), sin(b) * 0.65) * r * 0.22)
			at = nxt
	if cracks.size() >= CRACKS:
		cracks.pop_front()
	cracks.append([x, y, 0.0, 2.4, hot, lines])

# ---------- Per tick (Juice.update) ----------
static func update(dt: float) -> void:
	_made = 0
	if n > 0:
		var drag := pow(0.86, dt * 60.0)
		var w := 0
		for i in n:
			var t := _t[i] + dt
			if t >= _life[i]:
				continue
			var k := _k[i]
			var x := _x[i]
			var y := _y[i]
			var z := _z[i]
			var vx := _vx[i]
			var vy := _vy[i]
			var vz := _vz[i]
			match k:
				K_CHUNK, K_SHARD, K_DROP:
					x += vx * dt
					y += vy * dt
					if z > 0.0 or vz > 0.0:
						vz -= GRAV * dt
						z += vz * dt
						if z <= 0.0:
							z = 0.0
							if vz < -45.0 and k != K_DROP:
								vz = -vz * 0.35   # a bounce
								vx *= 0.55
								vy *= 0.55
							else:
								vz = 0.0
					else:
						vx *= 0.8
						vy *= 0.8
				K_STREAK, K_WISP:
					x += vx * dt
					y += vy * dt
					vx *= drag
					vy *= drag
				K_EMBER:
					x += (vx + sin(t * 9.0 + _a[i]) * 10.0) * dt
					y += vy * dt
					vy = maxf(vy - 30.0 * dt, -45.0)
				K_BUBBLE:
					x += sin(t * 7.0 + _a[i]) * 8.0 * dt
					y += vy * dt
				K_MOTE:
					x += vx * dt
					y += vy * dt
					vx *= 0.95
			if w != i:   # (a slot moves down only after one before it ended)
				_k[w] = k
				_sz[w] = _sz[i]
				_life[w] = _life[i]
				_a[w] = _a[i]
				_c[w] = _c[i]
			_t[w] = t
			_x[w] = x
			_y[w] = y
			_z[w] = z
			_vx[w] = vx
			_vy[w] = vy
			_vz[w] = vz
			w += 1
		n = w
		_over = mini(_over, maxi(0, n - 1))
	var j := 0
	while j < cracks.size():
		cracks[j][2] += dt
		if cracks[j][2] >= cracks[j][3]:
			cracks.remove_at(j)
		else:
			j += 1
	# Afflicted foes give off their affliction's particles: a few foes looked at a tick, in turn.
	if not Vfx.enabled or G.enemies.is_empty():
		return
	_amb -= dt
	if _amb > 0.0:
		return
	_amb = 0.08
	for tries in mini(3, G.enemies.size()):   # (each foe looked at once at most: a lone burning foe smoulders, not blazes)
		_scan = (_scan + 1) % G.enemies.size()
		var e: Enemy = G.enemies[_scan]
		if e.hp <= 0 or e.hidden or e.spawn_t > 0:
			continue
		var ex := e.x
		var ey := e.y - e.z - e.r * 0.8
		var spread := e.r * 0.8
		if e.burn_t > 0.0:
			_flavour(K_EMBER, ex, ey, 1, C_EMBER[1], spread)
		elif e.chill_t > 0.0:
			_add(K_SHARD, ex + _rng.randf_range(-spread, spread), ey, 6.0, 0.0, 0.0, 0.0, 0.5, C_ICE)
		elif e.poison > 0.0:
			_flavour(K_BUBBLE, ex, ey, 1, C_VENOM, spread)
		elif e.shock > 0:
			_flavour(K_ZAP, ex, ey, 1, C_STORM, spread)
		elif e.bleed_dps > 0.0:
			_add(K_DROP, ex + _rng.randf_range(-spread, spread), ey, 4.0, 0.0, 0.0, 0.0, 0.5, C_BLOOD)
		elif e.gloom > 0:
			_flavour(K_WISP, ex, ey, 1, C_WISP, spread)
		elif e.seared_t > 0.0:
			_flavour(K_MOTE, ex, ey, 1, C_GOLD, spread)

# ---------- Drawing (world_view) ----------
## The cracks, on the floor under everything that stands on it.
static func draw_ground(ci: CanvasItem) -> void:
	for c in cracks:
		var age: float = c[2]
		var k: float = age / c[3]
		var a := 1.0 if k < 0.7 else (1.0 - k) / 0.3
		var o := Vector2(roundf(c[0]), roundf(c[1]))
		var lines: PackedVector2Array = c[5]
		var dark := C_DARK
		dark.a = 0.95 * a
		var lit := C_LIGHT
		lit.a = C_LIGHT.a * a
		for i in range(0, lines.size(), 2):
			var w := 2.0 if lines[i] == Vector2.ZERO else 1.0   # thick where it starts, from the blow
			ci.draw_line(o + lines[i] + Vector2(0, w), o + lines[i + 1] + Vector2(0, w), lit, 1.0)
			ci.draw_line(o + lines[i], o + lines[i + 1], dark, w)
		if c[4] and age < 0.35:
			var hot := C_HOT
			hot.a = 1.0 - age / 0.35
			for i in range(0, lines.size(), 2):
				ci.draw_line(o + lines[i], o + lines[i + 1], hot, 1.0)

## The particles, over the foes (with the swings and the hit flashes).
static func draw(ci: CanvasItem) -> void:
	var shadow := Color(0, 0, 0, 0.3)
	for i in n:
		var k := _k[i]
		var f := _t[i] / _life[i]
		var x := roundf(_x[i])
		var y := roundf(_y[i])
		var c := _c[i]
		match k:
			K_CHUNK, K_DROP:
				var s := float(_sz[i])
				if _z[i] > 1.5:
					ci.draw_rect(Rect2(x - s * 0.5, y, s, 1), shadow)
				if f > 0.65:
					c.a = (1.0 - f) / 0.35
				var top := y - roundf(_z[i]) - s * 0.5
				ci.draw_rect(Rect2(x - s * 0.5, top, s, s), c)
				if s >= 2.0:
					var under := c.darkened(0.45)
					ci.draw_rect(Rect2(x - s * 0.5, top + s - 1.0, s, 1), under)
			K_STREAK:
				var col := Color(1, 1, 1).lerp(c, minf(1.0, f * 2.0))
				col.a = 1.0 - f
				ci.draw_line(Vector2(x, y), Vector2(x - _vx[i] * 0.05, y - _vy[i] * 0.05), col, 2.0 if f < 0.3 else 1.0)
			K_EMBER:
				if int(_t[i] * 30.0 + _a[i] * 3.0) % 5 == 0:
					continue   # a flicker
				var col: Color = C_EMBER[mini(3, int(f * 4.0))]
				col.a = 1.0 - f * 0.5
				var s := 2.0 if f < 0.25 and _sz[i] > 1 else 1.0
				ci.draw_rect(Rect2(x, y, s, s), col)
			K_SHARD:
				var a := _a[i] + _t[i] * 14.0
				var d := Vector2(cos(a), sin(a)) * 1.6
				var p := Vector2(x, y - roundf(_z[i]))
				if f > 0.7:
					c.a = (1.0 - f) / 0.3
				ci.draw_line(p - d, p + d, c, 1.0)
			K_BUBBLE:
				var r := 1.0 + _sz[i] * 0.5
				if f < 0.85:
					ci.draw_arc(Vector2(x, y), r, 0.0, TAU, 8, c, 1.0)
				else:   # it pops
					for q in 4:
						var a := q * PI * 0.5 + 0.785
						ci.draw_rect(Rect2(x + cos(a) * (r + 1.5), y + sin(a) * (r + 1.5), 1, 1), c)
			K_MOTE:
				c.a = 1.0 - f * 0.6
				if int(_t[i] * 20.0 + _a[i] * 3.0) % 3 == 0:
					ci.draw_rect(Rect2(x - 1, y, 3, 1), c)
					ci.draw_rect(Rect2(x, y - 1, 1, 3), c)
				else:
					ci.draw_rect(Rect2(x, y, 1, 1), c)
			K_WISP:
				var dark := c
				dark.a = 0.8 * (1.0 - f)
				ci.draw_rect(Rect2(x - 1, y - 1, 2, 2), dark)
				var core := c.lightened(0.5)
				core.a = 1.0 - f
				ci.draw_rect(Rect2(x, y, 1, 1), core)
			K_ZAP:
				# A fork of three jags out from the hit and a twig, turning a little each frame.
				var a := _a[i] + float(int(_t[i] * 40.0)) * 0.7
				var ln := float(_sz[i])
				var p := Vector2(x, y)
				var col := c
				col.a = 1.0 - f
				var core := Color(1, 1, 1, col.a)
				for s in 3:
					var j := sin(a * 3.1 + s * 2.3) * 0.9
					var q := p + Vector2(cos(a + j), sin(a + j)) * (ln / 3.0)
					ci.draw_line(p, q, col, 2.0)
					ci.draw_line(p, q, core, 1.0)
					if s == 1:
						var tw := q + Vector2(cos(a - 1.1), sin(a - 1.1)) * (ln * 0.35)
						ci.draw_line(q, tw, col, 1.0)
					p = q
