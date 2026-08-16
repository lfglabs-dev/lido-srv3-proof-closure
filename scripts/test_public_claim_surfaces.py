#!/usr/bin/env python3
"""Regression mutants for the fail-closed public-claim surface guard."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CHECKER = ROOT / "scripts/check_public_claim_surfaces.py"
FILES = (
    "README.md",
    "audit/guarantees.yaml",
    "LidoSRv3/Audit/AllGuarantees.lean",
    "LidoSRv3/Audit/Guarantees/PDeposit1.lean",
    "LidoSRv3/Audit/Guarantees/PTopup1.lean",
    "LidoSRv3/Audit/Guarantees/PAccount1.lean",
)


def run(root: Path, succeeds: bool, diagnostic: str = "") -> None:
    result = subprocess.run(
        ["python3", str(CHECKER), "--root", str(root)],
        text=True,
        capture_output=True,
        check=False,
    )
    if (result.returncode == 0) != succeeds:
        raise SystemExit(f"unexpected checker result: {result.stdout}{result.stderr}")
    if diagnostic and diagnostic not in result.stderr:
        raise SystemExit(f"missing diagnostic {diagnostic!r}: {result.stderr}")


with tempfile.TemporaryDirectory() as tmp:
    fixture = Path(tmp)
    for relative in FILES:
        destination = fixture / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / relative, destination)

    run(fixture, True)

    readme = fixture / "README.md"
    original = readme.read_text(encoding="utf-8")
    readme.write_text(
        original.replace(
            "LidoSRv3.Audit.Guarantees.PDeposit1.source_deposit_conserves_and_rolls_back",
            "LidoSRv3.Audit.Guarantees.PDeposit1.tx_one_unit_exact_transfer",
            1,
        ),
        encoding="utf-8",
    )
    run(fixture, False, "README: P-DEPOSIT-1")
    readme.write_text(original, encoding="utf-8")

    account = fixture / "LidoSRv3/Audit/Guarantees/PAccount1.lean"
    account_original = account.read_text(encoding="utf-8")
    account.write_text(
        account_original
        + "\n-- renamed false-claim mutant\ntheorem plausible_new_tx_closure : True := True.intro\n",
        encoding="utf-8",
    )
    run(fixture, False, "public declarations differ from the structural allowlist")

    account.write_text(
        "import LidoSRv3.Audit.Verity.AccountingTx\n" + account_original,
        encoding="utf-8",
    )
    run(fixture, False, "imports differ from the structural allowlist")

    account.unlink()
    run(fixture, False, "required public claim surface is missing")

print("public claim surface regressions ok: renamed claim/import/README/missing-file mutants fail closed")
