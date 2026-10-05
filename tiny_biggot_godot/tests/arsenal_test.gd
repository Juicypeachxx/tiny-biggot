extends Node
## The hundred new weapons (ROADMAP 4.6; scripts/combat/arsenal.gd). Run:
##   godot --headless --path . res://tests/arsenal_test.tscn -- --no-save
##   1. Data: every new weapon has an icon, a name and a text the font can draw, a kind with a
##      name, a picture word and a damage type; no name is used twice; none is in the original game.
##   2. Each one in a fight (the hero firing by himself at sturdy foes): it hurts them, and its own
##      trick happens (shrapnel, hops, seeds, a freeze, crumbs, a backblast, a star of sparks, a
##      guided flight, missiles hunting, a lock-on, sticking, a remote set-off, shells landing, snow,
##      mice, a line of bombs, a pillar, chained dynamite, a wall slam, wall shards, planted
##      charges, puppets, the pig).
##   3. +1 projectile without limit: with 999 more projectiles each one stays within the caps (live
##      objects, player shots), its logic time stays low (desktop numbers, printed), and it hurts
##      more than with none.
##   4. Rolling sets off the sticky jar's bombs; limpets wait for every 4th throw.
##   5. Part 2 (charged.gd): with an aim button held a charge waits at full and goes where the aim
##      was when you let go; a roll draws the swiftdraw bow fully at once; the chain glaive's chain
##      breaks on a miss; the javelin dash takes the javelin back; the anchor chain drags its foe
##      through another.
## Prints "arsenal test: PASSED" or a FAIL line per problem.

## Part 1 (MAYHEM): weapon id -> the trick (Arsenal.stats key) that shows it works.
const PART1 := { "pineapple": "shrapnel", "skipcharge": "skip", "pomegranate": "seed", "hoarfrost": "freeze",
	"fruitcake": "crumbs", "bottlerockets": "blast", "alleyrpg": "backblast", "festival": "star", "pathfinder": "guided",
	"swarmpod": "hunt", "lockon": "lock", "stickyjar": "stick", "limpets": "remote", "pocketmortar": "shell",
	"snowglobe": "snow", "clockmice": "mouse", "keg": "blast", "signalflare": "bomb", "skyhammer": "pillar",
	"dynamite": "chain", "repulsor": "slam", "shrapnelgun": "shard", "blastknuckles": "plant", "parasite": "puppet",
	"piggybank": "pig" }
## Part 2 (CHARGE AND COMBO): weapon id -> the trick (Charged.stats key).
const PART2 := { "plasmaslug": "full_hit", "shatterball": "shard", "gravityglobe": "pull", "swiftdraw": "draw_crit",
	"chokeshotgun": "choke_full", "coldstar": "freeze", "quakemaul": "ring_hit", "emberquake": "fire_ring",
	"aftershock": "aftershock", "dashblade": "dash_cut", "cometlance": "dash_blast", "phantomedge": "phantom_cut",
	"warjavelin": "follow", "thunderpike": "rod_zap", "grapple": "punch", "anchorchain": "pull_foe",
	"cutlass": "finisher_crit", "chainglaive": "step_spin", "flarefist": "step_upper", "steamrepeater": "vent",
	"reactorrifle": "hot_shot", "deadeye": "kill_reload", "magdump": "mag_throw", "starcaller": "launch",
	"snapback": "recall_hit" }
## Where the foes stand for a kind: close (fists, blades, combos), near (a slam's ring), else farther.
const CLOSE := ["slash", "thrust", "whip", "combo"]
const NEAR := ["slam"]
## Kinds that move the hero (dashes): the test does not hold him in place.
const FREE := ["dash", "javelin", "hook"]

var fails := 0
var notes := []

func fail(msg: String) -> void:
	fails += 1
	print("FAIL arsenal: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(5)
	Meta.opts["autofire"] = true
	_data()
	var only := DebugArgs.get_str("ids")   # --ids=a,b: only these weapons (any weapon, to compare with)
	for id in (Array(only.split(",")) if only != "" else PART1.keys() + PART2.keys()):
		_fight(id, PART1.get(id, PART2.get(id, "")))
	if only == "":
		_rolling()
		_charging()
	for n in notes:
		print("[arsenal] ", n)
	print("arsenal test: PASSED" if fails == 0 else "arsenal test: %d FAILED" % fails)
	get_tree().quit()

func _data() -> void:
	var names := {}
	for t in [Relics.all(), Gear.all(), Traits.all()]:
		for it in t:
			names[String(it["name"])] = "item"
	var seen := {}
	var ids := {}
	for row in Weapons.ROWS:
		if ids.has(row[0]):
			fail("two weapons with the id %s" % row[0])
		ids[row[0]] = true
	for w in Weapons.all():
		if seen.has(w["name"]):
			fail("two weapons named %s" % w["name"])
		seen[w["name"]] = true
	for id in PART1.keys() + PART2.keys():
		if not Weapons._by_id.has(id):
			fail("no weapon " + id)
			continue
		var w := Weapons.by_id(id)
		if Weapons.ROWS.map(func(r): return r[0]).find(id) < Weapons.ORIGINAL_COUNT:
			fail(id + " sits among the original weapons")
		if not Img.has(w["sprite"]):
			fail(id + ": no icon " + w["sprite"])
		if not Weapons.ARCH.has(w["kind"]) or not Weapons.ARCH_DESC.has(w["kind"]) or not WeaponInfo.KIND_TYPE.has(w["kind"]):
			fail(id + ": kind %s lacks a name, a picture word or a damage type" % w["kind"])
		if names.has(w["name"]):
			fail(id + " is named like an item: " + w["name"])
		for s in [w["name"], w["desc"], Weapons.ARCH[w["kind"]]["name"], Weapons.ARCH_DESC[w["kind"]]]:
			for ch in String(s):
				if not ch in Gfx.FONT_CHARS:
					fail("%s: '%s' is not in the font" % [id, ch])
					break

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

## Four sturdy foes: in front of the hero (close for a fist or a blade, near for a slam), or by the
## left wall.
func _foes(p: Player, near_wall: bool, close := false, near := false) -> Array:
	var out := []
	for i in 4:
		var x := (2.4 + i * 0.25) * TB.TS if near_wall else p.x - 60.0 + i * 40.0
		var y := p.y - 30.0 - (i % 2) * 18.0 if near_wall else p.y - 90.0 - (i % 2) * 20.0
		if close:
			x = p.x - 12.0 + i * 8.0
			y = p.y - 16.0
		elif near:
			x = p.x - 40.0 + i * 27.0
			y = p.y - 40.0
		var e := Combat.spawn_enemy("skeleton", x, y, false, true)
		e.speed = 0.0
		e.max_hp = 1e7
		e.hp = 1e7
		out.append(e)
	return out

## n ticks of play; the hero is kept at `hold` (null: he moves by himself, for dashes).
func _tick(n: int, hold: Variant = null, every: Callable = Callable()) -> void:
	for i in n:
		var p := G.player
		p.hp = p.max_hp
		if hold != null:
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
	var p := _start()
	_arena()
	Weapons.equip_weapon(p, Weapons.by_id(id))
	p.count += extra
	var near_wall := id == "repulsor"
	var hold := Vector2(5.0 * TB.TS, 12.0 * TB.TS) if near_wall else Vector2(14.0 * TB.TS, 13.0 * TB.TS)
	p.x = hold.x
	p.y = hold.y
	var kind: String = p.weapon["kind"]
	var foes := _foes(p, near_wall, kind in CLOSE, kind in NEAR)
	var keep: Variant = null if kind in FREE else hold
	var hp0 := 0.0
	for e in foes:
		hp0 += e.hp
	var most_live := 0
	var most_shots := 0
	var total := 0.0
	var worst := 0.0
	var n := int(secs * 60)
	var feed := func(i: int) -> void:
		if id == "piggybank" and i % 60 == 0:
			G.run_stats["gold"] += 12   # gold picked up fills the pig
		if id == "parasite" or id == "dynamite":
			for e in foes:
				e.hp = maxf(e.hp, 1e6)   # keep the targets standing
		if id == "deadeye" and i % 90 == 45:
			# A weak foe now and then: its death reloads the revolver.
			var w := Combat.spawn_enemy("skeleton", G.player.x + 30.0, G.player.y - 50.0, false, true)
			w.speed = 0.0
			w.hp = 1.0
	for i in n:
		var t0 := Time.get_ticks_usec()
		_tick(1, keep, func(_k): feed.call(i))
		var ms := (Time.get_ticks_usec() - t0) / 1000.0
		total += ms
		worst = maxf(worst, ms)
		most_live = maxi(most_live, maxi(Arsenal.live.size(), maxi(Charged.balls.size(), maxi(Charged.rings.size(), Charged.stars.size()))))
		most_shots = maxi(most_shots, G.pbullets.size())
	var dealt := 0.0
	for e in foes:
		dealt += 1e7 - maxf(e.hp, 0.0) if e.hp <= 1e7 else 0.0
	return { "dealt": dealt, "live": most_live, "shots": most_shots, "avg": total / n, "worst": worst }

func _fight(id: String, trick: String) -> void:
	if not Weapons._by_id.has(id):
		return
	Arsenal.stats.clear()
	Charged.stats.clear()
	var a := _run(id, 0, 8.0)
	var seen: Dictionary = Charged.stats if PART2.has(id) else Arsenal.stats
	if a["dealt"] <= 0:
		fail("%s did no damage in 8 s" % id)
	if trick != "" and seen.get(trick, 0) <= 0:
		fail("%s: its trick (%s) never happened; seen %s" % [id, trick, seen])
	var b := _run(id, 999, 8.0)
	var cap := Charged.MAX_BALLS if PART2.has(id) else Arsenal.MAX_LIVE
	if b["live"] > cap:
		fail("%s with 999 more projectiles: %d things alive (cap %d)" % [id, b["live"], cap])
	if b["shots"] > Effects.pbullet_cap() + 64:
		fail("%s with 999 more projectiles: %d shots alive" % [id, b["shots"]])
	if b["avg"] > 4.0:
		fail("%s with 999 more projectiles: %.2f ms a tick" % [id, b["avg"]])
	if id != "parasite" and b["dealt"] <= a["dealt"]:   # (puppets burst: their kills are not a measure)
		fail("%s: 999 more projectiles did not hurt more (%.0f a second against %.0f)" % [id, b["dealt"] / 8.0, a["dealt"] / 8.0])
	notes.append("%s: %.0f damage a second; with 999 more projectiles %.0f, at most %d things and %d shots alive, logic %.2f ms a tick (worst %.1f)" %
		[id, a["dealt"] / 8.0, b["dealt"] / 8.0, b["live"], b["shots"], b["avg"], b["worst"]])

func _rolling() -> void:
	Meta.opts["autofire"] = false   # only the throws made here
	var p := _start()
	_arena()
	Weapons.equip_weapon(p, Weapons.by_id("stickyjar"))
	var hold := Vector2(14.0 * TB.TS, 13.0 * TB.TS)
	p.x = hold.x
	p.y = hold.y
	var foes := _foes(p, false)
	_tick(1, hold)   # (the first tick in a room empties the arsenal's lists)
	Arsenal.fire(p, -PI / 2, false)
	_tick(50, hold)
	var waiting := 0
	for o in Arsenal.live:
		if o["k"] == "sticky" and o["fuse"] > 0.3:
			waiting += 1
	if waiting == 0:
		fail("no sticky bomb waiting to test rolling")
	Combat.on_roll_start(p)
	_tick(10, hold)
	for o in Arsenal.live:
		if o["k"] == "sticky" and o["t"] > 0.6:
			fail("a sticky bomb did not go off when you rolled")
			break
	# Limpets: three throws stick and wait; the 4th is the click that sets them all off.
	p = _start()
	_arena()
	Weapons.equip_weapon(p, Weapons.by_id("limpets"))
	p.x = hold.x
	p.y = hold.y
	foes = _foes(p, false)
	_tick(1, hold)
	Arsenal.throws = 0
	var blasts := 0
	for i in 3:
		Arsenal.stats.clear()
		Arsenal.fire(p, -PI / 2 + (i - 1) * 0.4, false)
		_tick(40, hold)
		blasts += Arsenal.stats.get("blast", 0)
	if blasts > 0:
		fail("limpets blew before the 4th throw")
	var stuck := 0
	for o in Arsenal.live:
		stuck += 1 if o["k"] == "sticky" else 0
	Arsenal.stats.clear()
	Arsenal.fire(p, -PI / 2, false)
	_tick(30, hold)
	if stuck != 3 or Arsenal.stats.get("blast", 0) != 3:
		fail("the 4th throw set off %d of %d limpets" % [Arsenal.stats.get("blast", 0), stuck])
	Meta.opts["autofire"] = true

## Part 2: holding a charge, the bow and a roll, the glaive's chain, the javelin, the anchor chain.
func _charging() -> void:
	Meta.opts["autofire"] = false   # aimed by hand here
	var p := _start()
	_arena()
	var hold := Vector2(14.0 * TB.TS, 13.0 * TB.TS)
	p.x = hold.x
	p.y = hold.y
	var foes := _foes(p, false)
	Weapons.equip_weapon(p, Weapons.by_id("plasmaslug"))
	_tick(1, hold)
	Charged.stats.clear()
	Input.action_press(&"aim_up")
	_tick(120, hold)   # full after 1 s; then it waits for you
	if Charged.level < 1.0 or Charged.stats.get("full_shot", 0) > 0:
		fail("with the aim held, the charge did not wait at full (level %.2f, %s)" % [Charged.level, Charged.stats])
	Input.action_release(&"aim_up")
	_tick(2, hold)
	if Charged.stats.get("full_shot", 0) != 1 or Charged.balls.is_empty():
		fail("letting go of the aim did not fire the full charge (%s)" % Charged.stats)
	elif absf(TB.wrap_ang(Charged.balls[0]["a"] + PI / 2)) > 0.01:
		fail("the charged shot did not go the way the aim was held")
	# The swiftdraw bow: a roll draws it fully at once.
	Weapons.equip_weapon(p, Weapons.by_id("swiftdraw"))
	_tick(2, hold)
	Input.action_press(&"aim_up")
	_tick(10, hold)
	var drawn := Charged.level
	Combat.on_roll_start(p)
	if drawn > 0.3 or Charged.level < 1.0:
		fail("a roll did not draw the swiftdraw bow fully (%.2f before, %.2f after)" % [drawn, Charged.level])
	Input.action_release(&"aim_up")
	_tick(30, hold)
	# The chain glaive: a sweep that misses starts the chain over.
	Weapons.equip_weapon(p, Weapons.by_id("chainglaive"))
	_tick(2, hold)
	Charged.step = 0
	Charged.fire(p, PI / 2, false)   # down, where no foe stands
	if Charged.step != 0:
		fail("the chain glaive's chain went on after a miss")
	Charged.step_t = 0.0
	Charged.fire(p, -PI / 2, false)   # up: the foes stand too far for a sweep, so it misses too
	# The javelin: thrown, it pins; the next attack dashes the hero to it and takes it back.
	p = _start()
	_arena()
	p.x = hold.x
	p.y = hold.y
	foes = _foes(p, false)
	Weapons.equip_weapon(p, Weapons.by_id("warjavelin"))
	_tick(2, hold)
	Charged.fire(p, TB.ang_to(p, foes[1]), false)
	_tick(40, hold)
	if Charged.jav.is_empty() or Charged.jav["state"] == "fly":
		fail("the javelin did not land (%s)" % Charged.jav.get("state", "gone"))
	Charged.fire(p, -PI / 2, false)
	_tick(40)
	if not Charged.jav.is_empty():
		fail("the javelin dash did not take the javelin back (%s)" % Charged.jav.get("state", ""))
	if TB.dist_xy(p.x, p.y, hold.x, hold.y) < 40.0:
		fail("the javelin's second stage did not dash the hero")
	# Training dummies only (the start room): no weapon moves the hero there.
	for id in ["dashblade", "warjavelin"]:
		p = _start()
		_arena()
		p.x = hold.x
		p.y = hold.y
		Combat.spawn_enemy("dummy", p.x, p.y - 60.0, false, true)
		Weapons.equip_weapon(p, Weapons.by_id(id))
		Meta.opts["autofire"] = true
		_tick(240)
		Meta.opts["autofire"] = false
		if TB.dist_xy(p.x, p.y, hold.x, hold.y) > 2.0:
			fail("%s moved the hero in a room of training dummies (%.0f px)" % [id, TB.dist_xy(p.x, p.y, hold.x, hold.y)])
	# The anchor chain: the hooked foe is dragged through one standing by the line.
	p = _start()
	_arena()
	p.x = hold.x
	p.y = hold.y
	Weapons.equip_weapon(p, Weapons.by_id("anchorchain"))
	var far := Combat.spawn_enemy("skeleton", p.x, p.y - 100.0, false, true)
	var by := Combat.spawn_enemy("skeleton", p.x + 12.0, p.y - 50.0, false, true)
	for e in [far, by]:
		e.speed = 0.0
		e.max_hp = 1e6
		e.hp = 1e6
	_tick(2, hold)
	Charged.stats.clear()
	Charged.fire(p, -PI / 2, false)
	_tick(60, hold)
	if Charged.stats.get("drag_hit", 0) < 1 or by.hp >= 1e6:
		fail("the anchor chain did not drag its foe through the other (%s)" % Charged.stats)
	Meta.opts["autofire"] = true
