extends Node2D
## Root of the game (port of Main.rb). The original runs one update per
## 60 fps frame with a fixed DT; here the logic runs in _physics_process at
## 60 ticks per second with the same fixed DT, and drawing reads the result.

const FadeView := preload("res://scripts/render/fade_view.gd")

var world: WorldView
var fade_view: Node2D

var _ticks := 0
var _shot_path := ""
var _shot_frame := -1

func _ready() -> void:
	if DebugArgs.has("seed"):
		seed(DebugArgs.get_int("seed"))
	_shot_path = DebugArgs.get_str("shot")
	_shot_frame = DebugArgs.get_int("shot-frame", 60)
	world = WorldView.new()
	add_child(world)
	var top := CanvasLayer.new()
	top.layer = 50
	add_child(top)
	fade_view = FadeView.new()
	top.add_child(fade_view)
	# Until the menus are ported (stage 7) the game boots straight into a run.
	G.floor_index = clampi(DebugArgs.get_int("floor", 0), 0, GameData.FLOORS.size() - 1)
	G.start_floor()
	if DebugArgs.has("room"):
		G.floor_d["depth"] = 2
		G.enter_room(World.make_room(G.floor_d, DebugArgs.get_str("room"), "gold", "s"))

func _physics_process(_delta: float) -> void:
	Keys.tick()
	G.update(TB.DT)
	world.refresh()
	fade_view.queue_redraw()
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
