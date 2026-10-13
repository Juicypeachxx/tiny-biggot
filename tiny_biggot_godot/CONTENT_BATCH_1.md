# Content batch 1: Tiny Biggot Rogues

Design spec step 5. This adds 52 weapons, 48 pieces of equipment (with 2 new 4-piece sets), 50 relics, 60 traits, 12 tag synergies and 8 named combos. All of it is data in the existing tables (`scripts/data/*.gd`) and runs on the existing effect system. No new parallel system was added, and no original item was changed or rebalanced.

All names and text are original. **Art:** the new items reuse existing sprites as placeholders (the last column of each row names the sprite), so some new items look like old ones until real art is drawn.

The source of truth is the rows in the data files (each table is marked `Content batch 1`). The lists below are generated from the same data.

## Coverage per archetype

Counts by tag; an item can carry two tags.

| Archetype | Tag | Weapons | Equipment | Relics | Traits |
|---|---|---|---|---|---|
| CRIT | `edge` | 5 | 6 | 5 | 8 |
| BLEED / BLOOD | `blood` | 4 | 3 | 4 | 4 |
| FIRE | `pyre` | 4 | 3 | 4 | 4 |
| POISON | `venom` | 4 | 3 | 4 | 4 |
| LIGHTNING | `storm` | 4 | 3 | 4 | 4 |
| PROJECTILE STORM | `arcane` | 5 | 3 | 4 | 4 |
| SUMMONER | `swarm` | 5 | 3 | 3 | 4 |
| ROLL / EVASION | `shadow` | 4 | 3 | 4 | 4 |
| TANK / THORNS | `bulwark` | 5 | 3 | 4 | 4 |
| BERSERK | `fury` | 5 | 6 | 4 | 8 |
| GREED | `fortune` | 5 | 4 | 5 | 4 |
| CURSE | `malice` | 4 | 4 | 5 | 8 |

## Intended broken combos

The spec asks for a few combos that are meant to be overpowered: high points of a run, not balance mistakes. Each is a named combo in `scripts/data/synergies.gd` and turns on when both parts are owned (a banner shows `COMBO: NAME`). The safety rails (proc depth 4, 200 procs per tick with a queue, 1000 player shots with damage merging, 24 summons) keep each one playable. The content test assembles every combo through the real pickup paths and runs it for 10 s within the frame budget.

To try one on PC: `godot --path . -- --combo=ID` (add `--god` to skip dying). `--give=relic:ID,weapon:ID,gear:ID,trait:ID` hands over any items.

### CHAIN REACTION (`--combo=chainreaction`)

- **Needs:** CAPACITOR CANNON (weapon, epic) + STORM IN A JAR (relic, rare)
- **Combo effect:** Shocked foes you kill call lightning that shocks again.
- **Why it breaks:** A shocked foe you kill calls lightning, and the lightning shocks again. In a dense room one kill can clear the screen. Bounded by proc depth 4 and the 200-per-tick budget, so a chain never runs forever.
- **Playtest:** Does it wipe whole rooms from one kill too early? Lightning damage scale (1.0) and shock stacks (2) are the knobs.

### BLOOD MONEY (`--combo=bloodmoney`)

- **Needs:** CURSED COIN (relic, rare) + DRAGON'S HOARD (relic, legend)
- **Combo effect:** Each room's heart cost pays 5 gold. more gold damage.
- **Why it breaks:** Cursed Coin costs half a heart every room. The combo pays 5 gold for it and adds +10% damage per 100 gold on top of the Hoard's +12%. Gold piles up quickly, so damage grows all run. The price is real: you keep bleeding hearts.
- **Playtest:** Is the scaling silly by floor 5? Is the heart cost still felt? Watch gold totals.

### HALL OF MIRRORS (`--combo=mirrorhall`)

- **Needs:** THOUSAND CUTS (weapon, legend) + PRISM SHARD (relic, rare)
- **Combo effect:** Every shot also fires a ring of 6.
- **Why it breaks:** Every shot also fires a ring of 6 sparks, and the Shard splits them on hit. This is the shot-cap stress case: it fills the screen. Past 1000 live shots, new ones fold their damage into existing shots.
- **Playtest:** Can you still read the enemy shots? Frame rate on the iPad in big rooms.

### DEATH SPIRAL (`--combo=deathspiral`)

- **Needs:** LAST BREATH (relic, legend) + THE KILLING BLOW (relic, legend)
- **Combo effect:** At low health, crits heal and overcrit doubles.
- **Why it breaks:** Below half health you get +100% damage and fire rate from Last Breath. Overcrit goes to +2 (crit chance past 100% crits again, twice). Crits have a 5% chance to heal. Living at low HP becomes the strategy.
- **Playtest:** Is the low-HP window too safe with the heal? The 5% heal chance is the knob.

### THE NIGHTMARE HOST (`--combo=nightmarehost`)

- **Needs:** COURT OF SHADES (weapon, legend) + HIVEMIND (relic, epic)
- **Combo effect:** Every kill raises a wisp.
- **Why it breaks:** Every kill raises a 6-second wisp. Wisps kill, which raises more wisps. Capped at 24 summons.
- **Playtest:** Do the wisps trivialise the bosses? Can you still see your own character?

### Ordinary combos

| Combo | Needs | Effect |
|---|---|---|
| DANCING FLAME (`dancingflame`) | gear:cinderboots, relic:afterimage | Rolling leaves an explosion |
| TOXIC FORTRESS (`toxicwalls`) | relic:spikedcollar, relic:toadstool | When hit, poison the nearest foe heavily |
| GOLDEN DUEL (`goldenduel`) | weapon:gildedrapier, gear:duel_ring | Crits pay 2 gold |

## Tag synergies

These count only new (Rogues) items you own: weapons, equipment, relics, and trait ranks. A tier turns on at 3 and at 6, and turns off again if you drop below.

| Tag | At 3 | At 6 |
|---|---|---|
| `edge` | **KEEN**: +10% crit | **RAZOR'S EDGE**: Crits deal +0.5x |
| `blood` | **BLOODLETTING**: Hits bleed 10% of the time | **RED TIDE**: Kills heal 3% of the time |
| `pyre` | **KINDLED**: +10% burn | **WILDFIRE**: Burning foes spread flame on death |
| `venom` | **TAINTED**: +1 poison on hit | **PLAGUEBRINGER**: Poison damage +50% |
| `storm` | **CHARGED AIR**: +10% arc chance | **THUNDERHEAD**: Every 5s, lightning strikes |
| `arcane` | **SPELLWOVEN**: +1 pierce | **STARFALL**: +1 projectile |
| `swarm` | **FLOCK**: +1 wisp | **LEGION**: Wisps deal +50% |
| `shadow` | **LIGHT FEET**: Rolls recharge 15% faster | **PHANTOM**: +1 roll charge |
| `bulwark` | **STALWART**: +10 thorns | **IRONCLAD**: +1 max heart |
| `fury` | **SEETHING**: +10% damage | **WARLORD**: +15% fire rate |
| `fortune` | **PROSPEROUS**: +15% gold | **MIDAS REACH**: +8% damage per 100 gold |
| `malice` | **DREADFUL**: 10% of hits curse | **UNHOLY**: Cursed foes are vulnerable |

## New equipment sets

- **DUELIST** (`edge`). 2 pieces: +10% crit chance. 4 pieces: Half of your crits strike again for 50%. The 4-piece bonus is an effect list (`e4`, procs allowed), new in `Gear.update_sets`.
- **RAVAGER** (`fury`). 2 pieces: +10% damage. 4 pieces: Below half health: +50% damage, +15% speed. The 4-piece bonus is an effect list (`e4`, procs allowed), new in `Gear.update_sets`.

## Weapons

| Id | Name | Kind | Rarity | Tags | Text |
|---|---|---|---|---|---|
| `needledirk` | NEEDLE DIRK | slash | common | edge | A quick dagger. +10% crit. crits speed up your next stabs. |
| `drifterblade` | DRIFTER'S BLADE | slash | rare | edge | A wanderer's sword. cuts shots. every 5th swing adds a 200% follow-up cut. |
| `deadeyebow` | DEADEYE LONGBOW | bolt | rare | edge | +15% crit, crits deal +0.5x. crits on elites mark them. |
| `mirrorshard` | SHARDS OF THE MIRROR | disc | epic | edge | +20% crit. crit chance past 100% can crit a second time. |
| `truthseeker` | TRUTHSEEKER | rail | legend | edge | +25% crit. every crit detonates the target for 100% damage. |
| `flayinghook` | FLAYING HOOK | whip | common | blood | A barbed lash. 35% of hits make foes bleed. |
| `sanguinering` | SANGUINE CHAKRAM | boomer | rare | blood | Flies out and back. hits bleed. killing a bleeding foe may heal. |
| `pactknives` | PACT KNIVES | bolt | rare | blood | Each room begins with a blood price: lose half a heart, gain +60% damage for 10s. |
| `hemoclaws` | HEMOCLAWS | slash | epic | blood | Twin claws. fast strikes, 20% bleed, 2% of hits heal. |
| `kindlingstaff` | KINDLING STAFF | orb | common | pyre | Bolts often burn. burning foes it kills burst into embers. |
| `magmamaul` | MAGMA MAUL | slash | rare | pyre | A molten hammer. every 3rd swing erupts for 120% damage. |
| `flarepistol` | FLARE PISTOL | burst | rare | pyre | Signal flares that ignite. 15% of hits pop in a small blast. |
| `sunforge` | SUNFORGE HALO | nova | epic | pyre | A ring of fire around you. crits burn twice as long. |
| `sporelauncher` | SPORE LAUNCHER | flask | common | venom | Poison flasks. a poisoned foe it kills infects the nearest foe. |
| `widowneedles` | WIDOW NEEDLES | bolt | rare | venom | A flurry of thin needles that poison. every 10th needle weakens. |
| `blightcenser` | BLIGHT CENSER | pulse | rare | venom | A hovering cloud of rot that poisons everything near it. |
| `serpentspine` | SERPENT SPINE | whip | epic | venom | A long poison lash. poisoned foes it hits may turn vulnerable. |
| `sparkingrod` | SPARKING ROD | zap | common | storm | Instant arcs. 25% of hits shock: shocked foes take more damage. |
| `thunderlance` | THUNDER LANCE | thrust | rare | storm | A long thrust that arcs. every 4th thrust calls lightning. |
| `capacitor` | CAPACITOR CANNON | rail | epic | storm | Each hit shocks twice. shocked foes it kills discharge into others. |
| `stormbreaker` | STORMBREAKER | gatling | legend | storm | A spinning storm. every 15th shot calls lightning and shocks. |
| `scatterwand` | SCATTER WAND | orb | common | arcane | Two bolts per cast. every 6th cast releases a ring of 6 sparks. |
| `prismbow` | PRISM BOW | bolt | rare | arcane | Piercing arrows that split into two when they hit. |
| `orreryblades` | ORRERY OF BLADES | disc | epic | arcane | Three blades that bounce and speed up as they fly. |
| `thousandcuts` | THOUSAND CUTS | burst | legend | arcane | Double bursts that ricochet. 25% of volleys add 2 extra shots. |
| `wispcrook` | WISPHERD'S CROOK | summon | common | swarm | Each shot raises a wisp for 6s. wisps fire 15% faster. |
| `hivelantern` | HIVE LANTERN | boomer | rare | swarm | Flies out and back. 20% of kills raise a wisp for 6s. |
| `bonebell` | BONE BELL | nova | rare | swarm | Rings out shots. every 5th toll raises a wisp for 5s. |
| `courtofshades` | COURT OF SHADES | summon | legend | swarm | Two permanent wisps that hit 50% harder. each room summons two more for 8s. |
| `twinshivs` | TWIN SHIVS | slash | common | shadow | Quick stabs. rolling scatters 6 shivs around you. |
| `smokebow` | SMOKE BOW | bolt | rare | shadow | Rolling erases enemy shots near you. rolls go 10% further. |
| `eclipsescythe` | ECLIPSE SCYTHE | slash | epic | shadow | A huge sweep all around you. kills often refund a roll. |
| `phantomvolley` | PHANTOM VOLLEY | disc | legend | shadow | +1 roll charge. every roll fires 4 full-power discs along your aim. |
| `towershield` | TOWER SHIELD | thrust | common | bulwark | A shield bash that blocks shots in its path. grants 1 armor. |
| `spikedgauntlets` | SPIKED GAUNTLETS | slash | rare | bulwark | +10 thorns. when you are hit, fire 10 spikes around you. |
| `ironwoodstaff` | IRONWOOD STAFF | orb | rare | bulwark | +8% damage per armor. 30% chance to gain 1 armor after each room. |
| `aegisorb` | AEGIS ORB | pulse | epic | bulwark | When hit, erase nearby shots and gain +50% damage for 3s. |
| `ragecleaver` | RAGE CLEAVER | slash | common | fury | +40% damage when wounded. kills give +20% fire rate for 2s. |
| `graveslab` | GRAVESLAB | slash | epic | fury | An absurdly large slab of iron. slow, wide, crushing. kills at low health may heal. |
| `warhornaxe` | WARHORN AXE | spin | rare | fury | When hit, you roar: +50% fire rate for 4s. |
| `frenzychain` | FRENZY CHAIN | whip | rare | fury | Below half health: +40% fire rate and +20% damage. |
| `undyinghatchets` | UNDYING HATCHETS | spin | legend | fury | Two hatchets per throw. below half health your damage doubles. |
| `coincannon` | COIN CANNON | shot | common | fortune | Fires a spray of coins. hits shake out gold and kills pay 1 gold. |
| `gildedrapier` | GILDED RAPIER | slash | rare | fortune | +10% damage per 100 gold held. 10% of crits pay 3 gold. |
| `luckydeck` | LUCKY DECK | disc | rare | fortune | Throws three playing cards. +10% crit. crits pay out 1 gold. |
| `tithescepter` | TITHE SCEPTER | zap | legend | fortune | +20% damage per 100 gold. arcs shake out coins. clearing a room pays 5 gold. |
| `hexsickle` | HEXBOUND SICKLE | slash | common | malice | A wide cut that curses 30% of foes it hits (+25% damage taken). |
| `cursedflintlock` | CURSED FLINTLOCK | rail | rare | malice | -1 max heart while held. cursed foes it hits take a 50% bonus shot. |
| `weepingstaff` | WEEPING IDOL STAFF | orb | epic | malice | +60% damage. 5% of casts draw half a heart of your blood. |
| `doombell` | DOOMSAYER'S KNELL | nova | legend | malice | 40% of hits curse. cursed foes it kills explode for 150% damage. |
| `juggler` | JUGGLER'S PINS | spin | rare | arcane, fortune | Three spinning pins that speed up. every 8th throw tosses a ring of 8. |
| `bannerpike` | RALLYING PIKE | thrust | epic | swarm, bulwark | A wisp follows you. clearing a room raises two wisps for 10s. |

## Equipment

| Id | Name | Slot | Rarity | Tags | Set | Text |
|---|---|---|---|---|---|---|
| `duel_hat` | DUELIST'S FEATHERCAP | head | rare | edge | duelist | +6% crit. |
| `duel_coat` | DUELIST'S DOUBLET | body | rare | edge | duelist | Crits give +10% move speed for 1s. |
| `duel_boots` | DUELIST'S STEPS | feet | rare | edge | duelist | Rolling sharpens you: +15% crit damage for 2s. |
| `duel_ring` | DUELIST'S SIGNET | trinket | epic | edge | duelist | Crits deal +0.3x. |
| `rav_helm` | RAVAGER'S HELM | head | rare | fury | ravager | +1 max heart. |
| `rav_hide` | RAVAGER'S HIDE | body | rare | fury | ravager | +20% damage when wounded. |
| `rav_boots` | RAVAGER'S TREADS | feet | rare | fury | ravager | Kills give +15% move speed for 2s. |
| `rav_tooth` | RAVAGER'S FANG | trinket | epic | fury | ravager | When hit, +30% damage for 3s. |
| `hawkmonocle` | HAWK MONOCLE | head | rare | edge |  | +8% crit. +15% damage from afar. |
| `razorcharm` | RAZOR CHARM | trinket | legend | edge |  | +12% crit. crit chance past 100% can crit again. |
| `leechmail` | LEECH-LINK MAIL | body | rare | blood |  | +1 armor. 1.5% of hits heal. |
| `clotring` | CLOTTING RING | trinket | rare | blood |  | Crits make foes bleed. killing a bleeding foe may heal. |
| `butchermask` | SCARLET HOOD | head | epic | blood |  | +15% damage. each room costs half a heart and gives +30% damage for 12s. |
| `ashcloak` | ASHEN CLOAK | body | rare | pyre |  | Foes near you catch fire. |
| `cinderboots` | CINDER SANDALS | feet | common | pyre |  | Rolling leaves a blast of fire. |
| `kilnheart` | KILN HEART | trinket | epic | pyre |  | Burning foes you kill explode for 80% damage. |
| `rotgloves` | ROTTING WRAPS | body | common | venom |  | +1 poison on hit. |
| `miasmamask` | MIASMA MASK | head | rare | venom |  | +15% damage to afflicted foes. |
| `blightboots` | BLIGHTSTEP BOOTS | feet | rare | venom |  | You leave poison puddles while moving. |
| `conductorhelm` | CONDUCTOR'S HELM | head | rare | storm |  | +10% arc chance, arcs jump 1 further. |
| `staticboots` | STATIC STRIDERS | feet | rare | storm |  | Rolling shocks the nearest foe twice. |
| `lightningrod` | LIGHTNING ROD | trinket | epic | storm |  | Every 4 seconds, lightning strikes the nearest foe. |
| `splittinglens` | SPLITTING LENS | head | rare | arcane |  | Shots split on their first hit. |
| `volleyrobe` | VOLLEY ROBE | body | epic | arcane |  | +1 projectile. |
| `ricochetband` | RICOCHET BAND | trinket | rare | arcane |  | Shots jump to another foe after a hit. |
| `beekeeperhat` | KEEPER'S VEIL | head | common | swarm |  | Wisps deal 20% more. |
| `broodcloak` | BROOD CLOAK | body | rare | swarm |  | When hit, a wisp rises for 8s. |
| `callingwhistle` | CALLING WHISTLE | trinket | epic | swarm |  | +1 wisp. wisps fire 15% faster. |
| `fadingcowl` | FADING COWL | head | rare | shadow |  | 5% dodge. rolling gives +30% damage for 1.5s. |
| `silkboots` | SILKEN SLIPPERS | feet | rare | shadow |  | Rolls recharge faster and go further. |
| `mirrorcape` | MIRROR CAPE | body | epic | shadow |  | +1 roll charge. rolling erases nearby shots. |
| `anvilhelm` | ANVIL HELM | head | rare | bulwark |  | +2 armor. a little slower. |
| `thornplate` | BRAMBLE PLATE | body | rare | bulwark |  | +15 thorns. when hit, fire 6 thorns. |
| `oathstone` | OATHSTONE | trinket | epic | bulwark |  | Clearing a room grants 1 armor. |
| `skullcap` | BATTLE SKULLCAP | head | common | fury |  | +6% damage. below half health, +15% more. |
| `bloodboil` | BLOODBOIL VIAL | trinket | rare | fury |  | Kills give +25% fire rate for 1.5s. |
| `merchantshat` | MERCHANT'S TRICORN | head | rare | fortune |  | +15% gold. clearing a room pays 3 gold. |
| `coinpurse` | BOTTOMLESS PURSE | trinket | rare | fortune |  | Better relics. +5% damage per 100 gold. |
| `goldtoes` | GOLD-TOED BOOTS | feet | common | fortune |  | Shops 8% cheaper. |
| `thornedcrown` | CROWN OF SPITE | head | epic | malice |  | +30% damage but -1 max heart. |
| `hexedmantle` | HEXED MANTLE | body | rare | malice |  | 20% of hits curse foes. |
| `grudgeboots` | GRUDGE BOOTS | feet | rare | malice |  | When hit, curse all... the nearest foe and make it vulnerable. |
| `blackpearl` | BLACK PEARL | trinket | legend | malice |  | -1 max heart. +80% damage. cursed foes you kill explode. |
| `pilgrimpack` | PILGRIM'S PACK | body | common |  |  | +1 potion slot. potions heal more. |
| `luckyhorseshoe` | BENT HORSESHOE | trinket | common | fortune |  | Better relic rarity. 10% of kills pay 1 gold. |
| `scoutboots` | SCOUT'S BOOTS | feet | common |  |  | +10% move speed. |
| `tinkerhelm` | TINKER'S GOGGLES | head | rare | demolition |  | Bigger blasts. clearing a room gives 1 bomb 40% of the time. |
| `frostwardcoat` | FROSTWARD COAT | body | rare | frost |  | +1 armor. +10% chill. when hit, weaken the nearest foe. |

## Relics

| Id | Name | Rarity | Tags | Text |
|---|---|---|---|---|
| `sharpstone` | OILED WHETSTONE | common | edge | +7% crit chance |
| `keeneye` | KEEN EYE | common | edge | Crits deal +0.25x more |
| `firstblood` | FIRST NICK | rare | edge | Crits on unhurt foes deal +60% |
| `hairtrigger` | HAIR TRIGGER | rare | edge | Crits give +20% fire rate for 1s |
| `killingblow` | THE KILLING BLOW | legend | edge | Crit chance past 100% crits again. +20% crit |
| `leechtooth` | LEECH TOOTH | common | blood | Kills on bleeding foes may heal |
| `openwound` | OPEN WOUND | rare | blood | Hits have 20% chance to make foes bleed |
| `bloodprice` | BLOOD PRICE | rare | blood, malice | +35% damage. potions heal 1 heart less |
| `crimsonfont` | CRIMSON FONT | epic | blood | Clearing a room heals half a heart |
| `matchbook` | DAMP MATCHBOOK | common | pyre | +12% burn chance |
| `firework` | FIREWORK | rare | pyre | Burning foes explode when killed |
| `oilflask` | LAMP OIL | rare | pyre | Burns deal +60% damage |
| `phoenixash` | PYRE ASH | epic | pyre | Burning foes take +30% damage. +10% burn |
| `toadstool` | TOADSTOOL | common | venom | Hits add 1 poison |
| `contagion` | CONTAGION | rare | venom | Poisoned foes that die infect the nearest foe |
| `witherroot` | WITHERROOT | rare | venom | Hits on poisoned foes weaken them 15% of the time |
| `blackbile` | BLACK BILE | epic | venom | Poison damage +80%. poison ticks faster |
| `copperwire` | COPPER WIRE | common | storm | +12% chance for hits to arc |
| `stormjar` | STORM IN A JAR | rare | storm | 15% of hits shock. shocked foes take more damage |
| `groundingrod` | GROUNDING SPIKE | rare | storm | Every 5 seconds, lightning strikes the nearest foe |
| `overload` | OVERLOAD COIL | epic | storm | Arcs and lightning +60%. +1 arc jump |
| `mirrorbead` | MIRROR BEAD | common | arcane | +15% shot speed, shots pierce 1 more |
| `prismshard` | PRISM SHARD | rare | arcane | Shots split in two on their first hit |
| `starchart` | STAR CHART | rare | arcane | Every 8th attack fires a ring of 8 sparks |
| `manyhands` | MANY HANDS | epic | arcane | +2 projectiles, -15% damage |
| `glowworm` | GLOW-WORM JAR | common | swarm | Wisps deal +30% damage |
| `broodmother` | BROOD EGG | rare | swarm | 15% of kills raise a wisp for 6s |
| `hivemind` | HIVEMIND | epic | swarm | +1 wisp. wisps fire 30% faster |
| `quickcloak` | QUICKSILVER THREAD | common | shadow | Rolls recharge 20% faster |
| `shadowcut` | SHADOW CUT | rare | shadow | Rolling fires 6 shadow blades around you |
| `afterimage` | AFTERIMAGE | rare | shadow | After a roll, +40% damage for 1.5s |
| `nightveil` | NIGHT VEIL | epic | shadow | +1 roll charge. 10% chance to dodge a hit |
| `ironrations` | IRON RATIONS | common | bulwark | +1 max heart |
| `spikedcollar` | SPIKED COLLAR | rare | bulwark | +15 thorns. when hit, fire 8 spikes |
| `towerkey` | BASTION KEY | rare | bulwark | Clearing a room grants 1 armor 50% of the time |
| `stonehide` | STONEHIDE | epic | bulwark | +2 armor. +6% damage per armor (up to 5) |
| `redmist` | RED MIST | common | fury | Below half health: +25% damage |
| `warpaint` | WAR PAINT | rare | fury | Kills give +30% fire rate for 2s |
| `grudge` | OLD GRUDGE | rare | fury | When hit, +60% damage for 4s |
| `lastbreath` | LAST BREATH | legend | fury | Below half health: +100% damage, +30% fire rate, +20% speed |
| `copperpenny` | LUCKY PENNY | common | fortune | Kills have 15% chance to pay 1 gold |
| `goldtongue` | GOLDEN TONGUE | rare | fortune | Shops 15% cheaper, +20% gold |
| `ledgerofdebt` | LEDGER OF DEBTS | rare | fortune | +1% damage for every 10 gold held |
| `dragonhoard` | DRAGON'S HOARD | legend | fortune | +12% damage per 100 gold. clearing a room pays 8 gold |
| `evileye` | EVIL EYE | common | malice | 15% of hits curse foes (+25% damage taken) |
| `bargain` | DEVIL'S BARGAIN | epic | malice | +70% damage. -1 max heart |
| `cursedcoin` | CURSED COIN | rare | malice, fortune | +50% gold, but each room costs half a heart |
| `voidheart` | VOID HEART | legend | malice | Cursed foes take a 60% bonus hit from everything. 25% of hits curse |
| `wanderersmap` | WANDERER'S MAP | common |  | Hidden walls glow. +1 key |
| `emptyflask` | BOTTOMLESS FLASK | rare |  | +1 potion slot. clearing a room may drop a potion |

## Traits

| Id | Name | Family | Max rank | Rarity | Text |
|---|---|---|---|---|---|
| `e_steady` | STEADY AIM | edge | 4 | common | +5% crit chance |
| `e_deep` | DEEP CUTS | edge | 3 | common | Crits deal +0.3x more. rank 3: +0.5x more |
| `e_momentum` | MOMENTUM | edge | 3 | uncommon | Crits give +10% fire rate for 1s |
| `e_exploit` | EXPLOIT | edge | 2 | uncommon | Crits make foes vulnerable 30% of the time |
| `e_cascade` | CRIT CASCADE | edge | 2 | rare | Crits have 25% chance to arc to a nearby foe |
| `e_precise` | PRECISE FOOTWORK | edge | 3 | uncommon | +3% crit. rolling gives +10% crit for 2s |
| `e_overcrit` | OVERCRIT | edge | 1 | legend | Crit chance past 100% crits again for double |
| `e_glass` | GLASS EDGE | edge | 1 | cursed | +25% crit, crits +1x. -1 max heart |
| `f_anger` | SHORT TEMPER | fury | 4 | common | When hit, +20% damage for 3s |
| `f_bloodlust` | BLOODLUST | fury | 3 | common | Kills give +10% fire rate for 2s |
| `f_desperate` | BACK TO THE WALL | fury | 3 | uncommon | +10% damage for each missing heart |
| `f_berserk` | BERSERK | fury | 3 | uncommon | Below half health: +20% damage and +10% speed |
| `f_thickskull` | THICK SKULL | fury | 2 | common | +1 max heart, +8% damage |
| `f_rampage` | RAMPAGE | fury | 2 | rare | Kills have 15% chance to refund a roll |
| `f_unstoppable` | UNSTOPPABLE | fury | 1 | legend | Below half health, kills heal 10% of the time |
| `f_frenzied` | BLIND FRENZY | fury | 1 | cursed | +40% fire rate. -20% shot speed |
| `m_hex` | LINGERING HEX | malice | 4 | common | 10% of hits curse foes |
| `m_spite` | SPITE | malice | 3 | uncommon | Hits on cursed foes deal a 20% bonus hit |
| `m_doom` | DOOM | malice | 2 | rare | Cursed foes that die explode |
| `m_bargain` | DARK BARGAIN | malice | 3 | cursed | +20% damage. each room costs half a heart |
| `m_hunger` | SOUL HUNGER | malice | 2 | uncommon | Killing a cursed foe gives +20% damage for 3s |
| `m_blight` | BLIGHTED TOUCH | malice | 2 | common | Cursed foes are also poisoned |
| `m_martyr` | MARTYR | malice | 1 | cursed | -1 max heart. when hit, every foe nearby is cursed and vulnerable... the nearest |
| `m_pact` | INFERNAL PACT | malice | 1 | legend | +80% damage. healing is halved... potions heal 1 less |
| `b_haemo` | HAEMORRHAGE | blood | 3 | common | 15% of hits make foes bleed |
| `b_transfuse` | TRANSFUSION | blood | 2 | uncommon | Killing a bleeding foe may heal |
| `b_offering` | BLOOD OFFERING | blood | 2 | rare | Each room costs half a heart for +40% damage for 10s |
| `b_vein` | OPEN VEINS | blood | 1 | legend | Bleeding foes take a 30% bonus hit from crits |
| `p_tinder` | TINDER | pyre | 3 | common | +8% burn chance |
| `p_ignite` | IGNITION | pyre | 2 | uncommon | Kills on burning foes explode |
| `p_ember` | EMBERSTORM | pyre | 2 | rare | Every 3 seconds, a burst of fire around you |
| `p_wildfire` | FIRESTORM | pyre | 1 | legend | Crits set foes ablaze and blast them |
| `v_sting` | STINGER | venom | 3 | common | 10% of hits add 2 extra poison |
| `v_spread` | PESTILENCE | venom | 2 | uncommon | Poisoned foes that die infect the nearest |
| `v_frail` | FRAILTY | venom | 2 | uncommon | Hits on poisoned foes weaken them 10% of the time |
| `v_toxic` | TOXIC BLOOM | venom | 1 | rare | Every 4 seconds, poison the nearest foe heavily |
| `s_charge` | CHARGED | storm | 3 | common | 10% of hits shock |
| `s_surge` | SURGE | storm | 2 | uncommon | Killing a shocked foe calls lightning |
| `s_static` | STATIC FIELD | storm | 2 | rare | Every 6 seconds, lightning strikes the nearest foe |
| `s_dynamo` | DYNAMO | storm | 1 | legend | +25% fire rate. shock stacks faster |
| `a_fork` | FORKING | arcane | 2 | rare | Shots split on their first hit |
| `a_ricochet` | BANK SHOT | arcane | 2 | uncommon | Shots jump to 1 more foe |
| `a_salvo` | SALVO | arcane | 3 | uncommon | Every 10th attack fires 6 extra shots |
| `a_storm` | BULLET STORM | arcane | 1 | legend | +2 projectiles. -20% damage |
| `w_call` | SPIRIT CALL | swarm | 2 | common | 10% of kills raise a wisp for 6s |
| `w_guard` | GUARDIAN SPIRITS | swarm | 2 | uncommon | When hit, raise a wisp for 8s |
| `w_choir` | CHOIR | swarm | 3 | common | Wisps deal +25% damage and fire 10% faster |
| `w_host` | THE HOST | swarm | 1 | legend | Each room begins with 3 wisps for 10s |
| `sh_blur` | BLUR | shadow | 3 | common | After a roll, +20% damage for 1s |
| `sh_knives` | SHADOW KNIVES | shadow | 2 | uncommon | Rolling throws 4 knives around you |
| `sh_vanish` | VANISH | shadow | 2 | rare | Rolling erases nearby shots |
| `sh_dance` | DEATH DANCE | shadow | 1 | legend | +1 roll charge. kills have 20% chance to refund a roll |
| `t_brace` | BRACE | bulwark | 3 | common | Clearing a room grants 1 armor 25% of the time |
| `t_retort` | RETORT | bulwark | 2 | uncommon | When hit, fire 8 spikes around you |
| `t_hulk` | HULKING | bulwark | 2 | common | +1 max heart. +10 thorns |
| `t_aegis` | LIVING AEGIS | bulwark | 1 | legend | When hit, erase nearby shots and gain +40% damage for 4s |
| `g_skim` | SKIMMING | fortune | 3 | common | Kills have 10% chance to pay 1 gold |
| `g_bounty` | BOUNTY HUNTER | fortune | 2 | uncommon | Killing an elite pays 10 gold |
| `g_invest` | INVESTMENT | fortune | 2 | uncommon | Clearing a room pays 4 gold |
| `g_goldblood` | GOLDEN BLOOD | fortune | 1 | legend | +1% damage for every 10 gold held. crits pay 1 gold |

## How this was tested

- **Content test** (`tests/content_test.tscn`, run by `tools/check.sh`). It covers:
  - Lint: unique ids per table, known stats, ops, triggers, actions, statuses and conditions, sprites, tags, rarities, set e2/e4 effects, and every shown string checked against the bitmap font.
  - Every one of the 703 items equipped live and fired.
  - Weapon and gear swaps restore the player exactly.
  - Rails, leveling and coverage of all 12 archetypes.
  - An 84-rank broken build, every named combo assembled and run for 10 s, and a 600-shot stress test.
- **Originals unchanged**:
  - `tools/replay.sh` first runs six 5-minute seeded autopilot scenarios with `--classic` (only the original items in every pool). They must match `tests/replays/classic/`, which was recorded before batch 1 existed, byte for byte, and they do.
  - The effects test still matches the Ruby original for 2424 item applications.
- **Full pools**: the same six scenarios without `--classic` are recorded in `tests/replays/` and repeat exactly, so a run with new content is deterministic too.
- **Soak**: three 15-minute autopilot runs over the full pools reached floor 4 with 0 script errors.
- **Not tested**: balance and feel. That is what the playtest is for. Touch on a real iPad also still needs checking.
