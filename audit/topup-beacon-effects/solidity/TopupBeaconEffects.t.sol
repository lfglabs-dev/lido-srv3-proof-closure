// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "pinned-lido/contracts/0.6.11/deposit_contract.sol";

interface BeaconTestVm {
    struct Log { bytes32[] topics; bytes data; address emitter; }
    function deal(address account, uint256 balance) external;
    function load(address account, bytes32 slot) external view returns (bytes32);
    function store(address account, bytes32 slot, bytes32 value) external;
    function recordLogs() external;
    function getRecordedLogs() external returns (Log[] memory);
}

contract TopupBeaconEffectsTest {
    BeaconTestVm constant vm = BeaconTestVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    DepositContract target;

    function setUp() public { target = new DepositContract(); }

    function little(uint64 value) internal pure returns (bytes memory out) {
        out = new bytes(8);
        for (uint256 i; i < 8; i++) out[i] = bytes1(uint8(value / (uint256(1) << (8 * i))));
    }

    // Independent four-field DepositData merkleization for the TOPUP zero signature.
    function root(bytes memory pk, bytes memory wc, uint64 amountGwei) internal pure returns (bytes32) {
        bytes32 zeroPair = sha256(abi.encodePacked(bytes32(0), bytes32(0)));
        bytes32[4] memory nodes = [sha256(abi.encodePacked(pk, bytes16(0))), bytes32(0),
            bytes32(0), sha256(abi.encodePacked(zeroPair, zeroPair))];
        assembly { mstore(add(nodes, 32), mload(add(wc, 32))) }
        bytes memory amount = little(amountGwei);
        bytes32 chunk;
        assembly { chunk := mload(add(amount, 32)) }
        nodes[2] = chunk;
        for (uint256 count = 4; count > 1; count /= 2)
            for (uint256 i; i < count / 2; i++) nodes[i] = sha256(abi.encodePacked(nodes[2*i], nodes[2*i+1]));
        return nodes[0];
    }

    function key(bytes32 seed) internal pure returns (bytes memory) {
        return abi.encodePacked(seed, bytes16(type(uint128).max));
    }

    function invoke(bytes memory pk, bytes memory wc, uint256 value, bytes32 supplied) internal returns (bool, bytes memory) {
        return address(target).call{value:value}(abi.encodeWithSelector(target.deposit.selector, pk, wc, new bytes(96), supplied));
    }

    function testFuzz_valueCountBranchAndEvent(uint32 countSeed, uint64 amountSeed, bytes32 seed, bytes32 wcWord, uint128 oldBalance) public {
        checkDeposit(countSeed, amountSeed, seed, wcWord, oldBalance);
    }

    function test_allCarryHeightsAndAmountEdges() public {
        for (uint256 height; height < 32; height++)
            checkDeposit(uint32((uint256(1) << height) - 1), height % 2 == 0 ? 0 : type(uint64).max - 10**9,
                bytes32(height), bytes32(~height), uint128(height));
        checkDeposit(type(uint32).max - 1, type(uint64).max - 10**9, bytes32(uint256(42)), bytes32(uint256(43)), type(uint128).max);
    }

    function checkDeposit(uint32 countSeed, uint64 amountSeed, bytes32 seed, bytes32 wcWord, uint128 oldBalance) internal {
        uint256 beforeCount = uint256(countSeed) % (2**32 - 1);
        uint64 amountGwei = uint64(10**9 + uint256(amountSeed) % (uint256(type(uint64).max) - 10**9 + 1));
        uint256 value = uint256(amountGwei) * 10**9;
        bytes memory pk = key(seed);
        bytes memory wc = abi.encodePacked(wcWord);
        bytes32 node = root(pk, wc, amountGwei);
        vm.store(address(target), bytes32(uint256(32)), bytes32(beforeCount));
        // Arbitrary branch-state fixture, not a claim that this state is reachable.
        bytes32[32] memory oldBranch;
        for (uint256 i; i < 32; i++) {
            oldBranch[i] = keccak256(abi.encode(seed, i));
            vm.store(address(target), bytes32(i), oldBranch[i]);
        }
        uint256 size = beforeCount + 1;
        uint256 changed;
        while (size % 2 == 0) { node = sha256(abi.encodePacked(oldBranch[changed], node)); changed++; size /= 2; }
        vm.deal(address(target), oldBalance);
        vm.deal(address(this), value + 17);
        vm.recordLogs();
        (bool success,) = invoke(pk, wc, value, root(pk, wc, amountGwei));
        require(success, "source rejected admitted deposit");
        require(address(this).balance == 17 && address(target).balance == uint256(oldBalance) + value, "actual ETH transfer");
        require(uint256(vm.load(address(target), bytes32(uint256(32)))) == beforeCount + 1, "count increment");
        require(keccak256(target.get_deposit_count()) == keccak256(little(uint64(beforeCount + 1))), "count encoding");
        for (uint256 i; i < 32; i++) require(vm.load(address(target), bytes32(i)) == (i == changed ? node : oldBranch[i]), "branch update");
        BeaconTestVm.Log[] memory logs = vm.getRecordedLogs();
        require(logs.length == 1 && logs[0].emitter == address(target), "event count and emitter");
        require(logs[0].topics.length == 1 && logs[0].topics[0] == keccak256("DepositEvent(bytes,bytes,bytes,bytes,bytes)"), "event topic");
        require(keccak256(logs[0].data) == keccak256(abi.encode(pk, wc, little(amountGwei), new bytes(96), little(uint64(beforeCount)))), "event ABI fields");
    }

    function test_guardOrderAndRejectionRestore() public {
        bytes memory pk = key(bytes32(uint256(3)));
        bytes memory wc = abi.encodePacked(bytes32(uint256(4)));
        vm.deal(address(this), 10 ether);
        vm.deal(address(target), 19);
        (bool ok, bytes memory reason) = invoke(new bytes(47), wc, 1, bytes32(0));
        require(!ok && keccak256(reason) == keccak256(abi.encodeWithSignature("Error(string)", "DepositContract: invalid pubkey length")), "length first");
        (ok, reason) = invoke(pk, wc, 1 ether + 1, bytes32(0));
        require(!ok && keccak256(reason) == keccak256(abi.encodeWithSignature("Error(string)", "DepositContract: deposit value not multiple of gwei")), "alignment before root");
        vm.store(address(target), bytes32(uint256(32)), bytes32(uint256(2**32 - 1)));
        (ok, reason) = invoke(pk, wc, 1 ether, bytes32(0));
        require(!ok && keccak256(reason) == keccak256(abi.encodeWithSignature("Error(string)", "DepositContract: reconstructed DepositData does not match supplied deposit_data_root")), "root before capacity");
        (ok, reason) = invoke(pk, wc, 1 ether, root(pk, wc, 10**9));
        require(!ok && keccak256(reason) == keccak256(abi.encodeWithSignature("Error(string)", "DepositContract: merkle tree full")), "capacity guard");
        require(address(this).balance == 10 ether && address(target).balance == 19, "rejected value restored");
        require(uint256(vm.load(address(target), bytes32(uint256(32)))) == 2**32 - 1, "rejected count unchanged");
    }

    function twoDeposits(bytes calldata pk, bytes calldata wc, bytes32 correctRoot) external payable {
        require(msg.sender == address(this), "test-only entry");
        target.deposit{value:1 ether}(pk, wc, new bytes(96), correctRoot);
        target.deposit{value:1 ether}(pk, wc, new bytes(96), bytes32(uint256(correctRoot) ^ 1));
    }

    function test_lateFailureRevertsPriorCalleeEffects() public {
        bytes memory pk = key(bytes32(uint256(5)));
        bytes memory wc = abi.encodePacked(bytes32(uint256(6)));
        vm.deal(address(this), 3 ether);
        vm.deal(address(target), 23);
        (bool ok,) = address(this).call(abi.encodeWithSelector(this.twoDeposits.selector, pk, wc, root(pk, wc, 10**9)));
        require(!ok, "late mismatch admitted");
        require(address(this).balance == 3 ether && address(target).balance == 23, "outer rollback balances");
        require(vm.load(address(target), bytes32(uint256(32))) == bytes32(0), "outer rollback count");
        for (uint256 i; i < 32; i++) require(vm.load(address(target), bytes32(i)) == bytes32(0), "outer rollback branch");
    }
}
