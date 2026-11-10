#!/bin/bash
# usage: excmp.sh <label> <frames> [args]
# Records the same seeded fight three ways (the project, the Linux release export, the iOS preset's pack
# with a desktop player) and counts frames that differ from the project's, and error lines in each log.
S=/tmp/claude-0/-home-claude/b5a8ad34-b7fb-5322-85f2-786358ca3d0f/scratchpad
G=$S/godot/Godot_v4.6.1-stable_linux.x86_64
L=$1; N=$2; shift 2
D=$S/ex/$L; rm -rf $D; mkdir -p $D/prj $D/lin $D/ios
X='xvfb-run -a -s "-screen 0 1344x864x24" timeout 400'
R="--rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --quit-after $N"
(cd $S/fin7 && eval $X $G --path . $R --write-movie $D/prj/f.png -- --no-save --seed=9 "$@" > $D/prj/log.txt 2>&1) &
(cd $S/linux_export && eval $X ./tb.x86_64 $R --write-movie $D/lin/f.png -- --no-save --seed=9 "$@" > $D/lin/log.txt 2>&1) &
(cd $S/ios_pack && eval $X ./TinyBiggot.x86_64 $R --write-movie $D/ios/f.png -- --no-save --seed=9 "$@" > $D/ios/log.txt 2>&1) &
wait
python3 - "$L" "$N" "$D" <<'PY'
import sys, os
from PIL import Image, ImageChops
L, n, D = sys.argv[1], int(sys.argv[2]), sys.argv[3]
out = []
for other in ('lin', 'ios'):
    bad = worst = tot = 0
    for f in range(n):
        pa = '%s/prj/f%08d.png' % (D, f); pb = '%s/%s/f%08d.png' % (D, other, f)
        if not (os.path.exists(pa) and os.path.exists(pb)):
            continue
        tot += 1
        d = ImageChops.difference(Image.open(pa).convert('RGB'), Image.open(pb).convert('RGB')).convert('L').point(lambda v: 255 if v else 0)
        c = d.histogram()[255]
        if c:
            bad += 1; worst = max(worst, c)
    out.append("%s: %d frames, %d differ (worst %d px)" % (other, tot, bad, worst))
errs = []
for k in ('prj', 'lin', 'ios'):
    t = [l for l in open('%s/%s/log.txt' % (D, k), errors='replace') if ('ERROR' in l or 'SCRIPT' in l) and 'resources still in use' not in l]
    errs.append("%s %d" % (k, len(t)))
print("%-14s %s | %s | errors: %s" % (L, out[0], out[1], ', '.join(errs)))
PY
