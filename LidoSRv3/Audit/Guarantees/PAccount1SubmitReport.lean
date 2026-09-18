import LidoSRv3.Audit.Guarantees.PAccount1AccountingCall
import LidoSRv3.Audit.Verity.SubmitReportEntryTx

/-!
# P-ACCOUNT-1 whole transaction: `submitReportData` to the fee execution

`SubmitReportEntryTx.submitReportDataTx` models the pinned oracle entry
`AccountingOracle.submitReportData` (`AccountingOracle.sol:360-366`): the
sender gate of `_checkMsgSenderIsAllowedToSubmitData`, the consensus-hash
equality of `_checkConsensusData`, then `_handleConsensusReportData`. Its
body is the computed-mint wrapper; the registered P-ACCOUNT-1 executor
`ReportFeeAccountingCall.execute` is the physical report/fee path
(`Accounting.handleOracleReport` → `_simulateOracleReport` →
`_calculateProtocolFees` with the router balances written first, the
distribution read from the written router state, the checked fee products,
the accounting CALL, payments and the treasury STATICCALL).

This module links the two:

* `reportWei` / `input` build the executor's `ReportWei` and `Input` from the
  entry's `SubmitReportData`: the same pre-state and report values the entry
  reads (`principalClBalance`, `postInternalEther`, `internalSharesBeforeFees`
  of `SubmitReportFeeCorrespondence`).
* `submitReportData` is the whole transaction with the entry's guard order
  (`guard_sender`, `guard_hash` agree with `entry_reverts_on_disallowed_sender`
  and `entry_reverts_on_hash_mismatch`) and the registered executor as body.
* `checked_fee_ether`: the executor's checked fee pipeline, when it succeeds
  with the distribution's fee parameters, computes exactly the entry's fee
  ether `feeEther d` and mints the pinned `pinnedSharesToMintAsFees d`, i.e.
  `feeEther d * internalSharesBeforeFees d / (postInternalEther d - feeEther d)`.
* `committed_success`: a committed run passed both entry gates and yields the
  registered `Success` data flow (`Prepared`: write, then read, then checked
  fee) with the fee result being the checked split of the pinned shares of
  `feeEther d`.
* `failure_restores`: a reverted body restores the entry world; a guard
  failure executes no body.

Inputs kept as inputs: the registered module list, the reported balances and
the report data (their binding to live membership and to the caller role are
the card's Assumed lines), the accounting/treasury callees and the fee
parameters (`totalFee`, `precisionPoints`) the entry data carries, which the
source reads from the same router getter the executor consumes.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
-/

set_option autoImplicit false

namespace LidoSRv3.Audit.Guarantees.PAccount1SubmitReport
open AccountAddress AccountAddress.ReportWriteFee AccountAddress.StETHMintShares
open AccountAddress.ReportFeeAccountingCall
open LidoSRv3.Audit.SolidityAccounting.SubmitReportEntry

/-- The executor's report words from the entry's report data. -/
def reportWei (d : SubmitReportData) : ReportWei :=
  ⟨d.clValidatorsBalance, d.clPendingBalance, d.withdrawalsVaultTransfer, principalClBalance d,
    d.elRewardsVaultTransfer, postInternalEther d, internalSharesBeforeFees d⟩

/-- The executor's input from the entry's report data. -/
def input (accountingAddress : Nat) (layout : Layout) (d : SubmitReportData) : Input :=
  ⟨accountingAddress, layout, d.report.registeredModuleIds, d.report.reportedModuleIds,
    d.report.balancesGwei, reportWei d⟩

inductive Outcome where
  | entryReverted (reason : String)
  | body (o : ReportFeeTreasuryCall.Outcome)

/-- `AccountingOracle.submitReportData` with the registered report/fee executor
as the body of `_handleConsensusReportData`: the sender gate, the consensus
hash, then the execution. Same guard order as `submitReportDataTx`. -/
def submitReportData (accounting : AccountingCall.Environment) (treasury : TreasuryCall.Environment)
    (accountingAddress : Nat) (layout : Layout) (d : SubmitReportData) (before : World) :
    Outcome × Attempts :=
  if senderAllowed d then
    if consensusHashMatches d then
      let r := execute accounting treasury (input accountingAddress layout d) before
      (.body r.outcome, r.accountingAttempts)
    else (.entryReverted "UNEXPECTED_DATA_HASH", [])
  else (.entryReverted "SENDER_NOT_ALLOWED", [])

/-- The sender gate agrees with the Verity entry. -/
theorem guard_sender (accounting : AccountingCall.Environment) (treasury : TreasuryCall.Environment)
    (accountingAddress : Nat) (layout : Layout) (d : SubmitReportData) (before : World)
    (s : _root_.Verity.ContractState) (h : senderAllowed d = false) :
    (submitReportData accounting treasury accountingAddress layout d before).1 =
        .entryReverted "SENDER_NOT_ALLOWED" ∧
      (LidoSRv3.Audit.Verity.SubmitReportEntryTx.submitReportDataTx d).run s =
        .revert "SENDER_NOT_ALLOWED" s :=
  ⟨by simp [submitReportData, h],
    LidoSRv3.Audit.Verity.SubmitReportEntryTx.entry_reverts_on_disallowed_sender d s h⟩

/-- The consensus-hash gate agrees with the Verity entry. -/
theorem guard_hash (accounting : AccountingCall.Environment) (treasury : TreasuryCall.Environment)
    (accountingAddress : Nat) (layout : Layout) (d : SubmitReportData) (before : World)
    (s : _root_.Verity.ContractState) (hs : senderAllowed d = true)
    (h : consensusHashMatches d = false) :
    (submitReportData accounting treasury accountingAddress layout d before).1 =
        .entryReverted "UNEXPECTED_DATA_HASH" ∧
      (LidoSRv3.Audit.Verity.SubmitReportEntryTx.submitReportDataTx d).run s =
        .revert "UNEXPECTED_DATA_HASH" s :=
  ⟨by simp [submitReportData, hs, h],
    LidoSRv3.Audit.Verity.SubmitReportEntryTx.entry_reverts_on_hash_mismatch d s hs h⟩

/-! The executor's checked arithmetic helpers are private to `ReportFeeMint`;
they are named here through their private identifiers, as the executor's own
replay proofs do (`pinnedMintRoot`). No new constant is introduced. -/
open Lean in
macro "chkWord" : term => pure (mkIdent
  (.str (.str (.str (.num `_private.ReportFeeMint 0) "AccountAddress") "ReportFeeMint") "checkedWord"))
open Lean in
macro "chkAdd" : term => pure (mkIdent
  (.str (.str (.str (.num `_private.ReportFeeMint 0) "AccountAddress") "ReportFeeMint") "checkedAdd"))
open Lean in
macro "chkSub" : term => pure (mkIdent
  (.str (.str (.str (.num `_private.ReportFeeMint 0) "AccountAddress") "ReportFeeMint") "checkedSub"))
open Lean in
macro "chkMul" : term => pure (mkIdent
  (.str (.str (.str (.num `_private.ReportFeeMint 0) "AccountAddress") "ReportFeeMint") "checkedMul"))
open Lean in
macro "chkDiv" : term => pure (mkIdent
  (.str (.str (.str (.num `_private.ReportFeeMint 0) "AccountAddress") "ReportFeeMint") "checkedDiv"))
open Lean in
macro "chkMax" : term => pure (mkIdent
  (.str (.str (.str (.num `_private.ReportFeeMint 0) "AccountAddress") "ReportFeeMint") "uint256Max"))

theorem word_some (n m : Nat) (h : chkWord n = some m) : m = n := by
  change (if n ≤ chkMax then some n else none) = some m at h
  split at h <;> simp_all

theorem add_some (a b c : Nat) (h : chkAdd a b = some c) : c = a + b := by
  change (if a + b ≤ chkMax then some (a + b) else none) = some c at h
  split at h <;> simp_all

theorem sub_some (a b c : Nat) (h : chkSub a b = some c) : b ≤ a ∧ c = a - b := by
  change (if b ≤ a then some (a - b) else none) = some c at h
  split at h <;> simp_all

theorem mul_some (a b c : Nat) (h : chkMul a b = some c) : c = a * b := by
  change (if a * b ≤ chkMax then some (a * b) else none) = some c at h
  split at h <;> simp_all

theorem div_some (a b c : Nat) (h : chkDiv a b = some c) : b ≠ 0 ∧ c = a / b := by
  change (if b = 0 then none else some (a / b)) = some c at h
  split at h <;> simp_all

/-- **The executor's fee is the entry's fee.** When the checked fee pipeline
succeeds on the entry's report words with the distribution's fee parameters,
the shares it mints are the pinned `feeEther * internalShares /
(postInternalEther - feeEther)` at `feeEther = feeEther d`. -/
theorem checked_fee_ether (d : SubmitReportData) (dist : Distribution) (fee : FeeResult)
    (htf : dist.totalFee = d.totalFee) (hpp : dist.precisionPoints = d.precisionPoints)
    (h : ReportFeeMint.checkedFeeProductsFromCommittedGetter (reportWei d) dist = some fee) :
    ReportFeeMint.checkedFeeResultOf dist (pinnedSharesToMintAsFees d) = some fee := by
  unfold ReportFeeMint.checkedFeeProductsFromCommittedGetter at h
  simp only [reportWei] at h
  obtain ⟨validators, hv, h⟩ := Option.bind_eq_some_iff.mp h
  obtain rfl := word_some _ _ hv
  obtain ⟨pending, hp, h⟩ := Option.bind_eq_some_iff.mp h
  obtain rfl := word_some _ _ hp
  obtain ⟨withdrawals, hw, h⟩ := Option.bind_eq_some_iff.mp h
  obtain rfl := word_some _ _ hw
  obtain ⟨principal, hpr, h⟩ := Option.bind_eq_some_iff.mp h
  obtain rfl := word_some _ _ hpr
  obtain ⟨elRewards, hel, h⟩ := Option.bind_eq_some_iff.mp h
  obtain rfl := word_some _ _ hel
  obtain ⟨postEther, hpe, h⟩ := Option.bind_eq_some_iff.mp h
  obtain rfl := word_some _ _ hpe
  obtain ⟨internalShares, his, h⟩ := Option.bind_eq_some_iff.mp h
  obtain rfl := word_some _ _ his
  obtain ⟨totalFee, htf', h⟩ := Option.bind_eq_some_iff.mp h
  obtain rfl := word_some _ _ htf'
  obtain ⟨precision, hpp', h⟩ := Option.bind_eq_some_iff.mp h
  obtain rfl := word_some _ _ hpp'
  obtain ⟨validatorPending, hvp, h⟩ := Option.bind_eq_some_iff.mp h
  obtain rfl := add_some _ _ _ hvp
  obtain ⟨unified, hu, h⟩ := Option.bind_eq_some_iff.mp h
  obtain rfl := add_some _ _ _ hu
  split at h
  · rename_i hlt
    obtain ⟨rewardBeforeEl, hr1, h⟩ := Option.bind_eq_some_iff.mp h
    obtain ⟨_, rfl⟩ := sub_some _ _ _ hr1
    obtain ⟨rewards, hr2, h⟩ := Option.bind_eq_some_iff.mp h
    obtain rfl := add_some _ _ _ hr2
    obtain ⟨feeProduct, hr3, h⟩ := Option.bind_eq_some_iff.mp h
    obtain rfl := mul_some _ _ _ hr3
    obtain ⟨feeEtherW, hr4, h⟩ := Option.bind_eq_some_iff.mp h
    obtain ⟨_, rfl⟩ := div_some _ _ _ hr4
    obtain ⟨denominator, hr5, h⟩ := Option.bind_eq_some_iff.mp h
    obtain ⟨_, rfl⟩ := sub_some _ _ _ hr5
    obtain ⟨sharesProduct, hr6, h⟩ := Option.bind_eq_some_iff.mp h
    obtain rfl := mul_some _ _ _ hr6
    obtain ⟨shares, hr7, h⟩ := Option.bind_eq_some_iff.mp h
    obtain ⟨_, rfl⟩ := div_some _ _ _ hr7
    have hlt' : principalClBalance d < unifiedClBalance d := hlt
    simp only [pinnedSharesToMintAsFees, feeShareRateDenominator, feeEther, totalRewards,
      unifiedClBalance, if_pos hlt', if_pos hlt, htf, hpp] at h ⊢
    exact h
  · rename_i hge
    have hge' : ¬ principalClBalance d < unifiedClBalance d := hge
    simp only [pinnedSharesToMintAsFees, feeEther, if_neg hge', Nat.zero_mul, Nat.zero_div]
    exact h

/-- **Committed whole transaction.** A committed run passed the sender and
consensus-hash gates and yields the registered `Success` data flow at the
entry-derived input: balances written first, distribution read from the
written router state, and the fee result being the checked split of the
pinned shares of the entry's `feeEther d` whenever the distribution carries
the report data's fee parameters. -/
theorem committed_success (accounting : AccountingCall.Environment)
    (treasury : TreasuryCall.Environment) (accountingAddress : Nat) (layout : Layout)
    (d : SubmitReportData) (before post : World) (fee : FeeResult) (events : List Event)
    (payments : Payments) (treasuryAttempts : Attempts)
    (h : (submitReportData accounting treasury accountingAddress layout d before).1 =
      .body (.committed post fee events payments treasuryAttempts)) :
    senderAllowed d = true ∧ consensusHashMatches d = true ∧
    Success accounting treasury (input accountingAddress layout d) before post fee events payments
      treasuryAttempts
      (submitReportData accounting treasury accountingAddress layout d before).2 ∧
    ∃ router distribution,
      reportValidatorBalances layout d.report.registeredModuleIds d.report.reportedModuleIds
        d.report.balancesGwei before.router = .committed router ∧
      getStakingRewardsDistribution layout d.report.registeredModuleIds router = .ok distribution ∧
      ReportFeeMint.checkedFeeProductsFromCommittedGetter (reportWei d) distribution = some fee ∧
      (distribution.totalFee = d.totalFee → distribution.precisionPoints = d.precisionPoints →
        ReportFeeMint.checkedFeeResultOf distribution (pinnedSharesToMintAsFees d) = some fee) := by
  unfold submitReportData at h ⊢
  cases hs : senderAllowed d with
  | false => simp [hs] at h
  | true =>
    cases hc : consensusHashMatches d with
    | false => simp [hs, hc] at h
    | true =>
      simp only [hs, hc, if_true] at h ⊢
      simp only [Outcome.body.injEq] at h
      have hsucc := PAccount1.actual_report_accounting_call accounting treasury
        (input accountingAddress layout d) before post fee events payments treasuryAttempts h
      refine ⟨by simp [hs], by simp [hc], hsucc, ?_⟩
      obtain ⟨router, derived, ⟨distribution, hw, hg, hf⟩, -, -⟩ := hsucc
      exact ⟨router, distribution, hw, hg, hf, fun htf hpp => checked_fee_ether d distribution fee htf hpp hf⟩

/-- **Failure restores.** A reverted body restores the entry world. -/
theorem failure_restores (accounting : AccountingCall.Environment)
    (treasury : TreasuryCall.Environment) (accountingAddress : Nat) (layout : Layout)
    (d : SubmitReportData) (before rollback : World) (fault : ReportFeeTreasuryCall.Error)
    (payments : Payments) (treasuryAttempts : Attempts)
    (h : (submitReportData accounting treasury accountingAddress layout d before).1 =
      .body (.reverted fault rollback payments treasuryAttempts)) :
    rollback = before := by
  unfold submitReportData at h
  cases hs : senderAllowed d with
  | false => simp [hs] at h
  | true =>
    cases hc : consensusHashMatches d with
    | false => simp [hs, hc] at h
    | true =>
      simp only [hs, hc, if_true, Outcome.body.injEq] at h
      exact PAccount1.actual_report_accounting_call_failure_restores accounting treasury
        (input accountingAddress layout d) before rollback fault payments treasuryAttempts h

/-- A guard failure executes no body: the outcome is the entry revert and no
accounting attempt is made. -/
theorem guard_failure_no_body (accounting : AccountingCall.Environment)
    (treasury : TreasuryCall.Environment) (accountingAddress : Nat) (layout : Layout)
    (d : SubmitReportData) (before : World)
    (h : senderAllowed d = false ∨ consensusHashMatches d = false) :
    ∃ reason, submitReportData accounting treasury accountingAddress layout d before =
      (.entryReverted reason, []) := by
  unfold submitReportData
  rcases h with h | h
  · exact ⟨"SENDER_NOT_ALLOWED", by simp [h]⟩
  · cases hs : senderAllowed d
    · exact ⟨"SENDER_NOT_ALLOWED", by simp⟩
    · exact ⟨"UNEXPECTED_DATA_HASH", by simp [h]⟩

#print axioms guard_sender
#print axioms guard_hash
#print axioms checked_fee_ether
#print axioms committed_success
#print axioms failure_restores
#print axioms guard_failure_no_body

end LidoSRv3.Audit.Guarantees.PAccount1SubmitReport
