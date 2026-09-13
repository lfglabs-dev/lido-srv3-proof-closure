import LidoSRv3.Audit.Source.TrioAlloc1.AdmissionFacts

/-!
Kill-lines pinning `TrioAlloc1.AdmissionFacts` `nameSlot`,
`success_id_bounds`, and `success_stored_share` witness identities
for the P-ALLOC-1 admission writer.
-/

namespace LidoSRv3.Tests.SourceTrioAlloc1AdmissionFactsKillLines

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1.AdmissionFacts

/-! ## `nameSlot` reduces to moduleSlot offset by 3. -/

theorem nameSlot_reduces (l : Layout) (id : Word) :
    nameSlot l id = word ((moduleSlot l id).val + 3) := rfl

/-! ## `success_id_bounds` — restated. -/

theorem success_id_bounds_restated
    (l : Layout) (s : Storage) (input : AdmissionWriter.Input)
    (success : AdmissionWriter.Success)
    (run : AdmissionWriter.stages l s input = .ok success) :
    success.id.val =
      field (s (AdmissionChecks.lastIdSlot l)) 0 24 + 1 ∧
    0 < success.id.val ∧ success.id.val < 2^24 :=
  success_id_bounds l s input success run

/-! ## `success_stored_share` — restated. -/

theorem success_stored_share_restated
    (l : Layout) (s : Storage) (input : AdmissionWriter.Input)
    (success : AdmissionWriter.Success)
    (run : AdmissionWriter.stages l s input = .ok success)
    (lastSeparate : moduleSlot l success.id ≠ AdmissionChecks.lastIdSlot l) :
    field (success.storage (moduleSlot l success.id)) 192 16 ≤ 10000 :=
  success_stored_share l s input success run lastSeparate

end LidoSRv3.Tests.SourceTrioAlloc1AdmissionFactsKillLines
