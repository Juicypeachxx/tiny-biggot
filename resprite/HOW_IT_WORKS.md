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

## 21 Oct: the look he picked, and where it stands

- **His pick.** His word: "keep the vibe and theme of it, make same art style vibe on all sprites
  in the game and show me sprite sheets of what you made step by step and then when all is good
  we will upload and package it". The look is Gemini's "Style 1, gritty dark fantasy"
  (`gemini/style-sheet-21oct.jpg`), on **every** sprite.
- **Double detail.** Every sprite at twice its size (a 16 px foe becomes 32 px), drawn at half
  size in the game: today's size, twice the detail. The engine work is still to do:
  - the viewport at 896 x 576 and every canvas at x2;
  - Gfx and Img knowing which pictures are double;
  - touch and mouse positions halved;
  - the atlas bigger.
- **Rule 3.** Take the look, never other works' characters: two of Gemini's warriors are
  practically Guts (Berserk) and Geralt (The Witcher).
- **Done.**
  - `tools/gritty.py`: an automatic gritty remaster at x2 (`gritty` gentle, `gritty2` stronger).
    Shown to him: it keeps every creature and adds light, grit and colour, but not Gemini's
    detail.
  - `tools/gemini_cut.py`: his 14 Gemini foes that match a foe, in `hd/`. The bat, crawler,
    bandsman and biker come out too dark at game size.
  - `tools/review.py`: the review sheets (today next to new).
- **His last word.** He then asked for all sprites truly like Gemini's.
  - Gemini's API is blocked from the container: generativelanguage.googleapis.com was refused.
  - He added the SpriteCook and CellCog plugins and opened `mcp.spritecook.ai` and `cellcog.ai`
    in the environment's network settings.
  - `spritecook.ai` was still refused at the last check.
  - Their MCP servers connect at session start, so this needs a new session.
- **Next** (a new session, with the SpriteCook tools there):
  1. Its workflow-essentials and generate-sprites skills first; then `get_credit_balance`.
  2. Upload his style sheet as the style reference.
  3. Make 6 to 8 of sheet 02's foes at 32 x 32 in that look.
  4. Lay them out with `tools/review.py` (put them in `hd/`) and show him.
  5. Then batches: heroes, foes, guardians, people, items, a sheet each.
  6. Then the engine's double detail, the import, IPA 59.1 "Gemini Sprites".

**21 Oct, later session:** the network now lets `mcp.spritecook.ai` (200) and `spritecook.ai` (307)
through, but the SpriteCook tools were still missing: no SpriteCook plugin or connector on his
claude.ai account (ListPlugins and ListConnectors found none for "sprite"). Nothing was made; no
credits spent. He needs to add SpriteCook as a plugin or connector on claude.ai and start a new
session.

## 21 Oct: SpriteCook connected, first test made

- **The connector works** in session 2ee66c08 (his paid account). Pictures cost credits: Nano
  Banana 2.1 is 12 a picture, Nano Banana 2 Lite 8, GPT 2.5 Flare 5/8/25 (low/medium/high).
  About 792 credits were left after the test.
- **The test (his ask: "first resprite characters and bosses").**
  - Made: 2 heroes (hexer, brute) and 2 guardians (colossus, sporemother), Nano Banana 2.1,
    48 credits.
  - The style guide is `spritecook/style-guide.png`: 10 of his Gemini foes at x4.
  - The reference for each is the game's sprite today, enlarged.
  - All four came back. SpriteCook sizes: 82, 30, 66 and 62 px square.
- **Downloaded** once he allowed `api.spritecook.ai` in the network settings (it reached this
  running session at once).
  - Kept as given in `spritecook/<name>.png`, fitted into `hd/` by `tools/spritecook_fit.py`.
  - `spritecook-assets.json` holds every asset id (style guide, references, the four) with sha12.
  - Fresh links: `get_asset_metadata(asset_id)`; they last an hour.
- **The shrink.** SpriteCook takes the size only as a hint: the hexer came back at 82 px for a
  24 x 28 sprite.
  - The Gemini cuts' fit (area average, then 24 colours) faded its eyes into the hood.
  - `spritecook_fit.down()` keeps a small bright or vivid detail (eyes, amulet, the skull's red
    eyes, the cap's spots) when it is rare among the pixels around it. So the skull's teeth stay
    an average.
  - No colour cut: 32 colours put a purple pixel into the hexer's eyes.
  - `gemini_cut.fit` now shares `frame()` (stand at the bottom middle, outline); its 14 foes came
    out byte-identical.
- **Shown to him:** the four as SpriteCook drew them, and `review.py` (today next to new, same
  size on screen).
- **If he likes it:**
  - The other 32 heroes at 12 credits (384).
  - The other 42 guardians' main pictures on Lite at 8 (336), if Lite holds up on one first.
  - That makes about 720 of the 792.
  - The EVOLVE and MINIS guardians' later phases come from the main picture through the art tools.
    The special guardians' extra poses come later.
