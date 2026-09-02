#!/usr/bin/env python3
"""Negative regressions for the production/test import DAG gate."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CHECKER = ROOT / "scripts/check_import_dag.py"
FILES = (
    "LidoSRv3.lean",
    "lakefile.lean",
    "audit/import-layer-allowlist.txt",
    "audit/import-layer-baseline.txt",
    "audit/import-layer-retired.txt",
    "scripts/check_import_dag.py",
    "scripts/check_proof_escapes.py",
    "LidoSRv3/Audit/Spec.lean",
    "LidoSRv3/Audit/Common/Units.lean",
    "LidoSRv3/Audit/Spec/AllocationCorrespondence.lean",
    "LidoSRv3/Audit/Guarantees/PAlloc1.lean",
    "LidoSRv3/Tests/AllocationTxMutants.lean",
    "LidoSRv3/Legacy/Model.lean",
    "LidoSRv3/Audit/Trust.lean",
)


def run(root: Path, succeeds: bool, diagnostic: str = "", *extra: str,
        baseline_override: bool = False, retired_override: Path | None = None) -> None:
    command = ["python3", str(CHECKER), "--root", str(root),
               "--allowlist", str(root / "audit/import-layer-allowlist.txt")]
    if baseline_override:
        command.extend(["--baseline", str(root / "audit/import-layer-baseline.txt")])
    if retired_override is not None:
        command.extend(["--retired", str(retired_override)])
    result = subprocess.run(
        [*command, *extra],
        text=True,
        capture_output=True,
        check=False,
    )
    output = result.stdout + result.stderr
    if (result.returncode == 0) != succeeds:
        raise SystemExit(f"unexpected checker result: {output}")
    if diagnostic and diagnostic not in output:
        raise SystemExit(f"missing diagnostic {diagnostic!r}: {output}")


def copy_tree(destination: Path) -> None:
    for relative in FILES:
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / relative, target)
    # Stage every source that owns baseline debt, so the retirement mutants
    # below cover each populated layer-debt family.
    for raw in (ROOT / "audit/import-layer-baseline.txt").read_text(encoding="utf-8").splitlines():
        if not raw or raw.startswith("#"):
            continue
        source, _ = raw.split()
        relative = Path(*source.split(".")).with_suffix(".lean")
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / relative, target)
    # The checker walks every Lean file under LidoSRv3/, so the copied
    # production/test/legacy samples are enough if they import only what we
    # stage. Rebuild the allowlist from this fixture so unused rows do not
    # fail the positive control.
    result = subprocess.run(
        ["python3", str(CHECKER), "--root", str(destination),
         "--allowlist", str(destination / "audit/import-layer-allowlist.txt"),
         "--baseline", str(ROOT / "audit/import-layer-baseline.txt"),
         "--write-allowlist"],
        check=False, capture_output=True, text=True,
    )
    if result.returncode:
        raise SystemExit(result.stdout + result.stderr)


with tempfile.TemporaryDirectory() as tmp:
    fixture = Path(tmp)
    copy_tree(fixture)
    run(fixture, True)

    baseline = fixture / "audit/import-layer-baseline.txt"
    baseline_original = baseline.read_text(encoding="utf-8")
    baseline.write_text(baseline_original + "# mutable baseline bypass\n", encoding="utf-8")
    run(fixture, False, "does not match pinned blob")
    baseline.write_text(baseline_original, encoding="utf-8")

    facade = fixture / "LidoSRv3.lean"
    original = facade.read_text(encoding="utf-8")
    facade.write_text(original + "\nimport LidoSRv3.Tests.AllocationTxMutants\n",
                      encoding="utf-8")
    run(fixture, False, "production → test")
    facade.write_text(original, encoding="utf-8")

    facade.write_text(original + "\nimport LidoSRv3.Legacy.Model\n", encoding="utf-8")
    run(fixture, False, "production → legacy")
    facade.write_text(original, encoding="utf-8")

    facade.write_text(original + "\nimport LidoSRv3.Audit.Trust\n", encoding="utf-8")
    run(fixture, False, "production → Trust")
    facade.write_text(original, encoding="utf-8")

    spec = fixture / "LidoSRv3/Audit/Spec.lean"
    spec_original = spec.read_text(encoding="utf-8")
    spec.write_text(spec_original + "\nimport LidoSRv3.Audit.Verity.AllocationTx\n",
                    encoding="utf-8")
    run(fixture, False, "new spec-verity edge")
    allowlist = fixture / "audit/import-layer-allowlist.txt"
    allowlist_original = allowlist.read_text(encoding="utf-8")
    allowlist.write_text(
        allowlist_original.replace(
            "# rule: spec-guarantees",
            "LidoSRv3.Audit.Spec LidoSRv3.Audit.Verity.AllocationTx\n\n"
            "# rule: spec-guarantees"),
        encoding="utf-8")
    run(fixture, False, "new spec-verity edge")
    run(fixture, False, "new spec-verity edge", "--write-allowlist")
    if allowlist.read_text(encoding="utf-8") != allowlist_original.replace(
            "# rule: spec-guarantees",
            "LidoSRv3.Audit.Spec LidoSRv3.Audit.Verity.AllocationTx\n\n"
            "# rule: spec-guarantees"):
        raise SystemExit("forbidden edge rewrote the mutable allowlist")
    allowlist.write_text(allowlist_original, encoding="utf-8")
    spec.write_text(spec_original, encoding="utf-8")

    # Moving a production glob to a different Lake library must not count as
    # production coverage.
    lakefile = fixture / "lakefile.lean"
    lakefile_original = lakefile.read_text(encoding="utf-8")
    moved_facade = lakefile_original.replace("    .one `LidoSRv3,\n", "", 1)
    moved_facade = moved_facade.replace(
        "  globs := #[\n    .submodules `LidoSRv3.Tests,",
        "  globs := #[\n    .one `LidoSRv3,\n    .submodules `LidoSRv3.Tests,",
        1,
    )
    lakefile.write_text(moved_facade, encoding="utf-8")
    run(fixture, False, "production modules missing from lakefile globs")
    lakefile.write_text(lakefile_original, encoding="utf-8")

    # A tombstone must reject restoration of both the import and its mutable
    # allowlist row, including the --write-allowlist path.  Exercise every
    # populated debt family rather than only spec-verity.
    retired = "LidoSRv3.Audit.Spec.AllocationCorrespondence LidoSRv3.Audit.Verity.DepositParentTx"
    allocation = fixture / "LidoSRv3/Audit/Spec/AllocationCorrespondence.lean"
    allocation_original = allocation.read_text(encoding="utf-8")
    allocation.write_text(allocation_original.replace(
        "import LidoSRv3.Audit.Verity.DepositParentTx\n", ""), encoding="utf-8")
    allowlist.write_text(allowlist_original.replace(retired + "\n", ""), encoding="utf-8")
    run(fixture, True)
    allocation.write_text(allocation_original, encoding="utf-8")
    run(fixture, False, "unallowlisted spec-verity edge(s) returned")
    allowlist.write_text(allowlist_original, encoding="utf-8")

    baseline_groups = {}
    active_rule = None
    for raw in allowlist_original.splitlines():
        if raw.startswith("# rule:"):
            active_rule = raw.split(":", 1)[1].strip()
        elif raw and not raw.startswith("#") and active_rule is not None:
            baseline_groups.setdefault(active_rule, []).append(raw)
    expected_families = set()
    active_rule = None
    for raw in (ROOT / "audit/import-layer-baseline.txt").read_text(encoding="utf-8").splitlines():
        if raw.startswith("# rule:"):
            active_rule = raw.split(":", 1)[1].strip()
        elif raw and not raw.startswith("#") and active_rule is not None:
            expected_families.add(active_rule)
    if set(baseline_groups) != expected_families:
        raise SystemExit("retirement fixture did not stage every debt family")
    for rule, rows in baseline_groups.items():
        row = rows[0]
        tombstones = fixture / f"audit/{rule}-retired.txt"
        tombstones.write_text(
            "# rule: " + rule + "\n" + row + "\n", encoding="utf-8")
        run(fixture, False, f"retired {rule} edge(s) restored",
            "--write-allowlist", retired_override=tombstones)

    lakefile = fixture / "lakefile.lean"
    lakefile_original = lakefile.read_text(encoding="utf-8")
    lakefile.write_text(lakefile_original.replace("    .one `LidoSRv3,\n", ""),
                        encoding="utf-8")
    run(fixture, False, "production modules missing from lakefile globs")
    lakefile.write_text(lakefile_original, encoding="utf-8")

    unlisted = fixture / "LidoSRv3/Audit/Verity/Unlisted.lean"
    unlisted.parent.mkdir(parents=True, exist_ok=True)
    unlisted.write_text("import LidoSRv3.Audit.Common.Units\n", encoding="utf-8")
    run(fixture, False, "production modules missing from lakefile globs")
    unlisted.unlink()

print("import-dag mutants ok")
