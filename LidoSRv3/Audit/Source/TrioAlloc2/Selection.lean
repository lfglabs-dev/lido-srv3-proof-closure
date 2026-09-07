import LidoSRv3.Audit.Source.TrioAlloc2.ScanCorrespondence

/-! Remove the source sentinel from the mathematical minimum observation. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2

/-- Every open word row lies strictly below the source's sentinel. -/
theorem openLevels_lt_max (buckets capacities : List Word) (level : Nat)
    (h : level ∈ Spec.openLevels (decodedRows buckets capacities)) : level < maxWord.val := by
  induction buckets generalizing capacities with
  | nil => simp [decodedRows, Spec.openLevels] at h
  | cons bucket tail ih =>
    cases capacities with
    | nil => simp [decodedRows, Spec.openLevels] at h
    | cons capacity rest =>
      by_cases opened : bucket.val < capacity.val
      · simp [decodedRows, Spec.openLevels, opened] at h
        rcases h with eq | later
        · have bounded := capacity.isLt
          simp only [maxWord]
          omega
        · exact ih rest (by simpa [decodedRows, Spec.openLevels] using later)
      · simp [decodedRows, Spec.openLevels, opened] at h
        exact ih rest (by simpa [decodedRows, Spec.openLevels] using h)

theorem foldl_min_eq_entry_or_mem (levels : List Nat) (entry : Nat) :
    levels.foldl Nat.min entry = entry ∨ levels.foldl Nat.min entry ∈ levels := by
  induction levels generalizing entry with
  | nil => exact Or.inl rfl
  | cons level tail ih =>
    have result := ih (min entry level)
    rcases result with eq | mem
    · by_cases le : entry ≤ level
      · exact Or.inl (by simpa [Nat.min_eq_left le] using eq)
      · right
        have eqLevel : min entry level = level := Nat.min_eq_right (by omega)
        rw [eqLevel] at eq
        simp [List.foldl_cons, eqLevel, eq]
    · right
      exact List.mem_cons_of_mem _ mem

/-- The actual sentinel scan corresponds to the independent optional minimum.
The absent case is exactly an absence of open rows, not a guessed count bound. -/
theorem initialScan_minimum_option (buckets capacities : List Word) (out : Candidate)
    (h : firstScan buckets capacities 0
      { index := buckets.length, allocation := maxWord, count := zero } = .ok out) :
    Spec.minimum (Spec.openLevels (decodedRows buckets capacities)) =
      if out.count.val = 0 then none else some out.allocation.val := by
  have minimumEq := firstScan_minimum buckets capacities 0 _ out h
  have countEq := initialScan_tie_count buckets capacities out h
  cases levelsEq : Spec.openLevels (decodedRows buckets capacities) with
  | nil =>
    simp only [levelsEq, List.filter_nil, List.length_nil] at countEq
    simp [levelsEq, Spec.minimum, countEq]
  | cons level tail =>
    have levelBound := openLevels_lt_max buckets capacities level (by simp [levelsEq])
    have minEntry : min maxWord.val level = level := Nat.min_eq_right (by omega)
    dsimp only at minimumEq
    simp only [levelsEq, List.foldl_cons, minEntry] at minimumEq
    have member : out.allocation.val ∈ level :: tail := by
      rw [minimumEq]
      rcases foldl_min_eq_entry_or_mem tail level with eq | mem
      · simp [eq]
      · exact List.mem_cons_of_mem _ mem
    have positive : 0 < ((level :: tail).filter (fun n => n = out.allocation.val)).length := by
      apply List.length_pos_iff_exists_mem.mpr
      exact ⟨out.allocation.val, List.mem_filter.mpr ⟨member, by simp⟩⟩
    have nonzero : out.count.val ≠ 0 := by
      rw [levelsEq] at countEq
      omega
    simp [levelsEq, Spec.minimum, nonzero, minimumEq]

theorem initialScan_no_candidate_iff (buckets capacities : List Word) (out : Candidate)
    (h : firstScan buckets capacities 0
      { index := buckets.length, allocation := maxWord, count := zero } = .ok out) :
    out.count.val = 0 ↔ Spec.openLevels (decodedRows buckets capacities) = [] := by
  have eq := initialScan_minimum_option buckets capacities out h
  cases levelsEq : Spec.openLevels (decodedRows buckets capacities) with
  | nil => simp [levelsEq, Spec.minimum] at eq ⊢; exact eq
  | cons level tail => simp [levelsEq, Spec.minimum] at eq ⊢; exact eq.1

end LidoSRv3.Audit.Source.TrioAlloc2
