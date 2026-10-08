class_name OverlayView
extends Node2D
## Object prompts, exit prompts, the relic choice and the level-up trait pick
## (port of Render.rb draw_prompt / draw_item_prompt / draw_exit_prompt /
## draw_choice / draw_traits). RGSS drew text into an overlay bitmap, the
## selection glow additively above it, and the relic icons as sprites on top.
## That becomes three draw layers here.

var _base: DrawLayer
var _glow: DrawLayer
var _sprites: DrawLayer

func _ready() -> void:
	_base = DrawLayer.new(_paint_base)
	_glow = DrawLayer.new(_paint_glow, true)
	_sprites = DrawLayer.new(_paint_sprites)
	for l in [_base, _glow, _sprites]:
		add_child(l)

func refresh() -> void:
	for l in [_base, _glow, _sprites]:
		l.queue_redraw()

func _shade(ci: CanvasItem, a: int) -> void:
	ci.draw_rect(Rect2(0, 0, TB.SW, TB.SH), TB.rgba(13, 10, 18, a))

func _paint_base(ci: CanvasItem) -> void:
	if G.player == null:
		return
	match G.state:
		&"play":
			if G.prompt != null:
				draw_prompt(ci, G.prompt)
			elif not G.locked:
				draw_exit_prompt(ci)
		&"choice":
			_shade(ci, 215)
			draw_choice(ci)
		&"traits":
			if TraitView.active():
				TraitView.draw(ci)
			else:
				_shade(ci, 215)
				draw_traits(ci)

# ---------- Prompts ----------
func draw_exit_prompt(ci: CanvasItem) -> void:
	var p := G.player
	var best := ""
	var bd := 46.0
	for d in G.room.exits:
		var c := World.door_center(d)
		var dd := TB.dist_xy(p.x, p.y, c.x, c.y)
		if dd < bd:
			bd = dd
			best = d
	if best == "":
		return
	var c: Dictionary = G.room.exits[best]
	var pos := World.door_center(best)
	var kind: Dictionary = GameData.door_kind(c)
	var has_reward: bool = c.get("reward", "") != ""
	var lines := [kind["name"]]
	if c["type"] == "rift" and c.get("step", 0) == 0:
		lines.append("A RIFT: 3 ROOMS AND A CHAMPION")
	elif c["type"] == "mystery":
		lines.append("WHO KNOWS WHAT WAITS INSIDE")
	if has_reward:
		lines.append("REWARD: " + GameData.REWARDS[c["reward"]]["name"])
	lines.append("LOCKED. USE A KEY ON THE LOCK" if G.room.sealed.has(best) else "WALK THROUGH TO ENTER")
	var w := 0
	for l in lines:
		w = maxi(w, TB.text_w(l))
	w += 10
	var h := lines.size() * 8 + 6
	var px := clampf(roundf(pos.x - w / 2), 4, TB.SW - w - 4)
	var py := 40.0 if best == "n" else clampf(roundf(pos.y - h - 18), 34, TB.SH - h - 4)
	Gfx.panel(ci, px, py, w, h, GameData.ROOM_COL.get(c["type"], "#8b8f9c"))
	for i in lines.size():
		var col: String = kind["col"] if i == 0 else (GameData.REWARDS[c["reward"]]["col"] if has_reward and lines[i].begins_with("REWARD") else "white")
		Gfx.text(ci, lines[i], px + w / 2, py + 4 + i * 8, col, 1, 0.5)

static func _tag_names(tags: Array) -> String:
	var names := []
	for t in tags:
		names.append(Traits.FAMILIES[t]["name"])
	return ", ".join(names)

## [text, colour] lines describing a weapon or gear piece (Render.rb item_lines).
static func item_lines(it: Dictionary) -> Array:
	var p := G.player
	var lines := []
	if it["item"] == "weapon" and GameData.rogues():
		# Rogues layer: a full weapon card.
		lines.append([WeaponInfo.display_name(it), GameData.RARITY_COL[it["rarity"]]])
		lines.append([GameData.RARITY_NAME[it["rarity"]] + " " + Weapons.ARCH[it["kind"]]["name"], "grey"])
		lines.append(["- WEAPON TYPE: %s   RANGE: %s" % [WeaponInfo.wtype(it), WeaponInfo.range_name(it)], "tan"])
		lines.append(["- DAMAGE SCALING: " + Attributes.grade_line(it), "white"])
		var dr := WeaponInfo.damage_range(p, it)
		var dt := WeaponInfo.damage_type(it)
		lines.append(["- ATTACK DAMAGE: %s TO %s %s" % [TB.fmt_dmg(dr[0]), TB.fmt_dmg(dr[1]), dt], WeaponInfo.TYPE_COL.get(dt, "white")])
		var cur: Dictionary = p.weapon
		var mine: float = WeaponInfo.hit_damage(p, it) * it["rate"] * maxi(1, it["count"])
		var theirs: float = WeaponInfo.hit_damage(p, cur) * cur["rate"] * maxi(1, cur["count"])
		var sl := "- ATTACK SPEED: %.1f/S" % it["rate"]
		var diff := roundi((mine / theirs - 1) * 100) if theirs > 0 else 0
		if it["id"] != cur["id"]:
			sl += "   (%s%d%% VS YOURS)" % ["+" if diff >= 0 else "", diff]
		lines.append([sl, "lime" if diff >= 0 else "red"])
		if not it["tags"].is_empty():
			lines.append(["TAGS: " + _tag_names(it["tags"]), "tan"])
	elif it["item"] == "weapon":
		lines.append([it["name"], GameData.RARITY_COL[it["rarity"]]])
		lines.append([GameData.RARITY_NAME[it["rarity"]] + " " + Weapons.ARCH[it["kind"]]["name"] + " - " + Weapons.ARCH_DESC[it["kind"]], "grey"])
		var cur: Dictionary = p.weapon
		var dps := Weapons.weapon_dps(it)
		var cdps := Weapons.weapon_dps(cur)
		var diff := roundi((dps / cdps - 1) * 100) if cdps > 0 else 0
		var d: float = it["dmg"]
		var dl := "DAMAGE %s  RATE %.1f/S" % [str(roundi(d)) if d == roundf(d) else "%.1f" % d, it["rate"]]
		if it["id"] != cur["id"]:
			dl += "  (%s%d%% BASE POWER)" % ["+" if diff >= 0 else "", diff]
		lines.append([dl, "lime" if diff >= 0 else "red"])
		if not it["tags"].is_empty():
			lines.append(["TAGS: " + _tag_names(it["tags"]), "tan"])
	else:
		lines.append([it["name"], GameData.RARITY_COL[it["rarity"]]])
		lines.append([GameData.RARITY_NAME[it["rarity"]] + " " + Gear.SLOT_NAME[it["slot"]]
			+ ("" if it["tags"].is_empty() else " - " + _tag_names(it["tags"])), "grey"])
		var sl := []
		for kv in it["stats"]:
			var line := Gear.stat_line(kv[0], kv[1])
			if line != "":
				sl.append(line)
		if not sl.is_empty():
			lines.append(["  ".join(sl), "lime"])
		if it["set"] != null:
			var st: Dictionary = Gear.SETS[it["set"]]
			var have: int = p.sets.get(it["set"], 0)
			if st.get("size", 4) == 6:   # 14.1: a LEGENDARY set
				lines.append(["LEGENDARY %s SET (%d/6): 2: %s" % [st["name"], have, st["d2"]], "gold"])
				lines.append(["4: " + st["d4"], "gold"])
				lines.append(["6: " + st["d6"], "gold"])
				lines.append(["   + " + Gear.D_MASTERY, "gold"])
			elif GameData.rogues():   # 13.2
				lines.append(["%s SET (%d/4): 2: %s" % [st["name"], have, st["d2"]], "gold"])
				lines.append(["3: " + Gear.D3, "gold"])
				lines.append(["4: " + st["d4"], "gold"])
				lines.append(["   + " + Gear.D_MASTERY, "gold"])
			else:
				lines.append(["%s SET (%d/4): 2: %s" % [st["name"], have, st["d2"]], "gold"])
				lines.append(["4: " + st["d4"], "gold"])
	for l in (TraitView.wrap_rich(Live.desc(it), 220) if ItemShow.active() else Gfx.wrap_text(it["desc"], 220)):   # 10.1
		lines.append([l, "white"])
	return lines

func draw_item_prompt(ci: CanvasItem, o: Dictionary, it: Dictionary, price: int = -1) -> void:
	var p := G.player
	var lines := item_lines(it)
	var gslot: String = Gear.slot_for(p, it) if it["item"] == "gear" else ""
	if it["item"] == "gear" and p.gear.get(gslot) != null and p.gear[gslot]["id"] != it["id"]:
		lines.append(["REPLACES " + p.gear[gslot]["name"], "dim"])
	elif it["item"] == "weapon" and p.weapon["id"] != it["id"]:
		lines.append(["REPLACES " + p.weapon["name"], "dim"])
	lines.append(["BUY FOR %d GOLD" % price if price >= 0 else "PRESS USE TO EQUIP", "gold" if price >= 0 else "grey"])
	var w := 0
	for l in lines:
		w = maxi(w, ItemShow.line_w(l[0], l[1]) if ItemShow.active() else TB.text_w(l[0]))   # 8.2: icons count
	w = mini(w + 10, TB.SW - 8)
	var h := lines.size() * 8 + 6
	var px := clampf(roundf(o["x"] - w / 2), 4, TB.SW - w - 4)
	var py := roundf(o["y"] - 22 - h)
	if py < 32:
		py = roundf(o["y"] + 16)
	Gfx.panel(ci, px, py, w, h, GameData.RARITY_HEX[it["rarity"]])
	var left := GameData.rogues()   # Rogues layer: left-aligned item cards
	for i in lines.size():
		if ItemShow.active():
			ItemShow.rich_line(ci, lines[i][0], px + 5, py + 4 + i * 8, lines[i][1])
		else:
			Gfx.text(ci, lines[i][0], px + 5 if left else px + w / 2, py + 4 + i * 8, lines[i][1], 1, 0.0 if left else 0.5)
	if ItemShow.active():
		var all := ""
		for l in lines:
			all += " " + l[0]
		ItemShow.keyword_panels(ci, all, px, py, w)

const SHOP_TEXT := {
	"potion": ["RED POTION", "STORE IT. HEAL BUTTON HEALS 2 HEARTS"], "heart": ["HEART", "HEALS 1 HEART"],
	"bomb": ["BOMB", "BLOWS UP FOES, CRATES AND CRACKED WALLS"], "key": ["KEY", "OPENS IRON CHESTS AND VAULTS"],
	"armor": ["ARMOR", "BLOCKS ONE HIT"],
}

func draw_prompt(ci: CanvasItem, o: Dictionary) -> void:
	if o["kind"] == "item":
		return draw_item_prompt(ci, o, o["item"])
	if o["kind"] == "shop" and o.has("thing"):
		return draw_item_prompt(ci, o, o["thing"], o["price"])
	var title := ""
	var desc := ""
	var extra := ""
	if Saloon.handles(o["kind"]) or EventRooms.handles(o["kind"]) or RiftExtras.handles(o["kind"]) or Pets.handles(o["kind"]) \
			or Rex.handles(o["kind"]) or Wanderers.handles(o["kind"]):
		var sl := Saloon.prompt(o) if Saloon.handles(o["kind"]) else (EventRooms.prompt(o) if EventRooms.handles(o["kind"]) \
			else (RiftExtras.prompt(o) if RiftExtras.handles(o["kind"]) else (Pets.prompt(o) if Pets.handles(o["kind"]) \
			else (Wanderers.prompt(o) if Wanderers.handles(o["kind"]) else Rex.prompt(o)))))
		title = sl[0]
		desc = sl[1]
		extra = sl[2]
	match o["kind"]:
		"chest":
			title = "GUARDIAN'S HOARD" if o.get("boss", false) else "OLD CHEST"
			desc = "CHOOSE A RELIC"
		"ichest":
			title = "IRON CHEST"
			desc = "RARER RELICS INSIDE"
			extra = "" if o.get("free", false) else "OPEN WITH 1 KEY"
		"cchest":
			title = "CURSED CHEST"
			desc = "COSTS 1 MAX HEART. POWERFUL RELICS"
		"pedestal":
			title = o["relic"]["name"] if o["relic"] != null else "EMPTY"
			desc = o["relic"]["desc"] if o["relic"] != null else ""
		"idol":
			title = "GREEDY IDOL"
			desc = "FEED IT GOLD. IT MAY REWARD YOU"
			extra = "PAY %d GOLD" % G.price(15 + G.floor_index * 3)
		"bell":
			title = "CHALLENGE BELL"
			desc = "RING IT FOR 3 HARD WAVES AND A PRIZE"
		"alshrine":
			title = Alignments.NAMES[o["al"]] + " SHRINE"
			desc = "+1 %s. ONE SHRINE PER REST STOP" % Alignments.NAMES[o["al"]]
		"campfire":
			title = "CAMPFIRE"
			desc = "REST: HEAL HALF YOUR HEARTS, REFILL ROLLS"
		"lockdoor":
			title = "LOCKED VAULT"
			desc = "TREASURE LIES BEYOND"
			extra = "OPEN WITH 1 KEY"
		"shop":
			if o["item"] == "relic":
				title = o["relic"]["name"]
				desc = Live.desc(o["relic"])   # 10.1
			else:
				title = SHOP_TEXT[o["item"]][0]
				desc = SHOP_TEXT[o["item"]][1]
			extra = "BUY FOR %d GOLD" % o["price"]
		"altar":
			title = "BLOOD ALTAR"
			desc = "OFFER 1 HEART FOR A RELIC"
		"fountain":
			title = "CLEAR SPRING"
			desc = "HEALS YOU FULLY, ONCE"
		"anvil":
			var ap := G.player
			title = "ANVIL"
			if WeaponInfo.plus(ap.weapon) >= WeaponInfo.MAX_PLUS:
				desc = "YOUR WEAPON IS ALREADY +%d" % WeaponInfo.MAX_PLUS
			else:
				desc = "UPGRADE %s TO +%d (+8%% DAMAGE)" % [ap.weapon["name"], WeaponInfo.plus(ap.weapon) + 1]
				extra = "PAY %d GOLD" % G.price(WeaponInfo.anvil_cost(ap))
		# ---------- Event rooms ----------
		"mimicchest":
			title = "OLD CHEST"
			desc = "CHOOSE A RELIC"
		"wheel":
			title = "WHEEL OF FATE"
			desc = "SPIN FOR GEMS, HEALING, A RELIC... OR A BITE"
			extra = "PAY %d GOLD (%d SPINS LEFT)" % [G.price(12 + G.floor_index * 4), o.get("uses", 0)]
		"bloodshop":
			title = o["relic"]["name"]
			desc = Live.desc(o["relic"])   # 10.1
			extra = "PAY 1 MAX HEART"
		"well":
			title = "WISHING WELL"
			desc = "TOSS A COIN IN AND MAKE A WISH"
			extra = "PAY %d GOLD (%d WISHES LEFT)" % [G.price(8 + G.floor_index * 2), o.get("uses", 0)]
		"mirror":
			title = "DARK MIRROR"
			desc = "YOUR SHADOW WAITS INSIDE. BEAT IT FOR A RARE RELIC"
		"tome":
			title = "FORBIDDEN TOME"
			desc = "READ IT: GAIN A LEVEL, LOSE HALF A HEART"
		"bed":
			title = "A SAFE BED"
			desc = "SLEEP: HEAL 2 HEARTS"
		"jukebox":
			title = "JUKEBOX"
			desc = "A GOOD TUNE: +25% DAMAGE AND +15% SPEED FOR 60S"
			extra = "PAY %d GOLD" % G.price(10 + G.floor_index * 2)
		"brick":
			title = "LOOSE BRICK"
			desc = "IT WOBBLES WHEN TOUCHED"
		"portal":
			title = "DESCEND"
			desc = "GO DEEPER INTO THE CRYPT"
		"loopportal":
			title = "LOOP AGAIN"
			desc = "BACK TO FLOOR 1 WITH YOUR WHOLE BUILD. FOES GROW STRONGER"
		"exitportal":
			title = "LEAVE IN VICTORY"
			desc = "END THE RUN AND CLAIM YOUR EMBERS"
		"soulgate":
			title = "THE SOUL GATE: " + ("HEAVEN" if o["realm"] == "heaven" else "HELL")
			desc = "YOUR SOUL LEANS TO THE %s (LIGHT %d, DARK %d). ITS RULER WAITS" % ["LIGHT" if o["realm"] == "heaven" else "DARK", o["light"], o["dark"]]
		"pageportal":
			title = "THE UNWRITTEN PAGE"
			desc = "THE LAST BOSS OF ALL"
	var lines := [title, desc, "PRESS USE" if extra == "" else extra]
	if o.has("curse"):
		lines.insert(lines.size() - 1, "CURSED: " + EventRooms.CURSES[o["curse"]][0])
	if o["kind"] == "pedestal" and o["relic"] != null:
		lines.insert(1, GameData.RARITY_NAME[o["relic"]["rarity"]])
	if o["kind"] == "shop" and o["item"] == "relic":
		lines.insert(1, GameData.RARITY_NAME[o["relic"]["rarity"]])
	if o["kind"] == "bloodshop":
		lines.insert(1, GameData.RARITY_NAME[o["relic"]["rarity"]])
	var w := 0
	for l in lines:
		w = maxi(w, TB.text_w(l))
	w += 10
	var h := lines.size() * 8 + 6
	var px := clampf(roundf(o["x"] - w / 2), 4, TB.SW - w - 4)
	var py := roundf(o["y"] - 26 - h)
	Gfx.panel(ci, px, py, w, h, "#f2c94c" if o["kind"] == "shop" else "#8b8f9c")
	for i in lines.size():
		var col := "gold" if i == 0 else ("gold" if i == lines.size() - 1 and extra != "" else "white")
		Gfx.text(ci, lines[i], px + w / 2, py + 4 + i * 8, col, 1, 0.5)
	if extra != "":
		Gfx.text(ci, "PRESS USE", px + w / 2, py + h + 3, "grey", 1, 0.5)

# ---------- Relic choice ----------
func _choice_geom() -> Array:
	var n: int = G.choice["relics"].size()
	var w := 100 if n > 3 else 120
	var gap := 8 if n > 3 else 14
	return [n, w, gap, (TB.SW - (n * w + (n - 1) * gap)) / 2]

func draw_choice(ci: CanvasItem) -> void:
	var c := G.choice
	Gfx.text(ci, "CHOOSE A RELIC", TB.SW / 2, 40, "gold", 2, 0.5)
	var g := _choice_geom()
	for i in g[0]:
		var r: Dictionary = c["relics"][i]
		var x: int = g[3] + i * (g[1] + g[2])
		var y := 72
		var h := 140
		var w: int = g[1]
		var sel: bool = c["idx"] == i
		var oy := -4 if sel else 0
		Gfx.panel(ci, x, y + oy, w, h, "#f2c94c" if sel else GameData.RARITY_HEX[r["rarity"]], "#221a2c" if sel else "#17121e")
		var nl := Gfx.wrap_text(r["name"], w - 10)
		for j in nl.size():
			Gfx.text(ci, nl[j], x + w / 2, y + 72 + j * 8 + oy, "gold", 1, 0.5)
		Gfx.text(ci, GameData.RARITY_NAME[r["rarity"]], x + w / 2, y + h - 12 + oy, GameData.RARITY_COL[r["rarity"]], 1, 0.5)
		TraitView.draw_rich(ci, Live.desc(r), x + w / 2, y + 94 + oy, w - 14, 0.5)   # 8.2: keywords in colour
	Gfx.text(ci, "< >  CHOOSE     USE  TAKE", TB.SW / 2, 236, "grey", 1, 0.5)

# ---------- Trait pick ----------
func _traits_x0(n: int) -> int:
	return (TB.SW - (n * 128 + (n - 1) * 10)) / 2

func draw_traits(ci: CanvasItem) -> void:
	var c := G.tchoice
	var p := G.player
	Gfx.text(ci, "LEVEL %d!" % p.level, TB.SW / 2, 20, "lime", 2, 0.5)
	Gfx.text(ci, "CHOOSE A TRAIT", TB.SW / 2, 38, "gold", 1, 0.5)
	var n: int = c["opts"].size()
	var w := 128
	var x0 := _traits_x0(n)
	for i in n:
		var t: Dictionary = c["opts"][i]
		var x: int = x0 + i * (w + 10)
		var y := 58
		var h := 150
		var sel: bool = c["idx"] == i
		var fam: Dictionary = Traits.FAMILIES[t["fam"]]
		var oy := -4 if sel else 0
		var border: String = fam["hex"]
		if t["new"] and t["rarity"] == "cursed":
			border = Traits.RARITY["cursed"]["hex"]
		Gfx.panel(ci, x, y + oy, w, h, "#f2c94c" if sel else border, "#221a2c" if sel else ("#1c1022" if t["new"] and t["rarity"] == "cursed" else "#17121e"))
		Gfx.text(ci, fam["name"] + (" CAPSTONE" if t["cap"] else ""), x + w / 2, y + 8 + oy, fam["col"], 1, 0.5)
		if t["new"]:
			var rar: Dictionary = Traits.RARITY[t["rarity"]]
			Gfx.text(ci, rar["name"], x + w / 2, y + h - 10 + oy, rar["col"], 1, 0.5)
		var nl := Gfx.wrap_text(t["name"], w - 10)
		for j in nl.size():
			Gfx.text(ci, nl[j], x + w / 2, y + 22 + j * 12 + oy, "gold", 2, 0.5)
		var rank: int = p.traits.get(t["id"], 0)
		var pips := []
		for k in t["max"]:
			pips.append("*" if k < rank else ("+" if k == rank else "-"))
		Gfx.text(ci, "RANK " + " ".join(pips), x + w / 2, y + 58 + oy, "tan", 1, 0.5)
		var dl := TraitView.rich_lines(t["desc"], w - 14)   # 8.2: keywords in colour
		for j in dl.size():
			TraitView.draw_line(ci, dl[j], x + w / 2 - TraitView.line_w(dl[j]) / 2.0, y + 74 + j * 9 + oy)
		var have: int = p.fam.get(t["fam"], 0)
		if t["fam"] != "core":
			var nxt := 0
			for v in [2, 4, 6]:
				if v > have:
					nxt = v
					break
			if nxt > 0:
				var bonus := Traits.bonus_name(t["fam"], nxt / 2 - 1)
				Gfx.text(ci, "%s %d/%d:" % [fam["name"], have + 1, nxt], x + w / 2, y + 116 + oy, fam["col"], 1, 0.5)
				var bl := Gfx.wrap_text(bonus, w - 14)
				for j in mini(2, bl.size()):
					Gfx.text(ci, bl[j], x + w / 2, y + 126 + j * 8 + oy, "grey", 1, 0.5)
	var reroll := "REROLL (%d LEFT)" % p.rerolls if p.rerolls > 0 else "REROLL (%d GOLD)" % G.reroll_cost()
	Gfx.text(ci, "< >  CHOOSE     USE  TAKE     MENU  " + reroll, TB.SW / 2, 226, "grey", 1, 0.5)
	if p.pending > 1:
		Gfx.text(ci, "%d MORE LEVEL-UPS WAITING" % (p.pending - 1), TB.SW / 2, 240, "lime", 1, 0.5)

# ---------- Glow and sprite layers ----------
func _paint_glow(ci: CanvasItem) -> void:
	match G.state:
		&"choice":
			var g := _choice_geom()
			var x: int = g[3] + G.choice["idx"] * (g[1] + g[2])
			Gfx.at(ci, "glow_white", x + g[1] / 2 - 24, 72 + 20)
		&"traits":
			if TraitView.active():
				return
			var x: int = _traits_x0(G.tchoice["opts"].size()) + G.tchoice["idx"] * 138
			Gfx.at(ci, "glow_white", x + 128 / 2 - 24, 58 + 4)

func _paint_sprites(ci: CanvasItem) -> void:
	if G.state != &"choice":
		return
	var g := _choice_geom()
	for i in g[0]:
		var r: Dictionary = G.choice["relics"][i]
		var x: int = g[3] + i * (g[1] + g[2])
		var sel: bool = G.choice["idx"] == i
		var oy := roundf(sin(G.time * 5) * 2) - 4 if sel else 0.0
		Gfx.sp(ci, r["sprite"], x + g[1] / 2, 72 + 58 + oy, 4, 4)
