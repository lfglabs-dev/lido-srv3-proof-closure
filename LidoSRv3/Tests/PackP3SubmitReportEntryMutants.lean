import LidoSRv3.Audit.Guarantees.POracleSupply1

/-!
# Node P3 fail-closed vectors

Parent-shaped negations for the P-ORACLE-SUPPLY-1 modeled
`submitReportData` entry
(`oracle_supply_submit_report_data_computed_entry`). Every mutant keeps
every premise of the parent — the checked `senderAllowed` /
`consensusHashMatches` gates and the named `entryShareRate d ≤ maxShareRate`
cap — and is refuted on a nonempty report witness.

1. `submitReportEntryStillFree`: the entry still takes a free
   `sharesToMintAsFees` argument instead of computing the pair.
2. `submitReportEntrySkipsSimulate`: the entry skips
   `_simulateOracleReport` — no LIP-12 profitability branch, no
   fee-adjusted share-rate division — and mints the raw unguarded fee
   ether directly.
3. `hash_premise_is_load_bearing`: dropping the consensus-hash premise
   makes even the honest entry refutable, so the checked gate is
   load-bearing rather than decorative.

The existing free-argument / sum-balances / raw-fee kill-lines of the
computed-wrapper parent stay in `PackN3OracleMintMutants` untouched.
-/

namespace LidoSRv3.Tests.PackP3SubmitReportEntryMutants

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

/-- Profitable nonempty witness: principal `50`, unified `60`, rewards
`10`, fee params `100/100`, so `feeEther = 10`; post-internal ether `110`,
denominator `100`, internal shares `200`, so `entryShareRate = 2 * E27`
and the computed mint is `20` — exactly the pinned
`10 * 200 / 100 = 20`. -/
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

/-- Non-profitable witness (LIP-12): unified `40` ≤ principal `50`, so the
pinned branch mints nothing, but the EL rewards vault transfer is `100`,
so an unguarded fee pipeline still computes a positive fee. -/
private def nonprofitableReport : SubmitReportData :=
  { profitableReport with
    clValidatorsBalance := 40
    elRewardsVaultTransfer := 100 }

/-- Mutant entry: same checked gates, but the mint is still a free
`sharesToMintAsFees` argument — the entry never computes the pair. -/
def submitReportEntryStillFree (d : SubmitReportData)
    (sharesToMintAsFees : Nat) : Contract Result := fun snapshot =>
  if senderAllowed d then
    if consensusHashMatches d then
      handleOracleReport d.report sharesToMintAsFees
        (failAfterWrites := false) snapshot
    else .revert "UNEXPECTED_DATA_HASH" snapshot
  else .revert "SENDER_NOT_ALLOWED" snapshot

private theorem still_free_runs_free_mint (d : SubmitReportData)
    (sharesToMintAsFees : Nat) (state : ContractState)
    (hSender : senderAllowed d = true)
    (hHash : consensusHashMatches d = true) :
    (submitReportEntryStillFree d sharesToMintAsFees).run state =
      (handleOracleReport d.report sharesToMintAsFees).run state := by
  unfold submitReportEntryStillFree Contract.run
  simp [hSender, hHash]

/-- Kill-line 1: an entry that still takes a free mint does not satisfy the
parent's computed-entry conjunct. Premises retained (checked gates and the
`entryShareRate d ≤ maxShareRate` binder). On the profitable witness the
computed mint is `20` (journals `.rewardsMinted`), while the free argument
`0` journals no mint step. -/
theorem still_free_entry_kill_line_refutes_parent :
    ¬ ∀ (d : SubmitReportData) (sharesToMintAsFees maxShareRate : Nat)
        (state : ContractState),
        senderAllowed d = true →
        consensusHashMatches d = true →
        entryShareRate d ≤ maxShareRate →
        observe d.report
            ((submitReportEntryStillFree d sharesToMintAsFees).run state) =
          sourceView d.report
            (mintedShares (entryFeeWei d) (entryShareRate d)) := by
  intro h
  have hEq := h profitableReport 0 (entryShareRate profitableReport)
    defaultState (by decide) (by decide) (Nat.le_refl _)
  rw [still_free_runs_free_mint profitableReport 0 defaultState
    (by decide) (by decide)] at hEq
  rw [verity_tx_simulates_pinned_source profitableReport.report 0
    defaultState] at hEq
  have hMint : mintedShares (entryFeeWei profitableReport)
      (entryShareRate profitableReport) = 20 := by decide
  rw [hMint] at hEq
  have hAcc : accept profitableReport.report = some ⟨[1, 2], [10, 20], 30⟩ := by
    decide
  have hHas : .rewardsMinted ∈ (sourceView profitableReport.report 20).steps := by
    simp [sourceView, hAcc, successfulSteps]
  have hNone : .rewardsMinted ∉ (sourceView profitableReport.report 0).steps := by
    simp [sourceView, hAcc, successfulSteps]
  exact (hEq ▸ hNone) hHas

/-- Mutant fee pipeline with `_simulateOracleReport` skipped: no LIP-12
`unifiedClBalance > principalClBalance` branch and no fee-adjusted
share-rate division — the raw (truncated) reward fee ether is minted
directly as shares. -/
def feeEtherNoSimulate (d : SubmitReportData) : Nat :=
  (unifiedClBalance d - principalClBalance d + d.elRewardsVaultTransfer)
    * d.totalFee / d.precisionPoints

/-- Mutant entry built on the skipped-simulation fee. -/
def submitReportEntrySkipsSimulate (d : SubmitReportData) :
    Contract Result := fun snapshot =>
  if senderAllowed d then
    if consensusHashMatches d then
      handleOracleReport d.report (feeEtherNoSimulate d)
        (failAfterWrites := false) snapshot
    else .revert "UNEXPECTED_DATA_HASH" snapshot
  else .revert "SENDER_NOT_ALLOWED" snapshot

private theorem skips_simulate_runs_raw_fee (d : SubmitReportData)
    (state : ContractState)
    (hSender : senderAllowed d = true)
    (hHash : consensusHashMatches d = true) :
    (submitReportEntrySkipsSimulate d).run state =
      (handleOracleReport d.report (feeEtherNoSimulate d)).run state := by
  unfold submitReportEntrySkipsSimulate Contract.run
  simp [hSender, hHash]

/-- Kill-line 2: an entry that skips `_simulateOracleReport` does not
satisfy the parent's computed-entry conjunct. Premises retained. On the
non-profitable witness LIP-12 makes the computed mint `0` (no
`.rewardsMinted` step), while the unguarded pipeline mints
`(0 + 100) * 100 / 100 = 100` and journals the step. -/
theorem skips_simulate_kill_line_refutes_parent :
    ¬ ∀ (d : SubmitReportData) (maxShareRate : Nat) (state : ContractState),
        senderAllowed d = true →
        consensusHashMatches d = true →
        entryShareRate d ≤ maxShareRate →
        observe d.report ((submitReportEntrySkipsSimulate d).run state) =
          sourceView d.report
            (mintedShares (entryFeeWei d) (entryShareRate d)) := by
  intro h
  have hEq := h nonprofitableReport (entryShareRate nonprofitableReport)
    defaultState (by decide) (by decide) (Nat.le_refl _)
  rw [skips_simulate_runs_raw_fee nonprofitableReport defaultState
    (by decide) (by decide)] at hEq
  rw [verity_tx_simulates_pinned_source nonprofitableReport.report
    (feeEtherNoSimulate nonprofitableReport) defaultState] at hEq
  have hRaw : feeEtherNoSimulate nonprofitableReport = 100 := by decide
  have hMint : mintedShares (entryFeeWei nonprofitableReport)
      (entryShareRate nonprofitableReport) = 0 :=
    entry_mint_zero_of_nonprofitable nonprofitableReport (by decide)
  rw [hRaw, hMint] at hEq
  have hAcc : accept nonprofitableReport.report =
      some ⟨[1, 2], [10, 20], 30⟩ := by decide
  have hHas : .rewardsMinted ∈
      (sourceView nonprofitableReport.report 100).steps := by
    simp [sourceView, hAcc, successfulSteps]
  have hNone : .rewardsMinted ∉
      (sourceView nonprofitableReport.report 0).steps := by
    simp [sourceView, hAcc, successfulSteps]
  exact (hEq ▸ hHas) |> hNone

/-- Hash-mismatch witness: same profitable report, wrong data hash. -/
private def mismatchedHashReport : SubmitReportData :=
  { profitableReport with dataHash := 78 }

/-- The consensus-hash premise is load-bearing: without it, even the honest
entry is refutable — the mismatched hash reverts while the source view at
the computed mint commits. -/
theorem hash_premise_is_load_bearing :
    ¬ ∀ (d : SubmitReportData) (state : ContractState),
        senderAllowed d = true →
        observe d.report ((submitReportDataTx d).run state) =
          sourceView d.report
            (mintedShares (entryFeeWei d) (entryShareRate d)) := by
  intro h
  have hEq := h mismatchedHashReport defaultState (by decide)
  rw [entry_reverts_on_hash_mismatch mismatchedHashReport defaultState
    (by decide) (by decide)] at hEq
  have hAcc : accept mismatchedHashReport.report =
      some ⟨[1, 2], [10, 20], 30⟩ := by decide
  simp [observe, sourceView, hAcc] at hEq

/-- The sender premise is load-bearing symmetrically. -/
private def disallowedSenderReport : SubmitReportData :=
  { profitableReport with senderIsMemberOrHasRole := false }

theorem sender_premise_is_load_bearing :
    ¬ ∀ (d : SubmitReportData) (state : ContractState),
        consensusHashMatches d = true →
        observe d.report ((submitReportDataTx d).run state) =
          sourceView d.report
            (mintedShares (entryFeeWei d) (entryShareRate d)) := by
  intro h
  have hEq := h disallowedSenderReport defaultState (by decide)
  rw [entry_reverts_on_disallowed_sender disallowedSenderReport defaultState
    (by decide)] at hEq
  have hAcc : accept disallowedSenderReport.report =
      some ⟨[1, 2], [10, 20], 30⟩ := by decide
  simp [observe, sourceView, hAcc] at hEq

/-- Positive control: the honest entry passes the parent shape on the
profitable witness, and both the computed and the pinned mint are `20`
there (the `E27`-quantized rate is exact on this vector). -/
theorem honest_entry_passes_profitable_vector :
    observe profitableReport.report
        ((submitReportDataTx profitableReport).run defaultState) =
      sourceView profitableReport.report 20 ∧
    mintedShares (entryFeeWei profitableReport)
        (entryShareRate profitableReport) = 20 ∧
    pinnedSharesToMintAsFees profitableReport = 20 := by
  have hMint : mintedShares (entryFeeWei profitableReport)
      (entryShareRate profitableReport) = 20 := by decide
  refine ⟨?_, hMint, by decide⟩
  have h := (POracleSupply1.oracle_supply_submit_report_data_computed_entry
    profitableReport (entryShareRate profitableReport) defaultState
    (by decide) (by decide) (Nat.le_refl _)).2.1
  rw [hMint] at h
  exact h

/-- Positive control (LIP-12): the honest entry mints nothing on the
non-profitable witness. -/
theorem honest_entry_nonprofitable_mints_nothing :
    mintedShares (entryFeeWei nonprofitableReport)
      (entryShareRate nonprofitableReport) = 0 :=
  entry_mint_zero_of_nonprofitable nonprofitableReport (by decide)

end LidoSRv3.Tests.PackP3SubmitReportEntryMutants
