import LidoSRv3.Audit.Source.TopupRouterContinuation

/-!
Kill-lines pinning `Source.TopupRouterContinuation` `guardSum`
correspondence to `TopupWeiBounds.allocationGuards` +
`uncheckedSum`.
-/

namespace LidoSRv3.Tests.SourceTopupRouterContinuationGuardSumKillLines

open LidoSRv3.Audit.Source.TopupRouterContinuation
open LidoSRv3.Audit.Source

/-! ## `guardSum_spec` — restated. -/

theorem guardSum_spec_restated (amounts : List Nat) :
    ∀ limits acc total,
      guardSum amounts limits acc = .ok total →
      TopupWeiBounds.allocationGuards amounts limits ∧
        total = TopupWeiBounds.uncheckedSum acc amounts :=
  guardSum_spec amounts

/-! ## `guardSum_run` — restated. -/

theorem guardSum_run_restated (amounts : List Nat) :
    ∀ limits acc,
      TopupWeiBounds.allocationGuards amounts limits →
      guardSum amounts limits acc =
        .ok (TopupWeiBounds.uncheckedSum acc amounts) :=
  guardSum_run amounts

/-! ## `guardSum` empty amounts is `.ok acc`. -/

theorem guardSum_empty (limits : List Nat) (acc : Nat) :
    guardSum [] limits acc = .ok acc := rfl

end LidoSRv3.Tests.SourceTopupRouterContinuationGuardSumKillLines
