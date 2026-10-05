extends Node
## The rift bosses (scripts/entities/rift_bosses.gd, ROADMAP 4.5).
## Run: godot --headless --path . res://tests/bosses_test.tscn -- --no-save
##   1. Data: each new world names a mini-boss and a guardian; both have plans for two phases,
##      sprites, a line for their second phase, and text the font can draw.
##   2. Each of the six, fought in its own world with a hero who stands still: every attack of
##      both phases starts and ends (none runs past 14 s), some of them hit the hero, the second
##      phase starts below half health with the shots on screen gone and no damage taken while it
##      starts, and the fight's things are gone when it falls.
##   3. A guardian's fall: its hoard (a chest, no portal), the way back, the floor unchanged, one
##      more guardian beaten for the constellation. A mini-boss's fall: its little hoard.
##   4. The rift: a new world's second room ends with its mini-boss; its champion's room has a door
##      to the guardian (named on the door); an old world's champion room has no such door.
##   5. Logic time per tick in each fight (desktop; printed).
##   6. REX (rex.gd): asleep in his barn until you come close (blows on a sleeping dog count
##      double); his bowl wakes him full and slow; every move of both phases; beaten, his hoard
##      and his offer to come along; the title's secret puts a door to his barn in the next run's
##      first room; a hidden room on the second floor or later is his barn about 12% of the time.
## Prints "bosses test: PASSED" or a FAIL line per problem.

const NEW_WORLDS := ["skyreach", "bastion", "cathedral"]

var fails := 0
var notes := []

func fail(msg: String) -> void:
	fails += 1
	print("FAIL bosses: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(7)
	_data()
	for w in NEW_WORLDS:
		var th := Themes.by_id(w)
		_fight(w, th["guardian"], true)
		_fight(w, th["mini"], false)
	_rift_flow()
	_rex()
	_rex_doors()
	for n in notes:
		print("[bosses] ", n)
	print("bosses test: PASSED" if fails == 0 else "bosses test: %d FAILED" % fails)
	get_tree().quit()

func _font(where: String, s: String) -> void:
	for ch in s:
		if not ch in Gfx.FONT_CHARS:
			fail("%s: '%s' is not in the font" % [where, ch])
			return

func _data() -> void:
	for w in NEW_WORLDS:
		var th := Themes.by_id(w)
		for k in ["mini", "guardian"]:
			if not th.has(k):
				fail("world %s has no %s" % [w, k])
				return
		var mini: String = th["mini"]
		var gd: String = th["guardian"]
		if not GameData.ENEMIES.has(mini) or GameData.ENEMIES[mini].get("ai", "") != "riftboss":
			fail("mini-boss %s is not a rift boss" % mini)
		if not GameData.BOSSES.has(gd) or not GameData.BOSSES[gd].get("rift", false):
			fail("guardian %s is not a rift guardian" % gd)
		for k in [mini, gd]:
			if not RiftBosses.PLANS.has(k) or RiftBosses.PLANS[k].size() != 2:
				fail("%s has no plan for two phases" % k)
			if not RiftBosses.PHASE_LINE.has(k):
				fail("%s has no second-phase line" % k)
			else:
				_font(k + " phase line", RiftBosses.PHASE_LINE[k])
		var md: Dictionary = GameData.ENEMIES[mini]
		_font(mini, md["name"])
		_font(gd, GameData.BOSSES[gd]["name"])
		for spr in [md["sprite"], md["sprite"] + "_elite", GameData.BOSSES[gd]["sprite"]]:
			if not Img.has(spr):
				fail("missing sprite " + spr)
		var door := GameData.door_kind({ "type": "rift", "theme": w, "step": 3 })
		if door["name"] != GameData.BOSSES[gd]["name"]:
			fail("the door to %s reads %s" % [gd, door["name"]])
	for spr in ["hydrahead", "hydraneck", "rb_bell", "rb_anchor"]:
		if not Img.has(spr):
			fail("missing sprite " + spr)

# ---------- One fight ----------
func _start() -> void:
	G.hero_index = 1
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = false

func _tick(n: int, hold := Vector2(-1, -1)) -> void:
	for i in n:
		var p := G.player
		p.hp = p.max_hp
		p.armor = 0
		if hold.x >= 0:
			p.x = hold.x
			p.y = hold.y
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

func _foe(type: String) -> Enemy:
	for e in G.enemies:
		if (e.type == type or e.boss == type) and e.hp > 0:
			return e
	return null

func _fight(world: String, key: String, guardian: bool) -> void:
	_start()
	var th := Themes.by_id(world)
	var e: Enemy
	if guardian:
		G.enter_room(World.make_room(G.floor_d, "boss", "", "s", { "theme": world, "step": 3 }))
		_tick(90)
		e = _foe(key)
		if e == null or G.boss != e:
			fail("%s did not come to its arena" % key)
			return
	else:
		G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "theme": world, "step": 0 }))
		G.room.waves_left = 0
		e = Combat.spawn_enemy(key, 14.0 * TB.TS, 7.0 * TB.TS, false, true)
		if G.champ != e:
			fail("%s does not show the boss bar" % key)
	var hold := Vector2(14.0 * TB.TS, 13.0 * TB.TS)
	# Phase one: very sturdy, so the hero's shots do not end it early.
	e.max_hp = 1e9
	e.hp = 1e9
	var hits0: int = G.room.hits
	var seen := _watch(e, 60.0, hold, key, 1)
	for a in RiftBosses.PLANS[key][0]:
		if not seen.has(a):
			fail("%s never used %s in its first phase" % [key, a])
	var hits1: int = G.room.hits - hits0
	if hits1 == 0:
		fail("%s never hit a hero standing still in 60 s" % key)
	# The second phase.
	e.hp = e.max_hp * 0.45
	_tick(1, hold)
	if e.state != &"phase":
		fail("%s did not start its second phase below half health (state %s)" % [key, e.state])
	var live := 0
	for i in EBullets.n:
		if EBullets.alive(i):
			live += 1
	if live > 0:
		fail("%s: %d shots left when its second phase began" % [key, live])
	var hp := e.hp
	Combat.damage_enemy(e, 5000.0, { "no_crit": true, "no_mult": true, "silent": true })
	if e.hp != hp:
		fail("%s took damage while its second phase began" % key)
	_tick(int(RiftBosses.PHASE_T * 60) + 5, hold)
	if e.phase != 2:
		fail("%s is not in its second phase after the grace" % key)
	var hits2: int = G.room.hits
	seen = _watch(e, 70.0, hold, key, 2)
	for a in RiftBosses.PLANS[key][1]:
		if not seen.has(a):
			fail("%s never used %s in its second phase" % [key, a])
	if G.room.hits == hits2:
		fail("%s never hit the hero in its second phase" % key)
	notes.append("%s: hit a hero standing still %d times in 60 s (first phase), %d in 70 s (second); logic %.2f ms a tick at worst %.2f" %
		[key, hits1, G.room.hits - hits2, _ms_avg, _ms_max])
	# The fall.
	var bosses0: int = Meta.meta["bosses"]
	var floor0 := G.floor_index
	var pick0 := G.pickups.size()
	# (A choir's deacon may be shielding it: half damage. Strike until it falls.)
	for k in 6:
		if e.hp > 0:
			Combat.damage_enemy(e, e.hp * 2.0 + 10.0, { "no_crit": true, "no_mult": true, "silent": true })
	_tick(2)
	if not RiftBosses._quiet():
		fail("%s: its things are still about after it fell" % key)
	if guardian:
		var chest := false
		for o in G.room.objects:
			if o["kind"] == "chest" and o.get("boss", false):
				chest = true
			if o["kind"] in ["portal", "loopportal", "exitportal"]:
				fail("%s left a portal" % key)
		if not chest:
			fail("%s left no hoard" % key)
		if G.room.exits.is_empty() or not G.room.cleared or G.locked:
			fail("%s: no way out after it fell" % key)
		if G.floor_index != floor0:
			fail("%s moved the floor on" % key)
		if Meta.meta["bosses"] != bosses0 + 1:
			fail("%s did not count as a guardian beaten" % key)
	elif G.pickups.size() < pick0 + 5:
		fail("%s left no hoard (%d pickups)" % [key, G.pickups.size() - pick0])

var _ms_avg := 0.0
var _ms_max := 0.0

## Runs the fight for `secs`, keeping the hero where he is; returns the attacks seen. An attack
## that runs past 14 s fails.
func _watch(e: Enemy, secs: float, hold: Vector2, key: String, phase: int) -> Dictionary:
	var seen := {}
	var since := 0.0
	var last := e.state
	var total := 0.0
	_ms_max = 0.0
	var n := int(secs * 60)
	for i in n:
		var t0 := Time.get_ticks_usec()
		_tick(1, hold)
		var us := float(Time.get_ticks_usec() - t0) / 1000.0
		total += us
		_ms_max = maxf(_ms_max, us)
		if e.hp <= 0:
			fail("%s fell while being watched" % key)
			break
		if e.state != last:
			last = e.state
			since = 0.0
			seen[String(e.state)] = true
		since += TB.DT
		if not e.state in [&"rest", &"idle", &"intro", &"phase"] and since > 14.0:
			fail("%s stuck in %s (phase %d)" % [key, e.state, phase])
			break
	_ms_avg = total / maxf(1.0, n)
	return seen

# ---------- The rift ----------
func _rift_flow() -> void:
	for w in NEW_WORLDS + ["gaol"]:
		_start()
		var th := Themes.by_id(w)
		# The second room: its waves, the last of them the mini-boss.
		G.enter_room(World.make_room(G.floor_d, "elite", "", "s", { "theme": w, "step": 1 }))
		var met := false
		for k in 120:
			_tick(30)
			for e in G.enemies.duplicate():
				if e.type == th.get("mini", "?"):
					met = true
				if e.hp > 0 and e.spawn_t <= 0:
					Combat.damage_enemy(e, e.hp * 2.0 + 1.0, { "no_crit": true, "no_mult": true, "silent": true })
			if G.room.cleared:
				break
		if not G.room.cleared:
			fail("%s: the second room never cleared" % w)
		if th.has("mini") != met:
			fail("%s: mini-boss met %s" % [w, met])
		# The champion's room: a door deeper for the new worlds.
		G.enter_room(World.make_room(G.floor_d, "elite", "", "s", { "theme": w, "step": 2 }))
		for k in 120:
			_tick(30)
			for e in G.enemies.duplicate():
				if e.hp > 0 and e.spawn_t <= 0:
					Combat.damage_enemy(e, e.hp * 2.0 + 1.0, { "no_crit": true, "no_mult": true, "silent": true })
			if G.room.cleared:
				break
		var deeper := ""
		for d in G.room.exits:
			if G.room.exits[d]["type"] == "rift" and G.room.exits[d].get("step", 0) == 3:
				deeper = d
		if th.has("guardian") != (deeper != ""):
			fail("%s: a door to a guardian: %s" % [w, deeper != ""])
		if deeper == "":
			continue
		if G.room.exits.size() < 2:
			fail("%s: the champion's room lost its way back" % w)
		G.leave_room(deeper)
		_tick(30)
		if G.room.type != "boss" or G.room.rift_step != 3:
			fail("%s: the deeper door led to %s" % [w, G.room.type])
		_tick(80)
		if G.boss == null or G.boss.boss != th["guardian"]:
			fail("%s: its guardian did not come" % w)

# ---------- Rex ----------
func _barn() -> Enemy:
	_start()
	G.floor_index = 0
	G.enter_room(World.make_room(G.floor_d, "barn", "", "s"))
	for e in G.enemies:
		if e.boss == "rex":
			return e
	return null

func _rex() -> void:
	for s in ["REX'S BARN", "SOMETHING BIG IS SNORING", "GOOD BOY, REX!", "HE ROLLS OVER FOR A BELLY RUB", "HE WANTS TO PLAY",
			"YOU WOKE HIM UP", "HE WAKES UP FOR DINNER. FULL AND SLOW", GameData.BOSSES["rex"]["name"], RiftBosses.PHASE_LINE["rex"],
			"WOOF! REX WANTS TO PLAY. HIS BARN IS BY YOUR FIRST ROOM", "EMPTY. FILL IT AND HE WAKES UP FULL AND SLOW"]:
		_font("rex", s)
	for spr in ["rex", "rex_lie", "rex_shades", "rex_sword", "pet_rex", "kit_barn", "rex_hay", "rex_mat", "rex_bowl", "rex_potatoes",
			"rex_potato", "icon_barn"]:
		if not Img.has(spr):
			fail("missing sprite " + spr)
	# Asleep until you come close.
	var e := _barn()
	if e == null or e.state != &"sleep":
		fail("rex is not asleep in his barn")
		return
	var p := G.player
	var fire0: bool = Meta.opts["autofire"]
	Meta.opts["autofire"] = false   # (a hero firing by himself would wake him)
	_tick(180, Vector2(3.0 * TB.TS, 15.0 * TB.TS))
	Meta.opts["autofire"] = fire0
	if e.state != &"sleep" or G.locked:
		fail("rex woke up with no one near (state %s)" % e.state)
	if RiftBosses.adjust_damage(e, 10.0) != 20.0:
		fail("a blow on sleeping rex counts %.1f, not double" % RiftBosses.adjust_damage(e, 10.0))
	Combat.damage_enemy(e, 10.0, { "no_crit": true, "no_mult": true, "silent": true })
	_tick(2)
	if e.state != &"nap" and RiftBosses.adjust_damage(e, 10.0) != 10.0:
		fail("a blow on awake rex counts %.1f" % RiftBosses.adjust_damage(e, 10.0))
	if e.state == &"sleep" or not G.locked:
		fail("rex slept through a blow, or the barn did not lock")
	# His bowl: he wakes up for dinner, full and slow.
	e = _barn()
	var bowl: Dictionary = {}
	for o in G.room.objects:
		if o["kind"] == "x_bowl":
			bowl = o
	if bowl.is_empty():
		fail("no bowl in the barn")
	else:
		var max0 := e.max_hp
		p = G.player
		p.gold = Rex.BOWL_PRICE
		G.interact(bowl)
		if p.gold != 0 or absf(e.max_hp - max0 * 0.85) > 0.01 or e.state == &"sleep":
			fail("the bowl: gold %d, health %.0f of %.0f, state %s" % [p.gold, e.max_hp, max0, e.state])
	# The fight, as for the other bosses.
	e = _barn()
	var hold := Vector2(14.0 * TB.TS, 6.0 * TB.TS)
	_tick(30, hold)
	e.max_hp = 1e9
	e.hp = 1e9
	var hits0: int = G.room.hits
	var seen := _watch(e, 70.0, hold, "rex", 1)
	for a in RiftBosses.PLANS["rex"][0]:
		if not seen.has(a):
			fail("rex never did %s in his first phase" % a)
	if G.room.hits == hits0:
		fail("rex never hit a hero standing still")
	e.hp = e.max_hp * 0.45
	_tick(1, hold)
	if e.state != &"phase":
		fail("rex did not start his second phase (state %s)" % e.state)
	_tick(int(RiftBosses.PHASE_T * 60) + 5, hold)
	if e.phase != 2:
		fail("rex has no second phase")
	seen = _watch(e, 80.0, hold, "rex", 2)
	for a in RiftBosses.PLANS["rex"][1]:
		if not seen.has(a):
			fail("rex never did %s in his second phase" % a)
	notes.append("rex: logic %.2f ms a tick on average, %.2f at worst" % [_ms_avg, _ms_max])
	var bosses0: int = Meta.meta["bosses"]
	var rex0: int = Meta.meta.get("rex", 0)
	for k in 6:
		if e.hp > 0:
			Combat.damage_enemy(e, e.hp * 2.0 + 10.0, { "no_crit": true, "no_mult": true, "silent": true })
	_tick(2)
	var offer: Dictionary = {}
	var chest := false
	for o in G.room.objects:
		if o["kind"] == "pet_cage" and o.get("nocage", false):
			offer = o
		if o["kind"] == "chest" and o.get("boss", false):
			chest = true
	if not chest or offer.is_empty() or offer["pet"] != "rex":
		fail("beaten rex left no hoard or no offer (chest %s)" % chest)
	if G.locked or Meta.meta["bosses"] != bosses0 + 1 or Meta.meta.get("rex", 0) != rex0 + 1:
		fail("after rex: locked %s, guardians %d, rex %d" % [G.locked, Meta.meta["bosses"] - bosses0, Meta.meta.get("rex", 0) - rex0])
	if not offer.is_empty():
		G.interact(offer)
		if G.player.pet != "rex":
			fail("rex did not come along")

func _rex_doors() -> void:
	# The title's secret: three pokes, and the next run's first room has a door to his barn.
	Rex.pokes = 0
	G.rex_call = false
	for i in 3:
		Rex.poke()
	if not G.rex_call:
		fail("three pokes did not wake the title's rex")
	G.hero_index = 1
	G.new_run()   # the first room of the first floor
	var door := ""
	for d in G.room.exits:
		if G.room.exits[d]["type"] == "barn":
			door = d
	if door == "" or G.rex_call:
		fail("no door to the barn in the first room (call %s)" % G.rex_call)
	else:
		var depth: int = G.floor_d["depth"]
		G.leave_room(door)
		_tick(30)
		if G.room.type != "barn" or G.floor_d["depth"] != depth:
			fail("the barn door led to %s (depth %d to %d)" % [G.room.type, depth, G.floor_d["depth"]])
	# Natural barns: hidden rooms from the second floor on, about one floor in eight.
	var barns := 0
	var floors := 0
	var first := 0
	for i in 400:
		G.run_stats["rex"] = false
		G.floor_index = 0 if i % 4 == 0 else 1 + i % 6
		var fd := World.new_floor(G.floor_index)
		FloorMap.generate(fd, G.player)
		for c in fd["map"]["cells"]:
			if fd["map"]["cells"][c]["type"] == "barn":
				if G.floor_index == 0:
					first += 1
				else:
					barns += 1
		if G.floor_index > 0:
			floors += 1
	notes.append("rex's barn on %d of %d floors past the first" % [barns, floors])
	if first > 0:
		fail("a barn on the first floor")
	if barns < floors * 0.05 or barns > floors * 0.22:
		fail("barns on %d of %d floors (want about 12%%)" % [barns, floors])
	G.run_stats["rex"] = false
