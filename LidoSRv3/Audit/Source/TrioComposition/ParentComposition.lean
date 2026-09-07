import LidoSRv3.Audit.Source.TrioComposition.Parent
import LidoSRv3.Audit.Source.TrioAlloc1.Memory
import LidoSRv3.Audit.Source.TrioAlloc2.RowBounds

/-! Discharge the public conversion components' length and subtraction premises
from the actual producer and proportional consumer runs. Ether product overflow,
ABI/copy semantics and full parent outcome refinement remain separate. -/
namespace LidoSRv3.Audit.Source.TrioComposition
open TrioAlloc1

/-- Actual producer/consumer lengths discharge both premises of the complete
positive-demand Ether conversion relation. No caller-supplied array lengths. -/
theorem producer_consumer_conversion_refines
    (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (output : CapacityOutput)
    (produced : produce layout storage oracle input before = (.ok output, after))
    (result : TrioAlloc2.StepOutput)
    (consumed : TrioAlloc2.allocate output.allocations output.capacities input.depositsToAllocate = .ok result)
    (deltas totals : List Word)
    (converted : convertPositive input.config.maxEBType1 (storage (countSlot layout)).val
      output.allocations result.buckets = .ok (deltas, totals)) :
    Converted input.config.maxEBType1.val output.allocations result.buckets deltas totals := by
  have oldLength := (producer_length_from_storage layout storage oracle input before after output produced).1
  have freshLength := TrioAlloc2.allocate_preserves_length _ _ _ _ consumed
  exact convertPositive_refines input.config.maxEBType1 (storage (countSlot layout)).val
    output.allocations result.buckets deltas totals oldLength (freshLength.trans oldLength) converted

/-- Zero-demand conversion also gets its loop bound from the real storage count. -/
theorem producer_zero_conversion_refines
    (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (output : CapacityOutput)
    (produced : produce layout storage oracle input before = (.ok output, after))
    (deltas totals : List Word)
    (converted : convertZero input.config.maxEBType1 (storage (countSlot layout)).val
      output.allocations = .ok (deltas, totals)) :
    Converted input.config.maxEBType1.val output.allocations output.allocations deltas totals := by
  exact convertZero_refines input.config.maxEBType1 (storage (countSlot layout)).val
    output.allocations deltas totals
    (producer_length_from_storage layout storage oracle input before after output produced).1 converted

/-- The new consumer row bound proves success of the exact Nat-input checked
subtraction used by the producer/public-wrapper arithmetic implementation. -/
theorem producer_consumer_parent_subtraction
    (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (output : CapacityOutput)
    (produced : produce layout storage oracle input before = (.ok output, after))
    (result : TrioAlloc2.StepOutput)
    (consumed : TrioAlloc2.allocate output.allocations output.capacities input.depositsToAllocate = .ok result)
    (i : Nat) (old fresh cap : Word)
    (oldRead : output.allocations[i]? = some old)
    (freshRead : result.buckets[i]? = some fresh)
    (capRead : output.capacities[i]? = some cap) :
    ∃ delta, TrioAlloc1.checkedSub fresh.val old.val = .ok delta ∧
      delta.val = fresh.val - old.val := by
  have lengths := (TrioAlloc2.producer_success_establishes_consumer_premises
    layout storage oracle input before after output produced).lengths
  have ordered := (TrioAlloc2.allocate_row_bounds output.allocations output.capacities
    input.depositsToAllocate result (Nat.le_of_eq lengths) consumed i old fresh cap
    oldRead capRead freshRead).1
  have bounded : fresh.val - old.val < 2 ^ 256 :=
    Nat.lt_of_le_of_lt (Nat.sub_le _ _) fresh.isLt
  refine ⟨⟨fresh.val - old.val, bounded⟩, ?_, rfl⟩
  simp [TrioAlloc1.checkedSub, ordered, checked, bounded]

#print axioms producer_consumer_conversion_refines
#print axioms producer_zero_conversion_refines
#print axioms producer_consumer_parent_subtraction
end LidoSRv3.Audit.Source.TrioComposition
