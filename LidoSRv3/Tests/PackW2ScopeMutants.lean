import LidoSRv3.Audit.Spec.PauseAdmissionCorrespondence
import LidoSRv3.Audit.Spec.VaultHubScopeChild
import LidoSRv3.Audit.Source.AddressCorrespondence
import LidoSRv3.Audit.Spec

/-!
# Wave 2 W2-SCOPE fail-closed vectors

Two unregistered children, no new guarantee IDs.

* Pause: `requestWithdrawals` / `unwrap` use `permissionlessAdmission`.
* VaultHub: all six approved constructors are protocol destinations; none is
  an arbitrary owner recipient.
-/

namespace LidoSRv3.Tests.PackW2ScopeMutants

open LidoSRv3.Audit.SolidityAddress
open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.PauseAdmissionCorrespondence
open LidoSRv3.Audit.Spec.VaultHubScopeChild

private def eligiblePause (ep : EntryPoint) : Input :=
  { entryPoint := ep, caller := 1, senderFrom := 1, recipient := 1,
    requestOwner := 99, amount := 1, requestId := 0, paused := false,
    requestExists := true, requestClaimed := false, requestFinalized := true,
    hintValid := true, callerIsApprovedForAll := false,
    callerIsTokenApproved := false, amountInRange := true,
    callerBalanceSufficient := true, callerAllowanceSufficient := true,
    externalCallSucceeds := true }

/-- Positive: `requestWithdrawals` admission is `permissionlessAdmission`. -/
theorem request_withdrawals_uses_permissionless_admission :
    let inp := eligiblePause .requestWithdrawals
    permissionlessAdmission inp = true ∧
      admitted inp = permissionlessAdmission inp := by
  decide

/-- Positive: `unwrap` admission is `permissionlessAdmission`. -/
theorem unwrap_uses_permissionless_admission :
    let inp := eligiblePause .unwrap
    permissionlessAdmission inp = true ∧
      admitted inp = permissionlessAdmission inp := by
  decide

example := request_or_unwrap_pause_balance_is_permissionless

/-- Scope guard: the complete match includes the two P-VAULT-ETH-1
protocol-return constructors. Adding an arbitrary owner-recipient constructor
would make this match incomplete. -/
def destIndex : ApprovedDestination → Nat
  | .consolidationRequest => 0
  | .refundRecipient => 1
  | .beaconDeposit => 2
  | .lidoPull => 3
  | .vaultToLido => 4
  | .vaultToWithdrawalQueue => 5

theorem approved_destination_has_only_six_scoped_ctors :
    destIndex .consolidationRequest = 0 ∧
    destIndex .refundRecipient = 1 ∧
    destIndex .beaconDeposit = 2 ∧
    destIndex .lidoPull = 3 ∧
    destIndex .vaultToLido = 4 ∧
    destIndex .vaultToWithdrawalQueue = 5 := by
  decide

example := approved_destination_cases
example := no_vaulthub_ctor

end LidoSRv3.Tests.PackW2ScopeMutants
