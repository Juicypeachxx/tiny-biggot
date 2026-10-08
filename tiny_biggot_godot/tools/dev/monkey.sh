#!/usr/bin/env bash
# ROADMAP 4.10: random buttons in every menu and in play (--monkey). One hour of game time from the
# title screen (with the object count printed every minute, for leaks), then ten shorter runs that
# start in the new content (new heroes, the late floors, the realms, Brazil, Rex, a loop; 22.4: the endless
# stair, night and storm floors, the wanderers, Chapter IV).
# A run fails on any line with SCRIPT ERROR, ERROR: or WARNING.
# Usage: GODOT=/path/to/godot tools/dev/monkey.sh [MINUTES] [SHORT_MINUTES]   (logs in $MONKEY_DIR, default /tmp/monkey)
set -u
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-godot}"
MIN="${1:-60}"
SHORT="${2:-6}"
OUT="${MONKEY_DIR:-/tmp/monkey}"
rm -rf "$OUT"; mkdir -p "$OUT"
one() {
  local name=$1 ticks=$2; shift 2
  "$GODOT" --headless --path . --fixed-fps 60 --quit-after "$ticks" -- --no-save --monkey "$@" >"$OUT/$name.log" 2>&1
  local bad=$(grep -cE "SCRIPT ERROR|ERROR:|WARNING" "$OUT/$name.log")
  printf "%-10s bad=%d  %s\n" "$name" "$bad" "$(grep '^\[monkey\]' "$OUT/$name.log" | tail -n 1 | cut -c1-150)"
}
export -f one; export GODOT OUT
runs=("hour $((MIN * 3600)) --seed=1 --objects")
s=$((SHORT * 3600))
runs+=("hero14 $s --seed=2 --hero=14" "hero17 $s --seed=3 --hero=17 --floor=4" "hero21 $s --seed=4 --hero=21 --floor=8")
runs+=("floor10 $s --seed=5 --hero=6 --floor=9" "heaven $s --seed=6 --hero=3 --floor=10 --rift=heaven --step=3")
runs+=("hell $s --seed=7 --hero=8 --floor=10 --rift=hell --step=0" "brazil $s --seed=8 --hero=11 --floor=3 --rift=brazil --step=0")
runs+=("rex $s --seed=9 --rex --hero=2" "loop $s --seed=10 --loop=1 --hero=12 --floor=2" "classic $s --seed=11 --classic")
# Stage 21-22: the endless stair, night and storm floors, the wanderers, Chapter IV.
runs+=("endless $s --seed=12 --endless --hero=5" "night $s --seed=13 --hero=7 --floor=3 --weather=dark")
runs+=("storm $s --seed=14 --hero=9 --floor=6 --weather=storm" "chapter4 $s --seed=15 --chapter=4 --floor=1 --hero=4")
runs+=("wander $s --seed=16 --wanderer --floor=2 --hero=10")
printf "%s\n" "${runs[@]}" | xargs -P 4 -I{} bash -c 'one {}' | tee "$OUT/summary.txt"
grep "^\[objects\]" "$OUT/hour.log" | sed -n '1p;$p'
fails=$(grep -cE "bad=[1-9]" "$OUT/summary.txt")
echo "$(( ${#runs[@]} )) runs, $fails with a problem"
[ "$fails" -eq 0 ]
