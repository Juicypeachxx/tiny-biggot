extends Node
## Diagnosis (his report, 9 Oct: "in early stage some elites are immortal"): every foe of the first
## floors as an elite with each elite trait, against a starting hero for up to 60 s. Prints the ones
## that do not die, with how their health went. Not part of check.sh.

func _ready() -> void:
	await get_tree().process_frame
	var bad := 0
	var n := 0
	var hero := DebugArgs.get_int("hero", 0)
	for fl in [0, 1, 2]:
		var pool: Array = GameData.floors()[fl]["pool"]
		for type in pool:
			for tr in EliteTraits.ALL + ["(rolled)"]:
				n += 1
				seed(n)
				G.hero_index = hero
				G.new_run()
				G.floor_index = fl
				G.start_floor()
				G.god = true
				var p := G.player
				p.oath_picks = 0
				p.pending = 0
				G.enter_room(World.make_room(G.floor_d, "combat", "", "s", { "no_secret": true }))
				G.room.waves_left = 0
				G.enemies.clear()
				G.locked = true
				G.state = &"play"
				Meta.opts["autofire"] = true
				p.x = 14.0 * TB.TS
				p.y = 12.0 * TB.TS
				var e := Combat.spawn_enemy(type, p.x, p.y - 70.0, true, true)
				if tr != "(rolled)":
					e.traits.clear()
					e.traits.append(tr)
				var hp0 := e.hp
				var low := e.hp
				var ticks := 0
				var trace := []
				while ticks < 3600 and e.hp > 0 and G.enemies.has(e):
					p.hp = p.max_hp
					p.x = 14.0 * TB.TS
					p.y = 12.0 * TB.TS
					Keys.tick()
					G.update(TB.DT)
					if G.state != &"play":
						G.state = &"play"
						G.tchoice = {}
						G.choice = {}
					low = minf(low, e.hp)
					if ticks % 600 == 0:
						trace.append(int(e.hp))
					ticks += 1
				var dead := e.hp <= 0 or not G.enemies.has(e)
				if not dead:
					bad += 1
					print("[elite] ALIVE floor %d %s %s: hp %d of %d (lowest %d), every 10 s %s, armor %.0f, guard %.1f, stage %d, state %s" % [
						fl + 1, type, e.traits, int(e.hp), int(hp0), int(low), trace, e.armor, e.guard_t, e.stage, e.state])
	print("[elite] %d fights, %d elites still alive after 60 s" % [n, bad])
	get_tree().quit()
