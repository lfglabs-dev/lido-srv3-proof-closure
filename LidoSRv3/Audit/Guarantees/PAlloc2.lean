import LidoSRv3.Audit.StrategyProofs
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAlloc2

def guarantee : Guarantee := ⟨.pAlloc2, [.algorithm]⟩

/--
The executable MinFirst control rule selects an open bucket with no larger
allocation than any other open input bucket. This is an ALG theorem for the
handwritten `Nat` model; Solidity and EVM refinement remain open.
-/
theorem selects_least_open_bucket
    (h : MinFirst.candidate? rows = some selected)
    (hOther : other ∈ rows) (hOpen : other.open = true) :
    selected.allocation ≤ other.allocation := by
  induction rows generalizing selected other with
  | nil => simp at hOther
  | cons bucket rows ih =>
      cases hCandidate : MinFirst.candidate? rows with
      | none =>
          have hBucket : bucket.open = true := by
            by_cases hOpenBucket : bucket.open = true
            · exact hOpenBucket
            · simp [MinFirst.candidate?, hCandidate, hOpenBucket] at h
          have hSelected : bucket = selected := by
            simpa [MinFirst.candidate?, hCandidate, hBucket] using h
          subst bucket
          simp only [List.mem_cons] at hOther
          rcases hOther with rfl | hOther
          · exact Nat.le_refl _
          · have hNoOpen := MinFirst.candidate_none_no_open hCandidate hOther
            simp_all
      | some later =>
          by_cases hBucket : bucket.open = true ∧
              bucket.allocation ≤ later.allocation
          · have hSelected : bucket = selected := by
              simpa [MinFirst.candidate?, hCandidate, hBucket] using h
            subst bucket
            simp only [List.mem_cons] at hOther
            rcases hOther with rfl | hOther
            · exact Nat.le_refl _
            · exact Nat.le_trans hBucket.2 (ih hCandidate hOther hOpen)
          · have hSelected : later = selected := by
              simpa [MinFirst.candidate?, hCandidate, hBucket] using h
            subst later
            simp only [List.mem_cons] at hOther
            rcases hOther with rfl | hOther
            · have hLaterOpen := MinFirst.candidate_open hCandidate
              have hNotLe : ¬ other.allocation ≤ selected.allocation := by
                intro hLe
                apply hBucket
                exact ⟨hOpen, hLe⟩
              omega
            · exact ih hCandidate hOther hOpen

end LidoSRv3.Audit.Guarantees.PAlloc2
