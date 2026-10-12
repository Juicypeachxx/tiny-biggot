# Souls-like guardians (his ask, 6 Oct)

"Make boss fights more complex and harder, rewarding after you beat them, multi-stage like
souls-like bosses with a different attack pattern per stage, chaotic and difficult; influence from
Enter the Gungeon, Tiny Rogues, Risk of Rain, Dark Souls." Expanded game only: the original
game's guardians fight exactly as before (classic replays identical).

## Stages (`BossAI.STAGE_PLANS`, `STAGE_LINE`)

Every guardian with a plan in `boss_ai.gd` (the eleven floor guardians, the Aureate Judge, the
Cinder King, the Unwritten, the Holy Cow) has three stages:

- **Stage 1** (full health to two thirds): its old plan.
- **Stage 2** (from two thirds): its own new plan, mixing its moves with new ones; rests a quarter
  shorter.
- **Stage 3** (from one third): chaos. Its own plan again, with a barrage; almost no rest (40% of
  the time the next attack follows at once), and every 3.5 s a desperation pulse (a ring of shots).

A **stage break** (souls-like): the guardian shakes in place and cannot be hurt for 1.6 s, every
shot on screen vanishes, it roars, the banner speaks (e.g. THE BONE COLOSSUS: ITS RIBS CRACK OPEN;
THE UMBRAL SUN: TOTAL ECLIPSE), and it ends with a double shockwave of shots.

New patterns (Gungeon and souls ideas, own code): **wall** (a ring of 30 shots with one gap that
turns wave after wave), **flower** (two sets of arms turning opposite ways), **cross** (lanes that
light up along and across you, then strike), **barrage** (fans, rings and bursts in no order).
Borrowed across guardians: halo, verdict, brimstone, hellgate, ink, eclipse, curtain.

The Holy Cow keeps its rising: after its three stages it rises again with its third plan, still
in stage-3 chaos.

## The reward (`game.gd`, `_boss_reward`)

A guardian falls: a half-second slow-motion hit stop, a white flash, a big shake, "GUARDIAN
FELLED!", a burst of gold sparks, 15 more coins, 4 gems, 2 more embers, and half your health back.
Not touched once in the fight: **FLAWLESS!**, a second boss chest and 3 more gems.

## Tests

`tests/realms_test.tscn` parts 5 and 6: each of the 15 guardians breaks into stage 2 and 3 at
the right health, takes no damage during a break, and uses every attack of each stage; a guardian
felled without a hit leaves two chests, heals and counts the flawless. Soaks: boss rooms on six
floors, 0 errors.

## Every other boss and mini-boss (`scripts/combat/stages.gd`)

His second ask the same day: "apply to all bosses and mini bosses". Expanded game only.

- **Floor mini-bosses, rift minis and rift champions**: stage 2 at two thirds of their health
  (IT GROWS FURIOUS), stage 3 at one third (IT FIGHTS FOR ITS LIFE). Each break: 1.2 s shaking
  and unhurt, every shot vanishes, it comes back 15% faster with a double shockwave. Stage 2: a
  wall of shots with a gap toward you every 6 s, attacks a third sooner. Stage 3: a ring and a fan
  every 3.5 s, attacks much sooner. Rift minis keep their own second move set at half on top.
- **Rift guardians and Rex** already have a second phase at half: below a quarter they break into
  a third stage, the same chaos.

## Their own drops (`scripts/data/boss_loot.gd`)

Every guardian, rift guardian, mini-boss and champion leaves its own legend item when it falls,
named for it and found nowhere else (never in a chest, shop or random drop): 16 weapons (THE
MOLDY LOAF from Rex, the Ash Warlord's warbow, the Marshal's iron, ...) and 21 gear pieces (the
Colossus's ribs, the Cinder King's crown, the cracked bell, ...). The Holy Cow and the Haggler
already had theirs (BRAZIL.md). `tests/bosses_test.tscn` checks the stages, that no break can be
hurt, that each owner drops its item, and that none turn up in 1600 random rolls.

## Stage 56: the guardians fight back (his playthrough, 12 Oct)

His words: "after i make my full build i just melt everything ... the bosses just melts in seconds,
also make bosses be visible when attacking because shear amount of projects just drown him ... make
later bosses harder and have beaffier healthpools and armor and new mechanic also new attack
patterens for all boses". Nothing of the build is toned down: the guardians rise to meet it.
Expanded game only (`--classic` as always). Not Rex (the good boy is as he was).

- **Measured first** (`tests/boss_clock.tscn`, a tool; `--boss-clock` prints each guardian's
  fall): 12 heroes, each with a random full build for the floor, 45 s of its fights, then its
  guardian. Before: the median fight was 30 s on floor 2 and 17 s on floor 10, the fastest 7 and 8 s
  (the later guardians fell faster than the first). After: 42, 53, 69, 72 and 86 s on floors 2, 4,
  6, 8 and 10 (the fastest 32, 45, 61, 69 and 80 s).
- **Seen** (world_view): a guardian is drawn over your shots, effects and sparks (the top layer,
  under the hero), outlined in its colour while it attacks (`_draw_boss`, gold while UNBROKEN); its
  lasers, chains, swings (Chaos, RiftBosses), the final final bosses' throws (Finale) and the new
  patterns are drawn over your shots too (the layer of foe shots, `_paint_foe`).
- **Health and plate** grow with depth (`Resolve.depth()`: the floor, and 11 a loop): health x(1 +
  6% a floor) (`Combat.boss_hp`, +72% at most), the plate 35% + 1.5% a floor of the health, and
  25% - 0.8% a floor of a blow through it (`Armor.plate`, `Armor.through`). The first floor is as it
  was.
- **RESOLVE** (`scripts/combat/resolve.gd`), the new mechanic: a gold bar under the guardian's health
  (HudView). Health it loses fills it, and it empties by itself. A blow takes at most what is left of
  it; full: UNBROKEN for 3.5 s (a golden shell, no blow hurts it nor its plate, a grey UNBROKEN now
  and then), and it answers with its signature (the first of its new patterns, at most every 7 s).
  Its size is 3.5 s / t_min, and t_min = 25 s + 6 s a floor (120 s at most): no build fells it
  faster. It empties at 80% of that pace, so a build that needs 1.25 t_min or longer never meets it.
  A billion a tick: 79 s on floor 10 (4.8 s without it). `Resolve.off`: tests of what came before.
- **Six new patterns** (`scripts/combat/patterns.gd`), each warned before it hurts: PINWHEEL (arms
  of shots that turn; hard: five, and they turn back), CAGE (a ring of marks round you with a gap,
  then it fires inward; hard: a second ring), ORBIT (orbs circle the guardian, widen and shoot;
  touching one hurts), COMETS (they turn after you, then burst in a ring), GRID (half the floor in
  great squares lights up and blasts, then the other half; hard: a third wave), QUAKE (shock rings
  run out along the floor, each with a gap). Every guardian has two or three of its own
  (`Patterns.NEW`): all of them in its stages 2 and 3 (and a risen third), its signature in stage 1
  from the fourth floor on (`Patterns.plan`, spread through its plan). A rift guardian adds one of
  its own every 9 s (Resolve.tick). Hard: stage 2 on, at half health, or six floors down.
- **Tests**: `tests/stage56_test.tscn` (in check.sh): the depth numbers, RESOLVE (a billion takes its
  share; UNBROKEN takes nothing; it ends; a slow build never meets it; Rex), the broken build on
  floor 10, every guardian's plans, a rift guardian's own, every pattern (plain and hard) plays out,
  hurts a hero standing in it and ends, the room clears them, they draw; `--classic`: none of it.
  The bosses, chaos, realms and Last Laugh tests set `Resolve.off`; realms checks every move of the
  new plans in real fights.
