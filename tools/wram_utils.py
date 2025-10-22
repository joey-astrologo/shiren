#!/usr/bin/env python3
"""
Utilities to inspect WRAM dumps (e.g., shiren-aeon-genesis-wram.bin).

Features:
  - Dump slices by offset/length
  - Dump named slices useful for this project
  - Optional diff versus a baseline WRAM file

Examples:
  python3 tools/wram_utils.py dump shiren-aeon-genesis-wram.bin --start 0xD60D --len 0x29 --diff "baseline dumps/shiren-aeon-genesis-wram.bin"
  python3 tools/wram_utils.py named shiren-aeon-genesis-wram.bin --which dp,textptr,ring,b360 --diff "baseline dumps/shiren-aeon-genesis-wram.bin"
"""

from __future__ import annotations

import argparse
import pathlib
from typing import Iterable, Tuple, List, Optional


def parse_int(s: str) -> int:
    s = s.strip().lower()
    if s.startswith("0x"):
        return int(s, 16)
    if s.endswith("h"):
        return int(s[:-1], 16)
    return int(s, 0)


def hexdump(data: bytes, base: int = 0) -> str:
    lines: List[str] = []
    for off in range(0, len(data), 16):
        chunk = data[off : off + 16]
        hexs = " ".join(f"{b:02X}" for b in chunk)
        lines.append(f"{base+off:04X}: {hexs}")
    return "\n".join(lines)


def diffdump(cur: bytes, base: bytes, start: int) -> str:
    lines: List[str] = []
    n = min(len(cur), len(base))
    for i in range(n):
        cb, bb = cur[i], base[i]
        if cb != bb:
            lines.append(f"{start+i:04X}: {bb:02X}->{cb:02X}")
    return "\n".join(lines) if lines else "(no differences)"


NAMED_SLICES = {
    # name: (start, length)
    "dp": (0x0000, 0x20),
    "textptr": (0x00D4, 0x12),
    "ring": (0xCA50, 0x40),
    "b360": (0xD60D, 0x29),
}


def read_bytes(path: pathlib.Path) -> bytes:
    return path.read_bytes()


def cmd_dump(args: argparse.Namespace) -> None:
    cur = read_bytes(args.path)
    start = parse_int(args.start)
    length = parse_int(args.len)
    end = start + length
    data = cur[start:end]
    print(hexdump(data, base=start))
    if args.diff:
        base = read_bytes(args.diff)
        bdata = base[start:end]
        print("-- DIFF --")
        print(diffdump(data, bdata, start))


def cmd_named(args: argparse.Namespace) -> None:
    cur = read_bytes(args.path)
    base: Optional[bytes] = None
    if args.diff:
        base = read_bytes(args.diff)
    which = [w.strip().lower() for w in args.which.split(",") if w.strip()]
    for name in which:
        if name not in NAMED_SLICES:
            print(f"Unknown slice name: {name}")
            continue
        start, length = NAMED_SLICES[name]
        print(f"[{name}] {start:04X}..{start+length:04X}")
        data = cur[start : start + length]
        print(hexdump(data, base=start))
        if base is not None:
            bdata = base[start : start + length]
            print("-- DIFF --")
            print(diffdump(data, bdata, start))
        print()


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="WRAM dump utilities")
    sub = p.add_subparsers(dest="cmd", required=True)

    p_dump = sub.add_parser("dump", help="dump an arbitrary slice")
    p_dump.add_argument("path", type=pathlib.Path, help="WRAM bin path")
    p_dump.add_argument("--start", required=True)
    p_dump.add_argument("--len", required=True)
    p_dump.add_argument("--diff", type=pathlib.Path, help="baseline WRAM bin")
    p_dump.set_defaults(func=cmd_dump)

    p_named = sub.add_parser("named", help="dump named slices (dp,textptr,ring,b360)")
    p_named.add_argument("path", type=pathlib.Path, help="WRAM bin path")
    p_named.add_argument("--which", default="dp,textptr,ring,b360")
    p_named.add_argument("--diff", type=pathlib.Path, help="baseline WRAM bin")
    p_named.set_defaults(func=cmd_named)

    return p


def main() -> None:
    args = build_parser().parse_args()
    args.func(args)


if __name__ == "__main__":
    main()

