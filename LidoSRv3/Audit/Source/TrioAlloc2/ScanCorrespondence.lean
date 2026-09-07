import LidoSRv3.Audit.Source.TrioAlloc2.ScanBounds
import LidoSRv3.Audit.Source.TrioAlloc2.Spec

/-! The two source scans refine minima over the independent mathematical rows.
The representation below forgets word widths, preserving each paired row's values.
A surplus capacity suffix is unobserved; short capacities still fail in the source.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc2

def decodedRows (buckets capacities : List Word) : List Spec.Row :=
  List.zipWith (fun b c => ⟨b.val, c.val⟩) buckets capacities

namespace Spec

def openLevels (rows : List Row) : List Nat :=
  (rows.filter (fun r => r.allocation < r.capacity)).map Row.allocation

def higherLevels (rows : List Row) (best : Nat) : List Nat :=
  (openLevels rows).filter (fun level => best < level)

end Spec

/-- The first scan returns the minimum open level, bounded by its entry level. -/
theorem firstScan_minimum (buckets capacities : List Word) (index : Nat)
    (candidate out : Candidate)
    (h : firstScan buckets capacities index candidate = .ok out) :
    out.allocation.val =
      (Spec.openLevels (decodedRows buckets capacities)).foldl Nat.min candidate.allocation.val := by
  induction buckets generalizing capacities index candidate with
  | nil => simp [firstScan] at h; cases h; rfl
  | cons bucket tail ih =>
    cases capacities with
    | nil => simp [firstScan] at h
    | cons capacity rest =>
      simp only [firstScan] at h
      split at h
      · rename_i closed
        simp only [pure, Except.pure, bind, Except.bind] at h
        simpa [decodedRows, Spec.openLevels, Nat.not_lt.mpr closed] using
          ih rest (index + 1) candidate h
      · rename_i opened
        have hopen : bucket.val < capacity.val := by omega
        split at h
        · rename_i lower
          simp only [pure, Except.pure, bind, Except.bind] at h
          simpa [decodedRows, Spec.openLevels, hopen, Nat.min_eq_right (Nat.le_of_lt lower)] using
            ih rest (index + 1) { index, allocation := bucket, count := one } h
        · rename_i notLower
          have hmin : Nat.min candidate.allocation.val bucket.val = candidate.allocation.val := by
            apply Nat.min_eq_left; omega
          split at h
          · cases hc : checkedAdd candidate.count one with
            | error e => simp [hc, bind, Except.bind] at h
            | ok count =>
              simp only [hc, pure, Except.pure, bind, Except.bind] at h
              simpa [decodedRows, Spec.openLevels, hopen, hmin] using
                ih rest (index + 1) { candidate with count } h
          · simp only [pure, Except.pure, bind, Except.bind] at h
            simpa [decodedRows, Spec.openLevels, hopen, hmin] using
              ih rest (index + 1) candidate h

theorem foldl_min_le_entry (levels : List Nat) (entry : Nat) :
    levels.foldl Nat.min entry ≤ entry := by
  induction levels generalizing entry with
  | nil => exact Nat.le_refl _
  | cons level tail ih =>
    exact Nat.le_trans (ih (min entry level)) (Nat.min_le_left _ _)

theorem firstScan_allocation_le (buckets capacities : List Word) (index : Nat)
    (candidate out : Candidate)
    (h : firstScan buckets capacities index candidate = .ok out) :
    out.allocation.val ≤ candidate.allocation.val := by
  rw [firstScan_minimum buckets capacities index candidate out h]
  exact foldl_min_le_entry _ _

/-- The final count is exactly the number of open rows at the final minimum,
plus the incoming count only when the incoming minimum survives. -/
theorem firstScan_tie_count (buckets capacities : List Word) (index : Nat)
    (candidate out : Candidate)
    (h : firstScan buckets capacities index candidate = .ok out) :
    out.count.val =
      (if candidate.allocation.val = out.allocation.val then candidate.count.val else 0) +
      ((Spec.openLevels (decodedRows buckets capacities)).filter
        (fun level => level = out.allocation.val)).length := by
  induction buckets generalizing capacities index candidate with
  | nil => simp [firstScan] at h; cases h; simp [decodedRows, Spec.openLevels]
  | cons bucket tail ih =>
    cases capacities with
    | nil => simp [firstScan] at h
    | cons capacity rest =>
      simp only [firstScan] at h
      split at h
      · rename_i closed
        simp only [pure, Except.pure, bind, Except.bind] at h
        simpa [decodedRows, Spec.openLevels, Nat.not_lt.mpr closed] using
          ih rest (index + 1) candidate h
      · rename_i opened
        have hopen : bucket.val < capacity.val := by omega
        split at h
        · rename_i lower
          simp only [pure, Except.pure, bind, Except.bind] at h
          have bounded := firstScan_allocation_le tail rest (index + 1)
            { index, allocation := bucket, count := one } out h
          dsimp only at bounded
          have oldNotFinal : candidate.allocation.val ≠ out.allocation.val := by omega
          have count := ih rest (index + 1) { index, allocation := bucket, count := one } h
          by_cases eqFinal : bucket.val = out.allocation.val
          · simpa [decodedRows, Spec.openLevels, hopen, eqFinal ▸ hopen, oldNotFinal, eqFinal, one,
              Nat.add_comm] using count
          · simpa [decodedRows, Spec.openLevels, hopen, oldNotFinal, eqFinal, one] using count
        · split at h
          · rename_i same
            cases hc : checkedAdd candidate.count one with
            | error e => simp [hc, bind, Except.bind] at h
            | ok count =>
              simp only [hc, pure, Except.pure, bind, Except.bind] at h
              have value := checkedAdd_value candidate.count one count hc
              have counted := ih rest (index + 1) { candidate with count } h
              dsimp only at counted
              by_cases eqFinal : bucket.val = out.allocation.val
              · simp [decodedRows, Spec.openLevels, eqFinal ▸ hopen, same, eqFinal] at counted ⊢
                simp only [one] at value
                omega
              · simpa [decodedRows, Spec.openLevels, hopen, same, eqFinal] using counted
          · rename_i notSame
            simp only [pure, Except.pure, bind, Except.bind] at h
            have bounded := firstScan_allocation_le tail rest (index + 1) candidate out h
            have different : bucket.val ≠ out.allocation.val := by omega
            simpa [decodedRows, Spec.openLevels, hopen, different] using
              ih rest (index + 1) candidate h

/-- The zero initial count removes any synthetic contribution from the sentinel. -/
theorem initialScan_tie_count (buckets capacities : List Word) (out : Candidate)
    (h : firstScan buckets capacities 0
      { index := buckets.length, allocation := maxWord, count := zero } = .ok out) :
    out.count.val = ((Spec.openLevels (decodedRows buckets capacities)).filter
      (fun level => level = out.allocation.val)).length := by
  have counted := firstScan_tie_count buckets capacities 0 _ out h
  simpa [zero] using counted

/-- A surviving entry wins ties; otherwise the first open row at the final
minimum determines the index. This is a mathematical find over the original order. -/
theorem firstScan_first_index (buckets capacities : List Word) (index : Nat)
    (candidate out : Candidate)
    (h : firstScan buckets capacities index candidate = .ok out) :
    out.index = if candidate.allocation.val = out.allocation.val then candidate.index
      else index + (decodedRows buckets capacities).findIdx
        (fun row => row.allocation < row.capacity && row.allocation = out.allocation.val) := by
  induction buckets generalizing capacities index candidate with
  | nil => simp [firstScan] at h; cases h; simp
  | cons bucket tail ih =>
    cases capacities with
    | nil => simp [firstScan] at h
    | cons capacity rest =>
      simp only [firstScan] at h
      split at h
      · rename_i closed
        simp only [pure, Except.pure, bind, Except.bind] at h
        have indexEq := ih rest (index + 1) candidate h
        by_cases survives : candidate.allocation.val = out.allocation.val
        · simpa [survives] using indexEq
        · simpa [decodedRows, List.findIdx_cons, Nat.not_lt.mpr closed, survives,
            Nat.add_assoc, Nat.add_comm, Nat.add_left_comm] using indexEq
      · rename_i opened
        have hopen : bucket.val < capacity.val := by omega
        split at h
        · rename_i lower
          simp only [pure, Except.pure, bind, Except.bind] at h
          have bounded := firstScan_allocation_le tail rest (index + 1)
            { index, allocation := bucket, count := one } out h
          dsimp only at bounded
          have oldNotFinal : candidate.allocation.val ≠ out.allocation.val := by omega
          have indexEq := ih rest (index + 1) { index, allocation := bucket, count := one } h
          by_cases eqFinal : bucket.val = out.allocation.val
          · simpa [decodedRows, List.findIdx_cons, eqFinal ▸ hopen, oldNotFinal, eqFinal] using indexEq
          · simpa [decodedRows, List.findIdx_cons, hopen, oldNotFinal, eqFinal,
              Nat.add_assoc, Nat.add_comm, Nat.add_left_comm] using indexEq
        · split at h
          · rename_i same
            cases hc : checkedAdd candidate.count one with
            | error e => simp [hc, bind, Except.bind] at h
            | ok count =>
              simp only [hc, pure, Except.pure, bind, Except.bind] at h
              have indexEq := ih rest (index + 1) { candidate with count } h
              by_cases survives : candidate.allocation.val = out.allocation.val
              · simpa [survives] using indexEq
              · have different : bucket.val ≠ out.allocation.val := by omega
                simpa [decodedRows, List.findIdx_cons, hopen, survives, different,
                  Nat.add_assoc, Nat.add_comm, Nat.add_left_comm] using indexEq
          · rename_i notSame
            simp only [pure, Except.pure, bind, Except.bind] at h
            have bounded := firstScan_allocation_le tail rest (index + 1) candidate out h
            have different : bucket.val ≠ out.allocation.val := by omega
            have indexEq := ih rest (index + 1) candidate h
            by_cases survives : candidate.allocation.val = out.allocation.val
            · simpa [survives] using indexEq
            · simpa [decodedRows, List.findIdx_cons, hopen, survives, different,
                Nat.add_assoc, Nat.add_comm, Nat.add_left_comm] using indexEq

theorem initialScan_first_index (buckets capacities : List Word) (out : Candidate)
    (h : firstScan buckets capacities 0
      { index := buckets.length, allocation := maxWord, count := zero } = .ok out)
    (nonempty : out.count.val ≠ 0) :
    out.index = (decodedRows buckets capacities).findIdx
      (fun row => row.allocation < row.capacity && row.allocation = out.allocation.val) := by
  have indexEq := firstScan_first_index buckets capacities 0 _ out h
  have bounded := initialScan_index_bound buckets capacities out h nonempty
  dsimp only at indexEq
  split at indexEq
  · omega
  · simpa using indexEq

/-- The second scan finds the smallest strictly higher open level. -/
theorem secondScan_higher_minimum (buckets capacities : List Word) (best upper out : Word)
    (h : secondScan buckets capacities best upper = .ok out) :
    out.val = (Spec.higherLevels (decodedRows buckets capacities) best.val).foldl Nat.min upper.val := by
  induction buckets generalizing capacities upper with
  | nil => simp [secondScan] at h; cases h; rfl
  | cons bucket tail ih =>
    cases capacities with
    | nil => simp [secondScan] at h
    | cons capacity rest =>
      simp only [secondScan] at h
      split at h
      · rename_i closed
        simpa [decodedRows, Spec.higherLevels, Spec.openLevels, Nat.not_lt.mpr closed] using
          ih rest upper h
      · rename_i opened
        have hopen : bucket.val < capacity.val := by omega
        split at h
        · rename_i between
          have hb : best.val < bucket.val ∧ bucket.val < upper.val := by simpa using between
          simpa [decodedRows, Spec.higherLevels, Spec.openLevels, hopen, hb.1,
            Nat.min_eq_right (Nat.le_of_lt hb.2)] using ih rest bucket h
        · rename_i notBetween
          by_cases higher : best.val < bucket.val
          · have hmin : Nat.min upper.val bucket.val = upper.val := by
              apply Nat.min_eq_left
              simp only [Bool.and_eq_true, decide_eq_true_eq] at notBetween
              omega
            simpa [decodedRows, Spec.higherLevels, Spec.openLevels, hopen, higher, hmin] using
              ih rest upper h
          · simpa [decodedRows, Spec.higherLevels, Spec.openLevels, hopen, higher] using
              ih rest upper h

end LidoSRv3.Audit.Source.TrioAlloc2
