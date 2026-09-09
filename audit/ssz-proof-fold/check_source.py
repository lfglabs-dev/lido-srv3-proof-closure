#!/usr/bin/env python3
"""Pinned file identity and textual anchors, not a semantic proof."""
from pathlib import Path
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[2]
PIN = "17005714f151e5502c559932319a3f2f74ac2436"
ANCHORS = {
    "contracts/common/lib/SSZ.sol": [
        "function verifyProof(bytes32[] calldata proof, bytes32 root, bytes32 leaf, GIndex gI)",
        "uint256 index = gI.index();",
        "if iszero(proof.length)",
        "let end := add(proof.offset, shl(5, proof.length))",
        "let offset := proof.offset",
        "let scratch := shl(5, and(index, 1))",
        "index := shr(1, index)",
        "if iszero(index)",
        "mstore(scratch, leaf)",
        "mstore(xor(scratch, 0x20), calldataload(offset))",
        "let result := staticcall(",
        "if iszero(result)",
        "leaf := mload(0x00)",
        "offset := add(offset, 0x20)",
        "if iszero(eq(index, 1))",
        "if iszero(eq(leaf, root))",
    ],
    "contracts/0.8.25/CLValidatorVerifier.sol": [
        "GIndex gIndexValidator = concat(GI_STATE_ROOT, _getValidatorGI(_validatorIndex, _beaconRootData.slot));",
        "SSZ.verifyProof({proof: _vw.proofValidator, root: parentBlockRoot, leaf: validatorLeaf, gI: gIndexValidator});",
        "_verifySlot(_vw.proofValidator, _beaconRootData.slot, _beaconRootData.proposerIndex);",
    ],
    "contracts/common/lib/GIndex.sol": ["function index(GIndex self) pure returns (uint256)", "return uint256(unwrap(self)) >> 8;"],
}
checks = []
for rel, anchors in ANCHORS.items():
    data = (ROOT / "lido-core" / rel).read_bytes()
    pinned = subprocess.check_output(["git", "-C", str(ROOT / "lido-core"), "show", f"{PIN}:{rel}"])
    assert data == pinned, f"Pin mismatch: {rel}"
    content = data.decode()
    for anchor in anchors:
        assert anchor in content, f"Missing anchor in {rel}: {anchor}"
    checks.append({"path": rel, "sha256": hashlib.sha256(data).hexdigest(), "matches_git_object": True, "anchors": len(anchors)})
print(json.dumps({"pin": PIN, "scope": "exact file identity and textual anchors only", "checks": checks}, indent=2))
