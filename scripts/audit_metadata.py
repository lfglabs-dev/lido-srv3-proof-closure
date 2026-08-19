#!/usr/bin/env python3
"""Validate the two-artifact assurance contract and render review views.

Lean proofs remain authoritative. Metadata records the abstract theorem, the
Verity Executable Contract theorem (or honest partial state), and one actionable gap class.
General Yul/EVM/deployment refinement is deliberately not an assurance lane.
"""

import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "audit"
CANONICAL_IDS = [
    "P-ALLOC-1", "P-ALLOC-2", "P-DEPOSIT-1", "P-TOPUP-1",
    "P-ACCOUNT-1", "P-RESERVE-1", "P-ETH-1", "P-ADDRESS-1",
    "P-TOPUP-2", "P-CONSOLIDATION-1", "P-SSZ-1",
]
SUBORDINATE_IDS = [
    "P-SSZ-1.deposit-data-root", "P-SSZ-1.gindex-concat",
    "P-SSZ-1.abstract-digest", "P-CONSOLIDATION-1.abstract-flow-model",
    "P-ALLOC-1.eugene-bound", "P-ADDRESS-1.yul-interface-harness",
    "P-DEPOSIT-1.verity-tx-rollback.tx",
    "P-CONSOLIDATION-1.fee-refinement.tx",
    "P-SSZ-1.tx-execution-simulation", "P-ETH-1a", "P-ETH-1b",
    "P-ADDRESS-1.denote-admission", "P-DEREF-1",
    "P-RESERVE-RELATIONAL",
]
EXPECTED_IDS = CANONICAL_IDS + SUBORDINATE_IDS
ASSURANCE_STATUSES = {"OPEN", "PARTIAL", "CHECKED"}
GAP_KINDS = {
    "NONE", "VERITY_FEATURE_REQUIRED", "PROPERTY_FALSE",
    "ASSUMPTION_REQUIRED", "IMPLEMENTATION_PENDING",
}
ASSUMPTION_FIELDS = {
    "id", "accepted", "risk", "justification", "severity",
    "violation_impact", "validation", "removal_path",
}
PINNED = {
    "lido_core": ("https://github.com/lidofinance/core.git", "af095e48bbc1c3841c2c9936219c8461af01056b"),
    "verity": ("https://github.com/lfglabs-dev/verity.git", "a063bfc869735045354ebc3862ca08859da0f56e"),
    "evmyullean": ("https://github.com/lfglabs-dev/EVMYulLean.git", "f7e4ee0dc8f8d5265ce822a937ab5be771f182e9"),
    "mathlib": ("https://github.com/leanprover-community/mathlib4.git", "fabf563a7c95a166b8d7b6efca11c8b4dc9d911f"),
}
EXPECTED_AUTHORITY = "Lean theorem statements and proofs are authoritative; metadata classifies but never closes evidence."
EXPECTED_OBJECTIVE = "Prove an abstract Lean model, a Verity Lean library program, and a Verity Executable Contract for each guarantee, or classify the gap. General Yul/EVM/deployment closure is out of scope; SSZ alone carries a targeted Yul binding."
EXPECTED_CANONICAL_CLAIMS = {
    "P-ALLOC-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PAlloc1.checked_execute", "CHECKED", "LidoSRv3.Audit.Guarantees.PAlloc1.verity_tx_simulates_allocation", "IMPLEMENTATION_PENDING", ("A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD")),
    "P-ALLOC-2": ("CHECKED", "LidoSRv3.Audit.Guarantees.PAlloc2.proportional_step_correspondence_and_bounded", "CHECKED", "LidoSRv3.Audit.Guarantees.PAlloc2.verity_tx_simulates_min_first_distribution", "IMPLEMENTATION_PENDING", ("A-HANDWRITTEN-MINFIRST", "A-VERITY-SCAFFOLD")),
    "P-DEPOSIT-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PDeposit1.source_deposit_conserves_and_rolls_back", "CHECKED", "LidoSRv3.Audit.Guarantees.PDeposit1.verity_tx_composes_deposit_conservation_and_rollback", "NONE", ("A-ABSTRACT-TX", "A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD")),
    "P-TOPUP-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PTopup1.source_topup_conserves_and_rolls_back", "CHECKED", "LidoSRv3.Audit.Guarantees.PTopup1.verity_tx_simulates_source", "NONE", ("A-ABSTRACT-TX", "A-SOURCE-SHAPED", "A-TOPUP-NOWRAP", "A-VERITY-SCAFFOLD")),
    "P-ACCOUNT-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PAccount1.mint_after_read_discipline", "CHECKED", "LidoSRv3.Audit.Guarantees.PAccount1.verity_tx_simulates_oracle_report", "IMPLEMENTATION_PENDING", ("A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD")),
    "P-RESERVE-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PReserve1.source_spend_preserves_withdrawal_reserve", "CHECKED", "LidoSRv3.Audit.Guarantees.PReserve1.verity_tx_simulates_reserve_spec", "IMPLEMENTATION_PENDING", ("A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD")),
    "P-ETH-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PEth1.eth_flow_parent", "CHECKED", "LidoSRv3.Audit.Guarantees.PEth1.verity_tx_composes_value_flow_and_rollback", "IMPLEMENTATION_PENDING", ("A-ABSTRACT-TX", "A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD")),
    "P-ADDRESS-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PAddress1.universal_address_writer_equivariance", "CHECKED", "LidoSRv3.Audit.Guarantees.PAddress1.abstract_source_verity_tx_address_equivariance", "IMPLEMENTATION_PENDING", ("A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD")),
    "P-TOPUP-2": ("CHECKED", "LidoSRv3.Audit.Guarantees.PTopup2.aggregate_bounded_by_block_cap", "CHECKED", "LidoSRv3.Audit.Guarantees.PTopup2.verity_tx_simulates_topup2_spec", "IMPLEMENTATION_PENDING", ("A-SOURCE-SHAPED", "A-TOPUP-NOWRAP", "A-VERITY-SCAFFOLD")),
    "P-CONSOLIDATION-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PConsolidation1.source_consolidation_preserves_eligibility_value_atomicity", "CHECKED", "LidoSRv3.Audit.Guarantees.PConsolidation1.verity_tx_simulates_consolidation", "IMPLEMENTATION_PENDING", ("A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD")),
    "P-SSZ-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PSsz1.composed_ssz_encoding", "CHECKED", "LidoSRv3.Audit.Guarantees.PSsz1.verity_tx_simulates_ssz_encoding", "IMPLEMENTATION_PENDING", ("A-SHA256-FFI", "A-MULTI-NODE-TRANSPORT", "A-SOLC-TRUSTED", "A-YUL-INTERFACE")),
}
EXPECTED_CANONICAL_DETAIL_SHA256 = {
    "P-ALLOC-1": "e40061e5c9f9dfee5fed47f93bcb6111d58804011e8c1994e72b505dd9944a4c",
    "P-ALLOC-2": "e3756e8bd136311ff0c4dcc8310369a9a0e56285be2287d62bc7ea19c8674bbd",
    "P-DEPOSIT-1": "d968278df75171e0f30b4313d99b3d1df2f1ccdb9d2862c114d02dee79d83bba",
    "P-TOPUP-1": "4e62eba04399db42903b0943efe58c5b7b146992c84c3f51ed11820c14c2984e",
    "P-ACCOUNT-1": "4d078d6909b4eaba18eb36ca2e7687ae55e55f551c080801caf8dc42de7c3e90",
    "P-RESERVE-1": "1487aff60c3d8b385d046b1029422b6880cce4003eaff6603db974c7ec2b57b1",
    "P-ETH-1": "75ad31154b8592c7c35d9d75000ff493c08aaddf0ae013585ef58dbcc8406dad",
    "P-ADDRESS-1": "f4ff64b6dfffc8920b37d04be01eb0afc4b01b6432f5ceb2d1c3637d44ba8650",
    "P-TOPUP-2": "194cbb0a5d081ea17a30574de5e1255a9d748e9c34fad0a371010662e93a2ef6",
    "P-CONSOLIDATION-1": "6c1816311aa78f70f7d35a678a1070c35e2659dd38e0083922f988eb0e67cf6d",
    "P-SSZ-1": "d7f0a2a3bb42065ba067793c87027ebfbde8d8b95c1c3050c00369afc9377d3c",
}
EXPECTED_PRIORITIES = {
    "P-RESERVE-1": "DONE",
    "P-DEPOSIT-1": "DONE", "P-TOPUP-1": "DONE", "P-ACCOUNT-1": "DONE",
    "P-ALLOC-1": "DONE", "P-ALLOC-2": "DONE", "P-ETH-1": "DONE",
    "P-ADDRESS-1": "DONE", "P-TOPUP-2": "DONE", "P-CONSOLIDATION-1": "DONE",
    "P-SSZ-1": "DONE",
}


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def require(condition, message):
    if not condition:
        raise SystemExit(f"audit metadata error: {message}")


def nonempty_strings(value):
    return isinstance(value, list) and all(isinstance(x, str) and x.strip() for x in value)


def validate_pins(lock, manifest, source_map):
    require(lock.get("schema") == "lido-srv3-artifacts-lock-v1", "artifact lock schema differs")
    pins = lock.get("pins", {})
    for name, (repository, commit) in PINNED.items():
        require(pins.get(name) == {"repository": repository, "commit": commit}, f"{name} pin differs")
    require(pins.get("lean") == {"toolchain": "leanprover/lean4:v4.31.0"}, "Lean toolchain pin differs")
    require(lock.get("unavailable") == {
        "sha256_ffi_implementation_identity": {"status": "MISSING", "blocked": True, "value": None},
    }, "artifact lock must not retain retired deployment-provenance blockers")
    require(manifest.get("schema") == "srv3-audit-manifest-v1", "audit manifest schema differs")
    revisions = manifest.get("source_revisions", {})
    require(revisions == {"lido": PINNED["lido_core"][1], "verity": PINNED["verity"][1], "lean": "v4.31.0"}, "manifest source revisions differ")
    policy = manifest.get("proof_policy", {})
    require(policy.get("project_axioms") == 0 and policy.get("sorry") == 0 and
            policy.get("admit") == 0 and policy.get("unsafe_proof_escapes") == 0,
            "manifest proof policy permits proof escapes")
    require(policy.get("report_entrypoint") == "LidoSRv3.Audit.Trust", "Trust report entrypoint differs")
    require(source_map.get("schema") == "lido-srv3-minimal-11-source-map-v3", "source-map schema differs")
    require(source_map.get("pinned_source") == f"lidofinance/core@{PINNED['lido_core'][1]}", "source-map pin differs")
    require(source_map.get("scope") == {
        "public_guarantee_count": 11,
        "assurance_contract": ["ABSTRACT_LEAN", "FAITHFUL_VERITY"],
        "general_yul_evm_deployment": "OUT_OF_SCOPE",
        "ssz_deployed_yul_binding": "TARGETED_ONLY",
        "metadata_is_proof_progress": False,
    }, "source-map assurance scope differs")
    require(source_map.get("accepted_risks") == {
        "baseline": "DEV-431-READY_NOT_AUDIT-CERT",
        "multi_node_certification": "UNAVAILABLE_OR_PARTIAL_NON_BLOCKING",
        "sha256_ffi": "OPAQUE",
        "solc": "TRUSTED_WHEN_ARTIFACTS_ARE_PRODUCED",
    }, "source-map accepted risks differ")
    require(source_map.get("ssz_claim") == {
        "level": "STRUCTURAL_AND_TARGETED_BINDING_PENDING",
        "includes": ["structures", "generalized_indices", "pivot_and_branch_traversal", "wrapper_binding", "operation_binding"],
        "excludes": ["FULL_SSZ", "SHA256_CRYPTOGRAPHIC_CORRECTNESS", "GENERAL_YUL_REFINEMENT", "GENERAL_EVM_REFINEMENT", "GENERAL_DEPLOYMENT_PROVENANCE"],
        "deployed_yul_binding": "OPEN_FOR_IMPORTED_SSZ_FRAGMENT_ONLY",
    }, "source-map SSZ boundary differs")
    targets = source_map.get("targets")
    require(isinstance(targets, list), "source-map targets must be a list")
    target_ids = [x.get("id") for x in targets]
    require(len(target_ids) == len(set(target_ids)), "duplicate source-map target")
    required_targets = set(CANONICAL_IDS) - {"P-ETH-1"}
    require(required_targets <= set(target_ids), "canonical source targets are incomplete")
    require({"P-ETH-1a", "P-ETH-1b"} <= set(target_ids), "P-ETH-1 child source targets are incomplete")
    sha = PINNED["lido_core"][1]
    for target in targets:
        require(target.get("status") in {"MAPPED", "UNMAPPED"}, f"{target.get('id')}: invalid source status")
        spans = target.get("spans")
        require(isinstance(spans, list), f"{target.get('id')}: spans must be a list")
        if target.get("status") == "MAPPED":
            require(spans, f"{target.get('id')}: mapped target has no spans")
        seen = set()
        for span in spans:
            require(set(span) == {"repository", "source_sha", "path", "function", "start_line", "end_line", "permalink"}, f"{target.get('id')}: malformed source span")
            require(span["repository"] == "lidofinance/core" and span["source_sha"] == sha, f"{target.get('id')}: source span pin differs")
            require(isinstance(span["start_line"], int) and span["start_line"] > 0 and span["end_line"] >= span["start_line"], f"{target.get('id')}: invalid source lines")
            expected = f"https://github.com/lidofinance/core/blob/{sha}/{span['path']}#L{span['start_line']}-L{span['end_line']}"
            require(span["permalink"] == expected, f"{target.get('id')}: source permalink is not immutable/exact")
            key = tuple(sorted(span.items()))
            require(key not in seen, f"{target.get('id')}: duplicate source span")
            seen.add(key)


def validate_assumptions(data):
    require(data.get("schema") == "lido-srv3-assumptions-v2", "assumption schema differs")
    rows = data.get("assumptions")
    require(isinstance(rows, list) and rows, "assumption registry is empty")
    ids = [row.get("id") for row in rows]
    require(len(ids) == len(set(ids)), "duplicate assumption id")
    for row in rows:
        require(set(row) == ASSUMPTION_FIELDS, f"{row.get('id')}: assumption fields differ")
        require(re.fullmatch(r"A-[A-Z0-9-]+", row["id"]) is not None, f"{row['id']}: invalid assumption id")
        require(row["accepted"] is True, f"{row['id']}: assumption must be explicitly accepted")
        require(row["severity"] in {"LOW", "MEDIUM", "HIGH", "CRITICAL"}, f"{row['id']}: invalid severity")
        for field in ASSUMPTION_FIELDS - {"id", "accepted", "severity"}:
            require(isinstance(row[field], str) and row[field].strip(), f"{row['id']}: empty {field}")
    require("A-SOLC-TRUSTED" in ids and "A-SHA256-FFI" in ids, "explicit solc/SHA-256 trust boundaries are missing")
    return set(ids)


def validate_classification(row, assumption_ids):
    c = row.get("classification")
    require(isinstance(c, dict) and c.get("kind") in GAP_KINDS, f"{row['id']}: invalid gap classification")
    kind = c["kind"]
    missing = row["fidelity"]["missing"]
    fully_checked = row["abstract"]["status"] == row["verity"]["status"] == "CHECKED" and not missing
    require((kind == "NONE") == fully_checked, f"{row['id']}: NONE is reserved for fully checked guarantees")
    if kind == "VERITY_FEATURE_REQUIRED":
        require(set(c) == {"kind", "feature", "upstream_test", "consumer"}, f"{row['id']}: feature gap fields differ")
        require(c["consumer"] == row["id"] and c["feature"].strip() and c["upstream_test"].strip(), f"{row['id']}: incomplete Verity feature gap")
    elif kind == "PROPERTY_FALSE":
        require(set(c) == {"kind", "counterexample", "reproduction"}, f"{row['id']}: false-property gap lacks counterexample")
        require(c["counterexample"].strip() and c["reproduction"].strip(), f"{row['id']}: empty counterexample")
    elif kind == "ASSUMPTION_REQUIRED":
        require(set(c) == {"kind", "assumption"}, f"{row['id']}: assumption gap fields differ")
        require(c["assumption"] in row["assumptions"] and c["assumption"] in assumption_ids, f"{row['id']}: gap assumption is not linked")
    elif kind == "IMPLEMENTATION_PENDING":
        require(set(c) == {"kind", "work"} and c["work"].strip(), f"{row['id']}: pending work is incomplete")
    else:
        require(set(c) == {"kind"}, f"{row['id']}: NONE may not hide extra claims")


def validate_guarantees(data, assumption_ids):
    require(data.get("schema") == "lido-srv3-assurance-contract-v4", "guarantee schema differs")
    require(data.get("authority") == EXPECTED_AUTHORITY, "authority wording differs")
    require(data.get("objective") == EXPECTED_OBJECTIVE, "project objective differs")
    rows = data.get("guarantees")
    require(isinstance(rows, list), "guarantees must be a list")
    ids = [row.get("id") for row in rows]
    require(ids == EXPECTED_IDS, "guarantee IDs/order differ from canonical public and subordinate surfaces")
    for row in rows:
        required = {"id", "summary", "abstract", "verity", "fidelity", "classification", "assumptions", "next_gate", "reproduction"}
        require(required <= set(row), f"{row['id']}: assurance contract fields are incomplete")
        require(isinstance(row["summary"], str) and row["summary"].strip(), f"{row['id']}: empty summary")
        for layer in ("abstract", "verity"):
            item = row[layer]
            require(set(item) == {"status", "theorem"}, f"{row['id']}: {layer} fields differ")
            require(item["status"] in ASSURANCE_STATUSES, f"{row['id']}: invalid {layer} status")
            if item["status"] == "CHECKED":
                require(isinstance(item["theorem"], str) and item["theorem"].startswith("LidoSRv3."), f"{row['id']}: checked {layer} lacks a Lean theorem")
            else:
                require(item["theorem"] is None, f"{row['id']}: non-checked {layer} may not expose a closure theorem")
        fidelity = row["fidelity"]
        require(set(fidelity) == {"covered", "missing"}, f"{row['id']}: fidelity fields differ")
        require(nonempty_strings(fidelity["covered"]), f"{row['id']}: invalid covered fidelity list")
        require(nonempty_strings(fidelity["missing"]), f"{row['id']}: invalid missing fidelity list")
        require(len(fidelity["covered"]) == len(set(fidelity["covered"])) and len(fidelity["missing"]) == len(set(fidelity["missing"])), f"{row['id']}: duplicate fidelity item")
        require(set(fidelity["covered"]).isdisjoint(fidelity["missing"]), f"{row['id']}: fidelity item both covered and missing")
        require(isinstance(row["assumptions"], list) and len(row["assumptions"]) == len(set(row["assumptions"])), f"{row['id']}: duplicate assumptions")
        require(set(row["assumptions"]) <= assumption_ids, f"{row['id']}: unknown assumption")
        require(isinstance(row["next_gate"], str) and row["next_gate"].strip(), f"{row['id']}: empty next gate")
        require(set(row["reproduction"]) == {"command", "expected"} and all(isinstance(v, str) and v.strip() for v in row["reproduction"].values()), f"{row['id']}: reproduction record is incomplete")
        validate_classification(row, assumption_ids)
        if row["id"] in EXPECTED_CANONICAL_CLAIMS:
            require(row.get("roadmap_priority") == EXPECTED_PRIORITIES[row["id"]],
                    f"{row['id']}: roadmap priority differs")
            actual = (
                row["abstract"]["status"], row["abstract"]["theorem"],
                row["verity"]["status"], row["verity"]["theorem"],
                row["classification"]["kind"], tuple(row["assumptions"]),
            )
            require(actual == EXPECTED_CANONICAL_CLAIMS[row["id"]],
                    f"{row['id']}: canonical assurance claim differs")
            detail = {key: row[key] for key in (
                "summary", "fidelity", "classification", "next_gate", "reproduction"
            )}
            digest = hashlib.sha256(json.dumps(
                detail, sort_keys=True, separators=(",", ":")
            ).encode()).hexdigest()
            require(digest == EXPECTED_CANONICAL_DETAIL_SHA256[row["id"]],
                    f"{row['id']}: canonical assurance detail differs")
        if row["id"] == "P-SSZ-1":
            binding = row.get("special_bindings", {}).get("deployed_yul")
            require(binding == {"status": "OPEN", "scope": "SSZ helper/wrapper Yul fragment only", "imported_digest": None, "deployed_digest": None, "assumption": "A-SOLC-TRUSTED"}, "P-SSZ-1: targeted deployed-Yul binding differs")
        else:
            require("special_bindings" not in row, f"{row['id']}: deployment/Yul bindings are SSZ-only")
        forbidden = " ".join([row["next_gate"], *row["fidelity"]["missing"]]).lower()
        if row["id"] != "P-SSZ-1":
            require(not re.search(r"\b(yul|evm|bytecode|runtime provenance|deployment provenance)\b", forbidden), f"{row['id']}: general Yul/EVM/deployment work reintroduced")
    return rows


def validate():
    registry = load(AUDIT / "guarantees.yaml")
    assumptions = load(AUDIT / "assumptions.yaml")
    lock = load(AUDIT / "artifacts.lock.json")
    manifest = load(ROOT / "verity/targets/audit-manifest.json")
    source_map = load(AUDIT / "source-map.yaml")
    assumption_ids = validate_assumptions(assumptions)
    validate_pins(lock, manifest, source_map)
    return validate_guarantees(registry, assumption_ids)


def rendered(rows):
    canonical = rows[:len(CANONICAL_IDS)]
    header = "<!-- GENERATED by scripts/audit_metadata.py; edit structured metadata, not this view. Lean is theorem authority. -->\n\n"
    roadmap_parts = [header + "# ROADMAP\n\n"
        "## P0 — keep published claims honest\n\n"
        "- Do not promote a parent guarantee without a composed theorem on the claimed plane.\n"
        "- `make test` and `make prove` remain the local gates; metadata never closes evidence.\n\n"
        "## P1 — first complete property: `P-RESERVE-RELATIONAL`\n\n"
        "Fix report, queue, and buffer. Two states that differ only in `depositsReserve` must yield the same prefinalized/finalized ranges and the same locked ETH. Checked `P-RESERVE-1` spending is a child, not this fact.\n\n"
        "Closed: a spec, an independently defined pinned-source interpreter, an executable Verity transaction that computes the five observables from storage and memory, the composition theorem, a rejected reserve→range mutant, report/queue/buffer mutants, and rollback after a mid-write. The parent is registered as a supplemental row now that composition exists.\n\n"
        "## P2 — allocation and value conservation\n\n"
        "Order: P-ALLOC-1/2, then deposit/top-up allocation, WC01/WC02 eligibility, Lido debit, Beacon credit, module delta, rollback. The P-RESERVE-RELATIONAL gate on other parent-closure lanes is now satisfied.\n\n"
        "## P3 — remaining parents\n\n"
        "Resume Accounting, Address, Topup2, Deposit, Topup1, ETH, Consolidation, and SSZ only with the composition patterns from P1/P2.\n\n"
        "## Current guarantee registry\n"]
    labels = {
        "P1": "Deferred P1-labelled registry rows",
        "P2": "Deferred P2-labelled registry rows",
        "P3": "Deferred P3-labelled registry rows",
        "DONE": "Checked baseline to preserve",
    }
    for priority in ("P1", "P2", "P3", "DONE"):
        roadmap_parts.append(f"\n## {labels[priority]}\n")
        roadmap_parts.extend(
            f"\n- `{r['id']}` — **{r['classification']['kind']}**: {r['next_gate']}"
            for r in canonical if r["roadmap_priority"] == priority
        )
        roadmap_parts.append("\n")
    roadmap = "".join(roadmap_parts)
    lines = ["# STATUS", "", "| ID | Abstract Lean | Verity Executable Contract | Fidelity gap | Classification | Assumptions |", "| --- | --- | --- | --- | --- | --- |"]
    for r in canonical:
        missing = "; ".join(r["fidelity"]["missing"]) or "—"
        assumptions = ", ".join(f"`{x}`" for x in r["assumptions"]) or "—"
        lines.append(f"| `{r['id']}` | {r['abstract']['status']} | {r['verity']['status']} | {missing} | {r['classification']['kind']} | {assumptions} |")
    status = header + "\n".join(lines) + "\n"
    reproduce = header + "# REPRODUCE\n\n" + "\n".join(f"- `{r['id']}`: `{r['reproduction']['command']}` — {r['reproduction']['expected']}" for r in canonical) + "\n"
    return {"ROADMAP.md": roadmap, "STATUS.md": status, "REPRODUCE.md": reproduce}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("generate", "check"))
    parser.add_argument("--expect-canonical-count", type=int)
    args = parser.parse_args()
    rows = validate()
    if args.expect_canonical_count is not None:
        require(len(CANONICAL_IDS) == args.expect_canonical_count, f"canonical guarantee count is {len(CANONICAL_IDS)}, expected {args.expect_canonical_count}")
    views = rendered(rows)
    if args.command == "generate":
        for name, content in views.items():
            (AUDIT / name).write_text(content, encoding="utf-8")
        print("generated audit/ROADMAP.md audit/STATUS.md audit/REPRODUCE.md")
    else:
        for name, content in views.items():
            require((AUDIT / name).read_text(encoding="utf-8") == content, f"{name} is stale; run scripts/audit_metadata.py generate")
        print(f"audit metadata v4 ok: {len(CANONICAL_IDS)} canonical guarantees + {len(SUBORDINATE_IDS)} subordinate evidence rows")


if __name__ == "__main__":
    main()
