import LidoSRv3.Audit.Source.TrioAlloc2.Word

/-! Totality and exact arithmetic for the checked ceil division. Bounds are
proved before constructing a result word; no successful-operation premise. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2

theorem ceilDiv_success (a b : Word) (hb : b.val ≠ 0) :
    ∃ out, ceilDiv a b = .ok out ∧ out.val = (a.val + b.val - 1) / b.val := by
  by_cases ha : a.val = 0
  · refine ⟨zero, ?_, ?_⟩
    · simp [ceilDiv, ha, pure, Except.pure]
    · have small : b.val - 1 < b.val := by omega
      simp [ha, zero, Nat.div_eq_of_lt small]
  · have subBound : a.val - 1 < 2 ^ 256 := Nat.lt_of_le_of_lt (Nat.sub_le ..) a.isLt
    let decremented : Word := ⟨a.val - 1, subBound⟩
    have hs : checkedSub a one = .ok decremented := by
      simp [checkedSub, one, show 1 ≤ a.val by omega, decremented]
    let quotient : Word := ⟨decremented.val / b.val,
      Nat.lt_of_le_of_lt (Nat.div_le_self ..) decremented.isLt⟩
    have hd : checkedDiv decremented b = .ok quotient := by
      simp [checkedDiv, hb, quotient]
    have divBound := Nat.div_le_self decremented.val b.val
    have resultBound : quotient.val + 1 < 2 ^ 256 := by
      have := a.isLt
      dsimp [quotient, decremented] at *
      omega
    let out : Word := ⟨quotient.val + 1, resultBound⟩
    have hadd : checkedAdd quotient one = .ok out := by
      simp [checkedAdd, one, resultBound, out]
    refine ⟨out, ?_, ?_⟩
    · simp [ceilDiv, ha, hs, hd, hadd, bind, Except.bind, pure, Except.pure]
    · have shifted : a.val + b.val - 1 = (a.val - 1) + b.val := by omega
      rw [shifted, Nat.add_div_right _ (by omega)]

theorem ceilDiv_zero_denominator (a : Word) (ha : a.val ≠ 0) :
    ceilDiv a zero = .error .divisionByZero := by
  simp [ceilDiv, ha, checkedSub, one, show 1 ≤ a.val by omega,
    checkedDiv, zero, bind, Except.bind, pure, Except.pure]

/-- The subtraction/addition implementation agrees with the independent
unbounded ceil formula whenever the denominator is positive. -/
theorem ceilDiv_formula (a b out : Word) (hb : b.val ≠ 0)
    (h : ceilDiv a b = .ok out) : out.val = (a.val + b.val - 1) / b.val := by
  obtain ⟨actual, executed, value⟩ := ceilDiv_success a b hb
  rw [h] at executed
  cases executed
  exact value

theorem minWord_value (a b : Word) : (minWord a b).val = min a.val b.val := by
  unfold minWord
  split
  · rename_i h; exact (Nat.min_eq_left (Nat.le_of_lt h)).symm
  · rename_i h; exact (Nat.min_eq_right (by omega)).symm

end LidoSRv3.Audit.Source.TrioAlloc2
