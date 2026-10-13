#!/bin/bash
# usage: launch.sh <exportdir> <label> [extra game args]
# Wall-clock time of launching an exported build and quitting after its 6th frame: once with an
# empty shader cache (a first launch), then five more times with the cache the first run left.
S=/tmp/claude-0/-home-claude/b5a8ad34-b7fb-5322-85f2-786358ca3d0f/scratchpad
D=$1; L=$2; shift 2
H=$S/fakehome_$L; rm -rf $H; mkdir -p $H
out=""
for i in 0 1 2 3 4 5; do
  t0=$(date +%s%N)
  ( cd $S/$D && HOME=$H XDG_DATA_HOME=$H/data XDG_CACHE_HOME=$H/cache xvfb-run -a -s "-screen 0 1344x864x24" ./tb.x86_64 --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --quit-after 6 -- --no-save --seed=9 "$@" > $S/cold3/launch_$L.log 2>&1 )
  t1=$(date +%s%N)
  out="$out $(( (t1 - t0) / 1000000 ))"
done
echo "$L: first launch and five more (ms, including starting and stopping the X server):$out"
