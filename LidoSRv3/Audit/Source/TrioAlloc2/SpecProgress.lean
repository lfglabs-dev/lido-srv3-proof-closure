import LidoSRv3.Audit.Source.TrioAlloc2.Spec

namespace LidoSRv3.Audit.Source.TrioAlloc2.Spec

private theorem fold_min_gt (levels : List Nat) (level entry : Nat)
    (start : level < entry) (allHigher : ∀ n ∈ levels, level < n) :
    level < levels.foldl Nat.min entry := by
  induction levels generalizing entry with
  | nil => exact start
  | cons next tail ih =>
    have hn := allHigher next (by simp)
    apply ih (Nat.min entry next)
    · simp only [Nat.min_eq_min]; omega
    · intro n mem; exact allHigher n (List.mem_cons_of_mem _ mem)

/-- Every choice of the independent specification makes positive progress.
The proof uses the first tied row's open capacity and the strictly higher levels,
not any property of the source executor. -/
theorem choose_positive (rows : List Row) (demand : Nat) (choice : Choice)
    (h : choose rows demand = some choice) : 0 < choice.amount := by
  by_cases hz : demand = 0
  · simp [choose, hz] at h
  · let opened := rows.zipIdx.filter (fun entry => entry.1.allocation < entry.1.capacity)
    have openEq : rows.zipIdx.filter (fun entry => entry.1.allocation < entry.1.capacity) = opened := rfl
    simp only [choose, hz, ↓reduceIte, openEq, bind, Option.bind] at h
    cases hm : minimum (opened.map (fun entry => entry.1.allocation)) with
    | none => simp [hm] at h
    | some level =>
      simp only [hm] at h
      cases hf : (opened.filter (fun entry => entry.1.allocation = level)).head? with
      | none => simp [hf] at h
      | some first =>
        simp only [hf] at h
        cases h
        have tied := List.mem_filter.mp (List.mem_of_head? hf)
        have firstOpen : first.1.allocation < first.1.capacity := by
          have mem := List.mem_filter.mp tied.1
          simpa using mem.2
        have firstLevel : first.1.allocation = level := by simpa using tied.2
        have ceilingGt := fold_min_gt
          ((opened.filter (fun entry => level < entry.1.allocation)).map (fun entry => entry.1.allocation))
          level first.1.capacity (by omega) (by
            intro n mem
            obtain ⟨entry, member, rfl⟩ := List.mem_map.mp mem
            have greater := List.mem_filter.mp member
            simpa using greater.2)
        have tiesPos : 0 < (opened.filter (fun entry => entry.1.allocation = level)).length :=
          List.length_pos_iff_exists_mem.mpr ⟨first, List.mem_of_head? hf⟩
        have sharePos := Nat.div_pos
          (show (opened.filter (fun entry => entry.1.allocation = level)).length ≤
            demand + (opened.filter (fun entry => entry.1.allocation = level)).length - 1 by omega) tiesPos
        dsimp only
        omega

end LidoSRv3.Audit.Source.TrioAlloc2.Spec
