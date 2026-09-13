import LidoSRv3.Audit.Source.TopupLiveWithdrawal

/-!
Kill-lines pinning `Source.TopupLiveWithdrawal.suffix` zero-noop
witnesses. This is the P-TOPUP-1 TOPUP-specific withdraw branch.
-/

namespace LidoSRv3.Tests.SourceTopupLiveWithdrawalSuffixKillLines

open LidoSRv3.Audit.Source.TopupLiveWithdrawal
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live

/-! ## `zero_noop` — restated (zero amount skips withdrawal). -/

theorem zero_noop_restated
    (external : External) (ctx : Context) (amount : Word)
    (before : World) (hz : amount.val = 0) :
    run (suffix external ctx amount) before = ⟨.ok (), before, []⟩ :=
  zero_noop external ctx amount before hz

/-! ## `zero_seed_tail` — restated (zero seed creates no accounting tail). -/

theorem zero_seed_tail_restated (ctx : Context) (before : World) :
    WithdrawalTail.updateSeeds ctx (word 0) before = ⟨.ok (), before, []⟩ :=
  zero_seed_tail ctx before

end LidoSRv3.Tests.SourceTopupLiveWithdrawalSuffixKillLines
