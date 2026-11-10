"""The five odd pictures in his bright look (22 Oct): another frame or pose of a foe, a guardian's
parts, a rift's statue. python3 resprite/tools/odd_sheet.py -> resprite/spritecook/refs/odd_o1.png
and odd_plan.json
- bat2 is the bat's other wing beat and believer_flex the believer flexing (world_view.gd,
  finale.gd): each must match its new base, so the reference shows the new bat and believer
  (resprite/hd) beside today's frame, and the prompt asks to draw the frame as the same one.
  Today's bat2 is a red bat, the bat purple: the new frame is the new bat's own colours.
- hydrahead and hydraneck make the Bilge Hydra's heads (rift_bosses.gd): its new look (sheet g2)
  is one of the style pictures.
- 4 x 4, like the foes: a 2 x 2 or 3 x 3 sheet draws them too big, and they blur when shrunk.
Then: tools/sheet_add.py cuts the sheet (cells 0 and 2, the bases, are not used).
python3 resprite/tools/odd_sheet.py fill NAME: the neck piece came back curled round a hole, and the
game draws six of them in a row: the hole (see-through pixels the outside cannot reach) is filled
with the drawing's middle green, and the piece fitted again."""
import json, os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventory import G, ROOT

CELL, COLS = 128, 4
# (picture, from the new set, words): the new set is at double detail, so drawn at half the scale.
CELLS = [("bat", True, "a bat, redrawn exactly as it is"),
         ("bat2", False, "the same bat again, the same colours and look, its wings in the other beat of its flap"
                         " as the reference shows"),
         ("believer", True, "a bald strongman, redrawn exactly as he is"),
         ("believer_flex", False, "the same strongman again, the same colours and look, flexing both arms up as"
                                  " the reference shows"),
         ("hydrahead", False, "the green head of the sea serpent hydra of the style guide, gold horns, mouth open"),
         ("hydraneck", False, "one round green scaly neck piece of the same hydra"),
         ("bullet_saint", False, "a little saint statue in a red robe with a gold halo, on a dark stone base")]

def main():
    sheet = Image.new("RGBA", (COLS * CELL, COLS * CELL), (0, 0, 0, 0))
    for i, (n, new, _) in enumerate(CELLS):
        im = Image.open(os.path.join(ROOT, "resprite", "hd", n + ".png") if new else os.path.join(G, n + ".png")).convert("RGBA")
        k = 3 if new else 6
        b = im.resize((im.width * k, im.height * k), Image.NEAREST)
        sheet.alpha_composite(b, ((i % COLS) * CELL + (CELL - b.width) // 2, (i // COLS) * CELL + (CELL - b.height) // 2))
    ref = os.path.join(ROOT, "resprite", "spritecook", "refs", "odd_o1.png")
    sheet.save(ref)
    n = len(CELLS)
    words = [w for _, _, w in CELLS]
    prompt = ("A sprite sheet in a %d by %d grid, redrawn from the reference sheet; only the first %d places are"
              " used and the rest stay empty. Every one stays in its own place in the grid. Row 1, left to right: %s."
              " Row 2: %s. The words are only to tell you what each one is: never write any names, words or letters"
              " in the picture. Each a clean, bright, colourful pixel art game sprite in exactly the look of the"
              " style guide, with clear empty space between them. No text, no labels, no captions, no background."
              % (COLS, COLS, n, "; ".join(words[:COLS]), "; ".join(words[COLS:])))
    cells = [c for c, _, _ in CELLS] + ["-"] * (COLS * COLS - n)
    path = os.path.join(ROOT, "resprite", "spritecook", "refs", "odd_plan.json")
    done = json.load(open(path)) if os.path.exists(path) else {}   # keeps the SpriteCook ids of sheets made
    done.setdefault("o1", {}).update({"cells": cells, "ref": os.path.relpath(ref, ROOT), "prompt": prompt,
                                      "use": [c for c, new, _ in CELLS if not new]})
    with open(path, "w") as f:
        json.dump(done, f, indent=1)
        f.write("\n")
    print(prompt)

def fill(name):
    from spritecook_fit import RAW, lum, main as fit
    path = os.path.join(RAW, name + ".png")
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    out = {(x, y) for x in range(w) for y in (0, h - 1)} | {(x, y) for x in (0, w - 1) for y in range(h)}
    todo = [p for p in out if px[p][3] < 128]
    out = set(todo)
    while todo:                                     # the outside: see-through, reached from the edge
        x, y = todo.pop()
        for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= q[0] < w and 0 <= q[1] < h and q not in out and px[q][3] < 128:
                out.add(q)
                todo.append(q)
    solid = sorted((px[x, y] for x in range(w) for y in range(h) if px[x, y][3] >= 128), key=lum)
    mid = solid[len(solid) // 2]
    holes = [(x, y) for x in range(w) for y in range(h) if px[x, y][3] < 128 and (x, y) not in out]
    for p in holes:
        px[p] = mid[:3] + (255,)
    im.save(path)
    fit([name])
    print("filled %d pixels of %s" % (len(holes), name))

if __name__ == "__main__":
    if sys.argv[1:2] == ["fill"]:
        fill(sys.argv[2])
    else:
        main()
