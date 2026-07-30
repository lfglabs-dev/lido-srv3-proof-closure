#!/usr/bin/env python3
"""Validate JSON-compatible YAML metadata and render review-only views.

This deliberately does not inspect or parse Lean. Lean remains the theorem
authority; the script only checks and renders declared structured metadata.
"""

import argparse
import json
import subprocess
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
PLANES = {"model", "source", "tx", "yul", "evm", "crypto"}
VIEWS = ("ROADMAP.md", "STATUS.md", "REPRODUCE.md")


def load(name):
    return json.loads((AUDIT / name).read_text(encoding="utf-8"))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def git_output(*args):
    return subprocess.run(
        ["git", "-C", str(ROOT), *args],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


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

    base = lock.get("campaign_base")
    require(isinstance(base, dict), "artifacts.lock.json: missing campaign_base")
    ref = base.get("ref")
    require(ref == "campaign/lido-minimal-11",
            "artifacts.lock.json: unexpected campaign_base ref")
    remote = git_output("remote", "get-url", "origin")
    require(base.get("repository") == remote,
            "artifacts.lock.json: campaign_base repository differs from origin")
    candidates = (f"refs/remotes/origin/{ref}", ref)
    resolved = None
    for candidate in candidates:
        result = subprocess.run(
            ["git", "-C", str(ROOT), "rev-parse", "--verify", f"{candidate}^{{commit}}"],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            resolved = result.stdout.strip()
            break
    require(resolved is not None, f"campaign base ref is unavailable locally: {ref}")
    require(base.get("commit") == resolved,
            "artifacts.lock.json: campaign_base commit differs from checked-out base")


def validate():
    registry = load("guarantees.yaml")
    assumptions = load("assumptions.yaml")
    load("exclusions.yaml")
    lock = load("artifacts.lock.json")
    source_map = load("source-map.yaml")
    rows = registry["guarantees"]
    ids = [row["id"] for row in rows]
    require(ids == EXPECTED_IDS, "guarantees must contain the exact ordered minimal-11 IDs")
    require([row["catalogue_wording"] for row in rows] == EXPECTED_WORDING,
            "catalogue wording changed")
    assumption_ids = {row["id"] for row in assumptions["assumptions"]}
    for row in rows:
        require(set(row["statuses"]) == PLANES, f"{row['id']}: assurance planes differ")
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
    unavailable = lock["unavailable"]
    require(unavailable, "unavailable provenance must be recorded")
    for name, artifact in unavailable.items():
        require(artifact == {"status": "MISSING", "blocked": True, "value": None},
                f"{name}: unavailable provenance must be explicit")
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
