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
	"e_plate", "e_decor", "w_drunk", "w_merchant"]
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
		"w_drunk":
			Gfx.sp(ci, "npc_drunk", x, y + 6, 1, 1)
		"w_merchant":
			Gfx.sp(ci, "npc_merchant", x, y + breathe)
