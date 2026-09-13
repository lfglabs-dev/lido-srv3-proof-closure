import LidoSRv3.Audit.Source.TrioAlloc1.CapacitySpec

/-!
Kill-lines pinning `TrioAlloc1.CapacitySpec` unbounded-arithmetic view
of the second pass: `available`, `target`, `capacity` reductions plus
the `checked_success` and `checkedDiv_success` witness theorems.
-/

namespace LidoSRv3.Tests.SourceTrioAlloc1CapacitySpecKillLines

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1.CapacitySpec

/-! ## `available` — SRLib.sol:543-549 unbounded reading. -/

theorem available_reduces_type2_topup
    (input : CapacityInput) (row : CachedRow)
    (hTop : input.isTopUp = true) (hWc : row.stored.wcType.val = 2) :
    available input row =
      row.active.val * input.config.maxEBType2.val /
        input.config.maxEBType1.val := by
  unfold available
  simp [hTop, hWc]

theorem available_reduces_else
    (input : CapacityInput) (row : CachedRow)
    (h : ¬ (input.isTopUp = true ∧ row.stored.wcType.val = 2)) :
    available input row = row.allocation.val + row.summary.depositable.val := by
  unfold available
  by_cases hTop : input.isTopUp = true
  · by_cases hWc : row.stored.wcType.val = 2
    · exact absurd ⟨hTop, hWc⟩ h
    · simp [hTop, hWc]
  · simp [hTop]

/-! ## `target` — SRLib.sol:552 share*total/10000. -/

theorem target_reduces (total : Word) (row : CachedRow) :
    target total row = row.stored.share.val * total.val / 10000 := rfl

/-! ## `capacity` — active vs inactive branch (SRLib.sol:539-558). -/

theorem capacity_active (input : CapacityInput) (total : Word) (row : CachedRow)
    (hActive : row.stored.status.val = 0) :
    capacity input total row = min (target total row) (available input row) := by
  unfold capacity
  simp [hActive]

theorem capacity_inactive (input : CapacityInput) (total : Word) (row : CachedRow)
    (hInactive : row.stored.status.val ≠ 0) :
    capacity input total row = row.allocation.val := by
  unfold capacity
  simp [hInactive]

/-! ## `checked_success` — restated. -/

theorem checked_success_restated {n : Nat} {w : Word} (h : checked n = .ok w) :
    w.val = n ∧ n < 2^256 :=
  checked_success h

/-! ## `checkedDiv_success` — restated. -/

theorem checkedDiv_success_restated
    {a b w : Word} (h : checkedDiv a b = .ok w) :
    w.val = a.val / b.val ∧ b.val ≠ 0 :=
  checkedDiv_success h

end LidoSRv3.Tests.SourceTrioAlloc1CapacitySpecKillLines
