#!/bin/bash
# usage: cmp.sh <label> <frames> [args]   (env: EXTRA_NEW, EXTRA_OLD, SEED, OLD, NEW, KEEP=1)
. /tmp/claude-0/-home-claude/b5a8ad34-b7fb-5322-85f2-786358ca3d0f/scratchpad/review8_logs/env.sh
LAB=$1; N=$2; shift 2
D=$L/cb/$LAB; rm -rf $D; mkdir -p $D/old $D/new
SEEDARG="--seed=${SEED:-9}"; [ "${SEED:-9}" = none ] && SEEDARG=""
RR="--rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --quit-after $N"
(cd ${OLD:-$B} && xvfb-run -a -s "-screen 0 1344x864x24" timeout 900 $G --path . $RR --write-movie $D/old/f.png -- --no-save $SEEDARG "$@" $EXTRA_OLD > $D/old/log.txt 2>&1)
(cd ${NEW:-$R} && xvfb-run -a -s "-screen 0 1344x864x24" timeout 900 $G --path . $RR --write-movie $D/new/f.png -- --no-save $SEEDARG "$@" $EXTRA_NEW > $D/new/log.txt 2>&1)
python3 $L/cmpframes.py "$LAB" "$N" "$D" | tee -a $L/cb/results.txt
echo "   args: $SEEDARG $* | new only: ${EXTRA_NEW:-} | old only: ${EXTRA_OLD:-}" >> $L/cb/results.txt
# keep only frames that differ (both sides) plus a few samples
mkdir -p $D/keep
for f in $(awk '{print $1}' $D/badframes.txt | head -20); do
  cp $D/old/$(printf 'f%08d.png' $f) $D/keep/old_$f.png; cp $D/new/$(printf 'f%08d.png' $f) $D/keep/new_$f.png
done
for f in 0 1 2 3 $((N/2)) $((N-1)); do cp $D/new/$(printf 'f%08d.png' $f) $D/keep/sample_new_$f.png 2>/dev/null; cp $D/old/$(printf 'f%08d.png' $f) $D/keep/sample_old_$f.png 2>/dev/null; done
if [ "${KEEP:-0}" != 1 ]; then rm -f $D/old/f*.png $D/new/f*.png $D/old/f.wav $D/new/f.wav; fi
