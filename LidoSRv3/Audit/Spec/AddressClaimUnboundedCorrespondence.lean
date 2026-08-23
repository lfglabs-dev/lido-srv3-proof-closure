import LidoSRv3.Audit.Spec.AddressClaimFuelCorrespondence

/-!
# Unbounded live claim-batch correspondence

Fuel-bounded payout and recipient rename stay lemmas. This module drops
the unused fuel parameter: the same `BatchReady` induction already
covers every well-formed request/hint list.
-/

namespace LidoSRv3.Audit.Spec.AddressClaimUnboundedCorrespondence

open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Spec.AddressClaimFuelCorrespondence
open _root_.Verity
open _root_.Verity.EVM.Uint256
open Contracts

/-- Unbounded source/observe correspondence for the live
`executeClaimWithdrawalsTo` loop. No fuel bound. -/
theorem unbounded_live_claim_batch_correspondence
    (state : ContractState) (requestIds hints payouts : List Nat)
    (recipient : Address)
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
  fuel_bounded_live_claim_batch_correspondence requestIds.length state
    requestIds hints payouts recipient (Nat.le_refl _) hlength hnodup
    hready hrecipient

/-- Unbounded recipient-rename parent: `ρ · executeClaimWithdrawalsTo =
execute · ρ` on the live observe journal dests. Fuel-bounded rename
remains a lemma. -/
theorem unbounded_live_claim_batch_recipient_rename
    (state : ContractState) (requestIds hints payouts : List Nat)
    (recipient : Address) (ρ : Address → Address)
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
  fuel_bounded_live_claim_batch_recipient_rename requestIds.length state
    requestIds hints payouts recipient ρ (Nat.le_refl _) hlength hnodup
    hready hrecipient hrenamed

theorem every_revert_restores_snapshot (requestIds hints : List Nat)
    (recipient : Address) (state rollback : ContractState) (reason : String)
    (h : (executeClaimWithdrawalsTo requestIds hints recipient).run state =
      .revert reason rollback) : rollback = state :=
  LidoSRv3.Audit.Spec.AddressClaimFuelCorrespondence.every_revert_restores_snapshot
    requestIds hints recipient state rollback reason h

end LidoSRv3.Audit.Spec.AddressClaimUnboundedCorrespondence
