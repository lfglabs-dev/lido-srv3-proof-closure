# P-DEPOSIT-1 Verity transaction rollback blocker

Pin: `lfglabs-dev/verity@c41757164e9e8230536d7af29d81a2961b30e482`, the
post-#2245/#2247/#2249 main used by this campaign.

The blocker is reproduced by
`callProgram_later_revert_does_not_restore_entry_snapshot` in
`LidoSRv3/Audit/Verity/DepositRollback.lean`.

`DenoteExternalCalls.CallProgram` threads the world from one call to the next.
A failed or reverted mutable call restores only that call's immediate
pre-world. If a Lido-side call succeeds and mutates the world, then a later
DepositContract call reverts, `CallProgram.denote` retains the Lido mutation.
This differs from Solidity/EVM whole-transaction rollback and is fatal for a
multi-validator batch when any later deposit fails.

Reproduce:

```text
lake build LidoSRv3.Audit.Verity.DepositRollback LidoSRv3.Audit.Verity.Tests.DepositRollback
```

The focused theorem uses only definitional reduction (`rfl`) and ordinary
equality reasoning. It introduces no axiom, interpreter, unsafe bridge, or
native decision procedure.

The other required surfaces do not repair this gap:

- `AllocationExtraction.extractAllocationFromSource` currently takes
  `SolidityFunction := FunctionSpec` and `compileSolidity fn := some fn`; it is
  not extraction from the pinned Solidity AST.
- `DenoteMemory` provides byte-memory operations and per-call memory lemmas,
  but no evaluator connecting a complete `FunctionSpec` statement trace,
  dynamic external returndata, and `CallProgram` into one transaction frame.
- #2245 makes linked external calls expressible in contract bodies; it does not
  add transaction-entry rollback to `CallProgram.denote`.
- #2247 and #2249 add inheritance/modifier and packed-storage lowering; neither
  changes the rollback semantics above.

Minimum upstream gate: a machine-checked evaluator/bridge for the relevant
`FunctionSpec` statements, exact byte memory and external-call trace whose
reverting terminal result restores the transaction-entry world (including
storage, balances and logs), plus a source extraction boundary that is not the
identity alias. Until then P-DEPOSIT-1 transaction closure remains OPEN.
