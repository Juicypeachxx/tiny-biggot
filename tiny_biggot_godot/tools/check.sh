#!/usr/bin/env bash
# Headless verification: import assets, compile every script, then run the
# main scene for a number of frames and fail on any script/engine error.
# Usage: GODOT=/path/to/godot tools/check.sh [frames] [extra args passed to the game after --]
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
# macOS has no `timeout`: run without a time limit there.
command -v timeout >/dev/null 2>&1 || timeout() { shift; "$@"; }
FRAMES="${1:-600}"
shift || true
LOG=$(mktemp)
status=0

echo "== import"
timeout 600 "$GODOT" --headless --path . --import >"$LOG" 2>&1 || true
if grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== compile all scripts"
timeout 900 "$GODOT" --headless --path . --quit-after 3000 res://tests/check_scripts.tscn 2>&1 | tee "$LOG" | tail -n 3
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== run main scene for $FRAMES frames"
"$GODOT" --headless --path . --fixed-fps 60 --quit-after "$FRAMES" -- "$@" >"$LOG" 2>&1
tail -n 5 "$LOG"
if grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== unit tests"
timeout 900 "$GODOT" --headless --path . --quit-after 3000 res://tests/unit_tests.tscn -- --no-save >"$LOG" 2>&1
tail -n 1 "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== the save file: whole or not at all, damaged ones turned down, the backup"
timeout 900 "$GODOT" --headless --path . --quit-after 6000 res://tests/save_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^\[save\]|save test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:|WARNING" "$LOG"; then status=1; fi

echo "== sprite atlas: the ready-made file is what packing the graphics gives now"
timeout 900 "$GODOT" --headless --path . --quit-after 400000 res://tests/atlas_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^\[atlas\]|atlas test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:|WARNING" "$LOG"; then status=1; fi

echo "== 10 s of play with the atlas packed at start-up instead, and with no atlas at all"
for extra in "--no-bake" "--no-atlas"; do
  "$GODOT" --headless --path . --fixed-fps 60 --quit-after 600 -- --bot --smart-bot --god --seed=6 --hero=2 --room=elite $extra --no-save >"$LOG" 2>&1
  grep "\[bot\]" "$LOG" | tail -n 1
  if grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi
done

echo "== item effects vs the original Ruby (tests/ruby_effects.json)"
timeout 900 "$GODOT" --headless --path . --quit-after 6000 res://tests/effects_test.tscn >"$LOG" 2>&1
grep "effects test" "$LOG"
if grep -E "MISMATCH|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== content test (spec section 11)"
timeout 900 "$GODOT" --headless --path . --quit-after 400000 res://tests/content_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^\[content\]|content test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== rift worlds and event rooms"
timeout 900 "$GODOT" --headless --path . --quit-after 400000 res://tests/rift_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^\[rift\]|rift test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== floors as a map: shape, walking every door, hidden rooms, the rift"
timeout 900 "$GODOT" --headless --path . --quit-after 600000 res://tests/map_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "map test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:|WARNING" "$LOG"; then status=1; fi

echo "== the rift bosses: every attack of both phases, their falls, the rift's doors"
timeout 900 "$GODOT" --headless --path . res://tests/bosses_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^\[bosses\]|bosses test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:|WARNING" "$LOG"; then status=1; fi

echo "== pets: each one's trick in a fight, growing, cages, swaps"
timeout 900 "$GODOT" --headless --path . res://tests/pets_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "pets test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:|WARNING" "$LOG"; then status=1; fi

echo "== the new weapons (4.6): each one's trick in a fight; 999 more projectiles stay within the caps"
timeout 900 "$GODOT" --headless --path . res://tests/arsenal_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "arsenal test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== the new gear and relics (4.7): each one in the moment it is made for; the sets; the new actions"
timeout 600 "$GODOT" --headless --path . res://tests/items_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "items test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== Heaven and Hell (4.7): the soul, the gate, both realms, their rulers, the page, the last boss"
timeout 600 "$GODOT" --headless --path . res://tests/realms_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "realms test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== every boss and mini-boss: its stages, unhurt while it breaks, its own drop (never in a random roll)"
timeout 600 "$GODOT" --headless --path . res://tests/bosses_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "bosses test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== elite traits (6.6): swift, plated, splitting, volatile, mending"
timeout 600 "$GODOT" --headless --path . res://tests/traits_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "traits test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== trophies (7.2): first falls per hero, embers, the starting rewards"
timeout 600 "$GODOT" --headless --path . res://tests/trophies_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "trophies test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== alignments (8.1): leads, devout, rest-stop shrines, the four spokes, a perk that holds while it leads"
timeout 600 "$GODOT" --headless --path . res://tests/align_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "align test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== stat stacking (8.3): every stat pickup, the attributes' side stats, a guardian's two"
timeout 600 "$GODOT" --headless --path . res://tests/stats_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "stats test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== fun and synergy traits (8.4): SUPER offers, family ranks, momentum's cap, the purse, the damage hooks"
timeout 600 "$GODOT" --headless --path . res://tests/supertraits_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "supertraits test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== chaos attacks (9.1): lasers, chains, circles only hurt after their warning; caps; the final bosses use them"
timeout 600 "$GODOT" --headless --path . res://tests/chaos_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "chaos test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== live descriptions (10.1): growing texts show their value now"
timeout 600 "$GODOT" --headless --path . res://tests/live_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "live test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== new events (10.2): frog, ritual, pawn shop, cups, lightning round"
timeout 600 "$GODOT" --headless --path . res://tests/events10_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "events10 test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== flails (10.4): the circling ball, the lash, more balls"
timeout 600 "$GODOT" --headless --path . res://tests/flail_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "flail test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== GLOOM and prism fans (11.2)"
timeout 600 "$GODOT" --headless --path . res://tests/gloom_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "gloom test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== the story (12): the Archivist's lines, milestones, rest stops"
timeout 600 "$GODOT" --headless --path . res://tests/story_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "story test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 13.1 key mapping (Options > KEYBOARD KEYS)"
timeout 300 "$GODOT" --headless --path . res://tests/keys_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "keys test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 13.2 armor sets: 3-piece step, completion, mastery, chasing pieces"
timeout 300 "$GODOT" --headless --path . res://tests/sets_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "sets test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 14.2 the WARDROBE page"
timeout 300 "$GODOT" --headless --path . res://tests/wardrobe_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "wardrobe test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 14.3 hidden trait combos"
timeout 300 "$GODOT" --headless --path . res://tests/combos_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "combos test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 15.1 fishing"
timeout 300 "$GODOT" --headless --path . res://tests/fishing_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "fishing test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 16 the rooms revamp: pots, coin heaps, powder kegs"
timeout 300 "$GODOT" --headless --path . res://tests/rooms_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "rooms test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 17.2 the camp"
timeout 300 "$GODOT" --headless --path . res://tests/camp_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "camp test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 19.2 more life in the camp"
timeout 300 "$GODOT" --headless --path . res://tests/camp_life_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "camp life test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 20.2 the camp grows, the quest board"
timeout 300 "$GODOT" --headless --path . res://tests/camp_build_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "camp build test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 21.1 voices: speech bubbles, barks, a foe that runs, the camp remembers"
timeout 300 "$GODOT" --headless --path . res://tests/barks_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "barks test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 21.2 rooms keep their story: remains, scorch marks, props that fall, crows"
timeout 300 "$GODOT" --headless --path . res://tests/remains_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "remains test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 21.3 the sound of each place: loops, footsteps, music in a fight and after"
timeout 300 "$GODOT" --headless --path . res://tests/ambience_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "ambience test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 21.4 life between the fights: a rival, your last hero's ghost, a lost traveller"
timeout 300 "$GODOT" --headless --path . res://tests/wanderers_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "wanderers test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 21.5 monsters with lives: sleepers, calls for help, moths, fire-dogs, greedy slimes"
timeout 300 "$GODOT" --headless --path . res://tests/lives_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "lives test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 21.6 the camp follows the iPad's clock; the cat's gift"
timeout 300 "$GODOT" --headless --path . res://tests/camp_clock_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "camp clock test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 22.1 weather and night in the dungeon"
timeout 300 "$GODOT" --headless --path . res://tests/weather_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "weather test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 22.2 the endless descent"
timeout 300 "$GODOT" --headless --path . res://tests/endless_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "endless test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 22.3 the bestiary and past runs"
timeout 300 "$GODOT" --headless --path . res://tests/bestiary_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "bestiary test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 23.1 the spellbook: twenty magic weapons"
timeout 900 "$GODOT" --headless --path . res://tests/spells_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "spells test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 23.2 his slow fight: merged shots, giant shots, the proc index, poison pools"
timeout 300 "$GODOT" --headless --path . res://tests/heavy_build_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "heavy build test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 30.1 every oath's vow kept: each oath awakens once, then fights with its new powers"
timeout 300 "$GODOT" --headless --path . res://tests/oaths_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "oaths test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 31 the toybox: every new weapon fired in a live fight, each kind doing its thing"
timeout 300 "$GODOT" --headless --path . res://tests/toys_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "toys test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 33.1 the mind field: halos that grow with INT, the surge, the Horizon Ring, the Mindwarden"
timeout 300 "$GODOT" --headless --path . res://tests/auras_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^\[auras\]|auras test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 33.2 the tavern: tipsy, the drinks, sure strike, last orders, the Tavern Knight"
timeout 300 "$GODOT" --headless --path . res://tests/tavern_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^\[tavern\]|tavern test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 34.1 the trigger path: lucky hits, the spell slot, static build-up, the Trickshot"
timeout 300 "$GODOT" --headless --path . res://tests/trigger_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^\[trigger\]|trigger test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 34.2 the legion path: companion damage, speed and cap for every helper, the Bonecaller"
timeout 300 "$GODOT" --headless --path . res://tests/legion_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^\[legion\]|legion test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 35.1 dice: reroll, alter and banish on picks, the backpack and the shop's dice cup"
timeout 300 "$GODOT" --headless --path . res://tests/dice_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^dice:|dice test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 18.1 the daily trial"
timeout 300 "$GODOT" --headless --path . res://tests/daily_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "daily test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== the ten heroes of 4.8: data, each passive and special in a fight, every branch node"
timeout 600 "$GODOT" --headless --path . res://tests/heroes_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "heroes test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== the constellation: the web, taking and giving back stars, a run with them"
timeout 300 "$GODOT" --headless --path . res://tests/stars_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "stars test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:|WARNING" "$LOG"; then status=1; fi

echo "== the twenty new foes: data, and each one's own trick"
timeout 900 "$GODOT" --headless --path . --quit-after 400000 res://tests/foes_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^\[foes\]|foes test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:|WARNING" "$LOG"; then status=1; fi

echo "== the Gaolbird (starter hero): tempo, rally, rolls, dive"
timeout 900 "$GODOT" --headless --path . --quit-after 400000 res://tests/gaolbird_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^\[gaolbird\]|gaolbird test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== the Gaolbird on screen (30 s: full tempo and tree, a hit, dives, feathers; every painter runs)"
"$GODOT" --headless --path . --fixed-fps 60 --quit-after 1800 -- --bot --smart-bot --seed=3 --hero=6 --unlock-all --room=elite --tempo=10 --hurt-at=240 --no-save >"$LOG" 2>&1
grep "\[bot\]" "$LOG" | tail -n 1
if grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== ability effects: drawing only, bounded, every painter"
timeout 900 "$GODOT" --headless --path . --quit-after 400000 res://tests/vfx_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^\[vfx\]|vfx test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== attack effects: shot rules, class tables, drawing only, bounded, every painter"
timeout 900 "$GODOT" --headless --path . --quit-after 400000 res://tests/afx_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^\[afx\]|afx test" "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== guardian attacks on screen (20 s each: charges and lanes, beams and blinks, slams)"
for fl in 3 5 0; do
  "$GODOT" --headless --path . --fixed-fps 60 --quit-after 1200 -- --bot --smart-bot --god --seed=4 --hero=6 --floor=$fl --room=boss --no-save >"$LOG" 2>&1
  grep "\[bot\]" "$LOG" | tail -n 1
  if grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi
done

echo "== a new weapon every second for 100 s (fills the shot class tables), fast and plain drawing"
for extra in "" "--plain-draw"; do
  "$GODOT" --headless --path . --fixed-fps 60 --quit-after 6000 -- --bot --smart-bot --god --unlock-all --seed=3 --hero=12 --weapon-cycle=1 $extra --no-save >"$LOG" 2>&1
  grep "\[bot\]" "$LOG" | tail -n 1
  if grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi
done

echo "== ability effects in a heavy fight (30 s: every effect in turn; then 15 s with FANCY EFFECTS off)"
"$GODOT" --headless --path . --fixed-fps 60 --quit-after 1800 -- --bot --smart-bot --god --seed=5 --hero=11 --floor=6 --weapon=worldeater --heavy --fx-demo --no-save >"$LOG" 2>&1
grep "\[bot\]" "$LOG" | tail -n 1
if grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi
"$GODOT" --headless --path . --fixed-fps 60 --quit-after 900 -- --bot --smart-bot --god --seed=5 --hero=11 --floor=6 --weapon=worldeater --heavy --fx-demo --no-vfx --no-save >"$LOG" 2>&1
grep "\[bot\]" "$LOG" | tail -n 1
if grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== bot soak (60 s, god mode, boss room on floor 3)"
"$GODOT" --headless --path . --fixed-fps 60 --quit-after 3600 -- --bot --smart-bot --god --seed=1 --floor=2 --room=boss >"$LOG" 2>&1
grep "\[bot\]" "$LOG" | tail -n 1
if grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== deterministic replays vs recorded baselines"
GODOT="$GODOT" tools/replay.sh check || status=1

rm -f "$LOG"
[ $status -eq 0 ] && echo "CHECK PASSED" || echo "CHECK FAILED"
exit $status
