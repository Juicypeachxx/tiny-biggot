"""Removes stray specks from a PixelLab picture: groups of touching pixels smaller than `minimum`
(the picture's own body is always kept). python3 resprite/tools/despeck.py <in.png> <out.png>"""
import sys
from PIL import Image

def despeck(im, minimum=6):
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    seen = set()
    groups = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0 or (x, y) in seen:
                continue
            stack, g = [(x, y)], []
            seen.add((x, y))
            while stack:
                cx, cy = stack.pop()
                g.append((cx, cy))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and px[nx, ny][3] > 0:
                            seen.add((nx, ny))
                            stack.append((nx, ny))
            groups.append(g)
    if not groups:
        return im
    big = max(len(g) for g in groups)
    for g in groups:
        if len(g) < minimum and len(g) < big:
            for (x, y) in g:
                px[x, y] = (0, 0, 0, 0)
    return im

if __name__ == "__main__":
    despeck(Image.open(sys.argv[1])).save(sys.argv[2])
