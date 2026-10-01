# Step 6: new heroes and skill trees

Seven new heroes join the six originals. The originals keep their place
(indices 0-5), stats, weapons and trees exactly as before. All names, text
and lore are original; the design spec's inspirations are only playstyle
moods.

Each new hero has:
- a signature weapon (never in loot pools, like the original hero weapons);
- a unique passive, written as effect-system data;
- a starting trait at rank 1;
- a skill tree. As for every hero, that is the shared MIGHT and SURVIVAL
  branches (helpful perks) plus the hero's own special branch, ending in a
  capstone.

Heroes unlock at the Ember Shrine, like the Gravedigger, Alchemist and Warden.

**Art:** each new hero is a palette-swapped copy of an original hero sprite.
These are placeholders until real art is drawn.

| Hero | Unlock | Weapon | Passive | Starting trait |
|---|---|---|---|---|
| **The Bane Hunter** (from the Poacher sprite) | 160 | Bane Sabre (sword) | +25% damage to elites. A potion also oils the blade: +40% damage for 10 s. Every 6 s a roll casts a sign: a ring of sparks that stuns the nearest foe | Bounty Hunter |
| **The Oathbreaker** (Brute) | 200 | Iron Slab (huge, slow, wide sword) | Rage: every kill gives +6% damage for 5 s, stacking. Below half health: +30% damage, +20% fire rate | Short Temper |
| **The Wayfarer** (Alchemist) | 180 | Wayfarer's Edge (quick sword, cuts shots) | +10% crit. Perfect dodge: rolling while a shot is close refunds the roll and gives +60% damage for 1.5 s | Precise Footwork |
| **The Racketeer** (Poacher) | 220 | Snub Guns (two-shot bursts) | +10% gold. Heat: each cleared room +1 (max 5), each level +8% damage and +10% gold; getting hit loses 2. Heat meter on the HUD | Skimming |
| **The Condemned** (Gravedigger) | 240 | Shackle Flail (whip) | Rises once per run. Reads a random scroll every floor (+6% damage, +6% rate, +1 heart or +4% crit). Swapping weapons: +50% damage for 8 s | Thick Skull |
| **The Cartomancer** (Hexer) | 260 | Gilt Deck (three bouncing cards) | In a fight, draws a card every 4 s and plays it: Blades, Storm, Shield, Mend, Star, Wheel or Coin | Salvo |
| **The Sellsword** (Warden) | 120 | War Lance (long spear) | Charge: faster rolls that trample foes for 250%. +1 roll charge, starts with 1 armor | Brace |

## Special branches (node costs 10 / 20 / 35 / 60 embers, as for all heroes)

| Hero | Branch | 1 | 2 | 3 | Capstone |
|---|---|---|---|---|---|
| Bane Hunter | MONSTER LORE | +20% more damage to elites | +1 potion slot and a full potion | Signs also erase shots | Elite kills heal half a heart, +30% damage for 20 s |
| Oathbreaker | IRON OATH | +25% swing size | Taking a hit: +40% damage for 4 s | +1 armor after each room | Every 4th swing: shockwave for 150% |
| Wayfarer | WAY OF THE BLADE | Crits +0.3x | Perfect dodge strikes the nearest foe for 300% | +1 roll charge | Perfect dodge erases shots and doubles crit chance for 2 s |
| Racketeer | THE RACKET | Room clears pay 3 gold | At 3+ heat, kills fire a ring of 6 shots | Hits only lose 1 heat | Heat can rise to 8 |
| Condemned | ESCAPE ARTIST | A second scroll every floor | Weapon swap refunds a roll and heals half a heart (every 20 s) | +1 max heart | Rise one more time |
| Cartomancer | THE ARCANA | Extra card every 10 s in a fight | Cards pierce +1 | Room clears draw a card | Every card plays twice |
| Sellsword | FREE COMPANY | Rolls recharge 20% faster | When hit, erase nearby shots (every 6 s) | Elite kills pay 12 gold | Charges hit twice as hard; kills refund the roll |

## What was added to the engine

These are extensions of the existing effect system. The originals never use
them, so they still take the same code paths:
- **Triggers:**
  - `on_potion`: drinking a potion.
  - `on_weapon_swap`: a weapon replaced by another.
  - `on_floor_start`: entering a new floor.
- **Conditions:**
  - `danger`: an enemy shot within 30 px, used for the perfect dodge.
  - `fighting`: foes are active.
  - `hot`: heat 3 or more.
- **Actions:**
  - `card`: play a random card.
  - `heat`: raise or lower heat.
  - `scroll`: a random small permanent boost.
- **Player stats:** `heat` and `heat_max`.
- **Hero data:** `GameData.NEW_HEROES`, with `passive`, `effects`, `trait` and
  `new` fields. `GameData.heroes()` and `GameData.unlocks()` list the
  originals first, then the new heroes. `--classic` leaves the new heroes out.
- **Hero select:** shows six heroes at a time and scrolls (arrows, `n / 13`).
  New heroes are tagged NEW, and their passive and starting trait are shown.
  Taps work on panels and on the scroll arrows.

## How it was tested

- **Content test, new "heroes" section:**
  - Every hero has a unique id, a sprite, a signature weapon and a tree branch, and every node has effects.
  - All text fits the font.
  - New heroes' effects pass the lint, and each has a starting trait and a shrine unlock.
  - Each new hero played 10 s with its whole tree learned (worst 0.33 ms/tick).
- **Mechanics checked directly:**
  - Heat: x1.4 damage and x1.5 gold at 5, back to exactly x1 after hits.
  - Scrolls change a stat.
  - A weapon swap gives the damage buff.
  - The perfect dodge refunds only when a shot is close.
  - The potion oil buff is applied.
  - Card draws reach the COIN card.
  - A planted wrong heat value and a removed card were both caught, so the checks can fail.
- **Soak:** a 5-minute autopilot run per new hero (no god mode), 0 errors.
- **Originals unchanged:** the `--classic` replays still match byte for byte.
  The full-pool replays also still match, because signature weapons never
  drop and the new triggers draw no random numbers.

**Balance note:** the first soak showed the Racketeer with a fully learned tree
reaching ~2,900 gold by floor 5. Its gold was lowered (+10% base and +10% per
heat level, from +20% and +15%). Hero balance is a playtest call.
