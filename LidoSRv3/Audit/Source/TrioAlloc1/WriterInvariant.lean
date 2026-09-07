import LidoSRv3.Audit.Source.TrioAlloc1.ShareWriter

/-!
Physical enumeration invariants and their preservation by the public share writer.
The separation premises concern concrete storage slots, not address uniqueness or
share bounds. They are exposed for the eventual deployment/finite-layout relation.
All-writer reachability additionally requires admission and migration transitions.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace WriterInvariant

def Holds (l : Layout) (s : Storage) : Prop :=
  (s (countSlot l)).val ≤ 32 ∧
  (∀ i, i < (s (countSlot l)).val → (readModule l s i).share.val ≤ 10000) ∧
  (∀ i j, i < (s (countSlot l)).val → j < (s (countSlot l)).val →
    (readModule l s i).identity.moduleAddress = (readModule l s j).identity.moduleAddress → i = j)

theorem empty (l : Layout) (s : Storage) (h : (s (countSlot l)).val = 0) : Holds l s := by
  simp [Holds, h]

theorem replacement_address (original : Word) (share threshold : Fin (2^16)) :
    field (ShareWriter.replaceShares original share threshold) 0 160 = field original 0 160 := by
  have ho := original.isLt
  have hs := share.isLt
  have ht := threshold.isLt
  simp only [ShareWriter.replaceShares, field, word]
  omega

/-- Updating the packed share fields does not change the physical identity read. -/
theorem identity_preserved (l : Layout) (s : Storage) (input : ShareWriter.Input) (i : Nat)
    (separate : idSlot l i ≠ moduleSlot l input.moduleId) :
    (readModule l (ShareWriter.execute l s input).storage i).identity = (readModule l s i).identity := by
  rcases ShareWriter.execute_cases l s input with ⟨reason, rejected⟩ | success
  · rw [rejected]
    rfl
  · rw [ShareWriter.execute_success_storage l s input success]
    have ids : ShareWriter.write s (moduleSlot l input.moduleId)
        (ShareWriter.replaceShares (s (moduleSlot l input.moduleId)) input.share input.threshold)
        (idSlot l i) = s (idSlot l i) := if_neg separate
    simp only [readModule, ids]
    by_cases same : moduleSlot l (s (idSlot l i)) = moduleSlot l input.moduleId
    · simp only [ShareWriter.write, same, ite_true, replacement_address]
    · simp only [ShareWriter.write, if_neg same]

theorem share_preserved_or_bounded (l : Layout) (s : Storage) (input : ShareWriter.Input) (i : Nat)
    (separate : idSlot l i ≠ moduleSlot l input.moduleId)
    (before : (readModule l s i).share.val ≤ 10000) :
    (readModule l (ShareWriter.execute l s input).storage i).share.val ≤ 10000 := by
  rcases ShareWriter.execute_cases l s input with ⟨reason, rejected⟩ | success
  · rw [rejected]
    exact before
  · rw [ShareWriter.execute_success_storage l s input success]
    have ids : ShareWriter.write s (moduleSlot l input.moduleId)
        (ShareWriter.replaceShares (s (moduleSlot l input.moduleId)) input.share input.threshold)
        (idSlot l i) = s (idSlot l i) := if_neg separate
    simp only [readModule, ids]
    by_cases same : moduleSlot l (s (idSlot l i)) = moduleSlot l input.moduleId
    · simp only [ShareWriter.write, same, ite_true, ShareWriter.replaceShares_share]
      exact (ShareWriter.execute_derives_admission_and_bounds l s input success).2.2.1
    · simpa only [readModule, ShareWriter.write, if_neg same] using before

theorem share_writer_preserves (l : Layout) (s : Storage) (input : ShareWriter.Input)
    (before : Holds l s)
    (countSeparate : countSlot l ≠ moduleSlot l input.moduleId)
    (idsSeparate : ∀ i, i < (s (countSlot l)).val → idSlot l i ≠ moduleSlot l input.moduleId) :
    Holds l (ShareWriter.execute l s input).storage := by
  have count := ShareWriter.execute_other_slot_preserved l s input (countSlot l) countSeparate
  rcases before with ⟨bound, shares, unique⟩
  refine ⟨?_, ?_, ?_⟩
  · simpa only [count] using bound
  · intro i hi
    rw [count] at hi
    exact share_preserved_or_bounded l s input i (idsSeparate i hi) (shares i hi)
  · intro i j hi hj equal
    rw [count] at hi hj
    have left := identity_preserved l s input i (idsSeparate i hi)
    have right := identity_preserved l s input j (idsSeparate j hj)
    rw [left, right] at equal
    exact unique i j hi hj equal

end WriterInvariant
end LidoSRv3.Audit.Source.TrioAlloc1
