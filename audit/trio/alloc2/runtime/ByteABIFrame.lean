import audit.trio.alloc2.runtime.ByteABIProducer

namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
open _root_.Compiler.CompilationModel
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (Bytes decodeWord ArrayAt)

theorem copyFrom_load_frame (memory : DenoteMemory.Memory) (source : Nat → DenoteMemory.Byte)
    (dest offset size address : Nat) (outside : address+32 ≤ dest ∨ dest+size ≤ address) :
    ByteMemory.load (view (memory.copyFrom source dest offset size)) address = ByteMemory.load (view memory) address := by
  unfold ByteMemory.load ByteMemory.bytes
  apply congrArg (fun bytes => decodeWord bytes 0)
  apply congrArg List.ofFn
  funext i
  exact copyFrom_frame memory source dest offset size (address+i.val) (by have := i.isLt; omega)

/-- A copied return region leaves the caller's original array intact in either
region order. Separation concerns complete byte intervals, including headers. -/
theorem copyFrom_array_frame (memory : DenoteMemory.Memory) (source : Nat → DenoteMemory.Byte)
    (dest offset size pointer : Nat) (values : List Word)
    (related : ArrayAt (ByteMemory.load (view memory)) pointer values)
    (separated : pointer+32*(values.length+1) ≤ dest ∨ dest+size ≤ pointer) :
    ArrayAt (ByteMemory.load (view (memory.copyFrom source dest offset size))) pointer values := by
  constructor
  · rw [copyFrom_load_frame memory source dest offset size pointer (by omega)]
    exact related.1
  · intro i
    rw [copyFrom_load_frame memory source dest offset size (pointer+32*(i.val+1))
      (by have := i.isLt; omega)]
    exact related.2 i

#print axioms copyFrom_load_frame
#print axioms copyFrom_array_frame
end LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
