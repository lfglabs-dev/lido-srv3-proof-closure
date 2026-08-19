import LidoSRv3.Audit.Source.ConsolidationCorrespondence
import Verity.Core.Model.Denote
import Verity.Core.Model.DenoteFunctionCalls
import Compiler.CompilationModel

/-!
# P-CONSOLIDATION-1 faithful call/event/memory transaction

This transaction models `WithdrawalVault.addConsolidationRequests` from
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`. Source and target
public keys and their lengths are read through the compilation-model
denotation of memory-backed `uint256[]` values. Successful pairs persist
`source ‖ target` through `writeMapUint`, the request count and fee through
`writeSlot`, one journaled CALL, and one `ConsolidationRequestAdded` event.
-/

namespace LidoSRv3.Audit.Verity.ConsolidationTx

open _root_.Verity
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote
open LidoSRv3.Audit.SolidityConsolidation

abbrev Word := SolidityConsolidation.Word

def sourcesBase : Nat := 0x1000
def targetsBase : Nat := 0x2000
def sourceLensBase : Nat := 0x3000
def targetLensBase : Nat := 0x4000
def countSlot : Nat := 30
def feePaidSlot : Nat := 31
def sourceMapSlot : Nat := 32
def targetMapSlot : Nat := 33

private def oracle : DenoteOracle where
  mappingSlot := fun _ _ => 0
  keccakMemorySlice := fun _ _ _ => 0

def arrayState (state : ContractState) (name : String) (base length : Nat) :
    DenoteState :=
  { world := state
    bindings := [(name ++ "_data_offset", base), (name ++ "_length", length)] }

def readWord (state : ContractState) (name : String) (base length index : Nat) :
    Option Word :=
  (evalExpr oracle [] (arrayState state name base length)
    (.memoryArrayElement name (.literal index))).map Verity.Core.Uint256.ofNat

def readArray (state : ContractState) (name : String) (base length : Nat) :
    Option (List Word) :=
  (List.range length).mapM (readWord state name base length)

def memoryFor (sources targets sourceLens targetLens : List Word) :
    Nat → Word := fun offset =>
  if sourcesBase ≤ offset ∧ offset < sourcesBase + 32 * sources.length ∧
      (offset - sourcesBase) % 32 = 0 then
    sources.getD ((offset - sourcesBase) / 32) 0
  else if targetsBase ≤ offset ∧ offset < targetsBase + 32 * targets.length ∧
      (offset - targetsBase) % 32 = 0 then
    targets.getD ((offset - targetsBase) / 32) 0
  else if sourceLensBase ≤ offset ∧
      offset < sourceLensBase + 32 * sourceLens.length ∧
      (offset - sourceLensBase) % 32 = 0 then
    sourceLens.getD ((offset - sourceLensBase) / 32) 0
  else if targetLensBase ≤ offset ∧
      offset < targetLensBase + 32 * targetLens.length ∧
      (offset - targetLensBase) % 32 = 0 then
    targetLens.getD ((offset - targetLensBase) / 32) 0
  else 0

def stateFor (sources targets sourceLens targetLens : List Word)
    (base : ContractState) : ContractState :=
  { base with memory := memoryFor sources targets sourceLens targetLens }

def toEvent (ev : EventObs) : Event :=
  { name := "ConsolidationRequestAdded"
    args := ev.payload
    indexedArgs := [ev.topic] }

def toJournal (c : CallObs) : ExternalCall :=
  { siteId := c.target.val
    kind := .call
    target := c.target.val
    value := c.value.val
    calldata := c.input.map (·.val)
    control := .success
    returndata := [] }

def ofEvent (ev : Event) : EventObs :=
  { topic := ev.indexedArgs.headD 0
    payload := ev.args }

def ofJournal (c : ExternalCall) : CallObs :=
  { target := Verity.Core.Uint256.ofNat c.target
    value := Verity.Core.Uint256.ofNat c.value
    input := c.calldata.map Verity.Core.Uint256.ofNat }

private theorem ofNat_val (w : Word) : Verity.Core.Uint256.ofNat w.val = w :=
  Verity.Core.Uint256.ext (Nat.mod_eq_of_lt w.isLt)

private theorem map_ofNat_val (ws : List Word) :
    ws.map (fun w => Verity.Core.Uint256.ofNat w.val) = ws := by
  induction ws with
  | nil => rfl
  | cons w ws ih => simp [ofNat_val w, ih]

@[simp] theorem ofEvent_toEvent (ev : EventObs) : ofEvent (toEvent ev) = ev := by
  simp [ofEvent, toEvent]

@[simp] theorem ofJournal_toJournal (c : CallObs) : ofJournal (toJournal c) = c := by
  cases c
  simp [ofJournal, toJournal, ofNat_val]
  exact map_ofNat_val _

def writePayloads : Nat → List (List Word) → ContractState → ContractState
  | _, [], state => state
  | index, payload :: rest, state =>
      writePayloads (index + 1) rest
        ((state.writeMapUint sourceMapSlot (Verity.Core.Uint256.ofNat index)
            (payload.getD 0 0)).writeMapUint targetMapSlot
          (Verity.Core.Uint256.ofNat index) (payload.getD 1 0))

def persist (start : Nat) (obs : Observables) (state : ContractState) :
    ContractState :=
  let dirty := writePayloads start obs.payloads state
  let dirty := (dirty.writeSlot countSlot
      (Verity.Core.Uint256.ofNat (start + obs.requestCount)))
    |>.writeSlot feePaidSlot obs.feePaid
  { dirty with
    events := dirty.events ++ obs.events.map toEvent
    calls := dirty.calls ++ obs.calls.map toJournal }

structure Result where
  calls : List CallObs
  events : List EventObs
  payloads : List (List Word)
  requestCount : Nat
  feePaid : Word
  deriving DecidableEq, Repr

def ofObservables (obs : Observables) : Result :=
  ⟨obs.calls, obs.events, obs.payloads, obs.requestCount, obs.feePaid⟩

/-- Executable transaction. Length mismatch, fee failure, or the injected
failure after intermediate writes reverts. -/
def addRequests (inputs : Inputs) (failAfterWrites : Bool := false) :
    Contract Result := fun snapshot =>
  match readArray snapshot "sources" sourcesBase inputs.sources.length,
      readArray snapshot "targets" targetsBase inputs.targets.length,
      readArray snapshot "sourceLens" sourceLensBase inputs.sourceLens.length,
      readArray snapshot "targetLens" targetLensBase inputs.targetLens.length with
  | some sources, some targets, some sourceLens, some targetLens =>
      let decoded : Inputs :=
        { inputs with
          sources := sources, targets := targets,
          sourceLens := sourceLens, targetLens := targetLens }
      match sourceRun decoded with
      | .reverted reason => .revert reason snapshot
      | .committed obs =>
          let start := (snapshot.readSlot countSlot).val
          let dirty := persist start obs snapshot
          if failAfterWrites then .revert "INJECTED_AFTER_WRITES" dirty
          else .success (ofObservables obs) dirty
  | _, _, _, _ => .revert "MEMORY_ARRAY_DECODE" snapshot

inductive Status where | committed | reverted deriving DecidableEq, Repr

structure View where
  status : Status
  calls : List CallObs
  events : List EventObs
  payloads : List (List Word)
  requestCount : Word
  feePaid : Word
  deriving DecidableEq, Repr

/-- Success reads the journal the body appended to `state.calls` / `state.events`,
not the `Result` payload. Payloads are the calldata of those calls. -/
def observe (before : ContractState) : ContractResult Result → View
  | .success _ state =>
      let calls := (state.calls.drop before.calls.length).map ofJournal
      let events := (state.events.drop before.events.length).map ofEvent
      ⟨.committed, calls, events, calls.map CallObs.input,
        state.readSlot countSlot, state.readSlot feePaidSlot⟩
  | .revert _ _ =>
      ⟨.reverted, [], [], [], before.readSlot countSlot, 0⟩

def sourceView (inputs : Inputs) (beforeCount : Nat) : View :=
  match sourceRun inputs with
  | .reverted _ =>
      ⟨.reverted, [], [], [], Verity.Core.Uint256.ofNat beforeCount, 0⟩
  | .committed obs =>
      ⟨.committed, obs.calls, obs.events, obs.calls.map CallObs.input,
        Verity.Core.Uint256.ofNat (beforeCount + obs.requestCount), obs.feePaid⟩

theorem writePayloads_readSlot (start : Nat) (payloads : List (List Word))
    (state : ContractState) (slot : Nat) :
    (writePayloads start payloads state).readSlot slot = state.readSlot slot := by
  revert start state
  induction payloads with
  | nil =>
      intro start state
      rfl
  | cons payload rest ih =>
      intro start state
      simp only [writePayloads]
      rw [ih]
      simp [ContractState.readSlot, ContractState.storage_writeMapUint]

@[simp] theorem readSlot_set_log (s : ContractState) (events : List Event)
    (calls : List ExternalCall) (slot : Nat) :
    ({ s with events := events, calls := calls }).readSlot slot = s.readSlot slot :=
  rfl

theorem persist_read_count (start : Nat) (obs : Observables)
    (state : ContractState) :
    (persist start obs state).readSlot countSlot =
      Verity.Core.Uint256.ofNat (start + obs.requestCount) := by
  unfold persist
  rw [readSlot_set_log]
  rw [ContractState.readSlot_writeSlot_other (slot := feePaidSlot) (slot' := countSlot)]
  · exact ContractState.readSlot_writeSlot_same _ countSlot _
  · decide

theorem persist_read_fee (start : Nat) (obs : Observables)
    (state : ContractState) :
    (persist start obs state).readSlot feePaidSlot = obs.feePaid := by
  unfold persist
  rw [readSlot_set_log]
  exact ContractState.readSlot_writeSlot_same _ feePaidSlot _

private theorem writeMapUint_calls (s : ContractState) (slot : Nat)
    (key value : Word) : (s.writeMapUint slot key value).calls = s.calls :=
  rfl

private theorem writeMapUint_events (s : ContractState) (slot : Nat)
    (key value : Word) : (s.writeMapUint slot key value).events = s.events :=
  rfl

theorem writePayloads_calls (start : Nat) (payloads : List (List Word))
    (state : ContractState) :
    (writePayloads start payloads state).calls = state.calls := by
  revert start state
  induction payloads with
  | nil => intro start state; rfl
  | cons _ rest ih =>
      intro start state
      simp only [writePayloads, writeMapUint_calls, ih]

theorem writePayloads_events (start : Nat) (payloads : List (List Word))
    (state : ContractState) :
    (writePayloads start payloads state).events = state.events := by
  revert start state
  induction payloads with
  | nil => intro start state; rfl
  | cons _ rest ih =>
      intro start state
      simp only [writePayloads, writeMapUint_events, ih]

theorem persist_calls (start : Nat) (obs : Observables) (state : ContractState) :
    (persist start obs state).calls = state.calls ++ obs.calls.map toJournal := by
  unfold persist
  simp [writePayloads_calls]

theorem persist_events (start : Nat) (obs : Observables) (state : ContractState) :
    (persist start obs state).events = state.events ++ obs.events.map toEvent := by
  unfold persist
  simp [writePayloads_events]

private theorem map_ofJournal_toJournal (cs : List CallObs) :
    cs.map (ofJournal ∘ toJournal) = cs := by
  induction cs with
  | nil => rfl
  | cons c cs ih => simp [ofJournal_toJournal, ih]

private theorem map_ofEvent_toEvent (es : List EventObs) :
    es.map (ofEvent ∘ toEvent) = es := by
  induction es with
  | nil => rfl
  | cons e es ih => simp [ofEvent_toEvent, ih]

private theorem drop_map_ofJournal (before : List ExternalCall)
    (calls : List CallObs) :
    ((before ++ calls.map toJournal).drop before.length).map ofJournal = calls := by
  rw [List.drop_left]
  simpa [Function.comp] using map_ofJournal_toJournal calls

private theorem drop_map_ofEvent (before : List Event) (events : List EventObs) :
    ((before ++ events.map toEvent).drop before.length).map ofEvent = events := by
  rw [List.drop_left]
  simpa [Function.comp] using map_ofEvent_toEvent events

/-- Composed faithful-plane theorem: the real memory-array transaction has the
same outcome observables as the independently stated pinned-source run. -/
theorem verity_tx_simulates_pinned_source
    (inputs : Inputs) (state : ContractState)
    (hSources : readArray state "sources" sourcesBase inputs.sources.length =
      some inputs.sources)
    (hTargets : readArray state "targets" targetsBase inputs.targets.length =
      some inputs.targets)
    (hSourceLens : readArray state "sourceLens" sourceLensBase
      inputs.sourceLens.length = some inputs.sourceLens)
    (hTargetLens : readArray state "targetLens" targetLensBase
      inputs.targetLens.length = some inputs.targetLens) :
    observe state ((addRequests inputs).run state) =
      sourceView inputs (state.readSlot countSlot).val := by
  unfold Contract.run addRequests sourceView
  simp only [hSources, hTargets, hSourceLens, hTargetLens]
  cases hRun : sourceRun inputs with
  | reverted _ =>
      simp [observe, ofNat_val]
  | committed obs =>
      have hCalls := persist_calls (state.readSlot countSlot).val obs state
      have hEvents := persist_events (state.readSlot countSlot).val obs state
      simp [observe, persist_read_count, persist_read_fee, hCalls, hEvents,
        map_ofJournal_toJournal, map_ofEvent_toEvent]

/-- Any failure, including the injected failure after intermediate
call/event/memory writes, returns the exact pre-transaction snapshot. -/
theorem revert_restores_snapshot
    (inputs : Inputs) (inject : Bool) (state rollback : ContractState)
    (reason : String)
    (h : (addRequests inputs inject).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

/-! ## FunctionSpec call/event/memory fragment

The official `denoteFunction` still maps `Expr.call` / `Stmt.externalCallBind`
to `none` / `.revert`. The widened `denoteFunctionWithCalls` fragment from
Verity #2360 executes `externalCallBind`, `emit`, and `mstore`. The single-pair
spec below stays inside that fragment so a success hypothesis is not vacuous.
-/

def requestsField : Field :=
  { name := "requests", ty := .uint256, «slot» := some 0 }

def consolidationExternal : ExternalFunction :=
  { name := "consolidationPredeploy"
    params := [.uint256, .uint256]
    returnType := none
    proofStatus := .unchecked
    axiomNames := [] }

def requestOne : FunctionSpec :=
  { name := "requestOne"
    params :=
      [{ name := "sourceKey", ty := .uint256 },
       { name := "targetKey", ty := .uint256 }]
    returnType := none
    isPayable := true
    reentrancyTrusted := true
    body :=
      [ .mstore (.literal 0) (.param "sourceKey")
      , .mstore (.literal 1) (.param "targetKey")
      , .externalCallBind [] "consolidationPredeploy"
          [.param "sourceKey", .param "targetKey"]
      , .emit "ConsolidationRequestAdded"
          [.param "sourceKey", .param "targetKey"]
      , .setStorage "requests" (.add (.storage "requests") (.literal 1))
      , .stop ] }

def functionSpec : CompilationModel :=
  { name := "ConsolidationFunctionSpecBridge"
    fields := [requestsField]
    constructor := none
    functions := [requestOne]
    externals := [consolidationExternal] }

def functionSelector : Nat := 0x72510002

def functionEnv (target fee : Nat) : DenoteFunctionCalls.CallEnv where
  oracle := oracle
  adversary := DenoteFunctionCalls.identityAdversary
  resolve := fun name =>
    if name = "consolidationPredeploy" then
      some { target := target, value := fee, siteId := 0 }
    else none

def functionTx (source target : Nat) : DenoteTransaction :=
  { sender := 0xCAFE, functionSelector := functionSelector
    args := [source, target] }

/-- The registered entrypoint uses `mstore` (memory), `externalCallBind`
(call), and `emit` (event) — the three bridge constructors. -/
theorem function_spec_bridge_constructors :
    requestOne.body =
      [ .mstore (.literal 0) (.param "sourceKey")
      , .mstore (.literal 1) (.param "targetKey")
      , .externalCallBind [] "consolidationPredeploy"
          [.param "sourceKey", .param "targetKey"]
      , .emit "ConsolidationRequestAdded"
          [.param "sourceKey", .param "targetKey"]
      , .setStorage "requests" (.add (.storage "requests") (.literal 1))
      , .stop ] :=
  rfl

end LidoSRv3.Audit.Verity.ConsolidationTx
