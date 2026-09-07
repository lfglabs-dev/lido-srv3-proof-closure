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

/-! ## StakingRouter.topUp (StakingRouter.sol:679-759), split at the module call -/

/-- Guards executed before the allocation-module call at `StakingRouter.sol:717-718`.

This is NOT `_validateTopUpInputs` alone. Its guards come from five origins, in
source order: `StakingRouter.sol:686` (`_checkAppAuth`), `:769-781` (the three
`_validateTopUpInputs` guards, reached from `:687`), `:689/691/694` (module
existence, status and WC type), `:706` (the gwei modulus totality guard), and
`:713-715` (paused Lido on the zero-allocation path). It is the prefix of
`SolidityTopup.run` up to, but excluding, the module call. -/
def preAllocation (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Option Outcome :=
  -- StakingRouter.sol:686  _checkAppAuth(_getTopUpGateway());
  if inp.callerIsTopUpGateway = false then some .revertNotAuthorized
  -- StakingRouter.sol:769-771  if (n == 0) { revert EmptyKeysList(); }  [_validateTopUpInputs]
  else if inp.keyIndicesLength = 0 then some .revertEmptyKeysList
  -- StakingRouter.sol:773-775  if (_operatorIds.length != n || ...) { revert ArraysLengthMismatch(); }  [_validateTopUpInputs]
  else if inp.operatorIdsLength != inp.keyIndicesLength
      || inp.topUpLimits.length != inp.keyIndicesLength
      || inp.pubkeyLengths.length != inp.keyIndicesLength then
    some .revertArraysLengthMismatch
  -- StakingRouter.sol:777-781  if (_pubkeys[i].length != PUBKEY_LENGTH) { revert WrongPubkeyLength(); }  [_validateTopUpInputs]
  else if inp.pubkeyLengths.any (fun length => length != cfg.pubkeyLength) then
    some .revertWrongPubkeyLength
  -- StakingRouter.sol:689  _getModuleState(_stakingModuleId)  (revert StakingModuleUnregistered, SRUtils.sol:46)
  else if inp.moduleExists = false then some .revertStakingModuleUnregistered
  -- StakingRouter.sol:691  if (stateConfig.status != StakingModuleStatus.Active) revert StakingModuleNotActive();
  else if inp.moduleActive = false then some .revertStakingModuleNotActive
  -- StakingRouter.sol:694  SRUtils._requireWCType2(stateConfig.withdrawalCredentialsType);
  else if inp.wcTypeIsType2 = false then some .revertWrongWithdrawalCredentialsType
  -- StakingRouter.sol:706  smDepositableEthAmount % 1 gwei  (totality guard, dead on chain)
  else if cfg.gwei = 0 then some .revertGweiModuloByZero
  -- StakingRouter.sol:713-715  if (smDepositableEthAmountRounded == 0 && !LIDO.canDeposit()) { revert LidoDepositsPaused(); }
  else if smDepositableEthAmountRounded cfg inp = 0 && inp.lidoCanDeposit = false then
    some .revertLidoDepositsPaused
  else none

/-- The complete path after a successful allocation-module return.

The `unchecked` accumulator at source line 732 is read through
`SolidityTopup.accumulated` (the sum reduced mod `2 ^ 256`), and the router
balance the line 755 `assert` observes through `SolidityTopup.routerBalanceAfter`
-- wave 5 routed the same wrapped reading through `SolidityTopup.run`'s
value-moving tail, so this module no longer keeps a separate copy. -/
def afterAllocation (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (iface : CalleeInterface) : ParentExecution :=
  -- StakingRouter.sol:717-718  allocations = IStakingModuleV2(...).allocateDeposits(...)  (journalled)
  let allocationObs := allocationCall iface
  let allocationCalls := [allocationObs]
  -- StakingRouter.sol:722-734  allocation guard loop
  match allocationLoop cfg inp.allocations inp.topUpLimits with
  | some outcome => sourceRevert allocationCalls outcome
  | none =>
    -- StakingRouter.sol:737-739  if (amount > smDepositableEthAmountRounded) { revert ModuleReturnExceedTarget(); }
    if smDepositableEthAmountRounded cfg inp < accumulated inp then
      sourceRevert allocationCalls .revertModuleReturnExceedTarget
    -- StakingRouter.sol:741  if (amount > 0) {  (else: commit without a pull)
    else if accumulated inp = 0 then
      { calls := allocationCalls, result := .committedNoTopUp }
    else
      -- StakingRouter.sol:744  LIDO.withdrawDepositableEther(amount, 0);  (journalled)
      let pullObs := lidoCall iface
      let pullCalls := allocationCalls ++ [pullObs]
      -- Lido.sol:870  require(canDeposit(), "CAN_NOT_DEPOSIT");
      if inp.lidoCanDeposit = false then sourceRevert pullCalls .revertLidoCannotDeposit
      -- Lido.sol:842  require(_depositAmount <= depositableEther, "NOT_ENOUGH_ETHER");
      else if inp.lidoDepositableEther < accumulated inp then
        sourceRevert pullCalls .revertLidoNotEnoughEther
      -- Added by the model: the callee frame itself may fail.
      else if !callSucceeded iface.lidoPull then
        { calls := pullCalls, result := .reverted .lidoPullCallFailed }
      else
        -- StakingRouter.sol:750  BeaconChainDepositor.makeBeaconChainTopUp(...)  (one journalled call per nonzero amount)
        let depositCalls := beaconCalls inp.allocations iface.beaconPushes
        let pushCalls := pullCalls ++ depositCalls
        -- BeaconChainDepositor.sol:74  if (len != _amount.length) revert ArrayLengthMismatch();
        if inp.pubkeyLengths.length != inp.allocations.length then
          sourceRevert pushCalls .revertArrayLengthMismatch
        -- BeaconChainDepositor.sol:79-107  per-key guard loop
        else match pushLoop cfg inp.pubkeyLengths inp.allocations with
          | some outcome => sourceRevert pushCalls outcome
          | none =>
            -- Added by the model: a deposit-contract frame may fail.
            if iface.beaconPushes.length != positiveCount inp.allocations
                || !allCallsSucceeded depositCalls then
              { calls := pushCalls, result := .reverted .beaconPushCallFailed }
            -- BeaconChainDepositor.sol:106  deposit{value: amount}  (unfunded transfer reverts)
            else if inp.routerBalanceBefore + accumulated inp < pushedValue inp then
              sourceRevert pushCalls .revertInsufficientRouterBalance
            -- StakingRouter.sol:755  assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits);
            else if accumulated inp != pushedValue inp then
              sourceRevert pushCalls .revertAssertBalanceUnchanged
            else
              { calls := pushCalls,
                result := .committedTopUp (accumulated inp) }

/-- `StakingRouter.sol:679-759 topUp(...)` as the parent model: `preAllocation`,
then the module call, then `afterAllocation`. Authentication is derived from the
public caller frame, rather than supplied as an already-decided suffix flag.

Added by the model: `CalleeInterface` responses (call success/failure and
returndata) for the three external calls at `:717-718`, `:744` and `:750`. -/
def sourceExecute (cfg : SourceTopupConfig) (base : SourceTopupInput)
    (gateway caller : Address) (iface : CalleeInterface) : ParentExecution :=
  -- StakingRouter.sol:1177-1179  _checkAppAuth: if (_msgSender() != _appAuth) revert NotAuthorized();
  let authenticated := { base with callerIsTopUpGateway := caller == gateway }
  -- StakingRouter.sol:686-715  guards before the module call
  match preAllocation cfg authenticated with
  | some outcome => sourceRevert [] outcome
  | none =>
    -- StakingRouter.sol:717-718  allocations = ...allocateDeposits(...)  (returndata bound here)
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
the exact Nat sum the push loop sends (`accumulated ≠ pushedValue`).  On a
*nonzero* wrap the line-755 assert is therefore live.  Wrap-to-zero is
different: `accumulated = 0` takes the line-741 empty commit and never reaches
the assert (`wrap_to_zero_commits_no_topup` on the routed `run`).  This lemma
is only the two-sum disagreement, not wrap-implies-revert.

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
  have hPos : 0 < uint256Modulus := by decide
  have hLt : allocSum inp.allocations % uint256Modulus < allocSum inp.allocations :=
    Nat.lt_of_lt_of_le (Nat.mod_lt _ hPos) hGe
  have hNe : allocSumUnchecked inp.allocations ≠ allocSum inp.allocations := by omega
  have hPushed : pushedValue inp = totalAllocated inp :=
    loopPushed_eq_allocSum _ _ hLen
  simp only [accumulated, totalAllocated] at *
  omega

end LidoSRv3.Audit.SolidityTopupParent
