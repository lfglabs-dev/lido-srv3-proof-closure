# SRV3-P3 Module Balance Conservation

Source references:

- `contracts/0.8.25/sr/SRLib.sol::_validateReportValidatorBalancesByStakingModule`
- `contracts/0.8.25/sr/SRLib.sol::_reportValidatorBalancesByStakingModule`
- `contracts/0.8.25/sr/SRTypes.sol::ModuleStateAccounting`
- `contracts/0.8.25/sr/SRTypes.sol::RouterStateAccounting`

Model artifact:

- `LidoSRv3/Legacy/Model.lean::reportBalancesWithinRange`
- `LidoSRv3/Legacy/Model.lean::reportWellFormed`
- `LidoSRv3/Legacy/Model.lean::reportValidatorBalancesTransition`
- `LidoSRv3/Legacy/Model.lean::acceptReport`
- `LidoSRv3/Legacy/Model.lean::moduleBalanceSum`
- `LidoSRv3/Legacy/SpecProofs.lean::P3_module_balance_conservation`
- `LidoSRv3/Legacy/SpecProofs.lean::P3_report_transition_requires_well_formed`
- `LidoSRv3/Legacy/SpecProofs.lean::P3_report_transition_module_balance_conservation`
- `LidoSRv3/Legacy/SpecProofs.lean::P3_report_transition_module_balances_match_report`
- `LidoSRv3/Legacy/SpecProofs.lean::P3_report_transition_records_accepted_report`
- `LidoSRv3/Legacy/SpecProofs.lean::P3_report_transition_preserves_module_length`
- `LidoSRv3/Legacy/SpecProofs.lean::P3_report_transition_modules_exact`
- `LidoSRv3/Legacy/SpecProofs.lean::P3_report_transition_preserves_eth_state`

Math statement:

```text
acceptedReport(M, b) => router.validatorsBalanceGwei' = sum_i b_i
                      = sum_m modules[m].validatorsBalanceGwei'
successfulReportTransition(r) => modules'.map(validatorsBalanceGwei) = reportBalances(r)
successfulReportTransition(r) => modules' = applyReportToModules(modules, r)
successfulReportTransition(r) => length(r) = modules.length
successfulReportTransition(r) => reportIds(r) = moduleIds(modules)
successfulReportTransition(r) => every balance is within SRv3 Gwei range
successfulReportTransition(r) => lastAcceptedReport' = r
successfulReportTransition(r) => modules'.length = modules.length
successfulReportTransition(r) => bufferedEther', depositReserve',
                                 withdrawalReserve', routerEthBalanceWei',
                                 and beaconDepositSinkWei' are unchanged
```

Proof command:

```sh
lake build LidoSRv3
```

Result:

```text
SRV3-P3 Lean-checked, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-ORC-03`
- `A-ID-04`
- `A-ARITH-05`
