"""Walk and attack frames for heroes and bosses on PixelLab (66.2, his word: "animation of heros and
bosses"). python3 -I resprite/tools/anim_pl.py <pl.py dir> <token file> name[:hero|:boss] ...
- Each picture (graphics_hd/<name>.png) becomes a one-direction PixelLab object (free: its own
  picture is the first frame), padded to a multiple of 4 (feet on the bottom, centred).
- Two moves an object (v3, 6 new frames + the first: 7): walk and attack (about 1 generation each).
- resprite/pixellab/anim/sheets/<name>.png: the frames as a strip, cut back to the picture's own size;
  row 0 the walk, row 1 the attack. state.json keeps where every name is, so a run picks up again.
The PixelLab key stays outside the repo (the token file)."""
import base64, io, json, os, re, sys, time, urllib.request, zipfile
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HD = os.path.join(ROOT, "tiny_biggot_godot", "assets", "graphics_hd")
OUT = os.path.join(ROOT, "resprite", "pixellab", "anim")
INFLIGHT = 7   # objects moving at once (PixelLab takes 8 jobs; a monster has one, a hero or boss two)

MOVES = {
    "hero": {"walk": "walking forward, a lively walk cycle, legs stepping, arms swinging a little",
             "attack": "a quick attack strike, a short lunge with the arms, small motion"},
    "mob": {"walk": "walking forward, a lively bouncy walk cycle (flapping or hovering if it flies)"},
    "boss": {"walk": "moving forward menacingly, a heavy walk cycle (hovering up and down if it flies)",
             "attack": "a big powerful attack: a strong wind-up, then a fierce strike or slam"},
}

def pad4(im):
    w, h = (im.width + 3) // 4 * 4, (im.height + 3) // 4 * 4
    w, h = max(w, 16), max(h, 16)
    box = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ox, oy = (w - im.width) // 2, h - im.height
    box.alpha_composite(im, (ox, oy))
    return box, ox, oy

def main():
    sys.path.insert(0, sys.argv[1])
    import pl
    tok = open(sys.argv[2]).read().strip()
    descs = json.load(open(os.path.join(ROOT, "resprite", "pixellab", "bosses", "bosses.json")))
    os.makedirs(os.path.join(OUT, "sheets"), exist_ok=True)
    sp = os.path.join(OUT, "state.json")
    st = json.load(open(sp)) if os.path.exists(sp) else {}
    def save():
        json.dump(st, open(sp, "w"), indent=1)
    names = []
    for a in sys.argv[3:]:
        n, kind = (a.split(":") + ["boss"])[:2]
        names.append(n)
        st.setdefault(n, {"kind": kind, "stage": "new"})
    save()
    t0 = time.time()
    while time.time() - t0 < 3 * 3600:
        busy = sum(1 for n in names if st[n]["stage"] == "moving")
        left = [n for n in names if st[n]["stage"] != "done" and st[n]["stage"] != "failed"]
        if not left:
            break
        for n in left:
            s = st[n]
            if s["stage"] == "new":
                im, ox, oy = pad4(Image.open(os.path.join(HD, n + ".png")).convert("RGBA"))
                b = io.BytesIO(); im.save(b, "PNG")
                base = n.split("_s")[0]
                d = descs.get(base, base.replace("_hero", "") + ", a pixel art " + s["kind"])
                r = pl.call("create_object_pro_flash", {"description": d[:1900], "name": n, "view": "side", "n_directions": 1,
                                                       "first_frame_base64": base64.b64encode(b.getvalue()).decode()})
                m = re.search(r'"object_id":\s*"([0-9a-f-]{36})"', pl.texts(r))
                if not m:
                    print("object refused", n, pl.texts(r)[:300], flush=True)
                    continue
                s.update(stage="object", id=m.group(1), ox=ox, oy=oy)
                s["size"] = Image.open(os.path.join(HD, n + ".png")).size
                save()
            elif s["stage"] == "object":
                if busy >= INFLIGHT:
                    continue
                t = pl.texts(pl.call("get_object", {"object_id": s["id"], "include_preview": False}))
                if "status: completed" not in t:
                    continue
                ok = True
                for mv in MOVES[s["kind"]]:
                    if mv in s.get("asked", []):
                        continue
                    r = pl.call("animate_object", {"object_id": s["id"], "animation_description": MOVES[s["kind"]][mv], "frame_count": 6})
                    if "queued" not in pl.texts(r):
                        print("animate refused", n, mv, pl.texts(r)[:200], flush=True)
                        ok = False
                        break
                    s.setdefault("asked", []).append(mv)
                    save()
                if ok:
                    s["stage"] = "moving"
                    busy += 1
                    save()
            elif s["stage"] == "moving":
                t = pl.texts(pl.call("get_object", {"object_id": s["id"], "include_preview": False}))
                if "pending jobs" in t:
                    continue
                if t.count("frames:") < len(MOVES[s["kind"]]):
                    print("a move failed", n, t[-400:], flush=True)
                    s["stage"] = "failed"
                    save()
                    continue
                req = urllib.request.Request("https://api.pixellab.ai/mcp/objects/%s/spritesheet" % s["id"], headers={"Authorization": "Bearer " + tok})
                z = zipfile.ZipFile(io.BytesIO(urllib.request.urlopen(req, timeout=120).read()))
                js = json.loads(z.read([f for f in z.namelist() if f.endswith(".json")][0]))["spritesheet"]
                sheet = Image.open(io.BytesIO(z.read(js["path"]))).convert("RGBA")
                cw, ch = js["cell_size"]["width"], js["cell_size"]["height"]
                w, h = s["size"]
                rows = {}
                for row in js["rows"]:
                    if row["type"] != "animation":
                        continue
                    mv = "walk" if row["animation"].startswith(MOVES[s["kind"]]["walk"][:40]) else "attack"
                    if mv not in MOVES[s["kind"]]:
                        continue
                    rows[mv] = [sheet.crop((i * cw + s["ox"], row["row"] * ch + s["oy"], i * cw + s["ox"] + w, row["row"] * ch + s["oy"] + h))
                                for i in range(row["frame_count"])]
                mvs = [m for m in ["walk", "attack"] if m in rows]
                k = min(len(rows[m]) for m in mvs)
                strip = Image.new("RGBA", (w * k, h * len(mvs)), (0, 0, 0, 0))
                for r, mv in enumerate(mvs):
                    for i in range(k):
                        strip.alpha_composite(rows[mv][i], (i * w, r * h))
                strip.save(os.path.join(OUT, "sheets", n + ".png"))
                s["stage"] = "done"
                s["frames"] = k
                save()
                print("done", n, k, "frames", flush=True)
        time.sleep(10)
    print("left:", [n for n in names if st[n]["stage"] != "done"], flush=True)
    print(pl.texts(pl.call("get_balance", {})).splitlines()[1], flush=True)

if __name__ == "__main__":
    main()
