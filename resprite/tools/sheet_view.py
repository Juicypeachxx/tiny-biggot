"""A labelled copy of a reference sheet, to describe each cell from the right picture (never upload it:
SpriteCook would copy the text). python3 resprite/tools/sheet_view.py REF.png OUT.png COLS NAME..."""
import sys
from PIL import Image, ImageDraw

def view(ref, out, cols, names, zoom=2):
    im = Image.open(ref).convert("RGBA")
    rows = (len(names) + cols - 1) // cols
    cw, ch = im.width // cols, im.height // rows
    big = Image.new("RGBA", (im.width * zoom, im.height * zoom + rows * 14), (60, 56, 66, 255))
    d = ImageDraw.Draw(big)
    for i, n in enumerate(names):
        c, r = i % cols, i // cols
        cell = im.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)).resize((cw * zoom, ch * zoom), Image.NEAREST)
        big.alpha_composite(cell, (c * cw * zoom, r * (ch * zoom + 14)))
        d.text((c * cw * zoom + 4, r * (ch * zoom + 14) + ch * zoom), "%d %s" % (i, n), fill=(255, 240, 200, 255))
    big.convert("RGB").save(out)

if __name__ == "__main__":
    view(sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4:])
