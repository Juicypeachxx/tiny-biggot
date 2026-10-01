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
  Keyboard and gamepad work for desktop testing.
* Self-contained: only `res://` and `user://` paths. Copy the
  `tiny_biggot_godot/` folder to the iPad and open it in Xogot. `.godot/` is
  regenerated on first open.

## Layout

```
tiny_biggot_godot/
  project.godot           settings, autoloads
  PORTING_NOTES.md        this file
  assets/graphics/        Graphics/CC/*.png (531 files, names unchanged)
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
```

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
   particles, pickups, bombs, zones, damage, death.

   *Stop here for play-testing.*
5. Items: relics, traits and level-ups, gear and weapon swaps, chests, shops,
   shrines.
6. HUD: hearts, minimap, prompts, banners, boss bar.
7. Menus: title, hero select, skill trees, shrine, codex, options, pause, end
   screens.
8. Touch polish: menu-friendly touch, haptics, safe areas.

## Testing

```
GODOT=/path/to/godot-4.6.1 tools/check.sh 600       # import, compile all, run 600 ticks
godot --headless --path . res://tests/unit_tests.tscn
godot --path . -- --hero=2 --seed=7                  # play a specific hero/seed
godot --path . -- --shot=shot.png --shot-frame=120   # screenshot (rendered)
```
