import LidoSRv3.Audit.Source.TrioAlloc2.StepCorrespondence
import LidoSRv3.Audit.Source.TrioAlloc2.SpecProgress
import LidoSRv3.Audit.Source.TrioAlloc2.LoopTotality

namespace LidoSRv3.Audit.Source.TrioAlloc2

theorem step_zero_choice_none (buckets capacities : List Word) (demand : Word)
    (out : StepOutput) (executed : step buckets capacities demand = .ok out)
    (zeroAmount : out.amount.val = 0) :
    Spec.choose (decodedRows buckets capacities) demand.val = none ∧
      decodedRows out.buckets capacities = decodedRows buckets capacities := by
  have refined := step_refines buckets capacities demand out executed
  cases chosen : Spec.choose (decodedRows buckets capacities) demand.val with
  | none =>
    refine ⟨rfl, ?_⟩
    have rowsEq := congrArg Prod.snd refined
    simpa [Spec.step, chosen] using rowsEq.symm
  | some choice =>
    have positive := Spec.choose_positive _ _ _ chosen
    have amountEq := congrArg Prod.fst refined
    simp [Spec.step, chosen] at amountEq
    omega

/-- The complete source loop realizes the original independent distribution
relation. The zero-step break is justified by absence of a mathematical choice;
the recursive rule uses the actual amount and updated rows from the source step. -/
theorem allocateLoop_refines (buckets capacities : List Word) (demand allocated : Word)
    (out : StepOutput) (start : allocated.val ≤ demand.val)
    (executed : allocateLoop buckets capacities demand allocated = .ok out) :
    Spec.Distributes (decodedRows buckets capacities) (demand.val - allocated.val)
      (out.amount.val - allocated.val) (decodedRows out.buckets capacities) := by
  rw [allocateLoop] at executed
  by_cases more : allocated.val < demand.val
  · simp only [more, ↓reduceIte] at executed
    cases subEq : checkedSub demand allocated with
    | error e => simp [subEq] at executed
    | ok remaining =>
      simp only [subEq] at executed
      have remainingValue := checkedSub_value demand allocated remaining subEq
      cases stepEq : step buckets capacities remaining with
      | error e => simp [stepEq] at executed
      | ok result =>
        simp only [stepEq] at executed
        by_cases stopped : result.amount.val = 0
        · simp only [stopped, ↓reduceIte] at executed
          cases executed
          obtain ⟨noChoice, rowsEq⟩ := step_zero_choice_none buckets capacities remaining result stepEq stopped
          have stop := Spec.Distributes.stopped (decodedRows buckets capacities) remaining.val noChoice
          simpa [remainingValue, rowsEq] using stop
        · simp only [stopped, ↓reduceIte] at executed
          split at executed
          · cases executed
          · rename_i total totalEq
            have sumValue := checkedAdd_value allocated result.amount total totalEq
            have stepBound := step_amount_le_demand buckets capacities remaining result stepEq
            have totalBound : total.val ≤ demand.val := by omega
            have decrease : 2 ^ 256 - total.val < 2 ^ 256 - allocated.val := by
              have := total.isLt
              omega
            have recursive := allocateLoop_refines result.buckets capacities demand total out totalBound executed
            have outBound := (allocateLoop_amount_between result.buckets capacities demand total out totalBound executed).1
            have refined := step_refines buckets capacities remaining result stepEq
            cases chosen : Spec.choose (decodedRows buckets capacities) remaining.val with
            | none =>
              have amountEq := congrArg Prod.fst refined
              simp [Spec.step, chosen] at amountEq
              omega
            | some choice =>
              have amountEq := congrArg Prod.fst refined
              simp [Spec.step, chosen] at amountEq
              have rowsEq := congrArg Prod.snd refined
              dsimp only at rowsEq
              have restDemand : demand.val - total.val = remaining.val - choice.amount := by omega
              have spentEq : choice.amount + (out.amount.val - total.val) = out.amount.val - allocated.val := by omega
              rw [restDemand, ← rowsEq] at recursive
              have advanced := Spec.Distributes.advance (decodedRows buckets capacities) remaining.val choice
                (out.amount.val - total.val) (decodedRows out.buckets capacities) chosen recursive
              simpa only [spentEq, remainingValue] using advanced
  · simp only [more, ↓reduceIte] at executed
    cases executed
    have equal : demand.val = allocated.val := by omega
    simpa [equal] using Spec.distributes_zero (decodedRows buckets capacities)
termination_by 2 ^ 256 - allocated.val
decreasing_by exact decrease

theorem allocate_refines (buckets capacities : List Word) (demand : Word)
    (out : StepOutput) (executed : allocate buckets capacities demand = .ok out) :
    Spec.Distributes (decodedRows buckets capacities) demand.val out.amount.val
      (decodedRows out.buckets capacities) := by
  simpa [zero] using allocateLoop_refines buckets capacities demand zero out (Nat.zero_le _) executed

/-- Existence is derived from executable totality and correspondence, not an
extra specification hypothesis. This remains a decoded-array theorem. -/
theorem distribution_exists (buckets capacities : List Word) (demand : Word)
    (lengths : buckets.length ≤ capacities.length) (bounded : buckets.length < 2 ^ 256) :
    ∃ out, allocate buckets capacities demand = .ok out ∧
      Spec.Distributes (decodedRows buckets capacities) demand.val out.amount.val
        (decodedRows out.buckets capacities) := by
  obtain ⟨out, executed⟩ := allocate_success buckets capacities demand lengths bounded
  exact ⟨out, executed, allocate_refines buckets capacities demand out executed⟩

end LidoSRv3.Audit.Source.TrioAlloc2
