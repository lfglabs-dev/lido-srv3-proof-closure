import LidoSRv3.Audit.Source.TrioReserve1.ACLPermission
import LidoSRv3.Audit.Source.TrioReserve1.PhysicalSequence

namespace LidoSRv3.Audit.Source.TrioReserve1.Target
open Live

/-- Closed physical post-state: target is always written; reserve is written only
when lowering it. The event order mirrors those writes. This does not invoke an
executor, permission query, or writer implementation. -/
def committed (ctx : Context) (requested : Word) (before : World) : World :=
  let lowered := requested.val < (before.core.readContractSlot ctx.self.val reserveSlot).val
  let targetCore := before.core.writeContractSlot ctx.self.val targetSlot requested
  { before with
    core := if lowered then targetCore.writeContractSlot ctx.self.val reserveSlot requested else targetCore
    logs := before.logs ++ [⟨ctx.self, "DepositsReserveTargetSet", [requested]⟩] ++
      (if lowered then [⟨ctx.self, "DepositsReserveSet", [requested]⟩] else []) }

theorem writer_success (ctx : Context) (requested : Word) (before : World) :
    setDepositsReserveTarget ctx requested before = ⟨.ok (), committed ctx requested before, []⟩ := by
  by_cases h : requested.val < (before.core.readContractSlot ctx.self.val reserveSlot).val
  all_goals
    simp only [reserveSlot] at h
    simp [setDepositsReserveTarget, setDepositsReserve, committed, Live.write, emit, Live.read,
      bind, bindExec, pure, pureExec, Writers.read_write_other, targetSlot, reserveSlot, h]

theorem accounting (ctx : Context) (requested : Word) (before : World) :
    WriterSpec.Target (Writers.project ctx before) requested.val
      (Writers.project ctx (committed ctx requested before)) := by
  have h := Writers.target_corresponds ctx before requested
  simpa [run, writer_success] using h

theorem balances (ctx : Context) (requested : Word) (before : World) :
    (committed ctx requested before).balances = before.balances := rfl

theorem other_slot (ctx : Context) (requested : Word) (before : World) (slot : Nat)
    (ht : slot ≠ targetSlot) (hr : slot ≠ reserveSlot) :
    (committed ctx requested before).core.readContractSlot ctx.self.val slot =
      before.core.readContractSlot ctx.self.val slot := by
  unfold committed
  dsimp only
  split <;> simp [Writers.read_write_other, ht, hr]

theorem other_account (ctx : Context) (requested : Word) (before : World) (account slot : Nat)
    (h : account ≠ ctx.self.val) :
    (committed ctx requested before).core.readContractSlot account slot = before.core.readContractSlot account slot := by
  unfold committed
  dsimp only
  split <;> simp [PhysicalReserve.read_other_account, h]

/-- Independent permission derivations yield the exact complete target transaction:
return value, both physical writes, balances, ordered events and nested call trace.
Physical code/initialization and primitive interpretation remain explicit inputs. -/
theorem success (k : Queue.Keccak) (staticExternal : StaticCall.External) (other : External)
    (ctx : Context) (requested : Word) (before : World) (trace : List NestedAttempt)
    (hi : Aragon.initialized ctx before = true) (hk : (Aragon.kernel ctx before).val ≠ 0)
    (hkc : (before.core.codeSize (Aragon.kernel ctx before).val).val ≠ 0)
    (ha : (Kernel.acl k (Aragon.kernel ctx before) before).val ≠ 0)
    (hac : (before.core.codeSize (Kernel.acl k (Aragon.kernel ctx before) before).val).val ≠ 0)
    (hs : ACLPermission.Describes k staticExternal (Kernel.acl k (Aragon.kernel ctx before) before)
      ctx Aragon.bufferReserveManagerRole [] before (.value true) trace) :
    ∃ fuel, ∀ extra, run (Aragon.setTarget (ACLCalls.external k staticExternal (Aragon.kernel ctx before)
      (Kernel.acl k (Aragon.kernel ctx before) before) ctx Aragon.bufferReserveManagerRole (fuel+extra) other)
        ctx requested) before = ⟨.ok (), committed ctx requested before,
          ACLPermission.admissionTrace k ctx Aragon.bufferReserveManagerRole before true trace⟩ := by
  obtain ⟨fuel, hf⟩ := ACLPermission.canPerform_traced k staticExternal other ctx
    Aragon.bufferReserveManagerRole before true trace hi hk hkc ha hac hs
  refine ⟨fuel, fun extra => ?_⟩
  simp [run, Aragon.setTarget, bind, bindExec, hf extra, require, pure, pureExec, writer_success]

theorem queue_preserved (k : Queue.Keccak) (ctx : Context) (requested : Word) (before : World)
    (queue : Address) (h : queue.val ≠ ctx.self.val) :
    Queue.unfinalizedStETH k queue (committed ctx requested before) = Queue.unfinalizedStETH k queue before := by
  simp only [Queue.unfinalizedStETH, Queue.getLastRequestId, Queue.getLastFinalizedRequestId,
    Queue.cumulative, other_account _ _ _ _ _ h]

/-- The exact successful external post-state instantiates the existing physical
sequence relation. External admission is supplied by `success`; this lemma alone
makes no claim that arbitrary target sequences are externally reachable. -/
theorem sequence_step (k : Queue.Keccak) (queue : Address) (ctx : Context) (requested : Word) (before : World) :
    PhysicalSequence.Steps k queue ctx before (committed ctx requested before) := by
  have h : PhysicalSequence.Steps k queue ctx before
      (run (setDepositsReserveTarget ctx requested) before).world :=
    .target requested (.refl _)
  simpa [run, writer_success] using h

end LidoSRv3.Audit.Source.TrioReserve1.Target
