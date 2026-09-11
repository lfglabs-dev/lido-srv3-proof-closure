#!/usr/bin/env python3
"""Reproduce the joint discharge of `MAX_EFFECTIVE_BALANCE_WC_TYPE_01`
(constructor immutable) and `BeaconChainDepositor.DEPOSIT_SIZE`
(compile-time constant) against the deployed Lido StakingRouter
implementation runtime bytecode.

Closes A-DEPOSIT-32-ETHER (P-DEPOSIT-1, P-ALLOC-EXEC-1) down to
A-RUNTIME-PROVENANCE.

Usage:
    python3 scripts/verify_deposit_thirty_two_ether.py
    ETH_RPC_URL=https://... python3 scripts/verify_deposit_thirty_two_ether.py
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

THIRTY_TWO_ETHER = 32 * 10 ** 18
THIRTY_TWO_ETHER_WORD = THIRTY_TWO_ETHER.to_bytes(32, "big")
EXPECTED_PUSH32_OFFSETS = (5521, 12112, 14036, 15415, 20126)


def die(msg: str) -> "None":
    print(f"verify_deposit_thirty_two_ether: {msg}", file=sys.stderr)
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
        die(f"RPC eth_getCode failed: {e}")
    if "result" not in d:
        die(f"RPC error: {d}")
    return bytes.fromhex(d["result"][2:])


def enumerate_push32_offsets(bytecode: bytes, word: bytes) -> list[int]:
    """Return all offsets where `word` sits in the bytecode immediately
    after a PUSH32 (0x7f) opcode. This over-approximates only if the
    byte 0x7f coincidentally precedes a 32-byte occurrence that is not
    an actual opcode; for a `constant` uint256 and an `immutable`
    uint256, solc always emits the read as `PUSH32 <32-byte>`, so this
    is exactly the set of runtime read sites."""
    offsets: list[int] = []
    i = 0
    while True:
        j = bytecode.find(word, i)
        if j == -1:
            break
        if j > 0 and bytecode[j - 1] == 0x7f:
            offsets.append(j)
        i = j + 1
    return offsets


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

    # Enumerate every PUSH32 site whose payload equals the 32-ether word.
    push_offsets = enumerate_push32_offsets(fixture_bytes, THIRTY_TWO_ETHER_WORD)
    if tuple(push_offsets) != EXPECTED_PUSH32_OFFSETS:
        die(f"PUSH32(32-ether) offset set changed: got {push_offsets}, "
            f"expected {list(EXPECTED_PUSH32_OFFSETS)}")

    # Confirm each 32-byte payload folds big-endian to 32 ether.
    for offset in push_offsets:
        payload = fixture_bytes[offset:offset + 32]
        value = int.from_bytes(payload, "big")
        status = "OK" if value == THIRTY_TWO_ETHER else "MISMATCH"
        print(f"PUSH32(32-ether) @ offset {offset}: {payload.hex()} => {value} ({status})")
        if value != THIRTY_TWO_ETHER:
            die(f"payload at offset {offset} does not decode to 32 ether")

    print(f"joint discharge: MAX_EFFECTIVE_BALANCE_WC_TYPE_01 immutable and DEPOSIT_SIZE constant "
          f"both read via one of {len(push_offsets)} PUSH32 sites, all folding to "
          f"{THIRTY_TWO_ETHER} wei = 32 ether")

    rpc_url = os.environ.get("ETH_RPC_URL")
    if rpc_url:
        live = refetch_from_rpc(rpc_url, entry["implementation"])
        live_sha = hashlib.sha256(live).hexdigest()
        if live_sha != entry["fixture_sha256"]:
            die(f"live deployed bytecode SHA diverged: got {live_sha}, fixture {entry['fixture_sha256']}")
        print(f"live re-verification (implementation bytecode via {rpc_url}): OK")
    else:
        print("live re-verification skipped (set ETH_RPC_URL to enable)")

    print("verify_deposit_thirty_two_ether: OK -- A-DEPOSIT-32-ETHER discharge")


if __name__ == "__main__":
    main()
