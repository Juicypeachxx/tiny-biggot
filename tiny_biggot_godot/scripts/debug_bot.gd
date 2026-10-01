class_name DebugBot
extends RefCounted
## Autopilot for headless soak tests (--bot). It presses the same input
## actions a player would: walks to an open door (or wanders while the room
## is locked), rolls, heals, drops bombs and restarts after death. It prints a
## summary every few seconds so long runs can be checked from the log.

var _target := Vector2.ZERO
var _retarget := 0.0
var _door := ""
var _room: Room = null
var _held := {}
var rooms := 0
var deaths := 0
var ticks := 0

func _hold(action: StringName, on: bool) -> void:
	if on and not _held.get(action, false):
		Input.action_press(action)
	elif not on and _held.get(action, false):
		Input.action_release(action)
	_held[action] = on

func _tap(action: StringName, chance: float) -> void:
	_hold(action, randf() < chance)

func tick() -> void:
	ticks += 1
	for a in Keys.ACTIONS:
		if a in [&"roll", &"use", &"heal", &"bomb", &"pause", &"special"]:
			_hold(a, false)
	if G.state != &"play":
		_tap(&"use", 0.05)
		for a in [&"move_left", &"move_right", &"move_up", &"move_down"]:
			_hold(a, false)
		if G.state == &"dead":
			_count_death()
		if G.state == &"win" and not _won:
			_won = true
			print("[bot] VICTORY at t=%ds" % [ticks / 60])
		return
	_dead_counted = false
	var p := G.player
	if G.room != _room:
		_room = G.room
		rooms += 1
		_door = ""
	if _door == "" and not G.locked:
		var open := []
		for d in G.room.exits:
			if not G.room.sealed.has(d):
				open.append(d)
		if open.size() > 0:
			_door = open[randi() % open.size()]
	_retarget -= TB.DT
	if _door != "" and not G.locked:
		# Aim past the door so the player crosses the exit line.
		var dv: Vector2i = World.DIRS[_door]
		_target = World.door_center(_door) + Vector2(dv) * 24
	elif _retarget <= 0:
		_retarget = 1.0 + randf()
		_target = World.free_spot(G.room, null, 0)
	var v := _target - Vector2(p.x, p.y)
	_hold(&"move_left", v.x < -4)
	_hold(&"move_right", v.x > 4)
	_hold(&"move_up", v.y < -4)
	_hold(&"move_down", v.y > 4)
	if G.prompt != null:
		_tap(&"use", 0.1)
	_tap(&"roll", 0.01)
	_tap(&"heal", 0.002)
	_tap(&"bomb", 0.003)
	# New heroes: use the special as soon as it is ready in a fight. No random
	# draw here, so runs with the original heroes replay exactly as before.
	if Abilities.ready(p) and G.enemies_active():
		_hold(&"special", true)
	if ticks % 600 == 0:
		var gear_n := 0
		for g in p.gear.values():
			if g != null:
				gear_n += 1
		print("[bot] t=%ds floor=%d rooms=%d deaths=%d hp=%d/%d room=%s lv=%d relics=%d traits=%d gear=%d weapon=%s gold=%d" % [
			ticks / 60, G.floor_index + 1, rooms, deaths, p.hp, p.max_hp, G.room.type, p.level, p.relics.size(),
			p.traits.size(), gear_n, p.weapon["id"], p.gold])
		if DebugArgs.has("bot-verbose"):
			var es := []
			for e in G.enemies:
				es.append("%s(%d,%d hp=%.0f sp=%.1f hid=%s st=%s)" % [e.type, e.x, e.y, e.hp, e.spawn_t, e.hidden, e.state])
			print("      locked=%s waves=%d pb=%d eb=%d player=(%d,%d) inv=%.1f enemies=%s" % [G.locked, G.room.waves_left,
				G.pbullets.size(), EBullets.n, p.x, p.y, p.invuln, ", ".join(es)])

var _dead_counted := false
var _won := false
func _count_death() -> void:
	if not _dead_counted:
		_dead_counted = true
		deaths += 1
