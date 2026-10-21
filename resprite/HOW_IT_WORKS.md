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

## 21 Oct: moving characters (his video: a wizard's idle loop)

- **His ask:** "can he make move like this for all characters". The video is a small wizard in
  an idle loop: breathing, the beard swaying, the hand with a flame bobbing. It was not made on his
  account.
- **What SpriteCook offers:** `animate_game_art` turns one of its pictures into a loop: idle,
  walk, attack, hurt or death.
  - About 20 credits a motion with the basic background removal.
  - A walk from the character workflow also needs a walk pose (+12).
- **Test:** the hexer's idle, 8 frames, 20 credits (772 left).
  - Saved as `spritecook/hexer_idle.png` (8 frames of 94 px in a row).
  - Fitted by `tools/spritecook_anim.py hexer idle 8`: every frame shrunk by the same amount and
    stood in the same place → `hd/hexer_idle_0..7.png`.
  - At game size the sway and the eyes' pulse survive. Small details flicker a little between
    frames (the amulet).
- **The free one:** `tools/idle_free.py`. Made from the still: the upper body breathes down a
  pixel, and the bright details pulse. Simpler, no credits.
- **What it costs for everything.**
  - Idles: 34 heroes 680, 44 guardians 880.
  - The stills still to make: about 720.
  - So the stills and the hero idles together need about 1,400 credits.
- **In the game.**
  - Today a hero is one picture: a 1 px bob when walking, squashes for dodge and leap.
  - Frames need the engine step (V2's double detail): pick the frame from time, each one a little
    out of step, and all frames in the atlas (small: 34 x 8 x 24 x 28).
  - The gear painted over the hero (`HeroGear.draw`) must follow each frame's head height.

## 21 Oct: the first sector (his ask: "finish one sector with those credits, at least bosses")

- **The sector is floor 1, THE OSSUARY.**
  - Foes: bat, slime, skeleton, mushroom.
  - Guardian: ARCI (his border collie). Since 58 he guards floor 1 in the Colossus's place.
  - Every run starts here, and floor 2 shares most of its foes.
- **Made (Nano Banana 2.1, 12 credits each).** The references are today's sprites at x8,
  uploaded with `create_asset_upload` now that `api.spritecook.ai` passes.
  - The bat, slime, skeleton and mushroom.
  - ARCI standing, lying and running, his frisbee and his stick.
  - His catch: the first lying ARCI had his head the right way up on a body lying on its back.
    An edit turned the head upside down (+12). The first try is kept as "rejected" in the manifest.
  - 120 credits this round; 652 left.
- **ARCI's stages are free:** `tools/arci_stages.py`, made the way today's stages are.
  - Stage 2: steel-blue eyes under a dark brow, placed by hand for these pictures. The lying one
    has its eyes shut, so its stage 2 is the same picture.
  - Stage 3: stage 2 with a dotted gold rim.
- **Fit changes.**
  - No extra outline on SpriteCook pictures: they bring their own, and painting one over the edge
    pixels ate the skeleton's thin bones. `frame(..., outline=False)`. The Gemini cuts are
    unchanged.
  - Density per sprite (`spritecook_fit.density`).
    - 4 for a guardian the game draws at scale 2 (the colossus and spore mother are now 64 x 64,
      about SpriteCook's own size).
    - 2 for everything else, ARCI included: at 4 he would be 144 px tall, past the atlas's 96.
  - `review.py` shows the new one at the same size on screen whatever its density.
- **His GIF ask:** `floor1_cast.gif` is the cast at true game proportions, moving with
  `idle_free` (no credits).
- **His mob sheets (two small pictures in the chat).** They only reached the chat as small images,
  not files, so nothing can be cut from them yet. Asked for the files and where they come from
  (rule 3). Two of them look like well-known D&D monsters: leave those out.
- **To finish floor 1:** the other 32 heroes (384 credits). Then the engine step and the IPA.

## 21 Oct: sheets of 9, and then his bright look

- **Sheets of 9 (cheap and the layout holds).**
  - `tools/sheet_ref.py OUT COLS [--fill] NAMES`: today's sprites enlarged in a 3 x 3 grid, uploaded
    as the reference. `--fill` enlarges each one to fill its cell (guardians).
  - `tools/sheet_view.py`: the same grid with names, to write the prompt's hints from (never
    uploaded). Hints written from a picture without names went to the wrong cells once.
  - The prompt names every cell, row by row: "Top row, left to right: the Hexer, a purple hooded
    witch ...". `smart_crop=false`, so the grid survives.
  - `tools/sheet_add.py SHEET ASSET JOB REF MODEL CREDITS 3x3 LABEL NAMES`: one step for a
    downloaded sheet. It goes into the manifest, is cut (`sheet_cut.py`: each solid piece belongs
    to the cell its middle is in; a piece running over a grid line is cut at its thinnest line
    there), each cell becomes the "made" picture of its name, and is fitted.
- **First pass (gritty):** GPT-Image-2 low, 2 credits a sheet: the 34 heroes, 44 guardians and
  the specials' poses, 31 champions, 14 props. Kept as alternatives:
  `spritecook/gritty/`, `spritecook/sheets/gritty/`.
- **His new word (21 Oct, evening):** "i want this vibe in all my sprites please do it", with a
  picture of a bright, clean, colourful monster sheet. That look replaces the gritty one.
  - Rule 3: only its look is used, never its monsters. The picture is a SpriteCook style guide
    (in the manifest); it stays out of the repo because we don't know where it is from.
- **GPT-Image-2 was down.** Every job failed with "This request could not be processed", even a
  plain apple. Failed jobs are refunded. So these sheets are **Nano Banana 2.1**: 12 credits a
  sheet, 18 at 2K. Its look is very close to his picture.
- **Done in his look (sheets `spritecook/sheets/bright_*.png`):**
  - heroes h1 to h4 (34);
  - guardians g1 to g4 (36, at 2K) and the specials s1, s2 (15 poses);
  - champions c1 to c4 (31);
  - props p1 to p3 (14).
  - Review sheets: `sheets/review-heroes.png`, `-guardians`, `-guardians-big`,
    `-special-guardians`, `-champions`, `-guardian-props`.
- **What Nano Banana does:**
  - It draws a person about 74 px tall and a guardian about 85 px, at 1K or 2K, on a 3 x 3 or a
    2 x 2 sheet alike. Asking for bigger did not work (two tries, kept as "rejected").
  - Its first specials sheet came out coarse with a faceless Seraph: redone with the s2 sheet
    (Sefe drawn right) as the style image.
  - Long things lying flat (the stick sword, the fetch stick) came out on a slant: redrawn alone,
    side by side on a 16:9 sheet, "lying perfectly flat".
- **Density** (`spritecook_fit.density`): 4 for the guardians drawn at twice size (64 x 64), 2 for
  the rest. A drawing under three quarters of double size stays at 1, the old size: the potato
  crate and Sefe's long cigarette. Sefe, the Prophet and running ARCI are 82 to 94% of double size,
  so they show a little smaller.
  - The only limit on 4 is the atlas's 96 px height (`Img.ATLAS_MAX_H`; widths up to 1024 pass).
  - "Big enough" is measured on the drawing's longer side after the fit: today's stage pictures
    are often wider (wings spread sideways), and the old rule (longest sides compared) dropped
    37 stage pictures to 2 while their stage 1 was at 4.
  - Left at 2: the Bilge Hydra's stages 2 and 3 (over 96 px tall at 4) and the Author's stage 3.
- **Stages 2 and 3 (20 sheets, Nano Banana 2.1).**
  - Reference: today's stage sheet (`stage_*`, in the manifest). First style image: the new
    stage-1 sheet, so the design stays; the second: his picture.
  - The prompt: "the same bosses as in the first style image, in the same places and with the
    same design, now in their second, angrier stage exactly as the reference sheet shows it.
    Keep every change the reference shows: the extra horns, spikes, wings, crowns, flames,
    cracks, glowing eyes, new colours" (stage 3 adds "glowing aura rims").
  - The specials' changes are named one by one: Rex's party hat and bandana, then his crown and
    throne; ARCI's sunglasses, then a gold rim; Sefe's crown and chain, then a green rim and red
    eyes; the Prophet's burning END! sign, then THE END.
  - `tools/stage_review.py`: each one at stage 1, 2 and 3 side by side
    (`sheets/review-guardian-stages-1`, `-2`, `-big`, `review-special-stages`,
    `review-champion-stages`).
  - The Reader (a big face) becomes a small winged, crowned figure in stages 2 and 3, as today's
    stage pictures suggest. Kept.
- **Credits:** 2775 before his look; 2151 after every hero, guardian, champion and prop, and
  all their stages (624 spent, 66 of them on four tries kept as "rejected").
- **Next:**
  1. The elites: made from the new pictures (gold outline, darker), no credits.
  2. Then his order: environments, foes (182), weapons and effects.
  3. Then the engine's double detail and IPA 59.1.
