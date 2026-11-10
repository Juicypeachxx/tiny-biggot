extends Node
## Stage 49 (his list of another game's core gameplay, 10 Oct; GAMEPLAY_PLAN.md). Run:
##   godot --headless --path . res://tests/stage49_test.tscn -- --no-save
## 49.2 ROOM DRAUGHTS (draughts.gd): each of the six gives its buff from the belt and every bit of
## it is gone when the room is clear (drunk in a quiet room, it lasts through the next fight); two
## of a kind count twice; doors promise two, guardians and elites drop them; their cards. 49.3 the
## WHETSTONE (+1 weapon level from the belt; his HONING STONE) behind a door.
## 49.1 THE CURSES YOU CARRY and THE FOES YOU HAVE SLAIN (burdens.gd): what counts as a curse (a
## cursed trait, an armory curse, a cursed relic, a flawed weapon), and each of the eight relics
## gives exactly its number for each curse or every 100 kills: damage (Combat.hook_mult), fire rate
## (Weapons.wrate), crit (Burdens.crit); SINNER'S CROWN is a curse itself; THE HUNDREDFOLD's heart
## every 100 kills; the cards show the value now; nothing for a hero without them.
## Prints "stage49 test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL stage49: ", msg)

func _start(hero: int = 0) -> Player:
	G.hero_index = hero
	G.new_run()
	G.floor_index = 2
	G.start_floor()
	G.god = true
	var p := G.player
	p.oath_picks = 0
	p.special_picks = 0
	p.pending = 0
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.enemies.clear()
	G.locked = true
	G.state = &"play"
	return p

func _foe(p: Player, dx: float = 40.0) -> Enemy:
	var e := Combat.spawn_enemy("slime", p.x + dx, p.y, false, true)
	e.max_hp = 1e7
	e.hp = 1e7
	e.speed = 0.0
	return e

## A new tick: the curse count is read once a tick.
func _tick() -> void:
	G.time += 0.02

func _relic(p: Player, id: String) -> void:
	G.add_relic(p, Relics.by_id(id))
	_tick()

func _near(a: float, b: float, what: String) -> void:
	if absf(a - b) > 0.0005:
		fail("%s: %.4f (want %.4f)" % [what, a, b])

func _ready() -> void:
	seed(49)
	_burdens()
	_draughts()
	print("stage49 test: PASSED" if fails == 0 else "stage49 test: %d FAILED" % fails)
	get_tree().quit()

# ---------- 49.1 ----------
func _burdens() -> void:
	var p := _start()
	var e := _foe(p)
	_tick()
	if Burdens.count(p) != 0:
		fail("a new hero carries %d curses" % Burdens.count(p))
	var m0 := Combat.hook_mult(p, e)
	var r0 := Weapons.wrate(p)
	# What counts: a cursed trait, the armory's curses, a cursed relic, a flawed weapon.
	var cursed: Array = Traits.all().filter(func(t): return t["rarity"] == "cursed")
	if cursed.is_empty():
		fail("no cursed traits to test with")
		return
	p.pending += 1
	G.take_trait(cursed[0])
	G.state = &"play"
	p.curse_marks += 2
	G.add_relic(p, Relics.by_id("cursedcoin"))
	Weapons.equip_weapon(p, Enchant.enchanted(p.weapon, Enchant.group_of("bad")[0]))
	_tick()
	var n := Burdens.count(p)
	if n != 5 or Burdens.curses(p) != 5:
		fail("a cursed trait, two armory curses, CURSED COIN and a flawed weapon: %d curses (want 5)" % n)
	# The relics that grow with them.
	m0 = Combat.hook_mult(p, e)
	r0 = Weapons.wrate(p)
	var c0 := Burdens.crit(p)
	if c0 != 0.0:
		fail("crit from curses with no relic for it: %.3f" % c0)
	_relic(p, "burdenidol")
	_near(Combat.hook_mult(p, e) - m0, 0.08 * 5, "BURDENED IDOL with 5 curses: damage")
	if Live.now(Relics.by_id("burdenidol")["effects"], p) != " (+40% NOW)":
		fail("BURDENED IDOL's card: \"%s\" (want \" (+40%% NOW)\")" % Live.now(Relics.by_id("burdenidol")["effects"], p))
	_relic(p, "penitentchain")
	_near(Weapons.wrate(p) / r0, 1.0 + 0.06 * 5, "PENITENT'S CHAIN with 5 curses: fire rate")
	_relic(p, "widowveil")
	_near(Burdens.crit(p), 0.04 * 5, "WIDOW'S VEIL with 5 curses: crit")
	# SINNER'S CROWN: a curse itself (6 now), a heart less, +15% damage and +5% fire rate a curse.
	var mh := p.max_hp
	m0 = Combat.hook_mult(p, e)
	r0 = Weapons.wrate(p)
	_relic(p, "sinnerscrown")
	if Burdens.curses(p) != 6 or p.max_hp != mh - 2:
		fail("SINNER'S CROWN: %d curses (want 6), max health %d (want %d)" % [Burdens.curses(p), p.max_hp, mh - 2])
	_near(Combat.hook_mult(p, e) - m0, 0.08 + 0.15 * 6, "SINNER'S CROWN: damage (one more curse for the idol, 15% a curse)")
	_near(Weapons.wrate(p) / r0, (1.0 + 0.11 * 6) / (1.0 + 0.06 * 5), "SINNER'S CROWN: fire rate")
	# The foes slain this run.
	p = _start()
	e = _foe(p)
	p.kills = 250
	_tick()
	m0 = Combat.hook_mult(p, e)
	r0 = Weapons.wrate(p)
	_relic(p, "tallystick")
	_near(Combat.hook_mult(p, e) - m0, 0.05 * 2.5, "TALLY STICK at 250 kills: damage")
	_relic(p, "bonerosary")
	_near(Burdens.crit(p), 0.03 * 2.5, "BONE ROSARY at 250 kills: crit")
	_relic(p, "reaperlamp")
	_near(Weapons.wrate(p) / r0, 1.0 + 0.08 * 2.5, "REAPER'S LAMP at 250 kills: fire rate")
	m0 = Combat.hook_mult(p, e)
	_relic(p, "hundredfold")
	_near(Combat.hook_mult(p, e) - m0, 0.12 * 2.5, "THE HUNDREDFOLD at 250 kills: damage")
	if Live.now(Relics.by_id("tallystick")["effects"], p) != " (+13% NOW)":
		fail("TALLY STICK's card: \"%s\" (want \" (+13%% NOW)\")" % Live.now(Relics.by_id("tallystick")["effects"], p))
	# THE HUNDREDFOLD: a heart every 100 kills.
	G.pickups.clear()
	for i in 200:
		var f := Combat.spawn_enemy("slime", p.x + 60, p.y, false, true)
		Combat.kill_enemy(f)
	var hearts := G.pickups.filter(func(k): return k.kind == "heart").size()
	if hearts < 2:
		fail("THE HUNDREDFOLD: %d hearts from 200 kills (want 2 or more)" % hearts)
	# Without them: nothing.
	p = _start()
	e = _foe(p)
	p.kills = 900
	p.curse_marks = 3
	_tick()
	if Burdens.dmg(p) != 0.0 or Burdens.crit(p) != 0.0 or Burdens.rate_mult(p) != 1.0:
		fail("a hero without these relics gets %.3f damage, %.3f crit, x%.3f fire rate" % [Burdens.dmg(p), Burdens.crit(p), Burdens.rate_mult(p)])
	print("[stage49] curses: a cursed trait, armory curses, cursed relics, a flawed weapon; 8 relics give their number for each, and for every 100 kills")

# ---------- 49.2, 49.3 ----------
func _sheet(p: Player) -> Dictionary:
	return { "dmg": p.dmg, "rate": p.rate, "speed": p.speed, "crit": p.crit, "crit_mult": p.crit_mult,
		"count": float(p.count), "dodge_cd": p.dodge_cd, "dodge_charges": float(p.dodge_charges), "procs": float(p.procs.size()) }

func _drink(p: Player, kind: String) -> void:
	p.belt.clear()
	p.belt.append(kind)
	Consumables.use(p, 0)

func _draughts() -> void:
	var want := {
		"d_war": { "dmg": 1.6 }, "d_quick": { "rate": 1.4, "speed": 1.15 }, "d_eagle": { "crit": 0.25, "crit_mult": 0.5 },
		"d_storm": { "count": 2.0 }, "d_ghost": { "dodge_cd": 0.5, "dodge_charges": 1.0 }, "d_leech": { "procs": 1.0 },
	}
	if Draughts.KINDS.size() != want.size():
		fail("%d room draughts (want %d)" % [Draughts.KINDS.size(), want.size()])
	for k in Draughts.KINDS:
		if not ResourceLoader.exists("res://assets/graphics/%s.png" % k):
			fail("%s has no picture" % k)
		var c := Consumables.data(k)
		if not Consumables.is_kind(k) or not String(c["desc"]).ends_with("UNTIL THE ROOM IS CLEAR"):
			fail("%s is not a belt item with its card (%s)" % [k, c.get("desc", "")])
		var p := _start()
		var before := _sheet(p)
		_drink(p, k)
		var on := _sheet(p)
		if p.draughts.size() != 1 or not p.belt.is_empty():
			fail("%s: %d draughts on, %d in the belt after drinking" % [k, p.draughts.size(), p.belt.size()])
		for stat in want[k]:
			var v: float = want[k][stat]
			var got: float = (on[stat] / before[stat]) if stat in ["dmg", "rate", "speed", "dodge_cd"] else (on[stat] - before[stat])
			if absf(got - v) > 0.001:
				fail("%s: %s %s (want %s)" % [k, stat, str(got), str(v)])
		G.room_cleared()
		var after := _sheet(p)
		for stat in before:
			if absf(after[stat] - before[stat]) > 0.0001:
				fail("%s: %s is %s after the room is clear (was %s)" % [k, stat, str(after[stat]), str(before[stat])])
		if not p.draughts.is_empty():
			fail("%s still on after the room is clear" % k)
	# Two of a kind count twice; drunk in a quiet room it lasts through the next fight.
	var p := _start()
	var c0 := p.count
	_drink(p, "d_storm")
	_drink(p, "d_storm")
	if p.count != c0 + 4:
		fail("two STORMCALL DRAUGHTS: %d projectiles (want %d)" % [p.count, c0 + 4])
	G.room_cleared()
	if p.count != c0:
		fail("two STORMCALL DRAUGHTS: %d projectiles after the room is clear (want %d)" % [p.count, c0])
	_drink(p, "d_war")
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.state = &"play"
	if p.draughts.size() != 1:
		fail("a draught drunk in a quiet room ended at the next door")
	G.room_cleared()
	if not p.draughts.is_empty():
		fail("a draught drunk in a quiet room outlasted the next fight")
	# Doors: two draughts, or a whetstone; the whetstone's level.
	var w := {}
	Draughts.reward_weights(w)
	if w.get("draught", 0) <= 0 or w.get("whet", 0) <= 0 or not GameData.REWARDS.has("draught") or not GameData.REWARDS.has("whet"):
		fail("no doors that promise draughts or a whetstone")
	for r in ["draught", "whet"]:
		if not ResourceLoader.exists("res://assets/graphics/%s.png" % GameData.REWARDS[r]["icon"]):
			fail("the %s door's sign has no picture" % r)
	G.pickups.clear()
	G.give_reward("draught")
	G.give_reward("whet")
	var got := G.pickups.map(func(k): return k.kind)
	if got.filter(func(k): return Draughts.is_kind(k)).size() != Draughts.REWARD_N or not got.has("c_whet"):
		fail("the doors' rewards: %s (want %d draughts and a whetstone)" % [str(got), Draughts.REWARD_N])
	var plus: int = p.weapon.get("plus", 0)
	_drink(p, "c_whet")
	if int(p.weapon.get("plus", 0)) != plus + 1:
		fail("a WHETSTONE: weapon +%d (want +%d)" % [int(p.weapon.get("plus", 0)), plus + 1])
	# Guardians and elites drop them with the other belt items.
	var seen := {}
	for i in 3000:
		var k := Consumables.random_kind()
		if not Consumables.is_kind(k):
			fail("a dropped belt item %s is no belt item" % k)
			break
		if Draughts.is_kind(k):
			seen[k] = true
	if seen.size() != Draughts.KINDS.size():
		fail("3000 belt drops held %d kinds of draught of %d" % [seen.size(), Draughts.KINDS.size()])
	print("[stage49] room draughts: %d kinds, each on until the room is clear, then gone to the last bit; doors with draughts or a whetstone" % Draughts.KINDS.size())
