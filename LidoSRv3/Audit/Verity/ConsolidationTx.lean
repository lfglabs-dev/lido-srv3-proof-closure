import LidoSRv3.Audit.Source.ConsolidationCorrespondence
import Verity.Core.Model.Denote
import Verity.Core.Model.DenoteFunctionCalls
import Compiler.CompilationModel

/-!
# P-CONSOLIDATION-1 faithful call/event/memory transaction

This transaction models `WithdrawalVault.addConsolidationRequests` from
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`. Source and target
public keys and their lengths are read through the compilation-model
denotation of memory-backed `uint256[]` values. Successful pairs persist
`source ‖ target` through `writeMapUint`, the request count and fee through
`writeSlot`, one journaled CALL, and one `ConsolidationRequestAdded` event.
The frame-entry payable credit of `msg.value` (`credited`) and the
per-request CALL debit (`forwardCalls`, the `call{value: fee}` of
`WithdrawalVaultEIP7685._callAddConsolidationRequest` lines 113--121) move
wei on the vault's balance, so committed runs forward exactly `msg.value`
across the journaled CALLs and restore the pre-call `selfBalance` — the
pinned `preservesEthBalance` modifier (`WithdrawalVault.sol:81--85`), vault
side. The frame-entry credit is admissibility-guarded: a
`selfBalance + msg.value` that would wrap the `Uint256` balance models no
executable transfer (the credit could not land and the CALL debits could
not be funded), so such entries are rejected before decode
(`ENTRY_CREDIT_OVERFLOW`) instead of committing wrapped debits. The
counterparty credit at the request predeploy is a separate contract's
balance and is not modeled on this single-contract plane.
-/

namespace LidoSRv3.Audit.Verity.ConsolidationTx

open _root_.Verity
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote
open LidoSRv3.Audit.SolidityConsolidation

abbrev Word := SolidityConsolidation.Word

/-! ## Memory layout and observation slots

`WithdrawalVault.addConsolidationRequests` (`WithdrawalVault.sol:199-208`)
has no mutable storage on this path: `CONSOLIDATION_GATEWAY` and
`CONSOLIDATION_REQUEST` are constructor immutables and the loop of
`WithdrawalVaultEIP7685.sol:68-72` only CALLs and emits. The four `*Base`
offsets model the memory-backed `sourcePubkeys` / `targetPubkeys` arrays
(and their element lengths); the four slots are observation slots, no
Solidity storage counterpart. -/

/-- Memory base of `sourcePubkeys` (harness layout, not a Solidity offset). -/
def sourcesBase : Nat := 0x1000
/-- Memory base of `targetPubkeys` (harness layout, not a Solidity offset). -/
def targetsBase : Nat := 0x2000
/-- Memory base of the `sourcePubkeys[i].length` words (harness layout). -/
def sourceLensBase : Nat := 0x3000
/-- Memory base of the `targetPubkeys[i].length` words (harness layout). -/
def targetLensBase : Nat := 0x4000
/-- Observation slot, no Solidity storage counterpart: running request count. -/
def countSlot : Nat := 30
/-- Observation slot, no Solidity storage counterpart: `msg.value` of the last commit. -/
def feePaidSlot : Nat := 31
/-- Observation slot, no Solidity storage counterpart: `sourcePubkey` word per request index. -/
def sourceMapSlot : Nat := 32
/-- Observation slot, no Solidity storage counterpart: `targetPubkey` word per request index. -/
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

/-- Frame-entry payable credit: the vault's balance receives `msg.value`
before the body runs. This mirrors `withPayableCallContext`; the pinned
`preservesEthBalance` modifier snapshots `address(this).balance - msg.value`
immediately after this credit (`WithdrawalVault.sol:81--85`).

`addRequests` applies this credit only when it does not wrap: a wrapping
credit has no executable counterpart, exactly as the checked debit path
`Contracts.externalCallBindTo` refuses `call.value > state.selfBalance` and
the official consolidation theorem carries a no-wrap funding premise. -/
def credited (state : ContractState) (inputs : Inputs) : ContractState :=
  { state with selfBalance := state.selfBalance + inputs.msgValue }

theorem readArray_credited (state : ContractState) (inputs : Inputs)
    (name : String) (base length : Nat) :
    readArray (credited state inputs) name base length =
      readArray state name base length := rfl

theorem selfBalance_credited (state : ContractState) (inputs : Inputs) :
    (credited state inputs).selfBalance = state.selfBalance + inputs.msgValue :=
  rfl

theorem credited_calls (state : ContractState) (inputs : Inputs) :
    (credited state inputs).calls = state.calls := rfl

theorem credited_events (state : ContractState) (inputs : Inputs) :
    (credited state inputs).events = state.events := rfl

theorem credited_readSlot (state : ContractState) (inputs : Inputs)
    (slot : Nat) :
    (credited state inputs).readSlot slot = state.readSlot slot := rfl

/-- `WithdrawalVaultEIP7685.sol:120  emit ConsolidationRequestAdded(request);` as a Verity `Event`. -/
def toEvent (ev : EventObs) : Event :=
  { name := "ConsolidationRequestAdded"
    args := ev.payload
    indexedArgs := [ev.topic] }

/-- `WithdrawalVaultEIP7685.sol:115  (bool success,) = CONSOLIDATION_REQUEST.call{value: fee}(request);`
as a journaled `.success` CALL frame (the failure arm, line 116-118
`RequestAdditionFailed`, is not transcribed). -/
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

/-- Added by the model: records each `source ‖ target` pair in the two
observation mapping slots (`sourceMapSlot`, `targetMapSlot`). No Solidity
storage write corresponds to this. -/
def writePayloads : Nat → List (List Word) → ContractState → ContractState
  | _, [], state => state
  | index, payload :: rest, state =>
      writePayloads (index + 1) rest
        ((state.writeMapUint sourceMapSlot (Verity.Core.Uint256.ofNat index)
            (payload.getD 0 0)).writeMapUint targetMapSlot
          (Verity.Core.Uint256.ofNat index) (payload.getD 1 0))

/-- One journaled CALL moves its value out of the vault: the pinned
`CONSOLIDATION_REQUEST.call{value: fee}` of
`WithdrawalVaultEIP7685._callAddConsolidationRequest` (lines 113--121)
debits the vault balance by the call's value. -/
def forwardCall (state : ContractState) (c : CallObs) : ContractState :=
  { state with selfBalance := state.selfBalance - c.value }

def forwardCalls (state : ContractState) : List CallObs → ContractState
  | [] => state
  | c :: rest => forwardCalls (forwardCall state c) rest

/-- Effects of a committed loop `WithdrawalVaultEIP7685.sol:68-72` on the
vault state: the per-CALL value debits (`forwardCalls`, line 115), the CALL
journal (line 115) and the events (line 120). The observation-slot writes
(`writePayloads`, `countSlot`, `feePaidSlot`) are added by the model. -/
def persist (start : Nat) (obs : Observables) (state : ContractState) :
    ContractState :=
  let dirty := writePayloads start obs.payloads state
  let dirty := (dirty.writeSlot countSlot
      (Verity.Core.Uint256.ofNat (start + obs.requestCount)))
    |>.writeSlot feePaidSlot obs.feePaid
  let dirty := forwardCalls dirty obs.calls
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

/-! ## WithdrawalVault.addConsolidationRequests (WithdrawalVault.sol:199-208), executed plane -/

/-- `WithdrawalVault.sol:199-208 addConsolidationRequests(bytes[] calldata sourcePubkeys, bytes[] calldata targetPubkeys)`,
executed transaction. Guards and the loop are delegated to the pinned
`SolidityConsolidation.sourceRun` (see its header for the line map); this
def adds the frame entry, the memory decode of the two arrays, and the
state effects.

Not transcribed: `preservesEthBalance` (`WithdrawalVault.sol:81-85`) as a
statement; it is proved instead (`committed_preserves_eth_balance`). The
STATICCALL fee read and the CALL failure arm follow `sourceRun`.

Added by the model: the payable frame-entry credit `credited` with its
`ENTRY_CREDIT_OVERFLOW` admissibility guard, the `MEMORY_ARRAY_DECODE`
revert, the `failAfterWrites` injection hook (`INJECTED_AFTER_WRITES`), and
the observation slots written by `persist`.

The entry state is the payable credit of `msg.value` (`credited`); a frame
entry whose credit would wrap the vault's `Uint256` balance is rejected
before decode (`ENTRY_CREDIT_OVERFLOW`); on admissible entries, length
mismatch, fee failure, or the injected failure after intermediate writes
reverts to the un-credited pre-call snapshot. -/
def addRequests (inputs : Inputs) (failAfterWrites : Bool := false) :
    Contract Result := fun snapshot =>
  if snapshot.selfBalance.val + inputs.msgValue.val <
      Verity.Core.Uint256.modulus then
    match readArray (credited snapshot inputs) "sources" sourcesBase
        inputs.sources.length,
        readArray (credited snapshot inputs) "targets" targetsBase
        inputs.targets.length,
        readArray (credited snapshot inputs) "sourceLens" sourceLensBase
        inputs.sourceLens.length,
        readArray (credited snapshot inputs) "targetLens" targetLensBase
        inputs.targetLens.length with
    | some sources, some targets, some sourceLens, some targetLens =>
        let decoded : Inputs :=
          { inputs with
            sources := sources, targets := targets,
            sourceLens := sourceLens, targetLens := targetLens }
        match sourceRun decoded with
        | .reverted reason => .revert reason snapshot
        | .committed obs =>
            let start := (snapshot.readSlot countSlot).val
            let dirty := persist start obs (credited snapshot inputs)
            if failAfterWrites then .revert "INJECTED_AFTER_WRITES" dirty
            else .success (ofObservables obs) dirty
    | _, _, _, _ => .revert "MEMORY_ARRAY_DECODE" snapshot
  else .revert "ENTRY_CREDIT_OVERFLOW" snapshot

/-- Solidity-facing name, `WithdrawalVault.sol:199`. -/
abbrev addConsolidationRequests := addRequests

/-- Entry-credit overflow rejects the transaction before any decode, guard,
or write: when `selfBalance + msg.value` would wrap the `Uint256` balance,
the payable credit could not land and the per-CALL debits could not be
funded, so the batch is turned away with the exact pre-call snapshot. This
closes the fidelity gap where a wrapping entry credit left the credited
balance below the per-request fee yet the unconditional CALL debits
wrapped back and the transaction still committed; the committed path now
certifies a non-wrapping entry credit, so the checked debit guard
`call.value ≤ state.selfBalance` of the repository's CALL interpreter is
never violated on a success arm. -/
theorem entry_credit_overflow_reverts (inputs : Inputs) (inject : Bool)
    (state : ContractState)
    (hOverflow : Verity.Core.Uint256.modulus ≤
      state.selfBalance.val + inputs.msgValue.val) :
    (addRequests inputs inject).run state =
      .revert "ENTRY_CREDIT_OVERFLOW" state := by
  unfold Contract.run addRequests
  rw [if_neg (by omega)]

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

/-! ## `forwardCalls` lenses: a value-bearing CALL moves only wei

The per-CALL debit touches `selfBalance` alone, so every storage, journal,
and log lens is unchanged. -/

private theorem forwardCall_readMapUint (s : ContractState) (c : CallObs)
    (slot : Nat) (key : Word) :
    (forwardCall s c).readMapUint slot key = s.readMapUint slot key := rfl

private theorem forwardCall_readSlot (s : ContractState) (c : CallObs)
    (slot : Nat) :
    (forwardCall s c).readSlot slot = s.readSlot slot := rfl

private theorem forwardCall_calls (s : ContractState) (c : CallObs) :
    (forwardCall s c).calls = s.calls := rfl

private theorem forwardCall_events (s : ContractState) (c : CallObs) :
    (forwardCall s c).events = s.events := rfl

private theorem forwardCall_selfBalance (s : ContractState) (c : CallObs) :
    (forwardCall s c).selfBalance = s.selfBalance - c.value := rfl

theorem forwardCalls_readMapUint (state : ContractState)
    (calls : List CallObs) (slot : Nat) (key : Word) :
    (forwardCalls state calls).readMapUint slot key =
      state.readMapUint slot key := by
  induction calls generalizing state with
  | nil => rfl
  | cons c rest ih => simp only [forwardCalls, ih, forwardCall_readMapUint]

theorem forwardCalls_readPayloads (state : ContractState)
    (calls : List CallObs) (start count : Nat) :
    readPayloads (forwardCalls state calls) start count =
      readPayloads state start count := by
  induction count generalizing start state with
  | zero => rfl
  | succ count ih =>
      simp only [readPayloads, forwardCalls_readMapUint, ih]

theorem forwardCalls_readSlot (state : ContractState) (calls : List CallObs)
    (slot : Nat) :
    (forwardCalls state calls).readSlot slot = state.readSlot slot := by
  induction calls generalizing state with
  | nil => rfl
  | cons c rest ih => simp only [forwardCalls, ih, forwardCall_readSlot]

theorem forwardCalls_calls (state : ContractState) (calls : List CallObs) :
    (forwardCalls state calls).calls = state.calls := by
  induction calls generalizing state with
  | nil => rfl
  | cons c rest ih => simp only [forwardCalls, ih, forwardCall_calls]

theorem forwardCalls_events (state : ContractState) (calls : List CallObs) :
    (forwardCalls state calls).events = state.events := by
  induction calls generalizing state with
  | nil => rfl
  | cons c rest ih => simp only [forwardCalls, ih, forwardCall_events]

private theorem writeMapUint_selfBalance (s : ContractState) (slot : Nat)
    (key value : Word) :
    (s.writeMapUint slot key value).selfBalance = s.selfBalance := rfl

theorem writePayloads_selfBalance (start : Nat) (payloads : List (List Word))
    (state : ContractState) :
    (writePayloads start payloads state).selfBalance = state.selfBalance := by
  revert start state
  induction payloads with
  | nil => intro start state; rfl
  | cons payload rest ih =>
      intro start state
      simp only [writePayloads, ih, writeMapUint_selfBalance]

theorem forwardCalls_selfBalance (state : ContractState)
    (calls : List CallObs) :
    (forwardCalls state calls).selfBalance =
      calls.foldl (fun bal c => bal - c.value) state.selfBalance := by
  induction calls generalizing state with
  | nil => rfl
  | cons c rest ih =>
      simp only [forwardCalls, ih, forwardCall_selfBalance, List.foldl_cons]

theorem writeSlot_selfBalance (state : ContractState) (slot : Nat)
    (value : Word) :
    (state.writeSlot slot value).selfBalance = state.selfBalance := rfl

theorem persist_selfBalance (start : Nat) (obs : Observables)
    (state : ContractState) :
    (persist start obs state).selfBalance =
      obs.calls.foldl (fun bal c => bal - c.value) state.selfBalance := by
  unfold persist
  simp only [forwardCalls_selfBalance, writeSlot_selfBalance,
    writePayloads_selfBalance]

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
  rw [readPayloads_set_log, forwardCalls_readPayloads, readPayloads_writeSlot,
    readPayloads_writeSlot, hCount]
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
  rw [readSlot_set_log, forwardCalls_readSlot]
  rw [ContractState.readSlot_writeSlot_other (slot := feePaidSlot) (slot' := countSlot)]
  · exact ContractState.readSlot_writeSlot_same _ countSlot _
  · decide

theorem persist_read_fee (start : Nat) (obs : Observables)
    (state : ContractState) :
    (persist start obs state).readSlot feePaidSlot = obs.feePaid := by
  unfold persist
  rw [readSlot_set_log, forwardCalls_readSlot]
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
  simp [writePayloads_calls, forwardCalls_calls]

theorem persist_events (start : Nat) (obs : Observables) (state : ContractState) :
    (persist start obs state).events = state.events ++ obs.events.map toEvent := by
  unfold persist
  simp [writePayloads_events, forwardCalls_events]

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

private theorem map_const_replicate {α β : Type} (l : List α) (b : β) :
    l.map (fun _ => b) = List.replicate l.length b := by
  induction l with
  | nil => rfl
  | cons _ _ ih => simp [List.replicate_succ, ih]

private theorem sum_replicate_nat (n v : Nat) :
    (List.replicate n v).sum = n * v := by
  induction n with
  | zero => simp
  | succ n ih =>
      simp only [List.replicate_succ, List.sum_cons, ih, Nat.succ_mul]
      omega

private theorem commitObservables_calls_value (target fee msgValue : Word)
    (requests : List Request) :
    (commitObservables target fee msgValue requests).calls.map (·.value) =
      List.replicate requests.length fee ∧
      (commitObservables target fee msgValue requests).calls.map (·.target) =
      List.replicate requests.length target ∧
      (commitObservables target fee msgValue requests).calls.length =
        requests.length := by
  induction requests with
  | nil => simp [commitObservables, requestCall]
  | cons r rest ih =>
      simp only [commitObservables, List.map_cons, List.length_cons,
        List.replicate_succ, requestCall] at ih ⊢
      exact ⟨by rw [ih.1], by rw [ih.2.1], by rw [ih.2.2]⟩

private theorem sourceRun_committed_payload_shape
    (inputs : Inputs) (obs : Observables)
    (hRun : sourceRun inputs = .committed obs) :
    obs.requestCount = obs.payloads.length ∧
      obs.calls.length = obs.requestCount ∧
      obs.payloads.length = inputs.sources.length ∧
      obs.payloads.map normalizedPayload = obs.payloads ∧
      obs.calls.map (·.value) = List.replicate obs.calls.length inputs.fee ∧
      obs.calls.map (·.target) =
        List.replicate obs.calls.length inputs.requestTarget ∧
      inputs.msgValue.val = obs.calls.length * inputs.fee.val := by
  unfold sourceRun at hRun
  split at hRun
  · next hCaller =>
      split at hRun
      · simp at hRun
      · next hNonempty =>
          split at hRun
          · simp at hRun
          · next requests hZip =>
              split at hRun
              · next hValid =>
                  split at hRun
                  · next hProduct =>
                      split at hRun
                      · next hFee =>
                          injection hRun with hObs
                          subst obs
                          have hLen := zipRequests_some_length hZip
                          have hFeeEq : inputs.msgValue.val =
                              requests.length * inputs.fee.val :=
                            beq_iff_eq.mp hFee
                          have hCalls := commitObservables_calls_value
                            inputs.requestTarget inputs.fee inputs.msgValue
                            requests
                          refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
                          · simp [commitObservables]
                          · simp [commitObservables]
                          · simp [commitObservables, payload, hLen]
                          · simp [commitObservables, normalizedPayload, payload]
                          · rw [hCalls.1, hCalls.2.2]
                          · rw [hCalls.2.1, hCalls.2.2]
                          · rw [hCalls.2.2]; exact hFeeEq
                      · simp at hRun
                  · simp at hRun
              · simp at hRun
  · simp at hRun

/-- Under the entry no-wrap premise and the four decode equations the
executed transaction is exactly the outcome of the pinned-source
interpreter: revert passes the pre-call snapshot through, commit persists
on the frame-entry credited state. The two sides differ only by structure
eta on the decoded `Inputs` literal and the ground `if false` injection
flag. -/
private theorem addRequests_run_eq
    (inputs : Inputs) (state : ContractState)
    (hEntry : state.selfBalance.val + inputs.msgValue.val <
      Verity.Core.Uint256.modulus)
    (hSources : readArray state "sources" sourcesBase inputs.sources.length =
      some inputs.sources)
    (hTargets : readArray state "targets" targetsBase inputs.targets.length =
      some inputs.targets)
    (hSourceLens : readArray state "sourceLens" sourceLensBase
      inputs.sourceLens.length = some inputs.sourceLens)
    (hTargetLens : readArray state "targetLens" targetLensBase
      inputs.targetLens.length = some inputs.targetLens) :
    (addRequests inputs).run state =
      match sourceRun inputs with
      | .reverted reason => .revert reason state
      | .committed obs =>
          .success (ofObservables obs)
            (persist (state.readSlot countSlot).val obs
              (credited state inputs)) := by
  unfold Contract.run
  have hap : (addRequests inputs) state =
      match sourceRun inputs with
      | .reverted reason => .revert reason state
      | .committed obs =>
          .success (ofObservables obs)
            (persist (state.readSlot countSlot).val obs
              (credited state inputs)) := by
    unfold addRequests
    rw [if_pos hEntry]
    simp only [readArray_credited, hSources, hTargets, hSourceLens,
      hTargetLens]
    rfl
  rw [hap]
  cases sourceRun inputs with
  | reverted reason => rfl
  | committed obs => rfl

/-- Outcome inversion for the executed transaction under the entry no-wrap
premise and the four decode equations: the run is exactly the
`.revert`-pass-through or the `.success` persistence of the pinned-source
interpreter's own outcome. -/
private theorem addRequests_run_cases
    (inputs : Inputs) (state : ContractState)
    (hEntry : state.selfBalance.val + inputs.msgValue.val <
      Verity.Core.Uint256.modulus)
    (hSources : readArray state "sources" sourcesBase inputs.sources.length =
      some inputs.sources)
    (hTargets : readArray state "targets" targetsBase inputs.targets.length =
      some inputs.targets)
    (hSourceLens : readArray state "sourceLens" sourceLensBase
      inputs.sourceLens.length = some inputs.sourceLens)
    (hTargetLens : readArray state "targetLens" targetLensBase
      inputs.targetLens.length = some inputs.targetLens)
    (r : ContractResult Result)
    (h : (addRequests inputs).run state = r) :
    (∃ reason, sourceRun inputs = .reverted reason ∧
        r = .revert reason state) ∨
    (∃ obs, sourceRun inputs = .committed obs ∧
        r = .success (ofObservables obs)
          (persist (state.readSlot countSlot).val obs
            (credited state inputs))) := by
  rw [addRequests_run_eq inputs state hEntry hSources hTargets hSourceLens
    hTargetLens] at h
  split at h
  · next reason hR =>
      exact Or.inl ⟨reason, hR, h.symm⟩
  · next obs hC =>
      exact Or.inr ⟨obs, hC, h.symm⟩

/-- Composed faithful-plane theorem: the real memory-array transaction has the
same outcome observables as the independently stated pinned-source run.
The entry no-wrap premise is the executed-plane funding condition: without
it the frame-entry payable credit would wrap and the transaction rejects
(`entry_credit_overflow_reverts`), so the pinned-source commit is not the
outcome of a wrapping entry. -/
theorem verity_tx_simulates_pinned_source
    (inputs : Inputs) (state : ContractState)
    (hCountBound : (state.readSlot countSlot).val + inputs.sources.length <
      Verity.Core.Uint256.modulus)
    (hEntry : state.selfBalance.val + inputs.msgValue.val <
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
  rcases addRequests_run_cases inputs state hEntry hSources hTargets
      hSourceLens hTargetLens _ rfl with
    ⟨reason, hRun, hr⟩ | ⟨obs, hRun, hr⟩
  · rw [hr]
    simp [sourceView, observe, ofNat_val, hRun]
  · rw [hr]
    have hCalls := persist_calls (state.readSlot countSlot).val obs
      (credited state inputs)
    have hEvents := persist_events (state.readSlot countSlot).val obs
      (credited state inputs)
    obtain ⟨hCount, hCallsLen, hPayloadLength, hNormalized, _, _, _⟩ :=
      sourceRun_committed_payload_shape inputs obs hRun
    have hBound : (state.readSlot countSlot).val + obs.payloads.length ≤
        Verity.Core.Uint256.modulus := by
      rw [hPayloadLength]
      exact Nat.le_of_lt hCountBound
    have hPayloads := persist_read_payloads
      (state.readSlot countSlot).val obs (credited state inputs) hCount
      hNormalized hBound
    have hCountVal :
        (Verity.Core.Uint256.ofNat
          ((state.readSlot countSlot).val + obs.requestCount)).val =
          (state.readSlot countSlot).val + obs.requestCount := by
      rw [Verity.Core.Uint256.val_ofNat, Nat.mod_eq_of_lt]
      · rw [hCount, hPayloadLength]; exact hCountBound
    simp only [sourceView, hRun, observe, persist_calls, credited_calls,
      persist_events, credited_events, persist_read_count, persist_read_fee,
      drop_map_ofJournal, drop_map_ofEvent]
    rw [hCallsLen, hPayloads]

/-- Any failure, including the injected failure after intermediate
call/event/memory writes, returns the exact pre-transaction snapshot. -/
theorem revert_restores_snapshot
    (inputs : Inputs) (inject : Bool) (state rollback : ContractState)
    (reason : String)
    (h : (addRequests inputs inject).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

/-! ## Value-bearing CALLs: exact forwarding and preservesEthBalance -/

private theorem foldl_sub_values (cs : List CallObs) (w : Word) :
    cs.foldl (fun bal c => bal - c.value) w =
      (cs.map (·.value)).foldl (fun bal v => bal - v) w := by
  induction cs generalizing w with
  | nil => rfl
  | cons c rest ih => simp [ih]

private theorem map_replicate_val (n : Nat) (v : Word) :
    (List.replicate n v).map Verity.Core.Uint256.val = List.replicate n v.val := by
  induction n with
  | zero => rfl
  | succ n ih => simp [ih]

/-- Word-level debit law: forwarding `fee` on each of `n` CALLs out of an
entry balance credited by `msg.value` restores the pre-call balance exactly
when `msg.value = n * fee`. True in wrapping arithmetic, so no non-wrapping
side condition is needed. -/
theorem sub_foldl_replicate (B fee : Word) (n : Nat) (msgValue : Word)
    (h : msgValue.val = n * fee.val) :
    (List.replicate n fee).foldl (fun bal c => bal - c) (B + msgValue) = B := by
  induction n generalizing msgValue with
  | zero =>
      have h0 : msgValue = 0 := by
        apply Verity.Core.Uint256.ext
        simpa using h
      simp [h0]
  | succ n ih =>
      have hSplit : msgValue.val = n * fee.val + fee.val := by
        rw [Nat.succ_mul] at h; exact h
      have hmsgLt : msgValue.val < Verity.Core.Uint256.modulus :=
        msgValue.isLt
      have hTailLt : n * fee.val < Verity.Core.Uint256.modulus := by omega
      have hmVal : (Verity.Core.Uint256.ofNat (n * fee.val)).val =
          n * fee.val := by
        rw [Verity.Core.Uint256.val_ofNat, Nat.mod_eq_of_lt hTailLt]
      have hEntry : msgValue = (Verity.Core.Uint256.ofNat (n * fee.val)) + fee := by
        apply Verity.Core.Uint256.ext
        have hval : ((Verity.Core.Uint256.ofNat (n * fee.val)) + fee).val =
            n * fee.val + fee.val := by
          show ((n * fee.val) % Verity.Core.Uint256.modulus + fee.val) %
              Verity.Core.Uint256.modulus = n * fee.val + fee.val
          rw [Nat.mod_eq_of_lt hTailLt, Nat.mod_eq_of_lt (by omega)]
        rw [hval]; exact hSplit
      have hEq : (B + msgValue) - fee =
          B + Verity.Core.Uint256.ofNat (n * fee.val) := by
        rw [hEntry, ← Verity.Core.Uint256.add_assoc,
          Verity.Core.Uint256.sub_add_cancel]
      simp only [List.replicate_succ, List.foldl_cons, hEq]
      exact ih _ hmVal

/-- Success inversion for the executed transaction: under the four decode
equations, a `.success` outcome implies `sourceRun inputs` committed some
`obs`, the result is that observables record, and the post-state is exactly
`persist` applied to the frame-entry credited state. A `.success` outcome
additionally certifies the entry credit did not wrap — a wrapping entry is
turned away before decode, so the success hypothesis is false there. -/
private theorem addRequests_success_inversion
    (inputs : Inputs) (state : ContractState)
    (hSources : readArray state "sources" sourcesBase inputs.sources.length =
      some inputs.sources)
    (hTargets : readArray state "targets" targetsBase inputs.targets.length =
      some inputs.targets)
    (hSourceLens : readArray state "sourceLens" sourceLensBase
      inputs.sourceLens.length = some inputs.sourceLens)
    (hTargetLens : readArray state "targetLens" targetLensBase
      inputs.targetLens.length = some inputs.targetLens)
    (result : Result) (after : ContractState)
    (h : (addRequests inputs).run state = .success result after) :
    ∃ obs, sourceRun inputs = .committed obs ∧
      ofObservables obs = result ∧
      persist (state.readSlot countSlot).val obs (credited state inputs) =
        after := by
  by_cases hEntry : state.selfBalance.val + inputs.msgValue.val <
      Verity.Core.Uint256.modulus
  · rcases addRequests_run_cases inputs state hEntry hSources hTargets
        hSourceLens hTargetLens _ h with ⟨reason, _, hr⟩ | ⟨obs, hsr, hr⟩
    · simp at hr
    · injection hr with hRes hAfter
      exact ⟨obs, hsr, hRes.symm, hAfter.symm⟩
  · have hRevert : (addRequests inputs).run state =
        .revert "ENTRY_CREDIT_OVERFLOW" state := by
      unfold Contract.run addRequests
      rw [if_neg hEntry]
    rw [hRevert] at h
    simp at h

/-- On a committed batch the executed transaction forwards exactly
`msg.value`: the journal suffix is one `.call` frame per request, every
frame is a `.success` frame to the consolidation-request target carrying
the per-request fee as its value, and the frame values sum to `msg.value`
— the pinned `_requireExactFee` guard exported onto the CALL journal.
Hypotheses are the four memory-array decode equations, as in
`verity_tx_simulates_pinned_source`. -/
theorem committed_journal_forwards_msg_value
    (inputs : Inputs) (state : ContractState)
    (hSources : readArray state "sources" sourcesBase inputs.sources.length =
      some inputs.sources)
    (hTargets : readArray state "targets" targetsBase inputs.targets.length =
      some inputs.targets)
    (hSourceLens : readArray state "sourceLens" sourceLensBase
      inputs.sourceLens.length = some inputs.sourceLens)
    (hTargetLens : readArray state "targetLens" targetLensBase
      inputs.targetLens.length = some inputs.targetLens)
    (result : Result) (after : ContractState)
    (h : (addRequests inputs).run state = .success result after) :
    let frames := after.calls.drop state.calls.length
    frames.length = result.requestCount ∧
      (∀ f ∈ frames, f.kind = .call ∧ f.control = .success ∧
        f.target = inputs.requestTarget.val ∧ f.value = inputs.fee.val) ∧
      (frames.map (fun f => f.value)).sum = inputs.msgValue.val := by
  obtain ⟨obs, hRun, hRes, hAfter⟩ :=
    addRequests_success_inversion inputs state hSources hTargets hSourceLens
      hTargetLens result after h
  obtain ⟨hCount, hCallsLen, _, _, hValues, hTargets', hFeeEq⟩ :=
    sourceRun_committed_payload_shape inputs obs hRun
  subst result
  subst after
  simp only [ofObservables, persist_calls, credited_calls, List.drop_left,
    List.length_map]
  refine ⟨hCallsLen, ?_, ?_⟩
  · intro f hf
    rw [List.mem_map] at hf
    obtain ⟨c, hcMem, rfl⟩ := hf
    have hcValue : c.value = inputs.fee := by
      have hmem : c.value ∈ obs.calls.map (·.value) :=
        List.mem_map_of_mem hcMem
      rw [hValues, List.mem_replicate] at hmem
      exact hmem.2
    have hcTarget : c.target = inputs.requestTarget := by
      have hmem : c.target ∈ obs.calls.map (·.target) :=
        List.mem_map_of_mem hcMem
      rw [hTargets', List.mem_replicate] at hmem
      exact hmem.2
    simp [toJournal, hcTarget, hcValue]
  · have hmap : (obs.calls.map toJournal).map (fun f => f.value) =
        (obs.calls.map (·.value)).map Verity.Core.Uint256.val := by
        simp [List.map_map, toJournal]
    rw [hmap, hValues, map_replicate_val, sum_replicate_nat, hFeeEq]

/-- `preservesEthBalance` (`WithdrawalVault.sol:81--85`), vault side: after
the modeled frame-entry payable credit of `msg.value` and the per-request
CALL debits, every committed run restores the vault's pre-call
`selfBalance` — the modifier's `assert`. A committed run certifies the
entry credit did not wrap (a wrapping `selfBalance + msg.value` is turned
away before decode, `entry_credit_overflow_reverts`), so the debits it
folds over are funded rather than wrapping. Every revert restores the whole
pre-call snapshot (`revert_restores_snapshot`), balance included. The
counterparty credit at the request predeploy is another contract's balance
and stays on the multi-contract plane. -/
theorem committed_preserves_eth_balance
    (inputs : Inputs) (state : ContractState)
    (hSources : readArray state "sources" sourcesBase inputs.sources.length =
      some inputs.sources)
    (hTargets : readArray state "targets" targetsBase inputs.targets.length =
      some inputs.targets)
    (hSourceLens : readArray state "sourceLens" sourceLensBase
      inputs.sourceLens.length = some inputs.sourceLens)
    (hTargetLens : readArray state "targetLens" targetLensBase
      inputs.targetLens.length = some inputs.targetLens)
    (result : Result) (after : ContractState)
    (h : (addRequests inputs).run state = .success result after) :
    after.selfBalance = state.selfBalance := by
  obtain ⟨obs, hRun, _, hAfter⟩ :=
    addRequests_success_inversion inputs state hSources hTargets hSourceLens
      hTargetLens result after h
  obtain ⟨_, hCallsLen, _, _, hValues, _, hFeeEq⟩ :=
    sourceRun_committed_payload_shape inputs obs hRun
  subst after
  rw [persist_selfBalance, selfBalance_credited, foldl_sub_values, hValues]
  exact sub_foldl_replicate state.selfBalance inputs.fee obs.calls.length
    inputs.msgValue hFeeEq

/-! ## Kill-line mutants (not source)

Model mutants for the value-plane kill-lines. `addRequestsValueBlind` keeps the frame-entry payable credit and the
journaled CALL frames but drops the per-CALL debit — exactly the pre-lift
stub behavior ("success stubs move no wei"). `addRequestsDoubleDebit`
debits twice the journaled value per CALL. `addRequestsJournalValueBlind`
debits honestly but journals each frame with value `0`. None of these is
the model of record; they exist so the kill-lines in
`Tests/ConsolidationTxMutants.lean` can refute `preservesEthBalance` and
exact forwarding on mutants of this model. -/

def forwardCallsDouble (state : ContractState) : List CallObs → ContractState
  | [] => state
  | c :: rest =>
      forwardCallsDouble
        { state with selfBalance := state.selfBalance - c.value - c.value } rest

def toJournalValueBlind (c : CallObs) : ExternalCall :=
  { toJournal c with value := 0 }

def persistPlain (start : Nat) (obs : Observables) (state : ContractState) :
    ContractState :=
  let dirty := writePayloads start obs.payloads state
  let dirty := (dirty.writeSlot countSlot
      (Verity.Core.Uint256.ofNat (start + obs.requestCount)))
    |>.writeSlot feePaidSlot obs.feePaid
  { dirty with
    events := dirty.events ++ obs.events.map toEvent
    calls := dirty.calls ++ obs.calls.map toJournal }

def persistDoubleDebit (start : Nat) (obs : Observables)
    (state : ContractState) : ContractState :=
  let dirty := writePayloads start obs.payloads state
  let dirty := (dirty.writeSlot countSlot
      (Verity.Core.Uint256.ofNat (start + obs.requestCount)))
    |>.writeSlot feePaidSlot obs.feePaid
  let dirty := forwardCallsDouble dirty obs.calls
  { dirty with
    events := dirty.events ++ obs.events.map toEvent
    calls := dirty.calls ++ obs.calls.map toJournal }

def persistJournalValueBlind (start : Nat) (obs : Observables)
    (state : ContractState) : ContractState :=
  let dirty := writePayloads start obs.payloads state
  let dirty := (dirty.writeSlot countSlot
      (Verity.Core.Uint256.ofNat (start + obs.requestCount)))
    |>.writeSlot feePaidSlot obs.feePaid
  let dirty := forwardCalls dirty obs.calls
  { dirty with
    events := dirty.events ++ obs.events.map toEvent
    calls := dirty.calls ++ obs.calls.map toJournalValueBlind }

/-- Common skeleton of the value-plane mutants: same decode, same
`sourceRun` decision tree, same entry credit; only `persistFn` differs. -/
def addRequestsWith
    (persistFn : Nat → Observables → ContractState → ContractState)
    (inputs : Inputs) : Contract Result := fun snapshot =>
  match readArray (credited snapshot inputs) "sources" sourcesBase
      inputs.sources.length,
      readArray (credited snapshot inputs) "targets" targetsBase
      inputs.targets.length,
      readArray (credited snapshot inputs) "sourceLens" sourceLensBase
      inputs.sourceLens.length,
      readArray (credited snapshot inputs) "targetLens" targetLensBase
      inputs.targetLens.length with
  | some sources, some targets, some sourceLens, some targetLens =>
      let decoded : Inputs :=
        { inputs with
          sources := sources, targets := targets,
          sourceLens := sourceLens, targetLens := targetLens }
      match sourceRun decoded with
      | .reverted reason => .revert reason snapshot
      | .committed obs =>
          .success (ofObservables obs)
            (persistFn (snapshot.readSlot countSlot).val obs
              (credited snapshot inputs))
  | _, _, _, _ => .revert "MEMORY_ARRAY_DECODE" snapshot

def addRequestsValueBlind (inputs : Inputs) : Contract Result :=
  addRequestsWith persistPlain inputs

def addRequestsDoubleDebit (inputs : Inputs) : Contract Result :=
  addRequestsWith persistDoubleDebit inputs

def addRequestsJournalValueBlind (inputs : Inputs) : Contract Result :=
  addRequestsWith persistJournalValueBlind inputs

/-! ## FunctionSpec call/event/memory fragment (not a transcription)

`requestOne` is a single-pair bridge spec exercising the three constructors,
not a transcription of the Solidity loop (its `requests` counter has no
storage counterpart in `WithdrawalVault`). The official `denoteFunction` still maps `Expr.call` / `Stmt.externalCallBind`
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
