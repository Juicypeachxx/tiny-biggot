# Art sample for ROADMAP 5.1

`sprites.py`: the redrawn sample (hero, three foes, the Colossus, hearts, five weapon icons) as
pixel grids. `render.py`: colours them in one of three looks (A crisp, B grim, C glow) and draws
the Ossuary floor tiles (`kit0`). `python3 sheet.py out.png` writes every look to `out/<A|B|C>/`
and a comparison sheet. Run it outside the project (it writes `out/` next to the working dir).
Nothing here is in the game until he picks a look.
