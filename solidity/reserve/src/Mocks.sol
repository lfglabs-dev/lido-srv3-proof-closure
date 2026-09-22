// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// Minimal mocks required to reach pinned `Lido.withdrawDepositableEther`.
/// Test fixtures, not Lido production contracts.

contract CallLog {
    struct Item {
        address target;
        uint256 value;
        string name;
        uint256 arg0;
        uint256 arg1;
    }

    Item[] public items;

    function push(address target, uint256 value, string memory name, uint256 arg0, uint256 arg1) external {
        items.push(Item({target: target, value: value, name: name, arg0: arg0, arg1: arg1}));
    }

    function count() external view returns (uint256) {
        return items.length;
    }

    function at(uint256 i) external view returns (Item memory) {
        return items[i];
    }

    function reset() external {
        delete items;
    }
}

/// Fixture: `IWithdrawalQueue` surface used at Lido.sol:612 and :816.
/// Selector of `unfinalizedStETH()` matches WithdrawalQueueBase.sol:143 (`0xd0fb84e8`).
contract MockWithdrawalQueue {
    uint256 public unfinalized;
    bool public bunker;
    CallLog public log;

    constructor(CallLog log_) {
        log = log_;
    }

    function setUnfinalized(uint256 value) external {
        unfinalized = value;
    }

    function setBunker(bool value) external {
        bunker = value;
    }

    function unfinalizedStETH() external view returns (uint256) {
        return unfinalized;
    }

    function isBunkerModeActive() external view returns (bool) {
        return bunker;
    }
}

/// Fixture: locator words the pin reads for router / queue / accounting oracle.
contract MockLocator {
    address public stakingRouterAddr;
    address public withdrawalQueueAddr;
    address public accountingOracleAddr;

    function set(address router, address queue, address oracle) external {
        stakingRouterAddr = router;
        withdrawalQueueAddr = queue;
        accountingOracleAddr = oracle;
    }

    function stakingRouter() external view returns (address) {
        return stakingRouterAddr;
    }

    function withdrawalQueue() external view returns (address) {
        return withdrawalQueueAddr;
    }

    function accountingOracle() external view returns (address) {
        return accountingOracleAddr;
    }
}

/// Fixture: `getCurrentFrame` so `_getDepositedNextReportAdjusted` keeps the seeded nonce.
contract MockAccountingOracle {
    uint256 public refSlot;
    uint256 public refTs;

    function setFrame(uint256 slot, uint256 ts) external {
        refSlot = slot;
        refTs = ts;
    }

    function getCurrentFrame() external view returns (uint256, uint256) {
        return (refSlot, refTs);
    }
}

/// Fixture: records `receiveDepositableEther` and the Lido buffer observed at pay time.
interface IBuffered {
    function getBufferedEther() external view returns (uint256);
}

contract MockStakingRouter {
    CallLog public log;
    bool public failReceive;
    uint256 public bufferedAtPay;

    constructor(CallLog log_) {
        log = log_;
    }

    function setFailReceive(bool value) external {
        failReceive = value;
    }

    function receiveDepositableEther() external payable {
        bufferedAtPay = IBuffered(msg.sender).getBufferedEther();
        log.push(address(this), msg.value, "receiveDepositableEther", msg.value, bufferedAtPay);
        if (failReceive) revert("router fail");
    }
}
