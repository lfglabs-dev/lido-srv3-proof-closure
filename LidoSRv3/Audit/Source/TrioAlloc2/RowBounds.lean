import LidoSRv3.Audit.Source.TrioAlloc2.Totality
import LidoSRv3.Audit.Source.TrioAlloc2.LoopBounds

namespace LidoSRv3.Audit.Source.TrioAlloc2

private theorem unchanged_row_bounds {buckets : List Word} {i : Nat} {before after capacity : Word}
    (hb : buckets[i]? = some before) (ha : buckets[i]? = some after) :
    before.val ≤ after.val ∧ after.val ≤ max before.val capacity.val := by
  have : before = after := Option.some.inj (hb.symm.trans ha)
  subst after
  exact ⟨Nat.le_refl _, Nat.le_max_left _ _⟩

private theorem selected_row_bounds {buckets capacities : List Word} {candidate : Candidate}
    {upper capacity space share previous updated before after cap : Word} {i : Nat}
    (lengths : buckets.length ≤ capacities.length)
    (scan : firstScan buckets capacities 0
      { index := buckets.length, allocation := maxWord, count := zero } = .ok candidate)
    (nonempty : candidate.count.val ≠ 0)
    (capacityRead : capacities[candidate.index]? = some capacity)
    (spaceEq : checkedSub (minWord upper capacity) candidate.allocation = .ok space)
    (previousRead : buckets[candidate.index]? = some previous)
    (updateEq : checkedAdd previous (minWord share space) = .ok updated)
    (beforeRead : buckets[i]? = some before) (capRead : capacities[i]? = some cap)
    (afterRead : (buckets.set candidate.index updated)[i]? = some after) :
    before.val ≤ after.val ∧ after.val ≤ max before.val cap.val := by
  by_cases same : candidate.index = i
  · subst i
    obtain ⟨b, c, hb, hc, level, opened⟩ := initialScan_selected_row buckets capacities candidate lengths scan nonempty
    have eqb : b = previous := Option.some.inj (hb.symm.trans previousRead)
    have eqc : c = capacity := Option.some.inj (hc.symm.trans capacityRead)
    have eqbefore : previous = before := Option.some.inj (previousRead.symm.trans beforeRead)
    have eqcap : capacity = cap := Option.some.inj (capacityRead.symm.trans capRead)
    subst b; subst c; subst before; subst cap
    have updatedEq : updated = after := by
      simpa [List.getElem?_set', previousRead] using afterRead
    subst after
    have updateValue := checkedAdd_value previous (minWord share space) updated updateEq
    have spaceValue := checkedSub_value (minWord upper capacity) candidate.allocation space spaceEq
    have amountBound : (minWord share space).val ≤ space.val := by
      rw [minWord_value]; exact Nat.min_le_right _ _
    have ceilingBound : (minWord upper capacity).val ≤ capacity.val := by
      rw [minWord_value]; exact Nat.min_le_right _ _
    constructor
    · omega
    · have : updated.val ≤ capacity.val := by omega
      exact Nat.le_trans this (Nat.le_max_right _ _)
  · rw [List.getElem?_set_ne same] at afterRead
    exact unchanged_row_bounds beforeRead afterRead

/-- Every successful step increases each row monotonically and never exceeds its
capacity unless that row was already overfull on entry. Overfull inputs remain
admitted; this is not a precondition restricting the producer. -/
theorem step_row_bounds (buckets capacities : List Word) (demand : Word)
    (out : StepOutput) (lengths : buckets.length ≤ capacities.length)
    (h : step buckets capacities demand = .ok out)
    (i : Nat) (before after cap : Word)
    (beforeRead : buckets[i]? = some before) (capRead : capacities[i]? = some cap)
    (afterRead : out.buckets[i]? = some after) :
    before.val ≤ after.val ∧ after.val ≤ max before.val cap.val := by
  by_cases hz : demand.val = 0
  · simp [step, hz, pure, Except.pure] at h
    cases h
    exact unchanged_row_bounds beforeRead afterRead
  · cases hf : firstScan buckets capacities 0
        { index := buckets.length, allocation := maxWord, count := zero } with
    | error e => simp [step, hz, hf, bind, Except.bind, pure, Except.pure] at h
    | ok candidate =>
      by_cases hc : candidate.count.val = 0
      · simp [step, hz, hf, hc, bind, Except.bind, pure, Except.pure] at h
        cases h
        exact unchanged_row_bounds beforeRead afterRead
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
                apply selected_row_bounds lengths hf hc
                all_goals assumption
          · simp only [hcount, ↓reduceIte] at h
            repeat' split at h
            all_goals cases h
            all_goals
              apply selected_row_bounds lengths hf hc
              all_goals assumption


/-- The whole loop preserves the per-row bound, including any overfull entry. -/
theorem allocateLoop_row_bounds (buckets capacities : List Word) (demand allocated : Word)
    (out : StepOutput) (lengths : buckets.length ≤ capacities.length)
    (run : allocateLoop buckets capacities demand allocated = .ok out)
    (i : Nat) (before after cap : Word)
    (beforeRead : buckets[i]? = some before) (capRead : capacities[i]? = some cap)
    (afterRead : out.buckets[i]? = some after) :
    before.val ≤ after.val ∧ after.val ≤ max before.val cap.val := by
  rw [allocateLoop] at run
  by_cases more : allocated.val < demand.val
  · simp only [more, ↓reduceIte] at run
    cases subEq : checkedSub demand allocated with
    | error e => simp [subEq] at run
    | ok remaining =>
      simp only [subEq] at run
      cases stepEq : step buckets capacities remaining with
      | error e => simp [stepEq] at run
      | ok result =>
        simp only [stepEq] at run
        have lengthEq := step_preserves_length buckets capacities remaining result stepEq
        by_cases stopped : result.amount.val = 0
        · simp only [stopped, ↓reduceIte] at run
          cases run
          exact step_row_bounds buckets capacities remaining result lengths stepEq i before after cap
            beforeRead capRead afterRead
        · simp only [stopped, ↓reduceIte] at run
          split at run
          · cases run
          · rename_i total addEq
            have decrease : 2 ^ 256 - total.val < 2 ^ 256 - allocated.val := by
              have := checkedAdd_value allocated result.amount total addEq
              have := total.isLt
              omega
            have bound : i < buckets.length := by
              by_cases inside : i < buckets.length
              · exact inside
              · have absent : buckets[i]? = none := List.getElem?_eq_none (by omega)
                rw [absent] at beforeRead
                cases beforeRead
            have midBound : i < result.buckets.length := by omega
            let middle := result.buckets[i]'midBound
            have middleRead : result.buckets[i]? = some middle := List.getElem?_eq_getElem midBound
            have first := step_row_bounds buckets capacities remaining result lengths stepEq i before middle cap
              beforeRead capRead middleRead
            have rest := allocateLoop_row_bounds result.buckets capacities demand total out
              (by omega) run i middle after cap middleRead capRead afterRead
            exact ⟨by omega, by omega⟩
  · simp only [more, ↓reduceIte] at run
    cases run
    exact unchanged_row_bounds beforeRead afterRead
termination_by 2 ^ 256 - allocated.val
decreasing_by exact decrease

theorem allocate_row_bounds (buckets capacities : List Word) (demand : Word)
    (out : StepOutput) (lengths : buckets.length ≤ capacities.length)
    (run : allocate buckets capacities demand = .ok out)
    (i : Nat) (before after cap : Word)
    (beforeRead : buckets[i]? = some before) (capRead : capacities[i]? = some cap)
    (afterRead : out.buckets[i]? = some after) :
    before.val ≤ after.val ∧ after.val ≤ max before.val cap.val :=
  allocateLoop_row_bounds buckets capacities demand zero out lengths run i before after cap
    beforeRead capRead afterRead

/-- The parent's checked subtraction of original allocation cannot underflow
for a successfully returned consumer row. The later multiplication is separate. -/
theorem allocate_delta_success (buckets capacities : List Word) (demand : Word)
    (out : StepOutput) (lengths : buckets.length ≤ capacities.length)
    (run : allocate buckets capacities demand = .ok out)
    (i : Nat) (before after cap : Word)
    (beforeRead : buckets[i]? = some before) (capRead : capacities[i]? = some cap)
    (afterRead : out.buckets[i]? = some after) :
    ∃ delta, checkedSub after before = .ok delta ∧ delta.val = after.val - before.val := by
  have bound := (allocate_row_bounds buckets capacities demand out lengths run i before after cap
    beforeRead capRead afterRead).1
  unfold checkedSub
  simp only [bound, ↓reduceDIte]
  exact ⟨_, rfl, rfl⟩

#print axioms step_row_bounds
#print axioms allocateLoop_row_bounds
#print axioms allocate_row_bounds
#print axioms allocate_delta_success
end LidoSRv3.Audit.Source.TrioAlloc2
