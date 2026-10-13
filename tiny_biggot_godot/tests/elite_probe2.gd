extends Node
## Diagnosis 2 (his report, 9 Oct: "in early stage some elites are immortal"): the bot plays the
## first floors with many heroes; every elite that stays alive more than 40 s in the room with
## the hero is printed with what it was doing. Not part of check.sh.

func _ready() -> void:
	await get_tree().process_frame
	var heroes := GameData.heroes().size()
	var found := 0
	var elites_seen := 0
	for h in heroes:
		seed(1000 + h)
		G.hero_index = h
		G.new_run()
		G.god = true
		var bot := DebugBot.new()
		var born := {}
		var reported := {}
		for t in 60 * 240:   # 4 minutes of play each
			bot.tick()
			Keys.tick()
			G.update(TB.DT)
			if G.state == &"play" and G.room != null:
				for e: Enemy in G.enemies:
					if not e.elite or e.is_boss():
						continue
					if not born.has(e.uid):
						born[e.uid] = t
						elites_seen += 1
					var age: int = t - born[e.uid]
					if age > 60 * 40 and not reported.has(e.uid):
						reported[e.uid] = true
						found += 1
						print("[elite2] hero %s floor %d room %s: %s %s alive %ds, hp %d/%d, spawn_t %.1f hidden %s state %s guard %.1f armor %.0f stage %d asleep %s fleeing %s pos (%d,%d) tile %d" % [
							GameData.heroes()[h]["id"], G.floor_index + 1, G.room.type, e.type, e.traits, age / 60, int(e.hp), int(e.max_hp),
							e.spawn_t, e.hidden, e.state, e.guard_t, e.armor, e.stage, e.asleep, e.get("fleeing"), int(e.x), int(e.y),
							G.room.tile(floori(e.x / TB.TS), floori(e.y / TB.TS))])
			if G.floor_index >= 3:
				break
	print("[elite2] %d heroes, %d elites seen, %d alive past 40 s" % [heroes, elites_seen, found])
	get_tree().quit()
