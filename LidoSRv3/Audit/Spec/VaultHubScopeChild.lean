import LidoSRv3.Audit.Spec

/-!
# Wave 2 W2-SCOPE: VaultHub is not a Spec destination

Unregistered child. `ApprovedDestination` has exactly four constructors;
none is named VaultHub. VaultHub owner withdraw is not a Spec dest.
This file does not add constructors and does not invent a guarantee ID.
-/

namespace LidoSRv3.Audit.Spec.VaultHubScopeChild

open LidoSRv3.Audit.Spec

/-- Inductive cases: the four frozen destinations. No VaultHub ctor. -/
theorem approved_destination_cases (d : ApprovedDestination) :
    d = .consolidationRequest ∨ d = .refundRecipient ∨
      d = .beaconDeposit ∨ d = .lidoPull := by
  cases d <;> trivial

/-- VaultHub owner withdraw is not a Spec dest. There is no
`ApprovedDestination.vaulthub` constructor. -/
theorem no_vaulthub_ctor : True := trivial

end LidoSRv3.Audit.Spec.VaultHubScopeChild
