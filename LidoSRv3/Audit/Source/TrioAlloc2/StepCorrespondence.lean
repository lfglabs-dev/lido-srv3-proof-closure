import LidoSRv3.Audit.Source.TrioAlloc2.ChoiceCorrespondence

namespace LidoSRv3.Audit.Source.TrioAlloc2

private theorem decodedRows_set (buckets capacities : List Word) (index : Nat)
    (updated capacity : Word) (hc : capacities[index]? = some capacity) :
    decodedRows (buckets.set index updated) capacities =
      (decodedRows buckets capacities).set index ⟨updated.val, capacity.val⟩ := by
  apply List.ext_getElem?
  intro j
  by_cases eq : index = j
  · subst j
    simp only [decodedRows, List.getElem?_zipWith, List.getElem?_set', ↓reduceIte, hc,
      Option.map_eq_map]
    cases buckets[index]? <;> rfl
  · simp [decodedRows, List.getElem?_zipWith, List.getElem?_set_ne eq, eq]

private theorem spec_update_set (rows : List Spec.Row) (index amount : Nat) (row : Spec.Row)
    (hr : rows[index]? = some row) :
    (rows.zipIdx.map fun (r, i) => if i = index then { r with allocation := r.allocation + amount } else r) =
      rows.set index { row with allocation := row.allocation + amount } := by
  apply List.ext_getElem?
  intro j
  by_cases eq : index = j
  · subst j
    simp [List.getElem?_map, List.getElem?_zipIdx, List.getElem?_set', hr]
  · simp [List.getElem?_map, List.getElem?_zipIdx, List.getElem?_set_ne eq,
      Ne.symm eq, Option.map_map, Function.comp_def]

private theorem selected_step_refines {buckets capacities : List Word} {demand : Word}
    {candidate : Candidate} {upper share capacity space bucket updated : Word}
    (positive : demand.val ≠ 0) (nonempty : candidate.count.val ≠ 0)
    (scanned : firstScan buckets capacities 0
      { index := buckets.length, allocation := maxWord, count := zero } = .ok candidate)
    (higher : secondScan buckets capacities candidate.allocation maxWord = .ok upper)
    (shareValue : share.val = (demand.val + candidate.count.val - 1) / candidate.count.val)
    (capacityRead : capacities[candidate.index]? = some capacity)
    (spaceEq : checkedSub (minWord upper capacity) candidate.allocation = .ok space)
    (bucketRead : buckets[candidate.index]? = some bucket)
    (updateEq : checkedAdd bucket (minWord share space) = .ok updated) :
    Spec.step (decodedRows buckets capacities) demand.val =
      ((minWord share space).val, decodedRows (buckets.set candidate.index updated) capacities) := by
  have chosen := choose_of_scans buckets capacities demand candidate upper bucket capacity
    positive nonempty scanned higher bucketRead capacityRead
  have spaceValue := checkedSub_value (minWord upper capacity) candidate.allocation space spaceEq
  have amountValue : (minWord share space).val =
      min ((demand.val + candidate.count.val - 1) / candidate.count.val)
        (min upper.val capacity.val - candidate.allocation.val) := by
    rw [minWord_value, shareValue, spaceValue, minWord_value]
  rw [← amountValue] at chosen
  have rowRead : (decodedRows buckets capacities)[candidate.index]? =
      some (Spec.Row.mk bucket.val capacity.val) := by
    simp [decodedRows, List.getElem?_zipWith, bucketRead, capacityRead]
  rw [Spec.step, chosen]
  apply Prod.ext
  · rfl
  · dsimp only
    rw [spec_update_set _ _ _ _ rowRead, decodedRows_set _ _ _ _ _ capacityRead]
    have updatedValue := checkedAdd_value bucket (minWord share space) updated updateEq
    simp [updatedValue]

/-- The actual successful decoded step refines the original independent
mathematical step, including its selected row update. No intermediate-success
or specification-choice premise is required. -/
theorem step_refines (buckets capacities : List Word) (demand : Word)
    (out : StepOutput) (h : step buckets capacities demand = .ok out) :
    Spec.step (decodedRows buckets capacities) demand.val =
      (out.amount.val, decodedRows out.buckets capacities) := by
  by_cases hz : demand.val = 0
  · simp [step, hz, pure, Except.pure] at h
    cases h
    simp [hz, Spec.step_zero, zero]
  · cases hf : firstScan buckets capacities 0
        { index := buckets.length, allocation := maxWord, count := zero } with
    | error e => simp [step, hz, hf, bind, Except.bind, pure, Except.pure] at h
    | ok candidate =>
      by_cases hc : candidate.count.val = 0
      · simp [step, hz, hf, hc, bind, Except.bind, pure, Except.pure] at h
        cases h
        simp [Spec.step, choose_none_of_scan buckets capacities demand candidate hf hc, zero]
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
              have shareValue := ceilDiv_formula demand candidate.count share hc hceil
              simp only [hceil] at h
              repeat' split at h
              all_goals cases h
              all_goals apply selected_step_refines (candidate := candidate) (upper := upper) (share := share)
              all_goals assumption
          · have countOne : candidate.count.val = 1 := by omega
            have shareValue : demand.val = (demand.val + candidate.count.val - 1) / candidate.count.val := by
              simp [countOne]
            simp only [hcount, ↓reduceIte] at h
            repeat' split at h
            all_goals cases h
            all_goals apply selected_step_refines (candidate := candidate) (upper := upper) (share := demand)
            all_goals assumption

end LidoSRv3.Audit.Source.TrioAlloc2
