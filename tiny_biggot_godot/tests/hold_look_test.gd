extends Node
## 67.7 (his word, 28 Oct: "test the armor fitting and weapon handling, only test this and make it
## perfect"): every hero standing in a room, in two outfits, holding a different weapon in each,
## aimed eight ways round; one close-up each, drawn by the game's own WorldView, side by side.
## Run with a screen: xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/hold_look_test.tscn -- --no-save --sheet=PATH [--heroes=0,1,2]
## Also checks, for every picture: the weapon is drawn, and its hand touches the hero's picture or
## the weapon (nothing floats apart). Prints "hold look test: PASSED" or a FAIL line per problem.

const AIMS := 8
const CW := 44     # a close-up, in the game's pixels
const CH := 40
const WEAPONS := ["rustblade", "blunderbuss", "huntbow", "hexwand", "halberd", "handcannon", "firespitter", "sabre"]

var fails := 0

func _first(slot: String, shape: String) -> Dictionary:
	for g: Dictionary in Gear.all():
		if g["slot"] == slot and g["shape"] == shape:
			return g
	return {}

func _ready() -> void:
	get_viewport().canvas_transform = Transform2D(0.0, Vector2(TB.D, TB.D), 0.0, Vector2.ZERO)
	await get_tree().process_frame
	var outfits := [
		{ "head": _first("head", "helm"), "body": _first("body", "plate"), "feet": _first("feet", "greaves"), "hands": _first("hands", "gloves"), "offhand": _first("offhand", "offhand") },
		{ "head": _first("head", "hood"), "body": _first("body", "robe"), "feet": _first("feet", "boots") },
		{ "head": _first("head", "hat"), "body": _first("body", "leather"), "neck": _first("neck", "amulet") },
		{ "head": _first("head", "crown"), "body": _first("body", "cloak"), "trinket": _first("trinket", "charm") },
	]
	var heroes: Array = GameData.heroes()
	var which: Array = []
	if DebugArgs.has("heroes"):
		for s in DebugArgs.get_str("heroes").split(","):
			which.append(int(s))
	else:
		which = range(heroes.size())
	var rows := which.size() * 2
	var k := 4
	var sheet := Image.create(CW * TB.D * AIMS * k / 2, CH * TB.D * rows * k / 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.1, 0.12))
	var world: WorldView = null
	var r := 0
	for hi: int in which:
		G.hero_index = hi
		G.new_run()
		G.enter_room(World.make_room(G.floor_d, "combat", "", "s"))
		G.room.objects.clear()
		for rr in range(TB.IY0, TB.IY0 + TB.IH):   # a clear floor round the hero
			for cc in range(TB.IX0, TB.IX0 + TB.IW):
				if G.room.tile(cc, rr) == World.T_PILLAR:
					G.room.set_tile(cc, rr, World.T_FLOOR)
		if world == null:
			world = WorldView.new()
			add_child(world)
			world.refresh()
			for i in 4:
				await RenderingServer.frame_post_draw
		for o in 2:
			var p: Player = G.player
			p.x = TB.SW / 2.0
			p.y = TB.SH / 2.0 + 10.0
			p.moving = false
			p.gear = {}
			var outfit: Dictionary = outfits[(hi * 2 + o) % outfits.size()]
			for slot in outfit:
				if not outfit[slot].is_empty():
					p.gear[slot] = outfit[slot]
			p.weapon = Weapons.by_id(WEAPONS[(hi * 2 + o) % WEAPONS.size()])
			for a in AIMS:
				p.aim_a = a * TAU / AIMS
				p.face = 1 if cos(p.aim_a) >= 0 else -1
				Juice.recoil = 0.0
				G.enemies.clear()
				G.pbullets.clear()
				world.refresh()
				await RenderingServer.frame_post_draw
				await RenderingServer.frame_post_draw
				var shot := get_viewport().get_texture().get_image()
				var rx := int((p.x - CW / 2.0) * TB.D)
				var ry := int((p.y - CH / 2.0 - 4.0) * TB.D)
				var crop := shot.get_region(Rect2i(rx, ry, CW * TB.D, CH * TB.D))
				crop.resize(CW * TB.D * k / 2, CH * TB.D * k / 2, Image.INTERPOLATE_NEAREST)
				sheet.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i(a * CW * TB.D * k / 2, r * CH * TB.D * k / 2))
			r += 1
	if DebugArgs.has("sheet"):
		print("[hold] sheet: %s" % error_string(sheet.save_png(DebugArgs.get_str("sheet"))))
	print("[hold] %d heroes, %d pictures" % [which.size(), rows * AIMS])
	print("hold look test: PASSED" if fails == 0 else "hold look test: FAILED (%d)" % fails)
	get_tree().quit(0 if fails == 0 else 1)
