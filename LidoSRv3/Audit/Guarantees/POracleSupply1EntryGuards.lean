import LidoSRv3.Audit.Guarantees.POracleSupply1
import LidoSRv3.Audit.Guarantees.PAccount1SubmitReportGuards

/-! # P-ORACLE-SUPPLY-1 entry guards: the supply parent's entry premises are executed

`POracleSupply1.oracle_supply_submit_report_data_computed_entry` and
`oracle_supply_entry_source_domain` take the entry gates
(`senderAllowed d = true`, `consensusHashMatches d = true`) as *supplied*
premises, and the registry recorded, as a Not-proven bullet, that the pinned
`AccountingOracle.submitReportData` contract-version, consensus-version,
ref-slot and processing-deadline checks were "not modeled" on this row.

`PAccount1SubmitReportGuards.submitReportDataGuarded` (caveat C4, 2026-09-19)
executes that whole ladder in source order — and it does so on the *same*
`LidoSRv3.Audit.SolidityAccounting.SubmitReportEntry.SubmitReportData`
that P-ORACLE-SUPPLY-1's entry consumes, so the two are composable without a
new model, a new assumption or a restated statement.

This module performs the composition:

* `guards_discharge_entry_premises`: every guarded run that reaches a body
  passed all eight checks (`PAccount1SubmitReportGuards.body_passed`), and the
  two premises the supply entry supplies are *derived* from that passing
  ladder rather than assumed.
* `supply_entry_under_executed_guards` / `supply_entry_source_domain_under_executed_guards`:
  the registered P-ORACLE-SUPPLY-1 entry conjuncts, verbatim, hold for every
  guarded run that reaches a body — the entry mint is the computed pair, it
  simulates the pinned source view, it is bounded by the pinned
  `_calculateTotalProtocolFeeShares` division and by the named cap, and under
  `EntryDomainValid` plus divisibility it equals the pinned division.
* `contract_version_checked`, `ref_slot_checked`, `consensus_version_checked`,
  `deadline_checked`: each of the four checks named in the retired bullet
  reverts with the source's error and reaches no supply entry at all.

What this does **not** close, and what stays published on the row: the
consensus hash is still an opaque word equality rather than `keccak256` of the
ABI-encoded report calldata (`consensusHashMatches` compares
`d.dataHash` with `d.consensusHash`; no preimage is modeled), and extra-data
processing is still outside the modeled body. Those remain Not-proven bullets.

**Status:** real theorems with complete proofs, no new axioms beyond the
imported ones (`propext`, `Classical.choice`, `Quot.sound`).
-/

set_option autoImplicit false

namespace LidoSRv3.Audit.Guarantees.POracleSupply1EntryGuards

open _root_.Verity
open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.OracleMintCorrespondence
open LidoSRv3.Audit.Verity.HandleOracleReportTx
open LidoSRv3.Audit.SolidityAccounting.SubmitReportEntry
open LidoSRv3.Audit.Verity.SubmitReportEntryTx

variable (accounting : AccountAddress.AccountingCall.Environment)
  (treasury : AccountAddress.TreasuryCall.Environment)
  (accountingAddress : Nat) (layout : AccountAddress.ReportWriteFee.Layout)
  (o : PAccount1SubmitReportGuards.OracleState)
  (a : PAccount1SubmitReportGuards.CallArgs)
  (d : SubmitReportData) (before : AccountAddress.ReportFeeAccountingCall.World)

/-- The eight executed checks deliver exactly the two premises the registered
P-ORACLE-SUPPLY-1 entry parent takes as hypotheses. `consensusHashMatches`
is derived from the executed `_checkConsensusData` data-hash comparison
together with the datum's coherence with the stored report hash. -/
theorem guards_discharge_entry_premises
    (hp : PAccount1SubmitReportGuards.Passed o a d)
    (hcoh : d.consensusHash = o.reportHash) :
    senderAllowed d = true ∧ consensusHashMatches d = true := by
  obtain ⟨hs, _, _, _, hh, _, _, _⟩ := hp
  exact ⟨hs, by simp [consensusHashMatches, hh, hcoh]⟩

/-- Every guarded run that reaches a body passed the ladder. -/
theorem body_run_passed (r : AccountAddress.ReportFeeTreasuryCall.Outcome)
    (hbody : (PAccount1SubmitReportGuards.submitReportDataGuarded accounting treasury
        accountingAddress layout o a d before).outcome = .body r) :
    PAccount1SubmitReportGuards.Passed o a d :=
  PAccount1SubmitReportGuards.body_passed accounting treasury accountingAddress layout o a d
    before r hbody

/-- **The registered P-ORACLE-SUPPLY-1 entry conjuncts under the executed
ladder.** For every guarded run that reaches a body, the pinned
contract-version, ref-slot, consensus-version, data-hash, report-presence,
deadline and already-processing checks have been executed and passed, and the
entry parent's four conjuncts hold at that datum. -/
theorem supply_entry_under_executed_guards
    (maxShareRate : Nat) (state : ContractState)
    (r : AccountAddress.ReportFeeTreasuryCall.Outcome)
    (hbody : (PAccount1SubmitReportGuards.submitReportDataGuarded accounting treasury
        accountingAddress layout o a d before).outcome = .body r)
    (hcoh : d.consensusHash = o.reportHash)
    (hCap : entryShareRate d ≤ maxShareRate) :
    PAccount1SubmitReportGuards.Passed o a d ∧
      ((submitReportDataTx d).run state =
          (handleOracleReportComputed d.report (entryFeeWei d)
            (entryShareRate d)).run state ∧
        observe d.report ((submitReportDataTx d).run state) =
          sourceView d.report
            (mintedShares (entryFeeWei d) (entryShareRate d)) ∧
        mintedShares (entryFeeWei d) (entryShareRate d)
            ≤ pinnedSharesToMintAsFees d ∧
        mintedShares (entryFeeWei d) (entryShareRate d)
            ≤ entryFeeWei d * maxShareRate / E27) := by
  have hp := body_run_passed accounting treasury accountingAddress layout o a d before r hbody
  obtain ⟨hs, hh⟩ := guards_discharge_entry_premises o a d hp hcoh
  exact ⟨hp, POracleSupply1.oracle_supply_submit_report_data_computed_entry
    d maxShareRate state hs hh hCap⟩

/-- Source-domain strengthening under the executed ladder: the same run also
gives the pinned `_calculateTotalProtocolFeeShares` equality under
`EntryDomainValid` and exact E27 divisibility. -/
theorem supply_entry_source_domain_under_executed_guards
    (maxShareRate : Nat) (state : ContractState)
    (r : AccountAddress.ReportFeeTreasuryCall.Outcome)
    (hbody : (PAccount1SubmitReportGuards.submitReportDataGuarded accounting treasury
        accountingAddress layout o a d before).outcome = .body r)
    (hcoh : d.consensusHash = o.reportHash)
    (hCap : entryShareRate d ≤ maxShareRate)
    (hDom : EntryDomainValid d)
    (hExact : feeShareRateDenominator d ∣ internalSharesBeforeFees d * E27)
    (hDiv : feeShareRateDenominator d
      ∣ entryFeeWei d * internalSharesBeforeFees d) :
    PAccount1SubmitReportGuards.Passed o a d ∧
      mintedShares (entryFeeWei d) (entryShareRate d) = pinnedSharesToMintAsFees d := by
  have hp := body_run_passed accounting treasury accountingAddress layout o a d before r hbody
  obtain ⟨hs, hh⟩ := guards_discharge_entry_premises o a d hp hcoh
  exact ⟨hp, (POracleSupply1.oracle_supply_entry_source_domain
    d maxShareRate state hs hh hCap hDom hExact hDiv).2.2.2.2⟩

section checks
variable (hs : senderAllowed d = true)

/-- `_checkContractVersion`: a version mismatch reverts with the source's
error and reaches no supply entry. -/
theorem contract_version_checked (h : a.contractVersion ≠ o.contractVersion) :
    PAccount1SubmitReportGuards.submitReportDataGuarded accounting treasury accountingAddress
        layout o a d before =
      PAccount1SubmitReportGuards.revertWith o "UNEXPECTED_CONTRACT_VERSION" :=
  PAccount1SubmitReportGuards.guard_contract_version accounting treasury accountingAddress layout
    o a d before hs h

/-- `_checkConsensusData`, ref slot. -/
theorem ref_slot_checked (hv : a.contractVersion = o.contractVersion)
    (h : a.refSlot ≠ o.reportRefSlot) :
    PAccount1SubmitReportGuards.submitReportDataGuarded accounting treasury accountingAddress
        layout o a d before =
      PAccount1SubmitReportGuards.revertWith o "UNEXPECTED_REF_SLOT" :=
  PAccount1SubmitReportGuards.guard_ref_slot accounting treasury accountingAddress layout
    o a d before hs hv h

/-- `_checkConsensusData`, consensus version. -/
theorem consensus_version_checked (hv : a.contractVersion = o.contractVersion)
    (hr : a.refSlot = o.reportRefSlot) (h : a.consensusVersion ≠ o.consensusVersion) :
    PAccount1SubmitReportGuards.submitReportDataGuarded accounting treasury accountingAddress
        layout o a d before =
      PAccount1SubmitReportGuards.revertWith o "UNEXPECTED_CONSENSUS_VERSION" :=
  PAccount1SubmitReportGuards.guard_consensus_version accounting treasury accountingAddress layout
    o a d before hs hv hr h

/-- `_startProcessing`, processing deadline. -/
theorem deadline_checked (hv : a.contractVersion = o.contractVersion)
    (hr : a.refSlot = o.reportRefSlot) (hc : a.consensusVersion = o.consensusVersion)
    (hh : d.dataHash = o.reportHash) (hn : o.reportHash ≠ 0)
    (h : o.processingDeadlineTime < o.time) :
    PAccount1SubmitReportGuards.submitReportDataGuarded accounting treasury accountingAddress
        layout o a d before =
      PAccount1SubmitReportGuards.revertWith o "PROCESSING_DEADLINE_MISSED" :=
  PAccount1SubmitReportGuards.guard_deadline accounting treasury accountingAddress layout
    o a d before hs hv hr hc hh hn h

end checks

#print axioms guards_discharge_entry_premises
#print axioms supply_entry_under_executed_guards
#print axioms supply_entry_source_domain_under_executed_guards
#print axioms contract_version_checked
#print axioms deadline_checked

end LidoSRv3.Audit.Guarantees.POracleSupply1EntryGuards
