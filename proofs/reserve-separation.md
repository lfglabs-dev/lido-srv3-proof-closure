# SRV3-P1 Reserve Separation

Source references:

- `contracts/0.4.24/Lido.sol::_getBufferedEtherAllocation`
- `contracts/0.4.24/Lido.sol::_getDepositableEther`
- `contracts/0.4.24/Lido.sol::_spendDepositableEther`

Model artifact:

- `LidoSRv3/Model.lean::depositReserveUsed`
- `LidoSRv3/Model.lean::withdrawalReserveUsed`
- `LidoSRv3/Model.lean::depositableEther`
- `LidoSRv3/SpecProofs.lean::P1_reserve_separation`

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
lake build LidoSRv3
```

Result:

```text
SRV3-P1 Lean-checked, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-EXT-01`
- `A-ARITH-05`
