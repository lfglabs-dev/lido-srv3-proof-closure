// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {CLValidatorVerifier} from "../../lido-core/contracts/0.8.25/CLValidatorVerifier.sol";
import {GIndex, pack, concat, fls, IndexOutOfRange} from "../../lido-core/contracts/common/lib/GIndex.sol";

contract WrapperIndexHarness is CLValidatorVerifier {
    constructor(uint256 previous, uint256 current, uint64 pivot)
        CLValidatorVerifier(pack(previous, 40), pack(current, 40), pivot) {}

    function indices(uint256 offset, uint64 slot) external view returns (uint256, uint256) {
        GIndex relative = _getValidatorGI(offset, slot);
        return (relative.index(), concat(GI_STATE_ROOT, relative).index());
    }

    function checkSlot(bytes32[] calldata proof, uint64 slot, uint64 proposer) external view {
        _verifySlot(proof, slot, proposer);
    }

    function concatenate(uint248 a, uint248 b, uint8 power) external pure returns (uint256, uint8) {
        GIndex result = concat(pack(a, 0), pack(b, power));
        return (result.index(), result.pow());
    }

    function lastBit(uint256 n) external pure returns (uint256) { return fls(n); }
}

contract SszWrapperIndexTest {
    uint256 constant WIDTH = 1 << 40;
    WrapperIndexHarness pinned = new WrapperIndexHarness(150 * WIDTH, 150 * WIDTH, 100);
    WrapperIndexHarness distinct = new WrapperIndexHarness(150 * WIDTH, 151 * WIDTH, 100);

    // Independent byte serialization; does not call the SSZ helper under test.
    function chunk(uint64 value) internal pure returns (bytes32 result) {
        for (uint256 i; i < 8; ++i) result |= bytes32(uint256(uint8(value >> (8 * i))) << (248 - 8 * i));
    }

    function testFuzz_pinnedHeaderIndex(uint40 offset, uint64 slot) public view {
        (uint256 relative, uint256 complete) = pinned.indices(offset, slot);
        require(relative == 150 * WIDTH + offset, "state index");
        require(complete == 1430 * WIDTH + offset, "header index");
        uint256 depth;
        for (uint256 n = complete; n > 1; n /= 2) ++depth;
        require(depth == 50, "branch depth");
        require(complete != relative, "header prefix required");
    }

    function testFuzz_distinctForkBoundary(uint40 offset) public view {
        (uint256 beforeIndex, uint256 beforeFull) = distinct.indices(offset, 99);
        (uint256 atIndex, uint256 atFull) = distinct.indices(offset, 100);
        require(beforeIndex == 150 * WIDTH + offset && beforeFull == 1430 * WIDTH + offset, "previous");
        require(atIndex == 151 * WIDTH + offset && atFull == 1431 * WIDTH + offset, "current at pivot");
    }

    function test_outOfRangeOffsets() public view {
        uint256[3] memory offsets = [WIDTH, WIDTH + 1, type(uint256).max];
        for (uint256 i; i < offsets.length; ++i) {
            try pinned.indices(offsets[i], 100) { revert("unexpected admission"); }
            catch (bytes memory reason) { require(keccak256(reason) == keccak256(abi.encodeWithSelector(IndexOutOfRange.selector)), "range error"); }
        }
    }

    function testFuzz_slotSiblingPosition(uint64 slot, uint64 proposer) public view {
        bytes32[] memory proof = new bytes32[](50);
        bytes32 expected = sha256(abi.encodePacked(chunk(slot), chunk(proposer)));
        proof[48] = expected;
        pinned.checkSlot(proof, slot, proposer);
        // Moving the correct node to either neighboring position must fail.
        proof[48] = bytes32(uint256(expected) ^ 1);
        proof[47] = expected;
        proof[49] = expected;
        try pinned.checkSlot(proof, slot, proposer) { revert("wrong sibling admitted"); }
        catch (bytes memory reason) { require(keccak256(reason) == keccak256(abi.encodeWithSelector(CLValidatorVerifier.InvalidSlot.selector)), "slot error"); }
    }

    function test_shortSlotProofPanics() public view {
        for (uint256 n; n < 2; ++n) {
            try pinned.checkSlot(new bytes32[](n), 1, 2) { revert("short proof admitted"); }
            catch (bytes memory reason) { require(keccak256(reason) == keccak256(abi.encodeWithSignature("Panic(uint256)", 0x11)), "checked subtraction"); }
        }
    }

    function testFuzz_genericPathAppend(uint248 aSeed, uint248 bSeed, uint8 aDepth, uint8 bDepth, uint8 power) public view {
        uint256 da = uint256(aDepth) % 248;
        uint256 db = uint256(bDepth) % 248;
        uint256 a = (1 << da) + uint256(aSeed) % (1 << da);
        uint256 b = (1 << db) + uint256(bSeed) % (1 << db);
        if (da + 1 + db > 248) {
            try pinned.concatenate(uint248(a), uint248(b), power) { revert("depth admitted"); }
            catch (bytes memory reason) { require(keccak256(reason) == keccak256(abi.encodeWithSelector(IndexOutOfRange.selector)), "depth error"); }
        } else {
            (uint256 result, uint8 resultPower) = pinned.concatenate(uint248(a), uint248(b), power);
            require(result == a * (1 << db) + (b - (1 << db)), "path append");
            require(resultPower == power, "right power");
        }
    }

    function testFuzz_lastBitAgainstDivision(uint256 n) public view {
        uint256 expected;
        if (n == 0) expected = 256;
        else for (uint256 rest = n; rest > 1; rest /= 2) ++expected;
        require(pinned.lastBit(n) == expected, "last set bit");
    }

    function test_lastBitBoundariesAndZeroIndices() public view {
        require(pinned.lastBit(0) == 256, "zero bit sentinel");
        for (uint256 bit; bit < 256; ++bit) require(pinned.lastBit(uint256(1) << bit) == bit, "one hot bit");
        for (uint256 side; side < 2; ++side) {
            try pinned.concatenate(uint248(side), uint248(1 - side), 40) { revert("zero index admitted"); }
            catch (bytes memory reason) { require(keccak256(reason) == keccak256(abi.encodeWithSelector(IndexOutOfRange.selector)), "zero index error"); }
        }
    }
}
