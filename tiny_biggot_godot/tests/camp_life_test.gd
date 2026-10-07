extends Node
## 19.2 More life in THE CAMP (scripts/game/camp_life.gd). Run:
##   godot --headless --path . res://tests/camp_life_test.tscn -- --no-save
## Two visitors and the training dummies are there; nothing hurts in the camp; the cook turns the
## larder's fish into a meal that the next run eats (not the daily trial); the bard's song and the
## peddler's relic reach the next run; the fishmonger buys only spare fish; the cat follows and
## stays; the training rack hands over any weapon or relic without marking it found, and puts
## everything back. Prints "camp life test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL camp life: ", msg)

func _tick(n: int) -> void:
	for i in n:
		Keys.tick()
		G.update(TB.DT)

func _by(kind: String) -> Dictionary:
	for o in G.room.objects:
		if o["kind"] == kind:
			return o
	return {}

func _press(a: StringName) -> void:
	Input.action_press(a)
	_tick(2)
	Input.action_release(a)
	_tick(2)

## A run's hero as new_run makes it (hero 0), with the camp's gifts applied or not.
func _run_hero() -> Player:
	G.hero_index = 0
	seed(19)
	G.new_run()
	return G.player

func _ready() -> void:
	await get_tree().process_frame
	seed(192)
	var base := _run_hero()
	var hp0 := base.max_hp
	var speed0 := base.speed
	var relics0 := base.relics.size()
	Camp.enter()
	_tick(20)
	# Visitors, the stray, the dummies.
	var vis := G.room.objects.filter(func(o): return CampLife.VISITORS.has(o["kind"]))
	if vis.size() != 2:
		fail("%d visitors, not 2" % vis.size())
	if G.enemies.filter(func(e): return e.type == "dummy").size() != 3:
		fail("the training ground has no 3 dummies")
	var php := G.player.hp
	Combat.hurt_player(2, "a test")
	if G.player.hp != php:
		fail("the camp hurt the hero")
	# The cook: the page, then a meal.
	G.interact(_by("c_cook"))
	if G.state != &"kitchen":
		fail("the cook did not open the kitchen")
	_press(&"pause")
	if G.state != &"play":
		fail("the kitchen did not come back to the camp")
	if CampLife.cook("soup"):
		fail("cooked fish soup with an empty larder")
	CampLife.stock("mudfin")
	CampLife.stock("bonecarp")
	CampLife.stock("oldboot")
	if not CampLife.cook("soup") or Meta.meta.get("meal", "") != "soup":
		fail("fish soup did not cook")
	if CampLife.larder().get("mudfin", 0) != 0 or CampLife.larder().get("oldboot", 0) != 1:
		fail("the soup took the wrong fish: %s" % [CampLife.larder()])
	# The bard.
	var bard := { "kind": "v_bard", "x": 0.0, "y": 0.0 }
	CampLife.interact(bard)
	if not Meta.meta.get("song", false):
		fail("the bard's song was not kept")
	# The peddler: a relic for embers.
	var pd := { "kind": "v_peddler", "x": 0.0, "y": 0.0, "relic": Relics.all()[3] }
	Meta.meta["embers"] = 0
	CampLife.interact(pd)
	if Meta.meta.has("next_relic"):
		fail("the peddler sold a relic for nothing")
	Meta.meta["embers"] = 500
	CampLife.interact(pd)
	if Meta.meta.get("next_relic", "") != Relics.all()[3]["id"] or Meta.meta["embers"] >= 500:
		fail("the peddler did not sell the relic")
	# The fishmonger: only what is past 3 of a kind.
	for i in 5:
		CampLife.stock("glimmer")
	var e0: int = Meta.meta["embers"]
	CampLife.interact({ "kind": "v_monger", "x": 0.0, "y": 0.0 })
	if CampLife.larder().get("glimmer", 0) != 3 or Meta.meta["embers"] != e0 + 4:
		fail("the fishmonger: %d glimmer left, %d embers paid" % [CampLife.larder().get("glimmer", 0), Meta.meta["embers"] - e0])
	# The stray follows, then stays.
	var cat := { "kind": "v_cat", "x": 236.0, "y": 166.0, "home": Vector2(236, 166), "follow_t": 0.0, "face": 1 }
	G.room.objects.append(cat)
	for i in CampLife.CAT_STAYS:
		CampLife.interact(cat)
	if int(Meta.meta.get("cat_pets", 0)) != CampLife.CAT_STAYS or not cat.get("used", false):
		fail("the cat was not petted / does not follow")
	G.player.x = 100.0
	G.player.y = 200.0
	_tick(120)
	if TB.dist_xy(cat["x"], cat["y"], G.player.x, G.player.y) > 30.0:
		fail("the cat did not follow the hero")
	_tick(600)
	if cat.get("used", false):
		fail("the cat never settled down again")
	# The training rack.
	G.interact(_by("c_rack"))
	if G.state != &"armory":
		fail("the rack did not open the training ground")
	var w: Dictionary = Weapons.all()[40]
	var fw: bool = Meta.meta["found_w"].has(w["id"])
	CampLife.take(["w", w])
	if G.player.weapon["id"] != w["id"] or Meta.meta["found_w"].has(w["id"]) != fw:
		fail("the rack did not hand over %s (or marked it found)" % w["id"])
	var r: Dictionary = Relics.all()[30]
	CampLife.take(["r", r])
	if G.player.relics.size() != 1 or Meta.meta["found"].has(r["id"]):
		fail("the rack did not hand over the relic (or marked it found)")
	CampLife.take(["reset"])
	if not G.player.relics.is_empty() or G.player.weapon["id"] != Weapons.HERO_WEAPON[GameData.heroes()[G.hero_index]["id"]]:
		fail("PUT EVERYTHING BACK did not")
	if G.state != &"play":
		fail("the rack did not come back to the camp")
	# The daily trial leaves the camp's gifts for the next ordinary run.
	Daily.start(20261007)
	if not Meta.meta.has("meal") or not Meta.meta.has("song"):
		fail("the daily trial ate the meal or the song")
	Daily.on_end(false, [])
	# The next run eats them.
	var p := _run_hero()
	if p.max_hp != hp0 + 2:
		fail("the fish soup gave %d max health, not 2" % (p.max_hp - hp0))
	if absf(p.speed - speed0 * 1.1) > 0.01:
		fail("the bard's song: speed %.1f, not %.1f" % [p.speed, speed0 * 1.1])
	if p.relics.size() != relics0 + 1 or not p.relics.any(func(x): return x["id"] == Relics.all()[3]["id"]):
		fail("the peddler's relic did not wait at the start")
	if Meta.meta.has("meal") or Meta.meta.has("song") or Meta.meta.has("next_relic"):
		fail("the camp's gifts were not used up")
	var p2 := _run_hero()
	if p2.max_hp != hp0:
		fail("the meal lasted into a second run")
	print("camp life test: PASSED" if fails == 0 else "camp life test: %d FAILED" % fails)
	get_tree().quit()
