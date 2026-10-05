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
| POCKET MORTAR | mortar | lobbed over walls onto the foe you aim at |
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

## Code

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
