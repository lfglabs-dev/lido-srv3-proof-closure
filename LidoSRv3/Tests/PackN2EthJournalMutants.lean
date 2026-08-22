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

namespace Parent :=
  LidoSRv3.Audit.Guarantees.PEthJournal1

namespace Confinement :=
  LidoSRv3.Audit.Spec.EthJournalConfinement

namespace ConsolidationJournal :=
  LidoSRv3.Audit.Spec.EthJournalCorrespondence

namespace DepositTx :=
  LidoSRv3.Audit.Verity.DepositParentTx

private def approved : ApprovedSet :=
  { consolidationContract := 1, refundRecipient := 2 }

private def honestConsolidationMoves : List EthMove :=
  [{ amount := 3, destination := .consolidationContract },
   { amount := 3, destination := .consolidationContract },
   { amount := 4, destination := .refundRecipient }]

private def topupAllocations : List Nat := [3, 0, 5]

/-- The fifth source destination is deliberately outside the frozen Spec
interface. -/
private def fifthDestinationLeg : Confinement.CandidateLeg :=
  { dest := ConsolidationJournal.specDest (.other 999), wei := ⟨1⟩ }

private def mutantConsolidationCandidate : Confinement.CandidateJournal :=
  Confinement.consolidationCandidate honestConsolidationMoves ++
    [fifthDestinationLeg]

/-- Positive control: the same success premises establish the honest parent. -/
theorem honest_success_parent_holds :
    Confinement.EveryModeledSuccessJournalApproved
        (Confinement.depositCandidate DepositTx.canonicalInputs)
        (Confinement.topupCandidate topupAllocations)
        (Confinement.consolidationCandidate honestConsolidationMoves) ∧
      Confinement.ProtocolReturnPathsExcluded honestConsolidationMoves := by
  exact Parent.every_modeled_success_journal_approved
    DepositTx.canonicalInputs DepositTx.canonicalState topupAllocations
    approved 10 2 3 honestConsolidationMoves
    DepositTx.canonical_preconditions (by decide) (by decide) (by decide)

/-- Kill-line: all three success premises are retained, but inserting an
unapproved fifth destination falsifies the parent-shaped statement that all
three journals are lossless `Spec.EthJournal`s. -/
theorem fifth_destination_kill_line_retains_success_premises :
    DepositTx.Preconditions DepositTx.canonicalInputs DepositTx.canonicalState ∧
      allocSumUnchecked topupAllocations ≠ 0 ∧
      gatewayExecute approved 10 2 3 = .success honestConsolidationMoves ∧
      ¬ (Confinement.EveryModeledSuccessJournalApproved
            (Confinement.depositCandidate DepositTx.canonicalInputs)
            (Confinement.topupCandidate topupAllocations)
            mutantConsolidationCandidate ∧
          Confinement.ProtocolReturnPathsExcluded honestConsolidationMoves) := by
  refine ⟨DepositTx.canonical_preconditions, by decide, by decide, ?_⟩
  intro hParent
  rcases hParent.1.2.2 with ⟨specJournal, hImage⟩
  have hBad : fifthDestinationLeg ∈ mutantConsolidationCandidate := by
    simp [mutantConsolidationCandidate]
  rw [hImage, Confinement.candidateOfSpec] at hBad
  rcases List.mem_map.mp hBad with ⟨leg, _, hLeg⟩
  have hDest := congrArg Confinement.CandidateLeg.dest hLeg
  simp [fifthDestinationLeg, ConsolidationJournal.specDest] at hDest

end LidoSRv3.Tests.PackN2EthJournalMutants
