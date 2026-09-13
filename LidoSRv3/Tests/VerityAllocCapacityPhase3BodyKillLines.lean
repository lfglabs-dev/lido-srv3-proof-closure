import LidoSRv3.Audit.Verity.AllocCapacityPhase3

/-!
Kill-lines pinning `Verity.AllocCapacityPhase3` selector byte decomposition,
canonical parameter list, canonical field list, and source summary site
constructor shape. These pin the byte-level ABI of the mapped
`SRLib._getStakingModuleSummary` static call.
-/

namespace LidoSRv3.Tests.VerityAllocCapacityPhase3BodyKillLines

open LidoSRv3.Audit.Verity.AllocCapacityPhase3
open Compiler.CompilationModel.DenoteExternalCalls

/-! ## `selectorByte` — byte-slicing of `0x9abddf09`. -/

theorem selectorByte_0 : selectorByte 0 = 0x9a := rfl
theorem selectorByte_1 : selectorByte 1 = 0xbd := rfl
theorem selectorByte_2 : selectorByte 2 = 0xdf := rfl
theorem selectorByte_3 : selectorByte 3 = 0x09 := rfl
theorem selectorByte_4 : selectorByte 4 = 0 := rfl

theorem summaryCalldata_bytes :
    summaryCalldata = [0x9a, 0xbd, 0xdf, 0x09] := rfl

theorem summaryCalldata_length :
    summaryCalldata.length = 4 := rfl

theorem summarySelector_val :
    summarySelector = 0x9abddf09 := rfl

theorem entrySelector_val :
    entrySelector = 0x6a70ca02 := rfl

theorem summaryReturnBytes_val :
    summaryReturnBytes = 96 := rfl

/-! ## `sourceParameters` — the three input names/types. -/

theorem sourceParameters_length :
    sourceParameters.length = 3 := rfl

theorem sourceParameters_head_depositable :
    (sourceParameters.head?).map Compiler.CompilationModel.Param.name =
      some "depositable" := rfl

theorem sourceParameters_names :
    sourceParameters.map Compiler.CompilationModel.Param.name =
      ["depositable", "moduleId", "moduleAddress"] := rfl

/-! ## `canonicalFields` — single storage field `lastCapacity`. -/

theorem canonicalFields_length :
    canonicalFields.length = 1 := rfl

theorem canonicalFields_name :
    canonicalFields.map Compiler.CompilationModel.Field.name =
      ["lastCapacity"] := rfl

/-! ## `sourceSummarySite` — the mapped staticcall shape. -/

theorem sourceSummarySite_siteId (moduleAddress : Nat) :
    (sourceSummarySite moduleAddress).siteId = 0 := rfl

theorem sourceSummarySite_kind (moduleAddress : Nat) :
    (sourceSummarySite moduleAddress).kind = CallKind.staticcall := rfl

theorem sourceSummarySite_value (moduleAddress : Nat) :
    (sourceSummarySite moduleAddress).value = 0 := rfl

theorem sourceSummarySite_calldata (moduleAddress : Nat) :
    (sourceSummarySite moduleAddress).calldata = summaryCalldata := rfl

theorem sourceSummarySite_gas (moduleAddress : Nat) :
    (sourceSummarySite moduleAddress).gas = maxGas := rfl

/-! ## `spec` — top-level compilation-model declarations. -/

theorem spec_name : spec.name = "PAlloc1ConsumedSummaryPhase3" := rfl

theorem spec_fields_equals_canonical :
    spec.fields = canonicalFields := rfl

theorem spec_functions_equals_one_entry :
    spec.functions = [consumedSummaryEntry] := rfl

end LidoSRv3.Tests.VerityAllocCapacityPhase3BodyKillLines
