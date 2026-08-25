import LidoSRv3.Audit.Guarantees.POracleSupply1

/-!
# O2 source-domain fail-closed vectors

Parent-shaped negations and regression tests for the P-ORACLE-SUPPLY-1
source-domain strengthening (`oracle_supply_entry_source_domain`).

1. `domainGuardIsLoadBearing`: the model silently accepts an input whose
   first checked-arithmetic subtraction would revert in Solidity, proving
   `EntryDomainValid` is a non-trivial restriction.
2. `nonExactReportNotDivisible` / `nonExactReportMintEqualsPinned`: an
   `EntryDomainValid` input where the rate denominator does NOT divide
   `internalSharesBeforeFees * E27` — so the `∣`-conditional equality
   premise fails — yet the E27-quantized mint still equals the pinned
   formula, confirming the `≤` bound is tight on realistic values.
3. `domainValidExactnessPositiveControl`: the strengthened parent passes
   on the exact-divisibility subset of the profitable vector.
4. `domainValidProfitableReport`: positive control confirming that the
   standard profitable test vector satisfies `EntryDomainValid`.
5. `existingParentStillPasses`: regression confirming the existing
   non-domain-restricted parent is not weakened.
6. `feeBoundIsLoadBearing`: the A-REWARD-09 counterexample
   (`totalFee = 2, precisionPoints = 1`) satisfies every existing
   parent conclusion but violates `EntryDomainValid.feeBound`, proving
   the `totalFee ≤ precisionPoints` guard is non-trivial.

Every test uses `decide` (not `native_decide`) and keeps witness values
small for tractability.
-/

namespace LidoSRv3.Tests.PackO2SupplyDomainMutants

open _root_.Verity
open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.SolidityAccounting.SubmitReportEntry
open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.OracleMintCorrespondence
open LidoSRv3.Audit.Guarantees
open LidoSRv3.Audit.Verity.HandleOracleReportTx
open LidoSRv3.Audit.Verity.SubmitReportEntryTx

private def routerReport : ReportInput :=
  { registeredModuleIds := [1, 2]
    reportedModuleIds := [1, 2]
    balancesGwei := [10, 20] }

/-- Standard profitable witness from PackP3, kept for positive controls. -/
private def profitableReport : SubmitReportData :=
  { report := routerReport
    dataHash := 77
    consensusHash := 77
    senderIsMemberOrHasRole := true
    preTotalPooledEther := 100
    preExternalEther := 0
    preTotalShares := 200
    preExternalShares := 0
    preClValidatorsBalance := 50
    preClPendingBalance := 0
    depositedBalance := 0
    clValidatorsBalance := 60
    clPendingBalance := 0
    withdrawalsVaultTransfer := 0
    elRewardsVaultTransfer := 0
    totalSharesToBurn := 0
    etherToFinalizeWQ := 0
    totalFee := 100
    precisionPoints := 100 }

/-- Domain-invalid witness: `preExternalEther > preTotalPooledEther`,
violating the first checked-arithmetic non-underflow condition.  The
Solidity checked subtraction `preTotalPooledEther - preExternalEther` would
revert; the Lean Nat model silently truncates to zero.

All existing P-ORACLE-SUPPLY-1 theorems (which have no domain restriction)
still hold on this input — that is exactly why the domain guard is load-
bearing: it restricts the quantifier domain to match the Solidity source. -/
private def domainInvalidReport : SubmitReportData :=
  { profitableReport with preExternalEther := 200 }

/-- The domain-invalid witness violates `EntryDomainValid`. -/
theorem domainInvalidReportNotValid :
    ¬ EntryDomainValid domainInvalidReport := by
  intro h
  exact absurd h.internalEther (by decide)

/-- The existing bound conjunct holds on the domain-invalid witness (the
model accepts it), demonstrating the gap between the model's Nat-wide
domain and the Solidity's checked-arithmetic domain. -/
theorem existingBoundHoldsOnInvalidDomain :
    mintedShares (entryFeeWei domainInvalidReport)
        (entryShareRate domainInvalidReport)
      ≤ pinnedSharesToMintAsFees domainInvalidReport := by
  exact entry_mint_le_pinned_shares domainInvalidReport

/-- Combined: domain guard is load-bearing — there exists an input the model
accepts (existing theorems hold) but `EntryDomainValid` rejects. -/
theorem domainGuardIsLoadBearing :
    ∃ (d : SubmitReportData),
      senderAllowed d = true ∧
      consensusHashMatches d = true ∧
      mintedShares (entryFeeWei d) (entryShareRate d)
        ≤ pinnedSharesToMintAsFees d ∧
      ¬ EntryDomainValid d :=
  ⟨domainInvalidReport, by decide, by decide,
    existingBoundHoldsOnInvalidDomain,
    domainInvalidReportNotValid⟩

/-- Non-exact-divisibility positive control: an `EntryDomainValid` input
where `feeShareRateDenominator` does NOT divide `internalSharesBeforeFees *
E27` — the divisibility premise of `entry_mint_eq_pinned_of_domain` fails —
yet the E27-quantized mint still equals the pinned formula because `E27`
is large enough to absorb the rounding remainder on practical-sized values.

Report: `totalFee = 70`, `precisionPoints = 100`, giving `feeEther = 7`,
`internalSharesBeforeFees = 200`, `feeShareRateDenominator = 103`.
`200 * E27 mod 103 ≠ 0`, so the rate is truncated, but
`7 * floor(200 * E27 / 103) / E27 = 7 * 200 / 103 = 13` — the
double-rounding loss is sub-unit and vanishes under the final Nat
division.  This confirms that `≤` is tight on realistic values and
that the `∣`-conditional `=` is stronger than needed on this vector. -/
private def nonExactReport : SubmitReportData :=
  { report := routerReport
    dataHash := 77
    consensusHash := 77
    senderIsMemberOrHasRole := true
    preTotalPooledEther := 100
    preExternalEther := 0
    preTotalShares := 200
    preExternalShares := 0
    preClValidatorsBalance := 50
    preClPendingBalance := 0
    depositedBalance := 0
    clValidatorsBalance := 60
    clPendingBalance := 0
    withdrawalsVaultTransfer := 0
    elRewardsVaultTransfer := 0
    totalSharesToBurn := 0
    etherToFinalizeWQ := 0
    totalFee := 70
    precisionPoints := 100 }

theorem nonExactReportDomainValid : EntryDomainValid nonExactReport :=
  ⟨by decide, by decide, by decide, by decide, by decide, by decide, by decide, by decide⟩

/-- The non-exact report's rate denominator does NOT divide
`internalSharesBeforeFees * E27`, confirming the divisibility premise
is not vacuously satisfied. -/
theorem nonExactReportNotDivisible :
    ¬ (feeShareRateDenominator nonExactReport
        ∣ internalSharesBeforeFees nonExactReport * E27) := by decide

/-- Despite non-divisibility, the E27-quantized mint equals the pinned
formula — the `≤` bound is tight on realistic witness values. -/
theorem nonExactReportMintEqualsPinned :
    mintedShares (entryFeeWei nonExactReport) (entryShareRate nonExactReport)
      = pinnedSharesToMintAsFees nonExactReport := by decide

/-- Positive control: the standard profitable report is domain-valid. -/
theorem domainValidProfitableReport : EntryDomainValid profitableReport :=
  ⟨by decide, by decide, by decide, by decide, by decide, by decide, by decide, by decide⟩

/-- Positive control: the strengthened parent holds on the profitable
vector.  On this vector the E27 rate divides exactly, so the domain-
conditional equality fires and the computed mint equals the pinned mint
(both `20`). -/
theorem domainValidExactnessPositiveControl :
    let d := profitableReport
    mintedShares (entryFeeWei d) (entryShareRate d)
      = pinnedSharesToMintAsFees d :=
  entry_mint_eq_pinned_of_domain profitableReport
    domainValidProfitableReport (by decide) (by decide)

/-- Regression: the existing non-domain-restricted parent still passes on
the profitable vector (no weakening). -/
theorem existingParentStillPasses :
    observe profitableReport.report
        ((submitReportDataTx profitableReport).run defaultState) =
      sourceView profitableReport.report
        (mintedShares (entryFeeWei profitableReport)
          (entryShareRate profitableReport)) :=
  (POracleSupply1.oracle_supply_submit_report_data_computed_entry
    profitableReport (entryShareRate profitableReport) defaultState
    (by decide) (by decide) (Nat.le_refl _)).2.1

/-- Lossy-quantization witness: `internalSharesBeforeFees = 3`,
`feeShareRateDenominator = 7`, `feeEther = 7`.  The E27-scaled rate
`3 * E27 / 7` truncates, so `mintedShares 7 (3*E27/7) / E27 = 2` while
`pinnedSharesToMintAsFees = 7 * 3 / 7 = 3`. -/
private def lossyQuantReport : SubmitReportData :=
  { report := routerReport
    dataHash := 77
    consensusHash := 77
    senderIsMemberOrHasRole := true
    preTotalPooledEther := 0
    preExternalEther := 0
    preTotalShares := 3
    preExternalShares := 0
    preClValidatorsBalance := 0
    preClPendingBalance := 0
    depositedBalance := 0
    clValidatorsBalance := 14
    clPendingBalance := 0
    withdrawalsVaultTransfer := 0
    elRewardsVaultTransfer := 0
    totalSharesToBurn := 0
    etherToFinalizeWQ := 0
    totalFee := 1
    precisionPoints := 2 }

/-- Kill-line: dropping the source-domain guard (EntryDomainValid,
divisibility) from the five-conjunct parent makes it refutable — the
E27-quantized mint `2` is strictly less than the pinned mint `3` on
`lossyQuantReport`, so the equality conjunct fails. -/
theorem domain_guard_kill_line_refutes_full_parent :
    ¬ ∀ (d : SubmitReportData) (maxShareRate : Nat) (state : ContractState),
      senderAllowed d = true →
      consensusHashMatches d = true →
      entryShareRate d ≤ maxShareRate →
      (submitReportDataTx d).run state =
          (handleOracleReportComputed d.report (entryFeeWei d)
            (entryShareRate d)).run state ∧
        observe d.report ((submitReportDataTx d).run state) =
          sourceView d.report
            (mintedShares (entryFeeWei d) (entryShareRate d)) ∧
        mintedShares (entryFeeWei d) (entryShareRate d)
            ≤ pinnedSharesToMintAsFees d ∧
        mintedShares (entryFeeWei d) (entryShareRate d)
            ≤ entryFeeWei d * maxShareRate / E27 ∧
        mintedShares (entryFeeWei d) (entryShareRate d)
            = pinnedSharesToMintAsFees d := by
  intro h
  have hAll := h lossyQuantReport (entryShareRate lossyQuantReport)
    defaultState (by decide) (by decide) (Nat.le_refl _)
  exact absurd hAll.2.2.2.2 (by decide)

/-- Zero-precision profitable witness: profitable branch with
`precisionPoints = 0`.  Solidity reverts on the division, but Lean
`Nat.div 0` yields `0`. -/
private def zeroPrecisionProfitableReport : SubmitReportData :=
  { profitableReport with precisionPoints := 0 }

/-- The zero-precision witness is profitable yet violates
`EntryDomainValid.precisionPos`. -/
theorem zeroPrecisionNotDomainValid :
    principalClBalance zeroPrecisionProfitableReport
        < unifiedClBalance zeroPrecisionProfitableReport ∧
      ¬ EntryDomainValid zeroPrecisionProfitableReport := by
  constructor
  · decide
  · intro h; exact absurd (h.precisionPos (by decide)) (by decide)

/-- Zero-denominator profitable witness: profitable branch, positive fee,
but `postInternalEther = feeEther` so `feeShareRateDenominator = 0`.
Solidity L317-331 always evaluates the division and would revert. -/
private def zeroDenomProfitableReport : SubmitReportData :=
  { report := routerReport
    dataHash := 77
    consensusHash := 77
    senderIsMemberOrHasRole := true
    preTotalPooledEther := 10
    preExternalEther := 0
    preTotalShares := 200
    preExternalShares := 0
    preClValidatorsBalance := 0
    preClPendingBalance := 0
    depositedBalance := 0
    clValidatorsBalance := 20
    clPendingBalance := 0
    withdrawalsVaultTransfer := 0
    elRewardsVaultTransfer := 0
    totalSharesToBurn := 0
    etherToFinalizeWQ := 10
    totalFee := 100
    precisionPoints := 100 }

/-- The zero-denominator witness is profitable yet violates
`EntryDomainValid.feeDenom`. -/
theorem zeroDenomNotDomainValid :
    principalClBalance zeroDenomProfitableReport
        < unifiedClBalance zeroDenomProfitableReport ∧
      feeShareRateDenominator zeroDenomProfitableReport = 0 ∧
      ¬ EntryDomainValid zeroDenomProfitableReport := by
  refine ⟨by decide, by decide, ?_⟩
  intro h; exact absurd (h.feeDenom (by decide)) (by decide)

/-- A-REWARD-09 counterexample: `totalFee = 2 > precisionPoints = 1` on the
profitable branch.  Solidity reverts at `getStakingRewardsDistribution`
(`af095e48:870`); the Lean model silently computes `feeEther = 2` from
`totalRewards = 1`, exceeding total rewards. -/
private def feeBoundWitness : SubmitReportData :=
  { report := routerReport
    dataHash := 77
    consensusHash := 77
    senderIsMemberOrHasRole := true
    preTotalPooledEther := 2
    preExternalEther := 0
    preTotalShares := 1
    preExternalShares := 0
    preClValidatorsBalance := 0
    preClPendingBalance := 0
    depositedBalance := 0
    clValidatorsBalance := 1
    clPendingBalance := 0
    withdrawalsVaultTransfer := 0
    elRewardsVaultTransfer := 0
    totalSharesToBurn := 0
    etherToFinalizeWQ := 0
    totalFee := 2
    precisionPoints := 1 }

/-- The feeBound witness is profitable with `totalFee > precisionPoints`,
violating `EntryDomainValid.feeBound`. -/
theorem feeBoundWitnessNotDomainValid :
    principalClBalance feeBoundWitness
        < unifiedClBalance feeBoundWitness ∧
      feeBoundWitness.totalFee > feeBoundWitness.precisionPoints ∧
      ¬ EntryDomainValid feeBoundWitness := by
  refine ⟨by decide, by decide, ?_⟩
  intro h; exact absurd (h.feeBound (by decide)) (by decide)

/-- The existing bound conjunct holds on the feeBound witness (the model
accepts it), demonstrating the gap between the model's domain and the
Solidity `totalFee ≤ precisionPoints` assertion. -/
theorem existingBoundHoldsOnFeeBoundWitness :
    mintedShares (entryFeeWei feeBoundWitness)
        (entryShareRate feeBoundWitness)
      ≤ pinnedSharesToMintAsFees feeBoundWitness :=
  entry_mint_le_pinned_shares feeBoundWitness

/-- feeBound is load-bearing: there exists an input the model accepts
(existing bound holds, sender allowed, consensus hash matches) but
`EntryDomainValid` rejects because `totalFee > precisionPoints`
(pinned A-REWARD-09). -/
theorem feeBoundIsLoadBearing :
    ∃ (d : SubmitReportData),
      senderAllowed d = true ∧
      consensusHashMatches d = true ∧
      mintedShares (entryFeeWei d) (entryShareRate d)
        ≤ pinnedSharesToMintAsFees d ∧
      ¬ EntryDomainValid d :=
  ⟨feeBoundWitness, by decide, by decide,
    existingBoundHoldsOnFeeBoundWitness,
    feeBoundWitnessNotDomainValid.2.2⟩

end LidoSRv3.Tests.PackO2SupplyDomainMutants
