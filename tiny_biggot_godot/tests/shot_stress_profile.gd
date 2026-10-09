extends Node
## 32.2: where a tick goes in the arsenal test's hardest case (a weapon with 999 more
## projectiles, four sturdy foes, the shot cap full). Per-section logic ms per tick.
##   godot --headless --path . res://tests/shot_stress_profile.tscn -- --no-save --weapon=steamrepeater [--extra=999] [--secs=8]
## Diagnosis only; not part of check.sh.

var secs := {}

func _ready() -> void:
	await get_tree().process_frame
	var id := DebugArgs.get_str("weapon") if DebugArgs.has("weapon") else "steamrepeater"
	var extra := DebugArgs.get_int("extra", 999)
	var n := DebugArgs.get_int("secs", 8) * 60
	seed(hash(id) + extra)
	G.hero_index = 0
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = true
	var p := G.player
	p.oath_picks = 0
	p.pending = 0
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	for c in range(TB.IX0, TB.IX0 + TB.IW):
		for r in range(TB.IY0, TB.IY0 + TB.IH):
			G.room.set_tile(c, r, World.T_FLOOR)
	G.locked = true
	G.state = &"play"
	Weapons.equip_weapon(p, Weapons.by_id(id))
	p.count += extra
	var hold := Vector2(14.0 * TB.TS, 13.0 * TB.TS)
	for i in 4:
		var e := Combat.spawn_enemy("skeleton", hold.x - 60.0 + i * 40.0, hold.y - 90.0 - (i % 2) * 20.0, false, true)
		e.speed = 0.0
		e.max_hp = 1e7
		e.hp = 1e7
	Meta.opts["autofire"] = true
	var total := 0
	var worst := 0
	var times := PackedInt32Array()
	for t in n:
		p.hp = p.max_hp
		p.x = hold.x
		p.y = hold.y
		Keys.tick()
		var t0 := Time.get_ticks_usec()
		_one(p)
		var us := Time.get_ticks_usec() - t0
		total += us
		times.append(us)
		worst = maxi(worst, us)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}
	times.sort()
	print("[shots] %s +%d: %.2f ms a tick (median %.2f, worst %.1f); shots %d, merged %d" % [id, extra, total / 1000.0 / n,
		times[n / 2] / 1000.0, worst / 1000.0, G.pbullets.size(), Effects.stats.get("merged_shots", 0)])
	var keys := secs.keys()
	keys.sort_custom(func(a, b): return secs[a] > secs[b])
	for k in keys:
		print("  %-14s %.3f ms a tick" % [k, secs[k] / 1000.0 / n])
	get_tree().quit()

func _t(name: String, c: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	c.call()
	secs[name] = secs.get(name, 0) + Time.get_ticks_usec() - t0

## The same steps as Game.update_play, each timed.
func _one(p: Player) -> void:
	var dt := TB.DT
	G.run_stats["time"] += dt
	G.time += dt
	if G.hitstop > 0:
		G.hitstop -= dt
		return
	_t("effects.tick", func(): Effects.tick(dt))
	_t("player", func(): Combat.update_player(p, dt))
	_t("enemies", func(): Combat.update_enemies(dt))
	_t("pbullets", func(): Combat.update_pbullets(dt))
	_t("ebullets", func(): EBullets.update(dt))
	_t("pickups", func(): Combat.update_pickups(dt))
	_t("zones", func(): Combat.update_zones(dt))
	_t("fx", func(): Fx.update(dt))
	_t("juice", func(): Juice.update(dt, p))
	var keep := []
	for w in G.swings:
		w["t"] -= dt
		if w["t"] > 0:
			keep.append(w)
	G.swings = keep
