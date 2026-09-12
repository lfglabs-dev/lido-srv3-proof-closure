// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// Minimal mocks required to reach pinned `StakingRouter.topUp`.
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
        items.push(Item(target, value, name, arg0, arg1));
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

contract MockLocator {
    address public gateway;
    address public dsm;

    function setGateway(address value) external {
        gateway = value;
    }

    function setDsm(address value) external {
        dsm = value;
    }

    function topUpGateway() external view returns (address) {
        return gateway;
    }

    function depositSecurityModule() external view returns (address) {
        return dsm;
    }
}

interface IReceiveDepositable {
    function receiveDepositableEther() external payable;
}

contract MockLido {
    CallLog public log;
    uint256 public depositable;
    address public router;
    bool public depositsEnabled;
    bool public failWithdraw;

    constructor(CallLog log_) {
        log = log_;
        depositsEnabled = true;
    }

    function setDepositable(uint256 value) external {
        depositable = value;
    }

    function setRouter(address value) external {
        router = value;
    }

    function setCanDeposit(bool value) external {
        depositsEnabled = value;
    }

    function setFailWithdraw(bool value) external {
        failWithdraw = value;
    }

    function getDepositableEther() external view returns (uint256) {
        return depositable;
    }

    function canDeposit() external view returns (bool) {
        return depositsEnabled;
    }

    function withdrawDepositableEther(uint256 amount, uint256 seedCount) external {
        log.push(address(this), 0, "withdrawDepositableEther", amount, seedCount);
        if (failWithdraw) revert("LIDO_FAIL");
        require(amount <= depositable, "NOT_ENOUGH_ETHER");
        depositable -= amount;
        IReceiveDepositable(router).receiveDepositableEther{value: amount}();
    }

    receive() external payable {}
}

contract MockModuleV2 {
    CallLog public log;
    uint256[] public nextAllocations;
    uint256 public totalStake;
    uint256 public depositedValidators;
    bool public failAllocate;

    constructor(CallLog log_) {
        log = log_;
        totalStake = 320 ether;
        depositedValidators = 10;
    }

    function setAllocations(uint256[] memory values) external {
        nextAllocations = values;
    }

    function setFailAllocate(bool value) external {
        failAllocate = value;
    }

    function getStakingModuleSummary() external view returns (uint256, uint256, uint256) {
        return (0, depositedValidators, 0);
    }

    function getTotalModuleStake() external view returns (uint256) {
        return totalStake;
    }

    function allocateDeposits(
        uint256 depositAmount,
        bytes[] calldata,
        uint256[] calldata,
        uint256[] calldata,
        uint256[] calldata
    ) external returns (uint256[] memory allocations) {
        log.push(address(this), 0, "allocateDeposits", depositAmount, nextAllocations.length);
        if (failAllocate) revert("MODULE_FAIL");
        allocations = nextAllocations;
    }

    function onWithdrawalCredentialsChanged() external {}
}

contract MockDeposit {
    CallLog public log;

    constructor(CallLog log_) {
        log = log_;
    }

    event DepositEvent(bytes pubkey, bytes wc, bytes sig, bytes32 root, uint256 value);

    function deposit(bytes calldata pubkey, bytes calldata wc, bytes calldata sig, bytes32 root) external payable {
        log.push(address(this), msg.value, "deposit", pubkey.length, msg.value);
        emit DepositEvent(pubkey, wc, sig, root, msg.value);
    }

    function get_deposit_root() external pure returns (bytes32) {
        return bytes32(0);
    }
}

/// Test infrastructure, not a Lido contract.
contract MinimalProxy {
    bytes32 private constant SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address impl, bytes memory data) {
        assembly ("memory-safe") {
            sstore(SLOT, impl)
        }
        (bool ok, bytes memory ret) = impl.delegatecall(data);
        require(ok, string(ret));
    }

    fallback() external payable {
        address impl;
        assembly ("memory-safe") {
            impl := sload(SLOT)
        }
        assembly ("memory-safe") {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
