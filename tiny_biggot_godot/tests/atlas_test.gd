extends Node
## The ready-made sprite atlas (assets/atlas/sprites.res; see scripts/core/img.gd).
## Run: godot --headless --path . res://tests/atlas_test.tscn -- --no-save
##   1. The game loads the atlas that comes with the project rather than packing one at start-up.
##   2. That file holds exactly what packing the graphics folder gives now: the same names, places
##      and pixels, and its fingerprint is the graphics' fingerprint now.
##      (If not: a graphic was added or changed; run tools/bake_atlas.sh.)
##   3. Beside each sprite is its silhouette: the same picture in white with the same alpha,
##      and that is what the game hands out for a tint. The texture itself is the sprites only,
##      the size it has always been.
##   4. Every sprite handed out is its own file: the same size, the same pixels.
##   5. Without a ready-made file the game packs at start-up and makes the same silhouettes,
##      from memory.
##   6. A ready-made file is refused unless it was made from exactly these graphics: another
##      fingerprint (one byte of one graphic changed, a graphic renamed, added, removed or
##      imported another way), another set of names or another version, notes with anything
##      missing or of the wrong kind, and it is not used. With a graphic that has no imported
##      file there is no fingerprint, and no ready-made file is used at all.
##   7. The file the game writes for itself when none fits: written, read back, the same atlas;
##      refused, like the other, when the graphics are not the ones it was made from, or when
##      its pixels are no longer the ones that were written (a damaged file).
##   8. A graphic with smaller copies of itself (mipmaps) still gets its silhouette.
##   9. The fingerprint is taken from the files the engine would load: all of a graphic's
##      imported files and no one else's, whatever is left lying beside them.
## With --bake (and --no-bake, so the stale file is not loaded first) it writes the file
## instead: that is what tools/bake_atlas.sh runs.
## Prints "atlas test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL atlas: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	if DebugArgs.has("bake"):
		var err := Img.bake()
		print("[atlas] wrote %s: %s" % [Img.BAKED, error_string(err)])
		get_tree().quit(0 if err == OK else 1)
		return
	_check()
	print("atlas test: PASSED" if fails == 0 else "atlas test: FAILED (%d)" % fails)
	get_tree().quit(0 if fails == 0 else 1)

func _file_image(name: String) -> Image:
	var img: Image = load(Img.GFX + name + ".png").get_image().duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img

func _check() -> void:
	var names := Img.folder_names()
	var baked = load(Img.BAKED) if ResourceLoader.exists(Img.BAKED) else null
	if not (baked is Image) or not baked.has_meta("atlas"):
		fail("there is no ready-made atlas at %s: run tools/bake_atlas.sh" % Img.BAKED)
		return
	var m: Dictionary = baked.get_meta("atlas")
	var stamp := Img.graphics_stamp(names)
	# 1
	if Img.atlas_source != "baked":
		fail("the game did not load the ready-made atlas (it has: '%s')" % Img.atlas_source)
	var script: GDScript = load("res://scripts/core/img.gd")
	var fresh = script.new()
	fresh._build_atlas()
	if fresh.atlas_source != "baked" or fresh.atlas_count != Img.atlas_count:
		fail("a fresh start would not load the ready-made atlas (it has: '%s')" % fresh.atlas_source)
	fresh.free()
	# 2
	var packed: Dictionary = Img.pack(names)
	if packed.is_empty():
		fail("the graphics no longer fit one atlas")
		return
	if m.get("version") != Img.BAKE_VERSION or m.get("folder") != names:
		fail("the atlas was made for a different set of graphics (%d then, %d now): run tools/bake_atlas.sh" % [
			m.get("folder", PackedStringArray()).size(), names.size()])
	if m.get("stamp", "") != stamp:
		fail("the atlas's fingerprint is not that of the graphics now: run tools/bake_atlas.sh")
	if m.get("names") != packed["names"] or m.get("rects") != packed["rects"]:
		fail("the graphics would be packed differently now: run tools/bake_atlas.sh")
		return
	var src: Image = packed["image"]
	var h := src.get_height()
	var w: int = Img.ATLAS_W
	if baked.get_width() != w * 2 or baked.get_height() != h or m.get("white_dx") != w or baked.get_format() != Image.FORMAT_RGBA8:
		fail("the atlas is %dx%d, expected %dx%d with the silhouettes %d to the right" % [baked.get_width(), baked.get_height(), w * 2, h, w])
		return
	if baked.get_region(Rect2i(0, 0, w, h)).get_data() != src.get_data():
		fail("a graphic has changed since the atlas was made: run tools/bake_atlas.sh")
	# 3
	if baked.get_region(Rect2i(w, 0, w, h)).get_data() != Img.whiten(src).get_data():
		fail("the silhouettes are not the sprites in white")
	var pn: PackedStringArray = packed["names"]
	var pr: PackedInt32Array = packed["rects"]
	var alt = script.new()
	alt._adopt(src, pn, pr, 0, "built")       # 5: as the game is without a ready-made file
	var bad_size := 0
	var bad_pixels := 0
	var bad_white := 0
	var bad_alt := 0
	var whites := 0
	for i in pn.size():
		var name := pn[i]
		var r := Rect2i(pr[i * 4], pr[i * 4 + 1], pr[i * 4 + 2], pr[i * 4 + 3])
		# 4
		var tex := Img.t(name)
		var file := _file_image(name)
		if not (tex is AtlasTexture) or Vector2i(tex.get_size()) != file.get_size() or Rect2i(tex.region) != r:
			bad_size += 1
		if Img.image(name).get_data() != file.get_data():
			bad_pixels += 1
		# 3: the silhouette handed out is the sprite in white
		var wt := Img.white(name)
		var wi := wt.get_image()
		if wt is AtlasTexture or wi == null or wi.get_size() != file.get_size() or wi.get_data() != Img.whiten(file).get_data():
			bad_white += 1
		elif baked.get_region(Rect2i(r.position + Vector2i(w, 0), r.size)).get_data() != wi.get_data():
			bad_white += 1
		else:
			whites += 1
		# 5: made on demand from memory, it is the same picture
		var at: Texture2D = alt.white(name)
		var ai := at.get_image()
		if at is AtlasTexture or ai == null or ai.get_data() != Img.whiten(file).get_data():
			bad_alt += 1
	alt.free()
	if bad_size > 0:
		fail("%d sprites are not handed out at their file's size and place" % bad_size)
	if bad_pixels > 0:
		fail("%d sprites' pixels in memory differ from their files" % bad_pixels)
	if bad_white > 0:
		fail("%d silhouettes are not their sprites in white" % bad_white)
	var atlas_tex: Texture2D = (Img.t(pn[0]) as AtlasTexture).atlas
	if Vector2i(atlas_tex.get_size()) != Vector2i(w, h):
		fail("the atlas texture is %s, not the %dx%d it has always been" % [atlas_tex.get_size(), w, h])
	if bad_alt > 0:
		fail("%d silhouettes made on demand differ from the ready-made ones" % bad_alt)
	# A graphic outside the atlas still works (it is read back from its own texture).
	var vg := Img.image("vignette")
	if Img.t("vignette") is AtlasTexture or vg == null or vg.get_size() != Vector2i(Img.t("vignette").get_size()):
		fail("the vignette (outside the atlas) is not handed out as its own texture")
	_check_fingerprint(names, m, stamp)
	_check_own_file(script, names, packed, stamp)
	_check_mipmaps()
	_check_imported_folder()
	print("[atlas] %d graphics in the folder, %d in the atlas (%dx%d), %d silhouettes ready-made; %d bytes on disk" % [
		names.size(), pn.size(), w, h, whites, FileAccess.get_file_as_bytes(Img.BAKED).size()])

## 6: what the fingerprint notices, and what a ready-made file is refused for.
func _check_fingerprint(names: PackedStringArray, m: Dictionary, stamp: String) -> void:
	if stamp.length() != 32 or Img.graphics_stamp(names) != stamp:
		fail("the graphics have no fingerprint, or not the same one twice ('%s')" % stamp)
	# Made-up graphics: name -> { imported file name: bytes }.
	var files := {
		"a": { "a.ctex": PackedByteArray([1, 2, 3]) },
		"b": { "b.ctex": PackedByteArray([4, 5]) },
		"c": { "c.ctex": PackedByteArray(), "c.s3tc.ctex": PackedByteArray([7]) },
	}
	var of := func(n: String) -> Array:
		var out := []
		var d: Dictionary = files.get(n, {})
		var keys := d.keys()
		keys.sort()
		for k in keys:
			out.append([k, d[k]])
		return out
	var abc := PackedStringArray(["a", "b", "c"])
	var base: String = Img.stamp_of(abc, of)
	var seen := { base: "the graphics as they are" }
	var cases := {
		"one byte of one graphic changed": func(): files["b"]["b.ctex"] = PackedByteArray([4, 6]),
		"a byte moved from one graphic to the next": func():
			files["a"]["a.ctex"] = PackedByteArray([1, 2])
			files["b"]["b.ctex"] = PackedByteArray([3, 4, 5]),
		"a byte moved from one of a graphic's files to its other": func():
			files["c"]["c.ctex"] = PackedByteArray([7])
			files["c"]["c.s3tc.ctex"] = PackedByteArray(),
		"an imported file that was empty is not": func(): files["c"]["c.ctex"] = PackedByteArray([0]),
		"a graphic imported a second way as well": func(): files["a"]["a.s3tc.ctex"] = PackedByteArray([9]),
		"a graphic imported one way fewer": func(): files["c"].erase("c.ctex"),
		"the same bytes under another file name": func(): files["a"] = { "a.etc2.ctex": PackedByteArray([1, 2, 3]) },
		"a graphic emptied": func(): files["a"]["a.ctex"] = PackedByteArray(),
	}
	for what in cases:
		var keep := files.duplicate(true)
		cases[what].call()
		var st: String = Img.stamp_of(abc, of)
		if st == "" or seen.has(st):
			fail("the fingerprint does not notice: %s (same as: %s)" % [what, seen.get(st, "none at all")])
		seen[st] = what
		files.clear()          # in place: the readers above hold this dictionary, not the name
		files.merge(keep)
	files["d"] = { "d.ctex": PackedByteArray([8]) }
	files["bb"] = { "bb.ctex": PackedByteArray([4, 5]) }
	for other in [PackedStringArray(["a", "b"]), PackedStringArray(["a", "b", "c", "d"]), PackedStringArray(["a", "bb", "c"]),
			PackedStringArray(["b", "a", "c"])]:
		var st: String = Img.stamp_of(other, of)
		if st == "" or seen.has(st):
			fail("the fingerprint does not notice another set of names: %s" % [other])
		seen[st] = str(other)
	if Img.stamp_of(abc, of) != base:
		fail("the fingerprint is not the same for the same graphics")
	# A graphic with no imported file: no fingerprint at all (it could not notice that graphic changing).
	files["b"] = {}
	if Img.stamp_of(abc, of) != "":
		fail("there is a fingerprint though a graphic has no imported file")
	# The file's own notes.
	if not Img.bake_fits(m, names, stamp):
		fail("the ready-made atlas is refused though it was made from these graphics")
	var fewer := names.duplicate()
	fewer.remove_at(fewer.size() - 1)
	var changed := func(key: String, value) -> Dictionary:
		var d := m.duplicate()
		if value == null:
			d.erase(key)
		else:
			d[key] = value
		return d
	var short_rects: PackedInt32Array = m["rects"].slice(0, 40)
	var refused := {
		"another fingerprint": Img.bake_fits(m, names, stamp.reverse()),
		"no fingerprint to compare": Img.bake_fits(m, names, ""),
		"another set of names": Img.bake_fits(m, fewer, stamp),
		"another version": Img.bake_fits(changed.call("version", Img.BAKE_VERSION - 1), names, stamp),
		"a version that is not a number": Img.bake_fits(changed.call("version", str(Img.BAKE_VERSION)), names, stamp),
		"names of the wrong kind": Img.bake_fits(changed.call("folder", Array(names)), names, stamp),
		"a fingerprint of the wrong kind": Img.bake_fits(changed.call("stamp", 7), names, stamp),
		"notes with the places missing": Img.bake_fits(changed.call("rects", null), names, stamp),
		"fewer places than sprites": Img.bake_fits(changed.call("rects", short_rects), names, stamp),
		"silhouettes somewhere else": Img.bake_fits(changed.call("white_dx", 0), names, stamp),
		"no sum of its pixels": Img.bake_fits(changed.call("sum", null), names, stamp),
		"no notes": Img.bake_fits({}, names, stamp),
		"notes that are not notes": Img.bake_fits("atlas", names, stamp),
	}
	for what in refused:
		if refused[what]:
			fail("a ready-made atlas would be used despite: %s" % what)
	# The picture against its notes.
	var baked: Image = load(Img.BAKED)
	if not Img.picture_fits(baked, m):
		fail("the ready-made atlas's picture is refused though it is the one that was written")
	var dented: Image = baked.duplicate()
	dented.set_pixel(3, 3, Color(0.5, 0.25, 0.125, 1.0))
	var narrow := baked.get_region(Rect2i(0, 0, Img.ATLAS_W, baked.get_height()))
	var low := baked.get_region(Rect2i(0, 0, Img.ATLAS_W * 2, 64))
	var outside: PackedInt32Array = m["rects"].duplicate()
	outside[2] = Img.ATLAS_W + 1
	var with_mips: Image = baked.duplicate()
	with_mips.generate_mipmaps()
	var bad_pictures := {
		"one pixel that is not the one written": Img.picture_fits(dented, m),
		"a picture half as wide": Img.picture_fits(narrow, m),
		"a picture half as wide, the sum noted being its own": Img.picture_fits(narrow, changed.call("sum", hash(narrow.get_data()))),
		"a picture too low for its sprites": Img.picture_fits(low, m),
		"a picture too low for its sprites, the sum noted being its own": Img.picture_fits(low, changed.call("sum", hash(low.get_data()))),
		"a picture with smaller copies of itself added": Img.picture_fits(with_mips, changed.call("sum", hash(with_mips.get_data()))),
		"a sprite's place reaching outside the picture": Img.picture_fits(baked, changed.call("rects", outside)),
	}
	for what in bad_pictures:
		if bad_pictures[what]:
			fail("a ready-made atlas would be used despite: %s" % what)

## 7: the file the game writes for itself, and which file a start takes.
func _check_own_file(script: GDScript, names: PackedStringArray, packed: Dictionary, stamp: String) -> void:
	var path := "user://atlas_test_%d.res" % OS.get_process_id()
	var none := "user://atlas_test_none_%d.res" % OS.get_process_id()
	DirAccess.remove_absolute(path)
	# No file fits: the atlas is packed now and written for next time.
	var first = script.new()
	first._start(names, none, path, true)
	if first.atlas_source != "built" or not FileAccess.file_exists(path) or FileAccess.file_exists(path.get_basename() + ".tmp.res"):
		fail("with no ready-made file the game did not pack the atlas and write its own file (it has: '%s')" % first.atlas_source)
		first.free()
		return
	first.free()
	# The next start reads it back, and it is the same atlas as the one that comes with the project.
	var own = script.new()
	own._start(names, none, path, true)
	if own.atlas_source != "cached" or own.atlas_count != Img.atlas_count:
		fail("the game's own atlas file was written but is not read back (it has: '%s')" % own.atlas_source)
	else:
		var differ := 0
		for name in packed["names"]:
			if own.image(name).get_data() != Img.image(name).get_data() or own.white(name).get_image().get_data() != Img.white(name).get_image().get_data():
				differ += 1
			if Rect2i((own.t(name) as AtlasTexture).region) != Rect2i((Img.t(name) as AtlasTexture).region):
				differ += 1
		if differ > 0:
			fail("%d sprites differ between the game's own atlas file and the one that comes with the project" % differ)
		var theirs = load(Img.BAKED)
		var ours = ResourceLoader.load(path, "Image", ResourceLoader.CACHE_MODE_IGNORE)
		if not (ours is Image) or ours.get_data() != theirs.get_data() or ours.get_meta("atlas") != theirs.get_meta("atlas"):
			fail("the game's own atlas file does not hold what the one that comes with the project holds")
	own.free()
	# Where both fit, the game's own is the one taken (the other is not even read).
	var both = script.new()
	both._start(names, Img.BAKED, path, true)
	if both.atlas_source != "cached":
		fail("with its own file there and fitting, the game did not take it (it has: '%s')" % both.atlas_source)
	both.free()
	# Its own file made from other graphics: not used. The project's fits, and the stale one is removed...
	var err: Error = Img.save_bake(packed, names, stamp.reverse(), path)
	var stale = script.new()
	stale._start(names, Img.BAKED, path, true)
	if err != OK or stale.atlas_source != "baked" or FileAccess.file_exists(path):
		fail("a stale file of the game's own was not passed over and removed (it has: '%s')" % stale.atlas_source)
	stale.free()
	# ... or neither fits: packed now; left alone where the game may not write, replaced where it may.
	Img.save_bake(packed, names, stamp.reverse(), path)
	var before := FileAccess.get_md5(path)
	var ro = script.new()
	ro._start(names, none, path, false)
	if ro.atlas_source != "built" or FileAccess.get_md5(path) != before:
		fail("a start that may not write did not leave the game's own file alone (it has: '%s')" % ro.atlas_source)
	ro.free()
	var rw = script.new()
	rw._start(names, none, path, true)
	var after = script.new()
	after._start(names, none, path, false)
	if rw.atlas_source != "built" or after.atlas_source != "cached":
		fail("a stale file of the game's own was not replaced (first '%s', then '%s')" % [rw.atlas_source, after.atlas_source])
	rw.free()
	after.free()
	# A damaged file of the game's own (a pixel is not the one that was written, the notes say
	# nothing of it): not used, and replaced.
	var hurt: Image = ResourceLoader.load(path, "Image", ResourceLoader.CACHE_MODE_IGNORE)
	hurt.set_pixel(5, 5, Color(0.5, 0.25, 0.125, 1.0))
	ResourceSaver.save(hurt, path, ResourceSaver.FLAG_COMPRESS)
	var dmg = script.new()
	dmg._start(names, none, path, true)
	var healed = script.new()
	healed._start(names, none, path, false)
	if dmg.atlas_source != "built" or healed.atlas_source != "cached":
		fail("a damaged file of the game's own was not passed over and replaced (first '%s', then '%s')" % [dmg.atlas_source, healed.atlas_source])
	elif healed.image(packed["names"][0]).get_data() != Img.image(packed["names"][0]).get_data():
		fail("the file written in place of a damaged one is not right either")
	dmg.free()
	healed.free()
	# Neither file to be used (--no-bake): packed, nothing written.
	DirAccess.remove_absolute(path)
	var plain = script.new()
	plain._start(names, "", "", false)
	if plain.atlas_source != "built" or plain.atlas_count != Img.atlas_count or FileAccess.file_exists(path):
		fail("a start without ready-made files did not simply pack the atlas")
	plain.free()

## 8: a graphic that carries smaller copies of itself still gets a silhouette, the full-size one right.
func _check_mipmaps() -> void:
	var img := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	for y in 4:
		for x in 8:
			img.set_pixel(x, y, Color(x / 8.0, y / 4.0, 0.5, (x + y) / 11.0))
	var plain := Img.whiten(img)
	var mip: Image = img.duplicate()
	mip.generate_mipmaps()
	var got := Img.whiten(mip)
	if got == null or got.is_empty() or not got.has_mipmaps() or got.get_size() != Vector2i(8, 4):
		fail("a graphic with mipmaps gets no silhouette")
		return
	got.clear_mipmaps()
	if got.get_data() != plain.get_data():
		fail("the silhouette of a graphic with mipmaps is not the one it gets without")
	for y in 4:
		for x in 8:
			var c := plain.get_pixel(x, y)
			if c.r8 != 255 or c.g8 != 255 or c.b8 != 255 or c.a8 != img.get_pixel(x, y).a8:
				fail("a silhouette's pixel is not white with the sprite's alpha")
				return

## 9: the fingerprint read from a folder of imported files (a made-up one, laid out as the engine does).
func _check_imported_folder() -> void:
	var dir := "user://atlas_test_imported_%d/" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(dir)
	var put := func(file: String, bytes: Array) -> void:
		var f := FileAccess.open(dir + file, FileAccess.WRITE)
		f.store_buffer(PackedByteArray(bytes))
		f.close()
	var key := func(name: String) -> String:
		return "%s.png-%s" % [name, (Img.GFX + name + ".png").md5_text()]
	var ab := PackedStringArray(["a", "b.png-x"])     # a name that looks like the engine's own naming, too
	put.call(key.call("a") + ".ctex", [1, 2, 3])
	put.call(key.call("b.png-x") + ".ctex", [4, 5])
	var base: String = Img.graphics_stamp(ab, dir)
	if base.length() != 32:
		fail("a folder of imported files gives no fingerprint")
	var seen := { base: "the folder as it was" }
	# Things that are not these graphics' imported files: no difference.
	put.call(key.call("a") + ".md5", [9])                                              # the editor's note
	put.call("a.png-%s.ctex" % "res://elsewhere/a.png".md5_text(), [7, 7])             # another folder's graphic of that name
	put.call("c.png-%s.ctex" % (Img.GFX + "c.png").md5_text(), [8])                    # a graphic not asked about
	put.call("cc_hit.wav-%s.sample" % "res://assets/audio/se/cc_hit.wav".md5_text(), [6])
	if Img.graphics_stamp(ab, dir) != base:
		fail("the fingerprint changes with files that are not these graphics' imported files")
	# Things that are: each a different fingerprint.
	var steps := [
		["a graphic imported a second way as well", func(): put.call(key.call("a") + ".s3tc.ctex", [1])],
		["that second file changed", func(): put.call(key.call("a") + ".s3tc.ctex", [2])],
		["the first file changed, the one left lying there", func(): put.call(key.call("a") + ".ctex", [1, 2, 4])],
		["the first file gone", func(): DirAccess.remove_absolute(dir + key.call("a") + ".ctex")],
		["the other graphic changed", func(): put.call(key.call("b.png-x") + ".ctex", [4, 6])],
	]
	for st in steps:
		st[1].call()
		var got: String = Img.graphics_stamp(ab, dir)
		if got == "" or seen.has(got):
			fail("the fingerprint read from a folder does not notice: %s (same as: %s)" % [st[0], seen.get(got, "none at all")])
		seen[got] = st[0]
	# A graphic left with no imported file: no fingerprint.
	DirAccess.remove_absolute(dir + key.call("a") + ".s3tc.ctex")
	if Img.graphics_stamp(ab, dir) != "":
		fail("the folder gives a fingerprint though a graphic has no imported file in it")
	if Img.graphics_stamp(ab, dir + "nothing_here/") != "":
		fail("a folder that is not there gives a fingerprint")
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + f)
	DirAccess.remove_absolute(dir.trim_suffix("/"))
