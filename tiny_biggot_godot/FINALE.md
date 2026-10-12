# THE LAST LAUGH: the final final boss (Stage 55)

His word, 11 Oct: "after final boss there is next final final boss that chooses form of most
gathered alignment", with three forms each. Expanded game only; `--classic` ends a won run at once,
as it always did. Code: `scripts/entities/finale.gd` (class `Finale`).

## When it comes

Every time a run would be won (`G.on_win`): the Critic falls, the book is closed after the
Unwritten, the Author, the Redactor or the Reader, or you walk out through the exit portal after the
Eclipse. Instead of the win, something laughs: a banner (WAIT. SOMETHING IS LAUGHING / THE FINAL FINAL
BOSS: YOU WERE MOSTLY GOOD), laughter over the room, and after 2.6 s you are healed in full and taken
to its arena (a realm room, step 3). A second win request while it is coming (walking into the exit
portal again) waits too. Endless descents have no endings, so no final final boss.

- **The pick** (`Finale.pick`): the alignment you gathered most (Player.al_good, al_evil, al_law,
  al_chaos); a tie is settled by a coin among the tied.
- **Its health** keeps pace with how deep the run went: 3600 (like every boss, times the floor,
  dread, loop and run scaling), and +15% for each chapter past the first.
- **Beaten**: two boss chests, the senator's taxes paid back in coins, the banner (... IS BEATEN /
  THE LAST LAUGH IS YOURS), and the run is won: THE LAST LAUGH, +400 embers; the end screen says
  "<HERO> HAD THE LAST LAUGH OVER <BOSS>"; the run log "WON: THE LAST LAUGH"; Meta `finale_wins` and
  `<boss>_wins`. A trophy, like every guardian.
- **Fall to it**: the run is still won (the book was already kept), and the end screen says
  "<BOSS> HAD THE LAST LAUGH. THE WIN STILL COUNTS". No LAST LAUGH embers.
- A run saved at a floor's start (RunSave) and continued replays that floor, its ending and then the
  final final boss.

## The four (our own characters and names)

Each has three forms: BossAI stages at two thirds and one third of its health, each with its own
picture (`<sprite>`, `_s2`, `_s3`), its name on the boss bar (`Finale.FORMS`), a line, and its
own plan (BossAI.BOSS_PLANS, STAGE_PLANS). Its own moves are in `Finale.move` (BossAI sends any move
it does not know there); shared moves (laserx, hooks, wall, flower, barrage, halo, zone, verdict,
brimstone, hellgate, lasers) are BossAI's. Stage 3 is the usual chaos (almost no rest, a pulse).

**GOOD: SIR BRAYSALOT**, a dim but noble donkey knight, a carrot for a lance (THE NOBLE PASTURE).
SUPER BRAYSALOT (gold, a mane like a flame), then ULTRA HOLY BRAYSALOT (wings and a halo).
- HEE-HAW: rings of shots that spread, each with one gap near you.
- The lance: a lane lights up from him through you, then he runs it, carrots flying off his
  sides; 2 runs (3 from SUPER).
- Carrots from the sky: shadows on the floor (one under you), then carrots that burst.
- The buck kick: he turns round and kicks three fans at you.
- He trips over his own lance: on his back for 2.2 s, taking +50% damage (stars round his head),
  then "I MEANT TO DO THAT." and a ring. Not in his ULTRA form.
- PONY SQUIRES (runners) as his followers.

**LAWFUL: SENATOR SCALESWORTH**, a big fat politician who is certainly not a lizard (THE GRAND
CHAMBER). THE MASK SLIPS (half his face scales and a yellow eye, the tongue), then COLD-BLOODED (a
fat lizard in what is left of his tie).
- The filibuster: a spiral of words (BLAH BLAH, IN CONCLUSION...).
- VETO: stamps come down where you stand (3, or 5 when it gets hard), each VETOED! and a ring.
- NEW TAX: up to 10% of your gold (60 at most) flies to him, and he throws coins back at you;
  he pays it all back, and more, when he falls.
- Red tape: lanes across the room light up red, then strike.
- From THE MASK SLIPS: the tongue (THWIP) down a line at you; it hits and pulls you in.
- LOBBYISTS (they lob paperwork) and INTERNS (fast, with coffee).

**CHAOTIC: PROPHET NIGH**, a raving prophet with a cardboard sign: THE END! (THE END OF THE
WORLD). PROVEN RIGHT (the sign on fire), then THE END (huge, afloat, burning, a stone tablet).
His sign always reads the right way round (he never turns).
- Sermons: REPENT! THE END IS NIGH! I TOLD YOU!, each a ring with one gap.
- Pamphlets: handfuls at you, and some everywhere.
- THE SKY IS FALLING: meteors at marked spots, two on you.
- The sign slam: he leaps onto where you stand (a ring shows where).
- THE END (his last form): the room goes dark, a countdown 3, 2, 1, then a great ring and meteors.
- TRUE BELIEVERS (charging bruisers) flex at you when you come close: FLEX!, and you are MOGGED:
  1.1 s at 40% of your speed (a roll still works), at most once every 2.4 s.
  (His first idea for this boss was built on a real people; we do not make that. This one mocks
  doomsayers in general, nobody real. "Doomsayer" itself is a card in another game, hence NIGH.)

**EVIL: BARON VON CHONK**, a fat cat overlord with a crown and a monocle (THE CAT'S PARLOUR). THE
ZOOMIES (fur on end, eyes like saucers), then NINE LIVES (a huge tuxedo cat, a cape, ghost tails,
eyes of red light).
- He knocks things off a table: a little table appears, with vases, mugs, a fishbowl and plant
  pots; one by one, *KNOCK*, they fly at you and shatter where they land (CRASH!, a ring).
- Hairballs: HACK! HACK!, a big hairball that bursts.
- The pounce: he leaps onto where you stand.
- A cat nap (his first form): Z, +50% damage taken, and two kittens to guard him.
- THE ZOOMIES: he tears round the room in straight lines, bouncing off the walls, leaving fur.
- NINE LIVES: laser eyes (lasers) and the laser dot: it follows you, settles, and a laser
  strikes there.
- Kittens (fast, small) as his followers.

## The pictures

`tools/art/stage55_finale.py` draws everything with shapes (ellipses, lines, polygons; outlines and
shading like Rex): the 12 boss pictures, the 5 followers and their elites, the believer's flex, the
thrown things (fp_vase, fp_mug, fp_bowl, fp_pot, fp_carrot, fp_meteor, fp_stamp, fp_table) and the
four arenas' tiles (kit_pasture, kit_senate, kit_endtimes, kit_parlour: the game's kit0 recoloured
by brightness onto each arena's own colours). All within 96 px, all in the atlas.

## Where it is wired in

- `G.on_win` asks `Finale.intercept()` first; `G.on_death` asks `Finale.keeps_win()`;
  `G._realm_won` sends a finale arena's boss to `Finale.won`; the boss room's banner and
  `Finale.spawned` (its health); `award_embers` (THE LAST LAUGH).
- `BossAI`: plans, lines, summons, ring shots; `_stage_break` calls `Finale.transform`; any move it
  does not know goes to `Finale.move` (finale bosses only).
- `EnemyAI2.adjust_damage` rule "finale" (the trip and the nap); `Player.update_move` x
  `Finale.speed_mult` (MOGGED); `Hazards.update` -> `Finale.tick`; world_view draws
  `Finale.draw_ground` / `draw_over`, the tilt of a tripped donkey or a napping cat, a believer's
  flex; the HUD's boss bar shows the form's name.
- Data: GameData.BOSSES (rule "finale"), ENEMIES (ponysquire, lobbyist, intern, believer, kitten),
  SPRITE_COLOR, ENEMY_XP; Themes.REALMS (f_pasture, f_senate, f_endtimes, f_parlour, "finale":
  the alignment); Ambience.RIFT; Barks (opening lines, follower barks).
- Test switches: `--finale=good|evil|law|chaos` (straight into its arena), `--finale-form=2|3`
  (pictures), `--no-finale` (a won run ends at once). `Finale.off` does the same for tests of the
  endings before it (realms_test).

## Tests

`tests/stage55_test` (in check.sh): the data of all four; the pick and a tie; a won run for each
alignment: the laugh, its arena, healed, its boss, its three forms and their names, its fall, its
chests, the win with THE LAST LAUGH's embers; a fall to it still wins; every move of every form plays
out and ends; MOGGED; a tripped donkey takes +50%; `--classic` wins at once. `realms_test` plays
every stage of every boss (the four too). The bestiary, trophies, bosses, chaos, foes and ambience
tests take them in as they do every guardian.
