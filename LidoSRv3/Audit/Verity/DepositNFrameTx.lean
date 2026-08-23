import LidoSRv3.Audit.Verity.DepositParentTx

/-!
# P-DEPOSIT-1 n-frame executable transaction

`Inputs.batches : List Batch` replaces the two-batch `first` / `second`
record.  `execute` is the inductive journal

  `processAll batches` then one `pullFromLido` of the folded total then
  `pushAll batches`

i.e. `batches.mapM (processBatch inputs)` / one pull / `batches.mapM
(pushBatch inputs)`.  The observed journal is

  `batches.map (moduleEntry inputs) ++ [pullEntry inputs] ++
   batches.map (pushEntry inputs)`.

Fold-stable no-wrap: the folded beacon wei equals
`batches.foldl (· + ·.amount) 0` and stays `< 2^256` under the no-wrap
premise.  A wrapping fold does not commit a value-moving journal
(`wrapping_fold_does_not_commit_value_moving`).

Arity-n: exactly `batches.length` module probes and exactly
`batches.length` `depositToBeacon` legs.  The n=2 specialization
(`ofTwoBatch`, `two_batch_journal_is_nframe_n2`) recovers today's
two-batch conjunct (d).

This module does not reopen ALLOC, invent a 32-ether pin, or claim
`LinksSource` from allocation parents.
-/

namespace LidoSRv3.Audit.Verity.DepositNFrameTx

open _root_.Verity
open _root_.Contracts
open LidoSRv3.Audit.Verity.DepositParentTx
  (Batch writeMap getState creditRouter callName Observables viewOf observe
    idleObservables cellsOf callValueOf afterCall bindTo_apply zero_le
    counterSlot lidoDepositableSlot allocationSlot dynamicDataSlot
    depositRootSlot)

abbrev Word := _root_.Verity.Core.Uint256
abbrev TwoInputs := LidoSRv3.Audit.Verity.DepositParentTx.Inputs
abbrev TwoPreconditions := LidoSRv3.Audit.Verity.DepositParentTx.Preconditions

/-! ## Inputs: a finite list of batches -/

structure Inputs where
  authorized : Bool
  moduleActive : Bool
  allocationValid : Bool
  lidoCallOk : Bool
  depositSize : Word
  lido : Address
  module : Address
  beacon : Address
  batches : List Batch
  deriving Repr, DecidableEq

/-- Recursive stand-in for `batches.foldl (· + ·.amount) 0`.  The
`foldedAmount_eq_foldl` theorem records the identification. -/
def foldedAmount : List Batch → Word
  | [] => 0
  | b :: rest => b.amount + foldedAmount rest

def foldedKeys : List Batch → Word
  | [] => 0
  | b :: rest => b.keys + foldedKeys rest

def foldedAmountNat : List Batch → Nat
  | [] => 0
  | b :: rest => b.amount.val + foldedAmountNat rest

def foldedKeysNat : List Batch → Nat
  | [] => 0
  | b :: rest => b.keys.val + foldedKeysNat rest

def totalAmount (inputs : Inputs) : Word := foldedAmount inputs.batches

def totalKeys (inputs : Inputs) : Word := foldedKeys inputs.batches

def batchHealthy (b : Batch) : Bool :=
  b.moduleCallOk && b.dataValid && b.rootValid && b.beaconCallOk

def allHealthy (batches : List Batch) : Bool :=
  batches.all batchHealthy

def modulesDistinct : List Batch → Bool
  | [] => true
  | b :: rest =>
      rest.all (fun b' => !decide (b'.moduleId = b.moduleId)) && modulesDistinct rest

/-! ## The transaction -/

def processBatch (inputs : Inputs) (batch : Batch) : Contract Unit := do
  writeMap allocationSlot batch.moduleId batch.keys
  externalCallBindTo inputs.module 0 [] (callName batch.moduleCallOk "obtainDepositData")
    [batch.moduleId, batch.keys]
  writeMap dynamicDataSlot batch.moduleId batch.dynamicDataCommitment
  require batch.dataValid "INVALID_DYNAMIC_DEPOSIT_DATA"
  writeMap depositRootSlot batch.moduleId batch.depositDataRoot
  require batch.rootValid "INVALID_DEPOSIT_DATA_ROOT"

def processAll (inputs : Inputs) : List Batch → Contract Unit
  | [] => Verity.pure ()
  | b :: rest => do
      processBatch inputs b
      processAll inputs rest

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

def pushAll (inputs : Inputs) : List Batch → Contract Unit
  | [] => Verity.pure ()
  | b :: rest => do
      pushBatch inputs b
      pushAll inputs rest

/-- Inductive n-frame deposit. -/
def execute (inputs : Inputs) : Contract Unit := do
  require inputs.authorized "NOT_AUTHORIZED"
  require inputs.moduleActive "MODULE_NOT_ACTIVE"
  require inputs.allocationValid "INVALID_ALLOCATION"
  let state ← getState
  setStorage ⟨counterSlot⟩ (state.readSlot counterSlot + 1)
  processAll inputs inputs.batches
  let total := foldedAmount inputs.batches
  require (total == foldedKeys inputs.batches * inputs.depositSize)
    "ALLOCATION_VALUE_MISMATCH"
  pullFromLido inputs total
  pushAll inputs inputs.batches
  let after ← getState
  require (after.selfBalance == state.selfBalance) "ASSERT_BALANCE_UNCHANGED"

/-- Fixed-arity-2 mutant: drop the tail after the first two batches. -/
def executeTwoOnly (inputs : Inputs) : Contract Unit :=
  execute { inputs with batches := inputs.batches.take 2 }

/-! ## Journal schedule -/

def moduleEntry (inputs : Inputs) (batch : Batch) : ExternalCall :=
  linkedCallEntryTo "obtainDepositData" inputs.module 0 [batch.moduleId, batch.keys]

def pullEntry (inputs : Inputs) : ExternalCall :=
  linkedCallEntryTo "withdrawDepositableEther" inputs.lido 0 [totalAmount inputs]

def pushEntry (inputs : Inputs) (batch : Batch) : ExternalCall :=
  linkedCallEntryTo "depositToBeacon" inputs.beacon batch.amount
    [batch.moduleId, batch.keys, batch.dynamicDataCommitment, batch.depositDataRoot]

def expectedCalls (inputs : Inputs) : List ExternalCall :=
  inputs.batches.map (moduleEntry inputs) ++
    [pullEntry inputs] ++
    inputs.batches.map (pushEntry inputs)

def probes (inputs : Inputs) : List Word :=
  inputs.batches.map (·.moduleId)

def sourceObservables (inputs : Inputs) (before : ContractState) : Observables :=
  { committed := true
    guardCounter := (before.readSlot counterSlot + 1).val
    allocationCells := inputs.batches.map (·.keys.val)
    dynamicDataCells := inputs.batches.map (·.dynamicDataCommitment.val)
    depositRootCells := inputs.batches.map (·.depositDataRoot.val)
    lidoDepositableAfter :=
      (before.readSlot lidoDepositableSlot).val - (totalAmount inputs).val
    pulled := (totalAmount inputs).val
    pushed := foldedAmountNat inputs.batches
    routerRetained := 0
    callNames := (expectedCalls inputs).map (·.name)
    callTargets := (expectedCalls inputs).map (·.target)
    callValues := (expectedCalls inputs).map (·.value)
    callArgs := (expectedCalls inputs).map (·.calldata) }

/-! ## Preconditions -/

structure Preconditions (inputs : Inputs) (state : ContractState) : Prop where
  authorized : inputs.authorized = true
  moduleActive : inputs.moduleActive = true
  allocationValid : inputs.allocationValid = true
  lidoCallOk : inputs.lidoCallOk = true
  healthy : allHealthy inputs.batches = true
  distinctModules : modulesDistinct inputs.batches = true
  valueMatches : totalAmount inputs = totalKeys inputs * inputs.depositSize
  entryBalance : state.selfBalance = 0
  funded : totalAmount inputs ≤ state.readSlot lidoDepositableSlot
  noWrap : foldedAmountNat inputs.batches < _root_.Verity.Core.Uint256.modulus

/-! ## State combinators -/

def afterBatch (inputs : Inputs) (batch : Batch) (s : ContractState) : ContractState :=
  ((afterCall 0 (moduleEntry inputs batch)
      (s.writeMapUint allocationSlot batch.moduleId batch.keys)).writeMapUint
      dynamicDataSlot batch.moduleId batch.dynamicDataCommitment).writeMapUint
      depositRootSlot batch.moduleId batch.depositDataRoot

def afterBatches (inputs : Inputs) : List Batch → ContractState → ContractState
  | [], s => s
  | b :: rest, s => afterBatches inputs rest (afterBatch inputs b s)

def afterPull (inputs : Inputs) (s : ContractState) : ContractState :=
  let s1 := afterCall 0 (pullEntry inputs) s
  let s2 := s1.writeSlot lidoDepositableSlot
    (s1.readSlot lidoDepositableSlot - totalAmount inputs)
  { s2 with selfBalance := s2.selfBalance + totalAmount inputs }

def afterPush (inputs : Inputs) (batch : Batch) (s : ContractState) : ContractState :=
  afterCall batch.amount (pushEntry inputs batch) s

def afterPushes (inputs : Inputs) : List Batch → ContractState → ContractState
  | [], s => s
  | b :: rest, s => afterPushes inputs rest (afterPush inputs b s)

def committedState (inputs : Inputs) (s : ContractState) : ContractState :=
  afterPushes inputs inputs.batches
    (afterPull inputs
      (afterBatches inputs inputs.batches
        (s.writeSlot counterSlot (s.readSlot counterSlot + 1))))

/-! ## Fold laws -/

theorem foldl_word_add (f : Batch → Word) (xs : List Batch) (acc : Word) :
    xs.foldl (fun a x => a + f x) acc = acc + xs.foldl (fun a x => a + f x) 0 := by
  induction xs generalizing acc with
  | nil =>
    simp [_root_.Verity.Core.Uint256.add_zero]
  | cons hd rest ih =>
    change rest.foldl (fun a x => a + f x) (acc + f hd)
      = acc + rest.foldl (fun a x => a + f x) (0 + f hd)
    rw [ih (acc + f hd), ih (0 + f hd), _root_.Verity.Core.Uint256.zero_add,
      _root_.Verity.Core.Uint256.add_assoc]

theorem foldedAmount_eq_foldl (batches : List Batch) :
    foldedAmount batches = batches.foldl (fun acc b => acc + b.amount) 0 := by
  induction batches with
  | nil => rfl
  | cons b rest ih =>
    change b.amount + foldedAmount rest
      = rest.foldl (fun acc x => acc + x.amount) (0 + b.amount)
    rw [ih, _root_.Verity.Core.Uint256.zero_add, foldl_word_add (·.amount) rest b.amount]

theorem foldedAmount_cons (b : Batch) (rest : List Batch) :
    foldedAmount (b :: rest) = b.amount + foldedAmount rest := rfl

theorem foldedKeys_cons (b : Batch) (rest : List Batch) :
    foldedKeys (b :: rest) = b.keys + foldedKeys rest := rfl

theorem foldedAmountNat_cons (b : Batch) (rest : List Batch) :
    foldedAmountNat (b :: rest) = b.amount.val + foldedAmountNat rest := rfl

theorem foldedKeysNat_cons (b : Batch) (rest : List Batch) :
    foldedKeysNat (b :: rest) = b.keys.val + foldedKeysNat rest := rfl

theorem foldedAmountNat_lt_of_cons {b : Batch} {rest : List Batch}
    (h : foldedAmountNat (b :: rest) < _root_.Verity.Core.Uint256.modulus) :
    foldedAmountNat rest < _root_.Verity.Core.Uint256.modulus := by
  rw [foldedAmountNat_cons] at h
  omega

theorem foldedAmount_val (batches : List Batch)
    (h : foldedAmountNat batches < _root_.Verity.Core.Uint256.modulus) :
    (foldedAmount batches).val = foldedAmountNat batches := by
  induction batches with
  | nil => simp [foldedAmount, foldedAmountNat]
  | cons b rest ih =>
    have hRest := foldedAmountNat_lt_of_cons h
    have hSum : b.amount.val + (foldedAmount rest).val
        < _root_.Verity.Core.Uint256.modulus := by
      rw [ih hRest, ← foldedAmountNat_cons]; exact h
    rw [foldedAmount_cons, foldedAmountNat_cons,
      _root_.Verity.Core.Uint256.add_eq_of_lt hSum, ih hRest]

theorem batch_le_folded (b : Batch) (rest : List Batch)
    (h : foldedAmountNat (b :: rest) < _root_.Verity.Core.Uint256.modulus) :
    b.amount ≤ foldedAmount (b :: rest) := by
  show b.amount.val ≤ (foldedAmount (b :: rest)).val
  rw [foldedAmount_val _ h, foldedAmountNat_cons]
  omega

theorem sub_sub_eq (a b c : Word)
    (hbc : b.val + c.val < _root_.Verity.Core.Uint256.modulus)
    (h : b.val + c.val ≤ a.val) :
    a - b - c = a - (b + c) := by
  have hb : b.val ≤ a.val := by omega
  have hc : c.val ≤ (a - b).val := by
    rw [_root_.Verity.Core.Uint256.sub_eq_of_le (show b ≤ a from hb)]
    omega
  apply _root_.Verity.Core.Uint256.ext
  rw [_root_.Verity.Core.Uint256.sub_eq_of_le (show c ≤ a - b from hc),
    _root_.Verity.Core.Uint256.sub_eq_of_le (show b ≤ a from hb),
    _root_.Verity.Core.Uint256.sub_eq_of_le
      (show b + c ≤ a from by
        change (b + c).val ≤ a.val
        rw [_root_.Verity.Core.Uint256.add_eq_of_lt hbc]; exact h),
    _root_.Verity.Core.Uint256.add_eq_of_lt hbc]
  omega

theorem rest_le_folded_sub (b : Batch) (rest : List Batch) (s : Word)
    (hNoWrap : foldedAmountNat (b :: rest) < _root_.Verity.Core.Uint256.modulus)
    (hBal : foldedAmount (b :: rest) ≤ s) :
    foldedAmount rest ≤ s - b.amount := by
  have hB : b.amount ≤ foldedAmount (b :: rest) := batch_le_folded b rest hNoWrap
  have hB' : b.amount ≤ s := by
    show b.amount.val ≤ s.val
    exact Nat.le_trans hB hBal
  show (foldedAmount rest).val ≤ (s - b.amount).val
  have hRestLt := foldedAmountNat_lt_of_cons hNoWrap
  rw [foldedAmount_val _ hRestLt, _root_.Verity.Core.Uint256.sub_eq_of_le hB']
  have hAll : (foldedAmount (b :: rest)).val ≤ s.val := hBal
  rw [foldedAmount_val _ hNoWrap, foldedAmountNat_cons] at hAll
  omega

/-! ## Healthy / distinct helpers -/

theorem allHealthy_cons {b : Batch} {rest : List Batch}
    (h : allHealthy (b :: rest) = true) :
    batchHealthy b = true ∧ allHealthy rest = true := by
  simp [allHealthy, List.all_cons, Bool.and_eq_true, List.all_eq_true] at h ⊢
  exact h

theorem batchHealthy_module {b : Batch} (h : batchHealthy b = true) :
    b.moduleCallOk = true := by
  simp [batchHealthy, Bool.and_eq_true] at h
  exact h.1.1.1

theorem batchHealthy_data {b : Batch} (h : batchHealthy b = true) :
    b.dataValid = true := by
  simp [batchHealthy, Bool.and_eq_true] at h
  exact h.1.1.2

theorem batchHealthy_root {b : Batch} (h : batchHealthy b = true) :
    b.rootValid = true := by
  simp [batchHealthy, Bool.and_eq_true] at h
  exact h.1.2

theorem batchHealthy_beacon {b : Batch} (h : batchHealthy b = true) :
    b.beaconCallOk = true := by
  simp [batchHealthy, Bool.and_eq_true] at h
  exact h.2

theorem modulesDistinct_cons {b : Batch} {rest : List Batch}
    (h : modulesDistinct (b :: rest) = true) :
    (∀ b' ∈ rest, b'.moduleId ≠ b.moduleId) ∧ modulesDistinct rest = true := by
  simp [modulesDistinct, Bool.and_eq_true, List.all_eq_true] at h ⊢
  exact h

/-! ## Stage reductions -/

theorem processBatch_apply (inputs : Inputs) (batch : Batch) (s : ContractState)
    (hCall : batch.moduleCallOk = true) (hData : batch.dataValid = true)
    (hRoot : batch.rootValid = true) :
    processBatch inputs batch s = .success () (afterBatch inputs batch s) := by
  have hFrame := bindTo_apply inputs.module 0 "obtainDepositData" [batch.moduleId, batch.keys]
    (s.writeMapUint allocationSlot batch.moduleId batch.keys) (by decide) (zero_le _)
  simp only [processBatch, Bind.bind, _root_.Verity.bind, writeMap, callName, hCall, hData,
    hRoot, if_true, hFrame, _root_.Verity.require, afterBatch, moduleEntry]

theorem processAll_apply (inputs : Inputs) (batches : List Batch) (s : ContractState)
    (h : allHealthy batches = true) :
    processAll inputs batches s = .success () (afterBatches inputs batches s) := by
  induction batches generalizing s with
  | nil =>
    simp [processAll, afterBatches, Verity.pure]
  | cons b rest ih =>
    obtain ⟨hB, hRest⟩ := allHealthy_cons h
    have hStep := processBatch_apply inputs b s
      (batchHealthy_module hB) (batchHealthy_data hB) (batchHealthy_root hB)
    simp only [processAll, Bind.bind, _root_.Verity.bind, hStep, afterBatches]
    exact ih _ hRest

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

theorem selfBalance_afterBatch (inputs : Inputs) (batch : Batch) (s : ContractState) :
    (afterBatch inputs batch s).selfBalance = s.selfBalance := by
  show s.selfBalance - 0 = s.selfBalance
  exact _root_.Verity.Core.Uint256.sub_zero _

theorem selfBalance_afterBatches (inputs : Inputs) (batches : List Batch)
    (s : ContractState) :
    (afterBatches inputs batches s).selfBalance = s.selfBalance := by
  induction batches generalizing s with
  | nil => simp [afterBatches]
  | cons b rest ih =>
    simp only [afterBatches]
    rw [ih, selfBalance_afterBatch]

theorem readSlot_afterBatch (inputs : Inputs) (batch : Batch) (s : ContractState)
    (slotId : Nat) : (afterBatch inputs batch s).readSlot slotId = s.readSlot slotId :=
  rfl

theorem readSlot_afterBatches (inputs : Inputs) (batches : List Batch)
    (s : ContractState) (slotId : Nat) :
    (afterBatches inputs batches s).readSlot slotId = s.readSlot slotId := by
  induction batches generalizing s with
  | nil => simp [afterBatches]
  | cons b rest ih =>
    simp only [afterBatches]
    rw [ih, readSlot_afterBatch]

theorem calls_afterBatch (inputs : Inputs) (batch : Batch) (s : ContractState) :
    (afterBatch inputs batch s).calls = s.calls ++ [moduleEntry inputs batch] :=
  rfl

theorem calls_afterBatches (inputs : Inputs) (batches : List Batch)
    (s : ContractState) :
    (afterBatches inputs batches s).calls
      = s.calls ++ batches.map (moduleEntry inputs) := by
  induction batches generalizing s with
  | nil => simp [afterBatches]
  | cons b rest ih =>
    simp only [afterBatches, List.map_cons]
    rw [ih, calls_afterBatch, List.append_assoc, List.cons_append, List.nil_append]

theorem selfBalance_afterPull (inputs : Inputs) (s : ContractState) :
    (afterPull inputs s).selfBalance = s.selfBalance + totalAmount inputs := by
  show s.selfBalance - 0 + totalAmount inputs = _
  rw [_root_.Verity.Core.Uint256.sub_zero]

theorem selfBalance_afterPush (inputs : Inputs) (batch : Batch) (s : ContractState) :
    (afterPush inputs batch s).selfBalance = s.selfBalance - batch.amount := rfl

theorem selfBalance_afterPushes (inputs : Inputs) (batches : List Batch)
    (s : ContractState)
    (hNoWrap : foldedAmountNat batches < _root_.Verity.Core.Uint256.modulus)
    (hBal : foldedAmount batches ≤ s.selfBalance) :
    (afterPushes inputs batches s).selfBalance
      = s.selfBalance - foldedAmount batches := by
  induction batches generalizing s with
  | nil =>
    simp [afterPushes, foldedAmount, _root_.Verity.Core.Uint256.sub_zero]
  | cons b rest ih =>
    have hRestLt := foldedAmountNat_lt_of_cons hNoWrap
    have hB : b.amount ≤ s.selfBalance := by
      show b.amount.val ≤ s.selfBalance.val
      exact Nat.le_trans (batch_le_folded b rest hNoWrap) hBal
    have hRestBal : foldedAmount rest ≤ s.selfBalance - b.amount :=
      rest_le_folded_sub b rest s.selfBalance hNoWrap hBal
    simp only [afterPushes]
    have ih' := ih (afterPush inputs b s) hRestLt (by
      simpa [afterPush, selfBalance_afterPush] using hRestBal)
    rw [ih', selfBalance_afterPush, foldedAmount_cons]
    refine sub_sub_eq s.selfBalance b.amount (foldedAmount rest) ?_ ?_
    · have hAll := foldedAmount_val (b :: rest) hNoWrap
      have hR := foldedAmount_val rest hRestLt
      rw [hR]
      have : b.amount.val + foldedAmountNat rest
          < _root_.Verity.Core.Uint256.modulus := by
        rw [← foldedAmountNat_cons]; exact hNoWrap
      exact this
    · have hAll := foldedAmount_val (b :: rest) hNoWrap
      have hR := foldedAmount_val rest hRestLt
      have : (foldedAmount (b :: rest)).val ≤ s.selfBalance.val := hBal
      rw [hAll, foldedAmountNat_cons] at this
      rwa [hR]

theorem calls_afterPull (inputs : Inputs) (s : ContractState) :
    (afterPull inputs s).calls = s.calls ++ [pullEntry inputs] := rfl

theorem calls_afterPush (inputs : Inputs) (batch : Batch) (s : ContractState) :
    (afterPush inputs batch s).calls = s.calls ++ [pushEntry inputs batch] := rfl

theorem calls_afterPushes (inputs : Inputs) (batches : List Batch)
    (s : ContractState) :
    (afterPushes inputs batches s).calls
      = s.calls ++ batches.map (pushEntry inputs) := by
  induction batches generalizing s with
  | nil => simp [afterPushes]
  | cons b rest ih =>
    simp only [afterPushes, List.map_cons]
    rw [ih, calls_afterPush, List.append_assoc, List.cons_append, List.nil_append]

theorem readSlot_afterPush (inputs : Inputs) (batch : Batch) (s : ContractState)
    (slotId : Nat) : (afterPush inputs batch s).readSlot slotId = s.readSlot slotId :=
  rfl

theorem readSlot_afterPushes (inputs : Inputs) (batches : List Batch)
    (s : ContractState) (slotId : Nat) :
    (afterPushes inputs batches s).readSlot slotId = s.readSlot slotId := by
  induction batches generalizing s with
  | nil => simp [afterPushes]
  | cons b rest ih =>
    simp only [afterPushes]
    rw [ih, readSlot_afterPush]

theorem readSlot_afterPull (inputs : Inputs) (s : ContractState) (slotId : Nat) :
    (afterPull inputs s).readSlot slotId
      = (s.writeSlot lidoDepositableSlot
          (s.readSlot lidoDepositableSlot - totalAmount inputs)).readSlot slotId :=
  rfl

theorem readMapUint_afterPush (inputs : Inputs) (batch : Batch) (s : ContractState)
    (mapSlot : Nat) (key : Word) :
    (afterPush inputs batch s).readMapUint mapSlot key = s.readMapUint mapSlot key :=
  rfl

theorem readMapUint_afterPushes (inputs : Inputs) (batches : List Batch)
    (s : ContractState) (mapSlot : Nat) (key : Word) :
    (afterPushes inputs batches s).readMapUint mapSlot key
      = s.readMapUint mapSlot key := by
  induction batches generalizing s with
  | nil => simp [afterPushes]
  | cons b rest ih =>
    simp only [afterPushes]
    rw [ih, readMapUint_afterPush]

theorem readMapUint_afterPull (inputs : Inputs) (s : ContractState)
    (mapSlot : Nat) (key : Word) :
    (afterPull inputs s).readMapUint mapSlot key = s.readMapUint mapSlot key :=
  rfl

theorem readMapUint_afterBatch_other_key (inputs : Inputs) (batch : Batch)
    (s : ContractState) (mapSlot : Nat) {key : Word}
    (hne : key ≠ batch.moduleId) :
    (afterBatch inputs batch s).readMapUint mapSlot key
      = s.readMapUint mapSlot key := by
  simp [afterBatch, afterCall, ContractState.readMapUint, ContractState.storageMapUint,
    ContractState.writeMapUint, hne]

theorem afterBatches_preserves_other (inputs : Inputs) (batches : List Batch)
    (s : ContractState) (mapSlot : Nat) (key : Word)
    (hFresh : ∀ b ∈ batches, b.moduleId ≠ key) :
    (afterBatches inputs batches s).readMapUint mapSlot key
      = s.readMapUint mapSlot key := by
  induction batches generalizing s with
  | nil => simp [afterBatches]
  | cons b rest ih =>
    have hb : b.moduleId ≠ key := hFresh b (List.mem_cons_self)
    have hRest : ∀ b' ∈ rest, b'.moduleId ≠ key :=
      fun b' hb' => hFresh b' (List.mem_cons_of_mem _ hb')
    simp only [afterBatches]
    rw [ih _ hRest, readMapUint_afterBatch_other_key]
    exact fun hEq => hb hEq.symm

theorem afterBatch_allocation_same (inputs : Inputs) (batch : Batch)
    (s : ContractState) :
    (afterBatch inputs batch s).readMapUint allocationSlot batch.moduleId
      = batch.keys := by
  have hRootAlloc : allocationSlot ≠ depositRootSlot := by decide
  have hDynAlloc : allocationSlot ≠ dynamicDataSlot := by decide
  simp [afterBatch, afterCall, ContractState.readMapUint, ContractState.storageMapUint,
    ContractState.writeMapUint, hRootAlloc, hDynAlloc]

theorem afterBatch_dynamic_same (inputs : Inputs) (batch : Batch)
    (s : ContractState) :
    (afterBatch inputs batch s).readMapUint dynamicDataSlot batch.moduleId
      = batch.dynamicDataCommitment := by
  have hRootDyn : dynamicDataSlot ≠ depositRootSlot := by decide
  simp [afterBatch, afterCall, ContractState.readMapUint, ContractState.storageMapUint,
    ContractState.writeMapUint, hRootDyn]

theorem afterBatch_root_same (inputs : Inputs) (batch : Batch)
    (s : ContractState) :
    (afterBatch inputs batch s).readMapUint depositRootSlot batch.moduleId
      = batch.depositDataRoot := by
  simp [afterBatch, afterCall, ContractState.readMapUint, ContractState.storageMapUint,
    ContractState.writeMapUint]

theorem afterBatches_read (inputs : Inputs) (batches : List Batch)
    (s : ContractState) (hDist : modulesDistinct batches = true)
    (mapSlot : Nat) (proj : Batch → Word)
    (hHead : ∀ (s' : ContractState) (b : Batch),
      (afterBatch inputs b s').readMapUint mapSlot b.moduleId = proj b)
    (b : Batch) (hb : b ∈ batches) :
    (afterBatches inputs batches s).readMapUint mapSlot b.moduleId = proj b := by
  induction batches generalizing s with
  | nil => cases hb
  | cons b' rest ih =>
    obtain ⟨hFresh, hRest⟩ := modulesDistinct_cons hDist
    simp only [afterBatches]
    cases List.mem_cons.mp hb with
    | inl hEq =>
      subst hEq
      rw [afterBatches_preserves_other inputs rest _ mapSlot b.moduleId hFresh,
        hHead]
    | inr hMem =>
      exact ih (afterBatch inputs b' s) hRest hMem

theorem cellsOf_proj (s : ContractState) (mapSlot : Nat) (batches : List Batch)
    (proj : Batch → Word)
    (hRead : ∀ b ∈ batches, s.readMapUint mapSlot b.moduleId = proj b) :
    cellsOf s mapSlot (batches.map (·.moduleId))
      = batches.map (fun b => (proj b).val) := by
  induction batches with
  | nil => simp [cellsOf]
  | cons b rest ih =>
    have hB := hRead b (List.mem_cons_self (l := rest))
    have hRest : ∀ b' ∈ rest, s.readMapUint mapSlot b'.moduleId = proj b' :=
      fun b' hb' => hRead b' (List.mem_cons_of_mem _ hb')
    change
      (s.readMapUint mapSlot b.moduleId).val ::
        cellsOf s mapSlot (rest.map (·.moduleId)) =
      (proj b).val :: rest.map (fun x => (proj x).val)
    rw [hB, ih hRest]

theorem cellsOf_congr (s t : ContractState) (mapSlot : Nat) (keys : List Word)
    (h : ∀ k ∈ keys, s.readMapUint mapSlot k = t.readMapUint mapSlot k) :
    cellsOf s mapSlot keys = cellsOf t mapSlot keys := by
  induction keys with
  | nil => simp [cellsOf]
  | cons k rest ih =>
    have hk := h k (List.mem_cons_self (l := rest))
    have hRest : ∀ k' ∈ rest, s.readMapUint mapSlot k' = t.readMapUint mapSlot k' :=
      fun k' hk' => h k' (List.mem_cons_of_mem _ hk')
    change
      (s.readMapUint mapSlot k).val :: cellsOf s mapSlot rest =
      (t.readMapUint mapSlot k).val :: cellsOf t mapSlot rest
    rw [hk, ih hRest]

theorem pushAll_apply (inputs : Inputs) (batches : List Batch) (s : ContractState)
    (hHealthy : allHealthy batches = true)
    (hNoWrap : foldedAmountNat batches < _root_.Verity.Core.Uint256.modulus)
    (hBal : foldedAmount batches ≤ s.selfBalance) :
    pushAll inputs batches s = .success () (afterPushes inputs batches s) := by
  induction batches generalizing s with
  | nil =>
    simp [pushAll, afterPushes, Verity.pure]
  | cons b rest ih =>
    obtain ⟨hB, hRest⟩ := allHealthy_cons hHealthy
    have hBBal : b.amount ≤ s.selfBalance := by
      show b.amount.val ≤ s.selfBalance.val
      exact Nat.le_trans (batch_le_folded b rest hNoWrap) hBal
    have hStep := pushBatch_apply inputs b s (batchHealthy_beacon hB) hBBal
    have hRestBal := rest_le_folded_sub b rest s.selfBalance hNoWrap hBal
    have hRestLt := foldedAmountNat_lt_of_cons hNoWrap
    simp only [pushAll, Bind.bind, _root_.Verity.bind, hStep]
    have ih' := ih (afterPush inputs b s) hRest hRestLt (by
      simpa [afterPush, selfBalance_afterPush] using hRestBal)
    simpa [afterPushes] using ih'

/-! ## Composed correspondence -/

theorem execute_apply (inputs : Inputs) (state : ContractState)
    (h : Preconditions inputs state) :
    execute inputs state = .success () (committedState inputs state) := by
  set entry := state.writeSlot counterSlot (state.readSlot counterSlot + 1) with hentry
  set sB := afterBatches inputs inputs.batches entry with hsB
  set sP := afterPull inputs sB with hsP
  have hLido : sB.readSlot lidoDepositableSlot = state.readSlot lidoDepositableSlot := by
    have hne : lidoDepositableSlot ≠ counterSlot := by decide
    rw [hsB, readSlot_afterBatches, ContractState.readSlot_writeSlot_other _ hne]
  have hFunded : totalAmount inputs ≤ sB.readSlot lidoDepositableSlot := by
    rw [hLido]; exact h.funded
  have hbalB : sB.selfBalance = 0 := by
    rw [hsB, selfBalance_afterBatches, LidoSRv3.Audit.Verity.DepositParentTx.selfBalance_writeSlot,
      h.entryBalance]
  have hbalP : sP.selfBalance = totalAmount inputs := by
    rw [hsP, selfBalance_afterPull, hbalB, _root_.Verity.Core.Uint256.zero_add]
  have hPushBal : foldedAmount inputs.batches ≤ sP.selfBalance := by
    show (foldedAmount inputs.batches).val ≤ sP.selfBalance.val
    rw [hbalP]
    exact Nat.le_refl _
  have hPushes :=
    pushAll_apply inputs inputs.batches sP h.healthy h.noWrap hPushBal
  have hClose :
      (afterPushes inputs inputs.batches sP).selfBalance = state.selfBalance := by
    rw [selfBalance_afterPushes inputs inputs.batches sP h.noWrap hPushBal, hbalP,
      h.entryBalance]
    simp [totalAmount]
  simp only [execute, Bind.bind, _root_.Verity.bind, _root_.Verity.require, h.authorized,
    h.moduleActive, h.allocationValid, if_true, getState, setStorage, ← hentry,
    processAll_apply inputs inputs.batches entry h.healthy, ← hsB]
  have hguard :
      (foldedAmount inputs.batches == foldedKeys inputs.batches * inputs.depositSize)
        = true := by
    have hEq := h.valueMatches
    simp [totalAmount, totalKeys] at hEq
    simp [hEq]
  rw [hguard]
  simp only [if_true, show foldedAmount inputs.batches = totalAmount inputs from rfl,
    pullFromLido_apply inputs sB h.lidoCallOk hFunded, ← hsP, hPushes]
  rw [hClose]
  simp only [beq_self_eq_true, if_true, committedState, hsP, hsB, hentry]
  try rfl

theorem execute_run (inputs : Inputs) (state : ContractState)
    (h : Preconditions inputs state) :
    (execute inputs).run state = .success () (committedState inputs state) := by
  simp [Contract.run, execute_apply inputs state h]

theorem callValueOf_append (name : String) (xs ys : List ExternalCall) :
    callValueOf name (xs ++ ys) = callValueOf name xs + callValueOf name ys := by
  induction xs with
  | nil => simp [callValueOf]
  | cons c rest ih =>
    simp [callValueOf, ih, Nat.add_assoc]

theorem callValueOf_modules (inputs : Inputs) (batches : List Batch) :
    callValueOf "depositToBeacon" (batches.map (moduleEntry inputs)) = 0 := by
  induction batches with
  | nil => rfl
  | cons b rest ih =>
    change (if "obtainDepositData" == "depositToBeacon" then _ else 0) +
        callValueOf "depositToBeacon" (rest.map (moduleEntry inputs)) = 0
    simp [ih]

theorem callValueOf_pushes (inputs : Inputs) (batches : List Batch) :
    callValueOf "depositToBeacon" (batches.map (pushEntry inputs))
      = foldedAmountNat batches := by
  induction batches with
  | nil => rfl
  | cons b rest ih =>
    change (if "depositToBeacon" == "depositToBeacon" then b.amount.val else 0) +
        callValueOf "depositToBeacon" (rest.map (pushEntry inputs)) =
      b.amount.val + foldedAmountNat rest
    simp [ih]

theorem callValueOf_expected (inputs : Inputs) :
    callValueOf "depositToBeacon" (expectedCalls inputs)
      = foldedAmountNat inputs.batches := by
  simp only [expectedCalls]
  rw [callValueOf_append, callValueOf_append, callValueOf_modules, callValueOf_pushes]
  change 0 + ((if "withdrawDepositableEther" == "depositToBeacon" then _ else 0) + 0) +
      foldedAmountNat inputs.batches =
    foldedAmountNat inputs.batches
  simp

theorem map_moduleEntry_name (inputs : Inputs) (batches : List Batch) :
    batches.map ((fun c => c.name) ∘ moduleEntry inputs)
      = batches.map (fun _ => "obtainDepositData") := by
  induction batches with
  | nil => rfl
  | cons _ rest ih =>
    simp [moduleEntry, linkedCallEntryTo, linkedCallEntry, ih]

theorem map_pushEntry_name (inputs : Inputs) (batches : List Batch) :
    batches.map ((fun c => c.name) ∘ pushEntry inputs)
      = batches.map (fun _ => "depositToBeacon") := by
  induction batches with
  | nil => rfl
  | cons _ rest ih =>
    simp [pushEntry, linkedCallEntryTo, linkedCallEntry, ih]

theorem map_moduleEntry_target (inputs : Inputs) (batches : List Batch) :
    batches.map ((fun c => c.target) ∘ moduleEntry inputs)
      = batches.map (fun _ => inputs.module.toNat) := by
  induction batches with
  | nil => rfl
  | cons _ rest ih =>
    simp [moduleEntry, linkedCallEntryTo, linkedCallEntry, ih]

theorem map_pushEntry_target (inputs : Inputs) (batches : List Batch) :
    batches.map ((fun c => c.target) ∘ pushEntry inputs)
      = batches.map (fun _ => inputs.beacon.toNat) := by
  induction batches with
  | nil => rfl
  | cons _ rest ih =>
    simp [pushEntry, linkedCallEntryTo, linkedCallEntry, ih]

theorem map_moduleEntry_value (inputs : Inputs) (batches : List Batch) :
    batches.map ((fun c => c.value) ∘ moduleEntry inputs)
      = batches.map (fun _ => (0 : Nat)) := by
  induction batches with
  | nil => rfl
  | cons _ rest ih =>
    simp [moduleEntry, linkedCallEntryTo, linkedCallEntry, ih]

theorem map_pushEntry_value (inputs : Inputs) (batches : List Batch) :
    batches.map ((fun c => c.value) ∘ pushEntry inputs)
      = batches.map (·.amount.val) := by
  induction batches with
  | nil => rfl
  | cons _ rest ih =>
    simp [pushEntry, linkedCallEntryTo, linkedCallEntry, ih]

theorem map_moduleEntry_args (inputs : Inputs) (batches : List Batch) :
    batches.map ((fun c => c.calldata) ∘ moduleEntry inputs)
      = batches.map (fun b => [b.moduleId.val, b.keys.val]) := by
  induction batches with
  | nil => rfl
  | cons _ rest ih =>
    simp [moduleEntry, linkedCallEntryTo, linkedCallEntry, ih]

theorem map_pushEntry_args (inputs : Inputs) (batches : List Batch) :
    batches.map ((fun c => c.calldata) ∘ pushEntry inputs)
      = batches.map (fun b =>
          [b.moduleId.val, b.keys.val, b.dynamicDataCommitment.val, b.depositDataRoot.val]) := by
  induction batches with
  | nil => rfl
  | cons _ rest ih =>
    simp [pushEntry, linkedCallEntryTo, linkedCallEntry, ih]

theorem filter_modules_deposit (inputs : Inputs) (batches : List Batch) :
    (batches.map (moduleEntry inputs) |>.filter
      (fun c => decide (c.name = "depositToBeacon"))).length = 0 := by
  induction batches with
  | nil => rfl
  | cons _ rest ih =>
    simp [moduleEntry, linkedCallEntryTo, linkedCallEntry, ih]

theorem filter_pushes_deposit (inputs : Inputs) (batches : List Batch) :
    (batches.map (pushEntry inputs) |>.filter
      (fun c => decide (c.name = "depositToBeacon"))).length = batches.length := by
  induction batches with
  | nil => rfl
  | cons _ rest ih =>
    simp [pushEntry, linkedCallEntryTo, linkedCallEntry, ih]

theorem filter_modules_obtain (inputs : Inputs) (batches : List Batch) :
    (batches.map (moduleEntry inputs) |>.filter
      (fun c => decide (c.name = "obtainDepositData"))).length = batches.length := by
  induction batches with
  | nil => rfl
  | cons _ rest ih =>
    simp [moduleEntry, linkedCallEntryTo, linkedCallEntry, ih]

theorem filter_pushes_obtain (inputs : Inputs) (batches : List Batch) :
    (batches.map (pushEntry inputs) |>.filter
      (fun c => decide (c.name = "obtainDepositData"))).length = 0 := by
  induction batches with
  | nil => rfl
  | cons _ rest ih =>
    simp [pushEntry, linkedCallEntryTo, linkedCallEntry, ih]

theorem depositToBeacon_count (inputs : Inputs) :
    ((expectedCalls inputs).filter (fun c => decide (c.name = "depositToBeacon"))).length
      = inputs.batches.length := by
  simp [expectedCalls, filter_modules_deposit, pullEntry, linkedCallEntryTo,
    linkedCallEntry, filter_pushes_deposit]

theorem obtainDepositData_count (inputs : Inputs) :
    ((expectedCalls inputs).filter (fun c => decide (c.name = "obtainDepositData"))).length
      = inputs.batches.length := by
  simp [expectedCalls, filter_modules_obtain, pullEntry, linkedCallEntryTo,
    linkedCallEntry, filter_pushes_obtain]

theorem probes_length (inputs : Inputs) :
    (probes inputs).length = inputs.batches.length := by
  simp [probes]

theorem committed_readMap (inputs : Inputs) (state : ContractState)
    (mapSlot : Nat) (key : Word) :
    (committedState inputs state).readMapUint mapSlot key
      = (afterBatches inputs inputs.batches
          (state.writeSlot counterSlot (state.readSlot counterSlot + 1))).readMapUint
        mapSlot key := by
  simp [committedState, readMapUint_afterPushes, readMapUint_afterPull]

theorem execute_observes_source (inputs : Inputs) (state : ContractState)
    (h : Preconditions inputs state) :
    observe state (probes inputs) ((execute inputs).run state)
      = sourceObservables inputs state := by
  have hCounter : lidoDepositableSlot ≠ counterSlot := by decide
  have hLidoNe : counterSlot ≠ lidoDepositableSlot := by decide
  rw [execute_run inputs state h]
  have hPushBal : foldedAmount inputs.batches ≤
      (afterPull inputs
        (afterBatches inputs inputs.batches
          (state.writeSlot counterSlot (state.readSlot counterSlot + 1)))).selfBalance := by
    rw [selfBalance_afterPull, selfBalance_afterBatches,
      LidoSRv3.Audit.Verity.DepositParentTx.selfBalance_writeSlot, h.entryBalance,
      _root_.Verity.Core.Uint256.zero_add]
    exact Nat.le_refl _
  have hbal : (committedState inputs state).selfBalance = 0 := by
    rw [committedState, selfBalance_afterPushes _ _ _ h.noWrap hPushBal,
      selfBalance_afterPull, selfBalance_afterBatches,
      LidoSRv3.Audit.Verity.DepositParentTx.selfBalance_writeSlot, h.entryBalance,
      _root_.Verity.Core.Uint256.zero_add]
    simp [totalAmount]
  have hcalls :
      (committedState inputs state).calls = state.calls ++ expectedCalls inputs := by
    simp only [committedState, calls_afterPushes, calls_afterPull, calls_afterBatches,
      LidoSRv3.Audit.Verity.DepositParentTx.calls_writeSlot, expectedCalls,
      List.append_assoc]
  have hlidoAfter :
      (committedState inputs state).readSlot lidoDepositableSlot
        = state.readSlot lidoDepositableSlot - totalAmount inputs := by
    simp only [committedState, readSlot_afterPushes, readSlot_afterPull, readSlot_afterBatches,
      ContractState.readSlot_writeSlot_same,
      ContractState.readSlot_writeSlot_other _ hCounter]
  have hcount :
      (committedState inputs state).readSlot counterSlot
        = state.readSlot counterSlot + 1 := by
    simp only [committedState, readSlot_afterPushes, readSlot_afterPull, readSlot_afterBatches,
      ContractState.readSlot_writeSlot_other _ hLidoNe,
      ContractState.readSlot_writeSlot_same]
  have hfresh :
      (committedState inputs state).calls.drop state.calls.length
        = expectedCalls inputs := by
    rw [hcalls]; exact List.drop_left
  have hMaps (mapSlot : Nat) (key : Word) :
      (committedState inputs state).readMapUint mapSlot key
        = (afterBatches inputs inputs.batches
            (state.writeSlot counterSlot (state.readSlot counterSlot + 1))).readMapUint
          mapSlot key :=
    committed_readMap inputs state mapSlot key
  let entry := state.writeSlot counterSlot (state.readSlot counterSlot + 1)
  have hAllocRead (b : Batch) (hb : b ∈ inputs.batches) :
      (committedState inputs state).readMapUint allocationSlot b.moduleId = b.keys := by
    rw [hMaps]
    exact afterBatches_read inputs inputs.batches entry h.distinctModules
      allocationSlot (·.keys) (fun s' b' => afterBatch_allocation_same inputs b' s') b hb
  have hDynRead (b : Batch) (hb : b ∈ inputs.batches) :
      (committedState inputs state).readMapUint dynamicDataSlot b.moduleId
        = b.dynamicDataCommitment := by
    rw [hMaps]
    exact afterBatches_read inputs inputs.batches entry h.distinctModules
      dynamicDataSlot (·.dynamicDataCommitment)
      (fun s' b' => afterBatch_dynamic_same inputs b' s') b hb
  have hRootRead (b : Batch) (hb : b ∈ inputs.batches) :
      (committedState inputs state).readMapUint depositRootSlot b.moduleId
        = b.depositDataRoot := by
    rw [hMaps]
    exact afterBatches_read inputs inputs.batches entry h.distinctModules
      depositRootSlot (·.depositDataRoot)
      (fun s' b' => afterBatch_root_same inputs b' s') b hb
  have hAllocCells :
      cellsOf (committedState inputs state) allocationSlot (probes inputs)
        = inputs.batches.map (·.keys.val) := by
    simpa [probes] using
      cellsOf_proj (committedState inputs state) allocationSlot inputs.batches (·.keys)
        hAllocRead
  have hDynCells :
      cellsOf (committedState inputs state) dynamicDataSlot (probes inputs)
        = inputs.batches.map (·.dynamicDataCommitment.val) := by
    simpa [probes] using
      cellsOf_proj (committedState inputs state) dynamicDataSlot inputs.batches
        (·.dynamicDataCommitment) hDynRead
  have hRootCells :
      cellsOf (committedState inputs state) depositRootSlot (probes inputs)
        = inputs.batches.map (·.depositDataRoot.val) := by
    simpa [probes] using
      cellsOf_proj (committedState inputs state) depositRootSlot inputs.batches
        (·.depositDataRoot) hRootRead
  refine Observables.ext ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_
  · simp [observe, viewOf, sourceObservables]
  · simp [observe, viewOf, hcount, sourceObservables]
  · simp [observe, viewOf, hAllocCells, sourceObservables]
  · simp [observe, viewOf, hDynCells, sourceObservables]
  · simp [observe, viewOf, hRootCells, sourceObservables]
  · simp [observe, viewOf, hlidoAfter, sourceObservables,
      _root_.Verity.Core.Uint256.sub_eq_of_le h.funded]
  · simp [observe, viewOf, hlidoAfter, sourceObservables,
      _root_.Verity.Core.Uint256.sub_eq_of_le h.funded]
    exact Nat.sub_sub_self h.funded
  · simp [observe, viewOf, hfresh, callValueOf_expected, sourceObservables]
  · simp [observe, viewOf, hbal, sourceObservables]
  · simp [observe, viewOf, hfresh, sourceObservables]
  · simp [observe, viewOf, hfresh, sourceObservables]
  · simp [observe, viewOf, hfresh, sourceObservables]
  · simp [observe, viewOf, hfresh, sourceObservables]

theorem revert_after_intermediate_writes_restores_snapshot
    (inputs : Inputs) (state rollback : ContractState) (reason : String)
    (h : (execute inputs).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  cases hx : execute inputs state <;> simp [hx] at h
  exact h.2.symm

theorem revert_observes_idle (inputs : Inputs) (state rollback : ContractState)
    (reason : String)
    (h : (execute inputs).run state = .revert reason rollback) :
    observe state (probes inputs) ((execute inputs).run state)
      = idleObservables state (probes inputs) := by
  have hroll : rollback = state :=
    revert_after_intermediate_writes_restores_snapshot inputs state rollback reason h
  rw [h, hroll]
  simp [observe, viewOf, idleObservables, callValueOf]

/-! ## n=2 specialization -/

def ofTwoBatch (inputs : TwoInputs) : Inputs :=
  { authorized := inputs.authorized
    moduleActive := inputs.moduleActive
    allocationValid := inputs.allocationValid
    lidoCallOk := inputs.lidoCallOk
    depositSize := inputs.depositSize
    lido := inputs.lido
    module := inputs.module
    beacon := inputs.beacon
    batches := [inputs.first, inputs.second] }

theorem ofTwoBatch_length (inputs : TwoInputs) :
    (ofTwoBatch inputs).batches.length = 2 := rfl

theorem foldedAmount_two (a b : Batch) :
    foldedAmount [a, b] = a.amount + b.amount := by
  simp [foldedAmount]

theorem foldedKeys_two (a b : Batch) :
    foldedKeys [a, b] = a.keys + b.keys := by
  simp [foldedKeys]

theorem ofTwoBatch_preconditions (inputs : TwoInputs) (state : ContractState)
    (h : TwoPreconditions inputs state) :
    Preconditions (ofTwoBatch inputs) state where
  authorized := h.authorized
  moduleActive := h.moduleActive
  allocationValid := h.allocationValid
  lidoCallOk := h.lidoCallOk
  healthy := by
    simp [ofTwoBatch, allHealthy, batchHealthy, h.firstModuleCallOk, h.firstDataValid,
      h.firstRootValid, h.firstBeaconCallOk, h.secondModuleCallOk, h.secondDataValid,
      h.secondRootValid, h.secondBeaconCallOk]
  distinctModules := by
    simp [ofTwoBatch, modulesDistinct, h.distinctModules]
  valueMatches := by
    change foldedAmount [inputs.first, inputs.second]
      = foldedKeys [inputs.first, inputs.second] * inputs.depositSize
    rw [foldedAmount_two, foldedKeys_two]
    simpa [LidoSRv3.Audit.Verity.DepositParentTx.totalAmount,
      LidoSRv3.Audit.Verity.DepositParentTx.totalKeys] using h.valueMatches
  entryBalance := h.entryBalance
  funded := by
    change foldedAmount [inputs.first, inputs.second] ≤ state.readSlot lidoDepositableSlot
    rw [foldedAmount_two]
    simpa [LidoSRv3.Audit.Verity.DepositParentTx.totalAmount] using h.funded
  noWrap := by
    simpa [ofTwoBatch, foldedAmountNat] using h.noWrap

theorem length_eq_two {α : Type _} {xs : List α} (h : xs.length = 2) :
    ∃ a b, xs = [a, b] := by
  cases xs with
  | nil => cases h
  | cons a xs' =>
    cases xs' with
    | nil => cases h
    | cons b xs'' =>
      cases xs'' with
      | nil => exact ⟨a, b, rfl⟩
      | cons _ _ =>
        cases h

/-- Any 2-element batch list recovers today's conjunct (d) journal. -/
theorem length_two_callNames (inputs : Inputs) (entry : ContractState)
    (h : inputs.batches.length = 2) :
    (sourceObservables inputs entry).callNames
      = ["obtainDepositData", "obtainDepositData", "withdrawDepositableEther",
         "depositToBeacon", "depositToBeacon"] ∧
      (probes inputs).length = 2 := by
  obtain ⟨a, b, heq⟩ := length_eq_two h
  simp [sourceObservables, expectedCalls, moduleEntry, pullEntry, pushEntry,
    linkedCallEntryTo, linkedCallEntry, probes, heq]

/-- Today's two-batch conjunct (d) journal is the n=2 case of the n-frame
journal. -/
theorem two_batch_journal_is_nframe_n2 (inputs : TwoInputs) (entry : ContractState) :
    (sourceObservables (ofTwoBatch inputs) entry).callNames
      = ["obtainDepositData", "obtainDepositData", "withdrawDepositableEther",
         "depositToBeacon", "depositToBeacon"] ∧
      (probes (ofTwoBatch inputs)).length = 2 ∧
      (LidoSRv3.Audit.Verity.DepositParentTx.sourceObservables inputs entry).callNames
        = (sourceObservables (ofTwoBatch inputs) entry).callNames ∧
      (LidoSRv3.Audit.Verity.DepositParentTx.probes inputs).length
        = (probes (ofTwoBatch inputs)).length := by
  refine ⟨?names, rfl, ?eq, rfl⟩
  · simp [sourceObservables, ofTwoBatch, expectedCalls, moduleEntry, pullEntry, pushEntry,
      linkedCallEntryTo, linkedCallEntry]
  · simp [sourceObservables, ofTwoBatch, expectedCalls, moduleEntry, pullEntry, pushEntry,
      linkedCallEntryTo, linkedCallEntry,
      LidoSRv3.Audit.Verity.DepositParentTx.sourceObservables]

/-! ## Canonical n-frame witness (arity 3) -/

def batchA : Batch :=
  { moduleId := 7, keys := 2, amount := 64, dynamicDataCommitment := 0xa1
    depositDataRoot := 0xd1, dataValid := true, rootValid := true
    moduleCallOk := true, beaconCallOk := true }

def batchB : Batch :=
  { moduleId := 9, keys := 3, amount := 96, dynamicDataCommitment := 0xa2
    depositDataRoot := 0xd2, dataValid := true, rootValid := true
    moduleCallOk := true, beaconCallOk := true }

def batchC : Batch :=
  { moduleId := 11, keys := 1, amount := 32, dynamicDataCommitment := 0xa3
    depositDataRoot := 0xd3, dataValid := true, rootValid := true
    moduleCallOk := true, beaconCallOk := true }

def canonicalInputs : Inputs :=
  { authorized := true, moduleActive := true, allocationValid := true,
    lidoCallOk := true, depositSize := 32, lido := 101, module := 202, beacon := 303,
    batches := [batchA, batchB, batchC] }

def canonicalState : ContractState :=
  (defaultState.writeSlot lidoDepositableSlot 1000).writeSlot counterSlot 41

theorem canonical_preconditions : Preconditions canonicalInputs canonicalState where
  authorized := rfl
  moduleActive := rfl
  allocationValid := rfl
  lidoCallOk := rfl
  healthy := by decide
  distinctModules := by decide
  valueMatches := by decide
  entryBalance := by decide
  funded := by decide
  noWrap := by
    show (64 : Nat) + 96 + 32 < _root_.Verity.Core.Uint256.modulus
    simp [_root_.Verity.Core.Uint256.modulus, _root_.Verity.Core.UINT256_MODULUS]

theorem canonical_observes_source :
    observe canonicalState (probes canonicalInputs)
        ((execute canonicalInputs).run canonicalState)
      = sourceObservables canonicalInputs canonicalState :=
  execute_observes_source canonicalInputs canonicalState canonical_preconditions

theorem canonical_arity_n :
    (probes canonicalInputs).length = 3 ∧
      ((expectedCalls canonicalInputs).filter
        (fun c => decide (c.name = "depositToBeacon"))).length = 3 ∧
      ((expectedCalls canonicalInputs).filter
        (fun c => decide (c.name = "obtainDepositData"))).length = 3 := by
  decide

/-- The arity-2 mutant on the 3-batch witness produces a 2-leg journal,
not the inductive n-frame journal. -/
def canonicalTakeTwo : Inputs :=
  { canonicalInputs with batches := canonicalInputs.batches.take 2 }

theorem executeTwoOnly_canonical :
    executeTwoOnly canonicalInputs = execute canonicalTakeTwo := rfl

theorem canonicalTakeTwo_preconditions : Preconditions canonicalTakeTwo canonicalState where
  authorized := rfl
  moduleActive := rfl
  allocationValid := rfl
  lidoCallOk := rfl
  healthy := by decide
  distinctModules := by decide
  valueMatches := by decide
  entryBalance := by decide
  funded := by decide
  noWrap := by
    show (64 : Nat) + 96 < _root_.Verity.Core.Uint256.modulus
    simp [_root_.Verity.Core.Uint256.modulus, _root_.Verity.Core.UINT256_MODULUS]

theorem observe_callNames_independent_of_probes
    (before : ContractState) (p q : List Word) (r : ContractResult Unit) :
    (observe before p r).callNames = (observe before q r).callNames := by
  cases r <;> simp [observe, viewOf]

theorem executeTwoOnly_drops_tail_journal :
    (sourceObservables canonicalInputs canonicalState).callNames
      = ["obtainDepositData", "obtainDepositData", "obtainDepositData",
         "withdrawDepositableEther",
         "depositToBeacon", "depositToBeacon", "depositToBeacon"] ∧
      (sourceObservables canonicalTakeTwo canonicalState).callNames
        = ["obtainDepositData", "obtainDepositData", "withdrawDepositableEther",
           "depositToBeacon", "depositToBeacon"] ∧
      (probes canonicalInputs).length = 3 ∧
      (probes canonicalTakeTwo).length = 2 := by
  decide

/-! ## Wrapping fold -/

def wrappingBatch (moduleId : Nat) : Batch :=
  { moduleId := _root_.Verity.Core.Uint256.ofNat moduleId, keys := 0
    amount := _root_.Verity.Core.Uint256.ofNat (2 ^ 255)
    dynamicDataCommitment := 0, depositDataRoot := 0
    dataValid := true, rootValid := true
    moduleCallOk := true, beaconCallOk := true }

def wrappingInputs : Inputs :=
  { authorized := true, moduleActive := true, allocationValid := true,
    lidoCallOk := true, depositSize := 32, lido := 101, module := 202, beacon := 303,
    batches := [wrappingBatch 1, wrappingBatch 2] }

theorem wrapping_fold_nat :
    foldedAmountNat wrappingInputs.batches = 2 ^ 256 := by
  have h1 : (_root_.Verity.Core.Uint256.ofNat (2 ^ 255)).val = 2 ^ 255 := by
    rw [_root_.Verity.Core.Uint256.val_ofNat, Nat.mod_eq_of_lt]
    simp [_root_.Verity.Core.Uint256.modulus, _root_.Verity.Core.UINT256_MODULUS]
  change
    (_root_.Verity.Core.Uint256.ofNat (2 ^ 255)).val +
      ((_root_.Verity.Core.Uint256.ofNat (2 ^ 255)).val + 0) = 2 ^ 256
  rw [h1, Nat.add_zero]
  omega

theorem wrapping_fold_exceeds_word :
    ¬ foldedAmountNat wrappingInputs.batches
        < _root_.Verity.Core.Uint256.modulus := by
  rw [wrapping_fold_nat]
  simp [_root_.Verity.Core.Uint256.modulus, _root_.Verity.Core.UINT256_MODULUS]

/-- A wrapping fold does not commit a value-moving journal: the run
reverts and both conservation aggregates stay 0. -/
theorem wrapping_fold_does_not_commit_value_moving :
    ¬ (foldedAmountNat wrappingInputs.batches
          < _root_.Verity.Core.Uint256.modulus) ∧
      (observe canonicalState (probes wrappingInputs)
          ((execute wrappingInputs).run canonicalState)).committed = false ∧
      (observe canonicalState (probes wrappingInputs)
          ((execute wrappingInputs).run canonicalState)).pulled = 0 ∧
      (observe canonicalState (probes wrappingInputs)
          ((execute wrappingInputs).run canonicalState)).pushed = 0 := by
  refine ⟨wrapping_fold_exceeds_word, ?_⟩
  decide

end LidoSRv3.Audit.Verity.DepositNFrameTx
