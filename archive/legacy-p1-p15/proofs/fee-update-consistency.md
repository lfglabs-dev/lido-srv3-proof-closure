# SRV3-P11 Fee-Update Consistency

Source reference:

- `contracts/0.8.25/sr/SRLib.sol::_updateAllModuleFees`
- `contracts/0.8.25/sr/StakingRouter.sol::updateAllStakingModulesFees`

Model artifact:

- `LidoSRv3/Legacy/Model.lean::feeRowsValidFromExpected`
- `LidoSRv3/Legacy/Model.lean::allModuleFeesConsistent`
- `LidoSRv3/Legacy/Model.lean::updateAllModuleFeesInModules`
- `LidoSRv3/Legacy/Model.lean::updateAllModuleFeesTransition`
- `LidoSRv3/Legacy/SpecProofs.lean::P11_update_all_module_fees_requires_lengths`
- `LidoSRv3/Legacy/SpecProofs.lean::P11_update_all_module_fees_requires_consistent_rows`
- `LidoSRv3/Legacy/SpecProofs.lean::P11_update_all_module_fees_preserves_module_length`
- `LidoSRv3/Legacy/SpecProofs.lean::P11_update_all_module_fees_exact_fee_projections`
- `LidoSRv3/Legacy/SpecProofs.lean::P11_update_all_module_fees_bounded_after_success`
- `LidoSRv3/Legacy/SpecProofs.lean::P11_update_all_module_fees_preserves_module_balance_sum`
- `LidoSRv3/Legacy/SpecProofs.lean::P11_update_all_module_fees_preserves_router_state`

Math statement:

```text
successfulFeeUpdate(moduleFees, treasuryFees) =>
  len(moduleFees) == len(modules) and len(treasuryFees) == len(modules)

successfulFeeUpdate(moduleFees, treasuryFees) =>
  every row has moduleFee + treasuryFee <= 10000
  every nonempty row has the same moduleFee + treasuryFee as row 0

successfulFeeUpdate(moduleFees, treasuryFees, modules') =>
  len(modules') == len(modules)
  map(module.moduleFeeBps, modules') == moduleFees
  map(module.treasuryFeeBps, modules') == treasuryFees
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
SRV3-P11 Lean-checked, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-GOV-14`
- `A-ARITH-05`
