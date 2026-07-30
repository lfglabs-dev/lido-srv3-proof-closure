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
    lido_repository, lido_commit = source_map["pinned_source"].split("@", 1)
    require(lido_repository == "lidofinance/core",
            "source-map pinned_source must use the canonical lidofinance/core repository")
    lido_repository = f"https://github.com/{lido_repository}.git"

    expected_pins = {
        "lido_core": {"repository": lido_repository, "commit": lido_commit},
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
    require(audit_manifest["source_revisions"]["lido"] == lido_commit,
            "source-map Lido pin differs from verity target audit manifest")
    verity = expected_pins["verity"]
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
    rows = registry["guarantees"]
    ids = [row["id"] for row in rows]
    require(ids == EXPECTED_IDS, "guarantees must contain the exact ordered minimal-11 IDs")
    require([row["catalogue_wording"] for row in rows] == EXPECTED_WORDING,
            "catalogue wording changed")
    require(exclusions == EXPECTED_EXCLUSIONS,
            "exclusions differ from the canonical scope boundary set")
    assumption_ids = {row["id"] for row in assumptions["assumptions"]}
    source_targets = {row["id"]: row for row in source_map["targets"]}
    for row, expected_statuses, expected_theorem_planes in zip(
        rows, EXPECTED_STATUSES, EXPECTED_THEOREM_PLANES
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
        require(row["next_gate"], f"{row['id']}: missing next gate")
        require(row["reproduction"]["command"], f"{row['id']}: missing reproduction")
        require(set(row["assumptions"]) <= assumption_ids,
                f"{row['id']}: unknown assumption")
    tx_revert = rows[EXPECTED_IDS.index("SRV3-TX-REVERT")]
    require(
        tx_revert["theorem"] == "LidoSRv3.Audit.revert_restores_state_value_and_logs"
        and tx_revert["reproduction"]["command"] == "lake build LidoSRv3.Audit.Trace",
        "SRV3-TX-REVERT reproduction must build the module containing its named theorem",
    )
    require([row["id"] for row in source_map["targets"]] == EXPECTED_IDS,
            "source-map targets must contain the exact ordered minimal-11 IDs")
    for row in source_map["targets"]:
        require(row["status"] == "UNMAPPED" and row["spans"] == [],
                f"{row['id']}: source mapping must remain explicitly unmapped")
    require(assumptions["certification"] == {
        "status": "DEV-431-READY",
        "audit_cert": False,
        "statement": "DEV-431-READY is development readiness, not AUDIT-CERT.",
    }, "certification status must remain DEV-431-READY, not AUDIT-CERT")
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
