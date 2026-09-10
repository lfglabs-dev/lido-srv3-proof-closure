import ReportFeeMint

namespace AccountActualMintRegression
open AccountAddress.ReportWriteFee AccountAddress.StETHMintShares
open AccountAddress.ReportFeeMint

def layout : Layout := ⟨1000, fun id => 2000 + 16 * id⟩
def router : Core := ⟨[(layout.moduleConfigSlot 1,
  ⟨170 + 500 * two160 + 500 * two176, by decide⟩)]⟩
def steth : State := {
  storage := (Core.write ⟨[]⟩ totalSharesPosition ⟨4 * two128 + 10, by decide⟩).write
    bufferedEtherAndDepositedPostReportPosition ⟨100, by decide⟩
  shares := fun a => if a = 7 then 5 else 0
  locatorAccounting := 7, selfAddress := 8, activeFlag := true }
def world : World := ⟨router,steth⟩
def input : Input := {
  accountingAddress := 7, layout := layout, registeredModuleIds := [1],
  reportedModuleIds := [1], balancesGwei := [20],
  report := ⟨100,0,0,0,0,110,20⟩ }

def result := handleOracleReportFromCommittedFeeProducts input world

theorem same_world_mint_and_rate : (match result with
  | .committed post fee events =>
    decide ((post.router.read layout.routerAccountingSlot).val = 20 ∧
    fee.sharesToMintAsFees = 2 ∧ totalShares post.steth = 12 ∧
    externalShares post.steth = 4 ∧ post.steth.shares 7 = 7 ∧ post.steth.shares 9 = 0 ∧
    events = [.transfer 0 7 25, .transferShares 0 7 2])
  | .reverted _ _ => false) = true := by decide +kernel

theorem mismatched_accounting_rejects : (match handleOracleReportFromCommittedFeeProducts
    {input with accountingAddress := 6} world with
  | .reverted (.mint .notAccounting) rollback => decide (rollback.router = world.router ∧ rollback.steth.storage = steth.storage)
  | _ => false) = true := by decide +kernel

theorem zero_fee_skips_mint_auth : (match handleOracleReportFromCommittedFeeProducts
    {input with accountingAddress := 6, report := {input.report with clValidatorsBalance := 0}} world with
  | .committed post fee events => decide (fee.sharesToMintAsFees = 0 ∧ post.steth.storage = steth.storage ∧ events = [])
  | _ => false) = true := by decide +kernel

theorem packed_overflow_restores_router : (match handleOracleReportFromCommittedFeeProducts input
    {world with steth := {steth with storage := steth.storage.write totalSharesPosition ⟨two128-1, by decide⟩}} with
  | .reverted (.mint .sharesOverflow) rollback => decide (rollback.router = world.router)
  | _ => false) = true := by decide +kernel

theorem fee_word_overflow_rejects : (match handleOracleReportFromCommittedFeeProducts
    {input with report := {input.report with clValidatorsBalance := two256}} world with
  | .reverted .feeArithmetic rollback => decide (rollback.router = world.router)
  | _ => false) = true := by decide +kernel

theorem distribution_product_checked : checkedFeeResultOf
  ⟨[170],[1],[2],2,10^20⟩ (two256-1) = none := by decide +kernel

theorem event_failure_restores_updates : (match handleOracleReportFromCommittedFeeProducts input
    {world with steth := {steth with storage := steth.storage.write totalSharesPosition ⟨12 * two128 + 10, by decide⟩}} with
  | .reverted (.mint .zeroShareRateDenominator) rollback => decide
      (rollback.router = world.router ∧ rollback.steth.shares 7 = 5 ∧ totalShares rollback.steth = 10)
  | _ => false) = true := by decide +kernel

theorem mapping_overflow_restores_packed_word : (match handleOracleReportFromCommittedFeeProducts input
    {world with steth := {steth with shares := fun a => if a = 7 then two256-1 else 0}} with
  | .reverted (.mint .safeMathAddOverflow) rollback => decide
      (rollback.router = world.router ∧ totalShares rollback.steth = 10 ∧ externalShares rollback.steth = 4)
  | _ => false) = true := by decide +kernel

#print axioms event_failure_restores_updates
#print axioms mapping_overflow_restores_packed_word
#print axioms same_world_mint_and_rate
#print axioms mismatched_accounting_rejects
#print axioms zero_fee_skips_mint_auth
#print axioms packed_overflow_restores_router
#print axioms fee_word_overflow_rejects
#print axioms distribution_product_checked
end AccountActualMintRegression
