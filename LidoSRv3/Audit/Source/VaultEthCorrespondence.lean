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

/-- Successful source schedule: one hop whose dest is the route constructor
and whose wei is the modeled amount. -/
def sourceJournal (endpoints : Endpoints) (inputs : Inputs) : SourceJournal :=
  [{ destination := destinationOf inputs.route
     target := targetOf endpoints inputs.route
     value := inputs.amount }]

/-- Source guards: nonzero amount and enough vault ETH. Address pins are not
consulted. -/
def sourceRun (endpoints : Endpoints) (inputs : Inputs) (vaultBalance : Word) :
    SourceOutcome :=
  if inputs.amount = 0 then .reverted "ZeroAmount"
  else if inputs.amount ≤ vaultBalance then
    .committed (sourceJournal endpoints inputs)
  else .reverted "NotEnoughEther"

theorem sourceRun_commits_of_preconditions
    (endpoints : Endpoints) (inputs : Inputs) (vaultBalance : Word)
    (hNonzero : inputs.amount ≠ 0)
    (hFunds : inputs.amount ≤ vaultBalance) :
    sourceRun endpoints inputs vaultBalance =
      .committed (sourceJournal endpoints inputs) := by
  simp [sourceRun, hNonzero, hFunds]

theorem sourceRun_reverts_on_zero
    (endpoints : Endpoints) (inputs : Inputs) (vaultBalance : Word)
    (hZero : inputs.amount = 0) :
    sourceRun endpoints inputs vaultBalance = .reverted "ZeroAmount" := by
  simp [sourceRun, hZero]

theorem sourceJournal_destination (endpoints : Endpoints) (inputs : Inputs) :
    (sourceJournal endpoints inputs).map SourceLeg.destination =
      [destinationOf inputs.route] := rfl

theorem sourceJournal_value (endpoints : Endpoints) (inputs : Inputs) :
    (sourceJournal endpoints inputs).map (fun leg => leg.value) =
      [inputs.amount] := rfl

end LidoSRv3.Audit.Source.VaultEthCorrespondence
