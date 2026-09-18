#!/usr/bin/env python3
"""Reproduce the LIDO immutable extraction from the deployed StakingRouter
implementation bytecode.

The LIDO immutable is inlined at seven `push20_payload_enumeration` byte
offsets in the deployed runtime (StakingRouter.sol:60 `LIDO = ILido(_lido)`
receives its value at constructor line 100 from the `_lido` argument, and
solc's immutable optimization inlines the 20-byte payload at every
`LIDO.*` call site: source lines 666, 697, 713, 744, 951, 983, plus one
internal helper reference).

`LidoSRv3.Audit.Provenance.LidoAddress.lean` proves the corresponding
`topup_verity_lido_equals_deployed_immutable` theorem by `decide +kernel`;
this Python companion re-hashes the pinned fixture and re-extracts every
recorded offset, closing the deployment-provenance obligation
A-RUNTIME-PROVENANCE for D-ADDR-1 (Grok #414) alongside
`verify_beacon_deposit_immutable.py`.

Usage:
    python3 scripts/verify_lido_immutable.py
    ETH_RPC_URL=https://... python3 scripts/verify_lido_immutable.py
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
IMMUTABLE_NAME_PREFIX = "LIDO ("

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_deployed_code import keccak256  # noqa: E402


def die(msg: str) -> "None":
    print(f"verify_lido_immutable: {msg}", file=sys.stderr)
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

    expected_codehash = entry.get("fixture_codehash_keccak256")
    if not expected_codehash:
        die("audit/artifacts.lock.json entry missing fixture_codehash_keccak256")
    actual_codehash = keccak256(fixture_bytes).hex()
    if actual_codehash != expected_codehash:
        die(f"fixture keccak256 mismatch: got {actual_codehash}, expected {expected_codehash}")
    print(
        f"fixture codehash keccak256 = {actual_codehash} "
        "(EIP-1052 EXTCODEHASH of the deployed runtime bytecode)"
    )

    lido_extractions = [
        ext for ext in entry["immutable_extractions"]
        if ext["immutable_name"].startswith(IMMUTABLE_NAME_PREFIX)
    ]
    if not lido_extractions:
        die(f"no LIDO immutable extraction found in {ARTIFACTS.relative_to(ROOT)}")
    if len(lido_extractions) != 1:
        die(f"expected exactly one LIDO immutable extraction, got {len(lido_extractions)}")

    extraction = lido_extractions[0]
    width = extraction["width_bytes"]
    if width != 20:
        die(f"LIDO immutable width {width} != 20 (expected an address payload)")
    expected_hex = extraction["expected_value_hex"].lower()
    offsets = extraction.get("byte_offsets") or [extraction["byte_offset"]]
    if not offsets:
        die("LIDO immutable extraction has no byte offsets")

    for offset in offsets:
        extracted = fixture_bytes[offset:offset + width].hex().lower()
        status = "OK" if extracted == expected_hex else "MISMATCH"
        print(f"{extraction['immutable_name']} @ offset {offset} width {width}: {extracted} ({status})")
        if extracted != expected_hex:
            die(f"LIDO extraction mismatch at offset {offset}")

    print(f"LIDO immutable re-extracted at {len(offsets)} recorded push20 offsets, all match")

    rpc_url = os.environ.get("ETH_RPC_URL")
    if rpc_url:
        live = refetch_from_rpc(rpc_url, entry["implementation"])
        live_sha = hashlib.sha256(live).hexdigest()
        if live_sha != entry["fixture_sha256"]:
            die(f"live deployed bytecode SHA diverged: got {live_sha}, fixture {entry['fixture_sha256']}")
        live_codehash = keccak256(live).hex()
        if live_codehash != expected_codehash:
            die(f"live EIP-1052 codehash diverged from fixture: got {live_codehash}, fixture {expected_codehash}")
        print(f"live re-verification (via {rpc_url}): OK (codehash {live_codehash})")
    else:
        print("live re-verification skipped (set ETH_RPC_URL to enable)")

    print("verify_lido_immutable: OK — D-ADDR-1 Lido-address half discharge companion")


if __name__ == "__main__":
    main()
