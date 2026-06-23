# SRV3-P13 Module-Status Update Consistency

## Source anchors

- `contracts/0.8.25/sr/StakingRouter.sol::setStakingModuleStatus`
- `contracts/0.8.25/sr/SRLib.sol::_setModuleStatus`
- `contracts/0.8.25/sr/SRTypes.sol::StakingModuleStatus`

## Lean artifacts

- `LidoSRv3/Model.lean::updateModuleStatusInModules`
- `LidoSRv3/Model.lean::updateModuleStatusTransition`
- `LidoSRv3/SpecProofs.lean::P13_update_module_status_requires_existing_module`
- `LidoSRv3/SpecProofs.lean::P13_update_module_status_preserves_module_length`
- `LidoSRv3/SpecProofs.lean::P13_update_module_status_preserves_module_balance_sum`
- `LidoSRv3/SpecProofs.lean::P13_update_module_status_requires_status_change`
- `LidoSRv3/SpecProofs.lean::P13_update_module_status_records_requested_status`
- `LidoSRv3/SpecProofs.lean::P13_update_module_status_preserves_router_state`

## Checked statement

The modeled public `_setModuleStatus` path succeeds only when the selected
module id exists and the requested status differs from the currently stored
status. On success it updates router-stored module status without changing the
router module-list length, the sum of router-stored module validator balances,
or non-module router state.

In notation:

```text
successfulStatusUpdate(m, status, M, M') => existsModule(m, M)
successfulStatusUpdate(m, status, M, M') => oldStatus(m) != status
successfulStatusUpdate(m, status, M, M') => statusOf(m, M') = status
successfulStatusUpdate(m, status, M, M') => |M'| = |M|
successfulStatusUpdate(m, status, M, M') =>
  sum(validatorsBalanceGwei, M') = sum(validatorsBalanceGwei, M)
successfulStatusUpdate(m, status, M, M') =>
  ETH accounting, router report balance, and lastAcceptedReport are unchanged
```

This connects the status-gating proofs to the governance-controlled transition
that changes a module's status while keeping validator-balance accounting
unchanged.

## Abstraction boundary

The proof keeps the SRv3-owned module lookup, unchanged-status rejection, status
write, module-list length preservation, balance-sum preservation, and unchanged
non-module router state. It abstracts role authorization, call authorship,
packed-storage representation, event emission, and internal harness no-op
behavior. Those facts are covered by the governance and implementation-plumbing
trust boundary rather than by this economic model.

## Evidence status

SRV3-P13 Lean-checked, recorded in `proofs/logs/proof-report.json`.
