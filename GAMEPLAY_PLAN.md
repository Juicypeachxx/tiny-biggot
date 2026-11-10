# His list of another game's core gameplay (10 Oct, after IPA 46)

He pasted a list of Tiny Rogues' core gameplay, combat and equipment. This file holds what we
already have for each point, and what is still to add. Like ENCHANTMENTS_PLAN.md: **ideas only**.
Every new thing gets **a name of our own** (rule 3), and nothing already in the game is removed or
toned down (rule 1).

## What we already have

| On his list | Here already |
|---|---|
| Rooms in a row, no map | The chain of doors is still in the code (classic, and `--linear` for tests); the expanded game uses the floor map |
| A tech tree at the campfire, points from bosses | THE CONSTELLATION at the camp telescope: 1 point per guardian, 2 per win, up to 30; hero skill trees; shrine unlocks for embers |
| Harder modifiers after beating the last boss | DREAD 1 to 5 (unlocked by winning; more dread, more embers) |
| Hardcore after 5 wins | Nothing yet |
| Dash, bombs | ROLL with charges; bombs |
| A refillable healing flask | Nothing yet (potions in the belt) |
| STR, DEX, INT, mana, luck | STR, DEX and INT (attributes.gd); LUCK is a stat; the special's charge works like mana |
| Class skills | Every hero has a special (34) and a skill tree |
| Hundreds of weapons, rarities | 512 weapons, common to mythic |
| Damage types | Weapons: SLASHING, PIERCING, BLAST, FIRE, FROST, POISON, LIGHTNING, ARCANE, SHADOW. Infusions and enchantments: holy, nature, necrotic, dark |
| Ailments | Bleed, poison, burn, chill, shock, curse, gloom, stun. Armour plates break on guardians only |
| Loot modifiers, enchantments | Loot stats (38), enchantments (46) |
| Items that grow with gold, curses, souls | Gold: DRAGON'S HOARD, HEAVY PURSE and more. Curses and souls: not yet |
| Booze, capped at 3 | TIPSY, up to 8 stacks (kept: rule 1) |
| Room potions, infusions | Infusions (44), drinks as buffs (36). Room potions: not yet |
| A whetstone, ethereal dice | The anvil, a hammer item (+2); REROLL, ALTER and BANISH dice (35) |

## What is new: proposed stages (in the order they would be felt most)

- **Stage 47: THE GOURD and SHATTER.** A healing gourd on the HUD: one sip heals 2 hearts and
  refills at every rest stop and after a guardian; stars and relics can add sips. Potions stay.
  SHATTER, a new ailment: a shattered foe takes more damage, and some weapons, traits and
  relics cause it (the guardians' armour plates as they are).
- **Stage 48: loot and drinks.** Items that grow with the curses you carry and the foes you have
  slain this run (next to the gold ones); ROOM DRAUGHTS (a strong buff until the room is clear);
  a HONING STONE (one use: +1 weapon level).
- **Stage 49: five more damage types.** RADIANT, NECROTIC, DARK, ENERGY and SOUND as weapon damage
  types (their own colours, ailments and reactions), and new weapons that deal them.
- **Stage 50: run modes.** THE NARROW WAY (a run with no map: room after room); OMENS (after a win:
  pick challenges one by one, each adds embers and star points; the constellation grows past 30);
  IRON VOW (after 5 wins: one life, no continue, a mark on the hero who wins it).
- **Stage 51: two more attributes.** SPIRIT (the special's charge and power) and LUCK as attributes
  next to STR, DEX and INT; each attribute also raises a pool (STR health, DEX roll charges, INT
  and SPIRIT the special). The deepest change to the numbers, so last.
