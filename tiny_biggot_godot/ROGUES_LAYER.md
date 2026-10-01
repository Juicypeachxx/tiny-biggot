# Rogues layer: feel, mechanics and look

On for the whole game. `--classic` turns it off and keeps the original game
unchanged; the classic replays still match byte for byte.

| Phase | What it adds |
|---|---|
| A | **Attributes** STR / DEX / INT. Each weapon has a grade per attribute (S..E or -), from its type and tags. Every point adds 3% x the grade weight to damage. Heroes start with their own spread, and trait ranks train their family's attribute. There are also attribute relics |
| B | **Item cards**: name +N, type, range, scaling, damage range and type, speed. Hits roll 85-115%. **Anvils** in rest rooms and shops upgrade your weapon (+8% each, up to +25). The level stays with the weapon if you drop it |
| C | **Inventory** (GEAR in pause): replaced items go to a 6-slot backpack, and you can equip them back from it. A 4-slot **quick belt** (keys 1-4, or tap) holds Fury, Smoke, Whetstone and Insight consumables, dropped by elites and bosses |
| D | **HUD**: armor shields, a floor timer and darker, crisper panels. Name plates over nearby items. **Training dummies**: two in every start room, never in mob rooms. They are only for testing damage and showing off skills: they show DPS, never die, don't lock doors and give no gold, heals or procs. Hurt foes show a ghost health bar |
| E | **Themed weapon effects** (visual only, own random numbers): a weapon's first tag picks a theme (fire embers rise, frost flakes drift, venom and blood drip, storm crackles, shadow wisps, arcane and gold twinkles). Themes show on shot trails, along melee swings and as hit sparks. Legendary weapons glow and shed their theme |

## Performance pass (lag in heavy late-run fights)

The iPad recording showed lag in big fights with a level 30+ build. A
profile of the same kind of build (`tests/heavy_profile.tscn`: 40 relics,
40 trait ranks, a legendary weapon, an endless fight) found:

| Cause | Fix | Result |
|---|---|---|
| Homing shots looked for the nearest foe every tick, and each search made a new empty Dictionary | No allocation, squared distances, a packed foe-position cache per tick | Shot update 10.9 -> 4.6 ms |
| Shot x foe hit tests read object properties | A cheap reject first, using the cached positions | |
| Gold-on-hit builds piled up thousands of coins, each tested against walls every tick and drawn every frame | Past 60 pickups on the floor, new coins and gems go straight to your gold (same value, a small sparkle). Resting pickups skip the wall test | Pickups 6.1 -> 1.1 ms |
| Up to 1000 live player shots | Rogues cap of 300; extra shots fold their damage into live ones, so DPS is kept | Fewer shots to move and draw |
| Slow frames ran up to 4 catch-up ticks, which made the next frame slower too | `max_physics_steps_per_frame = 1`: a slow frame slows the game slightly instead of hitching | No spiral |
| Weapon effect trails on crowded screens | Trail chance scales down with shot count | |

Logic per tick in that profile went from 20 ms to 8 ms. The content
test's broken build went from about 14 ms to 3.3 ms. All replays are still
identical. New content test: "heavy fight".

**Testing on device:** `--heavy` starts a run with that build, and
`--perf` prints fps, logic ms and per-layer drawing ms every 5 seconds.
