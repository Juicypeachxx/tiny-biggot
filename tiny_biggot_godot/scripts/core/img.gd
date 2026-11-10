extends Node
## Texture cache (port of Core.rb `Img`). Autoload name: Img.
##
## RGSS sprites can be tinted toward a colour (Sprite#color, used for hit
## flashes and chill tints). Godot's modulate can only darken, so every sprite
## has a white silhouette that is drawn on top with the tint colour as
## modulate: src * (1 - a) + col * a, exactly what RGSS does.

const GFX := "res://assets/graphics/"
## 59.1 (V2, his test, 22 Oct): the new pictures, by the same names (resprite/tools/hd_import.py).
## Each is today's picture's size times 1, 2 or 4 (a guardian, drawn at twice its size, has four of
## its pixels to one of today's). The game draws every picture at today's size: a new one shows
## its finer pixels, because the screen has TB.D pixels to each of the game's. The pictures with
## no new one (the font, dots, glows, shadows) are drawn as they are, each pixel D times.
## A floor's texture (<kit>_floor) has no picture of today's: it is at D, and repeats.
const HD := "res://assets/graphics_hd/"

var _cache := {}
var _white := {}
var _missing := {}

## Sprite atlas: every small graphic (sprites, icons, font sheets) sits in one
## texture and is handed out as AtlasTextures. Drawing then stays on one
## texture, so the renderer can batch hundreds of shots, coins, foes and damage
## numbers into a few draw calls instead of one per texture switch (the main
## GPU cost in big fights on iPad). Looks identical: nearest filtering and 1 px
## transparent padding between sprites.
##
## 59.1: the atlas holds every picture at TB.D pixels to each of the game's (its new picture, or
## today's drawn D times; a guardian's at four, too big for it, is a texture of its own). Its
## texture says it is D times smaller than it is, and so does each picture's place in it: the game
## draws and measures every picture in its own pixels as before, and the finer pixels show on the
## screen. Places in the ready-made file and in _rects are in the atlas's own pixels.
##
## The atlas is made ahead of time and loaded as one file: the sprites on the
## left, a white silhouette of each the same distance to the right. The left
## half becomes the texture, exactly the one that used to be packed at
## start-up; the right half stays in memory and a sprite's silhouette is cut
## from it the first time it is tinted. So starting the game does not decode
## 800 graphics, hand each to the graphics card and read it back, and a tint
## in the middle of a fight costs a small copy instead of reading the whole
## atlas back from the graphics card (on a phone or tablet that is a stall of
## a frame or more each time).
##
## The file is only used if it was made from exactly the graphics this copy of
## the game would load. It carries a fingerprint: the name of every graphic and
## the bytes of every file the engine has imported it into. That is worked out
## again and compared every time the game starts (the imported files are small
## and are only read, not decoded). Two files are tried:
##   BAKED   comes with the project (tools/bake_atlas.sh writes it);
##   CACHED  is written by the game itself, in its own data folder.
## If neither fits (a graphic was added, removed or redrawn, or this device
## stores imported graphics differently from the machine BAKED was made on),
## the atlas is packed at start-up from the separate graphics as it always
## was: slower to start, the same pictures, and silhouettes are worked out from
## the copy kept in memory. The game then writes CACHED, so the next start is
## quick again. Nothing has to be run by hand, and a picture that is out of
## date is not shown.
##
## Neither file is handed to the engine to make sense of. Each is read as plain
## bytes that begin with a checksum of all the rest, and nothing in it is
## unpacked or used until the checksum has been found right. A file that was
## cut short when it was copied, written to a full disk or damaged later is
## therefore turned down like one that does not fit, and the game's own is
## written again. (The engine's own file reader stops the whole game on some
## damaged files, which is why it is not used here.)
const BAKED := "res://assets/atlas/sprites.tbatlas"
const CACHED := "user://sprite_atlas.tbatlas"
## Raise this whenever pack(), whiten() or what a ready-made file holds changes: the files
## games have already written for themselves are then made again. (The sizes below are part
## of the fingerprint, so changing one of those needs nothing more.)
const BAKE_VERSION := 6
## A ready-made file: these four letters, 16 bytes of checksum (MD5 of everything after them),
## the size of the notes once unpacked (4 bytes), then the notes, packed.
const FILE_MAGIC := "TBAT"
const FILE_HEAD := 24
const FILE_MAX := 1 << 28       # no notes unpack to more than this (256 MB; 59.1: about 80 at double detail)
const ATLAS_W := 2048          # in the game's pixels: the texture is TB.D times as wide
const ATLAS_MAX_W := 1024
const ATLAS_MAX_H := 96
const ATLAS_SKIP := ["vignette"]
var _atlas_built := false
var atlas_count := 0
## How the atlas came to be: "baked" (the file that comes with the project), "cached" (the file
## the game wrote itself), "built" (packed at start-up) or "" (none).
var atlas_source := ""
var _atlas_tex: Texture2D = null
var _atlas_img: Image = null   # the atlas's pixels, kept in memory (with the silhouettes beside them when ready-made)
var _rects := {}            # name -> Rect2i inside the atlas
var _white_dx := 0          # a sprite's silhouette is this far to its right in _atlas_img (0: not there)
var _stamp_ms := 0          # what working out the fingerprint cost at start-up

func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	_build_atlas()
	if "--perf" in OS.get_cmdline_user_args():
		print("[perf] sprite atlas: %d graphics, %s in %d ms (of which the fingerprint: %d ms)" % [
			atlas_count, atlas_source, Time.get_ticks_msec() - t0, _stamp_ms])

## The name of every graphic in the folder, sorted. (An exported game lists them as *.png.import.)
func folder_names() -> PackedStringArray:
	var names := {}
	for f in DirAccess.get_files_at(GFX):
		var base := f.trim_suffix(".import").trim_suffix(".remap")
		if base.ends_with(".png"):
			names[base.trim_suffix(".png")] = true
	var out := PackedStringArray(names.keys())
	out.sort()
	return out

func _build_atlas() -> void:
	if _atlas_built:
		return
	_atlas_built = true
	var args := OS.get_cmdline_user_args()
	if OS.has_feature("no_atlas") or "--no-atlas" in args:
		return
	# Test runs: --no-bake packs at start-up whatever files there are; --no-save neither reads
	# nor writes the game's own file, so a run depends on the project alone; and a run with no
	# window (the automatic checks) writes nothing.
	var ready_made := not "--no-bake" in args
	var own_file := ready_made and not "--no-save" in args
	_start(folder_names(), BAKED if ready_made else "", CACHED if own_file else "",
		own_file and DisplayServer.get_name() != "headless", "--perf" in args)

## Takes an atlas into use for these graphics: the game's own file (`cached`) if it fits, else
## the one that comes with the project (`baked`), else packs one now and, if it may, writes it
## as the game's own file. An empty path: that file is not to be used.
func _start(names: PackedStringArray, baked: String, cached: String, may_write: bool, say: bool = false) -> void:
	var stamp := ""
	if baked != "" or cached != "":
		var t0 := Time.get_ticks_msec()
		stamp = graphics_stamp(names)
		_stamp_ms = Time.get_ticks_msec() - t0
	# The game's own file first: if there is one, the file that comes with the project did not
	# fit the last time, and there is no point reading that one only to turn it down.
	var own_there := cached != "" and FileAccess.file_exists(cached)
	if own_there and _load_baked(cached, names, stamp, "cached"):
		return
	if baked != "" and _load_baked(baked, names, stamp, "baked"):
		if own_there and may_write:
			DirAccess.remove_absolute(cached)      # made from other graphics: of no use any more
		return
	var packed := pack(names)
	if packed.is_empty():
		return
	_adopt(packed["image"], packed["names"], packed["rects"], 0, "built")
	# Not without a fingerprint (the file could never be told to fit), and not an empty atlas
	# (a project whose graphics have not been imported yet).
	if may_write and cached != "" and stamp != "" and not packed["names"].is_empty():
		var err := save_bake(packed, names, stamp, cached)
		if say:
			print("[perf] sprite atlas: no ready-made file fits these graphics; wrote %s for next time: %s" % [cached, error_string(err)])

## Where the engine keeps the files it imports graphics into.
static func imported_dir() -> String:
	var hidden: bool = ProjectSettings.get_setting("application/config/use_hidden_project_data_directory", true)
	return "res://.godot/imported/" if hidden else "res://godot/imported/"

## A fingerprint of the graphics as the game would load them now: every name in the folder and
## the bytes of every file the engine has imported it into. Empty if a graphic has no imported
## file at all (the fingerprint would then not change when that graphic does, so no ready-made
## atlas is used).
##
## The engine names an imported file NAME.png-<md5 of the graphic's path>.<kind>. A graphic
## has one (kind "ctex"), or one per kind of graphics chip if it is stored packed for the chip;
## all that are there are taken, since which one is loaded is the engine's choice.
func graphics_stamp(names: PackedStringArray, dir: String = imported_dir()) -> String:
	if not DirAccess.dir_exists_absolute(dir):
		return ""
	var by_key := {}
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".md5"):      # the editor's own note about an import; not in an exported game
			continue
		var i := f.rfind(".png-")
		if i < 0 or f.length() < i + 38:
			continue
		var key := f.substr(0, i + 37)
		if by_key.has(key):
			by_key[key].append(f)
		else:
			by_key[key] = [f]
	var files_of := func(name: String) -> Array:
		var out := []
		for folder in [GFX, HD]:      # 59.1: and its new picture's, if it has one
			var files: Array = by_key.get("%s.png-%s" % [name, (folder + name + ".png").md5_text()], [])
			files.sort()
			for f in files:
				out.append([f, FileAccess.get_file_as_bytes(dir + f)])
		return out
	return stamp_of(names, files_of)

## The fingerprint of these names, given each one's imported files as [file name, bytes] pairs.
## It also covers how the atlas is packed, so a ready-made file made by other rules never fits.
static func stamp_of(names: PackedStringArray, files_of: Callable) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(("atlas %d: %d wide, graphics up to %dx%d, without %s, %d pixels to the game's\n" % [BAKE_VERSION, ATLAS_W,
		ATLAS_MAX_W, ATLAS_MAX_H, ATLAS_SKIP, TB.D]).to_utf8_buffer())
	for name in names:
		var files: Array = files_of.call(name)
		if files.is_empty():
			return ""
		ctx.update(("%s: %d\n" % [name, files.size()]).to_utf8_buffer())
		for f in files:
			var bytes: PackedByteArray = f[1]
			ctx.update(("%s: %d\n" % [f[0], bytes.size()]).to_utf8_buffer())
			if not bytes.is_empty():
				ctx.update(bytes)
	return ctx.finish().hex_encode()

## Whether a ready-made atlas, by its notes, was made from exactly these graphics and holds a
## whole picture. Nothing about the notes is taken on trust.
static func bake_fits(m, names: PackedStringArray, stamp: String) -> bool:
	if not (m is Dictionary) or stamp == "":
		return false
	var version = m.get("version")
	var folder = m.get("folder")
	var made_from = m.get("stamp")
	var packed = m.get("names")
	var rects = m.get("rects")
	var dx = m.get("white_dx")
	var w = m.get("width")
	var h = m.get("height")
	var px = m.get("pixels")
	if not (version is int) or version != BAKE_VERSION:
		return false
	if not (folder is PackedStringArray) or folder != names:
		return false
	if not (made_from is String) or made_from != stamp:
		return false
	if not (packed is PackedStringArray) or not (rects is PackedInt32Array) or rects.size() != packed.size() * 4:
		return false
	if not (dx is int) or dx != ATLAS_W * TB.D or not (w is int) or w != ATLAS_W * TB.D * 2 or not (h is int) or h < 1 or h > 4096 or h % TB.D != 0:
		return false
	return px is PackedByteArray and px.size() == w * h * 4

## Whether every sprite's place in the notes lies inside the picture's sprite half, on whole pixels
## of the game's (TB.D of the atlas's).
static func picture_fits(m: Dictionary) -> bool:
	var h: int = m["height"]
	var rects: PackedInt32Array = m["rects"]
	var i := 0
	while i < rects.size():
		if rects[i] < 0 or rects[i + 1] < 0 or rects[i + 2] < 1 or rects[i + 3] < 1 or rects[i] + rects[i + 2] > ATLAS_W * TB.D or rects[i + 1] + rects[i + 3] > h:
			return false
		if rects[i] % TB.D != 0 or rects[i + 1] % TB.D != 0 or rects[i + 2] % TB.D != 0 or rects[i + 3] % TB.D != 0:
			return false
		i += 4
	return true

static func _md5(bytes: PackedByteArray) -> PackedByteArray:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	if not bytes.is_empty():
		ctx.update(bytes)
	return ctx.finish()

## A ready-made atlas (its notes, the picture's pixels among them) as the bytes of its file.
static func file_bytes(m: Dictionary) -> PackedByteArray:
	var raw := var_to_bytes(m)
	var rest := PackedByteArray()
	rest.resize(4)
	rest.encode_u32(0, raw.size())
	rest.append_array(raw.compress(FileAccess.COMPRESSION_ZSTD))
	var out := FILE_MAGIC.to_ascii_buffer()
	out.append_array(_md5(rest))
	out.append_array(rest)
	return out

## The notes in the bytes of a ready-made file, or nothing if the bytes are not, to the last
## one, what file_bytes once made. Until the checksum has been found right nothing is unpacked.
static func notes_in(bytes: PackedByteArray) -> Dictionary:
	if bytes.size() <= FILE_HEAD or bytes.slice(0, 4) != FILE_MAGIC.to_ascii_buffer():
		return {}
	if _md5(bytes.slice(20)) != bytes.slice(4, 20):
		return {}
	var size := bytes.decode_u32(20)
	if size < 1 or size > FILE_MAX:
		return {}
	var raw := bytes.slice(FILE_HEAD).decompress(size, FileAccess.COMPRESSION_ZSTD)
	if raw.size() != size:
		return {}
	var m = bytes_to_var(raw)
	return m if m is Dictionary else {}

## The notes in a ready-made file; nothing if it is not there or not whole.
static func read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	return notes_in(FileAccess.get_file_as_bytes(path))

## Writes a file whole or not at all: under another name first, read back and compared byte for
## byte (a full disk does not always say so), then moved into place.
static func write_whole(path: String, bytes: PackedByteArray) -> Error:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_buffer(bytes)
	var err := f.get_error()
	f.close()
	if err == OK and FileAccess.get_file_as_bytes(tmp) != bytes:
		err = ERR_FILE_CANT_WRITE
	if err == OK:
		err = DirAccess.rename_absolute(tmp, path)
	if err != OK:
		DirAccess.remove_absolute(tmp)
	return err

## Loads a ready-made atlas if its file is whole and was made from exactly the graphics the game
## would load now.
func _load_baked(path: String, names: PackedStringArray, stamp: String, source: String) -> bool:
	if stamp == "":
		return false
	var m := read_file(path)
	if not bake_fits(m, names, stamp) or not picture_fits(m):
		return false
	var img := Image.create_from_data(m["width"], m["height"], false, Image.FORMAT_RGBA8, m["pixels"])
	_adopt(img, m["names"], m["rects"], m["white_dx"], source)
	return true

## Packs the small graphics into one image (shelves, tallest first), each at TB.D pixels to the
## game's with a game pixel clear round it. Returns the image, the names packed and their rects
## (in the image's pixels) as x, y, w, h runs; empty if they do not fit.
func pack(names: PackedStringArray) -> Dictionary:
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
		var img := detail(name, tex)
		if img == null:
			continue
		imgs.append([name, img])
	# Shelf packing, tallest first.
	imgs.sort_custom(func(a, b): return a[1].get_height() > b[1].get_height() or (a[1].get_height() == b[1].get_height() and a[0] < b[0]))
	var d := TB.D
	var aw := ATLAS_W * d
	var spots := []
	var x := 0
	var y := 0
	var shelf := 0
	for it in imgs:
		var img: Image = it[1]
		var w := img.get_width() + 2 * d
		var h := img.get_height() + 2 * d
		if x + w > aw:
			x = 0
			y += shelf
			shelf = 0
		spots.append(Vector2i(x + d, y + d))
		x += w
		shelf = maxi(shelf, h)
	var total_h := y + shelf
	var ah := (total_h + 63) / 64 * 64      # 59.1: no longer a power of two (4096 x 2432, not 4096 x 4096)
	if ah > 4096:
		push_warning("Img: atlas too tall, using separate textures")
		return {}
	var atlas := Image.create(aw, ah, false, Image.FORMAT_RGBA8)
	var out_names := PackedStringArray()
	var out_rects := PackedInt32Array()
	for i in imgs.size():
		var img: Image = imgs[i][1]
		atlas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), spots[i])
		out_names.append(imgs[i][0])
		out_rects.append_array([spots[i].x, spots[i].y, img.get_width(), img.get_height()])
	return { "image": atlas, "names": out_names, "rects": out_rects }

## A picture at TB.D pixels to each of the game's, as the atlas holds it: its new picture (at D, or
## at today's size drawn D times), else today's drawn D times. Null for a new picture finer than
## D (a guardian's, at four): it is a texture of its own (t), with all its pixels.
func detail(name: String, base: Texture2D) -> Image:
	var w := base.get_width()
	var h := base.get_height()
	var src: Image
	if ResourceLoader.exists(HD + name + ".png"):
		var hd: Texture2D = load(HD + name + ".png")
		if hd == null or hd.get_width() > w * TB.D:
			return null
		src = hd.get_image()
	else:
		src = base.get_image()
	if src == null:
		return null
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	if src.get_width() != w * TB.D or src.get_height() != h * TB.D:
		src.resize(w * TB.D, h * TB.D, Image.INTERPOLATE_NEAREST)
	return src

## Takes an atlas image into use: one texture (the sprites; not the silhouettes beside them),
## and a region of it per name. The texture and the regions are in the game's pixels (TB.D of
## the image's to each), so every picture is drawn and measured at today's size.
func _adopt(img: Image, names: PackedStringArray, rects: PackedInt32Array, white_dx: int, source: String) -> void:
	_atlas_img = img
	var sprites := img.get_region(Rect2i(0, 0, white_dx, img.get_height())) if white_dx > 0 else img
	var tex := ImageTexture.create_from_image(sprites)
	tex.set_size_override(Vector2i(sprites.get_width() / TB.D, sprites.get_height() / TB.D))
	_atlas_tex = tex
	_white_dx = white_dx
	for i in names.size():
		var r := Rect2i(rects[i * 4], rects[i * 4 + 1], rects[i * 4 + 2], rects[i * 4 + 3])
		_rects[names[i]] = r
		var at := AtlasTexture.new()
		at.atlas = _atlas_tex
		at.region = Rect2(Vector2(r.position) / TB.D, Vector2(r.size) / TB.D)
		_cache[names[i]] = at
	atlas_count = names.size()
	atlas_source = source

## Writes the atlas that comes with the project (the sprites, and their silhouettes beside them)
## from the graphics in the folder now. Run by tools/bake_atlas.sh.
func bake() -> Error:
	var names := folder_names()
	var packed := pack(names)
	if packed.is_empty():
		return ERR_CANT_CREATE
	return save_bake(packed, names, graphics_stamp(names), BAKED)

## Writes a packed atlas (see pack) as a ready-made file.
func save_bake(packed: Dictionary, names: PackedStringArray, stamp: String, path: String) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	# Can a file be written there at all? Asked first, so that where it cannot the silhouettes
	# below are not worked out for nothing every time the game starts.
	var probe := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if probe == null:
		return FileAccess.get_open_error()
	probe.close()
	var src: Image = packed["image"]
	var h := src.get_height()
	var aw := ATLAS_W * TB.D
	var out := Image.create(aw * 2, h, false, Image.FORMAT_RGBA8)
	out.blit_rect(src, Rect2i(0, 0, aw, h), Vector2i.ZERO)
	out.blit_rect(whiten(src), Rect2i(0, 0, aw, h), Vector2i(aw, 0))
	return write_whole(path, file_bytes({ "version": BAKE_VERSION, "folder": names, "stamp": stamp, "names": packed["names"],
		"rects": packed["rects"], "white_dx": aw, "width": aw * 2, "height": h, "pixels": out.get_data() }))

func t(name: String) -> Texture2D:
	var tex = _cache.get(name)
	if tex != null:
		return tex
	var path := GFX + name + ".png"
	if ResourceLoader.exists(HD + name + ".png"):
		tex = _own(load(HD + name + ".png"), load(path) if ResourceLoader.exists(path) else null)
	elif ResourceLoader.exists(path):
		tex = load(path)
	else:
		if not _missing.has(name):
			_missing[name] = true
			push_warning("Img: missing graphic " + name)
		tex = _placeholder()
	_cache[name] = tex
	return tex

## A new picture as a texture of its own (not in the atlas: a guardian's at four, a floor, or
## everything when there is no atlas), drawn and measured at today's picture's size (a floor:
## TB.D times smaller than it is), all its pixels kept.
func _own(hd: Texture2D, base: Texture2D) -> Texture2D:
	var w := base.get_width() if base != null else hd.get_width() / TB.D
	var h := base.get_height() if base != null else hd.get_height() / TB.D
	if hd.get_width() == w and hd.get_height() == h:
		return hd
	var img := hd.get_image()
	if img == null:
		return hd
	if img.is_compressed():
		img.decompress()
	var tex := ImageTexture.create_from_image(img)
	tex.set_size_override(Vector2i(w, h))
	return tex

func has(name: String) -> bool:
	return _cache.has(name) or ResourceLoader.exists(GFX + name + ".png") or ResourceLoader.exists(HD + name + ".png")

## A sprite's pixels (RGBA8), all of them (59.1: TB.D or more to each of the game's when it has a
## new picture). Sprites in the atlas are cut from the copy kept in memory; only a graphic outside
## it is read back from its texture.
func image(name: String) -> Image:
	var r = _rects.get(name)
	if r != null and _atlas_img != null:
		return _atlas_img.get_region(r)
	var img := t(name).get_image()
	if img == null:
		return null
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img

## White silhouette of a sprite (alpha preserved).
func white(name: String) -> Texture2D:
	var tex = _white.get(name)
	if tex != null:
		return tex
	var r = _rects.get(name)
	var drawn := t(name)      # the size it is drawn at: the silhouette is drawn over it at that size
	if r != null and _white_dx > 0:
		# Ready-made: cut from the copy in memory.
		tex = ImageTexture.create_from_image(_atlas_img.get_region(Rect2i(r.position.x + _white_dx, r.position.y, r.size.x, r.size.y)))
	else:
		var img := image(name)
		tex = ImageTexture.create_from_image(whiten(img)) if img != null else drawn
	if tex is ImageTexture and (tex.get_width() != drawn.get_width() or tex.get_height() != drawn.get_height()):
		tex.set_size_override(Vector2i(drawn.get_width(), drawn.get_height()))
	_white[name] = tex
	return tex

## The same picture (RGBA8) with every pixel white and its alpha kept. (A graphic imported with
## smaller copies of itself, "mipmaps", keeps them: they are pixels like the rest.)
static func whiten(img: Image) -> Image:
	var d := img.get_data()
	var n := d.size()
	var w := PackedByteArray()
	w.resize(n)
	w.fill(255)
	var i := 3
	while i < n:
		w[i] = d[i]
		i += 4
	return Image.create_from_data(img.get_width(), img.get_height(), img.has_mipmaps(), Image.FORMAT_RGBA8, w)

func _placeholder() -> Texture2D:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0, 1, 1))
	return ImageTexture.create_from_image(img)
