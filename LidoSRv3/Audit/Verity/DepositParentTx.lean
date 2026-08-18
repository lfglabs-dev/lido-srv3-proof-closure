import LidoSRv3.Audit.Source.DepositCorrespondence
import Contracts.Common

/-!
# P-DEPOSIT-1 composed executable transaction

This module is the faithful bounded two-batch transaction slice for the pinned
`StakingRouter.deposit` path.  Unlike `DepositLedgerTx`, authorization,
allocation, dynamic deposit data, deposit-data roots, the Lido pull, and the
two beacon value calls execute in one `Verity.Contract.run` program.  Storage
uses `writeSlot`/`writeMapUint`; calls carry concrete targets and values through
`externalCallBindTo`.

The correspondence theorem `execute_observes_source` is general: it quantifies
over every `Inputs` and every entry `ContractState` satisfying the stated
`Preconditions`, and it is proved by reducing the program rather than by
`decide` on one ground term.  Observables expose the per-batch mapping words
(allocation, dynamic-data commitment, deposit-data root) alongside the
aggregates and the ordered call journal projected onto name, destination, wei
value and argument words.

Scope: this is not an EVM theorem.  It is a Verity-EDSL transaction whose
storage, journal and revert boundary are the model of the pinned Solidity path
under `A-VERITY-SCAFFOLD`; the pinned-source shape is `A-SOURCE-SHAPED`.
-/

namespace LidoSRv3.Audit.Verity.DepositParentTx

open _root_.Verity
open _root_.Contracts

abbrev Word := _root_.Verity.Core.Uint256

def counterSlot : Nat := 0
def lidoDepositableSlot : Nat := 1
def allocationSlot : Nat := 2
def dynamicDataSlot : Nat := 3
def depositRootSlot : Nat := 4

structure Batch where
  moduleId : Word
  keys : Word
  amount : Word
  dynamicDataCommitment : Word
  depositDataRoot : Word
  dataValid : Bool
  rootValid : Bool
  moduleCallOk : Bool
  beaconCallOk : Bool
  deriving Repr, DecidableEq

structure Inputs where
  authorized : Bool
  moduleActive : Bool
  allocationValid : Bool
  lidoCallOk : Bool
  /-- The per-key wei the beacon leg sends; the executable stand-in for
  `BeaconChainDepositor.DEPOSIT_SIZE`. -/
  depositSize : Word
  lido : Address
  module : Address
  beacon : Address
  first : Batch
  second : Batch
  deriving Repr, DecidableEq

def totalAmount (inputs : Inputs) : Word := inputs.first.amount + inputs.second.amount

def totalKeys (inputs : Inputs) : Word := inputs.first.keys + inputs.second.keys

/-- `"fail"` is Verity's reserved failing-callee name, so an unhealthy leg
really reverts inside the frame instead of being asserted away. -/
def callName (ok : Bool) (name : String) : String := if ok then name else "fail"

/-! ## The transaction -/

def writeMap (slotId : Nat) (key value : Word) : Contract Unit :=
  fun state => .success () (state.writeMapUint slotId key value)

def getState : Contract ContractState :=
  fun state => .success state state

def creditRouter (amount : Word) : Contract Unit :=
  fun state => .success () { state with selfBalance := state.selfBalance + amount }

/-- One module's leg: record the allocation, obtain deposit data through a real
call frame, commit the dynamic data and the deposit-data root.  Both validity
guards sit after their own storage write, so a failure has real state to undo. -/
def processBatch (inputs : Inputs) (batch : Batch) : Contract Unit := do
  writeMap allocationSlot batch.moduleId batch.keys
  externalCallBindTo inputs.module 0 [] (callName batch.moduleCallOk "obtainDepositData")
    [batch.moduleId, batch.keys]
  writeMap dynamicDataSlot batch.moduleId batch.dynamicDataCommitment
  require batch.dataValid "INVALID_DYNAMIC_DEPOSIT_DATA"
  writeMap depositRootSlot batch.moduleId batch.depositDataRoot
  require batch.rootValid "INVALID_DEPOSIT_DATA_ROOT"

/-- `externalCallBindTo` is a caller-side frame: it journals and debits, but
callee-originated inflow lives in `Verity.MultiContract`, so the credit that
`Lido.withdrawDepositableEther` performs is an explicit step. -/
def pullFromLido (inputs : Inputs) (total : Word) : Contract Unit := do
  externalCallBindTo inputs.lido 0 [] (callName inputs.lidoCallOk "withdrawDepositableEther")
    [total]
  let state ← getState
  require (total ≤ state.readSlot lidoDepositableSlot) "NOT_ENOUGH_ETHER"
  setStorage ⟨lidoDepositableSlot⟩ (state.readSlot lidoDepositableSlot - total)
  creditRouter total

def pushBatch (inputs : Inputs) (batch : Batch) : Contract Unit :=
  externalCallBindTo inputs.beacon batch.amount []
    (callName batch.beaconCallOk "depositToBeacon")
    [batch.moduleId, batch.keys, batch.dynamicDataCommitment, batch.depositDataRoot]

/-- The complete bounded transaction.  The counter/allocation/data/root writes
precede several possible failures, making rollback sensitivity executable. -/
def execute (inputs : Inputs) : Contract Unit := do
  require inputs.authorized "NOT_AUTHORIZED"
  require inputs.moduleActive "MODULE_NOT_ACTIVE"
  require inputs.allocationValid "INVALID_ALLOCATION"
  let state ← getState
  setStorage ⟨counterSlot⟩ (state.readSlot counterSlot + 1)
  processBatch inputs inputs.first
  processBatch inputs inputs.second
  let total := inputs.first.amount + inputs.second.amount
  require (total == (inputs.first.keys + inputs.second.keys) * inputs.depositSize)
    "ALLOCATION_VALUE_MISMATCH"
  pullFromLido inputs total
  pushBatch inputs inputs.first
  pushBatch inputs inputs.second
  let after ← getState
  require (after.selfBalance == state.selfBalance) "ASSERT_BALANCE_UNCHANGED"

/-! ## The journal the transaction has to produce

`moduleEntry`, `pullEntry` and `pushEntry` are written from the pinned source
schedule.  `execute` never mentions them: the theorems below *derive* them from
the `externalCallBindTo` frames the transaction actually runs. -/

def moduleEntry (inputs : Inputs) (batch : Batch) : ExternalCall :=
  linkedCallEntryTo "obtainDepositData" inputs.module 0 [batch.moduleId, batch.keys]

def pullEntry (inputs : Inputs) : ExternalCall :=
  linkedCallEntryTo "withdrawDepositableEther" inputs.lido 0 [totalAmount inputs]

def pushEntry (inputs : Inputs) (batch : Batch) : ExternalCall :=
  linkedCallEntryTo "depositToBeacon" inputs.beacon batch.amount
    [batch.moduleId, batch.keys, batch.dynamicDataCommitment, batch.depositDataRoot]

def expectedCalls (inputs : Inputs) : List ExternalCall :=
  [ moduleEntry inputs inputs.first
  , moduleEntry inputs inputs.second
  , pullEntry inputs
  , pushEntry inputs inputs.first
  , pushEntry inputs inputs.second ]

/-! ## Observables

Deliberately *not* the post-state: the per-module mapping words the guarantee
talks about, the reentrancy counter, the Lido ledger, the conservation
aggregates, and the call journal projected onto name, destination, wei value and
argument words. -/

@[ext] structure Observables where
  committed : Bool
  guardCounter : Nat
  allocationCells : List Nat
  dynamicDataCells : List Nat
  depositRootCells : List Nat
  lidoDepositableAfter : Nat
  pulled : Nat
  pushed : Nat
  routerRetained : Nat
  callNames : List String
  callTargets : List Nat
  callValues : List Nat
  callArgs : List (List Nat)
  deriving Repr, DecidableEq

def callValueOf (name : String) : List ExternalCall → Nat
  | [] => 0
  | call :: rest => (if call.name == name then call.value else 0) + callValueOf name rest

/-- The mapping words at `mapSlot` under each probed module id, in probe order. -/
def cellsOf (state : ContractState) (mapSlot : Nat) (keys : List Word) : List Nat :=
  keys.map (fun key => (state.readMapUint mapSlot key).val)

/-- The module ids a two-batch deposit writes under. -/
def probes (inputs : Inputs) : List Word := [inputs.first.moduleId, inputs.second.moduleId]

def viewOf (before after : ContractState) (probeKeys : List Word) (committed : Bool) :
    Observables :=
  let fresh := after.calls.drop before.calls.length
  { committed := committed
    guardCounter := (after.readSlot counterSlot).val
    allocationCells := cellsOf after allocationSlot probeKeys
    dynamicDataCells := cellsOf after dynamicDataSlot probeKeys
    depositRootCells := cellsOf after depositRootSlot probeKeys
    lidoDepositableAfter := (after.readSlot lidoDepositableSlot).val
    pulled := (before.readSlot lidoDepositableSlot).val - (after.readSlot lidoDepositableSlot).val
    pushed := callValueOf "depositToBeacon" fresh
    routerRetained := after.selfBalance.val
    callNames := fresh.map (·.name)
    callTargets := fresh.map (·.target)
    callValues := fresh.map (·.value)
    callArgs := fresh.map (·.calldata) }

def observe (before : ContractState) (probeKeys : List Word) :
    ContractResult Unit → Observables
  | .revert _ rollback => viewOf before rollback probeKeys false
  | .success _ after => viewOf before after probeKeys true

/-- Source-shaped specification of a committing two-batch deposit, written
independently of `execute`. -/
def sourceObservables (inputs : Inputs) (before : ContractState) : Observables :=
  { committed := true
    guardCounter := (before.readSlot counterSlot + 1).val
    allocationCells := [inputs.first.keys.val, inputs.second.keys.val]
    dynamicDataCells :=
      [inputs.first.dynamicDataCommitment.val, inputs.second.dynamicDataCommitment.val]
    depositRootCells := [inputs.first.depositDataRoot.val, inputs.second.depositDataRoot.val]
    lidoDepositableAfter :=
      (before.readSlot lidoDepositableSlot).val - (totalAmount inputs).val
    pulled := (totalAmount inputs).val
    pushed := inputs.first.amount.val + inputs.second.amount.val
    routerRetained := 0
    callNames :=
      ["obtainDepositData", "obtainDepositData", "withdrawDepositableEther",
       "depositToBeacon", "depositToBeacon"]
    callTargets :=
      [inputs.module.toNat, inputs.module.toNat, inputs.lido.toNat,
       inputs.beacon.toNat, inputs.beacon.toNat]
    callValues := [0, 0, 0, inputs.first.amount.val, inputs.second.amount.val]
    callArgs :=
      [ [inputs.first.moduleId.val, inputs.first.keys.val]
      , [inputs.second.moduleId.val, inputs.second.keys.val]
      , [(totalAmount inputs).val]
      , [inputs.first.moduleId.val, inputs.first.keys.val,
          inputs.first.dynamicDataCommitment.val, inputs.first.depositDataRoot.val]
      , [inputs.second.moduleId.val, inputs.second.keys.val,
          inputs.second.dynamicDataCommitment.val, inputs.second.depositDataRoot.val] ] }

/-- What a reverting transaction leaves visible: the entry world, unchanged. -/
def idleObservables (before : ContractState) (probeKeys : List Word) : Observables :=
  { committed := false
    guardCounter := (before.readSlot counterSlot).val
    allocationCells := cellsOf before allocationSlot probeKeys
    dynamicDataCells := cellsOf before dynamicDataSlot probeKeys
    depositRootCells := cellsOf before depositRootSlot probeKeys
    lidoDepositableAfter := (before.readSlot lidoDepositableSlot).val
    pulled := 0
    pushed := 0
    routerRetained := before.selfBalance.val
    callNames := []
    callTargets := []
    callValues := []
    callArgs := [] }

/-! ## Preconditions

Every field is a guard the transaction really evaluates, or the arithmetic
side condition that keeps the EVM-modular ledger from wrapping.  Nothing here
is assumed about the post-state. -/

structure Preconditions (inputs : Inputs) (state : ContractState) : Prop where
  authorized : inputs.authorized = true
  moduleActive : inputs.moduleActive = true
  allocationValid : inputs.allocationValid = true
  lidoCallOk : inputs.lidoCallOk = true
  firstModuleCallOk : inputs.first.moduleCallOk = true
  firstDataValid : inputs.first.dataValid = true
  firstRootValid : inputs.first.rootValid = true
  firstBeaconCallOk : inputs.first.beaconCallOk = true
  secondModuleCallOk : inputs.second.moduleCallOk = true
  secondDataValid : inputs.second.dataValid = true
  secondRootValid : inputs.second.rootValid = true
  secondBeaconCallOk : inputs.second.beaconCallOk = true
  /-- Two distinct modules, so neither leg's mapping words overwrite the other's. -/
  distinctModules : inputs.second.moduleId ≠ inputs.first.moduleId
  /-- The `ALLOCATION_VALUE_MISMATCH` guard: value is `DEPOSIT_SIZE` per key. -/
  valueMatches : totalAmount inputs = totalKeys inputs * inputs.depositSize
  /-- The router owns no ether of its own when the batch starts, so every wei
  the pushes move has to come from the Lido pull. -/
  entryBalance : state.selfBalance = 0
  /-- `NOT_ENOUGH_ETHER`: Lido really holds the aggregate. -/
  funded : totalAmount inputs ≤ state.readSlot lidoDepositableSlot
  /-- The aggregate does not wrap the 256-bit ledger. -/
  noWrap : inputs.first.amount.val + inputs.second.amount.val < _root_.Verity.Core.Uint256.modulus

/-! ## The state the transaction builds

Written with the same combinators the program uses, so each stage lemma is a
direct reduction rather than a re-derivation. -/

def afterCall (value : Word) (entry : ExternalCall) (s : ContractState) : ContractState :=
  { s with selfBalance := s.selfBalance - value, calls := s.calls ++ [entry] }

def afterBatch (inputs : Inputs) (batch : Batch) (s : ContractState) : ContractState :=
  ((afterCall 0 (moduleEntry inputs batch)
      (s.writeMapUint allocationSlot batch.moduleId batch.keys)).writeMapUint
      dynamicDataSlot batch.moduleId batch.dynamicDataCommitment).writeMapUint
      depositRootSlot batch.moduleId batch.depositDataRoot

def afterPull (inputs : Inputs) (s : ContractState) : ContractState :=
  let s1 := afterCall 0 (pullEntry inputs) s
  let s2 := s1.writeSlot lidoDepositableSlot
    (s1.readSlot lidoDepositableSlot - totalAmount inputs)
  { s2 with selfBalance := s2.selfBalance + totalAmount inputs }

def afterPush (inputs : Inputs) (batch : Batch) (s : ContractState) : ContractState :=
  afterCall batch.amount (pushEntry inputs batch) s

def committedState (inputs : Inputs) (s : ContractState) : ContractState :=
  afterPush inputs inputs.second
    (afterPush inputs inputs.first
      (afterPull inputs
        (afterBatch inputs inputs.second
          (afterBatch inputs inputs.first
            (s.writeSlot counterSlot (s.readSlot counterSlot + 1))))))

/-! ## Word and lens laws

Verity ships the same-key mapping law but no disjoint-key or cross-channel
companions, so the laws the two-batch chain needs are proved here. -/

theorem zero_le (a : Word) : (0 : Word) ≤ a := by
  show (0 : Word).val ≤ a.val
  simp

theorem uintWords (args : List Word) : args.flatMap ExternalArg.toWords = args := by
  induction args with
  | nil => rfl
  | cons a rest ih => simp [List.flatMap_cons, ExternalArg.toWords]

@[simp] theorem readSlot_writeMapUint' (s : ContractState) (mapSlot : Nat) (key value : Word)
    (slotId : Nat) : (s.writeMapUint mapSlot key value).readSlot slotId = s.readSlot slotId := rfl

@[simp] theorem readMapUint_writeSlot (s : ContractState) (slotId : Nat) (value : Word)
    (mapSlot : Nat) (key : Word) :
    (s.writeSlot slotId value).readMapUint mapSlot key = s.readMapUint mapSlot key := rfl

@[simp] theorem readMapUint_writeMapUint_other_slot (s : ContractState)
    {mapSlot mapSlot' : Nat} (h : mapSlot' ≠ mapSlot) (key key' value : Word) :
    (s.writeMapUint mapSlot key value).readMapUint mapSlot' key'
      = s.readMapUint mapSlot' key' := by
  simp [ContractState.readMapUint, ContractState.storageMapUint, ContractState.writeMapUint, h]

@[simp] theorem readMapUint_writeMapUint_other_key (s : ContractState) (mapSlot : Nat)
    {key key' : Word} (h : key' ≠ key) (value : Word) :
    (s.writeMapUint mapSlot key value).readMapUint mapSlot key'
      = s.readMapUint mapSlot key' := by
  simp [ContractState.readMapUint, ContractState.storageMapUint, ContractState.writeMapUint, h]

@[simp] theorem readSlot_afterCall (value : Word) (entry : ExternalCall) (s : ContractState)
    (slotId : Nat) : (afterCall value entry s).readSlot slotId = s.readSlot slotId := rfl

@[simp] theorem readMapUint_afterCall (value : Word) (entry : ExternalCall) (s : ContractState)
    (mapSlot : Nat) (key : Word) :
    (afterCall value entry s).readMapUint mapSlot key = s.readMapUint mapSlot key := rfl

@[simp] theorem selfBalance_afterCall (value : Word) (entry : ExternalCall) (s : ContractState) :
    (afterCall value entry s).selfBalance = s.selfBalance - value := rfl

@[simp] theorem calls_afterCall (value : Word) (entry : ExternalCall) (s : ContractState) :
    (afterCall value entry s).calls = s.calls ++ [entry] := rfl

@[simp] theorem selfBalance_writeSlot (s : ContractState) (slotId : Nat) (value : Word) :
    (s.writeSlot slotId value).selfBalance = s.selfBalance := rfl

@[simp] theorem selfBalance_writeMapUint (s : ContractState) (mapSlot : Nat) (key value : Word) :
    (s.writeMapUint mapSlot key value).selfBalance = s.selfBalance := rfl

@[simp] theorem calls_writeSlot (s : ContractState) (slotId : Nat) (value : Word) :
    (s.writeSlot slotId value).calls = s.calls := rfl

@[simp] theorem calls_writeMapUint (s : ContractState) (mapSlot : Nat) (key value : Word) :
    (s.writeMapUint mapSlot key value).calls = s.calls := rfl

@[simp] theorem readSlot_afterBatch (inputs : Inputs) (batch : Batch) (s : ContractState)
    (slotId : Nat) : (afterBatch inputs batch s).readSlot slotId = s.readSlot slotId := rfl

@[simp] theorem readSlot_afterPush (inputs : Inputs) (batch : Batch) (s : ContractState)
    (slotId : Nat) : (afterPush inputs batch s).readSlot slotId = s.readSlot slotId := rfl

@[simp] theorem readSlot_afterPull (inputs : Inputs) (s : ContractState) (slotId : Nat) :
    (afterPull inputs s).readSlot slotId
      = (s.writeSlot lidoDepositableSlot
          (s.readSlot lidoDepositableSlot - totalAmount inputs)).readSlot slotId := rfl

@[simp] theorem readMapUint_afterPull (inputs : Inputs) (s : ContractState) (mapSlot : Nat)
    (key : Word) : (afterPull inputs s).readMapUint mapSlot key = s.readMapUint mapSlot key := rfl

@[simp] theorem calls_afterBatch (inputs : Inputs) (batch : Batch) (s : ContractState) :
    (afterBatch inputs batch s).calls = s.calls ++ [moduleEntry inputs batch] := rfl

@[simp] theorem calls_afterPull (inputs : Inputs) (s : ContractState) :
    (afterPull inputs s).calls = s.calls ++ [pullEntry inputs] := rfl

@[simp] theorem calls_afterPush (inputs : Inputs) (batch : Batch) (s : ContractState) :
    (afterPush inputs batch s).calls = s.calls ++ [pushEntry inputs batch] := rfl

@[simp] theorem selfBalance_afterBatch (inputs : Inputs) (batch : Batch) (s : ContractState) :
    (afterBatch inputs batch s).selfBalance = s.selfBalance := by
  show s.selfBalance - 0 = s.selfBalance
  exact _root_.Verity.Core.Uint256.sub_zero _

@[simp] theorem selfBalance_afterPull (inputs : Inputs) (s : ContractState) :
    (afterPull inputs s).selfBalance = s.selfBalance + totalAmount inputs := by
  show s.selfBalance - 0 + totalAmount inputs = _
  rw [_root_.Verity.Core.Uint256.sub_zero]

@[simp] theorem selfBalance_afterPush (inputs : Inputs) (batch : Batch) (s : ContractState) :
    (afterPush inputs batch s).selfBalance = s.selfBalance - batch.amount := rfl

/-! ## Stage reductions -/

theorem bindTo_apply (target : Address) (value : Word) (name : String)
    (args : List Word) (s : ContractState)
    (hName : name ≠ "fail") (hBal : value ≤ s.selfBalance) :
    externalCallBindTo target value ([] : List String) name args s =
      .success () (afterCall value (linkedCallEntryTo name target value args) s) := by
  have hs : externalCallStubSuccess name = true := by
    simp [externalCallStubSuccess, hName]
  simp [externalCallBindTo, hBal, hs, uintWords, afterCall, linkedCallEntryTo, linkedCallEntry]

theorem processBatch_apply (inputs : Inputs) (batch : Batch) (s : ContractState)
    (hCall : batch.moduleCallOk = true) (hData : batch.dataValid = true)
    (hRoot : batch.rootValid = true) :
    processBatch inputs batch s = .success () (afterBatch inputs batch s) := by
  have hFrame := bindTo_apply inputs.module 0 "obtainDepositData" [batch.moduleId, batch.keys]
    (s.writeMapUint allocationSlot batch.moduleId batch.keys) (by decide) (zero_le _)
  simp only [processBatch, Bind.bind, _root_.Verity.bind, writeMap, callName, hCall, hData,
    hRoot, if_true, hFrame, _root_.Verity.require, afterBatch, moduleEntry]

theorem pullFromLido_apply (inputs : Inputs) (s : ContractState)
    (hCall : inputs.lidoCallOk = true)
    (hFunded : totalAmount inputs ≤ s.readSlot lidoDepositableSlot) :
    pullFromLido inputs (totalAmount inputs) s = .success () (afterPull inputs s) := by
  have hFrame := bindTo_apply inputs.lido 0 "withdrawDepositableEther" [totalAmount inputs] s
    (by decide) (zero_le _)
  have hGuard : decide (totalAmount inputs
      ≤ (afterCall 0 (linkedCallEntryTo "withdrawDepositableEther" inputs.lido 0
          [totalAmount inputs]) s).readSlot lidoDepositableSlot) = true :=
    decide_eq_true hFunded
  simp only [pullFromLido, Bind.bind, _root_.Verity.bind, callName, hCall, if_true,
    hFrame, getState, _root_.Verity.require, hGuard, setStorage, creditRouter,
    afterPull, pullEntry]
  try rfl

theorem pushBatch_apply (inputs : Inputs) (batch : Batch) (s : ContractState)
    (hCall : batch.beaconCallOk = true) (hBal : batch.amount ≤ s.selfBalance) :
    pushBatch inputs batch s = .success () (afterPush inputs batch s) := by
  have hFrame := bindTo_apply inputs.beacon batch.amount "depositToBeacon"
    [batch.moduleId, batch.keys, batch.dynamicDataCommitment, batch.depositDataRoot] s
    (by decide) hBal
  simp only [pushBatch, callName, hCall, if_true, hFrame, afterPush, pushEntry]

/-! ## Ledger arithmetic

The router's balance is EVM-modular.  Under `Preconditions.noWrap` the two
pushes spend exactly what the pull credited, so the closing
`ASSERT_BALANCE_UNCHANGED` holds by cancellation rather than by assumption. -/

theorem total_val (inputs : Inputs)
    (hNoWrap : inputs.first.amount.val + inputs.second.amount.val < _root_.Verity.Core.Uint256.modulus) :
    (totalAmount inputs).val = inputs.first.amount.val + inputs.second.amount.val :=
  _root_.Verity.Core.Uint256.add_eq_of_lt hNoWrap

theorem first_le_total (inputs : Inputs)
    (hNoWrap : inputs.first.amount.val + inputs.second.amount.val < _root_.Verity.Core.Uint256.modulus) :
    inputs.first.amount ≤ totalAmount inputs := by
  show inputs.first.amount.val ≤ (totalAmount inputs).val
  rw [total_val inputs hNoWrap]
  omega

theorem total_sub_first (inputs : Inputs) :
    totalAmount inputs - inputs.first.amount = inputs.second.amount := by
  show inputs.first.amount + inputs.second.amount - inputs.first.amount = _
  rw [_root_.Verity.Core.Uint256.add_comm]
  exact _root_.Verity.Core.Uint256.sub_add_cancel _ _

/-! ## Composed correspondence -/

theorem execute_apply (inputs : Inputs) (state : ContractState)
    (h : Preconditions inputs state) :
    execute inputs state = .success () (committedState inputs state) := by
  set entry := state.writeSlot counterSlot (state.readSlot counterSlot + 1) with hentry
  set s1 := afterBatch inputs inputs.first entry with hs1
  set s2 := afterBatch inputs inputs.second s1 with hs2
  set s3 := afterPull inputs s2 with hs3
  set s4 := afterPush inputs inputs.first s3 with hs4
  -- the Lido ledger is untouched by the counter and the six mapping writes
  have hLido : s2.readSlot lidoDepositableSlot = state.readSlot lidoDepositableSlot := by
    have hne : lidoDepositableSlot ≠ counterSlot := by decide
    simp [hs2, hs1, hentry, afterBatch, ContractState.readSlot_writeSlot_other _ hne]
  have hFunded : totalAmount inputs ≤ s2.readSlot lidoDepositableSlot := by
    rw [hLido]; exact h.funded
  -- balances along the chain
  have hbal2 : s2.selfBalance = 0 := by
    simp [hs2, hs1, hentry, afterBatch, h.entryBalance]
  have hbal3 : s3.selfBalance = totalAmount inputs := by
    simp [hs3, afterPull, hbal2, _root_.Verity.Core.Uint256.zero_add]
  have hbalFirst : inputs.first.amount ≤ s3.selfBalance := by
    rw [hbal3]; exact first_le_total inputs h.noWrap
  have hbal4 : s4.selfBalance = inputs.second.amount := by
    rw [hs4, afterPush, selfBalance_afterCall, hbal3, total_sub_first]
  have hbalSecond : inputs.second.amount ≤ s4.selfBalance := by
    simp [hbal4]
  have hclose : (afterPush inputs inputs.second s4).selfBalance = state.selfBalance := by
    rw [afterPush, selfBalance_afterCall, hbal4, _root_.Verity.Core.Uint256.sub_self,
      h.entryBalance]
  simp only [execute, Bind.bind, _root_.Verity.bind, _root_.Verity.require, h.authorized,
    h.moduleActive, h.allocationValid, if_true, getState, setStorage, ← hentry,
    processBatch_apply inputs inputs.first entry h.firstModuleCallOk h.firstDataValid
      h.firstRootValid, ← hs1,
    processBatch_apply inputs inputs.second s1 h.secondModuleCallOk h.secondDataValid
      h.secondRootValid, ← hs2]
  have hguard : (inputs.first.amount + inputs.second.amount
      == (inputs.first.keys + inputs.second.keys) * inputs.depositSize) = true := by
    have := h.valueMatches
    simp only [totalAmount, totalKeys] at this
    simp [this]
  rw [hguard]
  simp only [if_true, show inputs.first.amount + inputs.second.amount = totalAmount inputs from rfl,
    pullFromLido_apply inputs s2 h.lidoCallOk hFunded, ← hs3,
    pushBatch_apply inputs inputs.first s3 h.firstBeaconCallOk hbalFirst, ← hs4,
    pushBatch_apply inputs inputs.second s4 h.secondBeaconCallOk hbalSecond,
    committedState]
  rw [hclose]
  simp only [beq_self_eq_true, if_true, hs4, hs3, hs2, hs1, hentry]
  try rfl

theorem execute_run (inputs : Inputs) (state : ContractState)
    (h : Preconditions inputs state) :
    (execute inputs).run state = .success () (committedState inputs state) := by
  simp [Contract.run, execute_apply inputs state h]

/-- The executable Verity transaction, run through `Contract.run`, produces
exactly the observables the pinned two-batch Solidity deposit prescribes: the
per-module allocation, dynamic-data and deposit-data-root words, the guard
counter, the Lido ledger, both conservation aggregates, the router's closing
retention, and the external-call journal down to name, destination, wei value,
argument words and order.  This holds for every `Inputs` and every entry state
the guards accept, not for one ground term. -/
theorem execute_observes_source (inputs : Inputs) (state : ContractState)
    (h : Preconditions inputs state) :
    observe state (probes inputs) ((execute inputs).run state)
      = sourceObservables inputs state := by
  have hAllocDyn : dynamicDataSlot ≠ allocationSlot := by decide
  have hAllocRoot : depositRootSlot ≠ allocationSlot := by decide
  have hDynAlloc : allocationSlot ≠ dynamicDataSlot := by decide
  have hDynRoot : depositRootSlot ≠ dynamicDataSlot := by decide
  have hRootAlloc : allocationSlot ≠ depositRootSlot := by decide
  have hRootDyn : dynamicDataSlot ≠ depositRootSlot := by decide
  have hne : inputs.second.moduleId ≠ inputs.first.moduleId := h.distinctModules
  have hne' : inputs.first.moduleId ≠ inputs.second.moduleId := fun hEq => hne hEq.symm
  have hCounter : lidoDepositableSlot ≠ counterSlot := by decide
  have hLido : counterSlot ≠ lidoDepositableSlot := by decide
  rw [execute_run inputs state h]
  have hbal : (committedState inputs state).selfBalance = 0 := by
    simp only [committedState, selfBalance_afterPush, selfBalance_afterPull,
      selfBalance_afterBatch, selfBalance_writeSlot, h.entryBalance,
      _root_.Verity.Core.Uint256.zero_add]
    rw [total_sub_first, _root_.Verity.Core.Uint256.sub_self]
  have hcalls : (committedState inputs state).calls = state.calls ++ expectedCalls inputs := by
    simp only [committedState, calls_afterPush, calls_afterPull, calls_afterBatch,
      calls_writeSlot, expectedCalls, List.append_assoc, List.cons_append, List.nil_append]
  have hlidoAfter : (committedState inputs state).readSlot lidoDepositableSlot
      = state.readSlot lidoDepositableSlot - totalAmount inputs := by
    simp only [committedState, readSlot_afterPush, readSlot_afterPull, readSlot_afterBatch,
      ContractState.readSlot_writeSlot_same,
      ContractState.readSlot_writeSlot_other _ hCounter]
  have hcount : (committedState inputs state).readSlot counterSlot
      = state.readSlot counterSlot + 1 := by
    simp only [committedState, readSlot_afterPush, readSlot_afterPull, readSlot_afterBatch,
      ContractState.readSlot_writeSlot_other _ hLido,
      ContractState.readSlot_writeSlot_same]
  have hAllocFirst : (committedState inputs state).readMapUint allocationSlot inputs.first.moduleId
      = inputs.first.keys := by
    simp only [committedState, afterPush, afterBatch, readMapUint_afterCall, readMapUint_afterPull,
      readMapUint_writeMapUint_other_slot _ hRootAlloc,
      readMapUint_writeMapUint_other_slot _ hDynAlloc,
      readMapUint_writeMapUint_other_key _ _ hne',
      ContractState.readMapUint_writeMapUint_same]
  have hAllocSecond : (committedState inputs state).readMapUint allocationSlot inputs.second.moduleId
      = inputs.second.keys := by
    simp only [committedState, afterPush, afterBatch, readMapUint_afterCall, readMapUint_afterPull,
      readMapUint_writeMapUint_other_slot _ hRootAlloc,
      readMapUint_writeMapUint_other_slot _ hDynAlloc,
      ContractState.readMapUint_writeMapUint_same]
  have hDynFirst : (committedState inputs state).readMapUint dynamicDataSlot inputs.first.moduleId
      = inputs.first.dynamicDataCommitment := by
    simp only [committedState, afterPush, afterBatch, readMapUint_afterCall, readMapUint_afterPull,
      readMapUint_writeMapUint_other_slot _ hRootDyn,
      readMapUint_writeMapUint_other_slot _ hAllocDyn,
      readMapUint_writeMapUint_other_key _ _ hne',
      ContractState.readMapUint_writeMapUint_same]
  have hDynSecond : (committedState inputs state).readMapUint dynamicDataSlot inputs.second.moduleId
      = inputs.second.dynamicDataCommitment := by
    simp only [committedState, afterPush, afterBatch, readMapUint_afterCall, readMapUint_afterPull,
      readMapUint_writeMapUint_other_slot _ hRootDyn,
      ContractState.readMapUint_writeMapUint_same]
  have hRootFirst : (committedState inputs state).readMapUint depositRootSlot inputs.first.moduleId
      = inputs.first.depositDataRoot := by
    simp only [committedState, afterPush, afterBatch, readMapUint_afterCall, readMapUint_afterPull,
      readMapUint_writeMapUint_other_slot _ hDynRoot,
      readMapUint_writeMapUint_other_slot _ hAllocRoot,
      readMapUint_writeMapUint_other_key _ _ hne',
      ContractState.readMapUint_writeMapUint_same]
  have hRootSecond : (committedState inputs state).readMapUint depositRootSlot inputs.second.moduleId
      = inputs.second.depositDataRoot := by
    simp only [committedState, afterPush, afterBatch, readMapUint_afterCall, readMapUint_afterPull,
      ContractState.readMapUint_writeMapUint_same]
  have hfresh : (committedState inputs state).calls.drop state.calls.length
      = expectedCalls inputs := by
    rw [hcalls]; exact List.drop_left
  have hfundedVal : inputs.first.amount.val + inputs.second.amount.val
      ≤ (state.readSlot lidoDepositableSlot).val := by
    rw [← total_val inputs h.noWrap]; exact h.funded
  refine Observables.ext ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ <;>
    simp [observe, viewOf, probes, cellsOf, sourceObservables, hbal, hfresh, hlidoAfter, hcount,
      hAllocFirst, hAllocSecond, hDynFirst, hDynSecond, hRootFirst, hRootSecond,
      expectedCalls, moduleEntry, pullEntry, pushEntry, linkedCallEntryTo, linkedCallEntry,
      callValueOf, _root_.Verity.Core.Uint256.sub_eq_of_le h.funded,
      total_val inputs h.noWrap]
  omega

/-- All reverting runs restore the complete Verity snapshot, including writes
performed before dynamic-data, root, Lido, or beacon failures. -/
theorem revert_after_intermediate_writes_restores_snapshot
    (inputs : Inputs) (state rollback : ContractState) (reason : String)
    (h : (execute inputs).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  cases hx : execute inputs state <;> simp [hx] at h
  exact h.2.symm

/-- A reverting run is observationally idle: no ether moved, no call survived,
and every probed mapping word still reads its entry value. -/
theorem revert_observes_idle (inputs : Inputs) (state rollback : ContractState) (reason : String)
    (h : (execute inputs).run state = .revert reason rollback) :
    observe state (probes inputs) ((execute inputs).run state)
      = idleObservables state (probes inputs) := by
  have hroll : rollback = state :=
    revert_after_intermediate_writes_restores_snapshot inputs state rollback reason h
  rw [h, hroll]
  simp [observe, viewOf, idleObservables, callValueOf]

/-! ## Canonical instance

A concrete `Inputs`/entry state pair satisfying `Preconditions`, so the general
theorems above are not vacuous. -/

def batchA : Batch :=
  { moduleId := 7, keys := 2, amount := 64, dynamicDataCommitment := 0xa1
    depositDataRoot := 0xd1, dataValid := true, rootValid := true
    moduleCallOk := true, beaconCallOk := true }

def batchB : Batch :=
  { moduleId := 9, keys := 3, amount := 96, dynamicDataCommitment := 0xa2
    depositDataRoot := 0xd2, dataValid := true, rootValid := true
    moduleCallOk := true, beaconCallOk := true }

def canonicalInputs : Inputs :=
  { authorized := true, moduleActive := true, allocationValid := true,
    lidoCallOk := true, depositSize := 32, lido := 101, module := 202, beacon := 303,
    first := batchA, second := batchB }

def canonicalState : ContractState :=
  (defaultState.writeSlot lidoDepositableSlot 1000).writeSlot counterSlot 41

theorem canonical_preconditions : Preconditions canonicalInputs canonicalState where
  authorized := rfl
  moduleActive := rfl
  allocationValid := rfl
  lidoCallOk := rfl
  firstModuleCallOk := rfl
  firstDataValid := rfl
  firstRootValid := rfl
  firstBeaconCallOk := rfl
  secondModuleCallOk := rfl
  secondDataValid := rfl
  secondRootValid := rfl
  secondBeaconCallOk := rfl
  distinctModules := by decide
  valueMatches := by decide
  entryBalance := by decide
  funded := by decide
  noWrap := by
    show (64 : Nat) + 96 < _root_.Verity.Core.Uint256.modulus
    simp [_root_.Verity.Core.Uint256.modulus, _root_.Verity.Core.UINT256_MODULUS]

/-- The general correspondence, instantiated: the canonical two-batch deposit
really runs and really matches. -/
theorem canonical_observes_source :
    observe canonicalState (probes canonicalInputs)
        ((execute canonicalInputs).run canonicalState)
      = sourceObservables canonicalInputs canonicalState :=
  execute_observes_source canonicalInputs canonicalState canonical_preconditions

/-- The second module's deposit-data-root guard fails after both legs have
already written allocation and dynamic-data words and journalled a call frame;
the transaction boundary still restores the entry world. -/
def badSecondRootInputs : Inputs :=
  { canonicalInputs with second := { batchB with rootValid := false } }

theorem second_batch_root_failure_rolls_back_first_batch :
    observe canonicalState (probes canonicalInputs)
        ((execute badSecondRootInputs).run canonicalState)
      = idleObservables canonicalState (probes canonicalInputs) := by
  decide

end LidoSRv3.Audit.Verity.DepositParentTx
