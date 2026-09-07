import LidoSRv3.Audit.Source.TrioAlloc2.Totality

/-! Relate the original independent `Spec.choose` expression, including indexed
filtering and its capacity-seeded ceiling, to the two source scans. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2

private def indexedOpen (rows : List Spec.Row) : List (Spec.Row × Nat) :=
  rows.zipIdx.filter (fun entry => entry.1.allocation < entry.1.capacity)

private theorem indexedOpen_rows (rows : List Spec.Row) :
    (indexedOpen rows).map Prod.fst = rows.filter (fun row => row.allocation < row.capacity) := by
  have eq := List.filter_map (l := rows.zipIdx) (f := Prod.fst)
    (p := fun row : Spec.Row => row.allocation < row.capacity)
  simpa [indexedOpen, Function.comp_def] using eq.symm

private theorem indexedOpen_levels (rows : List Spec.Row) :
    (indexedOpen rows).map (fun entry => entry.1.allocation) = Spec.openLevels rows := by
  have eq := congrArg (List.map Spec.Row.allocation) (indexedOpen_rows rows)
  simpa [Spec.openLevels, List.map_map, Function.comp_def] using eq

private theorem indexedOpen_ties (rows : List Spec.Row) (level : Nat) :
    ((indexedOpen rows).filter (fun entry => entry.1.allocation = level)).length =
      ((Spec.openLevels rows).filter (fun n => n = level)).length := by
  rw [← indexedOpen_levels rows, List.filter_map]
  simp [Function.comp_def]

private theorem indexedOpen_higher (rows : List Spec.Row) (level : Nat) :
    ((indexedOpen rows).filter (fun entry => level < entry.1.allocation)).map
      (fun entry => entry.1.allocation) = Spec.higherLevels rows level := by
  rw [Spec.higherLevels, ← indexedOpen_levels rows, List.filter_map]
  rfl

private theorem indexed_find (rows : List Spec.Row) (p : Spec.Row → Bool) :
    (rows.zipIdx.find? (fun entry => p entry.1)) =
      rows[rows.findIdx p]?.map (fun row => (row, rows.findIdx p)) := by
  have index : rows.zipIdx.findIdx (fun entry => p entry.1) = rows.findIdx p := by
    simpa [Function.comp_def] using (List.findIdx_map rows.zipIdx Prod.fst p).symm
  rw [List.find?_eq_getElem?_findIdx, index, List.getElem?_zipIdx]
  simp

private theorem indexedOpen_first (rows : List Spec.Row) (level : Nat) :
    ((indexedOpen rows).filter (fun entry => entry.1.allocation = level)).head? =
      rows[rows.findIdx (fun row => row.allocation < row.capacity && row.allocation = level)]?.map
        (fun row => (row, rows.findIdx (fun row => row.allocation < row.capacity && row.allocation = level))) := by
  simpa [indexedOpen, List.filter_filter, Bool.and_comm] using
    indexed_find rows (fun row => row.allocation < row.capacity && row.allocation = level)

private theorem foldl_min_right (levels : List Nat) (a b : Nat) :
    levels.foldl Nat.min (min a b) = min (levels.foldl Nat.min a) b := by
  induction levels generalizing a b with
  | nil => rfl
  | cons level tail ih =>
    simp only [List.foldl_cons, Nat.min_eq_min]
    rw [Nat.min_assoc, Nat.min_comm b level, ← Nat.min_assoc]
    exact ih _ _

/-- The independent choice uses exactly the scan index, tie count, and upper
level. The row values here are actual indexed reads, not a chosen-row premise. -/
theorem choose_of_scans (buckets capacities : List Word) (demand : Word)
    (candidate : Candidate) (upper bucket capacity : Word)
    (positive : demand.val ≠ 0) (nonempty : candidate.count.val ≠ 0)
    (scanned : firstScan buckets capacities 0
      { index := buckets.length, allocation := maxWord, count := zero } = .ok candidate)
    (higher : secondScan buckets capacities candidate.allocation maxWord = .ok upper)
    (bucketRead : buckets[candidate.index]? = some bucket)
    (capacityRead : capacities[candidate.index]? = some capacity) :
    Spec.choose (decodedRows buckets capacities) demand.val =
      some ⟨candidate.index, min ((demand.val + candidate.count.val - 1) / candidate.count.val)
        (min upper.val capacity.val - candidate.allocation.val)⟩ := by
  let rows := decodedRows buckets capacities
  have minimumEq := initialScan_minimum_option buckets capacities candidate scanned
  simp only [nonempty, ↓reduceIte] at minimumEq
  change Spec.minimum (Spec.openLevels rows) = some candidate.allocation.val at minimumEq
  have countEq := (indexedOpen_ties rows candidate.allocation.val).trans
    (initialScan_tie_count buckets capacities candidate scanned).symm
  have indexEq := initialScan_first_index buckets capacities candidate scanned nonempty
  have firstEq : ((indexedOpen rows).filter
      (fun entry => entry.1.allocation = candidate.allocation.val)).head? =
      some (Spec.Row.mk bucket.val capacity.val, candidate.index) := by
    rw [indexedOpen_first, ← indexEq]
    simp [rows, decodedRows, List.getElem?_zipWith, bucketRead, capacityRead]
  have upperEq := secondScan_higher_minimum buckets capacities candidate.allocation maxWord upper higher
  have capMax : capacity.val ≤ maxWord.val := by
    have := capacity.isLt
    simp only [maxWord]
    omega
  have ceilingEq : (Spec.higherLevels rows candidate.allocation.val).foldl Nat.min capacity.val =
      min upper.val capacity.val := by
    rw [upperEq, ← foldl_min_right, Nat.min_eq_right capMax]
  have openEq : rows.zipIdx.filter (fun entry => entry.1.allocation < entry.1.capacity) =
      indexedOpen rows := rfl
  change Spec.choose rows demand.val = _
  simp only [Spec.choose, positive, ↓reduceIte, openEq, indexedOpen_levels, minimumEq,
    bind, Option.bind]
  simp only [firstEq, countEq, indexedOpen_higher, ceilingEq]

theorem choose_none_of_scan (buckets capacities : List Word) (demand : Word)
    (candidate : Candidate)
    (scanned : firstScan buckets capacities 0
      { index := buckets.length, allocation := maxWord, count := zero } = .ok candidate)
    (empty : candidate.count.val = 0) :
    Spec.choose (decodedRows buckets capacities) demand.val = none := by
  have minimumEq := initialScan_minimum_option buckets capacities candidate scanned
  simp only [empty, ↓reduceIte] at minimumEq
  by_cases hz : demand.val = 0
  · simp [Spec.choose, hz]
  · have openEq : (decodedRows buckets capacities).zipIdx.filter
        (fun entry => entry.1.allocation < entry.1.capacity) =
        indexedOpen (decodedRows buckets capacities) := rfl
    simp only [Spec.choose, hz, ↓reduceIte, openEq, indexedOpen_levels, minimumEq,
      bind, Option.bind]

end LidoSRv3.Audit.Source.TrioAlloc2
