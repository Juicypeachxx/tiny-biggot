extends Node
## Elite traits (6.6, scripts/combat/elite_traits.gd). Run:
##   godot --headless --path . res://tests/traits_test.tscn -- --no-save
##   1. Elites roll one trait (two from the seventh floor); plain foes, minis and champions none.
##   2. SWIFT is faster; PLATED wears a plate of half its health; SPLITTING leaves two smaller
##      copies; VOLATILE leaves a ring of shots; MENDING heals only when left alone.
##   3. The names fit the pixel font under a foe.
## Prints "traits test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL traits: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(66)
	_room(2)
	var p := G.player
	var plain := Combat.spawn_enemy("skeleton", p.x, p.y - 60, false, true)
	if not plain.traits.is_empty():
		fail("a plain foe rolled %s" % [plain.traits])
	for k in 30:
		var e := Combat.spawn_enemy("skeleton", p.x, p.y - 60, true, true)
		if e.traits.size() != 1:
			fail("an elite on floor 3 has %d traits" % e.traits.size())
			break
	_room(7)
	var e2 := Combat.spawn_enemy("skeleton", G.player.x, G.player.y - 60, true, true)
	if e2.traits.size() != 2 or e2.traits[0] == e2.traits[1]:
		fail("an elite on floor 8 has %s, not two traits" % [e2.traits])
	for t in EliteTraits.ALL:
		_one(t)
	for t in EliteTraits.ALL:
		for ch in t.to_upper():
			if Gfx.glyph_index(ch.unicode_at(0)) < 0:
				fail("the pixel font has no %s (in %s)" % [ch, t])
	print("traits test: PASSED" if fails == 0 else "traits test: %d FAILED" % fails)
	get_tree().quit()

func _room(f: int) -> void:
	G.hero_index = 0
	G.new_run()
	G.god = true
	G.floor_index = f
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.locked = true
	G.enemies.clear()

func _elite(t: String) -> Enemy:
	_room(2)
	var p := G.player
	var e := Combat.spawn_enemy("skeleton", p.x + 60, p.y - 60, false, true)
	e.elite = true
	e.traits = [t]
	return e

func _one(t: String) -> void:
	var e := _elite(t)
	match t:
		"swift":
			var plain := Combat.spawn_enemy("skeleton", e.x, e.y, false, true)
			var f := Combat.spawn_enemy("skeleton", e.x, e.y, true, true)
			while not f.traits.has("swift"):
				G.enemies.erase(f)
				f = Combat.spawn_enemy("skeleton", e.x, e.y, true, true)
			if f.speed < plain.speed * 1.3:
				fail("SWIFT is not faster (%.0f vs %.0f)" % [f.speed, plain.speed])
		"plated":
			if absf(Armor.plate(e) - e.max_hp * 0.5) > 0.1 or Armor.shown(e) <= 0:
				fail("PLATED wears no plate of half its health")
			Combat.damage_enemy(e, Armor.plate(e) * 1.3 + 1.0, { "no_crit": true, "no_mult": true })
			if e.stun_t <= 0:
				fail("breaking a PLATED elite's plate does not stun it")
		"splitting":
			var n := G.enemies.size()
			Combat.damage_enemy(e, e.hp * 3.0 + 1.0, { "no_crit": true, "no_mult": true })
			var kids := G.enemies.filter(func(o): return o.hp > 0 and o != e)
			if G.enemies.size() - n < 2 or kids.size() != 2 or absf(kids[0].max_hp - e.max_hp / 3.0) > 0.1 or kids[0].elite:
				fail("SPLITTING did not leave two smaller plain copies (%d)" % kids.size())
		"volatile":
			var n := EBullets.n
			Combat.damage_enemy(e, e.hp * 3.0 + 1.0, { "no_crit": true, "no_mult": true })
			if EBullets.n < n + 10:
				fail("VOLATILE left no ring of shots")
		"mending":
			e.stun_t = 99.0   # it stands still
			Combat.damage_enemy(e, e.max_hp * 0.5, { "no_crit": true, "no_mult": true })
			var h := e.hp
			_play(60)
			if e.hp > h + 0.5:
				fail("MENDING healed within 1 s of a blow")
			_play(120)
			if e.hp < h + e.max_hp * 0.05:
				fail("MENDING did not heal when left alone (%.0f -> %.0f)" % [h, e.hp])

func _play(n: int) -> void:
	Meta.opts["autofire"] = false
	for i in n:
		G.player.hp = G.player.max_hp
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
