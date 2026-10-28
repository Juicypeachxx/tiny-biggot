class_name Moves
extends RefCounted
## 67.2 (his references, 28 Oct: "the animation and movment, the aliveness of stages and mobs"): the
## commonest monsters walk. Each has a strip, assets/graphics_hd/anim/<picture>.png
## (resprite/tools/anim_pl.py, kind "mob"): row 0 the walk, every frame the size of the picture itself,
## so a frame stands in for it (the same feet, the same box). Only how it looks: the rules never see a
## frame. A frame is cut from its strip the first time it is drawn and kept in Img's cache under its own
## name, so Gfx draws it (and its white silhouette) like any other picture. Bosses keep their pictures
## (his word: "bosses are good").

const DIR := "res://assets/graphics_hd/anim/"
const FPS := 10.0

static var _frames := {}   # picture -> frames in its walk (0: no strip)

## How many frames the picture's walk has (0: it has none).
static func count(pic: String) -> int:
	if _frames.has(pic):
		return _frames[pic]
	var n := 0
	var path := DIR + pic + ".png"
	if ResourceLoader.exists(path):
		var strip: Texture2D = load(path)
		var own := Img.t(pic)
		var img := strip.get_image()
		if img != null:
			if img.is_compressed():
				img.decompress()
			var w := own.get_width() * TB.D
			var h := own.get_height() * TB.D
			n = img.get_width() / w if w > 0 and img.get_height() >= h else 0
			for i in n:
				var tex := ImageTexture.create_from_image(img.get_region(Rect2i(i * w, 0, w, h)))
				tex.set_size_override(Vector2i(own.get_width(), own.get_height()))
				Img._cache[_name(pic, i)] = tex
	_frames[pic] = n
	return n

static func _name(pic: String, i: int) -> String:
	return "%s@w%d" % [pic, i]

## The picture to draw for a monster: a frame of its walk while it moves, else its own.
static func mob(e: Enemy, pic: String) -> String:
	if not GameData.rogues() or e.is_boss() or e.hidden or e.stun_t > 0.0 or absf(e.vx) + absf(e.vy) < 4.0:
		return pic
	var n := count(pic)
	if n == 0:
		return pic
	return _name(pic, floori(e.anim * FPS + float(e.uid % 3)) % n)
