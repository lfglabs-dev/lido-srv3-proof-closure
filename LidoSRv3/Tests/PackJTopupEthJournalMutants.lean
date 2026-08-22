import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Spec.TopupEthJournalCorrespondence
import LidoSRv3.Audit.Verity.TopupTx

/-!
# Pack J-TOPUP fail-closed vectors

Unregistered Spec.EthJournal child. A beacon push tagged as Pack B
`.consolidationRequest` is not a Join dest. A nonempty journal on a
wrap-to-zero batch fails emptiness.
-/

namespace LidoSRv3.Tests.PackJTopupEthJournalMutants

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.TopupEthJournalCorrespondence
open LidoSRv3.Audit.Verity.TopupTx
open LidoSRv3.Audit.SolidityTopup

/-- Honest value-moving schedule: pull 8, push 3, skip 0, push 5. -/
private def honestAllocations : List Nat := [3, 0, 5]

private def honestJournal : EthJournal :=
  specJournalOfTopup honestAllocations

/-- Mutant: retag every beacon push as the Pack B consolidation dest. -/
def mutantBeaconAsConsolidation : EthJournal :=
  honestJournal.map fun leg =>
    if leg.dest == .beaconDeposit then
      { dest := .consolidationRequest, wei := leg.wei }
    else
      leg

/-- Classic wrap-to-zero: exact sum is the modulus, unchecked reading is 0. -/
def wrapToZeroAllocations : List Nat := [uint256Modulus - 1, 1]

/-- Mutant: invent a Lido pull when the wrapped total is 0. -/
def mutantNonemptyOnWrapZero : EthJournal :=
  [{ dest := .lidoPull, wei := ⟨0⟩ }]

theorem wrap_to_zero_allocations_sum :
    allocSumUnchecked wrapToZeroAllocations = 0 := by
  simp [wrapToZeroAllocations, allocSumUnchecked]
  have hOne : (1 + 0) % uint256Modulus = 1 :=
    Nat.mod_eq_of_lt (by simp [uint256Modulus]; omega)
  rw [hOne]
  have hSum : uint256Modulus - 1 + 1 = uint256Modulus := by
    simp [uint256Modulus]; omega
  rw [hSum, Nat.mod_self]

/-- Kill-line: tagging a beacon push as `.consolidationRequest` fails the
Join dest restriction. Pack J-TOPUP does not reuse Pack B dests. -/
theorem beacon_as_consolidation_kill_line_refutes_dest_restriction :
    (∀ leg ∈ honestJournal, isTopupJournalDest leg.dest = true) ∧
      ¬ (∀ leg ∈ mutantBeaconAsConsolidation,
          isTopupJournalDest leg.dest = true) := by
  refine ⟨specJournalOfTopup_dests_restricted honestAllocations, ?_⟩
  intro h
  have hmem :
      ({ dest := .consolidationRequest, wei := ⟨3⟩ } : EthJournalLeg) ∈
        mutantBeaconAsConsolidation := by
    native_decide
  have hfalse := h _ hmem
  simp [isTopupJournalDest] at hfalse

/-- Kill-line: a nonempty journal when `wrapped = 0` fails emptiness. -/
theorem wrap_to_zero_nonempty_kill_line_refutes_emptiness :
    allocSumUnchecked wrapToZeroAllocations = 0 ∧
      specJournalOfTopup wrapToZeroAllocations = [] ∧
      mutantNonemptyOnWrapZero ≠ [] :=
  ⟨wrap_to_zero_allocations_sum,
    topup_wrap_to_zero_journal_empty wrapToZeroAllocations
      wrap_to_zero_allocations_sum,
    by decide⟩

end LidoSRv3.Tests.PackJTopupEthJournalMutants
