import LidoSRv3.Audit.Spec.AddressClaimFuelCorrespondence
import LidoSRv3.Audit.Spec.AddressClaimUnboundedCorrespondence
import LidoSRv3.Audit.Spec.AddressClaimKeccakSlots
import LidoSRv3.Audit.Guarantees.Registry

/-!
# P-ADDRESS-BATCH-1: unbounded live claim rename and physical keccak slots

This parent is separate from, and does not weaken,
`PAddress1.universal_address_writer_equivariance`. It covers arbitrary
well-formed request/hint lists with no fuel bound, and the live
`ρ · executeClaimWithdrawalsTo = execute · ρ` journal rename.
Fuel-bounded rename stays a lemma. The live `mapUint` channels inhabit
the keccak mapping slots `keccak256(abi.encode(key, POSITION))` and the
next word.
-/

namespace LidoSRv3.Audit.Guarantees.PAddressBatch1

open _root_.Verity
open _root_.Verity.EVM.Uint256
open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Spec.AddressClaimFuelCorrespondence
open LidoSRv3.Audit.Spec.AddressClaimUnboundedCorrespondence
open LidoSRv3.Audit.Spec.AddressClaimKeccakSlots

/-- Supplemental unbounded live-loop parent. Does not weaken
`PAddress1.universal_address_writer_equivariance`. -/
def guarantee : Guarantee := ⟨.pAddressBatch1, [.model, .source, .verityTx]⟩

/-- Lemma: fuel-bounded payout correspondence. The registered parent no
longer carries a fuel parameter. -/
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

/-- Lemma: fuel-bounded recipient rename. -/
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

/-- Registered unbounded rename parent: `ρ · execute = execute · ρ` on
the live claim journal dests. No fuel bound. Premises are well-formed
`BatchReady` lists, distinct encoded keys, `recipient ≠ 0`, and
`ρ recipient ≠ 0`. -/
theorem p_address_batch_1_unbounded_recipient_rename
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
  unbounded_live_claim_batch_recipient_rename state requestIds hints
    payouts recipient ρ hlength hnodup hready hrecipient hrenamed

/-- Registered physical-slot parent: ∀ request id / hint / recipient on
the live path, the keyed `mapUint` channels are the keccak mapping slots
and the next word. -/
theorem p_address_batch_1_physical_keccak_slots
    (state : ContractState) (requestId hint : Nat) (recipient : Address)
    (h : PhysicalClaimSlots state) :
    requestAmountsWord state requestId =
        state.readSlot (queueAmountsPhysicalSlot requestId) ∧
      requestMetadataWord state requestId =
        state.readSlot (queueMetadataPhysicalSlot requestId) ∧
      checkpointFromWord state hint =
        state.readSlot (checkpointFromPhysicalSlot hint) ∧
      checkpointRateWord state hint =
        state.readSlot (checkpointRatePhysicalSlot hint) :=
  live_claim_channels_are_physical_keccak_slots state requestId hint
    recipient h

/-- Universal rollback is inherited from the live transaction boundary. -/
theorem every_revert_restores_snapshot (requestIds hints : List Nat)
    (recipient : Address) (state rollback : ContractState) (reason : String)
    (h : (executeClaimWithdrawalsTo requestIds hints recipient).run state =
      .revert reason rollback) : rollback = state :=
  LidoSRv3.Audit.Spec.AddressClaimFuelCorrespondence.every_revert_restores_snapshot
    requestIds hints recipient state rollback reason h

end LidoSRv3.Audit.Guarantees.PAddressBatch1
