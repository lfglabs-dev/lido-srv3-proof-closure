# Solidity Correspondence Register

Pinned source: `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

This register explains how the executable `LidoSRv3` Verity/Lean model tracks
the SRv3 Solidity slice. The target is line-shaped fidelity for economic state
transitions, while explicitly abstracting implementation plumbing that is not a
conservation law.

Re-pin note: this register was originally derived against
`d088bbc2deac9913b68036d73d35c37aa6279b90` and re-derived against
`af095e48bbc1c3841c2c9936219c8461af01056b` (315 commits later on the PR #1811
branch, absorbing the Statemind/audit-response fixes from PR #1818/#1820/#1823/
#1824). The semantic deltas absorbed into the model are called out inline
below; refactor-only and event/natspec-only changes are not enumerated.

## Deposit

Source: `contracts/0.8.25/sr/StakingRouter.sol:942-997`.

Model: `LidoSRv3/Model.lean::depositTransition`.

Line correspondence:

- `943`: authorization is an assumption, not modeled state.
- `944-946`: module lookup and active-status guard are modeled by `find?` and
  `m.status = ModuleStatus.active`.
- `948-949`: withdrawal credential bytes and module address are plumbing
  assumptions.
- `951-953`: `getDepositableEther` and `_getModuleDepositAllocation` are modeled
  as `depositableEther s` and the explicit `moduleAllocationWei` parameter.
- `954-958`: `maxDepositsCount` is modeled by `depositMaxCount`, using the
  per-block limit and `allocation / 32 ETH`. **Delta at `af095e48`** (PR #1824
  / commit `185965ea`): the additional `depositableValidatorsCount` cap present
  at `d088bbc2` was removed from the Solidity min-expression; the model's
  `depositMaxCount` drops the same term. The module-side depositable-key
  capacity is now enforced only inside `obtainDepositData` (assumption
  A-MOD-07).
- `960`: zero computed capacity rejects.
- `962-964`: `obtainDepositData` is the explicit `actualDeposits` interface
  input.
- `966-970`: pubkey byte divisibility is abstracted; the resulting
  `actualDeposits <= maxDepositsCount` guard is modeled.
- `973-977`: `depositsValue = actualDeposits * 32 ETH` and last-deposit state
  update are modeled by `depositPullWei` and `recordModuleLastDeposit`.
- `979`: zero-key return preserves ETH-side state while keeping the last-deposit
  accounting update.
- `981-997`: the Lido pull and beacon deposit sink are modeled as an exact
  value transfer: buffer and stored deposit reserve decrease by `depositsValue`,
  beacon sink increases by `depositsValue`, and router ETH balance is unchanged.

Lido reserve source:
`contracts/0.4.24/Lido.sol:605-616`, `823-859`, `869-886`, `1125-1132`.

- `_getBufferedEtherAllocation` is modeled by `depositReserveUsed`,
  `withdrawalReserveUsed`, `unreservedEther`, and `depositableEther`.
- `_spendDepositableEther` line `842` is modeled as the spend precondition.
- `_spendDepositableEther` lines `844-858` are modeled as buffer decrease and
  stored deposit reserve decrease, saturating at zero through natural-number
  subtraction.
- `withdrawDepositableEther` line `870` (`require(canDeposit(), ...)`) is the
  Lido protocol deposit gate; on the positive-amount path it stays inside the
  A-LIDO-06 interface boundary. The same gate surfaces as modeled state on the
  top-up zero-target path (see Top-Up below).
- `withdrawDepositableEther` line `885` is modeled as the router receiving the
  requested amount before immediately sinking it into the beacon deposit model.
- `_updateBufferedEtherAllocation` lines `1125-1132`. **Delta at `af095e48`**
  (commit `23a77a61`): the report-time reserve sync condition changed from
  `depositsReserve != depositsReserveTarget` to
  `depositsReserve < depositsReserveTarget`, so the sync now only raises the
  stored reserve toward the target; lowering happens immediately in
  `_setDepositsReserveTarget`. The P1 theorems are a static partition law over
  the stored reserve values and hold under either write discipline; the change
  narrows when the stored value is rewritten, not the partition itself.

## Top-Up

Source: `contracts/0.8.25/sr/StakingRouter.sol:679-759` (with
`_validateTopUpInputs` at `761-782` and the per-block cap
setter/getter at `1019-1034`).

Model: `LidoSRv3/Model.lean::topUpTransition`.

Line correspondence:

- `686`: gateway authorization is an assumption.
- `687` / `761-782`: input shape is modeled by nonempty/equal key, operator,
  pubkey, and limit lengths.
- `689-694`: module lookup, active status, and WC02 capability are modeled by
  `find?`, `ModuleStatus.active`, and `supportsTopUp`.
- `696-706`: **Delta at `af095e48`** (PR #1820): the module target allocation
  is now capped by the router-global per-block top-up limit before Gwei
  rounding: `Math.min(_getModuleDepositAllocation(...), maxTopUpPerBlockWei)`
  followed by rounding. The model captures this as
  `topUpTargetWei moduleAllocationWei maxTopUpPerBlockGwei =
  roundDownToGwei (min moduleAllocationWei (maxTopUpPerBlockGwei * 1 gwei))`,
  with `maxTopUpPerBlockGwei` an explicit transition input. New theorem
  `P8_topup_transition_respects_per_block_cap` checks the resulting bound.
- `708-715`: **Delta at `af095e48`**: when the capped, rounded target is zero
  the queue-advancement call is gated on `LIDO.canDeposit()`
  (`LidoDepositsPaused` otherwise). The model represents the gate through the
  explicit `lidoCanDeposit` interface input; new theorem
  `P8_topup_transition_zero_target_requires_lido_can_deposit` checks it.
- `717-718`: module allocation is the explicit `allocations` interface result
  (`IStakingModuleV2.allocateDeposits`).
- `720-734`: the returned allocation loop is modeled over arbitrary finite
  arrays: Gwei alignment, per-key limit checks, and sum accumulation. A return
  longer than the request rejects because `_topUpLimits[i]` is out of bounds.
- `736-739`: returned sum must not exceed the capped, rounded module target.
- `741-750` plus
  [`BeaconChainDepositor.sol:66-75`](https://github.com/lidofinance/core/blob/af095e48bbc1c3841c2c9936219c8461af01056b/contracts/0.8.25/lib/BeaconChainDepositor.sol#L66-L75):
  a short positive return rejects on pubkeys/amounts length mismatch, whereas a
  short zero-sum return may succeed because the helper call is skipped.
- `741-756`: successful positive sums pull exact depositable ETH, reduce the Lido buffer
  and stored deposit reserve, increase the beacon top-up sink by the same
  amount, and preserve router ETH balance.
- `758`: the `StakingRouterETHTopUp` event is out of lane.
- `1019-1034`: `setMaxTopUpPerBlockGwei` validation (positive, uint64-bounded)
  and storage are governance configuration (A-GOV-14); the model takes the
  configured value as a transition input.

## Allocation And Capacity

Source: `contracts/0.8.25/sr/SRLib.sol:493-559`.

Model: `LidoSRv3/Model.lean::modulesAllocationAndCapacity`.

The model keeps the two Solidity loops: first it builds current allocation rows
and a cache, then it computes capacity rows. It preserves router module order,
WC01 active-validator count, WC02 `ceil(totalModuleStake / maxEBType1)`,
inactive-module capacity equal to current allocation, active initial-deposit
capacity bounded by depositable validators and target share, and active WC02
top-up capacity bounded by scaled active validators and target share. The
external MinFirst strategy after these rows is an assumption. (The `af095e48`
change to this loop — initializing the running total with
`depositsToAllocate` instead of adding it after the loop — is arithmetically
identical and needs no model change.)

## Reports And Rewards

Sources:

- `contracts/0.8.25/sr/SRLib.sol:854-892`
- `contracts/0.8.25/sr/StakingRouter.sol:808-874`
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

Oracle-side note at `af095e48`: `AccountingOracle.ReportData` now documents
`stakingModuleIdsWithUpdatedBalance` as the ids of *all* staking modules in
router order (previously: only modules with changed balances), and the exited
sanity check moved to `checkExitedValidatorsCount`. The model's
`reportWellFormed` already required full router-order coverage
(`reportIds r = moduleIds s.modules`), so the clarified oracle semantics match
the modeled precondition exactly; A-ORC-03 is unchanged.

## Module Management

Sources:

- `contracts/0.8.25/sr/SRLib.sol:183-233`
- `contracts/0.8.25/sr/SRLib.sol:248-290`
- `contracts/0.8.25/sr/SRLib.sol:307-336`
- `contracts/0.8.25/sr/SRLib.sol:342-359`
- `contracts/0.8.25/sr/SRLib.sol:363-370`

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

Deltas at `af095e48`:

- `_updateModuleParams` (SRLib `271-273`) now rejects a zero
  `maxDepositsPerBlock` (`InvalidMaxDepositPerBlockValue`); the model adds the
  matching `maxDepositsPerBlock != 0` guard to `singleModuleParamsValid`
  (shared by the add-module path) and new theorem
  `P12_update_module_params_requires_positive_max_deposits` checks the
  precondition.
- `_setModuleStatus` (SRLib `363-370`) now reverts inside the library with
  `StakingModuleStatusTheSame` instead of returning `bool` to the router
  wrapper. Externally the rejection behavior is identical; the model's
  `updateModuleStatusTransition` (which already returned `none` on an unchanged
  status) needs no change.

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
- The router-global per-block top-up cap and the Lido protocol deposit gate
  (`canDeposit`) are modeled as explicit transition inputs; their governance
  configuration and Lido-side truthfulness are interface assumptions.
- Oracle reports are accepted inputs satisfying named validation assumptions;
  the proofs start after off-chain truth has been accepted.
- SSZ, Merkle, BLS, EIP-4788, proxy mechanics, packed-storage equivalence,
  governance authorization, gas behavior, events, revert strings, and exact
  call-stack behavior remain trust assumptions or later work.
- Finite arrays and loops are modeled over arbitrary Lean lists, so the checked
  properties are not bounded to a fixed number of modules or report rows.
