import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Source.AccountingCorrespondence
import LidoSRv3.Audit.Verity.AddressClaimBatchTx

/-!
# Node 3: fee/shareRate oracle mint correspondence

Spec-plane definitions for the P-ORACLE-SUPPLY-1 parent. The mint is a
*computed* quantity `feeWei * shareRate / E27`, not a free
`sharesToMintAsFees` argument: the Pack E leftover
(`OracleFrame.sharesMinted = argument`) is exactly what this module does
not restate. P-ACCOUNT-1 stays order-only and is not widened here.
-/

namespace LidoSRv3.Audit.Spec.OracleMintCorrespondence

open LidoSRv3.Audit.SolidityAccounting

/-- The existing Lido share-rate scale, `10^27`. Reused from
`AddressClaimBatchTx` rather than re-invented. -/
abbrev E27 : Nat := LidoSRv3.Audit.Verity.AddressClaimBatchTx.E27

theorem e27_pos : 0 < E27 := by decide

/-- Computed mint: the fee in wei converted through the `E27`-scaled share
rate. This is a definition over the inputs, not a transaction argument. -/
def mintedShares (feeWei shareRate : Nat) : Nat :=
  feeWei * shareRate / E27

/-- Spec frame built from the fee and share rate. Unlike Pack E's
`specOfOracle`, `sharesMinted` is computed by `mintedShares` and
`shareRateDelta` records the rate instead of being unmodeled `0`. -/
def specOfMint (i : ReportInput) (feeWei shareRate : Nat) : OracleFrame where
  balances := i.balancesGwei
  sharesMinted := mintedShares feeWei shareRate
  shareRateDelta := shareRate

/-- Non-definitional aggregate cap bound (sanity / Eugene-style aggregate):
under any named cap `maxShareRate` on the share rate, the computed mint is
bounded by the fee converted at the cap. Dropping the `hCap` premise is the
kill-line vector in `PackN3OracleMintMutants`. -/
theorem minted_shares_le_cap (feeWei shareRate maxShareRate : Nat)
    (hCap : shareRate ≤ maxShareRate) :
    mintedShares feeWei shareRate ≤ feeWei * maxShareRate / E27 :=
  Nat.div_le_div_right (Nat.mul_le_mul (Nat.le_refl feeWei) hCap)

/-- Exact-ratio conversion child: when the share rate is the exactly
divisible `E27`-scaled ratio `num / den`, the computed mint agrees with the
classic `feeWei * num / den` conversion. Both sides are load-bearing: the
left side is the frame's computed mint, the right side is the
accounting-plane ratio conversion. Instantiating `num := totalShares`,
`den := totalPooledEther` gives the wei-to-shares reading; instantiating
`num := totalPooledEther`, `den := totalShares` gives the pooled-ether rate
orientation stated in the node brief. -/
theorem minted_shares_exact_ratio (feeWei num den : Nat)
    (hden : 0 < den)
    (hExact : den ∣ num * E27)
    (hDiv : den ∣ feeWei * num) :
    mintedShares feeWei (num * E27 / den) = feeWei * num / den := by
  have hRateMul : num * E27 / den * den = num * E27 :=
    Nat.div_mul_cancel hExact
  have hq : feeWei * num / den * den = feeWei * num :=
    Nat.div_mul_cancel hDiv
  have key : feeWei * (num * E27 / den) = feeWei * num / den * E27 := by
    apply Nat.eq_of_mul_eq_mul_right hden
    calc feeWei * (num * E27 / den) * den
        = feeWei * (num * E27 / den * den) := by
          rw [Nat.mul_assoc]
      _ = feeWei * (num * E27) := by rw [hRateMul]
      _ = feeWei * num * E27 := by rw [Nat.mul_assoc]
      _ = feeWei * num / den * den * E27 := by rw [hq]
      _ = feeWei * num / den * E27 * den := by
          rw [Nat.mul_assoc, Nat.mul_comm den E27, ← Nat.mul_assoc]
  unfold mintedShares
  rw [key, Nat.mul_div_cancel _ e27_pos]

end LidoSRv3.Audit.Spec.OracleMintCorrespondence
