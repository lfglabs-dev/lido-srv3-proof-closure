import audit.trio.alloc2.runtime.ByteLoop
import audit.trio.alloc2.composition.ByteProducer

namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
open _root_.Compiler.CompilationModel
open _root_.LidoSRv3.Audit.Source.TrioAlloc1

def writeWords (memory : DenoteMemory.Memory) (start : Nat) : List Word → DenoteMemory.Memory
  | [] => memory
  | value :: rest => writeWords (memory.writeWord start (encode value)) (start+32) rest

theorem view_writeWords (memory : DenoteMemory.Memory) (start : Nat) (values : List Word) :
    view (writeWords memory start values) = ByteMemory.writeWords (view memory) start values := by
  induction values generalizing memory start with
  | nil => rfl
  | cons value rest ih =>
    simp only [writeWords, ByteMemory.writeWords, ih, view_writeWord]

def constructArrays (memory : DenoteMemory.Memory) (ap cp : Nat) (buckets capacities : List Word) :
    DenoteMemory.Memory :=
  writeWords (writeWords memory ap (word buckets.length :: buckets)) cp (word capacities.length :: capacities)

theorem view_constructArrays (memory : DenoteMemory.Memory) (ap cp : Nat) (buckets capacities : List Word) :
    view (constructArrays memory ap cp buckets capacities) =
      ByteMemory.constructArrays (view memory) ap cp buckets capacities := by
  simp only [constructArrays, view_writeWords, ByteMemory.constructArrays, ByteMemory.writeArray]

theorem constructArrays_related (memory : DenoteMemory.Memory) (ap cp : Nat) (buckets capacities : List Word)
    (bucketBound : buckets.length < 2^256) (capacityBound : capacities.length < 2^256)
    (separated : ap+32*(buckets.length+1) ≤ cp ∨ cp+32*(capacities.length+1) ≤ ap) :
    ArraysAt (constructArrays memory ap cp buckets capacities) ap cp buckets capacities := by
  change ByteIndexed.ArraysAt (view (constructArrays memory ap cp buckets capacities)) ap cp buckets capacities
  rw [view_constructArrays]
  exact ByteMemory.constructArrays_related (view memory) ap cp buckets capacities bucketBound capacityBound separated

/-- Actual producer outputs are serialized through the pinned Verity byte-store
primitive before the proportional loop. Compiler write scheduling is separate. -/
theorem producer_output_store_bridge (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (out : CapacityOutput)
    (executed : produce l storage oracle input before = (.ok out, after))
    (memory : DenoteMemory.Memory) (ap : Nat) :
    let cp := ByteProducer.capacityPointer ap out
    let entry := constructArrays memory ap cp out.allocations out.capacities
    ArraysAt entry ap cp out.allocations out.capacities ∧
    ∃ result final,
      allocate out.allocations out.capacities input.depositsToAllocate = .ok result ∧
      run entry ap cp input.depositsToAllocate = .ok (result.amount, final) ∧
      ArraysAt final ap cp result.buckets out.capacities ∧
      Spec.Distributes (decodedRows out.allocations out.capacities) input.depositsToAllocate.val
        result.amount.val (decodedRows result.buckets out.capacities) := by
  dsimp only
  have lengths := producer_length_from_storage l storage oracle input before after out executed
  have bucketBound : out.allocations.length < 2^256 := lengths.1 ▸ (storage (countSlot l)).isLt
  have capacityBound : out.capacities.length < 2^256 := lengths.2 ▸ (storage (countSlot l)).isLt
  have related := constructArrays_related memory ap (ByteProducer.capacityPointer ap out)
    out.allocations out.capacities bucketBound capacityBound (Or.inl (Nat.le_refl _))
  exact ⟨related, run_success _ _ _ _ _ _ related (by omega)⟩

#print axioms view_writeWords
#print axioms view_constructArrays
#print axioms constructArrays_related
#print axioms producer_output_store_bridge
end LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
