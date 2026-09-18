// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface VmSigningKeys {
    function readFile(string calldata) external view returns (string memory);
    function parseBytes(string calldata) external pure returns (bytes memory);
}
interface ISigningKeysHarness {
    function loadAt(uint256 start, uint256 count, uint256 offset, uint256 capacity)
        external view returns (bytes memory, bytes memory);
    function seed(uint256 index, uint256 first, uint256 second) external;
    function load(uint256 start, uint256 count, bool aliasBuffers)
        external view returns (bytes memory, bytes memory);
}

// Finite source controls, not a universal Lean-to-bytecode correspondence proof.
contract SigningKeysMemoryTest {
    VmSigningKeys constant vm = VmSigningKeys(address(uint160(uint256(keccak256("hevm cheat code")))));
    ISigningKeysHarness harness;
    uint256 constant FIRST = 0x1111111111111111111111111111111111111111111111111111111111111111;
    uint256 constant SECOND = 0x22222222222222222222222222222222ffffffffffffffffffffffffffffffff;

    function setUp() public {
        bytes memory code = vm.parseBytes(string.concat("0x", vm.readFile(
            "solidity/out/signing-keys-0424/SigningKeysHarness.bin")));
        address deployed;
        assembly { deployed := create(0, add(code, 32), mload(code)) }
        require(deployed != address(0), "pinned harness deployment");
        harness = ISigningKeysHarness(deployed);
        harness.seed(0, FIRST, SECOND);
    }

    function testOverlapAndPoisonedLowHalf() public view {
        (bytes memory keys, bytes memory signatures) = harness.load(0, 1, false);
        require(keys.length == 48 && signatures.length == 96, "buffer sizes");
        for (uint256 i; i < 48; ++i)
            require(keys[i] == (i < 32 ? bytes1(0x11) : bytes1(0x22)), "key overlap or shift");
        for (uint256 i; i < 96; ++i)
            require(signatures[i] == (i < 32 ? bytes1(0x33) : i < 64 ? bytes1(0x44) : bytes1(0x55)), "signature");
    }

    function testAliasedBuffersOverwriteKey() public view {
        (bytes memory keys,) = harness.load(0, 1, true);
        require(keys.length == 48, "key size");
        for (uint256 i; i < 48; ++i)
            require(keys[i] == (i < 32 ? bytes1(0x33) : bytes1(0x44)), "alias store order");
    }

    function testStartIndexWrapsAcrossIterations() public {
        harness.seed(type(uint256).max, 0, 0);
        (bytes memory keys,) = harness.load(type(uint256).max, 2, false);
        require(keys.length == 96, "two keys");
        for (uint256 i; i < 48; ++i) require(keys[i] == 0, "first key");
        for (uint256 i; i < 48; ++i)
            require(keys[48+i] == (i < 32 ? bytes1(0x11) : bytes1(0x22)), "wrapped source index");
    }
    function testNonzeroOffsetPreservesPrefixAndSuffix() public {
        harness.seed(1,
            0x6666666666666666666666666666666666666666666666666666666666666666,
            0x77777777777777777777777777777777ffffffffffffffffffffffffffffffff);
        (bytes memory keys, bytes memory signatures) = harness.loadAt(0, 2, 1, 4);
        require(keys.length == 192 && signatures.length == 384, "capacity sizes");
        for (uint256 i; i < keys.length; ++i) {
            bytes1 expected = 0xa5;
            if (i >= 48 && i < 96) expected = i < 80 ? bytes1(0x11) : bytes1(0x22);
            if (i >= 96 && i < 144) expected = i < 128 ? bytes1(0x66) : bytes1(0x77);
            require(keys[i] == expected, "key offset, stride or frame");
        }
        for (uint256 i; i < signatures.length; ++i) {
            bytes1 expected = 0xa5;
            if (i >= 96 && i < 288) {
                uint256 withinSignature = (i - 96) % 96;
                expected = withinSignature < 32 ? bytes1(0x33)
                    : withinSignature < 64 ? bytes1(0x44) : bytes1(0x55);
            }
            require(signatures[i] == expected, "signature offset, stride or frame");
        }
    }

}
