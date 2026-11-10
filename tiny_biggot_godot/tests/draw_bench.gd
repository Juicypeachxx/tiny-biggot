extends Node
## Times the hot drawing loops with a fixed crowd: 300 player shots of mixed kinds through the
## batch painter and through the plain painter, and 1500 enemy shots. Diagnosis only.
## Run: godot --headless --path . res://tests/draw_bench.tscn -- --no-save

var world: WorldView
var _res := {}
var _mode := ""
var _runs := 0

func _ready() -> void:
	await get_tree().process_frame
	seed(5)
	G.hero_index = 0
	G.new_run()
	G.state = &"play"
	world = WorldView.new()
	add_child(world)
	await get_tree().process_frame
	var p := G.player
	var kinds := ["bolt", "hex", "clod", "spark", "fire", "flask", "boomer", "spin", "disc", "pulse", "rail", "lance", "dart", "feather"]
	var tags := ["", "pyre"]
	if DebugArgs.has("only"):
		kinds = [DebugArgs.get_str("only")]
	var icons := [Weapons.by_id("pithatchet")["sprite"], Weapons.by_id("worldeater")["sprite"], Weapons.by_id("giltdeck")["sprite"]]
	for i in 300:
		var b := Combat.new_pbullet()
		b.kind = kinds[i % kinds.size()]
		b.tag = tags[(i / kinds.size()) % tags.size()]
		b.icon = icons[i % icons.size()]
		b.x = 40.0 + (i * 37) % 360
		b.y = 50.0 + (i * 53) % 200
		b.vx = 100.0 - (i % 7) * 30.0
		b.vy = 60.0 - (i % 5) * 30.0
		b.r = 2.5 + (i % 4) * 0.8
		b.life = 0.5
		b.max_life = 1.0
		b.age = i * 0.01
		b.rot = i * 0.3
		G.pbullets.append(b)
	for i in 1500:
		EBullets.add(30.0 + (i * 31) % 380, 40.0 + (i * 17) % 220, 20, 10, EBullets.SPRITES[i % EBullets.SPRITES.size()], 2.5)
	EBullets.compact()
	# 1. The batch painter's loop.
	Meta.opts["fast_draw"] = true
	for k in 30:
		world._prepare_shots()
	var best := 1e9
	for round in 8:
		var t0 := Time.get_ticks_usec()
		for k in 150:
			world._prepare_shots()
		best = minf(best, (Time.get_ticks_usec() - t0) / 150.0)
	_res["batch"] = best
	_res["plain_n"] = world._plain.size()
	# 2 and 3 need a canvas item that is being drawn.
	var layer := DrawLayer.new(_paint)
	add_child(layer)
	for mode in ["foe", "plain"]:
		_mode = mode
		_runs = 0
		if mode == "plain":
			Meta.opts["fast_draw"] = false
			world._prepare_shots()
		for k in 24:
			layer.queue_redraw()
			await get_tree().process_frame
	if _runs == 0:
		print("[bench] this run does not draw")
	print("[bench] batch loop, 300 shots: %.1f us (%.3f us a shot); %d of them left to the plain painter" % [_res["batch"], _res["batch"] / 300.0, _res["plain_n"]])
	if _res.has("foe"):
		print("[bench] enemy shots, 1500: %.1f us (%.3f us a shot)" % [_res["foe"], _res["foe"] / 1500.0])
	if _res.has("plain"):
		print("[bench] plain painter, 300 shots: %.1f us (%.3f us a shot)" % [_res["plain"], _res["plain"] / 300.0])
	get_tree().quit(0)

func _paint(ci: CanvasItem) -> void:
	_runs += 1
	if _runs < 3:
		if _mode == "foe":
			EBullets.draw(ci)
		else:
			world._paint_pbullets(ci)
		return
	var t0 := Time.get_ticks_usec()
	var n := 10
	for k in n:
		if _mode == "foe":
			EBullets.draw(ci)
		else:
			world._paint_pbullets(ci)
	var us := (Time.get_ticks_usec() - t0) / float(n)
	_res[_mode] = minf(_res.get(_mode, 1e9), us)
