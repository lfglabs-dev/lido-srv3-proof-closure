import LidoSRv3.Audit.Source.ReserveUnfinalizedCall

/-!
Kill-lines pinning `Source.ReserveUnfinalizedCall` STATICCALL
observation, `liveUnfinalizedStETH` gate, and the four `live_requires_*`
witness theorems.
-/

namespace LidoSRv3.Tests.SourceReserveUnfinalizedCallLiveKillLines

open LidoSRv3.Audit.SolidityReserve
open LidoSRv3.Audit.Source.ReserveUnfinalizedCall

/-! ## `unfinalizedStETHSelector` — the pinned 4-byte selector. -/

theorem unfinalizedStETHSelector_val :
    unfinalizedStETHSelector = 0xd0fb84e8 := rfl

/-! ## `abiWord` shape — 32-byte return payload of small Nats. -/

theorem abiWord_length_restated (n : Nat) :
    (abiWord n).length = 32 :=
  abiWord_length n

theorem abiWord_zero_first_byte :
    (abiWord 0).head? = some 0 := rfl

/-! ## `UnfinalizedStaticcall` — four-field structure. -/

private def wellFormed : UnfinalizedStaticcall :=
  { success := true, returndata := abiWord 42
    value := 0, selector := unfinalizedStETHSelector }

theorem wellFormed_success : wellFormed.success = true := rfl
theorem wellFormed_value : wellFormed.value = 0 := rfl
theorem wellFormed_selector :
    wellFormed.selector = unfinalizedStETHSelector := rfl

/-! ## `liveUnfinalizedStETH` — a well-formed call yields some. -/

theorem liveUnfinalizedStETH_wellFormed :
    (liveUnfinalizedStETH wellFormed).isSome = true := by decide

/-! ## Wrong selector → none. -/

private def wrongSelector : UnfinalizedStaticcall :=
  { wellFormed with selector := 0xDEADBEEF }

theorem liveUnfinalizedStETH_wrong_selector :
    liveUnfinalizedStETH wrongSelector = none := by decide

/-! ## Nonzero value → none. -/

private def withValue : UnfinalizedStaticcall :=
  { wellFormed with value := 1 }

theorem liveUnfinalizedStETH_nonzero_value :
    liveUnfinalizedStETH withValue = none := by decide

/-! ## Failed call → none. -/

private def failedCall : UnfinalizedStaticcall :=
  { wellFormed with success := false }

theorem liveUnfinalizedStETH_failed :
    liveUnfinalizedStETH failedCall = none := by decide

/-! ## Wrong return-length → none. -/

private def wrongLength : UnfinalizedStaticcall :=
  { wellFormed with returndata := [0, 0] }

theorem liveUnfinalizedStETH_short :
    liveUnfinalizedStETH wrongLength = none := by decide

/-! ## `live_requires_*` witness theorems restated. -/

theorem live_requires_selector_restated
    (c : UnfinalizedStaticcall) {w : LidoSRv3.Audit.Source.ReserveUnfinalizedCall.Word}
    (h : liveUnfinalizedStETH c = some w) :
    c.selector = unfinalizedStETHSelector :=
  live_requires_selector c h

theorem live_requires_zero_value_restated
    (c : UnfinalizedStaticcall) {w : LidoSRv3.Audit.Source.ReserveUnfinalizedCall.Word}
    (h : liveUnfinalizedStETH c = some w) :
    c.value = 0 :=
  live_requires_zero_value c h

theorem live_requires_success_restated
    (c : UnfinalizedStaticcall) {w : LidoSRv3.Audit.Source.ReserveUnfinalizedCall.Word}
    (h : liveUnfinalizedStETH c = some w) :
    c.success = true :=
  live_requires_success c h

theorem live_requires_32_bytes_restated
    (c : UnfinalizedStaticcall) {w : LidoSRv3.Audit.Source.ReserveUnfinalizedCall.Word}
    (h : liveUnfinalizedStETH c = some w) :
    c.returndata.length = 32 :=
  live_requires_32_bytes c h

end LidoSRv3.Tests.SourceReserveUnfinalizedCallLiveKillLines
