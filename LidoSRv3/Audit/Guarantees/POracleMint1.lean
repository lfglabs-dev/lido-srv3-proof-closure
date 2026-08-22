import LidoSRv3.Audit.Spec.OracleMintCorrespondence

/-!
# P-ORACLE-MINT-1

Supplemental parent for the fee/share-rate mint.  It does not widen
P-ACCOUNT-1 and does not reuse Pack E's free `sharesToMintAsFees` argument.
-/

namespace LidoSRv3.Audit.Guarantees.POracleMint1

open LidoSRv3.Audit.Spec.OracleMintCorrespondence

/-- Supplemental P-ORACLE-MINT-1 parent.  For every balance projection, fee,
and share rate, the constructed Spec frame carries the computed E27-scaled
mint and the supplied share rate. -/
theorem fee_share_rate_computed_mint
    (balances : List Nat) (feeWei shareRate : Nat) :
    (specOfFeeAndShareRate balances feeWei shareRate).sharesMinted =
        mintedShares feeWei shareRate ∧
      (specOfFeeAndShareRate balances feeWei shareRate).shareRateDelta =
        shareRate :=
  computed_mint_frame_correspondence balances feeWei shareRate

end LidoSRv3.Audit.Guarantees.POracleMint1
