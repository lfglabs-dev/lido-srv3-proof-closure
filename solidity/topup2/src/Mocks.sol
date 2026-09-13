// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// Minimal mocks required to reach pinned `TopUpGateway.topUp`.
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

/// Fixture: locator only exposes `stakingRouter()` for the gateway constructor.
contract MockLocator {
    address public router;

    function setRouter(address value) external {
        router = value;
    }

    function stakingRouter() external view returns (address) {
        return router;
    }
}

/// Fixture: records `topUp` target/payload/order. Not the pinned StakingRouter.
contract MockStakingRouter {
    CallLog public log;
    mapping(uint256 => bytes32) public wc;
    bool public failTopUp;
    uint256 public topUpCalls;

    constructor(CallLog log_) {
        log = log_;
    }

    function setWithdrawalCredentials(uint256 moduleId, bytes32 value) external {
        wc[moduleId] = value;
    }

    function setFailTopUp(bool value) external {
        failTopUp = value;
    }

    function getStakingModuleWithdrawalCredentials(uint256 moduleId) external view returns (bytes32) {
        return wc[moduleId];
    }

    function topUp(
        uint256 moduleId,
        uint256[] calldata keyIndices,
        uint256[] calldata,
        bytes[] calldata,
        uint256[] calldata topUpLimits
    ) external {
        uint256 first;
        if (topUpLimits.length != 0) first = topUpLimits[0];
        log.push(address(this), 0, "topUp", moduleId, first);
        unchecked {
            ++topUpCalls;
        }
        if (failTopUp) revert("router fail");
        keyIndices;
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
