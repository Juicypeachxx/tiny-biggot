extends Node
## Stage 45 THE ALIGNMENT SHOPS (his notes, 9 Oct; scripts/game/align_shops.gd). Run:
##   godot --headless --path . res://tests/alignshops_test.tscn -- --no-save
## Three shops, each open once its path's ruler has fallen (GOOD: THE AUREATE JUDGE, EVIL: THE
## CINDER KING, LAWFUL: THE MARSHAL); after a guardian one may set up by the WAYSHRINE with three
## wares that grow with its alignment, priced by your alignment; their nine relics never come from
## a chest; each relic does what it says; the stall stands clear of the shrines; classic has none.
## Prints "alignshops test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL alignshops: ", msg)

func _start() -> Player:
	G.hero_index = 0
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

func _relic(p: Player, id: String) -> void:
	G.add_relic(p, Relics.by_id(id))

func _ready() -> void:
	var saved_meta: Dictionary = Meta.meta.duplicate(true)
	# The nine relics: real rows with pictures, never in the random pool.
	var pool_ids := G.relic_pool().map(func(r): return r["id"])
	for al in AlignShops.SHOPS:
		var d: Dictionary = AlignShops.SHOPS[al]
		for id in d["relics"]:
			if not Relics._by_id.has(id) and not Relics.all().any(func(r): return r["id"] == id):
				fail("%s: no relic %s" % [al, id])
				continue
			if not Img.has(Relics.by_id(id)["sprite"]):
				fail("%s has no picture" % id)
			if id in pool_ids:
				fail("%s is in the random relic pool" % id)
		if Gear.by_id(d["gear"]).is_empty():
			fail("%s: no gear %s" % [al, d["gear"]])

	# Closed until the ruler falls.
	Meta.meta["heaven_wins"] = 0
	Meta.meta["hell_wins"] = 0
	Meta.meta["slain"] = {}
	if not AlignShops.open_ones().is_empty():
		fail("shops open with no ruler beaten: %s" % [AlignShops.open_ones()])
	var p := _start()
	var r0 := G.room.objects.size()
	for i in 20:
		AlignShops.place(G.room)
	if G.room.objects.size() != r0:
		fail("a shop set up with none open")
	Meta.meta["heaven_wins"] = 1
	Meta.meta["hell_wins"] = 1
	Meta.meta["slain"] = { "marshal": 1 }
	if AlignShops.open_ones().size() != 3:
		fail("open with every ruler beaten: %s" % [AlignShops.open_ones()])

	# A shop: its banner and three wares; owned relics are not offered; prices follow alignment.
	for al in AlignShops.SHOPS:
		p = _start()
		_relic(p, AlignShops.SHOPS[al]["relics"][0])
		var room := World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true })
		Alignments.wayshrine(room)
		AlignShops.stock(room, al)
		var wares := room.objects.filter(func(o): return o.get("kind", "") == "shop" and o.get("al", "") == al)
		var banners := room.objects.filter(func(o): return o.get("kind", "") == "alshop")
		if wares.size() != 3 or banners.size() != 1:
			fail("%s: %d wares, %d banners (want 3 and 1)" % [al, wares.size(), banners.size()])
		for w in wares:
			if w["item"] == "relic" and w["relic"]["id"] == AlignShops.SHOPS[al]["relics"][0]:
				fail("%s offers a relic already owned" % al)
		for a in room.objects:   # nothing stands on anything else
			for b in room.objects:
				if a != b and a.has("x") and b.has("x") and absf(a["x"] - b["x"]) < 24 and absf(a["y"] - b["y"]) < 16:
					fail("%s: a %s at %d,%d stands on a %s at %d,%d" % [al, a["kind"], a["x"], a["y"], b["kind"], b["x"], b["y"]])
		# Cheaper with your alignment leading, dearer with its opposite.
		var opp: String = { "good": "evil", "evil": "good", "law": "chaos" }[al]
		var w0: Dictionary = wares[0]
		Alignments.add(p, al, 3)
		var cheap := G.price(100, al)
		Alignments.add(p, al, -3)
		Alignments.add(p, opp, 3)
		var dear := G.price(100, al)
		if cheap >= dear:
			fail("%s: price %d with it, %d against it" % [al, cheap, dear])
		# Bought: the relic or the piece is yours.
		p.gold = 9999
		G.interact(w0)
		if not w0.get("gone", false):
			fail("%s: could not buy %s" % [al, w0["item"]])
	print("[alignshops] each shop: a banner, three wares, prices by alignment, bought")

	# In a real guardian's hall, after the kill: the shop stands clear of the hoard, the shrines and
	# the dropped things.
	for sd in [1, 2, 3]:
		seed(sd)
		p = _start()
		G.enter_room(World.make_room(G.floor_d, "boss", "", "s", { "no_secret": true }))
		G.state = &"play"
		for i in 600:
			G.update(TB.DT)
			if G.enemies.any(func(x): return x.is_boss()):
				break
		var bs := G.enemies.filter(func(x): return x.is_boss())
		if bs.is_empty():
			fail("seed %d: no guardian came" % sd)
			continue
		Combat.kill_enemy(bs[0], {})
		for i in 240:
			p.hp = p.max_hp
			G.update(TB.DT)
		if not G.room.objects.any(func(o): return o.get("kind", "") == "alshop"):
			AlignShops.stock(G.room, ["good", "evil", "law"][sd % 3])
		var mine := G.room.objects.filter(func(o): return o.get("kind", "") == "alshop" or o.has("al") and o.get("kind", "") == "shop")
		for a in mine:
			for b in G.room.objects:
				if a != b and b.has("x") and absf(a["x"] - b["x"]) < 24 and absf(a["y"] - b["y"]) < 16:
					fail("guardian's hall, seed %d: a %s at %d,%d stands on a %s at %d,%d" % [sd, a["kind"], a["x"], a["y"], b["kind"], b["x"], b["y"]])
	print("[alignshops] in a guardian's hall the shop stands clear")

	# What the relics do.
	p = _start()
	var pw0 := Might.power(p)
	p.al_good = 3
	_relic(p, "almshalo")
	if absf(Might.power(p) - pw0 - 12.0) > 1e-6:
		fail("ALMSGIVER'S HALO at 3 GOOD: +%.1f power (want +12)" % (Might.power(p) - pw0))
	p.al_good = 6
	_relic(p, "mercylamp")
	p.hp = 2
	AlignShops.on_room_clear(p)
	if p.hp != 4:
		fail("LAMP OF MERCY at 6 GOOD: %d health after a cleared fight (want 4)" % p.hp)
	p.al_good = 4
	_relic(p, "dawnbuckler")
	var a0 := p.armor
	AlignShops.on_floor(p)
	if p.armor != a0 + 2:
		fail("DAWN BUCKLER at 4 GOOD: +%d armor (want +2)" % (p.armor - a0))
	p = _start()
	p.al_evil = 5
	var c0 := Arcana.cursed_chance(p)
	_relic(p, "sinchalice")
	if absf(Arcana.cursed_chance(p) - c0 - 0.1) > 1e-6:
		fail("SINNER'S CHALICE at 5 EVIL: +%.3f cursed hit chance (want +0.1)" % (Arcana.cursed_chance(p) - c0))
	p.al_evil = 200
	_relic(p, "gravecoin")
	p.hp = 1
	AlignShops.on_kill(p)
	if p.hp != 2:
		fail("GRAVE COIN at 200 EVIL: a kill did not heal")
	p = _start()
	p.al_law = 5
	var r1 := Might.roll_rate(p)
	_relic(p, "ironwrit")
	if absf(Might.roll_rate(p) - r1 - 0.15) > 1e-6:
		fail("IRON WRIT at 5 LAWFUL: rolls +%.2f (want +0.15)" % (Might.roll_rate(p) - r1))
	p.al_law = 60
	p.crit = 0.0
	_relic(p, "duesledger")
	var e := Combat.spawn_enemy("slime", p.x + 30, p.y, false, true)
	e.max_hp = 1e7
	e.hp = 1e7
	var crits := 0
	for i in 20:
		if Combat.damage_enemy(e, 5.0, { "silent": true }):
			crits += 1
	if crits < 20:
		fail("LEDGER OF DUES at 60 LAWFUL (+120%% crit): %d crits in 20" % crits)
	print("[alignshops] the nine relics do what they say")

	# Classic: none of it.
	GameData.force_classic = true
	var c := _start()
	var n0 := G.room.objects.size()
	for i in 10:
		AlignShops.place(G.room)
	if G.room.objects.size() != n0:
		fail("classic set up a shop")
	GameData.force_classic = false

	Meta.meta = saved_meta
	print("alignshops test: PASSED" if fails == 0 else "alignshops test: %d FAILED" % fails)
	get_tree().quit()
