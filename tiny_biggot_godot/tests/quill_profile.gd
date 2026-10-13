extends Node
## His slow fight of 8 Oct (a screen recording: 31 fps, LOGIC 16.3 ms, the screen under giant
## shots): floor 12 (THE INKWELL), level 52, THE BLANK QUILL at 102 attacks a second, 12 shots an
## attack, 3626% crit, the RING OF BIGNESS, 40 relics and 40 trait ranks. Per-section logic cost
## per tick, and what is alive. Run:
##   godot --headless --path . res://tests/quill_profile.tscn -- --no-save [--secs=30]
## Diagnosis only; not part of check.sh.

var secs := {}
var ticks := 0

func _ready() -> void:
	await get_tree().process_frame
	seed(12)
	G.hero_index = DebugArgs.get_int("hero", 0)
	G.new_run()
	G.floor_index = mini(11, GameData.floors().size() - 1)
	G.floor_d["depth"] = 12
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
	Weapons.equip_weapon(p, Weapons.by_id(DebugArgs.get_str("weapon", "blankquill")))
	# His gear in the recording (two TWIN-SOUL RINGs, the RING OF BIGNESS in his pack; --bigness wears it instead).
	for id in ["owlhelm", "matriarchrobe", "sevenleague", "sapper_fuse", "fiendchains", "twinring"]:
		Gear.equip_gear(p, Gear.by_id(id))
	Gear.equip_gear(p, Gear.by_id("bigring" if DebugArgs.has("bigness") else "twinring"))
	p.count += DebugArgs.get_int("count", 11)
	p.rate *= float(DebugArgs.get_int("rate", 40))
	if DebugArgs.has("heavy"):
		p.heavy_n = 6   # the HEAVY BOLT trait: every 6th attack's shots x3 damage, x1.5 size
	p.crit = 36.26
	p.crit_mult = 5.0
	print("[quill] relics %d, ranks %d, weapon %s, %.0f attacks a second, %d shots, size %.2f" % [p.relics.size(), ranks,
		p.weapon["id"], Weapons.wrate(p), Weapons.wcount(p), Weapons.wsize(p)])
	var pool: Array = GameData.floors()[G.floor_index]["pool"]
	var widow := Combat.spawn_enemy("inkwidow", 14.0 * TB.TS, 6.0 * TB.TS, false, true)
	widow.max_hp *= 400
	widow.hp = widow.max_hp
	var n := DebugArgs.get_int("secs", 30) * 60
	var total := 0
	var worst := 0
	var most := {}
	for tick in n:
		while G.enemies.size() < 14:
			var s := World.free_spot(G.room, p, 50, World.M_FLYER)
			var e := Combat.spawn_enemy(TB.pick(pool), s.x, s.y, randf() < 0.2, true)
			e.max_hp *= 40
			e.hp = e.max_hp
		p.hp = p.max_hp
		p.invuln = 1.0
		Keys.tick()
		var t0 := Time.get_ticks_usec()
		if DebugArgs.has("full"):
			G.update(TB.DT)   # the whole tick, as the game runs it
		else:
			_one(p)
		var us := Time.get_ticks_usec() - t0
		if us > 15000 and not DebugArgs.has("full"):
			var parts := []
			for k in cur:
				if cur[k] > 1500:
					parts.append("%s %.1f" % [k, cur[k] / 1000.0])
			print("[quill] spike at t=%.1fs: %.1f ms (%s); %d shots, %d foes, %d labels" % [tick / 60.0, us / 1000.0, ", ".join(parts),
				G.pbullets.size(), G.enemies.size(), Juice.labels.size()])
		cur = {}
		total += us
		worst = maxi(worst, us)
		ticks += 1
		for k in ["pbullets", "fx", "texts", "labels", "buffs", "fams", "zones", "bombs", "pickups"]:
			var v := _count(k, p)
			most[k] = maxi(most.get(k, 0), v)
		if DebugArgs.has("heavy"):
			for b in G.pbullets:
				most["r"] = maxf(most.get("r", 0.0), b.r)
		if tick % 600 == 599:
			print("[quill] t=%ds: %.2f ms a tick so far; size %.2f, rate %.0f/s, %d shots, %d buffs, %d fx, %d labels; queue %d, %s" % [(tick + 1) / 60,
				total / 1000.0 / ticks, Weapons.wsize(p), Weapons.wrate(p), G.pbullets.size(), p.buffs.size(), Fx.n, Juice.labels.size(),
				Effects.queue.size(), Effects.stats])
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}
	print("[quill] total %.2f ms a tick (worst %.1f); most alive: %s" % [total / 1000.0 / ticks, worst / 1000.0, most])
	var pk := {}
	for k in G.pickups: pk[k.kind] = pk.get(k.kind, 0) + 1
	var zk := {}
	for z in G.zones: zk[z["kind"]] = zk.get(z["kind"], 0) + 1
	print("[quill] pickups %s; zones %s" % [pk, zk])
	var keys := secs.keys()
	keys.sort_custom(func(a, b): return secs[a] > secs[b])
	for k in keys:
		print("  %-16s %.3f ms/tick" % [k, secs[k] / 1000.0 / ticks])
	get_tree().quit()

func _count(k: String, p: Player) -> int:
	match k:
		"pbullets": return G.pbullets.size()
		"fx": return Fx.n
		"texts": return Fx.texts.size()
		"labels": return Juice.labels.size()
		"buffs": return p.buffs.size()
		"fams": return G.temp_fams.size()
		"zones": return G.zones.size()
		"bombs": return G.bombs.size()
		"pickups": return G.pickups.size()
	return 0

var cur := {}   # this tick's sections (spikes are printed with them)

func _t(name: String, c: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	c.call()
	var us := Time.get_ticks_usec() - t0
	secs[name] = secs.get(name, 0) + us
	cur[name] = us

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
	_t("power", func(): Combat.track_power(dt))
	_t("ambience", func(): Ambience.tick(p))
	_t("eventrooms", func(): EventRooms.update(dt))
	_t("barks", func(): Barks.update(dt))
	var keep := []
	for w in G.swings:
		w["t"] -= dt
		if w["t"] > 0:
			keep.append(w)
	G.swings = keep
