import LidoSRv3.Audit.Guarantees.PReserve1
import LidoSRv3.Audit.Source.TrioReserve1.WithdrawalParent
import LidoSRv3.Audit.Source.TrioReserve1.ReportParent

namespace LidoSRv3.Audit.Guarantees.PReserve1LiveWriters
set_option autoImplicit false
open Source.TrioReserve1 Source.TrioReserve1.Live

/-- The partition is obtained at the actual spending-stage entry, using the
actual locator/queue CALL/decoder. No cached demand or callee frame premise. -/
def SpendPartition (external : External) (ctx : Context) (amount : Word) (before : World) : Prop :=
  ∃ a queue data demand,
    (getBufferedEtherAllocation external ctx before).outcome = .ok a ∧
    amount.val ≤ a.deposits + a.unreserved ∧
    (withdrawalQueue external ctx before).outcome = .ok queue ∧
    (call external ctx queue 0xd0fb84e8 (word 0)
      (withdrawalQueue external ctx before).world).outcome = .ok data ∧
    (decodeWord data 0 (call external ctx queue 0xd0fb84e8 (word 0)
      (withdrawalQueue external ctx before).world).world).outcome = .ok demand ∧
    a.total = (before.core.readContractSlot ctx.self.val bufferSlot).val % width ∧
    AllocationSpec.Describes a.total (before.core.readContractSlot ctx.self.val reserveSlot).val
      demand.val (Allocation.observe a)

theorem spend_partition (external : External) (ctx : Context) (amount : Word) (before : World)
    (h : (spendDepositableEther external ctx amount before).outcome = .ok ()) :
    SpendPartition external ctx amount before := by
  unfold spendDepositableEther at h
  obtain ⟨a,ha,hr⟩ := Allocation.bind_success _ _ _ _ h
  obtain ⟨u,hu,_⟩ := Allocation.bind_success _ _ _ _ hr
  have hb : amount.val ≤ (getDepositableEther a).val := by
    by_contra hn
    simp [require,hn,fail] at hu
  rw [(Spending.allocation_bounds external ctx before a ha).2.2] at hb
  obtain ⟨queue,data,demand,hq,hd,hw,ht,hs⟩ := Allocation.success_corresponds external ctx before a ha
  exact ⟨a,queue,data,demand,ha,hb,hq,hd,hw,ht,hs⟩

/-- Successful withdrawal exposes its actual stage worlds and trace, then
consumes the queue-derived partition from the very spending stage executed.
Arbitrary callbacks can change accounting; final-reserve preservation is not
inferred without their named physical correspondence. -/
def WithdrawSuccess (external : External) (ctx : Context) (amount seeds : Word)
    (before after : World) (trace : List Attempt) : Prop :=
  ∃ statusWorld spendWorld spent s r p t router,
    canDeposit external ctx before = ⟨.ok true,statusWorld,s⟩ ∧
    stakingRouter external ctx statusWorld = ⟨.ok router,spendWorld,r⟩ ∧
    ctx.sender = router ∧ amount.val ≠ 0 ∧
    spendDepositableEther external ctx amount spendWorld = ⟨.ok (),spent,p⟩ ∧
    SpendPartition external ctx amount spendWorld ∧
    WithdrawalTail.finish external ctx router amount seeds spent = ⟨.ok (),after,t⟩ ∧
    trace = s ++ r ++ p ++ t

theorem withdrawal_success (external : External) (ctx : Context) (amount seeds : Word)
    (before after : World) (trace : List Attempt)
    (h : run (withdrawDepositableEther external ctx amount seeds) before = ⟨.ok (),after,trace⟩) :
    WithdrawSuccess external ctx amount seeds before after trace := by
  have hd := WithdrawalParent.to_spec external ctx amount seeds before after (.ok ()) trace h
  cases hd with
  | finished hs hr ha hn hp ht =>
    exact ⟨_,_,_,_,_,_,_,_,hs,hr,ha,hn,hp,
      spend_partition external ctx amount _ (by rw [hp]),ht,rfl⟩

/-- Existing source operations, not a new Solidity entrypoint. Target and
rebalance are internal writers; report/withdrawal run their actual root guards.
History steps are separate transactions, so a later revert retains prior commits. -/
inductive Action where
  | target (requested : Word)
  | rebalance
  | report (input : Report.Inputs)
  | withdraw (amount seeds : Word)

def execute (external : External) (ctx : Context) : Action → World → Result Unit
  | .target requested => run (setDepositsReserveTarget ctx requested)
  | .rebalance => run (updateBufferedEtherAllocation ctx)
  | .report input => run (Report.collect external ctx input)
  | .withdraw amount seeds => run (withdrawDepositableEther external ctx amount seeds)

def Effects (external : External) (ctx : Context) (action : Action) (before : World) : Prop :=
  let result := execute external ctx action before
  match action with
  | .target requested =>
    WriterSpec.Target (Writers.project ctx before) requested.val (Writers.project ctx result.world) ∧
    result.outcome = .ok () ∧ result.attempts = [] ∧ result.world.balances = before.balances ∧
    result.world.logs = before.logs ++ [⟨ctx.self,"DepositsReserveTargetSet",[requested]⟩] ++
      (if requested.val < (before.core.readContractSlot ctx.self.val reserveSlot).val
       then [⟨ctx.self,"DepositsReserveSet",[requested]⟩] else [])
  | .rebalance =>
    WriterSpec.Rebalance (Writers.project ctx before) (Writers.project ctx result.world) ∧
    result.outcome = .ok () ∧ result.attempts = [] ∧ result.world.balances = before.balances ∧
    result.world.logs = before.logs ++
      (if (before.core.readContractSlot ctx.self.val reserveSlot).val <
          (before.core.readContractSlot ctx.self.val targetSlot).val
       then [⟨ctx.self,"DepositsReserveSet",[before.core.readContractSlot ctx.self.val targetSlot]⟩] else [])
  | .report input =>
    ReportParent.Describes external ctx input before result.outcome result.world result.attempts
  | .withdraw amount seeds =>
    WithdrawalParent.Describes external ctx amount seeds before result.outcome result.world result.attempts ∧
    match result.outcome with
    | .ok _ => WithdrawSuccess external ctx amount seeds before result.world result.attempts
    | .error _ => result.world = before

theorem step_effects (external : External) (ctx : Context) (action : Action) (before : World) :
    Effects external ctx action before := by
  cases action with
  | target requested => exact PReserve1.reserve_set_target_execution ctx before requested
  | rebalance => exact PReserve1.reserve_update_buffered_allocation_execution ctx before
  | report input => exact ReportParent.complete external ctx input before
  | withdraw amount seeds =>
    have hd := WithdrawalParent.complete external ctx amount seeds before
    refine ⟨hd,?_⟩
    cases h : run (withdrawDepositableEther external ctx amount seeds) before with
    | mk outcome after trace =>
      cases outcome with
      | ok u =>
        cases u
        exact withdrawal_success external ctx amount seeds before after trace h
      | error fault =>
        rw [h] at hd
        exact WithdrawalSpec.failure_restores hd

/-- Recursive postcondition threads the actual returned World, including all
physical writer/callback changes, into the next real operation. It does not
assume that target, report or queue callbacks preserve a desired partition. -/
def HistoryEffects (external : External) (ctx : Context) : List Action → World → Prop
  | [], _ => True
  | action :: rest, before => Effects external ctx action before ∧
      HistoryEffects external ctx rest (execute external ctx action before).world

/-- Registered RESERVE consumer of physical writers, report accounting and
actual queue-derived withdrawal partitions across arbitrary finite histories. -/
theorem actual_reserve_writer_history (external : External) (ctx : Context)
    (actions : List Action) (before : World) : HistoryEffects external ctx actions before := by
  induction actions generalizing before with
  | nil => trivial
  | cons action rest ih => exact ⟨step_effects external ctx action before,ih _⟩

#print axioms actual_reserve_writer_history
end LidoSRv3.Audit.Guarantees.PReserve1LiveWriters
