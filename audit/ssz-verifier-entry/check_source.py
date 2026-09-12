#!/usr/bin/env python3
"""Pinned file identities and ordered textual anchors, not semantic equivalence."""
from pathlib import Path
import hashlib
import json
import subprocess
ROOT = Path(__file__).resolve().parents[2]
PIN = "17005714f151e5502c559932319a3f2f74ac2436"
ANCHORS = {
    "contracts/0.8.25/CLValidatorVerifier.sol": [
        "address public constant BEACON_ROOTS = 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;",
        "_verifySlot(_vw.proofValidator, _beaconRootData.slot, _beaconRootData.proposerIndex);",
        "bytes32 parentBlockRoot = _getParentBlockRoot(_beaconRootData.childBlockTimestamp);",
        "GIndex gIndexValidator = concat(GI_STATE_ROOT, _getValidatorGI(_validatorIndex, _beaconRootData.slot));",
        "bytes32 validatorLeaf = _validatorHashTreeRoot(_vw, _expectedWithdrawalCredentials);",
        "SSZ.verifyProof({proof: _vw.proofValidator, root: parentBlockRoot, leaf: validatorLeaf, gI: gIndexValidator});",
        "bytes32 parentSlotProposer = BLS12_381.sha256Pair(SSZ.toLittleEndian(_slot), SSZ.toLittleEndian(_proposerIndex));",
        "if (_proof[_proof.length - SLOT_PROPOSER_PARENT_PROOF_OFFSET] != parentSlotProposer)",
        "GIndex gI = _provenSlot < PIVOT_SLOT ? GI_FIRST_VALIDATOR_PREV : GI_FIRST_VALIDATOR_CURR;",
        "return gI.shr(_offset);",
        "(bool success, bytes memory data) = BEACON_ROOTS.staticcall(abi.encode(_childBlockTimestamp));",
        "if (!success || data.length == 0) revert RootNotFound();",
        "return abi.decode(data, (bytes32));",
    ],
    "contracts/common/lib/BLS.sol": [
        "function sha256Pair(bytes32 left, bytes32 right)",
        "let success := staticcall(gas(), SHA256, 0x00, 0x40, 0x00, 0x20)",
        "if iszero(and(success, eq(returndatasize(), 0x20)))",
        "function pubkeyRoot(bytes calldata pubkey)",
        "if (pubkey.length != 48) revert InvalidPubkeyLength();",
    ],
    "contracts/common/lib/SSZ.sol": [
        "function verifyProof(bytes32[] calldata proof, bytes32 root, bytes32 leaf, GIndex gI)",
        "if iszero(proof.length)", "let scratch := shl(5, and(index, 1))", "index := shr(1, index)",
        "if iszero(index)", "let result := staticcall(", "if iszero(result)",
        "leaf := mload(0x00)", "if iszero(eq(index, 1))", "if iszero(eq(leaf, root))",
    ],
    "contracts/common/lib/GIndex.sol": [],
    "contracts/common/interfaces/ValidatorWitness.sol": [
        "uint64 childBlockTimestamp;", "uint64 slot;", "uint64 proposerIndex;",
        "bytes32[] proofValidator;", "bytes pubkey;", "uint64 effectiveBalance;", "bool slashed;",
    ],
    "scripts/upgrade/upgrade-params-mainnet.toml": [],
}
checks = []
for path, anchors in ANCHORS.items():
    data = (ROOT / "lido-core" / path).read_bytes()
    pinned = subprocess.check_output(["git", "-C", str(ROOT / "lido-core"), "show", f"{PIN}:{path}"])
    assert data == pinned, f"Pin mismatch: {path}"
    position = -1
    for anchor in anchors:
        position = data.decode().find(anchor, position + 1)
        assert position >= 0, f"Missing or reordered anchor: {path}: {anchor}"
    if path.endswith("/SSZ.sol"):
        body = data.decode().split("function verifyProof(", 1)[1].split("function toLittleEndian(", 1)[0]
        assert "returndatasize()" not in body, "New SSZ fold returndata guard"
    checks.append({"path": path, "sha256": hashlib.sha256(data).hexdigest(),
                   "matches_git_object": True, "ordered_anchors": len(anchors)})
print(json.dumps({"pin": PIN, "scope": "file identity and ordered textual anchors only", "checks": checks}, indent=2))
