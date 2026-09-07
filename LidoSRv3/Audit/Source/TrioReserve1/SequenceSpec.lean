import LidoSRv3.Audit.Source.TrioReserve1.PartitionSpec
import LidoSRv3.Audit.Source.TrioReserve1.WriterSpec

namespace LidoSRv3.Audit.Source.TrioReserve1.SequenceSpec

/-- Independent reserve accounting transitions. Rebalance establishes a new
partition; it does not promise preservation of the old withdrawal allocation. -/
inductive Step : WriterSpec.State → WriterSpec.State → Prop
  | target (before after : WriterSpec.State) (requested : Nat)
      (h : WriterSpec.Target before requested after) : Step before after
  | rebalance (before after : WriterSpec.State)
      (h : WriterSpec.Rebalance before after) : Step before after
  | spend (before after : WriterSpec.State) (demand amount : Nat)
      (allowed : PartitionSpec.AllowedSpend before.buffer before.reserve demand amount)
      (buffer : after.buffer + amount = before.buffer)
      (reserve : after.reserve = before.reserve - amount)
      (target : after.target = before.target) : Step before after

inductive Steps : WriterSpec.State → WriterSpec.State → Prop
  | refl (s : WriterSpec.State) : Steps s s
  | cons {a b c : WriterSpec.State} (first : Step a b) (rest : Steps b c) : Steps a c

theorem target_protection (before after : WriterSpec.State) (requested demand : Nat)
    (h : WriterSpec.Target before requested after) :
    PartitionSpec.protectedReserve before.buffer before.reserve demand ≤
      PartitionSpec.protectedReserve after.buffer after.reserve demand := by
  rcases h with ⟨hb, _, hr⟩
  rw [hb, hr]
  exact PartitionSpec.lowering_reserve _ _ _ _ (Nat.min_le_left _ _)

theorem rebalance_partition (before after : WriterSpec.State) (demand : Nat)
    (h : WriterSpec.Rebalance before after) :
    PartitionSpec.protectedReserve after.buffer after.reserve demand =
      min (before.buffer - min before.buffer (max before.reserve before.target)) demand := by
  rcases h with ⟨hb, _, hr⟩
  rw [hb, hr]
  rfl

end LidoSRv3.Audit.Source.TrioReserve1.SequenceSpec
