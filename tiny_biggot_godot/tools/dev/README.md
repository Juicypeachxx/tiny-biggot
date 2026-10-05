# Helper scripts from the exported-app pass

Copied as they were used. Each begins with `S=` or `G=` set to a scratch folder
that no longer exists: point `S` at a working folder that holds the project
copies and `G` at the Godot 4.6.1 Linux binary before running one. They need
`xvfb-run` and Python with Pillow.

| Script | What it does |
|---|---|
| `cmpbuilds.sh label frames [args]` | Records the same seeded run in two project copies (`OLD`, `NEW`) with `--write-movie` and counts the frames that differ |
| `review_cmp.sh`, `review_cmpframes.py` | The reviewer's version of the same: all four channels, and the sound track too |
| `trcmp.sh label ticks [args]` | The same seeded bot fight headless in two copies with `--trace`, files compared byte for byte |
| `excmp.sh label frames [args]` | Project run against the Linux export and the iOS preset's pack run with a desktop player |
| `cold3.sh exportdir label frames [args]` | One run of an exported build on an empty shader cache: stalls at launch and in play, programs built in play |
| `coldrun2.sh`, `sweep2.sh` | Every graphics call timed (shim2); `sweep2.sh` runs 45 scenes |
| `boot.sh`, `launch.sh` | Launch timing, phase by phase (needs the `[boot]` prints: see HANDOFF.md) and by wall clock |
| `perf2.sh`, `perfx.sh` | Medians of logic and drawing time from `--perf` |
| `cprobe.sh projdir home [args]` | One rendered start with a chosen user-data folder; prints how the atlas came to be and whether every sprite equals its file. Copy `cache_probe.gd.txt` and `cache_probe.tscn.txt` into the project's `tests/` (without `.txt`) first |
| `pck.py file.pck` | Lists a Godot 4 pack |
| `glshim/shim.c`, `glshim/shim2.c` | LD_PRELOAD shims: `gcc -shared -fPIC -O2 -o glshim.so shim.c -ldl` (same for shim2). shim counts shader programs linked per frame; shim2 times every draw call and logs the slow ones |
