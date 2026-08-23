import LidoSRv3.Audit.Guarantees.PAddressBatch1
import LidoSRv3.Audit.Spec.AddressClaimBatchCorrespondence
import LidoSRv3.Audit.Spec.AddressClaimUnboundedCorrespondence
import LidoSRv3.Audit.Spec.AddressClaimKeccakSlots

/-!
# Pack N4 fail-closed vector

Unbounded rename is the registered parent. The three-item 30/40/10 witness
is an instance, not the quantified claim. The ∀ kill-line uses a
fixed-dest mutant on an arbitrary-length well-formed batch. Physical
keccak slots have their own parent-shaped raw-key and aliased-map
kill-lines.
-/

namespace LidoSRv3.Tests.PackN4AddressBatchMutants

open _root_.Verity
open _root_.Verity.EVM.Uint256
open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Spec.AddressClaimBatchCorrespondence
open LidoSRv3.Audit.Spec.AddressClaimFuelCorrespondence
open LidoSRv3.Audit.Spec.AddressClaimUnboundedCorrespondence
open LidoSRv3.Audit.Spec.AddressClaimKeccakSlots
open LidoSRv3.Audit.Guarantees
open Contracts

def honestThreeJournal : List ExternalCall :=
  [payoutEntry (2 : Address) 30, payoutEntry (2 : Address) 40,
    payoutEntry (2 : Address) 10]

/-- Mutant: the first two storage-derived payouts are emitted in reverse order. -/
def swappedThreeJournal : List ExternalCall :=
  [payoutEntry (2 : Address) 40, payoutEntry (2 : Address) 30,
    payoutEntry (2 : Address) 10]

def journalAgreesWithPreStateReads (state : ContractState)
    (requestIds hints : List Nat) (recipient : Address)
    (journal : List ExternalCall) : Prop :=
  ∃ payouts : List Nat,
    sourcePayouts state requestIds hints = List.map some payouts ∧
      journal = state.calls ++ List.map (payoutEntry recipient) payouts

theorem three_claim_batch_ready :
    BatchReady threeClaimState [1, 2, 3] [1, 1, 1] (2 : Address)
      [30, 40, 10] := by
  apply BatchReady.cons
  · constructor <;> decide +kernel
  apply BatchReady.cons
  · constructor <;> decide +kernel
  apply BatchReady.cons
  · constructor <;> decide +kernel
  exact BatchReady.nil _ _

/-- Honest three-item instance of the universal fuel-bounded parent. -/
theorem three_claim_batch_parent_instance :
    sourcePayouts threeClaimState [1, 2, 3] [1, 1, 1] =
        [some 30, some 40, some 10] ∧
      observe [1, 2, 3]
          ((executeClaimWithdrawalsTo [1, 2, 3] [1, 1, 1]
            (2 : Address)).run threeClaimState) =
        ⟨.committed, [true, true, true], 0, honestThreeJournal⟩ := by
  have hlocked :
      (threeClaimState.readSlot lockedEtherAmountPosition).val = 80 := by
    decide +kernel
  have hcalls : threeClaimState.calls = [] := by
    rfl
  simpa [honestThreeJournal, hlocked, hcalls] using
    fuel_bounded_live_claim_batch_correspondence 8 threeClaimState
      [1, 2, 3] [1, 1, 1] [30, 40, 10] (2 : Address)
      (by decide) (by decide) (by decide) three_claim_batch_ready (by decide)

/-- Parent-shaped kill-line: all well-formedness premises remain true, while
the swapped journal disagrees with the ordered pre-state reads. -/
theorem swapped_three_payout_order_kill_line_refutes_parent :
    [1, 2, 3].length ≤ 8 ∧
      [1, 2, 3].length = [1, 1, 1].length ∧
      (([1, 2, 3].map fun id => (.ofNat id : Uint256)).Nodup) ∧
      BatchReady threeClaimState [1, 2, 3] [1, 1, 1] (2 : Address)
        [30, 40, 10] ∧
      (2 : Address) ≠ zeroAddress ∧
      sourcePayouts threeClaimState [1, 2, 3] [1, 1, 1] =
        [some 30, some 40, some 10] ∧
      ¬ journalAgreesWithPreStateReads threeClaimState [1, 2, 3] [1, 1, 1]
        (2 : Address) swappedThreeJournal := by
  refine ⟨by decide, by decide, by decide, three_claim_batch_ready, by decide,
    three_claim_batch_parent_instance.1, ?_⟩
  intro hagrees
  rcases hagrees with ⟨payouts, hreads, hjournal⟩
  have hmaps : List.map some payouts = [some 30, some 40, some 10] :=
    hreads.symm.trans three_claim_batch_parent_instance.1
  have hpayouts : payouts = [30, 40, 10] := by
    simpa using
      congrArg (List.map (fun value : Option Nat => value.getD 0)) hmaps
  subst payouts
  have hcalls : threeClaimState.calls = [] := by
    rfl
  have hne : swappedThreeJournal ≠ honestThreeJournal := by
    decide
  apply hne
  simpa [honestThreeJournal, hcalls] using hjournal

/-- Mutant live path: payout dest is a constant, ignoring the renamed
recipient. -/
def executeClaimWithdrawalsToFixedDest (requestIds hints : List Nat)
    (_recipient : Address) : Contract Unit :=
  executeClaimWithdrawalsTo requestIds hints (99 : Address)

/-- Rename used by the kill-line: send payouts to address 7. -/
def renameToSeven (a : Address) : Address :=
  if a = (2 : Address) then (7 : Address) else a

/-- Parent-shaped kill-line: well-formedness premises stay, including
`renameToSeven 2 ≠ 0`, but the fixed-dest mutant still pays 99 instead of
the renamed dest 7. -/
theorem fixed_dest_rename_kill_line_refutes_parent :
    [1, 2, 3].length ≤ 8 ∧
      [1, 2, 3].length = [1, 1, 1].length ∧
      (([1, 2, 3].map fun id => (.ofNat id : Uint256)).Nodup) ∧
      BatchReady threeClaimState [1, 2, 3] [1, 1, 1] (2 : Address)
        [30, 40, 10] ∧
      (2 : Address) ≠ zeroAddress ∧
      renameToSeven (2 : Address) ≠ zeroAddress ∧
      observe [1, 2, 3]
          ((executeClaimWithdrawalsToFixedDest [1, 2, 3] [1, 1, 1]
            (renameToSeven (2 : Address))).run threeClaimState) ≠
        ⟨.committed, [true, true, true], 0,
          [payoutEntry (renameToSeven (2 : Address)) 30,
            payoutEntry (renameToSeven (2 : Address)) 40,
            payoutEntry (renameToSeven (2 : Address)) 10]⟩ := by
  refine ⟨by decide, by decide, by decide, three_claim_batch_ready, by decide,
    by decide, ?_⟩
  have hHonest :=
    (PAddressBatch1.p_address_batch_1_fuel_bounded_recipient_rename
      8 threeClaimState [1, 2, 3] [1, 1, 1] [30, 40, 10] (2 : Address)
      renameToSeven (by decide) (by decide) (by decide)
      three_claim_batch_ready (by decide) (by decide)).1
  have hMutant :
      observe [1, 2, 3]
          ((executeClaimWithdrawalsToFixedDest [1, 2, 3] [1, 1, 1]
            (renameToSeven (2 : Address))).run threeClaimState) =
        ⟨.committed, [true, true, true], 0,
          [payoutEntry (99 : Address) 30, payoutEntry (99 : Address) 40,
            payoutEntry (99 : Address) 10]⟩ := by
    have hready99 :
        BatchReady threeClaimState [1, 2, 3] [1, 1, 1] (99 : Address)
          [30, 40, 10] :=
      three_claim_batch_ready.with_recipient (99 : Address)
    have hlocked :
        (threeClaimState.readSlot lockedEtherAmountPosition).val = 80 := by
      decide +kernel
    have hcalls : threeClaimState.calls = [] := rfl
    simpa [executeClaimWithdrawalsToFixedDest, hlocked, hcalls] using
      (fuel_bounded_live_claim_batch_correspondence 8 threeClaimState
        [1, 2, 3] [1, 1, 1] [30, 40, 10] (99 : Address)
        (by decide) (by decide) (by decide) hready99 (by decide)).2
  intro hEq
  have hNe :
      (⟨.committed, [true, true, true], 0,
        [payoutEntry (99 : Address) 30, payoutEntry (99 : Address) 40,
          payoutEntry (99 : Address) 10]⟩ : View) ≠
      ⟨.committed, [true, true, true], 0,
        [payoutEntry (renameToSeven (2 : Address)) 30,
          payoutEntry (renameToSeven (2 : Address)) 40,
          payoutEntry (renameToSeven (2 : Address)) 10]⟩ := by
    decide
  exact hNe (hMutant.symm.trans hEq)

/-- Positive control: the honest rename parent holds on the three-item
batch. -/
theorem honest_rename_parent_holds :
    observe [1, 2, 3]
        ((executeClaimWithdrawalsTo [1, 2, 3] [1, 1, 1]
          (renameToSeven (2 : Address))).run threeClaimState) =
      ⟨.committed, [true, true, true], 0,
        [payoutEntry (7 : Address) 30, payoutEntry (7 : Address) 40,
          payoutEntry (7 : Address) 10]⟩ := by
  have hlocked :
      (threeClaimState.readSlot lockedEtherAmountPosition).val = 80 := by
    decide +kernel
  have hcalls : threeClaimState.calls = [] := rfl
  simpa [renameToSeven, hlocked, hcalls] using
    (PAddressBatch1.p_address_batch_1_unbounded_recipient_rename
      threeClaimState [1, 2, 3] [1, 1, 1] [30, 40, 10] (2 : Address)
      renameToSeven (by decide) (by decide)
      three_claim_batch_ready (by decide) (by decide)).1

/-- Parent-shaped ∀ kill-line: every well-formedness premise of the
unbounded rename stays, including `ρ recipient ≠ 0` and a nonempty
payout trace, but the fixed-dest mutant still pays 99. This is not a
2/3-item numeral receipt. -/
theorem fixed_dest_unbounded_rename_kill_line
    (state : ContractState) (requestIds hints payouts : List Nat)
    (recipient : Address) (ρ : Address → Address)
    (hlength : requestIds.length = hints.length)
    (hnodup : (requestIds.map fun id => (.ofNat id : Uint256)).Nodup)
    (hready : BatchReady state requestIds hints recipient payouts)
    (_hrecipient : recipient ≠ zeroAddress)
    (_hrenamed : ρ recipient ≠ zeroAddress)
    (hpayouts : payouts ≠ [])
    (hmutant : (99 : Address) ≠ ρ recipient) :
    observe requestIds
        ((executeClaimWithdrawalsToFixedDest requestIds hints
          (ρ recipient)).run state) ≠
      ⟨.committed, List.replicate requestIds.length true,
        (state.readSlot lockedEtherAmountPosition).val - payouts.sum,
        state.calls ++ payouts.map (payoutEntry (ρ recipient))⟩ := by
  have hready99 :
      BatchReady state requestIds hints (99 : Address) payouts :=
    hready.with_recipient (99 : Address)
  have h99 : (99 : Address) ≠ zeroAddress := by decide
  have hMutant :
      observe requestIds
          ((executeClaimWithdrawalsToFixedDest requestIds hints
            (ρ recipient)).run state) =
        ⟨.committed, List.replicate requestIds.length true,
          (state.readSlot lockedEtherAmountPosition).val - payouts.sum,
          state.calls ++ payouts.map (payoutEntry (99 : Address))⟩ := by
    simpa [executeClaimWithdrawalsToFixedDest] using
      (unbounded_live_claim_batch_correspondence state requestIds hints
        payouts (99 : Address) hlength hnodup hready99 h99).2
  intro hEq
  have hcalls :
      state.calls ++ payouts.map (payoutEntry (99 : Address)) =
        state.calls ++ payouts.map (payoutEntry (ρ recipient)) :=
    congrArg View.calls (hMutant.symm.trans hEq)
  have hmaps :
      payouts.map (payoutEntry (99 : Address)) =
        payouts.map (payoutEntry (ρ recipient)) :=
    List.append_cancel_left hcalls
  cases payouts with
  | nil => exact hpayouts rfl
  | cons amount payouts =>
      have hhead :
          payoutEntry (99 : Address) amount =
            payoutEntry (ρ recipient) amount :=
        (List.cons.inj hmaps).1
      have htarget :
          ((99 : Address).toNat) = (ρ recipient).toNat :=
        congrArg ExternalCall.target hhead
      exact hmutant (Verity.Core.Address.toNat_injective _ _ htarget)

/-- Raw-key mutant fails the physical-slot conjunct whenever the raw
cell and the keccak cell hold different words. -/
theorem raw_key_mutant_fails_physical_slot
    (state : ContractState) (requestId hint : Nat) (recipient : Address)
    (h : PhysicalClaimSlots state)
    (hdistinct :
      state.readSlot requestId ≠
        state.readSlot (queueAmountsPhysicalSlot requestId)) :
    requestAmountsWordRawKey state requestId ≠
      requestAmountsWord state requestId := by
  have hphys :=
    (PAddressBatch1.p_address_batch_1_physical_keccak_slots state
      requestId hint recipient h).1
  simpa [requestAmountsWordRawKey, hphys] using hdistinct

/-- Aliasing `POSITION+1` to a different map fails the physical-slot
conjunct whenever that other map's word is not the next keccak word. -/
theorem aliased_plus_one_map_fails_physical_slot
    (state : ContractState) (requestId hint : Nat) (recipient : Address)
    (h : PhysicalClaimSlots state)
    (hdistinct :
      state.readMapUint (checkpointsPosition + 1) (.ofNat requestId) ≠
        state.readSlot (queueMetadataPhysicalSlot requestId)) :
    requestMetadataWordAliasedMap state requestId ≠
      requestMetadataWord state requestId := by
  have hphys :=
    (PAddressBatch1.p_address_batch_1_physical_keccak_slots state
      requestId hint recipient h).2.1
  simpa [requestMetadataWordAliasedMap, hphys] using hdistinct

/-- The `queuePosition + 1` channel is a different keccak map, not the
next word of `queuePosition`. -/
theorem plus_one_channel_is_a_different_keccak_map (requestId : Nat) :
    Compiler.Proofs.solidityMappingSlot (queuePosition + 1) requestId ≠
      Compiler.Proofs.solidityMappingSlot queuePosition requestId :=
  (physical_queue_slots_are_keccak_derivation requestId).2.2

end LidoSRv3.Tests.PackN4AddressBatchMutants
