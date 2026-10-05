class_name Summons
extends RefCounted
## ROADMAP 4.6 part 3, DECK AND DEN: card decks, turrets, summoned fighters, pet commands, mirror
## images, swarms, a dragon egg and a taming whip (ideas from Slay the Spire, Risk of Rain's
## engineer, Dead Cells' turrets, Aion's spiritmasters, Worms and Enter the Gungeon's mimics; ideas
## only, every name, picture and number is this game's own).
##
## Kinds (Combat.player_shoot calls `fire`):
##   deck     a deck of cards, one played an attack; the next three show over the hero; when the
##            pile runs out the played cards are shuffled back in (a short pause)
##   turret   each attack builds a turret (or a trap) by you; two at a time, the oldest goes
##   thrall   fighters on your side: bones raised from kills, a growing golem, imps, wolves, a mimic
##   command  your pet's spirit (or a sheep) sent at the foe you aim at
##   mirror   mirror images that fire when you fire, or a shadow that repeats your cuts
##   swarm    a cloud of bats, or fireflies, sent at the foe you aim at
##   egg      a bolt; hits warm the egg until a baby dragon hatches for the room
## And the action ["charm", seconds] (the tamer's whip): an ordinary foe fights for you a while.
## What a weapon of those kinds does differently comes from keys on its row (TWISTS).
##
## +1 PROJECTILE STACKS WITHOUT LIMIT: cards, turrets, thralls, the pet's leap, the bats and the
## dragon hit 35% harder for every projectile past the first; a blade dance throws up to 8 shivs and
## a horn calls up to 6 wolves, then they merge the same way. Mirror images and the egg's bolt fire
## through the usual shot path (Combat.fire_projectiles). Summons cannot be hurt, and never pass
## their caps (two turrets, four bones, three imps, one golem, one mimic, 12 fireflies).
## Emptied when the room changes, except the deck (shuffled anew) and the egg's warmth (halved).

const KINDS := ["deck", "turret", "thrall", "command", "mirror", "swarm", "egg"]
## Keys a weapon row may carry to change what its kind does (the uniqueness report counts them).
const TWISTS := ["deck", "ascend", "turret", "thrall", "command", "mirror", "swarm"]
## Cards: id -> [letter on the card, its colour (a font colour)].
const CARDS := { "strike": ["S", "red"], "bash": ["B", "orange"], "cleave": ["C", "white"], "flurry": ["F", "gold"],
	"toxin": ["T", "lime"], "catalyst": ["K", "green"], "noxious": ["N", "green"], "shiv": ["V", "grey"],
	"dance": ["D", "bone"], "finisher": ["X", "purple"], "bomb": ["O", "red"], "double": ["2", "cyan"] }
const MAX_TURRETS := 2
const MAX_BONES := 4
const MAX_IMPS := 3
const MAX_FLIES := 12
const HATCH := 15

static var draw: Array = []       # deck: the draw pile, its first three the hand you see: { id, up }
static var discard: Array = []
static var shuffle_t := 0.0
static var played := 0            # cards played since the last shuffle (the finisher)
static var doubled := 0           # the next card is played this many more times (double tap)
static var cards: Array = []      # cards flying to their foe: { c, up, x, y, tx, ty, e, dmg, crit }
static var bombs: Array = []      # countdown bombs: { x, y, left, dmg }
static var turrets: Array = []    # { x, y, k, t, cd, a, dmg, hit, col, mend }
static var thralls: Array = []    # { k, x, y, t, cd, dmg, size, face, tx, ty, hop, e }
static var leaps: Array = []      # spirits and sheep in the air or about to blow: { k, spr, x0, y0, x1, y1, t, dur, dmg, rad, sit, e }
static var images: Array = []     # mirror images: { x, y, t }
static var trail: Array = []      # the hero's last second (the doppelganger): Vector2, newest last
static var echoes: Array = []     # the shadow's cuts to come: { t, dmg, crit }
static var swarms: Array = []     # { k, x, y, n, t, hit, e, a, idle }
static var warmth := 0
static var dragon := {}           # the hatchling: { x, y, cd, face }
static var flashes: Array = []    # zaps and rings: { k, x0, y0, x1, y1, t, max, col }
static var _room: WeakRef = null
static var _wid := ""
static var stats := {}            # how often each trick happened (tests/arsenal_test reads it)

static func _stat(k: String, n: int = 1) -> void:
	stats[k] = stats.get(k, 0) + n

static func handles(kind: String) -> bool:
	return kind in KINDS

static func _col(w: Dictionary) -> String:
	return Weapons.TAG_COLS[w["tags"][0] if w["tags"].size() > 0 else "core"][0]

## The room changed: summons and things in flight are gone; the deck is shuffled anew (upgrades
## lost); a hatched dragon goes back into its egg, half warm.
static func clear() -> void:
	cards.clear()
	bombs.clear()
	turrets.clear()
	thralls.clear()
	leaps.clear()
	images.clear()
	trail.clear()
	echoes.clear()
	swarms.clear()
	flashes.clear()
	if not draw.is_empty() or not discard.is_empty():
		var all := draw + discard
		for c in all:
			c["up"] = 0
		all.shuffle()
		draw = all
		discard = []
	played = 0
	doubled = 0
	shuffle_t = 0.0
	if not dragon.is_empty():
		dragon = {}
		warmth = int(HATCH * 0.5)

static func _reset_weapon() -> void:
	draw = []
	discard = []
	played = 0
	doubled = 0
	warmth = 0
	dragon = {}
	clear()

## The foe nearest your aim (within about 30 degrees, 260 px), else the nearest one in sight.
static func _aimed(p: Player, a: float) -> Enemy:
	var best: Enemy = null
	var bd := 260.0
	for e in G.enemies:
		if e.targetable() and e.charm_t <= 0 and absf(TB.wrap_ang(TB.ang_to(p, e) - a)) < 0.5:
			var d := TB.dist(p, e)
			if d < bd:
				bd = d
				best = e
	return best if best != null else Combat.auto_target(p, 260)

# ---------- Firing (Combat.player_shoot) ----------
## Returns the player shots made (shivs, mirror images, the egg's bolt) for the per-shot rules.
static func fire(p: Player, a: float, forced: bool) -> Array:
	var w: Dictionary = p.weapon
	var n := Weapons.wcount(p)
	var more := 1.0 + 0.35 * (n - 1)
	match w["kind"]:
		"deck":
			return _deck(p, a, w, n, more, forced)
		"turret":
			_turret(p, a, w, more)
		"thrall":
			return _thrall(p, a, w, n, more, forced)
		"command":
			_command(p, a, w, more)
		"mirror":
			return _mirror(p, a, w, more, forced)
		"swarm":
			_swarm(p, a, w, n)
		"egg":
			return Combat.fire_projectiles(p, a)
	return []

static func _deck(p: Player, a: float, w: Dictionary, n: int, more: float, forced: bool) -> Array:
	if draw.is_empty() and discard.is_empty():
		for id in w.get("deck", ["strike"]):
			draw.append({ "id": id, "up": 0 })
		draw.shuffle()
	if draw.is_empty():
		_shuffle(p, w)
		return []
	var card: Dictionary = draw.pop_front()
	discard.append(card)
	played += 1
	var times := 1 + doubled
	doubled = 0
	var made := []
	for k in times:
		made += _play(p, a, card, n, more, forced)
	if times > 1:
		_stat("doubled")
	# Countdown bombs: one card closer.
	for b in bombs:
		b["left"] -= 1
	if draw.is_empty():
		_shuffle(p, w)
	return made

static func _shuffle(p: Player, w: Dictionary) -> void:
	if w.get("ascend", false) and not discard.is_empty():
		# The ascending deck: one card is upgraded at every shuffle (+50%, up to three times).
		var c: Dictionary = discard[randi() % discard.size()]
		if c["up"] < 3:
			c["up"] += 1
			_stat("ascend")
			Fx.float_text(p.x, p.y - 30, "+ " + String(c["id"]).to_upper(), "gold")
	draw = discard
	discard = []
	draw.shuffle()
	played = 0
	shuffle_t = 0.6
	p.fire_cd = maxf(p.fire_cd, 0.6)
	_stat("shuffle")
	Snd.play("select")

static func _play(p: Player, a: float, card: Dictionary, n: int, more: float, forced: bool) -> Array:
	var id: String = card["id"]
	var up: float = 1.0 + 0.5 * card["up"]
	var dmg := Weapons.wdmg(p) * more * up
	var t := _aimed(p, a)
	_stat("card_" + id)
	var made := []
	match id:
		"strike":
			_fly(p, id, t, a, dmg * 2.2, forced)
		"bash":
			_fly(p, id, t, a, dmg * 1.5, forced)
		"flurry":
			_fly(p, id, t, a, dmg * 0.55, forced)
		"toxin", "catalyst":
			_fly(p, id, t, a, dmg * 0.5, forced)
		"noxious":
			_fly(p, id, t, a, dmg * 0.3, forced)
		"finisher":
			_fly(p, id, t, a, dmg * 0.7 * played, forced)
		"bomb":
			_fly(p, id, t, a, dmg * 5.0, forced)
		"double":
			doubled += 1
			Fx.float_text(p.x, p.y - 30, "X2", "cyan")
			Snd.play("lock")
		"cleave":
			for e in G.enemies.duplicate():
				if e.targetable() and e.charm_t <= 0 and TB.dist(e, p) - e.r < 42.0:
					Combat.melee_hit(p, e, dmg * 1.3, forced, 120.0)
					Afx.cut(e.x, e.y - e.z, TB.ang_to(p, e), false)
			G.swings.append({ "kind": "slash", "x": p.x, "y": p.y - 2, "a": a, "r": 42.0, "arc": TAU, "t": 0.14, "max": 0.14, "tag": "edge" })
			Snd.play("hatchet")
		"shiv", "dance":
			# Shivs are thrown: +1 projectile throws more of them (up to 8), then merges.
			var want := (1 if id == "shiv" else 3) + n - 1
			var per := Weapons.wdmg(p) * up * 0.9 * (1.0 + 0.35 * maxi(0, want - 8))
			var k := mini(want, 8)
			var aim := TB.ang_to(p, t) if t != null else a
			for i in k:
				var s := Combat._raw_shot(p.x, p.y - 3, aim + (i - (k - 1) / 2.0) * 0.16, 330, per, 0.6, 2.0, 0, "dart", {})
				made.append(s)
			Snd.play("hatchet")
	return made

## A card flies to its foe (or along the aim) and does its work where it lands.
static func _fly(p: Player, id: String, t: Enemy, a: float, dmg: float, crit: bool) -> void:
	var to := Vector2(t.x, t.y - 2) if t != null else Vector2(p.x, p.y) + Vector2.from_angle(a) * 120.0
	cards.append({ "c": id, "x": p.x, "y": p.y - 8, "tx": to.x, "ty": to.y, "e": weakref(t) if t != null else null, "dmg": dmg, "crit": crit })
	Snd.play("dodge")

static func _land(c: Dictionary, p: Player) -> void:
	var e: Enemy = c["e"].get_ref() if c["e"] != null else null
	if e == null or e.hp <= 0 or not e.targetable():
		e = Combat.nearest_enemy(c["tx"], c["ty"], 16)
	var x: float = c["tx"]
	var y: float = c["ty"]
	var dmg: float = c["dmg"]
	match c["c"]:
		"strike", "bash", "toxin", "finisher":
			if e != null:
				var hit := Combat.damage_enemy(e, dmg, { "force_crit": c["crit"] })
				Combat.on_hit_effects(e, dmg, hit, p, null)
				if c["c"] == "bash":
					Statuses.apply(e, "vulnerable", 1, dmg)
				if c["c"] == "toxin":
					Statuses.apply(e, "poison", 3, dmg)
				if c["c"] == "finisher":
					_stat("finisher_hit")
		"flurry":
			if e != null:
				for i in 4:
					if e.hp <= 0:
						break
					var hit := Combat.damage_enemy(e, dmg, { "force_crit": c["crit"] and i == 0, "silent": i > 0 })
					Combat.on_hit_effects(e, dmg, hit, p, null)
		"catalyst":
			# Every poisoned foe near the target: its poison doubled.
			for o in G.enemies:
				if o.targetable() and o.poison > 0 and TB.dist_xy(o.x, o.y, x, y) < 60.0 + o.r:
					o.poison = minf(12.0, o.poison * 2.0)
					_stat("catalyst")
			if e != null:
				var hit := Combat.damage_enemy(e, dmg, { "force_crit": c["crit"] })
				Combat.on_hit_effects(e, dmg, hit, p, null)
			Vfx.puff(x, y, "venom")
		"noxious":
			if G.zones.size() < 60:
				G.zones.append({ "x": x, "y": y + 2, "r": 26, "t": 3.5, "kind": "poison", "tick": 0.0 })
				_stat("cloud")
		"bomb":
			bombs.append({ "x": x, "y": y + 2, "left": 3, "dmg": dmg })
			Snd.play("place")
	Fx.burst(x, y, ["#f4ecd8", "#ffffff"], 5, 50, 0.2)

static func _turret(p: Player, a: float, w: Dictionary, more: float) -> void:
	var k: String = w.get("turret", "gun")
	var at := Vector2(p.x, p.y + 2)
	if k == "saw":
		# A trap goes down by the foe you aim at (90 px at most), where foes walk.
		var t := _aimed(p, a)
		at = RiftBosses._inside(Vector2(p.x, p.y) + Vector2.from_angle(a) * (minf(90.0, TB.dist(p, t)) if t != null else 50.0))
	if turrets.size() >= MAX_TURRETS:
		turrets.pop_front()   # two at a time: the oldest goes
	turrets.append({ "x": at.x, "y": at.y, "k": k, "t": 20.0, "cd": 0.3, "a": a, "dmg": Weapons.wdmg(p) * more, "hit": {},
		"col": _col(w), "mend": 0.0 })
	_stat("turret")
	Snd.play("place")
	Afx.dust(at.x, at.y)

static func _thrall(p: Player, a: float, w: Dictionary, n: int, more: float, forced: bool) -> Array:
	var k: String = w.get("thrall", "bones")
	var dmg := Weapons.wdmg(p) * more
	match k:
		"bones":
			return Combat.fire_projectiles(p, a)   # its bolts; the kills rise (on_kill)
		"golem":
			var g := _find("golem")
			if g.is_empty():
				thralls.append({ "k": "golem", "x": p.x + 10.0 * p.face, "y": p.y, "t": 9999.0, "cd": 0.5, "dmg": dmg, "size": 1,
					"face": p.face, "hop": 0.0 })
				Afx.dust(p.x + 10.0 * p.face, p.y)
			else:
				g["size"] = mini(5, g["size"] + 1)
				g["dmg"] = dmg
				if g["size"] == 5:
					_stat("golem_full")
			_stat("clay")
			Snd.play("place")
		"imp":
			var imps := thralls.filter(func(o): return o["k"] == "imp")
			if imps.size() >= MAX_IMPS:
				imps[0]["t"] = 10.0
			else:
				thralls.append({ "k": "imp", "x": p.x, "y": p.y - 10, "t": 10.0, "cd": 0.6, "dmg": dmg, "size": 1, "face": 1,
					"a": randf() * TAU })
				Vfx.puff(p.x, p.y - 10, "fire")
			_stat("imp")
		"wolf":
			# A pack: three wolves (+1 projectile: up to six, then merged) run at the foe you aim at.
			var want := 3 + n - 1
			var per := Weapons.wdmg(p) * (1.0 + 0.35 * maxi(0, want - 6))
			var t := _aimed(p, a)
			for i in mini(want, 6):
				var side := Vector2.from_angle(a + PI / 2) * ((i - 1) * 9.0)
				thralls.append({ "k": "wolf", "x": p.x + side.x, "y": p.y + side.y, "t": 1.6, "cd": 0.0, "dmg": per * 0.9, "size": 1,
					"face": 1 if cos(a) >= 0 else -1, "e": weakref(t) if t != null else null, "a": a })
			_stat("pack")
			Snd.play("charge")
		"mimic":
			var m := _find("mimic")
			if m.is_empty():
				m = { "k": "mimic", "x": p.x - 12.0 * p.face, "y": p.y, "t": 9999.0, "cd": 0.0, "dmg": dmg, "size": 1, "face": p.face,
					"hop": 0.0 }
				thralls.append(m)
			var t := _aimed(p, a)
			if t != null and m["hop"] <= 0:
				# A hop onto the foe: it lands with a chomp.
				m["hop"] = 0.35
				m["x0"] = m["x"]
				m["y0"] = m["y"]
				m["tx"] = t.x
				m["ty"] = t.y
				m["e"] = weakref(t)
				m["dmg"] = dmg * 2.5
				m["crit"] = forced
				_stat("hop")
	return []

static func _find(k: String) -> Dictionary:
	for o in thralls:
		if o["k"] == k:
			return o
	return {}

static func _command(p: Player, a: float, w: Dictionary, more: float) -> void:
	var t := _aimed(p, a)
	var to := Vector2(t.x, t.y) if t != null else Vector2(p.x, p.y) + Vector2.from_angle(a) * 70.0
	var has_pet := p.pet != ""
	var lv := p.pet_lv if has_pet else 0
	var from := Vector2(Pets.x, Pets.y) if has_pet else Vector2(p.x, p.y)
	if w.get("command", "leap") == "leap":
		# Your pet's spirit leaps at the foe and bites (a spirit pup if you have no pet).
		leaps.append({ "k": "bite", "spr": "pet_" + p.pet if has_pet else "pet_biscuit", "x0": from.x, "y0": from.y, "x1": to.x, "y1": to.y,
			"t": 0.0, "dur": 0.3, "dmg": Weapons.wdmg(p) * (2.2 + 0.3 * lv) * more, "rad": 0.0, "sit": 0.0,
			"e": weakref(t) if t != null else null })
		_stat("leap")
		Snd.play("dodge")
	else:
		# The crook lobs a sheep (or your pet's spirit): it lands, sits a moment, and blows.
		leaps.append({ "k": "lob", "spr": "pet_" + p.pet if has_pet else "s_sheep", "x0": p.x, "y0": p.y - 4, "x1": to.x, "y1": to.y,
			"t": 0.0, "dur": 0.5, "dmg": Weapons.wdmg(p) * 3.0 * more, "rad": 30.0 + 6.0 * lv, "sit": 0.6,
			"e": weakref(t) if t != null else null })
		_stat("lob")
		Snd.play("hatchet")

static func _mirror(p: Player, a: float, w: Dictionary, more: float, forced: bool) -> Array:
	if w.get("mirror", "image") == "shadow":
		# The doppelganger: your cut now, your shadow's a second later from where it is.
		var dmg := Weapons.wdmg(p) * more
		var reach := Weapons.wrange(p)
		_cut_at(p, p.x, p.y, a, reach, deg_to_rad(w.get("arc", 110)), dmg, forced, w)
		echoes.append({ "t": 1.0, "dmg": dmg * 0.8, "crit": forced })
		Snd.play("hatchet")
		return []
	# Mirror images fire when you fire, from where they stand, at the foe nearest them.
	var made := Combat.fire_projectiles(p, a)
	var hx := p.x
	var hy := p.y
	var n := Weapons.wcount(p)
	var k := mini(n, 3)   # an image fires at most three shots; more projectiles are merged into them
	var per := Weapons.wdmg(p) * float(n) / k
	for im in images:
		p.x = im["x"]
		p.y = im["y"]
		var t := Combat.auto_target(p, 260)
		var ia := TB.ang_to(p, t) if t != null else a
		for i in k:
			made.append(Combat._raw_shot(im["x"], im["y"] - 3, ia + (i - (k - 1) / 2.0) * 0.12, Weapons.wspd(p), per, Weapons.wlife(p), 2.5, 0, "bolt", {}))
		_stat("image_shot")
	p.x = hx
	p.y = hy
	if images.size() >= 2:
		images.pop_front()
	images.append({ "x": p.x, "y": p.y, "t": 5.0, "face": p.face })
	return made

static func _swarm(p: Player, a: float, w: Dictionary, n: int) -> void:
	var t := _aimed(p, a)
	if w.get("swarm", "bats") == "bats":
		var cloud := {}
		for s in swarms:
			if s["k"] == "bats":
				cloud = s
		if cloud.is_empty():
			cloud = { "k": "bats", "x": p.x, "y": p.y - 8, "n": 0, "t": 0.0, "hit": 0.0, "e": null, "idle": 0.0 }
			swarms.append(cloud)
		cloud["n"] = mini(int(cloud["n"]) + 2, 12)
		cloud["more"] = 1.0 + 0.35 * (n - 1)
		cloud["idle"] = 0.0
		if t != null:
			cloud["e"] = weakref(t)
		_stat("bats")
		Snd.play("dodge")
	else:
		var flies := swarms.filter(func(s): return s["k"] == "fly")
		if flies.size() >= MAX_FLIES:
			swarms.erase(flies[0])
		if t != null:
			swarms.append({ "k": "fly", "x": p.x, "y": p.y - 8, "t": 6.0, "hit": 0.3, "e": weakref(t), "a": randf() * TAU,
				"dmg": Weapons.wdmg(p) * (1.0 + 0.35 * (n - 1)) })
			_stat("firefly")
			Snd.play("select")

# ---------- Actions ----------
## ["warm", n] (the dragon egg's hits): warmer; at HATCH, the dragon hatches for the room.
static func warm(n: int) -> void:
	var p := G.player
	if p == null or p.weapon == null or p.weapon["kind"] != "egg" or not dragon.is_empty():
		return
	warmth += n
	if warmth >= HATCH:
		dragon = { "x": p.x, "y": p.y - 12, "cd": 0.6, "face": p.face }
		_stat("hatch")
		Fx.float_text(p.x, p.y - 26, "HATCHED!", "orange", true)
		Fx.burst(p.x, p.y - 10, ["#f4ecd8", "#e8873a", "#f2c94c"], 14, 70, 0.4)
		Snd.play("unlock")

## ["charm", seconds] (the tamer's whip): an ordinary foe fights for you for a while.
static func charm(e: Enemy, secs: float) -> void:
	if e == null or e.hp <= 0 or e.is_boss() or e.elite or e.d.get("mini", false) or e.d.get("champion", false) or e.type == "dummy":
		return
	if e.charm_t <= 0:
		_stat("charm")
		Fx.float_text(e.x, e.y - e.r - 10, "TAMED", "pink")
	e.charm_t = maxf(e.charm_t, secs)
	e.puppet_t = 0.0

## A tamed foe's turn (Combat.update_enemies, instead of its own AI): it goes for the nearest other
## foe and hits it.
static func charm_tick(e: Enemy, dt: float) -> void:
	e.charm_t -= dt
	var other: Enemy = null
	var bd := 1e9
	for o in G.enemies:
		if o != e and o.targetable() and o.charm_t <= 0 and o.type != "dummy":
			var d := TB.dist(o, e)
			if d < bd:
				bd = d
				other = o
	if other == null:
		return
	if bd > e.r + other.r + 2:
		Combat.steer(e, other.x, other.y, maxf(e.speed, 30.0) * 1.2, dt, World.M_FLYER if e.d.get("fly", false) else World.M_WALKER)
	elif e.t <= 0:
		e.t = 0.6
		var p := G.player
		var dmg := Weapons.wdmg(p) * 1.2 * (1.0 + 0.35 * (Weapons.wcount(p) - 1))   # +1 projectile: harder blows
		var c := Combat.damage_enemy(other, dmg, { "col": "pink" })
		Combat.on_hit_effects(other, dmg, c, p, null)
		Afx.cut(other.x, other.y - other.z, TB.ang_to(e, other), false)
		_stat("charm_hit")

## A kill (Combat.kill_enemy): the gravecaller raises it as a bone thrall.
static func on_kill(e: Enemy) -> void:
	var p := G.player
	if p == null or p.weapon == null or p.weapon.get("thrall", "") != "bones" or e.type == "dummy" or e.is_boss():
		return
	var bones := thralls.filter(func(o): return o["k"] == "bones")
	if bones.size() >= MAX_BONES:
		thralls.erase(bones[0])
	var n := Weapons.wcount(p)
	thralls.append({ "k": "bones", "x": e.x, "y": e.y, "t": 12.0, "cd": 0.6, "dmg": Weapons.wdmg(p) * 0.8 * (1.0 + 0.35 * (n - 1)),
		"size": 1, "face": 1, "rise": 0.4 })
	_stat("raise")
	Vfx.puff(e.x, e.y, "void")

# ---------- Every tick (Hazards.update) ----------
static func tick(room: Room, dt: float) -> void:
	if _room == null or _room.get_ref() != room:
		clear()
		_room = weakref(room)
	var p := G.player
	if p == null or p.weapon == null:
		return
	if p.weapon["id"] != _wid:
		_wid = p.weapon["id"]
		_reset_weapon()
	shuffle_t = maxf(0.0, shuffle_t - dt)
	if not cards.is_empty():
		_tick_cards(p, dt)
	if not bombs.is_empty():
		var keep := []
		for b in bombs:
			if b["left"] <= 0:
				Arsenal.blast(b["x"], b["y"], b["dmg"], 46.0, "#e8873a")
				_stat("bomb_blow")
			else:
				keep.append(b)
		bombs = keep
	if not turrets.is_empty():
		_tick_turrets(p, dt)
	if not thralls.is_empty():
		_tick_thralls(p, room, dt)
	if not leaps.is_empty():
		_tick_leaps(p, dt)
	if p.weapon.get("mirror", "") == "shadow":
		trail.append(Vector2(p.x, p.y))
		if trail.size() > 60:
			trail.pop_front()
	if not echoes.is_empty():
		_tick_echoes(p, dt)
	if not images.is_empty():
		var keep := []
		for im in images:
			im["t"] -= dt
			if im["t"] > 0:
				keep.append(im)
		images = keep
	if not swarms.is_empty():
		_tick_swarms(p, dt)
	if not dragon.is_empty():
		_tick_dragon(p, dt)
	if not flashes.is_empty():
		var kf := []
		for f in flashes:
			f["t"] -= dt
			if f["t"] > 0:
				kf.append(f)
		flashes = kf

static func _tick_cards(p: Player, dt: float) -> void:
	var keep := []
	for c in cards:
		var e: Enemy = c["e"].get_ref() if c["e"] != null else null
		if e != null and e.hp > 0:
			c["tx"] = e.x
			c["ty"] = e.y - 2
		var d := TB.dist_xy(c["x"], c["y"], c["tx"], c["ty"])
		var s := 360.0 * dt
		if d <= s:
			_land(c, p)
			continue
		c["x"] += (c["tx"] - c["x"]) / d * s
		c["y"] += (c["ty"] - c["y"]) / d * s
		keep.append(c)
	cards = keep

static func _tick_turrets(p: Player, dt: float) -> void:
	var keep := []
	var coils := []
	for o in turrets:
		o["t"] -= dt
		if o["t"] <= 0:
			continue
		keep.append(o)
		o["cd"] -= dt
		var x: float = o["x"]
		var y: float = o["y"]
		var dmg: float = o["dmg"]
		match o["k"]:
			"gun":
				if o["cd"] <= 0:
					var e := Combat.nearest_enemy(x, y, 160)
					if e != null:
						o["cd"] = 0.45
						o["a"] = TB.ang_xy(x, y - 5, e.x, e.y)
						Combat._raw_shot(x + cos(o["a"]) * 4, y - 5 + sin(o["a"]) * 4, o["a"], 260, dmg * 0.8, 0.8, 2.0, 0, "bolt", {})
						Fx.particle(x + cos(o["a"]) * 5, y - 5 + sin(o["a"]) * 5, 0, 0, 0.05, "#fffbe0", 2)
						_stat("turret_shot")
			"flame":
				if o["cd"] <= 0:
					var e := Combat.nearest_enemy(x, y, 70)
					if e != null:
						o["cd"] = 0.1
						o["a"] = TB.ang_xy(x, y - 4, e.x, e.y)
						Combat._raw_shot(x, y - 4, o["a"] + randf_range(-0.2, 0.2), 150, dmg * 0.22, 0.45, 2.5, 2, "fire", {})
						_stat("flame")
			"tesla":
				coils.append(o)
				if o["cd"] <= 0:
					var e := Combat.nearest_enemy(x, y, 70)
					if e != null:
						o["cd"] = 0.7
						var c := Combat.damage_enemy(e, dmg * 0.9, { "col": "cyan" })
						Combat.on_hit_effects(e, dmg * 0.9, c, p, null)
						flashes.append({ "k": "zap", "x0": x, "y0": y - 10, "x1": e.x, "y1": e.y - 4, "t": 0.12, "max": 0.12, "col": "#6fd3e0" })
						_stat("zap")
			"frost":
				if o["cd"] <= 0:
					o["cd"] = 1.0
					for e in G.enemies.duplicate():
						if e.targetable() and e.charm_t <= 0 and TB.dist_xy(e.x, e.y, x, y) < 50.0 + e.r:
							var c := Combat.damage_enemy(e, dmg, { "col": "cyan" })
							Combat.on_hit_effects(e, dmg, c, p, null)
							e.chill_t = maxf(e.chill_t, 1.5)
							_stat("frost_pulse")
					flashes.append({ "k": "ring", "x0": x, "y0": y, "x1": 50.0, "y1": 0.0, "t": 0.3, "max": 0.3, "col": "#c8f0ff" })
			"saw":
				if o["cd"] <= 0:
					o["cd"] = 0.2
					for e in G.enemies.duplicate():
						if e.targetable() and e.charm_t <= 0 and TB.dist_xy(e.x, e.y, x, y) < 10.0 + e.r:
							var c := Combat.damage_enemy(e, dmg * 0.35, { "silent": true })
							Combat.on_hit_effects(e, dmg * 0.35, c, p, null)
							e.chill_t = maxf(e.chill_t, 0.4)
							_stat("saw")
			"mend":
				if o["cd"] <= 0:
					# The two nearest foes in reach.
					var near := []
					for e in G.enemies:
						if e.targetable() and e.charm_t <= 0 and TB.dist_xy(e.x, e.y, x, y) < 80.0:
							near.append(e)
					near.sort_custom(func(a1, b1): return TB.dist_xy(a1.x, a1.y, x, y) < TB.dist_xy(b1.x, b1.y, x, y))
					if not near.is_empty():
						o["cd"] = 0.6
					for e in near.slice(0, 2):
						var c := Combat.damage_enemy(e, dmg * 0.9, { "col": "green" })
						Combat.on_hit_effects(e, dmg * 0.9, c, p, null)
						flashes.append({ "k": "zap", "x0": x, "y0": y - 12, "x1": e.x, "y1": e.y - 4, "t": 0.12, "max": 0.12, "col": "#b8e05a" })
						_stat("mend_zap")
				if TB.dist_xy(p.x, p.y, x, y) < 40.0:
					o["mend"] += dt
					if o["mend"] >= 12.0:
						o["mend"] = 0.0
						if p.hp < p.max_hp:
							p.heal(1)
							_stat("mend")
							Fx.float_text(p.x, p.y - 22, "+", "lime", true)
	turrets = keep
	if coils.size() >= 2:
		# Two coils: a beam between them burns foes crossing it.
		var a := Vector2(coils[0]["x"], coils[0]["y"] - 10)
		var b := Vector2(coils[1]["x"], coils[1]["y"] - 10)
		var hit: Dictionary = coils[0]["hit"]
		for uid in hit.keys():
			hit[uid] -= dt
			if hit[uid] <= 0:
				hit.erase(uid)
		for e in G.enemies.duplicate():
			if not e.targetable() or e.charm_t > 0 or hit.has(e.uid):
				continue
			var at := Vector2(e.x, e.y - 4)
			if Geometry2D.get_closest_point_to_segment(at, a, b).distance_to(at) < e.r + 4:
				hit[e.uid] = 0.25
				var dm: float = coils[0]["dmg"] * 0.45
				var c := Combat.damage_enemy(e, dm, { "col": "cyan", "silent": true })
				Combat.on_hit_effects(e, dm, c, p, null)
				_stat("link")

## A step of a summon on the floor, stopped by walls.
static func _step(o: Dictionary, dx: float, dy: float, room: Room) -> void:
	if not World.hits_solid(room, o["x"] + dx, o["y"], 3.0, World.M_WALKER):
		o["x"] += dx
	if not World.hits_solid(room, o["x"], o["y"] + dy, 3.0, World.M_WALKER):
		o["y"] += dy

static func _tick_thralls(p: Player, room: Room, dt: float) -> void:
	var keep := []
	for o in thralls:
		o["t"] -= dt
		if o["t"] <= 0:
			if o["k"] == "bones":
				Vfx.puff(o["x"], o["y"], "void")
			continue
		o["cd"] -= dt
		var x: float = o["x"]
		var y: float = o["y"]
		match o["k"]:
			"bones", "golem":
				if o.get("rise", 0.0) > 0:
					o["rise"] -= dt
					keep.append(o)
					continue
				var size: int = o["size"]
				var e := Combat.nearest_enemy(x, y, 220)
				if e != null and e.charm_t > 0:
					e = null
				var reach: float = 8.0 if o["k"] == "bones" else 12.0 + 3.0 * size
				if e == null:
					# Nothing to fight: back to the hero's side.
					var hd := TB.dist_xy(x, y, p.x, p.y)
					if hd > 24.0:
						_step(o, (p.x - x) / hd * 50.0 * dt, (p.y - y) / hd * 50.0 * dt, room)
				elif TB.dist_xy(x, y, e.x, e.y) > reach + e.r:
					var d := TB.dist_xy(x, y, e.x, e.y)
					var spd: float = 90.0 if o["k"] == "bones" else 55.0 + 8.0 * size
					_step(o, (e.x - x) / d * spd * dt, (e.y - y) / d * spd * dt, room)
					o["face"] = 1 if e.x > x else -1
				elif o["cd"] <= 0:
					o["cd"] = 0.7 if o["k"] == "bones" else 0.9
					var dm: float = o["dmg"] * (1.0 if o["k"] == "bones" else 0.6 + 0.4 * size)
					if o["k"] == "golem" and size >= 5:
						# A full-grown golem: its punch shakes the floor around it.
						for f in G.enemies.duplicate():
							if f.targetable() and f.charm_t <= 0 and TB.dist_xy(f.x, f.y, x, y) < 26.0 + f.r:
								var c := Combat.damage_enemy(f, dm, { "kx": (f.x - x) * 4.0, "ky": (f.y - y) * 4.0 })
								Combat.on_hit_effects(f, dm, c, p, null)
						G.add_shake(2)
						Afx.dust(x, y)
						_stat("stomp")
					else:
						var c := Combat.damage_enemy(e, dm, {})
						Combat.on_hit_effects(e, dm, c, p, null)
						Afx.cut(e.x, e.y - e.z, TB.ang_xy(x, y, e.x, e.y), false)
						_stat("bones_hit" if o["k"] == "bones" else "golem_hit")
			"imp":
				o["a"] += dt * 2.2
				var to := Vector2(p.x, p.y - 12) + Vector2(cos(o["a"]) * 22.0, sin(o["a"]) * 10.0)
				o["x"] = lerpf(x, to.x, minf(1.0, dt * 6.0))
				o["y"] = lerpf(y, to.y, minf(1.0, dt * 6.0))
				if o["cd"] <= 0:
					var e := Combat.nearest_enemy(o["x"], o["y"], 170)
					if e != null and e.charm_t <= 0:
						o["cd"] = 1.2
						var b := Combat._raw_shot(o["x"], o["y"], TB.ang_xy(o["x"], o["y"], e.x, e.y), 200, o["dmg"] * 0.8, 1.0, 3.0, 0, "hex", {})
						b.tag = "pyre"
						o["face"] = 1 if e.x > x else -1
						_stat("fireball")
			"wolf":
				var e: Enemy = o["e"].get_ref() if o["e"] != null else null
				if e == null or e.hp <= 0 or e.charm_t > 0:
					e = Combat.nearest_enemy(x, y, 200)
					o["e"] = weakref(e) if e != null else null
				var a: float = o["a"]
				if e != null:
					a = TB.ang_xy(x, y, e.x, e.y)
					o["a"] = a
				_step(o, cos(a) * 190.0 * dt, sin(a) * 190.0 * dt, room)
				o["face"] = 1 if cos(a) >= 0 else -1
				var bit := false
				for f in G.enemies:
					if f.targetable() and f.charm_t <= 0 and TB.dist_xy(f.x, f.y, o["x"], o["y"]) < f.r + 6.0:
						var c := Combat.damage_enemy(f, o["dmg"], {})
						Combat.on_hit_effects(f, o["dmg"], c, p, null)
						Statuses.apply(f, "bleed", 1, o["dmg"])
						Afx.cut(f.x, f.y - f.z, a, false)
						_stat("bite")
						bit = true
						break
				if bit:
					Vfx.puff(o["x"], o["y"], "void")
					continue
			"mimic":
				if o["hop"] > 0:
					o["hop"] -= dt
					# It lands where its foe is now, not where it was (a fast foe would always get away).
					var f0: Enemy = o["e"].get_ref() if o.get("e") != null else null
					if f0 != null and f0.hp > 0:
						o["tx"] = f0.x
						o["ty"] = f0.y
					var k := 1.0 - maxf(0.0, o["hop"]) / 0.35
					o["x"] = lerpf(o["x0"], o["tx"], k)
					o["y"] = lerpf(o["y0"], o["ty"], k)
					o["z"] = sin(k * PI) * 16.0
					o["face"] = 1 if o["tx"] > o["x0"] else -1
					if o["hop"] <= 0:
						o["z"] = 0.0
						for f in G.enemies.duplicate():
							if f.targetable() and f.charm_t <= 0 and TB.dist_xy(f.x, f.y, o["x"], o["y"]) < f.r + 10.0:
								var c := Combat.damage_enemy(f, o["dmg"], { "force_crit": o.get("crit", false) })
								Combat.on_hit_effects(f, o["dmg"], c, p, null)
								_stat("chomp")
								if f.hp <= 0:
									Combat.drop_pickup("coin", f.x, f.y)
									_stat("mimic_coin")
						Snd.play("hit")
				else:
					var hd := TB.dist_xy(x, y, p.x - 12.0 * p.face, p.y)
					if hd > 6.0:
						_step(o, (p.x - 12.0 * p.face - x) / hd * minf(hd * 4.0, 90.0) * dt, (p.y - y) / hd * minf(hd * 4.0, 90.0) * dt, room)
		keep.append(o)
	thralls = keep

static func _tick_leaps(p: Player, dt: float) -> void:
	var keep := []
	for o in leaps:
		o["t"] += dt
		if o["t"] < o["dur"]:
			# In the air it follows its foe.
			var e: Enemy = o["e"].get_ref() if o["e"] != null else null
			if e != null and e.hp > 0:
				o["x1"] = e.x
				o["y1"] = e.y
			keep.append(o)
			continue
		if o["k"] == "bite":
			var e := Combat.nearest_enemy(o["x1"], o["y1"], 14)
			if e != null and e.charm_t <= 0:
				var c := Combat.damage_enemy(e, o["dmg"], {})
				Combat.on_hit_effects(e, o["dmg"], c, p, null)
				Statuses.apply(e, "bleed", 1, o["dmg"])
				Afx.cut(e.x, e.y - e.z, 0.0, true)
				_stat("pet_bite")
			Vfx.puff(o["x1"], o["y1"], "void")
			continue
		# Landed, the sheep waddles at the nearest foe a moment, then blows.
		o["sit"] -= dt
		if o["sit"] > 0:
			if o["spr"] == "s_sheep" and absf(o["sit"] - 0.5) < dt:
				Fx.float_text(o["x1"], o["y1"] - 14, "BAA", "white")
			var f := Combat.nearest_enemy(o["x1"], o["y1"], 80)
			if f != null and f.charm_t <= 0:
				var d := TB.dist_xy(o["x1"], o["y1"], f.x, f.y)
				if d > 2.0:
					var st := minf(d, 90.0 * dt)
					o["x1"] += (f.x - o["x1"]) / d * st
					o["y1"] += (f.y - o["y1"]) / d * st
			keep.append(o)
			continue
		Arsenal.blast(o["x1"], o["y1"], o["dmg"], o["rad"], "#f4ecd8")
		_stat("sheep_blow")
	leaps = keep

static func _tick_echoes(p: Player, dt: float) -> void:
	var keep := []
	for m in echoes:
		m["t"] -= dt
		if m["t"] > 0:
			keep.append(m)
			continue
		# The shadow reaches a little further (the foes may have been knocked back since).
		var at: Vector2 = trail[0] if not trail.is_empty() else Vector2(p.x, p.y)
		var e := Combat.nearest_enemy(at.x, at.y, Weapons.wrange(p) + 40.0)
		var a := TB.ang_xy(at.x, at.y, e.x, e.y) if e != null else p.aim_a
		var hits := _cut_at(p, at.x, at.y, a, Weapons.wrange(p) + 12.0, deg_to_rad(p.weapon.get("arc", 110)), m["dmg"], m["crit"], p.weapon)
		if hits > 0:
			_stat("shadow_cut", hits)
	echoes = keep

## A cut from a point (the hero, or his shadow): every foe in reach and in the arc.
static func _cut_at(p: Player, x: float, y: float, a: float, reach: float, arc: float, dmg: float, crit: bool, w: Dictionary,
		kb := 30.0) -> int:
	var hits := 0
	for e in G.enemies.duplicate():
		if not e.targetable() or e.charm_t > 0 or TB.dist_xy(e.x, e.y, x, y) - e.r > reach:
			continue
		if absf(TB.wrap_ang(TB.ang_xy(x, y, e.x, e.y) - a)) > arc / 2:
			continue
		var ka := TB.ang_xy(x, y, e.x, e.y)
		var c := Combat.damage_enemy(e, dmg, { "force_crit": crit, "kx": cos(ka) * kb, "ky": sin(ka) * kb })
		Combat.on_hit_effects(e, dmg, c, p, null)
		Afx.cut(e.x, e.y - e.z, ka, false)
		hits += 1
	G.swings.append({ "kind": "slash", "x": x, "y": y - 2, "a": a, "r": reach, "arc": arc, "t": 0.14, "max": 0.14,
		"tag": w["tags"][0] if w["tags"].size() > 0 else "" })
	return hits

static func _tick_swarms(p: Player, dt: float) -> void:
	var keep := []
	var on := {}   # fireflies on each foe (three flare)
	for s in swarms:
		var e: Enemy = s["e"].get_ref() if s.get("e") != null else null
		if e != null and (e.hp <= 0 or not e.targetable() or e.charm_t > 0):
			e = null
		if s["k"] == "bats":
			if e == null:
				e = Combat.nearest_enemy(s["x"], s["y"], 200)
				s["e"] = weakref(e) if e != null else null
			var to := Vector2(e.x, e.y - 4) if e != null else Vector2(p.x, p.y - 14)
			var d := TB.dist_xy(s["x"], s["y"], to.x, to.y)
			if d > 1.0:
				var st := minf(d, 120.0 * dt)
				s["x"] += (to.x - s["x"]) / d * st
				s["y"] += (to.y - s["y"]) / d * st
			s["idle"] += dt
			if s["idle"] > 3.0:
				s["idle"] = 2.0
				s["n"] -= 1   # unfed, the cloud thins out
			if s["n"] <= 0:
				continue
			s["hit"] -= dt
			if s["hit"] <= 0:
				s["hit"] = 0.3
				var rr: float = 8.0 + s["n"]
				var dm: float = Weapons.wdmg(p) * 0.06 * s["n"] * s.get("more", 1.0)
				for f in G.enemies.duplicate():
					if f.targetable() and f.charm_t <= 0 and TB.dist_xy(f.x, f.y, s["x"], s["y"]) < rr + f.r:
						var c := Combat.damage_enemy(f, dm, { "silent": true })
						Combat.on_hit_effects(f, dm, c, p, null)
						_stat("bat_bite")
			keep.append(s)
		else:
			s["t"] -= dt
			if s["t"] <= 0:
				continue
			if e == null:
				e = Combat.nearest_enemy(s["x"], s["y"], 160)
				s["e"] = weakref(e) if e != null else null
				if e == null:
					keep.append(s)
					continue
			s["a"] += dt * 5.0
			var to := Vector2(e.x, e.y - 6) + Vector2(cos(s["a"]), sin(s["a"]) * 0.6) * 10.0
			s["x"] = lerpf(s["x"], to.x, minf(1.0, dt * 8.0))
			s["y"] = lerpf(s["y"], to.y, minf(1.0, dt * 8.0))
			s["hit"] -= dt
			if s["hit"] <= 0:
				s["hit"] = 0.5
				var c := Combat.damage_enemy(e, s["dmg"] * 0.4, { "silent": true })
				Combat.on_hit_effects(e, s["dmg"] * 0.4, c, p, null)
				Statuses.apply(e, "burn", 1, s["dmg"])
				_stat("fly_burn")
			if not on.has(e.uid):
				on[e.uid] = []
			on[e.uid].append(s)
			keep.append(s)
	# Three fireflies on one foe flare up in a blast, and are spent.
	for uid in on:
		var group: Array = on[uid]
		if group.size() >= 3:
			var e: Enemy = group[0]["e"].get_ref()
			if e != null:
				Arsenal.blast(e.x, e.y, group[0]["dmg"] * 3.0, 30.0, "#f2c94c")
				_stat("flare")
			for i in 3:
				keep.erase(group[i])
	swarms = keep

static func _tick_dragon(p: Player, dt: float) -> void:
	var to := Vector2(p.x - 14.0 * p.face, p.y - 14.0 + sin(G.time * 4.0) * 2.0)
	dragon["x"] = lerpf(dragon["x"], to.x, minf(1.0, dt * 5.0))
	dragon["y"] = lerpf(dragon["y"], to.y, minf(1.0, dt * 5.0))
	dragon["cd"] -= dt
	if dragon["cd"] > 0:
		return
	var e := Combat.nearest_enemy(dragon["x"], dragon["y"], 110)
	if e == null or e.charm_t > 0:
		return
	dragon["cd"] = 1.4
	var a := TB.ang_xy(dragon["x"], dragon["y"], e.x, e.y)
	dragon["face"] = 1 if cos(a) >= 0 else -1
	var n := Weapons.wcount(p)
	var dm := Weapons.wdmg(p) * 0.6 * (1.0 + 0.35 * (n - 1))
	for i in 5:
		Combat._raw_shot(dragon["x"] + cos(a) * 5, dragon["y"] + sin(a) * 5, a + (i - 2) * 0.12, 150, dm, 0.5, 2.5, 1, "fire", {})
	_stat("breath")
	Snd.play("shoot")

# ---------- Drawing ----------
## On the floor (world_view, after charged.gd's): turrets and traps, countdown bombs, frost rings.
static func draw_floor(ci: CanvasItem, t: float) -> void:
	for o in turrets:
		var x := roundf(o["x"])
		var y := roundf(o["y"])
		var c := TB.c(o["col"])
		var fade := 1.0 if o["t"] > 2.0 or floori(t * 10) % 2 == 0 else 0.4
		ci.draw_circle(Vector2(x, y + 1), 5.0, Color(0, 0, 0, 0.3 * fade))
		match o["k"]:
			"saw":
				ci.draw_circle(Vector2(x, y), 5.0, TB.c("#140f1c"))
				ci.draw_circle(Vector2(x, y), 4.0, Color(0.55, 0.56, 0.61, fade))
				for i in 4:
					var q := Vector2(x, y) + Vector2.from_angle(t * 18.0 + i * PI / 2) * 4.0
					ci.draw_rect(Rect2(roundf(q.x), roundf(q.y), 1, 1), TB.c("#f4ecd8"))
			"gun", "flame":
				ci.draw_rect(Rect2(x - 3, y - 3, 6, 4), TB.c("#140f1c"))
				ci.draw_rect(Rect2(x - 2, y - 2, 4, 2), TB.c("#4e4a5e"))
				var head := Vector2(x, y - 5)
				ci.draw_line(head, head + Vector2.from_angle(o["a"]) * 5.0, TB.c("#140f1c"), 2.0)
				ci.draw_circle(head, 2.5, TB.c("#140f1c"))
				ci.draw_circle(head, 1.8, Color(c.r, c.g, c.b, fade))
			"tesla":
				ci.draw_rect(Rect2(x - 2, y - 11, 4, 12), TB.c("#140f1c"))
				for i in 4:
					ci.draw_rect(Rect2(x - 2 + (i % 2), y - 10 + i * 3, 3, 1), TB.c("#c9a46a"))
				ci.draw_circle(Vector2(x, y - 11), 2.0, Color(0.43, 0.83, 0.88, fade))
			"frost":
				var pts := PackedVector2Array([Vector2(x, y - 12), Vector2(x + 3, y - 7), Vector2(x, y - 2), Vector2(x - 3, y - 7)])
				ci.draw_colored_polygon(pts, Color(0.78, 0.94, 1.0, fade))
				ci.draw_polyline(pts + PackedVector2Array([pts[0]]), TB.c("#140f1c"), 1.0)
			"mend":
				ci.draw_rect(Rect2(x - 1, y - 12, 3, 13), TB.c("#140f1c"))
				ci.draw_rect(Rect2(x, y - 11, 1, 11), TB.c("#7a5236"))
				ci.draw_rect(Rect2(x - 3, y - 13, 7, 3), Color(0.72, 0.88, 0.35, fade))
				ci.draw_rect(Rect2(x - 1, y - 15, 3, 7), Color(0.72, 0.88, 0.35, fade))
	var coils := turrets.filter(func(o): return o["k"] == "tesla")
	if coils.size() >= 2:
		var a := Vector2(coils[0]["x"], coils[0]["y"] - 11)
		var b := Vector2(coils[1]["x"], coils[1]["y"] - 11)
		var wob := Vector2(0, sin(t * 30.0))
		ci.draw_line(a, b + wob, Color(0.43, 0.83, 0.88, 0.7), 1.0)
		ci.draw_line(a + wob, b, Color(1, 1, 1, 0.5), 1.0)
	for b in bombs:
		var x := roundf(b["x"])
		var y := roundf(b["y"])
		ci.draw_circle(Vector2(x, y), 5.0, TB.c("#140f1c"))
		ci.draw_circle(Vector2(x - 1, y - 1), 1.5, TB.c("#4e4a5e"))
		if floori(t * 8) % 2 == 0:
			ci.draw_rect(Rect2(x + 2, y - 7, 2, 2), TB.c("#f2c94c"))
		Gfx.text(ci, str(maxi(1, b["left"])), x, y - 16, "red", 1, 0.5)
	for f in flashes:
		if f["k"] == "ring":
			var k: float = f["t"] / f["max"]
			ci.draw_arc(Vector2(f["x0"], f["y0"]), f["x1"] * (1.0 - 0.5 * k), 0.0, TAU, 32, Color(0.78, 0.94, 1.0, k), 1.0)

## Over everyone (world_view, after charged.gd's): cards, summons, images, the shadow, swarms, the
## egg and the dragon, zaps, and the hand over the hero.
static func draw_over(ci: CanvasItem, t: float) -> void:
	var p := G.player
	if p == null or p.weapon == null:
		return
	for c in cards:
		var x := roundf(c["x"])
		var y := roundf(c["y"])
		var tilt := sin(t * 20.0 + x) * 0.4
		ci.draw_set_transform(Vector2(x, y), tilt, Vector2.ONE)
		ci.draw_rect(Rect2(-3, -4, 6, 8), TB.c("#140f1c"))
		ci.draw_rect(Rect2(-2, -3, 4, 6), TB.c("#f4ecd8"))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for o in thralls:
		var x: float = o["x"]
		var y: float = o["y"]
		match o["k"]:
			"bones":
				var rise: float = o.get("rise", 0.0)
				Gfx.sp(ci, "s_bones", x, y + 6, 1.0, 1.0 - rise, 0.0, o["face"] < 0, 0.85, Color(0.55, 1.0, 0.6, 1))
			"golem":
				var z: float = 0.6 + 0.12 * o["size"]
				Gfx.sp(ci, "s_golem", x, y + 6, z, z, 0.0, o["face"] < 0)
			"imp":
				Gfx.sp(ci, "s_imp", x, y + 4 + sin(t * 9.0 + x) * 1.0, 1.0, 1.0, 0.0, o["face"] < 0)
			"wolf":
				Gfx.sp(ci, "s_wolf", x, y + 4, 1.0, 1.0, 0.0, o["face"] < 0, 0.75, Color(0.78, 0.94, 1.0, 1))
			"mimic":
				var z: float = o.get("z", 0.0)
				ci.draw_circle(Vector2(x, y + 2), 4.0, Color(0, 0, 0, 0.3))
				Gfx.sp(ci, "s_mimic", x, y + 5 - z, 1.0, 1.0, 0.0, o["face"] < 0)
	for o in leaps:
		var k := clampf(o["t"] / o["dur"], 0.0, 1.0)
		var x: float = lerpf(o["x0"], o["x1"], k)
		var y: float = lerpf(o["y0"], o["y1"], k) - sin(k * PI) * (14.0 if o["k"] == "bite" else 30.0)
		var spirit: bool = o["spr"] != "s_sheep"
		if spirit:
			Gfx.sp(ci, o["spr"], x, y + 6, 1.0, 1.0, 0.0, o["x1"] < o["x0"], 0.75, Color(0.78, 0.94, 1.0, 1))
		else:
			Gfx.sp(ci, o["spr"], x, y + 6, 1.0, 1.0, 0.0, o["x1"] < o["x0"])
	var hero_spr: String = p.hero["sprite"]
	for im in images:
		Gfx.sp(ci, hero_spr, im["x"], im["y"] + 6, 1.0, 1.0, 0.0, im["face"] < 0, 0.45 if im["t"] > 1.0 or floori(t * 10) % 2 == 0 else 0.2,
			Color(0.43, 0.83, 0.88, 1))
	if p.weapon.get("mirror", "") == "shadow" and not trail.is_empty():
		var at: Vector2 = trail[0]
		Gfx.sp(ci, hero_spr, at.x, at.y + 6, 1.0, 1.0, 0.0, p.face < 0, 0.6, Color(0.64, 0.36, 0.84, 1))
	for s in swarms:
		if s["k"] == "bats":
			for i in int(s["n"]):
				var a := i * 2.39996 + t * (5.0 + i % 3)
				var rr := 3.0 + (i * 7) % (6 + int(s["n"]))
				var q := Vector2(s["x"] + cos(a) * rr, s["y"] + sin(a) * rr * 0.6)
				var flap := floori(t * 16.0 + i) % 2 == 0
				ci.draw_rect(Rect2(roundf(q.x) - 1, roundf(q.y), 3, 1), TB.c("#3c1d47"))
				ci.draw_rect(Rect2(roundf(q.x) - (2 if flap else 1), roundf(q.y) - (1 if flap else 0), 1, 1), TB.c("#7a3a8c"))
				ci.draw_rect(Rect2(roundf(q.x) + (2 if flap else 1), roundf(q.y) - (1 if flap else 0), 1, 1), TB.c("#7a3a8c"))
		else:
			var glow := 0.5 + 0.5 * sin(t * 12.0 + s["a"])
			ci.draw_circle(Vector2(s["x"], s["y"]), 2.0, Color(0.95, 0.9, 0.3, 0.25 * glow))
			ci.draw_rect(Rect2(roundf(s["x"]), roundf(s["y"]), 1, 1), TB.c("#fffbe0"))
	if p.weapon["kind"] == "egg":
		if dragon.is_empty():
			var ex := roundf(p.x + 9.0 * -p.face)
			var ey := roundf(p.y - 2 + sin(t * 3.0))
			Gfx.sp(ci, "s_egg", ex, ey + 4, 1.0, 1.0, sin(t * 20.0) * 0.08 * warmth / HATCH)
			var k := float(warmth) / HATCH
			ci.draw_rect(Rect2(ex - 3, ey + 6, 6, 1), TB.c("#140f1c"))
			ci.draw_rect(Rect2(ex - 3, ey + 6, roundf(6 * k), 1), TB.c("#e8873a"))
		else:
			Gfx.sp(ci, "s_dragon", dragon["x"], dragon["y"] + 5, 1.0, 1.0, 0.0, dragon["face"] < 0)
	for f in flashes:
		if f["k"] != "zap":
			continue
		var k: float = f["t"] / f["max"]
		var c := TB.c(f["col"])
		var a := Vector2(f["x0"], f["y0"])
		var b := Vector2(f["x1"], f["y1"])
		var prev := a
		for j in range(1, 5):
			var q := a.lerp(b, j / 4.0) + (Vector2(sin(j * 7.3 + f["x0"]), cos(j * 5.1 + f["y1"])) * 3.0 if j < 4 else Vector2.ZERO)
			ci.draw_line(prev, q, Color(c.r, c.g, c.b, k), 1.0)
			prev = q
	if p.weapon["kind"] == "deck":
		# The hand: the next three cards, over the hero's head (the first one raised).
		var y0 := roundf(p.y) - 30
		if shuffle_t > 0:
			for i in 3:
				var x := roundf(p.x) - 9 + i * 6 + roundf(sin(t * 30.0 + i) * 2.0)
				ci.draw_rect(Rect2(x, y0, 5, 7), TB.c("#140f1c"))
				ci.draw_rect(Rect2(x + 1, y0 + 1, 3, 5), TB.c("#4e4a5e"))
		else:
			for i in mini(3, draw.size()):
				var c: Dictionary = draw[i]
				var x := roundf(p.x) - 9 + i * 6
				var y := y0 - (1 if i == 0 else 0)
				ci.draw_rect(Rect2(x - 1, y - 1, 7, 9), TB.c("#140f1c"))
				ci.draw_rect(Rect2(x, y, 5, 7), TB.c("#2b2238") if c["up"] == 0 else TB.c("#5c4a1a"))
				var info: Array = CARDS.get(c["id"], ["?", "white"])
				Gfx.text(ci, info[0], x + 1, y + 1, info[1], 1, 0.0, false)
			if doubled > 0:
				Gfx.text(ci, "X2", roundf(p.x) + 11, y0, "cyan", 1, 0.0)
