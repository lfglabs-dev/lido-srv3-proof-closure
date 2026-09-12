import LidoSRv3.Audit.Guarantees.PAccount1FeeDistribution
import Tests.Verity.ReportFeeCheckedSplitTest

namespace AccountFeeDistributionRegression
open AccountAddress ReportWriteFee StETHMintShares
open AccountCheckedSplitRegression

def treasury : FeeDistribution.TreasuryRead := fun s =>
  if s.shares 7 = 11 ∧ s.shares 170 = 2 ∧ s.shares 190 = 2 then .ok 500 else .error 99
def result := ReportFeeDistribution.execute treasury input world

theorem actual_distribution : (match result with
  | .committed post fee events trace => decide
    (fee = ⟨10,[170,180,190],[1,2,3],[2,0,2],6⟩ ∧ post.steth.shares 7 = 5 ∧
     post.steth.shares 170 = 2 ∧ post.steth.shares 180 = 0 ∧ post.steth.shares 190 = 2 ∧ post.steth.shares 500 = 6 ∧
     totalShares post.steth = 20 ∧ externalShares post.steth = 4 ∧ trace = [(170,2),(190,2),(500,6)] ∧
     events = [.transfer 0 7 62,.transferShares 0 7 10,.transfer 7 170 12,.transferShares 7 170 2,
       .transfer 7 190 12,.transferShares 7 190 2,.transfer 7 500 37,.transferShares 7 500 6])
  | .reverted _ _ _ => false) = true := by decide +kernel

theorem actual_public_consumer : match result with
    | .committed post fee events trace => ReportFeeDistribution.Success treasury input world post fee events trace ∧
      ReportFeeDistribution.Ledger input world post fee trace
    | .reverted _ _ _ => False := by
  cases hr : result with
  | committed post fee events trace =>
    exact LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_distribution _ _ _ _ _ _ _ hr
  | reverted e w t => have h := actual_distribution; rw [hr] at h; cases h

def aliasRouter : Core := ⟨[
  (AccountActualMintRegression.layout.moduleConfigSlot 1,⟨7+1000*two160,by decide⟩),
  (AccountActualMintRegression.layout.moduleConfigSlot 2,⟨180+1000*two176,by decide⟩),
  (AccountActualMintRegression.layout.moduleConfigSlot 3,⟨7+500*two160+500*two176,by decide⟩)]⟩
def aliasWorld : ReportFeeMint.World := {world with router := aliasRouter}
def aliasTreasury : FeeDistribution.TreasuryRead := fun s => if s.shares 7 = 15 then .ok 7 else .error 99

theorem self_and_duplicate_recipients : (match ReportFeeDistribution.execute aliasTreasury input aliasWorld with
  | .committed post _ _ trace => decide (post.steth.shares 7 = 15 ∧ trace = [(7,2),(7,2),(7,6)])
  | _ => false) = true := by decide +kernel

theorem late_overflow_rolls_back_prior_mint_and_transfer :
    let w := {world with steth := {world.steth with shares := fun a => if a = 190 then two256-1 else world.steth.shares a}}
    (match ReportFeeDistribution.execute treasury input w with
    | .reverted (.distribution (.transfer .addOverflow)) rollback trace => decide
      (rollback.router = w.router ∧ rollback.steth.storage = w.steth.storage ∧ rollback.steth.shares 7 = 5 ∧
       rollback.steth.shares 170 = 0 ∧ trace = [(170,2),(190,2)])
    | _ => false) = true := by decide +kernel

theorem zero_mint_skips_bad_treasury : (match ReportFeeDistribution.execute (fun _ => .error 42)
    {input with report := {input.report with clValidatorsBalance := 0}} world with
  | .committed post _ events trace => decide (post.steth.storage = world.steth.storage ∧ events = [] ∧ trace = [])
  | _ => false) = true := by decide +kernel

theorem zero_treasury_skips_read : (match FeeDistribution.execute (fun _ => .error 42) 7
    ⟨5,[170,180],[1,2],[2,3],0⟩ world.steth with
  | .committed post _ trace => decide (post.shares 7 = 0 ∧ post.shares 170 = 2 ∧ post.shares 180 = 3 ∧ trace = [(170,2),(180,3)])
  | _ => false) = true := by decide +kernel

theorem guard_order_from_zero_before_stopped : (match FeeDistribution.transferShares 0 0 1
    {world.steth with activeFlag := false} with
  | .reverted .fromZero _ => true
  | _ => false) = true := by decide +kernel

theorem conversion_reject_restores_debit :
    let w := {world.steth with shares := fun a => if a = 7 then uint128Max else 0}
    (match FeeDistribution.transferShares 7 170 uint128Max w with
    | .reverted (.conversion .sharesTooLargeForEvent) rollback => decide (rollback.shares 7 = uint128Max ∧ rollback.shares 170 = 0)
    | _ => false) = true := by decide +kernel

theorem wrapped_share_rate_after_transfer :
    let w := {world.steth with
      storage := world.steth.storage.write bufferedEtherAndDepositedPostReportPosition ⟨two256-1,by decide⟩
      shares := fun a => if a = 7 then 2^127 else 0}
    (match FeeDistribution.transferShares 7 170 (2^127) w with
    | .committed post pooled _ => decide
      (post.shares 7 = 0 ∧ post.shares 170 = 2^127 ∧ pooled = ((2^127 * (2*(two128-1))) % two256) / 6)
    | _ => false) = true := by decide +kernel

#print axioms actual_distribution
#print axioms actual_public_consumer
#print axioms self_and_duplicate_recipients
#print axioms late_overflow_rolls_back_prior_mint_and_transfer
#print axioms zero_mint_skips_bad_treasury
#print axioms zero_treasury_skips_read
#print axioms guard_order_from_zero_before_stopped
#print axioms conversion_reject_restores_debit
#print axioms wrapped_share_rate_after_transfer
end AccountFeeDistributionRegression
