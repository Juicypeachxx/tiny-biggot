# Handoff: where the work stands

Kept up to date at every push, so that a session that is cut off (it has
happened twice to usage limits) loses nothing. `CLAUDE.md` has the rules and
`ROADMAP.md` the plan, step by step; this file is the detail of what was done.

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

## What he asked for on 5 Oct, in his order

1. **A working IPA** he can sideload on the iPad Air M1, built through GitHub.
   Done: see "The IPA build". Waiting for his word that it installs and runs.
2. **A performance patch**, then a stability check. Best done from what he
   reports from the iPad (OPTIONS > SHOW FPS: FPS, LOGIC, DRAW, WORST).
3. **New things, last**: 10+ rooms, 100+ weapons, 10+ characters with their
   own playstyles, every weapon, relic and piece of equipment unique (the game
   already has 252 weapons, 14 heroes and 96+ gear pieces, so this includes
   going through the existing ones for near-duplicates), and a pixel-art
   revamp of all sprites in the spirit of the influences above.

He asked not to spend his usage on debugging and new things before the IPA
works. Keep each step small, commit and push after each.

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

## State of the fix: done (ef0d6af, 101017b)

The atlas file is no longer a Godot resource. It is a file of the game's own
(`assets/atlas/sprites.tbatlas`: "TBAT", an MD5 of everything after it, the
unpacked size, then `var_to_bytes` of the notes and pixels, zstd-packed).
`Img.notes_in` checks the checksum before anything is unpacked, and
`Img.write_whole` reads back what it wrote before moving it into place. Both
export presets include `*.tbatlas` (it is not a resource, so only a filter
gets it into the pack).

Checked on 101017b:
- `tools/check.sh` passes, 14 replays identical.
- `tests/atlas_test.gd`: 513 single-bit flips, 342 cuts and eleven other kinds
  of damage are refused without an engine error; eight planted faults in the
  loader were each caught.
- The project's file cut at seven lengths, or with a bit flipped: the game
  starts and packs the atlas itself. A full disk leaves no partial file.
- 30 seeded runs, 17,400 frames, against 4ecba1f: no pixel differs, sound the
  same, with the atlas loaded from the project's file (25 runs), packed at
  start-up (2), loaded from the game's own file (2) and switched off (1).
  (The commit message of 101017b says 17,820 frames; 17,400 is right.)
- A Linux release export carries the file and loads it ("baked", about 50 ms).

Not redone after the file-format change, because nothing they measure
changed: the stall timings and the 45-scene sweep in `IOS_BUILD.md`.

## The IPA build

`.github/workflows/build-ipa.yml` builds an unsigned `TinyBiggot.ipa` on a
GitHub Mac (macos-15): Godot 4.6.1 imports the project, `tools/bake_atlas.sh`
makes and tests the atlas, the iOS preset exports the Xcode project with the
release engine, `xcodebuild` builds it with signing off, and the app is zipped
as `Payload/`. The IPA is kept with the run and published as the release
`ipa-latest` (replaced by each build).

- It runs when a pushed commit message contains `[ipa]`, or from the Actions
  page ("Run workflow") once the file is on the default branch. Other pushes
  start nothing.
- First run: 1 min 18 s, green. The IPA is 28 MB: arm64, release engine,
  bundle id `com.joze.tinybiggot`, minimum iOS 14.0, Game Mode keys set, not
  signed (SideStore signs it).
- Its pack, run with a Linux desktop player, loads the atlas ("baked") and
  plays. All 842 imported graphics in it are byte-identical to the Linux
  import, so the atlas file made on Linux fits what the Mac imports.
- From a cloud session: `gh run list`, `gh run watch <id>` and
  `gh api repos/Juicypeachxx/tiny-biggot/releases/tags/ipa-latest` work.
  Run logs and run artifacts cannot be downloaded (blocked by the session's
  network rules); the release asset can:
  `gh api -H "Accept: application/octet-stream" repos/Juicypeachxx/tiny-biggot/releases/assets/<id> > TinyBiggot.ipa`.
- **Not known yet:** that it installs with SideStore and runs on the iPad.

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
