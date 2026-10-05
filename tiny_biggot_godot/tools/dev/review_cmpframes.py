#!/usr/bin/env python3
# usage: cmpframes.py <label> <frames> <dir>   compares <dir>/old/f%08d.png with <dir>/new/f%08d.png, all four channels
import sys, os, hashlib
import numpy as np
from PIL import Image
L, n, D = sys.argv[1], int(sys.argv[2]), sys.argv[3]
bad = worst = tot = 0; first = -1; missing = 0; badlist = []
for f in range(n):
    pa = '%s/old/f%08d.png' % (D, f); pb = '%s/new/f%08d.png' % (D, f)
    if not (os.path.exists(pa) and os.path.exists(pb)):
        missing += 1
        continue
    tot += 1
    a = np.asarray(Image.open(pa).convert('RGBA')); b = np.asarray(Image.open(pb).convert('RGBA'))
    if a.shape != b.shape:
        bad += 1; badlist.append((f, -1)); continue
    c = int((a != b).any(axis=2).sum())
    if c:
        bad += 1; worst = max(worst, c); badlist.append((f, c))
        if first < 0: first = f
errs = []
for k in ('old', 'new'):
    t = [l for l in open('%s/%s/log.txt' % (D, k), errors='replace') if ('ERROR' in l or 'SCRIPT' in l or 'WARNING' in l) and 'resources still in use' not in l and 'ObjectDB instances leaked' not in l and 'V-Sync' not in l]
    errs.append("%s %d" % (k, len(t)))
wav = 'n/a'
wa, wb = D + '/old/f.wav', D + '/new/f.wav'
if os.path.exists(wa) and os.path.exists(wb):
    wav = 'same' if open(wa, 'rb').read() == open(wb, 'rb').read() else 'DIFFERS'
# black/blank sanity: how many distinct frames were there in old
print("%-22s %d frames compared (%d missing), %d differ%s | sound track: %s | log lines with ERROR/WARNING: %s" % (
    L, tot, missing, bad, (' (first %d, worst %d px) %s' % (first, worst, badlist[:12])) if bad else '', wav, ', '.join(errs)))
open(D + '/badframes.txt', 'w').write('\n'.join('%d %d' % x for x in badlist))
