// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;
import {MinFirstAllocationStrategy} from "contracts/common/lib/MinFirstAllocationStrategy.sol";

contract MemorySequence {
    // Public library calls copy across delegatecall ABI. Feed the first returned
    // buckets to the second call, while exposing the original caller arrays.
    function sequence(uint256[] memory buckets, uint256[] memory capacities, uint256 d1, uint256 d2)
        external pure returns (uint256 a1, uint256 a2, uint256[] memory first,
            uint256[] memory second, uint256[] memory original, uint256[] memory caps)
    {
        (a1, first) = MinFirstAllocationStrategy.allocate(buckets, capacities, d1);
        (a2, second) = MinFirstAllocationStrategy.allocate(first, capacities, d2);
        return (a1, a2, first, second, buckets, capacities);
    }
}
