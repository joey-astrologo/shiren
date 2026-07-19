#!/usr/bin/env python3
"""Stamp extended-leaderboard-name tables into a .srm save file.

Test/migration helper for the extension-table scheme (see text.asm
"Extended leaderboard names"). Per board: 50 slots x [char5][char6][flag].
  flag 0xFF  = legacy 4-char entry
  flag 0x00  = player entry, chars 5-6 valid
  flag 0x80+n = default entry, rendered from ROM LeaderboardDefaultNames[n]

Default action FF-fills all four tables, then walks each board's entries
and stamps default flags on entries whose 4-char names match the expected
default names (in order), leaving everything else legacy.

Usage:
  python3 tools/stamp_srm_ext.py save.srm                 # stamp defaults
  python3 tools/stamp_srm_ext.py save.srm --player impasse 0 Shiren
                                        # also stamp a player entry's chars 5-6
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TABLE_PATH = ROOT / "data" / "mainFontMap.tbl"

ENTRY_SIZE = 0x28
SLOTS = 50

# name, entries file offset, ext table file offset, defaults, first flag value
BOARDS = {
    "impasse": (0x6007, 0x1EF0,
                ["Shijima", "Heiji", "Obito", "Tsubute", "Kazura", "Mugura",
                 "Tsumuri", "Kanji", "Jirokichi", "Senzo", "Hanzaki", "Sabu",
                 "Kanpachi", "Tage", "Yamake"], 0x80),
    "foodgod": (0x67D8, 0x3EF0, ["Shopkeep"], 0x8F),
    "wallscroll": (0x6FA9, 0x5EF0,
                   ["Saruyama", "Trainee 2", "Trainee 3",
                    "Trainee 4", "Trainee 5"], 0x90),
    "final": (0x777A, 0x7F53, ["Fei"], 0x95),
}


def load_font_map() -> dict[str, int]:
    enc: dict[str, int] = {}
    for line in TABLE_PATH.read_text().splitlines():
        line = line.rstrip("\r\n")
        if "=" not in line:
            continue
        code, char = line.split("=", 1)
        if len(char) == 1 and ord(" ") <= ord(char) <= ord("~") and char not in enc:
            enc[char] = int(code, 16)
    return enc


def encode(name: str, enc: dict[str, int]) -> bytes:
    try:
        return bytes(enc[c] for c in name)
    except KeyError as e:
        sys.exit(f"character {e} of {name!r} not in font map")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("srm", type=Path)
    ap.add_argument("--player", nargs=3, metavar=("BOARD", "SLOT", "FULLNAME"),
                    help="stamp a player entry's extension chars")
    ap.add_argument("-o", "--out", type=Path, help="output file (default: in place)")
    args = ap.parse_args()

    data = bytearray(args.srm.read_bytes())
    if len(data) != 0x8000:
        sys.exit(f"unexpected .srm size {len(data):#x}")
    enc = load_font_map()

    for board, (entries_off, table_off, defaults, first_flag) in BOARDS.items():
        data[table_off:table_off + SLOTS * 3] = b"\xFF" * (SLOTS * 3)
        cursor = 0
        stamped = []
        for slot in range(SLOTS):
            name4 = bytes(data[entries_off + slot * ENTRY_SIZE:
                               entries_off + slot * ENTRY_SIZE + 4])
            if name4 == b"\xFF\xFF\xFF\xFF" or cursor >= len(defaults):
                continue
            want = encode(defaults[cursor], enc)[:4]
            # short names are padded by the game (space/terminator); match prefix
            if name4[:len(want)] == want:
                data[table_off + slot * 3 + 2] = first_flag + cursor
                stamped.append((slot, defaults[cursor]))
                cursor += 1
        names = ", ".join(f"{s}:{n}" for s, n in stamped) or "none matched"
        print(f"{board:11s} defaults stamped -> {names}")

    if args.player:
        board, slot_s, fullname = args.player
        if board not in BOARDS:
            sys.exit(f"unknown board {board!r} (choose from {list(BOARDS)})")
        slot = int(slot_s)
        entries_off, table_off, _, _ = BOARDS[board]
        full = encode(fullname, enc)
        entry_off = entries_off + slot * ENTRY_SIZE
        data[entry_off:entry_off + 4] = (full[:4] + b"\xFF" * 4)[:4]
        ext = (full[4:6] + b"\xFF\xFF")[:2]
        data[table_off + slot * 3:table_off + slot * 3 + 2] = ext
        data[table_off + slot * 3 + 2] = 0x00
        print(f"{board} slot {slot}: player entry stamped as {fullname!r}")

    out = args.out or args.srm
    out.write_bytes(data)
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
