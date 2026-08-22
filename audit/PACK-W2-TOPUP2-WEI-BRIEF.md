# Pack W2-TOPUP2-WEI brief — abstract `valueWei / GWEI`

One node. No new guarantee IDs. `A-TOPUP-BEACON-ADDRESS` stays OPEN.
This child does not connect SSZ, `allocateDeposits`, or a live gateway.

## Frozen interfaces used

`PTopup2.GWEI`, `PTopup2.TopupBatch`, `PTopup2.TopupConfig`, and
`PTopup2.transitionBudget`. The leftover-budget walk already consumes
`valueWei / GWEI`.

## Work

1. `valueWei_div_gwei_of_aligned`: `(gwei * GWEI) / GWEI = gwei`.
2. `transitionBudget_uses_wei_div_gwei`: the budget is
   `min (valueWei / GWEI) (min moduleLimit blockCap)`.
3. `aligned_five_gwei_budget`: `valueWei = 5 * GWEI` with large caps
   budgets to 5.

## Kill-lines

- A mutant budget that uses raw `valueWei` (no `/ GWEI`) on the
  five-gwei witness equals `5 * 10^9 ≠ 5`.

## Out of scope

SSZ. `allocateDeposits`. Live gateway. Discharge of
`A-TOPUP-BEACON-ADDRESS`. New guarantee IDs. Integrator files.
