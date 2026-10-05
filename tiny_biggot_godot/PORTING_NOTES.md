# Tiny Biggot: Godot port notes

This is a port of *Tiny Biggot* (RPG Maker VX Ace / RGSS3, Ruby) to Godot.
The original Ruby scripts, extracted from `Data/Scripts.rvdata2`, are in
`reference/ruby/` for side-by-side reading. That folder has a `.gdignore`, so
Godot skips it.

> The conversion brief (`TinyBiggot-Godot-Conversion-Brief.md`) was not in the
> repository when this port started. This file records the rules actually
> followed. Fold in the brief's sections when it turns up.

## Target

* **Godot 4.6.1**, the engine inside **Xogot 1.6** on iPad. The project is
  verified with the official 4.6.1 Linux binary. Do not use 4.7+ APIs, or the
  project will not open in Xogot.
* Renderer: **Compatibility** (`gl_compatibility`) on desktop and mobile.
* Display: 448x288 base, stretch `viewport`, aspect `keep`, scale mode
  `integer` (5x on the iPad Air's 2360x1640 screen gives 2240x1440).
  Nearest-neighbour filtering is set project-wide. Landscape only.
* Input: touch first. The on-screen layout comes from `assets/controls.json`.
  Keyboard and gamepad also work, including an iPad Magic Keyboard. Any key
  or gamepad press hides the touch controls, and the next touch shows them
  again. The Magic Keyboard has no Esc or function row, so Tab, ` and P also
  open the menu, and E and B also throw a bomb. F (or R3 / Back on a gamepad, or the
  SKILL touch button) uses a new hero's special ability. Keys are bound both by
  position and by the letter typed, so non-QWERTY layouts work too.
* Self-contained: only `res://` and `user://` paths. Copy the
  `tiny_biggot_godot/` folder to the iPad and open it in Xogot. `.godot/` is
  regenerated on first open.

## Layout

```
tiny_biggot_godot/
  project.godot           settings, autoloads
  PORTING_NOTES.md        this file
  assets/graphics/        Graphics/CC/*.png (names unchanged)
  assets/atlas/           sprites.res: the sprite atlas, ready-made (see Img)
  assets/titles/          Cover.png
  assets/audio/se|bgm/    Audio/SE, Audio/BGM (names unchanged)
  assets/controls.json    original Empo touch layout and pad bindings
  scenes/main.tscn        root scene
  scripts/
    main.gd               fixed 60 Hz logic tick + screenshot hook
    debug_args.gd         --hero/--seed/--bot/--shot test options
    core/   tb.gd         constants + Ruby-safe math helpers (Core.rb)
            seed_rng.gd   SeedRng (Core.rb)
            keys.gd       autoload Keys: input map and RGSS trigger/repeat
            img.gd        autoload Img: texture cache + white silhouettes
            snd.gd        autoload Snd: SE pool with per-sound gaps, BGM
            meta.gd       autoload Meta: $opts / $meta and saves
            gfx.gd        RGSS-style sprite and pixel-font drawing
    data/                 tables from Data.rb, 01b_traits.rb, 01c_items.rb
    world/                rooms, floors, collision (World.rb)
    entities/             player and enemies (Entities.rb, 04b_items.rb)
    combat/               bosses, bullet pools, particles, pickups (Combat.rb)
    game/game.gd          autoload G: run flow and state machine (Game.rb)
    render/               world drawing layers, touch controls, overlays
  reference/ruby/         original scripts (ignored by Godot)
  tests/                  unit tests and the compile-everything checker
  tools/check.sh          headless import + compile + run check
  tools/bake_atlas.sh     remakes assets/atlas/sprites.res after a graphic changes
```

The app built with Xcode: IOS_BUILD.md (what was done for it, the build
steps, the export preset).

## Ruby to GDScript traps

| Ruby | GDScript trap | Rule used here |
| --- | --- | --- |
| `-1 % 5 == 4` (sign of divisor) | `%` truncates (`-1 % 5 == -1`); `fmod` too | `TB.rmod()` / `TB.fmodp()` (posmod/fposmod) wherever an operand can be negative: menu wrap, boss plan index, rotation angles |
| `-7 / 2 == -4` (floors) | int `/` truncates toward zero | `TB.idiv()` when an operand can be negative. Plain `/` only where both are known non-negative (`max_hp / 2`). |
| `x.floor`, `.ceil`, `.round` return Integer | `floor()` returns float | `floori`, `ceili`, `roundi` for indices and tiles; `round()` matches Ruby's half-away-from-zero |
| only `nil`/`false` are falsy | `0`, `0.0`, `""`, `[]`, `{}` are falsy | Never test a number for presence. `Keys.aim()` returns `null` or an angle, and the caller checks `!= null`, because angle 0.0 (aim right) is valid. Optional numbers use explicit `has_*` flags (enemy `orb`, `cyc`, `telegraph`, mine `mvx`). |
| `x ||= v`, `(x || 0) + 1` | no equivalent | Fields are declared with Ruby's implicit default (0, 0.0, false) on typed classes |
| boomerang `back`: `nil` / `false` / `true` | tri-state lost in bool | `PBullet.back` is an int: `BACK_NONE` / `BACK_OUT` / `BACK_RETURN` |
| `SeedRng` on arbitrary-precision ints | ints are signed 64-bit | Mask with `0xffffffff` after every left shift, exactly as the Ruby does. The largest intermediate is < 2^45. Verified against Ruby output in `tests/unit_tests.gd`. |
| `rand(n)`, `rint(a, b)` | | `randi() % n`, `randi_range(a, b)` (inclusive) |
| `array.each` while appending (slime splits, bullets spawning bullets) | `for x in array` while appending is unsafe | Index-based `while i < size()` loops, so new items are visited in the same tick, as in Ruby |
| `hash.each` insertion order (`weighted`) | Dictionary keeps insertion order | Same semantics |
| `object_id` keys in hit sets | | Enemies carry a unique int `uid`, and hit sets are Dictionaries keyed by it |
| Sprite `angle` (deg, CCW), `mirror`, `color` tint | rotation is radians clockwise; `modulate` can't lighten | `Gfx.sprite()` converts angle and mirror. Tints draw a white silhouette on top (`Img.white`). |
| `Bitmap#fill_rect` with alpha on the bg bitmap | replaces pixels, then shown over black | Pre-composited over black when drawing the room background |
| Textures loaded inside `_draw()` | freed at return, so they draw white | Always draw through the `Img` cache or a member/preload reference |

## Performance (the reason for the port)

The original slowed down with many projectiles. Each bullet and particle was a
Ruby Hash plus an RGSS Sprite, and the arrays were rebuilt with `reject!` every
frame. The port uses these rules:

* **Enemy bullets**: struct-of-arrays in packed arrays (x, y, vx, vy, r, life,
  fuse, sprite id) with a hard capacity. Dead bullets are compacted in place
  each tick. There is no per-bullet allocation, no Dictionary lookup and no
  Node.
* **Player bullets**: typed `PBullet` objects recycled through a free list.
  They need many per-shot flags, so there is no per-shot allocation after
  warm-up.
* **Particles**: struct-of-arrays, capped at 400 live like the original. Drawn
  as untextured rects in a single canvas item, so they batch into one draw
  call.
* **Drawing**: no node per entity. Each world layer is one `CanvasItem` that
  redraws from the arrays every tick, grouped by texture so Godot's 2D batcher
  merges them. The static room background and the doors/crates layer are only
  redrawn when they change.
* Logic runs at a fixed 60 Hz in `_physics_process` with `DT = 1/60`, matching
  the original's frame-locked update.

## Stage plan

1. **Skeleton**: project settings, autoloads, assets, input map, pixel font,
   SeedRng, headless check tooling. Done.
2. **World**: floors and door choices, room generation, collision, room
   background, doors, crates, exit signs, torches, vignette. Done.
3. **Player**: player state, movement, roll, collision, room transitions,
   particles, and touch controls (the primary input on iPad). Done.
4. **Combat**: weapons and attack types, enemies and AI, bosses, bullet pools,
   particles, pickups, bombs, zones, damage, death. Done.

   *Stop here for play-testing.*
5. Items: relics, traits and level-ups, gear and weapon swaps, chests, shops,
   shrines. Done. Every item effect is verified against the original Ruby
   (see Testing).
6. HUD: hearts, minimap, prompts, banners, boss bar. Done.
7. Menus: title, hero select, skill trees, shrine, codex, options, pause, end
   screens. Done. The game opens on the title screen ("TINY BIGGOT ROGUES",
   design spec section 1); test options such as --bot or --hero start a run
   directly. Small text fixes: "HOW TO PLAY" says 6 floors (the original said
   4 though the game has 6) and calls the on-screen controls TOUCH instead of
   EMPO. The codex scrolls when there are more relics than fit.
8. Touch polish: menu-friendly touch, haptics, safe areas.

## Status after stages 4 and 5 (what to try)

Playable now: the game boots straight into a run (no title menu yet) with
the Hexer. Use `--hero=N` on desktop to pick another hero. You can walk the
room chain, fight waves and elites, fight all six guardians, take the portal
to the next floor, die (USE restarts), and win after the sixth guardian. All
113 weapons fire correctly. Relic, trait and gear effects are wired into
combat but nothing grants them yet.

Temporary in this build:

* `render/debug_hud.gd` is a text status line, a boss bar and pause/death
  screens. The real HUD comes in stage 6.
* Stage 5 adds all room objects (chests, iron and cursed chests, pedestals,
  shops, altars, fountains, idols, campfires, challenge bells, vault locks),
  relic choice, level-up trait picks with rerolls and family bonuses, weapon
  and gear drops and swaps, gear sets, skill-tree nodes and shrine perks at
  run start. The skill-tree and shrine menus themselves come with the menus
  stage.
* No title, hero-select or pause menu. MENU pauses and resumes.

Deviations from the original (intentional):

* Vault and secret rooms place their gems, coins and embers in
  `room.pickups` before entering. The Ruby assigned `@pickups` before
  `setup_objects` filled `room[:pickups]`, so those pickups never appeared.
  That looks like a bug, so the port shows them.
* Entering a room recycles player shots into a pool instead of discarding them.

Performance (`--bench`, headless, logic only, this build machine):
500 enemy shots take 1.1 ms per tick and 1,500 take 2.4 ms, against a 16.7 ms
frame budget at 60 Hz.

## Effect system (design spec step 3)

`scripts/effects/` holds the effect system. Every item is data: an id plus a
list of effects.
* Stat ops: flat, multiplicative, additive-% and the original clamped forms.
* Procs (triggers with actions, chance, every-N, cooldown and conditions).
* Statuses: the originals plus shock, vulnerable and weakened.
* Timed buffs.
* Tag synergies and named combos (`data/synergies.gd`).

All original relics, traits, family bonuses, skill nodes, weapons, gear and
sets were moved onto it: their Ruby lambdas and stat tuples became op lists.

Rules that keep the original game identical:
* New mechanics only run when new content switches them on (procs, pct,
  overcrit, new statuses). A player without procs takes the old code paths and
  draws exactly the same random numbers.
* Tag synergies and combos count new-content items only. Original items keep
  feeding the original systems (family bonuses, weapon synergy, sets).
* Item ids are unique per table, because the originals reuse `lantern` and
  `echo` across tables. Combos therefore name items as `relic:x`,
  `weapon:x`, `gear:x` or `trait:x`.

Safety rails (`Effects` constants):
* proc depth 4;
* 200 proc actions per tick, with the rest queued;
* 1,000 live player shots, after which damage merges into the newest shot;
* 24 summons;
* one attack per tick;
* damage labels shortened past 99,999.

The shot cap is 1,000 rather than the spec's example of 2,000 because the
broken-build test needed it to stay inside a 60 Hz frame. Original content
never gets near it, as the replays show.

## Leveling and traits (design spec step 4)

* **12 archetypes:** `Traits.ARCHETYPES` maps each to a family. Nine reuse
  original families (blood, pyre, venom, storm, arcane, swarm, shadow,
  bulwark, fortune). Crit, berserk and curse get the new families EDGE, FURY
  and MALICE, each with three family-bonus tiers at 2, 4 and 6 ranks. Frost
  and demolition stay as extra original families.
* **Rarities:** common, uncommon, rare, legendary and cursed
  (`Traits.RARITY`). Original traits show as common, and their capstones as
  legendary.
* **Stacking tiers:** new traits can add effects when a rank is reached
  (`tier_effects`, e.g. rank 3).
* **Weighted offers:** original traits keep the original formula exactly. New
  traits weigh rarity times an affinity built from ranks in the family plus
  tag points from new-content items, so a build snowballs. Legendary traits
  need 3 family ranks and cursed traits appear from level 3.
* **Paid rerolls:** the two free rerolls are unchanged. Once they are gone,
  MENU rerolls for gold (15, then +10 per paid reroll). In the original,
  MENU did nothing at that point.
* **Room choice:** unchanged. It already shows room type and reward, and the
  new content has not needed new room types yet.

## Testing

**Unchanged behaviour (replays).** `tools/replay.sh check` reruns six seeded
5-minute autopilot scenarios (several heroes, god mode, every unlock, weapon
cycling, late floors) and compares a full logic-state line per second against
recorded baselines. It runs two sets:

* `tests/replays/classic/` uses `--classic`, so every pool holds only the
  original items. These baselines were recorded before the effect-system
  refactor (commit f2b3780) and before any new content. They must never be
  re-recorded. Any change to original behaviour, or to how many random
  numbers the game draws, fails them.
* `tests/replays/` uses the full Tiny Biggot Rogues pools. It proves that runs
  with new content are deterministic. `tools/replay.sh record` rewrites only
  this set; do that when new content is added.

**Content test (spec section 11).** `tests/content_test.tscn` lints all data,
gives every item (703 with batch 1) to a hero in a live fight, fires every trigger and plays 90
ticks. It also checks that every weapon and gear swap is reversible, verifies
each safety rail directly, and times a 50+ rank broken build and a stress run
(500+ enemy shots, summon cap, shot flood). It also assembles every named
combo and checks that every shown string fits the bitmap font. `tests/fixtures.gd` holds
synthetic items that reach every trigger, action, status and condition.

**Item effects against the original.** `tools/gen_ruby_effects.rb` loads the
untouched Ruby scripts from `reference/ruby/` into a real Ruby interpreter. For
each of the 6 heroes it gives a fresh player one item at a time: each of the 66
relics, each of the 72 traits at max rank, the 33 family bonuses, the skill
nodes, each of the 96 gear pieces, all 11 full gear sets, and each of the 113
weapons (with resulting damage, rate and range). It records every field that
changed in `tests/ruby_effects.json`. `tests/effects_test.tscn` repeats this
in Godot and fails if any field differs, or if Godot changes a field Ruby did
not touch. That is 2,424 comparisons, and all match. A planted wrong value and
a planted extra side effect were both caught, so the test can fail. Regenerate
the reference with `ruby tools/gen_ruby_effects.rb > tests/ruby_effects.json`.

```
GODOT=/path/to/godot-4.6.1 tools/check.sh 600       # import, compile all, run 600 ticks
godot --headless --path . res://tests/unit_tests.tscn
godot --path . -- --hero=2 --seed=7                  # play a specific hero/seed
godot --path . -- --shot=shot.png --shot-frame=120   # screenshot (rendered)
godot --headless --path . --fixed-fps 60 --quit-after 18000 -- --bot          # 5 min autopilot soak
godot --headless --path . --fixed-fps 60 --quit-after 21000 -- --bot --god --weapon-cycle=3   # every weapon
godot --headless --path . --fixed-fps 60 --quit-after 9000 -- --bot --god --floor=5 --room=boss  # final guardian
godot --headless --path . --fixed-fps 60 --quit-after 1400 -- --bench=1500 --god --bot --room=combat
godot --path . -- --touch                            # desktop: show touch controls, mouse = finger
godot --path . -- --god --combo=mirrorhall           # start with a named combo (CONTENT_BATCH_1.md)
godot --path . -- --give=relic:stormjar,trait:e_deep # start with specific items
godot --path . -- --classic                          # original items only
```

New content is listed in `CONTENT_BATCH_1.md`, along with the intended broken
combos.

All options are listed in `scripts/debug_args.gd`.
