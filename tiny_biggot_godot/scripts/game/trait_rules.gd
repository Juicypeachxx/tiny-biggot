class_name TraitRules
extends RefCounted
## 41.5 (his text, 10 Oct: the wiki's "How traits work"; asked, he chose a limit of 12): the rules
## of the trait pool in the expanded game. --classic has none of them.
##   THE LIMIT    at most CAP different traits a run (the run's OATH does not count). With CAP, a
##                pick offers only your own traits that can still rank up (G.trait_weight); rows it
##                cannot fill are STAT POINTS (+1 STR, DEX or INT; G.offer_traits, G.take_trait),
##                and with every trait at its top rank a pick is all stat points.
##   CONDITIONS   a trait that needs something to work only comes while you have it (NEEDS).
##   TOMES        a book holding one trait, its cube over it: read it to learn the trait, or with
##                CAP traits to swap it for one of yours (remove: what can come off comes off; a
##                one-off gift such as armour or a pet stays). In chests (TOME_CHANCE), one in every
##                expanded shop, one in the library room.

const CAP := 12
const TOME_CHANCE := 0.12
const NEEDS := {
	"str_shieldwall": "shield",   # HOLD THE LINE: a shield's block
	"dex_ballistics": "ranged",   # NO DISTANCE: bows, guns and thrown weapons
	"dex_pointblank": "ranged",   # MUZZLE FLASH
	"str_sharpend": "pierce",     # SHARP END: piercing hits
	"str_keenedge": "slash",      # BLEEDING EDGE: slashing hits
	"str_bluntforce": "blunt",    # BLUNT FORCE: blunt hits
	"dex_alacrity": "dexw",       # NIMBLE GRIP: a weapon that scales with DEX
	# 42.2: the INT traits that work through the hero's special
	"int_apocalypse": "special", "int_chrono": "special", "int_dreamer": "special", "int_entropy": "special",
	"int_insight": "special", "int_beacon": "special",
	"sup_engine": "special",   # 43.2 ARCANE ENGINE
}
## 43.2: the heroes' own traits (his pictures: Esper's and Cyborg's lists).
const HERO_ONLY := { "psy_": "mindwarden", "aug_": "tinkerer" }
## A stat point row: [attribute, name, a family of its colour].
const STATS := [["str", "+1 STRENGTH", "fury"], ["dex", "+1 DEXTERITY", "edge"], ["int", "+1 INTELLIGENCE", "arcane"]]
## The ops remove() can take back; the others are one-off gifts and stay.
const UNDO := ["add", "mul", "pct", "attr", "hook"]

static func on() -> bool:
	return GameData.rogues()

## How many different traits count toward the limit.
static func counted(p: Player) -> int:
	var n := 0
	for id in p.traits:
		if Traits.has(id) and Traits.by_id(id)["rarity"] != "oath":
			n += 1
	return n

static func full(p: Player) -> bool:
	return on() and counted(p) >= CAP

## Does the hero have what this trait needs to work?
static func meets(p: Player, id: String) -> bool:
	for pre in HERO_ONLY:
		if id.begins_with(pre) and p.hero.get("id", "") != HERO_ONLY[pre]:
			return false
	var w = p.weapon
	match NEEDS.get(id, ""):
		"shield": return Block.on(p)
		"ranged": return Might.ranged(w)
		"pierce": return Might.cut(w) == "PIERCING"
		"slash": return Might.cut(w) == "SLASHING"
		"blunt": return Might.blunt(w)
		"dexw": return w != null and Attributes.scaling(w)["dex"] != "-"
		"special": return Abilities.has_special(p)
	return true

## G.trait_weight and the grimoire's weights: may a pick show this trait now? Your own traits may
## always rank up; a new one needs room under the limit and what it needs to work.
static func allowed(p: Player, t: Dictionary) -> bool:
	if not on() or p.traits.has(t["id"]):
		return true
	if t["rarity"] != "oath" and counted(p) >= CAP:
		return false
	return meets(p, t["id"])

# ---------- stat points ----------
## The stat point rows, the attribute you have most of first (no random draw).
static func stat_rows(p: Player) -> Array:
	var rows := []
	for s in STATS:
		rows.append({ "id": "stat_" + s[0], "stat": s[0], "fam": s[2], "max": 1, "name": s[1],
			"desc": "A STAT POINT: +1 %s. YOU HOLD %d TRAITS, THE MOST A RUN ALLOWS." % [s[0].to_upper(), CAP],
			"cap": false, "effects": [], "new": false, "rarity": "common", "tags": [], "tiers": {} })
	rows.sort_custom(func(a, b): return Attributes.value(p, a["stat"]) > Attributes.value(p, b["stat"]))
	return rows

## G.take_trait: a stat point row.
static func take_stat(p: Player, t: Dictionary) -> void:
	Attributes.add(p, t["stat"], 1)
	p.pending -= 1
	Snd.play("relic")
	G.toast(t["name"], TraitView.GROUP_COL.get(TraitView.group(t), "white"))

# ---------- removing a trait (a tome's swap) ----------
static func remove(p: Player, id: String) -> void:
	var t := Traits.by_id(id)
	var rank: int = p.traits.get(id, 0)
	for r in range(rank, 0, -1):
		if t["tiers"].has(r):
			Effects.apply(p, _undoable(t["tiers"][r]), -1, "trait:%s:%d" % [id, r])
		Effects.apply(p, _undoable(t["effects"]), -1, "trait:" + id)
	p.traits.erase(id)
	var fam: String = t["fam"]
	var plus: int = Traits.PLUS[id][1] if Traits.PLUS.has(id) else 0
	p.fam[fam] = p.fam.get(fam, 0) - rank * (1 + plus)
	if Traits.FAMILY_BONUS.has(fam):
		var tier := mini(maxi(0, p.fam[fam]) / 2, 3)
		var have: int = p.fam_bonus.get(fam, 0)
		while have > tier:
			have -= 1
			Effects.apply(p, _undoable(Traits.FAMILY_BONUS[fam][have][1]), -1, "bonus:%s:%d" % [fam, have])
		p.fam_bonus[fam] = have
	if p.fam[fam] <= 0:
		p.fam.erase(fam)
	p.max_hp = maxi(2, p.max_hp)
	p.hp = maxi(mini(p.hp, p.max_hp), 1)
	p.armor = maxi(0, p.armor)
	p.charges = maxi(mini(p.charges, p.dodge_charges), 0)
	Effects.recount_tags(p)

static func _undoable(effects: Array) -> Array:
	return effects.filter(func(e): return e is Dictionary or (e is Array and e[0] in UNDO))

# ---------- tomes ----------
## A tome's trait: a new trait a pick could show you (its usual weight), whatever the limit.
static func roll_tome(p: Player) -> String:
	var cands := []
	var tot := 0
	for t in Traits.all():
		if not t["new"] or t["rarity"] == "oath" or p.banished.has(t["id"]) or p.traits.get(t["id"], 0) >= t["max"] or not meets(p, t["id"]):
			continue
		var w: int = G._new_trait_weight(p, t)
		if w > 0:
			cands.append([t["id"], w])
			tot += w
	if cands.is_empty():
		return ""
	var x := randf() * tot
	for c in cands:
		x -= c[1]
		if x < 0:
			return c[0]
	return cands[cands.size() - 1][0]

static func place_tome(r: Room, x: float, y: float, price: int = 0) -> void:
	if not on():
		return
	var id := roll_tome(G.player)
	if id == "":
		return
	var o := { "kind": "ttome", "trait": id, "x": x, "y": y }
	if price > 0:
		o["price"] = price
	r.objects.append(o)
	G.dyn_dirty = true

## An opened chest: sometimes a tome beside it.
static func maybe_drop(x: float, y: float) -> void:
	if on() and randf() < TOME_CHANCE:
		place_tome(G.room, x, y)

## With CAP traits and not this one, reading means giving one up.
static func must_swap(p: Player, o: Dictionary) -> bool:
	return full(p) and not p.traits.has(o["trait"])

## The traits a tome can take in exchange: all of yours but the oath.
static func swap_list(p: Player) -> Array:
	return TraitPage.owned().filter(func(t): return t["rarity"] != "oath")

static func open_tome(o: Dictionary) -> void:
	G.tome = o
	G.tome_i = 0
	G.state = &"tome"
	Snd.play("open")

## Game.update: the tome screen. ARROWS choose the trait to give up, USE reads, MENU leaves it.
static func update() -> void:
	var p := G.player
	var o: Dictionary = G.tome
	if Keys.back():
		G.state = &"play"
		Snd.play("select")
		return
	var list := swap_list(p)
	if must_swap(p, o):
		G.tome_i = G._grid_nav(clampi(G.tome_i, 0, maxi(0, list.size() - 1)), maxi(1, list.size()), TraitPage.COLS)
	if Keys.confirm():
		read(p, o, list)

static func read(p: Player, o: Dictionary, list: Array) -> void:
	var t := Traits.by_id(o["trait"])
	var swap := must_swap(p, o)
	if swap and list.is_empty():
		Snd.play("deny")
		G.state = &"play"
		return
	if o.has("price"):
		if p.gold < o["price"]:   # the book closes again: come back with the gold
			G.toast("NEED %d GOLD" % o["price"], "red")
			Snd.play("deny")
			G.state = &"play"
			return
		p.gold -= o["price"]
		Snd.play("coin")
		Effects.fire("on_buy", { "x": o["x"], "y": o["y"] })
	if swap:
		var old: Dictionary = list[clampi(G.tome_i, 0, list.size() - 1)]
		remove(p, old["id"])
		G.toast("%s GIVES WAY TO %s" % [old["name"], t["name"]], "gold")
	p.pending += 1
	G.take_trait(t)
	o["gone"] = true
	G.dyn_dirty = true
	Fx.burst(o["x"], o["y"], [TraitView.cube_hex(t), "#ffffff"], 18, 60)
	G.state = &"play"

# ---------- the tome screen ----------
const TOME_ROW := Rect2(74, 28, 300, 50)
const GRID_X := 84
const GRID_Y := 102
const BTN_Y := 256

static func cell_rect(i: int) -> Rect2:
	return Rect2(GRID_X + (i % TraitPage.COLS) * TraitPage.STEP_X, GRID_Y + (i / TraitPage.COLS) * TraitPage.STEP_Y, 40, 40)

static func btn_rect(k: int) -> Rect2:
	return Rect2(TB.SW / 2 - 104 + k * 112, BTN_Y, 96, 16)

static func draw(ci: CanvasItem) -> void:
	var p := G.player
	var o: Dictionary = G.tome
	var t := Traits.by_id(o["trait"])
	Gfx.text(ci, "A TRAIT TOME", TB.SW / 2, 6, "gold", 2, 0.5)
	TraitView._row(ci, TOME_ROW, t, true, 1.0)
	var swap := must_swap(p, o)
	if swap:
		var list := swap_list(p)
		Gfx.text(ci, "YOU HOLD %d TRAITS, THE MOST A RUN ALLOWS. GIVE ONE UP FOR IT:" % CAP, TB.SW / 2, 86, "white", 1, 0.5)
		var sel := clampi(G.tome_i, 0, maxi(0, list.size() - 1))
		for i in mini(list.size(), TraitPage.COLS * 2):
			var r := cell_rect(i)
			TraitView.cube(ci, r.position.x, r.position.y, list[i], 2, 1.0, i == sel)
		if not list.is_empty():
			var old: Dictionary = list[sel]
			var fam: Dictionary = Traits.FAMILIES[old["fam"]]
			Gfx.text(ci, "GIVE UP " + old["name"] + (" (RANK %d)" % p.traits[old["id"]] if old["max"] > 1 else ""), TB.SW / 2, 200,
				TraitView.GROUP_COL.get(TraitView.group(old), fam["col"]), 1, 0.5)
			var lines := TraitView.rich_lines(Live.desc(old), TB.SW - 60)
			for j in mini(3, lines.size()):
				TraitView.draw_line(ci, lines[j], TB.SW / 2 - TraitView.line_w(lines[j]) / 2.0, 211 + j * 8)
	else:
		var rank: int = p.traits.get(t["id"], 0)
		Gfx.text(ci, ("YOU HAVE IT: READ IT TO RAISE IT TO RANK %d" % (rank + 1)) if rank > 0 else "READ IT TO LEARN IT",
			TB.SW / 2, 92, "white", 1, 0.5)
		Gfx.text(ci, "TRAITS %d OF %d" % [counted(p), CAP], TB.SW / 2, 104, "grey", 1, 0.5)
	if o.has("price"):
		Gfx.text(ci, "IT COSTS %d GOLD. YOU HAVE %d." % [o["price"], p.gold], TB.SW / 2, 242, "gold" if p.gold >= o["price"] else "red", 1, 0.5)
	for k in 2:
		var b := btn_rect(k)
		Gfx.panel(ci, b.position.x, b.position.y, b.size.x, b.size.y, "#f2c94c" if k == 0 else "#8b8f9c", "#0c0b12")
		Gfx.text(ci, (("USE  SWAP" if swap else "USE  READ") if k == 0 else "MENU  LEAVE IT"), b.get_center().x, b.position.y + 4, "gold" if k == 0 else "grey", 1, 0.5)
