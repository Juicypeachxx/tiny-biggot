class_name DrawLayer
extends Node2D
## One immediate-mode drawing layer. The owner supplies a painter callable that
## receives this CanvasItem; the layer is redrawn whenever queue_redraw() is
## called (every tick for dynamic layers, only on change for static ones).

var painter: Callable
## --perf: GDScript time spent drawing, per painter, in microseconds.
static var perf := {}
static var perf_on := false

func _init(p: Callable = Callable(), additive: bool = false) -> void:
	painter = p
	if additive:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

func _draw() -> void:
	if not painter.is_valid():
		return
	if not perf_on:
		painter.call(self)
		return
	var t0 := Time.get_ticks_usec()
	painter.call(self)
	var k := painter.get_method()
	perf[k] = perf.get(k, 0) + Time.get_ticks_usec() - t0
