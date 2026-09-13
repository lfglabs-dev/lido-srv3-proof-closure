# DEPOSIT-1 Solidity ↔ Verity differential

CLAIM: grok owns lido-differential-deposit-1 since 2026-09-12

Pinned Solidity `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
Registered parent exposed: `DepositNFrameTx.execute`.

## Status

BLOCKED: model divergence

The harness is green: it deploys the pinned `StakingRouter`, runs the
registered Verity transaction, and records every mismatch instead of
hiding it. Conservation on a conserving deployment agrees. Call journal,
revert encoding, empty-batch control flow, and the maxEB / `DEPOSIT_SIZE`
split do not.

## What the harness compares

| Observable | Source | Model |
| --- | --- | --- |
| commit / revert class | custom error or Panic | model string |
| pulled / pushed wei | Lido withdraw + beacon `deposit` values | `lidoDepositable` delta + `depositToBeacon` values |
| router balance | `address(router).balance` | `selfBalance` |
| external calls | target / value / name / order | `ContractState.calls` |
| events | `StakingRouterETHDeposited`, `DepositableEthReceived`, beacon `DepositEvent` | none |
| storage words | ERC-7201 module deposits + OZ roles | observation slots 0–4 |

## Divergences (model obligations)

These are bugs of `DepositNFrameTx` relative to the pinned source. Existing
proof files are out of scope and were not edited.

### D-CALL-1 — journal shape

Pinned `deposit` journals `obtainDepositData(maxDepositsCount, calldata)`,
then `withdrawDepositableEther(depositsValue, actualDepositsCount)`, then
one `IDepositContract.deposit{value: 32 ether}` per key.

The model journals `obtainDepositData(moduleId, keys)`,
`withdrawDepositableEther(total)` with a single argument, then one
`depositToBeacon` frame per batch carrying `keys * depositSize`.

Obligation: rewrite `processBatch` / `pushBatch` so the executable journal
is the source schedule (per-key 32 ETH `deposit`, two-argument Lido pull).

### D-REVERT-1 — revert encoding

Source uses custom errors (`NotAuthorized()`, `StakingModuleNotActive()`,
`ZeroDeposits()`, `WrongPubkeyLength()`, `ModuleReturnExceedTarget()`) or
`Panic(0x01)`. The model uses strings (`NOT_AUTHORIZED`, `MODULE_NOT_ACTIVE`,
`INVALID_ALLOCATION`, …).

Obligation: emit the source selector (and Panic payload) instead of a
model name.

### D-EMPTY-PULL — empty key batch

Source returns at `StakingRouter.sol:978` after
`_updateModuleLastDepositState` and never calls Lido. The model still
runs `pullFromLido` with total 0.

Obligation: take the line-978 early return before the pull.

### D-SKEW-1 — `maxEBType1 ≠ DEPOSIT_SIZE`

Source pull is `actualDepositsCount * MAX_EFFECTIVE_BALANCE_WC_TYPE_01`
and the beacon loop always sends `DEPOSIT_SIZE = 32 ether`. A skewed
constructor hits the line-996 assert.

The model has a single `depositSize` used both as the
`ALLOCATION_VALUE_MISMATCH` check and as the push amount, so it cannot
express that split. On the skewed witness it reverts
`ALLOCATION_VALUE_MISMATCH` rather than `Panic(0x01)` after a 64/32 move.

Obligation: separate the constructor immutable from
`BeaconChainDepositor.DEPOSIT_SIZE` and keep the line-996 assert.

### D-SLOT-1 — storage identity

Model slots 0–4 are observation cells. Source writes ERC-7201
`ModuleState.deposits` and emits `StakingRouterETHDeposited`.

Obligation: use the source storage positions if the journal is to be
compared word-for-word.

### D-NFRAME-1 — list vs one module

Pinned `deposit` admits one module per call. `DepositNFrameTx` is a list
lift. Duplicate `moduleId`s are a `Preconditions` premise, not an
`execute` guard.

## Solidity-side finding

None. On a conserving deployment (`maxEBType1 = 32 ether`) the pin
conserves pulled = pushed. The skewed constructor reverts at the assert.
That matches `audit/P-DEPOSIT-1.md` / `report/P-DEPOSIT-1.md`.

## Vectors

Nominal two-key conserving deposit; empty keys; unauthorized caller;
paused module; unregistered module; `ZeroDeposits`; exact
`maxDepositsPerBlock` cap; bad pubkey length; module return above target;
model-only word overflow; duplicate module ids; Lido failure after the
module call; skewed maxEB assert; Solidity mutants (dropped assert,
reversed pull/push, wrong last-deposit slot).

## Recheck

```
bash scripts/test_deposit_source_differential.sh
lake build LidoSRv3.Audit.Verity.DepositSourceEntry
FOUNDRY_PROFILE=deposit_source forge test --ffi --match-contract DepositDifferentialTest -vv
```
