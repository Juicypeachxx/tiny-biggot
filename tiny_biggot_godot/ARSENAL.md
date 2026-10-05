# The hundred new weapons (ROADMAP 4.6)

His ask on 5 Oct: a hundred new weapons in four parts of 25, an IPA after each part. Ideas from
Enter the Gungeon, Slay the Spire, Worms, Risk of Rain, Cabal, Aion, GTA V, Saints Row: The Third
and Dead Cells. Ideas only: every name, picture and number is this game's own. Expanded game only:
the original game (`--classic`) never offers them, and its replays do not change.

## +1 projectile without limit

A weapon of a new kind throws at most a few things at once (`Arsenal.KEEP`: 2 to 5). Every
projectile past that is merged into the ones thrown: +35% damage each, and a wider blast (up to
twice as wide). A swarm or a line of bombs grows a little (up to 16 missiles, 12 bombs) and then
merges the same way. Thrown things never pass 48 at once (`MAX_LIVE`); more are folded into the
newest one's damage. A fist with a planted charge merges the count into the charge. The test gives
every weapon 999 more projectiles and checks the caps, the logic time and that it hurts more.

## Part 1: MAYHEM (explosives and mischief)

Nine new attack kinds (`scripts/combat/arsenal.gd`): grenade, rocket, missile, sticky, mortar,
walker, strike, dynamite, wave. Grenades and dynamite are aimed: they come to rest by the foe
nearest your aim (no farther than the arm throws), and a grenade rolling into a foe's feet stops.

| Weapon | Kind | What makes it different |
|---|---|---|
| PINEAPPLE GRENADE | grenade | the blast throws 6 shards |
| SKIPPING CHARGE | grenade | hops three times with a small blast at every hop, then a big one |
| POMEGRANATE | grenade | the blast scatters 6 seeds that pop on their own |
| HOARFROST GRENADE | grenade | freezes foes solid for 1.2 s, then chills them |
| GRANDMA'S FRUITCAKE | grenade | too heavy to bounce; a huge blast that leaves coins (now and then a heart) |
| BOTTLE ROCKETS | rocket | three wobbly rockets with small bangs; burn |
| BACKALLEY RPG | rocket | a big rocket; the backblast burns foes behind you |
| FESTIVAL LAUNCHER | rocket | flies through foes, then a star of 12 sparks |
| PATHFINDER ROCKET | rocket | steered by your aim; +100% damage for each second it flies |
| SWARM POD | missile | six missiles, each hunting a foe of its own |
| LOCK-ON LAUNCHER | missile | locks on to the toughest foe, then a missile that never misses; +50% to elites |
| STICKY JAR | sticky | sticks to foes and walls; rolling sets it off at once |
| LIMPET CHARGES | sticky | charges wait; every 4th throw is the click that sets them all off, each stronger for the others |
| POCKET MORTAR | mortar | lobbed over walls onto the foe you aim at (the shell follows it most of the way) |
| SNOWGLOBE MORTAR | mortar | leaves a snowstorm for 3 s; chilled foes take +30% |
| CLOCKWORK MICE | walker | two wind-up mice run to the nearest foe and blow |
| ROLLING KEG | walker | rolls straight, bounces off two walls, blows on the first foe |
| SIGNAL FLARE | strike | a line of five bombs falls along your aim; burn |
| SKY HAMMER | strike | paints the toughest foe; the sky hits it and stuns foes near it |
| DYNAMITE BUNDLE | dynamite | three sticks a throw; a blast sets off every stick near it, each 25% harder |
| REPULSOR | wave | a cone of force; foes hurled into a wall take +150% |
| SHRAPNEL SHOTGUN | shot | far-flying pellets that burst into 3 shards on walls |
| BLASTING KNUCKLES | slash | fast punches that plant a charge; it blows 0.6 s later |
| PARASITE LAUNCHER | flask | poison globs; 35% make the foe a puppet that walks into another and bursts |
| PIGGY BANK | shot | a spray of coins; every 30 gold picked up fills the pig, launched by the next shot |

## Part 2: CHARGE AND COMBO (charged and two-stage weapons)

Ten new attack kinds (`scripts/combat/charged.gd`). Three are **held to charge**: the charge
fills in 1/rate seconds while there is something to aim at (a ring round the hero shows it). With
AUTO-AIM FIRE (the default) it lets go at full by itself; while an aim button is held it waits at
full and fires the way you aimed when you let go.

- **charge**: a shot that grows: bigger, faster, harder (x0.4 to x3); a full charge pierces everything.
- **slam**: a shockwave ring rolls out along the floor; a full charge stuns.
- **dash**: you dash through foes, cutting each one; nothing touches you mid-dash.
- **javelin** (two stages): thrown, it pins a foe; the next attack dashes you to it, cutting all
  on the way, and tears it out (a second blow). A miss, or a foe more than 200 px away: it comes
  back by itself.
- **hook** (two stages): pulls a foe to you; the next attack is a punch that stuns and knocks it
  away (into a wall: a slam). Big foes and guardians pull you to them instead.
- **combo**: three different attacks in turn (the row's `steps`); a pause starts over.
- **heat**: fires fast and heats up (a bar over the hero); at full heat it vents a blast around
  you and cools for 1.3 s.
- **reload**: a magazine of shots, then a reload (pips and a bar over the hero).
- **orbit**: each attack adds a star circling you (it hurts what it touches); at the last one
  they all fly out and hunt.
- **recall**: a disc flies out and spins in place; the next attack calls it back through foes
  for double damage.

| Weapon | Kind | What makes it different |
|---|---|---|
| PLASMA SLUGGER | charge | the plain charge shot |
| SHATTERBALL | charge | bursts into 8 shards where it stops |
| GRAVITY GLOBE | charge | slow; drags foes to it as it flies, then collapses with a blast |
| SWIFTDRAW BOW | charge | draws slowly, but a roll draws it fully at once; a full draw crits and pierces |
| CHOKE SHOTGUN | charge | 7 pellets: the charge closes the spread from a wide fan to one slug |
| COLD STAR | charge | foes near you are chilled while you charge; a full charge freezes |
| QUAKE MAUL | slam | the plain slam |
| EMBERQUAKE MAUL | slam | leaves a ring of fire where the shockwave ends |
| AFTERSHOCK HAMMER | slam | two smaller aftershocks follow every slam |
| DASHBLADE | dash | the plain dash |
| COMET LANCE | dash | longer, and ends in a blast |
| PHANTOM EDGE | dash | 0.5 s later a phantom dashes the same way and cuts again |
| WAR JAVELIN | javelin | the plain javelin |
| THUNDER PIKE | javelin | pinned in a foe, it calls lightning on foes near it |
| GRAPPLE GAUNTLET | hook | the plain hook and punch |
| ANCHOR CHAIN | hook | the hooked foe is dragged through the others, hitting each one |
| CUTLASS AND FLINTLOCK | combo | cut, cut, then a pistol shot that always crits a foe the cuts hit |
| CHAIN GLAIVE | combo | sweep, thrust, spin: each only if the one before it hit (Aion's chain skills) |
| FLAREFIST | combo | jab, jab, a burning uppercut that stuns and slams the foe down |
| STEAM REPEATER | heat | the plain heat gun |
| REACTOR RIFLE | heat | the hotter, the harder (up to +100%); its vent is a huge blast |
| DEADEYE REVOLVER | reload | six shots, the sixth crits; a kill reloads at once |
| MAGDUMP CARBINE | reload | twelve shots; the empty magazine is thrown and blows |
| STARCALLER | orbit | stars circle you; at six they all hunt |
| SNAPBACK DISC | recall | out, spin, called back for double |

In a room with only training dummies (the start room) no weapon moves the hero: a dash cuts
along its line without moving, the javelin comes back, a hooked dummy is not pulled. (Found by a
soak: the javelin kept dashing the bot back to a dummy, so he never left the first room.) A dash
also leaves the hero safe for 0.35 s after it ends.

+1 projectile: a charged shot, a slam, a dash, a javelin, a punch, a combo step and the disc
are one thing each, and every projectile past the first adds 35% damage (a ball, a ring and the
disc also grow, up to twice as big). The choke adds pellets up to 14 and the star gatherer stars
up to 12, then they merge. Heat and magazine guns fire through the usual shot path. Shots in
flight never pass 24, rings 12, stars 12.

## Part 3: DECK AND DEN (cards, summons and companions)

Seven new attack kinds (`scripts/combat/summons.gd`), and a taming whip:

- **deck** (Slay the Spire's idea): a deck of cards, one played an attack. The next three show
  over the hero's head; when the pile runs out the played cards are shuffled back in (a short
  pause). Cards fly to the foe you aim at. Entering a room shuffles the whole deck anew.
- **turret**: each attack builds a turret (or a trap) by you; two at a time, the oldest goes.
- **thrall**: fighters on your side, who cannot be hurt.
- **command**: your pet's spirit (or a sheep) sent at the foe you aim at.
- **mirror**: images of you that fire when you fire, or a shadow that repeats your cuts.
- **swarm**: a bat cloud or fireflies sent at the foe you aim at.
- **egg**: hits warm the egg; at 15 a baby dragon hatches for the room (the next room: an egg
  again, half warm).

| Weapon | Kind | What makes it different |
|---|---|---|
| DUELIST'S DECK | deck | strikes, a bash (vulnerable), a cleave all round, a flurry of four hits |
| POISONER'S PACK | deck | toxin, a noxious cloud, and catalyst: the poison on every foe near its target doubled |
| SHIV DECK | deck | shivs and blade dances, then the finisher: harder for every card since the shuffle |
| COUNTDOWN DECK | deck | the bomb card: a bomb that blows when three more cards have been played |
| ECHO DECK | deck | double tap: the next card is played twice |
| ASCENDING DECK | deck | every shuffle upgrades one card (+50%) until you leave the room |
| SENTRY KIT | turret | gun turrets |
| FLAME SENTRY | turret | turrets that spray fire close by |
| TESLA PAIR | turret | coils that zap; two coils are joined by a beam that burns foes crossing it |
| FROST BEACON | turret | beacons that pulse cold |
| SAW TRAP | turret | thrown by the foe you aim at: cuts and slows what walks over it |
| MENDING TOTEM | turret | zaps foes; standing by it heals half a heart every 12 s |
| GRAVECALLER STAFF | thrall | foes you kill rise as bone thralls (12 s, four at most) |
| CLAY GOLEM | thrall | each attack adds clay: the golem grows five times, then its punches shake the floor |
| IMP LANTERN | thrall | imps that flit around you throwing fireballs (three at most) |
| WOLF HORN | thrall | three spirit wolves run at the foe you aim at; their bites bleed |
| MIMIC CHEST | thrall | a chest that follows you and hops onto foes to chomp; its kills drop a coin |
| PET WHISTLE | command | your pet's spirit leaps and bites, harder for each pet level (no pet: a spirit pup) |
| SHEPHERD'S CROOK | command | lobs a sheep that baas, then blows (with a pet: its spirit, a bigger blast) |
| LOOKING GLASS | mirror | each attack leaves a mirror image (two at a time) that fires when you fire |
| DOPPELGANGER BLADE | mirror | your shadow follows a second behind and repeats every cut from where it is |
| BAT CLOUD | swarm | each attack adds bats to a cloud that flies at the foe and bites all in it |
| FIREFLY JAR | swarm | fireflies circle the foe and burn it; three on one foe flare up in a blast |
| DRAGON EGG | egg | 15 hits hatch a baby dragon that breathes fire for the room |
| TAMER'S WHIP | whip | 25% of hits tame an ordinary foe: for 8 s it fights for you (and is not aimed at) |

+1 projectile: cards, turrets, thralls, the pet's leap, the bats and the dragon hit 35% harder
for each projectile past the first; a blade dance throws up to 8 shivs and a horn calls up to 6
wolves, then they merge. A mirror image fires at most three shots, the rest merged into them.

## Part 4: GUNPLAY AND ODDITIES (strange guns and tricks)

Seventeen new attack kinds (`scripts/combat/oddities.gd`), one thing an attack each:

| Weapon | Kind | What makes it different |
|---|---|---|
| TYPEWRITER | letters | every shot is a letter of BOOM; the last one's hit goes boom (the word shows over the hero) |
| PROPHET'S QUILL | letters | spells a random word: ZAP, ICE, BURN, GOLD or DOOM, cast by the last letter's hit |
| BUBBLE BLASTER | bubble | a bubble traps the first foe it meets; the next bubble on it pops it for triple damage (too big to trap: it bursts) |
| SOAP CANNON | bubble | big bubbles trap up to three foes together; pop one and they all pop |
| FLAK PISTOL | flak | shots pop the enemy shots they touch, three each, and go on through a foe (an idea from Cabal) |
| INTERCEPTOR | flak | for every 15 enemy shots popped, a ring of 12 shots |
| INK GUN | paint | ink on the floor: foes in it are slowed and take more damage |
| TRICOLOR SPLATTER | paint | red burns foes, blue chills them; in yellow you move and fire faster |
| SLOT PISTOL | slots | three reels a shot (over the hero): pairs and three of a kind pay out, sevens a jackpot |
| GILDED SLOTS | slots | stakes a coin a spin while you have one; every payout three times bigger |
| SNOW ROLLER | roller | a snowball that rolls, grows and chills, then bursts |
| MOSS BOULDER | roller | rolls and grows; at rest it stands as cover for 5 s, stopping enemy shots |
| PAYDAY CANNON | money | a coin a shot for a gold slug, +1% for every coin you hold; broke, it fires lint |
| FLASH CAMERA | camera | a flash that stuns; a foe's third photo develops into a huge crit |
| GLACIER RAY | ray | a foe held in the ray 1.2 s freezes solid; dying frozen, it shatters into ice |
| JUNK CANNON | junk | in turn: a boot (knocks back), a can (bounces), a bottle (shatters), a tire (rolls through) |
| FISH CANNON | junk | fish flop on the floor; a foe that steps on one slips and falls |
| HOME RUN BAT | bat | foes knocked flying hit the ones they meet (billiards) and slam into walls |
| CROQUET MALLET | bat | the nearest foe rolls along your aim, off two walls, through all in its way |
| BACKSTAB DIRK | stab | a stab in the back of a foe facing away always crits, twice as hard |
| CALLING CARD | duel | the first hit on each foe is four times the damage, always a crit |
| SHRINK RAY | shrink | shrunk foes deal no touch damage and take more; walk onto one to squash it (too big to shrink: 2.5x damage) |
| LEAF BLOWER | blower | turns enemy shots around (now yours) and pushes foes back |
| AEGIS PROJECTOR | dome | a dome that pops enemy shots and burns foes in it; each attack lances the nearest foe |
| COIN FLIPPER | coin | every 3rd shot tosses a coin; a shot that hits it splits into two seeking crits |

+1 projectile: every kind here makes one thing an attack, and each projectile past the first adds
35% damage to it (a ball also grows); slots and the coin flipper fire through the usual shot path.

## Code

`scripts/combat/oddities.gd` (class `Oddities`): `fire`, `tick`, `draw_floor`, `draw_over`,
`on_kill` (shattering). New on the foe: `Enemy.shrink_t` (drawn at 0.55 size, no touch damage).
Sprite `s_fish`. The weapon test found the aegis dome harmless to foes that keep their
distance, so each attack also lances the nearest foe. Every shot of the new kinds that starts a
few pixels out (part 4's, part 2's charged balls and javelin, part 1's rockets) checks the whole
path it flew each tick, from the hero on (`Arsenal.swept`): a soak found crawlers pressed against
the hero that no such shot could touch.

`scripts/combat/summons.gd` (class `Summons`): `fire` (from `Combat.player_shoot`), `tick` (from
`Hazards.update`), `draw_floor` and `draw_over` (world_view), `on_kill` (bone thralls), the
actions `charm` and `warm` (`actions.gd`), and `charm_tick` (from `Combat.update_enemies` for a
tamed foe, which also does not hurt you by touch and is skipped by `Combat.auto_target`; drawn
pink). Sprites: `s_bones`, `s_golem`, `s_imp`, `s_wolf`, `s_mimic`, `s_sheep`, `s_dragon`,
`s_egg`; mirror images and the shadow are the hero's own sprite, tinted.

`scripts/combat/charged.gd` (class `Charged`): `hold` (the charge, from
`Combat._update_player_base` in place of the usual cooldown for the held kinds), `fire` (from
`Combat.player_shoot`), `tick` (from `Hazards.update`), `draw_floor` and `draw_over` (world_view),
`on_kill` (the deadeye) and `on_roll` (the swiftdraw). Dashes use the hero's own dash
(`Player.dash_t`); `Abilities.while_dashing` leaves the cutting to `Charged` when a dash has no
trample damage. The magdump's magazine is thrown with `Arsenal.toss` (sprite `magazine.png`).

`scripts/combat/arsenal.gd` (class `Arsenal`): firing (`fire`), the thrown things (`live`, own
physics, emptied when the room changes), warnings and charges (`marks`), blasts (`blast`, through
`Combat.damage_enemy` and `on_hit_effects`, so crits, ailments and every on-hit effect work), the
twists a row may carry (`TWISTS`), the old-kind tricks (`wall_shards`, `plant`, `puppet`, the pig)
and the drawing. Hooks, one line each: `Combat.player_shoot`, `update_enemies` (puppets),
`on_roll_start`, the shot wall branch, `Hazards.update` (`Arsenal.tick`), `G.enter_room`,
`world_view` (floor and over layers), `hud_view` (the pig). Actions `plant` and `puppet` in
`actions.gd`. Data: kinds in `Weapons.ARCH`, rows after "homingaxes". Icons `w_<id>.png` (12 x 12)
and `dynastick.png`. Tested by `tests/arsenal_test.tscn` (`--ids=a,b` runs only those weapons,
old ones too, for comparing).
