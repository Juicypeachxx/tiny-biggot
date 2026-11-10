TINY BIGGOT: NEW PICTURES WITH GEMINI (test on the branch tiny-biggot-V2)

What is in here
- sheets/: 46 pictures. 00-try-me-first.png is a small test; 01 to 45 hold every picture of the
  game (heroes, foes, guardians, people, room things, weapons, gear, relics, traits, icons), the
  important ones first. Each game picture sits on a pink box; each big square is one game pixel.
- PROMPT.txt: the text to give Gemini.

What to do
1. Open Gemini (app or gemini.google.com) and pick the model that makes and edits pictures.
2. Start with 00-try-me-first.png: attach it and paste the first part of PROMPT.txt. Change the
   STYLE line to the look you want. Download the picture Gemini makes.
3. If you like it, stay in the same chat: attach 01-heroes.png and write the short line at the
   bottom of PROMPT.txt. Download it. Then 02, 03 and so on. Heroes, foes and guardians matter
   most; you can stop at any time: what you do not send back keeps the old look.
4. Save each result with the same name as its sheet (01-heroes.png, 02-foes.png...); jpg is fine.
5. Put them on GitHub: github.com/Juicypeachxx/tiny-biggot, switch to the branch tiny-biggot-V2,
   open the folder resprite/done, "Add file", "Upload files", drop them in, "Commit changes".
   (Or send them to Claude in the chat.)
6. Tell Claude "import": Claude puts them in the game, checks it and builds the IPA.

If Gemini goes wrong
- It moved boxes, changed the grid, made it not square or added text: say "Keep the exact layout,
  only redraw inside the pink boxes" and try again.
- A bigger or smaller picture is fine (Claude scales it back), as long as the layout is the same.

Good to know
- The game screen is 448 x 288 pixels, so every picture keeps its size (most are 12 or 16 pixels).
  Gemini's drawing is shrunk back to that: the new look comes through in the shapes and colours,
  not in finer detail.
- Made automatically from the new pictures: the elite foes (darker, gold outline) and the
  guardians' angry later phases.
- Kept as they are: the letters, floor and wall tiles, shadows, glows, sparks and shots.
