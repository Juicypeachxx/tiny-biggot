# Re-sprite with Gemini (his test, 20 Oct, branch tiny-biggot-V2 only)

His word: "ill try to respite a game with new gemini, can you make me the file soo gemini could
resprite the game and then you will package it to ipa". README.txt and PROMPT.txt are his steps.

## The tools (Python 3 with Pillow; run from the top of the repo)

- `tools/inventory.py`: sorts every picture in `tiny_biggot_godot/assets/graphics`:
  - **redrawn by Gemini** (1946): heroes, foes, guardians, people and pets, room things,
    weapons, gear, relics, traits, other items and icons.
  - **made again by the import** (308):
    - every `X_elite` from the new `X`;
    - the `_s2`/`_s3` phases of the guardians and champions in the art tools' EVOLVE and MINIS
      (and Rex) from the new base.
  - **kept** (356): fonts, dots, glows, effects, shots, the floor kits, the logo, shadows, and
    pictures that are mostly half-see-through (smoke, glowing orbs and staffs).
- `tools/make_sheets.py`: writes `sheets/` (1024 x 1024 each) and `sheets/plan.json` (every
  picture's box).
  - On each sheet: a grey board, a grid, every picture enlarged with square pixels on a pink
    #FF00FF box its own size.
  - Half-clear pixels are drawn solid or clear.
- `tools/import_sheets.py [folder] [--out DIR]`: reads the finished sheets (default `done/`,
  png/jpg/webp, any size) back into the game. For each sheet:
  - scaled back to 1024;
  - the shift Gemini made is found by laying the plan's pink boxes over the picture's pink;
  - every game pixel is the colour most of its square has, and a square that is mostly pink is
    clear;
  - a box that comes back as it was sent is left alone.

  Then the elites and phases are made from the new bases. The phases use the art tools' own
  `form`/`evolve`/`cute`, which rebuild today's phases pixel for pixel from today's bases.

## Checked (20 Oct)

- **The sheets sent back unchanged:** 0 pictures changed.
- **The sheets doubled, blurred, moved and saved as JPEG:** every picture's shape exact
  (0 of 366,007 pixels wrong), colours within 2/255 (median).
- **The rebuilt elite look** next to today's: the same idea (darker, gold outline), without the
  small extra marks some elites have.

## After he sends sheets back (into `resprite/done/` or the chat)

1. `python3 resprite/tools/import_sheets.py`.
2. `GODOT=... bash tiny_biggot_godot/tools/bake_atlas.sh`, then `tests/atlas_test.tscn`, and a
   screenshot of a fight to look at.
3. The IPA:
   - set VERSION to a number of its own (e.g. 59.1), so `ipa-59` stays his normal build;
   - add its line at the top of `scripts/data/versions.gd` (`59.1|Gemini Sprites|...`);
   - commit with `[ipa]`: build-ipa.yml builds any branch but windows-build.

   The "latest iPad build" release will then be this test.

## His first sheet back (20 Oct: 02-foes, from Gemini)

- **The layout was not kept:** pictures moved and changed size and run into each other (so they
  cannot be cut apart automatically); a few are doubled; some foes became other creatures (the
  worm a spider, the frog an armoured warrior); some are missing.
- **About half could be matched by eye** (15 of 30).
- **Gemini drew much finer pixels than the boxes ask for**, in a dark palette. Shrunk to the
  game's size (12 to 16 px) most of them become dark smudges; only the simple shapes still read
  (the red lips, the bomb sack, the door, the black blob, the ring).
- Nothing was put into the game. His choice is pending:
  - a stricter retry;
  - a double-detail V2 (sprites drawn at 2x and shown at half size, so Gemini's detail survives:
    a bigger job);
  - or keep today's art.
