"""Fetches every version of a PixelLab Pro batch and files it under the name it was asked for
(64: a Pro call lists up to 25 foes and gives one version a foe, in the same order).
python3 -I resprite/tools/pl_batch_get.py <set dir> <token file>
- <set dir>/jobs.json: the batch jobs (pl.py); <set dir>/batches.json: batch -> the names in order.
- Writes <set dir>/named/<name>.png. The download needs the PixelLab key; it is never kept in
  the repo (the token file is outside it)."""
import json, os, sys, urllib.request

def main():
    d, tok = sys.argv[1], open(sys.argv[2]).read().strip()
    jobs = json.load(open(os.path.join(d, "jobs.json")))
    batches = json.load(open(os.path.join(d, "batches.json")))
    out = os.path.join(d, "named")
    os.makedirs(out, exist_ok=True)
    for b, names in sorted(batches.items(), reverse=True):   # (a later batch redraws a name: it wins)
        j = jobs.get(b)
        if not j or not j.get("done") or j.get("failed"):
            print("not ready:", b)
            continue
        for i, n in enumerate(names):
            p = os.path.join(out, n + ".png")
            if os.path.exists(p):
                continue
            req = urllib.request.Request("https://api.pixellab.ai/mcp/images/%s/download?index=%d" % (j["id"], i),
                                         headers={"Authorization": "Bearer " + tok})
            try:
                open(p, "wb").write(urllib.request.urlopen(req, timeout=60).read())
            except Exception as e:
                print("missed", b, i, n, e)
        print(b, len(names))

if __name__ == "__main__":
    main()
