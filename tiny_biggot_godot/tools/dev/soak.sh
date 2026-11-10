#!/usr/bin/env bash
# Long soaks without a screen (ROADMAP 3.3): every hero (on floors 0-10 in turn; ten with a pet; $HEROES, default 30), all 11 rift
# worlds, --classic, FAST DRAWING and FANCY EFFECTS off, loops 1-3. Each run is TICKS of game
# time (default 36000 = 10 minutes) with the bot and --god, --weapon-cycle=1 in about half.
# Then one run of OBJ_TICKS (default 108000 = 30 minutes) prints the object count every minute.
# A run fails on any line with SCRIPT ERROR, ERROR: or WARNING.
# Usage: GODOT=/path/to/godot tools/dev/soak.sh [TICKS] [OBJ_TICKS]   (logs in $SOAK_DIR, default /tmp/soak)
set -u
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-godot}"
TICKS="${1:-36000}"
OBJ_TICKS="${2:-108000}"
OUT="${SOAK_DIR:-/tmp/soak}"
JOBS="${JOBS:-4}"
rm -rf "$OUT"; mkdir -p "$OUT"

runs=()
pets=(biscuit zappy cindertail bramble glimmer gulp gloop hoots snip kaboomba)
for h in $(seq 0 $((${HEROES:-30} - 1))); do   # 32.3: every hero (30 after Stage 31)
  wc=""; [ $((h % 2)) -eq 1 ] && wc="--weapon-cycle=1"
  pet=""; [ $h -lt 10 ] && pet="--pet=${pets[$h]}:$((h % 3 + 1))"
  runs+=("hero$h --hero=$h --floor=$((h % 11)) --seed=$((h + 1)) $wc $pet")
done
r=0
for w in gaol brand neon streets fog burb heist dust skyreach bastion cathedral; do
  wc=""; [ $((r % 2)) -eq 0 ] && wc="--weapon-cycle=1"
  runs+=("rift_$w --rift=$w --step=$((r % 3)) --hero=$(((r * 5) % 14)) --floor=$((r % 6)) --seed=$((20 + r)) $wc")
  r=$((r + 1))
done
runs+=("classic_a --classic --hero=0 --seed=40")
runs+=("classic_b --classic --hero=1 --floor=4 --seed=41 --weapon-cycle=1")
runs+=("plain_a --plain-draw --no-vfx --hero=3 --seed=50")
runs+=("plain_b --plain-draw --no-vfx --hero=8 --floor=6 --seed=51 --weapon-cycle=1")
# 55: the four final final bosses, fought from their arena (three forms, their followers).
al=(good law chaos evil)
for i in 0 1 2 3; do
  runs+=("finale_${al[$i]} --finale=${al[$i]} --hero=$((i * 7 + 3)) --floor=$((i * 3)) --seed=$((70 + i)) --weapon-cycle=1")
done
for l in 1 2 3; do
  wc=""; [ $l -ne 2 ] && wc="--weapon-cycle=1"
  runs+=("loop$l --loop=$l --hero=$((l + 9)) --floor=$((l * 3)) --seed=$((60 + l)) $wc")
done

one() {
  local name=$1; shift
  local t0=$(date +%s)
  "$GODOT" --headless --path . --fixed-fps 60 --quit-after "$TICKS" -- --no-save --bot --smart-bot --god "$@" >"$OUT/$name.log" 2>&1
  local code=$?
  local bad=$(grep -cE "SCRIPT ERROR|ERROR:|WARNING" "$OUT/$name.log")
  local last=$(grep "^\[bot\] t=" "$OUT/$name.log" | tail -n 1 | cut -c1-90)
  printf "%-12s exit=%d bad=%d %3ds  %s\n" "$name" "$code" "$bad" $(( $(date +%s) - t0 )) "$last"
}
export -f one; export GODOT TICKS OUT
printf "%s\n" "${runs[@]}" | xargs -P "$JOBS" -I{} bash -c 'one {}' | tee "$OUT/summary.txt"

echo "== objects, $((OBJ_TICKS / 3600)) minutes"
"$GODOT" --headless --path . --fixed-fps 60 --quit-after "$OBJ_TICKS" -- --no-save --bot --smart-bot --god --hero=5 --seed=77 --weapon-cycle=1 --objects >"$OUT/objects.log" 2>&1
grep "^\[objects\]" "$OUT/objects.log" | tee -a "$OUT/summary.txt"
grep -cE "SCRIPT ERROR|ERROR:|WARNING" "$OUT/objects.log" | sed 's/^/objects run bad lines: /' | tee -a "$OUT/summary.txt"

fails=$(grep -cE "exit=[1-9]|bad=[1-9]" "$OUT/summary.txt")
fails=$((fails + $(grep -cE "SCRIPT ERROR|ERROR:|WARNING" "$OUT/objects.log")))
echo "$(( ${#runs[@]} + 1 )) runs, $fails with a problem"
[ "$fails" -eq 0 ]
