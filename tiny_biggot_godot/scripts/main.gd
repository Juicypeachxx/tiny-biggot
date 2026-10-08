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
var monkey: DebugMonkey = null
var _trace: FileAccess = null
var _bench_us := 0
var _bench_n := 0
var _ticks := 0
var _shot_path := ""
var _shot_frame := -1
var _boss_key := ""

func _ready() -> void:
	if DebugArgs.has("seed"):
		seed(DebugArgs.get_int("seed"))
		# Visual-only generators too, so a seeded run draws the same frame every time (picture tests).
		Juice._rng.seed = DebugArgs.get_int("seed")
		WeaponFx._rng.seed = DebugArgs.get_int("seed")
		Vfx._rng.seed = DebugArgs.get_int("seed")
		Afx._rng.seed = DebugArgs.get_int("seed")
		BiomeDeco._rng.seed = DebugArgs.get_int("seed")
	_shot_path = DebugArgs.get_str("shot")
	_shot_frame = DebugArgs.get_int("shot-frame", 60)
	if DebugArgs.has("bot"):
		bot = DebugBot.new()
	if DebugArgs.has("monkey"):
		monkey = DebugMonkey.new()   # random buttons everywhere (ROADMAP 4.10)
	if DebugArgs.has("trace"):
		_trace = FileAccess.open(DebugArgs.get_str("trace"), FileAccess.WRITE)
	if not DebugArgs.has("no-warmup"):
		add_child(Warmup.new())   # under everything, for the first frames: see scripts/render/warmup.gd
	world = WorldView.new()
	add_child(world)
	if DebugArgs.has("seed"):
		world._vr.seed = DebugArgs.get_int("seed")
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
	var star_layer := CanvasLayer.new()
	star_layer.layer = 26   # the constellation screen, over the menus
	add_child(star_layer)
	star_layer.add_child(StarView.new())
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
	for k in ["bot", "room", "floor", "hero", "ui", "bench", "quick", "weapon", "heavy", "rift", "event", "rex", "set"]:
		if DebugArgs.has(k):
			quick = true
	if not quick:
		G.state = &"title"
		return
	G.new_run()
	if DebugArgs.get_int("chapter", 1) >= 2:   # 12.2 / 14.4: a chapter's floors (--floor counts on from them)
		G.run_stats["chapter"] = DebugArgs.get_int("chapter", 1)
	var ch: int = G.run_stats.get("chapter", 1)   # 20.3: and Chapter IV
	var off := (GameData.FLOORS.size() + GameData.NEW_FLOORS.size() + (GameData.CHAPTER2.size() if ch >= 3 else 0) + (GameData.CHAPTER3.size() if ch >= 4 else 0)) if ch >= 2 else 0
	G.floor_index = clampi(DebugArgs.get_int("floor", 0) + off, 0, GameData.floors().size() - 1)
	if G.floor_index > 0:
		G.start_floor()
	if DebugArgs.has("plain-draw"):   # picture tests: the plain painters instead of FAST DRAWING
		Meta.opts["fast_draw"] = false
	if DebugArgs.has("no-vfx"):   # the plain effects, as with FANCY EFFECTS off
		Meta.opts["vfx"] = false
		Vfx.reset()
	if DebugArgs.has("long"):   # performance tests: long-lived bouncy shots fill the room to the shot cap
		G.player.life *= 4.0
		G.player.bounce += 8
	if DebugArgs.has("room"):
		var kind := DebugArgs.get_str("room")
		G.floor_d["depth"] = G.floor_d["total"] - 1 if kind == "boss" else 2
		if kind == "mini":   # stage 7: the floor's mini-boss room
			kind = "elite"
			G.floor_d["depth"] = G.floor_d["total"] - 2
		G.enter_room(World.make_room(G.floor_d, kind, "gold" if kind == "combat" else "", "s"))
	# --rift=ID [--step=0..3] jumps into a rift world (3: a new world's guardian), --event=NAME into an event room.
	if DebugArgs.has("rift"):
		var step := DebugArgs.get_int("step", 0)
		G.enter_room(World.make_room(G.floor_d, ["combat", "elite", "elite", "boss"][clampi(step, 0, 3)], "", "s",
			{ "theme": DebugArgs.get_str("rift"), "step": step }))
	# --set=ID starts wearing a whole armor set (13.2: the set's big moment, its aura).
	if DebugArgs.has("set"):
		for g in Gear.pieces(DebugArgs.get_str("set")):
			Gear.equip_gear(G.player, g)
	# --pet=ID[:LEVEL] starts with a pet (scripts/entities/pets.gd).
	if DebugArgs.has("pet"):
		var pv := DebugArgs.get_str("pet").split(":")
		Pets.give(G.player, pv[0], clampi(int(pv[1]) if pv.size() > 1 else 1, 1, 3))
	# --rex starts in Rex's barn (scripts/entities/rex.gd).
	if DebugArgs.has("rex"):
		G.enter_room(World.make_room(G.floor_d, "barn", "", "s"))
	# --spawn=TYPE puts one foe (a GameData.ENEMIES key) in the middle of the room (picture tests).
	if DebugArgs.has("spawn"):
		G.locked = true
		Combat.spawn_enemy(DebugArgs.get_str("spawn"), 14.0 * TB.TS, 7.0 * TB.TS, false, true)
	# --tempo=N starts the Gaolbird with N tempo that does not fade for a while (picture tests).
	if DebugArgs.has("tempo") and G.player.tempo_max > 0:
		Tempo.set_to(G.player, DebugArgs.get_int("tempo"))
		G.player.tempo_t = 600.0
	if DebugArgs.has("neon"):
		Meta.opts["neon"] = true   # 10.5: pictures of the NEON LOOK
		G.room_changed.emit()
	if DebugArgs.has("event"):
		G.enter_room(World.make_room(G.floor_d, "mystery", "", "s", { "event": DebugArgs.get_str("event") }))
	match DebugArgs.get_str("ui"):
		"": pass
		"choice": G.open_choice("chest", { "x": 200.0, "y": 150.0 })
		"traits":
			G.player.pending = 2
			G.offer_traits()
			if DebugArgs.has("combo-hint"):   # 14.3: found combos named on the cards, one ready
				Meta.meta["combos_found"] = { "t_stormfront": true, "t_infernalkeg": true }
				G.take_trait(Traits.by_id("z_thunderstep"))
				G.state = &"traits"
				G.tchoice["opts"] = [Traits.by_id("z_static"), Traits.by_id("z_scorch"), Traits.by_id("z_bankshot")]
		"hud": pass
		"stars":   # the constellation; with --unlock-all, a few stars already taken
			G.state = &"title"
			StarView.open()
			if DebugArgs.has("unlock-all"):
				for id in ["n1", "n2", "n2b1", "n2b2", "n2b3", "e1", "s1", "s2"]:
					Stars.taken()[id] = true
				StarView.sel = Stars.nodes().find_custom(func(n): return n["id"] == "n2b3")
				StarView.cam = Stars.nodes()[StarView.sel]["pos"] * 0.6
		"wardrobe":   # 14.2 (with --unlock-all, every piece found)
			if DebugArgs.has("unlock-all"):
				for g in Gear.all():
					Meta.meta["found_g"][g["id"]] = true
			G.open_wardrobe(&"title")
			G.wardrobe_i = Gear.SETS.keys().find("sunforged")
			G.menu = G.wardrobe_i
		"fishing":   # 15.1: a pond next to the hero, the line already out (--fish-auto: it plays itself)
			Fishing.auto = DebugArgs.has("fish-auto")
			Fishing.setup_hole(G.room)
			G.room_changed.emit()   # the lake is drawn with the room
			var pd: Dictionary = G.room.objects.filter(func(o): return o["kind"] == "e_pond")[0]
			G.player.x = pd["x"]
			G.player.y = pd["y"]
			if not DebugArgs.has("no-cast"):
				Fishing.start(pd)
		"camp":   # 17.2: the camp between runs (20.2 --camp-built: everything the carpenter builds)
			if DebugArgs.has("camp-built"):
				Meta.meta["camp_built"] = {}
				for id in CampBuild.PLANS:
					Meta.meta["camp_built"][id] = true
			Camp.enter()
			if DebugArgs.has("camp-near"):   # 19.2: stand by one of its people (a visitor is made to come)
				var k := DebugArgs.get_str("camp-near")
				var near := G.room.objects.filter(func(o): return o["kind"] == k)
				if near.is_empty():
					var o := { "kind": k, "x": 186.0, "y": 214.0, "face": -1 }
					if k == "v_peddler":
						o["relic"] = G.roll_relics(1, "iron")[0]
					G.room.objects.append(o)
					near = [o]
				G.player.x = near[0]["x"] - 14.0
				G.player.y = near[0]["y"] + 4.0
		"kitchen", "armory", "plans", "board":   # 19.2 / 20.2: the camp's pages (--camp-fish: a full larder)
			if DebugArgs.has("camp-built"):
				Meta.meta["camp_built"] = {}
				for id in CampBuild.PLANS:
					Meta.meta["camp_built"][id] = true
			Camp.enter()
			if DebugArgs.has("camp-fish"):
				for f in Fishing.FISH:
					CampLife.stock(f)
					CampLife.stock(f)
			match DebugArgs.get_str("ui"):
				"kitchen":
					G.state = &"kitchen"
					G.menu = 0
				"plans":
					G.state = &"plans"
					G.menu = 3
					CampBuild.plan_i = 3
				"board":
					Meta.meta["quest_news"] = ["REACH FLOOR 6"]
					Quests.open_board()
				_:
					CampLife.open_armory()
					CampLife.pick(12)
		"options", "keys":   # the options page, or (13.1) its keyboard keys page
			G.state = StringName(DebugArgs.get_str("ui"))
			G.opt_from = &"title"
			G.menu = 0
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

## SHOW FPS: the longest gap between two frames in the last second. A stall shows here even
## when the average frame rate looks fine (17 ms is a steady 60 fps; 33 is one frame lost).
## --hitch-log=MS prints every frame that took longer than MS milliseconds, with its tick.
var _frame_us := 0
var _worst_us := 0
var _hitch_us := DebugArgs.get_int("hitch-log", 0) * 1000
func _process(_delta: float) -> void:
	if not (Meta.opts.get("fps", false) or _hitch_us > 0 or DebugArgs.has("perf")):
		_frame_us = 0
		return
	var now := Time.get_ticks_usec()
	if _frame_us > 0:
		_worst_us = maxi(_worst_us, now - _frame_us)
		if _hitch_us > 0 and now - _frame_us > _hitch_us:
			print("[hitch] tick %d: %.1f ms" % [_ticks, (now - _frame_us) / 1000.0])
	_frame_us = now

func _physics_process(_delta: float) -> void:
	if bot != null:
		bot.tick()
	if monkey != null:
		monkey.tick()
	Keys.tick()
	var t0 := Time.get_ticks_usec()
	if DebugArgs.has("bench"):
		_bench_feed()
	G.update(TB.DT)
	var us := Time.get_ticks_usec() - t0
	if _hitch_us > 0 and us > _hitch_us:
		print("[hitch] tick %d: the rules took %.1f ms (%s)" % [_ticks, us / 1000.0, G.state])
	if DebugArgs.has("bench") and _ticks > 120:
		_bench_us += us
		_bench_n += 1
		if _bench_n % 600 == 0:
			print("[bench] %d enemy shots, %d player shots, %d particles: logic %.2f ms/tick avg" % [
				EBullets.n, G.pbullets.size(), Fx.n, _bench_us / 1000.0 / _bench_n])
	if DebugArgs.has("perf") or Meta.opts.get("fps", false):
		_perf_tick(us)
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
	# --objects prints, once a minute of game time, how many engine objects there are (leak soaks).
	if DebugArgs.has("objects") and _ticks % 3600 == 0:
		print("[objects] t=%dm %s objects=%d nodes=%d resources=%d enemies=%d" % [_ticks / 3600, G.state,
			Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT), G.enemies.size()])
	# --hurt-at=TICK lands one hit on the hero at that tick (picture tests of hit reactions).
	if DebugArgs.has("hurt-at") and _ticks == DebugArgs.get_int("hurt-at") and G.player != null and G.state == &"play":
		var was_god := G.god
		G.god = false
		G.player.invuln = 0.0
		G.player.dodge_t = 0.0
		Combat.hurt_player(1, "a test")
		G.god = was_god
	# --boss-log prints the guardian's attack each time it changes (to pick frames for pictures).
	if DebugArgs.has("boss-log") and G.boss != null:
		var key := "%s/%d" % [G.boss.state, G.boss.sub]
		if key != _boss_key:
			_boss_key = key
			print("[boss] tick %d %s sub %d at %d %d hero %d %d" % [_ticks, G.boss.state, G.boss.sub, G.boss.x, G.boss.y, G.player.x, G.player.y])
	# --attack-every=N: the hero attacks every N ticks whatever the range (picture tests of swings and shots).
	if DebugArgs.has("attack-every") and G.player != null and G.state == &"play" and _ticks % maxi(1, DebugArgs.get_int("attack-every")) == 0:
		Combat.player_shoot(G.player, G.player.aim_a, false)
	# --fx-demo fires every ability effect in turn, one every half second; --fx-only=N repeats
	# just step N (picture tests, and so that every effect painter runs in the checks).
	if (DebugArgs.has("fx-demo") or DebugArgs.has("fx-only")) and _ticks % 30 == 0 and G.player != null and G.state == &"play":
		_fx_demo(DebugArgs.get_int("fx-only", _ticks / 30))
	if _shot_path != "" and _ticks == _shot_frame:
		_take_shot()

const FX_STEPS := 14
func _fx_demo(step: int) -> void:
	var p := G.player
	var foes := G.enemies.filter(func(o): return o.targetable() and o.hp > 0)
	var e: Enemy = foes[(_ticks / 30) % foes.size()] if not foes.is_empty() else null
	var at := Vector2(e.x, e.y) if e != null else Vector2(p.x + 60, p.y - 30)
	if DebugArgs.has("fx-keep"):   # recordings: the foes never die, so every step has its target
		for o in foes:
			o.hp = o.max_hp
	if DebugArgs.has("fx-only"):   # picture tests crop around these
		print("[fx] step %d at %d %d hero %d %d" % [step % FX_STEPS, at.x, at.y, p.x, p.y])
	match step % FX_STEPS:
		0:
			if e != null: Combat.lightning(e, 0.1)
		1: Combat.explode_at(at.x, at.y, 0.1, null, 18)
		2:
			if e != null: Combat.chain_from(e, 0.1)
		3: Combat.explode_at(at.x, at.y, 0.1, null, 28, "#b8e05a")
		4:   # a meteor on the chosen spot (the "meteor" action itself picks a random foe)
			Vfx.meteor(at.x, at.y)
			Combat.explode_at(at.x, at.y, 0.1, null, 34, "#e8873a", true)
			G.zones.append({ "x": at.x, "y": at.y, "r": 15.0, "t": 2.0, "kind": "fire", "tick": 0.0 })
		5: G.zones.append({ "x": at.x, "y": at.y, "r": 22.0, "t": 3.0, "kind": "fire", "tick": 0.0 })
		6: G.zones.append({ "x": at.x, "y": at.y, "r": 24.0, "t": 3.0, "kind": "poison", "tick": 0.0 })
		7:
			# Each round hands the statuses out one place further on; --fx-shift=N fixes the place.
			var shift := DebugArgs.get_int("fx-shift", _ticks / (30 * FX_STEPS))
			for i in foes.size():
				Statuses.apply(foes[i], Effects.STATUSES[(i + shift) % Effects.STATUSES.size()], 1.0, 1.0)
		8: Combat.explode_at(at.x, at.y, 0.1, null, 46, "#e8873a", true)
		9:
			Actions.run(["pull", 110, 100], 1, { "x": at.x, "y": at.y })
			Vfx.heal(p.x, p.y)
		10:
			Combat.explode_at(p.x, p.y, 0.1, null, 72, "#f2c94c", true)
		11:
			G.zones.append({ "x": p.x, "y": p.y, "r": 24.0, "t": 2.5, "kind": "smoke", "tick": 0.0 })
			Actions.run(["bolts", 4, 0.1], 1, {})
		12:   # blasts right beside the hero: drawn see-through, so the hero is never lost
			Combat.explode_at(p.x + 7, p.y - 4, 0.1, null, 26, "#e8873a", true)
			Combat.explode_at(p.x - 30, p.y + 4, 0.1, null, 40, "#b8e05a", true)
		13:   # frost: ice shatters on a foe, a frost ring around the hero, every foe chilled
			Vfx.shatter(at.x, at.y)
			Vfx.nova(p.x, p.y, 90.0, "frost")
			for o in foes:
				Statuses.apply(o, "chill", 1.0, 1.0)

## --perf (or SHOW FPS in Options): every second prints logic and per-layer drawing cost (GDScript side)
## plus the frame rate. Use it on device to see what a heavy fight costs.
var _perf_logic := 0
var _perf_n := 0
var _perf_rcpu := 0.0
var _perf_rgpu := 0.0
var _perf_calls := 0
func _perf_tick(us: int) -> void:
	if not DrawLayer.perf_on:
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	DrawLayer.perf_on = true
	_perf_logic += us
	var vp := get_viewport().get_viewport_rid()
	_perf_rcpu += RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.get_frame_setup_time_cpu()
	_perf_rgpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
	_perf_calls = maxi(_perf_calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	_perf_n += 1
	if _perf_n < 60:
		return
	var parts := []
	var total := 0
	var keys := DrawLayer.perf.keys()
	keys.sort_custom(func(a, b): return DrawLayer.perf[a] > DrawLayer.perf[b])
	for k in keys:
		total += DrawLayer.perf[k]
		if parts.size() < (24 if DebugArgs.has("perf-all") else 6):
			parts.append("%s %.2f" % [k, DrawLayer.perf[k] / 1000.0 / _perf_n])
	HudView.perf_line = "%d FPS  LOGIC %.1f  DRAW %.1f  CALLS %d  WORST %d" % [Engine.get_frames_per_second(),
		_perf_logic / 1000.0 / _perf_n, total / 1000.0 / _perf_n, _perf_calls, roundi(_worst_us / 1000.0)]
	if DebugArgs.has("perf"): print("[perf] fps %d | logic %.2f ms | draw %.2f ms (%s) | render cpu %.2f gpu %.2f ms, peak %d draw calls | shots %d, foe shots %d, pickups %d, fx %d, texts %d | worst frame %.1f ms" % [
		Engine.get_frames_per_second(), _perf_logic / 1000.0 / _perf_n, total / 1000.0 / _perf_n, ", ".join(parts),
		_perf_rcpu / _perf_n, _perf_rgpu / _perf_n, _perf_calls, G.pbullets.size(), EBullets.n, G.pickups.size(), Fx.n, Fx.texts.size(),
		_worst_us / 1000.0])
	_worst_us = 0
	_perf_rcpu = 0.0
	_perf_rgpu = 0.0
	_perf_calls = 0
	_perf_logic = 0
	_perf_n = 0
	DrawLayer.perf.clear()

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
	if G.player != null:
		print("[shot] hero %d %d" % [G.player.x, G.player.y])
	get_tree().quit()
