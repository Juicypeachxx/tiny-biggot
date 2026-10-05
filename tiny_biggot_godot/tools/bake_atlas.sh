#!/usr/bin/env bash
# Rebuilds the sprite atlas that comes with the project (assets/atlas/sprites.res) from
# assets/graphics/*.png, then checks it. The game does not need this (it notices at start-up
# that the file no longer fits and packs the atlas itself); it keeps the project's own file up
# to date, and tools/check.sh fails until it is.
# Usage: GODOT=/path/to/godot tools/bake_atlas.sh        Exit status: 0 only if written and checked.
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
# macOS has no `timeout`: run without a time limit there.
command -v timeout >/dev/null 2>&1 || timeout() { shift; "$@"; }
LOG=$(mktemp)
# New or changed graphics have to be imported before they can be packed.
timeout 600 "$GODOT" --headless --path . --import >/dev/null 2>&1 || true
timeout 600 "$GODOT" --headless --path . --quit-after 400000 res://tests/atlas_test.tscn -- --no-save --no-bake --bake >"$LOG" 2>&1
grep -E "^\[atlas\]|ERROR" "$LOG"
if ! grep -q "^\[atlas\] wrote .*: OK$" "$LOG" || grep -qE "SCRIPT ERROR|ERROR:" "$LOG"; then
  echo "bake FAILED"
  rm -f "$LOG"
  exit 1
fi
timeout 600 "$GODOT" --headless --path . --quit-after 400000 res://tests/atlas_test.tscn -- --no-save >"$LOG" 2>&1
grep -E "^\[atlas\]|atlas test|FAIL|ERROR" "$LOG"
status=0
if ! grep -q "^atlas test: PASSED$" "$LOG" || grep -qE "FAIL|SCRIPT ERROR|ERROR:|WARNING" "$LOG"; then status=1; fi
rm -f "$LOG"
exit $status
