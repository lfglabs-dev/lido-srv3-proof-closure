import ReportFeeMint

/-! Additive post-report fee-cast invariant at core17005714.
SRLib.sol:873-892 and StakingRouter.sol:819-893. Layout collisions and duplicate
registered IDs are admitted; this proves a bound, not per-row value identity.
No executable definition or prior claim is changed. -/
namespace AccountAddress.ReportFeeCastInvariant
open AccountAddress.PAccount1 AccountAddress.ReportWriteFee

/-- Any accounting slot targeted by the row sequence ends at a value bounded
by the final checked total, even if later rows alias or repeat that slot. -/
theorem rows_allocation_bound (L : Layout) (ids : List Nat) :
    ∀ amounts total before after final,
      writeReportRows L ids amounts total before = .ok (after, final) →
      ∀ id ∈ ids, low64 (after.read (L.moduleAccountingSlot id)).val ≤ final := by
  induction ids with
  | nil => simp
  | cons first rest ih =>
    intro amounts total before after final h id hid
    cases amounts with
    | nil => simp [writeReportRows] at h
    | cons amount amounts =>
      simp only [writeReportRows] at h
      split at h
      · cases h
      · rename_i next hn
        have htotal := (writeReportRows_total L rest amounts next _ after final h).1
        have hnext := (checkedAdd64_ok hn).1
        rcases List.mem_cons.mp hid with hfirst | hrest
        · subst id
          by_cases halias : ∃ j ∈ rest, L.moduleAccountingSlot j = L.moduleAccountingSlot first
          · obtain ⟨j, hj, heq⟩ := halias
            rw [← heq]
            exact ih amounts next _ after final h j hj
          · have hf := writeReportRows_frame L rest amounts next _ after final h
              (L.moduleAccountingSlot first) (by
                intro j hj heq
                exact halias ⟨j, hj, heq.symm⟩)
            rw [hf, Core.read_write_same, low64_writeLow64Storage _ _ (uint64_lt amount)]
            omega
        · exact ih amounts next _ after final h id hrest

/-- The router's final write can alias a module accounting slot: in that case
both reads equal the total, so the inequality still holds. -/
theorem report_allocation_le_total (L : Layout) (reg rep bal : List Nat) (before after : Core)
    (h : reportValidatorBalances L reg rep bal before = .committed after) :
    ∀ id ∈ reg, moduleAllocationWei L after id ≤ routerTotalWei L after := by
  obtain ⟨hreg, _, _, middle, total, hrows, hafter⟩ := report_committed_spec L reg rep bal before after h
  have ht : total < two64 := (writeReportRows_total L rep bal 0 before middle total hrows).2 (by decide)
  intro id hid
  have hb := rows_allocation_bound L rep bal 0 before middle total hrows id (hreg ▸ hid)
  subst after
  unfold moduleAllocationWei routerTotalWei fromGwei
  rw [Core.read_write_same, low64_writeLow64Storage _ _ ht]
  apply Nat.mul_le_mul_right
  by_cases heq : L.routerAccountingSlot = L.moduleAccountingSlot id
  · rw [← heq, Core.read_write_same, low64_writeLow64Storage _ _ ht]
    exact Nat.le_refl _
  · rw [Core.read_write_other _ _ heq]
    exact hb

/-- The casts' inputs are already strictly below uint96; the two independent
fee floors are retained, not replaced by a fee-split or greedy formula. -/
def ExactCasts (L : Layout) (router : Core) (id : Nat) : Prop :=
  let share := moduleAllocationWei L router id * FEE_PRECISION_POINTS / routerTotalWei L router
  let cfg := decodeConfig (router.read (L.moduleConfigSlot id))
  share ≤ FEE_PRECISION_POINTS ∧
  share * cfg.moduleFee / TOTAL_BASIS_POINTS < two96 ∧
  share * cfg.treasuryFee / TOTAL_BASIS_POINTS < two96 ∧
  (computeModuleFee (moduleAllocationWei L router id) (routerTotalWei L router) cfg).moduleFee =
    share * cfg.moduleFee / TOTAL_BASIS_POINTS ∧
  (computeModuleFee (moduleAllocationWei L router id) (routerTotalWei L router) cfg).treasuryFee =
    share * cfg.treasuryFee / TOTAL_BASIS_POINTS

theorem casts_of_allocation_le_total (L : Layout) (router : Core) (id : Nat)
    (h : moduleAllocationWei L router id ≤ routerTotalWei L router) : ExactCasts L router id := by
  let share := moduleAllocationWei L router id * FEE_PRECISION_POINTS / routerTotalWei L router
  have hs : share ≤ FEE_PRECISION_POINTS := by
    dsimp [share]
    by_cases hz : routerTotalWei L router = 0
    · simp [hz]
    · have hm := Nat.mul_le_mul_right FEE_PRECISION_POINTS h
      have hd : moduleAllocationWei L router id * FEE_PRECISION_POINTS / routerTotalWei L router ≤
          routerTotalWei L router * FEE_PRECISION_POINTS / routerTotalWei L router := Nat.div_le_div_right hm
      simpa [Nat.mul_div_cancel_left _ (Nat.pos_of_ne_zero hz)] using hd
  have hfee (fee : Nat) (hf : fee < two16) : share * fee / TOTAL_BASIS_POINTS < two96 := by
    have hm := Nat.mul_le_mul hs (Nat.le_of_lt hf)
    have hd := Nat.div_le_self (share * fee) TOTAL_BASIS_POINTS
    have hc : FEE_PRECISION_POINTS * two16 < two96 := by decide
    omega
  have hm := hfee (decodeConfig (router.read (L.moduleConfigSlot id))).moduleFee
    (Nat.mod_lt _ (by decide))
  have ht := hfee (decodeConfig (router.read (L.moduleConfigSlot id))).treasuryFee
    (Nat.mod_lt _ (by decide))
  exact ⟨hs, hm, ht, Nat.mod_eq_of_lt hm, Nat.mod_eq_of_lt ht⟩

theorem report_exact_casts (L : Layout) (reg rep bal : List Nat) (before after : Core)
    (h : reportValidatorBalances L reg rep bal before = .committed after) :
    ∀ id ∈ reg, ExactCasts L after id := by
  intro id hid
  exact casts_of_allocation_le_total L after id (report_allocation_le_total L reg rep bal before after h id hid)

/-- Necessary strengthening of the actual existing report/getter/fee/mint
consumer. The cast facts concern precisely its actual post-report router. -/
theorem composition_exact_casts (x : ReportFeeMint.Input) (before after : ReportFeeMint.World)
    (fee : FeeResult) (events : List StETHMintShares.Event)
    (h : ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before = .committed after fee events) :
    ReportFeeMint.Success x before after fee events ∧
    ∀ id ∈ x.registeredModuleIds, ExactCasts x.layout after.router id := by
  have hs := ReportFeeMint.committed_success x before after fee events h
  refine ⟨hs, ?_⟩
  obtain ⟨router, distribution, hr, _, _, heq, _⟩ := hs
  rw [heq]
  exact report_exact_casts x.layout x.registeredModuleIds x.reportedModuleIds x.balancesGwei before.router router hr

#print axioms rows_allocation_bound
#print axioms report_allocation_le_total
#print axioms report_exact_casts
#print axioms composition_exact_casts
end AccountAddress.ReportFeeCastInvariant
