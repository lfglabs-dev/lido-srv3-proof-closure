// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {StakingRouter} from "../../../lido-core/contracts/0.8.25/sr/StakingRouter.sol";
import {Math} from "@openzeppelin/contracts-v5.2/utils/math/Math.sol";
import {BeaconChainDepositor} from "contracts/0.8.25/lib/BeaconChainDepositor.sol";
import {IStakingModuleV2} from "contracts/common/interfaces/IStakingModuleV2.sol";
import {SRUtils} from "contracts/0.8.25/sr/SRUtils.sol";
import {SRStorage} from "contracts/0.8.25/sr/SRStorage.sol";
import {ModuleStateConfig, StakingModuleStatus} from "contracts/0.8.25/sr/SRTypes.sol";

/// Exact pinned `StakingRouter` plus mutated copies of `topUp`.
/// Mutants live only here; `lido-core` is never edited.
contract TopupHarness is StakingRouter {
    uint256 private mutantDummySlot;

    constructor(
        address depositContract,
        address lido,
        address locator,
        uint256 maxEBType1,
        uint256 maxEBType2
    ) StakingRouter(depositContract, lido, locator, maxEBType1, maxEBType2) {}

    function _topUpBody(
        uint256 _stakingModuleId,
        uint256[] calldata _keyIndices,
        uint256[] calldata _operatorIds,
        bytes[] calldata _pubkeys,
        uint256[] calldata _topUpLimits,
        bool dropAssert,
        bool reverseOrder,
        bool wrongSlot
    ) internal {
        _checkAppAuth(_getTopUpGateway());
        _validateTopUpInputs(_keyIndices, _operatorIds, _topUpLimits, _pubkeys);
        (, ModuleStateConfig storage stateConfig) = _getModuleState(_stakingModuleId);
        if (stateConfig.status != StakingModuleStatus.Active) revert StakingModuleNotActive();
        SRUtils._requireWCType2(stateConfig.withdrawalCredentialsType);
        uint256 maxTopUpPerBlockWei = uint256(SRStorage.getRouterState().maxTopUpPerBlockGwei) * 1 gwei;
        uint256 depositableEther = LIDO.getDepositableEther();
        uint256 smDepositableEthAmount =
            Math.min(_getModuleDepositAllocation(_stakingModuleId, depositableEther, true), maxTopUpPerBlockWei);
        uint256 smDepositableEthAmountRounded = smDepositableEthAmount - (smDepositableEthAmount % 1 gwei);
        if (smDepositableEthAmountRounded == 0 && !LIDO.canDeposit()) {
            revert LidoDepositsPaused();
        }
        uint256[] memory allocations = IStakingModuleV2(stateConfig.moduleAddress)
            .allocateDeposits(smDepositableEthAmountRounded, _pubkeys, _keyIndices, _operatorIds, _topUpLimits);
        uint256 amount;
        unchecked {
            for (uint256 i; i < allocations.length; ++i) {
                if (allocations[i] % 1 gwei != 0) revert AmountNotAlignedToGwei();
                if (allocations[i] > _topUpLimits[i]) revert AllocationExceedsLimit();
                amount += allocations[i];
            }
        }
        if (amount > smDepositableEthAmountRounded) revert ModuleReturnExceedTarget();
        if (wrongSlot) {
            mutantDummySlot = amount;
        }
        if (amount > 0) {
            uint256 etherBalanceBeforeDeposits = address(this).balance;
            bytes32 withdrawalCredentials = _getWithdrawalCredentialsWithType(stateConfig.withdrawalCredentialsType);
            bytes memory wcBytes = abi.encodePacked(withdrawalCredentials);
            if (reverseOrder) {
                BeaconChainDepositor.makeBeaconChainTopUp(DEPOSIT_CONTRACT, wcBytes, _pubkeys, allocations);
                LIDO.withdrawDepositableEther(amount, 0);
            } else {
                LIDO.withdrawDepositableEther(amount, 0);
                BeaconChainDepositor.makeBeaconChainTopUp(DEPOSIT_CONTRACT, wcBytes, _pubkeys, allocations);
            }
            if (!dropAssert) {
                assert(etherBalanceBeforeDeposits == address(this).balance);
            }
        }
        emit StakingRouterETHTopUp(_stakingModuleId, amount);
    }

    function topUpDroppedAssert(
        uint256 id,
        uint256[] calldata keyIndices,
        uint256[] calldata operatorIds,
        bytes[] calldata pubkeys,
        uint256[] calldata topUpLimits
    ) external {
        _topUpBody(id, keyIndices, operatorIds, pubkeys, topUpLimits, true, false, false);
    }

    function topUpReversedOrder(
        uint256 id,
        uint256[] calldata keyIndices,
        uint256[] calldata operatorIds,
        bytes[] calldata pubkeys,
        uint256[] calldata topUpLimits
    ) external {
        _topUpBody(id, keyIndices, operatorIds, pubkeys, topUpLimits, false, true, false);
    }

    function topUpWrongSlot(
        uint256 id,
        uint256[] calldata keyIndices,
        uint256[] calldata operatorIds,
        bytes[] calldata pubkeys,
        uint256[] calldata topUpLimits
    ) external {
        _topUpBody(id, keyIndices, operatorIds, pubkeys, topUpLimits, false, false, true);
    }
}
