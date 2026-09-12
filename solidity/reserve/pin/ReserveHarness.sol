// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.4.24;

import "../../../lido-core/contracts/0.4.24/Lido.sol";

/// Exact pinned `Lido` plus mutated copies of `withdrawDepositableEther`.
/// Mutants live only here; `lido-core` is never edited.
contract ReserveHarness is Lido {
    uint256 internal mutantDummySlot;

    function seedLocator(address loc) external {
        _setLidoLocator(loc);
    }

    function seedActive() external {
        _resume();
    }

    function seedStopped() external {
        _stop();
    }

    function seedBuffer(uint256 buffered, uint256 depositedPostReport) external {
        _setBufferedEtherAndDepositedPostReport(buffered, depositedPostReport);
    }

    function seedDepositsReserve(uint256 value) external {
        _setDepositsReserve(value);
    }

    function seedNextReport(uint256 depositedNextReport, uint256 nonce) external {
        _setDepositedNextReportAndLastDepositNonce(depositedNextReport, nonce);
    }

    function readDummySlot() external view returns (uint256) {
        return mutantDummySlot;
    }

    /// Mutant: `canDeposit` guard removed. Never the pin.
    function withdrawDroppedGuard(uint256 _amount, uint256 _seedDepositsCount) external {
        IStakingRouter stakingRouter = _stakingRouter();
        _auth(address(stakingRouter));
        require(_amount != 0, "ZERO_AMOUNT");
        _spendDepositableEther(_amount);
        if (_seedDepositsCount > 0) {
            _setSeedDepositsCount(_getSeedDepositsCount().add(_seedDepositsCount));
        }
        stakingRouter.receiveDepositableEther.value(_amount)();
    }

    /// Mutant: transfer before spend. Never the pin.
    function withdrawReversedOrder(uint256 _amount, uint256) external {
        require(canDeposit(), "CAN_NOT_DEPOSIT");
        IStakingRouter stakingRouter = _stakingRouter();
        _auth(address(stakingRouter));
        require(_amount != 0, "ZERO_AMOUNT");
        stakingRouter.receiveDepositableEther.value(_amount)();
        _spendDepositableEther(_amount);
    }

    /// Mutant: extra write to a dummy slot. Never the pin.
    function withdrawWrongSlot(uint256 _amount, uint256) external {
        require(canDeposit(), "CAN_NOT_DEPOSIT");
        IStakingRouter stakingRouter = _stakingRouter();
        _auth(address(stakingRouter));
        require(_amount != 0, "ZERO_AMOUNT");
        _spendDepositableEther(_amount);
        mutantDummySlot = _amount;
        stakingRouter.receiveDepositableEther.value(_amount)();
    }
}
