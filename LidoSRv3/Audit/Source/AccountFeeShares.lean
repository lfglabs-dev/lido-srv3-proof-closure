import LidoSRv3.Audit.Source.ReportFeeProductsCorrespondence
import LidoSRv3.Audit.Verity.HandleOracleReportTx
import Verity.Core
import Verity.Stdlib.Math

/-!
# P-ACCOUNT-1 derived `sharesToMintAsFees` consumer

Additive consumer beside the registered parent
`HandleOracleReportTx.handleOracleReport`.  The parent still takes
`sharesToMintAsFees : Nat` as a free argument
(`HandleOracleReportTx.lean:239`; `AccountingCorrespondence.successfulSteps`).
This module derives that word from the pinned `_calculateProtocolFees`
products and feeds it into the unchanged parent.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `Accounting.sol:263-303` `_calculateProtocolFees` (body from 265)
* `Accounting.sol:306-333` `_calculateTotalProtocolFeeShares`
* products at `Accounting.sol:317` (unified CL sum), `323` (totalRewards),
  `325` (`feeEther = totalRewards * totalFee / precisionPoints`),
  `331` (`sharesToMintAsFees = feeEther * internalShares / (postInternalEther - feeEther)`)
* `StakingRouter.sol:808-873` `getStakingRewardsDistribution`
  (`totalFee` accumulated at 854, `precisionPoints = FEE_PRECISION_POINTS` at 825,
  cap `assert` at 862)

`totalFee` / `precisionPoints` remain the getter **outputs as inputs** on
`FeeInput`.  This lot does not re-execute the getter against written router
storage; that re-read is the separate P-ACCOUNT-1 missing entry.
-/

namespace LidoSRv3.Audit.Source.AccountFeeShares

open _root_.Verity
open _root_.Verity.Stdlib.Math
open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.Verity.HandleOracleReportTx
open LidoSRv3.Audit.Source.ReportFeeProductsCorrespondence

abbrev FeeInput := ReportFeeProductsCorrespondence.Input
abbrev Word := Verity.Core.Uint256

/-- Accounting.sol:263-303 `_calculateProtocolFees` via the L317/323/325/331
products.  `none` is a Solidity 0.8 panic (overflow, underflow, or division
by zero).  `some 0` is the LIP-12 non-profitable branch
(`unifiedClBalance ≤ principalClBalance` at Accounting.sol:322). -/
def derivedSharesToMintAsFees (fee : FeeInput) : Option Word :=
  ReportFeeProductsCorrespondence.sharesToMintAsFees fee

/-- Parent `handleOracleReport` (`Accounting.sol:135-144` /
`Accounting.sol:403-413`) with the mint taken from the source products,
never as a free `Nat`.  A product panic reverts the pre-state (fail-closed;
not an always-success stub).  The revert string is model-local: pinned
solc0.8.9 emits a panic opcode, not this literal. -/
def handleOracleReportDerived (i : ReportInput) (fee : FeeInput)
    (failAfterWrites : Bool := false) : Verity.Contract Result :=
  match derivedSharesToMintAsFees fee with
  | none => fun snapshot => .revert "FEE_PANIC" snapshot
  | some w => handleOracleReport i w.val failAfterWrites

theorem derived_eq_source_products (fee : FeeInput) :
    derivedSharesToMintAsFees fee =
      ReportFeeProductsCorrespondence.sharesToMintAsFees fee := rfl

/-- Accounting.sol:322 LIP-12: non-profitable reports mint zero fee shares. -/
theorem derived_nonprofitable_zero (fee : FeeInput)
    (h : ReportFeeProductsCorrespondence.execute fee = some none) :
    derivedSharesToMintAsFees fee = some 0 :=
  ReportFeeProductsCorrespondence.nonprofitable_returns_zero fee h

/-- Accounting.sol:331: a successful profitable execution is exactly the
checked `feeEther * internalShares / (postInternalEther - feeEther)`
quotient, not an unchecked `Nat` approximation. -/
theorem derived_profitable_is_l331 (fee : FeeInput)
    (p : ReportFeeProductsCorrespondence.Products)
    (h : ReportFeeProductsCorrespondence.execute fee = some (some p)) :
    derivedSharesToMintAsFees fee = some p.sharesToMintAsFees :=
  ReportFeeProductsCorrespondence.successful_result_is_l331_quotient fee p h

/-- Accounting.sol:325: zero `precisionPoints` panics on every profitable
path that reaches the fee product; Lean `Nat` division is never used. -/
theorem derived_zero_precision_is_panic (fee : FeeInput)
    (hRun : ∃ u, safeAdd fee.clValidatorsBalance fee.clPendingBalance = some u ∧
      ∃ unified, safeAdd u fee.withdrawalsVaultTransfer = some unified ∧
        fee.principalClBalance < unified)
    (hPrecision : fee.feePrecisionPoints = 0) :
    derivedSharesToMintAsFees fee = none := by
  have hexec :=
    ReportFeeProductsCorrespondence.zero_precision_reverts_on_profitable_path
      fee hRun hPrecision
  simp [derivedSharesToMintAsFees, ReportFeeProductsCorrespondence.sharesToMintAsFees,
    hexec]

/-- Product panic never reaches the parent mint (Accounting.sol:403). -/
theorem product_panic_reverts
    (i : ReportInput) (fee : FeeInput) (state : Verity.ContractState)
    (h : derivedSharesToMintAsFees fee = none) :
    (handleOracleReportDerived i fee).run state = .revert "FEE_PANIC" state := by
  simp [handleOracleReportDerived, h, Verity.Contract.run]

theorem handleOracleReportDerived_eq_parent
    (i : ReportInput) (fee : FeeInput) (w : Word)
    (h : derivedSharesToMintAsFees fee = some w) :
    handleOracleReportDerived i fee = handleOracleReport i w.val := by
  simp [handleOracleReportDerived, h]

/-- `observe` of the derived consumer equals the independently stated
`sourceView` at the **derived** mint, not at a caller-supplied `Nat`.
Cites `verity_tx_simulates_pinned_source`; does not edit the parent. -/
theorem handleOracleReportDerived_observe
    (i : ReportInput) (fee : FeeInput) (w : Word) (state : Verity.ContractState)
    (h : derivedSharesToMintAsFees fee = some w) :
    observe i ((handleOracleReportDerived i fee).run state) =
      sourceView i w.val := by
  rw [handleOracleReportDerived_eq_parent i fee w h]
  exact verity_tx_simulates_pinned_source i w.val state

/-- Mint-after-read for the derived consumer
(`Accounting.sol:277` rewards read before `Accounting.sol:403-413` mint).
Cites the registered parent `mintAfterReadDiscipline_holds`; does not edit
`mint_after_read_discipline`. -/
theorem handleOracleReportDerived_mint_after_read
    (i : ReportInput) (fee : FeeInput) (state : Verity.ContractState) :
    match (handleOracleReportDerived i fee).run state with
    | .success _ dirty =>
        mintAfterRead (dirty.readSlot rewardsReadSlot) (dirty.readSlot rewardsMintedSlot)
    | .revert _ _ => True := by
  cases hder : derivedSharesToMintAsFees fee with
  | none =>
    simp [handleOracleReportDerived, hder, Verity.Contract.run]
  | some w =>
    simp [handleOracleReportDerived, hder]
    have hparent := mintAfterReadDiscipline_holds i w.val state
    cases hrun : (handleOracleReport i w.val).run state with
    | success _ dirty =>
      simp [hrun] at hparent
      exact hparent
    | revert _ _ => trivial

/-- Kill-line for the targeted gap: a free `Nat` can mint when the pinned
products (Accounting.sol:322 LIP-12) compute zero.  The derived consumer
follows the products; the parent follows the argument. -/
theorem free_argument_mints_when_source_is_zero
    (i : ReportInput) (fee : FeeInput) (state : Verity.ContractState)
    (accepted : AcceptedReport)
    (hAccept : accept i = some accepted)
    (hNon : ReportFeeProductsCorrespondence.execute fee = some none)
    (rogue : Nat) (hRogue : 0 < rogue) :
    .rewardsMinted ∈ (observe i ((handleOracleReport i rogue).run state)).steps ∧
      .rewardsMinted ∉
        (observe i ((handleOracleReportDerived i fee).run state)).steps := by
  have hDer : derivedSharesToMintAsFees fee = some 0 :=
    derived_nonprofitable_zero fee hNon
  have hParent := verity_tx_simulates_pinned_source i rogue state
  have hWrap := handleOracleReportDerived_observe i fee 0 state hDer
  constructor
  · simp [hParent, sourceView, hAccept, successfulSteps, hRogue]
  · simp [hWrap, sourceView, hAccept, successfulSteps]

/-- `FeeInput.totalFee` / `feePrecisionPoints` are the words the committed
getter `StakingRouter.getStakingRewardsDistribution` (808-873) returns, via
the existing a3 bridge.  They are not a second free mint argument. -/
theorem getter_outputs_feed_products
    (r : AccountAddress.ReportWriteFee.ReportWei)
    (d : AccountAddress.ReportWriteFee.Distribution)
    (fee : FeeInput)
    (hFit : r.clValidatorsBalance ≤ Verity.Core.MAX_UINT256 ∧
      r.clPendingBalance ≤ Verity.Core.MAX_UINT256 ∧
      r.withdrawalsVaultTransfer ≤ Verity.Core.MAX_UINT256 ∧
      r.principalClBalance ≤ Verity.Core.MAX_UINT256 ∧
      r.elRewardsVaultTransfer ≤ Verity.Core.MAX_UINT256 ∧
      d.totalFee ≤ Verity.Core.MAX_UINT256 ∧
      d.precisionPoints ≤ Verity.Core.MAX_UINT256 ∧
      r.postInternalEther ≤ Verity.Core.MAX_UINT256 ∧
      r.internalSharesBeforeFees ≤ Verity.Core.MAX_UINT256)
    (h : feeProductsFromCommittedGetter r d = some fee) :
    fee.totalFee = Verity.Core.Uint256.ofNat d.totalFee ∧
      fee.feePrecisionPoints = Verity.Core.Uint256.ofNat d.precisionPoints := by
  simp [feeProductsFromCommittedGetter, hFit] at h
  cases h
  exact ⟨rfl, rfl⟩

#print axioms derived_eq_source_products
#print axioms derived_nonprofitable_zero
#print axioms derived_profitable_is_l331
#print axioms derived_zero_precision_is_panic
#print axioms product_panic_reverts
#print axioms handleOracleReportDerived_eq_parent
#print axioms handleOracleReportDerived_observe
#print axioms handleOracleReportDerived_mint_after_read
#print axioms free_argument_mints_when_source_is_zero
#print axioms getter_outputs_feed_products

end LidoSRv3.Audit.Source.AccountFeeShares
