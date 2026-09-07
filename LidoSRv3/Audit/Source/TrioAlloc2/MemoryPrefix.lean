import LidoSRv3.Audit.Source.TrioAlloc2.Word

/-! Aligned allocation guards emitted by pinned solc 0.8.25 for SRLib. Word
addition wraps before the compiler checks the 64-bit free-pointer limit and
wraparound. The producer prefix allocates two count-sized pointer/word arrays
and count five-word cache structs before the first module call. This models
the allocation guards; zeroing, stores, gas and compiler refinement are separate. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.MemoryPrefix

inductive Failure where
  | memoryOverflow
  deriving DecidableEq, Repr
abbrev AllocResult := Except Failure Word

def reserve (pointer : Word) (alignedSize : Nat) : AllocResult :=
  let next : Word := ⟨(pointer.val+alignedSize)%2^256, Nat.mod_lt _ (by decide)⟩
  if next.val ≥ 2^64 ∨ next.val < pointer.val then .error .memoryOverflow else .ok next

def array (pointer count : Word) : AllocResult :=
  if count.val ≥ 2^64 then .error .memoryOverflow
  else reserve pointer (32*(count.val+1))

def cacheRows : Nat → Word → AllocResult
  | 0, pointer => .ok pointer
  | n+1, pointer => do
    let next ← reserve pointer 160
    cacheRows n next

def execute (pointer count : Word) : AllocResult := do
  let allocations ← array pointer count
  let cache ← array allocations count
  cacheRows count.val cache

theorem reserve_success (pointer out : Word) (size : Nat) (small : size < 2^128)
    (executed : reserve pointer size = .ok out) :
    out.val = pointer.val+size ∧ out.val < 2^64 := by
  unfold reserve at executed
  dsimp only at executed
  split at executed
  · contradiction
  · rename_i safe
    simp only [Except.ok.injEq] at executed
    subst out
    have pointerBound : pointer.val < 2^64 := by omega
    have noWrap : pointer.val+size < 2^256 := by omega
    simp only [Nat.mod_eq_of_lt noWrap] at safe ⊢
    exact ⟨True.intro, by omega⟩

theorem array_success (pointer count out : Word) (executed : array pointer count = .ok out) :
    count.val < 2^64 ∧ out.val = pointer.val+32*(count.val+1) ∧ out.val < 2^64 := by
  unfold array at executed
  split at executed
  · contradiction
  · rename_i countBound
    exact ⟨by omega, reserve_success _ _ _ (by omega) executed⟩

theorem cacheRows_success (n : Nat) (pointer out : Word)
    (executed : cacheRows n pointer = .ok out) : out.val = pointer.val+160*n := by
  induction n generalizing pointer with
  | zero =>
    simp only [cacheRows, Except.ok.injEq] at executed
    subst out
    simp
  | succ n ih =>
    cases hr : reserve pointer 160 with
    | error e => simp [cacheRows, hr, bind, Except.bind] at executed
    | ok next =>
      have hs := reserve_success pointer next 160 (by decide) hr
      have tail : cacheRows n next = .ok out := by simpa [cacheRows, hr, bind, Except.bind] using executed
      have ht := ih next tail
      omega

theorem cacheRows_bound (n : Nat) (pointer out : Word) (initial : pointer.val < 2^64)
    (executed : cacheRows n pointer = .ok out) : out.val < 2^64 := by
  induction n generalizing pointer with
  | zero => simp only [cacheRows, Except.ok.injEq] at executed; subst out; exact initial
  | succ n ih =>
    cases hr : reserve pointer 160 with
    | error e => simp [cacheRows, hr, bind, Except.bind] at executed
    | ok next =>
      exact ih next (reserve_success _ _ _ (by decide) hr).2
        (by simpa [cacheRows, hr, bind, Except.bind] using executed)

/-- The packet extent is derived from executed guards, not assumed from the
uint256 storage count. Cache allocations dominate the canonical ABI packet. -/
theorem execute_extent (pointer count out : Word) (executed : execute pointer count = .ok out) :
    out.val = pointer.val+224*count.val+64 ∧ out.val < 2^64 ∧ 160+64*count.val < 2^64 := by
  cases ha : array pointer count with
  | error e => simp [execute, ha, bind, Except.bind] at executed
  | ok allocations =>
    cases hc : array allocations count with
    | error e => simp [execute, ha, hc, bind, Except.bind] at executed
    | ok cache =>
      have a := array_success _ _ _ ha
      have c := array_success _ _ _ hc
      have tail : cacheRows count.val cache = .ok out := by simpa [execute, ha, hc, bind, Except.bind] using executed
      have value := cacheRows_success _ _ _ tail
      have bound := cacheRows_bound _ _ _ c.2.2 tail
      refine ⟨by omega, bound, ?_⟩
      by_cases hz : count.val = 0 <;> omega

private theorem reserve_of_bound (pointer : Word) (size : Nat)
    (bound : pointer.val+size < 2^64) : ∃ out, reserve pointer size = .ok out := by
  have noWrap : pointer.val+size < 2^256 := by omega
  refine ⟨⟨pointer.val+size, noWrap⟩, ?_⟩
  simp [reserve, Nat.mod_eq_of_lt noWrap, show ¬ pointer.val+size ≥ 2^64 by omega,
    show ¬ pointer.val+size < pointer.val by omega]

private theorem array_of_bound (pointer count : Word)
    (bound : pointer.val+32*(count.val+1) < 2^64) : ∃ out, array pointer count = .ok out := by
  have countBound : ¬ count.val ≥ 2^64 := by omega
  simpa only [array, countBound, ↓reduceIte] using reserve_of_bound pointer (32*(count.val+1)) bound

private theorem cacheRows_of_bound (n : Nat) (pointer : Word)
    (bound : pointer.val+160*n < 2^64) : ∃ out, cacheRows n pointer = .ok out := by
  induction n generalizing pointer with
  | zero => exact ⟨pointer, rfl⟩
  | succ n ih =>
    obtain ⟨next, allocated⟩ := reserve_of_bound pointer 160 (by omega)
    have value := reserve_success _ _ _ (by decide) allocated
    obtain ⟨out, tail⟩ := ih next (by omega)
    exact ⟨out, by simp [cacheRows, allocated, tail, bind, Except.bind]⟩

/-- Exact success condition for the emitted allocation-prefix guards. -/
theorem execute_success_iff (pointer count : Word) :
    (∃ out, execute pointer count = .ok out) ↔ pointer.val+224*count.val+64 < 2^64 := by
  constructor
  · rintro ⟨out, executed⟩
    have h := execute_extent _ _ _ executed
    omega
  · intro bound
    obtain ⟨allocations, ha⟩ := array_of_bound pointer count (by omega)
    have a := array_success _ _ _ ha
    obtain ⟨cache, hc⟩ := array_of_bound allocations count (by omega)
    have c := array_success _ _ _ hc
    obtain ⟨out, tail⟩ := cacheRows_of_bound count.val cache (by omega)
    exact ⟨out, by simp [execute, ha, hc, tail, bind, Except.bind]⟩

/-- Oversized prefixes fail with memory overflow, rather than array/arithmetic
panic or attempted producer calls. -/
theorem execute_overflow_iff (pointer count : Word) :
    execute pointer count = .error .memoryOverflow ↔ 2^64 ≤ pointer.val+224*count.val+64 := by
  have success := execute_success_iff pointer count
  cases result : execute pointer count with
  | error reason => cases reason; simp [result] at success; constructor <;> intro h <;> first | rfl | omega
  | ok out => simp [result] at success; constructor <;> intro h <;> first | cases h | omega

#print axioms execute_success_iff
#print axioms execute_overflow_iff

#print axioms reserve_success
#print axioms execute_extent
end LidoSRv3.Audit.Source.TrioAlloc2.MemoryPrefix
