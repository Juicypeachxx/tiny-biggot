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

## Sprite atlas: every small graphic (sprites, icons, font sheets) is packed
## into one texture at startup and handed out as AtlasTextures. Drawing then
## stays on one texture, so the renderer can batch hundreds of shots, coins,
## foes and damage numbers into a few draw calls instead of one per texture
## switch (the main GPU cost in big fights on iPad). Looks identical:
## nearest filtering and 1 px transparent padding between sprites.
const ATLAS_W := 1024
const ATLAS_MAX_W := 1024
const ATLAS_MAX_H := 96
const ATLAS_SKIP := ["vignette"]
var _atlas_built := false
var atlas_count := 0

func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	_build_atlas()
	if OS.is_debug_build() and "--perf" in OS.get_cmdline_user_args():
		print("[perf] sprite atlas: %d graphics packed in %d ms" % [atlas_count, Time.get_ticks_msec() - t0])

func _build_atlas() -> void:
	if _atlas_built:
		return
	_atlas_built = true
	if OS.has_feature("no_atlas") or "--no-atlas" in OS.get_cmdline_user_args():
		return
	var names := {}
	for f in DirAccess.get_files_at(GFX):
		var base := f.trim_suffix(".import").trim_suffix(".remap")
		if base.ends_with(".png"):
			names[base.trim_suffix(".png")] = true
	var imgs := []
	for name in names:
		if name in ATLAS_SKIP:
			continue
		var tex = load(GFX + name + ".png")
		if tex == null:
			continue
		var w: int = tex.get_width()
		var h: int = tex.get_height()
		if w > ATLAS_MAX_W or h > ATLAS_MAX_H:
			continue
		var img: Image = tex.get_image()
		if img == null:
			continue
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		imgs.append([name, img])
	# Shelf packing, tallest first.
	imgs.sort_custom(func(a, b): return a[1].get_height() > b[1].get_height() or (a[1].get_height() == b[1].get_height() and a[0] < b[0]))
	var spots := []
	var x := 0
	var y := 0
	var shelf := 0
	for it in imgs:
		var img: Image = it[1]
		var w := img.get_width() + 2
		var h := img.get_height() + 2
		if x + w > ATLAS_W:
			x = 0
			y += shelf
			shelf = 0
		spots.append(Vector2i(x + 1, y + 1))
		x += w
		shelf = maxi(shelf, h)
	var total_h := y + shelf
	var ah := 64
	while ah < total_h:
		ah *= 2
	if ah > 4096:
		push_warning("Img: atlas too tall, using separate textures")
		return
	var atlas := Image.create(ATLAS_W, ah, false, Image.FORMAT_RGBA8)
	for i in imgs.size():
		var img: Image = imgs[i][1]
		atlas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), spots[i])
	var atex := ImageTexture.create_from_image(atlas)
	for i in imgs.size():
		var at := AtlasTexture.new()
		at.atlas = atex
		at.region = Rect2(spots[i], imgs[i][1].get_size())
		_cache[imgs[i][0]] = at
	atlas_count = imgs.size()

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
