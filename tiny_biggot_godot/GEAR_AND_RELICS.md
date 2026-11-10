# Forty gear pieces, twenty relics and a harder game (ROADMAP 4.7, part A)

His ask on 5 Oct: new equipment and relics, and "make the game a little bit harder, it is too easy
at this stage". Expanded game only: the original game (`--classic`) never offers the new items,
none of its numbers change, and its six replays stay identical.

## Aimed at the thin spots

Counted from the data before starting:

- Gear slots: neck (14 pieces), hands (20) and ring (22) had the fewest. The forty new pieces are
  head 5, body 5, feet 5, trinket 5, hands 7, neck 7, ring 6.
- Tags: frost, demolition, swarm and malice had the fewest gear pieces; frost (3), demolition (2),
  swarm (6) and pyre (7) the fewest relics.
- Moments nothing listened for: healing (0 items), firing, picking something up, drinking a potion
  and swapping weapons (1 or 2 each). And nothing at all could react to setting a bomb, armor
  breaking, a dodge, healing at full health, opening a chest or buying.
- The 100 new weapons' turrets and skeletons (4.6, part 3) could only come from those weapons.

## New in the effect system

All data, like every item (`scripts/effects/`). The new moments fire only for a hero who carries
triggered effects, so the original game draws no extra random numbers.

| | |
|---|---|
| Moments (triggers) | `on_bomb` (you set a bomb), `on_armor_lost` (a point of armor takes a hit), `on_dodge` (a hit is dodged), `on_overheal` (healing at full health), `on_chest` (any chest opened), `on_buy` (anything bought) |
| Conditions | `close` (the foe within 50 px), `far` (beyond 120 px), `fresh` (this is the first hit it took), `last_foe` (the last foe in the room), `crowd` (6 or more foes), `unhurt` (not hit in this room), `coin` (the pickup was a coin) |
| Actions | `turret` [kind, s, dmg] a 4.6 turret by you (gun, flame, tesla, frost, saw, mend or random; items keep two); `raise` [s, dmg] a skeleton climbs out where the foe fell (items keep four); `reflect` [radius, dmg] foes' shots near you fly back the way they came, as yours; `spread` [radius] the foe's ailments jump to the foes near it; `consume` [dmg] every ailment on the foe is used up, each for a hit; `give` [bombs/keys/potions, n] (potions stop at your slots); `slow_shots` [radius, k] shots near you keep only k of their speed; `overkill` [share] damage past a foe's death carries on to the nearest foe |
| Hook | `gold_guard` (the bribe purse): with that much gold, a hit that would cost health costs gold |

## The four sets

| Set | Tag | 2 pieces | 4 pieces |
|---|---|---|---|
| RIMEWARDEN | frost | +15% chill chance | every 3 s in a fight, shots near you slow to a crawl |
| BLASTWRIGHT | demolition | +2 bombs, bombs 25% wider | a bomb you set drags foes in around it |
| BONECALLER | malice | +1 wisp | every foe you kill rises as your skeleton for 8 s |
| CLOCKWORK | swarm | +12% fire rate | every 8 s in a fight, a random turret springs up for 8 s |

| Piece | Slot | What it does |
|---|---|---|
| RIMEWARDEN HOOD | head | a quarter of your hits on far foes chill them |
| RIMEWARDEN MANTLE | body | when armor takes a hit, every foe near you freezes solid for 1 s |
| RIMEWARDEN GRIP | hands | a chilled foe you kill passes all its ailments to the foes near it |
| RIMEWARDEN BELL | neck | every 10 s in a fight, a frost totem rises beside you |
| BLASTWRIGHT GOGGLES | head | setting a bomb makes you untouchable for 0.6 s |
| BLASTWRIGHT APRON | body | 8% of kills hand you a bomb |
| BLASTWRIGHT MITTS | hands | every bomb you set leaves a flame turret behind |
| BLASTWRIGHT BAND | ring | clearing a room hands you a bomb |
| BONECALLER CROWN | head | an elite you kill rises as your skeleton, hitting twice as hard |
| BONECALLER RIBCAGE | body | when hit, a skeleton claws its way out beside you |
| BONECALLER RATTLE | neck | levelling up raises two skeletons |
| BONECALLER SIGNET | ring | 10% of hits on cursed foes use up all their ailments |
| CLOCKWORK MONOCLE | head | your first hit on each foe strikes again |
| CLOCKWORK COAT | body | when armor takes a hit, a tesla coil springs up |
| CLOCKWORK BOOTS | feet | rolling drops a saw trap |
| CLOCKWORK KEY | trinket | every 15 s in a fight, a mending totem rises (stand by it to heal) |

## The other 24 pieces

| Piece | Slot | What it does |
|---|---|---|
| HOOD OF LAST RITES | head | every hit on the last foe in a room strikes again |
| POLISHED CUIRASS | body | when armor takes a hit, the shots near you fly back as yours |
| GHOST STEPS | feet | dodging a hit gives +50% damage for 3 s |
| ABBOT'S SANDALS | feet | healing at full health gives 1 armor instead |
| ICE SKATES | feet | rolling in a crowd freezes the foes near you |
| MAGPIE BOOTS | feet | picking up a coin gives +25% fire rate for 2 s |
| UNSCATHED MEDAL | trinket | a room cleared without a scratch pays 8 gold and +25% damage |
| BRIBE PURSE | trinket | with 15 gold, a hit costs 15 gold instead of health |
| TREASURE MAP | trinket | a third of chests hold a spare key |
| VOODOO DOLL | trinket | when you are hit, the nearest foe takes 300% and is cursed |
| LEECH GLOVES | hands | 8% of foes killed up close heal half a heart |
| CATALYST GLOVES | hands | a crit uses up every ailment on the foe, 60% each |
| PLAGUE HAND | hands | 10% of hits on poisoned foes spread their ailments |
| PICKPOCKET GLOVES | hands | a quarter of your first hits on a foe pick 1 gold |
| BOUNCER'S KNUCKLES | hands | 15% of hits up close stun the foe and shove the others away |
| SAINT'S MEDALLION | neck | healing at full health sends out 12 stars |
| MIRROR PENDANT | neck | dodging a hit sends the shots near you back as yours |
| HOWLER'S TOOTH | neck | in a crowd, a war cry every 8 s: +30% damage |
| BLOODHOUND COLLAR | neck | hitting a bleeding foe heals half a heart (every 8 s) |
| MERCHANT'S CHARM | neck | every purchase comes with a free bomb |
| RING OF EXCESS | ring | damage past a kill carries on to the nearest foe |
| FROSTBITE RING | ring | a quarter of crits on chilled foes freeze them solid |
| RING OF RETURNING | ring | swapping weapons fires 12 shots and erases shots near you |
| KINDLING RING | ring | drinking a potion sets every foe near you alight |

## The twenty relics

| Relic | Tags | What it does |
|---|---|---|
| FROST LANTERN | frost | killing a chilled foe slows every shot near you |
| PERMAFROST | frost | your first hit on each foe chills it |
| SNOW ANGEL | frost, shadow | dodging a hit chills every foe near you |
| FUSE BOX | demolition | a quarter of the bombs you set come back |
| POWDER HORN | demolition, pyre | setting a bomb sprays 12 embers |
| BLAST SHIELD | demolition, bulwark | setting a bomb gives 1 armor (every 10 s) |
| GRAVE WHISTLE | swarm, malice | 10% of the foes you kill rise as skeletons |
| TINKER'S TOOLBOX | swarm, demolition | entering a room sets up a gun turret for 15 s |
| HONEYCOMB | swarm | healing calls a wisp |
| LITTLE KILN | pyre | healing at full health sets the foes near you alight |
| FURNACE HEART | pyre | a burning foe you kill passes all its ailments on |
| WYRM SCALE | bulwark, pyre | when armor takes a hit, 12 fireballs burst from you |
| QUICKDRAW HOLSTER | edge | swapping weapons gives +100% crit for 2 s |
| WISHING COIN | fortune | one coin in 20 makes a wish (something random) |
| PHILOSOPHER'S DROP | arcane | a quarter of the potions you drink fill back up |
| SURVEYOR'S CHART | fortune | every floor starts with a key and a bomb |
| RIPOSTE CHARM | edge, shadow | rolling past a close shot sends the shots near you back |
| DOMINO TILE | fury | damage past an elite's death carries on, doubled |
| STAMPEDE DRUM | fury, bulwark | in a crowd, every 5 s you blast the foes near you away |
| SPYGLASS | edge | 15% of hits on far foes strike again |

## A harder game (expanded game only)

`Combat.hard_hp`, `Combat.foe_hit`, `Combat.shot_mult`, `spawn_wave`; all are exactly the original
numbers under `--classic`.

- Foes, mini-bosses and guardians: +10% health on the first floor, +3% more a floor (+40% on the
  eleventh). Traps and hazards that hurt foes scale with it.
- From the third floor, one more foe a wave; 3% more elites.
- Foes' shots fly 6% faster.
- From the seventh floor (past the Pale Regent) a foe's blow or shot costs a whole heart; a toast
  says so on arriving. Traps, hazards and your own bombs stay at half a heart. Armor still takes a
  whole hit.

Measured (bot without god mode, everything unlocked, the same 16 seeds, 10 minutes each, the same
build with the change switched off and on): deaths 22 -> 31, average furthest floor 3.6 -> 3.1. Not
measured: how it feels to a person; the bot does not dodge.

## Tests

`tests/items_test.tscn` (in `tools/check.sh`): every new piece and relic in the moment it is made
for (its action runs and, for the new actions, finds something to do), the four sets (the 4-piece
power works and goes when a piece comes off), and the new actions looked at closely (reflected
shots fly back toward where they came from; slowed shots stay slow and far ones are left alone;
every ailment spreads to the foes beside, not to one far off; consume clears them and hurts;
overkill reaches the nearest foe; potions stop at the slots; the bribe purse with too little gold
lets the hit through). Planted faults it caught: no `on_bomb`, reflect keeping the shot's way, a
turret from entering a room cleared a tick later, `fresh` never true, the purse never paying,
`on_overheal` never firing.
