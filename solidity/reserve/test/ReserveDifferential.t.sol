// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {
    CallLog,
    MockLocator,
    MockWithdrawalQueue,
    MockAccountingOracle,
    MockStakingRouter
} from "../src/Mocks.sol";

interface IReserveHarness {
    function seedLocator(address loc) external;
    function seedActive() external;
    function seedStopped() external;
    function seedBuffer(uint256 buffered, uint256 depositedPostReport) external;
    function seedDepositsReserve(uint256 value) external;
    function seedNextReport(uint256 depositedNextReport, uint256 nonce) external;
    function readDummySlot() external view returns (uint256);
    function withdrawDepositableEther(uint256 amount, uint256 seedDepositsCount) external;
    function getBufferedEther() external view returns (uint256);
    function getWithdrawalsReserve() external view returns (uint256);
    function getDepositsReserve() external view returns (uint256);
    function getDepositableEther() external view returns (uint256);
    function canDeposit() external view returns (bool);
}

interface VmReserve {
    function ffi(string[] calldata command) external returns (bytes memory);
    function toString(uint256 value) external pure returns (string memory);
    function parseJsonBool(string calldata json, string calldata key) external pure returns (bool);
    function parseJsonUint(string calldata json, string calldata key) external pure returns (uint256);
    function parseJsonString(string calldata json, string calldata key) external pure returns (string memory);
    function parseBytes(string calldata) external pure returns (bytes memory);
    function readFile(string calldata path) external view returns (string memory);
    function deal(address account, uint256 amount) external;
    function prank(address sender) external;
    function startPrank(address sender) external;
    function stopPrank() external;
}

/// Foundry --ffi harness: pinned Lido.withdrawDepositableEther vs modelWithdrawDepositableEther.
contract ReserveDifferentialTest {
    VmReserve private constant vm = VmReserve(address(uint160(uint256(keccak256("hevm cheat code")))));

    CallLog internal log;
    MockLocator internal locator;
    MockWithdrawalQueue internal queue;
    MockAccountingOracle internal oracle;
    MockStakingRouter internal router;
    IReserveHarness internal lido;

    struct Model {
        bool ok;
        string revertText;
        uint256 buffered;
        uint256 storedDepositsReserve;
        uint256 unfinalizedStETH;
        uint256 wrBefore;
        uint256 wrAfter;
        uint256 depositedPostReport;
        uint256 depositedNextReportAdjusted;
    }

    function setUp() public {
        log = new CallLog();
        locator = new MockLocator();
        queue = new MockWithdrawalQueue(log);
        oracle = new MockAccountingOracle();
        router = new MockStakingRouter(log);
        lido = IReserveHarness(_deployPinnedLido());
        locator.set(address(router), address(queue), address(oracle));
        lido.seedLocator(address(locator));
        lido.seedActive();
        oracle.setFrame(1, 1);
        lido.seedNextReport(0, 1);
    }

    function _deployPinnedLido() internal returns (address addr) {
        string memory hexbin = vm.readFile("solidity/out/reserve-0424/ReserveHarness.bin");
        bytes memory code = vm.parseBytes(string.concat("0x", hexbin));
        assembly ("memory-safe") {
            addr := create(0, add(code, 0x20), mload(code))
        }
        require(addr != address(0), "pinned Lido create");
    }

    function seed(uint256 buffered, uint256 stored, uint256 unfinalized, uint256 post) internal {
        lido.seedBuffer(buffered, post);
        lido.seedDepositsReserve(stored);
        queue.setUnfinalized(unfinalized);
        vm.deal(address(lido), buffered);
        log.reset();
    }

    function modelJson(
        bool canDeposit,
        bool authorized,
        uint256 amount,
        uint256 buffered,
        uint256 stored,
        uint256 unfinalized,
        uint256 post,
        uint256 nextAdj
    ) internal view returns (string memory) {
        return string.concat(
            "{\"canDeposit\":",
            canDeposit ? "true" : "false",
            ",\"authorizedRouter\":",
            authorized ? "true" : "false",
            ",\"amount\":\"",
            vm.toString(amount),
            "\",\"buffered\":\"",
            vm.toString(buffered),
            "\",\"storedDepositsReserve\":\"",
            vm.toString(stored),
            "\",\"unfinalizedStETH\":\"",
            vm.toString(unfinalized),
            "\",\"depositedPostReport\":\"",
            vm.toString(post),
            "\",\"depositedNextReportAdjusted\":\"",
            vm.toString(nextAdj),
            "\"}"
        );
    }

    function runModel(string memory json) internal returns (Model memory o) {
        string[] memory command = new string[](3);
        command[0] = "scripts/run_reserve_model.sh";
        command[1] = "source";
        command[2] = json;
        string memory raw = string(vm.ffi(command));
        o.ok = vm.parseJsonBool(raw, ".ok");
        o.buffered = vm.parseJsonUint(raw, ".buffered");
        o.storedDepositsReserve = vm.parseJsonUint(raw, ".storedDepositsReserve");
        o.unfinalizedStETH = vm.parseJsonUint(raw, ".unfinalizedStETH");
        o.wrBefore = vm.parseJsonUint(raw, ".withdrawalsReserveBefore");
        o.wrAfter = vm.parseJsonUint(raw, ".withdrawalsReserveAfter");
        o.depositedPostReport = vm.parseJsonUint(raw, ".depositedPostReport");
        o.depositedNextReportAdjusted = vm.parseJsonUint(raw, ".depositedNextReportAdjusted");
        if (!o.ok) o.revertText = vm.parseJsonString(raw, ".revert");
    }

    function revertString(bytes memory ret) internal pure returns (string memory s) {
        if (ret.length < 68) return "";
        bytes memory payload = new bytes(ret.length - 4);
        for (uint256 i; i < payload.length; ++i) {
            payload[i] = ret[i + 4];
        }
        s = abi.decode(payload, (string));
    }

    function callWithdraw(address caller, uint256 amount) internal returns (bool ok, bytes memory ret) {
        log.reset();
        vm.prank(caller);
        (ok, ret) = address(lido).call(abi.encodeWithSignature("withdrawDepositableEther(uint256,uint256)", amount, 0));
    }

    function testNominalSpendPreservesWithdrawals() public {
        uint256 buffered = 100 ether;
        uint256 stored = 40 ether;
        uint256 unfinalized = 30 ether;
        uint256 amount = 10 ether;
        seed(buffered, stored, unfinalized, 0);
        uint256 wrBefore = lido.getWithdrawalsReserve();
        require(wrBefore == 30 ether, "wr = min(60, 30)");

        (bool ok, bytes memory ret) = callWithdraw(address(router), amount);
        require(ok, string(ret));
        require(lido.getBufferedEther() == 90 ether, "buffer spent");
        require(lido.getWithdrawalsReserve() == wrBefore, "WR unchanged");
        require(queue.unfinalizedStETH() == unfinalized, "queue word unchanged");
        require(address(router).balance == amount, "router paid");
        require(log.count() == 1 && log.at(0).value == amount, "one transfer");
        require(router.bufferedAtPay() == 90 ether, "spend before transfer");

        Model memory model = runModel(modelJson(true, true, amount, buffered, stored, unfinalized, 0, 0));
        require(model.ok, "model commit");
        require(model.buffered == 90 ether, "model buffer");
        require(model.wrAfter == model.wrBefore && model.wrAfter == wrBefore, "model WR");
        require(model.unfinalizedStETH == unfinalized, "model queue field");
        require(model.storedDepositsReserve == 30 ether, "stored reserve shrinks");
    }

    function testZeroAmountReverts() public {
        seed(100 ether, 40 ether, 30 ether, 0);
        (bool ok, bytes memory ret) = callWithdraw(address(router), 0);
        require(!ok && keccak256(bytes(revertString(ret))) == keccak256("ZERO_AMOUNT"));
        Model memory model = runModel(modelJson(true, true, 0, 100 ether, 40 ether, 30 ether, 0, 0));
        require(!model.ok && keccak256(bytes(model.revertText)) == keccak256("ZERO_AMOUNT"));
    }

    function testUnauthorizedRouter() public {
        seed(100 ether, 40 ether, 30 ether, 0);
        (bool ok, bytes memory ret) = callWithdraw(address(this), 1 ether);
        require(!ok && keccak256(bytes(revertString(ret))) == keccak256("APP_AUTH_FAILED"));
        Model memory model = runModel(modelJson(true, false, 1 ether, 100 ether, 40 ether, 30 ether, 0, 0));
        require(!model.ok && keccak256(bytes(model.revertText)) == keccak256("APP_AUTH_FAILED"));
    }

    function testCanNotDepositBunker() public {
        seed(100 ether, 40 ether, 30 ether, 0);
        queue.setBunker(true);
        (bool ok, bytes memory ret) = callWithdraw(address(router), 1 ether);
        require(!ok && keccak256(bytes(revertString(ret))) == keccak256("CAN_NOT_DEPOSIT"));
        Model memory model = runModel(modelJson(false, true, 1 ether, 100 ether, 40 ether, 30 ether, 0, 0));
        require(!model.ok && keccak256(bytes(model.revertText)) == keccak256("CAN_NOT_DEPOSIT"));
    }

    function testNotEnoughEtherDoesNotRaidWithdrawals() public {
        // depositable = depositsReserve + unreserved = 40 + (100-40-30) = 70
        seed(100 ether, 40 ether, 30 ether, 0);
        uint256 wrBefore = lido.getWithdrawalsReserve();
        (bool ok, bytes memory ret) = callWithdraw(address(router), 80 ether);
        require(!ok && keccak256(bytes(revertString(ret))) == keccak256("NOT_ENOUGH_ETHER"));
        require(lido.getWithdrawalsReserve() == wrBefore, "WR intact on revert");
        require(lido.getBufferedEther() == 100 ether, "buffer intact");
        Model memory model = runModel(modelJson(true, true, 80 ether, 100 ether, 40 ether, 30 ether, 0, 0));
        require(!model.ok && keccak256(bytes(model.revertText)) == keccak256("NOT_ENOUGH_ETHER"));
        require(model.wrAfter == model.wrBefore, "model WR intact");
    }

    function testExactDepositableCap() public {
        seed(100 ether, 40 ether, 30 ether, 0);
        uint256 depositable = lido.getDepositableEther();
        require(depositable == 70 ether, "40 + 30 unreserved");
        (bool ok, bytes memory ret) = callWithdraw(address(router), depositable);
        require(ok, string(ret));
        require(lido.getWithdrawalsReserve() == 30 ether, "WR still 30");
        require(lido.getBufferedEther() == 30 ether, "only WR left");
        Model memory model = runModel(modelJson(true, true, 70 ether, 100 ether, 40 ether, 30 ether, 0, 0));
        require(model.ok && model.buffered == 30 ether && model.wrAfter == 30 ether, "exact cap");
    }

    function testUnreservedOnlyWhenStoredReserveZero() public {
        seed(50 ether, 0, 20 ether, 0);
        require(lido.getDepositableEther() == 30 ether, "unreserved only");
        (bool ok,) = callWithdraw(address(router), 10 ether);
        require(ok, "unreserved spend");
        require(lido.getWithdrawalsReserve() == 20 ether, "WR untouched");
        Model memory model = runModel(modelJson(true, true, 10 ether, 50 ether, 0, 20 ether, 0, 0));
        require(model.ok && model.storedDepositsReserve == 0 && model.wrAfter == 20 ether, "zero stored");
    }

    function testPackedPostReportWrapsOnPin() public {
        // Pin stores depositedPostReport in the high uint128 of the buffer slot.
        // uint128.max + 1 ether still fits uint256 SafeMath, so the model commits
        // the exact sum; the pin's 0.4.24 `<< 128` wraps the packed high half.
        // D-PACK-1. Withdrawals reserve must still hold.
        uint256 post = type(uint128).max;
        seed(100 ether, 40 ether, 10 ether, post);
        uint256 wr = lido.getWithdrawalsReserve();
        (bool ok, bytes memory ret) = callWithdraw(address(router), 1 ether);
        require(ok, string(ret));
        require(lido.getWithdrawalsReserve() == wr, "WR holds under pack wrap");
        Model memory model = runModel(modelJson(true, true, 1 ether, 100 ether, 40 ether, 10 ether, post, 0));
        require(model.ok, "model uint256 add commits");
        require(model.depositedPostReport == post + 1 ether, "model exact sum");
        require(model.depositedPostReport != post, "not a no-op");
    }

    function testRouterFailAfterSpendRollsBack() public {
        seed(100 ether, 40 ether, 30 ether, 0);
        router.setFailReceive(true);
        uint256 wr = lido.getWithdrawalsReserve();
        (bool ok,) = callWithdraw(address(router), 10 ether);
        require(!ok, "router fail");
        require(lido.getBufferedEther() == 100 ether, "spend rolled back");
        require(lido.getWithdrawalsReserve() == wr, "WR rolled back");
        require(log.count() == 0, "journal rolled back");
    }

    function testEmptyUnfinalizedStillSpendsDepositable() public {
        seed(80 ether, 50 ether, 0, 0);
        require(lido.getWithdrawalsReserve() == 0, "no queue");
        (bool ok,) = callWithdraw(address(router), 20 ether);
        require(ok, "spend with empty queue");
        require(lido.getWithdrawalsReserve() == 0, "still zero");
        Model memory model = runModel(modelJson(true, true, 20 ether, 80 ether, 50 ether, 0, 0, 0));
        require(model.ok && model.wrAfter == 0, "empty queue");
    }

    function testDuplicateCallerStillAuthOnce() public {
        seed(100 ether, 40 ether, 30 ether, 0);
        (bool ok1,) = callWithdraw(address(router), 5 ether);
        (bool ok2,) = callWithdraw(address(router), 5 ether);
        require(ok1 && ok2, "two spends");
        require(lido.getWithdrawalsReserve() == 30 ether, "WR twice");
    }

    function testMutantDroppedGuardDetected() public {
        seed(100 ether, 40 ether, 30 ether, 0);
        queue.setBunker(true);
        (bool honestOk,) = callWithdraw(address(router), 10 ether);
        require(!honestOk, "honest bunker");
        vm.prank(address(router));
        (bool mutantOk,) = address(lido).call(abi.encodeWithSignature("withdrawDroppedGuard(uint256,uint256)", 10 ether, 0));
        require(mutantOk, "dropped canDeposit");
    }

    function testMutantReversedOrderDetected() public {
        seed(100 ether, 40 ether, 30 ether, 0);
        (bool ok,) = callWithdraw(address(router), 10 ether);
        require(ok && router.bufferedAtPay() == 90 ether, "honest spend first");
        seed(100 ether, 40 ether, 30 ether, 0);
        vm.prank(address(router));
        (bool mok,) = address(lido).call(abi.encodeWithSignature("withdrawReversedOrder(uint256,uint256)", 10 ether, 0));
        require(mok && router.bufferedAtPay() == 100 ether, "mutant transfer first");
    }

    function testMutantWrongSlotDetected() public {
        seed(100 ether, 40 ether, 30 ether, 0);
        require(lido.readDummySlot() == 0, "clean");
        (bool ok,) = callWithdraw(address(router), 10 ether);
        require(ok && lido.readDummySlot() == 0, "honest no dummy");
        seed(100 ether, 40 ether, 30 ether, 0);
        vm.prank(address(router));
        (bool mok,) = address(lido).call(abi.encodeWithSignature("withdrawWrongSlot(uint256,uint256)", 10 ether, 0));
        require(mok && lido.readDummySlot() == 10 ether, "wrong slot write");
    }

    function testBelowStoredReserveShrinksStoredOnly() public {
        seed(100 ether, 40 ether, 30 ether, 0);
        (bool ok,) = callWithdraw(address(router), 15 ether);
        require(ok, "partial stored");
        // stored 40-15=25; WR still 30
        require(lido.getDepositsReserve() == 25 ether, "capped stored");
        require(lido.getWithdrawalsReserve() == 30 ether, "WR");
        Model memory model = runModel(modelJson(true, true, 15 ether, 100 ether, 40 ether, 30 ether, 0, 0));
        require(model.ok && model.storedDepositsReserve == 25 ether, "model stored");
    }
}
