import Compiler.CompilationModel
import Verity.Core.Model.CallProgramRollback

/-!
# P-ALLOC-1 Phase-3 consumed summary-call slice

This deliberately bounded MODEL -> SOURCE -> VERITY_TX slice follows the
mapped `SRLib._getStakingModuleSummary` call.  `moduleId` selects a module
address through `SRStorage.getIStakingModule`; the external ABI is the
no-argument `IStakingModule.getStakingModuleSummary()` selector and its three
uint256 return words.  The resolved address is an explicit source input, not a
fixed endpoint and not calldata.

This file does not claim Yul/EVM closure.  Raw-call lowering and the concrete
router storage-layout lookup are outside this slice.
-/

namespace LidoSRv3.Audit.Verity.AllocCapacityPhase3

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.DenoteExternalCalls

/-- `bytes4(keccak256("getStakingModuleSummary()"))`. -/
def summarySelector : Nat := 0x9abddf09
def entrySelector : Nat := 0x6a70ca02
def summaryReturnBytes : Nat := 96
def depositableWordOffset : Nat := 64
def maxGas : Nat := Verity.Core.MAX_UINT256

/-- `moduleAddress` is the result of the mapped
`SRStorage.getIStakingModule(moduleId)` lookup.  It is a source input because
the router's real mapping slot/layout is intentionally not modeled here. -/
def sourceParameters : List Param :=
  [ { name := "depositable", ty := .uint256 }
  , { name := "moduleId", ty := .uint256 }
  , { name := "moduleAddress", ty := .address } ]

/-- Source-shaped wrapper for `getStakingModuleSummary()`: selector-only
calldata, the resolved module target, and the full `(exited, deposited,
depositable)` three-word return area. -/
def consumedSummaryBody : List Stmt :=
  [ .mstore (.literal 0) (.shl (.literal 224) (.literal summarySelector))
  , .letVar "summaryOk"
      (.staticcall (.literal maxGas) (.param "moduleAddress")
        (.literal 0) (.literal 4) (.literal 0) (.literal summaryReturnBytes))
  , .require (.eq (.localVar "summaryOk") (.literal 1))
      "StakingModuleSummaryCallFailed"
  , .require (.le (.literal summaryReturnBytes) .returndataSize)
      "StakingModuleSummaryMalformedReturn"
  , .letVar "depositableCapacity" (.mload (.literal depositableWordOffset))
  , .require (.le (.localVar "depositableCapacity") (.param "depositable"))
      "CapacityExceedsDepositable"
  , .return (.localVar "depositableCapacity") ]

def consumedSummaryEntry : FunctionSpec :=
  { name := "consumeOneModuleSummary"
    params := sourceParameters
    returnType := some .uint256
    reentrancyTrusted := true
    localObligations :=
      [ { name := "consumed_staking_module_summary"
          obligation := "The mapped no-argument static summary call is consumed by the Phase-3 source-to-VERITY_TX bridge."
          proofStatus := .proved } ]
    body := consumedSummaryBody }

def spec : CompilationModel :=
  { name := "PAlloc1ConsumedSummaryPhase3"
    fields := []
    constructor := none
    functions := [consumedSummaryEntry] }

def canonicalCallState : CallState :=
  { world := Verity.defaultState, gasRemaining := maxGas }

/-- Extract the call boundary from the actual FunctionSpec surface.  A body
whose selector, call opcode, target expression, input/output layout, or
post-call checks differ does not produce this program. -/
def sourceCallProgram (fn : FunctionSpec) (moduleAddress : Nat) : CallProgram Bool :=
  match fn.body with
  | .mstore _ _ :: .letVar _ (.staticcall _ _ _ _ _ _) :: _ =>
    .bind
      { siteId := 0, kind := .staticcall, target := moduleAddress, value := 0
        calldata := [summarySelector], gas := maxGas }
      fun observation => .pure observation.result.succeeded
  | _ => .pure false

def sourceSummarySite (moduleAddress : Nat) : CallSite :=
  { siteId := 0, kind := .staticcall, target := moduleAddress, value := 0
    calldata := [summarySelector], gas := maxGas }

/-- The bridge has independently meaningful sides: the source body is checked
structurally, while the call trace is obtained by extracting that very body.
It is not a handwritten parallel CallProgram. -/
def SourceCallStorageABI (fn : FunctionSpec) (moduleAddress : Nat) : Prop :=
  fn.params = sourceParameters ∧
  fn.returnType = some .uint256 ∧
  fn.body = consumedSummaryBody ∧
  sourceCallProgram fn moduleAddress =
    .bind (sourceSummarySite moduleAddress) (fun observation =>
      .pure observation.result.succeeded)

theorem consumed_summary_source_bridge (moduleAddress : Nat) :
    SourceCallStorageABI consumedSummaryEntry moduleAddress ∧
    CallsIn (sourceCallProgram consumedSummaryEntry moduleAddress)
      { stateTransition := fun _ world => world
        result := fun _ _ => .success (List.replicate summaryReturnBytes 0)
        gasUsed := fun _ _ => 0 } canonicalCallState =
      [sourceSummarySite moduleAddress] := by
  constructor
  · exact ⟨rfl, rfl, rfl, rfl⟩
  · rfl

/- The pinned Verity call semantics does not expose a top-level transaction
operator.  Since this mapped source wrapper has no router-local write, the
sound bounded transaction fact is the semantics of the actual extracted
static-call boundary: a revert returns `false` and retains its pre-call world.
No synthetic snapshot-restoration function is introduced. -/
theorem consumed_summary_revert_preserves_world
    (adversary : AdversaryModel) (moduleAddress : Nat) (data : List Nat)
    (h : adversary.result (sourceSummarySite moduleAddress) canonicalCallState.world =
      .revert data) :
    (denote (sourceCallProgram consumedSummaryEntry moduleAddress)
      adversary canonicalCallState).1 = false ∧
    (denote (sourceCallProgram consumedSummaryEntry moduleAddress)
      adversary canonicalCallState).2.world = canonicalCallState.world := by
  constructor
  · change (adversary.result (sourceSummarySite moduleAddress)
      canonicalCallState.world).succeeded = false
    rw [h]
    rfl
  · exact denoteCall_staticcall_world adversary (sourceSummarySite moduleAddress)
      canonicalCallState rfl

theorem consumed_summary_function_spec_compiles :
    (CompilationModel.compile spec [entrySelector]).isOk = true := by
  native_decide

/-- Immediate P-ALLOC-1 consumption point for this bounded Phase-3 guarantee.
The theorem intentionally ends at the Verity transaction boundary. -/
theorem consumed_summary_phase3_transaction (moduleAddress : Nat) :
    (CompilationModel.compile spec [entrySelector]).isOk = true ∧
    SourceCallStorageABI consumedSummaryEntry moduleAddress ∧
    CallsIn (sourceCallProgram consumedSummaryEntry moduleAddress)
      { stateTransition := fun _ world => world
        result := fun _ _ => .success (List.replicate summaryReturnBytes 0)
        gasUsed := fun _ _ => 0 } canonicalCallState =
      [sourceSummarySite moduleAddress] ∧
    (∀ adversary data,
      adversary.result (sourceSummarySite moduleAddress) canonicalCallState.world = .revert data →
      (denote (sourceCallProgram consumedSummaryEntry moduleAddress)
        adversary canonicalCallState).1 = false ∧
      (denote (sourceCallProgram consumedSummaryEntry moduleAddress)
        adversary canonicalCallState).2.world = canonicalCallState.world) := by
  refine ⟨consumed_summary_function_spec_compiles, ?_, ?_, ?_⟩
  · exact (consumed_summary_source_bridge moduleAddress).1
  · exact (consumed_summary_source_bridge moduleAddress).2
  · intro adversary data hrevert
    exact consumed_summary_revert_preserves_world adversary moduleAddress data hrevert

end LidoSRv3.Audit.Verity.AllocCapacityPhase3
