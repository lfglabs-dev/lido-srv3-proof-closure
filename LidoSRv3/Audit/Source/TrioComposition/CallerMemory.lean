import LidoSRv3.Audit.Source.TrioComposition.ParentCalls
import LidoSRv3.Audit.Source.TrioComposition.RowMemory

/-! Caller allocations in the pinned SRLib optimized IR: the zero-demand array
precedes conversion; a successful canonical library reply is finalized before
allocating its decoded array. Canonical return shape is an explicit boundary:
this module does not replace arbitrary-byte decoding or prove physical copies. -/
namespace LidoSRv3.Audit.Source.TrioComposition.CallerMemory
open TrioAlloc1

/-- Allocate the zero-demand result before running any conversion arithmetic. -/
def zero (pointer count : Word) (config : Config) (produced : CapacityOutput) :
    CallTree.Program ParentOutput := do
  let _ ← CallTree.check (AllocationMemory.allocateArray pointer count)
  let (deltas, totals) ← CallTree.check
    (convertZero config.maxEBType1 count.val produced.allocations)
  pure ⟨word 0, deltas, totals⟩

theorem zero_exact (pointer count : Word) (config : Config) (produced : CapacityOutput)
    (hp : pointer.val ≤ 2^32) (hc : count.val ≤ 32) :
    zero pointer count config produced =
      ParentCalls.afterProducer count.val config (word 0) produced := by
  simp [zero, AllocationMemory.bounded_array_allocates pointer count hp hc,
    RowMemory.check_ok_bind, ParentCalls.afterProducer, word]

theorem zero_allocation_failure (pointer count : Word) (config : Config)
    (produced : CapacityOutput) (reason : Failure)
    (failed : AllocationMemory.allocateArray pointer count = .error reason) :
    zero pointer count config produced = .done (.error reason) := by
  simp [zero, failed, CallTree.check, bind, CallTree.bind]

/-- The pinned library's canonical tuple occupies 96+32*n bytes. The caller
then allocates a separate 32+32*n-byte decoded array, retaining the old array. -/
def canonicalReturn (pointer count : Word) : Except Failure Word := do
  let next ← AllocationMemory.finalize pointer (word (96+32*count.val))
  AllocationMemory.allocateArray next count

theorem canonical_finalize (pointer count : Word)
    (hp : pointer.val+96+32*count.val ≤ 2^32) (hc : count.val ≤ 32) :
    AllocationMemory.finalize pointer (word (96+32*count.val)) =
      .ok (word (pointer.val+96+32*count.val)) := by
  have sizeBound : 96+32*count.val < 2^256 := by omega
  have roundedBound : 96+32*count.val+31 < 2^256 := by omega
  have rounded : AllocationMemory.roundedSize (word (96+32*count.val)) =
      96+32*count.val := by
    simp only [AllocationMemory.roundedSize, word, Nat.mod_eq_of_lt sizeBound,
      Nat.mod_eq_of_lt roundedBound]
    omega
  have nextBound : pointer.val+(96+32*count.val) < 2^256 := by omega
  have noFail : ¬ ((word (pointer.val+(96+32*count.val))).val > AllocationMemory.limit ∨
      (word (pointer.val+(96+32*count.val))).val < pointer.val) := by
    simp only [word, Nat.mod_eq_of_lt nextBound]
    unfold AllocationMemory.limit
    omega
  simp only [AllocationMemory.finalize, rounded, noFail, ↓reduceIte]
  congr 2 <;> omega

theorem canonicalReturn_exact (pointer count : Word)
    (hp : pointer.val+96+32*count.val ≤ 2^32) (hc : count.val ≤ 32) :
    canonicalReturn pointer count = .ok (word (pointer.val+128+64*count.val)) := by
  have nextBound : pointer.val+96+32*count.val < 2^256 := by omega
  have nextVal : (word (pointer.val+96+32*count.val)).val =
      pointer.val+96+32*count.val := Nat.mod_eq_of_lt nextBound
  have small : (word (pointer.val+96+32*count.val)).val ≤ 2^32 := by
    rw [nextVal]; exact hp
  simp only [canonicalReturn, canonical_finalize pointer count hp hc, bind, Except.bind,
    AllocationMemory.bounded_array_allocates _ count small hc, nextVal]
  congr 2 <;> omega

/-- A failed library execution never performs the successful-return allocations. -/
def afterLibrary (pointer count : Word) (reply : Except Failure α) :
    Except Failure (α × Word) := do
  let result ← reply
  let next ← canonicalReturn pointer count
  pure (result,next)

theorem library_failure (pointer count : Word) (reason : Failure) :
    afterLibrary (α := α) pointer count (.error reason) = .error reason := rfl

theorem library_success (pointer count : Word) (result : α)
    (hp : pointer.val+96+32*count.val ≤ 2^32) (hc : count.val ≤ 32) :
    afterLibrary pointer count (.ok result) =
      .ok (result,word (pointer.val+128+64*count.val)) := by
  simp only [afterLibrary, canonicalReturn_exact pointer count hp hc, bind, Except.bind]
  rfl

#print axioms zero_exact
#print axioms zero_allocation_failure
#print axioms canonicalReturn_exact
#print axioms library_success
end LidoSRv3.Audit.Source.TrioComposition.CallerMemory
