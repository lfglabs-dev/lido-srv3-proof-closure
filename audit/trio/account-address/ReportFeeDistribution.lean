import FeeDistribution

namespace AccountAddress.ReportFeeDistribution
open ReportWriteFee StETHMintShares

inductive Error where
  | mint (e : ReportFeeMint.Error)
  | distribution (e : FeeDistribution.Error)
  deriving DecidableEq, Repr
inductive Outcome where
  | reverted (error : Error) (rollback : ReportFeeMint.World) (attempted : List (Nat × Nat))
  | committed (post : ReportFeeMint.World) (fee : FeeResult) (events : List Event) (attempted : List (Nat × Nat))

/-- Accounting403-407 covered typed phase: same report/getter/checked fee/mint,
then positive-only fee distribution. Every failure restores the entire incoming
world, including report writes, mint and already successful module transfers. -/
def execute (read : FeeDistribution.TreasuryRead) (x : ReportFeeMint.Input)
    (before : ReportFeeMint.World) : Outcome :=
  match ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before with
  | .reverted e _ => .reverted (.mint e) before []
  | .committed minted fee mintEvents =>
    if fee.sharesToMintAsFees = 0 then .committed minted fee mintEvents []
    else match FeeDistribution.execute read x.accountingAddress fee minted.steth with
      | .reverted e _ trace => .reverted (.distribution e) before trace
      | .committed after events trace => .committed {minted with steth := after} fee (mintEvents++events) trace

def Success (read : FeeDistribution.TreasuryRead) (x : ReportFeeMint.Input)
    (before post : ReportFeeMint.World) (fee : FeeResult) (events : List Event) (trace : List (Nat × Nat)) : Prop :=
  ∃ minted mintEvents,
    ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before = .committed minted fee mintEvents ∧
    ReportFeeCheckedSplit.Success x before minted fee mintEvents ∧
    fee.sharesToMintAsFees ≤ minted.steth.shares x.accountingAddress ∧
    post.router = minted.router ∧ post.steth.storage = minted.steth.storage ∧
    ((fee.sharesToMintAsFees = 0 ∧ post = minted ∧ events = mintEvents ∧ trace = []) ∨
     (0 < fee.sharesToMintAsFees ∧ ∃ distributionEvents,
       FeeDistribution.execute read x.accountingAddress fee minted.steth = .committed post.steth distributionEvents trace ∧
       FeeDistribution.Success read x.accountingAddress fee minted.steth post.steth distributionEvents trace ∧
       events = mintEvents++distributionEvents))

/-- Funding is obtained from the actual mint, not a distribution premise. -/
theorem minted_budget (x : ReportFeeMint.Input) (before minted : ReportFeeMint.World)
    (fee : FeeResult) (events : List Event)
    (h : ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before = .committed minted fee events) :
    fee.sharesToMintAsFees ≤ minted.steth.shares x.accountingAddress := by
  obtain ⟨_,_,_,_,_,_,branch⟩ := ReportFeeMint.committed_success x before minted fee events h
  rcases branch with ⟨hz,_,_⟩ | ⟨_,_,effect⟩
  · rw [hz]; exact Nat.zero_le _
  · have hshares := effect.2.2.2.2.2.2.2.1 x.accountingAddress
    simp at hshares
    omega

theorem execute_success (read : FeeDistribution.TreasuryRead) (x : ReportFeeMint.Input)
    (before post : ReportFeeMint.World) (fee : FeeResult) (events : List Event) (trace : List (Nat × Nat))
    (h : execute read x before = .committed post fee events trace) : Success read x before post fee events trace := by
  unfold execute at h
  cases hm : ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before with
  | reverted e w => simp only [hm] at h; cases h
  | committed minted f mintEvents =>
    simp only [hm] at h
    split at h
    · rename_i hz
      cases h
      exact ⟨_,_,hm,ReportFeeCheckedSplit.committed_checked_split _ _ _ _ _ hm,
        minted_budget _ _ _ _ _ hm,rfl,rfl,Or.inl ⟨hz,rfl,rfl,rfl⟩⟩
    · rename_i hn
      cases hd : FeeDistribution.execute read x.accountingAddress f minted.steth with
      | reverted e w t => simp only [hd] at h; cases h
      | committed after distributionEvents t =>
        simp only [hd] at h
        cases h
        exact ⟨_,_,hm,ReportFeeCheckedSplit.committed_checked_split _ _ _ _ _ hm,
          minted_budget _ _ _ _ _ hm,rfl,
          FeeDistribution.success_storage _ _ _ _ _ _ _ (FeeDistribution.execute_success _ _ _ _ _ _ _ hd),Or.inr ⟨Nat.pos_of_ne_zero hn,distributionEvents,hd,
            FeeDistribution.execute_success _ _ _ _ _ _ _ hd,rfl⟩⟩

theorem failure_restores (read : FeeDistribution.TreasuryRead) (x : ReportFeeMint.Input)
    (before rollback : ReportFeeMint.World) (error : Error) (trace : List (Nat × Nat))
    (h : execute read x before = .reverted error rollback trace) : rollback = before := by
  unfold execute at h
  cases hm : ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before with
  | reverted e w => simp only [hm] at h; cases h; rfl
  | committed minted fee events =>
    simp only [hm] at h
    split at h
    · cases h
    · cases hd : FeeDistribution.execute read x.accountingAddress fee minted.steth with
      | committed after es t => simp only [hd] at h; cases h
      | reverted e w t => simp only [hd] at h; cases h; rfl

/-- The mint's exact pointwise increase, including its zero skip. -/
theorem minted_shares (x : ReportFeeMint.Input) (before minted : ReportFeeMint.World)
    (fee : FeeResult) (events : List Event)
    (h : ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before = .committed minted fee events)
    (account : Nat) : minted.steth.shares account = before.steth.shares account +
      (if account = x.accountingAddress then fee.sharesToMintAsFees else 0) := by
  obtain ⟨_,_,_,_,_,_,branch⟩ := ReportFeeMint.committed_success x before minted fee events h
  rcases branch with ⟨hz,hw,_⟩ | ⟨_,_,effect⟩
  · simp [hz,hw]
  · exact effect.2.2.2.2.2.2.2.1 account

/-- Every minted fee share is represented by an actual executed payment;
pointwise final account balances include all duplicate/self-recipient credits. -/
def Ledger (_x : ReportFeeMint.Input) (before post : ReportFeeMint.World)
    (fee : FeeResult) (trace : List (Nat × Nat)) : Prop :=
  FeeDistribution.paid trace = fee.sharesToMintAsFees ∧
  ∀ account, post.steth.shares account = before.steth.shares account + FeeDistribution.credits account trace

theorem execute_success_ledger (read : FeeDistribution.TreasuryRead) (x : ReportFeeMint.Input)
    (before post : ReportFeeMint.World) (fee : FeeResult) (events : List Event) (trace : List (Nat × Nat))
    (h : execute read x before = .committed post fee events trace) :
    Success read x before post fee events trace ∧ Ledger x before post fee trace := by
  have hs := execute_success read x before post fee events trace h
  refine ⟨hs,?_⟩
  obtain ⟨minted,mintEvents,hm,split,_,_,_,branch⟩ := hs
  rcases branch with ⟨hz,hpost,_,htrace⟩ | ⟨_,distributionEvents,_,distribution,_⟩
  · rw [hpost,htrace]
    refine ⟨by simp [FeeDistribution.paid,hz],?_⟩
    intro account
    simpa [FeeDistribution.credits,hz] using minted_shares x before minted fee mintEvents hm account
  · have aligned := split.2.2.1.trans split.2.2.2.1
    obtain ⟨d,_,_,partition⟩ := split.2.2.2.2
    have hpaid := (FeeDistribution.success_paid read x.accountingAddress fee minted.steth post.steth
      distributionEvents trace aligned distribution).trans partition.1
    refine ⟨hpaid,?_⟩
    intro account
    have hl := (FeeDistribution.success_chain read x.accountingAddress fee minted.steth post.steth
      distributionEvents trace distribution).ledger account
    rw [hpaid,minted_shares x before minted fee mintEvents hm account] at hl
    omega

#print axioms execute_success_ledger
#print axioms minted_budget
#print axioms execute_success
#print axioms failure_restores
end AccountAddress.ReportFeeDistribution
