# Pack C-GAP brief — official denotation gap

One node, one PR. No new guarantee IDs. `A-CONSOLIDATION-GATEWAY-NONZERO`
remains a named hyp. Official `Expr.call` reverts. Do not start the bus.
Do not compose P-CONSOLIDATION-ETH-1 with P-CONSOLIDATION-1.

## Frozen interfaces used

Existing public theorems in `ConsolidationCallFragment` and the
premise-necessity kill-line on `PConsolidation1`.

## Work

1. Name the official-denotation gap already proved: `Expr.call` /
   `Stmt.externalCallBind` have no `denoteFunction` arm and revert for
   every oracle, transaction, and world.
2. Re-export the strongest public fragment theorem as
   `official_external_call_reverts`
   (`registered_external_call_bind_entrypoint_always_reverts`).
3. Re-export `gateway_admitted_nonzero_kill_line` as
   `gateway_nonzero_remains_named_hyp`. Same shape as Pack F. The hyp
   stays named.

## Kill-lines

- Dropping the gateway-nonzero premise admits a free batch. Citation of
  the existing kill-line, not a new parent-shaped refutation of the
  hyp-conditioned parent.

## Out of scope

Bus, EIP-4788, Join verifier, discharging the hyp.
