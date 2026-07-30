# Mystery Dungeon: Shiren the Wanderer (SFC) — Translation Fixes Addendum

An unofficial addendum patch for the Aeon Genesis English translation of
*Fushigi no Dungeon 2: Fuurai no Shiren*. Apply over a ROM already patched
with the Aeon Genesis translation.

## How to apply

1. Start from a *Fushigi no Dungeon 2: Fuurai no Shiren* (SFC) ROM that
   already has the Aeon Genesis translation patch applied.
2. Apply this addendum's .ips file to that patched ROM using any IPS
   patcher (e.g. Floating IPS / Lunar IPS).

Do not apply this patch to an unpatched Japanese ROM — it must go on top
of the Aeon Genesis translation.

## Fixed

### Leaderboards / Rankings
- **Full-length English names on all four leaderboards.** The original
  hack's extended-name scheme only worked for Impasse Valley; the other
  boards read past the end of their name table and displayed garbage.
  Names now render correctly everywhere.
- **Overlong ranking subtitles and detail lines are clipped with "…"**
  instead of overflowing the window.
- **Sealed-equipment markers on the ranking detail screen** now display
  correctly (star placement was garbled or missing).
- **Existing save files:** leaderboards on an existing .srm may not look
  correct; full behavior is only guaranteed on a fresh save.

### Text / Messages
- **Fixed a stray Japanese character after "Eat" in the item action
  menu** — a leftover glyph from the original たべる that the
  translation missed.
- **Fixed "Remove" being cut off in the item action menu** — the action
  menu window was one tile too narrow for the longest English verb;
  widened it so equipped-item options display in full.
- **Fixed nine messages that displayed as blank or cut-off boxes.** The
  translation had dropped a trailing line-break, so the text never
  flushed to the screen — most visibly the "[item] dropped." box when a
  thrown item or dodged arrow lands on the floor (now shows the item
  name, e.g. "Wood Arrow dropped."), plus the chrome-coating, insomnia,
  staff-binding, monster-in-disguise, and dance messages, among others.
- **Fixed the "item stolen" message sequence** — corrected message flow
  and line printing when a monster steals an item.
- **Fixed overlapping seal descriptions in the item detail popup.** On
  heavily-sealed equipment, one seal description contained a stray line
  break that overprinted the seals below it and pushed text out of the
  window. All seal descriptions now fit correctly, verified up to the
  12-seal maximum.
- **Fixed two lines that ran past the window edge and split mid-word.**
  The renderer has no word wrapping — it breaks a line wherever it runs
  out of room — so a line that is too long loses its tail to the next
  row. The Plump Man's "The Golden Condor was beautiful." line was
  missing a line break before the following sentence, so it printed
  "beautiful.It sparkled so wonderfully i / n"; the Slippery Scroll's
  description was missing the break before its "Scribe:" credit that
  every other item description has.

### Signs
- **Fixed the Mountaintop Restaurant "Gakeppuchi" sign** pushing its
  closing quote onto a second, otherwise empty sign board. The sign's
  left padding was inherited from the shorter Japanese text, leaving the
  English name a couple of pixels too wide for the board.
- **Fixed the Golden City "This is the other side of the Earth" sign**,
  which was badly garbled — it kept the Japanese full-width bracket
  layout, where padding pushes a closing bracket out to the right edge,
  around English text nearly twice as wide as the kanji it replaced.
- **Fixed the "New store changed! / Restaurant Togeya" sign** splitting
  across two boards instead of showing both lines on one, and a stray
  empty board after the "Alleycat's path" sign. Both were caused by
  leftover padding that positioned a Japanese closing bracket the
  English text no longer has.

### Floor / area titles
- **Fixed the floor announcement banner mangling two-digit floor numbers
  in dungeons with long English names.** On floors 10 and up in the Cave
  of the Wall Scroll and the Shrine of the Food God (and at the Foot of
  the Rainbow), the tens digit was drawn one column left of the screen
  and wrapped onto the row above — showing "6 Cave of the Wall Scroll"
  with a stray "1" split across the right and left edges. Those titles
  were positioned one column too far left for the number to fit; they now
  start where the original Japanese put its own full-width title, so
  "16 Cave of the Wall Scroll" fits on one line.

## Notes
- This is a fan-made addendum and is not affiliated with the original
  translation's authors.
