import LidoSRv3.Audit.Source.TrioAlloc2.LoopBounds

namespace LidoSRv3.Audit.Source.TrioAlloc2

/-- Unbounded mathematical observation, not an extra EVM accumulator. -/
def bucketTotal (buckets : List Word) : Nat :=
  match buckets with
  | [] => 0
  | b :: bs => b.val + bucketTotal bs

theorem bucketTotal_set (buckets : List Word) (index : Nat)
    (previous updated : Word) (amount : Nat)
    (hget : buckets[index]? = some previous)
    (hadd : updated.val = previous.val + amount) :
    bucketTotal (buckets.set index updated) = bucketTotal buckets + amount := by
  induction buckets generalizing index with
  | nil => simp at hget
  | cons b bs ih =>
    cases index with
    | zero =>
      simp at hget
      cases hget
      simp [bucketTotal, hadd, Nat.add_assoc, Nat.add_comm]
    | succ index =>
      simp at hget
      simpa [bucketTotal, Nat.add_assoc] using congrArg (b.val + ·) (ih index hget)

/-- Conservation is derived from the successful executor result, including its
checked update. No assumption about a separately successful scan or addition. -/
theorem step_conserves (buckets capacities : List Word) (demand : Word)
    (out : StepOutput) (h : step buckets capacities demand = .ok out) :
    bucketTotal out.buckets = bucketTotal buckets + out.amount.val := by
  by_cases hz : demand.val = 0
  · simp [step, hz, pure, Except.pure] at h
    cases h
    simp [zero]
  · cases hf : firstScan buckets capacities 0
        { index := buckets.length, allocation := maxWord, count := zero } with
    | error e => simp [step, hz, hf, bind, Except.bind, pure, Except.pure] at h
    | ok candidate =>
      by_cases hc : candidate.count.val = 0
      · simp [step, hz, hf, hc, bind, Except.bind, pure, Except.pure] at h
        cases h
        simp [zero]
      · cases hs : secondScan buckets capacities candidate.allocation maxWord with
        | error e => simp [step, hz, hf, hc, hs, bind, Except.bind, pure, Except.pure] at h
        | ok upper =>
          simp only [step, hz, hf, hc, hs, ↓reduceIte,
            bind, Except.bind, pure, Except.pure] at h
          by_cases hcount : 1 < candidate.count.val
          · simp only [hcount, ↓reduceIte] at h
            cases hceil : ceilDiv demand candidate.count with
            | error e => simp [hceil] at h
            | ok share =>
              simp only [hceil] at h
              repeat' split at h
              all_goals cases h
              all_goals
                apply bucketTotal_set
                · assumption
                · apply checkedAdd_value; assumption
          · simp only [hcount, ↓reduceIte] at h
            repeat' split at h
            all_goals cases h
            all_goals
              apply bucketTotal_set
              · assumption
              · apply checkedAdd_value; assumption

/-- Includes nonzero initial accumulated amounts for sequential loop reasoning. -/
theorem allocateLoop_conserves (buckets capacities : List Word)
    (demand allocated : Word) (out : StepOutput)
    (hrun : allocateLoop buckets capacities demand allocated = .ok out) :
    bucketTotal out.buckets + allocated.val = bucketTotal buckets + out.amount.val := by
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
        have conserved := step_conserves buckets capacities remaining result hstep
        by_cases hzero : result.amount.val = 0
        · simp only [hzero, ↓reduceIte] at hrun
          cases hrun
          simp only at *
          omega
        · simp only [hzero, ↓reduceIte] at hrun
          split at hrun
          · cases hrun
          · rename_i total hadd
            have sumValue := checkedAdd_value allocated result.amount total hadd
            have decrease : 2 ^ 256 - total.val < 2 ^ 256 - allocated.val := by
              have := total.isLt
              omega
            have recursive := allocateLoop_conserves result.buckets capacities demand total out hrun
            omega
  · simp only [hmore, ↓reduceIte] at hrun
    cases hrun
    rfl
termination_by 2 ^ 256 - allocated.val
decreasing_by exact decrease

theorem allocate_conserves (buckets capacities : List Word) (demand : Word)
    (out : StepOutput) (h : allocate buckets capacities demand = .ok out) :
    bucketTotal out.buckets = bucketTotal buckets + out.amount.val := by
  simpa [zero] using allocateLoop_conserves buckets capacities demand zero out h

/-- Two successful decoded library executions conserve their combined return.
The second capacity array may differ. This is not a router-state, same-block,
rollback, or combined-demand equivalence theorem. -/
theorem allocate_twice_conserves (buckets capacities₁ capacities₂ : List Word)
    (demand₁ demand₂ : Word) (first second : StepOutput)
    (hfirst : allocate buckets capacities₁ demand₁ = .ok first)
    (hsecond : allocate first.buckets capacities₂ demand₂ = .ok second) :
    bucketTotal second.buckets = bucketTotal buckets + first.amount.val + second.amount.val ∧
    first.amount.val + second.amount.val ≤ demand₁.val + demand₂.val := by
  have h₁ := allocate_conserves buckets capacities₁ demand₁ first hfirst
  have h₂ := allocate_conserves first.buckets capacities₂ demand₂ second hsecond
  have b₁ := allocate_amount_le_demand buckets capacities₁ demand₁ first hfirst
  have b₂ := allocate_amount_le_demand first.buckets capacities₂ demand₂ second hsecond
  constructor <;> omega

end LidoSRv3.Audit.Source.TrioAlloc2
