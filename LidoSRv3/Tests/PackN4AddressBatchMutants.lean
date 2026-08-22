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
  ∃ payouts,
    sourcePayouts state requestIds hints = payouts.map some ∧
      journal = state.calls ++ payouts.map (payoutEntry recipient)

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
  simpa [honestThreeJournal] using
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
  have hpayouts : payouts = [30, 40, 10] := by
    simpa [sourcePayouts] using
      congrArg (List.map (Option.getD 0)) hreads
  subst payouts
  simpa [swappedThreeJournal] using hjournal

end LidoSRv3.Tests.PackN4AddressBatchMutants
