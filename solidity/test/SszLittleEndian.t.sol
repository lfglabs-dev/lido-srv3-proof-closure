// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

import {SSZ} from "../../lido-core/contracts/common/lib/SSZ.sol";

/// Execute the pinned library against an independent byte-by-byte specification.
/// The Lean companion proves the literal mask/shift transcription universally;
/// these tests additionally exercise the imported Solidity with solc 0.8.25.
contract SszLittleEndianTest {
    function octets(uint256 value) internal pure returns (bytes32 result) {
        for (uint256 i; i < 32; ++i) {
            result |= bytes32(uint256(uint8(value >> (8 * i))) << (248 - 8 * i));
        }
    }

    function testFuzz_integerMatchesOctets(uint256 value) public pure {
        require(SSZ.toLittleEndian(value) == octets(value), "integer octets");
    }

    function testFuzz_uint64ZeroPadding(uint64 value) public pure {
        bytes32 result = SSZ.toLittleEndian(uint256(value));
        require(result == octets(value), "uint64 octets");
        require(uint256(result) & type(uint192).max == 0, "uint64 padding");
    }

    function test_booleanBytePosition() public pure {
        require(SSZ.toLittleEndian(false) == bytes32(0), "false");
        require(SSZ.toLittleEndian(true) == bytes32(uint256(1) << 248), "true");
    }

    function test_everyInputBit() public pure {
        for (uint256 i; i < 256; ++i) {
            uint256 value = uint256(1) << i;
            require(SSZ.toLittleEndian(value) == octets(value), "bit position");
        }
    }
}
