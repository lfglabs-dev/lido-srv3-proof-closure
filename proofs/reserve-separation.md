# SRV3-P1 Reserve Separation

Source references:

- `contracts/0.4.24/Lido.sol::_getBufferedEtherAllocation`
- `contracts/0.4.24/Lido.sol::_getDepositableEther`
- `contracts/0.4.24/Lido.sol::_spendDepositableEther`

Model artifact:

- `verity/src/verity_srv3/model.py::buffered_allocation`
- `verity/src/verity_srv3/model.py::spend_depositable`
- `verity/src/verity_srv3/properties.py::reserve_separation`
- `tests/verity/fixtures/p1_reserve_separation.json`

Math statement:

```text
d = min(buffered, storedDepositReserve)
w = min(buffered - d, unfinalizedWithdrawal)
u = buffered - d - w
depositable = d + u
spend <= depositable
```

Proof command:

```sh
PYTHONPATH=verity/src python3 -m verity_srv3.runner --targets verity/targets/srv3-proof-targets.json --fixtures tests/verity/fixtures --output proofs/logs/proof-report.json
```

Result:

```text
SRV3-P1 pass, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-EXT-01`
- `A-ARITH-05`
