#!/bin/bash
# usage: sweep2.sh <exportdir> <tag>  -> for many scenes, each on an empty shader cache: GL draw calls that took
# over 12 ms after the 3rd frame (a first-use stall the launch warm-up did not cover), and error lines.
S=/tmp/claude-0/-home-claude/b5a8ad34-b7fb-5322-85f2-786358ca3d0f/scratchpad
D=$1; T=$2; O=$S/sweep2_$T; rm -rf $O; mkdir -p $O
one() { # label frames args...
  L=$1; N=$2; shift 2
  rm -rf $S/fakehome; mkdir -p $S/fakehome
  ( cd $S/$D && HOME=$S/fakehome XDG_DATA_HOME=$S/fakehome/data GLSHIM_SLOW=12 GLSHIM_LOG=$O/$L.txt LD_PRELOAD=$S/glshim/glshim2.so xvfb-run -a -s "-screen 0 1344x864x24" timeout -s KILL 200 ./tb.x86_64 --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --quit-after $N -- --no-save --seed=9 "$@" > $O/$L.log 2>&1 )
  late=$(awk -F'[ :]' '$2 > 3' $O/$L.txt | grep -c took)
  errs=$(grep -E "ERROR|SCRIPT" $O/$L.log | grep -vc "resources still in use")
  echo "$L: slow calls at launch $(awk -F'[ :]' '$2 <= 3' $O/$L.txt | grep -c took), after frame 3: $late, errors $errs"
  if [ "$late" != "0" ]; then awk -F'[ :]' '$2 > 3' $O/$L.txt | grep took | cut -c1-260 | head -6; fi
}
B="--bot --smart-bot --god"
one heavy 1800 $B --hero=11 --floor=6 --weapon=worldeater --heavy --fx-demo
for fl in 0 1 2 3 4 5 6 7 8 9 10; do one boss$fl 1200 $B --unlock-all --hero=$((fl % 14)) --floor=$fl --room=boss; done
k=0; for r in gaol brand neon streets fog burb heist dust; do one rift_$r 900 $B --unlock-all --hero=$(((k + 3) % 14)) --floor=$((k % 6)) --rift=$r --step=2; k=$((k+1)); done
one title 300
for u in choice traits hero tree shrine codex howto options pause traitlist gearpage relics dead win ending inventory card; do one ui_$u 240 --ui=$u; done
one touch 900 $B --touch --hero=2 --room=elite
one plain 900 $B --unlock-all --hero=12 --weapon-cycle=1 --plain-draw
one novfx 900 $B --unlock-all --hero=12 --weapon-cycle=1 --no-vfx
one classic 900 $B --classic --hero=5 --floor=3 --room=boss
one gaolbird 1200 $B --hero=6 --unlock-all --room=elite --tempo=10 --hurt-at=240
one melee 900 $B --unlock-all --hero=3 --room=elite --attack-every=20
one run6 2400 $B --unlock-all --hero=8
echo "sweep done"
