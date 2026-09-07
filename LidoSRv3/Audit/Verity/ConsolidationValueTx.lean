import LidoSRv3.Audit.Source.ConsolidationCorrespondence
import Contracts.Common

/-!
# Consolidation value-bearing request transaction

This is a justified executable interpreter for the successful
`WithdrawalVault.addConsolidationRequests` request loop.  Guard evaluation is
delegated to the independently pinned `sourceRun`; only its committed arm enters
the loop.  Every request is then executed by `externalCallBindTo`, so the
interpreter itself debits the vault and produces the call journal.

This module does not use or claim success of the official `denoteFunction`
interpreter.  It does not model a consensus-layer verification call, gateway
quota/delay logic, or the Bus.
-/

namespace LidoSRv3.Audit.Verity.ConsolidationValueTx

open _root_.Verity
open _root_.Contracts
open LidoSRv3.Audit.SolidityConsolidation

abbrev Word := Verity.Core.Uint256

def requestCallName : String := "addConsolidationRequest"

def requestAddress (call : CallObs) : Address :=
  Verity.Core.Address.ofNat call.target.val

def requestEntry (call : CallObs) : ExternalCall :=
  linkedCallEntryTo requestCallName (requestAddress call) call.value call.input

/-- `WithdrawalVaultEIP7685.sol:115  (bool success,) = CONSOLIDATION_REQUEST.call{value: fee}(request);`
[_callAddConsolidationRequest]. One real caller-side request frame.  The
nonzero value is taken from the committed source observation, where it is
the fee for this request. -/
def requestFrame (call : CallObs) : Contract Unit :=
  externalCallBindTo (requestAddress call) call.value [] requestCallName call.input

/-- Execute all committed request calls in source order. -/
def forwardCalls : List CallObs → Contract Unit
  | [] => Verity.pure ()
  | call :: rest => do
      requestFrame call
      forwardCalls rest

/-- Closed-form state transformer used to state the reduction of
`forwardCalls`.  Its steps are exactly the successful states produced by
`externalCallBindTo`. -/
def afterCall (call : CallObs) (state : ContractState) : ContractState :=
  { state with
    selfBalance := state.selfBalance - call.value
    calls := state.calls ++ [requestEntry call] }

def afterCalls : List CallObs → ContractState → ContractState
  | [], state => state
  | call :: rest, state => afterCalls rest (afterCall call state)

def callValueSum (calls : List CallObs) : Nat :=
  (calls.map fun call => call.value.val).sum

def freshCalls (before after : ContractState) : List ExternalCall :=
  after.calls.drop before.calls.length

def forwardedValue (before after : ContractState) : Nat :=
  (freshCalls before after |>.map (·.value)).sum

/-- `WithdrawalVault.sol:81-85` modifier `preservesEthBalance`:

```
modifier preservesEthBalance() {
    uint256 balanceBeforeCall = address(this).balance - msg.value;   // 82
    _;                                                               // 83
    assert(address(this).balance == balanceBeforeCall);              // 84
}
```

The modifier's postcondition: after forwarding the incoming `msg.value`,
the vault is back at its balance from before that value arrived. Here
`before` is the state at the top of the body, i.e. after the payable credit,
so `before.selfBalance - before.msgValue` is exactly Solidity's
`balanceBeforeCall` (line 82) and the equality is the `assert` of line 84. -/
def preservesEthBalance (before after : ContractState) : Prop :=
  after.selfBalance = before.selfBalance - before.msgValue

/-- Nat-level statement of a vault balance delta of exactly `-msg.value`. -/
def vaultEthDelta (inputs : Inputs) (before after : ContractState) : Prop :=
  after.selfBalance.val + inputs.msgValue.val = before.selfBalance.val

/-- This parent has only request frames; no consensus-layer verification frame
is performed by the vault interpreter. -/
def noConsensusLayerVerify (before after : ContractState) : Prop :=
  ∀ call ∈ freshCalls before after, call.name = requestCallName

/-! ## WithdrawalVault.addConsolidationRequests (WithdrawalVault.sol:199-208), value plane -/

/-- `WithdrawalVault.sol:199-208 addConsolidationRequests`, value plane: the
guards are `SolidityConsolidation.sourceRun` (see its header for the line
map) and the loop `WithdrawalVaultEIP7685.sol:68-72` is `forwardCalls`, one
`externalCallBindTo` per `CONSOLIDATION_REQUEST.call{value: fee}(request)`
(line 115).

Not transcribed: the `preservesEthBalance` modifier as a statement (it is
the predicate `preservesEthBalance` above, proved on the executed plane by
`ConsolidationTx.committed_preserves_eth_balance`); the event (120).

The guarded justified interpreter.  A source revert is a transaction
revert.  A source commit supplies the value-bearing request schedule. -/
def execute (inputs : Inputs) : Contract Unit := fun snapshot =>
  match sourceRun inputs with
  | .reverted reason => .revert reason snapshot
  | .committed obs => forwardCalls obs.calls snapshot

/-- Solidity-facing name, `WithdrawalVault.sol:199`. -/
abbrev addConsolidationRequests := execute

/-- Kill-line mutant (not source). Mutant interpreter: it retains the exact same committed guard result and
request payloads, but replaces every request value with zero. -/
def zeroValueCall (call : CallObs) : CallObs :=
  { call with value := 0 }

def executeZeroValueMutant (inputs : Inputs) : Contract Unit := fun snapshot =>
  match sourceRun inputs with
  | .reverted reason => .revert reason snapshot
  | .committed obs => forwardCalls (obs.calls.map zeroValueCall) snapshot

theorem uintWords (args : List Word) :
    args.flatMap ExternalArg.toWords = args := by
  induction args with
  | nil => rfl
  | cons _ rest ih =>
      rw [List.flatMap_cons, ih]
      rfl

theorem requestFrame_apply (call : CallObs) (state : ContractState)
    (hFunds : call.value ≤ state.selfBalance) :
    requestFrame call state = .success () (afterCall call state) := by
  simp [requestFrame, afterCall, requestEntry, requestAddress,
    externalCallBindTo, requestCallName, hFunds, externalCallStubSuccess,
    uintWords]

theorem afterCall_balance_val (call : CallObs) (state : ContractState)
    (hFunds : call.value.val ≤ state.selfBalance.val) :
    (afterCall call state).selfBalance.val =
      state.selfBalance.val - call.value.val := by
  exact Verity.Core.Uint256.sub_eq_of_le hFunds

theorem afterCalls_calls (calls : List CallObs) (state : ContractState) :
    (afterCalls calls state).calls = state.calls ++ calls.map requestEntry := by
  induction calls generalizing state with
  | nil => simp [afterCalls]
  | cons call rest ih =>
      rw [afterCalls, ih]
      simp [afterCall, List.append_assoc]

theorem afterCalls_balance_val (calls : List CallObs) (state : ContractState)
    (hFunds : callValueSum calls ≤ state.selfBalance.val) :
    (afterCalls calls state).selfBalance.val =
      state.selfBalance.val - callValueSum calls := by
  induction calls generalizing state with
  | nil => simp [afterCalls, callValueSum]
  | cons call rest ih =>
      have hCall : call.value.val ≤ state.selfBalance.val := by
        simpa [callValueSum] using
          Nat.le_trans (Nat.le_add_right call.value.val (callValueSum rest)) hFunds
      have hRest :
          callValueSum rest ≤ (afterCall call state).selfBalance.val := by
        rw [afterCall_balance_val call state hCall]
        simpa [callValueSum, Nat.add_comm] using
          (Nat.le_sub_of_add_le (by simpa [callValueSum, Nat.add_comm] using hFunds))
      rw [afterCalls, ih (afterCall call state) hRest,
        afterCall_balance_val call state hCall]
      simp only [callValueSum, List.map_cons, List.sum_cons]
      omega

theorem forwardCalls_apply (calls : List CallObs) (state : ContractState)
    (hFunds : callValueSum calls ≤ state.selfBalance.val) :
    forwardCalls calls state = .success () (afterCalls calls state) := by
  induction calls generalizing state with
  | nil => rfl
  | cons call rest ih =>
      have hCallVal : call.value.val ≤ state.selfBalance.val := by
        simpa [callValueSum] using
          Nat.le_trans (Nat.le_add_right call.value.val (callValueSum rest)) hFunds
      have hCall : call.value ≤ state.selfBalance := hCallVal
      have hRest :
          callValueSum rest ≤ (afterCall call state).selfBalance.val := by
        rw [afterCall_balance_val call state hCallVal]
        exact Nat.le_sub_of_add_le (by
          simpa [callValueSum, Nat.add_comm] using hFunds)
      simp only [forwardCalls, Bind.bind, Verity.bind,
        requestFrame_apply call state hCall]
      exact ih (afterCall call state) hRest

theorem forwardCalls_run (calls : List CallObs) (state : ContractState)
    (hFunds : callValueSum calls ≤ state.selfBalance.val) :
    (forwardCalls calls).run state = .success () (afterCalls calls state) := by
  rw [Contract.run, forwardCalls_apply calls state hFunds]

@[simp] theorem requestCall_value_val (target fee : Word) (request : Request) :
    (requestCall target fee request).value.val = fee.val := rfl

theorem requestCalls_value_sum (target fee : Word) (requests : List Request) :
    callValueSum (requests.map (requestCall target fee)) =
      requests.length * fee.val := by
  simp [callValueSum, Function.comp_def]

theorem committed_call_value_sum (inputs : Inputs) (obs : Observables)
    (hRun : sourceRun inputs = .committed obs) :
    callValueSum obs.calls = inputs.msgValue.val := by
  unfold sourceRun at hRun
  split at hRun
  · split at hRun
    · cases hRun
    · split at hRun
      · cases hRun
      · next requests hZip =>
          split at hRun
          · split at hRun
            · split at hRun
              · next hFee =>
                  have hFeeNat :
                      inputs.msgValue.val = requests.length * inputs.fee.val :=
                    beq_iff_eq.mp hFee
                  injection hRun with hObs
                  subst obs
                  rw [show (commitObservables inputs.requestTarget inputs.fee
                    inputs.msgValue requests).calls =
                    requests.map (requestCall inputs.requestTarget inputs.fee) by rfl]
                  rw [requestCalls_value_sum, ← hFeeNat]
              · cases hRun
            · cases hRun
          · cases hRun
  · cases hRun

theorem afterCalls_fresh (calls : List CallObs) (state : ContractState) :
    freshCalls state (afterCalls calls state) = calls.map requestEntry := by
  simp [freshCalls, afterCalls_calls]

@[simp] theorem requestEntry_value (call : CallObs) :
    (requestEntry call).value = call.value.val := rfl

theorem afterCalls_forwardedValue (calls : List CallObs) (state : ContractState) :
    forwardedValue state (afterCalls calls state) = callValueSum calls := by
  rw [forwardedValue, afterCalls_fresh]
  apply congrArg List.sum
  induction calls with
  | nil => rfl
  | cons call rest ih =>
      simp only [List.map_cons]
      change (requestEntry call).value ::
          List.map (fun x => x.value) (List.map requestEntry rest) =
        call.value.val :: List.map (fun call => call.value.val) rest
      rw [requestEntry_value, ih]

theorem afterCalls_noConsensusLayerVerify (calls : List CallObs)
    (state : ContractState) :
    noConsensusLayerVerify state (afterCalls calls state) := by
  intro call hCall
  simp only [afterCalls_fresh, List.mem_map] at hCall
  obtain ⟨sourceCall, _, rfl⟩ := hCall
  rfl

end LidoSRv3.Audit.Verity.ConsolidationValueTx
