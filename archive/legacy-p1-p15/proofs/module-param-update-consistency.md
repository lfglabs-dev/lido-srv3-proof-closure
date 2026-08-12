# SRV3-P12 Module-Param Update Consistency

Source reference:

- `contracts/0.8.25/sr/StakingRouter.sol::updateStakingModule`
- `contracts/0.8.25/sr/SRLib.sol::_updateModuleParams`
- `contracts/0.8.25/sr/SRLib.sol::_requireConsistentFeeSum`

Model artifact:

- `LidoSRv3/Legacy/Model.lean::shareParamsValid`
- `LidoSRv3/Legacy/Model.lean::otherModulesFeeSumConsistent`
- `LidoSRv3/Legacy/Model.lean::singleModuleParamsValid`
- `LidoSRv3/Legacy/Model.lean::updateModuleParamsInModules`
- `LidoSRv3/Legacy/Model.lean::updateModuleParamsTransition`
- `LidoSRv3/Legacy/SpecProofs.lean::P12_update_module_params_requires_existing_module`
- `LidoSRv3/Legacy/SpecProofs.lean::P12_update_module_params_requires_valid_config`
- `LidoSRv3/Legacy/SpecProofs.lean::P12_update_module_params_requires_positive_max_deposits`
- `LidoSRv3/Legacy/SpecProofs.lean::P12_update_module_params_preserves_module_length`
- `LidoSRv3/Legacy/SpecProofs.lean::P12_update_module_params_records_requested_params`
- `LidoSRv3/Legacy/SpecProofs.lean::P12_update_module_params_bounded_after_success`
- `LidoSRv3/Legacy/SpecProofs.lean::P12_update_module_params_preserves_module_balance_sum`
- `LidoSRv3/Legacy/SpecProofs.lean::P12_update_module_params_preserves_router_state`

Math statement:

```text
successfulModuleParamUpdate(moduleId, params) => moduleExists(moduleId)

successfulModuleParamUpdate(moduleId, params) =>
  stakeShareLimit <= priorityExitShareThreshold <= 10000
  moduleFee + treasuryFee <= 10000
  every other module has the same moduleFee + treasuryFee
  minDepositBlockDistance != 0
  minDepositBlockDistance <= uint64.max
  maxDepositsPerBlock != 0
  maxDepositsPerBlock <= uint64.max

successfulModuleParamUpdate(moduleId, params, modules') =>
  len(modules') == len(modules)
  selectedModule(modules', moduleId).stakeShareLimitBps == params.stakeShareLimit
  selectedModule(modules', moduleId).priorityExitShareThresholdBps
    == params.priorityExitShareThreshold
  selectedModule(modules', moduleId).moduleFeeBps == params.moduleFee
  selectedModule(modules', moduleId).treasuryFeeBps == params.treasuryFee
  selectedModule(modules', moduleId).maxDepositsPerBlock
    == params.maxDepositsPerBlock
  selectedModule(modules', moduleId).minDepositBlockDistance
    == params.minDepositBlockDistance
  every updated module has moduleFeeBps + treasuryFeeBps <= 10000
  sum(modules'.validatorsBalanceGwei) == sum(modules.validatorsBalanceGwei)
  ETH accounting, router report balance, and lastAcceptedReport are unchanged
```

Proof command:

```sh
lake build LidoSRv3
```

Result:

```text
SRV3-P12 Lean-checked, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-GOV-14`
- `A-ID-04`
- `A-ARITH-05`
