import ReportFeeCheckedSplit

namespace AccountAddress.FeeDistribution
open ReportWriteFee StETHMintShares

inductive TransferError where
  | invalidAddress | invalidAmount | fromZero | toZero | toSteth | stopped
  | balanceExceeded | addOverflow | conversion (e : StETHMintShares.Error)
  deriving DecidableEq, Repr
inductive TransferOutcome where
  | reverted (error : TransferError) (rollback : State)
  | committed (post : State) (pooled : Nat) (events : List Event)

/-- Sequential Solidity mapping writes: the recipient read follows the debit,
including sender=recipient. The mapping remains the accepted abstract map. -/
def debit (sender amount : Nat) (before : State) : StETHMintShares.Shares :=
  fun a => if a = sender then before.shares a - amount else before.shares a

def moved (sender recipient amount : Nat) (before : State) : State :=
  {before with shares := fun a => if a = recipient then debit sender amount before a + amount else debit sender amount before a}

/-- Typed StETH.sol:365-369,494-507, with Nat-word/address admission explicit.
No recipient callback occurs. The same post-state rate helper is executed. -/
def transferShares (sender recipient amount : Nat) (before : State) : TransferOutcome :=
  if sender ≥ 2^160 ∨ recipient ≥ 2^160 ∨ before.selfAddress ≥ 2^160 then
    .reverted .invalidAddress before
  else if amount ≥ two256 then .reverted .invalidAmount before
  else if sender = 0 then .reverted .fromZero before
  else if recipient = 0 then .reverted .toZero before
  else if recipient = before.selfAddress then .reverted .toSteth before
  else if !before.activeFlag then .reverted .stopped before
  else if before.shares sender < amount then .reverted .balanceExceeded before
  else if uint256Max < debit sender amount before recipient + amount then .reverted .addOverflow before
  else
    let post := moved sender recipient amount before
    match pooledEthByShares post amount with
    | .error e => .reverted (.conversion e) before
    | .ok pooled => .committed post pooled [.transfer sender recipient pooled,.transferShares sender recipient amount]

def TransferEffect (sender recipient amount : Nat) (before post : State)
    (pooled : Nat) (events : List Event) : Prop :=
  sender < 2^160 ∧ recipient < 2^160 ∧ before.selfAddress < 2^160 ∧ amount < two256 ∧
  sender ≠ 0 ∧ recipient ≠ 0 ∧ recipient ≠ before.selfAddress ∧ before.activeFlag = true ∧
  amount ≤ before.shares sender ∧ debit sender amount before recipient + amount ≤ uint256Max ∧
  post = moved sender recipient amount before ∧
  pooledEthByShares post amount = .ok pooled ∧
  events = [.transfer sender recipient pooled,.transferShares sender recipient amount]

theorem transfer_success (sender recipient amount : Nat) (before post : State)
    (pooled : Nat) (events : List Event)
    (h : transferShares sender recipient amount before = .committed post pooled events) :
    TransferEffect sender recipient amount before post pooled events := by
  unfold transferShares at h
  split at h
  · cases h
  · rename_i ha
    split at h
    · cases h
    · rename_i hm
      split at h
      · cases h
      · rename_i hf
        split at h
        · cases h
        · rename_i ht
          split at h
          · cases h
          · rename_i hs
            split at h
            · cases h
            · rename_i hp
              split at h
              · cases h
              · rename_i hb
                split at h
                · cases h
                · rename_i ho
                  dsimp only at h
                  cases hc : pooledEthByShares (moved sender recipient amount before) amount with
                  | error e => simp only [hc] at h; cases h
                  | ok value =>
                    simp only [hc] at h
                    cases h
                    have active : before.activeFlag = true := by cases hflag : before.activeFlag <;> simp_all
                    exact ⟨by omega,by omega,by omega,by omega,hf,ht,hs,active,by omega,by omega,rfl,hc,rfl⟩

/-- Source typed transfer calls, with exact actual intermediate states/events. -/
inductive PaymentChain (sender : Nat) : List (Nat × Nat) → State → State → List Event → Prop where
  | nil (before) : PaymentChain sender [] before before []
  | cons (recipient amount : Nat) (before middle after : State) (pooled : Nat)
      (events tailEvents : List Event) (rest : List (Nat × Nat))
      (positive : 0 < amount)
      (called : transferShares sender recipient amount before = .committed middle pooled events)
      (effect : TransferEffect sender recipient amount before middle pooled events)
      (tail : PaymentChain sender rest middle after tailEvents) :
      PaymentChain sender ((recipient,amount)::rest) before after (events ++ tailEvents)

theorem PaymentChain.storage {sender : Nat} {trace : List (Nat × Nat)} {before post : State}
    {events : List Event} (h : PaymentChain sender trace before post events) : post.storage = before.storage := by
  induction h with
  | nil => rfl
  | cons recipient amount before middle after pooled events tailEvents rest hp hc he ht ih =>
    have hw : middle.storage = before.storage := by rw [he.2.2.2.2.2.2.2.2.2.2.1]; rfl
    exact ih.trans hw

/-- Exact pointwise share ledger, including duplicate/self recipients. -/
def credits (account : Nat) (trace : List (Nat × Nat)) : Nat :=
  (trace.map fun p => if account = p.1 then p.2 else 0).sum

def paid (trace : List (Nat × Nat)) : Nat := (trace.map Prod.snd).sum

theorem transfer_ledger {sender recipient amount : Nat} {before post : State}
    {pooled : Nat} {events : List Event}
    (h : TransferEffect sender recipient amount before post pooled events) (account : Nat) :
    post.shares account + (if account = sender then amount else 0) =
      before.shares account + (if account = recipient then amount else 0) := by
  obtain ⟨_,_,_,_,_,_,_,_,hfund,_,hp,_⟩ := h
  rw [hp]
  by_cases hs : account = sender
  · subst account
    by_cases hr : sender = recipient
    · subst recipient
      simp [moved,debit,Nat.sub_add_cancel hfund]
    · simp [moved,debit,hr,Nat.sub_add_cancel hfund]
  · by_cases hr : account = recipient
    · subst account
      simp [moved,debit,hs]
    · simp [moved,debit,hs,hr]

theorem PaymentChain.ledger {sender : Nat} {trace : List (Nat × Nat)} {before post : State}
    {events : List Event} (h : PaymentChain sender trace before post events) (account : Nat) :
    post.shares account + (if account = sender then paid trace else 0) =
      before.shares account + credits account trace := by
  induction h with
  | nil => simp [paid,credits]
  | cons r a before middle after pooled es tailEvents rest hp hc he ht ih =>
    have single := transfer_ledger he account
    by_cases hs : account = sender
    · simp only [if_pos hs,paid,credits,List.map_cons,List.sum_cons] at ih single ⊢
      omega
    · simp only [if_neg hs,paid,credits,List.map_cons,List.sum_cons] at ih single ⊢
      omega

theorem PaymentChain.append {sender : Nat} {first rest : List (Nat × Nat)} {before middle post : State}
    {es tail : List Event} (h : PaymentChain sender first before middle es)
    (hrest : PaymentChain sender rest middle post tail) :
    PaymentChain sender (first++rest) before post (es++tail) := by
  induction h with
  | nil => exact hrest
  | cons r a before middle after pooled events tailEvents payments hp hc he ht ih =>
    simpa only [List.cons_append,List.append_assoc] using
      PaymentChain.cons r a before middle post pooled events (tailEvents++tail) (payments++rest)
        hp hc he (ih hrest)

inductive Error where
  | arrayBounds | transfer (e : TransferError) | treasuryRead (tag : Nat)
  deriving DecidableEq, Repr
/-- Typed read-only locator result on the actual post-module state. This is
an explicit external resolver boundary, not a proved locator STATICCALL ABI. -/
abbrev TreasuryRead := State → Except Nat Nat
inductive Outcome where
  | reverted (error : Error) (state : State) (attempted : List (Nat × Nat))
  | committed (post : State) (events : List Event) (attempted : List (Nat × Nat))

def positivePayments (recipients amounts : List Nat) : List (Nat × Nat) :=
  (recipients.zip amounts).filter (fun p => 0 < p.2)

/-- Accounting470-481: loop over recipients, read the corresponding amount,
skip zero, and consume the actual sequential transfer result. -/
def modules (sender : Nat) : List Nat → List Nat → State → Outcome
  | [], _, before => .committed before [] []
  | _::_, [], before => .reverted .arrayBounds before []
  | recipient::recipients, amount::amounts, before =>
    if amount = 0 then modules sender recipients amounts before
    else match transferShares sender recipient amount before with
      | .reverted e w => .reverted (.transfer e) w [(recipient,amount)]
      | .committed middle _ events =>
        match modules sender recipients amounts middle with
        | .reverted e w trace => .reverted e w ((recipient,amount)::trace)
        | .committed post tailEvents trace => .committed post (events++tailEvents) ((recipient,amount)::trace)

theorem modules_success (sender : Nat) (recipients amounts : List Nat) (before post : State)
    (events : List Event) (trace : List (Nat × Nat))
    (h : modules sender recipients amounts before = .committed post events trace) :
    trace = positivePayments recipients amounts ∧ PaymentChain sender trace before post events := by
  induction recipients generalizing amounts before post events trace with
  | nil => cases h; exact ⟨rfl,.nil before⟩
  | cons r rs ih =>
    cases amounts with
    | nil => cases h
    | cons a amounts =>
      unfold modules at h
      split at h
      · rename_i hz
        have ht := ih amounts before post events trace h
        refine ⟨?_,ht.2⟩
        simpa [positivePayments,hz] using ht.1
      · rename_i hn
        cases hc : transferShares sender r a before with
        | reverted e w => simp only [hc] at h; cases h
        | committed middle pooled logs =>
          simp only [hc] at h
          cases ht : modules sender rs amounts middle with
          | reverted e w t => simp only [ht] at h; cases h
          | committed after tailEvents tailTrace =>
            simp only [ht] at h
            cases h
            obtain ⟨he,chain⟩ := ih amounts middle _ tailEvents tailTrace ht
            refine ⟨?_,.cons r a before middle _ pooled logs tailEvents tailTrace
              (Nat.pos_of_ne_zero hn) hc (transfer_success _ _ _ _ _ _ _ hc) chain⟩
            simp [positivePayments,Nat.pos_of_ne_zero hn,he,positivePayments] at *

/-- Treasury resolution happens only after all module transfers, and only
for a positive treasury amount. No mutable locator callback is modeled. -/
def finish (read : TreasuryRead) (sender treasury : Nat) (middle : State)
    (events : List Event) (trace : List (Nat × Nat)) : Outcome :=
  if treasury = 0 then .committed middle events trace
  else match read middle with
    | .error e => .reverted (.treasuryRead e) middle trace
    | .ok recipient => match transferShares sender recipient treasury middle with
      | .reverted e w => .reverted (.transfer e) w (trace++[(recipient,treasury)])
      | .committed post _ tail => .committed post (events++tail) (trace++[(recipient,treasury)])

def execute (read : TreasuryRead) (sender : Nat) (fee : FeeResult) (before : State) : Outcome :=
  match modules sender fee.moduleFeeRecipients fee.moduleSharesToMint before with
  | .reverted e w trace => .reverted e w trace
  | .committed middle events trace => finish read sender fee.treasurySharesToMint middle events trace

def Success (read : TreasuryRead) (sender : Nat) (fee : FeeResult)
    (before post : State) (events : List Event) (trace : List (Nat × Nat)) : Prop :=
  ∃ middle moduleEvents moduleTrace,
    modules sender fee.moduleFeeRecipients fee.moduleSharesToMint before = .committed middle moduleEvents moduleTrace ∧
    moduleTrace = positivePayments fee.moduleFeeRecipients fee.moduleSharesToMint ∧
    PaymentChain sender moduleTrace before middle moduleEvents ∧
    ((fee.treasurySharesToMint = 0 ∧ post = middle ∧ events = moduleEvents ∧ trace = moduleTrace) ∨
     (0 < fee.treasurySharesToMint ∧ ∃ recipient pooled treasuryEvents,
       read middle = .ok recipient ∧
       transferShares sender recipient fee.treasurySharesToMint middle = .committed post pooled treasuryEvents ∧
       TransferEffect sender recipient fee.treasurySharesToMint middle post pooled treasuryEvents ∧
       events = moduleEvents++treasuryEvents ∧ trace = moduleTrace++[(recipient,fee.treasurySharesToMint)]))

theorem execute_success (read : TreasuryRead) (sender : Nat) (fee : FeeResult)
    (before post : State) (events : List Event) (trace : List (Nat × Nat))
    (h : execute read sender fee before = .committed post events trace) : Success read sender fee before post events trace := by
  unfold execute at h
  cases hm : modules sender fee.moduleFeeRecipients fee.moduleSharesToMint before with
  | reverted e w t => simp only [hm] at h; cases h
  | committed middle moduleEvents moduleTrace =>
    simp only [hm] at h
    have hs := modules_success _ _ _ _ _ _ _ hm
    refine ⟨middle,moduleEvents,moduleTrace,hm,hs.1,hs.2,?_⟩
    unfold finish at h
    split at h
    · rename_i hz
      cases h
      exact Or.inl ⟨hz,rfl,rfl,rfl⟩
    · rename_i hn
      cases hr : read middle with
      | error e => simp only [hr] at h; cases h
      | ok recipient =>
        simp only [hr] at h
        cases ht : transferShares sender recipient fee.treasurySharesToMint middle with
        | reverted e w => simp only [ht] at h; cases h
        | committed after pooled treasuryEvents =>
          simp only [ht] at h
          cases h
          exact Or.inr ⟨Nat.pos_of_ne_zero hn,recipient,pooled,treasuryEvents,rfl,ht,
            transfer_success _ _ _ _ _ _ _ ht,rfl,rfl⟩

theorem success_chain (read : TreasuryRead) (sender : Nat) (fee : FeeResult)
    (before post : State) (events : List Event) (trace : List (Nat × Nat))
    (h : Success read sender fee before post events trace) : PaymentChain sender trace before post events := by
  obtain ⟨middle,moduleEvents,moduleTrace,_,_,chain,branch⟩ := h
  rcases branch with ⟨_,hp,he,ht⟩ | ⟨hpos,recipient,pooled,treasuryEvents,_,hc,effect,he,ht⟩
  · rw [hp,he,ht]
    exact chain
  · rw [he,ht]
    apply chain.append
    simpa only [List.append_nil] using
      PaymentChain.cons recipient fee.treasurySharesToMint middle post post pooled treasuryEvents [] []
        hpos hc effect (.nil post)

theorem positivePayments_paid (recipients amounts : List Nat) (h : recipients.length = amounts.length) :
    paid (positivePayments recipients amounts) = amounts.sum := by
  induction recipients generalizing amounts with
  | nil => cases amounts <;> simp_all [positivePayments,paid]
  | cons r rs ih =>
    cases amounts with
    | nil => simp at h
    | cons a amounts =>
      have ht : rs.length = amounts.length := Nat.succ.inj h
      have hi := ih amounts ht
      by_cases hz : a = 0
      · simpa [positivePayments,paid,hz] using hi
      · simp only [positivePayments,List.zip_cons_cons,List.filter_cons,show decide (0<a) = true from by simp [Nat.pos_of_ne_zero hz],if_true,
          paid,List.map_cons,List.sum_cons]
        exact congrArg (a + ·) hi

theorem success_paid (read : TreasuryRead) (sender : Nat) (fee : FeeResult)
    (before post : State) (events : List Event) (trace : List (Nat × Nat))
    (aligned : fee.moduleFeeRecipients.length = fee.moduleSharesToMint.length)
    (h : Success read sender fee before post events trace) :
    paid trace = fee.moduleSharesToMint.sum + fee.treasurySharesToMint := by
  obtain ⟨middle,moduleEvents,moduleTrace,_,hm,_,branch⟩ := h
  have hp := positivePayments_paid fee.moduleFeeRecipients fee.moduleSharesToMint aligned
  rw [← hm] at hp
  rcases branch with ⟨hz,_,_,ht⟩ | ⟨_,recipient,pooled,treasuryEvents,_,_,_,_,ht⟩
  · simp only [ht,hp,hz,Nat.add_zero]
  · simp only [ht,paid,List.map_append,List.sum_append,List.map_cons,List.map_nil,List.sum_cons,List.sum_nil,Nat.add_zero]
    exact congrArg (· + fee.treasurySharesToMint) hp

#print axioms success_chain
#print axioms success_paid
theorem success_storage (read : TreasuryRead) (sender : Nat) (fee : FeeResult)
    (before post : State) (events : List Event) (trace : List (Nat × Nat))
    (h : Success read sender fee before post events trace) : post.storage = before.storage := by
  obtain ⟨middle,moduleEvents,moduleTrace,_,_,chain,branch⟩ := h
  rcases branch with ⟨_,hp,_,_⟩ | ⟨_,recipient,pooled,treasuryEvents,_,_,effect,_,_⟩
  · rw [hp]
    exact chain.storage
  · have hw : post.storage = middle.storage := by rw [effect.2.2.2.2.2.2.2.2.2.2.1]; rfl
    exact hw.trans chain.storage

#print axioms success_storage
#print axioms transfer_success
#print axioms modules_success
#print axioms execute_success
end AccountAddress.FeeDistribution
