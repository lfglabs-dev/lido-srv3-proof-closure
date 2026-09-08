# P-ACCOUNT-1 / P-ADDRESS-1 Verity vector trio

Exclusive scope: concrete executable vectors for the two registered
guarantees, plus the targeted Lean receipt. Nothing else is touched.

## Files

- `LidoSRv3/Tests/PAccount1Vectors.lean` — vectors against
  `LidoSRv3.Audit.Guarantees.PAccount1`:
  - committed / zero-fee / invalid-report `observe` views of
    `handleOracleReport`;
  - raw step-clock ticks `(1, 2, 3, 4)` behind the registered parent
    `mint_after_read_discipline`, and the `mintAfterRead` predicate on those
    exact ticks;
  - kill-line vectors: the pure call-site reordering mutant
    `handleOracleReportMintBeforeRead` records ticks `(1, 2, 4, 3)`, falsifies
    `mintAfterRead`, and drops both reordered steps from the reconstructed
    `Result.steps` trace;
  - injected post-write revert surfaces `INJECTED_AFTER_WRITES` and restores
    the pre-call snapshot (`verity_tx_revert_restores_snapshot`).

- `LidoSRv3/Tests/PAddress1Vectors.lean` — vectors against
  `LidoSRv3.Audit.Guarantees.PAddress1`:
  - caller-swap renaming vectors (swap, fixpoint, involution) and the
    caller-indexed input rename;
  - a committed single-item `transferFrom` source witness, with concrete
    instances of the registered admission and post-state parents
    (`source_admission_nondiscriminatory`,
    `source_success_post_state_equivariant`) and a wrong-caller negative
    control;
  - a wave-5 `claimWithdrawalsTo` witness showing the caller-relative
    request-owner gate renaming with the caller;
  - official-Denote TX-plane commit and wrong-caller revert vectors via
    `AddressTransferTx.run`;
  - a registry-surface instance of the universal parent
    `universal_address_writer_equivariance`.

## Receipt

`lean-receipt.txt` is the output of running, with `set -o pipefail`:

```
lake env lean LidoSRv3/Tests/PAccount1Vectors.lean
lake env lean LidoSRv3/Tests/PAddress1Vectors.lean
```

Both files elaborate with exit code 0 on Lean 4.31.0
(`leanprover/lean4:v4.31.0`). The receipt was captured by teeing the piped
command output, so a nonzero exit from either Lean invocation fails the
pipeline.
