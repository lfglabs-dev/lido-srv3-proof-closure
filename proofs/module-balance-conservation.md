# SRV3-P3 Module Balance Conservation

Source references:

- `contracts/0.8.25/sr/SRLib.sol::_reportValidatorBalancesByStakingModule`
- `contracts/0.8.25/sr/SRTypes.sol::ModuleStateAccounting`
- `contracts/0.8.25/sr/SRTypes.sol::RouterStateAccounting`

Model artifact:

- `LidoSRv3/Model.lean::acceptReport`
- `LidoSRv3/Model.lean::moduleBalanceSum`
- `LidoSRv3/SpecProofs.lean::P3_module_balance_conservation`

Math statement:

```text
acceptedReport(M, b) => router.validatorsBalanceGwei' = sum_i b_i
                      = sum_m modules[m].validatorsBalanceGwei'
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
