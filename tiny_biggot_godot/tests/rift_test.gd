extends Node
## Rift worlds and event rooms. Run: godot --headless --path . res://tests/rift_test.tscn -- --no-save
##   1. Lint: every world's tiles, foes (and elite sprites), champion moves, hazard and text.
##   2. Every world: its three rooms are fought, the champion appears and uses every move,
##      the way on is offered, and the champion's hoard appears.
##   3. A rift walked door to door: the floor advances by one room, and the doors lead back.
##   4. Every floor offers a rift door.
##   5. Every event room: each object is used, event fights are won, the room opens again.
##   6. Hidden doors: a flawless fight and a loose brick both open one.
## Prints "rift test: PASSED" or a FAIL line per problem.

var fails := 0
const MOVES := ["charge", "ring", "fan", "spiral", "burst", "duel", "lob", "rain", "summon", "blink"]

func fail(msg: String) -> void:
	fails += 1
	print("FAIL rift: ", msg)

func _tick(n: int) -> void:
	var p: Player = G.player
	for i in n:
		p.hp = p.max_hp
		p.invuln = 1.0
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

func _kill_all() -> void:
	for e in G.enemies.duplicate():
		if e.hp > 0 and e.spawn_t <= 0:
			Combat.damage_enemy(e, e.hp * 2.0 + 1.0, { "no_crit": true, "no_mult": true, "silent": true })

func _clear_room(max_ticks: int = 1500) -> bool:
	for i in max_ticks / 10:
		_tick(10)
		_kill_all()
		if not G.locked:
			return true
	return false

func _start(floor_i: int) -> void:
	G.hero_index = 1
	G.new_run()
	G.floor_index = floor_i
	if floor_i > 0:
		G.start_floor()
	_tick(30)

func _ready() -> void:
	await get_tree().process_frame
	seed(4242)
	lint()
	worlds()
	walk()
	doors()
	events()
	hidden()
	print("rift test: PASSED" if fails == 0 else "rift test: %d FAILED" % fails)
	get_tree().quit()

func _font(where: String, texts: Array) -> void:
	for t in texts:
		for ch in String(t).to_upper():
			if not ch in Gfx.FONT_CHARS:
				fail("%s: character '%s' is not in the game font" % [where, ch])

func lint() -> void:
	for th in Themes.LIST:
		var id: String = th["id"]
		_font("world " + id, [th["name"], th["sub"]])
		if not Img.has(th["kit"]):
			fail("world %s: missing tiles %s" % [id, th["kit"]])
		if th.get("hazard", "") != "" and th["hazard"] != "traffic" and not Hazards.STATIC.has(th["hazard"]) \
				and not Hazards.STRIKES.has(th["hazard"]):
			fail("world %s: unknown hazard %s" % [id, th["hazard"]])
		for t in th["pool"] + [th["champion"]]:
			if not GameData.ENEMIES.has(t):
				fail("world %s: unknown foe %s" % [id, t])
				continue
			var d: Dictionary = GameData.ENEMIES[t]
			for spr in [d["sprite"], d["sprite"] + "_elite"]:
				if not Img.has(spr):
					fail("foe %s: missing sprite %s" % [t, spr])
			if not GameData.ENEMY_XP.has(t) or not GameData.SPRITE_COLOR.has(d["sprite"]):
				fail("foe %s: no experience or colour entry" % t)
			if d.has("shot") and not d["shot"] in EBullets.SPRITES:
				fail("foe %s: unknown shot %s" % [t, d["shot"]])
			if d.has("summon") and not GameData.ENEMIES.has(d["summon"]):
				fail("foe %s: summons unknown %s" % [t, d["summon"]])
		var ch: Dictionary = GameData.ENEMIES[th["champion"]]
		_font("champion " + th["champion"], [ch["name"]])
		for m in ch["moves"]:
			if not m[0] in MOVES:
				fail("champion %s: unknown move %s" % [th["champion"], m[0]])
			if m[0] == "summon" and not GameData.ENEMIES.has(m[1]):
				fail("champion %s: summons unknown %s" % [th["champion"], m[1]])
	for ev in G.MYSTERY_EVENTS:
		if G.EVENT_TITLE.has(ev):
			_font("event " + ev, G.EVENT_TITLE[ev])
	for n in ["wheel", "well", "bloodstall", "brick", "car", "riftdoor", "tome", "bed", "jukebox", "goblin", "mimic", "shadow"]:
		if not Img.has(n):
			fail("missing sprite " + n)

func worlds() -> void:
	var worst := 0.0
	for th in Themes.LIST:
		for step in 3:
			_start(3)
			G.enter_room(World.make_room(G.floor_d, "combat" if step == 0 else "elite", "", "s", { "theme": th["id"], "step": step }))
			if G.room.theme.is_empty() or not G.locked:
				fail("world %s step %d: not a locked themed fight" % [th["id"], step])
			var t0 := Time.get_ticks_usec()
			_tick(240)
			worst = maxf(worst, (Time.get_ticks_usec() - t0) / 240000.0)
			for e in G.enemies:
				if e.type != th["champion"] and not e.type in th["pool"] and not _summoned(th, e.type):
					fail("world %s: foreign foe %s" % [th["id"], e.type])
			if step == 2:
				var ch: Enemy = G.champ
				if ch == null or ch.type != th["champion"]:
					fail("world %s: no champion" % th["id"])
					continue
				# Let the champion go through every move (others are cleared away so it has room).
				var moves: int = ch.d["moves"].size()
				for i in 400:
					_tick(10)
					for e in G.enemies.duplicate():
						if e != ch and e.hp > 0 and e.spawn_t <= 0:
							Combat.damage_enemy(e, e.hp * 2.0 + 1.0, { "no_crit": true, "no_mult": true, "silent": true })
					ch.hp = ch.max_hp * (0.4 if i > 200 else 1.0)   # the second half enraged
					if ch.cycle >= moves * 2:
						break
				if ch.cycle < moves:
					fail("champion %s: only %d of %d moves in 66 s" % [ch.type, ch.cycle, moves])
			if not _clear_room():
				fail("world %s step %d: the room never cleared" % [th["id"], step])
				continue
			var rifts := 0
			for d in G.room.exits:
				if G.room.exits[d]["type"] == "rift":
					rifts += 1
					if G.room.exits[d]["step"] != step + 1 or G.room.exits[d]["theme"] != th["id"]:
						fail("world %s step %d: wrong way on" % [th["id"], step])
			if step < 2 and (rifts != 1 or G.room.exits.size() != 1):
				fail("world %s step %d: %d rift doors of %d" % [th["id"], step, rifts, G.room.exits.size()])
			if step == 2:
				if rifts != 0 or G.room.exits.is_empty():
					fail("world %s: the champion's room does not lead back to the floor" % th["id"])
				if not G.room.objects.any(func(o): return o["kind"] == "chest" and o.get("boss", false)):
					fail("world %s: no champion's hoard" % th["id"])
	print("[rift] worlds: %d worlds x 3 rooms fought, every champion used every move; worst %.2f ms/tick" % [Themes.LIST.size(), worst])

func _summoned(th: Dictionary, type: String) -> bool:
	for t in th["pool"] + [th["champion"]]:
		var d: Dictionary = GameData.ENEMIES[t]
		if d.get("summon", "") == type:
			return true
		for m in d.get("moves", []):
			if m[0] == "summon" and m[1] == type:
				return true
	return false

func _go(dir: String) -> void:
	G.leave_room(dir)
	_tick(40)

func walk() -> void:
	_start(2)
	var depth0: int = G.floor_d["depth"]
	G.room.exits = { "n": { "type": "rift", "reward": "", "theme": "neon", "step": 0 } }
	_go("n")
	for step in 3:
		if G.room.theme.get("id", "") != "neon" or G.room.rift_step != step:
			fail("walk: room %d is not Neon Undercity step %d" % [step, step])
			return
		if not _clear_room():
			fail("walk: room %d never cleared" % step)
			return
		if step < 2:
			_go(G.room.exits.keys()[0])
	if G.floor_d["depth"] != depth0 + 1:
		fail("walk: the rift moved the floor on by %d rooms, not 1" % (G.floor_d["depth"] - depth0))
	if not "neon" in G.run_stats["rifts"] or not G.floor_d["rift_done"]:
		fail("walk: the rift was not recorded")
	var back := false
	for d in G.room.exits:
		if G.room.exits[d]["type"] != "rift":
			back = true
	if not back:
		fail("walk: no door back to the floor")
	_go(G.room.exits.keys()[0])
	if not G.room.theme.is_empty():
		fail("walk: still in the rift after leaving the champion's room")
	print("[rift] walk: a rift walked door to door; the floor advanced one room and the doors led back")

func doors() -> void:
	var seen := {}
	for f in GameData.floors().size():
		_start(f)
		var found := false
		for d in range(0, G.floor_d["total"]):
			G.floor_d["depth"] = d
			for c in World.gen_choices(G.floor_d, G.player):
				if c["type"] == "rift":
					found = true
					seen[c["theme"]] = true
					if d + 1 >= G.floor_d["total"] - 1:
						fail("floor %d: a rift door right before the guardian" % (f + 1))
		if not found:
			fail("floor %d: no rift door offered" % (f + 1))
	print("[rift] doors: every one of %d floors offers a rift door (%d worlds seen)" % [GameData.floors().size(), seen.size()])

func events() -> void:
	for ev in G.MYSTERY_EVENTS:
		_start(2)
		G.enter_room(World.make_room(G.floor_d, "mystery", "", "s", { "event": ev }))
		var p: Player = G.player
		p.gold = 5000
		p.max_hp = 20
		p.hp = 20
		if G.room.exits.is_empty():
			fail("event %s: no way out" % ev)
		if ev == "goblin":
			if not G.enemies.any(func(e): return e.type == "goblin"):
				fail("event goblin: no goblin")
			_tick(120)
			var n0: int = G.pickups.size()
			_kill_all()
			_tick(10)
			if G.pickups.size() <= n0:
				fail("event goblin: nothing dropped")
			continue
		if G.room.objects.is_empty():
			fail("event %s: empty room" % ev)
		var used := 0
		for round in 8:
			for o in G.room.objects.duplicate():
				if o.get("used", false) or o.get("opened", false) or o.get("gone", false):
					continue
				if G.locked:
					break
				G.interact(o)
				used += 1
				_tick(20)
			if G.room.event_fight:
				if not G.locked:
					fail("event %s: its fight did not lock the room" % ev)
				_tick(120)
				if not _clear_room() or G.room.event_fight:
					fail("event %s: its fight never ended" % ev)
				_tick(20)
		if used == 0:
			fail("event %s: nothing to use" % ev)
		if G.locked:
			fail("event %s: the room stayed locked" % ev)
		if ev == "armory":
			var left := 0
			for o in G.room.objects:
				if o["kind"] == "item" and o.has("group") and not o.get("gone", false):
					left += 1
			if left != 0:
				fail("event armory: %d weapons still on show after taking one" % left)
	# A hidden room may hold an event too.
	var with_event := 0
	for i in 40:
		_start(1)
		G.enter_room(World.make_room(G.floor_d, "secret", "", "e"))
		if G.room.event != "":
			with_event += 1
			if not G.room.event in G.SECRET_EVENTS:
				fail("hidden room: event %s is not allowed there" % G.room.event)
	if with_event == 0 or with_event == 40:
		fail("hidden rooms: %d of 40 held an event" % with_event)
	print("[rift] events: %d event rooms used up, fights won, rooms reopened; %d of 40 hidden rooms held an event" % [
		G.MYSTERY_EVENTS.size(), with_event])

func hidden() -> void:
	var flawless := 0
	for i in 40:
		_start(1)
		var r := World.make_room(G.floor_d, "combat", "gold", "s")
		G.enter_room(r)
		if not _clear_room():
			fail("hidden: a plain fight never cleared")
			return
		for d in G.room.exits:
			if G.room.exits[d]["type"] == "secret" and r.hits == 0:
				flawless += 1
	if flawless == 0:
		fail("hidden: 40 flawless fights opened no hidden door")
	_start(1)
	G.enter_room(World.make_room(G.floor_d, "treasure", "", "s"))
	G.room.objects.append({ "kind": "brick", "x": 2.0 * TB.TS, "y": 5.0 * TB.TS })
	G.interact(G.room.objects[G.room.objects.size() - 1])
	var opened := false
	for d in G.room.exits:
		if G.room.exits[d]["type"] == "secret":
			opened = true
	if not opened and G.pickups.is_empty():
		fail("hidden: the loose brick did nothing")
	print("[rift] hidden doors: %d of 40 flawless fights opened one; the loose brick works" % flawless)
