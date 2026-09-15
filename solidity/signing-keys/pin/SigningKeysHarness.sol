// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.4.24;

import "contracts/0.4.24/lib/SigningKeys.sol";

// Exercise the imported source and its actual ABI-packed key-slot producer.
contract SigningKeysHarness {
    using SigningKeys for bytes32;
    bytes32 constant POSITION = keccak256("signing-keys-memory-regression");

    function seed(uint256 index, uint256 first, uint256 second) external {
        uint256 slot = POSITION.getKeyOffset(7, index);
        assembly {
            sstore(slot, first)
            sstore(add(slot, 1), second)
            sstore(add(slot, 2), 0x3333333333333333333333333333333333333333333333333333333333333333)
            sstore(add(slot, 3), 0x4444444444444444444444444444444444444444444444444444444444444444)
            sstore(add(slot, 4), 0x5555555555555555555555555555555555555555555555555555555555555555)
        }
    }

    function load(uint256 start, uint256 count, bool aliasBuffers)
        external view returns (bytes memory keys, bytes memory signatures)
    {
        (keys, signatures) = SigningKeys.initKeysSigsBuf(count);
        for (uint256 i; i < keys.length; ++i) keys[i] = byte(0xa5);
        for (i = 0; i < signatures.length; ++i) signatures[i] = byte(0xa5);
        if (aliasBuffers) signatures = keys;
        POSITION.loadKeysSigs(7, start, count, keys, signatures, 0);
    }
}
