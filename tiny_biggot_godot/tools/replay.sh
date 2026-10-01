#!/usr/bin/env bash
# Deterministic replay check. `record` writes baseline traces; `check` reruns
# the same seeded autopilot scenarios and fails if any trace line differs.
# Traces hold the full logic state once per second (scripts/trace.gd), so
# a refactor that changes behaviour, or even the number of random rolls,
# is caught. Usage: GODOT=... tools/replay.sh record|check [ticks]
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
MODE="${1:-check}"
TICKS="${2:-18000}"
SCEN=(
  "a --bot --seed=101 --hero=0"
  "b --bot --god --unlock-all --seed=102 --hero=3"
  "c --bot --god --seed=103 --hero=5 --weapon-cycle=4"
  "d --bot --unlock-all --seed=104 --hero=2"
  "e --bot --god --unlock-all --seed=105 --hero=4 --floor=3"
  "f --bot --god --seed=106 --hero=1 --floor=5 --room=boss"
)
status=0
for s in "${SCEN[@]}"; do
  name=${s%% *}; args=${s#* }
  out=tests/replays/$name.txt
  [ "$MODE" = check ] && out=$(mktemp)
  "$GODOT" --headless --path . --fixed-fps 60 --quit-after "$TICKS" -- --no-save $args --trace="$(realpath -m "$out")" >/dev/null 2>&1
  if [ "$MODE" = check ]; then
    if cmp -s "$out" tests/replays/$name.txt; then echo "replay $name: identical ($(wc -l < "$out") s)"
    else echo "replay $name: DIFFERS"; diff <(cut -c1-300 tests/replays/$name.txt) <(cut -c1-300 "$out") | head -6; status=1; fi
    rm -f "$out"
  else echo "recorded $name ($(wc -l < "$out") lines)"; fi
done
exit $status
