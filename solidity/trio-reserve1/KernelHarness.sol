pragma solidity 0.4.24;
import "@aragon/os/contracts/kernel/Kernel.sol";

// Only raw fixture setup is added. acl(), getApp(), and hasPermission() are
// inherited unchanged from the pinned Aragon dependency used by Lido.
contract KernelHarness is Kernel {
    constructor() Kernel(false) public {}
    function fixtureStore(bytes32 slot, uint256 value) external {
        assembly { sstore(slot, value) }
    }
}
