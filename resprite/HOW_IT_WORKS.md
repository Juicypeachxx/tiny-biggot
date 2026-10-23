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

## 21 Oct: environments (room objects and floors)

- **Room objects (91):** props, wall dressing, chests and furniture, in six 4 x 4 sheets
  (`spritecook/sheets/bright_e1` to `e6`, Nano Banana 2.1, 12 credits each). Reference: today's
  pictures enlarged in a grid, as for the characters. Review: `sheets/review-room-things`, `-2`,
  `-3`.
- **Floors (43 sets, one texture each):** `tools/kit_build.py KIT TEXTURE` (or `--all`).
  - SpriteCook draws each floor as one seamless texture: `generate_game_art(mode="texture",
    bg_mode="include", smart_crop=false, width=32, height=32, pixel=true)`, his picture as the
    style image. The prompt: "seamless tileable top-down floor texture for <the place>:
    <material>. Clean bright pixel art in the look of the style guide, soft shading, calm and
    low contrast so characters stand out on it. No objects, no text." Each material follows
    today's floor colours; the manifest (kind "floor") has every one.
  - The pixel output (about 278 px) is seamless; the raw 1024 one is not. The transparent
    background mode cut holes in light stones, so always "include" (`fill_holes` mends holes).
  - Stones and tiles "of different sizes" work. Planks, carpet and small squares can make the
    pixel step collapse the picture (12 px, 32 px): asked again as stone or tiles. 8 tries are
    kept as "rejected" (one was the service being down, refunded).
  - Shrunk to 136 px (stones about the size of the old tiles), never enlarged; the kitchen's
    checker stays at 256 (`SIZES`). Calmed: contrast x0.6, a little darker, and no lighter than
    125 on average unless today's floor is paler (heaven stays cream).
  - Walls, the pillar and the rest: today's pieces at x2, in their own colours. Recoloured to the
    floor they lost each place's look (the red cathedral, the white Redacted), so that was dropped.
  - Lighter than today, his call: the first floor (grey-mauve stone, was purple), kit13
    (lavender, was dark purple), kit15 (orange sandstone, was dark brown).
  - Files: `spritecook/kits/<kit>.png` (as drawn), `hd/<kit>_floor.png` (the floor, to repeat
    over the room), `hd/<kit>.png` (today's kit layout at x2).
  - Review: `sheets/review-floors-1.png` (the numbered floors) and `-2` (the named places):
    today's floor and walls left, the new ones right. `sheets/review-rooms.png`: four mock rooms
    with the new floors, objects and characters (a mock, not the game's own drawing).
- **The engine needs (double-detail step):** to draw `<kit>_floor.png` repeated over the room
  instead of a random tile per cell. Row 0 of `hd/<kit>.png` (16 pieces of the texture) is only
  a stand-in: its pieces do not join up with each other.
- **Credits:** 2151 before, 1479 after (672: room objects 72, floors 516, tries 84).
- **Next (his order):** foes and people (4 x 4 sheets), then weapons, items and effects; the
  elites are made from the new pictures. Then the engine's double detail and IPA 59.1.
  (22 Oct he moved the effects first: see the next section.)

## 22 Oct: effects and skills

His word: "Before mobs can you do the effects and make super cool ones also keep original forms,
after effects and skills do the mobs". So the order is now: effects and skills (done here), then
foes and people, then weapons and items.

- **Redrawn (108 pictures):**
  - every effect strip (`fx_*`): the explosions in three sizes and five colours, shatter, zap,
    crit star, smoke, flames, dust, poison pool, scorch, falling rock, bubbles, frost, stars, and
    the marks over foes;
  - the attacks: `swing_*`, `slash_arc`, hit star, cut mark, cast ring, flare, muzzle flash, plus;
  - the foes' shots: `eb_*` with their rims `ebr_*`, and `orb_*`/`orbr_*`;
  - your shots: `shot_*`, all 17 weapon families.
- **Skills** have no pictures of their own. Hero skills are drawn from these pictures, plus lines
  and rings drawn in code, which stay as they are.
- **Method** (`tools/fx_ref.py`, `fx_fit.py`; `fx_make.sh` rebuilds everything in about 5 s):
  - **Reference:** today's frames enlarged x4 in a grid, on the game's dark colour (#1a1423).
  - **The ask:** the prompt names each cell's animation. Nano Banana 2.1, background "include"
    (flat dark navy, keyed out), his picture and the first new explosion as style images.
  - **Size:** Nano Banana draws an effect sheet about 175 pixels across whatever the grid, and
    keeps the reference's place for each frame. So a frame comes back at about
    `fill x 175 / (cols x biggest frame)` times today's size.
  - **Density:** the grids were chosen for density 1 (the game's own size: the big explosions,
    the swings, the marks) or 2 (the small explosion, shatter, zap, smoke, the foes' shots, your
    shots).
  - **Cutting:** the cutter looks a quarter of a frame round each cell and takes the window that
    lies best on today's frame (the sheets came back 3 to 4 pixels higher than the grid). A frame
    drawn a little bigger or smaller than its density is scaled; when it shrinks, its pixels are
    averaged.
  - **Forms, `--clip`:** the new art is kept inside today's form plus one game pixel, not across a
    thin shape such as a bolt. Used for the swings, the hit star, flare, cast ring, muzzle flash,
    the foes' shots and your shots. SpriteCook drew the slash as a big centred crescent; clipped,
    it sits where today's does.
  - **Forms, `--under`:** today's frame goes under the new one where SpriteCook drew less (the cut
    mark).
  - **Grey:** the strips the game tints (a hit in the weapon's colour, the swings, the cast ring,
    the muzzle flash, the flare, the plus) are kept grey (`--grey`), so the tint still works.
  - **Colour swap:** today each explosion colour and each weapon family is one drawing in several
    palettes, pixel for pixel. So the explosions' other colours (frost, gold, venom, void) and
    your shots' other 16 families are the new drawing with its colours swapped
    (`fx_recolour.py`, `fx_shots.py`): each new pixel takes the twin of today's colour nearest
    it, at its own lightness.
  - **Kept from today:** the big explosion's last two frames (a few embers, in the new colours)
    and the bubble's first frame (SpriteCook drew that 3-pixel dot cyan).
  - **Rims:** the foes' shot rims (35.3) are made again round the new shots (`fx_rims.py`), one
    game pixel wide.
- **Measured:**
  - Every new picture is exactly today's size x 1 or x 2.
  - For the big frames, the new art covers 70 to 95% of today's outline. Thin sparks and specks
    cover less; by eye they match.
- **Review:** `sheets/review-effects-explosions`, `-skills`, `-attacks`, `-foe-shots` (the .gif
  plays them with today on the left and the new one on the right; the .png shows every frame),
  and `sheets/review-shots.png`.
- **The engine needs (double-detail step):**
  - Effects at density 2 need the strip code (Vfx._strip, Afx, the shot shader's rects, EBullets)
    to read a strip's density (its height divided by today's) and draw it at today's size.
  - Density-1 effects can replace today's files as they are.
  - The swapped colours are already in `hd/` as full sheets, in today's layout.
- **Credits:** 1479 before, 1263 after (216 for 18 sheets).
- **Next (his order):** foes and people, then weapons and items; the elites from the new
  pictures. Then the engine's double detail and IPA 59.1.

## 22 Oct: foes, people and pets

His word: "do weapons and mobs then". So the order is now: the mobs (done here), then the weapons
(382 `w_*` pictures), then the other items.

- **Redrawn (206 pictures, every one at double detail, exactly today's size x 2):**
  - all 147 foes, in the order of ENEMIES in `game_data.gd`;
  - the 59 people and pets: the town's people (`npc_*`), the camp cat, the familiars (`fam_*`),
    the pets (`pet_*`) and the summons (`s_*`).
- **Method** (`tools/mob_sheets.py` makes the references and prompts into
  `spritecook/refs/`; `mobs_plan.json` keeps each sheet's prompt and SpriteCook ids):
  - 13 sheets of 16 (4 x 4), the same way as the characters: today's sprites enlarged on clear
    as the reference, a few words for each in the prompt ("a skeleton archer", "a pet owl"),
    Nano Banana 2.1, his picture and the champions' sheet `bright_c1` as style images.
  - `tools/sheet_add.py` cuts each sheet and fits each sprite at double detail (24 pixels for
    today's 12).
- **Second takes:** 12 had drifted from today's picture, because the name misled it (the biting
  book came back a little dragon, the walking card an empty frame, the friendly archivist a hooded
  figure). Sheet `r2` described today's picture instead of the name, and all 12 came back right.
  A first try at a 2 x 2 sheet (`r1`) is not used: it draws them about 80 pixels high, and they
  turn to mush when shrunk to 24. Keep 4 x 4 sheets (about 50 pixels) for 12-16 pixel sprites.
- **His Gemini foes** (17 of them, 20 Oct) are kept in `gemini/foes/`; the new ones replace them
  in `hd/`, so all foes share one look.
- **Review:** `sheets/review-mobs-01` to `-13` and `-retry` (today on the left, the new one on the
  right).
- **Credits:** 1263 before, 1083 after (180 for 15 sheets).
- **Next (his order):** weapons (382 `w_*`), then the other items; the elites from the new
  pictures. Then the engine's double detail and IPA 59.1.

## 22 Oct: weapons

The second half of his "do weapons and mobs then".

- **Redrawn (396 pictures, every one at double detail, exactly today's size x 2):** every `w_*`
  weapon. That includes 14 magic staffs that are mostly a soft glow, which the inventory's count
  of 382 leaves out.
- **Method** (`tools/weapon_sheets.py` makes the references and prompts into
  `spritecook/refs/`; `weapons_plan.json` keeps each sheet's prompt, ids and failed tries):
  - 11 sheets of 36 (6 x 6), sorted by kind (the swords together, the staffs together).
  - Each one named in the prompt by its name in the game and its kind ("hunting bow",
    "acid jar (potion flask)").
  - Nano Banana 2.1, with his picture, the champions' sheet `bright_c1` and the first weapon
    sheet `bright_w01` as style images.
  - Each keeps the direction it points today: a sword up and to the right, a gun to the right,
    a bow sideways.
- **Fitting** (`tools/weapon_fit.py`, after `sheet_add.py`):
  - The game turns a held weapon round the middle of its picture (`world_view.gd`,
    `_draw_weapon`). So each new drawing is shrunk into today's drawn outline at double size and
    centred on it, not stood at the bottom of its box like a foe.
  - Today's half-see-through pixels (the glow round 32 weapons) stay, enlarged, under the new
    drawing.
- **Trouble, and what was done:**
  - On 5 of 16 tries Nano Banana wrote each weapon's name under it, though asked not to. A later
    try added "never write any names" (w10). w02 was finally drawn from plain words with no names
    ("a pair of playing cards", "a crossbow"). The names on w06 were taken away
    (`tools/strip_labels.py`; `bright_w06_labels.png` is the sheet as drawn). Lesson: for item
    sheets, plain words invite fewer captions than names.
  - w08's second try drew 7 rows and tilted the guns. So its rifles, shotguns and last row come
    from its first try, which was drawn at half the detail; that is enough for thin guns.
  - A few follow their name more than today's picture: the fusion core is now an orb, and the
    bone reaper a sickle.
- **Review:** `sheets/review-weapons-01` to `-11` (today on the left, the new one on the right,
  at the same size on screen).
- **Credits:** 1083 before, 891 after (192 for 16 sheets: 11, and 5 tries again).
- **Next (his order):** the other items: gear (285), relics (140), traits (464), and the other
  items and icons (238). Then the engine's double detail and IPA 59.1.

## 22 Oct: gear, relics and icons

His "ok" to all the rest (after asking what it would cost: about 450 to 500 credits).

- **Redrawn (629 pictures, every one at double detail, exactly today's size x 2):**
  - gear (313): every `g_*` helm, hat, hood, crown, mask, armour, robe, cloak, boots, gloves,
    amulet, ring and charm, and the 28 offhands (`o_*`);
  - relics (140): every `relic_*`;
  - icons (176): food and golden food, drinks and draughts, fish and catches, charms, infusions,
    dice, keys, coins, bombs, hearts, map icons, the stat icons (`mi_*`), the rarity frames.
- **Method** (`tools/item_sheets.py GROUP` makes the references and prompts into
  `spritecook/refs/`; `<group>_plan.json` keeps each sheet's prompt and ids):
  - 18 sheets of 36 (6 x 6), sorted by kind. Gear and relics are named by their names in the
    game; icons by a few plain words ("a red heart", "golden food: bun").
  - Every prompt says never to write the names: none of the 19 sheets wrote any.
  - Nano Banana 2.1, with his picture, `bright_c1`, `bright_w01` and the first gear sheet
    `bright_g01` as style images.
  - Fitted like the weapons (`tools/weapon_fit.py`): each one inside today's drawn outline at
    double size, centred on it, so a pickup or an inventory icon sits where it does today.
- **Not here, on purpose:**
  - The traits (464): the game paints them in their family's colour. They need white shapes;
    see the next section.
  - Five pictures that belong to a character, not an item (the bat's second frame, the believer
    flexing, the hydra's head and neck, the bullet saint): they are made to match their
    character.
  - The foes' shot orbs (`orb_*`) were done with the effects.
- **One try again:** g06 came back 96 pixels across (far too small) the first time.
- **Review:** `sheets/review-gear-01` to `-09`, `review-relics-01` to `-04`, `review-icons-01`
  to `-05`.
- **Credits:** 891 before, 663 after (228 for 19 sheets).

## 22 Oct: traits and the odd pictures

The rest of his "ok" to all the rest.

- **Redrawn:**
  - every trait picture (464 `tr_*`), at double detail;
  - the five pictures that belong to a character: the bat's second wing beat (`bat2`), the
    believer flexing (`believer_flex`), the Bilge Hydra's head and neck piece (`hydrahead`,
    `hydraneck`) and the bullet saint (`bullet_saint`).
- **Traits, how** (`tools/trait_sheets.py` makes the references and prompts into
  `spritecook/refs/`; `traits_plan.json` keeps each sheet's prompt and ids):
  - The game paints a trait picture in its family's colour (`trait_view.gd`, the cube). So the
    new ones are white shapes with grey shading: the prompt asks for white and greys only, and
    `tools/trait_fit.py` turns what comes back into greys with its lightest pixel white. The
    family colour shows as strongly as on today's flat white shapes, and the shading shows as
    darker shades of it.
  - 13 sheets of 36 (6 x 6), sorted by family. The references are drawn on the game's dark
    colour: white shapes vanish on white.
  - Nano Banana 2.1, with his picture, `bright_g01` and the first trait sheet `bright_t01` as
    style pictures.
  - Fitted like the weapons: inside today's drawn outline at double size, centred on it.
- **Drawn again:**
  - t09 came back 133 pixels across (too small) the first time.
  - 18 traits came back as something else (a piggy bank as a wolf, a glass cannon as a sword, a
    shark fin as mountains). They were drawn again on one sheet with plain words for each
    (`trait_sheets.py fix`), each twice, and the better try kept (`tf2`). A first sheet with
    each once (`tf1`) came back with its top row cut off and the pictures in grey metal: not
    used.
  - OVERCRIT's two little sparkles under its stars were taken away, so its stars fill today's
    flat outline.
- **The odd pictures** (`tools/odd_sheet.py`, one 4 x 4 sheet, `bright_o1`):
  - The reference shows the new bat and believer beside today's second frame, and the prompt asks
    for the same one in the other pose: they match. Today's `bat2` is a red bat while `bat` is
    purple; the new one has the new bat's colours.
  - The hydra's new look (`bright_g2`) is a style picture for its head and neck. The neck piece
    came back curled round a hole, and the game draws six of them in a row: the hole is filled
    (`odd_sheet.py fill hydraneck`).
  - Their elite looks (`bat2_elite`, `believer_flex_elite`) are made from them at import, like
    every elite.
- **Review:** `sheets/review-traits-01` to `-13` (the final pictures), `review-traits-fix` (the
  18 drawn again), `review-odd`.
- **Credits:** 663 before, 459 after (192 for 16 trait sheets, 12 for the odd sheet).
- **Every picture is now redrawn:** `tools/inventory.py` finds none missing in any group. The
  308 elite looks and guardian phases are made from the new pictures at import. Next: the
  engine's double detail and the IPA.

## 22 Oct: the engine (double detail) and IPA 59.1

His word: "ok do the engine and make the ipa".

- **The new pictures in the game.** `tools/elite_hd.py` makes the 215 elite looks from the new
  pictures (a gold outline two of their pixels deep, as thick as today's, and a richer, darker
  body); the wisps and the kitten keep today's, as they have no new picture. Then
  `tools/hd_import.py` copies every new picture into `tiny_biggot_godot/assets/graphics_hd/`
  under its game name: 2494 (69 at today's size, 2280 with twice the detail, 102 guardians with
  four times, 43 floors). It checks each is exactly today's size x 1, 2 or 4; it makes a floor's
  odd side even; and the two floor marks that came back solid (`fx_scorch`, `fx_pool`) keep
  today's see-through shape (solid, a blast's scorch was a dark box on the floor).
- **The screen** (`project.godot`, `main.gd`, `TB.D`): 896 x 576, two pixels to each of the
  game's. The game still works in its own 448 x 288 pixels; the world and every layer over it
  (`_canvas`) are drawn twice over, and so are the floor's baked pictures (`world_view.gd`).
  Touch and mouse come in the screen's pixels and are halved (`TB.to_game`). It fills the iPad
  at a fractional scale (about 2.6 x), not the integer 5 x of 448 x 288: at an integer scale it
  would have been 2 x, a smaller picture than today.
- **The pictures** (`scripts/core/img.gd`):
  - The atlas holds every picture at two pixels to the game's: its new picture, or today's drawn
    twice. Its texture says it is half the size it is (`set_size_override`), and so does each
    picture's place in it: the game draws and measures every picture at today's size as before
    (Gfx, the effect strips, the shot shader's tables), and the finer pixels show. 2507 pictures,
    4096 x 2432, a 5 MB ready-made file (`tools/bake_atlas.sh`; the test checks it).
  - A guardian's picture at four times is a texture of its own (all its detail); so is a floor.
  - A tint's silhouette is made at the same detail and drawn at the picture's size.
- **Floors** (`world_view.gd`, `_paint_bg`): the room's floor is `<kit>_floor` repeated over it,
  where it has one; else today's tiles.
- **Traits** (`trait_view.gd`, the cube): the picture is drawn with its colour laid over it, so
  its grey shading shows as darker shades of the colour (today's flat white shapes took the
  colour whole, as a silhouette).
- **Measured** (the container, no iPad):
  - The same draw calls as today in a heavy fight (300 foe shots: peak 49 to 58 both).
  - The atlas loads in 1.25 s here (0.2 s today): 80 MB of pixels to unpack. A cloud machine is
    slow at this; the iPad should be well under a second.
  - The rules are unchanged: all 14 replays identical (classic and core). `tools/check.sh`:
    CHECK PASSED (the six unit tests that tap the screen now tap in the screen's pixels).
- **Not changed, on purpose:** the gear painted over the hero is still made of today's 12 x 14
  shapes, so a robe or hood still shows, over the new hero, in today's bigger pixels.
- **IPA 59.1 "Bright Sprites"** from this branch (`ipa-59` stays his normal build).

## 23 Oct: the armour on the hero in the new look (IPA 59.2)

His word: "make the armour on the hero in the new look too and package it to test".

- **Before:** the gear painted over the hero was today's 12 x 14 shapes in flat colours, in the
  game's big pixels, over the new heroes.
- **Now** (`scripts/render/hero_gear.gd`): drawn like the new heroes, two pixels to each of the
  game's (24 x 28 over the 12 x 14 hero), with a dark outline and five shades from the item's
  own colour (the commonest in its new icon), lit from the top left.
  - **Body, feet, hands** (robe, plate, leather, cloak; boots, greaves; gloves) take the shape of
    each hero's own picture, and its folds and lights: each of the hero's pixels there is given
    the shade of its brightness among them, in the item's colours. Then each kind its marks: the
    plate's seams, the leather's belt and buckle, the robe's sash and folds, the cloak hanging at
    the sides with its clasp. The new heroes are all drawn alike (head in the top third, the neck
    the narrowest row between, feet at the bottom), so one rule fits all 34.
  - **Head:** a helm (its dome, cheek guards and nose guard, the face left open), a hood (the
    face in its shadow), a hat, a crown, a mask: shapes of their own, over the head.
  - **Small pieces:** the amulet's chain and stone, a charm at the belt, a ring on each hand, a
    shield in the off hand.
- **Test:** `tests/gear_look_test` (in `tools/check.sh`): every kind of gear (18) on every hero
  (34) makes an outfit drawn at the hero's size; what goes on the body, feet and hands stays on
  the hero's picture; the same outfit twice is the same pixels. With `--sheet=PATH` it draws every
  hero bare and in five outfits.
- **IPA 59.2 "Bright Armour"** from this branch.

## 23 Oct: the pixel look (IPA 59.3)

His word: "can you make all sprites and textures little bit more pixelated and to fit my previous
style, now it feels all ai and sterile". Then, of the items: "this in my opinion does not look
good, you have some credits left if you find anything like this resprite it", and his picks
(asked with pictures): "Test 2 for all items" and the pixel look for the characters.

- **What made it look made by a machine:** many soft shades, thin pale edges, a speck of detail
  everywhere. His previous style (today's pictures) is a few flat colours inside a thick
  near-black outline, in big pixels.
- **Tried and left:** the new pictures shrunk to the game's own pixels (the faces turned into
  blobs); the floors in six colours with the sprites' bigger pixels (the joints broke into dots).
- **The pixel look** (`tools/pixel_look.py`; `hd_import.py` runs it on every picture going into
  the game, resprite/hd keeps them as they came; `python3 resprite/tools/pixel_look.py OUT NAMES`
  draws today / 59.2 / the pixel look in rows):
  - heroes, foes, guardians, people, pets, props: 5 to 16 colours (Oklab), no specks, bigger
    pixels where a game pixel's four agree (an eye or a line stays), more saturated with lighter
    middle tones, and today's outline: one game pixel thick, near-black leaning to the picture's
    main hue; dark lines inside take the same colour;
  - elites: made again from the pixel look (`elite_hd.elite`), so the gold is the outermost line;
  - floors and room kits: seven colours, each stone flat, the joints kept sharp, no outline;
  - traits: white and two greys, bigger pixels;
  - effects, shots and the pictures already at the game's pixel: left as they are.
- **The items drawn again** (`tools/pixel_sheets.py`, SpriteCook NB 2.1, 12 credits a sheet):
  - test 1, from today's (old) pictures: came back almost the same as the old pictures (kept as
    "rejected"); test 2, from the 59.2 pictures: his pick;
  - the reference is the sheet's 59.2 pictures x4; the style guide is the game's own pictures
    before V2 (`spritecook/style-old.png`, asset e6c03a1e-168d-461e-88ed-ab83464147f5);
  - SpriteCook gives a sheet back at about 32 of its pixels to a cell: each drawing goes into
    resprite/hd as it is (centred where today's picture is drawn), only one too big is shrunk;
  - 29 sheets, 1023 items: weapons w01-w11, gear g01-g09, relics r01-r04, icons i01-i05 (i02
    drew five of its six rows: its first four charms went onto i05b); the "made" pictures carry
    "look": "pixel" and go into the game as they are;
  - not yet: ch_clover and ch_coin (sheet i06 planned; SpriteCook was down) have the pixel look.
  - Pixel Engine (6 credits, true pixel art at the exact size) was down all day: worth a try.
- **The armour on the hero** keeps the hero's own near-black outline and lines (`_lines` in
  `hero_gear.gd`), so an armoured hero is outlined like a bare one.
- Credits: 459 before, 99 after (30 sheets).
- **IPA 59.3 "Pixel Look"** from this branch.
