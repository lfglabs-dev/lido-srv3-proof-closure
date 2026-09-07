import LidoSRv3.Audit.Source.TrioAlloc1.Properties
import LidoSRv3.Audit.Source.TrioAlloc2.Errors
import LidoSRv3.Audit.Source.TrioAlloc2.Conservation
import LidoSRv3.Audit.Source.TrioAlloc2.LoopCorrespondence

/-! Consumer-owned composition against the exact candidate producer executor.
This is the decoded boundary: byte-memory/ABI, public entry conversion, and trace
refinement remain additional obligations. No memory relation, count cap, callee
success, or arithmetic-success premise is silently added to producer success. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2
open LidoSRv3.Audit.Source

structure DecodedConsumerPremises (output : TrioAlloc1.CapacityOutput) : Prop where
  lengths : output.allocations.length = output.capacities.length
  length_representable : output.allocations.length < 2 ^ 256

/-- Actual producer execution establishes both premises required by the decoded
consumer totality theorem. The length bound comes from the actual storage word,
via the proved enumeration relation, not merely from an assumed output shape. -/
theorem producer_success_establishes_consumer_premises
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (input : TrioAlloc1.CapacityInput) (before after : TrioAlloc1.Transcript)
    (output : TrioAlloc1.CapacityOutput)
    (executed : TrioAlloc1.produce layout storage oracle input before = (.ok output, after)) :
    DecodedConsumerPremises output := by
  have order := TrioAlloc1.producer_router_order layout storage oracle input before after output executed
  change output.identities = TrioAlloc1.routerOrder layout storage at order
  have countEq : output.allocations.length = (storage (TrioAlloc1.countSlot layout)).val := by
    rw [output.allocations_length, order]
    simp [TrioAlloc1.routerOrder]
  exact ⟨TrioAlloc1.producer_lengths layout storage oracle input before after output executed,
    by rw [countEq]; exact (storage (TrioAlloc1.countSlot layout)).isLt⟩

/-- The producer's actual allocated/capacity arrays are passed to the consumer.
The demand is the same WC01-equivalent demand observed by the producer. -/
theorem producer_then_consumer_succeeds
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (input : TrioAlloc1.CapacityInput) (before after : TrioAlloc1.Transcript)
    (output : TrioAlloc1.CapacityOutput)
    (executed : TrioAlloc1.produce layout storage oracle input before = (.ok output, after)) :
    ∃ result, allocate output.allocations output.capacities input.depositsToAllocate = .ok result ∧
      result.amount.val ≤ input.depositsToAllocate.val ∧
      bucketTotal result.buckets = bucketTotal output.allocations + result.amount.val ∧
      result.buckets.length = output.identities.length := by
  have premises := producer_success_establishes_consumer_premises
    layout storage oracle input before after output executed
  obtain ⟨result, run⟩ := allocate_success output.allocations output.capacities input.depositsToAllocate
    (Nat.le_of_eq premises.lengths) premises.length_representable
  refine ⟨result, run, allocate_amount_le_demand _ _ _ _ run, ?_, ?_⟩
  · exact allocate_conserves _ _ _ _ run
  · exact (allocate_preserves_length _ _ _ _ run).trans output.allocations_length

#print axioms producer_success_establishes_consumer_premises
#print axioms producer_then_consumer_succeeds

/-- Actual producer outputs admit an execution satisfying the independent
proportional distribution relation, with no assumed consumer success. -/
theorem producer_then_consumer_distributes
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (input : TrioAlloc1.CapacityInput) (before after : TrioAlloc1.Transcript)
    (output : TrioAlloc1.CapacityOutput)
    (executed : TrioAlloc1.produce layout storage oracle input before = (.ok output, after)) :
    ∃ result, allocate output.allocations output.capacities input.depositsToAllocate = .ok result ∧
      Spec.Distributes (decodedRows output.allocations output.capacities)
        input.depositsToAllocate.val result.amount.val (decodedRows result.buckets output.capacities) := by
  have premises := producer_success_establishes_consumer_premises
    layout storage oracle input before after output executed
  exact distribution_exists output.allocations output.capacities input.depositsToAllocate
    (Nat.le_of_eq premises.lengths) premises.length_representable

#print axioms producer_then_consumer_distributes
end LidoSRv3.Audit.Source.TrioAlloc2
