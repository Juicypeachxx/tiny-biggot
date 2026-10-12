# Couch co-op (Windows line only)

His word, 12 Oct: "start coop multiplayer build, add keyboard and mouse and controller support to it
and also, modify multiplayer mode to fit in to the game, from drops to difficulty and drops and stage
progression, and room entering", then "look at brotato gameplay too reference and multiplayer
reference, i want local couch coop with 4 players max".

This lives on `windows-build` only (WINDOWS_BUILD.md): it never goes to `claude/dev` or the iPad.
Keep the co-op code in its own files (`scripts/coop/`) and the hooks in shared files to one line each,
so the automatic merges from `claude/dev` rarely clash. With one player nothing changes: the replays
stay identical.

## The reference: Brotato's local co-op (ideas only, rule 3)

Up to 4 players on one PC, any mix of keyboard and mouse and controllers; each picks a character on
the character screen; each has their own pickups, levels and items; loot boxes are not shared (an
option shares them); a player who dies sits out until the wave ends; foes scale with the players.

## How it fits this game

- **Joining.** CO-OP on the title opens the joining screen (START RUN stays the one-player hero
  screen). Each device joins with its confirm button (keyboard: Enter or Space, or a click on a hero;
  controller: A), up to 4, in the order they join (P1 red, P2 blue, P3 green, P4 gold). Each player
  chooses a hero with LEFT and RIGHT (their colour under it), USE readies, MENU unreadies and then
  leaves; the run starts when two or more have joined and all are ready. A device that joins counts
  as that player for the whole run. Back on the title the party ends.
- **Controls.** Keyboard and mouse: move with the keys, aim with the mouse, hold the left button to
  fire at the cursor, the right button rolls; everything else on its keys. Controller: left stick
  moves, the right stick aims at its true angle, the buttons as now. Autofire works for everyone.
- **One screen.** Every room fits the screen, so no split screen and no camera: all heroes are in the
  room together, each with a coloured ring and a P1 to P4 tag.
- **Drops.** Coins, hearts, potions, keys, bombs, food and belt items go to whoever touches them
  (as in Brotato: not shared). A pedestal, a shop ware: the player who takes or buys it pays from
  their own gold. Gold, keys and bombs are each player's own.
- **Chests** (his pick, 12 Oct: "3 is cool"): everyone picks from one chest, in turn. Whoever opens
  it picks first, then the others in player order from what is left; the chest has one more relic
  for each extra player (with four: 6, so the last still chooses from 3), and a relic a player
  already owns is swapped for a new one on their turn. The screen shows whose pick it is and who
  comes next; more than 4 relics scroll (an arrow and a sliver of the next card at the edge). The
  key of a locked chest is the opener's.
- **Levels.** Each player has their own experience (kills give it to the killer, a guardian's to
  everyone). Level-ups already wait until the room is clear here: then each player picks their
  trait in turn, with their own device, their colour on the choice screen.
- **Difficulty.** Per extra player: foes and mini-bosses +60% health, guardians +75% health, waves
  +25% foes (rounded up). DREAD and loops work on top as now.
- **Down, not out.** A player with no hearts left is DOWN: a grey ghost at the spot. Standing next to
  them for 3 s revives them with 1 heart; a cleared room revives every downed player with 1 heart
  (Brotato: back for the next wave). The run ends only when every player is down. Lives that items
  give (SECOND DAWN and the like) work per player first.
- **Rooms and doors.** The doors open when the room is clear, as now. The party moves on when every
  standing player is in the same doorway (the doorway shows who is in it); downed players come along.
  On the floor map the leader (P1) picks the door, the others walk to it.
- **Menus.** Any player can pause (a downed one too); the pause menu, the gear page, the traits and the
  relics belong to the player who pressed, and only their device works it. Every page that is one
  player's shows whose it is: a frame round the screen in their colour and "P2'S GEAR" (MENU, PICK,
  TRAITS, RELICS, TOME) in the top right corner. P2 to P4 see "USE" over their head by something
  they can open.
- **Saving.** A co-op run is not saved for CONTINUE; a one-player run waiting to be continued is left
  as it was. The unlocks, embers and dust a co-op run earns are kept.

## How it is built (the code)

The game was made for one hero: about 300 places read `G.player`. Co-op does not rewrite them.
`G.players` holds every hero; for each hero's own work the game runs with `G.player` set to that hero
and the input (`Keys`) set to that player's devices (`Coop.as_player`), then sets them back. So a
hero's movement, shots, items, procs and pickups all work as they always did. Foes are updated with
`G.player` set to their nearest standing hero (that is who they chase and hit); foe shots test every
hero; a shot remembers its owner, and its hits count for them.

## The steps

- [x] C1 Controls: each player's own devices in `Keys` (keyboard and mouse, or one controller); mouse
      aim, left button fires at the cursor, right button rolls (also for one player on Windows); the
      right stick aims at its true angle. Done: `Keys.pads` (add_pad "kbm" / "joy" dev / "bot",
      use_pad(i) points the API at a pad, -1 at every device), quick taps latch to their own pad;
      the controller bindings now take every controller (they took only the first); a cross cursor in
      play. tests/coop_test.tscn (in check.sh, near the top). One player: two replays identical.
- [x] C2 Co-op core: `G.players`, `--coop=N` for tests (bots for the others), every hero moves, aims
      and shoots with their own device, foes chase the nearest hero, foe shots hit any hero, shots
      count for their owner, each hero drawn with their ring and tag, a small HUD for each.
      Done (`scripts/coop/coop.gd`): `Coop.extras` (P2 to P4), each made by a whole new_run of its
      own before P1's (`Coop.before_run`, the first line of Game.new_run), placed beside P1 in every
      room (`Coop.enter_room`); `update_heroes` (every hero's turn with their pad), `foe_target`
      (Combat.update_enemies: each foe's nearest standing hero, chosen again every second),
      `shot_hit` / `hurt` (EBullets: the other heroes), `update_pbullets` (each hero's shots with them
      as the player; PBullet.owner_i is set from Coop.actor), `update_pickups` (to the nearest hero);
      DOWN and REVIVE already (Combat.hurt_player: down instead of the end while anyone stands; 3 s
      beside them, or a cleared room, brings them back with a heart); the party goes through a door
      together (`exits`: "THE DOOR WAITS FOR P2"); rings, P1 to P4 tags, aim dots; P2 to P4's panels
      at the bottom. `--coop=N` (main.gd): N heroes, P2 on played by the test bot.
- [x] C3 The rules: down and revive, drops and gold per player, experience and level-ups in turn,
      chests and shops per player, the party through a door, difficulty per player. Done: down,
      revive and the door came with C2; `scale_foe` (Combat.spawn_enemy +60% health, spawn_boss
      +75%, for each extra player), `wave_size` (Game.spawn_wave +25% foes), `share_xp` (a
      guardian's experience for every standing hero); TURNS: `offer_turn` (after P1's: each other
      hero's oath and level-ups, one at a time, with G.player theirs and the menus on their pad:
      Keys.tick uses `menu_pad`), a hero's USE by a chest, shop ware or pedestal opens it as theirs
      (`update_heroes`), and `play_tick` (the first line of Game.update_play) gives the game back to
      P1 once play goes on. The test bots take the first trait offered.
- [x] C4 Joining on the hero screen (up to 4 devices), whose turn it is on choice screens, pause and
      gear per player. Done: the title's CO-OP opens the joining screen (state "coop":
      `Coop.open_lobby` / `update_lobby` / `draw_lobby`; a pad for the keyboard and mouse and one for
      every controller, also one plugged in on the screen; `_start` makes the party's pads in the
      order they joined, `want` their heroes, and starts the run). `on_title` (the first line of
      Game.update_title) ends the party. Pause: a P2-P4 MENU press makes the pause theirs
      (`play_tick` hands G.player and the keys to them, Game.update_play's own pause check opens it);
      a menu that a hero's own move, USE or pickup opens stays theirs until play goes on;
      `turn_label` / `draw_turn` (MenuView, last); `menu_pad` lets anyone go on from the end screens.
      P1's HUD and P1's drawing in the world use `Coop.lead()` (P1 even while G.player is P2 in a
      menu). RunSave neither saves nor clears during co-op (`Coop.busy`). Pictures: `--ui=coop`,
      `--ui=coopgear` with `--coop=N`. tests/coop_test.tscn `_join` and `_menus`.
- [x] C5 A test for all of it, 4-player bot soaks, the Windows build. Done: tests/coop_test.tscn
      covers C1 to C4 (in check.sh); the full check passed on windows-build with Stage 55 merged
      in (CHECK PASSED, all replays identical). Soaks (`--coop=N --bot --smart-bot`, no errors in
      any): 4 players 15 min with --god (15 rooms, floor 2); 4 players 10 min without (downs,
      help-ups, deaths); 3 players 10 min at DREAD 8 (floor 2); 2 players until both were down.
      Speed here: 3 min of play took 24.7 s for one hero, 33.1 s for four. The test bots for P2 to
      P4 now join whoever is in a doorway after a quarter second (the soak bot leading them backs
      off a door that does not open at once; players are never moved) and close in with melee
      weapons; they make 6 to 23 kills each to the lead bot's 38 to 52, so co-op runs with bots
      are slower than real players would be. On paper, with players of equal skill: a room takes
      about as long as alone with 2 players and about 1.2 times as long with 4; a guardian falls a
      little faster. The README in the Windows zip explains playing together.

- [x] C6 Chests for everyone (his pick, 12 Oct). Done: `Coop.chest_extra` (Game.open_choice: one
      more relic per extra player), `draft_start` (the order after the opener), `draft_next`
      (Game.update_choice: the next player's turn with what is left, their owned relics swapped),
      `choice_x0` (OverlayView and Taps: a row of 4 that follows the chosen card), the order line
      and arrows in `draw_turn`; a test bot takes its pick at once (soaks never wait on a chest); a
      player whose controller is unplugged: anyone can finish their menu (`menu_pad`).
      tests/coop_test.tscn: P3 opens a chest for four, P3, P4, P1 and P2 take one each with their
      own device, none offered one they own. Full check passed, all replays identical; a 5 min
      4-player soak with chests: no errors, never stuck.

## Not done yet (later, if he wants it)

- Clicking menus with the mouse (the keyboard works them; the CO-OP screen takes clicks).
- Saving a co-op run for CONTINUE.
- Two players on one keyboard.
