# First iPad session: what to check

Everything below passes in automated tests on a desktop. These are the
things only the real device (iPad Air M1 in Xogot) can confirm. It takes
about 20 minutes. Note anything odd and send it over; each item says what
to report.

## Setup

1. Copy the whole `tiny_biggot_godot/` folder to the iPad and open it in
   Xogot. The first open re-imports assets (`.godot/` is rebuilt), which can
   take a minute.
2. Run the project. The title screen should say **TINY BIGGOT ROGUES**.
   - Report if: the screen is blurry (it should be crisp pixels at 5x) or
     not centred with dark borders.

## Touch

3. **Menus:**
   - Tap PLAY, the options and the pause menu items: one tap acts.
   - On the hero screen, tap a hero card once to select it and again to start.
   - Tap the arrows at the edges to scroll through the 13 heroes.
   - Report if: taps land on the wrong item, or are too small to hit.
4. **In a run:**
   - The left stick moves.
   - The aim pad aims.
   - ROLL, USE, HEAL, BOMB and MENU work while held.
   - Report if: a thumb blocks something important, or a button is
     uncomfortable to reach.
5. **SKILL button:** pick a new hero (for example the Sellsword) and press
   SKILL. The ring around the button refills and "SKILL READY" pops up.
6. **Level-up:**
   - Tap a trait card once to select it, then again to take it.
   - Tap the REROLL text to reroll.

## Magic Keyboard

7. Press any key: the touch controls should disappear. Touch the screen:
   they come back.
8. Keys:
   - Arrow keys move.
   - W A S D aims.
   - Shift rolls.
   - Enter uses.
   - Q heals.
   - E bombs.
   - F uses SKILL.
   - Tab opens the menu (the Magic Keyboard has no Esc).
   - Report if: any key does nothing, or Xogot takes a key for itself (for
     example Cmd shortcuts or Tab).
9. A click on the trackpad may count as a touch and bring the controls back.
   Report whether that bothers you.

## Look and speed

10. **Busy fights:** play a few busy fights and a guardian. On an M1 it
    should hold a steady 60 fps. Report if: it stutters, especially with
    many bullets, on the Eclipse floor or during Lead Rain or Stacked Deck.
11. **Effects to check:**
    - Hit flashes and screen shake.
    - The red edge when hurt.
    - Light beams over rare loot.
    - Report if: anything flickers or looks wrong at the iPad's scale.
12. **Sound:** music and effects play, and the options can mute them.

## Save

13. Finish or quit a run, close Xogot completely and reopen. Your embers,
    unlocks and skill tree should still be there.
