import LidoSRv3.Audit.Source.ReserveUnfinalizedCall

/-! # Kill-lines for `ReserveUnfinalizedCall` selector / decoding

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned `WithdrawalQueue.unfinalizedStETH()` STATICCALL
semantics.**

`ReserveUnfinalizedCall` names:
- `unfinalizedStETHSelector = 0xd0fb84e8` (4-byte selector).
- `decodeWord32` requires exactly 32 bytes.
- `liveUnfinalizedStETH` succeeds iff selector + value 0 + success +
  32 bytes.

These kill-lines pin the selector value and demonstrate wrong-shape
STATICCALLs are rejected. -/

namespace LidoSRv3.Tests.ReserveUnfinalizedCallSelectorKillLines

open LidoSRv3.Audit.Source.ReserveUnfinalizedCall

/-- **Kill-line: pinned selector is exactly `0xd0fb84e8`.**

A mutant that used a different selector would fail this. -/
theorem unfinalizedStETHSelector_pinned :
    unfinalizedStETHSelector = 0xd0fb84e8 := rfl

/-- **Kill-line: `decodeWord32` returns `none` on wrong length.**

At a 31-byte input, decoding fails. -/
theorem decodeWord32_rejects_short :
    decodeWord32 (List.replicate 31 0) = none := by
  unfold decodeWord32
  decide

/-- **Kill-line: `decodeWord32` returns `none` on 33 bytes.** -/
theorem decodeWord32_rejects_long :
    decodeWord32 (List.replicate 33 0) = none := by
  unfold decodeWord32
  decide

/-- **Kill-line: `decodeWord32` accepts exactly 32 bytes and decodes.** -/
theorem decodeWord32_accepts_32 :
    decodeWord32 (List.replicate 32 0) = some (Verity.Core.Uint256.ofNat 0) := by
  unfold decodeWord32
  decide

/-- **Kill-line: `liveUnfinalizedStETH` rejects wrong selector.** -/
theorem liveUnfinalizedStETH_rejects_wrong_selector :
    liveUnfinalizedStETH
      { selector := 0xdeadbeef
        value := 0
        success := true
        returndata := List.replicate 32 0 } = none := by
  unfold liveUnfinalizedStETH
  decide

/-- **Kill-line: `liveUnfinalizedStETH` rejects nonzero value.** -/
theorem liveUnfinalizedStETH_rejects_nonzero_value :
    liveUnfinalizedStETH
      { selector := unfinalizedStETHSelector
        value := 1
        success := true
        returndata := List.replicate 32 0 } = none := by
  unfold liveUnfinalizedStETH
  decide

/-- **Kill-line: `liveUnfinalizedStETH` rejects failed call.** -/
theorem liveUnfinalizedStETH_rejects_failed :
    liveUnfinalizedStETH
      { selector := unfinalizedStETHSelector
        value := 0
        success := false
        returndata := List.replicate 32 0 } = none := by
  unfold liveUnfinalizedStETH
  decide

#print axioms unfinalizedStETHSelector_pinned
#print axioms decodeWord32_rejects_short
#print axioms decodeWord32_rejects_long
#print axioms decodeWord32_accepts_32
#print axioms liveUnfinalizedStETH_rejects_wrong_selector
#print axioms liveUnfinalizedStETH_rejects_nonzero_value
#print axioms liveUnfinalizedStETH_rejects_failed

end LidoSRv3.Tests.ReserveUnfinalizedCallSelectorKillLines
