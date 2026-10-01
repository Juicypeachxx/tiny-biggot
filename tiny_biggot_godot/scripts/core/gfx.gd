class_name Gfx
extends RefCounted
## Immediate-mode drawing helpers that reproduce RGSS Sprite semantics inside a
## CanvasItem._draw(): origin (ox, oy), zoom, angle, mirror, opacity and the
## Sprite#color tint. Positions are rounded to whole pixels like RGSS.
##
## RGSS angles are degrees counter-clockwise; Godot rotation is radians
## clockwise (y points down). Callers pass Godot radians: rgss_deg -> -deg_to_rad.

const FONT_CHARS := " !$%'()*+,-./0123456789:<=>?ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_~"
static var _font_index := {}

static func sprite(ci: CanvasItem, name: String, x: float, y: float, ox: float, oy: float,
		zx: float = 1.0, zy: float = 1.0, rot: float = 0.0, mirror: bool = false,
		alpha: float = 1.0, tint: Color = Color(0, 0, 0, 0)) -> void:
	var tex := Img.t(name)
	var px := roundf(x)
	var py := roundf(y)
	var w := tex.get_width()
	var h := tex.get_height()
	var mod := Color(1, 1, 1, alpha)
	# A fully opaque tint replaces the sprite (RGSS color alpha 255).
	var solid := tint.a >= 1.0
	if rot == 0.0 and zx == 1.0 and zy == 1.0 and not mirror:
		var pos := Vector2(px - ox, py - oy)
		if not solid:
			ci.draw_texture(tex, pos, mod)
		if tint.a > 0.0:
			ci.draw_texture(Img.white(name), pos, Color(tint.r, tint.g, tint.b, tint.a * alpha))
		return
	ci.draw_set_transform(Vector2(px, py), rot, Vector2(zx, zy))
	var r := Rect2(-ox + w, -oy, -w, h) if mirror else Rect2(-ox, -oy, w, h)
	if not solid:
		ci.draw_texture_rect(tex, r, false, mod)
	if tint.a > 0.0:
		ci.draw_texture_rect(Img.white(name), r, false, Color(tint.r, tint.g, tint.b, tint.a * alpha))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## RGSS `sp()`: origin at bottom centre (ox = w / 2, oy = h).
static func sp(ci: CanvasItem, name: String, x: float, y: float, zx: float = 1.0, zy: float = 1.0,
		rot: float = 0.0, mirror: bool = false, alpha: float = 1.0, tint: Color = Color(0, 0, 0, 0)) -> void:
	var tex := Img.t(name)
	sprite(ci, name, x, y, tex.get_width() / 2, tex.get_height(), zx, zy, rot, mirror, alpha, tint)

## Sprite drawn with its top-left at (x, y) (RGSS default origin).
static func at(ci: CanvasItem, name: String, x: float, y: float, alpha: float = 1.0) -> void:
	ci.draw_texture(Img.t(name), Vector2(roundf(x), roundf(y)), Color(1, 1, 1, alpha))

## A solid pixel block (RGSS Img.px(hex, size) sprites), optionally zoomed/rotated.
static func px(ci: CanvasItem, col: Color, x: float, y: float, size: float = 1.0) -> void:
	ci.draw_rect(Rect2(roundf(x), roundf(y), size, size), col)

## RGSS px sprite with zoom and angle: a 1x1 pixel stretched to (zx, zy), rotated about its top-left.
static func bar(ci: CanvasItem, col: Color, x: float, y: float, zx: float, zy: float, rot: float = 0.0) -> void:
	if rot == 0.0:
		ci.draw_rect(Rect2(roundf(x), roundf(y), zx, zy), col)
		return
	ci.draw_set_transform(Vector2(roundf(x), roundf(y)), rot, Vector2.ONE)
	ci.draw_rect(Rect2(0, 0, zx, zy), col)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ---------- Pixel font (port of Core.rb ptext) ----------
static func _char_index(ch: String) -> int:
	if _font_index.is_empty():
		for i in FONT_CHARS.length():
			_font_index[FONT_CHARS[i]] = i
	return _font_index.get(ch, _font_index["?"])

## Draws pixel text. color is a font colour name ("white", "gold", ...). Returns the width.
static func text(ci: CanvasItem, s: Variant, x: float, y: float, color: String = "white",
		scale: int = 1, align: float = 0.0, shadow: bool = true, alpha: float = 1.0) -> int:
	var st := str(s).to_upper()
	var w := TB.text_w(st, scale)
	var cx := roundf(x - w * align)
	var cy := roundf(y)
	var sheet := Img.t("font%d_%s" % [scale, color])
	var sh: Texture2D = Img.t("font%d_shadow" % scale) if shadow else null
	var mod := Color(1, 1, 1, alpha)
	var pxx := cx
	for i in st.length():
		var idx := _char_index(st[i])
		if idx > 0:
			var src := Rect2(idx * 4 * scale, 0, 3 * scale, 5 * scale)
			if sh != null:
				ci.draw_texture_rect_region(sh, Rect2(pxx, cy + scale, 3 * scale, 5 * scale), src, mod)
			ci.draw_texture_rect_region(sheet, Rect2(pxx, cy, 3 * scale, 5 * scale), src, mod)
		pxx += 4 * scale
	return w

static func wrap_text(s: String, max_w: int) -> PackedStringArray:
	var lines := PackedStringArray()
	var cur := ""
	for w in s.split(" ", false):
		var test := w if cur.is_empty() else cur + " " + w
		if TB.text_w(test) > max_w and not cur.is_empty():
			lines.append(cur)
			cur = w
		else:
			cur = test
	if not cur.is_empty():
		lines.append(cur)
	return lines

## Core.rb panel(): bordered box.
static func panel(ci: CanvasItem, x: float, y: float, w: float, h: float,
		border: String = "#5c5a78", fill: String = "#1a1423") -> void:
	ci.draw_rect(Rect2(x - 1, y - 1, w + 2, h + 2), TB.c("#140f1c"))
	ci.draw_rect(Rect2(x, y, w, h), TB.c(border))
	ci.draw_rect(Rect2(x + 1, y + 1, w - 2, h - 2), TB.c(fill))
