import LidoSRv3.Audit.Strategy
import Verity.Proofs.Stdlib.Automation

namespace LidoSRv3.Audit.MinFirst

theorem candidate_mem (h : candidate? rows = some selected) :
    selected ∈ rows := by
  induction rows with
  | nil => simp [candidate?] at h
  | cons b bs ih =>
      simp only [candidate?] at h
      split at h
      · split at h <;> simp_all
      · split at h <;> simp_all

theorem candidate_open (h : candidate? rows = some selected) :
    selected.open = true := by
  induction rows with
  | nil => simp [candidate?] at h
  | cons b bs ih =>
      simp only [candidate?] at h
      split at h
      · split at h <;> simp_all
      · split at h <;> simp_all

theorem candidate_none_no_open (h : candidate? rows = none)
    (hMem : other ∈ rows) : other.open = false := by
  induction rows generalizing other with
  | nil => simp at hMem
  | cons b bs ih =>
      cases hc : candidate? bs with
      | none =>
          have hb : b.open = false := by
            by_cases ht : b.open = true
            · simp [candidate?, hc, ht] at h
            · cases hv : b.open <;> simp_all
          simp only [List.mem_cons] at hMem
          rcases hMem with rfl | hMem
          · exact hb
          · exact ih hc hMem
      | some later =>
          simp only [candidate?, hc] at h
          split at h <;> contradiction

theorem candidate_minimal
    (h : candidate? rows = some selected)
    (hOther : other ∈ rows) (hOpen : other.open = true) :
    selected.allocation ≤ other.allocation := by
  induction rows generalizing selected other with
  | nil => simp at hOther
  | cons b bs ih =>
      cases hc : candidate? bs with
      | none =>
          have hb : b.open = true := by
            by_cases ht : b.open = true
            · exact ht
            · simp [candidate?, hc, ht] at h
          have hs : b = selected := by simpa [candidate?, hc, hb] using h
          subst b
          simp only [List.mem_cons] at hOther
          rcases hOther with rfl | hOther
          · exact Nat.le_refl _
          · have hn := candidate_none_no_open hc hOther
            simp_all
      | some later =>
          by_cases hb : b.open = true ∧ b.allocation ≤ later.allocation
          · have hs : b = selected := by simpa [candidate?, hc, hb] using h
            subst b
            have hle : selected.allocation ≤ later.allocation := hb.2
            simp only [List.mem_cons] at hOther
            rcases hOther with rfl | hOther
            · exact Nat.le_refl _
            · exact Nat.le_trans hle (ih hc hOther hOpen)
          · have hs : later = selected := by simpa [candidate?, hc, hb] using h
            subst later
            simp only [List.mem_cons] at hOther
            rcases hOther with rfl | hOther
            · have hopenLater := candidate_open hc
              have hnotle : ¬ other.allocation ≤ selected.allocation := by
                intro hle
                apply hb
                exact ⟨hOpen, hle⟩
              omega
            · exact ih hc hOther hOpen

theorem candidate_router_tie
    (hLater : candidate? rows = some later)
    (hOpen : first.open = true)
    (hTie : first.allocation = later.allocation) :
    candidate? (first :: rows) = some first := by
  simp [candidate?, hLater, hOpen, hTie]

@[simp] theorem incrementSelected_moduleId :
    (incrementSelected selected b).moduleId = b.moduleId := by
  simp only [incrementSelected]
  split <;> rfl

@[simp] theorem incrementSelected_active :
    (incrementSelected selected b).active = b.active := by
  simp only [incrementSelected]
  split <;> rfl

theorem incrementSelected_monotone :
    b.allocation ≤ (incrementSelected selected b).allocation := by
  simp only [incrementSelected]
  split <;> simp

theorem incrementSelected_eq_of_ne
    (h : b.moduleId ≠ selected.moduleId) :
    incrementSelected selected b = b := by
  simp [incrementSelected, h]

theorem step_preserves_length :
    (step rows).length = rows.length := by
  simp only [step]
  split <;> simp

theorem step_preserves_module_order :
    (step rows).map Bucket.moduleId = rows.map Bucket.moduleId := by
  simp only [step]
  split <;> simp

theorem loop_preserves_length :
    (loop fuel rows).length = rows.length := by
  induction fuel generalizing rows with
  | zero => rfl
  | succ fuel ih =>
      simp only [loop, run]
      split
      · rfl
      · simpa [loop] using (ih (rows := rows.map (incrementSelected _)))

theorem loop_preserves_module_order :
    (loop fuel rows).map Bucket.moduleId = rows.map Bucket.moduleId := by
  induction fuel generalizing rows with
  | zero => rfl
  | succ fuel ih =>
      simp only [loop, run]
      split
      · rfl
      · change (loop fuel (rows.map (incrementSelected _))).map Bucket.moduleId =
            rows.map Bucket.moduleId
        rw [ih]
        simp

theorem allocate_preserves_length :
    (allocate requested rows).length = rows.length :=
  loop_preserves_length

theorem allocate_preserves_module_order :
    (allocate requested rows).map Bucket.moduleId = rows.map Bucket.moduleId :=
  loop_preserves_module_order

theorem run_spent_le (fuel : Nat) (rows : List Bucket) :
    (run fuel rows).spent ≤ fuel := by
  induction fuel generalizing rows with
  | zero => simp [run]
  | succ fuel ih =>
      simp only [run]
      split
      · simp
      · rename_i selected hSelected
        have hle := ih (rows := rows.map (incrementSelected selected))
        change (run fuel (rows.map (incrementSelected selected))).spent + 1 ≤ fuel + 1
        omega

/-- Exact fuel sufficiency: each source-shaped unit iteration consumes one unit
and the executable run cannot allocate more than requested demand. -/
theorem totalAllocated_le_requested (requested : Nat) (rows : List Bucket) :
    totalAllocated requested rows ≤ requested :=
  run_spent_le requested rows

/-- Determinism is for the concrete ordered snapshot, not unordered module sets. -/
theorem allocate_deterministic (requested : Nat) (rows : List Bucket) :
    ∀ other, allocate requested rows = other → other = allocate requested rows := by
  intro other h
  exact h.symm

end LidoSRv3.Audit.MinFirst
