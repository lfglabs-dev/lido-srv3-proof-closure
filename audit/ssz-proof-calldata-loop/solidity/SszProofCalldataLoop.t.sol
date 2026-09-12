// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {SszCalldataSourceHarness} from "../../ssz-proof-calldata-step/solidity/SszProofCalldataStep.t.sol";

contract SszProofCalldataLoopTest {
    SszCalldataSourceHarness h = new SszCalldataSourceHarness();

    // Independent complete heap: construct every tree node, then extract a path.
    // The root is not computed by folding only the selected source proof.
    function tree(uint256 depth, bytes32 seed, uint256 position) internal pure returns
        (bytes32[] memory nodes, bytes32[] memory proof, uint256 index)
    {
        uint256 width = 1 << depth;
        nodes = new bytes32[](2 * width);
        for (uint256 i; i < width; ++i) nodes[width+i] = keccak256(abi.encode(seed,i));
        for (uint256 i = width-1; i > 0; --i) nodes[i] = sha256(abi.encodePacked(nodes[2*i],nodes[2*i+1]));
        index = width + position % width;
        proof = new bytes32[](depth);
        uint256 at = index;
        for (uint256 i; i < depth; ++i) { proof[i] = nodes[at ^ 1]; at /= 2; }
    }

    function accept(bytes memory prefix, bytes32[] memory proof, bytes32 root,
        bytes32 leaf, uint256 rawIndex, bytes32 rightRoot) internal view
    {
        (bytes32 out0, bytes32 out1, uint256 offset, uint256 ptr0, uint256 ptr1) =
            h.run(prefix,proof,root,leaf,rawIndex,bytes32(type(uint256).max),keccak256("dirty"));
        require(out0 == root && out1 == rightRoot, "actual accumulated root/right scratch");
        require(ptr0 == ptr1, "word64 preserved");
        require(offset == 4 + 7*32 + 32 + ((prefix.length+31)/32)*32 + 32, "compiler proof offset");
    }

    function reject(bytes32[] memory proof, bytes32 root, bytes32 leaf, uint256 rawIndex,
        bytes4 selector) internal view
    {
        (bool ok, bytes memory data) = address(h).staticcall(abi.encodeCall(h.run,
            (hex"abcdef",proof,root,leaf,rawIndex,bytes32(uint256(7)),bytes32(uint256(9)))));
        require(!ok && data.length == 4 && bytes4(data) == selector, "source error priority");
    }

    function testFuzz_fullHeapPath(uint8 depthSeed, bytes32 seed, uint16 position,
        uint8 metadata, uint8 prefixSeed) public view
    {
        uint256 depth = 1 + uint256(depthSeed) % 8;
        (bytes32[] memory nodes, bytes32[] memory proof, uint256 index) = tree(depth,seed,position);
        accept(new bytes(uint256(prefixSeed)),proof,nodes[1],nodes[index],index*256+metadata,nodes[3]);
    }

    function test_everySmallHeapLeafAndMetadata() public view {
        // All 256 positions of one 8-level tree; metadata paired with position.
        for (uint256 position; position < 256; ++position) {
            (bytes32[] memory nodes, bytes32[] memory proof, uint256 index) = tree(8,keccak256("all leaves"),position);
            accept(new bytes(position%65),proof,nodes[1],nodes[index],index*256+position,nodes[3]);
        }
    }

    function test_maximumDecodedDepth247() public view {
        // Complete uniform subtrees represented by their recursively computed roots.
        // This checks depth/extent; mixed-side ordering is covered by full heaps above.
        bytes32 leaf = keccak256("uniform leaf");
        bytes32 digest = leaf;
        bytes32[] memory proof = new bytes32[](247);
        for (uint256 i; i < 247; ++i) {
            proof[i] = digest;
            digest = sha256(abi.encodePacked(digest,digest));
        }
        accept(new bytes(129),proof,digest,leaf,type(uint256).max,proof[246]);
        accept(new bytes(31),proof,digest,leaf,uint256(1)<<255,proof[246]);
        bytes32[] memory extra = new bytes32[](248);
        for (uint256 i; i < 247; ++i) extra[i] = proof[i];
        extra[247] = keccak256("extra");
        reject(extra,bytes32(0),leaf,type(uint256).max,0x5849603f);
    }

    function test_lateErrorsAndMutations() public view {
        for (uint256 depth = 2; depth <= 8; ++depth) {
            (bytes32[] memory nodes, bytes32[] memory proof, uint256 index) = tree(depth,keccak256(abi.encode(depth)),depth+1);
            uint256 raw = index*256+17;
            bytes32[] memory missing = new bytes32[](depth-1);
            for (uint256 i; i < depth-1; ++i) missing[i] = proof[i];
            reject(missing,bytes32(0),nodes[index],raw,0x1b6661c3);
            bytes32[] memory extra = new bytes32[](depth+1);
            for (uint256 i; i < depth; ++i) extra[i] = proof[i];
            extra[depth] = bytes32(uint256(123));
            reject(extra,bytes32(0),nodes[index],raw,0x5849603f);
            reject(proof,nodes[1]^bytes32(uint256(1)),nodes[index],raw,0x09bde339);
            proof[depth-1] ^= bytes32(uint256(1));
            reject(proof,nodes[1],nodes[index],raw,0x09bde339);
        }
    }

    function test_emptyPriorityAndInsufficientCallBudget() public view {
        bytes32[] memory empty = new bytes32[](0);
        reject(empty,bytes32(0),bytes32(uint256(1)),511,0x09bde339);
        (bytes32[] memory nodes, bytes32[] memory proof, uint256 index) = tree(8,keccak256("gas"),37);
        bytes memory payload = abi.encodeCall(h.run,
            (hex"00",proof,nodes[1],nodes[index],index*256,bytes32(0),bytes32(0)));
        // Whole Solidity call failure only; no claim about the exact OOG instruction.
        (bool ok,) = address(h).staticcall{gas: 2000}(payload);
        require(!ok,"insufficient whole-call gas accepted");
    }
}
