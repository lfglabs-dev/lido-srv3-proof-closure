import LidoSRv3.Audit.Guarantees.PAccount1SubmitReport

/-! # P-ACCOUNT-1 entry guards: contract version, ref slot, consensus version, processing deadline (caveat C4, 2026-09-19)

`PAccount1SubmitReport.submitReportData` linked the oracle entry to the
registered report/fee executor with two guards (sender, consensus hash). The
pinned `AccountingOracle.submitReportData` (`AccountingOracle.sol:360-366`)
executes, in this order, `_checkMsgSenderIsAllowedToSubmitData`,
`_checkContractVersion(contractVersion)` (`Versioned.sol`),
`_checkConsensusData(data.refSlot, data.consensusVersion, hash)`
(`BaseOracle.sol:300-316`: ref slot, consensus version, data hash against the
stored consensus report), `_startProcessing()` (`BaseOracle.sol:326-343`: a
consensus report exists, the processing deadline is not missed, the ref slot
is not already processing, then the `LAST_PROCESSING_REF_SLOT` write and
`ProcessingStarted`), and `_handleConsensusReportData`.

`submitReportDataGuarded` executes that whole ladder with the source's error
names on the oracle words it reads (`OracleState`: stored contract version,
consensus version, consensus report hash / ref slot / deadline, last processing
ref slot, block time) and the call's arguments (`CallArgs`), then the
registered executor as the body. The oracle words are inputs of this model, as
`consensusHash` already was; the checks on them are executed, not assumed.

* `guard_*`: each failing check reverts with the source's error, executes no
  body, makes no accounting attempt and leaves the oracle state unchanged.
* `refines_entry`: on the passing ladder the outcome is the registered
  `PAccount1SubmitReport.submitReportData` outcome, so `committed_success`
  and `failure_restores` carry over: a committed run passed all eight checks,
  wrote `lastProcessingRefSlot := reportRefSlot`, emitted `ProcessingStarted`
  and yields the registered `Success` data flow at the entry's fee.

Outside the modeled body, as one stated assumption: extra-data processing
(`_handleConsensusReportData`'s extra-data format/hash/count checks and
`submitReportExtraData*`) and the withdrawal queue's `onOracleReport` call.

**Status:** real theorems with complete proofs; axioms `propext`,
`Classical.choice`, `Quot.sound`. -/

set_option autoImplicit false

namespace LidoSRv3.Audit.Guarantees.PAccount1SubmitReportGuards
open AccountAddress AccountAddress.ReportWriteFee AccountAddress.StETHMintShares
open AccountAddress.ReportFeeAccountingCall
open LidoSRv3.Audit.SolidityAccounting.SubmitReportEntry
open LidoSRv3.Audit.Guarantees.PAccount1SubmitReport (input submitReportData)

/-- The oracle words the pinned entry reads: `Versioned.CONTRACT_VERSION_POSITION`,
`BaseOracle.CONSENSUS_VERSION_POSITION`, the stored `ConsensusReport`
(`hash`, `refSlot`, `processingDeadlineTime`),
`LAST_PROCESSING_REF_SLOT_POSITION`, and `_getTime()`. -/
structure OracleState where
  contractVersion : Nat
  consensusVersion : Nat
  reportHash : Nat
  reportRefSlot : Nat
  processingDeadlineTime : Nat
  lastProcessingRefSlot : Nat
  time : Nat
  deriving Repr, DecidableEq

/-- `submitReportData(data, contractVersion)`: the version argument and the
`data.refSlot` / `data.consensusVersion` fields the checks consume. -/
structure CallArgs where
  contractVersion : Nat
  refSlot : Nat
  consensusVersion : Nat
  deriving Repr, DecidableEq

structure Result where
  outcome : PAccount1SubmitReport.Outcome
  attempts : Attempts
  oracle : OracleState
  processingStarted : Bool

def revertWith (o : OracleState) (reason : String) : Result :=
  ⟨.entryReverted reason, [], o, false⟩

/-- The pinned entry ladder in source order, then the registered executor. -/
def submitReportDataGuarded (accounting : AccountingCall.Environment)
    (treasury : TreasuryCall.Environment) (accountingAddress : Nat) (layout : Layout)
    (o : OracleState) (a : CallArgs) (d : SubmitReportData) (before : World) : Result :=
  if senderAllowed d = false then revertWith o "SENDER_NOT_ALLOWED"
  else if a.contractVersion ≠ o.contractVersion then revertWith o "UNEXPECTED_CONTRACT_VERSION"
  else if a.refSlot ≠ o.reportRefSlot then revertWith o "UNEXPECTED_REF_SLOT"
  else if a.consensusVersion ≠ o.consensusVersion then revertWith o "UNEXPECTED_CONSENSUS_VERSION"
  else if d.dataHash ≠ o.reportHash then revertWith o "UNEXPECTED_DATA_HASH"
  else if o.reportHash = 0 then revertWith o "NO_CONSENSUS_REPORT_TO_PROCESS"
  else if o.processingDeadlineTime < o.time then revertWith o "PROCESSING_DEADLINE_MISSED"
  else if o.lastProcessingRefSlot = o.reportRefSlot then revertWith o "REF_SLOT_ALREADY_PROCESSING"
  else
    let r := execute accounting treasury (input accountingAddress layout d) before
    ⟨.body r.outcome, r.accountingAttempts, {o with lastProcessingRefSlot := o.reportRefSlot}, true⟩

/-- All eight checks of the pinned ladder. -/
def Passed (o : OracleState) (a : CallArgs) (d : SubmitReportData) : Prop :=
  senderAllowed d = true ∧ a.contractVersion = o.contractVersion ∧ a.refSlot = o.reportRefSlot ∧
  a.consensusVersion = o.consensusVersion ∧ d.dataHash = o.reportHash ∧ o.reportHash ≠ 0 ∧
  o.time ≤ o.processingDeadlineTime ∧ o.lastProcessingRefSlot ≠ o.reportRefSlot

section guards
variable (accounting : AccountingCall.Environment) (treasury : TreasuryCall.Environment)
  (accountingAddress : Nat) (layout : Layout) (o : OracleState) (a : CallArgs)
  (d : SubmitReportData) (before : World)

theorem guard_sender (h : senderAllowed d = false) :
    submitReportDataGuarded accounting treasury accountingAddress layout o a d before =
      revertWith o "SENDER_NOT_ALLOWED" := by
  unfold submitReportDataGuarded
  rw [if_pos h]

theorem guard_contract_version (hs : senderAllowed d = true)
    (h : a.contractVersion ≠ o.contractVersion) :
    submitReportDataGuarded accounting treasury accountingAddress layout o a d before =
      revertWith o "UNEXPECTED_CONTRACT_VERSION" := by
  unfold submitReportDataGuarded
  rw [if_neg (by simp [hs]), if_pos h]

theorem guard_ref_slot (hs : senderAllowed d = true) (hv : a.contractVersion = o.contractVersion)
    (h : a.refSlot ≠ o.reportRefSlot) :
    submitReportDataGuarded accounting treasury accountingAddress layout o a d before =
      revertWith o "UNEXPECTED_REF_SLOT" := by
  unfold submitReportDataGuarded
  rw [if_neg (by simp [hs]), if_neg (fun e => e hv), if_pos h]

theorem guard_consensus_version (hs : senderAllowed d = true)
    (hv : a.contractVersion = o.contractVersion) (hr : a.refSlot = o.reportRefSlot)
    (h : a.consensusVersion ≠ o.consensusVersion) :
    submitReportDataGuarded accounting treasury accountingAddress layout o a d before =
      revertWith o "UNEXPECTED_CONSENSUS_VERSION" := by
  unfold submitReportDataGuarded
  rw [if_neg (by simp [hs]), if_neg (fun e => e hv), if_neg (fun e => e hr), if_pos h]

theorem guard_data_hash (hs : senderAllowed d = true)
    (hv : a.contractVersion = o.contractVersion) (hr : a.refSlot = o.reportRefSlot)
    (hc : a.consensusVersion = o.consensusVersion) (h : d.dataHash ≠ o.reportHash) :
    submitReportDataGuarded accounting treasury accountingAddress layout o a d before =
      revertWith o "UNEXPECTED_DATA_HASH" := by
  unfold submitReportDataGuarded
  rw [if_neg (by simp [hs]), if_neg (fun e => e hv), if_neg (fun e => e hr), if_neg (fun e => e hc),
    if_pos h]

theorem guard_no_report (hs : senderAllowed d = true)
    (hv : a.contractVersion = o.contractVersion) (hr : a.refSlot = o.reportRefSlot)
    (hc : a.consensusVersion = o.consensusVersion) (hh : d.dataHash = o.reportHash)
    (h : o.reportHash = 0) :
    submitReportDataGuarded accounting treasury accountingAddress layout o a d before =
      revertWith o "NO_CONSENSUS_REPORT_TO_PROCESS" := by
  unfold submitReportDataGuarded
  rw [if_neg (by simp [hs]), if_neg (fun e => e hv), if_neg (fun e => e hr), if_neg (fun e => e hc),
    if_neg (fun e => e hh), if_pos h]

theorem guard_deadline (hs : senderAllowed d = true)
    (hv : a.contractVersion = o.contractVersion) (hr : a.refSlot = o.reportRefSlot)
    (hc : a.consensusVersion = o.consensusVersion) (hh : d.dataHash = o.reportHash)
    (hn : o.reportHash ≠ 0) (h : o.processingDeadlineTime < o.time) :
    submitReportDataGuarded accounting treasury accountingAddress layout o a d before =
      revertWith o "PROCESSING_DEADLINE_MISSED" := by
  unfold submitReportDataGuarded
  rw [if_neg (by simp [hs]), if_neg (fun e => e hv), if_neg (fun e => e hr), if_neg (fun e => e hc),
    if_neg (fun e => e hh), if_neg hn, if_pos h]

theorem guard_already_processing (hs : senderAllowed d = true)
    (hv : a.contractVersion = o.contractVersion) (hr : a.refSlot = o.reportRefSlot)
    (hc : a.consensusVersion = o.consensusVersion) (hh : d.dataHash = o.reportHash)
    (hn : o.reportHash ≠ 0) (hd : o.time ≤ o.processingDeadlineTime)
    (h : o.lastProcessingRefSlot = o.reportRefSlot) :
    submitReportDataGuarded accounting treasury accountingAddress layout o a d before =
      revertWith o "REF_SLOT_ALREADY_PROCESSING" := by
  have hd' : ¬ o.processingDeadlineTime < o.time := by omega
  unfold submitReportDataGuarded
  rw [if_neg (by simp [hs]), if_neg (fun e => e hv), if_neg (fun e => e hr), if_neg (fun e => e hc),
    if_neg (fun e => e hh), if_neg hn, if_neg hd', if_pos h]

/-- Any entry revert executes no body: no accounting attempt, the oracle state
unchanged and processing not started. -/
theorem entry_revert_no_body (reason : String)
    (h : (submitReportDataGuarded accounting treasury accountingAddress layout o a d before).outcome =
      .entryReverted reason) :
    (submitReportDataGuarded accounting treasury accountingAddress layout o a d before).attempts = [] ∧
    (submitReportDataGuarded accounting treasury accountingAddress layout o a d before).oracle = o ∧
    (submitReportDataGuarded accounting treasury accountingAddress layout o a d before).processingStarted
      = false := by
  unfold submitReportDataGuarded at h ⊢
  by_cases h1 : senderAllowed d = false
  · rw [if_pos h1]
    exact ⟨rfl, rfl, rfl⟩
  rw [if_neg h1] at h ⊢
  by_cases h2 : a.contractVersion ≠ o.contractVersion
  · rw [if_pos h2]
    exact ⟨rfl, rfl, rfl⟩
  rw [if_neg h2] at h ⊢
  by_cases h3 : a.refSlot ≠ o.reportRefSlot
  · rw [if_pos h3]
    exact ⟨rfl, rfl, rfl⟩
  rw [if_neg h3] at h ⊢
  by_cases h4 : a.consensusVersion ≠ o.consensusVersion
  · rw [if_pos h4]
    exact ⟨rfl, rfl, rfl⟩
  rw [if_neg h4] at h ⊢
  by_cases h5 : d.dataHash ≠ o.reportHash
  · rw [if_pos h5]
    exact ⟨rfl, rfl, rfl⟩
  rw [if_neg h5] at h ⊢
  by_cases h6 : o.reportHash = 0
  · rw [if_pos h6]
    exact ⟨rfl, rfl, rfl⟩
  rw [if_neg h6] at h ⊢
  by_cases h7 : o.processingDeadlineTime < o.time
  · rw [if_pos h7]
    exact ⟨rfl, rfl, rfl⟩
  rw [if_neg h7] at h ⊢
  by_cases h8 : o.lastProcessingRefSlot = o.reportRefSlot
  · rw [if_pos h8]
    exact ⟨rfl, rfl, rfl⟩
  rw [if_neg h8] at h
  simp at h

/-- On the passing ladder the guarded entry is the registered entry with
`consensusHash := reportHash`, `_startProcessing`'s write and event. -/
theorem refines_entry (hp : Passed o a d) (hcoh : d.consensusHash = o.reportHash) :
    submitReportDataGuarded accounting treasury accountingAddress layout o a d before =
      ⟨(submitReportData accounting treasury accountingAddress layout d before).1,
        (submitReportData accounting treasury accountingAddress layout d before).2,
        {o with lastProcessingRefSlot := o.reportRefSlot}, true⟩ := by
  obtain ⟨hs, hv, hr, hc, hh, hn, hd, hl⟩ := hp
  have hd' : ¬ o.processingDeadlineTime < o.time := by omega
  have hm : consensusHashMatches d = true := by
    simp [consensusHashMatches, hh, hcoh]
  unfold submitReportDataGuarded submitReportData
  rw [if_neg (by simp [hs]), if_neg (fun e => e hv), if_neg (fun e => e hr), if_neg (fun e => e hc),
    if_neg (fun e => e hh), if_neg hn, if_neg hd', if_neg hl, if_pos hs, if_pos hm]

/-- A body outcome came from the passing ladder. -/
theorem body_passed (r : ReportFeeTreasuryCall.Outcome)
    (h : (submitReportDataGuarded accounting treasury accountingAddress layout o a d before).outcome =
      .body r) : Passed o a d := by
  unfold submitReportDataGuarded at h
  by_cases h1 : senderAllowed d = false
  · rw [if_pos h1] at h
    simp [revertWith] at h
  rw [if_neg h1] at h
  by_cases h2 : a.contractVersion ≠ o.contractVersion
  · rw [if_pos h2] at h
    simp [revertWith] at h
  rw [if_neg h2] at h
  by_cases h3 : a.refSlot ≠ o.reportRefSlot
  · rw [if_pos h3] at h
    simp [revertWith] at h
  rw [if_neg h3] at h
  by_cases h4 : a.consensusVersion ≠ o.consensusVersion
  · rw [if_pos h4] at h
    simp [revertWith] at h
  rw [if_neg h4] at h
  by_cases h5 : d.dataHash ≠ o.reportHash
  · rw [if_pos h5] at h
    simp [revertWith] at h
  rw [if_neg h5] at h
  by_cases h6 : o.reportHash = 0
  · rw [if_pos h6] at h
    simp [revertWith] at h
  rw [if_neg h6] at h
  by_cases h7 : o.processingDeadlineTime < o.time
  · rw [if_pos h7] at h
    simp [revertWith] at h
  rw [if_neg h7] at h
  by_cases h8 : o.lastProcessingRefSlot = o.reportRefSlot
  · rw [if_pos h8] at h
    simp [revertWith] at h
  exact ⟨by simpa using h1, by simpa using h2, by simpa using h3, by simpa using h4,
    by simpa using h5, h6, by omega, h8⟩

/-- **Committed whole transaction with the entry guards.** A committed run
passed all eight checks, started processing (`lastProcessingRefSlot :=
reportRefSlot`, `ProcessingStarted`), and yields the registered `Success`
data flow at the entry's fee (`PAccount1SubmitReport.committed_success`). -/
theorem committed_success (hcoh : d.consensusHash = o.reportHash) (post : World)
    (fee : FeeResult) (events : List Event) (payments : Payments) (treasuryAttempts : Attempts)
    (h : (submitReportDataGuarded accounting treasury accountingAddress layout o a d before).outcome =
      .body (.committed post fee events payments treasuryAttempts)) :
    Passed o a d ∧
    (submitReportDataGuarded accounting treasury accountingAddress layout o a d before).oracle =
      {o with lastProcessingRefSlot := o.reportRefSlot} ∧
    (submitReportDataGuarded accounting treasury accountingAddress layout o a d before).processingStarted
      = true ∧
    Success accounting treasury (input accountingAddress layout d) before post fee events payments
      treasuryAttempts
      (submitReportDataGuarded accounting treasury accountingAddress layout o a d before).attempts := by
  have hp := body_passed accounting treasury accountingAddress layout o a d before _ h
  have he := refines_entry accounting treasury accountingAddress layout o a d before hp hcoh
  rw [he] at h ⊢
  have hc := PAccount1SubmitReport.committed_success accounting treasury accountingAddress layout d
    before post fee events payments treasuryAttempts h
  exact ⟨hp, rfl, rfl, hc.2.2.1⟩

/-- **Failure restores.** A reverted body restores the entry world. -/
theorem failure_restores (hcoh : d.consensusHash = o.reportHash) (rollback : World)
    (fault : ReportFeeTreasuryCall.Error) (payments : Payments) (treasuryAttempts : Attempts)
    (h : (submitReportDataGuarded accounting treasury accountingAddress layout o a d before).outcome =
      .body (.reverted fault rollback payments treasuryAttempts)) :
    rollback = before := by
  have hp := body_passed accounting treasury accountingAddress layout o a d before _ h
  have he := refines_entry accounting treasury accountingAddress layout o a d before hp hcoh
  rw [he] at h
  exact PAccount1SubmitReport.failure_restores accounting treasury accountingAddress layout d before
    rollback fault payments treasuryAttempts h

end guards

#print axioms guard_contract_version
#print axioms guard_ref_slot
#print axioms guard_deadline
#print axioms entry_revert_no_body
#print axioms refines_entry
#print axioms committed_success
#print axioms failure_restores

end LidoSRv3.Audit.Guarantees.PAccount1SubmitReportGuards
