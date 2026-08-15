#!/usr/bin/env python3
"""Fail closed when canonical public summaries contradict retracted TX claims."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


CLAIMS = {
    "P-DEPOSIT-1": {
        "module": "PDeposit1",
        "layers": ".model, .abstractTx, .source",
        "forbidden": ("tx_one_unit_exact_transfer", "tx_revert_restores_snapshot_and_effects"),
    },
    "P-TOPUP-1": {
        "module": "PTopup1",
        "layers": ".model, .abstractTx, .source",
        "forbidden": ("verity_tx_simulates_source",),
    },
    "P-ACCOUNT-1": {
        "module": "PAccount1",
        "layers": ".model, .source",
        "forbidden": ("source_to_verityTx",),
    },
}


def fail(message: str) -> None:
    raise ValueError(message)


def read(path: Path) -> str:
    if not path.is_file():
        fail(f"required public claim surface is missing: {path}")
    return path.read_text(encoding="utf-8")


def check(root: Path) -> None:
    try:
        registry = json.loads(read(root / "audit/guarantees.yaml"))
    except json.JSONDecodeError as exc:
        fail(f"cannot parse canonical registry: {exc}")
    rows = {row.get("id"): row for row in registry.get("guarantees", [])}
    readme = read(root / "README.md")
    facade = read(root / "LidoSRv3/Audit/AllGuarantees.lean")

    for claim_id, expected in CLAIMS.items():
        row = rows.get(claim_id)
        if row is None:
            fail(f"canonical registry is missing {claim_id}")
        if row.get("statuses", {}).get("tx") != "BLOCKED":
            fail(f"{claim_id}: this guard requires canonical TX status BLOCKED")
        theorem = row.get("theorem")
        if not isinstance(theorem, str) or not theorem:
            fail(f"{claim_id}: canonical theorem is missing")

        table_pattern = re.compile(
            rf"^\|\s*\d+\s*\|\s*`{re.escape(claim_id)}`\s*\|[^\n]*"
            rf"`{re.escape(theorem)}`[^\n]*TX BLOCKED[^\n]*\|$",
            re.MULTILINE,
        )
        if not table_pattern.search(readme):
            fail(f"README: {claim_id} must name its canonical theorem and TX BLOCKED")

        module = expected["module"]
        lean_path = root / f"LidoSRv3/Audit/Guarantees/{module}.lean"
        lean = read(lean_path)
        definition = re.compile(
            rf"def guarantee\s*:\s*Guarantee\s*:=\s*"
            rf"⟨\.{module[0].lower() + module[1:]},\s*\[{re.escape(expected['layers'])}\]\u27e9"
        )
        if not definition.search(lean):
            fail(f"{lean_path}: checkedLayers differ from the blocked canonical view")
        if "transaction claim is blocked" not in lean:
            fail(f"{lean_path}: missing explicit blocked-transaction description")

        for stale_name in expected["forbidden"]:
            if stale_name in readme or stale_name in lean or stale_name in facade:
                fail(f"stale public TX facade survives for {claim_id}: {stale_name}")

    if "Their former Verity transaction suffixes are retracted" not in readme:
        fail("README: missing explicit deposit/top-up TX retraction")
    if "transaction trace is non-evidence, and TX is BLOCKED" not in readme:
        fail("README: missing explicit accounting TX non-evidence statement")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    try:
        check(args.root.resolve())
    except (OSError, ValueError) as exc:
        print(f"public claim surface check failed: {exc}", file=sys.stderr)
        return 1
    print("public claim surfaces match canonical BLOCKED transaction statuses")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
