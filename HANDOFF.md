# Handoff: where the work stands

**10 Oct: his trait pictures.** 146 traits and 14 infusions to add (TRAITS_PLAN.md), in
Stages 40 to 44 (STR, DEX, INT, SUPER/PSYCHIC/AUGMENT, infusions), then 45 the alignment shops.
Stage 40 done (IPA 40 "Strength Traits"), Stage 41 done (IPA 41 "Dexterity Traits"), and his
"How traits work" text as 41.5 (IPA 41.5 "How Traits Work": a limit of 12 traits, his pick),
Stage 42 done (IPA 42 "Intelligence Traits"), Stage 43 done (IPA 43 "Super Traits"), 43.5 done
(IPA 43.5 "Steady Ground"), 43.7 done (IPA 43.7 "Old Traits Reborn": the 286 old traits each
gain one more effect and their own picture). Then his "Ok go 44 and 45, and 46": Stage 44 done
(IPA 44 "Infusions"), Stage 45 done (IPA 45 "Alignment Shops"), Stage 46 done (IPA 46 "Weapon
Enchantments"; the full check passed). Then his list of another game's core gameplay
(GAMEPLAY_PLAN.md): most of it is here; Stages 47 to 51 proposed in ROADMAP.md. His pick: Stage 47
(THE GOURD, SHATTER), and during it the title menu and the hero select reworked (his word): built,
its test passes; the core replays, the full check and IPA 47 "Gourd and Shatter" still to come.
Then: his try of it, and his pick of Stages 48 to 51.
Done before: 39.4 "Bosses Fall" (IPA 39.4), Stage 39 "More to Find", 38 "Alignment and Loot", 37,
36, 35 (the full check passed at 35). Next: Stage 40.

**His word, 9 Oct: "Just compile after add, I'll test it."** Until he says otherwise: after adding
content, only compile (import; a short run that starts the game) and build the IPA. He tests on the
iPad. The full check and the core replay re-recording wait until he asks or something breaks.

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
`remaster(shade=True)` from `tools/art/src/rooms/`. 
**5.6 (6 Oct).** HUD and menu icons from `tools/art/src/hud/`. Logos, font and effects untouched.
Stage 5 done: town people remodelled (his ask; the broker kept, recoloured; the drunk is a
standing sprite turned flat, `_lying()`). Full check passed, IPA 5.6 built (release ipa-5.6).
He kept all 5.4 icons as they are.

**5.7 extras (6 Oct).** `raider` foe (Brazil pool, `Brazil.rob` takes double), `Meta.opts.haggler`
(OPTIONS > MEET THE HAGGLER, `Brazil.maybe_spawn`). Tests in `realms_test` (`_meet_haggler`).

**5.8 harder (6 Oct).** `Stages.gate()` read before each blow in `Combat.damage_enemy` (only
bosses and minis; other foes keep overkill). `Combat.run_scale/boss_hp`, `hard_hp` and `loop_scale`
raised; `game._roll_twist()` and `Room.twist`. Tests fell bosses through their stages (`_fell`), and
`bosses_test._gate` checks the stage lines. Broken builds (bot, --combo): the first guardian lasts
about twice as long.
Evolved guardian looks: `render.evolve()` from each finished sprite; `world_view._enemy_sprite`
picks `_s2`/`_s3` by `Stages.look(e)`; `bosses_test._looks` checks them.
5.9: `form()` puts each stage's parts (`FORMS`) on the guardian before `evolve()`; the canvas
grows sideways and up only (bottom-centred drawing).
6.1: `MINIS` + `_mini_form()` (also `<name>_elite_s2/_s3`); `Stages.look` covers minis. 6.2: Rex
`rex(_lie)_s2/_s3` from `FORMS["rex"]` and `cute()`; `PART_META` colours a part on its own.
6.3: `RunSave` (save at `start_floor`, clear in `award_embers`, CONTINUE in `title_items`).
6.4: theme `spire` (themes.gd), foes and `foreman` (game_data ENEMIES), `greatengine` (BOSSES,
`rift: true`, BossAI plans like the Holy Cow), hero `clockmaker` (last of NEW_HEROES), weapons at the
end of weapons.gd ROWS, `foremanhat` in gear.gd, drops in boss_loot.gd; art in `tools/art/sprites.py`
(`kit_spire` from `kit()` with its own colours).
6.5 (his video: "still instantly clears everything"): `Combat.power()` = the weapon sheet
(dmg × rate × shots × crits) or `run_stats["dps"]` (what he really dealt in locked fights, a 20 s
running average fed by `damage_enemy` → `run_stats["dealt"]`, `Combat.track_power` in
`update_play`), whichever is more. `power_scale()` = (power / yardstick)^0.65 when ahead, the
yardstick `run_stats["power0"]` (set in `new_run` before `--give`) × (1 + 1.3f + 0.25f²) × loops;
it rides in `run_scale()`, so foes, minis, guardians and hazards all read it at spawn.
`scripts/combat/armor.gd`: a plate per stage (35% guardians, 25% minis/champions), 25% of a blow
through while it holds, break = stun (not when the same blow starts the next stage: the stun would hold the stage back) + vulnerable 3 s; `Armor.shown()` for the boss bar (drawing
never touches the foe). `boss_hp()` 2.0. Tests that fell a boss strike `hp + Armor.shown(e)`;
`bosses_test._armor`. Bot runs, seed 3, --god, against 6.4: High Caliber guardians 8-41 s → 36-110 s,
Hall of Mirrors 10-46 s → 30-163 s; floors take about 50% longer.

6.6: `EliteTraits` (`scripts/combat/elite_traits.gd`): `roll()` at the end of `spawn_enemy`
(elites only, not minis or champions; `Enemy.traits`), `tick()` in the foe loop before the stun
check (mending, `Enemy.mend_t` reset in `damage_enemy`), `on_kill()` from `kill_enemy`
(splitting, volatile). PLATED goes through `Armor.has/plate`. Labels drawn in
`world_view._paint_bars`. `tests/traits_test.tscn`.

7.1: `Armor.weakness(e)` (a fixed pick from the key's letters among fire, poison, storm, crits,
blasts; guardians, minis and champions only), `Armor.weak_hit(e, o, crit)` from damage_enemy's
options (`col` orange / lime / cyan, the crit, `boom`/`bomb`), `soak(..., weak)` wears the plate
×2.5. "WEAK: X" right-aligned above the boss bar. `bosses_test._armor` checks the wear.

7.2: `Trophies` (`scripts/game/trophies.gd`, Meta.meta["trophies"] = { hero id: [boss keys] }):
`take()` in `G.on_boss_dead` (toast, `run_stats["trophies"]` → NEW TROPHIES embers in
`award_embers`), `apply()` in `new_run` after `start_rare`, `line()` on the hero screen in place of
the unlock line. 19 guardians (not Rex): rewards at 5 / 10 / 15. `tests/trophies_test.tscn`.

7.3: theme `rimefrost` (themes.gd, hazard spikes), foes and `hoarknight` (game_data ENEMIES,
after the Foreman), `glacialmaw` (BOSSES, `rift: true`, BossAI rows next to the Great Engine's),
drops in boss_loot.gd, `hoarhelm` (gear.gd), `glacierheart` (weapons.gd, after enginecore); art in
`tools/art/sprites.py` (7.3 block), `kit_rimefrost`, FORMS/EVOLVE/MINIS rows in render.py.

8.1: `Alignments` (`scripts/game/alignments.gd`; `Player.al_good/al_evil/al_law/al_chaos`): `leads()`,
`devout()`; Effects conditions `lead_*`/`devout` and the `while_align` proc (`need`); shrines
(`alshrine`, from the rest stop setup; drawn in world_view, card in overlay_view); realms +2 in
`_realm_won`. Stars: `DIRS`, `ALIGN` and the diagonal chains at the end of `nodes()` (rogues only).
Icons `al_good/evil/law/chaos` (tools/art 8.1 block). `tests/align_test.tscn`.

8.2: `TraitView.KEYWORDS` (more words) and `ICONS` (7x7 `mi_*` from `tools/art/mini_icons.py`);
`rich_lines` gives [word, colour, icon]; `draw_line`, `draw_rich`, `line_w`, `wrap_rich` draw and
measure it. Used by trait cards, relic choice, star cards, item cards (ItemShow.rich_line/line_w),
the equipment page and the inventory (whose stat sidebar has icons and the alignments).
`hud_view._stat_column` (option STAT COLUMN, `Meta.opts["statcol"]`); options rows 74 + 18 px.

8.3: `StatDrops` (`scripts/game/stat_drops.gd`): pickup kinds `s_*` (taken in
`Combat.update_pickups`, drawn with a label in world_view), `maybe()` from `room_cleared`, chests,
elite kills and `on_boss_dead`. `Attributes._side()` from `add()` (and `start()` goes through `add`).
`tests/stats_test.tscn`; content_test's crit count includes the DEX side stat.

8.4: rows at the end of traits.gd ROWS before GOLDEN BLOOD (`x_*` SUPER, `f_*`, `y_*`); rarity
`super` (weight 1, from level 4 in `_new_trait_weight`); `Traits.PLUS` (extra family ranks in
`take_trait`); action `stack` (actions.gd, capped in `p.gf[key]`); hooks `idle_dmg`, `collect_dmg`,
`zealot_dmg`, `prism_dmg` in `Combat.hook_mult`, `purse` through `Combat.held_gold()`.
`tests/supertraits_test.tscn`. The odds box: `TraitView.odds()` and `_odds()` (cached in `G.tchoice["odds"]`).

8.5: trait pick layout in trait_view.gd (PX/PW rows, COL_X/COL_W column, FOOT_Y, `reroll_rect()`
for taps.gd, `bullets()` splits a text into its sentences; SUPER rows pink). `Traits.COMMON_SUPER`
weights in `_new_trait_weight`; the "drop" action takes "stat" (a random stat pickup).

9.1/9.2: `Chaos` (`scripts/combat/chaos.gd`): `beams`, `hooks`, `zones`; `cast_beams/cross/hooks/
zone`; `tick` from Hazards.update; `clear` with RiftBosses.clear (room change, boss death, stage
break); drawn in world_view next to RiftBosses. BossAI states "lasers", "laserx", "hooks", "zone"
("beams" was already an older move). Plans of the floor 8+ and realm guardians use them.
`tests/chaos_test.tscn`.

9.3: `GameData.ALT_GUARDIANS` (floor index -> key), rolled in `start_floor` into
`floor_d["guardian"]` and spawned at game.gd's boss room; the seven in BOSSES, BossAI tables,
afx colours, render.py EVOLVE/FORMS, sprites.py (9.3 block), drops in boss_loot.gd with their
gear/weapon rows. The phoenix's rise: `Brazil._phoenix_rises` (via `cow_rises`), THIRD_PLANS.
chaos_test section 5.

10.1: `Live` (`scripts/game/live.gd`): `now(effects, p)` reads hooks (gold/relic/armor/collect/
idle/zealot/trait _dmg), "stack" bonuses (`p.gf[key]`) and miser; `Live.desc(t)` used by trait
rows, item cards, relic choice and prompts, the equipment page and the inventory. `tests/live_test`.

10.2: event_rooms.gd `EVENTS_10` (frog, ritual, pawn, cups, lightning; kinds e_frog, e_glyph,
e_pawn, e_hustler, e_cup, e_gong): setup / interact / update (`_update_cups`, `cup_pos`,
`_update_gong`) / prompt / draw. `G.mystery_events()` adds them in the expanded game only (the
classic list is untouched). world_view's event-object match lists them. `tests/events10_test`.

10.3: heroes `minstrel`, `jester`, `berserker`, `forsaken` (end of NEW_HEROES; weapons lute,
jugglepins, greataxe, rustyshiv in HERO_WEAPON; branches SONGCRAFT, TOMFOOLERY, BLOODLUST,
SURVIVAL; attributes; art in sprites.py 10.3 block); heroes_test NEW covers them.

10.4: kind `flail` (`scripts/combat/flail.gd`: `tick` from Hazards.update, `fire` from
Combat.player_shoot's match, `draw_over` in world_view, `clear` with Arsenal.clear); base row in
weapons.gd KINDS, ARCH_DESC, WeaponInfo type PHYSICAL, attribute grades A/B/-. Six weapons before
the 10.3 hero weapons; icons from one grid in sprites.py (10.4). `tests/flail_test`.

10.5: option `neon` (Meta.opts; OPTION_LIST "NEON LOOK", rows now 17 px apart): world_view
`_paint_neon` replaces the tiled background (black, a bright double outline and a dotted band in
NEON[floor] or the rift world's accent; pillars outlined). Toggling emits room_changed. `--neon`.

11.2 (part): world_view `_paint_warnings`: a red circle and "!" under a foe in a wind-up state
(`WINDUPS`: slam, tele, swell, wind, spin, thrust, palm); drawing only, expanded game.

11.2: aura relics (relics.gd after furnaceheart; icons from one halo grid); status `gloom`
(Enemy.gloom/gloom_t, Statuses apply/tick/dmg_mult, condition "gloomy", keyword GLOOM); beams fan
one ray per projectile in the expanded game (`attack_beam(..., more)` keeps the fan's pictures);
weapons duskblade, prismfan, spectrum; relics gloomlantern, nightfall. `tests/gloom_test`.

11.3: `Combat.hard_hp` 1.45 + 0.06 f; `shot_mult` x1.10; elite chance +0.04 (game.gd).

12.1: `Story` (`scripts/game/story.gd`, STORY.md): `LINES` gated by milestones in
`Meta.meta["story"]`, `reach()` from on_boss_dead (floors 6 and 11) and `_realm_won`, the Archivist
(`n_archivist`, an EventRooms kind; seated by `Story.place` in rest stops). `tests/story_test`.

12.2: `GameData.CHAPTER2` (3 floors) joins `floors()` when `run_stats.chapter == 2`
(`_main_floors()` is the plain list). The seam's `n_endbook` / `n_turnpage` (game.gd `_realm_won`);
`begin_chapter2()`; `_chapter_won()` (the Author: last floor while chapter 2). `Story.chapter2()`,
`bind_shop()` (`n_bookbinder` at rest stops), `inkling()` (`n_inkling`, EventRooms.on_room_clear).
Test option `--chapter=2` (then `--floor=0-2`). Tests: realms (`_chapter2`), story (the people).

12.3: `Story.hide_page` (from setup_objects "secret") / `take_page` (`run_stats.pages`,
`page_floors`); `_chapter_won` with 3 pages adds `n_endbook` + `n_redactdoor` (EventRooms) →
`_enter_realm("redaction", 3)` (Themes.REALMS "redaction", kit_redact); `_realm_won` "redaction".
Boss `redactor` in GameData.BOSSES and BossAI tables. realms_test `_redactor()`.
Test option: `--chapter=2 --floor=2 --rift=redaction --step=3`.

12.4: endings in `menu_view.draw_end` (run_stats author / redactor); BossLoot drops inkspout,
binderthread, authorspen, blackbar (weapons.gd, gear.gd; icons in sprites.py).

13.1: key mapping in `Keys` (keys.gd): `DEFAULT_KEYS`, `REBIND` (the page's rows), `LOCKED`
(Esc, Enter), `keys_of`, `apply_keymap` (rebuilds keyboard events; pads bound once in
`_setup_input_map`), `set_key`, `reset_keys`, `capturing` (the next key press in `_input`).
Saved in `Meta.opts["keymap"]`. State `keys`: game.gd `update_keys`, menu_view `draw_keys`, taps.gd.
`--ui=keys` / `--ui=options`. `tests/keys_test`.

13.2: gear.gd `B3`, `MASTERY`, `_tier_of` / `_apply_tier` (tiers 1-3 in the expanded game, 1-2
under --classic), `_complete` (once per run: `run_stats.sets_done`), `chase_piece` (random_gear and
the shop), `continues_set` (plates), `pieces`. Aura: world_view `_paint_set_aura`. `tests/sets_test`.

13.3: traits.gd rows `z_*`, `x_tailor`, `x_halo`; hooks `wardrobe_dmg` (combat.gd hook_mult) and
`tailor` (gear.gd random_gear).

14.1: SETS gain "size": 6 (e4 at 4 pieces, e6/d6 at 6); `set_size`, `step_need`, `full_desc`;
`_tier_of(n, size)`. Piece icons: `tools/art/set_icons.py` writes recoloured `src/icons/g_*.png`.

14.2: state `wardrobe` (game.gd `open_wardrobe`, `update_wardrobe`, `pause_items()` replaces the
fixed pause indexes), menu_view `draw_wardrobe` / `ward_top`, taps.gd. `tests/wardrobe_test`.

14.3: hidden combos are Synergies.COMBOS rows with "hidden": true and two "trait:" needs;
effects.gd `_found_hidden` (Meta.meta["combos_found"]), `found_partners` (trait_view `_row`).
`--ui=traits --combo-hint`. `tests/combos_test`.

14.4: `GameData.CHAPTER3` (`floors()` with chapter 3 = main + CHAPTER2 + CHAPTER3, kits 14-16);
`_realm_won("redaction")` offers `n_endbook` / `n_readon` (EventRooms) → `begin_chapter3`;
`_chapter3_won` (the Reader). Story milestones ch3, reader. realms_test `_redactor` walks Chapter III
(and clears trophies before the stage checks: they make later test runs stronger).

15.1: `scripts/game/fishing.gd` (state `fishing`: update from game.gd, panel from menu_view, the
pond via EventRooms kind `e_pond`; touch: a finger anywhere holds USE). `Meta.meta["fish"]`,
`run_stats.fish`. `Fishing.auto` plays itself (tests, `--fish-auto`). `tests/fishing_test`.
15.2: ponds are `place(r, cx, cy, rx, ry, dock, casts)`; all drawn in code (`draw_pond`); `keep_out`
(from EventRooms.update); event "fishing" (THE FISHING HOLE, `setup_hole`), kind `e_angler`.
Sprites `fish_*`, `npc_angler` (sprites.py). `--ui=fishing [--no-cast] [--fish-auto]`.

16: `RoomDress` (scripts/render/room_dress.gd): `paint_static` (world_view `_paint_bg`, after the
floor's own dressing), `paint_live` (lower layer), `paint_glow`, `tick` (critters, own RNG);
`furnish` → `place_pots` / `place_coins` / `place_kegs` (game.gd setup_objects; placed with the
room's own seed so the run's random numbers are not shifted; drops roll at break time) and `tick_objects`
(EventRooms.update); kinds `e_pot`, `e_coins`, `e_keg`. `WALL_SPOTS` keep wall dressing clear of
the HUD. `tests/rooms_test`.

17.2: `Camp` (scripts/game/camp.gd): `enter` (room type "camp", kit1, no exits: open_exits
skips it), `setup` (setup_objects), kinds `c_*` (EventRooms), `paint_static` (RoomDress),
`back_state()` (shrine, skill trees, constellation return to the camp), `pause_items`
(LEAVE CAMP). The camp's pond has "camp": every world's fish. `--ui=camp`. `tests/camp_test`.

17.3: kegs have a fuse (`RoomDress.FUSE`, `o.fuse`), `_foe_shot_near` (foes' shots light kegs and
break pots), `_blow` pushes foes (kx/ky) and breaks crates; EBullets chips crates (`hit_crate`, 3)
in the expanded game. Weather: `STORMY` floors flash (`paint_over` in world_view `_paint_top`),
ink rain on chapter floors (own RNG).

18.1: `Daily` (scripts/game/daily.gd): `start(day)` (seed, hero, rule; `run_stats.daily`),
`is_on(id)` hooks in game.gd (elite chance, price, boss relics), combat.gd (foe speed, boss hp),
room_dress.gd (kegs); `on_end` from award_embers (score, `Meta.meta.daily_best`). Camp kind `c_daily`.

18.2: hero "inkling" (game_data NEW_HEROES, weapons inkquill, traits branch INKCRAFT + NODE_EFFECTS,
attributes); zone kind "ink" (combat.gd update_zones, vfx.gd draw_floor, world_view motes).
18.3: `tests/balance_probe.gd` (not in check.sh): `--probe-hero=N --probe-secs=S`; prints
"[probe] kind id ratio". Its arena suits ranged heroes; melee heroes barely reach the foes there.
19.1: probe `--probe-melee` (slimes with 60 health, back at once beside you) `--probe-hero=ID`
`--probe-only=a_storm,set:viper`. Traits that score exactly the same as each other did nothing in
the arena (room-enter, rolls, getting hit, gold: not measured there). Melee finding: projectile count
did nothing for swords and whips. Now (expanded only) combat.gd `attack_slash`: each projectile past
the first gives +30 degrees of arc and +15% damage; `whip`: one more lash in a fan. BULLET STORM for
melee heroes went from 0.80 to 1.02-1.35 (swords) and 1.3-2.3 (whips). Replays all identical.
19.2: `CampLife` (scripts/game/camp_life.gd), set up from `Camp.setup`, kinds forwarded by
`Camp.interact/prompt/draw` (and listed in EventRooms KINDS + world_view). Meta: `larder` (filled by
`Fishing._catch` → `stock`; first use copies the `fish` counts), `meal`, `song`, `next_relic`,
`cat_pets`. `on_new_run` (game.gd new_run, after Trophies) applies and clears them, except while
`Daily.starting`. States `kitchen` and `armory` (game.gd update, menu_view draw, taps.gd).
`Camp.fresh_player()` (enter and PUT EVERYTHING BACK; the rack never marks anything found).
`spawn_dummies` (Camp.enter). Combat: `_hurt_player_base` returns in the camp; auto-aim reach 90
there. `--ui=kitchen|armory [--camp-fish]`, `--ui=camp --camp-near=KIND`. `tests/camp_life_test`.
19.1 follow-up: sword arc/damage bonus counts at most 6 extra projectiles, whips at most 7 lashes
(a 999-projectile whip was 150 ms a tick). arsenal_test now seeds each fight by the weapon id (it
had one seed for hundreds of fights in a row, so any change upstream moved later fights' luck:
FROST BEACON's foes were pushed out of reach) and holds foes in place for turrets.
20.1: probe `--probe-live` (3 slimes + 3 skeletons, 60 health; not god, health topped up below 3;
`start_roll` every 2s and `Abilities.use` when ready, both inside the counted window, or their
instant damage is missed; a new room every 10s), `--probe-heroes`, `--probe-seeds=N`,
`--probe-actions`. Expanded-only hero changes: `GameData.ORIGINAL_SPECIALS` and
`ORIGINAL_PASSIVES` (merged into copies of the six originals in `heroes()`, never with --classic);
`Abilities.has_special` and game.gd new_run (hero effects) also check `GameData.rogues()`, so tests
that set `force_classic` see the originals as before. Hero page: a skill line for the originals.
Weapons raised: iciclewand (5.0, pierce 2), beastspear (9.0, 2.5/s), gearwound 3.4, lute 5.0,
pilgrimstaff 5.6, rivetgun 3.8. Traits raised: x_winter, y_prism, v_toxic.
20.2: `CampBuild` (scripts/game/camp_build.gd): PLANS, `built(id)`, `build(id)` (places the
`c_deco` objects and repaints the camp), kinds `c_build` / `c_deco` (Camp forwards them), state
`plans`, `paint_static` / `_still` (each thing at SPOT; the page draws it twice the size with
draw_set_transform), `lights` (lanterns), `on_set_out` (the portal: Meta `lend`), `on_run_end` (the
trap; own RNG). `Quests` (scripts/game/quests.gd): POOL, `active()` (Meta `quests`, 3, own RNG),
`met`, `on_run_end` (award_embers: parts "QUEST: ..."), `check_camp` and state `board`
(`open_board`, c_board). CampLife: visitors `v_gambler`, `v_tinker` (Meta `next_gear`), SPOTS[2]
with the guest tent, `meal2` (smokehouse), garden hearts in `on_new_run`, armory rows "g"/"s"
(master's rack). gear.gd `_complete` skips the camp. `--ui=plans|board`, `--camp-built`.
`tests/camp_build_test`.
20.3: `GameData.CHAPTER4` (`floors()` with chapter 4 = main + CHAPTER2 + CHAPTER3 + CHAPTER4, kits
17-19), foes and minis in ENEMIES (+ SPRITE_COLOR, ENEMY_XP), BOSSES shelver / hush / critic
(boss_ai plans, stage plans, lines, summons, ring and shot sprites; afx SHOT_COL). Hazards "books",
"lamps" (strikes) and "hearth" (pits + strikes). game.gd `_chapter3_won` now offers `n_endbook` /
`n_shelf` (EventRooms) → `begin_chapter4`; `_chapter4_won` (critic: `critic_wins`, three chests,
win); award "CHAPTER IV" 700; end screen "WELL READ"; Camp ENDINGS. RoomDress `library()` and
`_library_floor` (shelves at WALL_SPOTS, floor scatter; dust motes / rising embers instead of ink
rain). Sets `bookworm`, `criticregalia` (icons from set_icons.py); BossLoot shelversarm, hushbell,
redpen (sprites.py). realms_test walks Chapter IV to the Critic's win.
21.1: `Barks` (scripts/render/barks.gd): `say(who, text)` (a Player, an Enemy or a room object),
`hero(event, big)` (HERO / VOICE / FLOOR_LINES), `update` (game.gd update_play: expiry, foe barks
twice a second, elite taunts, `_boss_line` for G.boss, `_streak`), `flee(e, dt, p)` (Combat
update_enemies, before EnemyAI.run: one foe in three by `uid % 3`, no dice), `camp_tick` /
`camp_reset` (GREET; `last_run_line` from Meta `last_run`, written by `remember` in award_embers),
`draw` (world_view `_paint_texts`). Own RNG; nothing under --classic. Enemy `flee_t`, `fled`.
NOTE: the core replays are re-recorded once at the end of Stage 21 (21.1 and 21.5 change play).
`tests/barks_test`.
21.2: `Remains` (scripts/render/remains.gd): `add(e)` (Combat.kill_enemy), `scorch(x, y, r)`
(Combat.explode_at), FAMILY by words in the foe's type, Room `remains` / `scorch`, `tick` (once a
second; EventRooms.update), `paint` (world_view's dyn layer). RoomDress: `place_props` (furnish, last,
room seed), kinds `e_candle` / `e_shelf` (tick_objects: roll, shots, foe shots; `knock`; drawn on the
dyn layer, flames live, glow), `scare(x, y, r)` (explode_at: props fall, critters bolt), crows on
BIRD_FLOORS (`_bird`). `Snd.play(name, true)`: pitch from its own dice (decor must not move the
run's dice: the original pitched sounds roll the global randi). `tests/remains_test`.
21.3: `Ambience` (scripts/core/ambience.gd): FLOOR (floor name) and RIFT (theme id) -> [loop,
footsteps]; `on_room` (end of Game.enter_room), `tick(p)` (update_play after update_player:
`Snd.calm(not G.locked)`, a step every STRIDE px walked, none in a roll, a leap or a jump),
`stop` (title, death, win). Snd: two `_amb` players crossfaded in `_process` (AMB_VOL 0.12, x0.6
in a fight), `_music_level` MUSIC_VOL 0.7 / MUSIC_CALM 0.45 (calm only while a loop plays),
`step(surface)` on its own player, `places()` = sfx and OPTIONS PLACE SOUNDS (Meta opts
"places"; options rows now OPT_Y0 68, OPT_DY 15). Own dice throughout. The sounds:
`tools/audio/sounds21.py` (pure Python; noise beds made seamless by `seam`, loops matched by
loudness) -> assets/audio/amb/amb_*.wav (import: loop forward, QOA) and se/cc_step_*.wav.
Measured with the movie writer: the loops sit 2-5 dB under the calm music, about 12 dB under
it in a fight; footsteps peak about 11 dB under a hit. A run that is not headless reports
streams still in use at exit (music, effects and now a loop): the dummy audio driver, as before.
`tests/ambience_test`.
21.4: `Wanderers` (scripts/game/wanderers.gd), kinds `w_ghost`, `w_rival`, `w_traveller`. Hooks:
Game.room_cleared -> `on_room_clear` (after EventRooms; skipped when a drunk, inkling or merchant
came in; dice from floor, kills and run time: `_dice`, never the global RNG), Game.enter_room ->
`on_enter_room` (the traveller's object is made anew in each room from run_stats "traveller";
a boss room: `_arrive` pays a relic + gold; run_stats "rival_owes" brings the rival back as an
ally in the next fight), start_floor -> `on_floor_start`, on_death -> `on_death` (Meta "ghost":
floor, x, y, sprite, name, 40% gold), Combat.kill_enemy -> `on_kill` (a hostile rival: an
"outlaw" with a per-foe copy of `d`: the hero's sprite, x6 health, `rival`, `has_chest`;
Remains skips it), EventRooms.update -> `update`, interact / prompt (overlay_view) / draw
(world_view objects). The rival is struck by your shots or slashes (`_struck`); the traveller
by foe shots (`EBullets.take_near`) or foes touching them. Not in the camp or the daily trial.
Debug: `--wanderer`. `tests/wanderers_test`.
21.5: `Lives` (scripts/combat/lives.gd). Enemy fields `asleep`, `sleep_t` (a fire-dog: time at
play), `called`, `provoked`, `rally_t`, `play_cd`, `coins`. Hooks: Game.spawn_wave ->
`on_wave(new foes, first wave)` (combat rooms only; `uid % 3 == 1`, walkers, not elites, minis,
champions); Combat.update_enemies -> `override` (after Barks.flee: rally timer, sleep, greedy
slimes, mothlings at `_lamp`, fire-dog `_dog`, sootling `_soot`); Combat.damage_enemy -> a
sleeper takes x2 and wakes (before the +-15% roll), then `on_hurt` after the blow (provoked; one
foe in two by `uid % 2` calls below half health: wakes all within CALL_R, rallies its own type:
speed x RALLY, undone when rally_t runs out); kill_enemy -> `on_kill` (a slime's coins and gems
back); RoomDress.knock -> `lamp_down`; world_view `_draw_enemy` -> `draw` (Zz, coin glints);
Barks skips sleepers. `pop()`: a floating word without Fx.float_text's dice. No run dice rolled
by any of it. `tests/lives_test`.
21.6: `CampClock` (scripts/game/camp_clock.gd): `hour()` (force_hour for tests, --clock=H, else
the system clock), `phase()`; drawing in world_view: `paint_lower` (LANTERNS posts, fireflies,
stars and a moon in the pond at POND), `paint_tint` (start of the fx layer: over the people,
under the lights), `paint_glow` (lanterns, the cook fire, fireflies). RoomDress.tick lands
songbirds in the camp of a morning (`birds()`; `_land_t` set to 1 s on arrival). Ambience: the
camp's loop is `CampClock.loop()` ("campday": birdsong, made by sounds21.py `birds`/`chirp`).
Camp.enter -> `on_enter` (the gift `c_gift` by the cat; Meta "cat_gift" = the date it was
taken; routed through EventRooms KINDS/interact/prompt/draw), banner `greeting()`.
`tests/camp_clock_test`.
**Stage 21 done (8 Oct).** `tools/check.sh`: CHECK PASSED. The 6 classic replays identical; the 8
core replays re-recorded on purpose (50db7b3: 21.1, 21.4 and 21.5 change play) and reproduced
by the check. Timing against Stage 20 on the same seeded bot runs (this container, software
GL): logic 0.51 -> 0.58 ms, script drawing 0.71-0.78 -> 0.84-0.85 ms, render 4.0 -> 4.4-4.8 ms
(medians; a frame has 16.7 ms). IPA 21 (release ipa-21). Not tested on the iPad (no iPad, no
Mac here): the sound on the device and 60 fps there are his to try.
22.1: `Weather` (scripts/render/weather.gd): `on_floor_start` (Game.start_floor, before the
first room; own dice from floor, kills and run time; BY_FLOOR; CHANCE; floor 0 clear; `--weather`),
`here()` ("" in rifts, the camp, the barn, NEON LOOK), `sound()` (Ambience: rain, wind), `tick`
(world_view.refresh: rain/snow/ash `_air`, rain `_rings`, blast `_flashes`), `paint_floor`
(lower layer), `paint_air` (parts layer), `paint_eyes` (glow layer). NIGHT: the world_view layer
`dark` (between ents and fx) draws one rect with `Weather.SHADER` (up to MAX_LIGHTS lights
[x, y, r, strength] from `lights()`: lantern first, blasts, camp lanterns or wall torches,
winding-up and glowing foes, candles, fires, portals, chests, fire zones, bombs; 8 steps of
light). On a night floor the danger drawings (hazards, goo, rift-boss ground, chaos circles,
warnings, Afx ground) move from the lower layer to `_paint_danger` at the start of fx, over the
dark. `dark_level()`: DARK on a night floor, DARK_CAMP for the camp at night (CampClock's night
tint lightened). Storms use RoomDress's lightning; fog uses world_view `_paint_fog`. Combat
.explode_at -> `flash`. Warmup draws the dark shader once (dark 0). `tests/weather_test`.
22.2: `Endless` (scripts/game/endless.gd). Camp object `c_endless` (camp.gd: KINDS, setup at
(168, 80), interact sets `G.endless_next` and opens the heroes, prompt, draw; routed through the
EventRooms and world_view camp lists). Game.new_run -> `setup` (run_stats endless, chapter 4 for
every floor, best0) and clears `endless_next`; start_floor -> `on_floor` (depth, new_best, Meta
"endless_best") and the banner's `banner_sub`; on_boss_dead -> `guardian_down` (before the barn,
realm, rift and ending branches: chest + portal); the "portal" interact -> `next_floor` (past the
last floor: floor 0, loop + 1, the game's loop scaling); award_embers -> `score` (DEPTH in place
of FLOORS and LOOPS, NEW BEST DEPTH). HUD and end screen show the depth. Quests' "chapter" goal
is never met on the stair. main.gd: `--endless`; `--floor` counts from the top on the stair.
`tests/endless_test`.
22.3: `Bestiary` (scripts/game/bestiary.gd). Meta "seen" (Combat.spawn_enemy / spawn_boss ->
`seen`), "slain" (Combat.kill_enemy -> `slain`), "runs_log" (award_embers -> `log_run`, the last
LOG_MAX). `entries()`: every ENEMIES key but SKIP and every BOSSES key, ordered floor by floor
(pool, OLD_FLOOR_EXTRA, mini, guardian, ALT_GUARDIANS), then Themes, then the rest; `where`,
`name_of`, `line_of` (Barks FOE_BARKS / BOSS_LINES). The codex: Game `codex_tab` (ROLL cycles),
`bestiary_i`, `_grid_nav`; MenuView CODEX_TABS / CODEX_TAB_X (tab names at the top); taps.gd
taps on the names and the bestiary grid. Debug `--ui=codex|bestiary|runs`. `tests/bestiary_test`.
22.4 (in progress): heavy fight profile (tests/heavy_profile): 5.2 ms of logic a tick here, the
new foe lives (Lives.override) about 0.04 ms of it; drawing a night or storm floor adds 0.2-0.3 ms
of render time on this container's software GL. tools/dev/monkey.sh now also soaks the endless
stair, night and storm floors, the wanderers and Chapter IV.
Found by the soak: OPTIONS > KEYBOARD KEYS waited for "PRESS A KEY" until a keyboard key came, so
an iPad with no keyboard (and the soak, from minute 10 of its hour) was stuck there. Now a tap
(USE), BACK/MENU, or 8 s (Keys.CAPTURE_MAX) ends the wait (Game.update_keys; Keys.capture_t);
tests/keys_test covers both.
Then the soak, now really an hour of play, found the camp TINKER's prompt breaking on any gear
without a set (214 of 352 have "set": null; the line looked SETS[null] up): CampLife.prompt fixed,
camp_build_test asks it of every gear, and OverlayView.draw_prompt shows nothing for a failed
prompt instead of a second error. Endless.on_floor reads best0 with int() (a saved run's numbers
come back as fractions). Objects over the soak's hour: 3651 at 1 min, flat at about 4320 from 20
to 60 min (no leak); nodes 68 and resources 162 throughout.
A flaky check, found by the full run: vfx_test failed one run in four ("line 2: 36 vs 26", Fx.n
ten apart). Cause: 21.2's candelabra fall to a blast and throw 10 particles; the test runs each
blast twice (effects on, then off) and did not stand the props back up between the halves, and
whether one stood near the blast depended on the test room's layout. Now vfx_test puts a
candelabra by the blasts (it failed every run that way), `_restore` stands props up, and
RoomDress.knock seeds its dice from the prop's spot, so a prop always falls the same way.
**Stage 22 done (8 Oct).** `tools/check.sh`: CHECK PASSED on the final code; every replay identical
(the classic 6 and the core 8: Stage 22 changes no rules). Soak (tools/dev/monkey.sh 60 6): 16 of 16
runs clean, the hour included. IPA 22 (release ipa-22). Not tested on the iPad (no iPad, no Mac
here): the look of night floors, the sound of rain, and 60 fps there are his to try.

### Stage 23 THE SPELLBOOK (his word, 8 Oct: "Add more magic weapons with super cool effects")
23.1 (in progress). `scripts/combat/spells.gd`: ten new kinds of spell, each a weapon kind
(`Weapons.ARCH`, `ARCH_DESC`, `WeaponInfo.MAGIC` and `KIND_TYPE`, `Attributes.KIND`), hooked in
like the 4.6 kinds: `Combat.player_shoot` (fire), `Hazards.update` (tick), `world_view` (draw_floor,
draw_over, and a sheep drawn in a foe's place), `Game.enter_room` (clear).
  singularity  a mote that becomes a black hole: pulls foes, then collapses (+30% a foe it held).
               EVENT HORIZON also eats enemy shots (+10% each, 15 at most).
  serpent      a fire serpent hunts foes, its body burns, its tail leaves flames. RIME SERPENT: ice,
               and it coils round a foe to crush it.
  comet        warned by a line and a ring, a comet crosses the room through the aimed foe, then
               bursts. THE STARFALLEN: three, through three foes.
  glyph        a rune under the aimed foe erupts in a pillar that stuns; every 4th is great.
               SIGIL OF SUNDERING: each erupts twice, leaving foes vulnerable.
  blades       each cast a spectral blade that hunts on its own for 4 s (six at most).
               THE THOUSAND EDGES: every cut throws a wave of steel.
  chrono       a clock circle: ordinary foes in it are held still (a stun, kept up each tick),
               guardians only chilled; enemy shots in it hang; at the end the held foes take
               dmg x (1 + seconds held). HOURGLASS OF AEONS: the held shots fly back at foes.
  prism        a bolt that splits on a hit or a wall into red/blue/green bolts (burn, chill,
               poison) that split again. FRACTAL CROWN: a third time (48 alive at most).
  cloud        a storm cloud follows foes: lightning every 0.6 s, rain that chills (three at most).
               TEMPEST CORE: a tornado drags foes under it, and flings them when it ends.
  pinball      bounces foe to foe 6 times, x1.08 speed and +10% a bounce; a wall sends it back at
               the nearest foe. STARBOUND ORRERY: 10 bounces, each throws a seeking star.
  wild         a random spell a cast (fireball, ice, lightning, miasma, gold, sheep, heal at most
               every 20 s and only when hurt, a void, a smite). THE CHAOS CODEX: two at once.
               No gold from the training dummy.
+1 projectile stacks without limit (+35% damage each past the first; blades, comets and prism
bolts add one more first, to their caps). Twenty rows at the end of `Weapons.ROWS` (classic never
sees them). Icons: 12x12 in `tools/art/sprites.py` (look D, rendered and copied to
assets/graphics, atlas baked: 1741 graphics). `tests/spells_test` (in tools/check.sh): data, each
weapon's trick in a fight, +999 projectiles within caps (logic under 0.7 ms a tick here), stopped
time holds a foe still and only slows a champion, the sheep is squashed underfoot, one heal in 20 s,
no gold from the dummy. Damage a second in its fight (4 sturdy foes ahead; old weapons in the same
fight: commons 15-37, rares 6-29, epics 9-45, legends 5-97): pocket void 38, event horizon 112 (fed
6 enemy shots a second), ember wyrm 22, rime serpent 32, comet scepter 20, starfallen 62, rune
chalk 21, sundering 45, dancing steel 26, thousand edges 39, stopwatch 18, hourglass 50,
kaleidoscope 38, fractal crown 54, cloudherd 20, tempest 26, pinball 26, orrery 67, wild surge 34,
chaos codex 73. (First numbers were higher: the pinballs went from +15% to +10% a bounce and 6 or
10 bounces, the orrery's stars 40% to 30%, the event horizon +20% to +10% a shot eaten (15 at
most); sundering, kaleidoscope, fractal crown and wild surge were given less damage.)
content_test passes. Docs: ARSENAL.md part 5. 23.1 done.
23.2: replays before re-recording: the classic 6 identical; the core 8 identical but h, which
differs from 89 s: the bot picks up SANGUINE RING where it found the STEAM REPEATER, because the
rare pool has eight more weapons (the same roll lands on another). h re-recorded on purpose.
23.3 his recording (8 Oct, "We have a problem"): floor 12, level 52, 47 min, THE BLANK QUILL at
102 attacks/s, 12 shots, 3626% crit, two TWIN-SOUL RINGs; "31 FPS LOGIC 16.3 DRAW 3.4 CALLS 608";
the room under giant pink squares (orb_hexBig scaled by a shot's radius). After a pause and a ring
swap it read 60 fps, LOGIC 1.2: a quiet moment (nothing to shoot), not a fix.
  The giant squares were a bug: at the shot cap Combat._merge_shot returned the shot flying, and
  player_shoot's heavy x3/x1.5 (HEAVY BOLT heavy_n, nth_big), a lance's r/pierce/life, a dart's
  poison, a reflected spark's x/y, shatter lances' chill, a ricochet's crit and a fireball's tag
  were set on it, once per merged shot (15 a heavy attack): r reached 59000 px in the rebuild.
  Now (rogues only; classic keeps the old path) _merge_shot returns a stand-in PBullet (in no list,
  .merged = the shot flying, .dmg = its share). player_shoot: forced crit and "own" go to the shot
  flying as before; a heavy attack adds 2x each stand-in's share there (the share tripled), no size.
  Speed (tests/quill_profile.gd rebuilds his fight: 40 random relics, 41 trait ranks, his gear,
  --heavy adds HEAVY BOLT, --full times G.update, --secs=N; diagnosis only, not in check.sh):
  - Effects.fire: Player.proc_index (trigger -> its procs in order), emptied in add_proc and
    remove_procs; the same procs in the same order, so nothing else changes.
  - fire_projectiles: an attack that would only merge (room full, n > 1) merges in one step,
    rolling the same dice (2 or 3 randf a shot) so all that follows is identical.
  - Effects.pbullet_cap(): shots past twice their size (Weapons.wsize) get 300 * 2 / size, at
    least GIANT_PBULLET_CAP 120.
  - update_zones: past POISON_POOLS (80) poison pools the oldest go.
  - world_view: SHOT_DRAW_R 16 caps a shot's drawn radius (batch buffer, _draw_spec, plain kinds,
    glows). Remains.scorch: a blast within 0.2 s of the last marks waits (SCORCH_EVERY) and the
    floor layer is redrawn once for them.
  Six fights, old -> new code, 30 s each: 4.81->4.02, 7.35->4.86, 5.98->4.80, 8.43->5.56,
  6.72->5.55, 5.94->4.45 ms a tick (-26%); worst ticks 26-75 -> 15-40 ms. With --heavy:
  13.76 -> 10.66 ms, largest shot r 59002 -> 59. Found but left: hearts at full health and belt
  items with the belt full wait on the floor and pile up in a long fight (0.8 ms for 650 in the
  rebuild, where the hero stands still). tests/heavy_build_test (in check.sh) covers the fixes.
  Replays: all 14 identical.
  Pictures: two seeded runs of the same build differed from the first frame (the hero's first
  line): the decoration dice added in 21.1-22.1 (Barks, Remains, RoomDress, Weather, Quests,
  CampBuild, Snd._deco_dice) were not seeded with --seed like the older ones (main.gd). Now they
  are; a seeded run draws the same frames every time (0 of 420 differ). Old vs new code, 900
  frames, --seed=9 --hero=2 --bot --god, plain and with --weapon=dynamite: 0 frames differ.
  (tools/dev/cmpbuilds.sh still points at an old session's folders; the comparison was run by hand.)
**Stage 23 done (8 Oct).** tools/check.sh: CHECK PASSED on the final code; replays as in 23.2
above; soak 4 x 5 min (--monkey, spell weapons) clean. IPA 23 (release ipa-23). Not tested on the
iPad (no iPad, no Mac here): how the spells look and feel there, and whether his heavy build now
holds 60 fps (estimated LOGIC about 12 ms there, down from 16.3) are his to try.

### Stage 24 (his word, 9 Oct: nights too dark; armor sets repetitive)
24.1 weather.gd: DARK 0.8 -> 0.52, DARK_CAMP 0.5 -> 0.34, LANTERN 80 -> 108, the night colour
(0.02,0.02,0.07) -> (0.05,0.06,0.16), a moonlit blue; camp_clock.gd paint_tint evening 0.2 -> 0.16,
night 0.16 -> 0.12. Screenshots before/after: --weather=dark --room=combat and --ui=camp --clock=23.
24.2 gear.gd random_gear: CHASE_BASE 0.08 + CHASE_STEP 0.04 a worn piece (was 0.25 + 0.1); the
chase skips a set the last gear came from; the pool's pick is rolled again (REROLLS 4) while it
is a piece the hero owns (Gear.owns: worn or in the pack) or of the last gear's set
(G.run_stats["last_set"], kept per run). Rogues only (classic untouched). sets_test: 400 drops
with one piece worn: its set 42 times, never the worn piece, never two in a row from one set; a set
worn whole never drops in 300. Replays: classic identical; core e re-recorded on purpose.
IPA 24 built WITHOUT the full check (his word: skip it, low credits). Run tools/check.sh first
next session.

### Stage 25 (9 Oct): reactions, fourteen traits, nine magic and nine melee weapons
Built at his word WITHOUT tests ("dont test just compile"): only --import, bake_atlas (atlas test
passed) and 20 s bot runs with steamblade, serpentlash and stormfire (no errors). NEXT SESSION FIRST:
run tools/check.sh (content_test lints the new rows; spells_test and sets_test still apply) and
re-record the core replays with tools/replay.sh record (new weapons, traits and reactions change
the fights, on purpose); the classic replays must stay identical (all new code is rogues-only).
Reactions: scripts/combat/reactions.gd (check() from damage_enemy after a blow that leaves the foe
alive; clear() in G.enter_room; hooks react_dmg, react_fast). Rows: traits y_* at the end of
Traits.ROWS; weapons after "chaoscodex". Icons: recolours at the end of tools/art/sprites.py.

### Stage 26 (9 Oct): spells as item effects, reactions as a trigger, mythic traits, synergies
Only compiled at his word (import; two 30 s bot runs giving the new traits: no errors). NEXT
SESSION FIRST: tools/check.sh and tools/replay.sh record (as for Stage 25). New: Actions "spell"
["spell", kind, dmg_mult] -> Spells.cast(kind, p, x, y, dmg, skip_uid) (spells.gd, end); trigger
"on_reaction" fired by Reactions.check with { enemy, x, y, dmg }; hook react_avatar (reactions twice
as fast again); Traits.RARITY["mythic"] and Game._new_trait_weight (mythic: weight 1 from level 6).
Rows: traits l_* and m_* after y_catalyst; synergies t_steamengine..t_reactor at the end.

### Stage 27 (9 Oct): MYTHIC items
"mythic" rarity: GameData.RARITY_COL/HEX/NAME, Game.item_price (140), EventRooms.PAWN_PRICE (120),
Gear.roll_item_rarity (rogues: boss 8, elite 3, drops max(0, floor - 5)), Attributes.scaling and
world_view's hand glow treat it as legend. Rows: weapons after "steamblade", gear at the end of
Gear.ROWS. Only compiled (see the top of this file); the full check and replay re-record wait.

### Stage 28 (9 Oct): version names
`scripts/data/versions.gd` (class Versions): one line a version, newest first,
"number|Name|tweak; tweak" (no quote or | inside). The title screen draws `Versions.label()` in its
bottom right corner (menu_view.gd, dim). `tools/versions.sh name|notes|newest|all` reads the list
with plain awk; the IPA workflow uses it: the version step stops the build if VERSION has no line
or is not the top one, sets NAME and IPA (TinyBiggot-<V>-<Name>.ipa); the publish step titles the
release "Tiny Biggot Rogues <V>: <Name>" with the tweaks as notes, then renames every older
`ipa-*` release whose title lacks its name (tweaks put over its old notes from their "Version"
line; done once, already named ones are skipped). The rename loop was tried here with a stand-in
gh. No rule changed: replays untouched. IPA 28 built; all 39 releases named.

### Stage 29 (9 Oct): oaths, better picks, 54 traits, full hidden rooms
- Hidden rooms: `G._fill_secret(r, cx, cy, roll)` (expanded game; classic keeps its old fill and
  dice). The object `grimoire` (drawn as the tome, a white glow; prompt GOLDEN GRIMOIRE) gives
  `p.special_picks += 1; p.pending += 1`.
- Picks: `Player.oath_picks` / `special_picks` (saved with the run like every player value).
  `G.offer_traits` has a mode ("oath", "special", ""), kept in `tchoice["mode"]`;
  `G._special_weight` weighs those picks; `take_trait` spends the pick when the trait came from
  the offer. `new_run` gives the oath (expanded game). The pick gate in `update_play` ignores the
  start room's dummy and target (`_only_dummies`, expanded game). TraitView titles: SWEAR AN OATH
  FOR THIS RUN / THE GRIMOIRE: A RARE TRAIT; an oath's box is orange. Rarity "oath" in
  Traits.RARITY (weight 0 in ordinary picks).
- Rows: after "m_serpentking" in Traits.ROWS (o_* oaths, n_* the rest).
- Not run (his word): tools/check.sh. Watch for tests that start a run and expect no pick
  pending (a new run of the expanded game now has one: the oath), `--ui=traits` (shows the oath
  pick first), and content_test's text-fit check on the new rows.

### Stage 30 (9 Oct): oath vows, the trait book
- `Oaths.VOWS` (scripts/data/oaths.gd): id -> [goal, vow, HUD label, count proc, awakened text,
  awakened effects]. `G.take_trait` calls `Oaths.sworn` for an oath: `p.vows[id] = 0` and a count
  proc (src "vow:<id>") whose "do" is the new action ["vow", id] (Effects.ACTIONS, actions.gd)
  -> `Oaths.progress`. At the goal: `p.vows_done[id]`, the awakened effects applied (src
  "vow:<id>:awake"), banner OATH AWAKENED!. Counts that follow the oath's own strikes copy its
  proc's trigger, "every", "cd" and "period" so the two keep step. HUD lines under the map
  (hud_view, y 50). Pick rows show "VOW: ... TO AWAKEN IT" (trait_view).
- `TraitBook` (scripts/render/trait_book.gd): codex tab 3 (MenuView.CODEX_TABS, tab x moved to fit
  four; taps 100 wide). Meta "traits_seen" (set by G.offer_traits) and "traits_taken" (count, set
  by G.take_trait), made on first use with get_or_add. `G.traitbook_i`.
- New test `tests/oaths_test.tscn`, in check.sh after the heavy build test. It passes.

### Stage 31 (9 Oct): the toybox
- `Toys` (scripts/combat/toys.gd), built like `Spells`: `handles`/`fire` (Combat.player_shoot),
  `tick` (Hazards.update), `clear` (G.enter_room), `draw_floor`/`draw_over` (world_view), `cast`
  (the action "toy": shark, twister, disco, portal, saw, pin, anvil), POWER (Weapons.weapon_dps).
  Kinds in Weapons.ARCH / ARCH_DESC, WeaponInfo.MAGIC (twister, disco, voodoo) and KIND_TYPE,
  Attributes.KIND. Twists are keys on the row (frenzy, sharks, party, twin, rift, magnet, doom,
  piano).
- Voodoo: `Combat.damage_enemy` calls `Toys.shared(e, dmg)` while any foe is pinned (guarded
  against recursion; the shares skip crits and the damage multipliers). Pins only exist in the
  expanded game, so classic never reaches it.
- Twisters move held foes (not guardians, minis, champions) only onto walkable floor
  (`World.M_WALKER`). Anvils remove enemy shots near them with `EBullets.take_near`.
- Rows: after "voidhammer" in Weapons.ROWS. Icons: end of tools/art/sprites.py (render with the
  scratchpad's icons script: `all_for("D")`, then copy `w_*.png` to assets/graphics, import,
  bake). New test `tests/toys_test.tscn` in check.sh.

### Stage 32 (9 Oct): performance and stability check (his word: "now do performance and stability check and update it")
Done by another session (the port's), which took over from v31 on claude/dev.
- 32.1 The full check after Stages 24-31 (they were only compiled) found 18 failures; all fixed.
  Item data: HEART OF THE PHOENIX had slot "amulet" (unknown: never wearable), now "neck";
  SKYBREAKER ORB's text had a ';'; the Stage 31 weapon id `voodoodoll` clashed with the trinket
  of that id: the weapon is now `stitcheddoll` (icon renamed, tools/art/sprites.py too, atlas
  baked); the Stage 26 trait STARCALLER shared a weapon's name: COMET CALLER. Rules: common SUPER
  traits come from level 2 again (Stage 29 dropped that gate by accident). Trait cards: a found
  hidden combo whose partner is a weapon (Stage 26) names the weapon and shows COMBO READY while
  you hold it (trait_view). Tests: the Stage 29 OATH pick that opens every run stopped seven
  older tests (they waited on the pick screen); they now start past it, and combos_test accepts
  a trait paired with a weapon.
- 32.2 Speed. (a) `Combat._volley_full`: a volley with very many projectiles (the arsenal test's
  +999) that fills the shot cap part-way merges the rest at once (they merged one by one, each
  making a stand-in object: 700 in one tick, a 50 ms stall). Dice still rolled, so the same
  game. Arsenal +999: 3.7 -> 1.2 ms a tick, worst 50 -> 12 ms. (b) THE FLOOR BAKE (world_view
  `_bake`, `_floor`): the tiles and the remains and scorch marks are drawn into a 448x288
  picture, again only on dyn_dirty or a room change, and the bg layer shows it. In GL
  Compatibility every circle or polygon is a draw call of its own and each change between rects
  and lines/primitives breaks a batch (measured: 200 rects or lines = 1 call, 200 circles = 200);
  remains are circles, lines and dots, ~255 of a heavy fight's ~465 calls. The tiles are their
  own picture inside the bake, drawn once on entering the room, as bg was (some of what _paint_bg
  reads changes in a fight: redrawing it later changed pixels). Median draw calls: heavy fight
  461 -> 212, ordinary fight 79 -> 54; 3601 frames of a seeded run byte for byte identical with
  and without (`--no-floor-bake`). Tools: `--calls-probe[=TICK]` (freezes the scene, prints the
  draw calls each world layer costs), `tests/shot_stress_profile.tscn`, heavy_profile lists its
  slowest ticks by section. Heavy profile (40 relics, 14 sturdy foes): 6.2-6.9 ms a tick here;
  its slow ticks (14-17 ms) are the build's own on-hit procs when 10+ shots land at once (chains,
  explosions, on_hit/on_crit effects): the chaos itself, left as it is.
  The sprite atlas is 1024x4096 but only 56% used (power-of-two height): room for ~1500 more.
- 32.3 Stability: tools/dev/soak.sh now runs every hero (30); 49 runs (5 min each, all heroes,
  11 rift worlds, classic, plain drawing, loops 1-3, weapon cycling) with 0 errors. Monkey soak
  (tools/dev/monkey.sh 40 4): 16 runs, 0 errors; objects 3748 -> 4372 over 40 minutes in steps
  with long flat stretches (pools and caches filling as new content shows up), nodes and
  resources flat: no leak.
- 32.4 Core replays re-recorded on purpose (Stages 24-31 change every fight: oaths, traits,
  weapons, reactions, hidden rooms); the classic set identical. tools/check.sh: CHECK PASSED.
  VERSION 32 "Steady and Sound", IPA 32.

### Stage 33 (9 Oct): build paths I (his word: four builds "and this is how the game needs to feel")
- 33.1 THE MIND FIELD. `Auras` (scripts/combat/auras.gd): halos are gf stats `halo_<kind>` (burn,
  chill, poison, shock, gravity, sun, mind, wither, mist) pulsed by `Auras.tick` (from
  Combat.update_player, only while foes are up); reach = 1 + (2% + aura_int) per INT +
  aura_reach (cap x6), times the MIND SPIRAL surge (action "aura_surge"); hits x (1 + aura_dmg +
  aura_int_dmg per INT); aura_strike makes every pulse hit; aura_speed pulses faster. The six
  halo relics became stats (they were every_n_seconds procs); new WITHERING VEIL, BLOOD HAZE
  (bleed; kills in it may heal: Auras.on_kill) and HORIZON RING (moons at the field's edge,
  bigger and harder: orbit_radius, moon_scale, moon_dmg). The Ember Heart aura grows with reach.
  Fields drawn by `Auras.draw` in the vfx layer (a faint disc, a rim, turning marks). New stats
  are gf, so items use ["hook", stat, v] ("add" only works on Player properties). Traits k_*
  (INNER LIGHT, WIDE THOUGHTS, STILL MIND, DEEP WELL, HUMMING FIELD, OVERMIND). Hero THE
  MINDWARDEN (index 30, THOUGHTSTONE, [0,1,6], branch THE STILL FIELD, special MIND SPIRAL).
  Art: tools/art/stage33_icons.py (recoloured halo icons, the Horizon Ring grid, and the hero and
  staff grids from sprites.py rendered in look D). Test tests/auras_test.tscn (in check.sh).
- 33.2 THE TAVERN. `Tipsy` (scripts/combat/tipsy.gd): Player.tipsy (stacks) and tipsy_t; each
  stack x1.06 damage (Weapons.wdmg) and x1.04 rate (Weapons.wrate), compounding; cap 8 +
  tipsy_cap; a stack off every 12 s x (1 + tipsy_slow); a drink adds n + tipsy_gain. Drinks
  c_ale / c_stout / c_mead (Consumables, PICKUP_KINDS, world_view PICKUP_SPRITE); Saloon.drink
  adds 2. SURE STRIKE (gf sure_strike) in Combat.damage_enemy: no crit, x(1 + 1.5 x crit chance);
  crit_per_str and rate_per_str (the Tavern Knight); heart_dmg in hook_mult (BIG APPETITE).
  Conditions "tipsy", "very_tipsy" (8+); actions "tipsy", "belt". Traits j_*. Hero THE TAVERN
  KNIGHT (index 31, TANKARD MAUL, [6,1,0], THE TAPROOM, BAR FIGHT). HUD: TIPSY n beside the belt;
  the hero sways a little (drawing only). Test tests/tavern_test.tscn (in check.sh).
- 33.3 Fixes from his report: Lives._greed (greed_hp, growth capped with the size) and
  EBullets.update (the crate check past the room's edge; unit test _test_shots_off_the_edge).
  Diagnosis tools kept: tests/elite_probe.tscn (every early foe as an elite with each trait vs a
  starting hero) and tests/elite_probe2.tscn (the bot plays every hero; elites alive past 40 s).
  Core replays re-recorded (new content and the slime fix); classic identical.

### Stage 34 (9 Oct): build paths II
- 34.1 THE TRIGGER PATH. `Lucky` (scripts/combat/lucky.gd), called at the end of
  Combat.on_hit_effects: chance = gf lucky + lucky_dex x DEX (+1 during TRICK SHOT's rush_t); a
  lucky hit strikes again (damage_enemy, no on_hit) and fires the new trigger on_lucky. gf
  slot_cast: crits and lucky hits cast the first backpack weapon (CASTABLE kinds or the
  spellbook) via Combat.player_shoot with p.weapon swapped for the cast; new shots get
  PBullet.cast (never cast again) and x(1 + slot_dmg); at most 2 casts a tick, 0.12 s apart.
  STATIC BUILD-UP (gf static_buildup): Statuses "shock" at SHOCK_MAX calls Lucky.on_shock
  (lightning to 4 foes). rate_per_dex in Weapons.wrate. Actions slot_cast, lucky_rush. Traits q_*
  (CHARMED LIFE, LUCKY STARS, SPELLSLINGER, STATIC BUILD-UP, QUICK FINGERS, JACKPOT), relic
  WISHBONE. Hero THE TRICKSHOT (index 32; QUICKSILVER CROSSBOW; [1,6,1]; "pack": runechalk, a
  new hero field read in Game.new_run; SLEIGHT OF HAND; special TRICK SHOT). Test
  tests/trigger_test.tscn (in check.sh).
- 34.2 THE LEGION PATH. `Legion` (scripts/combat/legion.gd): gf minion_dmg, minion_speed, march
  (x % of extra move speed: p.speed against hero["speed"]) and minion_cap. Wisps:
  Combat.update_familiars (cap, cd, damage); Actions "summon" (cap). Thralls and turrets:
  Summons._tick_turrets / _tick_thralls take the damage once (Legion.boost, the "lg" key) and
  count cd down x Legion.speed; item_raise, item_turret and on_kill caps + minion_cap. Pets:
  Pets.update cd and damage. Traits h_* (BONE CALL, QUICK MARCH, GRAVE MARSHAL, BONE BEACON,
  ENDLESS RANKS), gear MARCHING BOOTS. Hero THE BONECALLER (index 33; BONE CENSER, a "thrall"
  weapon; [1,1,5]; THE BONEYARD; special ARMY OF BONES; every room entered raises 2 skeletons).
  Art in tools/art/stage33_icons.py (tint() for the boots). Test tests/legion_test.tscn.
  Core replays re-recorded for Stage 34; classic identical. IPA 34.

### Stage 35 (9 Oct): the feel
- 35.1 DICE. `Dice` (scripts/game/dice.gd). Counts: REROLL is the old Player.rerolls (still 2 at
  the start; with none left a reroll costs gold, Game.reroll_cost), plus new Player.alters and
  banishes (1 each at an expanded run's start, Dice.start) and Player.banished (ids gone for the
  run). Trait pick: Game.update_traits calls Dice.on_traits (HEAL = alter the chosen row, BOMB =
  banish it; MENU still rerolls and spends a REROLL die); Game.trait_cands (new, used by
  offer_traits) skips banished traits. Relic choice: Game.update_choice calls Dice.on_choice
  (MENU / HEAL / BOMB); Game.roll_relics takes `exclude` ids and skips banished relics; choice
  stores its "source". Backpack: Dice.on_inventory (HEAL / BOMB on the chosen item;
  Dice.changed_item: same rarity weapon keeping its anvil +N, or gear for the same slot).
  Weapons.random_weapon, Gear.random_gear and Gear.chase_piece skip banished ids. Shops (expanded):
  a die for sale (shop item "die") and the DICE CUP object (Dice.handles / interact / prompt /
  draw): a REROLL die (or the gold price) restocks every relic, weapon, gear and die on sale.
  Found: elites 12%, chests 25% (iron 40%, cursed 60%, boss 100%), cleared fights 6%, guardians
  2, hidden rooms 50% (Dice.maybe, x(1 + gf dice_find)); pickups die_reroll/alter/banish. Under
  every pick and in the backpack: chips with the dice and their counts (Dice.draw_chips; tap zones
  in taps.gd send the same actions); HUD shows the three counts (and they are in the HUD's
  redraw signature). A row a die changed shines (tchoice/choice "alt"). Trigger on_dice, action
  ["dice", kind|"any", n], gf dice_back (FIXED ODDS). Traits d_* (HOUSE RULES, FIXED ODDS, HIGH
  ROLLER), relics GAMBLER'S POUCH and KNUCKLEBONES; keywords REROLL, ALTER, BANISH, DICE. Art in
  tools/art/stage33_icons.py (die()). `--no-oath` (debug): no opening oath pick (pictures).
  Test tests/dice_test.tscn (in check.sh). Core replays re-recorded; classic identical.
- 35.2 PACE. Measured first: `--pace-log` (scripts/debug_pace.gd) prints how each fight room's
  time went (start, fight, waits between waves, tail = the last one or two foes, after = clear
  to exit) and the times of the level-ups, with the bot (use --unlock-all, or the bot stops at
  the hero select after a death with a locked hero). Before: start 0.5 s, waits ~0.1 s, tail
  1.6-4.3 s a room (up to 19 s in elite rooms), after ~2 s. `Pace` (scripts/game/pace.gd),
  expanded only: wave gate 2 foes (Game.update_play; was 1) and gap 0.35 s (was 0.6); spawn
  time 0.55 s (Combat.spawn_enemy and the rising ring in world_view; was 0.75); FINISH THEM
  (Pace.tick from update_play: last wave at 1-2 foes for 2 s: Weapons.wdmg x1.3, Player walk
  x1.15 via Pace.speed_mult, red arrows over them drawn in the top layer, a toast); CLEAR RUSH
  (Pace.on_clear from room_cleared: walk x1.35 until the room changes, Pace.on_enter); FIRST
  SPOILS (run_stats "fights": the first cleared fight of a run leaves an old chest, the second a
  rare-or-better weapon or gear piece; not in rift rooms). A/B with --smart-bot, 3 heroes x 6 min,
  same seeds: rooms 43 -> 47, fight 14.5 -> 11.8 s, tail 4.8 -> 2.7 s a room (single runs:
  rough). Test tests/pace_test.tscn (in check.sh). Core replays re-recorded; classic identical.
- 35.3 CLARITY (drawing only). world_view: the foe layer `ebul` (painter `_paint_foe`) is now the
  last world layer, after texts: Afx.draw_marks (aiming lines, beams), Hazards.draw_marks
  (warning rings) and EnemyAI2.draw_marks moved there from _paint_fx, then EBullets.draw. So foe
  warnings and shots are over your shots, vfx, glows, sparks, swings, the vignette, the fog and
  the floating numbers. The hero's body (`_draw_player`) is drawn in the top layer (over your own
  effects; the trail ghosts and the pet stay in ents), with `_draw_hero_mark`: a light ring with
  a dark edge at the feet (brighter when Fx.n + shots > 90). Foe shots use rimmed copies
  ebr_<kind> / orbr_<kind> (tools/art/shot_rims.py: a soft dark rim, #140f1c at 150/255, one
  pixel outside each frame's outline; the originals stay). Draw calls in a busy bench fight:
  59 -> 61. Pictures compared before/after (the hero shows through its own effect cloud).
- 35.4 The full check after 35.1-35.3: one failure, the realms test's Unwritten never showed
  LASER X and HELLGATE. Not a broken boss: its 13 moves take up to 38 s and the test watched 40 s,
  so the faster foe spawns of 35.2 (a different timing earlier in the test) left the last two
  just outside. A probe of the fight alone gave the same attack order with 0.55 s and 0.75 s
  spawns. The test now watches 4 s a move, 40 s at least (tests/realms_test.gd _fight). Every
  replay identical. VERSION 35 "Dice and Pace", IPA 35.

### Stage 36 (9 Oct): food and drink (his word: "Ideas for sprites for new stuff, and new stuff to add")
- `Food` (scripts/game/food.gd), expanded only. FOOD (10, f_*): pickups (Food.is_kind in
  Combat.update_pickups; drawn in world_view with a short label over them, Food.LABEL; labels
  that would overlap stack up, Food.labels cleared each frame): Effects (attributes; the WHEEL OF
  CHEESE is gf drink_slots) and XP = 12% of the next level (golden 35%) x (1 + gf food_xp).
  Sources: room reward "food" (World.roll_reward via Food.reward_weights, expanded only;
  GameData.REWARDS icon f_drumstick; Game.give_reward -> Food.reward: 2-3 foods), a shop ware
  (shop item "food", Food.stock_shop at cx+144, cy+34), elites 10% (Combat.kill_enemy).
  GOLDEN FOOD (10, gf_*): reward "golden" from floor index 8 (Food.GOLDEN_FLOOR), hidden rooms
  30% (_fill_secret), the blood altar 30%; each a lasting bonus: new gf hooks nocrit_dmg
  (Combat.damage_enemy, hits that do not crit; SURE STRIKE hits count) and proc_dmg (Actions.run's
  w: items' effects), plus lucky, minion_dmg, crit, crit_mult, rate, max_hp, attributes.
  DRINK BUFFS: every drink (Consumables.use -> Food.drink) also gives a buff of its own
  (Food.DRINKS: ALE +10% damage, STOUT +15 thorns, MEAD 10% burn, CIDER +10% rate, GROG +10%
  walk, PLUM WINE +5% crit) for 10 rooms (Food.on_room from Game.enter_room), at most 3 + gf
  drink_slots (the oldest is pushed out); Player.drinks [kind, rooms, src] and drink_n; effects
  applied with src "drink:<n>" and taken off with dir -1. Three new drinks c_cider, c_grog,
  c_wine (Consumables, PICKUP_KINDS, PICKUP_SPRITE). HUD: mugs with rooms left under the belt
  (in the redraw signature). Traits HOLLOW LEG (gf drink_forever, +1 slot) and GOURMAND (food_xp,
  food_heal); relics PICNIC BASKET (two foods every floor: action "drop" now takes "food" and
  "golden") and GOLDEN SPOON (a guardian kill leaves golden food). Art: tools/art/stage36_food.py
  (ART_OUT= for a preview). Debug: --give=drink:c_ale (its buff) and --give=food:f_bread (on the
  first room's floor). Test tests/food_test.tscn (in check.sh).

### Stage 37 (9 Oct): offhands and charms (his pictures)
- 37.1 THE OFFHAND: a ninth gear slot "offhand" (Gear.NEW_SLOTS, ITEM_SLOTS, SLOT_NAME), so it
  is expanded only (Gear.slots() leaves it out under --classic). 27 rows o_* at the end of
  Gear.ROWS (they drop, sell and roll like any gear). The backpack screen draws it beside the
  weapon (the weapon card is 84 px narrower), the other eight stay in the grid; HeroGear paints
  it on the hero's off side (OFFHAND pattern, last in ORDER). `Block` (scripts/combat/block.gd):
  gf block_rate (blocks per 10 s), block_chance, block_reflect (5 shards x150%), block_spikes
  (8 spikes); Block.tick from Combat.update_player, Block.stop in Combat._hurt_player_base after
  dodges and before the old buckler and armor; a small shield over the hero while one is ready
  (world_view top layer); Block.reset in new_run. Lanterns use the 33.1 halos (halo_burn,
  halo_wither, halo_sun) and aura_reach; tomes, flasks, the bell, the lute, the skull use procs.
  Art tools/art/stage37_offhand.py. Test tests/offhand_test.tscn (in check.sh).
- 37.2 CHARMS: `Charms` (scripts/data/charms.gd), 30 tokens (ch_*, a coin on a string with a
  symbol: tools/art/stage37_charms.py), items {"item": "charm"} worn in Player.charms, 3 slots +
  gf charm_slots (max 6; COLLECTOR trait, CHARM BRACELET relic). Effects through
  Effects.apply_equipment with "charm:<id>" (all reversible). Picked up from the floor
  (Game.interact "item") into a free slot or the backpack; a shop ware (shop item "charm" with
  "thing", at cx-144); chests 20-60% (open_choice), elites 6%. Backpack screen: a charm row after
  the belt (inv_i 10+; MenuView.inv_slot_rect, INV_CHARM_X; taps too); USE on a backpack charm
  wears it (all taken: a toast), USE on a worn one takes it off into the backpack, ROLL drops it.
  Item card line "CHARM - WORN IN A CHARM SLOT (n/m)", "PRESS USE TO WEAR". Dice ALTER/BANISH
  work on backpack charms. Debug --give=charm:<id>. Test tests/charms_test.tscn (in check.sh).

### Stage 38 (9 Oct): alignment and loot (his notes)
- 38.1 Alignment revamp (scripts/game/alignments.gd, the part under "38.1"): the four counts
  never cancelled each other (8.1 kept them apart) and still do not. New: Alignments.path: 3+
  GOOD over EVIL opens Heaven, 3+ EVIL over GOOD opens Hell, else the items decide (Soul.realm
  asks it first). Vendor prices: Game.price(v, al) and item_price(item, al) x price_mult (x0.7
  when yours matches, more of it than its opposite; x1.4 when the opposite leads you); vendors:
  saloon barkeep CHAOTIC, saloon merchant GOOD, pit boss CHAOTIC, mechanic and attendant LAWFUL,
  pawnbroker's sealed box and cup man EVIL, lost merchant GOOD (the regular shop has none);
  their prompts end with price_note "(EVIL: CHEAPER)". HERO_START: 23 heroes start with 1-2 of
  one. WAYSHRINE after every guardian (Game.on_boss_dead -> Alignments.wayshrine): offerings
  "alwayshrine" (drawn like the rest-stop shrines with a price), LAWFUL and CHAOTIC always, GOOD
  once Meta heaven_wins > 0, EVIL once hell_wins > 0; buying refreshes a soul gate in the room.
  Gear SAINT'S SIGIL (dmg_per_good, Weapons.wdmg), DEVIL'S BARGAIN (crit_per_evil,
  Combat.damage_enemy), MAGISTRATE'S SEAL (rate_per_law, Weapons.wrate), MADCAP'S BELLS
  (proc_per_chaos, Actions.run's w).
- 38.2 Loot (scripts/game/loot.gd): LUCK +2% lucky hits a point (Lucky.LUCK_LUCKY); gf
  magic_find multiplies the weights above common in Gear.roll_item_rarity; gf treasure_find is
  the chance of one more item (weapon 40%, gear 40%, charm 20%) from a cleared fight
  (room_cleared) or an opened chest (open_choice), over 100% one for sure. Shown as MAGIC FIND
  and TREASURE in the backpack screen's stats. PROSPECTOR (trait), JEWELER'S LOUPE (relic),
  DOWSING ROD (offhand). Art tools/art/stage38_icons.py. Test tests/alignloot_test.tscn.
- 38.3 (a soft cap on attribute damage) is NOT done: it would lower damage of big builds (rule
  1). Asked him; until he says yes, nothing changes there.

### Stage 39 (9 Oct): more to find (his pictures)
- 39.1 32 helmets and body armours (scripts/data/gear.gd, the rows under "39.1", before
  "firststar"): 16 head, 16 body, plain gear rows (stats, hooks, attr effects, a few procs).
  Four first ids clashed with older pieces (hornedhelm, travelcloak, monkrobe, berserkerhide):
  renamed BULL HELM, WANDERER'S CAPE, SAFFRON ROBE, WOLF PELT; the old ones and their pictures
  are as they were.
- 39.2 21 magic weapons (scripts/data/weapons.gd, under "39.2", before "thoughtstone"): kinds
  orb, zap, rail, pulse, wave, beam, flame, nova and swarm; every one scales with INT first (the
  RIME WAND, a rail, has an explicit "scaling" so it is not DEX). Two ids clashed and were renamed
  RIME WAND and BEADS OF DAWN (the old ICICLE WAND and PRAYER BEADS are untouched).
- 39.3 15 companions (scripts/data/relics.gd, under "39.3", before "jewelersloupe"): wisps
  (familiars, fam_dmg), a moon, item turrets and a raised skeleton and two ravens on entering a
  fight, bees from kills, a healing sprite, a fire-breathing egg, and minion_cap, minion_dmg,
  minion_speed (legion.gd). New condition "fight_room" (Effects._cond: G.locked): on_room_enter
  runs before a fight's foes are out, so "fighting" was always false there.
- Art tools/art/stage39_items.py (68 pictures, 12 px each). Test tests/stage39_test.tscn.

### 39.4 (9 Oct): bosses fall (his video, 18:20)
- What the video showed: floor 8, THE IRON CAPTAIN (Ashen Warfront's mini-boss) at 66% for the
  whole clip, a block of gold numbers on it, his build ~25 shots a second x 8, crit 314%, many
  stuns (FREEZE!, CHIME STAFF...). "WORST 4634" on the speed line: the clip's first half second
  is a still frame (the phone's recording banner), so that was the recording starting, not the game.
- Cause: Stages.gate holds a staged foe at its next stage line until it breaks into that stage;
  the break runs in its turn (Stages.tick for minis and rift guardians, BossAI.update_boss for
  floor guardians, RiftBosses.update for a rift guardian's second phase), and
  Combat.update_enemies skipped the turn of a stunned foe. Stunned on every hit: never broke.
- Fix: Stages.held(e) (held at its line, or in a stage break, or a rift guardian's "phase"):
  update_enemies lets such a foe take its turn while stunned. Classic: held() is false.
- Combat.damage_enemy no longer adds a blow on a foe held at its line to run_stats "dealt" (it took
  nothing off, yet fed Combat.power and so power_scale: every foe after it got tougher).
- Fx.hit_text (expanded game): a foe's hits of one colour in the first 0.3 s of its newest number
  add up in it (Enemy.num); FloatTexts redraws a number whose text changed. The nudge roll is
  made as before, so the game's dice are unchanged; classic keeps Fx.float_text.
- Test tests/stunlock_test.tscn (in check.sh): four staged foes stunned every tick and hit hard
  all die (4.6 to 7.4 s), a stun still holds a foe above its line, held blows count nothing, and
  100 hits in a moment make one number. Classic replays identical. Core replays re-recorded on
  purpose after the 39.4 build (Stage 39's new items and this fix; they matched at 38).

### Stage 40 (10 Oct): the trait look and the STRENGTH traits (his pictures)
- 40.0 Attributes.PER_POINT 0.05 (was 0.03; no cap), Lucky.LUCK_LUCKY 0.05 (was 0.02); the STR,
  DEX, INT and LUCK keyword texts say so.
- 40.1 TraitView._row: box and name in the group colour (GROUP_HEX/GROUP_COL by
  Attributes.FAMILY_ATTR; super red); a trait with a picture tr_<id> (16 x 16 white shape) has it
  drawn with a solid tint in that colour, else the family glyph. Debug --trait-opts=id,id,id.
- 40.2 scripts/combat/might.gd (class Might): power (gf power, war_charge, crowd), crushing hits
  (crush, resolute, crush_next; x1.5 and weak plate wear), rage (seething), puncture, instability,
  pride (on_taunt from taming, puppets, LOOMING THREAT), courage (opening), special speed
  (special_haste, special_str, honest) and on_special (Might.cast in Abilities.use, casting flag for
  MERCILESS), buff power (presence), stride, steady, giant_grip, heavy_draw, focus_str (Attributes
  .value), lucky_heart, drink_double, fire_blood stacks (Enemy.burn_n, bleed_n), open_wounds,
  moon_gloom. Enemy fields puncture, punct_t, instab, burn_n, bleed_n, dot_cd, taunt_cd. All 1.0
  or off in classic.
- 40.3 38 str_ traits (traits.gd, after the 38.x rows), names checked against every other name in
  scripts; pictures tools/art/stage40_traits.py. Test tests/stage40_test.tscn (in check.sh).

### Stage 41 (10 Oct): the DEXTERITY traits (his pictures)
- scripts/combat/finesse.gd (class Finesse): lethal hits (x2, or crit damage with lethality, on a
  foe under half health: lethal chance, sharpshooter from afar, cheap_shot on lucky hits; Lucky's
  extra strike carries o.lucky), close (ballistics: bows and guns always close; Might.close and the
  "close" condition use it), rate_mult (agility, alacrity, influence, spellblade), recharge_add
  (dynamo), special_power (special_per_roll; applied while Might.casting), helper_mult (bff in
  Legion.dmg_mult) and helper_speed (influence), tick_rate (clockwork; burn, bleed and poison
  ticks), crit_chance (crit_dex_rank, toxin_crit) and crit_add (shock_critdmg, illusion), tally
  (crit_next sure crits), repeats (two_steps: volleys with mult 2, Finesse.shot_mult in wdmg;
  repeat_debuff doubles statuses 4 s after any repeat), exit (on roll: refresh and tick DoTs),
  swagger (roll effects every 4 s), blood_poison, boom_vuln (explode_at), moon_rupture.
- New: actions lob and status_weakest, effect op pet (Pets.give or +1 level), Might.crushing(p, e)
  for point_blank, Actions w x 1.1^plus (proc_per_plus), Might.buff_mult adds buff_power.
- 38 dex_ traits (names checked), pictures tools/art/stage41_traits.py, test
  tests/stage41_test.tscn (in check.sh); the content test knows the pet op.
- 41.3 (his ask: "cubes around the trait sprites"): TraitView.cube(ci, x, y, tr, z, a, sel, known)
  draws a trait's picture (or its family glyph, a size up) in a square frame of its colour, 20 px a
  side at z 1 (1 px frame, 1 px gap, 16 px picture). Used by TraitView._row (40 px), TraitBook's
  detail panel and the new TraitPage (scripts/render/trait_page.gd): the pause menu's TRAITS page
  in the expanded game, a 6 x 4 grid of cubes that scrolls by rows (G.traitlist_i; game.gd's
  _grid_nav; taps.gd act zones, a tap elsewhere still goes back). Classic keeps the old text page.
- Core replays re-recorded on purpose for the new traits (e6361b1); classic identical.

### Stage 41.5 (10 Oct): how traits work (his wiki text; asked, he chose a limit of 12)
- scripts/game/trait_rules.gd (class TraitRules), expanded game only:
  - THE LIMIT: CAP 12 different traits (counted(p): p.traits without oaths). allowed(p, t) is
    checked by G.trait_weight and G._special_weight: with 12, only your own traits (rank-ups);
    oaths pass. G.offer_traits fills a pick of fewer than 3 rows with stat_rows(p) (pseudo-traits
    with a "stat" key, never in p.traits, pictures tr_stat_str/dex/int from
    tools/art/stage41_5_stats.py); G.take_trait hands them to take_stat (+1 attribute).
  - NEEDS: shield (Block.on), ranged (Might.ranged), pierce/slash (Might.cut), blunt, dexw.
  - TOMES: object kind "ttome" { trait, price? } (world_view draws the book and the trait's cube
    over it, a name plate; overlay_view's prompt). roll_tome uses G._new_trait_weight, ignoring
    the limit. Placed by place_tome: chests (maybe_drop, 12%), every expanded shop (cx - 144,
    cy + 34, for gold), the library room. interact opens state &"tome" (G.tome, G.tome_i):
    TraitRules.update/draw, taps.gd zones (12 cubes, READ and LEAVE buttons). read(): pays, with
    12 removes the chosen trait (remove(): UNDO ops add/mul/pct/attr/hook and procs come off for
    every rank and tier; family count and family bonus tiers drop; set/grant/add_cap and other
    one-off ops stay), then take_trait. Without the gold the book closes again (the bot only
    presses USE).
- The pick screen shows TRAITS N OF 12 (orange at the limit), the title RAISE A TRAIT or TAKE A
  STAT POINT, and no luck row at the limit. The TRAITS page's line says TRAITS N OF 12.
- Might.ranged no longer counts melee kinds outside WeaponInfo.MELEE (spin, flail, slam...) as
  ranged.
- --ui=tome / --ui=tomefloor (--trait-opts=ID) for pictures. Test tests/traitrules_test.tscn (in
  check.sh).

### Stage 42 (10 Oct): the INTELLIGENCE traits (his pictures)
- scripts/combat/arcana.gd (class Arcana), expanded game only, reset with Might and Finesse:
  power_add (dreamer x the special's charge, hungry x armor; in Might.power), dmg_mult
  (menagerie; in Might.dmg_mult), helper_mult (inspire, mind_beacon, menagerie, pack_mind; in
  Legion.dmg_mult), special_add (insight per INT rank; in Finesse.special_power), tick_add
  (entropy, bell_curve, slip_t; in Finesse.tick_rate), crit_add (anatomy on a bleeding foe),
  foe_mult (cursed hits: cursed_hit, x2 curse_x2; curse_dmg; sneaky hits: trickery per common
  gear piece, x1.6, "SNEAKY"; no dice for silent hits or builds without them), focus_mult
  (elem_focus: x2 burn/chill/shock while Might.casting or Auras.pulsing), on_status (end of
  Statuses.apply: poison_bleed, poison_vuln, elem_wheel burn>chill>shock>burn; _busy stops
  chains), on_lightning + tick (thunder_twice: once more after 0.5 s; Arcana.later), orbit_mult
  (wide_orbit x2 radius; moon hits leave foes vulnerable), orbit_speed (bell_curve), blast_mult
  (ignition: explode_at x1.5 and burns), on_attack (third_echo: the attack after every 3rd
  repeats), on_special (time_slip: 10 s; from Might.cast), fan (action fan_shots: frost shards
  chill, a venom thistle poisons and pierces), pocket (action pocket_cast: a random castable
  backpack weapon via Lucky.cast(p, e, pick)). Action trigger fires a moment's procs (VISION).
- Elsewhere: Auras pulse_<kind> (a field's own pulse speed), Lucky.chance x (1 + lucky_mult),
  lucky_extra strikes, Might.buff_mult + buff_int x INT, Finesse.helpers counts the minion cap.
- 38 int_ traits (names checked against everything), pictures tools/art/stage42_traits.py,
  keywords POWER, LUCKY, SNEAKY, MOON(S), FIELD(S), HELPERS. TraitRules.NEEDS "special" for
  CINDER RAIN, TIME SLIP, DAYDREAM, UNRAVELING, DEEP THOUGHT, MIND BEACON.
- Test tests/stage42_test.tscn (in check.sh).

### Stage 43 (10 Oct): SUPER, PSYCHIC and AUGMENT traits (his pictures)
- scripts/combat/marvels.gd (class Marvels), expanded game only, reset with the others: dmg_mult
  (idle_hands x empty Gear.slots, up to +250%; mind_link: a quarter of Legion's bonus; in
  Might.dmg_mult), helper_mult (mind_link x5 with exactly one helper, marionette x0.3; in
  Legion.dmg_mult), crit_chance (ranged_crit with a bow or gun), foe_mult (cryo_core: the special's
  blows chill, x1.5), special_add (dilation +10% a special used up to +200%, power_core: power/100;
  in Finesse.special_power), tick_add (still_ticks standing still), bleed_rate (bleed_moon: +10% a
  moon), burn_extra (burn_pct of max health a burn tick, a fifth from bosses), lucky_add
  (dice_mind x Player.dice_used), on_special (laser_core: a rail shot at the nearest foe every
  0.4 s for 8 s; dilation: drinks a room longer), on_floor (revive_floor: revive at least 1).
- Elsewhere: Statuses.shock_cap() (shock_max), op "drinks" (n random drinks, one-shot), actions
  drink_random and attrs, hurt_self skipped with no_curse, TraitRules.HERO_ONLY (psy_ the
  Mindwarden, aug_ the Tinkerer), TraitView groups psy (pink) and aug (steel), Traits.PLUS for the
  three that count as 6 ranks.
- 31 traits (sup_ 15 rarity super, psy_ 11, aug_ 5; names checked), pictures
  tools/art/stage43_traits.py (the AUGMENT cores share a hexagon), test tests/stage43_test.tscn.

### Stage 43.5 (10 Oct): stability test and bug fixes (his word)
- tools/dev/soak.sh with HEROES=34 JOBS=3 (53 runs, 10 minutes each, plus a 30-minute object
  count): clean. A small checker (scratchpad stuck.py, not in the repo) flags a run whose bot sat
  in one room 4 minutes: the four it found were level-1 heroes started deep (they kill slowly).
- tools/dev/monkey.sh 60 6: 16 runs clean; the tome screen (--ui=tome) and a 12-trait pick under
  --monkey clean.
- tools/check.sh: the rooms test placed a foe where the seed's layout has a wall (spawn_enemy moves
  it), fixed in the test; two relics renamed (arsenal test: names unique). The full check had not
  run since Stage 35 (his word of 9 Oct: compile only); it runs again now.

### Stage 43.7 (10 Oct): the old traits made like the new ones (his word)
His words: "revamp all old traits to be like our new traits", "Also update effects of old traits
to match new", then "dont update just picture update mechanic to match latest traits soo they wont
feel out of match": effects first (43.7a), then pictures (43.7b).
- 43.7a: scripts/data/trait_revamp.gd (class TraitRevamp), const MORE: id -> [sentence, effects]
  for all 286 traits from before Stage 40. Traits.all() keeps the old text as t["base_desc"], the
  sentence as t["more_text"], the effects as t["more"], and t["desc"] = base + ". " + sentence;
  under --classic none of that (the first 72 rows, as they were). Traits.apply applies t["more"]
  with src "trait+:"+id when GameData.rogues() (so force_classic, the effects test, sees the old
  effects only: ALL MATCH). TraitRules.remove takes it back rank by rank. Live.desc puts the
  "(+X% NOW)" value after the old text, before the added sentence. t.get("more", []) everywhere a
  hand-built trait dict may come in (the content test builds some).
- The add-ons use the hooks of Might, Finesse, Arcana and Marvels (crush, lethal, power, lucky,
  echo, roll_haste, minion_dmg/cap, menagerie, hungry, anatomy, chill_crit, cursed_hit,
  curse_dmg, ignition, shock_max, shock_critdmg, thunder_twice, elem_wheel, elem_focus, halo_*,
  tick_haste, toxin_crit, poison_vuln/bleed, burn_pct, trickery, lucky_heart, dice_mind, ...),
  a few procs (on_hit poison or bleed, on_room_clear die or stack, on_shoot ice shards, on_roll
  burns) and stats (crit, crit_mult, chain, storm, thorns, rerolls, attributes). Multi-rank
  traits got one that grows with every rank; oaths a one-line one; OATH OF BLOOD's text joined
  "+40% DAMAGE, -1 MAX HEART" so its add-on fits.
- tests/revamp_test.tscn (in check.sh): every old trait has one; every text fits its level-up row
  (4 lines, an oath's 3); each of the 286 taken to its last rank and given up twice, with and
  without its add-on (it changes something, and nothing of it stays); 14 fights of 20 old traits
  at their last rank; classic MIGHT gives no crushing hits. A fight with all 286 at once is slow
  (60 ms a frame), with or without the add-ons: no run can hold more than 12.
- 43.7b: tools/art/stage43_7_traits.py, a 16 x 16 picture for each of the 286, drawn in five
  batches by family (ART_OUT=<folder> and SHEET=<file.png> write a preview and a contact sheet).
  Each batch was looked at four times the size; the unclear ones were redrawn (a phantom too like
  a famous arcade ghost got a curling tail, a rune that looked like a peace sign became a diamond).
  Baked into the atlas (2442 of 2443 graphics, 1024 x 4096); tests/atlas_test passes. Seen on the
  level-up card (--ui=traits --trait-opts=might,o_rage,n_dragonsoul and others): pictures and
  texts fit. The core replays were re-recorded for 43.7a (classic identical).
- The full check found four things. STATIC BUILD-UP's add-on raised the shock a foe holds, which
  moved its own discharge from 5 to 6: its add-on is now a chance to arc, and its text says
  "AT FULL SHOCK" (other traits can raise the cap, as PSYCHIC LIGHTNING always could). Three tests
  measured an old effect with the add-ons mixed in: the live test wanted "(+X% NOW)" at the very
  end (it is now after the old text, on purpose), the legion test BONE BEACON's exact +40% (it now
  sets GRAVE MARSHAL's and BONE BEACON's add-ons aside for that), and the tavern test's BAR
  BRAWLER had about 8 hits in 10 s because LAST ORDERS throws the foes out of reach (a coin toss
  for a 15% stun; the foes are now put back in reach each frame).

### Stage 44 (10 Oct): INFUSIONS (his pictures; "Ok go 44 and 45, and 46")
- scripts/game/infusions.gd (class Infusions): KINDS id -> [name, element, least, most, rooms (0 =
  for good), weight, colour]; ELEMENTS -> [number colour, ailment, word]. Player.infusions =
  [[kind, rooms left, stacks]]. infuse (PIXIE SAP picks one of SAPS; the same kind again: one
  more stack, rooms start over; SLOTS 5, one more pushes out the oldest sap, else the oldest),
  on_room (Game.enter_room; gf infuse_forever: never), stretch (Marvels.on_special, SLOW TIME),
  on_hit (Combat.on_hit_effects for the weapon's own hits: one damage_enemy for all of them,
  silent and no crit, x (1 + 0.25 floor) x (1 + gf infuse_dmg) x stacks, holy x2 on a cursed
  foe or a type in UNHOLY; each element's ailment 25%), maybe (Game.open_choice: chests 20-50%),
  stock_shop (a stall at cx + 72, cy + 34, between the gear and the anvil), draw_hud (after the
  drinks under the belt: rooms left or *).
- Consumables: is_kind and the new data(k) know infusions (their card text comes from
  Infusions.card); use() steeps the weapon; random_kind (bosses, elites 15%) is an infusion a
  third of the time. The shop item "infusion" (Game.interact: into the belt, BELT FULL denied);
  world_view draws an infusion pickup as its own picture. Debug --give=infuse:ID.
- PBullet.own is now set on every weapon shot (it was only for the Gaolbird and the rally hero):
  Might.on_hit (rage, puncture, reel, keen edge, threat, open wounds) runs for ranged weapon hits
  too, as the STR traits' texts say; and the infusions ride on them.
- ENDLESS INFUSION (dex_temper, edge, rare): gf infuse_forever and infuse_dmg 0.25. SLOW TIME's
  text: drinks AND INFUSIONS. Keyword INFUSIONS. stage41_test wants 39 DEX traits.
- Art tools/art/stage44_infusions.py: vials (saps), pouches (spices), glowing chunks (ambers),
  a flask under a halo (BLESSED DEW), sparkles (PIXIE SAP); tr_dex_temper an endless loop over a
  drop. Test tests/infusions_test.tscn (in check.sh); a shop's things are listed to check the
  stall stands clear of them (it stood on the armor at first).
- The full check passed but for the camp build test: the quest board's two random quests could be
  one already met (the meal eaten earlier in the test); the test now sets all three.

### Stage 45 (10 Oct): the GOOD, EVIL and LAWFUL shops (his notes of 9 Oct)
- scripts/game/align_shops.gd (class AlignShops): SHOPS al -> name, ruler, three relics, the gear
  piece of 38.1. open(al): GOOD Meta heaven_wins > 0, EVIL hell_wins > 0, LAWFUL Meta slain
  marshal > 0 (the DUSTWATER rift's ruler). place (Game.on_boss_dead after the WAYSHRINE; returns
  before any roll when none is open, so seeded runs with a fresh save are as before): CHANCE 0.6,
  weighted 1 + your alignment; stock: a banner ("alshop", drawn by AlignShops.draw, card in
  overlay_view) and three "shop" objects with "al" (relic or gear; the shop code buys them as
  any other), G.price(base, al); spot(): the first of SPOTS (tiles) with nothing within 26 x 20
  of the banner or a ware (a guardian's hoard chest stood at 280,192, by the first try's row).
- Nine relics (relics.gd, under "45.1"), shop-only (Game.relic_pool leaves AlignShops.shop_only
  out): ALMSGIVER'S HALO power_per_good 4, LAMP OF MERCY heal_per_good (room_cleared, fights),
  DAWN BUCKLER armor_per_good (start_floor), CROWN OF ASH power_per_evil 4, SINNER'S CHALICE
  cursed_per_evil 0.02 (Arcana.cursed_chance), GRAVE COIN leech_per_evil 0.01 (kill_enemy),
  TIN STAR power_per_law 4, LEDGER OF DUES (id duesledger) crit_per_law 0.02 (damage_enemy),
  IRON WRIT roll_per_law 0.03 (Might.roll_rate). Power: Might.power + AlignShops.power_add.
  Two first ids clashed (bloodtithe, ledger: an older relic and a trinket): renamed; the content
  test caught it.
- Art tools/art/stage45_alignshops.py (12 x 12). Test tests/alignshops_test.tscn (in check.sh):
  closed until a ruler falls, each shop's banner and wares, prices by alignment, bought, a real
  guardian's hall after the kill (3 seeds) with nothing overlapping, the nine relics' numbers,
  classic none. Debug --ui=alshop --al=good|evil|law (a shop in the first room, for pictures).
- Checked: the shops test, the content test (every relic in a live fight), arsenal, items, alignloot,
  effects (ALL MATCH), all 14 replays identical. The full check runs with Stage 46's.

### Stage 46 (10 Oct): WEAPON ENCHANTMENTS (his pictures; "Ok go 44 and 45, and 46")
- scripts/game/enchant.gd (class Enchant): KINDS id -> [name, group, what it does, effects, more];
  more: "el" [element, least, most] (an element's hit, ridden on Infusions.on_hit: x(1 + 0.25
  floor), not x infuse_dmg), "grade" +-1 (Attributes.scaling shifts every grade but "-"; S at the
  top, E at the bottom), "plus" n (WeaponInfo.plus; the anvil's cap and price count only its own
  levels, raw w["plus"]), "needs" an element (has_element: the enchantment's, an infusion's, or
  the weapon's pyre / frost / storm tag). Groups: bad (FLAWED), good, grand (LEGENDARY), rare
  (only from their places), old (OLD LORE, the four removed there). ENCHANTMENTS_PLAN.md maps
  each picture to its name here.
- One at most, on the weapon's own copy: w["ench"] (+ w["ench_v"], CONTRABAND's pick). enchanted()
  duplicates; give() re-equips (Weapons.equip_weapon now calls Enchant.on_equip -1 for the old
  weapon and +1 for the new: Effects.apply_equipment src "ench"), so the effects come and go with
  the weapon and a new one replaces the old. RunSave keeps it (the weapon dict is saved whole).
- Drops: Weapons.random_weapon -> Enchant.maybe (DROP 10% common .. 40% mythic; BAD, GRAND by
  rarity; one randf more per weapon in the expanded game, none in classic). Hooks: foe_mult in
  Combat.damage_enemy (slay_dragon DRAGONS, slay_fiend FIENDS, slay_boss: is_boss, d.mini,
  d.champion; ench_afflicted Combat.afflicted; ench_armored guard_t or armour plates; ench_ready
  special_cd <= 0), burn_mult on the burn tick, status_mult in Statuses.apply (chill, shock),
  ench_top in Might.roll. Existing gf: lucky, nocrit_dmg; stats: crit, crit_mult, elite_mult,
  dmg, rate, attr.
- Infusions.ELEMENTS gained necrotic (pink, curse) and dark (grey, gloom).
- Places (Enchant.handles: game.interact, overlay_view prompt, world_view draw): "enchanter" in
  every expanded shop at cx - 72, cy + 34 (between the dice cup and the weapon; name plate
  ENCHANTER; price 30 + 8 floor + 20 per use this run, run_stats "enchanter"); "e_breath" x4
  (EventRooms "breath", THE WYRM'S BREATH, a fourth special room: EventRooms.specials() adds it in
  the expanded game only, game.gd and floor_map.gd pick from it); "e_runesmith" (chop shop,
  cx - 40, cy + 4), "e_contraband" (pawn shop, cx + 36, cy + 44), "e_branch" (frog pond,
  cx + 48, cy - 2), via Enchant.place_special.
- Shown: WeaponInfo.display_name (prefix), OverlayView.item_lines (a line in the group's colour),
  the swap card's REPLACES, the equipment page (name and a line at y 87), the shop's name plate of
  a weapon, Enchant.glint (two pixels over an enchanted weapon on the floor or in a shop).
- Art tools/art/stage46_enchant.py: o_enchanter (a lectern, an open book), o_breath (a stone wyrm
  head; its breath drawn in code), o_runeforge, o_contraband, o_branch. Debug --give=ench:ID.
  Pictures: --floor=1 --no-oath --room=shop | --event=breath (without --floor the first room
  comes back at the start of floor 1; --no-oath keeps the oath pick off the picture).
- Test tests/enchant_test.tscn (in check.sh): the 46 names and texts, drops (3000: about 25%,
  never a rare one, no legendary on a common weapon, the game's own weapon untouched), every one
  comes and goes with its weapon, a new one replaces the old, grades, levels, CONTRABAND, the
  slayers, KINGSLAYER, CRUEL, UNYIELDING, SPELLBOUND, SCALDING, WYRMFROST, HEAVY-HANDED, an
  element hit, THE ENCHANTER, THE WYRM'S BREATH (200 visits: about a fifth charred), the three
  places, the item card, a saved run, 5 s of a live fight with CRACKLING, classic none.
- Checked: the enchantments test, the content test (every item in a live fight, 795 swaps
  restored exactly), effects (ALL MATCH 2424), the six classic replays identical, the eight core
  ones re-recorded (content added on purpose) and identical on a second run, and the full check
  (84 sections, covering Stage 45 too): CHECK PASSED. Not tested: the iPad itself.

### Stage 47 (10 Oct): THE GOURD, SHATTER, the title menu and the hero select (his list; his word)
- scripts/game/gourd.gd (class Gourd): Player.gourd (sips left) and gourd_max (its own sips, 1 from
  Gourd.start in Game.new_run; 0 in classic). max_sips = gourd_max + gf gourd_sips; a sip heals
  SIP_HEAL (4 half-hearts) + gf gourd_heal. Player.try_heal: Gourd.sip first (with a heart to
  heal; ELIXIR's 3 s and on_potion as a potion's), then the potion as before. fill: on_room (a
  "rest" room, once a floor: floor_d gourd_rest) and Game.on_boss_dead. HUD: Gourd.draw_hud before
  the potions (the static HUD's signature has gourd and max_sips). HOW TO PLAY's empty row says it.
- scripts/combat/shatter.gd (class Shatter): Enemy.shatter (stacks, MAX 5) and shatter_t (TIME 4 s);
  Statuses.apply "shatter" -> add; dmg_mult x(1 + PER 0.05 x (1 + gf shatter_x) x stacks); tick;
  Combat.damage_enemy and update_enemies check shatter too; Combat.afflicted counts it (an
  ailment: status_dmg, CRUEL). Sources: Combat.on_hit_effects -> Shatter.on_hit (Might.blunt
  weapons' own blows, BLUNT 15%; 52 of 512 weapons are blunt), Combat.update_bombs ->
  Shatter.blast (BOMB 2 stacks, 1 for a cluster's), procs ["status", "shatter", 1]. Drawn in
  world_view._draw_enemy: a shard a stack (SPOTS around the body).
- Relics (relics.gd, "47.1 ... 47.2"): wayfarercork (rare, bulwark), honeystopper (common,
  bulwark), splitwedge (rare, demolition), crackedgeode (epic, demolition). Art
  tools/art/stage47_gourd_shatter.py (the HUD gourd 7 x 9, four relics 12 x 12).
- Title (menu_view.draw_title): TITLE_X/TITLE_W/TITLE_Y0, title_dy (16 up to 9 rows, 15 with
  CONTINUE), title_y(i); the menu in a panel on the left; the logo above; _title_camp: a campfire
  at CAMP_X/CAMP_Y with title_heroes() (the hero you play, then the next two unlocked in
  hero_order) at 3x on a lit oval, the played hero's name under it. taps.gd follows title_y.
- Hero select (menu_view.draw_hero): every hero in hero_cell(j) (two rows of ceil(n / 2) along
  the top, up to 26 px a cell), locked ones as grey shapes, a green dot on new ones you own; the
  card below (CARD_Y 84, CARD_H 146): the hero at 3x with hearts and "n / 34" on the left, its
  words left-aligned on the right. taps.gd: one two-tap zone a cell (hero_window and the scroll
  arrows are gone).
- Test tests/stage47_test.tscn (in check.sh): the gourd (a sip before a potion, not at full
  health, the rest stop once a floor, a guardian, the relics), shatter (stacks, x1.25 at 5 over
  2000 rolled hits, gone after 4 s, CRACKED GEODE, a maul about 15%, a blade never, a bomb, the
  wedge about 15%), every title row and hero cell tapped (no overlap, each picks its own), classic
  none.

### 47.6 (11 Oct): his lag clip, and every trait checked (his word: "check every trait for lag and bugs")
- His clip (10 Oct, IPA 46): THE ALCHEMIST on floor 3, SPORE MOTHER'S BLOOM, the ARCHMAGE set,
  COLLAPSED STAR, SPARE HEART, level 19, 476 kills, crit 7704% (p.crit 77), 17.2 shots a second x5;
  SHOW FPS read 14 to 19 FPS, LOGIC 39.7 to 62.6 ms, DRAW 0.8 (the 6424 ms worst frame: the iPad's
  screen recording stopping). Paused: 60 FPS.
- tests/trait_lag_test.tscn (not in check.sh: about 9 minutes; run it in parts, --part=N
  --parts=4, and --kind=relic): every trait at its most ranks, every relic, on the Alchemist in
  a live fight (foes that die and come back, rolls, the special) for 600 ticks, then 600 with no
  foe; fails on a median over 6 ms or a tick over 60 ms of logic, or a stat that stays grown
  (crit +0.05, damage or rate +25%, shots +2, health +4). All 432 traits and 198 relics pass
  (medians 0.5 to 1.1 ms here). So no single one: his case is a mix. Rebuilt with crit 77 and the
  crit traits (MOMENTUM, FIRESTORM, STATIC CLING, CRIT CASCADE ...): MOMENTUM's fire-rate buffs
  fill the 64 buff slots (x20 fire rate), the 300-shot cap holds, poison pools pile up from
  kills: 4.7 ms median, 8.2 p90 here; shots 1.4, spells 1.2, foes 0.9, the hero 0.6, effects 0.8.
  Where p.crit 77 came from is not found (no stat leaks in any trait or relic alone; nothing adds
  or multiplies crit that much); his relics page would tell.
- SHOW FPS has a second line now (main.gd _perf_tick, Game.lprof timed in update_play): the three
  costliest parts of the logic a tick (PROCS, HERO, FOES, SHOTS, FOE SHOTS, PICKUPS, POOLS,
  SPELLS, FX) and how many shots, foes, pools and procs a tick are in play. His next clip of a
  slow fight names the part to make cheaper.
- The full check's two failures fixed in the tests: vfx_test resets shatter between its runs;
  unit_tests checks the touch stick in play (the title's menu panel covers that corner now).

## Noted, not yet acted on

- Saving a run in progress: done in 6.3 (`RunSave`, CONTINUE on the title).

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
