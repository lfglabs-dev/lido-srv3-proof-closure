import LidoSRv3.Audit.Spec.PauseAdmissionCorrespondence
import LidoSRv3.Audit.Spec.VaultHubScopeChild
import LidoSRv3.Audit.Spec.DerefSupplementalChild
import LidoSRv3.Audit.Source.AddressCorrespondence
import LidoSRv3.Audit.Spec
import LidoSRv3.Tests.DereferenceMutants

/-!
# Wave 2 W2-SCOPE fail-closed vectors

Three unregistered children, no new guarantee IDs, no P-DEREF-1 promotion.

* Pause: `requestWithdrawals` / `unwrap` use `permissionlessAdmission`.
* VaultHub: `ApprovedDestination` has no fifth constructor — decide on a match.
* Deref: re-export of the existing packed-config clobber kill-line.
-/

namespace LidoSRv3.Tests.PackW2ScopeMutants

open LidoSRv3.Audit.SolidityAddress
open LidoSRv3.Audit.SolidityDereference
open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.PauseAdmissionCorrespondence
open LidoSRv3.Audit.Spec.VaultHubScopeChild
open LidoSRv3.Audit.Spec.DerefSupplementalChild
open LidoSRv3.Tests.DereferenceMutants

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

/-- Kill-line: a complete match on `ApprovedDestination` has four arms.
Adding a VaultHub constructor would fail this match. -/
def destIndex : ApprovedDestination → Nat
  | .consolidationRequest => 0
  | .refundRecipient => 1
  | .beaconDeposit => 2
  | .lidoPull => 3

theorem approved_destination_has_no_fifth_ctor :
    destIndex .consolidationRequest = 0 ∧
    destIndex .refundRecipient = 1 ∧
    destIndex .beaconDeposit = 2 ∧
    destIndex .lidoPull = 3 := by
  decide

example := approved_destination_cases
example := no_vaulthub_ctor

/-- Re-export of the existing P-DEREF-1 packed-config clobber kill-line.
This node does not promote P-DEREF-1. -/
theorem packed_config_clobber_kill_line_refutes_parent :
    ¬ ∀ (s : RegistryState) (_hs : Reachable s) (id : ModuleId)
        (_h : Dereferenceable s id) (steps : List Interleaving),
        sourceDeref (mutantRunInterleavingsClobber s steps) id =
          some (s.moduleAddress id) ∧ s.moduleAddress id ≠ 0 :=
  LidoSRv3.Tests.DereferenceMutants.packed_config_clobber_kill_line_refutes_parent

example := deref_closure_exists_shape
example := deref_remains_supplemental

end LidoSRv3.Tests.PackW2ScopeMutants
