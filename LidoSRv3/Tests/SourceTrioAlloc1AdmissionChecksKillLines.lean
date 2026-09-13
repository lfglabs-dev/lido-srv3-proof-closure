import LidoSRv3.Audit.Source.TrioAlloc1.AdmissionChecks

/-!
Kill-lines pinning `TrioAlloc1.AdmissionChecks` `nextId` uint24
arithmetic behavior (SRLib.sol:208) and `scan_success_iff` semantic
correspondence.
-/

namespace LidoSRv3.Tests.SourceTrioAlloc1AdmissionChecksKillLines

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1.AdmissionChecks

/-! ## `lastIdSlot` reduces to routerSlot + 5. -/

theorem lastIdSlot_reduces (l : Layout) :
    lastIdSlot l = word (l.routerSlot.val + 5) := rfl

/-! ## `scan_success_iff` — freshness ↔ pass. -/

theorem scan_success_iff_restated
    (l : Layout) (s : Storage) (address : Address) (n i : Nat) :
    scan l s address n i = .ok () ↔
      ∀ j, i ≤ j → j < i+n →
        (readModule l s j).identity.moduleAddress ≠ address :=
  scan_success_iff l s address n i

/-! ## `nextId_success` — bounds on returned id. -/

theorem nextId_success_restated
    (l : Layout) (s : Storage) (id : Word)
    (run : nextId l s = .ok id) :
    id.val = field (s (lastIdSlot l)) 0 24 + 1 ∧
      0 < id.val ∧ id.val < 2^24 :=
  nextId_success l s id run

/-! ## `nextId_overflow` — Panic(0x11) on maxed uint24. -/

theorem nextId_overflow_restated
    (l : Layout) (s : Storage)
    (maximal : field (s (lastIdSlot l)) 0 24 = 2^24-1) :
    nextId l s = .error (.panic 0x11) :=
  nextId_overflow l s maximal

end LidoSRv3.Tests.SourceTrioAlloc1AdmissionChecksKillLines
