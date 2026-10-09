class_name Food
extends RefCounted
## Stage 36 FOOD AND DRINK (his word, 9 Oct: "Ideas for sprites for new stuff, and new stuff to
## add", with pictures of another game's food and drinks; ideas only, our own names and pixels).
## Expanded game only; nothing that was there is taken away.
##   FOOD (36.1)         picked up: a little XP and a point or two of STR, DEX or INT (the cheese:
##                       one more drink buff at once). Room rewards ("food"), a shop ware, elites
##                       now and then, the PICNIC BASKET.
##   GOLDEN FOOD (36.2)  rare: room rewards on the deepest floors ("golden", floor 9 on), hidden
##                       rooms and the blood altar; each a lasting bonus of its own and more XP.
##   DRINK BUFFS (36.3)  every drink also gives a buff of its own that lasts ROOMS rooms. Up to
##                       SLOTS at once (+ drink_slots: the WHEEL OF CHEESE); one more pushes the
##                       oldest out. HOLLOW LEG: they never wear off. TIPSY (tipsy.gd) is as it was.

## kind: [name, what it gives, effects]; the sprite is the kind.
const FOODS := {
	"f_bread": ["BREAD ROLL", "+1 STR", [["attr", "str", 1]]],
	"f_berries": ["WILD BERRIES", "+1 DEX", [["attr", "dex", 1]]],
	"f_mushroom": ["SKY MUSHROOM", "+1 INT", [["attr", "int", 1]]],
	"f_drumstick": ["DRUMSTICK", "+2 STR", [["attr", "str", 2]]],
	"f_carrot": ["CRISP CARROT", "+2 DEX", [["attr", "dex", 2]]],
	"f_turnip": ["MOON TURNIP", "+2 INT", [["attr", "int", 2]]],
	"f_fishpie": ["FISH PIE", "+1 STR +1 INT", [["attr", "str", 1], ["attr", "int", 1]]],
	"f_nuts": ["SPICED NUTS", "+1 STR +1 DEX", [["attr", "str", 1], ["attr", "dex", 1]]],
	"f_plum": ["DUSK PLUM", "+1 DEX +1 INT", [["attr", "dex", 1], ["attr", "int", 1]]],
	"f_cheese": ["WHEEL OF CHEESE", "+1 DRINK BUFF AT ONCE", [["hook", "drink_slots", 1]]],
}
const FOOD_W := { "f_bread": 6, "f_berries": 6, "f_mushroom": 6, "f_drumstick": 3, "f_carrot": 3, "f_turnip": 3,
	"f_fishpie": 3, "f_nuts": 3, "f_plum": 3, "f_cheese": 2 }
const GOLDEN := {
	"gf_loaf": ["GILDED LOAF", "+10% DAMAGE OF HITS THAT DO NOT CRIT", [["hook", "nocrit_dmg", 0.1]]],
	"gf_sunfruit": ["SUNFRUIT", "+3% CRIT CHANCE", [["add", "crit", 0.03]]],
	"gf_quince": ["GOLDEN QUINCE", "+3% ATTACK SPEED", [["mul", "rate", 1.03]]],
	"gf_tart": ["CROWN TART", "+15% CRIT DAMAGE", [["add", "crit_mult", 0.15]]],
	"gf_egg": ["SUN EGG", "+1 TO YOUR HIGHEST ATTRIBUTE", [["attr", "highest", 1]]],
	"gf_bun": ["HONEY BUN", "+10% COMPANION DAMAGE", [["hook", "minion_dmg", 0.1]]],
	"gf_jelly": ["STAR JELLY", "+10% DAMAGE OF YOUR ITEMS' EFFECTS", [["hook", "proc_dmg", 0.1]]],
	"gf_cookie": ["CLOVER COOKIE", "+3% LUCKY HITS", [["hook", "lucky", 0.03]]],
	"gf_date": ["DRAGON DATE", "+1 MAX HEART", [["add", "max_hp", 2], ["add_cap", "hp", 2, "max_hp"]]],
	"gf_honeycomb": ["ROYAL HONEYCOMB", "+1 STR, DEX AND INT", [["attr", "str", 1], ["attr", "dex", 1], ["attr", "int", 1]]],
}
const XP_FOOD := 0.12     # of the XP the next level needs
const XP_GOLDEN := 0.35
const GOLDEN_FLOOR := 8   # floor index from which rooms can promise golden food (floor 9 on)

## The drinks' buffs: kind: [name, what it does, effects]. Each also gives TIPSY, as before.
const DRINKS := {
	"c_ale": ["ALE", "+10% DAMAGE", [["pct", "dmg", 0.1]]],
	"c_stout": ["STOUT", "+15 THORNS", [["add", "thorns", 15]]],
	"c_mead": ["MEAD", "10% OF HITS BURN", [{ "on": "on_hit", "chance": 0.1, "do": [["status", "burn", 1]] }]],
	"c_cider": ["CIDER", "+10% ATTACK SPEED", [["mul", "rate", 1.1]]],
	"c_grog": ["GROG", "+10% MOVE SPEED", [["mul", "speed", 1.1]]],
	"c_wine": ["PLUM WINE", "+5% CRIT CHANCE", [["add", "crit", 0.05]]],
}
const SLOTS := 3
const ROOMS := 10

static var stats := {}   # eaten, golden, drinks, worn (tests)

static func on() -> bool:
	return GameData.rogues()

static func is_kind(k: String) -> bool:
	return FOODS.has(k) or GOLDEN.has(k)

static func golden(k: String) -> bool:
	return GOLDEN.has(k)

static func info(k: String) -> Array:
	return GOLDEN[k] if GOLDEN.has(k) else FOODS[k]

static func roll() -> String:
	return TB.weighted(FOOD_W)

static func roll_golden() -> String:
	return TB.pick(GOLDEN.keys())

# ---------- eating ----------
## Picked up (Combat.update_pickups).
static func take(p: Player, k: String) -> void:
	var d := info(k)
	Effects.apply(p, d[2])
	var gold := golden(k)
	stats["golden" if gold else "eaten"] = stats.get("golden" if gold else "eaten", 0) + 1
	var share := (XP_GOLDEN if gold else XP_FOOD) * (1.0 + p.g("food_xp"))   # GOURMAND: more
	Combat.gain_xp(p, maxi(1, ceili(GameData.xp_needed(p.level) * share)))
	if p.g("food_heal") > 0:
		p.heal(int(p.g("food_heal")))
	Snd.play("relic" if gold else "heal")
	Fx.float_text(p.x, p.y - 12, d[0], "gold" if gold else "tan")
	Fx.float_text(p.x, p.y - 20, d[1], "gold" if gold else "white")
	if gold:
		Fx.burst(p.x, p.y - 4, ["#f2c94c", "#fff0b0", "#ffffff"], 12, 50, 0.4)
		G.toast(d[0] + ": " + d[1], "gold")

## A chance of food at x, y (elites).
static func maybe(chance: float, x: float, y: float) -> void:
	if on() and randf() < chance:
		Combat.drop_pickup(roll(), x, y)

## Room rewards: "food" (a small meal) and "golden".
static func reward(kind: String, cx: float, cy: float) -> void:
	if kind == "golden":
		Combat.drop_pickup(roll_golden(), cx, cy)
		return
	for i in 2 + (1 if randf() < 0.5 else 0):
		Combat.drop_pickup(roll(), cx + (i - 1) * 14.0, cy)

## World.roll_reward's extra rewards (expanded game only; classic keeps its weights).
static func reward_weights(w: Dictionary, floor_index: int) -> void:
	if not on():
		return
	w["food"] = 10
	if floor_index >= GOLDEN_FLOOR:
		w["golden"] = 6

## A food stall in an expanded shop: one food for sale.
static func stock_shop(r: Room, cx: float, cy: float) -> void:
	r.objects.append({ "kind": "shop", "item": "food", "food": roll(), "x": cx + 144, "y": cy + 34,
		"price": G.price(12 + G.floor_index * 2) })

## The labels drawn this frame (world_view clears it before the pickups).
static var labels: Array = []

## Short labels for the floor where the full text is long.
const LABEL := { "f_cheese": "+1 DRINK", "gf_loaf": "+10% NO-CRIT", "gf_sunfruit": "+3% CRIT", "gf_quince": "+3% RATE", "gf_tart": "+15% CRIT DMG", "gf_egg": "+1 BEST STAT", "gf_bun": "+10% ALLIES", "gf_jelly": "+10% EFFECTS", "gf_cookie": "+3% LUCKY", "gf_date": "+1 HEART", "gf_honeycomb": "+1 ALL STATS" }

## Its label over it on the floor (world_view), as the stat pickups have.
static func draw_label(ci: CanvasItem, k: Pickup, wob: float) -> void:
	var d := info(k.kind)
	var text: String = LABEL.get(k.kind, d[1])
	var w := TB.text_w(text) + 6
	var x := roundf(k.x - w / 2.0)
	var y := roundf(k.y - 16 - k.z - wob)
	for tries in 4:   # food that landed close together: the labels stack up instead of overlapping
		var hit := false
		for r in labels:
			if r.intersects(Rect2(x, y, w, 9)):
				hit = true
				break
		if not hit:
			break
		y -= 10
	labels.append(Rect2(x, y, w, 9))
	ci.draw_rect(Rect2(x, y, w, 9), Color(0.05, 0.04, 0.07, 0.85))
	ci.draw_rect(Rect2(x, y + 8, w, 1), TB.c("#f2c94c" if golden(k.kind) else "#5a5770"))
	Gfx.text(ci, text, x + 3, y + 2, "gold" if golden(k.kind) else "tan")

# ---------- drinks ----------
static func slots(p: Player) -> int:
	return SLOTS + int(p.g("drink_slots"))

## Consumables.use, for every drink: its buff for ROOMS rooms (the oldest goes if all are taken).
static func drink(p: Player, kind: String) -> void:
	if not on() or not DRINKS.has(kind):
		return
	while p.drinks.size() >= slots(p):
		_wear_off(p, 0, true)
	p.drink_n += 1
	var src := "drink:%d" % p.drink_n
	Effects.apply(p, DRINKS[kind][2], 1, src)
	p.drinks.append([kind, ROOMS, src])
	stats["drinks"] = stats.get("drinks", 0) + 1
	Fx.float_text(p.x, p.y - 28, DRINKS[kind][1], "gold")

## Game.enter_room: every buff has a room less (HOLLOW LEG: not).
static func on_room(p: Player) -> void:
	if p == null or p.drinks.is_empty() or p.g("drink_forever") > 0:
		return
	var i := 0
	while i < p.drinks.size():
		p.drinks[i][1] -= 1
		if p.drinks[i][1] <= 0:
			_wear_off(p, i, false)
		else:
			i += 1

static func _wear_off(p: Player, i: int, pushed: bool) -> void:
	var d: Array = p.drinks[i]
	Effects.apply(p, DRINKS[d[0]][2], -1, d[2])
	p.drinks.remove_at(i)
	stats["worn"] = stats.get("worn", 0) + 1
	G.toast(("%s PUSHED OUT" if pushed else "THE %s WORE OFF") % DRINKS[d[0]][0], "grey")

## The HUD: a small mug for every buff on, with its rooms left (hud_view, beside TIPSY).
static func draw_hud(ci: CanvasItem, p: Player, x: float, y: float) -> void:
	for d in p.drinks:
		Gfx.at(ci, d[0], x, y - 1)
		Gfx.text(ci, "*" if p.g("drink_forever") > 0 else str(d[1]), x + 11, y + 2, "tan")
		x += 22
