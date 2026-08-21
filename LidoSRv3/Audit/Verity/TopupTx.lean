import LidoSRv3.Audit.Source.TopupCorrespondence
import Contracts.Common

/-!
# Faithful executable P-TOPUP-1 transaction

An independent `Contract.run` program for the pinned `StakingRouter.topUp`
observable flow.  It does not call `SolidityTopup.run` or
`SolidityTopupParent.sourceExecute`.

Both value-moving hops run through Verity's own external-call frame
primitive, `Contracts.externalCallBindTo`: the frame checks the caller can
pay, debits `selfBalance`, and *itself* appends the journal entry recording
destination, wei value, and argument words.  Nothing here appends a
pre-built journal, so the call sequence in `ContractState.calls` is produced
by execution and the correspondence theorem below has to derive it.

Allocation amounts are materialized with `writeMapUint` and the running
aggregate with `writeSlot`.  Failure schedules revert after real intermediate
writes and real journalled frames, exposing transaction rollback.
Correspondence compares outcome observables, never full post-states.
-/

namespace LidoSRv3.Audit.Verity.TopupTx

open _root_.Verity
open _root_.Contracts
open LidoSRv3.Audit.SolidityTopup

def allocationSlot : Nat := 7100
def allocationTotalSlot : Nat := 7101
def pulledTotalSlot : Nat := 7102

def lidoAddress : Address := (0xF00D : Address)
def beaconAddress : Address := (0x00000000219ab540356cBB839Cbe05303d7705Fa : Address)

inductive FailurePoint where
  | none
  | afterAllocationWrite
  | afterLidoPull
  | afterFirstBeaconPush
  deriving Repr, DecidableEq

/-! ## Source-shaped schedule

Read off the pinned source's `allocations` array alone.  `execute` below
never consults these definitions; they are the specification side of the
correspondence. -/

/-- The push schedule of the pinned source's loop: one entry per nonzero
allocation carrying its index and wei.  The `if amount = 0` skip is the
`continue` at `BeaconChainDepositor.sol` line 89; the retained pair is the
transfer at line 106. -/
def sourcePushes : List Nat → Nat → List (Nat × Nat)
  | [], _ => []
  | amount :: rest, index =>
      if amount = 0 then sourcePushes rest (index + 1)
      else (index, amount) :: sourcePushes rest (index + 1)

/-- Calldata and call values are 256-bit EVM words, so the schedule states
them reduced.  Only the loop index needs this: `A-TOPUP-NOWRAP` already
bounds every wei amount. -/
def evmWord (n : Nat) : Nat := n % uint256Modulus

/-! ## Executable transaction -/

/-- Source-shaped allocation loop, expressed solely with Verity storage. -/
def allocationPass : List Nat → Nat → Nat → ContractState → ContractState
  | [], _, total, state => state.writeSlot allocationTotalSlot total
  | amount :: rest, index, total, state =>
      allocationPass rest (index + 1) (total + amount)
        ((state.writeMapUint allocationSlot index amount).writeSlot
          allocationTotalSlot (total + amount))

/-- The allocation loop as a transaction step, with the pull slot zeroed. -/
def allocationStage (allocations : List Nat) : Contract Unit := fun state =>
  .success () ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0)

/-- Real external-call frame: the zero-value Lido pull at source line 744.
`externalCallBindTo` journals the destination and argument word itself. -/
def lidoPull (total : Nat) : Contract Unit :=
  externalCallBindTo lidoAddress 0 [] "withdrawDepositableEther"
    ([(total : Uint256)] : List Uint256)

/-- The wei `withdrawDepositableEther` hands back.  `externalCallBindTo` is a
caller-side frame: it debits, journals, and binds, but callee-originated
inflow is outside its remit (callee state lives in `Verity.MultiContract`), so
the credit is an explicit step. -/
def creditPull (total : Nat) : Contract Unit := fun state =>
  .success ()
    (({ state with selfBalance := state.selfBalance + (total : Uint256) }).writeSlot
      pulledTotalSlot (total : Uint256))

/-- Real external-call frame: one value-bearing beacon push.  The frame fails
closed when the router cannot pay, so a push is gated on funds actually held. -/
def beaconPush (index amount : Nat) : Contract Unit :=
  externalCallBindTo beaconAddress (amount : Uint256) [] "makeBeaconChainTopUp"
    ([(index : Uint256), (amount : Uint256)] : List Uint256)

/-- The push loop.  Zero allocations are skipped exactly as
`BeaconChainDepositor.sol` line 89 does.  `stopAfterFirst` injects a failure
once the first frame has really debited and journalled. -/
def pushLoop (stopAfterFirst : Bool) : List Nat → Nat → Contract Unit
  | [], _ => Verity.pure ()
  | amount :: rest, index =>
      if amount = 0 then pushLoop stopAfterFirst rest (index + 1)
      else do
        beaconPush index amount
        require (!stopAfterFirst) "FAIL_AFTER_FIRST_BEACON_PUSH"
        pushLoop stopAfterFirst rest (index + 1)

/-- Pull the aggregate from Lido, then forward every non-zero allocation to
the deposit contract.  Both legs go through real `externalCallBindTo` frames,
so the journal is produced by execution rather than asserted. -/
def pushStage (allocations : List Nat) (total : Nat) (failure : FailurePoint) :
    Contract Unit := do
  lidoPull total
  creditPull total
  require (decide (failure ≠ .afterLidoPull)) "FAIL_AFTER_LIDO_PULL"
  pushLoop (failure = .afterFirstBeaconPush) allocations 0

/-- Executable Verity transaction.  Every failure point sits *after* real
storage writes and, past the first, after real journalled call frames;
`Contract.run` supplies the transaction boundary that restores the snapshot. -/
def execute (allocations : List Nat) (failure : FailurePoint) : Contract Unit := do
  allocationStage allocations
  require (decide (failure ≠ .afterAllocationWrite)) "FAIL_AFTER_ALLOCATION_WRITE"
  let total := allocSumUnchecked allocations
  if total = 0 then Verity.pure ()
  else pushStage allocations total failure

/-! ## Observables -/

/-- Everything a caller can observe at the transaction boundary: the
per-allocation mapping words, the aggregate slots, and the external-call
journal projected onto destination, wei value, argument words, and order. -/
@[ext] structure OutcomeObservables where
  committed : Bool
  allocationCells : List Nat
  allocationTotal : Nat
  pulled : Nat
  pushed : Nat
  callNames : List String
  callTargets : List Nat
  callValues : List Nat
  callArgs : List (List Nat)
  deriving Repr, DecidableEq

def callValueOf (name : String) : List ExternalCall → Nat
  | [] => 0
  | call :: rest => (if call.name == name then call.value else 0) + callValueOf name rest

/-- The per-allocation mapping words, index-ordered. -/
def cellsOf (state : ContractState) (index count : Nat) : List Nat :=
  (List.range count).map
    (fun i => (state.readMapUint allocationSlot ((index + i : Nat) : Uint256)).val)

def observe (before : ContractState) (allocationCount : Nat) :
    ContractResult Unit → OutcomeObservables
  | .revert _ _ => ⟨false, [], 0, 0, 0, [], [], [], []⟩
  | .success _ after =>
      let fresh := after.calls.drop before.calls.length
      ⟨true, cellsOf after 0 allocationCount,
        (after.readSlot allocationTotalSlot).val,
        (after.readSlot pulledTotalSlot).val,
        callValueOf "makeBeaconChainTopUp" fresh,
        fresh.map (·.name), fresh.map (·.target),
        fresh.map (·.value), fresh.map (·.calldata)⟩

/-- Independent source-shaped observable specification.

Totals are the on-chain wrapped reading `allocSumUnchecked` (`wrappedTotal =
exactTotal % 2^256`).  A wrap-to-zero batch is an empty success: no pull and
no pushes.  Under `NoUncheckedWrap` this coincides with the exact `Nat` sum. -/
def sourceObservables (allocations : List Nat) : OutcomeObservables :=
  let wrapped := allocSumUnchecked allocations
  let pushes := sourcePushes allocations 0
  ⟨true, allocations, wrapped, wrapped, wrapped,
    if wrapped = 0 then [] else
      "withdrawDepositableEther" :: pushes.map (fun _ => "makeBeaconChainTopUp"),
    if wrapped = 0 then [] else
      lidoAddress.toNat :: pushes.map (fun _ => beaconAddress.toNat),
    if wrapped = 0 then [] else 0 :: pushes.map (fun p => evmWord p.2),
    if wrapped = 0 then [] else
      [evmWord wrapped] :: pushes.map (fun p => [evmWord p.1, evmWord p.2])⟩

/-! ## The journal execution has to produce

`pushEntry` and `expectedCalls` are stated from the source-shaped schedule.
`execute` does not mention them: the theorems below derive them from the
`externalCallBindTo` frames the transaction actually runs. -/

def pushEntry (p : Nat × Nat) : ExternalCall :=
  linkedCallEntryTo "makeBeaconChainTopUp" beaconAddress (p.2 : Uint256)
    [(p.1 : Uint256), (p.2 : Uint256)]

def beaconJournal (allocations : List Nat) (index : Nat) : List ExternalCall :=
  (sourcePushes allocations index).map pushEntry

def pullEntry (total : Nat) : ExternalCall :=
  linkedCallEntryTo "withdrawDepositableEther" lidoAddress 0 [(total : Uint256)]

def expectedCalls (allocations : List Nat) : List ExternalCall :=
  if allocSumUnchecked allocations = 0 then []
  else pullEntry (allocSumUnchecked allocations) :: beaconJournal allocations 0

/-! ## Word and storage laws

Verity ships `readMapUint_writeMapUint_same` but no disjoint-key companion, so
the three lens laws the allocation loop needs are proved here. -/

theorem word_val {n : Nat} (h : n < uint256Modulus) : ((n : Uint256)).val = n :=
  Nat.mod_eq_of_lt h

theorem word_ne {a b : Nat} (ha : a < uint256Modulus) (hb : b < uint256Modulus)
    (hne : a ≠ b) : ((a : Uint256)) ≠ ((b : Uint256)) := fun h =>
  hne (by rw [← word_val ha, ← word_val hb, h])

theorem ofNat_val (x : Uint256) : ((x.val : Nat) : Uint256) = x :=
  Verity.Core.Uint256.ext (Nat.mod_eq_of_lt x.isLt)

theorem getD_eq (l : List Nat) {i : Nat} (hi : i < l.length) : l.getD i 0 = l[i] := by
  simp [List.getD_eq_getElem?_getD, List.getElem?_eq_getElem hi]

theorem readMapUint_writeMapUint_other (state : ContractState) (mapSlot : Nat)
    {key key' : Uint256} (h : key' ≠ key) (value : Uint256) :
    (state.writeMapUint mapSlot key value).readMapUint mapSlot key' =
      state.readMapUint mapSlot key' := by
  simp [ContractState.readMapUint, ContractState.storageMapUint,
    ContractState.writeMapUint, h]

theorem readMapUint_writeSlot (state : ContractState) (mapSlot wordSlot : Nat)
    (key value : Uint256) :
    (state.writeSlot wordSlot value).readMapUint mapSlot key =
      state.readMapUint mapSlot key := by
  simp [ContractState.readMapUint, ContractState.storageMapUint, ContractState.writeSlot]

theorem readSlot_writeMapUint (state : ContractState) (mapSlot wordSlot : Nat)
    (key value : Uint256) :
    (state.writeMapUint mapSlot key value).readSlot wordSlot = state.readSlot wordSlot := by
  simp [ContractState.readSlot, ContractState.storage, ContractState.writeMapUint]

/-! ## What the allocation loop does to storage -/

theorem allocationPass_calls : ∀ (l : List Nat) (index total : Nat) (state : ContractState),
    (allocationPass l index total state).calls = state.calls
  | [], _, _, _ => rfl
  | a :: rest, index, total, state => by
      rw [allocationPass]
      exact allocationPass_calls rest (index + 1) (total + a) _

theorem allocationPass_selfBalance :
    ∀ (l : List Nat) (index total : Nat) (state : ContractState),
      (allocationPass l index total state).selfBalance = state.selfBalance
  | [], _, _, _ => rfl
  | a :: rest, index, total, state => by
      rw [allocationPass]
      exact allocationPass_selfBalance rest (index + 1) (total + a) _

theorem allocationPass_total :
    ∀ (l : List Nat) (index total : Nat) (state : ContractState),
      (allocationPass l index total state).readSlot allocationTotalSlot
        = ((total + allocSum l : Nat) : Uint256)
  | [], _, total, state => by
      simp [allocationPass, allocSum, ContractState.readSlot_writeSlot_same]
  | a :: rest, index, total, state => by
      rw [allocationPass, allocationPass_total rest (index + 1) (total + a)]
      have : total + a + allocSum rest = total + allocSum (a :: rest) := by
        simp [allocSum]; omega
      rw [this]

/-- Writes made at indices at or above `index` leave a strictly smaller key
alone.  This is where the `Uint256` key encoding has to be injective, hence the
`index + l.length ≤ uint256Modulus` side condition. -/
theorem allocationPass_cell_untouched (l : List Nat) :
    ∀ (index total : Nat) (state : ContractState) (k : Nat),
      k < index → index + l.length ≤ uint256Modulus →
      (allocationPass l index total state).readMapUint allocationSlot ((k : Nat) : Uint256)
        = state.readMapUint allocationSlot ((k : Nat) : Uint256) := by
  induction l with
  | nil =>
      intro index total state k _ _
      simpa [allocationPass] using readMapUint_writeSlot state allocationSlot
        allocationTotalSlot ((k : Nat) : Uint256) ((total : Nat) : Uint256)
  | cons a rest ih =>
      intro index total state k hk hLen
      have hIndex : index < uint256Modulus := by simp [List.length_cons] at hLen; omega
      have hk' : k < uint256Modulus := Nat.lt_trans hk hIndex
      rw [allocationPass]
      rw [ih (index + 1) (total + a) _ k (Nat.lt_succ_of_lt hk)
        (by simp [List.length_cons] at hLen; omega)]
      rw [readMapUint_writeSlot, readMapUint_writeMapUint_other _ _
        (word_ne hk' hIndex (Nat.ne_of_lt hk))]

theorem allocationPass_cell (l : List Nat) :
    ∀ (index total : Nat) (state : ContractState) (i : Nat),
      i < l.length → index + l.length ≤ uint256Modulus →
      (allocationPass l index total state).readMapUint allocationSlot
          ((index + i : Nat) : Uint256)
        = ((l.getD i 0 : Nat) : Uint256) := by
  induction l with
  | nil => intro index total state i hi _; simp at hi
  | cons a rest ih =>
      intro index total state i hi hLen
      match i with
      | 0 =>
          rw [Nat.add_zero, allocationPass]
          rw [allocationPass_cell_untouched rest (index + 1) (total + a) _ index
            (Nat.lt_succ_self _) (by simp [List.length_cons] at hLen; omega)]
          rw [readMapUint_writeSlot, ContractState.readMapUint_writeMapUint_same]
          simp
      | j + 1 =>
          have hj : j < rest.length := by simp [List.length_cons] at hi; omega
          have hstep : index + (j + 1) = (index + 1) + j := by omega
          rw [hstep, allocationPass]
          rw [ih (index + 1) (total + a) _ j hj
            (by simp [List.length_cons] at hLen; omega)]
          simp

theorem cellsOf_allocationPass (l : List Nat) (total : Nat) (state : ContractState)
    (hLen : l.length ≤ uint256Modulus)
    (hAmt : ∀ a ∈ l, a < uint256Modulus) :
    cellsOf (allocationPass l 0 total state) 0 l.length = l := by
  apply List.ext_getElem
  · simp [cellsOf]
  · intro i h1 h2
    have hi : i < l.length := h2
    have hmem : l.getD i 0 ∈ l := by
      rw [getD_eq l hi]
      exact List.getElem_mem hi
    simp only [cellsOf, List.getElem_map, List.getElem_range]
    rw [allocationPass_cell l 0 total state i hi (by simpa using hLen)]
    rw [word_val (hAmt _ hmem), getD_eq l hi]

/-! ## What the external-call frames do

Nothing below assumes a journal.  `externalCallBindTo` is the only thing that
touches `ContractState.calls`, and these lemmas read the entries back off it. -/

theorem val_lt (x : Uint256) : x.val < uint256Modulus := x.isLt

theorem le_allocSum : ∀ {l : List Nat} {a : Nat}, a ∈ l → a ≤ allocSum l := by
  intro l
  induction l with
  | nil => intro a h; cases h
  | cons b rest ih =>
      intro a h
      rcases List.mem_cons.mp h with rfl | h'
      · simp [allocSum]
      · have := ih h'
        simp [allocSum]
        omega

theorem beaconStub : externalCallStubSuccess "makeBeaconChainTopUp" = true := by decide

theorem lidoStub : externalCallStubSuccess "withdrawDepositableEther" = true := by decide

/-- One value-bearing frame: the balance check passes, `selfBalance` is debited
by exactly the allocation, and the frame appends exactly `pushEntry`. -/
theorem beaconPush_run (index amount : Nat) (state : ContractState)
    (hle : ((amount : Uint256)) ≤ state.selfBalance) :
    beaconPush index amount state =
      ContractResult.success () { state with
        selfBalance := state.selfBalance - (amount : Uint256),
        calls := state.calls ++ [pushEntry (index, amount)] } := by
  simp [beaconPush, externalCallBindTo, hle, beaconStub, pushEntry, linkedCallEntryTo,
    linkedCallEntry, ExternalArg.toWords]

/-- The zero-value pull frame always passes the balance check and appends
exactly `pullEntry`. -/
theorem lidoPull_run (total : Nat) (state : ContractState) :
    lidoPull total state =
      ContractResult.success () { state with
        selfBalance := state.selfBalance - (0 : Uint256),
        calls := state.calls ++ [pullEntry total] } := by
  have hle : ((0 : Uint256)) ≤ state.selfBalance := by
    show (0 : Uint256).val ≤ state.selfBalance.val
    simp
  simp [lidoPull, externalCallBindTo, hle, lidoStub, pullEntry, linkedCallEntryTo,
    linkedCallEntry, ExternalArg.toWords]

/-- The push loop's journal is *derived*: each iteration's entry comes out of
`externalCallBindTo`, and the aggregate is exactly `beaconJournal`.  The only
hypothesis is that the router really holds the wei it is about to send, which is
what `creditPull` establishes. -/
theorem pushLoop_run (l : List Nat) :
    ∀ (index : Nat) (state : ContractState),
      allocSum l ≤ state.selfBalance.val →
      pushLoop false l index state =
        ContractResult.success () { state with
          selfBalance := ((state.selfBalance.val - allocSum l : Nat) : Uint256),
          calls := state.calls ++ beaconJournal l index } := by
  induction l with
  | nil =>
      intro index state _
      simp [pushLoop, beaconJournal, sourcePushes, allocSum, _root_.Verity.pure, ofNat_val]
  | cons a rest ih =>
      intro index state hbal
      have hsplit : allocSum (a :: rest) = a + allocSum rest := rfl
      by_cases ha : a = 0
      · subst ha
        rw [pushLoop, if_pos rfl, ih (index + 1) state (by omega)]
        simp [beaconJournal, sourcePushes, allocSum]
      · have haLe : a ≤ state.selfBalance.val := by omega
        have haLt : a < uint256Modulus :=
          Nat.lt_of_le_of_lt haLe (val_lt state.selfBalance)
        have hval : ((a : Uint256)).val = a := word_val haLt
        have hle : ((a : Uint256)) ≤ state.selfBalance := by
          show ((a : Uint256)).val ≤ state.selfBalance.val
          omega
        have hnext : (state.selfBalance - (a : Uint256)).val = state.selfBalance.val - a := by
          rw [Verity.Core.Uint256.sub_eq_of_le (by omega), hval]
        rw [pushLoop, if_neg ha]
        simp only [Bind.bind, _root_.Verity.bind, beaconPush_run index a state hle]
        simp only [Bool.not_false, _root_.Verity.require, if_pos]
        rw [ih (index + 1) _ (by simp only [hnext]; omega)]
        have hbal2 : (state.selfBalance - (a : Uint256)).val - allocSum rest
            = state.selfBalance.val - allocSum (a :: rest) := by
          rw [hnext, hsplit]; omega
        have hjournal : beaconJournal (a :: rest) index
            = pushEntry (index, a) :: beaconJournal rest (index + 1) := by
          simp [beaconJournal, sourcePushes, ha]
        simp [hbal2, hjournal]

/-! ## Running the transaction -/

theorem cellsOf_writeSlot (state : ContractState) (wordSlot : Nat) (value : Uint256)
    (index count : Nat) :
    cellsOf (state.writeSlot wordSlot value) index count = cellsOf state index count := by
  simp [cellsOf, readMapUint_writeSlot]

theorem cellsOf_frame (state : ContractState) (balance : Uint256)
    (journal : List ExternalCall) (index count : Nat) :
    cellsOf { state with selfBalance := balance, calls := journal } index count
      = cellsOf state index count := rfl

theorem execute_run_zero (allocations : List Nat) (state : ContractState)
    (hZero : allocSumUnchecked allocations = 0) :
    (execute allocations .none).run state = ContractResult.success ()
      ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0) := by
  simp [execute, Contract.run, allocationStage, Bind.bind, _root_.Verity.bind,
    _root_.Verity.pure, _root_.Verity.require, hZero]

/-- The push loop spends exactly the balance the Lido pull credited, so the
contract ends the batch holding nothing.  This is the executable counterpart
of the `assert(address(this).balance == 0)` at the end of the Solidity
top-up. -/
theorem pushLoop_run_exact (l : List Nat) (index : Nat) (st : ContractState)
    (h : st.selfBalance.val = allocSum l) :
    pushLoop false l index st = ContractResult.success ()
      { st with selfBalance := 0, calls := st.calls ++ beaconJournal l index } := by
  rw [pushLoop_run l index st (Nat.le_of_eq h.symm), h, Nat.sub_self]
  rfl

theorem pushStage_run (l : List Nat) (st : ContractState)
    (hbal : st.selfBalance = 0) (hNoWrap : allocSum l < uint256Modulus) :
    pushStage l (allocSum l) .none st = ContractResult.success ()
      { st.writeSlot pulledTotalSlot ((allocSum l : Nat) : Uint256) with
        selfBalance := 0
        calls := st.calls ++ (pullEntry (allocSum l) :: beaconJournal l 0) } := by
  have hcredited :
      ((st.selfBalance - (0 : Uint256)) + ((allocSum l : Nat) : Uint256)).val = allocSum l := by
    rw [hbal, Verity.Core.Uint256.sub_zero, Verity.Core.Uint256.zero_add]
    exact word_val hNoWrap
  simp only [pushStage, Bind.bind, _root_.Verity.bind, lidoPull_run, creditPull,
    _root_.Verity.require, ne_eq, reduceCtorEq, not_false_eq_true, decide_true, if_true,
    decide_false]
  rw [pushLoop_run_exact l 0 _ hcredited]
  show ContractResult.success ()
      { st.writeSlot pulledTotalSlot ((allocSum l : Nat) : Uint256) with
        selfBalance := 0
        calls := (st.calls ++ [pullEntry (allocSum l)]) ++ beaconJournal l 0 } = _
  rw [List.append_assoc]
  rfl

theorem execute_run_nonzero (allocations : List Nat) (state : ContractState)
    (hBalance : state.selfBalance = 0)
    (hNoWrap : allocSum allocations < uint256Modulus)
    (hNz : allocSum allocations ≠ 0) :
    (execute allocations .none).run state = ContractResult.success ()
      { ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0).writeSlot
            pulledTotalSlot ((allocSum allocations : Nat) : Uint256) with
        selfBalance := 0
        calls := state.calls ++ expectedCalls allocations } := by
  have hEq : allocSumUnchecked allocations = allocSum allocations :=
    allocSumUnchecked_eq_allocSum hNoWrap
  have hNzW : allocSumUnchecked allocations ≠ 0 := by rw [hEq]; exact hNz
  have hstagedBal :
      ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0).selfBalance = 0 := by
    show (allocationPass allocations 0 0 state).selfBalance = 0
    rw [allocationPass_selfBalance, hBalance]
  have hstagedCalls :
      ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0).calls = state.calls :=
    allocationPass_calls _ _ _ _
  simp only [execute, Contract.run, allocationStage, Bind.bind, _root_.Verity.bind,
    _root_.Verity.require, ne_eq, reduceCtorEq, not_false_eq_true, decide_true,
    if_true, hNzW, if_false]
  rw [hEq, pushStage_run allocations _ hstagedBal hNoWrap]
  rw [hstagedCalls, expectedCalls, hEq, if_neg hNz]

/-! ## Journal projections

The four projections below are what a caller sees of each recorded frame.
Everything is `rfl` against `linkedCallEntryTo`, so a misrouted destination, a
corrupted wei value, or a dropped argument word changes the observable. -/

theorem pushEntry_name (p : Nat × Nat) : (pushEntry p).name = "makeBeaconChainTopUp" := rfl
theorem pushEntry_target (p : Nat × Nat) : (pushEntry p).target = beaconAddress.toNat := rfl
theorem pushEntry_value (p : Nat × Nat) : (pushEntry p).value = evmWord p.2 := rfl
theorem pushEntry_calldata (p : Nat × Nat) :
    (pushEntry p).calldata = [evmWord p.1, evmWord p.2] := rfl

theorem pullEntry_name (total : Nat) :
    (pullEntry total).name = "withdrawDepositableEther" := rfl
theorem pullEntry_target (total : Nat) : (pullEntry total).target = lidoAddress.toNat := rfl
theorem pullEntry_value (total : Nat) : (pullEntry total).value = 0 := rfl
theorem pullEntry_calldata (total : Nat) : (pullEntry total).calldata = [evmWord total] := rfl

theorem callValueOf_beaconJournal :
    ∀ (l : List Nat) (index : Nat), (∀ a ∈ l, a < uint256Modulus) →
      callValueOf "makeBeaconChainTopUp" (beaconJournal l index) = allocSum l
  | [], _, _ => rfl
  | a :: rest, index, hmem => by
      have hrest := callValueOf_beaconJournal rest (index + 1)
        (fun x hx => hmem x (List.mem_cons_of_mem _ hx))
      by_cases ha : a = 0
      · subst ha
        rw [beaconJournal, sourcePushes, if_pos rfl, ← beaconJournal, hrest, allocSum,
          Nat.zero_add]
      · have haLt : a < uint256Modulus := hmem a List.mem_cons_self
        rw [beaconJournal, sourcePushes, if_neg ha, List.map_cons, ← beaconJournal,
          callValueOf, hrest, pushEntry_name, pushEntry_value, allocSum]
        simp [evmWord, Nat.mod_eq_of_lt haLt]

theorem beaconJournal_names (l : List Nat) (index : Nat) :
    (beaconJournal l index).map (·.name)
      = (sourcePushes l index).map (fun _ => "makeBeaconChainTopUp") := by
  simp [beaconJournal, List.map_map, Function.comp_def, pushEntry_name]

theorem beaconJournal_targets (l : List Nat) (index : Nat) :
    (beaconJournal l index).map (·.target)
      = (sourcePushes l index).map (fun _ => beaconAddress.toNat) := by
  simp [beaconJournal, List.map_map, Function.comp_def, pushEntry_target]

theorem beaconJournal_values (l : List Nat) (index : Nat) :
    (beaconJournal l index).map (·.value)
      = (sourcePushes l index).map (fun p => evmWord p.2) := by
  simp [beaconJournal, List.map_map, Function.comp_def, pushEntry_value]

theorem beaconJournal_calldata (l : List Nat) (index : Nat) :
    (beaconJournal l index).map (·.calldata)
      = (sourcePushes l index).map (fun p => [evmWord p.1, evmWord p.2]) := by
  simp [beaconJournal, List.map_map, Function.comp_def, pushEntry_calldata]

/-! ## Composed correspondence -/

theorem readSlot_frame (state : ContractState) (balance : Uint256)
    (journal : List ExternalCall) (wordSlot : Nat) :
    ({ state with selfBalance := balance, calls := journal } : ContractState).readSlot wordSlot
      = state.readSlot wordSlot := rfl

/-- The executable Verity transaction, run through `Contract.run`, produces
exactly the observables the pinned Solidity top-up prescribes: the
per-allocation mapping words, both aggregate slots, and the external-call
journal down to destination address, wei value, argument words, and order. -/
theorem execute_observes_source (allocations : List Nat) (state : ContractState)
    (hBalance : state.selfBalance = 0)
    (hNoWrap : allocSum allocations < uint256Modulus)
    (hLen : allocations.length ≤ uint256Modulus) :
    observe state allocations.length ((execute allocations .none).run state)
      = sourceObservables allocations := by
  have hAmt : ∀ a ∈ allocations, a < uint256Modulus := fun a ha =>
    Nat.lt_of_le_of_lt (le_allocSum ha) hNoWrap
  have hOther : allocationTotalSlot ≠ pulledTotalSlot := by decide
  have hcells : cellsOf (allocationPass allocations 0 0 state) 0 allocations.length = allocations :=
    cellsOf_allocationPass allocations 0 state hLen hAmt
  have htotal : ((allocationPass allocations 0 0 state).readSlot allocationTotalSlot).val
      = allocSum allocations := by
    rw [allocationPass_total, Nat.zero_add]
    exact word_val hNoWrap
  have hEq : allocSumUnchecked allocations = allocSum allocations :=
    allocSumUnchecked_eq_allocSum hNoWrap
  have hcalls : ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0).calls
      = state.calls := allocationPass_calls _ _ _ _
  by_cases hZero : allocSum allocations = 0
  · have hZeroW : allocSumUnchecked allocations = 0 := by rw [hEq]; exact hZero
    rw [execute_run_zero allocations state hZeroW]
    simp only [observe, sourceObservables, cellsOf_writeSlot, hcells,
      ContractState.readSlot_writeSlot_other _ hOther, htotal, hcalls, hEq, hZero,
      ContractState.readSlot_writeSlot_same, Verity.Core.Uint256.val_zero,
      List.drop_length, callValueOf, if_true, List.map_nil]
  · have hNzW : allocSumUnchecked allocations ≠ 0 := by rw [hEq]; exact hZero
    rw [execute_run_nonzero allocations state hBalance hNoWrap hZero]
    simp only [observe, sourceObservables, cellsOf_frame, cellsOf_writeSlot, hcells,
      readSlot_frame, ContractState.readSlot_writeSlot_same,
      ContractState.readSlot_writeSlot_other _ hOther,
      htotal, word_val hNoWrap, List.drop_left, expectedCalls, hEq, if_neg hZero,
      List.map_cons, pullEntry_name, pullEntry_target, pullEntry_value, pullEntry_calldata,
      beaconJournal_names, beaconJournal_targets, beaconJournal_values, beaconJournal_calldata,
      callValueOf, callValueOf_beaconJournal allocations 0 hAmt]
    simp [evmWord, Nat.mod_eq_of_lt hNoWrap]

/-- Entry frame for the composed guarantee: the router owns no ether of its
own when the batch starts, so `etherBalanceBeforeTopUp` at source line 743 is
zero and every wei the pushes move must come from the Lido pull. -/
def entryFrame (state : ContractState) : ContractState := { state with selfBalance := 0 }

theorem execute_observes_source_from_entry (allocations : List Nat) (state : ContractState)
    (hNoWrap : allocSum allocations < uint256Modulus)
    (hLen : allocations.length ≤ uint256Modulus) :
    observe (entryFrame state) allocations.length
        ((execute allocations .none).run (entryFrame state))
      = sourceObservables allocations :=
  execute_observes_source allocations (entryFrame state) rfl hNoWrap hLen

/-- Wrap-to-zero (and the ordinary zero batch) is an empty success: the
executable transaction writes the allocation cells, stores a wrapped total of
zero, and skips the pull/push. -/
theorem execute_observes_source_wrapped_zero (allocations : List Nat)
    (state : ContractState) (_hBalance : state.selfBalance = 0)
    (hZero : allocSumUnchecked allocations = 0)
    (hLen : allocations.length ≤ uint256Modulus)
    (hAmt : ∀ a ∈ allocations, a < uint256Modulus) :
    observe state allocations.length ((execute allocations .none).run state)
      = sourceObservables allocations := by
  have hOther : allocationTotalSlot ≠ pulledTotalSlot := by decide
  have hcells : cellsOf (allocationPass allocations 0 0 state) 0 allocations.length = allocations :=
    cellsOf_allocationPass allocations 0 state hLen hAmt
  have htotal : ((allocationPass allocations 0 0 state).readSlot allocationTotalSlot).val
      = allocSumUnchecked allocations := by
    rw [allocationPass_total, Nat.zero_add, allocSumUnchecked_eq_mod]
    have hmod : Core.Uint256.modulus = uint256Modulus := by decide
    simp [hmod, Core.Uint256.val_ofNat]
  have hcalls : ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0).calls
      = state.calls := allocationPass_calls _ _ _ _
  rw [execute_run_zero allocations state hZero]
  simp only [observe, sourceObservables, cellsOf_writeSlot, hcells,
    ContractState.readSlot_writeSlot_other _ hOther, htotal, hcalls, hZero,
    ContractState.readSlot_writeSlot_same, Verity.Core.Uint256.val_zero,
    List.drop_length, callValueOf, if_true, List.map_nil]

theorem execute_observes_source_wrapped_zero_from_entry (allocations : List Nat)
    (state : ContractState) (hZero : allocSumUnchecked allocations = 0)
    (hLen : allocations.length ≤ uint256Modulus)
    (hAmt : ∀ a ∈ allocations, a < uint256Modulus) :
    observe (entryFrame state) allocations.length
        ((execute allocations .none).run (entryFrame state))
      = sourceObservables allocations :=
  execute_observes_source_wrapped_zero allocations (entryFrame state) rfl hZero hLen hAmt

/-- The batch spends every wei it pulled: the executable counterpart of the
final `assert(address(this).balance == 0)`. -/
theorem execute_ends_with_zero_balance (allocations : List Nat) (state : ContractState)
    (hBalance : state.selfBalance = 0)
    (hNoWrap : allocSum allocations < uint256Modulus) :
    ∀ after, (execute allocations .none).run state = ContractResult.success () after →
      after.selfBalance = 0 := by
  intro after h
  by_cases hZero : allocSum allocations = 0
  · have hZeroW : allocSumUnchecked allocations = 0 :=
      (allocSumUnchecked_eq_allocSum hNoWrap).trans hZero
    rw [execute_run_zero allocations state hZeroW] at h
    injection h with _ hstate
    rw [← hstate]
    show (allocationPass allocations 0 0 state).selfBalance = 0
    rw [allocationPass_selfBalance, hBalance]
  · rw [execute_run_nonzero allocations state hBalance hNoWrap hZero] at h
    injection h with _ hstate
    rw [← hstate]

/-! ## Rollback after real prefix effects

The three injection points are not no-ops: each fires on a state the
transaction has already mutated -- storage words for the first, a journalled
and balance-debited call frame for the other two.  `Contract.run` then
normalizes every one of them back to the entry snapshot. -/

/-- `afterAllocationWrite` fires with every allocation word and the aggregate
already written. -/
theorem revert_after_allocation_write (allocations : List Nat) (state : ContractState) :
    execute allocations .afterAllocationWrite state =
      ContractResult.revert "FAIL_AFTER_ALLOCATION_WRITE"
        ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0) := by
  simp [execute, allocationStage, Bind.bind, _root_.Verity.bind, _root_.Verity.require]

theorem allocation_write_prefix_is_dirty (allocations : List Nat) (state : ContractState)
    (hNoWrap : allocSum allocations < uint256Modulus)
    (hNz : allocSum allocations ≠ 0)
    (hFresh : state.readSlot allocationTotalSlot = 0) :
    ((allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0).readSlot
        allocationTotalSlot ≠ state.readSlot allocationTotalSlot := by
  rw [ContractState.readSlot_writeSlot_other _ (by decide), allocationPass_total, Nat.zero_add,
    hFresh]
  exact fun h => hNz (by rw [← word_val hNoWrap, h]; rfl)

/-- `afterLidoPull` fires with the pull frame already journalled and the
pulled ether already on the balance. -/
theorem revert_after_lido_pull (l : List Nat) (st : ContractState) :
    pushStage l (allocSum l) .afterLidoPull st =
      ContractResult.revert "FAIL_AFTER_LIDO_PULL"
        (({ st with
              selfBalance := st.selfBalance - (0 : Uint256) + ((allocSum l : Nat) : Uint256),
              calls := st.calls ++ [pullEntry (allocSum l)] }).writeSlot
          pulledTotalSlot ((allocSum l : Nat) : Uint256)) := by
  simp [pushStage, Bind.bind, _root_.Verity.bind, lidoPull_run, creditPull,
    _root_.Verity.require]

/-- `afterFirstBeaconPush` fires once the first deposit frame has really
debited the balance and appended its journal entry. -/
theorem revert_after_first_beacon_push (a : Nat) (rest : List Nat) (index : Nat)
    (st : ContractState) (ha : a ≠ 0) (hle : ((a : Uint256)) ≤ st.selfBalance) :
    pushLoop true (a :: rest) index st =
      ContractResult.revert "FAIL_AFTER_FIRST_BEACON_PUSH"
        { st with
          selfBalance := st.selfBalance - (a : Uint256)
          calls := st.calls ++ [pushEntry (index, a)] } := by
  rw [pushLoop, if_neg ha]
  simp [Bind.bind, _root_.Verity.bind, beaconPush_run index a st hle, _root_.Verity.require]

/-- Whatever was mutated, `Contract.run` hands back the entry snapshot. -/
theorem revert_restores_snapshot (allocations : List Nat) (failure : FailurePoint)
    (state rollback : ContractState) (reason : String)
    (h : (execute allocations failure).run state = ContractResult.revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

/-- A failed batch is observationally inert: no allocation words, no aggregate
slots, no external calls. -/
theorem revert_observes_nothing (allocations : List Nat) (failure : FailurePoint)
    (state rollback : ContractState) (reason : String)
    (h : (execute allocations failure).run state = ContractResult.revert reason rollback) :
    observe state allocations.length ((execute allocations failure).run state)
      = ⟨false, [], 0, 0, 0, [], [], [], []⟩ := by
  rw [h]; rfl

end LidoSRv3.Audit.Verity.TopupTx
