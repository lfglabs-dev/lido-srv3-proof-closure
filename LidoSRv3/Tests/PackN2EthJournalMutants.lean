import LidoSRv3.Audit.Guarantees.PEthJournal1

/-!
# Node 2 ETH-journal confinement kill-line

The mutant retains a premise-satisfying success path and appends one source
leg whose destination is `.other 999`.  The source-preserving candidate keeps
that leg as `none`, so it cannot be the image of any `Spec.EthJournal`.
-/

namespace LidoSRv3.Tests.PackN2EthJournalMutants

open LidoSRv3.Audit.Guarantees.PConsolidationEth1
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Guarantees.PEthJournal1
open LidoSRv3.Audit.Spec.EthJournalConfinement
open LidoSRv3.Audit.Spec.EthJournalCorrespondence
open LidoSRv3.Audit.Verity.DepositParentTx

private def approved : ApprovedSet :=
  { consolidationContract := 1, refundRecipient := 2 }

private def honestConsolidationMoves : List EthMove :=
  [{ amount := 3, destination := .consolidationContract },
   { amount := 3, destination := .consolidationContract },
   { amount := 4, destination := .refundRecipient }]

private def topupAllocations : List Nat := [3, 0, 5]

/-- The fifth source destination is deliberately outside the frozen Spec
interface. -/
private def fifthDestinationLeg : CandidateLeg :=
  { dest := specDest (.other 999), wei := ⟨1⟩ }

private def mutantConsolidationCandidate : CandidateJournal :=
  consolidationCandidate honestConsolidationMoves ++
    [fifthDestinationLeg]

/-- Positive control: the same success premises establish the honest parent. -/
theorem honest_success_parent_holds :
    EveryModeledSuccessJournalApproved
        (depositCandidate canonicalInputs)
        (topupCandidate topupAllocations)
        (consolidationCandidate honestConsolidationMoves) ∧
      ProtocolReturnPathsExcluded honestConsolidationMoves := by
  exact every_modeled_success_journal_approved
    canonicalInputs canonicalState topupAllocations
    approved 10 2 3 honestConsolidationMoves
    canonical_preconditions (by decide) (by decide) (by decide)

/-- Kill-line: all three success premises are retained, but inserting an
unapproved fifth destination falsifies the parent-shaped statement that all
three journals are lossless `Spec.EthJournal`s. -/
theorem fifth_destination_kill_line_retains_success_premises :
    Preconditions canonicalInputs canonicalState ∧
      allocSumUnchecked topupAllocations ≠ 0 ∧
      gatewayExecute approved 10 2 3 = .success honestConsolidationMoves ∧
      ¬ (EveryModeledSuccessJournalApproved
            (depositCandidate canonicalInputs)
            (topupCandidate topupAllocations)
            mutantConsolidationCandidate ∧
          ProtocolReturnPathsExcluded honestConsolidationMoves) := by
  refine ⟨canonical_preconditions, by decide, by decide, ?_⟩
  intro hParent
  rcases hParent.1.2.2 with ⟨specJournal, hImage⟩
  have hBad : fifthDestinationLeg ∈ mutantConsolidationCandidate := by
    simp [mutantConsolidationCandidate]
  rw [hImage, candidateOfSpec] at hBad
  rcases List.mem_map.mp hBad with ⟨leg, _, hLeg⟩
  have hDest := congrArg CandidateLeg.dest hLeg
  simp [fifthDestinationLeg, specDest] at hDest

/-- A Vault→Lido hop is not a lossless Spec journal. Premises of the
exclusion parent stay: this is the hop the parent says cannot be
`JournalApproved`. -/
def lidoHop : List EthMove :=
  [{ amount := 1, destination := .lido }]

theorem lido_hop_not_journal_approved :
    ¬ JournalApproved (consolidationCandidate lidoHop) := by
  intro hApproved
  have hExcl :=
    LidoSRv3.Audit.Guarantees.PEthJournal1.journal_approved_excludes_protocol_return_paths
      lidoHop hApproved
  have hMem : { amount := 1, destination := .lido } ∈ lidoHop := by
    simp [lidoHop]
  exact (hExcl _ hMem).1 rfl

/-- Mutant projection: treat Vault→Lido as the frozen `lidoPull` dest.
Then the Lido hop would look approved while `ProtocolReturnPathsExcluded`
fails, so the implication depends on `specDest .lido = none`. -/
def mutantSpecDest : EthDestination → Option LidoSRv3.Audit.Spec.ApprovedDestination
  | .lido => some LidoSRv3.Audit.Spec.ApprovedDestination.lidoPull
  | dest => specDest dest

def mutantLidoCandidate (moves : List EthMove) : CandidateJournal :=
  moves.map fun move =>
    { dest := mutantSpecDest move.destination, wei := ⟨move.amount⟩ }

theorem mutant_lido_maps_to_lidoPull :
    mutantSpecDest .lido =
      some LidoSRv3.Audit.Spec.ApprovedDestination.lidoPull := rfl

def mutantLidoSpecJournal : LidoSRv3.Audit.Spec.EthJournal :=
  [{ dest := LidoSRv3.Audit.Spec.ApprovedDestination.lidoPull, wei := ⟨1⟩ }]

theorem mutant_lido_candidate_is_spec_image :
    mutantLidoCandidate lidoHop = candidateOfSpec mutantLidoSpecJournal := by
  simp [mutantLidoCandidate, lidoHop, mutantSpecDest, mutantLidoSpecJournal,
    candidateOfSpec]

/-- Parent-shaped kill-line: the mutant Lido hop is the image of a Spec
journal (so "approved"), but `ProtocolReturnPathsExcluded` fails. -/
theorem mutant_lido_approved_not_excluded_kill_line :
    JournalApproved (mutantLidoCandidate lidoHop) ∧
      ¬ ProtocolReturnPathsExcluded lidoHop := by
  constructor
  · exact ⟨mutantLidoSpecJournal, mutant_lido_candidate_is_spec_image⟩
  · intro hExcl
    have hMem : { amount := 1, destination := .lido } ∈ lidoHop := by
      simp [lidoHop]
    exact (hExcl _ hMem).1 rfl

end LidoSRv3.Tests.PackN2EthJournalMutants
