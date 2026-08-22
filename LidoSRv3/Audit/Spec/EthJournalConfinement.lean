import LidoSRv3.Audit.Spec.DepositEthJournalCorrespondence
import LidoSRv3.Audit.Spec.TopupEthJournalCorrespondence
import LidoSRv3.Audit.Spec.EthJournalCorrespondence

/-!
# Node 2: modeled-success ETH journal confinement

This module keeps every source leg while asking whether it has a frozen
`ApprovedDestination`.  In particular, an unapproved source leg is represented
by `none`; it cannot disappear through the `filterMap` used by the earlier
projection children.

Only the three modeled success paths are composed: the conserving two-batch
deposit, a value-moving top-up, and consolidation fee/refund.  Vault owner
withdrawals and WithdrawalQueue protocol returns remain outside this journal.
-/

namespace LidoSRv3.Audit.Spec.EthJournalConfinement

open LidoSRv3.Audit.Common
open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Guarantees.PConsolidationEth1

namespace DepositJournal :=
  LidoSRv3.Audit.Spec.DepositEthJournalCorrespondence

namespace TopupJournal :=
  LidoSRv3.Audit.Spec.TopupEthJournalCorrespondence

namespace ConsolidationJournal :=
  LidoSRv3.Audit.Spec.EthJournalCorrespondence

namespace DepositTx :=
  LidoSRv3.Audit.Verity.DepositParentTx

/-- A source journal leg before total projection. `none` means that the source
destination has no constructor in the frozen Spec interface. -/
structure CandidateLeg where
  dest : Option ApprovedDestination
  wei : Wei
  deriving DecidableEq, Repr

abbrev CandidateJournal := List CandidateLeg

/-- Forget only the fact that every destination is present. No source leg is
dropped. -/
def candidateOfSpec (journal : EthJournal) : CandidateJournal :=
  journal.map fun leg => { dest := some leg.dest, wei := leg.wei }

/-- A candidate is approved exactly when it is the lossless image of a
`Spec.EthJournal`. -/
def JournalApproved (journal : CandidateJournal) : Prop :=
  ∃ specJournal : EthJournal, journal = candidateOfSpec specJournal

/-- Source-preserving candidate for the conserving two-batch deposit journal. -/
def depositCandidate (inputs : DepositTx.Inputs) : CandidateJournal :=
  (DepositJournal.honestDepositLegs inputs).map fun leg =>
    { dest := DepositJournal.specDest leg.dest, wei := ⟨leg.wei⟩ }

/-- Source-preserving candidate for the value-moving top-up journal. The
earlier correspondence already constructs this schedule as a Spec journal. -/
def topupCandidate (allocations : List Nat) : CandidateJournal :=
  candidateOfSpec (TopupJournal.specJournalOfTopup allocations)

/-- Source-preserving candidate for consolidation fee/refund moves. Unlike the
earlier `filterMap`, this list retains an unapproved move as a `none` leg. -/
def consolidationCandidate (moves : List EthMove) : CandidateJournal :=
  moves.map fun move =>
    { dest := ConsolidationJournal.specDest move.destination, wei := ⟨move.amount⟩ }

/-- Parent conclusion shared by the three modeled success paths. -/
def EveryModeledSuccessJournalApproved
    (deposit topup consolidation : CandidateJournal) : Prop :=
  JournalApproved deposit ∧ JournalApproved topup ∧ JournalApproved consolidation

/-- Named scope conjunct: the retired Vault-to-Lido and WithdrawalQueue
protocol-return legs are not part of the consolidation fee/refund journal.
This is deliberately a predicate on the actual source moves, not a `True`
placeholder. -/
def ProtocolReturnPathsExcluded (moves : List EthMove) : Prop :=
  ∀ move, move ∈ moves →
    move.destination ≠ .lido ∧ move.destination ≠ .withdrawalQueue

theorem depositCandidate_approved (inputs : DepositTx.Inputs) :
    JournalApproved (depositCandidate inputs) := by
  refine ⟨DepositJournal.specJournalOfDeposit inputs, ?_⟩
  rfl

theorem topupCandidate_approved (allocations : List Nat) :
    JournalApproved (topupCandidate allocations) :=
  ⟨TopupJournal.specJournalOfTopup allocations, rfl⟩

/-- Projection totality upgrades the source-preserving candidate to a genuine
Spec journal. -/
theorem consolidationCandidate_approved_of_projected
    (moves : List EthMove)
    (hProjected : ∀ move, move ∈ moves →
      ConsolidationJournal.specDest move.destination ≠ none) :
    JournalApproved (consolidationCandidate moves) := by
  refine ⟨ConsolidationJournal.specJournal moves, ?_⟩
  induction moves with
  | nil => rfl
  | cons move rest ih =>
      have hMove := hProjected move (by simp)
      have hRest : ∀ other, other ∈ rest →
          ConsolidationJournal.specDest other.destination ≠ none := by
        intro other hMem
        exact hProjected other (by simp [hMem])
      cases hDest : ConsolidationJournal.specDest move.destination with
      | none => exact absurd hDest hMove
      | some dest =>
          simp [consolidationCandidate, candidateOfSpec,
            ConsolidationJournal.specJournal, ConsolidationJournal.specOfMove,
            hDest, ih hRest]

/-- Total Spec projection also proves the named exclusion conjunct. -/
theorem protocolReturnPathsExcluded_of_projected
    (moves : List EthMove)
    (hProjected : ∀ move, move ∈ moves →
      ConsolidationJournal.specDest move.destination ≠ none) :
    ProtocolReturnPathsExcluded moves := by
  intro move hMem
  have hDest := hProjected move hMem
  constructor
  · intro hLido
    subst hLido
    exact hDest ConsolidationJournal.specDest_lido
  · intro hQueue
    subst hQueue
    exact hDest rfl

end LidoSRv3.Audit.Spec.EthJournalConfinement
