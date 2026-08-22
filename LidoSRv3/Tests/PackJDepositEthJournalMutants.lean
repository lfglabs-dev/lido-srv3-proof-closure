import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Spec.DepositEthJournalCorrespondence
import LidoSRv3.Audit.Verity.DepositParentTx

/-!
# Leftover J-DEPOSIT fail-closed vectors

Unregistered Spec.EthJournal child. A consolidation or refund Spec dest
is not a deposit-success destination. A residual third dest has no
deposit Spec projection.
-/

namespace LidoSRv3.Tests.PackJDepositEthJournalMutants

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.DepositEthJournalCorrespondence
open LidoSRv3.Audit.Verity.DepositParentTx

/-- Honest success journal on the canonical two-batch deposit. -/
private def honestJournal : EthJournal :=
  specJournalOfDeposit canonicalInputs

/-- Mutant: injects a consolidation Spec dest into the deposit journal. -/
private def consolidationMutantJournal : EthJournal :=
  honestJournal ++ [{ dest := .consolidationRequest, wei := ⟨1⟩ }]

/-- Mutant: routes the first beacon push to `.refundRecipient`. -/
private def refundMutantJournal : EthJournal :=
  [{ dest := .lidoPull, wei := ⟨(totalAmount canonicalInputs).val⟩ },
   { dest := .refundRecipient, wei := ⟨canonicalInputs.first.amount.val⟩ },
   { dest := .beaconDeposit, wei := ⟨canonicalInputs.second.amount.val⟩ }]

/-- Mutant: routes the second beacon push to a residual third dest. -/
private def thirdDestMutantLegs : List DepositValueLeg :=
  [{ dest := .lidoWithdraw, wei := (totalAmount canonicalInputs).val },
   { dest := .beaconPush, wei := canonicalInputs.first.amount.val },
   { dest := .residual 999, wei := canonicalInputs.second.amount.val }]

/-- Positive: the honest success journal projects onto Spec.EthJournal. -/
theorem honest_success_projects :
    (specJournalOfDeposit canonicalInputs).map (fun leg => leg.wei.value) =
      [(totalAmount canonicalInputs).val,
        canonicalInputs.first.amount.val, canonicalInputs.second.amount.val] ∧
    (specJournalOfDeposit canonicalInputs).map (fun leg => leg.dest) =
      [.lidoPull, .beaconDeposit, .beaconDeposit] ∧
    (∀ leg, leg ∈ specJournalOfDeposit canonicalInputs →
      isDepositSuccessDest leg.dest = true) :=
  deposit_success_journal_projects_to_spec canonicalInputs

/-- Kill-line: adding `.consolidationRequest` or routing a beacon push to
`.refundRecipient` falsifies "every dest is lidoPull or beaconDeposit". -/
theorem consolidation_or_refund_dest_kill_line_refutes_deposit_dests :
    ¬ (∀ leg, leg ∈ consolidationMutantJournal →
        isDepositSuccessDest leg.dest = true) ∧
    ¬ (∀ leg, leg ∈ refundMutantJournal →
        isDepositSuccessDest leg.dest = true) := by
  constructor
  · intro h
    have ht : isDepositSuccessDest .consolidationRequest = true :=
      h ⟨.consolidationRequest, ⟨1⟩⟩ (by decide)
    simp [isDepositSuccessDest] at ht
  · intro h
    have ht : isDepositSuccessDest .refundRecipient = true :=
      h ⟨.refundRecipient, ⟨canonicalInputs.first.amount.val⟩⟩ (by decide)
    simp [isDepositSuccessDest] at ht

/-- Kill-line: routing a beacon push to a residual third dest falsifies
the Spec projection totality conjunct. -/
theorem third_destination_beacon_push_kill_line_refutes_projection_totality :
    ¬ (∀ m, m ∈ thirdDestMutantLegs → specDest m.dest ≠ none) := by
  intro h
  have hNone : specDest (.residual 999) = none := specDest_residual 999
  exact (h ⟨.residual 999, canonicalInputs.second.amount.val⟩ (by decide)) hNone

end LidoSRv3.Tests.PackJDepositEthJournalMutants
