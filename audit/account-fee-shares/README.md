# P-ACCOUNT-1 — derived `sharesToMintAsFees` (not a free argument)

## CLAIM

- **Guarantee:** `P-ACCOUNT-1`
- **fidelity.missing entry:** `fee computation (sharesToMintAsFees is an argument)`
- **Branch:** `grok/lido-account-fee-20260912`
- **Base:** `origin/main` @ `0debc40f5f7b1a1b687782710484397eaa7f781b`
- **Pinned Solidity:** `17005714f151e5502c559932319a3f2f74ac2436`
- **Claimed by:** grok cloud agent, 2026-09-12
- **Status:** claimed — implementing

This lot does **not** claim `packed uint64 accounting words` (closed by `grok/lido-account-packed-20260912` / PR #399) and does **not** claim Trust registration of already-integrated fee-mint consumers (`spark/lido-account-fee-mint-registration-20260911`).

## Targeted gap

Registered parent `LidoSRv3.Audit.HandleOracleReportTx.handleOracleReport` takes `sharesToMintAsFees : Nat` as a free argument (`HandleOracleReportTx.lean` header; `AccountingCorrespondence.successfulSteps`). Live `Accounting._handleOracleReport` (`Accounting.sol:203-261`) obtains that number from `_calculateProtocolFees` (`Accounting.sol:263-303`) after `StakingRouter.getStakingRewardsDistribution` (`StakingRouter.sol:808-873`).

This lot adds a **derived consumer beside the parent**. It does **not** edit `handleOracleReport`, `mint_after_read_discipline`, `PAccount1`, or `guarantees.yaml`.

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
3. Decrement the README gap count 7 → 6 if that bullet still lists this
   string (packed-words raccord may already have dropped it to 6).

## Honesty (not this entry)

`totalFee` and `precisionPoints` remain the getter **outputs as inputs** on
`ReportFeeProductsCorrespondence.Input`. This lot closes the *shares*
argument, not a live `STATICCALL` of `getStakingRewardsDistribution`. The
physical getter+mint path is already modeled in `ReportWriteFee` /
`ReportFeeMint` (supplemental on the P-ACCOUNT-1 row).
