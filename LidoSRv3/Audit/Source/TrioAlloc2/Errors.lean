import LidoSRv3.Audit.Source.TrioAlloc2.LoopTotality

/-! Exact decoded-array outcomes, preserving the zero-demand guard before scans.
Raw ABI decoding and panic-byte representation remain separate layers. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2

theorem firstScan_short_error (buckets capacities : List Word) (index : Nat)
    (candidate : Candidate) (short : capacities.length < buckets.length)
    (countBound : candidate.count.val + buckets.length < 2 ^ 256) :
    firstScan buckets capacities index candidate = .error .arrayBounds := by
  induction buckets generalizing capacities index candidate with
  | nil => simp at short
  | cons bucket tail ih =>
    cases capacities with
    | nil => rfl
    | cons capacity rest =>
      have tailShort : rest.length < tail.length := by simpa using short
      simp only [List.length_cons] at countBound
      by_cases closed : bucket.val ≥ capacity.val
      · have executed := ih rest (index + 1) candidate tailShort (by omega)
        simpa [firstScan, closed, pure, Except.pure, bind, Except.bind] using executed
      · by_cases lower : candidate.allocation.val > bucket.val
        · have executed := ih rest (index + 1)
            { index, allocation := bucket, count := one } tailShort (by simp only [one]; omega)
          simpa [firstScan, closed, lower, pure, Except.pure, bind, Except.bind] using executed
        · by_cases tied : candidate.allocation.val = bucket.val
          · have addBound : candidate.count.val + 1 < 2 ^ 256 := by omega
            let nextCount : Word := ⟨candidate.count.val + 1, addBound⟩
            have added : checkedAdd candidate.count one = .ok nextCount := by
              simp [checkedAdd, one, addBound, nextCount]
            have executed := ih rest (index + 1) { candidate with count := nextCount }
              tailShort (by dsimp [nextCount]; omega)
            simpa [firstScan, closed, lower, tied, added, pure, Except.pure,
              bind, Except.bind] using executed
          · have executed := ih rest (index + 1) candidate tailShort (by omega)
            simpa [firstScan, closed, lower, tied, pure, Except.pure,
              bind, Except.bind] using executed

theorem step_short_error (buckets capacities : List Word) (demand : Word)
    (positive : demand.val ≠ 0) (short : capacities.length < buckets.length)
    (bounded : buckets.length < 2 ^ 256) :
    step buckets capacities demand = .error .arrayBounds := by
  have scan := firstScan_short_error buckets capacities 0
    { index := buckets.length, allocation := maxWord, count := zero } short
    (by simpa [zero] using bounded)
  simp [step, positive, scan, pure, Except.pure, bind, Except.bind]

theorem allocate_short_error (buckets capacities : List Word) (demand : Word)
    (positive : demand.val ≠ 0) (short : capacities.length < buckets.length)
    (bounded : buckets.length < 2 ^ 256) :
    allocate buckets capacities demand = .error .arrayBounds := by
  have sub : checkedSub demand zero = .ok demand := by simp [checkedSub, zero]
  have failed := step_short_error buckets capacities demand positive short bounded
  unfold allocate
  rw [allocateLoop]
  simp only [show zero.val < demand.val by change 0 < demand.val; omega, ↓reduceIte, sub, failed]

/-- Exactly the zero-demand guard or sufficient capacities permit a decoded call.
For all other representable array lengths the outcome is arrayBounds. -/
theorem allocate_success_iff (buckets capacities : List Word) (demand : Word)
    (bounded : buckets.length < 2 ^ 256) :
    (∃ out, allocate buckets capacities demand = .ok out) ↔
      demand.val = 0 ∨ buckets.length ≤ capacities.length := by
  constructor
  · rintro ⟨out, executed⟩
    by_cases hz : demand.val = 0
    · exact Or.inl hz
    · right
      by_cases lengths : buckets.length ≤ capacities.length
      · exact lengths
      · have failed := allocate_short_error buckets capacities demand hz (by omega) bounded
        rw [executed] at failed
        cases failed
  · rintro (hz | lengths)
    · have eq : demand = zero := Fin.ext hz
      subst demand
      exact ⟨⟨zero, buckets⟩, allocate_zero_demand buckets capacities⟩
    · exact allocate_success buckets capacities demand lengths bounded

end LidoSRv3.Audit.Source.TrioAlloc2
