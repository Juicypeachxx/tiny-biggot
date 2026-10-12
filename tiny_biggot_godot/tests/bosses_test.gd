extends Node
## Every boss and mini-boss: stages and its own drop (his ask, 6 Oct). Run:
##   godot --headless --path . res://tests/bosses_test.tscn -- --no-save
##   1. Every floor mini-boss and rift champion breaks into stage 2 at two thirds of its health
##      and stage 3 at one third, cannot be hurt while it breaks, and fights on in each stage.
##   2. Every rift guardian (and Rex; rift minis are checked as minis) breaks into a third stage below a quarter of its health.
##   4. A blow of any size stops at the next stage's line (his ask, 6 Oct).
##   5. Boss armor (6.5, armor.gd): a small blow wears the plate and a quarter reaches the health;
##      breaking the plate stuns and leaves the foe vulnerable; a new stage brings a new plate.
##   3. Every owner in BossLoot.DROPS leaves its own item when it falls, and those items never
##      turn up in a random weapon or gear roll.
## Prints "bosses test: PASSED" or a FAIL line per problem.

var fails := 0

func fail(msg: String) -> void:
	fails += 1
	print("FAIL bosses: ", msg)

func _ready() -> void:
	await get_tree().process_frame
	Resolve.off = true   # (56.3 RESOLVE has its own test: stage56_test; here a blow fells a guardian)
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
	for key in ["holycow", "mirehulk"]:
		_armor(key)
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
		Combat.damage_enemy(e, (e.hp + Armor.shown(e)) * 2.0 + 10.0, { "no_crit": true, "no_mult": true })   # through the plate too
		play(150)
		staged = true
	return staged

func _fell(e: Enemy) -> void:
	if _break_down(e):
		play(120)   # the last stage's break and a rift foe's grace between phases run out
	Combat.damage_enemy(e, (e.hp + Armor.shown(e)) * 2.0 + 10.0, { "no_crit": true, "no_mult": true })   # through the plate too

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

func _armor(key: String) -> void:
	seed(key.hash())
	_room()
	var p := G.player
	var e: Enemy = Combat.spawn_boss(key) if GameData.BOSSES.has(key) else Combat.spawn_enemy(key, p.x, p.y - 70.0, false, true)
	play(30)
	_cull(e)
	var plate := Armor.plate(e)
	Armor.refresh(e)
	if plate <= 0 or e.armor <= 0:
		fail("%s: no armor plate (%.0f)" % [key, plate])
		return
	# 7.1: a hit of its weakness wears the plate WEAR times as fast; the health takes the same.
	var wk := Armor.weakness(e)
	var wo := { "no_mult": true, "no_crit": wk != "crits", "force_crit": wk == "crits" }
	match wk:
		"fire": wo["col"] = "orange"
		"poison": wo["col"] = "lime"
		"storm": wo["col"] = "cyan"
		"blasts": wo["boom"] = true
	var hw := e.hp
	var aw := e.armor
	Combat.damage_enemy(e, 20.0, wo)
	if wk == "" or absf((aw - e.armor) / maxf(0.01, hw - e.hp) - Armor.WEAR / Armor.through(e)) > 0.3:   # (56.3: less through further down)
		fail("%s: its weakness (%s) wore %.1f plate for %.1f health" % [key, wk, aw - e.armor, hw - e.hp])
	var hp0 := e.hp
	var a0 := e.armor
	Combat.damage_enemy(e, 40.0, { "no_crit": true, "no_mult": true })
	var worn := a0 - e.armor
	if worn < 30.0 or worn > 50.0 or absf(hp0 - e.hp - worn * Armor.through(e)) > 0.5:
		fail("%s: a blow of 40 wore %.1f armor and took %.1f health" % [key, worn, hp0 - e.hp])
	Combat.damage_enemy(e, e.armor * 1.3 + 1.0, { "no_crit": true, "no_mult": true })
	if e.armor > 0 or e.stun_t <= 0 or e.vuln_t <= 0:
		fail("%s: the plate did not break into a stun (armor %.1f, stun %.1f)" % [key, e.armor, e.stun_t])
	var st := e.stage * 4 + e.phase
	Combat.damage_enemy(e, e.hp * 2.0 + 10.0, { "no_crit": true, "no_mult": true })
	Meta.opts["autofire"] = false   # the player's own shots would wear the new plate
	for k in 80:   # until the next stage starts (checked at once: a pet's bites would wear it)
		play(5)
		if e.hp <= 0 or (e.stage * 4 + e.phase != st and e.break_t <= 0 and e.state != &"stagebreak"):
			break
	Meta.opts["autofire"] = true
	if e.hp <= 0 or e.stage * 4 + e.phase == st:
		fail("%s: did not reach its next stage (stage %d, state %s, hp %.0f of %.0f)" % [key, e.stage, e.state, e.hp, e.max_hp])
	elif Armor.shown(e) < plate - 0.5:
		fail("%s: no fresh plate in its next stage (%.0f of %.0f)" % [key, Armor.shown(e), plate])

## His ask (6 Oct): each guardian evolves with its stages: two more looks, drawn from stage 2 and 3.
func _looks() -> void:
	for key in GameData.BOSSES:
		if key == "rex":
			for st in [2, 3]:   # 6.2: Rex evolves too, cute (sitting and lying)
				for v in ["rex", "rex_lie"]:
					if not Img.has(v + "_s%d" % st):
						fail("Rex has no stage-%d look (%s)" % [st, v])
			continue
		var sp: String = GameData.BOSSES[key]["sprite"]
		for st in [2, 3]:
			if not Img.has(sp + "_s%d" % st):
				fail("%s has no stage-%d look" % [key, st])
	for key in GameData.ENEMIES:   # 6.1: every mini-boss and champion, and its elite
		if GameData.ENEMIES[key].get("mini", false):
			var sp: String = GameData.ENEMIES[key]["sprite"]
			for st in [2, 3]:
				for v in [sp, sp + "_elite"]:
					if Img.has(v) and not Img.has(v + "_s%d" % st):
						fail("%s has no stage-%d look" % [v, st])
	_room()
	var m := Combat.spawn_enemy("mirehulk", 100, 100, false, true)
	m.stage = 3
	if Stages.look(m) != 3:
		fail("a mini-boss in stage 3 shows look %d" % Stages.look(m))
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
