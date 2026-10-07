extends Node
## 18.3 balance probe (a tool, not part of check.sh). Run:
##   godot --headless --path . res://tests/balance_probe.tscn -- --no-save [--probe-hero=N] [--probe-secs=S]
## Gives the hero one thing at a time (each trait at its full rank, each whole armour set) in the
## same seeded arena: six ordinary foes that come back as they die, autofire, god mode, S seconds.
## Prints the damage dealt against a baseline with nothing, as "[probe] kind id ratio".

const FOE := "skeleton"

var secs := 20

func _arena(hero: int) -> Player:
	seed(1803)
	G.hero_index = hero
	G.new_run()
	G.god = true
	Meta.opts["autofire"] = true
	G.floor_index = 3
	G.floor_d["depth"] = 2
	G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
	G.enemies.clear()
	G.room.objects = G.room.objects.filter(func(o): return not o["kind"] in ["e_keg", "e_pot"])
	G.room.waves_left = 0
	G.locked = true
	G.state = &"play"
	G.player.x = 224.0   # the middle of the room, foes all round
	G.player.y = 152.0
	return G.player

## Damage dealt in `secs` seconds: dead foes count their full health.
func _measure() -> float:
	var dealt := 0.0
	var p := G.player
	for i in secs * 60:
		while G.enemies.filter(func(e): return e.hp > 0).size() < 6:
			var a := randf() * TAU
			var e := Combat.spawn_enemy(FOE, p.x + cos(a) * 60.0, p.y + sin(a) * 40.0, false, true)
			e.spawn_t = 0.0
			e.max_hp = 600.0   # tough enough that the damage is never capped by how fast foes arrive
			e.hp = 600.0
		var before := {}
		for e in G.enemies:
			before[e.uid] = [e, e.hp]
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
		G.player.hp = G.player.max_hp
	return dealt

func _ready() -> void:
	await get_tree().process_frame
	var hero := DebugArgs.get_int("probe-hero", 0)
	secs = DebugArgs.get_int("probe-secs", 20)
	_arena(hero)
	var base := _measure()
	print("[probe] base %s %.0f" % [GameData.heroes()[hero]["id"], base])
	for t in Traits.all():
		if not t["new"]:
			continue
		var p := _arena(hero)
		for k in t["max"]:
			p.pending += 1
			G.take_trait(t)
		print("[probe] trait %s %.2f" % [t["id"], _measure() / maxf(1.0, base)])
	for id in Gear.SETS:
		var p := _arena(hero)
		for g in Gear.pieces(id):
			Gear.equip_gear(p, g)
		print("[probe] set %s %.2f" % [id, _measure() / maxf(1.0, base)])
	get_tree().quit()
