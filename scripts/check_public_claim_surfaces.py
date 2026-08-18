#!/usr/bin/env python3
"""Fail closed when public surfaces diverge from canonical Verity claims."""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path
from typing import NoReturn


CLAIMS = {
    "P-DEPOSIT-1": {
        "abstract_theorem": "LidoSRv3.Audit.Guarantees.PDeposit1.source_deposit_conserves_and_rolls_back",
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
        "abstract_theorem": "LidoSRv3.Audit.Guarantees.PTopup1.source_topup_conserves_and_rolls_back",
        "verity_status": "CHECKED",
        "verity_theorem": "LidoSRv3.Audit.Guarantees.PTopup1.verity_tx_simulates_source",
        "module": "PTopup1",
        "layers": ".model, .abstractTx, .source, .verityTx",
        "imports": (
            "LidoSRv3.Audit.Allocation",
            "LidoSRv3.Audit.Trace",
            "LidoSRv3.Audit.Source.TopupCorrespondence",
            "LidoSRv3.Audit.Verity.TopupTx",
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
            ("theorem", "verity_tx_simulates_source"),
        ),
    },
}


def fail(message: str) -> NoReturn:
    raise ValueError(message)


def read(path: Path) -> str:
    if not path.is_file():
        fail(f"required public claim surface is missing: {path}")
    return path.read_text(encoding="utf-8")


def strip_lean_comments(source: str) -> str:
    """Remove nested Lean comments while preserving strings and line positions."""
    result: list[str] = []
    index = 0
    block_depth = 0
    in_string = False
    while index < len(source):
        pair = source[index : index + 2]
        char = source[index]
        if block_depth:
            if pair == "/-":
                block_depth += 1
                result.extend("  ")
                index += 2
            elif pair == "-/":
                block_depth -= 1
                result.extend("  ")
                index += 2
            else:
                result.append("\n" if char == "\n" else " ")
                index += 1
        elif in_string:
            result.append(char)
            index += 1
            if char == "\\" and index < len(source):
                result.append(source[index])
                index += 1
            elif char == '"':
                in_string = False
        elif pair == "/-":
            block_depth = 1
            result.extend("  ")
            index += 2
        elif pair == "--":
            while index < len(source) and source[index] != "\n":
                result.append(" ")
                index += 1
        else:
            result.append(char)
            index += 1
            if char == '"':
                in_string = True
    if block_depth:
        fail("unterminated Lean block comment")
    if in_string:
        fail("unterminated Lean string literal")
    return "".join(result)


def normalize_quoted_identifier(token: str) -> str:
    """Normalize quoting without conflating distinct Lean names.

    Lean treats backslash spellings inside guillemets as identifier content (for
    example, ``«foo\\u0061»`` is not the name ``fooa``), so preserve them.
    """
    return unicodedata.normalize("NFC", token[1:-1])


def declaration_name(source: str, start: int) -> str:
    """Read one bare Unicode or guillemet-quoted Lean declaration name."""
    if start >= len(source):
        fail("public declaration is missing its name")
    if source[start] == "«":
        index = start + 1
        while index < len(source):
            if source[index] == "\\":
                index += 2
            elif source[index] == "»":
                return normalize_quoted_identifier(source[start : index + 1])
            else:
                index += 1
        fail("unterminated quoted Lean identifier")

    index = start
    while index < len(source) and not source[index].isspace() and source[index] not in ":([{":
        index += 1
    token = source[start:index]
    if not token or not token.replace("'", "").isidentifier():
        fail(f"cannot parse public declaration name near {source[start:start + 32]!r}")
    return unicodedata.normalize("NFC", token)


def lean_surface(source: str) -> tuple[tuple[str, ...], tuple[tuple[str, str], ...]]:
    """Return imports and normalized named public declarations."""
    without_comments = strip_lean_comments(source)
    # Lean.Parser.Module.Syntax defines an import as, in order, optional
    # `public`, optional `meta`, `import`, optional `all`, and one module name.
    # Tokens may be separated by any whitespace, including line breaks
    # (`public import all\n  Module`) or packed on one line
    # (`import Allowed import Unauthorized`). Keep this grammar-shaped model
    # in sync as a unit: a start-of-line matcher silently misses a second
    # import command on the same physical line.
    import_head = re.compile(
        r"(?<![\w.])(?:public\s+)?(?:meta\s+)?import\s+"
        r"(?:all\s+)?([^\W\d]\w*(?:\.[^\W\d]\w*)*)",
    )
    imports = tuple(match.group(1) for match in import_head.finditer(without_comments))
    modifiers = r"(?:(?:public|protected|noncomputable|unsafe)\s+)*"
    attributes = r"(?:@\[[^\n]*\]\s*)*"
    kinds = r"def|theorem|lemma|abbrev|opaque|axiom|instance|structure|class|inductive"
    heads = re.compile(rf"^[ \t]*{attributes}{modifiers}({kinds})\s+", re.MULTILINE)
    declarations = tuple(
        (match.group(1), declaration_name(without_comments, match.end()))
        for match in heads.finditer(without_comments)
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
        if not isinstance(row, dict):
            fail(f"canonical registry is missing {claim_id}")
        abstract = row.get("abstract")
        verity = row.get("verity")
        if not isinstance(abstract, dict) or not isinstance(verity, dict):
            fail(f"{claim_id}: assurance objectives are malformed")
        theorem = expected["abstract_theorem"]
        if abstract.get("status") != "CHECKED" or abstract.get("theorem") != theorem:
            fail(f"{claim_id}: checked abstract theorem differs from the canonical view")
        expected_verity_status = expected.get("verity_status", "PARTIAL")
        expected_verity_theorem = expected.get("verity_theorem")
        if (verity.get("status"), verity.get("theorem")) != (
            expected_verity_status, expected_verity_theorem
        ):
            fail(f"{claim_id}: faithful Verity status/theorem differs from the canonical view")

        table_pattern = re.compile(
            rf"^\|\s*\d+\s*\|\s*`{re.escape(claim_id)}`\s*\|[^\n]*\|\s*{expected_verity_status}[^\n]*\|$",
            re.MULTILINE,
        )
        if not table_pattern.search(readme):
            fail(f"README: {claim_id} faithful Verity status differs")

        module = expected["module"]
        lean_path = root / f"LidoSRv3/Audit/Guarantees/{module}.lean"
        lean = read(lean_path)
        definition = re.compile(
            rf"def guarantee\s*:\s*Guarantee\s*:=\s*"
            rf"⟨\.{module[0].lower() + module[1:]},\s*\[{re.escape(expected['layers'])}\]\u27e9"
        )
        if not definition.search(lean):
            fail(f"{lean_path}: checkedLayers differ from the blocked canonical view")
        if expected_verity_status == "PARTIAL" and "transaction claim is blocked" not in lean:
            fail(f"{lean_path}: missing explicit blocked-transaction description")
        imports, declarations = lean_surface(lean)
        if imports != expected["imports"]:
            fail(f"{lean_path}: imports differ from the structural allowlist")
        if declarations != expected["declarations"]:
            fail(f"{lean_path}: public declarations differ from the structural allowlist")

    if "a behaviorally faithful Verity model with a checked refinement theorem" not in readme:
        fail("README: missing the faithful-Verity assurance objective")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    try:
        check(args.root.resolve())
    except (OSError, ValueError) as exc:
        print(f"public claim surface check failed: {exc}", file=sys.stderr)
        return 1
    print("public claim surfaces match canonical faithful-Verity claims")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
