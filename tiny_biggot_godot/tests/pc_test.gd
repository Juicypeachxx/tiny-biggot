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
##   8. W2, two players on one keyboard: on the CO-OP screen ENTER joins the right half and SPACE the
##      left one; one keyboard player has every key (but the other half's SPACE or ENTER, which joins a
##      second one); two each read only their half (D and the right arrow, the left and the right
##      Shift), in the run too (W and the up arrow, ESC and BACKSPACE); the mouse is the left half's.
##      Leaving with ESC held a while: the key does not become the other half's press.
##      A keyboard player alone in a run keeps every key.
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
	await _two_keys()
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

## A key pressed or let go, as the system sends it (the Input state and every _input).
func _key(code: int, down: bool, side: int = KEY_LOCATION_UNSPECIFIED) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.location = side
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()

## A key pressed for a tick, then let go.
func _tap(code: int, side: int = KEY_LOCATION_UNSPECIFIED) -> void:
	_key(code, true, side)
	await _tick()
	_key(code, false, side)
	await _tick()

## A key held for n ticks, then let go.
func _hold(code: int, n: int) -> void:
	_key(code, true)
	for i in n:
		await _tick()
	_key(code, false)
	await _tick()

## Held keys -> {pad: down[action]} of pads l and r after a tick (no game update).
func _held(codes: Array, l: int, r: int, a: StringName, side: int = KEY_LOCATION_UNSPECIFIED) -> Array:
	for c in codes:
		_key(c, true, side)
	Keys.tick()
	var out := [Keys.pads[l]["down"].get(a, false), Keys.pads[r]["down"].get(a, false)]
	for c in codes:
		_key(c, false, side)
	Keys.tick()
	return out

func _two_keys() -> void:
	Coop.solo()
	G.fade = {}
	G.state = &"title"
	Coop.open_lobby()
	var l := Keys.mouse_pad()
	var r := -1
	for i in Keys.pads.size():
		if Keys.pads[i]["kind"] == "kb2":
			r = i
	if l < 0 or r < 0 or Keys.pads[l]["kind"] != "kbm" or not Keys.split() or Coop._free_halves() != [0, 1]:
		fail("W2: the CO-OP screen has no two keyboard halves (pads %s)" % [Keys.pads.map(func(p): return p["kind"])])
		return
	# One keyboard player: ENTER joins the right half, who then has every key but SPACE.
	await _tap(KEY_ENTER)
	if Coop.lobby.size() != 1 or Coop.lobby[0]["pad"] != r:
		fail("W2: ENTER on the CO-OP screen: %d joined (want the keyboard's right half)" % Coop.lobby.size())
		return
	if Keys.split() or Keys.mouse_pad() != r or Coop._device_name(r) != "KEYBOARD" or Coop._free_halves() != [0] \
			or Coop._key_word(r, &"use") != "ENTER" or Coop._key_word(r, &"pause") != "ESC":
		fail("W2: one keyboard player: split %s, the mouse's pad %d (want %d), %s, free %s, %s / %s" % [Keys.split(),
			Keys.mouse_pad(), r, Coop._device_name(r), Coop._free_halves(), Coop._key_word(r, &"use"), Coop._key_word(r, &"pause")])
	var order := GameData.hero_order()
	var h0: int = Coop.lobby[0]["hero"]
	await _tap(KEY_RIGHT)
	if Coop.lobby[0]["hero"] != order[(order.find(h0) + 1) % order.size()]:
		fail("W2: one keyboard player's right arrow did not choose the next hero")
	var w := _held([KEY_W], l, r, &"aim_up")
	if w[0] or not w[1]:
		fail("W2: one keyboard player's W is not their aim (left half %s, theirs %s)" % w)
	# They leave with ESC held a while: it does not become the free half's press (the screen stays).
	await _hold(KEY_ESCAPE, 6)
	if G.state != &"coop" or not Coop.lobby.is_empty():
		fail("W2: the one keyboard player left with ESC: state %s, %d joined (want the CO-OP screen, nobody)" % [G.state, Coop.lobby.size()])
		return
	await _tap(KEY_ENTER)
	# SPACE: a second player joins on the left half (it does not ready P1); the keyboard is split.
	await _tap(KEY_SPACE)
	if Coop.lobby.size() != 2 or Coop.lobby[1]["pad"] != l or Coop.lobby[0]["ready"]:
		fail("W2: SPACE with one keyboard player: %d joined, P1 ready %s (want the left half joined, P1 not ready)" % [Coop.lobby.size(), Coop.lobby[0]["ready"]])
		return
	if not Keys.split() or Coop._device_name(l) != "WASD + MOUSE" or Coop._device_name(r) != "ARROWS" or not Coop._free_halves().is_empty() \
			or Coop._key_word(r, &"pause") != "BACKSPACE" or Coop._key_word(l, &"use") != "SPACE" or Keys.mouse_pad() != l:
		fail("W2: two on the keyboard: split %s, %s / %s, free %s, P1 MENU %s, the mouse's pad %d (want %d)" % [Keys.split(),
			Coop._device_name(l), Coop._device_name(r), Coop._free_halves(), Coop._key_word(r, &"pause"), Keys.mouse_pad(), l])
	# Each reads only their half: D is the left one's RIGHT, the right arrow the right one's.
	var a0: int = Coop.lobby[0]["hero"]
	var a1: int = Coop.lobby[1]["hero"]
	await _tap(KEY_D)
	if Coop.lobby[1]["hero"] == a1 or Coop.lobby[0]["hero"] != a0:
		fail("W2: D changed P1's hero (%s) or not P2's (%s)" % [Coop.lobby[0]["hero"] != a0, Coop.lobby[1]["hero"] != a1])
	a1 = Coop.lobby[1]["hero"]
	await _tap(KEY_RIGHT)
	if Coop.lobby[0]["hero"] == a0 or Coop.lobby[1]["hero"] != a1:
		fail("W2: the right arrow changed P2's hero (%s) or not P1's (%s)" % [Coop.lobby[1]["hero"] != a1, Coop.lobby[0]["hero"] != a0])
	# The left one leaves with ESC held a while: the right one stays (ESC is theirs only when alone).
	await _hold(KEY_ESCAPE, 6)
	if Coop.lobby.size() != 1 or Coop.lobby[0]["pad"] != r:
		fail("W2: the left one left with ESC: %d joined (want the right one still in)" % Coop.lobby.size())
		return
	await _tap(KEY_SPACE)
	var sr := _held([KEY_SHIFT], l, r, &"roll", KEY_LOCATION_RIGHT)
	var sl := _held([KEY_SHIFT], l, r, &"roll", KEY_LOCATION_LEFT)
	if sr != [false, true] or sl != [true, false]:
		fail("W2: the right Shift rolls %s, the left Shift %s (left half, right half; want [false, true], [true, false])" % [sr, sl])
	# A tap shorter than a tick counts for its own half only.
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	Keys.tick()
	if not Keys.pads[r]["trig"][&"use"] or Keys.pads[l]["trig"][&"use"]:
		fail("W2: a quick ENTER went to %s" % ("both halves" if Keys.pads[l]["trig"][&"use"] else "nobody"))
	Keys.tick()
	# Both ready (heroes they have): the run, with each half its own.
	var open := order.filter(func(i): return G.hero_unlocked(GameData.heroes()[i]))
	Coop.lobby[0]["hero"] = open[0]
	Coop.lobby[1]["hero"] = open[1 % open.size()]
	await _tap(KEY_ENTER)
	await _tap(KEY_SPACE)
	for k in 200:   # the fade, then the run
		Keys.tick()
		G.update(TB.DT)
		if G.state == &"play" and G.fade.is_empty():
			break
	if G.state != &"play" or Coop.count() != 2 or not Keys.split():
		fail("W2: two keyboard players ready: state %s, %d heroes, split %s" % [G.state, Coop.count(), Keys.split()])
		Coop.solo()
		return
	var p1: int = Coop.pads[0]
	var p2: int = Coop.pads[1]
	var mv := _held([KEY_W], p2, p1, &"move_up")
	var am := _held([KEY_W], p2, p1, &"aim_up")
	var ar := _held([KEY_UP], p2, p1, &"move_up")
	var es := _held([KEY_ESCAPE], p2, p1, &"pause")
	var bs := _held([KEY_BACKSPACE], p2, p1, &"pause")
	if mv != [true, false] or am != [false, false] or ar != [false, true] or es != [true, false] or bs != [false, true]:
		fail("W2: in the run (P2 left, P1 right): W moves %s, aims %s; up arrow %s; ESC %s; BACKSPACE %s" % [mv, am, ar, es, bs])
	if Keys.mouse_pad() != p2:
		fail("W2: in the run the mouse is pad %d (want P2's, the left half: %d)" % [Keys.mouse_pad(), p2])
	# A keyboard player alone in a run keeps every key (W aims, as always), and the mouse.
	Keys.clear_pads()
	Coop.pads = [Keys.add_pad("bot"), Keys.add_pad("kb2")]
	var solo := _held([KEY_W], Coop.pads[0], Coop.pads[1], &"aim_up")
	if Keys.split() or Keys.mouse_pad() != Coop.pads[1] or solo != [false, true]:
		fail("W2: a keyboard player alone: split %s, the mouse's pad %d, W aims %s" % [Keys.split(), Keys.mouse_pad(), solo])
	Coop.solo()
	G.state = &"title"

func _full() -> void:
	var was: bool = Meta.opts.get("fullscreen", false)
	MouseMenus.toggle_full()   # headless: no window to change, but nothing may break
	Meta.opts["fullscreen"] = was
