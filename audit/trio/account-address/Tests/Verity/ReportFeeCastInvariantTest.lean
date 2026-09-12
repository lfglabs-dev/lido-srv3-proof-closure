import LidoSRv3.Audit.Guarantees.PAccount1ActualFeeCasts

namespace AccountAddress.Tests.Verity.ReportFeeCastInvariantTest
open AccountAddress.PAccount1 AccountAddress.ReportWriteFee
open AccountAddress.ReportFeeCastInvariant

private instance (L : Layout) (s : Core) (id : Nat) : Decidable (ExactCasts L s id) := by
  unfold ExactCasts
  infer_instance

private def separate : Layout := ⟨100, fun id => 200 + 16 * id⟩
private def moduleAlias : Layout := ⟨100, fun _ => 200⟩
private def routerAlias : Layout := ⟨100, fun _ => 101⟩
private def maxFees : StorageWord := ⟨(two16-1)*two160 + (two16-1)*two176, by decide⟩
private def initial (L : Layout) : Core :=
  (Core.write ⟨[]⟩ (L.moduleConfigSlot 1) maxFees).write (L.moduleConfigSlot 2) maxFees

private def inspect (L : Layout) (reg balances : List Nat) (expectedModule expectedTotal : Nat) : Bool :=
  match reportValidatorBalances L reg reg balances (initial L) with
  | .reverted _ _ => false
  | .committed post => decide (
      moduleAllocationWei L post 1 = fromGwei expectedModule ∧
      routerTotalWei L post = fromGwei expectedTotal ∧
      ExactCasts L post 1 ∧ ExactCasts L post 2)

theorem module_slot_collision : inspect moduleAlias [1,2] [7,13] 13 20 = true := by decide +kernel
theorem router_slot_collision : inspect routerAlias [1,2] [7,13] 20 20 = true := by decide +kernel
theorem duplicate_registered_ids : inspect separate [1,1] [7,13] 13 20 = true := by decide +kernel
/-- Maximum source-admitted row is 10^18 gwei, not uint64Max. Fee fields take
all sixteen bits; no assumed basis-point cap is used for nontruncation. -/
theorem max_admitted_row_and_fee_fields :
    inspect separate [1,2] [maxValueGwei,maxValueGwei] maxValueGwei (2*maxValueGwei) = true := by decide +kernel
theorem zero_report_and_skipped_getter : (match
    reportValidatorBalances routerAlias [1,2] [1,2] [0,0] (initial routerAlias) with
  | .reverted _ _ => false
  | .committed post => match getStakingRewardsDistribution routerAlias [1,2] post with
    | .error _ => false
    | .ok d => decide (ExactCasts routerAlias post 1 ∧ d = ⟨[],[],[],0,FEE_PRECISION_POINTS⟩)) = true := by
  decide +kernel

/-- A positive actual report/getter/checked fee/mint execution, not only an
isolated arithmetic helper fixture. -/
private def world : ReportFeeMint.World := {
  router := Core.write ⟨[]⟩ (separate.moduleConfigSlot 1)
    ⟨170 + 500 * two160 + 500 * two176, by decide⟩
  steth := {
    storage := (Core.write ⟨[]⟩ StETHMintShares.totalSharesPosition
      ⟨4 * StETHMintShares.two128 + 10, by decide⟩).write
      StETHMintShares.bufferedEtherAndDepositedPostReportPosition ⟨100,by decide⟩
    shares := fun a => if a = 7 then 5 else 0
    locatorAccounting := 7, selfAddress := 8, activeFlag := true } }
private def input : ReportFeeMint.Input := {
  accountingAddress := 7, layout := separate, registeredModuleIds := [1],
  reportedModuleIds := [1], balancesGwei := [20], report := ⟨100,0,0,0,0,110,20⟩ }

theorem actual_positive_mint_casts : (match ReportFeeMint.handleOracleReportFromCommittedFeeProducts input world with
  | .reverted _ _ => false
  | .committed post fee events => decide (fee.sharesToMintAsFees = 2 ∧
      StETHMintShares.totalShares post.steth = 12 ∧ ExactCasts separate post.router 1 ∧
      events = [.transfer 0 7 25,.transferShares 0 7 2])) = true := by decide +kernel

theorem public_consumer (post : ReportFeeMint.World) (fee : FeeResult) (events : List StETHMintShares.Event)
    (h : ReportFeeMint.handleOracleReportFromCommittedFeeProducts input world = .committed post fee events) :
    ReportFeeMint.Success input world post fee events ∧
    ∀ id ∈ input.registeredModuleIds, ExactCasts input.layout post.router id :=
  LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_casts input world post fee events h

#print axioms module_slot_collision
#print axioms router_slot_collision
#print axioms duplicate_registered_ids
#print axioms max_admitted_row_and_fee_fields
#print axioms zero_report_and_skipped_getter
#print axioms actual_positive_mint_casts
#print axioms public_consumer
end AccountAddress.Tests.Verity.ReportFeeCastInvariantTest
