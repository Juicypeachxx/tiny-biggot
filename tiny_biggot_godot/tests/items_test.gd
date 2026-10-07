extends Node
## The forty gear pieces and twenty relics of ROADMAP 4.7. Run:
##   godot --headless --path . res://tests/items_test.tscn -- --no-save
##   1. Data: each one is there, after the original items; it has an icon, and its name and text
##      use only letters the font can draw; no item or weapon id or name is used twice.
##   2. Each one, carried by a hero in the moment it is made for (a hit on a far, close, fresh or
##      last foe, a kill, a hit taken, armor breaking, a dodge, a bomb set, healing at full
##      health, a chest, a purchase, a coin, a potion, a weapon swap, a room cleared without a
##      scratch, entering a room, a level, a new floor, a crowd, a long fight, a roll): what it
##      promises happens (the action runs, and the new ones find something to do).
##   3. The four sets: each 4-piece power works, and stops when a piece comes off.
##   4. The new actions, looked at closely: reflect turns foes' shots round into yours; spread
##      passes every ailment on; consume uses them up for damage; overkill carries on; slowed shots
##      keep their slowness; the bribe purse pays gold for a hit; potions stop at the slots; a turret
##      from an item stays when you enter a room.
## Prints "items test: PASSED" or a FAIL line per problem.

## id -> [moment, what must happen]. "ran:x": action x ran; "did:x": new action x found something
## to do; "sum:x": Summons.stats[x] (an item's turret or skeleton).
const GEAR := {
	"rime_hood": ["hit_far", "ran:status"], "rime_mantle": ["armor_lost", "ran:status_area"],
	"rime_grip": ["kill_chilled", "did:spread"], "rime_bell": ["fight", "sum:item_turret"],
	"blast_goggles": ["bomb", "ran:invuln"], "blast_apron": ["kill", "did:give"], "blast_mitts": ["bomb", "sum:item_turret"],
	"blast_ring": ["clear", "did:give"], "bone_crown": ["kill_elite", "sum:item_raise"], "bone_ribs": ["hurt", "sum:item_raise"],
	"bone_rattle": ["level", "sum:item_raise"], "bone_ring": ["hit_cursed", "did:consume"], "clock_monocle": ["hit", "ran:damage"],
	"clock_coat": ["armor_lost", "sum:item_turret"], "clock_boots": ["roll", "sum:item_turret"], "clock_key": ["fight", "sum:item_turret"],
	"lastriteshood": ["hit_last", "ran:damage"], "polishedcuirass": ["armor_lost", "did:reflect"], "ghoststeps": ["dodge", "ran:buff"],
	"abbotsandals": ["overheal", "ran:armor"], "iceskates": ["roll_crowd", "ran:status_area"], "magpieboots": ["coin", "ran:buff"],
	"unscathedmedal": ["clear", "ran:gold"], "bribepurse": ["guard", "guard"], "treasuremap": ["chest", "did:give"],
	"voodoodoll": ["hurt", "ran:damage"], "leechgloves": ["kill_close", "ran:heal"], "catalystgloves": ["crit", "did:consume"],
	"plaguehand": ["hit_poisoned", "did:spread"], "pickpocketgloves": ["kill", "ran:gold"], "bouncerknuckles": ["hit_close", "ran:push"],
	"saintsmedallion": ["overheal", "ran:nova"], "mirrorpendant": ["dodge", "did:reflect"], "howlertooth": ["crowd", "ran:buff"],
	"houndcollar": ["hit_bleeding", "ran:heal"], "merchantscharm": ["buy", "did:give"], "excessring": ["kill", "did:overkill"],
	"frostbitering": ["crit_chilled", "ran:status"], "returnring": ["swap", "ran:nova"], "kindlingring": ["potion", "ran:status_area"],
}
const RELICS := {
	"frostlantern": ["kill_chilled", "did:slow_shots"], "permafrost": ["hit", "ran:status"], "snowangel": ["dodge", "ran:status_area"],
	"fusebox": ["bomb", "did:give"], "powderhorn": ["bomb", "ran:nova"], "blastshield": ["bomb", "ran:armor"],
	"gravewhistle": ["kill", "sum:item_raise"], "toolbox": ["enter", "sum:item_turret"], "honeycomb": ["heal", "ran:summon"],
	"littlekiln": ["overheal", "ran:status_area"], "furnaceheart": ["kill_burning", "did:spread"], "wyrmscale": ["armor_lost", "ran:nova"],
	"drawholster": ["swap", "ran:buff"], "wishingcoin": ["coin", "ran:chaos"], "philosophersdrop": ["potion", "did:give"],
	"surveyorschart": ["floor", "did:give"], "ripostecharm": ["roll_danger", "did:reflect"], "dominotile": ["kill_elite", "did:overkill"],
	"stampededrum": ["crowd", "ran:area"], "spyglass": ["hit_far", "ran:damage"],
}
## set -> [its four pieces, the moment, what its 4-piece power does].
const SETS := {
	"rimewarden": [["rime_hood", "rime_mantle", "rime_grip", "rime_bell"], "fight_shots", "did:slow_shots"],
	"blastwright": [["blast_goggles", "blast_apron", "blast_mitts", "blast_ring"], "bomb", "ran:pull"],
	"bonecaller": [["bone_crown", "bone_ribs", "bone_rattle", "bone_ring"], "kill", "sum:item_raise"],
	"clockwork": [["clock_monocle", "clock_coat", "clock_boots", "clock_key"], "fight", "sum:item_turret"],
}
const HOLD := Vector2(14.0 * 16, 13.0 * 16)

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL items: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(7)
	_data()
	for id in GEAR:
		_check(id, "gear", GEAR[id][0], GEAR[id][1])
	for id in RELICS:
		_check(id, "relic", RELICS[id][0], RELICS[id][1])
	_sets()
	_actions()
	print("items test: PASSED" if fails == 0 else "items test: %d FAILED" % fails)
	get_tree().quit()

# ---------- 1. Data ----------
func _data() -> void:
	var gear_ids := Gear.ROWS.map(func(r): return r[0])
	var relic_ids := Relics.ROWS.map(func(r): return r[0])
	for id in GEAR:
		var i := gear_ids.find(id)
		if i < 0:
			fail("no gear " + id)
		elif i < Gear.ORIGINAL_COUNT:
			fail(id + " sits among the original gear")
	for id in RELICS:
		var i := relic_ids.find(id)
		if i < 0:
			fail("no relic " + id)
		elif i < Relics.ORIGINAL_COUNT:
			fail(id + " sits among the original relics")
	if GEAR.size() != 40 or RELICS.size() != 20:
		fail("%d gear pieces and %d relics, not 40 and 20" % [GEAR.size(), RELICS.size()])
	var ids := {}
	var names := {}
	for t in [["gear", Gear.all()], ["relic", Relics.all()], ["weapon", Weapons.all()]]:
		for it in t[1]:
			var mine: bool = GEAR.has(it["id"]) or RELICS.has(it["id"])
			if mine and ids.has(it["id"]):
				fail("the id %s is used twice (%s and %s)" % [it["id"], ids[it["id"]], t[0]])
			if mine and names.has(it["name"]):
				fail("the name %s is used twice (%s and %s)" % [it["name"], names[it["name"]], t[0]])
			ids[it["id"]] = t[0]
			names[it["name"]] = t[0]
	for t in [["gear", GEAR], ["relic", RELICS]]:
		for id in t[1]:
			var it: Dictionary = Gear.by_id(id) if t[0] == "gear" else Relics.by_id(id)
			if not Img.has(it["sprite"]):
				fail(id + ": no icon " + it["sprite"])
			for s in [it["name"], it["desc"]]:
				for ch in String(s):
					if not ch in Gfx.FONT_CHARS:
						fail("%s: '%s' is not in the font" % [id, ch])
						break
	for s in SETS:
		for k in ["d2", "d4", "name"]:
			for ch in String(Gear.SETS[s][k]):
				if not ch in Gfx.FONT_CHARS:
					fail("set %s: '%s' is not in the font" % [s, ch])
					break

# ---------- the arena ----------
func _start() -> Player:
	G.hero_index = 0
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = false
	_arena()
	var p := G.player
	Weapons.equip_weapon(p, Weapons.by_id("repeater"))   # straight bolts that pierce: steady hits
	p.x = HOLD.x
	p.y = HOLD.y
	Meta.opts["autofire"] = false
	return p

func _arena() -> void:
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	for c in range(TB.IX0, TB.IX0 + TB.IW):
		for r in range(TB.IY0, TB.IY0 + TB.IH):
			G.room.set_tile(c, r, World.T_FLOOR)
	G.locked = true

func _sturdy(at: Vector2, elite := false) -> Enemy:
	var e := Combat.spawn_enemy("skeleton", at.x, at.y, elite, true)
	e.speed = 0.0
	e.max_hp = 1e7
	e.hp = 1e7
	return e

## n ticks of play with the hero held in place and kept alive; `every` runs before each tick.
func _tick(n: int, every: Callable = Callable()) -> void:
	for i in n:
		var p := G.player
		p.hp = p.max_hp
		p.x = HOLD.x
		p.y = HOLD.y
		if every.is_valid():
			every.call(i)
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}

func _press(a: StringName, every: Callable = Callable()) -> void:
	Input.action_press(a)
	_tick(1, every)
	Input.action_release(a)
	_tick(1, every)

## Foes' shots in a ring around the hero, drifting outward (for reflect, slow and danger).
func _shots_round(r: float, n: int = 8) -> void:
	var p := G.player
	for k in n:
		var a := k * TAU / n
		Combat.eshot(p.x + cos(a) * r, p.y - 2 + sin(a) * r, a, 15.0, "red")

# ---------- 2. Each item ----------
func _give(p: Player, kind: String, id: String) -> void:
	if kind == "gear":
		Gear.equip_gear(p, Gear.by_id(id))
	else:
		G.add_relic(p, Relics.by_id(id))

func _check(id: String, kind: String, moment: String, want: String) -> void:
	Actions.ran.clear()
	Actions.did.clear()
	Summons.stats.clear()
	seed(id.hash())   # each item's fight is the same whatever runs before it
	var p := _start()
	_give(p, kind, id)
	_tick(1)
	var ok := _moment(p, moment, want)
	if not ok:
		fail("%s (%s): %s did not happen when %s; ran %s, did %s, summons %s" % [id, kind, want, moment, Actions.ran, Actions.did, Summons.stats])

func _seen(want: String) -> bool:
	var w := want.split(":")
	match w[0]:
		"ran": return Actions.ran.get(w[1], 0) > 0
		"did": return Actions.did.get(w[1], 0) > 0
		"sum": return Summons.stats.get(w[1], 0) > 0
	return false

## Plays out the moment; true when `want` happened.
func _moment(p: Player, m: String, want: String) -> bool:
	match m:
		"hit", "hit_far", "hit_close", "hit_last", "hit_poisoned", "hit_cursed", "hit_bleeding", "crit", "crit_chilled":
			Meta.opts["autofire"] = true
			var foes := []
			for i in (1 if m == "hit_last" else 4):
				var at := Vector2(p.x - 45.0 + i * 30.0, p.y - 90.0)
				if m == "hit_far":
					at = Vector2(p.x - 60.0 + i * 40.0, p.y - 160.0)
				elif m == "hit_close":
					at = Vector2(p.x - 18.0 + i * 12.0, p.y - 24.0)
				foes.append(_sturdy(at))
			if m.begins_with("crit"):
				p.crit = 1.0
			_tick(1800, func(_i): _mark(foes, m))   # 30 s: dozens of hits, for the 10% ones
		"kill", "kill_chilled", "kill_burning", "kill_elite", "kill_close":
			Meta.opts["autofire"] = true
			for i in 3:
				_sturdy(Vector2(p.x - 40.0 + i * 40.0, p.y - 110.0))
			_tick(1800, func(i): _feed(i, m))   # 30 s: over a hundred kills, for the 8% ones
		"hurt", "armor_lost", "dodge", "guard":
			_sturdy(Vector2(p.x + 30.0, p.y - 30.0))
			_sturdy(Vector2(p.x - 30.0, p.y - 30.0))
			var gold0 := 0
			for k in (24 if m == "dodge" else 1):
				_shots_round(26.0)
				p.invuln = 0.0
				p.dodge_t = 0.0
				if m == "armor_lost":
					p.armor = 1
				elif m == "dodge":
					p.evade = 0.6
				elif m == "guard":
					p.gold = 30
					gold0 = p.gold
				var hp0 := p.hp
				Combat.hurt_player(1, "a test")
				if m == "guard":
					return p.hp == hp0 and p.gold == gold0 - 15
				_tick(2)
		"bomb":
			for i in 6:
				_sturdy(Vector2(p.x + cos(i) * 60.0, p.y + sin(i) * 40.0))
			for k in 30:
				p.bombs = 3
				_press(&"bomb")
				_tick(20)
		"overheal":
			for k in 3:
				p.hp = p.max_hp
				p.heal(1)
				_tick(1)
		"heal":
			p.hp = p.max_hp - 2
			p.heal(1)
			_tick(2)
		"chest":
			for k in 25:
				var o := { "kind": "chest", "x": p.x + 20.0, "y": p.y }
				G.room.objects.append(o)
				G.interact(o)
				_tick(1)
		"buy":
			p.gold = 100
			var o := { "kind": "shop", "item": "bomb", "price": 5, "x": p.x + 20.0, "y": p.y }
			G.room.objects.append(o)
			G.interact(o)
			_tick(1)
		"coin":
			for k in 16:
				for j in 10:
					Combat.drop_pickup("coin", p.x, p.y)
				_tick(20)
		"potion":
			for k in 30:
				p.max_potions = maxi(p.max_potions, 2)
				p.potions = 1
				_press(&"heal", func(_i): _wound())
		"swap":
			Weapons.equip_weapon(p, Weapons.by_id("hexwand"))
			_tick(2)
		"clear":
			G.room.hits = 0
			G.room_cleared()
			_tick(2)
		"enter":
			_arena()
			_tick(5)
			# What an item called up on entering is still there a few ticks later.
			if Summons.turrets.filter(func(o): return o.get("item", false)).is_empty():
				fail("an item's turret from entering a room was gone %d ticks later" % 5)
		"level":
			Combat.gain_xp(p, 100000)
			_tick(2)
		"floor":
			G.start_floor()
			_tick(2)
		"crowd", "fight", "fight_shots":
			for i in (7 if m == "crowd" else 4):
				_sturdy(Vector2(p.x + cos(i * 0.9) * 50.0, p.y + sin(i * 0.9) * 40.0))
			_tick(16 * 60, func(i): _shoot_at_hero(i, m))
		"roll", "roll_crowd", "roll_danger":
			if m == "roll_crowd":
				for i in 7:
					_sturdy(Vector2(p.x + cos(i * 0.9) * 40.0, p.y + sin(i * 0.9) * 30.0))
			for k in 6:
				if m == "roll_danger":
					_shots_round(18.0, 6)
				Combat.on_roll_start(p)
				_tick(40)
		_:
			fail("no moment " + m)
	return _seen(want)

## Keeps the foes afflicted as the moment needs (they would shake it off).
func _mark(foes: Array, m: String) -> void:
	for e in foes:
		match m:
			"hit_poisoned":
				e.poison = 5.0
			"hit_cursed":
				e.curse_t = 3.0
			"hit_bleeding":
				e.bleed_t = 3.0
				e.bleed_dps = 0.0
			"crit_chilled":
				e.chill_t = 3.0
			"crit":
				e.burn_t = 3.0

## A weak foe in front of the hero every 12 ticks (to be killed), and foes' shots round him now and
## then (the frost lantern slows them).
func _feed(i: int, m: String) -> void:
	var p := G.player
	if i % 8 == 0:
		var k := (i / 8) % 4
		var at := Vector2(p.x - 30.0 + k * 20.0, p.y - 64.0)
		if m == "kill_close":
			at = Vector2(p.x - 12.0 + (k % 3) * 12.0, p.y - 22.0)
		var w := Combat.spawn_enemy("skeleton", at.x, at.y, m == "kill_elite", true)
		w.speed = 0.0
		w.hp = 1.0
		if m == "kill_chilled":
			w.chill_t = 99.0
		elif m == "kill_burning":
			w.burn_t = 99.0
	if i % 30 == 0:
		_shots_round(24.0, 6)

func _wound() -> void:
	G.player.hp = G.player.max_hp - 2   # a potion is only drunk when hurt

func _shoot_at_hero(i: int, m: String) -> void:
	if m == "fight_shots" and i % 20 == 0:
		_shots_round(40.0, 4)

# ---------- 3. Sets ----------
func _sets() -> void:
	for s in SETS:
		var pieces: Array = SETS[s][0]
		Actions.ran.clear()
		Actions.did.clear()
		Summons.stats.clear()
		var p := _start()
		for id in pieces:
			Gear.equip_gear(p, Gear.by_id(id))
		var full := 3 if GameData.rogues() else 2   # 13.2: the expanded game has a 3-piece step
		if p.set_tier.get(s, 0) != full:
			fail("set %s: four pieces worn, tier %d" % [s, p.set_tier.get(s, 0)])
		_tick(1)
		if not _moment(p, SETS[s][1], SETS[s][2]):
			fail("set %s: its 4-piece power (%s) did not happen" % [s, SETS[s][2]])
		# Swap one piece for a piece of another set: the power goes.
		var off: Dictionary = Gear.by_id(pieces[0])
		for g in Gear.all():
			if g["slot"] == off["slot"] and g["set"] != s and not g["new"]:
				Gear.equip_gear(p, g)
				break
		if p.set_tier.get(s, 0) != full - 1:
			fail("set %s: three pieces left, tier %d" % [s, p.set_tier.get(s, 0)])
		var src: String = "se4:" + str(s)
		for pr in p.procs:
			if pr.get("src", "") == src:
				fail("set %s: its 4-piece power stayed with three pieces" % s)
				break

# ---------- 4. The new actions, closely ----------
func _actions() -> void:
	var p := _start()
	_tick(1)
	# reflect: eight shots around the hero become eight of his, flying outward.
	EBullets.clear()
	_shots_round(30.0)
	var mine0 := G.pbullets.size()
	Actions.run(["reflect", 60, 1.0], 1, {})
	var live := 0
	for i in EBullets.n:
		if EBullets.blife[i] > 0:
			live += 1
	if live != 0 or G.pbullets.size() - mine0 != 8:
		fail("reflect: %d foes' shots left, %d of yours made (want 0 and 8)" % [live, G.pbullets.size() - mine0])
	else:
		for b in G.pbullets.slice(mine0):
			# Each one flies back the way it came: toward the hero's side of where it was.
			var out := Vector2(b.x - p.x, b.y - (p.y - 2))
			if Vector2(b.vx, b.vy).dot(out) >= 0:
				fail("reflect: a shot kept flying away from the hero")
				break
	# slow_shots: shots near slow down, and stay slow.
	EBullets.clear()
	_shots_round(30.0, 4)
	Combat.eshot(p.x + 150.0, p.y, 0.0, 15.0, "red")   # one far off: not slowed
	var speed0 := []
	for i in EBullets.n:
		speed0.append(Vector2(EBullets.bvx[i], EBullets.bvy[i]).length())
	Actions.run(["slow_shots", 60, 0.3], 1, {})
	var slow := 0
	for i in EBullets.n:
		if EBullets.blife[i] > 0 and Vector2(EBullets.bvx[i], EBullets.bvy[i]).length() < speed0[i] * 0.31:
			slow += 1
	if slow != 4:
		fail("slow_shots: %d of the 4 near shots slowed (and none far)" % slow)
	EBullets.clear()
	# spread: a foe with three ailments passes all three to the two beside it, not to one far off.
	var a := _sturdy(Vector2(p.x, p.y - 80.0))
	var b := _sturdy(Vector2(p.x + 30.0, p.y - 80.0))
	var c := _sturdy(Vector2(p.x - 30.0, p.y - 80.0))
	var far := _sturdy(Vector2(p.x, p.y + 120.0))
	far.x = p.x   # held there: a spawn inside a pillar is moved to any free spot, maybe near the others
	far.y = p.y + 120.0
	a.burn_t = 3.0
	a.poison = 6.0
	a.curse_t = 3.0
	Actions.run(["spread", 50], 1, { "enemy": a })
	for e in [b, c]:
		if e.burn_t <= 0 or e.poison <= 0 or e.curse_t <= 0:
			fail("spread: a foe beside did not take every ailment (burn %.1f poison %.1f curse %.1f)" % [e.burn_t, e.poison, e.curse_t])
	if far.burn_t > 0 or far.poison > 0:
		fail("spread: a far foe took the ailments (burn %.1f poison %.1f)" % [far.burn_t, far.poison])
	# consume: three ailments used up for three hits' worth.
	var hp0 := a.hp
	Actions.run(["consume", 1.0], 1, { "enemy": a })
	if Actions.ailments(a).size() != 0 or a.hp >= hp0:
		fail("consume: ailments left %s, health %.0f -> %.0f" % [Actions.ailments(a), hp0, a.hp])
	# overkill: a weak foe killed by a big hit passes the rest to the nearest foe.
	var weak := Combat.spawn_enemy("skeleton", b.x + 10.0, b.y + 10.0, false, true)
	weak.hp = 1.0
	var hb := b.hp
	Combat.damage_enemy(weak, 500.0, { "no_crit": true, "no_mult": true })
	if weak.over < 400.0:
		fail("overkill: the damage past death was not kept (%.0f)" % weak.over)
	Actions.run(["overkill", 1.0], 1, { "enemy": weak })
	if b.hp >= hb:
		fail("overkill: the nearest foe took nothing")
	# give: potions stop at the slots; bombs and keys add up.
	p.max_potions = 2
	p.potions = 1
	Actions.run(["give", "potions", 3], 1, {})
	if p.potions != 2:
		fail("give: %d potions in 2 slots" % p.potions)
	var b0 := p.bombs
	Actions.run(["give", "bombs", 2], 1, {})
	if p.bombs != b0 + 2:
		fail("give: bombs %d -> %d" % [b0, p.bombs])
	# The bribe purse with too little gold: the hit costs health as usual.
	Gear.equip_gear(p, Gear.by_id("bribepurse"))
	p.gold = 10
	p.invuln = 0.0
	p.armor = 0
	var h0 := p.hp
	Combat.hurt_player(1, "a test")
	if p.hp != h0 - 1 or p.gold != 10:
		fail("bribe purse with 10 gold: health %d -> %d, gold %d" % [h0, p.hp, p.gold])
