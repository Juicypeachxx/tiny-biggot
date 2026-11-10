extends Node
## Stage 48 (his 16 "cinders", 10 Oct; ROADMAP.md). Run:
##   godot --headless --path . res://tests/stage48_test.tscn -- --no-save
## 48.1 DREAD to 16 (dread.gd): the cap (16; classic 5), every level's +0.5% health a floor for foes
## and guardians, the first five's numbers stop at 5, and each new level's rule: FLAWED STEEL, COLD
## START, PACKED HALLS, BLOOD TOLL, ESCORTED, TIDE OF ROOMS (floor maps of 5 to 14 rooms still
## work), CROWNED, THE HUNTER, FALTERING NERVE, PLAGUE, TWICE CROWNED; none of them in classic.
## 48.2 STAR DUST: the dread bonus, what a run earns and leaves in the save, star points from it;
## the constellation of 60 (10 stars a spoke, no two too close, every notable name its own, every
## word in the pixel font, all of it taken at once starts a run). 48.3 six skills a tree branch
## (four in classic, which still starts with a tree learned in the expanded game), each does
## something, the reset gives every ember back after a second press (key and tap), the tree's taps.
## 48.4 RESET GAME: from the title's options only, after a second press.
## Prints "stage48 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage48: ", msg)

func _start(hero: int = 0, dread: int = 0, fi: int = 2) -> Player:
	Meta.meta["dread_max"] = dread
	Meta.meta["dread"] = dread
	G.hero_index = hero
	G.new_run()
	G.floor_index = clampi(fi, 0, GameData.floors().size() - 1)
	G.start_floor()
	G.god = true
	var p := G.player
	p.oath_picks = 0
	p.special_picks = 0
	p.pending = 0
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.enemies.clear()
	G.locked = true
	G.state = &"play"
	return p

func _font(where: String, s: String) -> void:
	for ch in s.to_upper():
		if Gfx.FONT_CHARS.find(ch) < 0:
			fail("%s: \"%s\" is not in the pixel font (%s)" % [where, ch, s])
			return

func _release() -> void:
	for k in Keys._trig.keys():
		Keys._trig[k] = false
	for k in Keys._rep.keys():
		Keys._rep[k] = false

func _press(a: StringName) -> void:
	_release()
	Keys._trig[a] = true

func _ready() -> void:
	seed(48)
	_dread()
	_dust()
	_stars()
	_trees()
	_reset_game()
	_release()
	print("stage48 test: PASSED" if fails == 0 else "stage48 test: %d FAILED" % fails)
	get_tree().quit()

# ---------- 48.1 DREAD ----------
func _dread() -> void:
	if Dread.cap() != 16:
		fail("DREAD opens to %d (want 16)" % Dread.cap())
	if GameData.DREAD_DESC.size() != 17:
		fail("%d DREAD lines (want 17: none and 16 levels)" % GameData.DREAD_DESC.size())
	for i in GameData.DREAD_DESC.size():
		_font("DREAD %d" % i, GameData.DREAD_DESC[i])
		if TB.text_w("DREAD %d: %s" % [i, GameData.DREAD_DESC[i]]) > TB.SW - 24:
			fail("DREAD %d's line is wider than the screen" % i)

	# Health: +0.5% a floor for each level, foes and guardians alike; the first five stop at 5.
	var boss_key: String = GameData.BOSSES.keys()[0]
	var hp := {}
	for d in [5, 9]:
		seed(7)
		_start(0, d, 2)
		var e := Combat.spawn_enemy("slime", 120, 120, false, true)
		var b := Combat.spawn_boss(boss_key, true)
		hp[d] = [e.max_hp, b.max_hp]
		G.enemies.clear()
	var want := (1.0 + 0.005 * 9 * 3) / (1.0 + 0.005 * 5 * 3)
	for k in 2:
		var got: float = hp[9][k] / hp[5][k]
		if absf(got - want) > 0.002:
			fail("DREAD 9 against 5 on floor 3: %s health x%.4f (want x%.4f)" % [["a foe", "a guardian"][k], got, want])
	G.dread = 16
	if Dread.old() != 5:
		fail("DREAD 16: the first five's numbers count %d (want 5)" % Dread.old())

	# 6 FLAWED STEEL
	var p := _start(0, 6, 2)
	if not (Enchant.of(p.weapon) in Enchant.group_of("bad")):
		fail("DREAD 6: the starting weapon is not flawed (%s)" % Enchant.of(p.weapon))
	p = _start(0, 5, 2)
	if Enchant.of(p.weapon) in Enchant.group_of("bad"):
		fail("DREAD 5: the starting weapon is flawed")

	# 7 COLD START
	G.dread = 7
	for fi in 4:
		G.floor_index = fi
		var wd: float = [3.0, 2.0, 1.0, 0.0][fi]
		if Dread.roll_delay() != wd:
			fail("DREAD 7 on floor %d: rolls %.1f s slower (want %.1f)" % [fi + 1, Dread.roll_delay(), wd])
	G.dread = 6
	G.floor_index = 0
	if Dread.roll_delay() != 0.0:
		fail("DREAD 6: rolls recharge slower")

	# 8 PACKED HALLS (the room is a fight)
	G.dread = 8
	var doubled := 0
	for i in 2000:
		if Dread.pack(5) == 10:
			doubled += 1
	if doubled < 300 or doubled > 500:
		fail("DREAD 8: %d of 2000 waves packed (want about 400)" % doubled)
	G.dread = 7
	for i in 200:
		if Dread.pack(5) != 5:
			fail("DREAD 7: a wave was packed")
			break

	# 9 BLOOD TOLL
	G.dread = 9
	var fd := { "map": { "cells": {} } }
	for i in 400:
		fd["map"]["cells"][Vector2i(i, 0)] = { "type": ["treasure", "shrine", "combat", "shop"][i % 4] }
	Dread.on_floor_map(fd)
	var tolls := [0, 0]
	for c in fd["map"]["cells"].values():
		if c.get("toll", false):
			tolls[0 if c["type"] in ["treasure", "shrine"] else 1] += 1
	if tolls[0] < 70 or tolls[0] > 130 or tolls[1] > 0:
		fail("DREAD 9: %d of 200 treasure rooms and shrines ask a heart (want about 100), %d other rooms" % tolls)
	p = G.player
	p.max_hp = maxi(p.max_hp, 10)
	p.hp = 6
	var cell := { "toll": true }
	if not Dread.pay_toll(p, cell) or p.hp != 4 or cell["toll"]:
		fail("DREAD 9: the door's heart: went in %s, health %d (want 4), still asks %s" % [str(cell["toll"] == false), p.hp, str(cell["toll"])])
	p.hp = 2
	cell = { "toll": true }
	if Dread.pay_toll(p, cell) or p.hp != 2:
		fail("DREAD 9: the door took the last heart")
	if not Dread.pay_toll(p, { "type": "treasure" }) or p.hp != 2:
		fail("DREAD 9: a door without a toll asked one")
	G.dread = 8
	fd = { "map": { "cells": { Vector2i.ZERO: { "type": "treasure" } } } }
	for i in 50:
		Dread.on_floor_map(fd)
	if fd["map"]["cells"][Vector2i.ZERO].get("toll", false):
		fail("DREAD 8: a door asks a heart")

	# 10 ESCORTED, 12 CROWNED, 14 FALTERING NERVE
	for d in [9, 10, 12, 14]:
		_start(0, d, 2)
		Dread.nerve_t = 0.0
		var b := Combat.spawn_boss(boss_key, true)
		var guards := G.enemies.filter(func(o): return o != b and o.elite and o.hp > 0).size()
		if guards != (2 if d >= 10 else 0):
			fail("DREAD %d: the guardian came with %d elite guards" % [d, guards])
		if (b.traits.size() > 0) != (d >= 12):
			fail("DREAD %d: the guardian carries %d elite traits" % [d, b.traits.size()])
		if (Dread.nerve_t > 0.0) != (d >= 14):
			fail("DREAD %d: nerve %.1f s at the guardian's start" % [d, Dread.nerve_t])
		G.enemies.clear()
	Dread.nerve_t = Dread.NERVE_TIME
	var nm := [Dread.nerve_mult()]
	Dread.tick(10.0)
	nm.append(Dread.nerve_mult())
	Dread.tick(10.0)
	nm.append(Dread.nerve_mult())
	if absf(nm[0] - 0.5) > 0.001 or absf(nm[1] - 0.75) > 0.001 or nm[2] != 1.0:
		fail("DREAD 14: damage x%.2f, x%.2f after 10 s, x%.2f after 20 s (want 0.5, 0.75, 1)" % nm)
	# ... and a blow really does half.
	p = _start(0, 14, 2)
	var foe := Combat.spawn_enemy("slime", p.x + 40, p.y, false, true)
	foe.max_hp = 1e7
	foe.hp = 1e7
	foe.speed = 0.0
	var dealt := [0.0, 0.0]
	for k in 2:
		for i in 600:
			Dread.nerve_t = Dread.NERVE_TIME if k == 1 else 0.0
			var h0 := foe.hp
			Combat.damage_enemy(foe, 10.0, { "no_crit": true })
			dealt[k] += h0 - foe.hp
	Dread.nerve_t = 0.0
	if absf(dealt[1] / maxf(1.0, dealt[0]) - 0.5) > 0.03:
		fail("DREAD 14: a blow at a stage's start deals x%.3f (want x0.5)" % (dealt[1] / maxf(1.0, dealt[0])))
	# 12 CROWNED: a champion or mini-boss too.
	var champs: Array = GameData.ENEMIES.keys().filter(func(k): return GameData.ENEMIES[k].get("champion", false))
	if champs.is_empty():
		fail("no champions to test with")
	else:
		for d in [11, 12]:
			_start(0, d, 2)
			var c := Combat.spawn_enemy(champs[0], 150, 120, false, true)
			if (c.traits.size() > 0) != (d >= 12):
				fail("DREAD %d: a champion carries %d elite traits" % [d, c.traits.size()])
			G.enemies.clear()

	# 13 THE HUNTER
	_start(0, 13, 2)
	G.run_stats["hunter_in"] = 1
	var n0 := G.enemies.size()
	Dread.maybe_hunter(true)
	var hunter: Enemy = G.enemies.back() if G.enemies.size() > n0 else null
	if hunter == null or not hunter.d.get("champion", false):
		fail("DREAD 13: no champion hunted you when the count ran out")
	var left: int = G.run_stats.get("hunter_in", -1)
	if left < 8 or left > 20:
		fail("DREAD 13: the next hunt in %d fights (want 8 to 20)" % left)
	G.run_stats["hunter_in"] = 5
	n0 = G.enemies.size()
	Dread.maybe_hunter(true)
	Dread.maybe_hunter(false)
	if G.run_stats["hunter_in"] != 4 or G.enemies.size() != n0:
		fail("DREAD 13: a fight counted %d (want 4 left) and the hunter came early" % G.run_stats["hunter_in"])
	_start(0, 12, 2)
	for i in 30:
		Dread.maybe_hunter(true)
	if G.enemies.size() > 0:
		fail("DREAD 12: a hunter came")

	# 15 PLAGUE
	p = _start(0, 15, 2)
	var one := Combat.spawn_enemy("slime", 150, 150, false, true)
	var carried := 0
	for i in 2000:
		one.plague = false
		Dread.maybe_plague([one])
		if one.plague:
			carried += 1
	if carried < 560 or carried > 840:
		fail("DREAD 15: %d of 2000 waves held a carrier (want about 700)" % carried)
	G.enemies.clear()
	var carrier := Combat.spawn_enemy("slime", p.x + 10, p.y, false, true)
	carrier.plague = true
	var near := Combat.spawn_enemy("slime", p.x + 40, p.y, false, true)
	var far := Combat.spawn_enemy("slime", p.x + 200, p.y, false, true)
	G.god = false
	p.invuln = 0.0
	p.dodge_t = 0.0
	p.armor = 0
	p.evade = 0.0
	p.buckler = false
	p.max_hp = maxi(p.max_hp, 10)
	p.hp = p.max_hp
	var hp0 := p.hp
	Combat.kill_enemy(carrier)
	G.god = true
	if not near.plague or far.plague:
		fail("DREAD 15: the burst passed the plague to the foe close by %s, far away %s" % [str(near.plague), str(far.plague)])
	if p.hp >= hp0:
		fail("DREAD 15: a carrier burst right beside the hero and did not hurt")
	_start(0, 14, 2)
	one = Combat.spawn_enemy("slime", 150, 150, false, true)
	for i in 200:
		Dread.maybe_plague([one])
	if one.plague:
		fail("DREAD 14: a plague carrier")

	# 16 TWICE CROWNED (floor 2: an elite's one trait, one more at 16)
	for d in [15, 16]:
		_start(0, d, 1)
		var e := Combat.spawn_enemy("skeleton", 150, 120, true, true)
		if e.traits.size() != (2 if d >= 16 else 1):
			fail("DREAD %d: an elite carries %d traits" % [d, e.traits.size()])
		G.enemies.clear()

	# 11 TIDE OF ROOMS: and the floor maps still come out whole.
	var last := GameData.floors().size() - 1
	for d in [10, 11]:
		for fi in [0, 1, 2, 5, 7, 9]:
			if fi > last:
				continue
			_start(0, d, fi)
			var base := mini(7 + fi, 11)
			var wt := base
			if d >= 11:
				wt = maxi(5, base - (3 - fi)) if fi < 3 else (base + mini(3, fi - 6) if fi >= 7 else base)
			if G.floor_d["total"] != wt:
				fail("DREAD %d, floor %d: %d rooms (want %d)" % [d, fi + 1, G.floor_d["total"], wt])
			if G.floor_d.has("map"):
				var m: Dictionary = G.floor_d["map"]
				var cells: Dictionary = m["cells"]
				if cells.size() < wt + 4 or not cells.has(m["boss"]) or cells[m["boss"]]["type"] != "boss":
					fail("DREAD %d, floor %d: a map of %d rooms, guardian's room %s" % [d, fi + 1, cells.size(), str(cells.has(m["boss"]))])

	# Classic: the first five only.
	GameData.force_classic = true
	if Dread.cap() != 5:
		fail("classic DREAD opens to %d (want 5)" % Dread.cap())
	p = _start(0, 16, 0)
	if G.dread != 5:
		fail("classic: a run at DREAD %d (want 5)" % G.dread)
	G.dread = 16
	if Dread.has(6) or Dread.roll_delay() != 0.0 or Dread.hp_mult() != 1.0 or Dread.pack(5) != 5 or Dread.floor_rooms(0, 7) != 7:
		fail("classic has the new DREAD rules")
	GameData.force_classic = false
	G.dread = 16
	print("[stage48] DREAD: 16 levels, each rule in force from its level, none in classic; floors of %d to %d rooms" % [Dread.floor_rooms(0, 7), Dread.floor_rooms(9, 11)])
	G.dread = 0

# ---------- 48.2 STAR DUST ----------
func _dust() -> void:
	var want := { 0: 1.0, 1: 1.3, 4: 2.2, 5: 2.4, 8: 3.0, 9: 3.1, 12: 3.4, 13: 3.45, 16: 3.6 }
	for l in want:
		if absf(Dread.dust_mult(l) - want[l]) > 0.0001:
			fail("STAR DUST at DREAD %d: x%.2f (want x%.2f)" % [l, Dread.dust_mult(l), want[l]])
	_start(0, 0, 2)
	G.run_stats["kills"] = 40
	G.run_stats["bosses"] = 1
	if Stars.dust_for(false) != 65 or Stars.dust_for(true) != 165:
		fail("STAR DUST: 40 kills, floor 3, a guardian: %d, with a win %d (want 65, 165)" % [Stars.dust_for(false), Stars.dust_for(true)])
	G.dread = 4
	if Stars.dust_for(false) != 143:
		fail("STAR DUST at DREAD 4: %d (want 143)" % Stars.dust_for(false))
	G.dread = 0
	Meta.meta["dust"] = 10
	G.award_embers(false)
	if int(Meta.meta.get("dust", 0)) != 75 or G.award.get("dust", -1) != 65:
		fail("STAR DUST: a run's end left %d in the save (want 75), shows %d" % [int(Meta.meta.get("dust", 0)), G.award.get("dust", -1)])
	var keep := [Meta.meta.get("bosses", 0), Meta.meta.get("wins", 0)]
	Meta.meta["bosses"] = 0
	Meta.meta["wins"] = 0
	Meta.meta["dust"] = 749
	if Stars.points() != 2:
		fail("STAR DUST: 749 gives %d star points (want 2)" % Stars.points())
	Meta.meta["bosses"] = 3
	Meta.meta["wins"] = 1
	if Stars.points() != 7:
		fail("STAR DUST: 3 guardians, a win and 749 dust give %d points (want 7)" % Stars.points())
	Meta.meta["dust"] = 1000000
	if Stars.points() != 60:
		fail("STAR DUST: a mountain of it gives %d points (want 60)" % Stars.points())
	Meta.meta["bosses"] = keep[0]
	Meta.meta["wins"] = keep[1]
	Meta.meta["dust"] = 0
	GameData.force_classic = true
	_start(0, 0, 2)
	G.run_stats["kills"] = 40
	G.award_embers(false)
	if int(Meta.meta.get("dust", 0)) != 0:
		fail("classic earned STAR DUST")
	GameData.force_classic = false
	print("[stage48] STAR DUST: x1 to x3.6 by DREAD; a point for every %d, up to %d points" % [Stars.DUST_PER_POINT, Stars.MAX_POINTS])

# ---------- 48.2 the constellation ----------
func _stars() -> void:
	var ns := Stars.nodes()
	var ids := {}
	var names := {}
	for n in ns:
		if ids.has(n["id"]):
			fail("two stars are called %s" % n["id"])
		ids[n["id"]] = true
		if n["notable"] and n["id"] != "heart":
			if names.has(n["name"]):
				fail("two notable stars are named %s" % n["name"])
			names[n["name"]] = true
		_font("star " + n["id"], n["name"] + " " + n["text"])
	for side in ["n", "e", "s", "w"]:
		for k in range(1, 11):
			if not ids.has("%s%d" % [side, k]):
				fail("the %s spoke has no star %d" % [side, k])
		if ids.has("%s11" % side):
			fail("the %s spoke is longer than 10" % side)
		var nb := ns.filter(func(n): return n["side"] == side and n["notable"]).size()
		if nb != Stars.NOTABLE[side].size():
			fail("the %s spoke shows %d notable stars of %d" % [side, nb, Stars.NOTABLE[side].size()])
	var closest := 1e9
	var pair := ""
	for a in ns.size():
		for b in range(a + 1, ns.size()):
			var dd: float = (ns[a]["pos"] as Vector2).distance_to(ns[b]["pos"])
			if dd < closest:
				closest = dd
				pair = ns[a]["id"] + " and " + ns[b]["id"]
	if closest < 30.0:
		fail("stars %s are %.1f apart (want 30 or more)" % [pair, closest])
	# Every star at once: a run starts with all of them; DEEP DRAUGHT's sip.
	var all := {}
	for n in ns:
		if n["id"] != "heart":
			all[n["id"]] = true
	Meta.meta["stars"] = all
	var p := _start(0, 0, 2)
	if Gourd.max_sips(p) != 2:
		fail("every star taken: the gourd holds %d sips (want 2: DEEP DRAUGHT)" % Gourd.max_sips(p))
	Meta.meta["stars"] = {}
	print("[stage48] the constellation: %d stars, %d notable, the closest two %.0f apart" % [ns.size(), names.size(), closest])

# ---------- 48.3 the hero trees ----------
func _trees() -> void:
	var total := 0
	for c in Traits.TREE_COSTS:
		total += c
	for h in GameData.heroes():
		var t := Traits.tree_for(h["id"])
		if t.size() != 3:
			fail("%s's tree has %d branches" % [h["name"], t.size()])
		for bi in t.size():
			if t[bi]["nodes"].size() != Traits.TREE_COSTS.size():
				fail("%s's %s has %d skills (want %d)" % [h["name"], t[bi]["name"], t[bi]["nodes"].size(), Traits.TREE_COSTS.size()])
			for nd in t[bi]["nodes"]:
				if not Traits.NODE_EFFECTS.has(nd[0]):
					fail("%s's skill %s does nothing" % [h["name"], nd[0]])
				_font("skill " + nd[0], nd[0] + " " + nd[1])
				if TB.text_w(nd[0]) > 96:
					fail("skill %s's name is wider than its box" % nd[0])
	GameData.force_classic = true
	for h in GameData.heroes():
		for br in Traits.tree_for(h["id"]):
			if br["nodes"].size() != 4:
				fail("classic: %s's %s has %d skills (want 4)" % [h["name"], br["name"], br["nodes"].size()])
	GameData.force_classic = false
	if Traits.tree_spent([6, 6, 6]) != 3 * total or Traits.tree_spent([2, 1, 0]) != 40:
		fail("a tree's cost: %d for all of it (want %d), %d for 2, 1 and 0 (want 40)" % [Traits.tree_spent([6, 6, 6]), 3 * total, Traits.tree_spent([2, 1, 0])])

	# The whole tree learned: every skill applies; LONG ROAD's sip, IRON WILL's and LEGEND's hearts.
	var hid: String = GameData.heroes()[0]["id"]
	# (The same seed for both: HEIRLOOM's random relic may be one that adds a sip.)
	Meta.meta["tree"][hid] = [4, 4, 4]
	seed(11)
	var p := _start(0, 0, 2)
	var four := [Gourd.max_sips(p), p.max_hp]
	Meta.meta["tree"][hid] = [6, 6, 6]
	seed(11)
	p = _start(0, 0, 2)
	if Gourd.max_sips(p) != four[0] + 1 or p.max_hp != four[1] + 4:
		fail("the whole tree: %d sips and %d max health (want %d and %d)" % [Gourd.max_sips(p), p.max_hp, four[0] + 1, four[1] + 4])
	# Classic with a save from the expanded game: the first four, no error.
	GameData.force_classic = true
	p = _start(0, 0, 0)
	if p == null or p.hp <= 0:
		fail("classic with a six-skill tree saved did not start")
	GameData.force_classic = false

	# The reset: the first press asks, the second gives every ember back.
	G.tree_hero = 0
	G.tree_b = 0
	G.tree_n = 0
	Meta.meta["tree"][hid] = [2, 1, 0]
	Meta.meta["embers"] = 5
	G.tree_reset_armed = false
	G.tree_reset()
	if Meta.meta["embers"] != 5 or not G.tree_reset_armed or Meta.meta["tree"][hid] != [2, 1, 0]:
		fail("RESET THIS TREE did not ask first")
	G.tree_reset()
	if Meta.meta["embers"] != 45 or Meta.meta["tree"][hid] != [0, 0, 0]:
		fail("RESET THIS TREE: %d embers (want 45), the tree %s" % [Meta.meta["embers"], str(Meta.meta["tree"][hid])])
	G.tree_reset()
	G.tree_reset()
	if Meta.meta["embers"] != 45:
		fail("RESET THIS TREE with nothing learned gave embers")
	# By the keys: BOMB twice; moving between the presses asks again.
	G.state = &"tree"
	Meta.meta["tree"][hid] = [1, 0, 0]
	Meta.meta["embers"] = 0
	_press(&"bomb")
	G.update_tree()
	_release()
	Keys._rep[&"move_down"] = true
	G.update_tree()
	_press(&"bomb")
	G.update_tree()
	if Meta.meta["embers"] != 0:
		fail("RESET THIS TREE: a move between the presses did not ask again")
	_press(&"bomb")
	G.update_tree()
	_release()
	if Meta.meta["embers"] != 10 or Meta.meta["tree"][hid] != [0, 0, 0]:
		fail("RESET THIS TREE by BOMB twice: %d embers (want 10)" % Meta.meta["embers"])
	# Learning the fifth and sixth skills: in order, at their price.
	Meta.meta["tree"][hid] = [4, 0, 0]
	Meta.meta["embers"] = 1000
	G.tree_b = 0
	G.tree_n = 5
	_press(&"use")
	G.update_tree()
	G.tree_n = 4
	_press(&"use")
	G.update_tree()
	G.tree_n = 5
	_press(&"use")
	G.update_tree()
	_release()
	if Meta.meta["tree"][hid][0] != 6 or Meta.meta["embers"] != 1000 - 100 - 150:
		fail("learning the fifth and sixth skills: the branch at %d, %d embers left (want 6, 750)" % [Meta.meta["tree"][hid][0], Meta.meta["embers"]])

	# The tree's taps: a box for each skill, none on another, each its own; RESET THIS TREE.
	for classic in [false, true]:
		GameData.force_classic = classic
		G.state = &"tree"
		G.tree_n = 0
		var zs := Taps.zones()
		var sel := zs.filter(func(z): return z.has("sel"))
		var nn: int = Traits.tree_for(hid)[0]["nodes"].size()
		if sel.size() != 3 * nn:
			fail("tree taps%s: %d boxes for %d skills" % [" (classic)" if classic else "", sel.size(), 3 * nn])
		for a in sel.size():
			var ra: Rect2 = sel[a]["rect"]
			if ra.position.x < 0 or ra.position.y < 0 or ra.end.x > TB.SW or ra.end.y > TB.SH:
				fail("tree taps: box %d off the screen" % a)
			for b in range(a + 1, sel.size()):
				if ra.intersects(sel[b]["rect"]):
					fail("tree taps: boxes %d and %d overlap" % [a, b])
			if ra.intersects(MenuView.TREE_RESET.grow(2)):
				fail("tree taps: box %d is on RESET THIS TREE" % a)
			sel[a]["sel"].call()
			if G.tree_b != a / nn or G.tree_n != a % nn:
				fail("tree taps: box %d picks branch %d skill %d" % [a, G.tree_b, G.tree_n])
		var reset := zs.filter(func(z): return not z.has("sel") and (z["rect"] as Rect2).intersects(MenuView.TREE_RESET))
		if reset.size() != 1:
			fail("tree taps: %d zones on RESET THIS TREE (want 1)" % reset.size())
		elif not classic:
			Meta.meta["tree"][hid] = [1, 0, 0]
			Meta.meta["embers"] = 0
			G.tree_reset_armed = false
			reset[0]["act"].call()
			reset[0]["act"].call()
			if Meta.meta["embers"] != 10:
				fail("tree taps: RESET THIS TREE tapped twice gave %d embers (want 10)" % Meta.meta["embers"])
	GameData.force_classic = false
	G.state = &"play"
	print("[stage48] hero trees: %d heroes, 3 branches of %d skills, %d embers for a whole tree; reset by key and tap" % [GameData.heroes().size(), Traits.TREE_COSTS.size(), 3 * total])

# ---------- 48.4 RESET GAME ----------
func _reset_game() -> void:
	var row := -1
	for i in G.OPTION_LIST.size():
		if G.OPTION_LIST[i][1] == "@reset":
			row = i
	if row < 0:
		fail("no RESET GAME in the options")
		return
	_font("options", G.OPTION_LIST[row][0])
	# From the pause menu: never.
	Meta.meta["embers"] = 50
	G.state = &"options"
	G.opt_from = &"pause"
	G.menu = row
	for i in 2:
		_press(&"use")
		G.update_options()
	_release()
	if Meta.meta["embers"] != 50:
		fail("RESET GAME worked from the pause menu")
	# From the title: the first press asks, the second starts it all over.
	Meta.meta["embers"] = 777
	Meta.meta["dust"] = 999
	Meta.meta["wins"] = 3
	Meta.meta["dread_max"] = 9
	G.reset_armed = false
	G.state = &"options"
	G.opt_from = &"title"
	G.menu = row
	_press(&"use")
	G.update_options()
	_release()
	if not G.reset_armed or Meta.meta["embers"] != 777:
		fail("RESET GAME did not ask first")
	G.menu = row
	_press(&"use")
	G.update_options()
	_release()
	for k in Meta.META_START:
		if Meta.meta.get(k) != Meta.META_START[k]:
			fail("RESET GAME: %s is %s (want %s)" % [k, str(Meta.meta.get(k)), str(Meta.META_START[k])])
	if G.state != &"title":
		fail("RESET GAME did not go back to the title")
	print("[stage48] RESET GAME: from the title's options, the second press")
