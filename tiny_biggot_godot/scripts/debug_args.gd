class_name DebugArgs
extends RefCounted
## Command-line options for testing, passed after `--`:
##   --shot=res_or_abs_path.png   save a screenshot ...
##   --shot-frame=N               ... after N logic ticks, then quit
##   --hero=N                     hero index for the debug quick-start (0-5)
##   --floor=N                    start on floor N (0-5)
##   --room=KIND                  jump straight into a room of that type (combat, boss, ...)
##   --seed=N                     fixed random seed
##   --bot                        autopilot that moves, aims and rolls (soak test)
##   --touch                      show the touch controls on a desktop (mouse = finger)

static var _args := {}
static var _parsed := false

static func _parse() -> void:
	if _parsed:
		return
	_parsed = true
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			_args[kv[0]] = kv[1] if kv.size() > 1 else "1"

static func has(k: String) -> bool:
	_parse()
	return _args.has(k)

static func get_str(k: String, def: String = "") -> String:
	_parse()
	return _args.get(k, def)

static func get_int(k: String, def: int = 0) -> int:
	_parse()
	return int(_args[k]) if _args.has(k) else def
