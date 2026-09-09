// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BLS12_381} from "contracts/common/lib/BLS.sol";

contract SszScratchEvmMemoryHarness {
    // Unmodified library execution; extra dynamic inputs vary the raw key offset.
    function actual(bytes calldata, bytes calldata key, bytes calldata, bytes32 dirty0, bytes32 dirty32, bytes32 frame)
        external view returns (bytes32 root, bytes32 after64, bytes32 after96) {
        assembly { mstore(0,dirty0) mstore(32,dirty32) mstore(64,0x200) mstore(96,frame) }
        root = BLS12_381.pubkeyRoot(key);
        assembly { after64 := mload(64) after96 := mload(96) }
    }

    // Exact two-operation source block, duplicated only to observe pre-SHA bytes.
    // This is distinct from execution of the unmodified helper above.
    function blockInput(bytes calldata, bytes calldata key, bytes calldata, bytes32 dirty0, bytes32 dirty32, bytes32 frame)
        external pure returns (bytes32 first, bytes32 second, bytes32 after64, bytes32 after96) {
        require(key.length == 48, "fixture width");
        assembly {
            mstore(0,dirty0) mstore(32,dirty32) mstore(64,0x200) mstore(96,frame)
            mstore(32,0)
            calldatacopy(0,key.offset,48)
            first := mload(0) second := mload(32) after64 := mload(64) after96 := mload(96)
        }
    }

    // Intentionally incorrect finite fixtures, never used as the source model.
    function mutant(bytes calldata, bytes calldata key, bytes calldata, uint8 mode)
        external pure returns (bytes32 first, bytes32 second) {
        assembly {
            let freeMemory := mload(64)
            mstore(0,not(0)) mstore(32,not(0))
            if iszero(eq(mode,0)) { mstore(32,0) }
            let count := 48
            if eq(mode,2) { count := 32 }
            if eq(mode,3) { count := 64 }
            let offset := key.offset
            if eq(mode,4) { offset := add(offset,1) }
            let dest := 0
            if eq(mode,5) { dest := 32 }
            calldatacopy(dest,offset,count)
            if eq(mode,1) { mstore(32,0) }
            first := mload(0) second := mload(32)
            mstore(64,freeMemory)
        }
    }
}

contract SszScratchEvmMemoryTest {
    SszScratchEvmMemoryHarness harness = new SszScratchEvmMemoryHarness();

    // Make the ABI padding immediately after the48-byte key dirty. Solidity's
    // decoder still accepts the bytes value; an incorrect64-byte copy leaks it.
    function raw(bytes memory payload) internal view returns (bytes memory reply) {
        uint256 offset;
        assembly { offset := mload(add(payload,68)) }
        uint256 padding = 4 + offset + 32 + 48;
        require(padding + 16 <= payload.length, "fixture extent");
        for (uint256 j; j < 16; j++) payload[padding+j] = 0xa5;
        bool ok;
        (ok,reply) = address(harness).staticcall(payload);
        require(ok, "raw fixture failed");
    }

    function check(bytes memory prefix, bytes memory key, bytes memory suffix,
        bytes32 dirty0, bytes32 dirty32, bytes32 frame) internal view {
        bytes memory expected = bytes.concat(key,new bytes(16));
        bytes32 e0; bytes32 e32;
        assembly { e0 := mload(add(expected,32)) e32 := mload(add(expected,64)) }
        (bytes32 a,bytes32 b,bytes32 f64,bytes32 f96) = abi.decode(raw(abi.encodeWithSelector(
            harness.blockInput.selector,prefix,key,suffix,dirty0,dirty32,frame)),(bytes32,bytes32,bytes32,bytes32));
        require(a == e0 && b == e32, "exact observed64 bytes");
        require(f64 == bytes32(uint256(0x200)) && f96 == frame, "outside scratch block frame");
        (bytes32 root,bytes32 a64,bytes32 a96) = abi.decode(raw(abi.encodeWithSelector(
            harness.actual.selector,prefix,key,suffix,dirty0,dirty32,frame)),(bytes32,bytes32,bytes32));
        require(root == sha256(expected), "actual BLS helper hash input");
        require(a64 == f64 && a96 == frame, "actual helper outside scratch frame");
    }

    function testFuzz_rawOffsetsDirtyScratchAndPadding(bytes32 first, bytes16 last,
        uint8 prefixSize,uint8 suffixSize,bytes32 dirty0,bytes32 dirty32,bytes32 frame) public view {
        bytes memory prefix = new bytes(prefixSize); bytes memory suffix = new bytes(suffixSize);
        for(uint256 i; i<prefix.length;i++) prefix[i]=bytes1(uint8(i)^0x5a);
        for(uint256 i; i<suffix.length;i++) suffix[i]=bytes1(uint8(i)^0xc3);
        check(prefix,abi.encodePacked(first,last),suffix,dirty0,dirty32,frame);
    }

    function test_all48KeyPositions() public view {
        for(uint256 i;i<48;i++) {
            bytes memory key = new bytes(48); key[i]=0x80;
            check(new bytes(i),key,hex"fefdfcfb",bytes32(type(uint256).max),bytes32(type(uint256).max),bytes32(uint256(i+1)));
        }
    }

    function test_sixMemoryMutations() public view {
        bytes memory key = new bytes(48);
        for(uint256 i;i<48;i++) key[i]=bytes1(uint8(i+1));
        bytes memory expected = bytes.concat(key,new bytes(16));
        bytes32 e0; bytes32 e32;
        assembly { e0:=mload(add(expected,32)) e32:=mload(add(expected,64)) }
        for(uint8 mode;mode<6;mode++) {
            (bytes32 a,bytes32 b)=abi.decode(raw(abi.encodeWithSelector(harness.mutant.selector,hex"1234",key,hex"aabb",mode)),(bytes32,bytes32));
            require(a!=e0 || b!=e32,"memory mutation survived");
        }
    }

    function testFuzz_actualLengthGuard(uint8 seed) public view {
        uint256 n=seed==48 ? 49 : seed;
        try harness.actual(hex"0102",new bytes(n),hex"ff",bytes32(type(uint256).max),bytes32(type(uint256).max),bytes32(uint256(7))) {
            revert("bad width accepted");
        } catch(bytes memory reason) {
            require(keccak256(reason)==keccak256(abi.encodeWithSelector(BLS12_381.InvalidPubkeyLength.selector)),"wrong BLS width error");
        }
    }
}
