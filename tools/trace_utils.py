#!/usr/bin/env python3
"""
Utilities to parse emulator trace logs (e.g., shiren-aeon-genesis-trace.log).

Features:
  - Tail the last N lines
  - Find a program counter (PC) address and print context around matches
  - Search for opcode text and print context

Examples:
  python3 tools/trace_utils.py tail shiren-aeon-genesis-trace.log --lines 5000
  python3 tools/trace_utils.py around shiren-aeon-genesis-trace.log --addr 00420c --before 50 --after 50
  python3 tools/trace_utils.py grep shiren-aeon-genesis-trace.log --pattern "brk #$00" --before 20 --after 20
"""

from __future__ import annotations

import argparse
import pathlib
import re
from typing import Iterable, List


def read_lines(path: pathlib.Path) -> List[str]:
    with path.open("r", encoding="utf-8", errors="ignore") as fh:
        return fh.readlines()


def cmd_tail(args: argparse.Namespace) -> None:
    lines = read_lines(args.path)
    n = min(args.lines, len(lines))
    for line in lines[-n:]:
        print(line.rstrip("\n"))


def normalize_addr(addr: str) -> str:
    s = addr.lower().strip()
    s = s.removeprefix("0x")
    return s.zfill(6)


def cmd_around(args: argparse.Namespace) -> None:
    lines = read_lines(args.path)
    addr_hex = normalize_addr(args.addr)
    # Match start-of-line 6-hex-digit PC
    pc_re = re.compile(r"^([0-9a-f]{6})\b", re.IGNORECASE)
    idxs: List[int] = []
    for i, line in enumerate(lines):
        m = pc_re.match(line)
        if m and m.group(1).lower() == addr_hex:
            idxs.append(i)
            if len(idxs) >= args.max:
                break
    if not idxs:
        print(f"No occurrences for PC {addr_hex} found")
        return
    for occ, i in enumerate(idxs, 1):
        start = max(0, i - args.before)
        end = min(len(lines), i + args.after + 1)
        print(f"=== occurrence {occ} at line {i+1} (PC={addr_hex}) ===")
        for j in range(start, end):
            print(lines[j].rstrip("\n"))


def cmd_grep(args: argparse.Namespace) -> None:
    lines = read_lines(args.path)
    pat = args.pattern
    idxs = [i for i, line in enumerate(lines) if pat in line]
    if not idxs:
        print(f"No matches for pattern: {pat!r}")
        return
    for occ, i in enumerate(idxs[: args.max], 1):
        start = max(0, i - args.before)
        end = min(len(lines), i + args.after + 1)
        print(f"=== occurrence {occ} at line {i+1} (pattern={pat!r}) ===")
        for j in range(start, end):
            print(lines[j].rstrip("\n"))


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Trace log utilities")
    sub = p.add_subparsers(dest="cmd", required=True)

    p_tail = sub.add_parser("tail", help="print last N lines")
    p_tail.add_argument("path", type=pathlib.Path)
    p_tail.add_argument("--lines", type=int, default=2000)
    p_tail.set_defaults(func=cmd_tail)

    p_around = sub.add_parser("around", help="find PC and print context")
    p_around.add_argument("path", type=pathlib.Path)
    p_around.add_argument("--addr", required=True, help="PC hex (e.g. 00420c or b983f7)")
    p_around.add_argument("--before", type=int, default=50)
    p_around.add_argument("--after", type=int, default=50)
    p_around.add_argument("--max", type=int, default=3, help="max occurrences to print")
    p_around.set_defaults(func=cmd_around)

    p_grep = sub.add_parser("grep", help="substring search with context")
    p_grep.add_argument("path", type=pathlib.Path)
    p_grep.add_argument("--pattern", required=True)
    p_grep.add_argument("--before", type=int, default=30)
    p_grep.add_argument("--after", type=int, default=30)
    p_grep.add_argument("--max", type=int, default=5)
    p_grep.set_defaults(func=cmd_grep)

    return p


def main() -> None:
    args = build_parser().parse_args()
    args.func(args)


if __name__ == "__main__":
    main()

