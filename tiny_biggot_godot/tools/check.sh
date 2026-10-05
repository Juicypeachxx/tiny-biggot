#!/usr/bin/env bash
# Headless verification: import assets, compile every script, then run the
# main scene for a number of frames and fail on any script/engine error.
# Usage: GODOT=/path/to/godot tools/check.sh [frames] [extra args passed to the game after --]
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
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
timeout 900 "$GODOT" --headless --path . --quit-after 3000 res://tests/unit_tests.tscn >"$LOG" 2>&1
tail -n 1 "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

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
