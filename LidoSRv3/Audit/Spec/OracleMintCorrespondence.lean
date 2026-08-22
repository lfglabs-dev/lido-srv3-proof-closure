import LidoSRv3.Audit.Spec.OracleFrameCorrespondence
import LidoSRv3.Audit.Verity.AddressClaimBatchTx

/-!
# Node 3: computed oracle mint correspondence

This is separate from Pack E's argument-projection frame.  Here both the fee
and share rate are inputs to the computation, and the frame records the
computed quotient and the supplied share rate.
-/

namespace LidoSRv3.Audit.Spec.OracleMintCorrespondence

open LidoSRv3.Audit.Spec

/-- Lido's share-rate precision, equal to the `E27` used by the address-claim
transaction. -/
def shareRateScale : Nat := 10 ^ 27

/-- Shares minted from a fee amount and the report's share rate. -/
def mintedShares (feeWei shareRate : Nat) : Nat :=
  feeWei * shareRate / shareRateScale

/-- A Spec oracle frame whose mint is computed from fee and share rate.
Unlike Pack E's `specOfOracle`, the minted value is not a free argument. -/
def specOfFeeAndShareRate (balances : List Nat) (feeWei shareRate : Nat) :
    OracleFrame where
  balances := balances
  sharesMinted := mintedShares feeWei shareRate
  shareRateDelta := shareRate

/-- The named scale is the same `E27` used by `AddressClaimBatchTx`. -/
theorem share_rate_scale_matches_address_claim :
    shareRateScale =
      LidoSRv3.Audit.Verity.AddressClaimBatchTx.E27 := by
  norm_num [shareRateScale, LidoSRv3.Audit.Verity.AddressClaimBatchTx.E27]

/-- The computed frame projects exactly the fee/share-rate mint and records
the supplied share rate. -/
theorem computed_mint_frame_correspondence
    (balances : List Nat) (feeWei shareRate : Nat) :
    (specOfFeeAndShareRate balances feeWei shareRate).sharesMinted =
        mintedShares feeWei shareRate ∧
      (specOfFeeAndShareRate balances feeWei shareRate).shareRateDelta =
        shareRate :=
  ⟨rfl, rfl⟩

/-- P-ACCOUNT-1 remains the independently registered order-only parent.
This node only cites that fact; it does not add mint arithmetic to it. -/
theorem account_order_parent_cited :
    LidoSRv3.Audit.Verity.HandleOracleReportTx.mintAfterReadDiscipline :=
  OracleFrameCorrespondence.account_parent_remains_order_only

end LidoSRv3.Audit.Spec.OracleMintCorrespondence
