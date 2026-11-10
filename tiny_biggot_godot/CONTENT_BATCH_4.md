# Content batch 4: chaos

27 weapons, 37 pieces of equipment (3 new four-piece sets), 18 named combos,
10 new effect actions, and equipment that shows on the hero.

## New effect actions (scripts/effects/actions.gd)

| Action | What it does |
| --- | --- |
| `["meteor", dmg, radius]` | A meteor falls on a random foe and leaves fire |
| `["bolts", n, dmg]` | Lightning on n random foes |
| `["pull", radius, force]` | Drags foes toward the target (guardians are immune) |
| `["push", radius, force]` | Hurls foes away from you |
| `["bomb", fuse]` | A lit bomb at the target, harmless to you |
| `["zone", kind, radius, seconds]` | A fire, poison or smoke pool |
| `["transmute", coins]` | An ordinary foe turns into coins (not elites or guardians) |
| `["rand_status", amount]` | A random ailment |
| `["shoot_at", n, dmg, kind, spread, angle]` | Shots at an angle from your aim |
| `["chaos"]` | One random entry of `Actions.WILD` (12 outcomes) |

New conditions: `rich` (100+ gold), `armored`.

## Sets

- **JESTER** (cap, motley, curly shoes, bauble): 2 = +1 luck, 4 = something random every 6 s in a fight.
- **STARFALL** (crown, plate, gauntlets, greaves): 2 = +15% burn, 4 = a meteor every 4 s in a fight.
- **VOIDWALKER** (cowl, wraps, locket, band): 2 = +8% dodge, 4 = rolling drags foes in and blasts them.

## Combos (pair, name)

singularity + collapsedstar = BIG BANG; partyhat + discoball = PARTY TIME;
beehive + beekeeperhat = QUEEN BEE; midascannon + midasglove = GOLD RUSH;
rocketboots + bombvest = DEMOLITION DERBY; chaosdie + slotmachine = HIGH ROLLER;
frostfist + slipperysoles = ABSOLUTE ZERO; bigring + tinyring = IDENTITY CRISIS;
volcano + pocketsun = ERUPTION; teslacoil + stormcloud = THUNDERDOME;
ghostsheet + necroflute = HAUNTED HOUSE; monkeypaw + chaosdie = WISHMASTER;
clownhammer + jester_cap = CLOWN CAR; chainsaw + boxinggloves = RIP AND TEAR;
orbitallaser + magnethelm = TARGET LOCK; crossfirebow + twinring = BULLET HELL;
gravitymaul + void_amulet = EVENT HORIZON; bubblewand + partyhat = BUBBLE BATH.

## Equipment on the hero (scripts/render/hero_gear.gd)

Each equipped piece paints a few pixels over the hero, shaped by the item's
`shape` and coloured from its icon. OPTIONS has SHOW GEAR ON HERO to turn it off.

## Icons

The new icons are recolours of existing ones (placeholder art, like batch 1).

## Testing

`tools/check.sh` passes. The full-pool replay baselines in `tests/replays/`
were re-recorded because the loot pools grew; the classic set is untouched.
On a desktop, `--give=weapon:volcano,gear:pocketsun` starts a run with items.
