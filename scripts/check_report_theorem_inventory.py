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


def fail(message):
    raise SystemExit(f"report theorem inventory: {message}")


def declared_theorems():
    # Doc comments wrap prose that can begin a line with "theorem", so blank
    # them out first while preserving line numbering.
    text = re.sub(r"/-.*?-/", lambda m: "\n" * m.group(0).count("\n"),
                  LEAN.read_text(encoding="utf-8"), flags=re.DOTALL)
    found = {}
    for number, line in enumerate(text.splitlines(), start=1):
        match = re.match(r"^theorem\s+([A-Za-z0-9_']+)", line)
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
