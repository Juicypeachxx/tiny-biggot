extends Node
## Pets (scripts/entities/pets.gd, ROADMAP 4.5b). Run: godot --headless --path . res://tests/pets_test.tscn -- --no-save
##   1. Data: ten pets, each with a name, a kind, three level lines the font can draw, a sprite.
##   2. Each pet in a fight, the hero not firing: its own trick happens (a fetch, zaps, a fire
##      trail, rolls with bleeding, marked foes, eaten shots, a hit taken, a swoop, snips, a blast),
##      and the foes lose health to it where it fights.
##   3. Growing: level 2 after 12 foes, level 3 after 35.
##   4. Cages: in the expanded game they turn up in treasure rooms, vaults, hidden rooms and shops,
##      never in the original game; a key (or gold) opens one; opening a second swaps the pets, and
##      the old one waits in the cage at its level; Gloop takes one hit a room; Glimmer at level 3
##      opens a hollow wall it glows at.
## Prints "pets test: PASSED" or a FAIL line per problem.

var fails := 0
var notes := []

func fail(msg: String) -> void:
	fails += 1
	print("FAIL pets: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(11)
	Meta.opts["autofire"] = false
	_data()
	for id in Pets.IDS:
		_fight(id)
	_levels()
	_cages()
	_gloop()
	_glimmer_wall()
	for n in notes:
		print("[pets] ", n)
	print("pets test: PASSED" if fails == 0 else "pets test: %d FAILED" % fails)
	get_tree().quit()

func _data() -> void:
	if Pets.IDS.size() != 10 or Pets.PETS.size() != 10:
		fail("%d pets" % Pets.IDS.size())
	for id in Pets.IDS:
		var d: Dictionary = Pets.PETS[id]
		if d["lv"].size() != 3:
			fail("%s has %d level lines" % [id, d["lv"].size()])
		for s in [d["name"], d["kind"]] + d["lv"]:
			for ch in String(s):
				if not ch in Gfx.FONT_CHARS:
					fail("%s: '%s' is not in the font" % [id, ch])
		if not Img.has("pet_" + id):
			fail("missing sprite pet_" + id)
	if not Img.has("pet_cage"):
		fail("missing sprite pet_cage")

func _start(floor_i: int = 2) -> Player:
	G.hero_index = 1
	G.new_run()
	G.floor_index = floor_i
	G.start_floor()
	G.god = true
	return G.player

func _tick(n: int) -> void:
	for i in n:
		G.player.hp = G.player.max_hp
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

## A plain fight room with no waves: the test puts the foes in.
func _arena() -> void:
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	for c in range(TB.IX0, TB.IX0 + TB.IW):
		for r in range(TB.IY0, TB.IY0 + TB.IH):
			G.room.set_tile(c, r, World.T_FLOOR)
	G.locked = true

func _foes(n: int, near: float) -> Array:
	var out := []
	var p := G.player
	for i in n:
		var a := float(i) / n * TAU
		var e := Combat.spawn_enemy("skeleton", p.x + cos(a) * near, p.y - 20 + sin(a) * near * 0.6, false, true)
		e.speed = 0.0
		e.max_hp = 9999.0
		e.hp = 9999.0
		out.append(e)
	return out

func _fight(id: String) -> void:
	var p := _start()
	_arena()
	Pets.give(p, id, 1)
	p.x = 14.0 * TB.TS
	p.y = 12.0 * TB.TS
	Pets.enter_room(p)
	var foes := _foes(3, 40.0)
	var hp0 := 0.0
	for e in foes:
		hp0 += e.hp
	var seen := {}
	var zones0 := G.zones.size()
	var ok := false
	for k in 60 * 15:
		if id == "biscuit" and k == 30:
			var h := Combat.drop_pickup("heart", 4.0 * TB.TS, 5.0 * TB.TS)
			h.vx = 0.0
			h.vy = 0.0
		if id == "gulp" and k % 20 == 0:
			Combat.eshot(Pets.x + 40, Pets.y, PI, 60, "red")
		_tick(1)
		p.x = 14.0 * TB.TS
		p.y = 12.0 * TB.TS
		if id == "cindertail":
			# It leaves fire only while you walk: a loop through the foes.
			p.x += cos(k * 0.04) * 40.0
			p.y += sin(k * 0.04) * 24.0 - 20.0
		seen[Pets.st] = true
		match id:
			"biscuit": ok = ok or seen.has("carry")
			"zappy": ok = ok or not Pets.bolts.is_empty()
			"cindertail": ok = ok or G.zones.size() > zones0
			"bramble": ok = ok or (seen.has("roll") and foes.any(func(e): return e.bleed_t > 0))
			"glimmer": ok = ok or foes.any(func(e): return e.mark_t > 0 and e.mark_v >= 0.2)
			"gulp": ok = ok or Pets.count > 0
			"gloop": ok = true   # its trick is tested on its own below
			"hoots": ok = ok or seen.has("swoop")
			"snip": ok = ok or Pets.count > 0
			"kaboomba": ok = ok or seen.has("gone")
	if not ok:
		fail("%s never did its trick (states %s)" % [id, seen.keys()])
	var hp1 := 0.0
	for e in foes:
		hp1 += maxf(0.0, e.hp)
	if id in ["zappy", "bramble", "hoots", "snip", "kaboomba", "cindertail"] and hp1 >= hp0:
		fail("%s did no damage" % id)
	notes.append("%s: the foes lost %d health in 15 s (the hero not firing)" % [id, roundi(hp0 - hp1)])

func _levels() -> void:
	var p := _start()
	_arena()
	Pets.give(p, "zappy", 1)
	for i in 11:
		Pets.on_kill(Combat.spawn_enemy("skeleton", 100, 100, false, true))
	if p.pet_lv != 1:
		fail("level %d after 11 foes" % p.pet_lv)
	Pets.on_kill(Combat.spawn_enemy("skeleton", 100, 100, false, true))
	if p.pet_lv != 2:
		fail("level %d after 12 foes" % p.pet_lv)
	for i in 23:
		Pets.on_kill(Combat.spawn_enemy("skeleton", 100, 100, false, true))
	if p.pet_lv != 3:
		fail("level %d after 35 foes" % p.pet_lv)

func _cages() -> void:
	var p := _start()
	var counts := {}
	for kind in ["treasure", "vault", "secret", "shop", "combat"]:
		var n := 0
		for i in 300:
			var r := World.make_room(G.floor_d, kind, "", "s")
			G.setup_objects(r)
			for o in r.objects:
				if o["kind"] == "pet_cage":
					n += 1
		counts[kind] = n
	notes.append("cages in 300 rooms each: %s" % counts)
	for kind in ["treasure", "vault", "secret", "shop"]:
		if counts[kind] < 10:
			fail("only %d cages in 300 %s rooms" % [counts[kind], kind])
	if counts["combat"] != 0:
		fail("cages in fight rooms")
	GameData.force_classic = true
	var classic := 0
	for kind in ["treasure", "vault", "secret", "shop"]:
		for i in 200:
			var r := World.make_room(G.floor_d, kind, "", "s")
			G.setup_objects(r)
			for o in r.objects:
				if o["kind"] == "pet_cage":
					classic += 1
	GameData.force_classic = false
	if classic > 0:
		fail("%d cages in the original game" % classic)
	# Opening one, then a second.
	_arena()
	G.locked = false
	var cage := Pets.cage(p, 200, 150, "key")
	G.room.objects.append(cage)
	p.keys = 0
	G.interact(cage)
	if p.pet != "":
		fail("a cage opened without a key")
	p.keys = 1
	var first: String = cage["pet"]
	G.interact(cage)
	if p.pet != first or p.keys != 0 or not cage.get("used", false):
		fail("a key did not open the cage (pet %s, keys %d)" % [p.pet, p.keys])
	p.pet_lv = 3
	p.pet_xp = 40
	var cage2 := Pets.cage(p, 260, 150, "gold")
	G.room.objects.append(cage2)
	var second: String = cage2["pet"]
	if second == first:
		fail("a cage held the pet you already have")
	p.gold = cage2["price"]
	G.interact(cage2)
	if p.pet != second or p.gold != 0 or p.pet_lv != 1:
		fail("buying a pet: %s, gold %d, level %d" % [p.pet, p.gold, p.pet_lv])
	if cage2["pet"] != first or cage2["how"] != "free" or cage2.get("lv", 0) != 3:
		fail("the old pet does not wait in the cage at its level")
	G.interact(cage2)
	if p.pet != first or p.pet_lv != 3 or p.pet_xp != 40:
		fail("taking the old pet back: %s level %d" % [p.pet, p.pet_lv])

func _gloop() -> void:
	var p := _start()
	_arena()
	G.god = false
	Pets.give(p, "gloop", 1)
	var hp := p.hp
	p.invuln = 0.0
	Combat.hurt_player(1, "a test")
	if p.hp != hp:
		fail("gloop did not take the first hit")
	p.invuln = 0.0
	Combat.hurt_player(1, "a test")
	if p.hp != hp - 1:
		fail("gloop took a second hit in one room")
	_arena()
	p.invuln = 0.0
	hp = p.hp
	Combat.hurt_player(1, "a test")
	if p.hp != hp:
		fail("gloop did not come back in the next room")

func _glimmer_wall() -> void:
	var p := _start()
	var r := World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true })
	r.secret_dirs["e"] = true
	r.doors["e"] = true
	G.enter_room(r)
	G.room.waves_left = 0
	Pets.give(p, "glimmer", 3)
	_tick(60 * 5)
	if G.room.secret_dirs.has("e"):
		fail("glimmer at level 3 did not open the hollow wall (wall '%s')" % Pets.wall)
