class_name AlignShops
extends RefCounted
## Stage 45 THE ALIGNMENT SHOPS (his notes, 9 Oct: after a guardian, a GOOD, EVIL or LAWFUL shop
## can appear, each once that path's ruler is beaten, selling items that grow with its alignment;
## ROADMAP 38.1 and 45.1). After a guardian falls, one of the shops whose ruler you have beaten (in
## any run) may set up its stall in the guardian's hall, by the WAYSHRINE:
##   GOOD   THE ALMONER        once THE AUREATE JUDGE has fallen (Heaven)
##   EVIL   THE ASH PEDDLER    once THE CINDER KING has fallen (Hell)
##   LAWFUL THE QUARTERMASTER  once THE MARSHAL has fallen (the DUSTWATER rift)
## Each sells three of its four wares: three relics of its own (SHOPS relics, never in a chest) and
## the growing piece of 38.1 (SAINT'S SIGIL, DEVIL'S BARGAIN, MAGISTRATE'S SEAL), at prices that
## follow your alignment (Game.price: cheaper when yours matches, dearer when its opposite leads).
## What the relics read (gf hooks):
##   power_per_good / _evil / _law   POWER for every point of it (Might.power)
##   heal_per_good    a cleared fight heals half a heart for every 3 GOOD (Game.room_cleared)
##   armor_per_good   a floor begins with 1 armor for every 2 GOOD (Game.start_floor)
##   cursed_per_evil  cursed hit chance for every point of EVIL (Arcana.cursed_chance)
##   leech_per_evil   a kill heals half a heart, this chance for every point of EVIL (kill_enemy)
##   crit_per_law     crit chance for every point of LAWFUL (Combat.damage_enemy)
##   roll_per_law     rolls recharge faster for every point of LAWFUL (Might's roll recharge)
## Expanded game only.

const CHANCE := 0.6   # after a guardian, while at least one shop is open
const SHOPS := {
	"good": { "name": "THE ALMONER", "ruler": "THE AUREATE JUDGE", "relics": ["almshalo", "mercylamp", "dawnbuckler"], "gear": "saintsigil" },
	"evil": { "name": "THE ASH PEDDLER", "ruler": "THE CINDER KING", "relics": ["ashcrown", "sinchalice", "gravecoin"], "gear": "devilsbargain" },
	"law": { "name": "THE QUARTERMASTER", "ruler": "THE MARSHAL", "relics": ["tinstar", "duesledger", "ironwrit"], "gear": "magistrateseal" },
}

static var stats := {}   # placed (tests)

static func on() -> bool:
	return GameData.rogues()

## A relic only these shops sell (Game.relic_pool leaves it out).
static func shop_only(id: String) -> bool:
	for k in SHOPS:
		if id in SHOPS[k]["relics"]:
			return true
	return false

## The shop is open once its path's ruler has fallen, in this run or an earlier one.
static func open(al: String) -> bool:
	match al:
		"good": return Meta.meta.get("heaven_wins", 0) > 0
		"evil": return Meta.meta.get("hell_wins", 0) > 0
		"law":
			var s = Meta.meta.get("slain", {})
			return s is Dictionary and int(s.get("marshal", 0)) > 0
	return false

static func open_ones() -> Array:
	return SHOPS.keys().filter(func(k): return open(k))

## Game.on_boss_dead, after the WAYSHRINE: perhaps one of the open shops (the more of its alignment
## you have, the likelier it is the one).
static func place(r: Room) -> void:
	if not on() or G.player == null:
		return
	var shops := open_ones()
	if shops.is_empty() or randf() >= CHANCE:
		return
	var w := {}
	for k in shops:
		w[k] = 1 + maxi(0, Alignments.value(G.player, k))
	stock(r, String(TB.weighted(w)))

## Its banner and three wares, at a clear spot of the hall (spot).
static func stock(r: Room, al: String) -> void:
	var p := G.player
	var d: Dictionary = SHOPS[al]
	var wares := []
	for id in d["relics"]:
		if not p.relics.any(func(x): return x["id"] == id):
			wares.append({ "item": "relic", "relic": Relics.by_id(id) })
	var g: Dictionary = Gear.by_id(d["gear"])
	if not p.gear.values().any(func(x): return x != null and x["id"] == g["id"]):
		wares.append({ "item": "gear", "thing": g })
	wares.shuffle()
	wares = wares.slice(0, 3)
	var at := spot(r)
	r.objects.append({ "kind": "alshop", "al": al, "x": at.x, "y": at.y })
	for i in wares.size():
		var o: Dictionary = wares[i]
		var base := 40 if o["item"] == "relic" and o["relic"]["rarity"] != "epic" else 56
		o.merge({ "kind": "shop", "x": at.x + 40.0 + i * 32.0, "y": at.y, "price": G.price(base + G.floor_index * 6, al), "al": al })
		r.objects.append(o)
	stats["placed"] = stats.get("placed", 0) + 1
	G.toast("%s HAS SET UP SHOP" % d["name"], Alignments.COLS[al])

## Where the banner stands (its wares in a row to its right): the first of a few rows of the hall
## with nothing within reach of any of the four (the hoard, the WAYSHRINE, dropped things).
const SPOTS := [Vector2(3.4, 11.2), Vector2(3.4, 7.0), Vector2(17.0, 7.0), Vector2(5.0, 15.0)]

static func spot(r: Room) -> Vector2:
	for s in SPOTS:
		var at: Vector2 = s * TB.TS
		var clear := true
		for o in r.objects:
			if not o.has("x"):
				continue
			for i in 4:
				if absf(o["x"] - (at.x + 40.0 * mini(i, 1) + 32.0 * maxi(0, i - 1))) < 26 and absf(o["y"] - at.y) < 20:
					clear = false
		if clear:
			return at
	return SPOTS[0] * TB.TS

# ---------- what the relics do ----------
## Might.power: POWER for every point of the alignment.
static func power_add(p: Player) -> float:
	return p.g("power_per_good") * p.al_good + p.g("power_per_evil") * p.al_evil + p.g("power_per_law") * p.al_law

## Game.room_cleared: LAMP OF MERCY.
static func on_room_clear(p: Player) -> void:
	if on() and p.g("heal_per_good") > 0 and p.al_good >= 3:
		p.heal(int(p.g("heal_per_good")) * int(p.al_good / 3))

## Game.start_floor: DAWN BUCKLER.
static func on_floor(p: Player) -> void:
	if on() and p.g("armor_per_good") > 0 and p.al_good >= 2:
		p.armor += int(p.g("armor_per_good")) * int(p.al_good / 2)

## Combat.kill_enemy: GRAVE COIN.
static func on_kill(p: Player) -> void:
	if on() and p.g("leech_per_evil") > 0 and p.al_evil > 0 and randf() < p.g("leech_per_evil") * p.al_evil:
		p.heal(1)

# ---------- the banner ----------
## World view: a pole with its alignment's cloth, its sign and its name.
static func draw(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x: float = o["x"]
	var y: float = o["y"]
	var al: String = o["al"]
	ci.draw_rect(Rect2(x - 1, y - 26, 2, 30), TB.c("#5a4a3a"))
	var sway := sin(t * 2.0 + x) * 1.0
	ci.draw_rect(Rect2(x + 1, y - 25 + sway * 0.3, 14, 16), TB.c(Alignments.HEX[al]))
	ci.draw_rect(Rect2(x + 2, y - 24 + sway * 0.3, 12, 14), TB.c("#1a1622"))
	Gfx.sp(ci, Alignments.ICON[al], x + 8, y - 13 + sway * 0.3)
	Gfx.text(ci, SHOPS[al]["name"], x + 8, y - 36, Alignments.COLS[al], 1, 0.5)   # above it: below, a long name ran into the first price
