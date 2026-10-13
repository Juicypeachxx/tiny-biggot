class_name EBullets
extends RefCounted
## Enemy bullets (port of Combat.rb update_ebullets and the `eshot` Hashes).
##
## This is where the original lagged: every enemy shot was a Ruby Hash plus
## an RGSS Sprite, and the array was rebuilt with reject! each frame. Here
## bullets are a struct of parallel packed arrays with a fixed capacity:
##   * spawning writes into the next free slot (no allocation),
##   * removal marks the slot dead, and one in-place compaction per tick
##     keeps the arrays dense,
##   * drawing is grouped by sprite so Godot's batcher merges each group
##     into one draw call.

const CAP := 2048
const KILLED := -1000.0   # life value of a bullet removed mid-tick (Ruby reject!)

## Sprite names (Img "orb_<name>") indexed by bullet sprite id.
const SPRITES := ["red", "redBig", "bone", "water", "ice", "iceBig", "spore", "dark", "darkBig", "fire", "fireBig", "cyan", "page"]
static var _spr_index := {}

static var n := 0
static var bx := PackedFloat32Array()
static var by := PackedFloat32Array()
static var bvx := PackedFloat32Array()
static var bvy := PackedFloat32Array()
static var br := PackedFloat32Array()
static var blife := PackedFloat32Array()
static var bfuse := PackedFloat32Array()
static var bhasfuse := PackedByteArray()
static var bspr := PackedByteArray()
static var bburst := PackedByteArray()
static var counts := PackedInt32Array()

static func _ensure() -> void:
	if bx.size() == CAP:
		return
	for i in SPRITES.size():
		_spr_index[SPRITES[i]] = i
	bx.resize(CAP); by.resize(CAP); bvx.resize(CAP); bvy.resize(CAP); br.resize(CAP); blife.resize(CAP)
	bfuse.resize(CAP); bhasfuse.resize(CAP); bspr.resize(CAP); bburst.resize(CAP)
	counts.resize(SPRITES.size())

static func sprite_id(name: String) -> int:
	_ensure()
	return _spr_index.get(name, 0)

static func clear() -> void:
	n = 0

## Removes every bullet (Ruby `$G.ebullets = []`). Safe to call mid-update.
static func clear_all() -> void:
	for i in n:
		blife[i] = KILLED

static func add(x: float, y: float, vx: float, vy: float, spr: String, r: float,
		fuse: float = -1.0, burst: String = "") -> void:
	_ensure()
	if n >= CAP:
		return
	bx[n] = x; by[n] = y; bvx[n] = vx; bvy[n] = vy; br[n] = r; blife[n] = 6.0
	bspr[n] = sprite_id(spr)
	bhasfuse[n] = 1 if fuse >= 0.0 else 0
	bfuse[n] = fuse
	bburst[n] = sprite_id(burst) if burst != "" else 0
	counts[bspr[n]] += 1
	n += 1

static func alive(i: int) -> bool:
	return blife[i] > KILLED * 0.5

## ROADMAP 4.7 ("reflect"): removes up to max_n live shots within rad of (x, y) and returns each
## as [x, y, vx, vy].
static func take_near(x: float, y: float, rad: float, max_n: int) -> Array:
	var out := []
	var r2 := rad * rad
	for i in n:
		if out.size() >= max_n:
			break
		if blife[i] <= 0:
			continue
		var dx := bx[i] - x
		var dy := by[i] - y
		if dx * dx + dy * dy <= r2:
			out.append([bx[i], by[i], bvx[i], bvy[i]])
			blife[i] = KILLED
	return out

## ROADMAP 4.7 ("slow_shots"): live shots within rad of (x, y) keep only k of their speed.
## Returns how many were slowed.
static func slow_near(x: float, y: float, rad: float, k: float) -> int:
	var r2 := rad * rad
	var c := 0
	for i in n:
		if blife[i] <= 0:
			continue
		var dx := bx[i] - x
		var dy := by[i] - y
		if dx * dx + dy * dy <= r2:
			bvx[i] *= k
			bvy[i] *= k
			c += 1
	return c

## Removes bullets within rad of (x, y) (Ruby reject! by distance).
## True when a live enemy shot is within rad (perfect-dodge check).
static func any_near(x: float, y: float, rad: float) -> bool:
	var r2 := rad * rad
	for i in n:
		if blife[i] <= KILLED * 0.5:
			continue
		var dx := bx[i] - x
		var dy := by[i] - y
		if dx * dx + dy * dy <= r2:
			return true
	return false

static func kill_radius(x: float, y: float, rad: float) -> void:
	var r2 := rad * rad
	for i in n:
		var dx := bx[i] - x
		var dy := by[i] - y
		if dx * dx + dy * dy <= r2:
			blife[i] = KILLED

static func update(dt: float) -> void:
	_ensure()
	var p := G.player
	var grid := G.room.grid
	var orbs: Array = Combat.orbital_positions(p) if p.orbitals > 0 else []
	var px := p.x
	var py := p.y - 2
	var hit_r := p.hit_r
	var mirror := p.mirror
	var inv_ts := 1.0 / TB.TS
	# Work on local copies (static member access is slow in GDScript) and
	# write them back afterwards. Anything that may touch the arrays from the
	# outside (a fuse ering, a hit) syncs first.
	var xs := bx
	var ys := by
	var vxs := bvx
	var vys := bvy
	var lifes := blife
	var i := 0
	while i < n:
		var l := lifes[i]
		if l <= KILLED * 0.5:
			i += 1
			continue
		l -= dt
		lifes[i] = l
		if bhasfuse[i] == 1:
			bfuse[i] -= dt
			vxs[i] *= 0.97
			vys[i] *= 0.97
			if bfuse[i] <= 0:
				lifes[i] = 0.0
				_store(xs, ys, vxs, vys, lifes)
				Combat.ering(xs[i], ys[i], 8, 70, randf(), SPRITES[bburst[i]])
				xs = bx; ys = by; vxs = bvx; vys = bvy; lifes = blife
				i += 1
				continue
		var x := xs[i]
		var y := ys[i]
		var slow := 1.0
		if mirror and (x - p.x) * (x - p.x) + (y - p.y) * (y - p.y) < 1600.0:
			slow = 0.5
		x += vxs[i] * dt * slow
		y += vys[i] * dt * slow
		xs[i] = x
		ys[i] = y
		# Inlined World.solid(..., M_BULLET): anything but floor (or open sky) stops a shot.
		var c := floori(x * inv_ts)
		var r := floori(y * inv_ts)
		if c < 0 or r < 0 or c >= TB.COLS or r >= TB.ROWS or (grid[r * TB.COLS + c] != World.T_FLOOR and grid[r * TB.COLS + c] != World.T_VOID):
			lifes[i] = 0.0
			if GameData.rogues() and G.room.tile(c, r) == World.T_CRATE:   # (tile(): a shot past the room's edge is not a crate)
				Combat.hit_crate(G.room, c, r, 3.0)   # 17.3: cover wears down under fire
			Fx.burst(x, y, ["#8b8f9c", "#4e4a5e"], 3, 30, 0.2)
			i += 1
			continue
		for o in orbs:
			if (o.x - x) * (o.x - x) + (o.y - y) * (o.y - y) < 36.0:
				lifes[i] = 0.0
				Fx.burst(x, y, ["#f4ecd8"], 4, 40, 0.2)
		var rr := br[i] + hit_r
		if lifes[i] > 0 and (px - x) * (px - x) + (py - y) * (py - y) < rr * rr:
			if p.dodge_t <= 0 and p.invuln <= 0:
				lifes[i] = 0.0
				_store(xs, ys, vxs, vys, lifes)
				Combat.hurt_player(1, "a stray shot")
				xs = bx; ys = by; vxs = bvx; vys = bvy; lifes = blife
		i += 1
	_store(xs, ys, vxs, vys, lifes)
	compact()

static func _store(xs: PackedFloat32Array, ys: PackedFloat32Array, vxs: PackedFloat32Array,
		vys: PackedFloat32Array, lifes: PackedFloat32Array) -> void:
	bx = xs; by = ys; bvx = vxs; bvy = vys; blife = lifes

## Drops dead bullets in place and recounts sprites for drawing.
static func compact() -> void:
	for s in counts.size():
		counts[s] = 0
	var w := 0
	for i in n:
		if blife[i] <= 0:
			continue
		if w != i:
			bx[w] = bx[i]; by[w] = by[i]; bvx[w] = bvx[i]; bvy[w] = bvy[i]; br[w] = br[i]; blife[w] = blife[i]
			bfuse[w] = bfuse[i]; bhasfuse[w] = bhasfuse[i]; bspr[w] = bspr[i]; bburst[w] = bburst[i]
		counts[bspr[w]] += 1
		w += 1
	n = w

## The old sprites by sprite id, and the new look's frames ([sprite * 4 + frame]: four frames each).
static var _otex: Array[Texture2D] = []
static var _ftex: Array[Texture2D] = []
static var _ohw := PackedFloat32Array()
static var _ohh := PackedFloat32Array()
static var _fhw := PackedFloat32Array()
static var _fhh := PackedFloat32Array()

static func _textures() -> void:
	for name in SPRITES:
		var old := Img.t("orbr_" + name)   # 35.3: with a soft dark rim (tools/art/shot_rims.py)
		_otex.append(old)
		_ohw.append(old.get_width() / 2)
		_ohh.append(old.get_height() / 2)
		var strip := Img.t("ebr_" + name)
		var w := strip.get_width() / 4
		var h := strip.get_height()
		_fhw.append(w / 2)
		_fhh.append(h / 2)
		for f in 4:
			var a := AtlasTexture.new()
			if strip is AtlasTexture:
				a.atlas = strip.atlas
				a.region = Rect2(strip.region.position + Vector2(f * w, 0), Vector2(w, h))
			else:
				a.atlas = strip
				a.region = Rect2(f * w, 0, w, h)
			_ftex.append(a)

## One pass over the bullets, one sprite each. Every sprite sits in the same atlas, so the
## whole lot is still one batch. With FANCY EFFECTS on each kind is a four-frame animation
## (all shots of a kind in step; the kinds out of step with each other); off, the old orbs.
static func draw(ci: CanvasItem) -> void:
	_ensure()
	if n == 0:
		return
	if _otex.is_empty():
		_textures()
	var xs := bx
	var ys := by
	var lf := blife
	var sp := bspr
	if Vfx.enabled:
		var f := int(G.time * 10.0)
		var tex := _ftex
		var hw := _fhw
		var hh := _fhh
		for i in n:
			if lf[i] <= 0:
				continue
			var s := sp[i]
			ci.draw_texture(tex[s * 4 + ((f + s) & 3)], Vector2(roundf(xs[i] - hw[s]), roundf(ys[i] - hh[s])))
	else:
		var tex := _otex
		var hw := _ohw
		var hh := _ohh
		for i in n:
			if lf[i] <= 0:
				continue
			var s := sp[i]
			ci.draw_texture(tex[s], Vector2(roundf(xs[i] - hw[s]), roundf(ys[i] - hh[s])))
