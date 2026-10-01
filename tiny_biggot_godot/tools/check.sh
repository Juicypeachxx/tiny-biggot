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
"$GODOT" --headless --path . --quit-after 3000 res://tests/check_scripts.tscn 2>&1 | tee "$LOG" | tail -n 3
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== run main scene for $FRAMES frames"
"$GODOT" --headless --path . --fixed-fps 60 --quit-after "$FRAMES" -- "$@" >"$LOG" 2>&1
tail -n 5 "$LOG"
if grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== unit tests"
"$GODOT" --headless --path . --quit-after 3000 res://tests/unit_tests.tscn >"$LOG" 2>&1
tail -n 1 "$LOG"
if grep -E "FAIL|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== item effects vs the original Ruby (tests/ruby_effects.json)"
"$GODOT" --headless --path . --quit-after 6000 res://tests/effects_test.tscn >"$LOG" 2>&1
grep "effects test" "$LOG"
if grep -E "MISMATCH|SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== bot soak (60 s, god mode, boss room on floor 3)"
"$GODOT" --headless --path . --fixed-fps 60 --quit-after 3600 -- --bot --god --seed=1 --floor=2 --room=boss >"$LOG" 2>&1
grep "\[bot\]" "$LOG" | tail -n 1
if grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

rm -f "$LOG"
[ $status -eq 0 ] && echo "CHECK PASSED" || echo "CHECK FAILED"
exit $status
