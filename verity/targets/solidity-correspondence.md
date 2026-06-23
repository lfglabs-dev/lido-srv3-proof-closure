# Solidity Correspondence Register

Pinned source: `lidofinance/core@d088bbc2deac9913b68036d73d35c37aa6279b90`.

This register explains how the executable `LidoSRv3` Verity/Lean model tracks
the SRv3 Solidity slice. The target is line-shaped fidelity for economic state
transitions, while explicitly abstracting implementation plumbing that is not a
conservation law.

## Deposit

Source: `contracts/0.8.25/sr/StakingRouter.sol:922-980`.

Model: `LidoSRv3/Model.lean::depositTransition`.

Line correspondence:

- `923`: authorization is an assumption, not modeled state.
- `924-927`: module lookup and active-status guard are modeled by `find?` and
  `m.status = ModuleStatus.active`.
- `928-930`: withdrawal credential bytes and module address are plumbing
  assumptions.
- `931-934`: `getDepositableEther` and `_getModuleDepositAllocation` are modeled
  as `depositableEther s` and the explicit `moduleAllocationWei` parameter.
- `935-940`: `maxDepositsCount` is modeled by `depositMaxCount`, using
  per-block limit, depositable validators, and `allocation / 32 ETH`.
- `942`: zero computed capacity rejects.
- `944-946`: `obtainDepositData` is the explicit `actualDeposits` interface
  input.
- `948-952`: pubkey byte divisibility is abstracted; the resulting
  `actualDeposits <= maxDepositsCount` guard is modeled.
- `954-959`: `depositsValue = actualDeposits * 32 ETH` and last-deposit state
  update are modeled by `depositPullWei` and `recordModuleLastDeposit`.
- `961`: zero-key return preserves ETH-side state while keeping the last-deposit
  accounting update.
- `963-979`: the Lido pull and beacon deposit sink are modeled as an exact
  value transfer: buffer and stored deposit reserve decrease by `depositsValue`,
  beacon sink increases by `depositsValue`, and router ETH balance is unchanged.

Lido reserve source:
`contracts/0.4.24/Lido.sol:603-614`, `819-845`, `856-872`.

- `_getBufferedEtherAllocation` is modeled by `depositReserveUsed`,
  `withdrawalReserveUsed`, `unreservedEther`, and `depositableEther`.
- `_spendDepositableEther` line `830` is modeled as the spend precondition.
- `_spendDepositableEther` lines `834-845` are modeled as buffer decrease and
  stored deposit reserve decrease, saturating at zero through natural-number
  subtraction.
- `withdrawDepositableEther` line `872` is modeled as the router receiving the
  requested amount before immediately sinking it into the beacon deposit model.

## Top-Up

Source: `contracts/0.8.25/sr/StakingRouter.sol:672-735`.

Model: `LidoSRv3/Model.lean::topUpTransition`.

Line correspondence:

- `679`: gateway authorization is an assumption.
- `680`: input shape is modeled by nonempty/equal key, operator, pubkey, and
  limit lengths.
- `682-687`: module lookup, active status, and WC02 capability are modeled by
  `find?`, `ModuleStatus.active`, and `supportsTopUp`.
- `689-700`: module target allocation is the explicit `moduleAllocationWei`
  parameter; Gwei rounding is modeled by `roundDownToGwei`; module allocation is
  the explicit `allocations` interface result.
- `702-716`: the returned allocation loop is modeled over arbitrary finite
  arrays: Gwei alignment, per-key limit checks, and sum accumulation.
- `718-721`: returned sum must not exceed the rounded module target.
- `723-735`: positive sums pull exact depositable ETH, reduce the Lido buffer and
  stored deposit reserve, increase the beacon top-up sink by the same amount,
  and preserve router ETH balance.

## Allocation And Capacity

Source: `contracts/0.8.25/sr/SRLib.sol:492-559`.

Model: `LidoSRv3/Model.lean::modulesAllocationAndCapacity`.

The model keeps the two Solidity loops: first it builds current allocation rows
and a cache, then it computes capacity rows. It preserves router module order,
WC01 active-validator count, WC02 `ceil(totalModuleStake / maxEBType1)`,
inactive-module capacity equal to current allocation, active initial-deposit
capacity bounded by depositable validators and target share, and active WC02
top-up capacity bounded by scaled active validators and target share. The
external MinFirst strategy after these rows is an assumption.

## Reports And Rewards

Sources:

- `contracts/0.8.25/sr/SRLib.sol:853-892`
- `contracts/0.8.25/sr/StakingRouter.sol:788-875`
- `contracts/0.8.25/sr/SRLib.sol:620-639`
- `contracts/0.8.25/sr/SRLib.sol:743-790`

Models:

- `reportValidatorBalancesTransition`
- `stakingRewardsDistributionRows`
- `reportRewardsMintedTransition`
- `updateExitedValidatorsTransition`

The validator-balance report model preserves full length checks, router-order
module ID alignment, Gwei range validation, row-by-row module balance writes,
and router aggregate update. Rewards preserve the zero-total empty path,
zero-balance row skipping, module-recipient alignment, high-precision share
formula, stopped-module zero paid module fee, and total-fee row sum. Reward
minted reporting preserves equal-length validation, zero-share skip before
module existence checks, and row order. Exited-count reporting preserves the
sequential loop, including duplicate module IDs seeing prior row updates.

## Module Management

Sources:

- `contracts/0.8.25/sr/SRLib.sol:184-233`
- `contracts/0.8.25/sr/SRLib.sol:249-289`
- `contracts/0.8.25/sr/SRLib.sol:306-335`
- `contracts/0.8.25/sr/SRLib.sol:341-358`
- `contracts/0.8.25/sr/SRLib.sol:362-369`

Models:

- `addModuleTransition`
- `updateModuleParamsTransition`
- `updateAllModuleFeesTransition`
- `updateAllModuleSharesTransition`
- `updateModuleStatusTransition`

The model keeps share guards, fee-sum guards, same-sum consistency, uint64
deposit-parameter bounds, router-order update loops, fresh-module append, zero
initial accounting for new modules, and status updates. It abstracts address
registration, string validation, role checks, event emission, packed storage,
and exact cast encoding.

## Explicit Abstractions

The pilot abstracts plumbing, not conservation laws:

- External contracts are modeled through interfaces stating inputs, outputs, and
  allowed SRv3 state effects.
- Lido buffer withdrawal makes a specific amount available to the router while
  reducing the buffer and stored deposit reserve; it does not consume
  withdrawal-reserved ETH.
- The beacon deposit contract is a value sink. Initial deposits remove exactly
  `n * 32 ETH`; top-ups remove exactly the returned allocation sum.
- Staking modules expose only the state SRv3 reads: status, validator balances,
  deposit/top-up interfaces, accounting counters, fee/share config, and reward
  recipient.
- Oracle reports are accepted inputs satisfying named validation assumptions;
  the proofs start after off-chain truth has been accepted.
- SSZ, Merkle, BLS, EIP-4788, proxy mechanics, packed-storage equivalence,
  governance authorization, gas behavior, events, revert strings, and exact
  call-stack behavior remain trust assumptions or later work.
- Finite arrays and loops are modeled over arbitrary Lean lists, so the checked
  properties are not bounded to a fixed number of modules or report rows.
