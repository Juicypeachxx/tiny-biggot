extends Node2D
## Root of the game (port of Main.rb). The original runs one update per
## 60 fps frame with a fixed DT; here the logic runs in _physics_process at
## 60 ticks per second with the same fixed DT, and drawing reads the result.

const FadeView := preload("res://scripts/render/fade_view.gd")
const DebugHud := preload("res://scripts/render/debug_hud.gd")

var world: WorldView
var fade_view: Node2D
var hud: Node2D
var overlay: OverlayView

var bot: DebugBot = null
var _bench_us := 0
var _bench_n := 0
var _ticks := 0
var _shot_path := ""
var _shot_frame := -1

func _ready() -> void:
	if DebugArgs.has("seed"):
		seed(DebugArgs.get_int("seed"))
	_shot_path = DebugArgs.get_str("shot")
	_shot_frame = DebugArgs.get_int("shot-frame", 60)
	if DebugArgs.has("bot"):
		bot = DebugBot.new()
	world = WorldView.new()
	add_child(world)
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)
	hud = DebugHud.new()
	hud_layer.add_child(hud)
	var over_layer := CanvasLayer.new()
	over_layer.layer = 20
	add_child(over_layer)
	overlay = OverlayView.new()
	over_layer.add_child(overlay)
	var top := CanvasLayer.new()
	top.layer = 50
	add_child(top)
	fade_view = FadeView.new()
	top.add_child(fade_view)
	var touch_layer := CanvasLayer.new()
	touch_layer.layer = 60
	add_child(touch_layer)
	touch_layer.add_child(TouchControls.new())
	# Until the menus are ported (stage 7) the game boots straight into a run.
	G.god = DebugArgs.has("god")
	G.hero_index = clampi(DebugArgs.get_int("hero", 0), 0, GameData.HEROES.size() - 1)
	G.new_run()
	G.floor_index = clampi(DebugArgs.get_int("floor", 0), 0, GameData.FLOORS.size() - 1)
	if G.floor_index > 0:
		G.start_floor()
	if DebugArgs.has("room"):
		var kind := DebugArgs.get_str("room")
		G.floor_d["depth"] = G.floor_d["total"] - 1 if kind == "boss" else 2
		G.enter_room(World.make_room(G.floor_d, kind, "gold" if kind == "combat" else "", "s"))
	match DebugArgs.get_str("ui"):
		"choice": G.open_choice("chest", { "x": 200.0, "y": 150.0 })
		"traits":
			G.player.pending = 2
			G.offer_traits()

func _physics_process(_delta: float) -> void:
	if bot != null:
		bot.tick()
	Keys.tick()
	var t0 := Time.get_ticks_usec()
	if DebugArgs.has("bench"):
		_bench_feed()
	G.update(TB.DT)
	if DebugArgs.has("bench") and _ticks > 120:
		_bench_us += Time.get_ticks_usec() - t0
		_bench_n += 1
		if _bench_n % 600 == 0:
			print("[bench] %d enemy shots, %d player shots, %d particles: logic %.2f ms/tick avg" % [
				EBullets.n, G.pbullets.size(), Fx.n, _bench_us / 1000.0 / _bench_n])
	world.refresh()
	hud.queue_redraw()
	overlay.refresh()
	fade_view.queue_redraw()
	_ticks += 1
	if DebugArgs.has("weapon-cycle") and G.player != null:
		var every := maxi(1, DebugArgs.get_int("weapon-cycle")) * 60
		if _ticks % every == 0:
			var all := Weapons.all()
			var idx: int = (_ticks / every) % all.size()
			Weapons.equip_weapon(G.player, all[idx])
			print("[weapon] ", all[idx]["id"], " (", all[idx]["kind"], ")")
	if _shot_path != "" and _ticks == _shot_frame:
		_take_shot()

## --bench: keeps the room full of bullets to measure the hot path.
func _bench_feed() -> void:
	if G.state != &"play" or G.room == null:
		return
	if EBullets.n < DebugArgs.get_int("bench", 1500):
		Combat.ering(TB.SW / 2.0, 6.0 * TB.TS, 24, 30 + randf() * 30, randf(), TB.pick(EBullets.SPRITES))
	if G.enemies.size() < 12:
		var s := World.free_spot(G.room, G.player, 60, World.M_FLYER)
		var e := Combat.spawn_enemy(TB.pick(GameData.FLOORS[G.floor_index]["pool"]), s.x, s.y, false, true)
		e.max_hp = 1e9
		e.hp = 1e9

func _take_shot() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := _shot_path
	if not path.is_absolute_path():
		path = ProjectSettings.globalize_path("res://" + path)
	img.save_png(path)
	print("screenshot saved: ", path)
	get_tree().quit()
