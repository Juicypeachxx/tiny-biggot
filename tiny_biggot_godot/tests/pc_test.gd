extends Node
## The Windows line: the mouse in the menus, and the full screen key (scripts/pc/mouse_menus.gd).
## Run: godot --headless --path . res://tests/pc_test.tscn -- --no-save
##   1. The title: pointing at an entry selects it; a click on CODEX opens the codex.
##   2. A level-up: pointing at the second trait selects it, a click takes it.
##   3. A chest: a click on a relic takes that relic.
##   4. A screen that waits for any button (the end screen): a click goes on. The wheel moves the
##      choice up and down.
##   5. In play the mouse does nothing to menus (it aims and fires there).
##   6. Co-op: the mouse is the keyboard player's: it works their menu, never another player's turn.
##   7. F11 does not break anything without a window (the cloud's headless run).
## Prints "pc test: PASSED" or a FAIL line per problem.

var fails := 0
var mm: MouseMenus

func fail(msg: String) -> void:
	fails += 1
	print("FAIL pc: ", msg)

## One logic tick, after the events of the last frame have arrived.
func _tick() -> void:
	await get_tree().process_frame
	Keys.tick()
	G.update(TB.DT)

func _zone_center(i: int) -> Vector2:
	var zs := Taps.zones().filter(func(z): return not z.has("act"))
	return (zs[i]["rect"] as Rect2).get_center()

func _ready() -> void:
	await get_tree().process_frame
	seed(12)
	mm = MouseMenus.new()
	add_child(mm)
	await _title()
	await _traits()
	await _chest()
	await _ends()
	await _in_play()
	await _coop()
	_full()
	print("pc test: PASSED" if fails == 0 else "pc test: %d FAILED" % fails)
	get_tree().quit()

func _title() -> void:
	G.state = &"title"
	G.menu = 0
	var items: Array = G.title_items()
	var ci := items.find("CODEX")
	MouseMenus.point(_zone_center(ci))
	if G.menu != ci:
		fail("pointing at CODEX (%d) selected %d" % [ci, G.menu])
	MouseMenus.click(_zone_center(ci), MOUSE_BUTTON_LEFT)
	for i in 3:
		await _tick()
	if G.state != &"codex":
		fail("a click on CODEX opened %s" % G.state)

func _start() -> Player:
	G.hero_index = 0
	G.new_run()
	G.god = true
	G.floor_index = 2
	G.start_floor()
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.enemies.clear()
	G.state = &"play"
	var p := G.player
	p.oath_picks = 0
	p.special_picks = 0
	return p

func _traits() -> void:
	var p := _start()
	p.pending = 1
	G.offer_traits()
	if G.state != &"traits":
		fail("no level-up to test (state %s)" % G.state)
		return
	var want: String = G.tchoice["opts"][1]["id"]
	for i in 180:   # (the starburst first: no input counts until the rows are in, keys and taps alike)
		if not TraitView.active() or TraitView.ready():
			break
		await _tick()
	MouseMenus.point(_zone_center(1))
	if G.tchoice["idx"] != 1:
		fail("pointing at the second trait selected %d" % G.tchoice["idx"])
	MouseMenus.click(_zone_center(1), MOUSE_BUTTON_LEFT)
	for i in 3:
		await _tick()
	if not p.traits.has(want):
		fail("a click on %s did not take it (traits %s, state %s)" % [want, p.traits.keys(), G.state])

func _chest() -> void:
	var p := _start()
	G.open_choice("chest", { "x": 200.0, "y": 150.0 })
	if G.state != &"choice":
		fail("no chest choice to test (state %s)" % G.state)
		return
	var want: String = G.choice["relics"][1]["id"]
	MouseMenus.click(_zone_center(1), MOUSE_BUTTON_LEFT)
	for i in 3:
		await _tick()
	if not p.relics.any(func(r): return r["id"] == want):
		fail("a click on the second relic did not take %s (state %s)" % [want, G.state])

func _ends() -> void:
	# The wheel: on the pause menu it moves the choice.
	_start()
	G.state = &"pause"
	G.menu = 0
	MouseMenus.click(Vector2(10, 10), MOUSE_BUTTON_WHEEL_DOWN)
	await _tick()
	if G.menu != 1:
		fail("the wheel down on the pause menu: entry %d (want 1)" % G.menu)
	MouseMenus.click(Vector2(10, 10), MOUSE_BUTTON_WHEEL_UP)
	await _tick()
	if G.menu != 0:
		fail("the wheel up on the pause menu: entry %d (want 0)" % G.menu)
	# The end screen waits for any button: a click goes on.
	G.state = &"dead"
	G.state_t = 5.0
	MouseMenus.click(Vector2(200, 200), MOUSE_BUTTON_LEFT)
	for i in 3:
		await _tick()
	if G.state == &"dead":
		fail("a click on the end screen did not go on")

func _in_play() -> void:
	_start()
	if MouseMenus.active():
		fail("the mouse would work menus in play")

func _coop() -> void:
	# Two players: P1 a controller (a test bot), P2 the keyboard and mouse.
	Keys.clear_pads()
	var order := GameData.hero_order()
	Coop.want = [order[0], order[1]]
	Coop.pads = [Keys.add_pad("bot"), Keys.add_pad("kbm")]
	Coop.bots = [false, false]
	G.hero_index = order[0]
	G.new_run()
	G.god = true
	G.state = &"play"
	# P1's level-up: the mouse leaves it alone.
	G.player.pending = 1
	G.player.oath_picks = 0
	G.player.special_picks = 0
	G.offer_traits()
	if G.state != &"traits":
		fail("co-op: no level-up for P1 (state %s)" % G.state)
	elif MouseMenus.active():
		fail("co-op: the mouse would work P1's (a controller's) level-up")
	# The keyboard player's turn: the mouse works it, as theirs.
	Coop.turn = 1
	Keys.tick()
	if not MouseMenus.active():
		fail("co-op: the mouse does not work the keyboard player's menu")
	MouseMenus._acting = true
	var latched := MouseMenus.latch(&"use")
	MouseMenus._acting = false
	if not latched or not Keys.pads[Coop.pads[1]]["latched"].get(&"use", false):
		fail("co-op: a click did not go to the keyboard player's pad")
	Keys.pads[Coop.pads[1]]["latched"][&"use"] = false
	Coop.turn = 0
	Keys.clear_pads()
	Coop.want = []
	Coop.pads = [-1]
	Coop.bots = [false]

func _full() -> void:
	var was: bool = Meta.opts.get("fullscreen", false)
	MouseMenus.toggle_full()   # headless: no window to change, but nothing may break
	Meta.opts["fullscreen"] = was
