extends Node
## Heaven and Hell (ROADMAP 4.7 part C; scripts/game/soul.gd). Run:
##   godot --headless --path . res://tests/realms_test.tscn -- --no-save
##   1. The soul: light gear leans to Heaven, dark gear to Hell, a tie to Heaven.
##   2. The whole way, once for each realm: the Umbral Sun falls and the SOUL GATE stands with LOOP
##      and EXIT, leading where the soul leans; the realm's two fights (its own foes) lead straight
##      to its ruler; the ruler falls and the page portal opens (no door back); the Unwritten waits
##      there; its fall wins the run with the last ending, counted, and paid in embers.
##   4. "You're going to Brazil" (brazil.gd): the Haggler catching you sends you to BRAZIL; a
##      scrounger's touch robs you (not with the Haggler's hat on); two fights lead to the Holy Cow;
##      it falls once and rises again in a third stage, falls for good and leaves the COW MILKER;
##      the Haggler killed leaves gold, his gun and his hat; neither prize is ever found elsewhere.
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
	for b in ["judge", "cinderking", "unwritten", "holycow"]:
		_fight(b)
	_brazil()
	_meet_haggler()
	Meta.meta["trophies"] = {}   # the guardians felled above leave trophies (7.2) that would make later runs stronger
	for b in BossAI.STAGE_PLANS:
		_stages(b)
	_reward()
	print("realms test: PASSED" if fails == 0 else "realms test: %d FAILED" % fails)
	get_tree().quit()

func _run() -> Player:
	G.hero_index = 0
	G.new_run()
	G.god = true
	return G.player

func play(ticks: int, every: Callable = Callable()) -> void:
	for i in ticks:
		G.player.hp = G.player.max_hp
		if every.is_valid():
			every.call(i)
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
		for e in G.enemies.duplicate():
			if e.type != "dummy" and e.spawn_t <= 0 and e.hp > 0:
				_fell(e)
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
	_fell(b)
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
	_fell(G.boss)
	for o in G.room.objects:
		if o["kind"] == "chest":
			o["opened"] = true
	play(30)
	# 12.2: end the story here (Heaven's way in this test), or turn the page (Hell's).
	var book = null
	var turn = null
	for o in G.room.objects:
		if o["kind"] == "n_endbook":
			book = o
		elif o["kind"] == "n_turnpage":
			turn = o
	if book == null or turn == null:
		fail("%s: no choice of ending the story or turning the page" % realm)
		return
	if realm == "hell":
		_chapter2(turn)
		return
	G.interact(book)
	for i in 400:
		play(1)
		if G.state == &"win":
			break
	if G.state != &"win" or not G.run_stats.get("unwritten", false) or Meta.meta.get("unwritten_wins", 0) != wins0 + 1:
		fail("%s: the Unwritten's fall did not win the run (state %s)" % [realm, G.state])
	elif not G.award.get("parts", []).any(func(x): return x[0] == "THE UNWRITTEN"):
		fail("%s: the last ending paid no embers" % realm)
	G.state = &"play"

## 12.2: the page turns: Chapter II's three floors, each with its own foes, then the Author.
func _chapter2(page: Dictionary) -> void:
	G.interact(page)
	play(90)
	if G.run_stats.get("chapter", 1) != 2 or GameData.floors().size() != GameData.FLOORS.size() + GameData.NEW_FLOORS.size() + 3:
		fail("chapter II: not begun (chapter %s, %d floors)" % [G.run_stats.get("chapter", 1), GameData.floors().size()])
		return
	for k in 3:
		var f := GameData.FLOORS.size() + GameData.NEW_FLOORS.size() + k
		if G.floor_index != f or GameData.floors()[f]["name"] != GameData.CHAPTER2[k]["name"]:
			fail("chapter II: on floor %d (%s), want %s" % [G.floor_index, GameData.floors()[G.floor_index]["name"], GameData.CHAPTER2[k]["name"]])
			return
		# 12.3: a hidden room of each chapter floor holds a torn page.
		G.enter_room(World.make_room(G.floor_d, "secret", "", "s", { "no_secret": true }))
		var pg = null
		for o in G.room.objects:
			if o["kind"] == "n_tornpage":
				pg = o
		if pg == null:
			fail("chapter II floor %d: no torn page in the hidden room" % (k + 1))
			return
		G.interact(pg)
		if G.run_stats.get("pages", 0) != k + 1:
			fail("chapter II floor %d: the page was not taken (%d)" % [k + 1, G.run_stats.get("pages", 0)])
		G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
		play(200)
		var ok2: Array = GameData.CHAPTER2[k]["pool"] + (GameData.floors()[mini(G.floor_index + 1, GameData.floors().size() - 1)]["pool"] if G.room.twist == "strangers" else [])
		for e in G.enemies:
			if not e.type in ok2 and e.type != "dummy":
				fail("chapter II floor %d: a foreign foe %s" % [k + 1, e.type])
				break
		G.enemies.clear()
		G.locked = false
		G.enter_room(World.make_room(G.floor_d, "boss", "", "s", { "no_secret": true }))
		play(240)
		if G.boss == null or G.boss.boss != GameData.CHAPTER2[k]["boss"]:
			fail("chapter II floor %d: the guardian is %s" % [k + 1, G.boss.boss if G.boss != null else "nobody"])
			return
		_fell(G.boss)
		play(60)
		if k < 2:
			var portal = null
			for o in G.room.objects:
				if o["kind"] == "portal":
					portal = o
			if portal == null:
				fail("chapter II floor %d: no way down" % (k + 1))
				return
			G.floor_index += 1
			G.start_floor()
	_redactor()
	if G.state != &"win" or not G.run_stats.get("author", false):
		fail("chapter II: the Author's fall did not win the run (state %s, author %s)" % [G.state, G.run_stats.get("author", false)])
	elif not G.award.get("parts", []).any(func(x): return x[0] == "CHAPTER II"):
		fail("chapter II: no embers for the chapter")
	G.state = &"play"
	G.run_stats["chapter"] = 1

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
	var third := BossAI.THIRD_PLANS.has(key)
	# The whole cycle must fit: 4 s a move, 40 s at least (35.2: the Unwritten's 13 moves took
	# up to 38 s, so a small shift in timing left its last two just outside a 40 s window).
	var secs := maxi(40, BossAI.BOSS_PLANS[key].size() * 4)
	for i in (secs + 40 if third else secs) * 60:
		play(1)
		seen[String(b.state)] = true
		most = maxi(most, EBullets.n + RiftBosses.bands.size() + RiftBosses.rings.size())
		if i % 300 == 0:
			_cull(b)   # (summons pile up otherwise, and a guardian with company does not summon)
		if third and i == secs * 60:
			Brazil.cow_rises(b)   # the third stage
			b.max_hp = 1e9
			b.hp = 1e9
	for a in BossAI.BOSS_PLANS[key] + BossAI.THIRD_PLANS.get(key, []):
		if a == "curtain":
			continue
		if not seen.has(a):
			fail("%s never used %s (seen %s)" % [key, a, seen.keys()])
	if most == 0:
		fail("%s: nothing was ever in the air" % key)

func _brazil() -> void:
	var p := _run()
	G.floor_index = 2
	G.start_floor()
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	var h := Combat.spawn_enemy("haggler", p.x + 4.0, p.y, false, true)
	play(120)
	if G.room.theme.get("id", "") != "brazil":
		fail("the Haggler caught the hero and he is in %s, not Brazil" % G.room.theme.get("id", "the floor"))
		return
	play(120)
	var s := Combat.spawn_enemy("scrounger", p.x, p.y, false, true)
	_cull(s)   # alone with the hero (Brazil's waves are bigger now)
	p.gold = 50
	p.invuln = 0.0
	p.dodge_t = 0.0
	G.god = false
	play(1, func(_i): _stick(s))
	G.god = true
	if p.gold >= 50:
		fail("a scrounger's touch did not rob the hero")
	# The raider (his ask, 6 Oct): a human robber who takes twice what a scrounger does.
	G.enemies.erase(s)
	play(90)   # the last hit's grace time runs out
	var rd := Combat.spawn_enemy("raider", p.x, p.y, false, true)
	_cull(rd)   # alone with the hero: no one else's touch first
	p.gold = 50
	p.invuln = 0.0
	p.dodge_t = 0.0
	G.god = false
	play(1, func(_i): _stick(rd))
	G.god = true
	if p.gold != 50 - 2 * (3 + G.floor_index):
		fail("a raider's touch took %d gold, not %d" % [50 - p.gold, 2 * (3 + G.floor_index)])
	G.enemies.erase(rd)
	G.enemies.append(s)
	Gear.equip_gear(p, Gear.by_id("hagglerhat"))
	p.gold = 50
	p.invuln = 0.0
	p.dodge_t = 0.0
	G.god = false
	play(1, func(_i): _stick(s))
	G.god = true
	if p.gold < 50:
		fail("the Haggler's hat did not keep the scrounger out of the pockets")
	if not _clear_and_leave() or G.room.rift_step != 1:
		fail("Brazil: no way from the first fight to the second")
		return
	if not _clear_and_leave() or G.room.rift_step != 3:
		fail("Brazil: the second fight does not lead to the Holy Cow")
		return
	play(240)
	if G.boss == null or G.boss.boss != "holycow":
		fail("Brazil: the Holy Cow is not there")
		return
	var cow: Enemy = G.boss
	_fell(cow)
	if cow.hp <= 0 or cow.phase != 3:
		fail("the Holy Cow did not rise again (hp %.0f, phase %d)" % [cow.hp, cow.phase])
	play(30)
	_fell(cow)
	play(30)
	if cow.hp > 0:
		fail("the Holy Cow rose a second time")
	if not G.room.objects.any(func(o): return o["kind"] == "item" and o["item"]["id"] == "cowmilker"):
		fail("the Holy Cow left no COW MILKER")
	# The Haggler killed: his hoard, gun and hat.
	p = _run()
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	h = Combat.spawn_enemy("haggler", p.x + 100.0, p.y, false, true)
	_fell(h)
	var got := G.room.objects.map(func(o): return o["item"]["id"] if o["kind"] == "item" else "")
	if not "hagglerbargain" in got or not "hagglerhat" in got or G.pickups.size() < 20:
		fail("the Haggler left %s and %d pickups" % [got, G.pickups.size()])
	for i in 300:
		if Weapons.random_weapon("legend")["id"] in Weapons.UNIQUE or Gear.random_gear("legend")["id"] == "hagglerhat":
			fail("a Brazil prize turned up in a random drop")
			break

## 5. Souls-like stages (expanded game): breaks at two thirds and one third, no damage during a
## break, every attack of each stage used, stage 3's desperation pulse.
func _stages(key: String) -> void:
	seed(key.hash())
	var p := _run()
	G.floor_index = 4
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.locked = true
	var b := Combat.spawn_boss(key)
	b.max_hp = 1e7
	b.hp = 1e7
	b.t = 0.3
	play(120)
	for st in [2, 3]:
		b.hp = b.max_hp * (0.6 if st == 2 else 0.3)
		play(2)
		if b.state != &"stagebreak":
			fail("%s did not break into stage %d (state %s)" % [key, st, b.state])
			return
		var hp0 := b.hp
		Combat.damage_enemy(b, 1000.0, { "no_crit": true })
		if b.hp != hp0:
			fail("%s was hurt during its stage break" % key)
		play(120)
		if b.stage != st:
			fail("%s is in stage %d, not %d" % [key, b.stage, st])
			return
		var seen := {}
		for i in 50 * 60:
			play(1)
			seen[String(b.state)] = true
			if i % 300 == 0:
				_cull(b)
			if b.hp < b.max_hp * 0.1:
				b.hp = b.max_hp * (0.6 if st == 2 else 0.3)
		for a in BossAI.STAGE_PLANS[key][st - 2]:
			if a != "curtain" and not seen.has(a):
				fail("%s never used %s in stage %d (seen %s)" % [key, a, st, seen.keys()])

## 6. The reward: a guardian felled without a hit pays a second chest, heals, and is counted.
func _reward() -> void:
	var p := _run()
	G.floor_index = 2
	G.start_floor()
	G.enter_room(World.make_room(G.floor_d, "boss", "", "s"))
	play(240)
	if G.boss == null:
		fail("no guardian to fell")
		return
	p.hp = 2
	G.room.hits = 0
	var chests := G.room.objects.filter(func(o): return o["kind"] == "chest").size()
	_fell(G.boss)
	var now := G.room.objects.filter(func(o): return o["kind"] == "chest").size()
	if now - chests != 2 or G.run_stats.get("flawless", 0) != 1:
		fail("a flawless guardian left %d chests (want 2), flawless %d" % [now - chests, G.run_stats.get("flawless", 0)])
	if p.hp <= 2:
		fail("felling a guardian did not heal")

## OPTIONS > MEET THE HAGGLER: he is in the first fight of the run, every time.
func _meet_haggler() -> void:
	_run()
	G.floor_index = 1
	G.start_floor()
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	Meta.opts["haggler"] = true
	G.run_stats.erase("haggler")
	Brazil.maybe_spawn(G.room, G.floor_index)
	Meta.opts["haggler"] = false
	if not G.enemies.any(func(e): return e.type == "haggler"):
		fail("MEET THE HAGGLER is on and he did not come to the first fight")


## A boss is felled the way a player fells it: down through every stage (Stages.gate), then the
## last blow. Other foes: the one blow.
func _break_down(e: Enemy) -> bool:
	var staged := false
	for k in 8:
		if e.hp <= 0 or Stages.gate(e) <= 0:
			return staged
		Combat.damage_enemy(e, (e.hp + Armor.shown(e)) * 2.0 + 10.0, { "no_crit": true, "no_mult": true })   # through the plate too
		play(150)
		staged = true
	return staged

func _fell(e: Enemy) -> void:
	if _break_down(e):
		play(120)   # the last stage's break and a rift foe's grace between phases run out
	Combat.damage_enemy(e, (e.hp + Armor.shown(e)) * 2.0 + 10.0, { "no_crit": true, "no_mult": true })

func _cull(b: Enemy) -> void:
	for e in G.enemies.duplicate():
		if e != b:
			G.enemies.erase(e)

func _stick(s: Enemy) -> void:
	s.x = G.player.x
	s.y = G.player.y

## 12.3: three pages carried: the Author's fall cuts a door to THE REDACTOR; its fall wins the run.
func _redactor() -> void:
	var door = null
	for o in G.room.objects:
		if o["kind"] == "n_redactdoor":
			door = o
	if door == null:
		fail("chapter II: three pages, but no door to the Redactor")
		return
	var wins0: int = Meta.meta.get("redactor_wins", 0)
	G.interact(door)
	play(300)
	if G.boss == null or G.boss.boss != "redactor":
		fail("the Redactor is not there (%s)" % (G.boss.boss if G.boss != null else "nobody"))
		return
	_fell(G.boss)
	play(30)
	if not G.run_stats.get("redactor", false) or Meta.meta.get("redactor_wins", 0) != wins0 + 1:
		fail("the Redactor's fall was not counted")
	# 14.4: close the book, or read on into CHAPTER III.
	var readon = null
	for o in G.room.objects:
		if o["kind"] == "n_readon":
			readon = o
	if readon == null:
		fail("no way to read on after the Redactor")
		return
	G.interact(readon)
	play(90)
	var base := GameData.FLOORS.size() + GameData.NEW_FLOORS.size() + GameData.CHAPTER2.size()
	if G.run_stats.get("chapter", 1) != 3 or GameData.floors().size() != base + 3:
		fail("chapter III: not begun (chapter %s, %d floors)" % [G.run_stats.get("chapter", 1), GameData.floors().size()])
		return
	for k in 3:
		if G.floor_index != base + k or GameData.floors()[base + k]["name"] != GameData.CHAPTER3[k]["name"]:
			fail("chapter III: on floor %d, want %s" % [G.floor_index, GameData.CHAPTER3[k]["name"]])
			return
		G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
		play(200)
		var ok3: Array = GameData.CHAPTER3[k]["pool"] + (GameData.floors()[mini(G.floor_index + 1, GameData.floors().size() - 1)]["pool"] if G.room.twist == "strangers" else [])   # STRANGERS: half from the next floor
		for e in G.enemies:
			if not e.type in ok3 and e.type != "dummy":
				fail("chapter III floor %d: a foreign foe %s" % [k + 1, e.type])
				break
		G.enemies.clear()
		G.locked = false
		G.enter_room(World.make_room(G.floor_d, "boss", "", "s", { "no_secret": true }))
		play(240)
		if G.boss == null or G.boss.boss != GameData.CHAPTER3[k]["boss"]:
			fail("chapter III floor %d: the guardian is %s" % [k + 1, G.boss.boss if G.boss != null else "nobody"])
			return
		_fell(G.boss)
		play(60)
		if k < 2:
			G.floor_index += 1
			G.start_floor()
	# 20.3: the Reader's fall: close the book, or step out onto the shelf: CHAPTER IV.
	if not G.run_stats.get("reader", false):
		fail("the Reader's fall was not counted")
	var shelf = null
	var book = null
	for o in G.room.objects:
		if o["kind"] == "n_shelf":
			shelf = o
		if o["kind"] == "n_endbook":
			book = o
	if shelf == null or book == null:
		fail("after the Reader: no book to close or shelf to step onto")
		return
	G.interact(shelf)
	play(90)
	var base4 := base + GameData.CHAPTER3.size()
	var cw0: int = Meta.meta.get("critic_wins", 0)
	if G.run_stats.get("chapter", 1) != 4 or GameData.floors().size() != base4 + 3 or not book.get("used", false):
		fail("chapter IV: not begun (chapter %s, %d floors)" % [G.run_stats.get("chapter", 1), GameData.floors().size()])
		return
	for k in 3:
		if G.floor_index != base4 + k or GameData.floors()[base4 + k]["name"] != GameData.CHAPTER4[k]["name"]:
			fail("chapter IV: on floor %d, want %s" % [G.floor_index, GameData.CHAPTER4[k]["name"]])
			return
		G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
		play(200)
		var ok4: Array = GameData.CHAPTER4[k]["pool"] + (GameData.floors()[mini(G.floor_index + 1, GameData.floors().size() - 1)]["pool"] if G.room.twist == "strangers" else [])
		for e in G.enemies:
			if not e.type in ok4 and e.type != "dummy":
				fail("chapter IV floor %d: a foreign foe %s" % [k + 1, e.type])
				break
		if G.room.strike == "" and RoomDress.library() != k:
			fail("chapter IV floor %d: no hazard (%s) or not the library (%d)" % [k + 1, G.room.strike, RoomDress.library()])
		G.enemies.clear()
		G.locked = false
		G.enter_room(World.make_room(G.floor_d, "boss", "", "s", { "no_secret": true }))
		play(240)
		if G.boss == null or G.boss.boss != GameData.CHAPTER4[k]["boss"]:
			fail("chapter IV floor %d: the guardian is %s" % [k + 1, G.boss.boss if G.boss != null else "nobody"])
			return
		_fell(G.boss)
		play(60)
		if k < 2:
			G.floor_index += 1
			G.start_floor()
	for o in G.room.objects:
		if o["kind"] == "chest":
			o["opened"] = true
	for i in 800:
		play(1)
		if G.state == &"win":
			break
	if G.state != &"win" or not G.run_stats.get("critic", false) or Meta.meta.get("critic_wins", 0) != cw0 + 1:
		fail("the Critic's fall did not win the run (state %s)" % G.state)
	else:
		for part in ["CHAPTER IV", "CHAPTER III", "THE REDACTOR"]:
			if not G.award.get("parts", []).any(func(x): return x[0] == part):
				fail("no embers for " + part)
