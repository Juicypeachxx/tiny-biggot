extends Node2D
## Root of the game (port of Main.rb). The original runs one update per
## 60 fps frame with a fixed DT; here the logic runs in _physics_process at
## 60 ticks per second with the same fixed DT, and drawing reads the result.

@onready var boot: Node2D = $Boot

var _ticks := 0
var _shot_path := ""
var _shot_frame := -1

func _ready() -> void:
	if DebugArgs.has("seed"):
		seed(DebugArgs.get_int("seed"))
	_shot_path = DebugArgs.get_str("shot")
	_shot_frame = DebugArgs.get_int("shot-frame", 60)
	Snd.music(0)

func _physics_process(_delta: float) -> void:
	Keys.tick()
	G.update(TB.DT)
	boot.queue_redraw()
	_ticks += 1
	if _shot_path != "" and _ticks == _shot_frame:
		_take_shot()

func _take_shot() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := _shot_path
	if not path.is_absolute_path():
		path = ProjectSettings.globalize_path("res://" + path)
	img.save_png(path)
	print("screenshot saved: ", path)
	get_tree().quit()
