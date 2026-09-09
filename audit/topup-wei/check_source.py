#!/usr/bin/env python3
"""Read-only source pin / arithmetic-slice correspondence checks.

This checks anchors, not semantic equivalence or deployed provenance.
"""
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
PIN = "17005714f151e5502c559932319a3f2f74ac2436"
SRC = ROOT / "lido-core"
ANCHORS = {
    "contracts/0.8.25/TopUpGateway.sol": [
        "uint64 maxValidatorsPerTopUp;",
        "uint64 targetBalanceGwei;",
        "uint64 minTopUpGwei;",
        "if (validatorsCount > $.maxValidatorsPerTopUp)",
        "topUpLimits[i] = _evaluateTopUpLimit(vw, _topUps.pendingBalanceGwei[i]) * 1 gwei;",
        "totalLimits += topUpLimits[i];",
        "if (_validator.exitEpoch != FAR_FUTURE_EPOCH || _validator.slashed)",
        "uint256 currentTotal = _validator.effectiveBalance + _pendingBalanceGwei;",
        "if (currentTotal >= $.targetBalanceGwei) return 0;",
        "uint256 topUpLimit = $.targetBalanceGwei - currentTotal;",
        "if (topUpLimit < $.minTopUpGwei) return 0;",
        "return topUpLimit;",
    ],
    "contracts/common/interfaces/ValidatorWitness.sol": [
        "uint64 effectiveBalance;", "uint64 exitEpoch;", "bool slashed;",
    ],
    "contracts/0.8.25/sr/SRTypes.sol": ["uint64 maxTopUpPerBlockGwei;"],
    "contracts/0.8.25/sr/StakingRouter.sol": [
        "uint256 maxTopUpPerBlockWei = uint256(SRStorage.getRouterState().maxTopUpPerBlockGwei) * 1 gwei;",
        "uint256 smDepositableEthAmount = Math.min(_getModuleDepositAllocation(_stakingModuleId, depositableEther, true), maxTopUpPerBlockWei);",
        "uint256 smDepositableEthAmountRounded = smDepositableEthAmount - (smDepositableEthAmount % 1 gwei);",
        "for (uint256 i; i < allocations.length; ++i)",
        "if (allocations[i] % 1 gwei != 0)",
        "if (allocations[i] > _topUpLimits[i])",
        "amount += allocations[i];",
        "if (amount > smDepositableEthAmountRounded)",
    ],
}

def main():
    head = subprocess.check_output(["git", "-C", str(SRC), "rev-parse", "HEAD"], text=True).strip()
    if head != PIN:
        raise SystemExit(f"source HEAD mismatch: {head}")
    result = {"source_pin": PIN, "checks": [], "scope": "exact file comparison and textual anchors only"}
    for filename, anchors in ANCHORS.items():
        current = (SRC / filename).read_bytes()
        pinned = subprocess.check_output(["git", "-C", str(SRC), "show", f"{PIN}:{filename}"])
        if current != pinned:
            raise SystemExit(f"working source differs from pin: {filename}")
        text = current.decode()
        for anchor in anchors:
            if anchor not in text:
                raise SystemExit(f"missing anchor in {filename}: {anchor}")
        result["checks"].append({"file": filename, "sha256": hashlib.sha256(current).hexdigest(), "anchors": len(anchors)})
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
