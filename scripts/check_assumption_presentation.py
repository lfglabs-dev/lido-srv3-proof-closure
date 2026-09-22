#!/usr/bin/env python3
"""Check the reader-facing groups without changing the assurance registry."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
import audit_metadata  # noqa: E402
import gfm_table  # noqa: E402

EXPECTED_PARTS = {'model-source': {'A-VERITY-SCAFFOLD', 'A-CLASSICAL-CHOICE', 'A-SOURCE-SHAPED', 'A-ABSTRACT-TX', 'A-NO-REENTRY'}, 'source-chain': {'A-RUNTIME-PROVENANCE', 'A-SOLC-TRUSTED', 'A-SUPPORTED-MODULES'}, 'primitives-transport': {'A-MULTI-NODE-TRANSPORT', 'A-SHA256-FFI', 'A-EIP4788-AUTHENTIC'}}



def validate(catalog, assumptions, guarantees):
    if catalog.get("schema") != "lido-assumption-presentation-v1":
        raise ValueError("unknown assumption presentation schema")
    known = {row["id"] for row in assumptions["assumptions"]}
    groups = catalog["groups"]
    if [group["id"] for group in groups] != list(EXPECTED_PARTS):
        raise ValueError("expected model, source-chain and primitive/transport groups")
    seen = set()
    for group in groups:
        parts = group["parts"]
        if not parts or not set(parts) <= known or seen.intersection(parts):
            raise ValueError("empty, unknown or repeated assumption parts")
        if set(parts) != EXPECTED_PARTS[group["id"]]:
            raise ValueError(f"{group['id']}: incorrect assumption membership")
        seen.update(parts)
        if not all(isinstance(text, str) and text.strip()
                   for text in [group["title"], group["mitigation"], *parts.values()]):
            raise ValueError("empty assumption explanation")
    for row in guarantees["guarantees"]:
        if not set(row["assumptions"]) <= known:
            raise ValueError(f"{row['id']}: unknown registry assumption")


# The README publishes `CHECKED` for every canonical row, and a row is only
# CHECKED under the premises the registry attaches to it.  Naming those premises
# beside the status table is a published claim like any other here, so it is
# bound to `audit/guarantees.yaml` rather than maintained by hand: a premise
# added to or dropped from a registry row, and a README cell left behind, is the
# drift this gate exists to refuse.  The table is located by its own header
# through the renderer-faithful reader the other README gates use, so a copy
# parked in a comment or a fence satisfies nothing.
README_PREMISE_COLUMNS = ("ID", "Named premises the row is proved under")
README_ID_CELL = re.compile(r"^`([^`]+)`$")
# A cell lists the premises as inline code, in the registry's own order: order
# carries no proof weight, but fixing it keeps the comparison exact instead of
# set-equal, so a cell cannot silently reorder into looking hand-written.
README_PREMISE_CELL = re.compile(r"^`[A-Z0-9-]+`(?:, `[A-Z0-9-]+`)*$")


def readme_premise_rows():
    """The rendered per-row premise table, as (ID, [premise ids]) pairs."""
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    masked = audit_metadata._mask_non_rendered_markdown(readme)
    tables = [t for t in gfm_table.find_tables(masked)
              if tuple(cell.strip() for cell in t.header.cells) == README_PREMISE_COLUMNS]
    if len(tables) != 1:
        raise ValueError(
            f"README: found {len(tables)} named-premise tables, expected exactly one; "
            "the premises qualify the CHECKED cells a reader meets above, and a second "
            "table claiming those columns would compete with that disclosure")
    table = tables[0]
    printed = []
    for line in table.rows:
        cells = [cell.strip() for cell in line.cells][:table.columns]
        cells += [""] * (table.columns - len(cells))
        named = README_ID_CELL.match(cells[0])
        if named is None:
            raise ValueError(f"README: named-premise row {cells[0]!r} names no claim ID")
        if not README_PREMISE_CELL.match(cells[1]):
            raise ValueError(
                f"README: {named.group(1)} lists its premises as {cells[1]!r}; the cell "
                "must be the registry's premise IDs as inline code, comma separated")
        printed.append((named.group(1), re.findall(r"`([^`]+)`", cells[1])))
    return printed


def validate_readme_premises(guarantees):
    registry = {row["id"]: row["assumptions"] for row in guarantees["guarantees"]}
    canonical = audit_metadata.CANONICAL_IDS
    printed = readme_premise_rows()
    if [identifier for identifier, _ in printed] != canonical:
        raise ValueError(
            f"README: the named-premise table prints {[i for i, _ in printed]}, "
            f"expected exactly the canonical rows in order: {canonical}")
    for identifier, premises in printed:
        expected = registry[identifier]
        if premises != expected:
            raise ValueError(
                f"README: {identifier} is published as proved under {premises}, "
                f"registry records {expected}")


def validate_readme_severity(assumptions, guarantees):
    """The README singles out the HIGH-severity premises; the registry decides which."""
    severity = {row["id"]: row["severity"] for row in assumptions["assumptions"]}
    carried = {premise for row in guarantees["guarantees"]
               if row["id"] in audit_metadata.CANONICAL_IDS
               for premise in row["assumptions"]}
    high = sorted(premise for premise in carried if severity[premise] == "HIGH")
    # Read the sentence with its whitespace collapsed: the claim is what a reader
    # meets, and rewrapping the paragraph must not be what breaks or satisfies it.
    readme = re.sub(r"\s+", " ", (ROOT / "README.md").read_text(encoding="utf-8"))
    claim = "is the only HIGH-severity premise on the table"
    if len(high) == 1 and f"`{high[0]}` {claim}" not in readme:
        raise ValueError(
            f"README: {high[0]} is the only HIGH-severity premise carried by a canonical "
            "row and the table must say so; a severity stated only in the registry does "
            "not qualify the CHECKED cells above")
    if len(high) != 1:
        expected = "HIGH-severity premises on the table: " + ", ".join(
            f"`{premise}`" for premise in high) + "."
        if expected not in readme or claim in readme:
            raise ValueError(
                f"README: disclose the exact HIGH-severity premises: {expected}")


def main():
    def read(name):
        return json.loads((ROOT / "audit" / name).read_text())
    assumptions, guarantees = read("assumptions.yaml"), read("guarantees.yaml")
    validate(read("assumption-presentation.json"), assumptions, guarantees)
    validate_readme_premises(guarantees)
    validate_readme_severity(assumptions, guarantees)
    print("assumption presentation ok: known, distinct IDs; registry membership "
          "preserved; README per-row premises match the registry")


if __name__ == "__main__":
    main()
