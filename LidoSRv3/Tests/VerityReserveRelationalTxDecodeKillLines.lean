import LidoSRv3.Audit.Verity.ReserveRelationalTx

/-!
Kill-lines pinning `Verity.ReserveRelationalTx` `Decoded` structure
extraction and `memoryFor` calldata-layout identity.
-/

namespace LidoSRv3.Tests.VerityReserveRelationalTxDecodeKillLines

open LidoSRv3.Audit.Verity.ReserveRelationalTx

private def d0 : Decoded :=
  { ids := [1, 2, 3]
    selected := []
    lastFinalized := 0
    paused := false
    buffer := 100
    locked := 50 }

/-! ## `Decoded` six-field extraction. -/

theorem decoded_ids : d0.ids = [1, 2, 3] := rfl
theorem decoded_selected : d0.selected = [] := rfl
theorem decoded_lastFinalized : d0.lastFinalized = 0 := rfl
theorem decoded_paused : d0.paused = false := rfl
theorem decoded_buffer : d0.buffer = 100 := rfl
theorem decoded_locked : d0.locked = 50 := rfl

theorem decoded_decEq_self : (decide (d0 = d0)) = true := by decide

/-! ## `memoryFor` — out-of-range offset returns zero. -/

theorem memoryFor_before_base :
    memoryFor [1, 2, 3] 0 = 0 := by
  simp [memoryFor, batchEndsBase]

theorem memoryFor_after_range :
    memoryFor [1, 2, 3] (batchEndsBase + 32 * 3) = 0 := by
  simp [memoryFor]

/-! ## `memoryFor` — misaligned offset (base+16) returns zero. -/

theorem memoryFor_misaligned :
    memoryFor [1, 2, 3] (batchEndsBase + 16) = 0 := by
  simp [memoryFor]

end LidoSRv3.Tests.VerityReserveRelationalTxDecodeKillLines
