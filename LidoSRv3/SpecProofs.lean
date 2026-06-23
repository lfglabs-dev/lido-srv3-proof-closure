import LidoSRv3.Model

namespace LidoSRv3

/-!
  P0 proof targets. These are Lean-checked theorems over the SRv3 Verity model,
  conditional on the source-correspondence and environment assumptions listed in
  `verity/targets/trust-boundary.json`.
-/

private theorem report_sum_matches_zipWith
    (modules : List Module) (r : List (ModuleId × Gwei))
    (hLen : r.length = modules.length) :
    (reportBalances r).sum =
      moduleBalanceSum (applyReportToModules modules r) := by
  induction modules generalizing r with
  | nil =>
      cases r with
      | nil => simp [reportBalances, moduleBalanceSum, applyReportToModules]
      | cons row rs => simp at hLen
  | cons m ms ih =>
      cases r with
      | nil => simp at hLen
      | cons row rs =>
          have hTail : rs.length = ms.length := Nat.succ.inj hLen
          simp [reportBalances, moduleBalanceSum, applyReportToModules]
          exact ih rs hTail

private theorem report_balances_match_zipWith
    (modules : List Module) (r : List (ModuleId × Gwei))
    (hLen : r.length = modules.length) :
    reportBalances r =
      (applyReportToModules modules r).map Module.validatorsBalanceGwei := by
  induction modules generalizing r with
  | nil =>
      cases r with
      | nil => simp [reportBalances, applyReportToModules]
      | cons row rs => simp at hLen
  | cons m ms ih =>
      cases r with
      | nil => simp at hLen
      | cons row rs =>
          have hTail : rs.length = ms.length := Nat.succ.inj hLen
          simp [reportBalances, applyReportToModules]
          exact ih rs hTail

theorem P1_reserve_separation
    (s : State) (actualDeposits : Nat)
    (h : depositAllowed s actualDeposits) :
    depositPullWei actualDeposits ≤ depositableEther s := by
  exact h

theorem P2_deposit_exact_pull (actualDeposits : Nat) :
    depositPullWei actualDeposits = validatorDepositWei * actualDeposits := by
  rfl

theorem P2_total_allocated_deposits
    (s : State) (count : Nat) :
    totalAllocatedDeposits s count =
      (s.modules.map (fun m => allocatedDeposits s m count)).sum := by
  rfl

theorem P3_module_balance_conservation
    (s : State) (r : List (ModuleId × Gwei))
    (hLen : r.length = s.modules.length) :
    let s' := acceptReport s r
    s'.routerBalanceGwei = moduleBalanceSum s'.modules := by
  simp [acceptReport, report_sum_matches_zipWith s.modules r hLen]

theorem P4_report_before_reward_consistency
    (s : State) (r : List (ModuleId × Gwei))
    (hLen : r.length = s.modules.length) :
    rewardsUseAcceptedReport (acceptReport s r) := by
  refine ⟨r, ?_, ?_⟩
  · simp [acceptReport]
  · simp [acceptReport, report_balances_match_zipWith s.modules r hLen]

theorem P5_reward_bound
    (totalReward : Wei) (m : Module) :
    moduleReward totalReward m ≤ moduleRewardUpperBound totalReward m := by
  simp [moduleReward]
  split
  · exact Nat.zero_le _
  · exact Nat.le_refl _

theorem P5_reward_recipient_alignment
    (totalReward : Wei) (modules : List Module) :
    recipientsAligned totalReward modules := by
  intro row hrow
  simp [rewardRows] at hrow
  rcases hrow with ⟨m, hm, hrow⟩
  exact ⟨m, hm, hrow.symm⟩

theorem P6_deposit_status_gating
    (s : State) (m : Module) (count : Nat)
    (h : m.status ≠ ModuleStatus.active) :
    allocatedDeposits s m count = 0 := by
  simp [allocatedDeposits, h]

theorem P6_stopped_module_reward_zero
    (totalReward : Wei) (m : Module)
    (h : m.status = ModuleStatus.stopped) :
    moduleReward totalReward m = 0 := by
  simp [moduleReward, h]

end LidoSRv3
