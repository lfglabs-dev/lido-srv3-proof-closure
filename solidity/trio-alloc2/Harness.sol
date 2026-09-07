// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;
import {MinFirstAllocationStrategy} from "contracts/common/lib/MinFirstAllocationStrategy.sol";
import {Math256} from "contracts/common/lib/Math256.sol";

// The public library boundary copies the arguments through delegatecall ABI.
// Returning the caller's original array makes this distinction observable.
contract Alloc2Harness {
    function run(uint256[] memory buckets, uint256[] memory capacities, uint256 demand)
        external pure returns (uint256 amount, uint256[] memory finalBuckets, uint256[] memory callerBuckets)
    {
        (amount, finalBuckets) = MinFirstAllocationStrategy.allocate(buckets, capacities, demand);
        callerBuckets = buckets;
    }

    function step(uint256[] memory buckets, uint256[] memory capacities, uint256 demand)
        external pure returns (uint256 amount, uint256[] memory finalBuckets)
    {
        amount = MinFirstAllocationStrategy.allocateToBestCandidate(buckets, capacities, demand);
        finalBuckets = buckets;
    }

    function ceil(uint256 a, uint256 b) external pure returns (uint256) {
        return Math256.ceilDiv(a, b);
    }
}
