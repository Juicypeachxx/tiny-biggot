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
