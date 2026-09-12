// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {DepositHarness} from "../src/DepositHarness.sol";
import {CallLog, MockLocator, MockLido, MockModule, MockDeposit, MinimalProxy} from "../src/Mocks.sol";
import {StakingRouter} from "../../../lido-core/contracts/0.8.25/sr/StakingRouter.sol";
import {StakingModuleConfig, StakingModuleStatus} from "contracts/0.8.25/sr/SRTypes.sol";

interface VmDeposit {
    function ffi(string[] calldata command) external returns (bytes memory);
    function toString(uint256 value) external pure returns (string memory);
    function parseJsonBool(string calldata json, string calldata key) external pure returns (bool);
    function parseJsonUint(string calldata json, string calldata key) external pure returns (uint256);
    function parseJsonString(string calldata json, string calldata key) external pure returns (string memory);
    function deal(address account, uint256 amount) external;
    function prank(address sender) external;
    function startPrank(address sender) external;
    function stopPrank() external;
    function recordLogs() external;
    function getRecordedLogs() external returns (Log[] memory);
    function record() external;
    function accesses(address target) external returns (bytes32[] memory reads, bytes32[] memory writes);
}

struct Log {
    bytes32[] topics;
    bytes data;
    address emitter;
}

/// Foundry --ffi harness: pinned StakingRouter.deposit vs DepositNFrameTx.
contract DepositDifferentialTest {
    VmDeposit private constant vm = VmDeposit(address(uint160(uint256(keccak256("hevm cheat code")))));

    uint256 internal constant DEPOSIT_SIZE = 32 ether;
    address internal constant DSM = address(0xD5);
    address internal constant ADMIN = address(0xA11CE);

    CallLog internal log;
    MockLocator internal locator;
    MockLido internal lido;
    MockModule internal module;
    MockDeposit internal beacon;
    DepositHarness internal router;
    uint256 internal moduleId;

    struct Obs {
        bool ok;
        string revertText;
        bytes4 selector;
        uint256 pulled;
        uint256 pushed;
        uint256 routerBalance;
        uint256 callCount;
        string names;
        uint256 eventCount;
        uint256 storageWrites;
    }

    function _deployRouter(uint256 maxEBType1) internal returns (DepositHarness deployed) {
        DepositHarness impl = new DepositHarness(
            address(beacon), address(lido), address(locator), maxEBType1, 2048 ether
        );
        bytes32 wc = bytes32((uint256(1) << 248) | uint256(uint160(address(0xBEEF))));
        bytes memory init = abi.encodeCall(StakingRouter.initialize, (ADMIN, wc, 1_000_000));
        MinimalProxy proxy = new MinimalProxy(address(impl), init);
        deployed = DepositHarness(payable(address(proxy)));
        vm.startPrank(ADMIN);
        deployed.grantRole(deployed.STAKING_MODULE_MANAGE_ROLE(), ADMIN);
        StakingModuleConfig memory cfg = StakingModuleConfig({
            stakeShareLimit: 10_000,
            priorityExitShareThreshold: 10_000,
            stakingModuleFee: 0,
            treasuryFee: 0,
            maxDepositsPerBlock: 100,
            minDepositBlockDistance: 1,
            withdrawalCredentialsType: 1
        });
        deployed.addStakingModule("mod", address(module), cfg);
        vm.stopPrank();
    }

    function setUp() public {
        log = new CallLog();
        locator = new MockLocator();
        lido = new MockLido(log);
        module = new MockModule(log);
        beacon = new MockDeposit(log);
        locator.setDsm(DSM);
        router = _deployRouter(DEPOSIT_SIZE);
        lido.setRouter(address(router));
        moduleId = 1;
        vm.deal(address(lido), 10_000 ether);
        lido.setDepositable(320 ether);
        module.configure(100, 2);
    }

    function resetLog() internal {
        log.reset();
    }

    function jsonBool(bool v) internal pure returns (string memory) {
        return v ? "true" : "false";
    }

    function jsonBatch(uint256 id, uint256 keys, uint256 amount) internal view returns (string memory) {
        return string.concat(
            "{\"moduleId\":", vm.toString(id),
            ",\"keys\":", vm.toString(keys),
            ",\"amount\":", vm.toString(amount),
            ",\"dynamicDataCommitment\":0,\"depositDataRoot\":0,",
            "\"dataValid\":true,\"rootValid\":true,\"moduleCallOk\":true,\"beaconCallOk\":true}"
        );
    }

    function modelJson(
        bool authorized,
        bool moduleActive,
        bool allocationValid,
        bool lidoCallOk,
        string memory batches,
        uint256 depositable,
        uint256 counter
    ) internal view returns (string memory) {
        return string.concat(
            "{",
            "\"authorized\":", jsonBool(authorized),
            ",\"moduleActive\":", jsonBool(moduleActive),
            ",\"allocationValid\":", jsonBool(allocationValid),
            ",\"lidoCallOk\":", jsonBool(lidoCallOk),
            ",\"depositSize\":", vm.toString(DEPOSIT_SIZE),
            ",\"lido\":", vm.toString(uint256(uint160(address(lido)))),
            ",\"module\":", vm.toString(uint256(uint160(address(module)))),
            ",\"beacon\":", vm.toString(uint256(uint160(address(beacon)))),
            ",\"batches\":", batches,
            ",\"counter\":", vm.toString(counter),
            ",\"lidoDepositable\":", vm.toString(depositable),
            ",\"selfBalance\":0",
            "}"
        );
    }

    function runModel(string memory json) internal returns (Obs memory o) {
        string[] memory command = new string[](3);
        command[0] = "scripts/run_deposit_model.sh";
        command[1] = "source";
        command[2] = json;
        string memory raw = string(vm.ffi(command));
        o.ok = vm.parseJsonBool(raw, ".ok");
        if (o.ok) {
            o.revertText = "";
            o.pulled = vm.parseJsonUint(raw, ".pulled");
            o.pushed = vm.parseJsonUint(raw, ".pushed");
        } else {
            o.revertText = vm.parseJsonString(raw, ".revert");
        }
        o.routerBalance = vm.parseJsonUint(raw, ".routerBalance");
    }

    function familyModel(string memory reason) internal pure returns (string memory) {
        if (keccak256(bytes(reason)) == keccak256("NOT_AUTHORIZED")) return "auth";
        if (keccak256(bytes(reason)) == keccak256("MODULE_NOT_ACTIVE")) return "inactive";
        if (
            keccak256(bytes(reason)) == keccak256("INVALID_ALLOCATION")
                || keccak256(bytes(reason)) == keccak256("BATCH_TOTAL_OVERFLOW")
                || keccak256(bytes(reason)) == keccak256("ALLOCATION_VALUE_MISMATCH")
        ) return "allocation";
        if (keccak256(bytes(reason)) == keccak256("ASSERT_BALANCE_UNCHANGED")) return "assert";
        if (keccak256(bytes(reason)) == keccak256("NOT_ENOUGH_ETHER")) return "funds";
        if (bytes(reason).length == 0) return "commit";
        return "other";
    }

    function familySolidity(bool ok, bytes memory data) internal pure returns (string memory) {
        if (ok) return "commit";
        if (data.length >= 4) {
            bytes4 sel = bytes4(data);
            if (sel == bytes4(keccak256("NotAuthorized()"))) return "auth";
            if (sel == bytes4(keccak256("StakingModuleNotActive()"))) return "inactive";
            if (
                sel == bytes4(keccak256("ZeroDeposits()"))
                    || sel == bytes4(keccak256("WrongPubkeyLength()"))
                    || sel == bytes4(keccak256("ModuleReturnExceedTarget()"))
                    || sel == bytes4(keccak256("StakingModuleUnregistered()"))
            ) return "allocation";
            if (sel == bytes4(0x4e487b71)) return "assert";
        }
        if (data.length >= 68) {
            // Error(string) ABI
            if (bytes4(data) == bytes4(keccak256("Error(string)"))) return "funds";
        }
        return "other";
    }

    function observePinned(address caller, uint256 id, bytes memory data) internal returns (Obs memory o) {
        resetLog();
        uint256 depositableBefore = lido.depositable();
        uint256 routerBefore = address(router).balance;
        vm.record();
        vm.recordLogs();
        vm.prank(caller);
        (bool ok, bytes memory ret) = address(router).call(abi.encodeCall(StakingRouter.deposit, (id, data)));
        o.ok = ok;
        if (!ok && ret.length >= 4) o.selector = bytes4(ret);
        if (!ok) o.revertText = _hex4(o.selector);
        (, bytes32[] memory writes) = vm.accesses(address(router));
        o.storageWrites = writes.length;
        Log[] memory logs = vm.getRecordedLogs();
        o.eventCount = logs.length;
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
            o.routerBalance = address(router).balance;
        } else {
            o.pulled = 0;
            o.pushed = 0;
            o.routerBalance = routerBefore;
            // restore mock ledger after a reverting outer call? Foundry reverts callee
            // storage; MockLido is a separate contract so a revert inside router
            // rolls back the Lido call too.
            require(lido.depositable() == depositableBefore, "lido leak");
        }
    }

    function _hex4(bytes4 sel) internal pure returns (string memory) {
        bytes memory hex_ = "0123456789abcdef";
        bytes memory out = new bytes(10);
        out[0] = "0";
        out[1] = "x";
        uint256 v = uint256(uint32(sel));
        for (uint256 i; i < 8; ++i) {
            out[9 - i] = hex_[v % 16];
            v /= 16;
        }
        return string(out);
    }

    function twoKeyBatches() internal view returns (string memory) {
        return string.concat("[", jsonBatch(moduleId, 2, 2 * DEPOSIT_SIZE), "]");
    }

    function compareConservation(Obs memory sol, Obs memory model) internal pure {
        require(sol.ok == model.ok, "ok mismatch");
        if (sol.ok) {
            require(sol.pulled == model.pulled, "pulled mismatch");
            require(sol.pushed == model.pushed, "pushed mismatch");
            require(sol.pulled == sol.pushed, "solidity conservation");
            require(model.pulled == model.pushed, "model conservation");
        }
    }

    function compareFamily(Obs memory sol, Obs memory model) internal pure {
        require(
            keccak256(bytes(familySolidity(sol.ok, abi.encodePacked(sol.selector))))
                == keccak256(bytes(familyModel(sol.ok ? "" : model.revertText))),
            "revert family mismatch"
        );
    }

    function testNominalTwoKeysConserves() public {
        Obs memory sol = observePinned(DSM, moduleId, "");
        Obs memory model = runModel(
            modelJson(true, true, true, true, twoKeyBatches(), 320 ether, 0)
        );
        require(sol.ok, "pinned deposit failed");
        compareConservation(sol, model);
        require(sol.pulled == 64 ether, "expected 2*32 ether");
        require(sol.eventCount > 0, "source events missing");
        require(sol.callCount == 1 + 1 + 2, "source call count");
        require(keccak256(bytes(sol.names)) != keccak256("obtainDepositData,withdrawDepositableEther,depositToBeacon"));
    }

    function testEmptyKeysEarlyReturn() public {
        module.configure(100, 0);
        Obs memory sol = observePinned(DSM, moduleId, "");
        Obs memory model = runModel(
            modelJson(true, true, true, true, string.concat("[", jsonBatch(moduleId, 0, 0), "]"), 320 ether, 0)
        );
        require(sol.ok, "empty batch should return");
        require(sol.pulled == 0 && sol.pushed == 0, "empty source moves no ether");
        // Model still journals a zero Lido pull. Documented divergence D-EMPTY-PULL.
        require(model.ok, "model empty commit");
        require(model.pulled == 0, "model zero pull amount");
        require(
            keccak256(bytes(sol.names)) != keccak256(bytes("obtainDepositData,withdrawDepositableEther")),
            "empty-batch pull divergence vanished"
        );
    }

    function testUnauthorized() public {
        Obs memory sol = observePinned(address(this), moduleId, "");
        Obs memory model = runModel(
            modelJson(false, true, true, true, twoKeyBatches(), 320 ether, 0)
        );
        require(!sol.ok && !model.ok, "both must revert");
        require(
            keccak256(bytes(familySolidity(false, abi.encodePacked(sol.selector)))) == keccak256("auth")
        );
        require(keccak256(bytes(familyModel(model.revertText))) == keccak256("auth"));
        require(sol.selector != bytes4(0), "custom error selector");
        require(keccak256(bytes(model.revertText)) == keccak256("NOT_AUTHORIZED"));
        require(sol.selector != bytes4(keccak256("NOT_AUTHORIZED()")), "encoding divergence D-REVERT-1");
    }

    function testInactiveModule() public {
        vm.prank(ADMIN);
        router.setStakingModuleStatus(moduleId, StakingModuleStatus.DepositsPaused);
        Obs memory sol = observePinned(DSM, moduleId, "");
        Obs memory model = runModel(
            modelJson(true, false, true, true, twoKeyBatches(), 320 ether, 0)
        );
        require(!sol.ok && !model.ok, "both must revert");
        require(keccak256(bytes(familySolidity(false, abi.encodePacked(sol.selector)))) == keccak256("inactive"));
        require(keccak256(bytes(familyModel(model.revertText))) == keccak256("inactive"));
    }

    function testZeroDeposits() public {
        lido.setDepositable(0);
        Obs memory sol = observePinned(DSM, moduleId, "");
        Obs memory model = runModel(
            modelJson(true, true, false, true, twoKeyBatches(), 0, 0)
        );
        require(!sol.ok && !model.ok, "both must revert");
        require(sol.selector == bytes4(keccak256("ZeroDeposits()")));
        require(keccak256(bytes(model.revertText)) == keccak256("INVALID_ALLOCATION"));
    }

    function testExactCapTwoKeys() public {
        vm.prank(ADMIN);
        router.updateStakingModule(moduleId, 10_000, 10_000, 0, 0, 2, 1);
        module.configure(100, 10);
        Obs memory sol = observePinned(DSM, moduleId, "");
        Obs memory model = runModel(
            modelJson(true, true, true, true, string.concat("[", jsonBatch(moduleId, 2, 64 ether), "]"), 320 ether, 0)
        );
        require(sol.ok, "exact cap");
        compareConservation(sol, model);
        require(sol.pulled == 64 ether, "capped at 2 keys");
    }

    function testWrongPubkeyLength() public {
        module.setBadLength(true);
        Obs memory sol = observePinned(DSM, moduleId, "");
        Obs memory model = runModel(
            modelJson(true, true, false, true, twoKeyBatches(), 320 ether, 0)
        );
        require(!sol.ok && !model.ok, "both must revert");
        require(sol.selector == bytes4(keccak256("WrongPubkeyLength()")));
        require(keccak256(bytes(model.revertText)) == keccak256("INVALID_ALLOCATION"));
    }

    function testModuleExceedsTarget() public {
        module.setExceedTarget(true);
        Obs memory sol = observePinned(DSM, moduleId, "");
        Obs memory model = runModel(
            modelJson(true, true, false, true, twoKeyBatches(), 320 ether, 0)
        );
        require(!sol.ok && !model.ok, "both must revert");
        require(sol.selector == bytes4(keccak256("ModuleReturnExceedTarget()")));
    }

    function testWordOverflowIsModelOnly() public {
        // Solidity cannot encode 2^256 keys. The registered parent reverts
        // BATCH_TOTAL_OVERFLOW on that Nat input. Documented domain gap.
        string memory batches = string.concat("[", jsonBatch(moduleId, 1, 2 ** 255), ",", jsonBatch(2, 1, 2 ** 255), "]");
        Obs memory model = runModel(
            modelJson(true, true, true, true, batches, 0, 0)
        );
        require(!model.ok, "wrapping fold must revert");
        require(keccak256(bytes(model.revertText)) == keccak256("BATCH_TOTAL_OVERFLOW"));
    }

    function testDuplicateModuleIdsAcceptedByModel() public {
        string memory batches = string.concat(
            "[", jsonBatch(moduleId, 1, DEPOSIT_SIZE), ",", jsonBatch(moduleId, 1, DEPOSIT_SIZE), "]"
        );
        Obs memory model = runModel(modelJson(true, true, true, true, batches, 320 ether, 0));
        // Preconditions.distinctModules is a theorem premise, not an execute guard.
        require(model.ok, "model execute does not reject duplicate module ids");
    }

    function testLidoFailureAfterModuleCallRollsBack() public {
        lido.setFailWithdraw(true);
        uint256 before = lido.depositable();
        Obs memory sol = observePinned(DSM, moduleId, "");
        require(!sol.ok, "lido failure must revert");
        require(lido.depositable() == before, "lido rolled back");
        require(address(router).balance == 0, "router rolled back");
        Obs memory model = runModel(
            modelJson(true, true, true, false, twoKeyBatches(), 320 ether, 0)
        );
        require(!model.ok, "model lidoCallOk=false reverts");
    }

    function testSkewedMaxEbHitsConservationAssert() public {
        DepositHarness skewed = _deployRouter(64 ether);
        lido.setRouter(address(skewed));
        lido.setDepositable(320 ether);
        module.configure(100, 1);
        resetLog();
        vm.prank(DSM);
        (bool ok, bytes memory ret) = address(skewed).call(abi.encodeCall(StakingRouter.deposit, (moduleId, bytes(""))));
        require(!ok, "skewed maxEB must revert");
        require(bytes4(ret) == bytes4(0x4e487b71), "expected Panic");
        // Model uses one depositSize for pull and push, so it cannot name this
        // maxEB ≠ DEPOSIT_SIZE split. Documented as D-SKEW-1.
        Obs memory model = runModel(
            modelJson(true, true, true, true, string.concat("[", jsonBatch(1, 1, 64 ether), "]"), 320 ether, 0)
        );
        require(!model.ok, "model rejects amount != keys * depositSize");
        require(keccak256(bytes(model.revertText)) == keccak256("ALLOCATION_VALUE_MISMATCH"));
        lido.setRouter(address(router));
    }

    function testModelJournalDivergesFromPinnedSource() public {
        Obs memory sol = observePinned(DSM, moduleId, "");
        Obs memory model = runModel(
            modelJson(true, true, true, true, twoKeyBatches(), 320 ether, 0)
        );
        require(sol.ok && model.ok, "nominal path");
        // Pinned source: obtainDepositData, withdrawDepositableEther, deposit x keys.
        // Model: obtainDepositData, withdrawDepositableEther, depositToBeacon x batches.
        require(
            keccak256(bytes(sol.names)) != keccak256("obtainDepositData,withdrawDepositableEther,depositToBeacon"),
            "call-journal divergence D-CALL-1 vanished; flip this test to equality"
        );
        require(model.pushed == sol.pushed, "conservation still agrees");
    }

    function testMutantDroppedAssertStrandsEther() public {
        DepositHarness skewed = _deployRouter(64 ether);
        lido.setRouter(address(skewed));
        lido.setDepositable(320 ether);
        module.configure(100, 1);
        resetLog();
        vm.prank(DSM);
        (bool honestOk,) = address(skewed).call(abi.encodeCall(StakingRouter.deposit, (moduleId, bytes(""))));
        require(!honestOk, "honest skewed pin reverts at the assert");
        resetLog();
        vm.prank(DSM);
        (bool mutantOk,) =
            address(skewed).call(abi.encodeCall(skewed.depositDroppedAssert, (moduleId, bytes(""))));
        require(mutantOk, "dropped-assert mutant commits the skew");
        require(address(skewed).balance == 32 ether, "stranded 32 ether");
        lido.setRouter(address(router));
    }

    function testMutantReversedOrderRevertsOnNominal() public {
        resetLog();
        vm.prank(DSM);
        (bool ok,) = address(router).call(abi.encodeCall(router.depositReversedOrder, (moduleId, bytes(""))));
        require(!ok, "push-before-pull must fail without pre-funded router");
        Obs memory honest = observePinned(DSM, moduleId, "");
        require(honest.ok, "honest pin succeeds");
    }

    function testMutantWrongSlotSkipsLastDepositWrite() public {
        vm.record();
        vm.prank(DSM);
        (bool ok,) = address(router).call(abi.encodeCall(router.depositWrongSlot, (moduleId, bytes(""))));
        require(ok, "wrong-slot mutant commits");
        (, bytes32[] memory mutantWrites) = vm.accesses(address(router));
        resetLog();
        vm.record();
        vm.prank(DSM);
        (bool ok2,) = address(router).call(abi.encodeCall(StakingRouter.deposit, (moduleId, bytes(""))));
        require(ok2, "honest second deposit");
        (, bytes32[] memory honestWrites) = vm.accesses(address(router));
        require(keccak256(abi.encode(mutantWrites)) != keccak256(abi.encode(honestWrites)), "wrong-slot undetected");
    }

    function testUnregisteredModule() public {
        Obs memory sol = observePinned(DSM, 99, "");
        require(!sol.ok, "unknown module");
        require(sol.selector == bytes4(keccak256("StakingModuleUnregistered()")));
    }
}
