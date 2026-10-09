class_name Fx
extends RefCounted
## Particles and floating numbers (port of Entities.rb burst/particle/float_text
## and Combat.rb update_particles).
##
## Performance: particles live in parallel packed arrays (struct of arrays)
## with a fixed capacity. Nothing is allocated per particle, dead ones are
## compacted in place each tick, and drawing is untextured rects in a single
## canvas item, which Godot batches into one draw call. Like the original, at
## most 400 particles stay alive (the oldest are dropped first).

const CAP := 1024
const LIVE_MAX := 400
const TEXT_MAX := 40

static var n := 0
static var px := PackedFloat32Array()
static var py := PackedFloat32Array()
static var pvx := PackedFloat32Array()
static var pvy := PackedFloat32Array()
static var plife := PackedFloat32Array()
static var pmax := PackedFloat32Array()
static var pdrag := PackedFloat32Array()
static var psize := PackedByteArray()
static var pcol := PackedColorArray()
## Drawing only: particles made while this is set are simulated exactly as usual
## (same random numbers, same slots, same lifetimes) but never drawn. The rules set
## it around particles that a Vfx effect replaces.
static var hide := false
static var phide := PackedByteArray()
static var texts: Array = []

static func _ensure() -> void:
	if px.size() == CAP:
		return
	px.resize(CAP); py.resize(CAP); pvx.resize(CAP); pvy.resize(CAP)
	plife.resize(CAP); pmax.resize(CAP); pdrag.resize(CAP); psize.resize(CAP); pcol.resize(CAP)
	phide.resize(CAP)

static func clear() -> void:
	n = 0
	for t in texts:
		t["life"] = 0.0   # (a foe's newest number, Fx.hit_text, is gone with them)
	texts.clear()

static func particle(x: float, y: float, vx: float, vy: float, life: float, col: String,
		size: int = 1, drag: float = 1.0) -> void:
	_ensure()
	if n >= CAP:
		return
	px[n] = x; py[n] = y; pvx[n] = vx; pvy[n] = vy
	plife[n] = life; pmax[n] = life; pdrag[n] = drag; psize[n] = size; pcol[n] = TB.c(col)
	phide[n] = 1 if hide else 0
	n += 1

static func burst(x: float, y: float, cols: Array, count: int = 8, speed: float = 60, life: float = 0.4,
		size: int = 1) -> void:
	_ensure()
	for i in count:
		if n >= CAP:
			return
		var a := randf() * TAU
		var s := speed * (0.3 + randf() * 0.7)
		px[n] = x; py[n] = y; pvx[n] = cos(a) * s; pvy[n] = sin(a) * s
		plife[n] = life * (0.6 + randf() * 0.6); pmax[n] = life; pdrag[n] = 0.9
		psize[n] = mini(3, size + (1 if randf() < 0.3 else 0))
		pcol[n] = TB.c(cols[randi() % cols.size()])
		phide[n] = 1 if hide else 0
		n += 1

## big: crits are drawn at double size with a small pop (drawing only).
static func float_text(x: float, y: float, text: Variant, col: String = "white", big: bool = false) -> void:
	texts.append({ "x": x + TB.rint(-3, 3), "y": y, "text": str(text), "col": col, "life": 0.7, "big": big })

## 39.4 (his video, 9 Oct 18:20: a guardian hit some 200 times a second wore a block of gold numbers
## piled on one spot). Expanded game: a foe's hits of one colour in the first MERGE_T seconds of its
## newest number add up in that number, which then floats off as before; the next hit starts a new
## one. Every hit still counts and shows. The nudge is rolled all the same, so the game's dice roll
## exactly as before.
const MERGE_T := 0.3
static func hit_text(e: Enemy, x: float, y: float, dmg: float, col: String, big: bool) -> void:
	var nudge := TB.rint(-3, 3)
	var t = e.num
	if t != null and t["col"] == col and t["big"] == big and t["life"] > 0.7 - MERGE_T:
		t["sum"] += dmg
		t["text"] = TB.fmt_dmg(t["sum"])
		return
	t = { "x": x + nudge, "y": y, "text": TB.fmt_dmg(dmg), "col": col, "life": 0.7, "big": big, "sum": dmg }
	texts.append(t)
	e.num = t

static func update(dt: float) -> void:
	# Local references: reading a static member costs far more than a local in GDScript.
	var xs := px
	var ys := py
	var vxs := pvx
	var vys := pvy
	var lifes := plife
	var drags := pdrag
	var w := 0
	for i in n:
		var l := lifes[i] - dt
		if l <= 0:
			continue
		var d := drags[i]
		var vx := vxs[i]
		var vy := vys[i]
		if w != i:
			psize[w] = psize[i]; pcol[w] = pcol[i]; pmax[w] = pmax[i]; drags[w] = d; phide[w] = phide[i]
		xs[w] = xs[i] + vx * dt
		ys[w] = ys[i] + vy * dt
		vxs[w] = vx * d
		vys[w] = vy * d
		lifes[w] = l
		w += 1
	px = xs; py = ys; pvx = vxs; pvy = vys; plife = lifes; pdrag = drags
	n = w
	if n > LIVE_MAX:
		_drop_oldest(n - LIVE_MAX)
	var i := 0
	while i < texts.size():
		var t: Dictionary = texts[i]
		t["life"] -= dt
		t["y"] -= 22 * dt
		if t["life"] <= 0:
			texts.remove_at(i)
		else:
			i += 1
	if texts.size() > TEXT_MAX:
		for k in texts.size() - TEXT_MAX:
			texts[k]["life"] = 0.0   # (so no foe adds to a number no longer shown)
		texts = texts.slice(texts.size() - TEXT_MAX)

static func _drop_oldest(k: int) -> void:
	for i in range(k, n):
		var j := i - k
		px[j] = px[i]; py[j] = py[i]; pvx[j] = pvx[i]; pvy[j] = pvy[i]
		plife[j] = plife[i]; pmax[j] = pmax[i]; pdrag[j] = pdrag[i]; psize[j] = psize[i]; pcol[j] = pcol[i]
		phide[j] = phide[i]
	n -= k

static func draw_particles(ci: CanvasItem) -> void:
	var xs := px
	var ys := py
	var lifes := plife
	var maxs := pmax
	var sizes := psize
	var cols := pcol
	var hides := phide
	for i in n:
		if hides[i] != 0:
			continue
		var sz := sizes[i]
		var c := cols[i]
		c.a = clampf(lifes[i] / maxs[i] * 1.5, 0.0, 1.0)
		ci.draw_rect(Rect2(roundf(xs[i] - sz / 2), roundf(ys[i] - sz / 2), sz, sz), c)

static func draw_texts(ci: CanvasItem) -> void:
	for t in texts:
		var sc := 2 if t.get("big", false) else 1
		var w := TB.text_w(t["text"], sc) + 1
		# Pop: numbers jump up a few pixels in their first 0.12 s, then drift.
		var age: float = 0.7 - t["life"]
		var jump := -sin(minf(age / 0.12, 1.0) * PI * 0.5) * (5.0 if sc == 2 else 3.0)
		Gfx.text(ci, t["text"], roundf(t["x"] - w / 2), roundf(t["y"] + jump - (4 if sc == 2 else 0)), t["col"], sc, 0.0, true,
			clampf(t["life"] * 3, 0.0, 1.0))
