#!/usr/bin/env python3
"""
Analyze the structure of ranking entries to determine if bytes 4-5 can be
safely repurposed for extending names from 4 to 6 characters.

This script examines the non-name bytes in ranking entries to identify patterns
and understand what data is stored there.
"""

from __future__ import annotations

import argparse
from pathlib import Path


def analyze_entry(data: bytes, offset: int, entry_num: int, name: str) -> None:
    """Analyze a single 40-byte ranking entry."""
    entry = data[offset:offset + 0x28]

    if len(entry) < 0x28:
        print(f"  Entry {entry_num}: TRUNCATED")
        return

    # Skip empty entries
    if all(b == 0xff for b in entry[:4]):
        return

    print(f"\n  Entry {entry_num}: {name}")
    print(f"  Offset: 0x{offset:04x}")

    # Name (bytes 0-3)
    name_bytes = entry[0:4]
    print(f"    Bytes 0-3 (name):     {' '.join(f'{b:02x}' for b in name_bytes)}")

    # Bytes 4-5 (potentially available for name extension)
    bytes_4_5 = entry[4:6]
    print(f"    Bytes 4-5 (???):      {' '.join(f'{b:02x}' for b in bytes_4_5)}  <- ANALYZE THESE")

    # Try to interpret as little-endian 16-bit value
    value_le = bytes_4_5[0] | (bytes_4_5[1] << 8)
    print(f"      As 16-bit LE:       {value_le:5d} (0x{value_le:04x})")

    # Rest of entry
    print(f"    Bytes 6-7:            {' '.join(f'{b:02x}' for b in entry[6:8])}")
    print(f"    Bytes 8-11:           {' '.join(f'{b:02x}' for b in entry[8:12])}")
    print(f"    Bytes 12-15:          {' '.join(f'{b:02x}' for b in entry[12:16])}")
    print(f"    Bytes 16-19:          {' '.join(f'{b:02x}' for b in entry[16:20])}")
    print(f"    Bytes 20-23:          {' '.join(f'{b:02x}' for b in entry[20:24])}")
    print(f"    Bytes 24-27:          {' '.join(f'{b:02x}' for b in entry[24:28])}")
    print(f"    Bytes 28-31:          {' '.join(f'{b:02x}' for b in entry[28:32])}")
    print(f"    Bytes 32-35:          {' '.join(f'{b:02x}' for b in entry[32:36])}")
    print(f"    Bytes 36-39:          {' '.join(f'{b:02x}' for b in entry[36:40])}")


def analyze_leaderboard(
    data: bytes,
    base_offset: int,
    name: str,
    entry_names: list[str] | None = None
) -> None:
    """Analyze all entries in a leaderboard."""
    print(f"\n{'='*70}")
    print(f"{name} Leaderboard (starting at 0x{base_offset:04x})")
    print('='*70)

    entry_size = 0x28
    max_entries = 10  # Only analyze first 10 for brevity

    for i in range(max_entries):
        offset = base_offset + (i * entry_size)
        if offset + 4 > len(data):
            break

        # Get entry name if provided
        entry_name = entry_names[i] if entry_names and i < len(entry_names) else "???"

        analyze_entry(data, offset, i + 1, entry_name)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Analyze ranking entry structure to determine extension feasibility"
    )
    parser.add_argument(
        "srm_file",
        type=Path,
        help="Path to the .srm save file",
    )
    args = parser.parse_args()

    if not args.srm_file.exists():
        print(f"Error: {args.srm_file} not found")
        return

    with args.srm_file.open("rb") as f:
        data = f.read()

    print("Ranking Entry Structure Analysis")
    print("="*70)
    print("\nPurpose: Determine if bytes 4-5 can be repurposed for name extension")
    print("Goal: Extend names from 4 characters to 6 characters")

    # Analyze each leaderboard
    analyze_leaderboard(
        data,
        0x6007,
        "Impasse Valley",
        ["Shij", "Heij", "Obit", "Tsub", "Kazu", "Mugu", "Tsum", "Kanj",
         "Jiro", "Senz"]
    )

    analyze_leaderboard(
        data,
        0x67D8,
        "Food God Shrine",
        ["Shir", "Shop"]
    )

    analyze_leaderboard(
        data,
        0x6FA9,
        "Wall Scroll Cave",
        ["Saru", "Appr", "Appr", "Appr", "Appr"]
    )

    analyze_leaderboard(
        data,
        0x777A,
        "Final Problem",
        ["Fei"]
    )

    print("\n" + "="*70)
    print("Analysis Summary")
    print("="*70)
    print("\nLook for patterns in bytes 4-5:")
    print("- If always 0x00 or 0xFF: Likely unused padding (SAFE to use)")
    print("- If incrementing values: Likely rank/position counter")
    print("- If large values: Likely score (16-bit little-endian)")
    print("- If small values: Likely level or floor number")
    print("\nIf bytes 4-5 contain important data:")
    print("- Option 1: Relocate that data to bytes 36-39 (if unused)")
    print("- Option 2: Compress/combine data in other bytes")
    print("- Option 3: Stay at 4 characters (safest)")


if __name__ == "__main__":
    main()
