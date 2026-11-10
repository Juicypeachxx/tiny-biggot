#!/bin/bash
# usage: perfx.sh <exportdir> <label> <ticks> [args] -> medians of logic and script-side draw per tick, headless (no rendering)
S=/tmp/claude-0/-home-claude/b5a8ad34-b7fb-5322-85f2-786358ca3d0f/scratchpad
D=$1; L=$2; T=$3; shift 3
( cd $S/$D && timeout 300 ./tb.x86_64 --headless --fixed-fps 60 --quit-after $T -- --no-save --seed=9 --perf "$@" > $S/perfx_run.log 2>&1 )
python3 - "$L" <<'PY'
import re, sys, statistics as st
L = [l for l in open('/tmp/claude-0/-home-claude/b5a8ad34-b7fb-5322-85f2-786358ca3d0f/scratchpad/perfx_run.log') if 'perf] fps' in l][2:]
if not L: print(sys.argv[1], 'NO DATA'); sys.exit()
def med(rx):
    v = [float(m.group(1)) for l in L for m in [re.search(rx, l)] if m]
    return st.median(v) if v else 0.0
print("%-26s n=%d logic %.2f ms | draw (script side) %.2f ms | shots %d" % (sys.argv[1], len(L), med(r'logic ([\d.]+)'), med(r'draw ([\d.]+) ms'), med(r'shots (\d+),')))
PY
