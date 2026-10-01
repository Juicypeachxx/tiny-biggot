# Step 8: more content, in batches

Design spec step 8 adds the remaining content in batches of about 50, with the content test run after each. Every item is data in the existing tables and uses the existing effect system. Original items are untouched, and the `--classic` replays prove it after every batch.

**Quality over quantity:** the spec allows stopping below 400 per type if items stop being distinct. Each item below has its own hook (a trigger, an interaction or a niche), not just bigger numbers. **Art:** new items reuse existing sprites as placeholders.

## Equipment slots

Gloves, an amulet and two ring slots join the original helm, armor, boots and trinket. A ring takes a free ring slot, otherwise it replaces the lower-rarity ring. Original items keep their slots (the original game's rings and amulets stay trinkets). `--classic` keeps the four original slots.

## Batch 2: 52 weapons

| Id | Name | Type | Rarity | Tags | What it does |
|---|---|---|---|---|---|
| `bogpump` | BOG PUMP | flame | common | venom | Sprays stinking mire water. every hit poisons. |
| `leechlance` | LEECHING LANCE | thrust | rare | blood | A hollow lance that drinks. 2% of hits heal. +30% damage to afflicted foes. |
| `frogspawn` | FROGSPAWN SATCHEL | mine | common | venom, swarm | Tosses egg clusters that burst. 15% of kills hatch a wisp for 4s. |
| `witchlight` | WITCH-LIGHT LANTERN | pulse | rare | arcane, venom | A slow green light that poisons all it touches. every 3rd light also throws 4 sparks. |
| `rainmaker` | RAINMAKER'S ROD | zap | epic | storm | Arcs jump 3 times. in a fight, calls lightning every 3 seconds. |
| `warbow` | WARBOW | bolt | common | edge | A heavy bow. +5% crit. arrows pierce one foe. |
| `volleybow` | VOLLEY BOW | bolt | rare | arcane | Looses five arrows in a tight fan. |
| `firepot` | FIREPOT SLING | flask | common | pyre | Throws clay pots of burning pitch. 25% burn chance. |
| `siegearbalest` | SIEGE ARBALEST | rail | rare | bulwark | Slow, crushing bolts that hurl foes back. clearing a room gives 1 armor. |
| `bannermaul` | BANNER MAUL | slash | epic | fury, bulwark | +25% damage at full health. every kill gives +10% fire rate for 3s. |
| `cinderwhip` | CINDER WHIP | whip | rare | pyre | The tip sets foes alight. burning foes you kill explode for 80%. |
| `scorchcannon` | SCORCH CANNON | gatling | epic | pyre | Spins up into a stream of embers. every 20th shot is a bursting fireball. |
| `ironpike` | IRON PIKE | thrust | common | bulwark | A long, wide pike. grants 1 armor. |
| `prayerbeads` | PRAYER BEADS | nova | rare | arcane | A ring of 14 beads. rolling casts an extra ring of 10. |
| `frostfang` | FROSTBITE FANG | slash | common | frost | Quick cuts that chill. chilled foes take +20% damage. |
| `avalanche` | AVALANCHE STAFF | orb | epic | frost | Huge, slow snowballs. a chilled foe you kill bursts, hitting all around it. |
| `quarterstaff` | MONK'S QUARTERSTAFF | thrust | rare | shadow | A broad sweeping staff. rolling gives +40% damage for 2s. |
| `templebell` | TEMPLE BELL | pulse | rare | bulwark | A big, slow toll. when you are hit it rings: 12 shots around you. |
| `iciclerepeater` | ICICLE REPEATER | bolt | common | frost | Rapid shards of ice. 15% chill chance. |
| `stillwater` | BLADE OF STILL WATER | slash | legend | edge, shadow | +15% crit. standing still, hits strike again for 50%. rolling past a close shot gives +100% damage for 2s. |
| `sixshooter` | SIX-SHOOTER | burst | common | edge | +8% crit. every 6th shot adds a slug for 300% to the nearest foe. |
| `alleyscatter` | ALLEY SCATTERGUN | shot | common | fury | Six pellets at once. devastating up close. |
| `throwknives` | THROWING KNIVES | bolt | rare | shadow, edge | Pairs of knives. +10% crit. kills refund a roll. |
| `drumgun` | DRUM GUN | gatling | rare | fortune | A chattering street gun. 10% of kills drop a coin. |
| `grapnel` | GRAPPLING HOOK | whip | rare | shadow | A very long reach. 30% of hits mark the foe: marked foes take more damage. |
| `smokecharges` | SMOKE CHARGES | mine | rare | shadow | Traps that burst. rolling erases shots around you (every 4s). |
| `goldengun` | GOLDEN GUN | rail | legend | fortune, edge | One shot, one kill. +20% crit. kills pay 3 gold. +10% damage per 100 gold. |
| `crowcaller` | CROWCALLER | summon | rare | swarm | Each shot raises a crow-spirit. 20% of kills call another for 5s. |
| `lampflamer` | STREETLAMP FLAMER | flame | rare | pyre | A short, hot cone. burning foes take +25% damage. |
| `voidray` | VOID RAY | beam | epic | malice, arcane | A constant dark ray. 10% of hits curse and weaken the foe. |
| `eclipseorb` | ECLIPSE ORB | pulse | legend | malice, storm | A slow black sun that hurts all it touches. every kill calls lightning on another foe. |
| `umbralscythe` | UMBRAL SCYTHE | slash | rare | malice, blood | A huge sweep. 10% of hits curse. killing a cursed foe may heal half a heart. |
| `starfall` | STARFALL CHIME | nova | epic | arcane, storm | A ring of 12. every 4th chime arcs lightning through nearby foes. |
| `hexchain` | HEX CHAIN | whip | common | malice | A chain of small curses. 15% of hits curse: cursed foes take +25%. |
| `riftcannon` | RIFT CANNON | rail | epic | arcane | Each hit tears a small rift that blasts everything near the foe. |
| `bloodletter` | BLOODLETTER | disc | rare | blood | Discs that bounce 4 times. 25% of hits bleed. |
| `bonesaw` | BONE SAW | spin | common | blood | A spinning saw that cuts through three foes. |
| `nightwing` | NIGHT-WING STAFF | summon | epic | swarm, blood | Each shot raises a spirit. +1 wisp. 5% of kills heal half a heart. |
| `hivecannon` | HIVE CANNON | flask | epic | swarm, venom | Lobs hives that burst and poison. 30% of hits release a wisp for 4s. |
| `shieldcannon` | SHIELD CANNON | rail | epic | bulwark | Grants 2 armor. when you are hit, fire a ring of 12 shots. |
| `briarspear` | BRIAR SPEAR | thrust | rare | bulwark, venom | +15 thorns. thrusts poison. |
| `tumbleredge` | TUMBLER'S EDGE | slash | common | shadow | Rolling sends out a ring of 6 blades (every 1.5s). |
| `phantombow` | PHANTOM BOW | bolt | epic | shadow, arcane | Homing ghost arrows. after a roll, +50% damage for 2s. |
| `skullsplitter` | SKULLSPLITTER | spin | rare | fury | Heavy axes. below half health they fly 40% faster. |
| `wrathbuss` | WRATH BLUNDERBUSS | shot | epic | fury | Seven pellets. taking a hit gives +50% damage for 4s. |
| `flippedcoin` | FLIPPED COIN | disc | common | fortune | +1 luck. half of your crits pay 1 gold. |
| `taxbell` | TAXMAN'S BELL | nova | rare | fortune | A ring of 10. clearing a room pays 4 gold. elite kills pay 6. |
| `thornidol` | IDOL OF THORNS | orb | rare | malice, bulwark | +10 thorns. each room costs half a heart and gives +40% damage for 15s. |
| `arcsprayer` | ARC SPRAYER | flame | epic | storm | A hissing cone of sparks. 15% arc chance. some hits shock. |
| `thunderdrum` | THUNDER DRUM | pulse | legend | storm, fury | Every hit shocks. shocked foes you kill erupt into 8 sparks. |
| `powdermortar` | POWDER MORTAR | flask | rare | demolition | Big bursting shells. +25% bomb radius. 5% of kills drop a bomb. |
| `deadfall` | DEADFALL TRAPS | mine | epic | demolition, bulwark | Heavy traps. when you are hit, gain a bomb (every 8s). |
