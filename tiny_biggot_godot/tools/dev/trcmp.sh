#!/bin/bash
# usage: trcmp.sh <label> <ticks> [args]  -> runs the same seeded bot fight in the previous build (base6) and this one,
# and compares their game-state traces (one line a second: hero, foes, random-number-dependent state).
S=/tmp/claude-0/-home-claude/b5a8ad34-b7fb-5322-85f2-786358ca3d0f/scratchpad
G=$S/godot/Godot_v4.6.1-stable_linux.x86_64
L=$1; N=$2; shift 2
for d in base6 work; do
  (cd $S/$d && timeout 300 $G --headless --path . --fixed-fps 60 --quit-after $N -- --no-save --bot --smart-bot "$@" --trace=$S/det/${L}_$d.trace > $S/det/${L}_$d.log 2>&1) &
done
wait
e=$(grep -cE "SCRIPT ERROR|ERROR:" $S/det/${L}_work.log)
if cmp -s $S/det/${L}_base6.trace $S/det/${L}_work.trace; then echo "$L: identical ($(wc -l < $S/det/${L}_work.trace) lines), errors $e"; else echo "$L: DIFFERS, errors $e"; diff $S/det/${L}_base6.trace $S/det/${L}_work.trace | head -4 | cut -c1-300; fi
