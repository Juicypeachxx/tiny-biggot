extends Node
## Every trait for lag and runaway numbers (his word, 11 Oct: "check every trait for lag and bugs",
## after a clip of a run at 14 to 19 frames a second with 7704% crit). Run:
##   godot --headless --path . res://tests/trait_lag_test.tscn -- --no-save [--kind=relic] [--part=N --parts=M]
## Each trait at its most ranks (or each relic, --kind=relic) on THE ALCHEMIST in a live fight: foes
## that die and come back, autofire, a roll now and then and the special when ready, TICKS ticks.
## Measured: the logic time per tick (median, worst) and the hero's numbers when it was taken and
## after the fight and CALM ticks with no foe (so a buff has worn off): crit, damage, fire rate,
## shots, health, to catch one that keeps stacking for good.
## Prints the slowest, then every problem as a FAIL line, then "trait lag test: PASSED".

const TICKS := 600
const CALM := 600            # ticks with no foe after the fight, for buffs to wear off
const FOES := 14
const SLOW_MEDIAN := 6.0     # ms of logic a tick, median (the content test's heavy fight: about 3)
const SLOW_WORST := 60.0     # ms, one tick
const GROW := { "crit": 0.05, "dmg": 0.25, "rate": 0.25, "count": 2.0, "max_hp": 4.0 }   # most it may grow in the fight (crit: +100 points; dmg, rate: +50%)

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL lag: ", msg)

func _hero(id: String) -> int:
	for i in GameData.heroes().size():
		if GameData.heroes()[i]["id"] == id:
			return i
	return 0

func _sheet(p: Player) -> Dictionary:
	return { "crit": p.crit, "dmg": p.dmg, "rate": p.rate, "count": float(p.count), "max_hp": float(p.max_hp) }

func _run_one(kind: String, id: String) -> Dictionary:
	seed(hash(id))
	G.hero_index = _hero("alchemist")
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = true
	var p := G.player
	p.oath_picks = 0
	p.special_picks = 0
	p.pending = 0
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.enemies.clear()
	G.room.waves_left = 0
	G.locked = true
	G.state = &"play"
	Meta.opts["autofire"] = true
	if kind == "relic":
		G.add_relic(p, Relics.by_id(id))
	else:
		var t: Dictionary = Traits.by_id(id)
		for k in t["max"]:
			p.pending += 1
			G.take_trait(t)
	G.state = &"play"
	G.tchoice = {}
	G.choice = {}
	Effects.recount_tags(p)
	var before := _sheet(p)
	var types := ["slime", "skeleton", "bat", "cultist", "mushroom"]
	var times := []
	var worst := 0.0
	for tick in TICKS:
		while G.enemies.size() < FOES:
			var e := Combat.spawn_enemy(types[randi() % types.size()], randf_range(60, TB.SW - 60), randf_range(60, TB.SH - 60), false, true)
			e.max_hp *= 2.0
			e.hp = e.max_hp
		p.hp = p.max_hp
		var t0 := Time.get_ticks_usec()
		Keys.tick()
		Keys._trig[&"special"] = true
		if tick % 50 == 25:
			Keys._trig[&"roll"] = true
		G.update(TB.DT)
		var ms := (Time.get_ticks_usec() - t0) / 1000.0
		times.append(ms)
		worst = maxf(worst, ms)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}
			G.tome = {}
		if G.room == null or not G.locked:
			G.locked = true
	var kills: int = G.run_stats.get("kills", 0)
	G.enemies.clear()
	for tick in CALM:   # no foe: buffs and fights wear off
		p.hp = p.max_hp
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}
			G.tome = {}
		G.enemies.clear()
	times.sort()
	return { "id": id, "median": times[times.size() / 2], "worst": worst, "before": before, "after": _sheet(p), "kills": kills }

func _ready() -> void:
	var kind := DebugArgs.get_str("kind") if DebugArgs.has("kind") else "trait"
	var ids: Array = []
	if kind == "relic":
		ids = G.relic_pool().map(func(r): return r["id"])
	else:
		ids = Traits.all().map(func(t): return t["id"])
	var parts := DebugArgs.get_int("parts", 1)
	var part := DebugArgs.get_int("part", 0)
	var mine: Array = []
	for i in ids.size():
		if i % parts == part:
			mine.append(ids[i])
	var res: Array = []
	var t_start := Time.get_ticks_msec()
	for id in mine:
		res.append(_run_one(kind, id))
	res.sort_custom(func(a, b): return a["median"] > b["median"])
	print("[lag] %d %ss, %.0f s; the slowest by median logic ms a tick:" % [res.size(), kind, (Time.get_ticks_msec() - t_start) / 1000.0])
	for r in res.slice(0, 12):
		print("[lag]   %-16s median %5.2f  worst %6.1f  kills %d" % [r["id"], r["median"], r["worst"], r["kills"]])
	for r in res:
		if r["median"] > SLOW_MEDIAN:
			fail("%s %s: median %.2f ms a tick of logic (over %.0f)" % [kind, r["id"], r["median"], SLOW_MEDIAN])
		if r["worst"] > SLOW_WORST:
			fail("%s %s: one tick took %.1f ms (over %.0f)" % [kind, r["id"], r["worst"], SLOW_WORST])
		for k in GROW:
			var b: float = r["before"][k]
			var a: float = r["after"][k]
			var grew := (a - b) if k in ["crit", "count", "max_hp"] else (a / maxf(0.001, b) - 1.0)
			if grew > GROW[k]:
				fail("%s %s: %s went from %.2f to %.2f for good in %d ticks of fighting (%d kills)" % [kind, r["id"], k, b, a, TICKS, r["kills"]])
	print("trait lag test: PASSED" if fails == 0 else "trait lag test: %d FAILED" % fails)
	get_tree().quit()
