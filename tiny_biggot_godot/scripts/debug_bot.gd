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
		if a in [&"roll", &"use", &"heal", &"bomb", &"pause"]:
			_hold(a, false)
	if G.state != &"play":
		_tap(&"use", 0.05)
		for a in [&"move_left", &"move_right", &"move_up", &"move_down"]:
			_hold(a, false)
		if G.state == &"dead":
			_count_death()
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
		_target = World.door_center(_door)
	elif _retarget <= 0:
		_retarget = 1.0 + randf()
		_target = World.free_spot(G.room, null, 0)
	var v := _target - Vector2(p.x, p.y)
	_hold(&"move_left", v.x < -4)
	_hold(&"move_right", v.x > 4)
	_hold(&"move_up", v.y < -4)
	_hold(&"move_down", v.y > 4)
	_tap(&"roll", 0.01)
	_tap(&"heal", 0.002)
	_tap(&"bomb", 0.003)
	if ticks % 600 == 0:
		print("[bot] t=%ds floor=%d rooms=%d deaths=%d hp=%d/%d room=%s" % [ticks / 60, G.floor_index + 1,
			rooms, deaths, p.hp, p.max_hp, G.room.type])

var _dead_counted := false
func _count_death() -> void:
	if not _dead_counted:
		_dead_counted = true
		deaths += 1
