# Step 8: more content, in batches

Design spec step 8 adds the remaining content in batches of about 50, with the content test run after each. Every item is data in the existing tables and uses the existing effect system. Original items are untouched, and the `--classic` replays prove it after every batch.

**Quality over quantity:** the spec allows stopping below 400 per type if items stop being distinct. Each item below has its own hook (a trigger, an interaction or a niche), not just bigger numbers. **Art:** new items reuse existing sprites as placeholders.

## Totals after step 8 so far

| | Original | Rogues (new) | Total |
|---|---|---|---|
| Weapons | 113 | 52 (batch 1) + 52 (batch 2) + 7 hero weapons = 111 | 224 |
| Equipment | 96 | 48 (batch 1) + 50 (batch 3) = 98 | 194 |
| Relics | 66 | 50 (batch 1) + 51 (batch 4) = 101 | 167 |
| Traits | 72 | 60 (batch 1) | 132 |

Every batch was followed by the content test (all items equipped and fired live, swaps reversible, rails, combos, heroes, biomes), the full check and soak runs. The `--classic` replays stayed byte-identical after every batch. The full-pool replays were re-recorded after each batch, because the loot pools grew.

## Equipment slots

Gloves, an amulet and two ring slots join the original helm, armor, boots and trinket. A ring takes a free ring slot, otherwise it replaces the lower-rarity ring. Original items keep their slots (the original game's rings and amulets stay trinkets). `--classic` keeps the four original slots.

## Batch 2: 52 weapons

| Id | Name | Type | Rarity | Tags | What it does |
|---|---|---|---|---|---|
| `bogpump` | BOG PUMP | flame | common | venom | Sprays stinking mire water. Every hit poisons. |
| `leechlance` | LEECHING LANCE | thrust | rare | blood | A hollow lance that drinks. 2% of hits heal. +30% damage to afflicted foes. |
| `frogspawn` | FROGSPAWN SATCHEL | mine | common | venom, swarm | Tosses egg clusters that burst. 15% of kills hatch a wisp for 4s. |
| `witchlight` | WITCH-LIGHT LANTERN | pulse | rare | arcane, venom | A slow green light that poisons all it touches. Every 3rd light also throws 4 sparks. |
| `rainmaker` | RAINMAKER'S ROD | zap | epic | storm | Arcs jump 3 times. In a fight, calls lightning every 3 seconds. |
| `warbow` | WARBOW | bolt | common | edge | A heavy bow. +5% crit. Arrows pierce one foe. |
| `volleybow` | VOLLEY BOW | bolt | rare | arcane | Looses five arrows in a tight fan. |
| `firepot` | FIREPOT SLING | flask | common | pyre | Throws clay pots of burning pitch. 25% burn chance. |
| `siegearbalest` | SIEGE ARBALEST | rail | rare | bulwark | Slow, crushing bolts that hurl foes back. Clearing a room gives 1 armor. |
| `bannermaul` | BANNER MAUL | slash | epic | fury, bulwark | +25% damage at full health. Every kill gives +10% fire rate for 3s. |
| `cinderwhip` | CINDER WHIP | whip | rare | pyre | The tip sets foes alight. Burning foes you kill explode for 80%. |
| `scorchcannon` | SCORCH CANNON | gatling | epic | pyre | Spins up into a stream of embers. Every 20th shot is a bursting fireball. |
| `ironpike` | IRON PIKE | thrust | common | bulwark | A long, wide pike. Grants 1 armor. |
| `prayerbeads` | PRAYER BEADS | nova | rare | arcane | A ring of 14 beads. Rolling casts an extra ring of 10. |
| `frostfang` | FROSTBITE FANG | slash | common | frost | Quick cuts that chill. Chilled foes take +20% damage. |
| `avalanche` | AVALANCHE STAFF | orb | epic | frost | Huge, slow snowballs. A chilled foe you kill bursts, hitting all around it. |
| `quarterstaff` | MONK'S QUARTERSTAFF | thrust | rare | shadow | A broad sweeping staff. Rolling gives +40% damage for 2s. |
| `templebell` | TEMPLE BELL | pulse | rare | bulwark | A big, slow toll. When you are hit it rings: 12 shots around you. |
| `iciclerepeater` | ICICLE REPEATER | bolt | common | frost | Rapid shards of ice. 15% chill chance. |
| `stillwater` | BLADE OF STILL WATER | slash | legend | edge, shadow | +15% crit. Standing still, hits strike again for 50%. Rolling past a close shot gives +100% damage for 2s. |
| `sixshooter` | SIX-SHOOTER | burst | common | edge | +8% crit. Every 6th shot adds a slug for 300% to the nearest foe. |
| `alleyscatter` | ALLEY SCATTERGUN | shot | common | fury | Six pellets at once. Devastating up close. |
| `throwknives` | THROWING KNIVES | bolt | rare | shadow, edge | Pairs of knives. +10% crit. Kills refund a roll. |
| `drumgun` | DRUM GUN | gatling | rare | fortune | A chattering street gun. 10% of kills drop a coin. |
| `grapnel` | GRAPPLING HOOK | whip | rare | shadow | A very long reach. 30% of hits mark the foe: marked foes take more damage. |
| `smokecharges` | SMOKE CHARGES | mine | rare | shadow | Traps that burst. Rolling erases shots around you (every 4s). |
| `goldengun` | GOLDEN GUN | rail | legend | fortune, edge | One shot, one kill. +20% crit. Kills pay 3 gold. +10% damage per 100 gold. |
| `crowcaller` | CROWCALLER | summon | rare | swarm | Each shot raises a crow-spirit. 20% of kills call another for 5s. |
| `lampflamer` | STREETLAMP FLAMER | flame | rare | pyre | A short, hot cone. Burning foes take +25% damage. |
| `voidray` | VOID RAY | beam | epic | malice, arcane | A constant dark ray. 10% of hits curse and weaken the foe. |
| `eclipseorb` | ECLIPSE ORB | pulse | legend | malice, storm | A slow black sun that hurts all it touches. Every kill calls lightning on another foe. |
| `umbralscythe` | UMBRAL SCYTHE | slash | rare | malice, blood | A huge sweep. 10% of hits curse. Killing a cursed foe may heal half a heart. |
| `starfall` | STARFALL CHIME | nova | epic | arcane, storm | A ring of 12. Every 4th chime arcs lightning through nearby foes. |
| `hexchain` | HEX CHAIN | whip | common | malice | A chain of small curses. 15% of hits curse: cursed foes take +25%. |
| `riftcannon` | RIFT CANNON | rail | epic | arcane | Each hit tears a small rift that blasts everything near the foe. |
| `bloodletter` | BLOODLETTER | disc | rare | blood | Discs that bounce 4 times. 25% of hits bleed. |
| `bonesaw` | BONE SAW | spin | common | blood | A spinning saw that cuts through three foes. |
| `nightwing` | NIGHT-WING STAFF | summon | epic | swarm, blood | Each shot raises a spirit. +1 wisp. 5% of kills heal half a heart. |
| `hivecannon` | HIVE CANNON | flask | epic | swarm, venom | Lobs hives that burst and poison. 30% of hits release a wisp for 4s. |
| `shieldcannon` | SHIELD CANNON | rail | epic | bulwark | Grants 2 armor. When you are hit, fire a ring of 12 shots. |
| `briarspear` | BRIAR SPEAR | thrust | rare | bulwark, venom | +15 thorns. Thrusts poison. |
| `tumbleredge` | TUMBLER'S EDGE | slash | common | shadow | Rolling sends out a ring of 6 blades (every 1.5s). |
| `phantombow` | PHANTOM BOW | bolt | epic | shadow, arcane | Homing ghost arrows. After a roll, +50% damage for 2s. |
| `skullsplitter` | SKULLSPLITTER | spin | rare | fury | Heavy axes. Below half health they fly 40% faster. |
| `wrathbuss` | WRATH BLUNDERBUSS | shot | epic | fury | Seven pellets. Taking a hit gives +50% damage for 4s. |
| `flippedcoin` | FLIPPED COIN | disc | common | fortune | +1 luck. Half of your crits pay 1 gold. |
| `taxbell` | TAXMAN'S BELL | nova | rare | fortune | A ring of 10. Clearing a room pays 4 gold. Elite kills pay 6. |
| `thornidol` | IDOL OF THORNS | orb | rare | malice, bulwark | +10 thorns. Each room costs half a heart and gives +40% damage for 15s. |
| `arcsprayer` | ARC SPRAYER | flame | epic | storm | A hissing cone of sparks. 15% arc chance. Some hits shock. |
| `thunderdrum` | THUNDER DRUM | pulse | legend | storm, fury | Every hit shocks. Shocked foes you kill erupt into 8 sparks. |
| `powdermortar` | POWDER MORTAR | flask | rare | demolition | Big bursting shells. +25% bomb radius. 5% of kills drop a bomb. |
| `deadfall` | DEADFALL TRAPS | mine | epic | demolition, bulwark | Heavy traps. When you are hit, gain a bomb (every 8s). |

## Batch 3: equipment

| Id | Name | Slot | Rarity | Tags | What it does |
|---|---|---|---|---|---|
| `brawlerwraps` | BRAWLER'S WRAPS | hands | common | fury | +6% fire rate. |
| `ironfist` | IRON FIST | hands | rare | bulwark | Grants 1 armor. When hit, punch back for 200% at the nearest foe. |
| `pickpocket` | PICKPOCKET'S GLOVES | hands | rare | fortune | +10% gold. 8% of hits filch 1 gold. |
| `alchemistmitts` | ALCHEMIST'S MITTS | hands | rare | venom | Potions heal more. Drinking one poisons every foe near you. |
| `flintgloves` | FLINT GLOVES | hands | common | pyre | +12% burn chance. |
| `frostgrip` | FROSTGRIP | hands | rare | frost | +15% chill chance. Rolling chills every foe near you (every 3s). |
| `duelistgauntlet` | PARRYING GAUNTLET | hands | epic | edge, shadow | +6% crit. A perfect dodge (rolling past a close shot) erases shots near you. |
| `quickdraw` | QUICKDRAW GLOVES | hands | rare | edge | +5% fire rate. Swapping weapons gives +40% fire rate for 5s. |
| `stormknuckles` | STORM KNUCKLES | hands | epic | storm | +10% arc chance. Crits shock. |
| `gravedigmitts` | GRAVEDIGGER'S MITTS | hands | common | demolition | +2 bombs. Bombs deal +15%. |
| `beastglove` | BEASTMASTER'S GLOVE | hands | rare | swarm | Wisps deal +25%. Clearing a room raises a wisp for 15s. |
| `midasglove` | TOUCH OF MIDAS | hands | legend | fortune | +25% gold. +10% damage per 100 gold. Kills have 10% chance to turn to coins. |
| `boneamulet` | BONE AMULET | neck | common | malice | 8% of hits curse. |
| `hourglass` | SANDS OF RESPITE | neck | rare | shadow | Rolls recharge 15% faster. Entering a room refunds a roll. |
| `phylactery` | CRACKED PHYLACTERY | neck | legend | malice, bulwark | -1 max heart, but you rise once more this run, and each floor starts with +1 armor. |
| `stormeye` | EYE OF THE GALE | neck | rare | storm | Arcs jump one more time. In a fight, shock the nearest foe every 2s. |
| `emberheart` | EMBER LOCKET | neck | rare | pyre | +10% burn. When hit, set every foe near you ablaze. |
| `wolftooth` | WOLF-TOOTH CHARM | neck | common | blood | +4% crit. Crits on bleeding foes heal 1 half-heart 5% of the time. |
| `frostlocket` | WINTER LOCKET | neck | rare | frost, bulwark | Grants 1 armor. When hit, freeze nearby shots away. |
| `sagestone` | SAGE'S STONE | neck | epic | arcane | +20% experience. Every level-up fires a ring of 16 sparks. |
| `dragonscale` | DRAGONSCALE PENDANT | neck | epic | pyre, fury | +10% damage. Below half health, every 3s a blast of fire around you. |
| `deckpendant` | THE LAST CARD | neck | legend | arcane, fortune | +1 luck. In a fight, draw and play a random card every 8s. |
| `copperband` | COPPER BAND | ring | common | storm | +6% arc chance. |
| `whetband` | WHETSTONE RING | ring | common | edge | Crits deal +0.15x. |
| `cinderring` | CINDER RING | ring | common | pyre | +8% burn chance. |
| `swiftring` | RING OF HASTE | ring | common | shadow | +6% move speed. |
| `goldband` | GOLD BAND | ring | common | fortune | +12% gold. |
| `venomring` | ASP RING | ring | rare | venom | +1 poison on hit. Poisoned foes you kill spread poison to the nearest foe. |
| `bloodring` | BLOOD-PACT RING | ring | rare | blood, malice | +12% damage. Every 4th room costs half a heart. |
| `echoring` | RING OF ECHOES | ring | epic | arcane | 12% chance for shots to cast again. |
| `thornring` | THORNED RING | ring | rare | bulwark | +12 thorns. When hit, +20% damage for 3s. |
| `wispring` | WISP-CALLER RING | ring | rare | swarm | Wisps fire 15% faster. 10% of kills raise a wisp for 5s. |
| `ragering` | RING OF RANCOR | ring | rare | fury | +25% damage while wounded. |
| `bombring` | FUSE RING | ring | rare | demolition | Bombs deal +20%. Clearing a room gives 1 bomb 30% of the time. |
| `seersring` | SEER'S RING | ring | epic | arcane, edge | +8% crit. Shots home in a little. |
| `doomring` | RING OF DOOM | ring | legend | malice | 15% of hits curse. Cursed foes you kill explode for 150%, cursing those nearby. |
| `conclave_gloves` | CONCLAVE GLOVES | hands | rare | arcane | +5% fire rate. |
| `conclave_sigil` | CONCLAVE SIGIL | neck | rare | arcane | +1 projectile. |
| `conclave_ring_a` | CONCLAVE RING OF DUSK | ring | rare | arcane | Shots home in a little. |
| `conclave_ring_b` | CONCLAVE RING OF DAWN | ring | rare | arcane | +1 pierce. |
| `hunt_hood` | HEADHUNTER'S HOOD | head | rare | edge | +5% crit. |
| `hunt_coat` | HEADHUNTER'S COAT | body | rare | edge | +1 max heart. |
| `hunt_gloves` | HEADHUNTER'S GLOVES | hands | rare | edge | Crits deal +0.2x. |
| `hunt_boots` | HEADHUNTER'S BOOTS | feet | rare | edge | +6% move speed. |
| `mirehelm` | MIRE-DIVER'S HELM | head | rare | venom, bulwark | Grants 1 armor. +1 poison on hit. |
| `monkrobe` | MONK'S HABIT | body | rare | shadow, frost | +1 roll charge. Rolling past a close shot chills foes near you. |
| `warcloak` | WAR-TORN CLOAK | body | common | fury | +6% damage. Entering a room gives +20% damage for 5s. |
| `rooftopboots` | ROOFRUNNER BOOTS | feet | rare | shadow | +8% move speed, faster rolls. |
| `eclipsecrown` | CROWN OF THE ECLIPSE | head | legend | malice, arcane | +15% damage. Each floor starts with a scroll (a small permanent boost). |
| `snowtreads` | SNOW TREADS | feet | common | frost | +8% chill chance. |

**New sets** (both use the new slots):

- **CONCLAVE** (`arcane`). 2 pieces: 15% chance for shots to cast again. 4 pieces: Every 6th attack spins out a ring of 8 stars.
- **HEADHUNTER** (`edge`). 2 pieces: +20% damage to elites. 4 pieces: Elite kills pay 8 gold and double crit chance for 5s.

## Batch 4: relics

| Id | Name | Rarity | Tags | What it does |
|---|---|---|---|---|
| `marshreed` | MARSH REED | common | venom | +1 poison on hit |
| `warhorn` | CRACKED WARHORN | common | fury | Entering a room gives +25% fire rate for 4s |
| `prayerflag` | PRAYER FLAG | common | bulwark | +1 max heart |
| `snowglobe` | SNOW GLOBE | common | frost | +15% chill chance |
| `lockpick` | BENT LOCKPICK | common | fortune | +2 keys |
| `spentcasing` | SPENT CASING | common | edge | +8% fire rate and shot speed |
| `candlestub` | CANDLE STUB | common | pyre | +10% burn chance. Burns last longer |
| `ravenquill` | RAVEN QUILL | common | shadow | +10% move speed |
| `copperspool` | COPPER SPOOL | common | storm | Arcs jump one more time |
| `seedpouch` | SEED POUCH | common | swarm | +1 wisp |
| `rooftile` | LOOSE ROOF TILE | common | demolition | Every floor starts with a free bomb |
| `bogwater` | JAR OF BOGWATER | common | venom | Poison deals +25% damage |
| `stillpond` | STILL POND | rare | edge | Standing still, hits deal +30% |
| `bloodmoon` | BLOOD MOON | rare | blood, fury | Below half health: +35% damage |
| `trophyteeth` | STRING OF TROPHY TEETH | rare | bulwark | Killing an elite drops a heart |
| `mudcharm` | MUD-CAKED CHARM | rare | venom, shadow | Rolling poisons every foe near you |
| `ironwill` | IRON WILL | rare | bulwark | When hit, gain 1 armor (every 10s) |
| `tailwind` | TAILWIND | rare | shadow | While moving, hits deal +20% |
| `sparkgap` | SPARK GAP | rare | storm | Hits on shocked foes deal +20% |
| `frozentear` | FROZEN TEAR | rare | frost | 10% of hits on chilled foes shatter, hitting all around them |
| `fielddressing` | FIELD DRESSING | rare | bulwark | Clearing a room heals half a heart 25% of the time |
| `scavsack` | SCAVENGER'S SACK | rare | fortune | Clearing a room drops a potion 12% of the time |
| `kindlingheart` | KINDLING HEART | epic | pyre | 15% of hits on burning foes burst in flame |
| `rotgut` | ROTGUT FLASK | epic | venom | 20% of hits on poisoned foes make them vulnerable |
| `stormglass` | STORM GLASS | epic | storm, edge | Every 5th crit calls lightning |
| `bladeoil` | BLADE OIL | rare | edge, blood | Crits make foes bleed |
| `queensjelly` | QUEEN'S JELLY | epic | swarm | Wisps deal +40%. 5% of kills raise a wisp for 10s |
| `nightshade` | NIGHTSHADE | rare | malice, shadow | Rolling curses the nearest foe |
| `towerbanner` | TOWER BANNER | epic | bulwark | Every point of armor gives +4% damage |
| `heavypurse` | HEAVY PURSE | rare | fortune | +5% damage per 100 gold held |
| `blastingcaps` | BLASTING CAPS | rare | demolition | Bombs deal +30% in a 15% wider blast |
| `echostone` | ECHO STONE | epic | arcane | 10% chance for shots to cast again |
| `loadeddice` | LOADED DICE | epic | fortune, edge | +2 luck. A quarter of your crits hit again |
| `shatteredcrown` | SHATTERED CROWN | epic | malice | +40% damage, but -1 max heart |
| `bloodtithe` | BLOOD TITHE | rare | malice, blood | +25% damage, but 2% of kills cost half a heart |
| `hungeringedge` | HUNGERING EDGE | epic | malice, fury | +30% damage, but half the rooms cost half a heart |
| `cursedcompass` | CURSED COMPASS | rare | malice, fortune | +2 luck, but -10% move speed |
| `leadweight` | LEAD WEIGHT | rare | fury | +30% damage, -15% fire rate |
| `voidpact` | VOID PACT | epic | malice, shadow | +1 roll charge and rolls erase shots, but -1 max heart |
| `warfletching` | WAR FLETCHING | rare | arcane | +1 projectile, -10% damage |
| `monasterybell` | MONASTERY BELL | rare | frost | Entering a room chills every foe near you |
| `alleycateye` | ALLEY CAT'S EYE | rare | shadow, edge | +10% crit chance, 5% dodge chance |
| `eclipseshard` | ECLIPSE SHARD | epic | malice | In a fight, every 10s curse and weaken every foe near you |
| `fallenstar` | HEART OF A FALLEN STAR | legend | arcane | +1 max heart. Every 4th attack fires a ring of 12 stars |
| `crownofash` | CROWN OF ASH | legend | pyre | Every hit burns. Burning foes take +30% damage |
| `mirroredsoul` | MIRRORED SOUL | legend | arcane | 30% chance for shots to cast again |
| `kingsransom` | KING'S RANSOM | legend | fortune | +100 gold now. +15% damage per 100 gold held |
| `undyingember` | EMBER OF THE UNDYING | legend | bulwark | Rise twice more this run |
| `thundertorc` | THUNDERLORD'S TORC | legend | storm | 15% of hits call lightning |
| `hivecrown` | CROWN OF THE HIVE | legend | swarm | +3 wisps. Wisps fire 30% faster |
| `redgodidol` | IDOL OF THE RED GOD | legend | blood | +20% damage. 10% of kills heal half a heart |
