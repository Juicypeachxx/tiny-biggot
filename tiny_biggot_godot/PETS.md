# Pets

His ask on 5 Oct: "also add companions and pets" (ROADMAP 4.5b). Expanded game only: the
original game (`--classic`) never shows a cage, and its replays do not change.

## How they work

- One pet at a time, for the run. A pet cannot be hurt and follows the hero from room to room.
- **Cages**: treasure rooms 12%, vaults 35%, hidden rooms 20% (not the ones holding an event),
  shops 25% (for gold: 40 + 10 a floor), a rift guardian's hoard 50% (free). A cage opens with a
  key. Opening one while you have a pet swaps them: your old pet waits in the cage, free, and
  keeps its level if you take it back.
- **Growing**: foes beaten while the pet is with you. Level 2 at 12, level 3 at 35. Each level
  is stronger and adds a trick. The HUD shows the pet, its name and one star a level.

| Pet | What it does | Level 2 | Level 3 |
|---|---|---|---|
| BISCUIT (a pup) | fetches anything that drops and brings it to you | digs up a coin in each room you clear | two coins, 15% a key |
| ZAPPY (a tiny drone) | zaps the nearest foe every 1.4 s | every 1.1 s | every 0.8 s, jumps to a second foe |
| CINDERTAIL (a fire newt) | leaves fire behind it as you walk | wider, longer | longer still |
| BRAMBLE (a hedgehog) | rolls into a foe every 3 s: it bleeds; knocks shots out of the air | every 2.4 s, harder | every 1.8 s, bounces to a second foe |
| GLIMMER (a lantern moth) | foes near its light take +20%; flutters at a hollow wall | +30% | +40%, and the wall opens where it glows |
| GULP (a hungry toad) | eats enemy shots that come near; every 25, a coin | eats faster | faster still; every 25, a ring of shots too |
| GLOOP (a loyal slime) | takes one hit for you a room | reforms 20 s after | and bursts into ten shots |
| HOOTS (an owl) | every 7 s marks the toughest foe (a ring), then swoops: a heavy blow, a stun | every 6 s, harder | every 5 s; a foe it kills drops a gem |
| SNIP (a crab) | snips foes beside you; every 15 snips, 1 armor (once a room) | faster | faster still |
| KABOOMBA (a fuse beetle) | every 6 s runs at a foe and blows up, then hatches again | every 5 s, bigger | every 4 s, the blast leaves fire |

+1 projectile stacks without limit, so ZAPPY's zap grows stronger with it (+25% a projectile)
instead of zapping more often. Pet damage is a share of the weapon's damage, like the wisps'.

## Code

`scripts/entities/pets.gd` (class `Pets`): the table, the pet's body (static state, reset on
entering a room), its tricks, the cages (`handles`, `prompt`, `interact`, like `Saloon`) and the
drawing. On the Player: `pet`, `pet_lv`, `pet_xp`. Hooks, one line each: `Combat` (update after
the familiars, `on_kill`, Gloop in `_hurt_player_base`), `G.enter_room`, `G.room_cleared`,
`G.interact`, `G.setup_objects` (cages), the rift guardian's hoard, `overlay_view` (prompt),
`world_view` (cage, pet, shadow, zaps), `hud_view`. Art: `pet_<id>.png` (12 x 12) and
`pet_cage.png`. Debug: `--pet=ID[:LEVEL]`. Tested by `tests/pets_test.tscn`.
