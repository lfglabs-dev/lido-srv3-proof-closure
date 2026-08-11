// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

import {PTopup2Differential} from "../src/PTopup2Differential.sol";

contract PTopup2DifferentialTest {
    PTopup2Differential internal harness;
    uint64 internal constant FAR_FUTURE_EPOCH = type(uint64).max;

    function setUp() public { harness = new PTopup2Differential(); }

    function testFuzz_evaluateDifferential(
        uint64 effective, uint64 exitEpoch, bool slashed, uint256 pending,
        uint64 target, uint64 minimum
    ) public {
        harness.setTarget(target);
        harness.setMinimum(minimum);
        (bool okA, bytes memory a) = address(harness).call(abi.encodeCall(
            harness.referenceEvaluate, (effective, exitEpoch, slashed, pending)));
        (bool okB, bytes memory b) = address(harness).call(abi.encodeCall(
            harness.equivalentModel, (effective, exitEpoch, slashed, pending)));
        require(okA == okB, "return/revert mismatch");
        require(keccak256(a) == keccak256(b), "return-data mismatch");
    }

    function testFuzz_targetRmwPreservesNeighbors(bytes32 word0, bytes32 word1, uint64 target) public {
        harness.seedWords(word0, word1);
        harness.setTarget(target);
        (bytes32 after0, bytes32 after1) = harness.words();
        uint256 mask = ((uint256(1) << 64) - 1) << 160;
        require((uint256(after0) & ~mask) == (uint256(word0) & ~mask), "word0 neighbor clobber");
        require(uint256(after0) & mask == uint256(target) << 160, "wrong target offset");
        require(after1 == word1, "word1 clobber");
        require(harness.getTarget() == target, "target reader mismatch");
    }

    function testFuzz_minimumRmwPreservesNeighbors(bytes32 word0, bytes32 word1, uint64 minimum) public {
        harness.seedWords(word0, word1);
        harness.setMinimum(minimum);
        (bytes32 after0, bytes32 after1) = harness.words();
        uint256 mask = type(uint64).max;
        require(after0 == word0, "word0 clobber");
        require((uint256(after1) & ~mask) == (uint256(word1) & ~mask), "word1 neighbor clobber");
        require(uint256(after1) & mask == minimum, "wrong minimum offset");
        require(harness.getMinimum() == minimum, "minimum reader mismatch");
    }

    function test_nonzeroSentinelBranches() public {
        harness.seedWords(bytes32(type(uint256).max), bytes32(type(uint256).max));
        harness.setTarget(64);
        harness.setMinimum(4);
        require(harness.referenceEvaluate(1, 0, false, 0) == 0, "exiting");
        require(harness.referenceEvaluate(1, FAR_FUTURE_EPOCH, true, 0) == 0, "slashed");
        require(harness.referenceEvaluate(64, FAR_FUTURE_EPOCH, false, 0) == 0, "target reached");
        require(harness.referenceEvaluate(61, FAR_FUTURE_EPOCH, false, 0) == 0, "below min");
        require(harness.referenceEvaluate(50, FAR_FUTURE_EPOCH, false, 10) == 4, "accepted gap/pending");
    }

    function test_checkedAdditionOverflowReverts() public {
        harness.setTarget(type(uint64).max);
        (bool ok,) = address(harness).call(abi.encodeCall(
            harness.referenceEvaluate,
            (uint64(1), FAR_FUTURE_EPOCH, false, type(uint256).max)
        ));
        require(!ok, "checked uint256 addition must revert");
    }
}
