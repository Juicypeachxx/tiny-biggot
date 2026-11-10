class_name Wanderers
extends RefCounted
## 21.4 LIFE BETWEEN THE FIGHTS (his word, 8 Oct: "make game more alive"). Expanded game only.
##   w_ghost      your last hero, on the floor where they fell in the run before, with some of the
##                gold they carried: walk up and take it.
##   w_rival      another adventurer, racing you to a chest that turns up with them. Get there first;
##                or WAVE them on, and they come back to fight beside you in your next fight on the
##                floor; or shoot them, and they fight you for it (and drop the chest and their purse).
##   w_traveller  someone lost on the floor: lead them to the guardian's door for a relic and gold.
##                They follow you from room to room; a shot or a foe that reaches them hurts, and
##                after three they run home.
## They turn up when a fight is won (Game.room_cleared), one at a time. Whether one turns up is
## decided with dice of their own (from the run's clock and kills), so it never moves the run's own.

const KINDS := ["w_ghost", "w_rival", "w_traveller"]
const RIVAL_CHANCE := 0.22
const TRAVELLER_CHANCE := 0.16
const RIVAL_SPEED := 64.0
const TRAVELLER_SPEED := 96.0
const TRAVELLER_HP := 3
const TRAVELLERS := [["PILGRIM", "#e8dcc0"], ["CARTOGRAPHER", "#6fd3e0"], ["PEDLAR", "#c9a35a"], ["NOVICE", "#a35bd6"],
	["BARD", "#63b84f"], ["LAMPLIGHTER", "#f2c94c"]]
const GHOST_LINES := ["GO ON. FINISH WHAT I STARTED.", "IT'S COLD DOWN HERE. KEEP MOVING.", "YOU LOOK FAMILIAR.",
	"WATCH THE LEFT. ALWAYS THE LEFT.", "SPEND IT ON SOMETHING SHINY."]
const RIVAL_TAKE := ["FINDERS KEEPERS!", "TOO SLOW!", "MINE NOW!"]
const RIVAL_LOSE := ["HMPH. NEXT TIME.", "BEGINNER'S LUCK.", "FINE. KEEP IT."]
const RIVAL_FIGHT := ["YOU WANT IT? COME AND GET IT!", "OH, IT'S LIKE THAT?", "BIG MISTAKE, FRIEND."]
const TRAVELLER_LINES := ["ARE WE NEARLY THERE?", "I HEARD SOMETHING.", "YOU'RE VERY GOOD AT THIS.", "LEFT? NO, RIGHT. NO...",
	"I'LL TELL EVERYONE ABOUT YOU.", "IS THAT BLOOD? IS IT YOURS?"]

static var _rng := RandomNumberGenerator.new()
static var _uid := 0
static var _trav: Dictionary = {}   # the traveller's object in the room you are in

static func on() -> bool:
	return GameData.rogues() and not G.run_stats.get("camp", false) and Daily.mod() == ""

static func handles(kind: String) -> bool:
	return kind in KINDS

## Dice from the run's clock and kills: the same in a replay, and the run's own dice are not moved.
static func _dice(salt: int) -> RandomNumberGenerator:
	_rng.seed = hash([G.floor_index, G.run_stats.get("kills", 0), int(G.run_stats.get("time", 0.0) * 60.0), salt])
	return _rng

static func _pick(list: Array) -> String:
	return list[_rng.randi() % list.size()]

# ---------- Turning up ----------
## Game.room_cleared: a fight was won; sometimes someone is there.
static func on_room_clear(room: Room) -> void:
	if not on() or not room.type in ["combat", "elite"] or not room.theme.is_empty() or room.event != "":
		return
	var met: Dictionary = G.run_stats.get("wanderers", {})
	G.run_stats["wanderers"] = met
	var f := str(G.floor_index)
	var gh: Dictionary = Meta.meta["ghost"] if Meta.meta.get("ghost") is Dictionary else {}
	if not gh.is_empty() and int(gh.get("floor", -1)) == G.floor_index and not met.has("ghost"):
		met["ghost"] = true
		_ghost(room, gh)
		return
	for o in room.objects:
		if o["kind"] in ["w_drunk", "n_inkling", "w_merchant"] and not o.get("gone", false):
			return   # someone already wandered in (EventRooms)
	var r := _dice(4)
	if G.floor_index >= 1 and not met.has("rival" + f) and r.randf() < RIVAL_CHANCE:
		met["rival" + f] = true
		_rival(room)
	elif not met.has("traveller" + f) and not G.run_stats.has("traveller") and r.randf() < TRAVELLER_CHANCE:
		met["traveller" + f] = true
		_traveller(room)

static func _ghost(room: Room, gh: Dictionary) -> void:
	var o := { "kind": "w_ghost", "x": float(gh.get("x", 224.0)), "y": float(gh.get("y", 150.0)), "sprite": str(gh.get("sprite", "hexer")),
		"name": str(gh.get("name", "A HERO")), "gold": int(gh.get("gold", 10)), "fade": 1.0 }
	if not Img.has(o["sprite"]):
		o["sprite"] = "hexer"
	if World.hits_solid(room, o["x"], o["y"], 8, World.M_PLAYER) or TB.dist_xy(o["x"], o["y"], G.player.x, G.player.y) < 30:
		if not _spot(room, o, _dice(7)):
			return
	room.objects.append(o)
	G.toast("A FAMILIAR FIGURE WAITS HERE...", "cyan")

static func _rival(room: Room) -> void:
	var r := _dice(5)
	var p := G.player
	var heroes: Array = GameData.heroes().filter(func(h): return h["id"] != p.hero["id"] and Img.has(h["sprite"]))
	if heroes.is_empty():
		return
	var h: Dictionary = heroes[r.randi() % heroes.size()]
	_uid += 1
	var chest := { "kind": "chest", "x": 0.0, "y": 0.0, "rid": _uid }
	if not _spot(room, chest, r, 90.0):
		return
	# The rival comes in by the door that makes it a fair race: a little farther from the chest than you.
	var want := TB.dist_xy(p.x, p.y, chest["x"], chest["y"]) * 1.25
	var door := World.door_center("n")
	for d in ["n", "s", "w", "e"]:
		var c := World.door_center(d)
		if absf(TB.dist_xy(c.x, c.y, chest["x"], chest["y"]) - want) < absf(TB.dist_xy(door.x, door.y, chest["x"], chest["y"]) - want):
			door = c
	door = door.move_toward(Vector2(14.0 * TB.TS, 9.5 * TB.TS), 18.0)   # just inside
	var o := { "kind": "w_rival", "x": door.x, "y": door.y, "sprite": h["sprite"], "name": h["name"], "st": "race", "rid": _uid,
		"face": 1, "stuck": 0.0, "t": 0.0 }
	room.objects.append(chest)
	room.objects.append(o)
	Barks.say(o, "THAT CHEST IS MINE!", "orange")
	G.toast("A RIVAL! RACE THEM TO THE CHEST", "orange")
	Snd.play("door")

static func _traveller(room: Room) -> void:
	var r := _dice(6)
	var t: Array = TRAVELLERS[r.randi() % TRAVELLERS.size()]
	var o := { "kind": "w_traveller", "st": "wait", "who": t[0], "col": t[1], "hp": TRAVELLER_HP, "face": 1, "iv": 0.0, "talk": 8.0 }
	if not _spot(room, o, r, 60.0):
		return
	room.objects.append(o)
	Barks.say(o, "HELLO? IS SOMEONE THERE?", "white")
	G.toast("SOMEONE IS LOST HERE", "white")

## Somewhere on open floor, away from the doors and from the hero (EventRooms._place, with own dice).
static func _spot(room: Room, o: Dictionary, r: RandomNumberGenerator, from_hero: float = 50.0) -> bool:
	for tries in 60:
		var x := r.randi_range(TB.IX0 + 2, TB.IX0 + TB.IW - 3) * TB.TS + 8.0
		var y := r.randi_range(TB.IY0 + 2, TB.IY0 + TB.IH - 3) * TB.TS + 8.0
		if World.hits_solid(room, x, y, 10, World.M_PLAYER) or TB.dist_xy(x, y, G.player.x, G.player.y) < from_hero:
			continue
		var ok := true
		for d in ["n", "s", "w", "e"]:
			if World.door_center(d).distance_to(Vector2(x, y)) < 60:
				ok = false
		for o2 in room.objects:
			if TB.dist_xy(x, y, o2["x"], o2["y"]) < 30:
				ok = false
		if ok:
			o["x"] = x
			o["y"] = y
			return true
	return false

# ---------- Rooms and floors ----------
## Game.enter_room: the traveller comes along; a rival you waved on comes back to help.
static func on_enter_room(room: Room) -> void:
	if not on():
		return
	var p := G.player
	if G.run_stats.get("traveller") is Dictionary:
		var tv: Dictionary = G.run_stats["traveller"]
		if not _trav.is_empty():
			_trav["gone"] = true
		_trav = { "kind": "w_traveller", "st": "follow", "used": true, "who": tv["who"], "col": tv["col"], "hp": int(tv["hp"]),
			"x": p.x, "y": p.y + 10.0, "face": 1, "iv": 1.0, "talk": 10.0 }
		room.objects.append(_trav)
		if room.type == "boss":
			_arrive(_trav)
	if int(G.run_stats.get("rival_owes", -1)) == G.floor_index and room.type in ["combat", "elite"] and not room.cleared \
			and room.theme.is_empty():
		var look: Array = G.run_stats.get("rival_look", ["hexer", "A RIVAL"])
		var o := { "kind": "w_rival", "st": "ally", "used": true, "x": p.x - 20.0, "y": p.y + 8.0, "sprite": look[0], "name": look[1],
			"face": 1, "cd": 1.0, "t": 0.0, "stuck": 0.0 }
		room.objects.append(o)
		G.run_stats.erase("rival_owes")
		Barks.say(o, "I OWE YOU ONE. LET'S GO!", "orange")

## Game.start_floor: a traveller who never reached a guardian's door goes their own way.
static func on_floor_start() -> void:
	_trav = {}
	if G.run_stats.has("traveller"):
		G.run_stats.erase("traveller")
		G.toast("THE TRAVELLER WENT THEIR OWN WAY", "grey")
	if int(G.run_stats.get("rival_owes", -1)) != G.floor_index:
		G.run_stats.erase("rival_owes")

## Game.on_death: where this hero fell, for the next run (Meta "ghost").
static func on_death(p: Player) -> void:
	if not on():
		return
	Meta.meta["ghost"] = { "floor": G.floor_index, "x": p.x, "y": p.y, "sprite": p.hero["sprite"], "name": p.hero["name"],
		"gold": maxi(10, int(p.gold * 0.4)) }

## Combat.kill_enemy: a rival who fought you for it gives up, dropping the chest and their purse.
static func on_kill(e: Enemy) -> void:
	if not e.d.get("rival", false):
		return
	var gold := 30 + G.floor_index * 6
	_pay(gold, e.x, e.y - 18)
	if e.d.get("has_chest", false) and G.room != null:
		G.room.objects.append({ "kind": "chest", "x": e.x, "y": e.y })
	G.toast("THE RIVAL GIVES UP AND RUNS FOR IT", "orange")

static func _pay(gold: int, x: float, y: float) -> void:
	var p := G.player
	p.gold += gold
	G.run_stats["gold"] = G.run_stats.get("gold", 0) + gold
	Fx.float_text(x, y, "+%d GOLD" % gold, "gold")
	Snd.play("coin")

# ---------- Every tick ----------
## EventRooms.update.
static func update(dt: float) -> void:
	var room := G.room
	if room == null or not on():
		return
	for o in room.objects:
		if o.get("gone", false):
			continue
		match o["kind"]:
			"w_rival":
				_update_rival(o, dt)
			"w_traveller":
				_update_traveller(o, dt)
			"w_ghost":
				if o.get("taken", false):
					o["fade"] -= dt * 0.6
					if o["fade"] <= 0.0:
						o["gone"] = true

## Moves an object toward (tx, ty), around what is in the way when it can; returns the distance left.
static func _walk(o: Dictionary, tx: float, ty: float, speed: float, dt: float) -> float:
	var d := TB.dist_xy(o["x"], o["y"], tx, ty)
	if d < 1.0:
		return d
	var step := minf(d, speed * dt)
	var nx: float = o["x"] + (tx - o["x"]) / d * step
	var ny: float = o["y"] + (ty - o["y"]) / d * step
	var room := G.room
	if o.get("over", false) or not World.hits_solid(room, nx, ny, 6, World.M_PLAYER):
		o["x"] = nx
		o["y"] = ny
	else:
		if not World.hits_solid(room, nx, o["y"], 6, World.M_PLAYER):
			o["x"] = nx
		elif not World.hits_solid(room, o["x"], ny, 6, World.M_PLAYER):
			o["y"] = ny
		o["stuck"] += dt
		if o["stuck"] > 1.5:
			o["over"] = true   # no way round it: after a moment they clamber over
	if absf(tx - o["x"]) > 1.0:
		o["face"] = 1 if tx > o["x"] else -1
	return TB.dist_xy(o["x"], o["y"], tx, ty)

static func _chest_of(o: Dictionary) -> Dictionary:
	for c in G.room.objects:
		if c["kind"] == "chest" and c.get("rid", -1) == o.get("rid", -2):
			return c
	return {}

static func _door_near(o: Dictionary) -> Vector2:
	var best := World.door_center("n")
	for d in ["s", "w", "e"]:
		var c := World.door_center(d)
		if c.distance_to(Vector2(o["x"], o["y"])) < best.distance_to(Vector2(o["x"], o["y"])):
			best = c
	return best

static func _update_rival(o: Dictionary, dt: float) -> void:
	o["t"] += dt
	if o["st"] in ["race", "leave"] and _struck(o):
		_turn_hostile(o)
		return
	match o["st"]:
		"race":
			var chest := _chest_of(o)
			if chest.is_empty() or chest.get("opened", false) or chest.get("gone", false):
				_rng.seed = int(o["t"] * 1000.0)
				Barks.say(o, _pick(RIVAL_LOSE), "orange")
				o["st"] = "leave"
				o["used"] = true
			elif _walk(o, chest["x"], chest["y"] + 6.0, RIVAL_SPEED, dt) < 8.0:
				chest["gone"] = true
				o["has_chest"] = true
				_rng.seed = int(o["t"] * 1000.0)
				Barks.say(o, "THANKS, FRIEND!" if o.get("waved", false) else _pick(RIVAL_TAKE), "orange")
				Snd.play("open")
				o["st"] = "leave"
				o["used"] = true
		"leave":
			var d := _door_near(o)
			if _walk(o, d.x, d.y, RIVAL_SPEED * 1.3, dt) < 10.0:
				o["gone"] = true
				Vfx.puff(o["x"], o["y"], "gold")
		"ally":
			_update_ally(o, dt)

## A shot of yours (or a swing) caught the rival.
static func _struck(o: Dictionary) -> bool:
	for b: PBullet in G.pbullets:
		if b.life > 0.0 and absf(b.x - o["x"]) < 8.0 and absf(b.y - (o["y"] - 6.0)) < 10.0:
			return true
	for w in G.swings:
		if w.get("kind", "") == "slash" and TB.dist_xy(w["x"], w["y"], o["x"], o["y"]) < float(w.get("r", 0.0)) + 6.0:
			return true
	return false

static func _turn_hostile(o: Dictionary) -> void:
	o["gone"] = true
	var e := Combat.spawn_enemy("outlaw", o["x"], o["y"], false, true)
	e.d = e.d.duplicate()
	e.d["sprite"] = o["sprite"]
	e.d["label"] = "your rival"
	e.d["rival"] = true
	e.d["burst"] = 3
	e.d["gold"] = 0.0
	e.d["has_chest"] = o.get("has_chest", false)
	e.max_hp *= 6.0
	e.hp = e.max_hp
	if o.get("waved", false):
		G.run_stats.erase("rival_owes")
	_rng.seed = int(o["t"] * 1000.0) + 7
	Barks.say(e, _pick(RIVAL_FIGHT), "red")

## A rival you waved on, back for one fight: keeps near you and shoots at your foes.
static func _update_ally(o: Dictionary, dt: float) -> void:
	var p := G.player
	var tx := p.x - 22.0
	var ty := p.y + 8.0
	o["x"] += (tx - o["x"]) * minf(1.0, dt * 4.0)
	o["y"] += (ty - o["y"]) * minf(1.0, dt * 4.0)
	o["cd"] -= dt
	if o["cd"] <= 0.0 and G.enemies_active():
		var t := Combat.nearest_enemy(o["x"], o["y"], 240)
		if t != null:
			o["cd"] = 0.55
			o["face"] = 1 if t.x >= o["x"] else -1
			Combat._raw_shot(o["x"], o["y"] - 6.0, TB.ang_xy(o["x"], o["y"] - 6.0, t.x, t.y), 230, maxf(3.0, Weapons.wdmg(p) * 0.6), 1.0, 2.5, 0,
				"bolt", {})
	if G.room.cleared and not G.locked:
		Barks.say(o, "THAT MAKES US EVEN!", "orange")
		o["st"] = "leave"

static func _update_traveller(o: Dictionary, dt: float) -> void:
	var p := G.player
	o["iv"] = maxf(0.0, o["iv"] - dt)
	o["flash"] = maxf(0.0, o.get("flash", 0.0) - dt)
	match o["st"]:
		"wait":
			o["face"] = 1 if p.x >= o["x"] else -1
		"follow":
			if TB.dist_xy(o["x"], o["y"], p.x, p.y) > 20.0:
				_walk_free(o, p.x, p.y + 6.0, TRAVELLER_SPEED, dt)
			_hurt(o)
			o["talk"] -= dt
			if o["talk"] <= 0.0 and not G.locked:
				_rng.seed = int(G.run_stats.get("time", 0.0) * 60.0)
				o["talk"] = 14.0 + _rng.randf() * 10.0
				Barks.say(o, _pick(TRAVELLER_LINES), "white")
		"flee":
			var d := _door_near(o)
			_walk_free(o, d.x, d.y, TRAVELLER_SPEED * 1.2, dt)
			if TB.dist_xy(o["x"], o["y"], d.x, d.y) < 10.0:
				o["gone"] = true
		"done":
			o["t"] = o.get("t", 0.0) + dt
			if o["t"] > 3.0:
				o["gone"] = true
				Vfx.puff(o["x"], o["y"], "gold")

static func _walk_free(o: Dictionary, tx: float, ty: float, speed: float, dt: float) -> void:
	var d := TB.dist_xy(o["x"], o["y"], tx, ty)
	if d < 1.0:
		return
	var step := minf(d, speed * dt)
	o["x"] += (tx - o["x"]) / d * step
	o["y"] += (ty - o["y"]) / d * step
	if absf(tx - o["x"]) > 1.0:
		o["face"] = 1 if tx > o["x"] else -1

## A foe's shot, or a foe itself, reaches the traveller.
static func _hurt(o: Dictionary) -> void:
	if o["iv"] > 0.0:
		return
	var hit := not EBullets.take_near(o["x"], o["y"] - 5.0, 7.0, 3).is_empty()
	if not hit:
		for e: Enemy in G.enemies:
			if e.targetable() and e.type != "dummy" and TB.dist_xy(e.x, e.y, o["x"], o["y"]) < e.r + 6.0:
				hit = true
				break
	if not hit:
		return
	o["hp"] -= 1
	o["iv"] = 1.0
	o["flash"] = 0.3
	if G.run_stats.get("traveller") is Dictionary:
		G.run_stats["traveller"]["hp"] = o["hp"]
	if o["hp"] <= 0:
		Barks.say(o, "THAT'S IT, I'M GOING HOME!", "red")
		o["st"] = "flee"
		G.run_stats.erase("traveller")
		G.toast("THE TRAVELLER RAN HOME", "grey")
	else:
		Barks.say(o, "OW! CAREFUL!", "red")

## At the guardian's door: the traveller pays and goes.
static func _arrive(o: Dictionary) -> void:
	var p := G.player
	G.run_stats.erase("traveller")
	o["st"] = "done"
	o["t"] = 0.0
	Barks.say(o, "THIS IS MY STOP. THANK YOU!", "gold")
	var r := G.roll_relics(1, "chest")
	if not r.is_empty():
		G.add_relic(p, r[0])
	_pay(20 + G.floor_index * 5, p.x, p.y - 24)
	G.toast("THE TRAVELLER GAVE YOU A RELIC" if not r.is_empty() else "THE TRAVELLER PAID YOU", "gold")

# ---------- Using them ----------
static func interact(o: Dictionary) -> void:
	match o["kind"]:
		"w_ghost":
			o["taken"] = true
			o["used"] = true
			_pay(o["gold"], o["x"], o["y"] - 22)
			_rng.seed = int(o["gold"]) * 31 + G.floor_index
			Barks.say(o, _pick(GHOST_LINES), "cyan")
			Meta.meta.erase("ghost")
			Meta.write_save()
		"w_rival":
			if o["st"] == "race":
				o["waved"] = true
				o["used"] = true
				G.run_stats["rival_owes"] = G.floor_index
				G.run_stats["rival_look"] = [o["sprite"], o["name"]]
				Barks.say(o, "MUCH OBLIGED! I OWE YOU ONE.", "orange")
				Snd.play("select")
		"w_traveller":
			if o["st"] == "wait":
				o["st"] = "follow"
				o["used"] = true
				_trav = o
				G.run_stats["traveller"] = { "who": o["who"], "col": o["col"], "hp": o["hp"] }
				Barks.say(o, "THANK YOU! THE GUARDIAN'S DOOR, YOU SAY?", "white")
				Snd.play("confirm")

static func prompt(o: Dictionary) -> Array:
	match o["kind"]:
		"w_ghost":
			return ["THE GHOST OF " + str(o["name"]), "YOU FELL HERE LAST TIME. %d GOLD IS STILL HERE" % o["gold"], "TAKE IT"]
		"w_rival":
			return ["THE RIVAL: " + str(o["name"]), "LET THEM HAVE THE CHEST, OR SHOOT TO FIGHT FOR IT", "WAVE THEM ON"]
		"w_traveller":
			return ["A LOST " + str(o["who"]), "LEAD THEM TO THE GUARDIAN'S DOOR: A RELIC", "LEAD THE WAY"]
	return ["", "", ""]

# ---------- Drawing (world_view's objects, every frame) ----------
static func draw(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x: float = o["x"]
	var y: float = o["y"]
	match o["kind"]:
		"w_ghost":
			var a: float = 0.6 * clampf(o["fade"], 0.0, 1.0)
			var bob := roundf(sin(t * 2.5) * 1.5)
			ci.draw_circle(Vector2(x, y), 9.0, Color(0.55, 0.9, 1.0, 0.1 * a))
			Gfx.sp(ci, o["sprite"], x, y + 4 + bob, 1, 1, 0.0, false, a, Color(0.6, 0.92, 1.0, 0.65))
			if not o.get("taken", false):
				Gfx.text(ci, "$", x, y - 22 + bob, "gold", 1, 0.5)
		"w_rival":
			var walking: bool = o["st"] != "ally" or G.enemies_active()
			var bob := -1.0 if walking and floori(o["t"] * 10.0) % 2 == 1 else 0.0
			Gfx.sp(ci, o["sprite"], x, y + 6 + bob, 1, 1, 0.0, o["face"] < 0)
			if o.get("has_chest", false):
				Gfx.sp(ci, "chest", x, y - 12 + bob, 0.6, 0.6)
			Gfx.text(ci, "RIVAL" if o["st"] != "ally" else "ALLY", x, y - 26, "orange" if o["st"] != "ally" else "lime", 1, 0.5)
		"w_traveller":
			_draw_traveller(ci, o, t)

## A small cloaked figure with a pack and a lantern (drawn here: the game's own).
static func _draw_traveller(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x := roundf(o["x"])
	var y := roundf(o["y"])
	var f: int = o["face"]
	var moving: bool = o["st"] in ["follow", "flee"]
	var bob := -1.0 if moving and floori(t * 8.0) % 2 == 1 else 0.0
	var cloak := TB.c(o["col"])
	if o.get("flash", 0.0) > 0.0 and floori(t * 20.0) % 2 == 0:
		cloak = Color(1, 1, 1)
	var dk := cloak.darkened(0.35)
	ci.draw_rect(Rect2(x - 3 - f * 3, y - 9 + bob, 4, 6), TB.c("#6b4a2a"))   # the pack
	ci.draw_rect(Rect2(x - 3, y - 8 + bob, 6, 9), cloak)                   # the cloak
	ci.draw_rect(Rect2(x - 3, y + bob, 6, 1), dk)
	ci.draw_rect(Rect2(x - 2, y - 12 + bob, 5, 4), dk)                     # the hood
	ci.draw_rect(Rect2(x - 1 + maxi(f, 0), y - 11 + bob, 2, 2), TB.c("#e0b090"))   # a face
	ci.draw_rect(Rect2(x - 2, y + 1, 2, 2), TB.c("#3a2a20"))               # feet
	ci.draw_rect(Rect2(x + 1, y + 1, 2, 2), TB.c("#3a2a20"))
	var lx := x + f * 5
	var ly := y - 4 + bob + roundf(sin(t * 3.0))
	ci.draw_line(Vector2(lx, ly - 4), Vector2(lx, ly - 1), TB.c("#4e4a5e"), 1.0)
	ci.draw_rect(Rect2(lx - 1, ly - 1, 3, 3), TB.c("#f2c94c"))             # the lantern
	ci.draw_circle(Vector2(lx + 0.5, ly + 0.5), 5.0, Color(1.0, 0.85, 0.4, 0.12))
	if o["st"] == "follow":
		for i in o["hp"]:
			ci.draw_rect(Rect2(x - 4 + i * 3, y - 16 + bob, 2, 2), TB.c("#d8443c"))
	elif o["st"] == "wait":
		Gfx.text(ci, "?", x, y - 22 + roundf(sin(t * 4.0)), "white", 1, 0.5)
