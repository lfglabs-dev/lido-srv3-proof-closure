import LidoSRv3.Audit.Guarantees.PAddressBatch1
import LidoSRv3.Audit.Spec.AddressClaimBatchCorrespondence

/-!
# Pack N4 fail-closed vector

The three-item 30/40/10 witness retains the fuel, equal-length, distinct-key,
live-guard, and recipient premises of the parent. The mutant swaps the first
two payout entries, so its journal cannot agree with the entry-snapshot
`claimableEther` reads.
-/

namespace LidoSRv3.Tests.PackN4AddressBatchMutants

open _root_.Verity
open _root_.Verity.EVM.Uint256
open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Spec.AddressClaimBatchCorrespondence
open LidoSRv3.Audit.Spec.AddressClaimFuelCorrespondence
open LidoSRv3.Audit.Guarantees

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
    (PAddressBatch1.p_address_batch_1_fuel_bounded_recipient_rename
      8 threeClaimState [1, 2, 3] [1, 1, 1] [30, 40, 10] (2 : Address)
      renameToSeven (by decide) (by decide) (by decide)
      three_claim_batch_ready (by decide) (by decide)).1

end LidoSRv3.Tests.PackN4AddressBatchMutants
