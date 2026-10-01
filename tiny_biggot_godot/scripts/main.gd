extends Node2D
## Root of the game (port of Main.rb). The original runs one update per
## 60 fps frame with a fixed DT; here the logic runs in _physics_process at
## 60 ticks per second with the same fixed DT, and drawing reads the result.

const FadeView := preload("res://scripts/render/fade_view.gd")

var world: WorldView
var fade_view: Node2D
var hud: HudView
var menus: MenuView
var overlay: OverlayView

var bot: DebugBot = null
var _trace: FileAccess = null
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
	if DebugArgs.has("trace"):
		_trace = FileAccess.open(DebugArgs.get_str("trace"), FileAccess.WRITE)
	world = WorldView.new()
	add_child(world)
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)
	hud = HudView.new()
	hud_layer.add_child(hud)
	var over_layer := CanvasLayer.new()
	over_layer.layer = 20
	add_child(over_layer)
	overlay = OverlayView.new()
	over_layer.add_child(overlay)
	var menu_layer := CanvasLayer.new()
	menu_layer.layer = 25
	add_child(menu_layer)
	menus = MenuView.new()
	menu_layer.add_child(menus)
	var top := CanvasLayer.new()
	top.layer = 50
	add_child(top)
	fade_view = FadeView.new()
	top.add_child(fade_view)
	var touch_layer := CanvasLayer.new()
	touch_layer.layer = 60
	add_child(touch_layer)
	touch_layer.add_child(TouchControls.new())
	G.god = DebugArgs.has("god")
	G.hero_index = clampi(DebugArgs.get_int("hero", 0), 0, GameData.heroes().size() - 1)
	# The game opens on the title screen. Test options start a run directly.
	var quick := false
	for k in ["bot", "room", "floor", "hero", "ui", "bench", "quick", "weapon"]:
		if DebugArgs.has(k):
			quick = true
	if not quick:
		G.state = &"title"
		return
	G.new_run()
	G.floor_index = clampi(DebugArgs.get_int("floor", 0), 0, GameData.floors().size() - 1)
	if G.floor_index > 0:
		G.start_floor()
	if DebugArgs.has("room"):
		var kind := DebugArgs.get_str("room")
		G.floor_d["depth"] = G.floor_d["total"] - 1 if kind == "boss" else 2
		if kind == "mini":   # stage 7: the floor's mini-boss room
			kind = "elite"
			G.floor_d["depth"] = G.floor_d["total"] - 2
		G.enter_room(World.make_room(G.floor_d, kind, "gold" if kind == "combat" else "", "s"))
	match DebugArgs.get_str("ui"):
		"": pass
		"choice": G.open_choice("chest", { "x": 200.0, "y": 150.0 })
		"traits":
			G.player.pending = 2
			G.offer_traits()
		"hud": pass
		"inventory":
			G.state = &"inventory"
		"tree":
			G.tree_hero = G.hero_index
			G.state = &"tree"
		"card":   # an item card: a legendary weapon at your feet (Rogues layer)
			var lw: Dictionary = Weapons.all().filter(func(w): return w["rarity"] == "legend" and w["new"])[0]
			G.room.objects.append({ "kind": "item", "item": lw, "x": G.player.x, "y": G.player.y - 6 })
		"ending":   # the true ending room, right after the last guardian falls
			G.floor_index = GameData.floors().size() - 1
			G.floor_d = World.new_floor(G.floor_index)
			G.floor_d["depth"] = G.floor_d["total"] - 1
			G.enter_room(World.make_room(G.floor_d, "boss", "", "s"))
			G.boss_delay = null
			G.on_boss_dead(Combat.spawn_boss(GameData.floors()[G.floor_index]["boss"]))
			G.enemies.clear()
			G.boss = null
		var other:
			G.state = StringName(other)

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
	world.visible = world.visible and HudView.world_state()
	hud.refresh()
	menus.refresh()
	overlay.refresh()
	fade_view.queue_redraw()
	_ticks += 1
	if _trace != null and _ticks % 60 == 0:
		_trace.store_line(Trace.line(_ticks))
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
		var e := Combat.spawn_enemy(TB.pick(GameData.floors()[G.floor_index]["pool"]), s.x, s.y, false, true)
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
