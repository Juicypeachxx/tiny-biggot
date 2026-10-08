class_name EventRooms
extends RefCounted
## Event rooms with people and something happening, special rooms, and wandering NPCs
## (ROADMAP 4.3b; the saloon has its own file, saloon.gd). All Rogues layer.
##
## Event rooms (a MYSTERY door):
##   pit       THE FIGHTING PIT: bet gold on yourself, survive three waves, take three times the bet
##   chopshop  THE CHOP SHOP: the mechanic bolts a mod onto your weapon (one per weapon)
##   fortune   THE FORTUNE TELLER: three cards face down, each a blessing with a curse; pick one
##   courier   THE COURIER: carry a parcel through the next three rooms within 100 s
##   gallery   THE SHOOTING GALLERY: 20 s of pop-up targets; prizes by score
## Special rooms (also behind MYSTERY doors, rarer):
##   beacon    THE SIGNAL BEACON: light it, then stand in its circle for 45 s while foes pour in
##   vault     THE PLATE VAULT: a statue shows four colours; step on the plates in that order
##   cursed    THE CURSED ARMORY: three strong weapons, each with a curse that stays for the run
## Wanderers (after a fight is won, in the cleared room, away from the doors):
##   the drunk from a saloon you visited, on a later floor: a gift, once per floor
##   a lost merchant: one thing for sale

const KINDS := ["e_pitboss", "e_mechanic", "e_teller", "e_card", "e_courier", "e_attendant", "e_beacon", "e_statue",
	"e_plate", "e_decor", "w_drunk", "w_merchant",
	"e_frog", "e_glyph", "e_pawn", "e_hustler", "e_cup", "e_gong",   # 10.2
	"n_archivist", "n_endbook", "n_turnpage", "n_inkling", "n_bookbinder", "n_tornpage", "n_redactdoor", "n_readon", "n_shelf", "e_pond", "e_angler", "e_pot", "e_coins", "e_keg",
	"c_portal", "c_wardrobe", "c_shrine", "c_telescope", "c_dummy", "c_board", "c_daily", "c_cook", "c_rack", "v_peddler", "v_bard", "v_seer", "v_monger", "v_cat", "v_gambler", "v_tinker", "c_build", "c_deco"]   # 17.2 camp.gd   # 16: room_dress.gd   # 12.1-12.2 (story.gd)
## 10.2 (his ask, 6 Oct, from his trailer clips: ideas only, this game's own events):
##   frog       THE FROG POND: kiss the frog or leave it. A royal gift, a little luck, or warts.
##   ritual     THE RITUAL CIRCLE: four glyphs (sun, moon, star, skull); stand on one for its
##              blessing and two points of its alignment. The skull's gift has a price.
##   pawn       THE PAWN SHOP: the broker buys a spare weapon or gear from your backpack, and sells
##              a sealed box with a random piece in it.
##   cups       CUP AND BALL: bet, watch three cups shuffle, pick one. The ball pays three times.
##   lightning  THE LIGHTNING ROUND: ring the gong, clear three quick waves within 30 s: an iron chest.
const EVENTS_10 := ["frog", "ritual", "pawn", "cups", "lightning", "fishing"]   # 15.2: THE FISHING HOLE
const GLYPHS := {
	"sun": ["THE SUN", "good", "HEAL EVERY HEART. +1 MAX HEART", [["add", "max_hp", 2], ["add", "hp", 99], ["clamp_max", "hp", "max_hp"]]],
	"moon": ["THE MOON", "chaos", "+1 ROLL CHARGE. +10% MOVE SPEED", [["add", "dodge_charges", 1], ["add", "charges", 1], ["mul", "speed", 1.1]]],
	"star": ["THE STAR", "law", "+10% CRIT. +10% FIRE RATE", [["add", "crit", 0.1], ["mul", "rate", 1.1]]],
	"skull": ["THE SKULL", "evil", "+30% DAMAGE, BUT -1 MAX HEART", [["mul", "dmg", 1.3], ["add_floor", "max_hp", -2, 2], ["clamp_max", "hp", "max_hp"]]],
}
const PAWN_PRICE := { "common": 12, "uncommon": 18, "rare": 28, "epic": 45, "legend": 80 }
const LIGHTNING_TIME := 30.0
const EVENTS := ["pit", "chopshop", "fortune", "courier", "gallery"]
const SPECIAL := ["beacon", "vault", "cursed"]

const TITLE := {
	"pit": ["THE FIGHTING PIT", "BET ON YOURSELF"],
	"chopshop": ["THE CHOP SHOP", "NO QUESTIONS ABOUT WHERE THE PARTS CAME FROM"],
	"fortune": ["THE FORTUNE TELLER", "EVERY GIFT HAS A PRICE"],
	"courier": ["THE COURIER'S POST", "A PARCEL THAT CANNOT WAIT"],
	"gallery": ["THE SHOOTING GALLERY", "THREE ROWS OF TARGETS, ONE PRIZE SHELF"],
	"beacon": ["THE SIGNAL BEACON", "LIGHT IT AND HOLD THE LINE"],
	"vault": ["THE PLATE VAULT", "THE STATUE KNOWS THE ORDER"],
	"cursed": ["THE CURSED ARMORY", "FINE WEAPONS. BAD LUCK"],
	"frog": ["THE FROG POND", "IT LOOKS AT YOU EXPECTANTLY"],
	"fishing": ["THE FISHING HOLE", "QUIET WATER. SOMETHING BIG LIVES HERE"],
	"ritual": ["THE RITUAL CIRCLE", "WHICH SIGN WILL YOU STAND ON?"],
	"pawn": ["THE PAWN SHOP", "EVERYTHING HAS A PRICE. EVEN YOUR JUNK"],
	"cups": ["CUP AND BALL", "KEEP YOUR EYE ON THE BALL"],
	"lightning": ["THE LIGHTNING ROUND", "THREE WAVES. THIRTY SECONDS. GO"],
}

## Chop shop mods: id: [name, what it does, effect]
const MODS := {
	"serrated": ["SERRATED", "20% OF HITS MAKE FOES BLEED", { "on": "on_hit", "chance": 0.2, "do": [["status", "bleed", 1]] }],
	"twinfeed": ["TWIN FEED", "EVERY 5TH ATTACK FIRES AN EXTRA SHOT", { "on": "every_n_shots", "every": 5, "do": [["shoot", 1, 1.0, "", 0.1]] }],
	"incendiary": ["INCENDIARY", "CRITS LEAVE FIRE ON THE FLOOR", { "on": "on_crit", "cd": 0.5, "do": [["zone", "fire", 16, 1.5]] }],
	"tracer": ["TRACER", "EVERY 8TH ATTACK CALLS LIGHTNING", { "on": "every_n_shots", "every": 8, "do": [["bolts", 1, 1.0]] }],
	"recoil": ["RECOIL KICK", "KILLS SHOVE FOES AWAY FROM YOU", { "on": "on_kill", "cd": 0.5, "do": [["push", 50, 220]] }],
	"scope": ["HUNTER SCOPE", "15% OF HITS ON ELITES LEAVE THEM VULNERABLE", { "on": "on_hit", "if": "elite", "chance": 0.15, "do": [["status", "vulnerable", 1]] }],
}

## Fortune cards and armory curses: [text, effects] (permanent for the run).
const BLESSINGS := [
	["+1 PROJECTILE", [["add", "count", 1]]],
	["+30% DAMAGE", [["mul", "dmg", 1.3]]],
	["+2 ARMOR AND +1 MAX HEART", [["add", "armor", 2], ["add", "max_hp", 2], ["add", "hp", 2]]],
	["+20% CRIT", [["add", "crit", 0.2]]],
	["+1 ROLL CHARGE", [["add", "dodge_charges", 1], ["add", "charges", 1]]],
]
const CURSES := [
	["-1 MAX HEART", [["add_floor", "max_hp", -2, 2], ["clamp_max", "hp", "max_hp"]]],
	["-15% MOVE SPEED", [["mul", "speed", 0.85]]],
	["-15% FIRE RATE", [["mul", "rate", 0.85]]],
	["ROLLS RECHARGE 30% SLOWER", [["mul", "dodge_cd", 1.3]]],
	["SHOPS COST 20% MORE", [["add", "shop_disc", -0.2]]],
]
const CARD_NAMES := ["THE COMET", "THE LANTERN", "THE ANVIL", "THE KEY", "THE HOURGLASS", "THE CROWN", "THE WOLF"]

const TELLER_LINES := ["I SEE... A LOT OF SKELETONS IN YOUR FUTURE.", "PICK A CARD. ANY CARD. NOT THAT ONE. FINE, THAT ONE.",
	"THE CARDS NEVER LIE. THE TELLER SOMETIMES DOES."]
const MECHANIC_LINES := ["ONE MOD PER WEAPON. I HAVE STANDARDS.", "IF IT SMOKES, THAT'S NORMAL. PROBABLY."]
const PITBOSS_LINES := ["NO REFUNDS IF YOU DIE.", "THE CROWD LIKES YOU. THE CROWD LIKES ANYONE WHO BLEEDS."]

const COURIER_TIME := 100.0
const COURIER_ROOMS := 3
const GALLERY_TIME := 20.0
const BEACON_TIME := 45.0
const BEACON_R := 56.0
const PLATE_COLS := ["r", "g", "u", "y"]
const PLATE_NAME := { "r": "RED", "g": "GREEN", "u": "BLUE", "y": "GOLD" }

static func handles(kind: String) -> bool:
	return kind in KINDS

static func _cx() -> float:
	return 14.0 * TB.TS

static func _cy() -> float:
	return 9.5 * TB.TS

# ---------- Setting up ----------
static func setup(r: Room, ev: String) -> void:
	var ts := TB.TS
	var cx := _cx()
	var cy := _cy()
	var f := G.floor_index
	match ev:
		"pit":
			r.objects.append({ "kind": "e_decor", "sprite": "bet_board", "x": cx + 40, "y": cy - 6, "used": true })
			r.objects.append({ "kind": "e_pitboss", "x": cx, "y": cy, "bet": 0, "waves": 0, "talks": 0 })
		"chopshop":
			r.objects.append({ "kind": "e_decor", "sprite": "tool_lift", "x": cx, "y": cy - 20, "used": true })
			r.objects.append({ "kind": "e_mechanic", "x": cx + 36, "y": cy + 4, "talks": 0 })
		"fortune":
			r.objects.append({ "kind": "e_teller", "x": cx, "y": cy - 26, "talks": 0 })
			var b := range(BLESSINGS.size())
			var c := range(CURSES.size())
			var nm := range(CARD_NAMES.size())
			b.shuffle()
			c.shuffle()
			nm.shuffle()
			for i in 3:
				r.objects.append({ "kind": "e_card", "x": cx - 32 + i * 32, "y": cy + 10, "bless": b[i], "curse": c[i],
					"name": CARD_NAMES[nm[i]] })
		"courier":
			r.objects.append({ "kind": "e_courier", "x": cx, "y": cy })
		"gallery":
			r.objects.append({ "kind": "e_decor", "sprite": "gallery_booth", "x": cx, "y": 7.0 * ts, "used": true })
			r.objects.append({ "kind": "e_attendant", "x": cx - 70, "y": cy + 30, "t": 0.0, "score": 0, "spawn": 0.0, "done": false })
		"beacon":
			r.objects.append({ "kind": "e_beacon", "x": cx, "y": cy, "lit": false, "held": 0.0, "spawn": 0.0 })
		"vault":
			var order := PLATE_COLS.duplicate()
			order.shuffle()
			r.objects.append({ "kind": "e_statue", "x": cx, "y": 5.0 * ts, "order": order, "step": 0, "show_t": -9.0, "done": false })
			var spots := [Vector2(cx - 80, cy - 10), Vector2(cx + 80, cy - 10), Vector2(cx - 80, cy + 50), Vector2(cx + 80, cy + 50)]
			var cols := PLATE_COLS.duplicate()
			cols.shuffle()
			for i in 4:
				r.objects.append({ "kind": "e_plate", "col": cols[i], "x": spots[i].x, "y": spots[i].y, "used": true, "lit": false, "on": false })
		# 10.2
		"frog":
			r.objects.append({ "kind": "e_frog", "x": cx, "y": cy })
		"fishing":
			Fishing.setup_hole(r)
		"ritual":
			var keys := GLYPHS.keys()
			for i in keys.size():
				var a := float(i) / keys.size() * TAU - PI / 2
				r.objects.append({ "kind": "e_glyph", "sign": keys[i], "x": cx + cos(a) * 56, "y": cy + sin(a) * 40 })
		"pawn":
			r.objects.append({ "kind": "e_pawn", "x": cx - 30, "y": cy, "boxes": 1 })
			r.objects.append({ "kind": "e_decor", "sprite": "weapon_rack", "x": cx + 36, "y": cy + 2, "used": true })
		"cups":
			r.objects.append({ "kind": "e_hustler", "x": cx, "y": cy - 34, "bet": 0, "t": 0.0, "state": "idle", "ball": 0,
				"order": [0, 1, 2], "swap": -1.0, "a": 0, "b": 1 })
			for i in 3:
				r.objects.append({ "kind": "e_cup", "i": i, "x": cx - 36 + i * 36, "y": cy + 10, "used": true })
		"lightning":
			r.objects.append({ "kind": "e_gong", "x": cx, "y": cy, "t": 0.0, "waves": 0 })
		"cursed":
			for i in 3:
				r.objects.append({ "kind": "e_decor", "sprite": "weapon_rack", "x": cx - 64 + i * 64, "y": cy + 2, "used": true })
			var seen := {}
			var curses := range(CURSES.size())
			curses.shuffle()
			for i in 3:
				var rar := "legend" if randf() < 0.35 + 0.05 * f else "epic"
				var w := Weapons.random_weapon(rar, G.player.weapon)
				for tries in 6:
					if not seen.has(w["id"]):
						break
					w = Weapons.random_weapon(rar, G.player.weapon)
				seen[w["id"]] = true
				r.objects.append({ "kind": "item", "item": w, "x": cx - 64 + i * 64, "y": cy, "t": 0.0, "group": "cursed",
					"curse": curses[i] })

# ---------- Using things ----------
static func interact(o: Dictionary) -> void:
	var p := G.player
	var f := G.floor_index
	match o["kind"]:
		"e_pitboss":
			if o["waves"] > 0:
				G.toast("FIGHT FIRST, TALK LATER", "white")
				return
			var bet := G.price(20 + f * 5)
			if p.gold < bet:
				o["talks"] += 1
				return G.deny(o, "NEED %d GOLD TO BET" % bet)
			p.gold -= bet
			o["bet"] = bet
			o["waves"] = 3
			o["used"] = true
			G.locked = true
			G.dyn_dirty = true
			G.show_banner("THE BET IS ON: %d GOLD" % bet, "SURVIVE THREE WAVES. THE POT IS THREE TIMES THAT")
			Snd.play("bell")
		"e_mechanic":
			if p.weapon == null:
				return
			if p.weapon.has("mod"):
				o["talks"] += 1
				G.toast(MECHANIC_LINES[0], "white")
				return
			var cost := G.price(30 + f * 6)
			if p.gold < cost:
				return G.deny(o, "NEED %d GOLD" % cost)
			p.gold -= cost
			var ids := MODS.keys()
			var id: String = ids[randi() % ids.size()]
			mod_weapon(p, id)
			G.show_banner(MODS[id][0] + " " + p.weapon["name"], MODS[id][1])
			Fx.burst(o["x"], o["y"] - 10, ["#f2c94c", "#e8873a", "#8b8f9c"], 18, 80)
			Snd.play("unlock")
		"e_teller":
			o["talks"] += 1
			G.toast(TELLER_LINES[(o["talks"] - 1) % TELLER_LINES.size()], "purple")
			Snd.play("select")
		"e_card":
			var bl: Array = BLESSINGS[o["bless"]]
			var cu: Array = CURSES[o["curse"]]
			Effects.apply(p, bl[1] + cu[1], 1, "card:" + o["name"])
			p.hp = clampi(p.hp, 1, p.max_hp)
			for o2 in G.room.objects:
				if o2["kind"] == "e_card" and o2 != o:
					o2["gone"] = true
					Fx.burst(o2["x"], o2["y"], ["#a35bd6", "#5c3483"], 8, 40)
			o["used"] = true
			o["shown"] = true
			G.show_banner(o["name"] + ": " + bl[0], "BUT " + cu[0])
			Snd.play("relic")
		"e_courier":
			if not G.run_stats.get("parcel", {}).is_empty():
				return G.deny(o, "YOU ALREADY CARRY ONE")
			G.run_stats["parcel"] = { "rooms": COURIER_ROOMS, "t": COURIER_TIME }
			o["used"] = true
			G.show_banner("TAKE THIS PARCEL", "THROUGH %d MORE ROOMS IN %d SECONDS. DON'T SHAKE IT" % [COURIER_ROOMS, COURIER_TIME])
			Snd.play("confirm")
		"e_attendant":
			if o["t"] > 0:
				return
			if o["done"]:
				return G.deny(o, "ONE ROUND A CUSTOMER")
			var cost := G.price(10 + f * 2)
			if p.gold < cost:
				return G.deny(o, "NEED %d GOLD" % cost)
			p.gold -= cost
			o["t"] = GALLERY_TIME
			o["score"] = 0
			o["used"] = true
			G.show_banner("SHOOT THE TARGETS", "20 SECONDS. 4 FOR GOLD, 8 FOR GEAR, 12 FOR A RELIC")
			Snd.play("bell")
		"e_beacon":
			o["lit"] = true
			o["used"] = true
			G.locked = true
			G.dyn_dirty = true
			G.show_banner("THE BEACON IS LIT", "STAY IN ITS LIGHT FOR %d SECONDS" % BEACON_TIME)
			Snd.play("portal")
		"e_statue":
			o["show_t"] = G.time
			o["step"] = 0
			for pl in G.room.objects:
				if pl["kind"] == "e_plate":
					pl["lit"] = false
			Snd.play("bell")
			G.toast("THE STATUE'S EYES FLASH: " + " ".join(o["order"].map(func(c): return PLATE_NAME[c])), "white")
		# 10.2
		"n_archivist":
			Story.tell(o)
		"n_inkling":
			Story.inkling(o)
		"n_tornpage":
			Story.take_page(o)
		"e_pond":
			Fishing.start(o)
		"e_angler":
			Fishing.angler(o)
		"c_portal", "c_wardrobe", "c_shrine", "c_telescope", "c_dummy", "c_board", "c_daily", "c_cook", "c_rack", "v_peddler", "v_bard", "v_seer", "v_monger", "v_cat", "v_gambler", "v_tinker", "c_build", "c_deco":
			Camp.interact(o)
		"n_readon":
			o["used"] = true
			for o2 in G.room.objects:
				if o2["kind"] == "n_endbook":
					o2["used"] = true
			Snd.play("portal")
			G.start_fade(func(): G.begin_chapter3())
		"n_shelf":   # 20.3
			o["used"] = true
			for o2 in G.room.objects:
				if o2["kind"] == "n_endbook":
					o2["used"] = true
			Snd.play("portal")
			G.start_fade(func(): G.begin_chapter4())
		"n_redactdoor":
			o["used"] = true
			for o2 in G.room.objects:
				if o2["kind"] == "n_endbook":
					o2["used"] = true
			Snd.play("portal")
			G._enter_realm("redaction", 3)
		"n_bookbinder":
			Story.bookbinder(o)
		"n_endbook":
			o["used"] = true
			for o2 in G.room.objects:
				if o2["kind"] in ["n_turnpage", "n_readon", "n_shelf", "n_redactdoor"]:
					o2["used"] = true
			G.show_banner("THE BOOK IS CLOSED", "THE PAGE IS YOURS. A STORY WELL TOLD")
			G.win_timer = 3.0
			Snd.play("open")
		"n_turnpage":
			o["used"] = true
			Snd.play("portal")
			G.start_fade(func(): G.begin_chapter2())
		"e_frog":
			o["used"] = true
			var roll := randf()
			if roll < 0.4:
				var r := G.roll_relics(1, "iron")
				if not r.is_empty():
					G.add_relic(p, r[0])
				G.show_banner("IT WAS A PRINCE ALL ALONG", "HE THANKS YOU WITH " + (r[0]["name"] if not r.is_empty() else "A BOW"))
				Fx.burst(o["x"], o["y"], ["#f2c94c", "#ffffff"], 24, 80)
			elif roll < 0.8:
				p.luck += 1
				G.show_banner("IT WAS JUST A FROG", "IT CROAKS HAPPILY. +1 LUCK")
			else:
				Effects.apply(p, [["mul", "speed", 0.92]], 1, "frog:warts")
				G.show_banner("WARTS", "YOU SHOULD HAVE KNOWN. -8% MOVE SPEED")
			o["gone"] = true
			Snd.play("select")
		"e_glyph":
			var gl: Array = GLYPHS[o["sign"]]
			Effects.apply(p, gl[3], 1, "glyph:" + o["sign"])
			Alignments.add(p, gl[1], 2)
			for o2 in G.room.objects:
				if o2["kind"] == "e_glyph":
					o2["used"] = true
			G.show_banner(gl[0] + ": " + gl[2], "+2 " + Alignments.NAMES[gl[1]])
			Fx.burst(o["x"], o["y"], [Alignments.HEX[gl[1]], "#ffffff"], 22, 70)
			Snd.play("portal")
		"e_pawn":
			var spare := -1
			for i in p.backpack.size():
				if p.backpack[i] != null:
					spare = i
					break
			if spare >= 0:
				var it: Dictionary = p.backpack[spare]
				var price := G.price(PAWN_PRICE.get(it["rarity"], 15))
				p.backpack.remove_at(spare)
				p.gold += price
				G.toast("SOLD %s FOR %d GOLD" % [it["name"], price], "gold")
				Snd.play("coin")
			elif o["boxes"] > 0:
				var cost := G.price(40 + f * 4)
				if p.gold < cost:
					return G.deny(o, "NEED %d GOLD FOR A SEALED BOX" % cost)
				p.gold -= cost
				o["boxes"] -= 1
				var rar := Gear.roll_item_rarity(f, "chest")
				G.drop_item(Gear.random_gear(rar) if randf() < 0.5 else Weapons.random_weapon(rar, p.weapon), o["x"] + 20, o["y"] + 16)
				G.toast("NO PEEKING BEFORE YOU PAY. TOO LATE NOW", "white")
				Snd.play("open")
			else:
				return G.deny(o, "NOTHING TO SELL, NOTHING TO BUY")
		"e_hustler":
			if o["state"] != "idle":
				return
			if o.get("done", false):
				return G.deny(o, "ONE GAME A CUSTOMER")
			var bet := G.price(15 + f * 4)
			if p.gold < bet:
				return G.deny(o, "NEED %d GOLD TO PLAY" % bet)
			p.gold -= bet
			o["bet"] = bet
			o["ball"] = randi() % 3
			o["order"] = [0, 1, 2]
			o["state"] = "show"
			o["t"] = 1.2
			o["swaps"] = 6 + f / 2
			G.toast("WATCH THE BALL...", "white")
			Snd.play("bell")
		"e_cup":
			var h = _hustler()
			if h == null or h["state"] != "pick":
				return
			h["state"] = "reveal"
			h["t"] = 1.6
			h["picked"] = o["i"]
			var won: bool = h["order"][o["i"]] == h["ball"]
			if won:
				p.gold += h["bet"] * 3
				G.show_banner("SHARP EYES", "THREE TIMES YOUR BET: %d GOLD" % (h["bet"] * 3))
				Snd.play("coin")
			else:
				G.show_banner("SO CLOSE", "THE BALL WAS NEVER THERE. OR WAS IT?")
				Snd.play("deny")
			h["done"] = true
		"e_gong":
			if o["waves"] > 0 or o.get("done", false):
				return
			o["waves"] = 3
			o["t"] = LIGHTNING_TIME
			o["used"] = true
			G.locked = true
			G.dyn_dirty = true
			G.show_banner("THE LIGHTNING ROUND", "CLEAR THREE WAVES IN %d SECONDS" % LIGHTNING_TIME)
			Snd.play("bell")
		"w_drunk":
			o["used"] = true
			var gift: String = TB.pick(["potion", "heart", "bomb", "key"])
			Combat.drop_pickup(gift, o["x"], o["y"] + 10)
			G.toast("YOU AGAIN! HAVE THIS. I FOUND IT. *HIC*", "gold")
			Snd.play("select")
		"w_merchant":
			if p.gold < o["price"]:
				return G.deny(o, "NEED %d GOLD" % o["price"])
			p.gold -= o["price"]
			o["used"] = true
			Combat.drop_pickup(o["sells"], o["x"], o["y"] + 12)
			G.toast("PLEASURE. NOW, WHICH WAY IS OUT?", "white")
			Snd.play("coin")

## The chop shop: a copy of the weapon with one more effect (the weapon list itself is never changed).
static func mod_weapon(p: Player, id: String) -> void:
	var w: Dictionary = p.weapon.duplicate(true)
	var fx: Array = w["effects"].duplicate(true)
	fx.append(MODS[id][2])
	w["effects"] = fx
	w["mod"] = id
	w["desc"] = w["desc"] + " " + MODS[id][0] + ": " + MODS[id][1] + "."
	Weapons.equip_weapon(p, w)

## Taking a weapon from the cursed armory (G.interact, item branch).
static func take_cursed(p: Player, o: Dictionary) -> void:
	var cu: Array = CURSES[o["curse"]]
	Effects.apply(p, cu[1], 1, "curse:" + str(o["curse"]))
	p.hp = clampi(p.hp, 1, p.max_hp)
	G.toast("CURSED: " + cu[0], "purple")
	Snd.play("roar")
	o.erase("curse")

# ---------- Every tick in play (G.update_play) ----------
static func update(dt: float) -> void:
	var room := G.room
	if room == null:
		return
	_update_parcel(dt)
	Fishing.keep_out(G.player)   # 15.2: nobody walks on water
	RoomDress.tick_objects(room)   # 16: pots break, coin heaps pay
	CampLife.tick(dt)   # 19.2: the stray cat, the bard
	if room.event == "":
		return
	for o in room.objects:
		match o["kind"]:
			"e_pitboss":
				_update_pit(o)
			"e_attendant":
				_update_gallery(o, dt)
			"e_beacon":
				_update_beacon(o, dt)
			"e_plate":
				_update_plate(o)
			"e_hustler":
				_update_cups(o, dt)
			"e_gong":
				_update_gong(o, dt)

static func _hustler() -> Variant:
	for o in G.room.objects:
		if o["kind"] == "e_hustler":
			return o
	return null

## The cups: show the ball, shuffle (each swap 0.35 s, cups slide past each other), then wait for a pick.
static func _update_cups(o: Dictionary, dt: float) -> void:
	match o["state"]:
		"show":
			o["t"] -= dt
			if o["t"] <= 0:
				o["state"] = "shuffle"
				o["swap"] = 0.0
				o["a"] = randi() % 3
				o["b"] = (o["a"] + 1 + randi() % 2) % 3
		"shuffle":
			o["swap"] += dt / 0.35
			if o["swap"] >= 1.0:
				var ord: Array = o["order"]
				var tmp = ord[o["a"]]
				ord[o["a"]] = ord[o["b"]]
				ord[o["b"]] = tmp
				o["swaps"] -= 1
				o["swap"] = 0.0
				if o["swaps"] <= 0:
					o["state"] = "pick"
					o["swap"] = -1.0
					G.toast("WHERE IS IT?", "white")
					for c in G.room.objects:
						if c["kind"] == "e_cup":
							c["used"] = false
				else:
					o["a"] = randi() % 3
					o["b"] = (o["a"] + 1 + randi() % 2) % 3
		"reveal":
			o["t"] -= dt
			if o["t"] <= 0:
				o["state"] = "idle"
				for c in G.room.objects:
					if c["kind"] == "e_cup":
						c["used"] = true

## Where cup i is drawn now (it slides while it is being swapped).
static func cup_pos(h: Dictionary, c: Dictionary) -> Vector2:
	var base := Vector2(_cx() - 36 + c["i"] * 36, _cy() + 10)
	if h["state"] != "shuffle" or h["swap"] < 0 or not c["i"] in [h["a"], h["b"]]:
		return base
	var other: int = h["b"] if c["i"] == h["a"] else h["a"]
	var to := Vector2(_cx() - 36 + other * 36, _cy() + 10)
	var k: float = h["swap"]
	return base.lerp(to, k) + Vector2(0, (14.0 if c["i"] == h["a"] else -14.0) * sin(k * PI))

static func _update_gong(o: Dictionary, dt: float) -> void:
	if o["waves"] <= 0:
		return
	o["t"] -= dt
	if not G.enemies.is_empty() and o.get("fighting", false):
		return
	if o.get("fighting", false):
		o["waves"] -= 1
		o["fighting"] = false
		if o["waves"] <= 0:
			o["done"] = true
			G.locked = false
			G.dyn_dirty = true
			Snd.play("door")
			if o["t"] > 0:
				G.room.objects.append({ "kind": "ichest", "x": o["x"], "y": o["y"] + 30, "free": true })
				G.show_banner("IN TIME!", "AN IRON CHEST, ON THE HOUSE")
			else:
				G.show_banner("TOO SLOW", "THE GONG IS SILENT")
			return
	o["fighting"] = true
	_spawn_foes(4 + G.floor_index / 2)

static func _spawn_foes(n: int, near: Vector2 = Vector2.ZERO) -> void:
	var pool: Array = GameData.floors()[G.floor_index]["pool"]
	for i in n:
		var type: String = TB.pick(pool)
		var s := World.free_spot(G.room, G.player, 80, World.M_FLYER if GameData.ENEMIES[type].get("fly", false) else World.M_WALKER)
		Combat.spawn_enemy(type, s.x, s.y, randf() < 0.12)

static func _update_pit(o: Dictionary) -> void:
	if o["waves"] <= 0 or not G.enemies.is_empty():
		return
	if o.get("fighting", false):
		o["waves"] -= 1
		o["fighting"] = false
		if o["waves"] <= 0:
			var pot: int = o["bet"] * 3
			G.player.gold += pot
			for i in 2:
				Combat.drop_pickup("gem", o["x"], o["y"] + 12)
			G.locked = false
			G.dyn_dirty = true
			Snd.play("door")
			G.show_banner("THE CROWD ROARS", "YOU WIN THE POT: %d GOLD" % pot)
			return
	o["fighting"] = true
	_spawn_foes(3 + G.floor_index / 2 + (3 - o["waves"]))

static func _update_gallery(o: Dictionary, dt: float) -> void:
	if o["t"] <= 0:
		return
	o["t"] -= dt
	o["spawn"] -= dt
	if o["spawn"] <= 0 and o["t"] > 0.5:
		o["spawn"] = 0.75
		var x := randf_range(4.0 * TB.TS, 24.0 * TB.TS)
		var y := randf_range(3.8 * TB.TS, 6.4 * TB.TS)
		var e := Combat.spawn_enemy("target", x, y, false, true)
		e.max_hp = 1.0
		e.hp = 1.0
		e.t = 1.7   # seconds it stays up
	for e in G.enemies.duplicate():
		if e.type == "target":
			e.t -= dt
			if e.t <= 0 or o["t"] <= 0:
				G.enemies.erase(e)
				Fx.burst(e.x, e.y, ["#8b8f9c"], 4, 30)
	if o["t"] <= 0:
		o["done"] = true
		o["used"] = false
		var s: int = o["score"]
		var p := G.player
		if s >= 12:
			var r := G.roll_relics(1, "chest")
			if not r.is_empty():
				G.add_relic(p, r[0])
		if s >= 8:
			G.drop_gear_at(o["x"] + 40, o["y"])
		if s >= 4:
			for i in 5:
				Combat.drop_pickup("coin", o["x"], o["y"] + 10)
		G.show_banner("SCORE: %d" % s, "A RELIC, GEAR AND GOLD" if s >= 12 else ("GEAR AND GOLD" if s >= 8 else ("GOLD" if s >= 4 else "BETTER LUCK NEXT TIME")))
		Snd.play("unlock" if s >= 4 else "deny")

static func _update_beacon(o: Dictionary, dt: float) -> void:
	if not o["lit"] or o["held"] >= BEACON_TIME:
		return
	var p := G.player
	if TB.dist_xy(p.x, p.y, o["x"], o["y"]) < BEACON_R:
		o["held"] += dt
	o["spawn"] -= dt
	if o["spawn"] <= 0 and G.enemies.size() < 6 + G.floor_index / 2:
		o["spawn"] = 2.2
		_spawn_foes(2)
	if o["held"] >= BEACON_TIME:
		for e in G.enemies.duplicate():
			Combat.damage_enemy(e, e.hp * 2.0 + 1.0, { "no_crit": true, "no_mult": true, "silent": true })
		G.locked = false
		G.dyn_dirty = true
		G.room.objects.append({ "kind": "ichest", "x": o["x"], "y": o["y"] + 40, "free": true })
		for i in 3:
			Combat.drop_pickup("ember", o["x"], o["y"] + 20)
		G.show_banner("THE SIGNAL IS SENT", "SOMETHING ANSWERS: A CHEST")
		Snd.play("unlock")

static func _update_plate(pl: Dictionary) -> void:
	var p := G.player
	var on := absf(p.x - pl["x"]) < 11 and absf(p.y - pl["y"]) < 9
	if on == pl["on"]:
		return
	pl["on"] = on
	if not on or pl["lit"]:
		return
	var st = null
	for o in G.room.objects:
		if o["kind"] == "e_statue":
			st = o
	if st == null or st["done"]:
		return
	if st["order"][st["step"]] == pl["col"]:
		pl["lit"] = true
		st["step"] += 1
		Snd.play("select")
		if st["step"] >= 4:
			st["done"] = true
			st["used"] = true
			G.room.objects.append({ "kind": "ichest", "x": _cx() - 26, "y": _cy() + 20, "free": true })
			G.room.objects.append({ "kind": "ichest", "x": _cx() + 26, "y": _cy() + 20, "free": true })
			G.show_banner("THE VAULT OPENS", "TWO IRON CHESTS RISE FROM THE FLOOR")
			Snd.play("unlock")
	else:
		# Wrong plate: the plates go dark and darts fly from it.
		st["step"] = 0
		for o in G.room.objects:
			if o["kind"] == "e_plate":
				o["lit"] = false
		Combat.ering(pl["x"], pl["y"], 8, 70, randf() * TAU, "bone")
		Snd.play("deny")
		G.toast("WRONG ORDER. ASK THE STATUE AGAIN", "red")

# ---------- The courier's parcel ----------
static func parcel() -> Dictionary:
	return G.run_stats.get("parcel", {})

static func _update_parcel(dt: float) -> void:
	var pc := parcel()
	if pc.is_empty():
		return
	pc["t"] -= dt
	if pc["t"] <= 0:
		G.run_stats.erase("parcel")
		G.toast("TOO SLOW. THE PARCEL WENT STALE", "grey")
		Snd.play("deny")

## A new room was entered (G.enter_room).
static func on_enter_room() -> void:
	var pc := parcel()
	if pc.is_empty():
		return
	pc["rooms"] -= 1
	if pc["rooms"] > 0:
		return
	G.run_stats.erase("parcel")
	var p := G.player
	var r := G.roll_relics(1, "chest")
	if not r.is_empty():
		G.add_relic(p, r[0])
	p.gold += 25
	G.show_banner("PARCEL DELIVERED", "PAID IN FULL: A RELIC AND 25 GOLD")
	Snd.play("unlock")

static func on_floor_start() -> void:
	if not parcel().is_empty():
		G.run_stats.erase("parcel")
		G.toast("THE PARCEL WAS LOST ON THE STAIRS", "grey")

static func hud_line() -> String:
	var pc := parcel()
	if pc.is_empty():
		return ""
	return "PARCEL: %d ROOMS, %dS" % [pc["rooms"], ceili(pc["t"])]

## A foe died (Combat.kill_enemy): gallery targets score.
static func on_kill(e: Enemy) -> void:
	if e.type != "target" or G.room == null:
		return
	for o in G.room.objects:
		if o["kind"] == "e_attendant" and o["t"] > 0:
			o["score"] += 1

## A fight was won (G.room_cleared): sometimes someone wanders in.
static func on_room_clear(room: Room) -> void:
	if not GameData.rogues() or not room.type in ["combat", "elite"] or not room.theme.is_empty():
		return
	var met: Dictionary = G.run_stats.get("wanderers", {})
	G.run_stats["wanderers"] = met
	var floor_key := str(G.floor_index)
	if G.run_stats.get("saloon_floor", -1) >= 0 and G.floor_index > G.run_stats["saloon_floor"] \
			and not met.has("drunk" + floor_key) and randf() < 0.3:
		met["drunk" + floor_key] = true
		_place(room, { "kind": "w_drunk" })
		G.toast("A FAMILIAR SNORE...", "grey")
	elif Story.chapter2() and not met.has("inkling" + floor_key) and randf() < 0.35:
		met["inkling" + floor_key] = true   # 12.2: in Chapter II, the Inkling knows where the walls are thin
		_place(room, { "kind": "n_inkling" })
		G.toast("SOMETHING DRIPS FROM THE CEILING...", "grey")
	elif not met.has("merchant" + floor_key) and randf() < 0.06:
		met["merchant" + floor_key] = true
		var sells: String = TB.pick(["potion", "key", "bomb", "armor"])
		_place(room, { "kind": "w_merchant", "sells": sells, "price": G.price(14 + G.floor_index * 3) })
		G.toast("A LOST MERCHANT WANDERS IN", "white")

## Somewhere on open floor, away from every door and from the hero, near a side wall.
static func _place(room: Room, o: Dictionary) -> void:
	for tries in 40:
		var c := TB.rint(TB.IX0 + 2, TB.IX0 + TB.IW - 3)
		var r := TB.rint(TB.IY0 + 2, TB.IY0 + TB.IH - 3)
		var x := c * TB.TS + 8.0
		var y := r * TB.TS + 8.0
		if World.hits_solid(room, x, y, 10, World.M_PLAYER):
			continue
		var near_door := false
		for d in ["n", "s", "w", "e"]:
			if TB.dist_xy(x, y, World.door_center(d).x, World.door_center(d).y) < 70:
				near_door = true
		if near_door or TB.dist_xy(x, y, G.player.x, G.player.y) < 50:
			continue
		var free := true
		for o2 in room.objects:
			if TB.dist_xy(x, y, o2["x"], o2["y"]) < 30:
				free = false
		if not free:
			continue
		o["x"] = x
		o["y"] = y
		room.objects.append(o)
		return

# ---------- Prompts ----------
static func prompt(o: Dictionary) -> Array:
	var f := G.floor_index
	match o["kind"]:
		"e_pitboss":
			return ["THE PIT BOSS", "BET ON YOURSELF: SURVIVE 3 WAVES, WIN 3 TIMES THE BET", "BET %d GOLD" % G.price(20 + f * 5)]
		"e_mechanic":
			if G.player.weapon != null and G.player.weapon.has("mod"):
				return ["THE MECHANIC", "YOUR WEAPON ALREADY CARRIES A MOD", "TALK"]
			return ["THE MECHANIC", "A RANDOM MOD FOR YOUR WEAPON, FOR GOOD", "PAY %d GOLD" % G.price(30 + f * 6)]
		"e_teller":
			return ["THE FORTUNE TELLER", "EACH CARD IS A BLESSING WITH A CURSE", "TALK"]
		"e_card":
			return ["A CARD, FACE DOWN", "A BLESSING AND A CURSE, FOR THE WHOLE RUN", "TURN IT"]
		"e_courier":
			return ["THE COURIER", "CARRY A PARCEL THROUGH 3 ROOMS IN 100S: A RELIC", "TAKE IT"]
		"e_attendant":
			return ["THE ATTENDANT", "20S OF TARGETS. 4: GOLD, 8: GEAR, 12: A RELIC", "PAY %d GOLD" % G.price(10 + f * 2)]
		"e_beacon":
			return ["A SIGNAL BEACON", "LIGHT IT, THEN STAND IN ITS LIGHT FOR 45S", "LIGHT IT"]
		"e_statue":
			return ["A STONE STATUE", "ITS EYES SHOW THE ORDER OF THE PLATES", "LOOK"]
		"n_endbook":
			return ["THE BOOK", "END THE STORY HERE: THE RUN IS WON", "CLOSE IT"]
		"n_turnpage":
			return ["THE NEXT PAGE", "CHAPTER II: THE MARGINS, THE AUTHOR'S WORKSHOP", "TURN THE PAGE"]
		"n_tornpage":
			return ["A TORN PAGE", "TORN FROM THE BOOK. %d OF 3 FOUND" % G.run_stats.get("pages", 0), "TAKE IT"]
		"e_angler":
			return Fishing.angler_prompt(o)
		"c_portal", "c_wardrobe", "c_shrine", "c_telescope", "c_dummy", "c_board", "c_daily", "c_cook", "c_rack", "v_peddler", "v_bard", "v_seer", "v_monger", "v_cat", "v_gambler", "v_tinker", "c_build", "c_deco":
			return Camp.prompt(o)
		"e_pond":
			return ["A POND", "%d CASTS LEFT. FISH FOUND %d OF %d" % [o.get("casts", 0), Fishing.caught_kinds(), Fishing.FISH.size()], "FISH"]
		"n_readon":
			return ["THE APPENDIX", "CHAPTER III: WHERE THE ERASED WORDS GATHER", "READ ON"]
		"n_shelf":
			return ["THE SHELF", "CHAPTER IV: THE LIBRARY, WHERE EVERY FINISHED BOOK IS KEPT", "STEP OUT"]
		"n_redactdoor":
			return ["A DOOR CUT INTO THE PAGE", "BEHIND IT: WHAT THE AUTHOR FEARED", "STEP THROUGH"]
		"n_inkling":
			return ["THE INKLING", "A DROP OF INK THAT GOT LOOSE FROM THE PAGE", "LISTEN"]
		"n_bookbinder":
			if o.get("relic") == null:
				return ["THE BOOKBINDER", "HER SHELF IS BARE", "..."]
			return ["THE BOOKBINDER", "A BOUND RELIC: " + str(o["relic"]["name"]), "PAY %d GOLD" % o["price"]]
		"n_archivist":
			return ["THE ARCHIVIST", "HE HAS SOMETHING NEW TO TELL" if Story.has_new() else "HE KNOWS HOW THE STORY GOES", "LISTEN"]
		"e_frog":
			return ["A FROG", "IT PUCKERS UP", "KISS IT"]
		"e_glyph":
			var gl: Array = GLYPHS[o["sign"]]
			return [gl[0], gl[2] + ". +2 " + Alignments.NAMES[gl[1]], "STAND ON IT"]
		"e_pawn":
			var p2 := G.player
			for it in p2.backpack:
				if it != null:
					return ["THE PAWNBROKER", "HE WANTS YOUR " + it["name"], "SELL FOR %d GOLD" % G.price(PAWN_PRICE.get(it["rarity"], 15))]
			return ["THE PAWNBROKER", "A SEALED BOX: A RANDOM PIECE", "BUY FOR %d GOLD" % G.price(40 + f * 4)]
		"e_hustler":
			return ["THE CUP MAN", "FIND THE BALL, WIN THREE TIMES THE BET", "BET %d GOLD" % G.price(15 + f * 4)]
		"e_cup":
			return ["A CUP", "IS THE BALL UNDER THIS ONE?", "LIFT IT"]
		"e_gong":
			return ["A GONG", "3 QUICK WAVES IN 30S FOR AN IRON CHEST", "RING IT"]
		"w_drunk":
			return ["THE DRUNK FROM THE SALOON", "HE WAVES A BOTTLE AT YOU", "SAY HELLO"]
		"w_merchant":
			return ["A LOST MERCHANT", "ONE " + str(o["sells"]).to_upper() + " FOR SALE", "PAY %d GOLD" % o["price"]]
	return ["", "", ""]

# ---------- Drawing ----------
static func draw(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x: float = o["x"]
	var y: float = o["y"]
	var breathe := roundf(sin(t * 2.0 + x) * 0.6)
	match o["kind"]:
		"e_decor":
			Gfx.sp(ci, o["sprite"], x, y, 2, 2)
		"e_pitboss":
			Gfx.sp(ci, "npc_pitboss", x, y + breathe)
		"e_mechanic":
			Gfx.sp(ci, "npc_mechanic", x, y + breathe)
		"e_teller":
			Gfx.sp(ci, "npc_teller", x, y + breathe)
		"e_card":
			if o.get("shown", false):
				Gfx.sp(ci, "card_front", x, y, 2, 2)
				Gfx.text(ci, o["name"], x, y + 4, "gold", 1, 0.5)
			else:
				Gfx.sp(ci, "card_back", x, y + roundf(sin(t * 3 + x) * 1.5), 2, 2)
		"e_courier":
			Gfx.sp(ci, "npc_courier", x, y + breathe)
		"e_attendant":
			Gfx.sp(ci, "npc_attendant", x, y + breathe)
			if o["t"] > 0:
				Gfx.text(ci, "%d  %dS" % [o["score"], ceili(o["t"])], x, y - 26, "gold", 1, 0.5)
		"e_beacon":
			Gfx.sp(ci, "beacon", x, y, 2, 2)
			if o["lit"]:
				var held: float = o["held"] / BEACON_TIME
				var k := 0
				while k < 48:
					var a := float(k) / 48.0 * TAU + t * 0.5
					var col := "#6fd3e0" if float(k) / 48.0 < held else "#2b4f8a"
					Gfx.px(ci, TB.c(col), x + cos(a) * BEACON_R, y + sin(a) * BEACON_R * 0.7, 2)
					k += 1
				if held < 1.0:
					Gfx.text(ci, "%dS" % ceili(BEACON_TIME - o["held"]), x, y - 44, "cyan", 1, 0.5)
		"e_statue":
			Gfx.sp(ci, "statue", x, y, 2, 2)
			var since: float = G.time - o["show_t"]
			if since >= 0 and since < 4.0:
				var i := floori(since)
				if fmod(since, 1.0) < 0.7:
					var col: String = { "r": "#d8443c", "g": "#63b84f", "u": "#4d9be6", "y": "#f2c94c" }[o["order"][i]]
					Gfx.px(ci, TB.c(col), x - 4, y - 27, 3)
					Gfx.px(ci, TB.c(col), x + 2, y - 27, 3)
		"e_plate":
			Gfx.sp(ci, ("plate_" + o["col"]) if o["lit"] else "plate_off", x, y + 8)
			if not o["lit"]:
				var col: String = { "r": "#d8443c", "g": "#63b84f", "u": "#4d9be6", "y": "#f2c94c" }[o["col"]]
				Gfx.px(ci, TB.c(col), x - 1, y + 2, 2)
		"n_endbook":
			if not o.get("used", false):
				Gfx.sp(ci, "tome", x, y + 6, 2, 2)
				Gfx.text(ci, "THE END", x, y - 30, "bone", 1, 0.5)
		"n_turnpage":
			if not o.get("used", false):
				var zm := 2.0 + sin(t * 3) * 0.08
				Gfx.sp(ci, "riftdoor", x, y + 8, zm, zm)
				Gfx.text(ci, "CHAPTER II", x, y - 34, "gold", 1, 0.5)
		"n_tornpage":
			if not o.get("gone", false):
				Gfx.sp(ci, "tornpage", x, y + sin(t * 2.5) * 2.0)
		"e_pond":
			Fishing.draw_pond(ci, o, t)
		"e_angler":
			Fishing.draw_angler(ci, o, t)
		"c_portal", "c_wardrobe", "c_shrine", "c_telescope", "c_dummy", "c_board", "c_daily", "c_cook", "c_rack", "v_peddler", "v_bard", "v_seer", "v_monger", "v_cat", "v_gambler", "v_tinker", "c_build", "c_deco":
			Camp.draw(ci, o, t)
		"e_pot":
			pass   # 17.1: drawn with the doors (RoomDress.paint_dyn)
		"e_coins":
			if not o.get("gone", false):
				RoomDress.draw_coins(ci, o, t)
		"e_keg":
			if not o.get("gone", false):
				RoomDress.draw_fuse(ci, o, t)
		"n_readon":
			if not o.get("used", false):
				var zq := 2.0 + sin(t * 3) * 0.08
				Gfx.sp(ci, "riftdoor", x, y + 8, zq, zq)
				Gfx.text(ci, "CHAPTER III", x, y - 34, "gold", 1, 0.5)
		"n_shelf":
			if not o.get("used", false):
				var zs := 2.0 + sin(t * 3) * 0.08
				Gfx.sp(ci, "riftdoor", x, y + 8, zs, zs)
				Gfx.text(ci, "CHAPTER IV", x, y - 34, "gold", 1, 0.5)
		"n_redactdoor":
			if not o.get("used", false):
				var zr := 2.0 + sin(t * 4) * 0.1
				Gfx.sp(ci, "riftdoor", x, y + 8, zr, zr)
				Gfx.text(ci, "???", x, y - 34, "red", 1, 0.5)
		"n_inkling":
			if not o.get("used", false):
				Gfx.sp(ci, "npc_inkling", x, y + absf(sin(t * 5.0)) * -2.0)
		"n_bookbinder":
			Gfx.sp(ci, "npc_bookbinder", x, y + breathe)
			if o.get("relic") != null:
				Gfx.text(ci, "RELIC", x, y - 24, "gold", 1, 0.5)
		"n_archivist":
			Gfx.sp(ci, "npc_archivist", x, y + breathe)
			if Story.has_new():
				Gfx.text(ci, "!", x, y - 24 - absf(sin(t * 4.0)) * 2.0, "gold", 1, 0.5)
		# 10.2
		"e_frog":
			if not o.get("gone", false):
				ci.draw_circle(Vector2(x, y + 4), 11, TB.c("#2f6a3a"))
				ci.draw_circle(Vector2(x, y + 4), 9, TB.c("#3f8a4a"))
				Gfx.sp(ci, "frog", x, y + 2 - absf(sin(t * 2.5)) * 3.0, 2, 2)
		"e_glyph":
			var gl: Array = GLYPHS[o["sign"]]
			var col := TB.c(Alignments.HEX[gl[1]])
			col.a = 0.35 if o.get("used", false) else 0.9
			ci.draw_arc(Vector2(x, y), 12, 0, TAU, 20, col, 1.5)
			ci.draw_arc(Vector2(x, y), 9, 0, TAU, 20, col, 1.0)
			Gfx.sp(ci, TraitView.ICONS[Alignments.NAMES[gl[1]]], x, y + 7, 2, 2, 0.0, false, 0.4 if o.get("used", false) else 1.0)
		"e_pawn":
			Gfx.sp(ci, "npc_merchant", x, y + breathe)
			Gfx.sp(ci, "mi_gold", x + 9, y - 22, 1, 1)
		"e_hustler":
			Gfx.sp(ci, "npc_attendant", x, y + breathe)
			if o["state"] == "show" or (o["state"] == "reveal"):
				var shown: int = o["ball"] if o["state"] == "show" else -1
				for c in G.room.objects:
					if c["kind"] == "e_cup" and (c["i"] == shown or (shown < 0 and o["order"][c["i"]] == o["ball"])):
						var cp := cup_pos(o, c)
						ci.draw_circle(Vector2(cp.x, cp.y + 3), 3.5, TB.c("#f4ecd8"))
		"e_cup":
			var h = _hustler()
			var cp := cup_pos(h, o) if h != null else Vector2(x, y)
			var lift := 0.0
			if h != null and h["state"] in ["show", "reveal"]:
				lift = 10.0
			var cx2 := cp.x
			var cy2 := cp.y - lift
			ci.draw_colored_polygon(PackedVector2Array([Vector2(cx2 - 8, cy2 + 6), Vector2(cx2 + 8, cy2 + 6), Vector2(cx2 + 5, cy2 - 8), Vector2(cx2 - 5, cy2 - 8)]), TB.c("#8a3a2a"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(cx2 - 6, cy2 + 4), Vector2(cx2 - 2, cy2 + 4), Vector2(cx2 - 2, cy2 - 6), Vector2(cx2 - 4, cy2 - 6)]), TB.c("#c05a3a"))
			ci.draw_rect(Rect2(cx2 - 9, cy2 + 5, 18, 2), TB.c("#5a2418"))
		"e_gong":
			ci.draw_line(Vector2(x - 14, y + 6), Vector2(x - 14, y - 26), TB.c("#6b4a2a"), 2.0)
			ci.draw_line(Vector2(x + 14, y + 6), Vector2(x + 14, y - 26), TB.c("#6b4a2a"), 2.0)
			ci.draw_line(Vector2(x - 15, y - 26), Vector2(x + 15, y - 26), TB.c("#6b4a2a"), 2.0)
			var sw := sin(t * 6.0) * 1.5 if o["waves"] > 0 else 0.0
			ci.draw_circle(Vector2(x + sw, y - 10), 11, TB.c("#b8862a"))
			ci.draw_circle(Vector2(x + sw, y - 10), 8, TB.c("#e8b84a"))
			ci.draw_circle(Vector2(x + sw, y - 10), 3, TB.c("#fff07a"))
			if o["waves"] > 0:
				Gfx.text(ci, "%dS" % maxi(0, ceili(o["t"])), x, y - 34, "gold" if o["t"] > 0 else "red", 1, 0.5)
		"w_drunk":
			Gfx.sp(ci, "npc_drunk", x, y + 6, 1, 1)
		"w_merchant":
			Gfx.sp(ci, "npc_merchant", x, y + breathe)
