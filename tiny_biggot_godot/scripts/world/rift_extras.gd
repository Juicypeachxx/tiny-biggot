class_name RiftExtras
extends RefCounted
## Two rift worlds with things to touch (ROADMAP 4.3, environments 2 and 3). Original homages:
##
## THE DROWNED BASTION (rampart ruins over a poisoned sea)
##   hazard "tide": a band of the room is marked for 1.2 s, then a wave of sludge sweeps along it.
##          It hurts you once if it catches you, and it hurts every foe it passes (not champions).
##   levers: pull one and a hidden alcove in the wall spills its stash (gold, sometimes a key)
##   easter eggs: a skull on a pike that tells jokes (the third is worth a gem); a hooded figure
##          fishing in a puddle (a fish, or an old boot)
## THE CALIBER CATHEDRAL (a temple of brass built from bullets)
##   tables: press USE beside one to flip it. A flipped table is cover: no shot and no walker gets
##          through it. Every fight room has some.
##   hazard "turrets": guns in the top wall show their aim for 0.8 s, then fire a three-shot burst
##   easter eggs: the shrine of a bullet saint (gold for a blessing on your shots); a rat asleep on
##          a pile of casings (it steals your gold and runs: catch it for twice as much back)
## Layouts 201-204 (bastion) and 301-304 (cathedral) in World.build_room. All Rogues layer.

const KINDS := ["x_table", "x_lever", "x_skull", "x_fisher", "x_saint", "x_ratpile"]
const SKULL_JOKES := ["WHY DON'T SKELETONS FIGHT? NO GUTS.", "I USED TO BE A KNIGHT. NOW I'M MOSTLY HEAD.",
	"I'D GIVE YOU A HAND, BUT... YOU KNOW."]

# ---------- Layouts ----------
static func layout(room: Room, pat: int) -> void:
	var P := World.T_PILLAR
	var K := World.T_CRATE
	match pat:
		201:  # ramparts: two long walls with gaps
			for a in [2, 3, 4, 5, 8, 9, 10]:
				World._put(room, a, 4, P)
		202:  # cells: four small cells with open fronts
			for b in [2, 3, 4]:
				World._put(room, 4, b, P)
				World._put(room, 9, b, P)
			World._put(room, 5, 2, P); World._put(room, 8, 2, P)
		203:  # the broken bridge: rubble on both sides of a clear middle (fixed spots: random rubble
			# could wall off a pocket of floor)
			for ab in [Vector2i(2, 2), Vector2i(4, 1), Vector2i(6, 3), Vector2i(3, 5), Vector2i(8, 1), Vector2i(9, 5)]:
				World._put(room, ab.x, ab.y, K)
			World._put(room, 5, 5, P); World._put(room, 10, 3, P)
		204:  # a ruined chapel: two columns of pillars
			for b in [1, 3, 5]:
				World._put(room, 5, b, P)
				World._put(room, 9, b, P)
		301:  # pews (tables are set up in setup())
			World._put(room, 2, 1, P)
		302:  # the altar: a block of pillars in the middle quarter
			World._put(room, 9, 4, P); World._put(room, 10, 4, P); World._put(room, 9, 5, P)
		303:  # crossfire: pillars in the corners
			World._put(room, 2, 1, P); World._put(room, 3, 1, P); World._put(room, 2, 2, P)
		304:  # the nave: two rows of pillars
			for a in [3, 7, 11]:
				World._put(room, a, 2, P)

# ---------- Room contents ----------
static func setup(room: Room) -> void:
	if room.type == "boss" and room.theme.get("id", "") == "cathedral":
		# The brass organ's nave: three tables to flip against its chords.
		for sp in [[6, 11], [13, 13], [20, 11]]:
			room.objects.append({ "kind": "x_table", "c": sp[0], "r": sp[1], "x": (sp[0] + 1.0) * TB.TS,
				"y": (sp[1] + 0.5) * TB.TS + 10.0, "flipped": false })
		return
	if room.theme.is_empty() or not room.type in ["combat", "elite"]:
		return
	match room.theme["id"]:
		"bastion":
			if randf() < 0.3:
				_add(room, { "kind": "x_lever", "pulled": false }, true)
			if randf() < 0.22:
				_add(room, { "kind": "x_skull", "talks": 0 }, false)
			if randf() < 0.08:
				_add(room, { "kind": "x_fisher", "talks": 0 }, false)
		"cathedral":
			var spots: Array = { 301: [[5, 6], [5, 12], [21, 6], [21, 12], [13, 5]], 302: [[7, 6], [19, 6], [7, 13], [19, 13]],
				303: [[9, 8], [17, 8], [13, 12], [6, 11], [20, 11]], 304: [[5, 9], [13, 6], [21, 9], [13, 13]] }.get(room.layout,
				[[8, 7], [18, 7], [13, 12]])
			for sp in spots:
				if _free(room, sp[0], sp[1]) and _free(room, sp[0] + 1, sp[1]):
					room.objects.append({ "kind": "x_table", "c": sp[0], "r": sp[1], "x": (sp[0] + 1.0) * TB.TS,
						"y": (sp[1] + 0.5) * TB.TS + 10.0, "flipped": false })
			if randf() < 0.25:
				_add(room, { "kind": "x_saint" }, false)
			if randf() < 0.12:
				_add(room, { "kind": "x_ratpile" }, false)

static func _free(room: Room, c: int, r: int) -> bool:
	return room.tile(c, r) == World.T_FLOOR

## A spot by a side wall (on_wall: the top wall, for a lever) clear of doors and other things.
static func _add(room: Room, o: Dictionary, on_wall: bool) -> void:
	for tries in 40:
		var c := TB.rint(3, 24)
		var r := 2 if on_wall else TB.rint(3, 15)
		if c >= 11 and c <= 16:
			continue   # the north and south doors
		if not on_wall and r >= 7 and r <= 11 and (c <= 4 or c >= 23):
			continue   # the side doors
		if not _free(room, c, r) or not _free(room, c, r + 1):
			continue
		var x := c * TB.TS + 8.0
		var y := r * TB.TS + (4.0 if on_wall else 8.0)
		var clear := true
		for o2 in room.objects:
			if TB.dist_xy(x, y, o2["x"], o2["y"]) < 34:
				clear = false
		if not clear:
			continue
		o["x"] = x
		o["y"] = y
		room.objects.append(o)
		return

# ---------- Using things ----------
static func handles(kind: String) -> bool:
	return kind in KINDS

static func interact(o: Dictionary) -> void:
	var p := G.player
	var f := G.floor_index
	match o["kind"]:
		"x_table":
			flip(o)
		"x_lever":
			o["pulled"] = true
			o["used"] = true
			for i in 4:
				Combat.drop_pickup("coin", o["x"], o["y"] + 14)
			if randf() < 0.3:
				Combat.drop_pickup("key", o["x"], o["y"] + 14)
			Fx.burst(o["x"], o["y"] + 4, ["#5a6660", "#7a8a80"], 14, 60)
			G.add_shake(3)
			Snd.play("lock")
			G.toast("A HIDDEN ALCOVE GRINDS OPEN", "gold")
		"x_skull":
			o["talks"] += 1
			G.toast(SKULL_JOKES[o["talks"] - 1], "white")
			Snd.play("select")
			if o["talks"] >= SKULL_JOKES.size():
				o["used"] = true
				Combat.drop_pickup("gem", o["x"], o["y"] + 12)
				G.toast("THE SKULL SPITS OUT A GEM. TOUGH CROWD", "gold")
		"x_fisher":
			o["talks"] += 1
			if o["talks"] == 1:
				G.toast("SHH. THEY'RE BITING.", "grey")
			else:
				o["used"] = true
				if randf() < 0.5:
					Combat.drop_pickup("heart", o["x"], o["y"] + 12)
					G.toast("A FISH! WELL, IT'S FOOD.", "pink")
				else:
					Combat.drop_pickup("coin", o["x"], o["y"] + 12)
					G.toast("AN OLD BOOT. THERE WAS A COIN IN IT.", "gold")
			Snd.play("select")
		"x_saint":
			var cost := G.price(15 + f * 3)
			if p.gold < cost:
				return G.deny(o, "NEED %d GOLD" % cost)
			p.gold -= cost
			o["used"] = true
			Effects.add_buff(p, "dmg", 0.2, 90.0)
			Fx.burst(o["x"], o["y"] - 10, ["#f2c94c", "#e8873a", "#ffffff"], 18, 70)
			Snd.play("relic")
			G.toast("THE BULLET SAINT BLESSES YOUR ROUNDS: +20% FOR 90S", "gold")
		"x_ratpile":
			o["used"] = true
			var stolen := mini(p.gold, 10 + f * 2)
			p.gold -= stolen
			o["stolen"] = stolen   # what the rat carries off (paid back twice over when caught)
			Combat.spawn_enemy("casingrat", o["x"], o["y"], false, true)
			Snd.play("roar")
			G.toast("A RAT! IT GRABS %d GOLD AND RUNS" % stolen, "red")

## Flipping a table: its two tiles become cover; nothing is left stuck inside them.
static func flip(o: Dictionary) -> void:
	var room := G.room
	o["flipped"] = true
	o["used"] = true
	for dc in 2:
		room.set_tile(o["c"] + dc, o["r"], World.T_PROP)
	_unstick(G.player, World.M_PLAYER)
	for e in G.enemies:
		if not e.d.get("fly", false):
			_unstick(e, World.M_WALKER)
	G.dyn_dirty = true
	G.add_shake(2)
	Snd.play("place")
	Fx.burst(o["x"], o["y"] - 4, ["#7a5236", "#5a3a26"], 10, 50)

static func _unstick(b: Object, mode: int) -> void:
	var room := G.room
	if not World.hits_solid(room, b.x, b.y, b.r, mode):
		return
	for d in range(1, 40):
		for a in 8:
			var x: float = b.x + cos(a * TAU / 8) * d
			var y: float = b.y + sin(a * TAU / 8) * d
			if not World.hits_solid(room, x, y, b.r, mode):
				b.x = x
				b.y = y
				return

## A foe died (Combat.kill_enemy): a caught rat pays back twice what it stole.
static func on_kill(e: Enemy) -> void:
	if e.type != "casingrat" or G.room == null:
		return
	var back := 0
	for o in G.room.objects:
		if o["kind"] == "x_ratpile" and o.get("stolen", 0) > 0:
			back = o["stolen"] * 2
			o["stolen"] = 0
			break
	G.player.gold += back
	Fx.float_text(e.x, e.y - 12, "+%d GOLD" % back, "gold")
	G.toast("CAUGHT IT. THE RAT PAYS BACK DOUBLE", "gold")

# ---------- Hazards (Hazards.update calls this) ----------
const TIDE_WARN := 1.2
const TIDE_SPEED := 220.0
const TIDE_HALF := 16.0
const TURRET_AIM := 0.8

static func hazard_setup(room: Room, kind: String) -> void:
	room.strike_t = 2.0
	if kind == "turrets":
		for c in [6, 21]:
			room.turrets.append({ "x": c * TB.TS + 8.0, "y": 2.0 * TB.TS + 6.0, "t": 1.0 + randf() * 2.0, "state": 0, "a": PI / 2,
				"shots": 0 })

static func update(room: Room, dt: float) -> void:
	var kind: String = "" if room.type == "boss" else room.theme.get("hazard", "")   # a guardian calls its own
	var active := G.enemies_active()
	if kind == "tide" or not room.tides.is_empty():
		_update_tide(room, dt, active and kind == "tide")
	if not room.turrets.is_empty():
		_update_turrets(room, dt, active)

static func _update_tide(room: Room, dt: float, active: bool) -> void:
	var p := G.player
	if active:
		room.strike_t -= dt
		if room.strike_t <= 0:
			room.strike_t = 4.0 + randf() * 1.4
			var y := clampf(p.y if randf() < 0.6 else randf_range(4 * TB.TS, 16 * TB.TS), 4 * TB.TS, 16 * TB.TS)
			var dir := 1 if randf() < 0.5 else -1
			room.tides.append({ "y": y, "dir": dir, "t": TIDE_WARN, "x": TB.TS - 10.0 if dir > 0 else TB.SW - TB.TS + 10.0,
				"hit": {}, "hit_p": false })
	var keep := []
	for w in room.tides:
		if w["t"] > 0:
			w["t"] -= dt
			if active:
				keep.append(w)
			continue
		w["x"] += w["dir"] * TIDE_SPEED * dt
		if w["x"] < -30 or w["x"] > TB.SW + 30:
			continue
		keep.append(w)
		if not w["hit_p"] and absf(p.y - w["y"]) < TIDE_HALF and absf(p.x - w["x"]) < 10:
			w["hit_p"] = true
			Combat.hurt_player(1, "the toxic tide", true)
		for e in G.enemies.duplicate():
			if not e.targetable() or w["hit"].has(e.uid) or e.d.get("champion", false) or e.is_boss():
				continue
			if absf(e.y - w["y"]) < TIDE_HALF + e.r and absf(e.x - w["x"]) < 10 + e.r:
				w["hit"][e.uid] = true
				Combat.damage_enemy(e, 12.0 * Combat.floor_scale(), { "no_crit": true, "no_mult": true, "col": "green",
					"kx": w["dir"] * 160.0, "ky": 0.0 })
	room.tides = keep

static func _update_turrets(room: Room, dt: float, active: bool) -> void:
	var p := G.player
	for t in room.turrets:
		match t["state"]:
			0:   # waiting
				if not active:
					continue
				t["t"] -= dt
				if t["t"] <= 0:
					t["state"] = 1
					t["t"] = TURRET_AIM
					t["a"] = atan2(p.y - t["y"], p.x - t["x"])
			1:   # aiming: the line is shown, the aim is fixed
				t["t"] -= dt
				if t["t"] <= 0:
					t["state"] = 2
					t["shots"] = 3
					t["t"] = 0.0
			2:   # firing
				t["t"] -= dt
				if t["t"] <= 0 and t["shots"] > 0:
					t["shots"] -= 1
					t["t"] = 0.12
					Combat.eshot(t["x"], t["y"] + 6, t["a"], 150.0, "red", 2.5)
					Snd.play("shot")
				if t["shots"] <= 0:
					t["state"] = 0
					t["t"] = 2.6 + randf() * 1.0

static func draw_hazards(ci: CanvasItem, t: float) -> void:
	var room := G.room
	if room == null:
		return
	for w in room.tides:
		var y: float = w["y"]
		if w["t"] > 0:
			var a := 0.18 + (0.14 if floori(t * 10) % 2 == 0 else 0.0)
			ci.draw_rect(Rect2(TB.TS, y - TIDE_HALF, TB.SW - 2 * TB.TS, TIDE_HALF * 2), Color(0.39, 0.72, 0.31, a))
			var x := 24.0
			while x < TB.SW - 24:
				var cx: float = x if w["dir"] > 0 else TB.SW - x
				ci.draw_rect(Rect2(roundf(cx), y - 1, 6, 2), Color(0.72, 0.88, 0.35, 0.85))
				x += 28
		else:
			var x0: float = w["x"]
			var back: float = -w["dir"] * 34.0
			ci.draw_rect(Rect2(minf(x0, x0 + back), y - TIDE_HALF, absf(back), TIDE_HALF * 2), Color(0.25, 0.48, 0.35, 0.55))
			ci.draw_rect(Rect2(x0 - 3, y - TIDE_HALF, 6, TIDE_HALF * 2), Color(0.72, 0.88, 0.35, 0.95))
			for k in 4:
				Gfx.px(ci, TB.c("#f4ecd8"), x0 - 2 + w["dir"] * 2, y - TIDE_HALF + 4 + k * 8 + fmod(t * 40 + k * 3, 4), 2)
	for tr in room.turrets:
		Gfx.sp(ci, "wall_turret", tr["x"], tr["y"] + 4)
		if tr["state"] == 1:
			var i := 14.0
			while i < 320:
				Gfx.px(ci, TB.ca("#d8443c", 170 if floori(t * 16) % 2 == 0 else 90), tr["x"] + cos(tr["a"]) * i - 1,
					tr["y"] + 6 + sin(tr["a"]) * i - 1, 2)
				i += 7

# ---------- Prompts and drawing ----------
static func prompt(o: Dictionary) -> Array:
	match o["kind"]:
		"x_table":
			return ["A HEAVY TABLE", "FLIP IT: COVER THAT STOPS SHOTS", "FLIP IT"]
		"x_lever":
			return ["A RUSTY LEVER", "SOMETHING IN THE WALL CLICKS WHEN YOU TOUCH IT", "PULL IT"]
		"x_skull":
			return ["A SKULL ON A PIKE", "IT LOOKS LIKE IT WANTS TO TALK", "LISTEN"]
		"x_fisher":
			return ["A HOODED FIGURE", "FISHING IN A PUDDLE. PATIENTLY", "WATCH"]
		"x_saint":
			return ["THE BULLET SAINT", "A BLESSING ON YOUR SHOTS: +20% DAMAGE FOR 90S", "PAY %d GOLD" % G.price(15 + G.floor_index * 3)]
		"x_ratpile":
			return ["A PILE OF CASINGS", "SOMETHING IN IT IS SNORING", "POKE IT"]
	return ["", "", ""]

static func draw(ci: CanvasItem, o: Dictionary, t: float) -> void:
	var x: float = o["x"]
	var y: float = o["y"]
	match o["kind"]:
		"x_table":
			Gfx.sp(ci, "table_flipped" if o["flipped"] else "table_up", x, y - (2.0 if o["flipped"] else 4.0))
		"x_lever":
			Gfx.sp(ci, "lever_on" if o["pulled"] else "lever_off", x, y, 2, 2)
		"x_skull":
			Gfx.sp(ci, "skull_pike", x, y + 4, 1, 1, sin(t * 2) * 0.05)
		"x_fisher":
			Gfx.sp(ci, "npc_fisher", x, y + 6)
		"x_saint":
			Gfx.sp(ci, "bullet_saint", x, y + 6)
			if not o.get("used", false) and floori(t * 2) % 2 == 0:
				Gfx.px(ci, TB.c("#f2c94c"), x - 1, y - 12, 2)
		"x_ratpile":
			Gfx.sp(ci, "casing_pile", x, y + 4)
			if not o.get("used", false):
				var zt := fmod(t, 2.0)
				Gfx.text(ci, "Z", x + 4 + zt * 3, y - 12 - zt * 5, "grey", 1, 0.5, true, 1.0 - zt / 2.0)
