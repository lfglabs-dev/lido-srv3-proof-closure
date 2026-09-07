import LidoSRv3.Audit.Source.TrioAlloc2.Step

/-! Bounds derived from successful source scans. These do not assume a fixed
module limit, equal array lengths, or success of intermediate arithmetic. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2

/-- Counting tied minima can grow by at most one per visited bucket. -/
theorem firstScan_count_bound (buckets capacities : List Word) (index : Nat)
    (candidate out : Candidate)
    (h : firstScan buckets capacities index candidate = .ok out) :
    out.count.val ≤ candidate.count.val + buckets.length := by
  induction buckets generalizing capacities index candidate with
  | nil => simp [firstScan] at h; cases h; omega
  | cons bucket tail ih =>
    cases capacities with
    | nil => simp [firstScan] at h
    | cons capacity rest =>
      simp only [firstScan] at h
      split at h
      · simp only [pure, Except.pure, bind, Except.bind] at h
        have bound := ih rest (index + 1) candidate h
        simp only [List.length_cons]; omega
      · split at h
        · simp only [pure, Except.pure, bind, Except.bind] at h
          have bound := ih rest (index + 1) { index, allocation := bucket, count := one } h
          simp only [one] at bound
          simp only [List.length_cons]; omega
        · split at h
          · cases hc : checkedAdd candidate.count one with
            | error e => simp [hc, bind, Except.bind] at h
            | ok count =>
              simp only [hc, pure, Except.pure, bind, Except.bind] at h
              have bound := ih rest (index + 1) { candidate with count } h
              dsimp only at bound
              have value := checkedAdd_value candidate.count one count hc
              simp only [one] at value
              simp only [List.length_cons]; omega
          · simp only [pure, Except.pure, bind, Except.bind] at h
            have bound := ih rest (index + 1) candidate h
            simp only [List.length_cons]; omega

/-- The actual initial scan has at most as many ties as input buckets. -/
theorem initialScan_count_bound (buckets capacities : List Word) (out : Candidate)
    (h : firstScan buckets capacities 0
      { index := buckets.length, allocation := maxWord, count := zero } = .ok out) :
    out.count.val ≤ buckets.length := by
  have bound := firstScan_count_bound buckets capacities 0 _ out h
  simpa [zero] using bound

/-- A nonempty candidate always names an already visited position. -/
theorem firstScan_index_bound (buckets capacities : List Word) (index : Nat)
    (candidate out : Candidate)
    (entry : candidate.count.val ≠ 0 → candidate.index < index)
    (sentinel : candidate.count.val = 0 → candidate.allocation = maxWord)
    (h : firstScan buckets capacities index candidate = .ok out)
    (nonempty : out.count.val ≠ 0) : out.index < index + buckets.length := by
  induction buckets generalizing capacities index candidate with
  | nil => simp [firstScan] at h; cases h; simpa using entry nonempty
  | cons bucket tail ih =>
    cases capacities with
    | nil => simp [firstScan] at h
    | cons capacity rest =>
      simp only [firstScan] at h
      split at h
      · simp only [pure, Except.pure, bind, Except.bind] at h
        have bound := ih rest (index + 1) candidate (by intro hn; have := entry hn; omega) sentinel h
        simp only [List.length_cons]; omega
      · split at h
        · simp only [pure, Except.pure, bind, Except.bind] at h
          have bound := ih rest (index + 1) { index, allocation := bucket, count := one }
            (by intro _; dsimp; omega) (by simp [one]) h
          simp only [List.length_cons]; omega
        · split at h
          · cases hc : checkedAdd candidate.count one with
            | error e => simp [hc, bind, Except.bind] at h
            | ok count =>
              simp only [hc, pure, Except.pure, bind, Except.bind] at h
              have oldNonzero : candidate.count.val ≠ 0 := by
                intro hz
                have hs := sentinel hz
                have capBound := capacity.isLt
                simp_all [maxWord]
                omega
              have countValue := checkedAdd_value candidate.count one count hc
              have bound := ih rest (index + 1) { candidate with count }
                (by intro _; dsimp; have := entry oldNonzero; omega)
                (by intro hz; dsimp at hz; simp only [one] at countValue; omega) h
              simp only [List.length_cons]; omega
          · simp only [pure, Except.pure, bind, Except.bind] at h
            have bound := ih rest (index + 1) candidate (by intro hn; have := entry hn; omega) sentinel h
            simp only [List.length_cons]; omega

/-- The library's sentinel initialization satisfies the scan invariant. -/
theorem initialScan_index_bound (buckets capacities : List Word) (out : Candidate)
    (h : firstScan buckets capacities 0
      { index := buckets.length, allocation := maxWord, count := zero } = .ok out)
    (nonempty : out.count.val ≠ 0) : out.index < buckets.length := by
  have bound := firstScan_index_bound buckets capacities 0 _ out
    (by simp [zero]) (by intro _; rfl) h nonempty
  simpa using bound

/-- The second scan only lowers its upper level. -/
theorem secondScan_upper_bound (buckets capacities : List Word) (best upper out : Word)
    (h : secondScan buckets capacities best upper = .ok out) : out.val ≤ upper.val := by
  induction buckets generalizing capacities upper with
  | nil => simp [secondScan] at h; cases h; omega
  | cons bucket tail ih =>
    cases capacities with
    | nil => simp [secondScan] at h
    | cons capacity rest =>
      simp only [secondScan] at h
      split at h
      · exact ih rest upper h
      · split at h
        · have bound := ih rest bucket h
          simp_all; omega
        · exact ih rest upper h

end LidoSRv3.Audit.Source.TrioAlloc2
