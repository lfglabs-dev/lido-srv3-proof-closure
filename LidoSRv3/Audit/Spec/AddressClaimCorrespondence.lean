import LidoSRv3.Audit.Verity.AddressClaimBatchTx

namespace LidoSRv3.Audit.Spec.AddressClaimCorrespondence
open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open _root_.Verity

/-- Actual physical claim success determines its payout and final locked write.
This replaces the former unproved finite storage-only CALL-journal assertion. -/
theorem actual_claim_payout_matches_locked_write (requestId hint : Nat) (recipient : Address)
    (before after : ContractState) (payout : Nat)
    (h : claimOne requestId hint recipient before = .success payout after) :
    ∃ removed, prepareClaim requestId hint recipient before = .success payout removed ∧
      payout ≤ (removed.readSlot lockedEtherAmountPosition).val ∧
      payout < 2 ^ 256 ∧
      after = removed.writeSlot lockedEtherAmountPosition
        (.ofNat ((removed.readSlot lockedEtherAmountPosition).val - payout)) :=
  claimOne_success_storage requestId hint recipient before after payout h
end LidoSRv3.Audit.Spec.AddressClaimCorrespondence
