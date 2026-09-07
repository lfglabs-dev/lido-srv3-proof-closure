import Lean.Elab.Tactic.Omega

/-! Independent frame specification. Euclidean quotient intervals select the
slot, epoch and reporting-frame index. The emitted reference/deadline slots are
the source's explicit uint64 projections, not an assumed untruncated pair. -/
namespace LidoSRv3.Audit.Source.TrioReserve1.FrameSpec

def Quotient (n d q : Nat) : Prop :=
  0 < d ∧ q * d ≤ n ∧ n < (q + 1) * d

theorem quotient_of_div (n d : Nat) (h : d ≠ 0) : Quotient n d (n / d) := by
  refine ⟨by omega, Nat.div_mul_le_self n d, ?_⟩
  simpa [Nat.mul_comm] using Nat.lt_mul_div_succ n (by omega : 0 < d)

theorem quotient_unique (n d a b : Nat) (ha : Quotient n d a) (hb : Quotient n d b) : a = b := by
  rcases ha with ⟨_, haLo, haHi⟩
  rcases hb with ⟨_, hbLo, hbHi⟩
  have hab : a ≤ b := by
    by_cases h : a ≤ b
    · exact h
    · have hm := Nat.mul_le_mul_right d (by omega : b + 1 ≤ a)
      omega
  have hba : b ≤ a := by
    by_cases h : b ≤ a
    · exact h
    · have hm := Nat.mul_le_mul_right d (by omega : a + 1 ≤ b)
      omega
  omega

def Describes (time genesis seconds slots initial epochs reference deadline : Nat) : Prop :=
  ∃ slot epoch index,
    genesis ≤ time ∧ Quotient (time - genesis) seconds slot ∧
    Quotient slot slots epoch ∧ initial ≤ epoch ∧
    Quotient (epoch - initial) epochs index ∧
    epochs * slots < 2^64 ∧
    let start := (initial + index * epochs) * slots
    let next := start + epochs * slots
    0 < start ∧ next < 2^256 ∧
    reference = (start - 1) % 2^64 ∧ deadline = (next - 1) % 2^64

theorem unique (time genesis seconds slots initial epochs r1 d1 r2 d2 : Nat)
    (h1 : Describes time genesis seconds slots initial epochs r1 d1)
    (h2 : Describes time genesis seconds slots initial epochs r2 d2) : r1 = r2 ∧ d1 = d2 := by
  rcases h1 with ⟨s1, e1, i1, _, hs1, he1, _, hi1, _, _, _, hr1, hd1⟩
  rcases h2 with ⟨s2, e2, i2, _, hs2, he2, _, hi2, _, _, _, hr2, hd2⟩
  have hs := quotient_unique _ _ _ _ hs1 hs2
  subst s2
  have he := quotient_unique _ _ _ _ he1 he2
  subst e2
  have hi := quotient_unique _ _ _ _ hi1 hi2
  subst i2
  exact ⟨hr1.trans hr2.symm, hd1.trans hd2.symm⟩

end LidoSRv3.Audit.Source.TrioReserve1.FrameSpec
