class_name Vfx
extends RefCounted
## Ability effects: lightning, explosions, fire, frost, poison, smoke and the
## marks over afflicted foes.
##
## Drawing only. Nothing here is read by the game's rules, and it has its own
## random stream, so a seeded run plays out the same with the effects on or off
## (OPTIONS > FANCY EFFECTS). The rules keep making their old particles exactly
## as before, so the game's own random numbers never move; where a new effect
## replaces them they are simply not drawn (Fx.hide).
##
## Cost is bounded: every list has a cap, the oldest entry makes room, and a
## storm of explosions falls back to small plain ones.

const ANIM_MAX := 44         # sprite animations alive at once
const BOLT_MAX := 14         # lightning bolts alive at once
const CRACKLE_MAX := 6       # of those, crackles on shocked foes
const DECAL_MAX := 10        # scorch marks
const GLOW_MAX := 16
const BLASTS_PER_TICK := 5
const FLAME_MAX := 40        # flames drawn for fire on the floor
const STATUS_MAX := 56       # sprites drawn over afflicted foes
const FALL_TICKS := 6        # a meteor's fall

## Frames in each strip (a strip is one row of equal frames).
const FRAMES := { "fx_blast_s": 8, "fx_blast_m": 9, "fx_blast_l": 10, "fx_flame": 8, "fx_flame_s": 8,
	"fx_smoke": 6, "fx_zap": 5, "fx_shatter": 7, "fx_bubble": 4, "fx_star": 2, "fx_frost": 2,
	# Attack effects (Afx).
	"fx_hit": 4, "fx_crit": 5, "fx_cut": 4, "fx_muzzle": 3, "fx_cast": 4, "fx_dust": 5, "fx_flare": 4,
	"swing_slash": 4, "swing_slash_edge": 4, "swing_thrust": 3, "swing_whip": 3 }
## Explosion colour (as the rules pass it) -> heat ramp of the picture.
const RAMP := { "": "fire", "#e8873a": "fire", "#d8443c": "fire", "#b8e05a": "venom", "#63b84f": "venom",
	"#f2c94c": "gold", "#6fd3e0": "frost", "#c8f0ff": "frost", "#4d9be6": "frost",
	"#a35bd6": "void", "#5c3483": "void", "#7a3a8c": "void", "#e86fb4": "void" }
const RAMP_HEX := { "fire": "#e8873a", "venom": "#b8e05a", "gold": "#f2c94c", "frost": "#6fd3e0", "void": "#a35bd6" }
const HAS_LARGE := ["fire", "venom", "gold"]
## Where the flames of a fire stand, back to front, as fractions of its radius.
const FLAME_SPOTS := [
	[Vector2(0, 0.15)],
	[Vector2(-0.35, -0.1), Vector2(0.3, 0.25)],
	[Vector2(0.05, -0.3), Vector2(-0.45, 0.1), Vector2(0.4, 0.3)],
	[Vector2(-0.3, -0.3), Vector2(0.35, -0.15), Vector2(-0.5, 0.2), Vector2(0.15, 0.4)],
	[Vector2(0, -0.4), Vector2(-0.55, -0.1), Vector2(0.5, -0.05), Vector2(-0.25, 0.3), Vector2(0.3, 0.42)],
]
## Last tick of each kind of bolt: a strike from the sky, an arc, a crackle.
const BOLT_LIFE := [18, 10, 4]

## One sprite animation: a strip played once.
class Anim:
	var tex: Texture2D
	var x := 0.0
	var y := 0.0
	var vx := 0.0
	var vy := 0.0
	var w := 1
	var h := 1
	var n := 1
	var t := 0.0          # seconds played (below zero: still waiting)
	var dur := 0.3
	var col := Color.WHITE
	var fade := false

## One lightning bolt.
class Bolt:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var kind := 0         # 0 strike from the sky, 1 arc between two points, 2 crackle on a shocked foe
	var age := 0          # ticks (below one: still waiting)
	var amp := 3.0        # how far the channel wanders
	var col := Color.WHITE
	var main := PackedVector2Array()    # the channel, as one line strip
	var twigs := PackedVector2Array()   # the forks, as point pairs
	var dash := PackedVector2Array()    # every other piece of the channel: the last flicker

static var enabled := true
## Set by the caller for the very next blast only (both are visual).
static var next_col := ""
static var next_delay := 0.0

static var _rng := RandomNumberGenerator.new()
static var anims: Array[Anim] = []
static var bolts: Array[Bolt] = []
static var decals: Array = []    # [x, y, scale, age, life], in ticks
static var glows: Array = []     # [x, y, radius, age, life, Color]
static var swirls: Array = []    # [x, y, radius, age, life, inward, Color]
static var falls: Array = []     # [x0, y0, x1, y1, age]: meteors
static var _later: Array = []    # [ticks, x, y, count, speed, Color]: sparks waiting for a delayed blast
static var _tick_blasts := 0
static var _tick := 0
static var _strips := {}

static var C_WHITE := Color(1, 1, 1)
static var C_CYAN := Color.html("#6fd3e0")
static var C_ICE := Color.html("#c8f0ff")
static var C_ORANGE := Color.html("#e8873a")
static var C_YELLOW := Color.html("#f2c94c")
static var C_CREAM := Color.html("#fffbe0")
static var C_PINK := Color.html("#ff8a8a")
static var C_ROSE := Color.html("#e86a8e")

static func reset() -> void:
	enabled = bool(Meta.opts.get("vfx", true))
	anims.clear()
	bolts.clear()
	decals.clear()
	glows.clear()
	swirls.clear()
	falls.clear()
	_later.clear()
	next_col = ""
	next_delay = 0.0
	_tick_blasts = 0
	Afx.reset()
	Bits.reset()   # 60.1
	# The shots' look follows the same switch: live shots are sorted again under the other rules.
	if ShotBatch.fancy != enabled:
		ShotBatch.fancy = enabled
		ShotBatch.reset_table()
		for b: PBullet in G.pbullets:
			b.dk = -1

## A strip by name: [texture, frame width, frame height, frames].
static func _strip(name: String) -> Array:
	var s: Array = _strips.get(name, [])
	if s.is_empty():
		var tex := Img.t(name)
		var n: int = FRAMES.get(name, FRAMES.get(name.substr(0, name.rfind("_")), 1))
		s = [tex, tex.get_width() / n, tex.get_height(), n]
		_strips[name] = s
	return s

static func _play(name: String, x: float, y: float, dur: float, delay: float = 0.0) -> Anim:
	var s := _strip(name)
	var a := Anim.new()
	a.tex = s[0]
	a.w = s[1]
	a.h = s[2]
	a.n = s[3]
	a.x = x
	a.y = y
	a.dur = dur
	a.t = -delay
	if anims.size() >= ANIM_MAX:
		anims.remove_at(0)
	anims.append(a)
	return a

static func _glow(x: float, y: float, r: float, life: int, col: Color, delay: int = 0) -> void:
	if glows.size() >= GLOW_MAX:
		glows.pop_front()
	glows.append([x, y, r, -delay, life, col])

## Sparks that fly out and fall. With a delay they wait for their blast.
static func _sparks(x: float, y: float, n: int, speed: float, col: Color, delay: int = 0) -> void:
	if delay > 0:
		if _later.size() < 16:
			_later.append([delay, x, y, n, speed, col])
		return
	for i in n:
		var a := _rng.randf() * TAU
		var v := speed * (0.45 + _rng.randf() * 0.55)
		Juice.spark(x, y, cos(a) * v, sin(a) * v * 0.8 - 30.0, 190.0, 0.3 + _rng.randf() * 0.3, col)

## A burnt patch on the floor (never on walls, pillars or crates).
static func _scorch(x: float, y: float, sc: float, delay: int = 0) -> void:
	var room := G.room
	if room == null or room.tile(floori(x / TB.TS), floori(y / TB.TS)) != World.T_FLOOR:
		return
	for d in decals:
		if absf(d[0] - x) < 9.0 and absf(d[1] - y) < 6.0:
			# Already burnt here: freshen the mark instead of stacking another.
			d[3] = mini(d[3], 0)
			d[2] = maxf(d[2], sc)
			return
	if decals.size() >= DECAL_MAX:
		decals.pop_front()
	decals.append([x, y, sc, -delay, 300])

# ---------- Explosions ----------
## An explosion of the given reach: a white flash, a fireball that cools to
## smoke, sparks, a shock ring and a scorch mark. Big ones go off as a cluster.
static func blast(x: float, y: float, r: float, col: String = "") -> void:
	if not enabled:
		return
	var ramp: String = RAMP.get(next_col if next_col != "" else col, "fire")
	var delay := next_delay
	next_col = ""
	next_delay = 0.0
	_tick_blasts += 1
	if _tick_blasts > BLASTS_PER_TICK:
		return
	var busy := anims.size()
	var tier := 0 if r < 20.0 else (1 if r < 32.0 else (2 if r < 52.0 else 3))
	if busy > 34:
		tier = 0
	elif busy > 22:
		tier = mini(tier, 1)
	var dticks := roundi(delay / TB.DT)
	if delay <= 0.0:
		Bits.blast(x, y - 2.0, r, ramp)   # 60.1: debris, a crack, the colour's particles
	var glow_col: Color = TB.c(RAMP_HEX[ramp])
	var large := tier >= 2 and ramp in HAS_LARGE
	var size := "s" if tier == 0 else ("l" if large else "m")
	var p := G.player
	var eye := tier >= 2 and p != null and absf(p.x - x) < 12.0 and absf(p.y - y) < 12.0
	if not eye:
		_play("fx_blast_%s_%s" % [size, ramp], x, y - 2.0, [0.24, 0.3, 0.38, 0.4][tier], delay)
	_glow(x, y - 2.0, r * 1.5 + 12.0, 9 + tier * 2, glow_col, dticks)
	if tier == 0:
		return
	_sparks(x, y - 2.0, 3 + tier * 2, 90.0 + r, glow_col, dticks)
	if r >= 24.0:
		_scorch(x, y + 2.0, 1.0 if tier == 1 else 2.0, dticks)
	if tier == 1:
		return
	if delay <= 0.0:
		Juice.ring(x, y, r * 0.3, r * 1.05, 0.22, "#fffbe0")
	# Smoke that hangs for a moment and drifts up.
	for k in tier:
		var s := _play("fx_smoke", x + _rng.randf_range(-0.35, 0.35) * r, y - 5.0 + _rng.randf_range(-0.3, 0.2) * r,
			0.5, delay + 0.13 + 0.05 * k)
		s.vy = -12.0
		s.col = Color(1, 1, 1, 0.85)
	if tier == 3 or eye:
		# The biggest go off as a cluster: smaller blasts around the first, a beat apart.
		# One centred on the hero is only the ring, so the hero stays in view in its eye.
		var n := (5 if tier == 2 else 7) if eye else (4 if r < 60.0 else 6)
		var out := maxf(31.0, r * 0.62) if eye else r * 0.55
		var a0 := _rng.randf() * TAU
		for k in n:
			var a := a0 + k * TAU / n
			_play("fx_blast_m_" + ramp, x + cos(a) * out, y - 2.0 + sin(a) * out * 0.8, 0.3,
				delay + (0.0 if eye else 0.035) + 0.018 * k)

## A small themed pop (a foe freshly frozen, hexed, ...).
static func puff(x: float, y: float, ramp: String) -> void:
	if not enabled or anims.size() > ANIM_MAX / 2:
		return
	_tick_blasts += 1
	if _tick_blasts > BLASTS_PER_TICK:
		return
	_play("fx_blast_s_" + ramp, x, y - 2.0, 0.22)

## A ring of small pops around a point, with a shock ring (frost skin, ice armour).
static func nova(x: float, y: float, r: float, ramp: String) -> void:
	if not enabled:
		return
	_glow(x, y, r * 0.8, 10, TB.c(RAMP_HEX[ramp]))
	Juice.ring(x, y, 6.0, r, 0.3, RAMP_HEX[ramp])
	if anims.size() > ANIM_MAX / 2:
		return
	var a0 := _rng.randf() * TAU
	for k in 8:
		var a := a0 + k * TAU / 8.0
		_play("fx_blast_s_" + ramp, x + cos(a) * 26.0, y - 2.0 + sin(a) * 21.0, 0.24, 0.012 * k)

## A meteor: a rock streaks down from the upper right; the blast waits for it.
static func meteor(x: float, y: float) -> void:
	if not enabled:
		return
	if falls.size() < 6:
		falls.append([x + 56.0, y - 132.0, x, y, 0])
	next_delay = (FALL_TICKS - 0.5) * TB.DT   # the blast shows on the tick the rock lands

## Ice breaking apart.
static func shatter(x: float, y: float) -> void:
	if not enabled:
		return
	_play("fx_shatter", x, y - 2.0, 0.3)
	_glow(x, y - 2.0, 30.0, 9, C_CYAN)

## Health coming back: little crosses float up.
static func heal(x: float, y: float) -> void:
	if not enabled:
		return
	_glow(x, y - 4.0, 26.0, 14, C_ROSE)
	for k in 5:
		var a := _play("fx_plus", x + (k - 2.0) * 6.0 + _rng.randf_range(-1.5, 1.5), y - 5.0 - _rng.randf_range(0.0, 7.0),
			0.6, k * 0.06)
		a.vy = -32.0
		a.fade = true
		a.col = C_PINK if k % 2 == 0 else C_CREAM

## A pull (inward) or a push (outward): motes that spiral.
static func swirl(x: float, y: float, r: float, inward: bool, col: String) -> void:
	if not enabled:
		return
	if swirls.size() >= 6:
		swirls.pop_front()
	swirls.append([x, y, r, 0, 22, inward, TB.c(col)])

# ---------- Lightning ----------
## A bolt from the sky onto a point: a leader races down, the return stroke
## flashes with its forks, it strikes a second time along a fresh path, and the
## channel breaks up as it fades.
static func strike(x: float, y: float) -> void:
	if not enabled:
		return
	var b := Bolt.new()
	b.kind = 0
	b.b = Vector2(x, y + 2.0)
	b.a = Vector2(x + _rng.randf_range(-34.0, 34.0), maxf(-10.0, y - _rng.randf_range(150.0, 190.0)))
	b.amp = 4.4
	b.col = C_CYAN
	_add_bolt(b)
	# The stroke lands on the third tick, after the leader has run down.
	_play("fx_zap", x, y + 1.0, 0.2, 2.5 * TB.DT)
	_glow(x, y - 3.0, 36.0, 10, C_CYAN, 3)
	_sparks(x, y, 6, 110.0, C_ICE, 3)
	_scorch(x, y + 2.0, 1.0, 3)

## Lightning jumping from one point to another.
static func arc(x0: float, y0: float, x1: float, y1: float, delay: int = 0) -> void:
	if not enabled:
		return
	var b := Bolt.new()
	b.kind = 1
	b.a = Vector2(x0, y0)
	b.b = Vector2(x1, y1)
	b.amp = clampf(b.a.distance_to(b.b) * 0.04, 1.5, 3.5)
	b.col = C_CYAN
	b.age = -delay
	_add_bolt(b)
	_glow(x1, y1, 18.0, 7, C_CYAN, delay + 2)
	_sparks(x1, y1, 2, 70.0, C_ICE, delay + 2)

static func _add_bolt(b: Bolt) -> void:
	if bolts.size() >= BOLT_MAX:
		bolts.remove_at(0)
	bolts.append(b)

## A wandering channel from a to b. It is a random walk pinned at both ends, so
## it leans one way for a while and kinks sharply, the way a real one does.
static func _channel(a: Vector2, b: Vector2, amp: float, seg: float) -> PackedVector2Array:
	var d := b - a
	var ln := maxf(d.length(), 0.001)
	var n := clampi(int(ln / seg), 2, 30)
	var nrm := Vector2(-d.y, d.x) / ln
	var walk := PackedFloat32Array()
	walk.resize(n + 1)
	var w := 0.0
	for i in range(1, n + 1):
		w += _rng.randf_range(-1.0, 1.0)
		walk[i] = w
	var out := PackedVector2Array()
	out.resize(n + 1)
	for i in n + 1:
		var k := float(i) / n
		var p := a + d * k
		if i > 0 and i < n:
			p += nrm * ((walk[i] - w * k) * amp) + d * (_rng.randf_range(-0.3, 0.3) / n)
		out[i] = Vector2(floorf(p.x) + 0.5, floorf(p.y) + 0.5)
	return out

## Draws (or redraws, for the second stroke) a bolt's channel and forks.
static func _forge(b: Bolt, first: bool) -> void:
	b.main = _channel(b.a, b.b, b.amp if first else b.amp * 0.75, 6.0 if b.kind == 0 else 5.0)
	var n := b.main.size()
	if first:
		b.twigs = PackedVector2Array()
		var forks := 0
		if b.kind == 0:
			forks = 2 + _rng.randi() % 2
		elif b.kind == 1 and n > 6:
			forks = _rng.randi() % 2
		var total := b.a.distance_to(b.b)
		for f in forks:
			var i := clampi(int(n * _rng.randf_range(0.2, 0.72)), 1, n - 2)
			var dir := (b.main[i + 1] - b.main[i - 1]).normalized()
			var turn := _rng.randf_range(0.45, 1.0) * (1.0 if _rng.randf() < 0.5 else -1.0)
			_twig(b, b.main[i], dir.rotated(turn), clampf(total * _rng.randf_range(0.18, 0.4), 8.0, 50.0), 1)
	b.dash = PackedVector2Array()
	var j := 0
	while j + 1 < n:
		b.dash.append(b.main[j])
		b.dash.append(b.main[j + 1])
		j += 2

static func _twig(b: Bolt, from: Vector2, dir: Vector2, ln: float, depth: int) -> void:
	var path := _channel(from, from + dir * ln, b.amp * 0.55, 5.0)
	for i in path.size() - 1:
		b.twigs.append(path[i])
		b.twigs.append(path[i + 1])
	if depth < 2 and path.size() > 3 and _rng.randf() < 0.45:
		var mid := path[path.size() / 2]
		_twig(b, mid, dir.rotated(_rng.randf_range(0.4, 0.8) * (1.0 if _rng.randf() < 0.5 else -1.0)), ln * 0.55, depth + 1)

## A short crackle around a shocked foe.
static func _crackle(x: float, y: float, r: float) -> void:
	var b := Bolt.new()
	b.kind = 2
	var a1 := _rng.randf() * TAU
	var a2 := a1 + _rng.randf_range(1.3, 2.7)
	b.a = Vector2(x + cos(a1) * (r + 2.0), y + sin(a1) * (r + 2.0))
	b.b = Vector2(x + cos(a2) * (r + 2.0), y + sin(a2) * (r + 2.0))
	b.amp = 1.6
	b.col = C_CYAN
	_add_bolt(b)

# ---------- Per logic tick (called from Juice.update) ----------
static func update(dt: float) -> void:
	_tick_blasts = 0
	next_col = ""
	next_delay = 0.0
	_tick += 1
	var i := 0
	while i < anims.size():
		var a := anims[i]
		a.t += dt
		if a.t >= a.dur:
			anims.remove_at(i)
			continue
		if a.t > 0.0:
			a.x += a.vx * dt
			a.y += a.vy * dt
		i += 1
	i = 0
	while i < bolts.size():
		var b := bolts[i]
		b.age += 1
		if b.age == 1:
			_forge(b, true)
		elif (b.kind == 0 and b.age == 8) or (b.kind == 1 and b.age == 5):
			_forge(b, false)   # the second stroke takes a slightly different path
		if b.age > BOLT_LIFE[b.kind]:
			bolts.remove_at(i)
		else:
			i += 1
	for l in [decals, glows, swirls]:
		i = 0
		while i < l.size():
			l[i][3] += 1
			if l[i][3] >= l[i][4]:
				l.remove_at(i)
			else:
				i += 1
	i = 0
	while i < falls.size():
		falls[i][4] += 1
		if falls[i][4] > FALL_TICKS + 5:
			falls.remove_at(i)
		else:
			i += 1
	i = 0
	while i < _later.size():
		var s: Array = _later[i]
		s[0] -= 1
		if s[0] <= 0:
			_sparks(s[1], s[2], s[3], s[4], s[5])
			_later.remove_at(i)
		else:
			i += 1
	if not enabled:
		return
	# Shocked foes crackle; fires on the floor throw embers.
	if (_tick & 1) == 0:
		# Crackles have their own small share of the bolts, so they never push out a strike.
		var live := 0
		for b in bolts:
			if b.kind == 2:
				live += 1
		for e: Enemy in G.enemies:
			if live >= CRACKLE_MAX:
				break
			if e.shock_t > 0.0 and e.hp > 0 and not e.hidden and e.spawn_t <= 0.0 and _rng.randf() < 0.25 + 0.1 * e.shock:
				_crackle(e.x, e.y - e.z, e.r)
				live += 1
	if (_tick & 3) == 0:
		var seen := 0
		for z in G.zones:
			if z["kind"] != "fire":
				continue
			seen += 1
			if seen > 12:
				break
			if _rng.randf() < 0.5:
				var r: float = z["r"]
				Juice.spark(z["x"] + _rng.randf_range(-0.7, 0.7) * r, z["y"] + _rng.randf_range(-0.4, 0.3) * r,
					_rng.randf_range(-8.0, 8.0), -_rng.randf_range(25.0, 50.0), -30.0, 0.45,
					C_ORANGE if _rng.randf() < 0.5 else C_YELLOW)

# ---------- Drawing ----------
static func _h(n: int) -> float:
	var x := (n * 374761393 + 668265263) & 0x7fffffff
	x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff
	return float(x & 0xffff) / 65536.0

static func _put(ci: CanvasItem, s: Array, f: int, x: float, y: float, col: Color = Color.WHITE) -> void:
	var w: int = s[1]
	var h: int = s[2]
	ci.draw_texture_rect_region(s[0], Rect2(roundf(x), roundf(y), w, h), Rect2(f * w, 0, w, h), col)

## On the floor, under the shadows: scorch marks, burnt ground, poison pools.
static func draw_floor(ci: CanvasItem, t: float) -> void:
	var scorch := _strip("fx_scorch")
	var stex: Texture2D = scorch[0]
	for d in decals:
		var age: int = d[3]
		if age < 0:
			continue
		var sc: float = d[2]
		var life: int = d[4]
		ci.draw_texture_rect(stex, Rect2(roundf(d[0] - 13.0 * sc), roundf(d[1] - 6.5 * sc), 26.0 * sc, 13.0 * sc), false,
			Color(1, 1, 1, 0.8 * clampf((life - age) / 90.0, 0.0, 1.0)))
	if G.zones.is_empty():
		return
	var pool: Texture2D = _strip("fx_pool")[0]
	var bub := _strip("fx_bubble")
	for z in G.zones:
		var kind: String = z["kind"]
		if kind != "fire" and kind != "poison" and kind != "ink":
			continue
		var r: float = z["r"]
		var zx: float = z["x"]
		var zy: float = z["y"]
		var a := clampf(z["t"] / 0.4, 0.0, 1.0)
		if kind == "fire":
			ci.draw_texture_rect(stex, Rect2(roundf(zx - r), roundf(zy - r * 0.45), r * 2.0, r), false, Color(1, 1, 1, 0.75 * a))
			continue
		var zs := int(zx * 7.0 + zy * 13.0)
		var grow := 1.0 + 0.04 * sin(t * 3.0 + zs)
		var tint := Color(0.22, 0.26, 0.6, 0.95 * a) if kind == "ink" else Color(1, 1, 1, 0.9 * a)   # 18.2 ink
		ci.draw_texture_rect(pool, Rect2(roundf(zx - r * 1.05 * grow), roundf(zy - r * 0.6 * grow + 1.0),
			roundf(r * 2.1 * grow), roundf(r * 1.2 * grow)), false, tint)
		for j in 2:
			var cyc := t * 1.6 + j * 0.5 + (zs % 10) * 0.1
			var id := int(cyc)
			var ph := cyc - id
			_put(ci, bub, int(ph * 4.0), zx + (_h(zs + id * 31 + j * 7) - 0.5) * r * 1.3 - 3.0,
				zy + (_h(zs * 3 + id * 17 + j) - 0.5) * r * 0.6 - ph * 4.0 - 3.0, Color(1, 1, 1, a))

## On the floor, over the shadows: the flames of fire zones.
static func draw_ground(ci: CanvasItem, t: float) -> void:
	if G.zones.is_empty():
		return
	var left := FLAME_MAX
	var ft := int(t * 14.0)
	var big := _strip("fx_flame")
	var small := _strip("fx_flame_s")
	var bw: int = big[1]
	var bh: int = big[2]
	var sw: int = small[1]
	var sh: int = small[2]
	for z in G.zones:
		if z["kind"] != "fire":
			continue
		if left <= 0:
			break
		var r: float = z["r"]
		var zx: float = z["x"]
		var zy: float = z["y"]
		var life: float = z["t"]
		var n := mini(clampi(int(r / 7.0), 1, 5), left)
		left -= n
		var zs := absi(int(zx * 7.0 + zy * 13.0))
		var spots: Array = FLAME_SPOTS[n - 1]
		var c := Color(1, 1, 1, clampf(life / 0.25, 0.0, 1.0))
		for k in n:
			var o: Vector2 = spots[k]
			var fx := zx + o.x * r
			var fy := zy + o.y * r * 0.7
			var f := (ft + k * 3 + zs) % 8
			if r >= 9.0 and (k + zs) % 2 == 0 and life > 0.35:
				ci.draw_texture_rect_region(big[0], Rect2(roundf(fx - bw * 0.5), roundf(fy - bh + 3.0), bw, bh), Rect2(f * bw, 0, bw, bh), c)
			else:
				ci.draw_texture_rect_region(small[0], Rect2(roundf(fx - sw * 0.5), roundf(fy - sh + 2.0), sw, sh), Rect2(f * sw, 0, sw, sh), c)

## Over the fighters, under every shot: marks on afflicted foes, smoke, the
## animations, then the line work (swirls, meteors, lightning).
static func draw_over(ci: CanvasItem, t: float) -> void:
	_draw_status(ci, t)
	if not G.zones.is_empty():
		_draw_smoke(ci, t)
	for m in falls:
		_draw_fall(ci, m)
	# A fireball that lands on the hero is drawn see-through, so the hero is never lost in it.
	var hero := G.player
	var hx := hero.x if hero != null else -999.0
	var hy := hero.y - 6.0 - hero.air if hero != null else -999.0
	for a in anims:
		if a.t < 0.0:
			continue
		var f := mini(a.n - 1, int(a.t / a.dur * a.n))
		var c := a.col
		if a.fade:
			var k := a.t / a.dur
			c.a *= 1.0 - k * k
		elif a.w >= 24 and absf(a.x - hx) < a.w * 0.42 and absf(a.y - hy) < a.h * 0.42:
			c.a *= 0.5
		ci.draw_texture_rect_region(a.tex, Rect2(roundf(a.x - a.w * 0.5), roundf(a.y - a.h * 0.5), a.w, a.h),
			Rect2(f * a.w, 0, a.w, a.h), c)
	for s in swirls:
		var k: float = float(s[3]) / s[4]
		var inward: bool = s[5]
		var c: Color = s[6]
		var rad: float = s[2] * ((1.0 - k) if inward else k)
		var sgn := 1.0 if inward else -1.0
		var spin := k * 5.0 * sgn
		for j in 12:
			var a := j * TAU / 12.0 + spin
			ci.draw_rect(Rect2(roundf(s[0] + cos(a) * rad) - 1.0, roundf(s[1] + sin(a) * rad * 0.8) - 1.0, 3, 3),
				Color(c.r, c.g, c.b, 1.0 - 0.4 * k))
			# A tail of three behind each mote, where it has just been.
			for q in range(1, 4):
				var r2 := rad + 5.0 * q * sgn
				if r2 <= 0.0:
					break
				var a2 := a - 0.2 * q * sgn
				ci.draw_rect(Rect2(roundf(s[0] + cos(a2) * r2), roundf(s[1] + sin(a2) * r2 * 0.8), 2 if q == 1 else 1, 2 if q == 1 else 1),
					Color(c.r, c.g, c.b, (0.8 - 0.2 * q) * (1.0 - k * 0.6)))
	_draw_bolts(ci)

static func _draw_fall(ci: CanvasItem, m: Array) -> void:
	var age: int = m[4]
	var a := Vector2(m[0], m[1])
	var b := Vector2(m[2], m[3])
	var dir := (b - a).normalized()
	if age <= FALL_TICKS:
		var pos := a.lerp(b, float(age) / FALL_TICKS)
		ci.draw_line(pos - dir * 46.0, pos, C_ORANGE, 5.0)
		ci.draw_line(pos - dir * 30.0, pos, C_YELLOW, 3.0)
		ci.draw_line(pos - dir * 16.0, pos, C_CREAM, 1.0)
		ci.draw_texture(Img.t("fx_rock"), Vector2(roundf(pos.x - 6.0), roundf(pos.y - 6.0)))
	else:
		# Landed: what is left of the trail runs into the blast.
		var k := float(age - FALL_TICKS) / 5.0
		ci.draw_line(b - dir * 56.0 * (1.0 - k), b, Color(C_ORANGE.r, C_ORANGE.g, C_ORANGE.b, 0.8 * (1.0 - k)), 3.0)

static func _draw_bolts(ci: CanvasItem) -> void:
	for b in bolts:
		var age := b.age
		var m := b.main
		if age <= 0 or m.size() < 2:
			continue
		var c := b.col
		if b.kind == 0:
			if age <= 2:
				# The leader: a thin line racing down.
				ci.draw_polyline(m.slice(0, maxi(2, int(m.size() * (0.4 if age == 1 else 0.75)))), C_WHITE, -1.0)
			elif age <= 6 or (age >= 8 and age <= 11):
				# A stroke: white core, coloured edge; the forks only light on the first.
				ci.draw_polyline(m, c, 3.0)
				ci.draw_polyline(m, C_WHITE, -1.0)
				if age <= 6 and b.twigs.size() >= 2:
					ci.draw_multiline(b.twigs, C_ICE, -1.0)
			elif age == 7:
				ci.draw_polyline(m, Color(c.r, c.g, c.b, 0.55), -1.0)   # dark for a moment between strokes
			elif age >= 16:
				ci.draw_multiline(b.dash, Color(c.r, c.g, c.b, 1.0 - (age - 11) / 8.0), -1.0)
			else:
				ci.draw_polyline(m, Color(c.r, c.g, c.b, 1.0 - (age - 11) / 8.0), -1.0)
		elif b.kind == 1:
			if age == 1:
				ci.draw_polyline(m.slice(0, maxi(2, int(m.size() * 0.55))), C_WHITE, -1.0)
			elif age <= 7:
				ci.draw_polyline(m, c, 3.0)
				ci.draw_polyline(m, C_WHITE, -1.0)
				if age <= 4 and b.twigs.size() >= 2:
					ci.draw_multiline(b.twigs, C_ICE, -1.0)
			elif age == 10:
				ci.draw_multiline(b.dash, Color(c.r, c.g, c.b, 0.5), -1.0)
			else:
				ci.draw_polyline(m, Color(c.r, c.g, c.b, 0.85), -1.0)
		else:
			ci.draw_polyline(m, C_WHITE if age <= 2 else Color(c.r, c.g, c.b, 0.7), -1.0)

static func _draw_smoke(ci: CanvasItem, t: float) -> void:
	var smoke := _strip("fx_smoke")
	for z in G.zones:
		if z["kind"] != "smoke":
			continue
		var r: float = z["r"]
		var zx: float = z["x"]
		var zy: float = z["y"]
		var c := Color(1, 1, 1, 0.5 * clampf(z["t"], 0.0, 1.0))
		var zs := absi(int(zx * 7.0 + zy * 13.0))
		var n := clampi(int(r / 5.0), 3, 8)
		for k in n:
			var inner := k < 3
			var ang := t * (0.7 if inner else -0.45) + k * 2.1 + zs
			var ring := 0.28 if inner else 0.7
			_put(ci, smoke, 1 + (int(t * 3.0) + k) % 3, zx + cos(ang) * r * ring - 8.0, zy + sin(ang) * r * ring * 0.6 - 11.0, c)

## Flames on burning foes, bubbles on poisoned ones, frost on chilled ones,
## stars over stunned ones, and a small icon for a curse, a mark or weakness.
static func _draw_status(ci: CanvasItem, t: float) -> void:
	var left := STATUS_MAX
	var ft := int(t * 14.0)
	var flame := _strip("fx_flame_s")
	var flame_b := _strip("fx_flame")
	var bub := _strip("fx_bubble")
	var star := _strip("fx_star")
	var frost := _strip("fx_frost")
	for e: Enemy in G.enemies:
		if left <= 0:
			break
		var burn := e.burn_t > 0.0
		var poison := e.poison > 0.0
		var chill := e.chill_t > 0.0
		var stun := e.stun_t > 0.0
		var icons := (1 if e.curse_t > 0.0 else 0) + (1 if e.weak_t > 0.0 else 0) + (1 if e.mark_t > 0.0 else 0)
		if not (burn or poison or chill or stun or icons > 0):
			continue
		if e.hp <= 0 or e.hidden or e.spawn_t > 0.0:
			continue
		var ex := e.x
		var ey := e.y - e.z
		var r := e.r
		var uid := e.uid
		if burn:
			var cnt := 1 if r < 5.5 else (2 if r < 10.0 else 3)
			var s := flame_b if r >= 10.0 else flame
			var w: int = s[1]
			var h: int = s[2]
			for k in cnt:
				var ox := (k - (cnt - 1) * 0.5) * r * 0.9
				var oy := r * 0.4 if (k + uid) % 2 == 0 else -r * 0.3
				_put(ci, s, (ft + k * 3 + uid) % 8, ex + ox - w * 0.5, ey + oy - h + 1.0)
			left -= cnt
		if poison:
			var cnt := 2 if e.poison >= 6.0 else 1
			for j in cnt:
				var cyc := t * 1.4 + (uid % 7) * 0.31 + j * 0.5
				var id := int(cyc)
				var ph := cyc - id
				_put(ci, bub, int(ph * 4.0), ex + (_h(uid * 11 + id * 5 + j) - 0.5) * r * 1.6 - 3.0, ey - r * 0.3 - ph * 9.0 - 3.0)
			left -= cnt
		if chill:
			_put(ci, frost, (int(t * 4.0) + uid) % 2, ex + r * 0.6 - 3.0, ey - r - 4.0)
			left -= 1
			if r >= 8.0:
				_put(ci, frost, (int(t * 4.0) + uid + 1) % 2, ex - r * 0.8 - 3.0, ey + r * 0.2 - 3.0)
				left -= 1
		if stun:
			for k in 3:
				var a := t * 7.0 + k * TAU / 3.0 + uid
				var sy := sin(a)
				_put(ci, star, 0 if sy > 0.0 else 1, ex + cos(a) * (r * 0.7 + 3.0) - 2.0, ey - r - 7.0 + sy * 2.0 - 2.0)
			left -= 3
		if icons > 0:
			var x0 := ex - (icons * 8 - 1) * 0.5
			var y0 := ey - r - 20.0 + sin(t * 5.0 + uid) * 1.0
			var k := 0
			if e.curse_t > 0.0:
				if e.curse_t > 0.6 or int(t * 12.0) % 2 == 0:
					ci.draw_texture(Img.t("fx_skull"), Vector2(roundf(x0 + k * 8), roundf(y0)))
				k += 1
			if e.weak_t > 0.0:
				if e.weak_t > 0.6 or int(t * 12.0) % 2 == 0:
					ci.draw_texture(Img.t("fx_weak"), Vector2(roundf(x0 + k * 8), roundf(y0)))
				k += 1
			if e.mark_t > 0.0:
				if e.mark_t > 0.6 or int(t * 12.0) % 2 == 0:
					ci.draw_texture(Img.t("fx_mark"), Vector2(roundf(x0 + k * 8), roundf(y0)))
			left -= icons

## The additive layer: flashes of light, and a soft band along live lightning.
static func draw_glow(ci: CanvasItem) -> void:
	if not glows.is_empty():
		var tex := Img.t("glow_white")
		for g in glows:
			var age: int = g[3]
			if age < 0:
				continue
			var k: float = 1.0 - float(age) / float(g[4])
			var r: float = g[2]
			var c: Color = g[5]
			ci.draw_texture_rect(tex, Rect2(roundf(g[0] - r), roundf(g[1] - r), r * 2.0, r * 2.0), false,
				Color(c.r, c.g, c.b, k * 0.85))
	for b in bolts:
		var age := b.age
		if b.main.size() < 2:
			continue
		var c := b.col
		if b.kind == 0 and ((age >= 3 and age <= 6) or (age >= 8 and age <= 11)):
			ci.draw_polyline(b.main, Color(c.r, c.g, c.b, 0.22), 7.0)
		elif b.kind == 1 and age >= 2 and age <= 7:
			ci.draw_polyline(b.main, Color(c.r, c.g, c.b, 0.18), 5.0)
