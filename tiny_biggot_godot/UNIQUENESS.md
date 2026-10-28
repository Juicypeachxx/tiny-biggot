# Uniqueness: what every weapon, relic and gear piece does

Made by `tests/uniqueness_report.tscn` from the game's data (ROADMAP 4.1). Do not edit by hand:
run it again after changing items. Numbers are left out on purpose: two swords that differ by
10% damage are one sword. ORIGINAL items are the classic game and are not changed.
Not seen by the signature: what a hero does with a signature weapon (`Weapons.HERO_WEAPON`),
and the look of an attack. A gear piece's set counts for "same", not for "near".

- **Same**: identical signatures.
- **Near**: the same once it is set aside how much, and in which way, a stat is changed; for a
  weapon also which plain stats it gives (same attack kind, mechanics and triggered effects).
- **Numbers only**: no triggered effect, no hook and (weapons) no mechanic of its own beyond its
  attack kind: it only changes numbers.

| | Items | Original | New | In a "same" group | In a "near" group | New items in a "near" group | Numbers only (new) |
|---|---|---|---|---|---|---|---|
| Weapons | 352 | 113 | 239 | 4 | 33 | 4 | 65 (31) |
| Relics | 193 | 66 | 127 | 6 | 6 | 0 | 48 (0) |
| Gear | 271 | 96 | 175 | 0 | 10 | 0 | 46 (0) |

## Weapons

### Same signature (2 groups)

- 2: `thrust |  |  |  | `  
  pike (ORIGINAL), warlance
- 2: `whip |  |  |  | `  
  drovewhip (ORIGINAL), shackleflail

### Near (13 groups)

- 4: `whip |  |  | `  
  drovewhip (ORIGINAL), bramblewhip (ORIGINAL), lightninglash (ORIGINAL), shackleflail
- 3: `flame |  |  | `  
  firespitter (ORIGINAL), bilesprayer (ORIGINAL), frostbellows (ORIGINAL)
- 3: `flask |  |  | `  
  flasksling (ORIGINAL), firebottle (ORIGINAL), frostvial (ORIGINAL)
- 3: `orb |  |  | `  
  hexwand (ORIGINAL), emberwand (ORIGINAL), rimerod (ORIGINAL)
- 3: `pulse |  |  | `  
  emberorb (ORIGINAL), frozenheart (ORIGINAL), plaguebell (ORIGINAL)
- 3: `summon |  |  | `  
  gravebell (ORIGINAL), hivestaff (ORIGINAL), warbanner (ORIGINAL)
- 2: `disc |  |  | `  
  sawblade (ORIGINAL), thunderring (ORIGINAL)
- 2: `gatling |  |  | `  
  crankgun (ORIGINAL), sunspitter (ORIGINAL)
- 2: `mine |  |  | `  
  snaremine (ORIGINAL), frosttrap (ORIGINAL)
- 2: `nova | count+ |  | `  
  frostbloom (ORIGINAL), thorntome (ORIGINAL)
- 2: `slash |  |  | `  
  rustblade (ORIGINAL), banesabre
- 2: `slash |  | parry | `  
  sabre (ORIGINAL), wayfareredge
- 2: `thrust |  |  | `  
  pike (ORIGINAL), warlance

### Numbers only (65, 31 of them new)

hexwand (ORIGINAL), emberwand (ORIGINAL), rimerod (ORIGINAL), pithatchet (ORIGINAL), graveshovel (ORIGINAL), flasksling (ORIGINAL), firebottle (ORIGINAL), frostvial (ORIGINAL), lantern (ORIGINAL), rustblade (ORIGINAL), pike (ORIGINAL), prismrod (ORIGINAL), firespitter (ORIGINAL), bilesprayer (ORIGINAL), frostbellows (ORIGINAL), sawblade (ORIGINAL), thunderring (ORIGINAL), emberorb (ORIGINAL), frozenheart (ORIGINAL), plaguebell (ORIGINAL), sparkrune (ORIGINAL), bonechime (ORIGINAL), snaremine (ORIGINAL), frosttrap (ORIGINAL), arbalest (ORIGINAL), burstpistol (ORIGINAL), crankgun (ORIGINAL), sunspitter (ORIGINAL), drovewhip (ORIGINAL), bramblewhip (ORIGINAL), lightninglash (ORIGINAL), gravebell (ORIGINAL), hivestaff (ORIGINAL), warbanner (ORIGINAL), banesabre, shackleflail, warlance, swarmpod, pocketmortar, signalflare, dynamite, repulsor, plasmaslug, quakemaul, dashblade, warjavelin, grapple, steamrepeater, starcaller, snapback, bubbleblaster, flakpistol, slotpistol, snowroller, paydaycannon, flashcamera, glacierray, junkcannon, homerunbat, backstabdirk, callingcard, shrinkray, leafblower, aegisprojector, coinflipper

### Every weapon

| id | name | | signature |
|---|---|---|---|
| repeater | REPEATER | ORIGINAL | `bolt | pierce |  |  | ` |
| huntbow | HUNTING BOW | ORIGINAL | `bolt |  |  | far_dmg | ` |
| streetpistol | STREET PISTOL | ORIGINAL | `bolt |  |  | nth_big | ` |
| silvercrossbow | SILVERED CROSSBOW | ORIGINAL | `bolt | pierce |  | elite_dmg | ` |
| longrifle | LONG RIFLE | ORIGINAL | `bolt | pierce |  | still_dmg | ` |
| thornbow | THORNBOW | ORIGINAL | `bolt |  | poison | split | ` |
| sunpiercer | SUNPIERCER | ORIGINAL | `bolt | pierce | burn | nth_nova | ` |
| hexwand | HEX WAND | ORIGINAL | `orb |  |  |  | ` |
| emberwand | EMBER WAND | ORIGINAL | `orb |  | burn |  | ` |
| rimerod | RIME ROD | ORIGINAL | `orb |  | chill |  | ` |
| witchstaff | WITCHWOOD STAFF | ORIGINAL | `orb |  |  | mark | ` |
| stormcaller | STORMCALLER | ORIGINAL | `orb |  | chain | nth_zap | ` |
| soulstaff | SOULREAVER STAFF | ORIGINAL | `orb |  |  | souls | ` |
| laststar | THE LAST STAR | ORIGINAL | `orb |  |  | grow,split | ` |
| pithatchet | PIT HATCHET | ORIGINAL | `spin |  |  |  | ` |
| woodaxe | WOODSMAN'S AXE | ORIGINAL | `spin |  |  | knock | ` |
| bonecleaver | BONE CLEAVER | ORIGINAL | `spin |  |  | execute | ` |
| tomahawk | FEATHERED TOMAHAWK | ORIGINAL | `spin |  |  | kill_wisp | ` |
| ragefang | RAGEFANG AXE | ORIGINAL | `spin |  |  | kill_haste,low_hp_dmg | ` |
| twincrescent | TWIN CRESCENTS | ORIGINAL | `spin | count+,pierce+ |  | accel | ` |
| graveshovel | GRAVE SHOVEL | ORIGINAL | `shot |  |  |  | ` |
| blunderbuss | BLUNDERBUSS | ORIGINAL | `shot | count+ |  | close_dmg | ` |
| sawnoff | SAWN-OFF | ORIGINAL | `shot | count+ |  | close_dmg,knock | ` |
| nailspitter | NAIL SPITTER | ORIGINAL | `shot | count+ | poison | shred | ` |
| hailcannon | HAILSTORM CANNON | ORIGINAL | `shot | count+ | chill | status_dmg | ` |
| dragonbreath | DRAGON'S BREATH | ORIGINAL | `shot | count+ | burn | kill_explode | ` |
| flasksling | FLASK SLING | ORIGINAL | `flask |  | explode,poison |  | ` |
| firebottle | FIREBOTTLE | ORIGINAL | `flask |  | burn,explode |  | ` |
| acidjar | ACID JAR | ORIGINAL | `flask |  | explode,poison | shred | ` |
| frostvial | FROST VIAL | ORIGINAL | `flask |  | chill,explode |  | ` |
| bottledstorm | BOTTLED STORM | ORIGINAL | `flask |  | chain,explode | nth_zap | ` |
| panacea | PANACEA | ORIGINAL | `flask |  | explode | leech,status_dmg | ` |
| lantern | WARDEN'S LANTERN | ORIGINAL | `boomer |  |  |  | ` |
| boomerang | HUNTER'S BOOMERANG | ORIGINAL | `boomer |  |  | gold_hit | ` |
| chakram | ROVING CHAKRAM | ORIGINAL | `boomer |  |  | accel,mark | ` |
| reaperhook | REAPER'S HOOK | ORIGINAL | `boomer |  |  | execute,kill_roll | ` |
| sunlantern | SUNLANTERN | ORIGINAL | `boomer |  | burn | nth_nova | ` |
| moonglaive | MOONGLAIVE | ORIGINAL | `boomer | count+ | chill | split | ` |
| rustblade | RUSTED BLADE | ORIGINAL | `slash |  |  |  | ` |
| sabre | DUELIST SABRE | ORIGINAL | `slash |  |  | parry | ` |
| wandererkatana | WANDERER'S KATANA | ORIGINAL | `slash |  |  | first_hit,parry | ` |
| huntsword | SILVER HUNTSWORD | ORIGINAL | `slash |  |  | elite_dmg,status_dmg | ` |
| gallows | GALLOWS GREATSWORD | ORIGINAL | `slash |  |  | knock,low_hp_dmg | ` |
| cinderbrand | CINDERBRAND | ORIGINAL | `slash |  | burn | kill_explode | ` |
| mirrorblade | MIRRORBLADE | ORIGINAL | `slash |  |  | parry,reflect | ` |
| pike | FOOTMAN'S PIKE | ORIGINAL | `thrust |  |  |  | ` |
| boarspear | BOAR SPEAR | ORIGINAL | `thrust |  | armor | knock | ` |
| halberd | WATCHMAN'S HALBERD | ORIGINAL | `thrust |  |  | parry | ` |
| tidetrident | TIDECALLER TRIDENT | ORIGINAL | `thrust | count+ | chill |  | ` |
| serpentlance | SERPENT LANCE | ORIGINAL | `thrust |  | poison | pierce_dmg | ` |
| stormspear | STORMSPEAR | ORIGINAL | `thrust |  | chain | nth_zap | ` |
| prismrod | PRISM ROD | ORIGINAL | `beam |  |  |  | ` |
| burninglens | BURNING LENS | ORIGINAL | `beam |  | burn | still_dmg | ` |
| leechrod | LEECHING ROD | ORIGINAL | `beam |  |  | leech | ` |
| winterbreath | WINTER'S BREATH | ORIGINAL | `beam |  | chill | status_dmg | ` |
| voidlight | VOIDLIGHT | ORIGINAL | `beam | pierce |  | mark | ` |
| judgement | JUDGEMENT RAY | ORIGINAL | `beam | pierce |  | gold_dmg,gold_hit | ` |
| firespitter | FIRE SPITTER | ORIGINAL | `flame |  | burn |  | ` |
| bilesprayer | BILE SPRAYER | ORIGINAL | `flame |  | poison |  | ` |
| frostbellows | FROST BELLOWS | ORIGINAL | `flame |  | chill |  | ` |
| locustcenser | LOCUST CENSER | ORIGINAL | `flame |  |  | kill_wisp | ` |
| hellmaw | HELLMAW | ORIGINAL | `flame |  | burn | close_dmg | ` |
| phoenixbellows | PHOENIX BELLOWS | ORIGINAL | `flame |  | burn | kill_explode,kill_heal | ` |
| sawblade | SAWBLADE | ORIGINAL | `disc |  |  |  | ` |
| razordisc | RAZOR DISC | ORIGINAL | `disc |  |  | shred | ` |
| doubloon | LUCKY DOUBLOON | ORIGINAL | `disc |  | ricochet | gold_hit | ` |
| thunderring | THUNDER RING | ORIGINAL | `disc |  | chain |  | ` |
| nightstar | NIGHT STARS | ORIGINAL | `disc | count+ |  | first_hit | ` |
| worldeater | WORLD-EATER | ORIGINAL | `disc | bounce+ |  | crit_explode,grow | ` |
| emberorb | EMBER ORB | ORIGINAL | `pulse |  | burn |  | ` |
| frozenheart | FROZEN HEART | ORIGINAL | `pulse |  | chill |  | ` |
| plaguebell | PLAGUE BELL | ORIGINAL | `pulse |  | poison |  | ` |
| gravitywell | GRAVITY WELL | ORIGINAL | `pulse |  |  | linger | ` |
| blacksun | BLACK SUN | ORIGINAL | `pulse |  |  | linger,souls | ` |
| sparkrune | SPARK RUNE | ORIGINAL | `zap |  |  |  | ` |
| coppercoil | COPPER COIL | ORIGINAL | `zap |  |  | nth_zap | ` |
| maledict | MALEDICTION RUNE | ORIGINAL | `zap |  |  | mark | ` |
| stormgauntlet | STORM GAUNTLET | ORIGINAL | `zap | chain+ |  | status_dmg | ` |
| heavensrod | HEAVEN'S ROD | ORIGINAL | `zap | chain+ | crit | crit_explode | ` |
| bonechime | BONE CHIME | ORIGINAL | `nova |  |  |  | ` |
| frostbloom | FROST BLOOM | ORIGINAL | `nova | count+ | chill |  | ` |
| bloodstar | BLOOD STAR | ORIGINAL | `nova |  |  | low_hp_dmg | ` |
| thorntome | TOME OF THORNS | ORIGINAL | `nova | count+ | poison |  | ` |
| cataclysm | CATACLYSM | ORIGINAL | `nova | count+ |  | kill_explode,roll_nova | ` |
| snaremine | SNARE MINES | ORIGINAL | `mine |  |  |  | ` |
| frosttrap | FROST TRAP | ORIGINAL | `mine |  | chill |  | ` |
| spiketrap | SPIKE TRAP | ORIGINAL | `mine |  |  | execute | ` |
| hivepod | HIVE POD | ORIGINAL | `mine |  |  | kill_wisp | ` |
| doomspring | DOOMSPRING | ORIGINAL | `mine |  |  | crit_explode,kill_explode | ` |
| arbalest | ARBALEST | ORIGINAL | `rail |  |  |  | ` |
| harpoon | WHALING HARPOON | ORIGINAL | `rail |  | chill | knock | ` |
| handcannon | HAND CANNON | ORIGINAL | `rail |  | crit | crit_explode | ` |
| dawnlance | LANCE OF DAWN | ORIGINAL | `rail |  |  | nth_nova | ` |
| deicide | DEICIDE | ORIGINAL | `rail |  |  | boss_dmg,execute | ` |
| burstpistol | THREE-ROUND PISTOL | ORIGINAL | `burst |  |  |  | ` |
| alleysprayer | ALLEY SPRAYER | ORIGINAL | `burst |  |  | moving_dmg | ` |
| triplecrossbow | TRIPLE CROSSBOW | ORIGINAL | `burst |  | pierce | pierce_dmg | ` |
| gildedrevolver | GILDED REVOLVER | ORIGINAL | `burst |  |  | gold_dmg,gold_hit | ` |
| hailfire | HAILFIRE | ORIGINAL | `burst |  | count | moving_dmg,nth_zap | ` |
| crankgun | CRANK GUN | ORIGINAL | `gatling |  |  |  | ` |
| rotarybow | ROTARY BOW | ORIGINAL | `gatling |  |  | kill_wisp | ` |
| bonegrinder | BONEGRINDER | ORIGINAL | `gatling |  |  | shred | ` |
| sunspitter | SUNSPITTER | ORIGINAL | `gatling |  | burn |  | ` |
| dreadnought | DREADNOUGHT | ORIGINAL | `gatling |  | armor | armor_dmg | ` |
| drovewhip | DROVER'S WHIP | ORIGINAL | `whip |  |  |  | ` |
| chainlash | CHAIN LASH | ORIGINAL | `whip |  |  | parry | ` |
| bramblewhip | BRAMBLE WHIP | ORIGINAL | `whip |  | poison |  | ` |
| lightninglash | LIGHTNING LASH | ORIGINAL | `whip |  | chain |  | ` |
| bloodvine | BLOODVINE | ORIGINAL | `whip |  |  | execute,leech | ` |
| gravebell | GRAVE BELL | ORIGINAL | `summon |  |  |  | ` |
| hivestaff | HIVE STAFF | ORIGINAL | `summon |  | fam_rate |  | ` |
| bonetome | BONE TOME | ORIGINAL | `summon |  | familiars | kill_wisp | ` |
| warbanner | WARBANNER | ORIGINAL | `summon |  | fam_dmg,familiars |  | ` |
| needledirk | NEEDLE DIRK | new | `slash |  | crit |  | on_crit>buff:rate` |
| drifterblade | DRIFTER'S BLADE | new | `slash |  | crit | parry | every_n_shots>damage` |
| deadeyebow | DEADEYE LONGBOW | new | `bolt | pierce | crit,crit_mult | far_dmg | on_crit[if elite]>status:mark` |
| mirrorshard | SHARDS OF THE MIRROR | new | `disc | count+ | crit,overcrit |  | on_crit>shoot` |
| truthseeker | TRUTHSEEKER | new | `rail |  | crit |  | on_crit>explode` |
| flayinghook | FLAYING HOOK | new | `whip |  |  |  | on_hit>status:bleed` |
| sanguinering | SANGUINE CHAKRAM | new | `boomer |  |  |  | on_hit>status:bleed; on_kill[if bleeding]>heal` |
| pactknives | PACT KNIVES | new | `bolt | count+ |  |  | on_room_enter>hurt_self+buff:dmg` |
| hemoclaws | HEMOCLAWS | new | `slash |  |  | leech | on_hit>status:bleed` |
| kindlingstaff | KINDLING STAFF | new | `orb |  | burn |  | on_kill[if burning]>explode` |
| magmamaul | MAGMA MAUL | new | `slash |  | burn | knock | every_n_shots>explode` |
| flarepistol | FLARE PISTOL | new | `burst |  | burn |  | on_hit>explode` |
| sunforge | SUNFORGE HALO | new | `nova | count+ | burn |  | on_crit>status:burn` |
| sporelauncher | SPORE LAUNCHER | new | `flask |  | explode,poison |  | on_kill[if poisoned]>status:poison` |
| widowneedles | WIDOW NEEDLES | new | `bolt | count+ | poison |  | every_n_shots>status:weakened` |
| blightcenser | BLIGHT CENSER | new | `pulse |  | poison | linger | on_kill[if poisoned]>status_area:poison` |
| serpentspine | SERPENT SPINE | new | `whip |  | poison |  | on_hit[if poisoned]>status:vulnerable` |
| sparkingrod | SPARKING ROD | new | `zap |  |  |  | on_hit>status:shock` |
| thunderlance | THUNDER LANCE | new | `thrust |  | chain |  | every_n_shots>lightning` |
| capacitor | CAPACITOR CANNON | new | `rail |  |  |  | on_hit>status:shock; on_kill[if shocked]>chain` |
| stormbreaker | STORMBREAKER | new | `gatling |  | chain |  | every_n_shots>lightning+status:shock` |
| scatterwand | SCATTER WAND | new | `orb | count+ |  |  | every_n_shots>nova` |
| prismbow | PRISM BOW | new | `bolt | pierce |  | split | ` |
| orreryblades | ORRERY OF BLADES | new | `disc | count+,bounce+ |  | accel | ` |
| thousandcuts | THOUSAND CUTS | new | `burst | count+ | ricochet |  | on_shoot>shoot` |
| wispcrook | WISPHERD'S CROOK | new | `summon |  | fam_rate |  | on_room_clear>summon` |
| hivelantern | HIVE LANTERN | new | `boomer |  |  |  | on_kill>summon` |
| bonebell | BONE BELL | new | `nova |  |  |  | every_n_shots>summon` |
| courtofshades | COURT OF SHADES | new | `summon |  | fam_dmg,familiars |  | on_room_enter>summon+summon` |
| twinshivs | TWIN SHIVS | new | `slash |  |  |  | on_roll>nova` |
| smokebow | SMOKE BOW | new | `bolt |  | roll_speed |  | on_roll>clear_shots` |
| eclipsescythe | ECLIPSE SCYTHE | new | `slash |  |  | kill_roll | ` |
| phantomvolley | PHANTOM VOLLEY | new | `disc |  | charges,dodge_charges |  | on_roll>shoot` |
| towershield | TOWER SHIELD | new | `thrust |  | armor | parry | on_damage_taken>clear_shots` |
| spikedgauntlets | SPIKED GAUNTLETS | new | `slash |  | thorns |  | on_damage_taken>nova` |
| ironwoodstaff | IRONWOOD STAFF | new | `orb |  |  | armor_dmg | on_room_clear>armor` |
| aegisorb | AEGIS ORB | new | `pulse |  |  |  | on_damage_taken>clear_shots+buff:dmg` |
| ragecleaver | RAGE CLEAVER | new | `slash |  |  | low_hp_dmg | on_kill>buff:rate` |
| graveslab | GRAVESLAB | new | `slash |  |  | knock | on_kill[if low_hp]>heal` |
| warhornaxe | WARHORN AXE | new | `spin |  |  |  | on_damage_taken>buff:rate` |
| frenzychain | FRENZY CHAIN | new | `whip |  |  |  | while_low_hp>buff:rate+buff:dmg` |
| undyinghatchets | UNDYING HATCHETS | new | `spin | count+ |  |  | while_low_hp>buff:dmg` |
| coincannon | COIN CANNON | new | `shot | count+ |  | gold_hit | on_kill>gold` |
| gildedrapier | GILDED RAPIER | new | `slash |  |  | gold_dmg | on_crit>gold` |
| luckydeck | LUCKY DECK | new | `disc | count+ | crit |  | on_crit>gold` |
| tithescepter | TITHE SCEPTER | new | `zap | chain+ |  | gold_dmg,gold_hit | on_room_clear>gold` |
| hexsickle | HEXBOUND SICKLE | new | `slash |  |  |  | on_hit>status:curse` |
| cursedflintlock | CURSED FLINTLOCK | new | `rail |  | max_hp |  | on_hit[if cursed]>damage` |
| weepingstaff | WEEPING IDOL STAFF | new | `orb |  |  |  | on_shoot>hurt_self; pct:dmg` |
| doombell | DOOMSAYER'S KNELL | new | `nova | count+ |  |  | on_hit>status:curse; on_kill[if cursed]>explode` |
| juggler | JUGGLER'S PINS | new | `spin | count+ |  | accel | every_n_shots>nova` |
| bannerpike | RALLYING PIKE | new | `thrust |  | familiars |  | on_room_clear>summon+summon` |
| banesabre | BANE SABRE | new | `slash |  | crit |  | ` |
| ironslab | IRON SLAB | new | `slash |  |  | knock | ` |
| wayfareredge | WAYFARER'S EDGE | new | `slash |  | crit | parry | ` |
| snubguns | SNUB GUNS | new | `burst | count+ |  |  | on_kill>drop` |
| shackleflail | SHACKLE FLAIL | new | `whip |  |  |  | ` |
| giltdeck | GILT DECK | new | `disc | count+ |  |  | ` |
| warlance | WAR LANCE | new | `thrust |  |  |  | ` |
| irontalons | IRON TALONS | new | `slash |  | crit |  | every_n_shots>area+vfx:spin+vfx:ring` |
| bogpump | BOG PUMP | new | `flame |  | poison |  | on_kill>zone` |
| leechlance | LEECHING LANCE | new | `thrust |  |  | leech,status_dmg | ` |
| frogspawn | FROGSPAWN SATCHEL | new | `mine |  | poison |  | on_kill>summon` |
| witchlight | WITCH-LIGHT LANTERN | new | `pulse |  | poison |  | every_n_shots>shoot` |
| rainmaker | RAINMAKER'S ROD | new | `zap | chain+ |  |  | every_n_seconds[if fighting]>lightning` |
| warbow | WARBOW | new | `bolt | pierce | crit |  | on_shoot[if still]>buff:crit` |
| volleybow | VOLLEY BOW | new | `bolt | count+ |  |  | ` |
| firepot | FIREPOT SLING | new | `flask |  | burn |  | on_hit>zone` |
| siegearbalest | SIEGE ARBALEST | new | `rail |  |  | knock | on_room_clear>armor` |
| bannermaul | BANNER MAUL | new | `slash |  | full_hp_dmg |  | on_kill>buff:rate` |
| cinderwhip | CINDER WHIP | new | `whip |  | burn |  | on_kill[if burning]>explode` |
| scorchcannon | SCORCH CANNON | new | `gatling |  | burn |  | every_n_shots>shoot` |
| ironpike | IRON PIKE | new | `thrust |  | armor |  | on_damage_taken>push` |
| prayerbeads | PRAYER BEADS | new | `nova | count+ |  |  | on_roll>nova` |
| frostfang | FROSTBITE FANG | new | `slash |  | chill,vs_chill |  | on_crit>status_area:chill` |
| avalanche | AVALANCHE STAFF | new | `orb |  | chill |  | on_kill[if chilled]>explode` |
| quarterstaff | MONK'S QUARTERSTAFF | new | `thrust |  |  |  | on_roll>buff:dmg` |
| templebell | TEMPLE BELL | new | `pulse |  |  |  | on_damage_taken>nova` |
| iciclerepeater | ICICLE REPEATER | new | `bolt |  | chill |  | on_kill[if chilled]>nova` |
| stillwater | BLADE OF STILL WATER | new | `slash |  | crit |  | on_hit[if still]>damage; on_roll[if danger]>buff:dmg` |
| sixshooter | SIX-SHOOTER | new | `burst |  | crit |  | every_n_shots>damage` |
| alleyscatter | ALLEY SCATTERGUN | new | `shot | count+ |  |  | ` |
| throwknives | THROWING KNIVES | new | `bolt | count+ | crit | kill_roll | ` |
| drumgun | DRUM GUN | new | `gatling |  |  |  | on_kill>drop` |
| grapnel | GRAPPLING HOOK | new | `whip |  |  |  | on_hit>status:mark` |
| smokecharges | SMOKE CHARGES | new | `mine |  |  |  | on_roll>clear_shots` |
| goldengun | GOLDEN GUN | new | `rail |  | crit | gold_dmg | on_kill>gold` |
| crowcaller | CROWCALLER | new | `summon |  |  |  | on_kill>summon` |
| lampflamer | STREETLAMP FLAMER | new | `flame |  | burn,vs_burn |  | on_hit[if burning]>explode` |
| voidray | VOID RAY | new | `beam |  |  |  | on_hit>status:curse+status:weakened` |
| eclipseorb | ECLIPSE ORB | new | `pulse |  |  |  | on_kill>lightning` |
| umbralscythe | UMBRAL SCYTHE | new | `slash |  | curse |  | on_kill[if cursed]>heal` |
| starfall | STARFALL CHIME | new | `nova | count+ |  |  | every_n_shots>chain` |
| hexchain | HEX CHAIN | new | `whip |  | curse |  | on_hit[if cursed]>chain` |
| riftcannon | RIFT CANNON | new | `rail |  |  |  | on_hit>explode` |
| bloodletter | BLOODLETTER | new | `disc | bounce+ |  |  | on_hit>status:bleed` |
| bonesaw | BONE SAW | new | `spin | pierce+ |  |  | ` |
| nightwing | NIGHT-WING STAFF | new | `summon |  | familiars |  | on_kill>heal` |
| hivecannon | HIVE CANNON | new | `flask |  | poison |  | on_hit>summon` |
| shieldcannon | SHIELD CANNON | new | `rail |  | armor |  | on_damage_taken>nova` |
| briarspear | BRIAR SPEAR | new | `thrust |  | poison,thorns |  | on_roll>status_area:bleed` |
| tumbleredge | TUMBLER'S EDGE | new | `slash |  |  |  | on_roll>buff:crit` |
| phantombow | PHANTOM BOW | new | `bolt | homing |  |  | on_roll>buff:dmg` |
| skullsplitter | SKULLSPLITTER | new | `spin |  |  |  | while_low_hp>buff:rate` |
| wrathbuss | WRATH BLUNDERBUSS | new | `shot | count+ |  |  | on_damage_taken>buff:dmg` |
| flippedcoin | FLIPPED COIN | new | `disc |  | luck |  | on_crit>gold` |
| taxbell | TAXMAN'S BELL | new | `nova |  |  |  | on_kill[if elite]>gold; on_room_clear>gold` |
| thornidol | IDOL OF THORNS | new | `orb |  | thorns |  | on_room_enter>hurt_self+buff:dmg` |
| arcsprayer | ARC SPRAYER | new | `flame |  | chain |  | on_hit>status:shock` |
| thunderdrum | THUNDER DRUM | new | `pulse |  |  |  | on_hit>status:shock; on_kill[if shocked]>nova` |
| powdermortar | POWDER MORTAR | new | `flask |  | bomb_r |  | on_kill>drop` |
| deadfall | DEADFALL TRAPS | new | `mine |  |  |  | on_damage_taken>drop` |
| whimsywand | WAND OF WHIMSY | new | `orb |  |  |  | every_n_shots>chaos` |
| meteorstaff | METEOR STAFF | new | `orb |  | burn |  | every_n_shots>meteor` |
| singularity | SINGULARITY CANNON | new | `rail |  |  |  | on_hit>pull+explode` |
| gravitymaul | GRAVITY MAUL | new | `slash |  |  | knock | every_n_shots>pull+explode` |
| beehive | ANGRY BEEHIVE | new | `gatling | homing | poison |  | on_kill>summon` |
| midascannon | MIDAS CANNON | new | `shot | count+ |  | gold_hit | on_hit>transmute` |
| discoball | DISCO BALL | new | `pulse |  |  | linger | on_hit>rand_status; on_shoot>nova` |
| boomstick | BOOMSTICK | new | `shot | count+ |  | close_dmg | on_kill>bomb` |
| razoryoyo | RAZOR YO-YO | new | `boomer |  | crit |  | on_crit>buff:size` |
| pinball | PINBALL CANNON | new | `disc | bounce+ | ricochet |  | on_hit>buff:rate` |
| teslacoil | TESLA COIL | new | `zap | chain+ |  |  | on_kill>bolts` |
| volcano | POCKET VOLCANO | new | `flask |  | burn,explode |  | every_n_shots>meteor+meteor+meteor; on_hit>zone` |
| frostfist | FROST GIANT'S FIST | new | `slash |  | chill | knock | every_n_shots>status_area:stun+status_area:chill+vfx:ring` |
| slimecannon | SLIME CANNON | new | `flask |  | explode,poison |  | on_hit>zone; on_kill[if poisoned]>summon` |
| doomclock | DOOMSDAY CLOCK | new | `mine |  |  |  | every_n_seconds[if fighting]>area+status_area:curse+vfx:flash+vfx:label+vfx:sigil` |
| chainsaw | RIPSAW | new | `flame |  |  |  | on_hit>status:bleed; on_kill>buff:rate; while_low_hp>buff:dmg` |
| slotmachine | ONE-ARMED BANDIT | new | `burst |  | luck |  | on_kill>chaos` |
| orbitallaser | ORBITAL LASER | new | `beam | pierce |  |  | every_n_seconds[if fighting]>bolts` |
| peppershaker | GHOST PEPPER SHAKER | new | `nova | count+ | burn |  | on_roll>zone+buff:speed` |
| bubblewand | BUBBLE WAND | new | `orb | pierce |  |  | on_hit>status:weakened` |
| clownhammer | SQUEAKY HAMMER | new | `slash |  | crit | knock | on_crit>gold+push` |
| necroflute | BONE FLUTE | new | `summon |  | curse |  | on_kill[if cursed]>summon` |
| backfire | BACKFIRE BLUNDERBUSS | new | `shot | count+ |  |  | on_shoot>shoot_at` |
| crossfirebow | CROSSFIRE BOW | new | `bolt | pierce | crit |  | on_shoot>shoot_at+shoot_at+shoot_at` |
| tentacle | KRAKEN TENTACLE | new | `whip |  | poison |  | every_n_shots>pull+status_area:weakened` |
| joustrocket | JOUSTING ROCKET | new | `thrust |  |  |  | on_hit>explode; on_roll>buff:dmg` |
| homingaxes | BLOODHOUND HATCHETS | new | `spin | pierce+,homing |  |  | on_kill>refund_roll` |
| pineapple | PINEAPPLE GRENADE | new | `grenade | shrapnel |  |  | ` |
| skipcharge | SKIPPING CHARGE | new | `grenade | skips |  |  | ` |
| pomegranate | POMEGRANATE | new | `grenade | cluster |  |  | ` |
| hoarfrost | HOARFROST GRENADE | new | `grenade | freeze |  |  | ` |
| fruitcake | GRANDMA'S FRUITCAKE | new | `grenade | heavy,crumbs |  |  | ` |
| bottlerockets | BOTTLE ROCKETS | new | `rocket | count+,wobble | burn |  | ` |
| alleyrpg | BACKALLEY RPG | new | `rocket | backblast |  |  | ` |
| festival | FESTIVAL LAUNCHER | new | `rocket | fireworks |  |  | ` |
| pathfinder | PATHFINDER ROCKET | new | `rocket | guided,ramp |  |  | ` |
| swarmpod | SWARM POD | new | `missile |  |  |  | ` |
| lockon | LOCK-ON LAUNCHER | new | `missile | lock |  | elite_dmg | ` |
| stickyjar | STICKY JAR | new | `sticky | rolldet |  |  | ` |
| limpets | LIMPET CHARGES | new | `sticky | remote |  |  | ` |
| pocketmortar | POCKET MORTAR | new | `mortar |  |  |  | ` |
| snowglobe | SNOWGLOBE MORTAR | new | `mortar | zone=frost | vs_chill |  | ` |
| clockmice | CLOCKWORK MICE | new | `walker | count+ |  |  | ` |
| keg | ROLLING KEG | new | `walker | roll |  |  | ` |
| signalflare | SIGNAL FLARE | new | `strike |  | burn |  | ` |
| skyhammer | SKY HAMMER | new | `strike | pillar |  |  | ` |
| dynamite | DYNAMITE BUNDLE | new | `dynamite |  |  |  | ` |
| repulsor | REPULSOR | new | `wave |  |  |  | ` |
| shrapnelgun | SHRAPNEL SHOTGUN | new | `shot | count+ |  | wall_shrapnel | ` |
| blastknuckles | BLASTING KNUCKLES | new | `slash |  |  |  | on_hit>plant` |
| parasite | PARASITE LAUNCHER | new | `flask |  | poison |  | on_hit>puppet` |
| piggybank | PIGGY BANK | new | `shot | count+ |  | gold_hit,piggy | ` |
| plasmaslug | PLASMA SLUGGER | new | `charge |  |  |  | ` |
| shatterball | SHATTERBALL | new | `charge | shatter |  |  | ` |
| gravityglobe | GRAVITY GLOBE | new | `charge | pull |  |  | ` |
| swiftdraw | SWIFTDRAW BOW | new | `charge | roll_draw |  |  | ` |
| chokeshotgun | CHOKE SHOTGUN | new | `charge | tighten |  |  | ` |
| coldstar | COLD STAR | new | `charge | aura | vs_chill |  | ` |
| quakemaul | QUAKE MAUL | new | `slam |  |  |  | ` |
| emberquake | EMBERQUAKE MAUL | new | `slam | fire_ring | burn |  | ` |
| aftershock | AFTERSHOCK HAMMER | new | `slam | aftershocks |  |  | ` |
| dashblade | DASHBLADE | new | `dash |  |  |  | ` |
| cometlance | COMET LANCE | new | `dash | dash_blast |  |  | ` |
| phantomedge | PHANTOM EDGE | new | `dash | phantom |  |  | ` |
| warjavelin | WAR JAVELIN | new | `javelin |  |  |  | ` |
| thunderpike | THUNDER PIKE | new | `javelin | rod |  |  | ` |
| grapple | GRAPPLE GAUNTLET | new | `hook |  |  |  | ` |
| anchorchain | ANCHOR CHAIN | new | `hook | drag |  |  | ` |
| cutlass | CUTLASS AND FLINTLOCK | new | `combo | steps=slash/slash/shot |  |  | ` |
| chainglaive | CHAIN GLAIVE | new | `combo | steps=sweep/thrust/spin,linked |  |  | ` |
| flarefist | FLAREFIST | new | `combo | steps=jab/jab/upper |  |  | ` |
| steamrepeater | STEAM REPEATER | new | `heat |  |  |  | ` |
| reactorrifle | REACTOR RIFLE | new | `heat | heat_dmg |  |  | ` |
| deadeye | DEADEYE REVOLVER | new | `reload | last_crit,kill_reload |  |  | ` |
| magdump | MAGDUMP CARBINE | new | `reload | throw_mag |  |  | ` |
| starcaller | STARCALLER | new | `orbit |  |  |  | ` |
| snapback | SNAPBACK DISC | new | `recall |  |  |  | ` |
| duelistdeck | DUELIST'S DECK | new | `deck | deck=strike/strike/strike/bash/cleave/flurry |  |  | ` |
| poisonpack | POISONER'S PACK | new | `deck | deck=toxin/toxin/toxin/catalyst/noxious/strike |  |  | ` |
| shivdeck | SHIV DECK | new | `deck | deck=dance/dance/shiv/shiv/finisher |  |  | ` |
| countdowndeck | COUNTDOWN DECK | new | `deck | deck=bomb/strike/strike/bash/flurry |  |  | ` |
| echodeck | ECHO DECK | new | `deck | deck=double/strike/cleave/double/flurry/bash |  |  | ` |
| ascenddeck | ASCENDING DECK | new | `deck | deck=strike/strike/bash/cleave/flurry,ascend |  |  | ` |
| sentrykit | SENTRY KIT | new | `turret | turret=gun |  |  | ` |
| flamesentry | FLAME SENTRY | new | `turret | turret=flame | burn |  | ` |
| teslapair | TESLA PAIR | new | `turret | turret=tesla |  |  | ` |
| frostbeacon | FROST BEACON | new | `turret | turret=frost |  |  | ` |
| sawtrap | SAW TRAP | new | `turret | turret=saw |  |  | ` |
| mendtotem | MENDING TOTEM | new | `turret | turret=mend |  |  | ` |
| gravecaller | GRAVECALLER STAFF | new | `thrall | thrall=bones |  |  | ` |
| claygolem | CLAY GOLEM | new | `thrall | thrall=golem |  |  | ` |
| implantern | IMP LANTERN | new | `thrall | thrall=imp |  |  | ` |
| wolfhorn | WOLF HORN | new | `thrall | thrall=wolf |  |  | ` |
| mimicchest | MIMIC CHEST | new | `thrall | thrall=mimic |  |  | ` |
| petwhistle | PET WHISTLE | new | `command | command=leap |  |  | ` |
| shepherdcrook | SHEPHERD'S CROOK | new | `command | command=lob |  |  | ` |
| lookingglass | LOOKING GLASS | new | `mirror | mirror=image |  |  | ` |
| doppelganger | DOPPELGANGER BLADE | new | `mirror | range,arc,mirror=shadow |  |  | ` |
| batcloud | BAT CLOUD | new | `swarm | swarm=bats,swarm=bats |  |  | ` |
| fireflyjar | FIREFLY JAR | new | `swarm | swarm=fireflies,swarm=fireflies |  |  | ` |
| dragonegg | DRAGON EGG | new | `egg |  |  |  | on_hit>warm` |
| tamerswhip | TAMER'S WHIP | new | `whip |  |  |  | on_hit>charm` |
| typewriter | TYPEWRITER | new | `letters | words=BOOM |  |  | ` |
| prophetquill | PROPHET'S QUILL | new | `letters | words=ZAP/ICE/BURN/GOLD/DOOM |  |  | ` |
| bubbleblaster | BUBBLE BLASTER | new | `bubble |  |  |  | ` |
| soapcannon | SOAP CANNON | new | `bubble | soap |  |  | ` |
| flakpistol | FLAK PISTOL | new | `flak |  |  |  | ` |
| interceptor | INTERCEPTOR | new | `flak | barrage |  |  | ` |
| inkgun | INK GUN | new | `paint | colors=ink |  |  | ` |
| tricolor | TRICOLOR SPLATTER | new | `paint | colors=red/blue/yellow |  |  | ` |
| slotpistol | SLOT PISTOL | new | `slots |  |  |  | ` |
| gildedslots | GILDED SLOTS | new | `slots | stakes |  |  | ` |
| snowroller | SNOW ROLLER | new | `roller |  |  |  | ` |
| mossboulder | MOSS BOULDER | new | `roller | moss |  |  | ` |
| paydaycannon | PAYDAY CANNON | new | `money |  |  |  | ` |
| flashcamera | FLASH CAMERA | new | `camera |  |  |  | ` |
| glacierray | GLACIER RAY | new | `ray |  |  |  | ` |
| junkcannon | JUNK CANNON | new | `junk |  |  |  | ` |
| fishcannon | FISH CANNON | new | `junk | fish |  |  | ` |
| homerunbat | HOME RUN BAT | new | `bat |  |  |  | ` |
| croquetmallet | CROQUET MALLET | new | `bat | croquet |  |  | ` |
| backstabdirk | BACKSTAB DIRK | new | `stab |  |  |  | ` |
| callingcard | CALLING CARD | new | `duel |  |  |  | ` |
| shrinkray | SHRINK RAY | new | `shrink |  |  |  | ` |
| leafblower | LEAF BLOWER | new | `blower |  |  |  | ` |
| aegisprojector | AEGIS PROJECTOR | new | `dome |  |  |  | ` |
| coinflipper | COIN FLIPPER | new | `coin |  |  |  | ` |

## Relics

### Same signature (3 groups)

- 2: `add:armor`  
  filings (ORIGINAL), boneshield (ORIGINAL)
- 2: `add:familiars`  
  wispjar (ORIGINAL), twinwisp (ORIGINAL)
- 2: `add_cap:shop_disc; mul:gold_mult`  
  crown (ORIGINAL), gildedtooth (ORIGINAL)

### Near (3 groups)

- 2: `add_cap:shop_disc; stat:gold_mult`  
  crown (ORIGINAL), gildedtooth (ORIGINAL)
- 2: `stat:armor`  
  filings (ORIGINAL), boneshield (ORIGINAL)
- 2: `stat:familiars`  
  wispjar (ORIGINAL), twinwisp (ORIGINAL)

### Numbers only (48, 0 of them new)

whetstone (ORIGINAL), twitch (ORIGINAL), splitfang (ORIGINAL), owl (ORIGINAL), sparrow (ORIGINAL), bramble (ORIGINAL), sap (ORIGINAL), seeker (ORIGINAL), coal (ORIGINAL), needle (ORIGINAL), viper (ORIGINAL), luckycoin (ORIGINAL), hourglass (ORIGINAL), lantern (ORIGINAL), moon (ORIGINAL), dice (ORIGINAL), arrowhead (ORIGINAL), thorn (ORIGINAL), heavy (ORIGINAL), fever (ORIGINAL), bonecharm (ORIGINAL), echo (ORIGINAL), rage (ORIGINAL), sigil (ORIGINAL), shells (ORIGINAL), spark (ORIGINAL), tallow (ORIGINAL), skeletonkey (ORIGINAL), quiver (ORIGINAL), filings (ORIGINAL), gravedust (ORIGINAL), mothwing (ORIGINAL), bitterroot (ORIGINAL), tinwhistle (ORIGINAL), rustynail (ORIGINAL), wispjar (ORIGINAL), emberheart (ORIGINAL), boneshield (ORIGINAL), huntersmark (ORIGINAL), staticcoil (ORIGINAL), ricochet (ORIGINAL), coldiron (ORIGINAL), splinter (ORIGINAL), phoenix (ORIGINAL), twinwisp (ORIGINAL), stormcrown (ORIGINAL), deepeye (ORIGINAL), cindercrown (ORIGINAL)

### Every relic

| id | name | | signature |
|---|---|---|---|
| whetstone | WHETSTONE | ORIGINAL | `mul:dmg` |
| twitch | TWITCHING FINGER | ORIGINAL | `mul:rate` |
| splitfang | SPLIT FANG | ORIGINAL | `add:count; mul:dmg` |
| owl | OWL FEATHER | ORIGINAL | `mul:life; mul:shot_speed` |
| sparrow | SPARROW BOOTS | ORIGINAL | `mul:speed` |
| garnet | BLOOD GARNET | ORIGINAL | `add:max_hp; add_cap:hp` |
| bramble | BRAMBLE RING | ORIGINAL | `add:pierce` |
| sap | RUBBER SAP | ORIGINAL | `add:bounce; mul:life` |
| seeker | SEEKER'S EYE | ORIGINAL | `add:homing` |
| coal | CINDER COAL | ORIGINAL | `add:burn` |
| needle | FROST NEEDLE | ORIGINAL | `add:chill` |
| viper | VIPER TOOTH | ORIGINAL | `add:poison` |
| luckycoin | CROOKED COIN | ORIGINAL | `add:crit` |
| hourglass | SAND GLASS | ORIGINAL | `mul:dodge_cd` |
| lantern | GRAVE LANTERN | ORIGINAL | `add:lifesteal` |
| buckler | IRON BUCKLER | ORIGINAL | `set:buckler` |
| moon | PALE MOON | ORIGINAL | `add:orbitals` |
| sapbomb | POWDER POUCH | ORIGINAL | `set:bomb_dodge` |
| dice | LOADED DIE | ORIGINAL | `add:triple` |
| arrowhead | BARBED TIP | ORIGINAL | `mul:dmg; mul:shot_speed` |
| thorn | THORN LEAF | ORIGINAL | `add:thorns` |
| crown | PAUPER'S CROWN | ORIGINAL | `add_cap:shop_disc; mul:gold_mult` |
| heavy | LEAD SHOT | ORIGINAL | `mul:dmg; mul:rate; mul:size` |
| fever | FEVER SCROLL | ORIGINAL | `add:frenzy` |
| bonecharm | BONE CHARM | ORIGINAL | `add:charges; add:dodge_charges` |
| glassheart | GLASS HEART | ORIGINAL | `add_floor:max_hp; clamp_max:hp; mul:dmg` |
| echo | ECHO RING | ORIGINAL | `add:backshot` |
| witcheye | WITCH EYE | ORIGINAL | `add:crit; at_least:crit_mult` |
| rage | WRATH EMBER | ORIGINAL | `add:rage` |
| lodestone | LODESTONE | ORIGINAL | `mul:gold_mult; set:magnet` |
| sigil | WARDING SIGIL | ORIGINAL | `add:ward` |
| shells | VOLATILE SHELLS | ORIGINAL | `add:explode` |
| spark | CHAIN SPARK | ORIGINAL | `add:chain` |
| keyring | WARDEN'S KEY | ORIGINAL | `add:max_potions; add_cap:potions` |
| tallow | TALLOW CANDLE | ORIGINAL | `add:bombs; mul:bomb_mult` |
| skeletonkey | SKELETON KEY | ORIGINAL | `add:keys` |
| quiver | QUIVER STRAP | ORIGINAL | `mul:rate; mul:shot_speed` |
| filings | IRON FILINGS | ORIGINAL | `add:armor` |
| gravedust | GRAVE DUST | ORIGINAL | `mul:gold_drop` |
| mothwing | MOTH WING | ORIGINAL | `mul:roll_speed` |
| bitterroot | BITTER ROOT | ORIGINAL | `add:potion_heal` |
| tinwhistle | TIN WHISTLE | ORIGINAL | `mul:dodge_cd; mul:speed` |
| chalk | MAPPER'S CHALK | ORIGINAL | `add:bombs; set:reveal` |
| rustynail | RUSTY NAIL | ORIGINAL | `add:pierce; mul:dmg` |
| wispjar | WISP JAR | ORIGINAL | `add:familiars` |
| emberheart | EMBER HEART | ORIGINAL | `add:aura` |
| boneshield | BONE SHIELD | ORIGINAL | `add:armor` |
| huntersmark | HUNTER'S MARK | ORIGINAL | `add:elite_mult` |
| glasslens | GLASS LENS | ORIGINAL | `set:lens` |
| staticcoil | STATIC COIL | ORIGINAL | `add:coil` |
| bloodoath | BLOOD OATH | ORIGINAL | `set:oath` |
| ricochet | RICOCHET BEAD | ORIGINAL | `add:ricochet` |
| misers | MISER'S PURSE | ORIGINAL | `set:miser` |
| shadowstep | SHADOW STEP | ORIGINAL | `set:shadowstep` |
| coldiron | COLD IRON | ORIGINAL | `add:chill; mul:dmg` |
| splinter | SPLINTER | ORIGINAL | `add:splinter` |
| phoenix | PHOENIX FEATHER | ORIGINAL | `add:revive` |
| twinwisp | TWIN LANTERNS | ORIGINAL | `add:familiars` |
| stormcrown | STORM CROWN | ORIGINAL | `add:storm` |
| hollowmirror | HOLLOW MIRROR | ORIGINAL | `set:mirror` |
| gildedtooth | GILDED TOOTH | ORIGINAL | `add_cap:shop_disc; mul:gold_mult` |
| overcharge | OVERCHARGE | ORIGINAL | `add:count; add_floor:max_hp; clamp_max:hp; mul:rate` |
| deepeye | EYE OF THE DEEP | ORIGINAL | `add:count; add:homing` |
| cindercrown | CROWN OF CINDERS | ORIGINAL | `add:burn; mul:dmg` |
| ageglass | GLASS OF AGES | ORIGINAL | `add:charges; add:dodge_charges; set:roll_reload` |
| worldseed | WORLDSEED | ORIGINAL | `add:max_hp; copy:hp` |
| sharpstone | OILED WHETSTONE | new | `add:crit; on_crit>refund_roll` |
| keeneye | KEEN EYE | new | `add:crit_mult; on_crit>status:vulnerable` |
| firstblood | FIRST NICK | new | `add:crit; hook:first_hit` |
| hairtrigger | HAIR TRIGGER | new | `on_crit>buff:rate` |
| killingblow | THE KILLING BLOW | new | `add:crit; add:overcrit; on_crit[if boss]>damage` |
| leechtooth | LEECH TOOTH | new | `on_kill[if bleeding]>heal` |
| openwound | OPEN WOUND | new | `on_hit>status:bleed` |
| bloodprice | BLOOD PRICE | new | `add_floor:potion_heal; mul:dmg` |
| crimsonfont | CRIMSON FONT | new | `on_room_clear>heal` |
| matchbook | DAMP MATCHBOOK | new | `add:burn; every_n_seconds[if fighting]>status_area:burn` |
| firework | FIREWORK | new | `on_kill[if burning]>explode` |
| oilflask | LAMP OIL | new | `add:burn_dmg; on_hit[if burning]>zone` |
| phoenixash | PYRE ASH | new | `add:burn; add:vs_burn; on_damage_taken>status_area:burn` |
| toadstool | TOADSTOOL | new | `add:poison; on_damage_taken>status_area:poison` |
| contagion | CONTAGION | new | `on_kill[if poisoned]>status:poison` |
| witherroot | WITHERROOT | new | `on_hit[if poisoned]>status:weakened` |
| blackbile | BLACK BILE | new | `add:poison_dmg; set:poison_fast` |
| copperwire | COPPER WIRE | new | `add:chain; on_damage_taken>bolts` |
| stormjar | STORM IN A JAR | new | `on_hit>status:shock` |
| groundingrod | GROUNDING SPIKE | new | `every_n_seconds>lightning` |
| overload | OVERLOAD COIL | new | `add:chain_jumps; add:storm_dmg; every_n_seconds[if fighting]>bolts` |
| mirrorbead | MIRROR BEAD | new | `add:pierce; mul:shot_speed; on_kill>shoot` |
| prismshard | PRISM SHARD | new | `hook:split` |
| starchart | STAR CHART | new | `every_n_shots>nova` |
| manyhands | MANY HANDS | new | `add:count; every_n_shots>nova; mul:dmg` |
| glowworm | GLOW-WORM JAR | new | `add:fam_dmg; every_n_seconds[if fighting]>summon` |
| broodmother | BROOD EGG | new | `on_kill>summon` |
| hivemind | HIVEMIND | new | `add:familiars; mul:fam_rate; on_kill[if elite]>summon` |
| quickcloak | QUICKSILVER THREAD | new | `mul:dodge_cd; on_roll>buff:speed` |
| shadowcut | SHADOW CUT | new | `on_roll>nova` |
| afterimage | AFTERIMAGE | new | `on_roll>buff:dmg` |
| nightveil | NIGHT VEIL | new | `add:charges; add:dodge_charges; add:evade; on_damage_taken>refund_roll` |
| ironrations | IRON RATIONS | new | `add:max_hp; add_cap:hp; on_floor_start>heal` |
| spikedcollar | SPIKED COLLAR | new | `add:thorns; on_damage_taken>nova` |
| towerkey | BASTION KEY | new | `on_room_clear>armor` |
| stonehide | STONEHIDE | new | `add:armor; add:fortress; on_level_up>armor` |
| redmist | RED MIST | new | `while_low_hp>buff:dmg` |
| warpaint | WAR PAINT | new | `on_kill>buff:rate` |
| grudge | OLD GRUDGE | new | `on_damage_taken>buff:dmg` |
| lastbreath | LAST BREATH | new | `while_low_hp>buff:dmg+buff:rate+buff:speed` |
| copperpenny | LUCKY PENNY | new | `on_kill>gold` |
| goldtongue | GOLDEN TONGUE | new | `add_cap:shop_disc; mul:gold_mult; on_hit>drop` |
| ledgerofdebt | LEDGER OF DEBTS | new | `on_kill[if rich]>gold; set:miser` |
| dragonhoard | DRAGON'S HOARD | new | `hook:gold_dmg; on_room_clear>gold` |
| evileye | EVIL EYE | new | `on_hit>status:curse` |
| bargain | DEVIL'S BARGAIN | new | `add_floor:max_hp; clamp_max:hp; mul:dmg; on_kill[if elite]>heal` |
| cursedcoin | CURSED COIN | new | `mul:gold_mult; on_room_enter>hurt_self` |
| voidheart | VOID HEART | new | `on_hit>status:curse; on_hit[if cursed]>damage` |
| wanderersmap | WANDERER'S MAP | new | `add:keys; set:reveal` |
| emptyflask | BOTTOMLESS FLASK | new | `add:max_potions; on_room_clear>drop` |
| marshreed | MARSH REED | new | `add:poison; on_roll>zone` |
| warhorn | CRACKED WARHORN | new | `on_room_enter>buff:rate` |
| prayerflag | PRAYER FLAG | new | `add:hp; add:max_hp; on_level_up>heal` |
| snowglobe | SNOW GLOBE | new | `add:chill; on_roll>status_area:chill` |
| lockpick | BENT LOCKPICK | new | `add:keys; on_room_clear>drop` |
| spentcasing | SPENT CASING | new | `every_n_shots>drop; mul:rate; mul:shot_speed` |
| candlestub | CANDLE STUB | new | `add:burn; add:burn_time; on_room_enter>status_area:burn` |
| ravenquill | RAVEN QUILL | new | `mul:speed; on_kill>buff:speed` |
| copperspool | COPPER SPOOL | new | `add:chain_jumps; on_pickup>bolts` |
| seedpouch | SEED POUCH | new | `add:familiars; on_room_enter>summon` |
| rooftile | LOOSE ROOF TILE | new | `on_floor_start>drop` |
| bogwater | JAR OF BOGWATER | new | `add:poison_dmg; on_hit[if poisoned]>status:weakened` |
| stillpond | STILL POND | new | `on_hit[if still]>damage` |
| bloodmoon | BLOOD MOON | new | `on_kill[if low_hp]>heal; while_low_hp>buff:dmg` |
| trophyteeth | STRING OF TROPHY TEETH | new | `on_kill[if elite]>drop` |
| mudcharm | MUD-CAKED CHARM | new | `on_roll>status_area:poison` |
| ironwill | IRON WILL | new | `on_damage_taken>armor` |
| tailwind | TAILWIND | new | `on_hit[if moving]>damage` |
| sparkgap | SPARK GAP | new | `on_hit[if shocked]>damage` |
| frozentear | FROZEN TEAR | new | `on_hit[if chilled]>explode` |
| fielddressing | FIELD DRESSING | new | `on_potion>armor; on_room_clear>heal` |
| scavsack | SCAVENGER'S SACK | new | `on_room_clear>drop` |
| kindlingheart | KINDLING HEART | new | `on_hit[if burning]>explode` |
| rotgut | ROTGUT FLASK | new | `on_hit[if poisoned]>status:vulnerable` |
| stormglass | STORM GLASS | new | `on_crit>lightning` |
| bladeoil | BLADE OIL | new | `on_crit>status:bleed` |
| queensjelly | QUEEN'S JELLY | new | `add:fam_dmg; on_kill>summon` |
| nightshade | NIGHTSHADE | new | `on_roll>status:curse` |
| towerbanner | TOWER BANNER | new | `hook:armor_dmg` |
| heavypurse | HEAVY PURSE | new | `hook:gold_dmg` |
| blastingcaps | BLASTING CAPS | new | `mul:bomb_mult; mul:bomb_r; on_kill>bomb` |
| echostone | ECHO STONE | new | `add:echo; every_n_shots>card` |
| loadeddice | LOADED DICE | new | `add:luck; on_crit>damage` |
| shatteredcrown | SHATTERED CROWN | new | `add_floor:max_hp; clamp_max:hp; mul:dmg; on_crit>explode` |
| bloodtithe | BLOOD TITHE | new | `mul:dmg; on_kill>hurt_self` |
| hungeringedge | HUNGERING EDGE | new | `mul:dmg; on_room_enter>hurt_self` |
| cursedcompass | CURSED COMPASS | new | `add:luck; mul:speed; on_room_clear>chaos` |
| leadweight | LEAD WEIGHT | new | `mul:dmg; mul:rate; on_hit>status:stun` |
| voidpact | VOID PACT | new | `add:charges; add:dodge_charges; add_floor:max_hp; clamp_max:hp; on_roll>clear_shots` |
| warfletching | WAR FLETCHING | new | `add:count; mul:dmg; on_kill>buff:shot_speed` |
| monasterybell | MONASTERY BELL | new | `on_room_enter>status_area:chill` |
| alleycateye | ALLEY CAT'S EYE | new | `add:crit; add:evade; on_room_enter>invuln` |
| eclipseshard | ECLIPSE SHARD | new | `every_n_seconds[if fighting]>status_area:curse+status_area:weakened+vfx:ring` |
| fallenstar | HEART OF A FALLEN STAR | new | `add:hp; add:max_hp; every_n_shots>nova` |
| crownofash | CROWN OF ASH | new | `add:burn; add:vs_burn; on_kill[if burning]>meteor` |
| mirroredsoul | MIRRORED SOUL | new | `add:echo; on_kill>summon` |
| kingsransom | KING'S RANSOM | new | `add:gold; hook:gold_dmg` |
| undyingember | EMBER OF THE UNDYING | new | `add:revive; while_low_hp>buff:burn` |
| thundertorc | THUNDERLORD'S TORC | new | `on_hit>lightning` |
| hivecrown | CROWN OF THE HIVE | new | `add:familiars; mul:fam_rate; on_damage_taken>summon` |
| redgodidol | IDOL OF THE RED GOD | new | `mul:dmg; on_kill>heal` |
| tonicmight | TONIC OF MIGHT | new | `attr:str` |
| quickdraught | QUICKENING DRAUGHT | new | `attr:dex` |
| sagesink | SAGE'S INK | new | `attr:int` |
| heavennectar | HEAVENLY NECTAR | new | `add:hp; add:max_hp; attr:highest` |
| balancestone | STONE OF BALANCE | new | `attr:dex; attr:int; attr:str` |
| smithhammer | SMITH'S HAMMER | new | `upgrade:weapon` |
| frostlantern | FROST LANTERN | new | `on_kill[if chilled]>slow_shots` |
| permafrost | PERMAFROST | new | `add:chill; on_hit[if fresh]>status:chill` |
| snowangel | SNOW ANGEL | new | `add:evade; on_dodge>status_area:chill+vfx:ring` |
| fusebox | FUSE BOX | new | `on_bomb>give` |
| powderhorn | POWDER HORN | new | `add:bombs; on_bomb>nova` |
| blastshield | BLAST SHIELD | new | `on_bomb>armor` |
| gravewhistle | GRAVE WHISTLE | new | `on_kill>raise` |
| toolbox | TINKER'S TOOLBOX | new | `on_room_enter>turret` |
| honeycomb | HONEYCOMB | new | `on_heal>summon` |
| littlekiln | LITTLE KILN | new | `on_overheal>status_area:burn+vfx:ring` |
| furnaceheart | FURNACE HEART | new | `add:burn; on_kill[if burning]>spread` |
| wyrmscale | WYRM SCALE | new | `add:armor; on_armor_lost>nova` |
| drawholster | QUICKDRAW HOLSTER | new | `on_weapon_swap>buff:crit` |
| wishingcoin | WISHING COIN | new | `on_pickup[if coin]>chaos` |
| philosophersdrop | PHILOSOPHER'S DROP | new | `on_potion>give` |
| surveyorschart | SURVEYOR'S CHART | new | `on_floor_start>give+give` |
| ripostecharm | RIPOSTE CHARM | new | `on_roll[if danger]>reflect` |
| dominotile | DOMINO TILE | new | `on_kill[if elite]>overkill` |
| stampededrum | STAMPEDE DRUM | new | `every_n_seconds[if crowd]>area+push+vfx:ring` |
| spyglass | SPYGLASS | new | `mul:life; on_hit[if far]>damage` |

## Gear

### Same signature (0 groups)

None.

### Near (5 groups)

- 2: `body | max_hp |  | `  
  plague_coat (ORIGINAL), paddedjack (ORIGINAL)
- 2: `feet | dodge_cd |  | `  
  frost_boots (ORIGINAL), sandals (ORIGINAL)
- 2: `feet | speed |  | `  
  thunder_boots (ORIGINAL), worntboots (ORIGINAL)
- 2: `head | armor |  | `  
  bastion_helm (ORIGINAL), tinhelm (ORIGINAL)
- 2: `trinket | dmg |  | status_dmg`  
  ember_ring (ORIGINAL), plague_censer (ORIGINAL)

### Numbers only (46, 0 of them new)

ember_hood (ORIGINAL), frost_helm (ORIGINAL), frost_boots (ORIGINAL), plague_mask (ORIGINAL), plague_coat (ORIGINAL), thunder_helm (ORIGINAL), thunder_boots (ORIGINAL), butcher_cap (ORIGINAL), bastion_helm (ORIGINAL), bastion_plate (ORIGINAL), bastion_boots (ORIGINAL), night_hood (ORIGINAL), night_boots (ORIGINAL), arch_hat (ORIGINAL), arch_robe (ORIGINAL), arch_boots (ORIGINAL), arch_orb (ORIGINAL), gild_crown (ORIGINAL), gild_boots (ORIGINAL), sapper_helm (ORIGINAL), shep_hat (ORIGINAL), shep_boots (ORIGINAL), shep_crook (ORIGINAL), tinhelm (ORIGINAL), leathercap (ORIGINAL), huntershood (ORIGINAL), scholarcap (ORIGINAL), paddedjack (ORIGINAL), chainshirt (ORIGINAL), travelcloak (ORIGINAL), acolyterobe (ORIGINAL), spikedmail (ORIGINAL), smugglercoat (ORIGINAL), worntboots (ORIGINAL), ironboots (ORIGINAL), sandals (ORIGINAL), ninjatabi (ORIGINAL), luckycharm (ORIGINAL), whetring (ORIGINAL), quickring (ORIGINAL), vialbelt (ORIGINAL), bombbag (ORIGINAL), toothnecklace (ORIGINAL), hourglassamulet (ORIGINAL), stormbottle (ORIGINAL), gamblerdie (ORIGINAL)

### Every gear

| id | name | | signature |
|---|---|---|---|
| ember_hood | EMBERWEAVE HOOD | ORIGINAL | `head set:emberweave | burn |  | ` |
| ember_robe | EMBERWEAVE ROBE | ORIGINAL | `body set:emberweave | max_hp | fire_aura | ` |
| ember_boots | EMBERWEAVE TREADS | ORIGINAL | `feet set:emberweave | speed | fire_steps | ` |
| ember_ring | EMBERWEAVE BAND | ORIGINAL | `trinket set:emberweave | dmg | status_dmg | ` |
| frost_helm | HOARFROST CROWN | ORIGINAL | `head set:hoarfrost | chill |  | ` |
| frost_plate | HOARFROST PLATE | ORIGINAL | `body set:hoarfrost | armor | frost_skin | ` |
| frost_boots | HOARFROST GREAVES | ORIGINAL | `feet set:hoarfrost | dodge_cd |  | ` |
| frost_amulet | HOARFROST LOCKET | ORIGINAL | `trinket set:hoarfrost | crit | chill_crit | ` |
| plague_mask | PLAGUE DOCTOR'S MASK | ORIGINAL | `head set:plaguedoc | poison |  | ` |
| plague_coat | PLAGUE DOCTOR'S COAT | ORIGINAL | `body set:plaguedoc | max_hp |  | ` |
| plague_boots | PLAGUE DOCTOR'S BOOTS | ORIGINAL | `feet set:plaguedoc | speed | toxic_steps | ` |
| plague_censer | PLAGUE CENSER | ORIGINAL | `trinket set:plaguedoc | dmg | status_dmg | ` |
| thunder_helm | THUNDERBORN HELM | ORIGINAL | `head set:thunderborn | chain |  | ` |
| thunder_mail | THUNDERBORN MAIL | ORIGINAL | `body set:thunderborn | armor | spark_skin | ` |
| thunder_boots | THUNDERBORN BOOTS | ORIGINAL | `feet set:thunderborn | speed |  | ` |
| thunder_ring | THUNDERBORN SIGNET | ORIGINAL | `trinket set:thunderborn | rate | nth_zap | ` |
| butcher_cap | BUTCHER'S CAP | ORIGINAL | `head set:butcher | crit_mult |  | ` |
| butcher_apron | BUTCHER'S APRON | ORIGINAL | `body set:butcher | max_hp | kill_heal | ` |
| butcher_boots | BUTCHER'S CLOGS | ORIGINAL | `feet set:butcher | speed | close_dmg | ` |
| butcher_hook | BUTCHER'S HOOK | ORIGINAL | `trinket set:butcher | dmg | execute | ` |
| bastion_helm | BASTION GREATHELM | ORIGINAL | `head set:bastion | armor |  | ` |
| bastion_plate | BASTION PLATE | ORIGINAL | `body set:bastion | armor,max_hp |  | ` |
| bastion_boots | BASTION SABATONS | ORIGINAL | `feet set:bastion | thorns |  | ` |
| bastion_seal | BASTION SEAL | ORIGINAL | `trinket set:bastion |  | room_armor | ` |
| night_hood | NIGHTSTALKER COWL | ORIGINAL | `head set:nightstalker | evade |  | ` |
| night_cloak | NIGHTSTALKER CLOAK | ORIGINAL | `body set:nightstalker | roll_speed | roll_ambush | ` |
| night_boots | NIGHTSTALKER SOFTSTEPS | ORIGINAL | `feet set:nightstalker | dodge_cd,speed |  | ` |
| night_fang | NIGHTSTALKER FANG | ORIGINAL | `trinket set:nightstalker | crit | first_hit | ` |
| arch_hat | ARCHMAGE HAT | ORIGINAL | `head set:archmage | homing |  | ` |
| arch_robe | ARCHMAGE ROBE | ORIGINAL | `body set:archmage | dmg,size |  | ` |
| arch_boots | ARCHMAGE SLIPPERS | ORIGINAL | `feet set:archmage | shot_speed |  | ` |
| arch_orb | ARCHMAGE ORRERY | ORIGINAL | `trinket set:archmage | orbitals |  | ` |
| gild_crown | GILDED CIRCLET | ORIGINAL | `head set:gilded | luck |  | ` |
| gild_vest | GILDED VEST | ORIGINAL | `body set:gilded | max_hp | gold_dmg | ` |
| gild_boots | GILDED BOOTS | ORIGINAL | `feet set:gilded | shop_disc |  | ` |
| gild_ring | GILDED RING | ORIGINAL | `trinket set:gilded | gold_mult | gold_hit | ` |
| sapper_helm | SAPPER'S HELMET | ORIGINAL | `head set:sapper | bomb_r |  | ` |
| sapper_vest | SAPPER'S BLAST VEST | ORIGINAL | `body set:sapper | armor | bomb_immune | ` |
| sapper_boots | SAPPER'S BOOTS | ORIGINAL | `feet set:sapper | speed | roll_bomb | ` |
| sapper_fuse | SAPPER'S FUSE | ORIGINAL | `trinket set:sapper | shrapnel | bomb_on_kill | ` |
| shep_hat | SHEPHERD'S HAT | ORIGINAL | `head set:shepherd | fam_dmg |  | ` |
| shep_cloak | SHEPHERD'S CLOAK | ORIGINAL | `body set:shepherd | max_hp | kill_wisp | ` |
| shep_boots | SHEPHERD'S SANDALS | ORIGINAL | `feet set:shepherd | fam_rate |  | ` |
| shep_crook | SHEPHERD'S BELL | ORIGINAL | `trinket set:shepherd | familiars |  | ` |
| tinhelm | DENTED TIN HELM | ORIGINAL | `head | armor |  | ` |
| leathercap | LEATHER CAP | ORIGINAL | `head | max_hp |  | ` |
| huntershood | HUNTER'S HOOD | ORIGINAL | `head | crit |  | ` |
| scholarcap | SCHOLAR'S CAP | ORIGINAL | `head | xp_mult |  | ` |
| ironmask | IRON DEATHMASK | ORIGINAL | `head | dmg | low_hp_dmg | ` |
| owlhelm | OWL-EYED HELM | ORIGINAL | `head | life | far_dmg | ` |
| crownofthorns | CROWN OF THORNS | ORIGINAL | `head | poison,thorns | thorns_nova | ` |
| hornedhelm | HORNED WARHELM | ORIGINAL | `head | dmg,max_hp | kill_haste | ` |
| seerveil | SEER'S VEIL | ORIGINAL | `head | luck | trait_dmg | ` |
| kingscrown | CROWN OF THE LOST KING | ORIGINAL | `head | gold_mult,luck | relic_dmg | ` |
| stormcrownhelm | TEMPEST DIADEM | ORIGINAL | `head | chain,chain_jumps | crit_chain | ` |
| headsman | HEADSMAN'S HOOD | ORIGINAL | `head | crit | execute | ` |
| paddedjack | PADDED JACK | ORIGINAL | `body | max_hp |  | ` |
| chainshirt | CHAIN SHIRT | ORIGINAL | `body | armor,speed |  | ` |
| travelcloak | TRAVELLER'S CLOAK | ORIGINAL | `body | evade,speed |  | ` |
| acolyterobe | ACOLYTE ROBE | ORIGINAL | `body | rate |  | ` |
| bloodplate | BLOODSTAINED PLATE | ORIGINAL | `body | armor,max_hp | kill_heal | ` |
| spikedmail | SPIKED MAIL | ORIGINAL | `body | armor,thorns |  | ` |
| hunterscoat | MONSTER HUNTER'S COAT | ORIGINAL | `body | max_hp,potion_heal | elite_dmg | ` |
| smugglercoat | SMUGGLER'S COAT | ORIGINAL | `body | keys,max_potions |  | ` |
| mirrorplate | MIRROR PLATE | ORIGINAL | `body | armor | reflect_hit | ` |
| berserkerhide | BERSERKER HIDE | ORIGINAL | `body | armor,max_hp | low_hp_dmg | ` |
| phoenixmantle | PHOENIX MANTLE | ORIGINAL | `body | burn,max_hp | revive_g | ` |
| voidshroud | VOID SHROUD | ORIGINAL | `body | charges,dodge_charges,evade | roll_nova | ` |
| worntboots | WORN BOOTS | ORIGINAL | `feet | speed |  | ` |
| ironboots | IRON BOOTS | ORIGINAL | `feet | armor,speed |  | ` |
| sandals | PILGRIM SANDALS | ORIGINAL | `feet | dodge_cd |  | ` |
| runnersboots | COURIER BOOTS | ORIGINAL | `feet | speed | moving_dmg | ` |
| ninjatabi | SILENT TABI | ORIGINAL | `feet | charges,dodge_charges,roll_speed |  | ` |
| anchorboots | ANCHOR BOOTS | ORIGINAL | `feet | armor | still_dmg | ` |
| wingedboots | WINGED BOOTS | ORIGINAL | `feet | dodge_cd,speed | roll_zap | ` |
| coalwalkers | COALWALKERS | ORIGINAL | `feet | burn,speed | fire_steps | ` |
| sevenleague | SEVEN-LEAGUE BOOTS | ORIGINAL | `feet | dodge_cd,roll_speed,speed | moving_dmg | ` |
| luckycharm | RABBIT'S FOOT | ORIGINAL | `trinket | luck |  | ` |
| whetring | WHETSTONE RING | ORIGINAL | `trinket | dmg |  | ` |
| quickring | QUICKSILVER RING | ORIGINAL | `trinket | rate |  | ` |
| vialbelt | BELT OF VIALS | ORIGINAL | `trinket | max_potions,potions |  | ` |
| bombbag | POWDER BANDOLIER | ORIGINAL | `trinket | bombs |  | ` |
| toothnecklace | WOLF TOOTH NECKLACE | ORIGINAL | `trinket | crit,crit_mult |  | ` |
| hourglassamulet | SANDS OF ESCAPE | ORIGINAL | `trinket | charges,dodge_charges |  | ` |
| emberheartgem | EMBER HEART | ORIGINAL | `trinket | burn | fire_aura | ` |
| frostshard | SHARD OF WINTER | ORIGINAL | `trinket | chill | chill_crit | ` |
| venomsac | VENOM SAC | ORIGINAL | `trinket | poison | status_dmg | ` |
| stormbottle | BOTTLED LIGHTNING | ORIGINAL | `trinket | chain |  | ` |
| ledger | MERCHANT'S LEDGER | ORIGINAL | `trinket | shop_disc | room_gold | ` |
| vampirefang | VAMPIRE FANG | ORIGINAL | `trinket | crit | leech | ` |
| eyeofstorm | EYE OF THE STORM | ORIGINAL | `trinket | chain | nth_zap | ` |
| hollowidol | HOLLOW IDOL | ORIGINAL | `trinket | count,dmg | split | ` |
| grimoire | BLACK GRIMOIRE | ORIGINAL | `trinket | dmg | souls | ` |
| heartofglass | HEART OF GLASS | ORIGINAL | `trinket | dmg,max_hp | crit_explode | ` |
| dragonheart | DRAGON'S HEART | ORIGINAL | `trinket | burn,max_hp | kill_explode | ` |
| gamblerdie | GAMBLER'S LAST DIE | ORIGINAL | `trinket | crit,crit_mult,luck |  | ` |
| duel_hat | DUELIST'S FEATHERCAP | new | `head set:duelist | crit |  | on_room_enter>buff:crit` |
| duel_coat | DUELIST'S DOUBLET | new | `body set:duelist | max_hp |  | on_crit>buff:speed` |
| duel_boots | DUELIST'S STEPS | new | `feet set:duelist | speed |  | on_roll>buff:crit_mult` |
| duel_ring | DUELIST'S SIGNET | new | `trinket set:duelist | crit_mult |  | on_crit[if elite]>damage` |
| rav_helm | RAVAGER'S HELM | new | `head set:ravager | max_hp |  | on_damage_taken>buff:dmg` |
| rav_hide | RAVAGER'S HIDE | new | `body set:ravager | max_hp | low_hp_dmg | ` |
| rav_boots | RAVAGER'S TREADS | new | `feet set:ravager | speed |  | on_kill>buff:speed` |
| rav_tooth | RAVAGER'S FANG | new | `trinket set:ravager | dmg |  | on_damage_taken>buff:dmg` |
| hawkmonocle | HAWK MONOCLE | new | `head | crit | far_dmg | ` |
| razorcharm | RAZOR CHARM | new | `trinket | crit,overcrit |  | on_kill[if crit]>nova` |
| leechmail | LEECH-LINK MAIL | new | `body | armor | leech | ` |
| clotring | CLOTTING RING | new | `trinket | bleed |  | on_kill[if bleeding]>heal` |
| butchermask | SCARLET HOOD | new | `head | dmg |  | on_room_enter>hurt_self+buff:dmg` |
| ashcloak | ASHEN CLOAK | new | `body | burn | fire_aura | ` |
| cinderboots | CINDER SANDALS | new | `feet | speed |  | on_roll>explode` |
| kilnheart | KILN HEART | new | `trinket | burn |  | on_kill[if burning]>explode` |
| rotgloves | ROTTING WRAPS | new | `body | poison |  | on_room_enter>status_area:poison` |
| miasmamask | MIASMA MASK | new | `head | poison | status_dmg | ` |
| blightboots | BLIGHTSTEP BOOTS | new | `feet | speed | toxic_steps | on_roll>status_area:poison` |
| conductorhelm | CONDUCTOR'S HELM | new | `head | chain,chain_jumps |  | on_roll>bolts` |
| staticboots | STATIC STRIDERS | new | `feet | speed |  | on_roll>status:shock` |
| lightningrod | LIGHTNING ROD | new | `trinket | rate |  | every_n_seconds>lightning` |
| splittinglens | SPLITTING LENS | new | `head | shot_speed | split | ` |
| volleyrobe | VOLLEY ROBE | new | `body | count |  | every_n_shots>shoot_at` |
| ricochetband | RICOCHET BAND | new | `trinket | ricochet |  | on_kill>bolts` |
| beekeeperhat | KEEPER'S VEIL | new | `head | fam_dmg |  | on_pickup>summon` |
| broodcloak | BROOD CLOAK | new | `body | max_hp |  | on_damage_taken>summon` |
| callingwhistle | CALLING WHISTLE | new | `trinket | fam_rate,familiars |  | on_level_up>summon` |
| fadingcowl | FADING COWL | new | `head | evade |  | on_roll>buff:dmg` |
| silkboots | SILKEN SLIPPERS | new | `feet | dodge_cd,roll_speed |  | on_roll>push` |
| mirrorcape | MIRROR CAPE | new | `body | charges,dodge_charges |  | on_roll>clear_shots` |
| anvilhelm | ANVIL HELM | new | `head | armor,speed |  | on_damage_taken>status_area:stun` |
| thornplate | BRAMBLE PLATE | new | `body | thorns | thorns_nova | ` |
| oathstone | OATHSTONE | new | `trinket | max_hp |  | on_room_clear>armor` |
| skullcap | BATTLE SKULLCAP | new | `head | dmg |  | while_low_hp>buff:dmg` |
| bloodboil | BLOODBOIL VIAL | new | `trinket | rate |  | on_kill>buff:rate` |
| merchantshat | MERCHANT'S TRICORN | new | `head | gold_mult |  | on_room_clear>gold` |
| coinpurse | BOTTOMLESS PURSE | new | `trinket | luck | gold_dmg | ` |
| goldtoes | GOLD-TOED BOOTS | new | `feet | shop_disc,speed |  | on_roll>drop` |
| thornedcrown | CROWN OF SPITE | new | `head | dmg,max_hp |  | on_kill[if full_hp]>buff:dmg` |
| hexedmantle | HEXED MANTLE | new | `body | max_hp |  | on_hit>status:curse` |
| grudgeboots | GRUDGE BOOTS | new | `feet | speed |  | on_damage_taken>status:curse+status:vulnerable` |
| blackpearl | BLACK PEARL | new | `trinket | max_hp |  | on_kill[if cursed]>explode; pct:dmg` |
| pilgrimpack | PILGRIM'S PACK | new | `body | max_potions,potion_heal |  | on_floor_start>drop` |
| luckyhorseshoe | BENT HORSESHOE | new | `trinket | luck |  | on_kill>gold` |
| scoutboots | SCOUT'S BOOTS | new | `feet | speed |  | on_room_enter>buff:speed` |
| tinkerhelm | TINKER'S GOGGLES | new | `head | bomb_r |  | on_room_clear>drop` |
| frostwardcoat | FROSTWARD COAT | new | `body | armor,chill |  | on_damage_taken>status:weakened` |
| brawlerwraps | BRAWLER'S WRAPS | new | `hands | rate |  | every_n_shots>push` |
| ironfist | IRON FIST | new | `hands | armor |  | on_damage_taken>damage` |
| pickpocket | PICKPOCKET'S GLOVES | new | `hands | gold_mult |  | on_hit>gold` |
| alchemistmitts | ALCHEMIST'S MITTS | new | `hands | potion_heal |  | on_potion>status_area:poison+vfx:ring` |
| flintgloves | FLINT GLOVES | new | `hands | burn |  | on_crit>status:burn` |
| frostgrip | FROSTGRIP | new | `hands | chill |  | on_roll>status_area:chill` |
| duelistgauntlet | PARRYING GAUNTLET | new | `hands | crit |  | on_roll[if danger]>clear_shots+vfx:label` |
| quickdraw | QUICKDRAW GLOVES | new | `hands | rate |  | on_weapon_swap>buff:rate` |
| stormknuckles | STORM KNUCKLES | new | `hands | chain |  | on_crit>status:shock` |
| gravedigmitts | GRAVEDIGGER'S MITTS | new | `hands | bomb_mult,bombs |  | on_kill>drop` |
| beastglove | BEASTMASTER'S GLOVE | new | `hands | fam_dmg |  | on_room_clear>summon` |
| midasglove | TOUCH OF MIDAS | new | `hands | gold_mult | gold_dmg | on_kill>drop+drop` |
| boneamulet | BONE AMULET | new | `neck | curse |  | on_kill[if cursed]>heal` |
| hourglass | SANDS OF RESPITE | new | `neck | dodge_cd |  | on_room_enter>refund_roll` |
| phylactery | CRACKED PHYLACTERY | new | `neck | max_hp |  | grant:revive; on_floor_start>armor` |
| stormeye | EYE OF THE GALE | new | `neck | chain_jumps |  | every_n_seconds[if fighting]>status:shock` |
| emberheart | EMBER LOCKET | new | `neck | burn |  | on_damage_taken>status_area:burn` |
| wolftooth | WOLF-TOOTH CHARM | new | `neck | crit |  | on_crit[if bleeding]>heal` |
| frostlocket | WINTER LOCKET | new | `neck | armor |  | on_damage_taken>clear_shots` |
| sagestone | SAGE'S STONE | new | `neck | xp_mult |  | on_level_up>nova` |
| dragonscale | DRAGONSCALE PENDANT | new | `neck | dmg |  | every_n_seconds[if low_hp]>explode` |
| deckpendant | THE LAST CARD | new | `neck | luck |  | every_n_seconds[if fighting]>card` |
| copperband | COPPER BAND | new | `ring | chain |  | on_hit[if shocked]>chain` |
| whetband | WHETSTONE RING | new | `ring | crit_mult |  | on_crit>status:bleed` |
| cinderring | CINDER RING | new | `ring | burn |  | on_kill[if burning]>zone` |
| swiftring | RING OF HASTE | new | `ring | speed |  | on_shoot[if moving]>buff:rate` |
| goldband | GOLD BAND | new | `ring | gold_mult |  | on_room_clear>gold` |
| venomring | ASP RING | new | `ring | poison |  | on_kill[if poisoned]>status:poison` |
| bloodring | BLOOD-PACT RING | new | `ring | dmg |  | on_room_enter>hurt_self` |
| echoring | RING OF ECHOES | new | `ring | echo |  | on_room_enter>buff:echo` |
| thornring | THORNED RING | new | `ring | thorns |  | on_damage_taken>buff:dmg` |
| wispring | WISP-CALLER RING | new | `ring | fam_rate |  | on_kill>summon` |
| ragering | RING OF RANCOR | new | `ring |  | low_hp_dmg | ` |
| bombring | FUSE RING | new | `ring | bomb_mult |  | on_room_clear>drop` |
| seersring | SEER'S RING | new | `ring | crit,homing |  | on_crit>status:mark` |
| doomring | RING OF DOOM | new | `ring | curse |  | on_kill[if cursed]>explode+status_area:curse` |
| conclave_gloves | CONCLAVE GLOVES | new | `hands set:conclave | rate |  | every_n_shots>buff:rate` |
| conclave_sigil | CONCLAVE SIGIL | new | `neck set:conclave | count |  | on_level_up>nova` |
| conclave_ring_a | CONCLAVE RING OF DUSK | new | `ring set:conclave | homing |  | on_kill>buff:homing` |
| conclave_ring_b | CONCLAVE RING OF DAWN | new | `ring set:conclave | pierce |  | on_hit[if elite]>status:vulnerable` |
| hunt_hood | HEADHUNTER'S HOOD | new | `head set:headhunter | crit |  | on_kill[if elite]>buff:crit` |
| hunt_coat | HEADHUNTER'S COAT | new | `body set:headhunter | max_hp |  | on_kill[if elite]>armor` |
| hunt_gloves | HEADHUNTER'S GLOVES | new | `hands set:headhunter | crit_mult |  | on_hit[if elite]>status:bleed` |
| hunt_boots | HEADHUNTER'S BOOTS | new | `feet set:headhunter | speed |  | on_kill[if elite]>refund_roll` |
| mirehelm | MIRE-DIVER'S HELM | new | `head | armor,poison |  | on_damage_taken>zone` |
| monkrobe | MONK'S HABIT | new | `body | charges,dodge_charges |  | on_roll[if danger]>status_area:chill` |
| warcloak | WAR-TORN CLOAK | new | `body | dmg |  | on_room_enter>buff:dmg` |
| rooftopboots | ROOFRUNNER BOOTS | new | `feet | roll_speed,speed |  | on_roll>buff:rate` |
| eclipsecrown | CROWN OF THE ECLIPSE | new | `head | dmg |  | on_floor_start>scroll` |
| snowtreads | SNOW TREADS | new | `feet | chill |  | on_room_enter>status_area:chill` |
| jester_cap | JESTER'S CAP | new | `head set:jester | crit |  | on_crit>chaos` |
| jester_coat | JESTER'S MOTLEY | new | `body set:jester | max_hp |  | on_damage_taken>push` |
| jester_shoes | JESTER'S CURLY SHOES | new | `feet set:jester | speed |  | on_roll>drop` |
| jester_bauble | JESTER'S BAUBLE | new | `trinket set:jester | gold_mult |  | on_crit>gold` |
| star_helm | STARFALL CROWN | new | `head set:starfall | burn |  | on_level_up>meteor` |
| star_plate | STARFALL PLATE | new | `body set:starfall | armor |  | on_damage_taken>meteor` |
| star_gloves | STARFALL GAUNTLETS | new | `hands set:starfall | bomb_mult |  | on_kill>bomb` |
| star_boots | STARFALL GREAVES | new | `feet set:starfall | speed | fire_steps | on_roll>nova` |
| void_cowl | VOIDWALKER COWL | new | `head set:voidwalker | evade |  | on_roll>invuln` |
| void_wraps | VOIDWALKER WRAPS | new | `hands set:voidwalker | dodge_cd |  | on_roll>status_area:weakened` |
| void_amulet | VOIDWALKER LOCKET | new | `neck set:voidwalker | charges,dodge_charges |  | on_roll[if low_hp]>heal` |
| void_ring | VOIDWALKER BAND | new | `ring set:voidwalker | curse |  | on_hit[if cursed]>status:weakened` |
| magnethelm | MAGNET HELM | new | `head | armor |  | every_n_seconds[if fighting]>pull+status_area:shock` |
| partyhat | PARTY HAT | new | `head | xp_mult |  | on_level_up>nova+gold+vfx:label` |
| thirdeye | THIRD EYE | new | `head | crit,homing |  | on_crit>rand_status` |
| bombvest | POWDERKEG VEST | new | `body | armor,bombs | bomb_immune | on_damage_taken>bomb` |
| giantbelt | GIANT'S GIRDLE | new | `body | max_hp,size |  | on_kill>buff:size` |
| ghostsheet | BEDSHEET GHOST | new | `body | evade |  | on_damage_taken>clear_shots+invuln+vfx:label` |
| hedgehogmail | HEDGEHOG MAIL | new | `body | armor,thorns |  | every_n_seconds[if fighting]>nova` |
| rocketboots | ROCKET BOOTS | new | `feet | roll_speed |  | on_roll>explode+zone` |
| slipperysoles | BUTTERED SOLES | new | `feet | speed |  | on_roll>status_area:stun` |
| springheels | SPRING HEELS | new | `feet | dodge_cd |  | on_roll>buff:speed` |
| goldengoose | GOLDEN GOOSE | new | `trinket | luck | gold_dmg | every_n_seconds[if fighting]>drop` |
| chaosdie | CHAOS DIE | new | `trinket | luck |  | on_kill>chaos; on_room_enter>chaos` |
| pocketsun | POCKET SUN | new | `trinket | burn | fire_aura | every_n_seconds[if fighting]>status_area:burn+vfx:ring` |
| stormcloud | PET STORMCLOUD | new | `trinket | chain |  | every_n_seconds[if fighting]>bolts` |
| boxinggloves | BOXING GLOVES | new | `hands | dmg |  | every_n_shots>area+push` |
| fireworkmitts | FIREWORK MITTS | new | `hands | crit |  | on_crit>nova` |
| puppetstrings | PUPPETEER'S STRINGS | new | `hands | familiars |  | on_hit>summon` |
| monkeypaw | MONKEY'S PAW | new | `hands | luck |  | on_room_enter>chaos; on_room_enter>hurt_self; pct:dmg` |
| cowbell | LOUD COWBELL | new | `neck | max_hp |  | on_damage_taken>status_area:stun+vfx:ring` |
| collapsedstar | COLLAPSED STAR | new | `neck | dmg |  | every_n_seconds[if fighting]>pull+area+vfx:sigil` |
| ricochetring | RING OF REBOUNDS | new | `ring | bounce,ricochet |  | on_hit>shoot` |
| bigring | RING OF BIGNESS | new | `ring | size |  | on_kill>explode` |
| tinyring | RING OF SMALLNESS | new | `ring | rate,size |  | on_roll>clear_shots` |
| twinring | TWIN-SOUL RING | new | `ring | count,echo |  | every_n_shots>shoot_at` |
| toadring | TOAD RING | new | `ring | poison |  | on_kill[if poisoned]>zone` |
| rime_hood | RIMEWARDEN HOOD | new | `head set:rimewarden | chill |  | on_hit[if far]>status:chill` |
| rime_mantle | RIMEWARDEN MANTLE | new | `body set:rimewarden | armor |  | on_armor_lost>status_area:chill+status_area:stun+vfx:ring` |
| rime_grip | RIMEWARDEN GRIP | new | `hands set:rimewarden | crit |  | on_kill[if chilled]>spread` |
| rime_bell | RIMEWARDEN BELL | new | `neck set:rimewarden | dmg |  | every_n_seconds[if fighting]>turret` |
| blast_goggles | BLASTWRIGHT GOGGLES | new | `head set:blastwright | bomb_mult |  | on_bomb>invuln` |
| blast_apron | BLASTWRIGHT APRON | new | `body set:blastwright | max_hp |  | on_kill>give` |
| blast_mitts | BLASTWRIGHT MITTS | new | `hands set:blastwright | bombs |  | on_bomb>turret` |
| blast_ring | BLASTWRIGHT BAND | new | `ring set:blastwright | bomb_r |  | on_room_clear>give` |
| bone_crown | BONECALLER CROWN | new | `head set:bonecaller | fam_dmg |  | on_kill[if elite]>raise` |
| bone_ribs | BONECALLER RIBCAGE | new | `body set:bonecaller | max_hp |  | on_damage_taken>raise` |
| bone_rattle | BONECALLER RATTLE | new | `neck set:bonecaller | familiars |  | on_level_up>raise+raise` |
| bone_ring | BONECALLER SIGNET | new | `ring set:bonecaller | curse |  | on_hit[if cursed]>consume` |
| clock_monocle | CLOCKWORK MONOCLE | new | `head set:clockwork | crit |  | on_hit[if fresh]>damage` |
| clock_coat | CLOCKWORK COAT | new | `body set:clockwork | armor |  | on_armor_lost>turret` |
| clock_boots | CLOCKWORK BOOTS | new | `feet set:clockwork | speed |  | on_roll>turret` |
| clock_key | CLOCKWORK KEY | new | `trinket set:clockwork | rate |  | every_n_seconds[if fighting]>turret` |
| lastriteshood | HOOD OF LAST RITES | new | `head | crit_mult |  | on_hit[if last_foe]>damage` |
| polishedcuirass | POLISHED CUIRASS | new | `body | armor |  | on_armor_lost>reflect` |
| ghoststeps | GHOST STEPS | new | `feet | evade |  | on_dodge>buff:dmg` |
| abbotsandals | ABBOT'S SANDALS | new | `feet | speed |  | on_overheal>armor` |
| iceskates | ICE SKATES | new | `feet | speed |  | on_roll[if crowd]>status_area:chill+status_area:stun` |
| magpieboots | MAGPIE BOOTS | new | `feet | speed |  | on_pickup[if coin]>buff:rate` |
| unscathedmedal | UNSCATHED MEDAL | new | `trinket | crit |  | on_room_clear[if unhurt]>gold+buff:dmg+vfx:label` |
| bribepurse | BRIBE PURSE | new | `trinket | gold_mult | gold_guard | ` |
| treasuremap | TREASURE MAP | new | `trinket | luck |  | on_chest>give` |
| voodoodoll | VOODOO DOLL | new | `trinket | curse |  | on_damage_taken>damage+status:curse` |
| leechgloves | LEECH GLOVES | new | `hands | dmg |  | on_kill[if close]>heal` |
| catalystgloves | CATALYST GLOVES | new | `hands | burn |  | on_crit>consume` |
| plaguehand | PLAGUE HAND | new | `hands | poison |  | on_hit[if poisoned]>spread` |
| pickpocketgloves | PICKPOCKET GLOVES | new | `hands | rate |  | on_hit[if fresh]>gold` |
| bouncerknuckles | BOUNCER'S KNUCKLES | new | `hands | dmg |  | on_hit[if close]>status:stun+push` |
| saintsmedallion | SAINT'S MEDALLION | new | `neck | max_hp |  | on_overheal>nova` |
| mirrorpendant | MIRROR PENDANT | new | `neck | evade |  | on_dodge>reflect` |
| howlertooth | HOWLER'S TOOTH | new | `neck | dmg |  | every_n_seconds[if crowd]>buff:dmg+vfx:label` |
| houndcollar | BLOODHOUND COLLAR | new | `neck | crit |  | on_hit[if bleeding]>heal` |
| merchantscharm | MERCHANT'S CHARM | new | `neck | shop_disc |  | on_buy>give` |
| excessring | RING OF EXCESS | new | `ring | dmg |  | on_kill>overkill` |
| frostbitering | FROSTBITE RING | new | `ring | chill |  | on_crit[if chilled]>status:stun` |
| returnring | RING OF RETURNING | new | `ring | rate |  | on_weapon_swap>nova+clear_shots` |
| kindlingring | KINDLING RING | new | `ring | burn |  | on_potion>status_area:burn+vfx:ring` |

