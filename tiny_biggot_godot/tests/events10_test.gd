extends Node
## 10.2 New events (event_rooms.gd EVENTS_10). Run:
##   godot --headless --path . res://tests/events10_test.tscn -- --no-save
## Each one set up and played: the frog gives something, a glyph blesses and quiets the others, the
## pawnbroker buys a spare and sells a box, the cups shuffle and pay or not, the gong's three waves.
## Prints "events10 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL events10: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(102)
	G.hero_index = 0
	G.new_run()
	G.god = true
	var p := G.player
	if not "frog" in G.mystery_events():
		fail("the new events are not among the mystery rooms")
	# Frog.
	_event("frog")
	var before := [p.relics.size(), p.luck, p.speed]
	G.interact(_obj("e_frog"))
	if [p.relics.size(), p.luck, p.speed] == before:
		fail("the frog's kiss did nothing")
	# Ritual.
	_event("ritual")
	var good0 := p.al_good
	var gl: Array = G.room.objects.filter(func(o): return o["kind"] == "e_glyph" and o["sign"] == "sun")
	G.interact(gl[0])
	if p.al_good != good0 + 2 or not G.room.objects.filter(func(o): return o["kind"] == "e_glyph").all(func(o): return o.get("used", false)):
		fail("the sun glyph: GOOD %d (want %d), or the others still lit" % [p.al_good, good0 + 2])
	# Pawn.
	_event("pawn")
	p.backpack.append(Weapons.random_weapon("rare", p.weapon))
	var g0 := p.gold
	G.interact(_obj("e_pawn"))
	if not p.backpack.filter(func(x): return x != null).is_empty() or p.gold <= g0:
		fail("the pawnbroker did not buy the spare (gold %d -> %d)" % [g0, p.gold])
	p.gold = 500
	var items0 := G.room.objects.filter(func(o): return o["kind"] == "item").size()
	G.interact(_obj("e_pawn"))
	if G.room.objects.filter(func(o): return o["kind"] == "item").size() != items0 + 1:
		fail("the sealed box gave nothing")
	# Cups.
	_event("cups")
	p.gold = 500
	var h := _obj("e_hustler")
	G.interact(h)
	_play(600)
	if h["state"] != "pick":
		fail("the cups did not reach the pick (state %s)" % h["state"])
	else:
		var win := -1
		for i in 3:
			if h["order"][i] == h["ball"]:
				win = i
		var gold0 := p.gold
		var cup: Dictionary = G.room.objects.filter(func(o): return o["kind"] == "e_cup" and o["i"] == win)[0]
		G.interact(cup)
		if p.gold != gold0 + h["bet"] * 3:
			fail("finding the ball paid %d, want %d" % [p.gold - gold0, h["bet"] * 3])
	# Lightning round.
	_event("lightning")
	var gong := _obj("e_gong")
	G.interact(gong)
	for k in 200:
		_play(10)
		for e in G.enemies.duplicate():
			if e.hp > 0 and e.spawn_t <= 0:
				Combat.damage_enemy(e, (e.hp + Armor.shown(e)) * 2.0 + 1.0, { "no_crit": true, "no_mult": true, "silent": true })
		if gong.get("done", false):
			break
	if not gong.get("done", false) or G.locked or not G.room.objects.any(func(o): return o["kind"] == "ichest"):
		fail("the lightning round did not end with a chest (done %s, locked %s)" % [gong.get("done", false), G.locked])
	print("events10 test: PASSED" if fails == 0 else "events10 test: %d FAILED" % fails)
	get_tree().quit()

func _event(ev: String) -> void:
	G.enemies.clear()
	G.locked = false
	G.enter_room(World.make_room(G.floor_d, "mystery", "", "s", { "event": ev, "no_secret": true }))

func _obj(kind: String) -> Dictionary:
	for o in G.room.objects:
		if o["kind"] == kind:
			return o
	fail("no %s in the room" % kind)
	return {}

func _play(n: int) -> void:
	for i in n:
		G.player.hp = G.player.max_hp
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}
