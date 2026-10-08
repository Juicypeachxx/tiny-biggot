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
- [x] 5.3 Foes, champions and guardians. In chunks, each a picture for his picks (new or the old
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
- [x] 6.4 New content: THE CLOCKWORK SPIRE, a rift world of brass and steam (steam vents; foes
      cogling, steamjack, boltslinger, gearhound, rivet lobber, brass wasp; champion THE FOREMAN;
      guardian THE GREAT ENGINE, on the guardians' rules: three stages, evolving forms, own drop
      ENGINE CORE; the Foreman drops his HARD HAT). A new hero, THE CLOCKMAKER (every 12th shot slows
      the foes' shots; REWIND; the CLOCKWORK branch). Eight clockwork weapons: gearwound repeater
      (his), the pendulum, spring lance, cog thrower, steam cannon, chrono blade, ticking flask,
      escapement rifle. Stage 6 built as one IPA, 6.4 (his ask).
  Stage 6 closed (6 Oct): full check passed, IPA 6.4 built.

## Step 6.5: foes answer the build (his ask, 6 Oct, with a video)

"The game still instantly clears everything and melts the bosses after a few pickups." (Floor 3,
level 19, THE HIGH CALIBER +11, hits of about 230.) Builds stay exactly as they are (rule 1).
- [x] Foes, mini-bosses and guardians spawned from now on read your real strength: the weapon
      sheet (damage, rate, shots, crits) or what you really dealt in fights lately (combos, wisps,
      meteors), whichever is more. When it runs ahead of what the floor expects, their health
      grows with the lead to the power 0.6 (`Combat.power_scale`). Expanded game only.
      The yardstick is what a plain build (no combo) has on each floor, measured in bot runs.
- [x] His words after the first measurements: "I want the core build mechanic to still feel the
      same, to explore different build paths and make broken builds, and I want enemies to
      withstand those builds and scaling, not just instantly die, and bosses with a bigger health
      pool and armor, to make fights last longer and feel rewarding, not boring."
- [x] Boss armor (`scripts/combat/armor.gd`): guardians, rift guardians, minis and rift champions
      start every stage behind a plate (35% / 25% of their health, a pale bar over the health
      bar). While it holds only a quarter of a blow reaches the health; breaking it: ARMOR
      BROKEN, the foe reels and takes +25% for 3 s. Guardians' health ×2.0 (was ×1.6).
- [x] Measured with bot runs (plain, Hall of Mirrors, High Caliber) against 6.4; full replays
      re-recorded; classic identical; IPA 6.5.

  Step 6.5 closed (6 Oct): full check passed, IPA 6.5 built. Waiting for his word on how it feels.

## Step 6.6: elite traits (6 Oct, his word: "do what is best for now, go")

Chosen for his asks of 6 Oct (more variety, foes that stand up to a build), no build touched.
- [x] Every elite rolls a trait, two from the seventh floor or on a loop, its name in gold under
      it: SWIFT (35% faster), PLATED (a plate of half its health, armor.gd; breaking it stuns),
      SPLITTING (two copies of a third of its health), VOLATILE (a slow ring of shots when it
      dies), MENDING (heals 5% a second when left alone 2 s). `scripts/combat/elite_traits.gd`,
      `tests/traits_test.tscn` (in check.sh). Expanded game only.
- [x] Full replays re-recorded, classic identical, full check passed, IPA 6.6.


## Stage 7 (his word, 6 Oct: "All", to the three ideas after 6.6; one IPA at the end)

- [x] 7.1 Boss weaknesses: each guardian, mini-boss and champion has one (FIRE, POISON, STORM,
      CRITS or BLASTS), shown on its bar. Hits of that kind wear its armor plate 2.5 times as
      fast. Other hits are exactly as before: no build loses anything.
- [x] 7.2 Trophies: the first time a hero fells a guardian it is a trophy (+embers, a banner). The
      hero screen shows the count; 5 / 10 / 15 trophies (of 19) give that hero a starting potion / a
      relic / a rare relic.
- [x] 7.3 A new rift world, in the way of the Clockwork Spire: THE RIMEFROST HOLLOWS (ice
      caverns, icicle spikes): frostmite, rime brute, shardcaster, frostfang, snow lobber, glimmer
      wisp (+ elites); THE HOARFROST KNIGHT (champion, drops the HOARFROST HELM: +2 armor, being
      hit chills every foe near you) and THE GLACIAL MAW (rift guardian on the guardians' rules,
      three stages and evolving looks, drops GLACIER HEART: chilling bolts, every 4th calls
      lightning). Original art in tools/art.
- [x] Full check passed, replays re-recorded on purpose (new world in the pools), classic identical, IPA 7.3.


## Stage 8: alignments, clear info, stat stacking (his ask, 6 Oct, with five pictures of another game's
perk tree and HUD: ideas only, every name, number and icon here is this game's own)

"Add those alignments in constellations and similar, also the last picture shows you how to make
info of perks and stats and all info of the game, keep it this way so it could be easier to
understand the build, also add stat stacking as shown to buff weapons and builds."

- [x] 8.1 Alignments: GOOD, EVIL, LAWFUL, CHAOTIC. Points come from the four little shrines in
      every rest stop (take one), the realms (Heaven +2 GOOD, Hell +2 EVIL) and the constellation. The constellation grows four diagonal
      spokes, one per alignment, with stars that give points and stars whose perks depend on them
      (e.g. "while one alignment is 2 or more and the other three 1 or less: ..."; "while GOOD is
      your highest: ...").
- [x] 8.2 Clear info: every description (items, stars, traits, shop, stats) colours its keywords
      (damage, crit, armor, gold, STR/DEX/INT, alignments, numbers) with a small icon, in boxes like
      his pictures. A stat column on the left of the HUD: gold, keys, bombs, STR / DEX / INT,
      luck, the four alignments (an option can hide it).
- [x] 8.3 Stat stacking: fights (25%), elites (15%), chests (35%) and guardians (2) give stat pickups with a label over them (+1 STR,
      +1 DEX, +1 INT, +1% crit, +0.5% move speed ...), and the attributes do more than weapon
      damage (STR: +1 max heart per 5; DEX: +1% crit each; INT: +2% burn, poison and lightning
      damage each).
- [x] 8.4 Fun traits and synergy traits (his ask, 6 Oct, with pictures of a trait pick: ideas
      only). Big, odd, run-shaping picks on the level-up screen: "super" versions of a family
      (a big pile of one attribute, counted as extra ranks of that family), rule-benders (lazy:
      damage per empty gear slot; rich: count as holding lots of gold; elemental: every few
      seconds burn / chill / shock / poison every foe), and synergy traits that grow with what you
      already do (per skill use, per roll, per alignment...). The pick screen shows the odds of
      each family and explains each keyword in a side box.
      Done: 9 SUPER traits (new pink rarity, from level 4: TITAN'S FRAME, QUICKSILVER, GENIUS,
      ALL FAITHS, FOUR-LEAF CROWN, BOTTOMLESS HEART, ELEMENTAL STORM, OVERCHARGED, TAILWIND), 2
      rule-benders (IDLE HANDS, BOTTOMLESS PURSE), 5 synergy traits (MOMENTUM, VETERAN, COLLECTOR,
      ZEALOT, PRISM). The keyword side box was already there and now covers the new words; the
      odds box (his "ok do that", 6 Oct) sits left of the panel: STR / DEX / INT / ANY shares of
      the next roll, the SUPER chance and luck's 4th row (TraitView.odds).
- [x] Full check passed, replays re-recorded on purpose, classic identical, IPA 8.4.

## Step 8.5: the trait pick revamped, more SUPER traits (his ask, 6 Oct)

"Revamp traits as [his pictures], also add more super traits and make some common super traits to
refresh runs."
- [x] The pick screen in the way of his pictures: wide rows, a big icon box in the family's
      colour, the name, each effect on its own bullet line; on the right a column with the odds
      box and the keyword boxes under it.
- [x] More SUPER traits, and a set of COMMON SUPER traits: smaller, offered often from level 2,
      so most runs meet a few. 12 new (TWIN SOUL, LIGHTNING REFLEXES, STAT SURGE, HOARDER, LEGION,
      GLASS CANNON, ASSASSIN, BLOOD MOON, WINTER'S HEART, INFERNO, PLAGUE LORD, JUGGERNAUT): 21 in
      all; 8 are common (Traits.COMMON_SUPER: weight 4 from level 2), the rest rare from level 4.
- [x] Full check passed, replays re-recorded on purpose, classic identical, IPA 8.5.

## Stage 9: chaos bosses (his ask, 6 Oct, with three pictures of another game: a final boss fight
## full of lasers and shots, a tier list of its bosses, a demon throwing chains inside a red circle.
## Ideas only: every boss, name and sprite here is this game's own design, nothing traced.)

"First picture shows final boss combat and chaos please make me similar, also second picture is a
roster of bosses look at them and add similar, also 3 picture shows you boss abilities it looks
fun and hard and chaotic, make me this."

- [x] 9.1 Chaos attacks for bosses, each shown before it hits: laser beams that sweep round the boss
      (a thin warning line, then the beam), laser crosses and fans, chain hooks flung from the
      boss across the room that then swing, and big danger circles (a red ring that fills, then
      blasts). Kept within the 60 fps budget.
- [x] 9.2 The final fights become chaos: the last guardians and the Unwritten use them, the very
      last phase stacking beams, hooks and shot storms at once. Done for the Ash Warlord, the
      Frozen Abbot, the Crow King, the Umbral Sun, the Judge, the Cinder King and the Unwritten
      (all expanded-game only); in stage 3 a chaos move no longer waits for its lasers to end.
- [x] 9.3 New bosses in the spirit of his roster (original designs): a radiant seraph, a dragon,
      a chain demon (picture 3), a walrus admiral, a phoenix that rises again, a golem king, an
      archmage. Each floor's guardian can now be one of several, so runs differ.
      Done: THE WALRUS ADMIRAL (floor 2), THE GOLEM KING (4), THE ARCHMAGE (6), THE PHOENIX (7,
      rises once from its ashes), THE WHITE WYRM (9), THE CHAIN FIEND (10), THE SERAPH (11), each
      met half the time instead of the floor's guardian; three looks each, stages, a drop of its
      own (bicorne, mantle, staff, plume, wyrmfang, chains, lance). First-draft art: he may want
      a picking round on it.
- [x] Full check passed, replays re-recorded on purpose, classic identical, IPA 9.3.

## Stage 10: from his trailer clips (his ask, 6 Oct: four screen recordings of another game's
## update trailer, "learn the mechanics, core gameplay, visuals and vibe, and add". Ideas only:
## every name, number and sprite here is this game's own.)

Already here: trait pick with keyword boxes, coloured info and stat column, companions (pets), a
meta web (the constellation), telegraphed attacks, an anvil, event rooms.
- [x] 10.1 Live descriptions: texts that grow with the run show their current value
      ("+20% DAMAGE FOR EACH EMPTY GEAR SLOT (+60% NOW)").
- [x] 10.2 New events: a frog to kiss or leave; a ritual circle where you draw a symbol for a
      blessing; a pawn shop that buys your gear; a cup-and-ball game; a lightning round of quick
      fights before a rest.
- [x] 10.3 New heroes: a minstrel who plays songs (picked buffs), a jester (random tricks), a
      berserker, and a hero who starts with nothing (hard mode).
- [x] 10.4 Flails: weapons on a chain that swing round you. Six: MORNING STAR, TWIN CHAIN,
      RIMEBALL, EMBER MACE, THUNDERBALL, THE GRAVE BELL.
- [x] 10.5 An optional NEON look (Options > NEON LOOK, off by default): black floors, thin bright walls, a colour per floor.
- [x] Full check passed, replays re-recorded on purpose, classic identical, IPA 10.5.

## His plan from here (6 Oct, his words: "after you finish go stage 10 and then check videos for
## anything new then continue to analyze the game to add new things, after analysis continue to add
## fresh new fun and cool stuff, also you can make the game a little bit harder, then after all we
## will make some story, add new npc and final bosses and hidden final bosses that fit into the story
## and game progress with new stages and environments, like a new dlc ... go step by step per stage
## ipa"). One IPA at the end of every stage.

## Stage 11: a second look, and fresh fun
- [x] 11.1 Go through his clips again for anything not taken yet; look over our own game for
      gaps (thin floors, items nobody picks, dull rooms) and write what is found here.
      Found (6 Oct): enemies' big hits marked by a red "!" circle on the floor before they land;
      aura rings round the hero (yellow circles that burn or slow what is inside); a stacking dark
      ailment (each stack, more damage taken); fans of several lasers from one weapon; eight charm
      slots (ours: relics do this already); equip load, attunement and mana costs (left out: they
      add bookkeeping, not fun). Our side: the floors' own foes rarely warn before a big hit, and
      relic choice is wide but has few "aura" or "ailment" builds.
- [x] 11.2 Fresh, fun, cool additions from that list (new weapons with new kinds, rooms, relics,
      events), in the game's own style: "!" warnings before foes' big hits; aura relics and gear
      (rings round you that burn, chill, poison or pull); the GLOOM ailment and items that use it;
      prism weapons (fans of lasers). Done: "!" warnings; six aura relics; GLOOM with DUSKBLADE,
      GLOOM LANTERN and NIGHTFALL; a beam's extra projectiles now fan out as rays (PRISM FAN,
      THE SPECTRUM).
- [x] 11.3 A little harder, measured with bot runs (nothing removed or toned down, rule 1).
      Foes +45% health on the first floor (was +35%), their shots 10% faster (was 6%), 4% more
      elites. Bot (no god mode, 10 min, seeds 3 and 7): deaths 9 and 11 before, 10 and 11 after;
      it reached level 2-3 instead of 4 (foes take longer to fall).
- [x] Full check passed, replays re-recorded on purpose, classic identical, IPA 11.3.

## Stage 12: the story (a DLC of our own)
- [x] 12.1 A story that ties the floors, the realms and the Unwritten together; told by new NPCs
      met along the run (and in a hub between runs if it fits), a little at a time.
      Done: STORY.md (the world is a book still being written by THE AUTHOR); THE ARCHIVIST at rest
      stops tells it line by line as far as the player has ever reached (saved); milestones at the
      Regent, the Umbral Sun, a realm, the Unwritten. The chapter's NPCs come with 12.2.
- [x] 12.2 New stages and environments after the current end, in a new chapter.
      Done: after the Unwritten falls, END THE STORY or TURN THE PAGE. CHAPTER II, THE MARGINS: three
      new floors (THE INKWELL, THE BINDERY, THE QUILL SPIRE), 15 new foes, 3 mini-bosses, 3 guardians
      (the Ink Leviathan, the Binder, THE AUTHOR, with chaos attacks), new floor tiles. The Author's
      fall wins the run (+300 embers). New people: THE INKLING (wanders into cleared chapter fights,
      opens a hidden wall) and THE BOOKBINDER (chapter rest stops, sells a relic).
- [x] 12.3 New final bosses for the chapter, and hidden final bosses reached only by secret
      routes or conditions that the story hints at.
      Done: THE AUTHOR ends Chapter II (12.2). Hidden: a TORN PAGE in a hidden room of each chapter
      floor (the Archivist and the Inkling hint at them); all three carried, the Author's fall
      opens a door to THE REDACTED and THE REDACTOR (3800 health, chaos in three stages). +500 embers.
- [x] 12.4 Endings and unlocks that follow the story; IPA per part as it grows.
      Done: end screens "THE STORY IS YOURS" (the Author) and "NOTHING IS ERASED" (the Redactor);
      each chapter guardian leaves its own legend item: THE INKSPOUT, THE BINDER'S THREAD, THE
      AUTHOR'S PEN, THE BLACK BAR (the Redactor's). Embers: CHAPTER II +300, THE REDACTOR +500.
- [x] Full check passed except replays b and d, which changed only because the Archivist (12.1)
      now sits at rest stops: re-recorded on purpose. Classic identical. IPA 12.4.

## Stage 13: his asks after Stage 12
- [x] 13.1 Keyboard mapping in Options (his ask, 7 Oct). Options > KEYBOARD KEYS lists all 18
      actions with their keys; pick one, press a key. A key taken from another action leaves it.
      Esc always pauses and Enter always confirms (so nobody locks themselves out). RESET ALL
      KEYS. Saved with the options. Pads and touch are unchanged. IPA 13.1.
- [x] 13.2 Armor sets that matter (his ask, 7 Oct: "much more rewarding when you complete a set,
      and something to plan, not just random pieces"). A 3-piece step (+1 armor, +8% damage); the
      4th piece adds SET MASTERY (+1 max heart, +12% damage) and an aura in the set's colour; the
      first time in a run: slow motion, flash, banner, full health and a relic. Once a set is
      started its missing pieces drop far more often (35-55% of gear drops), shops offer one, and
      loot that continues a set says "SET 2/4 > 3/4". `--set=ID` test option.
- [x] 13.3 Creative new traits (his ask, 7 Oct). One IPA for 13.2 and 13.3.
      Done: 16 new traits. BANK SHOT, SCORCHED TRAIL, FALLING STAR, STATIC CLING, NIGHT FEAST,
      GOLDEN TOUCH, EVIL EYE, EVENT HORIZON, SPILLOVER, LAST WORD, LOADED DICE, THUNDER STEP, CHAIN
      REACTION, WARDROBE (+6% damage per set piece worn); SUPER: MASTER TAILOR (set pieces come far
      more often, +8% per piece), HALO OF BLADES. Core replays re-recorded on purpose (set pieces
      now drop more often once a set is started). IPA 13.3.

## Stage 14: sets, combos, Chapter III (his word, 7 Oct: "go 2,3,4,5")
- [x] 14.1 New sets for styles that have few or none (pets, turrets, rolling, gold, curses...)
      and LEGENDARY sets of 6 pieces with a 6-piece power.
      Done: STORMCALLER, BLOODLETTER, HEXWEAVER, VIPER, WARLORD, BEASTMASTER, DRIFTER (4 pieces);
      LEGENDARY SUNFORGED and VOID REGALIA (6 pieces: steps at 2, 4, 6; the sixth brings their
      power and SET MASTERY). 40 pieces, icons recoloured per set (tools/art/set_icons.py).
- [x] 14.2 A WARDROBE page: every set, the pieces found, what each step gives. IPA.
      Done: WARDROBE on the title menu and in the pause menu. All 32 sets (LEGENDARY ones marked *),
      pieces found and worn, each step (green when worn), mastery. `--ui=wardrobe`. IPA 14.2.
- [x] 14.3 Trait combos: two particular traits together unlock a hidden third power. IPA.
      Done: 12 HIDDEN combos (INFERNAL KEG, STORMFRONT, SINGULARITY, CURSED HALO, FOUNTAIN, FINAL
      ACT, TAILOR-MADE, STARSTORM, SLIPSTREAM, KING'S RANSOM, BLACK PLAGUE, LUCKY STRIKE). Nobody
      is told; the first find is a big moment and is kept, then trait cards say "COMBO WITH X" or
      "COMBO READY". The traits page counts them. IPA 14.3.
- [x] 14.4 Chapter III: after the Redactor, a third chapter with its own floors, foes,
      guardians and an ending. IPA.
      Done: after the Redactor, CLOSE THE BOOK or READ ON. CHAPTER III, THE APPENDIX: THE GLOSSARY,
      THE FOOTNOTES, THE COVER; 15 foes, 3 minis (Lexicant, Fine Print, Colophon), 3 guardians
      (THE LEXICON, THE ERRATUM, THE READER), new tiles. The Reader's fall: "THE END", +600 embers.
      Four new Archivist lines. The Bookbinder and the Inkling come along. `--chapter=3`. IPA 14.4.

## Stage 15: his asks after Stage 14
- [x] 15.1 Fishing (his ask, 7 Oct: "can you add fishing"). PONDS in 45% of rest stops and 25% of
      treasure rooms, 3 casts each. Cast, wait, strike on the "!", then reel: hold USE to lift the
      green box onto the darting fish until the catch bar fills (a finger anywhere on the iPad).
      16 fish: everyday ones, one per part of the world, junk, rare (Golden Carp, Armored Bass,
      Sunken Chest) and legendary (Moonlit Koi, The Old One: a relic). Each pays at once. Fish found
      are kept between runs. `--ui=fishing --fish-auto`. (15.1 was not built: he wanted more first.)
- [x] 15.2 Fishing made a place (his ask, 7 Oct: "make it better, not blank and soulless"). Ponds
      live: an uneven shore with mud, stones and grass, deeper water in the middle, light on the
      water, lily pads with flowers, reeds and cattails, fish shadows swimming (one comes to your
      float on a bite), rain rings, fireflies, a sign. You cannot walk on water. THE FISHING HOLE (a
      mystery room): a lake across the room, a wooden dock to fish from, lantern posts, THE ANGLER
      and his camp (crates, rods, a bucket with something flapping in it): GLOW-WORM BAIT (+2 casts,
      rare fish bite far more) and a relic for 3 fish. Every fish has its own sprite; the catch leaps
      out of the water with a splash and floats over you with its name; the reel panel is a wooden
      frame with a water column, bubbles, a net and the real fish (a dark shape until first caught).
      IPA 15.2.
- [x] 16 ROOMS REVAMP (his word, 7 Oct: "go and revamp all, add new things, make them full and
      enjoyable"). Done (scripts/render/room_dress.gd): THE HOARD (gold-trimmed rug, coin heaps,
      open chests, banners, braziers, glints), THE STALL (striped awning, bottle shelves, sign,
      sacks, crates, lanterns, rug), the SHRINE (rune circle, ring of candles, carpet, statues,
      petals, incense), the VAULT (iron floor, velvet ropes on brass posts, gold bars, strongboxes,
      chains), HIDDEN ROOMS (cobwebs, dust, bones, candles, glowing mushrooms), THE CAMP at rest
      stops (log seats, tent, bedroll, pot on a tripod, firewood, lantern), the GUARDIAN'S ARENA
      (a sigil in the floor's colour, cracks, braziers, banners), the START (a runner, braziers),
      MYSTERY rooms (lanterns, barrels), ink and pages on Chapter II/III floors. Warm light from
      every flame; rats, moths and butterflies that run from you. New to play with: POTS along the
      walls (shoot or roll into them: coins, gems, hearts), COIN HEAPS in the hoard (walk through),
      POWDER KEGS in some fights (shoot one: it blows up the foes round it and the keg beside it).
      Still parts drawn once per room (no cost per frame). IPA 16.

## Stage 17 (his word, 7 Oct: "2, 4, 5")
- [x] 17.1 Speed check of the heaviest moments (a furnished room full of foes, lights and kegs;
      Chapter III guardians; several sets with auras; fishing), and cut what costs too much.
      Done (PERFORMANCE.md, 17.1): ponds' still parts drawn once, pots/kegs/heaps redrawn only
      when one breaks, chaos chains batch. Rest stop draw 2.90 -> 1.81 ms; the Reader 277 -> 148
      draw calls, the Redactor 217 -> 88. Fights unchanged from 15.2.
- [x] 17.2 THE CAMP: a hub between runs. The Archivist, the Angler and his pond, the Bookbinder,
      the Wardrobe as a real wardrobe; what you have earned shows as furniture. IPA.
      Done: THE CAMP on the title menu, a clearing walked with your hero (no run counted or
      saved). The portal (start a run), the Archivist, the Angler's pond (every world's fish), the
      wardrobe (WARDROBE page) with an armour stand per set ever completed, the ember shrine, a
      telescope (constellation), a practice dummy (skill trees), a notice board (runs, wins, deepest
      floor, embers), a tent, trees, flowers, the fire. Earned furniture: a trophy cup per guardian
      felled, a banner per ending reached, the fish wall. MENU > LEAVE CAMP. (One IPA with 17.3.)
- [x] 17.3 Livelier fights: weather on each floor, foes that react to kegs and pots, cover that
      breaks. IPA.
      Done: a hit keg now burns a short fuse (it flashes, sparks, shows its blast ring) and foes
      near it scramble away; the blast throws foes back and smashes crates round it; kegs set each
      other off. Foes' shots light kegs and break pots too, and wear crates down (cover breaks
      under fire). Lightning flashes over the stormy floors (Nightspire, the rooftops, the
      Eclipse); ink rain on the chapter floors (the floors' own rain, snow, ash... were already
      there). IPA 17.

## Stage 18 (his word, 7 Oct: "3, 4, 5")
- [x] 18.1 THE DAILY TRIAL: one fixed run a day (seed and hero from the date) with a rule of the
      day; best score kept and shown in the camp.
      Done: a standing stone in THE CAMP. Rules: POWDER DAY (kegs in every fight, blasts x2), ELITE
      HOUR (half the foes elite), GLASS HEROES (double damage, 2 fewer hearts), GOLD RUSH (double
      gold, shops +50%), HASTE (you and every foe 30% faster), BIG GAME (guardians +50% health,
      2 more relics). Score: floors x1000, foes x10, guardians x500, gold, a win +5000; the day's
      best on the stone; +50 embers. `--day=YYYYMMDD`. `tests/daily_test`.
- [x] 18.2 A new hero from the story: THE INKLING (ink that lingers, sketched allies).
      Done: THE INKLING (250 embers at the shrine). INKWELL QUILL: curving ink bolts that poison.
      INK: a fifth of hits leave a pool of ink (poisons; drawn as dark ink); half of the poisoned
      foes it kills rise as sketched wisps for 6s. SKETCH (special): three ink wisps for 10s and a
      flood of ink that poisons every foe near. Skill branch INKCRAFT: INK BLOTS, SKETCHBOOK, WET
      PAGES, MASTERPIECE. New zone kind "ink" (combat.gd, vfx.gd).
- [x] 18.3 Bot balance pass: many bot runs, measure what is never worth taking, raise the weak
      (nothing lowered). IPA.
      Done: `tests/balance_probe` (a tool: each trait at full rank and each whole set alone in the
      same seeded arena, damage against a baseline; ~100 s). Raised: GRAVITY WELL (every 5s, wider
      pull, blast 90 wide for 300%), FALLING STAR (every 5th kill, stronger), THUNDER STEP (3
      strikes), POWDER KEG (16%), OPEN VEINS (50%), SHADOW KNIVES (6, stronger), RETORT (12,
      stronger), THE HOST (4 wisps for 12s). What scores low but works through rolls, hits, rooms
      or gold was left as it is; the strongest sets (Plague Doctor, Conclave) were not touched.
      IPA 18.

## Stage 19 (his word, 7 Oct: "3, 5")
- [x] 19.1 A fair balance check for heroes who fight up close: the probe with foes that walk in
      (`--probe-melee`), run for the melee heroes; raise what is weak for them (nothing lowered).
      Done: run for the Berserker, Executioner, Oathbreaker, Gaolbird, Sellsword. The one real gap:
      extra projectiles did nothing for swords and whips (BULLET STORM was a 20% loss for them).
      Now each extra projectile widens a sword's swing (+30 degrees) and adds 15% damage, and is
      one more lash for a whip. BULLET STORM for them: 1.02-1.35x (swords), 1.3-2.3x (whips).
- [x] 19.2 More life in THE CAMP: visitors who come and go, a cook who turns your fish into a meal
      for the next run, and a training ground where any weapon or relic can be tried on dummies. IPA.
      Done: THE COOK by the fire. Every fish you catch (any pond) goes in a larder; eight meals
      (FISH SOUP +1 heart, GRILLED EEL +15% damage, EMBER CHOWDER +15% fire rate, INKFISH PIE +10%
      crit, GOLDEN FILLET +50% gold, IRON STEW +3 armor, BOOT BROTH a key and a bomb, THE MOONLIT
      FEAST a relic, a heart and +10% damage), one at a time, eaten at the next run's start.
      VISITORS, two of four each time: THE PEDDLER (a relic for embers, waiting at the next run's
      start), THE BARD (a song: +10% speed and gold next run), THE SEER (tomorrow's daily trial and
      a fortune), THE FISHMONGER (buys fish past 3 of a kind for embers). A STRAY CAT naps by the
      fire; pet it and it follows you; 10 pets and it stays, named SOOT. THE TRAINING GROUND: a
      fenced yard with 3 dummies (damage per second) and a rack: every weapon and relic in the
      game, tried in the camp only (nothing counts as found); PUT EVERYTHING BACK. The daily trial
      leaves the camp's gifts for the next ordinary run. New sprites: the cook, the four visitors,
      the cat. Nothing hurts in the camp; autofire there only reaches the dummies nearby.

## Stage 20 (his word, 8 Oct: "3, 4, 5")
- [x] 20.1 A second balance pass: why the Condemned and the Sellsword dealt the least of the
      close-range heroes (raise them if it is real), and a test fight with rolls, hits, new rooms
      and gold, to measure the traits the first one could not (MARTYR, THE HOST, LEGION, PRISM,
      THUNDER STEP ...). Raise the weak ones; nothing lowered.
      Done: a live test fight (`--probe-live`: foes that walk in and foes that shoot, hits land,
      a roll every 2s, the skill when ready, a new room every 10s). The Condemned and the
      Sellsword are fine once they roll and use their skill (1,636 and 2,659; the middle is about
      2,150). The weakest were the six originals, who had no skill: in the expanded game each now
      has one (WITCHING HOUR, HUNTER'S VOLLEY, WHIRLWIND, OPEN GRAVES, GRAND REACTION, LANTERN
      FLARE) and the two free starters a passive (HEXCRAFT, QUICK HANDS). Hexer 829 -> 1,705,
      Poacher 958 -> 1,560, Brute 1,301 -> 2,446, Gravedigger 1,125 -> 1,514, Alchemist 1,296 ->
      2,237, Warden 1,210 -> 2,073. Raised too: Frost Witch 665 -> 1,975 (her shards now pierce,
      chilled foes take +30% from her, BLIZZARD hits for 150%), Beastmaster 988 -> 2,204,
      Clockmaker 1,044 -> 1,556 (a ring of gears every 12th shot), Minstrel 1,006 -> 1,498,
      Pilgrim 1,136 -> 1,794, Tinkerer 1,293 -> 1,619. The Forsaken stays the hard one on purpose.
      Traits: WINTER'S HEART (every second, +50%), PRISM (+15% an ailment, 15% of hits add one),
      TOXIC BLOOM (every 3s, and the foes near you). MARTYR, THE HOST, LEGION, THUNDER STEP and
      OVERCHARGED are strong once rolls, hits and rooms are in the fight: left as they are.
- [x] 20.2 Camp upgrades and quests: embers build the camp up (more meals at once, a third
      visitor, a better rack, more), and a quest board with small goals that pay embers.
      Done: THE CARPENTER at her workbench and her PLANS page (with a picture of each): LANTERNS
      (40), THE FISH TRAP (80: a fish for the larder every time a run ends), THE HERB GARDEN (100:
      every meal also +1 max heart), THE SMOKEHOUSE (120: two meals at once), THE GUEST TENT (150:
      a third visitor), THE MASTER'S RACK (150: every piece of armour and whole sets on the
      training ground), THE LENDING RACK (250: set out holding a weapon you have found before and
      it comes along in your pack). Each stands in the camp once built. Two more visitors: THE
      GAMBLER (bet 20 embers, double or nothing, 3 a visit) and THE TINKER (a piece of armour
      waiting at the next run's start). THE QUEST BOARD: three goals from 26 (floors, guardians,
      foes, gold, relics, a set, fish, secrets, levels, the daily trial, Chapter II, a weapon
      kind, a hero, the Old One, a hidden combo, dread, a camp meal), 30 to 150 embers each, paid
      on the run's tally (dread multiplies them); a fish or a combo found in the camp pays at the
      board. A set tried on the training ground never counts as completed.
- [x] 20.3 Chapter IV: a new world after the Reader, with its own foes, guardians, gear sets and
      story. IPA.
      Done: CHAPTER IV, THE LIBRARY (STORY.md). When the Reader falls: close the book (a win) or
      step out onto the shelf. THE STACKS (bookcases on the walls, dust in the air, FALLING BOOKS;
      mothlings, dust bunnies, shelf mimics, book golems, card sprites; mini THE OVERDUE; guardian
      THE SHELVER), THE READING ROOM (rugs, green lamps, A FALLING LAMP; shushers, lamp wisps,
      bookends, page wings, spectacles; mini THE QUIET; guardian THE HUSH), THE HEARTH (burning
      pits, FALLING EMBERS, ash and embers rising; cinder pages, ash worms, poker knights,
      fire-dogs, sootlings; mini THE KINDLING; THE CRITIC, the last of all). The Critic's fall:
      "WELL READ", +700 embers, a banner in the camp. New sets BOOKWORM (4) and THE CRITIC'S
      REGALIA (legendary, 6); the guardians drop THE SHELVER'S ARM, THE HUSH BELL and THE RED PEN.
      21 new sprites (with elite and evolved forms), three floor tile kits, 13 icons, the
      Archivist's new lines. `--chapter=4`. IPA 20.

## Stage 21: a living game (his word, 8 Oct: "how to make game more alive" ... "1,2,3,4,5,6")
- [x] 21.1 Voices and reactions: speech bubbles. The hero speaks at big moments (low health, a
      legendary, a guardian down, a new floor), foes bark (elites taunt, shushers SHH, guardians
      open their fights with a line), nearly dead foes may flee, and the camp's people greet you
      by your hero's name and remember your last run.
      Done: speech bubbles over heads. The hero: a line on every floor (each of the 20 floors has
      its own), at low health, on a legendary, when a guardian falls, a level, a whole set, rising
      again, a shop, six kills in three seconds; every hero has a voice of their own for some of
      these. Elites taunt when they come near; about 30 kinds of foe bark now and then (SHH!,
      *CLATTER*, WOOF!); all 38 guardians open their fight with a line. One ordinary foe in three
      runs for a moment when nearly dead ("NOT LIKE THIS!"). In the camp everyone greets you by
      your hero's name, and the archivist (or the seer) remembers how your last run ended
      ("FLOOR 5, AND A SKELETON. IT HAPPENS."). `tests/barks_test`.
- [x] 21.2 Rooms that keep their story: fallen foes leave bones, ink or ash that fade slowly,
      blasts leave scorch marks, candles and bookcases can be knocked over, critters scatter
      when you come close or something blows up.
      Done: every fallen foe leaves something of its own kind (bones, goo, ink, ash with embers,
      torn paper, feathers, scrap, a fading glow, or a splash of its colour; guardians a big one).
      They stay with the room (come back and they are still there) and fade after about 35s.
      Big blasts leave scorch marks. Fight rooms get standing candelabra (bookcases in the
      library) that fall to a roll, a shot (yours or a foe's) or a blast, and stay down. Crows
      peck about on the open-air floors and take off when you come close or something blows up;
      new ones land later. All drawing only, with dice of its own. `tests/remains_test`.
- [x] 21.3 The sound of each place: a quiet loop for every world, footsteps that change with the
      floor, music that swells in a fight and calms after (all made here, original).
      Done: 11 loops of 8 seconds made from scratch by a small program here (dripping crypt,
      crickets in the grotto, rain with far thunder, lapping water, the forge and a far anvil,
      wind with a bell, the hum of the Eclipse, bubbling ink, a ticking library clock, the
      roaring hearth, the camp's fire and crickets). Every floor and every rift world has one;
      a new place fades in as the old one fades out. Footsteps on 7 kinds of floor (stone,
      wood, grass, snow, water, paper, metal). The music is as loud as before in a fight and a
      little softer once the room is quiet, and the place's own sound comes up. OPTIONS has a
      new switch, PLACE SOUNDS, to turn the loops and footsteps off. `tests/ambience_test`.
- [x] 21.4 Life between the fights: a rival adventurer who races you to chests (help or fight),
      your last hero's ghost where they fell with some of their gold, lost travellers met on a
      floor.
      Done: after a fight is won, sometimes someone is there. A RIVAL (another hero) comes in
      with a chest on the far side and races you to it: get there first and they sulk off; be
      slow and they grab it and run. Wave them on and they come back in your next fight on that
      floor and shoot at your foes ("I OWE YOU ONE"); shoot them and they fight you for it,
      then give up, dropping the chest and their purse. When a hero dies, the next run finds
      their GHOST on that floor, where they fell, with 40% of the gold they had. A LOST
      TRAVELLER (a pilgrim, a pedlar, a bard...) asks to be led to the guardian's door: they
      follow you room to room and chat; a foe's shot or touch hurts them, and after three hits
      they run home; at the guardian's door they pay with a relic and gold. Not in the daily
      trial. `tests/wanderers_test`. Test switch for pictures: `--wanderer`.
- [x] 21.5 Monsters with lives of their own: some foes asleep until you come close, packs that
      call for help, moths drawn to the lamps, fire-dogs chasing sootlings, slimes that swallow
      dropped coins and grow.
      Done: in the first wave of a fight room, one walking foe in three is asleep (Zz). It wakes
      when you come near, when it is hit, when another foe calls, when it is the last one, or
      after 14 seconds; the first hit on a sleeper does double damage (SNEAK ATTACK!). A foe
      brought below half health may call for help ("HELP!", "AWOOO!"): sleepers near it wake,
      and its own kind runs a third faster for 3 seconds. Mothlings flutter round the nearest
      candelabra or wall torch until you come close or hit one; knock their candelabra over
      and they come for you in a frenzy. In the Hearth, fire-dogs chase the sootlings about
      until they notice you (the sootlings flee, "EEP!"). Slimes leave you for coins and gems
      dropped near them and swallow them: each makes the slime bigger and tougher (+20%
      health); burst it and the coins come back. `tests/lives_test`.
- [x] 21.6 The camp follows the iPad's clock: birds in the morning, lanterns in the evening,
      fireflies and stars at night; the cat brings small gifts. IPA.
      Done: the camp reads the iPad's clock. Morning (5-10): a warm haze, songbirds (brown,
      blue, red, yellow) land and peck about and fly off when you come near, and birdsong by
      the fire instead of crickets. Day (11-16): as before, with birdsong. Evening (17-20): a
      dusky light, five lantern posts lit, the first fireflies, crickets. Night (21-4): dark
      blue, the lanterns and the fire glow, fireflies drift and blink, stars and the moon
      shine in the pond. The banner greets you for the time of day. Once a day (the iPad's
      date), if Soot the cat is about, a gift lies by the cat: a fish for the larder, or a shiny
      button, a lost ring, a feather or a mouse for embers. `tests/camp_clock_test`. Test
      switch for pictures: `--clock=H`. Stage 21 ends with IPA 21.

## Stage 22 (his word, 8 Oct: "4, 5, 6 and stability and performance polish patch")
- [x] 22.1 Weather and night in the dungeon: storms, fog, and dark floors lit by your lantern
      (what the camp got in 21.6, taken into the runs).
      Done: every floor after the first has a chance (about half) of weather fitting it: RAIN
      (falling rain, rings on the floor, the sound of rain), STORM (wind-driven rain and
      lightning), FOG (banks drifting across), SNOW (flakes; the sound of wind), ASH (ash and
      embers falling), or NIGHT: the rooms go dark but for the light of your lantern (the
      Warden's is bigger), the wall torches, candelabra, fires, blasts, chests and glowing foes.
      In the dark, foes' eyes glow red; their shots, warnings, danger circles and health bars
      always show. A word when the floor begins ("NIGHT HAS FALLEN: KEEP TO THE LIGHT"). The
      camp at night is now lit the same way: lantern posts, the fire and the portal light it.
      Rift worlds keep their own look. Drawing only (replays unchanged). `tests/weather_test`.
      Test switch for pictures: `--weather=KIND`.
- [x] 22.2 Endless descent: a mode to see how deep you can go; your best depth is kept.
      Done: THE ENDLESS STAIR, a stairwell beside the camp's portal (DOWN; your best depth
      under it). Take it, choose a hero ("THE ENDLESS DESCENT"), and go down all twenty floors
      in order, each with its guardian; a fallen guardian leaves its hoard and the stair down,
      never an ending (no Throne victory, no chapter endings). Past the Hearth the stair goes on
      into the Ossuary again, a loop deeper, where everything is much tougher, and so on for
      ever. The depth is on the floor banner ("DEPTH 5   BEST 5"), the HUD and the end of the run;
      going deeper than ever before says so and pays 50 embers; the run's embers count the depth
      (6 a floor). The camp's chapter quests are not won on the stair. (In the title menu there
      was no room for another line, so the stair is in the camp.) `tests/endless_test`. Test
      switch: `--endless`.
- [x] 22.3 A bestiary: every foe you have met, their lines, how many you have beaten, and your
      past runs.
      Done: the title's CODEX has three pages now, named along the top (tap one, or ROLL for the
      next): RELICS (as before), BESTIARY and PAST RUNS. The bestiary holds all 212 foes and
      guardians, floor by floor and then the rift worlds; one you have not met is a dark shape,
      guardians stand on red. Pick one: its name, where it lives ("LIVES IN THE OSSUARY", "A
      GUARDIAN OF THE CINDERFORGE"), how many you have slain, and what it says. It counts from
      now on: foes met before this IPA start as shapes. PAST RUNS lists your last ten runs: the
      hero, how far (or the endless depth), how it ended, the time, foes slain, embers and the
      date. `tests/bestiary_test`. Test switch for pictures: `--ui=bestiary` / `--ui=runs`.
- [x] 22.4 Stability and performance polish: profile the heaviest fights and everything Stages
      21-22 added, a long random-button soak for crashes, fix what is found (nothing toned
      down). IPA 22.
      Done: the soak (random buttons for an hour of play from the title, and 16 shorter runs,
      now also in the endless stair, night and storm floors, the wanderers and Chapter IV) found
      two real faults, both fixed: (1) OPTIONS > KEYBOARD KEYS waited for a key press for ever,
      so an iPad with no keyboard was stuck on that page; now a tap, BACK or 8 seconds ends the
      wait. (2) The camp's TINKER broke his talk box for most of the gear he could offer (gear
      with no set); fixed, and a failed talk box now shows nothing instead of a second error.
      After the fixes: 16 of 16 soak runs clean, the hour included, and the game's object count
      levels off (no leak). Measured: the new foe lives cost about 0.04 ms of a frame's logic; a
      night or storm floor about 0.2-0.3 ms more to draw here (on this container's software
      graphics; the iPad's chip does the dark in one cheap pass); nothing worth changing.
      Stage 22 ends with IPA 22.

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
