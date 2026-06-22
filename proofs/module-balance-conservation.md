# SRV3-P3 Module Balance Conservation

Source references:

- `contracts/0.8.25/sr/SRLib.sol::_reportValidatorBalancesByStakingModule`
- `contracts/0.8.25/sr/SRTypes.sol::ModuleStateAccounting`
- `contracts/0.8.25/sr/SRTypes.sol::RouterStateAccounting`

Model artifact:

- `verity/src/verity_srv3/model.py::accept_balance_report`
- `verity/src/verity_srv3/properties.py::module_balance_conservation`
- `tests/verity/fixtures/p3_module_balance_conservation.json`

Math statement:

```text
acceptedReport(M, b) => router.validatorsBalanceGwei' = sum_i b_i
                      = sum_m modules[m].validatorsBalanceGwei'
```

Proof command:

```sh
PYTHONPATH=verity/src python3 -m verity_srv3.runner --targets verity/targets/srv3-proof-targets.json --fixtures tests/verity/fixtures --output proofs/logs/proof-report.json
```

Result:

```text
SRV3-P3 pass, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-ORC-03`
- `A-ID-04`
- `A-ARITH-05`
