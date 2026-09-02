#!/usr/bin/env python3
"""Fail closed on production imports of Tests, Legacy, and Trust.

Layer inversions that already exist (Spec → Verity, Spec/Source/Verity →
Guarantees) are a shrinking allowlist: every listed edge must still be
present, and no new edge may appear. Fixing an inversion means deleting its
row from `audit/import-layer-allowlist.txt` in the same change.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ALLOWLIST = Path("audit/import-layer-allowlist.txt")
BASELINE_REV = "4fb659e8f8689346f155e633aabc068b6d75c1a5"
LAKEFILE = Path("lakefile.lean")
IMPORT = re.compile(r"^\s*import\s+(\S+)\s*$", re.MULTILINE)
GLOB_ONE = re.compile(r"\.one\s+`([A-Za-z0-9.]+)")
GLOB_SUB = re.compile(r"\.submodules\s+`([A-Za-z0-9.]+)")
GLOB_AND = re.compile(r"\.andSubmodules\s+`([A-Za-z0-9.]+)")

# Layers that must not import test, legacy, or Trust.
PRODUCTION = frozenset({
    "facade", "production", "guarantees", "spec", "verity", "source",
    "model", "common", "provenance",
})

# Existing inversions. New pairs require an architecture change, not a row.
LAYER_DEBT = {
    "spec-verity": ("spec", "verity"),
    "spec-guarantees": ("spec", "guarantees"),
    "source-guarantees": ("source", "guarantees"),
    "model-guarantees": ("model", "guarantees"),
    "common-guarantees": ("common", "guarantees"),
    "verity-guarantees": ("verity", "guarantees"),
    "provenance-guarantees": ("provenance", "guarantees"),
}


def fail(message: str) -> None:
    raise SystemExit(f"import-dag check failed: {message}")


def strip_comments_and_strings(source: str) -> str:
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import check_proof_escapes
    return check_proof_escapes.strip_comments_and_strings(source)


def module_of(path: Path, root: Path) -> str:
    rel = path.relative_to(root).as_posix()
    if rel.endswith(".lean"):
        rel = rel[:-5]
    return rel.replace("/", ".")


def layer_of(name: str) -> str:
    if name == "LidoSRv3":
        return "facade"
    if name == "LidoSRv3Test" or name.startswith("LidoSRv3.Tests."):
        return "test"
    if name.startswith("LidoSRv3.Legacy."):
        return "legacy"
    if name == "LidoSRv3.Audit.Trust":
        return "audit"
    if name.startswith("LidoSRv3.Audit.Verity.Tests.") or name == "LidoSRv3.Audit.Verity.Tests":
        return "test"
    if name.startswith("LidoSRv3.Audit.Regression."):
        return "test"
    if name.startswith("LidoSRv3.Audit.Guarantees."):
        return "guarantees"
    if name == "LidoSRv3.Audit.Spec" or name.startswith("LidoSRv3.Audit.Spec."):
        return "spec"
    if name.startswith("LidoSRv3.Audit.Verity."):
        return "verity"
    if name.startswith("LidoSRv3.Audit.Source."):
        return "source"
    if name.startswith("LidoSRv3.Audit.Model."):
        return "model"
    if name.startswith("LidoSRv3.Audit.Common."):
        return "common"
    if name.startswith("LidoSRv3.Audit.Provenance."):
        return "provenance"
    if name.startswith("LidoSRv3.Audit."):
        return "production"
    return "other"


def is_excluded_from_production(rel: str) -> bool:
    return (
        rel.startswith("LidoSRv3/Tests/")
        or rel.startswith("LidoSRv3/Legacy/")
        or rel == "LidoSRv3/Audit/Trust.lean"
        or rel.startswith("LidoSRv3/Audit/Verity/Tests/")
        or rel.startswith("LidoSRv3/Audit/Regression/")
    )


def glob_covers(module: str, ones: set[str], subs: set[str], ands: set[str]) -> bool:
    if module in ones:
        return True
    for prefix in ands:
        if module == prefix or module.startswith(prefix + "."):
            return True
    for prefix in subs:
        if module.startswith(prefix + "."):
            return True
    return False


def production_glob_gaps(root: Path) -> list[str]:
    """Every production .lean file must be explicitly covered by a Lake glob."""
    lakefile = root / LAKEFILE
    if not lakefile.is_file():
        fail(f"missing {LAKEFILE}")
    text = lakefile.read_text(encoding="utf-8")
    # Only the production library lists Verity as `.one` rows. Parsing the
    # whole file is safe: test/legacy globs are directory prefixes, not `.one`
    # names of production Verity modules.
    ones = set(GLOB_ONE.findall(text))
    subs = set(GLOB_SUB.findall(text))
    ands = set(GLOB_AND.findall(text))
    gaps: list[str] = []
    paths = sorted((root / "LidoSRv3").rglob("*.lean"))
    facade = root / "LidoSRv3.lean"
    if facade.is_file():
        paths.append(facade)
    for path in paths:
        rel = path.relative_to(root).as_posix()
        if is_excluded_from_production(rel):
            continue
        module = rel[:-5].replace("/", ".")
        if not glob_covers(module, ones, subs, ands):
            gaps.append(module)
    return gaps


def project_sources(root: Path) -> list[Path]:
    files = sorted((root / "LidoSRv3").rglob("*.lean"))
    facade = root / "LidoSRv3.lean"
    if facade.is_file():
        files.append(facade)
    if not files:
        fail("no Lean sources under LidoSRv3/")
    return files


def edges(root: Path) -> list[tuple[str, str, str, str]]:
    """(src_module, src_layer, imported_module, dst_layer) for every import."""
    found: list[tuple[str, str, str, str]] = []
    for path in project_sources(root):
        src = module_of(path, root)
        src_layer = layer_of(src)
        text = strip_comments_and_strings(path.read_text(encoding="utf-8"))
        for imported in IMPORT.findall(text):
            found.append((src, src_layer, imported, layer_of(imported)))
    return found


def hard_violations(found: list[tuple[str, str, str, str]]) -> list[str]:
    bad: list[str] = []
    for src, src_layer, imported, dst_layer in found:
        if src_layer not in PRODUCTION:
            continue
        if dst_layer == "test":
            bad.append(f"{src} → {imported} (production → test)")
        elif dst_layer == "legacy":
            bad.append(f"{src} → {imported} (production → legacy)")
        elif dst_layer == "audit":
            bad.append(f"{src} → {imported} (production → Trust)")
    return bad


def debt_edges(found: list[tuple[str, str, str, str]]) -> dict[str, set[tuple[str, str]]]:
    grouped: dict[str, set[tuple[str, str]]] = {rule: set() for rule in LAYER_DEBT}
    inverse = {pair: rule for rule, pair in LAYER_DEBT.items()}
    for src, src_layer, imported, dst_layer in found:
        rule = inverse.get((src_layer, dst_layer))
        if rule is None:
            continue
        grouped[rule].add((src, imported))
    return grouped


def load_allowlist(path: Path) -> dict[str, set[tuple[str, str]]]:
    if not path.is_file():
        fail(f"missing allowlist {path}")
    grouped: dict[str, set[tuple[str, str]]] = {rule: set() for rule in LAYER_DEBT}
    current: str | None = None
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            if line.startswith("# rule:"):
                current = line.split(":", 1)[1].strip()
                if current not in LAYER_DEBT:
                    fail(f"{path}:{number}: unknown rule {current}")
            continue
        if current is None:
            fail(f"{path}:{number}: edge before a `# rule:` header")
        parts = line.split()
        if len(parts) != 2:
            fail(f"{path}:{number}: expected `src imported`, got {line!r}")
        grouped[current].add((parts[0], parts[1]))
    return grouped


def render_allowlist(grouped: dict[str, set[tuple[str, str]]]) -> str:
    lines = [
        "# Shrinking import-layer debt. Delete a row only when the import is gone.",
        "# Adding a row is forbidden; new inversions fail the check.",
        "",
    ]
    for rule in LAYER_DEBT:
        lines.append(f"# rule: {rule}")
        for src, imported in sorted(grouped[rule]):
            lines.append(f"{src} {imported}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def load_pinned_baseline(root: Path, path: Path | None) -> dict[str, set[tuple[str, str]]]:
    """Load the debt ceiling from an immutable Git object, never this PR's file."""
    if path is not None:
        return load_allowlist(path)
    source = f"{BASELINE_REV}:{ALLOWLIST.as_posix()}"
    result = subprocess.run(
        ["git", "-C", str(root), "show", source],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode:
        detail = result.stderr.strip() or result.stdout.strip()
        fail(f"cannot read immutable layer-debt baseline {source}: {detail}")
    # Parse the pinned Git blob without materializing it in the worktree.
    grouped: dict[str, set[tuple[str, str]]] = {rule: set() for rule in LAYER_DEBT}
    current: str | None = None
    for number, raw in enumerate(result.stdout.splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            if line.startswith("# rule:"):
                current = line.split(":", 1)[1].strip()
                if current not in LAYER_DEBT:
                    fail(f"{source}:{number}: unknown rule {current}")
            continue
        if current is None:
            fail(f"{source}:{number}: edge before a `# rule:` header")
        parts = line.split()
        if len(parts) != 2:
            fail(f"{source}:{number}: expected `src imported`, got {line!r}")
        grouped[current].add((parts[0], parts[1]))
    return grouped


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--allowlist", type=Path, default=None)
    parser.add_argument("--baseline", type=Path, default=None,
                        help="test-only override for the immutable baseline")
    parser.add_argument("--write-allowlist", action="store_true",
                        help="rewrite the allowlist from the current tree and exit")
    args = parser.parse_args()
    root = args.root.resolve()
    allowlist_path = (args.allowlist if args.allowlist is not None
                      else root / ALLOWLIST)
    found = edges(root)
    hard = hard_violations(found)
    debt = debt_edges(found)
    if hard:
        fail("production must not import Tests, Legacy, or Trust: " + "; ".join(hard))
    gaps = production_glob_gaps(root)
    if gaps:
        fail("production modules missing from lakefile globs: " + ", ".join(gaps))
    baseline = load_pinned_baseline(root, args.baseline)
    for rule in LAYER_DEBT:
        extra = debt[rule] - baseline[rule]
        if extra:
            rendered = ", ".join(f"{s} → {i}" for s, i in sorted(extra))
            fail(f"new {rule} edge(s) {rendered}; exceeds immutable baseline "
                 f"{BASELINE_REV}")
    if args.write_allowlist:
        allowlist_path.parent.mkdir(parents=True, exist_ok=True)
        allowlist_path.write_text(render_allowlist(debt), encoding="utf-8")
        count = sum(len(rows) for rows in debt.values())
        print(f"wrote {count} layer-debt edges to {allowlist_path}")
        return
    recorded = load_allowlist(allowlist_path)
    for rule in LAYER_DEBT:
        missing = recorded[rule] - debt[rule]
        if missing:
            rendered = ", ".join(f"{s} → {i}" for s, i in sorted(missing))
            fail(f"allowlisted {rule} edge(s) are gone: {rendered}; delete them from "
                 f"{allowlist_path.relative_to(root)}")
    print("import-dag ok: production ↛ test/legacy/Trust; globs cover production; "
          f"layer debt did not grow past immutable baseline {BASELINE_REV}")


if __name__ == "__main__":
    main()
