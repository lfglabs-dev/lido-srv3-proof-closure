#!/usr/bin/env python3
"""Reproduce the CONSOLIDATION_REQUEST immutable extraction from the deployed
Lido WithdrawalVault implementation bytecode.

This script is the offline reproduction that closes A-CANONICAL-REQUEST-ADDRESS
down to A-RUNTIME-PROVENANCE for the P-CONSOLIDATION-ETH-1 guarantee. It
recomputes the fixture SHA-256, extracts the immutable at the pinned offset,
and prints both — a reviewer compares the script output to the pinned Lean
literal (`LidoSRv3.Audit.Verity.ConsolidationCallFragment.consolidationPredeploy`)
and to the entry in `audit/artifacts.lock.json`.

Optionally, with `ETH_RPC_URL` set, the script also refetches the deployed
runtime bytecode from the Ethereum JSON-RPC endpoint and re-verifies the fixture
SHA-256. That re-verification is the exact `A-RUNTIME-PROVENANCE` check for this
immutable.

Usage:
    python3 scripts/verify_consolidation_request_immutable.py
    ETH_RPC_URL=https://... python3 scripts/verify_consolidation_request_immutable.py
"""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FIXTURE = ROOT / "fixtures/deployed/WithdrawalVault-impl-runtime.bin"
ARTIFACTS = ROOT / "audit/artifacts.lock.json"


def die(msg: str) -> "None":
    print(f"verify_consolidation_request_immutable: {msg}", file=sys.stderr)
    sys.exit(1)


def load_artifacts() -> dict:
    with ARTIFACTS.open() as f:
        return json.load(f)


def refetch_from_rpc(rpc_url: str, address: str) -> bytes:
    body = json.dumps({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "eth_getCode",
        "params": [address, "latest"],
    }).encode()
    req = urllib.request.Request(
        rpc_url,
        data=body,
        headers={"Content-Type": "application/json", "User-Agent": "verify-immutable/1.0"},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            d = json.load(resp)
    except Exception as e:
        die(f"RPC refetch failed: {e}")
    if "result" not in d:
        die(f"RPC error: {d}")
    return bytes.fromhex(d["result"][2:])


def main() -> None:
    if not FIXTURE.is_file():
        die(f"fixture missing: {FIXTURE.relative_to(ROOT)}")

    fixture_bytes = FIXTURE.read_bytes()
    actual_sha = hashlib.sha256(fixture_bytes).hexdigest()

    artifacts = load_artifacts()
    entry = (
        artifacts.get("deployed_bytecode", {})
        .get("WithdrawalVault_implementation")
    )
    if not entry:
        die("audit/artifacts.lock.json missing deployed_bytecode.WithdrawalVault_implementation")

    expected_sha = entry["fixture_sha256"]
    if actual_sha != expected_sha:
        die(
            f"fixture SHA-256 mismatch: got {actual_sha}, expected {expected_sha}"
        )

    if len(fixture_bytes) != entry["fixture_size_bytes"]:
        die(
            f"fixture length mismatch: got {len(fixture_bytes)}, expected {entry['fixture_size_bytes']}"
        )

    # Extract every recorded immutable and print / verify.
    for extraction in entry["immutable_extractions"]:
        offset = extraction["byte_offset"]
        width = extraction["width_bytes"]
        expected_hex = extraction["expected_value_hex"].lower()
        extracted = fixture_bytes[offset:offset + width].hex().lower()
        status = "OK" if extracted == expected_hex else "MISMATCH"
        print(
            f"{extraction['immutable_name']} @ offset {offset} width {width}: "
            f"{extracted} ({status})"
        )
        if extracted != expected_hex:
            die(
                f"{extraction['immutable_name']} extraction mismatch: "
                f"got {extracted}, expected {expected_hex}"
            )

    # Optional live re-verification via RPC.
    rpc_url = os.environ.get("ETH_RPC_URL")
    if rpc_url:
        live = refetch_from_rpc(rpc_url, entry["implementation"])
        live_sha = hashlib.sha256(live).hexdigest()
        if live_sha != expected_sha:
            die(
                f"live deployed bytecode SHA-256 diverged from fixture: "
                f"got {live_sha}, fixture {expected_sha}"
            )
        print(f"live re-verification (via {rpc_url}): OK")
    else:
        print("live re-verification skipped (set ETH_RPC_URL to enable)")

    print(
        "verify_consolidation_request_immutable: OK — "
        "fixture-hash-anchored A-CANONICAL-REQUEST-ADDRESS discharge"
    )


if __name__ == "__main__":
    main()
