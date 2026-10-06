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
##   --monkey                     random buttons in every menu and in play, seeded by --seed (ROADMAP 4.10)
##   --smart-bot                  with --bot: detours when stuck, hunts far foes, rings challenge bells
##   --touch                      show the touch controls on a desktop (mouse = finger)
##   --god                        the player takes no damage (soak tests)
##   --weapon=ID                  start with this weapon (see data/weapons.gd)
##   --weapon-cycle=SECONDS       switch to the next weapon every N seconds (soak tests)
##   --ui=SCREEN                  open a screen at start: choice, traits, title, hero, tree, shrine,
##                                codex, howto, options, pause, traitlist, gearpage, relics, dead, win,
##                                stars (the constellation),
##                                ending (the true-ending room with the loop and exit portals)
##   --no-save                    neither read nor write the save file, nor the sprite atlas the game keeps for
##                                itself (repeatable test runs)
##   --unlock-all                 every shrine unlock and every skill-tree node, all 30 constellation points
##   --rex                        start a run in Rex's barn (the hidden boss, scripts/entities/rex.gd)
##   --pet=ID[:LEVEL]             start with a pet (scripts/entities/pets.gd), level 1 to 3
##   --spawn=TYPE                 put one foe of that type (GameData.ENEMIES) in the middle of the room
##   --give=relic:ID,gear:ID,...  start with these items (relic, gear, trait at max rank, weapon)
##   --combo=ID                   start with everything a named combo needs (data/synergies.gd)
##   --loop=N                     start on loop playthrough N (0 = first time through)
##   --classic                    original items only in every pool (no Rogues content)
##   --trace=FILE                 write one line of game state per second (replay comparison)
##   --bench[=N]                  keep ~N enemy shots alive and print logic time per tick
##   --hitch-log=MS               print every frame that took longer than MS milliseconds
##   --objects                    print the engine's object count once a minute of game time (leak soaks)
##   --no-warmup                  skip the launch warm-up (scripts/render/warmup.gd)
##   --no-bake                    pack the sprite atlas at start-up instead of loading a ready-made one
##   --no-atlas                   no sprite atlas at all: every graphic is its own texture

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
