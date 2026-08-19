import LidoSRv3.Audit.Source.TopupCorrespondence
import Verity.Core

/-!
# P-TOPUP-1 parent transaction correspondence

This module models the complete public `StakingRouter.topUp` transaction rather
than a suffix selected by an abstract outcome.  The caller is read from the
Verity frame, the module allocation return is an explicit call response, the
unchecked accumulator is reduced modulo `2^256`, and the Lido and beacon calls
retain success/failure, value and returndata observations.

The call interface deliberately cannot replace the caller frame.  Arbitrary
callee effects belong to their own world; the caller continues from the same
`ContractState`, and `Contract.run` restores its exact snapshot on every
reverting result.
-/

namespace LidoSRv3.Audit.SolidityTopupParent

open LidoSRv3.Audit.SolidityTopup
open Verity

inductive CallControl where
  | success
  | failure
  | revert
  deriving Repr, DecidableEq

structure CallResponse where
  control : CallControl
  returndata : List Nat
  deriving Repr, DecidableEq

structure AllocationResponse where
  response : CallResponse
  /-- Dynamic `uint256[]` returned by `allocateDeposits`. -/
  allocations : List Nat
  deriving Repr, DecidableEq

structure CalleeInterface where
  allocation : AllocationResponse
  lidoPull : CallResponse
  /-- One response for each nonzero per-validator deposit call. -/
  beaconPushes : List CallResponse
  deriving Repr, DecidableEq

inductive CallKind where
  | allocation
  | lidoPull
  | beaconPush
  deriving Repr, DecidableEq

structure CallObservation where
  kind : CallKind
  /-- ETH sent by the router at this boundary.  The Lido pull therefore has
  value zero; its returned ETH is recorded by the parent result. -/
  value : Nat
  response : CallResponse
  deriving Repr, DecidableEq

inductive RevertReason where
  | source (outcome : Outcome)
  | allocationCallFailed
  | lidoPullCallFailed
  | beaconPushCallFailed
  deriving Repr, DecidableEq

inductive ParentResult where
  | committedNoTopUp
  /-- A committing parent transaction carries the single conserved amount. -/
  | committedTopUp (amount : Nat)
  | reverted (reason : RevertReason)
  deriving Repr, DecidableEq

structure ParentExecution where
  calls : List CallObservation
  result : ParentResult
  deriving Repr, DecidableEq

def callSucceeded (response : CallResponse) : Bool :=
  response.control == .success

def sourceRevert (calls : List CallObservation) (outcome : Outcome) : ParentExecution :=
  { calls := calls, result := .reverted (.source outcome) }

def allocationCall (iface : CalleeInterface) : CallObservation :=
  { kind := .allocation, value := 0, response := iface.allocation.response }

def lidoCall (iface : CalleeInterface) : CallObservation :=
  { kind := .lidoPull, value := 0, response := iface.lidoPull }

def beaconCall (amount : Nat) (response : CallResponse) : CallObservation :=
  { kind := .beaconPush, value := amount, response := response }

def missingResponse : CallResponse := ⟨.failure, []⟩

/-- The exact deposit-call sequence: zero amounts take the source `continue` and
consume no response; every positive amount carries its own ETH value and
returndata. A short response vector becomes an explicit failed call. -/
def beaconCalls : List Nat -> List CallResponse -> List CallObservation
  | [], _ => []
  | amount :: amounts, responses =>
      if amount = 0 then beaconCalls amounts responses
      else match responses with
        | [] => beaconCall amount missingResponse :: beaconCalls amounts []
        | response :: rest => beaconCall amount response :: beaconCalls amounts rest

def allCallsSucceeded : List CallObservation -> Bool
  | [] => true
  | call :: calls => callSucceeded call.response && allCallsSucceeded calls

def positiveCount (amounts : List Nat) : Nat :=
  (amounts.filter (fun amount => amount != 0)).length

/-- Guards executed before the allocation-module call at source lines 717--718. -/
def preAllocation (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Option Outcome :=
  if inp.callerIsTopUpGateway = false then some .revertNotAuthorized
  else if inp.keyIndicesLength = 0 then some .revertEmptyKeysList
  else if inp.operatorIdsLength != inp.keyIndicesLength
      || inp.topUpLimits.length != inp.keyIndicesLength
      || inp.pubkeyLengths.length != inp.keyIndicesLength then
    some .revertArraysLengthMismatch
  else if inp.pubkeyLengths.any (fun length => length != cfg.pubkeyLength) then
    some .revertWrongPubkeyLength
  else if inp.moduleExists = false then some .revertStakingModuleUnregistered
  else if inp.moduleActive = false then some .revertStakingModuleNotActive
  else if inp.wcTypeIsType2 = false then some .revertWrongWithdrawalCredentialsType
  else if cfg.gwei = 0 then some .revertGweiModuloByZero
  else if smDepositableEthAmountRounded cfg inp = 0 && inp.lidoCanDeposit = false then
    some .revertLidoDepositsPaused
  else none

/-- Faithful reading of the `unchecked` accumulator at line 732. -/
def accumulated (inp : SourceTopupInput) : Nat :=
  allocSumUnchecked inp.allocations

def routerBalanceAfterWrapped (inp : SourceTopupInput) : Nat :=
  inp.routerBalanceBefore + accumulated inp - pushedValue inp

/-- The complete path after a successful allocation-module return. -/
def afterAllocation (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (iface : CalleeInterface) : ParentExecution :=
  let allocationObs := allocationCall iface
  let allocationCalls := [allocationObs]
  match allocationLoop cfg inp.allocations inp.topUpLimits with
  | some outcome => sourceRevert allocationCalls outcome
  | none =>
    if smDepositableEthAmountRounded cfg inp < accumulated inp then
      sourceRevert allocationCalls .revertModuleReturnExceedTarget
    else if accumulated inp = 0 then
      { calls := allocationCalls, result := .committedNoTopUp }
    else
      let pullObs := lidoCall iface
      let pullCalls := allocationCalls ++ [pullObs]
      if inp.lidoCanDeposit = false then sourceRevert pullCalls .revertLidoCannotDeposit
      else if inp.lidoDepositableEther < accumulated inp then
        sourceRevert pullCalls .revertLidoNotEnoughEther
      else if !callSucceeded iface.lidoPull then
        { calls := pullCalls, result := .reverted .lidoPullCallFailed }
      else
        let depositCalls := beaconCalls inp.allocations iface.beaconPushes
        let pushCalls := pullCalls ++ depositCalls
        if inp.pubkeyLengths.length != inp.allocations.length then
          sourceRevert pushCalls .revertArrayLengthMismatch
        else match pushLoop cfg inp.pubkeyLengths inp.allocations with
          | some outcome => sourceRevert pushCalls outcome
          | none =>
            if iface.beaconPushes.length != positiveCount inp.allocations
                || !allCallsSucceeded depositCalls then
              { calls := pushCalls, result := .reverted .beaconPushCallFailed }
            else if inp.routerBalanceBefore + accumulated inp < pushedValue inp then
              sourceRevert pushCalls .revertInsufficientRouterBalance
            else if accumulated inp != pushedValue inp then
              sourceRevert pushCalls .revertAssertBalanceUnchanged
            else
              { calls := pushCalls,
                result := .committedTopUp (accumulated inp) }

/-- Pinned-source parent model. Authentication is derived from the public
caller frame, rather than supplied as an already-decided suffix flag. -/
def sourceExecute (cfg : SourceTopupConfig) (base : SourceTopupInput)
    (gateway caller : Address) (iface : CalleeInterface) : ParentExecution :=
  let authenticated := { base with callerIsTopUpGateway := caller == gateway }
  match preAllocation cfg authenticated with
  | some outcome => sourceRevert [] outcome
  | none =>
    let inp := { authenticated with allocations := iface.allocation.allocations }
    if !callSucceeded iface.allocation.response then
      { calls := [allocationCall iface], result := .reverted .allocationCallFailed }
    else afterAllocation cfg inp iface

def ParentResult.reverts : ParentResult -> Bool
  | .reverted _ => true
  | _ => false

def ParentResult.pulled : ParentResult -> Nat
  | .committedTopUp amount => amount
  | _ => 0

def ParentResult.pushed : ParentResult -> Nat
  | .committedTopUp amount => amount
  | _ => 0

theorem committed_conserves (execution : ParentExecution)
    (h : execution.result.reverts = false) :
    execution.result.pulled = execution.result.pushed := by
  cases execution with
  | mk calls result =>
    cases result <;> simp_all [ParentResult.reverts, ParentResult.pulled,
      ParentResult.pushed]

/--
Under a uint256 wrap the on-chain accumulator at source line 732 disagrees with
the exact Nat sum the push loop sends.  Consequently `afterAllocation` reaches
the `assert(etherBalanceBefore == etherBalanceAfter)` at source line 755 and
reverts -- the assert is load-bearing precisely on the wrap branch.

The premise is the *negation* of `NoUncheckedWrap` together with the array-
length agreement that gates the push tail (`BeaconChainDepositor.sol` line 74).
-/
theorem wrap_implies_accumulated_ne_pushed {inp : SourceTopupInput}
    (hWrap : ¬ NoUncheckedWrap inp)
    (hLen : inp.pubkeyLengths.length = inp.allocations.length) :
    accumulated inp ≠ pushedValue inp := by
  have hGe : uint256Modulus ≤ allocSum inp.allocations := Nat.not_lt.mp hWrap
  have hMod : allocSumUnchecked inp.allocations = allocSum inp.allocations % uint256Modulus :=
    allocSumUnchecked_eq_mod inp.allocations
  have hLt : allocSum inp.allocations % uint256Modulus < allocSum inp.allocations :=
    Nat.mod_lt_of_pos_of_le (Nat.pos_of_ne_zero (by omega)) hGe
  have hNe : allocSumUnchecked inp.allocations ≠ allocSum inp.allocations := by omega
  have hPushed : pushedValue inp = totalAllocated inp :=
    (loopPushed_eq_allocSum _ _ hLen).symm
  simp only [accumulated, totalAllocated] at *
  omega

end LidoSRv3.Audit.SolidityTopupParent
