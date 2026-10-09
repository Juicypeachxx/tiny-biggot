class_name MenuView
extends Node2D
## Menus and full-screen pages (port of Render.rb draw_overlay and the draw_*
## menu functions): title, hero select, skill tree, ember shrine, codex, how
## to play, options, pause, traits / gear / relics pages and the end screens.
## As in RGSS, text goes on a base layer, glows are additive above it, and
## sprites sit on top.

var _base: DrawLayer
var _glow: DrawLayer
var _spr: DrawLayer
var _sprites: Array = []   # queued [name, x, y, zoom, mirror, alpha, tint]
var _glows: Array = []     # queued [name, x, y]

func _ready() -> void:
	_base = DrawLayer.new(_paint_base)
	_glow = DrawLayer.new(_paint_glow, true)
	_spr = DrawLayer.new(_paint_sprites)
	for l in [_base, _glow, _spr]:
		add_child(l)

func refresh() -> void:
	for l in [_base, _glow, _spr]:
		l.queue_redraw()

func _sprite(name: String, x: float, y: float, zoom: float = 1.0, mirror: bool = false, alpha: float = 1.0,
		tint: Color = Color(0, 0, 0, 0)) -> void:
	_sprites.append([name, x, y, zoom, mirror, alpha, tint])

func _paint_glow(ci: CanvasItem) -> void:
	for g in _glows:
		Gfx.at(ci, g[0], g[1], g[2])

func _paint_sprites(ci: CanvasItem) -> void:
	for s in _sprites:
		Gfx.sp(ci, s[0], s[1], s[2], s[3], s[3], 0.0, s[4], s[5], s[6])
		if s.size() > 7:
			HeroGear.draw(ci, s[7], s[1], s[2], s[3], s[3], s[4], s[5])

func _shade(ci: CanvasItem, a: int) -> void:
	ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), TB.rgba(13, 10, 18, a))

func _paint_base(ci: CanvasItem) -> void:
	_sprites.clear()
	_glows.clear()
	match G.state:
		&"title", &"hero", &"howto", &"shrine", &"codex", &"tree":
			_backdrop(ci, true)
			call("draw_" + String(G.state), ci)
			_toast(ci)
		&"options", &"keys":
			if G.opt_from == &"title":
				_backdrop(ci, true)
			else:
				_shade(ci, 210)
			call("draw_" + String(G.state), ci)
		&"pause":
			_shade(ci, 210)
			draw_pause(ci)
		&"fishing":
			Fishing.draw_panel(ci)   # 15.1: over the world
		&"traitlist":
			_shade(ci, 220)
			draw_traitlist(ci)
		&"gearpage":
			_shade(ci, 222)
			draw_gearpage(ci)
		&"inventory":
			_shade(ci, 228)
			draw_inventory(ci)
		&"relics":
			_shade(ci, 220)
			draw_relics(ci)
		&"kitchen":   # 19.2
			_shade(ci, 228)
			CampLife.draw_kitchen(ci)
		&"armory":
			_shade(ci, 228)
			CampLife.draw_armory(ci)
		&"plans":   # 20.2
			_shade(ci, 228)
			CampBuild.draw_plans(ci)
		&"board":
			_shade(ci, 228)
			Quests.draw_board(ci)
		&"wardrobe":
			if G.wardrobe_from == &"title":
				_backdrop(ci, true)
			else:
				_shade(ci, 228)
			draw_wardrobe(ci)
		&"dead", &"win":
			_backdrop(ci, false)
			draw_end(ci)
	_glow.queue_redraw()
	_spr.queue_redraw()

func _backdrop(ci: CanvasItem, towers: bool) -> void:
	ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), TB.c("#120e18"))
	if towers:
		for i in 28:
			var h := 30 + ((i * 37) % 50)
			ci.draw_rect(Rect2(i * 16, TB.SH - h, 15, h), TB.c("#1a1423"))
	for e in G.embers:
		ci.draw_rect(Rect2(roundf(e["x"]), roundf(e["y"]), 1, 1), TB.ca(e["col"], roundi(clampf(e["life"] / 3, 0.0, 1.0) * 255)))

func _menu_item(ci: CanvasItem, label: String, x: float, y: float, i: int, scale: int = 1, w: int = 120) -> void:
	var sel := G.menu == i
	var tw := TB.text_w(label, scale)
	if sel:
		ci.draw_rect(Rect2(x - w / 2, y - 3, w, 5 * scale + 6), TB.rgba(232, 135, 58, 46))
		Gfx.text(ci, ">", x - tw / 2 - 8 - roundf(sin(G.time * 8)), y, "orange", scale)
	Gfx.text(ci, label, x, y, "gold" if sel else "tan", scale, 0.5)

func _toast(ci: CanvasItem) -> void:
	var m := G.msg
	if m.is_empty():
		return
	var w := TB.text_w(m["text"], 2) + 20
	var y := 228 if G.state == &"tree" else 130
	Gfx.panel(ci, (TB.SW - w) / 2, y, w, 22, "#e8873a")
	Gfx.text(ci, m["text"], TB.SW / 2, y + 6, m["col"], 2, 0.5)

static func fmt_time(s: float) -> String:
	var t := floori(s)
	return "%d:%02d" % [t / 60, t % 60]

static func _fmt_num(v: float) -> String:
	return str(roundi(v)) if v == roundf(v) else "%.1f" % v

# ---------- Title ----------
func draw_title(ci: CanvasItem) -> void:
	var t := G.time
	var wob := roundf(sin(t * 2) * 2)
	var l1 := Img.t("logo_cinder")
	var l2 := Img.t("logo_crypt")
	Gfx.at(ci, "logo_cinder", (TB.SW - l1.get_width()) / 2, 18 + wob)
	Gfx.at(ci, "logo_crypt", (TB.SW - l2.get_width()) / 2, 58 + wob)
	# Design spec section 1: the game is now "Tiny Biggot Rogues".
	Gfx.text(ci, "ROGUES", (TB.SW + l2.get_width()) / 2 + 6, 58 + l2.get_height() - 12 + wob, "red", 2)
	var shown := []
	for hi in GameData.hero_order():
		var h: Dictionary = GameData.heroes()[hi]
		if G.hero_unlocked(h):
			shown.append(h)
	# 36 px apart, closer once the whole roster is unlocked so the row stays on screen.
	var gap := mini(36, (TB.SW - 48) / maxi(1, shown.size() - 1))
	for i in shown.size():
		_sprite(shown[i]["sprite"], TB.SW / 2 - (shown.size() - 1) * gap / 2 + i * gap, 128 + (-1 if floori(t * 3 + i) % 2 == 1 else 0),
			2, i >= shown.size() / 2)
	var items := G.title_items()
	for i in items.size():
		_menu_item(ci, items[i], TB.SW / 2, 142 + i * title_dy(), i, 2, 170)
	var m := Meta.meta
	var line := "EMBERS %d    RUNS %d    WINS %d    DEEPEST FLOOR %d" % [m["embers"], m["runs"], m["wins"], m["best"]]
	if m.get("best_loop", 0) > 0:
		line += "    BEST LOOP %d" % (m["best_loop"] + 1)
	Gfx.at(ci, "ember", TB.SW / 2 - TB.text_w(line) / 2 - 8, 250)
	Gfx.text(ci, line, TB.SW / 2, 251, "grey", 1, 0.5)
	Gfx.text(ci, "PRESS USE TO SELECT", TB.SW / 2, 268, "dim", 1, 0.5)
	Gfx.text(ci, Versions.label(), TB.SW - 4, 277, "dim", 1, 1)   # 28: the version and its name (versions.gd)
	Rex.draw_title(ci, t)   # someone is asleep in the corner

# ---------- Hero select ----------
## Title menu row spacing (taps.gd uses it too): a little tighter with the constellation's row.
static func title_dy() -> int:
	var n := G.title_items().size()
	return 17 if n <= 6 else (15 if n == 7 else (13 if n == 8 else (12 if n == 9 else 11)))   # 8 with CONTINUE (6.3), 9 with the WARDROBE (14.2)

## Hero strip geometry, shared with the tap zones (taps.gd): up to six panels
## are shown and the strip scrolls to keep the selected hero in view.
## Returns [first index, shown count, x of the first panel].
const HERO_W := 68
const HERO_GAP := 4
const HERO_VIS := 6
static func hero_window() -> Array:
	var n := GameData.heroes().size()
	var vis := mini(n, HERO_VIS)
	var first := clampi(GameData.hero_order().find(G.hero_index) - 2, 0, n - vis)
	return [first, vis, (TB.SW - (vis * HERO_W + (vis - 1) * HERO_GAP)) / 2]

func draw_hero(ci: CanvasItem) -> void:
	var t := G.time
	Gfx.text(ci, "THE ENDLESS DESCENT" if G.endless_next else "CHOOSE YOUR DELVER", TB.SW / 2, 10, "purple" if G.endless_next else "gold", 2, 0.5)
	var n := GameData.heroes().size()
	var w := HERO_W
	var win := hero_window()
	var x0: int = win[2]
	var order := GameData.hero_order()   # free heroes first, then the ones bought at the shrine
	for j in win[1]:
		var i: int = order[win[0] + j]
		var h: Dictionary = GameData.heroes()[i]
		var x: int = x0 + j * (w + HERO_GAP)
		var y := 30
		var sel := G.hero_index == i
		var open := G.hero_unlocked(h)
		Gfx.panel(ci, x, y, w, 66, "#e8873a" if sel else "#4e4a5e", "#221a2c" if sel else "#17121e")
		if sel and open:
			_glows.append(["glow_torch", x + w / 2 - 36, y - 4])
		_sprite(h["sprite"], x + w / 2, y + 48 + (-2 if sel and floori(t * 4) % 2 == 1 else 0), 3, false, 1.0,
			Color(0, 0, 0, 0) if open else TB.rgba(20, 15, 28, 255))
		Gfx.text(ci, h["name"].replace("THE ", "") if open else "LOCKED", x + w / 2, y + 54, "gold" if sel else ("tan" if open else "dim"), 1, 0.5)
		if h.get("new", false):
			Gfx.text(ci, "NEW", x + w - 4, y + 4, "lime", 1, 1)
	# Scroll arrows when there are more heroes than fit.
	if win[0] > 0:
		Gfx.text(ci, "<", 6, 58, "orange", 2)
	if win[0] + win[1] < n:
		Gfx.text(ci, ">", TB.SW - 12, 58, "orange", 2)
	Gfx.text(ci, "%d / %d" % [order.find(G.hero_index) + 1, n], TB.SW / 2, 98, "dim", 1, 0.5)
	var h: Dictionary = GameData.heroes()[G.hero_index]
	var open := G.hero_unlocked(h)
	Gfx.panel(ci, 40, 104, TB.SW - 80, 126, "#4e4a5e", "#17121e")   # tall enough for a three-line passive and a skill
	Gfx.text(ci, h["name"], TB.SW / 2, 112, "gold" if open else "dim", 2, 0.5)
	Gfx.text(ci, h["weapon"], TB.SW / 2, 128, "grey", 1, 0.5)
	for k in h["hp"] / 2:
		Gfx.at(ci, "heart_full", roundf(TB.SW / 2 - (h["hp"] / 2) * 4.5 + k * 9), 138)
	var bl := Gfx.wrap_text(h["blurb"], TB.SW - 120)
	for j in bl.size():
		Gfx.text(ci, bl[j], TB.SW / 2, 152 + j * 9, "white", 1, 0.5)
	var hw := Weapons.by_id(Weapons.HERO_WEAPON[h["id"]])
	var sy := 176
	if h.has("passive"):
		# New heroes: their passive ability, then the starting trait.
		var pl := Gfx.wrap_text(h["passive"], TB.SW - 100)
		for j in pl.size():
			Gfx.text(ci, pl[j], TB.SW / 2, 152 + bl.size() * 9 + 2 + j * 8, "cyan", 1, 0.5)
		sy = 152 + bl.size() * 9 + 4 + pl.size() * 8
		if h.has("special"):
			var spl := Gfx.wrap_text("SKILL - " + h["special"]["name"] + ": " + h["special"]["desc"], TB.SW - 100)
			for j in spl.size():
				Gfx.text(ci, spl[j], TB.SW / 2, sy + j * 8, "orange", 1, 0.5)
			sy += spl.size() * 8 + 2
		if h.has("trait"):   # 20.1: the originals have a passive and a skill, but no starting trait
			Gfx.text(ci, "STARTING TRAIT: " + Traits.by_id(h["trait"])["name"], TB.SW / 2, sy, "lime", 1, 0.5)
			sy += 10
	elif h.has("special"):   # 20.1: the other originals: their skill only
		sy = 152 + bl.size() * 9 + 2
		var spl := Gfx.wrap_text("SKILL - " + h["special"]["name"] + ": " + h["special"]["desc"], TB.SW - 100)
		for j in spl.size():
			Gfx.text(ci, spl[j], TB.SW / 2, sy + j * 8, "orange", 1, 0.5)
		sy += spl.size() * 8 + 2
	Gfx.text(ci, "STARTS WITH %s   DAMAGE %s   RATE %.1f/S   SPEED %d" % [hw["name"], _fmt_num(hw["dmg"]), hw["rate"], h["speed"]],
		TB.SW / 2, sy, "tan", 1, 0.5)
	if open and GameData.rogues():
		Gfx.text(ci, Trophies.line(h["id"]), TB.SW / 2, sy + 10, "gold", 1, 0.5)   # 7.2
	if not open:
		Gfx.text(ci, "UNLOCK AT THE EMBER SHRINE FOR %d EMBERS" % h["cost"], TB.SW / 2, maxi(196, sy + 11), "orange", 1, 0.5)
	var mx: int = Meta.meta.get("dread_max", 0)
	if mx > 0:
		var d := mini(Meta.meta.get("dread", 0), mx)
		# Under the hero panel, so it never sits on a new hero's passive and skill text.
		Gfx.text(ci, "DREAD %d: %s" % [d, GameData.DREAD_DESC[d]], TB.SW / 2, 236, "red" if d > 0 else "grey", 1, 0.5)
		Gfx.text(ci, "UP/DOWN CHANGES DREAD.  MORE DREAD, MORE EMBERS", TB.SW / 2, 246, "dim", 1, 0.5)
	else:
		Gfx.text(ci, "WIN A RUN TO UNLOCK DREAD LEVELS", TB.SW / 2, 240, "dim", 1, 0.5)
	Gfx.text(ci, "< >  CHOOSE     USE  BEGIN     ROLL  SKILL TREE     MENU  BACK", TB.SW / 2, 262, "grey", 1, 0.5)

# ---------- Ember shrine ----------
func draw_shrine(ci: CanvasItem) -> void:
	Gfx.text(ci, "EMBER SHRINE", TB.SW / 2, 10, "orange", 2, 0.5)
	var line := "%d EMBERS" % Meta.meta["embers"]
	Gfx.at(ci, "ember", TB.SW / 2 - TB.text_w(line) / 2 - 8, 28)
	Gfx.text(ci, line, TB.SW / 2, 29, "gold", 1, 0.5)
	var sel := G.shrine_i
	var ul := GameData.unlocks()
	var top := mini(maxi(0, sel - 6), maxi(0, ul.size() - 12))
	for j in mini(12, ul.size() - top):
		var i := top + j
		var u: Dictionary = ul[i]
		var y := 42 + j * 16
		var on := Meta.unlocked(u["id"])
		if i == sel:
			ci.draw_rect(Rect2(30, y - 3, TB.SW - 60, 14), TB.rgba(232, 135, 58, 46))
		Gfx.text(ci, ">" if i == sel else " ", 34, y, "orange")
		Gfx.text(ci, u["name"], 44, y, "dim" if on else ("gold" if i == sel else "tan"))
		Gfx.text(ci, u["desc"], 150, y, "dim" if on else "white")
		Gfx.text(ci, "OWNED" if on else str(u["cost"]), TB.SW - 36, y, "green" if on else ("gold" if Meta.meta["embers"] >= u["cost"] else "red"), 1, 1)
	Gfx.text(ci, "EARN EMBERS BY GOING DEEP, SLAYING GUARDIANS AND FINDING SECRETS", TB.SW / 2, 246, "grey", 1, 0.5)
	Gfx.text(ci, "USE  UNLOCK     MENU  BACK", TB.SW / 2, 262, "grey", 1, 0.5)

# ---------- Relic codex ----------
## 22.3: the codex's pages, named along the top (tap one, or ROLL for the next).
const CODEX_TABS := ["RELICS", "BESTIARY", "PAST RUNS", "TRAITS"]   # 30.2: the trait book
const CODEX_TAB_X := [56, 160, 280, 392]
func draw_codex(ci: CanvasItem) -> void:
	for k in CODEX_TABS.size():
		Gfx.text(ci, CODEX_TABS[k], CODEX_TAB_X[k], 10, "gold" if G.codex_tab == k else "dim", 2, 0.5)
	Gfx.text(ci, "ARROWS  BROWSE     ROLL  NEXT PAGE     MENU  BACK", TB.SW / 2, 262, "grey", 1, 0.5)
	match G.codex_tab:
		1:
			Bestiary.draw_beasts(ci, G.bestiary_i)
			return
		2:
			Bestiary.draw_runs(ci)
			return
		3:
			TraitBook.draw(ci, G.traitbook_i)
			return
	var rel := Relics.all()
	var found_d: Dictionary = Meta.meta["found"]
	var found := 0
	for r in rel:
		if found_d.has(r["id"]):
			found += 1
	Gfx.text(ci, "%d OF %d FOUND" % [found, rel.size()], TB.SW / 2, 28, "grey", 1, 0.5)
	var pool := {}
	for r in G.relic_pool():
		pool[r["id"]] = true
	var cols := G.CODEX_COLS
	var cw := 30
	var chh := 22
	var x0 := (TB.SW - cols * cw) / 2 + 4
	# The codex grid scrolls so the selected relic stays on screen.
	var rows_shown := 6
	var sel_row := G.codex_i / cols
	var first_row := clampi(sel_row - rows_shown / 2, 0, maxi(0, (rel.size() + cols - 1) / cols - rows_shown))
	for i in rel.size():
		var row := i / cols - first_row
		if row < 0 or row >= rows_shown:
			continue
		var r: Dictionary = rel[i]
		var x := x0 + (i % cols) * cw
		var y := 42 + row * chh
		var sel := G.codex_i == i
		if sel:
			ci.draw_rect(Rect2(x - 4, y - 4, 20, 20), TB.rgba(232, 135, 58, 90))
		var fr: String = "frame_" + (r["rarity"] if r["rarity"] in ["common", "rare", "epic", "legend"] else "common")
		Gfx.at(ci, fr, x - 2, y - 2, 1.0 if found_d.has(r["id"]) else 90 / 255.0)
		if found_d.has(r["id"]):
			Gfx.at(ci, r["sprite"], x - 1, y - 1)
		else:
			Gfx.text(ci, "?" if pool.has(r["id"]) else "-", x + 4, y + 1, "dim")
	var r: Dictionary = rel[G.codex_i]
	Gfx.panel(ci, 30, 182, TB.SW - 60, 56, "#4e4a5e", "#17121e")
	if found_d.has(r["id"]):
		Gfx.text(ci, r["name"], TB.SW / 2, 190, "gold", 2, 0.5)
		Gfx.text(ci, GameData.RARITY_NAME[r["rarity"]], TB.SW / 2, 207, GameData.RARITY_COL[r["rarity"]], 1, 0.5)
		Gfx.text(ci, r["desc"], TB.SW / 2, 220, "white", 1, 0.5)
	elif pool.has(r["id"]):
		Gfx.text(ci, "UNDISCOVERED", TB.SW / 2, 196, "grey", 2, 0.5)
		Gfx.text(ci, "FIND IT IN THE CRYPT TO LEARN WHAT IT DOES", TB.SW / 2, 220, "dim", 1, 0.5)
	else:
		Gfx.text(ci, "LOCKED", TB.SW / 2, 196, "red", 2, 0.5)
		Gfx.text(ci, "UNLOCK ITS RELIC CACHE AT THE EMBER SHRINE", TB.SW / 2, 220, "dim", 1, 0.5)

# ---------- How to play ----------
func draw_howto(ci: CanvasItem) -> void:
	Gfx.text(ci, "HOW TO PLAY", TB.SW / 2, 16, "gold", 2, 0.5)
	var lines := [
		["GOAL", "DESCEND 6 FLOORS AND SLAY EACH GUARDIAN." if GameData.floors().size() <= 6 else "SLAY 6 GUARDIANS TO WIN, THEN GO ON TO THE ECLIPSE."],
		["", "DEATH ENDS THE RUN. EVERY RUN IS NEW."],
		["ROOMS", "DOORS SEAL UNTIL ALL FOES ARE DEAD."],
		["", "MAP: RED BOSS, GOLD CHEST, GREEN SHOP, PURPLE SHRINE."],
		["RELICS", "STACK RELICS TO BUILD YOUR RUN."],
		["", "SPEND GOLD IN SHOPS. PAY BLOOD AT ALTARS."],
		["", ""],
		["TOUCH", "STICK MOVES. AIM BUTTONS AIM BY HAND."],
		["", "AUTO-AIM SHOOTS THE NEAREST FOE FOR YOU."],
		["", "ROLL DODGES. USE BUYS AND OPENS. HEAL DRINKS. BOMB BLASTS."],
		["KEYS", "ARROWS MOVE. WASD AIM. SHIFT ROLL. ENTER USE. CTRL BOMB."],
		["", "Q HEAL. ESC MENU. F SKILL. IPAD: TAB MENU, E BOMB."],
		["PAD", "STICKS MOVE AND AIM. B ROLL. A USE. X HEAL."],
	]
	for i in lines.size():
		Gfx.text(ci, lines[i][0], 40, 44 + i * 15, "orange")
		Gfx.text(ci, lines[i][1], 96, 44 + i * 15, "white")
	Gfx.text(ci, "ROLLING MAKES YOU UNTOUCHABLE FOR A MOMENT.", TB.SW / 2, 248, "cyan", 1, 0.5)
	Gfx.text(ci, "PRESS ANY BUTTON", TB.SW / 2, 266, "dim", 1, 0.5)

# ---------- Options and pause ----------
## Where the option rows sit (the tap zones in taps.gd use the same numbers).
const OPT_Y0 := 68   # 8.2: eleven rows (STAT COLUMN) fit
const OPT_DY := 15   # 13.1: thirteen rows; 21.3: fourteen (PLACE SOUNDS)
func draw_options(ci: CanvasItem) -> void:
	Gfx.text(ci, "OPTIONS", TB.SW / 2, 46, "gold", 2, 0.5)
	for i in G.OPTION_LIST.size():
		var label: String = G.OPTION_LIST[i][0]
		var key: String = G.OPTION_LIST[i][1]
		var txt := "%s:  %s" % [label, "ON" if Meta.opts[key] else "OFF"] if key != "" and key[0] != "@" else label
		_menu_item(ci, txt, TB.SW / 2, OPT_Y0 + i * OPT_DY, i, 2, 260)

## 13.1: the keyboard keys page (taps.gd uses the same rows).
const KEYS_Y0 := 36
const KEYS_DY := 12
func draw_keys(ci: CanvasItem) -> void:
	Gfx.text(ci, "KEYBOARD KEYS", TB.SW / 2, 14, "gold", 2, 0.5)
	var n := Keys.REBIND.size()
	for i in n + 2:
		var y := KEYS_Y0 + i * KEYS_DY
		var sel := G.menu == i
		if sel:
			ci.draw_rect(Rect2(60, y - 3, TB.SW - 120, 11), TB.rgba(232, 135, 58, 46))
		if i < n:
			var a: StringName = Keys.REBIND[i][0]
			Gfx.text(ci, Keys.REBIND[i][1], 72, y, "gold" if sel else "tan")
			var k := "PRESS A KEY... (TAP OR ESC: CANCEL)" if Keys.capturing == a else Keys.keys_label(a)
			Gfx.text(ci, k, TB.SW - 72, y, "orange" if Keys.capturing == a else "white", 1, 1)
		else:
			Gfx.text(ci, "RESET ALL KEYS" if i == n else "BACK", TB.SW / 2, y, "gold" if sel else "tan", 1, 0.5)
	Gfx.text(ci, "ESC ALWAYS PAUSES AND ENTER ALWAYS CONFIRMS", TB.SW / 2, TB.SH - 12, "dim", 1, 0.5)

const PAUSE_Y0 := 86
static func pause_dy() -> int:
	return 22 if G.pause_items().size() <= 6 else 19   # 14.2: seven rows with the WARDROBE

func draw_pause(ci: CanvasItem) -> void:
	Gfx.text(ci, "PAUSED", TB.SW / 2, 44, "gold", 3, 0.5)
	var items := G.pause_items()
	for i in items.size():
		var label: String = items[i]
		if label == "ABANDON RUN" and G.quit_armed:
			label = "SURE? PRESS AGAIN"
		_menu_item(ci, label, TB.SW / 2, PAUSE_Y0 + i * pause_dy(), i, 2, 260)
	var p := G.player
	Gfx.text(ci, "TIME %s   KILLS %d   LEVEL %d" % [fmt_time(G.run_stats["time"]), G.run_stats["kills"], p.level],
		TB.SW / 2, 214 if G.pause_items().size() <= 6 else 222, "grey", 1, 0.5)

# ---------- Traits page ----------
func draw_traitlist(ci: CanvasItem) -> void:
	var p := G.player
	Gfx.text(ci, "TRAITS  -  LEVEL %d" % p.level, TB.SW / 2, 12, "gold", 2, 0.5)
	var y := 32
	var fams: Array = p.fam.keys()
	fams.sort_custom(func(a, b): return p.fam[a] > p.fam[b])
	for f in fams:
		var fam: Dictionary = Traits.FAMILIES[f]
		var tier: int = p.fam_bonus.get(f, 0)
		Gfx.text(ci, "%s %d" % [fam["name"], p.fam[f]], 20, y, fam["col"])
		if Traits.FAMILY_BONUS.has(f):
			for k in Traits.FAMILY_BONUS[f].size():
				Gfx.text(ci, "%d: %s" % [(k + 1) * 2, Traits.bonus_name(f, k)], 110, y + k * 8, fam["col"] if k < tier else "dim")
		var names := []
		for t in Traits.all():
			if t["fam"] == f and p.traits.has(t["id"]):
				names.append("%s %d" % [t["name"], p.traits[t["id"]]])
		var wl := Gfx.wrap_text(", ".join(names), 80)
		for j in mini(2, wl.size()):
			Gfx.text(ci, wl[j], 20, y + 9 + j * 8, "white")
		y += 20 if f == "core" else 28
		if y > 226:
			break
	if fams.is_empty():
		Gfx.text(ci, "NO TRAITS YET. LEVEL UP BY SLAYING FOES.", TB.SW / 2, 60, "grey", 1, 0.5)
	# New: active tag synergies and combos.
	if not p.synergies.is_empty():
		Gfx.text(ci, "ACTIVE SYNERGIES: %d" % p.synergies.size(), TB.SW / 2, 252, "gold", 1, 0.5)
	if GameData.rogues():   # 14.3: the hidden trait combos
		var hid := Synergies.COMBOS.filter(func(c): return c.get("hidden", false))
		var fd: Dictionary = Meta.meta.get("combos_found", {}) if Meta.meta.get("combos_found") is Dictionary else {}
		var live := hid.filter(func(c): return p.synergies.has("combo:" + c["id"])).map(func(c): return c["name"])
		Gfx.text(ci, "HIDDEN COMBOS FOUND %d OF %d%s" % [fd.size(), hid.size(), ("   ACTIVE: " + ", ".join(live)) if not live.is_empty() else ""],
			TB.SW / 2, 242, "purple", 1, 0.5)
	Gfx.text(ci, "PRESS ANY BUTTON", TB.SW / 2, 266, "dim", 1, 0.5)

# ---------- Skill tree ----------
func draw_tree(ci: CanvasItem) -> void:
	var h: Dictionary = GameData.heroes()[G.tree_hero]
	var open := G.hero_unlocked(h)
	var owned := G.tree_owned(h["id"])
	Gfx.text(ci, "SKILL TREE", TB.SW / 2, 8, "gold", 2, 0.5)
	_sprite(h["sprite"], 40, 40, 2)
	Gfx.text(ci, "< " + h["name"] + " >", TB.SW / 2, 26, "tan" if open else "dim", 1, 0.5)
	var line := "%d EMBERS" % Meta.meta["embers"]
	Gfx.at(ci, "ember", TB.SW - 40 - TB.text_w(line), 26)
	Gfx.text(ci, line, TB.SW - 32, 27, "gold", 1, 1)
	var tree := Traits.tree_for(h["id"])
	for bi in tree.size():
		var br: Dictionary = tree[bi]
		var x := 34 + bi * 132
		Gfx.text(ci, br["name"], x + 60, 44, "orange" if bi == 2 else "tan", 1, 0.5)
		for ni in br["nodes"].size():
			var nd: Array = br["nodes"][ni]
			var y: int = 56 + ni * 38
			var got: bool = owned[bi] > ni
			var avail: bool = owned[bi] == ni
			var sel: bool = G.tree_b == bi and G.tree_n == ni
			var border: String = "#f2c94c" if sel else ("#63b84f" if got else ("#8b8f9c" if avail else "#2a2838"))
			Gfx.panel(ci, x, y, 120, 32, border, "#1d2a20" if got else "#17121e")
			if ni > 0:
				ci.draw_rect(Rect2(x + 59, y - 6, 2, 6), TB.c("#63b84f" if got else "#2a2838"))
			Gfx.text(ci, nd[0], x + 60, y + 4, "lime" if got else ("gold" if avail else "dim"), 1, 0.5)
			var wl := Gfx.wrap_text(nd[1], 112)
			for j in mini(2, wl.size()):
				Gfx.text(ci, wl[j], x + 60, y + 13 + j * 8, "white" if got or avail else "dim", 1, 0.5)
			if not got:
				Gfx.text(ci, str(Traits.TREE_COSTS[ni]), x + 116, y + 4, "orange" if Meta.meta["embers"] >= Traits.TREE_COSTS[ni] else "red", 1, 1)
	var nd: Array = tree[G.tree_b]["nodes"][G.tree_n]
	Gfx.text(ci, nd[0] + ": " + nd[1], TB.SW / 2, 214, "white", 1, 0.5)
	Gfx.text(ci, "ARROWS  PICK     USE  LEARN     AIM L/R  HERO     MENU  BACK", TB.SW / 2, 262, "grey", 1, 0.5)

# ---------- Gear page ----------
func draw_gearpage(ci: CanvasItem) -> void:
	var p := G.player
	Gfx.text(ci, "EQUIPMENT", TB.SW / 2, 10, "gold", 2, 0.5)
	var w: Dictionary = p.weapon
	Gfx.panel(ci, 16, 30, TB.SW - 32, 64, GameData.RARITY_HEX[w["rarity"]], "#17121e")
	ci.draw_texture_rect(Img.t(w["sprite"]), Rect2(24, 38, 24, 24), false)
	Gfx.text(ci, w["name"], 56, 36, GameData.RARITY_COL[w["rarity"]], 2)
	Gfx.text(ci, GameData.RARITY_NAME[w["rarity"]] + " " + Weapons.ARCH[w["kind"]]["name"] + " - " + Weapons.ARCH_DESC[w["kind"]], 56, 50, "grey")
	Gfx.text(ci, "DAMAGE %.1f  RATE %.1f/S  SHOTS %d  SYNERGY +%d%%" % [Weapons.wdmg(p), Weapons.wrate(p), Weapons.wcount(p),
		roundi((Weapons.synergy_mult(p) - 1) * 100)], 56, 60, "lime")
	var tags := "NONE" if w["tags"].is_empty() else OverlayView._tag_names(w["tags"])
	if Attributes.enabled():
		# Rogues layer: the weapon's scaling and your attributes.
		var g := Attributes.scaling(w)
		var x := 56
		x += Gfx.text(ci, "SCALING ", x, 70, "tan")
		for a in Attributes.ATTRS:
			x += Gfx.text(ci, "%s %s  " % [Attributes.NAMES[a], g[a]], x, 70, Attributes.COLS[a])
		x += Gfx.text(ci, " YOU ", x, 70, "tan")
		for a in Attributes.ATTRS:
			x += Gfx.text(ci, "%s %d  " % [Attributes.NAMES[a], Attributes.value(p, a)], x, 70, Attributes.COLS[a])
		Gfx.text(ci, "+%d%% DAMAGE" % roundi((Attributes.mult(p) - 1) * 100), x, 70, "gold")
	else:
		Gfx.text(ci, "TAGS: " + tags + "  (EACH MATCHING TRAIT RANK +8%, GEAR PIECE +12%)", 56, 70, "tan")
	var dl := TraitView.rich_lines(w["desc"], TB.SW - 90)   # 8.2: keywords in colour
	if not dl.is_empty():
		TraitView.draw_line(ci, dl[0], 56, 80)
	var gs := Gear.slots()
	var compact := gs.size() > 4   # step 8: eight slots in shorter panels
	for i in gs.size():
		var sl: String = gs[i]
		var g = p.gear.get(sl)
		var x: int = 16 + (i % 2) * 212
		var y: int = (96 + (i / 2) * 31) if compact else (100 + (i / 2) * 58)
		var ph := 29 if compact else 52
		Gfx.panel(ci, x, y, 204, ph, GameData.RARITY_HEX[g["rarity"]] if g != null else "#2a2838", "#17121e")
		if compact:
			Gfx.text(ci, Gear.SLOT_NAME[sl], x + 4, y + 3, "dim")
			if g != null:
				ci.draw_texture_rect(Img.t(g["sprite"]), Rect2(x + 4, y + 11, 14, 14), false)
				Gfx.text(ci, g["name"], x + 40, y + 3, GameData.RARITY_COL[g["rarity"]])
				var gl := TraitView.rich_lines(Live.desc(g), 178)
				for j in mini(2, gl.size()):
					TraitView.draw_line(ci, gl[j], x + 22, y + 12 + j * 8)
			else:
				Gfx.text(ci, "EMPTY", x + 40, y + 3, "dim")
			continue
		Gfx.text(ci, Gear.SLOT_NAME[sl], x + 6, y + 4, "dim")
		if g != null:
			ci.draw_texture_rect(Img.t(g["sprite"]), Rect2(x + 6, y + 14, 20, 20), false)
			Gfx.text(ci, g["name"], x + 32, y + 14, GameData.RARITY_COL[g["rarity"]])
			var lines := []
			for kv in g["stats"]:
				var sline := Gear.stat_line(kv[0], kv[1])
				if sline != "":
					lines.append(sline)
			if not lines.is_empty():
				Gfx.text(ci, "  ".join(lines), x + 32, y + 24, "lime")
			var gl := TraitView.rich_lines(Live.desc(g), 166)
			for j in mini(2, gl.size()):
				TraitView.draw_line(ci, gl[j], x + 32, y + 33 + j * 8)
		else:
			Gfx.text(ci, "EMPTY", x + 32, y + 22, "dim")
	var y := 222 if compact else 220
	for id in p.sets:
		var n: int = p.sets[id]
		if n <= 0:
			continue
		var st: Dictionary = Gear.SETS[id]
		var sline := "%s %d/4:  2: %s   4: %s" % [st["name"], n, st["d2"], st["d4"]]
		if GameData.rogues():   # 13.2: the next step is shown
			var sz: int = st.get("size", 4)
			sline = "%s %d/%d  NEXT: %s" % [st["name"], n, sz, Gear.set_desc(st, Gear._tier_of(n, sz) + 1) if n < sz else "COMPLETE! " + Gear.full_desc(st)]
		Gfx.text(ci, sline, TB.SW / 2, y, "gold" if n >= 2 else "dim", 1, 0.5)
		y += 9
	Gfx.text(ci, "PRESS ANY BUTTON", TB.SW / 2, 266, "dim", 1, 0.5)

# ---------- 14.2 The WARDROBE ----------
const WARD_Y0 := 34
const WARD_DY := 13
const WARD_ROWS := 16
## The first set shown in the list (it scrolls to keep the chosen one in view); taps.gd uses it.
static func ward_top() -> int:
	return clampi(G.wardrobe_i - WARD_ROWS / 2, 0, maxi(0, Gear.SETS.size() - WARD_ROWS))

func draw_wardrobe(ci: CanvasItem) -> void:
	Gfx.text(ci, "WARDROBE", TB.SW / 2, 10, "gold", 2, 0.5)
	var ids: Array = Gear.SETS.keys()
	var found: Dictionary = Meta.meta.get("found_g", {})
	var p := G.player
	var in_run := G.wardrobe_from == &"pause" and p != null
	var top := ward_top()
	var all_found := 0
	var all_n := 0
	for id in ids:
		for g in Gear.pieces(id):
			all_n += 1
			if found.has(g["id"]):
				all_found += 1
	for j in mini(WARD_ROWS, ids.size() - top):
		var i := top + j
		var id: String = ids[i]
		var st: Dictionary = Gear.SETS[id]
		var pcs := Gear.pieces(id)
		var nf := pcs.filter(func(g): return found.has(g["id"])).size()
		var y := WARD_Y0 + j * WARD_DY
		var sel := i == G.wardrobe_i
		if sel:
			ci.draw_rect(Rect2(10, y - 3, 168, 11), TB.rgba(232, 135, 58, 46))
		var col := "gold" if sel else ("tan" if nf > 0 else "dim")
		Gfx.text(ci, ("* " if st.get("size", 4) == 6 else "") + st["name"], 16, y, col)
		var right := "%d/%d" % [nf, pcs.size()]
		if in_run and p.sets.get(id, 0) > 0:
			right = "WEAR %d/%d" % [p.sets[id], pcs.size()]
		Gfx.text(ci, right, 174, y, "lime" if in_run and p.sets.get(id, 0) > 0 else ("white" if nf == pcs.size() else "grey"), 1, 1)
	if top > 0:
		Gfx.text(ci, "^", 94, WARD_Y0 - 9, "dim", 1, 0.5)
	if top + WARD_ROWS < ids.size():
		Gfx.text(ci, "V", 94, WARD_Y0 + WARD_ROWS * WARD_DY - 2, "dim", 1, 0.5)
	# The chosen set.
	var id: String = ids[G.wardrobe_i]
	var st: Dictionary = Gear.SETS[id]
	var sz: int = st.get("size", 4)
	var x0 := 192
	var cols: Array = Weapons.TAG_COLS.get(st["tag"], Weapons.TAG_COLS["core"])
	Gfx.text(ci, st["name"], x0, 34, "gold", 2)
	Gfx.text(ci, ("LEGENDARY SET OF 6" if sz == 6 else "SET OF 4") + " - " + Traits.FAMILIES.get(st["tag"], { "name": st["tag"].to_upper() })["name"],
		x0, 50, "pink" if sz == 6 else "grey")
	var pcs := Gear.pieces(id)
	for k in pcs.size():
		var g: Dictionary = pcs[k]
		var gx := x0 + 12 + k * 40
		var have := found.has(g["id"])
		var worn := in_run and p.gear.values().any(func(w): return w != null and w["id"] == g["id"])
		ci.draw_rect(Rect2(gx - 14, 62, 28, 28), TB.c(cols[1]) if worn else Color(0.08, 0.06, 0.11, 0.8))
		ci.draw_rect(Rect2(gx - 14, 62, 28, 1), TB.c(cols[0]) if have else TB.c("#4e4a5e"))
		Gfx.sp(ci, g["sprite"], gx, 86, 2, 2, 0.0, false, 1.0 if have else 0.7, Color(0, 0, 0, 0) if have else Color(0.32, 0.29, 0.4, 1))
		Gfx.text(ci, Gear.SLOT_NAME[g["slot"]], gx, 93, "white" if have else "dim", 1, 0.5)
	var y := 106
	for k in pcs.size():
		var g: Dictionary = pcs[k]
		Gfx.text(ci, g["name"] if found.has(g["id"]) else "??? " + Gear.SLOT_NAME[g["slot"]] + " - NOT FOUND YET", x0, y,
			GameData.RARITY_COL[g["rarity"]] if found.has(g["id"]) else "dim")
		y += 9
	y += 4
	var steps := [[2, st["d2"]]]
	if sz == 6:
		steps.append([4, st["d4"]])
		steps.append([6, st["d6"]])
	elif GameData.rogues():
		steps.append([3, Gear.D3])
		steps.append([4, st["d4"]])
	else:
		steps.append([4, st["d4"]])
	var wearing: int = p.sets.get(id, 0) if in_run else 0
	for stp in steps:
		var on: bool = wearing >= stp[0]
		var lines := Gfx.wrap_text("%d PIECES: %s" % [stp[0], stp[1]], 196)
		for l in lines:
			Gfx.text(ci, l, x0, y, "lime" if on else "white")
			y += 9
	if GameData.rogues():
		Gfx.text(ci, "ALL %d: %s" % [sz, Gear.D_MASTERY], x0, y, "gold")
		y += 9
		Gfx.text(ci, "FIRST TIME IN A RUN: FULL HEALTH AND A RELIC", x0, y, "gold")
	Gfx.text(ci, "PIECES FOUND %d OF %d    SETS COMPLETED %d" % [all_found, all_n, Meta.meta.get("sets_done", 0)], TB.SW / 2, 256, "grey", 1, 0.5)
	Gfx.text(ci, "UP / DOWN: CHOOSE    BACK: ESC OR TAP HERE", TB.SW / 2, 268, "dim", 1, 0.5)

# ---------- Relics page ----------
func draw_relics(ci: CanvasItem) -> void:
	var p := G.player
	Gfx.text(ci, "RELICS (%d)" % p.relics.size(), TB.SW / 2, 16, "gold", 2, 0.5)
	if p.relics.is_empty():
		Gfx.text(ci, "NONE YET. OPEN CHESTS AND VISIT SHOPS.", TB.SW / 2, 60, "grey", 1, 0.5)
	for i in p.relics.size():
		var r: Dictionary = p.relics[i]
		var x: int = 16 + (i % 2) * 216
		var y: int = 36 + (i / 2) * 13
		if y > 232:
			continue
		Gfx.at(ci, r["sprite"], x, y - 1)
		Gfx.text(ci, r["name"], x + 13, y + 1, GameData.RARITY_COL[r["rarity"]])
		var d: String = r["desc"]
		if TB.text_w(r["name"]) + TB.text_w(d) > 190 and d.length() > 34:
			d = d.substr(0, 34) + "."
		if TB.text_w(r["name"]) + TB.text_w(d) <= 195:
			Gfx.text(ci, d, x + 13 + TB.text_w(r["name"]) + 5, y + 1, "tan")
	if p.relics.size() > 30:
		Gfx.text(ci, "AND %d MORE" % (p.relics.size() - 30), TB.SW / 2, 236, "grey", 1, 0.5)
	Gfx.text(ci, "DMG %.1f  RATE %.1f/S  SHOTS %d  PIERCE %d  CRIT %d%%  SPEED %d" % [Weapons.wdmg(p), Weapons.wrate(p),
		Weapons.wcount(p), mini(Weapons.wpierce(p), 99), roundi(p.crit * 100), roundi(p.speed)], TB.SW / 2, 250, "grey", 1, 0.5)
	Gfx.text(ci, "PRESS ANY BUTTON", TB.SW / 2, 266, "dim", 1, 0.5)

# ---------- End screens ----------
func draw_end(ci: CanvasItem) -> void:
	var p := G.player
	var r := G.run_stats
	var win := G.state == &"win"
	var unwritten: bool = win and r.get("unwritten", false)   # ROADMAP 4.7 part C: the last ending of all
	var title := ("THE PAGE IS YOURS" if unwritten else "THE CRYPT IS SILENT") if win else "YOU HAVE FALLEN"
	if win and r.get("critic", false):
		title = "WELL READ"   # 20.3: the book is kept
	elif win and r.get("reader", false):
		title = "THE END"   # 14.4: the last page of all
	elif win and r.get("redactor", false):
		title = "NOTHING IS ERASED"   # 12.4: the hidden ending
	elif win and r.get("author", false):
		title = "THE STORY IS YOURS"   # 12.4: Chapter II's ending
	Gfx.text(ci, title, TB.SW / 2, 30, "gold" if win else "red", 3, 0.5)
	_sprite(p.hero["sprite"], TB.SW / 2, 92, 3, false, 1.0 if win else 0.5, Color(0, 0, 0, 0) if win else Color(1, 1, 1, 1))
	if win:
		_sprites[_sprites.size() - 1].append(p)   # the winner wears their gear
	var msg: String = p.hero["name"] + " ESCAPED WITH THE REGENT'S CROWN" + (" ON DREAD %d" % G.dread if G.dread > 0 else "") \
		if win else "SLAIN BY " + G.death_by.to_upper()
	if unwritten:
		msg = p.hero["name"] + " UNMADE THE UNWRITTEN, BY WAY OF " + ("HEAVEN" if r.get("realm", "") == "heaven" else "HELL")
	if win and r.get("critic", false):
		msg = p.hero["name"] + " SILENCED THE CRITIC. THE BOOK IS KEPT"
	elif win and r.get("reader", false):
		msg = p.hero["name"] + " TURNED THE LAST PAGE. THE READER WAS YOU"
	elif win and r.get("redactor", false):
		msg = p.hero["name"] + " ERASED THE REDACTOR. THE BOOK IS WHOLE"
	elif win and r.get("author", false):
		msg = p.hero["name"] + " OUTWROTE THE AUTHOR"
	if r.get("endless", false):   # 22.2
		msg = "THE ENDLESS DESCENT: DEPTH %d%s" % [r.get("depth", 1), "  NEW BEST!" if r.get("new_best", false) else ""]
	if r.has("daily_score"):   # 18.1
		msg = "DAILY TRIAL (%s): SCORE %d%s" % [Daily.MODS[r["daily"]][0], r["daily_score"], "  NEW BEST!" if r.get("daily_record", false) else ""]
	Gfx.text(ci, msg, TB.SW / 2, 102, "white", 1, 0.5)
	var reached := ["FLOOR REACHED", "%d - %s" % [G.floor_index + 1, GameData.floors()[G.floor_index]["name"]]]
	if r.get("endless", false):
		reached = ["DEPTH REACHED", "%d - %s (BEST %d)" % [r.get("depth", 1), GameData.floors()[G.floor_index]["name"], Endless.best()]]
	var rows := [reached, ["FOES SLAIN", r["kills"]],
		["GUARDIANS", r["bosses"]], ["SECRETS FOUND", r["secrets"]], ["TIME", fmt_time(r["time"])]]
	for i in rows.size():
		Gfx.text(ci, rows[i][0], 120, 118 + i * 11, "grey")
		Gfx.text(ci, rows[i][1], TB.SW - 120, 118 + i * 11, "white", 1, 1)
	var shown: Array = p.relics.slice(0, 30)
	for i in shown.size():
		Gfx.at(ci, shown[i]["sprite"], TB.SW / 2 - shown.size() * 6 + i * 12, 182)
	if not G.award.is_empty():
		var a := G.award
		var parts := []
		for x in a["parts"]:
			if x[1] > 0:
				parts.append("%s %d" % [x[0], x[1]])
		Gfx.text(ci, "  ".join(parts), TB.SW / 2, 200, "tan", 1, 0.5)
		var extra := "  (DREAD X%.2f)" % a["mult"] if a["mult"] > 1 else ""
		Gfx.text(ci, "+%d EMBERS%s" % [a["total"], extra], TB.SW / 2, 212, "orange", 2, 0.5)
	if G.state_t > 1:
		Gfx.text(ci, "PRESS USE TO CONTINUE", TB.SW / 2, 250, "white" if floori(G.time * 2) % 2 == 1 else "grey", 1, 0.5)

# ---------- Rogues layer: inventory ----------
## Geometry shared with the tap zones (taps.gd).
const INV_X := 108
const INV_BP_Y := 170
const INV_BELT_Y := 206
const INV_SLOT := 22
const INV_DICE := ["alter", "banish"]
const INV_CHARM_X := INV_X + 4 * (INV_SLOT + 4) + 18
const INV_DICE_Y := 273

static func inv_slot_rect(i: int) -> Rect2:
	if i < 6:
		return Rect2(INV_X + i * (INV_SLOT + 4), INV_BP_Y, INV_SLOT, INV_SLOT)
	if i >= 10:   # 37.2 the charm slots, after the belt
		return Rect2(INV_CHARM_X + (i - 10) * (INV_SLOT + 4), INV_BELT_Y, INV_SLOT, INV_SLOT)
	return Rect2(INV_X + (i - 6) * (INV_SLOT + 4), INV_BELT_Y, INV_SLOT, INV_SLOT)

func _stat_row(ci: CanvasItem, y: int, label: String, value: String, col: String) -> void:
	# 8.2: the label in its keyword colour with its little icon (TraitView.KEYWORDS / ICONS).
	var key := label.split(" ")[0]
	var ic: String = TraitView.ICONS.get(key, "") if GameData.rogues() else ""
	Gfx.text(ci, label, 10, y, TraitView.KEYWORDS[key][0] if ic != "" else "grey")
	if ic != "":
		Gfx.at(ci, ic, 10 + TB.text_w(label) + 2, y - 1)
	Gfx.text(ci, value, 92, y, col, 1, 1.0)

func draw_inventory(ci: CanvasItem) -> void:
	var p := G.player
	Gfx.text(ci, "INVENTORY", TB.SW / 2 + 40, 6, "gold", 2, 0.5)
	# Left: the stat sidebar.
	Gfx.panel(ci, 4, 6, 94, 236, "#4e4a5e", "#0f0d16")
	var y := 12
	for a in Attributes.ATTRS:
		_stat_row(ci, y, Attributes.NAMES[a], str(Attributes.value(p, a)), Attributes.COLS[a])
		y += 9
	y += 4
	var rows := [
		["DAMAGE", "%s" % TB.fmt_dmg(Weapons.wdmg(p)), "white"],
		["RATE", "%.1f/S" % Weapons.wrate(p), "white"],
		["CRIT", "%d%%" % roundi(p.crit * 100), "gold"],
		["CRIT DMG", "X%.1f" % p.crit_mult, "gold"],
		["SHOTS", str(Weapons.wcount(p)), "white"],
		["ARMOR", str(p.armor), "cyan"],
		["SPEED", str(roundi(p.speed)), "white"],
		["ROLLS", str(p.dodge_charges), "white"],
		["LUCK", str(p.luck), "lime"],
		["LEVEL", str(p.level), "lime"],
		["GOLD", str(p.gold), "gold"],
		["KILLS", str(G.run_stats.get("kills", 0)), "grey"],
	]
	if GameData.rogues():   # 38.2 the loot stats
		rows.insert(rows.size() - 3, ["MAGIC FIND", "+%d%%" % roundi(p.g("magic_find") * 100), "lime"])
		rows.insert(rows.size() - 3, ["TREASURE", "+%d%%" % roundi(p.g("treasure_find") * 100), "lime"])
	for r in rows:
		_stat_row(ci, y, r[0], r[1], r[2])
		y += 9
	if GameData.rogues():   # 8.1: the alignments
		y += 3
		for k in Alignments.KEYS:
			_stat_row(ci, y, Alignments.NAMES[k], str(Alignments.value(p, k)) + (" LEADS" if Alignments.leads(p, k) else ""), Alignments.COLS[k])
			y += 9
	if G.loop > 0:
		_stat_row(ci, y + 4, "LOOP", str(G.loop + 1), "gold")
	# Right top: weapon and equipment.
	var w: Dictionary = p.weapon
	var has_off := Gear.slots().has("offhand")   # 37.1: the offhand beside the weapon
	Gfx.panel(ci, INV_X - 4, 24, TB.SW - INV_X - (84 if has_off else 0), 34, GameData.RARITY_HEX[w["rarity"]], "#0f0d16")
	ci.draw_texture_rect(Img.t(w["sprite"]), Rect2(INV_X, 29, 24, 24), false)
	Gfx.text(ci, WeaponInfo.display_name(w), INV_X + 30, 29, GameData.RARITY_COL[w["rarity"]])
	var dr := WeaponInfo.damage_range(p, w)
	Gfx.text(ci, "%s %s  %s TO %s %s  %.1f/S" % [WeaponInfo.wtype(w), WeaponInfo.range_name(w), TB.fmt_dmg(dr[0]), TB.fmt_dmg(dr[1]),
		WeaponInfo.damage_type(w), w["rate"]], INV_X + 30, 39, "tan")
	Gfx.text(ci, "SCALING " + Attributes.grade_line(w), INV_X + 30, 48, "white")
	var gs := Gear.slots().filter(func(sl): return sl != "offhand")
	if has_off:
		var og = p.gear.get("offhand")
		var ox := TB.SW - 84
		Gfx.panel(ci, ox, 24, 80, 34, GameData.RARITY_HEX[og["rarity"]] if og != null else "#2a2838", "#0f0d16")
		Gfx.text(ci, "OFFHAND", ox + 4, 27, "dim")
		if og != null:
			ci.draw_texture_rect(Img.t(og["sprite"]), Rect2(ox + 4, 36, 16, 16), false)
			var onl := Gfx.wrap_text(og["name"], 54)
			for j in mini(2, onl.size()):
				Gfx.text(ci, onl[j], ox + 23, 37 + j * 8, GameData.RARITY_COL[og["rarity"]])
	for i in gs.size():
		var g = p.gear.get(gs[i])
		var gx := INV_X - 4 + (i % 4) * 84
		var gy := 64 + (i / 4) * 38
		Gfx.panel(ci, gx, gy, 80, 34, GameData.RARITY_HEX[g["rarity"]] if g != null else "#2a2838", "#0f0d16")
		Gfx.text(ci, Gear.SLOT_NAME[gs[i]], gx + 4, gy + 3, "dim")
		if g != null:
			ci.draw_texture_rect(Img.t(g["sprite"]), Rect2(gx + 4, gy + 12, 16, 16), false)
			var nl := Gfx.wrap_text(g["name"], 54)
			for j in mini(2, nl.size()):
				Gfx.text(ci, nl[j], gx + 23, gy + 13 + j * 8, GameData.RARITY_COL[g["rarity"]])
	# Backpack and belt.
	Gfx.text(ci, "BACKPACK", INV_X - 4, INV_BP_Y - 9, "tan")
	Gfx.text(ci, "QUICK BELT  (KEYS 1-4)", INV_X - 4, INV_BELT_Y - 9, "tan")
	if Charms.on():   # 37.2 the charm row
		var ns := Charms.slots(p)
		Gfx.text(ci, "CHARMS %d/%d" % [p.charms.size(), ns], INV_CHARM_X - 2, INV_BELT_Y - 9, "tan")
		for k in ns:
			var cr := inv_slot_rect(10 + k)
			var csel := G.inv_i == 10 + k
			var cc = p.charms[k] if k < p.charms.size() else null
			Gfx.panel(ci, cr.position.x, cr.position.y, cr.size.x, cr.size.y,
				"#f2c94c" if csel else (GameData.RARITY_HEX[cc["rarity"]] if cc != null else "#2a2838"), "#0f0d16")
			if cc != null:
				Gfx.at(ci, cc["sprite"], cr.position.x + 6, cr.position.y + 5)
	for i in 10:
		var r := inv_slot_rect(i)
		var sel := G.inv_i == i
		var it = null
		if i < 6 and i < p.backpack.size():
			it = p.backpack[i]
		var ck := ""
		if i >= 6 and i - 6 < p.belt.size():
			ck = p.belt[i - 6]
		var border: String = "#f2c94c" if sel else ("#5a5770" if it == null and ck == "" else (GameData.RARITY_HEX[it["rarity"]] if it != null else "#8b8f9c"))
		Gfx.panel(ci, r.position.x, r.position.y, r.size.x, r.size.y, border, "#1d1a28" if sel else "#0f0d16")
		if it != null:
			ci.draw_texture_rect(Img.t(it["sprite"]), Rect2(r.position + Vector2(3, 3), Vector2(16, 16)), false)
		elif ck != "":
			Gfx.sp(ci, ck, r.position.x + 11, r.position.y + 17, 1.5, 1.5)
		if i >= 6:
			Gfx.text(ci, str(i - 5), r.position.x + 2, r.position.y + 2, "dim")
	# Details of the selected slot.
	var dy := 234
	var sel_it = p.backpack[G.inv_i] if G.inv_i < 6 and G.inv_i < p.backpack.size() else null
	if G.inv_i >= 10 and G.inv_i - 10 < p.charms.size():
		sel_it = p.charms[G.inv_i - 10]   # 37.2 a worn charm
	var sel_c: String = p.belt[G.inv_i - 6] if G.inv_i >= 6 and G.inv_i - 6 < p.belt.size() else ""
	if sel_it != null:
		Gfx.text(ci, (WeaponInfo.display_name(sel_it) if sel_it["item"] == "weapon" else sel_it["name"]), INV_X - 4, dy, GameData.RARITY_COL[sel_it["rarity"]])
		var dl := TraitView.rich_lines(Live.desc(sel_it), TB.SW - INV_X - 4)
		for j in mini(2, dl.size()):
			TraitView.draw_line(ci, dl[j], INV_X - 4, dy + 9 + j * 8)
	elif sel_c != "":
		Gfx.text(ci, Consumables.KINDS[sel_c]["name"], INV_X - 4, dy, "gold")
		Gfx.text(ci, Consumables.KINDS[sel_c]["desc"], INV_X - 4, dy + 9, "white")
	else:
		Gfx.text(ci, "EMPTY", INV_X - 4, dy, "dim")
	Gfx.text(ci, "< > PICK   USE EQUIP / DRINK   ROLL DROP   MENU BACK", TB.SW / 2, 263, "grey", 1, 0.5)
	if GameData.rogues():
		Dice.draw_chips(ci, INV_DICE, INV_DICE_Y)   # 35.1: ALTER or BANISH a backpack item
