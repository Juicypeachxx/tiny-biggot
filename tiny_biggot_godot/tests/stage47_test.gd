extends Node
## Stage 47 (his list of another game's core gameplay, 10 Oct; GAMEPLAY_PLAN.md). Run:
##   godot --headless --path . res://tests/stage47_test.tscn -- --no-save
## THE GOURD (gourd.gd): full at the start; HEAL drinks a sip before any potion and only with a
## heart to heal; it fills again at the floor's rest stop (once a floor) and when a guardian falls;
## WAYFARER'S CORK and HONEY STOPPER. SHATTER (shatter.gd): stacks to 5, +5% damage taken a stack
## (CRACKED GEODE twice), gone 4 s after the last; blunt weapons' blows, bombs and the SPLITTING
## WEDGE bring it; a shattered foe really takes more. Classic has neither. The reworked title menu
## and hero select (47.3, 47.4): every row and every hero can be tapped, nothing overlaps, each
## selects its own, and the heroes by the title's fire are yours.
## Prints "stage47 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage47: ", msg)

func _start(hero: int = 0) -> Player:
	G.hero_index = hero
	G.new_run()
	G.floor_index = 2
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

func _foe(p: Player, type: String = "slime", dx: float = 30.0) -> Enemy:
	var e := Combat.spawn_enemy(type, p.x + dx, p.y, false, true)
	e.max_hp = 1e7
	e.hp = 1e7
	e.speed = 0.0
	return e

func _heal_button(p: Player) -> void:
	Keys._trig[&"heal"] = true
	p.try_heal()
	Keys._trig[&"heal"] = false

func _relic(p: Player, id: String) -> void:
	G.add_relic(p, Relics.by_id(id))

func _ready() -> void:
	# ---- THE GOURD.
	var p := _start()
	if p.gourd != 1 or Gourd.max_sips(p) != 1:
		fail("a new run's gourd: %d of %d sips (want 1 of 1)" % [p.gourd, Gourd.max_sips(p)])
	p.max_hp = maxi(p.max_hp, 10)
	p.hp = 2
	var pots := p.potions
	_heal_button(p)
	if p.hp != 2 + Gourd.SIP_HEAL or p.gourd != 0 or p.potions != pots:
		fail("HEAL with a full gourd: health %d (want %d), gourd %d, potions %d (were %d)" % [p.hp, 2 + Gourd.SIP_HEAL, p.gourd, p.potions, pots])
	p.potions = maxi(1, p.potions)
	pots = p.potions
	var hp0 := p.hp
	_heal_button(p)
	if p.potions != pots - 1 or p.hp <= hp0:
		fail("HEAL with the gourd dry: a potion was not drunk (potions %d, were %d)" % [p.potions, pots])
	Gourd.fill(p)
	p.hp = p.max_hp
	_heal_button(p)
	if p.gourd != 1:
		fail("HEAL at full health drank the gourd")
	# The rest stop fills it, once a floor; a guardian's fall fills it.
	p.gourd = 0
	G.enter_room(World.make_room(G.floor_d, "rest", "", "s", {}))
	if p.gourd != 1:
		fail("the rest stop did not fill the gourd")
	p.gourd = 0
	G.enter_room(World.make_room(G.floor_d, "rest", "", "s", {}))
	if p.gourd != 0:
		fail("a second rest stop on the same floor filled the gourd again")
	p = _start()
	p.gourd = 0
	var boss_key: String = GameData.BOSSES.keys()[0]
	G.enter_room(World.make_room(G.floor_d, "boss", "", "s", { "no_secret": true }))
	G.enemies.clear()
	var b := Combat.spawn_boss(boss_key, true)
	b.hp = 0
	G.on_boss_dead(b)
	if p.gourd != Gourd.max_sips(p):
		fail("a guardian's fall did not fill the gourd (%d of %d)" % [p.gourd, Gourd.max_sips(p)])
	# The relics.
	p = _start()
	_relic(p, "wayfarercork")
	if Gourd.max_sips(p) != 2 or p.gourd != 2:
		fail("WAYFARER'S CORK: %d of %d sips (want 2 of 2)" % [p.gourd, Gourd.max_sips(p)])
	_relic(p, "honeystopper")
	if Gourd.heal_amount(p) != Gourd.SIP_HEAL + 2:
		fail("HONEY STOPPER: a sip heals %d (want %d)" % [Gourd.heal_amount(p), Gourd.SIP_HEAL + 2])
	print("[stage47] THE GOURD: a sip before a potion, filled at the rest stop and by a guardian, its relics")

	# ---- SHATTER.
	p = _start()
	p.crit = 0.0
	var e := _foe(p)
	Statuses.apply(e, "shatter", 1, 0.0)
	if e.shatter != 1 or absf(Statuses.dmg_mult(e) - 1.05) > 1e-6:
		fail("one stack: %d, x%.3f damage taken (want 1, x1.05)" % [e.shatter, Statuses.dmg_mult(e)])
	for i in 9:
		Statuses.apply(e, "shatter", 1, 0.0)
	if e.shatter != Shatter.MAX or absf(Statuses.dmg_mult(e) - 1.25) > 1e-6:
		fail("ten stacks: %d, x%.3f (want 5, x1.25)" % [e.shatter, Statuses.dmg_mult(e)])
	var clean := _foe(p, "slime", 60.0)
	var hp_a := e.hp
	var hp_b := clean.hp
	for i in 2000:   # (every hit rolls 85..115 of 100: many, to compare)
		Combat.damage_enemy(e, 10.0, { "silent": true, "no_crit": true })
		Combat.damage_enemy(clean, 10.0, { "silent": true, "no_crit": true })
	var ratio := (hp_a - e.hp) / maxf(0.001, hp_b - clean.hp)
	if absf(ratio - 1.25) > 0.02:
		fail("a shattered foe took x%.3f of a clean one's damage (want x1.25)" % ratio)
	Statuses.tick(e, Shatter.TIME + 0.1)
	if e.shatter != 0:
		fail("shatter still %d after %.1f s" % [e.shatter, Shatter.TIME + 0.1])
	_relic(p, "crackedgeode")
	Statuses.apply(e, "shatter", 5, 0.0)
	if absf(Statuses.dmg_mult(e) - 1.5) > 1e-6:
		fail("CRACKED GEODE at 5 stacks: x%.3f (want x1.5)" % Statuses.dmg_mult(e))
	# A blunt weapon's blows shatter now and then; a blade's never.
	p = _start()
	Weapons.equip_weapon(p, Weapons.by_id("magmamaul"))
	var f2 := _foe(p)
	var hits := 0
	for i in 600:
		f2.shatter = 0
		Combat.on_hit_effects(f2, 1.0, false, p, null)
		if f2.shatter > 0:
			hits += 1
	if hits < 600 * Shatter.BLUNT * 0.5 or hits > 600 * Shatter.BLUNT * 1.6:
		fail("MAGMA MAUL: %d of 600 blows shattered (want about %d)" % [hits, int(600 * Shatter.BLUNT)])
	var blade := ""
	for w in Weapons.all():
		if not Might.blunt(w) and w["rarity"] == "common":
			blade = w["id"]
			break
	Weapons.equip_weapon(p, Weapons.by_id(blade))
	f2.shatter = 0
	for i in 300:
		Combat.on_hit_effects(f2, 1.0, false, p, null)
	if f2.shatter > 0:
		fail("%s (not blunt) shattered" % blade)
	var blunt_n := Weapons.all().filter(func(w): return Might.blunt(w)).size()
	print("[stage47] SHATTER: stacks, x1.25 at 5, gone after %.0f s; %d of 600 maul blows; %d of %d weapons are blunt" % [Shatter.TIME, hits, blunt_n, Weapons.all().size()])
	# A bomb shatters what it hits.
	p = _start()
	var f3 := _foe(p, "slime", 40.0)
	G.bombs.append({ "x": f3.x, "y": f3.y, "t": 0.0, "safe": true })
	Combat.update_bombs(TB.DT)
	if f3.shatter != Shatter.BOMB:
		fail("a bomb left %d shatter (want %d)" % [f3.shatter, Shatter.BOMB])
	# SPLITTING WEDGE: 15% of any weapon's hits (a ranged hero's, not blunt).
	p = _start(1)
	_relic(p, "splitwedge")
	var f5 := _foe(p)
	var wedge := 0
	for i in 600:
		f5.shatter = 0
		Combat.on_hit_effects(f5, 1.0, false, p, null)
		if f5.shatter > 0:
			wedge += 1
	if Might.blunt(p.weapon) or wedge < 600 * 0.15 * 0.5 or wedge > 600 * 0.15 * 1.6:
		fail("SPLITTING WEDGE: %d of 600 hits shattered (want about 90; weapon %s)" % [wedge, p.weapon["id"]])
	print("[stage47] a bomb shatters; the SPLITTING WEDGE: %d of 600 hits" % wedge)

	# ---- The title menu and the hero select (47.3, 47.4).
	_menus()

	# ---- Classic: neither.
	GameData.force_classic = true
	var c := _start()
	if c.gourd != 0 or Gourd.max_sips(c) != 0:
		fail("classic has a gourd")
	c.hp = 1
	var cp := c.potions
	_heal_button(c)
	if cp > 0 and c.potions != cp - 1:
		fail("classic HEAL did not drink a potion")
	Weapons.equip_weapon(c, Weapons.by_id("magmamaul") if Weapons._by_id.has("magmamaul") else c.weapon)
	var f4 := _foe(c)
	for i in 200:
		Combat.on_hit_effects(f4, 1.0, false, c, null)
	G.bombs.append({ "x": f4.x, "y": f4.y, "t": 0.0, "safe": true })
	Combat.update_bombs(TB.DT)
	if f4.shatter != 0:
		fail("classic shattered a foe")
	GameData.force_classic = false

	print("stage47 test: PASSED" if fails == 0 else "stage47 test: %d FAILED" % fails)
	get_tree().quit()

func _sel_zones() -> Array:
	return Taps.zones().filter(func(z): return z.has("sel"))

func _no_overlap(where: String, zs: Array) -> void:
	for a in zs.size():
		var ra: Rect2 = zs[a]["rect"]
		if ra.position.x < 0 or ra.position.y < 0 or ra.end.x > TB.SW or ra.end.y > TB.SH:
			fail("%s: zone %d off the screen: %s" % [where, a, ra])
		for b in range(a + 1, zs.size()):
			if ra.intersects(zs[b]["rect"]):
				fail("%s: zones %d and %d overlap" % [where, a, b])

func _menus() -> void:
	var saved_state: StringName = G.state
	var saved_hero := G.hero_index
	G.state = &"title"
	var items := G.title_items()
	var zs := _sel_zones()
	if zs.size() != items.size():
		fail("title: %d tap rows for %d items" % [zs.size(), items.size()])
	_no_overlap("title", zs)
	for i in zs.size():
		G.menu = -1
		zs[i]["sel"].call()
		if G.menu != i:
			fail("title: the row of %s selects %d" % [items[i], G.menu])
		if MenuView.title_dy() < 13:
			fail("title: rows %d apart (too tight)" % MenuView.title_dy())
	for h in MenuView.title_heroes():
		if not G.hero_unlocked(h):
			fail("title: %s by the fire is locked" % h["name"])
	if MenuView.title_heroes().size() > 3:
		fail("title: %d heroes by the fire" % MenuView.title_heroes().size())
	G.state = &"hero"
	var order := GameData.hero_order()
	zs = _sel_zones()
	if zs.size() != order.size():
		fail("hero select: %d tap cells for %d heroes" % [zs.size(), order.size()])
	_no_overlap("hero select", zs)
	for j in zs.size():
		zs[j]["sel"].call()
		if G.hero_index != order[j]:
			fail("hero select: cell %d selects hero %d (want %d)" % [j, G.hero_index, order[j]])
		var r: Rect2 = zs[j]["rect"]
		if r.end.y > MenuView.CARD_Y:
			fail("hero select: cell %d runs into the hero's card" % j)
	print("[stage47] title: %d rows %d apart; hero select: %d heroes in a grid, each tap picks its own" % [items.size(), MenuView.title_dy(), order.size()])
	G.hero_index = saved_hero
	G.state = saved_state
