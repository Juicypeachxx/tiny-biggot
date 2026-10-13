class_name RunSave
extends RefCounted
## Save and continue a run (his ask, 6 Oct, ROADMAP 6.3). The expanded game keeps the run at the start
## of every floor, so iOS closing the app (a call, the iPad locked for long) costs at most the floor
## in progress: CONTINUE on the title brings back the hero with everything carried, on a fresh floor
## of the same depth. Written like the main save (Meta.write_save_to: whole or not at all, with a
## backup), into a file of its own; gone when the run ends.

const FILE := "user://tiny_biggot.run"
const BACKUP := "user://tiny_biggot.run.bak"
const VERSION := 1

static var _has := -1   # -1: not looked yet

## The run as plain data: the game's run numbers and every value the hero holds (stats, weapon,
## gear, relics, traits, pets, gold...). Anything that is an object (a foe it aims at) is left out.
static func capture() -> Dictionary:
	var p: Player = G.player
	var props := {}
	for pr in p.get_property_list():
		if not (pr["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var v = p.get(pr["name"])
		if _plain(v):
			props[pr["name"]] = v.duplicate(true) if (v is Array or v is Dictionary) else v
	return { "v": VERSION, "hero": G.hero_index, "floor": G.floor_index, "loop": G.loop, "dread": G.dread,
		"stats": G.run_stats.duplicate(true), "player": props }

static func _plain(v) -> bool:
	if v is Object or v is Callable or v is Signal or v is RID:
		return false
	if v is Array:
		for x in v:
			if not _plain(x):
				return false
	elif v is Dictionary:
		for k in v:
			if not _plain(k) or not _plain(v[k]):
				return false
	return true

## Puts a captured run back: the hero rebuilt, then every saved value set on it, then a fresh floor
## of the same depth. False if the data is not a run this version can read.
static func restore(d: Dictionary) -> bool:
	if d.get("v", 0) != VERSION or not d.has("player") or int(d.get("hero", -1)) >= GameData.heroes().size():
		return false
	G.hero_index = int(d["hero"])
	G.player = Player.new(GameData.heroes()[G.hero_index])
	Effects.reset_run_state()
	var p: Player = G.player
	var saved: Dictionary = d["player"]
	for k in saved:
		var cur = p.get(k)
		var v = saved[k]
		if (cur is Array or cur is Dictionary) and cur.is_read_only():
			continue   # the game's own data (the hero's sheet): it never changes in a run
		if cur is Array and v is Array:
			cur.clear()
			cur.assign(v)
		elif cur is Dictionary and v is Dictionary:
			cur.clear()
			cur.assign(v)
		elif cur == null or typeof(cur) == typeof(v) or (cur is float and v is int) or (cur is int and v is float):
			p.set(k, v)
	G.run_stats = d["stats"].duplicate(true)
	G.loop = int(d["loop"])
	G.dread = int(d["dread"])
	G.floor_index = int(d["floor"])
	G.familiars = []
	G.temp_fams = []
	G.zones = []
	G.start_floor()
	return true

## At the start of every floor (game.start_floor).
static func save() -> void:
	if not GameData.rogues() or DebugArgs.has("no-save") or G.player == null:
		return
	if Meta.write_save_to(FILE, BACKUP, capture()) == OK:
		_has = 1

## A run waits to be continued.
static func exists() -> bool:
	if _has < 0:
		_has = 1 if GameData.rogues() and not DebugArgs.has("no-save") and not Meta.read_save(FILE).is_empty() else 0
	return _has == 1

## CONTINUE: the saved run, or the backup if the file is damaged.
static func load_run() -> bool:
	var d := Meta.read_save(FILE)
	if d.is_empty():
		d = Meta.read_save(BACKUP)
	return not d.is_empty() and restore(d)

## The run is over (death, a win, abandoned): nothing to continue.
static func clear() -> void:
	_has = 0
	if DebugArgs.has("no-save"):
		return
	for f in [FILE, BACKUP]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
