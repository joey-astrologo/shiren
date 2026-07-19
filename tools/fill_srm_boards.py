#!/usr/bin/env python3
"""Fill every leaderboard in a .srm with 50 test entries.

Each board's entries are cloned from its first existing entry (so stats/
floor/equipment bytes stay realistic for the detail screen), with names
and descending scores substituted. Extension slots cycle through all
display paths:
  default slots  -> 6-char player names ("Hero07")
  slot % 10 == 3 -> 5-char player names ("Pal03")
  slot % 10 == 6 -> ROM default names (flag $80+n, entry name matched)
  slot % 10 == 9 -> legacy 4-char entries ("Ld09")
Count bytes are set to 50 and the extension marker is stamped, so the
in-game lazy init will not overwrite the tables.

Usage: python3 tools/fill_srm_boards.py save.srm [-o out.srm]
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from stamp_srm_ext import BOARDS, ENTRY_SIZE, SLOTS, encode, load_font_map

ALL_DEFAULTS = (BOARDS["impasse"][2] + BOARDS["foodgod"][2]
                + BOARDS["wallscroll"][2] + BOARDS["final"][2])


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("srm", type=Path)
    ap.add_argument("-o", "--out", type=Path, help="output file (default: in place)")
    args = ap.parse_args()

    data = bytearray(args.srm.read_bytes())
    if len(data) != 0x8000:
        sys.exit(f"unexpected .srm size {len(data):#x}")
    enc = load_font_map()

    for board, (entries_off, table_off, _defaults, _flag) in BOARDS.items():
        template = None
        for slot in range(SLOTS):
            off = entries_off + slot * ENTRY_SIZE
            if bytes(data[off:off + 4]) != b"\xFF\xFF\xFF\xFF":
                template = bytes(data[off:off + ENTRY_SIZE])
                break
        if template is None:
            sys.exit(f"{board}: no existing entry to use as template - "
                     "unlock this board in-game first")

        data[table_off:table_off + SLOTS * 3] = b"\xFF" * (SLOTS * 3)
        for slot in range(SLOTS):
            off = entries_off + slot * ENTRY_SIZE
            entry = bytearray(template)
            score = 15000 - slot * 250
            entry[4:6] = score.to_bytes(2, "little")

            ext = data[table_off + slot * 3:table_off + slot * 3 + 3]
            if slot % 10 == 6:
                n = slot % len(ALL_DEFAULTS)
                name = encode(ALL_DEFAULTS[n], enc)
                entry[0:4] = (name[:4] + b"\xFF" * 4)[:4]
                data[table_off + slot * 3 + 2] = 0x80 + n
            elif slot % 10 == 9:
                name = encode(f"Ld{slot:02d}", enc)
                entry[0:4] = name[:4]
                # flag stays $FF: legacy display
            else:
                full = f"Pal{slot:02d}" if slot % 10 == 3 else f"Hero{slot:02d}"
                name = encode(full, enc)
                entry[0:4] = (name[:4] + b"\xFF" * 4)[:4]
                ext = (name[4:6] + b"\xFF\xFF")[:2]
                data[table_off + slot * 3:table_off + slot * 3 + 2] = ext
                data[table_off + slot * 3 + 2] = 0x00
            data[off:off + ENTRY_SIZE] = entry

        data[entries_off - 1] = SLOTS  # count byte at base-1
        print(f"{board:11s} filled with {SLOTS} entries (template slot stats)")

    data[0x7FEA:0x7FEC] = b"\x4C\x58"  # marker: tables are authoritative
    # ranking-region checksum (func_C67EDB): negated 8-bit sum of
    # $B3:6006-7F49, stored at $B3:7F4A; boot wipes the boards if wrong
    data[0x7F4A] = (-sum(data[0x6006:0x7F4A])) & 0xFF
    out = args.out or args.srm
    out.write_bytes(data)
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
