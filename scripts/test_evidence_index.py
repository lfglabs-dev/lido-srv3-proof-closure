#!/usr/bin/env python3
"""Focused theorem-resolution and evidence-index regression fixtures."""

import copy
import tempfile
from pathlib import Path

from evidence_index import EvidenceError, evidence_data, render_markdown, validate_and_resolve


STATUSES_OPEN = {
    "model": "OPEN", "algorithm": "NOT_APPLICABLE", "source": "OPEN",
    "tx": "OPEN", "yul": "OPEN", "evm": "OPEN", "crypto": "NOT_APPLICABLE",
}


def row(row_id, theorem=None, parent=None, wording=None):
    statuses = dict(STATUSES_OPEN)
    planes = []
    if theorem:
        statuses["model"] = "LEAN_CHECKED"
        planes = ["model"]
    value = {
        "id": row_id,
        "catalogue_wording": wording or f"Exact wording for {row_id}",
        "theorem": theorem,
        "theorem_planes": planes,
        "statuses": statuses,
        "assumptions": [],
        "reproduction": {"command": "lake build Fixture", "expected": "bounded fixture only"},
    }
    if parent:
        value.update(parent_id=parent, source_plane_scope=f"bounded {row_id} scope")
    return value


def expect_error(rows, root, needle):
    try:
        validate_and_resolve(rows, root)
    except EvidenceError as error:
        assert needle in str(error), error
    else:
        raise AssertionError(f"expected EvidenceError containing {needle!r}")


def main():
    with tempfile.TemporaryDirectory(prefix="evidence-index-") as directory:
        root = Path(directory)
        source = root / "LidoSRv3/Audit/Guarantees"
        source.mkdir(parents=True)
        (source / "PEth1.lean").write_text(
            "namespace LidoSRv3.Audit.Guarantees.PEth1\n"
            "theorem eth_flow_confined : True := by trivial\n"
            "theorem consolidation_fee_path_confined : True := by trivial\n"
            "end LidoSRv3.Audit.Guarantees.PEth1\n",
            encoding="utf-8",
        )
        (source / "PChecked.lean").write_text(
            "namespace LidoSRv3.Audit.Guarantees.PChecked\n"
            "theorem checked_parent : True := by trivial\n"
            "end LidoSRv3.Audit.Guarantees.PChecked\n",
            encoding="utf-8",
        )
        rows = [
            row("P-ETH-1", wording="Broad ETH guarantee remains OPEN."),
            row("P-CONSOLIDATION-1", wording="Broad consolidation guarantee remains OPEN."),
            row("P-CHECKED", "LidoSRv3.Audit.Guarantees.PChecked.checked_parent"),
            row("P-ETH-1a", "LidoSRv3.Audit.Guarantees.PEth1.eth_flow_confined", "P-ETH-1"),
            row("P-ETH-1b", "LidoSRv3.Audit.Guarantees.PEth1.consolidation_fee_path_confined", "P-ETH-1"),
            {
                **row("P-SUPPLEMENTAL", "LidoSRv3.Audit.Guarantees.PChecked.checked_parent"),
                "source_plane_scope": "standalone bounded supplemental scope",
            },
        ]
        resolved = validate_and_resolve(rows, root)
        rendered = render_markdown(evidence_data(rows, resolved))
        assert rendered.count("**Parent theorem: NO PARENT THEOREM**") == 2
        assert "P-ETH-1a" in rendered and "P-ETH-1b" in rendered
        assert "Subordinate evidence (does not prove the parent)" in rendered
        assert "PChecked.lean#L2" in rendered
        assert "Standalone supplemental evidence" in rendered
        assert "P-SUPPLEMENTAL" in rendered
        assert evidence_data(rows, resolved)["supplemental"][0]["id"] == "P-SUPPLEMENTAL"

        missing = copy.deepcopy(rows)
        missing[2]["theorem"] = "LidoSRv3.Audit.Guarantees.PChecked.missing"
        expect_error(missing, root, "declared theorem not found")

        # These public rows have historically shared short theorem names with
        # nearby evidence.  A bare short name must never resolve by accident.
        for row_id, short_name in (
            ("P-TOPUP-1", "verity_tx_simulates_source"),
            ("P-ACCOUNT-1", "source_to_verityTx"),
            ("P-SSZ-1", "structural_witness_binding_sound"),
        ):
            short = copy.deepcopy(rows)
            short.append(row(row_id, short_name))
            expect_error(short, root, "declared theorem not found")

        duplicate = source / "Duplicate.lean"
        duplicate.write_text((source / "PChecked.lean").read_text(encoding="utf-8"), encoding="utf-8")
        expect_error(rows, root, "declared theorem is ambiguous")
        duplicate.unlink()

        promoted = copy.deepcopy(rows)
        promoted[0]["theorem"] = promoted[3]["theorem"]
        promoted[0]["theorem_planes"] = ["model"]
        promoted[0]["statuses"]["model"] = "LEAN_CHECKED"
        expect_error(promoted, root, "broad parent text is paired with a child-only theorem")

    print("evidence index fixtures ok: open parents, checked, missing, ambiguous, stale scope")


if __name__ == "__main__":
    main()
