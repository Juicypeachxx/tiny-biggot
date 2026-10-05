# Rift worlds, champions, events and hidden rooms

Everything here belongs to the Rogues layer. `--classic` runs never see any of it,
and the classic replays in `tests/replays/classic` are unchanged.

## Rift worlds

Once per floor (from the third room on, never right before the boss) one exit is a
rift door named after a world. A rift is three rooms: two fights, then the world's
champion. Rooms inside a rift do not count towards the floor's depth. Each world has
its own tile kit, foe pool, hazard, music and champion. All of them are original
homages: setting and mood only, own names, own art.

| id | World | Foes | Hazard | Champion |
|---|---|---|---|---|
| gaol | BLACKROCK GAOL | inmate, grenadier, jailer | floor spikes | THE TURNKEY |
| brand | THE BRANDED FIELD | graveborn, bandsman, fiendling, blackknight | blood rain | THE CARRION KNIGHT |
| neon | NEON UNDERCITY | drone, glitch, chrome, turret | shock pylons | THE BROKER |
| streets | RIOT ALLEY | thug, molotov, copper, bomber | explosive barrels | THE MAYOR |
| fog | ASHFALL TOWN | orderly, crawler, static, tollkeeper | falling ash, fog | THE RUST BUTCHER |
| burb | MAPLE COURT | neighbour, robovac, burglar, gnome | kitchen fires | THE LANDLORD |
| heist | HEIST CITY | gangster, biker, riotcop | traffic lanes | THE KINGPIN |
| dust | DUSTWATER | outlaw, dynamiter, sharpshooter, coyote | dynamite | THE MARSHAL |

A run prefers worlds it has not shown yet (`Themes.pick`).

Champions are data rows in `GameData.ENEMIES` with `"champion": true` and a `"moves"`
list run by `scripts/entities/champion_ai.gd` (charge, ring, fan, spiral, burst, duel,
lob, rain, summon, blink). Below half health they speed up by 35%. Beating one drops
a boss chest, a weapon, embers and gems.

## Mystery rooms

A `?` door leads to one of nine events (`MYSTERY_EVENTS` in `scripts/game/game.gd`):

- wheel: pay gold to spin, up to three times, for a prize or a punishment
- market: blood market, three relics, each costs a max heart
- mimic: one of the chests bites
- armory: three weapons on display, take one
- well: throw gold in, up to five times, sometimes something comes back
- goblin: a loot goblin runs for the exit, catch it for its sack
- mirror: your shadow steps out, beat it and it leaves a relic
- library: a tome that costs half a heart and grants a level
- safehouse: a bed that heals and a jukebox that takes gold

## Hidden doors

- Half of all secret rooms now hold an event instead of a plain chest.
- A loose brick sits in the wall of some treasure, shrine, rest and shop rooms. Press it.
- Clearing a combat or elite room without being hit has a 35% chance to open a hidden door.

## New room layouts

Layouts 9 to 16 in `scripts/world/world.gd` (Rogues only). Champion rooms always use
the open arena.

## Item art

All 27 batch 4 weapons and 37 batch 4 gear pieces have their own icons
(`assets/graphics/w_*.png`, `g_*.png`). Gear drawn on the hero takes its colours from
the icon, so those pieces now show in their real colours.

## Debug arguments

    --rift=ID [--step=0..2]   start inside a rift world (step 2 is the champion)
    --event=NAME              start in an event room

## Tests

`tests/rift_test.gd` (run by `tools/check.sh`) enters every world and every event,
kills every champion and checks the rewards. Full replays were re-recorded because
door rolls changed; classic replays are bit-identical.

Balance is a first pass and has only been played by the bot.
