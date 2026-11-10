# Traits and infusions from his pictures (10 Oct)

His word (10 Oct, 00:53 to 00:55): "Im gonna send you more pictures of a traits and how needs to look
in my game, include all listed traits and pictures of traits" and "Also add infusion mechanics".
18 screenshots of a wiki: Strength, Dexterity, Intelligence, Super Hero, Esper and (removed) Cyborg
traits, and the infusions.

**Rule 3 still holds:** ideas and kinds of things only. Every trait gets **our own name and our own
picture** (drawn by tools/art). The reference names below are only here so he can check that every
one he listed is in; they never appear in the game.

## The look

Each trait gets its own picture: a 16 x 16 single-colour pixel icon, drawn at 2x in the framed
square box of the trait row (TraitView._row), on a dark ground, frame and icon in the trait's colour:

| Group | Colour | Our families in it |
|---|---|---|
| STR | pink-red `#ff3b6b` | fury, bulwark, blood, demolition |
| DEX | green `#3cf06e` | edge, shadow, fortune |
| INT | blue `#36b4ff` | arcane, pyre, frost, storm, venom, malice, swarm |
| SUPER | red `#ff3a2e` | super traits |
| PSYCHIC (Esper) | pink `#e889c8` | the Mindwarden's own |
| AUGMENT (Cyborg) | grey `#8b8f9c` with a coloured core | the Tinkerer's own |

Traits without their own picture yet keep their family glyph, in their group's colour.

## Shared mechanics (built once, used by many traits)

| In his pictures | In our game |
|---|---|
| Power | POWER, a new stat: +1% damage a point |
| Skill, On Skill Used, Skill Effect | the hero's SPECIAL (trigger on_special; gf special_power) |
| Stamina, Stamina Container, Recovery Speed | ROLL charges and their recharge |
| Mana, Mana Container, Mana Recovery, missing Mana | the SPECIAL's charge: max charge, recharge speed, charge still missing |
| Soul Hearts, Armor Containers | ARMOR (the blue hearts) and its maximum |
| Equip Load | gear pieces worn (and their rarity) |
| Block | the offhand's block (block.gd) |
| Tick Speed | how fast burn, poison and bleed tick (gf tick_speed) |
| Orbitals | MOONS |
| Auras | the halo fields (auras.gd) |
| Companions, Companion Capacity | the helpers of 34.2 (legion.gd) |
| Booze Buffs | drink buffs (36.3) |
| Infusion Buffs | INFUSIONS (new, below) |
| Lucky Hits | as now (34.1) |
| Crushing, Lethal, Ruthless, Sneaky, Cursed Hits | five new HIT KINDS, each a chance: crushing = +50% damage and wears a plate 3x; lethal = +100% on a foe under half health; ruthless = ignores a foe's guard and +30%; sneaky = +60% on a foe not facing you or asleep; cursed = curses the foe |
| Courage, Morale, Tailwind, Berserk, Rage, Burning Passion | named BUFFS (damage, rate, speed; stacks shown on the HUD) |
| Instability, Crush, Puncture, Rupture, Fatigue, Fragility, Scorch, Frostbite, Zap, Disintegration, Taunt, Intimidate | new statuses where nothing fits (instability builds to a stun; puncture and rupture are bleeds that grow; disintegration takes a share of health), else ours: fatigue = weakened, fragility = vulnerable, scorch / frostbite / zap = a burn, chill, shock mark that hits harder, taunt / intimidate = foes deal less damage |
| Tally of N Attacks | every_n_shots |
| Repeat an Attack | the next attack fires twice |
| Damage types (slashing, striking, thrusting, radiant, dark, nature, necrotic) | from the weapon's kind (slash, spin/slam, thrust) and its tags (holy, shadow, venom...) |

## STRENGTH (38)

| His list | What it does there | Ours |
|---|---|---|
| Adrenaline | +1 missing heart; +25% emotion effect per missing heart | +1 empty heart; +X% buff power per missing heart |
| An Honest Day of Work | stamina recovery mods also boost skill effect | roll recharge bonuses also power the special |
| Ancestral Aid | 2 spirit companions; each +10% attack speed | 2 spirit helpers; each +10% fire rate |
| Arrogance | on taunt or charm, x1.4 non-crit damage 8 s | on taming or taunting, x1.4 non-crit damage 8 s |
| Attack of Opportunity | after 2 s without attacking, next attack gives Courage | the same, COURAGE buff |
| Barbarism | +5% crit damage per STR | the same |
| Battle Rush | +25 power at +10/20/30% move speed | the same |
| Beef | x2 STR stats, x0.5 DEX and INT | the same |
| Berserk | on skill used, Berserk | on special, BERSERK |
| Blessed Hammer | 25% of attacks drop a holy hammer | the same, a hammer from the sky |
| Blunt Trauma | striking damage inflicts instability | spin/slam hits build INSTABILITY |
| Bone Crusher | crushing hits inflict crush (x0.5 ranged/magic) | the same |
| Boozer | booze buffs permanent, +100% effect | drink buffs for good and doubled |
| Brawler | +20 power per actor in room (max +100) | the same (you, helpers, foes) |
| Brawn Over Brain | +25% mana recovery per STR trait | special recharge per STR trait |
| Close Combat | +100% ruthless hit chance at close range | the same |
| Explosive Force | 40% of attacks explode on hit | the same |
| Fire and Blood | burn and bleed stack 10x, deal x0.35 | the same |
| Hand of Hearts | +15% lucky hit chance per heart container | the same |
| Heavy Draw | half STR applies to DEX scaling of ranged | the same |
| Holy Fire | radiant damage gives Burning Passion | holy damage gives BURNING PASSION |
| Momentum | +50% stamina recovery; on dash next 5 attacks crush | roll recharge; after a roll, 5 crushing hits |
| No Pain No Gain | cursed hit chance mods also apply to crit | the same |
| Overwhelming Presence | +0.25% buff effect per equip load | buff power per gear worn |
| Pack Mentality | damage rolls twice, takes lower; +1 companion | the same |
| Pointy End | thrusting damage inflicts puncture | thrust hits inflict PUNCTURE |
| Power is Power | power also increases debuff effect | the same |
| Pushing Through | per equip load: +0.3% stamina rec, speed, damage | per gear worn |
| Rage | attacks give a rage stack, melee 5 | RAGE stacks |
| Razors Edge | slashing damage inflicts bleed | slash hits bleed |
| Resolute Technique | crit chance 0%; +100% crushing hit chance | the same |
| Savage Wounds | your and companions' attacks tick DoTs | the same |
| Shrouded In Shadows | 3 shadow orbitals; inflict all gloom at once | 3 shadow moons |
| Steady Strikes | attack speed mods x0.5, and apply to damage at 200% | the same |
| Testudo | x1.20 melee damage per block | the same |
| Threat Reckoning | one-handed taunt, two-handed intimidate | the same by weapon kind |
| Titan Grip | offhand with two-handed weapons | the same |
| Unforgiving | skill damage vulnerability; skill debuffs +100% | special's hits: vulnerable, debuffs doubled |

## DEXTERITY (39; one row may be missing between Transcendence and Trigger Maniac)

| His list | What it does there | Ours |
|---|---|---|
| Advanced Ballistics | ranged damage always at close range | the same |
| Agility | move speed mods also apply to attack speed | the same |
| Alacrity | +40% attack speed with DEX weapons | the same |
| Ascetic's Discipline | +25% skill effect per stamina | special power per roll charge |
| Best Friends Forever | companions' stats +300/200/100% at 1/2/3 | the same |
| Blood Infection | bleed ticks give 5 poison | the same |
| Cheap Shot | lucky hits are also lethal hits | the same |
| Chill Aura | chill aura, 4 ticks a second | a frost field |
| Cull the Weak | slowed foes take more; every 4 s fatigue the weakest | the same |
| Deadly Toxins | each poison stack +1% crit chance taken | the same |
| Dynamo | move speed mods apply to stamina and mana recovery at 200% | to roll and special recharge |
| Earned Luck | +2.5% lucky hit chance per DEX | the same |
| Electric City | each shock stack +25% crit damage taken | the same |
| Exit Strategy | on dash, refresh DoTs and tick them per stamina | on roll |
| Exploitative Explosives | explosions inflict vulnerability | the same |
| Grenadier | every 4 s a grenade throw | the same |
| Harmony | +radiant with cursed hits, +dark with lucky hits | the same |
| Influence | +30% attack speed per aura (you and companions) | per halo |
| Illusion Of Control | lucky hit mods apply to crit damage at 150% (max +250%) | the same |
| Intuition | x2 DEX stats, x0.5 STR and INT | the same |
| Lethality | lethal hit bonus uses crit damage | the same |
| Lightning Conductor | 25% chain lightning on hit | the same |
| Like Clockwork | attack speed mods apply to tick speed | the same |
| Opportunistic | few foes: x1.2 far; many: x1.3 close | the same |
| Pet The Dog | a puppy companion, +50% buff effect | a pup helper |
| Point Blank | +100% crushing hit chance, ranged at close range | the same |
| Poison Aura | poison aura, 4 ticks a second | a venom field |
| Precision | +5% crit chance per DEX trait | the same |
| Raised Morale | combat room without damage: +1 Morale | the same, MORALE |
| Repeat Offender | debuffs +100% if you repeated an attack lately | the same |
| Rogue's Tally | every 3rd attack: next is a sure crit | the same |
| Sharpshooter | +100% lethal hit chance at far range | the same |
| Spellblade | +20% attack speed per missing mana | per special charge missing |
| Spinning Blades | 2 blade orbitals that inflict rupture | 2 blade moons |
| Step of the Wind | on dash, 5 Tailwind | on roll, TAILWIND |
| Swagger | every 4 s trigger on-dash effects | on-roll effects every 4 s |
| Transcendence | infusion buffs permanent | the same |
| Trigger Maniac | x1.10 trigger damage per weapon upgrade | the same |
| Two Steps Ahead | on dash, repeat the next 2 attacks, repeats x2 | on roll |

## INTELLIGENCE (38)

| His list | What it does there | Ours |
|---|---|---|
| Anatomical Knowledge | +200% crit damage vs bleeding | the same |
| Apocalypse | on skill used, 3 meteors | on special |
| Arcane Familiar | an arcane familiar companion, +1 mana | an arcane helper |
| Astromancy | lucky hits x4 trigger chance (from x2) | the same |
| Bramble Growth | nature damage bleeds; nettles x2 | the same |
| Burn Aura | burn aura, 4 ticks a second | a fire field |
| Chrono Shift | on skill used, +100% tick speed 10 s | on special |
| Cold Blood | chill: +20% chance to take a crit | the same |
| Combustion | burn +100% and splashes | the same |
| Corrosive Magic | necrotic and poison inflict fragility | the same |
| Dominance | per INT: +1.25% buff effect, +1.25% aura radius | the same |
| Dreamer | +20 power per mana container (max +100) | per special charge |
| Elemental Balance | lightning, fire, cold each boost the next element | the same |
| Elemental Focus | fire, cold, lightning of skills and auras: scorch, frostbite, zap | the same |
| Entropy | mana recovery mods apply to DoTs | special recharge mods |
| Event Horizon | +100% orbital range; orbitals inflict vulnerability | moons |
| Forethought | hearts count as soul hearts; +2 hearts each floor | the same with armor |
| Hex Touch | debuff effect + cursed hit chance (max +100%) | the same |
| Ice Conjuration | 35% of attacks: 3 ice shards | the same |
| Ignition Burst | +fire damage to explosions | the same |
| Insight | +25% skill effect per INT trait | special power |
| Inspiring Presence | power also boosts companion damage at 200% | the same |
| Keen Mind | x2 INT stats, x0.5 STR and DEX | the same |
| Lightning Always Strikes Twice | lightning repeats after 0.5 s | the same |
| Mageblood | potion buffs permanent | the same |
| Mana Beacon | x1.10 companion damage per mana container | per special charge |
| Nature's Boon | every 3rd attack: a razor leaf | the same |
| Normal Distribution | lucky hit mods apply to tick and orbital speed | the same |
| Pocket Magic | every 1 s, an attack of a random backpack wand or staff | the same |
| Power Hungry | +20 power per soul heart (max +100) | per armor |
| Prodigy | +50% lucky hit chance; x2 cursed hit chance | the same |
| Shock Aura | shock aura, 4 ticks a second | a storm field |
| Static Blows | max shock stacks: consumed for a lightning strike | the same |
| Strong Together | +2 companion capacity; x0.5 companion stats | the same |
| Thaumaturgical Echo | every 3rd attack: repeat the next | the same |
| Trickery | +20% sneaky hit chance per common or uncommon item worn | the same |
| Vision Quest | every 30th attack: on-skill effects and +100% damage 8 s | the same |
| Zoo Utopia | you and companions x1.05 damage per companion | the same |

## SUPER (15): rare SUPER traits for every hero (the pink row of the odds panel)

Super Protection (+5 armor, armor counts as hearts), Super Fortune (+5 luck, magic find, treasure
find), Super Reflexes (+20 DEX, counts as 6 DEX traits), Super Health (+3 empty hearts, all hearts
back after each fight), Super Rich (gold counts as 1000 for everything that grows with gold),
Super Smarts (+20 INT, 6 INT traits), Super Speed (+100% speed, Tailwind for good), Super Stamina
(+3 rolls, rolls recharge twice as fast), Super Strength (+20 STR, 6 STR traits), Super Charged (a
roll strikes every foe with lightning; chain lightning every 0.67 s), Super Devoted (+4 of every
alignment; revived once a floor; no curses), Super Drunkard (+30 tipsy cap; 10 random drinks), Super
Friendly (+3 helpers at once, helpers +100%), Super Lazy (+25% damage per empty gear slot, max
+250%; all foes wither every 0.5 s), Super Magi-Tech Metabolism (special charge x3; +1 STR, DEX
and INT per charge).

## PSYCHIC (11): the Mindwarden's own (Esper only)

Energy Aura (+30 power; a field that unmakes), Lightning Force (+4 shocks at once; every 3rd attack a
psi-bolt), Mama's Stuff (3 knife moons that bleed; bleeds tick faster per moon), Mental Link
(companion damage bonuses also yours at 25%; exactly one helper: +400%), Papa's Stuff (+20% ranged
crit; 2 rifle helpers, each +75% crit damage), Psionic Bombardment (standing still: faster ticks;
every 2 s, 5 psi-blasts), Spontaneous Combustion (burns take a share of health; 10% of hits a fire
burst), Elemental Complexion (all foes: burn every 8 s, chill 4 s, shock 2 s, poison 1 s), Mere
Marionettes (+2 helpers, helpers x0.3), Mastering Randomness (a die every room; +2.5% lucky hits
per die used), Time Dilation (+10% special power per special used; +1 room of potion and infusion
buffs per special used).

## AUGMENT (5 or more; "removed" there): the Tinkerer's own

Freezing Core (special +cold damage), Laser Core (on special: a laser every 0.4 s for 8 s), Lucky
Core (on special: +100% lucky hits 8 s), Mana Core (+20% special recharge per level, max +120%),
Power Core (power also gives special power). The picture was cut after Power Core: if he has more,
they go here.

## INFUSIONS (14): a new consumable that adds an element to the weapon

Used from the belt like a drink; adds flat damage of an element to every weapon hit, for 10 rooms
(resins, the holy water) or for good (spices, fresh resins). TRANSCENDENCE makes all of them last
for good; TIME DILATION adds rooms. From chests, shops and some elites. Our own names and pictures.

| His list | Element | Damage | Lasts |
|---|---|---|---|
| Blue Spice | cold | 15-35 | for good |
| Charcoal Pine Resin | fire | 10-40 | 10 rooms |
| Crystal Pine Resin | cold | 15-35 | 10 rooms |
| Fairy Pine Resin | gives another resin | - | - |
| Fresh Charcoal Pine Resin | fire | 30-70 | for good |
| Fresh Crystal Pine Resin | cold | 45-60 | for good |
| Fresh Gold Pine Resin | lightning | 5-100 | for good |
| Gold Pine Resin | lightning | 5-50 | 10 rooms |
| Green Spice | poison | 20-30 | for good |
| Holy Water | holy | 35-50 | 10 rooms |
| Maple Pine Resin | nature | 15-35 | 10 rooms |
| Red Spice | fire | 10-40 | for good |
| Spore Pine Resin | poison | 25-30 | 10 rooms |
| Yellow Spice | lightning | 5-50 | for good |

Numbers there are for their scale; ours are scaled to our weapons (a few points a hit, growing by
floor), and each element also carries its ailment (fire burns, cold chills, lightning shocks, poison
poisons, holy hits harder on cursed and evil foes, nature bleeds).
