"""Cut his icon sheet into single icons (background, drop shadow and panel frames left out)."""
import sys, os
import numpy as np
from PIL import Image
from collections import Counter

src, out = sys.argv[1], sys.argv[2]
im = np.asarray(Image.open(src).convert("RGBA")).astype(int)
H, W = im.shape[:2]
BG = [(142, 123, 119), (123, 97, 97), (130, 104, 104), (165, 134, 128)]
rgb = im[..., :3]
fg = np.ones((H, W), bool)
for c in BG:
    fg &= ~(np.abs(rgb - np.array(c)).sum(-1) <= 6)
# connected parts (8-neighbour)
lab = np.zeros((H, W), int)
n = 0
boxes = []
for y in range(H):
    for x in range(W):
        if fg[y, x] and not lab[y, x]:
            n += 1
            st = [(y, x)]
            lab[y, x] = n
            pts = []
            while st:
                cy, cx = st.pop()
                pts.append((cy, cx))
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < H and 0 <= nx < W and fg[ny, nx] and not lab[ny, nx]:
                            lab[ny, nx] = n
                            st.append((ny, nx))
            ys = [p[0] for p in pts]; xs = [p[1] for p in pts]
            boxes.append([min(xs), min(ys), max(xs) + 1, max(ys) + 1, len(pts)])
print("parts", len(boxes))
# merge parts whose boxes come within 3 px of each other (an icon in two pieces)
def near(a, b, g=3):
    return not (a[2] + g <= b[0] or b[2] + g <= a[0] or a[3] + g <= b[1] or b[3] + g <= a[1])
merged = True
while merged:
    merged = False
    for i in range(len(boxes)):
        for j in range(i + 1, len(boxes)):
            if near(boxes[i], boxes[j]):
                a, b = boxes[i], boxes[j]
                boxes[i] = [min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3]), a[4] + b[4]]
                boxes.pop(j)
                merged = True
                break
        if merged:
            break
boxes = [b for b in boxes if b[4] >= 12]
boxes.sort(key=lambda b: (round((b[1] + b[3]) / 2 / 8), b[0]))
print("icons", len(boxes))
sizes = Counter((b[2] - b[0], b[3] - b[1]) for b in boxes)
print("sizes", sizes.most_common(10))
os.makedirs(out, exist_ok=True)
alpha = np.where(fg, 255, 0)
full = np.dstack([rgb, alpha]).astype(np.uint8)
with open(os.path.join(out, "boxes.txt"), "w") as f:
    for i, b in enumerate(boxes):
        Image.fromarray(full[b[1]:b[3], b[0]:b[2]], "RGBA").save(os.path.join(out, "i%03d.png" % i))
        f.write("i%03d %d %d %d %d\n" % (i, b[0], b[1], b[2], b[3]))
