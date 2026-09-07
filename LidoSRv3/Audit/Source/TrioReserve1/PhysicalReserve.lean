import LidoSRv3.Audit.Source.TrioReserve1.Pipeline
import LidoSRv3.Audit.Source.TrioReserve1.PhysicalPacking
import LidoSRv3.Audit.Source.TrioReserve1.PartitionSpec

namespace LidoSRv3.Audit.Source.TrioReserve1.PhysicalReserve
open Live

def buffer (ctx : Context) (w : World) : Nat :=
  (w.core.readContractSlot ctx.self.val bufferSlot).val % width

def reserve (ctx : Context) (w : World) : Nat :=
  (w.core.readContractSlot ctx.self.val reserveSlot).val

/-- The committed world in Pipeline.success, including receiver transfer and log. -/
def committed (ctx : Context) (router : Address) (amount seeds : Word)
    (w : World) (demand reference : Nat) : World :=
  let sw := Pipeline.seeded ctx seeds (Pipeline.spent ctx amount w demand reference)
  {transfer sw ctx.self router amount.val with
    logs := sw.logs ++ [⟨router, "DepositableEthReceived", [amount]⟩]}

theorem after_frame_buffer (ctx : Context) (amount : Word) (next nonce : Nat) (w : World) :
    buffer ctx (Spending.afterFrame ctx amount next nonce w) = buffer ctx w := by
  unfold Spending.afterFrame
  dsimp only
  split <;> simp only [buffer, Pipeline.read_other_slot _ _ _ _ _ _
    (by decide : bufferSlot ≠ reserveSlot), Pipeline.read_other_slot _ _ _ _ _ _
    (by decide : bufferSlot ≠ nextSlot)]

theorem after_frame_reserve (ctx : Context) (amount : Word) (next nonce : Nat) (w : World) :
    reserve ctx (Spending.afterFrame ctx amount next nonce w) = reserve ctx w - amount.val := by
  unfold Spending.afterFrame
  dsimp only
  rw [Pipeline.read_other_slot _ _ _ _ _ _ (by decide : reserveSlot ≠ nextSlot)]
  split
  · simp only [reserve, Verity.ContractState.readContractSlot_writeContractSlot_same]
    exact Nat.mod_eq_of_lt (Nat.lt_of_le_of_lt (Nat.sub_le _ _)
      (w.core.readContractSlot ctx.self.val reserveSlot).isLt)
  · simp only [reserve, Pipeline.read_other_slot _ _ _ _ _ _
      (by decide : reserveSlot ≠ nextSlot)]
    omega

theorem seeded_read (ctx : Context) (seeds : Word) (w : World) (slot : Nat)
    (h : slot ≠ seedSlot) :
    (Pipeline.seeded ctx seeds w).core.readContractSlot ctx.self.val slot =
      w.core.readContractSlot ctx.self.val slot := by
  unfold Pipeline.seeded
  split
  · rfl
  · exact Pipeline.read_other_slot _ _ _ _ _ _ h

/-- Physical subtraction does not wrap, including reserve values above buffer. -/
theorem committed_fields (ctx : Context) (router : Address) (amount seeds : Word)
    (w : World) (demand reference : Nat) :
    buffer ctx (committed ctx router amount seeds w demand reference) = buffer ctx w - amount.val ∧
    reserve ctx (committed ctx router amount seeds w demand reference) = reserve ctx w - amount.val := by
  have hb : buffer ctx w - amount.val < width :=
    Nat.lt_of_le_of_lt (Nat.sub_le _ _) (Nat.mod_lt _ (by decide))
  constructor
  · change ((Pipeline.seeded ctx seeds (Pipeline.spent ctx amount w demand reference)).core.readContractSlot
      ctx.self.val bufferSlot).val % width = _
    rw [seeded_read _ _ _ _ (by decide : bufferSlot ≠ seedSlot)]
    change buffer ctx (Pipeline.spent ctx amount w demand reference) = _
    unfold Pipeline.spent
    rw [after_frame_buffer]
    simp only [Pipeline.prepared, Spending.beforeFrame, buffer,
      Verity.ContractState.readContractSlot_writeContractSlot_same, PhysicalPacking.low_pack,
      QueueCalls.allocationValues]
    exact Nat.mod_eq_of_lt hb
  · change ((Pipeline.seeded ctx seeds (Pipeline.spent ctx amount w demand reference)).core.readContractSlot
      ctx.self.val reserveSlot).val = _
    rw [seeded_read _ _ _ _ (by decide : reserveSlot ≠ seedSlot)]
    change reserve ctx (Pipeline.spent ctx amount w demand reference) = _
    unfold Pipeline.spent
    rw [after_frame_reserve]
    congr 1
    exact congrArg Verity.Core.Uint256.val (Pipeline.read_other_slot _ _ _ _ _ _
      (by decide : reserveSlot ≠ bufferSlot))

theorem admitted (ctx : Context) (w : World) (demand amount : Nat)
    (h : amount ≤ (QueueCalls.allocationValues ctx w demand).deposits +
      (QueueCalls.allocationValues ctx w demand).unreserved) :
    PartitionSpec.AllowedSpend (buffer ctx w) (reserve ctx w) demand amount := by
  unfold QueueCalls.allocationValues at h
  unfold PartitionSpec.AllowedSpend PartitionSpec.protectedReserve buffer reserve
  dsimp only at h
  omega

/-- Independent withdrawal protection evaluated on actual final physical cells. -/
theorem committed_protection (ctx : Context) (router : Address) (amount seeds : Word)
    (w : World) (demand reference : Nat)
    (h : amount.val ≤ (QueueCalls.allocationValues ctx w demand).deposits +
      (QueueCalls.allocationValues ctx w demand).unreserved) :
    PartitionSpec.protectedReserve
      (buffer ctx (committed ctx router amount seeds w demand reference))
      (reserve ctx (committed ctx router amount seeds w demand reference)) demand =
      PartitionSpec.protectedReserve (buffer ctx w) (reserve ctx w) demand := by
  rw [(committed_fields ctx router amount seeds w demand reference).1,
    (committed_fields ctx router amount seeds w demand reference).2]
  exact PartitionSpec.spend_preserves _ _ _ _ (admitted ctx w demand amount.val h)

theorem read_other_account (core : Verity.ContractState) (writer reader written slot : Nat)
    (value : Word) (h : reader ≠ writer) :
    (core.writeContractSlot writer written value).readContractSlot reader slot =
      core.readContractSlot reader slot := by
  by_cases hs : slot = written
  · subst slot
    exact Verity.ContractState.readContractSlot_writeContractSlot_other_contract core h value
  · exact Pipeline.read_other_slot core writer reader written slot value hs

/-- Every storage cell of a distinct contract survives the accounting and seed
writes. This includes arbitrary queue mapping hashes, without injectivity assumptions. -/
theorem committed_other_account (ctx : Context) (router : Address) (amount seeds : Word)
    (w : World) (demand reference reader slot : Nat) (h : reader ≠ ctx.self.val) :
    (committed ctx router amount seeds w demand reference).core.readContractSlot reader slot =
      w.core.readContractSlot reader slot := by
  change (Pipeline.seeded ctx seeds (Pipeline.spent ctx amount w demand reference)).core.readContractSlot
    reader slot = _
  have hseed : ∀ v : World, (Pipeline.seeded ctx seeds v).core.readContractSlot reader slot =
      v.core.readContractSlot reader slot := by
    intro v
    unfold Pipeline.seeded
    split
    · rfl
    · exact read_other_account _ _ _ _ _ _ h
  rw [hseed]
  unfold Pipeline.spent Spending.afterFrame
  dsimp only
  split <;> simp only [read_other_account _ _ _ _ _ _ h]
  all_goals exact read_other_account _ _ _ _ _ _ h

theorem committed_queue (k : Queue.Keccak) (ctx : Context) (router queue : Address)
    (amount seeds : Word) (w : World) (demand reference : Nat)
    (h : queue.val ≠ ctx.self.val) :
    Queue.unfinalizedStETH k queue (committed ctx router amount seeds w demand reference) =
      Queue.unfinalizedStETH k queue w := by
  simp only [Queue.unfinalizedStETH, Queue.getLastRequestId, Queue.getLastFinalizedRequestId,
    Queue.cumulative, committed_other_account _ _ _ _ _ _ _ _ _ h]


open Pipeline

/-- Concrete successful execution preserves the independent protected reserve
on the resulting physical world, and its next live queue read returns the same
demand. Every execution premise is a physical/configuration or numeric check. -/
theorem success_preserves (k : Queue.Keccak) (c : Config) (staticOther : StaticCall.External)
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
    (hlido : ctx.self = c.lido) (hrcode : (w.core.codeSize c.contracts.router.val).val ≠ 0)
    (hqueue : c.contracts.queue.val ≠ ctx.self.val) :
    let result := run (withdrawDepositableEther (external k c staticOther other) ctx amount seeds) w
    result.outcome = .ok () ∧
      buffer ctx result.world = buffer ctx w - amount.val ∧
      reserve ctx result.world = reserve ctx w - amount.val ∧
      Queue.unfinalizedStETH k c.contracts.queue result.world = .ok demand ∧
      PartitionSpec.protectedReserve (buffer ctx result.world) (reserve ctx result.world) demand =
        PartitionSpec.protectedReserve (buffer ctx w) (reserve ctx w) demand := by
  dsimp only
  rw [Pipeline.success k c staticOther other ctx w amount seeds demand reference deadline time
    b hb hp hauth hn hq hamount hf ht hseed hfunds hlido hrcode]
  change Except.ok () = Except.ok () ∧
    buffer ctx (committed ctx c.contracts.router amount seeds w demand reference) = _ ∧
    reserve ctx (committed ctx c.contracts.router amount seeds w demand reference) = _ ∧
    Queue.unfinalizedStETH k c.contracts.queue
      (committed ctx c.contracts.router amount seeds w demand reference) = _ ∧ _
  exact ⟨rfl, (committed_fields ctx c.contracts.router amount seeds w demand reference).1,
    (committed_fields ctx c.contracts.router amount seeds w demand reference).2,
    (committed_queue k ctx c.contracts.router c.contracts.queue amount seeds w demand reference hqueue).trans hq,
    committed_protection ctx c.contracts.router amount seeds w demand reference hamount⟩

end LidoSRv3.Audit.Source.TrioReserve1.PhysicalReserve
