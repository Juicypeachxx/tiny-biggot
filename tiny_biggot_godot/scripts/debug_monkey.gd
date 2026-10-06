class_name DebugMonkey
extends RefCounted
## Random input for every menu and for play (ROADMAP 4.10, "the monkey"; --monkey). Each tick it
## may press or let go of any button a player has (moves are held for a while, the rest tapped),
## from its own generator seeded by --seed, so a failure can be played again. It goes wherever
## the buttons take it: title, hero choice, shrine, skill tree, options, codex, runs, pauses,
## choices, deaths and wins. tools/dev/monkey.sh runs it for an hour of game time.

var _rng := RandomNumberGenerator.new()
var _held := {}
var _hold_t := {}
var ticks := 0
var states := {}   # how many ticks it spent in each game state (printed)

func _init() -> void:
	_rng.seed = DebugArgs.get_int("seed", 1) * 7919 + 13

func tick() -> void:
	ticks += 1
	states[String(G.state)] = states.get(String(G.state), 0) + 1
	for a in Keys.ACTIONS:
		var moving := String(a).begins_with("move_") or String(a).begins_with("aim_")
		if _held.get(a, false):
			_hold_t[a] = _hold_t.get(a, 0) - 1
			if _hold_t[a] <= 0:
				Input.action_release(a)
				_held[a] = false
		elif _rng.randf() < (0.02 if moving else (0.004 if a in [&"pause"] else 0.012)):
			Input.action_press(a)
			_held[a] = true
			_hold_t[a] = _rng.randi_range(20, 90) if moving else _rng.randi_range(1, 4)
	if ticks % 3600 == 0:
		print("[monkey] t=%dm state=%s floor=%d states=%s" % [ticks / 3600, G.state, G.floor_index + 1, states])
