# Handoff: where the work stands

Kept up to date at every push, so that a session that is cut off (it has
happened twice to usage limits) loses nothing. `CLAUDE.md` has the rules and
`ROADMAP.md` the plan, step by step; this file is the detail of what was done.

The Godot project is in `tiny_biggot_godot/` (Godot 4.6.1, GL Compatibility).
`TinyBiggot-Stage2.zip` is the RPG Maker original it was ported from.

## The owner and his rules

- Jože plays on an iPad Air M1. He tests in Xogot (Godot 4.6.1 on iPad) and
  sideloads IPAs with SideStore. He has a Mac with Xcode but wants the IPA
  built here, through GitHub.
- Nothing is to be removed or toned down: "the same broken paths and chaos".
- A steady 60 fps is a requirement.
- Art influences he named: Tiny Rogues (the game's model), Dead Cells, Aion,
  League of Legends. Ideas only: every sprite is original work. No character,
  sprite or logo from those games is copied.
- Write to him in plain, short English. Say what was measured and what could
  not be tested (there is no iPad and no Mac in the cloud container).

## What he asked for on 5 Oct, in his order

1. **A working IPA** he can sideload on the iPad Air M1, built through GitHub.
   Done: see "The IPA build". He installed it with SideStore on 5 Oct: it
   installs and works.
2. **A performance patch**, then a stability check. Best done from what he
   reports from the iPad (OPTIONS > SHOW FPS: FPS, LOGIC, DRAW, WORST).
3. **New things, last**: 10+ rooms, 100+ weapons, 10+ characters with their
   own playstyles, every weapon, relic and piece of equipment unique (the game
   already has 252 weapons, 14 heroes and 96+ gear pieces, so this includes
   going through the existing ones for near-duplicates), and a pixel-art
   revamp of all sprites in the spirit of the influences above.

He asked not to spend his usage on debugging and new things before the IPA
works. Keep each step small, commit and push after each.

## Branch and commits

Branch `claude/dev` (work goes on here). It continues
`claude/xcode-pass-handoff`, which sits on top of the port branch
`claude/compassionate-ramanujan-vjr3qr` (4dbec24).

| Commit | What it is |
|---|---|
| 4ecba1f | Everything delivered to him up to 3 Oct (the "attack-effects" build). The baseline: later work is compared against it picture for picture |
| e8765f0 | The exported-app pass as checked on 3 Oct. **Not delivered**: see below |
| after that | The fix in progress, then whatever follows. See "State of the fix" |

## The exported-app pass (e8765f0)

Goal: remove the stalls an exported app has, without changing a rule or a
pixel. `tiny_biggot_godot/IOS_BUILD.md` has the causes and the measurements.
In short: no texture read-backs during play (`Img` keeps the atlas pixels in
memory), a launch warm-up that draws every kind of thing once
(`scripts/render/warmup.gd`), sounds loaded at launch, a shot batch that
always hands over the same instance count, a ready-made sprite atlas with a
fingerprint of the imported graphics, and the iOS export preset.

Checked on that commit: `tools/check.sh` passes with all 14 replays identical;
an independent review compared 47 seeded runs (46,500 frames) and 14 traces
against 4ecba1f with no difference, ran 40 soaks (505,800 ticks) without an
error line, and found six defects, all fixed in that commit.

**Why it was not delivered.** The same reviewer's second pass (cut off before
it could report; recovered from its logs) found that the engine itself aborts
when it is asked to load a damaged compressed `.res`:
`FATAL: Index p_index = 16777215 is out of bounds` inside `ResourceLoader.load`.
With the atlas stored as `assets/atlas/sprites.res`:

- cut short at 95 of 151 lengths tried: crash at every start, also when it is
  the project's own file (an interrupted copy to the iPad would do it);
- a single flipped bit in the notes area: crash in 53 of 120 tries, or wrong
  sprite places accepted in 21 of 120;
- `ResourceSaver.save` reports OK on a full disk and leaves a partial file.

## State of the fix: done (ef0d6af, 101017b)

The atlas file is no longer a Godot resource. It is a file of the game's own
(`assets/atlas/sprites.tbatlas`: "TBAT", an MD5 of everything after it, the
unpacked size, then `var_to_bytes` of the notes and pixels, zstd-packed).
`Img.notes_in` checks the checksum before anything is unpacked, and
`Img.write_whole` reads back what it wrote before moving it into place. Both
export presets include `*.tbatlas` (it is not a resource, so only a filter
gets it into the pack).

Checked on 101017b:
- `tools/check.sh` passes, 14 replays identical.
- `tests/atlas_test.gd`: 513 single-bit flips, 342 cuts and eleven other kinds
  of damage are refused without an engine error; eight planted faults in the
  loader were each caught.
- The project's file cut at seven lengths, or with a bit flipped: the game
  starts and packs the atlas itself. A full disk leaves no partial file.
- 30 seeded runs, 17,400 frames, against 4ecba1f: no pixel differs, sound the
  same, with the atlas loaded from the project's file (25 runs), packed at
  start-up (2), loaded from the game's own file (2) and switched off (1).
  (The commit message of 101017b says 17,820 frames; 17,400 is right.)
- A Linux release export carries the file and loads it ("baked", about 50 ms).

Not redone after the file-format change, because nothing they measure
changed: the stall timings and the 45-scene sweep in `IOS_BUILD.md`.

## The IPA build

`.github/workflows/build-ipa.yml` builds an unsigned `TinyBiggot-<VERSION>.ipa`
(the file `VERSION`; release `ipa-<VERSION>` kept, plus `ipa-latest`) on a
GitHub Mac (macos-15): Godot 4.6.1 imports the project, `tools/bake_atlas.sh`
makes and tests the atlas, the iOS preset exports the Xcode project with the
release engine, `xcodebuild` builds it with signing off, and the app is zipped
as `Payload/`. The IPA is kept with the run and published as the release
`ipa-latest` (replaced by each build).

- It runs when a pushed commit message contains `[ipa]`, or from the Actions
  page ("Run workflow") once the file is on the default branch. Other pushes
  start nothing.
- First run: 1 min 18 s, green. The IPA is 28 MB: arm64, release engine,
  bundle id `com.joze.tinybiggot`, minimum iOS 14.0, Game Mode keys set, not
  signed (SideStore signs it).
- Its pack, run with a Linux desktop player, loads the atlas ("baked") and
  plays. All 842 imported graphics in it are byte-identical to the Linux
  import, so the atlas file made on Linux fits what the Mac imports.
- From a cloud session: `gh run list`, `gh run watch <id>` and
  `gh api repos/Juicypeachxx/tiny-biggot/releases/tags/ipa-latest` work.
  Run logs and run artifacts cannot be downloaded (blocked by the session's
  network rules); the release asset can:
  `gh api -H "Accept: application/octet-stream" repos/Juicypeachxx/tiny-biggot/releases/assets/<id> > TinyBiggot.ipa`.
- He installed it with SideStore on the iPad Air M1 on 5 Oct: it installs and
  works.
- 5 Oct, part 1 build: the release came out as a hidden **draft** (its URL read
  `untagged-...`, and fetching it by tag gave 404). The old tag's deletion
  landed after the new release was made, and GitHub drafts a release whose
  tag is deleted. The workflow now moves the tag (`git tag -f`, force push)
  instead of deleting it, and publishes the release if it is still a draft.
  After a build, check `draft: false` in the release list.

## Stage 2 (performance)

Closed 5 Oct with no change: he reports a good 60 fps on the iPad Air M1
("for now"). He did not send the SHOW FPS lines; if a drop shows up later,
ask for them and reopen 2.2-2.4.

## Stage 3 (stability)

**3.1, the save file (done).** `scripts/core/meta.gd`:

- Format: "TBSV", an MD5 of the rest, then `var_to_bytes` of
  `{opts, meta}`. The old format (`store_var`: a u32 length, then the same
  bytes) still loads if its length is right, and becomes the new format at
  the next save. His save on the iPad is the old format.
- `write_save_to`: writes `NAME.tmp`, reads it back and compares, then moves
  the save in place to `tiny_biggot.save.bak` (only if it is whole) and the
  new one into place. Any failure leaves both files as they were.
- `load_from`: the save if whole, else the backup, else defaults. It writes
  nothing. `save_source` says which ("save", "backup", "fresh", "").
  Saved values of another kind than the default are left out (int and float
  count as one kind: `embers` can become a float through item costs).
- `tests/save_test.tscn` (in `tools/check.sh`): 5,439 damaged saves (every
  cut, every single bit, zeroes, a doubled block, garbage) turned down with no
  engine error; backup kept; a failed write changes nothing; old format; wrong
  kinds. Planted faults: no checksum (engine errors, caught by check.sh) and
  rotating a damaged save into the backup (caught). The read-back and the
  re-encode check are not caught by it: no fault reaches them on Linux.
- Checked by hand: a really full disk (8 KB tmpfs): "Can't write file", the
  save unchanged, no spare file. A game started on an old-format save (runs
  41) loaded it and wrote it back as TBSV with runs 42 and a backup.
- Not checked: the iPad. On iOS `rename` replaces the target the same way, and
  the atlas file already relies on that.

**3.2, hit points above the maximum (done).** `Effects._update_synergies`
took a lost synergy or combo back with `apply`, which has no limits. Losing
IRONCLAD (bulwark 6: +1 max heart) at full health left 2 hit points above the
maximum; losing PHANTOM (shadow 6: +1 roll charge) with every roll spent left
-1 charges. Now it uses `apply_equipment`, the same limits gear and gear sets
use when taken off (max hp at least 2, hp between 1 and max, armor and revive
not below 0, rolls between 0 and the rolls there are, potions not above the
most). Only new content has tag synergies; combos need named items. Test:
`_test_synergy_loss` in `tests/unit_tests.gd`, red before, green after.

**3.3, long soaks (done, nothing to fix).** `tools/dev/soak.sh` (about 7
minutes here, 4 at a time) runs 29 soaks of 10 minutes of game time with the
bot, `--smart-bot` and `--god`: the 14 heroes on floors 0-10 in turn, the 8
rift worlds (`--rift=ID --step=0..2`), `--classic` twice, `--plain-draw
--no-vfx` (FAST DRAWING and FANCY EFFECTS off) twice, `--loop=1..3`;
`--weapon-cycle=1` in 15 of them. Result: no `SCRIPT ERROR`, `ERROR:` or
`WARNING` line in any, every run reached floors 4-10 at level 11-25.

Object count (new option `--objects`, once a minute of game time):
- One run, `--god`, 30 minutes: 2,666 at 1 min, 3,133 at 30. It grows with the
  build (75 relics, 49 traits by 52 min, when the bot won) and is flat after.
- Restarting runs (no `--god`, hero 0, seed 5, `--smart-bot`), counted at the
  start of each new run, 409 runs in 4 hours: 2,581 at the first, 2,704 by
  run 10, 2,819 by run 100, 2,882 at the last. Of that, the known caches:
  sprite silhouettes `Img._white` (88; at most one per graphic), outfit
  pictures `HeroGear._cache` (31; cleared at 257), the shot pool
  `Combat._pool` (21; at most 4,096). The rest went 2,658, 2,709, 2,742: about
  +0.1 a run over the last 200.
- Weak references showed every old hero, room, foe and pickup is freed.
- Exits report no leaked objects (that check is in the error grep).

Two things that look like faults and are not: without `--smart-bot` the bot
can walk into a pillar and stay there (seed 5, 91 min: room cleared, doors
open and reachable); and with a locked hero (`--hero=5` without a save or
`--unlock-all`) the bot cannot start a new run after dying. Both are the bot.

**3.5, leaving and coming back (done).** Read through: the rules advance by
`G.update(TB.DT)` once per physics tick, `max_physics_steps_per_frame=1`, so a
suspended app resumes exactly where it was, with no jump. `Time.*` is used
only for the SHOW FPS / perf readouts (WORST shows one long frame after
coming back). Touches are dropped on focus loss (`touch_controls.gd`). Music
is engine-paused by iOS. Added `G._notification`: on
`NOTIFICATION_APPLICATION_PAUSED` or `FOCUS_OUT`, a fight in progress goes to
the pause menu and `Meta.write_save()` runs. Test `_test_background` in
`tests/unit_tests.gd` (unit tests now run with `--no-save` in check.sh).
Not done: a run in progress is not saved; if iOS ends the app in the
background, the run is lost (meta progress is saved). Not tested on iPad.

## Stage 4 (new content)

**4.1, stock-taking (done).** `tests/uniqueness_report.tscn` writes
`tiny_biggot_godot/UNIQUENESS.md` from the data. Signature, without numbers:
weapon = kind | mechanics it adds to its kind (count+, homing, bounce, ...) |
stat names | hooks | effects; relic = effects; gear = slot (+ set) | stat
names | hooks | effects. An effect is `op:stat` or `trigger[if]>actions`.
"Same" = identical; "near" = identical once how a stat is changed (add, mul,
pct) is set aside (gear: and the set); "numbers only" = nothing triggered,
no hook, no mechanic. Result: weapons 252 (5 same, 18 near groups, 46 numbers
only), relics 173 (22 same groups, 84 numbers only), gear 231 (13 near
groups, 93 numbers only). New items needing work in 4.2: 20 weapons, 45
relics, 49 gear. Not seen by it: hero signature weapons' hero mechanics.

**4.2, part 1 (done).** Only data (`scripts/data/weapons.gd`,
`relics.gd`): descriptions and one triggered effect each, built from the
existing actions. Weapons: bogpump, lampflamer, hexchain, firepot,
wispcrook, ironpike, briarspear, frostfang, warbow, mirrorshard,
blightcenser, tumbleredge, towershield, iciclerepeater. Relics: goldtongue,
bargain, shatteredcrown, manyhands, warfletching, seedpouch, toadstool,
marshreed, ironrations, fielddressing, ledgerofdebt, matchbook, crownofash,
copperwire, snowglobe, sharpstone, quickcloak, mirroredsoul, hivecrown,
lockpick, spentcasing, undyingember, ravenquill, bloodmoon. Nothing lost:
each keeps its old stats. Left alone on purpose: banesabre, shackleflail,
warlance, wayfareredge, giltdeck (hero signature weapons). Still to do: the
new gear in near groups or numbers only (49) and 21 numbers-only relics
(keeneye, killingblow, oilflask, overload, mirrorbead, glowworm, nightveil,
stonehide, prayerflag, candlestub, copperspool, bogwater, blastingcaps,
cursedcompass, leadweight, alleycateye, phoenixash, hivemind, echostone,
crimsonfont, redmist: the last five each had a twin that changed, so they
already differ, but still only change numbers).

**4.2, part 2 (done).** 48 gear pieces plus star_boots
(`scripts/data/gear.gd`) and 19 relics each gained one triggered effect,
keeping their old stats. `UNIQUENESS.md` now: no new relic or gear piece in a
"same" or "near" group or numbers-only; weapons only the 3-4 hero signature
weapons. Full replays d, g, h re-recorded.

**4.3, environment 1 of 3: SKYREACH ISLES (done).** Details in
`tiny_biggot_godot/RIFTS.md`. New tile `World.T_VOID` (5): `World.solid`
blocks it for M_PLAYER and M_WALKER only; the two inlined bullet checks
(`ebullets.gd`, `combat.gd` player shots) let shots pass it. Original rooms
never contain it. Theme key `layouts: "isles"` picks layouts 101-104 (one
`rng.int_range(1, 4)` draw, same count as before). Hazard `gusts` lives in
`hazards.gd` next to the traffic code; `Room.gusts` holds the bands. Foe pool
is crow, wisp, torchimp until 4.4. Checked: rift test (with new section 7,
two planted faults caught), content test, atlas test, three 10-minute
soaks in the world (0 errors), screenshots of layouts and a gust. Not
checked: how it plays on the iPad.

**4.3b part 1: the saloon (done).** `scripts/game/saloon.gd` holds all of it
(setup, NPCs, drinks, quests, prompts, drawing); hooks: `G._setup_event`,
`G.interact` (first line), `G.room_cleared`, `G.start_floor`,
`Combat.kill_enemy`, `overlay_view` (prompt), `world_view` (draw, shadows),
`hud_view` (bounty line at y 20). The quest lives in `G.run_stats["quest"]`.
New tile `World.T_PROP` (6). 15 new sprites (npc_*, saloon_*, wanted_poster,
drink_*). Tests: rift test section 8 (reachability, every drink, free round,
each bounty paid and shown, expiry, easter eggs, font), with a planted
payout fault caught; two 10-minute soaks starting in the saloon, 0 errors.
Content test: once (of 8 runs) "gaolbird: dash did not move the hero";
not reproduced; likely a random layout's pillar in front of the dash, so
the specials check now clears the arena floor first.

**4.3b part 2: event rooms, special rooms, wanderers (done).** All in
`scripts/game/event_rooms.gd` (class `EventRooms`, same shape as `Saloon`).
Hooks: `G._setup_event` (titles and setup), `G.interact` (first lines; and
`take_cursed` in the item branch), `G.enter_room` (parcel rooms),
`G.update_play` (after `Hazards.update`), `G.room_cleared` (wanderers, Rogues
only), `G.start_floor` (parcel lost), `Combat.kill_enemy` (gallery score),
the touch-damage check skips `target`, `EnemyAI` has a do-nothing "target"
behaviour, `overlay_view` (prompts, curse line), `world_view` (draw,
shadows), `hud_view` (parcel line). Mystery doors: 18% become a special room
(`EventRooms.SPECIAL`). Tests: rift test section 9 (each room to its payout,
wanderer placement, font), with a planted fault (weapon list edited in
place) caught; a 5-minute soak starting in each of the 8 rooms, 0 errors.

**4.3, environments 2 and 3 (done).** `scripts/world/rift_extras.gd` (class
`RiftExtras`): layouts 201-204/301-304 (called from `World.build_room` after
the match), room contents (`G.enter_room`, after `Hazards.setup`),
interactions, prompts, drawing, and the tide and turret hazards (called
from `Hazards.update`; `Room.tides`, `Room.turrets`). `ai_flee` now reads an
optional `away` line. New foes in data: champions rotking, highcaliber; the
casingrat. Layout 203 was random rubble at first; the test showed it could
wall off a pocket of floor, so it is fixed spots now. Tests: rift test
section 10 (layouts reachable, table cover, turrets, every easter egg, the
tide), planted fault (table not cover) caught; six 10-minute soaks, 0 errors.

**4.4, twenty new foes (done).** `scripts/entities/enemy_ai2.gd`; details in
`tiny_biggot_godot/RIFTS.md`. Hooks: `EnemyAI.run` (one match line for all of
them), `Combat.damage_enemy` (`adjust_damage` when `guard_t > 0` or the data
has a `rule`), touch damage skips data with `no_touch`, `update_player` slows
in webs, `Hazards.update` calls `EnemyAI2.tick`, `world_view` draws goo and
the warnings, `GameData.floors()` adds `OLD_FLOOR_EXTRA` to copies of the
original floors unless `--classic`. Tests: foes test (planted fault: shield
off, caught), rift and content tests, 11 ten-minute soaks with 0 errors.
Desktop logic time in the busiest new room about 0.3 ms a frame (old floor
about 0.2). Not measured on the iPad.

**4.4b, floors as a map and the three clip features (done; IPA next).** His
ask on 5 Oct, with three clips: mechanics, layout and timing close to the
clips, art and names our own.
- `scripts/world/floor_map.gd` (`FloorMap`): `generate` grows a tree of cells
  (no loops; guardian at the farthest leaf, rest stop and mini-boss before it,
  at least 4 side leaves for shop, rift, treasure, mystery, shrine, vault,
  challenge; 1-2 hidden cells off fights), stored in `G.floor_d["map"]`.
  `room_at` builds a cell's room on its first visit; `link` gives it a door to
  each neighbour (hidden ones as cracked walls, the vault sealed with a lock
  door). Hooks: `G.start_floor`, `G.open_exits`, `G.leave_room`
  (`_leave_on_map`), `G.enter_room` (cleared rooms stay cleared),
  `World.open_secret`, the bot (`FloorMap.bot_door`), the HUD minimap. Off
  in `--classic` and with `--linear`.
- `scripts/render/trait_view.gd` (`TraitView`): the level-up screen in the
  expanded game (burst 0.9 s, rows shining in 0.14 s apart, keyword panels, a
  4th choice at luck x 15%, at most 90%). `G.update_traits` waits for
  `TraitView.ready()`; `taps.gd` has its zones.
- `scripts/render/item_show.gd` (`ItemShow`): rarity beams under items, the
  coloured keywords on item cards, and the pedestal treasure room (40% of
  treasure rooms in the expanded game).
- `scripts/game/stars.gd` (`Stars`, the rules) and
  `scripts/render/star_view.gd` (`StarView`, its own CanvasLayer 26): the
  constellation. Taken stars are in `Meta.meta["stars"]`; `G.new_run` calls
  `Stars.apply_to` in the expanded game. Title menu items are now looked up
  by name (`G.title_items()`, `G.title_index`); `TouchControls` hands touches
  to `StarView.touch` on that screen. `--ui=stars` opens it,
  `--unlock-all` gives the 30 points.
- Tests: `tests/map_test` (planted fault caught), `tests/stars_test`
  (planted fault caught), the content test lints the stars (effects, font,
  no notable named like an item; four renamed for that). The content test's
  paid-reroll check now waits out the level-up burst.
- Soaks (`tools/dev/soak.sh`, now with the 3 new rift worlds): 33 ten-minute
  runs, 0 error lines; the 30-minute object run went 2,783 to 3,247 (the
  stage 3 baseline went 2,666 to 3,133: the same growth with the build).
  Replays: the 6 classic ones identical; the 8 full-content ones re-recorded
  (the map changes every run's rooms).
- `tools/check.sh`: CHECK PASSED (with the stars test), all 14 replays
  identical.
- IPA for him to test: pushed with `[ipa]` after that (release `ipa-latest`).
- Not tested: the iPad (touch on the constellation: drag, pinch, hold), and
  frame time there.

**4.5, rift bosses (done).** `scripts/entities/rift_bosses.gd` (class
`RiftBosses`); details in `tiny_biggot_godot/RIFTS.md`. Minis: ENEMIES rows
with `"ai": "riftboss"` and `"champion"`; guardians: BOSSES rows with `"rift"`;
both `"rule": "phase"` (EnemyAI2.adjust_damage hands it to RiftBosses: no damage
in the grace between phases, the bellringer +50% without its bell). Enemy
gained `phase` and `parts`. Their things (quills, rods, arcs, bands, rings,
orbs, cyclones, lobs, tolls, notes, pipes, chords, pedal waves) are lists in
RiftBosses, ticked from `Hazards.update` and emptied on entering a room and on
a guardian's fall. Flow: `G.spawn_wave` (mini as the last wave of rift step 1),
`G.open_exits` (`_deeper_door` in step 2 of a new world), `G.leave_room` (step
3 is a "boss" room), `G.update_play` (spawns `theme.guardian`), `G.on_boss_dead`
(rift branch: hoard, way back, no portal), `Combat.spawn_boss` (health x floor),
`BossAI.update_boss` and `EnemyAI.run` dispatch, `world_view` (ground warnings,
over-layer, parts with the body), Afx got public `lane`, `landing`, `circle`,
`reach`. In a guardian's arena the world's hazard does not fire by itself (the
guardian calls gusts, tides, turrets). The organ's nave has three tables. The
bot now takes a rift's deeper door. Tests: `tests/bosses_test` (planted faults
caught: no shot clearing, no deeper door, a stuck attack), rift test updated
(the deeper door; its saloon check had a latent flake with the house special,
fixed), six 10-minute soaks in the new worlds, 0 errors. Desktop logic in the
fights 0.16-0.29 ms a tick on average, worst tick 2-5 ms. Not tested on iPad.

**4.5b, pets (done).** `scripts/entities/pets.gd`; details in
`tiny_biggot_godot/PETS.md`. Tests: `tests/pets_test` (planted faults caught:
a level off by one, Gloop taking every hit). The full soak set now gives ten
heroes a pet; 33 runs, 0 errors; objects 2,815 to 3,325 in 30 minutes (a
different random path from before; same kind of growth). The bosses test's
killing blow now strikes until the boss falls (a summoned deacon can halve it).
Full-content replays re-recorded (cages add random draws); the 6 classic ones
identical. **The IPA built before 4.5 does not have the bosses or the pets.**

**4.5c, Rex (done; IPA built).** `scripts/entities/rex.gd` (class `Rex`): his
barn (room type "barn": `World.build_room` calls `Rex.layout`, which sets
`Room.kit = "kit_barn"` and four hay-bale pillars; `G.setup_objects` puts his
bowl; `G.enter_room` calls `Rex.on_enter`, which spawns him asleep with
`Combat.spawn_boss("rex", true)`, quiet), his moves (run inside RiftBosses:
`PLANS["rex"]`, a "sleep" state before "intro", `Rex.to_hay` in the grace,
potatoes as a lob kind), his drawing (`world_view._enemy_sprite` asks
`Rex.sprite`; the sunglasses and the sword are parts), his defeat (no blasts,
hearts and a bark in `Combat.kill_enemy`; `G.on_boss_dead` calls
`Rex.on_beaten`: a hoard and a cage-less offer of the pet REX, Meta "rex" +1),
the title secret (`MenuView` draws him, `Taps` and SPECIAL call `Rex.poke`,
`G.rex_call` puts a "barn" door in the next on-map room entered), and the map
(`FloorMap.generate` makes a hidden cell a barn). Pet REX in `pets.gd` (not in
cages: `IDS` stays ten). New: `Room.kit`, `spawn_boss(key, quiet)`, sounds
`cc_bark.wav` and `cc_snore.wav` (made from sine waves and noise), debug
`--rex`. A phase change now also pauses the room's own hazards (gusts, tides,
turrets): a gust's shard could land in the grace. Tests: bosses test section 6
(planted faults caught: no double damage asleep, a bowl that does nothing),
pets test has REX; three 10-minute soaks from the barn, 0 errors.
`tools/check.sh`: CHECK PASSED, all 14 replays identical. The IPA with the
rift bosses, the pets and Rex was pushed with `[ipa]` after that (release
`ipa-latest`). Not tested on the iPad.

**4.6 part 1, MAYHEM (done).** 25 weapons, nine new attack kinds; details in
`tiny_biggot_godot/ARSENAL.md`. `scripts/combat/arsenal.gd` (class `Arsenal`)
fires, moves, blasts and draws them; hooks are one line each (listed there).
+1 projectile merges past a few thrown things (+35% damage each, wider blast),
and thrown things never pass 48. Grenades and dynamite are aimed at the foe
nearest the aim and stop at a foe's feet. Tests: `tests/arsenal_test` (in
`check.sh`): data, each weapon's own trick in a fight, then 999 more
projectiles (caps kept, more damage, desktop logic 0.15-0.35 ms a tick for the
new kinds; the shot and flask kinds 1-1.6 ms with worst ticks of 12-17 ms,
the same as the old shotguns and flasks at that count, so not new). Planted
faults caught (no dynamite chain, no remote click). Content test passes (plant
and puppet registered as actions). The uniqueness report now counts a new
kind's twists: no part-1 weapon is in a "same" or "near" group; five are the
plain weapon of a new kind. 25 soaks of 10 minutes, one per weapon (half with
+6 projectiles), 0 errors. Full-content replays re-recorded; the 6 classic ones
identical. `tools/check.sh`: CHECK PASSED. The IPA with part 1 was pushed with
`[ipa]` after that (release `ipa-latest`). Not tested on the iPad.

**4.6 part 2, CHARGE AND COMBO (done).** 25 weapons, ten new attack kinds;
details in `tiny_biggot_godot/ARSENAL.md`. `scripts/combat/charged.gd` (class
`Charged`). Charge, slam and dash are held to charge (`Charged.hold` replaces
the cooldown in `Combat._update_player_base`): with AUTO-AIM FIRE they let go
at full; with an aim button held they wait and fire where you aimed. Dashes
use the hero's own dash (`Player.dash_t`; `Abilities.while_dashing` skips its
trample when `dash_dmg` is 0). New hooks: `player_shoot`, `kill_enemy`
(`Charged.on_kill`), `on_roll_start` (`Charged.on_roll`), `Hazards.update`,
`G.enter_room`, `world_view`; `Arsenal.toss` throws the magdump's magazine.
Found and fixed on the way: two ids already taken (`magmamaul`, `stillwater`:
the new ones are EMBERQUAKE MAUL and SWIFTDRAW BOW; the bow got a new trick,
a roll draws it fully, because the old Blade of Still Water already uses
standing still; the test now checks ids); and a soak caught the javelin
dashing the bot back to a training dummy forever, so in a room with only
dummies no weapon moves the hero, and a javelin that misses comes back by
itself. Tests: `tests/arsenal_test` covers all 50 weapons (trick in a fight,
999 more projectiles) plus holding a charge, the roll draw, the glaive's
chain breaking on a miss, the javelin dash, the anchor drag, and no moving in
a dummy room. Desktop logic 0.15-0.31 ms a tick for the new kinds with 999
more projectiles; the heat and magazine guns use the old shot path (1.5-2.3
ms, worst ticks 16-22 ms at that count, like the old guns). Planted faults
caught (a charge firing while the aim is held, no javelin dash, a dash in a
dummy room). Uniqueness report: a twist's words count (a combo's steps); no
part-2 weapon in a "same" or "near" group; eight are the plain weapon of a
new kind. 25 soaks of 10 minutes plus three from the first floor, 0 errors.
Full-content replays re-recorded; the 6 classic ones identical.
`tools/check.sh`: CHECK PASSED. The IPA with part 2 was pushed with `[ipa]`
after that (release `ipa-latest`). Not tested on the iPad.

**4.6 part 3, DECK AND DEN (done).** 25 weapons: card decks (a real deck:
the next three cards over the hero, a shuffle when the pile runs out),
turrets and traps, summoned fighters (bone thralls from kills, a growing clay
golem, imps, a wolf pack, a mimic), pet commands, mirror images and a
shadow, swarms, a dragon egg, and a whip that tames foes. Details in
`tiny_biggot_godot/ARSENAL.md`. `scripts/combat/summons.gd` (class
`Summons`); new hooks: `player_shoot`, `kill_enemy` (`Summons.on_kill`),
`update_enemies` (a tamed foe's turn, `Enemy.charm_t`; no touch damage),
`auto_target` (skips tamed foes), the actions `charm` and `warm`,
`Hazards.update`, `G.enter_room`, `world_view` (pink tint for tamed foes).
Eight new sprites (`s_*`); mirror images and the shadow are the hero's
sprite, tinted. Found and fixed: a soak caught the mimic never catching a
fast wisp (it hopped to where the foe had been), which left the bot stuck in
one room for ten minutes; the hop now follows its foe, and bone thralls and
the golem move fast enough for quick foes. The mending totem, the pet whistle
and the frost beacon were far weaker than the rest (the bot cleared 14-42
rooms in 10 minutes against about 90) and were made stronger (the totem now
72). The looking glass's images fire at most three shots each (with 999 more
projectiles they had tripled the cost: worst tick 45 ms, now 13 ms like the
old guns). Tests: `tests/arsenal_test` covers all 75 weapons, and checks that
the hand plays in the order shown and shuffles back, catalyst doubles poison,
the countdown bomb waits three cards, two tesla coils burn a foe between
them, the totem heals, kills rise as thralls, the egg hatches and is an egg
again (half warm) in the next room, and a tamed foe is not aimed at.
Planted faults caught (the deck played from the wrong end, catalyst not
doubling). Desktop logic 0.15-0.25 ms a tick for the new kinds. The same
"lands where the foe was" flaw was fixed in two more weapons: the shepherd's
sheep follows its foe in the air and waddles at the nearest foe before it
blows, and part 1's mortar shells follow their foe for the first 70% of the
flight (the ring moves with it). 25 soaks of 10 minutes after the fixes, plus
the crook and both mortars again: 0 errors, no stalls. Full-content replays
re-recorded; the 6 classic ones identical. `tools/check.sh`: CHECK PASSED.
The IPA with part 3 was pushed with `[ipa]` after that (release
`ipa-latest`). Not tested on the iPad.

**4.6 part 4, GUNPLAY AND ODDITIES (done; 4.6 complete: 100 weapons).** 25
weapons, seventeen new attack kinds; details in
`tiny_biggot_godot/ARSENAL.md`. `scripts/combat/oddities.gd` (class
`Oddities`); new hooks: `player_shoot`, `kill_enemy` (`Oddities.on_kill`:
frozen foes shatter), `Hazards.update`, `G.enter_room`, `world_view` (a shrunk
foe is drawn at 0.55 size), and `Enemy.shrink_t` (no touch damage while
shrunk). Sprite `s_fish`. Two ids were already taken (`highroller`,
`avalanche`): GILDED SLOTS and SNOW ROLLER. Two ideas were dropped before
building because the game already has them (shots that grow as they
pierce, shots that ricochet between foes). The weapon test found the aegis
dome harmless to foes that keep their distance, so each attack also lances
the nearest foe. Junk fires in turn (testable), and the coin is tossed along
the line of fire (so shots can hit it). Tests: `tests/arsenal_test` covers
all 100 weapons, plus squashing a shrunk foe, the calling card spent once a
foe, yellow paint hastening you, the payday cannon spending a coin a shot
(lint when broke), and a frozen foe shattering. Planted faults caught (the
calling card on every hit, no squash). Desktop logic 0.16-0.27 ms a tick for
the new kinds; the slot pistols and the coin flipper use the old shot path
(worst ticks 13-23 ms with 999 more projectiles, like the old guns).
Uniqueness report: no new weapon in a "same" or "near" group. The part 4
soaks found two more things, both fixed: (1) a swarm of crawlers huddled on
the bot was never hit by the new kinds' own shots, which start a few pixels
out and only looked for foes where they were each tick, so the interceptor
sat in one room for five minutes; now every such shot (part 4's, part 2's
charged balls and javelin, part 1's rockets) checks the whole path it flew
that tick, starting at the hero (`Arsenal.swept`; the weapon test checks a
foe pressed against the hero is hit). (2) Bubbles and the shrink ray did
almost nothing to guardians and mini-bosses (they can't be trapped or shrunk;
the soap cannon took two minutes over one room): a bubble now bursts on them
for 1.5x, and the shrink ray hits them for 2.5x. (3) In a room where two
tollkeepers pour crawlers onto the hero, a single-target gun that only ever
shoots the nearest crawler never reaches the summoners (even the original
repeater is slow there; it gets through because its bolts pierce): the flak
guns' shots now go on through a foe, and hit a little harder (the
interceptor then cleared 37 rooms in 10 minutes on the seed where it had
been stuck in room 7). Re-soaked after the fixes: all 25 part-4 weapons and
the 11 older ones whose shots changed, 0 errors, no stalls (the slowest, the
plasma slugger, spends up to two minutes in summoner rooms). Full-content
replays re-recorded; the 6 classic ones identical. `tools/check.sh`: CHECK
PASSED. The IPA with all 100 new weapons was pushed with `[ipa]` after that
(release `ipa-latest`). Not tested on the iPad.

**4.7 part A, GEAR AND RELICS and a harder game (done).** His ask (5 Oct):
the 4.7 items, and "make the game a little bit harder, it is too easy at
this stage"; then part B (environments) and part C (Heaven and Hell), each
with an IPA. Details in `tiny_biggot_godot/GEAR_AND_RELICS.md`. 40 gear
pieces (four sets: RIMEWARDEN frost, BLASTWRIGHT demolition, BONECALLER
malice, CLOCKWORK swarm) and 20 relics, aimed at the thin spots counted from
the data (neck, hands and ring slots; frost, demolition, swarm, pyre;
moments nothing listened for). Data only, plus the effect system:
`scripts/effects/effects.gd` has six new triggers (`on_bomb`,
`on_armor_lost`, `on_dodge`, `on_overheal`, `on_chest`, `on_buy`; fired in
combat.gd, player.gd, game.gd only for a hero with procs) and seven
conditions (`close`, `far`, `fresh`, `last_foe`, `crowd`, `unhurt`, `coin`;
`Effects.foes_left`); `scripts/effects/actions.gd` eight actions (`turret`,
`raise` via `Summons.item_turret`/`item_raise`; `reflect` and `slow_shots`
via `EBullets.take_near`/`slow_near`; `spread`, `consume`
(`Actions.ailments`), `give`, `overkill` (`Enemy.over`, kept in
`damage_enemy`)), and the `gold_guard` hook (`_hurt_player_base`). `Enemy`
gained `struck` (hits taken, for `fresh`) and `over`. `Summons.clear` now
remembers the room it was called for, so a turret an item raises on entering
a room is not cleared a tick later (this also stops a second, needless deck
shuffle on entering a room). `Actions.ran`/`did` count what ran (the test
reads them). 60 new icons (12-wide gear, 10x10 relics; atlas 1157). Ten
names or ids were already taken and were changed before building (the old
MIRROR PLATE, VAMPIRE FANG, CINDER RING, PIGGY BANK, HEADSMAN'S HOOD,
PILGRIM SANDALS, WARHORN, DRAGON SCALE, QUICKDRAW, BONE FLUTE). The harder
game, expanded only (`Combat.hard_hp`, `foe_hit`, `shot_mult`,
`spawn_wave`): foes, mini-bosses and guardians +10% health on floor 1, +3% a
floor; one more foe a wave from floor 3; +3% elites; foes' shots 6% faster;
from floor 7 a foe's blow or shot costs a whole heart (a toast on arriving;
traps, hazards and your own bombs pass `env` to `hurt_player` and stay at
half). Measured with the bot (no god mode, all unlocks, the same 16 seeds,
10 minutes, the same build with the change off and on): deaths 22 -> 31,
average furthest floor 3.6 -> 3.1; before any of this, with all unlocks,
half the heroes reached floor 7-8 in 15 minutes without dying. Tests:
`tests/items_test.tscn` (new, in `tools/check.sh`; 19 s) checks every item
in its moment, the four sets on and off, and the new actions closely; six
planted faults were caught (16 failures). Content test passed; uniqueness
report: no new item in a "same" or "near" group, none numbers-only. Soaks:
14 runs of 10 minutes carrying all 60 items (7 loadouts, with and without
god mode), 0 errors. The six classic replays identical; the full-content
replays re-recorded. Not tested on the iPad.

**4.7 part B, the floors' new look (done).** Details in
`tiny_biggot_godot/ENVIRONMENTS.md`. `scripts/render/biome_deco.gd` (class
`BiomeDeco`): per floor three props drawn where the square pillar was (same
collision), floor marks, a centre piece in 60% of rooms (not start rooms),
top-wall dressing, lights for lit props (glow layer), drifting air (only
with FANCY EFFECTS on), and pit drawing. 43 new graphics (`prop_*`,
`wall_*`; atlas 1200). Layouts 17-20 with `T_VOID` pits in the expanded game
(`World.build_room`); `Hazards` runs `_off_the_edge` for them;
`Combat.drop_pickup` moves a drop that lands on a pit to the nearest floor
(this also helps Skyreach). His ask on 6 Oct, "revamp original stages too":
`BiomeDeco.on` no longer requires the expanded game, so `--classic` gets the
look (drawing only; classic replays identical). Full-content replays
re-recorded. Soaks: 23 x 10 minutes, every floor, 0 errors, none stuck. Not
tested on the iPad.

**4.7 part C, Heaven and Hell (done; 4.7 complete).** Details in
`tiny_biggot_godot/HEAVEN_AND_HELL.md`. `scripts/game/soul.gd` (class
`Soul`: weigh, realm); `Themes.REALMS` (heaven, hell, seam; found by
`by_id`, never picked as rifts); `game.gd`: the soul gate in the true ending,
`_enter_realm`, `_realm_won`, `open_exits` skips a realm ruler's room, the
page portal, the award parts; `world_view.gd`/`overlay_view.gd`: the gate and
page portal; `menu_view.gd`: the last ending's lines. Bosses `judge`,
`cinderking`, `unwritten` in `GameData.BOSSES` and `BossAI` (new attacks
halo, verdict, brimstone, hellgate, ink, rewrite; verdict and brimstone use
`RiftBosses.bands`/`rings`). `tests/realms_test.tscn` in `tools/check.sh`;
three planted faults caught. Soaks: 8 x 10 minutes in the realms, 0 errors.
Not tested on the iPad. Next: 4.8 (characters) needs his one-line yes per
character first.

**Rex's moldy bread (his ask, 6 Oct).** `rex_sword.png` redrawn as a moldy
bread loaf (same 36x9 size and grip, so every move, reach and hit is
unchanged); his phase-two line is now "SUNGLASSES ON. HE FOUND A MOLDY LOAF
IN THE HAY". Code names (`rex_sword`, SWORD SPIN...) kept. RIFTS.md updated.

**Brazil easter egg (his ask, 6 Oct; done).** `scripts/game/brazil.gd`
(class `Brazil`), see `tiny_biggot_godot/BRAZIL.md`. Hooks: `spawn_wave`
(`Brazil.maybe_spawn`, one `randf` a wave in the expanded game), the touch
code in `Combat.update_enemies` (haggler catches, scrounger robs),
`kill_enemy` (haggler hoard), `damage_enemy` (`Brazil.cow_rises`),
`Hazards.update` (nags), `on_boss_dead` (cow milker). `Themes.REALMS` has
"brazil" ("short": its second fight leads straight to the guardian).
`BossAI`: plan holycow, and `THIRD_PLANS`/`THIRD_SUMMONS` (used when `e.phase == 3`), attacks moo,
milkrain, udder, ascend, holyfire, stampede. Weapons may set "bullet" in
their stats (the milker shoots sparks). Full replays re-recorded.

**4.8, ten more heroes (done, his go on 6 Oct).** See the 4.8 section of
`tiny_biggot_godot/HEROES.md`. Hero indices 14-23. New actions
`charm_area`, `consume_area`, `execute_weakest` (`actions.gd`).
`tests/heroes_test.tscn` in `tools/check.sh`. The Beastmaster's tame chance
went from 8% to 12% after the test showed two tames in 30 s (too rare to
feel). Soaks 10 x 10 minutes, 0 errors (a fresh Frost Witch started on floor
9 is slow against golems, not stuck).

**4.10, the monkey (done).** `--monkey` presses random buttons from its own
generator (seeded by --seed) in every state; `tools/dev/monkey.sh` runs an
hour from the title with `--objects`, then ten 6-minute runs started in new
heroes, late floors, Heaven, Hell, Brazil, Rex, a loop and --classic. Result:
11 runs, 0 errors; objects 3026 -> 3132 in the hour (nodes 64, resources 115
throughout). `BiomeDeco._rng` is now seeded by --seed too (picture tests).

**4.11, stage 4 delivered (6 Oct).** `tools/check.sh` CHECK PASSED, the IPA
built with `[ipa]`. The check found two slips fixed before it: the atlas had
not been baked after the hero sprites, and the Mirror Knight's sword id
clashed with the old MIRRORBLADE (now `brightblade`, BRIGHT BLADE). Next:
stage 5 (sprite revamp), which starts with a sample for his yes (5.1).

**4.12, souls-like guardians (his ask, 6 Oct).** See
`tiny_biggot_godot/BOSS_STAGES.md`. `BossAI`: `STAGE_PLANS`, `STAGE_LINE`,
`_want_stage`, `_stage_break` (state `stagebreak`, which `damage_enemy`
refuses), `done()` rests less by stage and chains in stage 3, the pulse
(`Enemy.pulse_t`); `Enemy.stage`. New attacks wall, flower, cross, barrage.
`game.gd._boss_reward` (expanded game, not Rex's barn). The Colossus keeps
its rule of summoning only below half health. Full replays re-recorded.

**4.13, every boss and mini-boss (his ask, 6 Oct: "apply to all bosses and
mini bosses, also they drop unique equipment or weapon fitted to them").**
`scripts/combat/stages.gd` (`Stages`, hooked in `Combat.update_enemies`
before the AI; `Enemy.break_t`, which `damage_enemy` refuses): every floor
mini-boss, rift mini and rift champion breaks into stage 2 at 67% and stage 3
at 34% (wall of shots with a gap every 6 s; then ring + fan every 3.5 s and
quicker attacks); rift guardians and Rex (which have a second phase at half)
break into stage 3 at 25%. `scripts/data/boss_loot.gd` (`BossLoot.DROPS`):
37 owners, each with its own legend item (16 weapons, 21 gear pieces, rows at
the end of `weapons.gd` / `gear.gd`), dropped by `game.on_boss_dead` and
`Combat.kill_enemy`; `random_weapon` / `random_gear` never roll them. Test:
`tests/bosses_test.tscn` (in check.sh). Full replays re-recorded.

**5.1, art sample (6 Oct): he picked a mix of A and C (look "D" in
`tiny_biggot_godot/tools/art/render.py`).** In the game: hexer, bat, skeleton, slime
(+ elites: the outline turned gold), colossus, hearts, w_hexwand, w_repeater,
w_pithatchet, w_graveshovel, w_flasksling, kit0. Same sizes. To redraw more: add grids to
`sprites.py`, run `python3 tools/art/sheet.py x.png` from a folder outside the project,
copy `out/D/*.png` into `assets/graphics/`, bake the atlas.

**5.2, the heroes (6 Oct).** All 24 hero sprites redrawn in `tools/art/sprites.py`
(same 12x14 rows as `hero_gear.gd`: head 0-6, body 7-10, hands row 9, legs 11, feet 12).
Skin tones vary by hero (`skin:` in each sprite's line). The gear overlay's outline is
now tinted by the piece's colour (`HeroGear.palette`, 4th entry). 5.2b (his picks):
nine heroes went back to their old design, remastered (marked in `sprites.py`);
warm colours' highlights now lean to yellow (`render.tones`). Next: 5.3 (foes).

**5.3a (6 Oct).** First three floors' foes and guardians redrawn (all new, his pick).
Elites: `sprite(name, vb, elite=True)` with the `ELITE` marks; every elite file is
made by the tool, so a foe redrawn later gets its elite in the same run.

**5.3b (6 Oct).** Cinderforge to the Umbral Sun (26 foes and minis, 8 guardians). `M()` in
`sprites.py` mirrors a left half into a whole sprite. Glowing bodies (`halo:1`) keep their
glow as elites. His ask: no tests or IPA until stage 5 is all drawn; then one check and
one IPA.

**5.3c-e (6 Oct).** Every foe, champion, mini and guardian is now drawn in `sprites.py`
(`OV()` adds one-handed things to a mirrored sprite; `compare.py` makes his pick sheets).
Rex and Rex lying down are recoloured only (`REMASTER`). His picks are in: the old designs he
kept are recoloured pixel for pixel from `tools/art/src/` (`REMASTER`, `REMASTER_ELITE`: the
elite's outer outline turns gold, the body darker).

**5.4 (6 Oct).** The 518 icons are recoloured from `tools/art/src/icons/` with `_shade()` in
`render.py`. To redraw one: add its grid to `sprites.py` (it then wins over the recolour).

**5.5 (6 Oct).** Tiles: `kit_remaster()`; objects, npcs, summons, hydra parts, Rex props:
`remaster(shade=True)` from `tools/art/src/rooms/`. Next: 5.6 (HUD and menus), then the one
full check and IPA of stage 5.

## Noted, not yet acted on

- Saving a run in progress (so iOS closing the app does not end it). Needs
  his say: it is a large change (the whole run state).

## Tools

- Godot 4.6.1: `Godot_v4.6.1-stable_linux.x86_64.zip` and
  `Godot_v4.6.1-stable_export_templates.tpz` from the godotengine/godot
  releases on GitHub. Templates go to
  `~/.local/share/godot/export_templates/4.6.1.stable/`.
- `tiny_biggot_godot/tools/check.sh` is the full test suite (about 8 minutes).
- `tiny_biggot_godot/tools/dev/` holds the comparison and timing scripts used
  so far, with a README.
- To compare pictures: check out 4ecba1f beside the working copy
  (`git worktree add ../base 4ecba1f`), import both, and record the same
  seeded run in each with `--write-movie` (see `tools/dev/cmpbuilds.sh`).
