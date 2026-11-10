# Heaven and Hell (ROADMAP 4.7 part C)

His ask, 5 Oct: "make heaven and hell story part, final two bosses based on your perks like in
Tiny Rogues, that unlocks the final final final boss". Names, story and art are this game's own.
Expanded game only (the original game ends at the Pale Regent as before).

## The story

1. **The Umbral Sun falls** (floor 11). Beside LOOP and EXIT a third way opens: the **SOUL GATE**.
   Its sign says where your soul leans and why ("LIGHT 7, DARK 4").
2. **Your soul** (`scripts/game/soul.gd`): every tag on your weapon, gear, relics and traits
   counts (a trait once per rank). Light: bulwark, frost, arcane, edge, storm, swarm. Dark: blood,
   malice, shadow, fury, pyre, venom. Fortune and demolition weigh nothing. A tie is light.
3. **THE GILDED EMPYREAN** (light: "THE LIGHT HAS WEIGHED YOUR SOUL") or **THE SCORCHED DEEP**
   (dark: "THE DARK HAS CLAIMED YOUR SOUL"): a realm in its own tiles and foes, two fights, then
   its ruler.
   - **THE AUREATE JUDGE** (Heaven): halos (rings with one gap, turned to where you stand), the
     verdict (lanes that light up across you, then strike), beams, a spiral, a choir of wisps and
     knights, and a teleport.
   - **THE CINDER KING** (Hell): brimstone (burning rings that close in, each with one way out),
     the hellgate (lines of fire across the floor and a spiral), sweeps, embers, a charge, imps.
4. The ruler falls ("A BLANK PAGE OPENS WHERE IT STOOD"): its hoard, and a portal to **THE
   UNWRITTEN PAGE** ("WHERE THE WORLD WAS FIRST WRITTEN"). No door back.
5. **THE UNWRITTEN**, the last boss of all, half light and half ink, uses both realms' powers:
   ink from both walls (rows with a gap), halos, brimstone, the rewrite (the page is wiped clean,
   it reappears across the room and writes three rings), the eclipse, the verdict, the hellgate.
6. Its fall wins the run: "THE PAGE IS YOURS", "<HERO> UNMADE THE UNWRITTEN, BY WAY OF HEAVEN (or
   HELL)". Embers: +100 for the realm, +200 for the Unwritten. Counted in the save
   (`heaven_wins`, `hell_wins`, `unwritten_wins`).

Health: the Judge and the King 2500, the Unwritten 3300 (x dread, loops and the expanded game's
toughness, like every guardian). Each has a harder second half like the other guardians.

## Code

Realms are rift-world themes (`Themes.REALMS`, never offered as rifts): step 0 and 1 fights, then
step 3, the ruler's room. `game.gd`: the gate in the true ending, `_enter_realm`, `_realm_won`,
no exits in a ruler's room. Bosses: `GameData.BOSSES` and `BossAI` plans; six new attacks in
`boss_ai.gd`. Art: `judge`, `cinderking`, `unwritten`, `kit_heaven`, `kit_hell`, `kit_seam`.

## Tests

`tests/realms_test.tscn` (in `tools/check.sh`): light gear leans to Heaven, dark to Hell; the
whole way for both realms (gate, two fights of the realm's foes, the ruler, no door back, the
page, the Unwritten, the win with its embers); each boss fights 40 s and uses every attack of its
plan. Planted faults caught: a soul always light, no page portal, an attack missing. Soaks: 8
runs of 10 minutes in the realms and on the page, 0 errors. Not tested on the iPad.
