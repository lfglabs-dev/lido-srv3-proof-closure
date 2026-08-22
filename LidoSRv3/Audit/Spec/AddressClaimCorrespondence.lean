import LidoSRv3.Audit.Verity.AddressClaimBatchTx

/-!
# Pack D: live claim-batch read→payout correspondence

Unregistered child. It does not replace the registered P-ADDRESS-1 parent,
does not add a pause row, and does not invent a guarantee ID.
-/

namespace LidoSRv3.Audit.Spec.AddressClaimCorrespondence

open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open _root_.Verity

/-- Storage-backed claimable amounts of the pinned two-item witness, in
loop order. -/
def twoClaimPayouts : List (Option Nat) :=
  [claimableEther (readRequest twoClaimState 1 1),
   claimableEther (readRequest twoClaimState 2 1)]

/-- Unregistered child: the two-item live batch journals exactly the
`claimableEther` of the pre-state `readRequest`s, to the supplied recipient,
and marks both requests claimed. -/
theorem two_claim_payouts_match_reads :
    twoClaimPayouts = [some 30, some 40] ∧
      observe [1, 2]
          ((executeClaimWithdrawalsTo [1, 2] [1, 1] (2 : Address)).run twoClaimState) =
        ⟨.committed, [true, true], 0,
          [payoutEntry (2 : Address) 30, payoutEntry (2 : Address) 40]⟩ := by
  refine ⟨by decide, two_claim_batch_observe⟩

end LidoSRv3.Audit.Spec.AddressClaimCorrespondence
