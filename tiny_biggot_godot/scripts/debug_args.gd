class_name DebugArgs
extends RefCounted
## Command-line options for testing, passed after `--`:
##   --shot=res_or_abs_path.png   save a screenshot ...
##   --shot-frame=N               ... after N logic ticks, then quit
##   --hero=N                     hero index; starts a run straight away (skips the title)
##   --quick                      start a run straight away with the default hero
##   --floor=N                    start on floor N (0-5)
##   --day=YYYYMMDD               the daily trial of that date (18.1)
##   --set=ID                     start wearing a whole armor set (13.2), e.g. --set=emberweave
##   --chapter=2|3|4              Chapter II, III or IV: --floor=0-2 are its three floors (12.2, 14.4, 20.3)
##   --room=KIND                  jump straight into a room of that type (combat, boss, mini, ...)
##   --seed=N                     fixed random seed
##   --bot                        autopilot that moves, aims and rolls (soak test)
##   --monkey                     random buttons in every menu and in play, seeded by --seed (ROADMAP 4.10)
##   --smart-bot                  with --bot: detours when stuck, hunts far foes, rings challenge bells
##   --boss-clock                 print "[clock] ..." when a guardian falls: its floor, how many seconds it
##                                lasted, its health and the hero's build (56.1; tests/boss_clock.tscn times them)
##   --touch                      show the touch controls on a desktop (mouse = finger)
##   --god                        the player takes no damage (soak tests)
##   --dread=N                    DREAD level N opened and picked (48.1: up to 16; 5 in classic)
##   --weapon=ID                  start with this weapon (see data/weapons.gd)
##   --weapon-cycle=SECONDS       switch to the next weapon every N seconds (soak tests)
##   --ui=SCREEN                  open a screen at start: choice, traits, title, hero, tree, shrine, options, keys,
##                                codex, howto, options, pause, traitlist, gearpage, relics, dead, win,
##                                stars (the constellation), camp, kitchen, armory, plans, board (the camp;
##                                22.3: codex, bestiary, runs (the codex on a page);
##                                --camp-built: all its upgrades, --camp-fish: a full larder, --camp-near=KIND),
##                                ending (the true-ending room with the loop and exit portals);
##                                (Windows co-op) coop: the CO-OP screen with three joined, coopkeys: with
##                                two on the keyboard, coopgear: with --coop=N, P2's gear page as theirs
##   --coop=N                     (Windows co-op) N heroes in the run, P2 on played by the test bot
##   --no-save                    neither read nor write the save file, nor the sprite atlas the game keeps for
##                                itself (repeatable test runs)
##   --unlock-all                 every shrine unlock and every skill-tree node, all 30 constellation points
##   --rex                        start a run in Rex's barn (the hidden boss, scripts/entities/rex.gd)
##   --finale=good|evil|law|chaos 55: start in the arena of the final final boss of that alignment (finale.gd)
##   --no-finale                  55: a won run ends at once, without the final final boss (tests)
##   --finale-form=2|3            55: with --finale, the boss starts in its second or third form (pictures)
##   --endless                    22.2: the run is an endless descent
##   --weather=KIND               22.1: every floor after the first gets this weather (rain storm fog snow ash dark)
##   --clock=H                    21.6: the camp at hour H (0-23) instead of the iPad's clock
##   --wanderer                   21.4: a cleared fight room with a rival and their chest, a lost traveller and a ghost
##   --pet=ID[:LEVEL]             start with a pet (scripts/entities/pets.gd), level 1 to 3
##   --trait-opts=ID,ID,ID        with --ui=traits: the traits offered (pictures); with --ui=tome or
##                                tomefloor (41.5): the trait tome's trait
##   --spawn=TYPE                 put one foe of that type (GameData.ENEMIES) in the middle of the room
##   --neon                       turn the NEON LOOK option on (10.5)
##   --give=relic:ID,gear:ID,...  start with these items (relic, gear, trait at max rank, weapon)
##                                (also belt:KIND into the belt, drink:KIND a room draught already on: 49.2)
##   --combo=ID                   start with everything a named combo needs (data/synergies.gd)
##   --loop=N                     start on loop playthrough N (0 = first time through)
##   --classic                    original items only in every pool (no Rogues content)
##   --trace=FILE                 write one line of game state per second (replay comparison)
##   --bench[=N]                  keep ~N enemy shots alive and print logic time per tick
##   --hitch-log=MS               print every frame that took longer than MS milliseconds
##   --objects                    print the engine's object count once a minute of game time (leak soaks)
##   --no-warmup                  skip the launch warm-up (scripts/render/warmup.gd)
##   --no-bake                    pack the sprite atlas at start-up instead of loading a ready-made one
##   --no-floor-bake              draw the floor and the remains of fallen foes directly each frame (32.2), not baked into one picture
##   --calls-probe[=TICK]         at TICK (900) freeze the scene and print the draw calls each world layer costs (32.2)
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
