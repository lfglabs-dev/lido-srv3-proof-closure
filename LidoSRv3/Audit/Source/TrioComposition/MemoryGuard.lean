import LidoSRv3.Audit.Source.TrioAlloc2.MemoryPrefix
import LidoSRv3.Audit.Source.TrioAlloc1.Execution

/-! Constant-time evaluation of the already modeled allocation prefix. The
closed form is proved equal on every outcome; this is not a compiler schedule
or physical-memory-store refinement. The initial free pointer remains explicit. -/
namespace LidoSRv3.Audit.Source.TrioComposition.MemoryGuard
open TrioAlloc1

def run (pointer count : Word) : Except TrioAlloc2.MemoryPrefix.Failure Word :=
  if pointer.val+224*count.val+64 < 2^64 then
    .ok (word (pointer.val+224*count.val+64))
  else .error .memoryOverflow

theorem run_eq (pointer count : Word) :
    run pointer count = TrioAlloc2.MemoryPrefix.execute pointer count := by
  cases executed : TrioAlloc2.MemoryPrefix.execute pointer count with
  | error reason =>
    cases reason
    have overflow := (TrioAlloc2.MemoryPrefix.execute_overflow_iff pointer count).mp executed
    simp [run, show ¬ pointer.val+224*count.val+64 < 2^64 by omega]
  | ok out =>
    have extent := TrioAlloc2.MemoryPrefix.execute_extent pointer count out executed
    have bound : pointer.val+224*count.val+64 < 2^64 := by omega
    have wordBound : pointer.val+224*count.val+64 < 2^256 := by omega
    simp only [run, bound, ↓reduceIte, Except.ok.injEq]
    apply Fin.ext
    simpa only [word, Nat.mod_eq_of_lt wordBound] using extent.1.symm

def check (pointer count : Word) : Except Failure Word :=
  (run pointer count).mapError fun _ => .panic (word 0x41)

theorem check_eq (pointer count : Word) :
    check pointer count = (TrioAlloc2.MemoryPrefix.execute pointer count).mapError
      (fun _ => Failure.panic (word 0x41)) := by
  rw [check, run_eq]

#print axioms run_eq
#print axioms check_eq
end LidoSRv3.Audit.Source.TrioComposition.MemoryGuard
