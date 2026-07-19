# Leaderboard .srm File Format

Structure of leaderboard data in Shiren SFC save files (.srm), including the
extended-name scheme implemented on this branch.

## SRAM banks

32KB .srm = 4 banks x 8KB, each mapped at $6000-$7FFF:

| Bank | File offset | Contents |
|------|-------------|----------|
| $B0  | 0x0000      | Journal 1 game data; save block at $7B58; ext table (Impasse) at $7EF0 |
| $B1  | 0x2000      | Journal 2 game data; save block at $7B58; ext table (Food God) at $7EF0 |
| $B2  | 0x4000      | Journal 3 game data; save block at $7B58; ext table (Wall Scroll) at $7EF0 |
| $B3  | 0x6000      | All 4 leaderboards (shared across journals); ext table (Final) at $7F53 |

Each journal's save block ($7B58-$7EBF, 0x368 bytes) carries a "VAL" signature
and checksum (see bank_03 `func_C3E66B` area table). The player's name (up to
6 chars) is at save block +4.

## Leaderboards (bank $B3)

4 boards, 50 entries x 40 bytes (0x28), count byte at base-1:

| Board            | Entries base | Ext table        | Defaults |
|------------------|--------------|------------------|----------|
| Impasse Valley   | $B3:6007     | $B0:7EF0         | 15 (Shijima..Yamake) |
| Food God Shrine  | $B3:67D8     | $B1:7EF0         | Shopkeep (slot 1) |
| Wall Scroll Cave | $B3:6FA9     | $B2:7EF0         | Saruyama, Trainee 2-5 (slots 1-5) |
| Final Problem    | $B3:777A     | $B3:7F53         | Fei (slot 0) |

Entry layout: +0..3 name (4 chars, font codes, $FF pad / $00 space pad),
+4..5 score (16-bit LE), +6.. stats (level, HP, floor, equipment...).
"HISCORE\xF3" marker at $B3:7F4B-7F52; when absent the game re-initializes
all boards (func_C67821).

## Extended names (this branch)

The 4-char entry field is untouched. Each board has a parallel extension
table in proven-free SRAM: 50 slots x 3 bytes `[char5][char6][flag]`:

- flag `$FF` — legacy entry: stock 4-char display
- flag `$00` — player entry: chars 5-6 valid ($FF = name is <5 chars)
- flag `$80+n` — default entry: full name rendered from the ROM
  `LeaderboardDefaultNames` table (22 names, text.asm)

Marker `$4C $58` at $B3:7FEA-7FEB; staging buffer for display at $B3:7FF0.
When the marker is absent (fresh save, pre-extension save, post-wipe) the
tables rebuild lazily: FF-fill, then order-match entry names against the
ROM defaults (with $FF-wildcard padding) and stamp default flags.

Code map (all new code at the end of text.asm, bank $FF):
- `func_LbExtName` — display hook (bank_04 print-string text command)
- `func_LbGlyphShift` — VWF compositor shift fix (bank_06 func_C67008)
- `func_LbExtInit` / `func_LbExtSaveInit` — lazy init + wipe invalidation
- `func_LbExtInsert` — insert hook (bank_06 func_C630A3/func_C630C1)
- `func_LbSubStart` / `func_LbPopClip` — 27-glyph clip with "..." for
  variable strings (death causes, equipment) on the board/detail screens
  (bank_06 func_C66D6B loop; counter at $B3:7FF7)

Display limit: the ranking rows fit ~9 characters, hence the shortened
default names. Player names cap at 6 (game-wide name length).

## Tools

- `tools/parse_srm_leaderboard.py` — decode board entries from a .srm
- `tools/stamp_srm_ext.py` — stamp/inspect extension tables (mostly
  obsolete now that tables self-initialize; useful for tests)
- `tools/mesen_sram_watch.lua` — Mesen 2 write-watch for SRAM regions
- `tools/monitor_sram_changes.py`, `tools/inject_test_name.py` — general
  SRAM diffing/injection helpers

## Font encoding

Names use `data/mainFontMap.tbl` codes (one byte per char). `$FF` = @ =
terminator/padding, `$00` = space. Short names may be space-padded by the
game; matching code treats ROM `$FF` padding as a wildcard for this reason.
