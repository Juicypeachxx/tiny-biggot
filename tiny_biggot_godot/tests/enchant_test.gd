extends Node
## Stage 46 WEAPON ENCHANTMENTS (his pictures, 10 Oct; scripts/game/enchant.gd). Run:
##   godot --headless --path . res://tests/enchant_test.tscn -- --no-save
## The 46 enchantments: names and texts the font can draw; weapons drop with one now and then (on a
## copy: the game's own weapon stays plain; the rare ones never drop; no grand one on a common
## weapon); one at a time: a new one replaces the old, and its effects come and go with the weapon;
## each does what it says; THE ENCHANTER in the shop, THE WYRM'S BREATH, the runesmith, the back
## room and the silver branch put theirs on; a saved run keeps it; a live fight with an element one;
## classic has none.
## Prints "enchant test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL enchant: ", msg)

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

func _font(where: String, s: String) -> void:
	for ch in s:
		if not ch in Gfx.FONT_CHARS:
			fail("%s: the font has no '%s' (%s)" % [where, ch, s])
			return

## What an enchantment can change on the hero.
func _sheet(p: Player) -> Dictionary:
	var d := { "dmg": p.dmg, "rate": p.rate, "crit": p.crit, "crit_mult": p.crit_mult, "elite_mult": p.elite_mult,
		"str": p.a_str, "dex": p.a_dex, "int": p.a_int }
	for h in ["slay_dragon", "slay_fiend", "slay_boss", "lucky", "ench_top", "nocrit_dmg", "ench_burn", "ench_chill",
			"ench_shock", "ench_afflicted", "ench_armored", "ench_ready"]:
		d[h] = p.g(h)
	return d

func _near(a: float, b: float) -> bool:
	return absf(a - b) < 1e-6

func _event(p: Player, ev: String) -> void:
	G.enter_room(World.make_room(G.floor_d, "mystery", "", "s", { "event": ev }))
	G.enemies.clear()
	G.state = &"play"

func _one(kind: String) -> Dictionary:
	for o in G.room.objects:
		if o.get("kind", "") == kind:
			return o
	return {}

func _clear_of_others(o: Dictionary, what: String) -> void:
	for b in G.room.objects:
		if b != o and b.has("x") and absf(b["x"] - o["x"]) < 24 and absf(b["y"] - o["y"]) < 20:
			fail("%s at %d,%d stands on a %s at %d,%d" % [what, o["x"], o["y"], b["kind"], b["x"], b["y"]])

func _ready() -> void:
	var saved_meta: Dictionary = Meta.meta.duplicate(true)
	# ---- The 46: names, texts, groups.
	if Enchant.KINDS.size() != 46:
		fail("%d enchantments (want 46)" % Enchant.KINDS.size())
	var names := {}
	for id in Enchant.KINDS:
		var k: Array = Enchant.KINDS[id]
		if not Enchant.GROUP_COL.has(k[1]):
			fail("%s: no group %s" % [id, k[1]])
		if names.has(k[0]):
			fail("%s: the name %s twice" % [id, k[0]])
		names[k[0]] = true
		_font(id, k[0])
		_font(id, k[2])
		_font(id, Enchant.what({ "ench": id }))
		if k[4].has("el") and not Infusions.ELEMENTS.has(k[4]["el"][0]):
			fail("%s: no element %s" % [id, k[4]["el"][0]])
		if k[4].has("needs") and not Infusions.ELEMENTS.has(k[4]["needs"]):
			fail("%s needs an element there is not: %s" % [id, k[4]["needs"]])
	for c in Enchant.CONTRABAND:
		_font("contraband", c[0])
	for b in Enchant.BREATHS:
		if not Enchant.KINDS.has(Enchant.BREATHS[b][1]):
			fail("the %s breath gives %s, which is not one" % [b, Enchant.BREATHS[b][1]])
	for t in [Enchant.DRAGONS, Enchant.FIENDS]:
		for id in t:
			if not GameData.ENEMIES.has(id) and not GameData.BOSSES.has(id):
				fail("DRAKEBANE / FIENDBANE: no foe %s" % id)

	# ---- Drops: now and then, on a copy; never a rare one; no grand one on a common weapon.
	var p := _start()
	var got := 0
	var by_group := {}
	var draws := 3000
	for i in draws:
		var rar: String = ["common", "rare", "epic", "legend", "mythic"][i % 5]
		var w := Weapons.random_weapon(rar)
		var id := Enchant.of(w)
		if id == "":
			continue
		got += 1
		var g: String = Enchant.KINDS[id][1]
		by_group[g] = by_group.get(g, 0) + 1
		if g == "rare":
			fail("a weapon dropped with a rare one: %s" % id)
		if g == "grand" and rar == "common":
			fail("a common weapon dropped %s" % id)
		if Weapons.by_id(w["id"]).has("ench"):
			fail("the game's own %s got enchanted" % w["id"])
	var share := float(got) / draws
	if share < 0.15 or share > 0.35:
		fail("%.0f%% of weapons dropped enchanted (want about 25%%)" % (share * 100))
	print("[enchant] %d of %d weapons dropped enchanted: %s" % [got, draws, by_group])

	# ---- One at a time; its effects come and go with the weapon; each changes what it says.
	for id in Enchant.KINDS:
		p = _start()
		var plain: Dictionary = p.weapon
		var before := _sheet(p)
		Enchant.give(p, id)
		if Enchant.of(p.weapon) != id:
			fail("%s did not go on the weapon" % id)
			continue
		if not WeaponInfo.display_name(p.weapon).begins_with(Enchant.KINDS[id][0] + " "):
			fail("%s: the weapon is called %s" % [id, WeaponInfo.display_name(p.weapon)])
		if plain.has("ench"):
			fail("%s went on the game's own %s" % [id, plain["id"]])
		var after := _sheet(p)
		var fx: Array = Enchant.effects(p.weapon)
		if not fx.is_empty() and after == before:
			fail("%s changed nothing on the hero" % id)
		Weapons.equip_weapon(p, plain)
		var back := _sheet(p)
		for k in before:
			if not _near(float(back[k]), float(before[k])):
				fail("%s: %s is %s after the weapon was put away (was %s)" % [id, k, back[k], before[k]])
	p = _start()
	var d0 := p.dmg
	Enchant.give(p, "savage")
	Enchant.give(p, "godforged")
	if not _near(p.dmg, d0 * 1.3):
		fail("SAVAGE then GODFORGED: damage x%.3f (want x1.3: the new one replaces the old)" % (p.dmg / d0))
	if Enchant.of(p.weapon) != "godforged":
		fail("two enchantments: %s" % Enchant.of(p.weapon))
	print("[enchant] each comes and goes with the weapon; a new one replaces the old")

	# Grades, levels, CONTRABAND.
	p = _start()
	var plain_w: Dictionary = p.weapon
	var g0 := Attributes.scaling(plain_w)
	Enchant.give(p, "runesmithed")
	var gu := Attributes.scaling(p.weapon)
	Enchant.give(p, "dull")
	var gd := Attributes.scaling(p.weapon)
	for a in g0:
		if g0[a] == "-":
			if gu[a] != "-" or gd[a] != "-":
				fail("%s: no scaling became %s / %s" % [a, gu[a], gd[a]])
			continue
		if Attributes.GRADES.find(gu[a]) > Attributes.GRADES.find(g0[a]) or (gu[a] == g0[a] and g0[a] != Attributes.GRADES[0]):
			fail("RUNESMITHED: %s grade %s -> %s" % [a, g0[a], gu[a]])
		if Attributes.GRADES.find(gd[a]) < Attributes.GRADES.find(g0[a]) or (gd[a] == g0[a] and g0[a] != "E"):
			fail("DULL: %s grade %s -> %s" % [a, g0[a], gd[a]])
	var pl0 := WeaponInfo.plus(p.weapon)
	Enchant.give(p, "starlit")
	if WeaponInfo.plus(p.weapon) != 3 or not WeaponInfo.display_name(p.weapon).ends_with("+3"):
		fail("STARLIT: level %d, called %s" % [WeaponInfo.plus(p.weapon), WeaponInfo.display_name(p.weapon)])
	if pl0 != 0:
		fail("DULL gave levels: %d" % pl0)
	Enchant.give(p, "contraband")
	var cv: int = p.weapon.get("ench_v", -1)
	if cv < 0 or cv >= Enchant.CONTRABAND.size() or not Enchant.what(p.weapon).ends_with(Enchant.CONTRABAND[cv][0]):
		fail("CONTRABAND: pick %d, says %s" % [cv, Enchant.what(p.weapon)])

	# What they do against foes.
	p = _start()
	var slime := _foe(p)
	var wyrm := _foe(p, "bookwyrm", 50.0)
	var imp := _foe(p, "imp", 70.0)
	Enchant.give(p, "drakebane")
	if not _near(Enchant.foe_mult(p, wyrm), 2.0) or not _near(Enchant.foe_mult(p, slime), 1.0):
		fail("DRAKEBANE: x%.2f on a wyrm, x%.2f on a slime" % [Enchant.foe_mult(p, wyrm), Enchant.foe_mult(p, slime)])
	Enchant.give(p, "fiendbane")
	if not _near(Enchant.foe_mult(p, imp), 2.0) or not _near(Enchant.foe_mult(p, wyrm), 1.0):
		fail("FIENDBANE: x%.2f on an imp, x%.2f on a wyrm" % [Enchant.foe_mult(p, imp), Enchant.foe_mult(p, wyrm)])
	Enchant.give(p, "kingslayer")
	var champ := _foe(p, "slime", -40.0)
	champ.d = champ.d.duplicate()
	champ.d["mini"] = true
	if not _near(Enchant.foe_mult(p, champ), 1.2) or not _near(Enchant.foe_mult(p, slime), 1.0):
		fail("KINGSLAYER: x%.2f on a mini-boss, x%.2f on a slime" % [Enchant.foe_mult(p, champ), Enchant.foe_mult(p, slime)])
	Enchant.give(p, "cruel")
	slime.burn_t = 2.0
	if not _near(Enchant.foe_mult(p, slime), 1.1) or not _near(Enchant.foe_mult(p, wyrm), 1.0):
		fail("CRUEL: x%.2f on a burning foe, x%.2f on a well one" % [Enchant.foe_mult(p, slime), Enchant.foe_mult(p, wyrm)])
	slime.burn_t = 0.0
	Enchant.give(p, "unyielding")
	slime.guard_t = 2.0
	if not _near(Enchant.foe_mult(p, slime), 1.25) or not _near(Enchant.foe_mult(p, wyrm), 1.0):
		fail("UNYIELDING: x%.2f behind a shield, x%.2f without" % [Enchant.foe_mult(p, slime), Enchant.foe_mult(p, wyrm)])
	slime.guard_t = 0.0
	Enchant.give(p, "spellbound")
	p.special_cd = 0.0
	var ready := Enchant.foe_mult(p, slime)
	p.special_cd = 5.0
	if not _near(ready, 1.25) or not _near(Enchant.foe_mult(p, slime), 1.0):
		fail("SPELLBOUND: x%.2f with the special ready, x%.2f without" % [ready, Enchant.foe_mult(p, slime)])
	# The element ones need their element on the weapon.
	Enchant.give(p, "scalding")
	var fire0 := Enchant.has_element(p, "fire")
	var cold_burn := Enchant.burn_mult(p)
	Infusions.infuse(p, "inf_embersap")
	if not _near(cold_burn, 1.25 if fire0 else 1.0) or not _near(Enchant.burn_mult(p), 1.25):
		fail("SCALDING: burns x%.2f without fire, x%.2f with" % [cold_burn, Enchant.burn_mult(p)])
	p.infusions.clear()
	Enchant.give(p, "wyrmfrost")
	Infusions.infuse(p, "inf_rimesap")
	if not _near(Enchant.status_mult(p, "chill"), 2.0) or not _near(Enchant.status_mult(p, "shock"), 1.0):
		fail("WYRMFROST: chill x%.2f, shock x%.2f" % [Enchant.status_mult(p, "chill"), Enchant.status_mult(p, "shock")])
	p.infusions.clear()
	# HEAVY-HANDED: the top of the roll.
	var top0 := 0.0
	for i in 2000:
		top0 = maxf(top0, Might.roll(p))
	Enchant.give(p, "heavyhand")
	var top1 := 0.0
	var low1 := 9.0
	for i in 2000:
		var r := Might.roll(p)
		top1 = maxf(top1, r)
		low1 = minf(low1, r)
	if top1 < 1.3 or top0 > 1.16 or low1 < 0.85 - 1e-6:
		fail("HEAVY-HANDED: rolls up to %.2f (without: %.2f), the least %.2f" % [top1, top0, low1])
	# An element one hits with it.
	Enchant.give(p, "crackling")
	Infusions.stats["hits"] = 0
	var hp0 := slime.hp
	for i in 20:
		Infusions.on_hit(p, slime)
	if Infusions.stats.get("hits", 0) != 20 or slime.hp >= hp0:
		fail("CRACKLING: %d element hits in 20, %.1f damage" % [Infusions.stats.get("hits", 0), hp0 - slime.hp])
	print("[enchant] each does what it says")

	# ---- THE ENCHANTER in the shop.
	p = _start()
	G.enter_room(World.make_room(G.floor_d, "shop", "", "s", { "no_secret": true }))
	var table := _one("enchanter")
	if table.is_empty():
		fail("no enchanter in the shop")
	else:
		_clear_of_others(table, "the enchanter")
		p.gold = 999
		var cost := Enchant.enchanter_price()
		G.interact(table)
		if Enchant.of(p.weapon) == "" or p.gold != 999 - cost:
			fail("THE ENCHANTER: weapon %s, paid %d (price %d)" % [Enchant.of(p.weapon), 999 - p.gold, cost])
		if Enchant.enchanter_price() <= cost:
			fail("THE ENCHANTER: the second costs %d, the first %d" % [Enchant.enchanter_price(), cost])
		p.gold = 0
		var had := Enchant.of(p.weapon)
		G.interact(table)
		if Enchant.of(p.weapon) != had:
			fail("THE ENCHANTER enchanted for nothing")
	print("[enchant] THE ENCHANTER")

	# ---- THE WYRM'S BREATH: four stones, one breath, now and then charred.
	if not "breath" in EventRooms.specials():
		fail("THE WYRM'S BREATH is not a special room")
	var charred := 0
	var tries := 200
	for i in tries:
		p = _start()
		_event(p, "breath")
		var stones := G.room.objects.filter(func(o): return o.get("kind", "") == "e_breath")
		if stones.size() != 4:
			fail("THE WYRM'S BREATH: %d stones" % stones.size())
			break
		if i == 0:
			for s in stones:
				_clear_of_others(s, "a stone")
		var s: Dictionary = stones[i % 4]
		G.interact(s)
		var e := Enchant.of(p.weapon)
		if e == "charred":
			charred += 1
		elif e != Enchant.BREATHS[s["breath"]][1]:
			fail("the %s breath gave %s" % [s["breath"], e])
		if stones.any(func(o): return not o.get("used", false)):
			fail("THE WYRM'S BREATH: a second breath left")
			break
	if charred < tries * 0.1 or charred > tries * 0.32:
		fail("THE WYRM'S BREATH charred %d of %d (want about a fifth)" % [charred, tries])
	print("[enchant] THE WYRM'S BREATH: charred %d of %d" % [charred, tries])

	# ---- The runesmith, the back room, the silver branch.
	for c in [["chopshop", "e_runesmith", "runesmithed"], ["pawn", "e_contraband", "contraband"], ["frog", "e_branch", "spellbound"]]:
		p = _start()
		_event(p, c[0])
		var o := _one(c[1])
		if o.is_empty():
			fail("%s: no %s" % [c[0], c[1]])
			continue
		_clear_of_others(o, c[1])
		p.gold = 999
		var cost := Enchant.special_price(c[1])
		var pr := Enchant.prompt(o)
		for s in pr:
			_font(c[1], s)
		G.interact(o)
		if Enchant.of(p.weapon) != c[2] or p.gold != 999 - cost or not o.get("used", false):
			fail("%s: weapon %s, paid %d of %d" % [c[1], Enchant.of(p.weapon), 999 - p.gold, cost])
	print("[enchant] the runesmith, the back room, the silver branch")

	# ---- Every prompt the font can draw.
	p = _start()
	Enchant.give(p, "hallowed")
	for o in [{ "kind": "enchanter" }, { "kind": "e_breath", "breath": "storm" }, { "kind": "e_runesmith" }, { "kind": "e_contraband" }, { "kind": "e_branch" }]:
		for s in Enchant.prompt(o):
			_font(o["kind"], s)
	for l in OverlayView.item_lines(p.weapon):
		_font("item card", l[0])
	if not OverlayView.item_lines(p.weapon).any(func(l): return l[0].contains("HALLOWED: ")):
		fail("the item card does not say what HALLOWED does")

	# ---- A saved run keeps it.
	p = _start()
	Enchant.give(p, "wicked")
	var cm := p.crit_mult
	var back := Meta.save_in(Meta.save_bytes(RunSave.capture()))
	G.player = null
	if not RunSave.restore(back):
		fail("the run did not load")
	elif Enchant.of(G.player.weapon) != "wicked" or not _near(G.player.crit_mult, cm):
		fail("after loading: %s, crit x%.2f (was x%.2f)" % [Enchant.of(G.player.weapon), G.player.crit_mult, cm])
	print("[enchant] a saved run keeps it")

	# ---- A live fight: a ranged hero, CRACKLING, 5 s.
	p = _start(1)
	Meta.opts["autofire"] = true
	Enchant.give(p, "crackling")
	Infusions.stats["hits"] = 0
	for i in 4:
		_foe(p, "slime", -40.0 + i * 25.0).y = p.y - 40.0
	for i in 300:
		p.hp = p.max_hp
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}
	if Infusions.stats.get("hits", 0) <= 0:
		fail("5 s of fighting with CRACKLING: no lightning hit (weapon %s)" % p.weapon["id"])
	print("[enchant] 5 s of fighting with CRACKLING: %d lightning hits" % Infusions.stats.get("hits", 0))

	# ---- Classic: none of it.
	GameData.force_classic = true
	var c := _start()
	for i in 300:
		if Enchant.of(Weapons.random_weapon("mythic")) != "":
			fail("classic dropped an enchanted weapon")
			break
	Enchant.give(c, "godforged")
	if Enchant.of(c.weapon) != "" or "breath" in EventRooms.specials():
		fail("classic has enchantments")
	G.enter_room(World.make_room(G.floor_d, "shop", "", "s", { "no_secret": true }))
	if not _one("enchanter").is_empty():
		fail("classic has an enchanter")
	GameData.force_classic = false

	Meta.meta = saved_meta
	print("enchant test: PASSED" if fails == 0 else "enchant test: %d FAILED" % fails)
	get_tree().quit()
