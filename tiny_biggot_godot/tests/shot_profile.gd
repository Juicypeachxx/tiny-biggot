extends Node
## Profiles the "screen full of shots in the start room" case (training
## dummies, a heavy build, the shot cap reached): per-section logic cost.
## Run: godot --headless --path . res://tests/shot_profile.tscn -- --no-save --hero=12 --floor=6 --weapon=worldeater --heavy
## Diagnosis only; not part of check.sh.

var secs := {}

func _ready() -> void:
	await get_tree().process_frame
	seed(11)
	G.hero_index = DebugArgs.get_int("hero", 0)
	G.new_run()
	G.floor_index = clampi(DebugArgs.get_int("floor", 0), 0, GameData.floors().size() - 1)
	if G.floor_index > 0:
		G.start_floor()
	var p: Player = G.player
	G.state = &"play"
	# --long: long-lived, bouncy shots so the room fills to the shot cap.
	if DebugArgs.has("long"):
		p.life *= 4.0
		p.bounce += 8
	if DebugArgs.has("nohoming"):
		p.homing = -100.0
	print("[profile] homing %.2f lens %s grow %.2f accel %.2f count %d rate %.2f weapon %s" % [Weapons.whoming(p), p.lens, p.g("grow"), p.g("accel"), Weapons.wcount(p), Weapons.wrate(p), p.weapon["id"]])
	var total := 0
	var shots := 0
	var ticks := DebugArgs.get_int("ticks", 1800)
	for tick in ticks:
		p.hp = p.max_hp
		p.invuln = 1.0
		Keys.tick()
		var t0 := Time.get_ticks_usec()
		_one(p)
		if tick >= 300:
			total += Time.get_ticks_usec() - t0
			shots += G.pbullets.size()
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}
	var n := float(ticks - 300)
	print("[profile] total %.3f ms/tick; avg shots %.0f, fx %d, sparks %d, texts %d, procs %d, dummies %d" % [
		total / 1000.0 / n, shots / n, Fx.n, Juice.spark_n, Fx.texts.size(), p.procs.size(), G.enemies.size()])
	var keys := secs.keys()
	keys.sort_custom(func(a, b): return secs[a] > secs[b])
	for k in keys:
		print("  %-16s %.3f ms/tick" % [k, secs[k] / 1000.0 / ticks])
	get_tree().quit()

func _t(name: String, c: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	c.call()
	secs[name] = secs.get(name, 0) + Time.get_ticks_usec() - t0

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
