#!/bin/bash
# usage: cmpbuilds.sh <label> <frames> [args]
# Records the same seeded run in the previous build (base7) and in this one (work or $NEW) and
# counts the frames that differ.
S=/tmp/claude-0/-home-claude/b5a8ad34-b7fb-5322-85f2-786358ca3d0f/scratchpad
G=$S/godot/Godot_v4.6.1-stable_linux.x86_64
L=$1; N=$2; shift 2
D=$S/cb/$L; rm -rf $D; mkdir -p $D/old $D/new
X='xvfb-run -a -s "-screen 0 1344x864x24" timeout 400'
R="--rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --quit-after $N"
(cd $S/${OLD:-base7} && eval $X $G --path . $R --write-movie $D/old/f.png -- --no-save --seed=9 "$@" > $D/old/log.txt 2>&1) &
(cd $S/${NEW:-work} && eval $X $G --path . $R --write-movie $D/new/f.png -- --no-save --seed=9 "$@" $EXTRA_NEW > $D/new/log.txt 2>&1) &
wait
python3 - "$L" "$N" "$D" <<'PY'
import sys, os
from PIL import Image, ImageChops
L, n, D = sys.argv[1], int(sys.argv[2]), sys.argv[3]
bad = worst = tot = 0; first = -1
for f in range(n):
    pa = '%s/old/f%08d.png' % (D, f); pb = '%s/new/f%08d.png' % (D, f)
    if not (os.path.exists(pa) and os.path.exists(pb)):
        continue
    tot += 1
    d = ImageChops.difference(Image.open(pa).convert('RGB'), Image.open(pb).convert('RGB')).convert('L').point(lambda v: 255 if v else 0)
    c = d.histogram()[255]
    if c:
        bad += 1; worst = max(worst, c)
        if first < 0: first = f
errs = []
for k in ('old', 'new'):
    t = [l for l in open('%s/%s/log.txt' % (D, k), errors='replace') if ('ERROR' in l or 'SCRIPT' in l) and 'resources still in use' not in l]
    errs.append("%s %d" % (k, len(t)))
print("%-16s %d frames, %d differ%s | errors: %s" % (L, tot, bad, (' (first %d, worst %d px)' % (first, worst)) if bad else '', ', '.join(errs)))
PY
