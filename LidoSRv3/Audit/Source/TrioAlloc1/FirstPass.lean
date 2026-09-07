import LidoSRv3.Audit.Source.TrioAlloc1.CapacitySpec

/-!
First-pass arithmetic contracts. These characterize ceiling by its least-integer
property and active count by conservation, rather than restating the formulas.
External summary/stake values remain arbitrary uint256 values.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1

/-- The smallest validator-equivalent count whose balance covers the stake. -/
def Ceiling (stake divisor count : Nat) : Prop :=
  stake ≤ count*divisor ∧ ∀ smaller, stake ≤ smaller*divisor → count ≤ smaller

/-- Every nonzero divisor succeeds; no reachable-router arithmetic premise is needed. -/
theorem checkedCeilDiv_nonzero (stake divisor : Word) (positive : divisor.val ≠ 0) :
    ∃ count, checkedCeilDiv stake divisor = .ok count ∧
      Ceiling stake.val divisor.val count.val := by
  have divisorPos : 0 < divisor.val := by omega
  by_cases zero : stake.val = 0
  · refine ⟨word 0, ?_, ?_⟩
    · simp [checkedCeilDiv, positive, zero]
    · simp [Ceiling, zero, word]
  · let n := (stake.val-1)/divisor.val+1
    have leStake : n ≤ stake.val := by
      have hd := Nat.div_le_self (stake.val-1) divisor.val
      dsimp [n]
      omega
    have bound : n < 2^256 := Nat.lt_of_le_of_lt leStake stake.isLt
    let count : Word := ⟨n, bound⟩
    refine ⟨count, ?_, ?_⟩
    · simp [checkedCeilDiv, positive, zero, checked, n, count, bound]
    · change Ceiling stake.val divisor.val n
      constructor
      · have hdiv : (stake.val-1)/divisor.val < n := by dsimp [n]; omega
        have cover := (Nat.div_lt_iff_lt_mul divisorPos).mp hdiv
        omega
      · intro smaller covers
        have hlt : stake.val-1 < smaller*divisor.val := by omega
        have lower := (Nat.div_lt_iff_lt_mul divisorPos).mpr hlt
        dsimp [n]
        omega

/-- All outcomes of stake conversion, including 0/0, are specified. -/
theorem checkedCeilDiv_all_outcomes (stake divisor : Word) :
    (divisor.val = 0 ∧ checkedCeilDiv stake divisor = .error (.panic (word 0x12))) ∨
    (divisor.val ≠ 0 ∧ ∃ count, checkedCeilDiv stake divisor = .ok count ∧
      Ceiling stake.val divisor.val count.val) := by
  by_cases zero : divisor.val = 0
  · exact Or.inl ⟨zero, by simp [checkedCeilDiv, zero]⟩
  · exact Or.inr ⟨zero, checkedCeilDiv_nonzero stake divisor zero⟩

/-- Checked active-count subtraction fails exactly on inconsistent exited counts. -/
theorem checkedSub_word_all_outcomes (deposited : Word) (exited : Nat) :
    (deposited.val < exited ∧ checkedSub deposited.val exited = .error (.panic (word 0x11))) ∨
    (∃ active, checkedSub deposited.val exited = .ok active ∧
      active.val + exited = deposited.val) := by
  by_cases valid : exited ≤ deposited.val
  · have bound : deposited.val-exited < 2^256 :=
      Nat.lt_of_le_of_lt (Nat.sub_le _ _) deposited.isLt
    let active : Word := ⟨deposited.val-exited, bound⟩
    apply Or.inr
    refine ⟨active, ?_, ?_⟩
    · simp [checkedSub, valid, checked, bound, active]
    · dsimp [active]
      omega
  · exact Or.inl ⟨by omega, by simp [checkedSub, valid]⟩

/-- A successful subtraction establishes consistency, not merely saturated Nat subtraction. -/
theorem checkedSub_word_success (deposited : Word) (exited : Nat) (active : Word)
    (h : checkedSub deposited.val exited = .ok active) :
    active.val + exited = deposited.val := by
  rcases checkedSub_word_all_outcomes deposited exited with ⟨_, error⟩ | ⟨value, success, equation⟩
  · rw [error] at h
    cases h
  · rw [success] at h
    cases h
    exact equation

/-- Live first-pass active count is conserved against both decoded and stored exits. -/
theorem firstRow_active_count (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (i : Nat) (total : Word) (before after : Transcript)
    (row : CachedRow) (next : Word)
    (h : firstRow l s oracle input i total before = (.ok (row, next), after)) :
    row.active.val + max row.summary.exited.val row.stored.accountingExited.val =
      row.summary.deposited.val := by
  unfold firstRow at h
  simp only [bind, pure] at h
  split at h
  · simp [failExec] at h
  · repeat first
      | (split at h)
      | (simp only [bindExec, pureExec, liftChecked] at h)
      | (simp at h)
      | (obtain ⟨⟨rfl, rfl⟩, _⟩ := h
         exact checkedSub_word_success _ _ _
           (congrArg Prod.fst ‹(checkedSub _ _, _) = (Except.ok _, _)›))

end LidoSRv3.Audit.Source.TrioAlloc1
