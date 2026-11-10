# Stage 7: new biomes, foes, mini-bosses and guardians

The six original floors, their foes and guardians are unchanged. Five new
biomes come after them. All names are original; the spec's inspirations are
only moods.

## Run flow

- **Floors 1-6** play exactly as before. Killing **the Pale Regent** is still
  the game's victory: it counts as a win and unlocks the next dread level, and
  a "VICTORY! THE THRONE IS BROKEN" banner shows. A rift (portal) then opens and
  the run goes on.
- **Floors 7-11** are the new biomes. Killing **the Umbral Sun** on floor 11 is
  the true ending.
- **Embers:** a run that dies after the throne still earns the 40-ember
  VICTORY bonus. The true ending adds 80 more ("THE ECLIPSE").
- **`--classic`** (original content only) keeps the original six-floor game.
  Its six recorded runs still match their baselines exactly.

## Every new floor has

- its own tile palette (`kit6`-`kit10`, recoloured copies of the original
  kits) and one of the original music tracks;
- a hazard (below);
- new foes, mixed with a few originals;
- a **mini-boss**. The door choice before the rest stop is always that
  floor's mini-boss room, so you meet one on every new floor. Mini-bosses have
  fixed health (like guardians), a name banner, and a ring burst every few
  seconds on top of their behaviour;
- a **guardian** with its own attack sequence.

| Floor | Biome | Hazard | Foes | Mini-boss | Guardian |
|---|---|---|---|---|---|
| 7 | **Rainmarsh Hamlet** | Mire pools: you move at 60% inside, and they bubble into small spore rings | Bogling (lurks under the mire, surfaces beside you, spits a ring), Gnat swarms, Hexwife (spore spirals), Drowned | **The Mire Hulk** | **The Bog Matriarch**: lobbed bog globs that burst where they land, spore spirals, spore clouds, summons |
| 8 | **Ashen Warfront** | Burning pits that flare, plus **arrow volleys**: a red target marks where you stand, then hits 1 s later | Longbowman (5-arrow volleys), Lancer (cavalry charge), War-priest (fire spirals), Torch imp, Skeleton | **The Iron Captain** | **The Ash Warlord**: charges, slanted **arrow rain** with gaps, fire sweeps, embers, summons |
| 9 | **Frostpeak Monastery** | **Falling icicles**: two targets at a time | Monk (closes in, sidesteps, palm strike = ice ring + fan), Ice archer, Snow lantern (ice rings), Frost wisp, Golem | **The Stone Abbot** | **The Frozen Abbot**: glides beside you and strikes (**palms**), freeze rings, hail, shards, summons monks |
| 10 | **Nightspire Rooftops** | Steam vents that puff scalding rings | Gunman (keeps distance, shows his aim, fires a burst), Cutthroat (vanishes and reappears), Crows, Chimney imp | **The Enforcer** (6-shot bursts) | **The Crow King**: teleports, a rotating **gun crossfire** with aimed triple shots, spirals, beams, summons |
| 11 | **The Eclipse** | Void rifts that spit rings, plus **falling stars** | Voidling, Shade knight, Eclipsed (double spirals), Ghost, Golem, Cutthroat | **The Herald of Dusk** | **The Umbral Sun**: **eclipse** (counter-rotating light and dark spirals with rings), beams, curtains, teleport, sweeps, hail, summons |

Hazards only act while foes are alive, so a cleared room is safe. A roll
dodges a strike like any other hit.

**Art:** every new foe, mini-boss and guardian sprite is a hue-shifted copy
of an original sprite (with matching elite versions). These are placeholders
until real art is drawn.

## How it was built

- **Data:**
  - `GameData.NEW_FLOORS` with `mini`, `hazard` and `music`. `GameData.floors()` lists originals first; `--classic` leaves the new floors out.
  - New entries in `ENEMIES` (with `shot`, `fan`, `burst` and `mini` fields), `BOSSES`, `ENEMY_XP` and `SPRITE_COLOR`.
- **Behaviours** (`enemy_ai.gd`):
  - Original behaviours now read an optional `shot` sprite, defaulting to their original one, so recoloured foes reuse them unchanged.
  - New behaviours: `ambush`, `monk`, `gunman`.
  - Mini-boss extra ring burst.
- **Guardians** (`boss_ai.gd`): new attack sequences built from the original
  attack library. Five new attacks: `bogspit`, `arrowrain`, `palms`,
  `gunline` and `eclipse`. Per-guardian bullet sprites live in `SHOT_SPR`;
  the originals keep theirs.
- **Hazards:** `scripts/world/hazards.gd`. Rooms on original floors hold
  none, so the original game never reaches this code's random draws.
- **Debug:** `--room=mini` jumps to a floor's mini-boss room. For example,
  `--floor=8 --room=mini` gives the Stone Abbot, and `--floor=10 --room=boss`
  gives the Umbral Sun.

## How it was tested

- **Content test, new "biomes" section:**
  - **Data checks:** every floor's tiles, foe and guardian data, sprites (incl. elite versions), bullet sprites, summons and text.
  - **Fights:** each new floor fought for 15 s with its hazard, one of every pool foe and its mini-boss.
  - **Mini-boss room:** the forced door and the spawn are checked.
  - **Guardians:** every one of the 33 guardian attacks is forced and played to completion.
  - **Run flow:** the throne victory (win granted, rift opened) and the true ending are checked.
- **Smoke runs:** autopilot runs on every new floor's combat room, mini-boss room and guardian room had 0 errors.
- **Soaks:** 10-minute runs from each new floor, plus one without god mode, had 0 errors. Autopilot runs beat the Crow King and the Umbral Sun and reached the true ending.
- **Replays:**
  - The `--classic` replays are byte-identical.
  - Full-pool replay f was re-recorded. It used to end at the Pale Regent's victory, and now continues through the rift into the Rainmarsh Hamlet. Everything before the Regent's death is identical.
  - The other five full-pool replays are unchanged.

**Balance:** guardian health (1,200-2,100) and the 60% mire slow are first
guesses; the playtest should decide. Floors 7-11 also inherit the original
per-floor scaling of foe health and speed.
