#!/usr/bin/env python3
"""Resolve declared Lean theorems and render theorem-scoped evidence views."""

import json
import re
from pathlib import Path

PLANES = ("model", "algorithm", "source", "tx", "yul", "evm", "crypto")
THEOREM_BACKED_STATUSES = {"ABSTRACT_LEAN_CHECKED", "LEAN_CHECKED", "REGRESSION"}
CAMPAIGN_COMMIT = "4649ba55052fa29132b016dc443ac738134c332f"
DECLARATION = re.compile(
    r"^\s*(?:private\s+|protected\s+)?(?:theorem|lemma)\s+([A-Za-z_][A-Za-z0-9_']*)\b"
)
NAMESPACE = re.compile(r"^\s*namespace\s+([A-Za-z_][A-Za-z0-9_'.]*)\s*(?:--.*)?$")
SECTION = re.compile(r"^\s*(?:section)(?:\s+[A-Za-z_][A-Za-z0-9_']*)?\s*(?:--.*)?$")
END = re.compile(r"^\s*end(?:\s+([A-Za-z_][A-Za-z0-9_'.]*))?\s*(?:--.*)?$")


class EvidenceError(RuntimeError):
    """A fail-closed evidence validation error."""


def discover_theorems(root):
    """Return fully qualified Lean theorem/lemma declarations by exact name."""
    declarations = {}
    lean_root = Path(root) / "LidoSRv3"
    if not lean_root.is_dir():
        raise EvidenceError(f"Lean source directory is missing: {lean_root}")
    for path in sorted(lean_root.rglob("*.lean")):
        blocks = []
        in_block_comment = 0
        for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            # Declaration-bearing lines in this tree are not inside nested block
            # comments. Strip comments so documentation examples cannot become evidence.
            line = raw
            if in_block_comment:
                in_block_comment += line.count("/-") - line.count("-/")
                if in_block_comment > 0:
                    continue
                line = line.rsplit("-/", 1)[-1]
            while "/-" in line:
                before, after = line.split("/-", 1)
                depth = 1 + after.count("/-") - after.count("-/")
                if depth > 0:
                    in_block_comment = depth
                    line = before
                    break
                line = before + after.split("-/", 1)[-1]
            line = line.split("--", 1)[0]
            namespace = NAMESPACE.match(line)
            if namespace:
                blocks.append(("namespace", namespace.group(1)))
                continue
            if SECTION.match(line):
                blocks.append(("section", None))
                continue
            end = END.match(line)
            if end:
                if not blocks:
                    continue
                name = end.group(1)
                if name:
                    candidates = [i for i, block in enumerate(blocks) if block == ("namespace", name)]
                    if candidates:
                        del blocks[candidates[-1]:]
                    else:
                        blocks.pop()
                else:
                    blocks.pop()
                continue
            declaration = DECLARATION.match(line)
            if declaration:
                prefix = [name for kind, name in blocks if kind == "namespace"]
                full_name = ".".join(prefix + [declaration.group(1)])
                declarations.setdefault(full_name, []).append({
                    "source": path.relative_to(root).as_posix(),
                    "line": line_number,
                })
    return declarations


def validate_and_resolve(rows, root):
    ids = [row.get("id") for row in rows]
    if len(ids) != len(set(ids)):
        raise EvidenceError("guarantee IDs must be unique")
    by_id = {row["id"]: row for row in rows}
    for row in rows:
        parent = row.get("parent_id")
        if parent is not None:
            if parent not in by_id:
                raise EvidenceError(f"{row['id']}: unknown parent_id {parent}")
            if by_id[parent].get("parent_id") is not None:
                raise EvidenceError(f"{row['id']}: parent must be a public parent row")

    declarations = discover_theorems(root)
    resolved = {}
    for row in rows:
        row_id = row["id"]
        theorem = row.get("theorem")
        theorem_planes = row.get("theorem_planes", [])
        if bool(theorem) != bool(theorem_planes):
            raise EvidenceError(f"{row_id}: theorem and theorem planes must be declared together")
        if len(theorem_planes) != len(set(theorem_planes)) or not set(theorem_planes) <= set(PLANES):
            raise EvidenceError(f"{row_id}: invalid theorem evidence plane")
        for plane, status in row["statuses"].items():
            if status in THEOREM_BACKED_STATUSES and plane not in theorem_planes:
                raise EvidenceError(f"{row_id}: {plane} status {status} lacks theorem evidence")
        if theorem is None:
            resolved[row_id] = None
            continue
        matches = declarations.get(theorem, [])
        if not matches:
            raise EvidenceError(f"{row_id}: declared theorem not found: {theorem}")
        if len(matches) != 1:
            locations = ", ".join(f"{m['source']}:{m['line']}" for m in matches)
            raise EvidenceError(f"{row_id}: declared theorem is ambiguous: {theorem} ({locations})")
        resolved[row_id] = matches[0]

    # A parent theorem must be its own declaration, never a theorem assigned to a child.
    for row in rows:
        if row.get("parent_id") is None and row.get("theorem"):
            child_theorems = {
                child.get("theorem") for child in rows if child.get("parent_id") == row["id"]
            }
            if row["theorem"] in child_theorems:
                raise EvidenceError(f"{row['id']}: broad parent text is paired with a child-only theorem")
    return resolved


def evidence_data(rows, resolved):
    children = {}
    for row in rows:
        if row.get("parent_id"):
            children.setdefault(row["parent_id"], []).append(row)

    def item(row):
        location = resolved[row["id"]]
        return {
            "id": row["id"],
            "catalogue_wording": row["catalogue_wording"],
            "scope": row.get("source_plane_scope"),
            "statuses": row["statuses"],
            "theorem": row.get("theorem"),
            "theorem_planes": row.get("theorem_planes", []),
            "assumptions": row.get("assumptions", []),
            "source": location,
            "reproduction": row["reproduction"],
        }

    parents = [
        {**item(row), "children": [item(child) for child in children.get(row["id"], [])]}
        for row in rows
        if row.get("parent_id") is None and row.get("source_plane_scope") is None
    ]
    supplemental = [
        item(row)
        for row in rows
        if row.get("parent_id") is None and row.get("source_plane_scope") is not None
    ]
    represented = {row["id"] for row in parents + supplemental}
    represented.update(child["id"] for parent in parents for child in parent["children"])
    if represented != {row["id"] for row in rows}:
        missing = sorted({row["id"] for row in rows} - represented)
        raise EvidenceError(f"evidence rows were not represented: {', '.join(missing)}")

    return {
        "schema": "lido-srv3-theorem-scoped-evidence-v1",
        "campaign_commit": CAMPAIGN_COMMIT,
        "authority": "Catalogue target is not theorem scope; Lean theorem statements are authority.",
        "parents": parents,
        "supplemental": supplemental,
    }


def _statuses(statuses):
    return "; ".join(f"{plane}={statuses[plane]}" for plane in PLANES)


def _theorem_block(row):
    if row["theorem"] is None:
        return "- **Parent theorem: NO PARENT THEOREM**\n- Proof link: none (a file is not proof of this parent claim)"
    source = row["source"]
    return (
        f"- Theorem: [`{row['theorem']}`](../{source['source']}#L{source['line']})\n"
        f"- Theorem planes: {', '.join(f'`{p}`' for p in row['theorem_planes'])}\n"
        f"- Lean source: [`{source['source']}:{source['line']}`](../{source['source']}#L{source['line']})"
    )


def render_markdown(data):
    lines = [
        "<!-- GENERATED by scripts/audit_metadata.py; edit structured metadata or Lean, not this view. -->",
        "", "# Theorem-scoped evidence index", "",
        "**Catalogue target ≠ theorem scope.** A compiling file is not evidence that every natural-language claim associated with it is proved. Lean theorem statements are the authority; subordinate evidence remains subordinate.",
        "", f"Campaign commit: `{data['campaign_commit']}`", "",
    ]
    for parent in data["parents"]:
        lines += [
            f"## {parent['id']}", "", parent["catalogue_wording"], "",
            f"- Plane statuses: {_statuses(parent['statuses'])}",
            _theorem_block(parent),
            f"- Assumptions: {', '.join(f'`{a}`' for a in parent['assumptions']) or 'none'}",
            f"- Reproduce: `{parent['reproduction']['command']}`",
            f"- Expected scope: {parent['reproduction']['expected']}",
        ]
        if parent["children"]:
            lines += ["", "### Subordinate evidence (does not prove the parent)", ""]
            for child in parent["children"]:
                lines += [
                    f"#### {child['id']}", "", child["catalogue_wording"], "",
                    f"- Scope: {child['scope'] or 'not separately declared'}",
                    f"- Plane statuses: {_statuses(child['statuses'])}",
                    _theorem_block(child).replace("Parent theorem", "Theorem"),
                    f"- Assumptions: {', '.join(f'`{a}`' for a in child['assumptions']) or 'none'}",
                    f"- Reproduce: `{child['reproduction']['command']}`",
                    f"- Expected scope: {child['reproduction']['expected']}", "",
                ]
        lines.append("")
    if data["supplemental"]:
        lines += [
            "## Standalone supplemental evidence",
            "",
            "These scoped rows are not public parent guarantees and are not subordinate to one of the eleven public guarantees.",
            "",
        ]
        for row in data["supplemental"]:
            lines += [
                f"### {row['id']}", "", row["catalogue_wording"], "",
                f"- Scope: {row['scope']}",
                f"- Plane statuses: {_statuses(row['statuses'])}",
                _theorem_block(row).replace("Parent theorem", "Theorem"),
                f"- Assumptions: {', '.join(f'`{a}`' for a in row['assumptions']) or 'none'}",
                f"- Reproduce: `{row['reproduction']['command']}`",
                f"- Expected scope: {row['reproduction']['expected']}", "",
            ]
    return "\n".join(lines).rstrip() + "\n"


def render_json(data):
    return json.dumps(data, indent=2) + "\n"
