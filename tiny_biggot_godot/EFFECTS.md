# Ability effects

Every ability effect was redrawn as a pixel effect at the game's own 448x288
resolution and palette. Nothing is smoothed or blurred.

The switch is **OPTIONS > FANCY EFFECTS** (on by default). Off gives the old
particle look. It takes effect at once and changes nothing in play.

## What each one looks like now

| Effect | Before | Now |
|---|---|---|
| Lightning strike (storm procs, STORM!, spark skin, thunder) | a column of 12 dots | A bolt from the sky. A thin leader races down over 2 ticks, the return stroke flashes (white core, cyan edge) with 2-3 forks that fork again, it goes dark for a tick, strikes a second time along a fresh path, then the channel thins and breaks into dashes. Ground flash, sparks, a glow and a scorch mark where it lands |
| Chain lightning, the rune weapons' arcs | dots along a line | A jagged arc per jump, each jump a moment after the last, with the same stroke, re-strike and fade |
| Shocked foes | nothing | Small crackles run around them |
| Explosions (every source: bombs, mines, procs, hero skills, flasks, kills) | a burst of dots | White flash, fireball, cooling, smoke that breaks up. Three sizes by reach (24, 48 and 80 px pictures), sparks, a shock ring and smoke on the big ones, a scorch mark. Five colours: fire, venom (green), gold, frost, void |
| The biggest explosions (reach 52+: Burning Sigil, a guardian's death, a revive) | a burst of dots | A cluster: smaller blasts go off around the first, a beat apart |
| A big explosion centred on the hero (Talon Dive, War Charge, Burning Sigil) | a burst of dots | Only the ring of blasts around the hero, so the hero stays in view in the middle |
| Any fireball that overlaps the hero | a burst of dots | Drawn half see-through, so the hero is never lost inside one |
| Meteor | a diagonal row of dots | A rock streaks down with a flame tail (6 ticks), then the blast |
| Fire on the floor | random dots | 1-5 animated flames by size, on burnt ground, with embers rising |
| Burning foes | a dot now and then | Flames on the foe (the embers are kept) |
| Poison on the floor | three dots | A pool with bubbles that swell and pop |
| Poisoned foes | nothing | Bubbles rising from them |
| Smoke | a glow | Drifting puffs over the glow |
| Chilled foes | a blue tint | The tint plus frost crystals; a frost pop when the chill first lands |
| Shatter | a burst of dots | Ice spikes shoot out and break into shards |
| Frost skin, ice armour | a burst of dots | A ring of frost pops and a shock ring |
| Stunned foes | one flickering dot | Three stars circling the head |
| Cursed, weakened and marked foes | nothing | A small icon over the head: skull, blue arrow, pink crosshair. It blinks as it runs out |
| Healing | a burst of dots | The burst plus small crosses floating up |
| Pull and push (VORTEX!) | a ring | The ring plus motes that spiral in or out |
| Burn, chill, curse or poison first landing (from a skill or proc) | nothing | A small pop in that colour |
| Shadowstep hit, hurting yourself, transmute | a burst of dots | The burst plus a small void or gold pop |

Shots, melee swings and beams, enemy shots and guardian attacks were redrawn in
a second pass: see ATTACK_EFFECTS.md. Not changed: kill bursts, coins, level-up
and room-clear effects.

## It is drawing only

- All of it lives in `scripts/render/vfx.gd` and has its own random stream.
  Nothing in it is read by the rules.
- The rules still make their old particles exactly as before, so the game's own
  random numbers do not move. Where a new effect replaces them (the lightning
  dots, the meteor's row, the stun dot) they are simulated but not drawn
  (`Fx.hide`).
- Enemy shots, your shots and foe health bars are drawn over the effects, so
  an explosion never hides a bullet.
- The meteor's blast is shown 6 ticks (0.1 s) after its damage, when the rock
  lands. Everything else is shown on the tick it happens.

## Cost

Everything is capped: 44 animations, 14 bolts (6 of them crackles), 10 scorch
marks, 16 glows, 40 floor flames, 56 status sprites, 5 new blasts a tick. Past
22 live animations new blasts drop to the middle size, past 34 to the small one.

Measured on desktop in the heavy test fight with every effect firing in turn,
same seed, effects on against off: drawing 0.88-0.91 ms against 0.83-0.94 ms a
frame (the difference is inside the noise; the effects layer itself is about
0.05 ms), logic unchanged at about 0.96 ms, peak draw calls 110 against 108.
Not yet measured on the iPad.

## Hooks (all one line, none uses the game's random numbers)

`Combat.lightning`, `chain_from`, `attack_zap`, `explode_at` (so every
explosion), mines, the shatter kill, the chill on hit, frost skin, ice armour,
the revive, shadowstep, a guardian's death; the `meteor`, `pull`, `push`,
`hurt_self` and `transmute` actions; `Statuses.apply`; `Player.heal`. Fire,
poison and smoke on the floor and the marks over foes are drawn straight from
the game state.

`Vfx.next_col` lets a caller colour the next blast (a flask's is green).

## Debug arguments

    --fx-demo            fires every effect in turn, one every half second
    --fx-only=N          repeats just step N (0 lightning, 1 small blast, 2 chain,
                         3 venom blast, 4 meteor, 5 fire, 6 poison, 7 statuses,
                         8 big blast, 9 pull and heal, 10 cluster on the hero,
                         11 smoke and storm, 12 blasts beside the hero, 13 frost)
    --fx-shift=N         which status each foe gets in step 7
    --fx-keep            heals the foes at every step, so a recording keeps its targets
    --no-vfx             start with FANCY EFFECTS off

## Checks

- `tests/vfx_test.gd` (run by `tools/check.sh`): each hooked piece of the rules is
  run twice from the same state and seed, effects on and off, and must leave the
  same foes, hero, particles and random numbers; hidden particles keep their flag
  through the tidy-up; a flood of every effect stays under the caps; everything
  ends; the lightning channel is pinned to both ends; a new room starts clean;
  every painter draws every moment of every effect.
- `tools/check.sh` also plays 30 s of the heavy fight with `--fx-demo`, and 15 s
  with the effects off.
- All 14 recorded replays are identical to their baselines, which were recorded
  before these effects existed.

Found on the way, not caused by this: with FAST DRAWING on and off the same
frame could differ by a dozen pixels on the edges of the World Eater's rotated
shots (in the old look; in the new one the two match to within a pixel, see
ATTACK_EFFECTS.md).

## Art

`assets/graphics/fx_*.png`, 28 strips. A strip is one row of equal frames; the
frame counts are in `Vfx.FRAMES`. They are in the sprite atlas like every
other small graphic.
