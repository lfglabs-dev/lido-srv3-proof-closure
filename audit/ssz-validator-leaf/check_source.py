#!/usr/bin/env python3
"""Exact pinned file comparison and textual anchors, not semantic equivalence."""
from pathlib import Path
import hashlib
import json
import subprocess
ROOT = Path(__file__).resolve().parents[2]
PIN = "17005714f151e5502c559932319a3f2f74ac2436"
ANCHORS = {
    "contracts/0.8.25/CLValidatorVerifier.sol": [
        "leaves[0] = BLS12_381.pubkeyRoot(_w.pubkey);",
        "leaves[1] = _expectedWithdrawalCredentials;",
        "leaves[2] = SSZ.toLittleEndian(_w.effectiveBalance);",
        "leaves[3] = SSZ.toLittleEndian(_w.slashed ? uint64(1) : 0);",
        "leaves[4] = SSZ.toLittleEndian(_w.activationEligibilityEpoch);",
        "leaves[5] = SSZ.toLittleEndian(_w.activationEpoch);",
        "leaves[6] = SSZ.toLittleEndian(_w.exitEpoch);",
        "leaves[7] = SSZ.toLittleEndian(_w.withdrawableEpoch);",
        "l1[0] = BLS12_381.sha256Pair(leaves[0], leaves[1]);",
        "l1[1] = BLS12_381.sha256Pair(leaves[2], leaves[3]);",
        "l1[2] = BLS12_381.sha256Pair(leaves[4], leaves[5]);",
        "l1[3] = BLS12_381.sha256Pair(leaves[6], leaves[7]);",
        "l2[0] = BLS12_381.sha256Pair(l1[0], l1[1]);",
        "l2[1] = BLS12_381.sha256Pair(l1[2], l1[3]);",
        "return BLS12_381.sha256Pair(l2[0], l2[1]);",
    ],
    "contracts/common/lib/BLS.sol": [
        "function sha256Pair(bytes32 left, bytes32 right)",
        "mstore(0x00, left)", "mstore(0x20, right)",
        "function pubkeyRoot(bytes calldata pubkey)",
        "if (pubkey.length != 48) revert InvalidPubkeyLength();",
        "mstore(0x20, 0)", "calldatacopy(0x00, pubkey.offset, 48)",
        "let success := staticcall(gas(), SHA256, 0x00, 0x40, 0x00, 0x20)",
        "if iszero(and(success, eq(returndatasize(), 0x20)))",
    ],
    "contracts/common/interfaces/ValidatorWitness.sol": [
        "bytes32[] proofValidator;", "bytes pubkey;", "uint64 effectiveBalance;", "bool slashed;",
    ],
    "contracts/common/lib/SSZ.sol": [
        "function toLittleEndian(uint256 v)",
    ],
}
checks = []
for path, anchors in ANCHORS.items():
    data = (ROOT / "lido-core" / path).read_bytes()
    pinned = subprocess.check_output(["git", "-C", str(ROOT / "lido-core"), "show", f"{PIN}:{path}"])
    assert data == pinned, f"Pin mismatch: {path}"
    for anchor in anchors:
        assert anchor in data.decode(), f"Missing anchor: {path}: {anchor}"
    checks.append({"path": path, "sha256": hashlib.sha256(data).hexdigest(), "matches_git_object": True, "anchors": len(anchors)})
print(json.dumps({"pin": PIN, "scope": "file identity and textual anchors only", "checks": checks}, indent=2))
