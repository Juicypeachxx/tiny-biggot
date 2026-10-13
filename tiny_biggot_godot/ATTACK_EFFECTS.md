# Attack effects

The second effects pass: your shots, melee swings and beams, enemy shots, and
the guardians' attacks. Like the ability effects (EFFECTS.md) it is pixel art at
the game's own resolution, drawing only, and under the same switch:
**OPTIONS > FANCY EFFECTS**. Off gives every old picture back, with one
difference nobody will see: where two enemy shots overlap, which one is on top
can differ from before (they are now drawn in the order they were fired, in
one pass, instead of grouped by kind).

The look borrows ideas, not art, from three games: bold blade smears and cut
marks (Dead Cells), attacks you can read before they land, with lanes and
rings that fill (League of Legends), and glowing orbs and casting circles
(Aion).

## What changed

| | Before | Now |
|---|---|---|
| Staff orbs | a purple ball for every staff | An orb with a wake that points where it flies, two motes circling it, a four-frame sparkle, in the weapon family's colour, with a glow of the same colour |
| Bolts (bow, burst gun, gatling) | one brown bolt | A bolt with a bright head and a streaked wake, in the family's colour |
| Scattergun | brown clods | Pellets with a short streak; plain ones are dirt |
| Chime, sparks | a cyan ball | A star that twinkles between a plus and a cross |
| Flame sprayer | an orange ball | A flame whose tongues change every frame, in the family's colour |
| Flask | a green ball | A spinning bottle with the family's liquid |
| Orb (pulse) | a ball | A sphere with a turning three-armed swirl |
| Railshot | a white bar | A lance of light with a streaked tail |
| Thrown weapons, discs, boomerangs | the weapon spinning | The same, with a whirl of two blurred arcs under it |
| Shatter shards, darts | reused balls | An icicle; a thorn |
| A shot landing | three dots | The dots plus a small star in the family's colour |
| A critical hit | a gold number | The number plus a gold starburst |
| Firing a gun, bow or staff | recoil | The recoil plus a muzzle flash |
| Sword swing | a grey crescent, tinted | A smear: a thin leading arc, then a crescent that tapers at both ends with a white-hot outer rim, then wisps. Brighter than the family colour so it stands off the floor. Swings alternate direction. A soft bloom on the first frames |
| Spear thrust | a bar | A spearhead of light with a white core and a flare at the point |
| Whip | a bar | A lash whose wave runs out to the tip, and a crack at the tip |
| Ray | two bars | A dark sheath, the colour, a white core, pulses of light running along it, a flare at both ends, and it breathes a pixel wider and narrower |
| A blade landing | nothing | A white cut mark across the foe, turned to the blow |
| Enemy shots (all 13 kinds) | still balls | Four-frame animations: red orbs that throb, bones that spin, water with a turning highlight, ice crystals that turn, spores with moving spikes, void rings round a dark eye, fireballs with flickering crowns, lightning orbs, pages that tumble |
| A volley leaving a foe | nothing | A ring flash in the shots' colour |
| Charge wind-up (guardians, knights, champions) | a dotted line | A lane on the floor as wide as the runner, to the wall it will hit, that fills as the wind-up ends, with chevrons marching along it |
| The charge itself | dust dots | Three afterimages behind the runner; dust where it crashes |
| Marksman's aim | a dotted line | A thin line of sight that steadies and brightens, with a dot where it ends |
| Guardian slam, palm strike | nothing until it lands | A ring on the floor where it will land that fills as it comes; dust when it does |
| Guardian beams | a thin line, then two bars | They gather: a faint band where each will fire, a line that thickens, motes drawn in to the guardian. They fire: the full ray picture, drawn as wide as what it hits |
| Guardian casting (rings, spirals, sweeps, walls of shots, summons) | nothing | A circle under it in its own colour: two rings and marks that turn |
| Guardian blink | a burst of dots | A void burst where it leaves and where it arrives |

Not changed: hit boxes, damage, speeds, timings. A guardian beam is now drawn
14 px wide, which is the width that has always hurt (it used to be drawn 10).
Enemy shots are the same size as before.

## Cost, measured

Desktop, same seed, the previous build against this one, the two run in turn
(three to six runs each; the ranges are what the runs gave). Xogot runs scripts
about 4.5 times slower than this desktop; an exported build is faster than Xogot.

| | Before | Now |
|---|---|---|
| Drawing 1500 enemy shots | 1.38-1.45 ms | 0.32-0.36 ms |
| Whole frame's drawing, 1500 enemy shots on screen | 2.54-2.61 ms | 1.31-1.39 ms |
| Sorting 300 mixed shots for the batch | 0.18-0.20 ms, 84 of them left for the slow painter (about 0.31 ms more) | 0.28-0.30 ms, none left |
| The same for 300 shots of one kind | 0.21 ms | 0.22-0.24 ms |
| 300 shots with FAST DRAWING off | 1.09-1.11 ms | 0.97-1.02 ms |
| Whole frame's drawing, heavy fight | 0.68-0.75 ms | 0.72-0.76 ms (one run of six gave 0.86) |
| Whole frame's drawing, guardian fight | 0.33 ms | 0.35 ms |
| Whole frame's drawing, melee fight | 0.33-0.42 ms | 0.35-0.41 ms |
| Bookkeeping each tick (ageing the flashes, finding the foes that show a mark) | none | 0.006 ms with 12 foes, 0.017 ms with 40 |
| Logic per tick, heavy fight (includes the line above) | 0.59-0.74 ms | 0.63-0.78 ms (the same within the noise between runs) |
| Sprite atlas | 1024x2048 | 1024x2048 |

So ordinary fights draw about 0.02-0.06 ms a frame more, and the worst case
the game has (a guardian filling the room with shots) draws over 1 ms less.
Not yet measured on the iPad.

How it stays cheap:

- Enemy shots: still one sprite each, in one pass. The old painter walked the
  whole list once per kind of sprite.
- Your shots: still one instanced draw for all of them. Animation is one clock
  handed to the shader once a frame, so it costs nothing per shot. Every kind
  now has a rule, so none are left for the slow painter. Whirls are one more
  instance each, at most 64 a frame.
- The flashes (hit stars, crits, cut marks, muzzle and casting flashes, dust)
  live in 28 slots; at most 6 start in one tick.
- Wind-up marks and guardian visuals are drawn from the game state, a few
  rectangles each. The foes that need one are found in one pass a tick.
- Swings and beams are two to ten draws each, and there are only a few.

## For the Xcode build

- No new shader. The one shader in the game (the shot batch, which has been
  there since the speed pass) gained a few lines: the animation clock.
  FAST DRAWING off draws every shot without it.
- Everything else is plain sprites, rectangles and lines.
- Checked here, on this final code: the same seeded fight was recorded three
  ways (from the project, from a Linux release export, and from the iOS
  preset's resource pack run with a desktop player) and compared frame by
  frame. Nine fights (three guardians, the heavy fight with every ability
  effect, two melee fights, a new weapon every second, one with FAST DRAWING
  off, one with FANCY EFFECTS off), 4,830 frames: no pixel differs and no error
  is logged. The iOS pack holds all 36 new graphics and the new script. It also
  ran the guardian fights, the weapon soak and a normal run without drawing,
  with no errors.
- What this cannot show is the iPad's own graphics driver, or the Xcode build
  itself (there is no Mac here). IPAD_CHECKLIST.md has what to look at.

## How it is built

- `scripts/render/afx.gd` (new): swings, beams, flashes, wind-up marks,
  guardian visuals. Its own random stream.
- `scripts/render/shot_batch.gd`: the shot sheets, families, rules ("specs").
  The plain painter in `world_view.gd` draws from the same rule as the shader,
  and rounds a shot's velocity, spin, size and life to 16-bit floats as the
  engine does on the way to the shader, so FAST DRAWING on and off give the same
  picture, as near as two ways of turning a sprite can. Compared frame by frame
  in eight fights (a staff, a crossbow, thrown and juggled axes, the Last Star,
  the heavy build, a hammer, a guardian; 340 to 440 frames each): no frame
  differs by a pixel. In a ninth, with a new weapon every second, 6 of 840
  frames differ, each by one pixel inside a turned staff orb (the graphics card
  and the script each work out the angle, and now and then they round a pixel
  differently).
- The class tables hold 64 rows. A long run meets more shot classes than that,
  though never many at once, so when they fill they are emptied at the start of
  the next tick and the classes in use take their places again
  (`ShotBatch.try_reset`), at most once every 10 seconds.
- Which way a swing's smear goes alternates from swing to swing; it is decided
  the tick the swing appears and kept with the swing itself (not with its place
  in the game's list, which shifts when an older swing ends), so a swing frozen
  by a hit does not flicker and neither do two swings alive at once.
- `scripts/combat/ebullets.gd`: the new enemy-shot painter.
- Hooks in the rules, one line each, none using the game's random numbers:
  a shot landing, a blade landing (slash and thrust), a crit, `ering` and
  `efan`, the guardians' slam, crash, palm strike and blink, a knight's crash.
- Shots carry two more drawing-only fields (`ds`, `dw`), set when they are
  first drawn, like `dk`.

## Art

`assets/graphics/shot_*.png` (12), `eb_*.png` (13), `swing_*.png` (4) and seven
more `fx_*.png`. A shot sheet holds 17 colour families, eight to a row, each a
run of frames: the 15 weapon families, `none` and `earth`. A weapon with no
family uses a plain one chosen per kind (`ShotBatch.PLAIN_TAG`): purple staff
orbs, bone-coloured bolts, dirt pellets.

## Debug arguments

    --attack-every=N     the hero attacks every N ticks, whatever the range
    --boss-log           prints the guardian's attack each time it changes
    --perf-all           with --perf: every painter, not just the top six

`tests/draw_bench.tscn` times the shot and enemy-shot painters with a fixed
crowd (`--only=bolt` for one kind).

## Checks

- `tests/afx_test.gd` (run by `tools/check.sh`): every sheet divides into whole
  frames and every weapon family has its run; every shot kind has a rule and
  the shader's tables hold exactly what the rule says; the old look is
  untouched; full class tables are emptied and refilled, once, without
  thrashing, and nothing is left pointing at a row that is gone; with the
  tables full a spinning weapon still gets its whirl; 900 spinning shots never
  write past the batch buffer; a lane ends at the wall's face; swings alternate,
  and one keeps its direction while a hit freezes it, when an older swing ends
  and when new ones begin; each hooked piece of the rules (four weapons' attacks, a shot landing, a crit, enemy
  volleys, six guardian attacks, a knight's crash) run twice from the same
  state, effects on and off, leaves the same foes, hero, shots, particles and
  random numbers; the flashes stay inside their slots and all end; every
  painter draws every swing, mark, guardian state and shot in both looks, with
  FAST DRAWING on and off.
- `tools/check.sh` also plays three guardian fights for 20 s each, and 100 s
  with a new weapon every second (which fills the class tables several times).
- All 14 recorded replays are identical to their baselines.
- 22 more seeded fights played by the test bot (every hero, six guardians, the
  heavy fight, a new weapon every second) were run in the previous build and
  in this one with a line of game state written every second (`--trace`): the
  files are identical byte for byte, so the rules and the game's random
  numbers have not moved.
- A second pair of eyes went over the change and ran its own soaks (all 14
  heroes, 11 guardians through every attack, 8 champions, both options toggled
  every tick, no atlas, classic mode). It found seven things; six are fixed
  (an error on the tick the class tables were emptied, smears flickering while
  a hit froze them, the two painters differing by a pixel on turned shots,
  whirls missing without a table row, afterimages on a stunned charger, lanes
  running into walls) and one is the enemy-shot order noted at the top.
- The same soaks were then run again on the finished build, from the zip as it
  ships: no errors. Going over the fixes once more turned up an eighth thing:
  with two swings alive at once, the newer one could be drawn mirrored for one
  frame when the older one ended. Fixed, and the test now covers it.
