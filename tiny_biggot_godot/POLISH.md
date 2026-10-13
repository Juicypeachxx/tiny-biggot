# Polish pass (design spec step 0b)

This pass makes the game feel punchier and plays better on the iPad. It does
not change any mechanic, number or balance value: every change here is
drawing or input only. All of it is original work; nothing is taken from
other games (spec section 1).

**Proof:** the new feedback has its own random generator and never touches
game state that logic reads. `tools/replay.sh` still reproduces all six
5-minute `--classic` runs recorded before any new content, byte for byte.
The six full-content runs also match.

## Hit and kill feedback (`scripts/render/juice.gd`)

| Change | Where |
|---|---|
| Foes squash briefly when hit (not bosses) | `world_view.gd` `_draw_enemy` |
| Killed foes leave a white silhouette that swells and fades, plus a shock ring | `Juice.kill` from `Combat.kill_enemy` |
| Boss kills add a big gold ring and a short white screen flash | `Juice.kill` |
| Crit numbers are drawn at double size; all damage numbers jump up a few pixels before they drift | `Fx.draw_texts` |
| Level-up adds a green ring around the hero | `Juice.level_up` |
| Clearing a room sends a gold ring out from the hero | `Juice.room_clear` |

## Player feedback

| Change | Where |
|---|---|
| Red screen edges flash when you take a hit | `Juice.hurt`, `Juice.draw_screen` |
| On your last heart the red edges pulse | `Juice.draw_screen` |
| The weapon kicks back and shows a small muzzle flash when it fires | `world_view.gd` `_draw_weapon` |

## Loot feedback

| Change | Where |
|---|---|
| Rare, epic and legendary drops (weapons, gear, relic pedestals) get a light beam in their rarity colour. Legendary beams are the tallest | `Juice.beam` in the glow layer |
| Coins and gems glint now and then | `Juice.glint` |

## iPad and input

| Change | Where |
|---|---|
| Menus can be tapped. Title, pause and options act on one tap. Relic and trait cards, heroes, shrine unlocks and skill-tree nodes take two taps (select, then tap again to confirm), so a stray touch never picks or buys anything. Codex icons select on tap. Screens that wait for any button take a tap anywhere | `scripts/render/taps.gd`, `touch_controls.gd` |
| Tapping the REROLL hint on the trait screen rerolls (same as MENU) | `taps.gd` |
| Touch controls fade to 35% on menu screens. There, a card under an idle button (BOMB, HEAL, aim) wins the tap; USE, MENU and ROLL still work | `touch_controls.gd` |
| Magic Keyboard support; touch controls hide on key or gamepad use and return on touch | previous commit, see `PORTING_NOTES.md` |

## Tests

- **Unit tests** (`tests/unit_tests.gd`):
  - A tap on the title menu selects and confirms.
  - A trait card needs two taps.
  - A touch that is lifted somewhere else is ignored.
  - A tap anywhere works on the end screen.
  - The keyboard and gamepad hide/show rules hold.
- **Full suite:** `tools/check.sh` passes, including the content test, the Ruby effects comparison and all 12 replays.
- **Soak:** two 10-minute autopilot runs without god mode had 0 errors.

## Not done

- **Hitstop on crits and kills:** left out. It would change game timing, and section 0 of the spec keeps the original feel.
- **Real iPad testing:** the tap layouts follow the 448x288 drawing code, but finger comfort needs a check on the device.
