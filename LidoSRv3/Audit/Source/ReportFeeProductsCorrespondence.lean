import Verity.Stdlib.Math

/-!
# Checked uint256 fee-product correspondence

This is a deliberately narrow transcription of
`Accounting.sol:317,323,325,331` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

It does not model report admission, storage, fee distribution, or minting.
Its only purpose is to make the Solidity 0.8 checked arithmetic of the fee
products explicit: an overflow, an underflow, or a zero divisor produces no
result, in the same left-to-right order as the source expressions.
-/

namespace LidoSRv3.Audit.Source.ReportFeeProductsCorrespondence

open Verity Verity.Stdlib.Math

abbrev Word := Verity.Core.Uint256

/-- The values read by the four Accounting expressions in scope. -/
structure Input where
  clValidatorsBalance : Word
  clPendingBalance : Word
  withdrawalsVaultTransfer : Word
  principalClBalance : Word
  elRewardsVaultTransfer : Word
  totalFee : Word
  feePrecisionPoints : Word
  postInternalEther : Word
  internalSharesBeforeFees : Word
  deriving Repr, DecidableEq

/-- The profitable-branch intermediates, retained so the correspondence is
about both source products rather than only the final share count. -/
structure Products where
  unifiedClBalance : Word
  totalRewards : Word
  feeEther : Word
  feeShareDenominator : Word
  sharesToMintAsFees : Word
  deriving Repr, DecidableEq

/-- `none` denotes a Solidity 0.8 panic (overflow, underflow, or division by
zero). `some none` is the LIP-12 non-profitable branch; `some (some p)` is the
successful profitable branch. -/
def execute (i : Input) : Option (Option Products) := do
  -- Accounting.sol:317: a checked left-associated uint256 sum.
  let clAndPending <- safeAdd i.clValidatorsBalance i.clPendingBalance
  let unifiedClBalance <- safeAdd clAndPending i.withdrawalsVaultTransfer
  if unifiedClBalance ≤ i.principalClBalance then
    pure none
  else
    -- Accounting.sol:323: checked subtraction before the checked reward add.
    let clRewards <- safeSub unifiedClBalance i.principalClBalance
    let totalRewards <- safeAdd clRewards i.elRewardsVaultTransfer
    -- Accounting.sol:325: checked product before checked division.
    let feeProduct <- safeMul totalRewards i.totalFee
    let feeEther <- safeDiv feeProduct i.feePrecisionPoints
    -- Accounting.sol:331: checked product, then checked denominator subtraction,
    -- then checked division.  Do not commute these operations.
    let shareProduct <- safeMul feeEther i.internalSharesBeforeFees
    let feeShareDenominator <- safeSub i.postInternalEther feeEther
    let sharesToMintAsFees <- safeDiv shareProduct feeShareDenominator
    some (some ⟨unifiedClBalance, totalRewards, feeEther,
      feeShareDenominator, sharesToMintAsFees⟩)

/-- The source-facing result: non-profitable reports produce zero shares;
successful profitable reports return precisely the L331 quotient. -/
def sharesToMintAsFees (i : Input) : Option Word := do
  match <- execute i with
  | none => pure 0
  | some products => pure products.sharesToMintAsFees

/-- The LIP-12 branch has no fee product and returns the Solidity default
`sharesToMintAsFees == 0`, provided the L317 sum itself did not panic. -/
theorem nonprofitable_returns_zero (i : Input)
    (h : execute i = some none) : sharesToMintAsFees i = some 0 := by
  simp [sharesToMintAsFees, h]

/-- Successful profitable execution exposes exactly the L331 product quotient;
this is a projection theorem rather than an unchecked Nat approximation. -/
theorem successful_result_is_l331_quotient (i : Input) (p : Products)
    (h : execute i = some (some p)) : sharesToMintAsFees i = some p.sharesToMintAsFees := by
  simp [sharesToMintAsFees, h]

/-- A zero fee precision point is rejected on every profitable path that
reaches L325; Lean's total natural-number division is never used here. -/
theorem zero_precision_reverts_on_profitable_path (i : Input)
    (hRun : ∃ u, safeAdd i.clValidatorsBalance i.clPendingBalance = some u ∧
      ∃ unified, safeAdd u i.withdrawalsVaultTransfer = some unified ∧
        i.principalClBalance < unified)
    (hPrecision : i.feePrecisionPoints = 0) : execute i = none := by
  rcases hRun with ⟨u, hu, unified, hUnified, hProfit⟩
  simp [execute, hu, hUnified, Nat.not_le.mpr hProfit, hPrecision, safeDiv]

end LidoSRv3.Audit.Source.ReportFeeProductsCorrespondence
