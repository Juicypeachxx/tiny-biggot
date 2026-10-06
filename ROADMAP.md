# Roadmap

What is left to do, in the order the owner set on 5 Oct 2026:
**the performance and stability patch, then new content, then new sprites.**
`CLAUDE.md` has the rules. `HANDOFF.md` has the details of what was done so
far.

How to use this file: find the first step that is not ticked, do that one
step, tick it here, add a line under "Log" at the bottom, update `HANDOFF.md`,
push, tell the owner what to try, and stop. One step is one session.

**Every stage ends with a working IPA that he tests on the iPad.** The next
stage does not start until that IPA is built and he has been told what to try
in it.

**He steers while the work is going on.** If he asks for something else in the
middle of a step, do that first, write it into this file (a new step, or a
changed one), and carry on from there. What he says last outranks this file.

| Stage | What | State |
|---|---|---|
| 1 | The IPA installs and runs on the iPad | **Done** (he confirmed, 5 Oct) |
| 2 | Performance patch | **Done**: nothing to patch (he reports a good 60 fps, 5 Oct) |
| 3 | Stability patch | Done (3.4 and 3.6 delivered with the end of stage 4, 6 Oct) |
| 4 | New content: environments, mobs, bosses, weapons, equipment, relics, abilities, characters; everything unique | Done (6 Oct) |
| 5 | Sprite revamp: every sprite redrawn, "cool and pixelated" | **Next**: 5.1, a sample for his yes |

---

## Stage 1: the IPA on the iPad

- [x] 1.1 The game builds as `TinyBiggot.ipa` on GitHub (release `ipa-latest`).
- [x] 1.2 The owner installed it with SideStore: it installs and works.

If a later IPA does not install or start, that comes before everything else. Ask him
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

He has said the game needs this patch. He has not yet said what he saw.

**Ask first.** He turns on OPTIONS > SHOW FPS in the app and sends the line
(`FPS  LOGIC  DRAW  CALLS  WORST`) from four moments: the title screen, an
ordinary fight, the busiest fight he can make (a late build, many shots), and
a guardian that fills the room with shots. And whether anything stutters, and
when.

Read the numbers like this. `LOGIC` and `DRAW` are milliseconds of script
time per frame; together they should stay under about 8 on the iPad, which
leaves the graphics chip half the frame. `WORST` is the longest frame of the
last second: 17 is steady, 33 is one missed frame.

- [x] 2.1 Get the numbers. If all four are steady at 60 with `WORST` near 17,
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
- [x] 2.5 Build a new IPA, and he confirms on the iPad. (Not needed: nothing
      was changed, the IPA he has is the one he measured.)

**Closed 5 Oct 2026.** He reports the game runs a good 60 fps on the iPad.
2.2 to 2.4 were not needed. He did not send the full SHOW FPS lines, so if he
later sees stutter or a drop, reopen this stage with those four numbers.

Not allowed as a "fix": fewer particles, shots, effects or enemies, a lower
shot cap, a lower frame rate.

## Stage 3: stability patch

Each step ends with `tools/check.sh` green.

- [x] 3.1 **The save file.** `Meta.write_save` writes in place; on a full disk
      the file is left empty and his progress is gone. Write to a temporary
      file, read it back, then rename (the pattern is `Img.write_whole` in
      `scripts/core/img.gd`). A damaged save must load as a fresh one without
      an error, and must not be overwritten until the next real save. Add a
      test. (Done: also keeps the save before as a backup, loaded when the
      save is damaged. `tests/save_test.tscn`.)
- [x] 3.2 **Known small fault:** hit points can stay above the maximum after
      a synergy is lost. Find it, fix it, add a test. (Done: a lost synergy
      or combo is now taken back with the same limits as gear. Also fixed
      roll charges going below 0 when PHANTOM is lost.)
- [x] 3.3 **Long soaks, no screen.** Every hero, floors 0-10, all 8 rift
      worlds, `--classic`, both options off, three loops: at least 10 minutes
      of game time each (`--quit-after 36000`), with `--weapon-cycle=1` in
      half of them. Not one line with `SCRIPT ERROR`, `ERROR:` or `WARNING`.
      Print the object count (`Performance.OBJECT_COUNT`) every minute in one
      30-minute run: it must level off. (Done: `tools/dev/soak.sh`, 29 runs
      clean; object count levels off. See `HANDOFF.md`.)
- [~] 3.4 Moved to 4.10 at his request (5 Oct): the monkey test runs once
      the new content is in, so it covers that too.
- [x] 3.5 **Leaving and coming back.** On iOS the game stops when the app
      goes to the background. Check by reading the code that nothing depends
      on wall-clock time across that gap (cooldowns, music), and that a run in
      progress is not lost. Tell him what to try on the iPad: lock the screen
      in a fight, come back.
- [~] 3.6 Moved: he wants the next IPA only after the new content (5 Oct).
      It is built at 4.11 and carries the stage 3 fixes too.

## Stage 4: new content

He asked for new **weapons, environments, bosses, mobs and equipment**, and
before that for **10+ rooms, 100+ weapons and 10+ characters with their own
playstyles**, and that **every weapon, relic and piece of equipment feels
unique**. The game has 252 weapons, 14 heroes, 34 kinds of foe, 11 guardians,
26 named combos, 11 floors, 8 rift worlds and 9 event rooms already.

**What he asked for on 5 Oct (outranks the proposals below where they differ):**

- Weapons, equipment, relics and **abilities** with ideas from Enter the
  Gungeon, Slay the Spire, Worms Armageddon, Risk of Rain, Cabal, Aion,
  GTA V, Saints Row: The Third and Dead Cells. Ideas and mechanics only:
  every name, sprite and effect is our own (rule 3). No item may carry a
  name, character or logo from those games.
- Cool pixelated effects for them (in the look of `EFFECTS.md` and
  `ATTACK_EFFECTS.md`).
- Every part must feel mechanically new and be unique (the test below).
- **+1 projectile stacks without limit.** Every new weapon and effect must
  stay correct, readable and within the frame budget at any projectile
  count (say 1, 10, 100, 1000): a shape that still makes sense with many
  shots (fans that close into rings, volleys that queue, beams that thicken
  instead of multiplying), per-shot extras that scale by merging rather than
  by copying, and the existing live-shot cap (`Effects.pbullet_cap`) as the
  only limit. `tests/content_test.tscn` gets a check that gives each new
  weapon a huge count and measures it.
- **New themed environments with a variety of mobs, each with attack
  patterns of its own** (4.3, 4.4, 4.5).
- Then the monkey test (4.10), then **one IPA with everything** (4.11).
  No IPA in between unless he asks: 4.9's per-step IPAs are dropped. (He
  asked for one after 4.4b, before 4.5.)

Where he gave no number, the numbers below are a proposal. Tell him the
proposal in one line at the start of the step; he can change it.

What "unique" means here: an item differs from every other in what it does,
not only in its numbers. For a weapon that is at least one of: how it attacks
(shape, rhythm, range), what a hit sets off, a condition or resource of its
own, or what it scales with. Two swords that differ by 10% damage are one
sword. The same goes for a mob (how it moves and attacks) and a boss (its
attacks and phases).

New content must not change the original game: original items keep their
numbers, and `tests/replays/classic/` stay identical. Re-record the
full-content replays (`tools/replay.sh record`) at the end of each step that
adds content. Every new thing needs its sprite; draw it in the game's present
look (stage 5 redraws everything together later).

- [x] 4.1 **Take stock.** Write `UNIQUENESS.md`: every weapon, relic and gear
      piece with a short "signature" worked out from its data (kind, attack
      pattern, effects, conditions). List the groups whose signatures are the
      same or nearly so. No changes yet. Tell him the count and three
      examples. (Done: `tiny_biggot_godot/UNIQUENESS.md`, made by
      `tests/uniqueness_report.tscn`. About 114 new items need a mechanic of
      their own: 20 weapons, 45 relics, 49 gear; "numbers only" items count.)
- [x] 4.2 **Make the duplicates different.** For each group from 4.1 give all
      but one a mechanic of its own. Nothing is deleted, and original items
      are left alone (they are the classic game). Largest groups first; stop
      at about 40 items a session.
- [x] 4.3 **New environments.** Proposal: 3 new floors or rift worlds, each
      with its own tiles, a hazard of its own, and at least 4 room layouts
      that use it (that gives the 10+ rooms). `BIOMES.md` and `RIFTS.md` show
      how the present ones are built. One environment a session.
      (Done 5 Oct: SKYREACH ISLES, THE DROWNED BASTION, THE CALIBER
      CATHEDRAL, all rift worlds. See RIFTS.md.)
- [x] 4.3b **Event rooms, special rooms, NPCs, easter eggs** (his ask, 5 Oct).
      (Done 5 Oct: the saloon, 5 event rooms, 3 special rooms, wanderers.
      He approved the list. See RIFTS.md.)
      - A **saloon** event room: a whole bar with NPCs. A bartender sells
        booze (drinks are timed buffs, each with a catch of its own); a
        merchant NPC sells things; a quest giver hands out quests (a goal
        for this floor, such as "kill 3 elites without being hit", with a
        reward when it is done). Needs a small quest system: one quest at a
        time, shown on the HUD, checked by the rules, saved in the run.
      - Proposal: 5 more event rooms of that kind (rooms with people and
        something happening, not only a chest) and 3 special rooms. Tell
        him the list in one line first.
      - **Easter eggs** in those rooms (a hidden interaction, a joke, a
        secret reward). Original jokes only, no names from other games.
      - **NPCs scattered smartly**: rare wanderers in ordinary rooms that
        have a reason to be there (a lost merchant in a cleared room, a
        drunk from the saloon on the next floor, a quest giver's helper),
        never in a fight's way, never blocking a door.
      - Sprites for every NPC, the bar and its props; the content test
        visits every room and talks to every NPC.
- [x] 4.4 **New mobs.** Proposal: 5 for each new environment and 5 more spread
      over the old floors, 20 in all. Each moves or attacks in a way no
      present foe does. Each needs a sprite, a place in a floor's pool, and a
      line in the content test.
- [x] 4.4b **Floors as a map, and three things from his clips** (his ask, 5 Oct:
      "98% identical" in mechanics, layout and timing; the art, icons and
      names are this game's own, rule 3). Then **an IPA for him to test
      before 4.5** (his ask; the one exception to "no IPA in between").
      - **Floors are a branching map**, not a chain: dead ends with the shop,
        the rift, treasure, mystery and shrine rooms; the guardian at the
        farthest dead end; hidden rooms behind cracked walls (bomb them); a
        vault behind a locked door; a minimap. `--classic` and `--linear`
        keep the chain. (`scripts/world/floor_map.gd`, `tests/map_test`.)
      - **Level-up screen**: a burst of light, then a framed panel of trait
        rows that shine in one by one, keywords in colour with their
        explanations in small panels, a 4th choice with luck.
        (`scripts/render/trait_view.gd`.)
      - **Items on the floor**: sparkles fall, then a beam in the rarity's
        colour comes down and settles; the card colours its keywords and
        explains them beside it; a treasure room can hold three items on
        stone pedestals, take one and the rest sink away.
        (`scripts/render/item_show.gd`.)
      - **The constellation** (title menu): a web of 89 passive stars in
        four directions (offense, defense, agility, fortune), 21 of them
        named notables. Points from guardians beaten (1) and wins (2), up to
        30. Tap to read, tap again to take, hold to give back, drag and
        pinch. (`scripts/game/stars.gd`, `scripts/render/star_view.gd`,
        `tests/stars_test`.)
- [x] 4.5 **New bosses.** Proposal: a guardian and a mini-boss for each new
      environment. A guardian has at least three attacks, each with a warning
      the player can read (the lanes, rings and bands in
      `ATTACK_EFFECTS.md`), and a second phase. One a session.
      (Done 5 Oct, all three in one session at his "go": THE SQUALL HERON and
      THE STORMCROWN, THE DROWNED CAPTAIN and THE BILGE HYDRA, THE BELLRINGER
      and THE BRASS ORGAN. Mini-bosses end a new world's second room; the
      guardian is behind a second door in the champion's room, an optional
      fight. Every boss has a second phase. See RIFTS.md.)
- [x] 4.5b **Pets and companions** (his ask, 5 Oct: "also add companions and
      pets"). Ten pets, each with a trick of its own and three levels, found
      in cages (key, gold, or free from a rift guardian). See PETS.md.
- [x] 4.5c **REX THE FAT GOLDEN RETRIEVER** (his ask, 5 Oct: an easter-egg
      boss made from photos of his own dog, a second phase "with a sword in
      his mouth", a themed boss room, then an IPA). Rex sleeps in REX'S BARN
      (old stone and beams, green hay, his blue striped mat, a potato patch,
      his bowl). A hidden room may be his barn (12% a floor from the second,
      once a run); on the title screen a sleeping Rex in the corner can be
      woken (tap him, or SPECIAL, three times) and the next run's first room
      gets a door to the barn. Phase 1: belly flop, zoomies, potato dig,
      woof, nap. Phase 2: sunglasses on, a sword pulled from the hay: spin,
      leap slash, fetch (throws the sword and runs to bring it back), sword
      wave. Beaten, he rolls over and comes along as a pet. Art, sounds and
      moves are this game's own; the sword idea only nods at the picture he
      sent. See RIFTS.md. IPA built after it.
- [x] 4.6 **A hundred new weapons.** In batches of 20 to 25, each batch a
      theme (for example: thrown, summoning, charged, two-stage, cursed).
      **His ask, 5 Oct: four parts of 25, and an IPA at the end of each part**
      (so a session cut off by usage limits still leaves him a working build).
      Every weapon passes the "unique" test above against all weapons, old and
      new; put its signature in `UNIQUENESS.md`. Each needs an icon, and a
      shot or swing picture if no existing one fits. `tests/content_test.tscn`
      must pass and all shown text must fit the font.
      - [x] Part 1, MAYHEM (5 Oct): 25 explosives and mischief, nine new
        attack kinds (grenade, rocket, missile, sticky, mortar, walker,
        strike, dynamite, wave). See `ARSENAL.md`. IPA built after it.
      - [x] Part 2, CHARGE AND COMBO (5 Oct): 25 charged and two-stage
        weapons, ten new attack kinds (charge, slam, dash, javelin, hook,
        combo, heat, reload, orbit, recall). See `ARSENAL.md`. IPA built
        after it.
      - [x] Part 3, DECK AND DEN (5 Oct): 25 weapons of cards, turrets,
        summons and companions, seven new attack kinds (deck, turret,
        thrall, command, mirror, swarm, egg) and a taming whip. See
        `ARSENAL.md`. IPA built after it.
      - [x] Part 4, GUNPLAY AND ODDITIES (5 Oct): 25 strange guns and
        tricks, seventeen new attack kinds (letters, bubble, flak, paint,
        slots, roller, money, camera, ray, junk, bat, stab, duel, shrink,
        blower, dome, coin). See `ARSENAL.md`. IPA built after it.
- [x] 4.7 **New equipment and relics.** Proposal: 40 gear pieces over the 8
      slots, with at least 3 new sets, and 20 relics, aimed at the thin spots
      stock-taking showed. Same "unique" test.
      **His ask, 5 Oct ("go"), with three more things. Done in three parts,
      each ending in an IPA:**
      - [x] Part A (5 Oct): 40 gear pieces (four new sets: RIMEWARDEN,
        BLASTWRIGHT, BONECALLER, CLOCKWORK) and 20 relics, aimed at the thin
        slots, tags and moments; six new moments, seven conditions, eight
        actions. **A harder game**, expanded only: foes +10% health on floor
        1 rising to +40% on floor 11, one more foe a wave from floor 3, a few
        more elites, foes' shots 6% faster, and from floor 7 a foe's hit costs
        a whole heart. See `GEAR_AND_RELICS.md`. IPA built after it.
      - [x] Part B (6 Oct): **revamp the environments** ("make them less
        boring"). Each of the 11 floors: three props of its own instead of
        the square pillar, floor marks, a centre piece in some rooms, top-wall
        dressing, flickering lights, drifting air (dust, spores, embers, snow,
        rain...), and four new room layouts with the floor's own pits (water,
        lava, chasm, ice, void; expanded game only). **His ask, 6 Oct:
        "revamp original stages too"**: the look applies to the original
        game (`--classic`) as well; its rules and layouts are untouched and
        its replays identical. See `tiny_biggot_godot/ENVIRONMENTS.md`. IPA
        built after it.
      - [x] Part C (6 Oct): done, see `tiny_biggot_godot/HEAVEN_AND_HELL.md`.
        The soul gate after the Umbral Sun; THE GILDED EMPYREAN (THE AUREATE
        JUDGE) or THE SCORCHED DEEP (THE CINDER KING); then THE UNWRITTEN PAGE
        and THE UNWRITTEN, the last boss of all. IPA built after it. The ask:
        **Heaven and Hell** ("a story part, final two bosses
        based on your perks like in Tiny Rogues, that unlocks the final final
        final boss"): after the Umbral Sun, what your perks lean to (light or
        dark) opens Heaven or Hell, each with its own final boss; beating it
        opens the way to the last boss of all. Names and art are our own.
- [x] 4.7b **His ask, 6 Oct: "add moldy bread instead of sword" to Rex.** In
      his second phase Rex pulls a moldy bread loaf out of the hay; every move
      (spin, leap, fetch, wave) is the same, only the picture and his line
      changed.
- [x] 4.7c **His ask, 6 Oct: "you're going to Brazil".** A rare easter-egg mob
      (THE HAGGLER, lots of health; kill him for gold, a unique gun and his
      hat; if he catches you he sends you to BRAZIL), a dark grimy stage
      whose foes nag and rob you, and THE HOLY COW (two halves, then it rises
      again with new moves) that drops the COW MILKER. The robbers are scrap
      rats, not gypsies (no real people as the joke). See
      `tiny_biggot_godot/BRAZIL.md`.
- [x] 4.8 **Ten new characters.** (Done 6 Oct on his go, "do complete stage 4", in
      place of the one-line approvals; see `tiny_biggot_godot/HEROES.md`.) Send him one line per character first
      (name, weapon, the one thing that makes it play differently) and wait
      for his yes. No two may share a mechanic with each other or with the 14
      there are (`HEROES.md`, `GAOLBIRD.md`). Build two or three a session:
      sprite, weapon, passive, special, skill branch, unlock price, tests. The
      Gaolbird is the model for depth.
- [x] 4.9 After each of 4.3 to 4.8: `tools/check.sh` green, a new IPA, and
      three things for him to try in it.

- [x] 4.10 **Menus under random input** (was 3.4). Done 6 Oct: `--monkey`
      (`scripts/debug_monkey.gd`) and `tools/dev/monkey.sh`: an hour from the
      title (every screen visited) and ten 6-minute runs started in the new
      content, 0 errors; objects 3026 -> 3132 over the hour, nodes and
      resources flat. Add a debug option that presses
      random buttons in every menu and during play (the "monkey"), seeded, and
      run it for an hour of game time. Same pass condition. Run it over all the new content.

- [x] 4.11 (6 Oct) `tools/check.sh` green, the IPA (`[ipa]` commit), and a list for
      him of what is new and what to try. This also delivers stage 3.

- [x] 4.12 **His ask, 6 Oct (before stage 5): souls-like guardians.** Three stages per
      guardian with their own plans, stage breaks, new chaotic patterns (wall,
      flower, cross, barrage), stage-3 chaos, and a reward for felling one (slow
      motion, loot, half health back, FLAWLESS second chest). Expanded game only.
      See `tiny_biggot_godot/BOSS_STAGES.md`.
- [x] 4.13 **His ask, 6 Oct: the same for every boss and mini-boss, and each
      drops its own item.** Mini-bosses, rift minis and champions get three
      stages (breaks at 67% and 34%); rift guardians and Rex a third stage
      below 25%. 37 bosses and mini-bosses each drop a unique legend weapon
      or gear piece, found nowhere else. See `BOSS_STAGES.md`.
- [x] 4.14 **His ask, 6 Oct: the expanded game is the core.** Everything added
      is kept and guarded as part of the game (rule 4 of `CLAUDE.md`). It was
      already what he plays; classic rules stay behind the test switch only.
- [x] 4.15 **His ask, 6 Oct: every IPA named by its stage.** The file `VERSION`
      (the step a build ends) names the IPA `TinyBiggot-<version>.ipa`, its own
      kept release `ipa-<version>`, and the app's version in SideStore.
      `ipa-latest` stays the newest. First: 4.14.

## Stage 5: sprite revamp

He wants every sprite redrawn, "cool and pixelated". The influences are in
`CLAUDE.md`; they are for mood (bold shapes and outlines, readable
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

- [x] 5.1 **A sample, for his yes.** Drawn in three looks (A crisp, B grim, C
      glow); he picked **a mix of A and C** (6 Oct): A's clean, bright colours
      and readable outlines with C's richer colour, outlines tinted by each
      sprite's colour, and a soft glow on magic. In the game: the hexer, bat,
      skeleton, slime (and their elites), the Colossus, hearts, five weapon
      icons and the Ossuary tiles. Built as IPA 5.1. Tool: `tools/art/` (look
      "D"); the rest of stage 5 follows the same rules.
- [x] 5.2 Heroes (14, plus those from stage 4) and their gear overlay
      (`scripts/render/hero_gear.gd`). All 24 redrawn in the A+C look (6 Oct); the
      Gaolbird now wears its crow mask; worn gear gets an outline tinted by its colour.
      His picks (6 Oct, 5.2b): he kept 15 new designs and asked for 9 old designs
      remastered in the new look (bane hunter, wayfarer, condemned, cartomancer,
      sellsword, tinkerer, mirror knight, demolitionist, pilgrim).
- [ ] 5.3 Foes, champions and guardians. In chunks, each a picture for his picks (new or the old
      design remastered), then an IPA: 5.3a the first three floors, 5.3b Cinderforge and the floors
      after, 5.3c the rift worlds, 5.3d Heaven, Hell, Brazil and the special ones.
      **His ask (6 Oct): elites look a little different from the normal foe, plus the gold
      outline** (`ELITE` in `tools/art/sprites.py`: darker, richer body, gold eyes, an own mark).
  - [x] 5.3a (6 Oct): bat, bat2, slime, skeleton, mushroom, imp, ghost, bookwyrm, drowned (+ elites),
        Colossus, Spore Mother, Librarian. He took every new design.
  - [x] 5.3b (6 Oct): Cinderforge to the Umbral Sun: 26 foes and minis (+ elites) and 8 guardians.
        His picks: old designs remastered for gnat, longbowman, torch imp, crow, stone abbot,
        Pale Regent, Frozen Abbot (their elites keep the new drawing); wisp and bogling elites
        are the old design.
  - [x] 5.3c (6 Oct): six rift worlds (Gaol, Brand, Neon, Streets, Fog, Burb): 23 foes (+ elites)
        and 6 champions. His picks: drone and chrome keep the old design (elite new); turret, copper,
        robovac, burglar, gnome, turnkey, carrion knight keep the old design for both (recoloured,
        `REMASTER`/`REMASTER_ELITE`, originals in `tools/art/src/`).
  - [x] 5.3d (6 Oct): Heist, Dust, Skyreach, Bastion, Cathedral: 23 foes (+ elites), 5 champions,
        3 rift minis, 3 rift guardians (the organ is drawn by `_organ()`). His picks: sludge crawler,
        kingpin, marshal, gale warden, tide captain keep the old design for both (recoloured).
  - [x] 5.3e (6 Oct): the special ones: dummy, target, tomb spider, candlewight, gargoyle, war
        drummer, blood leech, casing rat, scrounger, goblin, mimic, shadow, the Haggler, the Holy Cow,
        the Judge, the Cinder King, the Unwritten. Rex (his dog) is only recoloured, pixel for
        pixel (`REMASTER`, originals in `tools/art/src/`). His picks: dummy and goblin keep the old
        design for both; the Holy Cow and the Cinder King keep theirs (recoloured).
  Stage 5.3 done: every foe, elite, champion, mini and guardian is in the look.
  **His ask (6 Oct): no tests and no IPA between the art steps.** Redraw everything first (5.3 to
  5.6), committing as it goes; then one full check and one IPA at the end of stage 5.
- [x] 5.4 Weapon, gear and relic icons. (6 Oct) All 518 weapon, gear, relic and pet icons kept as
      drawn and recoloured into the look with its volume (`remaster(shade=True)`: light on the
      top-left edges, shadow on the bottom-right, outlines tinted by their colour). Originals in
      `tools/art/src/icons/`. He kept them all as they are (6 Oct).
- [x] 5.5 Tiles and room objects, floor by floor. (6 Oct) Every tile sheet but kit0 (drawn new)
      kept as drawn, recoloured, each floor tile bevelled like kit0 (`kit_remaster`); 128 room
      objects, shop people, summons, the hydra's extra heads and Rex's barn props recoloured with
      volume like the icons. Originals in `tools/art/src/kits/` and `src/rooms/`.
- [x] 5.6 Menus, HUD and the pixel font (the font last and only if he asks:
      every string in the game is measured against it). (6 Oct) HUD hearts, pickups, map,
      family and combo icons, rarity frames and cards recoloured with volume (`src/hud/`). The
      logos and the font are left as they are. Effects (fx, shots, glows) left: drawn in October.
      **His ask (6 Oct): the ten town and shop people remodelled before the IPA** (new grids
      `npc_*` in `sprites.py`).
  Stage 5 closed (6 Oct): full check passed (all replays identical), IPA 5.6 built.

## Stage 5.7: small extras (his ask, 6 Oct)

- [x] A human robber for Brazil: THE RAIDER, a wasteland scavenger (goggles, rust scarf, shoulder
      spikes, a pipe). Faster and tougher than a scrounger, robs twice as much; added to Brazil's
      foes (nothing taken out). No real people: the robbers are scavengers and rats.
- [x] OPTIONS > MEET THE HAGGLER: when on, the Haggler is in the first fight of every run, so he can
      try Brazil on the iPad.
- Noted for the next additions: saving a run in progress (there is no such option yet).

## Stage 5.8: harder (his ask, 6 Oct)

"Stages are still too easy, boss fights end fast, crank it up, rooms longer and more varied; broken
builds end fights instantly: fix it without nerfing the builds; each loop harder; I can't even feel
the 3 boss stages." Nothing about any build was touched.

- [x] Bosses never skip a stage: a blow of any size stops at the next stage's line (`Stages.gate`),
      for floor guardians, rift guardians, Rex and every mini-boss and champion.
- [x] Guardians and rift guardians: 60% more health (`Combat.boss_hp`).
- [x] Foes: 35% more health on the first floor, 6% more each floor (`hard_hp`).
- [x] The run grows with you: +2% foe health per relic carried, +1% per minute (`run_scale`).
- [x] Loops: +150% health per loop (was 80%), foes' shots +12% per loop, many more elites.
- [x] Longer fights: one wave more in every fight, one more foe a wave, more elites; one room in
      three has a twist: SWARM, HUNTERS, STRANGERS (foes from the next floor), AMBUSH (one more wave).
- [x] Hidden rooms that felt empty: the embers-and-gems one gets a free iron chest, the loot-goblin
      one keeps a pile of his coins.
- [x] **His ask (6 Oct): every guardian evolves with its stages**, more menacing each time: stage 2
      (spikes, cracks of light, angrier colours, hotter eyes) and stage 3 (bigger spikes, a dark
      corrupted body with glowing veins, white-hot eyes, an aura), in each guardian's own colour.
      18 guardians (`EVOLVE` in `tools/art/render.py`, `<sprite>_s2/_s3`, `Stages.look`). Rex, his
      dog, keeps his look. He confirmed nothing about any build changed in 5.8.
  IPA 5.8 built (6 Oct).

## Stage 5.9: evolved forms (his ask, 6 Oct)

- [x] "Different evolved sprites per stage, to feel the evolution": each guardian's stage 2 and 3
      now change shape, not only colour: hand-drawn parts (horns, bat and feather wings, a third
      eye, eye clusters, a fanged maw, a crown of flames, shoulder spikes, tentacles, a broken halo),
      a different mix per guardian and stage (`PART` and `FORMS` in `tools/art/render.py`), then
      burned by `evolve()`. Nothing hangs below a guardian's feet.

After each of 5.2 to 5.6: `tools/bake_atlas.sh`, `tools/check.sh`, a
before-and-after picture for him, a new IPA.


## Stage 6: additions (his ask, 6 Oct)

He said yes to all four; he will say when he has played 5.9 enough to judge the difficulty.

- [x] 6.1 Mini-bosses, rift minis and champions evolve with their stages, as the guardians do
      (stage-2 and stage-3 forms). 20 of them and their elites: four kinds of form (brute, wing,
      maw, fire), each in its own colour (`MINIS` in `tools/art/render.py`).
- [x] 6.2 Rex evolves too, **cute, not scary** (his word): party Rex (party hat, red bandana,
      sparkles) and super Rex (golden crown, red hero cape, hearts, a soft golden glow), sitting
      and lying (`cute()`). 6.1 and 6.2 built together as IPA 6.2.
- [x] 6.3 Save and continue a run: CONTINUE on the title. The run is saved at the start of every
      floor (`scripts/game/run_save.gd`: every value the hero holds, the floor, loop, dread and run
      numbers; written whole or not at all with a backup), and gone when the run ends. Continuing
      puts him on a fresh floor of the same depth. Test: `save_test` (220 values back exactly).
  **His ask (6 Oct): make all of stage 6, then build one IPA.**
- [ ] 6.4 New content: a new world, heroes, weapons and a boss (to agree with him). IPA.

---

## Log

- 5 Oct 2026: 1.1 done. First IPA built on GitHub (28 MB, arm64, release
  engine, not signed). Its game files run in a desktop player.
- 5 Oct 2026: 1.2 done. He installed it with SideStore: it installs and
  works. He widened stage 4 (environments, mobs, bosses, equipment), wants a
  working IPA at the end of every stage, and will steer during the work.
  Work now goes on the branch `claude/dev`.
- 5 Oct 2026: 2.1 started. Asked him for the SHOW FPS line from the four
  moments (title, ordinary fight, busiest fight, a guardian full of shots) and
  when anything stutters. Waiting on his numbers. Offered to do stage 3
  (stability, needs no iPad numbers) in the meantime if he prefers.
- 5 Oct 2026: 2.1 done, stage 2 closed. He says it runs a good 60 fps "for
  now". Nothing to patch; no new IPA needed. Next: 3.1 (the save file).
- 5 Oct 2026: 3.1 done. The save is written whole or not at all, with a
  checksum, and the one before is kept as a backup. Damaged saves load the
  backup, or start fresh, without an engine error. Old saves still load.
  New test `tests/save_test.tscn` in `tools/check.sh`. No IPA yet (3.6).
- 5 Oct 2026: 3.2 done. A lost synergy or combo is taken back through
  `Effects.apply_equipment` (the gear limits): hit points no higher than the
  new maximum, roll charges between 0 and the rolls there are. Test in
  `tests/unit_tests.gd` (failed before the fix, passes after).
- 5 Oct 2026: 3.3 done. `tools/dev/soak.sh`: 29 runs of 10 minutes (every
  hero, floors 0-10, 8 rift worlds, classic, both options off, loops 1-3,
  weapon cycling in 15) without one error or warning line. Object count:
  flat within a run once the build stops growing, and back to the same level
  at every new run (409 runs in 4 hours: +23 objects over the last 200, all
  in caches with a limit). New debug option `--objects`. Nothing to fix.
- 5 Oct 2026: he moved the monkey test (3.4) to after the new content
  (now 4.10), and asked for weapons, gear, relics and abilities with ideas
  from Enter the Gungeon, Slay the Spire, Worms Armageddon, Risk of Rain,
  Cabal, Aion, GTA V, Saints Row 3 and Dead Cells, cool pixel effects,
  every one mechanically unique, and safe at any projectile count (written
  into stage 4). Next: 3.5, then 3.6 (the IPA that closes stage 3).
- 5 Oct 2026: 3.5 done. Nothing in the rules uses the clock (fixed 1/60 s
  steps, at most one per frame: no catch-up after a pause). New: going to the
  background mid-fight opens the pause menu and saves progress. A run in
  progress is still not saved: if iOS closes the app, that run is gone
  (embers already earned are kept). Saving a run is a bigger job; asked him.
- 5 Oct 2026: he wants all of stage 4 first (weapons, gear, relics,
  abilities, themed environments, mobs with their own attack patterns), then
  the monkey test, then one IPA (4.11). Stage 3's IPA waits for that. Run
  saving (see HANDOFF) not answered yet.
- 5 Oct 2026: 4.1 done. `UNIQUENESS.md` lists 252 weapons, 173 relics and
  231 gear pieces with a signature each. New items that are near-copies of
  another or change only numbers: 20 weapons, 45 relics, 49 gear (114).
  Originals are listed but left alone. Next: 4.2.
- 5 Oct 2026: 4.2 part 1. 14 weapons and 24 relics each keep what they
  did and gain one triggered effect of their own. No new relic is a
  near-copy now. Content test passes; classic replays identical; full
  replays a and b re-recorded (their heroes carry changed relics).
- 5 Oct 2026: 4.2 done (part 2: 49 gear, 19 relics). Every new item now
  has a mechanic of its own; content test passes, classic replays
  identical, full replays d, g, h re-recorded. Next: 4.3 (environments).
- 5 Oct 2026: he asked for event rooms with NPCs (a saloon with a
  bartender selling booze, a merchant, a quest giver), special rooms,
  easter eggs and smartly scattered NPCs: new step 4.3b, after the first
  environment. 4.3 started: a new rift world, SKYREACH ISLES.
- 5 Oct 2026: 4.3, first environment: SKYREACH ISLES (rift world): open
  sky tiles, 4 island layouts, gusts, the Gale Warden. Rift test extended
  (layouts reachable, sky rules, gusts); classic replays identical; 7 full
  replays re-recorded (a 9th world changes which rift a run is offered).
  Next: 4.3b (saloon and event rooms) or the second environment.
- 5 Oct 2026: 4.3b part 1: the saloon (bartender and 5 drinks, merchant,
  bounty broker with 3 floor quests on the HUD, piano / poster / drunk
  easter eggs). Rift test section 8; content test's specials check now
  clears the arena floor (one unreproduced dash failure, likely a pillar).
- 5 Oct 2026: 4.3b done. Event rooms: fighting pit, chop shop, fortune
  teller, courier, shooting gallery. Special rooms: signal beacon, plate
  vault, cursed armory. Wanderers: the saloon drunk on later floors, a lost
  merchant. Rift test section 9 plays each to its payout. Next: 4.3,
  environments 2 and 3.
- 5 Oct 2026: 4.3 done. Environments 2 and 3 at his request in the moods of
  Dead Cells and Enter the Gungeon: THE DROWNED BASTION (toxic tide,
  levers, a joking skull, a fisher) and THE CALIBER CATHEDRAL (flippable
  tables as cover, wall turrets, a bullet saint, a thieving rat). Rift
  test section 10. Next: 4.4 (new mobs, 5 per new world and 5 more).
- 5 Oct 2026: 4.4 done. 20 new foes (5 per new world, 5 on the original
  floors in the expanded game only), each with its own trick, all warned.
  New tests/foes_test.tscn; a belt-feeder memory leak found by it and
  fixed. 11 soaks clean; classic replays identical; full re-recorded.
  Next: 4.5 (a guardian and a mini-boss for each new environment).
