# SRV3-P15 Module-Share Update Consistency

## Source anchors

- `contracts/0.8.25/sr/StakingRouter.sol::updateStakingModulesShares`
- `contracts/0.8.25/sr/SRLib.sol::_updateModuleShares`
- `contracts/0.8.25/sr/SRTypes.sol::StakingModule`

## Lean artifacts

- `LidoSRv3/Model.lean::allModuleSharesValid`
- `LidoSRv3/Model.lean::updateAllModuleSharesInModules`
- `LidoSRv3/Model.lean::updateAllModuleSharesTransition`
- `LidoSRv3/SpecProofs.lean::P15_update_all_module_shares_requires_lengths`
- `LidoSRv3/SpecProofs.lean::P15_update_all_module_shares_requires_valid_rows`
- `LidoSRv3/SpecProofs.lean::P15_update_all_module_shares_preserves_module_length`
- `LidoSRv3/SpecProofs.lean::P15_update_all_module_shares_exact_share_projections`
- `LidoSRv3/SpecProofs.lean::P15_update_all_module_shares_preserves_module_balance_sum`
- `LidoSRv3/SpecProofs.lean::P15_update_all_module_shares_preserves_router_state`

## Checked statement

The modeled `_updateModuleShares` path succeeds only when the stake-share-limit
and priority-exit-threshold arrays both match router module count and every row
passes the share-parameter ordering guard. On success, it updates only the two
share fields for each module in router order, preserves module-list length, and
preserves the router-stored module validator-balance sum and non-module router
state.

In notation:

```text
successfulShareUpdate(s, p, M, M') => |s| = |M| and |p| = |M|
successfulShareUpdate(s, p, M, M') =>
  forall i. s_i <= p_i and p_i <= 10000
successfulShareUpdate(s, p, M, M') => |M'| = |M|
successfulShareUpdate(s, p, M, M') =>
  map(module.stakeShareLimitBps, M') = s
  map(module.priorityExitShareThresholdBps, M') = p
successfulShareUpdate(s, p, M, M') =>
  sum(validatorsBalanceGwei, M') = sum(validatorsBalanceGwei, M)
successfulShareUpdate(s, p, M, M') =>
  ETH accounting, router report balance, and lastAcceptedReport are unchanged
```

This makes all-module share changes part of the finite router-array model
instead of treating target-share configuration as static background state.

## Abstraction boundary

The proof keeps the SRv3-owned array length checks, per-row share validation,
router-order update loop, module-list length preservation, and balance-sum
preservation, and it checks that the share update does not alter ETH accounting,
router report balance, or the last accepted report. It abstracts governance role
authorization, calldata authorship, storage packing, casts, event emission,
revert strings, and exact call-stack behavior. Those facts remain named
governance and implementation-plumbing assumptions.

## Evidence status

SRV3-P15 Lean-checked, recorded in `proofs/logs/proof-report.json`.
