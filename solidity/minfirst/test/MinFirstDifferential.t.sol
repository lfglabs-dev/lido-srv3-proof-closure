// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {MinFirstAllocationStrategy} from "../../../lido-core/contracts/common/lib/MinFirstAllocationStrategy.sol";

interface VmMinFirst {
    function ffi(string[] calldata command) external returns (bytes memory);
    function toString(uint256 value) external pure returns (string memory);
}

/// Executes the imported pinned Solidity and the Verity model under the Lean runtime for
/// identical decoded inputs. No source-algorithm copy or fixture oracle.
contract MinFirstDifferentialTest {
    VmMinFirst private constant vm = VmMinFirst(address(uint160(uint256(keccak256("hevm cheat code")))));

    function source(uint256[] memory buckets, uint256[] memory capacities, uint256 demand)
        external pure returns (uint256, uint256[] memory)
    {
        return MinFirstAllocationStrategy.allocate(buckets, capacities, demand);
    }

    function csv(uint256[] memory words) internal pure returns (string memory out) {
        for (uint256 i; i < words.length; ++i) {
            out = string.concat(out, i == 0 ? "" : ",", vm.toString(words[i]));
        }
    }

    function model(string memory mode, uint256[] memory b, uint256[] memory c, uint256 demand)
        internal returns (bytes memory)
    {
        string[] memory command = new string[](5);
        command[0] = "scripts/run_minfirst_model.sh";
        command[1] = mode;
        command[2] = vm.toString(demand);
        command[3] = csv(b);
        command[4] = csv(c);
        return vm.ffi(command);
    }

    /// Normalization: (success, allocated-or-panic-code, returned-buckets).
    /// Exact ABI error encoding is checked for the source panic then normalized
    /// to its code; legacy model strings are deliberately a distinct sentinel.
    function sourceObservation(uint256[] memory b, uint256[] memory c, uint256 demand)
        internal view returns (bytes memory)
    {
        (bool ok, bytes memory data) = address(this).staticcall(abi.encodeCall(this.source, (b, c, demand)));
        if (ok) {
            (uint256 total, uint256[] memory afterBuckets) = abi.decode(data, (uint256, uint256[]));
            return abi.encode(true, total, afterBuckets);
        }
        require(data.length == 36 && bytes4(data) == bytes4(0x4e487b71), "unexpected source error");
        uint256 code;
        assembly ("memory-safe") { code := mload(add(data, 36)) }
        return abi.encode(false, code, new uint256[](0));
    }

    function compare(uint256[] memory b, uint256[] memory c, uint256 demand) internal {
        require(keccak256(sourceObservation(b, c, demand)) == keccak256(model("source", b, c, demand)),
            "Solidity/Verity mismatch");
    }

    function one(uint256 a) internal pure returns (uint256[] memory x) {
        x = new uint256[](1); x[0] = a;
    }

    function two(uint256 a, uint256 b) internal pure returns (uint256[] memory x) {
        x = new uint256[](2); x[0] = a; x[1] = b;
    }

    function testEmptyAndZeroBoundaries() public {
        compare(new uint256[](0), new uint256[](0), 0);
        compare(new uint256[](0), new uint256[](0), 7);
        compare(new uint256[](0), one(10), 7);
        compare(one(7), new uint256[](0), 0);
        compare(one(7), new uint256[](0), 1);
        compare(two(0, 1), one(10), 1);
    }

    function testSurplusCapacitiesAndExactCaps() public {
        compare(one(0), two(5, 0), 3);
        compare(one(0), one(5), 5);
        compare(one(0), one(5), 6);
        compare(one(9), one(5), 10);
        compare(two(0, 0), two(3, 3), 5);
        compare(two(2, 4), two(5, 7), 6);
    }

    function testWordBoundaries() public {
        compare(one(0), one(type(uint256).max), type(uint256).max);
        compare(one(type(uint256).max - 1), one(type(uint256).max), 2);
        compare(two(0, 0), two(type(uint256).max, type(uint256).max), type(uint256).max);
        compare(one(type(uint256).max), one(type(uint256).max), 1);
    }

    function testEagerLengthGuardMutationProducesMismatch() public {
        uint256[] memory b = one(7);
        uint256[] memory c = new uint256[](0);
        require(keccak256(sourceObservation(b, c, 0)) != keccak256(model("legacy", b, c, 0)),
            "zero-demand guard mutation escaped");
        b = one(0); c = two(5, 0);
        require(keccak256(sourceObservation(b, c, 3)) != keccak256(model("legacy", b, c, 3)),
            "surplus-capacity guard mutation escaped");
    }
}
