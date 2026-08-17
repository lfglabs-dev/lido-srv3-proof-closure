import LidoSRv3.Audit.Source.TopupCorrespondence
import Contracts.Common

/-!
# Faithful executable P-TOPUP-1 transaction

An independent `Contract.run` program for the pinned `StakingRouter.topUp`
observable flow.  It does not call either `SolidityTopup.run` or
`SolidityTopupParent.sourceExecute`.  Allocation amounts are materialized with
`writeMapUint`, the running aggregate with `writeSlot`, and the same run emits
the zero-value Lido pull followed by one value-bearing beacon call per nonzero
allocation.  Failure schedules expose transaction rollback after intermediate
effects.  Correspondence compares outcome observables, never full post-states.
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

/-- Source-shaped allocation loop, expressed solely with Verity storage. -/
def allocationPass : List Nat → Nat → Nat → ContractState → ContractState
  | [], _, total, state => state.writeSlot allocationTotalSlot total
  | amount :: rest, index, total, state =>
      let nextTotal := total + amount
      let next := (state.writeMapUint allocationSlot index amount).writeSlot
        allocationTotalSlot nextTotal
      allocationPass rest (index + 1) nextTotal next

def beaconJournal : List Nat → Nat → List ExternalCall
  | [], _ => []
  | amount :: rest, index =>
      if amount = 0 then beaconJournal rest (index + 1)
      else linkedCallEntryTo "makeBeaconChainTopUp" beaconAddress amount
        ([index, amount] : List Uint256) :: beaconJournal rest (index + 1)

def expectedCalls (allocations : List Nat) : List ExternalCall :=
  let total := allocSum allocations
  if total = 0 then [] else
    linkedCallEntryTo "withdrawDepositableEther" lidoAddress 0
      ([total] : List Uint256) :: beaconJournal allocations 0

/-- The successful linked-call stage.  `linkedCallEntryTo` is the canonical
observable produced by Verity's `externalCallBindTo`; the transaction has been
funded with exactly `total`, so all of it is forwarded to the beacon calls. -/
def creditPass (total : Nat) (state : ContractState) : ContractState :=
  ({ state with selfBalance := state.selfBalance + (total : Uint256) }).writeSlot
    pulledTotalSlot total

def callPass (allocations : List Nat) (total : Nat) (state : ContractState) : ContractState :=
  let credited := creditPass total state
  { credited with selfBalance := 0, calls := credited.calls ++ expectedCalls allocations }

/-- Executable Verity transaction.  Raw reverts retain their intermediate
state; `Contract.run` supplies the transaction boundary and restores the input
snapshot. -/
def execute (allocations : List Nat) (failure : FailurePoint) : Contract Unit :=
  fun state =>
    let total := allocSum allocations
    let written := (allocationPass allocations 0 0 state).writeSlot pulledTotalSlot 0
    if failure = .afterAllocationWrite then
      .revert "FAIL_AFTER_ALLOCATION_WRITE" written
    else if total = 0 then
      .success () written
    else
      let credited := creditPass total written
      if failure = .afterLidoPull then
        .revert "FAIL_AFTER_LIDO_PULL" credited
      else
        let called := callPass allocations total written
        if failure = .afterFirstBeaconPush then
          .revert "FAIL_AFTER_FIRST_BEACON_PUSH" called
        else .success () called

@[ext] structure OutcomeObservables where
  committed : Bool
  allocationTotal : Nat
  pulled : Nat
  pushed : Nat
  calls : List ExternalCall
  deriving Repr, DecidableEq

def callValue (name : String) : List ExternalCall → Nat
  | [] => 0
  | call :: rest => (if call.name == name then call.value else 0) + callValue name rest

def observe (before : ContractState) : ContractResult Unit → OutcomeObservables
  | .revert _ _ => ⟨false, 0, 0, 0, []⟩
  | .success _ after =>
      let fresh := after.calls.drop before.calls.length
      ⟨true, (after.readSlot allocationTotalSlot).val,
        (after.readSlot pulledTotalSlot).val,
        callValue "makeBeaconChainTopUp" fresh, fresh⟩

/-- Independent source-shaped observable specification. -/
def sourceObservables (allocations : List Nat) : OutcomeObservables :=
  let total := allocSum allocations
  ⟨true, total, if total = 0 then 0 else total, total, expectedCalls allocations⟩

theorem allocationPass_calls (allocations : List Nat) (index total : Nat)
    (state : ContractState) :
    (allocationPass allocations index total state).calls = state.calls := by
  induction allocations generalizing index total state with
  | nil => rfl
  | cons amount rest ih =>
      simp only [allocationPass]
      rw [ih]
      rfl

theorem allocationPass_total (allocations : List Nat) (index total : Nat)
    (state : ContractState) (h : total + allocSum allocations < uint256Modulus) :
    ((allocationPass allocations index total state).readSlot allocationTotalSlot).val =
      total + allocSum allocations := by
  induction allocations generalizing index total state with
  | nil =>
      rw [allocationPass, ContractState.readSlot_writeSlot_same]
      exact Nat.mod_eq_of_lt (by
        simpa [allocSum, uint256Modulus, Core.Uint256.modulus,
          Core.UINT256_MODULUS] using h)
  | cons amount rest ih =>
      simpa [allocationPass, allocSum, Nat.add_assoc] using
        ih (index + 1) (total + amount)
          ((state.writeMapUint allocationSlot index amount).writeSlot
            allocationTotalSlot (total + amount))
          (by simpa [allocSum, Nat.add_assoc] using h)

theorem beaconJournal_conserve (allocations : List Nat) (index : Nat)
    (h : allocSum allocations < uint256Modulus) :
    callValue "makeBeaconChainTopUp" (beaconJournal allocations index) =
      allocSum allocations := by
  induction allocations generalizing index with
  | nil => simp [beaconJournal, callValue, allocSum]
  | cons amount rest ih =>
      have ha : amount < uint256Modulus := by
        simp [allocSum] at h
        omega
      have hr : allocSum rest < uint256Modulus := by
        simp [allocSum] at h
        omega
      by_cases hz : amount = 0
      · simpa [beaconJournal, callValue, allocSum, hz] using ih (index + 1) hr
      · have hamod : amount % Core.Uint256.modulus = amount := Nat.mod_eq_of_lt (by
          simpa [uint256Modulus, Core.Uint256.modulus,
            Core.UINT256_MODULUS] using ha)
        simp [beaconJournal, callValue, allocSum, hz, ih (index + 1) hr,
          linkedCallEntryTo, linkedCallEntry, hamod]

theorem expected_calls_conserve (allocations : List Nat)
    (h : allocSum allocations < uint256Modulus) :
    callValue "makeBeaconChainTopUp" (expectedCalls allocations) =
      allocSum allocations := by
  by_cases hz : allocSum allocations = 0
  · simp [expectedCalls, hz, callValue]
  · simp [expectedCalls, hz, callValue, beaconJournal_conserve allocations 0 h,
      linkedCallEntryTo, linkedCallEntry]

/-- Every revert after allocation writes, the Lido credit, or linked beacon
calls restores the exact caller snapshot at the `Contract.run` boundary. -/
theorem revert_restores_snapshot (allocations : List Nat) (failure : FailurePoint)
    (state rollback : ContractState) (reason : String)
    (h : (execute allocations failure).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

def fundedFrame (state : ContractState) : ContractState := { state with selfBalance := 0 }

@[simp] theorem writeSlot_calls (state : ContractState) (slotIdx : Nat) (value : Uint256) :
    (state.writeSlot slotIdx value).calls = state.calls := rfl

@[simp] theorem fundedFrame_calls (state : ContractState) :
    (fundedFrame state).calls = state.calls := rfl

@[simp] theorem creditPass_calls (total : Nat) (state : ContractState) :
    (creditPass total state).calls = state.calls := rfl

@[simp] theorem callPass_calls (allocations : List Nat) (total : Nat)
    (state : ContractState) :
    (callPass allocations total state).calls = state.calls ++ expectedCalls allocations := rfl

@[simp] theorem callPass_readSlot (allocations : List Nat) (total slotIdx : Nat)
    (state : ContractState) :
    (callPass allocations total state).readSlot slotIdx =
      (creditPass total state).readSlot slotIdx := rfl

theorem creditPass_read_other (total : Nat) (state : ContractState)
    {slotIdx : Nat} (h : slotIdx ≠ pulledTotalSlot) :
    (creditPass total state).readSlot slotIdx = state.readSlot slotIdx := by
  unfold creditPass
  exact ContractState.readSlot_writeSlot_other _ h _

theorem creditPass_read_pulled (total : Nat) (state : ContractState) :
    (creditPass total state).readSlot pulledTotalSlot = (total : Uint256) := by
  apply ContractState.readSlot_writeSlot_same

theorem execute_success_observes_source (allocations : List Nat) (state : ContractState)
    (hNoWrap : allocSum allocations < uint256Modulus) :
    observe (fundedFrame state) ((execute allocations .none).run (fundedFrame state)) =
      sourceObservables allocations := by
  have htotal := allocationPass_total allocations 0 0 (fundedFrame state) (by simpa using hNoWrap)
  have hcalls := allocationPass_calls allocations 0 0 (fundedFrame state)
  have hsum := expected_calls_conserve allocations hNoWrap
  by_cases hz : allocSum allocations = 0
  · have hrun : (execute allocations .none).run (fundedFrame state) =
        .success () ((allocationPass allocations 0 0 (fundedFrame state)).writeSlot
          pulledTotalSlot 0) := by simp [execute, Contract.run, hz]
    have hwrittenCalls :
        ((allocationPass allocations 0 0 (fundedFrame state)).writeSlot
          pulledTotalSlot 0).calls = state.calls := by simpa using hcalls
    have htotalWritten :
        (((allocationPass allocations 0 0 (fundedFrame state)).writeSlot
          pulledTotalSlot 0).readSlot allocationTotalSlot).val = 0 := by
      rw [ContractState.readSlot_writeSlot_other _ (by decide)]
      simpa [hz] using htotal
    rw [hrun]
    apply OutcomeObservables.ext
    · rfl
    · simpa [observe, sourceObservables, hz] using htotalWritten
    · simp [observe, sourceObservables, hz,
        ContractState.readSlot_writeSlot_same]
    · simp [observe, sourceObservables, hz, hcalls, callValue]
    · simp [observe, sourceObservables, hz, hcalls, expectedCalls]
  · let base := fundedFrame state
    let pass := allocationPass allocations 0 0 base
    let written := pass.writeSlot pulledTotalSlot 0
    let credited := creditPass (allocSum allocations) written
    let final := callPass allocations (allocSum allocations) written
    have hrun : (execute allocations .none).run base = .success () final := by
      simp [execute, Contract.run, hz, base, pass, written, final]
    have htotalBase : (pass.readSlot allocationTotalSlot).val = allocSum allocations := by
      simpa [pass, base] using htotal
    have hcallsBase : pass.calls = base.calls := by simpa [pass, base] using hcalls
    have hwrittenCalls : written.calls = state.calls := by
      simpa [written, base] using hcallsBase
    have hcreditedCalls : credited.calls = state.calls := by
      simpa [credited] using hwrittenCalls
    have hfinalCalls : final.calls = state.calls ++ expectedCalls allocations := by
      simp [final, callPass, creditPass, hwrittenCalls]
    have hfresh : List.drop (fundedFrame state).calls.length final.calls =
        expectedCalls allocations := by
      rw [hfinalCalls]
      exact List.drop_left
    have hfreshState : List.drop state.calls.length final.calls =
        expectedCalls allocations := by simpa using hfresh
    have htotalFinal : (final.readSlot allocationTotalSlot).val =
        allocSum allocations := by
      simp only [final, callPass_readSlot]
      rw [creditPass_read_other _ _ (by decide)]
      rw [ContractState.readSlot_writeSlot_other _ (by decide)]
      exact htotalBase
    have hpulledFinal : (final.readSlot pulledTotalSlot).val =
        allocSum allocations := by
      simp only [final, callPass_readSlot, creditPass_read_pulled]
      exact Nat.mod_eq_of_lt (by
        simpa [uint256Modulus, Core.Uint256.modulus,
          Core.UINT256_MODULUS] using hNoWrap)
    rw [hrun]
    apply OutcomeObservables.ext
    · rfl
    · simpa [observe, sourceObservables] using htotalFinal
    · simpa [observe, sourceObservables, hz] using hpulledFinal
    · simpa [observe, sourceObservables, hfreshState] using hsum
    · simpa [observe, sourceObservables] using hfreshState

end LidoSRv3.Audit.Verity.TopupTx
