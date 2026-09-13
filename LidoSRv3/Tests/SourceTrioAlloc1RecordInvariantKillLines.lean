import LidoSRv3.Audit.Source.TrioAlloc1.RecordInvariant

/-!
Kill-lines pinning `TrioAlloc1.RecordInvariant.SameReads` frame
preservation and `share_preserves` / `parameter_preserves` /
`admission_preserves` witness theorems.
-/

namespace LidoSRv3.Tests.SourceTrioAlloc1RecordInvariantKillLines

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1.RecordInvariant
open LidoSRv3.Audit.Source.TrioAlloc1.AdmissionFacts

/-! ## `preserves` — same-reads frame preserves fresh records. -/

theorem preserves_restated
    (l : Layout) (before after : Storage)
    (records : FreshRecords l before)
    (frame : SameReads l before after) :
    FreshRecords l after :=
  preserves l before after records frame

/-! ## `share_preserves` — restated. -/

theorem share_preserves_restated
    (l : Layout) (s : Storage) (input : ShareWriter.Input)
    (records : FreshRecords l s)
    (separate : SeparateFrom l s (moduleSlot l input.moduleId)) :
    FreshRecords l (ShareWriter.execute l s input).storage :=
  share_preserves l s input records separate

/-! ## `parameter_preserves` — restated. -/

theorem parameter_preserves_restated
    (l : Layout) (s : Storage) (input : ParameterWriter.Input)
    (records : FreshRecords l s)
    (config : SeparateFrom l s (moduleSlot l input.moduleId))
    (deposit : SeparateFrom l s (word ((moduleSlot l input.moduleId).val+1))) :
    FreshRecords l (ParameterWriter.execute l s input).storage :=
  parameter_preserves l s input records config deposit

end LidoSRv3.Tests.SourceTrioAlloc1RecordInvariantKillLines
