# SRV3-P2 Deposit Conservation

Source references:

- `contracts/0.8.25/sr/StakingRouter.sol::deposit`
- `contracts/0.4.24/Lido.sol::withdrawDepositableEther`
- `contracts/0.8.25/lib/BeaconChainDepositor.sol::makeBeaconChainDeposits32ETH`

Model artifact:

- `verity/src/verity_srv3/model.py::deposit`
- `verity/src/verity_srv3/properties.py::deposit_conservation`
- `tests/verity/fixtures/p2_deposit_conservation.json`

Math statement:

```text
pulledWei = 32 ETH * actualDeposits
routerEthAfter = routerEthBefore
actualDeposits <= maxDepositsCount
```

Proof command:

```sh
PYTHONPATH=verity/src python3 -m verity_srv3.runner --targets verity/targets/srv3-proof-targets.json --fixtures tests/verity/fixtures --output proofs/logs/proof-report.json
```

Result:

```text
SRV3-P2 pass, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-DEP-02`
- `A-ID-04`
- `A-ARITH-05`
