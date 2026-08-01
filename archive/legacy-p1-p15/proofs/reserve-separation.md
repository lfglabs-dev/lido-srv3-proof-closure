# SRV3-P1 Reserve Separation

Source references:

- `contracts/0.4.24/Lido.sol::_getBufferedEtherAllocation`
- `contracts/0.4.24/Lido.sol::_getDepositableEther`
- `contracts/0.4.24/Lido.sol::_spendDepositableEther`

Model artifact:

- `LidoSRv3/Legacy/Model.lean::depositReserveUsed`
- `LidoSRv3/Legacy/Model.lean::withdrawalReserveUsed`
- `LidoSRv3/Legacy/Model.lean::depositableEther`
- `LidoSRv3/Legacy/SpecProofs.lean::P1_reserve_separation`
- `LidoSRv3/Legacy/SpecProofs.lean::P1_depositable_excludes_withdrawal_reserve`

Math statement:

```text
d = min(buffered, storedDepositReserve)
w = min(buffered - d, unfinalizedWithdrawal)
u = buffered - d - w
depositable = d + u
depositable + w = buffered            (P1_reserve_separation: exact partition of the buffer)
depositable <= buffered - w           (P1_depositable_excludes_withdrawal_reserve: depositable never draws on withdrawal-reserved liquidity)
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
