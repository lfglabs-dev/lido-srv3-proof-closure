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

/-- Reread the persisted source/target payload pair for each request index. -/
def readPayloads (state : ContractState) : Nat → Nat → List (List Word)
  | _, 0 => []
  | index, count + 1 =>
      [state.readMapUint sourceMapSlot (Verity.Core.Uint256.ofNat index),
       state.readMapUint targetMapSlot (Verity.Core.Uint256.ofNat index)] ::
        readPayloads state (index + 1) count

/-- Success reads the journal the body appended to `state.calls` / `state.events`,
not the `Result` payload. Payloads are independently reread from the two
persisted mapping slots for the new request indices
`[beforeCount, beforeCount + calls.length)`. Using `calls.length` (not a
Uint256 slot delta) keeps the reread count on `Nat` and avoids modulus
round-trips through the count slot. -/
def observe (before : ContractState) : ContractResult Result → View
  | .success _ state =>
      let calls := (state.calls.drop before.calls.length).map ofJournal
      let events := (state.events.drop before.events.length).map ofEvent
      let beforeCount := (before.readSlot countSlot).val
      ⟨.committed, calls, events,
        readPayloads state beforeCount calls.length,
        state.readSlot countSlot, state.readSlot feePaidSlot⟩
  | .revert _ _ =>
      ⟨.reverted, [], [], [], before.readSlot countSlot, 0⟩

def sourceView (inputs : Inputs) (beforeCount : Nat) : View :=
  match sourceRun inputs with
  | .reverted _ =>
      ⟨.reverted, [], [], [], Verity.Core.Uint256.ofNat beforeCount, 0⟩
  | .committed obs =>
      ⟨.committed, obs.calls, obs.events, obs.payloads,
        Verity.Core.Uint256.ofNat (beforeCount + obs.requestCount), obs.feePaid⟩

private theorem readMapUint_writeMapUint_other_slot (s : ContractState)
    {slot slot' : Nat} (hslot : slot' ≠ slot) (key key' value : Word) :
    (s.writeMapUint slot key value).readMapUint slot' key' =
      s.readMapUint slot' key' := by
  simp [ContractState.readMapUint, ContractState.storageMapUint,
    ContractState.writeMapUint, hslot]

private theorem readMapUint_writeMapUint_other_key (s : ContractState)
    (slot : Nat) {key key' : Word} (hkey : key' ≠ key) (value : Word) :
    (s.writeMapUint slot key value).readMapUint slot key' =
      s.readMapUint slot key' := by
  simp [ContractState.readMapUint, ContractState.storageMapUint,
    ContractState.writeMapUint, hkey]

private theorem writePayloads_preserves_prior (payloads : List (List Word)) :
    ∀ (start : Nat) (state : ContractState) (key : Nat),
      key < start →
      start + payloads.length ≤ Verity.Core.Uint256.modulus →
      (writePayloads start payloads state).readMapUint sourceMapSlot
          (Verity.Core.Uint256.ofNat key) =
        state.readMapUint sourceMapSlot (Verity.Core.Uint256.ofNat key) ∧
      (writePayloads start payloads state).readMapUint targetMapSlot
          (Verity.Core.Uint256.ofNat key) =
        state.readMapUint targetMapSlot (Verity.Core.Uint256.ofNat key) := by
  intro start state key hKey hBound
  induction payloads generalizing start state with
  | nil => exact ⟨rfl, rfl⟩
  | cons payload rest ih =>
      rw [writePayloads]
      have hStart : start < Verity.Core.Uint256.modulus := by
        simp only [List.length_cons] at hBound
        omega
      have hKeyBound : key < Verity.Core.Uint256.modulus := Nat.lt_trans hKey hStart
      have hWordNe :
          Verity.Core.Uint256.ofNat key ≠ Verity.Core.Uint256.ofNat start := by
        intro h
        have hv := congrArg Verity.Core.Uint256.val h
        simp [Verity.Core.Uint256.val_ofNat, Nat.mod_eq_of_lt hKeyBound,
          Nat.mod_eq_of_lt hStart] at hv
        omega
      have hTail := ih (start + 1)
        ((state.writeMapUint sourceMapSlot (Verity.Core.Uint256.ofNat start)
          (payload.getD 0 0)).writeMapUint targetMapSlot
          (Verity.Core.Uint256.ofNat start) (payload.getD 1 0))
        (by omega) (by simp only [List.length_cons] at hBound ⊢; omega)
      constructor
      · rw [hTail.1]
        rw [readMapUint_writeMapUint_other_slot _ (by decide)]
        exact readMapUint_writeMapUint_other_key _ _ hWordNe _
      · rw [hTail.2]
        rw [readMapUint_writeMapUint_other_key _ _ hWordNe]
        exact readMapUint_writeMapUint_other_slot _ (by decide) _ _ _

theorem writePayloads_read_written (payloads : List (List Word)) :
    ∀ (start : Nat) (state : ContractState) (i : Nat),
      start + payloads.length ≤ Verity.Core.Uint256.modulus →
      i < payloads.length →
      (writePayloads start payloads state).readMapUint sourceMapSlot
          (Verity.Core.Uint256.ofNat (start + i)) = (payloads.getD i []).getD 0 0 ∧
        (writePayloads start payloads state).readMapUint targetMapSlot
          (Verity.Core.Uint256.ofNat (start + i)) = (payloads.getD i []).getD 1 0 := by
  intro start state i hBound hi
  induction payloads generalizing start state i with
  | nil => simp at hi
  | cons payload rest ih =>
      cases i with
      | zero =>
          simp only [Nat.add_zero]
          rw [writePayloads]
          have hPrior := writePayloads_preserves_prior rest (start + 1)
            ((state.writeMapUint sourceMapSlot (Verity.Core.Uint256.ofNat start)
              (payload.getD 0 0)).writeMapUint targetMapSlot
              (Verity.Core.Uint256.ofNat start) (payload.getD 1 0))
            start (by omega)
            (by simp only [List.length_cons] at hBound ⊢; omega)
          constructor
          · rw [hPrior.1, readMapUint_writeMapUint_other_slot _ (by decide)]
            exact ContractState.readMapUint_writeMapUint_same _ _ _ _
          · rw [hPrior.2, ContractState.readMapUint_writeMapUint_same]
            rfl
      | succ i =>
          simp only [writePayloads]
          have hTailBound : start + 1 + rest.length ≤ Verity.Core.Uint256.modulus := by
            simp only [List.length_cons] at hBound
            omega
          have hTailI : i < rest.length := by
            simp only [List.length_cons, Nat.succ_lt_succ_iff] at hi
            exact hi
          simpa [Nat.add_assoc, List.getD_cons_succ] using
            ih (start + 1)
              ((state.writeMapUint sourceMapSlot (Verity.Core.Uint256.ofNat start)
                (payload.getD 0 0)).writeMapUint targetMapSlot
                (Verity.Core.Uint256.ofNat start) (payload.getD 1 0))
              i hTailBound hTailI

def normalizedPayload (payload : List Word) : List Word :=
  [payload.getD 0 0, payload.getD 1 0]

theorem writePayloads_readPayloads (start : Nat) (payloads : List (List Word))
    (state : ContractState)
    (hBound : start + payloads.length ≤ Verity.Core.Uint256.modulus) :
    readPayloads (writePayloads start payloads state) start payloads.length =
      payloads.map normalizedPayload := by
  induction payloads generalizing start state with
  | nil => rfl
  | cons payload rest ih =>
      have hHead := writePayloads_read_written (payload :: rest) start state 0
        hBound (by simp)
      have hTailBound : start + 1 + rest.length ≤ Verity.Core.Uint256.modulus := by
        simp only [List.length_cons] at hBound
        omega
      simp only [writePayloads, List.length_cons, readPayloads, List.map_cons]
      have hs : (writePayloads (start + 1) rest
            ((state.writeMapUint sourceMapSlot (Verity.Core.Uint256.ofNat start)
              (payload.getD 0 0)).writeMapUint targetMapSlot
              (Verity.Core.Uint256.ofNat start) (payload.getD 1 0))).readMapUint
              sourceMapSlot (Verity.Core.Uint256.ofNat start) =
          payload.getD 0 0 := by
        simpa [Nat.add_zero, writePayloads] using hHead.1
      have ht : (writePayloads (start + 1) rest
            ((state.writeMapUint sourceMapSlot (Verity.Core.Uint256.ofNat start)
              (payload.getD 0 0)).writeMapUint targetMapSlot
              (Verity.Core.Uint256.ofNat start) (payload.getD 1 0))).readMapUint
              targetMapSlot (Verity.Core.Uint256.ofNat start) =
          payload.getD 1 0 := by
        simpa [Nat.add_zero, writePayloads] using hHead.2
      rw [hs, ht, ih (start + 1)
        ((state.writeMapUint sourceMapSlot (Verity.Core.Uint256.ofNat start)
          (payload.getD 0 0)).writeMapUint targetMapSlot
          (Verity.Core.Uint256.ofNat start) (payload.getD 1 0)) hTailBound]
      rfl

theorem readPayloads_writeSlot (state : ContractState) (slot : Nat) (value : Word)
    (start count : Nat) :
    readPayloads (state.writeSlot slot value) start count =
      readPayloads state start count := by
  induction count generalizing start with
  | zero => rfl
  | succ count ih =>
      simp only [readPayloads]
      simp [ContractState.readMapUint, ih]

@[simp] theorem readPayloads_set_log (state : ContractState)
    (events : List Event) (calls : List ExternalCall) (start count : Nat) :
    readPayloads { state with events := events, calls := calls } start count =
      readPayloads state start count := by
  induction count generalizing start with
  | zero => rfl
  | succ count ih =>
      simp only [readPayloads]
      change _ :: _ = _ :: _
      rw [show ({ state with events := events, calls := calls } : ContractState).readMapUint
          sourceMapSlot (Verity.Core.Uint256.ofNat start) =
          state.readMapUint sourceMapSlot (Verity.Core.Uint256.ofNat start) by rfl]
      rw [show ({ state with events := events, calls := calls } : ContractState).readMapUint
          targetMapSlot (Verity.Core.Uint256.ofNat start) =
          state.readMapUint targetMapSlot (Verity.Core.Uint256.ofNat start) by rfl]
      rw [ih]

theorem persist_read_payloads (start : Nat) (obs : Observables)
    (state : ContractState) (hCount : obs.requestCount = obs.payloads.length)
    (hNormalized : obs.payloads.map normalizedPayload = obs.payloads)
    (hBound : start + obs.payloads.length ≤ Verity.Core.Uint256.modulus) :
    readPayloads (persist start obs state) start obs.requestCount = obs.payloads := by
  unfold persist
  rw [readPayloads_set_log, readPayloads_writeSlot, readPayloads_writeSlot, hCount]
  rw [writePayloads_readPayloads start obs.payloads state hBound, hNormalized]

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

private theorem sourceRun_committed_payload_shape
    (inputs : Inputs) (obs : Observables)
    (hRun : sourceRun inputs = .committed obs) :
    obs.requestCount = obs.payloads.length ∧
      obs.calls.length = obs.requestCount ∧
      obs.payloads.length = inputs.sources.length ∧
      obs.payloads.map normalizedPayload = obs.payloads := by
  unfold sourceRun at hRun
  repeat' first | split at hRun
  all_goals try contradiction
  all_goals try { cases hRun }
  next requests hCaller hNonempty hZip hValid hProduct hFee =>
    injection hRun with hObs
    subst obs
    have hLen := zipRequests_some_length hZip
    simp [commitObservables, normalizedPayload, payload, hLen]

/-- Composed faithful-plane theorem: the real memory-array transaction has the
same outcome observables as the independently stated pinned-source run. -/
theorem verity_tx_simulates_pinned_source
    (inputs : Inputs) (state : ContractState)
    (hCountBound : (state.readSlot countSlot).val + inputs.sources.length <
      Verity.Core.Uint256.modulus)
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
      obtain ⟨hCount, hCallsLen, hPayloadLength, hNormalized⟩ :=
        sourceRun_committed_payload_shape inputs obs hRun
      have hBound : (state.readSlot countSlot).val + obs.payloads.length ≤
          Verity.Core.Uint256.modulus := by
        rw [hPayloadLength]
        exact Nat.le_of_lt hCountBound
      have hPayloads := persist_read_payloads
        (state.readSlot countSlot).val obs state hCount hNormalized hBound
      have hCountVal :
          (Verity.Core.Uint256.ofNat
            ((state.readSlot countSlot).val + obs.requestCount)).val =
            (state.readSlot countSlot).val + obs.requestCount := by
        rw [Verity.Core.Uint256.val_ofNat, Nat.mod_eq_of_lt]
        · rw [hCount, hPayloadLength]; exact hCountBound
      simp [observe, persist_read_count, persist_read_fee, hCalls, hEvents,
        hPayloads, hCallsLen, map_ofJournal_toJournal, map_ofEvent_toEvent]

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
