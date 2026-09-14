import LidoSRv3.Audit.Guarantees.PReserve1
import LidoSRv3.Audit.Guarantees.Composition.ReserveUnfinalizedCall

/-! # P-RESERVE-1 registered STATICCALL consumer

**Chantier 2 (Piste A, Thomas 2026-09-13) resolves the circular-import
constraint that previously kept `spend_preserves_from_live_call` in the
`LidoSRv3.Audit.Source` namespace.**

`ReserveUnfinalizedCall.lean` imports `PReserve1` (for
`source_spend_preserves_withdrawal_reserve` used inside its proof).
`PReserve1.lean` therefore cannot import `ReserveUnfinalizedCall`
without creating a cycle.  This joining module — which sits above BOTH
in the import graph — re-exports the STATICCALL-derived spend consumer
into the `LidoSRv3.Audit.Guarantees.PReserve1` namespace, closing the
Chantier 2 "freshQueueCache STATICCALL registered at P-RESERVE-1"
follow-up.

The re-exported theorems document the executable-plane path from an
`UnfinalizedStaticcall` observation to the registered parent's
conclusion.  No new proof content is introduced; the joining module
just consumes the existing `Source.ReserveUnfinalizedCall` machinery
at the Guarantees layer. -/

namespace LidoSRv3.Audit.Guarantees.PReserve1

open Verity
open LidoSRv3.Audit.SolidityReserve

/-- **STATICCALL-derived P-RESERVE-1 spend consumer.**

Under a well-formed `WithdrawalQueue.unfinalizedStETH()` STATICCALL
observation `c` (correct selector `0xd0fb84e8`, value 0, success, 32
ABI bytes returned decoding to word `w`) and the derived freshness
`freshQueueCacheFromCall`, the registered parent
`source_spend_preserves_withdrawal_reserve` applies at the decoded
word.  Re-export of
`LidoSRv3.Audit.Source.ReserveUnfinalizedCall.spend_preserves_from_live_call`
into the `LidoSRv3.Audit.Guarantees.PReserve1` namespace, closing the
"freshQueueCache STATICCALL registered at P-RESERVE-1" follow-up. -/
theorem reserve_spend_preserves_from_live_staticcall
    (inputs : WithdrawInputs) (before after : ReserveState) (amount : Word)
    (c : LidoSRv3.Audit.Source.ReserveUnfinalizedCall.UnfinalizedStaticcall)
    (w : Word)
    (hlive : LidoSRv3.Audit.Source.ReserveUnfinalizedCall.liveUnfinalizedStETH c =
      some w)
    (hfresh : LidoSRv3.Audit.Source.ReserveUnfinalizedCall.freshQueueCacheFromCall
      before c)
    (h : modelWithdrawDepositableEther inputs before amount = .committed after) :
    scopedWithdrawGuards inputs ∧
      amount ≠ 0 ∧
      withdrawalPartitionSpendInvariant before after amount ∧
      liveEffectiveWithdrawalsReserve after w =
        liveEffectiveWithdrawalsReserve before w :=
  LidoSRv3.Audit.Source.ReserveUnfinalizedCall.spend_preserves_from_live_call
    inputs before after amount c w hlive hfresh h

/-- A failed STATICCALL cannot produce a fresh cache — the derived
freshness `freshQueueCacheFromCall` is false on any observation `c`
whose `liveUnfinalizedStETH c = none`.  Re-export of
`Source.ReserveUnfinalizedCall.failed_call_not_fresh`. -/
theorem reserve_failed_staticcall_not_fresh
    (state : ReserveState)
    (c : LidoSRv3.Audit.Source.ReserveUnfinalizedCall.UnfinalizedStaticcall)
    (h : LidoSRv3.Audit.Source.ReserveUnfinalizedCall.liveUnfinalizedStETH c = none) :
    ¬ LidoSRv3.Audit.Source.ReserveUnfinalizedCall.freshQueueCacheFromCall state c :=
  LidoSRv3.Audit.Source.ReserveUnfinalizedCall.failed_call_not_fresh state c h

/-- Under a well-formed STATICCALL, the derived freshness
`freshQueueCacheFromCall` is equivalent to `freshQueueCache` at the
decoded word.  Re-export of `Source.ReserveUnfinalizedCall.success_fresh_iff`. -/
theorem reserve_staticcall_fresh_iff
    (state : ReserveState)
    (c : LidoSRv3.Audit.Source.ReserveUnfinalizedCall.UnfinalizedStaticcall)
    (w : Word)
    (h : LidoSRv3.Audit.Source.ReserveUnfinalizedCall.liveUnfinalizedStETH c =
      some w) :
    LidoSRv3.Audit.Source.ReserveUnfinalizedCall.freshQueueCacheFromCall state c ↔
      freshQueueCache state w :=
  LidoSRv3.Audit.Source.ReserveUnfinalizedCall.success_fresh_iff state c w h

end LidoSRv3.Audit.Guarantees.PReserve1
