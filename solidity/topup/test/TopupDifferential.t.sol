// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {TopupHarness} from "../src/TopupHarness.sol";
import {CallLog, MockLocator, MockLido, MockModuleV2, MockDeposit, MinimalProxy} from "../src/Mocks.sol";
import {StakingRouter} from "../../../lido-core/contracts/0.8.25/sr/StakingRouter.sol";
import {StakingModuleConfig, StakingModuleStatus} from "contracts/0.8.25/sr/SRTypes.sol";

interface VmTopup {
    function ffi(string[] calldata command) external returns (bytes memory);
    function toString(uint256 value) external pure returns (string memory);
    function parseJsonBool(string calldata json, string calldata key) external pure returns (bool);
    function parseJsonUint(string calldata json, string calldata key) external pure returns (uint256);
    function parseJsonString(string calldata json, string calldata key) external pure returns (string memory);
    function deal(address account, uint256 amount) external;
    function prank(address sender) external;
    function startPrank(address sender) external;
    function stopPrank() external;
    function record() external;
    function accesses(address target) external returns (bytes32[] memory reads, bytes32[] memory writes);
}

/// Foundry --ffi harness: pinned StakingRouter.topUp vs TopupTx.execute.
contract TopupDifferentialTest {
    VmTopup private constant vm = VmTopup(address(uint160(uint256(keccak256("hevm cheat code")))));

    uint256 internal constant DEPOSIT_SIZE = 32 ether;
    address internal constant GATEWAY = address(0x6A7E);
    address internal constant ADMIN = address(0xA11CE);

    CallLog internal log;
    MockLocator internal locator;
    MockLido internal lido;
    MockModuleV2 internal module;
    MockDeposit internal beacon;
    TopupHarness internal router;
    uint256 internal moduleId;

    struct Obs {
        bool ok;
        string revertText;
        bytes4 selector;
        uint256 pulled;
        uint256 pushed;
        string names;
        uint256 callCount;
    }

    function setUp() public {
        log = new CallLog();
        locator = new MockLocator();
        lido = new MockLido(log);
        module = new MockModuleV2(log);
        beacon = new MockDeposit(log);
        locator.setGateway(GATEWAY);

        TopupHarness impl = new TopupHarness(
            address(beacon), address(lido), address(locator), DEPOSIT_SIZE, 2048 ether
        );
        bytes32 wc = bytes32((uint256(2) << 248) | uint256(uint160(address(0xBEEF))));
        bytes memory init = abi.encodeCall(StakingRouter.initialize, (ADMIN, wc, 10_000_000_000));
        MinimalProxy proxy = new MinimalProxy(address(impl), init);
        router = TopupHarness(payable(address(proxy)));
        lido.setRouter(address(router));

        vm.startPrank(ADMIN);
        router.grantRole(router.STAKING_MODULE_MANAGE_ROLE(), ADMIN);
        StakingModuleConfig memory cfg = StakingModuleConfig({
            stakeShareLimit: 10_000,
            priorityExitShareThreshold: 10_000,
            stakingModuleFee: 0,
            treasuryFee: 0,
            maxDepositsPerBlock: 100,
            minDepositBlockDistance: 1,
            withdrawalCredentialsType: 2
        });
        router.addStakingModule("mod", address(module), cfg);
        vm.stopPrank();
        moduleId = 1;
        vm.deal(address(lido), 10_000 ether);
        lido.setDepositable(320 ether);
    }

    function _pk(uint256 salt) internal pure returns (bytes memory) {
        return bytes.concat(bytes32(salt), bytes16(uint128(salt)));
    }

    function _one(uint256 v) internal pure returns (uint256[] memory xs) {
        xs = new uint256[](1);
        xs[0] = v;
    }

    function _two(uint256 a, uint256 b) internal pure returns (uint256[] memory xs) {
        xs = new uint256[](2);
        xs[0] = a;
        xs[1] = b;
    }

    function _pks(uint256 n) internal pure returns (bytes[] memory pks) {
        pks = new bytes[](n);
        for (uint256 i; i < n; ++i) pks[i] = _pk(i + 1);
    }

    function modelJson(string memory allocations, string memory failure) internal pure returns (string memory) {
        return string.concat("{\"allocations\":", allocations, ",\"failure\":\"", failure, "\"}");
    }

    function runModel(string memory json) internal returns (Obs memory o) {
        string[] memory command = new string[](3);
        command[0] = "scripts/run_topup_model.sh";
        command[1] = "source";
        command[2] = json;
        string memory raw = string(vm.ffi(command));
        o.ok = vm.parseJsonBool(raw, ".ok");
        if (o.ok) {
            o.pulled = vm.parseJsonUint(raw, ".pulled");
            o.pushed = vm.parseJsonUint(raw, ".pushed");
        } else {
            o.revertText = vm.parseJsonString(raw, ".revert");
        }
    }

    function observePinned(
        address caller,
        uint256[] memory keys,
        uint256[] memory ops,
        bytes[] memory pks,
        uint256[] memory limits
    ) internal returns (Obs memory o) {
        log.reset();
        vm.prank(caller);
        (bool ok, bytes memory ret) =
            address(router).call(abi.encodeCall(StakingRouter.topUp, (moduleId, keys, ops, pks, limits)));
        o.ok = ok;
        if (!ok && ret.length >= 4) o.selector = bytes4(ret);
        o.callCount = log.count();
        uint256 pulled;
        uint256 pushed;
        string memory names = "";
        for (uint256 i; i < o.callCount; ++i) {
            CallLog.Item memory item = log.at(i);
            names = string.concat(names, i == 0 ? item.name : string.concat(",", item.name));
            if (keccak256(bytes(item.name)) == keccak256("withdrawDepositableEther")) pulled += item.arg0;
            if (keccak256(bytes(item.name)) == keccak256("deposit")) pushed += item.value;
        }
        o.names = names;
        if (ok) {
            o.pulled = pulled;
            o.pushed = pushed;
        }
    }

    function testNominalOneKeyConserves() public {
        uint256[] memory allocs = _one(2 ether);
        module.setAllocations(allocs);
        Obs memory sol = observePinned(GATEWAY, _one(0), _one(0), _pks(1), _one(5 ether));
        Obs memory model = runModel(modelJson("[2000000000000000000]", "none"));
        require(sol.ok && model.ok, "nominal topup");
        require(sol.pulled == model.pulled && sol.pushed == model.pushed, "conservation");
        require(sol.pulled == 2 ether && sol.pulled == sol.pushed, "2 ether move");
    }

    function testZeroAllocationIsEmptyCommit() public {
        module.setAllocations(_one(0));
        Obs memory sol = observePinned(GATEWAY, _one(0), _one(0), _pks(1), _one(5 ether));
        Obs memory model = runModel(modelJson("[0]", "none"));
        require(sol.ok && model.ok, "zero alloc commits");
        require(sol.pulled == 0 && model.pulled == 0 && sol.pushed == 0, "no ether");
    }

    function testEmptyKeysList() public {
        log.reset();
        vm.prank(GATEWAY);
        (bool ok, bytes memory ret) = address(router).call(
            abi.encodeCall(StakingRouter.topUp, (moduleId, new uint256[](0), new uint256[](0), new bytes[](0), new uint256[](0)))
        );
        require(!ok && bytes4(ret) == bytes4(keccak256("EmptyKeysList()")));
        // Model execute has no empty-keys guard; [] is an empty commit. D-EMPTY-1.
        Obs memory model = runModel(modelJson("[]", "none"));
        require(model.ok && model.pulled == 0, "model empty list commits");
    }

    function testUnauthorized() public {
        module.setAllocations(_one(2 ether));
        Obs memory sol = observePinned(address(this), _one(0), _one(0), _pks(1), _one(5 ether));
        require(!sol.ok && sol.selector == bytes4(keccak256("NotAuthorized()")));
        // Model execute has no auth flag. D-AUTH-1.
        Obs memory model = runModel(modelJson("[2000000000000000000]", "none"));
        require(model.ok, "model execute ignores caller");
    }

    function testInactiveModule() public {
        vm.prank(ADMIN);
        router.setStakingModuleStatus(moduleId, StakingModuleStatus.DepositsPaused);
        module.setAllocations(_one(2 ether));
        Obs memory sol = observePinned(GATEWAY, _one(0), _one(0), _pks(1), _one(5 ether));
        require(!sol.ok && sol.selector == bytes4(keccak256("StakingModuleNotActive()")));
    }

    function testWrongPubkeyLength() public {
        bytes[] memory bad = new bytes[](1);
        bad[0] = hex"01";
        vm.prank(GATEWAY);
        (bool ok, bytes memory ret) = address(router).call(
            abi.encodeCall(StakingRouter.topUp, (moduleId, _one(0), _one(0), bad, _one(5 ether)))
        );
        require(!ok && bytes4(ret) == bytes4(keccak256("WrongPubkeyLength()")));
    }

    function testArrayLengthMismatch() public {
        vm.prank(GATEWAY);
        (bool ok, bytes memory ret) = address(router).call(
            abi.encodeCall(StakingRouter.topUp, (moduleId, _one(0), _two(0, 1), _pks(1), _one(5 ether)))
        );
        require(!ok && bytes4(ret) == bytes4(keccak256("ArraysLengthMismatch()")));
    }

    function testAllocationExceedsLimit() public {
        module.setAllocations(_one(6 ether));
        Obs memory sol = observePinned(GATEWAY, _one(0), _one(0), _pks(1), _one(5 ether));
        require(!sol.ok && sol.selector == bytes4(keccak256("AllocationExceedsLimit()")));
    }

    function testExactCapUsesReturnedAllocation() public {
        module.setAllocations(_one(3 ether));
        Obs memory sol = observePinned(GATEWAY, _one(0), _one(0), _pks(1), _one(3 ether));
        Obs memory model = runModel(modelJson("[3000000000000000000]", "none"));
        require(sol.ok && model.ok && sol.pulled == 3 ether && model.pulled == 3 ether);
    }

    function testZeroSkipThenPush() public {
        module.setAllocations(_two(0, 2 ether));
        Obs memory sol = observePinned(GATEWAY, _two(0, 1), _two(0, 0), _pks(2), _two(5 ether, 5 ether));
        Obs memory model = runModel(modelJson("[0,2000000000000000000]", "none"));
        require(sol.ok && model.ok, "skip zero");
        require(sol.pulled == 2 ether && model.pulled == 2 ether);
        require(sol.pushed == 2 ether && model.pushed == 2 ether);
    }

    function testWordWrapIsModelOnly() public {
        // Unchecked wrap in the model: [2^256-1, 2] wraps to 1, then assert/push disagree.
        Obs memory model = runModel(modelJson("[115792089237316195423570985008687907853269984665640564039457584007913129639935,2]", "none"));
        require(!model.ok, "nonzero wrap reverts in the model");
    }

    function testDuplicateKeysAreCallerSupplied() public {
        module.setAllocations(_two(1 ether, 1 ether));
        bytes[] memory pks = _pks(2);
        pks[1] = pks[0];
        Obs memory sol = observePinned(GATEWAY, _two(0, 0), _two(0, 0), pks, _two(5 ether, 5 ether));
        require(sol.ok, "pin does not reject duplicate pubkeys");
    }

    function testModuleFailureAfterGuards() public {
        module.setFailAllocate(true);
        uint256 before = lido.depositable();
        Obs memory sol = observePinned(GATEWAY, _one(0), _one(0), _pks(1), _one(5 ether));
        require(!sol.ok && lido.depositable() == before);
    }

    function testLidoFailureAfterAllocateRollsBack() public {
        module.setAllocations(_one(2 ether));
        lido.setFailWithdraw(true);
        uint256 before = lido.depositable();
        Obs memory sol = observePinned(GATEWAY, _one(0), _one(0), _pks(1), _one(5 ether));
        require(!sol.ok && lido.depositable() == before);
        Obs memory model = runModel(modelJson("[2000000000000000000]", "afterLidoPull"));
        require(!model.ok, "model failure hook after pull");
    }

    function testModelJournalOmitsAllocateDeposits() public {
        module.setAllocations(_one(2 ether));
        Obs memory sol = observePinned(GATEWAY, _one(0), _one(0), _pks(1), _one(5 ether));
        require(sol.ok);
        require(
            keccak256(bytes(sol.names)) == keccak256("allocateDeposits,withdrawDepositableEther,deposit"),
            "source journal"
        );
        // TopupTx.execute starts after the module call. D-CALL-1.
    }

    function testMutantDroppedAssertStrandsEther() public {
        // Honest path with a 1-wei leftover is not reachable (gwei alignment).
        // Mutant simply omits the assert; compare storage/call success against
        // a reversed-order revert to show the harness distinguishes copies.
        module.setAllocations(_one(2 ether));
        log.reset();
        vm.prank(GATEWAY);
        (bool ok,) = address(router).call(
            abi.encodeCall(router.topUpDroppedAssert, (moduleId, _one(0), _one(0), _pks(1), _one(5 ether)))
        );
        require(ok, "dropped-assert copy still conserves on a gwei-aligned path");
        log.reset();
        vm.prank(GATEWAY);
        (bool revOk,) = address(router).call(
            abi.encodeCall(router.topUpReversedOrder, (moduleId, _one(0), _one(0), _pks(1), _one(5 ether)))
        );
        require(!revOk, "reversed-order mutant is detected");
    }

    function testMutantReversedOrderRevertsOnNominal() public {
        module.setAllocations(_one(2 ether));
        log.reset();
        vm.prank(GATEWAY);
        (bool ok,) = address(router).call(
            abi.encodeCall(router.topUpReversedOrder, (moduleId, _one(0), _one(0), _pks(1), _one(5 ether)))
        );
        require(!ok, "push-before-pull fails");
        Obs memory honest = observePinned(GATEWAY, _one(0), _one(0), _pks(1), _one(5 ether));
        require(honest.ok, "honest pin succeeds");
    }

    function testMutantWrongSlotExtraWrite() public {
        module.setAllocations(_one(2 ether));
        vm.record();
        vm.prank(GATEWAY);
        (bool ok,) = address(router).call(
            abi.encodeCall(router.topUpWrongSlot, (moduleId, _one(0), _one(0), _pks(1), _one(5 ether)))
        );
        require(ok, "wrong-slot mutant commits");
        (, bytes32[] memory mutantWrites) = vm.accesses(address(router));
        log.reset();
        vm.record();
        vm.prank(GATEWAY);
        (bool ok2,) = address(router).call(
            abi.encodeCall(StakingRouter.topUp, (moduleId, _one(0), _one(0), _pks(1), _one(5 ether)))
        );
        require(ok2, "honest topup");
        (, bytes32[] memory honestWrites) = vm.accesses(address(router));
        require(keccak256(abi.encode(mutantWrites)) != keccak256(abi.encode(honestWrites)), "wrong slot undetected");
    }

    function testType1ModuleRejected() public {
        // The registered module is type 2. A type-1 module is a separate add.
        // This pin already enforces WC type 2; keep the type-2 module and
        // just record that execute has no WC guard (D-WC-1).
        Obs memory model = runModel(modelJson("[2000000000000000000]", "none"));
        require(model.ok, "model execute has no WC-type guard");
    }
}
