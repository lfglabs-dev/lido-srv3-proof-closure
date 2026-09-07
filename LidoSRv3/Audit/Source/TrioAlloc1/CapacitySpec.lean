import LidoSRv3.Audit.Source.TrioAlloc1.Properties

/-! Independent unbounded arithmetic view of the successful second pass.
This specification does not call `checked`, `rowCapacity`, or either execution loop.
Success implies these equations; arbitrary external responses may still revert.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1

namespace CapacitySpec

def available (input : CapacityInput) (row : CachedRow) : Nat :=
  if input.isTopUp && row.stored.wcType.val == 2 then
    row.active.val * input.config.maxEBType2.val / input.config.maxEBType1.val
  else row.allocation.val + row.summary.depositable.val

def target (total : Word) (row : CachedRow) : Nat :=
  row.stored.share.val * total.val / 10000

def capacity (input : CapacityInput) (total : Word) (row : CachedRow) : Nat :=
  if row.stored.status.val = 0 then min (target total row) (available input row)
  else row.allocation.val

end CapacitySpec

theorem checked_success {n : Nat} {w : Word} (h : checked n = .ok w) :
    w.val = n ∧ n < 2^256 := by
  unfold checked at h
  split at h
  · cases h; exact ⟨rfl, ‹n < 2^256›⟩
  · cases h

theorem checkedDiv_success {a b w : Word} (h : checkedDiv a b = .ok w) :
    w.val = a.val / b.val ∧ b.val ≠ 0 := by
  unfold checkedDiv at h
  split at h
  · cases h
  · cases h
    exact ⟨Nat.mod_eq_of_lt (Nat.lt_of_le_of_lt (Nat.div_le_self _ _) a.isLt), ‹b.val ≠ 0›⟩

/-- Success discharges every checked second-pass arithmetic obligation locally. -/
theorem rowCapacity_matches_spec (input : CapacityInput) (total : Word)
    (row : CachedRow) (cap : Word) (h : rowCapacity input total row = .ok cap) :
    cap.val = CapacitySpec.capacity input total row := by
  unfold rowCapacity at h
  by_cases active : row.stored.status.val = 0
  · simp only [active, ne_eq, not_true_eq_false, ↓reduceIte] at h
    simp only [bind, Except.bind] at h
    unfold CapacitySpec.capacity
    simp only [active, ↓reduceIte]
    by_cases topup : (input.isTopUp && row.stored.wcType.val == 2) = true
    · simp only [topup, ↓reduceIte] at h
      cases hm : checked (row.active.val * input.config.maxEBType2.val) with
      | error e => simp [hm] at h
      | ok product =>
        simp only [hm] at h
        cases hd : checkedDiv product input.config.maxEBType1 with
        | error e => simp [hd] at h
        | ok avail =>
          simp only [hd] at h
          cases ht : checked (row.stored.share.val * total.val) with
          | error e => simp [ht] at h
          | ok targetProduct =>
            simp [ht, pure, Except.pure] at h
            subst cap
            have hm' := (checked_success hm).1
            have hd' := (checkedDiv_success hd).1
            have ht' := (checked_success ht).1
            have bound : min (targetProduct.val / 10000) avail.val < 2^256 :=
              Nat.lt_of_le_of_lt (Nat.min_le_right _ _) avail.isLt
            simp only [word, Nat.mod_eq_of_lt bound]
            simp [CapacitySpec.target, CapacitySpec.available, topup, ← hm', ← hd', ← ht']
    · simp only [Bool.not_eq_true] at topup
      simp only [topup, Bool.false_eq_true, ↓reduceIte] at h
      cases ha : checked (row.allocation.val + row.summary.depositable.val) with
      | error e => simp [ha] at h
      | ok avail =>
        simp only [ha] at h
        cases ht : checked (row.stored.share.val * total.val) with
        | error e => simp [ht] at h
        | ok targetProduct =>
          simp [ht, pure, Except.pure] at h
          subst cap
          have ha' := (checked_success ha).1
          have ht' := (checked_success ht).1
          have bound : min (targetProduct.val / 10000) avail.val < 2^256 :=
            Nat.lt_of_le_of_lt (Nat.min_le_right _ _) avail.isLt
          simp only [word, Nat.mod_eq_of_lt bound]
          simp [CapacitySpec.target, CapacitySpec.available, topup, ← ha', ← ht']
  · simp [active, pure, Except.pure] at h
    subst cap
    simp [CapacitySpec.capacity, active]

/-- The clamp bound follows for the executor's returned word, not just a min definition. -/
theorem successful_active_capacity_bounds (input : CapacityInput) (total : Word)
    (row : CachedRow) (cap : Word) (active : row.stored.status.val = 0)
    (h : rowCapacity input total row = .ok cap) :
    cap.val ≤ CapacitySpec.target total row ∧ cap.val ≤ CapacitySpec.available input row := by
  rw [rowCapacity_matches_spec input total row cap h]
  simp only [CapacitySpec.capacity, active, ↓reduceIte]
  exact ⟨Nat.min_le_left _ _, Nat.min_le_right _ _⟩

end LidoSRv3.Audit.Source.TrioAlloc1
