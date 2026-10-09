class_name Dice
extends RefCounted
## 35.1 DICE (his word, 9 Oct: "a broken sandbox" where you bend luck with dice; ideas only, every
## name our own). Three dice, in the expanded game:
##   REROLL  every row of a pick changes. It is the trait pick's old reroll (p.rerolls; with none
##           left a reroll still costs gold). At a shop's DICE CUP the whole shop restocks.
##   ALTER   the chosen row, or the chosen backpack item, changes into another.
##   BANISH  the chosen one is gone for the rest of the run (never again in a pick, a chest, a shop
##           or a drop) and another takes its place.
## On a trait pick and a relic choice: MENU, HEAL and BOMB (or a tap on the dice under the rows).
## In the backpack: HEAL and BOMB on an item. Dice come from elites, chests, hidden rooms, cleared
## rooms and guardians, and shops sell one. A run starts with 2 REROLL, 1 ALTER and 1 BANISH.

## kind: [name, sprite, text colour, hex, what it does]
const KINDS := {
	"reroll": ["REROLL", "die_reroll", "gold", "#f2c94c", "EVERY CHOICE CHANGES. AT A DICE CUP: THE WHOLE SHOP"],
	"alter": ["ALTER", "die_alter", "cyan", "#6fd3e0", "THE CHOSEN ONE CHANGES INTO ANOTHER"],
	"banish": ["BANISH", "die_banish", "red", "#d8443c", "THE CHOSEN ONE IS GONE FOR THE RUN"],
}
const ORDER := ["reroll", "alter", "banish"]
const DROP_W := { "reroll": 45, "alter": 35, "banish": 20 }
const PICKUPS := ["die_reroll", "die_alter", "die_banish"]
const START := { "alter": 1, "banish": 1 }
const PRICE := 22   # a die in a shop: this + 3 a floor

static var stats := {}   # kind -> dice used (tests)

# ---------- counts ----------
static func count(p: Player, kind: String) -> int:
	match kind:
		"reroll": return p.rerolls
		"alter": return p.alters
		"banish": return p.banishes
	return 0

static func give(p: Player, kind: String, n: int = 1) -> void:
	if kind == "any":
		kind = roll_kind()
	match kind:
		"reroll": p.rerolls += n
		"alter": p.alters += n
		"banish": p.banishes += n

## Spends one die (FIXED ODDS may hand it back) and fires "on_dice".
static func spend(p: Player, kind: String) -> void:
	give(p, kind, -1)
	p.dice_used += 1
	stats[kind] = stats.get(kind, 0) + 1
	if p.g("dice_back") > 0 and randf() < p.g("dice_back"):
		give(p, kind, 1)
		G.toast("THE %s DIE CAME BACK" % KINDS[kind][0], KINDS[kind][2])
	if not p.procs.is_empty():
		Effects.fire("on_dice", { "x": p.x, "y": p.y, "kind": kind })

static func roll_kind() -> String:
	return TB.weighted(DROP_W)

## A run's start (game.new_run).
static func start(p: Player) -> void:
	if GameData.rogues():
		for k in START:
			give(p, k, START[k])

## Gone for the run (the drop pools and the picks skip it).
static func banned(id: String) -> bool:
	return G.player != null and G.player.banished.has(id)

# ---------- found ----------
static func is_kind(k: String) -> bool:
	return k in PICKUPS

## A die on the floor, with this chance (DICE FIND makes it likelier).
static func maybe(chance: float, x: float, y: float) -> void:
	var p := G.player
	if not GameData.rogues() or p == null:
		return
	if randf() < chance * (1.0 + p.g("dice_find")):
		Combat.drop_pickup("die_" + roll_kind(), x, y)

## Picked up (Combat.update_pickups).
static func take(p: Player, k: String) -> void:
	var kind := k.trim_prefix("die_")
	give(p, kind, 1)
	Snd.play("relic")
	Fx.float_text(p.x, p.y - 12, "+%s DIE" % KINDS[kind][0], KINDS[kind][2])

# ---------- the trait pick ----------
## Game.update_traits: HEAL alters the chosen row, BOMB banishes it. True when a key was used.
static func on_traits() -> bool:
	if not GameData.rogues():
		return false
	if Keys.heal():
		trait_row(false)
		return true
	if Keys.bomb():
		trait_row(true)
		return true
	return false

static func trait_row(banish: bool) -> bool:
	var p := G.player
	var c := G.tchoice
	var opts: Array = c["opts"]
	var i: int = c["idx"]
	var kind := "banish" if banish else "alter"
	if i >= opts.size() or count(p, kind) <= 0:
		return _no(kind)
	var old: Dictionary = opts[i]
	var showing := {}
	for t in opts:
		showing[t["id"]] = true
	if banish:
		showing[old["id"]] = true
		p.banished[old["id"]] = true
	var cands: Array = G.trait_cands(p, c.get("mode", "")).filter(func(pair): return not showing.has(pair[0]["id"]))
	if cands.is_empty():
		if banish and opts.size() > 1:
			opts.remove_at(i)
			c["idx"] = mini(i, opts.size() - 1)
			spend(p, kind)
			_used(kind, TraitView.row_rect(i).get_center())
			return true
		if banish:
			p.banished.erase(old["id"])
		G.toast("NOTHING ELSE TO OFFER", "grey")
		Snd.play("deny")
		return false
	var tot := 0
	for pair in cands:
		tot += pair[1]
	var x := randf() * tot
	var got: Dictionary = cands[0][0]
	for pair in cands:
		x -= pair[1]
		if x < 0:
			got = pair[0]
			break
	opts[i] = got
	TraitBook.note_seen(got)
	if not c.has("alt"):
		c["alt"] = {}
	c["alt"][i] = G.time   # the row shines as it changes (trait_view.gd)
	spend(p, kind)
	_used(kind, TraitView.row_rect(i).get_center())
	return true

# ---------- the relic choice ----------
## Game.update_choice: MENU rerolls every relic, HEAL alters the chosen one, BOMB banishes it.
static func on_choice() -> bool:
	if not GameData.rogues():
		return false
	if Keys.back():
		choice_reroll()
		return true
	if Keys.heal():
		choice_row(false)
		return true
	if Keys.bomb():
		choice_row(true)
		return true
	return false

static func choice_reroll() -> bool:
	var p := G.player
	var c := G.choice
	var ids := []
	for r in c["relics"]:
		ids.append(r["id"])
	var fresh: Array = G.roll_relics(c["relics"].size(), c.get("source", "chest"), null, ids)
	if fresh.is_empty():
		G.toast("NOTHING ELSE TO OFFER", "grey")
		Snd.play("deny")
		return false
	if not _pay_reroll(p):
		return _no("reroll")
	c["relics"] = fresh
	c["idx"] = mini(c["idx"], fresh.size() - 1)
	c["alt"] = {}
	for i in fresh.size():
		c["alt"][i] = G.time
	_used("reroll", Vector2(TB.SW / 2.0, 140))
	return true

static func choice_row(banish: bool) -> bool:
	var p := G.player
	var c := G.choice
	var rel: Array = c["relics"]
	var i: int = c["idx"]
	var kind := "banish" if banish else "alter"
	if i >= rel.size() or count(p, kind) <= 0:
		return _no(kind)
	var old: Dictionary = rel[i]
	var ids := []
	for r in rel:
		ids.append(r["id"])
	if banish:
		p.banished[old["id"]] = true
	var got: Array = G.roll_relics(1, c.get("source", "chest"), null, ids)
	if got.is_empty():
		if banish and rel.size() > 1:
			rel.remove_at(i)
			c["idx"] = mini(i, rel.size() - 1)
			spend(p, kind)
			_used(kind, Vector2(TB.SW / 2.0, 140))
			return true
		if banish:
			p.banished.erase(old["id"])
		G.toast("NOTHING ELSE TO OFFER", "grey")
		Snd.play("deny")
		return false
	rel[i] = got[0]
	if not c.has("alt"):
		c["alt"] = {}
	c["alt"][i] = G.time
	spend(p, kind)
	_used(kind, Vector2(TB.SW / 2.0, 140))
	return true

## A REROLL die, or the gold price once they are gone (the trait pick's old rule).
static func _pay_reroll(p: Player) -> bool:
	if p.rerolls > 0:
		spend(p, "reroll")
		return true
	if p.gold >= G.reroll_cost():
		p.gold -= G.reroll_cost()
		p.paid_rerolls += 1
		Snd.play("coin")
		if not p.procs.is_empty():
			Effects.fire("on_dice", { "x": p.x, "y": p.y, "kind": "reroll" })
		return true
	return false

# ---------- the backpack ----------
## Game.update_inventory: HEAL alters the chosen backpack item, BOMB banishes it.
static func on_inventory() -> bool:
	if not GameData.rogues() or not (Keys.heal() or Keys.bomb()):
		return false
	item_row(Keys.bomb())
	return true

static func item_row(banish: bool) -> bool:
	var p := G.player
	var i: int = G.inv_i
	var kind := "banish" if banish else "alter"
	if i >= 6 or i >= p.backpack.size() or count(p, kind) <= 0:
		return _no(kind)
	var old: Dictionary = p.backpack[i]
	if banish:
		p.banished[old["id"]] = true
	var nw = changed_item(old)
	if nw == null:
		if banish:
			p.banished.erase(old["id"])
		G.toast("NOTHING ELSE LIKE IT", "grey")
		Snd.play("deny")
		return false
	p.backpack[i] = nw
	spend(p, kind)
	G.toast("%s > %s" % [old["name"], nw["name"]], KINDS[kind][2])
	_used(kind, MenuView.inv_slot_rect(i).get_center())
	return true

## Another item like this one: a weapon of the same rarity, or gear for the same slot (the same
## rarity when there is one). A weapon keeps its anvil levels.
static func changed_item(old: Dictionary) -> Variant:
	var pool := []
	if old["item"] == "charm":   # 37.2 another charm of the same rarity
		for c in Charms.all():
			if c["id"] != old["id"] and c["rarity"] == old["rarity"] and not banned(c["id"]) and not Charms.wearing(G.player, c["id"]):
				pool.append(c)
		return TB.pick(pool) if not pool.is_empty() else null
	if old["item"] == "weapon":
		for w in Weapons.all():
			if w["rarity"] == old["rarity"] and _droppable_weapon(w, old):
				pool.append(w)
		if pool.is_empty():
			for w in Weapons.all():
				if _droppable_weapon(w, old):
					pool.append(w)
	else:
		for g in Gear.all():
			if g["slot"] == old["slot"] and g["rarity"] == old["rarity"] and _droppable_gear(g, old):
				pool.append(g)
		if pool.is_empty():
			for g in Gear.all():
				if g["slot"] == old["slot"] and _droppable_gear(g, old):
					pool.append(g)
	if pool.is_empty():
		return null
	var nw: Dictionary = TB.pick(pool)
	if WeaponInfo.plus(old) > 0 and old["item"] == "weapon":
		nw = nw.duplicate()
		nw["plus"] = WeaponInfo.plus(old)
	return nw

static func _droppable_weapon(w: Dictionary, old: Dictionary) -> bool:
	return w["id"] != old["id"] and not Weapons.HERO_WEAPON.values().has(w["id"]) and not w["id"] in Weapons.UNIQUE \
		and not BossLoot.is_unique(w["id"]) and not banned(w["id"])

static func _droppable_gear(g: Dictionary, old: Dictionary) -> bool:
	return g["id"] != old["id"] and g["id"] != "hagglerhat" and not BossLoot.is_unique(g["id"]) and not banned(g["id"])

# ---------- the shop's DICE CUP ----------
static func handles(kind: String) -> bool:
	return kind == "dicecup"

## Game.setup_objects: a die for sale and the DICE CUP, in an expanded shop.
static func stock_shop(r: Room, cx: float, cy: float) -> void:
	r.objects.append({ "kind": "shop", "item": "die", "die": roll_kind(), "x": cx + 144, "y": cy - 8,
		"price": G.price(PRICE + G.floor_index * 3) })
	r.objects.append({ "kind": "dicecup", "x": cx - 104, "y": cy + 34 })

static func interact(o: Dictionary) -> void:
	var p := G.player
	if not _pay_reroll(p):
		return G.deny(o, "NEEDS A REROLL DIE OR %d GOLD" % G.reroll_cost())
	var n := restock(G.room)
	o["shakes"] = o.get("shakes", 0) + 1
	o["t"] = G.time
	G.add_shake(2)
	Snd.play("confirm")
	Fx.burst(o["x"], o["y"] - 6, ["#f2c94c", "#fffbe0", "#a8705a"], 14, 60)
	G.toast("THE SHOP RESTOCKS (%d)" % n, "gold")

## Every relic, weapon, gear and die still on sale changes. Returns how many.
static func restock(r: Room) -> int:
	var p := G.player
	var f: int = G.floor_index
	var n := 0
	for o in r.objects:
		if o["kind"] != "shop" or o.get("gone", false):
			continue
		match o["item"]:
			"relic":
				var got: Array = G.roll_relics(1, "shop", r, [o["relic"]["id"]])
				if got.is_empty():
					continue
				o["relic"] = got[0]
				var base: int = { "common": 30, "rare": 48, "epic": 70, "legend": 95 }.get(got[0]["rarity"], 48)
				o["price"] = G.price(base + f * 8 + TB.rint(0, 8))
			"weapon":
				o["thing"] = Weapons.random_weapon(Gear.roll_item_rarity(f), p.weapon)
				o["price"] = G.item_price(o["thing"])
			"gear":
				o["thing"] = Gear.random_gear(Gear.roll_item_rarity(f))
				o["price"] = G.item_price(o["thing"])
			"die":
				o["die"] = roll_kind()
			_:
				continue
		n += 1
		Fx.burst(o["x"], o["y"], ["#f2c94c", "#ffffff"], 8, 40, 0.3)
	return n

static func prompt(o: Dictionary) -> Array:
	var p := G.player
	var pay := "1 REROLL DIE (YOU HAVE %d)" % p.rerolls if p.rerolls > 0 else "PAY %d GOLD (NO REROLL DIE)" % G.reroll_cost()
	return ["DICE CUP", "SHAKE IT: EVERY RELIC, WEAPON, GEAR AND DIE ON SALE CHANGES", pay]

## A leather cup on its side, two dice rolled out of it.
static func draw(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x := roundf(o["x"])
	var y := roundf(o["y"])
	var shake := 0.0
	if t - o.get("t", -9.0) < 0.4:
		shake = roundf(sin(t * 60.0) * 1.5)
	ci.draw_rect(Rect2(x - 12, y + 6, 24, 3), Color(0, 0, 0, 0.35))
	ci.draw_rect(Rect2(x - 10 + shake, y - 6, 11, 13), TB.c("#140f1c"))
	ci.draw_rect(Rect2(x - 9 + shake, y - 5, 9, 11), TB.c("#7a4a2a"))
	ci.draw_rect(Rect2(x - 9 + shake, y - 5, 9, 2), TB.c("#a8705a"))
	ci.draw_rect(Rect2(x - 9 + shake, y + 1, 9, 1), TB.c("#5a3420"))
	Gfx.sp(ci, "die_reroll", x + 5, y + 3)
	Gfx.sp(ci, "die_alter", x + 10, y - 3 + (sin(t * 3 + x) * 1.0))
	if floori(t * 2) % 3 == 0:
		Gfx.px(ci, TB.c("#fffbe0"), x + 7, y - 7)

# ---------- the dice under a pick (trait_view, overlay_view, menu_view; taps.gd) ----------
const CHIP_H := 13

## The chips for these kinds, centred on the screen at y: [[kind, Rect2]...].
static func chips(kinds: Array, y: float) -> Array:
	var p := G.player
	if p == null:
		return []
	var ws := []
	var tot := 0.0
	for k in kinds:
		var w := 17.0 + TB.text_w(_chip_text(p, k))
		ws.append(w)
		tot += w
	tot += 8.0 * (kinds.size() - 1)
	var x := roundf(TB.SW / 2.0 - tot / 2.0)
	var out := []
	for i in kinds.size():
		out.append([kinds[i], Rect2(x, y, ws[i], CHIP_H)])
		x += ws[i] + 8.0
	return out

static func _chip_text(p: Player, kind: String) -> String:
	var key: String = { "reroll": "MENU", "alter": "HEAL", "banish": "BOMB" }[kind]
	if kind == "reroll" and p.rerolls <= 0:
		return "%s  REROLL %dG" % [key, G.reroll_cost()]
	return "%s  %s x%d" % [key, KINDS[kind][0], count(p, kind)]

static func draw_chips(ci: CanvasItem, kinds: Array, y: float) -> void:
	var p := G.player
	if p == null:
		return
	for ch in chips(kinds, y):
		var k: String = ch[0]
		var r: Rect2 = ch[1]
		var have := count(p, k) > 0 or (k == "reroll" and p.gold >= G.reroll_cost())
		Gfx.panel(ci, r.position.x, r.position.y, r.size.x, r.size.y, KINDS[k][3] if have else "#4e4a5e", "#0c0b12")
		Gfx.at(ci, KINDS[k][1], r.position.x + 3, r.position.y + 2, 1.0 if have else 0.4)
		Gfx.text(ci, _chip_text(p, k), r.position.x + 14, r.position.y + 3, KINDS[k][2] if have else "dim")

## The action a chip sends (taps.gd).
static func chip_action(kind: String) -> StringName:
	return { "reroll": &"pause", "alter": &"heal", "banish": &"bomb" }[kind]

## The HUD: the three dice and how many (hud_view).
static func draw_hud(ci: CanvasItem, p: Player, x: float, y: float) -> float:
	for k in ORDER:
		var n := count(p, k)
		Gfx.at(ci, KINDS[k][1], x, y - 2, 1.0 if n > 0 else 0.35)
		Gfx.text(ci, str(n), x + 11, y, KINDS[k][2] if n > 0 else "dim")
		x += 15 + TB.text_w(str(n))
	return x

## (Menus: a sound; the row that changed shines, trait_view / overlay_view.)
static func _used(_kind: String, _at: Vector2) -> void:
	Snd.play("confirm")

static func _no(kind: String) -> bool:
	Snd.play("deny")
	G.toast("NO %s DIE" % KINDS[kind][0], "grey")
	return false
