import audit.trio.deposit.WithdrawalLedger

/-! The ledger needs only the physical locator binding. Getter selectors derive
world preservation, including arbitrary address aliases, missing code and an
arbitrary read-only consensus reply. No general fallback frame is assumed. -/
namespace audit.trio.deposit.WithdrawalLedgerMinimal
open LidoSRv3.Audit.Source.TrioReserve1
open Live
open WithdrawalLedger

abbrev LocatorBound (c : Pipeline.Config) (ctx : Context) (w : World) : Prop :=
  c.locator = Verity.Core.Address.ofNat (w.core.readContractSlot ctx.self.val locatorSlot).val

def ReplyWorld (w : World) : Reply → Prop
  | .success _ after => after = w
  | .successWithTrace _ after _ => after = w
  | .rejected _ | .rejectedWithTrace _ _ => True

theorem zero_call_world (external : External) (ctx : Context) (target : Address)
    (selector : Nat) (w : World)
    (h : ReplyWorld w (external ⟨ctx.self, target, word 0, encode 4 selector⟩ w)) :
    (call external ctx target selector (word 0) w).world = w := by
  have hz : (word 0).val = 0 := rfl
  simp only [call, hz, Nat.not_lt_zero, ↓reduceIte, CallResults.transfer_zero]
  split
  · rfl
  · split <;> simp_all [ReplyWorld]

theorem queue_call_world (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (ctx : Context)
    (selector : Nat) (hs : selector = 0xd0fb84e8 ∨ selector = 0x2b95b781) (w : World) :
    (call (Pipeline.external k c staticOther other) ctx c.contracts.queue selector (word 0) w).world = w := by
  apply zero_call_world
  have h1 : encode 4 selector ≠ encode 4 0x37d5fe99 := by rcases hs with rfl | rfl <;> decide
  have h2 : encode 4 selector ≠ encode 4 0xef6c064c := by rcases hs with rfl | rfl <;> decide
  have h3 : encode 4 selector ≠ encode 4 0x5a2031f9 := by rcases hs with rfl | rfl <;> decide
  have h4 : encode 4 0x2b95b781 ≠ encode 4 0xd0fb84e8 := by decide
  rcases hs with rfl | rfl
  all_goals
    simp only [Pipeline.external, OracleCalls.external, QueueCalls.external,
      Locator.dispatch, Queue.dispatch, h1, h2, h3, h4,
      and_self, and_false, ↓reduceIte, ite_self, word, Verity.Core.Uint256.ofNat,
      Nat.zero_mod, ne_eq, not_true_eq_false]
  · split <;> simp [ReplyWorld]
  · rfl

theorem oracle_call_world (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (ctx : Context) (w : World) :
    (call (Pipeline.external k c staticOther other) ctx c.contracts.oracle 0x72f79b13 (word 0) w).world = w := by
  apply zero_call_world
  have h1 : encode 4 0x72f79b13 ≠ encode 4 0x37d5fe99 := by decide
  have h2 : encode 4 0x72f79b13 ≠ encode 4 0xef6c064c := by decide
  have h3 : encode 4 0x72f79b13 ≠ encode 4 0x5a2031f9 := by decide
  have h4 : encode 4 0x72f79b13 ≠ encode 4 0xd0fb84e8 := by decide
  have h5 : encode 4 0x72f79b13 ≠ encode 4 0x2b95b781 := by decide
  simp only [Pipeline.external, OracleCalls.external, QueueCalls.external,
    Locator.dispatch, Queue.dispatch, Oracle.dispatch, h1,h2,h3,h4,h5,
    and_self, and_false, ↓reduceIte, ite_self, word, Verity.Core.Uint256.ofNat,
    Nat.zero_mod, ne_eq, not_true_eq_false]
  unfold Oracle.frame
  dsimp only
  split
  · trivial
  · split
    · trivial
    · split <;> simp [ReplyWorld]

theorem pipeline_status_world (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (ctx : Context)
    (w : World) (b : LocatorBound c ctx w) :
    (canDeposit (Pipeline.external k c staticOther other) ctx w).world = w := by
  by_cases hc : (w.core.codeSize c.locator.val).val = 0
  · simp [canDeposit, withdrawalQueue, locatorAddress, getLidoLocator,
      Live.read, bind, bindExec, pure, pureExec, call, ← b, hc]
  · have hl := CallResults.queue_lookup ctx w c.contracts
      (Queue.dispatch k c.contracts.queue
        (Oracle.dispatch c.contracts.oracle c.oracle (Consensus.dispatch c.consensus c.frame staticOther)
          (Router.dispatch c.contracts.router c.lido other))) (by simpa only [← b] using hc)
    simp only [← b] at hl
    change withdrawalQueue (Pipeline.external k c staticOther other) ctx w = _ at hl
    have hw := queue_call_world k c staticOther other ctx 0x2b95b781 (Or.inr rfl) w
    cases he : call (Pipeline.external k c staticOther other) ctx c.contracts.queue 0x2b95b781 (word 0) w with
    | mk result after trace =>
      rw [he] at hw
      change after = w at hw
      subst after
      cases result with
      | error fault => simp [canDeposit, hl, he, bind, bindExec]
      | ok bytes =>
        by_cases hd : 32 ≤ bytes.length
        · simp [canDeposit, hl, he, bind, bindExec, decodeWord, require, hd, pure, pureExec]
          split <;> rfl
        · simp [canDeposit, hl, he, bind, bindExec, decodeWord, require, hd, fail]


theorem pipeline_allocation_world (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (ctx : Context)
    (w : World) (b : LocatorBound c ctx w) :
    (getBufferedEtherAllocation (Pipeline.external k c staticOther other) ctx w).world = w := by
  by_cases hc : (w.core.codeSize c.locator.val).val = 0
  · simp [getBufferedEtherAllocation, withdrawalQueue, locatorAddress, getLidoLocator,
      Live.read, bind, bindExec, pure, pureExec, call, ← b, hc]
  · have hl := CallResults.queue_lookup ctx w c.contracts
      (Queue.dispatch k c.contracts.queue
        (Oracle.dispatch c.contracts.oracle c.oracle (Consensus.dispatch c.consensus c.frame staticOther)
          (Router.dispatch c.contracts.router c.lido other))) (by simpa only [← b] using hc)
    simp only [← b] at hl
    change withdrawalQueue (Pipeline.external k c staticOther other) ctx w = _ at hl
    have hw := queue_call_world k c staticOther other ctx 0xd0fb84e8 (Or.inl rfl) w
    cases he : call (Pipeline.external k c staticOther other) ctx c.contracts.queue 0xd0fb84e8 (word 0) w with
    | mk result after trace =>
      rw [he] at hw
      change after = w at hw
      subst after
      cases result with
      | error fault => simp [getBufferedEtherAllocation, hl, he, bind, bindExec, Live.read]
      | ok bytes =>
        by_cases hd : 32 ≤ bytes.length <;>
          simp [getBufferedEtherAllocation, hl, he, bind, bindExec, Live.read,
            decodeWord, require, hd, pure, pureExec, fail]

theorem pipeline_frame_world (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (ctx : Context)
    (w : World) (b : LocatorBound c ctx w) :
    (getCurrentFrame (Pipeline.external k c staticOther other) ctx w).world = w := by
  by_cases hc : (w.core.codeSize c.locator.val).val = 0
  · simp [getCurrentFrame, locatorAddress, getLidoLocator,
      Live.read, bind, bindExec, pure, pureExec, call, ← b, hc]
  · have hl := CallResults.oracle_lookup ctx w c.contracts
      (Queue.dispatch k c.contracts.queue
        (Oracle.dispatch c.contracts.oracle c.oracle (Consensus.dispatch c.consensus c.frame staticOther)
          (Router.dispatch c.contracts.router c.lido other))) (by simpa only [← b] using hc)
    simp only [← b] at hl
    change locatorAddress (Pipeline.external k c staticOther other) ctx 0x5a2031f9 w = _ at hl
    have hw := oracle_call_world k c staticOther other ctx w
    cases he : call (Pipeline.external k c staticOther other) ctx c.contracts.oracle 0x72f79b13 (word 0) w with
    | mk result after trace =>
      rw [he] at hw
      change after = w at hw
      subst after
      cases result with
      | error fault => simp [getCurrentFrame, hl, he, bind, bindExec]
      | ok bytes =>
        by_cases hd : 64 ≤ bytes.length
        · have h32 : 32 ≤ bytes.length := by omega
          simp [getCurrentFrame, hl, he, bind, bindExec, decodeWord,
            require, hd, h32, pure, pureExec]
        · simp [getCurrentFrame, hl, he, bind, bindExec, require, hd, fail]
theorem pipeline_spending_success_balances (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (ctx : Context)
    (amount : Word) (before after : World) (trace : List Attempt)
    (b : LocatorBound c ctx before)
    (h : spendDepositableEther (Pipeline.external k c staticOther other) ctx amount before =
      ⟨.ok (), after, trace⟩) : after.balances = before.balances := by
  have hd := Spend.to_spec (Pipeline.external k c staticOther other) ctx amount before after (.ok ()) trace h
  cases hd with
  | success ha hn hf =>
    rename_i a allocated framed left right value
    have hw := pipeline_allocation_world k c staticOther other ctx before b
    rw [ha] at hw
    change allocated = before at hw
    subst allocated
    have hb := pipeline_frame_world k c staticOther other ctx
      (Spending.beforeFrame ctx a amount before) (by simpa only [LocatorBound, Pipeline.prepared_locator] using b)
    rw [hf] at hb
    have hb := congrArg World.balances hb
    change framed.balances = before.balances at hb
    simp only [Spend.committed, Spending.afterFrame]
    split <;> exact hb


theorem pipeline_router_success (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (ctx : Context)
    (w after : World) (target : Address) (trace : List Attempt) (b : LocatorBound c ctx w)
    (h : stakingRouter (Pipeline.external k c staticOther other) ctx w = ⟨.ok target, after, trace⟩) :
    after = w ∧ target = c.contracts.router := by
  by_cases hc : (w.core.codeSize c.locator.val).val = 0
  · simp [stakingRouter, locatorAddress, getLidoLocator,
      Live.read, bind, bindExec, pure, pureExec, call, ← b, hc] at h
  · have hl := CallResults.router_lookup ctx w c.contracts
      (Queue.dispatch k c.contracts.queue
        (Oracle.dispatch c.contracts.oracle c.oracle (Consensus.dispatch c.consensus c.frame staticOther)
          (Router.dispatch c.contracts.router c.lido other))) (by simpa only [← b] using hc)
    simp only [← b] at hl
    change stakingRouter (Pipeline.external k c staticOther other) ctx w = _ at hl
    exact ⟨by simpa using congrArg Result.world (h.symm.trans hl),
      by simpa using congrArg Result.outcome (h.symm.trans hl)⟩

/-- Success derives funding and the exact transferred ledger using only the
existing physical locator binding. All getter frames follow from their actual
source selector dispatch, without code-presence or oracle-pointer premises. -/
theorem pipeline_withdrawal_success_ledger (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (ctx : Context)
    (amount seeds : Word) (before after : World) (trace : List Attempt)
    (b : LocatorBound c ctx before)
    (h : run (withdrawDepositableEther (Pipeline.external k c staticOther other) ctx amount seeds) before =
      ⟨.ok (), after, trace⟩) :
    amount.val ≤ before.balances ctx.self ∧
      after.balances = (transfer before ctx.self ctx.sender amount.val).balances := by
  have hd := WithdrawalParent.to_spec (Pipeline.external k c staticOther other)
    ctx amount seeds before after (.ok ()) trace h
  cases hd with
  | finished hs hr ha hn hp ht =>
    rename_i w v u s r p t target
    have sw := pipeline_status_world k c staticOther other ctx before b
    rw [hs] at sw
    change w = before at sw
    subst w
    obtain ⟨vw, targetEq⟩ := pipeline_router_success k c staticOther other ctx before v target r b hr
    subst v
    have bp := pipeline_spending_success_balances k c staticOther other ctx amount before u p b hp
    unfold WithdrawalTail.finish at ht
    cases hseed : WithdrawalTail.updateSeeds ctx seeds u with
    | mk seedOutcome seeded seedTrace =>
      cases seedOutcome with
      | error fault => simp [hseed, bind, bindExec] at ht
      | ok value =>
        cases value
        have bseed := seeds_unchanged ctx seeds u
        rw [hseed] at bseed
        cases hc : call (Pipeline.external k c staticOther other) ctx target 0x13ae8460 amount seeded with
        | mk outcome transferred calls =>
          cases outcome with
          | error fault => simp [hseed, hc, bind, bindExec] at ht
          | ok bytes =>
            have hcallee := pipeline_receiver_preserves k c staticOther other ctx.self amount
              (transfer seeded ctx.self target amount.val)
            rw [← targetEq] at hcallee
            obtain ⟨hf, hb⟩ := call_success_ledger_at (Pipeline.external k c staticOther other)
              ctx target 0x13ae8460 amount seeded transferred bytes calls hcallee hc
            simp only [hseed, hc, bind, bindExec, pure, pureExec, Result.mk.injEq,
              true_and] at ht
            obtain ⟨hafter, _⟩ := ht
            subst after
            have same : seeded.balances = before.balances := bseed.trans bp
            refine ⟨by simpa only [same] using hf, ?_⟩
            rw [hb]
            simp only [transfer, same, ha]

#print axioms pipeline_withdrawal_success_ledger

end audit.trio.deposit.WithdrawalLedgerMinimal