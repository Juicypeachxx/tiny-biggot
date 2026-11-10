extends Node
## Profiles a heavy late-game build (like a level 30+ run with ~40 relics):
## per-section logic cost per tick. Run: godot --headless --path . res://tests/heavy_profile.tscn
## Visual only for diagnosis; not part of check.sh.

var secs := {}

func _ready() -> void:
	await get_tree().process_frame
	seed(11)
	G.hero_index = DebugArgs.get_int("hero", 0)
	G.new_run()
	G.floor_index = mini(9, GameData.floors().size() - 1)
	G.floor_d["depth"] = 10
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s"))
	var p: Player = G.player
	var rel := Relics.all().duplicate()
	rel.shuffle()
	for i in 40:
		G.add_relic(p, rel[i])
	var tr := Traits.all().duplicate()
	tr.shuffle()
	var ranks := 0
	for t in tr:
		if ranks >= 40:
			break
		for k in t["max"]:
			p.pending += 1
			G.take_trait(t)
			ranks += 1
	G.state = &"play"
	var legends := Weapons.all().filter(func(w): return w["rarity"] == "legend")
	Weapons.equip_weapon(p, legends[0])
	for g in Gear.all().filter(func(g): return g["rarity"] == "legend"):
		Gear.equip_gear(p, g)
	print("[profile] relics %d, ranks %d, weapon %s" % [p.relics.size(), ranks, p.weapon["id"]])
	var pool: Array = GameData.floors()[G.floor_index]["pool"]
	var total := 0
	for tick in 1800:
		while G.enemies.size() < 14:
			var s := World.free_spot(G.room, p, 50, World.M_FLYER)
			var e := Combat.spawn_enemy(TB.pick(pool), s.x, s.y, randf() < 0.2, true)
			e.max_hp *= 40
			e.hp = e.max_hp
		p.hp = p.max_hp
		p.invuln = 1.0
		Keys.tick()
		var t0 := Time.get_ticks_usec()
		tick_secs = {}
		_one(p)
		var tus := Time.get_ticks_usec() - t0
		total += tus
		if tus > 10000:
			worst_ticks.append([tus, tick_secs.duplicate(), tick])
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}
	var kinds := {}
	for k in G.pickups: kinds[k.kind] = kinds.get(k.kind, 0) + 1
	print("[profile] pickups ", kinds)
	var bk := {}
	for b in G.pbullets: bk[b.kind + "/" + str(b.homing > 0) + "/" + str(b.split) + "/" + str(b.pierce)] = bk.get(b.kind + "/" + str(b.homing > 0) + "/" + str(b.split) + "/" + str(b.pierce), 0) + 1
	print("[profile] shots ", bk)
	print("[profile] total %.2f ms/tick; shots %d, eshots %d, fx %d, sparks %d" % [total / 1800000.0, G.pbullets.size(), EBullets.n, Fx.n, Juice.spark_n])
	var keys := secs.keys()
	keys.sort_custom(func(a, b): return secs[a] > secs[b])
	for k in keys:
		print("  %-16s %.3f ms/tick" % [k, secs[k] / 1800000.0])
	worst_ticks.sort_custom(func(a, b): return a[0] > b[0])
	print("[profile] ticks over 10 ms: %d" % worst_ticks.size())
	for wt in worst_ticks.slice(0, 6):
		var parts := []
		for k in wt[1]:
			if wt[1][k] > 700:
				parts.append("%s %.1f" % [k, wt[1][k] / 1000.0])
		print("  tick %d: %.1f ms (%s)" % [wt[2], wt[0] / 1000.0, ", ".join(parts)])
	get_tree().quit()

var tick_secs := {}
var worst_ticks := []   # [us, {section: us}]

func _t(name: String, c: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	c.call()
	var us := Time.get_ticks_usec() - t0
	secs[name] = secs.get(name, 0) + us
	tick_secs[name] = us

func _one(p: Player) -> void:
	var dt := TB.DT
	G.time += dt
	_t("effects.tick", func(): Effects.tick(dt))
	_t("player", func(): Combat.update_player(p, dt))
	_t("enemies", func(): Combat.update_enemies(dt))
	_t("pbullets", func(): Combat.update_pbullets(dt))
	_t("ebullets", func(): EBullets.update(dt))
	_t("pickups", func(): Combat.update_pickups(dt))
	_t("bombs", func(): Combat.update_bombs(dt))
	_t("zones", func(): Combat.update_zones(dt))
	_t("hazards", func(): Hazards.update(dt))
	_t("fx", func(): Fx.update(dt))
	_t("juice", func(): Juice.update(dt, p))
	var keep := []
	for w in G.swings:
		w["t"] -= dt
		if w["t"] > 0:
			keep.append(w)
	G.swings = keep
