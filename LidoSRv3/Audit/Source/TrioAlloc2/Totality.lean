import LidoSRv3.Audit.Source.TrioAlloc2.Arithmetic
import LidoSRv3.Audit.Source.TrioAlloc2.Selection

/-! Successful execution derived from array and word bounds, rather than assumed
for individual instructions. These are decoded-array bounds, not byte-memory proofs. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2

theorem firstScan_success (buckets capacities : List Word) (index : Nat)
    (candidate : Candidate) (lengths : buckets.length ≤ capacities.length)
    (countBound : candidate.count.val + buckets.length < 2 ^ 256) :
    ∃ out, firstScan buckets capacities index candidate = .ok out := by
  induction buckets generalizing capacities index candidate with
  | nil => exact ⟨candidate, rfl⟩
  | cons bucket tail ih =>
    cases capacities with
    | nil => simp at lengths
    | cons capacity rest =>
      have tailLengths : tail.length ≤ rest.length := by simpa using lengths
      simp only [List.length_cons] at countBound
      by_cases closed : bucket.val ≥ capacity.val
      · obtain ⟨out, executed⟩ := ih rest (index + 1) candidate tailLengths (by omega)
        exact ⟨out, by simpa [firstScan, closed, pure, Except.pure, bind, Except.bind] using executed⟩
      · by_cases lower : candidate.allocation.val > bucket.val
        · obtain ⟨out, executed⟩ := ih rest (index + 1)
            { index, allocation := bucket, count := one } tailLengths (by simp only [one]; omega)
          exact ⟨out, by simpa [firstScan, closed, lower, pure, Except.pure, bind, Except.bind] using executed⟩
        · by_cases tied : candidate.allocation.val = bucket.val
          · have addBound : candidate.count.val + 1 < 2 ^ 256 := by omega
            let nextCount : Word := ⟨candidate.count.val + 1, addBound⟩
            have added : checkedAdd candidate.count one = .ok nextCount := by
              simp [checkedAdd, one, addBound, nextCount]
            obtain ⟨out, executed⟩ := ih rest (index + 1) { candidate with count := nextCount }
              tailLengths (by dsimp [nextCount]; omega)
            exact ⟨out, by simpa [firstScan, closed, lower, tied, added, pure, Except.pure,
              bind, Except.bind] using executed⟩
          · obtain ⟨out, executed⟩ := ih rest (index + 1) candidate tailLengths (by omega)
            exact ⟨out, by simpa [firstScan, closed, lower, tied, pure, Except.pure,
              bind, Except.bind] using executed⟩

theorem initialScan_success (buckets capacities : List Word)
    (lengths : buckets.length ≤ capacities.length) (bounded : buckets.length < 2 ^ 256) :
    ∃ out, firstScan buckets capacities 0
      { index := buckets.length, allocation := maxWord, count := zero } = .ok out := by
  exact firstScan_success buckets capacities 0 _ lengths (by simpa [zero] using bounded)

theorem secondScan_success (buckets capacities : List Word) (best upper : Word)
    (lengths : buckets.length ≤ capacities.length) :
    ∃ out, secondScan buckets capacities best upper = .ok out := by
  induction buckets generalizing capacities upper with
  | nil => exact ⟨upper, rfl⟩
  | cons bucket tail ih =>
    cases capacities with
    | nil => simp at lengths
    | cons capacity rest =>
      have tailLengths : tail.length ≤ rest.length := by simpa using lengths
      simp only [secondScan]
      split
      · exact ih rest upper tailLengths
      · split
        · exact ih rest bucket tailLengths
        · exact ih rest upper tailLengths

/-- Successful selection names the actual paired bucket/capacity values, and
that bucket is open. No separate successful-read hypothesis is needed. -/
theorem initialScan_selected_row (buckets capacities : List Word) (candidate : Candidate)
    (lengths : buckets.length ≤ capacities.length)
    (h : firstScan buckets capacities 0
      { index := buckets.length, allocation := maxWord, count := zero } = .ok candidate)
    (nonempty : candidate.count.val ≠ 0) :
    ∃ bucket capacity, buckets[candidate.index]? = some bucket ∧
      capacities[candidate.index]? = some capacity ∧
      bucket.val = candidate.allocation.val ∧ bucket.val < capacity.val := by
  have bounded := initialScan_index_bound buckets capacities candidate h nonempty
  have capBounded : candidate.index < capacities.length := by omega
  let bucket := buckets[candidate.index]'bounded
  let capacity := capacities[candidate.index]'capBounded
  have hb : buckets[candidate.index]? = some bucket := List.getElem?_eq_getElem bounded
  have hc : capacities[candidate.index]? = some capacity := List.getElem?_eq_getElem capBounded
  have indexEq := initialScan_first_index buckets capacities candidate h nonempty
  have observed : (decodedRows buckets capacities)[candidate.index]? =
      some (Spec.Row.mk bucket.val capacity.val) := by
    simp [decodedRows, List.getElem?_zipWith, hb, hc]
  rw [indexEq] at observed
  have selected := List.findIdx_of_getElem?_eq_some observed
  simp only [Bool.and_eq_true, decide_eq_true_eq] at selected
  exact ⟨bucket, capacity, hb, hc, selected.2, selected.1⟩

theorem secondScan_above_best (buckets capacities : List Word) (best upper out : Word)
    (entry : best.val < upper.val)
    (h : secondScan buckets capacities best upper = .ok out) : best.val < out.val := by
  induction buckets generalizing capacities upper with
  | nil => simp [secondScan] at h; cases h; exact entry
  | cons bucket tail ih =>
    cases capacities with
    | nil => simp [secondScan] at h
    | cons capacity rest =>
      simp only [secondScan] at h
      split at h
      · exact ih rest upper entry h
      · split at h
        · rename_i between
          have hb : best.val < bucket.val ∧ bucket.val < upper.val := by simpa using between
          exact ih rest bucket hb.1 h
        · exact ih rest upper entry h

/-- A valid decoded shape and representable length suffice for every checked
operation in the complete candidate step. No scan, read, divide, or update success
is a premise. Capacities may be below their paired allocations. -/
theorem step_success (buckets capacities : List Word) (demand : Word)
    (lengths : buckets.length ≤ capacities.length) (bounded : buckets.length < 2 ^ 256) :
    ∃ out, step buckets capacities demand = .ok out := by
  by_cases hz : demand.val = 0
  · exact ⟨⟨zero, buckets⟩, by simp [step, hz, pure, Except.pure]⟩
  · obtain ⟨candidate, candidateEq⟩ := initialScan_success buckets capacities lengths bounded
    by_cases empty : candidate.count.val = 0
    · exact ⟨⟨zero, buckets⟩, by simp [step, hz, candidateEq, empty, bind, Except.bind,
        pure, Except.pure]⟩
    · obtain ⟨bucket, capacity, bucketEq, capacityEq, levelEq, opened⟩ :=
        initialScan_selected_row buckets capacities candidate lengths candidateEq empty
      obtain ⟨upper, upperEq⟩ := secondScan_success buckets capacities candidate.allocation maxWord lengths
      have belowMax : candidate.allocation.val < maxWord.val := by
        have capBound := capacity.isLt
        simp only [maxWord]
        omega
      have upperBound := secondScan_above_best buckets capacities candidate.allocation maxWord upper belowMax upperEq
      have shareSuccess : ∃ share, (if candidate.count.val > 1 then ceilDiv demand candidate.count
          else pure demand : Result Word) = .ok share := by
        split
        · obtain ⟨share, executed, _⟩ := ceilDiv_success demand candidate.count empty
          exact ⟨share, executed⟩
        · exact ⟨demand, rfl⟩
      obtain ⟨share, shareEq⟩ := shareSuccess
      let ceiling := minWord upper capacity
      have above : candidate.allocation.val ≤ ceiling.val := by
        dsimp [ceiling]
        rw [minWord_value]
        omega
      let space : Word := ⟨ceiling.val - candidate.allocation.val,
        Nat.lt_of_le_of_lt (Nat.sub_le ..) ceiling.isLt⟩
      have spaceEq : checkedSub ceiling candidate.allocation = .ok space := by
        simp [checkedSub, above, space]
      let amount := minWord share space
      have amountBound : amount.val ≤ space.val := by
        dsimp [amount]
        rw [minWord_value]
        exact Nat.min_le_right _ _
      have updateBound : bucket.val + amount.val < 2 ^ 256 := by
        have ceilingBound := ceiling.isLt
        dsimp [space] at amountBound
        omega
      let updated : Word := ⟨bucket.val + amount.val, updateBound⟩
      have updateEq : checkedAdd bucket amount = .ok updated := by
        simp [checkedAdd, updateBound, updated]
      refine ⟨⟨amount, buckets.set candidate.index updated⟩, ?_⟩
      by_cases divided : candidate.count.val > 1
      · simp only [divided, ↓reduceIte] at shareEq
        simp [step, hz, candidateEq, empty, upperEq, divided, shareEq, capacityEq,
          bucketEq, spaceEq, updateEq, bind, Except.bind, pure, Except.pure, ceiling, amount]
      · simp only [divided, ↓reduceIte, pure, Except.pure] at shareEq
        cases shareEq
        simp [step, hz, candidateEq, empty, upperEq, divided, capacityEq,
          bucketEq, spaceEq, updateEq, bind, Except.bind, pure, Except.pure, ceiling, amount]

end LidoSRv3.Audit.Source.TrioAlloc2
