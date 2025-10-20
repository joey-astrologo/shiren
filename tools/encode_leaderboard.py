#!/usr/bin/env python3
"""
Utility script to convert leaderboard names into tile-coded 16-bit values.

Reads the font mapping from data/mainFontMap.tbl and emits .dw directives
for the default leaderboard names so they can be pasted into
text/leaderboard.asm. Each character is mapped to its corresponding byte code
and stored as a 16-bit word with a zero high byte. An explicit $00FF terminator
is appended to mirror the old endtext marker.
"""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TABLE_PATH = ROOT / "data" / "mainFontMap.tbl"

DEFAULT_NAMES = [
    "Shijima",
    "Heiji",
    "Obito",
    "Tsubute",
    "Kazura",
    "Mugura",
    "Tsumuri",
    "Kanji",
    "Jirokichi",
    "Senzo",
    "Hanzaki",
    "Sabu",
    "Kanpachi",
    "Tage",
    "Yamake",
    "Shopkeeper",
    "Saruyama",
    "Apprentice 2",
    "Apprentice 3",
    "Apprentice 4",
    "Apprentice 5",
    "Fei",
]


def load_table(path: Path) -> dict[str, int]:
    mapping: dict[str, int] = {}
    with path.open(encoding="utf-8") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            stripped = line.strip()
            if not stripped or stripped.startswith(";") or "=" not in line:
                continue
            key_str, value = line.split("=", 1)
            key = int(key_str, 16)
            # The table may contain multi-character sequences (control codes),
            # but we only need entries that represent a single glyph.
            if not value:
                continue
            if len(value) > 1:
                # Ignore multicharacter tokens like control sequences.
                continue
            mapping[value] = key
    return mapping


MAX_LEN = 16


def encode_name(name: str, table: dict[str, int]) -> list[int]:
    codes: list[int] = []
    for ch in name:
        if ch not in table:
            raise KeyError(f"No mapping for character {ch!r}")
        codes.append(table[ch])
    # pad with '@' (tile id FF) and terminate with FF if needed
    if len(codes) >= MAX_LEN:
        # ensure terminator is present
        if codes[-1] != 0xFF:
            codes.append(0xFF)
    else:
        codes.append(0xFF)
    while len(codes) < MAX_LEN:
        codes.append(0xFF)
    return codes[:MAX_LEN]


def format_db(values: list[int]) -> str:
    # Format up to sixteen entries per line for readability.
    chunks = []
    for i in range(0, len(values), 16):
        chunk = values[i : i + 16]
        rendered = ", ".join(f"${code:02X}" for code in chunk)
        chunks.append(f"\t.db {rendered}")
    return "\n".join(chunks)


def main() -> None:
    parser = argparse.ArgumentParser(description="Encode leaderboard names.")
    parser.add_argument(
        "--table",
        type=Path,
        default=TABLE_PATH,
        help="Path to main font map table.",
    )
    args = parser.parse_args()

    table = load_table(args.table)
    for idx, name in enumerate(DEFAULT_NAMES, start=1312):
        codes = encode_name(name, table)
        block = format_db(codes)
        print(f"; Text{idx}")
        print(block)
        print()


if __name__ == "__main__":
    main()
