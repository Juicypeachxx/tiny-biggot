# Roadmap

What is left to do, in the order the owner set on 5 Oct 2026:
**a working IPA first, then the performance patch, then new things and new
sprites.** `CLAUDE.md` has the rules. `HANDOFF.md` has the details of what was
done so far.

How to use this file: find the first step that is not ticked, do that one
step, tick it here, add a line under "Log" at the bottom, update `HANDOFF.md`,
push, tell the owner what to try, and stop. One step is one session.

| Stage | What | State |
|---|---|---|
| 1 | The IPA installs and runs on the iPad | Built; waiting for his word |
| 2 | Performance patch | Not started; needs his numbers from the iPad |
| 3 | Stability check | Not started |
| 4 | New content: rooms, characters, weapons; everything unique | Not started |
| 5 | Sprite revamp | Not started |

---

## Stage 1: the IPA on the iPad

- [x] 1.1 The game builds as `TinyBiggot.ipa` on GitHub (release `ipa-latest`).
- [ ] 1.2 The owner installs it with SideStore and says whether it starts.

If it does not install or start, that comes before everything else. Ask him
for the exact message SideStore shows, or what he sees (black screen, closes
at once, no touch controls). Things to check, cheapest first:

- SideStore refuses the file: compare with another unsigned IPA he has
  installed; check `Payload/TinyBiggot.app/Info.plist` (bundle id, minimum iOS
  14.0, `UIDeviceFamily`).
- It closes at launch: the app writes `user://logs` only on desktop, so ask
  for the crash report (Settings > Privacy & Security > Analytics &
  Improvements > Analytics Data, a file beginning with `TinyBiggot`).
- It runs but looks wrong: a screenshot from him is worth more than guessing.

## Stage 2: performance patch

**Ask first.** He turns on OPTIONS > SHOW FPS in the app and sends the line
(`FPS  LOGIC  DRAW  CALLS  WORST`) from four moments: the title screen, an
ordinary fight, the busiest fight he can make (a late build, many shots), and
a guardian that fills the room with shots. And whether anything stutters, and
when.

Read the numbers like this. `LOGIC` and `DRAW` are milliseconds of script
time per frame; together they should stay under about 8 on the iPad, which
leaves the graphics chip half the frame. `WORST` is the longest frame of the
last second: 17 is steady, 33 is one missed frame.

- [ ] 2.1 Get the numbers. If all four are steady at 60 with `WORST` near 17,
      write that down here and close the stage: there is nothing to patch.
- [ ] 2.2 If `LOGIC` is high: profile that fight with
      `tests/heavy_profile.tscn` and `tests/shot_profile.tscn` and take the
      top one or two costs. The rules must give the same results (replays).
- [ ] 2.3 If `DRAW` is high: `--perf --perf-all` lists every painter. Known
      and not yet touched: circles, arcs and polylines are rebuilt by the
      engine on every redraw; a ring or beam drawn as a sprite costs less.
      The picture must not change (compare frames before and after).
- [ ] 2.4 If only `WORST` jumps: find what happens at that moment (he should
      name it: "first time I open the inventory"). `--hitch-log=20` prints
      long frames with their tick. First-use stalls are covered in
      `IOS_BUILD.md`; anything new goes into `scripts/render/warmup.gd`.
- [ ] 2.5 Build a new IPA, and he confirms on the iPad.

Not allowed as a "fix": fewer particles, shots, effects or enemies, a lower
shot cap, a lower frame rate.

## Stage 3: stability check

Each step ends with `tools/check.sh` green.

- [ ] 3.1 **The save file.** `Meta.write_save` writes in place; on a full disk
      the file is left empty and his progress is gone. Write to a temporary
      file, read it back, then rename (the pattern is `Img.write_whole` in
      `scripts/core/img.gd`). A damaged save must load as a fresh one without
      an error, and must not be overwritten until the next real save. Add a
      test.
- [ ] 3.2 **Known small fault:** hit points can stay above the maximum after
      a synergy is lost. Find it, fix it, add a test.
- [ ] 3.3 **Long soaks, no screen.** Every hero, floors 0-10, all 8 rift
      worlds, `--classic`, both options off, three loops: at least 10 minutes
      of game time each (`--quit-after 36000`), with `--weapon-cycle=1` in
      half of them. Not one line with `SCRIPT ERROR`, `ERROR:` or `WARNING`.
      Print the object count (`Performance.OBJECT_COUNT`) every minute in one
      30-minute run: it must level off.
- [ ] 3.4 **Menus under random input.** Add a debug option that presses
      random buttons in every menu and during play (the "monkey"), seeded, and
      run it for an hour of game time. Same pass condition.
- [ ] 3.5 **Leaving and coming back.** On iOS the game stops when the app
      goes to the background. Check by reading the code that nothing depends
      on wall-clock time across that gap (cooldowns, music), and that a run in
      progress is not lost. Tell him what to try on the iPad: lock the screen
      in a fight, come back.
- [ ] 3.6 New IPA; he plays it.

## Stage 4: new content

He asked for **10+ rooms, 100+ weapons, 10+ characters with their own
playstyles**, and that **every weapon, relic and piece of equipment feels
unique**. The game has 252 weapons, 14 heroes, 26 named combos, 11 floors, 8
rift worlds and 9 event rooms already.

What "unique" means here: an item differs from every other in what it does,
not only in its numbers. For a weapon that is at least one of: how it attacks
(shape, rhythm, range), what a hit sets off, a condition or resource of its
own, or what it scales with. Two swords that differ by 10% damage are one
sword.

New content must not change the original game: original items keep their
numbers, and `tests/replays/classic/` stay identical. Re-record the
full-content replays (`tools/replay.sh record`) at the end of each step that
adds content.

- [ ] 4.1 **Take stock.** Write `UNIQUENESS.md`: every weapon, relic and gear
      piece with a short "signature" worked out from its data (kind, attack
      pattern, effects, conditions). List the groups whose signatures are the
      same or nearly so. No changes yet. Tell him the count and three
      examples.
- [ ] 4.2 **Make the duplicates different.** For each group from 4.1 give all
      but one a mechanic of its own. Nothing is deleted, and original items
      are left alone (they are the classic game). Largest groups first; stop
      at about 40 items a session.
- [ ] 4.3 **Ten new rooms.** Ask him first what he means by a room (a layout
      to fight in, a special room like the shop or shrine, or an event). Until
      he says, plan for a mix: 4 fight layouts with a feature of their own
      (moving walls, a pit, a turret, light and dark), 3 special rooms, 3
      events. Each needs its tiles or objects, a place in the room choice, and
      a line in `tests/rift_test.gd` or `tests/content_test.gd`.
- [ ] 4.4 **Ten new characters.** Send him one line per character first
      (name, weapon, the one thing that makes it play differently) and wait
      for his yes. No two may share a mechanic with each other or with the 14
      there are (`HEROES.md`, `GAOLBIRD.md`). Build two or three a session:
      sprite, weapon, passive, special, skill branch, unlock price, tests. The
      Gaolbird is the model for depth.
- [ ] 4.5 **A hundred new weapons.** In batches of 20 to 25, each batch a
      theme (for example: thrown, summoning, charged, two-stage, cursed).
      Every weapon passes the "unique" test above against all weapons, old and
      new; put its signature in `UNIQUENESS.md`. Each needs an icon, and a
      shot or swing picture if no existing one fits. `tests/content_test.tscn`
      must pass and all shown text must fit the font.
- [ ] 4.6 **Relics and gear** to go with them, if stock-taking showed thin
      spots (a build type with few relics, a gear slot with look-alikes).
- [ ] 4.7 After each of 4.3 to 4.6: a new IPA, and three things for him to
      try.

## Stage 5: sprite revamp

He wants every sprite redrawn in a stronger pixel style. The influences are
in `CLAUDE.md`; they are for mood (bold shapes and outlines, readable
silhouettes, lively shading, glow on magic). Every sprite is drawn new.

Rules for the art:

- **Same file names, same sizes, same frame layout** as the graphic replaced
  (heroes are 12x14). Then no hit box, room or menu moves, and the work is
  only art. If he wants bigger sprites, that is a different and much larger
  job: say so before starting.
- One palette for the whole game, written down in `ART.md` with the outline
  and shading rules, so 800 graphics look like one game.
- Must read at the iPad's scale (5x) against every floor's tiles.
- The ability and attack effects were redrawn in October (`EFFECTS.md`,
  `ATTACK_EFFECTS.md`). Leave them unless they clash with the new look.

- [ ] 5.1 **A sample, for his yes.** Redraw one hero, three foes, one
      guardian, five weapon icons, one floor's tiles and the hearts. Send him
      one picture: old on the left, new on the right, at 5x, and a screenshot
      of a fight using them. Do not go on without his answer.
- [ ] 5.2 Heroes (14, plus any from stage 4) and their gear overlay
      (`scripts/render/hero_gear.gd`).
- [ ] 5.3 Foes, champions and guardians.
- [ ] 5.4 Weapon, gear and relic icons.
- [ ] 5.5 Tiles and room objects, floor by floor.
- [ ] 5.6 Menus, HUD and the pixel font (the font last and only if he asks:
      every string in the game is measured against it).

After each of 5.2 to 5.6: `tools/bake_atlas.sh`, `tools/check.sh`, a
before-and-after picture for him, a new IPA.

---

## Log

- 5 Oct 2026: 1.1 done. First IPA built on GitHub (28 MB, arm64, release
  engine, not signed). Its game files run in a desktop player.
