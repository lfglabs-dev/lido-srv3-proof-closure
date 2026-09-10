import LidoSRv3.Audit.Guarantees.PAccount1CheckedFeeSplit
import Tests.Verity.ReportFeeMintTest

namespace AccountCheckedSplitRegression
open AccountAddress.ReportWriteFee AccountAddress.StETHMintShares
open AccountAddress.ReportFeeMint AccountAddress.ReportFeeCheckedSplit

/-- Both floors round down; treasury receives the exact remainder. -/
theorem nontrivial_rounding : checkedFeeResultOf ⟨[17,18],[1,2],[2,3],7,100⟩ 11 =
    some ⟨11,[17,18],[1,2],[3,4],4⟩ := by decide +kernel

theorem zero_row_retains_position : checkedFeeResultOf ⟨[17,18,19],[1,2,3],[2,0,3],7,100⟩ 11 =
    some ⟨11,[17,18,19],[1,2,3],[3,0,4],4⟩ := by decide +kernel

/-- The source's zero-mint branch skips even the total-fee assertion. -/
theorem zero_mint_skips_distribution : checkedFeeResultOf ⟨[17],[1],[3],0,100⟩ 0 =
    some ⟨0,[],[],[],0⟩ := by decide +kernel

theorem checked_product_rejects : checkedFeeResultOf ⟨[17],[1],[2],2,100⟩ (two256-1) = none := by decide +kernel

theorem checked_sum_rejects : checkedFeeResultOf ⟨[17,18],[1,2],[1,1],1,100⟩ (two256-1) = none := by decide +kernel

theorem checked_treasury_subtraction_rejects : checkedFeeResultOf ⟨[17],[1],[2],1,100⟩ 10 = none := by decide +kernel

def router : Core := ⟨[
  (AccountActualMintRegression.layout.moduleConfigSlot 1,⟨170+1000*two160,by decide⟩),
  (AccountActualMintRegression.layout.moduleConfigSlot 2,⟨180+1000*two176,by decide⟩),
  (AccountActualMintRegression.layout.moduleConfigSlot 3,⟨190+500*two160+500*two176,by decide⟩)]⟩
def world : World := ⟨router,AccountActualMintRegression.steth⟩
def input : Input := {AccountActualMintRegression.input with
  registeredModuleIds := [1,2,3],reportedModuleIds := [1,2,3],balancesGwei := [1,1,2],
  report := {AccountActualMintRegression.input.report with internalSharesBeforeFees := 100}}
def result := handleOracleReportFromCommittedFeeProducts input world

/-- Actual report/getter/checked products/mint, with two rounding losses and
one zero-fee row; the same ten shares are minted and partitioned 2/0/2 + 6. -/
theorem actual_multirow_mint_split : (match result with
  | .committed post fee events => decide
    (fee = ⟨10,[170,180,190],[1,2,3],[2,0,2],6⟩ ∧
     totalShares post.steth = 20 ∧ post.steth.shares 7 = 15 ∧
     events = [.transfer 0 7 62,.transferShares 0 7 10])
  | .reverted _ _ => false) = true := by decide +kernel

theorem actual_multirow_joint_consumer :
    match result with
    | .committed post fee events => AccountAddress.ReportFeeCheckedSplit.Success input world post fee events
    | .reverted _ _ => False := by
  cases hr : result with
  | committed post fee events =>
    exact LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_checked_split input world post fee events hr
  | reverted e rollback =>
    have h := actual_multirow_mint_split
    rw [hr] at h
    cases h

theorem actual_zero_skip_retained : (match handleOracleReportFromCommittedFeeProducts
    {input with accountingAddress := 6,report := {input.report with clValidatorsBalance := 0}} world with
  | .committed post fee events => decide
    (fee = ⟨0,[],[],[],0⟩ ∧ post.steth.storage = world.steth.storage ∧ events = [])
  | .reverted _ _ => false) = true := by decide +kernel

theorem actual_arithmetic_reject_restores : (match handleOracleReportFromCommittedFeeProducts
    {input with report := {input.report with internalSharesBeforeFees := two256-1}} world with
  | .reverted .feeArithmetic rollback => decide (rollback.router = world.router ∧ rollback.steth.storage = world.steth.storage)
  | _ => false) = true := by decide +kernel

#print axioms nontrivial_rounding
#print axioms zero_row_retains_position
#print axioms zero_mint_skips_distribution
#print axioms checked_product_rejects
#print axioms checked_sum_rejects
#print axioms checked_treasury_subtraction_rejects
#print axioms actual_multirow_mint_split
#print axioms actual_multirow_joint_consumer
#print axioms actual_zero_skip_retained
#print axioms actual_arithmetic_reject_restores
end AccountCheckedSplitRegression
