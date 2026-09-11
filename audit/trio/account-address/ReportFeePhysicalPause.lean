import LidoSRv3.Audit.Guarantees.PAccount1TreasuryCall
namespace AccountAddress.ReportFeePhysicalPause
set_option autoImplicit false
open ReportWriteFee StETHMintShares ReportFeeTreasuryCall

def activePosition : Nat := 0x644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece
def pauseWord (s : State) : StorageWord := s.storage.read activePosition
def active (s : State) : Bool := decide ((pauseWord s).val ≠ 0)
def Consistent (s : State) : Prop := s.activeFlag = active s

def project (w : ReportFeeMint.World) : ReportFeeMint.World :=
  {w with steth := {w.steth with activeFlag := active w.steth}}

/-- Only the legacy flag metadata is interpreted; physical words, abstract share
map, router and existing supplied identity/auth context are unchanged. -/
theorem projection (w : ReportFeeMint.World) :
    (project w).router = w.router ∧ (project w).steth.storage = w.steth.storage ∧
    (project w).steth.shares = w.steth.shares ∧
    (project w).steth.locatorAccounting = w.steth.locatorAccounting ∧
    (project w).steth.selfAddress = w.steth.selfAddress ∧ Consistent (project w).steth := by
  exact ⟨rfl,rfl,rfl,rfl,rfl,rfl⟩

def Frame (before after : State) : Prop :=
  after.activeFlag = before.activeFlag ∧ pauseWord after = pauseWord before

theorem frame_consistent (before after : State) (hf : Frame before after) (hc : Consistent before) :
    Consistent after := by
  unfold Consistent active
  rw [hf.1,hf.2]
  exact hc

/-- Literal pinned positions are unequal; no storage nonalias premise. -/
theorem total_slot_distinct : totalSharesPosition ≠ activePosition := by decide +kernel

theorem mint_frame (caller recipient amount : Nat) (before after : State) (events : List Event)
    (h : mintShares caller recipient amount before = .committed after events) :
    Frame before after ∧ before.activeFlag = true := by
  unfold mintShares at h
  split at h
  · cases h
  split at h
  · cases h
  split at h
  · cases h
  rename_i hp
  split at h
  · cases h
  split at h
  · cases h
  split at h
  · cases h
  split at h
  · cases h
  split at h
  · cases h
  dsimp only at h
  split at h
  · cases h
  · cases h
    refine ⟨⟨rfl,?_⟩,?_⟩
    · exact Core.read_write_other _ _ total_slot_distinct
    · cases hf : before.activeFlag <;> simp_all

theorem transfer_frame (sender recipient amount : Nat) (before after : State) (pooled : Nat)
    (events : List Event) (h : FeeDistribution.TransferEffect sender recipient amount before after pooled events) :
    Frame before after := by
  obtain ⟨_,_,_,_,_,_,_,_,_,_,hp,_⟩ := h
  rw [hp]
  exact ⟨rfl,rfl⟩

/-- Each actual payment retains its old effect and derives the admission from
that call's physical word. The word is carried through every intermediate. -/
inductive Payments (sender : Nat) (entryWord : StorageWord) :
    List (Nat × Nat) → State → State → List Event → Prop where
  | nil (w) (consistent : Consistent w) (word : pauseWord w = entryWord) : Payments sender entryWord [] w w []
  | cons (recipient amount : Nat) (before middle after : State) (pooled : Nat)
      (events tailEvents : List Event) (rest : List (Nat × Nat))
      (positive : 0 < amount)
      (called : FeeDistribution.transferShares sender recipient amount before = .committed middle pooled events)
      (effect : FeeDistribution.TransferEffect sender recipient amount before middle pooled events)
      (consistent : Consistent before) (word : pauseWord before = entryWord)
      (physicalActive : active before = true)
      (tail : Payments sender entryWord rest middle after tailEvents) :
      Payments sender entryWord ((recipient,amount)::rest) before after (events++tailEvents)

theorem chain_physical {sender : Nat} {trace : List (Nat × Nat)} {before after : State} {events : List Event}
    (h : FeeDistribution.PaymentChain sender trace before after events) (hc : Consistent before) :
    Payments sender (pauseWord before) trace before after events ∧ Frame before after ∧ Consistent after := by
  induction h with
  | nil w => exact ⟨Payments.nil w hc rfl,⟨rfl,rfl⟩,hc⟩
  | cons recipient amount before middle after pooled events tailEvents rest hp called effect tail ih =>
    have hf := transfer_frame _ _ _ _ _ _ _ effect
    have hm := frame_consistent _ _ hf hc
    obtain ⟨chain,ht,ha⟩ := ih hm
    have activeFlag : before.activeFlag = true := effect.2.2.2.2.2.2.2.1
    refine ⟨?_,⟨ht.1.trans hf.1,ht.2.trans hf.2⟩,ha⟩
    apply Payments.cons recipient amount before middle after pooled events tailEvents rest hp called effect hc rfl
    · exact hc.symm.trans activeFlag
    · simpa only [hf.2] using chain

/-- The canonicalized input is actually executed. Failed outcomes restore the
original entry including ignored flag metadata, not merely its projection. -/
def execute (e : TreasuryCall.Environment) (x : ReportFeeMint.Input) (before : ReportFeeMint.World) :
    ReportFeeTreasuryCall.Outcome :=
  match ReportFeeTreasuryCall.execute e x (project before) with
  | .reverted fault _ payments attempts => .reverted fault before payments attempts
  | .committed post fee events payments attempts => .committed post fee events payments attempts

def OldEffect (e : TreasuryCall.Environment) (x : ReportFeeMint.Input) (before post : ReportFeeMint.World)
    (fee : FeeResult) (events : List Event) (payments : ReportFeeTreasuryCall.Payments) (attempts : Attempts) : Prop :=
  ∃ minted mintEvents,
    ReportFeeMint.handleOracleReportFromCommittedFeeProducts x (project before) = .committed minted fee mintEvents ∧
    ReportFeeDistribution.Success (TreasuryCall.read e x.accountingAddress minted.router) x (project before) post fee events payments ∧
    ReportFeeDistribution.Ledger x (project before) post fee payments ∧
    ((fee.sharesToMintAsFees = 0 ∧ attempts = []) ∨
     (0 < fee.sharesToMintAsFees ∧ ∃ distributionEvents,
       ReportFeeTreasuryCall.distribute e x.accountingAddress fee minted = .committed post distributionEvents payments attempts ∧
       ReadEffects e x.accountingAddress fee minted post distributionEvents payments attempts ∧ events = mintEvents++distributionEvents))

/-- The exact module result used by ReadEffects/TreasuryCall has the physical
invariant. A readonly external receives this state and has no post-world channel. -/
def ModuleWorldInvariant (caller : Nat) (fee : FeeResult) (before : State) (entryWord : StorageWord) : Prop :=
  ∀ middle moduleEvents modulePayments,
    FeeDistribution.modules caller fee.moduleFeeRecipients fee.moduleSharesToMint before =
      .committed middle moduleEvents modulePayments →
    Consistent middle ∧ pauseWord middle = entryWord

theorem module_world_invariant (caller : Nat) (fee : FeeResult) (before : State) (entryWord : StorageWord)
    (hc : Consistent before) (hw : pauseWord before = entryWord) : ModuleWorldInvariant caller fee before entryWord := by
  intro middle moduleEvents modulePayments hm
  have chain := (FeeDistribution.modules_success _ _ _ _ _ _ _ hm).2
  have hp := chain_physical chain hc
  exact ⟨hp.2.2,hp.2.1.2.trans hw⟩

def PhysicalEffect (x : ReportFeeMint.Input) (before post : ReportFeeMint.World)
    (fee : FeeResult) (events : List Event) (payments : ReportFeeTreasuryCall.Payments) : Prop :=
  Consistent post.steth ∧ pauseWord post.steth = pauseWord before.steth ∧
  ∃ minted mintEvents distributionEvents,
    ReportFeeMint.handleOracleReportFromCommittedFeeProducts x (project before) = .committed minted fee mintEvents ∧
    Consistent minted.steth ∧ pauseWord minted.steth = pauseWord before.steth ∧
    (fee.sharesToMintAsFees = 0 ∨ active (project before).steth = true) ∧
    ModuleWorldInvariant x.accountingAddress fee minted.steth (pauseWord before.steth) ∧
    Payments x.accountingAddress (pauseWord before.steth) payments minted.steth post.steth distributionEvents ∧
    events = mintEvents++distributionEvents

theorem mint_branch_frame (x : ReportFeeMint.Input) (before minted : ReportFeeMint.World)
    (fee : FeeResult) (events : List Event)
    (h : ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before = .committed minted fee events) :
    Frame before.steth minted.steth ∧ (fee.sharesToMintAsFees = 0 ∨ before.steth.activeFlag = true) := by
  obtain ⟨_,_,_,_,_,_,branch⟩ := ReportFeeMint.committed_success _ _ _ _ _ h
  rcases branch with ⟨hz,hw,_⟩ | ⟨hp,hm,_⟩
  · rw [hw]; exact ⟨⟨rfl,rfl⟩,Or.inl hz⟩
  · have hf := mint_frame _ _ _ _ _ _ hm
    exact ⟨hf.1,Or.inr hf.2⟩

theorem old_success_physical (read : FeeDistribution.TreasuryRead) (x : ReportFeeMint.Input)
    (before post : ReportFeeMint.World) (fee : FeeResult) (events : List Event) (payments : ReportFeeTreasuryCall.Payments)
    (h : ReportFeeDistribution.Success read x (project before) post fee events payments) :
    PhysicalEffect x before post fee events payments := by
  obtain ⟨minted,mintEvents,hm,hs,hbudget,hr,hstorage,branch⟩ := h
  obtain ⟨hf,ha⟩ := mint_branch_frame x (project before) minted fee mintEvents hm
  have hc := frame_consistent _ _ hf (projection before).2.2.2.2.2
  have hword : pauseWord minted.steth = pauseWord before.steth := hf.2
  have admission : fee.sharesToMintAsFees = 0 ∨ active (project before).steth = true := ha
  rcases branch with ⟨hz,hpost,he,ht⟩ | ⟨hp,es,hd,heffect,hev⟩
  · subst post
    subst payments
    exact ⟨hc,hword,minted,mintEvents,[],hm,hc,hword,admission,module_world_invariant _ _ _ _ hc hword,
      Payments.nil minted.steth hc hword,by simpa using he⟩
  · have chain := FeeDistribution.success_chain read x.accountingAddress fee minted.steth post.steth es payments heffect
    obtain ⟨physical,hframe,hconsistent⟩ := chain_physical chain hc
    exact ⟨hconsistent,hframe.2.trans hword,minted,mintEvents,es,hm,hc,hword,admission,module_world_invariant _ _ _ _ hc hword,
      by simpa only [hword] using physical,hev⟩

theorem execute_success (e : TreasuryCall.Environment) (x : ReportFeeMint.Input)
    (before post : ReportFeeMint.World) (fee : FeeResult) (events : List Event)
    (payments : ReportFeeTreasuryCall.Payments) (attempts : Attempts)
    (h : execute e x before = .committed post fee events payments attempts) :
    OldEffect e x before post fee events payments attempts ∧ PhysicalEffect x before post fee events payments := by
  unfold execute at h
  cases hr : ReportFeeTreasuryCall.execute e x (project before) with
  | reverted f w ps ats => simp only [hr] at h; cases h
  | committed p f es ps ats =>
    simp only [hr] at h
    cases h
    have old := LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_treasury_call e x (project before) post fee events payments attempts hr
    refine ⟨old,?_⟩
    obtain ⟨minted,mes,hm,hs,hl,hread⟩ := old
    exact old_success_physical _ x before post fee events payments hs

theorem failure_restores (e : TreasuryCall.Environment) (x : ReportFeeMint.Input)
    (before rollback : ReportFeeMint.World) (fault : ReportFeeTreasuryCall.Error)
    (payments : ReportFeeTreasuryCall.Payments) (attempts : Attempts)
    (h : execute e x before = .reverted fault rollback payments attempts) : rollback = before := by
  unfold execute at h
  split at h <;> cases h
  rfl
end AccountAddress.ReportFeePhysicalPause
