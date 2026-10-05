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
##   6. Part 3 (summons.gd): the hand plays in the order shown, and shuffles back; catalyst doubles
##      poison; a countdown bomb waits for three more cards; two tesla coils burn a foe between them;
##      a mending totem heals; kills rise as bone thralls; the egg hatches, and is an egg again (half
##      warm) in the next room; a tamed foe is not aimed at.
##   7. Part 4 (oddities.gd): a shrunk foe is squashed underfoot; the calling card is spent once a
##      foe; yellow paint hastens you; the payday cannon spends a coin a shot (lint when broke); a
##      foe that dies frozen shatters.
##   8. A foe pressed against the hero is hit by the new kinds' own shots (a charged ball, flak, a
##      rocket, a javelin, a letter, a calling card): a soak found crawlers hugging the hero untouched.
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
## Part 3 (DECK AND DEN): weapon id -> the trick (Summons.stats key).
const PART3 := { "duelistdeck": "card_bash", "poisonpack": "catalyst", "shivdeck": "finisher_hit", "countdowndeck": "bomb_blow",
	"echodeck": "doubled", "ascenddeck": "ascend", "sentrykit": "turret_shot", "flamesentry": "flame", "teslapair": "zap",
	"frostbeacon": "frost_pulse", "sawtrap": "saw", "mendtotem": "mend_zap", "gravecaller": "bones_hit", "claygolem": "stomp",
	"implantern": "fireball", "wolfhorn": "bite", "mimicchest": "chomp", "petwhistle": "pet_bite", "shepherdcrook": "sheep_blow",
	"lookingglass": "image_shot", "doppelganger": "shadow_cut", "batcloud": "bat_bite", "fireflyjar": "flare",
	"dragonegg": "hatch", "tamerswhip": "charm_hit" }
## Part 4 (GUNPLAY AND ODDITIES): weapon id -> the trick (Oddities.stats key).
const PART4 := { "typewriter": "word_BOOM", "prophetquill": "word", "bubbleblaster": "pop_bubble", "soapcannon": "soap_pop",
	"flakpistol": "pop", "interceptor": "barrage", "inkgun": "inked", "tricolor": "painted_chill", "slotpistol": "pair",
	"gildedslots": "stake", "snowroller": "ball_hit", "mossboulder": "cover", "paydaycannon": "slug", "flashcamera": "develop",
	"glacierray": "freeze", "junkcannon": "bottle", "fishcannon": "slip", "homerunbat": "billiard", "croquetmallet": "croquet_bounce",
	"backstabdirk": "backstab", "callingcard": "calling", "shrinkray": "shrink", "leafblower": "turned", "aegisprojector": "dome_pop",
	"coinflipper": "ricochet" }
## Kinds shot at now and then (enemy shots to pop, turn round or stop), and kinds given gold.
const SHOT_AT := ["flakpistol", "interceptor", "leafblower", "aegisprojector"]
const GOLD := ["paydaycannon", "gildedslots"]
## Where the foes stand for a kind: close (fists, blades, combos), near (a slam's ring), else farther.
const CLOSE := ["slash", "thrust", "combo", "mirror", "bubble", "bat", "stab"]
const NEAR := ["slam", "turret", "whip", "camera", "blower", "dome"]
## Kinds fed weak foes now and then (their deaths are the trick: a reload, a thrall, a coin).
const FEED := ["deadeye", "gravecaller", "mimicchest"]
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
	for id in (Array(only.split(",")) if only != "" else PART1.keys() + PART2.keys() + PART3.keys() + PART4.keys()):
		_fight(id, PART1.get(id, PART2.get(id, PART3.get(id, PART4.get(id, "")))))
	if only == "":
		_rolling()
		_charging()
		_den()
		_odd()
		_point_blank()
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
	for id in PART1.keys() + PART2.keys() + PART3.keys() + PART4.keys():
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
		if id in SHOT_AT and i % 10 == 0:
			var f: Enemy = foes[(i / 10) % foes.size()]
			Combat.eshot(f.x, f.y, TB.ang_xy(f.x, f.y, G.player.x, G.player.y), 90, "red")
		if id in GOLD and i % 30 == 0:
			G.player.gold = maxi(G.player.gold, 100)
		if id in FEED and i % 90 == 45:
			# A weak foe now and then: its death reloads the revolver, rises as a thrall, drops a coin.
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
		most_live = maxi(most_live, maxi(Summons.turrets.size(), maxi(Summons.thralls.size(), maxi(Summons.swarms.size(), Summons.cards.size()))))
		most_live = maxi(most_live, maxi(Oddities.shots.size(), maxi(Oddities.balls.size(), Oddities.puddles.size())))
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
	Summons.stats.clear()
	Oddities.stats.clear()
	var a := _run(id, 0, 8.0)
	var seen: Dictionary = Charged.stats if PART2.has(id) else (Summons.stats if PART3.has(id) else (Oddities.stats if PART4.has(id) else Arsenal.stats))
	if a["dealt"] <= 0:
		fail("%s did no damage in 8 s" % id)
	if trick != "" and seen.get(trick, 0) <= 0:
		fail("%s: its trick (%s) never happened; seen %s" % [id, trick, seen])
	var b := _run(id, 999, 8.0)
	var cap := Arsenal.MAX_LIVE if PART1.has(id) else (Oddities.MAX_SHOTS if PART4.has(id) else Charged.MAX_BALLS)
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

## Part 3: the deck, catalyst, the countdown, the tesla beam, the totem, thralls, the egg, a tame.
func _den() -> void:
	Meta.opts["autofire"] = false
	var hold := Vector2(14.0 * TB.TS, 13.0 * TB.TS)
	var p := _start()
	_arena()
	p.x = hold.x
	p.y = hold.y
	var foes := _foes(p, false)
	Weapons.equip_weapon(p, Weapons.by_id("duelistdeck"))
	_tick(2, hold)
	Summons.fire(p, -PI / 2, false)   # the first card makes the deck
	var shown: Array = Summons.draw.slice(0, 3).map(func(c): return c["id"])
	for i in 3:
		Summons.fire(p, -PI / 2, false)
	var played: Array = Summons.discard.slice(1, 4).map(func(c): return c["id"])
	if played != shown:
		fail("the deck did not play the hand in the order shown (%s, then %s)" % [shown, played])
	Summons.stats.clear()
	for i in 2:
		Summons.fire(p, -PI / 2, false)
	if Summons.stats.get("shuffle", 0) != 1 or Summons.draw.size() != 6 or not Summons.discard.is_empty():
		fail("the deck did not shuffle back when its pile ran out (%d in the pile)" % Summons.draw.size())
	# Catalyst: the poison on a foe near the target, doubled.
	Weapons.equip_weapon(p, Weapons.by_id("poisonpack"))
	_tick(2, hold)
	for e in foes:
		e.poison = 2.0
	Summons.draw = [{ "id": "catalyst", "up": 0 }, { "id": "strike", "up": 0 }]
	Summons.discard = []
	var target := Summons._aimed(p, -PI / 2)
	Summons.fire(p, -PI / 2, false)
	_tick(25, hold)
	for e in foes:
		var near: bool = TB.dist(e, target) < 60.0 + e.r
		if (near and e.poison < 3.0) or (not near and e.poison > 2.1):
			fail("catalyst: a foe %.0f px from its target has %.1f poison (2 before)" % [TB.dist(e, target), e.poison])
	# The countdown bomb: it blows when three more cards have been played.
	Weapons.equip_weapon(p, Weapons.by_id("countdowndeck"))
	_tick(2, hold)
	Summons.draw = []
	for id in ["bomb", "strike", "strike", "strike", "strike"]:
		Summons.draw.append({ "id": id, "up": 0 })
	Summons.discard = [{ "id": "flurry", "up": 0 }]
	Summons.stats.clear()
	Summons.fire(p, -PI / 2, false)
	_tick(30, hold)
	for i in 2:
		Summons.fire(p, -PI / 2, false)
		_tick(2, hold)
	if Summons.stats.get("bomb_blow", 0) > 0 or Summons.bombs.size() != 1:
		fail("the countdown bomb blew too soon")
	Summons.fire(p, -PI / 2, false)
	_tick(2, hold)
	if Summons.stats.get("bomb_blow", 0) != 1:
		fail("the countdown bomb did not blow after three more cards")
	# Two tesla coils, a foe between them.
	p = _start()
	_arena()
	p.x = hold.x - 40.0
	p.y = hold.y
	Weapons.equip_weapon(p, Weapons.by_id("teslapair"))
	_tick(2)
	Summons.fire(p, 0.0, false)
	p.x = hold.x + 40.0
	Summons.fire(p, 0.0, false)
	var mid := Combat.spawn_enemy("skeleton", hold.x, hold.y - 8.0, false, true)
	mid.speed = 0.0
	mid.hp = 1e6
	mid.max_hp = 1e6
	Summons.stats.clear()
	_tick(30, Vector2(hold.x + 40.0, hold.y))
	if Summons.stats.get("link", 0) < 1:
		fail("two tesla coils did not burn the foe between them (%s)" % Summons.stats)
	# The mending totem: half a heart for 12 s by it.
	p = _start()
	_arena()
	p.x = hold.x
	p.y = hold.y
	Weapons.equip_weapon(p, Weapons.by_id("mendtotem"))
	_tick(2, hold)
	Summons.fire(p, 0.0, false)
	p.hp = p.max_hp - 1
	for i in 60 * 13:
		p.x = hold.x
		p.y = hold.y
		Keys.tick()
		G.update(TB.DT)
	if p.hp != p.max_hp:
		fail("standing by the mending totem for 13 s did not heal (%d of %d)" % [p.hp, p.max_hp])
	# The gravecaller: a kill rises as a bone thrall.
	Weapons.equip_weapon(p, Weapons.by_id("gravecaller"))
	_tick(2, hold)
	var weak := Combat.spawn_enemy("skeleton", p.x + 20.0, p.y, false, true)
	Combat.damage_enemy(weak, 1e9, { "no_crit": true })
	_tick(2, hold)
	if Summons.thralls.filter(func(o): return o["k"] == "bones").size() != 1:
		fail("a kill with the gravecaller did not rise as a thrall")
	# The dragon egg: 15 warms hatch it; in the next room it is an egg again, half warm.
	Weapons.equip_weapon(p, Weapons.by_id("dragonegg"))
	_tick(2, hold)
	Summons.warm(14)
	if not Summons.dragon.is_empty():
		fail("the egg hatched before 15 warms")
	Summons.warm(1)
	if Summons.dragon.is_empty():
		fail("15 warms did not hatch the egg")
	_arena()
	_tick(2, hold)
	if not Summons.dragon.is_empty() or Summons.warmth != Summons.HATCH / 2:
		fail("in the next room the dragon is not an egg again, half warm (warmth %d)" % Summons.warmth)
	# A tamed foe is not aimed at.
	p = _start()
	_arena()
	p.x = hold.x
	p.y = hold.y
	var tame := Combat.spawn_enemy("skeleton", p.x + 30.0, p.y, false, true)
	var other := Combat.spawn_enemy("skeleton", p.x + 120.0, p.y, false, true)
	Summons.charm(tame, 8.0)
	if tame.charm_t <= 0 or Combat.auto_target(p, 320) != other:
		fail("a tamed foe is still aimed at (or was not tamed)")
	Meta.opts["autofire"] = true

## Part 4: squashing, the calling card, yellow paint, the payday cannon, a frozen foe shattering.
func _odd() -> void:
	Meta.opts["autofire"] = false
	var hold := Vector2(14.0 * TB.TS, 13.0 * TB.TS)
	var p := _start()
	_arena()
	p.x = hold.x
	p.y = hold.y
	Weapons.equip_weapon(p, Weapons.by_id("shrinkray"))
	_tick(2, hold)
	var small := Combat.spawn_enemy("skeleton", p.x + 30.0, p.y, false, true)
	small.speed = 0.0
	small.shrink_t = 5.0
	Oddities.stats.clear()
	_tick(2, hold)
	if small.hp <= 0:
		fail("a shrunk foe 30 px away was squashed")
	_tick(2, Vector2(small.x, small.y))
	if small.hp > 0 or Oddities.stats.get("squash", 0) != 1:
		fail("walking onto a shrunk foe did not squash it")
	# The calling card: once a foe.
	Weapons.equip_weapon(p, Weapons.by_id("callingcard"))
	_tick(2, hold)
	var duel := Combat.spawn_enemy("skeleton", p.x, p.y - 60.0, false, true)
	duel.speed = 0.0
	duel.max_hp = 1e6
	duel.hp = 1e6
	Oddities.stats.clear()
	for i in 3:
		Oddities.fire(p, -PI / 2, false)
		_tick(20, hold)
	if Oddities.stats.get("calling", 0) != 1:
		fail("the calling card was played %d times on one foe (once)" % Oddities.stats.get("calling", 0))
	# Yellow paint under you: faster.
	Weapons.equip_weapon(p, Weapons.by_id("tricolor"))
	_tick(2, hold)
	p.haste_t = 0.0
	Oddities.puddles.append({ "x": p.x, "y": p.y, "r": 16.0, "t": 5.0, "c": "yellow", "tick": 0.0, "seed": 0.0 })
	_tick(3, hold)
	if p.haste_t <= 0:
		fail("standing in yellow paint did not hasten the hero")
	# The payday cannon: a coin a shot; broke, lint.
	Weapons.equip_weapon(p, Weapons.by_id("paydaycannon"))
	_tick(2, hold)
	p.gold = 2
	Oddities.stats.clear()
	for i in 3:
		Oddities.fire(p, -PI / 2, false)
	if p.gold != 0 or Oddities.stats.get("slug", 0) != 2 or Oddities.stats.get("lint", 0) != 1:
		fail("the payday cannon: %d gold left, %s" % [p.gold, Oddities.stats])
	# The glacier ray: a foe that dies frozen shatters.
	Weapons.equip_weapon(p, Weapons.by_id("glacierray"))
	_tick(2, hold)
	var ice := Combat.spawn_enemy("skeleton", p.x + 40.0, p.y, false, true)
	Oddities.frozen[ice.uid] = 2.0
	Oddities.stats.clear()
	Combat.damage_enemy(ice, 1e9, { "no_crit": true })
	_tick(2, hold)
	if Oddities.stats.get("shatter", 0) != 1:
		fail("a foe that died frozen did not shatter")
	Meta.opts["autofire"] = true

## Shots that start a little way out still hit a foe pressed against the hero.
func _point_blank() -> void:
	Meta.opts["autofire"] = false
	for id in ["plasmaslug", "flakpistol", "alleyrpg", "warjavelin", "typewriter", "callingcard"]:
		var p := _start()
		_arena()
		var hold := Vector2(14.0 * TB.TS, 13.0 * TB.TS)
		p.x = hold.x
		p.y = hold.y
		Weapons.equip_weapon(p, Weapons.by_id(id))
		_tick(2, hold)
		var hug := Combat.spawn_enemy("skeleton", p.x + 1.0, p.y - 1.0, false, true)
		hug.speed = 0.0
		hug.max_hp = 1e6
		hug.hp = 1e6
		_tick(1, hold)
		Combat.player_shoot(p, -PI / 2)
		_tick(10, hold)
		if hug.hp >= 1e6:
			fail("%s: a foe pressed against the hero was not hit" % id)
	Meta.opts["autofire"] = true
