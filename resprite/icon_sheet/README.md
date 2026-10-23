# His icon sheet (V2 only, personal use)

`sheet.png`: the icon sheet he sent on 23 Oct ("some playful 16x sprites", r/PixelArt). Its artist's
note: "they were commissioned work for a project that since went under, so feel free to rip them
for solely personal use, but not anything involving redistributing / using for public purposes".
So (CLAUDE.md, rule 3, his exception): only on branch tiny-biggot-V2, only while the repo is
private, only in the game he plays himself. Never on claude/dev, ios-build or windows-build, never
in a copy shared with anyone. The brand logos, flags, letters and emoji faces are never used.
If the repo is ever made public again, these pictures must come out first (git history keeps them).

`python3 -I cut.py sheet.png OUT`: cuts it into single icons (the background, the drop shadow and
the panel frames left out), `OUT/i000.png` ... and `OUT/boxes.txt`. Index numbers in the game's
notes (ROADMAP.md, 59.5) are these.

Used so far (59.5): 26 weapons (w_*), 10 pets (pet_*), 31 foods (f_*), 10 drinks (c_*). Each
picture is the icon as it is, one pixel to each of the game's (no new-look picture: the game draws
it as it is). Weapons sit on an even square so they turn about their middle in the hand.
