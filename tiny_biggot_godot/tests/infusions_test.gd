extends Node
## Stage 44 INFUSIONS (his pictures, 10 Oct; scripts/game/infusions.gd). Run:
##   godot --headless --path . res://tests/infusions_test.tscn -- --no-save
## The fourteen infusions: each a belt item with its picture and a text the font can draw; used from
## the belt, it puts its element on the weapon; weapon hits then deal that element's damage and
## bring its ailment; holy hits the unholy twice as hard; saps wear off after 10 rooms, spices and
## ambers stay; the same one again stacks; no more than 5 at once; PIXIE SAP turns into a sap;
## ENDLESS INFUSION keeps them and SLOW TIME stretches them; chests and the shop stall give them;
## a weapon's own shots carry them in a live fight; classic has none.
## Prints "infusions test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL infusions: ", msg)

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

func _use(p: Player, kind: String) -> void:
	p.belt.clear()
	Consumables.take(p, kind)
	Consumables.use(p, 0)

func _ready() -> void:
	# Data: every one a belt item with a picture, a drawable text and a known element.
	for k in Infusions.KINDS:
		var d: Array = Infusions.KINDS[k]
		if not Consumables.is_kind(k):
			fail("%s is not a belt item" % k)
		if not Img.has(k):
			fail("%s has no picture" % k)
		if d[1] != "" and not Infusions.ELEMENTS.has(d[1]):
			fail("%s: unknown element %s" % [k, d[1]])
		var c := Consumables.data(k)
		for s in [c["name"], c["desc"]]:
			for ch in String(s):
				if not ch in Gfx.FONT_CHARS:
					fail("%s: '%s' is not in the font (%s)" % [k, ch, s])
					break
	if Infusions.KINDS.size() != 14:
		fail("%d infusions, not 14" % Infusions.KINDS.size())
	if not Img.has("tr_dex_temper"):
		fail("ENDLESS INFUSION has no picture")

	# From the belt onto the weapon.
	var p := _start()
	_use(p, "inf_embersap")
	if p.infusions.size() != 1 or p.infusions[0][0] != "inf_embersap" or p.infusions[0][1] != Infusions.ROOMS or not p.belt.is_empty():
		fail("EMBER SAP from the belt: %s, belt %s" % [p.infusions, p.belt])

	# Each element: its damage on a hit, and its ailment now and then.
	var ail := { "inf_embersap": "burn_t", "inf_rimesap": "chill_t", "inf_sparksap": "shock", "inf_moldsap": "poison", "inf_briarsap": "bleed_t" }
	for k in ail:
		p = _start()
		_use(p, k)
		var e := _foe(p)
		var hp0 := e.hp
		for i in 60:
			Infusions.on_hit(p, e)
		if e.hp >= hp0:
			fail("%s: 60 hits took nothing off" % k)
		if float(e.get(ail[k])) <= 0.0:
			fail("%s: 60 hits and no %s" % [k, ail[k]])
	print("[infusions] each element hurts and brings its ailment")

	# Holy: twice as hard on the unholy (the same rolls on a slime and a skeleton).
	p = _start()
	_use(p, "inf_blessdew")
	var plain := _foe(p, "slime")
	var dark := _foe(p, "skeleton", -30.0)
	seed(11)
	for i in 40:
		Infusions.on_hit(p, plain)
	seed(11)
	for i in 40:
		Infusions.on_hit(p, dark)
	var ratio := (1e7 - dark.hp) / maxf(1.0, 1e7 - plain.hp)
	if ratio < 1.8 or ratio > 2.2:
		fail("BLESSED DEW: x%.2f on a skeleton (want x2)" % ratio)
	print("[infusions] BLESSED DEW: x%.2f on a skeleton" % ratio)

	# Rooms: a sap wears off after 10, a spice stays; the same again stacks and starts over.
	p = _start()
	_use(p, "inf_rimesap")
	_use(p, "inf_viperspice")
	for i in 9:
		Infusions.on_room(p)
	_use(p, "inf_rimesap")
	var rime: Array = p.infusions[0]
	if rime[2] != 2 or rime[1] != Infusions.ROOMS:
		fail("RIME SAP again: %s (want 2 stacks, %d rooms)" % [rime, Infusions.ROOMS])
	for i in Infusions.ROOMS:
		Infusions.on_room(p)
	if p.infusions.size() != 1 or p.infusions[0][0] != "inf_viperspice":
		fail("after 10 rooms: %s (want the spice only)" % [p.infusions])

	# ENDLESS INFUSION: nothing wears off; and its 25% more.
	p = _start()
	_use(p, "inf_sparksap")
	G.take_trait(Traits.by_id("dex_temper"))
	for i in 30:
		Infusions.on_room(p)
	if p.infusions.size() != 1:
		fail("ENDLESS INFUSION: the sap wore off")
	if p.g("infuse_dmg") <= 0.0:
		fail("ENDLESS INFUSION: no more damage")

	# SLOW TIME: a room longer for every special used.
	p = _start()
	_use(p, "inf_briarsap")
	p.gf["dilation"] = 1.0
	Marvels.on_special(p)
	if p.infusions[0][1] != Infusions.ROOMS + 1:
		fail("SLOW TIME: the sap has %d rooms (want %d)" % [p.infusions[0][1], Infusions.ROOMS + 1])

	# At most 5 kinds: the oldest that wears off goes.
	p = _start()
	_use(p, "inf_cinderspice")
	for k in ["inf_embersap", "inf_rimesap", "inf_sparksap", "inf_briarsap", "inf_moldsap"]:
		_use(p, k)
	var kinds: Array = p.infusions.map(func(x): return x[0])
	if kinds.size() != Infusions.SLOTS or not kinds.has("inf_cinderspice") or kinds.has("inf_embersap"):
		fail("six kinds: %s (want 5, the spice kept, EMBER SAP out)" % [kinds])

	# PIXIE SAP: one of the saps.
	p = _start()
	_use(p, "inf_pixiesap")
	if p.infusions.size() != 1 or not Infusions.SAPS.has(p.infusions[0][0]):
		fail("PIXIE SAP became %s" % [p.infusions])

	# Chests drop them; the shop has a stall; bought, it goes in the belt (not with a full belt).
	p = _start()
	var n0 := G.pickups.size()
	Infusions.maybe(1.0, p.x, p.y)
	if G.pickups.size() != n0 + 1 or not Infusions.is_kind(G.pickups.back().kind):
		fail("a chest's infusion did not drop")
	var shop := World.make_room(G.floor_d, "shop", "", "s", { "no_secret": true })
	G.enter_room(shop)
	var stall: Dictionary = {}
	for o in G.room.objects:
		if o.get("kind", "") == "shop" and o.get("item", "") == "infusion":
			stall = o
	if stall.is_empty():
		fail("no infusion stall in the shop")
	else:
		for o in G.room.objects:   # it stands clear of every other thing in the shop
			if o != stall and o.has("x") and absf(o["x"] - stall["x"]) < 24 and absf(o["y"] - stall["y"]) < 20:
				fail("the infusion stall at %d,%d stands on a %s at %d,%d" % [stall["x"], stall["y"], o["kind"], o["x"], o["y"]])
		p.belt.clear()
		p.gold = 999
		G.interact(stall)
		if p.belt.size() != 1 or not Infusions.is_kind(p.belt[0]):
			fail("bought the stall's infusion: belt %s" % [p.belt])
	print("[infusions] chests, the shop stall")

	# A live fight: the weapon's own shots carry them (a ranged hero), 5 s.
	p = _start(1)
	Meta.opts["autofire"] = true
	_use(p, "inf_stormamber")
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
		fail("5 s of fighting with STORM AMBER: no infused hit (weapon %s)" % p.weapon["id"])
	print("[infusions] 5 s of fighting with STORM AMBER: %d infused hits" % Infusions.stats.get("hits", 0))

	# Classic: none of it.
	GameData.force_classic = true
	var c := _start()
	Infusions.infuse(c, "inf_embersap")
	if not c.infusions.is_empty():
		fail("classic took an infusion")
	GameData.force_classic = false

	print("infusions test: PASSED" if fails == 0 else "infusions test: %d FAILED" % fails)
	get_tree().quit()
