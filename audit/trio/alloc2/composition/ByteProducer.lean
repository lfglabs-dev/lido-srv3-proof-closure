import audit.trio.alloc2.composition.ByteInitialize
import audit.trio.alloc2.composition.ByteFrame

/-! Actual ALLOC-1 output to an executed physical serialization adapter and
ALLOC-2. This derives the array entry relation; it does not assume it. Relating
this adapter's adjacent layout to the compiler's interleaved allocation/copy
schedule, uint256 addresses and gas remains a separate source boundary. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteProducer
open _root_.LidoSRv3.Audit.Source.TrioAlloc1

def capacityPointer (ap : Nat) (out : CapacityOutput) : Nat :=
  ap+32*(out.allocations.length+1)

def storeOutput (memory : ByteMemory.Memory) (ap : Nat) (out : CapacityOutput) : ByteMemory.Memory :=
  ByteMemory.constructArrays memory ap (capacityPointer ap out) out.allocations out.capacities

/-- The executor result supplies both header bounds through the actual storage
count. Caller premises contain neither ArrayAt nor successful ALLOC-2 execution. -/
theorem producer_output_store_bridge (l : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (out : CapacityOutput)
    (executed : produce l storage oracle input before = (.ok out, after))
    (memory : ByteMemory.Memory) (ap : Nat) :
    ByteIndexed.ArraysAt (storeOutput memory ap out) ap (capacityPointer ap out)
      out.allocations out.capacities ∧
    ∃ result final,
      allocate out.allocations out.capacities input.depositsToAllocate = .ok result ∧
      ByteIndexed.run (storeOutput memory ap out) ap (capacityPointer ap out) input.depositsToAllocate =
        .ok (result.amount, final) ∧
      ByteIndexed.ArraysAt final ap (capacityPointer ap out) result.buckets out.capacities ∧
      Spec.Distributes (decodedRows out.allocations out.capacities) input.depositsToAllocate.val
        result.amount.val (decodedRows result.buckets out.capacities) := by
  have lengths := producer_length_from_storage l storage oracle input before after out executed
  have bucketBound : out.allocations.length < 2^256 := lengths.1 ▸ (storage (countSlot l)).isLt
  have capacityBound : out.capacities.length < 2^256 := lengths.2 ▸ (storage (countSlot l)).isLt
  have related : ByteIndexed.ArraysAt (storeOutput memory ap out) ap (capacityPointer ap out)
      out.allocations out.capacities :=
    ByteMemory.constructArrays_related memory ap (capacityPointer ap out) out.allocations out.capacities
      bucketBound capacityBound (Or.inl (Nat.le_refl _))
  exact ⟨related, ByteIndexed.run_success _ _ _ _ _ _ related (by omega)⟩

#print axioms producer_output_store_bridge
end LidoSRv3.Audit.Source.TrioAlloc2.ByteProducer
