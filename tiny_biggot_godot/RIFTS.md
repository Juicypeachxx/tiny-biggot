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
| skyreach | SKYREACH ISLES | crow, wisp, torchimp (own foes come in ROADMAP 4.4) | gusts, open sky | THE GALE WARDEN |

A run prefers worlds it has not shown yet (`Themes.pick`).

### Skyreach Isles (October 2026)

- **Open sky** (`World.T_VOID`): islands in the sky. The hero and walking foes cannot
  cross it; flying foes and every shot pass over it. A hero left on it by anything
  (a dash, a blink) steps back onto the nearest island (`Hazards._off_the_edge`).
  Pickups move like walkers, so none can land in the sky.
- **Four layouts of its own** (101-104 in `World.build_room`): four sky lakes, a ring of
  sky round the middle island, three lanes split by long drops, stepping stones. The
  champion room is the open arena, as in every world.
- **Gusts** (`Hazards._update_gusts`): a band across the room is marked for 1 s, pale
  blue with arrows showing the way; then the wind blows along it for 1.4 s, shoving the
  hero and foes (not champions) 150 px/s and carrying ice debris shots. Step out of the
  band or roll through the debris.
- **The Gale Warden**: a flying champion (blink, fans, a spiral, ice rings, falling
  strikes, calls crows).
- Art: `kit_skyreach.png` (mossy flagstones, cloud-stone walls, crystal pillars, sky and
  cliff-lip tiles at row 2, columns 2 and 3) and `galewarden(_elite).png`.

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
- saloon (October 2026, `scripts/game/saloon.gd`): THE LAST DROP SALOON. A bar with a
  bartender (three of five drinks on the counter, each a 45 s boost with a catch: DRAGON'S
  BREATH +40% damage / -15% fire rate, QUICKSILVER GIN +25% fire rate +20% speed / rolls 50%
  slower, BOG MOONSHINE heals 2 hearts / -15% speed, LIQUID COURAGE +2 armor / -15% damage, THE
  HOUSE SPECIAL +30% crit / spill a tenth of your gold; the fifth chat earns a free round), a
  merchant with a weapon or gear piece and a potion, and the bounty broker: one quest for the
  floor (kill 3 elites: a relic; clear 3 fights unhit: gear; kill 60 foes: 40 gold and a
  potion), shown on the HUD under the floor name and dropped at the next floor. Easter eggs:
  the piano (play it four times), the WANTED poster (it is you), the sleeping drunk (sometimes
  a key in his boot). Furniture stands on `World.T_PROP` tiles (blocks all but flyers).

### More event rooms, special rooms and wanderers (October 2026, `scripts/game/event_rooms.gd`)

Event rooms (in the MYSTERY pool):

- pit: THE FIGHTING PIT. Bet gold with the pit boss; the room locks for three waves; win three
  times the bet and two gems.
- chopshop: THE CHOP SHOP. The mechanic bolts a random mod onto your weapon for gold, one per
  weapon: SERRATED, TWIN FEED, INCENDIARY, TRACER, RECOIL KICK, HUNTER SCOPE. The weapon is
  copied; the weapon list is never changed.
- fortune: THE FORTUNE TELLER. Three cards face down, each a blessing with a curse for the run
  (+1 projectile, +30% damage, +2 armor and a heart, +20% crit, +1 roll / -1 heart, -15% speed,
  -15% fire rate, slower rolls, dearer shops). Pick one; the others vanish.
- courier: THE COURIER'S POST. Carry a parcel through the next 3 rooms within 100 s: a relic
  and 25 gold. Too slow, or a new floor, and it is lost. Shown on the HUD in cyan.
- gallery: THE SHOOTING GALLERY. 20 s of pop-up targets (harmless `target` foes); 4 hits gold,
  8 gear too, 12 a relic too.

Special rooms (an 18% chance that a MYSTERY door holds one of these instead):

- beacon: THE SIGNAL BEACON. Light it: the room locks and foes keep coming; stand in its circle
  for 45 s in all; then an iron chest and embers.
- vault: THE PLATE VAULT. A statue flashes four colours (and says them); step on the plates in
  that order for two iron chests. A wrong plate resets them and fires darts.
- cursed: THE CURSED ARMORY. Three epic or legendary weapons; each carries a curse that stays
  for the run (shown in its prompt). Take one; the others are locked away.

Wanderers, after a fight is won (combat or elite, not in a rift), placed on open floor at least
70 px from every door and 50 px from the hero:

- the drunk, on a floor after one where you met the saloon (30%, once a floor): a gift;
- a lost merchant (6%, once a floor): one potion, key, bomb or armor for gold.

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
