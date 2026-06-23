# SRV3-P14 Module-Addition Consistency

## Source anchors

- `contracts/0.8.25/sr/StakingRouter.sol::addStakingModule`
- `contracts/0.8.25/sr/SRLib.sol::_addModule`
- `contracts/0.8.25/sr/SRLib.sol::_requireConsistentFeeSum`

## Lean artifacts

- `LidoSRv3/Model.lean::addModuleConfigValid`
- `LidoSRv3/Model.lean::newModuleFromConfig`
- `LidoSRv3/Model.lean::addModuleTransition`
- `LidoSRv3/SpecProofs.lean::P14_add_module_requires_valid_config`
- `LidoSRv3/SpecProofs.lean::P14_add_module_requires_fresh_module_id`
- `LidoSRv3/SpecProofs.lean::P14_add_module_preserves_config_guards`
- `LidoSRv3/SpecProofs.lean::P14_add_module_increments_module_length`
- `LidoSRv3/SpecProofs.lean::P14_add_module_appends_new_module_from_config`
- `LidoSRv3/SpecProofs.lean::P14_add_module_new_module_zero_accounting`
- `LidoSRv3/SpecProofs.lean::P14_add_module_preserves_module_balance_sum`
- `LidoSRv3/SpecProofs.lean::P14_add_module_preserves_router_state`

## Checked statement

The modeled `_addModule` path succeeds only for a fresh module id and only after
the same share, fee-sum, consistency, nonzero deposit-distance, and uint64-bound
guards used by single-module config updates pass. On success, it appends exactly
the module built from the accepted config, starts that module active with zero
initial accounting fields, and preserves the router-stored module
validator-balance sum and non-module router state.

In notation:

```text
successfulAddModule(m, p, M, M') => not existsModule(m, M)
successfulAddModule(m, p, M, M') => configValid(p, M)
successfulAddModule(m, p, M, M') => |M'| = |M| + 1
successfulAddModule(m, p, M, M') => M' = M ++ [newModuleFromConfig(p)]
newModule(p).validatorsBalanceGwei = 0
successfulAddModule(m, p, M, M') =>
  sum(validatorsBalanceGwei, M') = sum(validatorsBalanceGwei, M)
successfulAddModule(m, p, M, M') =>
  ETH accounting, router report balance, and lastAcceptedReport are unchanged
```

This makes module creation part of the finite router-array model instead of
treating it as background setup, while preserving the accounting boundary used
by report and reward proofs.

## Abstraction boundary

The proof keeps the SRv3-owned freshness check, config guards, append behavior,
zero initial accounting state, balance-sum preservation, and unchanged
non-module router state. It abstracts module contract registration,
address/interface validation, locator plumbing, role authorization, packed
storage, event emission, revert strings, and exact call-stack behavior. Those
facts remain named implementation-plumbing or governance assumptions.

## Evidence status

SRV3-P14 Lean-checked, recorded in `proofs/logs/proof-report.json`.
