extends Node
## Every boss and mini-boss: stages and its own drop (his ask, 6 Oct). Run:
##   godot --headless --path . res://tests/bosses_test.tscn -- --no-save
##   1. Every floor mini-boss and rift champion breaks into stage 2 at two thirds of its health
##      and stage 3 at one third, cannot be hurt while it breaks, and fights on in each stage.
##   2. Every rift guardian (and Rex; rift minis are checked as minis) breaks into a third stage below a quarter of its health.
##   4. A blow of any size stops at the next stage's line (his ask, 6 Oct).
##   3. Every owner in BossLoot.DROPS leaves its own item when it falls, and those items never
##      turn up in a random weapon or gear roll.
## Prints "bosses test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL bosses: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	seed(5)
	Meta.opts["autofire"] = true
	for type in GameData.ENEMIES:
		if GameData.ENEMIES[type].get("mini", false):
			_mini(type)
	for key in RiftBosses.PLANS:
		if GameData.BOSSES.has(key):
			_rift(key)   # the rift minis are foes: checked with the minis above
	for key in BossLoot.DROPS:
		_drop(key)
	_pools()
	for key in BossAI.STAGE_PLANS:
		_gate(key)
	_gate("squallheron")
	_looks()
	print("bosses test: PASSED" if fails == 0 else "bosses test: %d FAILED" % fails)
	get_tree().quit()

func _room() -> void:
	G.hero_index = 0
	G.new_run()
	G.god = true
	G.floor_index = 4
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.room.waves_left = 0
	G.locked = true

func play(ticks: int) -> void:
	for i in ticks:
		G.player.hp = G.player.max_hp
		Keys.tick()
		G.update(TB.DT)
		if G.state != &"play":
			G.state = &"play"
			G.tchoice = {}
			G.choice = {}


## A boss is felled the way a player fells it: down through every stage (Stages.gate), then the
## last blow. Other foes: the one blow.
func _break_down(e: Enemy) -> bool:
	var staged := false
	for k in 8:
		if e.hp <= 0 or Stages.gate(e) <= 0:
			return staged
		Combat.damage_enemy(e, e.hp * 2.0 + 10.0, { "no_crit": true, "no_mult": true })
		play(150)
		staged = true
	return staged

func _fell(e: Enemy) -> void:
	if _break_down(e):
		play(120)   # the last stage's break and a rift foe's grace between phases run out
	Combat.damage_enemy(e, e.hp * 2.0 + 10.0, { "no_crit": true, "no_mult": true })

func _cull(b: Enemy) -> void:
	for e in G.enemies.duplicate():
		if e != b:
			G.enemies.erase(e)

## A foe at the given share of its health: it breaks, unhurt, then fights on in that stage.
func _breaks(e: Enemy, name: String, share: float, st: int) -> bool:
	e.hp = e.max_hp * share
	play(2)
	if e.break_t <= 0 or e.stage != st:
		fail("%s at %d%% did not break into stage %d (stage %d)" % [name, share * 100, st, e.stage])
		return false
	var hp0 := e.hp
	Combat.damage_enemy(e, 1000.0, { "no_crit": true })
	if e.hp != hp0:
		fail("%s was hurt during its stage break" % name)
	for i in 8 * 60:
		play(1)
		if i % 120 == 0:
			_cull(e)
		e.hp = e.max_hp * share
		if not e in G.enemies:
			fail("%s vanished in stage %d" % [name, st])
			return false
	return true

func _mini(type: String) -> void:
	seed(type.hash())
	_room()
	var p := G.player
	var e := Combat.spawn_enemy(type, p.x, p.y - 70.0, false, true)
	e.max_hp = 1e6
	e.hp = 1e6
	play(30)
	if e.stage > 1:
		fail("%s started in stage %d" % [type, e.stage])
	if _breaks(e, type, 0.6, 2):
		_breaks(e, type, 0.3, 3)

func _rift(key: String) -> void:
	seed(key.hash())
	_room()
	var b: Enemy = Combat.spawn_boss(key) if GameData.BOSSES.has(key) else Combat.spawn_enemy(key, G.player.x, G.player.y - 70.0, false, true)
	b.max_hp = 1e7
	b.hp = 1e7
	play(60)
	b.hp = b.max_hp * 0.4   # its own second phase first
	play(120)
	_cull(b)
	if b.stage > 1:
		fail("%s broke too early (stage %d at 40%%)" % [key, b.stage])
	_breaks(b, key, 0.2, 3)

func _drop(key: String) -> void:
	seed(key.hash())
	_room()
	var p := G.player
	var e: Enemy = Combat.spawn_boss(key) if GameData.BOSSES.has(key) else Combat.spawn_enemy(key, p.x, p.y - 70.0, false, true)
	play(30)
	_cull(e)
	_fell(e)
	if e.hp > 0:
		_fell(e)
	play(2)
	var want: String = BossLoot.DROPS[key][1]
	var got := G.room.objects.filter(func(o): return o["kind"] == "item" and o["item"]["id"] == want)
	if got.size() != 1:
		fail("%s left %d of its %s (want 1)" % [key, got.size(), want])
	var it: Dictionary = Weapons.by_id(want) if BossLoot.DROPS[key][0] == "weapon" else Gear.by_id(want)
	if it.is_empty() or not Img.has(it["sprite"]):
		fail("%s: its %s has no icon" % [key, want])

## His ask (6 Oct): a blow of any size stops at the line of the next stage (Stages.gate).
func _gate(key: String) -> void:
	seed(key.hash())
	_room()
	var p := G.player
	var e: Enemy = Combat.spawn_boss(key) if GameData.BOSSES.has(key) else Combat.spawn_enemy(key, p.x, p.y - 70.0, false, true)
	play(30)
	_cull(e)
	var line := Stages.gate(e)
	Combat.damage_enemy(e, 1e12, { "no_crit": true })
	if e.hp <= 0 or absf(e.hp - line) > 1.0:
		fail("%s: a huge blow left %.0f health, not its stage line %.0f" % [key, e.hp, line])

## His ask (6 Oct): each guardian evolves with its stages: two more looks, drawn from stage 2 and 3.
func _looks() -> void:
	for key in GameData.BOSSES:
		if key == "rex":
			continue   # his own dog keeps his look
		var sp: String = GameData.BOSSES[key]["sprite"]
		for st in [2, 3]:
			if not Img.has(sp + "_s%d" % st):
				fail("%s has no stage-%d look" % [key, st])
	_room()
	var b := Combat.spawn_boss("colossus")
	for st in [1, 2, 3]:
		b.stage = st
		if Stages.look(b) != st:
			fail("the Colossus in stage %d shows look %d" % [st, Stages.look(b)])

func _pools() -> void:
	for r in ["common", "rare", "epic", "legend"]:
		for i in 400:
			var w := Weapons.random_weapon(r)
			if BossLoot.is_unique(w["id"]):
				fail("%s turned up in a random %s weapon roll" % [w["id"], r])
				return
			var g := Gear.random_gear(r)
			if BossLoot.is_unique(g["id"]):
				fail("%s turned up in a random %s gear roll" % [g["id"], r])
				return
