#!/usr/bin/env python3
"""
Monitor SRAM changes during gameplay to track leaderboard modifications.

Usage:
1. Take SRAM snapshot before action (save .srm file)
2. Perform game action (die, view rankings, etc.)
3. Take SRAM snapshot after action
4. Run this script to see what changed
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def load_font_table(table_path: Path) -> dict[int, str]:
    """Load the font mapping from mainFontMap.tbl."""
    mapping: dict[int, str] = {}
    with table_path.open(encoding="utf-8") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            if not line.strip() or line.startswith(";") or "=" not in line:
                continue
            key_str, value = line.split("=", 1)
            key = int(key_str, 16)
            if value and len(value) == 1 and ord(value) < 128:
                mapping[key] = value
    return mapping


def decode_name(data: bytes, offset: int, font_table: dict[int, str]) -> str:
    """Decode a 4-byte name from data."""
    name_bytes = data[offset:offset + 4]
    chars = []
    for byte in name_bytes:
        if byte == 0xff:
            break
        char = font_table.get(byte, f"<{byte:02x}>")
        chars.append(char)
    return "".join(chars)


def compare_sram(
    before_path: Path,
    after_path: Path,
    font_table: dict[int, str]
) -> None:
    """Compare two SRAM files and show differences."""

    with before_path.open("rb") as f:
        before = f.read()

    with after_path.open("rb") as f:
        after = f.read()

    if len(before) != len(after):
        print(f"ERROR: File sizes differ ({len(before)} vs {len(after)})")
        return

    # Find all differences
    differences = []
    i = 0
    while i < len(before):
        if before[i] != after[i]:
            # Found a difference, collect consecutive changed bytes
            start = i
            while i < len(before) and before[i] != after[i]:
                i += 1
            end = i
            differences.append((start, end))
        else:
            i += 1

    if not differences:
        print("No differences found.")
        return

    print(f"Found {len(differences)} changed region(s):\n")

    # Known leaderboard regions
    leaderboards = [
        ("Impasse Valley", 0x6007, 0x28, 50),
        ("Food God Shrine", 0x67D8, 0x28, 50),
        ("Wall Scroll Cave", 0x6FA9, 0x28, 50),
        ("Final Problem", 0x777A, 0x28, 50),
    ]

    for start, end in differences:
        size = end - start
        print(f"Offset 0x{start:04x} - 0x{end:04x} ({size} bytes changed)")

        # Check if this is in a known leaderboard region
        in_leaderboard = False
        for name, base, entry_size, max_entries in leaderboards:
            lb_end = base + (entry_size * max_entries)
            if base <= start < lb_end:
                # Calculate which entry
                offset_from_base = start - base
                entry_num = offset_from_base // entry_size
                offset_in_entry = offset_from_base % entry_size

                print(f"  → {name} leaderboard")
                print(f"  → Entry {entry_num + 1}, offset +{offset_in_entry} within entry")

                # If it's at the name position (offset 0-3)
                if 0 <= offset_in_entry < 4:
                    before_name = decode_name(before, base + (entry_num * entry_size), font_table)
                    after_name = decode_name(after, base + (entry_num * entry_size), font_table)
                    print(f"  → Name changed: '{before_name}' → '{after_name}'")

                # If it's at the score position (offset 4-5)
                elif 4 <= offset_in_entry < 6:
                    entry_offset = base + (entry_num * entry_size)
                    before_score = before[entry_offset + 4] | (before[entry_offset + 5] << 8)
                    after_score = after[entry_offset + 4] | (after[entry_offset + 5] << 8)
                    print(f"  → Score changed: {before_score} → {after_score}")

                in_leaderboard = True
                break

        if not in_leaderboard:
            print(f"  → Not in known leaderboard region")

        # Show hex diff
        print(f"  Before: {' '.join(f'{b:02x}' for b in before[start:end])}")
        print(f"  After:  {' '.join(f'{b:02x}' for b in after[start:end])}")

        # Try to show as ASCII
        before_ascii = ''.join(chr(b) if 32 <= b < 127 else '.' for b in before[start:end])
        after_ascii = ''.join(chr(b) if 32 <= b < 127 else '.' for b in after[start:end])
        if before_ascii.strip('.'):
            print(f"  ASCII:  '{before_ascii}' → '{after_ascii}'")

        print()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Monitor SRAM changes between two snapshots",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Example workflow:
  1. cp save.srm save_before.srm
  2. (play game, die, view rankings, etc.)
  3. cp save.srm save_after.srm
  4. python3 monitor_sram_changes.py save_before.srm save_after.srm

This helps identify exactly which memory addresses are modified
during leaderboard operations.
        """
    )
    parser.add_argument("before", type=Path, help="SRAM file before action")
    parser.add_argument("after", type=Path, help="SRAM file after action")
    parser.add_argument(
        "--table",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "data" / "mainFontMap.tbl",
        help="Path to mainFontMap.tbl",
    )
    args = parser.parse_args()

    if not args.before.exists():
        print(f"Error: {args.before} not found")
        sys.exit(1)

    if not args.after.exists():
        print(f"Error: {args.after} not found")
        sys.exit(1)

    font_table = {}
    if args.table.exists():
        font_table = load_font_table(args.table)

    compare_sram(args.before, args.after, font_table)


if __name__ == "__main__":
    main()
