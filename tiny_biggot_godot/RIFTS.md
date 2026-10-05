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
| bastion | THE DROWNED BASTION | rampartguard, sludgecrawler, chainwarden, tidecaller, longpike, drowned | toxic tide | THE ROTTING KING |
| cathedral | THE CALIBER CATHEDRAL | shellpriest, dervish, deacon, beltfeeder, ammomimic, gunman | wall turrets | THE HIGH CALIBER |
| skyreach | SKYREACH ISLES | skykite, gustling, stormharpy, thunderhead, mirrorwing, crow | gusts, open sky | THE GALE WARDEN |

A run prefers worlds it has not shown yet (`Themes.pick`).

### The Drowned Bastion and the Caliber Cathedral (October 2026, `scripts/world/rift_extras.gd`)

Moods of a rain-soaked rampart over a poisoned sea, and of a brass temple built from bullets.
Original names and art.

- **Bastion:** the **toxic tide**: a band is marked green with arrows for 1.2 s, then a sludge
  wave sweeps along it at 220 px/s; it hurts the hero once and every foe it passes (12 x floor
  scale, not champions). **Levers** on the top wall (30% of fights) open a hidden alcove: 4 coins,
  sometimes a key. Easter eggs: a **skull on a pike** (its third joke spits out a gem; 22%), a
  **hooded fisher** at a puddle (a fish that heals, or a boot with a coin; 8%).
- **Cathedral:** **tables** in every fight room: USE flips one into cover (`World.T_PROP`: stops
  shots and walkers; anyone inside is pushed out). Two **wall turrets** show a red aim line for
  0.8 s, then fire three shots. Easter eggs: the **bullet saint** shrine (gold for +20% damage,
  90 s; 25%), a **rat asleep on casings** (it steals gold and flees; catch it and it pays back
  double; 12%).
- Layouts 201-204 (ramparts, cells, broken bridge, chapel) and 301-304 (pews, altar, crossfire,
  nave). Champions: THE ROTTING KING, THE HIGH CALIBER.

### Twenty new foes (October 2026, `scripts/entities/enemy_ai2.gd`, ROADMAP 4.4)

Each fights in a way no older foe does, and every attack is warned first. Skyreach: sky kite
(circles you, floating mines), gustling (swells, blasts you away), storm harpy (marks a spot,
dives onto it), thunderhead (calls marked lightning), mirrorwing (mirrors you through the middle
of the room, fires when lined up). Bastion: rampart guard (front shield takes 80%, turns slowly),
sludge crawler (a trail that hurts), chain warden (hook along a shown line drags you in),
tidecaller (calls a sludge wave along its row), longpike (reach thrust along a red lane).
Cathedral: shell priest (wide blast with recoil), bullet dervish (spiral, then dizzy and +50%
damage taken), deacon (shields foes near it: half damage, 3 s), belt feeder (a four-link snake;
links fire sideways in turn), ammo mimic (a crate until you come near). Original floors, expanded
game only (`EnemyAI2.OLD_FLOOR_EXTRA`, added to copies of the floor data): tomb spider (webs that
slow), candlewight (can only be hurt while its candle is lit), gargoyle (moves only while you do),
war drummer (every foe 50% faster for 2 s), blood leech (latches on: roll, or lose a heart).
New enemy fields: `guard_t`, `haste_t`, `aux`, `aux2`, `links`, `trail`, `lead` (a WeakRef: the
head holds its links strongly, so the two never keep each other alive). Webs and sludge live in
`Room.goo`. Tested by `tests/foes_test.tscn` (in `tools/check.sh`).

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

### Rift bosses (October 2026, `scripts/entities/rift_bosses.gd`, ROADMAP 4.5)

The three new worlds each have a **mini-boss** (the last wave of the rift's second room) and a
**guardian**. When the world's champion falls, its room has a second door, named after the
guardian, leading deeper: an optional fight in an open arena (`Room.rift_step` 3, room type
"boss"), with a guardian's hoard (a boss chest, a weapon, gear, gems, embers) and the way back.
It counts as a guardian beaten (constellation points). No portal: the floor goes on.

Every attack is shown before it lands. Below half health each boss has a **second phase**: 1.4 s
in which it takes no damage and every shot on screen vanishes, a line on the banner, then a
harder plan with new attacks.

- **THE SQUALL HERON** (Skyreach): quills that stop in the air, flash, and turn on you; lightning
  rods round you joined by arcs (thin flickering lines first); a gale along its row (the world's
  gust). Phase 2: rings of quills, arcs to itself as well, a second gale across.
- **THE STORMCROWN** (Skyreach): sky lances (pale bands with falling chevrons, then a bolt and
  sparks); a ring of shots round you that closes in, with one gold gap; downdrafts (gusts); ball
  lightning joined by arcs. Phase 2: a cyclone that hunts you, lances in crosses, and the eye of
  the storm pulls you gently in.
- **THE DROWNED CAPTAIN** (Bastion): throws his anchor down a lane and hauls himself after it
  along the chain; swings it round (a ring on the floor first); lobs sludge barrels (landing
  rings). Phase 2: more of each, and the haul leaves sludge.
- **THE BILGE HYDRA** (Bastion): heads lunge down lanes; a breath sweeps an arc (its edges shown
  first) and leaves sludge; spit in arcs; it calls the toxic tide. Phase 2: two more heads grow,
  two breaths cross.
- **THE BELLRINGER** (Cathedral): tolls, rings of sound that spread (roll through them); a hymn of
  notes that weave; drops the bell where you stand, and takes half again as much damage until it
  comes back. Phase 2: three tolls, the bell bounces after you twice.
- **THE BRASS ORGAN** (Cathedral): each pipe glows before it fires (a toccata that runs along the
  pipes, a fugue of aimed triplets); a chord: only the gold lanes on the floor are safe; a choir
  of foes. Its nave has three tables to flip. Phase 2: pedal waves down the room with one gap,
  two wall turrets, and it slides along the wall as it plays.

Data: minis are `GameData.ENEMIES` rows with `"ai": "riftboss"` (and `"champion"`, so their health
grows with the floor and the world's hazards leave them be); guardians are `GameData.BOSSES` rows
with `"rift": true`. Both carry `"rule": "phase"`. Themes name them (`"mini"`, `"guardian"`). In a
guardian's arena the world's own hazard does not fire by itself: the guardian calls it.
Debug: `--rift=ID --step=3` starts in the arena; `--spawn=TYPE` puts one foe in the room.
Tested by `tests/bosses_test.tscn`.

### REX THE FAT GOLDEN RETRIEVER (October 2026, `scripts/entities/rex.gd`, ROADMAP 4.5c)

A hidden boss made from photos of the owner's dog. **REX'S BARN** has its own tiles (`kit_barn`:
old stone, dark beams, a straw floor, hay bales for pillars), a potato patch, the hay pile (a
sword's grip pokes out of it), his blue striped mat and his bowl. Two ways in: a hidden room on
the second floor or later is his barn 12% of the time (once a run), and the title screen has
him asleep in the bottom-left corner: tap him (or press SPECIAL) three times and the next run's
first room has a door to his barn.

He sleeps until you come within 64 px or hit him (blows on a sleeping dog count double). Fill
his bowl first (5 gold): he wakes up for dinner with 15% less health. The barn locks when he
wakes. First phase: BELLY FLOP (a landing ring, a shock wave and a ring of bones), ZOOMIES (two
laps of an oval shown first, shedding bones), POTATO DIG (lobbed potatoes with landing rings),
WOOF (he breathes in, then a ring of sound that shoves you and a ring of bones), NAP (on his mat,
snoring: double damage). Second phase (the banner: SUNGLASSES ON. HE FOUND A SWORD IN THE HAY):
SWORD SPIN (a ring shows the blade's reach, one and a half turns), LEAP SLASH (a landing ring,
then a lane), THE FETCH (a lane, the sword flies to the wall, he runs after it), SWORD WAVE (a
crescent of shots), harder flops and woofs. Beaten, he rolls over (no explosions: hearts), leaves
a guardian's hoard and offers to come along as the pet REX. It counts as a guardian beaten.

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

    --rift=ID [--step=0..3]   start inside a rift world (step 2 is the champion, 3 a new world's guardian)
    --event=NAME              start in an event room

## Tests

`tests/rift_test.gd` (run by `tools/check.sh`) enters every world and every event,
kills every champion and checks the rewards. Full replays were re-recorded because
door rolls changed; classic replays are bit-identical.

Balance is a first pass and has only been played by the bot.
