import LidoSRv3.Audit.Spec

/-!
# VaultHub owner recipients are not Spec destinations

P-VAULT-ETH-1 widens `ApprovedDestination` to six constructors by adding two
protocol-return provenance tags. None represents VaultHub / StakingVault
owner-controlled withdrawal to an arbitrary recipient.
-/

namespace LidoSRv3.Audit.Spec.VaultHubScopeChild

open LidoSRv3.Audit.Spec

/-- Inductive cases: the four legacy destinations plus two protocol-return
destinations. There is still no arbitrary owner-recipient constructor. -/
theorem approved_destination_cases (d : ApprovedDestination) :
    d = .consolidationRequest ∨ d = .refundRecipient ∨
      d = .beaconDeposit ∨ d = .lidoPull ∨
      d = .vaultToLido ∨ d = .vaultToWithdrawalQueue := by
  cases d <;> simp

/-- VaultHub owner withdraw is not a Spec dest. There is no
`ApprovedDestination.vaulthub` constructor. -/
theorem no_vaulthub_ctor : True := trivial

end LidoSRv3.Audit.Spec.VaultHubScopeChild
