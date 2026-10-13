class_name Warmup
extends Node2D
## Draws one of every kind of thing the game draws, invisibly, during the first
## frames after launch, then removes itself.
##
## A graphics card builds the program for each kind of drawing (textured
## rectangles, lines, filled shapes, the additive glow layer, the shot batch's
## own shader) the first time that kind is drawn, and the game stalls while it
## does: a few frames lost at the first shot fired, the first ring, the first
## lightning bolt. Drawing them all once here moves those stalls to the moment
## the game starts, where nothing is moving yet.
##
## Everything is drawn with no opacity in the top-left corner, so no pixel
## changes. Drawing only: it reads nothing from the game and uses no random
## numbers.

const FRAMES := 3
var _left := FRAMES
var _layers: Array[DrawLayer] = []
## One tiny clear texture of each shape (power-of-two sides or not). Some drivers, the software
## one used for the tests among them, build a variant per texture shape as well.
var _shapes: Array[ImageTexture] = []

func _ready() -> void:
	for size in [Vector2i(4, 4), Vector2i(4, 3), Vector2i(3, 4), Vector2i(3, 3)]:
		_shapes.append(ImageTexture.create_from_image(Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)))
	# The same two kinds of layer the world is drawn with: plain, and additive (the glow layer).
	for additive in [false, true]:
		var l := DrawLayer.new(_paint, additive)
		add_child(l)
		_layers.append(l)
	# The shot batch: one shot showing one clear texel of the sprite atlas.
	var tex := Img.t("glow_white")
	if tex is AtlasTexture:
		var sb := ShotBatch.new()
		add_child(sb)
		var buf := sb.begin(1)
		buf[3] = 0.0        # one instance at the corner; the rest stay parked, as in play
		buf[7] = 0.0
		sb.finish(1)
		# Its own table, whatever the game's holds by now: class 0 is the atlas's corner texel,
		# which is padding (clear).
		var rects := PackedVector4Array([Vector4(0, 0, 1, 1)])
		var parms := PackedVector4Array([Vector4(1, 0, 0, 0)])
		rects.resize(ShotBatch.MAX_CLASSES)
		parms.resize(ShotBatch.MAX_CLASSES)
		sb.texture = (tex as AtlasTexture).atlas
		sb.material.set_shader_parameter("rects", rects)
		sb.material.set_shader_parameter("parms", parms)

	# 22.1: the dark of a night floor, with nothing dark (dark = 0).
	var dl := DrawLayer.new(func(ci): ci.draw_rect(Rect2(0, 0, 2, 2), Color.WHITE))
	dl.material = Weather.material()
	dl.material.set_shader_parameter("lights", PackedVector4Array([Vector4(0, 0, 1, 1)]))
	dl.material.set_shader_parameter("count", 1)
	dl.material.set_shader_parameter("dark", 0.0)
	add_child(dl)
	_layers.append(dl)

func _process(_delta: float) -> void:
	_left -= 1
	if _left <= 0:
		queue_free()
		return
	for l in _layers:
		l.queue_redraw()

func _paint(ci: CanvasItem) -> void:
	var clear := Color(1, 1, 1, 0)
	var tex := Img.t("glow_white")
	var pts := PackedVector2Array([Vector2(1, 1), Vector2(6, 2), Vector2(4, 6), Vector2(1, 5)])
	# Rectangles and sprites, straight and turned.
	ci.draw_rect(Rect2(0, 0, 4, 4), clear)
	ci.draw_texture(tex, Vector2.ZERO, clear)
	ci.draw_texture_rect(tex, Rect2(0, 0, 8, 8), false, clear)
	ci.draw_texture_rect_region(tex, Rect2(0, 0, 8, 8), Rect2(0, 0, 4, 4), clear)
	for st in _shapes:
		ci.draw_texture(st, Vector2.ZERO, clear)
	ci.draw_set_transform(Vector2(6, 6), 0.5, Vector2(1.5, 1.5))
	ci.draw_texture_rect(tex, Rect2(-4, -4, 8, 8), false, clear)
	ci.draw_rect(Rect2(-2, -2, 4, 4), clear)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Lines: thick ones and hairlines, single, joined and in pairs.
	ci.draw_line(Vector2(1, 1), Vector2(7, 5), clear, 1.0)
	ci.draw_line(Vector2(1, 1), Vector2(7, 5), clear, 3.0)
	ci.draw_polyline(pts, clear, -1.0)
	ci.draw_polyline(pts, clear, 3.0)
	ci.draw_polyline(pts, clear, 1.0, false)
	ci.draw_multiline(pts, clear, -1.0)
	# Filled shapes and rings.
	ci.draw_circle(Vector2(5, 5), 4.0, clear, true, -1.0, false)
	ci.draw_circle(Vector2(5, 5), 4.0, clear)
	ci.draw_arc(Vector2(5, 5), 4.0, 0.0, TAU, 12, clear, 1.0, false)
	ci.draw_arc(Vector2(5, 5), 4.0, 0.0, TAU, 12, clear, 1.0)
	ci.draw_arc(Vector2(5, 5), 4.0, 0.0, 2.0, 8, clear, 2.0, false)
	ci.draw_colored_polygon(pts, clear)
