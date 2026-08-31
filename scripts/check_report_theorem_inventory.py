#!/usr/bin/env python3
"""Bind the P-ALLOC-1 report's theorem inventory to Lean and to the registry.

The report is a reader-facing surface: a theorem that exists in the guarantee
module but is missing from the inventory reads as if the guarantee had fewer
moving parts than it has, and an inventory row that claims REGISTERED without a
matching `audit/guarantees.yaml` theorem overstates what the published CHECKED
cells assert.  Both directions fail closed here.
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEAN = ROOT / "LidoSRv3/Audit/Guarantees/PAlloc1.lean"
REPORT = ROOT / "report/P-ALLOC-1.md"
REGISTRY = ROOT / "audit/guarantees.yaml"
GUARANTEE_ID = "P-ALLOC-1"
NAMESPACE = "LidoSRv3.Audit.Guarantees.PAlloc1."

ROW = re.compile(
    r"^\| `(?P<name>[A-Za-z0-9_']+)` \| (?P<line>\d+) \| (?P<plane>[^|]+?) \| "
    r"(?P<registered>[^|]+?) \| (?P<role>[^|]+?) \|$",
    re.MULTILINE,
)

# A top-level declaration is not always a bare `theorem` in column zero.  Lean
# accepts leading whitespace, attribute blocks, visibility/reducibility
# modifiers, and `lemma` as an alias for `theorem`; every one of those is
# ordinary formatting rather than an exotic spelling.  Matching only the bare
# form would let any of them hide a declaration from the inventory while this
# gate still reported success, so the whole prefix is parsed.  Widening only
# ever finds more declarations to demand rows for, so it cannot loosen the gate.
# `\s+` after the keyword keeps `theorem_like_name` from matching, and
# `-- theorem ...` still cannot, since `--` is neither attribute nor modifier.
MODIFIERS = ("private", "protected", "scoped", "local", "nonrec", "noncomputable")
DECL = re.compile(
    r"^[ \t]*"
    r"(?:@\[[^\]]*\][ \t]*)*"
    rf"(?:(?:{'|'.join(MODIFIERS)})[ \t]+)*"
    r"(?:theorem|lemma)\s+([A-Za-z0-9_']+)"
)


def fail(message):
    raise SystemExit(f"report theorem inventory: {message}")


def strip_block_comments(text):
    """Blank Lean block comments, preserving every newline and column.

    Lean block comments nest, so `/-.*?-/` closes an outer comment at the first
    inner `-/` and hands the rest of that comment back as source: a prose line
    beginning `theorem ...` inside it is then demanded as an inventory row for a
    theorem Lean never declares, failing the gate on valid source.  Depth is
    tracked here instead.

    `/-` only opens a comment where code is actually being read.  Inside a `--`
    line comment or a string literal it is ordinary text, and treating one as an
    opener would blank the real declarations that follow — the failure direction
    that matters, since it hides theorems rather than inventing them.
    """
    out = []
    index = 0
    depth = 0
    end = len(text)
    while index < end:
        pair = text[index:index + 2]
        if depth:
            if pair in ("/-", "-/"):
                depth += 1 if pair == "/-" else -1
                out.append("  ")
                index += 2
                continue
            # Blanking the body to spaces rather than dropping it keeps every
            # declaration at the line and column it occupies on disk.
            out.append("\n" if text[index] == "\n" else " ")
            index += 1
        elif pair == "/-":
            depth = 1
            out.append("  ")
            index += 2
        elif pair == "--":
            while index < end and text[index] != "\n":
                out.append(text[index])
                index += 1
        elif text[index] == '"':
            out.append(text[index])
            index += 1
            while index < end:
                if text[index] == "\\" and index + 1 < end:
                    out.append(text[index:index + 2])
                    index += 2
                    continue
                out.append(text[index])
                index += 1
                if text[index - 1] == '"':
                    break
        else:
            out.append(text[index])
            index += 1
    if depth:
        fail(f"{LEAN.relative_to(ROOT)} has an unterminated block comment; the "
             "declarations after it cannot be read, so the inventory cannot be checked")
    return "".join(out)


def declared_theorems():
    # Comments wrap prose that can begin a line with "theorem", so blank them
    # out first while preserving line numbering.
    text = strip_block_comments(LEAN.read_text(encoding="utf-8"))
    found = {}
    for number, line in enumerate(text.splitlines(), start=1):
        match = DECL.match(line)
        if match:
            found[match.group(1)] = number
    return found


def main():
    lean = declared_theorems()
    if not lean:
        fail(f"no theorem declarations parsed from {LEAN.relative_to(ROOT)}")

    report = REPORT.read_text(encoding="utf-8")
    rows = {m.group("name"): m for m in ROW.finditer(report)}

    missing = sorted(set(lean) - set(rows))
    if missing:
        fail(f"{REPORT.relative_to(ROOT)} omits declared theorem(s): {', '.join(missing)}")
    extra = sorted(set(rows) - set(lean))
    if extra:
        fail(f"{REPORT.relative_to(ROOT)} lists theorem(s) absent from Lean: {', '.join(extra)}")

    for name, match in rows.items():
        if int(match.group("line")) != lean[name]:
            fail(f"{name} is declared at Lean line {lean[name]}, "
                 f"inventory says {match.group('line')}")
        plane = match.group("plane").strip()
        if plane not in ("Abstract", "Verity", "Abstract and Verity (composite)"):
            fail(f"{name} has no recognized abstract/Verity plane: {plane!r}")

    row = next(g for g in json.loads(REGISTRY.read_text(encoding="utf-8"))["guarantees"]
               if g["id"] == GUARANTEE_ID)
    registered = set()
    for plane in ("abstract", "verity"):
        theorem = row[plane].get("theorem")
        if theorem and theorem.startswith(NAMESPACE):
            registered.add(theorem[len(NAMESPACE):])
    if not registered:
        fail(f"registry records no {NAMESPACE}* theorem for {GUARANTEE_ID}")

    claimed = {name for name, match in rows.items()
               if match.group("registered").strip().startswith("REGISTERED")}
    if claimed != registered:
        fail(f"inventory marks {sorted(claimed)} REGISTERED; "
             f"registry names {sorted(registered)}")

    print(f"report theorem inventory ok: {len(rows)} {GUARANTEE_ID} theorems, "
          f"{len(registered)} registered")


if __name__ == "__main__":
    sys.exit(main())
