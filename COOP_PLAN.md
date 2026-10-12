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

- **Joining.** On the hero screen each device joins with its confirm button (keyboard: Enter or a
  mouse click; controller: A), up to 4. Each player moves their own coloured frame (P1 red, P2 blue,
  P3 green, P4 gold) over the heroes and confirms; the run starts when every joined player is ready.
  A device that joins counts as that player for the whole run.
- **Controls.** Keyboard and mouse: move with the keys, aim with the mouse, hold the left button to
  fire at the cursor, the right button rolls; everything else on its keys. Controller: left stick
  moves, the right stick aims at its true angle, the buttons as now. Autofire works for everyone.
- **One screen.** Every room fits the screen, so no split screen and no camera: all heroes are in the
  room together, each with a coloured ring and a P1 to P4 tag.
- **Drops.** Coins, hearts, potions, keys, bombs, food and belt items go to whoever touches them
  (as in Brotato: not shared). A chest, a pedestal, a shop ware: the player who opens or buys it
  chooses and pays from their own gold. Gold, keys and bombs are each player's own.
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
- **Menus.** Any player can pause; the pause menu, the gear page and the belt belong to the player who
  pressed. Choice screens show whose turn it is.
- **Saving.** A co-op run is not saved for CONTINUE yet; the unlocks, embers and dust it earns are.

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
- [ ] C2 Co-op core: `G.players`, `--coop=N` for tests (bots for the others), every hero moves, aims
      and shoots with their own device, foes chase the nearest hero, foe shots hit any hero, shots
      count for their owner, each hero drawn with their ring and tag, a small HUD for each.
- [ ] C3 The rules: down and revive, drops and gold per player, experience and level-ups in turn,
      chests and shops per player, the party through a door, difficulty per player.
- [ ] C4 Joining on the hero screen (up to 4 devices), whose turn it is on choice screens, pause and
      gear per player.
- [ ] C5 A test for all of it, 4-player bot soaks, the Windows build.
