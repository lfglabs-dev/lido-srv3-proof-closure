import LidoSRv3.Audit.Spec.AddressClaimFuelCorrespondence
import LidoSRv3.Audit.Guarantees.Registry

/-!
# P-ADDRESS-BATCH-1: fuel-bounded live claim loop and recipient rename

This parent is separate from, and does not weaken,
`PAddress1.universal_address_writer_equivariance`. It covers arbitrary
well-formed request/hint lists within an explicit natural-number fuel bound,
and the live `ρ · executeClaimWithdrawalsTo = execute · ρ` journal rename.
keccak / machine-storage slot maps stay OPEN.
-/

namespace LidoSRv3.Audit.Guarantees.PAddressBatch1

open _root_.Verity
open _root_.Verity.EVM.Uint256
open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Spec.AddressClaimFuelCorrespondence

/-- Supplemental fuel-bounded live-loop parent. Does not weaken
`PAddress1.universal_address_writer_equivariance`. -/
def guarantee : Guarantee := ⟨.pAddressBatch1, [.model, .source, .verityTx]⟩

/-- Registered fuel-bounded parent for the live `claimWithdrawalsTo` loop. -/
theorem p_address_batch_1_fuel_bounded_live_claim_batch
    (fuel : Nat) (state : ContractState) (requestIds hints payouts : List Nat)
    (recipient : Address)
    (hfuel : requestIds.length ≤ fuel)
    (hlength : requestIds.length = hints.length)
    (hnodup : (requestIds.map fun id => (.ofNat id : Uint256)).Nodup)
    (hready : BatchReady state requestIds hints recipient payouts)
    (hrecipient : recipient ≠ zeroAddress) :
    sourcePayouts state requestIds hints = payouts.map some ∧
      observe requestIds
          ((executeClaimWithdrawalsTo requestIds hints recipient).run state) =
        ⟨.committed, List.replicate requestIds.length true,
          (state.readSlot lockedEtherAmountPosition).val - payouts.sum,
          state.calls ++ payouts.map (payoutEntry recipient)⟩ :=
  fuel_bounded_live_claim_batch_correspondence fuel state requestIds hints
    payouts recipient hfuel hlength hnodup hready hrecipient

/-- Registered fuel-bounded rename parent: `ρ · execute = execute · ρ` on
the live claim journal dests. Premises are the payout-correspondence
premises plus `ρ recipient ≠ zeroAddress`. -/
theorem p_address_batch_1_fuel_bounded_recipient_rename
    (fuel : Nat) (state : ContractState) (requestIds hints payouts : List Nat)
    (recipient : Address) (ρ : Address → Address)
    (hfuel : requestIds.length ≤ fuel)
    (hlength : requestIds.length = hints.length)
    (hnodup : (requestIds.map fun id => (.ofNat id : Uint256)).Nodup)
    (hready : BatchReady state requestIds hints recipient payouts)
    (hrecipient : recipient ≠ zeroAddress)
    (hrenamed : ρ recipient ≠ zeroAddress) :
    observe requestIds
          ((executeClaimWithdrawalsTo requestIds hints (ρ recipient)).run
            state) =
        ⟨.committed, List.replicate requestIds.length true,
          (state.readSlot lockedEtherAmountPosition).val - payouts.sum,
          state.calls ++ payouts.map (payoutEntry (ρ recipient))⟩ ∧
      observe requestIds
          ((executeClaimWithdrawalsTo requestIds hints recipient).run state) =
        ⟨.committed, List.replicate requestIds.length true,
          (state.readSlot lockedEtherAmountPosition).val - payouts.sum,
          state.calls ++ payouts.map (payoutEntry recipient)⟩ :=
  fuel_bounded_live_claim_batch_recipient_rename fuel state requestIds hints
    payouts recipient ρ hfuel hlength hnodup hready hrecipient hrenamed

/-- Universal rollback is inherited from the live transaction boundary. -/
theorem every_revert_restores_snapshot (requestIds hints : List Nat)
    (recipient : Address) (state rollback : ContractState) (reason : String)
    (h : (executeClaimWithdrawalsTo requestIds hints recipient).run state =
      .revert reason rollback) : rollback = state :=
  LidoSRv3.Audit.Spec.AddressClaimFuelCorrespondence.every_revert_restores_snapshot
    requestIds hints recipient state rollback reason h

end LidoSRv3.Audit.Guarantees.PAddressBatch1
