import LidoSRv3.Audit.Source.TrioAlloc1.Execution

/-!
Pinned solc 0.8.25 via-IR allocation primitives observed in the capacity harness.
These are explicit machine-word operations, including panic 0x41. They do not
silently constrain the physical module count to 32. Integration of the complete
compiler allocation schedule with the producer remains a separate obligation.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace AllocationMemory

def limit : Nat := 2^64-1

def arraySize (count : Word) : Except Failure Word :=
  if count.val > limit then .error (.panic (word 0x41))
  else .ok (word (32*count.val+32))

/-- `and(add(size,31),not(31))`, including uint256 wrap before rounding. -/
def roundedSize (size : Word) : Nat := ((size.val+31) % 2^256) / 32 * 32

def finalize (pointer size : Word) : Except Failure Word :=
  let next := word (pointer.val+roundedSize size)
  if next.val > limit ∨ next.val < pointer.val then .error (.panic (word 0x41))
  else .ok next

def allocateArray (pointer count : Word) : Except Failure Word := do
  let size ← arraySize count
  finalize pointer size

theorem arraySize_oversized (count : Word) (h : count.val > limit) :
    arraySize count = .error (.panic (word 0x41)) := by simp [arraySize, h]

theorem finalize_success_bounds (pointer size next : Word)
    (h : finalize pointer size = .ok next) :
    pointer.val ≤ next.val ∧ next.val ≤ limit := by
  dsimp only [finalize] at h
  split at h
  · cases h
  · cases h
    omega

theorem bounded_array_allocates (pointer count : Word)
    (hp : pointer.val ≤ 2^32) (hc : count.val ≤ 32) :
    allocateArray pointer count = .ok (word (pointer.val+32*count.val+32)) := by
  have bound : ¬ count.val > limit := by unfold limit; omega
  have sizeBound : 32*count.val+32 < 2^256 := by omega
  have roundedBound : 32*count.val+32+31 < 2^256 := by omega
  have rounded : roundedSize (word (32*count.val+32)) = 32*count.val+32 := by
    simp only [roundedSize, word, Nat.mod_eq_of_lt sizeBound, Nat.mod_eq_of_lt roundedBound]
    omega
  simp only [allocateArray, arraySize, if_neg bound]
  change finalize pointer (word (32*count.val+32)) = _
  have nextBound : pointer.val+(32*count.val+32) < 2^256 := by omega
  simp only [finalize]
  rw [rounded]
  have noFail : ¬ ((word (pointer.val + (32*count.val+32))).val > limit ∨
      (word (pointer.val + (32*count.val+32))).val < pointer.val) := by
    simp only [word, Nat.mod_eq_of_lt nextBound]
    unfold limit
    omega
  rw [if_neg noFail]
  exact congrArg Except.ok (congrArg word (Nat.add_assoc _ _ _).symm)


end AllocationMemory
end LidoSRv3.Audit.Source.TrioAlloc1
