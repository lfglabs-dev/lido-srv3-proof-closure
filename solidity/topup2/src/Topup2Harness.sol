// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {TopUpGateway} from "../../../lido-core/contracts/0.8.25/TopUpGateway.sol";
import {GIndex} from "contracts/common/lib/GIndex.sol";
import {BeaconRootData, ValidatorWitness} from "contracts/common/interfaces/ValidatorWitness.sol";

/// Exact pinned `TopUpGateway` plus mutated copies of `_evaluateTopUpLimit`.
/// Mutants live only here; `lido-core` is never edited.
contract Topup2Harness is TopUpGateway {
    uint256 private mutantDummySlot;

    constructor(
        address lidoLocator,
        GIndex gIFirstValidatorPrev,
        GIndex gIFirstValidatorCurr,
        uint64 pivotSlot,
        uint256 slotsPerEpoch
    ) TopUpGateway(lidoLocator, gIFirstValidatorPrev, gIFirstValidatorCurr, pivotSlot, slotsPerEpoch) {}

    /// Fixture: skip CL Merkle verification so the numeric evaluate loop is reachable.
    /// Not a production override of the pin.
    function _verifyValidator(BeaconRootData calldata, ValidatorWitness calldata, uint256, bytes32)
        internal
        view
        override
    {}

    function evaluateLimit(ValidatorWitness calldata vw, uint256 pendingBalanceGwei)
        external
        view
        returns (uint256)
    {
        return _evaluateTopUpLimit(vw, pendingBalanceGwei);
    }

    /// Independent per-key limits, matching `TopUpGateway.sol:226` without `* 1 gwei`.
    function evaluateBatch(ValidatorWitness[] calldata vws, uint256[] calldata pending)
        external
        view
        returns (uint256[] memory limits)
    {
        limits = new uint256[](vws.length);
        for (uint256 i; i < vws.length; ++i) {
            limits[i] = _evaluateTopUpLimit(vws[i], pending[i]);
        }
    }

    /// Mutant: slash / exit guard removed. Never the pin.
    function evaluateDroppedGuard(ValidatorWitness calldata vw, uint256 pendingBalanceGwei)
        external
        view
        returns (uint256)
    {
        Storage storage $ = _gatewayStorage();
        uint256 currentTotal = vw.effectiveBalance + pendingBalanceGwei;
        if (currentTotal >= $.targetBalanceGwei) return 0;
        uint256 topUpLimit = $.targetBalanceGwei - currentTotal;
        if (topUpLimit < $.minTopUpGwei) return 0;
        return topUpLimit;
    }

    /// Mutant: last-to-first write order. Never the pin.
    function evaluateReversedOrder(ValidatorWitness[] calldata vws, uint256[] calldata pending)
        external
        view
        returns (uint256[] memory limits)
    {
        uint256 n = vws.length;
        limits = new uint256[](n);
        for (uint256 i; i < n; ++i) {
            limits[n - 1 - i] = _evaluateTopUpLimit(vws[i], pending[i]);
        }
    }

    /// Mutant: treat `minTopUpGwei` as the target (wrong packed field). Never the pin.
    function evaluateWrongSlot(ValidatorWitness calldata vw, uint256 pendingBalanceGwei)
        external
        view
        returns (uint256)
    {
        Storage storage $ = _gatewayStorage();
        uint256 currentTotal = vw.effectiveBalance + pendingBalanceGwei;
        uint256 bogusTarget = $.minTopUpGwei;
        if (currentTotal >= bogusTarget) return 0;
        uint256 topUpLimit = bogusTarget - currentTotal;
        if (topUpLimit < $.minTopUpGwei) return 0;
        mutantDummySlot;
        return topUpLimit;
    }
}
