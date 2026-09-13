import LidoSRv3.Audit.Source.TrioReserve1.SequenceSpec

/-!
Kill-lines pinning `TrioReserve1.SequenceSpec` `target_protection`
+ `rebalance_partition` witness theorems.
-/

namespace LidoSRv3.Tests.SourceTrioReserve1SequenceSpecKillLines

open LidoSRv3.Audit.Source.TrioReserve1.SequenceSpec
open LidoSRv3.Audit.Source.TrioReserve1

/-! ## `target_protection` — restated. -/

theorem target_protection_restated
    (before after : WriterSpec.State) (requested demand : Nat)
    (h : WriterSpec.Target before requested after) :
    PartitionSpec.protectedReserve before.buffer before.reserve demand ≤
      PartitionSpec.protectedReserve after.buffer after.reserve demand :=
  target_protection before after requested demand h

/-! ## `rebalance_partition` — restated. -/

theorem rebalance_partition_restated
    (before after : WriterSpec.State) (demand : Nat)
    (h : WriterSpec.Rebalance before after) :
    PartitionSpec.protectedReserve after.buffer after.reserve demand =
      min (before.buffer -
        min before.buffer (max before.reserve before.target)) demand :=
  rebalance_partition before after demand h

end LidoSRv3.Tests.SourceTrioReserve1SequenceSpecKillLines
