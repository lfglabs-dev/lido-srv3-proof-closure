// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SRStorage} from "contracts/0.8.25/sr/SRStorage.sol";
import {RouterState} from "contracts/0.8.25/sr/SRTypes.sol";
import {WithdrawalCredentials} from "contracts/common/lib/WithdrawalCredentials.sol";

interface StorageVm {
    function store(address target, bytes32 slot, bytes32 value) external;
    function load(address target, bytes32 slot) external view returns (bytes32);
}

// Real imported types expose their compiler layout; actual reads use the
// unmodified namespaced SRStorage getters, not this slot-zero fixture.
contract TopupRouterCredentialsHarness {
    RouterState private compilerLayout;

    function rootSlot() external pure returns (bytes32 slot) {
        RouterState storage state = SRStorage.getRouterState();
        assembly { slot := state.slot }
    }

    function read(uint256 moduleId) external view returns (bytes32 wc, uint8 kind, bytes32 prefixed) {
        wc = SRStorage.getRouterState().withdrawalCredentials;
        kind = SRStorage.getModuleState(moduleId).config.withdrawalCredentialsType;
        prefixed = WithdrawalCredentials.setType(wc, kind);
    }

    function writeType(uint256 moduleId, uint8 kind) external {
        SRStorage.getModuleState(moduleId).config.withdrawalCredentialsType = kind;
    }
}

contract TopupRouterCredentialsTest {
    StorageVm constant vm = StorageVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    TopupRouterCredentialsHarness harness = new TopupRouterCredentialsHarness();
    bytes32 constant ROOT = 0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000;

    function moduleSlot(uint256 id) internal pure returns (bytes32) {
        return keccak256(abi.encode(id, ROOT));
    }

    function testFuzz_readsActualNamespacedWords(uint256 id, bytes32 config, bytes32 credentials) public {
        vm.store(address(harness), bytes32(uint256(ROOT) + 4), credentials);
        vm.store(address(harness), moduleSlot(id), config);
        (bytes32 wc, uint8 kind, bytes32 prefixed) = harness.read(id);
        require(wc == credentials, "root plus four");
        require(kind == uint8(uint256(config) >> 232), "packed type at byte29");
        require(uint256(prefixed) >> 248 == kind, "credential prefix");
        require(uint248(uint256(prefixed)) == uint248(uint256(credentials)), "credential lower31 bytes");
    }

    function testFuzz_typeAssignmentPreservesAllOtherBits(uint256 id, bytes32 config, uint8 kind) public {
        vm.store(address(harness), moduleSlot(id), config);
        harness.writeType(id, kind);
        uint256 actual = uint256(vm.load(address(harness), moduleSlot(id)));
        uint256 mask = uint256(255) << 232;
        require(actual == ((uint256(config) & ~mask) | (uint256(kind) << 232)), "actual uint8 write layout");
    }

    function test_rootAndAllTypeValues() public {
        require(harness.rootSlot() == ROOT, "actual ERC7201 root");
        bytes32 independentlyComputed = bytes32(uint256(keccak256(abi.encode(uint256(keccak256(bytes("lido.StakingRouter.routerStorage"))) - 1))) & ~uint256(255));
        require(independentlyComputed == ROOT, "namespace formula");
        for (uint256 kind; kind < 256; kind++) {
            testFuzz_readsActualNamespacedWords(kind, bytes32((type(uint256).max & ~(uint256(255) << 232)) | (kind << 232)), bytes32(type(uint256).max));
        }
    }

    function test_currentWordsAreReadAgain() public {
        testFuzz_readsActualNamespacedWords(5, bytes32(uint256(1) << 232), bytes32(uint256(123)));
        testFuzz_readsActualNamespacedWords(5, bytes32(uint256(2) << 232), bytes32(uint256(456)));
        (bytes32 wc, uint8 kind, bytes32 prefixed) = harness.read(5);
        require(wc == bytes32(uint256(456)) && kind == 2 && uint248(uint256(prefixed)) == 456, "fresh storage read");
    }
}
