import LidoSRv3.Audit.Source.TrioAlloc2.Loop
import LidoSRv3.Audit.Source.TrioAlloc2.StepBounds

namespace LidoSRv3.Audit.Source.TrioAlloc2

theorem allocateLoop_amount_between (buckets capacities : List Word)
    (demand allocated : Word) (out : StepOutput)
    (hstart : allocated.val ≤ demand.val)
    (hrun : allocateLoop buckets capacities demand allocated = .ok out) :
    allocated.val ≤ out.amount.val ∧ out.amount.val ≤ demand.val := by
  rw [allocateLoop] at hrun
  by_cases hmore : allocated.val < demand.val
  · simp only [hmore, ↓reduceIte] at hrun
    cases hsub : checkedSub demand allocated with
    | error error => simp [hsub] at hrun
    | ok remaining =>
      simp only [hsub] at hrun
      cases hstep : step buckets capacities remaining with
      | error error => simp [hstep] at hrun
      | ok result =>
        simp only [hstep] at hrun
        by_cases hzero : result.amount.val = 0
        · simp only [hzero, ↓reduceIte] at hrun
          cases hrun
          exact ⟨Nat.le_refl _, hstart⟩
        · simp only [hzero, ↓reduceIte] at hrun
          split at hrun
          · cases hrun
          · rename_i total hadd
            have sumValue := checkedAdd_value allocated result.amount total hadd
            have subValue := checkedSub_value demand allocated remaining hsub
            have stepBound := step_amount_le_demand buckets capacities remaining result hstep
            have totalBound : total.val ≤ demand.val := by omega
            have decrease : 2 ^ 256 - total.val < 2 ^ 256 - allocated.val := by
              have := total.isLt
              omega
            have recursiveBounds := allocateLoop_amount_between result.buckets capacities demand total
              out totalBound hrun
            exact ⟨by omega, recursiveBounds.2⟩
  · simp only [hmore, ↓reduceIte] at hrun
    cases hrun
    exact ⟨Nat.le_refl _, hstart⟩
termination_by 2 ^ 256 - allocated.val
decreasing_by exact decrease

theorem allocate_amount_le_demand (buckets capacities : List Word) (demand : Word)
    (out : StepOutput) (h : allocate buckets capacities demand = .ok out) :
    out.amount.val ≤ demand.val :=
  (allocateLoop_amount_between buckets capacities demand zero out (Nat.zero_le _) h).2

theorem allocateLoop_preserves_length (buckets capacities : List Word)
    (demand allocated : Word) (out : StepOutput)
    (hrun : allocateLoop buckets capacities demand allocated = .ok out) :
    out.buckets.length = buckets.length := by
  rw [allocateLoop] at hrun
  by_cases hmore : allocated.val < demand.val
  · simp only [hmore, ↓reduceIte] at hrun
    cases hsub : checkedSub demand allocated with
    | error error => simp [hsub] at hrun
    | ok remaining =>
      simp only [hsub] at hrun
      cases hstep : step buckets capacities remaining with
      | error error => simp [hstep] at hrun
      | ok result =>
        simp only [hstep] at hrun
        have length := step_preserves_length buckets capacities remaining result hstep
        by_cases hzero : result.amount.val = 0
        · simp only [hzero, ↓reduceIte] at hrun
          cases hrun
          exact length
        · simp only [hzero, ↓reduceIte] at hrun
          split at hrun
          · cases hrun
          · rename_i total hadd
            have decrease : 2 ^ 256 - total.val < 2 ^ 256 - allocated.val := by
              have := checkedAdd_value allocated result.amount total hadd
              have := total.isLt
              omega
            exact (allocateLoop_preserves_length result.buckets capacities demand total out hrun).trans length
  · simp only [hmore, ↓reduceIte] at hrun
    cases hrun
    rfl
termination_by 2 ^ 256 - allocated.val
decreasing_by exact decrease

theorem allocate_preserves_length (buckets capacities : List Word) (demand : Word)
    (out : StepOutput) (h : allocate buckets capacities demand = .ok out) :
    out.buckets.length = buckets.length :=
  allocateLoop_preserves_length buckets capacities demand zero out h

end LidoSRv3.Audit.Source.TrioAlloc2
