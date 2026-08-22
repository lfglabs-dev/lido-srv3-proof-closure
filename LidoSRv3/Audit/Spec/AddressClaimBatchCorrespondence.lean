import LidoSRv3.Audit.Verity.AddressClaimBatchTx

/-!
# Wave 2 W2-ADDR: three-item live claim-batch correspondence

Unregistered child. Pack D remains the two-item read→payout naming.
This node adds a three-item witness and a length-mismatch revert; it
does not replace the registered P-ADDRESS-1 parent, does not add a
pause row, and does not invent a guarantee ID.

It does not claim unbounded source equivariance, keccak/machine-storage
slot derivation, EnumerableSet/events, or that all four address writers
are permissionless.
-/

namespace LidoSRv3.Audit.Spec.AddressClaimBatchCorrespondence

open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open _root_.Verity

/-- Three-item witness packed like `twoClaimState`. Request 3 pays 10;
locked ETH is 80 so 30+40+10 is consistent. Pack D's `twoClaimState`
is unchanged (locked 70, payouts 30+40). -/
def threeClaimState : ContractState :=
  let state := { defaultState with sender := (1 : Address), selfBalance := .ofNat 80 }
  let state := state.writeSlot lastFinalizedRequestIdPosition 3
  let state := state.writeSlot lastCheckpointIndexPosition 1
  let state := state.writeSlot lockedEtherAmountPosition 80
  let state := state.writeMapUint queuePosition 0 (packAmounts 0 0)
  let state := state.writeMapUint queuePosition 1 (packAmounts 30 30)
  let state := state.writeMapUint queuePosition 2 (packAmounts 70 70)
  let state := state.writeMapUint queuePosition 3 (packAmounts 80 80)
  let state := state.writeMapUint (queuePosition + 1) 1
    (packMetadata (1 : Address) 100 false 90)
  let state := state.writeMapUint (queuePosition + 1) 2
    (packMetadata (1 : Address) 101 false 90)
  let state := state.writeMapUint (queuePosition + 1) 3
    (packMetadata (1 : Address) 102 false 90)
  let state := state.writeMapUint checkpointsPosition 1 1
  state.writeMapUint (checkpointsPosition + 1) 1 (.ofNat E27)

/-- Storage-backed claimable amounts of the three-item witness, in
loop order. -/
def threeClaimPayouts : List (Option Nat) :=
  [claimableEther (readRequest threeClaimState 1 1),
   claimableEther (readRequest threeClaimState 2 1),
   claimableEther (readRequest threeClaimState 3 1)]

/-- Unregistered child: the three-item live batch journals exactly the
`claimableEther` of the pre-state `readRequest`s, to the supplied
recipient, and marks all three requests claimed. This is a bounded
three-item receipt, not unbounded source equivariance. -/
theorem three_claim_payouts_match_reads :
    threeClaimPayouts = [some 30, some 40, some 10] ∧
      observe [1, 2, 3]
          ((executeClaimWithdrawalsTo [1, 2, 3] [1, 1, 1] (2 : Address)).run
            threeClaimState) =
        ⟨.committed, [true, true, true], 0,
          [payoutEntry (2 : Address) 30, payoutEntry (2 : Address) 40,
            payoutEntry (2 : Address) 10]⟩ := by
  refine ⟨by decide, by decide +kernel⟩

/-- Parallel-array length mismatch reverts before any claim write. -/
theorem length_mismatch_reverts :
    (executeClaimWithdrawalsTo [1, 2] [1] (2 : Address)).run threeClaimState =
      .revert "ArraysLengthMismatch" threeClaimState := by
  rfl

/-- Existing universal rollback, re-exported. This node does not re-prove
the transaction boundary. -/
theorem every_revert_restores_snapshot (requestIds hints : List Nat)
    (recipient : Address) (state rollback : ContractState) (reason : String)
    (h : (executeClaimWithdrawalsTo requestIds hints recipient).run state =
      .revert reason rollback) : rollback = state :=
  LidoSRv3.Audit.Verity.AddressClaimBatchTx.every_revert_restores_snapshot
    requestIds hints recipient state rollback reason h

end LidoSRv3.Audit.Spec.AddressClaimBatchCorrespondence
