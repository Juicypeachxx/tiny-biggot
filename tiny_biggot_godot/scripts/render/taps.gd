class_name Taps
extends RefCounted
## Touch-friendly menus (polish, spec step 0b): where each menu screen can be
## tapped. Rects use the same numbers as the drawing code in menu_view.gd and
## overlay_view.gd. A zone is { rect, sel: Callable, on: bool, instant: bool,
## act: Callable }:
## - list menus (title, pause, options) are instant: one tap selects and
##   confirms;
## - cards, purchases and grids take two taps: the first selects, a tap on the
##   selected one confirms, so a stray touch never picks or buys anything;
## - "act" zones run an action directly (e.g. switch the skill-tree hero);
## - screens that wait for any button take a tap anywhere.
## Confirming sends the normal USE action, so the game logic is unchanged.

static func _z(r: Rect2, sel: Callable, on: bool, instant: bool = false) -> Dictionary:
	return { "rect": r, "sel": sel, "on": on, "instant": instant }

static func _act(r: Rect2, act: Callable) -> Dictionary:
	return { "rect": r, "act": act }

## True when a tap anywhere should count as pressing USE.
static func any_tap() -> bool:
	return G.state in [&"howto", &"relics", &"traitlist", &"gearpage", &"dead", &"win"]

static func zones() -> Array:
	var out := []
	var sw := TB.SW
	match G.state:
		&"title":
			var dy := MenuView.title_dy()
			for i in G.title_items().size():
				out.append(_z(Rect2(sw / 2 - 85, 142 + i * dy - 4, 170, dy), func(): G.menu = i, G.menu == i, true))
			out.append(_act(Rex.title_rect(), func(): Rex.poke()))   # the sleeping dog in the corner
		&"options", &"pause":
			var opts := G.state == &"options"
			var n: int = G.OPTION_LIST.size() if opts else G.PAUSE_ITEMS.size()
			var y0 := MenuView.OPT_Y0 if opts else 86
			var dy := MenuView.OPT_DY if opts else 22
			for i in n:
				out.append(_z(Rect2(sw / 2 - 130, y0 + i * dy - 5, 260, dy - 1), func(): G.menu = i, G.menu == i, true))
		&"hero":
			var order := GameData.hero_order()   # the hero screen's own order: free heroes first
			var n := order.size()
			var win := MenuView.hero_window()
			for j in win[1]:
				var i: int = order[win[0] + j]
				out.append(_z(Rect2(win[2] + j * (MenuView.HERO_W + MenuView.HERO_GAP), 30, MenuView.HERO_W, 66),
					func(): G.hero_index = i, G.hero_index == i))
			# Scroll arrows at the screen edges.
			out.append(_act(Rect2(0, 30, win[2], 66), func(): G.hero_index = order[maxi(0, order.find(G.hero_index) - 1)]))
			out.append(_act(Rect2(sw - win[2], 30, win[2], 66), func(): G.hero_index = order[mini(n - 1, order.find(G.hero_index) + 1)]))
		&"shrine":
			var sel: int = G.shrine_i
			var ul := GameData.unlocks()
			var top := mini(maxi(0, sel - 6), maxi(0, ul.size() - 12))
			for j in mini(12, ul.size() - top):
				var i := top + j
				out.append(_z(Rect2(30, 42 + j * 16 - 3, sw - 60, 15), func(): G.shrine_i = i, sel == i))
		&"codex":
			var n := Relics.all().size()
			var cols: int = G.CODEX_COLS
			var x0 := (sw - cols * 30) / 2 + 4
			var sel_row: int = G.codex_i / cols
			var first_row := clampi(sel_row - 3, 0, maxi(0, (n + cols - 1) / cols - 6))
			for i in n:
				var row := i / cols - first_row
				if row >= 0 and row < 6:
					# Codex: a tap only selects (USE leaves the codex).
					out.append(_act(Rect2(x0 + (i % cols) * 30 - 5, 42 + row * 22 - 5, 26, 22), func(): G.codex_i = i))
		&"tree":
			var tree := Traits.tree_for(GameData.heroes()[G.tree_hero]["id"])
			for bi in tree.size():
				for ni in tree[bi]["nodes"].size():
					out.append(_z(Rect2(34 + bi * 132, 56 + ni * 38, 120, 32), _tree_sel.bind(bi, ni),
						G.tree_b == bi and G.tree_n == ni))
			var ho := GameData.hero_order()
			var hn := ho.size()
			out.append(_act(Rect2(sw / 2 - 110, 20, 80, 16), func(): G.tree_hero = ho[(ho.find(G.tree_hero) + hn - 1) % hn]))
			out.append(_act(Rect2(sw / 2 + 30, 20, 80, 16), func(): G.tree_hero = ho[(ho.find(G.tree_hero) + 1) % hn]))
		&"inventory":
			for i in 10:
				out.append(_z(MenuView.inv_slot_rect(i), func(): G.inv_i = i, G.inv_i == i))
		&"choice":
			var n: int = G.choice["relics"].size()
			var w := 100 if n > 3 else 120
			var gap := 8 if n > 3 else 14
			var x0 := (sw - (n * w + (n - 1) * gap)) / 2
			for i in n:
				out.append(_z(Rect2(x0 + i * (w + gap), 68, w, 144), func(): G.choice["idx"] = i, G.choice["idx"] == i))
		&"traits" when TraitView.active():
			for i in G.tchoice["opts"].size():
				out.append(_z(TraitView.row_rect(i), func(): G.tchoice["idx"] = i, G.tchoice["idx"] == i))
			out.append(_act(Rect2(sw / 2 + 40, TraitView.ROW_Y + 4 * TraitView.ROW_STEP + 4, 140, 14), func(): send(&"pause")))
		&"traits":
			var n: int = G.tchoice["opts"].size()
			var x0 := (sw - (n * 128 + (n - 1) * 10)) / 2
			for i in n:
				out.append(_z(Rect2(x0 + i * 138, 54, 128, 154), func(): G.tchoice["idx"] = i, G.tchoice["idx"] == i))
			# The REROLL hint line: same as pressing MENU.
			out.append(_act(Rect2(sw / 2 + 40, 220, 120, 16), func(): send(&"pause")))
	return out

static func _tree_sel(bi: int, ni: int) -> void:
	G.tree_b = bi
	G.tree_n = ni

static func hit(pos: Vector2) -> Dictionary:
	for z in zones():
		if z["rect"].grow(2).has_point(pos):
			return z
	return {}

## Runs a tap that started and ended on zone z.
static func activate(z: Dictionary) -> void:
	if z.has("act"):
		z["act"].call()
		Snd.play("select")
		return
	if z["on"]:
		send(&"use")
		return
	z["sel"].call()
	if z["instant"]:
		send(&"use")
	else:
		Snd.play("select")

## Presses and releases an input action (the same path as the touch buttons;
## Keys latches the press, so the next logic tick sees it).
static func send(action: StringName) -> void:
	for pressed in [true, false]:
		var e := InputEventAction.new()
		e.action = action
		e.pressed = pressed
		e.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(e)
