# Shiren SFC Leaderboards — Extended Names

The leaderboards on this branch display full-length names with correct
proportional spacing on all four boards, record up to 6 characters of the
player's name, and stay compatible with old saves. This replaces the Aeon
Genesis hack's partial scheme (which only covered Impasse Valley and broke
name saving).

**[LEADERBOARD_SRM_FORMAT.md](LEADERBOARD_SRM_FORMAT.md)** is the reference:
SRAM layout, extension-table format, code map, tools.

## How it works (summary)

- The original 40-byte entries (4-char name, score, stats, sorting) are
  never touched — zero risk to scores or ranking order.
- A parallel 3-byte-per-slot extension table per board (in proven-free
  SRAM tails) supplies name chars 5-6 or flags an entry as a default,
  rendered full-length from a ROM table ("Jirokichi", "Shopkeep", ...).
- Ranking names render through the text engine with the restored VWF
  glyph-shift fix, so spacing matches dialogue quality.
- Tables self-initialize (fresh saves, old saves, post-wipe) via a marker,
  and the insert hook keeps them in lockstep when new runs land on a board.

## History / lessons (for future archaeology)

- The AG hack stored 16-char names for 51 global slots split across three
  272-byte SRAM tails; boards other than Impasse computed slot indices past
  the table end and read open bus — that was the "garbage names" bug.
- Banks $B1/$B2 look empty but belong to journals 2/3 (verified with a
  Mesen write-watch: creating a second journal writes ~2.2KB to $B1) — do
  not claim their main regions.
- The mysterious spacing bug was a single reverted 4-byte AG patch in the
  bank_06 compositor (shift by remaining-cell-pixels, not char width).
- Mesen 2 defaults to random RAM power-on: fresh SRAM looks like data.
  FF-fill regions before drawing conclusions from .srm files, and remember
  .srm only flushes to disk when the ROM closes.
- BREAKPOINT_CHEATSHEET.md predates this implementation and is kept as
  general emulator-debugging reference material.
