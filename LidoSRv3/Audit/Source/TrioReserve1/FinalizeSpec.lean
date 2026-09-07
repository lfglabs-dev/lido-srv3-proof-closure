namespace LidoSRv3.Audit.Source.TrioReserve1.FinalizeSpec

inductive Failure where
  | upper_id | finalized_id | steth | amount | first_id | checkpoint | locked | shares
  deriving DecidableEq, Repr

/-- A failure is the first false guard, with every earlier guard true. A
successful observation requires the entire ordered list to hold. -/
def Checks : List (Prop × Failure) → Option Failure → Prop
  | [], result => result = none
  | (guard, fault) :: rest, result =>
      (¬ guard ∧ result = some fault) ∨ (guard ∧ Checks rest result)

theorem checks_total (guards : List (Prop × Failure)) : ∃ result, Checks guards result := by
  classical
  induction guards with
  | nil => exact ⟨none, rfl⟩
  | cons pair rest ih =>
    by_cases h : pair.1
    · obtain ⟨result, hr⟩ := ih
      exact ⟨result, Or.inr ⟨h, hr⟩⟩
    · exact ⟨some pair.2, Or.inl ⟨h, rfl⟩⟩

/-- Independent finalization observations. `lockedAfterCheckpoint` is read after
checkpoint writes; packed cumulative fields are the saved pre-write observations. -/
structure Observations where
  limit : Nat
  last : Nat
  tail : Nat
  finalized : Nat
  oldStETH : Nat
  newStETH : Nat
  oldShares : Nat
  newShares : Nat
  amount : Nat
  checkpoint : Nat
  lockedAfterCheckpoint : Nat

def Computes (o : Observations) : Option Failure → Prop :=
  Checks [(o.last ≤ o.tail, .upper_id), (o.finalized < o.last, .finalized_id),
    (o.oldStETH ≤ o.newStETH, .steth), (o.amount ≤ o.newStETH - o.oldStETH, .amount),
    (o.finalized + 1 < o.limit, .first_id), (o.checkpoint + 1 < o.limit, .checkpoint),
    (o.lockedAfterCheckpoint + o.amount < o.limit, .locked), (o.oldShares ≤ o.newShares, .shares)]

theorem total (o : Observations) : ∃ result, Computes o result := checks_total _

end LidoSRv3.Audit.Source.TrioReserve1.FinalizeSpec
