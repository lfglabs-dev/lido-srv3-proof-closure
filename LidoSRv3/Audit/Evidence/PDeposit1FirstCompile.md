# P-DEPOSIT-1 first focused compile

Command:

`lake build LidoSRv3.Audit.Verity.DepositTx LidoSRv3.Tests.DepositTxMutants`

First compiler error (before the direct fix):

```text
error: LidoSRv3/Audit/Verity/DepositTx.lean:91:55: unsolved goals
case committedNoDeposits
cfg : SourceDepositConfig
inp : SourceDepositInput
snapshot : ContractState
balances : Balances
hrun : run cfg inp = Outcome.committedNoDeposits
⊢ False
```

Cause and fix: `executeOutcome` initially sent the source's committed empty-batch
early return through the generic module-revert program.  It now uses the typed,
no-external-call `DepositTxContract.executeNoDeposits` success path.
