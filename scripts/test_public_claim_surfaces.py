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

    # Positive control: every existing allowed import and declaration is accepted.
    run(fixture, True)

    account = fixture / "LidoSRv3/Audit/Guarantees/PAccount1.lean"
    account_original = account.read_text(encoding="utf-8")
    account.write_text(
        account_original.replace(
            "theorem source_report_before_reward",
            "theorem «source_report_before_reward»",
            1,
        ),
        encoding="utf-8",
    )
    run(fixture, True)
    account.write_text(account_original, encoding="utf-8")

    readme = fixture / "README.md"
    original = readme.read_text(encoding="utf-8")
    readme.write_text(
        original.replace(
            "| 3 | `P-DEPOSIT-1` | CHECKED | PARTIAL — linked calls not yet faithfully executed |",
            "| 3 | `P-DEPOSIT-1` | CHECKED | CHECKED |",
            1,
        ),
        encoding="utf-8",
    )
    run(fixture, False, "README: P-DEPOSIT-1")
    readme.write_text(original, encoding="utf-8")

    account.write_text(
        account_original
        + "\n-- renamed false-claim mutant\ntheorem plausible_new_tx_closure : True := True.intro\n",
        encoding="utf-8",
    )
    run(fixture, False, "public declarations differ from the structural allowlist")

    account.write_text(
        account_original
        + "\n-- quoted ASCII identifier mutant\n"
        + "theorem «plausible_new_tx_closure» : True := True.intro\n",
        encoding="utf-8",
    )
    run(fixture, False, "public declarations differ from the structural allowlist")

    account.write_text(
        account_original
        + "\n-- bare Unicode identifier mutant\n"
        + "theorem plausible_new_tx_closurε : True := True.intro\n",
        encoding="utf-8",
    )
    run(fixture, False, "public declarations differ from the structural allowlist")

    account.write_text(
        account_original
        + "\n-- escaped quoted identifier mutant\n"
        + "theorem «plausible_new_tx_\\u0063losure» : True := True.intro\n",
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

print(
    "public claim surface regressions ok: allowed declarations pass; "
    "ASCII/quoted/Unicode/escaped/import/README/missing-file mutants fail closed"
)
