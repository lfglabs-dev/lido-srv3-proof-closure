import LidoSRv3.Audit.Guarantees.PAlloc1Phase3

/-!
Kill-lines pinning `Guarantees.PAlloc1Phase3` re-exports of the
Phase-3 constants (`summaryCalldata`, `summaryReturnBytes`,
`entrySelector`) and lastCapacitySlot slot.
-/

namespace LidoSRv3.Tests.GuaranteesPAlloc1Phase3KillLines

open LidoSRv3.Audit.Verity.AllocCapacityPhase3

/-! ## Concrete four-byte selector pin. -/

theorem summaryCalldata_pinned :
    summaryCalldata = [0x9a, 0xbd, 0xdf, 0x09] := rfl

theorem summaryCalldata_length_pinned :
    summaryCalldata.length = 4 := rfl

theorem summaryReturnBytes_pinned :
    summaryReturnBytes = 96 := rfl

theorem entrySelector_pinned :
    entrySelector = 0x6a70ca02 := rfl

theorem summarySelector_pinned :
    summarySelector = 0x9abddf09 := rfl

/-! ## lastCapacitySlot is slot 0 (only writable field of the Phase-3
    boundary). -/

theorem lastCapacitySlot_val : lastCapacitySlot.slot = 0 := rfl

end LidoSRv3.Tests.GuaranteesPAlloc1Phase3KillLines
