import LidoSRv3.Audit.Source.TrioReserve1.Packing
import LidoSRv3.Audit.Source.TrioReserve1.PartitionSpec

namespace LidoSRv3.Tests.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1

example : PartitionSpec.protectedReserve 100 20 50 = 50 := by decide
example : PartitionSpec.protectedReserve 70 0 50 = 50 := by decide
example : PartitionSpec.protectedReserve 100 20 90 = 80 := by decide

/-- Restoring a target greater than buffer is permitted by the pinned rebalance
helper; this witness rejects the proposed invariant storedReserve <= buffer. -/
example : PartitionSpec.protectedReserve 100 200 50 = 0 := by decide

/-- The wrong partition (spending buffer without consuming reserve) decreases
withdrawal protection even though the same amount is admitted by the spec. -/
example : PartitionSpec.AllowedSpend 100 20 80 20 ∧
    PartitionSpec.protectedReserve (100 - 20) 20 80 ≠
      PartitionSpec.protectedReserve 100 20 80 := by
  unfold PartitionSpec.AllowedSpend
  decide

#print axioms Packing.low_pack
#print axioms Packing.high_pack
#print axioms Packing.companion_preserved
#print axioms PartitionSpec.spend_preserves
#print axioms PartitionSpec.lowering_reserve
#print axioms PartitionSpec.demand_monotone
#print axioms PartitionSpec.two_spends
end LidoSRv3.Tests.TrioReserve1
