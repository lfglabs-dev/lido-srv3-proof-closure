import LidoSRv3.Audit.Source.TrioAlloc1.EnumerationWriter

/-!
Kill-lines pinning `TrioAlloc1.EnumerationWriter.insert` semantics:
idSlot injectivity, existing-noop, oversized-absent Panic(0x41).
-/

namespace LidoSRv3.Tests.SourceTrioAlloc1EnumerationWriterKillLines

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1.EnumerationWriter

/-! ## `idSlot_injective` — the slot keccak base is injective on
    (i, j) below 2^256. -/

theorem idSlot_injective_restated
    (l : Layout) (i j : Nat) (hi : i < 2^256) (hj : j < 2^256)
    (equal : idSlot l i = idSlot l j) : i = j :=
  idSlot_injective l i j hi hj equal

/-! ## `existing_noop` — inserting a present id is a no-op. -/

theorem existing_noop_restated
    (l : Layout) (s : Storage) (id : Word)
    (present : (s (ShareWriter.modulePositionSlot l id)).val ≠ 0) :
    insert l s id = .ok s :=
  existing_noop l s id present

/-! ## `oversized_absent` — EnumerableSet.length overflow panics. -/

theorem oversized_absent_restated
    (l : Layout) (s : Storage) (id : Word)
    (absent : (s (ShareWriter.modulePositionSlot l id)).val = 0)
    (bound : 2^64 ≤ (s (countSlot l)).val) :
    insert l s id = .error (.panic 0x41) :=
  oversized_absent l s id absent bound

end LidoSRv3.Tests.SourceTrioAlloc1EnumerationWriterKillLines
