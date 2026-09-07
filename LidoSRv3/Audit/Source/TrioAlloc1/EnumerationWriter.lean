import LidoSRv3.Audit.Source.TrioAlloc1.ShareWriter

/-!
Physical EnumerableSet insertion used by SRStorage.addModuleId. An existing
position performs no writes; otherwise push updates length and the element,
then the position mapping reads the resulting length. Concrete slot separation
is explicit, so a hash collision is not silently ruled out by the state type.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace EnumerationWriter

open ShareWriter (write modulePositionSlot)

-- SRStorage.sol:76-78
/-- `EnumerableSet._add`, retaining checked dynamic-array length growth. -/
def insert (l : Layout) (s : Storage) (id : Word) : Except Failure Storage :=
  if (s (modulePositionSlot l id)).val ≠ 0 then .ok s
  else if (s (countSlot l)).val ≥ 2^64 then .error (.panic 0x41)
  else
    let size := word ((s (countSlot l)).val+1)
    let lengthWritten := write s (countSlot l) size
    let elementWritten := write lengthWritten (idSlot l (s (countSlot l)).val) id
    .ok (write elementWritten (modulePositionSlot l id) (elementWritten (countSlot l)))

theorem idSlot_injective (l : Layout) (i j : Nat) (hi : i < 2^256) (hj : j < 2^256)
    (equal : idSlot l i = idSlot l j) : i = j := by
  have hbase := (l.keccak (encodeWord (countSlot l))).isLt
  have values := congrArg Fin.val equal
  simp only [idSlot, word] at values
  omega

theorem existing_noop (l : Layout) (s : Storage) (id : Word)
    (present : (s (modulePositionSlot l id)).val ≠ 0) : insert l s id = .ok s := by
  simp [insert, present]

/-- In the admitted domain, derive the successful insertion storage expression. -/
theorem absent_insert (l : Layout) (s : Storage) (id : Word)
    (absent : (s (modulePositionSlot l id)).val = 0)
    (bound : (s (countSlot l)).val < 32) :
    insert l s id = .ok (
      let first := write s (countSlot l) (word ((s (countSlot l)).val+1))
      let second := write first (idSlot l (s (countSlot l)).val) id
      write second (modulePositionSlot l id) (second (countSlot l))) := by
  have safe : ¬ (s (countSlot l)).val ≥ 2^64 := by omega
  simp [insert, absent, safe]

/-- The pinned compiler's storage-array push limit, before any write. -/
theorem oversized_absent (l : Layout) (s : Storage) (id : Word)
    (absent : (s (modulePositionSlot l id)).val = 0)
    (large : (s (countSlot l)).val ≥ 2^64) :
    insert l s id = .error (.panic 0x41) := by
  simp [insert, absent, large]

theorem absent_count (l : Layout) (s after : Storage) (id : Word)
    (absent : (s (modulePositionSlot l id)).val = 0)
    (bound : (s (countSlot l)).val < 32)
    (elementSeparate : countSlot l ≠ idSlot l (s (countSlot l)).val)
    (positionSeparate : countSlot l ≠ modulePositionSlot l id)
    (run : insert l s id = .ok after) :
    (after (countSlot l)).val = (s (countSlot l)).val+1 := by
  rw [absent_insert l s id absent bound] at run
  cases run
  have safe : (s (countSlot l)).val+1 < 2^256 := by omega
  simp [write, positionSeparate, elementSeparate, word, Nat.mod_eq_of_lt safe]

theorem old_element_preserved (l : Layout) (s after : Storage) (id : Word) (i : Nat)
    (bound : (s (countSlot l)).val < 32)
    (inside : i < (s (countSlot l)).val)
    (countSeparate : idSlot l i ≠ countSlot l)
    (positionSeparate : idSlot l i ≠ modulePositionSlot l id)
    (run : insert l s id = .ok after) : after (idSlot l i) = s (idSlot l i) := by
  by_cases present : (s (modulePositionSlot l id)).val ≠ 0
  · rw [existing_noop l s id present] at run
    cases run
    rfl
  · have absent : (s (modulePositionSlot l id)).val = 0 := by omega
    rw [absent_insert l s id absent bound] at run
    cases run
    have different : idSlot l i ≠ idSlot l (s (countSlot l)).val := by
      intro same
      have := idSlot_injective l i (s (countSlot l)).val (by omega) (by omega) same
      omega
    simp [write, positionSeparate, different, countSeparate]

theorem new_element (l : Layout) (s after : Storage) (id : Word)
    (absent : (s (modulePositionSlot l id)).val = 0)
    (bound : (s (countSlot l)).val < 32)
    (separate : idSlot l (s (countSlot l)).val ≠ modulePositionSlot l id)
    (run : insert l s id = .ok after) : after (idSlot l (s (countSlot l)).val) = id := by
  rw [absent_insert l s id absent bound] at run
  cases run
  simp [write, separate]

/-- Reachable enumeration records each enumerated ID's one-based position. -/
def Consistent (l : Layout) (s : Storage) : Prop :=
  ∀ i, i < (s (countSlot l)).val →
    (s (modulePositionSlot l (s (idSlot l i)))).val = i+1

theorem empty_consistent (l : Layout) (s : Storage)
    (empty : (s (countSlot l)).val = 0) : Consistent l s := by
  intro i inside
  omega

theorem absent_not_enumerated (l : Layout) (s : Storage) (id : Word)
    (consistent : Consistent l s)
    (absent : (s (modulePositionSlot l id)).val = 0)
    (i : Nat) (inside : i < (s (countSlot l)).val) : s (idSlot l i) ≠ id := by
  intro equal
  have position := consistent i inside
  rw [equal, absent] at position
  omega

theorem enumerated_ids_unique (l : Layout) (s : Storage)
    (consistent : Consistent l s) (i j : Nat)
    (hi : i < (s (countSlot l)).val) (hj : j < (s (countSlot l)).val)
    (equal : s (idSlot l i) = s (idSlot l j)) : i = j := by
  have pi := consistent i hi
  have pj := consistent j hj
  rw [equal] at pi
  omega

theorem new_position (l : Layout) (s after : Storage) (id : Word)
    (absent : (s (modulePositionSlot l id)).val = 0)
    (bound : (s (countSlot l)).val < 32)
    (separate : countSlot l ≠ idSlot l (s (countSlot l)).val)
    (run : insert l s id = .ok after) :
    (after (modulePositionSlot l id)).val = (s (countSlot l)).val+1 := by
  rw [absent_insert l s id absent bound] at run
  cases run
  have safe : (s (countSlot l)).val+1 < 2^256 := by omega
  simp [write, separate, word, Nat.mod_eq_of_lt safe]

/-- Concrete non-aliasing obligations for the finite set of touched slots. -/
structure InsertSeparation (l : Layout) (s : Storage) (id : Word) : Prop where
  count_element : countSlot l ≠ idSlot l (s (countSlot l)).val
  count_position : countSlot l ≠ modulePositionSlot l id
  element_position : idSlot l (s (countSlot l)).val ≠ modulePositionSlot l id
  old_element_count : ∀ i, i < (s (countSlot l)).val → idSlot l i ≠ countSlot l
  old_element_position : ∀ i, i < (s (countSlot l)).val →
    idSlot l i ≠ modulePositionSlot l id
  old_position_count : ∀ i, i < (s (countSlot l)).val →
    modulePositionSlot l (s (idSlot l i)) ≠ countSlot l
  old_position_element : ∀ i, i < (s (countSlot l)).val →
    modulePositionSlot l (s (idSlot l i)) ≠ idSlot l (s (countSlot l)).val
  old_position_new_position : ∀ i, i < (s (countSlot l)).val →
    modulePositionSlot l (s (idSlot l i)) ≠ modulePositionSlot l id

theorem insertion_preserves_consistency (l : Layout) (s after : Storage) (id : Word)
    (consistent : Consistent l s)
    (bound : (s (countSlot l)).val < 32)
    (separation : InsertSeparation l s id)
    (run : insert l s id = .ok after) : Consistent l after := by
  by_cases present : (s (modulePositionSlot l id)).val ≠ 0
  · rw [existing_noop l s id present] at run
    cases run
    exact consistent
  · have absent : (s (modulePositionSlot l id)).val = 0 := by omega
    have count := absent_count l s after id absent bound
      separation.count_element separation.count_position run
    intro i inside
    by_cases old : i < (s (countSlot l)).val
    · rw [old_element_preserved l s after id i bound old
        (separation.old_element_count i old) (separation.old_element_position i old) run]
      have storage := run
      rw [absent_insert l s id absent bound] at storage
      cases storage
      simpa [write, separation.old_position_count i old,
        separation.old_position_element i old, separation.old_position_new_position i old]
        using consistent i old
    · have last : i = (s (countSlot l)).val := by omega
      subst i
      rw [new_element l s after id absent bound separation.element_position run]
      exact new_position l s after id absent bound separation.count_element run

end EnumerationWriter
end LidoSRv3.Audit.Source.TrioAlloc1
