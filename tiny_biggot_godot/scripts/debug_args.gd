class_name DebugArgs
extends RefCounted
## Command-line options for testing, passed after `--`:
##   --shot=res_or_abs_path.png   save a screenshot ...
##   --shot-frame=N               ... after N logic ticks, then quit
##   --hero=N                     hero index; starts a run straight away (skips the title)
##   --quick                      start a run straight away with the default hero
##   --floor=N                    start on floor N (0-5)
##   --room=KIND                  jump straight into a room of that type (combat, boss, mini, ...)
##   --seed=N                     fixed random seed
##   --bot                        autopilot that moves, aims and rolls (soak test)
##   --smart-bot                  with --bot: detours when stuck, hunts far foes, rings challenge bells
##   --touch                      show the touch controls on a desktop (mouse = finger)
##   --god                        the player takes no damage (soak tests)
##   --weapon=ID                  start with this weapon (see data/weapons.gd)
##   --weapon-cycle=SECONDS       switch to the next weapon every N seconds (soak tests)
##   --ui=SCREEN                  open a screen at start: choice, traits, title, hero, tree, shrine,
##                                codex, howto, options, pause, traitlist, gearpage, relics, dead, win,
##                                ending (the true-ending room with the loop and exit portals)
##   --no-save                    neither read nor write the save file (repeatable test runs)
##   --unlock-all                 every shrine unlock and every skill-tree node
##   --give=relic:ID,gear:ID,...  start with these items (relic, gear, trait at max rank, weapon)
##   --combo=ID                   start with everything a named combo needs (data/synergies.gd)
##   --loop=N                     start on loop playthrough N (0 = first time through)
##   --classic                    original items only in every pool (no Rogues content)
##   --trace=FILE                 write one line of game state per second (replay comparison)
##   --bench[=N]                  keep ~N enemy shots alive and print logic time per tick

static var _args := {}
static var _parsed := false

static func _parse() -> void:
	if _parsed:
		return
	_parsed = true
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			_args[kv[0]] = kv[1] if kv.size() > 1 else "1"

static func has(k: String) -> bool:
	_parse()
	return _args.has(k)

static func get_str(k: String, def: String = "") -> String:
	_parse()
	return _args.get(k, def)

static func get_int(k: String, def: int = 0) -> int:
	_parse()
	return int(_args[k]) if _args.has(k) else def
