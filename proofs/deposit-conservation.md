# SRV3-P2 Deposit Conservation

Source references:

- `contracts/0.8.25/sr/StakingRouter.sol::deposit`
- `contracts/0.4.24/Lido.sol::withdrawDepositableEther`
- `contracts/0.8.25/lib/BeaconChainDepositor.sol::makeBeaconChainDeposits32ETH`

Model artifact:

- `LidoSRv3/Model.lean::depositPullWei`
- `LidoSRv3/Model.lean::allocatedDeposits`
- `LidoSRv3/SpecProofs.lean::P2_deposit_exact_pull`
- `LidoSRv3/SpecProofs.lean::P2_total_allocated_deposits`

Math statement:

```text
pulledWei = 32 ETH * actualDeposits
routerEthAfter = routerEthBefore
actualDeposits <= maxDepositsCount
```

Proof command:

```sh
lake build LidoSRv3
```

Result:

```text
SRV3-P2 Lean-checked, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-DEP-02`
- `A-ID-04`
- `A-ARITH-05`
