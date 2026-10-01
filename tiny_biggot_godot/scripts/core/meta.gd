extends Node
## Options and between-run progress (port of Core.rb `$opts` / `$meta` and
## load_save / write_save). Autoload name: Meta.

const SAVE_FILE := "user://tiny_biggot.save"

var opts := { "autofire": true, "music": true, "sfx": true, "shake": true }
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

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	var f := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if f == null:
		return
	var data = f.get_var()
	if typeof(data) != TYPE_DICTIONARY:
		return
	if data.get("opts") is Dictionary:
		opts.merge(data["opts"], true)
	if data.get("meta") is Dictionary:
		meta.merge(data["meta"], true)
	for k in ["unlocked", "found", "tree", "found_w", "found_g"]:
		if not (meta.get(k) is Dictionary):
			meta[k] = {}

func write_save() -> void:
	if DebugArgs.has("no-save"):
		return
	var f := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if f == null:
		return
	f.store_var({ "opts": opts, "meta": meta })
