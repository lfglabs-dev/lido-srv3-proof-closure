# P-ACCOUNT-1 — derived `sharesToMintAsFees` (not a free argument)

## CLAIM

- **Guarantee:** `P-ACCOUNT-1`
- **fidelity.missing entry:** `fee computation (sharesToMintAsFees is an argument)`
- **Branch:** `grok/lido-account-fee-20260912`
- **Base:** `origin/main` @ `0debc40f5f7b1a1b687782710484397eaa7f781b`
- **Pinned Solidity:** `17005714f151e5502c559932319a3f2f74ac2436`
- **Claimed by:** grok cloud agent, 2026-09-12
- **Status:** closed on this consumer — Spark raccord pending

This lot does **not** claim `packed uint64 accounting words` (closed by `grok/lido-account-packed-20260912` / PR #399) and does **not** claim Trust registration of already-integrated fee-mint consumers (`spark/lido-account-fee-mint-registration-20260911`).

## Targeted gap

Registered parent `LidoSRv3.Audit.Verity.HandleOracleReportTx.handleOracleReport` takes `sharesToMintAsFees : Nat` as a free argument (`HandleOracleReportTx.lean:239`; `AccountingCorrespondence.successfulSteps`). Live `Accounting.handleOracleReport` (`Accounting.sol:135-144`) obtains that number from `_calculateProtocolFees` (`Accounting.sol:263-303`) after `StakingRouter.getStakingRewardsDistribution` (`StakingRouter.sol:808-873`).

This lot adds a **derived consumer beside the parent**. It does **not** edit `handleOracleReport`, `mint_after_read_discipline`, `PAccount1`, or `guarantees.yaml`.

## What is proved

Additive files:

- `LidoSRv3/Audit/Source/AccountFeeShares.lean`
- `LidoSRv3/Tests/AccountFeeSharesMutants.lean`

`handleOracleReportDerived i fee` runs the unchanged parent at
`derivedSharesToMintAsFees fee`, which is the pinned
`ReportFeeProductsCorrespondence.sharesToMintAsFees` transcription of
`Accounting.sol:317,323,325,331`.

| Theorem | Source span | Claim |
|---|---|---|
| `derived_eq_source_products` | Accounting.sol:263-303 / 317-331 | derivation is the existing products function |
| `derived_nonprofitable_zero` | Accounting.sol:322 LIP-12 | non-profitable → `some 0` |
| `derived_profitable_is_l331` | Accounting.sol:331 | profitable success is the checked quotient |
| `derived_zero_precision_is_panic` | Accounting.sol:325 | zero `precisionPoints` → `none` |
| `product_panic_reverts` | panic opcode, not a success stub | wrapper reverts the pre-state |
| `handleOracleReportDerived_eq_parent` | Accounting.sol:135-144 / 403-413 | wrapper = parent at the derived word |
| `handleOracleReportDerived_observe` | same | `observe` = `sourceView` at the derived mint |
| `handleOracleReportDerived_mint_after_read` | Accounting.sol:277 before 403 | cites `mintAfterReadDiscipline_holds`; parent not edited |
| `free_argument_mints_when_source_is_zero` | Accounting.sol:322 vs free `Nat` | parent can mint when products say 0 |
| `getter_outputs_feed_products` | StakingRouter.sol:808-873 | `totalFee` / `precisionPoints` are getter output words |

Mutants (`AccountFeeSharesMutants`): profitable witness mints 5 and writes the four-step trace; LIP-12 skips mint; panic reverts; free `7` on a zero-fee report still mints on the parent and does not on the wrapper; derived ticks are read `3` then mint `4`.

Axioms of every export: `propext` and (where used) `Quot.sound`. No `sorryAx`, no `Classical.choice`.

## Spark raccord (do not apply in this lot)

In `audit/guarantees.yaml` under `P-ACCOUNT-1`:

1. Remove this exact `fidelity.missing` string:
   ```
   - "fee computation (sharesToMintAsFees is an argument)"
   ```
2. Add a `fidelity.covered` bullet that the ACCOUNT consumer
   `handleOracleReportDerived` obtains `sharesToMintAsFees` from the pinned
   `_calculateProtocolFees` products (`ReportFeeProductsCorrespondence`)
   rather than a free `Nat`.
3. Decrement the README / STATUS gap count if that bullet still lists this
   string (packed-words raccord may already have dropped it).

## Honesty (not this entry)

`totalFee` and `precisionPoints` remain the getter **outputs as inputs** on
`ReportFeeProductsCorrespondence.Input`. `getter_outputs_feed_products`
only shows that a successful `feeProductsFromCommittedGetter` bridge copies
those two words from a `Distribution`. This lot does **not** re-execute
`getStakingRewardsDistribution` against written router storage; that
re-read is the separate P-ACCOUNT-1 missing entry
`re-read of the written router snapshot for rewards`.

The physical getter+mint path is already modeled in `ReportWriteFee` /
`ReportFeeMint` (supplemental on the P-ACCOUNT-1 row). P-ORACLE-SUPPLY-1's
`handleOracleReportComputed` uses an `E27` quantized `feeWei * shareRate`
pair, not this ACCOUNT products consumer.
