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


def run(root: Path, succeeds: bool, diagnostic: str = "", *extra: str) -> None:
    result = subprocess.run(
        ["python3", str(CHECKER), "--root", str(root),
         "--allowlist", str(root / "audit/import-layer-allowlist.txt"),
        # The fixture is not a Git worktree; its copied baseline is the same
        # immutable input used by the production checker's pinned Git blob.
        # Mutants may change the allowlist but never this baseline.
         "--baseline", str(root / "audit/import-layer-baseline.txt"), *extra],
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
    # The checker walks every Lean file under LidoSRv3/, so the copied
    # production/test/legacy samples are enough if they import only what we
    # stage. Rebuild the allowlist from this fixture so unused rows do not
    # fail the positive control.
    subprocess.run(
        ["python3", str(CHECKER), "--root", str(destination),
         "--allowlist", str(destination / "audit/import-layer-allowlist.txt"),
         "--baseline", str(ROOT / "audit/import-layer-allowlist.txt"),
         "--write-allowlist"],
        check=True, capture_output=True, text=True,
    )
    shutil.copy2(destination / "audit/import-layer-allowlist.txt",
                 destination / "audit/import-layer-baseline.txt")


with tempfile.TemporaryDirectory() as tmp:
    fixture = Path(tmp)
    copy_tree(fixture)
    run(fixture, True)

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
