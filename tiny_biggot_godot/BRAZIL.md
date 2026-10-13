# "You're going to Brazil" (his ask, 6 Oct)

An easter egg, expanded game only (`scripts/game/brazil.gd`).

- **THE HAGGLER**: once a run, rarely (3% a wave, floors 1-10), a junk peddler under a huge hat
  joins a fight ("HE WANTS A WORD. DON'T LET HIM CATCH YOU"). 900 health (grows with the floor),
  walks after you. Kill him: 30 coins, 6 gems, his gun **HAGGLER'S BARGAIN** and his **HAGGLER'S
  HAT**. If he touches you: "YOU'RE GOING TO BRAZIL!" and you are dragged there.
- **BRAZIL**: a dark, grimy, foggy wasteland of its own tiles. **SCROUNGERS** (scrap rats with
  goggles) nag you without end ("SPARE A COIN?", "GIVE GIVE GIVE"...) and every touch picks your
  pocket (3 + floor gold; half comes back if you kill the thief). Two fights, then:
- **THE HOLY COW**: moo rings, milk rain, an udder spray, a charge, scroungers. Harder below half
  health. When it falls it **rises again** ("IT WAS ONLY RESTING") at full health with a new move
  set: it ascends and crashes down, a holy spiral, phantom stampedes down lit lanes, halos. Beaten:
  its hoard, the **COW MILKER**, and the way back to your floor.

Prizes, never found anywhere else (`Weapons.UNIQUE`, `Gear.random_gear`):
- COW MILKER: a milk sprayer (fast, chills); every 30th squirt "MOO!" rings out 16 milk shots;
  5% of kills heal half a heart.
- HAGGLER'S BARGAIN: +10% damage per 100 gold; a fifth of hits pay 1 gold; every 12th shot throws
  5 coins.
- HAGGLER'S HAT: +2 luck, prices -15%, purchases pay 10 gold back, scroungers can't rob you.

He asked for gypsies as the robbers; they are scrap rats here (a real people is never the joke).

Tests: `tests/realms_test.tscn` part 4 (caught -> Brazil, robbed, the hat, the way to the cow, the
third stage, the prizes, prizes never in random drops; the cow's attacks in part 3). Soaks: 5 x 10
minutes, 0 errors.
