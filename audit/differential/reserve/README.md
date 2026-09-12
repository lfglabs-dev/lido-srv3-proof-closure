# RESERVE-1 Solidity ↔ Verity differential

CLAIM: grok owns lido-differential-reserve-1 since 2026-09-12

Pinned Solidity `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
Registered parent exposed: `modelWithdrawDepositableEther`.

## Status

BLOCKED: model divergence

The harness is green. A committed spend of depositable ether leaves the
withdrawals slice unchanged on both sides. Several wrapper and runtime
observables are not in the registered parent.

## Divergences (model obligations)

Existing proof files were not edited.

### D-TRANSFER-1 — router value transfer

Pinned `Lido.sol:885` `stakingRouter.receiveDepositableEther.value(_amount)()`.
`modelWithdrawDepositableEther` updates reserve words only.

Obligation: journal the payable CALL (target, value, selector, order
after the spend writes).

### D-WQ-FIELD-1 — `unfinalizedStETH` is a stored word

Pinned `_getBufferedEtherAllocation` (`:612`) STATICALLs
`WithdrawalQueue.unfinalizedStETH()`. The parent reads
`ReserveState.unfinalizedStETH`. `ReserveUnfinalizedCall` is additive and
is not this CLI parent.

Obligation: take a live STATICCALL observation as the `unfinalized`
input of `modelWithdrawDepositableEther`.

### D-SLOT-1 — model slots 0–4

Verity storage is `buffered` / `storedDepositsReserve` /
`unfinalizedStETH` / `depositedPostReport` /
`depositedNextReportAdjusted` at slots 0–4. The pin uses keccak
unstructured positions (`BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION`,
`DEPOSITS_RESERVE_POSITION`, …) and a packed uint128 pair for buffer +
post-report.

Obligation: bind the keccak positions and the packed layout.

### D-OVERFLOW-STRING-1

SafeMath `.add` at `:846` reverts without the model string
`DEPOSITED_POST_REPORT_OVERFLOW`. The four live wrapper strings
(`CAN_NOT_DEPOSIT`, `APP_AUTH_FAILED`, `ZERO_AMOUNT`, `NOT_ENOUGH_ETHER`)
match.

### D-PACK-1 — uint128 packed post-report

The pin packs `buffered` and `depositedPostReport` as two uint128s
(`Lido.sol:131-132`). A seeded `depositedPostReport = uint128.max`
plus a 1-ether spend still fits `uint256` SafeMath, so the model
commits `uint128.max + 1 ether`. The pin's 0.4.24 `<< 128` wraps the
high half. Withdrawals reserve still holds. The registered parent
cannot see the pack wrap.

### D-SEED-1 / D-EVENT-1

`_seedDepositsCount` bookkeeping (`:877-882`) and `Unbuffered` /
`DepositedPostReportUpdated` are omitted.

### D-WRAP-1

Allocation helper raw `remaining -=` is 0.4.24 unchecked wrap. The model
uses `safeSub` and treats overflow as `ALLOCATION_ARITHMETIC`. The `min`
bounds make that branch unreachable on the vectors here.

## Solidity-side finding

None. Withdrawals reserve is unchanged on committed depositable spends
and on `NOT_ENOUGH_ETHER` / router-fail rollbacks. The pin does not raid
the withdrawals slice. Thomas: no pin bug to escalate.

## Vectors

Nominal 10 ETH spend (WR preserved); zero amount; unauthorized caller;
bunker `CAN_NOT_DEPOSIT`; amount above depositable; exact depositable
cap (only WR left); stored-reserve zero (unreserved only); packed post-report wrap (D-PACK-1); router fail after spend (full rollback); empty
unfinalized; two sequential spends; stored-reserve shrink; Solidity
mutants (dropped `canDeposit`, transfer-before-spend, dummy slot write).

The pinned `Lido` is Solidity 0.4.24. Foundry 1.8 does not resolve that
compiler, so `scripts/compile_reserve_pin.sh` builds
`ReserveHarness` (inherits the pin) with `solc 0.4.24` and the test
`create`s that bytecode. The pin file under `lido-core` is not edited.

## Recheck

```
bash scripts/test_reserve_source_differential.sh
lake build LidoSRv3.Audit.Verity.ReserveSourceEntry
bash scripts/compile_reserve_pin.sh
FOUNDRY_PROFILE=reserve_source forge test --ffi --match-contract ReserveDifferentialTest -vv
```
