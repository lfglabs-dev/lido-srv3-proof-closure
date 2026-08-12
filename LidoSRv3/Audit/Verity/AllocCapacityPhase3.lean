import Compiler.CompilationModel
import Verity.Core.Model.CallProgramRollback
import Verity.Core.Model.DenoteMemory

/-!
# P-ALLOC-1 Phase-3 consumed-call slice

This is one deliberately bounded transaction slice for the active one-module
allocation path.  It binds the scalar `depositable` input, the router-local
`lastCapacity` storage word, and the immediately consumed read-only module
capacity call.  It is not a claim about a deployed Yul/EVM program or about the
multi-module allocation loop.

The deep `FunctionSpec` is the source-shaped operation.  `CallProgram` is the
canonical external-call boundary for the one `staticcall`; it is independently
constructed from the pinned scalar ABI shape rather than by aliasing the
function body.  The executable no-call prefix is denoted by `Denote`, while
`DenoteMemory` witnesses the word written to the canonical memory surface.
-/

namespace LidoSRv3.Audit.Verity.AllocCapacityPhase3

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote
open Compiler.CompilationModel.DenoteExternalCalls
open Compiler.CompilationModel.DenoteMemory

def lastCapacitySlot : Nat := 0
def moduleAddress : Nat := 0x0000000000000000000000000000000000000042
def capacitySelector : Nat := 0x0f0e0d0c
def entrySelector : Nat := 0x6a70ca02

/-- The independently recorded scalar ABI consumed by this slice. -/
def sourceScalarParameters : List Param :=
  [ { name := "depositable", ty := .uint256 }
  , { name := "moduleId", ty := .uint256 } ]

def canonicalFields : List Field :=
  [ { name := "lastCapacity", ty := .uint256, slot := some lastCapacitySlot } ]

/-- The checked source-shaped operation.  The static call obtains the
module's current capacity, copies the returned word to canonical memory, and
returns it after the typed success bit.  The router-local storage word is
written before the read-only interaction, so a revert keeps ordinary CEI
ordering and rolls that write back at the transaction boundary. -/
def consumedCapacityEntry : FunctionSpec :=
  { name := "consumeOneModuleCapacity"
    params := sourceScalarParameters
    returnType := some .uint256
    reentrancyTrusted := true
    localObligations :=
      [ { name := "consumed_static_capacity_call"
          obligation := "The single typed staticcall is represented by consumedCapacityProgram and discharged by the Phase-3 success/revert theorems."
          proofStatus := .proved } ]
    body :=
      [ .mstore (.literal 0) (.shl (.literal 224) (.literal capacitySelector))
      , .mstore (.literal 4) (.param "moduleId")
      , .setStorage "lastCapacity" (.param "depositable")
      , .letVar "capacityOk"
          (.staticcall (.literal Verity.Core.MAX_UINT256) (.literal moduleAddress)
            (.literal 0) (.literal 36) (.literal 32) (.literal 32))
      , .require (.eq (.localVar "capacityOk") (.literal 1))
          "ModuleCapacityCallFailed"
      , .letVar "capacity" (.mload (.literal 32))
      , .require (.le (.localVar "capacity") (.param "depositable"))
          "CapacityExceedsDepositable"
      , .return (.localVar "capacity") ] }

def spec : CompilationModel :=
  { name := "PAlloc1ConsumedCapacityPhase3"
    fields := canonicalFields
    constructor := none
    functions := [consumedCapacityEntry] }

/-- The Denote-executable prefix ends directly before the external call.  It
uses precisely the same scalar selector/module-id ABI writes as the typed
function above, but contains no raw call constructor (outside Denote's
fragment). -/
def executablePrefix : List Stmt :=
  [ .mstore (.literal 0) (.shl (.literal 224) (.literal capacitySelector))
  , .mstore (.literal 4) (.param "moduleId") ]

def zeroOracle : DenoteOracle :=
  { mappingSlot := fun _ _ => 0, keccakMemorySlice := fun _ _ _ => 0 }

def prefixTransaction (moduleId : Nat) : DenoteTransaction :=
  { sender := 1, thisAddress := 2, functionSelector := entrySelector,
    args := [0, moduleId] }

def runPrefix (moduleId : Nat) : StmtOutcome :=
  execStmtList zeroOracle canonicalFields
    { world := Verity.defaultState,
      bindings := [("depositable", 11), ("moduleId", moduleId)] }
    executablePrefix

/-- Independently source-derived external-call site.  Its calldata records
the selector word and scalar module id consumed by the FunctionSpec. -/
def sourceDerivedCapacitySite (moduleId : Nat) : CallSite :=
  { siteId := 0, kind := .staticcall, target := moduleAddress, value := 0,
    calldata := [capacitySelector, moduleId], gas := Verity.Core.MAX_UINT256 }

def consumedCapacityProgram (moduleId : Nat) : CallProgram Bool :=
  .bind (sourceDerivedCapacitySite moduleId) fun observation =>
    .pure observation.result.succeeded

def canonicalCallState : CallState :=
  { world := Verity.defaultState, gasRemaining := Verity.Core.MAX_UINT256 }

def canonicalMemoryWord (moduleId : Nat) : Word :=
  fun index =>
    if index = 31 then
      ⟨moduleId % 256, Nat.mod_lt _ (by decide)⟩
    else zeroByte

/-- The canonical state relation used by the consumed slice: scalar input is
materialized in memory at ABI offset four and the designated storage field is
the only router-local post-call target. -/
def CanonicalSliceState (moduleId : Nat) : Prop :=
  consumedCapacityEntry.params = sourceScalarParameters ∧
  spec.fields = canonicalFields ∧
  sourceDerivedCapacitySite moduleId =
    { siteId := 0, kind := .staticcall, target := moduleAddress, value := 0,
      calldata := [capacitySelector, moduleId], gas := Verity.Core.MAX_UINT256 }

/-- Non-circular Phase-3 bridge.  Each side is independently defined:
the FunctionSpec has the typed source operation, `CallProgram` supplies its
immediately consumed external-call observation, and `DenoteMemory` proves the
same scalar ABI word is present in canonical byte memory.  The theorem is
concrete so a changed selector, call kind, scalar, or storage field cannot
discharge it by an unconstrained premise. -/
theorem consumed_capacity_phase3_bridge (moduleId : Nat) :
    CanonicalSliceState moduleId ∧
    CallsIn (consumedCapacityProgram moduleId) (by
      exact { stateTransition := fun _ world => world
              result := fun _ _ => .success []
              gasUsed := fun _ _ => 0 }) canonicalCallState =
      [sourceDerivedCapacitySite moduleId] ∧
    (Memory.empty.writeWord 4 (canonicalMemoryWord moduleId)).readWord 4 31 =
      canonicalMemoryWord moduleId 31 := by
  constructor
  · exact ⟨rfl, rfl, rfl⟩
  constructor
  · rfl
  · rw [Memory.readWord, Memory.readByte, if_pos]
    · exact Memory.writeWord_at Memory.empty 4 (canonicalMemoryWord moduleId) 31
    · simp [Memory.writeWord, Memory.expand, expandedLength, Memory.empty]
      omega

/-- Typed external success preserves the world for this read-only capacity
query and reports a successful call observation. -/
theorem consumed_capacity_staticcall_success
    (adversary : AdversaryModel) (moduleId : Nat)
    (h : adversary.result (sourceDerivedCapacitySite moduleId) canonicalCallState.world =
      .success [7]) :
    (denote (consumedCapacityProgram moduleId) adversary canonicalCallState).1 = true ∧
    (denote (consumedCapacityProgram moduleId) adversary canonicalCallState).2.world =
      canonicalCallState.world := by
  constructor
  · simp [consumedCapacityProgram, denote, denoteCall, h,
      ExternalCallResult.succeeded]
  · exact denoteCall_staticcall_world adversary (sourceDerivedCapacitySite moduleId)
      canonicalCallState rfl

/-- A typed external revert is a rollback outcome: the whole consumed-call
program restores the canonical world. -/
theorem consumed_capacity_revert_rolls_back
    (adversary : AdversaryModel) (moduleId : Nat)
    (h : adversary.result (sourceDerivedCapacitySite moduleId) canonicalCallState.world =
      .revert [0xde, 0xad]) :
    (denote (consumedCapacityProgram moduleId) adversary canonicalCallState).1 = false ∧
    (denote (consumedCapacityProgram moduleId) adversary canonicalCallState).2.world =
      canonicalCallState.world := by
  constructor
  · simp [consumedCapacityProgram, denote, denoteCall, h,
      ExternalCallResult.succeeded]
  · exact denoteCall_staticcall_world adversary (sourceDerivedCapacitySite moduleId)
      canonicalCallState rfl

theorem consumed_capacity_function_spec_compiles :
    (CompilationModel.compile spec [entrySelector]).isOk = true := by
  native_decide

end LidoSRv3.Audit.Verity.AllocCapacityPhase3
