import LidoSRv3.Audit.Source.AccountFeeShares

/-! P-ACCOUNT-1 derived-fee fail-closed vectors.

The registered parent still takes a free `sharesToMintAsFees : Nat`.
These mutants show that the derived consumer follows pinned
`_calculateProtocolFees` products (Accounting.sol:317/323/325/331) and
that a free argument can disagree with that derivation.
-/

namespace LidoSRv3.Tests.AccountFeeSharesMutants

open _root_.Verity
open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.Verity.HandleOracleReportTx
open LidoSRv3.Audit.Source.ReportFeeProductsCorrespondence
open LidoSRv3.Audit.Source.AccountFeeShares

private def word (n : Nat) : LidoSRv3.Audit.Source.AccountFeeShares.Word :=
  Verity.Core.Uint256.ofNat n

private def valid : ReportInput := ⟨[1, 2], [1, 2], [10, 20]⟩

/-- Profitable products: unified CL = 20 > principal 10, totalRewards = 10,
`feeEther = 10 * 1 / 1 = 10`, `shares = 10 * 50 / 90 = 5`
(Accounting.sol:317,323,325,331). -/
private def profitableFee : FeeInput where
  clValidatorsBalance := word 20
  clPendingBalance := word 0
  withdrawalsVaultTransfer := word 0
  principalClBalance := word 10
  elRewardsVaultTransfer := word 0
  totalFee := word 1
  feePrecisionPoints := word 1
  postInternalEther := word 100
  internalSharesBeforeFees := word 50

/-- LIP-12 non-profitable: unified CL = 20 ≤ principal 20 (Accounting.sol:322). -/
private def nonprofitableFee : FeeInput :=
  { profitableFee with principalClBalance := word 20 }

/-- Zero precision on a profitable path panics at Accounting.sol:325. -/
private def panicFee : FeeInput :=
  { profitableFee with feePrecisionPoints := word 0 }

private def derivedView (i : ReportInput) (fee : FeeInput) : View :=
  observe i ((handleOracleReportDerived i fee).run defaultState)

/-- Happy path: derived mint is the L331 quotient 5, and the parent mint
step is present. -/
example :
    derivedSharesToMintAsFees profitableFee = some (word 5) ∧
      derivedView valid profitableFee =
        ⟨.committed, [10, 20], 30,
          [.balancesWritten [10, 20], .accountingCalled,
            .rewardsRead [10, 20], .rewardsMinted]⟩ := by native_decide

/-- LIP-12: non-profitable products mint zero and skip
`reportRewardsMinted` (Accounting.sol:403-413). -/
example :
    derivedSharesToMintAsFees nonprofitableFee = some 0 ∧
      derivedView valid nonprofitableFee =
        ⟨.committed, [10, 20], 30,
          [.balancesWritten [10, 20], .accountingCalled,
            .rewardsRead [10, 20]]⟩ := by native_decide

/-- Product panic is fail-closed: the wrapper reverts the pre-state, it
does not stub success or mint a default.  The revert equality is `rfl`
via `product_panic_reverts` (`ContractState` is not `DecidableEq`). -/
example : derivedSharesToMintAsFees panicFee = none := by native_decide

example :
    (handleOracleReportDerived valid panicFee).run defaultState =
      .revert "FEE_PANIC" defaultState :=
  product_panic_reverts valid panicFee defaultState (by native_decide)

/-- Free-argument mutant: balances `[10, 20]` compute 0 fee shares, but the
parent still mints when the harness passes `7`.  The derived consumer does
not.  This is report/P-ACCOUNT-1.md issue 11, now a named kill-line. -/
example :
    derivedSharesToMintAsFees nonprofitableFee = some 0 ∧
      observe valid ((handleOracleReport valid 7).run defaultState) =
        ⟨.committed, [10, 20], 30,
          [.balancesWritten [10, 20], .accountingCalled,
            .rewardsRead [10, 20], .rewardsMinted]⟩ ∧
      derivedView valid nonprofitableFee =
        ⟨.committed, [10, 20], 30,
          [.balancesWritten [10, 20], .accountingCalled,
            .rewardsRead [10, 20]]⟩ := by native_decide

/-- The derived consumer keeps the parent clock order on the profitable
witness: read tick 3 before mint tick 4 (Accounting.sol:277 before 403).
`mintAfterRead` itself is not `Decidable`; the ticks are. -/
example :
    let dirty := match (handleOracleReportDerived valid profitableFee).run defaultState with
      | .success _ s => s
      | .revert _ s => s
    dirty.readSlot rewardsReadSlot = 3 ∧ dirty.readSlot rewardsMintedSlot = 4 := by
  native_decide

#print axioms LidoSRv3.Audit.Source.AccountFeeShares.derived_eq_source_products
#print axioms LidoSRv3.Audit.Source.AccountFeeShares.derived_nonprofitable_zero
#print axioms LidoSRv3.Audit.Source.AccountFeeShares.derived_profitable_is_l331
#print axioms LidoSRv3.Audit.Source.AccountFeeShares.derived_zero_precision_is_panic
#print axioms LidoSRv3.Audit.Source.AccountFeeShares.product_panic_reverts
#print axioms LidoSRv3.Audit.Source.AccountFeeShares.handleOracleReportDerived_eq_parent
#print axioms LidoSRv3.Audit.Source.AccountFeeShares.handleOracleReportDerived_observe
#print axioms LidoSRv3.Audit.Source.AccountFeeShares.handleOracleReportDerived_mint_after_read
#print axioms LidoSRv3.Audit.Source.AccountFeeShares.free_argument_mints_when_source_is_zero
#print axioms LidoSRv3.Audit.Source.AccountFeeShares.getter_outputs_feed_products

end LidoSRv3.Tests.AccountFeeSharesMutants
