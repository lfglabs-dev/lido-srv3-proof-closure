import Compiler.CompilationModel
import Verity.Core
import Verity.Core.Model.CallProgramRollback
import Verity.Core.Model.DenoteMemory
import Verity.Macro
import Contracts.Common

/-!
# P-ALLOC-1 Phase-3 consumed summary-call slice

This bounded MODEL -> SOURCE -> VERITY_TX slice follows the mapped
`SRLib._getStakingModuleSummary` call.  It proves the byte-level selector ABI,
the source-shaped pre-call storage transition, and transaction rollback of that
transition in Verity's executable `Contract.run` model.  It does not claim Yul,
EVM, deployed storage layout, or a full allocation-loop refinement.
-/

namespace LidoSRv3.Audit.Verity.AllocCapacityPhase3

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.DenoteExternalCalls
open Compiler.CompilationModel.DenoteMemory

/-- `bytes4(keccak256("getStakingModuleSummary()"))`. -/
def summarySelector : Nat := 0x9abddf09
/-- The selector is the sole canonical ABI representation.  Both the call
payload and the staged `mstore` word below are computed from it, so changing
the selector changes the checked source/program/memory bridge. -/
def selectorByte (index : Nat) : Nat :=
  match index with
  | 0 => (summarySelector / 0x1000000) % 0x100
  | 1 => (summarySelector / 0x10000) % 0x100
  | 2 => (summarySelector / 0x100) % 0x100
  | 3 => summarySelector % 0x100
  | _ => 0

def summaryCalldata : List Nat := [selectorByte 0, selectorByte 1, selectorByte 2, selectorByte 3]
def entrySelector : Nat := 0x6a70ca02
def summaryReturnBytes : Nat := 96
def maxGas : Nat := Verity.Core.MAX_UINT256

/-- The exact selector word staged by `mstore(0, bytes4 << 224)`, derived
from the same selector used by the source expression and calldata. -/
def summarySelectorWord : Word := fun index =>
  if index < 4 then ⟨selectorByte index, by simp [selectorByte]; split <;> omega⟩ else zeroByte

/-- `moduleAddress` is the mapped `SRStorage.getIStakingModule(moduleId)`
result.  The mapping layout is deliberately outside this bounded slice. -/
def sourceParameters : List Param :=
  [ { name := "depositable", ty := .uint256 }
  , { name := "moduleId", ty := .uint256 }
  , { name := "moduleAddress", ty := .address } ]

def canonicalFields : List Compiler.CompilationModel.Field :=
  [ Compiler.CompilationModel.Field.mk "lastCapacity" .uint256 false (some 0) none [] ]

/-- Source-shaped wrapper: its model-local pre-call store makes the rollback
claim non-vacuous. `lastCapacity` is not asserted to be a deployed router slot. -/
def consumedSummaryBody : List Stmt :=
  [ .mstore (.literal 0) (.shl (.literal 224) (.literal summarySelector))
  , .setStorage "lastCapacity" (.param "depositable")
  , .letVar "summaryOk"
      (.staticcall (.literal maxGas) (.param "moduleAddress")
        (.literal 0) (.literal 4) (.literal 0) (.literal summaryReturnBytes))
  , .require (.eq (.localVar "summaryOk") (.literal 1))
      "StakingModuleSummaryCallFailed"
  , .require (.le (.literal summaryReturnBytes) .returndataSize)
      "StakingModuleSummaryMalformedReturn"
  , .return (.literal 0) ]

def consumedSummaryEntry : FunctionSpec :=
  { name := "consumeOneModuleSummary"
    params := sourceParameters
    returnType := some .uint256
    reentrancyTrusted := true
    localObligations :=
      [ { name := "consumed_staking_module_summary"
          obligation := "The mapped selector-only static summary call and its typed success/revert result are consumed by the Phase-3 bridge."
          proofStatus := .proved } ]
    body := consumedSummaryBody }

def spec : Compiler.CompilationModel.CompilationModel :=
  Compiler.CompilationModel.CompilationModel.mk "PAlloc1ConsumedSummaryPhase3" 1
    canonicalFields [] [] [] [] none [consumedSummaryEntry] [] [] [] [] none

def canonicalCallState : CallState :=
  { world := Verity.defaultState, gasRemaining := maxGas }

/-- The call program is extracted only from the complete checked source body.
Changing the selector, store ordering, call kind, target expression, ABI sizes,
or post-call guards yields no call trace. -/
def sourceCallProgram (fn : FunctionSpec) (moduleAddress : Nat) : CallProgram Bool :=
  match fn.body with
  | [ .mstore (.literal 0) (.shl (.literal 224) (.literal selector))
    , .setStorage "lastCapacity" (.param "depositable")
    , .letVar "summaryOk"
        (.staticcall (.literal gas) (.param "moduleAddress")
          (.literal 0) (.literal inputBytes) (.literal 0) (.literal outputBytes))
    , .require (.eq (.localVar "summaryOk") (.literal 1))
        "StakingModuleSummaryCallFailed"
    , .require (.le (.literal returnBytes) .returndataSize)
        "StakingModuleSummaryMalformedReturn"
    , .return (.literal 0) ] =>
      if selector = summarySelector ∧ gas = maxGas ∧ inputBytes = 4 ∧
          outputBytes = summaryReturnBytes ∧ returnBytes = summaryReturnBytes then
        .bind
          { siteId := 0, kind := .staticcall, target := moduleAddress, value := 0
            calldata := summaryCalldata, gas := maxGas }
          fun observation => .pure observation.result.succeeded
      else .pure false
  | _ => .pure false

def sourceSummarySite (moduleAddress : Nat) : CallSite :=
  { siteId := 0, kind := .staticcall, target := moduleAddress, value := 0
    calldata := summaryCalldata, gas := maxGas }

/-- The canonical FunctionSpec ↔ CallProgram ↔ DenoteMemory bridge.  The call
program comes from the checked body; the memory side proves the byte-level
selector materialized by that body's first statement. -/
def SourceCallStorageABI (fn : FunctionSpec) (moduleAddress : Nat) : Prop :=
  fn.params = sourceParameters ∧
  fn.returnType = some .uint256 ∧
  fn.body = consumedSummaryBody ∧
  sourceCallProgram fn moduleAddress =
    .bind (sourceSummarySite moduleAddress) (fun observation =>
      .pure observation.result.succeeded)

theorem selector_memory_is_byte_precise :
    (Memory.empty.writeWord 0 summarySelectorWord).readWord 0 0 = ⟨0x9a, by decide⟩ ∧
    (Memory.empty.writeWord 0 summarySelectorWord).readWord 0 1 = ⟨0xbd, by decide⟩ ∧
    (Memory.empty.writeWord 0 summarySelectorWord).readWord 0 2 = ⟨0xdf, by decide⟩ ∧
    (Memory.empty.writeWord 0 summarySelectorWord).readWord 0 3 = ⟨0x09, by decide⟩ := by
  repeat' apply And.intro
  all_goals
    rw [Memory.readWord]
    rw [Memory.readByte]
    simp [Memory.writeWord, Memory.expand, expandedLength, Memory.empty,
      summarySelectorWord, selectorByte]
    native_decide

theorem consumed_summary_source_bridge (moduleAddress : Nat) :
    SourceCallStorageABI consumedSummaryEntry moduleAddress ∧
    CallsIn (sourceCallProgram consumedSummaryEntry moduleAddress)
      { stateTransition := fun _ world => world
        result := fun _ _ => .success (List.replicate summaryReturnBytes 0)
        gasUsed := fun _ _ => 0 } canonicalCallState =
      [sourceSummarySite moduleAddress] ∧
    summaryCalldata = [0x9a, 0xbd, 0xdf, 0x09] := by
  refine ⟨?_, rfl, rfl⟩
  exact ⟨rfl, rfl, rfl, rfl⟩

/-! The executable transaction frame is intentionally separate from the
FunctionSpec.  `Contract.run` supplies snapshot rollback; the external is a
typed summary boundary, not deployed-code semantics. -/
def lastCapacitySlot : Verity.StorageSlot Verity.Uint256 := ⟨0⟩

def executeSummary (depositable : _root_.Verity.Uint256) (callSucceeded : Bool) : _root_.Verity.Contract Unit := do
  _root_.Verity.setStorage lastCapacitySlot depositable
  Contracts.externalCallBind [] "getStakingModuleSummary" ([] : List Verity.Uint256)
  _root_.Verity.require callSucceeded "StakingModuleSummaryCallFailed"

/-- Embed the live transaction state in the call-program state.  In
particular, the mapped call observes the state after the router-local
pre-call write, rather than a fixed default snapshot. -/
def callStateOfTransaction (state : _root_.Verity.ContractState) : CallState :=
  { world := state, gasRemaining := maxGas }

/-- Execute the exact mapped summary `CallProgram` observation in the
`Contract` transaction.  This adapter deliberately retains the complete
call-site construction -- including `moduleAddress` and `summaryCalldata` --
rather than passing a precomputed success bit into a separate transaction. -/
def executeMappedSummaryCall (adversary : AdversaryModel) (moduleAddress : Nat) :
    _root_.Verity.Contract Bool :=
  fun state =>
    _root_.Verity.ContractResult.success
      (denote (sourceCallProgram consumedSummaryEntry moduleAddress)
        adversary (callStateOfTransaction state)).1 state

/-- The same source-shaped call boundary, retaining the observed result bytes
for the post-call guards.  `sourceCallProgram` intentionally records only the
success bit for its trace theorem; this companion program is what prevents the
transaction adapter from discarding returndata before checking it. -/
def sourceSummaryResultProgram (fn : FunctionSpec) (moduleAddress : Nat) :
    CallProgram (Option ExternalCallResult) :=
  match fn.body with
  | [ .mstore (.literal 0) (.shl (.literal 224) (.literal selector))
    , .setStorage "lastCapacity" (.param "depositable")
    , .letVar "summaryOk"
        (.staticcall (.literal gas) (.param "moduleAddress")
          (.literal 0) (.literal inputBytes) (.literal 0) (.literal outputBytes))
    , .require (.eq (.localVar "summaryOk") (.literal 1))
        "StakingModuleSummaryCallFailed"
    , .require (.le (.literal returnBytes) .returndataSize)
        "StakingModuleSummaryMalformedReturn"
    , .return (.literal 0) ] =>
      if selector = summarySelector ∧ gas = maxGas ∧ inputBytes = 4 ∧
          outputBytes = summaryReturnBytes ∧ returnBytes = summaryReturnBytes then
        .bind (sourceSummarySite moduleAddress) fun observation =>
          .pure (some observation.result)
      else .pure none
  | _ => .pure none

/-- Execute the exact source-derived call and keep its typed returndata for the
transaction-level checks. -/
def executeMappedSummaryResult (adversary : AdversaryModel) (moduleAddress : Nat) :
    _root_.Verity.Contract (Option ExternalCallResult) :=
  fun state =>
    _root_.Verity.ContractResult.success
      (denote (sourceSummaryResultProgram consumedSummaryEntry moduleAddress)
        adversary (callStateOfTransaction state)).1 state

/-- Non-circular executable bridge: running the contract call adapter yields
the result of the very `CallProgram` whose site fixes the mapped target,
selector calldata, call kind, and gas. -/
theorem execute_mapped_summary_call_bridge (adversary : AdversaryModel)
    (moduleAddress : Nat) (state : _root_.Verity.ContractState) :
    (executeMappedSummaryCall adversary moduleAddress).run state =
      _root_.Verity.ContractResult.success
        (denote (sourceCallProgram consumedSummaryEntry moduleAddress)
          adversary (callStateOfTransaction state)).1 state := rfl

/-- The transaction wrapper executes the typed `CallProgram` observation
inside `Contract.run`; a reverted mapped summary call is therefore the call
that causes the following `require` and whole-transaction rollback. -/
def executeObservedSummary (adversary : AdversaryModel) (moduleAddress : Nat)
    (depositable : _root_.Verity.Uint256) : _root_.Verity.Contract Unit :=
  fun state =>
    match (executeMappedSummaryResult adversary moduleAddress)
      (state.writeSlot lastCapacitySlot.slot depositable) with
    | .success (some (.success data)) afterCall =>
        if summaryReturnBytes <= data.length then
          _root_.Verity.ContractResult.success () afterCall
        else _root_.Verity.ContractResult.revert "StakingModuleSummaryMalformedReturn" afterCall
    | .success _ afterCall =>
        _root_.Verity.ContractResult.revert "StakingModuleSummaryCallFailed" afterCall
    | .revert reason afterCall => .revert reason afterCall

theorem typed_success_commits_pre_call_store
    (depositable : _root_.Verity.Uint256) (state : _root_.Verity.ContractState) :
    ∃ after, (executeSummary depositable true).run state = .success () after ∧
      after.storage lastCapacitySlot.slot = depositable := by
  refine ⟨_, rfl, rfl⟩

/-- This is the non-vacuous rollback theorem: `setStorage` executes before the
typed external boundary and the failed typed result is returned by actual
`Contract.run` with the original snapshot, not by a synthetic reset function. -/
theorem typed_revert_rolls_back_pre_call_store
    (depositable : _root_.Verity.Uint256) (state rollback : _root_.Verity.ContractState) (reason : String)
    (h : (executeSummary depositable false).run state =
      _root_.Verity.ContractResult.revert reason rollback) :
    rollback = state := by
  unfold _root_.Verity.Contract.run at h
  split at h <;> simp_all

theorem typed_external_revert_rolls_back_pre_call_store
    (adversary : AdversaryModel) (moduleAddress : Nat) (data : List Nat)
    (depositable : _root_.Verity.Uint256) (state : _root_.Verity.ContractState)
    (hresult : adversary.result (sourceSummarySite moduleAddress)
      (state.writeSlot lastCapacitySlot.slot depositable) = .revert data) :
    ∃ reason, (executeObservedSummary adversary moduleAddress depositable).run state =
      _root_.Verity.ContractResult.revert reason state := by
  have hcall :
      (executeMappedSummaryResult adversary moduleAddress)
        (state.writeSlot lastCapacitySlot.slot depositable) =
        _root_.Verity.ContractResult.success (some (.revert data))
          (state.writeSlot lastCapacitySlot.slot depositable) := by
    change _root_.Verity.ContractResult.success
      (denote (sourceSummaryResultProgram consumedSummaryEntry moduleAddress) adversary
        (callStateOfTransaction (state.writeSlot lastCapacitySlot.slot depositable))).1 _ = _
    change _root_.Verity.ContractResult.success
      (some (adversary.result (sourceSummarySite moduleAddress)
        (state.writeSlot lastCapacitySlot.slot depositable))) _ = _
    rw [hresult]
  unfold executeObservedSummary _root_.Verity.Contract.run
  dsimp only
  rw [hcall]
  exact ⟨_, rfl⟩

/-- A zero-success-bit is not the only rejecting path: a successful mapped
call with insufficient returndata reaches the source-shaped size guard and
rolls the pre-call store back through the same transaction boundary. -/
theorem typed_short_returndata_rolls_back_pre_call_store
    (adversary : AdversaryModel) (moduleAddress : Nat) (data : List Nat)
    (depositable : _root_.Verity.Uint256) (state : _root_.Verity.ContractState)
    (hresult : adversary.result (sourceSummarySite moduleAddress)
      (state.writeSlot lastCapacitySlot.slot depositable) = .success data)
    (hshort : ¬ summaryReturnBytes <= data.length) :
    (executeObservedSummary adversary moduleAddress depositable).run state =
      _root_.Verity.ContractResult.revert "StakingModuleSummaryMalformedReturn" state := by
  have hresponse :
      (denote (sourceSummaryResultProgram consumedSummaryEntry moduleAddress) adversary
        (callStateOfTransaction (state.writeSlot lastCapacitySlot.slot depositable))).1 =
        some (.success data) := by
    change some (adversary.result (sourceSummarySite moduleAddress)
      (state.writeSlot lastCapacitySlot.slot depositable)) = _
    rw [hresult]
  have hcall :
      (executeMappedSummaryResult adversary moduleAddress)
        (state.writeSlot lastCapacitySlot.slot depositable) =
        _root_.Verity.ContractResult.success (some (.success data))
          (state.writeSlot lastCapacitySlot.slot depositable) := by
    change _root_.Verity.ContractResult.success _ _ = _
    rw [hresponse]
  unfold executeObservedSummary _root_.Verity.Contract.run
  dsimp only
  rw [hcall]
  simp [hshort]

/-- A successful mapped call with the complete summary tuple commits the
pre-call store.  The payload is otherwise unconstrained here: in particular,
this transaction slice does not invent a `capacity <= depositable` guard. -/
theorem typed_complete_returndata_commits_pre_call_store
    (adversary : AdversaryModel) (moduleAddress : Nat) (data : List Nat)
    (depositable : _root_.Verity.Uint256) (state : _root_.Verity.ContractState)
    (hresult : adversary.result (sourceSummarySite moduleAddress)
      (state.writeSlot lastCapacitySlot.slot depositable) = .success data)
    (hcomplete : summaryReturnBytes <= data.length) :
    (executeObservedSummary adversary moduleAddress depositable).run state =
      _root_.Verity.ContractResult.success ()
        (state.writeSlot lastCapacitySlot.slot depositable) := by
  have hresponse :
      (denote (sourceSummaryResultProgram consumedSummaryEntry moduleAddress) adversary
        (callStateOfTransaction (state.writeSlot lastCapacitySlot.slot depositable))).1 =
        some (.success data) := by
    change some (adversary.result (sourceSummarySite moduleAddress)
      (state.writeSlot lastCapacitySlot.slot depositable)) = _
    rw [hresult]
  have hcall :
      (executeMappedSummaryResult adversary moduleAddress)
        (state.writeSlot lastCapacitySlot.slot depositable) =
        _root_.Verity.ContractResult.success (some (.success data))
          (state.writeSlot lastCapacitySlot.slot depositable) := by
    change _root_.Verity.ContractResult.success _ _ = _
    rw [hresponse]
  unfold executeObservedSummary _root_.Verity.Contract.run
  dsimp only
  rw [hcall]
  simp [hcomplete]

theorem consumed_summary_function_spec_compiles :
    (CompilationModel.compile spec [entrySelector]).isOk = true := by
  native_decide

/-- Real P-ALLOC-1 Phase-3 consumption theorem.  The static `CallProgram`
records typed success/revert observations; the executable Verity transaction
separately proves rollback of the preceding scalar storage update. -/
theorem consumed_summary_phase3_transaction (moduleAddress : Nat) :
    (CompilationModel.compile spec [entrySelector]).isOk = true ∧
    SourceCallStorageABI consumedSummaryEntry moduleAddress ∧
    CallsIn (sourceCallProgram consumedSummaryEntry moduleAddress)
      { stateTransition := fun _ world => world
        result := fun _ _ => .success (List.replicate summaryReturnBytes 0)
        gasUsed := fun _ _ => 0 } canonicalCallState =
      [sourceSummarySite moduleAddress] ∧
    summaryCalldata = [0x9a, 0xbd, 0xdf, 0x09] ∧
    (∀ adversary data (depositable : _root_.Verity.Uint256) state,
      adversary.result (sourceSummarySite moduleAddress)
        (state.writeSlot lastCapacitySlot.slot depositable) = .revert data →
      ∃ reason, (executeObservedSummary adversary moduleAddress depositable).run state =
        _root_.Verity.ContractResult.revert reason state) ∧
    (∀ adversary data (depositable : _root_.Verity.Uint256) state,
      adversary.result (sourceSummarySite moduleAddress)
        (state.writeSlot lastCapacitySlot.slot depositable) = .success data →
      ¬ summaryReturnBytes <= data.length →
      (executeObservedSummary adversary moduleAddress depositable).run state =
        _root_.Verity.ContractResult.revert "StakingModuleSummaryMalformedReturn" state) ∧
    (∀ adversary data (depositable : _root_.Verity.Uint256) state,
      adversary.result (sourceSummarySite moduleAddress)
        (state.writeSlot lastCapacitySlot.slot depositable) = .success data →
      summaryReturnBytes <= data.length →
      (executeObservedSummary adversary moduleAddress depositable).run state =
        _root_.Verity.ContractResult.success ()
          (state.writeSlot lastCapacitySlot.slot depositable)) := by
  refine ⟨consumed_summary_function_spec_compiles, ?_, ?_, rfl, ?_, ?_, ?_⟩
  · exact (consumed_summary_source_bridge moduleAddress).1
  · exact (consumed_summary_source_bridge moduleAddress).2.1
  · intro adversary data depositable state hresult
    exact typed_external_revert_rolls_back_pre_call_store adversary moduleAddress data
      depositable state hresult
  · intro adversary data depositable state hresult hshort
    exact typed_short_returndata_rolls_back_pre_call_store adversary moduleAddress data
      depositable state hresult hshort
  · intro adversary data depositable state hresult hcomplete
    exact typed_complete_returndata_commits_pre_call_store adversary moduleAddress data
      depositable state hresult hcomplete

end LidoSRv3.Audit.Verity.AllocCapacityPhase3
