// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

/// Nested read and rejected mutation from a summary call executing in static context.
contract CallbackModule {
    address immutable router;
    uint256 immutable slot;
    uint256 immutable expectedRoot;
    constructor(address target, uint256 testSlot, uint256 root) {
        router = target; slot = testSlot; expectedRoot = root;
    }
    fallback() external {
        (bool readOk, bytes memory root) = router.staticcall(abi.encodeWithSignature("routerSlot()"));
        require(readOk && abi.decode(root, (uint256)) == expectedRoot, "callback read");
        // Zero-value CALL inherits static context, so this attempted SSTORE fails.
        (bool wrote,) = router.call{gas: 100000}(abi.encodeWithSignature("writeSlot(uint256,uint256)", slot, 99));
        require(!wrote, "static mutation committed");
        bytes memory result = abi.encode(uint256(0), uint256(1), uint256(2));
        assembly { return(add(result, 32), mload(result)) }
    }
}
