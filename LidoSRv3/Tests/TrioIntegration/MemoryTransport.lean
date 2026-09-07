import LidoSRv3.Audit.Source.TrioComposition.MemoryTransportABI

namespace LidoSRv3.Tests.TrioIntegration.MemoryTransport
open Audit.Source.TrioAlloc1
open Audit.Source.TrioComposition.MemoryTransport
open Audit.Source.TrioAlloc2 (readMemoryArray allocateMemory)

private def initial : MemoryWords := fun _ => word 777
private def allocated : MemoryWords :=
  storeElement (storeElement (zeroArray initial 128 2) 128 0 (word 9)) 128 1 (word 0)
private def capacities : MemoryWords :=
  storeElement (storeElement (zeroArray allocated 256 2) 256 0 (word 8)) 256 1 (word 5)

/-- First-pass writes are preserved when fresh capacities are zeroed/filled;
the overfull first bucket remains 9, including capacity below allocation. -/
example : (readMemoryArray capacities 128).map Fin.val = [9,0] := by decide
example : (readMemoryArray capacities 256).map Fin.val = [8,5] := by decide
example : capacities 96 = word 777 ∧ capacities 352 = word 777 := by decide

private def copied : MemoryWords := copyWordsLive capacities 128 512 3
example : (readMemoryArray copied 512).map Fin.val = [9,0] := by decide
example : (readMemoryArray copied 128).map Fin.val = [9,0] := by decide
example : (readMemoryArray (storeElement copied 512 0 (word 42)) 128).map Fin.val = [9,0] := by decide

/-- Overlap really changes live-copy behavior, so isolation cannot be omitted. -/
example : copyWordsLive capacities 128 160 3 224 = word 2 := by decide
example : copyWords capacities 128 capacities 160 3 224 = word 0 := by decide

private def result : Audit.Source.TrioAlloc2.StepOutput := ⟨word 3,[word 9,word 3]⟩
#eval do
  match allocateMemory capacities 128 256 (word 3) with
  | .error _ => throw (IO.userError "memory-fed library unexpectedly failed")
  | .ok out =>
    unless out.amount.val == 3 && out.buckets.map Fin.val == [9,3] do
      throw (IO.userError "memory-fed library returned wrong allocation")
    IO.println "MEMORY_TRANSPORT library actual-read regression passed"

private def returned : MemoryWords := importReturn capacities 512 result
example : (readMemoryArray returned 512).map Fin.val = [9,3] := by decide
example : (readMemoryArray returned 128).map Fin.val = [9,0] := by decide
example : (readMemoryArray returned 256).map Fin.val = [8,5] := by decide

/-- The return array and old allocations supply distinct operands to the
parent's delta conversion; mutating the returned bucket cannot erase its base. -/
example : (returned 576).val - (returned 192).val = 3 := by decide
example : (readMemoryArray (storeElement returned 512 1 (word 96)) 128).map Fin.val = [9,0] := by decide

end LidoSRv3.Tests.TrioIntegration.MemoryTransport
