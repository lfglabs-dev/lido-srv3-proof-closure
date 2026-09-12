// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {SSZ} from "contracts/common/lib/SSZ.sol";
import {GIndex} from "contracts/common/lib/GIndex.sol";

contract SszCalldataSourceHarness {
    // A preceding dynamic argument varies the real compiler-produced proof offset.
    // The source verifier is unmodified. Only its initial scratch contents are set here.
    function run(bytes calldata, bytes32[] calldata proof, bytes32 root, bytes32 leaf,
        uint256 rawIndex, bytes32 dirty0, bytes32 dirty1)
        external view returns (bytes32 out0, bytes32 out1, uint256 proofOffset,
            uint256 freeBefore, uint256 freeAfter)
    {
        assembly {
            proofOffset := proof.offset
            freeBefore := mload(0x40)
            mstore(0, dirty0)
            mstore(32, dirty1)
        }
        SSZ.verifyProof(proof, root, leaf, GIndex.wrap(bytes32(rawIndex)));
        assembly {
            out0 := mload(0)
            out1 := mload(32)
            freeAfter := mload(0x40)
        }
    }
}

contract SszProofCalldataStepTest {
    SszCalldataSourceHarness h = new SszCalldataSourceHarness();

    // Explicit two-level tree positions, independent of the source cursor/shift loop.
    function treeRoot(bytes32 leaf, bytes32 s0, bytes32 s1, uint256 position)
        internal pure returns (bytes32 root, bytes32 upper)
    {
        bytes32 first;
        if (position == 4 || position == 6) first = sha256(abi.encodePacked(leaf, s0));
        else first = sha256(abi.encodePacked(s0, leaf));
        if (position == 4 || position == 5) {
            root = sha256(abi.encodePacked(first, s1)); upper = s1;
        } else {
            root = sha256(abi.encodePacked(s1, first)); upper = first;
        }
    }

    function check(bytes32 leaf, bytes32 s0, bytes32 s1, uint256 position,
        uint8 metadata, uint256 prefixLength) internal view
    {
        bytes32[] memory proof = new bytes32[](2); proof[0] = s0; proof[1] = s1;
        bytes memory preceding = new bytes(prefixLength);
        for (uint256 i; i < prefixLength; ++i) preceding[i] = bytes1(uint8(i ^ 0xa5));
        (bytes32 root, bytes32 upper) = treeRoot(leaf, s0, s1, position);
        (bytes32 out0, bytes32 out1, uint256 offset, uint256 beforePtr, uint256 afterPtr) =
            h.run(preceding, proof, root, leaf, position * 256 + metadata,
                bytes32(type(uint256).max), bytes32(uint256(0xdeadbeef)));
        require(out0 == root && out1 == upper, "actual ordered SHA/mload result");
        require(offset == 4 + 7 * 32 + 32 + ((prefixLength + 31) / 32) * 32 + 32,
            "actual compiler calldata offset");
        require(beforePtr == afterPtr, "word64 frame");
    }

    function testFuzz_actualCalldataOrder(bytes32 leaf, bytes32 s0, bytes32 s1,
        uint8 metadata, uint8 prefixSeed, uint8 sideSeed) public view
    {
        check(leaf, s0, s1, 4 + uint256(sideSeed) % 4, metadata, uint256(prefixSeed) % 161);
    }

    function test_allMetadataAndWordBitPositions() public view {
        for (uint256 i; i < 256; ++i) {
            check(bytes32(uint256(1) << i), keccak256("sibling zero"), keccak256("sibling one"),
                4 + i % 4, uint8(i), i % 65);
        }
    }

    function revertSelector(bytes32[] memory proof, bytes32 root, bytes32 leaf,
        uint256 rawIndex, bytes4 expected) internal view
    {
        (bool ok, bytes memory result) = address(h).staticcall(abi.encodeCall(h.run,
            (hex"010203", proof, root, leaf, rawIndex, bytes32(uint256(9)), bytes32(uint256(8)))));
        require(!ok && result.length == 4 && bytes4(result) == expected, "source revert selector/order");
    }

    function test_sourceGuardPriority() public view {
        bytes32[] memory empty = new bytes32[](0);
        // Empty proof wins over a zero/one decoded index.
        revertSelector(empty, bytes32(0), bytes32(uint256(1)), 0, 0x09bde339);
        revertSelector(empty, bytes32(0), bytes32(uint256(1)), 511, 0x09bde339);
        bytes32[] memory one = new bytes32[](1); one[0] = bytes32(uint256(2));
        revertSelector(one, bytes32(0), bytes32(uint256(1)), 0, 0x5849603f);
        revertSelector(one, bytes32(0), bytes32(uint256(1)), 511, 0x5849603f);
        // One sibling with index4 is missing an item, before the wrong-root check.
        revertSelector(one, bytes32(0), bytes32(uint256(1)), 4 * 256, 0x1b6661c3);
    }

    function test_wrongOrderAndStrideRootsRejected() public view {
        bytes32 leaf = keccak256("leaf"); bytes32 s0 = keccak256("first"); bytes32 s1 = keccak256("second");
        bytes32[] memory proof = new bytes32[](2); proof[0] = s0; proof[1] = s1;
        (bytes32 correct,) = treeRoot(leaf, s0, s1, 4);
        (bytes32 wrongSide,) = treeRoot(leaf, s0, s1, 6);
        (bytes32 wrongOrder,) = treeRoot(leaf, s1, s0, 4);
        bytes memory packed = abi.encodePacked(s0, s1, bytes32(0));
        bytes32 offByOne;
        assembly { offByOne := mload(add(packed, 65)) }
        (bytes32 wrongStride,) = treeRoot(leaf, s0, offByOne, 4);
        require(correct != wrongSide && correct != wrongOrder && correct != wrongStride, "distinct finite mutants");
        revertSelector(proof, wrongSide, leaf, 4 * 256, 0x09bde339);
        revertSelector(proof, wrongOrder, leaf, 4 * 256, 0x09bde339);
        revertSelector(proof, wrongStride, leaf, 4 * 256, 0x09bde339);
    }
}
