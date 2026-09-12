import StETHMintShares

/-!
# Committed report → getter → fee products → physical Lido mint

Pinned to `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:
`Accounting.sol:403-406`, `Lido.sol:894-900`, and
`StETH.sol:518-527,559-571`.

This is the ACCOUNT continuation of the physical router slice.  A successful
SRLib report writes a router `Core`; the StakingRouter getter then reads that
same post-write core; `checkedFeeProductsFromCommittedGetter` consumes that exact
getter result; and the resulting `sharesToMintAsFees` is passed once to the
modeled Lido/StETH mint.  In particular there is no caller-supplied fee
product, mint quantity, equality premise, or assumed successful mint.
-/

namespace AccountAddress.ReportFeeMint

open AccountAddress.PAccount1
open AccountAddress.ReportWriteFee
open AccountAddress.StETHMintShares

/-- All mutable state touched by this suffix.  Router words and StETH words
are distinct modeled contract components (deployment separation is not proved), while the packed StETH total-share word and the
abstract account-share map deliberately live in this one `steth` state and are updated
by the same `mintShares` execution. -/
structure World where
  router : Core
  steth : AccountAddress.StETHMintShares.State


structure Input where
  accountingAddress : Nat
  layout : Layout
  registeredModuleIds : List Nat
  reportedModuleIds : List Nat
  balancesGwei : List Nat
  report : ReportWei


inductive Error where
  | invalidReport (e : AccountAddress.PAccount1.Error)
  | getter (e : GetterError)
  /-- A Solidity 0.8 uint256 operation in Accounting 317/323/325/331 panics. -/
  | feeArithmetic
  | fee (e : FeeError)
  | mint (e : AccountAddress.StETHMintShares.Error)
  deriving Repr, DecidableEq


inductive Outcome where
  | reverted (error : Error) (rollback : World)
  | committed (post : World) (fee : FeeResult) (events : List Event)


private def uint256Max : Nat := two256 - 1


private def checkedWord (n : Nat) : Option Nat :=
  if n ≤ uint256Max then some n else none

private def checkedAdd (a b : Nat) : Option Nat :=
  if a + b ≤ uint256Max then some (a + b) else none

private def checkedSub (a b : Nat) : Option Nat :=
  if b ≤ a then some (a - b) else none

private def checkedMul (a b : Nat) : Option Nat :=
  if a * b ≤ uint256Max then some (a * b) else none

private def checkedDiv (a b : Nat) : Option Nat :=
  if b = 0 then none else some (a / b)


/-- Checked Accounting335–358 distribution. Unlike the older unrestricted
Nat helper, each product and running sum is checked before minting can run. -/
private def checkedModuleShares (shares totalFee : Nat) : List Nat → Nat → Option (List Nat × Nat)
  | [], running => some ([], running)
  | f :: fs, running => do
    let part ← if 0 < f then do
      let product ← checkedMul shares f
      checkedDiv product totalFee
      else some 0
    let next ← checkedAdd running part
    let (rest, final) ← checkedModuleShares shares totalFee fs next
    some (part :: rest, final)


def checkedFeeResultOf (d : Distribution) (shares : Nat) : Option FeeResult := do
  if 0 < shares then
    if d.totalFee = 0 then none else do
      let (parts, total) ← checkedModuleShares shares d.totalFee d.stakingModuleFees 0
      let treasury ← checkedSub shares total
      some ⟨shares, d.recipients, d.stakingModuleIds, parts, treasury⟩
  else some ⟨0, [], [], [], 0⟩


/-- The checked Accounting 317, 323, 325 and 331 products over the exact
post-write getter result.  This is deliberately an executable failure surface
rather than a bounded-domain premise: any out-of-word field, overflow,
underflow, or zero divisor rejects the whole composed transaction. -/
def checkedFeeProductsFromCommittedGetter (r : ReportWei) (d : Distribution) :
    Option FeeResult := do
  let validators ← checkedWord r.clValidatorsBalance
  let pending ← checkedWord r.clPendingBalance
  let withdrawals ← checkedWord r.withdrawalsVaultTransfer
  let principal ← checkedWord r.principalClBalance
  let elRewards ← checkedWord r.elRewardsVaultTransfer
  let postEther ← checkedWord r.postInternalEther
  let internalShares ← checkedWord r.internalSharesBeforeFees
  let totalFee ← checkedWord d.totalFee
  let precision ← checkedWord d.precisionPoints
  let validatorPending ← checkedAdd validators pending
  let unified ← checkedAdd validatorPending withdrawals
  if principal < unified then
    let rewardBeforeEl ← checkedSub unified principal
    let rewards ← checkedAdd rewardBeforeEl elRewards
    let feeProduct ← checkedMul rewards totalFee
    let feeEther ← checkedDiv feeProduct precision
    let denominator ← checkedSub postEther feeEther
    let sharesProduct ← checkedMul feeEther internalShares
    let shares ← checkedDiv sharesProduct denominator
    checkedFeeResultOf d shares
  else checkedFeeResultOf d 0


/-- Bounded Accounting403–406 mint call. `_distributeFee`, reportRewardsMinted
and subsequent observer/rebase calls are deliberately outside this suffix. -/
def mintCommittedFee (accountingAddress : Nat) (before : World) (fee : FeeResult) : Outcome :=
  if 0 < fee.sharesToMintAsFees then
    match mintShares accountingAddress accountingAddress fee.sharesToMintAsFees before.steth with
    | .reverted e _ => .reverted (.mint e) before
    | .committed steth events => .committed { before with steth } fee events
  else .committed before fee []

private def runStages (dr : Except GetterError Distribution)
    (calculate : Distribution → Option FeeResult) (mint : FeeResult → Outcome)
    (before : World) : Outcome :=
  match dr with
  | .error e => .reverted (.getter e) before
  | .ok d => match calculate d with
    | none => .reverted .feeArithmetic before
    | some f => match mint f with
      | .reverted e _ => .reverted e before
      | .committed p f es => .committed p f es

private def runRoot (report : ReportOutcome) (cont : Core → Outcome)
    (before : World) : Outcome :=
  match report with
  | .reverted e _ => .reverted (.invalidReport e) before
  | .committed r => cont r

def continueFromCommittedReport (x : Input) (before : World) (postRouter : Core) : Outcome :=
  runStages (getStakingRewardsDistribution x.layout x.registeredModuleIds postRouter)
    (checkedFeeProductsFromCommittedGetter x.report)
    (mintCommittedFee x.accountingAddress {before with router := postRouter}) before

/-- Execute report writes, getter, checked fee products, and the bounded mint
suffix. Omitted full-report prefix and later distribution calls remain outside. -/
def handleOracleReportFromCommittedFeeProducts (x : Input) (before : World) : Outcome :=
  runRoot (reportValidatorBalances x.layout x.registeredModuleIds x.reportedModuleIds
    x.balancesGwei before.router) (continueFromCommittedReport x before) before

def MintBranch (accountingAddress : Nat) (before post : World) (fee : FeeResult)
    (events : List Event) : Prop :=
  (fee.sharesToMintAsFees = 0 ∧ post.steth = before.steth ∧ events = []) ∨
  (0 < fee.sharesToMintAsFees ∧
    mintShares accountingAddress accountingAddress fee.sharesToMintAsFees before.steth =
      .committed post.steth events ∧
    MintEffect accountingAddress accountingAddress fee.sharesToMintAsFees before.steth post.steth events)

def Success (x : Input) (before post : World) (fee : FeeResult) (events : List Event) : Prop :=
  ∃ router distribution,
    reportValidatorBalances x.layout x.registeredModuleIds x.reportedModuleIds
      x.balancesGwei before.router = .committed router ∧
    getStakingRewardsDistribution x.layout x.registeredModuleIds router = .ok distribution ∧
    checkedFeeProductsFromCommittedGetter x.report distribution = some fee ∧
    post.router = router ∧ MintBranch x.accountingAddress before post fee events

attribute [local irreducible] AccountAddress.ReportWriteFee.reportValidatorBalances getStakingRewardsDistribution
  checkedFeeProductsFromCommittedGetter mintShares

private theorem mint_success (accountingAddress : Nat) (before post : World)
    (inputFee fee : FeeResult) (events : List Event)
    (h : mintCommittedFee accountingAddress before inputFee = .committed post fee events) :
    fee = inputFee ∧ post.router = before.router ∧ MintBranch accountingAddress before post fee events := by
  unfold mintCommittedFee at h
  split at h
  · rename_i hn
    cases hm : mintShares accountingAddress accountingAddress inputFee.sharesToMintAsFees before.steth with
    | reverted error rollback => rw [hm] at h; cases h
    | committed after logs =>
      rw [hm] at h
      cases h
      exact ⟨rfl, rfl, Or.inr ⟨hn, hm, committed_mint_effect _ _ _ _ _ _ hm⟩⟩
  · rename_i hz
    cases h
    exact ⟨rfl, rfl, Or.inl ⟨Nat.eq_zero_of_not_pos hz, rfl, rfl⟩⟩

private theorem stages_success (dr : Except GetterError Distribution)
    (calculate : Distribution → Option FeeResult) (mint : FeeResult → Outcome)
    (before post : World) (fee : FeeResult) (events : List Event)
    (h : runStages dr calculate mint before = .committed post fee events) :
    ∃ d f, dr = .ok d ∧ calculate d = some f ∧ mint f = .committed post fee events := by
  unfold runStages at h
  cases dr with
  | error e => cases h
  | ok d =>
    cases hf : calculate d with
    | none => simp only [hf] at h; cases h
    | some f =>
      simp only [hf] at h
      cases hm : mint f with
      | reverted e w => simp only [hm] at h; cases h
      | committed w f' es =>
        simp only [hm] at h
        cases h
        exact ⟨d, f, rfl, hf, hm⟩

private theorem mintBranch_router (accounting : Nat) (before post : World)
    (router : Core) (fee : FeeResult) (events : List Event) :
    MintBranch accounting {before with router} post fee events ↔
      MintBranch accounting before post fee events := Iff.rfl

private theorem root_success (report : ReportOutcome) (cont : Core → Outcome)
    (before post : World) (fee : FeeResult) (events : List Event)
    (h : runRoot report cont before = .committed post fee events) :
    ∃ r, report = .committed r ∧ cont r = .committed post fee events := by
  unfold runRoot at h
  cases report with
  | reverted e w => cases h
  | committed r => exact ⟨r, rfl, h⟩

theorem committed_success (x : Input) (before post : World) (fee : FeeResult)
    (events : List Event)
    (h : handleOracleReportFromCommittedFeeProducts x before = .committed post fee events) :
    Success x before post fee events := by
  have rs := root_success
    (reportValidatorBalances x.layout x.registeredModuleIds x.reportedModuleIds x.balancesGwei before.router)
    (continueFromCommittedReport x before) before post fee events h
  let router := rs.choose
  have hs := stages_success
    (getStakingRewardsDistribution x.layout x.registeredModuleIds router)
    (checkedFeeProductsFromCommittedGetter x.report)
    (mintCommittedFee x.accountingAddress {before with router}) before post fee events rs.choose_spec.2
  let d := hs.choose
  let inputFee := hs.choose_spec.choose
  have stage := hs.choose_spec.choose_spec
  have hm := mint_success x.accountingAddress {before with router} post inputFee fee events stage.2.2
  exact ⟨router, d, rs.choose_spec.1, stage.1,
    stage.2.1.trans (congrArg some hm.1.symm), hm.2.1,
    (mintBranch_router x.accountingAddress before post router fee events).mp hm.2.2⟩

/-- Retained event projection now derives Accounting/locator equality from
actual mint authorization rather than passing locator as the caller. -/
theorem committed_nonzero_mint_uses_fee_result (x : Input) (before post : World)
    (fee : FeeResult) (events : List Event)
    (h : handleOracleReportFromCommittedFeeProducts x before = .committed post fee events)
    (hfee : 0 < fee.sharesToMintAsFees) :
    ∃ pooled, events = [.transfer 0 before.steth.locatorAccounting pooled,
      .transferShares 0 before.steth.locatorAccounting fee.sharesToMintAsFees] := by
  obtain ⟨_, _, _, _, _, _, branches⟩ := committed_success x before post fee events h
  rcases branches with hz | ⟨_, _, effect⟩
  · exact False.elim ((Nat.ne_of_gt hfee) hz.1)
  · obtain ⟨pooled, _, he⟩ := effect.2.2.2.2.2.2.2.2
    exact ⟨pooled, effect.1 ▸ he⟩

private theorem stages_failure (dr : Except GetterError Distribution)
    (calculate : Distribution → Option FeeResult) (mint : FeeResult → Outcome)
    (before rollback : World) (error : Error)
    (h : runStages dr calculate mint before = .reverted error rollback) :
    rollback = before := by
  unfold runStages at h
  cases dr with
  | error e => cases h; rfl
  | ok d =>
    cases hf : calculate d with
    | none => simp only [hf] at h; cases h; rfl
    | some f =>
      simp only [hf] at h
      cases hm : mint f with
      | reverted e w => simp only [hm] at h; cases h; rfl
      | committed w f' es => simp only [hm] at h; cases h

private theorem root_failure (report : ReportOutcome) (cont : Core → Outcome)
    (before rollback : World) (error : Error)
    (hc : ∀ r e w, cont r = .reverted e w → w = before)
    (h : runRoot report cont before = .reverted error rollback) :
    rollback = before := by
  unfold runRoot at h
  cases report with
  | reverted e w => cases h; rfl
  | committed r => exact hc r error rollback h

theorem failure_restores (x : Input) (before rollback : World) (error : Error)
    (h : handleOracleReportFromCommittedFeeProducts x before = .reverted error rollback) :
    rollback = before := by
  exact root_failure
    (reportValidatorBalances x.layout x.registeredModuleIds x.reportedModuleIds x.balancesGwei before.router)
    (continueFromCommittedReport x before) before rollback error
    (fun r e w hc => stages_failure
      (getStakingRewardsDistribution x.layout x.registeredModuleIds r)
      (checkedFeeProductsFromCommittedGetter x.report)
      (mintCommittedFee x.accountingAddress {before with router := r}) before w e hc) h

/-- Checked loop success determines every exact floor and its mathematical
running total; no bounded-sum premise is supplied. -/
private theorem checkedModuleShares_split (shares totalFee : Nat) (fees : List Nat) :
    ∀ running parts final,
      checkedModuleShares shares totalFee fees running = some (parts, final) →
      parts = fees.map (fun f => shares * f / totalFee) ∧ final = running + parts.sum := by
  induction fees with
  | nil =>
    intro running parts final h
    simp only [checkedModuleShares, Option.some.injEq, Prod.mk.injEq] at h
    rcases h with ⟨rfl,rfl⟩
    simp
  | cons f fs ih =>
    intro running parts final h
    have step (part next : Nat) (rest : List Nat) (finish : Nat)
        (hn : checkedAdd running part = some next)
        (hr : checkedModuleShares shares totalFee fs next = some (rest,finish))
        (he : some (part :: rest,finish) = some (parts,final))
        (hp : part = shares * f / totalFee) :
        parts = (f :: fs).map (fun f => shares * f / totalFee) ∧ final = running + parts.sum := by
      cases Option.some.inj he
      have hnext : next = running + part := by
        unfold checkedAdd at hn
        split at hn
        · exact (Option.some.inj hn).symm
        · cases hn
      obtain ⟨hparts,hfinal⟩ := ih next rest _ hr
      constructor
      · simp only [List.map_cons,hp,hparts]
      · simp only [List.sum_cons]
        omega
    simp only [checkedModuleShares] at h
    by_cases hf : 0 < f
    · simp only [if_pos hf,bind,Option.bind_eq_some_iff] at h
      obtain ⟨product,hm,part,hd,next,hn,⟨rest,finish⟩,hr,he⟩ := h
      apply step part next rest finish hn hr he
      unfold checkedMul at hm
      split at hm
      · cases Option.some.inj hm
        unfold checkedDiv at hd
        split at hd
        · cases hd
        · exact (Option.some.inj hd).symm
      · cases hm
    · simp only [if_neg hf,bind,Option.bind_some,Option.bind_eq_some_iff] at h
      obtain ⟨next,hn,⟨rest,finish⟩,hr,he⟩ := h
      apply step 0 next rest finish hn hr he
      simp [Nat.eq_zero_of_not_pos hf]

/-- Exact checked distribution, including the source's zero-mint skip. -/
theorem checkedFeeResultOf_split (d : Distribution) (shares : Nat) (fee : FeeResult)
    (h : checkedFeeResultOf d shares = some fee) :
    fee.sharesToMintAsFees = shares ∧
    fee.moduleSharesToMint.sum + fee.treasurySharesToMint = shares ∧
    ((shares = 0 ∧ fee.moduleSharesToMint = [] ∧ fee.moduleFeeRecipients = [] ∧ fee.moduleIds = []) ∨
     (0 < shares ∧ 0 < d.totalFee ∧
      fee.moduleSharesToMint = d.stakingModuleFees.map (fun f => shares * f / d.totalFee) ∧
      fee.moduleFeeRecipients = d.recipients ∧ fee.moduleIds = d.stakingModuleIds)) := by
  unfold checkedFeeResultOf at h
  split at h
  · rename_i hs
    split at h
    · cases h
    · rename_i ht
      simp only [bind, Option.bind_eq_some_iff] at h
      obtain ⟨⟨parts,total⟩,hm,treasury,htreasury,heq⟩ := h
      cases Option.some.inj heq
      obtain ⟨hp,hsum⟩ := checkedModuleShares_split shares d.totalFee d.stakingModuleFees 0 parts total hm
      unfold checkedSub at htreasury
      split at htreasury
      · rename_i hle
        cases Option.some.inj htreasury
        refine ⟨rfl,?_,Or.inr ⟨hs,Nat.pos_of_ne_zero ht,hp,rfl,rfl⟩⟩
        simp only [Nat.zero_add] at hsum
        dsimp only
        omega
      · cases htreasury
  · rename_i hs
    cases Option.some.inj h
    have hz := Nat.eq_zero_of_not_pos hs
    exact ⟨hz.symm,by simp [hz],Or.inl ⟨hz,rfl,rfl,rfl⟩⟩

/-- Any actual checked fee-products success reaches that same checked split;
the share quantity is obtained from execution rather than a caller equality. -/
theorem checkedFeeProducts_split_origin (r : ReportWei) (d : Distribution) (fee : FeeResult)
    (h : checkedFeeProductsFromCommittedGetter r d = some fee) :
    ∃ shares, checkedFeeResultOf d shares = some fee := by
  unfold checkedFeeProductsFromCommittedGetter at h
  obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
  obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
  obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
  obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
  obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
  obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
  obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
  obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
  obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
  obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
  obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
  split at h
  · obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
    obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
    obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
    obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
    obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
    obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
    obtain ⟨_,_,h⟩ := Option.bind_eq_some_iff.mp h
    exact ⟨_,h⟩
  · exact ⟨0,h⟩

#print axioms checkedFeeResultOf_split
#print axioms checkedFeeProducts_split_origin
#print axioms committed_success
#print axioms failure_restores
end AccountAddress.ReportFeeMint
