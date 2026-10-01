class_name DrawLayer
extends Node2D
## One immediate-mode drawing layer. The owner supplies a painter callable that
## receives this CanvasItem; the layer is redrawn whenever queue_redraw() is
## called (every tick for dynamic layers, only on change for static ones).

var painter: Callable

func _init(p: Callable = Callable(), additive: bool = false) -> void:
	painter = p
	if additive:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

func _draw() -> void:
	if painter.is_valid():
		painter.call(self)
