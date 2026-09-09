// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SSZ} from "../../lido-core/contracts/common/lib/SSZ.sol";
import {pack} from "../../lido-core/contracts/common/lib/GIndex.sol";

contract SszProofFoldHarness {
    function verify(bytes32[] calldata branch, bytes32 root, bytes32 leaf, uint248 index) external view {
        SSZ.verifyProof(branch, root, leaf, pack(index, 0));
    }
}

contract SszProofFoldTest {
    SszProofFoldHarness harness = new SszProofFoldHarness();

    // Reference uses bits of the ORIGINAL index, standard ABI byte concatenation,
    // and high-level SHA256. No source assembly, scratch memory, or shifted index.
    function referenceRoot(bytes32[] memory branch, bytes32 leaf, uint248 index) internal pure returns (bytes32) {
        for (uint256 level; level < branch.length; ++level) {
            bool right = (uint256(index) / (uint256(1) << level)) % 2 == 1;
            leaf = right ? sha256(abi.encodePacked(branch[level], leaf)) : sha256(abi.encodePacked(leaf, branch[level]));
        }
        return leaf;
    }

    function siblings(uint256 depth, bytes32 seed) internal pure returns (bytes32[] memory branch) {
        branch = new bytes32[](depth);
        for (uint256 level; level < depth; ++level) branch[level] = keccak256(abi.encode(seed, level));
    }

    function rejects(bytes32[] memory branch, bytes32 root, bytes32 leaf, uint248 index, bytes4 errorSelector) internal view {
        try harness.verify(branch, root, leaf, index) { revert("unexpected acceptance"); }
        catch (bytes memory reason) {
            require(keccak256(reason) == keccak256(abi.encodeWithSelector(errorSelector)), "wrong failure");
        }
    }

    function testFuzz_validAndWrongRoot(uint8 depthSeed, uint248 pathSeed, bytes32 leaf, bytes32 siblingSeed) public view {
        // uint248 generalized indices derive depth <=247; no arbitrary proof cap.
        uint256 depth = 1 + uint256(depthSeed) % 247;
        uint256 width = uint256(1) << depth;
        uint248 index = uint248(width + uint256(pathSeed) % width);
        bytes32[] memory branch = siblings(depth, siblingSeed);
        bytes32 root = referenceRoot(branch, leaf, index);
        harness.verify(branch, root, leaf, index);
        rejects(branch, bytes32(uint256(root) ^ 1), leaf, index, SSZ.InvalidProof.selector);
    }

    function testFuzz_missingAndExtra(uint8 depthSeed, uint248 pathSeed, bytes32 seed) public view {
        uint256 depth = 2 + uint256(depthSeed) % 246;
        uint256 width = uint256(1) << depth;
        uint248 index = uint248(width + uint256(pathSeed) % width);
        // Deliberately wrong root: structural errors must win over root comparison.
        rejects(siblings(depth - 1, seed), bytes32(0), seed, index, SSZ.BranchHasMissingItem.selector);
        rejects(siblings(depth + 1, seed), bytes32(0), seed, index, SSZ.BranchHasExtraItem.selector);
    }

    function test_emptyAndRootIndices() public view {
        bytes32 leaf = bytes32(uint256(123));
        bytes32[] memory empty = new bytes32[](0);
        rejects(empty, leaf, leaf, 0, SSZ.InvalidProof.selector);
        rejects(empty, leaf, leaf, 1, SSZ.InvalidProof.selector);
        rejects(empty, leaf, leaf, type(uint248).max, SSZ.InvalidProof.selector);
        bytes32[] memory branch = siblings(1, leaf);
        rejects(branch, leaf, leaf, 0, SSZ.BranchHasExtraItem.selector);
        rejects(branch, leaf, leaf, 1, SSZ.BranchHasExtraItem.selector);
    }

    function test_maximumDepthBothEdges() public view {
        bytes32 leaf = bytes32(uint256(456));
        bytes32[] memory branch = siblings(247, leaf);
        uint248 left = uint248(uint256(1) << 247);
        harness.verify(branch, referenceRoot(branch, leaf, left), leaf, left);
        uint248 right = type(uint248).max;
        harness.verify(branch, referenceRoot(branch, leaf, right), leaf, right);
    }

    function testFuzz_pinnedHeaderPath(uint40 offset, bytes32 leaf, bytes32 seed) public view {
        uint248 index = uint248(1430 * (uint256(1) << 40) + offset);
        bytes32[] memory branch = siblings(50, seed);
        harness.verify(branch, referenceRoot(branch, leaf, index), leaf, index);
        // Omitting the header prefix leaves a depth-47 index for a depth-50 proof.
        rejects(branch, bytes32(0), leaf, uint248(150 * (uint256(1) << 40) + offset), SSZ.BranchHasExtraItem.selector);
    }

    function test_orderAndParityMutants() public view {
        bytes32 leaf = bytes32(uint256(789));
        bytes32[] memory branch = siblings(3, leaf);
        uint248 index = 10; // leaf-to-root directions: left, right, left.
        bytes32 root = referenceRoot(branch, leaf, index);
        harness.verify(branch, root, leaf, index);
        bytes32 mutated = leaf;
        uint256 shifted = index;
        for (uint256 level; level < branch.length; ++level) {
            shifted /= 2; // Wrong: select parity AFTER advancing the index.
            mutated = shifted % 2 == 1 ? sha256(abi.encodePacked(branch[level], mutated)) : sha256(abi.encodePacked(mutated, branch[level]));
        }
        require(mutated != root, "parity mutant survived");
        rejects(branch, mutated, leaf, index, SSZ.InvalidProof.selector);
        (branch[0], branch[2]) = (branch[2], branch[0]);
        require(referenceRoot(branch, leaf, index) != root, "order mutant survived");
        rejects(branch, root, leaf, index, SSZ.InvalidProof.selector);
    }
}
