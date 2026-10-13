extends Node
## Stage 55 THE LAST LAUGH (his word, 11 Oct: "after final boss there is next final final boss that
## chooses form of most gathered alignment"; scripts/entities/finale.gd, FINALE.md). Run:
##   godot --headless --path . res://tests/stage55_test.tscn -- --no-save
##   1. The four: each alignment has its boss (data, three looks, plans, its followers and their
##      pictures) and its arena (a tile set and a sound).
##   2. The pick: the alignment gathered most; a tie goes to one of the tied.
##   3. A won run is not over: the banner, the arena of its alignment, its boss with its three forms;
##      it falls, its chests, and the win with THE LAST LAUGH's embers.
##   4. Falling to it still wins the run (and the last laugh is its).
##   5. Every move of every form plays out and comes to an end.
##   6. A believer flexes: MOGGED, slower for a moment. A tripped donkey takes half again.
##   7. --classic: a won run ends at once, as it always did.
## Prints "stage55 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage55: ", msg)

func _run(hero: int = 0) -> Player:
	G.hero_index = hero
	G.new_run()
	G.god = true
	G.floor_index = 4
	G.start_floor()
	G.state = &"play"
	return G.player

func play(ticks: int, heal: bool = true) -> void:
	for i in ticks:
		if heal:
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
			&"pause":
				G.state = &"play"

func _cull(b: Enemy) -> void:
	for e in G.enemies.duplicate():
		if e != b:
			G.enemies.erase(e)

func _ready() -> void:
	await get_tree().process_frame
	Resolve.off = true   # 56.3: blows drive the forms here; RESOLVE is tests/stage56_test
	seed(55)
	Meta.opts["autofire"] = true
	_data()
	_pick()
	for al in Finale.BOSS:
		_flow(al)
	_lost()
	_moves()
	_mogged()
	_classic()
	Meta.meta["trophies"] = {}
	print("[stage55] ", Finale.stats)
	print("stage55 test: PASSED" if fails == 0 else "stage55 test: %d FAILED" % fails)
	get_tree().quit()

## 1. The four bosses, their looks, plans, followers and arenas.
func _data() -> void:
	var moves := {}
	for al in Finale.BOSS:
		var key: String = Finale.BOSS[al]
		if not GameData.BOSSES.has(key) or Finale.ALIGN.get(key, "") != al:
			fail("%s: no boss %s" % [al, key])
			continue
		var d: Dictionary = GameData.BOSSES[key]
		for sp in [d["sprite"], d["sprite"] + "_s2", d["sprite"] + "_s3"]:
			if not Img.has(sp):
				fail("%s has no picture %s" % [key, sp])
		if not BossAI.BOSS_PLANS.has(key) or not BossAI.STAGE_PLANS.has(key) or not BossAI.STAGE_LINE.has(key) or not BossAI.BOSS_SUMMONS.has(key):
			fail("%s is missing a plan" % key)
			continue
		for f in BossAI.BOSS_SUMMONS[key]:
			var fd: Dictionary = GameData.ENEMIES.get(f, {})
			if fd.is_empty() or not Img.has(fd["sprite"]) or not Img.has(fd["sprite"] + "_elite"):
				fail("%s's follower %s is missing (or its pictures)" % [key, f])
			if not GameData.SPRITE_COLOR.has(f) or not GameData.ENEMY_XP.has(f) or not Barks.FOE_BARKS.has(f):
				fail("%s's follower %s has no colour, xp or lines" % [key, f])
		if not Barks.BOSS_LINES.has(key):
			fail("%s has no opening line" % key)
		for nm in Finale.FORMS[key]:
			if TB.text_w(nm) > TB.SW - 120:
				fail("%s: the form name %s is too wide for the bar" % [key, nm])
		var th := Themes.by_id(Finale.ARENA[al])
		if th.is_empty() or th.get("finale", "") != al or th.get("guardian", "") != key or not th.get("realm", false):
			fail("%s: no arena %s" % [al, Finale.ARENA[al]])
		elif not Img.has(th["kit"]):
			fail("%s: the arena has no tiles %s" % [al, th["kit"]])
		if not Ambience.RIFT.has(Finale.ARENA[al]):
			fail("%s: the arena has no sound" % al)
		for m in BossAI.BOSS_PLANS[key] + BossAI.STAGE_PLANS[key][0] + BossAI.STAGE_PLANS[key][1]:
			moves[m] = true
	for s in ["believer_flex", "believer_flex_elite", "fp_table"]:
		if not Img.has(s):
			fail("no picture " + s)
	for k in Finale.PROPS + ["carrot", "meteor", "stamp"]:
		if not Img.has("fp_" + k):
			fail("no picture fp_" + k)

## 2. The alignment gathered most.
func _pick() -> void:
	var p := _run()
	for k in Alignments.KEYS:
		p.set("al_" + k, 0)
	p.al_chaos = 4
	p.al_good = 2
	if Finale.pick(p) != "chaos":
		fail("4 CHAOTIC and 2 GOOD picked %s" % Finale.pick(p))
	p.al_evil = 4
	var seen := {}
	for i in 40:
		seen[Finale.pick(p)] = true
	if seen.size() != 2 or not seen.has("chaos") or not seen.has("evil"):
		fail("a tie of CHAOTIC and EVIL picked %s" % [seen.keys()])

## 3. A won run: the laugh, the arena, the three forms, the fall, the win.
func _flow(al: String) -> void:
	seed(al.hash())
	var p := _run()
	for k in Alignments.KEYS:
		p.set("al_" + k, 1)
	p.set("al_" + al, 5)
	G.run_stats["chapter"] = 4
	G.on_win()
	if G.state != &"play" or G.run_stats.get("finale", "") != al:
		fail("%s: a won run ended at once (state %s, finale %s)" % [al, G.state, G.run_stats.get("finale", "")])
		return
	G.on_win()   # (walking into the way out again does not end it either)
	if G.state != &"play":
		fail("%s: a second win request ended the run" % al)
	play(int((Finale.WAIT + 1.0) * 60))
	if G.room.theme.get("id", "") != Finale.ARENA[al]:
		fail("%s: not in the arena after the laugh (room %s)" % [al, G.room.theme.get("id", G.room.type)])
		return
	if p.hp != p.max_hp:
		fail("%s: not healed for the fight" % al)
	play(240)
	var b := G.boss
	if b == null or b.boss != Finale.BOSS[al]:
		fail("%s: its boss did not come (%s)" % [al, b.boss if b != null else "none"])
		return
	var base: float = GameData.BOSSES[b.boss]["hp"]
	if b.max_hp < base * 1.4:
		fail("%s: health %.0f does not keep pace with Chapter IV" % [b.boss, b.max_hp])
	# its three forms: break it down a stage at a time
	for st in [2, 3]:
		_cull(b)
		Combat.damage_enemy(b, (b.hp + Armor.shown(b)) * 2.0 + 10.0, { "no_crit": true, "no_mult": true })
		for i in 6 * 60:   # (a chilled boss changes form at half speed too)
			play(1)
			if b.stage == st and b.state != &"stagebreak":
				break
		if b.stage != st:
			fail("%s: not in form %d (stage %d, state %s)" % [b.boss, st, b.stage, b.state])
		elif Finale.bar_name(b) != Finale.FORMS[b.boss][st - 1]:
			fail("%s: the bar shows %s in form %d" % [b.boss, Finale.bar_name(b), st])
	play(60)
	_cull(b)
	Combat.damage_enemy(b, (b.hp + Armor.shown(b)) * 2.0 + 10.0, { "no_crit": true, "no_mult": true })
	if b.hp > 0 or not G.run_stats.get("finale_won", false):
		fail("%s: did not fall (hp %.0f)" % [b.boss, b.hp])
		return
	var chests := G.room.objects.filter(func(o): return o["kind"] == "chest")
	if chests.size() < 2:
		fail("%s: %d chests, not 2" % [b.boss, chests.size()])
	for o in chests:
		o["opened"] = true
	play(int(7.0 * 60))
	if G.state != &"win":
		fail("%s: the run was not won after its fall (state %s)" % [b.boss, G.state])
		return
	if not G.award["parts"].any(func(x): return x[0] == "THE LAST LAUGH" and x[1] == Finale.EMBERS):
		fail("%s: no LAST LAUGH embers: %s" % [b.boss, G.award["parts"]])
	G.state = &"play"

## 4. Fall to it, and the run is still won.
func _lost() -> void:
	seed(4)
	var p := _run()
	G.on_win()
	play(int((Finale.WAIT + 1.0) * 60))
	if not Finale.arena():
		fail("no arena before the fall test")
		return
	G.god = false
	G.on_death("the test")
	if G.state != &"win" or not G.run_stats.get("finale_lost", false):
		fail("falling to the final final boss lost the run (state %s)" % G.state)
	G.god = true
	G.state = &"play"

## 5. Every move of every form: it starts, plays out and ends in a rest, with shots or its things.
func _moves() -> void:
	for al in Finale.BOSS:
		var key: String = Finale.BOSS[al]
		var plans: Array = [BossAI.BOSS_PLANS[key]] + BossAI.STAGE_PLANS[key]
		for st in [1, 2, 3]:
			seed(key.hash() + st)
			var p := _run()
			G.run_stats["finale"] = al
			G.enter_room(World.make_room(G.floor_d, "boss", "", "s", { "theme": Finale.ARENA[al], "step": 3 }))
			G.locked = true
			var b := Combat.spawn_boss(key)
			b.max_hp = 1e9
			b.hp = 1e9 * (1.0 if st == 1 else (0.6 if st == 2 else 0.3))
			b.stage = st
			b.t = 0.0
			b.state = &"pick"
			play(2)
			for m in plans[st - 1]:
				if m in ["summon", "curtain"]:
					continue
				_cull(b)
				b.state = StringName(m)
				b.st = 0.0
				b.sub = 0
				b.t = 0.0
				b.repeat = 0
				b.cycle = 0
				var ended := false
				for i in 12 * 60:
					play(1)
					if b.hp < b.max_hp * 0.05:
						b.hp = b.max_hp * 0.3
					if b.state != StringName(m):
						ended = true
						break
				if not ended:
					fail("%s form %d: %s never ended (sub %d, t %.2f)" % [key, st, m, b.sub, b.t])
				b.state = &"pick"
				play(1)
	# every one of Finale's own moves was played at least once somewhere above
	for k in ["trip", "tax", "doomsday", "nap", "knock", "crash", "laser", "drop_carrot", "drop_meteor", "drop_stamp", "tape"]:
		if Finale.stats.get(k, 0) == 0:
			fail("%s never happened" % k)

## 6. MOGGED; a tripped donkey.
func _mogged() -> void:
	seed(6)
	var p := _run()
	G.run_stats["finale"] = "chaos"
	G.enter_room(World.make_room(G.floor_d, "boss", "", "s", { "theme": "f_endtimes", "step": 3 }))
	G.locked = true
	G.boss_delay = null
	Finale.mog_t = 0.0
	Finale.mog_cd = 0.0
	var bel := Combat.spawn_enemy("believer", p.x + 30.0, p.y, false, true)
	bel.x = p.x + 30.0
	bel.y = p.y
	bel.max_hp = 1e6
	bel.hp = 1e6
	var mogged := false
	for i in 4 * 60:
		bel.x = p.x + 30.0
		bel.y = p.y
		bel.state = &"idle"
		play(1)
		if Finale.mog_t > 0.0:
			mogged = true
			break
	if not mogged:
		fail("a believer close by never MOGGED you")
	elif absf(Finale.speed_mult(p) - Finale.MOG_SLOW) > 0.001:
		fail("MOGGED, but the speed is x%.2f" % Finale.speed_mult(p))
	play(int((Finale.MOG_T + 0.2) * 60))
	if Finale.speed_mult(p) != 1.0:
		fail("still MOGGED long after")
	# a donkey on his back takes half again
	var b := Combat.spawn_boss("braysalot")
	b.state = &"trip"
	b.sub = 1
	if absf(Finale.adjust_damage(b, 100.0) - 100.0 * Finale.VULN) > 0.01:
		fail("a tripped donkey takes x%.2f" % (Finale.adjust_damage(b, 100.0) / 100.0))
	b.state = &"rest"
	if Finale.adjust_damage(b, 100.0) != 100.0:
		fail("a donkey on his feet takes more than he should")

## 7. --classic: a won run ends at once.
func _classic() -> void:
	GameData.force_classic = true
	var p := _run()
	G.on_win()
	if G.state != &"win" or G.run_stats.has("finale"):
		fail("classic: a won run did not end at once (state %s)" % G.state)
	GameData.force_classic = false
	G.state = &"play"
