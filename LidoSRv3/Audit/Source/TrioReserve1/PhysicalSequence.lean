import LidoSRv3.Audit.Source.TrioReserve1.PhysicalReserve
import LidoSRv3.Audit.Source.TrioReserve1.SequenceSpec

namespace LidoSRv3.Audit.Source.TrioReserve1.PhysicalSequence
open Live

theorem committed_target (ctx : Context) (router : Address) (amount seeds : Word)
    (w : World) (demand reference : Nat) :
    (PhysicalReserve.committed ctx router amount seeds w demand reference).core.readContractSlot
      ctx.self.val targetSlot = w.core.readContractSlot ctx.self.val targetSlot := by
  change (Pipeline.seeded ctx seeds (Pipeline.spent ctx amount w demand reference)).core.readContractSlot
    ctx.self.val targetSlot = _
  rw [PhysicalReserve.seeded_read _ _ _ _ (by decide : targetSlot ≠ seedSlot)]
  unfold Pipeline.spent Spending.afterFrame
  dsimp only
  split <;> simp only [Pipeline.read_other_slot _ _ _ _ _ _
    (by decide : targetSlot ≠ reserveSlot), Pipeline.read_other_slot _ _ _ _ _ _
    (by decide : targetSlot ≠ nextSlot)]
  all_goals exact Pipeline.read_other_slot _ _ _ _ _ _ (by decide : targetSlot ≠ bufferSlot)

theorem committed_step (ctx : Context) (router : Address) (amount seeds : Word)
    (w : World) (demand reference : Nat)
    (h : amount.val ≤ (QueueCalls.allocationValues ctx w demand).deposits +
      (QueueCalls.allocationValues ctx w demand).unreserved) :
    SequenceSpec.Step (Writers.project ctx w)
      (Writers.project ctx (PhysicalReserve.committed ctx router amount seeds w demand reference)) := by
  have ha := PhysicalReserve.admitted ctx w demand amount.val h
  apply SequenceSpec.Step.spend _ _ demand amount.val ha
  · change PhysicalReserve.buffer ctx (PhysicalReserve.committed ctx router amount seeds w demand reference) +
      amount.val = PhysicalReserve.buffer ctx w
    rw [(PhysicalReserve.committed_fields ctx router amount seeds w demand reference).1]
    unfold PartitionSpec.AllowedSpend at ha
    omega
  · exact (PhysicalReserve.committed_fields ctx router amount seeds w demand reference).2
  · exact congrArg Verity.Core.Uint256.val (committed_target ctx router amount seeds w demand reference)

/-- Internal writer and committed-withdrawal worlds, with each spend admitted
against its current physical partition. External ACL/report admission and queue
writers are separate; no constructor purports to implement them. -/
inductive Steps (k : Queue.Keccak) (queue : Address) (ctx : Context) : World → World → Prop
  | refl (w : World) : Steps k queue ctx w w
  | target {a b : World} (requested : Word)
      (rest : Steps k queue ctx (run (setDepositsReserveTarget ctx requested) a).world b) : Steps k queue ctx a b
  | rebalance {a b : World}
      (rest : Steps k queue ctx (run (updateBufferedEtherAllocation ctx) a).world b) : Steps k queue ctx a b
  | spend {a b : World} (router : Address) (amount seeds : Word) (demand reference : Nat)
      (live : Queue.unfinalizedStETH k queue a = .ok demand)
      (admitted : amount.val ≤ (QueueCalls.allocationValues ctx a demand).deposits +
        (QueueCalls.allocationValues ctx a demand).unreserved)
      (rest : Steps k queue ctx (PhysicalReserve.committed ctx router amount seeds a demand reference) b) :
      Steps k queue ctx a b

/-- Arbitrary finite interleavings refine an executor-independent relation;
in particular a target increase is deferred until a rebalance step. -/
theorem corresponds (k : Queue.Keccak) (queue : Address) (ctx : Context) (a b : World) (h : Steps k queue ctx a b) :
    SequenceSpec.Steps (Writers.project ctx a) (Writers.project ctx b) := by
  induction h with
  | refl w => exact .refl _
  | target requested rest ih =>
    exact .cons (.target _ _ requested.val (Writers.target_corresponds ctx _ requested)) ih
  | rebalance rest ih =>
    exact .cons (.rebalance _ _ (Writers.rebalance_corresponds ctx _)) ih
  | spend router amount seeds demand reference live admitted rest ih =>
    exact .cons (committed_step ctx router amount seeds _ demand reference admitted) ih

theorem target_protection (ctx : Context) (w : World) (requested : Word) (demand : Nat) :
    PartitionSpec.protectedReserve (PhysicalReserve.buffer ctx w) (PhysicalReserve.reserve ctx w) demand ≤
      PartitionSpec.protectedReserve
        (PhysicalReserve.buffer ctx (run (setDepositsReserveTarget ctx requested) w).world)
        (PhysicalReserve.reserve ctx (run (setDepositsReserveTarget ctx requested) w).world) demand :=
  SequenceSpec.target_protection _ _ requested.val demand (Writers.target_corresponds ctx w requested)

theorem rebalance_partition (ctx : Context) (w : World) (demand : Nat) :
    PartitionSpec.protectedReserve
      (PhysicalReserve.buffer ctx (run (updateBufferedEtherAllocation ctx) w).world)
      (PhysicalReserve.reserve ctx (run (updateBufferedEtherAllocation ctx) w).world) demand =
    min (PhysicalReserve.buffer ctx w - min (PhysicalReserve.buffer ctx w)
      (max (PhysicalReserve.reserve ctx w) (w.core.readContractSlot ctx.self.val targetSlot).val)) demand :=
  SequenceSpec.rebalance_partition _ _ demand (Writers.rebalance_corresponds ctx w)

theorem target_other_account (ctx : Context) (w : World) (requested : Word)
    (reader slot : Nat) (h : reader ≠ ctx.self.val) :
    (run (setDepositsReserveTarget ctx requested) w).world.core.readContractSlot reader slot =
      w.core.readContractSlot reader slot := by
  by_cases hc : requested.val < (w.core.readContractSlot ctx.self.val reserveSlot).val
  all_goals simp [run, setDepositsReserveTarget, setDepositsReserve, Live.read, Live.write,
    Live.emit, bind, bindExec, pure, pureExec, Writers.read_write_other,
    PhysicalReserve.read_other_account _ _ _ _ _ _ h,
    (by decide : reserveSlot ≠ targetSlot), hc]

theorem rebalance_other_account (ctx : Context) (w : World) (reader slot : Nat)
    (h : reader ≠ ctx.self.val) :
    (run (updateBufferedEtherAllocation ctx) w).world.core.readContractSlot reader slot =
      w.core.readContractSlot reader slot := by
  by_cases hc : (w.core.readContractSlot ctx.self.val reserveSlot).val <
    (w.core.readContractSlot ctx.self.val targetSlot).val
  all_goals simp [run, updateBufferedEtherAllocation, setDepositsReserve, Live.read, Live.write,
    Live.emit, bind, bindExec, pure, pureExec, PhysicalReserve.read_other_account _ _ _ _ _ _ h, hc]

/-- Even coinciding numeric slot hashes cannot alias a distinct contract's
storage namespace. All queue rows and both current IDs survive these sequences. -/
theorem other_account (k : Queue.Keccak) (queue : Address) (ctx : Context) (a b : World)
    (steps : Steps k queue ctx a b) (reader slot : Nat) (h : reader ≠ ctx.self.val) :
    b.core.readContractSlot reader slot = a.core.readContractSlot reader slot := by
  induction steps with
  | refl w => rfl
  | target requested rest ih => exact ih.trans (target_other_account ctx _ requested reader slot h)
  | rebalance rest ih => exact ih.trans (rebalance_other_account ctx _ reader slot h)
  | spend router amount seeds demand reference live admitted rest ih =>
    exact ih.trans (PhysicalReserve.committed_other_account ctx router amount seeds _ demand reference reader slot h)

theorem queue_preserved (k : Queue.Keccak) (queue : Address) (ctx : Context) (a b : World)
    (steps : Steps k queue ctx a b) (h : queue.val ≠ ctx.self.val) :
    Queue.unfinalizedStETH k queue b = Queue.unfinalizedStETH k queue a := by
  simp only [Queue.unfinalizedStETH, Queue.getLastRequestId, Queue.getLastFinalizedRequestId,
    Queue.cumulative, other_account k queue ctx a b steps queue.val _ h]


open Pipeline

/-- The real concrete withdrawal execution instantiates the independent spend
transition from raw source configuration and numeric checks. -/
theorem concrete_success_step (k : Queue.Keccak) (c : Config) (staticOther : StaticCall.External)
    (other : External) (ctx : Context) (w : World) (amount seeds : Word)
    (demand reference deadline time : Nat) (b : Bound c ctx w)
    (hb : Queue.isBunkerModeActive c.contracts.queue w = false)
    (hp : (w.core.readContractSlot ctx.self.val activeSlot).val ≠ 0)
    (hauth : ctx.sender = c.contracts.router) (hn : amount.val ≠ 0)
    (hq : Queue.unfinalizedStETH k c.contracts.queue w = .ok demand)
    (hamount : amount.val ≤ (QueueCalls.allocationValues ctx w demand).deposits +
      (QueueCalls.allocationValues ctx w demand).unreserved)
    (hf : Consensus.compute c.frame (prepared ctx amount w demand).core.blockTimestamp.val
      ((prepared ctx amount w demand).core.readContractSlot c.consensus.val c.frame.frameSlot).val =
        .ok (reference, deadline))
    (ht : Oracle.timestamp c.oracle.genesis.val c.oracle.secondsPerSlot.val reference = .value time)
    (hseed : ((spent ctx amount w demand reference).core.readContractSlot ctx.self.val seedSlot).val % width +
      seeds.val < Verity.Core.UINT256_MODULUS)
    (hfunds : amount.val ≤ w.balances ctx.self)
    (hlido : ctx.self = c.lido) (hrcode : (w.core.codeSize c.contracts.router.val).val ≠ 0) :
    SequenceSpec.Step (Writers.project ctx w)
      (Writers.project ctx (run
        (withdrawDepositableEther (external k c staticOther other) ctx amount seeds) w).world) := by
  rw [Pipeline.success k c staticOther other ctx w amount seeds demand reference deadline time
    b hb hp hauth hn hq hamount hf ht hseed hfunds hlido hrcode]
  exact committed_step ctx c.contracts.router amount seeds w demand reference hamount

end LidoSRv3.Audit.Source.TrioReserve1.PhysicalSequence
