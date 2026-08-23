import Verity.Core

/-!
# P-VAULT-ETH-1 pinned-source-shaped protocol return model

This module separates protocol-selected return routes from owner-selected
withdraw recipients. The first route is the pinned
`WithdrawalVault.withdrawWithdrawals` →
`LIDO.receiveWithdrawals{value: amount}()` shape. The second is the modeled
WithdrawalQueue protocol-return endpoint requested by this assurance row.

The route tag, rather than equality with a pinned address, carries provenance.
`ownerWithdrawal` is represented in the source destination type but has no
protocol-return input constructor. Consequently this model does not claim
that `VaultHub.withdraw` or `StakingVault.withdraw` to an arbitrary recipient
is approved.

This is a source-shaped audit model, not Solidity extraction or a claim about
all SRv3 ETH.
-/

namespace LidoSRv3.Audit.Source.VaultEthCorrespondence

abbrev Word := _root_.Verity.Core.Uint256
abbrev Address := _root_.Verity.Core.Address

/-- The two protocol-selected return routes covered by P-VAULT-ETH-1. -/
inductive Route
  | lidoReceiveWithdrawals
  | withdrawalQueueReturn
  deriving DecidableEq, Repr

/-- Runtime endpoints are explicit inputs. Their addresses do not establish
the route's provenance; the `Route` constructor does. -/
structure Endpoints where
  lido : Address
  withdrawalQueue : Address
  deriving DecidableEq, Repr

structure Inputs where
  route : Route
  amount : Word
  deriving DecidableEq, Repr

/-- Source destinations include the exact unmodeled owner-recipient class so
its exclusion is a proposition, not an omission hidden by address pins. -/
inductive Destination
  | lidoReceiveWithdrawals
  | withdrawalQueueReturn
  | ownerWithdrawal (recipient : Address)
  deriving DecidableEq, Repr

structure SourceLeg where
  destination : Destination
  target : Address
  value : Word
  deriving DecidableEq, Repr

abbrev SourceJournal := List SourceLeg

def destinationOf : Route → Destination
  | .lidoReceiveWithdrawals => .lidoReceiveWithdrawals
  | .withdrawalQueueReturn => .withdrawalQueueReturn

def targetOf (endpoints : Endpoints) : Route → Address
  | .lidoReceiveWithdrawals => endpoints.lido
  | .withdrawalQueueReturn => endpoints.withdrawalQueue

def sourceLeg (endpoints : Endpoints) (inputs : Inputs) : SourceLeg :=
  { destination := destinationOf inputs.route
    target := targetOf endpoints inputs.route
    value := inputs.amount }

def sourceJournal (endpoints : Endpoints) (inputs : Inputs) : SourceJournal :=
  [sourceLeg endpoints inputs]

/-- Explicit residual leg for `VaultHub.withdraw` / `StakingVault.withdraw`.
It is never produced by `sourceJournal`. -/
def ownerWithdrawalLeg (recipient : Address) (amount : Word) : SourceLeg :=
  { destination := .ownerWithdrawal recipient
    target := recipient
    value := amount }

inductive SourceOutcome
  | reverted (reason : String)
  | committed (journal : SourceJournal)
  deriving DecidableEq, Repr

/-- Source success requires a nonzero return amount no larger than the vault's
entry balance. Both success routes preserve the amount in the source journal.
-/
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

end LidoSRv3.Audit.Source.VaultEthCorrespondence
