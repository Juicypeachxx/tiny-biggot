# Handoff: where the work stands

Kept up to date at every push, so that a session that is cut off (it has
happened twice to usage limits) loses nothing. Read this first.

The Godot project is in `tiny_biggot_godot/` (Godot 4.6.1, GL Compatibility).
`TinyBiggot-Stage2.zip` is the RPG Maker original it was ported from.

## The owner and his rules

- Jože plays on an iPad Air M1. He tests in Xogot (Godot 4.6.1 on iPad) and
  sideloads IPAs with SideStore. He has a Mac with Xcode but wants the IPA
  built here, through GitHub.
- Nothing is to be removed or toned down: "the same broken paths and chaos".
- A steady 60 fps is a requirement.
- Art influences he named: Tiny Rogues (the game's model), Dead Cells, Aion,
  League of Legends. Ideas only: every sprite is original work. No character,
  sprite or logo from those games is copied.
- Write to him in plain, short English. Say what was measured and what could
  not be tested (there is no iPad and no Mac in the cloud container).

## What he asked for on 5 Oct (the roadmap)

1. **An IPA** he can sideload on the iPad Air M1, built through GitHub.
2. **A stability check and a performance check**, thorough.
3. **10+ new rooms, 100+ new weapons, 10+ new characters** with their own
   playstyles. Every weapon, relic and piece of equipment must feel unique
   (the game has 252 weapons, 14 heroes and 96+ gear pieces already, so this
   includes going through the existing ones for near-duplicates).
4. **A pixel-art revamp of all sprites** in the spirit of the influences above,
   at sizes that still fit the game.

Order agreed so far: 1 first. 3 and 4 are large and need his answers on art
direction and priorities before they start (asked on 5 Oct; see the chat).

## Branch and commits

Branch `claude/xcode-pass-handoff`, on top of the port branch
`claude/compassionate-ramanujan-vjr3qr` (4dbec24).

| Commit | What it is |
|---|---|
| 4ecba1f | Everything delivered to him up to 3 Oct (the "attack-effects" build). The baseline: later work is compared against it picture for picture |
| e8765f0 | The exported-app pass as checked on 3 Oct. **Not delivered**: see below |
| after that | The fix in progress, then whatever follows. See "State of the fix" |

## The exported-app pass (e8765f0)

Goal: remove the stalls an exported app has, without changing a rule or a
pixel. `tiny_biggot_godot/IOS_BUILD.md` has the causes and the measurements.
In short: no texture read-backs during play (`Img` keeps the atlas pixels in
memory), a launch warm-up that draws every kind of thing once
(`scripts/render/warmup.gd`), sounds loaded at launch, a shot batch that
always hands over the same instance count, a ready-made sprite atlas with a
fingerprint of the imported graphics, and the iOS export preset.

Checked on that commit: `tools/check.sh` passes with all 14 replays identical;
an independent review compared 47 seeded runs (46,500 frames) and 14 traces
against 4ecba1f with no difference, ran 40 soaks (505,800 ticks) without an
error line, and found six defects, all fixed in that commit.

**Why it was not delivered.** The same reviewer's second pass (cut off before
it could report; recovered from its logs) found that the engine itself aborts
when it is asked to load a damaged compressed `.res`:
`FATAL: Index p_index = 16777215 is out of bounds` inside `ResourceLoader.load`.
With the atlas stored as `assets/atlas/sprites.res`:

- cut short at 95 of 151 lengths tried: crash at every start, also when it is
  the project's own file (an interrupted copy to the iPad would do it);
- a single flipped bit in the notes area: crash in 53 of 120 tries, or wrong
  sprite places accepted in 21 of 120;
- `ResourceSaver.save` reports OK on a full disk and leaves a partial file.

## State of the fix

The atlas file is no longer a Godot resource. It is a file of the game's own
(`sprites.tbatlas`: "TBAT", an MD5 of everything after it, the unpacked size,
then `var_to_bytes` of the notes and pixels, zstd-packed). `Img.notes_in`
checks the checksum before anything is unpacked, and `Img.write_whole` reads
back what it wrote before moving it into place.

Done:
- `scripts/core/img.gd`: the new format, loader and writer. It runs: a first
  start packs the atlas and writes the game's own file, the next start loads
  it ("cached").

Not done yet (in this order):
1. `tests/atlas_test.gd` still uses the old API and will not compile. Rewrite
   for `read_file` / `notes_in` / `bake_fits` / `picture_fits(m)`, and add
   file-damage cases: every header byte and many body bytes flipped, cuts at
   many lengths, zeroed blocks, wrong magic, a right checksum around garbage.
   All must be refused with no engine error line.
2. `export_presets.cfg`: `include_filter="*.json, *.tbatlas"` in both presets
   (the file is not a resource, so it is only exported if a filter names it).
3. Delete `assets/atlas/sprites.res`, run `tools/bake_atlas.sh` to write
   `sprites.tbatlas`, fix the old file name in `tools/bake_atlas.sh`,
   `IOS_BUILD.md` and `PORTING_NOTES.md`.
4. Re-run: `tools/check.sh`; pictures and traces against 4ecba1f in the four
   atlas modes (shipped file, `--no-bake`, the game's own file, `--no-atlas`);
   a clean unpack; Linux and iOS exports (does the pack hold the file, does the
   exported build say "baked"); the cut and bit-flip campaigns (0 crashes).
5. Re-measure only the atlas load time for `IOS_BUILD.md`; the stall figures
   there do not depend on the file format.

## Noted, not yet acted on

- `Meta.write_save` writes the save file in place. On a full disk it is left
  empty and the player's progress is gone. Belongs in the stability check:
  write to a temporary file, read it back, then rename.
- Hit points can stay above the maximum after a synergy is lost (older note).

## Tools

- Godot 4.6.1: `Godot_v4.6.1-stable_linux.x86_64.zip` and
  `Godot_v4.6.1-stable_export_templates.tpz` from the godotengine/godot
  releases on GitHub. Templates go to
  `~/.local/share/godot/export_templates/4.6.1.stable/`.
- `tiny_biggot_godot/tools/check.sh` is the full test suite (about 8 minutes).
- `tiny_biggot_godot/tools/dev/` holds the comparison and timing scripts used
  so far, with a README.
- To compare pictures: check out 4ecba1f beside the working copy
  (`git worktree add ../base 4ecba1f`), import both, and record the same
  seeded run in each with `--write-movie` (see `tools/dev/cmpbuilds.sh`).
