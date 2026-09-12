// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {StakingRouter} from "../../../lido-core/contracts/0.8.25/sr/StakingRouter.sol";
import {Math} from "@openzeppelin/contracts-v5.2/utils/math/Math.sol";
import {BeaconChainDepositor} from "contracts/0.8.25/lib/BeaconChainDepositor.sol";
import {IStakingModule} from "contracts/common/interfaces/IStakingModule.sol";
import {
    ModuleState,
    ModuleStateConfig,
    StakingModuleStatus
} from "contracts/0.8.25/sr/SRTypes.sol";

/// Exact pinned `StakingRouter` plus mutated copies of `deposit`.
/// Mutants live only here; `lido-core` is never edited.
contract DepositHarness is StakingRouter {
    /// Observation slot used only by the wrong-slot mutant.
    uint256 private mutantDummySlot;

    constructor(
        address depositContract,
        address lido,
        address locator,
        uint256 maxEBType1,
        uint256 maxEBType2
    ) StakingRouter(depositContract, lido, locator, maxEBType1, maxEBType2) {}

    /// Mutant: line-996 conservation assert removed.
    function depositDroppedAssert(uint256 _stakingModuleId, bytes calldata _depositCalldata) external {
        _checkAppAuth(_getDepositSecurityModule());
        (ModuleState storage state, ModuleStateConfig storage stateConfig) = _getModuleState(_stakingModuleId);
        if (stateConfig.status != StakingModuleStatus.Active) revert StakingModuleNotActive();
        bytes32 withdrawalCredentials = _getWithdrawalCredentialsWithType(stateConfig.withdrawalCredentialsType);
        address stakingModuleAddress = stateConfig.moduleAddress;
        uint256 depositableEther = LIDO.getDepositableEther();
        uint256 stakingModuleDepositableEthAmount =
            _getModuleDepositAllocation(_stakingModuleId, depositableEther, false);
        uint256 maxDepositsCount = Math.min(
            state.deposits.maxDepositsPerBlock,
            stakingModuleDepositableEthAmount / MAX_EFFECTIVE_BALANCE_WC_TYPE_01
        );
        if (maxDepositsCount == 0) revert ZeroDeposits();
        (bytes memory publicKeysBatch, bytes memory signaturesBatch) =
            IStakingModule(stakingModuleAddress).obtainDepositData(maxDepositsCount, _depositCalldata);
        if (publicKeysBatch.length % PUBKEY_LENGTH != 0) revert WrongPubkeyLength();
        uint256 actualDepositsCount = publicKeysBatch.length / PUBKEY_LENGTH;
        if (actualDepositsCount > maxDepositsCount) revert ModuleReturnExceedTarget();
        uint256 depositsValue = actualDepositsCount * MAX_EFFECTIVE_BALANCE_WC_TYPE_01;
        _updateModuleLastDepositState(_stakingModuleId, depositsValue);
        if (actualDepositsCount == 0) return;
        LIDO.withdrawDepositableEther(depositsValue, actualDepositsCount);
        BeaconChainDepositor.makeBeaconChainDeposits32ETH(
            DEPOSIT_CONTRACT,
            actualDepositsCount,
            abi.encodePacked(withdrawalCredentials),
            publicKeysBatch,
            signaturesBatch
        );
    }

    /// Mutant: beacon push runs before the Lido pull.
    function depositReversedOrder(uint256 _stakingModuleId, bytes calldata _depositCalldata) external {
        _checkAppAuth(_getDepositSecurityModule());
        (ModuleState storage state, ModuleStateConfig storage stateConfig) = _getModuleState(_stakingModuleId);
        if (stateConfig.status != StakingModuleStatus.Active) revert StakingModuleNotActive();
        bytes32 withdrawalCredentials = _getWithdrawalCredentialsWithType(stateConfig.withdrawalCredentialsType);
        address stakingModuleAddress = stateConfig.moduleAddress;
        uint256 depositableEther = LIDO.getDepositableEther();
        uint256 stakingModuleDepositableEthAmount =
            _getModuleDepositAllocation(_stakingModuleId, depositableEther, false);
        uint256 maxDepositsCount = Math.min(
            state.deposits.maxDepositsPerBlock,
            stakingModuleDepositableEthAmount / MAX_EFFECTIVE_BALANCE_WC_TYPE_01
        );
        if (maxDepositsCount == 0) revert ZeroDeposits();
        (bytes memory publicKeysBatch, bytes memory signaturesBatch) =
            IStakingModule(stakingModuleAddress).obtainDepositData(maxDepositsCount, _depositCalldata);
        if (publicKeysBatch.length % PUBKEY_LENGTH != 0) revert WrongPubkeyLength();
        uint256 actualDepositsCount = publicKeysBatch.length / PUBKEY_LENGTH;
        if (actualDepositsCount > maxDepositsCount) revert ModuleReturnExceedTarget();
        uint256 depositsValue = actualDepositsCount * MAX_EFFECTIVE_BALANCE_WC_TYPE_01;
        _updateModuleLastDepositState(_stakingModuleId, depositsValue);
        if (actualDepositsCount == 0) return;
        uint256 etherBalanceBeforeDeposits = address(this).balance;
        BeaconChainDepositor.makeBeaconChainDeposits32ETH(
            DEPOSIT_CONTRACT,
            actualDepositsCount,
            abi.encodePacked(withdrawalCredentials),
            publicKeysBatch,
            signaturesBatch
        );
        LIDO.withdrawDepositableEther(depositsValue, actualDepositsCount);
        uint256 etherBalanceAfterDeposits = address(this).balance;
        assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits);
    }

    /// Mutant: last-deposit write goes to a dummy slot, not module deposits storage.
    function depositWrongSlot(uint256 _stakingModuleId, bytes calldata _depositCalldata) external {
        _checkAppAuth(_getDepositSecurityModule());
        (ModuleState storage state, ModuleStateConfig storage stateConfig) = _getModuleState(_stakingModuleId);
        if (stateConfig.status != StakingModuleStatus.Active) revert StakingModuleNotActive();
        bytes32 withdrawalCredentials = _getWithdrawalCredentialsWithType(stateConfig.withdrawalCredentialsType);
        address stakingModuleAddress = stateConfig.moduleAddress;
        uint256 depositableEther = LIDO.getDepositableEther();
        uint256 stakingModuleDepositableEthAmount =
            _getModuleDepositAllocation(_stakingModuleId, depositableEther, false);
        uint256 maxDepositsCount = Math.min(
            state.deposits.maxDepositsPerBlock,
            stakingModuleDepositableEthAmount / MAX_EFFECTIVE_BALANCE_WC_TYPE_01
        );
        if (maxDepositsCount == 0) revert ZeroDeposits();
        (bytes memory publicKeysBatch, bytes memory signaturesBatch) =
            IStakingModule(stakingModuleAddress).obtainDepositData(maxDepositsCount, _depositCalldata);
        if (publicKeysBatch.length % PUBKEY_LENGTH != 0) revert WrongPubkeyLength();
        uint256 actualDepositsCount = publicKeysBatch.length / PUBKEY_LENGTH;
        if (actualDepositsCount > maxDepositsCount) revert ModuleReturnExceedTarget();
        uint256 depositsValue = actualDepositsCount * MAX_EFFECTIVE_BALANCE_WC_TYPE_01;
        mutantDummySlot = depositsValue;
        if (actualDepositsCount == 0) return;
        uint256 etherBalanceBeforeDeposits = address(this).balance;
        LIDO.withdrawDepositableEther(depositsValue, actualDepositsCount);
        BeaconChainDepositor.makeBeaconChainDeposits32ETH(
            DEPOSIT_CONTRACT,
            actualDepositsCount,
            abi.encodePacked(withdrawalCredentials),
            publicKeysBatch,
            signaturesBatch
        );
        uint256 etherBalanceAfterDeposits = address(this).balance;
        assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits);
    }
}
