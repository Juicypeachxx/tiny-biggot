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
static var texts: Array = []

static func _ensure() -> void:
	if px.size() == CAP:
		return
	px.resize(CAP); py.resize(CAP); pvx.resize(CAP); pvy.resize(CAP)
	plife.resize(CAP); pmax.resize(CAP); pdrag.resize(CAP); psize.resize(CAP); pcol.resize(CAP)

static func clear() -> void:
	n = 0
	texts.clear()

static func particle(x: float, y: float, vx: float, vy: float, life: float, col: String,
		size: int = 1, drag: float = 1.0) -> void:
	_ensure()
	if n >= CAP:
		return
	px[n] = x; py[n] = y; pvx[n] = vx; pvy[n] = vy
	plife[n] = life; pmax[n] = life; pdrag[n] = drag; psize[n] = size; pcol[n] = TB.c(col)
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
		n += 1

static func float_text(x: float, y: float, text: Variant, col: String = "white") -> void:
	texts.append({ "x": x + TB.rint(-3, 3), "y": y, "text": str(text), "col": col, "life": 0.7 })

static func update(dt: float) -> void:
	var w := 0
	for i in n:
		var l := plife[i] - dt
		if l <= 0:
			continue
		var d := pdrag[i]
		if w != i:
			psize[w] = psize[i]; pcol[w] = pcol[i]; pmax[w] = pmax[i]; pdrag[w] = d
		px[w] = px[i] + pvx[i] * dt
		py[w] = py[i] + pvy[i] * dt
		pvx[w] = pvx[i] * d
		pvy[w] = pvy[i] * d
		plife[w] = l
		w += 1
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
		texts = texts.slice(texts.size() - TEXT_MAX)

static func _drop_oldest(k: int) -> void:
	for i in range(k, n):
		var j := i - k
		px[j] = px[i]; py[j] = py[i]; pvx[j] = pvx[i]; pvy[j] = pvy[i]
		plife[j] = plife[i]; pmax[j] = pmax[i]; pdrag[j] = pdrag[i]; psize[j] = psize[i]; pcol[j] = pcol[i]
	n -= k

static func draw_particles(ci: CanvasItem) -> void:
	for i in n:
		var sz := psize[i]
		var c := pcol[i]
		c.a = clampf(plife[i] / pmax[i] * 1.5, 0.0, 1.0)
		ci.draw_rect(Rect2(roundf(px[i] - sz / 2), roundf(py[i] - sz / 2), sz, sz), c)

static func draw_texts(ci: CanvasItem) -> void:
	for t in texts:
		var w := TB.text_w(t["text"]) + 1
		Gfx.text(ci, t["text"], roundf(t["x"] - w / 2), roundf(t["y"]), t["col"], 1, 0.0, true,
			clampf(t["life"] * 3, 0.0, 1.0))
