import LidoSRv3.Audit.Source.ReserveUnfinalizedCall

/-! P-RESERVE-1 live unfinalizedStETH STATICCALL vectors. -/

namespace LidoSRv3.Tests.ReserveUnfinalizedCallMutants

open LidoSRv3.Audit.SolidityReserve
open LidoSRv3.Audit.Source.ReserveUnfinalizedCall

private def word (n : Nat) : LidoSRv3.Audit.Source.ReserveUnfinalizedCall.Word :=
  Verity.Core.Uint256.ofNat n

private def okCall (n : Nat) : UnfinalizedStaticcall where
  success := true
  returndata := abiWord n
  value := 0
  selector := unfinalizedStETHSelector

private def failCall : UnfinalizedStaticcall := { okCall 50 with success := false }
private def wrongSelector : UnfinalizedStaticcall :=
  { okCall 50 with selector := 0x2b95b781 }
private def payableCall : UnfinalizedStaticcall := { okCall 50 with value := 1 }
private def shortCall : UnfinalizedStaticcall := { okCall 50 with returndata := [50] }

private def cache50 : ReserveState where
  buffered := word 100
  storedDepositsReserve := word 20
  unfinalizedStETH := word 50
  depositedPostReport := word 3
  depositedNextReportAdjusted := word 2

/-- Happy path: STATICCALL `0xd0fb84e8`, value 0, 32-byte `50` matches the
cache (Lido.sol:612 / WithdrawalQueueBase.sol:143-146). -/
example : liveUnfinalizedStETH (okCall 50) = some (word 50) := by native_decide

example : freshQueueCacheFromCall cache50 (okCall 50) :=
  (success_fresh_iff cache50 (okCall 50) (word 50) (by native_decide)).mpr rfl

/-- Failed STATICCALL cannot witness freshness. -/
example : liveUnfinalizedStETH failCall = none := by native_decide

example : ¬ freshQueueCacheFromCall cache50 failCall :=
  failed_call_not_fresh cache50 failCall (by native_decide)

/-- Wrong selector is not `unfinalizedStETH()`. -/
example : liveUnfinalizedStETH wrongSelector = none := by native_decide

/-- Nonzero value is not a view STATICCALL. -/
example : liveUnfinalizedStETH payableCall = none := by native_decide

/-- Short returndata fails ABI uint256 decode. -/
example : liveUnfinalizedStETH shortCall = none := by native_decide

/-- Stale cache: live decode is 80, cached field is 50. -/
example : liveUnfinalizedStETH (okCall 80) = some (word 80) := by native_decide

example : ¬ freshQueueCacheFromCall cache50 (okCall 80) := by
  intro hf
  have h : freshQueueCache cache50 (word 80) :=
    (success_fresh_iff cache50 (okCall 80) (word 80) (by native_decide)).mp hf
  simp [freshQueueCache, cache50, word] at h
  exact absurd (congrArg Verity.Core.Uint256.val h) (by decide)

#print axioms LidoSRv3.Audit.Source.ReserveUnfinalizedCall.spend_preserves_from_live_call
#print axioms LidoSRv3.Audit.Source.ReserveUnfinalizedCall.failed_call_not_fresh
#print axioms LidoSRv3.Audit.Source.ReserveUnfinalizedCall.decode_abiWord_small

end LidoSRv3.Tests.ReserveUnfinalizedCallMutants
