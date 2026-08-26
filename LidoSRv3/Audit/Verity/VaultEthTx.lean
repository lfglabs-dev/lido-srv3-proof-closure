import LidoSRv3.Audit.Source.VaultEthCorrespondence
import Contracts.Common

/-!
# P-VAULT-ETH-1 value-bearing Verity frames

Each successful protocol-return route executes one real caller-side
`externalCallBindTo`.  The frame debits the vault's `selfBalance` and appends
an `ExternalCall` whose target, name, and value are derived from the same
source input.  In particular, neither new Spec constructor is justified by an
address pin or a constructor-only model.

This remains a Verity executable-contract abstraction.  It does not execute
the callee body, identify deployed addresses, update Lido's stored buffered
ether, or model owner-controlled arbitrary-recipient withdrawals.
-/

namespace LidoSRv3.Audit.Verity.VaultEthTx

open _root_.Verity
open _root_.Contracts
open LidoSRv3.Audit.Source.VaultEthCorrespondence

def callName : Route → String
  | .lidoReceiveWithdrawals => "LIDO.receiveWithdrawals"
  | .withdrawalQueueReturn => "WithdrawalQueue.protocolReturn"

def returnEntry (endpoints : Endpoints) (inputs : Inputs) : ExternalCall :=
  linkedCallEntryTo (callName inputs.route)
    (targetOf endpoints inputs.route) inputs.amount []

/-- The value-bearing frame used by both protocol-return constructors. -/
def returnFrame (endpoints : Endpoints) (inputs : Inputs) : Contract Unit :=
  externalCallBindTo (targetOf endpoints inputs.route) inputs.amount []
    (callName inputs.route) ([] : List Word)

def afterFrame (endpoints : Endpoints) (inputs : Inputs)
    (entry : ContractState) : ContractState :=
  { entry with
    selfBalance := entry.selfBalance - inputs.amount
    calls := entry.calls ++ [returnEntry endpoints inputs] }

/-- Only the pinned WithdrawalVault→Lido route evaluates its caller guard
against the executable `msg.sender`.  WithdrawalQueue remains source-shaped. -/
def execute (endpoints : Endpoints) (inputs : Inputs) : Contract Unit := fun entry =>
  match sourceRun endpoints inputs entry with
  | .reverted reason => .revert reason entry
  | .committed _ => returnFrame endpoints inputs entry

def freshCalls (entry after : ContractState) : List ExternalCall :=
  after.calls.drop entry.calls.length

def freshFrameValues (entry after : ContractState) : List Nat :=
  (freshCalls entry after).map (·.value)

theorem callName_ne_fail (route : Route) : callName route ≠ "fail" := by
  cases route <;> decide

theorem returnFrame_apply (endpoints : Endpoints) (inputs : Inputs)
    (entry : ContractState) (hFunds : inputs.amount ≤ entry.selfBalance) :
    returnFrame endpoints inputs entry =
      .success () (afterFrame endpoints inputs entry) := by
  have hName : callName inputs.route ≠ "fail" := callName_ne_fail inputs.route
  simp [returnFrame, afterFrame, returnEntry, externalCallBindTo, hFunds,
    externalCallStubSuccess, hName]

theorem execute_commits_of_preconditions
    (endpoints : Endpoints) (inputs : Inputs) (entry : ContractState)
    (hCaller : callerAuthorized endpoints inputs entry.sender = true)
    (hNonzero : inputs.amount ≠ 0)
    (hFunds : inputs.amount ≤ entry.selfBalance) :
    (execute endpoints inputs).run entry =
      .success () (afterFrame endpoints inputs entry) := by
  rw [Contract.run]
  simp [execute, sourceRun_commits_of_preconditions endpoints inputs entry
    hCaller hNonzero hFunds, returnFrame_apply endpoints inputs entry hFunds]

/-- Any successful executable run came from the source committed arm and has
exactly the state produced by its value-bearing frame. -/
theorem execute_success_corresponds_to_source
    (endpoints : Endpoints) (inputs : Inputs) (entry after : ContractState)
    (hExecute : (execute endpoints inputs).run entry = .success () after) :
    sourceRun endpoints inputs entry =
        .committed (sourceJournal endpoints inputs) ∧
      after = afterFrame endpoints inputs entry := by
  cases hRoute : inputs.route with
  | lidoReceiveWithdrawals =>
    by_cases hCaller : callerAuthorized endpoints inputs entry.sender
    · by_cases hNonzero : inputs.amount = 0
      · have hSource :
            sourceRun endpoints inputs entry =
              .reverted "ZeroAmount" := by
          simp [sourceRun, hCaller, hNonzero]
        simp [execute, hRoute, hSource, Contract.run] at hExecute
      · by_cases hFunds : inputs.amount ≤ entry.selfBalance
        · have hSource :=
            sourceRun_commits_of_preconditions endpoints inputs entry
              hCaller hNonzero hFunds
          refine ⟨hSource, ?_⟩
          have hExpected :=
            execute_commits_of_preconditions endpoints inputs entry
              hCaller hNonzero hFunds
          rw [hExecute] at hExpected
          injection hExpected
        · have hSource :
            sourceRun endpoints inputs entry =
              .reverted "NotEnoughEther" := by
            simp [sourceRun, hCaller, hNonzero, hFunds]
          simp [execute, hRoute, hSource, Contract.run] at hExecute
    · have hSource :
          sourceRun endpoints inputs entry = .reverted "NotLido" := by
        simp [sourceRun, hCaller]
      simp [execute, hRoute, hSource, Contract.run] at hExecute
  | withdrawalQueueReturn =>
    by_cases hCaller : callerAuthorized endpoints inputs entry.sender
    · by_cases hNonzero : inputs.amount = 0
      · have hSource :
          sourceRun endpoints inputs entry =
            .reverted "ZeroAmount" := by
          simp [sourceRun, hCaller, hNonzero]
        simp [execute, hRoute, hSource, Contract.run] at hExecute
      · by_cases hFunds : inputs.amount ≤ entry.selfBalance
        · have hSource :=
            sourceRun_commits_of_preconditions endpoints inputs entry
              hCaller hNonzero hFunds
          refine ⟨hSource, ?_⟩
          have hExpected :=
            execute_commits_of_preconditions endpoints inputs entry
              hCaller hNonzero hFunds
          rw [hExecute] at hExpected
          injection hExpected
        · have hSource :
          sourceRun endpoints inputs entry =
              .reverted "NotEnoughEther" := by
            simp [sourceRun, hCaller, hNonzero, hFunds]
          simp [execute, hRoute, hSource, Contract.run] at hExecute
    · simp [callerAuthorized, hRoute] at hCaller

theorem afterFrame_freshCalls (endpoints : Endpoints) (inputs : Inputs)
    (entry : ContractState) :
    freshCalls entry (afterFrame endpoints inputs entry) =
      [returnEntry endpoints inputs] := by
  simp [freshCalls, afterFrame]

theorem returnEntry_value (endpoints : Endpoints) (inputs : Inputs) :
    (returnEntry endpoints inputs).value = inputs.amount.val := rfl

end LidoSRv3.Audit.Verity.VaultEthTx
