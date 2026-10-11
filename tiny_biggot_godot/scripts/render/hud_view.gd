class_name HudView
extends Node2D
## In-run HUD (port of Render.rb draw_hud, draw_minimap and the banner).
## Hearts and armour, potions, gold, roll charges, bombs, keys, embers, XP bar
## and level, floor name, minimap, relic strip, weapon and gear slots, boss bar
## and toasts. The banner fades in and out over the room.

## The HUD is many small draws (hearts, counters, minimap, relic strip, gear)
## that almost never change from one tick to the next, so it is only redrawn
## when something it shows has changed: refresh() compares a short list of
## the values _draw reads (rounded the way they are drawn) with last tick's.
## The two parts that animate on their own, the special meter and the room
## banner, live in a small child layer that is redrawn every tick.
var _sig: Array = []
var _ticks := 0
var _anim: DrawLayer

func _ready() -> void:
	_anim = DrawLayer.new(_paint_anim)
	add_child(_anim)

func refresh() -> void:
	_ticks += 1
	var sig := _signature()
	# Every half second it is redrawn regardless, so nothing can stay stale.
	if sig != _sig or _ticks % 30 == 0:
		_sig = sig
		queue_redraw()
	_anim.queue_redraw()

## Everything the static part of the HUD shows.
func _signature() -> Array:
	var p := G.player
	if p == null or G.room == null or not world_state():
		return [perf_line, perf_line2, Meta.opts.get("fps", false)]
	var f := G.floor_d
	var bo := _bar_foe()
	var gear := []
	for sl in Gear.slots():
		var g = p.gear.get(sl)
		gear.append(g["id"] if g != null else "")
	return [perf_line, perf_line2, Meta.opts.get("fps", false), p.max_hp, p.hp, p.armor, p.max_potions, p.potions, p.gold, p.gourd, Gourd.max_sips(p),
		p.dodge_charges, p.charges, roundi(5 * p.charge_t / p.dodge_cd), p.bombs, p.keys, p.embers_found, p.rerolls, p.alters, p.banishes, p.drinks.duplicate(true),
		G.msg.get("text", ""), G.msg.get("col", ""), p.level, roundf(80.0 * p.xp / GameData.xp_needed(p.level)),
		p.hero.get("hud", ""), p.heat, p.heat_max, p.tempo, p.tempo_max, G.floor_index, G.loop, f["depth"], f["total"], f["path"].size(),
		int(G.run_stats.get("time", 0.0)), p.belt.duplicate(), p.relics.size(),
		p.relics[p.relics.size() - 1]["id"] if not p.relics.is_empty() else "",
		p.weapon["sprite"] if p.weapon != null else "", p.weapon["rarity"] if p.weapon != null else "", gear,
		ceilf(220.0 * bo.hp / bo.max_hp) if bo != null and bo.hp > 0 else -1.0, bo.d["name"] if bo != null else ""]

## The parts that animate every tick: the special ability meter and the banner.
func _paint_anim(ci: CanvasItem) -> void:
	var p := G.player
	if p == null or G.room == null or not world_state():
		return
	# Special ability meter (step-6 heroes): fills while it recharges.
	if Abilities.has_special(p):
		var sp: Dictionary = p.hero["special"]
		var k := Abilities.charge(p)
		var ready := k >= 1.0
		var col: String = sp.get("col", "#f2c94c")
		ci.draw_rect(Rect2(5, 34, 52, 5), TB.c("#140f1c"))
		ci.draw_rect(Rect2(6, 35, roundf(50.0 * k), 3), TB.c(col) if ready or floori(G.time * 2) % 2 == 0 else TB.ca(col, 160))
		if ready:
			ci.draw_rect(Rect2(6, 35, 50, 1), Color(1, 1, 1, 0.5 + 0.5 * sin(G.time * 8)))
		Gfx.text(ci, sp["name"] if ready else "%ds" % ceili(p.special_cd), 60, 34, "gold" if ready else "dim")
	# Gaolbird rally: the health at stake pulses in gold over the lost hearts.
	if p.rally_t > 0 and p.rally_hp > 0:
		var a := 0.7 + 0.3 * sin(G.time * (22.0 if Rally.time_left(p) < 0.35 else 11.0))
		var tex := Img.t("heart_rally")
		var want := mini(p.hp + p.rally_hp, p.max_hp)
		for i in p.max_hp / 2:
			var have := clampi(p.hp - i * 2, 0, 2)
			var ghost := clampi(want - i * 2, 0, 2)
			if ghost <= have:
				continue
			# Left half is columns 0-3, right half 4-8 (the heart sprite's own split).
			var x0 := 0 if have == 0 else 4
			var x1 := 9 if ghost == 2 else 4
			ci.draw_texture_rect_region(tex, Rect2(5 + i * 9 + x0, 6, x1 - x0, 8), Rect2(x0, 0, x1 - x0, 8), Color(1, 1, 1, a))
	_banner(ci)

static func world_state() -> bool:
	match G.state:
		&"play", &"pause", &"relics", &"choice", &"traits", &"traitlist", &"gearpage", &"inventory", &"fishing":
			return true
		&"options", &"keys":
			return G.opt_from == &"pause"
	return false

## SHOW FPS option: frame rate, logic and drawing ms, draw calls (set by main.gd).
static var perf_line := ""
static var perf_line2 := ""   # 47.6: the logic's costliest parts (main.gd)

func _draw() -> void:
	if (Meta.opts.get("fps", false) or DebugArgs.has("perf")) and perf_line != "":
		Gfx.text(self, perf_line, 4, TB.SH - 26, "lime", 1)
		if perf_line2 != "":
			Gfx.text(self, perf_line2, 4, TB.SH - 35, "lime", 1)
	var p := G.player
	if p == null or G.room == null or not world_state():
		return
	# Hearts and armour.
	for i in p.max_hp / 2:
		var v := p.hp - i * 2
		Gfx.at(self, "heart_" + ("full" if v >= 2 else ("half" if v == 1 else "empty")), 5 + i * 9, 6)
	var ax := 5 + (p.max_hp / 2) * 9
	for i in p.armor:
		if GameData.rogues():
			_shield(ax + i * 9, 6)   # Rogues layer: armor as shields
		else:
			Gfx.at(self, "heart_armor", ax + i * 9, 6)
	# Potions, gold, roll charges, bombs, keys, embers.
	var x := 5
	x = int(Gourd.draw_hud(self, p, x, 17))   # 47.1: THE GOURD's sips first
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
		x += TB.text_w(str(p.embers_found)) + 6
	if GameData.rogues():
		Dice.draw_hud(self, p, x + 2, 18)   # 35.1: REROLL, ALTER and BANISH dice
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
	Arsenal.draw_hud(self)   # the piggy bank's fill
	if Pets.active(p):
		# The pet: its picture, name and level.
		Gfx.sp(self, "pet_" + p.pet, 12, 47)
		Gfx.text(self, "%s %s" % [Pets.pet_name(p.pet), "*".repeat(p.pet_lv)], 20, 38, "gold")
	if GameData.rogues() and Meta.opts.get("statcol", true):
		_stat_column(p, 52 if Pets.active(p) else 38)
	# (The special ability meter is drawn by _paint_anim: it animates every tick.)
	# Racketeer heat meter (step 6): one pip per level.
	if p.hero.get("hud", "") == "heat":
		Gfx.text(self, "HEAT", 116, 27, "orange" if p.heat > 0 else "dim")
		for k in p.heat_max:
			draw_rect(Rect2(134 + k * 5, 28, 4, 4), TB.c("#e8873a" if k < p.heat else "#2a2838"))
	# Gaolbird tempo meter: one pip per point, brighter toward the top; all lit in full flight.
	if p.hero.get("hud", "") == "tempo":
		var top := Tempo.full(p)
		Gfx.text(self, "TEMPO", 116, 27, "pink" if p.tempo > 0 else "dim")
		for k in p.tempo_max:
			var on := k < p.tempo
			draw_rect(Rect2(138 + k * 5, 26, 5, 7), TB.c("#140f1c"))
			draw_rect(Rect2(139 + k * 5, 27, 3, 5), TB.c(("#ffffff" if top else ("#e86fb4" if k >= 5 else "#a35bd6")) if on else "#2a2838"))
	# Floor name and minimap.
	var fl: Dictionary = GameData.floors()[G.floor_index]
	Gfx.text(self, fl["name"], TB.SW / 2, 4, fl["accent"], 1, 0.5)
	Gfx.text(self, "%d/%d" % [G.floor_index + 1, GameData.floors().size()] + ("  LOOP %d" % (G.loop + 1) if G.loop > 0 else ""),
		TB.SW / 2, 12, "gold" if G.loop > 0 else "grey", 1, 0.5)
	_minimap()
	# 30.1: each sworn oath's vow, under the map (orange while it counts, gold once awakened).
	if not p.vows.is_empty():
		var vy := 50
		for ln in Oaths.hud_lines(p):
			Gfx.text(self, ln[0], TB.SW - 6, vy, ln[1], 1, 1)
			vy += 9
	# The saloon's bounty, while one is on (under the floor name).
	var bounty := Saloon.hud_line()
	if bounty != "":
		Gfx.text(self, "BOUNTY: " + bounty, TB.SW / 2, 20, "gold", 1, 0.5)
	var parcel := EventRooms.hud_line()
	if parcel != "":
		Gfx.text(self, parcel, TB.SW / 2, 28 if bounty != "" else 20, "cyan", 1, 0.5)
	# Rogues layer: the quick belt, under the floor name (keys 1-4, or tap).
	if GameData.rogues():
		for i in Consumables.BELT_SIZE:
			var r := belt_rect(i)
			draw_rect(r, TB.c("#5a5770"))
			draw_rect(r.grow(-1), TB.c("#0f0d16"))
			if i < p.belt.size():
				Gfx.sp(self, p.belt[i], r.get_center().x, r.end.y - 1)
			else:
				Gfx.text(self, str(i + 1), r.position.x + 4, r.position.y + 3, "dim")
		if p.tipsy >= 1.0:   # 33.2 THE TAVERN: how tipsy, beside the belt
			var r4 := belt_rect(Consumables.BELT_SIZE - 1)
			Gfx.text(self, "TIPSY %d" % int(p.tipsy), r4.end.x + 4, r4.position.y + 4, "gold" if p.tipsy >= Tipsy.VERY else "orange")
		if not p.drinks.is_empty():   # 36.3: the drink buffs on, with their rooms left, under the belt
			Food.draw_hud(self, p, belt_rect(0).position.x, belt_rect(0).end.y + 3)
		if not p.infusions.is_empty():   # 44: then the infusions on
			Infusions.draw_hud(self, p, belt_rect(0).position.x + 22 * p.drinks.size() + (4 if not p.drinks.is_empty() else 0), belt_rect(0).end.y + 3)
	# Relic strip (last 24).
	var rel: Array = p.relics.slice(maxi(0, p.relics.size() - 24))
	for i in rel.size():
		Gfx.at(self, rel[i]["sprite"], 4 + i * 11, TB.SH - 13, 220 / 255.0)
	# Weapon and gear slots.
	if p.weapon != null:
		Gfx.panel(self, TB.SW - 20, TB.SH - 22, 16, 16, GameData.RARITY_HEX[p.weapon["rarity"]])
		Gfx.at(self, p.weapon["sprite"], TB.SW - 18, TB.SH - 20)
		var gs := Gear.slots()
		for i in gs.size():
			var gp = p.gear.get(gs[i])
			var gx := TB.SW - 34 - (gs.size() - 1 - i) * 12
			draw_rect(Rect2(gx, TB.SH - 16, 11, 11), TB.c(GameData.RARITY_HEX[gp["rarity"]] if gp != null else "#2a2838"))
			draw_rect(Rect2(gx + 1, TB.SH - 15, 9, 9), TB.c("#17121e"))
			if gp != null:
				draw_texture_rect(Img.t(gp["sprite"]), Rect2(gx + 1, TB.SH - 15, 9, 9), false)
	# Boss bar (guardians, and rift champions and mini-bosses).
	var bo := _bar_foe()
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
		var aw := ceilf(w * Armor.shown(bo) / bo.max_hp)   # the plate of the stage, over the health (armor.gd)
		if aw > 0:
			draw_rect(Rect2(bx, by + 1, aw, 3), TB.c("#a8b4c8"))
			draw_rect(Rect2(bx, by + 1, aw, 1), TB.c("#e8eef8"))
		Gfx.text(self, bo.d["name"], TB.SW / 2, by - 9, "white", 1, 0.5)
		var wk := Armor.weakness(bo)   # 7.1: its weakness wears the plate faster (armor.gd)
		if wk != "":
			Gfx.text(self, "WEAK: " + wk.to_upper(), bx + w, by - 18, Armor.WEAK_COL[wk], 1, 1)

## 8.2 (his ask, 6 Oct: the build at a glance, like his picture): a column on the left: STR, DEX,
## INT, luck and crit, then the four alignments two by two (a leading one in its colour).
func _stat_column(p: Player, y: int) -> void:
	var rows := [["mi_str", str(p.a_str), "red"], ["mi_dex", str(p.a_dex), "lime"], ["mi_int", str(p.a_int), "cyan"],
		["mi_luck", str(p.luck), "lime"], ["mi_crit", "%d%%" % roundi(p.crit * 100), "gold"]]
	for r in rows:
		Gfx.at(self, r[0], 5, y)
		Gfx.text(self, r[1], 14, y + 1, r[2])
		y += 9
	y += 2
	for i in Alignments.KEYS.size():
		var k: String = Alignments.KEYS[i]
		var x := 5 + (i % 2) * 22
		var v := Alignments.value(p, k)
		Gfx.at(self, TraitView.ICONS[Alignments.NAMES[k]], x, y + (i / 2) * 9, 1.0 if v > 0 else 0.45)
		Gfx.text(self, str(v), x + 9, y + 1 + (i / 2) * 9, Alignments.COLS[k] if Alignments.leads(p, k) else ("white" if v > 0 else "dim"))

## The foe the boss bar shows: the floor's guardian, else a champion or mini-boss.
func _bar_foe() -> Enemy:
	if G.boss != null:
		return G.boss
	if G.champ != null and G.champ.hp > 0:
		return G.champ
	return null

func _minimap() -> void:
	var f := G.floor_d
	if FloorMap.active():
		FloorMap.draw_minimap(self, TB.SW - 6, 2)
		var secs2 := int(G.run_stats.get("time", 0.0))
		Gfx.text(self, ("DEPTH %d  %02d:%02d" % [Endless.depth(), secs2 / 60, secs2 % 60]) if Endless.on() else
			("FLOOR %d  %02d:%02d" % [G.floor_index + 1, secs2 / 60, secs2 % 60]), TB.SW - 6, 40, "bone", 1, 1)
		return
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
	if GameData.rogues():
		# Rogues layer: floor-room and the run clock.
		var secs := int(G.run_stats.get("time", 0.0))
		Gfx.text(self, ("DEPTH %d-%d  %02d:%02d" % [Endless.depth(), f["depth"], secs / 60, secs % 60]) if Endless.on() else
			("FLOOR %d-%d  %02d:%02d" % [G.floor_index + 1, f["depth"], secs / 60, secs % 60]), TB.SW - 6, 12, "bone", 1, 1)
	else:
		Gfx.text(self, "ROOM %d/%d" % [f["depth"], n], TB.SW - 6, 12, "grey", 1, 1)

func _banner(ci: CanvasItem) -> void:
	var bn := G.banner
	if bn.is_empty():
		return
	var a := clampf(minf(bn["t"], 2.6 - bn["t"]) * 4, 0.0, 1.0)
	var sub: String = bn["sub"]
	ci.draw_rect(Rect2(0, 96, TB.SW, 26 if sub.is_empty() else 36), TB.rgba(13, 10, 18, roundi(190 * a)))
	Gfx.text(ci, bn["text"], TB.SW / 2, 96 + 5, "gold", 2, 0.5, true, a)
	if not sub.is_empty():
		Gfx.text(ci, sub, TB.SW / 2, 96 + 22, "white", 1, 0.5, true, a)

## Rogues layer: quick-belt slot i on the HUD (shared with the touch controls).
static func belt_rect(i: int) -> Rect2:
	return Rect2(TB.SW / 2 - 28 + i * 14, 20, 13, 13)

## A small shield icon (Rogues layer armor).
func _shield(x: float, y: float) -> void:
	var o := PackedVector2Array([Vector2(x, y), Vector2(x + 8, y), Vector2(x + 8, y + 4), Vector2(x + 4, y + 8), Vector2(x, y + 4)])
	draw_colored_polygon(o, TB.c("#140f1c"))
	var i := PackedVector2Array([Vector2(x + 1, y + 1), Vector2(x + 7, y + 1), Vector2(x + 7, y + 4), Vector2(x + 4, y + 7), Vector2(x + 1, y + 4)])
	draw_colored_polygon(i, TB.c("#4d9be6"))
	draw_rect(Rect2(x + 2, y + 2, 2, 2), TB.c("#c8f0ff"))
