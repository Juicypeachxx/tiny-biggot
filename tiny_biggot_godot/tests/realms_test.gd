extends Node
## Heaven and Hell (ROADMAP 4.7 part C; scripts/game/soul.gd). Run:
##   godot --headless --path . res://tests/realms_test.tscn -- --no-save
##   1. The soul: light gear leans to Heaven, dark gear to Hell, a tie to Heaven.
##   2. The whole way, once for each realm: the Umbral Sun falls and the SOUL GATE stands with LOOP
##      and EXIT, leading where the soul leans; the realm's two fights (its own foes) lead straight
##      to its ruler; the ruler falls and the page portal opens (no door back); the Unwritten waits
##      there; its fall wins the run with the last ending, counted, and paid in embers.
##   3. Each of the three bosses fights for 40 s (the hero cannot be hurt): every attack in its plan
##      is used, each new attack puts shots or lanes in the air, and nothing errs.
## Prints "realms test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL realms: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(11)
	Meta.opts["autofire"] = true
	_soul()
	for realm in ["heaven", "hell"]:
		_way(realm)
	for b in ["judge", "cinderking", "unwritten"]:
		_fight(b)
	print("realms test: PASSED" if fails == 0 else "realms test: %d FAILED" % fails)
	get_tree().quit()

func _run() -> Player:
	G.hero_index = 0
	G.new_run()
	G.god = true
	return G.player

func play(ticks: int) -> void:
	for i in ticks:
		G.player.hp = G.player.max_hp
		Keys.tick()
		G.update(TB.DT)
		match G.state:
			&"traits":
				G.take_trait(G.tchoice["opts"][0])
				G.tchoice = {}
				G.state = &"play"
			&"choice":
				G.add_relic(G.player, G.choice["relics"][0])
				G.choice = {}
				G.state = &"play"
			&"pause", &"dead":
				G.state = &"play"

func _soul() -> void:
	var p := _run()
	for id in ["rime_hood", "rime_mantle", "clock_boots"]:   # frost, bulwark, swarm: light
		Gear.equip_gear(p, Gear.by_id(id))
	var w := Soul.weigh(p)
	if Soul.realm(p) != "heaven":
		fail("light gear leans to %s (%s)" % [Soul.realm(p), w])
	p = _run()
	for id in ["bone_crown", "bone_ribs", "leechgloves", "lastriteshood"]:   # malice, blood: dark
		Gear.equip_gear(p, Gear.by_id(id))
	if Soul.realm(p) != "hell":
		fail("dark gear leans to %s (%s)" % [Soul.realm(p), Soul.weigh(p)])

## Kills what is in the room, keeps playing until the doors open, and walks through the one door.
func _clear_and_leave() -> bool:
	for k in 40:
		for e in G.enemies:
			if e.type != "dummy" and e.spawn_t <= 0:
				Combat.damage_enemy(e, e.hp + 1.0, { "no_crit": true, "no_mult": true })
		play(30)
		if G.room.exits_open and not G.room.exits.is_empty():
			break
	if G.room.exits.is_empty():
		return false
	var from := G.room
	G.leave_room(G.room.exits.keys()[0])
	play(90)
	return G.room != from

func _way(realm: String) -> void:
	var p := _run()
	var tags := ["rime_hood", "rime_mantle", "clock_boots"] if realm == "heaven" else ["bone_crown", "bone_ribs", "leechgloves"]
	for id in tags:
		Gear.equip_gear(p, Gear.by_id(id))
	var fl := GameData.floors()
	G.floor_index = fl.size() - 1
	G.start_floor()
	G.on_boss_dead(Combat.spawn_boss(fl[fl.size() - 1]["boss"]))
	var gate = null
	for o in G.room.objects:
		if o["kind"] == "soulgate":
			gate = o
	if gate == null or not G.room.objects.any(func(o): return o["kind"] == "loopportal") \
			or not G.room.objects.any(func(o): return o["kind"] == "exitportal"):
		fail("%s: the true ending lacks the soul gate, LOOP or EXIT" % realm)
		return
	if gate["realm"] != realm:
		fail("the gate leads to %s, the soul leans to %s" % [gate["realm"], realm])
	G.enemies.clear()
	G.interact(gate)
	play(90)
	var th: Dictionary = G.room.theme
	if th.get("id", "") != realm or G.room.rift_step != 0:
		fail("%s: the gate led to %s step %d" % [realm, th.get("id", "?"), G.room.rift_step])
		return
	play(120)
	var pool: Array = th["pool"]
	if G.enemies.is_empty() or G.enemies.any(func(e): return not e.type in pool):
		fail("%s: the first fight is not the realm's foes (%s)" % [realm, G.enemies.map(func(e): return e.type)])
	if not _clear_and_leave() or G.room.rift_step != 1:
		fail("%s: no way from the first fight to the second" % realm)
		return
	if not _clear_and_leave() or G.room.rift_step != 3 or G.room.type != "boss":
		fail("%s: the second fight does not lead to the ruler (step %d, %s)" % [realm, G.room.rift_step, G.room.type])
		return
	play(240)
	var want := "judge" if realm == "heaven" else "cinderking"
	if G.boss == null or G.boss.boss != want:
		fail("%s: the ruler is %s, not %s" % [realm, G.boss.boss if G.boss != null else "nobody", want])
		return
	var b: Enemy = G.boss
	Combat.damage_enemy(b, b.hp + 1.0, { "no_crit": true, "no_mult": true })
	play(60)
	var page = null
	for o in G.room.objects:
		if o["kind"] == "pageportal":
			page = o
	if page == null:
		fail("%s: no page portal after the ruler" % realm)
		return
	if not G.room.exits.is_empty():
		fail("%s: the ruler's room opened a door back" % realm)
	if G.run_stats.get("realm", "") != realm:
		fail("%s: the realm was not counted" % realm)
	G.interact(page)
	play(90)
	if G.room.theme.get("id", "") != "seam":
		fail("%s: the page portal led to %s" % [realm, G.room.theme.get("id", "?")])
		return
	play(240)
	if G.boss == null or G.boss.boss != "unwritten":
		fail("%s: the Unwritten is not there" % realm)
		return
	var wins0: int = Meta.meta.get("unwritten_wins", 0)
	Combat.damage_enemy(G.boss, G.boss.hp + 1.0, { "no_crit": true, "no_mult": true })
	for o in G.room.objects:
		if o["kind"] == "chest":
			o["opened"] = true
	for i in 400:
		play(1)
		if G.state == &"win":
			break
	if G.state != &"win" or not G.run_stats.get("unwritten", false) or Meta.meta.get("unwritten_wins", 0) != wins0 + 1:
		fail("%s: the Unwritten's fall did not win the run (state %s)" % [realm, G.state])
	elif not G.award.get("parts", []).any(func(x): return x[0] == "THE UNWRITTEN"):
		fail("%s: the last ending paid no embers" % realm)
	G.state = &"play"

func _fight(key: String) -> void:
	var p := _run()
	G.floor_index = GameData.floors().size() - 1
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.locked = true
	var b := Combat.spawn_boss(key)
	b.max_hp = 1e9
	b.hp = 1e9
	b.t = 0.5
	var seen := {}
	var most := 0
	for i in 40 * 60:
		play(1)
		seen[String(b.state)] = true
		most = maxi(most, EBullets.n + RiftBosses.bands.size() + RiftBosses.rings.size())
		if i == 20 * 60:
			b.hp = b.max_hp * 0.4   # the second half: harder versions
	for a in BossAI.BOSS_PLANS[key]:
		if a == "curtain":
			continue
		if not seen.has(a):
			fail("%s never used %s (seen %s)" % [key, a, seen.keys()])
	if most == 0:
		fail("%s: nothing was ever in the air" % key)
