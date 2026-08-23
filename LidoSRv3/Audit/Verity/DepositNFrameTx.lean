import LidoSRv3.Audit.Verity.DepositParentTx

/-!
# P-DEPOSIT-1 finite list-batch executable

This is the list lift of `DepositParentTx`.  `execute` has two inductive
passes around one aggregate pull:

```
batches.mapM (processBatch inputs)
pullFromLido inputs (wordTotal batches)
batches.mapM (pushBatch inputs)
```

The journal theorem is derived from those executable passes.  `FoldStable`
tracks every exact prefix, rather than assuming only a final modular equality.
-/

namespace LidoSRv3.Audit.Verity.DepositNFrameTx

open _root_.Verity
open _root_.Contracts

abbrev Word := _root_.Verity.Core.Uint256
abbrev Batch := DepositParentTx.Batch

def counterSlot := DepositParentTx.counterSlot
def lidoDepositableSlot := DepositParentTx.lidoDepositableSlot

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

def zeroBatch : Batch :=
  { moduleId := 0, keys := 0, amount := 0, dynamicDataCommitment := 0,
    depositDataRoot := 0, dataValid := true, rootValid := true,
    moduleCallOk := true, beaconCallOk := true }

/-- View the shared fields through the old helper API.  The distinguished
fields are never consulted by `processBatch` or `pushBatch`. -/
def legacyInputs (inputs : Inputs) : DepositParentTx.Inputs :=
  { authorized := inputs.authorized
    moduleActive := inputs.moduleActive
    allocationValid := inputs.allocationValid
    lidoCallOk := inputs.lidoCallOk
    depositSize := inputs.depositSize
    lido := inputs.lido
    module := inputs.module
    beacon := inputs.beacon
    first := zeroBatch
    second := zeroBatch }

def pullLegacyInputs (inputs : Inputs) (total : Word) : DepositParentTx.Inputs :=
  { legacyInputs inputs with first := { zeroBatch with amount := total } }

def exactTotal (batches : List Batch) : Nat :=
  (batches.map fun batch => batch.amount.val).sum

def exactKeys (batches : List Batch) : Nat :=
  (batches.map fun batch => batch.keys.val).sum

def wordTotal (batches : List Batch) : Word :=
  batches.foldl (fun total batch => total + batch.amount) 0

def wordKeys (batches : List Batch) : Word :=
  batches.foldl (fun total batch => total + batch.keys) 0

inductive FoldStable : Nat → List Batch → Prop
  | nil (hAcc : acc < _root_.Verity.Core.Uint256.modulus) : FoldStable acc []
  | cons (hStep : acc + batch.amount.val < _root_.Verity.Core.Uint256.modulus)
      (tail : FoldStable (acc + batch.amount.val) batches) :
      FoldStable acc (batch :: batches)

structure Healthy (batch : Batch) : Prop where
  moduleCallOk : batch.moduleCallOk = true
  dataValid : batch.dataValid = true
  rootValid : batch.rootValid = true
  beaconCallOk : batch.beaconCallOk = true

def processBatch (inputs : Inputs) (batch : Batch) : Contract Unit :=
  DepositParentTx.processBatch (legacyInputs inputs) batch

def pullFromLido (inputs : Inputs) (total : Word) : Contract Unit := do
  externalCallBindTo inputs.lido 0 [] (DepositParentTx.callName inputs.lidoCallOk
    "withdrawDepositableEther") [total]
  let state ← DepositParentTx.getState
  require (total ≤ state.readSlot lidoDepositableSlot) "NOT_ENOUGH_ETHER"
  setStorage ⟨lidoDepositableSlot⟩ (state.readSlot lidoDepositableSlot - total)
  DepositParentTx.creditRouter total

def pushBatch (inputs : Inputs) (batch : Batch) : Contract Unit :=
  DepositParentTx.pushBatch (legacyInputs inputs) batch

/-- The exact bound is checked before either pass.  Therefore a wrapping list
cannot leave a value-moving journal even when callers omit `Preconditions`. -/
def execute (inputs : Inputs) : Contract Unit := do
  require inputs.authorized "NOT_AUTHORIZED"
  require inputs.moduleActive "MODULE_NOT_ACTIVE"
  require inputs.allocationValid "INVALID_ALLOCATION"
  require (decide (exactTotal inputs.batches < _root_.Verity.Core.Uint256.modulus))
    "BATCH_TOTAL_OVERFLOW"
  let state ← DepositParentTx.getState
  setStorage ⟨counterSlot⟩ (state.readSlot counterSlot + 1)
  let _ ← inputs.batches.mapM (processBatch inputs)
  let total := wordTotal inputs.batches
  require (total == wordKeys inputs.batches * inputs.depositSize)
    "ALLOCATION_VALUE_MISMATCH"
  pullFromLido inputs total
  let _ ← inputs.batches.mapM (pushBatch inputs)
  let after ← DepositParentTx.getState
  require (after.selfBalance == state.selfBalance) "ASSERT_BALANCE_UNCHANGED"

def moduleEntry (inputs : Inputs) (batch : Batch) : ExternalCall :=
  linkedCallEntryTo "obtainDepositData" inputs.module 0 [batch.moduleId, batch.keys]

def pullEntry (inputs : Inputs) : ExternalCall :=
  linkedCallEntryTo "withdrawDepositableEther" inputs.lido 0 [wordTotal inputs.batches]

def pushEntry (inputs : Inputs) (batch : Batch) : ExternalCall :=
  linkedCallEntryTo "depositToBeacon" inputs.beacon batch.amount
    [batch.moduleId, batch.keys, batch.dynamicDataCommitment, batch.depositDataRoot]

def expectedCalls (inputs : Inputs) : List ExternalCall :=
  inputs.batches.map (moduleEntry inputs) ++ [pullEntry inputs] ++
    inputs.batches.map (pushEntry inputs)

@[ext] structure Observables where
  committed : Bool
  routerRetained : Nat
  journal : List ExternalCall
  deriving Repr, DecidableEq

def observe (before : ContractState) : ContractResult Unit → Observables
  | .revert _ _ => ⟨false, before.selfBalance.val, []⟩
  | .success _ after =>
      ⟨true, after.selfBalance.val, after.calls.drop before.calls.length⟩

def sourceObservables (inputs : Inputs) (before : ContractState) : Observables :=
  ⟨true, before.selfBalance.val, expectedCalls inputs⟩

structure Preconditions (inputs : Inputs) (state : ContractState) : Prop where
  authorized : inputs.authorized = true
  moduleActive : inputs.moduleActive = true
  allocationValid : inputs.allocationValid = true
  lidoCallOk : inputs.lidoCallOk = true
  healthy : ∀ batch ∈ inputs.batches, Healthy batch
  distinctModules : (inputs.batches.map fun batch => batch.moduleId).Nodup
  valueMatches : wordTotal inputs.batches = wordKeys inputs.batches * inputs.depositSize
  entryBalance : state.selfBalance = 0
  funded : wordTotal inputs.batches ≤ state.readSlot lidoDepositableSlot
  foldStable : FoldStable 0 inputs.batches

theorem foldStable_bound {acc : Nat} {batches : List Batch}
    (h : FoldStable acc batches) :
    acc + exactTotal batches < _root_.Verity.Core.Uint256.modulus := by
  induction h with
  | nil hAcc => simpa [exactTotal] using hAcc
  | cons hStep tail ih =>
      simp only [exactTotal, List.map_cons, List.sum_cons]
      omega

theorem foldStable_of_bound (acc : Nat) (batches : List Batch)
    (h : acc + exactTotal batches < _root_.Verity.Core.Uint256.modulus) :
    FoldStable acc batches := by
  induction batches generalizing acc with
  | nil =>
      exact .nil (by simpa [exactTotal] using h)
  | cons batch batches ih =>
      apply FoldStable.cons
      · simp only [exactTotal, List.map_cons, List.sum_cons] at h
        omega
      · apply ih
        simp only [exactTotal, List.map_cons, List.sum_cons] at h ⊢
        omega

theorem wordFold_val {acc : Nat} (start : Word) {batches : List Batch}
    (hStart : start.val = acc) (h : FoldStable acc batches) :
    (batches.foldl (fun total batch => total + batch.amount) start).val =
      acc + exactTotal batches := by
  induction batches generalizing acc start with
  | nil => simp [exactTotal, hStart]
  | cons batch batches ih =>
      cases h with
      | cons hStep tail =>
          simp only [List.foldl_cons]
          apply ih (acc := acc + batch.amount.val) (start := start + batch.amount)
            (by
              apply _root_.Verity.Core.Uint256.add_eq_of_lt
              simpa [hStart] using hStep) tail

theorem wordTotal_val (batches : List Batch) (h : FoldStable 0 batches) :
    (wordTotal batches).val = exactTotal batches := by
  simpa [wordTotal] using wordFold_val (0 : Word) rfl h

def afterBatch (inputs : Inputs) (batch : Batch) (state : ContractState) : ContractState :=
  DepositParentTx.afterBatch (legacyInputs inputs) batch state

def afterBatches (inputs : Inputs) : List Batch → ContractState → ContractState
  | [], state => state
  | batch :: batches, state => afterBatches inputs batches (afterBatch inputs batch state)

abbrev afterCall (value : Word) (entry : ExternalCall) (state : ContractState) : ContractState :=
  DepositParentTx.afterCall value entry state

def afterPull (inputs : Inputs) (total : Word) (state : ContractState) : ContractState :=
  let s1 := afterCall 0
    (linkedCallEntryTo "withdrawDepositableEther" inputs.lido 0 [total]) state
  let s2 := s1.writeSlot lidoDepositableSlot (s1.readSlot lidoDepositableSlot - total)
  { s2 with selfBalance := s2.selfBalance + total }

def afterPush (inputs : Inputs) (batch : Batch) (state : ContractState) : ContractState :=
  DepositParentTx.afterPush (legacyInputs inputs) batch state

def afterPushes (inputs : Inputs) : List Batch → ContractState → ContractState
  | [], state => state
  | batch :: batches, state => afterPushes inputs batches (afterPush inputs batch state)

def committedState (inputs : Inputs) (state : ContractState) : ContractState :=
  afterPushes inputs inputs.batches
    (afterPull inputs (wordTotal inputs.batches)
      (afterBatches inputs inputs.batches
        (state.writeSlot counterSlot (state.readSlot counterSlot + 1))))

theorem processBatch_apply (inputs : Inputs) (batch : Batch) (state : ContractState)
    (h : Healthy batch) :
    processBatch inputs batch state = .success () (afterBatch inputs batch state) := by
  exact DepositParentTx.processBatch_apply (legacyInputs inputs) batch state
    h.moduleCallOk h.dataValid h.rootValid

theorem processBatches_apply (inputs : Inputs) (batches : List Batch) (state : ContractState)
    (h : ∀ batch ∈ batches, Healthy batch) :
    batches.mapM (processBatch inputs) state =
      .success (List.replicate batches.length ()) (afterBatches inputs batches state) := by
  induction batches generalizing state with
  | nil => simp [_root_.Verity.pure, afterBatches]
  | cons batch batches ih =>
      have hb := h batch (by simp)
      have ht : ∀ b ∈ batches, Healthy b := fun b hmem => h b (by simp [hmem])
      rw [List.mapM_cons]
      simp only [Bind.bind, _root_.Verity.bind, processBatch_apply inputs batch state hb]
      rw [ih (state := afterBatch inputs batch state) ht]
      rfl

theorem pullFromLido_apply (inputs : Inputs) (total : Word) (state : ContractState)
    (hCall : inputs.lidoCallOk = true)
    (hFunded : total ≤ state.readSlot lidoDepositableSlot) :
    pullFromLido inputs total state = .success () (afterPull inputs total state) := by
  have hOld := DepositParentTx.pullFromLido_apply (pullLegacyInputs inputs total) state
    hCall (by simpa [pullLegacyInputs, legacyInputs, DepositParentTx.totalAmount,
      zeroBatch, _root_.Verity.Core.Uint256.add_zero] using hFunded)
  simpa [pullFromLido, pullLegacyInputs, legacyInputs, DepositParentTx.pullFromLido,
    DepositParentTx.totalAmount, DepositParentTx.afterPull, DepositParentTx.pullEntry,
    zeroBatch, afterPull, afterCall, _root_.Verity.Core.Uint256.add_zero] using hOld

theorem pushBatch_apply (inputs : Inputs) (batch : Batch) (state : ContractState)
    (hCall : batch.beaconCallOk = true) (hBal : batch.amount ≤ state.selfBalance) :
    pushBatch inputs batch state = .success () (afterPush inputs batch state) :=
  DepositParentTx.pushBatch_apply (legacyInputs inputs) batch state hCall hBal

@[simp] theorem selfBalance_afterBatch (inputs : Inputs) (batch : Batch)
    (state : ContractState) :
    (afterBatch inputs batch state).selfBalance = state.selfBalance :=
  DepositParentTx.selfBalance_afterBatch _ _ _

theorem selfBalance_afterBatches (inputs : Inputs) (batches : List Batch)
    (state : ContractState) :
    (afterBatches inputs batches state).selfBalance = state.selfBalance := by
  induction batches generalizing state with
  | nil => rfl
  | cons batch batches ih => rw [afterBatches, ih, selfBalance_afterBatch]

@[simp] theorem readSlot_afterBatch (inputs : Inputs) (batch : Batch)
    (state : ContractState) (slotId : Nat) :
    (afterBatch inputs batch state).readSlot slotId = state.readSlot slotId :=
  DepositParentTx.readSlot_afterBatch _ _ _ _

theorem readSlot_afterBatches (inputs : Inputs) (batches : List Batch)
    (state : ContractState) (slotId : Nat) :
    (afterBatches inputs batches state).readSlot slotId = state.readSlot slotId := by
  induction batches generalizing state with
  | nil => rfl
  | cons batch batches ih => rw [afterBatches, ih, readSlot_afterBatch]

@[simp] theorem calls_afterBatch (inputs : Inputs) (batch : Batch) (state : ContractState) :
    (afterBatch inputs batch state).calls = state.calls ++ [moduleEntry inputs batch] := rfl

theorem calls_afterBatches (inputs : Inputs) (batches : List Batch)
    (state : ContractState) :
    (afterBatches inputs batches state).calls =
      state.calls ++ batches.map (moduleEntry inputs) := by
  induction batches generalizing state with
  | nil => simp [afterBatches]
  | cons batch batches ih =>
      rw [afterBatches, ih, calls_afterBatch]
      simp [List.append_assoc]

@[simp] theorem selfBalance_afterPull (inputs : Inputs) (total : Word)
    (state : ContractState) :
    (afterPull inputs total state).selfBalance = state.selfBalance + total := by
  show state.selfBalance - 0 + total = _
  rw [_root_.Verity.Core.Uint256.sub_zero]

@[simp] theorem calls_afterPull (inputs : Inputs) (total : Word) (state : ContractState) :
    (afterPull inputs total state).calls =
      state.calls ++ [linkedCallEntryTo "withdrawDepositableEther" inputs.lido 0 [total]] := rfl

@[simp] theorem calls_afterPush (inputs : Inputs) (batch : Batch) (state : ContractState) :
    (afterPush inputs batch state).calls = state.calls ++ [pushEntry inputs batch] := rfl

theorem calls_afterPushes (inputs : Inputs) (batches : List Batch)
    (state : ContractState) :
    (afterPushes inputs batches state).calls =
      state.calls ++ batches.map (pushEntry inputs) := by
  induction batches generalizing state with
  | nil => simp [afterPushes]
  | cons batch batches ih =>
      rw [afterPushes, ih, calls_afterPush]
      simp [List.append_assoc]

theorem selfBalance_afterPushes (inputs : Inputs) (batches : List Batch)
    (state : ContractState) (hFunds : exactTotal batches ≤ state.selfBalance.val) :
    (afterPushes inputs batches state).selfBalance.val =
      state.selfBalance.val - exactTotal batches := by
  induction batches generalizing state with
  | nil => simp [afterPushes, exactTotal]
  | cons batch batches ih =>
      have hHead : batch.amount.val ≤ state.selfBalance.val := by
        simp only [exactTotal, List.map_cons, List.sum_cons] at hFunds
        omega
      have hSub : (state.selfBalance - batch.amount).val =
          state.selfBalance.val - batch.amount.val :=
        _root_.Verity.Core.Uint256.sub_eq_of_le hHead
      have hTail : exactTotal batches ≤ (afterPush inputs batch state).selfBalance.val := by
        simp only [afterPush, DepositParentTx.afterPush, DepositParentTx.afterCall, hSub]
        simp only [exactTotal, List.map_cons, List.sum_cons] at hFunds
        omega
      rw [afterPushes, ih (state := afterPush inputs batch state) hTail]
      simp only [afterPush, DepositParentTx.afterPush, DepositParentTx.afterCall, hSub,
        exactTotal, List.map_cons, List.sum_cons]
      omega

theorem pushBatches_apply (inputs : Inputs) (batches : List Batch) (state : ContractState)
    (hHealthy : ∀ batch ∈ batches, Healthy batch)
    (hFunds : exactTotal batches ≤ state.selfBalance.val) :
    batches.mapM (pushBatch inputs) state =
      .success (List.replicate batches.length ()) (afterPushes inputs batches state) := by
  induction batches generalizing state with
  | nil => simp [_root_.Verity.pure, afterPushes]
  | cons batch batches ih =>
      have hb := hHealthy batch (by simp)
      have ht : ∀ b ∈ batches, Healthy b :=
        fun b hmem => hHealthy b (by simp [hmem])
      have hHeadVal : batch.amount.val ≤ state.selfBalance.val := by
        simp only [exactTotal, List.map_cons, List.sum_cons] at hFunds
        omega
      have hHead : batch.amount ≤ state.selfBalance := hHeadVal
      have hSub : (state.selfBalance - batch.amount).val =
          state.selfBalance.val - batch.amount.val :=
        _root_.Verity.Core.Uint256.sub_eq_of_le hHeadVal
      have hRest : exactTotal batches ≤ (afterPush inputs batch state).selfBalance.val := by
        simp only [afterPush, DepositParentTx.afterPush, DepositParentTx.afterCall, hSub]
        simp only [exactTotal, List.map_cons, List.sum_cons] at hFunds
        omega
      rw [List.mapM_cons]
      simp only [Bind.bind, _root_.Verity.bind,
        pushBatch_apply inputs batch state hb.beaconCallOk hHead]
      rw [ih (state := afterPush inputs batch state) ht hRest]
      rfl

theorem execute_apply (inputs : Inputs) (state : ContractState)
    (h : Preconditions inputs state) :
    execute inputs state = .success () (committedState inputs state) := by
  let entry := state.writeSlot counterSlot (state.readSlot counterSlot + 1)
  let processed := afterBatches inputs inputs.batches entry
  let pulled := afterPull inputs (wordTotal inputs.batches) processed
  have hNoWrap :
      exactTotal inputs.batches < _root_.Verity.Core.Uint256.modulus :=
    foldStable_bound h.foldStable
  have hNoWrapGuard :
      decide (exactTotal inputs.batches < _root_.Verity.Core.Uint256.modulus) = true :=
    decide_eq_true hNoWrap
  have hLido : processed.readSlot lidoDepositableSlot =
      state.readSlot lidoDepositableSlot := by
    rw [show processed = afterBatches inputs inputs.batches entry from rfl,
      readSlot_afterBatches]
    exact ContractState.readSlot_writeSlot_other _ (by decide)
  have hFunded : wordTotal inputs.batches ≤ processed.readSlot lidoDepositableSlot := by
    rw [hLido]
    exact h.funded
  have hProcessedBalance : processed.selfBalance = 0 := by
    rw [show processed = afterBatches inputs inputs.batches entry from rfl,
      selfBalance_afterBatches]
    exact h.entryBalance
  have hPulledBalance : pulled.selfBalance = wordTotal inputs.batches := by
    rw [show pulled = afterPull inputs (wordTotal inputs.batches) processed from rfl,
      selfBalance_afterPull, hProcessedBalance, _root_.Verity.Core.Uint256.zero_add]
  have hTotalVal := wordTotal_val inputs.batches h.foldStable
  have hPushFunds : exactTotal inputs.batches ≤ pulled.selfBalance.val := by
    rw [hPulledBalance, hTotalVal]
  have hCloseVal :
      (afterPushes inputs inputs.batches pulled).selfBalance.val = state.selfBalance.val := by
    rw [selfBalance_afterPushes inputs inputs.batches pulled hPushFunds, hPulledBalance,
      hTotalVal]
    simp [h.entryBalance]
  have hClose :
      (afterPushes inputs inputs.batches pulled).selfBalance = state.selfBalance :=
    _root_.Verity.Core.Uint256.ext hCloseVal
  have hValueGuard :
      (wordTotal inputs.batches == wordKeys inputs.batches * inputs.depositSize) = true := by
    simp [h.valueMatches]
  simp only [execute, Bind.bind, _root_.Verity.bind, _root_.Verity.require,
    h.authorized, h.moduleActive, h.allocationValid, hNoWrapGuard, if_true,
    DepositParentTx.getState, setStorage]
  rw [processBatches_apply inputs inputs.batches entry h.healthy]
  simp only [Bind.bind, _root_.Verity.bind, hValueGuard, _root_.Verity.require, if_true]
  rw [pullFromLido_apply inputs (wordTotal inputs.batches) processed h.lidoCallOk hFunded]
  simp only [Bind.bind, _root_.Verity.bind]
  rw [pushBatches_apply inputs inputs.batches pulled h.healthy hPushFunds]
  simp only [Bind.bind, _root_.Verity.bind, DepositParentTx.getState, hClose,
    beq_self_eq_true, _root_.Verity.require, if_true, committedState, entry, processed, pulled]

theorem execute_run (inputs : Inputs) (state : ContractState)
    (h : Preconditions inputs state) :
    (execute inputs).run state = .success () (committedState inputs state) := by
  simp [Contract.run, execute_apply inputs state h]

theorem committed_calls (inputs : Inputs) (state : ContractState) :
    (committedState inputs state).calls = state.calls ++ expectedCalls inputs := by
  simp only [committedState, calls_afterPushes, calls_afterPull, calls_afterBatches,
    ContractState.calls_writeSlot, expectedCalls, pullEntry]
  simp [List.append_assoc]

theorem committed_balance (inputs : Inputs) (state : ContractState)
    (h : Preconditions inputs state) :
    (committedState inputs state).selfBalance = state.selfBalance := by
  have hBefore :
      (afterBatches inputs inputs.batches
        (state.writeSlot counterSlot (state.readSlot counterSlot + 1))).selfBalance = 0 := by
    rw [selfBalance_afterBatches]
    exact h.entryBalance
  have hAfterPull :
      (afterPull inputs (wordTotal inputs.batches)
        (afterBatches inputs inputs.batches
          (state.writeSlot counterSlot (state.readSlot counterSlot + 1)))).selfBalance =
        wordTotal inputs.batches := by
    rw [selfBalance_afterPull, hBefore, _root_.Verity.Core.Uint256.zero_add]
  have hFunds : exactTotal inputs.batches ≤
      (afterPull inputs (wordTotal inputs.batches)
        (afterBatches inputs inputs.batches
          (state.writeSlot counterSlot (state.readSlot counterSlot + 1)))).selfBalance.val := by
    rw [hAfterPull, wordTotal_val inputs.batches h.foldStable]
  apply _root_.Verity.Core.Uint256.ext
  rw [committedState, selfBalance_afterPushes inputs inputs.batches _ hFunds, hAfterPull,
    wordTotal_val inputs.batches h.foldStable]
  simp [h.entryBalance]

theorem execute_observes_source (inputs : Inputs) (state : ContractState)
    (h : Preconditions inputs state) :
    observe state ((execute inputs).run state) = sourceObservables inputs state := by
  rw [execute_run inputs state h]
  apply Observables.ext <;>
    simp [observe, sourceObservables, committed_balance inputs state h, committed_calls,
      List.drop_left]

/-- Exact public conclusion shared by the production theorem and mutant. -/
def ParentConclusion (program : Inputs → Contract Unit) (inputs : Inputs)
    (state : ContractState) : Prop :=
  observe state ((program inputs).run state) = sourceObservables inputs state ∧
    (wordTotal inputs.batches).val = exactTotal inputs.batches ∧
    exactTotal inputs.batches < _root_.Verity.Core.Uint256.modulus ∧
    (inputs.batches.map (moduleEntry inputs)).length = inputs.batches.length ∧
    (inputs.batches.map (pushEntry inputs)).length = inputs.batches.length

theorem nframe_deposit_parent (inputs : Inputs) (state : ContractState)
    (h : Preconditions inputs state) :
    ParentConclusion execute inputs state := by
  exact ⟨execute_observes_source inputs state h,
    wordTotal_val inputs.batches h.foldStable,
    foldStable_bound h.foldStable, by simp, by simp⟩

theorem wrapping_fold_reverts_without_journal (inputs : Inputs) (state : ContractState)
    (hAuthorized : inputs.authorized = true)
    (hActive : inputs.moduleActive = true)
    (hAllocation : inputs.allocationValid = true)
    (hWrap : _root_.Verity.Core.Uint256.modulus ≤ exactTotal inputs.batches) :
    (execute inputs).run state = .revert "BATCH_TOTAL_OVERFLOW" state ∧
      observe state ((execute inputs).run state) = ⟨false, state.selfBalance.val, []⟩ := by
  have hGuard :
      decide (exactTotal inputs.batches < _root_.Verity.Core.Uint256.modulus) = false :=
    decide_eq_false (Nat.not_lt.mpr hWrap)
  simp [execute, Contract.run, hAuthorized, hActive, hAllocation, hGuard, observe]

def ofTwoBatches (inputs : DepositParentTx.Inputs) : Inputs :=
  { authorized := inputs.authorized, moduleActive := inputs.moduleActive,
    allocationValid := inputs.allocationValid, lidoCallOk := inputs.lidoCallOk,
    depositSize := inputs.depositSize, lido := inputs.lido, module := inputs.module,
    beacon := inputs.beacon, batches := [inputs.first, inputs.second] }

theorem two_batch_expectedCalls_eq (inputs : DepositParentTx.Inputs) :
    expectedCalls (ofTwoBatches inputs) = DepositParentTx.expectedCalls inputs := by
  simp [expectedCalls, ofTwoBatches, moduleEntry, pullEntry, pushEntry, wordTotal,
    DepositParentTx.expectedCalls, DepositParentTx.moduleEntry, DepositParentTx.pullEntry,
    DepositParentTx.pushEntry, DepositParentTx.totalAmount]

theorem two_batch_is_n_eq_two (inputs : DepositParentTx.Inputs) :
    (ofTwoBatches inputs).batches.length = 2 ∧
      ((ofTwoBatches inputs).batches.map (moduleEntry (ofTwoBatches inputs))).length = 2 ∧
      ((ofTwoBatches inputs).batches.map (pushEntry (ofTwoBatches inputs))).length = 2 := by
  simp [ofTwoBatches]

end LidoSRv3.Audit.Verity.DepositNFrameTx
