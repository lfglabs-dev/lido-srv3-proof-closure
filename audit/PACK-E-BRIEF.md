# Pack E brief — OracleFrame fee/share child and Eugene citation

One node, one PR. Not Best-of-N. No new guarantee IDs. P-ACCOUNT-1 remains
order-only (`mint_after_read_discipline`). No stETH supply bound from ticks.

## Frozen interfaces used

`Spec.OracleFrame` (`balances`, `sharesMinted`, `shareRateDelta`) from Wave 0.
Fee computation and `submitReportData` stay out of this freeze.

## Work

1. Unregistered child: `OracleFrame.sharesMinted` is the `sharesToMintAsFees`
   argument, not a computed fee. `shareRateDelta` is `0` (unmodeled).
   `balances` are the report's `balancesGwei`.
2. Cite existing `P-ALLOC-1.eugene-bound` (`checked_amount_le_bond` /
   `operator_reward_share_le_configured_bond`). Do not re-home it.
3. Keep ACCOUNT order-only. Do not start supply bounds from ticks.

## Kill-lines

- Mutant frame that sets `sharesMinted` to the sum of balances disagrees
  with the argument on a witness where those differ.

## Out of scope

`submitReportData` fee computation, stETH supply bounds, packs F / Join.
