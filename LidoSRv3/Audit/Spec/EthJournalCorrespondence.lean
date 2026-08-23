import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Guarantees.PConsolidationEth1

/-!
# Pack B: Spec.EthJournal projection

Unregistered child. It does not replace the registered P-CONSOLIDATION-ETH-1
parent, does not add VaultHub, and does not invent a guarantee ID.
-/

namespace LidoSRv3.Audit.Spec.EthJournalCorrespondence

open LidoSRv3.Audit.Common
open LidoSRv3.Audit.Guarantees.PConsolidationEth1

/-- Success-journal destinations only. Retired Lido / WQ / withdrawal-request
tags and residual `.other` addresses have no Spec destination. -/
def specDest : EthDestination → Option ApprovedDestination
  | .consolidationContract => some .consolidationRequest
  | .refundRecipient => some .refundRecipient
  | _ => none

def specOfMove (m : EthMove) : Option EthJournalLeg :=
  match specDest m.destination with
  | some dest => some { dest := dest, wei := ⟨m.amount⟩ }
  | none => none

def specJournal (moves : List EthMove) : EthJournal :=
  moves.filterMap specOfMove

theorem specDest_consolidation :
    specDest .consolidationContract = some .consolidationRequest := rfl

theorem specDest_refund :
    specDest .refundRecipient = some .refundRecipient := rfl

theorem specDest_other (addr : Address) : specDest (.other addr) = none := rfl

theorem specDest_lido : specDest .lido = none := rfl

theorem specDest_withdrawalQueue : specDest .withdrawalQueue = none := rfl

/-- If every move has a Spec destination, the Spec journal preserves amounts
in order. -/
theorem specJournal_amounts_of_projected
    (moves : List EthMove)
    (h : ∀ m, m ∈ moves → specDest m.destination ≠ none) :
    (specJournal moves).map (fun leg => leg.wei.value) = moves.map EthMove.amount := by
  induction moves with
  | nil => simp [specJournal]
  | cons m ms ih =>
      have hm : specDest m.destination ≠ none :=
        h m (List.mem_cons.mpr (Or.inl rfl))
      have hms : ∀ x, x ∈ ms → specDest x.destination ≠ none := fun x hx =>
        h x (List.mem_cons.mpr (Or.inr hx))
      cases hDest : specDest m.destination with
      | none => exact absurd hDest hm
      | some dest =>
          simp [specJournal, specOfMove, hDest] at *
          exact ih hms

private theorem classify_self_consolidation (approved : ApprovedSet) :
    classifyJournal approved approved.consolidationContract = .consolidationContract := by
  simp [classifyJournal]

private theorem classify_self_refund (approved : ApprovedSet)
    (h : approved.refundRecipient ≠ approved.consolidationContract) :
    classifyJournal approved approved.refundRecipient = .refundRecipient := by
  simp [classifyJournal, h]

/-- Unregistered child: every successful `gatewayExecute` journal projects onto
`Spec.EthJournal`. Destinations are only the two frozen Spec approvals; Spec
wei amounts match the move amounts. Conservation remains the registered
parent. -/
theorem success_journal_projects_to_spec
    (approved : ApprovedSet)
    (hDistinct : approved.refundRecipient ≠ approved.consolidationContract)
    (msgValue n fee : Nat) :
    match gatewayExecute approved msgValue n fee with
    | .reverted _ => True
    | .success moves =>
        (∀ m, m ∈ moves → specDest m.destination ≠ none) ∧
          (specJournal moves).map (fun leg => leg.wei.value) = moves.map EthMove.amount := by
  unfold gatewayExecute
  split_ifs with h1 h2 h3
  · trivial
  · trivial
  · trivial
  · have hCons := classify_self_consolidation approved
    by_cases hRefundZero : msgValue - n * fee = 0
    · have hRefund :
          (if msgValue - n * fee = 0 then ([] : List EthMove)
            else [{ amount := msgValue - n * fee,
                    destination := classifyJournal approved approved.refundRecipient }]) = [] :=
        if_pos hRefundZero
      have hAll : ∀ m, m ∈
          List.replicate n
            { amount := fee,
              destination := classifyJournal approved approved.consolidationContract } ++
            (if msgValue - n * fee = 0 then ([] : List EthMove)
              else [{ amount := msgValue - n * fee,
                      destination := classifyJournal approved approved.refundRecipient }]) →
          specDest m.destination ≠ none := by
        intro m hm
        rw [hRefund, List.append_nil] at hm
        have := List.eq_of_mem_replicate hm
        subst this
        simp [hCons, specDest]
      refine ⟨hAll, specJournal_amounts_of_projected _ hAll⟩
    · have hRefl := classify_self_refund approved hDistinct
      have hRefund :
          (if msgValue - n * fee = 0 then ([] : List EthMove)
            else [{ amount := msgValue - n * fee,
                    destination := classifyJournal approved approved.refundRecipient }]) =
            [{ amount := msgValue - n * fee,
                destination := classifyJournal approved approved.refundRecipient }] :=
        if_neg hRefundZero
      have hAll : ∀ m, m ∈
          List.replicate n
            { amount := fee,
              destination := classifyJournal approved approved.consolidationContract } ++
            (if msgValue - n * fee = 0 then ([] : List EthMove)
              else [{ amount := msgValue - n * fee,
                      destination := classifyJournal approved approved.refundRecipient }]) →
          specDest m.destination ≠ none := by
        intro m hm
        rw [hRefund] at hm
        rcases List.mem_append.mp hm with hm | hm
        · have := List.eq_of_mem_replicate hm
          subst this
          simp [hCons, specDest]
        · simp only [List.mem_singleton] at hm
          subst hm
          simp [hRefl, specDest]
      refine ⟨hAll, specJournal_amounts_of_projected _ hAll⟩

end LidoSRv3.Audit.Spec.EthJournalCorrespondence
