#!/usr/bin/env python3
"""
Inject a test name into SRAM to verify display without playing the game.

This is useful for testing if modified display code can handle 6+ character names.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def load_font_table(table_path: Path) -> dict[str, int]:
    """Load the font mapping from mainFontMap.tbl."""
    mapping: dict[str, int] = {}
    with table_path.open(encoding="utf-8") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            if not line.strip() or line.startswith(";") or "=" not in line:
                continue
            key_str, value = line.split("=", 1)
            key = int(key_str, 16)
            if value and len(value) == 1 and ord(value) < 128:
                mapping[value] = key
    return mapping


def encode_name(name: str, font_table: dict[str, int], max_len: int = 6) -> bytes:
    """Encode a name to bytes."""
    encoded = []
    for char in name[:max_len]:
        if char not in font_table:
            print(f"Warning: Character '{char}' not in font table, using '?'")
            encoded.append(font_table.get('?', 0xFF))
        else:
            encoded.append(font_table[char])

    # Pad with 0xFF if needed
    while len(encoded) < max_len:
        encoded.append(0xFF)

    return bytes(encoded)


def inject_name(
    srm_path: Path,
    output_path: Path,
    name: str,
    dungeon: str,
    entry_num: int,
    font_table: dict[str, int],
    name_length: int = 6
) -> None:
    """Inject a test name into SRAM."""

    # Leaderboard base addresses
    leaderboards = {
        "impasse": 0x6007,
        "foodgod": 0x67D8,
        "wallscroll": 0x6FA9,
        "final": 0x777A,
    }

    if dungeon not in leaderboards:
        print(f"Error: Unknown dungeon '{dungeon}'")
        print(f"Valid options: {', '.join(leaderboards.keys())}")
        sys.exit(1)

    with srm_path.open("rb") as f:
        data = bytearray(f.read())

    base = leaderboards[dungeon]
    entry_size = 0x28
    offset = base + ((entry_num - 1) * entry_size)

    if offset + name_length > len(data):
        print(f"Error: Offset 0x{offset:04x} is beyond SRAM size")
        sys.exit(1)

    # Encode the name
    encoded_name = encode_name(name, font_table, name_length)

    print(f"Injecting '{name}' into {dungeon} entry {entry_num}")
    print(f"Offset: 0x{offset:04x}")
    print(f"Encoded bytes: {' '.join(f'{b:02x}' for b in encoded_name)}")

    # Write the name
    for i, byte in enumerate(encoded_name):
        data[offset + i] = byte

    # Write the modified SRAM
    with output_path.open("wb") as f:
        f.write(data)

    print(f"\nSuccess! Modified SRAM written to: {output_path}")
    print(f"\nNOTE: This only modifies the name bytes (0-{name_length-1}).")
    print(f"If you extended names to {name_length} chars, bytes 4-5 may conflict with score.")
    print(f"You may need to manually clear or relocate score bytes.")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Inject test name into SRAM for display testing",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Inject "Shiren" (6 chars) into Impasse Valley entry 1
  python3 inject_test_name.py save.srm save_test.srm "Shiren" impasse 1

  # Inject "Player" into Food God Shrine entry 1
  python3 inject_test_name.py save.srm save_test.srm "Player" foodgod 1

Dungeons: impasse, foodgod, wallscroll, final

WARNING: This overwrites name bytes. If extending to 6 chars, bytes 4-5
will conflict with score data. You must relocate score first!
        """
    )
    parser.add_argument("input", type=Path, help="Input .srm file")
    parser.add_argument("output", type=Path, help="Output .srm file")
    parser.add_argument("name", type=str, help="Name to inject (max 6 chars)")
    parser.add_argument(
        "dungeon",
        type=str,
        choices=["impasse", "foodgod", "wallscroll", "final"],
        help="Which dungeon's leaderboard"
    )
    parser.add_argument("entry", type=int, help="Entry number (1-50)")
    parser.add_argument(
        "--length",
        type=int,
        default=6,
        help="Name length to write (default: 6 for extended names)"
    )
    parser.add_argument(
        "--table",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "data" / "mainFontMap.tbl",
        help="Path to mainFontMap.tbl",
    )
    args = parser.parse_args()

    if not args.input.exists():
        print(f"Error: {args.input} not found")
        sys.exit(1)

    if not args.table.exists():
        print(f"Error: Font table {args.table} not found")
        sys.exit(1)

    if args.entry < 1 or args.entry > 50:
        print(f"Error: Entry number must be 1-50")
        sys.exit(1)

    if len(args.name) > args.length:
        print(f"Warning: Name '{args.name}' is longer than {args.length} chars, will be truncated")

    font_table = load_font_table(args.table)
    inject_name(args.input, args.output, args.name, args.dungeon, args.entry, font_table, args.length)


if __name__ == "__main__":
    main()
