// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Topup2Harness} from "../src/Topup2Harness.sol";
import {CallLog, MockLocator, MockStakingRouter, MinimalProxy} from "../src/Mocks.sol";
import {TopUpGateway} from "../../../lido-core/contracts/0.8.25/TopUpGateway.sol";
import {GIndex} from "contracts/common/lib/GIndex.sol";
import {TopUpData, BeaconRootData, ValidatorWitness} from "contracts/common/interfaces/TopUpWitness.sol";

interface VmTopup2 {
    function ffi(string[] calldata command) external returns (bytes memory);
    function toString(uint256 value) external pure returns (string memory);
    function parseJsonBool(string calldata json, string calldata key) external pure returns (bool);
    function parseJsonUint(string calldata json, string calldata key) external pure returns (uint256);
    function parseJsonString(string calldata json, string calldata key) external pure returns (string memory);
    function prank(address sender) external;
    function startPrank(address sender) external;
    function stopPrank() external;
    function record() external;
    function accesses(address target) external returns (bytes32[] memory reads, bytes32[] memory writes);
    function warp(uint256) external;
}

/// Foundry --ffi harness: pinned TopUpGateway vs Source.Topup2.sourceRun.
contract Topup2DifferentialTest {
    VmTopup2 private constant vm = VmTopup2(address(uint160(uint256(keccak256("hevm cheat code")))));

    address internal constant ADMIN = address(0xA11CE);
    address internal constant OPERATOR = address(0x0B07);
    uint256 internal constant MODULE = 1;
    uint64 internal constant FAR = type(uint64).max;
    uint256 internal constant TARGET = 32_000_000_000;
    uint256 internal constant MIN_TOP = 1_000_000_000;
    uint256 internal constant GWEI = 1_000_000_000;

    CallLog internal log;
    MockLocator internal locator;
    MockStakingRouter internal router;
    Topup2Harness internal gateway;

    struct Model {
        bool ok;
        string revertText;
        uint256 used;
        uint256 remaining;
        uint256 n;
        uint256[8] allocs;
        uint256[8] limits;
        uint256 limitCount;
    }

    function setUp() public {
        vm.warp(1_700_000_000);
        log = new CallLog();
        locator = new MockLocator();
        router = new MockStakingRouter(log);
        locator.setRouter(address(router));
        bytes32 wc = bytes32((uint256(2) << 248) | uint256(uint160(address(0xBEEF))));
        router.setWithdrawalCredentials(MODULE, wc);

        Topup2Harness impl = new Topup2Harness(
            address(locator), GIndex.wrap(bytes32(uint256(1))), GIndex.wrap(bytes32(uint256(1))), 0, 32
        );
        bytes memory init = abi.encodeCall(TopUpGateway.initialize, (ADMIN, 32, 1, 3600, TARGET, MIN_TOP));
        MinimalProxy proxy = new MinimalProxy(address(impl), init);
        gateway = Topup2Harness(address(proxy));

        vm.startPrank(ADMIN);
        gateway.grantRole(gateway.TOP_UP_ROLE(), OPERATOR);
        gateway.grantRole(gateway.MANAGE_LIMITS_ROLE(), ADMIN);
        vm.stopPrank();
    }

    function _pk(uint256 salt) internal pure returns (bytes memory) {
        return bytes.concat(bytes32(salt), bytes16(uint128(salt)));
    }

    function _vw(uint64 effective, uint64 exitEpoch, bool slashed) internal pure returns (ValidatorWitness memory vw) {
        vw.proofValidator = new bytes32[](0);
        vw.pubkey = _pk(1);
        vw.effectiveBalance = effective;
        vw.activationEligibilityEpoch = 0;
        vw.activationEpoch = 0;
        vw.exitEpoch = exitEpoch;
        vw.withdrawableEpoch = FAR;
        vw.slashed = slashed;
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

    function _arr1(uint64 effective, uint64 exitEpoch, bool slashed)
        internal
        pure
        returns (ValidatorWitness[] memory vws)
    {
        vws = new ValidatorWitness[](1);
        vws[0] = _vw(effective, exitEpoch, slashed);
    }

    function _arr2(uint64 e0, uint64 e1) internal pure returns (ValidatorWitness[] memory vws) {
        vws = new ValidatorWitness[](2);
        vws[0] = _vw(e0, FAR, false);
        vws[1] = _vw(e1, FAR, false);
        vws[1].pubkey = _pk(2);
    }

    function _jsonList(uint256[] memory xs) internal view returns (string memory out) {
        out = "[";
        for (uint256 i; i < xs.length; ++i) {
            if (i != 0) out = string.concat(out, ",");
            out = string.concat(out, "\"", vm.toString(xs[i]), "\"");
        }
        out = string.concat(out, "]");
    }

    function modelJson(
        uint256[] memory effective,
        uint256[] memory pending,
        uint256[] memory requested,
        uint256[] memory topUpLimits,
        uint256 remainingCap
    ) internal view returns (string memory) {
        return string.concat(
            "{\"effective\":",
            _jsonList(effective),
            ",\"pending\":",
            _jsonList(pending),
            ",\"requested\":",
            _jsonList(requested),
            ",\"topUpLimits\":",
            _jsonList(topUpLimits),
            ",\"target\":\"",
            vm.toString(TARGET),
            "\",\"minTopUp\":\"",
            vm.toString(MIN_TOP),
            "\",\"remainingCap\":\"",
            vm.toString(remainingCap),
            "\",\"moduleLimit\":\"",
            vm.toString(uint256(type(uint64).max)),
            "\",\"valueGwei\":\"",
            vm.toString(uint256(type(uint64).max)),
            "\"}"
        );
    }

    function runModel(string memory json) internal returns (Model memory o) {
        string[] memory command = new string[](3);
        command[0] = "scripts/run_topup2_model.sh";
        command[1] = "source";
        command[2] = json;
        string memory raw = string(vm.ffi(command));
        o.ok = vm.parseJsonBool(raw, ".ok");
        o.used = vm.parseJsonUint(raw, ".used");
        o.remaining = vm.parseJsonUint(raw, ".remaining");
        o.n = vm.parseJsonUint(raw, ".n");
        o.limitCount = vm.parseJsonUint(raw, ".limitN");
        if (!o.ok) {
            o.revertText = vm.parseJsonString(raw, ".revert");
        }
        for (uint256 i; i < 8; ++i) {
            if (i < o.n) {
                o.allocs[i] = vm.parseJsonUint(raw, string.concat(".allocs[", vm.toString(i), "]"));
            }
            if (i < o.limitCount) {
                o.limits[i] = vm.parseJsonUint(raw, string.concat(".limits[", vm.toString(i), "]"));
            }
        }
    }

    function _data(uint256[] memory indices, ValidatorWitness[] memory vws, uint256[] memory pending)
        internal
        view
        returns (TopUpData memory d)
    {
        uint256 n = indices.length;
        uint256[] memory keys = new uint256[](n);
        uint256[] memory ops = new uint256[](n);
        for (uint256 i; i < n; ++i) {
            keys[i] = i;
            ops[i] = 0;
        }
        d.moduleId = MODULE;
        d.keyIndices = keys;
        d.operatorIds = ops;
        d.validatorIndices = indices;
        d.beaconRootData =
            BeaconRootData({childBlockTimestamp: uint64(block.timestamp), slot: 32, proposerIndex: 1});
        d.validatorWitness = vws;
        d.pendingBalanceGwei = pending;
    }

    function callTopUp(address caller, TopUpData memory data) internal returns (bool ok, bytes memory ret) {
        log.reset();
        vm.prank(caller);
        (ok, ret) = address(gateway).call(abi.encodeCall(TopUpGateway.topUp, (data)));
    }

    function testNominalOneKeyAgreesOnLimitAndUsed() public {
        uint64 effective = 12_000_000_000;
        uint256 gap = TARGET - effective;
        uint256 sol = gateway.evaluateLimit(_vw(effective, FAR, false), 0);
        require(sol == gap, "pinned gap");

        Model memory model = runModel(modelJson(_one(effective), _one(0), _one(gap), _one(gap), type(uint64).max));
        require(model.ok, "sourceRun nominal");
        require(model.limits[0] == sol, "sourceLimits vs evaluate");
        require(model.used == gap && model.allocs[0] == gap, "leftover used");

        ValidatorWitness[] memory vws = _arr1(effective, FAR, false);
        (bool ok, bytes memory ret) = callTopUp(OPERATOR, _data(_one(1), vws, _one(0)));
        require(ok, string(ret));
        require(log.count() == 1, "one router call");
        CallLog.Item memory item = log.at(0);
        require(item.target == address(router), "router target");
        require(item.arg1 == gap * GWEI, "limit wei");
        require(gateway.getLastTopUpTimestamp() == block.timestamp, "last top-up written");
    }

    function testZeroPendingStillComputesGap() public {
        uint64 effective = 31_000_000_000;
        uint256 gap = TARGET - effective;
        require(gap == MIN_TOP, "exact min");
        uint256 sol = gateway.evaluateLimit(_vw(effective, FAR, false), 0);
        require(sol == MIN_TOP, "exact min pin");
        Model memory model = runModel(modelJson(_one(effective), _one(0), _one(gap), _one(gap), type(uint64).max));
        require(model.ok && model.used == MIN_TOP, "exact cap used");
    }

    function testEmptyEffectiveIsNone() public {
        Model memory model = runModel(modelJson(new uint256[](0), new uint256[](0), new uint256[](0), new uint256[](0), 1));
        require(!model.ok, "empty sourceRun");
        ValidatorWitness[] memory vws = new ValidatorWitness[](0);
        (bool ok, bytes memory ret) = callTopUp(OPERATOR, _data(new uint256[](0), vws, new uint256[](0)));
        require(!ok && bytes4(ret) == bytes4(keccak256("WrongArrayLength()")));
    }

    function testExactTargetReturnsZeroLimit() public {
        uint64 effective = uint64(TARGET);
        uint256 sol = gateway.evaluateLimit(_vw(effective, FAR, false), 0);
        require(sol == 0, "at target");
        Model memory model = runModel(modelJson(_one(effective), _one(0), _one(0), _one(0), type(uint64).max));
        require(model.ok && model.used == 0 && model.limits[0] == 0, "zero used");
        require(gateway.getLastTopUpTimestamp() == 0, "no prior write");
        ValidatorWitness[] memory vws = _arr1(effective, FAR, false);
        (bool ok,) = callTopUp(OPERATOR, _data(_one(1), vws, _one(0)));
        require(ok, "zero-limit topUp commits");
        require(gateway.getLastTopUpTimestamp() == 0, "zero totalLimits skips last write");
    }

    function testOverflowEvaluateReverts() public {
        (bool ok, bytes memory ret) =
            address(gateway).call(abi.encodeCall(Topup2Harness.evaluateLimit, (_vw(1, FAR, false), type(uint256).max)));
        require(!ok && ret.length >= 4 && bytes4(ret) == bytes4(0x4e487b71), "panic overflow");
        Model memory model =
            runModel(modelJson(_one(1), _one(type(uint256).max), _one(0), _one(0), type(uint64).max));
        require(!model.ok, "model overflow none");
        require(model.limitCount == 0, "sourceLimits none");
    }

    function testSlashZeroOnPinModelIgnoresFlag() public {
        uint64 effective = 12_000_000_000;
        uint256 gap = TARGET - effective;
        uint256 sol = gateway.evaluateLimit(_vw(effective, FAR, true), 0);
        require(sol == 0, "pin slash");
        // Model evaluate has no slash flag. Supplied [0] != evaluated [gap] => none. D-SLASH-1.
        Model memory model = runModel(modelJson(_one(effective), _one(0), _one(gap), _one(0), type(uint64).max));
        require(!model.ok, "inconsistent limits");
        require(model.limits[0] == gap, "model still evaluates gap");
    }

    function testUnauthorizedCaller() public {
        ValidatorWitness[] memory vws = _arr1(12_000_000_000, FAR, false);
        (bool ok, bytes memory ret) = callTopUp(address(this), _data(_one(1), vws, _one(0)));
        require(!ok && bytes4(ret) == bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")));
        uint256 gap = TARGET - 12_000_000_000;
        Model memory model = runModel(modelJson(_one(12_000_000_000), _one(0), _one(gap), _one(gap), type(uint64).max));
        require(model.ok, "model has no role check");
    }

    function testDuplicateIndices() public {
        ValidatorWitness[] memory vws = _arr2(12_000_000_000, 20_000_000_000);
        (bool ok, bytes memory ret) = callTopUp(OPERATOR, _data(_two(1, 1), vws, _two(0, 0)));
        require(!ok && bytes4(ret) == bytes4(keccak256("InvalidValidatorIndicesSortOrder()")));
    }

    function testTwoKeyBlockCapLeftoverVsIndependent() public {
        // Each key independently eligible for 20e9. Cap 20e9.
        // Pin writes [20e9, 20e9] * 1 gwei. sourceRun leftover is [20e9, 0]. D-CONSUME-1.
        uint64 e0 = 12_000_000_000;
        uint64 e1 = 12_000_000_000;
        uint256 gap = TARGET - e0;
        uint256[] memory ev = gateway.evaluateBatch(_arr2(e0, e1), _two(0, 0));
        require(ev[0] == gap && ev[1] == gap, "independent limits");

        Model memory model = runModel(modelJson(_two(e0, e1), _two(0, 0), _two(gap, gap), _two(gap, gap), gap));
        require(model.ok, "sourceRun cap");
        require(model.allocs[0] == gap && model.allocs[1] == 0, "leftover walk");
        require(model.used == gap, "used equals cap");
        require(model.limits[0] == gap && model.limits[1] == gap, "evaluated still independent");

        ValidatorWitness[] memory vws = _arr2(e0, e1);
        (bool ok, bytes memory ret) = callTopUp(OPERATOR, _data(_two(1, 2), vws, _two(0, 0)));
        require(ok, string(ret));
        require(log.at(0).arg1 == gap * GWEI, "first independent wei");
    }

    function testWrongWithdrawalCredentials() public {
        router.setWithdrawalCredentials(MODULE, bytes32((uint256(1) << 248) | uint256(uint160(address(0xBEEF)))));
        ValidatorWitness[] memory vws = _arr1(12_000_000_000, FAR, false);
        (bool ok, bytes memory ret) = callTopUp(OPERATOR, _data(_one(1), vws, _one(0)));
        require(!ok && bytes4(ret) == bytes4(keccak256("WrongWithdrawalCredentials()")));
    }

    function testWrongPubkeyLength() public {
        ValidatorWitness[] memory vws = _arr1(12_000_000_000, FAR, false);
        vws[0].pubkey = hex"1234";
        (bool ok, bytes memory ret) = callTopUp(OPERATOR, _data(_one(1), vws, _one(0)));
        require(!ok && bytes4(ret) == bytes4(keccak256("WrongPubkeyLength()")));
    }

    function testMaxValidatorsExceeded() public {
        vm.prank(ADMIN);
        gateway.setMaxValidatorsPerTopUp(1);
        ValidatorWitness[] memory vws = _arr2(12_000_000_000, 12_000_000_000);
        (bool ok, bytes memory ret) = callTopUp(OPERATOR, _data(_two(1, 2), vws, _two(0, 0)));
        require(!ok && bytes4(ret) == bytes4(keccak256("MaxValidatorsPerTopUpExceeded()")));
    }

    function testRouterFailureAfterLimitLoop() public {
        router.setFailTopUp(true);
        ValidatorWitness[] memory vws = _arr1(12_000_000_000, FAR, false);
        (bool ok,) = callTopUp(OPERATOR, _data(_one(1), vws, _one(0)));
        require(!ok, "router revert");
        require(gateway.getLastTopUpTimestamp() == 0, "no last write after fail");
        require(log.count() == 1, "call happened then reverted");
    }

    function testMutantDroppedGuardDetected() public {
        uint256 honest = gateway.evaluateLimit(_vw(12_000_000_000, FAR, true), 0);
        uint256 mutant = gateway.evaluateDroppedGuard(_vw(12_000_000_000, FAR, true), 0);
        require(honest == 0 && mutant == TARGET - 12_000_000_000, "dropped slash");
    }

    function testMutantReversedOrderDetected() public {
        ValidatorWitness[] memory vws = _arr2(12_000_000_000, 20_000_000_000);
        uint256[] memory honest = gateway.evaluateBatch(vws, _two(0, 0));
        uint256[] memory mutant = gateway.evaluateReversedOrder(vws, _two(0, 0));
        require(honest[0] != honest[1], "distinct gaps");
        require(mutant[0] == honest[1] && mutant[1] == honest[0], "reversed");
    }

    function testMutantWrongSlotDetected() public {
        uint256 honest = gateway.evaluateLimit(_vw(12_000_000_000, FAR, false), 0);
        uint256 mutant = gateway.evaluateWrongSlot(_vw(12_000_000_000, FAR, false), 0);
        require(honest == TARGET - 12_000_000_000, "honest gap");
        require(mutant == 0, "wrong field as target");
    }

    function testBelowMinTopUpIsZero() public {
        uint64 effective = uint64(TARGET - MIN_TOP + 1);
        uint256 sol = gateway.evaluateLimit(_vw(effective, FAR, false), 0);
        require(sol == 0, "below min");
        Model memory model = runModel(modelJson(_one(effective), _one(0), _one(0), _one(0), type(uint64).max));
        require(model.ok && model.limits[0] == 0 && model.used == 0, "model min");
    }

    function testPendingShrinksGap() public {
        uint64 effective = 12_000_000_000;
        uint256 pending = 5_000_000_000;
        uint256 gap = TARGET - effective - pending;
        uint256 sol = gateway.evaluateLimit(_vw(effective, FAR, false), pending);
        require(sol == gap, "pending gap");
        Model memory model =
            runModel(modelJson(_one(effective), _one(pending), _one(gap), _one(gap), type(uint64).max));
        require(model.ok && model.used == gap, "pending used");
    }

    function testLengthMismatchIsNone() public {
        Model memory model = runModel(modelJson(_one(12_000_000_000), _two(0, 0), _one(1), _one(1), 10));
        require(!model.ok, "length mismatch");
    }
}
