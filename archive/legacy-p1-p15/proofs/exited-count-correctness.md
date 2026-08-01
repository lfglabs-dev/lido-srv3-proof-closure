# SRV3-P7 Exited-Count Correctness

Source references:

- `contracts/0.8.25/sr/StakingRouter.sol::updateExitedValidatorsCountByStakingModule`
- `contracts/0.8.25/sr/SRLib.sol::_updateExitedValidatorsCountByStakingModule`
- `contracts/0.8.25/sr/SRTypes.sol::ModuleStateAccounting`
- `contracts/common/interfaces/IStakingModule.sol::getStakingModuleSummary`

Model artifact:

- `LidoSRv3/Legacy/Model.lean::recordModuleExitedCount`
- `LidoSRv3/Legacy/Model.lean::exitedCountUpdateRowsValid`
- `LidoSRv3/Legacy/Model.lean::updateExitedCountInModules`
- `LidoSRv3/Legacy/Model.lean::updateExitedValidatorsTransition`
- `LidoSRv3/Legacy/SpecProofs.lean::P7_exited_count_update_requires_valid_rows`
- `LidoSRv3/Legacy/SpecProofs.lean::P7_exited_count_update_empty`
- `LidoSRv3/Legacy/SpecProofs.lean::P7_exited_count_update_preserves_module_length`
- `LidoSRv3/Legacy/SpecProofs.lean::P7_exited_count_update_preserves_module_balance_sum`
- `LidoSRv3/Legacy/SpecProofs.lean::P7_exited_count_update_returns_loop_result`
- `LidoSRv3/Legacy/SpecProofs.lean::P7_exited_count_update_preserves_router_state`

Math statement:

```text
successfulExitedCountUpdate(rows) =>
  every processed row names an existing module at that loop step
  and previousExited(module) <= newExited(row)
  and newExited(row) <= depositedValidators(module)
  and (modules', newlyExited) is exactly the sequential loop result
  and modules'.length = modules.length
  and sum(validatorsBalanceGwei(modules')) = sum(validatorsBalanceGwei(modules))
  and ETH accounting, router report balance, and lastAcceptedReport are unchanged
emptyExitedCountUpdate(state) = (state, 0)
```

The row predicate is recursive over the current module state, so duplicate
module IDs are treated like Solidity treats them: later rows see earlier writes.
The empty-row path is a separate checked no-op target. Because the modeled loop
only writes router-stored exited counts, a successful update also preserves the
router module-balance sum and non-module router state.

Proof command:

```sh
lake build LidoSRv3
```

Result:

```text
SRV3-P7 Lean-checked, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-MOD-08`
- `A-ORC-03`
- `A-ARITH-05`
