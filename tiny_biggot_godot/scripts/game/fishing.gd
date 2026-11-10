class_name Fishing
extends RefCounted
## 15.1 Fishing (his ask, 7 Oct: "can you add fishing"); 15.2 made it a place worth stopping at
## (his ask: "make it better, not blank and soulless"). This game's own; expanded game only.
##
## PONDS (EventRooms kind "e_pond") sit in some rest stops and treasure rooms; THE FISHING HOLE is a
## mystery room with a lake, a dock and THE ANGLER, who sells bait and rewards a good haul.
## A pond lives: an uneven shore with stones and reeds, deeper water in the middle, lily pads, light
## on the water, fish shadows gliding about (one swims up to your float when it bites), ripples and
## fireflies. You cannot walk on water (keep_out); you fish from the shore or the dock.
##   CAST    the line goes out; wait for a bite (pressing USE now is too soon: the fish flees)
##   BITE    a "!" over the float: press USE in time
##   REEL    the fish darts up and down a bar; hold USE to lift your net, let go to drop it. While
##           the fish is in the net the catch bar fills; outside it drains. Full: it leaps out.
## Each world has fish of its own; junk, treasure and rare fish turn up anywhere, a legendary one
## seldom (luck and bait help). Every catch does something at once. Kept between runs:
## Meta.meta["fish"]. MENU lets go of the line.

const CASTS := 3
## id: [name, colour, rarity, difficulty, what it does, where (floor range) or [] for anywhere]
const FISH := {
	"mudfin": ["MUDFIN", "#7a5236", "common", 1.0, "HEALS HALF A HEART", []],
	"bonecarp": ["BONE CARP", "#d9d0b4", "common", 1.0, "6 GOLD", []],
	"glimmer": ["GLIMMER MINNOW", "#6fd3e0", "common", 0.9, "A GEM", []],
	"crypteel": ["CRYPT EEL", "#5c3483", "common", 1.2, "A POTION", [0, 3]],
	"embertrout": ["EMBER TROUT", "#e8873a", "common", 1.3, "HEALS A HEART AND 10 GOLD", [4, 7]],
	"gloompike": ["GLOOM PIKE", "#2a2838", "common", 1.4, "A STAT PICKUP", [8, 10]],
	"inkfish": ["INKFISH", "#2a2a4a", "common", 1.5, "A STAT PICKUP", [11, 13]],
	"pagepike": ["PAGE PIKE", "#f4ecd8", "common", 1.5, "25 GOLD", [14, 99]],
	"oldboot": ["OLD BOOT", "#4e4a5e", "junk", 0.6, "NOTHING. IT IS A BOOT", []],
	"rustkey": ["RUSTED KEY", "#a8705a", "junk", 0.7, "A KEY", []],
	"soddenscroll": ["SODDEN SCROLL", "#c8a878", "junk", 0.7, "A GEM, DRIED OUT", []],
	"goldcarp": ["GOLDEN CARP", "#f2c94c", "rare", 1.7, "40 GOLD", []],
	"armorbass": ["ARMORED BASS", "#8b8f9c", "rare", 1.7, "2 ARMOR", []],
	"sunkenchest": ["SUNKEN CHEST", "#8a6a4a", "rare", 1.5, "A PIECE OF GEAR", []],
	"moonkoi": ["MOONLIT KOI", "#c8f0ff", "legend", 2.2, "A RELIC AND FULL HEALTH", []],
	"oldone": ["THE OLD ONE", "#3f7a5a", "legend", 2.5, "A RELIC AND +1 MAX HEART", []],
	# V2 (his word, 23 Oct): the fish of his icon sheet (another artist's, for his own use only: CLAUDE.md,
	# rule 3; branch tiny-biggot-V2 only, the repo private). Anywhere; what each catch gives: REWARD.
	"mantaray": ["MANTA RAY", "#3a3a44", "rare", 1.6, "2 ARMOR", []],
	"rockfish": ["ROCKFISH", "#d8443c", "common", 1.1, "12 GOLD", []],
	"clownfish": ["CLOWNFISH", "#e8873a", "common", 1.0, "HEALS HALF A HEART", []],
	"pufferfish": ["PUFFERFISH", "#f2c94c", "common", 1.2, "A BOMB", []],
	"bass": ["LARGEMOUTH BASS", "#63b84f", "common", 1.2, "A MEAL", []],
	"parrotfish": ["PARROTFISH", "#4dc8c8", "common", 1.1, "A GEM", []],
	"blueseahorse": ["BLUE SEAHORSE", "#4d9be6", "rare", 1.5, "A KEY AND 15 GOLD", []],
	"blueshark": ["BLUE SHARK", "#4d9be6", "rare", 1.9, "+1 WEAPON LEVEL", []],
	"crayfish": ["CRAYFISH", "#d8643c", "common", 1.0, "8 GOLD", []],
	"squid": ["SQUID", "#e86fb4", "common", 1.2, "A POTION", []],
	"koi": ["KOI", "#f4ecd8", "rare", 1.6, "+1 LUCK", []],
	"goldfish": ["GOLDFISH", "#f2a03c", "common", 0.9, "5 GOLD", []],
	"mackerel": ["MACKEREL", "#6fd3e0", "common", 1.1, "A MEAL", []],
	"bluetang": ["BLUE TANG", "#2a5ad8", "common", 1.1, "HEALS A HEART", []],
	"catfish": ["CATFISH", "#7a5a3a", "common", 1.3, "A STAT PICKUP", []],
	"redsnapper": ["RED SNAPPER", "#e8645a", "common", 1.1, "10 GOLD", []],
	"trout": ["TROUT", "#a8a8b0", "common", 1.0, "A MEAL", []],
	"angelfish": ["ANGELFISH", "#f2d24c", "rare", 1.5, "FULL HEALTH", []],
	"perch": ["PERCH", "#9ad07a", "common", 1.0, "HEALS HALF A HEART", []],
	"wrasse": ["TEAL WRASSE", "#3fb8b0", "common", 1.1, "A GEM", []],
	"swordfish": ["SWORDFISH", "#2a4a8a", "rare", 1.9, "+1 WEAPON LEVEL", []],
	"goldseahorse": ["GOLDEN SEAHORSE", "#f2a03c", "rare", 1.7, "50 GOLD", []],
	"devilfish": ["RED DEVILFISH", "#c83c3c", "rare", 1.8, "A STAT PICKUP AND A BOMB", []],
	"mudshark": ["MUD SHARK", "#6a5a4a", "rare", 1.8, "3 ARMOR", []],
	"sunfish": ["SUNFISH", "#f2c94c", "rare", 1.6, "+1 TO YOUR BEST ATTRIBUTE", []],
	"greatshark": ["GREAT SHARK", "#4d7ad8", "legend", 2.4, "A RELIC AND 2 ARMOR", []],
	"anglerfish": ["ANGLERFISH", "#3fa8c8", "legend", 2.3, "A RELIC AND A KEY", []],
	"dolphin": ["DOLPHIN", "#a8a8c8", "rare", 1.4, "IT SMILES AND SWIMS OFF: +1 LUCK", []],
	"hermitcrab": ["HERMIT CRAB", "#c87a5a", "junk", 0.8, "3 GOLD", []],
}
## V2: what a fish of his sheet gives: ["gold", n], ["heal", n], ["armor", n], ["drop", pickup], ["food"]
## (a meal), ["stat"] (a stat pickup), ["luck"] (+1 for the run), ["upgrade"] (+1 weapon level),
## ["attr"] (+1 to the best attribute), ["relic"].
const REWARD := {
	"mantaray": [["armor", 2]],
	"rockfish": [["gold", 12]],
	"clownfish": [["heal", 1]],
	"pufferfish": [["drop", "bomb"]],
	"bass": [["food"]],
	"parrotfish": [["drop", "gem"]],
	"blueseahorse": [["drop", "key"], ["gold", 15]],
	"blueshark": [["upgrade"]],
	"crayfish": [["gold", 8]],
	"squid": [["drop", "potion"]],
	"koi": [["luck"]],
	"goldfish": [["gold", 5]],
	"mackerel": [["food"]],
	"bluetang": [["heal", 2]],
	"catfish": [["stat"]],
	"redsnapper": [["gold", 10]],
	"trout": [["food"]],
	"angelfish": [["heal", 99]],
	"perch": [["heal", 1]],
	"wrasse": [["drop", "gem"]],
	"swordfish": [["upgrade"]],
	"goldseahorse": [["gold", 50]],
	"devilfish": [["stat"], ["drop", "bomb"]],
	"mudshark": [["armor", 3]],
	"sunfish": [["attr"]],
	"greatshark": [["relic"], ["armor", 2]],
	"anglerfish": [["relic"], ["drop", "key"]],
	"dolphin": [["luck"]],
	"hermitcrab": [["gold", 3]],
}
const WEIGHT := { "common": 60, "junk": 22, "rare": 14, "legend": 4 }
const RARITY_COL := { "common": "white", "junk": "grey", "rare": "gold", "legend": "pink" }
const BAIT_PRICE := 20
const ANGLER_TIPS := [
	"\"WAIT FOR THE FLOAT TO DANCE. THEN STRIKE.\"",
	"\"KEEP THE NET UNDER THE FISH. LET IT TIRE ITSELF OUT.\"",
	"\"EVERY WORLD HAS ITS OWN FISH. CATCH THEM ALL, IF YOU CAN.\"",
	"\"THEY SAY THE OLD ONE HAS SLEPT HERE SINCE THE FIRST PAGE.\"",
	"\"A BOOT IS STILL A CATCH. NOT A GOOD ONE.\"",
]

static var pond: Dictionary = {}
static var phase := ""      # cast, bite, reel, done
static var t := 0.0
static var fish_id := ""
static var pos := 0.5        # the fish on the bar, 0 (bottom) .. 1 (top)
static var goal := 0.5
static var box := 0.3        # the bottom of your net
static var boxv := 0.0
static var prog := 0.0
static var result := ""      # what the last cast brought (shown in the panel)
static var fresh := false     # the first one of its kind ever
static var leap: Dictionary = {}   # the catch flying out of the water: { id, t }
static var auto := false   # tests and --fish-auto: the line plays itself (strikes, follows the fish)

const BOX_H := 0.26

static func active() -> bool:
	return G.state == &"fishing"

# ---------- Ponds ----------
## A pond centred at cx, cy (radii rx, ry). With a dock you fish from its end, else from the shore.
static func place(r: Room, cx: float, cy: float, rx: float = 30.0, ry: float = 14.0, dock: bool = false, casts: int = CASTS) -> Dictionary:
	var o := { "kind": "e_pond", "cx": cx, "cy": cy, "rx": rx, "ry": ry, "dock": dock, "casts": casts,
		"seed": randf() * 100.0, "caught": 0 }
	o["x"] = cx
	o["y"] = cy + ry * (0.45 if dock else 1.0) + (10.0 if dock else 8.0)
	r.objects.append(o)
	return o

## THE FISHING HOLE (a mystery room): a lake with a dock, the Angler, crates and lanterns.
static func setup_hole(r: Room) -> void:
	var cx := 14.0 * TB.TS
	var o := place(r, cx, 112.0, 130.0, 48.0, true, 5)
	o["big"] = true
	r.objects.append({ "kind": "e_angler", "x": cx + 46, "y": 196.0, "pond": o, "rewarded": false })

static func _shore(o: Dictionary, a: float) -> float:
	var s: float = o["seed"]
	return 1.0 + 0.07 * sin(3.0 * a + s) + 0.05 * sin(5.0 * a + 2.0 * s) + 0.03 * sin(7.0 * a + 3.0 * s)

static func _pts(o: Dictionary, k: float, n: int = 28) -> PackedVector2Array:
	var c := Vector2(o["cx"], o["cy"])
	var out := PackedVector2Array()
	for i in n:
		var a := i * TAU / n
		var f := _shore(o, a) * k
		out.append(c + Vector2(cos(a) * o["rx"] * f, sin(a) * o["ry"] * f))
	return out

static func _dock_rect(o: Dictionary) -> Rect2:
	var top: float = o["cy"] + o["ry"] * 0.35
	var bottom: float = o["cy"] + o["ry"] * 1.25 + 8.0
	return Rect2(o["cx"] - 10.0, top, 20.0, bottom - top)

## Nobody walks on water: the hero is nudged back onto the shore (or stays on the dock).
static func keep_out(p: Player) -> void:
	if G.room == null or p == null:
		return
	for o in G.room.objects:
		if o["kind"] != "e_pond":
			continue
		if o["dock"] and _dock_rect(o).grow(-2.0).has_point(Vector2(p.x, p.y)):
			continue
		var dx: float = p.x - o["cx"]
		var dy: float = p.y - o["cy"]
		var a := atan2(dy / o["ry"], dx / o["rx"])
		var f := _shore(o, a) * 1.02
		var e := pow(dx / (o["rx"] * f), 2) + pow(dy / (o["ry"] * f), 2)
		if e <= 0.0001:
			p.y = o["cy"] + o["ry"] * _shore(o, PI * 0.5) * 1.05   # dead centre: out to the near shore
		elif e < 1.0:
			var k := 1.0 / sqrt(e)
			p.x = o["cx"] + dx * k
			p.y = o["cy"] + dy * k

# ---------- Casting ----------
## USE at the pond: cast.
static func start(o: Dictionary) -> void:
	if o.get("casts", 0) <= 0:
		G.toast("THE FISH HAVE GONE QUIET HERE", "grey")
		return
	pond = o
	o["casts"] -= 1
	if o["casts"] <= 0:
		o["used"] = true
	phase = "cast"
	t = 1.0 + randf() * 2.5
	result = ""
	fresh = false
	leap = {}
	G.state = &"fishing"
	Snd.play("dodge")

static func _pick() -> String:
	var f := G.floor_index
	var luck := G.player.luck if G.player != null else 0
	var w := {}
	for id in FISH:
		var d: Array = FISH[id]
		var where: Array = d[5]
		if not where.is_empty() and (f < where[0] or f > where[1]) and not pond.get("camp", false):
			continue   # the camp's pond has every world's fish
		var wt: float = WEIGHT[d[2]]
		if d[2] in ["rare", "legend"]:
			wt *= (1.0 + 0.25 * luck) * (2.5 if pond.get("bait", false) else 1.0) * (1.5 if pond.get("big", false) else 1.0)
		w[id] = wt
	return TB.weighted(w)

static func update(dt: float) -> void:
	if leap.has("t"):
		leap["t"] += dt
	if Keys.back():
		_finish("YOU LET GO OF THE LINE")
		G.state = &"play"
		return
	t -= dt
	match phase:
		"cast":
			if Keys.use():
				_finish("TOO SOON! THE FISH FLED")
			elif t <= 0:
				fish_id = _pick()
				phase = "bite"
				t = 0.75 if FISH[fish_id][2] != "legend" else 0.55
				Snd.play("bell")
				Fx.burst(_bob().x, _bob().y, ["#c8f0ff", "#ffffff"], 6, 20)
		"bite":
			if Keys.use() or (auto and t < 0.5):
				phase = "reel"
				prog = 0.3
				pos = 0.5
				goal = randf()
				box = 0.35
				boxv = 0.0
				Snd.play("select")
			elif t <= 0:
				_finish("IT GOT AWAY")
		"reel":
			_reel(dt)
		"done":
			if t <= 0 or (Keys.use() and not auto):
				G.state = &"play"

static func _reel(dt: float) -> void:
	var diff: float = FISH[fish_id][3]
	# The fish darts toward a new spot now and then; harder fish more often and faster.
	if randf() < dt * (0.9 + diff * 0.6):
		goal = randf()
	pos = move_toward(pos, goal, dt * (0.35 + diff * 0.3))
	var hold := Keys.pressed(&"use") or (auto and pos > box + BOX_H * 0.5)
	boxv += (2.6 if hold else -2.2) * dt
	boxv = clampf(boxv, -1.4, 1.4)
	box += boxv * dt
	if box < 0.0:
		box = 0.0
		boxv = 0.0
	if box > 1.0 - BOX_H:
		box = 1.0 - BOX_H
		boxv = 0.0
	if pos >= box and pos <= box + BOX_H:
		prog += dt * 0.32
	else:
		prog -= dt * (0.16 + 0.06 * diff)
	if randf() < dt * 3.0:
		var b := _bob()
		Fx.burst(b.x + randf_range(-4, 4), b.y, ["#c8f0ff", "#6fd3e0"], 3, 16)   # thrashing
	if prog >= 1.0:
		_catch()
	elif prog <= 0.0:
		_finish("THE " + FISH[fish_id][0] + " SLIPPED THE HOOK")

static func _finish(msg: String) -> void:
	result = msg
	phase = "done"
	t = 1.2
	Snd.play("deny")

static func _catch() -> void:
	var d: Array = FISH[fish_id]
	if not (Meta.meta.get("fish") is Dictionary):
		Meta.meta["fish"] = {}
	fresh = not Meta.meta["fish"].has(fish_id)
	CampLife.stock(fish_id)   # 19.2: into the larder (for the camp's cook)
	Meta.meta["fish"][fish_id] = int(Meta.meta["fish"].get(fish_id, 0)) + 1
	G.run_stats["fish"] = G.run_stats.get("fish", 0) + 1
	pond["caught"] = pond.get("caught", 0) + 1
	_reward(fish_id)
	result = d[4]
	phase = "done"
	t = 2.6
	leap = { "id": fish_id, "t": 0.0 }
	Snd.play("relic" if d[2] == "legend" else ("unlock" if d[2] == "rare" else "coin"))
	var b := _bob()
	Fx.burst(b.x, b.y, ["#c8f0ff", "#ffffff", "#6fd3e0"], 22 if d[2] != "legend" else 40, 70)
	if d[2] in ["rare", "legend"]:
		G.add_shake(3 if d[2] == "rare" else 7)
	if d[2] == "legend":
		G.show_banner("A LEGEND FROM THE DEEP", d[0])
		Juice.flash(0.25)
	Meta.write_save()

static func _reward(id: String) -> void:
	var p := G.player
	var x: float = pond["x"]
	var y: float = pond["y"] + 12
	if REWARD.has(id):   # V2: a fish of his sheet
		_give(id, x, y)
		return
	match id:
		"mudfin": p.heal(1)
		"bonecarp": _gold(6)
		"glimmer": Combat.drop_pickup("gem", x, y)
		"crypteel": Combat.drop_pickup("potion", x, y)
		"embertrout":
			p.heal(2)
			_gold(10)
		"gloompike", "inkfish": StatDrops.maybe(1.0, x, y)
		"pagepike": _gold(25)
		"oldboot": pass
		"rustkey": Combat.drop_pickup("key", x, y)
		"soddenscroll": Combat.drop_pickup("gem", x, y)
		"goldcarp": _gold(40)
		"armorbass":
			Combat.drop_pickup("armor", x, y)
			Combat.drop_pickup("armor", x, y)
		"sunkenchest": G.drop_item(Gear.random_gear(Gear.roll_item_rarity(G.floor_index, "elite")), x, y)
		"moonkoi", "oldone":
			var rel := G.roll_relics(1, "iron")
			if not rel.is_empty():
				G.add_relic(p, rel[0])
			if id == "moonkoi":
				p.hp = p.max_hp
			else:
				p.max_hp += 2
				p.hp += 2

## V2: a fish of his sheet: what REWARD says.
static func _give(id: String, x: float, y: float) -> void:
	var p := G.player
	for r in REWARD[id]:
		match r[0]:
			"gold": _gold(int(r[1]))
			"heal": p.heal(int(r[1]))
			"armor":
				for i in int(r[1]):
					Combat.drop_pickup("armor", x, y)
			"drop": Combat.drop_pickup(r[1], x, y)
			"food": Combat.drop_pickup(Food.roll_meal(), x, y)
			"stat": StatDrops.maybe(1.0, x, y)
			"luck": p.luck += 1
			"upgrade": WeaponInfo.upgrade(p, 1)
			"attr": Attributes.add(p, Attributes.highest(p), 1)
			"relic":
				var rel := G.roll_relics(1, "iron")
				if not rel.is_empty():
					G.add_relic(p, rel[0])

static func _gold(n: int) -> void:
	G.player.gold += n
	G.run_stats["gold"] = G.run_stats.get("gold", 0) + n

## How many kinds have ever been caught.
static func caught_kinds() -> int:
	return (Meta.meta["fish"] as Dictionary).size() if Meta.meta.get("fish") is Dictionary else 0

static func sprite_of(id: String) -> String:
	match id:
		"rustkey": return "key"
		"sunkenchest": return "chest"
	return "fish_" + id

# ---------- The Angler ----------
static func angler(o: Dictionary) -> void:
	var pd: Dictionary = o["pond"]
	var p := G.player
	if pd.get("camp", false):
		G.show_banner("THE ANGLER", "\"MY POND HAS A FISH FROM EVERY WORLD. %d OF %d FOUND.\"" % [caught_kinds(), FISH.size()])
		Snd.play("select")
		return
	if pd.get("caught", 0) >= 3 and not o["rewarded"]:
		o["rewarded"] = true
		var rel := G.roll_relics(1, "iron")
		if not rel.is_empty():
			G.add_relic(p, rel[0])
		G.show_banner("THE ANGLER", "\"NOW THAT IS FISHING. TAKE THIS, I FOUND IT IN A CARP.\"")
		Snd.play("relic")
		return
	if not pd.get("bait", false):
		if p.gold < G.price(BAIT_PRICE):
			G.deny(o, "NEED %d GOLD" % G.price(BAIT_PRICE))
			return
		p.gold -= G.price(BAIT_PRICE)
		pd["bait"] = true
		pd["casts"] += 2
		pd.erase("used")
		G.show_banner("GLOW-WORM BAIT", "RARE FISH BITE FAR MORE. +2 CASTS")
		Snd.play("coin")
		return
	G.show_banner("THE ANGLER", ANGLER_TIPS[randi() % ANGLER_TIPS.size()])
	Snd.play("select")

static func angler_prompt(o: Dictionary) -> Array:
	var pd: Dictionary = o["pond"]
	if pd.get("camp", false):
		return ["THE ANGLER", "FISH HERE AS LONG AS YOU LIKE", "TALK"]
	if pd.get("caught", 0) >= 3 and not o["rewarded"]:
		return ["THE ANGLER", "HE WANTS TO SEE YOUR HAUL", "SHOW HIM"]
	if not pd.get("bait", false):
		return ["THE ANGLER", "GLOW-WORM BAIT: RARE FISH BITE MORE, +2 CASTS", "BUY FOR %d GOLD" % G.price(BAIT_PRICE)]
	return ["THE ANGLER", ("CATCH 3 FISH HERE FOR A GIFT (%d/3)" % mini(3, pd.get("caught", 0))) if not o["rewarded"] else "HE NODS AT THE WATER", "TALK"]

# ---------- Drawing ----------
static func _bob() -> Vector2:
	if pond.is_empty():
		return Vector2.ZERO
	if pond["dock"]:
		return Vector2(pond["cx"] + 6.0, pond["cy"] - pond["ry"] * 0.15)
	return Vector2(pond["cx"] + 4.0, pond["cy"] - 1.0)

static func _ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := i * TAU / 10.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)

## The pond in the room. 17.1: what never moves (bank, water, lily pads, reeds, the dock, lantern
## posts) is drawn once into the room's background (RoomDress.paint_static: live = false); the rest
## every frame (EventRooms.draw: live = true).
static func draw_pond(ci: CanvasItem, o: Dictionary, tm: float, live: bool = true) -> void:
	var c := Vector2(o["cx"], o["cy"])
	var rx: float = o["rx"]
	var ry: float = o["ry"]
	var s: float = o["seed"]
	var big: bool = o.get("big", false)
	var n := 40 if big else 28
	if not live:
		_pond_still(ci, o, c, rx, ry, s, big, n)
		return
	_pond_moving(ci, o, c, rx, ry, s, big, tm)

static func _pond_still(ci: CanvasItem, o: Dictionary, c: Vector2, rx: float, ry: float, s: float, big: bool, n: int) -> void:
	# The bank: mud, then a ring of stones and tufts of grass.
	var bank := _pts(o, 1.16, n)
	ci.draw_colored_polygon(bank, TB.c("#4a3a2a"))
	ci.draw_colored_polygon(_pts(o, 1.08, n), TB.c("#5a4632"))
	for i in n:
		var pt := bank[i]
		var k := int(s * 7 + i * 13) % 5
		if k < 2:
			ci.draw_circle(pt, 2.5 if k == 0 else 2.0, TB.c("#6b6a72" if k == 0 else "#8b8f9c"))
			ci.draw_circle(pt + Vector2(-0.5, -0.8), 1.0, TB.c("#b0b4c0"))
		elif k == 3:
			for g in 3:
				ci.draw_line(pt + Vector2(g * 2 - 2, 0), pt + Vector2(g * 2 - 3, -4 - g), TB.c("#3f7a3a"), 1.0)
	# The water: deeper toward the middle.
	ci.draw_colored_polygon(_pts(o, 1.0, n), TB.c("#3a7ea8"))
	ci.draw_colored_polygon(_pts(o, 0.84, n), TB.c("#2f6f9a"))
	ci.draw_colored_polygon(_pts(o, 0.62, n), TB.c("#275e86"))
	ci.draw_colored_polygon(_pts(o, 0.38, n), TB.c("#1f4b6e"))
	var edge := _pts(o, 1.0, n)
	edge.append(edge[0])
	ci.draw_polyline(edge, Color(0.75, 0.92, 1.0, 0.55), 1.0)
	# Lily pads, some with a flower.
	var pads := 7 if big else 3
	for k in pads:
		var a := s + k * 2.39
		var f := 0.62 + 0.25 * fmod(k * 0.53, 1.0)
		var pp := c + Vector2(cos(a) * rx * f, sin(a) * ry * f)
		var r := 4.5 if big else 3.5
		ci.draw_circle(pp, r, TB.c("#3f8a4a"))
		ci.draw_circle(pp + Vector2(-0.8, -0.8), r - 1.5, TB.c("#5aa85a"))
		ci.draw_colored_polygon(PackedVector2Array([pp, pp + Vector2(cos(a) * r * 1.2, sin(a) * r * 1.2 - 1), pp + Vector2(cos(a) * r * 1.2 + 2, sin(a) * r * 1.2 + 1)]), TB.c("#2f6f9a"))
		if k % 3 == 0:
			ci.draw_circle(pp + Vector2(1, -1), 1.6, TB.c("#e86fb4"))
			ci.draw_circle(pp + Vector2(1, -1), 0.7, TB.c("#fff0f8"))
	# Reeds and cattails on the far bank and the sides.
	var reeds := 10 if big else 4
	for k in reeds:
		var a := PI + 0.25 + k * (PI - 0.5) / maxf(1.0, reeds - 1) + sin(s + k) * 0.08
		var base := c + Vector2(cos(a) * rx * _shore(o, a) * 1.05, sin(a) * ry * _shore(o, a) * 1.05)
		for st in 3:
			var h := 9.0 + float((k * 7 + st * 3) % 6) + (4.0 if big else 0.0)
			var sway := sin(k * 1.7 + st) * 1.0
			var top := base + Vector2(st * 2.0 - 2.0 + sway, -h)
			ci.draw_line(base + Vector2(st * 2.0 - 2.0, 0), top, TB.c("#3f6a3a" if st != 1 else "#4f7f45"), 1.0)
			if st == 1:
				ci.draw_rect(Rect2(top.x - 1, top.y, 2, 4), TB.c("#6b4a2a"))
	# The dock: planks out over the water, posts, a coil of rope.
	if o["dock"]:
		var dr := _dock_rect(o)
		ci.draw_rect(Rect2(dr.position + Vector2(1, 2), dr.size), Color(0, 0, 0, 0.3))
		ci.draw_rect(dr, TB.c("#7a5236"))
		var yy := dr.position.y
		while yy < dr.end.y:
			ci.draw_line(Vector2(dr.position.x, yy), Vector2(dr.end.x, yy), TB.c("#5a3a22"), 1.0)
			ci.draw_line(Vector2(dr.position.x + 1, yy + 1), Vector2(dr.end.x - 1, yy + 1), TB.c("#9a6a42"), 1.0)
			yy += 4.0
		for px in [dr.position.x - 1, dr.end.x - 2]:
			ci.draw_rect(Rect2(px, dr.position.y - 3, 3, 6), TB.c("#4a3020"))
			ci.draw_rect(Rect2(px, dr.position.y + dr.size.y * 0.5, 3, 5), TB.c("#4a3020"))
		ci.draw_arc(Vector2(dr.end.x - 5, dr.end.y - 6), 2.5, 0, TAU, 8, TB.c("#c8a878"), 1.0)
	# Lantern posts on the bank (the big lake); their flames move.
	if big:
		for k in 4:
			var a: float = [PI * 1.15, PI * 1.85, PI * 0.2, PI * 0.8][k]
			var lp := c + Vector2(cos(a) * rx * 1.2, sin(a) * ry * 1.3)
			ci.draw_rect(Rect2(lp.x - 1, lp.y - 14, 2, 14), TB.c("#4a3020"))
			ci.draw_rect(Rect2(lp.x - 3, lp.y - 19, 6, 6), TB.c("#2a2018"))

static func _pond_moving(ci: CanvasItem, o: Dictionary, c: Vector2, rx: float, ry: float, s: float, big: bool, tm: float) -> void:
	# Fish shadows gliding about (one comes to the float when something bites).
	var shadows := 6 if big else 3
	for k in shadows:
		var sp := 0.25 + 0.12 * k
		var a := tm * sp * (1 if k % 2 == 0 else -1) + s + k * 2.1
		var sc := 0.25 + 0.45 * fmod(k * 0.37 + s * 0.01, 1.0)
		var at := c + Vector2(cos(a) * rx * sc, sin(a) * ry * sc)
		var dir := (Vector2(-sin(a), cos(a) * ry / rx) * (1 if k % 2 == 0 else -1)).normalized()
		if active() and pond == o and k == 0 and phase in ["bite", "reel"]:
			at = _bob() + Vector2(sin(tm * 9) * 3.0, 3.0)
			dir = Vector2(1, 0)
		if o["dock"] and _dock_rect(o).grow(4.0).has_point(at):
			continue   # it passes under the dock
		var col := Color(0.04, 0.1, 0.18, 0.5)
		var len := 6.0 if big else 4.5
		_ellipse(ci, at, len, len * 0.45, col)
		var back := at - dir * len
		var side := Vector2(-dir.y, dir.x)
		var wig := sin(tm * 10 + k) * 1.5
		ci.draw_colored_polygon(PackedVector2Array([back, back - dir * 4 + side * (2.5 + wig), back - dir * 4 - side * (2.5 - wig)]), col)
	# Light on the water.
	var glints := 12 if big else 5
	for k in glints:
		var u := fmod(s * 3.1 + k * 0.618, 1.0) * 2.0 - 1.0
		var v := fmod(s * 1.7 + k * 0.414, 1.0) * 1.4 - 0.7
		var gp := c + Vector2(u * rx * 0.75 + sin(tm * 0.6 + k) * 3.0, v * ry * 0.8)
		var al := 0.15 + 0.3 * (0.5 + 0.5 * sin(tm * 1.7 + k * 1.3))
		ci.draw_line(gp, gp + Vector2(3.0 + (k % 3) * 2.0, 0), Color(0.9, 0.97, 1.0, al), 1.0)
	# Rain-drop rings now and then.
	for k in (3 if big else 1):
		var ph := tm * 0.5 + k * 0.37 + s
		var rr := fmod(ph, 1.0)
		var u := fmod(s * 5.3 + k * 0.71 + floorf(ph) * 0.29, 1.0) * 1.2 - 0.6
		var v := fmod(s * 2.9 + k * 0.33 + floorf(ph) * 0.47, 1.0) * 1.0 - 0.5
		ci.draw_arc(c + Vector2(u * rx, v * ry), 1.0 + rr * 6.0, 0, TAU, 12, Color(0.85, 0.95, 1.0, 0.5 * (1.0 - rr)), 1.0)
	if big:
		for k in 4:
			var a: float = [PI * 1.15, PI * 1.85, PI * 0.2, PI * 0.8][k]
			var lp := c + Vector2(cos(a) * rx * 1.2, sin(a) * ry * 1.3)
			var fl := 0.8 + 0.2 * sin(tm * 9 + k * 2)
			ci.draw_rect(Rect2(lp.x - 2, lp.y - 18, 4, 4), Color(1.0, 0.82 * fl, 0.4 * fl))
			ci.draw_circle(Vector2(lp.x, lp.y - 16), 10, Color(1.0, 0.8, 0.35, 0.12 * fl))
	# Fireflies over the water.
	for k in (8 if big else 3):
		var a := tm * (0.3 + 0.07 * k) + k * 1.9 + s
		var fp := c + Vector2(cos(a) * rx * 0.9 + sin(tm * 1.1 + k) * 6.0, sin(a * 1.3) * ry * 0.9 - 8.0 + cos(tm * 0.9 + k) * 4.0)
		var on := 0.5 + 0.5 * sin(tm * 3.0 + k * 2.3)
		if on > 0.3:
			ci.draw_circle(fp, 2.0, Color(1.0, 0.95, 0.5, 0.2 * on))
			ci.draw_rect(Rect2(fp.x, fp.y, 1, 1), Color(1.0, 0.98, 0.6, on))
	# The line, the float and the catch.
	if active() and pond == o:
		var p := G.player
		var b := _bob()
		var dip := 0.0
		if phase == "bite":
			dip = 2.0 + sin(tm * 30) * 1.5
		elif phase == "reel":
			dip = 1.0 + sin(tm * 18) * 1.0
		else:
			dip = sin(tm * 3) * 0.8
		var tip := Vector2(p.x + 9, p.y - 18)
		ci.draw_line(Vector2(p.x + 2, p.y - 8), tip, TB.c("#7a5236"), 2.0)
		var mid := (tip + b) * 0.5 + Vector2(0, 4 if phase == "cast" else 0)
		ci.draw_polyline(PackedVector2Array([tip, mid, b + Vector2(0, dip)]), TB.c("#f4ecd8"), 1.0)
		var ring := fmod(tm * 1.5, 1.0)
		ci.draw_arc(b + Vector2(0, 2), 3.0 + ring * 4.0, 0, TAU, 10, Color(0.85, 0.95, 1.0, 0.6 * (1.0 - ring)), 1.0)
		ci.draw_circle(b + Vector2(0, dip - 1), 2.0, TB.c("#ffffff"))
		ci.draw_circle(b + Vector2(0, dip + 0.5), 2.0, TB.c("#d8443c"))
		if phase == "bite":
			Gfx.text(ci, "!", b.x, b.y - 16 - absf(sin(tm * 12)) * 3, "gold", 2, 0.5)
	if not leap.is_empty() and pond == o:
		var lt: float = leap["t"]
		var b := _bob()
		var p := G.player
		var to := Vector2(p.x, p.y - 34)
		var k := clampf(lt / 0.8, 0.0, 1.0)
		var at := b.lerp(to, k) + Vector2(0, -sin(k * PI) * 30.0)
		var zm := 1.5 if k < 1.0 else 2.0
		if k >= 1.0:
			at.y += sin(tm * 4) * 1.5
			var d: Array = FISH[leap["id"]]
			Gfx.text(ci, ("NEW! " if fresh else "") + d[0], to.x, to.y - 24, RARITY_COL[d[2]], 1, 0.5)
		Gfx.sp(ci, sprite_of(leap["id"]), at.x, at.y + 6, zm, zm, sin(lt * 12) * 0.4 * (1.0 - k))
	elif o.get("casts", 0) > 0 and not active():
		# A little sign on the bank.
		var sg := Vector2(o["x"] - 16, o["y"] - 2)
		ci.draw_rect(Rect2(sg.x - 1, sg.y - 10, 2, 10), TB.c("#4a3020"))
		ci.draw_rect(Rect2(sg.x - 9, sg.y - 17, 18, 9), TB.c("#7a5236"))
		ci.draw_rect(Rect2(sg.x - 9, sg.y - 17, 18, 1), TB.c("#9a6a42"))
		Gfx.sp(ci, "fish_mudfin", sg.x, sg.y - 9, 1, 1)


static func pd_camp(o: Dictionary) -> bool:
	return (o["pond"] as Dictionary).get("camp", false)

static func _bucket(ci: CanvasItem, x: float, y: float, tm: float) -> void:
	ci.draw_rect(Rect2(x + 9, y - 2, 8, 7), TB.c("#5a5a6a"))
	ci.draw_rect(Rect2(x + 9, y - 2, 8, 1), TB.c("#8b8f9c"))
	ci.draw_rect(Rect2(x + 10, y - 1, 6, 2), TB.c("#2f6f9a"))
	if fmod(tm, 3.0) < 0.3:
		Gfx.sp(ci, "fish_mudfin", x + 13, y - 3 - fmod(tm, 3.0) * 20.0, 1, 1)

## The Angler (EventRooms.draw).
static func draw_angler(ci: CanvasItem, o: Dictionary, tm: float) -> void:
	var x: float = o["x"]
	var y: float = o["y"]
	# His camp: crates on the far side of the dock, a barrel, a rod rack (not at the hero's camp).
	if pd_camp(o):
		_bucket(ci, x, y, tm)
		Gfx.sp(ci, "npc_angler", x, y + sin(tm * 2) * 0.5)
		return
	Gfx.sp(ci, "crate", x - 108, y + 8)
	Gfx.sp(ci, "crate", x - 94, y + 12)
	Gfx.sp(ci, "crate", x - 101, y)
	Gfx.sp(ci, "barrel", x + 30, y + 8)
	for k in 3:
		ci.draw_line(Vector2(x - 78 + k * 4, y + 8), Vector2(x - 74 + k * 4, y - 16), TB.c("#7a5236"), 1.0)
	ci.draw_rect(Rect2(x - 80, y - 4, 14, 2), TB.c("#5a3a22"))
	ci.draw_rect(Rect2(x + 9, y - 2, 8, 7), TB.c("#5a5a6a"))   # his bucket
	ci.draw_rect(Rect2(x + 9, y - 2, 8, 1), TB.c("#8b8f9c"))
	ci.draw_rect(Rect2(x + 10, y - 1, 6, 2), TB.c("#2f6f9a"))
	if fmod(tm, 3.0) < 0.3:
		Gfx.sp(ci, "fish_mudfin", x + 13, y - 3 - fmod(tm, 3.0) * 20.0, 1, 1)   # something flaps in it
	Gfx.sp(ci, "npc_angler", x, y + sin(tm * 2) * 0.5)
	var pd: Dictionary = o["pond"]
	if pd.get("caught", 0) >= 3 and not o["rewarded"]:
		Gfx.text(ci, "!", x, y - 26 - absf(sin(tm * 4.0)) * 2.0, "gold", 1, 0.5)

## The reel panel over the world (menu_view, state "fishing").
static func draw_panel(ci: CanvasItem) -> void:
	var tm := G.time
	var x0 := TB.SW - 126
	var y0 := 34
	var w := 110
	var h := 200
	Gfx.panel(ci, x0, y0, w, h, "#9a6a42", "#14121c")
	ci.draw_rect(Rect2(x0 + 2, y0 + 2, w - 4, 12), TB.c("#5a3a22"))
	Gfx.text(ci, "FISHING", x0 + w / 2, y0 + 5, "gold", 1, 0.5)
	var bx := x0 + 12
	var by := y0 + 22
	var bh := 128
	# The water column, light at the top, dark below, bubbles rising.
	for k in 8:
		var cl := TB.c("#3a7ea8").lerp(TB.c("#14304a"), k / 7.0)
		ci.draw_rect(Rect2(bx, by + k * bh / 8.0, 22, bh / 8.0 + 1), cl)
	for k in 5:
		var by2 := by + bh - fmod(tm * (18 + k * 5) + k * 31, bh)
		ci.draw_arc(Vector2(bx + 4 + (k * 7) % 16, by2), 1.2, 0, TAU, 6, Color(0.85, 0.95, 1.0, 0.6), 1.0)
	ci.draw_rect(Rect2(bx, by, 22, bh), TB.c("#9a6a42"), false, 1.0)
	if phase == "reel":
		var bt := by + bh * (1.0 - box - BOX_H)
		var nh := bh * BOX_H
		ci.draw_rect(Rect2(bx + 1, bt, 20, nh), Color(0.39, 0.85, 0.4, 0.35))
		ci.draw_rect(Rect2(bx + 1, bt, 20, 1), TB.c("#8af07a"))
		ci.draw_rect(Rect2(bx + 1, bt + nh - 1, 20, 1), TB.c("#8af07a"))
		for k in 3:
			ci.draw_line(Vector2(bx + 1, bt + nh * (k + 1) / 4.0), Vector2(bx + 21, bt + nh * (k + 1) / 4.0), Color(0.55, 0.95, 0.5, 0.35), 1.0)
		var fy := by + bh * (1.0 - pos)
		var known: bool = (Meta.meta["fish"] as Dictionary).has(fish_id) if Meta.meta.get("fish") is Dictionary else false
		Gfx.sp(ci, sprite_of(fish_id), bx + 11 + sin(tm * 14) * 1.5, fy + 4, 1, 1, sin(tm * 10) * 0.3, false, 1.0,
			Color(0, 0, 0, 0) if known else Color(0.1, 0.15, 0.25, 1))
		# The catch bar.
		var cx := bx + 30
		ci.draw_rect(Rect2(cx, by, 8, bh), TB.c("#1a1423"))
		var ph := bh * clampf(prog, 0.0, 1.0)
		ci.draw_rect(Rect2(cx + 1, by + bh - ph, 6, ph), TB.c("#f2c94c"))
		ci.draw_rect(Rect2(cx + 1, by + bh - ph, 2, ph), TB.c("#fff07a"))
		ci.draw_rect(Rect2(cx, by, 8, bh), TB.c("#9a6a42"), false, 1.0)
		if prog > 0.8:
			ci.draw_circle(Vector2(cx + 4, by + bh - ph), 2.0 + sin(tm * 20), Color(1, 1, 0.8, 0.8))
		var rar: String = FISH[fish_id][2]
		Gfx.text(ci, "HOLD", x0 + 84, by + 18, "white", 1, 0.5)
		Gfx.text(ci, "USE", x0 + 84, by + 28, "gold", 1, 0.5)
		Gfx.text(ci, "TO LIFT", x0 + 84, by + 38, "white", 1, 0.5)
		Gfx.text(ci, "THE NET", x0 + 84, by + 48, "white", 1, 0.5)
		if rar == "legend":
			Gfx.text(ci, "IT IS", x0 + 84, by + 80, "pink", 1, 0.5)
			Gfx.text(ci, "HUGE!", x0 + 84, by + 90, "pink", 1, 0.5)
		elif rar == "rare":
			Gfx.text(ci, "IT FEELS", x0 + 84, by + 80, "gold", 1, 0.5)
			Gfx.text(ci, "HEAVY", x0 + 84, by + 90, "gold", 1, 0.5)
	elif phase == "cast":
		Gfx.text(ci, "WAIT FOR", x0 + 76, by + 40, "white", 1, 0.5)
		Gfx.text(ci, "A BITE...", x0 + 76, by + 50, "white", 1, 0.5)
	elif phase == "bite":
		Gfx.text(ci, "BITE!", x0 + 76, by + 40, "gold", 2, 0.5)
		Gfx.text(ci, "PRESS USE", x0 + 76, by + 58, "white", 1, 0.5)
	elif phase == "done" and not leap.is_empty():
		Gfx.sp(ci, sprite_of(leap["id"]), x0 + w / 2, by + 74, 3, 3)
	# What happened.
	var lines := Gfx.wrap_text(result, 96)
	var ry := y0 + h - 40
	if not leap.is_empty() and phase == "done":
		var d: Array = FISH[leap["id"]]
		Gfx.text(ci, ("NEW! " if fresh else "") + d[0], x0 + w / 2, ry - 10, RARITY_COL[d[2]], 1, 0.5)
	for i in mini(3, lines.size()):
		Gfx.text(ci, lines[i], x0 + w / 2, ry + i * 8, "white", 1, 0.5)
	Gfx.text(ci, "CASTS LEFT %d" % pond.get("casts", 0), x0 + w / 2, y0 + h - 12, "grey", 1, 0.5)
	Gfx.text(ci, "FISH FOUND %d OF %d    MENU: STOP" % [caught_kinds(), FISH.size()], TB.SW / 2, TB.SH - 14, "cyan", 1, 0.5)
