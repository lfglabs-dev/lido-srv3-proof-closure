import AccountingCall

/-! Execute report/getter/checked fees first; zero fees skip the accounting
CALL. For positive fees the actual source getter at the physical locator is
called before mint authorization; the returned World and decoded address are
consumed by mint, then actual module payments and treasury STATICCALL. -/
namespace AccountAddress.ReportFeeAccountingCall
set_option autoImplicit false
open ReportWriteFee StETHMintShares
open LidoSRv3.Audit.Source.TrioReserve1
abbrev World := ReportFeeMint.World
abbrev Input := ReportFeeMint.Input
abbrev Outcome := ReportFeeTreasuryCall.Outcome
abbrev Payments := ReportFeeTreasuryCall.Payments
abbrev Attempts := ReportFeeTreasuryCall.Attempts

def withAccounting (w : World) (a : Nat) : World :=
  {w with steth := {w.steth with locatorAccounting := a}}

/-- Generic stage combinator keeps proof reduction independent of the
large physical report/getter definitions; every argument below is fixed by prepare. -/
def collect (report : ReportOutcome) (get : Core → Except GetterError Distribution)
    (calculate : Distribution → Option FeeResult) : Except ReportFeeMint.Error (Core × FeeResult) :=
  match report with
  | .reverted fault _ => .error (.invalidReport fault)
  | .committed router => match get router with
    | .error fault => .error (.getter fault)
    | .ok distribution => match calculate distribution with
      | none => .error .feeArithmetic
      | some fee => .ok (router,fee)

/-- The original pure report, physical getter and checked fee operations,
reused in source order. No mint or external call occurs in preparation. -/
def prepare (x : Input) (before : Core) : Except ReportFeeMint.Error (Core × FeeResult) :=
  collect (reportValidatorBalances x.layout x.registeredModuleIds x.reportedModuleIds x.balancesGwei before)
    (getStakingRewardsDistribution x.layout x.registeredModuleIds)
    (ReportFeeMint.checkedFeeProductsFromCommittedGetter x.report)

def Prepared (x : Input) (before router : Core) (fee : FeeResult) : Prop :=
  ∃ distribution,
    reportValidatorBalances x.layout x.registeredModuleIds x.reportedModuleIds x.balancesGwei before = .committed router ∧
    getStakingRewardsDistribution x.layout x.registeredModuleIds router = .ok distribution ∧
    ReportFeeMint.checkedFeeProductsFromCommittedGetter x.report distribution = some fee

attribute [local irreducible] reportValidatorBalances getStakingRewardsDistribution
  ReportFeeMint.checkedFeeProductsFromCommittedGetter mintShares

theorem collect_success (report : ReportOutcome) (get : Core → Except GetterError Distribution)
    (calculate : Distribution → Option FeeResult) (router : Core) (fee : FeeResult)
    (h : collect report get calculate = .ok (router,fee)) :
    ∃ distribution, report = .committed router ∧ get router = .ok distribution ∧ calculate distribution = some fee := by
  unfold collect at h
  cases report with
  | reverted fault core => cases h
  | committed core =>
    cases hg : get core with
    | error fault => simp only [hg] at h; cases h
    | ok distribution =>
      simp only [hg] at h
      cases hf : calculate distribution with
      | none => simp only [hf] at h; cases h
      | some f => simp only [hf] at h; cases h; exact ⟨distribution,rfl,hg,hf⟩

theorem prepare_success (x : Input) (before router : Core) (fee : FeeResult)
    (h : prepare x before = .ok (router,fee)) : Prepared x before router fee :=
  collect_success
    (reportValidatorBalances x.layout x.registeredModuleIds x.reportedModuleIds x.balancesGwei before)
    (getStakingRewardsDistribution x.layout x.registeredModuleIds)
    (ReportFeeMint.checkedFeeProductsFromCommittedGetter x.report) router fee h

/-- This continuation consumes the actual prepared/returned state. The
report is not executed a second time after CALL. -/
def finish (e : TreasuryCall.Environment) (x : Input) (entry ready : World) (fee : FeeResult) : Outcome :=
  match ReportFeeMint.mintCommittedFee x.accountingAddress ready fee with
  | .reverted fault _ => .reverted (.mint fault) entry [] []
  | .committed minted f mintEvents =>
    if f.sharesToMintAsFees = 0 then .committed minted f mintEvents [] []
    else match ReportFeeTreasuryCall.distribute e x.accountingAddress f minted with
      | .reverted fault payments attempts => .reverted fault entry payments attempts
      | .committed post events payments attempts => .committed post f (mintEvents++events) payments attempts

structure Result where
  outcome : Outcome
  accountingAttempts : Attempts

def execute (accounting : AccountingCall.Environment) (treasury : TreasuryCall.Environment)
    (x : Input) (before : World) : Result :=
  match prepare x before.router with
  | .error fault => ⟨.reverted (.mint fault) before [] [],[]⟩
  | .ok (router,fee) =>
    let ready := {ReportFeePhysicalPause.project before with router}
    if fee.sharesToMintAsFees = 0 then ⟨finish treasury x before ready fee,[]⟩
    else
      let called := AccountingCall.call accounting ready
      match called.outcome with
      | .error fault => ⟨.reverted (.locator fault) before [] [],called.attempts⟩
      | .ok (returned,resolved) =>
        ⟨finish treasury x before (withAccounting returned resolved) fee,called.attempts⟩

-- These two syntax aliases name the pinned, already checked private stage
-- combinators. Expansion produces only existing constants; there is no new
-- axiom, evaluator replacement or execution hook.
open Lean in
macro "pinnedMintRoot" : term => pure (mkIdent
  (.str (.str (.str (.num `_private.ReportFeeMint 0) "AccountAddress") "ReportFeeMint") "runRoot"))
open Lean in
macro "pinnedMintStages" : term => pure (mkIdent
  (.str (.str (.str (.num `_private.ReportFeeMint 0) "AccountAddress") "ReportFeeMint") "runStages"))

/-- Generic expression definitionally equal to the unchanged old private
root/stage combinators. It is used only to prove replay, never by execute. -/
def legacyStages (report : ReportOutcome) (get : Core → Except GetterError Distribution)
    (calculate : Distribution → Option FeeResult) (mint : Core → FeeResult → ReportFeeMint.Outcome)
    (before : World) : ReportFeeMint.Outcome :=
  pinnedMintRoot report
    (fun router => pinnedMintStages
      (get router) calculate (mint router) before) before

theorem legacy_success (report : ReportOutcome) (get : Core → Except GetterError Distribution)
    (calculate : Distribution → Option FeeResult) (mint : Core → FeeResult → ReportFeeMint.Outcome)
    (before post : World) (router : Core) (d : Distribution) (fee actualFee : FeeResult)
    (events : List Event) (hr : report = .committed router) (hg : get router = .ok d)
    (hf : calculate d = some fee) (hm : mint router fee = .committed post actualFee events) :
    legacyStages report get calculate mint before = .committed post actualFee events := by
  subst report
  change (match get router with
    | .error fault => ReportFeeMint.Outcome.reverted (.getter fault) before
    | .ok d => match calculate d with
      | none => ReportFeeMint.Outcome.reverted .feeArithmetic before
      | some f => match mint router f with
        | .reverted fault _ => ReportFeeMint.Outcome.reverted fault before
        | .committed post fee es => ReportFeeMint.Outcome.committed post fee es) = _
  simp only [hg,hf,hm]

/-- Reconstruct the old report/mint equation from operations already
executed. This is a proof, never a second runtime report or assumed stage. -/
theorem mint_replay (x : Input) (before post : World) (router : Core) (fee actualFee : FeeResult)
    (events : List Event) (hp : Prepared x before.router router fee)
    (hm : ReportFeeMint.mintCommittedFee x.accountingAddress {before with router} fee =
      .committed post actualFee events) :
    ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before = .committed post actualFee events := by
  obtain ⟨d,hr,hg,hf⟩ := hp
  exact legacy_success
    (reportValidatorBalances x.layout x.registeredModuleIds x.reportedModuleIds x.balancesGwei before.router)
    (getStakingRewardsDistribution x.layout x.registeredModuleIds)
    (ReportFeeMint.checkedFeeProductsFromCommittedGetter x.report)
    (fun r f => ReportFeeMint.mintCommittedFee x.accountingAddress {before with router := r} f)
    before post router d fee actualFee events hr hg hf hm

/-- Complete old executor on its explicit derived entry, obtained from a
successful actual continuation; no extra public hypothesis is introduced. -/
theorem finish_success_replay (e : TreasuryCall.Environment) (x : Input)
    (entry derived post : World) (router : Core) (inputFee fee : FeeResult)
    (events : List Event) (payments : Payments) (attempts : Attempts)
    (hp : Prepared x derived.router router inputFee)
    (h : finish e x entry {ReportFeePhysicalPause.project derived with router} inputFee =
      .committed post fee events payments attempts) :
    ReportFeePhysicalPause.execute e x derived = .committed post fee events payments attempts := by
  unfold finish at h
  cases hm : ReportFeeMint.mintCommittedFee x.accountingAddress
      {ReportFeePhysicalPause.project derived with router} inputFee with
  | reverted fault world => simp only [hm] at h; cases h
  | committed minted f mes =>
    simp only [hm] at h
    have oldMint := mint_replay x (ReportFeePhysicalPause.project derived) minted router inputFee f mes hp hm
    unfold ReportFeePhysicalPause.execute ReportFeeTreasuryCall.execute
    simp only [oldMint]
    split at h
    · rename_i hz
      rw [if_pos hz]
      cases h
      rfl
    · rename_i hn
      rw [if_neg hn]
      cases hd : ReportFeeTreasuryCall.distribute e x.accountingAddress f minted with
      | reverted fault ps ats => simp only [hd] at h; cases h
      | committed final es ps ats => simp only [hd] at h; cases h; rfl


theorem finish_fee (e : TreasuryCall.Environment) (x : Input) (entry ready post : World)
    (inputFee fee : FeeResult) (events : List Event) (payments : Payments) (attempts : Attempts)
    (h : finish e x entry ready inputFee = .committed post fee events payments attempts) : fee = inputFee := by
  unfold finish at h
  cases hm : ReportFeeMint.mintCommittedFee x.accountingAddress ready inputFee with
  | reverted fault w => simp only [hm] at h; cases h
  | committed minted f mes =>
    have hf : f = inputFee := by
      unfold ReportFeeMint.mintCommittedFee at hm
      split at hm
      · cases hs : mintShares x.accountingAddress x.accountingAddress inputFee.sharesToMintAsFees ready.steth with
        | reverted fault w => simp only [hs] at hm; cases hm
        | committed w es => simp only [hs] at hm; cases hm; rfl
      · cases hm; rfl
    simp only [hm] at h
    split at h
    · cases h; exact hf
    · cases hd : ReportFeeTreasuryCall.distribute e x.accountingAddress f minted with
      | reverted fault ps ats => simp only [hd] at h; cases h
      | committed w es ps ats => simp only [hd] at h; cases h; exact hf

/-- Full340 success on the explicit derived entry, including all prior324
report/mint/ledger/payment/treasury conclusions. -/
def Retained (e : TreasuryCall.Environment) (x : Input) (derived post : World)
    (fee : FeeResult) (events : List Event) (payments : Payments) (attempts : Attempts) : Prop :=
  ReportFeePhysicalPause.execute e x derived = .committed post fee events payments attempts ∧
  ReportFeePhysicalPause.OldEffect e x derived post fee events payments attempts ∧
  ReportFeePhysicalPause.PhysicalEffect x derived post fee events payments

/-- An actual accounting CALL on the post-report, pre-mint World, with
physical target, returned World and decoded bytes all retained. -/
def AccountingEffect (e : AccountingCall.Environment) (before : World) (router : Core)
    (resolved : Nat) (attempts : Attempts) : Prop :=
  let ready := {ReportFeePhysicalPause.project before with router}
  (AccountingCall.call e ready).outcome = .ok (ready,resolved) ∧
  attempts = (AccountingCall.call e ready).attempts ∧ resolved < 2^160 ∧
  ∃ g, e.code (AccountingCall.locator ready) = some g ∧
    AccountingCall.getter g (AccountingCall.request ready) ready =
      .success ready (Live.encode 32 g.accounting.val) ∧
    AccountingCall.decodeAddress (Live.encode 32 g.accounting.val) = .ok resolved ∧ resolved = g.accounting.val ∧
    attempts = [⟨AccountingCall.request ready,false,true,Live.encode 32 g.accounting.val,1⟩]

/-- The context change is explicit and tied to the actual returned address.
Zero fee has no accounting call and retains original authorization metadata. -/
def Success (accounting : AccountingCall.Environment) (treasury : TreasuryCall.Environment)
    (x : Input) (before post : World) (fee : FeeResult) (events : List Event)
    (payments : Payments) (treasuryAttempts accountingAttempts : Attempts) : Prop :=
  ∃ router derived,
    Prepared x before.router router fee ∧
    ((fee.sharesToMintAsFees = 0 ∧ derived = before ∧ accountingAttempts = []) ∨
     (0 < fee.sharesToMintAsFees ∧ ∃ resolved,
       derived = withAccounting before resolved ∧ x.accountingAddress = resolved ∧
       AccountingEffect accounting before router resolved accountingAttempts)) ∧
    Retained treasury x derived post fee events payments treasuryAttempts

private theorem retained (e : TreasuryCall.Environment) (x : Input) (derived post : World)
    (fee : FeeResult) (events : List Event) (payments : Payments) (attempts : Attempts)
    (h : ReportFeePhysicalPause.execute e x derived = .committed post fee events payments attempts) :
    Retained e x derived post fee events payments attempts :=
  ⟨h,ReportFeePhysicalPause.execute_success e x derived post fee events payments attempts h⟩

private theorem retained_auth (e : TreasuryCall.Environment) (x : Input) (derived post : World)
    (fee : FeeResult) (events : List Event) (payments : Payments) (attempts : Attempts)
    (h : Retained e x derived post fee events payments attempts) (hp : 0 < fee.sharesToMintAsFees) :
    x.accountingAddress = derived.steth.locatorAccounting := by
  obtain ⟨_,old,_⟩ := h
  obtain ⟨minted,mes,hm,_⟩ := old
  obtain ⟨_,_,_,_,_,_,branch⟩ := ReportFeeMint.committed_success _ _ _ _ _ hm
  rcases branch with ⟨hz,_,_⟩ | ⟨_,_,effect⟩
  · omega
  · exact effect.1

theorem execute_success (accounting : AccountingCall.Environment) (treasury : TreasuryCall.Environment)
    (x : Input) (before post : World) (fee : FeeResult) (events : List Event)
    (payments : Payments) (treasuryAttempts : Attempts)
    (h : (execute accounting treasury x before).outcome = .committed post fee events payments treasuryAttempts) :
    Success accounting treasury x before post fee events payments treasuryAttempts
      (execute accounting treasury x before).accountingAttempts := by
  unfold execute at h ⊢
  cases hp : prepare x before.router with
  | error fault => simp only [hp] at h; cases h
  | ok pair =>
    obtain ⟨router,inputFee⟩ := pair
    simp only [hp] at h ⊢
    have prepared := prepare_success x before.router router inputFee hp
    split at h
    · rename_i hz
      simp only [if_pos hz]
      have hf := finish_fee treasury x before _ post inputFee fee events payments treasuryAttempts h
      subst inputFee
      have old := finish_success_replay treasury x before before post router fee fee events payments treasuryAttempts prepared h
      exact ⟨router,before,prepared,Or.inl ⟨hz,rfl,rfl⟩,retained _ _ _ _ _ _ _ _ old⟩
    · rename_i hn
      simp only [if_neg hn]
      cases hc : (AccountingCall.call accounting {ReportFeePhysicalPause.project before with router}).outcome with
      | error fault => simp only [hc] at h; cases h
      | ok pair =>
        obtain ⟨returned,resolved⟩ := pair
        simp only [hc] at h ⊢
        obtain ⟨hw,hbound,g,hcode,hgetter,hdecode,hvalue,hattempts⟩ := AccountingCall.call_success accounting _ returned resolved hc
        subst returned
        have hf := finish_fee treasury x before _ post inputFee fee events payments treasuryAttempts h
        subst inputFee
        have readyEq : withAccounting {ReportFeePhysicalPause.project before with router} resolved =
            {ReportFeePhysicalPause.project (withAccounting before resolved) with router} := rfl
        rw [readyEq] at h
        have old := finish_success_replay treasury x before (withAccounting before resolved) post router fee fee events payments treasuryAttempts prepared h
        have full := retained treasury x (withAccounting before resolved) post fee events payments treasuryAttempts old
        have positive := Nat.pos_of_ne_zero hn
        exact ⟨router,withAccounting before resolved,prepared,
          Or.inr ⟨positive,resolved,rfl,retained_auth _ _ _ _ _ _ _ _ full positive,
            hc,rfl,hbound,g,hcode,hgetter,hdecode,hvalue,hattempts⟩,full⟩

theorem finish_failure (e : TreasuryCall.Environment) (x : Input) (entry ready rollback : World)
    (fee : FeeResult) (fault : ReportFeeTreasuryCall.Error) (payments : Payments) (attempts : Attempts)
    (h : finish e x entry ready fee = .reverted fault rollback payments attempts) : rollback = entry := by
  unfold finish at h
  split at h
  · cases h; rfl
  · split at h
    · cases h
    · split at h <;> cases h
      rfl

theorem failure_restores (accounting : AccountingCall.Environment) (treasury : TreasuryCall.Environment)
    (x : Input) (before rollback : World) (fault : ReportFeeTreasuryCall.Error)
    (payments : Payments) (attempts : Attempts)
    (h : (execute accounting treasury x before).outcome = .reverted fault rollback payments attempts) :
    rollback = before := by
  unfold execute at h
  split at h
  · cases h; rfl
  · split at h
    · exact finish_failure _ _ _ _ _ _ _ _ _ h
    · dsimp only at h
      split at h
      · cases h; rfl
      · exact finish_failure _ _ _ _ _ _ _ _ _ h

end AccountAddress.ReportFeeAccountingCall
