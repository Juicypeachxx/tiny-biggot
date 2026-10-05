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

## Code

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
