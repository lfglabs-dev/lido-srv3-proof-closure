#!/usr/bin/env python3
"""Fail closed on proof escapes in every project Lean source surface."""

from __future__ import annotations

import argparse
import bisect
import hashlib
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
# The default library has both the `LidoSRv3/` module tree and the
# `LidoSRv3.lean` umbrella module at the project root.  Keep this inventory
# explicit: the root module is compiled production code, not a fixture.
SOURCE_ROOT = "LidoSRv3"
LIBRARY_ROOTS = ("LidoSRv3.lean",)
# This is an inventory, rather than a permission to introduce the tactic: any
# addition, deletion, or move of a project `native_decide` use must be reviewed
# by deliberately updating this guard.  The existing uses are separately
# disclosed by the Trust report's axiom output.
NATIVE_DECIDE_COUNT = 218
NATIVE_DECIDE_SHA256 = "187f9bad4a1f96e8919eba8d5feca034ccde6f01b6ce268e26066e57ced14e81"
ESCAPES = (
    ("sorry", re.compile(r"\bsorry\b")),
    ("admit", re.compile(r"\badmit\b")),
    ("axiom", re.compile(r"\baxiom\b")),
    # `constant foo : T` is Lean's equivalent axiom declaration spelling.
    ("constant", re.compile(r"\bconstant\b")),
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


def project_sources(root: Path) -> list[Path]:
    source_root = root / SOURCE_ROOT
    files = sorted([*source_root.rglob("*.lean"),
                    *(root / relative for relative in LIBRARY_ROOTS)])
    missing_roots = [path.relative_to(root).as_posix() for path in files if not path.is_file()]
    if missing_roots:
        fail(f"missing production Lean source(s): {', '.join(missing_roots)}")
    if not files:
        fail(f"no Lean sources below {SOURCE_ROOT}/")
    return files


def native_decide_sites(root: Path, files: list[Path] | None = None) -> list[tuple[str, int, str]]:
    """Every `native_decide` tactic site in project source, as `(path, line, text)`.

    Comments and string literals are blanked first, so a site here is a real
    tactic occurrence Lean can mint a native-decision axiom from.
    """
    sites: list[tuple[str, int, str]] = []
    for path in (project_sources(root) if files is None else files):
        source = path.read_text(encoding="utf-8")
        if "native_decide" not in source:
            continue
        clean = strip_comments_and_strings(source)
        lines = source.splitlines()
        newlines = [index for index, char in enumerate(clean) if char == "\n"]
        relative = path.relative_to(root).as_posix()
        for match in re.finditer(r"\bnative_decide\b", clean):
            line = bisect.bisect_right(newlines, match.start()) + 1
            sites.append((relative, line, lines[line - 1].strip()))
    return sites


def native_decide_digest(sites: list[tuple[str, int, str]]) -> str:
    return hashlib.sha256(
        "\n".join(f"{path}:{line}:{text}" for path, line, text in sites).encode()
    ).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--native-decide-policy", choices=("enforce", "forbid"), default="enforce")
    args = parser.parse_args()
    root = args.root.resolve()
    files = project_sources(root)
    for path in files:
        source = path.read_text(encoding="utf-8")
        if not any(token in source for token in ("sorry", "admit", "axiom", "constant", "unsafe", "Lean.ofReduceBool")):
            continue
        clean = strip_comments_and_strings(source)
        newlines = [index for index, char in enumerate(clean) if char == "\n"]
        relative = path.relative_to(root).as_posix()
        for name, pattern in ESCAPES:
            match = pattern.search(clean)
            if match:
                line = bisect.bisect_right(newlines, match.start()) + 1
                fail(f"{relative}:{line}: forbidden {name}")
    native_records = native_decide_sites(root)
    digest = native_decide_digest(native_records)
    if args.native_decide_policy == "forbid" and native_records:
        fail("forbidden native_decide")
    if args.native_decide_policy == "enforce" and (len(native_records) != NATIVE_DECIDE_COUNT or digest != NATIVE_DECIDE_SHA256):
        fail("native_decide inventory differs from the recorded project baseline")
    print(f"proof-escape check ok: {len(files)} project Lean files; no sorry/admit/axiom/constant/unsafe/Lean.ofReduceBool; native_decide inventory {digest}")


if __name__ == "__main__":
    main()
