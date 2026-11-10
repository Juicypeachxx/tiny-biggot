# The Gaolbird (starter hero)

A fourth free hero. It costs nothing and is never sold at the Ember Shrine. The
hero and skill-tree screens now show the free heroes first, so it is the fourth
panel, next to the Hexer, Poacher and Brute. (In the data it is hero 6, right
after the six originals, whose indices are unchanged; the seven shrine heroes moved
from 6-12 to 7-13.) `--classic` leaves it out, like every new hero.

An escapee from Blackrock Gaol in a crow mask. Original character, name and art;
the mood it is after is a fast, aggressive escape-the-prison action game: never
stand still, roll through everything, hit back at once.

| | |
|---|---|
| Health, speed | 3 hearts, 94 (fast) |
| Weapon | IRON TALONS: quick melee, 3.6 damage, 3.6 strikes a second, +5% crit. Every 3rd strike is a spinning finisher: 150% to every foe around you |
| Starting trait | BLUR (after a roll, +20% damage for 1 s) |
| Special | TALON DIVE, 7 s |

## Tempo (the HUD meter next to the level)

- Every 5 blows landed and every kill is +1 tempo (elite +2, guardian +3), up to 10.
- A blow is a hit by your weapon itself: a swing, or one of its own shots (and the
  pieces they split into). Wisps and bonus shots from traits and relics do not count.
  Blows on training dummies do not count either.
- A kill counts however the foe dies.
- Each point: +2.5% move speed and +4% fire rate. At 10 that is +25% and +40%.
- At 10 you are IN FULL FLIGHT: +20% crit, and rolls cut through foes for 250%.
- Stop landing blows for 3 s and it fades, one point every 0.7 s.
- A hit halves it (rounded down), armour or not.
- From 6 tempo the hero leaves pink afterimages; in full flight it glows and the
  meter turns white.

Tempo works with any weapon you pick up.

## Rally

- A hit that costs health puts that health at stake for 3 s: a gold heart over
  the hero, six pips and a timer, and the lost heart pulses gold on the HUD.
- Land 6 blows in that time (a kill counts as 3) and the heart comes back.
- Run out of time, or take another hit first, and it is gone.
- Rally then rests: 8 s after a win, 4 s after a loss.
- Armour hits put nothing at stake. Healing to full ends a rally quietly.

## Rolls

- Rolling through a foe exposes it (+25% damage taken for 3 s, a pink chevron
  over it) and makes your next strike a crit.
- In full flight the roll also cuts the foe for 250%.

## Talon Dive

Leap up and crash down on the foe you are aiming at, if one is within 150 px
(the one nearest your aim); otherwise 90 px the way you move or aim.

- 300% to everything within 46 px of the landing; foes within 52 px are stunned for
  1 s (guardians a quarter of a second) and exposed; enemy shots within 52 px are
  erased; +2 tempo.
- Untouchable in the air and for 0.4 s after landing. The leap clears pillars and
  crates, never leaves the room and never lands inside a wall.
- On a guardian or any big foe the hero comes down at its feet, not inside it.
- A dive out of a roll ends the roll.

## JAILBREAK branch (10 / 20 / 35 / 60 embers)

| Node | Effect |
|---|---|
| KEEP TIME | Tempo holds 2 s longer before it fades |
| OLD GRUDGE | Rally lasts 1.5 s longer and returns 3 s sooner |
| HOLLOW BONES | +1 roll charge. Kills in full flight refund a roll |
| MURDER OF CROWS | Kills in full flight fire a ring of 8 feathers (60% each). A hit costs at most 2 tempo |

In Blackrock Gaol (the rift world) the gaol greets its runaway.

## What was added to the engine

- `scripts/combat/tempo.gd` and `rally.gd`: the two mechanics. A hero has them when
  `tempo_max` or `rally_n` is above zero; every other hero skips the code entirely.
  Tempo's bonuses are ordinary additive-% stat effects, applied and taken back as
  the level changes (the way the Racketeer's heat works).
- Actions: `["tempo", n]` and `["leap", speed, reach, [landing actions]]`.
- Condition: `flight` (the hero is at full tempo).
- Hooks: `roll_expose`, `flight`, `tempo_hold`, `tempo_grit`, `rally_window`, `rally_haste`.
- Visual effect: `["vfx", "slam", colour, radius]`.
- Shot kind `feather` (sprite `feather.png`, drawn along its heading).
- Shots carry an `own` mark when the hero's weapon itself fired them (set only for
  a hero with tempo or rally).
- A hero with `"cost": 0` in `NEW_HEROES` is a starter and gets no shrine entry.
- A pink chevron now marks any exposed (vulnerable) foe, whatever exposed it.
- Hero screen: the info panel is 8 px taller and the dread lines sit below it, so
  a three-line passive plus a skill no longer runs into them. Free heroes come
  first (`GameData.hero_order()`), on the title row and the skill-tree screen too.

## Two drawing bugs fixed on the way

- Every sprite drawn mirrored (anything facing left: the hero, foes, the hero row
  on the title screen, gear on the hero) was drawn one sprite-width too far to the
  right, so left-facing heroes and foes stood beside their own shadow and health
  bar instead of on them. `Gfx.sprite` and `HeroGear.draw` now flip in place.
- The weapon in the hero's hand turned the wrong way when aiming left and up or
  down (aimed up-left it pointed down-left). It is now the mirror image of aiming
  right.

Logic is untouched by both: only where things are painted changed, and every
recorded replay is still identical.

## Debug arguments

    --hero=6             the Gaolbird
    --tempo=N            start with N tempo that does not fade for a while
    --hurt-at=TICK       land one hit on the hero at that tick

## Tests

`tests/gaolbird_test.gd` (run by `tools/check.sh`): starter status and hero-screen
order, tempo numbers and that they come off exactly, which hits count, fading,
hits, armour and god mode, rally in every outcome, rolls, the dive (over a pillar,
at walls and doors, from a doorway, at a guardian, out of a roll, across a room
change), the finisher, each branch node, death and cheating death, 30 s of play
with the whole tree, and walking the hero screen. `tools/check.sh` also runs the
hero on screen for 30 s so every painter is exercised, and `tools/replay.sh` has
two recorded Gaolbird runs (`tests/replays/g.txt`, `h.txt`).

Balance is a first pass and has only been played by the bot.
