#!/usr/bin/env python3
"""Fail closed on proof escapes in every project Lean source surface."""

from __future__ import annotations

import argparse
import bisect
import hashlib
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = "LidoSRv3"
# This is an inventory, rather than a permission to introduce the tactic: any
# addition, deletion, or move of a project `native_decide` use must be reviewed
# by deliberately updating this guard.  The existing uses are separately
# disclosed by the Trust report's axiom output.
NATIVE_DECIDE_COUNT = 222
NATIVE_DECIDE_SHA256 = "d5683baf091837853642374e44e584e3f8818e6d134b055feb8c9f7e9dcbc243"
ESCAPES = (
    ("sorry", re.compile(r"\bsorry\b")),
    ("admit", re.compile(r"\badmit\b")),
    ("axiom", re.compile(r"\baxiom\b")),
    ("unsafe", re.compile(r"\bunsafe\b")),
    ("Lean.ofReduceBool", re.compile(r"\bLean\.ofReduceBool\b")),
)


def strip_comments_and_strings(source: str) -> str:
    """Blank comments/strings while preserving positions and newlines."""
    out: list[str] = []
    i = 0
    depth = 0
    in_string = False
    while i < len(source):
        pair = source[i : i + 2]
        ch = source[i]
        if depth:
            if pair == "/-":
                depth += 1
                out.extend("  ")
                i += 2
            elif pair == "-/":
                depth -= 1
                out.extend("  ")
                i += 2
            else:
                out.append("\n" if ch == "\n" else " ")
                i += 1
        elif in_string:
            out.append("\n" if ch == "\n" else " ")
            if ch == "\\" and i + 1 < len(source):
                out.append("\n" if source[i + 1] == "\n" else " ")
                i += 2
            elif ch == '"':
                in_string = False
                i += 1
            else:
                i += 1
        elif pair == "/-":
            depth = 1
            out.extend("  ")
            i += 2
        elif pair == "--":
            newline = source.find("\n", i)
            if newline == -1:
                out.extend(" " * (len(source) - i))
                break
            out.extend(" " * (newline - i))
            i = newline
        elif ch == '"':
            in_string = True
            out.append(" ")
            i += 1
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def fail(message: str) -> None:
    raise SystemExit(f"proof-escape check failed: {message}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--native-decide-policy", choices=("enforce", "forbid"), default="enforce")
    args = parser.parse_args()
    root = args.root.resolve()
    source_root = root / SOURCE_ROOT
    files = sorted(source_root.rglob("*.lean"))
    if not files:
        fail(f"no Lean sources below {SOURCE_ROOT}/")
    native_records: list[str] = []
    for path in files:
        source = path.read_text(encoding="utf-8")
        if not any(token in source for token in ("sorry", "admit", "axiom", "unsafe", "Lean.ofReduceBool", "native_decide")):
            continue
        clean = strip_comments_and_strings(source)
        lines = source.splitlines()
        newlines = [index for index, char in enumerate(clean) if char == "\n"]
        relative = path.relative_to(root).as_posix()
        for name, pattern in ESCAPES:
            match = pattern.search(clean)
            if match:
                line = bisect.bisect_right(newlines, match.start()) + 1
                fail(f"{relative}:{line}: forbidden {name}")
        for match in re.finditer(r"\bnative_decide\b", clean):
            line = bisect.bisect_right(newlines, match.start()) + 1
            original = lines[line - 1].strip()
            native_records.append(f"{relative}:{line}:{original}")
    digest = hashlib.sha256("\n".join(native_records).encode()).hexdigest()
    if args.native_decide_policy == "forbid" and native_records:
        fail("forbidden native_decide")
    if args.native_decide_policy == "enforce" and (len(native_records) != NATIVE_DECIDE_COUNT or digest != NATIVE_DECIDE_SHA256):
        fail("native_decide inventory differs from the recorded project baseline")
    print(f"proof-escape check ok: {len(files)} project Lean files; no sorry/admit/axiom/unsafe/Lean.ofReduceBool; native_decide inventory {digest}")


if __name__ == "__main__":
    main()
