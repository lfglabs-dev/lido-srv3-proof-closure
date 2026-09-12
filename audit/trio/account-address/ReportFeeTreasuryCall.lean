import TreasuryCall
namespace AccountAddress.ReportFeeTreasuryCall
set_option autoImplicit false
open ReportWriteFee StETHMintShares
open LidoSRv3.Audit.Source.TrioReserve1
abbrev Payments := List (Nat × Nat)
abbrev Attempts := List Live.NestedAttempt
inductive Error where
  | mint (e : ReportFeeMint.Error)
  | distribution (e : FeeDistribution.Error)
  | locator (e : Live.Fault)
  deriving DecidableEq, Repr
inductive DistributionOutcome where
  | reverted (error : Error) (payments : Payments) (attempts : Attempts)
  | committed (post : ReportFeeMint.World) (events : List Event) (payments : Payments) (attempts : Attempts)

/-- Actual module transfers, then the readonly request on exactly that
intermediate ACCOUNT World, then payment to the actually decoded address. -/
def distribute (e : TreasuryCall.Environment) (caller : Nat) (fee : FeeResult)
    (before : ReportFeeMint.World) : DistributionOutcome :=
  match FeeDistribution.modules caller fee.moduleFeeRecipients fee.moduleSharesToMint before.steth with
  | .reverted fault _ payments => .reverted (.distribution fault) payments []
  | .committed middle moduleEvents payments =>
    if fee.treasurySharesToMint = 0 then .committed {before with steth := middle} moduleEvents payments []
    else
      let called := TreasuryCall.call e caller {before with steth := middle}
      match called.outcome with
      | .error fault => .reverted (.locator fault) payments called.attempts
      | .ok recipient =>
        match FeeDistribution.transferShares caller recipient fee.treasurySharesToMint middle with
        | .reverted fault _ => .reverted (.distribution (.transfer fault))
            (payments++[(recipient,fee.treasurySharesToMint)]) called.attempts
        | .committed post _ events => .committed {before with steth := post}
            (moduleEvents++events) (payments++[(recipient,fee.treasurySharesToMint)]) called.attempts

def ReadEffects (e : TreasuryCall.Environment) (caller : Nat) (fee : FeeResult)
    (before post : ReportFeeMint.World) (events : List Event) (payments : Payments) (attempts : Attempts) : Prop :=
  ∃ middle moduleEvents modulePayments,
    FeeDistribution.modules caller fee.moduleFeeRecipients fee.moduleSharesToMint before.steth =
      .committed middle moduleEvents modulePayments ∧
    ((fee.treasurySharesToMint = 0 ∧ attempts = [] ∧ post.steth = middle) ∨
     (0 < fee.treasurySharesToMint ∧ ∃ recipient raw pooled treasuryEvents,
       caller < 2^160 ∧ (TreasuryCall.request e caller).caller.val = caller ∧
       (e.codeSize e.locator).val ≠ 0 ∧
       e.external (TreasuryCall.request e caller) {before with steth := middle} = .success raw ∧
       TreasuryCall.decodeAddress raw = .ok recipient ∧ recipient < 2^160 ∧
       recipient = Live.decode (raw.take 32) ∧
       attempts = [⟨TreasuryCall.request e caller,true,true,raw,1⟩] ∧
       FeeDistribution.transferShares caller recipient fee.treasurySharesToMint middle =
         .committed post.steth pooled treasuryEvents ∧
       events = moduleEvents++treasuryEvents ∧ payments = modulePayments++[(recipient,fee.treasurySharesToMint)]))

theorem distribute_success (e : TreasuryCall.Environment) (caller : Nat) (fee : FeeResult)
    (before post : ReportFeeMint.World) (events : List Event) (payments : Payments) (attempts : Attempts)
    (h : distribute e caller fee before = .committed post events payments attempts) :
    FeeDistribution.execute (TreasuryCall.read e caller before.router) caller fee before.steth =
      .committed post.steth events payments ∧ post.router = before.router ∧
    ReadEffects e caller fee before post events payments attempts := by
  unfold distribute at h
  cases hm : FeeDistribution.modules caller fee.moduleFeeRecipients fee.moduleSharesToMint before.steth with
  | reverted fault state ps => simp only [hm] at h; cases h
  | committed middle moduleEvents ps =>
    simp only [hm] at h
    split at h
    · rename_i hz
      cases h
      exact ⟨by simp [FeeDistribution.execute,hm,FeeDistribution.finish,hz],rfl,
        middle,events,payments,hm,Or.inl ⟨hz,rfl,rfl⟩⟩
    · rename_i hn
      cases hc : (TreasuryCall.call e caller {before with steth := middle}).outcome with
      | error fault => simp only [hc] at h; cases h
      | ok recipient =>
        simp only [hc] at h
        cases ht : FeeDistribution.transferShares caller recipient fee.treasurySharesToMint middle with
        | reverted fault state => simp only [ht] at h; cases h
        | committed after pooled treasuryEvents =>
          simp only [ht] at h
          cases h
          obtain ⟨hcode,raw,hext,hd,haddr,heq,hattempts⟩ := TreasuryCall.call_success e caller _ recipient hc
          have hcaller : caller < 2^160 := (FeeDistribution.transfer_success _ _ _ _ _ _ _ ht).1
          have hcallerExact : (TreasuryCall.request e caller).caller.val = caller := by
            change caller % (2^160) = caller
            exact Nat.mod_eq_of_lt hcaller
          refine ⟨?_,rfl,middle,moduleEvents,ps,hm,Or.inr ⟨Nat.pos_of_ne_zero hn,
            recipient,raw,pooled,treasuryEvents,hcaller,hcallerExact,hcode,hext,hd,haddr,heq,hattempts,ht,rfl,rfl⟩⟩
          simp [FeeDistribution.execute,hm,FeeDistribution.finish,hn,TreasuryCall.read,hc,Except.mapError,ht]

inductive Outcome where
  | reverted (error : Error) (rollback : ReportFeeMint.World) (payments : Payments) (attempts : Attempts)
  | committed (post : ReportFeeMint.World) (fee : FeeResult) (events : List Event) (payments : Payments) (attempts : Attempts)

/-- Same report/mint, followed by the directly consumed distribution. No
extra resolver call occurs on zero mint or zero treasury allocation. -/
def execute (e : TreasuryCall.Environment) (x : ReportFeeMint.Input) (before : ReportFeeMint.World) : Outcome :=
  match ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before with
  | .reverted fault _ => .reverted (.mint fault) before [] []
  | .committed minted fee mintEvents =>
    if fee.sharesToMintAsFees = 0 then .committed minted fee mintEvents [] []
    else match distribute e x.accountingAddress fee minted with
      | .reverted fault payments attempts => .reverted fault before payments attempts
      | .committed post events payments attempts => .committed post fee (mintEvents++events) payments attempts

/-- Retain all established ACCOUNT mint/casts/split/distribution/ledger
conclusions; the resolver is now fixed by the actual STATICCALL execution. -/
theorem execute_success (e : TreasuryCall.Environment) (x : ReportFeeMint.Input)
    (before post : ReportFeeMint.World) (fee : FeeResult) (events : List Event) (payments : Payments) (attempts : Attempts)
    (h : execute e x before = .committed post fee events payments attempts) :
    ∃ minted mintEvents,
      ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before = .committed minted fee mintEvents ∧
      ReportFeeDistribution.Success (TreasuryCall.read e x.accountingAddress minted.router) x before post fee events payments ∧
      ReportFeeDistribution.Ledger x before post fee payments ∧
      ((fee.sharesToMintAsFees = 0 ∧ attempts = []) ∨
       (0 < fee.sharesToMintAsFees ∧ ∃ distributionEvents,
         distribute e x.accountingAddress fee minted = .committed post distributionEvents payments attempts ∧
         ReadEffects e x.accountingAddress fee minted post distributionEvents payments attempts ∧
         events = mintEvents++distributionEvents)) := by
  unfold execute at h
  cases hm : ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before with
  | reverted fault state => simp only [hm] at h; cases h
  | committed minted f mintEvents =>
    simp only [hm] at h
    split at h
    · rename_i hz
      cases h
      have old : ReportFeeDistribution.execute (TreasuryCall.read e x.accountingAddress post.router) x before =
          .committed post fee events [] := by simp [ReportFeeDistribution.execute,hm,hz]
      obtain ⟨hs,hl⟩ := ReportFeeDistribution.execute_success_ledger _ _ _ _ _ _ _ old
      exact ⟨post,events,rfl,hs,hl,Or.inl ⟨hz,rfl⟩⟩
    · rename_i hn
      cases hd : distribute e x.accountingAddress f minted with
      | reverted fault ps ats => simp only [hd] at h; cases h
      | committed after distributionEvents ps ats =>
        simp only [hd] at h
        cases h
        obtain ⟨hold,hr,hread⟩ := distribute_success e x.accountingAddress fee minted post distributionEvents payments attempts hd
        have hw : {minted with steth := post.steth} = post := by cases post; simp_all
        have old : ReportFeeDistribution.execute (TreasuryCall.read e x.accountingAddress minted.router) x before =
            .committed post fee (mintEvents++distributionEvents) payments := by
          simp [ReportFeeDistribution.execute,hm,hn,hold,hw]
        obtain ⟨hs,hl⟩ := ReportFeeDistribution.execute_success_ledger _ _ _ _ _ _ _ old
        exact ⟨minted,mintEvents,rfl,hs,hl,Or.inr ⟨Nat.pos_of_ne_zero hn,distributionEvents,hd,hread,rfl⟩⟩

theorem failure_restores (e : TreasuryCall.Environment) (x : ReportFeeMint.Input)
    (before rollback : ReportFeeMint.World) (fault : Error) (payments : Payments) (attempts : Attempts)
    (h : execute e x before = .reverted fault rollback payments attempts) : rollback = before := by
  unfold execute at h
  cases hm : ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before with
  | reverted f w => simp only [hm] at h; cases h; rfl
  | committed minted fee events =>
    simp only [hm] at h
    split at h
    · cases h
    · cases hd : distribute e x.accountingAddress fee minted with
      | committed w es ps ats => simp only [hd] at h; cases h
      | reverted f ps ats => simp only [hd] at h; cases h; rfl

#print axioms distribute_success
#print axioms execute_success
#print axioms failure_restores
end AccountAddress.ReportFeeTreasuryCall
