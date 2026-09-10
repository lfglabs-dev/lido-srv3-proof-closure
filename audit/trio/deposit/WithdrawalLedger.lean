import LidoSRv3.Audit.Source.TrioReserve1.CalleeBalance
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalParent
import LidoSRv3.Audit.Source.TrioReserve1.Spend

/-! Internal ledger composition for the DEPOSIT consumer. `Preserves` below is
an internal comparison premise. The final pipeline theorem discharges it for
the actual configured source paths, for every arbitrary fallback. It uses the
existing configuration binding and derives funding and authorization from the
successful execution; these are not separate caller premises. -/
namespace audit.trio.deposit.WithdrawalLedger
open LidoSRv3.Audit.Source.TrioReserve1
open Live

abbrev Unchanged (program : Exec α) : Prop :=
  ∀ before, (program before).world.balances = before.balances

theorem bind_unchanged (first : Exec α) (next : α → Exec β)
    (hf : Unchanged first) (hn : ∀ value, Unchanged (next value)) :
    Unchanged (bindExec first next) := by
  intro before
  unfold bindExec
  dsimp only
  split
  · exact hf before
  · exact (hn _ _).trans (hf before)

theorem ite_unchanged (p : Prop) [Decidable p] (left right : Exec α)
    (hl : Unchanged left) (hr : Unchanged right) :
    Unchanged (if p then left else right) := by
  split <;> assumption

theorem transfer_zero (before : World) (sender target : Address) :
    (transfer before sender target 0).balances = before.balances := by
  funext a
  simp [transfer]

theorem call_success_ledger_at (external : External)
    (ctx : Context) (target : Address) (selector : Nat) (amount : Word)
    (before after : World) (data : Bytes) (trace : List Attempt)
    (he : CalleeBalance.ReplyPreserves (transfer before ctx.self target amount.val)
      (external ⟨ctx.self, target, amount, encode 4 selector⟩
        (transfer before ctx.self target amount.val)))
    (h : call external ctx target selector amount before = ⟨.ok data, after, trace⟩) :
    amount.val ≤ before.balances ctx.self ∧
      after.balances = (transfer before ctx.self target amount.val).balances := by
  unfold call at h
  split at h
  · cases h
  · split at h
    · cases h
    · rename_i hcode hfunds
      have hp := he
      dsimp only at h
      split at h <;> simp_all [CalleeBalance.ReplyPreserves, Result.mk.injEq]

theorem zero_call_unchanged (external : External) (he : CalleeBalance.Preserves external)
    (ctx : Context) (target : Address) (selector : Nat) :
    Unchanged (call external ctx target selector (word 0)) := by
  intro before
  unfold call
  split
  · rfl
  · split
    · rfl
    · have hp := he ⟨ctx.self, target, word 0, encode 4 selector⟩
        (transfer before ctx.self target (word 0).val)
      dsimp only
      split <;> simp_all [CalleeBalance.ReplyPreserves, word, transfer_zero]

theorem seeds_unchanged (ctx : Context) (seeds : Word) :
    Unchanged (WithdrawalTail.updateSeeds ctx seeds) := by
  unfold WithdrawalTail.updateSeeds checkedAdd
  repeat' first
    | apply bind_unchanged
    | solve | intro before; rfl
    | apply ite_unchanged
    | unfold require
    | intro x

/-- An internal comparison callee only. The source pipeline below is proved
independent of this fallback before its invariant can be used. -/
def reject : External := fun _ _ => .rejected []

theorem reject_preserves : CalleeBalance.Preserves reject := by intro req before; trivial

theorem frame_unchanged (external : External) (he : CalleeBalance.Preserves external)
    (ctx : Context) : Unchanged (getCurrentFrame external ctx) := by
  unfold getCurrentFrame locatorAddress getLidoLocator decodeWord
  repeat' first
    | apply bind_unchanged
    | solve | exact zero_call_unchanged external he _ _ _
    | solve | intro before; rfl
    | apply ite_unchanged
    | unfold require
    | intro x

theorem pipeline_status_world (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (ctx : Context)
    (w : World) (b : Pipeline.Bound c ctx w) :
    (canDeposit (Pipeline.external k c staticOther other) ctx w).world = w := by
  have hs := QueueCalls.status k c.contracts
    (Oracle.dispatch c.contracts.oracle c.oracle (Consensus.dispatch c.consensus c.frame staticOther)
      (Router.dispatch c.contracts.router c.lido other)) ctx w
    (by simpa only [← b.locator] using b.queue_ne_locator)
    (by simpa only [← b.locator] using b.locator_code) b.queue_code
  simpa only [← b.locator, Pipeline.external, OracleCalls.external] using congrArg Result.world hs

theorem pipeline_allocation_world (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (ctx : Context)
    (w : World) (b : Pipeline.Bound c ctx w) :
    (getBufferedEtherAllocation (Pipeline.external k c staticOther other) ctx w).world = w := by
  cases hq : Queue.unfinalizedStETH k c.contracts.queue w with
  | ok demand => exact congrArg Result.world (Pipeline.allocation_result k c staticOther other ctx w demand b hq)
  | error code =>
    have ha := QueueCalls.allocation_panic k c.contracts
      (Oracle.dispatch c.contracts.oracle c.oracle (Consensus.dispatch c.consensus c.frame staticOther)
        (Router.dispatch c.contracts.router c.lido other)) ctx w code
      (by simpa only [← b.locator] using b.queue_ne_locator)
      (by simpa only [← b.locator] using b.locator_code) b.queue_code hq
    simpa only [← b.locator, Pipeline.external, OracleCalls.external] using congrArg Result.world ha

/-- Both lookups reach the configured source oracle, so no arbitrary fallback
is executed. This is an equality of full results, not a new callee assumption. -/
theorem pipeline_frame_other_irrel (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (left right : External) (ctx : Context)
    (w : World) (b : Pipeline.Bound c ctx w) :
    getCurrentFrame (Pipeline.external k c staticOther left) ctx w =
      getCurrentFrame (Pipeline.external k c staticOther right) ctx w := by
  have lookup (other : External) := CallResults.oracle_lookup ctx w c.contracts
    (Queue.dispatch k c.contracts.queue
      (Oracle.dispatch c.contracts.oracle c.oracle (Consensus.dispatch c.consensus c.frame staticOther)
        (Router.dispatch c.contracts.router c.lido other)))
    (by simpa only [← b.locator] using b.locator_code)
  have hl := lookup left
  have hr := lookup right
  simp only [← b.locator] at hl hr
  change locatorAddress (Pipeline.external k c staticOther left) ctx 0x5a2031f9 w = _ at hl
  change locatorAddress (Pipeline.external k c staticOther right) ctx 0x5a2031f9 w = _ at hr
  simp only [getCurrentFrame, bind, bindExec, hl, hr]
  have hcall : call (Pipeline.external k c staticOther left) ctx c.contracts.oracle 0x72f79b13 (word 0) w =
      call (Pipeline.external k c staticOther right) ctx c.contracts.oracle 0x72f79b13 (word 0) w := by
    simp [call, Pipeline.external, OracleCalls.external, QueueCalls.external, Locator.dispatch,
      Queue.dispatch, Oracle.dispatch, b.oracle_ne_locator, b.oracle_ne_queue,
      b.oracle_code, word, Verity.Core.Uint256.ofNat, CallResults.transfer_zero]
  rw [hcall]

theorem pipeline_frame_world (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (ctx : Context)
    (w : World) (b : Pipeline.Bound c ctx w) :
    (getCurrentFrame (Pipeline.external k c staticOther other) ctx w).world.balances = w.balances := by
  rw [pipeline_frame_other_irrel k c staticOther other reject ctx w b]
  exact frame_unchanged _ (CalleeBalance.pipeline k c staticOther reject reject_preserves) ctx w

theorem prepared_bound (c : Pipeline.Config) (ctx : Context) (a : Live.Allocation)
    (amount : Word) (w : World) (b : Pipeline.Bound c ctx w) :
    Pipeline.Bound c ctx (Spending.beforeFrame ctx a amount w) := by
  constructor
  · simpa only [Pipeline.prepared_locator] using b.locator
  · simpa only [Pipeline.prepared_consensus] using b.consensus
  · exact b.queue_ne_locator
  · exact b.oracle_ne_locator
  · exact b.oracle_ne_queue
  · simpa only [Pipeline.prepared_code] using b.locator_code
  · simpa only [Pipeline.prepared_code] using b.queue_code
  · simpa only [Pipeline.prepared_code] using b.oracle_code
  · simpa only [Pipeline.prepared_code] using b.consensus_code

theorem pipeline_spending_success_balances (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (ctx : Context)
    (amount : Word) (before after : World) (trace : List Attempt)
    (b : Pipeline.Bound c ctx before)
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
      (Spending.beforeFrame ctx a amount before) (prepared_bound c ctx a amount before b)
    rw [hf] at hb
    change framed.balances = before.balances at hb
    simp only [Spend.committed, Spending.afterFrame]
    split <;> exact hb

/-- The literal payable receiver selector passes through every preceding
source dispatcher and reaches Router.receiveDepositableEther. The fallback is
not invoked even when configured addresses coincide. -/
theorem pipeline_receiver_preserves (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (caller : Address)
    (amount : Word) (w : World) :
    CalleeBalance.ReplyPreserves w ((Pipeline.external k c staticOther other)
      ⟨caller, c.contracts.router, amount, encode 4 0x13ae8460⟩ w) := by
  have h1 : encode 4 0x13ae8460 ≠ encode 4 0x37d5fe99 := by decide
  have h2 : encode 4 0x13ae8460 ≠ encode 4 0xef6c064c := by decide
  have h3 : encode 4 0x13ae8460 ≠ encode 4 0x5a2031f9 := by decide
  have h4 : encode 4 0x13ae8460 ≠ encode 4 0xd0fb84e8 := by decide
  have h5 : encode 4 0x13ae8460 ≠ encode 4 0x2b95b781 := by decide
  have h6 : encode 4 0x13ae8460 ≠ encode 4 0x72f79b13 := by decide
  by_cases hc : caller = c.lido <;>
    simp [Pipeline.external, OracleCalls.external, QueueCalls.external, Locator.dispatch,
      Queue.dispatch, Oracle.dispatch, Router.dispatch, Router.receiveDepositableEther,
      h1,h2,h3,h4,h5,h6, hc, CalleeBalance.ReplyPreserves]

/-- No preservation hypothesis on the arbitrary fallback: successful source
routing derives every frame needed for the ledger. `Bound` is the existing
RESERVE source-configuration binding; funding and admission are derived. -/
theorem pipeline_withdrawal_success_ledger (k : Queue.Keccak) (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (ctx : Context)
    (amount seeds : Word) (before after : World) (trace : List Attempt)
    (b : Pipeline.Bound c ctx before)
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
    have rr := Pipeline.router_result k c staticOther other ctx before b
    have vw : v = before := by
      simpa only using congrArg Result.world (hr.symm.trans rr)
    have targetEq : target = c.contracts.router := by
      simpa only [Except.ok.injEq] using congrArg Result.outcome (hr.symm.trans rr)
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

end audit.trio.deposit.WithdrawalLedger
