// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

import {TopUpGateway} from "../../../lido-core/contracts/0.8.25/TopUpGateway.sol";
import {GIndex} from "../../../lido-core/contracts/common/lib/GIndex.sol";
import {ValidatorWitness} from "../../../lido-core/contracts/common/interfaces/ValidatorWitness.sol";

/// Exercise the inherited pinned evaluator, without replacing its body.
/// Typed storage is seeded directly; authorization and initialization are not tested.
contract TopupWeiBoundsHarness is TopUpGateway {
    constructor() TopUpGateway(address(1), GIndex.wrap(bytes32(0)), GIndex.wrap(bytes32(0)), 0, 32) {}

    function evaluate(ValidatorWitness calldata v, uint256 pending, uint64 target, uint64 minimum)
        external returns (uint256)
    {
        _gatewayStorage().targetBalanceGwei = target;
        _gatewayStorage().minTopUpGwei = minimum;
        return _evaluateTopUpLimit(v, pending);
    }
}

contract TopupWeiBoundsTest {
    TopupWeiBoundsHarness private harness;
    function setUp() public { harness = new TopupWeiBoundsHarness(); }

    function testFuzz_pinnedEvaluatorAndConversion(
        uint64 effective, uint256 pending, uint64 exitEpoch, bool slashed,
        uint64 target, uint64 minimum
    ) public {
        ValidatorWitness memory v;
        v.effectiveBalance = effective;
        v.exitEpoch = exitEpoch;
        v.slashed = slashed;
        (bool ok, bytes memory result) = address(harness).call(
            abi.encodeCall(harness.evaluate, (v, pending, target, minimum))
        );
        bool filtered = exitEpoch != type(uint64).max || slashed;
        bool overflow = pending > type(uint256).max - effective;
        if (!filtered && overflow) {
            require(!ok, "overflow accepted");
            require(keccak256(result) == keccak256(abi.encodeWithSignature("Panic(uint256)", 0x11)), "overflow error");
            return;
        }
        require(ok, "unexpected failure");
        uint256 expected;
        if (!filtered && pending < target && effective < target - pending) {
            uint256 gap = target - pending - effective;
            if (gap >= minimum) expected = gap;
        }
        uint256 limit = abi.decode(result, (uint256));
        require(limit == expected, "mathematical gap");
        require(limit <= target, "target bound");
        uint256 weiLimit;
        unchecked { weiLimit = limit * 1 gwei; }
        require(weiLimit / 1 gwei == limit, "conversion loses value");
    }

    function test_activeMaximumTarget() public {
        ValidatorWitness memory v;
        v.exitEpoch = type(uint64).max;
        uint256 limit = harness.evaluate(v, 0, type(uint64).max, 1);
        require(limit == type(uint64).max, "max target");
        require(limit * 1 gwei / 1 gwei == limit, "max conversion");
    }

    function testFuzz_activeEvaluatorAndConversion(
        uint64 effective, uint256 pending, uint64 target, uint64 minimum
    ) public {
        testFuzz_pinnedEvaluatorAndConversion(effective, pending, type(uint64).max, false, target, minimum);
    }

    function testFuzz_successfulGap(uint64 target, uint64 effectiveSeed, uint64 pendingSeed) public {
        uint64 effective = uint64(uint256(effectiveSeed) % (uint256(target) + 1));
        uint256 pending = uint256(pendingSeed) % (uint256(target) - effective + 1);
        testFuzz_pinnedEvaluatorAndConversion(effective, pending, type(uint64).max, false, target, 1);
    }

    function test_checkedOverflowAndEarlyFilter() public {
        ValidatorWitness memory v;
        v.effectiveBalance = 1;
        v.exitEpoch = type(uint64).max;
        (bool ok, bytes memory result) = address(harness).call(
            abi.encodeCall(harness.evaluate, (v, type(uint256).max, 1, 1))
        );
        require(!ok && keccak256(result) == keccak256(abi.encodeWithSignature("Panic(uint256)", 0x11)), "checked addition");
        v.slashed = true;
        require(harness.evaluate(v, type(uint256).max, 1, 1) == 0, "filter before addition");
    }
}
