extends Node
## Options and between-run progress (port of Core.rb `$opts` / `$meta` and
## load_save / write_save). Autoload name: Meta.

const SAVE_FILE := "user://tiny_biggot.save"
## The save before the last one, kept whole: used when the save itself is damaged.
const SAVE_BACKUP := "user://tiny_biggot.save.bak"
## The save file: "TBSV", an MD5 of everything after it, then var_to_bytes of the data.
## (Before October 2026 it was FileAccess.store_var: a length, then the same bytes. That still loads.)
const SAVE_MAGIC := "TBSV"
const SAVE_HEAD := 20

var opts := { "autofire": true, "music": true, "sfx": true, "shake": true, "fps": false, "show_gear": true, "fast_draw": true, "vfx": true, "haggler": false, "statcol": true, "neon": false, "keymap": {} }
var meta := {
	"runs": 0, "wins": 0, "best": 0, "embers": 0, "unlocked": {}, "found": {}, "secrets": 0,
	"bosses": 0, "kills": 0, "dread_max": 0, "dread": 0, "tree": {}, "found_w": {}, "found_g": {},
}

func _ready() -> void:
	if not DebugArgs.has("no-save"):
		load_save()
	if DebugArgs.has("unlock-all"):
		unlock_all()

## Debug: every shrine unlock and every skill-tree node.
func unlock_all() -> void:
	for u in GameData.unlocks():
		meta["unlocked"][u["id"]] = true
	for h in GameData.heroes():
		meta["tree"][h["id"]] = [4, 4, 4]

func unlocked(id: String) -> bool:
	return meta["unlocked"].get(id, false) == true

## What load_save found: "" (nothing), "save", "backup" (the save was damaged or missing) or
## "fresh" (a file was there, but neither it nor the backup was whole: a new game's progress).
var save_source := ""

func load_save() -> void:
	load_from(SAVE_FILE, SAVE_BACKUP)

## Takes the save if it is whole, else the backup if that is whole, else starts fresh. Nothing
## is written: a damaged file stays as it is until the next real save replaces it.
func load_from(path: String, backup: String) -> void:
	var data := read_save(path)
	save_source = "save"
	if data.is_empty():
		data = read_save(backup)
		save_source = "backup"
	if data.is_empty():
		save_source = "fresh" if FileAccess.file_exists(path) or FileAccess.file_exists(backup) else ""
		return
	if data.get("opts") is Dictionary:
		_merge_typed(opts, data["opts"])
	if data.get("meta") is Dictionary:
		_merge_typed(meta, data["meta"])

## Takes the saved values over the defaults; a value of another kind than the default's is left
## out (a whole number and a fraction count as the same kind).
static func _merge_typed(into: Dictionary, saved: Dictionary) -> void:
	for k in saved:
		if not into.has(k) or _kind(saved[k]) == _kind(into[k]):
			into[k] = saved[k]

static func _kind(v) -> int:
	return TYPE_INT if typeof(v) == TYPE_FLOAT else typeof(v)

func write_save() -> void:
	if DebugArgs.has("no-save"):
		return
	write_save_to(SAVE_FILE, SAVE_BACKUP, { "opts": opts, "meta": meta })

static func _md5(bytes: PackedByteArray) -> PackedByteArray:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	if not bytes.is_empty():
		ctx.update(bytes)
	return ctx.finish()

static func save_bytes(data: Dictionary) -> PackedByteArray:
	var raw := var_to_bytes(data)
	var out := SAVE_MAGIC.to_ascii_buffer()
	out.append_array(_md5(raw))
	out.append_array(raw)
	return out

## The data in the bytes of a save file, or nothing if they are not, to the last one, what
## save_bytes (or the old store_var) once made. A damaged file is turned down before anything in
## it is unpacked, so the engine has nothing to complain about.
static func save_in(bytes: PackedByteArray) -> Dictionary:
	var raw := PackedByteArray()
	if bytes.size() > SAVE_HEAD and bytes.slice(0, 4) == SAVE_MAGIC.to_ascii_buffer():
		raw = bytes.slice(SAVE_HEAD)
		if _md5(raw) != bytes.slice(4, SAVE_HEAD):
			return {}
	elif bytes.size() > 4 and bytes.decode_u32(0) == bytes.size() - 4:
		raw = bytes.slice(4)     # the old format: no checksum, but the length must be right
	else:
		return {}
	var data = bytes_to_var(raw)
	if not (data is Dictionary) or var_to_bytes(data) != raw:
		return {}
	return data

static func read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	return save_in(FileAccess.get_file_as_bytes(path))

## Writes the save whole or not at all: under another name first, read back and compared byte for
## byte (a full disk does not always say so). Only then does the save in place, if it is whole,
## become the backup, and the new one take its place. If anything fails the files are as they were.
static func write_save_to(path: String, backup: String, data: Dictionary) -> Error:
	var bytes := save_bytes(data)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_buffer(bytes)
	var err := f.get_error()
	f.close()
	if err == OK and FileAccess.get_file_as_bytes(tmp) != bytes:
		err = ERR_FILE_CANT_WRITE
	if err == OK and not read_save(path).is_empty():
		err = DirAccess.rename_absolute(path, backup)
	if err == OK:
		err = DirAccess.rename_absolute(tmp, path)
	if err != OK:
		DirAccess.remove_absolute(tmp)
	return err
