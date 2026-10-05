extends Node
## Rift worlds and event rooms. Run: godot --headless --path . res://tests/rift_test.tscn -- --no-save
##   1. Lint: every world's tiles, foes (and elite sprites), champion moves, hazard and text.
##   2. Every world: its three rooms are fought, the champion appears and uses every move,
##      the way on is offered, and the champion's hoard appears.
##   3. A rift walked door to door: the floor advances by one room, and the doors lead back.
##   4. Every floor offers a rift door.
##   5. Every event room: each object is used, event fights are won, the room opens again.
##   6. Hidden doors: a flawless fight and a loose brick both open one.
##   7. Skyreach Isles: every island layout leaves all floor reachable from every door; open sky
##      stops the hero and walkers but not flyers or shots; a gust shoves the hero along its band;
##      a hero left on open sky steps back onto an island.
##   8. The saloon: every object can be reached past the furniture; drinks cost gold and give their
##      boost and their catch; the fifth chat earns a free round; each bounty is paid when done, shows
##      on the HUD while on, and runs out on a new floor; the piano, poster and drunk pay out; all
##      its text fits the font.
##   9. The other event rooms, special rooms and wanderers, each played to its payout: the pit's
##      bet and waves, a chop-shop mod (and the weapon list left untouched), a fortune card, the
##      courier's parcel (delivered, too slow, lost on the stairs), the gallery's score and prizes,
##      the beacon held, the vault's plates (wrong and right), a cursed weapon, the drunk and the
##      lost merchant placed clear of the doors; all their text fits the font.
##  10. The Drowned Bastion and the Caliber Cathedral: every layout leaves all floor reachable; a
##      flipped table stops shots and walkers and leaves no one stuck; levers, the skull, the fisher,
##      the saint and the rat each pay out (the rat pays back double); the tide hurts foes and the
##      hero; the turrets aim, then fire.
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
	isles()
	saloon()
	event_rooms()
	worlds2()
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
		if th.get("hazard", "") != "" and not th["hazard"] in ["traffic", "gusts", "tide", "turrets"] and not Hazards.STATIC.has(th["hazard"]) \
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
				# The new worlds' champion rooms also have a door deeper, to their guardian (ROADMAP 4.5).
				if rifts != (1 if th.has("guardian") else 0) or G.room.exits.size() <= rifts:
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
		if G.locked and ev == "pit":
			_fight_through(6000)   # the pit's bet: its waves must be fought
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

func isles() -> void:
	_start(0)
	var seen := {}
	for sd in 400:
		var room := World.make_room(G.floor_d, "combat", "", "s", { "theme": "skyreach", "step": 0 })
		room.seed_value = sd * 7919 + 1
		room.doors = { "n": true, "w": true, "e": true, "s": true }
		World.build_room(room)
		if room.layout < 101 or room.layout > 104:
			fail("isles: a Skyreach fight room has layout %d" % room.layout)
			continue
		if seen.has(room.layout):
			continue
		seen[room.layout] = true
		# Flood the floor from the south door; every floor tile must be reached.
		var start := Vector2i(13, 16)
		var reach := { start: true }
		var q := [start]
		while not q.is_empty():
			var c: Vector2i = q.pop_back()
			for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n2: Vector2i = c + dv
				if reach.has(n2) or World.solid(room, n2.x, n2.y, World.M_PLAYER):
					continue
				reach[n2] = true
				q.append(n2)
		var voids := 0
		for r in TB.ROWS:
			for c in TB.COLS:
				var t := room.tile(c, r)
				if t == World.T_VOID:
					voids += 1
				elif (t == World.T_FLOOR or t == World.T_DOOR) and not reach.has(Vector2i(c, r)):
					fail("isles: layout %d leaves tile %d,%d cut off" % [room.layout, c, r])
		if voids == 0:
			fail("isles: layout %d has no open sky" % room.layout)
	if seen.size() != 4:
		fail("isles: only layouts %s seen in 400 rooms" % [seen.keys()])
	# The rules of open sky.
	var room := World.make_room(G.floor_d, "combat", "", "s", { "theme": "skyreach", "step": 0 })
	room.set_tile(5, 5, World.T_VOID)
	if not World.solid(room, 5, 5, World.M_PLAYER) or not World.solid(room, 5, 5, World.M_WALKER):
		fail("isles: open sky does not stop the hero or a walker")
	if World.solid(room, 5, 5, World.M_FLYER) or World.solid(room, 5, 5, World.M_BULLET):
		fail("isles: open sky stops a flyer or a shot")
	# A gust shoves the hero along its band, and only inside it.
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "theme": "skyreach", "step": 0 }))
	_tick(5)
	var pl: Player = G.player
	for e in G.enemies:
		e.spawn_t = 0.0
	for r in TB.ROWS:
		for c in TB.COLS:
			if G.room.tile(c, r) == World.T_VOID or G.room.tile(c, r) == World.T_PILLAR:
				G.room.set_tile(c, r, World.T_FLOOR)
	pl.x = 200.0
	pl.y = 150.0
	G.room.strike_t = 99.0
	G.room.gusts = [{ "horiz": true, "pos": 150.0, "dir": 1, "t": 0.0, "blow": 1.0, "spawn": 9.0 }]
	var x0 := pl.x
	for i in 30:
		Hazards.update(TB.DT)
	if pl.x - x0 < 50.0:
		fail("isles: a gust moved the hero only %.1f px" % (pl.x - x0))
	pl.x = 200.0
	pl.y = 100.0
	G.room.gusts = [{ "horiz": true, "pos": 150.0, "dir": 1, "t": 0.0, "blow": 1.0, "spawn": 9.0 }]
	for i in 30:
		Hazards.update(TB.DT)
	if absf(pl.x - 200.0) > 0.01:
		fail("isles: a gust moved a hero outside its band")
	# Stranded on open sky: back onto the nearest island.
	G.room.set_tile(12, 9, World.T_VOID)
	pl.x = 12 * TB.TS + 8.0
	pl.y = 9 * TB.TS + 8.0
	Hazards.update(TB.DT)
	if G.room.tile(floori(pl.x / TB.TS), floori(pl.y / TB.TS)) != World.T_FLOOR:
		fail("isles: a hero on open sky was not put back on an island")

func _saloon_room() -> void:
	_start(2)
	G.enter_room(World.make_room(G.floor_d, "mystery", "", "s", { "event": "saloon" }))
	_tick(5)

func _obj(kind: String) -> Dictionary:
	for o in G.room.objects:
		if o["kind"] == kind and not o.get("gone", false):
			return o
	return {}

func saloon() -> void:
	_saloon_room()
	var p: Player = G.player
	# Every object can be reached: some floor spot within use range is joined to the doors.
	var start := Vector2i(13, 16)
	var reach := { start: true }
	var q := [start]
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n2: Vector2i = c + dv
			if reach.has(n2) or World.solid(G.room, n2.x, n2.y, World.M_PLAYER):
				continue
			reach[n2] = true
			q.append(n2)
	for o in G.room.objects:
		if o.get("used", false):
			continue
		var ok := false
		for cell in reach:
			if TB.dist_xy(cell.x * TB.TS + 8.0, cell.y * TB.TS + 8.0, o["x"], o["y"]) < 20.0:
				ok = true
				break
		if not ok:
			fail("saloon: %s at %d,%d cannot be reached" % [o["kind"], o["x"], o["y"]])
	for kind in ["s_bartender", "s_drink", "s_merchant", "s_broker", "s_drunk", "s_piano", "s_poster", "shop"]:
		if _obj(kind).is_empty():
			fail("saloon: no %s" % kind)
	# Text.
	var texts := []
	for k in Saloon.DRINKS:
		texts.append_array(Saloon.DRINKS[k])
	texts.append_array(Saloon.BARTENDER_LINES)
	texts.append_array(Saloon.DRUNK_LINES)
	texts.append(Saloon.MERCHANT_LINE)
	for k in Saloon.QUESTS:
		var d: Array = Saloon.QUESTS[k]
		texts.append_array([d[0], d[1] % d[2], d[3], "BOUNTY: " + d[0].trim_prefix("BOUNTY: ") + " 99/99"])
	for o in G.room.objects:
		if Saloon.handles(o["kind"]):
			texts.append_array(Saloon.prompt(o))
	_font("saloon", texts)
	# A drink costs gold and gives its boost and its catch.
	p.gold = 100
	var drink := _obj("s_drink")
	var dmg0 := p.dmg
	var rate0 := p.rate
	var crit0 := p.crit
	var armor0 := p.armor
	var gold_before := p.gold
	var cost := Saloon.drink_price()
	if drink["drink"] == "special":
		cost += (gold_before - cost) / 10   # the house special spills a tenth of what is left
	G.interact(drink)
	if p.gold != gold_before - cost:
		fail("saloon: a drink cost %d, not %d" % [gold_before - p.gold, cost])
	if not drink.get("gone", false):
		fail("saloon: a drink was not drunk")
	match drink["drink"]:
		"firewater":
			if not (p.dmg > dmg0 and p.rate < rate0): fail("saloon: dragon's breath did not boost damage and slow fire")
		"quickgin":
			if not p.rate > rate0: fail("saloon: gin did not speed up fire")
		"courage":
			if not (p.armor == armor0 + 2 and p.dmg < dmg0): fail("saloon: courage did not give armor and cut damage")
		"special":
			if not p.crit > crit0: fail("saloon: the special did not raise crit")
	# Every drink works on a fresh hero.
	for id in Saloon.DRINKS:
		_saloon_room()
		var h: Player = G.player
		h.gold = 100
		h.hp = 2
		var b0 := h.buffs.size()
		var a0 := h.armor
		Saloon.drink(h, id)
		match id:
			"moonshine":
				if h.hp != mini(6, h.max_hp) or h.buffs.size() != b0 + 1: fail("saloon: moonshine did not heal and slow")
			"courage":
				if h.armor != a0 + 2: fail("saloon: courage gave no armor")
			"special":
				if h.gold != 90: fail("saloon: the special did not spill gold (%d)" % h.gold)
		if id != "moonshine" and h.buffs.size() <= b0:
			fail("saloon: %s gave no timed boost" % id)
	# Five chats: the next drink is free, once.
	_saloon_room()
	p = G.player
	p.gold = 0
	var bar := _obj("s_bartender")
	for i in 5:
		G.interact(bar)
	var d2 := _obj("s_drink")
	G.interact(d2)
	if not d2.get("gone", false) or p.gold != 0:
		fail("saloon: the free round was not free")
	var d3 := _obj("s_drink")
	G.interact(d3)
	if d3.get("gone", false):
		fail("saloon: a second free drink with no gold")
	# Bounties.
	for id in Saloon.QUESTS:
		_saloon_room()
		p = G.player
		var broker := _obj("s_broker")
		seed(0)
		for tries in 50:
			G.run_stats.erase("quest")
			broker.erase("used")
			G.interact(broker)
			if Saloon.quest().get("id", "") == id:
				break
		if Saloon.quest().get("id", "") != id:
			fail("saloon: the broker never offered %s" % id)
			continue
		if Saloon.hud_line() == "":
			fail("saloon: bounty %s not on the HUD" % id)
		var relics0 := p.relics.size()
		var gold0 := p.gold
		var items0 := G.room.objects.size()
		match id:
			"elites":
				for i in 3:
					var e := Combat.spawn_enemy("skeleton", 200, 150, true, true)
					Combat.damage_enemy(e, e.hp * 3 + 1, { "no_crit": true, "no_mult": true, "silent": true })
				if p.relics.size() != relics0 + 1: fail("saloon: elite bounty paid no relic")
			"cull":
				for i in 60:
					var e := Combat.spawn_enemy("skeleton", 200, 150, false, true)
					Combat.damage_enemy(e, e.hp * 3 + 1, { "no_crit": true, "no_mult": true, "silent": true })
				if p.gold < gold0 + 40: fail("saloon: cull bounty paid no gold")
			"clean":
				for i in 3:
					var r := World.make_room(G.floor_d, "combat", "", "s")
					r.hits = 0
					Saloon.on_room_clear(r)
				if G.room.objects.size() <= items0: fail("saloon: clean bounty dropped no gear")
		if not Saloon.quest().get("done", false) or Saloon.hud_line() != "":
			fail("saloon: bounty %s not done after its goal" % id)
	# An unfinished bounty runs out on a new floor.
	_saloon_room()
	G.interact(_obj("s_broker"))
	if Saloon.quest().is_empty():
		fail("saloon: no bounty taken")
	G.floor_index += 1
	G.start_floor()
	if not Saloon.quest().is_empty():
		fail("saloon: a bounty outlived its floor")
	# Easter eggs.
	_saloon_room()
	var n0 := G.pickups.size()
	var piano := _obj("s_piano")
	for i in 4:
		G.interact(piano)
	if not piano.get("used", false) or G.pickups.size() < n0 + 4:
		fail("saloon: the piano paid nothing")
	n0 = G.pickups.size()
	G.interact(_obj("s_poster"))
	if G.pickups.size() != n0 + 1:
		fail("saloon: the poster paid nothing")
	var drunk := _obj("s_drunk")
	drunk["key"] = true
	n0 = G.pickups.size()
	G.interact(drunk)
	G.interact(drunk)
	if G.pickups.size() != n0 + 1:
		fail("saloon: the drunk kept his key")

func _event(ev: String) -> Player:
	_start(2)
	G.enter_room(World.make_room(G.floor_d, "mystery", "", "s", { "event": ev }))
	_tick(5)
	var p: Player = G.player
	p.gold = 5000
	return p

func _fight_through(max_ticks: int) -> void:
	for i in max_ticks / 10:
		_tick(10)
		_kill_all()
		if not G.locked:
			return

func event_rooms() -> void:
	# Text.
	var texts := []
	for ev in EventRooms.TITLE:
		texts.append_array(EventRooms.TITLE[ev])
	for k in EventRooms.MODS:
		texts.append_array([EventRooms.MODS[k][0], EventRooms.MODS[k][1]])
	for b in EventRooms.BLESSINGS:
		texts.append(b[0])
	for c in EventRooms.CURSES:
		texts.append_array([c[0], "CURSED: " + c[0], "BUT " + c[0]])
	texts.append_array(EventRooms.CARD_NAMES)
	texts.append_array(EventRooms.TELLER_LINES)
	texts.append_array(EventRooms.MECHANIC_LINES)
	texts.append_array(EventRooms.PITBOSS_LINES)
	texts.append("PARCEL: 3 ROOMS, 100S")
	for ev in EventRooms.EVENTS + EventRooms.SPECIAL:
		_event(ev)
		for o in G.room.objects:
			if EventRooms.handles(o["kind"]):
				texts.append_array(EventRooms.prompt(o))
	_font("event rooms", texts)
	# The pit: the bet is taken, the room locks, three waves, three times the bet.
	var p := _event("pit")
	var boss := _obj("e_pitboss")
	var g0 := p.gold
	G.interact(boss)
	var bet: int = boss["bet"]
	if bet <= 0 or p.gold != g0 - bet or not G.locked:
		fail("pit: the bet was not taken or the room not locked")
	_fight_through(6000)
	if G.locked or p.gold != g0 - bet + bet * 3:
		fail("pit: no payout after the waves (gold %d, expected %d)" % [p.gold, g0 + bet * 2])
	# The chop shop: a mod, once; the weapon list is not changed.
	p = _event("chopshop")
	var wid: String = p.weapon["id"]
	var n_fx: int = Weapons.by_id(wid)["effects"].size()
	G.interact(_obj("e_mechanic"))
	if not p.weapon.has("mod") or p.weapon["effects"].size() != n_fx + 1:
		fail("chopshop: no mod on the weapon")
	if Weapons.by_id(wid)["effects"].size() != n_fx or Weapons.by_id(wid).has("mod"):
		fail("chopshop: the weapon list itself was changed")
	var g1 := p.gold
	G.interact(_obj("e_mechanic"))
	if p.gold != g1:
		fail("chopshop: a second mod was sold")
	# The fortune teller: one card, the others vanish, its blessing and curse stay.
	p = _event("fortune")
	var card := _obj("e_card")
	G.interact(card)
	if not p.granted.has("card:" + card["name"]):
		fail("fortune: the card did nothing")
	if G.room.objects.filter(func(o): return o["kind"] == "e_card" and not o.get("gone", false)).size() != 1:
		fail("fortune: the other cards did not vanish")
	# The courier: delivered after three rooms; too slow; lost on a new floor.
	p = _event("courier")
	G.interact(_obj("e_courier"))
	if EventRooms.hud_line() == "":
		fail("courier: no parcel on the HUD")
	var rel0 := p.relics.size()
	g0 = p.gold
	for i in 3:
		G.enter_room(World.make_room(G.floor_d, "treasure", "", "s"))
		_tick(2)
	if p.relics.size() != rel0 + 1 or p.gold < g0 + 25 or not EventRooms.parcel().is_empty():
		fail("courier: the parcel was not paid for")
	p = _event("courier")
	G.interact(_obj("e_courier"))
	EventRooms.parcel()["t"] = 0.1
	_tick(10)
	if not EventRooms.parcel().is_empty():
		fail("courier: a stale parcel was still carried")
	p = _event("courier")
	G.interact(_obj("e_courier"))
	G.floor_index += 1
	G.start_floor()
	if not EventRooms.parcel().is_empty():
		fail("courier: a parcel outlived its floor")
	# The gallery: targets pop up, shots score, prizes by score, targets do not hurt.
	p = _event("gallery")
	var att := _obj("e_attendant")
	G.interact(att)
	if att["t"] <= 0:
		fail("gallery: the round did not start")
	var hits := 0
	for i in 1300:
		_tick(1)
		for e in G.enemies.duplicate():
			if e.type == "target" and e.hp > 0:
				Combat.damage_enemy(e, 5.0, { "no_crit": true, "no_mult": true, "silent": true })
				hits += 1
		if att["t"] <= 0:
			break
	if att["score"] < 12 or att["score"] != hits:
		fail("gallery: score %d from %d hits" % [att["score"], hits])
	if not att["done"] or G.enemies.any(func(e): return e.type == "target"):
		fail("gallery: the round did not end cleanly")
	# The beacon: lit, held in its light, then a chest and the doors open.
	p = _event("beacon")
	var bc := _obj("e_beacon")
	G.interact(bc)
	if not G.locked:
		fail("beacon: lighting it did not lock the room")
	for i in 3200:
		p.x = bc["x"]
		p.y = bc["y"] + 20
		_tick(1)
		if i % 30 == 0:
			_kill_all()
		if not G.locked:
			break
	if G.locked or _obj("ichest").is_empty():
		fail("beacon: holding it gave nothing (held %.1f s)" % bc["held"])
	# The vault: a wrong plate resets; the right order opens it.
	p = _event("vault")
	var st := _obj("e_statue")
	G.interact(st)
	var plates := {}
	for o in G.room.objects:
		if o["kind"] == "e_plate":
			plates[o["col"]] = o
	var wrong: String = st["order"][1]
	p.x = plates[wrong]["x"]
	p.y = plates[wrong]["y"]
	_tick(2)
	if st["step"] != 0 or plates[wrong]["lit"]:
		fail("vault: a wrong plate was taken")
	for col in st["order"]:
		p.x = 14.0 * TB.TS
		p.y = 15.0 * TB.TS
		_tick(2)
		p.x = plates[col]["x"]
		p.y = plates[col]["y"]
		_tick(2)
	if not st["done"] or G.room.objects.filter(func(o): return o["kind"] == "ichest").size() != 2:
		fail("vault: the right order did not open it")
	# The cursed armory: the weapon comes with its curse; the others are locked away.
	p = _event("cursed")
	var item := _obj("item")
	var cu: int = item["curse"]
	G.interact(item)
	if not p.granted.has("curse:" + str(cu)):
		fail("cursed: the curse did not stick")
	if G.room.objects.filter(func(o): return o["kind"] == "item" and o.get("curse", -1) >= 0 and not o.get("gone", false)).size() != 0:
		fail("cursed: the other weapons were not locked away")
	# Wanderers: placed clear of the doors and of the hero; each gives what it should.
	var placed := { "w_drunk": 0, "w_merchant": 0 }
	for sd in 400:
		_start(3)
		G.run_stats["saloon_floor"] = 1
		seed(sd)
		var r := World.make_room(G.floor_d, "combat", "", "s")
		G.enter_room(r)
		_tick(2)
		EventRooms.on_room_clear(r)
		for o in r.objects:
			if placed.has(o["kind"]):
				placed[o["kind"]] += 1
				for d in ["n", "s", "w", "e"]:
					if TB.dist_xy(o["x"], o["y"], World.door_center(d).x, World.door_center(d).y) < 70:
						fail("wanderer %s next to the %s door" % [o["kind"], d])
				if World.hits_solid(r, o["x"], o["y"], 6, World.M_PLAYER):
					fail("wanderer %s in a wall" % o["kind"])
				var n0 := G.pickups.size()
				G.player.gold = 500
				G.interact(o)
				if G.pickups.size() != n0 + 1:
					fail("wanderer %s gave nothing" % o["kind"])
		if placed["w_drunk"] > 0 and placed["w_merchant"] > 0:
			break
	if placed["w_drunk"] == 0 or placed["w_merchant"] == 0:
		fail("wanderers never met: %s" % [placed])

func _reachable_all(room: Room) -> bool:
	var start := Vector2i(13, 16)
	var reach := { start: true }
	var q := [start]
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n2: Vector2i = c + dv
			if reach.has(n2) or World.solid(room, n2.x, n2.y, World.M_PLAYER):
				continue
			reach[n2] = true
			q.append(n2)
	for r in TB.ROWS:
		for c in TB.COLS:
			var t := room.tile(c, r)
			if (t == World.T_FLOOR or t == World.T_DOOR) and not reach.has(Vector2i(c, r)):
				return false
	return true

func _rift_room(world: String) -> Room:
	_start(2)
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "theme": world, "step": 0 }))
	_tick(3)
	return G.room

func worlds2() -> void:
	_start(2)
	G.locked = false   # door tiles count as floor for the flood
	for world in ["bastion", "cathedral"]:
		var seen := {}
		var base := 200 if world == "bastion" else 300
		for sd in 400:
			var room := World.make_room(G.floor_d, "combat", "", "s", { "theme": world, "step": 0 })
			room.seed_value = sd * 7919 + 3
			room.doors = { "n": true, "w": true, "e": true, "s": true }
			World.build_room(room)
			if room.layout <= base or room.layout > base + 4:
				fail("%s: a fight room has layout %d" % [world, room.layout])
				continue
			if not _reachable_all(room):
				fail("%s: layout %d cuts floor off" % [world, room.layout])
			seen[room.layout] = true
		if seen.size() != 4:
			fail("%s: only layouts %s seen" % [world, seen.keys()])
	_font("worlds2", RiftExtras.SKULL_JOKES + ["THE DROWNED BASTION", "THE TIDE COMES IN POISONED", "THE CALIBER CATHEDRAL",
		"FLIP A TABLE. SAY A PRAYER", "THE ROTTING KING", "THE HIGH CALIBER", "THE RAT GOT AWAY WITH YOUR GOLD",
		"A HIDDEN ALCOVE GRINDS OPEN", "THE SKULL SPITS OUT A GEM. TOUGH CROWD", "SHH. THEY'RE BITING.", "A FISH! WELL, IT'S FOOD.",
		"AN OLD BOOT. THERE WAS A COIN IN IT.", "THE BULLET SAINT BLESSES YOUR ROUNDS: +20% FOR 90S", "A RAT! IT GRABS 99 GOLD AND RUNS",
		"CAUGHT IT. THE RAT PAYS BACK DOUBLE"])
	for kind in RiftExtras.KINDS:
		_font("worlds2 " + kind, RiftExtras.prompt({ "kind": kind }))
	# Tables: every cathedral fight room has some; a flipped one is cover and leaves no one inside it.
	var rm := _rift_room("cathedral")
	var tables := rm.objects.filter(func(o): return o["kind"] == "x_table")
	if tables.is_empty():
		fail("cathedral: a fight room without tables")
	else:
		var tb: Dictionary = tables[0]
		var p: Player = G.player
		p.x = tb["c"] * TB.TS + 10.0
		p.y = tb["r"] * TB.TS + 8.0
		G.interact(tb)
		if rm.tile(tb["c"], tb["r"]) != World.T_PROP or not World.solid(rm, tb["c"] + 1, tb["r"], World.M_BULLET) \
				or not World.solid(rm, tb["c"], tb["r"], World.M_WALKER):
			fail("cathedral: a flipped table is not cover")
		if World.hits_solid(rm, p.x, p.y, p.r, World.M_PLAYER):
			fail("cathedral: the hero was left inside a flipped table")
		var n0: int = EBullets.n
		EBullets.add(tb["x"], tb["y"] - 40.0, 0.0, 200.0, "red", 2.5, -1.0, "")
		for i in 30:
			EBullets.update(TB.DT)
		if EBullets.n > n0:
			fail("cathedral: a shot went through a flipped table")
	# The turrets aim, then fire.
	rm = _rift_room("cathedral")
	if rm.turrets.is_empty():
		fail("cathedral: no turrets")
	else:
		var foe0 := Combat.spawn_enemy("skeleton", 60.0, 250.0, false, true)
		foe0.spawn_t = 0.0
		var shots0: int = EBullets.n
		var aimed := false
		for i in 400:
			for e in G.enemies:
				e.hp = e.max_hp
			Hazards.update(TB.DT)
			EBullets.update(TB.DT)
			if rm.turrets[0]["state"] == 1:
				aimed = true
			if EBullets.n > shots0 + 2:
				break
		if not aimed or EBullets.n <= shots0:
			fail("cathedral: the turrets never aimed and fired")
	# The saint and the rat.
	rm = _rift_room("cathedral")
	var p2: Player = G.player
	p2.gold = 200
	var saint := { "kind": "x_saint", "x": 200.0, "y": 150.0 }
	rm.objects.append(saint)
	var b0 := p2.buffs.size()
	G.interact(saint)
	if p2.gold != 200 - G.price(15 + G.floor_index * 3) or p2.buffs.size() != b0 + 1:
		fail("cathedral: the saint took no gold or gave no blessing")
	var pile := { "kind": "x_ratpile", "x": 220.0, "y": 180.0 }
	rm.objects.append(pile)
	var g0 := p2.gold
	G.interact(pile)
	var stolen: int = pile.get("stolen", 0)
	var rat = null
	for e in G.enemies:
		if e.type == "casingrat":
			rat = e
	if stolen <= 0 or p2.gold != g0 - stolen or rat == null:
		fail("cathedral: the rat stole nothing or never appeared")
	else:
		Combat.damage_enemy(rat, rat.hp * 3 + 1, { "no_crit": true, "no_mult": true, "silent": true })
		if p2.gold != g0 + stolen:
			fail("cathedral: the caught rat paid back %d, not %d" % [p2.gold - (g0 - stolen), stolen * 2])
	# The bastion: lever, skull, fisher.
	rm = _rift_room("bastion")
	var lever := { "kind": "x_lever", "x": 100.0, "y": 36.0, "pulled": false }
	var skull := { "kind": "x_skull", "x": 150.0, "y": 150.0, "talks": 0 }
	var fisher := { "kind": "x_fisher", "x": 250.0, "y": 150.0, "talks": 0 }
	rm.objects.append_array([lever, skull, fisher])
	var n1 := G.pickups.size()
	G.interact(lever)
	if G.pickups.size() < n1 + 4 or not lever["pulled"]:
		fail("bastion: the lever opened nothing")
	n1 = G.pickups.size()
	for i in 3:
		G.interact(skull)
	if G.pickups.size() != n1 + 1 or not skull.get("used", false):
		fail("bastion: the skull's third joke paid nothing")
	n1 = G.pickups.size()
	G.interact(fisher)
	G.interact(fisher)
	if G.pickups.size() != n1 + 1:
		fail("bastion: the fisher caught nothing")
	# The tide: it hurts foes in its band and the hero once.
	rm = _rift_room("bastion")
	var ph: Player = G.player
	ph.x = 200.0
	ph.y = 150.0
	ph.invuln = 0.0
	var foe := Combat.spawn_enemy("skeleton", 120.0, 150.0, false, true)
	foe.max_hp = 1000.0
	foe.hp = 1000.0
	rm.strike_t = 99.0
	rm.tides = [{ "y": 150.0, "dir": 1, "t": 0.0, "x": 20.0, "hit": {}, "hit_p": false }]
	var hp0 := ph.hp
	G.god = false
	for i in 120:
		ph.dodge_t = 0.0
		RiftExtras.update(rm, TB.DT)
	G.god = true
	if foe.hp >= 1000.0:
		fail("bastion: the tide did not hurt a foe in its band")
	if ph.hp >= hp0 and ph.armor <= 0:
		fail("bastion: the tide did not hurt the hero")
