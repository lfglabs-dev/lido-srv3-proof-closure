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
import subprocess
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

sys.path.insert(0, str(Path(__file__).resolve().parent))

import gfm_table  # noqa: E402  (sibling module, located above)
import markdown_text  # noqa: E402  (sibling module, located above)

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "audit"
R1_REVIEW_BASE = "3d505676229bb19436d49e023c065d179ca5d5d0"
# The report calls this commit its certified review basis.  Keep the exact
# generator inputs bound both to that Git object and to their expected bytes:
# a changed registry, source map, or Trust allowlist must not be presented as
# if it had that review.
# This exact family is every structured input used to render the R1 review
# report.  A normal regeneration may never pair changed family content with a
# stale certified basis.
R1_REPORT_INPUT_SHA256 = {
    "audit/guarantees.yaml": "46631450fb99a6cc57e5a974f250a04162b160160b22db4f78c629deacfeed1e",
    "audit/source-map.yaml": "e592f4e15e9d3ce8ffdcefdc87bb664ac404c6d0b7447e29e35d5c60611eaba6",
    "audit/trust-native-decide-allowlist.txt": "4874951cd0717f16756f3f644c424f06bdbbfcca1561173b32fd134b1fb6730c",
}
CANONICAL_IDS = [
    "P-ALLOC-1", "P-ALLOC-2", "P-DEPOSIT-1", "P-TOPUP-1",
    "P-ACCOUNT-1", "P-RESERVE-1", "P-CONSOLIDATION-ETH-1", "P-ADDRESS-1",
    "P-TOPUP-2", "P-CONSOLIDATION-1", "P-SSZ-1",
]
SUBORDINATE_IDS = [
    "P-SSZ-1.deposit-data-root", "P-SSZ-1.gindex-concat",
    "P-SSZ-1.abstract-digest", "P-CONSOLIDATION-1.abstract-flow-model",
    "P-ALLOC-1.eugene-bound", "P-ADDRESS-1.yul-interface-harness",
    "P-DEPOSIT-1.verity-tx-rollback.tx",
    "P-CONSOLIDATION-1.fee-refinement.tx",
    "P-SSZ-1.tx-execution-simulation",
    "P-ADDRESS-1.denote-admission",
    "P-RESERVE-RELATIONAL",
    "P-ALLOC-EXEC-1", "P-ETH-JOURNAL-1", "P-VAULT-ETH-1", "P-ORACLE-SUPPLY-1",
    "P-ADDRESS-BATCH-1", "P-SSZ-LIVE-1", "P-CONSOLIDATION-VALUE-1",
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
    "lido_core": ("https://github.com/lidofinance/core.git", "17005714f151e5502c559932319a3f2f74ac2436"),
    "verity": ("https://github.com/lfglabs-dev/verity.git", "e977aaad6e1a9e92e0132d41b3d33a14135a4d46"),
    "evmyullean": ("https://github.com/lfglabs-dev/EVMYulLean.git", "f7e4ee0dc8f8d5265ce822a937ab5be771f182e9"),
    "mathlib": ("https://github.com/leanprover-community/mathlib4.git", "fabf563a7c95a166b8d7b6efca11c8b4dc9d911f"),
}
EXPECTED_AUTHORITY = "Lean theorem statements and proofs are authoritative; metadata classifies but never closes evidence."
EXPECTED_OBJECTIVE = "Prove an abstract Lean model, a Verity Lean library program, and a Verity Executable Contract for each guarantee, or classify the gap. General Yul/EVM/deployment closure is out of scope; SSZ alone carries a targeted Yul binding."
EXPECTED_CANONICAL_CLAIMS = {
    "P-ALLOC-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PAlloc1.checked_execute", "CHECKED", "LidoSRv3.Audit.Guarantees.PAlloc1.verity_tx_simulates_allocation_count_from_storage", "IMPLEMENTATION_PENDING", ("A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD")),
    "P-ALLOC-2": ("CHECKED", "LidoSRv3.Audit.Guarantees.PAlloc2.step_correspondence_and_full_loop_conservation", "CHECKED", "LidoSRv3.Audit.Guarantees.PAlloc2.verity_tx_simulates_min_first_distribution", "IMPLEMENTATION_PENDING", ("A-HANDWRITTEN-MINFIRST", "A-VERITY-SCAFFOLD")),
    "P-DEPOSIT-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PDeposit1.source_deposit_conserves_and_rolls_back", "CHECKED", "LidoSRv3.Audit.Guarantees.PDeposit1.NFrame.verity_tx_composes_nframe_deposit", "IMPLEMENTATION_PENDING", ("A-ABSTRACT-TX", "A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD", "A-DEPOSIT-CONTRACT", "A-DEPOSIT-32-ETHER")),
    "P-TOPUP-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PTopup1.source_topup_conserves_and_rolls_back", "CHECKED", "LidoSRv3.Audit.Guarantees.PTopup1.verity_tx_simulates_source_with_nonzero_wrap_close", "IMPLEMENTATION_PENDING", ("A-ABSTRACT-TX", "A-SOURCE-SHAPED", "A-TOPUP-NOWRAP", "A-VERITY-SCAFFOLD", "A-TOPUP-BEACON-ADDRESS")),
    "P-ACCOUNT-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PAccount1.mint_after_read_discipline", "CHECKED", "LidoSRv3.Audit.Guarantees.PAccount1.verity_tx_simulates_oracle_report", "IMPLEMENTATION_PENDING", ("A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD")),
    "P-RESERVE-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PReserve1.source_spend_preserves_withdrawal_reserve", "CHECKED", "LidoSRv3.Audit.Guarantees.PReserve1.verity_tx_simulates_reserve_spec", "IMPLEMENTATION_PENDING", ("A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD")),
    "P-CONSOLIDATION-ETH-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PConsolidationEth1.eth_flow_parent_at_canonical", "CHECKED", "LidoSRv3.Audit.Guarantees.PConsolidationEth1.verity_tx_success_and_revert_partition", "IMPLEMENTATION_PENDING", ("A-ABSTRACT-TX", "A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD", "A-CANONICAL-REQUEST-ADDRESS")),
    "P-ADDRESS-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PAddress1.universal_address_writer_equivariance", "CHECKED", "LidoSRv3.Audit.Guarantees.PAddress1.abstract_source_verity_tx_address_equivariance", "IMPLEMENTATION_PENDING", ("A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD")),
    "P-TOPUP-2": ("CHECKED", "LidoSRv3.Audit.Guarantees.PTopup2.aggregate_bounded_by_block_cap", "CHECKED", "LidoSRv3.Audit.Guarantees.PTopup2.verity_tx_simulates_topup2_spec", "IMPLEMENTATION_PENDING", ("A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD")),
    "P-CONSOLIDATION-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PConsolidation1.source_consolidation_preserves_eligibility_value_atomicity", "CHECKED", "LidoSRv3.Audit.Guarantees.PConsolidation1.verity_tx_simulates_consolidation", "IMPLEMENTATION_PENDING", ("A-SOURCE-SHAPED", "A-VERITY-SCAFFOLD", "A-CONSOLIDATION-GATEWAY-NONZERO")),
    "P-SSZ-1": ("CHECKED", "LidoSRv3.Audit.Guarantees.PSsz1.deposit_root_iff", "CHECKED", "LidoSRv3.Audit.Guarantees.PSsz1.verity_tx_simulates_ssz_encoding", "IMPLEMENTATION_PENDING", ("A-SHA256-FFI", "A-PERFECT-HASH", "A-MULTI-NODE-TRANSPORT", "A-SOLC-TRUSTED", "A-YUL-INTERFACE")),
}
EXPECTED_CANONICAL_DETAIL_SHA256 = {
    "P-ALLOC-1": "c184a7c659c8ddbdc2af3461644eccce399496c51e9ab9beff1a0498124eab12",
    "P-ALLOC-2": "e5955a7a287a477ee8e21da15dabed644676f247d242035be35cf8db5f39f70e",
    "P-DEPOSIT-1": "768e8ca14a82e6185ec6cfaaa87365c708434f9a6281fa265eb332a8a10e8208",
    "P-TOPUP-1": "7097df87332a3b9f4996ae897b5619947c71d4bdc547dad407759174fa62212f",
    "P-ACCOUNT-1": "0bfe71a24bbb39a1c72af1020f7aab17feeb628dc0889f0688ab7499e5ee1a0b",
    "P-RESERVE-1": "5b2e39b7d0f6ae09eabea8ee1f4ff5f02337921e576bb6786bb6b9063272b010",
    "P-CONSOLIDATION-ETH-1": "0bbd358a2b0ab770b4a88536e88ce9a32fa6bfdecbc83c70c519673505841017",
    "P-ADDRESS-1": "2aec78330a6f136e109160e4cca2c2da6e159dc2db719d28b260134d69e447aa",
    "P-TOPUP-2": "ab0afa6dde459f2b29f0102aada3cd2df77e376b2c48a435b4081b32a9307c6e",
    "P-CONSOLIDATION-1": "2fb9fc984cd8ded5ed7f11e749e5ba0356dc128ee8ea11ad59b30973778a0cdb",
    "P-SSZ-1": "34b6ab0e40f56dd44ffb44c1b37a090ffeb3880339d403022e172534a16cbb8a",
}
EXPECTED_PRIORITIES = {
    "P-RESERVE-1": "DONE",
    "P-DEPOSIT-1": "DONE", "P-TOPUP-1": "DONE", "P-ACCOUNT-1": "DONE",
    "P-ALLOC-1": "DONE", "P-ALLOC-2": "DONE", "P-CONSOLIDATION-ETH-1": "DONE",
    "P-ADDRESS-1": "DONE", "P-TOPUP-2": "DONE", "P-CONSOLIDATION-1": "DONE",
    "P-SSZ-1": "DONE",
}
DEPOSIT_CONSTRUCTOR_FIXTURE = ROOT / "fixtures/solidity-reference/StakingRouter.constructor.L88-L106.sol"
DEPOSIT_PROVENANCE_LEAN = ROOT / "LidoSRv3/Audit/Provenance/Deposit.lean"
TRUST_NATIVE_DECIDE_ALLOWLIST = AUDIT / "trust-native-decide-allowlist.txt"
NATIVE_DECIDE_AXIOM = re.compile(r"(?:[A-Za-z_]\w*\.)+_native\.native_decide\.ax_\d+(?:_\d+)*")
DEPOSIT_CONSTRUCTOR_FIXTURE_SHA256 = "41278266ceadd14837f7f1b81e4ab26d7634be2673af7c9b9775f28b231cfee9"
DEPOSIT_UPSTREAM_SOURCE_URL = (
    "https://raw.githubusercontent.com/lidofinance/core/"
    f"{PINNED['lido_core'][1]}/contracts/0.8.25/sr/StakingRouter.sol"
)
DEPOSIT_CONSTRUCTOR_SPAN = {
    "repository": "lidofinance/core",
    "source_sha": PINNED["lido_core"][1],
    "path": "contracts/0.8.25/sr/StakingRouter.sol",
    "function": "constructor",
    "start_line": 88,
    "end_line": 106,
    "permalink": (
        "https://github.com/lidofinance/core/blob/"
        f"{PINNED['lido_core'][1]}/contracts/0.8.25/sr/StakingRouter.sol#L88-L106"
    ),
}


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def require(condition, message):
    if not condition:
        raise SystemExit(f"audit metadata error: {message}")


def markdown_table_cell(value):
    """Render metadata as one Markdown table cell, never as table syntax."""
    return str(value).replace("\\", "\\\\").replace("|", "\\|").replace("\r\n", "<br>").replace("\n", "<br>").replace("\r", "<br>")


def canonical_metadata_bytes(value):
    """Ignore JSON whitespace while binding every metadata value and shape."""
    return json.dumps(json.loads(value), sort_keys=True, separators=(",", ":")).encode()


def canonical_review_input_bytes(relative, value):
    """Normalize structured review inputs while retaining exact text inputs."""
    if relative.endswith((".yaml", ".json")):
        return canonical_metadata_bytes(value)
    return value


def nonempty_strings(value):
    return isinstance(value, list) and all(isinstance(x, str) and x.strip() for x in value)


def validate_deposit_constructor_fixture():
    require(DEPOSIT_CONSTRUCTOR_FIXTURE.is_file(), "pinned StakingRouter constructor fixture is missing")
    source = DEPOSIT_CONSTRUCTOR_FIXTURE.read_bytes()
    require(hashlib.sha256(source).hexdigest() == DEPOSIT_CONSTRUCTOR_FIXTURE_SHA256,
            "pinned StakingRouter constructor fixture hash differs")
    try:
        request = Request(DEPOSIT_UPSTREAM_SOURCE_URL, headers={"User-Agent": "lido-srv3-audit-metadata"})
        with urlopen(request, timeout=30) as response:
            upstream_source = response.read()
    except (HTTPError, URLError, TimeoutError, OSError) as error:
        raise SystemExit(
            "audit metadata error: cannot read pinned upstream StakingRouter Git blob: "
            f"{error}"
        ) from error
    upstream_slice = b"\n".join(upstream_source.splitlines()[87:106]) + b"\n"
    require(source == upstream_slice,
            "pinned StakingRouter constructor fixture differs from pinned upstream Git blob")
    text = source.decode("utf-8")
    guards = re.findall(r"SRUtils\._requireNotZero\((_[A-Za-z0-9]+)\);", text)
    require(guards == ["_depositContract", "_lido", "_lidoLocator", "_maxEBType1", "_maxEBType2"],
            "pinned StakingRouter constructor guard sequence differs")
    bindings = re.findall(r"(DEPOSIT_CONTRACT|MAX_EFFECTIVE_BALANCE_WC_TYPE_01)\s*=\s*(?:IDepositContract\()?(_[A-Za-z0-9]+)\)?;", text)
    require(bindings == [("DEPOSIT_CONTRACT", "_depositContract"),
                         ("MAX_EFFECTIVE_BALANCE_WC_TYPE_01", "_maxEBType1")],
            "pinned StakingRouter constructor correspondence differs")
    lean = DEPOSIT_PROVENANCE_LEAN.read_text(encoding="utf-8")
    predicate = re.search(
        r"^def PinnedConstructorAdmitted \(inputs : ConstructorInputs\) : Prop :="
        r"(?P<body>.*?)(?=\n\s*\n)",
        lean,
        re.MULTILINE | re.DOTALL,
    )
    expected_body = r"\s*inputs\.depositContract ≠ 0 ∧ inputs\.maxEBType1 ≠ 0\s*"
    require(predicate is not None and re.fullmatch(expected_body, predicate.group("body")) is not None,
            "pinned StakingRouter constructor Lean predicate differs")


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
    require(policy.get("trust_native_decide_allowlist") == "audit/trust-native-decide-allowlist.txt",
            "Trust native-decision allowlist differs")
    trust_names = [line.strip() for line in TRUST_NATIVE_DECIDE_ALLOWLIST.read_text(encoding="utf-8").splitlines()
                   if line.strip() and not line.lstrip().startswith("#")]
    require(len(trust_names) == len(set(trust_names)) and trust_names,
            "Trust native-decision allowlist must be nonempty and unique")
    production_native = {
        "LidoSRv3.Audit.Verity.AllocCapacityPhase3.consumed_summary_function_spec_compiles._native.native_decide.ax_1_1",
        "LidoSRv3.Audit.Verity.SszAbstractDigest.deposit_data_root_compiles._native.native_decide.ax_1_1",
        "LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel.forward_compiles._native.native_decide.ax_1_1",
    }
    require(production_native <= set(trust_names) and
            all(name in production_native or name.startswith("LidoSRv3.Tests.") for name in trust_names),
            "Trust native-decision allowlist contains an undisclosed production dependency")
    # The report publishes these as the exact emitted native-decision axioms.
    # An arbitrary project axiom must not be presentable as one of them.
    require(all(NATIVE_DECIDE_AXIOM.fullmatch(name) for name in trust_names),
            "Trust native-decision allowlist documents a non-native axiom")
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
    required_targets = set(CANONICAL_IDS)
    require(required_targets <= set(target_ids), "canonical source targets are incomplete")
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
    deposit_target = next(target for target in targets if target.get("id") == "P-DEPOSIT-1")
    require(DEPOSIT_CONSTRUCTOR_SPAN in deposit_target["spans"],
            "P-DEPOSIT-1: pinned constructor source span is missing")


def validate_r1_review_basis():
    """Require the complete rendered-report input family at R1's basis."""
    for relative, expected_digest in R1_REPORT_INPUT_SHA256.items():
        result = subprocess.run(
            ["git", "-C", str(ROOT), "show", f"{R1_REVIEW_BASE}:{relative}"],
            text=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        require(result.returncode == 0,
                f"R1 review basis cannot read {R1_REVIEW_BASE}:{relative}")
        reviewed = result.stdout
        reviewed_canonical = canonical_review_input_bytes(relative, reviewed)
        require(hashlib.sha256(reviewed_canonical).hexdigest() == expected_digest,
                f"R1 review basis digest differs for {relative}")
        current_canonical = canonical_review_input_bytes(relative, (ROOT / relative).read_bytes())
        require(current_canonical == reviewed_canonical,
                f"R1 review basis input family differs for {relative}")


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


# Every headline-table row that discloses a gap count, whatever index it claims.
# The per-ID pattern below binds an ID to the position it must carry, so a
# duplicate published under a *different* index does not match that pattern at
# all and would go on asserting a contradictory count unchecked.
README_FIDELITY_ROW = re.compile(
    r"^\|\s*\d+\s*\|\s*`([^`]+)`\s*\|[^\n|]*\|[^\n|]*\|\s*\d+ open\s*\|$",
    re.MULTILINE,
)

# The disclosure is a claim about one table: the headline status table, whose
# CHECKED cells the gap counts are there to qualify.  Matching those rows
# anywhere in the README bound them to nothing in particular, so a row moved out
# of the headline table into any later table went on satisfying this gate while
# the table a reader actually meets had silently dropped it — the headline could
# skip from 6 to 8 with `P-CONSOLIDATION-ETH-1` re-filed in an appendix and every
# check below still passed.  The table is located by its own header, so its rows
# are read from it and from nowhere else.
# A header line alone does not make a table.  Markdown renders one only when the
# next line is a delimiter row whose every cell is one or more hyphens, with
# optional alignment colons; `|     |     |     |` is pipes and spaces and
# delimits nothing, so accepting `[ \t\-|]+` let the headline and its gap counts
# collapse into paragraph text while this gate still read them as a table.  The
# cell counts must agree too: Markdown drops the table entirely when the
# delimiter row is not as wide as the header it underlines.
# Locating the table with a pattern of its own repeated the same mistake one
# level down.  The pattern compared the header's and the delimiter's `|` counts,
# and an escaped pipe is a `|` character that delimits no cell: a header reading
# `| # | ID | Abstract \| Lean | … | Fidelity gaps |` under a delimiter row
# widened by one column balanced those counts exactly while cmark-gfm, finding a
# five-cell header under a six-cell delimiter, rendered no table on the page at
# all.  Every gap count in this gate was checked against a block a reader meets
# as a paragraph of literal text.  The table is located through
# `scripts/gfm_table.py`, which splits cells the way the renderer does.
#
# The header is identified by the three columns that make it this table: the
# index, the claim ID, and the gap-count column the disclosure lives in.
README_HEADLINE_COLUMNS = ("#", "ID", "Fidelity gaps")
# Inside the rendered table the cells come from the renderer's own split, so
# only the two that carry a checked value need a pattern of their own.
README_ID_CELL = re.compile(r"^`([^`]+)`$")
README_GAP_CELL = re.compile(r"^(\d+) open$")
# A heading opens a section, and the headline is what comes before the first
# one.  Requiring only that the table exist *somewhere* bound it to no position,
# so moving it under a trailing `## Appendix` left this gate green while the
# headline a reader meets before the CHECKED cells no longer carried a single
# gap count.
README_SECTION_HEADING = re.compile(r"^ {0,3}#{2,6}[ \t]", re.MULTILINE)

# The model-vs-deployed boundary and the total gap count are headline claims:
# they qualify the CHECKED table before a reader reaches it, which is the whole
# reason they are stated up front.  Searching the README for those sentences
# bound them to nothing in particular, so relocating either one into an appendix
# below the table — or into any prose paragraph a reader scrolls past — left
# this gate green while the headline no longer carried the qualification at all.
# The opening blockquote is located by its position instead: the leading `>`
# block immediately under the title, and nowhere else.
README_HEADLINE_BLOCK = re.compile(r"\A# [^\n]*\n\n(?P<block>(?:>[^\n]*\n)+)")

# Locating the block is only half of it: its contents were then searched as raw
# Markdown, and text a reader never meets satisfied that search.  Dropping the
# visible count and boundary and adding a line such as
# `> <!-- not about a deployed contract; 67 in total -->` left both
# qualifications present in the source and absent from the rendered page, so the
# headline CHECKED table published itself unqualified while this gate stayed
# green.  Every construct whose characters render as no visible text is removed
# before the block is tested — comments, processing instructions, declarations
# and CDATA, the elements whose bodies are never shown as prose, and the tags
# themselves, so a sentence cannot hide in an attribute value either.  Removal
# only ever deletes text, so a qualification can vanish from this view but can
# never be invented in it; the failure direction is a real disclosure reported
# missing, never a missing one reported present.
#
# The elements are handed to `markdown_text.non_rendered_spans`, which owns that
# question for every gate that asks it.  Spelling them here as
# `<(script|style|textarea)\b.*?</\1>` named three of them and stopped at the
# first end tag, so `<template>67 in total</template>` published a count to no
# reader while this gate read it as prose, and a `<template>` nested in another
# one carried a sentence past the close the pattern stopped at.
_HTML_ATTRIBUTE = markdown_text.HTML_ATTRIBUTE
README_UNRENDERED = re.compile(
    r"<!--.*?(?:-->|\Z)"
    r"|<\?.*?(?:\?>|\Z)"
    r"|<!\[CDATA\[.*?(?:\]\]>|\Z)"
    r"|<![A-Za-z].*?(?:>|\Z)"
    rf"|<[A-Za-z][A-Za-z0-9-]*{_HTML_ATTRIBUTE}*\s*/?>"
    r"|</[A-Za-z][A-Za-z0-9-]*\s*>",
    re.DOTALL | re.IGNORECASE,
)

# CommonMark type-6 HTML block openers: a line that starts with one of these
# block-level element names causes everything until the next blank line to be
# emitted as raw HTML, not parsed as Markdown.  Pipe characters on those
# interior lines never render as table rows.
_HTML_BLOCK_TAG = re.compile(
    r"^ {0,3}</?(?:address|article|aside|base|basefont|blockquote|body|"
    r"caption|center|col|colgroup|dd|details|dialog|dir|div|dl|dt|"
    r"fieldset|figcaption|figure|footer|form|frame|frameset|h[1-6]|"
    r"head|header|hr|html|iframe|legend|li|link|main|menu(?:item)?|"
    r"meta|nav|noframes|ol|optgroup|option|p|param|section|source|"
    r"summary|table|tbody|td|tfoot|th|thead|title|tr|track|ul)"
    r"(?:[ \t>]|/>|$)",
    re.IGNORECASE,
)


def _mask_readme(text):
    """Position-preserving blank of non-rendered regions in the README.

    A pipe line inside a code fence or HTML block is printed as raw text,
    not as a table row.  Searching the raw README let a table wrapped in
    `<!--` … `-->` or a code fence satisfy the headline-table gate while the
    rendered page showed nothing.  Each masked character is replaced with a
    space so every position in the result corresponds to the same position in
    the original; this keeps the body-position range the stray-row detection
    compares against consistent with `README_FIDELITY_ROW.finditer(readme)`.
    """
    def blank(m):
        return "".join(" " if c != "\n" else "\n" for c in m.group(0))

    # Blank whole non-rendered elements first: a table wrapped in `<template>`
    # keeps every raw pipe character while the page shows no table at all.
    # Positions are preserved here the same way, by writing spaces over the
    # span rather than deleting it.
    held = list(text)
    for start, stop in markdown_text.non_rendered_spans(text):
        for i in range(start, stop):
            if held[i] != "\n":
                held[i] = " "
    masked = "".join(held)

    # Blank the remaining inline HTML constructs, preserving positions.
    masked = README_UNRENDERED.sub(blank, masked)

    # Line-by-line pass: blank code fences and CommonMark type-6 HTML blocks.
    # Code fences: a closing sequence repeats the opening character at least as
    # many times; a backtick fence carries no backtick in its info string.
    # Type-6 HTML blocks: a line whose first non-space token is a block-level
    # element open/close tag causes everything until the next blank line to be
    # raw HTML.  The detection uses the original line (before step 1 blanked
    # the opening tag) so the block-tag pattern fires on the actual characters.
    lines_m = masked.splitlines(True)   # output lines (positions preserved)
    lines_o = text.splitlines(True)     # original lines (for HTML-block detection)
    fence = None
    html_block = False
    for i, (ml, ol) in enumerate(zip(lines_m, lines_o)):
        msk = ml.rstrip("\r\n")
        orig = ol.rstrip("\r\n")
        if fence is not None:
            m = re.match(r"^ {0,3}(?P<seq>`{3,}|~{3,})[ \t]*$", msk)
            if m and m.group("seq")[0] == fence[0] and len(m.group("seq")) >= fence[1]:
                fence = None
            lines_m[i] = "".join(" " if c not in "\r\n" else c for c in ml)
        elif html_block:
            if orig == "":  # blank line ends the HTML block
                html_block = False
            else:
                lines_m[i] = "".join(" " if c not in "\r\n" else c for c in ml)
        else:
            m = re.match(r"^ {0,3}(?P<seq>`{3,}|~{3,})(?P<info>.*)$", msk)
            if m and not (m.group("seq")[0] == "`" and "`" in m.group("info")):
                fence = (m.group("seq")[0], len(m.group("seq")))
                lines_m[i] = "".join(" " if c not in "\r\n" else c for c in ml)
            elif _HTML_BLOCK_TAG.match(orig):
                html_block = True
                lines_m[i] = "".join(" " if c not in "\r\n" else c for c in ml)
    return "".join(lines_m)


def validate_readme_fidelity_disclosure(rows):
    """Bind the README headline table to the registry's own fidelity counts.

    The headline table is the first thing a reader sees, and every canonical row
    reads CHECKED/CHECKED.  Without a per-row gap count next to those cells the
    surface reads as "finished" while the registry still records open gaps, so
    the count is part of the published claim and may not drift from
    `fidelity.missing`.
    """
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    # A pipe line inside a code fence or HTML block renders as literal text, not
    # as a table row, so wrapping the headline table in `<!--` … `-->` or a code
    # fence left the raw-text search finding it while the rendered page showed
    # nothing.  The masked version blanks every non-rendered region character-
    # for-character (preserving newlines), so positions in `masked_readme` are
    # identical to positions in `readme` and stray-row detection remains sound.
    masked_readme = _mask_readme(readme)
    tables = [t for t in gfm_table.find_tables(masked_readme)
              if (t.header.cells[0].strip(), t.header.cells[1].strip(),
                  t.header.cells[-1].strip()) == README_HEADLINE_COLUMNS]
    require(len(tables) == 1,
            f"README: found {len(tables)} headline fidelity tables, expected exactly one; "
            "the gap counts qualify the CHECKED cells a reader meets first, and a second "
            "table claiming those columns would compete with that disclosure. A header "
            "whose delimiter row is not exactly as wide renders no table at all, and an "
            "escaped pipe narrows the header without removing the character")
    headline = tables[0]
    canonical = rows[:len(CANONICAL_IDS)]
    # Read the rows through the cells the renderer lays out, padded to the width
    # the header declares — GFM pads a short row out rather than dropping it, so
    # a row that stops before its gap-count cell still prints as a row of the
    # table with that cell empty.
    body = []
    for line in headline.rows:
        cells = [cell.strip() for cell in line.cells][:headline.columns]
        body.append(cells + [""] * (headline.columns - len(cells)))
    printed = [m.group(1) for row in body if (m := README_ID_CELL.match(row[1]))
               and README_GAP_CELL.match(row[-1])]
    strays = sorted({m.group(1) for m in README_FIDELITY_ROW.finditer(readme)
                     if not headline.body_start <= m.start() < headline.body_end})
    require(not strays,
            f"README: {', '.join(strays)} print(s) a fidelity-gap row outside the headline "
            "table; a row filed elsewhere is still a published gap count and is not the "
            "disclosure the headline table makes")
    total = 0
    for position, row in enumerate(canonical, start=1):
        expected = len(row["fidelity"]["missing"])
        require(expected > 0, f"{row['id']}: registry records no fidelity gap to disclose")
        total += expected
        # A reader meets every row the table prints, but `search` read only the
        # first: a duplicated row published a second, contradictory gap count
        # while the first copy kept this gate green.  No canonical ID may name a
        # repeat, so a second copy is rejected rather than shadowed by whichever
        # one happens to come first.  Absence is left to the position-bound
        # `found` check below, which names the missing cell precisely.
        appearances = printed.count(row["id"])
        require(appearances <= 1,
                f"README: {row['id']} names {appearances} headline fidelity rows; "
                "every printed row is a published claim and exactly one must carry it")
        found = [gap.group(1) for cells in body
                 if cells[0] == str(position) and cells[1] == f"`{row['id']}`"
                 and (gap := README_GAP_CELL.match(cells[-1]))]
        require(len(found) == 1,
                f"README: {row['id']} row is missing its `N open` fidelity-gap cell "
                f"at headline position {position}")
        require(int(found[0]) == expected,
                f"README: {row['id']} discloses {found[0]} fidelity gaps, "
                f"registry records {expected}")
    # Every canonical claim now has exactly one row, so anything else the table
    # prints is a gap count standing behind no registry row at all.  Checked
    # last so the per-row rules above keep naming their own failures precisely.
    extra = sorted(set(printed) - {row["id"] for row in canonical})
    require(not extra,
            f"README: the headline table prints a fidelity-gap row for {', '.join(extra)}, "
            "which the registry does not record as a canonical claim; a published gap "
            "count qualifies a published CHECKED cell and must have one to qualify")
    opening = README_HEADLINE_BLOCK.match(readme)
    require(opening is not None,
            "README: no headline blockquote under the title, so the qualifications a "
            "reader meets before the CHECKED table cannot be located")
    # The headline is a position, not just a shape.  Requiring only that the
    # table exist *somewhere* bound it to no position, so moving it under a
    # trailing `## Appendix` left this gate green while the headline a reader
    # meets before the CHECKED cells carried no gap count at all.  The table has
    # to sit between the headline blockquote and the first section heading:
    # after the qualifications that bound it, and before the document breaks
    # into sections a reader may never scroll to.  Checked once the blockquote
    # is known to be in place, so displacing the blockquote is reported by the
    # rule above, which names that failure exactly.
    section = README_SECTION_HEADING.search(masked_readme, opening.end("block"))
    heading = readme[section.start():readme.index("\n", section.start())] if section else ""
    require(headline.start >= opening.end("block"),
            "README: the fidelity table is printed above the headline blockquote, so the "
            "gap counts are published before the boundary and the total that qualify them")
    require(section is None or headline.start < section.start(),
            f"README: the fidelity table is printed below `{heading.strip()}`, not in the "
            "headline above the first section; the gap counts qualify the CHECKED cells a "
            "reader meets first and cannot do that from an appendix")
    # Strip HTML constructs, then the link metadata a reader never meets — the
    # reference definition lines and the inline destinations and titles.  Each
    # pass only deletes characters, so a qualification that survives is one a
    # reader actually sees, and the display text is kept (`[text](url "title")`
    # → `text`) so a qualification carried in the clickable label still counts.
    # `scripts/markdown_text.py` does the second half: a destination may carry
    # balanced parentheses, and a pattern that stopped at the first `)` left the
    # title of `[details](foo(bar) "…")` standing as ordinary text, so a
    # headline rendering only the word "details" satisfied this check.
    block = markdown_text.visible_text(README_UNRENDERED.sub(
        "", markdown_text.strip_non_rendered_elements(opening.group("block"))))
    require(f"{total} in total" in block,
            f"README: the headline blockquote must render the {total} total fidelity "
            "gaps as visible text; a count stated only further down, or only inside a "
            "comment or other unrendered markup, does not qualify the table above it")
    require("not about a deployed contract" in block,
            "README: the headline blockquote must render the model-vs-deployed boundary "
            "as visible text; a boundary stated only further down, or only inside a "
            "comment or other unrendered markup, does not qualify the table above it")


def validate():
    validate_deposit_constructor_fixture()
    registry = load(AUDIT / "guarantees.yaml")
    assumptions = load(AUDIT / "assumptions.yaml")
    lock = load(AUDIT / "artifacts.lock.json")
    manifest = load(ROOT / "verity/targets/audit-manifest.json")
    source_map = load(AUDIT / "source-map.yaml")
    assumption_ids = validate_assumptions(assumptions)
    validate_pins(lock, manifest, source_map)
    rows = validate_guarantees(registry, assumption_ids)
    validate_r1_review_basis()
    validate_readme_fidelity_disclosure(rows)
    return rows


def rendered(rows, source_map):
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
        missing = markdown_table_cell("; ".join(r["fidelity"]["missing"]) or "—")
        assumptions = markdown_table_cell(", ".join(f"`{x}`" for x in r["assumptions"]) or "—")
        lines.append(
            f"| `{markdown_table_cell(r['id'])}` | {markdown_table_cell(r['abstract']['status'])} | "
            f"{markdown_table_cell(r['verity']['status'])} | {missing} | "
            f"{markdown_table_cell(r['classification']['kind'])} | {assumptions} |"
        )
    status = header + "\n".join(lines) + "\n"
    reproduce = header + "# REPRODUCE\n\n" + "\n".join(f"- `{r['id']}`: `{r['reproduction']['command']}` — {r['reproduction']['expected']}" for r in canonical) + "\n"
    # This is a review surface, not another source of truth.  Keep the final
    # auditor slice derived from the same structured registry as STATUS and
    # REPRODUCE so it cannot quietly widen a claim or omit a registered child.
    spans_by_id = {target["id"]: target for target in source_map["targets"]}
    trust_names = [line.strip() for line in TRUST_NATIVE_DECIDE_ALLOWLIST.read_text(encoding="utf-8").splitlines()
                   if line.strip() and not line.lstrip().startswith("#")]
    # Every canonical row is held gap-bearing by validate_readme_fidelity_disclosure,
    # but a supplemental row may legitimately record none: it closes one narrow
    # slice and its parent carries the residue.  Naming those rows keeps this
    # sentence from contradicting the `0 open` cells the table prints for them.
    gap_free = [r["id"] for r in rows if not r["fidelity"]["missing"]]
    if gap_free:
        quoted = [f"`{markdown_table_cell(i)}`" for i in gap_free]
        listed = quoted[0] if len(quoted) == 1 else \
            ", ".join(quoted[:-1]) + (" and " if len(quoted) == 2 else ", and ") + quoted[-1]
        gap_note = (
            f"Every one of the {len(canonical)} canonical claims still records at "
            f"least one open gap. The {'row' if len(quoted) == 1 else 'rows'} "
            f"{listed} print `0 open` because {'it is' if len(quoted) == 1 else 'they are'} "
            "supplemental: the count covers only the narrow slice each such row "
            "closes, and the residual gaps stay recorded against its parent "
            "canonical claim."
        )
    else:
        gap_note = "No row is gap-free."
    report = [header + "# R1 final auditor report\n\n",
        "## Decision\n\n",
        f"Review basis: certified R1 input set `{R1_REVIEW_BASE}`. **Not an audit certificate or deployment/bytecode verification.** The eleven canonical guarantees are Lean-checked only on the named abstract and Verity executable-contract planes. `CHECKED` means the theorem named below is buildable; it does not establish Solidity-to-bytecode, runtime-codehash, chain-address, constructor, or live-deployment identity. This report is generated from the canonical assurance registry and source map; it is an acceptance record, not proof evidence.\n\n",
        "## Architecture and evidence boundary\n\n",
        "The evidence stack is: pinned Lido source spans → source-shaped/abstract Lean specifications → Verity Lean program and `Contract.run` transaction observables → named theorem and negative-mutant receipts. Revert theorems concern the modeled snapshot and journal. External calls, storage observations, and source correspondences have only the scope stated per row. Lean theorem names are authoritative; metadata records classification and fidelity, never proof progress.\n\n",
        "Pinned upstream source is `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`; Verity is pinned in `audit/artifacts.lock.json`; Lean is `leanprover/lean4:v4.31.0`. Canonical source anchors are immutable permalinks in `audit/source-map.yaml`. A source-map entry is source provenance, not deployed-artifact provenance. Supplemental rows deliberately have no independent source-map target unless their parent mapping says otherwise.\n\n",
        "## Acceptance index — every registered claim\n\n",
        "One row per registered claim, with the number of fidelity gaps the "
        f"registry still records against it. {gap_note} The full "
        "assumptions, limitations, and source provenance for each claim are "
        "expanded in the per-claim sections below; nothing that qualifies a "
        "claim is left folded into a table cell.\n\n",
        "| Claim | Abstract | Verity | Fidelity gaps | Classification |\n",
        "| --- | --- | --- | --- | --- |\n"]
    for row in rows:
        # Registry IDs are untrusted table content; keep only the characters a
        # GitHub heading anchor can contain so a link target cannot add columns.
        anchor = re.sub(r"[^a-z0-9-]", "", row["id"].lower())
        report.append(
            f"| [`{markdown_table_cell(row['id'])}`](#{anchor}) | "
            f"{markdown_table_cell(row['abstract']['status'])} | "
            f"{markdown_table_cell(row['verity']['status'])} | "
            f"{len(row['fidelity']['missing'])} open | "
            f"**{markdown_table_cell(row['classification']['kind'])}** |\n"
        )
    report.append("\n## Per-claim acceptance — assumptions, limitations, and source\n\n")
    for row in rows:
        source = spans_by_id.get(row["id"])
        if source:
            provenance = (f"`{source['status']}`; {len(source['spans'])} immutable pinned "
                          f"source span(s) in `audit/source-map.yaml`")
        else:
            provenance = "No independent source-map target; supplemental evidence only"
        abstract = row["abstract"]
        verity = row["verity"]
        missing = row["fidelity"]["missing"]
        report.append(f"### `{row['id']}`\n\n")
        report.append(
            f"**Accepted theorem planes.** Abstract `{abstract['status']}`: "
            f"`{abstract['theorem'] or '—'}`. Verity `{verity['status']}`: "
            f"`{verity['theorem'] or '—'}`.\n\n")
        report.append(f"**Proof shape / exact domain statement.** {row['summary']}\n\n")
        report.append(f"**Source/artifact provenance.** {provenance}. A source-map entry is "
                      f"source provenance, not deployed-artifact provenance.\n\n")
        report.append("**Assumptions.** " + (", ".join(
            f"`{a}`" for a in row["assumptions"]) or "None recorded.") + "\n\n")
        report.append(f"**Limitations — {len(missing)} open fidelity gap(s).** "
                      f"Surfaces the accepted theorems above do *not* cover:\n\n")
        report.extend(f"- {item}\n" for item in missing)
        classification = row["classification"]
        remaining = classification.get("work")
        report.append(f"\n**Classification.** **{classification['kind']}**"
                      + (f" — {remaining}" if remaining else "") + "\n\n")
        report.append(f"**Next gate.** {row['next_gate']}\n\n")
    report.extend([
        "\n## Explicit NOT YET boundaries\n\n",
        "- **ETH confinement:** `P-ETH-JOURNAL-1` is a modeled journal exclusion result, not global ETH confinement across live contracts, arbitrary calls, or deployment state.\n",
        "- **Oracle sanity:** `P-ORACLE-SUPPLY-1` covers the registered source-domain/computed-mint model; it does not prove oracle-report truth, committee/oracle authorization, all report sanity, or live storage/execution correspondence.\n",
        "- **Broad token semantics:** `P-TOKEN-1` remains NOT YET and is not registered. The scoped address and claim rows do not establish general ERC-20/ERC-721/WstETH approvals, balances, transfers, events, or adversarial recipient semantics.\n",
        "- **Deployment identity:** NOT YET. Neither a pinned source span, a constructor literal, a configured endpoint, a runtime receipt, nor a model address proves deployed bytecode/codehash/chain identity. General Yul/EVM/deployment provenance is out of scope; the SSZ targeted binding remains OPEN.\n\n",
        "## Proof-escape and receipt acceptance\n\n",
        "`LidoSRv3.Audit.Trust` is the public axiom surface. It permits only Lean foundations (`propext`, `Classical.choice`, `Quot.sound`) plus the three explicitly recorded production exceptions (P-ALLOC-1 Phase-3 capacity, SSZ digest, consolidation flow) and the exact test/mutant-only native-decision names below; the run summary reports each production exception by name rather than folding it into the test-only count. `scripts/check_trust_axioms.py` rebuilds and reruns Trust, parses every emitted named axiom report (including Lean's empty-set spelling), and fails closed on any missing or unexpected dependency, including a production-parent or opaque project axiom. Neither Trust's source text nor its log is taken as evidence: a `#print axioms` line reads the same inside a `/- -/` block, and an `#eval IO.println` can emit a report Lean never computed, so disclosure is read from active commands only, with comments and strings blanked first, and every printed theorem's dependencies are recomputed by the checker itself through the same `Lean.collectAxioms` call `#print axioms` makes, in a probe it spawns that imports only `Lean` and loads the audited module as data, so audited code contributes declarations but never elaborates the probe measuring it — a macro bound to the collector's token sequence would otherwise intercept that call in every spelling, fully qualified ones included. The published log is then confirmed against that recomputation, and a report that hides, invents, or misstates a dependency fails closed. A disclosed native-decision name is bound to provenance rather than spelling: no project Lean source may declare a name in Lean's compiler-generated `_native.native_decide` namespace, so an `opaque` merely spelled like a generated axiom cannot be laundered into the allowed set. That lexical guard only rules out spellings a source can be scanned for, and nothing the environment records about a declaration is evidence of who created it: an elaborator can assemble the name from fragments, give it the reflection type, and register it at a line that genuinely contains `native_decide`. Each disclosed name is therefore vouched for by re-establishing its own claim rather than its origin — the checker recompiles and runs the `Bool` expression the axiom asserts is `true`, which is the same evidence `native_decide` itself relies on — while the recorded kind, type, module, and site conditions are retained only to keep the disclosed set inside the pinned tactic inventory. `scripts/check_proof_escapes.py` mechanically scans every production project Lean source, including top-level library roots, after removing comments and strings: project `sorry`, `admit`, `axiom`, equivalent `constant` declarations, `unsafe`, and `Lean.ofReduceBool` fail closed, and the complete `native_decide` inventory is pinned so additions also fail closed; its negative regression mutates an imported module, the top-level library root, and the Trust entrypoint. `audit/validation-receipt.txt` binds the current tracked tree excluding itself. A green receipt and metadata/public-surface checks establish synchronization, not semantic closure.\n\n",
        "### Exact emitted native-decision axioms\n\n```text\n" + "\n".join(trust_names) + "\n```\n\n",
        "## Recommendation\n\n",
        "**Q1:** close the first end-to-end fidelity gap rather than adding claims: independently bind one production deployment artifact (constructor inputs, runtime codehash, chain/address) to the already pinned source and one modeled value-moving endpoint, then prove the correspondence or retain it explicitly NOT YET.\n",
    ])
    return {"ROADMAP.md": roadmap, "STATUS.md": status, "REPRODUCE.md": reproduce,
            "R1-FINAL-AUDITOR-REPORT.md": "".join(report)}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("generate", "check"))
    parser.add_argument("--expect-canonical-count", type=int)
    args = parser.parse_args()
    rows = validate()
    if args.expect_canonical_count is not None:
        require(len(CANONICAL_IDS) == args.expect_canonical_count, f"canonical guarantee count is {len(CANONICAL_IDS)}, expected {args.expect_canonical_count}")
    source_map = load(AUDIT / "source-map.yaml")
    views = rendered(rows, source_map)
    if args.command == "generate":
        for name, content in views.items():
            (AUDIT / name).write_text(content, encoding="utf-8")
        print("generated audit/ROADMAP.md audit/STATUS.md audit/REPRODUCE.md audit/R1-FINAL-AUDITOR-REPORT.md")
    else:
        for name, content in views.items():
            require((AUDIT / name).read_text(encoding="utf-8") == content, f"{name} is stale; run scripts/audit_metadata.py generate")
        print(f"audit metadata v4 ok: {len(CANONICAL_IDS)} canonical guarantees + {len(SUBORDINATE_IDS)} subordinate evidence rows")


if __name__ == "__main__":
    main()
