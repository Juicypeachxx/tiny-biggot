#!/bin/bash
# usage: boot.sh <exportdir> <label> <runs> [game args] -> the [boot] timestamps of a first launch (empty
# shader cache) and of later launches (cache kept), one line per run.
S=/tmp/claude-0/-home-claude/b5a8ad34-b7fb-5322-85f2-786358ca3d0f/scratchpad
D=$1; L=$2; R=$3; shift 3
H=$S/fakehome_$L; rm -rf $H; mkdir -p $H
for i in $(seq 1 $R); do
  ( cd $S/$D && HOME=$H XDG_DATA_HOME=$H/data XDG_CACHE_HOME=$H/cache xvfb-run -a -s "-screen 0 1344x864x24" ./tb.x86_64 --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --quit-after 8 -- --no-save --seed=9 "$@" > $S/cold3/boot_$L.log 2>&1 )
  python3 - $S/cold3/boot_$L.log "$L run $i" <<'PY'
import re, sys
L = open(sys.argv[1], errors='replace').read()
def at(rx):
    m = re.search(rx, L)
    return m.group(1) if m else '?'
print("%-22s engine up %4s | atlas %-28s | sounds %-9s | scene ready %4s | frame 1 %4s, 2 %4s, 3 %4s, 4 %4s, 5 %4s, 6 %4s" % (sys.argv[2],
    at(r'Meta\._ready at (\d+) ms'), at(r'sprite atlas: (.*?)\n').replace('837 graphics ', ''), at(r'Snd: \d+ sounds loaded in ([\d.]+ ms)'), at(r'main\._ready at (\d+) ms'),
    at(r'frame 1 drawn at (\d+)'), at(r'frame 2 drawn at (\d+)'), at(r'frame 3 drawn at (\d+)'), at(r'frame 4 drawn at (\d+)'), at(r'frame 5 drawn at (\d+)'), at(r'frame 6 drawn at (\d+)')))
PY
done
