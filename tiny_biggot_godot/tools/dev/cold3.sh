#!/bin/bash
# usage: cold3.sh <exportdir> <label> <frames> [args]
# One run of an exported build with an empty shader cache (a first launch), under the GL shim that
# counts shader program links per frame. Prints: stalls at launch (first 5 frames) and in play.
S=/tmp/claude-0/-home-claude/b5a8ad34-b7fb-5322-85f2-786358ca3d0f/scratchpad
D=$1; L=$2; N=$3; shift 3
rm -rf $S/fakehome; mkdir -p $S/fakehome $S/cold3
( cd $S/$D && HOME=$S/fakehome XDG_DATA_HOME=$S/fakehome/data GLSHIM_LOG=$S/cold3/$L.txt LD_PRELOAD=$S/glshim/glshim.so xvfb-run -a -s "-screen 0 1344x864x24" ./tb.x86_64 --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --quit-after $N -- --no-save --seed=9 --hitch-log=9 "$@" > $S/cold3/$L.log 2>&1 )
python3 - $S/cold3/$L.log $S/cold3/$L.txt "$L" <<'PY'
import re, sys
L = open(sys.argv[1], errors='replace').read().splitlines()
h = []
for l in L:
    m = re.search(r'\[hitch\] frame (\d+) \(tick \d+\): ([\d.]+) ms', l) or re.search(r'\[hitch\] tick (\d+): ([\d.]+) ms', l)
    if m: h.append((int(m.group(1)), float(m.group(2))))
launch = [x for x in h if x[0] <= 5]
play = [x for x in h if x[0] > 5]
b33 = [x for x in play if x[1] >= 33.4]
b40 = [x for x in play if x[1] >= 40.0]
links = []
for l in open(sys.argv[2], errors='replace'):
    m = re.match(r'frame (\d+): (\d+) programs linked.*?([\d.]+) ms', l)
    if m: links.append((int(m.group(1)), int(m.group(2)), float(m.group(3))))
late = [x for x in links if x[0] > 5]
w = [float(m.group(1)) for l in L for m in [re.search(r'\[white\] .*total ([\d.]+) ms', l)] if m]
s = [float(m.group(1)) for l in L for m in [re.search(r'\[sndload\] .*: ([\d.]+) ms', l)] if m]
errs = [l for l in L if ('ERROR' in l or 'SCRIPT' in l) and 'resources still in use' not in l]
print("%-18s launch stalls %4.0f ms | in play: %2d frames >=33 ms, %2d >=40 ms, worst %5.1f, lost %5.0f ms | programs built in play: %d (%.0f ms) at frames %s | readbacks %d (%.1f ms) sounds on first use %d (%.1f ms) | errors %d" % (
    sys.argv[3], sum(x[1] for x in launch), len(b33), len(b40), max([x[1] for x in play] or [0]), sum(x[1] - 16.7 for x in b33),
    sum(x[1] for x in late), sum(x[2] for x in late), ','.join(str(x[0]) for x in late) or '-', len(w), sum(w), len(s), sum(s), len(errs)))
PY
