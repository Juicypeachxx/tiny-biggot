extends Node
## Stage 23 THE SPELLBOOK: the twenty magic weapons (scripts/combat/spells.gd). Run:
##   godot --headless --path . res://tests/spells_test.tscn -- --no-save
##   1. Data: every one has an icon, a name and a text the font can draw, a kind with a name, a
##      picture word, a damage type and the MAGIC type; no name is used twice; none sits among the
##      original weapons (so --classic never sees them).
##   2. Each one in a fight (the hero casting by himself at sturdy foes): it hurts them, and its own
##      trick happens (a collapse, shots eaten, bites, a coil, a comet's burst, a shower, a great
##      rune, a rune twice, cuts, waves, time catching up, shots turned back, splits, a third split,
##      lightning, a tornado, bounces, stars, wild magic, two spells at once).
##   3. +1 projectile without limit: with 999 more projectiles everything stays within its caps, the
##      logic time stays low (desktop numbers, printed), and it hurts more than with none.
##   4. Stopped time: an ordinary foe in the circle stands still and does nothing, then takes the
##      blow; a champion is only slowed.
##   5. Wild magic: a sheep is squashed underfoot; a heal comes at most every 20 s, only when hurt;
##      no gold from the training dummy.
## Prints "spells test: PASSED" or a FAIL line per problem.

## Weapon id -> the trick (Spells.stats key) that shows it works.
const TRICK := { "pocketvoid": "collapse", "eventhorizon": "eat", "emberwyrm": "bite", "rimeserpent": "coil",
	"cometscepter": "comet_burst", "starfallen": "shower", "runechalk": "great", "sundersigil": "sunder",
	"dancingsteel": "slash", "thousandedges": "wave", "stopwatch": "catch_up", "aeonglass": "reverse",
	"kaleidoscope": "split", "fractalcrown": "fractal", "cloudherd": "strike", "tempestcore": "twist",
	"pinballwand": "bounce", "orrery": "star", "wildsurge": "wild", "chaoscodex": "double" }
## Weapons shot at now and then (enemy shots to eat, stop or turn back).
const SHOT_AT := ["eventhorizon", "stopwatch", "aeonglass"]

var fails := 0
var notes := []

func fail(msg: String) -> void:
	fails += 1
	print("FAIL spells: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(23)
	Meta.opts["autofire"] = true
	_data()
	var only := DebugArgs.get_str("ids")   # --ids=a,b: only these weapons
	for id in (Array(only.split(",")) if only != "" else TRICK.keys()):
		_fight(id, TRICK.get(id, ""))
	if only == "":
		_stopped_time()
		_wild()
	for n in notes:
		print("[spells] ", n)
	print("spells test: PASSED" if fails == 0 else "spells test: %d FAILED" % fails)
	get_tree().quit()

func _data() -> void:
	var names := {}
	for t in [Relics.all(), Gear.all(), Traits.all()]:
		for it in t:
			names[String(it["name"])] = "item"
	var seen := {}
	for w in Weapons.all():
		if seen.has(w["name"]):
			fail("two weapons named %s" % w["name"])
		seen[w["name"]] = true
	var kinds := {}
	var ids: Array = Weapons.ROWS.map(func(r): return r[0])
	for id in TRICK:
		if not Weapons._by_id.has(id):
			fail("no weapon " + id)
			continue
		var w := Weapons.by_id(id)
		kinds[w["kind"]] = kinds.get(w["kind"], 0) + 1
		if ids.find(id) < Weapons.ORIGINAL_COUNT:
			fail(id + " sits among the original weapons")
		if not Spells.handles(w["kind"]):
			fail(id + ": kind %s is not a spell" % w["kind"])
		if not Img.has(w["sprite"]) or w["sprite"] != "w_" + id:
			fail(id + ": no icon of its own (" + w["sprite"] + ")")
		if not Weapons.ARCH.has(w["kind"]) or not Weapons.ARCH_DESC.has(w["kind"]) or not WeaponInfo.KIND_TYPE.has(w["kind"]):
			fail(id + ": kind %s lacks a name, a picture word or a damage type" % w["kind"])
		if WeaponInfo.wtype(w) != "MAGIC":
			fail(id + " is not shown as MAGIC")
		if names.has(w["name"]):
			fail(id + " is named like an item: " + w["name"])
		for s in [w["name"], w["desc"], Weapons.ARCH[w["kind"]]["name"], Weapons.ARCH_DESC[w["kind"]]]:
			for ch in String(s):
				if not ch in Gfx.FONT_CHARS:
					fail("%s: '%s' is not in the font" % [id, ch])
					break
	for k in Spells.KINDS:
		if kinds.get(k, 0) != 2:
			fail("kind %s has %d weapons, not two" % [k, kinds.get(k, 0)])
	notes.append("data: %d spell weapons over %d kinds, all with icons, MAGIC, after the originals" % [TRICK.size(), kinds.size()])

func _start() -> Player:
	G.hero_index = 0
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = true
	return G.player

func _arena() -> void:
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	for c in range(TB.IX0, TB.IX0 + TB.IW):
		for r in range(TB.IY0, TB.IY0 + TB.IH):
			G.room.set_tile(c, r, World.T_FLOOR)
	G.locked = true

## Four sturdy foes in front of the hero.
func _foes(p: Player) -> Array:
	var out := []
	for i in 4:
		var e := Combat.spawn_enemy("skeleton", p.x - 60.0 + i * 40.0, p.y - 90.0 - (i % 2) * 20.0, false, true)
		e.speed = 0.0
		e.max_hp = 1e7
		e.hp = 1e7
		out.append(e)
	return out

## n ticks of play with the hero kept at `hold`.
func _tick(n: int, hold: Vector2, every: Callable = Callable()) -> void:
	for i in n:
		var p := G.player
		p.hp = p.max_hp
		p.x = hold.x
		p.y = hold.y
		if every.is_valid():
			every.call(i)
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

## Damage dealt to sturdy foes in `secs`, with `extra` more projectiles; checks the caps and times.
func _run(id: String, extra: int, secs: float) -> Dictionary:
	seed(hash(id) + extra)   # each fight its own luck, whatever the fights before it did
	var p := _start()
	_arena()
	Weapons.equip_weapon(p, Weapons.by_id(id))
	p.count += extra
	var hold := Vector2(14.0 * TB.TS, 13.0 * TB.TS)
	p.x = hold.x
	p.y = hold.y
	var foes := _foes(p)
	var most_live := 0
	var most_shots := 0
	var big := { "blades": 0, "clouds": 0, "serpents": 0, "clocks": 0 }
	var total := 0.0
	var worst := 0.0
	var n := int(secs * 60)
	var feed := func(i: int) -> void:
		if id in SHOT_AT and i % 10 == 0:
			var f: Enemy = foes[(i / 10) % foes.size()]
			Combat.eshot(f.x, f.y, TB.ang_xy(f.x, f.y, G.player.x, G.player.y), 90, "red")
	for i in n:
		var t0 := Time.get_ticks_usec()
		_tick(1, hold, func(_k): feed.call(i))
		var ms := (Time.get_ticks_usec() - t0) / 1000.0
		total += ms
		worst = maxf(worst, ms)
		most_live = maxi(most_live, Spells.live())
		most_shots = maxi(most_shots, G.pbullets.size())
		big["blades"] = maxi(big["blades"], Spells.blades.size())
		big["clouds"] = maxi(big["clouds"], Spells.clouds.size())
		big["serpents"] = maxi(big["serpents"], Spells.serpents.size())
		big["clocks"] = maxi(big["clocks"], Spells.clocks.size())
	var dealt := 0.0
	for e in foes:
		dealt += 1e7 - maxf(e.hp, 0.0) if e.hp <= 1e7 else 0.0
	return { "dealt": dealt, "live": most_live, "shots": most_shots, "avg": total / n, "worst": worst, "big": big }

func _fight(id: String, trick: String) -> void:
	if not Weapons._by_id.has(id):
		return
	Spells.stats.clear()
	var a := _run(id, 0, 8.0)
	var seen := Spells.stats.duplicate()
	if a["dealt"] <= 0:
		fail("%s did no damage in 8 s" % id)
	if trick != "" and seen.get(trick, 0) <= 0:
		fail("%s: its trick (%s) never happened; seen %s" % [id, trick, seen])
	if id == "wildsurge":
		var kinds := 0
		for k in seen:
			if String(k).begins_with("wild_"):
				kinds += 1
		if kinds < 4:
			fail("wild surge cast only %d different spells in 8 s: %s" % [kinds, seen])
	var b := _run(id, 999, 8.0)
	if b["live"] > Spells.MAX_PRISMS:
		fail("%s with 999 more projectiles: %d things alive (cap %d)" % [id, b["live"], Spells.MAX_PRISMS])
	if b["big"]["blades"] > Spells.MAX_BLADES or b["big"]["clouds"] > Spells.MAX_CLOUDS or b["big"]["serpents"] > 8 or b["big"]["clocks"] > 3:
		fail("%s with 999 more projectiles: over a cap %s" % [id, b["big"]])
	if b["shots"] > Effects.pbullet_cap() + 64:
		fail("%s with 999 more projectiles: %d shots alive" % [id, b["shots"]])
	if b["avg"] > 4.0:
		fail("%s with 999 more projectiles: %.2f ms a tick" % [id, b["avg"]])
	if b["dealt"] <= a["dealt"]:
		fail("%s: 999 more projectiles did not hurt more (%.0f a second against %.0f)" % [id, b["dealt"] / 8.0, a["dealt"] / 8.0])
	notes.append("%s: %.0f damage a second; with 999 more projectiles %.0f, at most %d things and %d shots alive, logic %.2f ms a tick (worst %.1f)" %
		[id, a["dealt"] / 8.0, b["dealt"] / 8.0, b["live"], b["shots"], b["avg"], b["worst"]])

## A foe in stopped time does nothing; a champion is only slowed; the held foe takes the blow after.
func _stopped_time() -> void:
	Meta.opts["autofire"] = false   # only the casts made here
	var p := _start()
	_arena()
	Weapons.equip_weapon(p, Weapons.by_id("stopwatch"))
	var hold := Vector2(14.0 * TB.TS, 13.0 * TB.TS)
	p.x = hold.x
	p.y = hold.y
	var e := Combat.spawn_enemy("skeleton", p.x, p.y - 80.0, false, true)
	e.max_hp = 1e7
	e.hp = 1e7
	var c := Combat.spawn_enemy("skeleton", p.x + 24.0, p.y - 80.0, false, true)
	c.d = c.d.duplicate()
	c.d["champion"] = true
	c.max_hp = 1e7
	c.hp = 1e7
	_tick(1, hold)
	Spells.fire(p, -PI / 2, false)
	_tick(1, hold)   # (the clock takes hold on its first tick)
	var x0 := e.x
	var y0 := e.y
	_tick(60, hold)
	if Spells.clocks.is_empty():
		fail("stopped time: no clock was cast")
	if absf(e.x - x0) > 0.5 or absf(e.y - y0) > 0.5:
		fail("a foe in stopped time moved (%.1f, %.1f)" % [e.x - x0, e.y - y0])
	if e.stun_t <= 0.0:
		fail("a foe in stopped time is not held")
	if c.stun_t > 0.0 or c.chill_t <= 0.0:
		fail("a champion in stopped time should only be slowed (stun %.2f, chill %.2f)" % [c.stun_t, c.chill_t])
	_tick(150, hold)
	if not Spells.clocks.is_empty():
		fail("stopped time did not end")
	if e.hp >= 1e7:
		fail("the foe held in stopped time took no blow when time caught up")
	Meta.opts["autofire"] = true
	notes.append("stopped time: a foe held still for a second, a champion only slowed, and the blow when time caught up")

func _wild() -> void:
	Meta.opts["autofire"] = false
	var p := _start()
	_arena()
	Weapons.equip_weapon(p, Weapons.by_id("wildsurge"))
	var hold := Vector2(14.0 * TB.TS, 13.0 * TB.TS)
	p.x = hold.x
	p.y = hold.y
	var f := Combat.spawn_enemy("skeleton", p.x, p.y - 60.0, false, true)
	f.max_hp = 1e5
	f.hp = 1e5
	_tick(1, hold)
	# A sheep: small and harmless, squashed underfoot.
	Spells._wild(p, -PI / 2, "sheep", 6.0, false, 0)
	if not Spells.sheep.has(f.uid) or f.shrink_t <= 0.0:
		fail("wild magic: the foe did not become a sheep")
	_tick(2, Vector2(f.x, f.y))
	if f.hp > 0:
		fail("wild magic: a sheep was not squashed underfoot")
	# A heal: only when hurt, at most every 20 s.
	Spells.heal_t = 0.0
	p.hp = p.max_hp - 2
	Spells._wild(p, -PI / 2, "heal", 6.0, false, 0)
	if p.hp != p.max_hp - 1:
		fail("wild magic: the heal did not heal (%d of %d)" % [p.hp, p.max_hp])
	Spells._wild(p, -PI / 2, "heal", 6.0, false, 0)
	if p.hp != p.max_hp - 1:
		fail("wild magic: two heals in a row")
	# No gold from the training dummy.
	var d := Combat.spawn_enemy("dummy", p.x, p.y - 50.0, false, true)
	var coins := G.pickups.filter(func(k): return k.kind == "coin").size()
	Spells._wild(p, -PI / 2, "gold", 6.0, false, 0)
	if G.pickups.filter(func(k): return k.kind == "coin").size() != coins:
		fail("wild magic: gold from the training dummy")
	d.hp = 0.0
	Meta.opts["autofire"] = true
	notes.append("wild magic: a sheep squashed underfoot, one heal in 20 s and only when hurt, no gold from the dummy")
