# Step 9: loops, balance pass and final stability

## Loop playthroughs (new)

When **the Umbral Sun** (floor 11) falls, two portals appear instead of the
run ending at once:

- **LOOP:** back to floor 1 with your whole build (level, relics, traits,
  gear, weapon). The loop counter goes up by one.
- **EXIT:** end the run in victory and claim the embers.

Each loop makes foes, mini-bosses and guardians **+80% health** (loop 2 is
x1.8, loop 3 is x2.6), gives enemy shots **+6% speed** and adds more elites.
A run pays **60 embers per loop** on top of everything else. The Pale
Regent's victory (wins and dread unlock) is counted once per run, not once
per loop.

The HUD and floor banners show the loop ("1/11 LOOP 2"). The title screen
shows your best loop.

Testing helpers:
- `--loop=N` starts on loop N.
- `--ui=ending` opens the true-ending room with both portals.

The original six-floor game (`--classic`) is unchanged.

## Balance pass (measured, new content only)

Section 0 of the spec keeps original content as it is, so only new items
and heroes were tuned.

- **Weapons:** `tests/balance_report.tscn` compares every new weapon's base
  damage per second with the median original weapon of the same type and
  rarity.
  - **Seven high outliers fixed.** All were multi-shot weapons, now within
    1.6x: Pact Knives, Widow Needles, Scatter Wand, Lucky Deck, Juggler's
    Pins, Throwing Knives, Deadfall Traps.
  - **Low flags left alone.** These are spears measured against a single
    unusually strong original rare spear (their common reference is fine),
    and one epic whose overcrit effect isn't counted in base damage.
- **Heroes:** all 13 heroes ran on the same 3 seeds with full skill trees and
  no god mode, measured by the deepest floor reached.

  | Originals | Avg floor | New | Avg floor |
  |---|---|---|---|
  | Hexer | 3.7 | Bane Hunter | 2.7 (sabre buffed to 8 dmg, 2.6/s) |
  | Poacher | 4.7 | Oathbreaker | 3.7 |
  | Brute | 3.3 | Wayfarer | 3.3 |
  | Gravedigger | 3.7 | Racketeer | 4.7 |
  | Alchemist | 3.0* | Condemned | 3.7 |
  | Warden | 4.0 | Cartomancer | 4.7 |
  | | | Sellsword | 4.0 |

  No new hero outclasses the originals. *The autopilot sometimes gets stuck
  in a room with the Alchemist; that is a bot limit, not the hero. Three
  seeds is noisy, so the playtest should have the final word.
- **Guardian health** rises evenly across all 11 floors (420 to 2,100). Foe
  health also scales by floor (up to x5.2 on floor 11).

## Final stability tests

- **Full check:** import, compile, unit tests, Ruby comparison (2,424
  items), content test, autopilot run and 12 replays all pass.
- **Content test:** covers 908 items, heroes, specials, slots, biomes, loops
  and rails.
- **Save compatibility:** an old-format save (from before heroes, slots,
  biomes and loops) loads and plays with an original hero and a new hero,
  and saves back with its progress, tree, unlocks and options kept.
- **Performance:** with about 1,500 enemy shots, game logic takes 2.6 ms per
  tick on floor 1 and on the Eclipse (floor 11). The budget is 16.7 ms.
- **20-minute soaks:**
  - A full run with god mode.
  - A loop-3 run on the last floors, which reached the ending and won.
  - A run without god mode, which reached floor 8 at level 25 with no deaths.
  - All three had 0 errors and no leak warnings.

## Known limits

- **iPad:** nothing has been tested on a real iPad yet (touch feel,
  Magic Keyboard in Xogot, rendering speed on the device). Headless timing
  covers game logic only.
- **Art:** new heroes, foes, guardians, tiles and items use recoloured or
  reused sprites as placeholders.
- **Timing test:** the content test's "broken build" timing check (normally
  13-14 ms against 16.7 ms) can fail if another heavy process runs at the
  same time. Run `tools/check.sh` on its own.
- **Content totals:** 224 weapons, 194 equipment pieces, 167 relics and 132
  traits. More weapons, armor and traits come after the game is finished, as
  agreed.
