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
		&"options":
			if G.opt_from == &"title":
				_backdrop(ci, true)
			else:
				_shade(ci, 210)
			draw_options(ci)
		&"pause":
			_shade(ci, 210)
			draw_pause(ci)
		&"traitlist":
			_shade(ci, 220)
			draw_traitlist(ci)
		&"gearpage":
			_shade(ci, 222)
			draw_gearpage(ci)
		&"relics":
			_shade(ci, 220)
			draw_relics(ci)
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
	for h in GameData.HEROES:
		if G.hero_unlocked(h):
			shown.append(h)
	for i in shown.size():
		_sprite(shown[i]["sprite"], TB.SW / 2 - (shown.size() - 1) * 18 + i * 36, 128 + (-1 if floori(t * 3 + i) % 2 == 1 else 0),
			2, i >= shown.size() / 2)
	for i in G.TITLE_ITEMS.size():
		_menu_item(ci, G.TITLE_ITEMS[i], TB.SW / 2, 142 + i * 17, i, 2, 170)
	var m := Meta.meta
	var line := "EMBERS %d    RUNS %d    WINS %d    DEEPEST FLOOR %d" % [m["embers"], m["runs"], m["wins"], m["best"]]
	Gfx.at(ci, "ember", TB.SW / 2 - TB.text_w(line) / 2 - 8, 250)
	Gfx.text(ci, line, TB.SW / 2, 251, "grey", 1, 0.5)
	Gfx.text(ci, "PRESS USE TO SELECT", TB.SW / 2, 268, "dim", 1, 0.5)

# ---------- Hero select ----------
func draw_hero(ci: CanvasItem) -> void:
	var t := G.time
	Gfx.text(ci, "CHOOSE YOUR DELVER", TB.SW / 2, 10, "gold", 2, 0.5)
	var n := GameData.HEROES.size()
	var w := 68
	var gap := 4
	var x0 := (TB.SW - (n * w + (n - 1) * gap)) / 2
	for i in n:
		var h: Dictionary = GameData.HEROES[i]
		var x := x0 + i * (w + gap)
		var y := 30
		var sel := G.hero_index == i
		var open := G.hero_unlocked(h)
		Gfx.panel(ci, x, y, w, 66, "#e8873a" if sel else "#4e4a5e", "#221a2c" if sel else "#17121e")
		if sel and open:
			_glows.append(["glow_torch", x + w / 2 - 36, y - 4])
		_sprite(h["sprite"], x + w / 2, y + 48 + (-2 if sel and floori(t * 4) % 2 == 1 else 0), 3, false, 1.0,
			Color(0, 0, 0, 0) if open else TB.rgba(20, 15, 28, 255))
		Gfx.text(ci, h["name"].replace("THE ", "") if open else "LOCKED", x + w / 2, y + 54, "gold" if sel else ("tan" if open else "dim"), 1, 0.5)
	var h: Dictionary = GameData.HEROES[G.hero_index]
	var open := G.hero_unlocked(h)
	Gfx.panel(ci, 40, 104, TB.SW - 80, 118, "#4e4a5e", "#17121e")
	Gfx.text(ci, h["name"], TB.SW / 2, 112, "gold" if open else "dim", 2, 0.5)
	Gfx.text(ci, h["weapon"], TB.SW / 2, 128, "grey", 1, 0.5)
	for k in h["hp"] / 2:
		Gfx.at(ci, "heart_full", roundf(TB.SW / 2 - (h["hp"] / 2) * 4.5 + k * 9), 138)
	var bl := Gfx.wrap_text(h["blurb"], TB.SW - 120)
	for j in bl.size():
		Gfx.text(ci, bl[j], TB.SW / 2, 152 + j * 9, "white", 1, 0.5)
	var hw := Weapons.by_id(Weapons.HERO_WEAPON[h["id"]])
	Gfx.text(ci, "STARTS WITH %s   DAMAGE %s   RATE %.1f/S   SPEED %d" % [hw["name"], _fmt_num(hw["dmg"]), hw["rate"], h["speed"]],
		TB.SW / 2, 176, "tan", 1, 0.5)
	if not open:
		Gfx.text(ci, "UNLOCK AT THE EMBER SHRINE FOR %d EMBERS" % h["cost"], TB.SW / 2, 196, "orange", 1, 0.5)
	var mx: int = Meta.meta.get("dread_max", 0)
	if mx > 0:
		var d := mini(Meta.meta.get("dread", 0), mx)
		Gfx.text(ci, "DREAD %d: %s" % [d, GameData.DREAD_DESC[d]], TB.SW / 2, 208, "red" if d > 0 else "grey", 1, 0.5)
		Gfx.text(ci, "UP/DOWN CHANGES DREAD.  MORE DREAD, MORE EMBERS", TB.SW / 2, 230, "dim", 1, 0.5)
	else:
		Gfx.text(ci, "WIN A RUN TO UNLOCK DREAD LEVELS", TB.SW / 2, 230, "dim", 1, 0.5)
	Gfx.text(ci, "< >  CHOOSE     USE  BEGIN     ROLL  SKILL TREE     MENU  BACK", TB.SW / 2, 262, "grey", 1, 0.5)

# ---------- Ember shrine ----------
func draw_shrine(ci: CanvasItem) -> void:
	Gfx.text(ci, "EMBER SHRINE", TB.SW / 2, 10, "orange", 2, 0.5)
	var line := "%d EMBERS" % Meta.meta["embers"]
	Gfx.at(ci, "ember", TB.SW / 2 - TB.text_w(line) / 2 - 8, 28)
	Gfx.text(ci, line, TB.SW / 2, 29, "gold", 1, 0.5)
	var sel := G.shrine_i
	var ul := GameData.UNLOCKS
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
func draw_codex(ci: CanvasItem) -> void:
	var rel := Relics.all()
	var found_d: Dictionary = Meta.meta["found"]
	var found := 0
	for r in rel:
		if found_d.has(r["id"]):
			found += 1
	Gfx.text(ci, "RELIC CODEX", TB.SW / 2, 10, "gold", 2, 0.5)
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
	Gfx.text(ci, "ARROWS  BROWSE     MENU  BACK", TB.SW / 2, 262, "grey", 1, 0.5)

# ---------- How to play ----------
func draw_howto(ci: CanvasItem) -> void:
	Gfx.text(ci, "HOW TO PLAY", TB.SW / 2, 16, "gold", 2, 0.5)
	var lines := [
		["GOAL", "DESCEND 6 FLOORS AND SLAY EACH GUARDIAN."],
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
		["", "Q HEAL. ESC MENU."],
		["PAD", "STICKS MOVE AND AIM. B ROLL. A USE. X HEAL."],
	]
	for i in lines.size():
		Gfx.text(ci, lines[i][0], 40, 44 + i * 15, "orange")
		Gfx.text(ci, lines[i][1], 96, 44 + i * 15, "white")
	Gfx.text(ci, "ROLLING MAKES YOU UNTOUCHABLE FOR A MOMENT.", TB.SW / 2, 248, "cyan", 1, 0.5)
	Gfx.text(ci, "PRESS ANY BUTTON", TB.SW / 2, 266, "dim", 1, 0.5)

# ---------- Options and pause ----------
func draw_options(ci: CanvasItem) -> void:
	Gfx.text(ci, "OPTIONS", TB.SW / 2, 50, "gold", 2, 0.5)
	for i in G.OPTION_LIST.size():
		var label: String = G.OPTION_LIST[i][0]
		var key: String = G.OPTION_LIST[i][1]
		var txt := "%s:  %s" % [label, "ON" if Meta.opts[key] else "OFF"] if key != "" else label
		_menu_item(ci, txt, TB.SW / 2, 86 + i * 22, i, 2, 260)

func draw_pause(ci: CanvasItem) -> void:
	Gfx.text(ci, "PAUSED", TB.SW / 2, 44, "gold", 3, 0.5)
	for i in G.PAUSE_ITEMS.size():
		var label: String = G.PAUSE_ITEMS[i]
		if i == 5 and G.quit_armed:
			label = "SURE? PRESS AGAIN"
		_menu_item(ci, label, TB.SW / 2, 86 + i * 22, i, 2, 260)
	var p := G.player
	Gfx.text(ci, "TIME %s   KILLS %d   LEVEL %d" % [fmt_time(G.run_stats["time"]), G.run_stats["kills"], p.level],
		TB.SW / 2, 214, "grey", 1, 0.5)

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
	Gfx.text(ci, "PRESS ANY BUTTON", TB.SW / 2, 266, "dim", 1, 0.5)

# ---------- Skill tree ----------
func draw_tree(ci: CanvasItem) -> void:
	var h: Dictionary = GameData.HEROES[G.tree_hero]
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
			var border := "#f2c94c" if sel else ("#63b84f" if got else ("#8b8f9c" if avail else "#2a2838"))
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
	Gfx.text(ci, "TAGS: " + tags + "  (EACH MATCHING TRAIT RANK +8%, GEAR PIECE +12%)", 56, 70, "tan")
	var dl := Gfx.wrap_text(w["desc"], TB.SW - 90)
	if not dl.is_empty():
		Gfx.text(ci, dl[0], 56, 80, "white")
	for i in Gear.SLOTS.size():
		var sl: String = Gear.SLOTS[i]
		var g = p.gear.get(sl)
		var x: int = 16 + (i % 2) * 212
		var y: int = 100 + (i / 2) * 58
		Gfx.panel(ci, x, y, 204, 52, GameData.RARITY_HEX[g["rarity"]] if g != null else "#2a2838", "#17121e")
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
			var gl := Gfx.wrap_text(g["desc"], 166)
			for j in mini(2, gl.size()):
				Gfx.text(ci, gl[j], x + 32, y + 33 + j * 8, "white")
		else:
			Gfx.text(ci, "EMPTY", x + 32, y + 22, "dim")
	var y := 220
	for id in p.sets:
		var n: int = p.sets[id]
		if n <= 0:
			continue
		var st: Dictionary = Gear.SETS[id]
		Gfx.text(ci, "%s %d/4:  2: %s   4: %s" % [st["name"], n, st["d2"], st["d4"]], TB.SW / 2, y, "gold" if n >= 2 else "dim", 1, 0.5)
		y += 9
	Gfx.text(ci, "PRESS ANY BUTTON", TB.SW / 2, 266, "dim", 1, 0.5)

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
	Gfx.text(ci, "THE CRYPT IS SILENT" if win else "YOU HAVE FALLEN", TB.SW / 2, 30, "gold" if win else "red", 3, 0.5)
	_sprite(p.hero["sprite"], TB.SW / 2, 92, 3, false, 1.0 if win else 0.5, Color(0, 0, 0, 0) if win else Color(1, 1, 1, 1))
	var msg: String = p.hero["name"] + " ESCAPED WITH THE REGENT'S CROWN" + (" ON DREAD %d" % G.dread if G.dread > 0 else "") \
		if win else "SLAIN BY " + G.death_by.to_upper()
	Gfx.text(ci, msg, TB.SW / 2, 102, "white", 1, 0.5)
	var rows := [["FLOOR REACHED", "%d - %s" % [G.floor_index + 1, GameData.FLOORS[G.floor_index]["name"]]], ["FOES SLAIN", r["kills"]],
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
