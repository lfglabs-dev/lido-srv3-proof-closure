import LidoSRv3.Audit.Source.TrioAlloc2.Totality
import LidoSRv3.Audit.Source.TrioAlloc2.LoopBounds

namespace LidoSRv3.Audit.Source.TrioAlloc2

/-- Every mathematical loop run succeeds for a valid decoded shape. The checked
accumulator cannot overflow because each actual step is bounded by the remainder.
This is not a gas or feasible-runtime bound for arbitrary uint256 inputs. -/
theorem allocateLoop_success (buckets capacities : List Word) (demand allocated : Word)
    (lengths : buckets.length ≤ capacities.length) (bounded : buckets.length < 2 ^ 256) :
    ∃ out, allocateLoop buckets capacities demand allocated = .ok out := by
  by_cases more : allocated.val < demand.val
  · let remaining : Word := ⟨demand.val - allocated.val,
      Nat.lt_of_le_of_lt (Nat.sub_le ..) demand.isLt⟩
    have remainingEq : checkedSub demand allocated = .ok remaining := by
      simp [checkedSub, Nat.le_of_lt more, remaining]
    obtain ⟨result, resultEq⟩ := step_success buckets capacities remaining lengths bounded
    by_cases stopped : result.amount.val = 0
    · exact ⟨⟨allocated, result.buckets⟩, by rw [allocateLoop]; simp [more, remainingEq, resultEq, stopped]⟩
    · have amountBound := step_amount_le_demand buckets capacities remaining result resultEq
      have sumBound : allocated.val + result.amount.val < 2 ^ 256 := by
        have demandBound := demand.isLt
        dsimp [remaining] at amountBound
        omega
      let total : Word := ⟨allocated.val + result.amount.val, sumBound⟩
      have totalEq : checkedAdd allocated result.amount = .ok total := by
        simp [checkedAdd, sumBound, total]
      have lengthEq := step_preserves_length buckets capacities remaining result resultEq
      have decrease : 2 ^ 256 - total.val < 2 ^ 256 - allocated.val := by
        have := total.isLt
        dsimp [total] at *
        omega
      obtain ⟨out, outEq⟩ := allocateLoop_success result.buckets capacities demand total
        (by simpa [lengthEq] using lengths) (by simpa [lengthEq] using bounded)
      refine ⟨out, ?_⟩
      rw [allocateLoop]
      simp only [more, ↓reduceIte, remainingEq, resultEq, stopped]
      split
      · rename_i error failed
        rw [totalEq] at failed
        cases failed
      · rename_i actual added
        have same : actual = total := Except.ok.inj (added.symm.trans totalEq)
        subst actual
        exact outEq
  · exact ⟨⟨allocated, buckets⟩, allocateLoop_done buckets capacities demand allocated (by omega)⟩
termination_by 2 ^ 256 - allocated.val
decreasing_by exact decrease

theorem allocate_success (buckets capacities : List Word) (demand : Word)
    (lengths : buckets.length ≤ capacities.length) (bounded : buckets.length < 2 ^ 256) :
    ∃ out, allocate buckets capacities demand = .ok out :=
  allocateLoop_success buckets capacities demand zero lengths bounded

end LidoSRv3.Audit.Source.TrioAlloc2
