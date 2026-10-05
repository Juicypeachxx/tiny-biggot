class_name Saloon
extends RefCounted
## THE LAST DROP SALOON: an event room with people in it (ROADMAP 4.3b).
##
##   bartender  sells drinks from the counter (three of the five below, chosen per saloon). Each
##              is a timed boost with a catch. Talk to him enough and the next drink is free.
##   merchant   travelling goods at a table: a weapon or gear piece, and a potion (shop objects)
##   broker     the bounty broker: one quest for this floor, shown on the HUD, paid on the spot
##   easter eggs: a piano (play it enough and something falls out), a WANTED poster (it is you),
##              a sleeping drunk (once in a while he finds a key in his boot)
## The bar, the shelf, the piano and the tables stand on T_PROP tiles: nothing walks or shoots
## through them. Everything here is the Rogues layer: --classic never meets a saloon.

const KINDS := ["s_decor", "s_bartender", "s_drink", "s_merchant", "s_broker", "s_drunk", "s_piano", "s_poster"]

## id: [name, sprite, what it does, its catch, effects]  (buffs last DRINK_TIME seconds)
const DRINK_TIME := 45.0
const DRINKS := {
	"firewater": ["DRAGON'S BREATH", "drink_red", "+40% DAMAGE", "-15% FIRE RATE"],
	"quickgin": ["QUICKSILVER GIN", "drink_blue", "+25% FIRE RATE, +20% SPEED", "ROLLS RECHARGE 50% SLOWER"],
	"moonshine": ["BOG MOONSHINE", "drink_green", "HEALS 2 HEARTS", "-15% SPEED"],
	"courage": ["LIQUID COURAGE", "drink_amber", "+2 ARMOR", "-15% DAMAGE"],
	"special": ["THE HOUSE SPECIAL", "drink_purple", "+30% CRIT", "YOU SPILL A TENTH OF YOUR GOLD"],
}

const BARTENDER_LINES := [
	"WHAT'LL IT BE?",
	"WE DON'T SERVE SKELETONS. NO STOMACH FOR IT.",
	"THE PIANO PLAYER QUIT. TOO MUCH SHOOTING.",
	"YOUR TAB IS OPEN. JUST KIDDING. PAY UP.",
	"IF THE DRUNK OFFERS YOU A KEY, DON'T ASK.",
]
const DRUNK_LINES := ["ZZZ... FIVE MORE MINUTES...", "*HIC* THE FLOOR IS MOVING AGAIN", "I WAS A HERO ONCE. THEN I SAT DOWN.",
	"THE BROKER OWES ME... SOMETHING. ZZZ"]
const MERCHANT_LINE := "TRAVELLING GOODS. NO REFUNDS. NO QUESTIONS."

## Quests of the bounty broker: id: [title, what to do, need, reward text]. One at a time, for one floor.
const QUESTS := {
	"elites": ["BOUNTY: ELITES", "KILL %d ELITE FOES ON THIS FLOOR", 3, "A RELIC"],
	"clean": ["BOUNTY: CLEAN HANDS", "CLEAR %d FIGHTS WITHOUT BEING HIT", 3, "A PIECE OF GEAR"],
	"cull": ["BOUNTY: PEST CONTROL", "KILL %d FOES ON THIS FLOOR", 60, "40 GOLD AND A POTION"],
}

# ---------- The room ----------
static func setup(r: Room) -> void:
	var ts := TB.TS
	# The bar along the top left, with the shelf of bottles on the wall behind it.
	for c in range(3, 11):
		r.set_tile(c, 5, World.T_PROP)
	# Drawn in this order: the shelf, the bartender, then the counter in front of him.
	r.objects.append({ "kind": "s_decor", "sprite": "saloon_shelf", "x": 7.0 * ts, "y": 4.4 * ts, "used": true })
	r.objects.append({ "kind": "s_bartender", "x": 10.0 * ts, "y": 6.4 * ts, "talks": 0, "free": false })
	r.objects.append({ "kind": "s_decor", "sprite": "saloon_bar", "x": 7.0 * ts, "y": 6.0 * ts, "used": true })
	var menu := DRINKS.keys()
	menu.shuffle()
	for i in 3:
		r.objects.append({ "kind": "s_drink", "drink": menu[i], "x": (4.5 + i * 2.0) * ts, "y": 6.4 * ts })
	# The piano against the top right wall.
	for c in [21, 22]:
		for rr in [3, 4]:
			r.set_tile(c, rr, World.T_PROP)
	r.objects.append({ "kind": "s_piano", "x": 22.0 * ts, "y": 5.4 * ts, "plays": 0 })
	r.objects.append({ "kind": "s_poster", "x": 18.0 * ts, "y": 2.6 * ts })
	# Two tables: the merchant sits at one, the drunk sleeps at the other.
	for tc in [[6, 11], [20, 11]]:
		r.set_tile(tc[0], tc[1], World.T_PROP)
		r.set_tile(tc[0] + 1, tc[1], World.T_PROP)
		r.objects.append({ "kind": "s_decor", "sprite": "saloon_table", "x": (tc[0] + 1.0) * ts, "y": (tc[1] + 0.9) * ts, "used": true })
	r.objects.append({ "kind": "s_merchant", "x": 9.0 * ts, "y": 11.6 * ts })
	var f := G.floor_index
	var w := Weapons.random_weapon(Gear.roll_item_rarity(f), G.player.weapon) if randf() < 0.5 \
		else Gear.random_gear(Gear.roll_item_rarity(f))
	r.objects.append({ "kind": "shop", "item": "weapon" if w.get("item", "") == "weapon" else "gear", "thing": w,
		"x": 5.0 * ts, "y": 13.8 * ts, "price": G.item_price(w) })
	r.objects.append({ "kind": "shop", "item": "potion", "x": 8.0 * ts, "y": 13.8 * ts, "price": G.price(18 + f * 3) })
	r.objects.append({ "kind": "s_drunk", "x": 22.6 * ts, "y": 12.0 * ts, "talks": 0, "key": randf() < 0.35 })
	r.objects.append({ "kind": "s_broker", "x": 17.0 * ts, "y": 14.0 * ts })

# ---------- Using things ----------
static func handles(kind: String) -> bool:
	return kind in KINDS

static func drink_price() -> int:
	return G.price(14 + G.floor_index * 3)

static func interact(o: Dictionary) -> void:
	var p := G.player
	match o["kind"]:
		"s_bartender":
			o["talks"] += 1
			if o["talks"] >= 5 and not o["free"]:
				o["free"] = true
				G.toast("ALRIGHT, ALRIGHT. THE NEXT ONE'S ON THE HOUSE", "gold")
			else:
				G.toast(BARTENDER_LINES[(o["talks"] - 1) % BARTENDER_LINES.size()], "white")
			Snd.play("select")
		"s_drink":
			var bar = _bartender()
			var free: bool = bar != null and bar["free"]
			var cost := 0 if free else drink_price()
			if p.gold < cost:
				return G.deny(o, "NEED %d GOLD" % cost)
			p.gold -= cost
			if free:
				bar["free"] = false
				bar["talks"] = -100   # one free round per saloon
			o["gone"] = true
			drink(p, o["drink"])
			var d: Array = DRINKS[o["drink"]]
			G.show_banner(d[0], d[2] + ". BUT " + d[3])
			Fx.burst(p.x, p.y - 6, ["#f2c94c", "#e8873a", "#f4ecd8"], 12, 50)
			Snd.play("heal")
		"s_merchant":
			G.toast(MERCHANT_LINE, "white")
			Snd.play("select")
		"s_broker":
			_broker(o)
		"s_drunk":
			o["talks"] += 1
			if o["key"] and o["talks"] >= 2:
				o["key"] = false
				Combat.drop_pickup("key", o["x"], o["y"] + 10)
				G.toast("FOUND THIS IN MY BOOT. YOU HAVE IT. *HIC*", "gold")
			else:
				G.toast(DRUNK_LINES[(o["talks"] - 1) % DRUNK_LINES.size()], "grey")
			Snd.play("select")
		"s_piano":
			o["plays"] += 1
			o["note_t"] = G.time
			Snd.play("bell")
			if o["plays"] >= 4:
				o["used"] = true
				for i in 3:
					Combat.drop_pickup("coin", o["x"], o["y"] + 10)
				Combat.drop_pickup("gem", o["x"], o["y"] + 10)
				G.toast("A FEW COINS WERE STUCK IN THE KEYS", "gold")
			else:
				G.toast(["PLINK.", "PLONK. PLINK.", "THAT ONE WAS NEARLY A TUNE."][o["plays"] - 1], "pink")
		"s_poster":
			o["used"] = true
			var hero: String = GameData.heroes()[G.hero_index]["name"]
			G.show_banner("WANTED: " + hero, "FOR %d COUNTS OF MONSTER-SLAYING. HEY... THAT'S YOU" % G.run_stats.get("kills", 0))
			Combat.drop_pickup("gem", o["x"], o["y"] + 14)
			Snd.play("coin")

static func _bartender() -> Variant:
	for o in G.room.objects:
		if o["kind"] == "s_bartender":
			return o
	return null

## A drink's boost and its catch.
static func drink(p: Player, id: String) -> void:
	match id:
		"firewater":
			Effects.add_buff(p, "dmg", 0.4, DRINK_TIME)
			Effects.add_buff(p, "rate", -0.15, DRINK_TIME)
		"quickgin":
			Effects.add_buff(p, "rate", 0.25, DRINK_TIME)
			Effects.add_buff(p, "speed", 0.2, DRINK_TIME)
			Effects.add_buff(p, "dodge_cd", 0.5, DRINK_TIME)
		"moonshine":
			p.heal(4)
			Effects.add_buff(p, "speed", -0.15, DRINK_TIME)
		"courage":
			p.armor += 2
			Effects.add_buff(p, "dmg", -0.15, DRINK_TIME)
		"special":
			Effects.add_buff(p, "crit", 0.3, DRINK_TIME)
			var spill := p.gold / 10
			if spill > 0:
				p.gold -= spill
				Fx.float_text(p.x, p.y - 16, "-%d GOLD" % spill, "gold")

# ---------- The bounty broker ----------
static func quest() -> Dictionary:
	return G.run_stats.get("quest", {})

static func _broker(o: Dictionary) -> void:
	var q := quest()
	if not q.is_empty() and not q.get("done", false):
		G.toast("STILL WAITING: %d OF %d" % [q["have"], q["need"]], "white")
		Snd.play("select")
		return
	var ids := QUESTS.keys()
	var id: String = ids[randi() % ids.size()]
	var def: Array = QUESTS[id]
	G.run_stats["quest"] = { "id": id, "have": 0, "need": def[2], "floor": G.floor_index, "done": false }
	o["used"] = true
	G.show_banner(def[0], (def[1] % def[2]) + ". REWARD: " + def[3])
	Snd.play("confirm")

static func _progress(n: int) -> void:
	var q := quest()
	if q.is_empty() or q.get("done", false):
		return
	q["have"] = mini(q["have"] + n, q["need"])
	if q["have"] >= q["need"]:
		q["done"] = true
		_pay(q["id"])

static func _pay(id: String) -> void:
	var p := G.player
	G.show_banner("BOUNTY PAID", QUESTS[id][0].trim_prefix("BOUNTY: ") + ": " + QUESTS[id][3])
	Snd.play("unlock")
	match id:
		"elites":
			var r := G.roll_relics(1, "chest")
			if not r.is_empty():
				G.add_relic(p, r[0])
		"clean":
			G.drop_gear_at(p.x, p.y + 20)
		"cull":
			p.gold += 40
			Combat.drop_pickup("potion", p.x, p.y + 10)

## Rules hooks (Combat.kill_enemy, G.room_cleared, G.start_floor).
static func on_kill(e: Enemy) -> void:
	var q := quest()
	if q.is_empty() or q.get("done", false):
		return
	match q["id"]:
		"elites":
			if e.elite:
				_progress(1)
		"cull":
			_progress(1)

static func on_room_clear(room: Room) -> void:
	var q := quest()
	if not q.is_empty() and q["id"] == "clean" and room.type in ["combat", "elite", "challenge"] and room.hits == 0:
		_progress(1)

static func on_floor_start() -> void:
	var q := quest()
	if q.is_empty():
		return
	if not q.get("done", false):
		G.toast("THE BOUNTY RAN OUT", "grey")
	G.run_stats.erase("quest")

## The HUD line: "ELITES 1/3" while a bounty is on.
static func hud_line() -> String:
	var q := quest()
	if q.is_empty() or q.get("done", false):
		return ""
	return "%s %d/%d" % [QUESTS[q["id"]][0].trim_prefix("BOUNTY: "), q["have"], q["need"]]

# ---------- What the prompt says ----------
static func prompt(o: Dictionary) -> Array:
	match o["kind"]:
		"s_bartender":
			return ["THE BARTENDER", BARTENDER_LINES[0], "TALK"]
		"s_drink":
			var d: Array = DRINKS[o["drink"]]
			var bar = _bartender()
			var cost := "ON THE HOUSE" if bar != null and bar["free"] else "PAY %d GOLD" % drink_price()
			return [d[0], d[2] + " FOR 45S. BUT " + d[3], cost]
		"s_merchant":
			return ["THE MERCHANT", "HIS GOODS ARE ON THE FLOOR BELOW HIM", "TALK"]
		"s_broker":
			var q := quest()
			if not q.is_empty() and not q.get("done", false):
				return ["THE BOUNTY BROKER", "YOU ALREADY HAVE A BOUNTY", "TALK"]
			return ["THE BOUNTY BROKER", "A JOB FOR THIS FLOOR, PAID ON THE SPOT", "TAKE A BOUNTY"]
		"s_drunk":
			return ["A SLEEPING DRUNK", "HE MUMBLES SOMETHING ABOUT HIS BOOT", "WAKE HIM"]
		"s_piano":
			return ["AN OLD PIANO", "NOBODY HAS PLAYED IT IN YEARS", "PLAY"]
		"s_poster":
			return ["A WANTED POSTER", "THE FACE LOOKS FAMILIAR", "READ IT"]
	return ["", "", ""]

# ---------- Drawing (world_view.gd, with the room objects) ----------
static func draw(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x: float = o["x"]
	var y: float = o["y"]
	var breathe := roundf(sin(t * 2.0 + x) * 0.6)
	match o["kind"]:
		"s_decor":
			Gfx.sp(ci, o["sprite"], x, y, 2, 2)
		"s_bartender":
			Gfx.sp(ci, "npc_bartender", x, y - 30 + breathe)   # behind the counter
		"s_drink":
			Gfx.sp(ci, DRINKS[o["drink"]][1], x, y - 26, 2, 2)   # on the counter
		"s_merchant":
			Gfx.sp(ci, "npc_merchant", x, y + breathe)
		"s_broker":
			Gfx.sp(ci, "npc_broker", x, y + breathe)
			if not o.get("used", false) and floori(t * 3) % 2 == 0:
				Gfx.text(ci, "!", x, y - 26, "gold", 1, 0.5)
		"s_drunk":
			Gfx.sp(ci, "npc_drunk", x - 14, y - 8, 2, 2)
			var zt := fmod(t, 2.0)
			Gfx.text(ci, "Z", x - 8 + zt * 4, y - 28 - zt * 6, "grey", 1, 0.5, true, 1.0 - zt / 2.0)
		"s_piano":
			Gfx.sp(ci, "saloon_piano", x, y - 6, 2, 2)
			if G.time - o.get("note_t", -9.0) < 0.8:
				var k: float = G.time - o["note_t"]
				Gfx.text(ci, "~", x + 8 + k * 10, y - 36 - k * 20, "pink", 1, 0.5)
		"s_poster":
			Gfx.sp(ci, "wanted_poster", x, y - 4, 2, 2)
