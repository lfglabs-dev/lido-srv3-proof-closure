import LidoSRv3.Audit.Source.TrioReserve1.PartitionSpec

/-!
Kill-lines pinning `TrioReserve1.PartitionSpec` `protectedReserve`
and `AllowedSpend` invariants — the P-RESERVE-1 mathematical
partition semantics.
-/

namespace LidoSRv3.Tests.SourceTrioReserve1PartitionSpecKillLines

open LidoSRv3.Audit.Source.TrioReserve1.PartitionSpec

/-! ## `protectedReserve` reduces to `min (buffer - min buffer reserve) demand`. -/

theorem protectedReserve_reduces (buffer reserve demand : Nat) :
    protectedReserve buffer reserve demand =
      min (buffer - min buffer reserve) demand := rfl

/-! ## `spend_preserves` — allowed spend preserves protection. -/

theorem spend_preserves_restated
    (buffer reserve demand amount : Nat)
    (allowed : AllowedSpend buffer reserve demand amount) :
    protectedReserve (buffer - amount) (reserve - amount) demand =
      protectedReserve buffer reserve demand :=
  spend_preserves buffer reserve demand amount allowed

/-! ## `lowering_reserve` — lower stored reserve doesn't hurt protection. -/

theorem lowering_reserve_restated
    (buffer demand before after : Nat) (h : after ≤ before) :
    protectedReserve buffer before demand ≤
      protectedReserve buffer after demand :=
  lowering_reserve buffer demand before after h

/-! ## `demand_monotone` — demand ↑ implies protection ↑. -/

theorem demand_monotone_restated
    (buffer reserve oldDemand newDemand : Nat)
    (h : oldDemand ≤ newDemand) :
    protectedReserve buffer reserve oldDemand ≤
      protectedReserve buffer reserve newDemand :=
  demand_monotone buffer reserve oldDemand newDemand h

/-! ## `two_spends` — two sequential allowed spends compose. -/

theorem two_spends_restated
    (buffer reserve demand first second : Nat)
    (h₁ : AllowedSpend buffer reserve demand first)
    (h₂ : AllowedSpend (buffer - first) (reserve - first) demand second) :
    protectedReserve (buffer - first - second) (reserve - first - second) demand =
      protectedReserve buffer reserve demand :=
  two_spends buffer reserve demand first second h₁ h₂

end LidoSRv3.Tests.SourceTrioReserve1PartitionSpecKillLines
