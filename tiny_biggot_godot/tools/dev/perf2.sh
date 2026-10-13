#!/bin/bash
# usage: perf2.sh <projdir> <label> <ticks> [args] -> medians of logic, script-side draw, engine render time (cpu, gpu), worst frame
S=/tmp/claude-0/-home-claude/b5a8ad34-b7fb-5322-85f2-786358ca3d0f/scratchpad
G=$S/godot/Godot_v4.6.1-stable_linux.x86_64
D=$1; L=$2; T=$3; shift 3
cd $S/$D && xvfb-run -a -s "-screen 0 1344x864x24" timeout 300 $G --path . --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --quit-after $T -- --no-save --seed=9 --perf "$@" > $S/perf2_run.log 2>&1
python3 - "$D $L" <<'PY'
import re, sys, statistics as st
L = [l for l in open('/tmp/claude-0/-home-claude/b5a8ad34-b7fb-5322-85f2-786358ca3d0f/scratchpad/perf2_run.log') if 'perf] fps' in l][2:]
if not L: print(sys.argv[1], 'NO DATA'); sys.exit()
def med(rx):
    v = [float(m.group(1)) for l in L for m in [re.search(rx, l)] if m]
    return st.median(v) if v else 0.0
print("%-22s n=%d logic %.2f | draw %.2f | render cpu %.2f gpu %.2f ms | calls %d | shots %d" % (sys.argv[1], len(L), med(r'logic ([\d.]+)'), med(r'draw ([\d.]+) ms'),
      med(r'render cpu ([\d.]+)'), med(r'gpu ([\d.]+) ms'), max(int(m.group(1)) for l in L for m in [re.search(r'peak (\d+) draw calls', l)] if m), med(r'shots (\d+),')))
PY
