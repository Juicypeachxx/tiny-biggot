# Weapon enchantments: the plan (his pictures, 10 Oct)

He sent 5 pictures of a wiki's "Weapon Enchantments" page: "Learn from that, we will add this later."
This file is what was on them and what each becomes here. Like TRAITS_PLAN.md: **ideas only**. When
it is built, every enchantment gets **a name of our own** (rule 3); the names below are only there to
match the pictures. Planned as Stage 46 in ROADMAP.md, after the alignment shops.

## How they work there

- An enchanted weapon carries **one** modifier at a time (most weapons only ever have one).
- Five kinds: negative (bad rolls), positive, legendary, special (only from certain events and
  shops) and some removed from that game.
- Some need something on the weapon first: the burn, chill and shock ones need that element's damage
  on the weapon.

## How they could work here

- A weapon gets an **enchantment slot**: one at most. It shows on the item card, in the weapon's
  name (a prefix) and on its name plate.
- Found on weapons as they drop (rarer weapons more often, legendary ones only on rare or better),
  set at a new **enchanter** in the expanded shops (pay to roll one), and the special ones from the
  events and shops listed below.
- The negative ones come on cheap or cursed weapons, so a lucky roll can still be a bad one.
- Nothing removed (rule 1): the four the wiki lists as removed come in too.
- Expanded game only; classic weapons stay plain.

Words used below: **scaling** = a weapon's STR, DEX and INT grades (S to E, attributes.gd);
**upgrade level** = the anvil's +1 levels (WeaponInfo.plus); **lucky hits** = 34.1; **mana
container** = the special's charge (TRAITS_PLAN.md); flat element damage = an extra hit of that
element, growing with the floor.

## Negative

| On the picture | Effect there | Here |
|---|---|---|
| Trash | -1 to all scaling | every grade one step lower |
| Crappy | -10% damage | the same |
| Godawful | -20% damage | the same |
| Slow | -10% attack speed | -10% fire rate |
| Tortoiselike | -20% attack speed | -20% fire rate |

## Positive

| On the picture | Effect there | Here |
|---|---|---|
| Precise | +10% crit chance | the same |
| Dragonslayer's | x2 damage against dragons | x2 against dragon-kind foes (needs foe kinds) |
| Deadly | +75% crit damage | the same |
| Contaminated | +20 to 30 poison damage | hits add poison damage (and poison) |
| Quick | +10% attack speed | +10% fire rate |
| Electric | +5 to 75 lightning damage | hits add lightning damage, wide range |
| Fierce | +10% damage | the same |
| Icy | +20 to 30 cold damage | hits add cold damage (and chill) |
| Happy | +10% lucky hit chance | the same |
| Potent | x1.20 top end damage | the top of each hit's roll (Might.roll) x1.2 |
| Fiery | +20 to 35 fire damage | hits add fire damage (and burn) |
| Steady | x1.20 damage with non-critical hits | the same |
| Witchhunter's | x2 damage against fiends | x2 against demon-kind foes (needs foe kinds) |
| Sly | +5 DEX | the same |
| Clever | +5 INT | the same |
| Brutal | +5 STR | the same |
| Incinerating | x1.25 burn damage (needs fire damage on the weapon) | the same |
| Glacial | x1.25 chill effect (needs cold damage on the weapon) | the same |
| Charged | x1.25 shock effect (needs lightning damage on the weapon) | the same |

## Legendary

| On the picture | Effect there | Here |
|---|---|---|
| Almighty | +30% damage | the same |
| Baleful | +25 to 50 necrotic damage | hits add necrotic (wither / curse) damage |
| Divine | +25 to 50 radiant damage | hits add radiant (holy, sun) damage |
| Lucky | +25% lucky hit chance | the same |
| Headhunter's | x1.20 damage against bosses | against guardians and mini-bosses |
| Occult | +15 to 85 dark damage | hits add dark (shadow, gloom) damage |
| Unreal | +25% attack speed | +25% fire rate |
| Sniper's | +20% crit chance | the same |
| Merciless | +125% crit damage | the same |
| Twinkling | +1 upgrade level | the same |

## Special (only from these places)

| On the picture | Effect there | Where there | Here |
|---|---|---|---|
| Dwarven | +1 to all scaling | Dwarf Hideout event | every grade one step higher; a smiths' event |
| Illegal | one of: +20% damage, +15% crit chance, +20% attack speed | Black Market shop | our black-market style dealer |
| Shining | +3 upgrade levels | Star Breath, Dragon Trophy Room event | a dragon event: four breaths |
| Blazing | x2 burn damage | Fire Breath, same event | the same |
| Freezing | x2 chill effect | Ice Breath, same event | the same |
| Thundering | x2 shock effect | Lightning Breath, same event | the same |
| Scorched | -50% damage | the same event (the bad outcome) | the same |
| Arcane | +5% damage per mana container | Fairy Tale Branch | per special charge |

## Removed there (kept here, rule 1)

| On the picture | Effect there | Here |
|---|---|---|
| Disenchanting | +25% damage to enchanted enemies | against elite foes |
| Legendary | +25% damage | the same |
| Brutal (old) | +10% super effective multiplier | +10% against foes weak to your element |
| Unstoppable | +25% not very effective multiplier | your element hurts resistant foes more |

## What it needs first

- An enchantment slot on weapons (save, drop, the item card, the name plate, the inventory).
- Flat element damage on hits, growing with the floor.
- Foe kinds (dragon, demon, ...) for the slayer enchantments; elements foes are weak or resistant
  to for the two "effective" ones.
- The enchanter in the shops, and the events: a smiths' hideout, the dragon room's four breaths,
  the fairy-tale branch.
