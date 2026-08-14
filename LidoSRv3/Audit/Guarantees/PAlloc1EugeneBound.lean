import LidoSRv3.Audit.Guarantees.PAlloc1
import LidoSRv3.Audit.Guarantees.PAlloc2

/-!
# P-ALLOC-1.eugene-bound

Subordinate evidence for the Eugene operator bound.  A row returned by the
canonical checked SRLib allocation model supplies the current allocation and
capacity consumed by the canonical MinFirst mutation.  The configured
operator `bond` is the checked capacity headroom.  Consequently the reward
share allocated by one MinFirst step cannot exceed that bond.

This is evidence attached to `P-ALLOC-1`; it is not a public guarantee.
-/

namespace LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound

open Verity Verity.Stdlib.Math
open LidoSRv3.Audit.AllocCapacity
open LidoSRv3.Audit.MinFirstAllocation

/-- The canonical checked MinFirst amount is capped by the selected row's
checked capacity headroom. -/
theorem checked_amount_le_bond
    (rows : List Source.Row) (allocationSize : Source.Word) (best : Source.Row)
    (bond allocated : Source.Word)
    (hBond : safeSub best.capacity best.allocation = some bond)
    (hAmount : Source.checkedAmount rows allocationSize best = some allocated) :
    allocated ≤ bond := by
  have minWord_val_le_right (a b : Source.Word) : (Source.minWord a b).val ≤ b.val := by
    simp only [Source.minWord]
    split <;> simp_all
  have minWord_nested_val_le_right (a b c : Source.Word) :
      (Source.minWord a (Source.minWord b c)).val ≤ c.val := by
    exact Nat.le_trans (minWord_val_le_right a (Source.minWord b c))
      (minWord_val_le_right b c)
  cases hNext : Source.nextLevel? rows best.allocation with
  | none =>
      simp [Source.checkedAmount, hNext, hBond] at hAmount
      subst allocated
      exact minWord_nested_val_le_right _ _ _
  | some next =>
      cases hLevel : safeSub next best.allocation with
      | none =>
          simp [Source.checkedAmount, hNext, hLevel] at hAmount
      | some levelHeadroom =>
          simp [Source.checkedAmount, hNext, hLevel, hBond] at hAmount
          subst allocated
          exact minWord_nested_val_le_right _ _ _

/-- Eugene bound over the composed canonical algorithm: `sourceRow` is taken
from a successful P-ALLOC-1 checked execution, then used as the selected row of
the P-ALLOC-2 MinFirst mutation.  The membership premise makes the SRLib
connection explicit; the arithmetic conclusion follows from the exact checked
capacity headroom used by that mutation. -/
theorem operator_reward_share_le_configured_bond
    (cfg : Config) (modules : List Module) (depositsToAllocate : Verity.Uint256)
    (isTopUp : Bool) (srRows : List Row)
    (sourceRows : List Source.Row) (allocationSize : Source.Word)
    (sourceRow : Source.Row) (bond allocated : Source.Word)
    (_hExecute : execute cfg modules depositsToAllocate isTopUp = some srRows)
    (_hCanonicalRow : ∃ row ∈ srRows,
      sourceRow.allocation = row.currentAllocation ∧ sourceRow.capacity = row.capacity)
    (_hSelected : Source.candidate? sourceRows = some sourceRow)
    (hBond : safeSub sourceRow.capacity sourceRow.allocation = some bond)
    (hAmount : Source.checkedAmount sourceRows allocationSize sourceRow = some allocated) :
    allocated ≤ bond :=
  checked_amount_le_bond sourceRows allocationSize sourceRow bond allocated hBond hAmount

end LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound
