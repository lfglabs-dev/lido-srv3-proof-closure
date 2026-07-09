# Verity Targets

The executable SRv3 model lives in `LidoSRv3/` as Lean files checked through the
pinned Verity dependency in `lakefile.lean`.

For source fidelity, see `targets/solidity-correspondence.md`; it maps the
modeled transitions to pinned Solidity line ranges and names the deliberate
abstractions.

The model covers:

- `StakingRouter.deposit`
- `StakingRouter.topUp`
- `SRLib._getModulesAllocationAndCapacity`
- `SRLib._updateAllModuleFees`
- `SRLib._updateModuleShares`
- `SRLib._updateModuleParams`
- `SRLib._setModuleStatus`
- `SRLib._addModule`
- deposit reserve and withdrawal reserve separation
- module balances and `validatorsBalanceGwei`
- accepted balance reports
- exited-validator count updates
- `getStakingRewardsDistribution`
- `reportRewardsMinted`
- all-module fee update validation
- all-module share update validation
- single-module config update validation
- module-status update validation
- module-addition validation
- active, deposits-paused, and stopped status gating
- Wei/Gwei and basis-point integer rounding

## Abstraction Boundary

The current `StakingRouter.deposit` model follows the Solidity control-flow
order for the accounting-relevant lines:

1. Require the selected module to exist and be active.
2. Compute `maxDepositsCount` from module capacity, per-block limit, and the
   allocated ETH divided by 32 ETH.
3. Treat `IStakingModule.obtainDepositData` as an explicit interface returning
   `actualDeposits`; pubkey/signature bytes and BLS validity stay outside this
   model.
4. Record the module last-deposit accounting before the zero-key return, matching
   the Solidity update order.
5. Model `LIDO.withdrawDepositableEther` as providing exactly
   `32 ETH * actualDeposits` when the depositable-buffer premise holds.
6. Model `BeaconChainDepositor.makeBeaconChainDeposits32ETH` as a value sink
   receiving exactly that pulled amount.
7. Prove total modeled allocated deposits is the finite sum of per-module
   allocated deposits.
8. Prove the router ETH balance is unchanged after every successful modeled
   deposit transition.
9. Prove every successful nonzero deposit had enough depositable ETH for the
   modeled Lido buffer pull.
10. Prove successful nonzero deposits reduce buffered ETH by exactly the pulled
   `32 ETH * actualDeposits` amount.
11. Prove successful zero-deposit transitions do not change modeled buffered ETH
    or the beacon sink while still recording last-deposit accounting.
12. Prove the withdrawal-reserved bucket is unchanged after every successful
   modeled deposit transition.
13. Prove every successful deposit used an existing active module and a nonzero
   computed capacity, with actual deposits no larger than that capacity.
14. Prove every successful deposit updates the module array exactly with
    `recordModuleLastDeposit stakingModuleId (32 ETH * actualDeposits)`.
15. Prove every successful deposit records the selected module last-deposit
    value as exactly `32 ETH * actualDeposits`, including the zero-key return.
16. Prove every successful deposit preserves router module-array length while
    recording that last-deposit accounting.
17. Prove that last-deposit accounting preserves the router-stored module
    validator-balance sum.
18. Prove successful deposits do not mutate router report accounting: the router
    validator-balance aggregate and last accepted report.
19. Prove the stored deposit-reserve bucket is decreased by the exact positive
    spend amount, saturating at zero, after every successful nonzero modeled
    deposit transition.

The current `StakingRouter.topUp` model follows the accounting-relevant
array-and-loop structure for top-ups:

1. Require nonempty, equal-length key/operator/limit/pubkey inputs.
2. Require the selected module to be active and top-up capable.
3. Round the module allocation down to a Gwei boundary before calling the module.
4. Treat `IStakingModuleV2.allocateDeposits` as an explicit interface returning
   one allocation per key.
5. Check returned allocations are Gwei-aligned and do not exceed per-key limits.
6. Check the allocation sum does not exceed the rounded module target.
7. Prove every successful top-up allocation sum stays within the module
   allocation budget before rounding.
8. Model positive top-up pulls through `LIDO.withdrawDepositableEther` and
   `BeaconChainDepositor.makeBeaconChainTopUp` as an exact value sink.
9. Prove the router ETH balance is unchanged after every successful modeled
   top-up transition.
10. Prove successful top-ups do not mutate router module accounting.
11. Prove successful top-ups do not mutate router report accounting: the router
    validator-balance aggregate and last accepted report.
12. Prove the withdrawal-reserved bucket is unchanged after every successful
   modeled top-up transition.
13. Prove successful nonzero top-ups reduce buffered ETH by exactly the returned
    allocation sum.
14. Prove every successful nonzero top-up had enough depositable ETH for the
    modeled Lido buffer pull.
15. Prove every successful zero-allocation top-up returns the unchanged state
    after validation.
16. Prove the stored deposit-reserve bucket is decreased by the exact positive
    allocation sum, saturating at zero, after every successful nonzero modeled
    top-up transition.

The current allocation-capacity model follows the SRv3-owned loop in
`SRLib._getModulesAllocationAndCapacity`:

1. Build one current-allocation row per router module.
2. Preserve router module id order in the returned allocation-capacity rows.
3. Use active validator count for WC01-style modules.
4. Use `ceil(totalModuleStake / maxEBType1)` for WC02-style modules.
5. Add the requested deposit count to compute the post-allocation total used for
   target-share capacity.
6. For inactive modules, keep capacity equal to current allocation.
7. For active modules, bound capacity by both target share and available module
   capacity.
8. For WC02 top-up capacity, use active validators scaled by
   `maxEBType2 / maxEBType1`.

The current reward-minted reporting model follows the SRv3-owned loop in
`SRLib._reportRewardsMinted`:

1. Require equal `_stakingModuleIds` and `_totalShares` array lengths.
2. Build one report row per zipped calldata pair.
3. Preserve module-id and total-share order exactly in returned row projections.
4. Skip zero-share rows before checking module existence.
5. Require every nonzero-share row to name an existing router module.
6. Abstract `IStakingModule.onRewardsMinted` callback effects, revert bytes,
   event emission, and gas-estimation behavior behind the named module-callback
   trust boundary.

The current all-module fee-update model follows the SRv3-owned loop in
`SRLib._updateAllModuleFees`:

1. Require the module-fee and treasury-fee arrays to match router module count.
2. Return successfully on the empty-module case.
3. Use row 0 as the expected fee sum when modules are present.
4. Require every row sum to be at most `TOTAL_BASIS_POINTS`.
5. Require every row sum to equal the expected fee sum.
6. Update every module's `moduleFeeBps` and `treasuryFeeBps` in router order.
7. Prove the updated module-fee and treasury-fee projections exactly equal the
   supplied arrays.
8. Preserve non-module router state, including ETH accounting, report balance,
   and the last accepted report.

The current all-module share-update model follows the SRv3-owned loop in
`SRLib._updateModuleShares`:

1. Require the stake-share-limit and priority-exit-threshold arrays to match
   router module count.
2. Validate every row with the same stake-share and priority-exit ordering guard
   used by single-module config updates.
3. Update every module's `stakeShareLimitBps` and
   `priorityExitShareThresholdBps` in router order.
4. Prove the updated stake-share and priority-exit projections exactly equal
   the supplied arrays.
5. Preserve router module-list length.
6. Preserve the router-stored module validator-balance sum.
7. Preserve non-module router state, including ETH accounting, report balance,
   and the last accepted report.

The current single-module config-update model follows the accounting-relevant
guards in `SRLib._updateModuleParams`:

1. Require the selected module id to exist.
2. Validate stake-share limit, priority-exit share threshold, and their order.
3. Require the new module-plus-treasury fee sum to fit within
   `TOTAL_BASIS_POINTS`.
4. Require every other module to have the same fee sum.
5. Require nonzero `minDepositBlockDistance` and uint64 bounds for deposit
   distance and max deposits per block.
6. Update the selected module's share, fee, and deposit-distance fields without
   changing router module-list length.
7. Prove the selected module lookup in the post-state records exactly the
   requested share, fee, and deposit-distance fields.
8. Preserve non-module router state, including ETH accounting, report balance,
   and the last accepted report.

The current module-status update model follows the accounting-relevant path in
`SRLib._setModuleStatus`:

1. Require the selected module id to exist.
2. Reject unchanged public status updates.
3. Update only the router-stored status field for matching module ids.
4. Prove the selected module lookup in the post-state records the requested
   status.
5. Preserve router module-list length.
6. Preserve the sum of router-stored module validator balances.
7. Preserve non-module router state, including ETH accounting, report balance,
   and the last accepted report.

The current module-addition model follows the accounting-relevant path in
`SRLib._addModule`:

1. Require the new module id to be fresh.
2. Reuse the share, fee-sum, consistency, nonzero deposit-distance, and uint64
   bounds from single-module config validation.
3. Append exactly `newModuleFromConfig` for the accepted config in router order.
4. Initialize accounting fields to zero.
5. Preserve the sum of router-stored module validator balances.
6. Preserve non-module router state, including ETH accounting, report balance,
   and the last accepted report.

The proof intentionally abstracts implementation plumbing rather than
conservation laws. Authorization, calldata packing, withdrawal credential byte
encoding, event emission, revert strings, gas behavior, and exact call-stack
shape are trust-boundary facts. Staking modules are represented only by the
fields SRv3 reads in this lane: status, depositable validator count, per-block
limit, last-deposit accounting, validator balance, deposited-validator count,
router-stored exited-validator count, stake-share limit, priority-exit share
threshold, max deposits per block, minimum deposit block distance, total module
stake, module and treasury fee basis points, and reward recipient, plus whether
the module supports WC-type-2 top-ups.
Oracle reports enter as accepted inputs satisfying the named alignment and range
assumptions. The module-balance report transition explicitly checks array
length, router module-order alignment, and the SRv3 Gwei range before applying
the update loop, writes the accepted balances exactly into the module balance
fields, proves the post-state module array is exactly the update-loop result,
preserves module-array length and ETH-side state after the loop, then stores
the exact accepted report for later reward reads.
The exited-count transition processes arbitrary finite row
arrays sequentially, including duplicate module IDs, and proves that every
successful row names an existing module, cannot decrease the router-stored
exited count, and cannot exceed the deposited-validator count returned by the
staking-module summary interface while preserving module-array length and the
router-stored module-balance sum. The transition wrapper returns exactly the
sequential loop result and preserves non-module router state; the empty update
path is proved to return the unchanged state with zero newly exited validators. The
reward-distribution loop returns no rows and an empty module-id projection when
the router total validator balance is zero; otherwise it reads accepted
module balances, skips zero-balance modules, proves every emitted row has
nonzero validator balance, keeps row recipients aligned with the router module
array, computes module and treasury fees from the same precision share, and pays
stopped modules zero module-side fee while still proving total fee is the
row-wise module plus treasury fee sum. Memory
preallocation, array shrinking, Solidity casts, and the final total-fee
precision assertion remain explicit trust-boundary or arithmetic-domain facts.
The top-up model preserves returned allocation loops over arbitrary finite
arrays but abstracts gateway authorization, pubkey ownership, deposit-data-root
construction, dummy signature bytes, deposit-contract minimum amount checks, and
exact calldata/revert behavior.
The allocation-capacity model preserves SRv3's array construction and target
capacity bounds, while the external MinFirst allocation strategy and governance
admissibility of target limits remain named assumptions.
The reward-minted reporting model preserves the SRLib array length check,
returns one zipped row per module id, preserves both input arrays as row
projections, and keeps the zero-share skip and nonzero module-existence check,
while callback side effects and low-level revert handling remain named
assumptions.
The all-module fee-update model preserves SRLib's two-array length check,
consistent fee-sum validation, empty-module success case, and router-order
module-config update loop while leaving router-stored validator-balance sums
unchanged and preserving non-module router state; governance authorization,
calldata authorship, and events remain named assumptions.
The all-module share-update model preserves SRLib's two-array length check,
per-row share validation, router-order share-field update loop, module-list
length preservation, validator-balance sum preservation, and non-module router
state; governance authorization, calldata authorship, casts, storage packing,
and events remain named assumptions.
The single-module config-update model preserves SRLib's selected-module
existence check, share-parameter validation, fee-sum consistency with other
modules, uint64 deposit-parameter bounds, module-list length preservation, and
validator-balance sum preservation, and non-module router state; governance
authorization, storage packing, casts, and events remain named assumptions.
The module-status update model preserves SRLib's selected-module existence
check, unchanged-status rejection, status-field update, module-list length
preservation, validator-balance sum preservation, and non-module router state;
governance authorization, internal harness no-op behavior, storage packing, and
events remain named assumptions.
The module-addition model preserves SRLib's fresh-id check, config-validation
guards, exact one-row append behavior, active initial status, zero initial
accounting fields, validator-balance sum preservation, and non-module router
state; module contract registration, interface/address validation, locator
plumbing, governance authorization, storage packing, and events remain named
assumptions.
Consensus-layer truthfulness, BLS, SSZ, Merkle, EIP-4788, proxy mechanics,
packed-storage equivalence, and full governance configuration remain outside
this pilot unless promoted into scope.

The external Verity reference is pinned in `proofs/LOCKFILE.md` and
`lake-manifest.json`.

Run:

```sh
make test
make prove
```
