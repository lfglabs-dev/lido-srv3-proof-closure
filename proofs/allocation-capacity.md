# SRV3-P9 Allocation Capacity

Source references:

- `contracts/0.8.25/sr/SRLib.sol::_getDepositAllocations`
- `contracts/0.8.25/sr/SRLib.sol::_getModuleDepositAllocation`
- `contracts/0.8.25/sr/SRLib.sol::_getModulesAllocationAndCapacity`
- `contracts/0.8.25/sr/StakingRouter.sol::getDepositAllocations`

Model artifact:

- `LidoSRv3/Legacy/Model.lean::AllocationConfig`
- `LidoSRv3/Legacy/Model.lean::AllocationCapacityRow`
- `LidoSRv3/Legacy/Model.lean::moduleCurrentAllocationEquivalent`
- `LidoSRv3/Legacy/Model.lean::moduleAvailableCapacityEquivalent`
- `LidoSRv3/Legacy/Model.lean::allocationTotalValidators`
- `LidoSRv3/Legacy/Model.lean::moduleTargetValidators`
- `LidoSRv3/Legacy/Model.lean::allocationCapacityRow`
- `LidoSRv3/Legacy/Model.lean::modulesAllocationAndCapacity`
- `LidoSRv3/Legacy/SpecProofs.lean::P9_allocation_capacity_rows_aligned`
- `LidoSRv3/Legacy/SpecProofs.lean::P9_allocation_capacity_length`
- `LidoSRv3/Legacy/SpecProofs.lean::P9_allocation_capacity_values_length`
- `LidoSRv3/Legacy/SpecProofs.lean::P9_allocation_capacity_module_ids_preserved`
- `LidoSRv3/Legacy/SpecProofs.lean::P9_active_allocation_capacity_target_bound`
- `LidoSRv3/Legacy/SpecProofs.lean::P9_active_allocation_capacity_available_bound`
- `LidoSRv3/Legacy/SpecProofs.lean::P9_inactive_allocation_capacity_current`

Math statement:

```text
len(modulesAllocationAndCapacity(modules)) = len(modules)
len(allocatedCapacityValues(modulesAllocationAndCapacity(modules))) = len(modules)
map(row.moduleId, modulesAllocationAndCapacity(modules)) = map(module.id, modules)
row in modulesAllocationAndCapacity(modules) => exists module in modules aligned to row
active(module) => row.capacity <= row.targetValidators
active(module) => row.capacity <= availableCapacity(module)
inactive(module) => row.capacity = row.currentAllocation
```

Proof command:

```sh
lake build LidoSRv3
```

Result:

```text
SRV3-P9 Lean-checked, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-ID-04`
- `A-MOD-08`
- `A-MOD-11`
- `A-ALLOC-12`
- `A-ARITH-05`
