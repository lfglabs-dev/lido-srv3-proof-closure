#!/usr/bin/env python3
"""Validate JSON-compatible YAML metadata and render review-only views.

This deliberately does not inspect or parse Lean. Lean remains the theorem
authority; the script only checks and renders declared structured metadata.
"""

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "audit"
EXPECTED_IDS = [
    "SRV3-LEGACY-ECON",
    "SRV3-ARITH-CHECKED",
    "SRV3-TX-REVERT",
    "SRV3-ALLOC-ORDER",
    "SRV3-MINFIRST-BOUND",
    "SRV3-SOLIDITY-CORR",
    "SRV3-VERITY-431",
    "SRV3-YUL-COMP",
    "SRV3-EVM-RUNTIME",
    "SRV3-SHA256-PRECOMPILE",
    "SRV3-CONSOLIDATION-E2E",
]
EXPECTED_AUTHORITY = (
    "Lean theorem statements and proofs are authoritative; this metadata does not "
    "close a semantic guarantee."
)
EXPECTED_WORDING = [
    "Legacy pure model is not a Solidity or deployed-bytecode correspondence proof.",
    "Quantity bounds and units are model inputs; Solidity correspondence remains unproved.",
    "TxObservation is an abstract transaction model, not an EVM execution trace.",
    "Allocation inputs are source-shaped data, not extracted Solidity state.",
    "The handwritten MinFirst model has no established Solidity/EVM equivalence in M0.",
    "Verity 4.31 is a non-certified development scaffold.",
    "Pinned Verity target is active on this Lean 4.31 branch but remains non-certified.",
    "Handwritten Yul/direct bytecode must not receive a fabricated Verity projection.",
    "Current consolidation helper uses a Mock build and cannot establish production runtime identity.",
    "SHA-256 precompile hashing currently relies on opaque native FFI.",
    "Mock-derived helper evidence is non-production evidence.",
]
EXPECTED_ASSUMPTIONS = {
    "schema": "lido-srv3-assumptions-v1",
    "certification": {
        "status": "DEV-431-READY",
        "audit_cert": False,
        "statement": "DEV-431-READY is development readiness, not AUDIT-CERT.",
    },
    "assumptions": [
        {"id": "A-LEGACY-MODEL", "accepted": True,
         "risk": "Legacy pure-model regression evidence is not source or deployed-bytecode correspondence."},
        {"id": "A-MODEL-INPUTS", "accepted": True,
         "risk": "Quantity bounds and units remain model inputs until source refinement is proved."},
        {"id": "A-ABSTRACT-TX", "accepted": True,
         "risk": "Common success/revert semantics are abstract and are not executable EVM trace semantics."},
        {"id": "A-SOURCE-SHAPED", "accepted": True,
         "risk": "Source-shaped inputs are not extracted from independently verified pinned Solidity spans."},
        {"id": "A-HANDWRITTEN-MINFIRST", "accepted": True,
         "risk": "The handwritten MinFirst model lacks established Solidity and EVM equivalence."},
        {"id": "A-VERITY-SCAFFOLD", "accepted": True,
         "risk": "The Verity 4.31 scaffold is non-certified."},
        {"id": "A-DEV-NOT-CERT", "accepted": True,
         "risk": "DEV-431-READY is explicitly accepted as not AUDIT-CERT."},
        {"id": "A-MULTI-NODE-TRANSPORT", "accepted": True,
         "risk": "Multi-node certification transport is accepted as a trust and reproducibility risk; transported results require independent identity and consistency checks."},
        {"id": "A-YUL-INTERFACE", "accepted": True,
         "risk": "Handwritten Yul and direct bytecode require explicit interface composition, not a fabricated source projection."},
        {"id": "A-SHA256-FFI", "accepted": True,
         "risk": "SHA-256 precompile behavior relies on opaque native FFI and host-library behavior; differential vectors do not close this crypto risk."},
        {"id": "A-RUNTIME-PROVENANCE", "accepted": True,
         "risk": "Canonical runtime, codehash, fork configuration, and address provenance are unavailable; Mock-derived evidence is non-production evidence."},
    ],
}
EXPECTED_REPRODUCTION = [
    {"command": "lake build LidoSRv3",
     "expected": "successful Lean build; model layer only"},
    {"command": "lake build LidoSRv3.Audit.Trust",
     "expected": "successful Lean build and declared axiom report"},
    {"command": "lake build LidoSRv3.Audit.Trace",
     "expected": "successful Lean build of the module containing the named rollback theorem"},
    {"command": "lake build LidoSRv3.Audit.Allocation",
     "expected": "successful Lean build; relational model only"},
    {"command": "lake build LidoSRv3.Audit.Vectors",
     "expected": "successful theorem and falsifier-vector build"},
    {"command": "python3 scripts/audit_metadata.py check",
     "expected": "metadata consistency only; no source theorem"},
    {"command": "lake build",
     "expected": "active Lean 4.31 dependency graph builds; not certification"},
    {"command": "python3 scripts/audit_metadata.py check",
     "expected": "pin and blocker validation only; no Yul theorem"},
    {"command": "python3 scripts/audit_metadata.py check",
     "expected": "MISSING provenance remains explicit and fails semantic closure"},
    {"command": "python3 scripts/audit_metadata.py check",
     "expected": "opaque FFI risk remains recorded; no crypto closure"},
    {"command": "python3 scripts/audit_metadata.py check",
     "expected": "E2E remains blocked; metadata cannot discharge dependencies"},
]
EXPECTED_ASSUMPTION_LINKS = [
    ["A-LEGACY-MODEL"],
    ["A-MODEL-INPUTS"],
    ["A-ABSTRACT-TX"],
    ["A-SOURCE-SHAPED"],
    ["A-HANDWRITTEN-MINFIRST"],
    ["A-VERITY-SCAFFOLD", "A-MULTI-NODE-TRANSPORT"],
    ["A-DEV-NOT-CERT", "A-MULTI-NODE-TRANSPORT"],
    ["A-YUL-INTERFACE"],
    ["A-RUNTIME-PROVENANCE"],
    ["A-SHA256-FFI"],
    ["A-RUNTIME-PROVENANCE", "A-SHA256-FFI", "A-MULTI-NODE-TRANSPORT"],
]
EXPECTED_NEXT_GATES = [
    "Establish pinned-source correspondence for each claimed economic transition.",
    "Connect checked quantities to independently verified pinned source spans.",
    "Refine success/revert and rollback against pinned executable EVM semantics.",
    "Prove extraction and ordered-row correspondence from pinned Solidity.",
    "Establish source correspondence and checked-Uint256 execution refinement.",
    "Produce source-mutant-sensitive refinement proofs from independently verified pinned spans.",
    "Complete certification gates; DEV-431-READY must never be interpreted as AUDIT-CERT.",
    "Build a mutant-sensitive Yul interface harness at the exact EVMYulLean pin.",
    "Obtain independent canonical runtime, codehash, fork, and address provenance.",
    "Replace or independently validate the opaque native SHA-256 FFI trust boundary.",
    "Close source/Yul/EVM/crypto composition with canonical production provenance.",
]
EXPECTED_EXCLUSIONS = {
    "schema": "lido-srv3-exclusions-v1",
    "exclusions": [
        {"id": "BLS", "scope": "BLS signature validity and related cryptographic correctness"},
        {"id": "FULL-REPORT-PIPELINE-REFINEMENT",
         "scope": "Full report-pipeline source, transaction, and EVM refinement"},
        {"id": "STVAULT-INTERNALS",
         "scope": "stVault internal state, accounting, and lifecycle semantics"},
        {"id": "VALUE-BASED-EXIT-BOUND",
         "scope": "Value-based exit and consolidation bounds"},
        {"id": "BROAD-REGISTRY-LIFECYCLE",
         "scope": "Broad registry, governance, module lifecycle, and role-management behavior"},
    ],
}
PLANES = {"model", "source", "tx", "yul", "evm", "crypto"}
EXPECTED_STATUSES = [
    {"model": "REGRESSION", "source": "OPEN", "tx": "OPEN",
     "yul": "NOT_APPLICABLE", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "LEAN_CHECKED", "source": "OPEN", "tx": "NOT_APPLICABLE",
     "yul": "NOT_APPLICABLE", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "LEAN_CHECKED", "source": "OPEN", "tx": "ABSTRACT_LEAN_CHECKED",
     "yul": "NOT_APPLICABLE", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "LEAN_CHECKED", "source": "OPEN", "tx": "OPEN",
     "yul": "NOT_APPLICABLE", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "LEAN_CHECKED", "source": "OPEN", "tx": "OPEN",
     "yul": "NOT_APPLICABLE", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "OPEN", "source": "OPEN", "tx": "OPEN",
     "yul": "NOT_APPLICABLE", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "DEV-431-READY", "source": "DEV-431-READY", "tx": "OPEN",
     "yul": "OPEN", "evm": "OPEN", "crypto": "OPEN"},
    {"model": "OPEN", "source": "OPEN", "tx": "OPEN",
     "yul": "OPEN", "evm": "OPEN", "crypto": "NOT_APPLICABLE"},
    {"model": "OPEN", "source": "BLOCKED", "tx": "BLOCKED",
     "yul": "OPEN", "evm": "BLOCKED", "crypto": "NOT_APPLICABLE"},
    {"model": "OPEN", "source": "NOT_APPLICABLE", "tx": "OPEN",
     "yul": "OPEN", "evm": "OPEN", "crypto": "STRETCH_OPAQUE_FFI"},
    {"model": "OPEN", "source": "BLOCKED", "tx": "BLOCKED",
     "yul": "OPEN", "evm": "BLOCKED", "crypto": "BLOCKED"},
]
EXPECTED_THEOREM_PLANES = [
    ["model"],
    ["model"],
    ["model", "tx"],
    ["model"],
    ["model"],
    [],
    [],
    [],
    [],
    [],
    [],
]
STATUS_VALUES = {
    "ABSTRACT_LEAN_CHECKED",
    "BLOCKED",
    "DEV-431-READY",
    "LEAN_CHECKED",
    "NOT_APPLICABLE",
    "OPEN",
    "REGRESSION",
    "STRETCH_OPAQUE_FFI",
}
THEOREM_BACKED_STATUSES = {"ABSTRACT_LEAN_CHECKED", "LEAN_CHECKED", "REGRESSION"}
SOURCE_CLOSURE_STATUSES = THEOREM_BACKED_STATUSES | {"AUDIT-CERT"}
CAMPAIGN_BASE = {
    "repository": "https://github.com/lfglabs-dev/lido-srv3-proof-closure.git",
    "ref": "campaign/lido-minimal-11",
    "commit": "9131f1820f0f5034b3ebc08f4c9decacb49bdcb1",
}
CANONICAL_LIDO_REPOSITORY = "https://github.com/lidofinance/core.git"
CANONICAL_LEAN_TOOLCHAIN_PREFIX = "leanprover/lean4:"
REQUIRED_UNAVAILABLE = {
    name: {"status": "MISSING", "blocked": True, "value": None}
    for name in (
        "canonical_eip7251_runtime",
        "canonical_eip7251_codehash",
        "canonical_eip7251_fork",
        "canonical_eip7251_address",
        "sha256_ffi_implementation_identity",
    )
}
EXPECTED_COMMON_MODULES = {
    "LidoSRv3.Audit.Common.Units",
    "LidoSRv3.Audit.Common.Result",
    "LidoSRv3.Audit.Common.Trace",
    "LidoSRv3.Audit.Common.Atomicity",
    "LidoSRv3.Audit.Common.Bounded",
}
EXPECTED_COMMON_THEOREMS = [
    {
        "name": "Common.BoundedAmount.checkedAdd_sound",
        "status": "lean_checked",
        "axioms": [],
    },
    {
        "name": "Common.revert_rolls_back_state_and_committed_effects",
        "status": "lean_checked",
        "axioms": ["propext"],
    },
    {
        "name": "Common.success_exposes_exact_committed_effects",
        "status": "lean_checked",
        "axioms": ["propext"],
    },
]
EXPECTED_SOURCE_POLICY = (
    "Source spans remain unmapped unless independently verified from pinned source; "
    "names or legacy anchors are insufficient."
)
EXPECTED_SOURCE_TARGETS = [
    {"id": "SRV3-LEGACY-ECON", "status": "UNMAPPED", "spans": [],
     "blocker": "No independently verified pinned-source span in this bootstrap."},
    {"id": "SRV3-ARITH-CHECKED", "status": "UNMAPPED", "spans": [],
     "blocker": "No independently verified pinned-source span in this bootstrap."},
    {"id": "SRV3-TX-REVERT", "status": "UNMAPPED", "spans": [],
     "blocker": "No independently verified pinned-source span in this bootstrap."},
    {"id": "SRV3-ALLOC-ORDER", "status": "UNMAPPED", "spans": [],
     "blocker": "No independently verified pinned-source span in this bootstrap."},
    {"id": "SRV3-MINFIRST-BOUND", "status": "UNMAPPED", "spans": [],
     "blocker": "No independently verified pinned-source span in this bootstrap."},
    {"id": "SRV3-SOLIDITY-CORR", "status": "UNMAPPED", "spans": [],
     "blocker": "No independently verified pinned-source span in this bootstrap."},
    {"id": "SRV3-VERITY-431", "status": "UNMAPPED", "spans": [],
     "blocker": "Toolchain item; no independently verified Lido source span."},
    {"id": "SRV3-YUL-COMP", "status": "UNMAPPED", "spans": [],
     "blocker": "No independently verified pinned-source span in this bootstrap."},
    {"id": "SRV3-EVM-RUNTIME", "status": "UNMAPPED", "spans": [],
     "blocker": "Canonical runtime provenance is MISSING."},
    {"id": "SRV3-SHA256-PRECOMPILE", "status": "UNMAPPED", "spans": [],
     "blocker": "Opaque native FFI identity is MISSING."},
    {"id": "SRV3-CONSOLIDATION-E2E", "status": "UNMAPPED", "spans": [],
     "blocker": "Canonical runtime/codehash/fork/address provenance is MISSING."},
]
VIEWS = ("ROADMAP.md", "STATUS.md", "REPRODUCE.md")


def load(name):
    return json.loads((AUDIT / name).read_text(encoding="utf-8"))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def manifest_package(manifest, name):
    matches = [package for package in manifest["packages"] if package["name"] == name]
    require(len(matches) == 1, f"lake-manifest.json: expected exactly one {name} package")
    return matches[0]


def validate_lock(lock, source_map):
    manifest = json.loads((ROOT / "lake-manifest.json").read_text(encoding="utf-8"))
    audit_manifest = json.loads(
        (ROOT / "verity/targets/audit-manifest.json").read_text(encoding="utf-8")
    )
    toolchain = (ROOT / "lean-toolchain").read_text(encoding="utf-8").strip()
    lakefile = (ROOT / "lakefile.lean").read_text(encoding="utf-8")
    lido_source_repository, lido_commit = source_map["pinned_source"].split("@", 1)
    require(lido_source_repository == "lidofinance/core",
            "source-map pinned_source must use the canonical lidofinance/core repository")
    require(toolchain.startswith(CANONICAL_LEAN_TOOLCHAIN_PREFIX),
            "lean-toolchain must use the canonical leanprover/lean4 origin")

    expected_pins = {
        "lido_core": {
            "repository": CANONICAL_LIDO_REPOSITORY,
            "commit": lido_commit,
        },
        "verity": {
            "repository": manifest_package(manifest, "verity")["url"],
            "commit": manifest_package(manifest, "verity")["rev"],
        },
        "evmyullean": {
            "repository": manifest_package(manifest, "evmyul")["url"],
            "commit": manifest_package(manifest, "evmyul")["rev"],
        },
        "lean": {"toolchain": toolchain},
        "mathlib": {
            "repository": manifest_package(manifest, "mathlib")["url"],
            "commit": manifest_package(manifest, "mathlib")["rev"],
        },
    }
    require(lock.get("pins") == expected_pins,
            "artifacts.lock.json pins differ from source-map/toolchain/Lake authorities")
    verity = expected_pins["verity"]
    require(audit_manifest["source_revisions"]["lido"] == lido_commit,
            "source-map Lido pin differs from verity target audit manifest")
    require(audit_manifest["source_revisions"]["verity"] == verity["commit"],
            "Lake Verity pin differs from verity target audit manifest")
    lean_revision = toolchain.rsplit(":", 1)[-1]
    require(audit_manifest["source_revisions"]["lean"] == lean_revision,
            "Lean toolchain pin differs from verity target audit manifest")
    audit_modules = set(audit_manifest["layers"]["audit"]["modules"])
    require(EXPECTED_COMMON_MODULES <= audit_modules,
            "audit manifest omits canonical Common modules")
    manifest_theorems = audit_manifest["theorems"]
    for theorem in EXPECTED_COMMON_THEOREMS:
        require(manifest_theorems.count(theorem) == 1,
                f"audit manifest must contain exact Common theorem record: "
                f"{theorem['name']}")
    require(
        f'"{verity["repository"]}"@"{verity["commit"]}"' in lakefile,
        "lakefile.lean Verity pin differs from lake-manifest.json",
    )

    require(lock.get("campaign_base") == CAMPAIGN_BASE,
            "artifacts.lock.json campaign_base differs from canonical campaign authority")


def validate():
    registry = load("guarantees.yaml")
    assumptions = load("assumptions.yaml")
    exclusions = load("exclusions.yaml")
    lock = load("artifacts.lock.json")
    source_map = load("source-map.yaml")
    require(registry.get("authority") == EXPECTED_AUTHORITY,
            "guarantee registry authority differs from the canonical declaration")
    rows = registry["guarantees"]
    ids = [row["id"] for row in rows]
    require(ids == EXPECTED_IDS, "guarantees must contain the exact ordered minimal-11 IDs")
    require([row["catalogue_wording"] for row in rows] == EXPECTED_WORDING,
            "catalogue wording changed")
    require(exclusions == EXPECTED_EXCLUSIONS,
            "exclusions differ from the canonical scope boundary set")
    require(assumptions == EXPECTED_ASSUMPTIONS,
            "assumptions differ from the canonical accepted risk records")
    require(source_map.get("policy") == EXPECTED_SOURCE_POLICY,
            "source-map policy differs from the canonical assurance rule")
    assumption_ids = {row["id"] for row in assumptions["assumptions"]}
    source_targets = {row["id"]: row for row in source_map["targets"]}
    for row, expected_statuses, expected_theorem_planes, expected_reproduction, expected_links, expected_gate in zip(
        rows, EXPECTED_STATUSES, EXPECTED_THEOREM_PLANES,
        EXPECTED_REPRODUCTION, EXPECTED_ASSUMPTION_LINKS, EXPECTED_NEXT_GATES
    ):
        require(set(row["statuses"]) == PLANES, f"{row['id']}: assurance planes differ")
        theorem_planes = row.get("theorem_planes")
        require(theorem_planes == expected_theorem_planes,
                f"{row['id']}: theorem planes differ from canonical evidence")
        require(len(theorem_planes) == len(set(theorem_planes))
                and set(theorem_planes) <= PLANES,
                f"{row['id']}: invalid theorem evidence plane")
        require(bool(row["theorem"]) == bool(theorem_planes),
                f"{row['id']}: theorem and theorem planes must be declared together")
        for plane, status in row["statuses"].items():
            require(status in STATUS_VALUES,
                    f"{row['id']}: invalid {plane} assurance status: {status}")
            require(status not in THEOREM_BACKED_STATUSES or plane in theorem_planes,
                    f"{row['id']}: {plane} status {status} requires theorem evidence "
                    "for that plane")
        require(row["statuses"] == expected_statuses,
                f"{row['id']}: assurance statuses differ from canonical claims")
        source_status = row["statuses"]["source"]
        mapping = source_targets[row["id"]]
        require(
            source_status not in SOURCE_CLOSURE_STATUSES
            or (mapping["status"] == "MAPPED" and mapping["spans"]),
            f"{row['id']}: source assurance closure requires verified source spans",
        )
        require(row["next_gate"] == expected_gate,
                f"{row['id']}: next gate differs from canonical roadmap")
        require(row["reproduction"] == expected_reproduction,
                f"{row['id']}: reproduction record differs from canonical evidence")
        require(row["assumptions"] == expected_links,
                f"{row['id']}: assumption links differ from canonical risks")
        require(set(row["assumptions"]) <= assumption_ids,
                f"{row['id']}: canonical assumption link is unknown")
    require(source_map["targets"] == EXPECTED_SOURCE_TARGETS,
            "source-map targets differ from canonical blocker records")
    validate_lock(lock, source_map)
    require(lock.get("unavailable") == REQUIRED_UNAVAILABLE,
            "unavailable provenance must contain the exact canonical blocker set")
    return rows


def rendered(rows):
    header = (
        "<!-- GENERATED by scripts/audit_metadata.py; edit structured metadata, "
        "not this view. Lean is theorem authority. -->\n\n"
    )
    roadmap = header + "# ROADMAP\n\n" + "\n".join(
        f"- `{row['id']}`: {row['next_gate']}" for row in rows
    ) + "\n"
    status_lines = [
        "# STATUS",
        "",
        "| ID | Model | Source | TX | Yul | EVM | Crypto |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for row in rows:
        s = row["statuses"]
        status_lines.append(
            f"| `{row['id']}` | {s['model']} | {s['source']} | {s['tx']} | "
            f"{s['yul']} | {s['evm']} | {s['crypto']} |"
        )
    status = header + "\n".join(status_lines) + "\n"
    reproduce = header + "# REPRODUCE\n\n" + "\n".join(
        f"- `{row['id']}`: `{row['reproduction']['command']}` — "
        f"{row['reproduction']['expected']}"
        for row in rows
    ) + "\n"
    return {"ROADMAP.md": roadmap, "STATUS.md": status, "REPRODUCE.md": reproduce}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("generate", "check"))
    args = parser.parse_args()
    rows = validate()
    views = rendered(rows)
    if args.command == "generate":
        for name, content in views.items():
            (AUDIT / name).write_text(content, encoding="utf-8")
        print("generated audit/ROADMAP.md audit/STATUS.md audit/REPRODUCE.md")
    else:
        for name, content in views.items():
            require((AUDIT / name).read_text(encoding="utf-8") == content,
                    f"{name} is stale; run scripts/audit_metadata.py generate")
        print("audit metadata ok: exact minimal-11, risks, pins, source-map, generated views")


if __name__ == "__main__":
    main()
