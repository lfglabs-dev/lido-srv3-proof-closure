# Campaign node 3 — live computed oracle mint (P-ORACLE-SUPPLY-1)

One node, one PR. Same guarantee ID. Do not split into P-ORACLE-MINT-1 /
P-ORACLE-BOUND-1. Do not widen P-ACCOUNT-1.

## What the parent says

`LidoSRv3/Audit/Guarantees/POracleSupply1.lean`, theorem
`oracle_supply_live_computed_mint`, universal over `ReportInput`, `feeWei`,
`shareRate`, named cap `maxShareRate`, and the entry `ContractState`, with
retained premise `shareRate ≤ maxShareRate`.

1. **Live conjunct.** `handleOracleReportComputed i feeWei shareRate` is
   `handleOracleReport i (mintedShares feeWei shareRate)`. Its `observe`
   equals `sourceView i (mintedShares feeWei shareRate)`.
2. **Mint conjunct.** Spec frame `specOfMint i feeWei shareRate` has
   `sharesMinted = mintedShares feeWei shareRate` and
   `shareRateDelta = shareRate`.
3. **Bound conjunct.** `sharesMinted ≤ feeWei * maxShareRate / E27`.

`submitReportData` is named out. The Pack E leftover
(`sharesMinted = argument`) is not this conclusion.

## Kill-line

`free_argument_does_not_satisfy_computed_observe`: mutant
`handleOracleReportStillFree` still takes a free `sharesToMintAsFees`.
On `feeWei = shareRate = 1` the computed mint is `0` (no mint step) while
the free argument `1` journals `.rewardsMinted`. Spec sum-balances and
raw-fee kill-lines stay.

## Non-goals

- P-ACCOUNT-1 stays order-only; `PAccount1.lean` is not edited.
- No second mint/cap ID.
- No claim that `submitReportData` computes the mint.

## Build

    lake build LidoSRv3.Audit.Guarantees.POracleSupply1
    lake build LidoSRv3.Tests.PackN3OracleMintMutants
