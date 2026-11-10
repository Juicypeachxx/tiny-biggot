extends Node
## Loads and compiles every GDScript under res://scripts and reports failures.
## Runs as a scene (not with --script) so autoload singletons such as G, Img
## and Keys are defined while compiling.
## Usage: godot --headless --path . res://tests/check_scripts.tscn

func _ready() -> void:
	var files: Array[String] = []
	_collect("res://scripts", files)
	_collect("res://tests", files)
	files.sort()
	var bad := 0
	for f in files:
		var s = ResourceLoader.load(f, "", ResourceLoader.CACHE_MODE_IGNORE)
		if s == null or not (s is GDScript) or not s.can_instantiate():
			print("FAIL  ", f)
			bad += 1
		else:
			print("ok    ", f)
	print("%d scripts checked, %d failed" % [files.size(), bad])
	get_tree().quit(1 if bad > 0 else 0)

func _collect(dir: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		# Skip this checker itself: reloading the running script breaks it.
		if f.ends_with(".gd") and f != "check_scripts.gd":
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		_collect(dir + "/" + sub, out)
