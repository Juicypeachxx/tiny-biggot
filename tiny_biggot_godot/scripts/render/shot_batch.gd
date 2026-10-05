class_name ShotBatch
extends MultiMeshInstance2D
## Draws every player shot in one instanced draw. The painter writes eight
## numbers per shot (place, spin, size, kind, age, heading) into one buffer;
## the vertex shader below turns them into the same sprite, zoom and angle
## the plain painter (WorldView._draw_pbullet) works out per shot in script.
## Hundreds of shots cost the script a short loop instead of several calls
## and draw commands each.
##
## A shot "class" is one row of the tables given to the shader: its sprite in
## the atlas and how its zoom and angle follow from the shot. Shots the
## shader has no rule for (in the old look: lance, dart, pulse, rail), sprites
## outside the atlas and classes past the table size report PLAIN and are drawn
## by the plain painter.
##
## Two looks. With FANCY EFFECTS on, shots are drawn from the shot sheets
## (assets/graphics/shot_*.png): animated, pointing where they fly, coloured by
## the weapon's family, and every kind has a rule, so all of them are batched.
## A shot's rule is a "spec" (see specs); the plain painter draws from the same
## spec, so FAST DRAWING on and off give the same picture. With it off, the old
## rules below are used unchanged.

const STRIDE := 16          # MultiMesh 2D layout: 8 transform, 4 colour, 4 custom
const MAX_CLASSES := 64
const PLAIN := 1000         # draw with the plain painter
const SKIP := 1001          # a mine: drawn on the floor, in the lower layer
## Specials (what the shader does besides zoom = max(zmin, r / zdiv)).
const S_NONE := 0.0
const S_HEX := 1.0          # big sprite (next class) past r 3.5, zoom r / 5 past r 6
const S_BOLT := 2.0         # origin (4, 2), zoom 1.4 past r 3.2
const S_FIRE := 3.0         # zoom and opacity follow the shot's remaining life
const R_NONE := 0.0
const R_SPIN := 1.0         # spins with the shot's rot
const R_HEADING := 2.0      # points along its velocity

## The colour families of the shot sheets, in sheet order, eight to a row: the
## fifteen weapon families, "none" (a shot no weapon fired) and "earth" (dirt).
const TAGS := ["none", "core", "pyre", "frost", "venom", "storm", "blood", "bulwark", "shadow", "arcane", "fortune",
	"demolition", "swarm", "edge", "fury", "malice", "earth"]
const PER_ROW := 8
## Frames of each shot sheet.
const SHEETS := { "shot_bolt": 2, "shot_pellet": 2, "shot_hex": 4, "shot_hexBig": 4, "shot_spark": 4, "shot_fire": 4,
	"shot_flask": 1, "shot_pulse": 4, "shot_rail": 2, "shot_whirl": 2 }
## The family a shot with no family of its own is drawn in, by kind.
const PLAIN_TAG := { "hex": "shadow", "fire": "pyre", "flask": "venom", "pulse": "shadow", "spark": "none", "bolt": "core",
	"clod": "earth", "rail": "none", "whirl": "core" }
## Frames a second of a shot's own animation.
const ANIM_FPS := 14.0

const SHADER := """
shader_type canvas_item;
uniform vec4 rects[64];
uniform vec4 parms[64];
uniform float gf;                      // the animation clock, in frames
varying float v_alpha;
void vertex() {
	vec4 d = INSTANCE_CUSTOM;          // spin (degrees), r, class, life left (0..1)
	vec2 vel = COLOR.rg;               // velocity, for shots that point where they fly
	int cls = int(d.b + 0.5);
	vec4 pm = parms[cls];              // zmin, zdiv, rotation rule + 10 * (frames - 1), special
	float nfr = floor(pm.z / 10.0 + 0.01) + 1.0;
	float rule = pm.z - (nfr - 1.0) * 10.0;
	float r = d.g;
	float z = pm.x;
	if (pm.y > 0.0) { z = max(pm.x, r / pm.y); }
	float alpha = 1.0;
	vec2 org = vec2(-1.0);
	if (pm.w > 0.5 && pm.w < 1.5) {          // hex
		if (r > 3.5) { cls += 1; }
		z = r > 6.0 ? r / 5.0 : 1.0;
	} else if (pm.w > 1.5 && pm.w < 2.5) {   // bolt
		z = r > 3.2 ? 1.4 : 1.0;
		org = vec2(4.0, 2.0);
	} else if (pm.w > 2.5) {                 // fire
		z = 0.6 + 0.8 * (1.0 - d.a);
		alpha = clamp(d.a * 1.5, 0.0, 1.0);
	}
	vec4 rc = rects[cls];
	rc.x += mod(gf, nfr) * rc.z;       // the class's frame now: frames sit side by side
	if (org.x < 0.0) { org = floor(rc.zw * 0.5); }
	float a = 0.0;
	if (rule > 0.5 && rule < 1.5) { a = -radians(d.r); }
	else if (rule > 1.5) { a = atan(vel.y, vel.x); }
	vec2 corner = VERTEX + vec2(0.5);
	vec2 p = (corner * rc.zw - org) * z;
	float c = cos(a);
	float s = sin(a);
	VERTEX = vec2(c * p.x - s * p.y, s * p.x + c * p.y);
	UV = (rc.xy + corner * rc.zw) * TEXTURE_PIXEL_SIZE;
	v_alpha = alpha;
}
void fragment() {
	vec4 t = texture(TEXTURE, UV);
	COLOR = vec4(t.rgb, t.a * v_alpha);
}
"""

static var _classes := {}      # key -> class id
static var _rects := PackedVector4Array()
static var _parms := PackedVector4Array()
static var _version := 1       # goes up whenever the tables change; each batch hands them to its shader once per version
static var _atlas: Texture2D = null
## Frames of each class, by class id. Shots of one class animate in step, off one clock the
## shader is handed once a frame (gf), so animation costs the painter nothing per shot.
static var frames := PackedInt32Array()
## Whirls drawn under spinning weapons in one frame; in a flood past this the rest go without.
const WHIRL_MAX := 64
## A class found no room in the tables since the last reset (see try_reset).
static var overflow := false
static var _reset_frame := -100000
const RESET_GAP := 600        # physics frames between table resets
## The new look. Set by Vfx.reset() from OPTIONS > FANCY EFFECTS.
static var fancy := true
## New-look rules: [sprite, frame 0 inside the sprite (Rect2), frames, zmin, zdiv, rotation rule, special,
## class id or -1, spec of the big sprite (hex) or -1]. A shot keeps its spec's index in b.ds.
static var specs: Array = []
static var _spec_ids := {}     # key -> index in specs

## One shader for every batch: the graphics card builds its program once, whichever batch draws first.
static var _shader: Shader = null

## Instances not in use are parked far off-screen rather than left out of the draw: with any
## shot in the air the batch draws its whole buffer, so the graphics card is asked for the
## same kind of draw every frame whatever the number of shots. (How the per-draw data is
## stepped depends on the count drawn. A driver may build a new pipeline the first time it
## meets each count, a stall each time; the software one used for the tests always does.)
const PARK := -4096.0

var buf := PackedFloat32Array()
var cap := 0
var used := 0           # instances written this tick
var _seen := 0          # the table version this batch's shader has

func _init() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	multimesh.mesh = q
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	material = m
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_reserve(512)

func _reserve(count: int) -> void:
	cap = count
	used = 0
	multimesh.instance_count = cap
	multimesh.visible_instance_count = 0
	# The whole screen, so the engine neither works the bounds out from every instance each
	# frame nor skips the batch.
	multimesh.custom_aabb = AABB(Vector3(-64, -64, 0), Vector3(TB.SW + 128, TB.SH + 128, 1))
	buf.resize(cap * STRIDE)
	buf.fill(0.0)
	for i in cap:
		buf[i * STRIDE] = 1.0        # identity basis: the shader does zoom and angle
		buf[i * STRIDE + 5] = 1.0
		buf[i * STRIDE + 3] = PARK
		buf[i * STRIDE + 7] = PARK

## Makes room for `count` shots and returns the buffer to write into.
func begin(count: int) -> PackedFloat32Array:
	if count > cap:
		_reserve(maxi(count, cap * 2))
	return buf

var _gf := -1

## Shows the first `count` shots written into the buffer, animated at clock gf.
func finish(count: int, gf: int = 0) -> void:
	if gf != _gf:
		_gf = gf
		material.set_shader_parameter("gf", float(gf))
	if _seen != _version and _atlas != null:
		_seen = _version
		texture = _atlas
		var rr := _rects.duplicate()
		var pp := _parms.duplicate()
		rr.resize(MAX_CLASSES)
		pp.resize(MAX_CLASSES)
		material.set_shader_parameter("rects", rr)
		material.set_shader_parameter("parms", pp)
	# Park what was in use last tick and is not now.
	for i in range(count, used):
		buf[i * STRIDE + 3] = PARK
		buf[i * STRIDE + 7] = PARK
	used = count
	multimesh.visible_instance_count = cap if count > 0 else 0
	if count > 0:
		multimesh.buffer = buf

## Registers one shader table row; -1 when the sprite is not in the atlas or the table is full.
## cell is the first frame inside the sprite (the whole sprite when left empty).
static func _row(key: String, sprite: String, zmin: float, zdiv: float, rot: float, special: float,
		cell: Rect2 = Rect2(), nframes: int = 1) -> int:
	if _classes.has(key):
		return _classes[key]
	var id := -1
	var tex := Img.t(sprite)
	if tex is AtlasTexture and (_atlas == null or tex.atlas == _atlas) and _rects.size() >= MAX_CLASSES:
		overflow = true
	if tex is AtlasTexture and (_atlas == null or tex.atlas == _atlas) and _rects.size() < MAX_CLASSES:
		_atlas = tex.atlas
		id = _rects.size()
		var rg: Rect2 = tex.region
		if cell.size.x > 0.0:
			rg = Rect2(rg.position + cell.position, cell.size)
		_rects.append(Vector4(rg.position.x, rg.position.y, rg.size.x, rg.size.y))
		_parms.append(Vector4(zmin, zdiv, rot + 10.0 * (nframes - 1), special))
		frames.append(nframes)
		_version += 1
	_classes[key] = id
	return id

## A rule made earlier. If it has no place in the shader tables (they were emptied, or were
## full), it asks for one again.
static func _known(key: String) -> int:
	var at: int = _spec_ids[key]
	var sp: Array = specs[at]
	if sp[7] < 0:
		sp[7] = _row("f:" + key, sp[0], sp[3], sp[4], sp[5], sp[6], sp[1], sp[2])
	return at

## A new-look rule for a sprite (frames side by side; the whole sprite when cell is empty).
## Returns its index in specs.
static func _spec(key: String, sprite: String, cell: Rect2, nframes: int, zmin: float, zdiv: float, rot: float,
		special: float) -> int:
	if _spec_ids.has(key):
		return _known(key)
	if cell.size.x <= 0.0:
		var tex := Img.t(sprite)
		cell = Rect2(0, 0, tex.get_width() / nframes, tex.get_height())
	var id := _row("f:" + key, sprite, zmin, zdiv, rot, special, cell, nframes)
	specs.append([sprite, cell, nframes, zmin, zdiv, rot, special, id, -1])
	_spec_ids[key] = specs.size() - 1
	return specs.size() - 1

## The tables hold 64 classes. A long run meets more than that (every thrown weapon is one, every
## family of every kind another), though never many at once. So when a class finds no room, the
## tables are emptied and the classes in use take their places again: returns true when it did
## that, and the caller then marks every live shot to be sorted again. At most once every
## RESET_GAP frames, so a screen that really shows more than 64 at once does not thrash.
static func try_reset() -> bool:
	if not overflow:
		return false
	var now := Engine.get_physics_frames()
	if now - _reset_frame < RESET_GAP:
		return false
	_reset_frame = now
	reset_table()
	return true

static func reset_table() -> void:
	_classes.clear()
	_rects.clear()
	_parms.clear()
	frames.clear()
	for sp in specs:
		sp[7] = -1
	overflow = false
	_version += 1

## A number as the batch's shader receives it. The engine hands a shot's velocity, spin, size and
## life to the shader as 16-bit floats; the plain painter rounds the same way, so a shot turned
## to its heading lands on the same pixels in both.
static var _hb := PackedByteArray([0, 0])
static func half(v: float) -> float:
	_hb.encode_half(0, v)
	return _hb.decode_half(0)

## The animation clock at time t (seconds): every class shows frame clock % its frames.
## Kept under 64 so the shader's arithmetic stays exact (frame counts are 1, 2 and 4).
static func clock(t: float) -> int:
	return int(t * ANIM_FPS) % 64

## A new-look rule for one family's run of frames in a shot sheet.
static func _sheet_spec(sheet: String, kind: String, tag: String, zmin: float, zdiv: float, rot: float, special: float,
		variant: String = "") -> int:
	var t := tag
	var ti := TAGS.find(t) if t != "" and t != "core" else -1
	if ti < 0:
		t = PLAIN_TAG.get(kind, "none")
		ti = TAGS.find(t)
	var key := sheet + ":" + t + variant
	if _spec_ids.has(key):
		return _known(key)
	var tex := Img.t(sheet)
	var nf: int = SHEETS[sheet]
	var rows := (TAGS.size() + PER_ROW - 1) / PER_ROW
	var w := tex.get_width() / (PER_ROW * nf)
	var h := tex.get_height() / rows
	return _spec(key, sheet, Rect2((ti % PER_ROW) * nf * w, (ti / PER_ROW) * h, w, h), nf, zmin, zdiv, rot, special)

## The new look: every kind has a rule. Sets b.ds (the spec), b.dw (the spec of the whirl under
## a spinning weapon, or -1) and b.dk (the class, or PLAIN when the shader table has no room).
static func _classify_fancy(b: PBullet) -> int:
	var tag := b.tag
	var s := -1
	b.dw = -1
	match b.kind:
		"mine":
			b.ds = -1
			b.dk = SKIP
			return SKIP
		"hex":
			# Two rules in a row: the shader steps to the big sprite past r 3.5.
			s = _sheet_spec("shot_hex", "hex", tag, 1.0, 0.0, R_HEADING, S_HEX)
			var big := _sheet_spec("shot_hexBig", "hex", tag, 1.0, 0.0, R_HEADING, S_HEX)
			specs[s][8] = big
			if specs[s][7] >= 0 and specs[big][7] != specs[s][7] + 1:
				specs[s][7] = -1     # not side by side in the table: the plain painter draws it
		"bolt":
			s = _sheet_spec("shot_bolt", "bolt", tag, 1.0, 2.5, R_HEADING, S_NONE)
		"clod":
			s = _sheet_spec("shot_pellet", "clod", tag, 1.0, 2.5, R_HEADING, S_NONE)
		"flask":
			s = _sheet_spec("shot_flask", "flask", tag, 1.0, 2.5, R_SPIN, S_NONE)
		"spark":
			s = _sheet_spec("shot_spark", "spark", tag, 1.0, 0.0, R_NONE, S_NONE)
		"fire":
			s = _sheet_spec("shot_fire", "fire", tag, 1.0, 0.0, R_NONE, S_FIRE)
		"pulse":
			s = _sheet_spec("shot_pulse", "pulse", tag, 0.0, 4.0, R_NONE, S_NONE)
		"rail":
			s = _sheet_spec("shot_rail", "rail", tag, 1.0, 0.0, R_HEADING, S_NONE)
		"lance":
			s = _spec("lance", "shot_lance", Rect2(), 1, 1.0, 0.0, R_HEADING, S_NONE)
		"dart":
			s = _spec("dart", "shot_dart", Rect2(), 1, 1.0, 0.0, R_HEADING, S_NONE)
		"feather":
			s = _spec("feather", "feather", Rect2(), 1, 1.0, 0.0, R_HEADING, S_NONE)
		"boomer":
			var name := b.icon if b.icon != "" else "orb_gold"
			var still := b.icon == "w_lantern" or b.icon == "w_sunlantern"
			s = _spec("boomer:" + name, name, Rect2(), 1, 1.0, 3.0, R_NONE if still else R_SPIN, S_NONE)
			if not still:
				b.dw = _sheet_spec("shot_whirl", "whirl", tag, 1.0, 3.0, R_SPIN, S_NONE, ":b")
		_:
			var name := b.icon if b.icon != "" and b.kind != "hatchet" else "hatchet"
			s = _spec("icon:" + name, name, Rect2(), 1, 0.8, 4.0, R_SPIN, S_NONE)
			b.dw = _sheet_spec("shot_whirl", "whirl", tag, 0.8, 4.0, R_SPIN, S_NONE)
	b.ds = s
	var id: int = specs[s][7]
	b.dk = id if id >= 0 else PLAIN
	return b.dk

## The shader class of a shot (cached on the shot as b.dk), PLAIN or SKIP.
## Mirrors WorldView._draw_pbullet branch for branch.
static func classify(b: PBullet) -> int:
	var id := -1
	b.gk = 1 if b.kind in ["hex", "boomer", "rail"] else (2 if b.kind == "pulse" else 0)
	if fancy:
		return _classify_fancy(b)
	b.ds = -1
	b.dw = -1
	match b.kind:
		"mine":
			b.dk = SKIP
			return SKIP
		"lance", "dart", "pulse", "rail":
			pass
		"hex":
			# Two rows in a row: the shader steps to the big sprite past r 3.5.
			if _rects.size() + 2 <= MAX_CLASSES or _classes.has("hex"):
				id = _row("hex", "orb_hex", 1.0, 0.0, R_NONE, S_HEX)
				if id >= 0 and _row("hexBig", "orb_hexBig", 1.0, 0.0, R_NONE, S_HEX) != id + 1:
					id = -1
		"clod":
			id = _row("clod", "orb_clod", 1.0, 2.5, R_NONE, S_NONE)
		"flask":
			id = _row("flask", "orb_flask", 1.0, 2.5, R_NONE, S_NONE)
		"spark":
			id = _row("spark", "orb_cyan", 1.0, 0.0, R_NONE, S_NONE)
		"boomer":
			var name := b.icon if b.icon != "" else "orb_gold"
			var still := b.icon == "w_lantern" or b.icon == "w_sunlantern"
			id = _row("boomer:" + name, name, 1.0, 3.0, R_NONE if still else R_SPIN, S_NONE)
		"bolt":
			id = _row("bolt", "bolt", 1.0, 0.0, R_HEADING, S_BOLT)
		"fire":
			id = _row("fire", "orb_fire", 1.0, 0.0, R_NONE, S_FIRE)
		"feather":
			id = _row("feather", "feather", 1.0, 0.0, R_HEADING, S_NONE)
		_:
			var name := b.icon if b.icon != "" and b.kind != "hatchet" else "hatchet"
			id = _row("icon:" + name, name, 0.8, 4.0, R_SPIN, S_NONE)
	b.dk = id if id >= 0 else PLAIN
	return b.dk
