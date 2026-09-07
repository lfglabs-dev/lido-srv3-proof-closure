import LidoSRv3.Audit.Source.TrioAlloc2.Step

namespace LidoSRv3.Audit.Source.TrioAlloc2

/-- All scan/arithmetic failures remain executable outcomes. These conclusions
require only the observed successful result, not independent success assumptions. -/
theorem step_invariants (buckets capacities : List Word) (demand : Word)
    (out : StepOutput) (h : step buckets capacities demand = .ok out) :
    out.amount.val ≤ demand.val ∧ out.buckets.length = buckets.length := by
  by_cases hz : demand.val = 0
  · simp [step, hz, pure, Except.pure] at h
    cases h
    exact ⟨Nat.zero_le _, rfl⟩
  · cases hf : firstScan buckets capacities 0
        { index := buckets.length, allocation := maxWord, count := zero } with
    | error e => simp [step, hz, hf, bind, Except.bind, pure, Except.pure] at h
    | ok candidate =>
      by_cases hc : candidate.count.val = 0
      · simp [step, hz, hf, hc, bind, Except.bind, pure, Except.pure] at h
        cases h
        exact ⟨Nat.zero_le _, rfl⟩
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
              simp only [hceil] at h
              have bound := ceilDiv_le_numerator demand candidate.count share hceil
              repeat' split at h
              all_goals cases h
              all_goals exact ⟨Nat.le_trans (minWord_le_left _ _) bound, by simp⟩
          · simp only [hcount, ↓reduceIte] at h
            repeat' split at h
            all_goals cases h
            all_goals exact ⟨minWord_le_left _ _, by simp⟩

theorem step_amount_le_demand (buckets capacities : List Word) (demand : Word)
    (out : StepOutput) (h : step buckets capacities demand = .ok out) :
    out.amount.val ≤ demand.val :=
  (step_invariants buckets capacities demand out h).1

theorem step_preserves_length (buckets capacities : List Word) (demand : Word)
    (out : StepOutput) (h : step buckets capacities demand = .ok out) :
    out.buckets.length = buckets.length :=
  (step_invariants buckets capacities demand out h).2

end LidoSRv3.Audit.Source.TrioAlloc2
