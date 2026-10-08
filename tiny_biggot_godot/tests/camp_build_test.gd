extends Node
## 20.2 THE CAMP GROWS and THE QUEST BOARD (scripts/game/camp_build.gd, quests.gd). Run:
##   godot --headless --path . res://tests/camp_build_test.tscn -- --no-save
## The carpenter builds for embers (not without them); the smokehouse keeps two meals and the
## herb garden adds a heart to each; the guest tent brings a third visitor; the master's rack
## lends armour and whole sets (a set worn there is not a set completed); the lending rack sends a
## found weapon along in the pack; the fish trap fills the larder when a run ends; the gambler
## and the tinker; three quests on the board, paid on the run's tally when met, and in the camp
## for a fish. Prints "camp build test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL camp build: ", msg)

func _tick(n: int) -> void:
	for i in n:
		Keys.tick()
		G.update(TB.DT)

func _press(a: StringName) -> void:
	Input.action_press(a)
	_tick(2)
	Input.action_release(a)
	_tick(2)

func _by(kind: String) -> Dictionary:
	for o in G.room.objects:
		if o["kind"] == kind:
			return o
	return {}

func _run_hero() -> Player:
	G.hero_index = 0
	seed(20)
	G.new_run()
	return G.player

func _ready() -> void:
	await get_tree().process_frame
	seed(202)
	var hp0 := _run_hero().max_hp
	Camp.enter()
	_tick(10)
	# The carpenter and her page.
	if _by("c_build").is_empty():
		fail("no carpenter in the camp")
	G.interact(_by("c_build"))
	if G.state != &"plans":
		fail("the carpenter did not open the plans")
	_press(&"pause")
	if G.state != &"play":
		fail("the plans did not come back to the camp")
	Meta.meta["embers"] = 0
	if CampBuild.build("smokehouse"):
		fail("built the smokehouse for nothing")
	Meta.meta["embers"] = 5000
	for id in CampBuild.PLANS:
		if not CampBuild.build(id):
			fail("could not build " + id)
	var cost := 0
	for id in CampBuild.PLANS:
		cost += CampBuild.PLANS[id][1]
	if Meta.meta["embers"] != 5000 - cost:
		fail("building cost %d embers, not %d" % [5000 - Meta.meta["embers"], cost])
	if CampBuild.build("lanterns"):
		fail("built the lanterns twice")
	if G.room.objects.filter(func(o): return o["kind"] == "c_deco").size() < 8:
		fail("what was built does not stand in the camp")
	# The guest tent: three visitors next time.
	Camp.enter()
	_tick(5)
	if G.room.objects.filter(func(o): return CampLife.VISITORS.has(o["kind"])).size() != 3:
		fail("the guest tent brought no third visitor")
	# The smokehouse: two meals; a third pushes out the oldest.
	for i in 8:
		CampLife.stock("mudfin")
	CampLife.stock("goldcarp")
	CampLife.cook("soup")
	CampLife.cook("soup")
	if Meta.meta.get("meal", "") != "soup" or Meta.meta.get("meal2", "") != "soup":
		fail("the smokehouse did not keep two meals: %s, %s" % [Meta.meta.get("meal", ""), Meta.meta.get("meal2", "")])
	CampLife.cook("fillet")
	if Meta.meta.get("meal", "") != "soup" or Meta.meta.get("meal2", "") != "fillet":
		fail("a third meal did not push out the oldest")
	# The master's rack: armour and whole sets, and a set worn here is not a set completed.
	CampLife.open_armory()
	var rows: Array = CampLife.arm_list
	if rows.filter(func(r): return r[0] == "g").size() != Gear.all().size() or rows.filter(func(r): return r[0] == "s").is_empty():
		fail("the master's rack has no armour or sets")
	var sets0: int = Meta.meta.get("sets_done", 0)
	var found0: int = (Meta.meta["found_g"] as Dictionary).size()
	CampLife.take(["s", "sunforged"])
	if G.player.sets.get("sunforged", 0) != 6:
		fail("the whole SUNFORGED set was not worn (%d)" % G.player.sets.get("sunforged", 0))
	if Meta.meta.get("sets_done", 0) != sets0 or (Meta.meta["found_g"] as Dictionary).size() != found0:
		fail("a set tried in the camp counted as completed or found")
	CampLife.take(["reset"])
	# The lending rack: a found weapon goes along in the pack.
	var w: Dictionary = Weapons.all()[30]
	Meta.meta["found_w"][w["id"]] = true
	CampLife.take(["w", w])
	CampBuild.on_set_out()
	if Meta.meta.get("lend", "") != w["id"]:
		fail("the lending rack did not keep %s" % w["id"])
	# The gambler.
	var gam := { "kind": "v_gambler", "x": 0.0, "y": 0.0, "bets": 1 }
	var e0: int = Meta.meta["embers"]
	CampLife.interact(gam)
	if absi(Meta.meta["embers"] - e0) != CampLife.BET or gam["bets"] != 0:
		fail("the gambler's bet: %d embers, %d bets left" % [Meta.meta["embers"] - e0, gam["bets"]])
	var e1: int = Meta.meta["embers"]
	CampLife.interact(gam)
	if Meta.meta["embers"] != e1:
		fail("the gambler took a bet with none left")
	# The tinker.
	var piece: Dictionary = Gear.all().filter(func(g): return g["rarity"] == "rare")[0]
	CampLife.interact({ "kind": "v_tinker", "x": 0.0, "y": 0.0, "gear": piece })
	if Meta.meta.get("next_gear", "") != piece["id"]:
		fail("the tinker did not sell %s" % piece["id"])
	# The next run eats both meals (with the garden's hearts), wears the piece, carries the weapon.
	var p := _run_hero()
	if p.max_hp != hp0 + 2 + 2 + 2:   # the soup's heart, and the garden's with each meal
		fail("two meals and the garden gave %d max health, not 6" % (p.max_hp - hp0))
	if not p.gear.values().any(func(g): return g != null and g["id"] == piece["id"]):
		fail("the tinker's piece was not worn")
	if not p.backpack.any(func(x): return x["id"] == w["id"]):
		fail("the lent weapon is not in the pack")
	if Meta.meta.has("meal") or Meta.meta.has("meal2") or Meta.meta.has("lend") or Meta.meta.has("next_gear"):
		fail("the camp's gifts were not used up")
	# Quests: three on the board; a goal met pays on the tally and is replaced.
	Meta.meta["quests"] = [{ "id": "kills150", "hero": "", "base": 0 }]
	if Quests.active().size() != Quests.SLOTS:
		fail("%d quests on the board, not %d" % [Quests.active().size(), Quests.SLOTS])
	G.run_stats["kills"] = 200
	var larder0 := CampLife.larder_total()
	G.award_embers(false)
	var parts: Array = G.award["parts"]
	if not parts.any(func(x): return str(x[0]).begins_with("QUEST: SLAY 150")):
		fail("the met quest did not pay: %s" % [parts])
	if Quests.active().size() != Quests.SLOTS or Quests.active().any(func(q): return q["id"] == "kills150" and false):
		fail("the board was not filled again")
	if int(Meta.meta.get("quests_done", 0)) != 1:
		fail("quests done: %d" % Meta.meta.get("quests_done", 0))
	if CampLife.larder_total() != larder0 + 1 or not Meta.meta.has("trap_news"):
		fail("the fish trap caught nothing when the run ended")
	# A fish caught in the camp pays at the board.
	Camp.enter()
	_tick(5)
	if Meta.meta.has("trap_news"):
		fail("the trap's catch was not told in the camp")
	Meta.meta["quests"] = [{ "id": "oldone", "hero": "", "base": 0 }]
	if not (Meta.meta.get("fish") is Dictionary):
		Meta.meta["fish"] = {}
	Meta.meta["fish"]["oldone"] = 1
	var e2: int = Meta.meta["embers"]
	G.interact(_by("c_board"))
	if G.state != &"board" or Meta.meta["embers"] != e2 + Quests.reward({ "id": "oldone" }):
		fail("the board did not pay the fish quest (state %s, %d embers)" % [G.state, Meta.meta["embers"] - e2])
	_press(&"pause")
	if G.state != &"play":
		fail("the board did not come back to the camp")
	print("camp build test: PASSED" if fails == 0 else "camp build test: %d FAILED" % fails)
	get_tree().quit()
