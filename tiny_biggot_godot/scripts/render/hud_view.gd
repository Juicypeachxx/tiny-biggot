class_name HudView
extends Node2D
## In-run HUD (port of Render.rb draw_hud, draw_minimap and the banner).
## Hearts and armour, potions, gold, roll charges, bombs, keys, embers, XP bar
## and level, floor name, minimap, relic strip, weapon and gear slots, boss bar
## and toasts. The banner fades in and out over the room.

func refresh() -> void:
	queue_redraw()

static func world_state() -> bool:
	match G.state:
		&"play", &"pause", &"relics", &"choice", &"traits", &"traitlist", &"gearpage":
			return true
		&"options":
			return G.opt_from == &"pause"
	return false

func _draw() -> void:
	var p := G.player
	if p == null or G.room == null or not world_state():
		return
	# Hearts and armour.
	for i in p.max_hp / 2:
		var v := p.hp - i * 2
		Gfx.at(self, "heart_" + ("full" if v >= 2 else ("half" if v == 1 else "empty")), 5 + i * 9, 6)
	var ax := 5 + (p.max_hp / 2) * 9
	for i in p.armor:
		Gfx.at(self, "heart_armor", ax + i * 9, 6)
	# Potions, gold, roll charges, bombs, keys, embers.
	var x := 5
	for i in p.max_potions:
		Gfx.at(self, "potion", x + 1, 18, 1.0 if i < p.potions else 64 / 255.0)
		x += 9
	x += 4
	Gfx.at(self, "coin", x + 1, 19)
	Gfx.text(self, p.gold, x + 8, 18, "gold")
	x += 14 + TB.text_w(str(p.gold))
	for i in p.dodge_charges:
		var full := i < p.charges
		draw_rect(Rect2(x - 1, 18, 7, 7), TB.c("#140f1c"))
		draw_rect(Rect2(x, 19, 5, 5), TB.c("#6fd3e0" if full else "#4e4a5e"))
		if not full and i == p.charges:
			var h := roundi(5 * p.charge_t / p.dodge_cd)
			if h > 0:
				draw_rect(Rect2(x, 24 - h, 5, h), TB.c("#4d9be6"))
		x += 8
	x += 6
	for pair in [["bomb", p.bombs], ["key", p.keys]]:
		var ic := Img.t(pair[0])
		Gfx.at(self, pair[0], x, 25 - ic.get_height())
		x += ic.get_width() + 2
		x += Gfx.text(self, pair[1], x, 18, "white") + 6
	if p.embers_found > 0:
		Gfx.at(self, "ember", x, 19)
		x += 7
		Gfx.text(self, p.embers_found, x, 18, "orange")
	# Toast.
	if not G.msg.is_empty():
		var w := TB.text_w(G.msg["text"]) + 10
		Gfx.panel(self, (TB.SW - w) / 2, 242, w, 11, "#4e4a5e")
		Gfx.text(self, G.msg["text"], TB.SW / 2, 245, G.msg["col"], 1, 0.5)
	# XP bar and level.
	var need := GameData.xp_needed(p.level)
	draw_rect(Rect2(5, 28, 82, 3), TB.c("#140f1c"))
	draw_rect(Rect2(6, 29, roundf(80.0 * p.xp / need), 1), TB.c("#b8e05a"))
	Gfx.text(self, "LV %d" % p.level, 90, 27, "lime")
	# Special ability meter (step-6 heroes): fills while it recharges.
	if Abilities.has_special(p):
		var sp: Dictionary = p.hero["special"]
		var k := Abilities.charge(p)
		var ready := k >= 1.0
		var col: String = sp.get("col", "#f2c94c")
		draw_rect(Rect2(5, 34, 52, 5), TB.c("#140f1c"))
		draw_rect(Rect2(6, 35, roundf(50.0 * k), 3), TB.c(col) if ready or floori(G.time * 2) % 2 == 0 else TB.ca(col, 160))
		if ready:
			draw_rect(Rect2(6, 35, 50, 1), Color(1, 1, 1, 0.5 + 0.5 * sin(G.time * 8)))
		Gfx.text(self, sp["name"] if ready else "%ds" % ceili(p.special_cd), 60, 34, "gold" if ready else "dim")
	# Racketeer heat meter (step 6): one pip per level.
	if p.hero.get("hud", "") == "heat":
		Gfx.text(self, "HEAT", 116, 27, "orange" if p.heat > 0 else "dim")
		for k in p.heat_max:
			draw_rect(Rect2(134 + k * 5, 28, 4, 4), TB.c("#e8873a" if k < p.heat else "#2a2838"))
	# Floor name and minimap.
	var fl: Dictionary = GameData.floors()[G.floor_index]
	Gfx.text(self, fl["name"], TB.SW / 2, 4, fl["accent"], 1, 0.5)
	Gfx.text(self, "%d/%d" % [G.floor_index + 1, GameData.floors().size()], TB.SW / 2, 12, "grey", 1, 0.5)
	_minimap()
	# Relic strip (last 24).
	var rel: Array = p.relics.slice(maxi(0, p.relics.size() - 24))
	for i in rel.size():
		Gfx.at(self, rel[i]["sprite"], 4 + i * 11, TB.SH - 13, 220 / 255.0)
	# Weapon and gear slots.
	if p.weapon != null:
		Gfx.panel(self, TB.SW - 20, TB.SH - 22, 16, 16, GameData.RARITY_HEX[p.weapon["rarity"]])
		Gfx.at(self, p.weapon["sprite"], TB.SW - 18, TB.SH - 20)
		for i in Gear.SLOTS.size():
			var gp = p.gear.get(Gear.SLOTS[i])
			var gx := TB.SW - 34 - (3 - i) * 12
			draw_rect(Rect2(gx, TB.SH - 16, 11, 11), TB.c(GameData.RARITY_HEX[gp["rarity"]] if gp != null else "#2a2838"))
			draw_rect(Rect2(gx + 1, TB.SH - 15, 9, 9), TB.c("#17121e"))
			if gp != null:
				draw_texture_rect(Img.t(gp["sprite"]), Rect2(gx + 1, TB.SH - 15, 9, 9), false)
	# Boss bar.
	var bo := G.boss
	if bo != null and bo.hp > 0:
		var w := 220
		var bx := (TB.SW - w) / 2
		var by := TB.SH - 12
		Gfx.panel(self, bx - 2, by - 2, w + 4, 8, "#8a2a33")
		draw_rect(Rect2(bx, by, w, 4), TB.c("#4e4a5e"))
		var fw := ceilf(w * bo.hp / bo.max_hp)
		if fw > 0:
			draw_rect(Rect2(bx, by, fw, 4), TB.c("#d8443c"))
			draw_rect(Rect2(bx, by, fw, 1), TB.c("#ff8a70"))
		Gfx.text(self, bo.d["name"], TB.SW / 2, by - 9, "white", 1, 0.5)
	_banner()

func _minimap() -> void:
	var f := G.floor_d
	var n: int = f["total"]
	var w := 7
	var ox := TB.SW - 6 - (n + 1) * w
	var oy := 4
	for i in n + 1:
		var x := ox + i * w
		if i == n:
			Gfx.at(self, "icon_skull", x, oy - 1, 1.0 if i <= f["depth"] else 150 / 255.0)
			continue
		var col := "#5c5a78" if i < f["depth"] else ("#f4ecd8" if i == f["depth"] else "#2a2838")
		if i > 0 and i - 1 < f["path"].size() and i <= f["depth"]:
			col = GameData.ROOM_COL.get(f["path"][i - 1]["type"], col)
		draw_rect(Rect2(x, oy, w - 2, 5), TB.c("#140f1c"))
		draw_rect(Rect2(x + 1, oy + 1, w - 4, 3), TB.c(col))
	Gfx.text(self, "ROOM %d/%d" % [f["depth"], n], TB.SW - 6, 12, "grey", 1, 1)

func _banner() -> void:
	var bn := G.banner
	if bn.is_empty():
		return
	var a := clampf(minf(bn["t"], 2.6 - bn["t"]) * 4, 0.0, 1.0)
	var sub: String = bn["sub"]
	draw_rect(Rect2(0, 96, TB.SW, 26 if sub.is_empty() else 36), TB.rgba(13, 10, 18, roundi(190 * a)))
	Gfx.text(self, bn["text"], TB.SW / 2, 96 + 5, "gold", 2, 0.5, true, a)
	if not sub.is_empty():
		Gfx.text(self, sub, TB.SW / 2, 96 + 22, "white", 1, 0.5, true, a)
