extends Node
## Texture cache (port of Core.rb `Img`). Autoload name: Img.
##
## RGSS sprites can be tinted toward a colour (Sprite#color, used for hit
## flashes and chill tints). Godot's modulate can only darken, so we build a
## white silhouette of each sprite on demand and draw it on top with the tint
## colour as modulate: src * (1 - a) + col * a, exactly what RGSS does.

const GFX := "res://assets/graphics/"

var _cache := {}
var _white := {}
var _missing := {}

func t(name: String) -> Texture2D:
	var tex = _cache.get(name)
	if tex != null:
		return tex
	var path := GFX + name + ".png"
	if ResourceLoader.exists(path):
		tex = load(path)
	else:
		if not _missing.has(name):
			_missing[name] = true
			push_warning("Img: missing graphic " + name)
		tex = _placeholder()
	_cache[name] = tex
	return tex

func has(name: String) -> bool:
	return _cache.has(name) or ResourceLoader.exists(GFX + name + ".png")

## White silhouette of a sprite (alpha preserved).
func white(name: String) -> Texture2D:
	var tex = _white.get(name)
	if tex != null:
		return tex
	var img := t(name).get_image()
	if img == null:
		tex = t(name)
	else:
		img = img.duplicate()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		for y in img.get_height():
			for x in img.get_width():
				var a := img.get_pixel(x, y).a
				img.set_pixel(x, y, Color(1, 1, 1, a))
		tex = ImageTexture.create_from_image(img)
	_white[name] = tex
	return tex

func _placeholder() -> Texture2D:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0, 1, 1))
	return ImageTexture.create_from_image(img)
