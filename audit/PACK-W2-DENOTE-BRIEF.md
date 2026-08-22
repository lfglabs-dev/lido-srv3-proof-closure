# Pack W2-DENOTE brief — widened constructors ≠ official success

One node, one PR. No new guarantee IDs. Official `denoteFunction` still
reverts on `Expr.call` (C-GAP). Do not claim official denotation succeeds.
`A-CONSOLIDATION-GATEWAY-NONZERO` stays a named hyp. Do not start the bus.

## Frozen interfaces used

Existing public theorems in `ConsolidationTx` and
`ConsolidationCallFragment`. The documented
`PConsolidation1.preservesEthBalance_gap` string.

## Work

1. Re-export `function_spec_bridge_constructors` as
   `requestOne_uses_widened_call_constructor`. The `requestOne` body
   contains `externalCallBind`. That is constructor shape, not official
   success.
2. Re-export `raw_call_entrypoint_always_reverts` as
   `official_raw_call_still_reverts`. Official denotation still reverts.
3. Prove `functionEnv` resolves `"consolidationPredeploy"` to the supplied
   target/fee. Resolution is not execution.
4. Prove `preservesEthBalance_gap` equals the documented nonempty string.
   The gap stays named. Value-bearing CALL frames stay out.

## Kill-lines

- Official call entrypoint reverts, and the `requestOne` body still
  contains `externalCallBind` (constructors theorem). Widened
  constructors ≠ official success.

## Out of scope

Discharging `A-CONSOLIDATION-GATEWAY-NONZERO`. Starting the bus.
Claiming official denotation succeeds. Composing P-CONSOLIDATION-ETH-1
with P-CONSOLIDATION-1. EIP-4788.
