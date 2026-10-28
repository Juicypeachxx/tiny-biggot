# Tiny Biggot Rogues

A pixel roguelite for iPad, made in Godot 4.6.1 (GL Compatibility renderer).
The project is in `tiny_biggot_godot/`. `TinyBiggot-Stage2.zip` is the RPG
Maker original it was ported from; leave it alone.

**Start every session by reading `ROADMAP.md` (what to do next) and
`HANDOFF.md` (where things stand).** Do the next open step in `ROADMAP.md`
unless the owner says otherwise.

## The owner

Jože plays on an iPad Air M1. He installs the game as an IPA with SideStore
and can also open the project in Xogot (Godot 4.6.1 on iPad). He is not a
programmer. Write to him in short, plain English. Always say what you
measured, and what you could not test (there is no iPad and no Mac in the
cloud container).

## Rules that do not change

1. **Nothing is removed or toned down.** No weapon, effect, enemy, "broken"
   build or bit of chaos goes away to make something else easier.
2. **A steady 60 frames a second on the iPad Air M1.**
3. **Art is original.** The look takes ideas from Tiny Rogues, Dead Cells,
   Aion and League of Legends. No sprite, character, name or logo from any
   game is copied or traced. His word, 26 Oct: the authentic hand-made pixel
   vibe of Dead Cells, Enter the Gungeon, Noita, Terraria, Soulbound,
   Iconoclasts and Tiny Rogues (their look as an idea, never their art).
   His one exception (23 Oct, branch tiny-biggot-V2 only): the icon sheet in
   `resprite/icon_sheet/` (another artist's, for personal use only). Only
   while the repo is private, only in the game he plays himself: never on
   claude/dev, ios-build or windows-build, never in a shared copy, no logos,
   flags or emoji from it. Read its README before using it.
4. **The expanded game is the core** (his word, 6 Oct). Everything added so
   far is part of the game and is kept, the same as the original. It is
   what he plays: classic rules only exist behind the test switch
   `--classic`. Two sets of recordings guard it:
   `tests/replays/classic/` (the original rules: never re-recorded) and
   `tests/replays/*.txt` (the core as it is now). The core recordings are
   re-recorded only when content is added or changed on purpose, and the
   commit says so. If either set changes by accident, something was broken.
5. **Godot 4.6.1 only.** No 4.7 features: the project must still open in Xogot.
6. **Every stage ends with a working IPA** that he tests on the iPad. The next
   stage waits for it.
7. **He steers.** He will ask for changes and additions while the work is
   going on. What he says last outranks `ROADMAP.md`: do it, and write it
   into the roadmap.

## His usage is limited

Sessions have been cut off by usage limits more than once. So:

- One step of `ROADMAP.md` per session, unless he asks for more.
- Commit and push after every piece that works. Update `HANDOFF.md` in the
  same push.
- No long exploration. No sub-agents unless a step in `ROADMAP.md` calls for a
  review. Run the one test that covers your change while you work, and at the
  end of a step only the tests that cover its changes, the replays and a short
  play (his word, 27 Oct: "major tests we will do after i say so"). The full
  suite `tools/check.sh` only when he asks for it.
- When a step is done: say in five lines what changed, what was checked, what
  he should try on the iPad, and stop.

## Working on the project

Setup in a fresh container (about a minute):

    curl -fsSL -o /tmp/godot.zip https://github.com/godotengine/godot/releases/download/4.6.1-stable/Godot_v4.6.1-stable_linux.x86_64.zip
    unzip -q /tmp/godot.zip -d /opt/godot
    export GODOT=/opt/godot/Godot_v4.6.1-stable_linux.x86_64
    cd tiny_biggot_godot && $GODOT --headless --path . --import

Commands, run in `tiny_biggot_godot/`:

| What | Command |
|---|---|
| The whole test suite (8-10 minutes) | `GODOT=$GODOT bash tools/check.sh` |
| One test | `$GODOT --headless --path . res://tests/NAME.tscn -- --no-save` |
| Play 30 s without a screen | `$GODOT --headless --path . --fixed-fps 60 --quit-after 1800 -- --no-save --bot --smart-bot --god --seed=3 --hero=2` |
| A screenshot | `xvfb-run -a $GODOT --path . --rendering-driver opengl3 -- --no-save --seed=3 --hero=2 --shot=/tmp/a.png --shot-frame=300` |
| After adding or changing any graphic | `GODOT=$GODOT bash tools/bake_atlas.sh` |
| After adding content on purpose | `GODOT=$GODOT tools/replay.sh record` (full-content replays only) |

All test options are listed in `scripts/debug_args.gd`. `tools/dev/` has the
scripts for comparing pictures between two builds and for timing.

How the code is laid out, and the traps of the port: `PORTING_NOTES.md`.
Items are data (an id and a list of effects): `scripts/effects/`,
`scripts/data/`, `CONTENT_BATCH_1.md`. A hero with a mechanic of its own, as a
model: `GAOLBIRD.md`. Rooms, events and rift bosses: `RIFTS.md`, `BIOMES.md`. The final final boss after every won run: `FINALE.md`. Guardians' stages, plates, RESOLVE and attack patterns, the first guardian (his dog ARČI, `arci.gd`) and the third (ŠEFE, `sefe.gd`): `BOSS_STAGES.md`. Pets: `PETS.md`. Effects:
`EFFECTS.md`, `ATTACK_EFFECTS.md`. Speed: `PERFORMANCE.md`, `IOS_BUILD.md`.

**Paid art tools.** SpriteCook made V2's pictures (`resprite/HOW_IT_WORKS.md`; its credits left
are in `HANDOFF.md`). Higgsfield is connected too (his word, 26 Oct: "from now on we have
higgsfield intergration with 60 credits"; the Higgsfield tools of the session: images, video,
sound, 3D; check the balance with its `balance` tool, which costs nothing; reference pictures go
up to `upload.higgsfield.ai` (shown back from `d2ol7oe51mr4n9.cloudfront.net`) and finished
pictures come from `d8j0ntlcm91z4.cloudfront.net`, so the environment's network access must allow
all three). PixelLab too (his word, 26 Oct: "i have https://www.pixellab.ai/mcp subscription"),
true pixel art at an exact size: his pick for the weapon pictures of Stage 60. Credits are his money:
spend them only on something he asked for, say the cost before a big batch, and write what is left
in `HANDOFF.md` after each use. Rule 3 still holds for whatever they make.

## Checks before anything is called done

- The tests covering the change pass (`tools/check.sh` ends with `CHECK PASSED` when he asks for the full suite).
- A change that is not meant to change the picture changes no pixel: record
  the same seeded run before and after (`tools/dev/cmpbuilds.sh`).
- A change that is not meant to change the rules leaves all replays identical.
- New content: `tests/content_test.tscn` passes (it gives every item to a hero
  in a live fight and checks every shown string fits the pixel font).
- New or changed graphics: the atlas is baked and `tests/atlas_test.tscn`
  passes. A graphic taller than 96 px stays out of the atlas and costs draw
  calls: keep sprites within that.

## Building the IPA

Push a commit whose message contains `[ipa]`. GitHub builds the app on a Mac
in about a minute and a half and publishes `TinyBiggot-<version>-<Name>.ipa` twice:
as the release `ipa-<version>` (kept, one per step, so he can go back) and as
`ipa-latest`. **The version is the file `VERSION`** at the top of the repo:
set it to the roadmap step the build ends (e.g. `5.1`) in the `[ipa]` commit.
The app shows it in SideStore. **Every version has a name** (his ask, 9 Oct): in
the same commit add its line at the top of `scripts/data/versions.gd`
(`number|Name|tweak; tweak`). The title screen shows it, the release and the
file take its name (`TinyBiggot-28-Version-Names.ipa`), and the build stops if
the line is missing. Do this once at the end of a step, not on
every commit. Follow it with `gh run list` and `gh run watch <id>`.

## Git

**The work lives on the branch `tiny-biggot-V2`** (his word, 26 Oct: "v2 is
latest version with new sprites"). Start from it. When a step is done, its
commits must be on `tiny-biggot-V2` on GitHub: push there directly if the
session may, otherwise open a pull request into `tiny-biggot-V2` and tell him
to press Merge. A step that is only on a session's own branch is lost to the
next session. `claude/dev` is the line before the new sprites (up to IPA 59):
it stays as it is, and V2 is never merged into it (rule 3: his icon sheet
stays on V2).

**The iOS and Windows lines** (his word, 12 Oct: "if i work on multiplayer addon
on windows it wont be pushed on ios"). `ios-build` and `windows-build` are his
build branches. Every iPad build from `claude/dev` moves `ios-build` up to it,
merges it into `windows-build` and builds the Windows game (`build-ipa.yml`, the
job "windows"; `WINDOWS_BUILD.md` on `windows-build`). An IPA built from
`tiny-biggot-V2` touches neither, so the Windows game (co-op) still has the
old look. Windows-only work is done
on `windows-build` and **never merged into `claude/dev` or `ios-build`**: that
would put it on the iPad. No IPA is ever built from `windows-build`.

Do not push to `main` unless he asks. End commit messages with the session's
attribution lines.
