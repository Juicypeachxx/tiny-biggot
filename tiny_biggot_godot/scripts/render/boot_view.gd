extends Node2D
## Stage 1 boot screen: proves textures, the pixel font and input load.
## Replaced by the title menu in a later stage.

# Keep a reference: a texture freed after _draw() renders as white.
var cover: Texture2D = preload("res://assets/titles/Cover.png")

func _draw() -> void:
	draw_rect(Rect2(0, 0, TB.SW, TB.SH), TB.c("#0d0a12"))
	var w := cover.get_width() * 0.5
	var h := cover.get_height() * 0.5
	draw_texture_rect(cover, Rect2((TB.SW - w) / 2, 24, w, h), false)
	Gfx.text(self, "TINY BIGGOT", TB.SW / 2, 228, "orange", 2, 0.5)
	Gfx.text(self, "GODOT PORT - STAGE 1 SKELETON", TB.SW / 2, 248, "bone", 1, 0.5)
	var held := []
	for a in Keys.ACTIONS:
		if Keys.pressed(a):
			held.append(String(a).replace("_", " "))
	Gfx.text(self, "HELD: " + (", ".join(held) if held.size() > 0 else "-"), TB.SW / 2, 262, "grey", 1, 0.5)
	Gfx.sp(self, "hexer", TB.SW / 2 + sin(G.time * 3) * 40, 220)
