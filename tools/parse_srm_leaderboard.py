#!/usr/bin/env python3
"""
Parse leaderboard names from Shiren SFC .srm save file.

The .srm file contains 4 leaderboards, each supporting up to 50 entries:
- Impasse Valley: starts at offset 0x6007 (40 bytes spacing, 15 default entries)
- Food God Shrine: starts at offset 0x67D8 (40 bytes spacing, 1 default entry)
- Wall Scroll Cave: starts at offset 0x6FA9 (40 bytes spacing, 5 default entries)
- Final Problem: starts at offset 0x777A (40 bytes spacing, 1 default entry)

Each entry stores the name as 4 bytes (one per character) using the font encoding
from mainFontMap.tbl. Names are truncated to 4 characters maximum. Empty slots
are filled with 0xFF bytes.
"""

from __future__ import annotations

import argparse
from pathlib import Path

# Load the font mapping table to decode character bytes
def load_font_table(table_path: Path) -> dict[int, str]:
    """Load the font mapping from mainFontMap.tbl, preferring ASCII characters."""
    mapping: dict[int, str] = {}
    with table_path.open(encoding="utf-8") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            stripped = line.strip()
            if not stripped or stripped.startswith(";") or "=" not in line:
                continue
            key_str, value = line.split("=", 1)
            key = int(key_str, 16)
            # Only single character mappings
            if value and len(value) == 1:
                # Prefer ASCII characters over Japanese characters
                # If we already have a mapping and the new value is ASCII, use it
                # If we don't have a mapping yet, or current is non-ASCII and new is ASCII
                if key not in mapping:
                    mapping[key] = value
                elif ord(value) < 128:  # ASCII character
                    mapping[key] = value
                # Otherwise keep the existing mapping (first one wins unless ASCII comes later)
    return mapping


def decode_name(name_bytes: bytes, font_table: dict[int, str]) -> str:
    """Decode a 4-byte name into a string."""
    chars = []
    for byte in name_bytes:
        if byte == 0xff:  # Terminator/padding
            break
        char = font_table.get(byte, f"<{byte:02x}>")
        chars.append(char)
    return "".join(chars)


def parse_leaderboard(srm_path: Path, font_table: dict[int, str]) -> None:
    """Parse and print all leaderboard names from the .srm file."""
    with srm_path.open("rb") as f:
        data = f.read()

    # Leaderboard entry structure:
    # Each entry is 0x28 (40) bytes apart
    # The name is stored as 4 consecutive bytes

    print("=== Shiren SFC Leaderboard Names ===\n")

    # Impasse Valley: up to 50 entries starting at 0x6007
    print("Impasse Valley:")
    base_offset = 0x6007
    entry_size = 0x28  # 40 bytes between entries
    max_entries = 50

    count = 0
    for i in range(max_entries):
        offset = base_offset + (i * entry_size)
        if offset + 4 <= len(data):
            name_bytes = data[offset:offset + 4]
            # Only print if not empty (all 0xFF means empty slot)
            if not all(b == 0xff for b in name_bytes):
                name = decode_name(name_bytes, font_table)
                print(f"  {i+1:2d}. {name}")
                count += 1
    if count == 0:
        print("  (no entries)")

    print()

    # Food God Shrine: up to 50 entries starting at 0x67D8
    print("Food God Shrine:")
    base_offset = 0x67D8
    entry_size = 0x28  # 40 bytes between entries
    max_entries = 50

    count = 0
    for i in range(max_entries):
        offset = base_offset + (i * entry_size)
        if offset + 4 <= len(data):
            name_bytes = data[offset:offset + 4]
            # Only print if not empty
            if not all(b == 0xff for b in name_bytes):
                name = decode_name(name_bytes, font_table)
                print(f"  {i+1:2d}. {name}")
                count += 1
    if count == 0:
        print("  (no entries)")

    print()

    # Wall Scroll Cave: up to 50 entries starting at 0x6FA9
    print("Wall Scroll Cave:")
    base_offset = 0x6FA9
    entry_size = 0x28  # 40 bytes between entries
    max_entries = 50

    count = 0
    for i in range(max_entries):
        offset = base_offset + (i * entry_size)
        if offset + 4 <= len(data):
            name_bytes = data[offset:offset + 4]
            # Only print if not empty
            if not all(b == 0xff for b in name_bytes):
                name = decode_name(name_bytes, font_table)
                print(f"  {i+1:2d}. {name}")
                count += 1
    if count == 0:
        print("  (no entries)")

    print()

    # Final Problem: up to 50 entries starting at 0x777A
    print("Final Problem:")
    base_offset = 0x777A
    entry_size = 0x28  # 40 bytes between entries
    max_entries = 50

    count = 0
    for i in range(max_entries):
        offset = base_offset + (i * entry_size)
        if offset + 4 <= len(data):
            name_bytes = data[offset:offset + 4]
            # Only print if not empty
            if not all(b == 0xff for b in name_bytes):
                name = decode_name(name_bytes, font_table)
                print(f"  {i+1:2d}. {name}")
                count += 1
    if count == 0:
        print("  (no entries)")

    print("\n" + "="*40)
    print("Note: Names are stored as 4 characters max.")
    print("Full default names in text/leaderboard.asm:")
    print("  Impasse Valley: Shijima, Heiji, Obito, Tsubute, Kazura,")
    print("                  Mugura, Tsumuri, Kanji, Jirokichi, Senzo,")
    print("                  Hanzaki, Sabu, Kanpachi, Tage, Yamake")
    print("  Food God Shrine: Shopkeeper")
    print("  Wall Scroll Cave: Saruyama, Apprentice 2-5")
    print("  Final Problem: Fei")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Parse leaderboard names from Shiren SFC .srm file",
        epilog="""
Examples:
  %(prog)s shiren-aeon-genesis.srm
  %(prog)s path/to/save.srm --table data/mainFontMap.tbl

This script extracts the 4-character names stored in the leaderboard
sections of a Shiren SFC save file (.srm). It uses the font mapping
from mainFontMap.tbl to decode the character bytes.
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "srm_file",
        type=Path,
        help="Path to the .srm save file",
    )
    parser.add_argument(
        "--table",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "data" / "mainFontMap.tbl",
        help="Path to mainFontMap.tbl (default: ../data/mainFontMap.tbl)",
    )
    args = parser.parse_args()

    if not args.srm_file.exists():
        print(f"Error: {args.srm_file} not found")
        return

    if not args.table.exists():
        print(f"Error: Font table {args.table} not found")
        return

    font_table = load_font_table(args.table)
    parse_leaderboard(args.srm_file, font_table)


if __name__ == "__main__":
    main()
