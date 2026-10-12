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

**Next up (his ask, 10 Oct: "add what will you do next on to do list"):**
1. Stage 42 the INTELLIGENCE traits: done, IPA 42 built (10 Oct).
2. Stage 43 (done, IPA 43): 15 SUPER traits for every hero, 11 PSYCHIC traits for the Mindwarden, 5 AUGMENT
   traits for the Tinkerer (IPA 43). His word (10 Oct): "Do next stage then stability test and
   bug fix": straight on, without waiting for his try of 42.
2b. Stage 43.5: a stability test and bug fixes: done, IPA 43.5 "Steady Ground" built (10 Oct).
2c. Stage 43.7: the 286 OLD traits made like the new ones: done, IPA 43.7 "Old Traits Reborn"
   built (10 Oct, run 282): each keeps all it did and gains one more effect from the new mechanics, and each has
   its own picture.
   His word after IPA 43.7 (10 Oct): "Ok go 44 and 45, and 46": the three stages straight on, each
   with its own IPA, without waiting for his try in between.
3. Stage 44: the 14 INFUSIONS, and the traits that work with them: done, IPA 44 "Infusions" (10 Oct).
4. Stage 45: the GOOD, EVIL and LAWFUL shops: done, IPA 45 "Alignment Shops" (10 Oct).
5. Stage 46: WEAPON ENCHANTMENTS from his pictures: done, IPA 46 "Weapon Enchantments" (10 Oct).
   All 46 with names of our own (ENCHANTMENTS_PLAN.md has the list), THE ENCHANTER in the shops,
   THE WYRM'S BREATH, and the runesmith, the back room and the silver branch.
6. His list, 10 Oct (after IPA 46): another game's core gameplay, combat and equipment. What we
   have and what is new: GAMEPLAY_PLAN.md. Proposed Stages 47 to 51 (below). His pick (10 Oct):
   "Stage 47 first": THE GOURD and SHATTER, with its own IPA, then wait for his try.
   His word, during it (10 Oct): "Also we need to rework the menu it looks all confused and heroes
   stacked in front, also we can work on character select menu to be better": in Stage 47 too.
   Stage 47 done: IPA 47 "Gourd and Shatter" (11 Oct; the full check passed).
7. His word, 10 Oct (during 47; three pictures of the other game's 16 "cinders"): 16 difficulty
   steps, played at about the 12th; each step also +0.5% health and armour per floor to every
   foe and guardian; each step multiplies the meta progress ("+30% for 0-4, 20% for 5-8, 10% for
   9-12, 5% for 13-16"); "also expand and reset constellation and hero trees, in options make
   reset the game option". Stage 48 (below), right after IPA 47. The proposed 48 to 51 become
   49 to 52.
8. His clip (10 Oct): a slow fight (14 to 19 FPS) in an Alchemist run with 7704% crit; then (11 Oct)
   "Check every trait for lag and bugs". Done in 47.6: every trait and relic checked in a live
   fight (all pass alone); SHOW FPS now names the costliest parts. Waiting: his relics page and a
   clip of a slow fight with the new line, to fix his exact case.
Each stage waits for him to try the last IPA. Details of each step are further down.

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
      The full check then caught a flaky test (one run in four): a blast in its first half
      knocked a candelabra over and the second half found it down; the test now stands props
      up between the halves, and a falling prop always throws the same particles. After the fixes: 16 of 16 soak runs clean, the hour included, and the game's object count
      levels off (no leak). Measured: the new foe lives cost about 0.04 ms of a frame's logic; a
      night or storm floor about 0.2-0.3 ms more to draw here (on this container's software
      graphics; the iPad's chip does the dark in one cheap pass); nothing worth changing.
      Stage 22 ends with IPA 22.

## Stage 23 (his word, 8 Oct: "Add more magic weapons with super cool effects")
- [x] 23.1 THE SPELLBOOK: ten new kinds of spell, each its own effect, never seen in the game
      before: a black hole that drags foes in and collapses; a fire serpent that slithers after
      foes; a comet that crosses the whole room; rune circles that erupt in pillars of light;
      blades that dance and fight on their own; a clock that stops time (foes crawl, their shots
      hang in the air); a prism bolt that splits into colours and splits again; a storm cloud that
      follows foes and strikes; a pinball of light that bounces from foe to foe; wild magic,
      every cast a different spell. Twenty magic weapons using them (two of each kind, each with
      a twist), with icons of their own. Expanded game only; nothing removed or toned down.
      Done: `scripts/combat/spells.gd` and twenty weapons at the end of the weapon list (classic
      never sees them), each with its own 12x12 icon; see `ARSENAL.md` part 5. The time-stop
      holds ordinary foes still (a guardian is only slowed). Wild magic heals at most every 20 s
      and gives no gold from the training dummy. `tests/spells_test` checks each weapon's trick in
      a fight, the caps and the logic time with 999 more projectiles (under 0.7 ms a tick here),
      stopped time and wild magic. In its test fight each sits with the old weapons of its rarity
      (the pinballs and the event horizon were first much stronger and were tuned before release).
- [x] 23.3 (his recording, 8 Oct: "We have a problem"): a late run (floor 12, level 52, THE BLANK
      QUILL at 100+ attacks a second, two TWIN-SOUL RINGs) ran at 31 fps with LOGIC 16.3 ms, and the
      room was hidden under giant pink squares. Done: (1) a bug: with the room full of shots, an
      attack's shots merge into a shot already flying, and a heavy shot's x3 and x1.5 (or a lance's
      reach) landed on that old shot once per merged shot, attack after attack: a shot grew to a
      radius of 59000 px and its damage tripled over and over. A merged shot now hands back a
      stand-in with its own share; the share is tripled, the old shot keeps its size. (2) Speed,
      same rules: triggers find their procs through an index (it looked through every proc of a
      40-relic build each time); a whole attack merges at once when the room is full (the dice it
      would have rolled are still rolled). (3) Giant shots (past twice their size) fly fewer at once:
      the cap falls with their size from 300 to 120, the rest merge their damage as at any cap.
      (4) Past 80 poison pools the oldest dry up (a foe's poison stops at 12 stacks anyway).
      (5) Drawing only: a shot is drawn at most 16 px in radius (its reach is untouched); blasts in
      quick succession redraw the floor's scorch marks together, five times a second at most.
      Measured on a rebuild of his fight (tests/quill_profile, six fights): 6.5 -> 4.9 ms of logic
      a tick here (-26%, worst ticks 75 -> 40 ms); with the HEAVY BOLT trait 13.8 -> 10.7 ms. On his
      iPad that is about 16 -> 12 ms (an estimate: no iPad here). All replays identical.
- [x] 23.2 Checks, the core replays re-recorded (new weapons change what drops), IPA 23.
      Done: tools/check.sh CHECK PASSED on the final code (spells_test and heavy_build_test in it).
      Replays: the classic 6 identical; core replay h re-recorded on purpose (the rare pool grew by
      eight, so the bot picks up another old weapon at 89 s), the other 7 identical; 23.3 changed
      no replay. Pictures: old vs new code, 900 frames each of a plain and a dynamite run, 0 differ
      (seeded runs now seed every decoration die, so they repeat). Soak: 4 runs of 5 minutes with
      random buttons and spell weapons, no errors. IPA 23.

## Stage 24 (his word, 9 Oct: "Day and night cycle is too dark at night it is hard to play, also
make armor sets not repetitive like now, it drops only one set until you complete it like bug and
also when you complete it it still drops frequently")
- [x] 24.1 Lighter nights: night floors in the dungeon and the camp at night stay night, but you
      can see the room and the foes in it (less dark, a wider lantern).
      Done (weather.gd): the dark over unlit floor 0.8 -> 0.52 on night floors and 0.5 -> 0.34 in
      the camp at night, a moonlit blue instead of near black, the lantern 80 -> 108 px; the
      camp's evening and night tints a little lighter (camp_clock.gd). Drawing only.
- [x] 24.2 Armor sets without the repetition: a started set's missing pieces come far less often
      (and the shop still offers one); no piece you already own drops again; a set you have
      whole stops dropping; two drops in a row are not from the same set.
      Done (gear.gd random_gear): the chase is 8% + 4% a worn piece (x1.6 with MASTER TAILOR),
      where it was 25% + 10% a piece; a piece worn or in the pack is rolled again (so a whole set
      stops dropping); never two gear drops in a row from one set (up to 4 rolls). Measured: with
      one piece worn its set came 42 times in 400 drops (it was over 1 in 3). tests/sets_test
      checks all of it. Core replay e re-recorded on purpose (at 148 s the bot now finds a sapper
      vest where it found a second bastion piece); the rest and the classic replays identical.
- [x] 24.3 Checks, the core replays re-recorded (drops change), IPA 24.
      Done: he asked to skip the full check to save his credits (9 Oct), so IPA 24 was built
      without it. Run: sets, weather, camp clock and ambience tests, and all replays (classic
      identical, core e re-recorded on purpose). The next session should run tools/check.sh first.

## Stage 25 (his word, 9 Oct: "add more cool traits and magic weapons also melee weapons, dont test
just compile" and "add new effect system")
- [x] 25.1 REACTIONS (scripts/combat/reactions.gd): two ailments on a foe react, once every 2 s a
      foe: burn+chill MELT (300%), burn+poison TOXIC BLAST (200% around), chill+shock SHATTER (200%
      around, stun), poison+curse WITHER (vulnerable, weakened), bleed+curse HEMORRHAGE (350%),
      shock+burn OVERLOAD (lightning). Checked after every blow in Combat.damage_enemy.
- [x] 25.2 Fourteen traits (y_*: STORM HEART, RED HARVEST, FROSTWAKE, ECHOING EDGE, METEOR SHOWER,
      MIRROR SKIN, PLAGUE BEARER, WILD CARD, BLOOD FRENZY, DREAD LORD, THORNHIDE, COMET ROLL, and
      for reactions ALCHEMIST'S EYE and CATALYST). Nine magic weapons (MOONWELL, HYDRA'S ROD,
      SKYFALL STAFF, STORM SIGIL, TIMEWARP SCEPTER, RAINBOW STAFF, SKYBREAKER ORB, LUCKY STAR,
      STORMFIRE ROD) and nine melee (THUNDERFANG, FROSTBRAND, VOID SCYTHE, EMBER PIKE, QUAKE HAMMER,
      SERPENT LASH, TWIN FANGS, GIANTSBANE, STEAMFORGED BLADE); several carry two ailments that
      react. Icons recoloured from existing shapes (tools/art/sprites.py), atlas baked.
- [x] 25.3 At his word only compiled (import, atlas test, 20 s runs with three of the weapons): the
      next session runs tools/check.sh (content_test lints every new row) and re-records the core
      replays on purpose (new items and reactions change the fights). IPA 25.

## Stage 26 (his word, 9 Oct: "Add more super cool synergy and legendary and mythic traits, with super
cool effects, add new effects and synergies")
- [x] 26.1 New effects: the "spell" action (an item casts a spell of the spellbook at a foe:
      void, comet, glyph, blade, clock, prism, cloud, serpent, pinball; Spells.cast) and the
      "on_reaction" trigger (reactions.gd fires it). A new rarity, MYTHIC (red), above legendary:
      offered from level 6 only, never helped by a family.
- [x] 26.2 Six legendary traits (BLADESTORM, STARCALLER, STORMHERD, RUNELORD, VOIDHEART, CHAIN
      REACTION), six MYTHIC (ASCENDANT, WORLDBREAKER, CHRONOMANCER, PRISMATIC SOUL, ELEMENTAL
      AVATAR, SERPENT KING) and nine hidden synergies (STEAM ENGINE, PLAGUE STORM, DANCE OF BLADES,
      STARFORGE, THE ABYSS, FROZEN HOUR, WYRMFIRE, HAND OF GOD, REACTOR).
- [x] 26.3 Only compiled (import; 30 s runs with the new traits given, no errors). Next session:
      tools/check.sh first (content_test lints the new rows), the core replays re-recorded on
      purpose. IPA 26.

## Stage 27 (his word, 9 Oct: "can we add mythic armors and other weapons")
- [x] 27.1 A MYTHIC item rarity (red, above legendary): guardians drop one 8 times in 100, elites 3,
      ordinary drops from floor 7 (1, 2, 3... deeper); prices, pawn, names and colours know it;
      mythic weapons glow in the hand and grade S like legends. Expanded game only.
- [x] 27.2 Seven MYTHIC armor pieces, one a slot (CROWN OF THE STORM KING, AEGIS OF ETERNITY,
      STRIDERS OF THE VOID, GAUNTLETS OF THE MAKER, RING OF ALL ELEMENTS, HEART OF THE PHOENIX,
      SHARD OF THE FIRST STAR), six MYTHIC weapons (WORLD-ENDER, BOW OF THE DAWN GOD, ETERNITY'S
      EDGE, STAFF OF THE ABYSS, DRAGONLORD'S LANCE, SCEPTER OF THE THUNDER KING) and six more of
      other kinds (STARSHELL MORTAR, FROSTFOAM GUN, DECK OF RUNES, SPECTRAL REPEATER, VIPER'S BOW,
      HAMMER OF THE VOID), most casting the spellbook's spells. Icons: recolours and one new boot.
- [x] 27.3 Only compiled at his word (import, atlas test, two 30 s runs: no errors). He tests on the
      iPad. IPA 27.

## Stage 28 (his word, 9 Oct: "Can vo name versions of the game with latest tweaks and version number")
- [x] 28.1 Every version has a name and its tweaks, kept in `scripts/data/versions.gd` (one line a
      version, newest first: number|Name|tweak; tweak). The title screen shows the newest in its
      bottom right corner (V28 VERSION NAMES). The IPA build reads the line of the version in
      VERSION (`tools/versions.sh`): the release is titled "Tiny Biggot Rogues 28: Version Names",
      its notes list the tweaks, the file is `TinyBiggot-28-Version-Names.ipa`, and every older
      release (4.14 to 27) is retitled and given its tweaks the same way. The build stops at once if
      the version has no line at the top of the list. IPA 28. From now on: every `[ipa]` commit
      adds its version's line at the top.

## Stage 29 (his word, 9 Oct: "There are still some empty hidden rooms, also make better trait listing when I pick up trait at start of the game there are only basic traits, make so much new and cool traits so every run could feel different")
- [x] 29.1 Hidden rooms (expanded game, `G._fill_secret`): never an empty pedestal (no relic left:
      a free iron chest; the same for the mirror's gift and an empty blood market); a little loot
      beside every find; two new kinds: THE GOLDEN GRIMOIRE (read it: one of three rare traits)
      and A DRAGON'S HOARD (two chests, 16 coins, gems, embers).
- [x] 29.2 Better trait picks (expanded game): every run opens with an OATH pick (three of 19
      run-shaping traits, before the first room: the start room's dummy and target no longer hold
      a pick back); the first row of every pick is rare or better when one can be offered
      (`Traits.SPOTLIGHT`); the plain original traits weigh 1 instead of 3; SUPER traits from
      level 3 (was 4) and twice as often.
- [x] 29.3 54 new traits: 19 OATHS (FLAME, FROST, VENOM, THUNDER, BLOOD, THE SWARM, STEEL, SHADOWS,
      THE ARCHMAGE, GREED, THE DUELIST, RAGE, RUIN, THE HEXER, THE GRAVE, THE ENGINEER, THE
      HOURGLASS, CHAOS, DAWN) and 35 more, common to mythic.
- [x] 29.4 Only compiled at his word (import; a 30 s bot run; a 30 s run with all 54 new traits
      at once; twelve hidden rooms; pictures of the oath pick and a hoard: no errors). IPA 29.
      Next session: the full check (content_test lints the new rows and their texts) and the core
      replays re-recorded (the oath pick, the offers and the hidden rooms change every run).
      Classic is untouched (all of it behind `GameData.rogues()`).

## Stage 30 (his word, 9 Oct: "2,3", from the list after Stage 29: oaths that grow, a trait book)
- [x] 30.1 OATH VOWS (`scripts/data/oaths.gd`): every one of the 19 oaths carries a vow (KILL 120
      BURNING FOES, ROLL 150 TIMES, CALL 60 COMETS, KILL 12 ELITES, CLEAR 10 ROOMS...). Keep it and
      the oath AWAKENS: a second power for the rest of the run, a banner. The vow shows on the
      oath pick and under the map while it counts (gold once awakened). Test
      `tests/oaths_test.tscn` (in check.sh): each oath sworn, its vow kept, awakened once, 3 s of
      fight with the new powers.
- [x] 30.2 THE TRAIT BOOK: the codex's fourth page, TRAITS. All 256 traits and oaths, rarest first,
      lit once a pick has shown them; how often each was taken; the chosen one's text, and an
      oath's vow and awakening. Keys and taps. `--ui=traitbook`.
- [x] 30.3 Compiled; oaths test passed; 30 s bot runs; pictures of the trait book and the vow
      lines. IPA 30. The full check and the core replay re-record still wait (see 29.4).

## Stage 31 (his word, 9 Oct: "Can you add more fun and crazy weapons with cool effects and new effects 20+")
- [x] 31.1 THE TOYBOX (`scripts/combat/toys.gd`): eight new kinds of weapon, each a new effect:
      shark (a fin under the floor that bites 3 foes), twister (lifts and carries foes, flings them
      down), disco (a mirror ball whose beams hurt and make foes dance), yoyo (a cutting string),
      portal (shots come out behind the foe, +50%), saw (blades that dig in as traps), voodoo
      (pinned foes share 35% of each other's harm) and anvil (a crush from the sky, then cover that
      stops shots). Twists: frenzy, sharks, party, twin, rift, magnet, doom, piano. The action
      ["toy", kind, mult] lets items loose them too.
- [x] 31.2 26 weapons: one of each kind, one with each twist (SHARKNADO is mythic), and ten crazy
      ones on old kinds that let toys loose (THE FISH SLAPPER, RUBBER CHICKEN, CONFETTI CANNON,
      PINATA STICK, BOTTLED TWISTER, BLACKSMITH'S REVENGE, PARTY HORN, CURSED CROSSBOW, BOW OF
      ELSEWHERE, BUZZ BLADE). 26 icons (19 drawn, 7 recoloured), atlas baked.
- [x] 31.3 Compiled; atlas test passed; new test `tests/toys_test.tscn` (in check.sh) passed: all
      26 fired in a live fight, every kind did its thing; pictures of four in a fight. IPA 31.
      The full check and the core replay re-record still wait (see 29.4).

## Stage 32 (his word, 9 Oct: "now do performance and stability check and update it, then we will work on some new additions")
- [x] 32.1 The full check after Stages 24-31 (25.3-31.3 waited for it): 18 failures, all fixed
      (item data, a lost rule gate, combo cards with a weapon partner, tests behind the oath pick).
- [x] 32.2 Speed: big volleys at the shot cap merge at once (a 50 ms stall gone); THE FLOOR BAKE:
      tiles, remains and scorch marks drawn into one picture, so they no longer cost draw calls
      every frame (heavy fight 461 -> 212, ordinary 79 -> 54; the picture byte for byte the same).
- [x] 32.3 Stability: the soak over all 30 heroes, the rift worlds, classic and loops (49 runs, no
      error); the monkey soak (random buttons) over the menus and the new content.
- [x] 32.4 The full check passes, the core replays re-recorded (Stages 24-31 changed every fight
      on purpose; the classic ones identical), IPA 32. Then his new additions.

## Stages 33-35 (his word, 9 Oct: four builds to add "and this is how the game needs to feel")
He sent four well-loved builds of the game we take ideas from, and what makes it feel good:
fast rooms, a broken sandbox with ways to bend luck (dice), many classes, and clear pictures in
a bullet storm. Ideas and play only: every name, sprite and text here is our own.

### Stage 33: build paths I (IPA 33)
- [x] 33.1 THE MIND FIELD (an INT aura build: "walk to the exit while everything dies"). AURA
      REACH: every halo and aura grows with INT; the action "halo" (the halo relics move to it);
      a visible field round you that can fill the room. Traits: OVERMIND (reach per INT), DEEP
      WELL (INT, aura damage), STILL MIND (halos pulse faster), WIDE THOUGHTS. HORIZON RING: the
      moons grow with your reach and hit hard. A hero built on it: THE MINDWARDEN.
- [x] 33.2 THE TAVERN (a STR melee build that needs no crits). Drinks for the belt (ALE, DARK
      STOUT, FIRE MEAD) give TIPSY: a growing multiplier to damage and attack speed that wears
      off. THE TAVERN, a room with a barkeep; shops sell ale. Traits: SURE STRIKE (never crit:
      the crit chance becomes damage), BIG APPETITE, IRON GUT, BAR BRAWLER, LAST ORDERS. A
      hero: THE TAVERN KNIGHT (attack speed and crit per STR).
- [x] 33.3 His report while 33 was built (9 Oct: "big green slimes, elite or not, are tanky"):
      a slime grew 20% of its current health per coin it swallowed, without end (and its own hits'
      coins fed it); now 20% of its first health, six swallows at most (x2.2). Also fixed: a foe
      shot leaving the room was looked up past the tile grid (a script error that stopped the rest
      of that tick's foe shots). IPA 33.
### Stage 34: build paths II (IPA 34)
- [x] 34.1 THE TRIGGER PATH (DEX/INT). LUCKY HITS (a chance per hit, its own trigger). THE
      SPELL SLOT: the weapon in your first backpack slot is cast for free on crits and lucky
      hits. Traits: SPELLSLINGER, FOUR-LEAF (lucky hits per DEX), STATIC BUILD-UP (shocks stack
      and discharge), QUICK FINGERS. A hero: THE TRICKSHOT.
- [x] 34.2 THE LEGION PATH (companions). Companion cap, damage and speed for every kind of
      helper (wisps, thralls, turrets, pets, swarms); move speed turns into their attack speed.
      Traits: GRAVE MARSHAL, BONE BEACON, QUICK MARCH, ENDLESS RANKS; MARCHING BOOTS. A hero:
      THE BONECALLER.
### Stage 35: the feel (IPA 35, "Dice and Pace", built 9 Oct)
- [x] 35.1 DICE to bend luck: REROLL, BANISH (gone for the run), ALTER (one row or one item
      changed): found and bought, used on trait picks, relic choices, items and shops. A run
      starts with 2 REROLL, 1 ALTER, 1 BANISH; MENU / HEAL / BOMB or a tap on the dice under a
      pick; HEAL / BOMB on a backpack item; the shop's DICE CUP restocks it; a die for sale.
      HOUSE RULES, FIXED ODDS, HIGH ROLLER, GAMBLER'S POUCH, KNUCKLEBONES. Test dice_test.
- [x] 35.2 PACE: rooms measured, then faster to start and to finish (spawns, waves, rewards),
      and a power spike in the first rooms. Measured with the bot (--pace-log): the slow part
      was the last one or two foes. Now: the next wave comes with 2 foes left, foes appear
      faster, FINISH THEM (the last foes marked, +30% damage), CLEAR RUSH (+35% walk to the
      door), FIRST SPOILS (a chest after the first fight, an item after the second).
- [x] 35.3 CLARITY in a bullet storm: foe shots always above your own effects with a dark rim,
      your hero always easy to find; nothing toned down. Foe shots, aiming lines, beams and
      warning rings are drawn last (over your shots, sparks and numbers), with a soft dark rim;
      the hero is drawn over its own effects with a light ring at its feet. Draw calls +2.

## Stages 36-39 (his word, 9 Oct: "Ideas for sprites for new stuff, and new stuff to add")
He sent pictures of a wiki of the game we take ideas from (charms, offhands, body armour, helmets,
magic weapons, companions, golden food, tipsiness) and notes on alignment, morality, loot
modifiers, damage scaling and food. Ideas and kinds of things only: every name, sprite and text is
our own (no names from there, e.g. no "Boozer" or "Emblem of ..."). Nothing that is in the game now
is removed: new things are added beside it. After Stage 35, in this order:

### Stage 36: food and drink (IPA 36, "Food and Drink", built 9 Oct)
- [x] 36.1 FOOD: room rewards, shop wares and gifts of some gear; each gives +1 XP and a point of
      STR, DEX or INT (some two). Ten or so foods, drawn here. Ten foods (the cheese: one more
      drink buff); a food room reward, one in every shop, elites now and then; PICNIC BASKET,
      GOURMAND.
- [x] 36.2 GOLDEN FOOD: rare, from the deepest floors (and hidden rooms, blood altars): each a
      lasting bonus of its own (damage of hits that are not crits, crit chance, attack speed, crit
      damage, companion damage, trigger damage, lucky hits, +1 to the highest attribute) and +1 XP.
      Ten, from floor 9 on; GOLDEN SPOON (guardians leave one).
- [x] 36.3 DRINKS as buffs: each drink also gives a buff of its own that lasts a number of rooms;
      how many can be on at once is a stat (3 to start); one more replaces the oldest; CHEESE raises
      the most; a trait makes them last for good. Today's TIPSY stays as it is. 10 rooms each; three
      new drinks (CIDER, GROG, PLUM WINE); HOLLOW LEG; the buffs show under the belt.

### Stage 37: offhands and charms (IPA 37, "Offhands and Charms", built 9 Oct)
- [x] 37.1 THE OFFHAND: a new slot. Shields (stop a shot now and then), quivers (more arrows),
      lanterns, tomes, potions, balloons, hearts, bombs: 25 or more, each with its own effect.
      27 offhands; shields stop a hit every few seconds (a small shield over the hero when ready),
      lanterns carry a field, tomes cast; shown beside the weapon in the backpack.
- [x] 37.2 CHARMS: small cards in a row of charm slots, each a passive; 30 or more. 30 charms
      (our own look: tokens on a string), 3 slots (COLLECTOR, CHARM BRACELET: more), a row in the
      backpack screen; from chests, elites and shops.

### Stage 38: alignment and loot (IPA 38, "Alignment and Loot", built 9 Oct; 38.3 waits for his word)
- [x] 38.1 ALIGNMENT REVAMP: GOOD, EVIL, LAWFUL and CHAOTIC do not cancel each other out. They
      decide the end path (the gates ask for enough of one), the prices of the tavern's and the
      vendors' wares (cheap when yours matches, dear when it is the opposite), and the bonus of
      gear that grows with one. Some heroes start GOOD or EVIL. Alignment shops can follow a
      guardian once that path's gate guardian has been beaten. 3 GOOD or 3 EVIL choose the soul
      gate (it never blocks: without them the items decide, as before); vendors x0.7 / x1.4;
      23 heroes start aligned; a WAYSHRINE after every guardian; four growing pieces.
- [x] 38.2 LOOT: each point of LUCK also gives lucky hits (34.1); new stats MAGIC FIND (rarer
      items) and TREASURE FIND (more items and gold), on gear and traits, shown with the stats.
      +2% lucky hits a LUCK; PROSPECTOR, JEWELER'S LOUPE, DOWSING ROD.
- [x] 38.3 DAMAGE SCALING GRADES (S to D) with a soft cap: **asked first** (10 Oct: no preference;
      done in 40.0 as +5% a point with no cap, nothing lowered). (a cap that lowers
      damage would tone builds down, rule 1). Without his yes, only the grade letters are shown.

### Stage 39: more to find (IPA 39, "More to Find", built 9 Oct; IPA 39.4 "Bosses Fall")
- [x] 39.1 Helmets and body armour: 30 or more new ones (hats, crowns, masks, hoods, robes, plate).
      16 helmets (a pumpkin, a frog hood, a bee veil, a chef's hat, a miner's lamp...) and 16 body
      armours (plate, robes, a wolf pelt, an apron, a feather cloak...), each with its own picture.
- [x] 39.2 Magic weapons: 20 or more (wands, staves, tomes, scrolls, a lute, an accordion, bells,
      a harp). 21: wands, rods, staves, an orb, a crystal ball, a candle, a harp, a squeezebox, a
      bell, a glass lute, beads, two scrolls and a book of moths; all scale with INT first.
- [x] 39.3 Companions: 15 or more small things that each bring a helper (an acorn, a mushroom, a
      skull, berries...), counted by the companion stats of 34.2. 15: wisps, a beetle moon, a
      frost or gun turret, a skeleton, two ravens every fight, bees from kills, a berry sprite that
      heals, a dragon egg that breathes fire, and three that make every helper stronger or more.
- [x] 39.4 His report (9 Oct, video 18:20: "There is a problem again, please fix scaling and bugs";
      THE IRON CAPTAIN stayed at two thirds of its health while he hit it some 200 times a second).
      A foe with stages stops at the line of its next stage until it breaks into it, and the break
      was part of its turn, which a stun skips: stunned on every hit, it never broke and never
      died (floor guardians and rift guardians too). Now a foe held at its stage line, or breaking
      into the next stage, takes its turn stunned or not; stuns keep all their power everywhere
      else. Blows on such a foe took nothing off but counted as damage dealt, which makes every
      foe after it tougher (power_scale): no longer. A foe's quick hits add up in one number
      instead of a block of gold numbers. IPA 39.4.

### His word, 10 Oct (night): every trait from his pictures, and infusions
He sent 18 pictures of trait lists (STR, DEX, INT, Super Hero, Esper, Cyborg) and infusions: "include
all listed traits and pictures of traits" (how they look: a square pixel picture in the trait's
colour) and "Also add infusion mechanics". 146 traits and 14 infusions, each transcribed with what
it becomes here in **TRAITS_PLAN.md**. Our own names and pictures (rule 3). Asked what was next
before this, he had no preference: the +5% numbers of his notes go in with Stage 40, the alignment
shops after the traits.

### Stage 40: the trait look and the STRENGTH traits (IPA 40, "Strength Traits", built 10 Oct)
- [x] 40.0 His notes' numbers: +5% damage per STR, DEX or INT point (times the weapon's grade; it
      was 3%), no soft cap (38.3: never his yes, it would lower big builds); +5% lucky hits per
      LUCK (was 2%).
- [x] 40.1 The look: every trait row's box in its group's colour (STR pink-red, DEX green, INT
      blue, SUPER red), and a trait with a picture of its own shows it there.
- [x] 40.2 Shared mechanics the STR list needs: POWER, the hit kinds (crushing, ruthless), the
      named buffs (courage, berserk, rage, burning passion), instability, puncture, crush.
- [x] 40.3 The 38 STRENGTH traits of TRAITS_PLAN.md, each with its picture.

### Stage 41: the DEXTERITY traits (IPA 41, "Dexterity Traits", built 10 Oct)
- [x] 41.1 What the DEX list needs: lethal hits, close range for bows, rate from speed, fields,
      helpers by count, tally crits, repeats at x2, tick speed, a tailwind and morale (buffs), a
      grenade lob, the weakest foe weakened, a pup (scripts/combat/finesse.gd). Sneaky hits wait for
      the INT list (TRICKERY needs them).
- [x] 41.2 38 DEXTERITY traits, each with its picture. The 39th (infusion buffs for good) comes
      with the infusions in Stage 44.
- [x] 41.3 His ask (10 Oct): "Also add cubes around the trait sprites". Like his wiki pictures,
      every trait picture sits in a square frame of its colour with a black gap around it
      (TraitView.cube): on the level-up rows, in the trait book, and on the pause menu's TRAITS
      page, which now shows every trait you have as a cube (arrows or a tap choose one; its text,
      its family's bonuses, synergies and combos beside it; scripts/render/trait_page.gd).
      --classic keeps the old text page.

### His word, 10 Oct: how traits work (his text from the wiki), and a limit of 12
He sent the wiki's "How traits work": traits come from a random pool at each level-up, at most 6
different ones a run; dice reroll a pick or change a trait; TOMES hold a random trait you can swap
for one of yours; some traits only come when they can work (shield traits need a shield); some
heroes have traits of their own (Super Hero, Esper, Cyborg). Asked (a limit goes against rule 1),
he chose **a limit of 12 different traits**. Our dice (REROLL, ALTER, BANISH, 35.1) already do what
his dice do. The heroes' own traits are Stage 43 (PSYCHIC the Mindwarden's, AUGMENT the Tinkerer's).

### Stage 41.5: how traits work (IPA 41.5, "How Traits Work", built 10 Oct)
- [x] 41.5a At most 12 different traits a run (the expanded game; the run's OATH does not count).
      With 12, a level-up offers only your own traits that can still rank up; when it has fewer
      than three to show, the rest are STAT POINTS (+1 STR, DEX or INT); with all 12 at their top
      rank, a level-up is a stat point. The pick screen and the TRAITS page show how many of 12.
- [x] 41.5b TRAIT TOMES: a book holding one trait (its cube floats over it). Read it: with room,
      learn it; with 12, choose one of yours to give up for it (its effects come off; a one-off
      gift such as armour or a pet already given stays). In chests (sometimes), one in every
      expanded shop, and one in the library room beside the forbidden tome.
- [x] 41.5c Traits that only come when they can work: HOLD THE LINE (a shield's block) only while
      you wear a shield, NO DISTANCE and MUZZLE FLASH only with a bow or gun, SHARP END, BLEEDING
      EDGE and BLUNT FORCE only with a weapon of their kind, NIMBLE GRIP only with a DEX weapon.
      Found on the way: flails, spinning and slamming weapons counted as bows for the Stage 40-41
      traits (Might.ranged); fixed.

### Stage 42: the INTELLIGENCE traits (IPA 42, "Intelligence Traits", built 10 Oct)
- [x] 42.1 What the INT list needs (scripts/combat/arcana.gd): cursed hits, sneaky hits (TRICKERY
      at last), fragility (= vulnerable, from poison), scorch / frostbite / zap (the special's and
      the fields' fire, frost and lightning twice as strong), the element wheel, tick speed (from
      special recharge, lucky hit chance, 10 s after the special), the special's charge as mana
      (power, helpers' damage), lightning that strikes twice, blasts that burn, moons twice as far,
      fields 4 times a second, shards and thistles, a backpack weapon that fires on its own.
- [x] 42.2 The 38 INTELLIGENCE traits, each with its picture. The six that work through the
      special only come to a hero who has one (41.5 conditions).

### Stage 43: SUPER, PSYCHIC and AUGMENT traits (IPA 43, "Super Traits", built 10 Oct)
- [x] 43.1 What they need (scripts/combat/marvels.gd): damage per empty gear slot, a mind link with
      helpers, puppets, faster ticks standing still, knives that speed bleeds, burns that take a
      share of health, more shock a foe can hold, the special's cores (a beam, chill, power,
      lucky hits), more special power each time it is used, a revive every floor, drinks.
- [x] 43.2 15 SUPER traits for every hero (rare); 11 PSYCHIC traits only for the Mindwarden (pink
      squares); 5 AUGMENT cores only for the Tinkerer (steel squares). Each with its picture.

### Stage 43.5: stability test and bug fixes (IPA 43.5; his word, 10 Oct)
- [x] 43.5a The full check (tools/check.sh); long bot soaks with every hero on several seeds, the
      menu monkey, the timing test; every script error, stuck screen or slow fight found is fixed.
      Soak: 53 runs (all 34 heroes, 11 rift worlds, classic, plain drawing, loops 1-3) of 10
      minutes, no error, no leak in 30 minutes (nodes and resources flat). Four runs sat long in
      one room: a level-1 hero started deep (loop 3 floor 10, floor 9, 11, a rift) kills slowly;
      not a bug. Monkey: 16 runs (an hour from the title, 15 of 6 minutes in new content) clean,
      and the trait tome screen and a 12-trait pick under random buttons clean. The full check
      found 2 failures, fixed: the rooms test's keg blast missed a foe the layout had moved (the
      test now places the kegs beside the foe), and two Stage 39 relics were named like older
      weapons (DRAGON EGG is WHELP'S CRADLE, FIREFLY JAR is JAR OF EMBERFLIES).
- [x] 43.5b A note of what was found and fixed, for him (the 43.5 version line).

### Stage 43.7: the old traits made like the new ones (IPA 43.7; his word, 10 Oct)
His words: "revamp all old traits to be like our new traits" and "Also update effects of old traits
to match new", then: "dont update just picture update mechanic to match latest traits soo they
wont feel out of match": the mechanics matter most, so they come first. 286 traits came before
Stage 40 (72 originals, 214 added since) and none has a picture of its own: they show their
family's glyph.
- [x] 43.7a Their effects brought up to the new traits: the new mechanics where they fit (power,
      crushing, lethal, cursed and sneaky hits, fields, the special), numbers that keep up with the
      new traits, so none feels out of place beside them. Nothing weaker than now (rule 1).
      Done: every old trait keeps all it did and gains one more effect and one more sentence
      (scripts/data/trait_revamp.gd), with every rank. A trait with more than one rank got one that
      grows with each rank; an oath's is one line (its vow takes a line of its card). IDLE HANDS,
      BOTTOMLESS PURSE and ELEMENTAL STORM, which do what LAZY GENIUS, ENDLESS WEALTH and WEATHER
      WITCH do, got add-ons the newer ones do not have. tests/revamp_test.tscn.
- [x] 43.7b Every old trait gets its own 16 x 16 picture in its cube (by family, in batches), and
      its text in the new style (short sentences, keywords).
      Done: 286 pictures (tools/art/stage43_7_traits.py, five batches, each looked at and the
      unclear ones redrawn), in the atlas. The text: the added sentence is in the new style; the
      old sentences keep their words (the 72 originals' words are the classic game's).
- [x] 43.7c The 72 originals change in the expanded game only: --classic keeps them exactly as they
      were (rule 4; the classic replays stay identical).
      Done: the six classic replays identical, the effects test ALL MATCH (2424 applications), the
      core replays re-recorded on purpose; the full check passes. IPA 43.7 "Old Traits Reborn".

### Stage 44: INFUSIONS (IPA 44)
- [x] 44.1 14 infusions: belt items that add an element to the weapon for 10 rooms or for good;
      the DEX list's infusion trait (for good) and TIME DILATION work with them.
      Done (scripts/game/infusions.gd): 7 SAPS for 10 rooms (fire, cold, lightning, nature,
      poison, PIXIE SAP that turns into one, BLESSED DEW holy), 4 SPICES and 3 AMBERS for good.
      Every weapon hit deals the element too (it grows with the floor and with all that makes
      hits stronger) and a quarter of the time its ailment; holy hits the cursed and the unholy
      twice as hard. The same again stacks; 5 at once. From bosses and elites, chests and a shop
      stall; shown under the belt. ENDLESS INFUSION (DEX): they never wear off, +25%. SLOW TIME
      stretches them. Every weapon shot now counts as the weapon's own (STR traits' on-hit marks
      work with bows and guns too, as their texts say).

### His word, 10 Oct: weapon enchantments, "Learn from that, we will add this later"
Five pictures of a wiki's "Weapon Enchantments" page: one modifier per weapon, negative, positive,
legendary, special (from certain events and shops) and some that game removed. All transcribed, with
what each becomes here, in **ENCHANTMENTS_PLAN.md**. Our own names when built (rule 3); the removed
ones come in too (rule 1). Planned as Stage 46, after the alignment shops.

### Stage 45: alignment shops (IPA 45)
- [x] 45.1 After a guardian, a GOOD, EVIL or LAWFUL shop can appear (each opens once that path's
      ruler is beaten), selling items that grow with its alignment (his notes, 9 Oct).
      Done (scripts/game/align_shops.gd): THE ALMONER (GOOD, once THE AUREATE JUDGE has fallen),
      THE ASH PEDDLER (EVIL, THE CINDER KING), THE QUARTERMASTER (LAWFUL, THE MARSHAL of the
      DUSTWATER rift, a lawman). 60% after a guardian, one of the open ones (likelier the more of
      its alignment you have); three of its four wares: nine new relics, shop-only (POWER, healing,
      armour, cursed hits, a kill's heal, crit, rolls, all for every point of the alignment) and
      the growing piece of 38.1; prices by your alignment.

### His list, 10 Oct (after IPA 46): core gameplay, combat and equipment
He pasted a list of Tiny Rogues' core gameplay. Most of it is here already (GAMEPLAY_PLAN.md has
each point); the rest, proposed in the order it would be felt most, with names of our own:
- [x] Stage 47: THE GOURD (a refillable healing flask; potions stay) and SHATTER (an armour-break
      ailment for every foe).
  - [x] 47.1 THE GOURD (scripts/game/gourd.gd): HEAL sips it before any potion (2 hearts, only
        with a heart to heal; a sip counts as a potion for what you carry); it fills at the
        floor's rest stop (once a floor) and when a guardian falls; on the HUD before the potions.
        Relics: WAYFARER'S CORK (+1 sip), HONEY STOPPER (+1 heart a sip).
  - [x] 47.2 SHATTER (scripts/combat/shatter.gd): stacks to 5, +5% damage taken a stack, gone 4 s
        after the last; blunt weapons' blows (15%), bombs (2 stacks), SPLITTING WEDGE (15% of
        hits), CRACKED GEODE (twice as strong); shards drawn in a shattered foe.
  - [x] 47.3 The title menu reworked (his word: "it looks all confused and heroes stacked in
        front"): the nine items packed with no room between them, the four heroes standing on
        top of the list, the stats line touching it. Done: the menu in its own panel on the left,
        rows 16 apart; the logo above; the hero you play and two companions by a campfire on the
        right.
  - [x] 47.4 A better hero select: all 34 heroes to see and tap at once, not 6 at a time. Done:
        a grid of two rows along the top (tap to see, tap again to begin), the chosen hero large
        beside its card.
- [x] Stage 48 (his word, 10 Oct): DREAD to 16, star dust, trees expanded and reset, RESET GAME.
      IPA 48 "Dread and Dust".
  - [x] 48.1 DREAD (our own ladder, unlocked one level a win, more dread more embers) grows from 5
        to 16 levels, as his 16 "cinders": levels 1 to 5 keep what they do (rule 1); 6 to 16
        each add one more rule of our own, from his list (a FLAWED starting weapon, short early
        floors and long late ones, packed rooms, blood doors, guardians with escorts, guardians
        and mini-bosses as elites, harder elite modifiers, a hunter that invades fights, plague
        carriers, guardians stronger in their second stage, a weaker start on each guardian).
        Every level also +0.5% health a floor to every foe and guardian (their plates with it).
        Done (scripts/game/dread.gd): 6 FLAWED STEEL, 7 COLD START (slower roll recharge on the
        first three floors), 8 PACKED HALLS, 9 BLOOD TOLL, 10 ESCORTED, 11 TIDE OF ROOMS,
        12 CROWNED, 13 THE HUNTER, 14 FALTERING NERVE (each guardian stage starts at half damage),
        15 PLAGUE, 16 TWICE CROWNED. Classic keeps its five. Test switch --dread=N.
  - [x] 48.2 STAR DUST (his "Mastery / Paragon EXP"): runs earn it (kills, floors, guardians,
        wins), times the DREAD bonus (+30% a level for 1 to 4, +20% for 5 to 8, +10% for 9 to 12,
        +5% for 13 to 16); star points come from it, and the constellation grows past 30.
        Done: a point for every 250 dust, up to 60 points; each of the four spokes 10 stars
        long (was 7) with two new notable stars; the end screen shows the dust a run earned.
  - [x] 48.3 The constellation and the hero skill trees: more to take, and a RESET that gives the
        points back. Done: every branch of every hero's tree has six skills (was four; 100 and
        150 embers); RESET THIS TREE (tap or BOMB, twice) gives every ember back; the
        constellation's RESET is red and plain to see.
  - [x] 48.4 OPTIONS: RESET GAME (asks twice; the save starts over).
  - [x] 48.5 A test for all of it, the replays (classic unchanged), IPA 48. Done:
        tests/stage48_test (in check.sh); classic replays identical; core replays b, d, e and h
        re-recorded on purpose (--unlock-all now learns the fifth and sixth tree skills).
- [x] Stage 49 (his list, 10 Oct; GAMEPLAY_PLAN.md; his "go", 11 Oct): items that grow with curses
      carried and foes slain, ROOM DRAUGHTS, a HONING STONE. IPA 49 "Curses and Draughts".
  - [x] 49.1 Relics that grow with the curses you carry and the foes you have slain this run, beside
        the gold ones. Done (scripts/game/burdens.gd): a curse is a cursed trait, an armory curse, a
        cursed relic or a flawed weapon; 8 relics: BURDENED IDOL, PENITENT'S CHAIN, WIDOW'S VEIL,
        SINNER'S CROWN (a curse itself), TALLY STICK, BONE ROSARY, REAPER'S LAMP, THE HUNDREDFOLD.
  - [x] 49.2 ROOM DRAUGHTS: a strong buff that lasts until the room is clear. Done
        (scripts/game/draughts.gd): six belt drinks, WARCRY (+60% damage), QUICKSILVER (+40% attack
        speed, +15% move speed), EAGLE-EYE (+25% crit, +0.5x crit damage), STORMCALL (+2
        projectiles), GHOSTWALK (rolls twice as fast, +1 charge), BLOODLETTER'S (kills may heal);
        all gone when the room is clear. Guardians and elites drop them; a door promises two.
  - [x] 49.3 A HONING STONE: one use, +1 weapon level. It was already in the belt as the
        WHETSTONE (+1 weapon level, one use), but only guardians and a few elites dropped it: now a
        door can promise one (no second item doing the same).
  - [x] 49.4 A test for all of it, the replays (classic unchanged), IPA 49. Done:
        tests/stage49_test (in check.sh); classic replays identical; core a, b, c, d, e, g, h
        re-recorded on purpose (new relics in the pools, draughts in the drops, new doors).
- [x] Stage 50 (his word, 11 Oct: "Do stage 50 and 52, also we need to ajust traits and oaths to be more
      random and not repeat soo much when picking traits or rerolling them"):
  - [x] 50.1 Picks that do not repeat (expanded game): a reroll shows other traits than the ones it
        throws away; a trait offered and passed over comes up less each time; one not yet shown
        this run a little more; the oath pick avoids the oaths of the last two runs. Done
        (G.vary_cands): with a build going, 12 rerolls showed thrown-away traits 3 times before, 0
        now; 30 picks showed 59 different traits (one 6 times) before, 73 (none over 3) now.
  - [x] 50.2 RADIANT, NECROTIC, DARK, ENERGY and SOUND as weapon damage types, each with its colour,
        its ailment (SEARED, ROT, GLOOM, CHARGED, RATTLED) and new reactions, and 20 weapons that
        deal them (four a type). Done (scripts/combat/damage_types.gd): reactions ECLIPSE, BLIGHT,
        SUPERCONDUCT, CRACKLE, FEEDBACK; tests/stage50_test passes.
  - [x] 50.3 A test for all of it, the replays (classic unchanged), IPA 50. Done with 53.3: one IPA 53
        carries 50, 52 and 53.
- [ ] Stage 51: run modes: THE NARROW WAY (no map), IRON VOW (after 5 wins: one life). (OMENS:
      his 16 cinders became DREAD to 16 in Stage 48.)
- [x] Stage 52 (his word, 11 Oct, with Stage 50): SPIRIT (the special's charge and power) and LUCK as
      attributes next to STR, DEX and INT; each attribute also raises a pool (STR health, DEX roll
      charges, INT and SPIRIT the special). A test, the replays, IPA 52.
      Done: tests/stage52_test passes. Built with Stage 53: one IPA 53 carries 50, 52 and 53.
- [x] Stage 53 (his word, 11 Oct, before IPA 52: "Add new level up traits to pick matching the new
      additions, also add new effects and mechanic make it very cool and satisfying"):
  - [x] 53.1 SOULS (a new mechanic, expanded game): every foe slain lets out its soul, a wisp that
        flies to you and fills the SOUL gauge (an elite 3, a mini or champion 5, a guardian 10); at
        30 it goes off: SOUL SURGE, a ring of light around you (300% of your weapon's damage, foes
        thrown back), a flash and a moment of slow time. New triggers (a soul, a surge, a reroll),
        actions (a new ailment, +SPIRIT, the special ready) and conditions (seared, rotting,
        charged, rattled) for items. Done (scripts/combat/souls.gd).
  - [x] 53.2 New traits for what is new: the five damage types and their ailments, their reactions,
        SPIRIT and LUCK, the toybox, the souls, and an OATH OF SOULS with its vow; each with its
        picture. Done: 28 traits (q_*) and o_souls, pictures from tools/art/stage53_traits.py;
        tests/stage53_test passes (every one taken in a live fight).
  - [x] 53.3 A test, the replays (classic unchanged), the full check, IPA 53 (with 50 and 52). Done:
        the 6 classic replays identical; the 8 core replays re-recorded on purpose (souls, the new
        weapons and traits in the pools); the full check passed after four older tests learned the
        new statuses, attributes and traits (content, stats, stage43, revamp). IPA 53 "Souls".
- [ ] Stage 54 (his word, 11 Oct: "After that make ipa and after that full stability test and bug fixing
      test"): the long bot soaks with every hero (34) on several seeds, the rift worlds, classic and
      the loops; the menu monkey (an hour, and short runs in the new content); every script error,
      stuck screen or slow fight fixed; a note of it for him. Built with Stage 55 (one IPA 55).
  - [x] 54.1 The soak (tools/dev/soak.sh, HEROES=34): all 34 heroes 10 minutes each, the 11 rift
        worlds, classic, plain drawing, loops 1-3: 52 runs, no script error or warning; 30 minutes of
        play: the engine's objects creep up (4534 to 5328) while nodes and resources stay flat, and
        the game's own objects (foes, pickups, shots, rooms) stay bounded (the shot pool grows to
        the most shots ever on screen and is then reused). Same as before (43.5): no leak.
  - [ ] 54.2 The monkey (tools/dev/monkey.sh): an hour, and short runs in the new content (now also
        the new damage types and the four final final bosses); the soak now has the four too.
- [ ] Stage 55 (his word, 11 Oct): after the final boss, the FINAL FINAL BOSS takes the form of the
      alignment you gathered most (GOOD, EVIL, LAWFUL, CHAOTIC), each with three forms. His four, in our
      own names and pictures: a dim but noble DONKEY knight with three super forms (GOOD); a big fat
      REPTILIAN POLITICIAN (LAWFUL); a raving doomsday prophet who calls buff followers that flex at
      you (CHAOTIC; his first idea was a boss built on a real people, which we do not make; named
      PROPHET NIGH, as "Doomsayer" is a card in another game); and a stupid funny one of ours: a fat
      evil CAT overlord who knocks things off tables at you and calls kittens (EVIL). IPA 55.
  - [x] 55.1 THE LAST LAUGH (scripts/entities/finale.gd, FINALE.md): every won run (the Critic, a
        closed book, the walk out after the Eclipse) is not over: something laughs, you are healed
        and taken to its arena; beat it for THE LAST LAUGH (+400 embers); fall to it and the run is
        still won. SIR BRAYSALOT (SUPER, ULTRA HOLY), SENATOR SCALESWORTH (THE MASK SLIPS,
        COLD-BLOODED), PROPHET NIGH (PROVEN RIGHT, THE END), BARON VON CHONK (THE ZOOMIES, NINE
        LIVES): 21 moves of their own, their followers (pony squires, lobbyists, interns, true
        believers who MOG you, kittens), four arenas.
  - [x] 55.2 The pictures (tools/art/stage55_finale.py): 12 boss forms, 5 followers and their
        elites, the thrown things, four arenas' tiles.
  - [ ] 55.3 tests/stage55_test (passes), the full check, the replays (classic and core unchanged:
        the final final boss only comes after a win), IPA 55 "The Last Laugh".

### Stage 46: weapon enchantments (IPA 46; his word: "Ok go 44 and 45, and 46")
- [x] 46.1 An enchantment slot on weapons (one at most): the item card, the name, the name plate,
      saving; flat element damage on hits; foe kinds for the slayer enchantments.
      Done (scripts/game/enchant.gd): w["ench"] on the weapon's own copy; the name starts with it,
      the item card, the equipment page and the swap card say what it does, an enchanted weapon
      glints; its effects come and go with the weapon (Weapons.equip_weapon); a saved run keeps
      it. Element ones hit with the infusions (two new elements: necrotic, dark). Foe kinds:
      wyrms and worms, imps and fiends.
- [x] 46.2 The enchantments of ENCHANTMENTS_PLAN.md (negative, positive, legendary, the four
      removed there), on dropped weapons and at an enchanter in the expanded shops.
      Done: 5 flawed, 19 enchanted, 10 legendary, 4 old lore. A dropped weapon has one 10%
      (common) to 40% (mythic) of the time; THE ENCHANTER (a lectern between the dice cup and the
      weapon) rolls one onto the weapon you hold.
- [x] 46.3 The special ones from their places: a smiths' hideout, a black-market dealer, a dragon
      room with four breaths, a fairy-tale branch.
      Done: THE WYRM'S BREATH (a fourth special room: four stone wyrm heads, one breath a visit,
      one time in five it chars the weapon), THE CHOP SHOP's runesmith, THE PAWN SHOP's back room,
      THE FROG POND's silver branch. Classic: none of it, and its special rooms are the same three.

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
