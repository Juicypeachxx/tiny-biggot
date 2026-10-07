# The story (Stage 12)

His ask (6 Oct): "make some story, add new npc and final bosses and hidden final bosses that fit
into the story and game progress with new stages and environments, like a new dlc". Everything
here is this game's own. Expanded game only.

## What the world is

The world is a book, and it is still being written by **THE AUTHOR**. Each floor is a chapter and
each guardian a page that bites. **The Pale Regent** was the Author's first villain and was never
meant to win; after him the ink ran wild. **The Umbral Sun** is no sun: it is a blot, a drop of ink
on the sky. Past it lie the margins, where the Author scribbled **Heaven** and **Hell**: the
Judge and the Cinder King are notes in the margin. **The Unwritten** is the blank page that eats
stories that never end; beating it gives it one that does.

## Chapter II: THE MARGINS (12.2 - 12.3)

When the Unwritten falls the run can end there (a win, as before) or **turn the page** into the
Author's workshop, three new floors:
1. **THE INKWELL**: a sea of black ink, ink-born foes.
2. **THE BINDERY**: stitched paper, binding presses, paper foes.
3. **THE QUILL SPIRE**: the climb to the Author's desk.

**THE AUTHOR** waits at the top and wants to close the book: the chapter's final boss.
**Three TORN PAGES** are hidden in the chapter's hidden rooms. Carry all three to the Author and,
when it falls, a door opens that should not exist: **THE REDACTOR**, the eraser that blots out
even authors: the hidden final boss.

## Chapter III: THE APPENDIX (14.4)

When the Redactor is erased, the run can end (a win) or **read on**. The words the Redactor erased
did not vanish: they gather at the back of the book. Three floors:
1. **THE GLOSSARY**: pale pages of loose letters and words. Guardian **THE LEXICON**, a swarm of
   every word at once (mini: the Lexicant).
2. **THE FOOTNOTES**: the cramped bottom of the page, asterisks and small print. Guardian **THE
   ERRATUM**, the one mistake nobody fixed (mini: the Fine Print).
3. **THE COVER**: the leather and gold outside the book. Guardian **THE READER**, the one who has
   been turning the pages all along (mini: the Colophon). Its fall ends the run: "THE END. WRITTEN
   BY YOU". +600 embers.

## The people

- **THE ARCHIVIST** (12.1, done): an old ghost of a librarian by the fire at rest stops. He tells
  the story a line at a time, as far as the player has ever reached (kept between runs:
  `Meta.meta["story"]`, `story_heard`). A "!" over him: something new to hear.
- **THE INKLING** (12.2, done): a drop of ink loose from the page. It wanders into cleared fights
  on the chapter's floors (once a floor, 35%); talk to it and it drips on a wall: a hidden door
  opens (the torn pages hide behind such walls).
- **THE BOOKBINDER** (12.2, done): at the chapter's rest stops; sells one relic bound in a cover.

## The torn pages (12.3, done)

One TORN PAGE lies in the first hidden room found on each chapter floor (`Story.hide_page`). With
all three carried, the Author's fall burns them and opens a door (`n_redactdoor`) beside the book:
close the book (a win) or step through to THE REDACTED, a black room, and **THE REDACTOR** (3800
health, three stages of chaos). Its fall wins the run: +500 embers, `redactor_wins`.

## Milestones (`Story.reach`)

f6 the Pale Regent falls; f11 the Umbral Sun falls; realm a realm's ruler falls; unwritten the
Unwritten falls; ch2 Chapter II begun; author the Author falls; redactor the Redactor falls; ch3
Chapter III begun; reader the Reader falls.
