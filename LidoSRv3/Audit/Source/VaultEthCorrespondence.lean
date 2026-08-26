import Verity.Core

/-!
# P-VAULT-ETH-1 source schedule

Independent source interpreter for the two protocol-return hops that
`P-ETH-JOURNAL-1` names out of the consolidation journal:

* Vault→Lido via `LIDO.receiveWithdrawals` / protocol rebalance
* Vault→WithdrawalQueue

Provenance is the route constructor, not an address pin. Endpoint addresses
are runtime inputs. Owner-controlled `VaultHub.withdraw` /
`StakingVault.withdraw` to an arbitrary recipient is a third source
destination and is not committed here.

This is not a claim that Lido never drains ETH, and it is not all SRv3 ETH.
-/

namespace LidoSRv3.Audit.Source.VaultEthCorrespondence

open Verity

abbrev Word := Verity.Core.Uint256
abbrev Address := Verity.Core.Address

/-- Runtime endpoints. These are journal keys, not live-deployment identity. -/
structure Endpoints where
  lido : Address
  withdrawalQueue : Address
  deriving DecidableEq, Repr

/-- Modeled protocol-return routes. Each is inhabited by a value-bearing
`externalCallBindTo` frame on the Verity plane. -/
inductive Route
  | lidoReceiveWithdrawals
  | withdrawalQueueReturn
  deriving DecidableEq, Repr

/-- Source destinations. The owner-withdraw residual stays unapproved. -/
inductive Destination
  | lidoReceiveWithdrawals
  | withdrawalQueueReturn
  | ownerWithdrawal (recipient : Address)
  deriving DecidableEq, Repr

structure Inputs where
  route : Route
  /-- `msg.sender` at the modeled vault entry.  It is checked only for the
  source-backed WithdrawalVault→Lido body. -/
  caller : Address
  amount : Word
  deriving Repr

structure SourceLeg where
  destination : Destination
  target : Address
  value : Word
  deriving Repr

abbrev SourceJournal := List SourceLeg

inductive SourceOutcome where
  | reverted (reason : String)
  | committed (journal : SourceJournal)
  deriving Repr

def destinationOf : Route → Destination
  | .lidoReceiveWithdrawals => .lidoReceiveWithdrawals
  | .withdrawalQueueReturn => .withdrawalQueueReturn

def targetOf (endpoints : Endpoints) : Route → Address
  | .lidoReceiveWithdrawals => endpoints.lido
  | .withdrawalQueueReturn => endpoints.withdrawalQueue

/-- The exact caller guard present in the pinned
`WithdrawalVault.withdrawWithdrawals` body.  The WithdrawalQueue constructor
has no such body binding yet, so it remains source-shaped. -/
def callerAuthorized (endpoints : Endpoints) (inputs : Inputs) : Bool :=
  match inputs.route with
  | .lidoReceiveWithdrawals => inputs.caller == endpoints.lido
  | .withdrawalQueueReturn => true

/-- Successful source schedule: one hop whose dest is the route constructor
and whose wei is the modeled amount. -/
def sourceJournal (endpoints : Endpoints) (inputs : Inputs) : SourceJournal :=
  [{ destination := destinationOf inputs.route
     target := targetOf endpoints inputs.route
     value := inputs.amount }]

/-- Source guards: the exact pinned Lido-caller check where a body is known,
then nonzero amount and enough vault ETH. Endpoints are runtime inputs, not
deployment identity evidence. -/
def sourceRun (endpoints : Endpoints) (inputs : Inputs) (vaultBalance : Word) :
    SourceOutcome :=
  if !callerAuthorized endpoints inputs then .reverted "NotLido"
  else if inputs.amount = 0 then .reverted "ZeroAmount"
  else if inputs.amount ≤ vaultBalance then
    .committed (sourceJournal endpoints inputs)
  else .reverted "NotEnoughEther"

theorem sourceRun_commits_of_preconditions
    (endpoints : Endpoints) (inputs : Inputs) (vaultBalance : Word)
    (hCaller : callerAuthorized endpoints inputs = true)
    (hNonzero : inputs.amount ≠ 0)
    (hFunds : inputs.amount ≤ vaultBalance) :
    sourceRun endpoints inputs vaultBalance =
      .committed (sourceJournal endpoints inputs) := by
  simp [sourceRun, hCaller, hNonzero, hFunds]

theorem sourceRun_reverts_on_zero
    (endpoints : Endpoints) (inputs : Inputs) (vaultBalance : Word)
    (hCaller : callerAuthorized endpoints inputs = true)
    (hZero : inputs.amount = 0) :
    sourceRun endpoints inputs vaultBalance = .reverted "ZeroAmount" := by
  simp [sourceRun, hCaller, hZero]

/-- The modeled Lido-route constraints retained by this slice.  This is a
caller-guard/runtime-endpoint relation, not an implementation-body binding or
a claim that either runtime address identifies a deployed contract. -/
def LidoCallerEndpointBinding (endpoints : Endpoints) (inputs : Inputs)
    (entry : ContractState) : Prop :=
  inputs.route = .lidoReceiveWithdrawals →
    entry.sender = endpoints.lido ∧
      inputs.caller = entry.sender ∧
      targetOf endpoints inputs.route = endpoints.lido

theorem lido_caller_endpoint_binding_of_success
    (endpoints : Endpoints) (inputs : Inputs) (vaultBalance : Word)
    (entry : ContractState) (journal : SourceJournal)
    (hSuccess : sourceRun endpoints inputs vaultBalance = .committed journal) :
    (inputs.route = .lidoReceiveWithdrawals → inputs.caller = entry.sender) →
      LidoCallerEndpointBinding endpoints inputs entry := by
  rcases inputs with ⟨route, caller, amount⟩
  cases route with
  | lidoReceiveWithdrawals =>
      simp only [LidoCallerEndpointBinding]
      intro _
      have hCaller : caller = endpoints.lido := by
        cases hEqual : caller == endpoints.lido with
        | false => simp [sourceRun, callerAuthorized, hEqual] at hSuccess
        | true => exact beq_iff_eq.mp hEqual
      intro hEntryCaller
      exact ⟨hEntryCaller rfl ▸ hCaller, hEntryCaller rfl, rfl⟩
  | withdrawalQueueReturn => simp [LidoCallerEndpointBinding]

theorem sourceJournal_destination (endpoints : Endpoints) (inputs : Inputs) :
    (sourceJournal endpoints inputs).map SourceLeg.destination =
      [destinationOf inputs.route] := rfl

theorem sourceJournal_value (endpoints : Endpoints) (inputs : Inputs) :
    (sourceJournal endpoints inputs).map (fun leg => leg.value) =
      [inputs.amount] := rfl

end LidoSRv3.Audit.Source.VaultEthCorrespondence
