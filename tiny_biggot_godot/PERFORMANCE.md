# Performance pass (the "room full of shots" case)

Target: a steady 60 fps with the shot cap reached (300 player shots), a late
build and the training dummies, as in the iPad recording (30 fps, LOGIC 11,
DRAW 8). Nothing was removed or toned down: every shot, particle, number,
effect and proc is still there. The work is the same work done in fewer
script steps.

## What changed

| Area | Before | Now |
| --- | --- | --- |
| Shot drawing | Three or four script calls and draw commands per shot, and each of three layers looped over every shot | One pass per tick writes eight numbers per shot; a small shader places, zooms and turns the sprites (`scripts/render/shot_batch.gd`) |
| Shots against foes | Every shot looped over every foe, every tick | A grid of the room marks the tiles a foe can reach; a shot on an unmarked tile skips the loop. Same hits |
| Shots against walls | Two function calls per shot | Read straight from the room's tile array |
| Homing | Seven trigonometry calls per homing shot per tick, and a search through every foe | The same turn worked out as a rotation with none, and the search made every 4th tick of a shot's life (it keeps steering at the foe it found in between) |
| HUD | Fully redrawn 60 times a second | Redrawn when something it shows changes (and twice a second regardless). The special meter and banner, which animate, have their own small layer |
| Touch controls | All redrawn every frame while a hero with a special is played | Only the SKILL button, whose ring animates |
| Damage numbers | Two draw calls per character, every tick | Each number's glyphs are drawn once into its own canvas item, which is then only moved and faded (`scripts/render/float_texts.gd`) |
| Sparks | A dictionary per spark | Packed arrays, like the other particles |
| Text | Sheet names built and a lookup per character on every draw | Cached |

The first row and the damage numbers can be switched off in
OPTIONS > FAST DRAWING. Off, the original painters draw everything, so if
shots or numbers ever look wrong on a device, that switch tells you whether
the new drawing is the cause.

## Measured (desktop, same machine, same seeded scene, 270-300 shots)

| | Before | Now |
| --- | --- | --- |
| Logic per tick | 3.3 ms | 2.0 ms |
| World drawing (script side) per tick | 2.0 ms | 0.9 ms |
| HUD drawing per tick | 0.4 ms | about 0 |
| World-Eater build, 126 shots, logic | 1.46 ms | 0.70 ms |
| Heavy fight (14 foes, 40 relics), logic | 8.1 ms | 5.0 ms |

Xogot on the iPad ran these about 4.5 times slower than this desktop, so the
recording's 19 ms a tick should come to roughly 9 to 10 ms. Xogot runs the
game inside an editor build; an exported app has no debugger attached and
should be faster again.

## How it was checked

- `tools/check.sh` passes. The classic replays (original items) are
  identical to their baselines: the original game is untouched.
- The full-content replays were re-recorded: homing now turns by the same
  angle through different arithmetic (worst difference 0.00003 px/s in
  200,000 random cases), which shifts the recorded runs in their last digits.
  The foe grid on its own left all 12 replays identical before that change.
- Pictures: 30 seeded scenes (25 weapons, fights, a boss, the bullet stress
  test, the dummy room at the shot cap, the touch controls) were rendered
  before and after and compared pixel by pixel. 25 are identical. Five
  differ by 2 to 12 pixels where a turning sprite's edge rounds the other
  way. With FAST DRAWING off, the four scenes checked that way are identical.

## Measuring on the device

OPTIONS > SHOW FPS. LOGIC and DRAW are milliseconds per tick; their sum
needs to stay under about 12 to hold 60 fps in Xogot. DRAW now also counts
the shot pass ("shots") and the damage numbers ("texts").

`tests/shot_profile.tscn` profiles the dummy room per section:
`godot --headless --path . res://tests/shot_profile.tscn -- --no-save --hero=12 --floor=6 --weapon=worldeater --long --give=gear:volleyrobe`

## Ability effects (later)

The redrawn ability effects are capped and cost about 0.05 ms a frame on
desktop in the heavy fight; see EFFECTS.md. `--fx-demo` fires every effect in
turn and `--no-vfx` turns them off, so `--heavy --perf --fx-demo` with and
without `--no-vfx` compares the two on the device.

## Attack effects (later still)

The redrawn shots, swings, enemy shots and guardian attacks: ATTACK_EFFECTS.md
has the measurements. In short: 1500 enemy shots draw in a quarter of the time
(one pass instead of one per kind), shots are still one instanced draw and
every kind is now in it, and ordinary fights draw 0.02-0.06 ms a frame more on
desktop. `tests/draw_bench.tscn` times the two painters with a fixed crowd.
