import os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from render import *
OLD = "/home/user/tiny-biggot/tiny_biggot_godot/assets/graphics/"
names = ["hexer","bat","skeleton","slime","colossus","heart_full","heart_half","heart_empty",
         "w_hexwand","w_repeater","w_pithatchet","w_graveshovel","w_flasksling"]
SC = 5
def scene(get, kitim):
    # a 9x5-tile patch of floor with wall on top, the sample standing on it
    W,H = 9*16, 6*16
    c = Image.new("RGBA",(W,H),(20,15,28,255))
    for x in range(9):
        c.alpha_composite(kitim.crop((16,16,32,32)),(x*16,0))
    for y in range(1,6):
        for x in range(9):
            v = ((x*7+y*3)%8)*2 + (0 if (x+y)%2 else 1)
            c.alpha_composite(kitim.crop((v*16,0,v*16+16,16)),(x*16,y*16))
    c.alpha_composite(kitim.crop((0,32,17,64)),(112,14))
    pos = {"hexer":(20,40),"bat":(56,26),"skeleton":(80,44),"slime":(56,66),"colossus":(92,66),
           "w_hexwand":(24,72),"heart_full":(2,1),"heart_half":(12,1),"heart_empty":(22,1)}
    for n,(x,y) in pos.items():
        im = get(n)
        if n == "colossus": im = im.resize((32,32),Image.NEAREST)
        c.alpha_composite(im,(x,y))
    return c
cols = [("OLD", lambda n: Image.open(OLD+n+".png").convert("RGBA"), Image.open(OLD+"kit0.png").convert("RGBA"))]
for v in "ABCD":
    d = all_for(v)
    cols.append((v+" "+VIBES[v]["name"], (lambda d: lambda n: d[n])(d), d["kit0"]))
    os.makedirs("out/"+v, exist_ok=True)
    for n,im in d.items(): im.save(f"out/{v}/{n}.png")
# one row of sprites per column + a little scene
rowW = sum(Image.open(OLD+n+".png").width + 3 for n in names)
cw = max(rowW, 9*16) + 6
img = Image.new("RGBA",(cw*SC, len(cols)*(16+6*16+14)*SC),(28,24,36,255))
dr = ImageDraw.Draw(img)
y0 = 0
for title,get,kitim in cols:
    x = 3
    for n in names:
        im = get(n); img.alpha_composite(im.resize((im.width*SC,im.height*SC),Image.NEAREST),(x*SC,(y0+10)*SC)); x += im.width+3
    sc = scene(get,kitim)
    img.alpha_composite(sc.resize((sc.width*SC,sc.height*SC),Image.NEAREST),(3*SC,(y0+28)*SC))
    dr.text((4,y0*SC+4), title, fill=(255,255,255,255))
    y0 += 16+6*16+14
img.save(sys.argv[1] if len(sys.argv)>1 else "compare.png")
print(img.size)
