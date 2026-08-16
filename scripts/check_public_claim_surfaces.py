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
        "imports": (
            "LidoSRv3.Audit.Trace",
            "LidoSRv3.Audit.Source.DepositCorrespondence",
            "LidoSRv3.Audit.Guarantees.Registry",
        ),
        "declarations": (
            ("def", "guarantee"),
            ("theorem", "revert_restores_state_value_and_logs"),
            ("theorem", "source_deposit_conserves_and_rolls_back"),
            ("theorem", "source_router_balance_unchanged"),
            ("theorem", "source_reverting_branch_moves_no_ether"),
            ("theorem", "source_nonconserving_deployment_reverts"),
        ),
    },
    "P-TOPUP-1": {
        "module": "PTopup1",
        "layers": ".model, .abstractTx, .source",
        "imports": (
            "LidoSRv3.Audit.Allocation",
            "LidoSRv3.Audit.Trace",
            "LidoSRv3.Audit.Source.TopupCorrespondence",
            "LidoSRv3.Audit.Guarantees.Registry",
        ),
        "declarations": (
            ("def", "guarantee"),
            ("theorem", "valid_result_preserves_router_order"),
            ("theorem", "revert_restores_state_value_and_logs"),
            ("theorem", "source_topup_conserves_and_rolls_back"),
            ("theorem", "source_router_balance_unchanged"),
            ("theorem", "source_reverting_branch_moves_no_ether"),
            ("theorem", "source_balance_guards_discharged"),
            ("theorem", "source_unchecked_accumulation_faithful"),
            ("theorem", "source_pinned_config_discharges_pubkey_guard"),
        ),
    },
    "P-ACCOUNT-1": {
        "module": "PAccount1",
        "layers": ".model, .source",
        "imports": (
            "LidoSRv3.Audit.Source.AccountingCorrespondence",
            "LidoSRv3.Audit.Guarantees.Registry",
        ),
        "declarations": (
            ("def", "guarantee"),
            ("theorem", "source_report_before_reward"),
        ),
    },
}


def fail(message: str) -> None:
    raise ValueError(message)


def read(path: Path) -> str:
    if not path.is_file():
        fail(f"required public claim surface is missing: {path}")
    return path.read_text(encoding="utf-8")


def lean_surface(source: str) -> tuple[tuple[str, ...], tuple[tuple[str, str], ...]]:
    """Return imports and named public declarations after removing Lean comments."""
    without_blocks = re.sub(r"/-.*?-/", "", source, flags=re.DOTALL)
    without_comments = re.sub(r"--[^\n]*", "", without_blocks)
    imports = tuple(re.findall(r"^import\s+([^\s]+)\s*$", without_comments, re.MULTILINE))
    modifiers = r"(?:(?:public|protected|noncomputable|unsafe)\s+)*"
    attributes = r"(?:@\[[^\n]*\]\s*)*"
    kinds = r"def|theorem|lemma|abbrev|opaque|axiom|instance|structure|class|inductive"
    declarations = tuple(
        re.findall(
            rf"^{attributes}{modifiers}({kinds})\s+([A-Za-z_][A-Za-z0-9_']*)\b",
            without_comments,
            re.MULTILINE,
        )
    )
    return imports, declarations


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
        imports, declarations = lean_surface(lean)
        if imports != expected["imports"]:
            fail(f"{lean_path}: imports differ from the structural allowlist")
        if declarations != expected["declarations"]:
            fail(f"{lean_path}: public declarations differ from the structural allowlist")

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
