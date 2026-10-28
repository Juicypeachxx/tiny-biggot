extends Node
## 18.3 balance probe (a tool, not part of check.sh). Run:
##   godot --headless --path . res://tests/balance_probe.tscn -- --no-save [--probe-hero=N] [--probe-secs=S]
## Gives the hero one thing at a time (each trait at its full rank, each whole armour set) in the
## same seeded arena: six ordinary foes that come back as they die, autofire, god mode, S seconds.
## Prints the damage dealt against a baseline with nothing, as "[probe] kind id ratio".
## 19.1 --probe-melee: foes that walk in (slimes) and come back right beside you, so heroes that
## fight up close are measured fairly (skeletons keep their distance). --probe-hero=ID also works.
## 20.1 --probe-live: a fight more like a run. Half the foes walk in (slimes), half shoot from
## further off (skeletons), all with 60 health; the hero is NOT in god mode (hits land, and the
## health is topped up before it runs out), rolls every 2s, uses the skill whenever it is ready,
## and every 10s the room is cleared and a new one entered (on_room_clear, on_room_enter).
## --probe-heroes: only the baseline of every hero. --probe-seeds=N: N fights each, summed.
## --probe-only=a_storm,set:viper: only those. --probe-actions: what each trait's actions did.

var secs := 20
var foe := "skeleton"
var ring := Vector2(60, 40)
var foe_hp := 600.0
var live := false
var seeds := 1
var seed_i := 0

func _arena(hero: int) -> Player:
	seed(1803 + seed_i * 7919)
	G.hero_index = hero
	G.new_run()
	G.god = not live
	Meta.opts["autofire"] = true
	G.floor_index = 3
	G.floor_d["depth"] = 2
	_room()
	return G.player

func _room() -> void:
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.enemies.clear()
	G.room.objects = G.room.objects.filter(func(o): return not o["kind"] in ["e_keg", "e_pot"])
	G.room.waves_left = 0
	G.locked = true
	G.state = &"play"
	G.player.x = 224.0   # the middle of the room, foes all round
	G.player.y = 152.0

## The damage of `seeds` fights, each in a fresh arena after `setup` (the trait or set) is applied.
func _sum(hero: int, setup: Callable) -> float:
	var total := 0.0
	for k in seeds:
		seed_i = k
		var p := _arena(hero)
		setup.call(p)
		total += _measure()
	return total

## Damage dealt in `secs` seconds: dead foes count their full health.
func _measure() -> float:
	var dealt := 0.0
	for i in secs * 60:
		var alive := G.enemies.filter(func(e): return e.hp > 0)
		while alive.size() < 6:
			var a := randf() * TAU
			var kind := foe
			var rr := ring
			if live:   # three of each
				kind = "slime" if alive.filter(func(e): return e.type == "slime").size() < 3 else "skeleton"
				rr = Vector2(34, 28) if kind == "slime" else Vector2(96, 70)
			var e := Combat.spawn_enemy(kind, 224.0 + cos(a) * rr.x, 152.0 + sin(a) * rr.y, false, true)
			e.spawn_t = 0.0
			e.max_hp = foe_hp   # tough enough that the damage is never capped by how fast foes arrive
			e.hp = foe_hp
			alive.append(e)
		var before := {}
		for e in G.enemies:
			before[e.uid] = [e, e.hp]
		if live:   # inside the counted window: a roll or a skill can hurt foes at once
			var p := G.player
			if i % 120 == 60 and p.charges > 0 and p.dodge_t <= 0 and p.dash_t <= 0:
				var to := Vector2(224.0 + randf_range(-40.0, 40.0), 152.0 + randf_range(-30.0, 30.0)) - Vector2(p.x, p.y)
				p.start_roll(to.normalized() if to.length() > 1.0 else Vector2(1, 0))
			if i % 30 == 15 and Abilities.ready(p):
				Abilities.use(p)
		Keys.tick()
		G.update(TB.DT)
		for k in before:
			var e: Enemy = before[k][0]
			dealt += maxf(0.0, before[k][1] - maxf(e.hp, 0.0))
		match G.state:
			&"traits":
				G.tchoice = {}
				G.player.pending = 0
				G.state = &"play"
			&"choice":
				G.choice = {}
				G.state = &"play"
			&"dead", &"win", &"pause":
				G.state = &"play"
		if not live or G.player.hp < 3:
			G.player.hp = G.player.max_hp
		if live and i % 600 == 599:
			Effects.fire("on_room_clear")
			_room()
	return dealt

func _ready() -> void:
	await get_tree().process_frame
	var hero := DebugArgs.get_int("probe-hero", 0)
	for i in GameData.heroes().size():
		if GameData.heroes()[i]["id"] == DebugArgs.get_str("probe-hero", ""):
			hero = i
	secs = DebugArgs.get_int("probe-secs", 20)
	seeds = DebugArgs.get_int("probe-seeds", 1)
	if DebugArgs.has("probe-live"):
		live = true
		foe_hp = 60.0
	if DebugArgs.has("probe-melee"):
		foe = "slime"
		ring = Vector2(26, 22)
		foe_hp = 60.0   # they come back at once beside you, so kills (and what kills trigger) happen often
	if DebugArgs.has("probe-heroes"):
		for h in GameData.heroes().size():
			print("[probe] hero %s %.0f" % [GameData.heroes()[h]["id"], _sum(h, func(_p): pass)])
		get_tree().quit()
		return
	var base := _sum(hero, func(_p): pass)
	print("[probe] base %s %.0f" % [GameData.heroes()[hero]["id"], base])
	var only: Array = Array(DebugArgs.get_str("probe-only", "").split(",", false))
	for t in Traits.all():
		if not t["new"] or (not only.is_empty() and not t["id"] in only):
			continue
		var give := func(p: Player) -> void:
			for k in t["max"]:
				p.pending += 1
				G.take_trait(t)
		Actions.ran.clear()
		print("[probe] trait %s %.2f" % [t["id"], _sum(hero, give) / maxf(1.0, base)])
		if DebugArgs.has("probe-actions"):
			print("[probe]   actions ", Actions.ran)
	for id in Gear.SETS:
		if not only.is_empty() and not ("set:" + id) in only:
			continue
		var wear := func(p: Player) -> void:
			for g in Gear.pieces(id):
				Gear.equip_gear(p, g)
		print("[probe] set %s %.2f" % [id, _sum(hero, wear) / maxf(1.0, base)])
	get_tree().quit()
