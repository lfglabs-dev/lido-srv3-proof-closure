import LidoSRv3.Audit.Guarantees.POracleMint1
import LidoSRv3.Audit.Guarantees.POracleBound1

/-!
# Node 3 oracle-mint fail-closed vectors

The first mutant substitutes the sum of balances for the computed fee mint.
The second drops the E27-scaled share-rate cap path and treats raw fee wei as
shares.  Each theorem negates the corresponding universal parent shape.
-/

namespace LidoSRv3.Tests.PackN3OracleMintMutants

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.OracleMintCorrespondence

/-- Mutant: derive `sharesMinted` from balances, ignoring fee and share rate. -/
def sumBalancesFrame (balances : List Nat) (_feeWei shareRate : Nat) :
    OracleFrame where
  balances := balances
  sharesMinted := balances.sum
  shareRateDelta := shareRate

/-- Kill-line for P-ORACLE-MINT-1.  All parent binders are retained, but the
E27-fee witness should mint one share while the mutant mints thirty. -/
theorem sum_balances_mutant_refutes_computed_mint_parent :
    ¬ (∀ (balances : List Nat) (feeWei shareRate : Nat),
      (sumBalancesFrame balances feeWei shareRate).sharesMinted =
          mintedShares feeWei shareRate ∧
        (sumBalancesFrame balances feeWei shareRate).shareRateDelta =
          shareRate) := by
  intro hParent
  have hMint := (hParent [10, 20] shareRateScale 1).1
  norm_num [sumBalancesFrame, mintedShares, shareRateScale] at hMint

/-- Mutant: raw fee wei is used as shares, omitting both share-rate scaling
and division by E27. -/
def rawFeeWithoutCap (feeWei _shareRate : Nat) : Nat :=
  feeWei

/-- Kill-line for P-ORACLE-BOUND-1.  The named-cap premise is retained.
At fee/rate/cap `1`, the mutant yields one share while the capped E27 quotient
is zero. -/
theorem raw_fee_mutant_refutes_aggregate_cap_parent :
    ¬ (∀ (feeWei shareRate maxShareRate : Nat),
      shareRate ≤ maxShareRate →
        rawFeeWithoutCap feeWei shareRate ≤
          feeWei * maxShareRate / shareRateScale) := by
  intro hParent
  have hBound := hParent 1 1 1 (by decide)
  norm_num [rawFeeWithoutCap, shareRateScale] at hBound

end LidoSRv3.Tests.PackN3OracleMintMutants
