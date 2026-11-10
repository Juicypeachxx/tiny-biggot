#!/bin/bash
# usage: coldrun2.sh <exportdir> <label> <frames> [args]  -> slow draw calls on a cold shader cache, with their GL state
S=/tmp/claude-0/-home-claude/b5a8ad34-b7fb-5322-85f2-786358ca3d0f/scratchpad
D=$1; L=$2; N=$3; shift 3
rm -rf $S/fakehome; mkdir -p $S/fakehome
( cd $S/$D && HOME=$S/fakehome XDG_DATA_HOME=$S/fakehome/data GLSHIM_SLOW=${SLOW:-15} GLSHIM_LOG=$S/glshim/$L.txt LD_PRELOAD=$S/glshim/glshim2.so xvfb-run -a -s "-screen 0 1344x864x24" ./tb.x86_64 --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --quit-after $N -- --no-save --seed=9 "$@" > $S/glshim/$L.log 2>&1 )
echo "== $L: $(grep -c 'took' $S/glshim/$L.txt) slow calls after frame 3: $(awk -F'[ :]' '$2 > 3' $S/glshim/$L.txt | grep -c took)"
