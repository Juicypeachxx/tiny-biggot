extends Node
## The save file (Meta in scripts/core/meta.gd).
## Run: godot --headless --path . res://tests/save_test.tscn -- --no-save
##   1. A save is written and read back the same; nothing is left lying beside it.
##   2. The next save keeps the one before it as the backup.
##   3. A damaged save (cut short at any length, any single bit flipped, a block of zeroes, a block
##      written twice, not a save at all) is turned down without an error from the engine: the
##      backup is loaded instead, or a fresh game's progress if the backup is gone too. The
##      damaged file is not touched by loading it.
##   4. A damaged save is never moved into the backup: the next real save replaces it, and the
##      backup stays the last whole one.
##   5. Where the new save cannot be written, the save and the backup stay as they were.
##   6. A save in the format before October 2026 loads; one of those cut short is turned down.
##   7. A saved value of the wrong kind is left out; one missing keeps its default.
## Prints "save test: PASSED" or a FAIL line per problem.

const META := preload("res://scripts/core/meta.gd")
const DIR := "user://save_test/"

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL save: ", msg)

func _ready() -> void:
	_clean()
	_check()
	_clean()
	print("save test: PASSED" if fails == 0 else "save test: FAILED (%d)" % fails)
	get_tree().quit(0 if fails == 0 else 1)

func _clean() -> void:
	if DirAccess.dir_exists_absolute(DIR):
		for f in DirAccess.get_files_at(DIR):
			DirAccess.remove_absolute(DIR + f)
		for d in DirAccess.get_directories_at(DIR):
			DirAccess.remove_absolute(DIR + d)
	DirAccess.make_dir_recursive_absolute(DIR)

func _put(path: String, bytes: PackedByteArray) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()

func _bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()

## A save with some progress in it, told apart by n.
func _data(n: int) -> Dictionary:
	var blank: Node = META.new()
	var m: Dictionary = blank.meta.duplicate(true)
	blank.free()
	m["runs"] = 10 + n
	m["embers"] = 300 * n
	m["unlocked"] = { "hero_2": true, "relic_box": true }
	m["found"] = { "sword": true, "bow": true, "orb_%d" % n: true }
	m["tree"] = { "gaolbird": [2, 1, n % 5] }
	return { "opts": { "music": false, "fps": true }, "meta": m }

## What a fresh Meta holds after loading from these files.
func _load(path: String, backup: String) -> Node:
	var m: Node = META.new()
	m.load_from(path, backup)
	return m

func _check() -> void:
	var p := DIR + "a.save"
	var b := DIR + "a.save.bak"
	var d1 := _data(1)
	var d2 := _data(2)
	var d3 := _data(3)
	var fresh: Node = META.new()

	# 1 and 2
	if META.write_save_to(p, b, d1) != OK or META.read_save(p) != d1:
		fail("a save is not read back the same")
	if FileAccess.file_exists(b) or FileAccess.file_exists(p + ".tmp"):
		fail("the first save left a backup or a spare file")
	if META.write_save_to(p, b, d2) != OK or META.read_save(p) != d2 or META.read_save(b) != d1:
		fail("the second save did not keep the first as the backup")
	if FileAccess.file_exists(p + ".tmp"):
		fail("a spare file was left beside the save")
	var m := _load(p, b)
	if m.save_source != "save" or m.meta != d2["meta"] or m.opts["music"] != false or m.opts["fps"] != true:
		fail("a whole save does not load as written")
	m.free()

	# 3
	var whole := _bytes(p)
	var older := _bytes(b)
	var damaged := []
	for n in whole.size():
		damaged.append(whole.slice(0, n))
	for i in whole.size() * 8:
		var x := whole.duplicate()
		x[i >> 3] ^= 1 << (i & 7)
		damaged.append(x)
	var zeroes := whole.duplicate()
	for i in range(30, mini(zeroes.size(), 94)):
		zeroes[i] = 0
	damaged.append(zeroes)
	var twice := whole.slice(0, 60)
	twice.append_array(whole.slice(40))
	damaged.append(twice)
	damaged.append("this is not a save file at all".to_utf8_buffer())
	var bad_backup := 0
	var bad_fresh := 0
	var touched := 0
	for x in damaged:
		_put(p, x)
		m = _load(p, b)
		if m.save_source != "backup" or m.meta != d1["meta"]:
			bad_backup += 1
		m.free()
		DirAccess.rename_absolute(b, b + ".away")
		m = _load(p, b)
		if m.save_source != "fresh" or m.meta != fresh.meta or m.opts != fresh.opts:
			bad_fresh += 1
		m.free()
		DirAccess.rename_absolute(b + ".away", b)
		if _bytes(p) != x or _bytes(b) != older:
			touched += 1
	if bad_backup > 0:
		fail("%d of %d damaged saves did not load the backup" % [bad_backup, damaged.size()])
	if bad_fresh > 0:
		fail("%d of %d damaged saves without a backup did not start fresh" % [bad_fresh, damaged.size()])
	if touched > 0:
		fail("loading changed the files %d times" % touched)
	print("[save] %d damaged saves turned down (%d bytes long when whole)" % [damaged.size(), whole.size()])

	# 4: the save is damaged (cut short) when the next save comes
	_put(p, whole.slice(0, whole.size() / 2))
	if META.write_save_to(p, b, d3) != OK or META.read_save(p) != d3 or META.read_save(b) != d1:
		fail("a damaged save was moved into the backup, or the new save not written")

	# 5: the new save cannot be written (its spare file's name is taken by a folder)
	var now := _bytes(p)
	var bak := _bytes(b)
	DirAccess.make_dir_absolute(p + ".tmp")
	if META.write_save_to(p, b, _data(4)) == OK:
		fail("writing where it cannot be written reported OK")
	if _bytes(p) != now or _bytes(b) != bak:
		fail("a save that could not be written changed the files")
	DirAccess.remove_absolute(p + ".tmp")
	if META.read_save(p) != d3:
		fail("the save is not whole after a failed write")

	# 6: the old format (FileAccess.store_var)
	var old := DIR + "old.save"
	var f := FileAccess.open(old, FileAccess.WRITE)
	f.store_var(d2)
	f.close()
	var old_bytes := _bytes(old)
	if META.read_save(old) != d2:
		fail("a save in the old format does not load")
	var old_bad := 0
	for n in old_bytes.size():
		if not META.save_in(old_bytes.slice(0, n)).is_empty():
			old_bad += 1
	if old_bad > 0:
		fail("%d old-format saves cut short were taken" % old_bad)
	if META.write_save_to(old, old + ".bak", d3) != OK or META.read_save(old + ".bak") != d2:
		fail("an old-format save was not kept as the backup when the next save came")

	# 7: values of the wrong kind, values missing, a fraction where a whole number was
	var odd := { "opts": { "music": 5, "sfx": false }, "meta": { "runs": "many", "embers": 12.0, "unlocked": [1], "wins": 4 } }
	META.write_save_to(DIR + "odd.save", DIR + "odd.save.bak", odd)
	m = _load(DIR + "odd.save", DIR + "odd.save.bak")
	if m.opts["music"] != true or m.opts["sfx"] != false:
		fail("options of the wrong kind were taken, or right ones left out")
	if m.meta["runs"] != 0 or m.meta["embers"] != 12 or not (m.meta["unlocked"] is Dictionary) or m.meta["wins"] != 4:
		fail("progress of the wrong kind was taken, or right ones left out: %s" % [m.meta])
	if m.meta["kills"] != 0 or not (m.meta["found_w"] is Dictionary):
		fail("progress missing from the save did not keep its default")
	m.free()

	# no save at all
	m = _load(DIR + "none.save", DIR + "none.save.bak")
	if m.save_source != "" or m.meta != fresh.meta:
		fail("no save at all does not start fresh")
	m.free()
	fresh.free()
