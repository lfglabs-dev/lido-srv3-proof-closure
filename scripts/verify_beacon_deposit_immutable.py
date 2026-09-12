#!/usr/bin/env python3
"""Reproduce the DEPOSIT_CONTRACT immutable extraction from the deployed
Lido StakingRouter implementation bytecode.

Closes A-TOPUP-BEACON-ADDRESS (P-TOPUP-1) and A-DEPOSIT-CONTRACT (P-DEPOSIT-1,
P-ALLOC-EXEC-1) down to A-RUNTIME-PROVENANCE for these guarantees.

Usage:
    python3 scripts/verify_beacon_deposit_immutable.py
    ETH_RPC_URL=https://... python3 scripts/verify_beacon_deposit_immutable.py
"""

from __future__ import annotations

import hashlib
import json
import os
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FIXTURE = ROOT / "fixtures/deployed/StakingRouter-impl-runtime.bin"
ARTIFACTS = ROOT / "audit/artifacts.lock.json"


def die(msg: str) -> "None":
    print(f"verify_beacon_deposit_immutable: {msg}", file=sys.stderr)
    sys.exit(1)


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

    with ARTIFACTS.open() as f:
        artifacts = json.load(f)
    entry = artifacts["deployed_bytecode"]["StakingRouter_implementation"]

    if actual_sha != entry["fixture_sha256"]:
        die(f"fixture SHA-256 mismatch: got {actual_sha}, expected {entry['fixture_sha256']}")
    if len(fixture_bytes) != entry["fixture_size_bytes"]:
        die(f"fixture length mismatch: got {len(fixture_bytes)}, expected {entry['fixture_size_bytes']}")

    for extraction in entry["immutable_extractions"]:
        # Chantier 7 fix (mandate 2026-09-12): some entries carry a single
        # `byte_offset`, others (extraction_kind = push32_payload_enumeration)
        # carry a `byte_offsets` list. Support both.
        width = extraction["width_bytes"]
        expected_hex = extraction["expected_value_hex"].lower()
        offsets = extraction.get("byte_offsets")
        if offsets is None:
            offsets = [extraction["byte_offset"]]
        for offset in offsets:
            extracted = fixture_bytes[offset:offset + width].hex().lower()
            status = "OK" if extracted == expected_hex else "MISMATCH"
            print(f"{extraction['immutable_name']} @ offset {offset} width {width}: {extracted} ({status})")
            if extracted != expected_hex:
                die(f"{extraction['immutable_name']} extraction mismatch at offset {offset}")

    rpc_url = os.environ.get("ETH_RPC_URL")
    if rpc_url:
        live = refetch_from_rpc(rpc_url, entry["implementation"])
        live_sha = hashlib.sha256(live).hexdigest()
        if live_sha != entry["fixture_sha256"]:
            die(f"live deployed bytecode SHA diverged: got {live_sha}, fixture {entry['fixture_sha256']}")
        print(f"live re-verification (via {rpc_url}): OK")
    else:
        print("live re-verification skipped (set ETH_RPC_URL to enable)")

    print("verify_beacon_deposit_immutable: OK — A-TOPUP-BEACON-ADDRESS + A-DEPOSIT-CONTRACT discharge")


if __name__ == "__main__":
    main()
