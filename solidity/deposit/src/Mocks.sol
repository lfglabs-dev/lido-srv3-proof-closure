// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// Minimal mocks required to reach pinned `StakingRouter.deposit`.
/// These are test fixtures, not Lido production contracts.

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

/// Locator stub: only `depositSecurityModule()` is read by `deposit`.
contract MockLocator {
    address public dsm;

    function setDsm(address value) external {
        dsm = value;
    }

    function depositSecurityModule() external view returns (address) {
        return dsm;
    }

    function topUpGateway() external view returns (address) {
        return address(0);
    }
}

interface IReceiveDepositable {
    function receiveDepositableEther() external payable;
}

/// Lido stub: `getDepositableEther` / `withdrawDepositableEther` only.
contract MockLido {
    CallLog public log;
    uint256 public depositable;
    address public router;
    bool public failWithdraw;
    bool public underpay;

    constructor(CallLog log_) {
        log = log_;
    }

    function setDepositable(uint256 value) external {
        depositable = value;
    }

    function setRouter(address value) external {
        router = value;
    }

    function setFailWithdraw(bool value) external {
        failWithdraw = value;
    }

    function setUnderpay(bool value) external {
        underpay = value;
    }

    function getDepositableEther() external view returns (uint256) {
        return depositable;
    }

    function withdrawDepositableEther(uint256 amount, uint256 seedCount) external {
        log.push(address(this), 0, "withdrawDepositableEther", amount, seedCount);
        if (failWithdraw) revert("LIDO_FAIL");
        require(amount <= depositable, "NOT_ENOUGH_ETHER");
        depositable -= amount;
        uint256 sent = underpay && amount > 0 ? amount - 1 : amount;
        IReceiveDepositable(router).receiveDepositableEther{value: sent}();
    }

    receive() external payable {}
}

/// Module stub: summary + `obtainDepositData`.
contract MockModule {
    CallLog public log;
    uint256 public depositableValidators;
    uint256 public keysToReturn;
    bool public failObtain;
    bool public exceedTarget;
    bool public badLength;

    constructor(CallLog log_) {
        log = log_;
        depositableValidators = 100;
        keysToReturn = 2;
    }

    function configure(uint256 depositable_, uint256 keys_) external {
        depositableValidators = depositable_;
        keysToReturn = keys_;
    }

    function setFailObtain(bool value) external {
        failObtain = value;
    }

    function setExceedTarget(bool value) external {
        exceedTarget = value;
    }

    function setBadLength(bool value) external {
        badLength = value;
    }

    function getStakingModuleSummary() external view returns (uint256, uint256, uint256) {
        return (0, 0, depositableValidators);
    }

    function obtainDepositData(uint256 count, bytes calldata) external returns (bytes memory, bytes memory) {
        log.push(address(this), 0, "obtainDepositData", count, 0);
        if (failObtain) revert("MODULE_FAIL");
        uint256 n = keysToReturn;
        if (exceedTarget) n = count + 1;
        else if (n > count) n = count;
        uint256 pkLen = badLength ? n * 48 + 1 : n * 48;
        return (new bytes(pkLen), new bytes(n * 96));
    }

    function onWithdrawalCredentialsChanged() external {}
}

/// Beacon deposit-contract stub.
contract MockDeposit {
    CallLog public log;

    constructor(CallLog log_) {
        log = log_;
    }

    event DepositEvent(bytes pubkey, bytes withdrawal_credentials, bytes signature, bytes32 root, uint256 value);

    function deposit(bytes calldata pubkey, bytes calldata wc, bytes calldata sig, bytes32 root) external payable {
        log.push(address(this), msg.value, "deposit", pubkey.length, msg.value);
        emit DepositEvent(pubkey, wc, sig, root, msg.value);
    }

    function get_deposit_root() external pure returns (bytes32) {
        return bytes32(0);
    }
}

/// Minimal ERC-1967 proxy so the pinned implementation can be initialized.
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
